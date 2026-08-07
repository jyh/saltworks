// RV32I CORE — the surveyed blocks assembled into one datapath, single-cycle,
// machine mode without CSR/trap (C3's scope). Every inter-block boundary the
// survey identified is NAMED so the whole-core census can cut where the
// block-level census cut. NOT a submission artifact.
//
// Blocks: fetch (PC + next-PC), decode/control + immgen, register file,
// ALU, memory interface, writeback select.
module core32(clk, rst_n, instr, dmem_rdata, dmem_addr, dmem_wdata, dmem_be,
              imem_addr);
    input         clk, rst_n;
    input  [31:0] instr;
    input  [31:0] dmem_rdata;
    output [31:0] dmem_addr, dmem_wdata;
    output [3:0]  dmem_be;
    output [31:0] imem_addr;

    // ---- the survey's named boundaries -----------------------------------
    (* keep *) wire [31:0] pc_q, pc_next, pc_plus_4, pc_plus_imm;
    (* keep *) wire [31:0] imm, rf1, rf2, alu_y, ld_out, wb_val;
    (* keep *) wire        br_taken, alu_zero;

    reg [31:0] pc_r;
    always @(posedge clk) if (!rst_n) pc_r <= 32'h0; else pc_r <= pc_next;
    assign pc_q = pc_r;
    assign imem_addr = {pc_q[31:2], 2'b00};

    wire [6:0] opcode = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire       f7     = instr[30];
    wire [4:0] rs1 = instr[19:15], rs2 = instr[24:20], rd = instr[11:7];

    wire is_lui=(opcode==7'b0110111), is_auipc=(opcode==7'b0010111);
    wire is_jal=(opcode==7'b1101111), is_jalr=(opcode==7'b1100111);
    wire is_br=(opcode==7'b1100011),  is_load=(opcode==7'b0000011);
    wire is_store=(opcode==7'b0100011), is_immop=(opcode==7'b0010011);
    wire is_regop=(opcode==7'b0110011);

    wire reg_we = is_lui|is_auipc|is_jal|is_jalr|is_load|is_immop|is_regop;
    wire alu_src = is_immop|is_load|is_store|is_jalr;
    wire [3:0] alu_op = is_regop ? {f7,funct3} : is_immop ? {1'b0,funct3} : 4'd0;

    // immediates
    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
    wire [31:0] imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    wire [31:0] imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    wire [31:0] imm_u = {instr[31:12], 12'b0};
    wire [31:0] imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
    assign imm = is_store ? imm_s : is_br ? imm_b :
                 (is_lui|is_auipc) ? imm_u : is_jal ? imm_j : imm_i;

    // register file (31 x 32, 2 read ports)
    reg [31:0] regs [1:31];
    always @(posedge clk) if (reg_we && rd != 5'd0) regs[rd] <= wb_val;
    assign rf1 = (rs1 == 5'd0) ? 32'b0 : regs[rs1];
    assign rf2 = (rs2 == 5'd0) ? 32'b0 : regs[rs2];

    // ALU
    wire [31:0] b_op = alu_src ? imm : rf2;
    assign alu_y = (alu_op==4'h0) ? rf1 + b_op :
                   (alu_op==4'h8) ? rf1 - b_op :
                   (alu_op==4'h1) ? rf1 << b_op[4:0] :
                   (alu_op==4'h2) ? {31'b0, $signed(rf1) < $signed(b_op)} :
                   (alu_op==4'h3) ? {31'b0, rf1 < b_op} :
                   (alu_op==4'h4) ? rf1 ^ b_op :
                   (alu_op==4'h5) ? rf1 >> b_op[4:0] :
                   (alu_op==4'hd) ? $signed(rf1) >>> b_op[4:0] :
                   (alu_op==4'h6) ? rf1 | b_op : rf1 & b_op;
    assign alu_zero = (alu_y == 32'b0);

    // branch
    assign br_taken = is_br & ((funct3==3'b000) ? (rf1==rf2) : (funct3==3'b001) ? (rf1!=rf2) :
                               (funct3==3'b100) ? ($signed(rf1)<$signed(rf2)) :
                               (funct3==3'b101) ? ~($signed(rf1)<$signed(rf2)) :
                               (funct3==3'b110) ? (rf1<rf2) : (rf1>=rf2));

    // PC path
    assign pc_plus_4   = pc_q + 32'd4;
    assign pc_plus_imm = pc_q + imm;
    assign pc_next = is_jalr ? ((rf1 + imm) & ~32'd1) :
                     (is_jal | br_taken) ? pc_plus_imm : pc_plus_4;

    // memory interface
    assign dmem_addr  = alu_y;
    assign dmem_wdata = (funct3==3'b000) ? {4{rf2[7:0]}} :
                        (funct3==3'b001) ? {2{rf2[15:0]}} : rf2;
    assign dmem_be = ~is_store ? 4'b0000 :
                     (funct3==3'b000) ? (4'b0001 << alu_y[1:0]) :
                     (funct3==3'b001) ? (alu_y[1] ? 4'b1100 : 4'b0011) : 4'b1111;
    wire [7:0]  lb = (alu_y[1:0]==2'd0) ? dmem_rdata[7:0] : (alu_y[1:0]==2'd1) ? dmem_rdata[15:8] :
                     (alu_y[1:0]==2'd2) ? dmem_rdata[23:16] : dmem_rdata[31:24];
    wire [15:0] lh = alu_y[1] ? dmem_rdata[31:16] : dmem_rdata[15:0];
    assign ld_out = (funct3==3'b000) ? {{24{lb[7]}}, lb} : (funct3==3'b100) ? {24'b0, lb} :
                    (funct3==3'b001) ? {{16{lh[15]}}, lh} : (funct3==3'b101) ? {16'b0, lh} : dmem_rdata;

    // writeback select
    assign wb_val = is_load ? ld_out : (is_jal|is_jalr) ? pc_plus_4 :
                    is_lui ? imm : is_auipc ? pc_plus_imm : alu_y;
endmodule
