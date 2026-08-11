// Reproduces test.py::test_counter_alignment's three checks against the RTL.
// cocotb will not import here, so the checks are re-run in iverilog instead of
// asserted about. Mirrors _start() and _cycle()'s falling-edge sampling exactly.
`default_nettype none
module tb_cnt;
  localparam HDR = 6, FRAME = 14;
  reg clk=0, rst_n=0, ena=1; reg [7:0] ui_in=0, uio_in=0;
  wire [7:0] uo_out, uio_out, uio_oe;
  integer f, t, first_old5 = -1, bad_new = 0, bad_old_cnt = 0, bad_new_cnt = 0, bad_valid = 0;
  integer cnt3, cnt4, vld;
  tt_um_saltworks_banyan dut(.ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in),
    .uio_out(uio_out), .uio_oe(uio_oe), .ena(ena), .clk(clk), .rst_n(rst_n));
  always #5 clk = ~clk;
  initial begin
    @(posedge clk); @(posedge clk); rst_n = 1; @(posedge clk);
    uio_in = 1; @(negedge clk); @(posedge clk); uio_in = 0;   // sof: next cycle is 0
    for (f = 0; f < 2; f = f + 1)
      for (t = 0; t < FRAME; t = t + 1) begin
        @(negedge clk);
        cnt3 = (uio_out >> 1) & 3'h7;
        cnt4 = (((uio_out >> 5) & 1) << 3) | cnt3;
        vld  = (uio_out >> 4) & 1;
        if (((uio_out >> 5) != 0) && first_old5 < 0) first_old5 = t;   // the SHIPPED assert
        if ((uio_out >> 6) != 0)          bad_new     = bad_new + 1;   // the FIX
        if (cnt3 != (t % 8))              bad_old_cnt = bad_old_cnt + 1;
        if (cnt4 != t)                    bad_new_cnt = bad_new_cnt + 1;
        if (vld  != (t >= HDR))           bad_valid   = bad_valid + 1;
        @(posedge clk);
      end
    $display("SHIPPED  assert (uio>>5)==0        : first FAILS at cycle t=%0d", first_old5);
    $display("FIXED    assert (uio>>6)==0        : violations %0d", bad_new);
    $display("SHIPPED  cnt3 == t%%8 (3-bit)       : violations %0d   <- passes BY ALIASING", bad_old_cnt);
    $display("FIXED    cnt4 == t   (4-bit)       : violations %0d", bad_new_cnt);
    $display("         valid == (t>=HDR)         : violations %0d", bad_valid);
    $finish;
  end
endmodule
