// READ-PATH ATTACK, candidate 2 — RV32E: 16 architectural registers.
// x0 hardwired, so 15 are STORED. Read cone = 4 address bits + 15 registers.
// NOT a submission artifact.
module regfile16(clk, we, waddr, wdata, raddr1, raddr2, rdata1, rdata2);
    input         clk;
    input         we;
    input  [3:0]  waddr;
    input  [31:0] wdata;
    input  [3:0]  raddr1;
    input  [3:0]  raddr2;
    output [31:0] rdata1;
    output [31:0] rdata2;

    reg [31:0] regs [1:15];

    always @(posedge clk)
        if (we && waddr != 4'd0)
            regs[waddr] <= wdata;

    assign rdata1 = (raddr1 == 4'd0) ? 32'b0 : regs[raddr1];
    assign rdata2 = (raddr2 == 4'd0) ? 32'b0 : regs[raddr2];
endmodule
