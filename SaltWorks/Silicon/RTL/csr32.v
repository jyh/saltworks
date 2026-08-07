// RV32I Zicsr — a 16-CSR machine-mode file with CSRRW/CSRRS/CSRRC.
// The 12-bit CSR address is per spec, regardless of how few CSRs exist.
// NOT a submission artifact.
module csr32(clk, csr_addr, csr_op, csr_we, rs1_val, csr_rdata, csr_wdata_dbg);
    input         clk;
    input  [11:0] csr_addr;
    input  [1:0]  csr_op;      // 01 RW, 10 RS, 11 RC
    input         csr_we;
    input  [31:0] rs1_val;
    output [31:0] csr_rdata;
    output [31:0] csr_wdata_dbg;

    reg [31:0] csr [0:15];
    wire [3:0] idx = csr_addr[3:0];          // 16 CSRs, low bits select

    // ---- read: N-way select under a 12-bit address --------------------
    assign csr_rdata = (csr_addr[11:4] == 8'h30) ? csr[idx] : 32'b0;

    // ---- modify: per-bit, and cheap -----------------------------------
    (* keep *) wire [31:0] csr_wdata;
    assign csr_wdata = (csr_op == 2'b01) ? rs1_val :
                       (csr_op == 2'b10) ? (csr_rdata |  rs1_val) :
                       (csr_op == 2'b11) ? (csr_rdata & ~rs1_val) : csr_rdata;
    assign csr_wdata_dbg = csr_wdata;

    integer k;
    always @(posedge clk)
        if (csr_we && (csr_addr[11:4] == 8'h30))
            csr[idx] <= csr_wdata;
endmodule
