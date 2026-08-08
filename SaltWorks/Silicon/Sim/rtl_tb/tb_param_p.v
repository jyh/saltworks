// tb_param_p.v — is banyan_fabric actually parametric in PAYLOAD?
//
// The module declares `parameter PAYLOAD = 8` and computes FRAME = 2k+PAYLOAD,
// but the frame counter is a hard-coded `reg [3:0] cnt`. A 4-bit register holds
// 0..15, so the explicit wrap test `cnt == FRAME-1` can only ever match while
// FRAME-1 <= 15, i.e. PAYLOAD <= 10. Beyond that the counter rolls over at 16
// instead of at FRAME and the frame period silently stops tracking the header.
//
// Measures the ACTUAL counter period (cycles between successive cnt==0) at
// several PAYLOAD values and compares it with FRAME. No opinion, one number.

`timescale 1ns/1ps

module period_probe #(parameter PAYLOAD = 8);
  reg clk = 1'b0, rst_n = 1'b1, sof = 1'b0;
  reg [7:0] din = 8'd0;
  wire [7:0] dout; wire [3:0] cnt_o; wire valid;
  integer c;
  integer period;

  banyan_fabric #(.PAYLOAD(PAYLOAD)) dut (
      .clk(clk), .rst_n(rst_n), .sof(sof), .din(din),
      .dout(dout), .cnt_o(cnt_o), .valid(valid));

  always #5 clk = ~clk;

  initial begin
    period = -1;
    @(negedge clk); sof = 1'b1;
    @(posedge clk);
    @(negedge clk); sof = 1'b0;          // cnt == 0 during this cycle
    c = 0;
    while (period < 0 && c <= 40) begin
      @(negedge clk);
      c = c + 1;
      if (dut.cnt === 4'd0) period = c;
    end
  end
endmodule

module tb_param_p;
  period_probe #(.PAYLOAD(8))  P8  ();
  period_probe #(.PAYLOAD(9))  P9  ();
  period_probe #(.PAYLOAD(10)) P10 ();
  period_probe #(.PAYLOAD(11)) P11 ();
  period_probe #(.PAYLOAD(12)) P12 ();
  period_probe #(.PAYLOAD(16)) P16 ();

  task row;
    input integer pl; input integer meas;
    begin
      $display("   %0d\t\t%0d\t\t%0d\t\t%s", pl, 6+pl, meas,
               (meas == 6+pl) ? "ok" : "*** MISMATCH ***");
    end
  endtask

  initial begin
    #6000;
    $display("");
    $display("PAYLOAD\tFRAME(6+P)\tmeasured period\tverdict");
    row(8,  P8.period);
    row(9,  P9.period);
    row(10, P10.period);
    row(11, P11.period);
    row(12, P12.period);
    row(16, P16.period);
    $finish;
  end
endmodule
