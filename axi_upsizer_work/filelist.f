# Compile list for tb_axi_dw_upsizer_sameid.
#
# Paths are relative to CHECKOUTS (see run_xsim.sh / run_vsim.sh), which
# defaults to the Cheshire tree's .bender/git/checkouts.
#
# NB the upsizer is NOT self-contained: besides lzc / onehot_to_bin /
# rr_arb_tree it instantiates axi_err_slv (:185) and axi_demux (:208), which
# drag in axi_atop_filter, axi_demux_simple, fifo_v3, spill_register,
# stream_register and counter. This list is the full transitive closure,
# packages first.
#
# Two include directories are required:
#   axi/include          (axi/typedef.svh, axi/assign.svh)
#   common_cells/include (common_cells/registers.svh, assertions.svh)

# --- packages ---
axi-ecdc900686449c15/src/axi_pkg.sv
common_cells-7f7ae0f5e6bf7fb5/src/cf_math_pkg.sv

# --- common_cells leaves ---
common_cells-7f7ae0f5e6bf7fb5/src/lzc.sv
common_cells-7f7ae0f5e6bf7fb5/src/onehot_to_bin.sv
common_cells-7f7ae0f5e6bf7fb5/src/delta_counter.sv
common_cells-7f7ae0f5e6bf7fb5/src/counter.sv
common_cells-7f7ae0f5e6bf7fb5/src/fifo_v3.sv
common_cells-7f7ae0f5e6bf7fb5/src/spill_register_flushable.sv
common_cells-7f7ae0f5e6bf7fb5/src/spill_register.sv
common_cells-7f7ae0f5e6bf7fb5/src/stream_register.sv
common_cells-7f7ae0f5e6bf7fb5/src/rr_arb_tree.sv

# --- axi ---
axi-ecdc900686449c15/src/axi_atop_filter.sv
axi-ecdc900686449c15/src/axi_err_slv.sv
axi-ecdc900686449c15/src/axi_demux_simple.sv
axi-ecdc900686449c15/src/axi_demux.sv
axi-ecdc900686449c15/src/axi_dw_upsizer.sv
