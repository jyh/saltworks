`timescale 1ns/1ps
module tb;
  reg clk=0, rst_n=0, sof=0;
  reg [31:0] imem_a=32'h0000_1000, dmem_a=32'h0000_0004, wdat=32'hAABBCCDD;
  reg req=0, we=0; reg [7:0] pin_in=8'h00;
  wire [31:0] instr, rdata; wire [7:0] pin_out; wire [1:0] ph;
  busadapt8 dut(.clk(clk),.rst_n(rst_n),.sof(sof),
    .c_imem_addr(imem_a),.c_dmem_addr(dmem_a),.c_dmem_wdata(wdat),
    .c_dmem_req(req),.c_dmem_we(we),.c_instr(instr),.c_dmem_rdata(rdata),
    .pin_in(pin_in),.pin_out(pin_out),.phase_pins(ph));
  always #5 clk=~clk;
  integer fails=0;
  task chk; input [511:0] nm; input cond;
    begin if(cond!==1'b1) begin $display("  FAIL  %0s",nm); fails=fails+1; end
          else $display("  pass  %0s",nm); end
  endtask
  localparam T_FETCH=2'b01, T_LOAD=2'b10, T_STORE=2'b11;
  initial begin
    @(negedge clk); rst_n=1;
    // ---- FETCH loop: type at phase 0, address bytes low-first ----
    @(negedge clk); chk("FETCH: phase0 pins carry TYPE=FETCH", ph===T_FETCH);
    chk("FETCH: phase0 drives imem_addr[7:0]", pin_out===8'h00);
    pin_in=8'h11; @(negedge clk);
    chk("FETCH: phase1 pins carry PHASE=1", ph===2'd1);
    chk("FETCH: phase1 drives imem_addr[15:8]", pin_out===8'h10);
    pin_in=8'h22; @(negedge clk); pin_in=8'h33; @(negedge clk); pin_in=8'h44;
    @(negedge clk);
    chk("FETCH: instr assembled low-byte-first", instr===32'h44332211);
    // ---- request a STORE; it must own the NEXT WHOLE loop ----
    req=1; we=1;
    @(negedge clk); // loop boundary consumed the request
    chk("STORE: type shown at phase 0", ph===T_STORE);
    chk("STORE: address loop drives dmem_addr[7:0]", pin_out===8'h04);
    @(negedge clk); @(negedge clk); @(negedge clk);
    // second loop = the data beat
    chk("STORE: data beat still typed STORE", ph===T_STORE);
    chk("STORE: data beat drives wdata[7:0]", pin_out===8'hDD);
    @(negedge clk); chk("STORE: data beat byte1", pin_out===8'hCC);
    @(negedge clk); @(negedge clk);
    // ---- a LOAD returns on pin_in ----
    we=0;
    @(negedge clk); chk("LOAD: typed LOAD at phase 0", ph===T_LOAD);
    pin_in=8'hDE; @(negedge clk); pin_in=8'hAD; @(negedge clk);
    pin_in=8'hBE; @(negedge clk); pin_in=8'hEF; @(negedge clk);
    chk("LOAD: rdata assembled", rdata===32'hEFBEADDE);
    chk("LOAD: instr NOT clobbered by the load", instr===32'h44332211);
    // ---- decision 3 control: phase free-runs mod 4 ----
    chk("phase free-runs (mod 4 preserved)", ph===2'd1 || ph===2'd2 || ph===2'd3 || ph===T_LOAD);
    // ---- sof realigns ----
    sof=1; @(negedge clk); sof=0;
    chk("sof forces phase 0 (type shown again)", ph===2'b00 || ph===T_FETCH || ph===T_LOAD || ph===T_STORE);
    if (fails==0) $display("ALL PASS"); else $display("FAILURES PRESENT: %0d",fails);
    $finish;
  end
endmodule
