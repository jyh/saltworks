// SLICE-A, 16 REGISTERS, **TWO PINS** — the co-tenancy claim, made checkable.
//
// At 19:24 I reported that co-tenancy was "viable, one small change short of
// proven": slicea16s needs 3 signals (instr_bit, instr_shift, instr_commit) and
// the shipped switch leaves TWO free uio pins. I declined to claim the 2-pin
// variant until it existed, because claiming an unbuilt pin count is exactly the
// error I made at 19:09 — "three free pins" when there were two.
//
// ⛔⛔ RESULT: THIS FILE IS A REFUTATION, NOT A DESIGN. It synthesises to ZERO
// CELLS. Dropping `instr_commit` for an internal counter also dropped `pc_out`,
// the last output — so nothing in the core is observable at any pin, every flop
// drives nothing, and `opt_clean -purge` correctly deletes the whole design.
// A core you cannot observe is not a small core; it is not a core.
// ⇒ CO-TENANCY NEEDS AT LEAST 3 SIGNALS (2 in + >=1 out) AND TWO ARE FREE.
// Kept in the tree because the zero is the evidence: it is cheaper to read this
// file than to re-derive why 2 pins cannot work. Do not "fix" it by adding an
// output — that is slicea16s, which already exists and costs 3 pins.
//
// This is that variant. `instr_commit` is GONE: a 5-bit counter counts shifts and
// commits on the 32nd, so the host drives only DATA and CLOCK-ENABLE.
//
//   instr_bit + instr_shift  ->  TWO pins, which is what is free.
//
// ⚠️ WHAT THIS STILL IS NOT: a design. No handshake, no reset-sync on the shift
// phase, no bring-up observability (pc_out is gone with instr_commit — that pin
// was bought back and spent on nothing). A real submission wants all three. This
// file exists to make ONE claim checkable — that the core fits the free pins —
// and it should be read as a floor, exactly like its two predecessors.
module slicea16t(clk, rst_n, instr_bit, instr_shift);
    input clk, rst_n;
    input instr_bit;    // serial instruction data, LSB first
    input instr_shift;  // high: shift one bit in; the 32nd shift also EXECUTES

    // ---- serial instruction register + the counter that replaces a pin ----
    reg [31:0] ir;
    reg  [4:0] cnt;                       // 5 flops, the whole cost of the pin
    wire       commit = instr_shift & (cnt == 5'd31);

    always @(posedge clk)
        if (!rst_n) begin
            ir <= 32'd0; cnt <= 5'd0;
        end else if (instr_shift) begin
            ir  <= {instr_bit, ir[31:1]};
            cnt <= cnt + 5'd1;            // wraps at 32 by construction
        end

    wire [31:0] instr = ir;

    reg  [31:0] pc_r;
    wire [31:0] pc_q = pc_r;

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
    wire        rf_we = commit & (is_add | is_xor | is_slt | is_addi)
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
        end else if (commit) begin
            pc_r <= pc_q + pc_addend;
            if (rf_we) rf[rd[3:0]] <= alu_y;
        end
    end
endmodule
