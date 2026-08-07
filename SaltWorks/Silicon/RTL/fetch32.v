// RV32I FETCH PATH — PC register, next-PC select, PC+4, JALR target, alignment.
// The adders are deliberately INCLUDED and NAMED so the census can separate
// them from the rest of fetch. NOT a submission artifact.
module fetch32(clk, rst_n, br_taken, is_jal, is_jalr, imm, rs1,
               pc, imem_addr, misaligned);
    input         clk, rst_n;
    input         br_taken, is_jal, is_jalr;
    input  [31:0] imm;
    input  [31:0] rs1;
    output [31:0] pc;
    output [31:0] imem_addr;
    output        misaligned;

    reg  [31:0] pc_q;
    (* keep *) wire [31:0] pc_plus_4, pc_plus_imm, jalr_target;
    (* keep *) wire [31:0] pc_next;

    assign pc_plus_4   = pc_q + 32'd4;
    assign pc_plus_imm = pc_q + imm;
    assign jalr_target = (rs1 + imm) & ~32'd1;      // RV32I: clear bit 0

    assign pc_next = is_jalr            ? jalr_target :
                     (is_jal | br_taken) ? pc_plus_imm : pc_plus_4;

    always @(posedge clk)
        if (!rst_n) pc_q <= 32'h0000_0000;
        else        pc_q <= pc_next;

    assign pc         = pc_q;
    assign imem_addr  = {pc_q[31:2], 2'b00};
    assign misaligned = |pc_q[1:0];
endmodule
