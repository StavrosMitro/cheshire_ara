#!/usr/bin/env bash
# Out-of-context synthesis of axi_dw_upsizer, stock vs patched, and the delta.
#
#   ./run_synth.sh                      # 64->128, MaxReads=24, 20 ns
#   MAXREADS=8 ./run_synth.sh
#   SLVW=128 MSTW=256 ./run_synth.sh
#   PERIOD=10 ./run_synth.sh            # tighter clock, to see where it breaks
#   ./run_synth.sh --compare-only       # re-read the reports already on disk
#
# Needs the FULL Vivado (server). Vivado_Lab has no synthesiser.
#
# WHAT THIS ANSWERS
#   the AREA COST of the fix: id_queue added, one onehot_to_bin removed.
#
# WHAT IT DOES NOT ANSWER
#   real timing closure. Out of context there are no paths to the LLC, the
#   IW converter or the CDC, and no placement. Treat WNS here as a smoke test,
#   not as a result. Closure is decided by the full build.

set -uo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SYNTH="$HERE/synth"
CHECKOUTS=${CHECKOUTS:-$HERE/../.bender/git/checkouts}
AXI_INC=${AXI_INC:-$CHECKOUTS/axi-ecdc900686449c15/include}
CC_INC=${CC_INC:-$CHECKOUTS/common_cells-7f7ae0f5e6bf7fb5/include}

PART=${PART:-xczu9eg-ffvb1156-2-e}    # ZCU102, target/xilinx/scripts/common.tcl:20
PERIOD=${PERIOD:-20}                  # ns; the SoC runs off clkwiz clk_50
MAXREADS=${MAXREADS:-24}              # dram_wrapper_xilinx.sv:121
SLVW=${SLVW:-64}
MSTW=${MSTW:-128}

OUT="$HERE/synth_out/${SLVW}to${MSTW}_mr${MAXREADS}"

build_srcs () {   # $1 = stock|patched  -> prints the file list
  local variant=$1
  while read -r line; do
    line="${line%%#*}"; line="$(echo "$line" | xargs)"
    [ -z "$line" ] && continue
    case "$line" in
      */axi_dw_upsizer.sv)
        if [ "$variant" = patched ]; then
          echo "$CHECKOUTS/common_cells-7f7ae0f5e6bf7fb5/src/id_queue.sv"
          echo "$HERE/patched/axi_dw_upsizer.sv"
        else
          echo "$CHECKOUTS/$line"
        fi ;;
      *) echo "$CHECKOUTS/$line" ;;
    esac
  done < "$HERE/filelist.f"
  echo "$SYNTH/synth_wrap_upsizer.sv"
}

run_one () {
  local variant=$1
  local outdir="$OUT/$variant"
  echo
  echo "############################################################"
  echo "#  SYNTH $variant   ${SLVW}->${MSTW}  MaxReads=$MAXREADS  ${PERIOD}ns"
  echo "############################################################"
  rm -rf "$outdir"; mkdir -p "$outdir"
  local srcs; mapfile -t srcs < <(build_srcs "$variant")
  local t0=$SECONDS
  ( cd "$outdir" && vivado -mode batch -nojournal -notrace \
      -log vivado.log \
      -source "$SYNTH/synth_ooc.tcl" \
      -tclargs "$outdir" "$PART" "$PERIOD" "$MAXREADS" "$SLVW" "$MSTW" \
               "$AXI_INC" "$CC_INC" "${srcs[@]}" ) \
    2>&1 | grep --line-buffered -E '^###|^ERROR|^CRITICAL|Synthesis finished|WNS' || true
  echo "#  $variant finished in $((SECONDS-t0))s"
}

if [ "${1:-}" != "--compare-only" ]; then
  command -v vivado >/dev/null 2>&1 || {
    echo "*** 'vivado' not on PATH. Source the settings first, e.g."
    echo "***   source /opt/Xilinx/Vivado/2021.1/settings64.sh"
    exit 1
  }
  run_one stock
  run_one patched
fi

python3 - "$OUT" <<'PY'
import os, re, sys
out = sys.argv[1]

def grab(path):
    """Pull the headline resource counts out of a Vivado utilization report."""
    vals = {}
    if not os.path.exists(path):
        return None
    rows = {
        "LUTs"      : r"CLB LUTs\*?",
        "Registers" : r"CLB Registers",
        "LUTRAM"    : r"LUT as Memory",
        "SRL"       : r"LUT as Shift Register",
        "BRAM"      : r"Block RAM Tile",
        "DSP"       : r"DSPs",
    }
    txt = open(path, errors="ignore").read()
    for name, pat in rows.items():
        m = re.search(r"\|\s*" + pat + r"\s*\|\s*(\d+)\s*\|", txt)
        if m:
            vals[name] = int(m.group(1))
    return vals

def wns(path):
    if not os.path.exists(path):
        return None
    m = re.search(r"WNS\(ns\).*?\n.*?\n\s*(-?[\d.]+)", open(path, errors="ignore").read())
    return m.group(1) if m else None

rows = []
for name, fn in (("whole wrapper", "utilization.rpt"), ("DUT only", "dut_only.rpt")):
    s = grab(os.path.join(out, "stock",   fn))
    p = grab(os.path.join(out, "patched", fn))
    rows.append((name, s, p))

print()
print("=" * 68)
print(f"  OOC SYNTHESIS  {os.path.basename(out)}")
print("=" * 68)

missing = False
for name, s, p in rows:
    print(f"\n-- {name}")
    if not s or not p:
        print("   (report missing -- did synthesis fail? check synth_out/*/vivado.log)")
        missing = True
        continue
    print(f"   {'resource':<14}{'stock':>10}{'patched':>10}{'delta':>10}{'':>4}")
    for k in ("LUTs", "Registers", "LUTRAM", "SRL", "BRAM", "DSP"):
        if k in s or k in p:
            a, b = s.get(k, 0), p.get(k, 0)
            d = b - a
            pct = f"{100.0*d/a:+.1f}%" if a else ""
            print(f"   {k:<14}{a:>10}{b:>10}{d:>+10}  {pct}")

sw = wns(os.path.join(out, "stock",   "timing.rpt"))
pw = wns(os.path.join(out, "patched", "timing.rpt"))
if sw or pw:
    print(f"\n-- OOC WNS (indicative only, no real placement)")
    print(f"   stock {sw}   patched {pw}")

print()
print("  Read the DELTA, not the absolute numbers: the wrapper's shift register")
print("  and XOR tree are counted too, and are identical in both builds.")
print("  For scale, the real 2-lane bitstream spends 10,644 LUTs on this")
print("  converter (bitstream_archive L2_V2048 utilization report).")
if missing:
    print("\n  *** at least one report is missing -- the comparison is incomplete")
print()
PY
