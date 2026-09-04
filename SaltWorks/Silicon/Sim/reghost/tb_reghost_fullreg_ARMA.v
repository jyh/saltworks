`timescale 1ns/1ps
// tb_reghost_fullreg_ARMA — FACT-FINDING FOR FORK ARM (A). ⛔ NOT A RATIFIED DESIGN.
//
// ⛔⛔ WHAT THIS IS AND IS NOT. Arm (A) — a symmetric "+4" on §7's FETCH row — is an
//   UNRATIFIED option needing its own two signatures. NOTHING HERE CHANGES THE
//   SHIPPED RTL, and there is deliberately NO second copy of `busadapt8.v` in this
//   tree: `run_armA_factfinding.sh` DERIVES the variant from the shipped file into a
//   temp dir at run time, exactly as the mutation arms do. A dead twin of a ratified
//   module is this seat's most expensive recurring defect and one is not created here.
//
// ⭐ WHY IT EXISTS: I posted a PRICE for arm (A) computed by arithmetic and never
//   drove it. A forecast is the one kind of claim nobody runs a control on. This
//   measures whether (A) actually closes the gap, and what it actually costs.
//
// THE HOST IS FULLY REGISTERED — `assign pin_in = din_r;` and nothing else. There is
// no combinational concession anywhere, unlike tb_plane32bus_reghost.v, which serves
// the FETCH combinationally because option (2) leaves that row in-phase.
module tb;
  reg clk = 0, rst_n = 0; reg sof = 0;
  wire [7:0] pin_out; wire [1:0] ph; wire retire_w; wire [7:0] pin_in;
  plane32bus dut(.clk(clk), .rst_n(rst_n), .sof(sof), .instr_byte(pin_in),
                 .addr_byte(pin_out), .phase_o(ph), .retire(retire_w));
  always #5 clk = ~clk;
  localparam T_IDLE=2'b00, T_FETCH=2'b01, T_LOAD=2'b10, T_STORE=2'b11;

  function [31:0] progword; input [31:0] a;
    case (a[3:2])
      2'd0: progword = 32'h04000093;  2'd1: progword = 32'h0010A023;
      2'd2: progword = 32'h0000A183;  default: progword = 32'h00000013;
    endcase
  endfunction

  reg [7:0] hmem [0:255]; integer i;

  // ---- the FULLY registered host -------------------------------------------
  reg [1:0] hphase;
  always @(posedge clk) if (!rst_n) hphase <= 2'd0;
                        else if (sof) hphase <= 2'd0; else hphase <= hphase + 2'd1;
  reg [1:0] htype; reg hbeat, serving;
  reg [7:0] a0,a1,a2,a3; reg [31:0] hword; reg [7:0] din_r;
  reg [31:0] st_addr; integer stores_done = 0;
  assign pin_in = din_r;                     // <- NO combinational path. At all.

  always @(posedge clk) if (!rst_n) begin
    htype<=T_IDLE; hbeat<=0; serving<=0; din_r<=0; a0<=0;a1<=0;a2<=0;a3<=0; hword<=0;
  end else begin
    if (hphase == 2'd0) htype <= ph;
    case (hphase) 2'd0: a0<=pin_out; 2'd1: a1<=pin_out; 2'd2: a2<=pin_out; default: a3<=pin_out; endcase

    if (serving) case (hphase)
        2'd0: din_r <= hword[15:8];
        2'd1: din_r <= hword[23:16];
        2'd2: din_r <= hword[31:24];
        2'd3: begin serving <= 1'b0; din_r <= 8'h00; end
    endcase

    if (hphase == 2'd3) begin
      if (!hbeat) begin
        hbeat <= 1'b1;                       // EVERY type now owns a second loop
        if (htype == T_FETCH) begin
          hword <= progword({24'd0, a0}); din_r <= progword({24'd0, a0}) & 32'hFF; serving <= 1'b1;
        end else if (htype == T_LOAD) begin
          hword <= {hmem[a0+3],hmem[a0+2],hmem[a0+1],hmem[a0]}; din_r <= hmem[a0]; serving <= 1'b1;
        end else if (htype == T_STORE) begin
          st_addr <= {pin_out, a2, a1, a0};
        end
      end else begin
        hbeat <= 1'b0;
        if (htype == T_STORE) begin
          hmem[st_addr[7:0]  ] <= a0;  hmem[st_addr[7:0]+1] <= a1;
          hmem[st_addr[7:0]+2] <= a2;  hmem[st_addr[7:0]+3] <= pin_out;
          stores_done = stores_done + 1;
        end
      end
    end
  end

  // ---- observer -------------------------------------------------------------
  integer fetch_loops=0, load_loops=0, store_loops=0, idle_loops=0;
  integer lrun=0, maxlrun=0, frun=0, maxfrun=0, srun=0, maxsrun=0;
  integer retires=0, pc_adv=0, couple_viol=0, fails=0;
  reg [31:0] pc_prev, pc_now; reg retire_prev, seen_pc;
  always @(negedge clk) if (rst_n) begin
    pc_now = dut.u_bus.c_imem_addr;
    if (retire_w) retires = retires + 1;
    if (pc_now !== pc_prev && seen_pc) begin
      pc_adv = pc_adv + 1; if (!retire_prev) couple_viol = couple_viol + 1;
    end
    retire_prev = retire_w; pc_prev = pc_now; seen_pc = 1;
    if (dut.u_bus.phase == 2'd0) case (ph)
        T_FETCH: begin fetch_loops=fetch_loops+1; srun=0;lrun=0;frun=frun+1; if(frun>maxfrun) maxfrun=frun; end
        T_LOAD : begin load_loops =load_loops +1; srun=0;frun=0;lrun=lrun+1; if(lrun>maxlrun) maxlrun=lrun; end
        T_STORE: begin store_loops=store_loops+1; lrun=0;frun=0;srun=srun+1; if(srun>maxsrun) maxsrun=srun; end
        default: begin idle_loops=idle_loops+1; srun=0;lrun=0;frun=0; end
    endcase
  end

  task chk; input cond; input [8*72:1] name;
    begin if (cond) $display("  G-pass  %0s", name);
          else begin $display("  G-FAIL  %0s", name); fails=fails+1; end end
  endtask

  initial begin
    for (i=0;i<256;i=i+1) hmem[i] = 8'hAA;
    hmem[64]=0; hmem[65]=0; hmem[66]=0; hmem[67]=0;
    st_addr=0; pc_prev=32'hFFFFFFFF; retire_prev=0; seen_pc=0;
    $display("=== ARM (A) FACT-FINDING (UNRATIFIED) — FULLY REGISTERED HOST, symmetric +4 ===");
    @(negedge clk); rst_n = 1;
    repeat (1200) @(posedge clk);
    $display("  loops: FETCH=%0d LOAD=%0d STORE=%0d IDLE=%0d (max runs F=%0d L=%0d S=%0d)",
             fetch_loops, load_loops, store_loops, idle_loops, maxfrun, maxlrun, maxsrun);
    $display("  retires=%0d pc advances=%0d advance-without-retire=%0d", retires, pc_adv, couple_viol);
    $display("  mem[64..67]=%h%h%h%h  x1=%h  x3=%h",
             hmem[67],hmem[66],hmem[65],hmem[64], dut.u_core.regs[1], dut.u_core.regs[3]);
    chk(load_loops>0 && store_loops>0,                   "G1 a LOAD and a STORE appear on the pins");
    chk({hmem[67],hmem[66],hmem[65],hmem[64]} == 32'd64, "G2 the SW wrote the right word to the right address");
    chk(dut.u_core.regs[3] == 32'd64,                    "G3 the LW's word REACHED A REGISTER (fully registered host)");
    chk(maxlrun == 2,                                    "G4 a LOAD owns exactly TWO consecutive loops");
    chk(couple_viol == 0,                                "G5 no PC advance without a retire");
    // ⛔ G7's FIRST FORM WAS A CRITERION THAT COULD NOT PASS, AND THE DESIGN WAS INNOCENT.
    // I wrote `maxfrun == 2` — but `maxfrun` is the longest run of consecutive FETCH
    // loops ACROSS instruction boundaries, and this program has three non-memory
    // fetches in a row (nop, addi, then sw's own fetch), so 6 is the CORRECT reading.
    // The right criterion is per-instruction: every instruction has exactly ONE fetch,
    // and under arm (A) a fetch is two loops.
    chk(fetch_loops == 2*retires,                        "G7 every instruction's fetch owns exactly TWO loops (arm A)");
    if (fails==0) $display("==> ARM (A): ALL PASS (6/6)"); else $display("==> ARM (A) RED: %0d/6 FAILED", fails);
    $finish;
  end
endmodule
