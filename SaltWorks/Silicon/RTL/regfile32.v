// R3 TEST ARTICLE — an RV32I register file, for the campaign freeze's kill-check
// R3 ("THE REGFILE: 1024 state bits. Show the flop-treatment census keeps every
// cone inside the law").
//
// ⚠️ THIS IS NOT PART OF ANY SUBMISSION. `TT/assemble.sh` copies two NAMED files
// (banyan_fabric.v, bitserial_switch.v), never `RTL/*.v`, so this file cannot
// reach the tape-out. It exists to be synthesized and censused, because R3
// cannot be measured on a real artifact: no CPU netlist exists yet.
//
// ⚠️ AND THE STATE COUNT IN R3 IS NOT WHAT A REAL REGFILE HAS. RV32I's `x0` is
// hardwired zero, so a correct register file STORES 31 REGISTERS, not 32:
// 31 x 32 = 992 flops, not 1024. Storing x0 would be 32 flops that can only ever
// hold zero. The kill-check's own figure is the arithmetic of the ISA's register
// count, not of the hardware's state.
//
// Two read ports and one write port, which is what a single-cycle RV32I
// datapath needs (rs1, rs2, rd).
module regfile32(clk, we, waddr, wdata, raddr1, raddr2, rdata1, rdata2);
    input         clk;
    input         we;
    input  [4:0]  waddr;
    input  [31:0] wdata;
    input  [4:0]  raddr1;
    input  [4:0]  raddr2;
    output [31:0] rdata1;
    output [31:0] rdata2;

    reg [31:0] regs [1:31];

    always @(posedge clk)
        if (we && waddr != 5'd0)
            regs[waddr] <= wdata;

    // x0 reads as zero and is not stored.
    assign rdata1 = (raddr1 == 5'd0) ? 32'b0 : regs[raddr1];
    assign rdata2 = (raddr2 == 5'd0) ? 32'b0 : regs[raddr2];
endmodule
