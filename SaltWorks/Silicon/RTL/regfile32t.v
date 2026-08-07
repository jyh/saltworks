// READ-PATH ATTACK, candidate 1 — RV32I with an explicit TWO-LEVEL read tree.
// 4 groups of 8, boundaries named and (* keep *)-marked. The question is whether
// restructuring the SOURCE buys anything when the flow re-derives.
// NOT a submission artifact.
module regfile32t(clk, we, waddr, wdata, raddr1, raddr2, rdata1, rdata2);
    input         clk;
    input         we;
    input  [4:0]  waddr;
    input  [31:0] wdata;
    input  [4:0]  raddr1;
    input  [4:0]  raddr2;
    output [31:0] rdata1;
    output [31:0] rdata2;

    reg  [31:0] regs [1:31];
    wire [31:0] r [0:31];

    always @(posedge clk)
        if (we && waddr != 5'd0)
            regs[waddr] <= wdata;

    assign r[0] = 32'b0;
    genvar k;
    generate for (k = 1; k < 32; k = k + 1) begin : rmap
        assign r[k] = regs[k];
    end endgenerate

    (* keep *) wire [31:0] g1_0, g1_1, g1_2, g1_3;
    (* keep *) wire [31:0] g2_0, g2_1, g2_2, g2_3;

    assign g1_0 = r[{2'b00, raddr1[2:0]}];
    assign g1_1 = r[{2'b01, raddr1[2:0]}];
    assign g1_2 = r[{2'b10, raddr1[2:0]}];
    assign g1_3 = r[{2'b11, raddr1[2:0]}];
    assign g2_0 = r[{2'b00, raddr2[2:0]}];
    assign g2_1 = r[{2'b01, raddr2[2:0]}];
    assign g2_2 = r[{2'b10, raddr2[2:0]}];
    assign g2_3 = r[{2'b11, raddr2[2:0]}];

    assign rdata1 = (raddr1[4:3] == 2'b00) ? g1_0 :
                    (raddr1[4:3] == 2'b01) ? g1_1 :
                    (raddr1[4:3] == 2'b10) ? g1_2 : g1_3;
    assign rdata2 = (raddr2[4:3] == 2'b00) ? g2_0 :
                    (raddr2[4:3] == 2'b01) ? g2_1 :
                    (raddr2[4:3] == 2'b10) ? g2_2 : g2_3;
endmodule
