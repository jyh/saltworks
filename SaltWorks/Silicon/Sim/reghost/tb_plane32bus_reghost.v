`timescale 1ns/1ps
// ============================================================================
// tb_plane32bus_reghost — THE LW/SW PLANE SERVED BY A **REGISTERED** HOST.
//
// Criteria G1-G6 and the red-first bar are PRE-REGISTERED in
// docs/silicon-ndf-option2-plus4-prereg-0904.md, written before this file existed.
//
// ── WHY THIS BENCH EXISTS ─────────────────────────────────────────────────────
// tb_plane32bus_lwsw.v says so itself, in its own scope block: *"A COMBINATIONAL
// (async-SRAM-like) host reads pin_out and drives pin_in in the same delta cycle
// ... SO A GREEN HERE ... SAYS NOTHING ABOUT A REGISTERED HOST."* The RP2040 as a
// PIO memory server IS a registered host. This bench is that host.
//
// ⭐ THE ONE PROPERTY THAT DEFINES IT: **`din_r` IS A FLOP.** The host can never
//   answer in the cycle it is asked. Nothing else here is the experiment.
//
// ── ⛔ DECLARED SCOPE — THE FETCH PATH IS *NOT* REGISTERED HERE ────────────────
// Ratified option (2) gives "+4" to §7's **LOAD row only**, while §7's own text
// says the load's assumption holds *"exactly as the instruction does during a
// fetch"*. So the fetch still demands an in-phase turnaround and (2) does not
// change that. This bench therefore serves FETCH combinationally — the SAME
// concession tb_plane32bus_lwsw.v makes, kept identical so the two are comparable
// — and isolates the LOAD row, which is the row (2) is about.
// ⇒ `REGHOST_FETCH` makes the fetch registered too. It is a MEASUREMENT OF THE
//   GAP, pre-registered in §5 of the prereg as a NEW row, and it is NOT part of (2).
// ============================================================================
module tb;
  reg clk = 0, rst_n = 0;
  wire [7:0] pin_out;  wire [1:0] ph;  wire retire_w;
  wire [7:0] pin_in;
  reg  sof = 0;

  plane32bus dut(.clk(clk), .rst_n(rst_n), .sof(sof),
                 .instr_byte(pin_in), .addr_byte(pin_out),
                 .phase_o(ph), .retire(retire_w));
  always #5 clk = ~clk;

  localparam T_IDLE=2'b00, T_FETCH=2'b01, T_LOAD=2'b10, T_STORE=2'b11;

  // ---- the program, byte-identical to the tracked bench ----------------------
  function [31:0] progword; input [31:0] a;
    case (a[3:2])
      2'd0: progword = 32'h04000093;  // addi x1, x0, 64
      2'd1: progword = 32'h0010A023;  // sw   x1, 0(x1)      -> mem[64] = 64
      2'd2: progword = 32'h0000A183;  // lw   x3, 0(x1)      -> x3 = mem[64]
      default: progword = 32'h00000013; // nop
    endcase
  endfunction

  reg [7:0] hmem [0:255];
  integer i;

  // ==========================================================================
  // THE REGISTERED HOST
  //
  // It owns its own phase counter, aligned by the `sof` IT drives (busadapt8
  // decision 2: `sof` is a host-driven realign, so the host KNOWS where phase 0
  // is because it asserted it). It therefore never reads the DUT's phase.
  // ==========================================================================
  reg [1:0] hphase;
  always @(posedge clk)
    if (!rst_n)   hphase <= 2'd0;
    else if (sof) hphase <= 2'd0;
    else          hphase <= hphase + 2'd1;

  reg [1:0] htype;                       // TYPE, latched at the phase-0 edge
  reg [7:0] a0, a1, a2, a3;              // address bytes as they are handed over
  reg       hbeat;                       // 0 = first loop of a transaction, 1 = second
  reg [31:0] hword;                      // the word this host will stream back
  reg [7:0] din_r;                       // ⭐ THE FLOP. The whole experiment.
  reg       ld_serving;                  // this loop is a LOAD's DATA loop

  // ⛔ THE FETCH CONCESSION, ISOLATED TO THIS ONE MUX AND NOWHERE ELSE.
  wire [31:0] fetch_word = progword(dut.u_bus.c_imem_addr);
  reg  [7:0]  fetch_byte;
  always @(*) case (dut.u_bus.phase)
      2'd0: fetch_byte = fetch_word[7:0];    2'd1: fetch_byte = fetch_word[15:8];
      2'd2: fetch_byte = fetch_word[23:16];  default: fetch_byte = fetch_word[31:24];
  endcase
`ifdef REGHOST_FETCH
  // THE GAP ARM: the fetch is registered too. Pre-registered as a NEW row.
  assign pin_in = din_r;
`else
  assign pin_in = (dut.u_bus.kind == T_FETCH) ? fetch_byte : din_r;
`endif

  // the host's own store memory-write bookkeeping
  reg [31:0] st_addr, st_data;
  integer    stores_done = 0;

  always @(posedge clk) if (!rst_n) begin
    htype <= T_IDLE; hbeat <= 1'b0; ld_serving <= 1'b0; din_r <= 8'h00;
    a0 <= 0; a1 <= 0; a2 <= 0; a3 <= 0; hword <= 0;
  end else begin
    // --- what the host is handed this cycle, sampled at the edge --------------
    if (hphase == 2'd0) htype <= ph;      // at phase 0 the TYPE pins carry the type
    case (hphase)
      2'd0: a0 <= pin_out;  2'd1: a1 <= pin_out;
      2'd2: a2 <= pin_out;  default: a3 <= pin_out;
    endcase

    // --- serving a LOAD's data loop: one byte per phase, all from the flop ----
    if (ld_serving) begin
      case (hphase)
        2'd0: din_r <= hword[15:8];
        2'd1: din_r <= hword[23:16];
        2'd2: din_r <= hword[31:24];
        2'd3: begin ld_serving <= 1'b0; din_r <= 8'h00; end
      endcase
    end

    // --- loop boundary: advance the host's own transaction beat --------------
    if (hphase == 2'd3) begin
      if ((htype == T_LOAD || htype == T_STORE) && !hbeat) begin
        hbeat <= 1'b1;
        if (htype == T_LOAD) begin
          // ⭐ THE "+4" THE HOST IS COUNTING ON: it has had the whole address
          // loop to look the word up, and drives byte 0 on the NEXT phase 0.
          hword      <= {hmem[a0+3], hmem[a0+2], hmem[a0+1], hmem[a0]};
          din_r      <= hmem[a0];
          ld_serving <= 1'b1;
        end
      end else begin
        hbeat <= 1'b0;
      end

      // a STORE's data loop has just completed: commit it
      if (htype == T_STORE && hbeat) begin
        hmem[st_addr[7:0]  ] <= a0;   hmem[st_addr[7:0]+1] <= a1;
        hmem[st_addr[7:0]+2] <= a2;   hmem[st_addr[7:0]+3] <= pin_out;
        st_data <= {pin_out, a2, a1, a0};
        stores_done = stores_done + 1;
      end
      if (htype == T_STORE && !hbeat) st_addr <= {pin_out, a2, a1, a0};
    end
  end

  // ==========================================================================
  // THE OBSERVER — a logic analyzer on the pins. Not the host.
  // ==========================================================================
  integer fetch_loops=0, load_loops=0, store_loops=0, idle_loops=0;
  integer srun=0, maxsrun=0, lrun=0, maxlrun=0;
  integer retires=0, pc_adv=0, couple_viol=0, fails=0;
  reg [31:0] pc_prev, pc_now;
  reg        retire_prev, seen_pc;

  always @(negedge clk) if (rst_n) begin
    pc_now = dut.u_bus.c_imem_addr;
    if (retire_w) retires = retires + 1;
    if (pc_now !== pc_prev && seen_pc) begin
      pc_adv = pc_adv + 1;
      if (!retire_prev) couple_viol = couple_viol + 1;
    end
    retire_prev = retire_w; pc_prev = pc_now; seen_pc = 1;

    if (dut.u_bus.phase == 2'd0) case (ph)
        T_FETCH: begin fetch_loops=fetch_loops+1; srun=0; lrun=0; end
        T_LOAD : begin load_loops =load_loops +1; srun=0; lrun=lrun+1;
                       if (lrun>maxlrun) maxlrun=lrun; end
        T_STORE: begin store_loops=store_loops+1; lrun=0; srun=srun+1;
                       if (srun>maxsrun) maxsrun=srun; end
        default: begin idle_loops =idle_loops +1; srun=0; lrun=0; end
    endcase
  end

  // ---- L7's count criterion, carried over VERBATIM from the tracked bench ----
  integer n_sw_fetched = 0, n_store_done = 0, store_unaccounted = 0;
  reg     sw_pending = 1'b0;
  always @(posedge clk) if (rst_n) begin
    if (dut.u_bus.kind == 2'b01 && dut.u_bus.phase == 2'd3
        && dut.u_bus.c_dmem_req && dut.u_bus.c_dmem_we) begin
      n_sw_fetched = n_sw_fetched + 1;
      sw_pending <= 1'b1;
    end
    if (dut.u_bus.kind == 2'b11 && dut.u_bus.store_beat
        && dut.u_bus.phase == 2'd3 && retire_w) begin
      n_store_done = n_store_done + 1;
      if (!sw_pending) store_unaccounted = store_unaccounted + 1;
      sw_pending <= 1'b0;
    end
  end

  // ── THE PIN TRACE, FOR THE FIRMWARE REPLAY CHECK ────────────────────────────
  // One line per DUT cycle, sampled at the NEGEDGE — mid-phase, the only
  // unambiguous sampling point (this kit's 08/17 precedent, 323ee32). The fields
  // are EXACTLY what a real host can see (`phase_pins`, `uo_out`) plus the byte
  // this bench drove (`ui_in`), so the RP2040 firmware's state machine can be
  // replayed against it and compared byte for byte at every phase the DUT
  // actually consumes.
`ifdef TRACE
  always @(negedge clk) if (rst_n) $display("TRACE %0d %02h %02h", ph, pin_out, pin_in);
`endif

  task chk; input cond; input [8*72:1] name;
    begin
      if (cond) $display("  G-pass  %0s", name);
      else begin $display("  G-FAIL  %0s", name); fails = fails + 1; end
    end
  endtask

  initial begin
    // ⛔ NON-ZERO BACKGROUND, AND IT IS A PERMANENT CONTROL. An all-zero memory is
    //   what let the TRACKED bench's address-incoherent host score green for its
    //   whole life (repaired 2026-09-04; `x3=0xaaaaaa40` under exactly this fill).
    //   This host LATCHES the address across the loop and is green under it — the
    //   fill is kept so that property is GUARDED and not merely once-measured.
    for (i=0; i<256; i=i+1) hmem[i] = 8'hAA;
    hmem[64]=8'h00; hmem[65]=8'h00; hmem[66]=8'h00; hmem[67]=8'h00;
    st_addr = 0; st_data = 0; pc_prev = 32'hFFFFFFFF; retire_prev = 0; seen_pc = 0;
    $display("=== tb_plane32bus_reghost — A REGISTERED HOST ON THE BYTE-PHASE BUS ===");
    @(negedge clk); rst_n = 1;
    repeat (900) @(posedge clk);

    $display("  loops: FETCH=%0d LOAD=%0d STORE=%0d IDLE=%0d (longest LOAD run %0d, STORE run %0d)",
             fetch_loops, load_loops, store_loops, idle_loops, maxlrun, maxsrun);
    $display("  retires=%0d  pc advances=%0d  advance-without-retire=%0d",
             retires, pc_adv, couple_viol);
    $display("  stores completed=%0d  mem[64..67]=%h%h%h%h  x1=%h  x3=%h",
             stores_done, hmem[67], hmem[66], hmem[65], hmem[64],
             dut.u_core.regs[1], dut.u_core.regs[3]);
    $display("  store transactions completed = %0d   SW fetched = %0d   UNACCOUNTED = %0d",
             n_store_done, n_sw_fetched, store_unaccounted);
    $display("  ---- pre-registered criteria (prereg 0904 §3) ----");
    chk(load_loops > 0 && store_loops > 0,               "G1 a LOAD and a STORE both appear on the pins");
    chk({hmem[67],hmem[66],hmem[65],hmem[64]} == 32'd64, "G2 the SW wrote the right word to the right address");
    chk(dut.u_core.regs[3] == 32'd64,                    "G3 the LW's word REACHED A REGISTER via a REGISTERED host");
    chk(maxlrun == 2,                                    "G4 a LOAD owns exactly TWO consecutive loops (the +4)");
    chk(couple_viol == 0,                                "G5 no PC advance without a retire");
    chk(store_unaccounted == 0,                          "G6 no store completes without a SW fetch (L7 carried over)");
    if (fails == 0) $display("==> ALL PASS (6/6)");
    else            $display("==> RED: %0d/6 criteria FAILED", fails);
    $finish;
  end
endmodule
