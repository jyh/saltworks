// RV32I CONTROL PATH — decode + immediate generation + branch decision + PC
// select, with the PC adder deliberately INCLUDED so its cone is visible.
// Boundaries named so the census can ask what cutting buys. NOT a submission.
module ctrl32(instr, pc, zero, lt, ltu, imm, pc_next,
              reg_we, mem_we, mem_re, alu_src, wb_sel, alu_op, br_taken);
    input  [31:0] instr;
    input  [31:0] pc;
    input         zero, lt, ltu;
    output [31:0] imm;
    output [31:0] pc_next;
    output        reg_we, mem_we, mem_re, alu_src, br_taken;
    output [1:0]  wb_sel;
    output [3:0]  alu_op;

    wire [6:0] opcode = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire       f7     = instr[30];

    // ---- decode ----------------------------------------------------------
    wire is_lui   = (opcode == 7'b0110111);
    wire is_auipc = (opcode == 7'b0010111);
    wire is_jal   = (opcode == 7'b1101111);
    wire is_jalr  = (opcode == 7'b1100111);
    wire is_br    = (opcode == 7'b1100011);
    wire is_load  = (opcode == 7'b0000011);
    wire is_store = (opcode == 7'b0100011);
    wire is_immop = (opcode == 7'b0010011);
    wire is_regop = (opcode == 7'b0110011);

    assign reg_we  = is_lui | is_auipc | is_jal | is_jalr | is_load | is_immop | is_regop;
    assign mem_we  = is_store;
    assign mem_re  = is_load;
    assign alu_src = is_immop | is_load | is_store | is_jalr;
    assign wb_sel  = is_load ? 2'd1 : (is_jal | is_jalr) ? 2'd2 : 2'd0;
    assign alu_op  = is_regop ? {f7, funct3} : is_immop ? {1'b0, funct3} : 4'd0;

    // ---- immediate generation, all five formats --------------------------
    (* keep *) wire [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
    assign imm_i = {{20{instr[31]}}, instr[31:20]};
    assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    assign imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    assign imm_u = {instr[31:12], 12'b0};
    assign imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

    assign imm = is_store ? imm_s : is_br ? imm_b :
                 (is_lui | is_auipc) ? imm_u : is_jal ? imm_j : imm_i;

    // ---- branch decision -------------------------------------------------
    assign br_taken = is_br & ((funct3 == 3'b000) ?  zero :
                               (funct3 == 3'b001) ? ~zero :
                               (funct3 == 3'b100) ?  lt   :
                               (funct3 == 3'b101) ? ~lt   :
                               (funct3 == 3'b110) ?  ltu  :
                               (funct3 == 3'b111) ? ~ltu  : 1'b0);

    // ---- PC path: the 32-bit adder lives here ----------------------------
    (* keep *) wire [31:0] pc_plus_imm, pc_plus_4;
    assign pc_plus_imm = pc + imm;
    assign pc_plus_4   = pc + 32'd4;
    assign pc_next = (is_jal | br_taken) ? pc_plus_imm : pc_plus_4;
endmodule
