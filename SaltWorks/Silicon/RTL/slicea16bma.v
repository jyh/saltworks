// SLICE-A, 16 REGISTERS, BYTE-WIDE DATA *AND* BYTE-MULTIPLEXED 32-BIT ADDRESS.
//
// THE CAPTAIN'S CONDITIONAL WORD, 8/8 21:2x, verbatim: "note we want 32 bit
// addresses, but we have to multiplex them into 8 pins like the data. will that
// work? if so, we should choose it, on its own tile."
//
// This is that machine, built so the answer is MEASURED. The 19:37 zero-cell
// lesson stands: no pin count and no area claim before a synthesis run.
//
// THE SHAPE — one 4-phase loop does fetch and execute together:
//   phase 0..3   addr_byte drives PC[7:0], [15:8], [23:16], [31:24]  -> uo_out
//   phase 0..3   instr_byte assembles the returned word, low byte first <- ui_in
//   phase 3      commit: execute the assembled instruction, advance the PC
//
//   instr_byte[7:0]  8   <- ui_in     the returned instruction, byte per phase
//   addr_byte[7:0]   8   -> uo_out    the PC, byte per phase
//   phase_o[1:0]     2   -> uio       the phase strobe, so the host can align
//                   ──
//                   18   signals, against TinyTapeout's 24
//
// ⭐ AND THE BRING-UP PORT DISAPPEARS, which is why this is cheaper than it
// looks: `slicea16s`/`slicea16b` carry `pc_out[7:0]` purely so the PC is
// observable. Here the address bus IS the PC, continuously, in four phases —
// so the 8 bring-up pins are not spent and the debug view is BETTER, not worse.
//
// ⚠️ WHAT THIS FILE MEASURES IS AREA, NOT A PROTOCOL. The fetch handshake —
// memory latency, wait states, whether the instruction for phase 0 arrives at
// phase 3 or a loop later — is a DESIGN question this artifact does not settle.
// It is a floor: the address machinery cannot cost less than what is here.
// Everything below the sequencer is byte-identical to `slicea16b.v`, so the
// area delta against that file is the ADDRESS PATH and nothing else.
`default_nettype none

module slicea16bma(clk, rst_n, instr_byte, addr_byte, phase_o);
    input  wire       clk, rst_n;
    input  wire [7:0] instr_byte;   // instruction byte in, LOW BYTE FIRST
    output wire [7:0] addr_byte;    // PC byte out, low byte on phase 0
    output wire [1:0] phase_o;      // phase strobe for host alignment

    // ---- THE SEQUENCER — the whole cost this file adds over slicea16b ----
    reg [1:0] phase;
    always @(posedge clk)
        if (!rst_n) phase <= 2'd0;
        else        phase <= phase + 2'd1;
    assign phase_o = phase;

    reg  [31:0] pc_r;
    wire [31:0] pc_q = pc_r;

    // the 32-bit address, multiplexed onto 8 pins — the Captain's question
    assign addr_byte = (phase == 2'd0) ? pc_q[7:0]
                     : (phase == 2'd1) ? pc_q[15:8]
                     : (phase == 2'd2) ? pc_q[23:16]
                     :                   pc_q[31:24];

    // the returned instruction, assembled over the same four phases
    reg [31:0] ir;
    always @(posedge clk)
        if (!rst_n) ir <= 32'd0;
        else        ir <= {instr_byte, ir[31:8]};

    wire [31:0] instr = ir;
    wire instr_commit = (phase == 2'd3);

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

`default_nettype wire
