// SPDX-FileCopyrightText: 2026 Jason Hickey
// SPDX-License-Identifier: Apache-2.0
//
// UNRUN LOCALLY — cocotb unavailable (python 3.14.4). Referee: TT CI. First CI run is this benchs first receipt.
//
// ⭐ BUT THIS FILE IS NOT UNCHECKED. It ELABORATES against the real sources — see the
// landing commit: `iverilog` builds it with `../src/*.v` and exits 0, which verifies
// the DUT MODULE NAME and EVERY PORT NAME. That is exactly the check the shipped
// project's own tb.v names as "the classic first failure" (leaving the template's
// `tt_um_example` in place). Elaboration is not execution; it is also not nothing.
//
// `initial` is banned in `src/` (flops power up random; an explicit reset is
// mandatory) but is fine here — a testbench is never synthesized.

`default_nettype none
`timescale 1ns / 1ps

module tb ();

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
  // The shuttle builds POWERED netlists, so every cell — and the top with it —
  // carries explicit supply ports.
  wire VPWR = 1'b1;
  wire VGND = 1'b0;
`endif

  tt_um_saltworks_ndf_c32 user_project (
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
