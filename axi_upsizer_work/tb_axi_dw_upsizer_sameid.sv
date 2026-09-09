// Directed testbench: same-ID outstanding reads through axi_dw_upsizer.
//
// WHY THIS EXISTS
// ---------------
// The upsizer routes every incoming AR whose ID matches a busy context to that
// same busy context (`id_clash_upsizer`, axi_dw_upsizer.sv:275/286).  A busy
// context never grants, because the grant lives only in the R_IDLE arm of the
// FSM (:368-369).  The result is exactly ONE outstanding read per AXI ID.
//
// axi_llc issues every refill with a fixed ID (`AxReqId = 9`,
// axi_llc_ax_master.sv:129) because its r_master consumes descriptors in FIFO
// order and therefore needs in-order responses.  Both modules are correct in
// isolation; composed, the LLC gets 1 outstanding refill instead of the 4-6 its
// pipeline is built for, and pays the full DDR latency on every 64 B line.
//
// The existing tb_axi_dw_upsizer.sv is class-based and randomized and never
// forces several same-ID reads to be live at once, so it passes today.
//
// STYLE: deliberately procedural -- no classes, no randomize(), no
// common_verification dependency.  Runs on xsim and on Questa FSE alike.
//
// EXPECTED RESULTS
//   current RTL : TEST 1 FAILS (1 AR issued out of 4)
//   fixed RTL   : all checks pass
//
// Written for the Cheshire+Ara ZCU102 investigation, 2026-09-09.
// See AGENT_NOTES_FP16_4LANE.md sections 52 and 53.

`include "axi/typedef.svh"

module tb_axi_dw_upsizer_sameid #(
    parameter int unsigned TbAxiAddrWidth = 32  ,
    parameter int unsigned TbAxiIdWidth   = 6   ,  // cheshire's llc_id_t is 6 b
    parameter int unsigned TbAxiUserWidth = 1   ,
    parameter int unsigned TbSlvDataWidth = 64  ,  // LLC side  (2 lanes)
    parameter int unsigned TbMstDataWidth = 128 ,  // PS HP0 side
    parameter int unsigned TbAxiMaxReads  = 8   ,
    parameter time         TbClkPeriod    = 10ns,
    parameter time         TbApplTime     = 2ns ,
    parameter time         TbTestTime     = 8ns
  );

  // The refill shape axi_llc emits: chan_d.len = NumBlocks-1 = 7,
  // chan_d.size = clog2(BlockSize/8), where BlockSize is the SLAVE-side bus.
  // At the ZCU102's 2-lane geometry that is 8 beats x 8 B = one 64 B line.
  // Derived from the widths so the same testbench covers other width pairs.
  localparam int unsigned RefillBeats = 8;                       // NumBlocks
  localparam logic [7:0]  RefillLen   = 8'(RefillBeats - 1);
  localparam logic [2:0]  RefillSize  = 3'($clog2(TbSlvDataWidth/8));
  localparam int unsigned RefillBytes = RefillBeats * (TbSlvDataWidth/8);

  // Shape expected downstream after upsizing: same bytes, wider beats.
  //   64 -> 128 : 8x8 B  becomes 4x16 B  (len=3, size=4)
  //  128 -> 256 : 8x16 B becomes 4x32 B  (len=3, size=5)
  localparam logic [2:0] ExpMstSize = 3'($clog2(TbMstDataWidth/8));
  localparam logic [7:0] ExpMstLen  =
      8'((RefillBytes / (TbMstDataWidth/8)) - 1);

  // Number of 64-bit lanes in one slave beat; the payload check walks them.
  localparam int unsigned SlvLanes = TbSlvDataWidth/64 > 0 ? TbSlvDataWidth/64 : 1;

  localparam logic [TbAxiIdWidth-1:0] LlcRefillId = 'd9;  // axi_llc_pkg::AxReqId

  localparam int unsigned NumIds = 1 << TbAxiIdWidth;

  /////////////
  //  TYPES  //
  /////////////

  typedef logic [TbAxiAddrWidth-1:0]   addr_t;
  typedef logic [TbAxiIdWidth-1:0]     id_t;
  typedef logic [TbAxiUserWidth-1:0]   user_t;
  typedef logic [TbSlvDataWidth-1:0]   slv_data_t;
  typedef logic [TbSlvDataWidth/8-1:0] slv_strb_t;
  typedef logic [TbMstDataWidth-1:0]   mst_data_t;
  typedef logic [TbMstDataWidth/8-1:0] mst_strb_t;

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

  ///////////////////////
  //  CLOCK AND RESET  //
  ///////////////////////

  logic clk   = 1'b0;
  logic rst_n = 1'b0;

  always #(TbClkPeriod/2) clk = ~clk;

  initial begin
    rst_n = 1'b0;
    repeat (5) @(posedge clk);
    #TbApplTime;
    rst_n = 1'b1;
  end

  ///////////
  //  DUT  //
  ///////////

  slv_req_t  slv_req;
  slv_resp_t slv_resp;
  mst_req_t  mst_req;
  mst_resp_t mst_resp;

  axi_dw_upsizer #(
    .AxiMaxReads         (TbAxiMaxReads ),
    .AxiSlvPortDataWidth (TbSlvDataWidth),
    .AxiMstPortDataWidth (TbMstDataWidth),
    .AxiAddrWidth        (TbAxiAddrWidth),
    .AxiIdWidth          (TbAxiIdWidth  ),
    .aw_chan_t           (aw_chan_t     ),
    .mst_w_chan_t        (mst_w_chan_t  ),
    .slv_w_chan_t        (slv_w_chan_t  ),
    .b_chan_t            (b_chan_t      ),
    .ar_chan_t           (ar_chan_t     ),
    .mst_r_chan_t        (mst_r_chan_t  ),
    .slv_r_chan_t        (slv_r_chan_t  ),
    .axi_mst_req_t       (mst_req_t     ),
    .axi_mst_resp_t      (mst_resp_t    ),
    .axi_slv_req_t       (slv_req_t     ),
    .axi_slv_resp_t      (slv_resp_t    )
  ) i_dut (
    .clk_i      (clk     ),
    .rst_ni     (rst_n   ),
    .slv_req_i  (slv_req ),
    .slv_resp_o (slv_resp),
    .mst_req_o  (mst_req ),
    .mst_resp_i (mst_resp)
  );

  ///////////////////
  //  TB CONTROLS  //
  ///////////////////

  logic mst_ar_ready_en;   // downstream accepts AR
  logic r_enable;          // downstream is allowed to return R bursts
  logic slv_r_ready_en;    // upstream R backpressure
  logic check_enable;      // payload checking armed
  logic ctr_clear;         // synchronous clear for all counters
  logic r_ooo;             // answer bursts out of order ACROSS ids

  // slv_req_t / mst_resp_t are `struct packed`, i.e. ONE variable each. Mixing
  // a continuous assign on some fields with procedural drives on others would
  // be multiple drivers on the same variable and is illegal. So each struct is
  // built in exactly one always_comb from plain signals that the processes
  // below drive individually.

  ar_chan_t    slv_ar_beat;
  logic        slv_ar_valid_r;
  mst_r_chan_t mst_r_beat;
  logic        mst_r_valid_r;

  always_comb begin
    slv_req          = '0;
    slv_req.ar       = slv_ar_beat;
    slv_req.ar_valid = slv_ar_valid_r;
    slv_req.r_ready  = slv_r_ready_en;
    slv_req.b_ready  = 1'b1;
    slv_req.aw_valid = 1'b0;
    slv_req.w_valid  = 1'b0;
  end

  always_comb begin
    mst_resp          = '0;
    mst_resp.ar_ready = mst_ar_ready_en;
    mst_resp.r        = mst_r_beat;
    mst_resp.r_valid  = mst_r_valid_r;
    // Write channels are unused here; tie them off safely.
    mst_resp.aw_ready = 1'b1;
    mst_resp.w_ready  = 1'b1;
    mst_resp.b_valid  = 1'b0;
  end

  ////////////////////////////
  //  DOWNSTREAM DDR MODEL  //
  ////////////////////////////
  //
  // Captures every accepted AR, and returns its R burst only while r_enable is
  // high.  Payload is address-derived: the 64-bit half living at byte address A
  // carries the value A.  A context swap therefore shows up upstream as a data
  // mismatch, not merely as reordering -- which is the failure mode that any
  // ordering scheme gets wrong.

  addr_t      cap_addr [$];
  logic [7:0] cap_len  [$];
  logic [2:0] cap_size [$];
  id_t        cap_id   [$];

  int unsigned ar_issued;      // master-side AR handshakes
  int unsigned first_ar_len;   // shape of the first AR that went out
  int unsigned first_ar_size;
  logic        first_ar_seen;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ar_issued     <= 0;
      first_ar_seen <= 1'b0;
      first_ar_len  <= 0;
      first_ar_size <= 0;
    end else if (ctr_clear) begin
      ar_issued     <= 0;
      first_ar_seen <= 1'b0;
      first_ar_len  <= 0;
      first_ar_size <= 0;
    end else if (mst_req.ar_valid && mst_resp.ar_ready) begin
      cap_addr.push_back(mst_req.ar.addr);
      cap_len .push_back(mst_req.ar.len );
      cap_size.push_back(mst_req.ar.size);
      cap_id  .push_back(mst_req.ar.id  );
      ar_issued <= ar_issued + 1;
      if (!first_ar_seen) begin
        first_ar_seen <= 1'b1;
        first_ar_len  <= mst_req.ar.len;
        first_ar_size <= mst_req.ar.size;
      end
    end
  end

  // R return process.  Declarations are at process scope so no tool has to
  // accept mid-block `automatic` declarations.
  addr_t       rr_addr;
  logic [7:0]  rr_len;
  logic [2:0]  rr_size;
  id_t         rr_id;
  addr_t       rr_beat_addr;
  int unsigned rr_beat;
  int unsigned rr_half;
  int unsigned rr_sel;
  int unsigned rr_k;
  int unsigned rr_j;
  logic        rr_is_first;

  initial begin : ddr_model
    mst_r_beat    = '0;
    mst_r_valid_r = 1'b0;
    @(posedge rst_n);
    forever begin
      @(posedge clk);
      #TbApplTime;
      if (r_enable && cap_addr.size() > 0) begin
        // Which captured burst to answer.
        //
        // In OOO mode, scan from the BACK for an entry that is the EARLIEST
        // still-outstanding one of its own id, and serve that.  Reordering
        // across different ids is legal and is what we want to stress; but
        // reordering two responses that share an id is an AXI violation BY THE
        // SLAVE, and would make this model, not the DUT, the thing under test.
        //
        // The first version of this model picked "the last entry whose id
        // differs from the HEAD's id", which happily jumped over an earlier
        // entry of the SAME id as the one it picked.  With a queue of
        // [1, 2, 3, 9@C0, 9@100, 9@140] it served 9@140 first -- an illegal
        // slave -- and the resulting upstream mismatch looked exactly like a
        // DUT misrouting bug.  It was not.
        rr_sel = 0;
        if (r_ooo) begin
          for (rr_k = cap_addr.size(); rr_k > 0; rr_k--) begin
            rr_is_first = 1'b1;
            for (rr_j = 0; rr_j < rr_k - 1; rr_j++)
              if (cap_id[rr_j] == cap_id[rr_k-1]) rr_is_first = 1'b0;
            if (rr_is_first) begin
              rr_sel = rr_k - 1;
              break;
            end
          end
        end
        rr_addr = cap_addr[rr_sel]; cap_addr.delete(rr_sel);
        rr_len  = cap_len [rr_sel]; cap_len .delete(rr_sel);
        rr_size = cap_size[rr_sel]; cap_size.delete(rr_sel);
        rr_id   = cap_id  [rr_sel]; cap_id  .delete(rr_sel);
        for (rr_beat = 0; rr_beat <= rr_len; rr_beat++) begin
          rr_beat_addr  = rr_addr + rr_beat * (1 << rr_size);
          mst_r_beat    = '0;
          mst_r_beat.id = rr_id;
          mst_r_beat.last = (rr_beat == rr_len);
          mst_r_beat.resp = axi_pkg::RESP_OKAY;
          for (rr_half = 0; rr_half < TbMstDataWidth/64; rr_half++)
            mst_r_beat.data[64*rr_half +: 64] = 64'(rr_beat_addr + 8*rr_half);
          mst_r_valid_r = 1'b1;
          // hold the beat until the DUT accepts it
          #(TbTestTime - TbApplTime);
          while (!mst_req.r_ready) begin
            @(posedge clk);
            #TbTestTime;
          end
          @(posedge clk);
          #TbApplTime;
          mst_r_valid_r = 1'b0;
        end
      end
    end
  end

  ///////////////////////////
  //  UPSTREAM R CHECKER   //
  ///////////////////////////

  int unsigned r_beats;
  int unsigned r_errors;
  int unsigned r_lasts;

  addr_t next_expected [0:NumIds-1];
  logic  expect_active [0:NumIds-1];
  logic  beat_ok;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      r_beats  <= 0;
      r_errors <= 0;
      r_lasts  <= 0;
    end else if (ctr_clear) begin
      r_beats  <= 0;
      r_errors <= 0;
      r_lasts  <= 0;
    end else if (slv_resp.r_valid && slv_req.r_ready) begin
      r_beats <= r_beats + 1;
      if (slv_resp.r.last) r_lasts <= r_lasts + 1;
      if (check_enable) begin
        if (!expect_active[slv_resp.r.id]) begin
          $display("  [CHK] unexpected R beat for id=%0d data=0x%0h",
                   slv_resp.r.id, slv_resp.r.data);
          r_errors <= r_errors + 1;
        end else begin
          // A slave beat may be wider than 64 b (e.g. 128 b at the 128->256
          // pair), so check every 64-bit lane against its own byte address.
          beat_ok = 1'b1;
          for (int unsigned h = 0; h < SlvLanes; h++)
            if (slv_resp.r.data[64*h +: 64] !==
                64'(next_expected[slv_resp.r.id] + 8*h))
              beat_ok = 1'b0;
          if (!beat_ok) begin
            $display("  [CHK] id=%0d beat %0d: expected base 0x%0h got 0x%0h",
                     slv_resp.r.id, r_beats,
                     next_expected[slv_resp.r.id], slv_resp.r.data);
            r_errors <= r_errors + 1;
          end
        end
        next_expected[slv_resp.r.id] <= next_expected[slv_resp.r.id]
                                        + (TbSlvDataWidth/8);
      end
    end
  end

  /////////////////
  //  UTILITIES  //
  /////////////////

  int unsigned tests_run;
  int unsigned tests_failed;

  task automatic banner(input string name);
    $display("\n============================================================");
    $display("  %s", name);
    $display("============================================================");
  endtask

  // NB never pass a conditional expression with string-literal arms to this
  // task: XSim 2021.1 dies with FATAL_ERROR inside $display. Use $sformatf.
  task automatic check(input string what, input logic ok, input string detail);
    tests_run++;
    if (ok) $display("  [PASS] %s -- %s", what, detail);
    else begin
      tests_failed++;
      $display("  [FAIL] %s -- %s", what, detail);
    end
  endtask

  task automatic idle_cycles(input int unsigned n);
    repeat (n) @(posedge clk);
  endtask

  // Drain anything still in flight, then clear every counter and the queues.
  task automatic fresh_start();
    r_enable = 1'b1;
    idle_cycles(500);
    r_enable = 1'b0;
    r_ooo    = 1'b0;
    @(posedge clk);
    #TbApplTime;
    check_enable = 1'b0;
    cap_addr.delete(); cap_len.delete(); cap_size.delete(); cap_id.delete();
    for (int i = 0; i < NumIds; i++) begin
      expect_active[i] = 1'b0;
      next_expected[i] = '0;
    end
    ctr_clear = 1'b1;
    @(posedge clk);
    #TbApplTime;
    ctr_clear = 1'b0;
    @(posedge clk);
  endtask

  // Sends one AR, giving up after `budget` cycles.  Giving up is the expected
  // outcome on the unfixed RTL and must never hang the run.
  task automatic send_ar(input  id_t         id,
                         input  addr_t       addr,
                         input  logic [7:0]  len,
                         input  logic [2:0]  size,
                         input  int unsigned budget,
                         output logic        accepted);
    int unsigned waited;
    accepted = 1'b0;
    waited   = 0;
    @(posedge clk);
    #TbApplTime;
    slv_ar_beat       = '0;
    slv_ar_beat.id    = id;
    slv_ar_beat.addr  = addr;
    slv_ar_beat.len   = len;
    slv_ar_beat.size  = size;
    slv_ar_beat.burst = axi_pkg::BURST_INCR;
    // Must be modifiable, otherwise the upsizer takes R_PASSTHROUGH and never
    // recomputes the burst -- axi_dw_upsizer.sv:388-397.
    slv_ar_beat.cache = axi_pkg::CACHE_MODIFIABLE;
    slv_ar_valid_r    = 1'b1;
    #(TbTestTime - TbApplTime);
    while (!slv_resp.ar_ready && waited < budget) begin
      @(posedge clk);
      #TbTestTime;
      waited++;
    end
    accepted = slv_resp.ar_ready;
    @(posedge clk);
    #TbApplTime;
    slv_ar_valid_r = 1'b0;
  endtask

  //////////////////
  //  STIMULUS    //
  //////////////////

  logic        ok;
  logic        ok2;
  int unsigned admitted;
  int unsigned issued_before_first_r;

  initial begin : stimulus
    slv_ar_beat      = '0;
    slv_ar_valid_r   = 1'b0;
    slv_r_ready_en   = 1'b1;
    mst_ar_ready_en  = 1'b1;
    r_enable         = 1'b0;
    r_ooo            = 1'b0;
    check_enable     = 1'b0;
    ctr_clear        = 1'b0;
    tests_run        = 0;
    tests_failed     = 0;
    for (int i = 0; i < NumIds; i++) begin
      expect_active[i] = 1'b0;
      next_expected[i] = '0;
    end

    @(posedge rst_n);
    idle_cycles(4);

    $display("");
    $display("  GEOMETRY: slave %0d b -> master %0d b, AxiMaxReads=%0d",
             TbSlvDataWidth, TbMstDataWidth, TbAxiMaxReads);
    $display("  refill  : %0d beats x %0d B = %0d B  (len=%0d size=%0d)",
             RefillBeats, TbSlvDataWidth/8, RefillBytes, RefillLen, RefillSize);
    $display("  expected: %0d beats x %0d B downstream (len=%0d size=%0d)",
             ExpMstLen+1, TbMstDataWidth/8, ExpMstLen, ExpMstSize);

    ////////////////////////////////////////////////////////////////////////
    // TEST 1 -- the red one.  Four refill-shaped reads, all ARID = 9,
    // downstream accepting AR but returning no R.  Counts how many ARs the
    // DUT issues downstream before any response can come back.
    ////////////////////////////////////////////////////////////////////////
    banner("TEST 1: four same-ID (9) refill reads, no R returned");

    r_enable     = 1'b0;
    check_enable = 1'b0;

    for (int unsigned i = 0; i < 4; i++) begin
      send_ar(LlcRefillId, addr_t'('h8000_0000 + i*RefillBytes),
              RefillLen, RefillSize, 40, ok);
      if (!ok) begin
        $display("  AR #%0d was NOT accepted upstream (slave port stalled)", i);
        break;
      end
    end

    idle_cycles(20);
    issued_before_first_r = ar_issued;

    $display("  downstream ARs issued before first R : %0d (want 4)",
             issued_before_first_r);
    check("same-ID outstanding reads", issued_before_first_r == 4,
          $sformatf("got %0d, want 4", issued_before_first_r));

    // Whatever DID go out must have been reshaped, independently of the count.
    check("downstream burst reshaped 8x8B -> 4x16B",
          first_ar_seen && (first_ar_len == ExpMstLen)
                        && (first_ar_size == ExpMstSize),
          $sformatf("len=%0d size=%0d, want len=%0d size=%0d",
                    first_ar_len, first_ar_size, ExpMstLen, ExpMstSize));

    fresh_start();

    ////////////////////////////////////////////////////////////////////////
    // TEST 2 -- data integrity for two back-to-back same-ID reads.
    // On the unfixed RTL this passes trivially (they are serialized).  On the
    // fixed RTL it is what catches a returning burst handed to the wrong
    // context: the payload is address-derived, so a swap is visible.
    ////////////////////////////////////////////////////////////////////////
    banner("TEST 2: same-ID data integrity (address-derived payload)");

    next_expected[LlcRefillId] = 'h9000_0000;
    expect_active[LlcRefillId] = 1'b1;
    check_enable = 1'b1;
    r_enable     = 1'b1;

    for (int unsigned i = 0; i < 2; i++) begin
      send_ar(LlcRefillId, addr_t'('h9000_0000 + i*RefillBytes),
              RefillLen, RefillSize, 400, ok);
      if (!ok) $display("  AR #%0d not accepted", i);
    end
    idle_cycles(400);

    check("payload matches address on every beat", r_errors == 0,
          $sformatf("%0d data errors over %0d beats", r_errors, r_beats));
    check("two RLAST seen", r_lasts == 2,
          $sformatf("r_lasts=%0d, want 2", r_lasts));
    check("16 slave beats for two 64 B lines", r_beats == 2*RefillBeats,
          $sformatf("r_beats=%0d, want %0d", r_beats, 2*RefillBeats));

    fresh_start();

    ////////////////////////////////////////////////////////////////////////
    // TEST 3 -- ID 0.  An idle context has r_req_q.ar = '0, so its recorded
    // ID reads as 0.  Any same-ID blocking rule not qualified with "has a
    // pending AR" aliases against every idle context here.  ID 0 is exactly
    // what Ara's VLSU emits (addrgen.sv:883), so this is not hypothetical.
    ////////////////////////////////////////////////////////////////////////
    banner("TEST 3: ID 0 must not alias against idle contexts");

    r_enable = 1'b0;

    for (int unsigned i = 0; i < 4; i++) begin
      send_ar(id_t'(0), addr_t'('hA000_0000 + i*RefillBytes),
              RefillLen, RefillSize, 40, ok);
      if (!ok) begin
        $display("  AR #%0d (id=0) not accepted", i);
        break;
      end
    end
    idle_cycles(20);

    $display("  downstream ARs issued for id=0 : %0d (want 4)", ar_issued);
    check("id=0 behaves like any other ID", ar_issued == 4,
          $sformatf("got %0d, want 4", ar_issued));

    fresh_start();

    ////////////////////////////////////////////////////////////////////////
    // TEST 4 -- different IDs.  The baseline the module already supports:
    // distinct IDs take distinct contexts and run concurrently.  If this ever
    // fails, the fix broke something that used to work.
    ////////////////////////////////////////////////////////////////////////
    banner("TEST 4: four DIFFERENT IDs run concurrently (regression baseline)");

    r_enable = 1'b0;

    for (int unsigned i = 0; i < 4; i++) begin
      send_ar(id_t'(i + 1), addr_t'('hB000_0000 + i*RefillBytes),
              RefillLen, RefillSize, 40, ok);
      if (!ok) begin
        $display("  AR #%0d (id=%0d) not accepted", i, i+1);
        break;
      end
    end
    idle_cycles(20);

    check("distinct IDs are concurrent", ar_issued == 4,
          $sformatf("got %0d, want 4", ar_issued));

    fresh_start();

    ////////////////////////////////////////////////////////////////////////
    // TEST 5 -- upstream R backpressure inside a master beat.  One 128-bit
    // master beat is held for two cycles while two 64-bit slave beats are
    // produced (axi_dw_upsizer.sv:515).  Stalling in the middle must not lose,
    // duplicate or corrupt a beat.
    ////////////////////////////////////////////////////////////////////////
    banner("TEST 5: upstream R backpressure mid master-beat");

    next_expected[LlcRefillId] = 'hC000_0000;
    expect_active[LlcRefillId] = 1'b1;
    check_enable = 1'b1;
    r_enable     = 1'b1;

    fork
      begin : drive_ar
        logic ok_l;
        send_ar(LlcRefillId, addr_t'('hC000_0000), RefillLen, RefillSize,
                400, ok_l);
        if (!ok_l) $display("  AR not accepted");
      end
      begin : chop_ready
        // Irregular upstream stalling for the duration of the burst.
        for (int unsigned k = 0; k < 40; k++) begin
          @(posedge clk); #TbApplTime; slv_r_ready_en = 1'b0;
          @(posedge clk); #TbApplTime; slv_r_ready_en = 1'b1;
          repeat (k % 3) @(posedge clk);
        end
        @(posedge clk); #TbApplTime; slv_r_ready_en = 1'b1;
      end
    join

    idle_cycles(200);
    slv_r_ready_en = 1'b1;

    check("no beat lost or corrupted under backpressure", r_errors == 0,
          $sformatf("%0d data errors", r_errors));
    check("exactly 8 slave beats for one 64 B line", r_beats == RefillBeats,
          $sformatf("r_beats=%0d, want %0d", r_beats, RefillBeats));
    check("exactly one RLAST", r_lasts == 1,
          $sformatf("r_lasts=%0d, want 1", r_lasts));

    check_enable = 1'b0;

    fresh_start();

    ////////////////////////////////////////////////////////////////////////
    // TEST 6 -- the invariant the whole fix rests on.
    //
    // While a same-ID AR has NOT yet completed its master-side handshake, a
    // second AR with that ID must be blocked. That is what guarantees two
    // same-ID ARs are never pending at i_mst_ar_arb together, and therefore
    // that the round-robin arbiter cannot reorder them. Push-at-allocation
    // into the id_queue is only correct because of this.
    //
    // On the STOCK RTL the second AR stays blocked even after the first has
    // issued (it waits for RLAST), so the third check below separates the two
    // designs.
    ////////////////////////////////////////////////////////////////////////
    banner("TEST 6: same-ID admission and order under AR backpressure");

    // NB the upsizer's internal axi_demux is instantiated WITHOUT overriding
    // SpillAr, which defaults to 1 (axi_dw_upsizer.sv:208, axi_demux.sv:59).
    // So there is a spill register between i_mst_ar_arb and this testbench's
    // ar_ready. Deasserting ar_ready therefore does NOT keep an AR "unissued"
    // as far as the upsizer is concerned: the spill absorbs it, the internal
    // handshake completes, and the next same-ID AR is legitimately admitted.
    // Order is still preserved -- the spill is a FIFO downstream of the
    // arbiter. What we can check here is that admission is BOUNDED, and that
    // whatever is admitted comes back upstream in request order.
    mst_ar_ready_en = 1'b0;
    r_enable        = 1'b0;
    check_enable    = 1'b1;
    next_expected[LlcRefillId] = 'hD000_0000;
    expect_active[LlcRefillId] = 1'b1;

    admitted = 0;
    for (int unsigned i = 0; i < TbAxiMaxReads; i++) begin
      send_ar(LlcRefillId, addr_t'('hD000_0000 + i*RefillBytes),
              RefillLen, RefillSize, 40, ok);
      if (!ok) break;
      admitted++;
    end
    $display("  same-ID ARs admitted with downstream ar_ready low : %0d", admitted);

    check("admission is bounded by backpressure, not unbounded",
          (admitted > 0) && (admitted < TbAxiMaxReads),
          $sformatf("admitted=%0d of %0d", admitted, TbAxiMaxReads));

    mst_ar_ready_en = 1'b1;
    idle_cycles(20);
    check("every admitted AR reached the wire", ar_issued == admitted,
          $sformatf("ar_issued=%0d, admitted=%0d", ar_issued, admitted));

    r_enable = 1'b1;
    idle_cycles(600);
    check("same-ID responses arrive in request order", r_errors == 0,
          $sformatf("%0d data errors over %0d beats", r_errors, r_beats));
    check("every admitted burst returned", r_lasts == admitted,
          $sformatf("r_lasts=%0d, admitted=%0d", r_lasts, admitted));

    fresh_start();

    ////////////////////////////////////////////////////////////////////////
    // TEST 7 -- fragmented contexts, several live same-ID transactions, and
    // responses returned OUT OF ORDER across ids.
    //
    // This is the case §53.1 says would break a naive fix. Four ARs with
    // different ids are made to pile up at i_mst_ar_arb simultaneously (AR
    // backpressure), so round-robin picks its own order. Then two more id=9
    // reads are added while the first id=9 is still outstanding -- legal only
    // after the patch. Finally the DDR model answers out of order across ids.
    // Every 64-bit beat must still carry its own address.
    ////////////////////////////////////////////////////////////////////////
    banner("TEST 7: fragmented contexts + mixed IDs + out-of-order responses");

    mst_ar_ready_en = 1'b0;
    r_enable        = 1'b0;
    check_enable    = 1'b1;

    // Every address MUST be spaced by RefillBytes, which is width-dependent
    // (64 B at 64->128, 128 B at 128->256). Hard-coding 0x40 here made the
    // three id=9 bursts OVERLAP at the wider pair, and since the checker walks
    // one contiguous expected-address stream per id, that showed up as a
    // "regression" that was entirely this testbench's fault. Derive, never
    // hard-code.
    next_expected[1] = 'hE000_0000 + 0*RefillBytes; expect_active[1] = 1'b1;
    next_expected[2] = 'hE000_0000 + 1*RefillBytes; expect_active[2] = 1'b1;
    next_expected[3] = 'hE000_0000 + 2*RefillBytes; expect_active[3] = 1'b1;
    next_expected[LlcRefillId] = 'hE000_0000 + 3*RefillBytes;
    expect_active[LlcRefillId] = 1'b1;

    send_ar(id_t'(1), addr_t'('hE000_0000 + 0*RefillBytes),
            RefillLen, RefillSize, 40, ok);
    send_ar(id_t'(2), addr_t'('hE000_0000 + 1*RefillBytes),
            RefillLen, RefillSize, 40, ok);
    send_ar(id_t'(3), addr_t'('hE000_0000 + 2*RefillBytes),
            RefillLen, RefillSize, 40, ok);
    send_ar(LlcRefillId, addr_t'('hE000_0000 + 3*RefillBytes),
            RefillLen, RefillSize, 40, ok);

    // Four ARs are now pending at the master arbiter at once.
    mst_ar_ready_en = 1'b1;
    idle_cycles(20);
    check("four pending ARs all reached the wire", ar_issued == 4,
          $sformatf("ar_issued=%0d, want 4", ar_issued));

    // The first id=9 has issued but is still outstanding; more may follow.
    send_ar(LlcRefillId, addr_t'('hE000_0000 + 4*RefillBytes),
            RefillLen, RefillSize, 100, ok);
    send_ar(LlcRefillId, addr_t'('hE000_0000 + 5*RefillBytes),
            RefillLen, RefillSize, 100, ok);
    idle_cycles(20);
    check("more same-ID reads admitted while earlier ones outstanding",
          ar_issued == 6, $sformatf("ar_issued=%0d, want 6", ar_issued));

    // Answer out of order across ids.
    r_ooo    = 1'b1;
    r_enable = 1'b1;
    idle_cycles(1200);

    check("no misrouted beat under arbiter reordering + OOO responses",
          r_errors == 0, $sformatf("%0d data errors over %0d beats",
                                   r_errors, r_beats));
    check("all six bursts returned", r_lasts == 6,
          $sformatf("r_lasts=%0d, want 6", r_lasts));
    check("48 slave beats for six 64 B lines", r_beats == 6*RefillBeats,
          $sformatf("r_beats=%0d, want %0d", r_beats, 6*RefillBeats));

    fresh_start();

    ////////////////////////////////////////////////////////////////////////
    // TEST 8 -- fill AxiMaxReads completely, then one more.
    // Running out of contexts must stall, never corrupt.
    ////////////////////////////////////////////////////////////////////////
    banner("TEST 8: fill all AxiMaxReads contexts, then overflow");

    mst_ar_ready_en = 1'b1;
    r_enable        = 1'b0;

    for (int unsigned i = 0; i < TbAxiMaxReads; i++) begin
      send_ar(id_t'(i + 1), addr_t'('hF000_0000 + i*RefillBytes),
              RefillLen, RefillSize, 60, ok);
      if (!ok) $display("  AR #%0d (id=%0d) not accepted", i, i+1);
    end
    idle_cycles(20);
    check("all AxiMaxReads contexts usable", ar_issued == TbAxiMaxReads,
          $sformatf("ar_issued=%0d, want %0d", ar_issued, TbAxiMaxReads));

    send_ar(id_t'(TbAxiMaxReads + 1),
            addr_t'('hF100_0000), RefillLen, RefillSize, 40, ok2);
    check("one beyond capacity stalls (backpressure, not corruption)", !ok2,
          $sformatf("accepted=%0b, want 0 (no free context)", ok2));

    fresh_start();

    ////////////////////////////////////////////////////////////////////////
    // TEST 9 -- sustained streaming with responses flowing.
    // Exercises queue push and pop landing in the same cycle, which is why
    // id_queue is instantiated with FULL_BW = 1 (id_queue.sv:25,203).
    ////////////////////////////////////////////////////////////////////////
    banner("TEST 9: sustained streaming (simultaneous queue push and pop)");

    mst_ar_ready_en = 1'b1;
    r_enable        = 1'b1;
    r_ooo           = 1'b0;
    check_enable    = 1'b1;

    for (int unsigned i = 0; i < 4; i++) begin
      next_expected[i + 1] = addr_t'('h7000_0000 + i*4*RefillBytes);
      expect_active[i + 1] = 1'b1;
    end

    for (int unsigned i = 0; i < 16; i++) begin
      send_ar(id_t'((i % 4) + 1),
              addr_t'('h7000_0000 + (i % 4)*4*RefillBytes
                                  + (i / 4)*RefillBytes),
              RefillLen, RefillSize, 400, ok);
      if (!ok) $display("  stream AR #%0d not accepted", i);
    end
    idle_cycles(1500);

    check("streaming: no data error", r_errors == 0,
          $sformatf("%0d errors over %0d beats", r_errors, r_beats));
    check("streaming: 16 bursts completed", r_lasts == 16,
          $sformatf("r_lasts=%0d, want 16", r_lasts));

    check_enable = 1'b0;

    ////////////////////////////////////////////////////////////////////////
    // SUMMARY
    ////////////////////////////////////////////////////////////////////////
    $display("\n============================================================");
    if (tests_failed == 0)
      $display("  RESULT: all %0d checks PASSED", tests_run);
    else
      $display("  RESULT: %0d of %0d checks FAILED", tests_failed, tests_run);
    $display("============================================================");
    $display("");
    $display("  On the UNFIXED RTL, TEST 1 is EXPECTED to fail with 1 AR");
    $display("  issued instead of 4. That failure is the point of this");
    $display("  testbench. See AGENT_NOTES_FP16_4LANE.md section 53.");
    $display("");

    idle_cycles(5);
    $finish;
  end

  // Global watchdog: the unfixed RTL must not be able to hang the run.
  initial begin
    #(TbClkPeriod * 500000);
    $display("\n[TB] WATCHDOG TIMEOUT -- simulation did not finish");
    $fatal(1, "watchdog");
  end

endmodule
