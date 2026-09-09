#!/usr/bin/env bash
# Run the directed same-ID upsizer testbench under Questa / ModelSim.
#
# NOTE (2026-09-09): Questa is NOT currently installed on this laptop.  The
# licence is valid (LR-270178, node-locked to wlp43s0, expires 26-Nov-2026) and
# ~/.bashrc:160 puts ~/altera/25.1std/questa_fse/bin on PATH, but that directory
# does not exist -- see AGENT_NOTES_FP16_4LANE.md section 52.8.  Reinstall, or
# use run_xsim.sh on the server.
#
#   ./run_vsim.sh                 # default: AxiMaxReads=8
#   MAXREADS=24 ./run_vsim.sh
#
# Expected on the UNFIXED RTL: TEST 1 fails with 1 AR issued instead of 4.

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CHECKOUTS=${CHECKOUTS:-$HERE/../.bender/git/checkouts}
AXI_INC=${AXI_INC:-$CHECKOUTS/axi-ecdc900686449c15/include}
CC_INC=${CC_INC:-$CHECKOUTS/common_cells-7f7ae0f5e6bf7fb5/include}
MAXREADS=${MAXREADS:-8}
TOP=tb_axi_dw_upsizer_sameid
WORK=${WORK:-$HERE/vsim_work}
VLOG=${VLOG:-vlog}
VSIM=${VSIM:-vsim}
VLIB=${VLIB:-vlib}

command -v "$VLOG" >/dev/null 2>&1 || {
  echo "*** '$VLOG' not on PATH -- Questa does not appear to be installed."
  echo "*** See the header of this script, or use run_xsim.sh on the server."
  exit 1
}

[ -d "$CHECKOUTS" ] || { echo "*** CHECKOUTS not found: $CHECKOUTS"; exit 1; }

rm -rf "$WORK"; mkdir -p "$WORK"; cd "$WORK"

SRCS=()
while read -r line; do
  line="${line%%#*}"; line="$(echo "$line" | xargs)"
  [ -z "$line" ] && continue
  SRCS+=("$CHECKOUTS/$line")
done < "$HERE/filelist.f"
SRCS+=("$HERE/$TOP.sv")

# PATCH=1 swaps in the fixed upsizer from patched/ and pulls in id_queue,
# which the fix instantiates. PATCH unset runs the stock upstream RTL.
if [ "${PATCH:-0}" = "1" ]; then
  NEW=()
  for f in "${SRCS[@]}"; do
    case "$f" in
      */axi_dw_upsizer.sv)
        NEW+=("$CHECKOUTS/common_cells-7f7ae0f5e6bf7fb5/src/id_queue.sv")
        NEW+=("$HERE/patched/axi_dw_upsizer.sv") ;;
      *) NEW+=("$f") ;;
    esac
  done
  SRCS=("${NEW[@]}")
  TAG="patched"
  echo ">>> PATCHED upsizer (patched/axi_dw_upsizer.sv) + id_queue"
else
  TAG="stock"
  echo ">>> stock upstream upsizer"
fi

"$VLIB" work

echo "=== vlog (${#SRCS[@]} files) ==="
"$VLOG" -sv +incdir+"$AXI_INC" +incdir+"$CC_INC" -suppress 2583 "${SRCS[@]}"

echo "=== vsim (AxiMaxReads=$MAXREADS) ==="
"$VSIM" -c -voptargs=+acc \
        -G/${TOP}/TbAxiMaxReads=$MAXREADS \
        "$TOP" -do "run -all; quit -f" | tee "$HERE/vsim_${TAG}_${MAXREADS}.log"

echo
echo "log: $HERE/vsim_${TAG}_${MAXREADS}.log"
