`timescale 1ns/1ps
// tb_memory_inert.v — THE ③ SEAM RULING'S CLAIM, AS A TEST.
//
//     iverilog -g2005 -o /tmp/tb tb_memory_inert.v ../../RTL/core32.v && /tmp/tb
//
// The Captain ruled (08/17, "yes take recommendation a+b") that the six encodings
// the kernel's WORD-ONLY ISA excludes — LB/LH/LBU/LHU/SB/SH — are MEMORY-INERT.
// The claim language is BINDING: memory-inert, never "refused". Nothing traps and
// nothing signals; the excluded encodings simply cannot reach memory or the regfile.
//
// ⚠️ THE HALF THAT IS EASY TO FORGET, AND THE HELM PUT IT INSIDE THE WAVE: gating
// only the MEMORY strobes leaves an excluded LOAD still writing the regfile from
// ld_out. Inert-at-the-memory-port is not inert. Hence the reg_we arms below.
//
// ⭐ EVERY NEGATIVE ARM IS PAIRED WITH A POSITIVE ONE. A test that only ever shows
// signals going LOW cannot distinguish a correct gate from a dead core: SW must
// still raise all four byte enables, LW must still write back, ADD must still
// write back. This file exists to fail if the gate is too wide OR too narrow.
//
// ⛔ AND IT HAS BEEN SHOWN TO FAIL, which is the only thing that makes the greens
// above worth reading. Running the PORTABLE arms — the ones touching signals that
// exist in BOTH revisions (`dmem_be`, `reg_we`) — against the PRE-RULING core32:
//
//     new RTL   SB dmem_be==0 pass · LB reg_we==0 pass · SW pass · LW pass
//     OLD RTL   SB dmem_be==0 FAIL · LB reg_we==0 FAIL · SW pass · LW pass
//
// The two inert arms fail on the old RTL and the two positive controls pass on
// both — so the harness discriminates on exactly the property that changed, and
// is not merely broken in a direction that flatters the change.
//
// ⚠️ NOTE the arms referencing `dut.is_load_w`/`dut.is_store_w` CANNOT be part of
// that control: those wires do not exist in the old revision, so it fails to
// COMPILE rather than to PASS. A compile error is not a test failure, and citing
// one as a negative control would be the same mistake as citing a swallowed error
// as a measured zero.
module tb;
  reg clk = 0, rst_n = 1;
  reg [31:0] instr = 0, dmem_rdata = 32'hDEADBEEF;
  wire [31:0] dmem_addr, dmem_wdata, imem_addr;
  wire [3:0]  dmem_be;

  core32 dut(.clk(clk), .rst_n(rst_n), .en(1'b1), .instr(instr), .dmem_rdata(dmem_rdata),
             .dmem_addr(dmem_addr), .dmem_wdata(dmem_wdata), .dmem_be(dmem_be),
             .imem_addr(imem_addr));

  integer fails = 0;
  task chk;
    input [511:0] nm;
    input cond;
    begin
      if (cond !== 1'b1) begin $display("  FAIL  %0s", nm); fails = fails + 1; end
      else                    $display("  pass  %0s", nm);
    end
  endtask

  // rs1=x1, rs2=x2, rd=x1; funct3 at 14:12, opcode at 6:0
  function [31:0] mk;
    input [6:0] op;
    input [2:0] f3;
    mk = {7'd0, 5'd2, 5'd1, f3, 5'd1, op};
  endfunction

  initial begin
    // ---- EXCLUDED STORES: no byte enables, ever ----------------------------
    instr = mk(7'b0100011, 3'b000); #1;
    chk("SB   dmem_be == 0000", dmem_be === 4'b0000);
    chk("SB   is_store_w == 0", dut.is_store_w === 1'b0);
    instr = mk(7'b0100011, 3'b001); #1;
    chk("SH   dmem_be == 0000", dmem_be === 4'b0000);

    // ---- POSITIVE CONTROL: the word store must still fire -------------------
    instr = mk(7'b0100011, 3'b010); #1;
    chk("SW   dmem_be == 1111", dmem_be === 4'b1111);
    chk("SW   is_store_w == 1", dut.is_store_w === 1'b1);
    chk("SW   wdata is rs2 unreplicated", dmem_wdata === dut.rf2);

    // ---- EXCLUDED LOADS: no regfile write (the in-wave check) ---------------
    instr = mk(7'b0000011, 3'b000); #1;
    chk("LB   reg_we == 0", dut.reg_we === 1'b0);
    chk("LB   is_load_w == 0", dut.is_load_w === 1'b0);
    instr = mk(7'b0000011, 3'b001); #1;
    chk("LH   reg_we == 0", dut.reg_we === 1'b0);
    instr = mk(7'b0000011, 3'b100); #1;
    chk("LBU  reg_we == 0", dut.reg_we === 1'b0);
    instr = mk(7'b0000011, 3'b101); #1;
    chk("LHU  reg_we == 0", dut.reg_we === 1'b0);

    // ---- POSITIVE CONTROLS: the gate must also say YES ----------------------
    instr = mk(7'b0000011, 3'b010); #1;
    chk("LW   reg_we == 1", dut.reg_we === 1'b1);
    chk("LW   ld_out is rdata verbatim", dut.ld_out === 32'hDEADBEEF);
    instr = mk(7'b0110011, 3'b000); #1;
    chk("ADD  reg_we == 1 (gate not too wide)", dut.reg_we === 1'b1);

    if (fails == 0) $display("ALL PASS");
    else            $display("FAILURES PRESENT: %0d", fails);
    $finish;
  end
endmodule
