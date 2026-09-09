#!/usr/bin/env bash
# Run the directed testbench against BOTH the stock upstream upsizer and the
# patched one, then diff the results check by check.
#
#   ./run_both.sh                 # run what is needed, then compare
#   MAXREADS=24 ./run_both.sh     # at the ZCU102 dram_wrapper value
#   ./run_both.sh --compare-only  # just re-compare the logs already on disk
#   ./run_both.sh --force-stock   # re-run stock even if its log looks current
#
# The stock RTL never changes -- it is the upstream checkout. Its result is a
# baseline that goes stale for exactly one reason: the TESTBENCH changed. So
# the stock run is skipped automatically when its log is newer than the
# testbench and the file list, and re-run when it is not. That keeps the loop
# short while you iterate on the patch, and refuses to compare against a
# baseline produced by a different testbench.
#
# The number that matters is REGRESSIONS: checks that pass on stock and fail on
# patched. That count must be zero. "Fixed by the patch" is the headline, but a
# single regression outweighs any number of fixes.

set -uo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MAXREADS=${MAXREADS:-8}
SLVW=${SLVW:-64}
MSTW=${MSTW:-128}
STOCK_LOG="$HERE/xsim_stock_${MAXREADS}_${SLVW}to${MSTW}.log"
PATCH_LOG="$HERE/xsim_patched_${MAXREADS}_${SLVW}to${MSTW}.log"

# Show progress. The full transcript still goes to the .log files via the
# tee inside run_xsim.sh; here we surface only the lines worth watching, live.
KEEP='^(=== |>>> )|GEOMETRY:|TEST [0-9]+:|\[(PASS|FAIL)\]|\[CHK\]|RESULT:|FATAL_ERROR|WATCHDOG|ERROR:'

run_phase () {
  local label="$1"; shift
  local t0=$SECONDS
  echo
  echo "############################################################"
  echo "#  $label"
  echo "############################################################"
  ( "$@" 2>&1 | grep --line-buffered -E "$KEEP" ) || true
  echo "#  $label finished in $((SECONDS - t0))s"
}

# The stock baseline is invalidated by testbench changes, nothing else.
TB_DEPS=("$HERE/tb_axi_dw_upsizer_sameid.sv" "$HERE/filelist.f")

stock_is_stale () {
  [ -f "$STOCK_LOG" ] || return 0
  grep -q 'RESULT:' "$STOCK_LOG" 2>/dev/null || return 0   # previous run died
  local d
  for d in "${TB_DEPS[@]}"; do
    [ -e "$d" ] && [ "$d" -nt "$STOCK_LOG" ] && return 0
  done
  return 1
}

MODE=${1:-}
if [ "$MODE" != "--compare-only" ]; then
  if [ "$MODE" = "--force-stock" ] || stock_is_stale; then
    run_phase "STOCK  ${SLVW}->${MSTW}" \
      env MAXREADS=$MAXREADS SLVW=$SLVW MSTW=$MSTW "$HERE/run_xsim.sh"
  else
    echo
    echo "############################################################"
    echo "#  STOCK  ${SLVW}->${MSTW}: reusing $(basename "$STOCK_LOG")"
    echo "#  (testbench unchanged since that baseline was produced)"
    echo "############################################################"
  fi
  run_phase "PATCHED  ${SLVW}->${MSTW}" \
    env PATCH=1 MAXREADS=$MAXREADS SLVW=$SLVW MSTW=$MSTW "$HERE/run_xsim.sh"
fi

for f in "$STOCK_LOG" "$PATCH_LOG"; do
  [ -f "$f" ] || { echo "*** missing log: $f"; exit 1; }
done

python3 - "$STOCK_LOG" "$PATCH_LOG" <<'PY'
import re, sys, collections

def parse(path):
    """Return {(test, check): (verdict, detail)} plus a list of anomalies."""
    res, order, notes = {}, [], []
    test = "(before any test)"
    with open(path, errors="ignore") as fh:
        for line in fh:
            line = line.rstrip("\n")
            m = re.match(r'\s*(TEST \d+):', line)
            if m:
                test = m.group(1)
                continue
            m = re.match(r'\s*\[(PASS|FAIL)\]\s+(.*?)(?:\s+--\s+(.*))?$', line)
            if m:
                key = (test, m.group(2).strip())
                if key not in res:                 # keep first, logs can echo
                    res[key] = (m.group(1), (m.group(3) or "").strip())
                    order.append(key)
                continue
            if "FATAL_ERROR" in line or "WATCHDOG" in line:
                notes.append(line.strip()[:100])
            m = re.search(r'\[CHK\]', line)
            if m:
                notes.append(line.strip()[:100])
    return res, order, notes

stock, order_s, notes_s = parse(sys.argv[1])
patch, order_p, notes_p = parse(sys.argv[2])

# Preserve the patched run's ordering, then append anything only stock saw.
order = order_p + [k for k in order_s if k not in patch]

W = 62
print()
print("=" * (W + 20))
print(f"{'CHECK':<{W}} {'STOCK':>7} {'PATCHED':>9}")
print("=" * (W + 20))

fixed = regressed = both_pass = both_fail = 0
cur_test = None
for key in order:
    test, name = key
    if test != cur_test:
        print(f"\n-- {test}")
        cur_test = test
    sv = stock.get(key, ("--",""))[0]
    pv = patch.get(key, ("--",""))[0]
    label = name if len(name) <= W-2 else name[:W-5] + "..."
    mark = ""
    if sv == "FAIL" and pv == "PASS":
        fixed += 1;     mark = "  <-- fixed"
    elif sv == "PASS" and pv == "FAIL":
        regressed += 1; mark = "  <== REGRESSION"
    elif sv == "PASS" and pv == "PASS":
        both_pass += 1
    elif sv == "FAIL" and pv == "FAIL":
        both_fail += 1; mark = "  (fails in both)"
    print(f"  {label:<{W-2}} {sv:>7} {pv:>9}{mark}")

print()
print("=" * (W + 20))
print(f"  fixed by the patch      : {fixed}")
print(f"  unchanged, passing      : {both_pass}")
print(f"  failing in both         : {both_fail}")
print(f"  REGRESSIONS             : {regressed}   <-- must be 0")
print("=" * (W + 20))

for tag, notes in (("stock", notes_s), ("patched", notes_p)):
    if notes:
        print(f"\n  anomalies in the {tag} log ({len(notes)}):")
        for n in notes[:12]:
            print("    " + n)
        if len(notes) > 12:
            print(f"    ... and {len(notes)-12} more")

print()
if regressed:
    print("  VERDICT: the patch BREAKS something that worked. Do not build it.")
elif both_fail:
    print("  VERDICT: no regression, but checks still fail in both. Read them:")
    print("           a check failing in BOTH is either an untouched limitation")
    print("           or a testbench bug -- not evidence for the patch.")
elif fixed:
    print("  VERDICT: no regression, and the patch fixes what it claims.")
else:
    print("  VERDICT: nothing changed. Did PATCH=1 actually take effect?")
print()
PY
