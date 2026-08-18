`timescale 1ns/1ps
// DESIGN VALIDATION, NOT A LANDING. The RTL is untouched. `retire` is computed HERE
// from signals busadapt8 already carries, to test §2's claim that it needs NO NEW
// STATE. If the derivation is right, retire fires exactly once per instruction —
// even though nothing consumes it yet, which is precisely why the machine hangs.
module tb;
  reg clk=0, rst_n=0, sof=0;
  wire [31:0] imem_a, dmem_a, dmem_wd; wire dmem_rq, dmem_we_w;
  wire [31:0] instr, rdata; wire [7:0] pin_out; wire [1:0] ph;
  reg  [7:0]  pin_in;
  core32 core(.clk(clk),.rst_n(rst_n),.instr(instr),.dmem_rdata(rdata),
    .dmem_addr(dmem_a),.dmem_wdata(dmem_wd),.dmem_be(),
    .dmem_req(dmem_rq),.dmem_we(dmem_we_w),.imem_addr(imem_a));
  busadapt8 ad(.clk(clk),.rst_n(rst_n),.sof(sof),
    .c_imem_addr(imem_a),.c_dmem_addr(dmem_a),.c_dmem_wdata(dmem_wd),
    .c_dmem_req(dmem_rq),.c_dmem_we(dmem_we_w),
    .c_instr(instr),.c_dmem_rdata(rdata),
    .pin_in(pin_in),.pin_out(pin_out),.phase_pins(ph));
  always #5 clk=~clk;
  wire [31:0] SW = {7'd0, 5'd2, 5'd1, 3'b010, 5'd0, 7'b0100011};
  always @(*) case (ad.phase)
      2'd0: pin_in = SW[7:0];   2'd1: pin_in = SW[15:8];
      2'd2: pin_in = SW[23:16]; default: pin_in = SW[31:24];
  endcase
  // ── §2's DERIVATION, verbatim, from EXISTING signals only ──
  wire retire = ad.loop_end && ( (ad.kind==2'b01) ? ~dmem_rq
                               : (ad.kind==2'b10) ? 1'b1
                               : (ad.kind==2'b11) ? ad.store_beat : 1'b1 );
  integer fires=0, loops=0, gap=0, minGap=999, maxGap=0;
  always @(negedge clk) if (rst_n) begin
    if (ad.loop_end) begin loops=loops+1; gap=gap+1; end
    if (retire) begin
      fires=fires+1;
      if (gap<minGap) minGap=gap; if (gap>maxGap) maxGap=gap;
      gap=0;
    end
  end
  initial begin
    @(negedge clk); rst_n=1; repeat (400) @(negedge clk);
    $display("  loops completed      : %0d", loops);
    $display("  retire fired         : %0d", fires);
    $display("  loops between fires  : min %0d  max %0d   (a SW needs 3: fetch+addr+data)", minGap, maxGap);
    if (fires>0 && minGap==maxGap)
      $display("ALL PASS — derivation fires at a FIXED cadence from existing state only");
    else
      $display("FAILURES PRESENT — derivation is not periodic");
    $finish;
  end
endmodule
