// ref_dmem_addr8 — THE RULING, TRANSCRIBED AS A REFERENCE MODEL. NOT SYNTHESIZED.
//
// D1t's arm [B] proves the candidate equivalent to THIS, over all 2^34 input
// assignments, with yosys `miter -equiv` + `sat -prove-asserts`.
//
// ⭐ DELIBERATELY WRITTEN IN A DIFFERENT STYLE FROM ANY CANDIDATE. The candidate
// says `|byte_addr[31:5]`; this says `byte_addr >= 32`. The candidate says
// `byte_addr[4:2]`; this says `(byte_addr / 4) % 8`. That is the point: the
// equivalence `32 <= a  <->  |a[31:5]` is the nontrivial content of the width
// edit, and a reference written in the SAME bit-slicing idiom would assume it
// rather than check it. Here the SAT proof discharges it over every address.
//
// ⚠️ WHAT THIS DOES AND DOES NOT ESTABLISH, stated because both files are in one
// hand and [[agreement-is-not-corroboration]] applies to me first:
//   DOES     prove the candidate computes the ARITHMETIC FUNCTION the ruling
//            states, on every input — no sampling, no testbench coverage claim.
//   DOES NOT prove the ruling is what the kernel means. That is the F4 bridge
//            and it belongs to math. This file is a transcription; if it is
//            mistranscribed, arm [B] is wrong in both directions at once.
//   MITIGATION, and it is the only honest one available: every line below cites
//            the kernel text it transcribes, so the transcription is checkable
//            by reading, and the two formulations are structurally independent.
//
// THE SOURCE TEXT, SaltWorks/HDL/ISA.lean:111-114 —
//     def addrClass (a : BitVec 32) : AddrClass :=
//       if 32 <= a.toNat then .outOfRange
//       else if a.toNat % 4 != 0 then .misaligned
//       else .ok
// and ISA.lean:121, addrClass_ok_lt, PROVED:  ok -> a.toNat / 4 < 8.
//
// ⚠️ THE KERNEL'S PRIORITY IS NOT TRANSCRIBED, AND THAT IS THE RULING.
// `addrClass` tests range FIRST, so byte 33 is `outOfRange` and NOT `misaligned`.
// This reference raises BOTH bits at byte 33, exactly as the RTL does, because
// memory-design-v1.md's F4 bridge facts pre-register that shape: "the RTL
// carries misaligned and out_of_range as TWO INDEPENDENT bits (a both-bad
// address sets both); the kernel enum forces a priority. The bridge therefore
// relates the RESPONSE, not the class label."
// ⇒ A REFERENCE THAT IMPOSED THE PRIORITY WOULD MAKE D1t ENFORCE THE OPPOSITE OF
//   THE RULING, and it would look MORE faithful to ISA.lean while being wrong.
//
// ⚠️ `word_index` IS COMPARED ON EVERY INPUT, INCLUDING TRAPPING ONES — which is
// STRICTER than the kernel requires. The kernel only ever uses the index on an
// `ok` address (that is what `addrClass_ok_lt` licenses). The ruling states the
// assignment unconditionally, so D1t enforces it unconditionally; a candidate
// that zeroed its index on a trap would be REJECTED. That is a deliberate
// choice, and it is recorded here rather than discovered by whoever it bites.
`default_nettype none

module ref_dmem_addr8 (
    input  wire [31:0] byte_addr,
    input  wire        req,
    input  wire        we_in,
    output wire        misaligned,
    output wire        out_of_range,
    output wire        trap,
    output wire        we_out,
    output wire [2:0]  word_index
);
    wire ok;
    // a.toNat % 4 != 0
    assign misaligned   = (byte_addr % 32'd4) != 32'd0;
    // 32 <= a.toNat
    assign out_of_range = (byte_addr >= 32'd32);
    // the .ok arm of addrClass, after both tests
    assign ok           = !misaligned && !out_of_range;
    // trapped := true on a bad address; nothing traps without a request
    assign trap         = req && !ok;
    // the write is SUPPRESSED, not merely flagged — the load-bearing term
    assign we_out       = we_in && req && ok;
    // a.toNat / 4, in the 8-word file addrClass_ok_lt proves it lands in
    assign word_index   = (byte_addr / 32'd4) % 32'd8;
endmodule

`default_nettype wire
