// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Cyril Koenig <cykoenig@iis.ee.ethz.ch>

`ifdef TARGET_VCU128
  `define USE_RESET
  `define USE_JTAG
  `define USE_JTAG_VDDGND
  `define USE_DDR4
  `define USE_QSPI
  `define USE_STARTUPE3
  `define USE_VIO
`endif

`ifdef TARGET_GENESYS2
  `define USE_RESETN
  `define USE_JTAG
  `define USE_JTAG_TRSTN
  `define USE_SD
  `define USE_SWITCHES
  `define USE_DDR3
  `define USE_FAN
  `define USE_VIO
  `define USE_I2C
  `define USE_VGA
  `define USE_USB
`endif

`ifdef TARGET_ZCU102
  // `define USE_RESET
  // `define USE_JTAG
  // `define USE_DDR4
  // `define USE_VIO
  // Task K1 amendment: USE_VIO stays OFF on purpose (its probe_out2 init
  // value 0x1 would immediately force vio_boot_mode_sel=1, overriding the
  // physical boot-mode pins at power-up -- untested/unsafe for this board).
  // K5 3b: USE_NI_VIO (the K1/K3/K4 ni_disable diagnostic switch's macro)
  // removed -- the deadlock it gated around is now fixed at the config
  // source (Cva6NiDramRule, cheshire_pkg.sv), so no VIO is instantiated on
  // zcu102 at all anymore.
  `define USE_ZYNQMP
  `define USE_DDR
`endif

/////////////////////
// DRAM INTERFACES //
/////////////////////

`ifdef USE_DDR4
`define USE_DDR
`endif
`ifdef USE_DDR3
`define USE_DDR
`endif

`define DDR4_INTF \
  output          c0_ddr4_reset_n, \
  output [0:0]    c0_ddr4_ck_t, \
  output [0:0]    c0_ddr4_ck_c, \
  output          c0_ddr4_act_n, \
  output [16:0]   c0_ddr4_adr, \
  output [1:0]    c0_ddr4_ba, \
  output [0:0]    c0_ddr4_bg, \
  output [0:0]    c0_ddr4_cke, \
  output [0:0]    c0_ddr4_odt, \
  output [1:0]    c0_ddr4_cs_n, \
  inout  [8:0]    c0_ddr4_dm_dbi_n, \
  inout  [71:0]   c0_ddr4_dq, \
  inout  [8:0]    c0_ddr4_dqs_c, \
  inout  [8:0]    c0_ddr4_dqs_t,

`define DDR3_INTF \
  output        ddr3_ck_p, \
  output        ddr3_ck_n, \
  inout  [31:0] ddr3_dq, \
  inout  [3:0]  ddr3_dqs_n, \
  inout  [3:0]  ddr3_dqs_p, \
  output [14:0] ddr3_addr, \
  output [2:0]  ddr3_ba, \
  output        ddr3_ras_n, \
  output        ddr3_cas_n, \
  output        ddr3_we_n, \
  output        ddr3_reset_n, \
  output [0:0]  ddr3_cke, \
  output [0:0]  ddr3_cs_n, \
  output [3:0]  ddr3_dm, \
  output [0:0]  ddr3_odt,

///////////////////////
// ZYNQMP INTERFACES //
///////////////////////
// AXI HP0 (S_AXI_GP2 / SAXIGP2) slave port — Cheshire SoC master → PS DDR
// Data width: 128-bit (PSU__SAXIGP2__DATA_WIDTH = 128)
// ID width: 6-bit (zynq_ultra_ps_e default for HP ports)
// Addr width: 32-bit (low 32 bits of 49-bit PS address)
`define ZYNQMP_HP0_MST_INTF        \
  output logic        ps_hp0_aclk,    \
  output logic [5:0]  ps_hp0_awid,    \
  output logic [31:0] ps_hp0_awaddr,  \
  output logic [7:0]  ps_hp0_awlen,   \
  output logic [2:0]  ps_hp0_awsize,  \
  output logic [1:0]  ps_hp0_awburst, \
  output logic [0:0]  ps_hp0_awlock,  \
  output logic [3:0]  ps_hp0_awcache, \
  output logic [2:0]  ps_hp0_awprot,  \
  output logic [3:0]  ps_hp0_awqos,   \
  output logic        ps_hp0_awvalid, \
  input  logic        ps_hp0_awready, \
  output logic [127:0] ps_hp0_wdata,  \
  output logic [15:0] ps_hp0_wstrb,   \
  output logic        ps_hp0_wlast,   \
  output logic        ps_hp0_wvalid,  \
  input  logic        ps_hp0_wready,  \
  input  logic [5:0]  ps_hp0_bid,     \
  input  logic [1:0]  ps_hp0_bresp,   \
  input  logic        ps_hp0_bvalid,  \
  output logic        ps_hp0_bready,  \
  output logic [5:0]  ps_hp0_arid,    \
  output logic [31:0] ps_hp0_araddr,  \
  output logic [7:0]  ps_hp0_arlen,   \
  output logic [2:0]  ps_hp0_arsize,  \
  output logic [1:0]  ps_hp0_arburst, \
  output logic [0:0]  ps_hp0_arlock,  \
  output logic [3:0]  ps_hp0_arcache, \
  output logic [2:0]  ps_hp0_arprot,  \
  output logic [3:0]  ps_hp0_arqos,   \
  output logic        ps_hp0_arvalid, \
  input  logic        ps_hp0_arready, \
  input  logic [5:0]  ps_hp0_rid,     \
  input  logic [127:0] ps_hp0_rdata,  \
  input  logic [1:0]  ps_hp0_rresp,   \
  input  logic        ps_hp0_rlast,   \
  input  logic        ps_hp0_rvalid,  \
  output logic        ps_hp0_rready,

// Internal wire declarations for ZCU102 PS AXI HP0 signals
// (not IO ports — these are internal FPGA fabric connections)
`define ZYNQMP_HP0_WIRE_DECL    \
  logic        ps_hp0_aclk;    \
  logic [5:0]  ps_hp0_awid;    \
  logic [31:0] ps_hp0_awaddr;  \
  logic [7:0]  ps_hp0_awlen;   \
  logic [2:0]  ps_hp0_awsize;  \
  logic [1:0]  ps_hp0_awburst; \
  logic [0:0]  ps_hp0_awlock;  \
  logic [3:0]  ps_hp0_awcache; \
  logic [2:0]  ps_hp0_awprot;  \
  logic [3:0]  ps_hp0_awqos;   \
  logic        ps_hp0_awvalid; \
  logic        ps_hp0_awready; \
  logic [127:0] ps_hp0_wdata;  \
  logic [15:0] ps_hp0_wstrb;   \
  logic        ps_hp0_wlast;   \
  logic        ps_hp0_wvalid;  \
  logic        ps_hp0_wready;  \
  logic [5:0]  ps_hp0_bid;     \
  logic [1:0]  ps_hp0_bresp;   \
  logic        ps_hp0_bvalid;  \
  logic        ps_hp0_bready;  \
  logic [5:0]  ps_hp0_arid;    \
  logic [31:0] ps_hp0_araddr;  \
  logic [7:0]  ps_hp0_arlen;   \
  logic [2:0]  ps_hp0_arsize;  \
  logic [1:0]  ps_hp0_arburst; \
  logic [0:0]  ps_hp0_arlock;  \
  logic [3:0]  ps_hp0_arcache; \
  logic [2:0]  ps_hp0_arprot;  \
  logic [3:0]  ps_hp0_arqos;   \
  logic        ps_hp0_arvalid; \
  logic        ps_hp0_arready; \
  logic [5:0]  ps_hp0_rid;     \
  logic [127:0] ps_hp0_rdata;  \
  logic [1:0]  ps_hp0_rresp;   \
  logic        ps_hp0_rlast;   \
  logic        ps_hp0_rvalid;  \
  logic        ps_hp0_rready;
