// SLICE-A CORE, 32 REGISTERS — the five landed ops, purpose-built.
//
// ISA per docs/lang-design-v1.md:6 — ADD ADDI XOR SLT BEQ. NO MEMORY; the only
// architectural state is the register file and the PC. This is NOT core32: that
// module is the full RV32I datapath and its own header says "NOT a submission
// artifact". This one exists so the layout pricing in
// docs/silicon-riscv-layout-pricing-0808.md stops being a bottom-up ESTIMATE
// summed from RV32I blocks and becomes a MEASUREMENT of the object proposed.
//
// Paired with slicea16.v, which differs ONLY in the register-file address width
// (4 vs 5 bits, 16 vs 32 entries). That pair is the whole experiment: the
// pricing found the register file, not the switch, decides the tile.
//
// Encodings (RV32I):
//   ADD  funct7=0000000 funct3=000 opcode=0110011
//   XOR  funct7=0000000 funct3=100 opcode=0110011
//   SLT  funct7=0000000 funct3=010 opcode=0110011
//   ADDI                funct3=000 opcode=0010011
//   BEQ                 funct3=000 opcode=1100011
// Anything else retires as a no-op (PC advances, no write). Trapping is Slice-B.
module slicea32(clk, rst_n, instr, imem_addr);
    input         clk, rst_n;
    input  [31:0] instr;
    output [31:0] imem_addr;

    // ---- fetch -----------------------------------------------------------
    reg  [31:0] pc_r;
    wire [31:0] pc_q = pc_r;
    assign imem_addr = {pc_q[31:2], 2'b00};

    // ---- decode ----------------------------------------------------------
    wire [6:0] opcode = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];
    wire [4:0] rs1 = instr[19:15], rs2 = instr[24:20], rd = instr[11:7];

    wire is_rtype = (opcode == 7'b0110011) & (funct7 == 7'b0000000);
    wire is_add   = is_rtype & (funct3 == 3'b000);
    wire is_xor   = is_rtype & (funct3 == 3'b100);
    wire is_slt   = is_rtype & (funct3 == 3'b010);
    wire is_addi  = (opcode == 7'b0010011) & (funct3 == 3'b000);
    wire is_beq   = (opcode == 7'b1100011) & (funct3 == 3'b000);

    // ---- immediates ------------------------------------------------------
    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
    wire [31:0] imm_b = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};

    // ---- register file (32 x 32, x0 hardwired zero) ----------------------
    reg [31:0] rf [1:31];
    wire       rf_we = (is_add | is_xor | is_slt | is_addi) & (rd != 5'd0);
    wire [31:0] rs1_v = (rs1 == 5'd0) ? 32'd0 : rf[rs1];
    wire [31:0] rs2_v = (rs2 == 5'd0) ? 32'd0 : rf[rs2];

    // ---- ALU: the three ops that write a register -------------------------
    wire [31:0] opnd_b = is_addi ? imm_i : rs2_v;
    wire [31:0] sum    = rs1_v + opnd_b;
    wire        lt     = ($signed(rs1_v) < $signed(opnd_b));
    wire [31:0] alu_y  = is_xor ? (rs1_v ^ opnd_b)
                       : is_slt ? {31'd0, lt}
                       :          sum;               // ADD / ADDI

    // ---- branch ----------------------------------------------------------
    wire        br_taken = is_beq & (rs1_v == rs2_v);
    wire [31:0] pc_next  = br_taken ? (pc_q + imm_b) : (pc_q + 32'd4);

    // ---- sequential ------------------------------------------------------
    integer i;
    always @(posedge clk) begin
        if (!rst_n) begin
            pc_r <= 32'd0;
            for (i = 1; i < 32; i = i + 1) rf[i] <= 32'd0;
        end else begin
            pc_r <= pc_next;
            if (rf_we) rf[rd] <= alu_y;
        end
    end
endmodule
