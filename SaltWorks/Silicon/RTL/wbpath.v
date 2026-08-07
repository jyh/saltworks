// WRITEBACK PATH — RV32I: 4:1 result select + write-port decode + 31x32 flops.
// All registers are exposed so none is pruned; the READ path is deliberately
// absent (measured separately). NOT a submission artifact.
module wbpath(clk, we, rd, sel, alu, mem, pc4, csr, regs_flat);
    input         clk;
    input         we;
    input  [4:0]  rd;
    input  [1:0]  sel;
    input  [31:0] alu, mem, pc4, csr;
    output [991:0] regs_flat;

    reg [31:0] regs [1:31];
    wire [31:0] wb;

    assign wb = (sel == 2'd0) ? alu :
                (sel == 2'd1) ? mem :
                (sel == 2'd2) ? pc4 : csr;

    always @(posedge clk)
        if (we && rd != 5'd0)
            regs[rd] <= wb;

    genvar k;
    generate for (k = 1; k < 32; k = k + 1) begin : expose
        assign regs_flat[(k-1)*32 +: 32] = regs[k];
    end endgenerate
endmodule
