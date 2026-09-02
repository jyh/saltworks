// tb_lwtrap.v — does the core write rd on a TRAPPING word load? Compile with -DDUT=<module> and the three
// -DEXP_* macros naming what rd must hold after each trapping load. Expected: core32 WRITES (the die's behaviour, the row-5 measurement);
// core32_gated HOLDS. Controls in BOTH arms: an aligned in-range LW writes (positive control —
// the gate must not silence loads), an SW never writes (negative control), and dmem_req is 1
// on the trapping loads in BOTH arms (the one-wire property: only the register write differs).
`timescale 1ns/1ps
module tb;
    reg clk=0, rst_n=0, en=1; reg [31:0] instr=0, dmem_rdata=0;
    wire [31:0] dmem_addr, dmem_wdata, imem_addr; wire [3:0] dmem_be; wire dmem_req, dmem_we;
    `DUT dut(.clk(clk),.rst_n(rst_n),.en(en),.instr(instr),.dmem_rdata(dmem_rdata),.dmem_addr(dmem_addr),
             .dmem_wdata(dmem_wdata),.dmem_be(dmem_be),.dmem_req(dmem_req),.dmem_we(dmem_we),.imem_addr(imem_addr));
    always #5 clk=~clk;
    integer fails=0;
    // LW rd, imm(x0): imm[11:0] rs1=0 funct3=010 rd opcode=0000011
    function [31:0] LW; input [4:0] rd; input [11:0] imm; LW = {imm, 5'd0, 3'b010, rd, 7'b0000011}; endfunction
    // SW x0, imm(x0): imm[11:5] rs2=0 rs1=0 funct3=010 imm[4:0] opcode=0100011
    function [31:0] SW; input [11:0] imm; SW = {imm[11:5], 5'd0, 5'd0, 3'b010, imm[4:0], 7'b0100011}; endfunction
    task step; input [31:0] i; input [31:0] d; begin instr=i; dmem_rdata=d; @(negedge clk); #1; end endtask
    // reseed x1 with a NOP (ADDI x0,x0,0) on the bus, so the previous instruction cannot rewrite it
    task seed; input [31:0] v; begin instr=32'h00000013; @(negedge clk); #1; dut.regs[1]=v; @(negedge clk); #1; end endtask
    task check; input [8*40:1] name; input [31:0] got; input [31:0] exp; begin
        if (got!==exp) begin fails=fails+1; $display("FAIL %0s: got %h expected %h", name, got, exp); end
        else $display("ok   %0s: %h", name, got); end endtask
    initial begin
        @(negedge clk); rst_n=1; seed(32'h11111111);
        // trap 1: misaligned, in range (addr 1)
        step(LW(1,12'd1), 32'hdeadbeef); check("req on misaligned LW", {31'b0,dmem_req}, 32'd1);
        check("rd after misaligned LW x1,1(x0)", dut.regs[1], `EXP_MISALIGNED);
        seed(32'h22222222);
        // trap 2: out of range at the kernel boundary (addr 32, aligned)
        step(LW(1,12'd32), 32'hcafef00d); check("req on out-of-range LW", {31'b0,dmem_req}, 32'd1);
        check("rd after LW x1,32(x0)", dut.regs[1], `EXP_OOR32);
        seed(32'h33333333);
        // trap 3: out of range, far (addr 64) — the 08/31 case
        step(LW(1,12'd64), 32'hcafef00d); check("rd after LW x1,64(x0)", dut.regs[1], `EXP_OOR64);
        seed(32'h44444444);
        // POSITIVE CONTROL: aligned, in range (addr 28) must WRITE in both arms
        step(LW(1,12'd28), 32'h0badf00d); check("rd after aligned in-range LW x1,28(x0)", dut.regs[1], 32'h0badf00d);
        seed(32'h55555555);
        // NEGATIVE CONTROL: a store never writes rd in either arm (and we=1)
        step(SW(12'd1), 32'hffffffff); check("we on SW", {31'b0,dmem_we}, 32'd1);
        check("rd after SW", dut.regs[1], 32'h55555555);
        if (fails==0) $display("PASS `DUT: all checks hold"); else $display("FAIL `DUT: %0d check(s)", fails);
        $finish;
    end
endmodule
