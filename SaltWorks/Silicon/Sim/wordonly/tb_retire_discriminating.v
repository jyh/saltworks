`timescale 1ns/1ps
// ============================================================================
// tb_retire_discriminating — THE POSITIVE ARM SILICON IS OWED (5f25f53).
//
// WHY silicon's bench could not discriminate (its own diagnosis, adopted):
//   tb_store_run_REFUTES_RULING.v drives the SAME word (SW) onto pin_in at every
//   phase regardless of the address the adapter asked for. That is a store-only
//   PROGRAM, not a hang, so "98 STORE loops, 0 separators" is the correct trace
//   for BOTH a hung machine and a perfectly advancing one. The type stream is
//   blind here BY CONSTRUCTION.
//
// WHAT THIS BENCH CHANGES — both of silicon's named remedies, together:
//   (R1) THE OBSERVABLE IS THE PC. core32's PC is reachable two ways: as the
//        register core.pc_r, and — the host's own view — as c_imem_addr, whose
//        four bytes are driven onto pin_out during every FETCH loop. Both are
//        measured, independently.
//   (R2) THE PROGRAM CONTAINS NON-STORE INSTRUCTIONS. The host is now an actual
//        memory: it answers with the word AT THE ADDRESS the adapter presents,
//        from a 4-word ROM that wraps on addr[3:2]:
//            +0  addi x1, x0, 64     0x04000093   (non-memory)
//            +4  sw   x2, 0(x1)      0x0020A023   (store, word)
//            +8  addi x2, x2, 1      0x00110113   (non-memory)
//            +c  lw   x3, 0(x1)      0x0000A183   (load, word)
//        A machine that advances must therefore emit FETCH loops a hung one
//        cannot, and must present a NEW address at each one.
//
// ARM SELECT — no committed file is edited; the arm is a +define on the
// iverilog line, wired to core32's `en` port only:
//   -DARM_EN_RETIRE   en = adapter's landed `retire` output      (POSITIVE)
//   -DARM_EN_HIGH     en = 1'b1                                  (NEGATIVE CTRL)
//   -DARM_EN_ZERO     en = 1'b0                                  (MUTANT: no retire)
//   -DARM_EN_INV      en = ~retire                               (MUTANT: inverted)
//
// PRE-REGISTERED PASS CRITERIA for the positive arm (stated before the run;
// each is a way the bench can go RED, which is the point):
//   C1  the PC changes at least once                       (the machine moves)
//   C2  PC-changed  <=>  retire was high the prior cycle   (design §4 inv. 2)
//   C3  zero TORN fetch frames — the address on the pins is ONE address for all
//       four phases of a FETCH loop                        (frame integrity)
//   C4  every consecutive pair of pin-observed fetch addresses differs by
//       exactly 4, over >= 4 fetch loops                   (in-order execution)
//   C5  FETCH separators exist and no STORE run exceeds 2  (design §4 inv. 3)
//   C6  x1 == 64 — the ADDI actually retired into the regfile (arch. progress)
// C1/C2/C6 read core state; C3/C4/C5 read ONLY pins. Two independent families.
// ============================================================================
module tb;
  reg clk=0, rst_n=0, sof=0;
  wire [31:0] imem_a, dmem_a, dmem_wd;
  wire        dmem_rq, dmem_we_w;
  wire [31:0] instr, rdata;
  wire [7:0]  pin_out;
  wire [1:0]  ph;
  wire        retire_w;
  reg  [7:0]  pin_in;

  // ---- the arm ------------------------------------------------------------
`ifdef ARM_EN_HIGH
  wire core_en = 1'b1;
  `define ARMTXT "ARM A  (NEGATIVE CONTROL) : core32.en = 1'b1        [ungated]"
`elsif ARM_EN_ZERO
  wire core_en = 1'b0;
  `define ARMTXT "MUTANT Z (control)        : core32.en = 1'b0        [retire held low]"
`elsif ARM_EN_INV
  wire core_en = ~retire_w;
  `define ARMTXT "MUTANT I (control)        : core32.en = ~retire      [enable inverted]"
`else
  wire core_en = retire_w;
  `define ARMTXT "ARM B  (POSITIVE)         : core32.en = retire      [the landed wire]"
`endif

  core32 core(.clk(clk),.rst_n(rst_n),.en(core_en),.instr(instr),.dmem_rdata(rdata),
    .dmem_addr(dmem_a),.dmem_wdata(dmem_wd),.dmem_be(),
    .dmem_req(dmem_rq),.dmem_we(dmem_we_w),.imem_addr(imem_a));
  busadapt8 ad(.clk(clk),.rst_n(rst_n),.sof(sof),
    .c_imem_addr(imem_a),.c_dmem_addr(dmem_a),.c_dmem_wdata(dmem_wd),
    .c_dmem_req(dmem_rq),.c_dmem_we(dmem_we_w),
    .c_instr(instr),.c_dmem_rdata(rdata),
    .pin_in(pin_in),.pin_out(pin_out),.phase_pins(ph),.retire(retire_w));

  always #5 clk=~clk;

  // ---- the host: an ADDRESSED memory, not a word generator ----------------
  localparam T_IDLE=2'b00, T_FETCH=2'b01, T_LOAD=2'b10, T_STORE=2'b11;
  function [31:0] progword; input [31:0] a;
    case (a[3:2])
      2'd0: progword = 32'h04000093;  // addi x1, x0, 64
      2'd1: progword = 32'h0020A023;  // sw   x2, 0(x1)
      2'd2: progword = 32'h00110113;  // addi x2, x2, 1
      default: progword = 32'h0000A183;  // lw x3, 0(x1)
    endcase
  endfunction
  // -DHOST_STOREONLY restores silicon's ORIGINAL host (the SW word at every phase,
  // the address ignored) so the two remedies can be told apart: R2 alone, R1 alone.
`ifdef HOST_STOREONLY
  wire [31:0] serve = 32'h0020A023;
`else
  wire [31:0] serve = (ad.kind==T_FETCH) ? progword(imem_a) : 32'hDEADBEEF;
`endif
  always @(*) case (ad.phase)
      2'd0: pin_in = serve[7:0];   2'd1: pin_in = serve[15:8];
      2'd2: pin_in = serve[23:16]; default: pin_in = serve[31:24];
  endcase

  // ---- observation --------------------------------------------------------
  integer cyc=0, pc_adv=0, couple_viol=0, retires=0;
  integer fetch_loops=0, store_loops=0, load_loops=0, idle_loops=0;
  integer torn_fetch=0, nfetch=0, strides_bad=0;
  integer stride, stride_min=2147483647, stride_max=-2147483647;
  integer run=0, maxrun=0, seps=0;
  integer gap=0, gmin=999999, gmax=0;
  integer d4=0, d8=0, d12=0, dother=0;   // retire-to-retire DISTANCE histogram
  reg [31:0] pc_prev, pc_now;
  reg        retire_prev;
  reg [31:0] f_a0,f_a1,f_a2,f_a3, pin_addr, prev_pin_addr;
  reg [7:0]  pb0,pb1,pb2,pb3;
  reg        seen0=1'b0, have_prev=1'b0;
  reg        chg;

  always @(negedge clk) if (rst_n) begin
    cyc  = cyc + 1;
    pc_now = core.pc_r;

    // --- C1/C2: the PC, and its coupling to retire ------------------------
    if (cyc > 1) begin
      chg = (pc_now !== pc_prev);
      if (chg) pc_adv = pc_adv + 1;
      if (chg !== (retire_prev === 1'b1)) couple_viol = couple_viol + 1;
    end

    if (retire_w === 1'b1) begin
      retires = retires + 1;
      if (gap < gmin) gmin = gap;
      if (gap > gmax) gmax = gap;
      if (retires > 1) case (gap + 1)                 // DISTANCE in cycles
        4:  d4  = d4  + 1;
        8:  d8  = d8  + 1;
        12: d12 = d12 + 1;
        default: dother = dother + 1;
      endcase
      gap = 0;
    end else gap = gap + 1;

    // --- C5: the type stream, read off the PHASE PINS at phase 0 ----------
    if (ad.phase == 2'd0) begin
      case (ph)                          // `ph` IS uio_out[1:0], a real pin
        T_FETCH: begin fetch_loops=fetch_loops+1; if(run>0) seps=seps+1; run=0; end
        T_LOAD : begin load_loops =load_loops +1; if(run>0) seps=seps+1; run=0; end
        T_STORE: begin store_loops=store_loops+1; run=run+1; if(run>maxrun) maxrun=run; end
        default: begin idle_loops =idle_loops +1; if(run>0) seps=seps+1; run=0; end
      endcase
      if (fetch_loops + store_loops + load_loops + idle_loops <= 24)
        $display("    loop @%0t  type=%b  pin_out=%h   pc_r=%h", $time, ph, pin_out, pc_now);
    end

    // --- C3/C4: the fetch address AS THE HOST SEES IT, byte by byte -------
    if (ad.kind == T_FETCH) begin
      case (ad.phase)
        2'd0: begin f_a0=imem_a; pb0=pin_out; seen0=1'b1; end
        2'd1: begin f_a1=imem_a; pb1=pin_out; end
        2'd2: begin f_a2=imem_a; pb2=pin_out; end
        2'd3: begin
          f_a3=imem_a; pb3=pin_out;
          if (seen0) begin
            pin_addr = {pb3,pb2,pb1,pb0};
            nfetch = nfetch + 1;
            if (!(f_a0===f_a1 && f_a1===f_a2 && f_a2===f_a3)) begin
              torn_fetch = torn_fetch + 1;
              if (torn_fetch <= 4)
                $display("    TORN fetch frame: addr per phase = %h %h %h %h  -> pins said %h",
                         f_a0,f_a1,f_a2,f_a3,pin_addr);
            end
            if (have_prev) begin
              stride = pin_addr - prev_pin_addr;
              if (stride < stride_min) stride_min = stride;
              if (stride > stride_max) stride_max = stride;
              if (stride != 4) strides_bad = strides_bad + 1;
            end
            prev_pin_addr = pin_addr; have_prev = 1'b1;
          end
          seen0 = 1'b0;
        end
      endcase
    end

    pc_prev = pc_now;  retire_prev = retire_w;
  end

  // ---- PROBE (optional, -DPROBE): what is actually EXECUTING? -------------
  // Not part of the pass criteria. It answers a separate question: an advancing
  // machine may still be executing the wrong instruction stream, and x2/x3
  // staying `x` in the positive arm is a fact that deserves a cause.
`ifdef PROBE
  integer wr[0:31]; integer wi;
  initial for (wi=0; wi<32; wi=wi+1) wr[wi]=0;
  always @(negedge clk) if (rst_n && core.en===1'b1 && core.reg_we===1'b1 && core.rd!==5'd0)
    wr[core.rd] = wr[core.rd] + 1;
  integer ploops=0;
  always @(negedge clk) if (rst_n && ad.phase==2'd0) begin
    ploops = ploops + 1;
    if (ploops <= 16)
      $display("    PROBE loop%0d  type=%b  pc=%h  instr_r=%h  req=%b we=%b  reg_we=%b rd=%0d",
               ploops, ph, core.pc_r, ad.instr_r, dmem_rq, dmem_we_w, core.reg_we, core.rd);
  end
`endif

  integer fails=0;
  initial begin
    $display("================================================================");
    $display(`ARMTXT);
    $display("================================================================");
    @(negedge clk); rst_n=1;
    repeat (400) @(negedge clk);
    $display("  ---- PC / retire (core state) --------------------------------");
    $display("  cycles observed          : %0d", cyc);
    $display("  retire fired             : %0d", retires);
    $display("  PC changed on            : %0d cycles", pc_adv);
    $display("  final PC                 : %h", core.pc_r);
    $display("  PC-advance <=> retire violations : %0d", couple_viol);
    $display("  retire-to-retire DISTANCE: min %0d  max %0d cycles", gmin+1, gmax+1);
    $display("  distance histogram       : 4cyc=%0d  8cyc=%0d  12cyc=%0d  other=%0d",
             d4, d8, d12, dother);
    $display("  ---- the pins ------------------------------------------------");
    $display("  FETCH loops              : %0d", fetch_loops);
    $display("  STORE loops              : %0d   (longest run %0d)", store_loops, maxrun);
    $display("  LOAD  loops              : %0d", load_loops);
    $display("  IDLE  loops              : %0d", idle_loops);
    $display("  separator events         : %0d", seps);
    $display("  fetch frames completed   : %0d", nfetch);
    $display("  TORN fetch frames        : %0d", torn_fetch);
    if (nfetch > 1)
      $display("  pin fetch-addr stride    : min %0d  max %0d   (must be 4)", stride_min, stride_max);
    else
      $display("  pin fetch-addr stride    : n/a (fewer than 2 fetch frames)");
    $display("  strides != 4             : %0d", strides_bad);
    $display("  ---- architectural state -------------------------------------");
    $display("  x1 = %h   (must be 00000040)   x2 = %h   x3 = %h",
             core.regs[1], core.regs[2], core.regs[3]);
`ifdef PROBE
    $display("  regfile WRITE counts     : x1=%0d  x2=%0d  x3=%0d", wr[1], wr[2], wr[3]);
`endif
    $display("  ---- pre-registered criteria ---------------------------------");
    if (!(pc_adv > 0))            begin fails=fails+1; $display("  C1 FAIL  the PC never changed"); end
    else                                              $display("  C1 pass  the PC advances");
    if (!(couple_viol == 0))      begin fails=fails+1; $display("  C2 FAIL  %0d PC/retire coupling violations", couple_viol); end
    else                                              $display("  C2 pass  PC advances exactly once per retire");
    if (!(torn_fetch == 0))       begin fails=fails+1; $display("  C3 FAIL  %0d torn fetch frames", torn_fetch); end
    else                                              $display("  C3 pass  every fetch frame carries ONE address");
    if (!(strides_bad == 0 && nfetch >= 4)) begin fails=fails+1; $display("  C4 FAIL  %0d bad strides over %0d fetch frames", strides_bad, nfetch); end
    else                                              $display("  C4 pass  consecutive fetch addresses differ by exactly 4");
    if (!(fetch_loops > 0 && maxrun <= 2 && seps > 0)) begin fails=fails+1; $display("  C5 FAIL  fetch=%0d maxSTORErun=%0d seps=%0d", fetch_loops, maxrun, seps); end
    else                                              $display("  C5 pass  FETCH separators present, store runs bounded by 2");
    if (!(core.regs[1] === 32'd64)) begin fails=fails+1; $display("  C6 FAIL  x1 = %h, not 00000040", core.regs[1]); end
    else                                              $display("  C6 pass  x1 == 64: the ADDI retired");
    if (fails==0) $display("  ==> ALL PASS (6/6) — THE MACHINE ADVANCES");
    else          $display("  ==> RED: %0d/6 criteria FAILED", fails);
    $finish;
  end
endmodule
