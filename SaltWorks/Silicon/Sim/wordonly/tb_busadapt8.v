`timescale 1ns/1ps
// INVARIANT bench: instead of guessing which absolute cycle carries which byte,
// assert the CONTRACT at every cycle against the adapter's own phase/kind.
module tb;
  reg clk=0, rst_n=0, sof=0;
  reg [31:0] ia=32'h11223344, da=32'h55667788, wd=32'h99AABBCC;
  reg req=0, we=0; reg [7:0] pin_in=8'h00;
  wire [31:0] instr, rdata; wire [7:0] pin_out; wire [1:0] ph;
  busadapt8 dut(.clk(clk),.rst_n(rst_n),.sof(sof),
    .c_imem_addr(ia),.c_dmem_addr(da),.c_dmem_wdata(wd),
    .c_dmem_req(req),.c_dmem_we(we),.c_instr(instr),.c_dmem_rdata(rdata),
    .pin_in(pin_in),.pin_out(pin_out),.phase_pins(ph));
  always #5 clk=~clk;
  integer fails=0, checks=0;
  localparam T_FETCH=2'b01, T_LOAD=2'b10, T_STORE=2'b11;
  // the word the adapter SHOULD be driving, derived independently of the DUT's mux
  function [31:0] expect_word; input [1:0] k; input sb;
    expect_word = (k==T_FETCH) ? ia : (k==T_STORE && sb) ? wd : da;
  endfunction
  function [7:0] expect_byte; input [31:0] w; input [1:0] p;
    expect_byte = (p==2'd0)? w[7:0] : (p==2'd1)? w[15:8] : (p==2'd2)? w[23:16] : w[31:24];
  endfunction
  // INVARIANT 1 — the pin always carries the right byte of the right word
  always @(negedge clk) if (rst_n) begin
    checks = checks + 1;
    if (pin_out !== expect_byte(expect_word(dut.kind, dut.store_beat), dut.phase)) begin
      $display("  FAIL  pin_out wrong: phase=%0d kind=%b sb=%b got=%h want=%h",
               dut.phase, dut.kind, dut.store_beat, pin_out,
               expect_byte(expect_word(dut.kind,dut.store_beat), dut.phase));
      fails = fails + 1;
    end
    // INVARIANT 2 — the phase pins show TYPE at phase 0 and PHASE elsewhere
    if (dut.phase == 2'd0) begin
      if (ph !== dut.kind) begin $display("  FAIL  phase0 must show TYPE"); fails=fails+1; end
    end else if (ph !== dut.phase) begin
      $display("  FAIL  phase%0d must show PHASE", dut.phase); fails=fails+1;
    end
  end
  initial begin
    @(negedge clk); rst_n=1;
    repeat (4) @(negedge clk);                       // a FETCH loop
    req=1; we=1; repeat (8) @(negedge clk);          // STORE: address loop + data loop
    we=0;        repeat (8) @(negedge clk);          // LOAD loops
    req=0;       repeat (4) @(negedge clk);          // back to FETCH
    sof=1; @(negedge clk); sof=0; repeat (4) @(negedge clk);
    $display("  invariant checks run: %0d", checks);
    if (fails==0) $display("ALL PASS"); else $display("FAILURES PRESENT: %0d",fails);
    $finish;
  end
endmodule
