// SPDX-FileCopyrightText: 2026 Jason Hickey
// SPDX-License-Identifier: Apache-2.0
//
// Cocotb testbench harness for `tt_um_saltworks_banyan`.
//
// This is the TinyTapeout template's `test/tb.v` with the one edit the template
// REQUIRES and does not make for you: the instantiated module is our top module,
// not `tt_um_example`. Leaving that unedited is the classic first failure.
//
// `initial` is banned in `src/` (flops power up random; an explicit reset is
// mandatory) but is fine here — a testbench is never synthesized.

`default_nettype none
`timescale 1ns / 1ps

module tb ();

  // Waveforms for `make ... && gtkwave tb.vcd` (or surfer).
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  reg        clk;
  reg        rst_n;
  reg        ena;
  reg  [7:0] ui_in;
  reg  [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

`ifdef GL_TEST
  // The shuttle builds POWERED netlists (`powered_netlists: true`), so every
  // cell — and the top module with it — carries explicit supply ports.
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  tt_um_saltworks_banyan user_project (
`ifdef GL_TEST
      .VPWR   (VPWR),
      .VGND   (VGND),
`endif
      .ui_in  (ui_in),
      .uo_out (uo_out),
      .uio_in (uio_in),
      .uio_out(uio_out),
      .uio_oe (uio_oe),
      .ena    (ena),
      .clk    (clk),
      .rst_n  (rst_n)
  );

endmodule
