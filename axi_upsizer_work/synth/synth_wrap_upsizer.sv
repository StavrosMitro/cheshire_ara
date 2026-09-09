// Out-of-context synthesis wrapper for axi_dw_upsizer.
//
// WHY A WRAPPER
// -------------
// axi_dw_upsizer has TYPE parameters (aw_chan_t, mst_r_chan_t, ...) that
// default to `logic`. `synth_design -generic` cannot set those, so synthesising
// the module directly out of context would build a degenerate 1-bit version.
// This wrapper fixes the types the way the SoC does and exposes only scalars.
//
// WHY THE SHIFT REGISTER
// ----------------------
// With constant or dangling ports the synthesiser prunes almost everything and
// the area number is meaningless. So every input bit of the DUT is driven from
// a shift register fed by one serial pin, and every output bit is XOR-reduced
// into one register. Nothing can be constant-propagated away.
//
// The wrapper's own cost (the shift register and the XOR tree) is IDENTICAL for
// the stock and patched builds, so it cancels in the delta -- which is the only
// number we are after. Do not read the absolute figure as "the converter costs
// N LUTs"; read the difference.
//
// See AGENT_NOTES_FP16_4LANE.md section 53.

`include "axi/typedef.svh"

module synth_wrap_upsizer #(
    // Defaults are the real ZCU102 2-lane geometry:
    //   SocDataWidth 64 (LLC side) -> cfg.DataWidth 128 (PS HP0)
    //   cfg.MaxReads 24            (dram_wrapper_xilinx.sv:121)
    //   llc_id_t     6 bits        (cheshire typedef.svh)
    parameter int unsigned AxiAddrWidth = 32,
    parameter int unsigned AxiIdWidth   = 6,
    parameter int unsigned AxiUserWidth = 1,
    parameter int unsigned SlvDataWidth = 64,
    parameter int unsigned MstDataWidth = 128,
    parameter int unsigned MaxReads     = 24
  ) (
    input  logic clk_i,
    input  logic rst_ni,
    input  logic serial_i,
    output logic serial_o
  );

  typedef logic [AxiAddrWidth-1:0]   addr_t;
  typedef logic [AxiIdWidth-1:0]     id_t;
  typedef logic [AxiUserWidth-1:0]   user_t;
  typedef logic [SlvDataWidth-1:0]   slv_data_t;
  typedef logic [SlvDataWidth/8-1:0] slv_strb_t;
  typedef logic [MstDataWidth-1:0]   mst_data_t;
  typedef logic [MstDataWidth/8-1:0] mst_strb_t;

  `AXI_TYPEDEF_AW_CHAN_T(aw_chan_t, addr_t, id_t, user_t)
  `AXI_TYPEDEF_B_CHAN_T(b_chan_t, id_t, user_t)
  `AXI_TYPEDEF_AR_CHAN_T(ar_chan_t, addr_t, id_t, user_t)

  `AXI_TYPEDEF_W_CHAN_T(slv_w_chan_t, slv_data_t, slv_strb_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(slv_r_chan_t, slv_data_t, id_t, user_t)
  `AXI_TYPEDEF_REQ_T(slv_req_t, aw_chan_t, slv_w_chan_t, ar_chan_t)
  `AXI_TYPEDEF_RESP_T(slv_resp_t, b_chan_t, slv_r_chan_t)

  `AXI_TYPEDEF_W_CHAN_T(mst_w_chan_t, mst_data_t, mst_strb_t, user_t)
  `AXI_TYPEDEF_R_CHAN_T(mst_r_chan_t, mst_data_t, id_t, user_t)
  `AXI_TYPEDEF_REQ_T(mst_req_t, aw_chan_t, mst_w_chan_t, ar_chan_t)
  `AXI_TYPEDEF_RESP_T(mst_resp_t, b_chan_t, mst_r_chan_t)

  slv_req_t  slv_req;
  slv_resp_t slv_resp;
  mst_req_t  mst_req;
  mst_resp_t mst_resp;

  localparam int unsigned InW  = $bits(slv_req_t) + $bits(mst_resp_t);
  localparam int unsigned OutW = $bits(slv_resp_t) + $bits(mst_req_t);

  // Drive every DUT input from a shift register so nothing is constant.
  logic [InW-1:0] in_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) in_q <= '0;
    else         in_q <= {in_q[InW-2:0], serial_i};
  end
  assign {slv_req, mst_resp} = in_q;

  // Observe every DUT output so nothing is dangling.
  logic out_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) out_q <= 1'b0;
    else         out_q <= ^{slv_resp, mst_req};
  end
  assign serial_o = out_q;

  axi_dw_upsizer #(
    .AxiMaxReads         (MaxReads    ),
    .AxiSlvPortDataWidth (SlvDataWidth),
    .AxiMstPortDataWidth (MstDataWidth),
    .AxiAddrWidth        (AxiAddrWidth),
    .AxiIdWidth          (AxiIdWidth  ),
    .aw_chan_t           (aw_chan_t   ),
    .mst_w_chan_t        (mst_w_chan_t),
    .slv_w_chan_t        (slv_w_chan_t),
    .b_chan_t            (b_chan_t    ),
    .ar_chan_t           (ar_chan_t   ),
    .mst_r_chan_t        (mst_r_chan_t),
    .slv_r_chan_t        (slv_r_chan_t),
    .axi_mst_req_t       (mst_req_t   ),
    .axi_mst_resp_t      (mst_resp_t  ),
    .axi_slv_req_t       (slv_req_t   ),
    .axi_slv_resp_t      (slv_resp_t  )
  ) i_dut (
    .clk_i      (clk_i    ),
    .rst_ni     (rst_ni   ),
    .slv_req_i  (slv_req  ),
    .slv_resp_o (slv_resp ),
    .mst_req_o  (mst_req  ),
    .mst_resp_i (mst_resp )
  );

endmodule
