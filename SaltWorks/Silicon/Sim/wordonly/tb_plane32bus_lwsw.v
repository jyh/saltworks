`timescale 1ns/1ps
// ============================================================================
// tb_plane32bus_lwsw — RUNG ZERO DELIVERABLE (4): ONE LW AND ONE SW THROUGH THE
// PINS, ON THE SHIPPING PLANE, WITH AN ADDRESSED MEMORY AND A CHECKED DATA PATH.
//
// TRACKED ON PURPOSE. The 08/17 executor harness that ruled the enable is
// UNTRACKED scratch (ScratchRETIRE-tb.v) — its protocol handling is excellent and
// this bench follows it, with credit — but a receipt that lives in an untracked
// file dies with a `git clean`. This one is committed.
//
// ── WHAT THIS ADDS OVER EVERY EXISTING ARM ─────────────────────────────────────
// The executor host serves `32'hDEADBEEF` for a LOAD: enough to exercise the LOAD
// path (14 load loops, 6/6) and NOT enough to check that a loaded VALUE ARRIVES.
// ⇒ THIS BENCH SERVES LOADS FROM AN ADDRESSED MEMORY and asserts the LOADED WORD
//   REACHES A REGISTER. The LW data path has not been checked end to end before.
//
// ── THE ASSUMPTION THIS BENCH MAKES, AND IT IS §7's OWN ────────────────────────
// A load's address bytes and its returned data bytes SHARE THE SAME FOUR CYCLES:
// at phase p the adapter drives addr[8p+7:8p] on pin_out and latches pin_in into
// in_acc[8p+7:8p]. So the host must present data[7:0] in the SAME CYCLE it first
// sees addr[7:0].
// ⚠️ I NEARLY PUBLISHED THAT THIS IS CIRCULAR BY CONSTRUCTION. IT IS NOT. A
//   COMBINATIONAL (async-SRAM-like) host reads pin_out and drives pin_in in the
//   same delta cycle, which is exactly what §7 calls "an assumption about THE HOST,
//   not about this design". This bench IS that host, deliberately.
// ⇒ SO A GREEN HERE MEASURES THE DESIGN UNDER §7's STATED ASSUMPTION AND SAYS
//   NOTHING ABOUT A REGISTERED HOST. A host that cannot turn a read around in-phase
//   needs §7's "+4" second loop, which this bench does NOT model and which remains
//   the open question §7 named. Do not read this green as closing it.
//
// ── PRE-REGISTERED CRITERIA (published before the first run) ───────────────────
//   L1  at least one LOAD loop and one STORE loop appear on the TYPE pins
//   L2  the SW writes the RIGHT WORD to the RIGHT ADDRESS in host memory
//   L3  the LW's loaded word REACHES A REGISTER (the data path, end to end)
//   L4  every retire coincides with a PC advance, and no PC advance without one
//   L5  the store owns exactly TWO consecutive loops (address, then data) — §7
//   L6  the fetch address stride is 4 on every fetch frame
// ============================================================================
module tb;
  reg clk = 0, rst_n = 0, sof = 0;
  wire [7:0] pin_out;  wire [1:0] ph;  wire retire_w;
  reg  [7:0] pin_in;

  plane32bus dut(.clk(clk), .rst_n(rst_n), .sof(sof),
                 .instr_byte(pin_in), .addr_byte(pin_out),
                 .phase_o(ph), .retire(retire_w));
  always #5 clk = ~clk;

  localparam T_IDLE=2'b00, T_FETCH=2'b01, T_LOAD=2'b10, T_STORE=2'b11;

  // ---- the program. x1 = 64; store x1 to [64]; then load it back into x3. ----
  // Chosen so L2 and L3 are INDEPENDENT: the stored value is a register the ADDI
  // set, and the loaded value must equal it via MEMORY rather than via a bypass.
  function [31:0] progword; input [31:0] a;
    case (a[3:2])
      2'd0: progword = 32'h04000093;  // addi x1, x0, 64
      2'd1: progword = 32'h0010A023;  // sw   x1, 0(x1)      -> mem[64] = 64
      2'd2: progword = 32'h0000A183;  // lw   x3, 0(x1)      -> x3 = mem[64]
      default: progword = 32'h00000013; // nop (addi x0,x0,0)
    endcase
  endfunction

  // ---- host memory, byte-addressed, 256 B ----------------------------------
  reg [7:0] hmem [0:255];
  integer i;

  // The adapter's live view, used ONLY to model the host's own knowledge: the host
  // legitimately knows the phase (it is on the pins) and the type (phase 0), and it
  // reconstructs the address from the bytes it is being handed.
  reg [31:0] addr_seen;
  always @(*) begin
    addr_seen = 32'h0;
    addr_seen[7:0] = pin_out;      // phase 0 byte, available in THIS cycle
  end

  // ---- the COMBINATIONAL host: serve fetch from the program, load from memory --
  wire [31:0] fetch_word = progword(dut.u_bus.c_imem_addr);
  wire [7:0]  la = pin_out;        // during a LOAD loop phase 0 this IS addr[7:0]
  reg  [31:0] load_word;
  always @(*) load_word = {hmem[la+3], hmem[la+2], hmem[la+1], hmem[la]};

  wire [31:0] serve = (dut.u_bus.kind == T_FETCH) ? fetch_word
                    : (dut.u_bus.kind == T_LOAD)  ? load_word
                    : 32'h0;
  always @(*) case (dut.u_bus.phase)
      2'd0: pin_in = serve[7:0];    2'd1: pin_in = serve[15:8];
      2'd2: pin_in = serve[23:16];  default: pin_in = serve[31:24];
  endcase

  // ---- STORE capture: address in the first loop, data in the second ---------
  reg [31:0] st_addr, st_data;
  reg        st_addr_valid;
  integer    stores_done = 0;
  // ⛔ NEGEDGE, NOT POSEDGE. `pin_out` is combinational off `phase`, so sampling at
  // the posedge samples the boundary where phase is changing — the tracked
  // tb_busadapt8.v uses `always @(negedge clk)` for exactly this reason and my first
  // version ignored it. THE BENCH WAS WRONG, NOT THE ADAPTER (this kit's own 08/17
  // precedent, 323ee32). Mid-phase is the only unambiguous sampling point.
  always @(negedge clk) if (rst_n) begin
    if (dut.u_bus.kind == T_STORE) begin
      if (!dut.u_bus.store_beat) begin
        case (dut.u_bus.phase)
          2'd0: st_addr[7:0]   <= pin_out;   2'd1: st_addr[15:8]  <= pin_out;
          2'd2: st_addr[23:16] <= pin_out;
          2'd3: begin st_addr[31:24] <= pin_out; st_addr_valid <= 1'b1; end
        endcase
      end else begin
        case (dut.u_bus.phase)
          2'd0: st_data[7:0]   <= pin_out;   2'd1: st_data[15:8]  <= pin_out;
          2'd2: st_data[23:16] <= pin_out;
          2'd3: begin
            st_data[31:24] <= pin_out;
            if (st_addr_valid) begin
              hmem[st_addr[7:0]  ] <= st_data[7:0];
              hmem[st_addr[7:0]+1] <= st_data[15:8];
              hmem[st_addr[7:0]+2] <= st_data[23:16];
              hmem[st_addr[7:0]+3] <= pin_out;
              stores_done = stores_done + 1;
              if (stores_done <= 3)
                $display("    STORE#%0d commit: st_addr=%h st_data=%h core_addr=%h core_wd=%h | instr=%h rs2=%0d regs1=%h regs3=%h", stores_done, st_addr, st_data, dut.u_bus.c_dmem_addr, dut.u_bus.c_dmem_wdata, dut.u_bus.c_instr, dut.u_bus.c_instr[24:20], dut.u_core.regs[1], dut.u_core.regs[3]);
            end
          end
        endcase
      end
    end
  end

  // ---- observation ---------------------------------------------------------
  integer fetch_loops=0, load_loops=0, store_loops=0, idle_loops=0;
  integer run=0, maxrun=0, retires=0, pc_adv=0, couple_viol=0;
  integer nfetch=0, strides_bad=0, fails=0;
  reg [31:0] pc_prev, pc_now, fa;
  reg        retire_prev;
  reg        seen_pc;
  reg        seen_fetch = 0;

  always @(negedge clk) if (rst_n) begin
    pc_now = dut.u_bus.c_imem_addr;
    if (retire_w) retires = retires + 1;
    // ⛔⛔ L4's IMPLEMENTATION WAS A CHECK THAT COULD NOT PASS, AND THAT IS MY OWN
    // BANKED DEFECT SITTING IN A TRACKED BENCH. First version asked whether
    // `retire_w` was high IN THE SAME SAMPLE as the PC change — but `retire`
    // asserts at loop_end (phase 3) and the PC updates on the FOLLOWING edge, so
    // the change is always observed one sample AFTER retire has gone low. It
    // flagged 87 of 87 advances: the signature of an unsatisfiable criterion, not
    // of a machine that never couples.
    // ⚠️ THE CRITERION IS UNCHANGED — "no PC advance without a retire". Only the
    //   SAMPLING is fixed, against `retire_prev`, exactly as the 08/17 executor
    //   bench does (it declares that register for this reason and I did not read it
    //   closely enough). WEAKENING a criterion on the day it fires would make it
    //   untrustworthy; making an unsatisfiable one TESTABLE is the opposite act.
    // 📌 And leaving it permanently red had its own cost: an alarm that always
    //   sounds is an alarm nobody hears, which is this kit's own law.
    // ⛔ AND THE FIRST OBSERVATION IS NOT AN ADVANCE. With pc_prev seeded to a
    // sentinel, sample 1 compared ffffffff against the real PC of 0 and counted it —
    // one violation out of 87, entirely mine. `seen_pc` gates it. Confirmed by
    // PRINTING the violation rather than assuming it was the reset edge.
    if (pc_now !== pc_prev && seen_pc) begin
      pc_adv = pc_adv + 1;
`ifdef MUT_BREAK_COUPLE
      if (1'b1) begin      // MUTATION CONTROL: force the arm, L4 must go RED
`else
      if (!retire_prev) begin
`endif
        couple_viol = couple_viol + 1;
        $display("    COUPLE-VIOL #%0d @%0t  pc %h -> %h  (retire_prev=%b)", couple_viol, $time, pc_prev, pc_now, retire_prev);
      end
    end
    retire_prev = retire_w;
    pc_prev = pc_now; seen_pc = 1;

    if (dut.u_bus.phase == 2'd0) begin
      case (ph)
        T_FETCH: begin fetch_loops=fetch_loops+1; run=0;
                       if (seen_fetch && (pc_now - fa) != 32'd4 && (pc_now !== fa))
                         strides_bad = strides_bad + 1;
                       fa = pc_now; seen_fetch = 1; nfetch = nfetch + 1; end
        T_LOAD : begin load_loops =load_loops +1; run=0;
                       if (load_loops <= 3)
                         $display("    LOAD#%0d phase0 pin_out=%h la=%h load_word=%h core_addr=%h", load_loops, pin_out, la, load_word, dut.u_bus.c_dmem_addr); end
        T_STORE: begin store_loops=store_loops+1; run=run+1;
                       if (run>maxrun) maxrun=run; end
        default: begin idle_loops =idle_loops +1; run=0; end
      endcase
    end
  end

  task chk; input cond; input [8*48:1] name;
    begin
      if (cond) $display("  L-pass  %0s", name);
      else begin $display("  L-FAIL  %0s", name); fails = fails + 1; end
    end
  endtask

  initial begin
    for (i=0; i<256; i=i+1) hmem[i] = 8'h00;
    st_addr = 0; st_data = 0; st_addr_valid = 0; pc_prev = 32'hFFFFFFFF; retire_prev = 0; seen_pc = 0;
    $display("=== tb_plane32bus_lwsw — ONE LW AND ONE SW THROUGH THE PINS ===");
    @(negedge clk); rst_n = 1;
    repeat (600) @(posedge clk);

    $display("  loops: FETCH=%0d LOAD=%0d STORE=%0d IDLE=%0d (longest STORE run %0d)",
             fetch_loops, load_loops, store_loops, idle_loops, maxrun);
    $display("  retires=%0d  pc advances=%0d  advance-without-retire=%0d",
             retires, pc_adv, couple_viol);
    $display("  stores completed=%0d  mem[64..67]=%h%h%h%h  x1=%h  x3=%h",
             stores_done, hmem[67], hmem[66], hmem[65], hmem[64],
             dut.u_core.regs[1], dut.u_core.regs[3]);
    $display("  ---- pre-registered criteria ----");
    chk(load_loops  > 0 && store_loops > 0,             "L1 a LOAD and a STORE both appear on the pins");
    chk({hmem[67],hmem[66],hmem[65],hmem[64]} == 32'd64,"L2 the SW wrote the right word to the right address");
    chk(dut.u_core.regs[3] == 32'd64,                   "L3 the LW's word REACHED A REGISTER (data path)");
    chk(couple_viol == 0,                               "L4 no PC advance without a retire");
    chk(maxrun == 2,                                    "L5 a store owns exactly TWO consecutive loops");
    chk(strides_bad == 0,                               "L6 fetch stride is 4 on every frame");
    if (fails == 0) $display("==> ALL PASS (6/6)");
    else            $display("==> RED: %0d/6 criteria FAILED", fails);
    $finish;
  end
endmodule
