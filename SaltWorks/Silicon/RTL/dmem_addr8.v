// dmem_addr8 — THE ADDRESS MASK FOR dmem8, at the RULED 8-WORD WIDTH.
//
// Stage ③ D1b. This is the module `memory-design-v1.md` ⬥v1.1 commissioned when
// it killed the dmem8/dmem_addr16 pairing (the U1 kill, found independently by
// r-trap and r-exec-lang): a 16-word mask lets byte addresses 32–63 pass as
// in-range and ALIAS onto dmem8's 8 slots, and the kernel's 8-word `outOfRange`
// (≥ 32) would DISAGREE with a 16-word RTL's (≥ 64), making F4's equivalence
// false as cited.
//
// ⛔⛔ THIS FILE IS VERIFIED AGAINST THE RULING, NEVER AGAINST ITS SIBLING.
// `dmem_addr16.v` is CORRECT CODE for a memory this is not. Copying a correct
// file is exactly how a 16-word bound gets inherited without anyone stating it,
// so every line below is justified by a kernel or design-doc citation, and the
// sibling is used only as the shape the citations happen to have already taken.
//
// ⭐ THE RULING, AT THREE SOURCES THAT AGREE, none of them the sibling:
//
//   SaltWorks/HDL/ISA.lean:111-114   the kernel classification, RANGE FIRST
//       def addrClass (a : BitVec 32) : AddrClass :=
//         if 32 ≤ a.toNat then .outOfRange
//         else if a.toNat % 4 ≠ 0 then .misaligned
//         else .ok
//   SaltWorks/HDL/ISA.lean:121       addrClass_ok_lt — PROVED, and it is the
//       word-index width: `addrClass a = .ok → a.toNat / 4 < 8`. Three bits.
//   docs/memory-design-v1.md:388-390 the mask stated as bits:
//       out_of_range = |byte_addr[31:5] · word_index = byte_addr[4:2], 3 BITS
//
// EACH LINE, AND WHAT DISCHARGES IT:
//   misaligned    ⟺ a.toNat % 4 ≠ 0        ⟺ byte_addr[1:0] ≠ 0   (32-bit words)
//   out_of_range  ⟺ 32 ≤ a.toNat           ⟺ byte_addr[31:5] ≠ 0  (8 words = 32 B = 2^5)
//   word_index    = a.toNat / 4, and for an `ok` address (< 32, low bits clear)
//                   that is exactly byte_addr[4:2] — three bits, the width
//                   `addrClass_ok_lt` proves and the block states.
//
// ⚠️ THREE EDIT SITES, NOT TWO — AND THE THIRD IS WHY DERIVING THE DELTA FROM
// THE SIBLING IS NOT ENOUGH. The two ASSIGNMENTS move ([31:6]→[31:5] and
// [5:2]→[4:2]); so does the PORT DECLARATION, [3:0]→[2:0]. Editing only the
// assignments COMPILES: a 3-bit value into a 4-bit port zero-extends, yielding a
// correct value on a wrong-width interface, presented to an organ whose `addr`
// is 3 bits. A 16-word SHAPE would survive into an 8-word module through the one
// line of the file that is not an expression. The block's own D1b text and the
// silicon bank both say "two bit-ranges"; the RULING says "3 bits" and is right.
//
// ⭐ THE TWO TRAP BITS ARE INDEPENDENT, AND THAT IS THE RULING, NOT A LAPSE.
// The kernel's enum forces a PRIORITY — byte 33 classifies `outOfRange`, not
// `misaligned`, because `addrClass` tests range first (and ISA.lean:107-110
// records that the order was chosen so `outOfRange ↔ byte_addr ≥ 32` reads as
// stated). This RTL raises BOTH bits at byte 33. The disagreement is
// PRE-REGISTERED by the fold as correct — memory-design-v1.md, F4 bridge facts:
// "the RTL carries `misaligned` and `out_of_range` as TWO INDEPENDENT bits (a
// both-bad address sets both); the kernel enum forces a priority. The bridge
// therefore relates the RESPONSE (we_out suppressed + trap raised), not the
// class label." ISA.lean:222-228 is the kernel half of the same fact: both bad
// classes take ONE `else` arm because they "are specified to produce the
// IDENTICAL response".
// ⇒ ANY CHECKER OR PROOF THAT DEMANDS THIS RTL REPRODUCE THE KERNEL'S PRIORITY
//   IS ENFORCING THE OPPOSITE OF THE RULING. The bridge relates responses.
//
// ⚠️ THE WRITE-SUPPRESSION TERM IS THE LOAD-BEARING ONE (kept from the sibling's
// header because it is a statement about this design, not about that width). A
// trap that raises a flag but still lets `we` through writes to a wrong word and
// then reports an error — the isolation frame would be FALSE while the trap
// logic looked correct. `we_out` is gated on the SAME predicate `trap` is raised
// on, so the two cannot disagree. The kernel's trapped arm writes no memory cell
// and no register; suppression is what realises that.
//
// ⛔ WHAT THIS DOES NOT DO: byte and half-word accesses. The kernel is WORD-ONLY
// by ruling (ISA.lean:132 — `LW`/`SW` and nothing else, "so there are no byte
// semantics to get wrong"). If LB/LH/SB/SH ever arrive, this module is WRONG
// rather than incomplete: the mask becomes width-dependent and `we_out` needs
// byte enables.
//
// ⛔ NOT A REPLACEMENT FOR dmem_addr16.v. That file stays: it is the correct
// mask for a 16-word memory, and it is D1t's T1 planted failure — the negative
// control that proves the checker can catch an inherited 16-word bound.
`default_nettype none

module dmem_addr8 (
    input  wire [31:0] byte_addr,
    input  wire        req,           // an LW or SW is being attempted
    input  wire        we_in,         // the access is a store
    output wire        misaligned,
    output wire        out_of_range,
    output wire        trap,
    output wire        we_out,        // the SUPPRESSED write strobe
    output wire [2:0]  word_index     // 3 bits — addrClass_ok_lt, and it is a PORT
);
    assign misaligned   = byte_addr[1] | byte_addr[0];
    assign out_of_range = |byte_addr[31:5];
    assign trap         = req & (misaligned | out_of_range);
    assign we_out       = we_in & req & ~misaligned & ~out_of_range;
    assign word_index   = byte_addr[4:2];
endmodule

`default_nettype wire
