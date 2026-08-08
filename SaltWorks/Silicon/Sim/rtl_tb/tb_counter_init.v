// tb_counter_init.v — the init surface the protocol's own simulator cannot see.
//
// frame_sim.py decodes its strobes from a LOOP VARIABLE, so it has no frame
// counter and every simulated frame is perfectly phased by construction. Its
// row 3 ("200 arbitrary power-up states") therefore randomises the twelve
// elements' act/sel registers and NOTHING ELSE. This bench randomises BOTH
// init surfaces against the real banyan_fabric.v.
//
// ARM A (aligned)   : sof asserted, then ONE frame. Claim under test: the FIRST
//                     well-phased frame is already correct from any register
//                     state, because the header strobes every stage in order
//                     before the validity window opens at cycle 6.
// ARM B (control)   : sof withheld and a random 0..13 cycle offset inserted, so
//                     the counter meets the frame at an arbitrary phase. MUST
//                     fail, or arm A proves nothing.
//
// ⚠️ REV 2. Rev 1 reported ARM A 186/200 FAIL and I did not publish it, because
// the pass count was 14/200 = 1/14 — exactly the chance that a free-running
// 14-cycle counter sits at 0 by luck. That is the fingerprint of a treatment
// that never happened: rev 1 deasserted `sof` in the SAME timestep as the
// posedge that samples it, a stimulus race, so both arms were the same
// experiment. THE STRUCTURAL FIX IS NOT "drive on the negedge" — it is the
// TREATMENT ASSERTION below: arm A now checks cnt==0 at frame start on every
// seed and reports a harness failure if not. An experiment must verify that
// its independent variable was actually applied.

`timescale 1ns/1ps

module tb_counter_init;

  localparam K     = 3;
  localparam N     = 8;
  localparam P     = 8;
  localparam HDR   = 2*K;        // 6
  localparam FRAME = HDR + P;    // 14
  localparam SEEDS = 200;

  reg        clk   = 1'b0;
  reg        rst_n = 1'b1;       // deliberately never asserted: §5's whole point
  reg        sof   = 1'b0;
  reg  [7:0] din   = 8'd0;
  wire [7:0] dout;
  wire [3:0] cnt_o;
  wire       valid;

  banyan_fabric #(.PAYLOAD(P)) dut (
      .clk(clk), .rst_n(rst_n), .sof(sof), .din(din),
      .dout(dout), .cnt_o(cnt_o), .valid(valid));

  always #5 clk = ~clk;

  integer seed, i, j, t, n, k, off;
  reg  [7:0] mask;
  integer    dest  [0:7];
  reg  [7:0] pay   [0:7];
  integer    srcof [0:7];
  reg  [FRAME-1:0] stream [0:7];
  reg  [7:0] cap [0:FRAME-1];
  integer fail_a, fail_b, fail_c, fail_d, fail_e, bad, harness_fail, distinct;
  reg [3:0]  cnt_at_start;
  reg [47:0] sig, sigs [0:SEEDS-1];

  task randomize_state;          // called at a NEGEDGE: no pending NBA, so
    begin                        // blocking writes to DUT regs survive
      dut.cnt = $random;
      dut.e00.act0=$random; dut.e00.act1=$random; dut.e00.sel0=$random; dut.e00.sel1=$random;
      dut.e01.act0=$random; dut.e01.act1=$random; dut.e01.sel0=$random; dut.e01.sel1=$random;
      dut.e02.act0=$random; dut.e02.act1=$random; dut.e02.sel0=$random; dut.e02.sel1=$random;
      dut.e03.act0=$random; dut.e03.act1=$random; dut.e03.sel0=$random; dut.e03.sel1=$random;
      dut.e10.act0=$random; dut.e10.act1=$random; dut.e10.sel0=$random; dut.e10.sel1=$random;
      dut.e11.act0=$random; dut.e11.act1=$random; dut.e11.sel0=$random; dut.e11.sel1=$random;
      dut.e12.act0=$random; dut.e12.act1=$random; dut.e12.sel0=$random; dut.e12.sel1=$random;
      dut.e13.act0=$random; dut.e13.act1=$random; dut.e13.sel0=$random; dut.e13.sel1=$random;
      dut.e20.act0=$random; dut.e20.act1=$random; dut.e20.sel0=$random; dut.e20.sel1=$random;
      dut.e21.act0=$random; dut.e21.act1=$random; dut.e21.sel0=$random; dut.e21.sel1=$random;
      dut.e22.act0=$random; dut.e22.act1=$random; dut.e22.sel0=$random; dut.e22.sel1=$random;
      dut.e23.act0=$random; dut.e23.act1=$random; dut.e23.sel0=$random; dut.e23.sel1=$random;
    end
  endtask

  task snapshot;                 // the 48 routing bits actually present at
    begin                        // frame start — the state the claim quantifies
      sig = {dut.e00.act0,dut.e00.act1,dut.e00.sel0,dut.e00.sel1,
             dut.e01.act0,dut.e01.act1,dut.e01.sel0,dut.e01.sel1,
             dut.e02.act0,dut.e02.act1,dut.e02.sel0,dut.e02.sel1,
             dut.e03.act0,dut.e03.act1,dut.e03.sel0,dut.e03.sel1,
             dut.e10.act0,dut.e10.act1,dut.e10.sel0,dut.e10.sel1,
             dut.e11.act0,dut.e11.act1,dut.e11.sel0,dut.e11.sel1,
             dut.e12.act0,dut.e12.act1,dut.e12.sel0,dut.e12.sel1,
             dut.e13.act0,dut.e13.act1,dut.e13.sel0,dut.e13.sel1,
             dut.e20.act0,dut.e20.act1,dut.e20.sel0,dut.e20.sel1,
             dut.e21.act0,dut.e21.act1,dut.e21.sel0,dut.e21.sel1,
             dut.e22.act0,dut.e22.act1,dut.e22.sel0,dut.e22.sel1,
             dut.e23.act0,dut.e23.act1,dut.e23.sel0,dut.e23.sel1};
    end
  endtask

  // A random 8-bit mask's set bits, read ascending, ARE a sorted destination
  // set; assigning them to sources 0..n-1 concentrates the sources. That is
  // banyan_selfrouting's hypothesis, built by construction, not filtered for.
  task build_load;                    // a random load
    begin
      build_load_mask($random);
    end
  endtask

  task build_load_mask;               // a NAMED load, for the exhaustive arm
    input [7:0] m;
    begin
      mask = m;
      if (mask == 8'd0) mask = 8'd1;
      n = 0;
      for (i = 0; i < N; i = i + 1) srcof[i] = -1;
      for (i = 0; i < N; i = i + 1)
        if (mask[i]) begin
          dest[n] = i;  srcof[i] = n;
          pay[n]  = (8'hA5 ^ (n * 8'h1B)) | 8'h01;   // distinct and nonzero
          n = n + 1;
        end
      for (i = 0; i < N; i = i + 1) begin
        stream[i] = {FRAME{1'b0}};
        if (i < n) begin
          stream[i][0] = 1'b1;  stream[i][1] = dest[i][2];
          stream[i][2] = 1'b1;  stream[i][3] = dest[i][1];
          stream[i][4] = 1'b1;  stream[i][5] = dest[i][0];
          for (j = 0; j < P; j = j + 1) stream[i][HDR+j] = pay[i][j];
        end
      end
    end
  endtask

  // sof is raised at a negedge and held ACROSS the sampling posedge; it is
  // lowered at the next negedge inside drive_frame. No same-timestep race.
  task align;
    begin
      @(negedge clk); sof = 1'b1;
      @(posedge clk);              // cnt <= 0 here, sof stable
    end
  endtask

  task drive_frame;
    begin
      for (t = 0; t < FRAME; t = t + 1) begin
        @(negedge clk);
        sof = 1'b0;
        if (t == 0) begin cnt_at_start = dut.cnt; snapshot; end
        for (i = 0; i < N; i = i + 1) din[i] = stream[i][t];
        #1;
        cap[t] = dout;             // data path is combinational
        @(posedge clk);
      end
    end
  endtask

  task check_frame;
    begin
      bad = 0;
      for (i = 0; i < N; i = i + 1)
        for (j = 0; j < P; j = j + 1)
          if (srcof[i] >= 0) begin
            if (cap[HDR+j][i] !== pay[srcof[i]][j]) bad = bad + 1;
          end else begin
            if (cap[HDR+j][i] !== 1'b0)             bad = bad + 1;
          end
    end
  endtask

  initial begin
    fail_a = 0; fail_b = 0; fail_c = 0; fail_d = 0; fail_e = 0; harness_fail = 0;
    $display("tb_counter_init rev2 — BOTH init surfaces randomised (48 routing bits AND cnt)");
    $display("rst_n is NEVER asserted; self-initialisation is the property under test.");
    $display("");

    // ===== DIRECTED: out-of-range counter power-up (4-bit reg, 14-cycle
    // frame). Claimed structurally on the bus at 13:31; verified here.
    for (i = 12; i <= 15; i = i + 1) begin
      @(negedge clk); dut.cnt = i[3:0];
      k = 0;
      while (dut.cnt !== 4'd0 && k < 24) begin @(negedge clk); k = k + 1; end
      $display("RECOVERY   cnt power-up %0d reaches 0 in %0d cycles (no sof, no rst)", i, k);
    end
    $display("");

    // ================= ARM A: sof-aligned, ONE frame ======================
    for (seed = 0; seed < SEEDS; seed = seed + 1) begin
      @(negedge clk); randomize_state;
      build_load;
      align;
      drive_frame;
      sigs[seed] = sig;
      // TREATMENT ASSERTION — did the independent variable actually apply?
      if (cnt_at_start !== 4'd0) begin
        harness_fail = harness_fail + 1;
        if (harness_fail <= 3)
          $display("  ⛔ HARNESS: seed %0d began at cnt=%0d, NOT 0 — sof did not take",
                   seed, cnt_at_start);
      end
      check_frame;
      if (bad != 0) begin
        fail_a = fail_a + 1;
        if (fail_a <= 5)
          $display("  A FAIL seed %0d: cnt@start=%0d n=%0d state=%h badbits=%0d",
                   seed, cnt_at_start, n, sig, bad);
      end
    end

    distinct = 0;
    for (i = 0; i < SEEDS; i = i + 1) begin
      k = 1;
      for (j = 0; j < i; j = j + 1) if (sigs[j] === sigs[i]) k = 0;
      distinct = distinct + k;
    end

    $display("TREATMENT  arm A frames that truly began at cnt==0            : %0d/%0d",
             SEEDS - harness_fail, SEEDS);
    $display("COVERAGE   distinct 48-bit power-up register states exercised : %0d/%0d",
             distinct, SEEDS);
    $display("ARM A      sof-aligned, ONE frame, arbitrary regs             : %0d/%0d FAIL",
             fail_a, SEEDS);

    // ========= ARM B (control): no sof, arbitrary counter phase ===========
    for (seed = 0; seed < SEEDS; seed = seed + 1) begin
      @(negedge clk); randomize_state;
      build_load;
      off = ($random % 14); if (off < 0) off = -off;
      for (k = 0; k < off; k = k + 1) @(negedge clk);   // arbitrary phase
      drive_frame;                                      // no align
      check_frame;
      if (bad != 0) fail_b = fail_b + 1;
    end
    $display("ARM B      control, sof WITHHELD, arbitrary phase             : %0d/%0d FAIL",
             fail_b, SEEDS);

    // ===== ARM C: the spec's clause AS WRITTEN. Mis-phased host, TWO frames
    // back to back, judge the SECOND — i.e. "at or after the second act_stb".
    // If waiting repairs anything, C passes where B failed.
    for (seed = 0; seed < SEEDS; seed = seed + 1) begin
      @(negedge clk); randomize_state;
      build_load;
      off = ($random % 14); if (off < 0) off = -off;
      for (k = 0; k < off; k = k + 1) @(negedge clk);
      drive_frame;                     // frame 1, discarded
      build_load;                      // a FRESH load for frame 2
      drive_frame;                     // frame 2, judged
      check_frame;
      if (bad != 0) fail_c = fail_c + 1;
    end
    $display("ARM C      mis-phased, TWO frames, judge the SECOND           : %0d/%0d FAIL",
             fail_c, SEEDS);

    // ===== ARM D: aligned, TWO frames back to back, judge the SECOND. This is
    // the spec's CURRENT hypothesis, and it must pass or my harness disagrees
    // with what §5 already certifies. Also the first evidence on §9's open
    // "may frames abut with no gap" question.
    for (seed = 0; seed < SEEDS; seed = seed + 1) begin
      @(negedge clk); randomize_state;
      build_load;
      align;
      drive_frame;                     // frame 1
      build_load;                      // fresh load
      drive_frame;                     // frame 2, judged
      check_frame;
      if (bad != 0) fail_d = fail_d + 1;
    end
    $display("ARM D      sof-aligned, TWO frames abutting, judge the SECOND : %0d/%0d FAIL",
             fail_d, SEEDS);

    // ===== ARM E: EXHAUSTIVE over the theorem's hypothesis at k=3.
    // Every non-empty subset of the 8 outputs, read ascending, IS a sorted
    // destination set; sources 0..n-1 concentrate it. So masks 1..255 enumerate
    // ALL sorted+concentrated loads — the same population as §8 row 2, but
    // against the REAL VERILOG rather than frame_sim.py's transcription of it,
    // and with a random register power-up per case rather than a zero one.
    // Strictly stronger than either row it supplements.
    for (seed = 1; seed <= 255; seed = seed + 1) begin
      @(negedge clk); randomize_state;
      build_load_mask(seed[7:0]);
      align;
      drive_frame;
      if (cnt_at_start !== 4'd0) harness_fail = harness_fail + 1;
      check_frame;
      if (bad != 0) begin
        fail_e = fail_e + 1;
        if (fail_e <= 5)
          $display("  E FAIL mask %b n=%0d state=%h badbits=%0d", seed[7:0], n, sig, bad);
      end
    end
    $display("ARM E      EXHAUSTIVE: all 255 sorted+concentrated loads,");
    $display("           aligned, random power-up per case                   : %0d/255 FAIL",
             fail_e);

    $display("");
    $display("VERDICT harness=%0d armA=%0d armB=%0d armC=%0d armD=%0d armE=%0d",
             harness_fail, fail_a, fail_b, fail_c, fail_d, fail_e);
    $finish;
  end

endmodule
