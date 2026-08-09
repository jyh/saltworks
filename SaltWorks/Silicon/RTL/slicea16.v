// SLICE-A CORE, 16 REGISTERS — identical to slicea32.v except the register file.
//
// The PAIR is the experiment. docs/silicon-riscv-layout-pricing-0808.md found
// that the register file, not the switch fabric, decides the tile: 45,011 µm² at
// 32 registers against 21,592 at 16, on a 2×2 whose gross area is 75,603. This
// file and its 32-entry twin turn that bottom-up estimate into a measurement of
// the actual proposed object.
//
// x0 stays hardwired to zero, so this is 15 live registers (RV32E-shaped). Any
// instruction naming x16..x31 is OUT OF THIS ISA — see the guard below, which is
// the one semantic difference from slicea32 and is deliberate rather than
// implicit: a wider register name is retired as a no-op, exactly like an
// unsupported opcode, instead of silently aliasing into the low 16.
module slicea16(clk, rst_n, instr, imem_addr);
    input         clk, rst_n;
    input  [31:0] instr;
    output [31:0] imem_addr;

    reg  [31:0] pc_r;
    wire [31:0] pc_q = pc_r;
    assign imem_addr = {pc_q[31:2], 2'b00};

    wire [6:0] opcode = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];
    wire [4:0] rs1 = instr[19:15], rs2 = instr[24:20], rd = instr[11:7];

    // ⚠️ THE 16-ENTRY GUARD, stated not implied: an instruction naming a register
    // above x15 is not in this ISA and retires as a no-op. Without this it would
    // ALIAS into the low 16 and compute a wrong answer silently.
    wire in_range = (rs1[4] == 1'b0) & (rs2[4] == 1'b0) & (rd[4] == 1'b0);

    wire is_rtype = (opcode == 7'b0110011) & (funct7 == 7'b0000000) & in_range;
    wire is_add   = is_rtype & (funct3 == 3'b000);
    wire is_xor   = is_rtype & (funct3 == 3'b100);
    wire is_slt   = is_rtype & (funct3 == 3'b010);
    wire is_addi  = (opcode == 7'b0010011) & (funct3 == 3'b000) & in_range;
    wire is_beq   = (opcode == 7'b1100011) & (funct3 == 3'b000) & in_range;

    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
    wire [31:0] imm_b = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};

    // ---- register file (16 x 32, x0 hardwired zero) ----------------------
    reg [31:0] rf [1:15];
    wire        rf_we = (is_add | is_xor | is_slt | is_addi) & (rd[3:0] != 4'd0);
    wire [31:0] rs1_v = (rs1[3:0] == 4'd0) ? 32'd0 : rf[rs1[3:0]];
    wire [31:0] rs2_v = (rs2[3:0] == 4'd0) ? 32'd0 : rf[rs2[3:0]];

    wire [31:0] opnd_b = is_addi ? imm_i : rs2_v;
    wire [31:0] sum    = rs1_v + opnd_b;
    wire        lt     = ($signed(rs1_v) < $signed(opnd_b));
    wire [31:0] alu_y  = is_xor ? (rs1_v ^ opnd_b)
                       : is_slt ? {31'd0, lt}
                       :          sum;

    wire        br_taken = is_beq & (rs1_v == rs2_v);
    // ⭐ ONE PC ADDER, NOT TWO: mux the ADDEND, not the SUM. Written as
    // `br_taken ? (pc+imm_b) : (pc+4)` this infers two 32-bit adders whose
    // results are then discarded one apiece. Measured saving below.
    wire [31:0] pc_addend = br_taken ? imm_b : 32'd4;
    wire [31:0] pc_next   = pc_q + pc_addend;

    integer i;
    always @(posedge clk) begin
        if (!rst_n) begin
            pc_r <= 32'd0;
            for (i = 1; i < 16; i = i + 1) rf[i] <= 32'd0;
        end else begin
            pc_r <= pc_next;
            if (rf_we) rf[rd[3:0]] <= alu_y;
        end
    end
endmodule
