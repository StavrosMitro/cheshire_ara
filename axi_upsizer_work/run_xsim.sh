#!/usr/bin/env bash
# Run the directed same-ID upsizer testbench under Vivado XSim.
#
# XSim ships with the full Vivado on the server (vitis-2021.1); Vivado_Lab has
# no simulator at all, so this will not run on the laptop as it stands today.
# Source the Vivado settings first, exactly as for a bitstream build.
#
#   ./run_xsim.sh                 # default: AxiMaxReads=8
#   MAXREADS=24 ./run_xsim.sh     # match the ZCU102 dram_wrapper setting
#
# Expected on the UNFIXED RTL: TEST 1 fails with 1 AR issued instead of 4.

set -euo pipefail

HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CHECKOUTS=${CHECKOUTS:-$HERE/../.bender/git/checkouts}
AXI_INC=${AXI_INC:-$CHECKOUTS/axi-ecdc900686449c15/include}
CC_INC=${CC_INC:-$CHECKOUTS/common_cells-7f7ae0f5e6bf7fb5/include}
MAXREADS=${MAXREADS:-8}
SLVW=${SLVW:-64}       # narrow side (LLC)
MSTW=${MSTW:-128}      # wide side (PS HP0)
TOP=tb_axi_dw_upsizer_sameid
WORK=${WORK:-$HERE/xsim_work}

for t in xvlog xelab xsim; do
  command -v "$t" >/dev/null 2>&1 || {
    echo "*** '$t' not on PATH. Source the Vivado settings first, e.g."
    echo "***   source /tools/Xilinx/Vivado/2021.1/settings64.sh"
    exit 1
  }
done

[ -d "$CHECKOUTS" ] || { echo "*** CHECKOUTS not found: $CHECKOUTS"; exit 1; }

rm -rf "$WORK"; mkdir -p "$WORK"; cd "$WORK"

# Build the source list, resolving filelist.f against CHECKOUTS.
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

echo "=== xvlog (${#SRCS[@]} files) ==="
# -d XSIM: common_cells guards its `default disable iff` with `ifndef XSIM`
# precisely because XSim does not support that construct (rr_arb_tree.sv:117).
# This keeps the $onehot0 assertion in onehot_to_bin alive -- that one is
# guarded only by SYNTHESIS/COMMON_CELLS_ASSERTS_OFF, and it is worth having:
# it fires exactly when a fix produces multiple same-ID matches.
# If XSim also rejects `assert final`, fall back to:
#   DEFS="-d XSIM -d COMMON_CELLS_ASSERTS_OFF" ./run_xsim.sh
# and rely on this testbench's address-derived payload check instead.
DEFS=${DEFS:--d XSIM}

xvlog -sv $DEFS -i "$AXI_INC" -i "$CC_INC" "${SRCS[@]}"

# -debug typical builds a full signal database. The earlier runs showed
# cpu = 2 s against elapsed = 4 min 19 s -- essentially all of it writing that
# database, not simulating. We only need pass/fail, so default to no debug.
# Set XELAB_DEBUG=typical when you actually want to look at waveforms.
XELAB_DEBUG=${XELAB_DEBUG:-off}

echo "=== xelab ($SLVW->$MSTW, AxiMaxReads=$MAXREADS, debug=$XELAB_DEBUG) ==="
xelab -debug "$XELAB_DEBUG" \
      -generic_top "TbAxiMaxReads=$MAXREADS" \
      -generic_top "TbSlvDataWidth=$SLVW" \
      -generic_top "TbMstDataWidth=$MSTW" \
      -s ${TOP}_snap "$TOP"

echo "=== xsim ==="
xsim ${TOP}_snap -runall | tee "$HERE/xsim_${TAG}_${MAXREADS}_${SLVW}to${MSTW}.log"

echo
echo "log: $HERE/xsim_${TAG}_${MAXREADS}_${SLVW}to${MSTW}.log"
