`timescale 1ns/1ps
// ============================================================================
// ⛔⛔ REFUTED. THIS BENCH DOES NOT WORK AND IT IS KEPT ON PURPOSE.
//
// VERDICT (silicon 2026-09-03 18:1x): a `sof`-stretched phase 0 CANNOT serve a
// registered host, and this file is the producer of that null. Run it and the
// core executes NOTHING: x1 and x3 stay `xxxxxxxx` and R1/R2/R4 all FAIL.
//
// WHY, and it is a timing fact I had to TRACE rather than read: `sof` is a flop.
// A stall asserted in REACTION to seeing phase 0 arrives one cycle late — the
// phase counter has already left 0 — so the frame bounces 0 -> 1 -> 0 and the
// transaction restarts forever. A stall here must be asserted at phase 3, BEFORE
// the host knows whether it needs one, which makes it pre-scheduled and not
// demand-driven. And at phase 3 it is worse: see the second refutation.
//
// THE SECOND, STRUCTURAL REFUTATION is measured by the SIBLING bench in this
// directory, `tb_sof_at_retire.v`, which is the one to read: the `sof` arm of
// busadapt8's arbitration does not consult `retire` (the ratified shape-A repair
// reached only the `loop_end` arm), so `sof` at a retiring phase-3 edge RE-ISSUES
// a completed memory transaction — +2 STORE loops, measured, and INVISIBLE to
// the tracked bench's six criteria.
//
// ⇒ FULL WRITE-UP: docs/silicon-ndf-registered-host-results-0903.md
//   PRE-REGISTRATION: docs/silicon-ndf-registered-host-prereg-0903.md
//
// KEPT rather than deleted because a null with no runnable producer is only
// quotable, and because the next head to reach for `sof`-as-wait-state should
// find the attempt already made and priced. Named in this directory's own
// convention (cf. tb_retire_derivation_INCONCLUSIVE.v).
// ⛔ DO NOT CITE A GREEN FROM THIS FILE. IT HAS NONE.
// ============================================================================
module tb;

  // LAT = extra phase-0 cycles the host takes to "look up" (its lookup latency).
  // STRETCH = 1 uses `sof` to hold phase 0 while it looks up; 0 is the CONTROL.
  parameter integer LAT     = 3;
  parameter integer STRETCH = 1;

  reg clk = 0, rst_n = 0;
  reg sof = 0;
  wire [7:0] pin_out;  wire [1:0] ph;  wire retire_w;
  reg  [7:0] pin_in;

  plane32bus dut(.clk(clk), .rst_n(rst_n), .sof(sof),
                 .instr_byte(pin_in), .addr_byte(pin_out),
                 .phase_o(ph), .retire(retire_w));
  always #5 clk = ~clk;

  // ---- host memory, 256 bytes, indexed by addr[7:0] (as the tracked bench) --
  reg [7:0] hmem [0:255];

  function [31:0] progword(input [31:0] a);
    case (a[3:2])
      2'd0: progword = 32'h04000093;  // addi x1, x0, 64
      2'd1: progword = 32'h0010A023;  // sw   x1, 0(x1)   -> mem[64] = 64
      2'd2: progword = 32'h0000A183;  // lw   x3, 0(x1)   -> x3 = mem[64]
      default: progword = 32'h00000013; // nop
    endcase
  endfunction

  // ---- THE REGISTERED HOST ---------------------------------------------------
  // ⛔ THE TIMING FACT THAT MAKES THIS HARD, AND MY FIRST VERSION GOT IT WRONG:
  //   busadapt8 latches `in_acc[8p+7:8p] <= pin_in` on the edge taken WHILE phase
  //   == p. So byte p must be sitting on pin_in DURING phase p. `pin_in` here is a
  //   flop, so it must be WRITTEN on the edge that ENTERS phase p — one phase
  //   AHEAD of where it is consumed. A registered host therefore runs a byte
  //   ahead of the bus; my first attempt drove byte p during phase p and was one
  //   byte late in every frame, which read as the core never fetching at all.
  //
  // ⭐ AND THE STRETCH IS WHAT MAKES BYTE 0 REACHABLE. Byte 0 must be on pin_in
  //   during phase 0, but the address low byte only APPEARS at phase 0 — so
  //   without a stretch the host would have to have driven byte 0 before it knew
  //   the address. Holding `sof` gives phase 0 extra cycles: the host samples the
  //   address on the first, looks up during the next LAT-1, drives byte 0 from a
  //   flop, and releases. in_acc[7:0] re-latches on every phase-0 edge, so the
  //   LAST value before release is the one that counts.
  reg [7:0]  addr_lo_r;
  reg [1:0]  kind_r;
  reg [3:0]  waitcnt;
  reg        serving;
  reg [7:0]  pin_in_r;
  reg [2:0]  bidx;            // which byte to place on pin_in NEXT
  integer    r3_violations = 0;

  // pin_in is a pure flop output. THIS is the registered property, structurally.
  always @(*) pin_in = pin_in_r;

  localparam T_IDLE = 2'b00, T_FETCH = 2'b01, T_LOAD = 2'b10, T_STORE = 2'b11;

  wire at_phase0 = (dut.u_bus.phase == 2'd0);

  // The served word, computed from FLOPPED state only — never from live pin_out.
  wire [31:0] fetch_word = progword({24'd0, addr_lo_r});
  wire [31:0] load_word  = {hmem[addr_lo_r+3], hmem[addr_lo_r+2],
                            hmem[addr_lo_r+1], hmem[addr_lo_r]};
  wire [31:0] serve_now  = (kind_r == T_LOAD) ? load_word : fetch_word;

  function [7:0] byte_of(input [31:0] w, input [2:0] k);
    case (k)
      3'd0: byte_of = w[7:0];   3'd1: byte_of = w[15:8];
      3'd2: byte_of = w[23:16]; default: byte_of = w[31:24];
    endcase
  endfunction

  always @(posedge clk) begin
    if (!rst_n) begin
      sof <= 1'b0; waitcnt <= 0; serving <= 0; pin_in_r <= 8'h00;
      addr_lo_r <= 0; kind_r <= T_FETCH; bidx <= 0;
    end else if (at_phase0 && !serving) begin
      // ---- SAMPLE: take addr[7:0] and TYPE off the pins (registered) --------
      addr_lo_r <= pin_out;
      kind_r    <= ph;                 // at phase 0 the phase pins carry TYPE
      if (STRETCH != 0 && LAT > 0) begin
        sof <= 1'b1; waitcnt <= LAT[3:0]; serving <= 1'b1;
      end else begin
        // CONTROL ARM: no stretch. The host cannot know the address in time, so
        // it must drive byte 0 from whatever it had — one frame stale.
        sof <= 1'b0; serving <= 1'b0;
        pin_in_r <= byte_of(serve_now, 3'd1);
        bidx <= 2;
      end
    end else if (serving) begin
      if (waitcnt > 1) begin
        waitcnt <= waitcnt - 1;        // still looking up; sof stays high
        pin_in_r <= byte_of(serve_now, 3'd0);   // park byte 0 on the pins
      end else begin
        // lookup done. Byte 0 is already on pin_in and will be latched by the
        // phase-0 edge that ends the stretch. Queue byte 1 for phase 1.
        sof <= 1'b0; waitcnt <= 0; serving <= 1'b0;
        pin_in_r <= byte_of(serve_now, 3'd1);
        bidx <= 2;
      end
    end else begin
      // ---- phases 1..3: keep running one byte ahead of the bus -------------
      pin_in_r <= byte_of(serve_now, bidx);
      bidx <= (bidx == 3) ? 3'd0 : bidx + 3'd1;
    end
  end

  // ---- R3: THE REGISTERED PROPERTY --------------------------------------------
  // ⛔ MY FIRST TWO ATTEMPTS AT A RUNTIME R3 WERE BOTH BAD AND I AM NAMING BOTH:
  //   (1) it ended in `&& 0` and could not fire — a check that cannot fail;
  //   (2) the replacement compared a pre-edge sample against a post-edge one and
  //       fired on EVERY cycle a flop legitimately changed (451 of them).
  // ⇒ THE OBSERVABLE DOES NOT EXIST AT THIS LEVEL. "pin_in changed at the same
  //   simulation time as pin_out" is TRUE OF BOTH host shapes here, because
  //   pin_out is combinational off `phase` and `phase` is itself a flop — so both
  //   a registered and a combinational host move at the posedge. A third bad
  //   check would be worse than none.
  // ✅ SO R3 IS STRUCTURAL, AND STATED AS STRUCTURAL RATHER THAN MEASURED:
  //   `pin_in` is assigned ONLY from `pin_in_r`; `pin_in_r` is written ONLY inside
  //   `always @(posedge clk)`; and every RHS feeding it (`addr_lo_r`, `kind_r`,
  //   `bidx`, `hmem`) is a flop or a memory. There is NO combinational path from
  //   `pin_out` to `pin_in` in this module. The BEHAVIOURAL evidence that this
  //   host is genuinely registered is R6: a combinational host would not need the
  //   stretch, and the no-stretch arm must go RED.
  // [[a-check-never-shown-to-fail]] [[the-observable-cannot-carry-the-answer]]

  // ---- store capture, mid-phase sampling (negedge) --------------------------
  reg [31:0] st_addr, st_data; reg st_addr_valid = 0; integer stores_done = 0;
  always @(negedge clk) if (rst_n) begin
    if (ph == T_STORE || dut.u_bus.kind == T_STORE) begin
      if (!dut.u_bus.store_beat) begin
        case (dut.u_bus.phase)
          2'd0: st_addr[7:0]   <= pin_out;  2'd1: st_addr[15:8]  <= pin_out;
          2'd2: st_addr[23:16] <= pin_out;
          2'd3: begin st_addr[31:24] <= pin_out; st_addr_valid <= 1'b1; end
        endcase
      end else begin
        case (dut.u_bus.phase)
          2'd0: st_data[7:0]   <= pin_out;  2'd1: st_data[15:8]  <= pin_out;
          2'd2: st_data[23:16] <= pin_out;
          2'd3: begin
            if (st_addr_valid) begin
              hmem[st_addr[7:0]  ] <= st_data[7:0];
              hmem[st_addr[7:0]+1] <= st_data[15:8];
              hmem[st_addr[7:0]+2] <= st_data[23:16];
              hmem[st_addr[7:0]+3] <= pin_out;
              stores_done = stores_done + 1;
              $display("    STORE commit: addr=%h data=%h%h%h%h",
                       st_addr, pin_out, st_data[23:16], st_data[15:8], st_data[7:0]);
            end
          end
        endcase
      end
    end
  end

  // ---- observation ----------------------------------------------------------
  integer load_loops = 0, stretch_seen = 0;
  always @(negedge clk) if (rst_n) begin
    if (dut.u_bus.phase == 2'd0 && dut.u_bus.kind == T_LOAD) begin
      load_loops = load_loops + 1;
      if (sof) stretch_seen = stretch_seen + 1;
    end
  end

  integer i;
  initial begin
    for (i = 0; i < 256; i = i + 1) hmem[i] = 8'h00;
    #1 rst_n = 0; repeat (4) @(posedge clk); rst_n = 1;
    repeat (900) @(posedge clk);

    $display("");
    $display("=== tb_plane32bus_reghost   LAT=%0d STRETCH=%0d ===", LAT, STRETCH);
    $display("R1 LOAD loops seen           = %0d  (stretch active on %0d)", load_loops, stretch_seen);
    $display("R2 x3 (the LW's destination) = %h   expected 00000040", dut.u_core.regs[3]);
    $display("R3 registered property        = STRUCTURAL, NOT MEASURED — pin_in is driven");
    $display("                                 only from a flop; no combinational path from");
    $display("                                 pin_out. The runtime counter was REMOVED because");
    $display("                                 the observable does not exist at this level.");
    $display("R4 hmem[64..67]              = %h%h%h%h  expected 00000040",
             hmem[67], hmem[66], hmem[65], hmem[64]);
    $display("   stores committed          = %0d", stores_done);
    $display("   x1                        = %h", dut.u_core.regs[1]);

    if (load_loops >= 1) $display("R1 PASS"); else $display("R1 FAIL");
    if (dut.u_core.regs[3] == 32'h00000040) $display("R2 PASS"); else $display("R2 FAIL");
    $display("R3 n/a  (structural — see the note above; do not read this as a PASS)");
    if ({hmem[67],hmem[66],hmem[65],hmem[64]} == 32'h00000040) $display("R4 PASS"); else $display("R4 FAIL");
    $finish;
  end
endmodule
