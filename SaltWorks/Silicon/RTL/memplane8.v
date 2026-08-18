// memplane8 — ③'s INTEGRATION PLANE: core32 + dmem_addr8 + dmem8, wired.
//
// This module is the realization of the plane `DriveMap` describes. Until it
// existed, F4 door 1's hypothesis had no referent in RTL at all: compiler's
// finding, helm-verified, was that NOTHING instantiates `dmem_addr8` anywhere in
// RTL or Flow, so `dmem_wdata ← req` and `dmem_be ← we_in` had no source.
//
// ⭐ WHAT MAKES `DriveMap` TRUE HERE, AND WHY IT IS TWO WIRES AND NOT A COMMENT.
// `DriveMap` (Certs/DmemKernelBridge.lean:50-52) asks for exactly:
//
//     we  : ins 33 = (ctrlSpec w)[6]!     -- dmem_addr8.we_in  ← isSW
//     req : ins 32 = (ctrlSpec w)[7]!     -- dmem_addr8.req    ← isLW ∨ isSW
//
// `core32.dmem_we` IS isSW and `core32.dmem_req` IS isLW ∨ isSW — both funct3-gated
// (core32.v, the ③ seam ruling). They are carried here by DIRECT WIRE, with no
// re-derivation, no width change and no intervening logic, so the hypothesis is
// discharged by construction rather than assumed. A plane that re-derived these
// from `dmem_be` or from an opcode compare would be the exact defect that
// docs/silicon-stage3-drivemap-gap-0817.md records.
//
// ⚠️ WHAT THIS PLANE DOES NOT DO, stated because an integration invites the
// assumption that everything now meets:
//   · it is SINGLE-CYCLE and COMBINATIONAL through the address path. There is no
//     handshake, no stall, and no multi-cycle access. `dmem8`'s read is
//     combinational and its write lands on the clock edge.
//   · it does NOT model reset. `dmem8`'s 256 flops are async-reset (dfrtp) and the
//     imported datum is RESTRICTED to `rst_n ≡ 1`; nothing here says anything about
//     the deassertion seam.
//   · `trap` is BROUGHT OUT, not handled. C3's scope is machine mode without
//     CSR/trap, so there is no trap target to jump to yet. Exporting it keeps the
//     signal observable instead of quietly tying it off — an unobserved trap is
//     the shape a synthesiser deletes.
//   · the excluded encodings are MEMORY-INERT here as they are in core32: they
//     raise neither `dmem_req` nor `dmem_we`, so `we_out` cannot rise for them.
//     They are NOT refused; nothing signals.
//
// NOT a submission artifact.
module memplane8(clk, rst_n, instr, imem_addr,
                 dmem_addr, dmem_trap, dmem_misaligned, dmem_out_of_range);
    input         clk, rst_n;
    input  [31:0] instr;
    output [31:0] imem_addr;
    output [31:0] dmem_addr;
    output        dmem_trap, dmem_misaligned, dmem_out_of_range;

    // ---- core -> memory ---------------------------------------------------
    wire [31:0] c_dmem_addr, c_dmem_wdata;
    wire [3:0]  c_dmem_be;
    wire        c_dmem_req, c_dmem_we;
    // ---- memory -> core ---------------------------------------------------
    wire [31:0] m_rdata;
    // ---- address mask -> memory -------------------------------------------
    wire        a_we_out;
    wire [2:0]  a_word_index;

    core32 u_core(
        // en TIED HIGH: memplane8 is the SINGLE-CYCLE configuration. Left floating
        // since 5f25f53 this silently froze the core — found by the executor, 08/18.
        .clk(clk), .rst_n(rst_n), .en(1'b1), .instr(instr),
        .dmem_rdata(m_rdata),
        .dmem_addr(c_dmem_addr), .dmem_wdata(c_dmem_wdata), .dmem_be(c_dmem_be),
        .dmem_req(c_dmem_req), .dmem_we(c_dmem_we),
        .imem_addr(imem_addr));

    // THE SEAM. These two connections are the whole of `DriveMap`.
    dmem_addr8 u_mask(
        .byte_addr(c_dmem_addr),
        .req(c_dmem_req),               // ← ctrlSpec[7], isLW ∨ isSW
        .we_in(c_dmem_we),              // ← ctrlSpec[6], isSW
        .misaligned(dmem_misaligned),
        .out_of_range(dmem_out_of_range),
        .trap(dmem_trap),
        .we_out(a_we_out),
        .word_index(a_word_index));

    // `we_out` is the SUPPRESSED strobe: dmem_addr8 already gates it on
    // ~misaligned & ~out_of_range, and DmemAddr8Suppress proves at the emitted
    // gates that it cannot coincide with `trap`. dmem8 therefore needs no
    // additional guard, and adding one would duplicate a proved property in
    // unproved logic.
    dmem8 u_mem(
        .clk(clk), .rst_n(rst_n),
        .we(a_we_out),
        .addr(a_word_index),
        .wdata(c_dmem_wdata),
        .rdata(m_rdata));

    assign dmem_addr = c_dmem_addr;

    // c_dmem_be is intentionally UNUSED here and that is not an oversight: under
    // the word-only ISA it is {4{isSW}}, which carries no information `we_out`
    // does not already carry, and dmem8 is word-granular with no byte enables.
    // It stays a core32 port because the census and the D2 area rows name it.
    wire _unused_be = &{1'b0, c_dmem_be};
endmodule
