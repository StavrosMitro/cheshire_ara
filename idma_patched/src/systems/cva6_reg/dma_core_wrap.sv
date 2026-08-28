// Copyright 2022 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Thomas Benz    <tbenz@iis.ee.ethz.ch>
// Author: Andreas Kuster <kustera@ethz.ch>
// Author: Paul Scheffler <paulsc@iis.ee.ethz.ch>
//
// Description: DMA core wrapper for the CVA6 integration

`include "axi/assign.svh"
`include "axi/typedef.svh"
`include "idma/typedef.svh"
`include "register_interface/typedef.svh"

module dma_core_wrap #(
  parameter int unsigned AxiAddrWidth     = 32'd0,
  parameter int unsigned AxiDataWidth     = 32'd0,
  parameter int unsigned AxiIdWidth       = 32'd0,
  parameter int unsigned AxiUserWidth     = 32'd0,
  parameter int unsigned AxiSlvIdWidth    = 32'd0,
  parameter int unsigned NumAxInFlight    = 32'd0,
  parameter int unsigned MemSysDepth      = 32'd0,
  parameter int unsigned JobFifoDepth     = 32'd0,
  parameter bit          RAWCouplingAvail = 32'd0,
  parameter bit          IsTwoD           = 32'd0,
  parameter type         axi_mst_req_t    = logic,
  parameter type         axi_mst_rsp_t    = logic,
  parameter type         axi_slv_req_t    = logic,
  parameter type         axi_slv_rsp_t    = logic
) (
  input  logic          clk_i,
  input  logic          rst_ni,
  input  logic          testmode_i,
  output axi_mst_req_t  axi_mst_req_o,
  input  axi_mst_rsp_t  axi_mst_rsp_i,
  input  axi_slv_req_t  axi_slv_req_i,
  output axi_slv_rsp_t  axi_slv_rsp_o
);

  // local params
  localparam int unsigned DmaRegisterWidth = 32'd64;
  localparam int unsigned NumDim           = 32'd2;
  localparam int unsigned TFLenWidth       = AxiAddrWidth;

  typedef logic [AxiDataWidth-1:0]     data_t;
  typedef logic [AxiDataWidth/8-1:0]   strb_t;
  typedef logic [AxiAddrWidth-1:0]     addr_t;
  typedef logic [AxiIdWidth-1:0]       axi_id_t;
  typedef logic [AxiSlvIdWidth-1:0]    axi_slv_id_t;
  typedef logic [AxiUserWidth-1:0]     axi_user_t;

  // ---------------------------------------------------------------------------
  // PATCH 2026-08-28 (local fork): register bus must be DmaRegisterWidth, NOT
  // AxiDataWidth.
  //
  // The iDMA register file is hardcoded 64 bit
  // (idma_reg64_2d_frontend_reg_top.sv: `localparam int DW = 64`), and it does
  //     assign reg_wdata = reg_intf_req.wdata;   // truncates to [63:0]
  //     assign reg_be    = reg_intf_req.wstrb;   // truncates to [7:0]
  // Upstream built the reg bus from `data_t` (= AxiDataWidth) instead of the
  // already-declared `DmaRegisterWidth`, so at AxiDataWidth=128 the upper half
  // of every beat is silently DISCARDED: registers at byte offsets = 8 (mod 16)
  // -- DST_ADDR(0x08), CONF(0x18), STRIDE_SRC(0x38), NUM_REPETITIONS(0x48) --
  // can never be written.
  //
  // Measured on ZCU102 (same binary, only the bitstream differs):
  //   offset  4 lanes/128b        2 lanes/64b
  //   0x00    0xC0DE0000 OK       0xC0DE0000 OK
  //   0x08    0x00000000 LOST     0xC0DE0008 OK
  //   0x10    0xC0DE0010 OK       0xC0DE0010 OK
  //   0x38    0x00000000 LOST     0xC0DE0038 OK
  //   0x40    0xC0DE0040 OK       0xC0DE0040 OK
  // DST_ADDR stuck at 0 meant every transfer targeted address 0.
  //
  // Fix: narrow ONLY the config port to DmaRegisterWidth. idma_backend keeps
  // .DataWidth(AxiDataWidth), so DMA bandwidth is unaffected. At AxiDataWidth
  // == DmaRegisterWidth (2 lanes) the converter hits axi_dw_converter's
  // gen_no_dw_conversion branch and the cut is Bypass'd, so the 64-bit netlist
  // is unchanged.
  typedef logic [DmaRegisterWidth-1:0]   reg_data_t;
  typedef logic [DmaRegisterWidth/8-1:0] reg_strb_t;

  // Wide (SoC-side) and narrow (register-side) AXI views of the config port.
  `AXI_TYPEDEF_ALL(dma_cfg_wide,   addr_t, axi_slv_id_t, data_t,     strb_t,     axi_user_t)
  `AXI_TYPEDEF_ALL(dma_cfg_narrow, addr_t, axi_slv_id_t, reg_data_t, reg_strb_t, axi_user_t)
  // ---------------------------------------------------------------------------

  // iDMA struct definitions
  typedef logic [TFLenWidth-1:0]  tf_len_t;

  // iDMA request / response types
  `IDMA_TYPEDEF_FULL_REQ_T(idma_req_t, axi_slv_id_t, addr_t, tf_len_t)
  `IDMA_TYPEDEF_FULL_RSP_T(idma_rsp_t, addr_t)

  // PATCH: was `REG_BUS_TYPEDEF_ALL(dma_regs, addr_t, data_t, strb_t)` -- data_t
  // is AxiDataWidth wide, but the register file is fixed at DmaRegisterWidth.
  `REG_BUS_TYPEDEF_ALL(dma_regs, addr_t, reg_data_t, reg_strb_t)

  idma_req_t burst_req, burst_req_d;
  logic      be_valid, be_valid_d;
  logic      be_ready, be_ready_d;
  logic      be_trans_complete;
  idma_pkg::idma_busy_t idma_busy;

  idma_rsp_t idma_rsp;
  logic idma_rsp_valid;
  logic idma_rsp_ready;

  logic twod_trans_complete;
  logic twod_busy;

  dma_regs_req_t dma_regs_req;
  dma_regs_rsp_t dma_regs_rsp;

  // PATCH: narrow the CONFIG port AxiDataWidth -> DmaRegisterWidth.
  // Degenerates to plain wires when the widths already match (2 lanes).
  dma_cfg_narrow_req_t  cfg_dw_req,  cfg_req;
  dma_cfg_narrow_resp_t cfg_dw_resp, cfg_resp;

  axi_dw_converter #(
    .AxiMaxReads         ( 4                     ),
    .AxiSlvPortDataWidth ( AxiDataWidth          ),
    .AxiMstPortDataWidth ( DmaRegisterWidth      ),
    .AxiAddrWidth        ( AxiAddrWidth          ),
    .AxiIdWidth          ( AxiSlvIdWidth         ),
    .aw_chan_t           ( dma_cfg_wide_aw_chan_t   ),
    .b_chan_t            ( dma_cfg_wide_b_chan_t    ),
    .ar_chan_t           ( dma_cfg_wide_ar_chan_t   ),
    .mst_w_chan_t        ( dma_cfg_narrow_w_chan_t  ),
    .mst_r_chan_t        ( dma_cfg_narrow_r_chan_t  ),
    .axi_mst_req_t       ( dma_cfg_narrow_req_t     ),
    .axi_mst_resp_t      ( dma_cfg_narrow_resp_t    ),
    .slv_w_chan_t        ( dma_cfg_wide_w_chan_t    ),
    .slv_r_chan_t        ( dma_cfg_wide_r_chan_t    ),
    .axi_slv_req_t       ( axi_slv_req_t         ),
    .axi_slv_resp_t      ( axi_slv_rsp_t         )
  ) i_dma_cfg_dw_conv (
    .clk_i,
    .rst_ni,
    .slv_req_i  ( axi_slv_req_i ),
    .slv_resp_o ( axi_slv_rsp_o ),
    .mst_req_o  ( cfg_dw_req    ),
    .mst_resp_i ( cfg_dw_resp   )
  );

  // Register slice between the converter and axi_to_reg. axi_to_reg's ready
  // path is combinational; chaining it directly after a dw_converter is the
  // same shape that produced DRC LUTLP-1 on the debug module's
  // dw_conv -> axi_to_mem_interleaved path. Bypassed (pure wires, zero cost)
  // whenever no conversion happens.
  axi_cut #(
    .Bypass     ( AxiDataWidth == DmaRegisterWidth ),
    .aw_chan_t  ( dma_cfg_narrow_aw_chan_t ),
    .w_chan_t   ( dma_cfg_narrow_w_chan_t  ),
    .b_chan_t   ( dma_cfg_narrow_b_chan_t  ),
    .ar_chan_t  ( dma_cfg_narrow_ar_chan_t ),
    .r_chan_t   ( dma_cfg_narrow_r_chan_t  ),
    .axi_req_t  ( dma_cfg_narrow_req_t     ),
    .axi_resp_t ( dma_cfg_narrow_resp_t    )
  ) i_dma_cfg_cut (
    .clk_i,
    .rst_ni,
    .slv_req_i  ( cfg_dw_req  ),
    .slv_resp_o ( cfg_dw_resp ),
    .mst_req_o  ( cfg_req     ),
    .mst_resp_i ( cfg_resp    )
  );

  axi_to_reg #(
    .ADDR_WIDTH( AxiAddrWidth          ),
    .DATA_WIDTH( DmaRegisterWidth      ),
    .ID_WIDTH  ( AxiSlvIdWidth         ),
    .USER_WIDTH( AxiUserWidth          ),
    .axi_req_t ( dma_cfg_narrow_req_t  ),
    .axi_rsp_t ( dma_cfg_narrow_resp_t ),
    .reg_req_t ( dma_regs_req_t        ),
    .reg_rsp_t ( dma_regs_rsp_t        )
  ) i_axi_translate (
    .clk_i,
    .rst_ni,
    .testmode_i ( 1'b0          ),
    .axi_req_i  ( cfg_req       ),
    .axi_rsp_o  ( cfg_resp      ),
    .reg_req_o  ( dma_regs_req  ),
    .reg_rsp_i  ( dma_regs_rsp  )
  );


  if (!IsTwoD) begin : gen_one_d
    /*
     * DMA Frontend
     */
    idma_reg64_frontend #(
      .dma_regs_req_t  ( dma_regs_req_t ),
      .dma_regs_rsp_t  ( dma_regs_rsp_t ),
      .burst_req_t     ( idma_req_t     )
    ) i_dma_frontend (
      .clk_i,
      .rst_ni,
      // AXI slave: control port
      .dma_ctrl_req_i   ( dma_regs_req      ),
      .dma_ctrl_rsp_o   ( dma_regs_rsp      ),
      // Backend control
      .burst_req_o      ( burst_req_d       ),
      .valid_o          ( be_valid_d        ),
      .ready_i          ( be_ready_d        ),
      .backend_idle_i   ( ~|idma_busy       ),
      .trans_complete_i ( be_trans_complete )
    );

    stream_fifo #(
        .FALL_THROUGH ( 1'b0         ),
        .DATA_WIDTH   ( AxiDataWidth ),
        .DEPTH        ( JobFifoDepth ),
        .T            ( idma_req_t   )
      ) i_stream_fifo_jobs_oned (
        .clk_i,
        .rst_ni,
        .testmode_i,
        .flush_i    ( 1'b0                ),
        .usage_o    ( /* NOT CONNECTED */ ),
        .data_i     ( burst_req_d         ),
        .valid_i    ( be_valid_d          ),
        .ready_o    ( be_ready_d          ),
        .data_o     ( burst_req           ),
        .valid_o    ( be_valid            ),
        .ready_i    ( be_ready            )
    );


    assign be_trans_complete = idma_rsp_valid;
    assign idma_rsp_ready    = 1'b1;

  end else begin : gen_two_d

    `IDMA_TYPEDEF_FULL_ND_REQ_T(idma_nd_req_t, idma_req_t, tf_len_t, tf_len_t)

    idma_nd_req_t idma_nd_req,       idma_nd_req_d;
    logic         idma_nd_req_valid, idma_nd_req_valid_d;
    logic         idma_nd_req_ready, idma_nd_req_ready_d;

    // 2D frontend
    idma_reg64_2d_frontend #(
      .dma_regs_req_t  ( dma_regs_req_t ),
      .dma_regs_rsp_t  ( dma_regs_rsp_t ),
      .burst_req_t     ( idma_req_t     ),
      .idma_nd_req_t   ( idma_nd_req_t  )

    ) i_dma_2d_frontend (
      .clk_i,
      .rst_ni,
      // AXI slave: control port
      .dma_ctrl_req_i   ( dma_regs_req             ),
      .dma_ctrl_rsp_o   ( dma_regs_rsp             ),
      // Backend control
      .idma_nd_req_o    ( idma_nd_req_d            ),
      .valid_o          ( idma_nd_req_valid_d      ),
      .ready_i          ( idma_nd_req_ready_d      ),
      .backend_idle_i   ( ~|idma_busy & !twod_busy ),
      .trans_complete_i ( twod_trans_complete      )
    );

    stream_fifo #(
        .FALL_THROUGH ( 1'b0          ),
        .DATA_WIDTH   ( AxiDataWidth  ),
        .DEPTH        ( JobFifoDepth  ),
        .T            ( idma_nd_req_t )
      ) i_stream_fifo_jobs_twod (
        .clk_i,
        .rst_ni,
        .testmode_i,
        .flush_i    ( 1'b0                ),
        .usage_o    ( /* NOT CONNECTED */ ),
        .data_i     ( idma_nd_req_d       ),
        .valid_i    ( idma_nd_req_valid_d ),
        .ready_o    ( idma_nd_req_ready_d ),
        .data_o     ( idma_nd_req         ),
        .valid_o    ( idma_nd_req_valid   ),
        .ready_i    ( idma_nd_req_ready   )
    );

    // Midend
    idma_nd_midend #(
      .NumDim        ( NumDim          ),
      .addr_t        ( addr_t          ),
      .idma_req_t    ( idma_req_t      ),
      .idma_rsp_t    ( idma_rsp_t      ),
      .idma_nd_req_t ( idma_nd_req_t   ),
      .RepWidths     ( {AxiAddrWidth, AxiAddrWidth} )
    ) i_idma_nd_midend (
      .clk_i,
      .rst_ni,
      .nd_req_i         ( idma_nd_req         ),
      .nd_req_valid_i   ( idma_nd_req_valid   ),
      .nd_req_ready_o   ( idma_nd_req_ready   ),
      .nd_rsp_o         ( /* NOT CONECTED */  ),
      .nd_rsp_valid_o   ( twod_trans_complete ),
      .nd_rsp_ready_i   ( 1'b1                ),
      .burst_req_o      ( burst_req           ),
      .burst_req_valid_o( be_valid            ),
      .burst_req_ready_i( be_ready            ),
      .burst_rsp_i      ( idma_rsp            ),
      .burst_rsp_valid_i( idma_rsp_valid      ),
      .burst_rsp_ready_o( idma_rsp_ready      ),
      .busy_o           ( twod_busy           )
    );
  end

  `AXI_TYPEDEF_AW_CHAN_T(axi_mst_aw_chan_t, addr_t, axi_id_t, axi_user_t)
  `AXI_TYPEDEF_AR_CHAN_T(axi_mst_ar_chan_t, addr_t, axi_id_t, axi_user_t)

  idma_backend #(
    .DataWidth           ( AxiDataWidth                ),
    .AddrWidth           ( AxiAddrWidth                ),
    .UserWidth           ( AxiUserWidth                ),
    .AxiIdWidth          ( AxiIdWidth                  ),
    .NumAxInFlight       ( NumAxInFlight               ),
    .BufferDepth         ( 3                           ),
    .TFLenWidth          ( TFLenWidth                  ),
    .RAWCouplingAvail    ( RAWCouplingAvail            ),
    .MaskInvalidData     ( 1'b0                        ),
    .HardwareLegalizer   ( 1'b1                        ),
    .RejectZeroTransfers ( 1'b1                        ),
    .MemSysDepth         ( MemSysDepth                 ),
    .ErrorCap            ( idma_pkg::NO_ERROR_HANDLING ),
    .idma_req_t          ( idma_req_t                  ),
    .idma_rsp_t          ( idma_rsp_t                  ),
    .idma_eh_req_t       ( idma_pkg::idma_eh_req_t     ),
    .idma_busy_t         ( idma_pkg::idma_busy_t       ),
    .protocol_req_t      ( axi_mst_req_t               ),
    .protocol_rsp_t      ( axi_mst_rsp_t               ),
    .aw_chan_t           ( axi_mst_aw_chan_t           ),
    .ar_chan_t           ( axi_mst_ar_chan_t           )
  ) i_idma_backend (
    .clk_i,
    .rst_ni,
    .testmode_i,

    .idma_req_i    ( burst_req         ),
    .req_valid_i   ( be_valid          ),
    .req_ready_o   ( be_ready          ),

    .idma_rsp_o    ( idma_rsp          ),
    .rsp_valid_o   ( idma_rsp_valid    ),
    .rsp_ready_i   ( idma_rsp_ready    ),

    .idma_eh_req_i ( '0                ), // No error handling
    .eh_req_valid_i( 1'b1              ),
    .eh_req_ready_o( /*NOT CONNECTED*/ ),

    .protocol_req_o( axi_mst_req_o     ),
    .protocol_rsp_i( axi_mst_rsp_i     ),
    .busy_o        ( idma_busy         )
  );

endmodule : dma_core_wrap



module dma_core_wrap_intf #(
  parameter int unsigned AXI_ADDR_WIDTH     = 32'd0,
  parameter int unsigned AXI_DATA_WIDTH     = 32'd0,
  parameter int unsigned AXI_USER_WIDTH     = 32'd0,
  parameter int unsigned AXI_ID_WIDTH       = 32'd0,
  parameter int unsigned AXI_SLV_ID_WIDTH   = 32'd0,
  parameter int unsigned JOB_FIFO_DEPTH     = 32'd0,
  parameter int unsigned NUM_AX_IN_FLIGHT   = 32'd0,
  parameter int unsigned MEM_SYS_DEPTH      = 32'd0,
  parameter bit          RAW_COUPLING_AVAIL =  1'b0,
  parameter bit          IS_TWO_D           =  1'b0
) (
  input  logic   clk_i,
  input  logic   rst_ni,
  input  logic   testmode_i,
  AXI_BUS.Master axi_master,
  AXI_BUS.Slave  axi_slave
);

  typedef logic [AXI_ADDR_WIDTH-1:0]     addr_t;
  typedef logic [AXI_DATA_WIDTH-1:0]     data_t;
  typedef logic [(AXI_DATA_WIDTH/8)-1:0] strb_t;
  typedef logic [AXI_USER_WIDTH-1:0]     user_t;
  typedef logic [AXI_ID_WIDTH-1:0]       axi_id_t;
  typedef logic [AXI_SLV_ID_WIDTH-1:0]   axi_slv_id_t;

  `AXI_TYPEDEF_ALL(axi_mst, addr_t, axi_id_t, data_t, strb_t, user_t)
  axi_mst_req_t axi_mst_req;
  axi_mst_resp_t axi_mst_resp;
  `AXI_ASSIGN_FROM_REQ(axi_master, axi_mst_req)
  `AXI_ASSIGN_TO_RESP(axi_mst_resp, axi_master)

  `AXI_TYPEDEF_ALL(axi_slv, addr_t, axi_slv_id_t, data_t, strb_t, user_t)
  axi_slv_req_t axi_slv_req;
  axi_slv_resp_t axi_slv_resp;
  `AXI_ASSIGN_TO_REQ(axi_slv_req, axi_slave)
  `AXI_ASSIGN_FROM_RESP(axi_slave, axi_slv_resp)

  dma_core_wrap #(
    .AxiAddrWidth     ( AXI_ADDR_WIDTH     ),
    .AxiDataWidth     ( AXI_DATA_WIDTH     ),
    .AxiIdWidth       ( AXI_USER_WIDTH     ),
    .AxiUserWidth     ( AXI_ID_WIDTH       ),
    .AxiSlvIdWidth    ( AXI_SLV_ID_WIDTH   ),
    .JobFifoDepth     ( JOB_FIFO_DEPTH     ),
    .NumAxInFlight    ( NUM_AX_IN_FLIGHT   ),
    .MemSysDepth      ( MEM_SYS_DEPTH      ),
    .RAWCouplingAvail ( RAW_COUPLING_AVAIL ),
    .IsTwoD           ( IS_TWO_D           ),
    .axi_mst_req_t    ( axi_mst_req_t      ),
    .axi_mst_rsp_t    ( axi_mst_resp_t     ),
    .axi_slv_req_t    ( axi_slv_req_t      ),
    .axi_slv_rsp_t    ( axi_slv_resp_t     )
  ) i_dma_core_wrap (
    .clk_i,
    .rst_ni,
    .testmode_i,
    .axi_mst_req_o ( axi_mst_req  ),
    .axi_mst_rsp_i ( axi_mst_resp ),
    .axi_slv_req_i ( axi_slv_req  ),
    .axi_slv_rsp_o ( axi_slv_resp )
  );

endmodule : dma_core_wrap_intf
