# This script was generated automatically by bender.
set ROOT "/home/smitropoulos/cheshire_soc"

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/tech_cells_generic-223c43ccbeb688f9/src/fpga/pad_functional_xilinx.sv \
    $ROOT/.bender/git/checkouts/tech_cells_generic-223c43ccbeb688f9/src/fpga/tc_clk_xilinx.sv \
    $ROOT/.bender/git/checkouts/tech_cells_generic-223c43ccbeb688f9/src/fpga/tc_sram_xilinx.sv \
    $ROOT/.bender/git/checkouts/tech_cells_generic-223c43ccbeb688f9/src/rtl/tc_sram_impl.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/tech_cells_generic-223c43ccbeb688f9/src/deprecated/pulp_clock_gating_async.sv \
    $ROOT/.bender/git/checkouts/tech_cells_generic-223c43ccbeb688f9/src/deprecated/cluster_clk_cells.sv \
    $ROOT/.bender/git/checkouts/tech_cells_generic-223c43ccbeb688f9/src/deprecated/pulp_clk_cells.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/binary_to_gray.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/cb_filter_pkg.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/cc_onehot.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/cdc_reset_ctrlr_pkg.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/cf_math_pkg.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/clk_int_div.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/delta_counter.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/ecc_pkg.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/edge_propagator_tx.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/exp_backoff.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/fifo_v3.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/gray_to_binary.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/isochronous_4phase_handshake.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/isochronous_spill_register.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/lfsr.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/lfsr_16bit.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/lfsr_8bit.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/lossy_valid_to_stream.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/mv_filter.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/onehot_to_bin.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/plru_tree.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/passthrough_stream_fifo.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/popcount.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/rr_arb_tree.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/rstgen_bypass.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/serial_deglitch.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/shift_reg.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/shift_reg_gated.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/spill_register_flushable.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_demux.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_filter.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_fork.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_intf.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_join_dynamic.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_mux.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_throttle.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/sub_per_hash.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/sync.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/sync_wedge.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/unread.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/read.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/addr_decode_dync.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/cdc_2phase.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/cdc_4phase.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/clk_int_div_static.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/addr_decode.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/addr_decode_napot.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/multiaddr_decode.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/cb_filter.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/cdc_fifo_2phase.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/clk_mux_glitch_free.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/counter.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/ecc_decode.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/ecc_encode.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/edge_detect.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/lzc.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/max_counter.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/rstgen.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/spill_register.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_delay.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_fifo.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_fork_dynamic.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_join.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/cdc_reset_ctrlr.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/cdc_fifo_gray.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/fall_through_register.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/id_queue.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_to_mem.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_arbiter_flushable.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_fifo_optimal_wrap.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_register.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_xbar.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/cdc_fifo_gray_clearable.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/cdc_2phase_clearable.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/mem_to_banks_detailed.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_arbiter.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/stream_omega_net.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/mem_to_banks.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/deprecated/clock_divider_counter.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/deprecated/clk_div.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/deprecated/find_first_one.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/deprecated/generic_LFSR_8bit.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/deprecated/generic_fifo.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/deprecated/prioarbiter.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/deprecated/pulp_sync.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/deprecated/pulp_sync_wedge.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/deprecated/rrarbiter.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/deprecated/clock_divider.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/deprecated/fifo_v2.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/deprecated/fifo_v1.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/edge_propagator_ack.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/edge_propagator.sv \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/src/edge_propagator_rx.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-33e0a4fc0dc853c1/hdl/defs_div_sqrt_mvp.sv \
    $ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-33e0a4fc0dc853c1/hdl/iteration_div_sqrt_mvp.sv \
    $ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-33e0a4fc0dc853c1/hdl/control_mvp.sv \
    $ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-33e0a4fc0dc853c1/hdl/norm_div_sqrt_mvp.sv \
    $ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-33e0a4fc0dc853c1/hdl/preprocess_mvp.sv \
    $ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-33e0a4fc0dc853c1/hdl/nrbd_nrsc_mvp.sv \
    $ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-33e0a4fc0dc853c1/hdl/div_sqrt_top_mvp.sv \
    $ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-33e0a4fc0dc853c1/hdl/div_sqrt_mvp_wrapper.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/apb-521b279a5c028536/src/apb_pkg.sv \
    $ROOT/.bender/git/checkouts/apb-521b279a5c028536/src/apb_intf.sv \
    $ROOT/.bender/git/checkouts/apb-521b279a5c028536/src/apb_err_slv.sv \
    $ROOT/.bender/git/checkouts/apb-521b279a5c028536/src/apb_regs.sv \
    $ROOT/.bender/git/checkouts/apb-521b279a5c028536/src/apb_cdc.sv \
    $ROOT/.bender/git/checkouts/apb-521b279a5c028536/src/apb_demux.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_pkg.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_intf.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_atop_filter.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_burst_splitter.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_bus_compare.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_cdc_dst.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_cdc_src.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_cut.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_delayer.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_demux_simple.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_dw_downsizer.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_dw_upsizer.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_fifo.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_id_remap.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_id_prepend.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_isolate.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_join.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_lite_demux.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_lite_dw_converter.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_lite_from_mem.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_lite_join.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_lite_lfsr.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_lite_mailbox.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_lite_mux.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_lite_regs.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_lite_to_apb.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_lite_to_axi.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_modify_address.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_mux.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_rw_join.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_rw_split.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_serializer.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_slave_compare.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_throttle.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_to_detailed_mem.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_cdc.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_demux.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_err_slv.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_dw_converter.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_from_mem.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_id_serialize.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_lfsr.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_multicut.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_to_axi_lite.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_to_mem.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_zero_mem.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_interleaved_xbar.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_iw_converter.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_lite_xbar.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_xbar.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_to_mem_banked.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_to_mem_interleaved.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_to_mem_split.sv \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/src/axi_xp.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/fpnew-4306b9caf058dae1/src/fpnew_pkg.sv \
    $ROOT/.bender/git/checkouts/fpnew-4306b9caf058dae1/src/fpnew_cast_multi.sv \
    $ROOT/.bender/git/checkouts/fpnew-4306b9caf058dae1/src/fpnew_classifier.sv \
    $ROOT/.bender/git/checkouts/fpnew-4306b9caf058dae1/src/fpnew_divsqrt_multi.sv \
    $ROOT/.bender/git/checkouts/fpnew-4306b9caf058dae1/src/fpnew_fma.sv \
    $ROOT/.bender/git/checkouts/fpnew-4306b9caf058dae1/src/fpnew_fma_multi.sv \
    $ROOT/.bender/git/checkouts/fpnew-4306b9caf058dae1/src/fpnew_noncomp.sv \
    $ROOT/.bender/git/checkouts/fpnew-4306b9caf058dae1/src/fpnew_opgroup_block.sv \
    $ROOT/.bender/git/checkouts/fpnew-4306b9caf058dae1/src/fpnew_opgroup_fmt_slice.sv \
    $ROOT/.bender/git/checkouts/fpnew-4306b9caf058dae1/src/fpnew_opgroup_multifmt_slice.sv \
    $ROOT/.bender/git/checkouts/fpnew-4306b9caf058dae1/src/fpnew_rounding.sv \
    $ROOT/.bender/git/checkouts/fpnew-4306b9caf058dae1/src/fpnew_top.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/cva6_patched/core/include/config_pkg.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/cva6_patched/core/include/cv64a6_imafdcv_sv39_config_pkg.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/cva6_patched/core/include/riscv_pkg.sv \
    $ROOT/cva6_patched/core/include/ariane_pkg.sv \
    $ROOT/cva6_patched/core/include/build_config_pkg.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/cva6_patched/core/cva6_mmu/cva6_tlb.sv \
    $ROOT/cva6_patched/core/cva6_mmu/cva6_shared_tlb.sv \
    $ROOT/cva6_patched/core/cva6_mmu/cva6_mmu.sv \
    $ROOT/cva6_patched/core/cva6_mmu/cva6_ptw.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/cva6_patched/core/include/wt_cache_pkg.sv \
    $ROOT/cva6_patched/core/include/std_cache_pkg.sv \
    $ROOT/cva6_patched/core/cvxif_example/include/cvxif_instr_pkg.sv \
    $ROOT/cva6_patched/core/cvxif_fu.sv \
    $ROOT/cva6_patched/core/cvxif_issue_register_commit_if_driver.sv \
    $ROOT/cva6_patched/core/cvxif_compressed_if_driver.sv \
    $ROOT/cva6_patched/core/cvxif_example/cvxif_example_coprocessor.sv \
    $ROOT/cva6_patched/core/cvxif_example/instr_decoder.sv \
    $ROOT/cva6_patched/core/cva6_rvfi_probes.sv \
    $ROOT/cva6_patched/core/cva6_fifo_v3.sv \
    $ROOT/cva6_patched/core/cva6.sv \
    $ROOT/cva6_patched/core/alu.sv \
    $ROOT/cva6_patched/core/fpu_wrap.sv \
    $ROOT/cva6_patched/core/branch_unit.sv \
    $ROOT/cva6_patched/core/compressed_decoder.sv \
    $ROOT/cva6_patched/core/controller.sv \
    $ROOT/cva6_patched/core/csr_buffer.sv \
    $ROOT/cva6_patched/core/csr_regfile.sv \
    $ROOT/cva6_patched/core/decoder.sv \
    $ROOT/cva6_patched/core/ex_stage.sv \
    $ROOT/cva6_patched/core/acc_dispatcher.sv \
    $ROOT/cva6_patched/core/instr_realign.sv \
    $ROOT/cva6_patched/core/id_stage.sv \
    $ROOT/cva6_patched/core/issue_read_operands.sv \
    $ROOT/cva6_patched/core/issue_stage.sv \
    $ROOT/cva6_patched/core/load_unit.sv \
    $ROOT/cva6_patched/core/load_store_unit.sv \
    $ROOT/cva6_patched/core/lsu_bypass.sv \
    $ROOT/cva6_patched/core/mult.sv \
    $ROOT/cva6_patched/core/multiplier.sv \
    $ROOT/cva6_patched/core/serdiv.sv \
    $ROOT/cva6_patched/core/perf_counters.sv \
    $ROOT/cva6_patched/core/ariane_regfile_ff.sv \
    $ROOT/cva6_patched/core/ariane_regfile_fpga.sv \
    $ROOT/cva6_patched/core/scoreboard.sv \
    $ROOT/cva6_patched/core/store_buffer.sv \
    $ROOT/cva6_patched/core/amo_buffer.sv \
    $ROOT/cva6_patched/core/store_unit.sv \
    $ROOT/cva6_patched/core/commit_stage.sv \
    $ROOT/cva6_patched/core/axi_shim.sv \
    $ROOT/cva6_patched/core/frontend/btb.sv \
    $ROOT/cva6_patched/core/frontend/bht.sv \
    $ROOT/cva6_patched/core/frontend/ras.sv \
    $ROOT/cva6_patched/core/frontend/instr_scan.sv \
    $ROOT/cva6_patched/core/frontend/instr_queue.sv \
    $ROOT/cva6_patched/core/frontend/frontend.sv \
    $ROOT/cva6_patched/core/cache_subsystem/wt_dcache_ctrl.sv \
    $ROOT/cva6_patched/core/cache_subsystem/wt_dcache_mem.sv \
    $ROOT/cva6_patched/core/cache_subsystem/wt_dcache_missunit.sv \
    $ROOT/cva6_patched/core/cache_subsystem/wt_dcache_wbuffer.sv \
    $ROOT/cva6_patched/core/cache_subsystem/wt_dcache.sv \
    $ROOT/cva6_patched/core/cache_subsystem/wt_cache_subsystem.sv \
    $ROOT/cva6_patched/core/cache_subsystem/wt_axi_adapter.sv \
    $ROOT/cva6_patched/core/cache_subsystem/cva6_icache.sv \
    $ROOT/cva6_patched/core/cache_subsystem/tag_cmp.sv \
    $ROOT/cva6_patched/core/cache_subsystem/cva6_icache_axi_wrapper.sv \
    $ROOT/cva6_patched/core/cache_subsystem/axi_adapter.sv \
    $ROOT/cva6_patched/core/cache_subsystem/miss_handler.sv \
    $ROOT/cva6_patched/core/cache_subsystem/cache_ctrl.sv \
    $ROOT/cva6_patched/core/cache_subsystem/std_nbdcache.sv \
    $ROOT/cva6_patched/core/cache_subsystem/std_cache_subsystem.sv \
    $ROOT/cva6_patched/core/pmp/src/pmp.sv \
    $ROOT/cva6_patched/core/pmp/src/pmp_entry.sv \
    $ROOT/cva6_patched/core/pmp/src/pmp_data_if.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/cva6_patched/common/local/util/sram.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/cva6_patched/common/local/util/sram_cache.sv \
    $ROOT/cva6_patched/common/local/util/tc_sram_fpga_wrapper.sv \
    $ROOT/cva6_patched/vendor/pulp-platform/fpga-support/rtl/SyncSpRamBeNx64.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/src/reg_intf.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/vendor/lowrisc_opentitan/src/prim_subreg_arb.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/vendor/lowrisc_opentitan/src/prim_subreg_ext.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/src/apb_to_reg.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/src/axi_lite_to_reg.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/src/axi_to_reg_v2.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/src/periph_to_reg.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/src/reg_cdc.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/src/reg_cut.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/src/reg_demux.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/src/reg_err_slv.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/src/reg_filter_empty_writes.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/src/reg_mux.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/src/reg_to_apb.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/src/reg_to_mem.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/src/reg_to_tlul.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/src/reg_to_axi.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/src/reg_uniform.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/vendor/lowrisc_opentitan/src/prim_subreg_shadow.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/vendor/lowrisc_opentitan/src/prim_subreg.sv \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/src/deprecated/axi_to_reg.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/apb_uart-38dcfab592cbc1a1/src/slib_clock_div.sv \
    $ROOT/.bender/git/checkouts/apb_uart-38dcfab592cbc1a1/src/slib_counter.sv \
    $ROOT/.bender/git/checkouts/apb_uart-38dcfab592cbc1a1/src/slib_edge_detect.sv \
    $ROOT/.bender/git/checkouts/apb_uart-38dcfab592cbc1a1/src/slib_fifo.sv \
    $ROOT/.bender/git/checkouts/apb_uart-38dcfab592cbc1a1/src/slib_input_filter.sv \
    $ROOT/.bender/git/checkouts/apb_uart-38dcfab592cbc1a1/src/slib_input_sync.sv \
    $ROOT/.bender/git/checkouts/apb_uart-38dcfab592cbc1a1/src/slib_mv_filter.sv \
    $ROOT/.bender/git/checkouts/apb_uart-38dcfab592cbc1a1/src/uart_baudgen.sv \
    $ROOT/.bender/git/checkouts/apb_uart-38dcfab592cbc1a1/src/uart_interrupt.sv \
    $ROOT/.bender/git/checkouts/apb_uart-38dcfab592cbc1a1/src/uart_receiver.sv \
    $ROOT/.bender/git/checkouts/apb_uart-38dcfab592cbc1a1/src/uart_transmitter.sv \
    $ROOT/.bender/git/checkouts/apb_uart-38dcfab592cbc1a1/src/apb_uart.sv \
    $ROOT/.bender/git/checkouts/apb_uart-38dcfab592cbc1a1/src/apb_uart_wrap.sv \
    $ROOT/.bender/git/checkouts/apb_uart-38dcfab592cbc1a1/src/reg_uart_wrap.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    /home/smitropoulos/ara_patched/hardware/include/rvv_pkg.sv \
    /home/smitropoulos/ara_patched/hardware/include/ara_pkg.sv \
    /home/smitropoulos/ara_patched/hardware/src/segment_sequencer.sv \
    /home/smitropoulos/ara_patched/hardware/src/ctrl_registers.sv \
    /home/smitropoulos/ara_patched/hardware/src/cva6_accel_first_pass_decoder.sv \
    /home/smitropoulos/ara_patched/hardware/src/ara_dispatcher.sv \
    /home/smitropoulos/ara_patched/hardware/src/ara_sequencer.sv \
    /home/smitropoulos/ara_patched/hardware/src/axi_inval_filter.sv \
    /home/smitropoulos/ara_patched/hardware/src/lane/lane_sequencer.sv \
    /home/smitropoulos/ara_patched/hardware/src/lane/operand_queue.sv \
    /home/smitropoulos/ara_patched/hardware/src/lane/operand_requester.sv \
    /home/smitropoulos/ara_patched/hardware/src/lane/simd_alu.sv \
    /home/smitropoulos/ara_patched/hardware/src/lane/simd_div.sv \
    /home/smitropoulos/ara_patched/hardware/src/lane/simd_mul.sv \
    /home/smitropoulos/ara_patched/hardware/src/lane/vector_regfile.sv \
    /home/smitropoulos/ara_patched/hardware/src/lane/power_gating_generic.sv \
    /home/smitropoulos/ara_patched/hardware/src/masku/masku_operands.sv \
    /home/smitropoulos/ara_patched/hardware/src/sldu/p2_stride_gen.sv \
    /home/smitropoulos/ara_patched/hardware/src/sldu/sldu_op_dp.sv \
    /home/smitropoulos/ara_patched/hardware/src/sldu/sldu.sv \
    /home/smitropoulos/ara_patched/hardware/src/vlsu/addrgen.sv \
    /home/smitropoulos/ara_patched/hardware/src/vlsu/vldu.sv \
    /home/smitropoulos/ara_patched/hardware/src/vlsu/vstu.sv \
    /home/smitropoulos/ara_patched/hardware/src/lane/operand_queues_stage.sv \
    /home/smitropoulos/ara_patched/hardware/src/lane/valu.sv \
    /home/smitropoulos/ara_patched/hardware/src/lane/vmfpu.sv \
    /home/smitropoulos/ara_patched/hardware/src/lane/fixed_p_rounding.sv \
    /home/smitropoulos/ara_patched/hardware/src/vlsu/vlsu.sv \
    /home/smitropoulos/ara_patched/hardware/src/masku/masku.sv \
    /home/smitropoulos/ara_patched/hardware/src/lane/vector_fus_stage.sv \
    /home/smitropoulos/ara_patched/hardware/src/lane/lane.sv \
    /home/smitropoulos/ara_patched/hardware/src/ara.sv \
    /home/smitropoulos/ara_patched/hardware/src/ara_system.sv \
    /home/smitropoulos/ara_patched/hardware/src/ara_soc.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/axi_llc_pkg.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/axi_llc_burst_cutter.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/axi_llc_data_way.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/axi_llc_merge_unit.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/axi_llc_read_unit.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/axi_llc_reg_pkg.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/axi_llc_reg_top.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/axi_llc_write_unit.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/eviction_refill/axi_llc_ax_master.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/eviction_refill/axi_llc_r_master.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/eviction_refill/axi_llc_w_master.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/hit_miss_detect/axi_llc_evict_box.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/hit_miss_detect/axi_llc_lock_box_bloom.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/hit_miss_detect/axi_llc_miss_counters.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/hit_miss_detect/axi_llc_tag_pattern_gen.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/axi_llc_chan_splitter.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/axi_llc_evict_unit.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/axi_llc_refill_unit.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/axi_llc_ways.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/hit_miss_detect/axi_llc_tag_store.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/axi_llc_config.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/axi_llc_hit_miss.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/axi_llc_top.sv \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/src/axi_llc_reg_wrap.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/axi_riscv_atomics-40ad8d2d0e0daa8b/src/axi_res_tbl.sv \
    $ROOT/.bender/git/checkouts/axi_riscv_atomics-40ad8d2d0e0daa8b/src/axi_riscv_amos_alu.sv \
    $ROOT/.bender/git/checkouts/axi_riscv_atomics-40ad8d2d0e0daa8b/src/axi_riscv_amos.sv \
    $ROOT/.bender/git/checkouts/axi_riscv_atomics-40ad8d2d0e0daa8b/src/axi_riscv_lrsc.sv \
    $ROOT/.bender/git/checkouts/axi_riscv_atomics-40ad8d2d0e0daa8b/src/axi_riscv_atomics.sv \
    $ROOT/.bender/git/checkouts/axi_riscv_atomics-40ad8d2d0e0daa8b/src/axi_riscv_lrsc_wrap.sv \
    $ROOT/.bender/git/checkouts/axi_riscv_atomics-40ad8d2d0e0daa8b/src/axi_riscv_amos_wrap.sv \
    $ROOT/.bender/git/checkouts/axi_riscv_atomics-40ad8d2d0e0daa8b/src/axi_riscv_atomics_wrap.sv \
    $ROOT/.bender/git/checkouts/axi_riscv_atomics-40ad8d2d0e0daa8b/src/axi_riscv_atomics_structs.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/axi_rt-7cef46f372eaf0fb/target/xilinx/src/axi_rt_unit_top_xilinx.sv \
    $ROOT/.bender/git/checkouts/axi_rt-7cef46f372eaf0fb/target/xilinx/src/axi_rt_unit_top_xilinx_ip.v \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/axi_vga-74c838b44ce780d5/src/axi_vga_reg_pkg.sv \
    $ROOT/.bender/git/checkouts/axi_vga-74c838b44ce780d5/src/axi_vga_reg_top.sv \
    $ROOT/.bender/git/checkouts/axi_vga-74c838b44ce780d5/src/axi_vga_timing_fsm.sv \
    $ROOT/.bender/git/checkouts/axi_vga-74c838b44ce780d5/src/axi_vga_fetcher.sv \
    $ROOT/.bender/git/checkouts/axi_vga-74c838b44ce780d5/src/axi_vga.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/clic-360fff7ce2d41116/src/clicint_reg_pkg.sv \
    $ROOT/.bender/git/checkouts/clic-360fff7ce2d41116/src/clicint_reg_top.sv \
    $ROOT/.bender/git/checkouts/clic-360fff7ce2d41116/src/mclic_reg_pkg.sv \
    $ROOT/.bender/git/checkouts/clic-360fff7ce2d41116/src/mclic_reg_top.sv \
    $ROOT/.bender/git/checkouts/clic-360fff7ce2d41116/src/clic_reg_adapter.sv \
    $ROOT/.bender/git/checkouts/clic-360fff7ce2d41116/src/clic_gateway.sv \
    $ROOT/.bender/git/checkouts/clic-360fff7ce2d41116/src/clic_target.sv \
    $ROOT/.bender/git/checkouts/clic-360fff7ce2d41116/src/clic_apb.sv \
    $ROOT/.bender/git/checkouts/clic-360fff7ce2d41116/src/clic.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/clint-de4a234303f657d0/src/clint_reg_pkg.sv \
    $ROOT/.bender/git/checkouts/clint-de4a234303f657d0/src/clint_reg_top.sv \
    $ROOT/.bender/git/checkouts/clint-de4a234303f657d0/src/clint.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/idma_patched/src/frontends/idma_transfer_id_gen.sv \
    $ROOT/idma_patched/src/idma_pkg.sv \
    $ROOT/idma_patched/src/idma_stream_fifo.sv \
    $ROOT/idma_patched/src/idma_buffer.sv \
    $ROOT/idma_patched/src/idma_error_handler.sv \
    $ROOT/idma_patched/src/idma_channel_coupler.sv \
    $ROOT/idma_patched/src/idma_axi_transport_layer.sv \
    $ROOT/idma_patched/src/idma_axi_lite_transport_layer.sv \
    $ROOT/idma_patched/src/idma_obi_transport_layer.sv \
    $ROOT/idma_patched/src/idma_legalizer.sv \
    $ROOT/idma_patched/src/idma_backend.sv \
    $ROOT/idma_patched/src/legacy/axi_dma_backend.sv \
    $ROOT/idma_patched/src/legacy/midends/idma_2D_midend.sv \
    $ROOT/idma_patched/src/midends/idma_nd_midend.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/idma_patched/src/frontends/register_32bit_2d/idma_reg32_2d_frontend_reg_pkg.sv \
    $ROOT/idma_patched/src/frontends/register_32bit_2d/idma_reg32_2d_frontend_reg_top.sv \
    $ROOT/idma_patched/src/frontends/register_32bit_2d/idma_reg32_2d_frontend.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/idma_patched/src/frontends/register_64bit/idma_reg64_frontend_reg_pkg.sv \
    $ROOT/idma_patched/src/frontends/register_64bit/idma_reg64_frontend_reg_top.sv \
    $ROOT/idma_patched/src/frontends/register_64bit/idma_reg64_frontend.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/idma_patched/src/frontends/register_64bit_2d/idma_reg64_2d_frontend_reg_pkg.sv \
    $ROOT/idma_patched/src/frontends/register_64bit_2d/idma_reg64_2d_frontend_reg_top.sv \
    $ROOT/idma_patched/src/frontends/register_64bit_2d/idma_reg64_2d_frontend.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/idma_patched/src/frontends/desc64/idma_desc64_reg_pkg.sv \
    $ROOT/idma_patched/src/frontends/desc64/idma_desc64_reg_top.sv \
    $ROOT/idma_patched/src/frontends/desc64/idma_desc64_shared_counter.sv \
    $ROOT/idma_patched/src/frontends/desc64/idma_desc64_reg_wrapper.sv \
    $ROOT/idma_patched/src/frontends/desc64/idma_desc64_top.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/idma_patched/src/systems/cva6_reg/dma_core_wrap.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/idma_patched/src/synth_wrapper/idma_backend_synth.sv \
    $ROOT/idma_patched/src/synth_wrapper/idma_lite_backend_synth.sv \
    $ROOT/idma_patched/src/synth_wrapper/idma_obi_backend_synth.sv \
    $ROOT/idma_patched/src/synth_wrapper/idma_nd_backend_synth.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/irq_router-376b3d113c15d0ef/rtl/irq_router_reg_pkg.sv \
    $ROOT/.bender/git/checkouts/irq_router-376b3d113c15d0ef/rtl/irq_router_reg_top.sv \
    $ROOT/.bender/git/checkouts/irq_router-376b3d113c15d0ef/rtl/irq_router.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/prim/prim_pulp_platform/prim_flop_2sync.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/prim/prim_pulp_platform/prim_flop_en.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/prim/rtl/prim_fifo_sync_cnt.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/prim/rtl/prim_util_pkg.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/prim/rtl/prim_max_tree.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/prim/rtl/prim_sync_reqack.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/prim/rtl/prim_sync_reqack_data.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/prim/rtl/prim_pulse_sync.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/prim/rtl/prim_packer_fifo.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/prim/rtl/prim_fifo_sync.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/prim/rtl/prim_filter_ctr.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/prim/rtl/prim_intr_hw.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/prim/rtl/prim_fifo_async.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/gpio/rtl/gpio_reg_pkg.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/i2c/rtl/i2c_reg_pkg.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/rv_plic/rtl/rv_plic_reg_pkg.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/spi_host/rtl/spi_host_reg_pkg.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/gpio/rtl/gpio_reg_top.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/i2c/rtl/i2c_reg_top.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/rv_plic/rtl/rv_plic_reg_top.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/spi_host/rtl/spi_host_reg_top.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/i2c/rtl/i2c_pkg.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/i2c/rtl/i2c_fsm.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/rv_plic/rtl/rv_plic_gateway.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/spi_host/rtl/spi_host_byte_merge.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/spi_host/rtl/spi_host_byte_select.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/spi_host/rtl/spi_host_cmd_pkg.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/spi_host/rtl/spi_host_command_queue.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/spi_host/rtl/spi_host_fsm.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/spi_host/rtl/spi_host_window.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/spi_host/rtl/spi_host_data_fifos.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/spi_host/rtl/spi_host_shift_register.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/i2c/rtl/i2c_core.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/rv_plic/rtl/rv_plic_target.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/spi_host/rtl/spi_host_core.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/gpio/rtl/gpio.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/i2c/rtl/i2c.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/spi_host/rtl/spi_host.sv \
    $ROOT/.bender/git/checkouts/opentitan_peripherals-7b624fb57f78de9a/src/rv_plic/rtl/rv_plic.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/riscv-dbg-1a98531d53bb4602/src/dm_pkg.sv \
    $ROOT/.bender/git/checkouts/riscv-dbg-1a98531d53bb4602/debug_rom/debug_rom.sv \
    $ROOT/.bender/git/checkouts/riscv-dbg-1a98531d53bb4602/debug_rom/debug_rom_one_scratch.sv \
    $ROOT/.bender/git/checkouts/riscv-dbg-1a98531d53bb4602/src/dm_csrs.sv \
    $ROOT/.bender/git/checkouts/riscv-dbg-1a98531d53bb4602/src/dm_mem.sv \
    $ROOT/.bender/git/checkouts/riscv-dbg-1a98531d53bb4602/src/dmi_cdc.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/riscv-dbg-1a98531d53bb4602/src/dmi_jtag_tap.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/riscv-dbg-1a98531d53bb4602/src/dm_sba.sv \
    $ROOT/.bender/git/checkouts/riscv-dbg-1a98531d53bb4602/src/dm_top.sv \
    $ROOT/.bender/git/checkouts/riscv-dbg-1a98531d53bb4602/src/dmi_jtag.sv \
    $ROOT/.bender/git/checkouts/riscv-dbg-1a98531d53bb4602/src/dm_obi_top.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/regs/serial_link_reg_pkg.sv \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/regs/serial_link_reg_top.sv \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/regs/serial_link_single_channel_reg_pkg.sv \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/regs/serial_link_single_channel_reg_top.sv \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/serial_link_pkg.sv \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/channel_allocator/stream_chopper.sv \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/channel_allocator/stream_dechopper.sv \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/channel_allocator/channel_despread_sfr.sv \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/channel_allocator/channel_spread_sfr.sv \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/channel_allocator/serial_link_channel_allocator.sv \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/serial_link_network.sv \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/serial_link_data_link.sv \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/serial_link_physical.sv \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/serial_link.sv \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/serial_link_occamy_wrapper.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/serial_link_synth_wrapper.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/.bender/git/checkouts/unbent-a93c32aef5b319fd/src/bus_err_unit_bare.sv \
    $ROOT/.bender/git/checkouts/unbent-a93c32aef5b319fd/src/bus_err_unit_reg_pkg.sv \
    $ROOT/.bender/git/checkouts/unbent-a93c32aef5b319fd/src/bus_err_unit_reg_top.sv \
    $ROOT/.bender/git/checkouts/unbent-a93c32aef5b319fd/src/bus_err_unit.sv \
    $ROOT/.bender/git/checkouts/unbent-a93c32aef5b319fd/src/axi_err_unit_wrap.sv \
    $ROOT/.bender/git/checkouts/unbent-a93c32aef5b319fd/src/obi_err_unit_wrap.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/hw/future/UsbOhciAxi4.v \
    $ROOT/hw/future/spinal_usb_ohci.sv \
    $ROOT/hw/bootrom/cheshire_bootrom.sv \
    $ROOT/hw/regs/cheshire_reg_pkg.sv \
    $ROOT/hw/regs/cheshire_reg_top.sv \
    $ROOT/hw/cheshire_pkg.sv \
    $ROOT/hw/cheshire_soc.sv \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/target/xilinx/src/phy_definitions.svh \
]

add_files -norecurse -fileset [current_fileset] [list \
    $ROOT/target/xilinx/src/dram_wrapper_xilinx.sv \
    $ROOT/target/xilinx/src/fan_ctrl.sv \
    $ROOT/target/xilinx/src/cheshire_top_xilinx.sv \
]

set_property include_dirs [list \
    /home/smitropoulos/ara_patched/hardware/include \
    $ROOT/.bender/git/checkouts/apb-521b279a5c028536/include \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/include \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/include \
    $ROOT/.bender/git/checkouts/axi_rt-7cef46f372eaf0fb/include \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/include \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/include \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/axis/include \
    $ROOT/cva6_patched/common/local/util \
    $ROOT/cva6_patched/core/include \
    $ROOT/hw/include \
    $ROOT/idma_patched/src/include \
] [current_fileset]

set_property include_dirs [list \
    /home/smitropoulos/ara_patched/hardware/include \
    $ROOT/.bender/git/checkouts/apb-521b279a5c028536/include \
    $ROOT/.bender/git/checkouts/axi-ecdc900686449c15/include \
    $ROOT/.bender/git/checkouts/axi_llc-5fb8850caad4fcfa/include \
    $ROOT/.bender/git/checkouts/axi_rt-7cef46f372eaf0fb/include \
    $ROOT/.bender/git/checkouts/common_cells-7f7ae0f5e6bf7fb5/include \
    $ROOT/.bender/git/checkouts/register_interface-902ad5bfde7bb98c/include \
    $ROOT/.bender/git/checkouts/serial_link-6e09ea4800bad616/src/axis/include \
    $ROOT/cva6_patched/common/local/util \
    $ROOT/cva6_patched/core/include \
    $ROOT/hw/include \
    $ROOT/idma_patched/src/include \
] [current_fileset -simset]

set_property verilog_define [list \
    TARGET_CV64A6_IMAFDCV_SV39 \
    TARGET_CVA6 \
    TARGET_EXCLUDE_FIRST_PASS_DECODER \
    TARGET_FPGA \
    TARGET_SYNTHESIS \
    TARGET_VIVADO \
    TARGET_XILINX \
    TARGET_ZCU102 \
    ARA \
    NR_LANES=4 \
    VLEN=4096 \
    LLC_KIB=1024 \
    NO_ATOMICS \
    NO_DBG \
] [current_fileset]

set_property verilog_define [list \
    TARGET_CV64A6_IMAFDCV_SV39 \
    TARGET_CVA6 \
    TARGET_EXCLUDE_FIRST_PASS_DECODER \
    TARGET_FPGA \
    TARGET_SYNTHESIS \
    TARGET_VIVADO \
    TARGET_XILINX \
    TARGET_ZCU102 \
    ARA \
    NR_LANES=4 \
    VLEN=4096 \
    LLC_KIB=1024 \
    NO_ATOMICS \
    NO_DBG \
] [current_fileset -simset]

