// RV32I BRANCH PATH — dedicated comparator (eq/lt/ltu), funct3 decision, target
// adder. The comparator is the part ctrl32 took as given. NOT a submission.
module branch32(rs1, rs2, funct3, is_br, pc, imm, taken, target);
    input  [31:0] rs1, rs2;
    input  [2:0]  funct3;
    input         is_br;
    input  [31:0] pc, imm;
    output        taken;
    output [31:0] target;

    (* keep *) wire eq, lt, ltu;
    assign eq  = (rs1 == rs2);
    assign lt  = ($signed(rs1) < $signed(rs2));
    assign ltu = (rs1 < rs2);

    assign taken = is_br & ((funct3 == 3'b000) ?  eq  :
                            (funct3 == 3'b001) ? ~eq  :
                            (funct3 == 3'b100) ?  lt  :
                            (funct3 == 3'b101) ? ~lt  :
                            (funct3 == 3'b110) ?  ltu :
                            (funct3 == 3'b111) ? ~ltu : 1'b0);

    (* keep *) wire [31:0] tgt;
    assign tgt    = pc + imm;
    assign target = tgt;
endmodule
