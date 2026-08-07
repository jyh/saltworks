// RV32I machine-mode TRAP PATH — exception detect, interrupt priority, cause
// encode, trap PC select. NOT a submission artifact.
module trap32(instr, pc, ls_addr, mip, mie, mstatus_mie, mtvec, mepc,
              trap, cause, trap_pc);
    input  [31:0] instr;
    input  [31:0] pc;
    input  [31:0] ls_addr;
    input  [15:0] mip, mie;
    input         mstatus_mie;
    input  [31:0] mtvec, mepc;
    output        trap;
    output [4:0]  cause;
    output [31:0] trap_pc;

    wire [6:0] opcode = instr[6:0];
    wire [2:0] funct3 = instr[14:12];

    // ---- exception detection: decode-shaped ------------------------------
    wire is_load  = (opcode == 7'b0000011);
    wire is_store = (opcode == 7'b0100011);
    wire is_sys   = (opcode == 7'b1110011);
    wire legal    = (opcode == 7'b0110111) | (opcode == 7'b0010111) |
                    (opcode == 7'b1101111) | (opcode == 7'b1100111) |
                    (opcode == 7'b1100011) | is_load | is_store |
                    (opcode == 7'b0010011) | (opcode == 7'b0110011) | is_sys;

    (* keep *) wire e_illegal, e_ecall, e_ebreak, e_mis_f, e_mis_l, e_mis_s;
    assign e_illegal = ~legal;
    assign e_ecall   = is_sys & (instr[31:20] == 12'h000);
    assign e_ebreak  = is_sys & (instr[31:20] == 12'h001);
    assign e_mis_f   = |pc[1:0];
    assign e_mis_l   = is_load  & ((funct3[1] & |ls_addr[1:0]) | (funct3[0] & ls_addr[0]));
    assign e_mis_s   = is_store & ((funct3[1] & |ls_addr[1:0]) | (funct3[0] & ls_addr[0]));

    // ---- interrupt priority encode over 16 sources ----------------------
    wire [15:0] pending = mip & mie;
    (* keep *) wire       irq;
    (* keep *) wire [3:0] irq_id;
    assign irq = mstatus_mie & |pending;
    assign irq_id = pending[15] ? 4'd15 : pending[14] ? 4'd14 : pending[13] ? 4'd13 :
                    pending[12] ? 4'd12 : pending[11] ? 4'd11 : pending[10] ? 4'd10 :
                    pending[9]  ? 4'd9  : pending[8]  ? 4'd8  : pending[7]  ? 4'd7  :
                    pending[6]  ? 4'd6  : pending[5]  ? 4'd5  : pending[4]  ? 4'd4  :
                    pending[3]  ? 4'd3  : pending[2]  ? 4'd2  : pending[1]  ? 4'd1  : 4'd0;

    // ---- cause + trap PC -------------------------------------------------
    assign trap  = e_illegal | e_ecall | e_ebreak | e_mis_f | e_mis_l | e_mis_s | irq;
    assign cause = irq        ? {1'b1, irq_id} :
                   e_mis_f    ? 5'd0  : e_illegal ? 5'd2  : e_ebreak ? 5'd3 :
                   e_mis_l    ? 5'd4  : e_mis_s   ? 5'd6  : 5'd11;
    assign trap_pc = mtvec;
endmodule
