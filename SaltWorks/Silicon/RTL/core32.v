// RV32I CORE — the surveyed blocks assembled into one datapath, single-cycle,
// machine mode without CSR/trap (C3's scope). Every inter-block boundary the
// survey identified is NAMED so the whole-core census can cut where the
// block-level census cut. NOT a submission artifact.
//
// Blocks: fetch (PC + next-PC), decode/control + immgen, register file,
// ALU, memory interface, writeback select.
module core32(clk, rst_n, en, instr, dmem_rdata, dmem_addr, dmem_wdata, dmem_be,
              dmem_req, dmem_we, imem_addr);
    input         clk, rst_n;
    // ⚠️ ENABLE LANDED FOR VALIDATION — SHAPE AWAITING COMPILER SEAM CHECK.
    // `en` is the adapter's `retire`. Architectural state advances ONLY when it is
    // high; every other cycle is a STALL cycle by definition (design §1: stall ≡
    // ¬retire, one object). Tie high for the single-cycle configuration.
    input         en;
    input  [31:0] instr;
    input  [31:0] dmem_rdata;
    output [31:0] dmem_addr, dmem_wdata;
    output [3:0]  dmem_be;
    // ⭐ THE MEMORY PORT ③ NEEDS, and the reason it is TWO WIRES rather than a
    // decode the plane repeats. `dmem_addr8` consumes `req` and `we_in`; the only
    // strobes core32 used to expose were opcode-only, so a plane wiring them would
    // falsify `DriveMap` (docs/silicon-stage3-drivemap-gap-0817.md).
    //
    // These two ARE the kernel's `req` and `isSW`: dmem_req = isLW ∨ isSW and
    // dmem_we = isSW, both funct3-gated. Exporting them — rather than letting the
    // plane re-derive them from `dmem_be` or an opcode compare — is what makes
    // `DriveMap` hold BY CONSTRUCTION and, more importantly, READABLE: the
    // hypothesis names two ports, and two ports is exactly what crosses.
    output        dmem_req, dmem_we;
    output [31:0] imem_addr;

    // ---- the survey's named boundaries -----------------------------------
    (* keep *) wire [31:0] pc_q, pc_next, pc_plus_4, pc_plus_imm;
    (* keep *) wire [31:0] imm, rf1, rf2, alu_y, ld_out, wb_val;
    (* keep *) wire        br_taken, alu_zero;

    reg [31:0] pc_r;
    always @(posedge clk) if (!rst_n) pc_r <= 32'h0; else if (en) pc_r <= pc_next;
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

    // ⭐ THE FUNCT3 GATE (③ seam ruling, Captain 08/17 "yes take recommendation
    // a+b"). `is_load`/`is_store` above test OPCODE ONLY, but the kernel's ISA is
    // WORD-ONLY: `Decoder.lean:31-33` has isLW = opcode ∧ funct3=010, isSW likewise,
    // and req = isLW ∨ isSW. Wiring the memory plane from the opcode-only strobes
    // would make `DriveMap` (Certs/DmemKernelBridge.lean:50-52) FALSE, which does
    // not break F4 door 1 — it makes it SILENT about the fabricated part.
    //
    // These two wires ARE the kernel's isLW and isSW, bit for bit, so the plane's
    // `req` ← is_load_w|is_store_w and `we_in` ← is_store_w discharge DriveMap by
    // construction rather than by assumption.
    //
    // ⚠️ CLAIM LANGUAGE IS BINDING (same ruling): the excluded encodings
    // (LB/LH/LBU/LHU/SB/SH) are MEMORY-INERT. They are NOT "refused" — nothing
    // traps, nothing signals; they simply cannot reach memory or the regfile.
    wire is_word    = (funct3 == 3'b010);
    wire is_load_w  = is_load  & is_word;
    wire is_store_w = is_store & is_word;

    // `is_load_w`, NOT `is_load` — the check the helm put inside this wave. Gating
    // only the MEMORY strobes would leave an excluded load still writing the
    // regfile from `ld_out`, which is not inert in any sense worth the word.
    wire reg_we = is_lui|is_auipc|is_jal|is_jalr|is_load_w|is_immop|is_regop;
    // alu_src stays OPCODE-ONLY on purpose: an excluded load still computes an
    // address into `dmem_addr`, and that is harmless because no strobe accompanies
    // it. Narrowing it would touch the ALU path for no architectural gain.
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
    always @(posedge clk) if (en && reg_we && rd != 5'd0) regs[rd] <= wb_val;
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

    // memory interface — WORD-ONLY. What stood here until 08/17 was `RTL/memif.v`
    // inlined: byte/half replication, lane enables, and extract-with-extend for
    // LB/LH/LBU/LHU/SB/SH. The 08/12 word-only ruling foreclosed the standalone
    // memif MODULE and left this COPY, so the logic shipped anyway and the silicon
    // executed six instructions `ISA.lean:126-135` excludes.
    //
    // Removed under the ③ seam ruling (a). Measured on the mirrored synth harness,
    // baseline arm reproducing the committed figure to the digit:
    //     core32 committed  5,054 cells  57,606.4992 µm²
    //     core32 word-only  4,434 cells  56,462.9024 µm²   −620 cells, −1,143.6 µm²
    // (−12.3% of CELLS but −2.0% of AREA — the removed cells are small ones, and
    // the cell percentage is the wrong figure to quote for an area argument.)
    assign dmem_addr  = alu_y;
    assign dmem_wdata = rf2;
    assign dmem_be    = {4{is_store_w}};
    assign ld_out     = dmem_rdata;
    // The seam, exported. `dmem_req` is the kernel's `req` (isLW ∨ isSW) and
    // `dmem_we` is `isSW` — see the port comment above for why the plane must NOT
    // re-derive these.
    assign dmem_req   = is_load_w | is_store_w;
    assign dmem_we    = is_store_w;

    // writeback select
    assign wb_val = is_load_w ? ld_out : (is_jal|is_jalr) ? pc_plus_4 :
                    is_lui ? imm : is_auipc ? pc_plus_imm : alu_y;
endmodule
