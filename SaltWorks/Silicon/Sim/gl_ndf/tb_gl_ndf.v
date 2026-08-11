// GATE-LEVEL smoke test of the SUBMITTED NDF, on the MAPPED sky130 netlist.
// Mirrors the three checks in the submission's own test/test.py -- the arm TT's
// `gds` workflow runs as gl_test, which is BLOCKING. Run here so the answer is
// known before TT's CI is the first to ask.
`default_nettype none
`timescale 1ns/1ps
module tb_gl_ndf;
  localparam [7:0] OE_EXPECTED = 8'b1011_0011;   // the frozen D6 direction mask
  reg clk=0, rst_n=0, ena=1; reg [7:0] ui_in=0, uio_in=0;
  wire [7:0] uo_out, uio_out, uio_oe;
  integer i, oe_bad=0, phase_bad=0, prev_phase=-1, phase, rises=0, prev_valid=0, valid;
  tt_um_saltworks_ndf dut(.clk(clk), .ena(ena), .rst_n(rst_n), .ui_in(ui_in),
    .uio_in(uio_in), .uio_oe(uio_oe), .uio_out(uio_out), .uo_out(uo_out));
  // NEGATIVE CONTROL: +held_in_reset keeps rst_n LOW for the whole run. If the
  // three checks still pass with the design held in reset, they are not measuring
  // the design and a GL PASS means nothing. A harness that cannot fail is not a
  // harness -- so this arm exists to be run, and its expected verdict is FAIL.
  reg control = 0;
  always #5 clk = ~clk;
  initial begin
    if ($test$plusargs("held_in_reset")) control = 1;
    repeat (2) @(posedge clk);
    rst_n = control ? 1'b0 : 1'b1; @(posedge clk);
    uio_in = 8'h40;                 // sof rides uio[6] -- non-destructive re-align
    @(negedge clk); @(posedge clk);
    uio_in = 8'h00;

    for (i = 0; i < 56; i = i + 1) begin      // four 14-cycle frames
      @(negedge clk);
      if (uio_oe !== OE_EXPECTED) oe_bad = oe_bad + 1;
      valid = (uio_out >> 7) & 1;
      if (valid === 1 && prev_valid === 0) rises = rises + 1;
      prev_valid = valid;
      phase = uio_out & 2'b11;                // phase_o free-runs mod 4
      if (prev_phase >= 0 && phase !== (prev_phase + 1) % 4) phase_bad = phase_bad + 1;
      prev_phase = phase;
      @(posedge clk);
    end

    $display("GATE-LEVEL, mapped sky130 netlist of the SUBMITTED RTL:%s", control ? "   [NEGATIVE CONTROL: held in reset]" : "");
    $display("  uio_oe == 8'b1011_0011 every cycle : %0d deviations %s",
             oe_bad, oe_bad==0 ? "PASS" : "FAIL");
    $display("  phase_o[1:0] increments mod 4      : %0d deviations %s",
             phase_bad, phase_bad==0 ? "PASS" : "FAIL");
    $display("  valid rising edges over 4 frames   : %0d (expect 4) %s",
             rises, rises==4 ? "PASS" : "FAIL");
    if (oe_bad==0 && phase_bad==0 && rises==4) $display("  ==> GL SMOKE PASS");
    else                                       $display("  ==> GL SMOKE FAIL");
    $finish;
  end
endmodule
