#!/usr/bin/env bash
# Sweep the width pairs we could plausibly build, stock vs patched.
#
#   ./run_sweep.sh                # both pairs at MaxReads=24
#   MAXREADS=8 ./run_sweep.sh     # faster smoke run
#
# Only two pairs, deliberately.
#
#   64 -> 128   the ONLY converter instantiated in the SoC: the 2-lane build's
#               LLC (SocDataWidth=64) into the PS HP0 port (128 b). At 4 lanes
#               the widths match and the converter collapses to wires.
#   128 -> 256  same 2:1 ratio at double the absolute widths. Not a
#               configuration we build; it is there to catch arithmetic in the
#               lane steering and address offsets that only shows up at wider
#               buses.
#
# The upstream regression sweeps 36 combinations (8..1024 on each side). That
# matters for a pull request against pulp-platform/axi, not for this bitstream.
# See AGENT_NOTES_FP16_4LANE.md 53.12.

set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MAXREADS=${MAXREADS:-24}

PAIRS=("64 128" "128 256")

overall=0
for pair in "${PAIRS[@]}"; do
  set -- $pair
  slvw=$1; mstw=$2
  echo
  echo "################################################################"
  echo "#  WIDTH PAIR  ${slvw} -> ${mstw}   (AxiMaxReads=${MAXREADS})"
  echo "################################################################"
  SLVW=$slvw MSTW=$mstw MAXREADS=$MAXREADS "$HERE/run_both.sh"
  rc=$?
  [ $rc -eq 0 ] || overall=$rc
done

echo
echo "################################################################"
echo "#  SWEEP SUMMARY"
echo "################################################################"
for pair in "${PAIRS[@]}"; do
  set -- $pair
  slvw=$1; mstw=$2
  sl="$HERE/xsim_stock_${MAXREADS}_${slvw}to${mstw}.log"
  pl="$HERE/xsim_patched_${MAXREADS}_${slvw}to${mstw}.log"
  sres=$(grep -h 'RESULT:' "$sl" 2>/dev/null | head -1 | sed 's/^ *//')
  pres=$(grep -h 'RESULT:' "$pl" 2>/dev/null | head -1 | sed 's/^ *//')
  printf "  %4s -> %-4s  stock  : %s\n" "$slvw" "$mstw" "${sres:-<no result, run did not finish>}"
  printf "  %4s -> %-4s  patched: %s\n" "$slvw" "$mstw" "${pres:-<no result, run did not finish>}"
  echo
done

echo "  A patched run must show 'all N checks PASSED' for BOTH pairs."
echo "  Stock is expected to fail the same-ID checks in both -- that is the bug."
exit $overall
