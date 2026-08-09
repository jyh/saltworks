// SLICE-A, 16 REGISTERS, BYTE-WIDE INSTRUCTION FEED — THE CAPTAIN'S THIRD SHAPE.
//
// His words (8/8 21:09): "what about an 8-bit pinout architecture? (so a 32 bit
// load takes 4 cycles)". This is that shape, built so it can be PRICED rather
// than estimated — the 19:37 zero-cell lesson stands: build before claiming.
//
// ⭐ METHOD, and it is why the area delta is attributable: this file was
// TRANSFORMED from `slicea16s.v`, not retyped. The diff is THREE CODE LINES —
// the module name, the port width, and the shift expression. Everything else is
// byte-identical, so any area difference is the FEED WIDTH and nothing else.
//
//   slicea16s   ir <= {instr_bit,  ir[31:1]}    1 bit/cycle   32 cycles/word
//   slicea16b   ir <= {instr_byte, ir[31:8]}    8 bits/cycle   4 cycles/word
//
//   instr_byte[7:0] + instr_shift + instr_commit  ->  10 signals
//   imem_addr is NOT brought out at all: the host drives the instruction stream,
//   so the core needs no address pins. pc is still architectural state and is
//   still correct; it is simply not observable, which is what makes this fit.
//
// ⚠️ THE POINT OF THIS FILE IS ITS AREA, NOT ITS MICROARCHITECTURE. It answers
// one question — what does escaping the pin wall COST — and it is a floor, not a
// design: a real serial feed wants handshake, reset-sync and a bring-up path
// this does not have.
module slicea16b(clk, rst_n, instr_byte, instr_shift, instr_commit, pc_out);
    input         clk, rst_n;
    input  [7:0]  instr_byte;   // byte-wide instruction data, LOW BYTE FIRST
    input         instr_shift;   // high: shift instr_byte in
    input         instr_commit;  // high for one cycle: execute the shifted word
    output [7:0]  pc_out;        // low 8 bits of PC, for bring-up only

    // ---- the serial instruction register — THE COST THIS FILE MEASURES ----
    reg [31:0] ir;
    always @(posedge clk)
        if (!rst_n)          ir <= 32'd0;
        else if (instr_shift) ir <= {instr_byte, ir[31:8]};  // low byte first

    wire [31:0] instr = ir;

    reg  [31:0] pc_r;
    wire [31:0] pc_q = pc_r;
    assign pc_out = pc_q[7:0];

    wire [6:0] opcode = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];
    wire [4:0] rs1 = instr[19:15], rs2 = instr[24:20], rd = instr[11:7];

    wire in_range = (rs1[4] == 1'b0) & (rs2[4] == 1'b0) & (rd[4] == 1'b0);
    wire is_rtype = (opcode == 7'b0110011) & (funct7 == 7'b0000000) & in_range;
    wire is_add   = is_rtype & (funct3 == 3'b000);
    wire is_xor   = is_rtype & (funct3 == 3'b100);
    wire is_slt   = is_rtype & (funct3 == 3'b010);
    wire is_addi  = (opcode == 7'b0010011) & (funct3 == 3'b000) & in_range;
    wire is_beq   = (opcode == 7'b1100011) & (funct3 == 3'b000) & in_range;

    wire [31:0] imm_i = {{20{instr[31]}}, instr[31:20]};
    wire [31:0] imm_b = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};

    reg [31:0] rf [1:15];
    wire        rf_we = instr_commit & (is_add | is_xor | is_slt | is_addi)
                        & (rd[3:0] != 4'd0);
    wire [31:0] rs1_v = (rs1[3:0] == 4'd0) ? 32'd0 : rf[rs1[3:0]];
    wire [31:0] rs2_v = (rs2[3:0] == 4'd0) ? 32'd0 : rf[rs2[3:0]];

    wire [31:0] opnd_b = is_addi ? imm_i : rs2_v;
    wire [31:0] sum    = rs1_v + opnd_b;
    wire        lt     = ($signed(rs1_v) < $signed(opnd_b));
    wire [31:0] alu_y  = is_xor ? (rs1_v ^ opnd_b)
                       : is_slt ? {31'd0, lt}
                       :          sum;

    wire        br_taken  = is_beq & (rs1_v == rs2_v);
    wire [31:0] pc_addend = br_taken ? imm_b : 32'd4;

    integer i;
    always @(posedge clk) begin
        if (!rst_n) begin
            pc_r <= 32'd0;
            for (i = 1; i < 16; i = i + 1) rf[i] <= 32'd0;
        end else if (instr_commit) begin
            pc_r <= pc_q + pc_addend;
            if (rf_we) rf[rd[3:0]] <= alu_y;
        end
    end
endmodule
