// dmem_addr16 — B4's ALIGNMENT MASK, STATED AT THE RTL, for a 16-word dmem.
//
// slice-b-design-v1.md B4: "address alignment/width at LW/SW (state the mask,
// prove the mask)". This is the STATE half, in synthesizable form, so the mask
// is one artifact rather than a sentence in a design doc — and so it can be
// PRICED, which is the question B1 actually asks.
//
// ⭐ WHY THIS IS A SEPARATE MODULE, AND IT IS A DESIGN FINDING, NOT PACKAGING:
// `dmem8/16/32.v` take `addr` as a WORD INDEX. A word-indexed memory CANNOT
// EXPRESS A MISALIGNED ACCESS — there is no bit in its interface that could be
// wrong. So the alignment trap cannot live in the memory organ; it lives in the
// ADDRESS PATH upstream, and B4's "the memory organ must not silently widen the
// state the executive later quantifies over" is satisfied by construction:
// the organ's state is 16x32 bits and no address input can reach outside it.
//
// ⇒ THE MASK IS A PROPERTY OF THE ADDRESSING, NOT OF THE MEMORY. Anyone pricing
//   "the memory with alignment" as one number is pricing two organs that are
//   separable, and the separation is what makes the trap provable.
//
// THE MASK, stated exactly (32-bit words, 16 words = 64 bytes at base 0):
//   misaligned   <=>  byte_addr[1:0] != 2'b00
//   out_of_range <=>  byte_addr[31:6] != 0
//   trap         <=>  req & (misaligned | out_of_range)
//   effective we <=>  we & req & !misaligned & !out_of_range
//
// ⚠️ THE WRITE-SUPPRESSION TERM IS THE LOAD-BEARING ONE. A trap that raises a
// flag but still lets `we` through writes to a wrong word and then reports an
// error — the isolation frame theorem in B-EXEC E2 would be FALSE while the
// trap logic looked correct. `we_out` is gated on the SAME predicate the trap
// is raised on, so the two cannot disagree.
//
// ⛔ WHAT THIS DOES NOT DO: byte and half-word accesses (LB/LH/SB/SH are not in
// Slice-B's five ops). If they arrive, this module is wrong rather than
// incomplete — the mask becomes width-dependent and `we_out` needs byte enables.
`default_nettype none

module dmem_addr16 (
    input  wire [31:0] byte_addr,
    input  wire        req,           // an LW or SW is being attempted
    input  wire        we_in,         // the access is a store
    output wire        misaligned,
    output wire        out_of_range,
    output wire        trap,
    output wire        we_out,        // the SUPPRESSED write strobe
    output wire [3:0]  word_index
);
    assign misaligned   = byte_addr[1] | byte_addr[0];
    assign out_of_range = |byte_addr[31:6];
    assign trap         = req & (misaligned | out_of_range);
    assign we_out       = we_in & req & ~misaligned & ~out_of_range;
    assign word_index   = byte_addr[5:2];
endmodule

`default_nettype wire
