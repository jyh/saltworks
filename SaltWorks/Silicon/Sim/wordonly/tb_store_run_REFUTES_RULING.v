`timescale 1ns/1ps
// Does an UNBOUNDED STORE RUN exist at the pins? My residual-(2) ruling says no:
// every store is preceded by its own fetch, so 11,11 pairs always carry an 01
// separator. That is an ARGUMENT about the CORE, so the core must be in the loop.
module tb;
  reg clk=0, rst_n=0, sof=0;
  wire [31:0] imem_a, dmem_a, dmem_wd; wire dmem_rq, dmem_we_w;
  wire [31:0] instr, rdata; wire [7:0] pin_out; wire [1:0] ph;
  reg  [7:0]  pin_in=8'h13;
  core32 core(.clk(clk),.rst_n(rst_n),.instr(instr),.dmem_rdata(rdata),
    .dmem_addr(dmem_a),.dmem_wdata(dmem_wd),.dmem_be(),
    .dmem_req(dmem_rq),.dmem_we(dmem_we_w),.imem_addr(imem_a));
  busadapt8 ad(.clk(clk),.rst_n(rst_n),.sof(sof),
    .c_imem_addr(imem_a),.c_dmem_addr(dmem_a),.c_dmem_wdata(dmem_wd),
    .c_dmem_req(dmem_rq),.c_dmem_we(dmem_we_w),
    .c_instr(instr),.c_dmem_rdata(rdata),
    .pin_in(pin_in),.pin_out(pin_out),.phase_pins(ph));
  always #5 clk=~clk;
  // the host feeds a stream of SW x2,0(x1) — the densest possible store run
  wire [31:0] SW = {7'd0, 5'd2, 5'd1, 3'b010, 5'd0, 7'b0100011};
  always @(*) case (ad.phase)
      2'd0: pin_in = SW[7:0];   2'd1: pin_in = SW[15:8];
      2'd2: pin_in = SW[23:16]; default: pin_in = SW[31:24];
  endcase
  integer stores=0, seps=0, run=0, maxrun=0, i;
  always @(negedge clk) if (rst_n && ad.phase==2'd0) begin
    if (ad.kind==2'b11) begin stores=stores+1; run=run+1; if(run>maxrun) maxrun=run; end
    else begin if (run>0) seps=seps+1; run=0; end
  end
  initial begin
    @(negedge clk); rst_n=1;
    repeat (400) @(negedge clk);
    $display("  STORE loops seen        : %0d", stores);
    $display("  longest CONSECUTIVE run : %0d  (my ruling says 2: address + data)", maxrun);
    $display("  separator events        : %0d", seps);
    if (maxrun <= 2 && seps > 0)
      $display("ALL PASS — no unbounded store run; 11,11 always separated");
    else
      $display("FAILURES PRESENT — run of %0d contradicts the reachability ruling", maxrun);
    $finish;
  end
endmodule
