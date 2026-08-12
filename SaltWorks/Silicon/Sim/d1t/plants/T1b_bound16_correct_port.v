// T1b — THE INHERITED 16-WORD BOUND, WITH THE PORT WIDTH ALREADY FIXED.
// MUST REJECT, and must reject on arm [B] — the BOUND, not the interface.
//
// ⛔ WHY THIS PLANT EXISTS, AND IT IS A CORRECTION TO MY OWN PRE-REGISTERED BAR.
// T1 was registered as "plant dmem_addr16 unmodified" with the rationale "the
// ONLY arm that can catch the 16-word bound being inherited". Measured 8/12
// while prototyping D1t: the unmodified sibling is rejected by arm [A] on its
// 4-BIT PORT, before any proof runs — so T1 as written is satisfied WITHOUT THE
// BOUND EVER BEING TESTED. The arm and its stated reason had come apart.
//
// This plant is the accident the maestro's anchor actually describes: an
// engineer copies the sibling, FIXES the port width (which the tool warns about
// and which is visible in the stat file), and MISSES the bound (which nothing
// warns about). It is more likely than the literal unmodified copy, and it is
// the case where every cheap instrument reads green.
//
// THE DEFECT: out_of_range fires at >= 64 instead of >= 32. Byte addresses
// 32..63 pass as in-range and ALIAS onto the 8 slots — memory-design-v1.md's
// ⬥v1.1 kill, verbatim: "byte addresses 32-63 pass as in-range and ALIAS onto
// dmem8's 8 slots when the top index bit is dropped".
// Everything else — ports, misaligned, trap, we_out gating, word_index — is
// CORRECT, so no arm but the proof can see it.
`default_nettype none

module dmem_addr8 (
    input  wire [31:0] byte_addr,
    input  wire        req,
    input  wire        we_in,
    output wire        misaligned,
    output wire        out_of_range,
    output wire        trap,
    output wire        we_out,
    output wire [2:0]  word_index
);
    assign misaligned   = byte_addr[1] | byte_addr[0];
    assign out_of_range = |byte_addr[31:6];   // <-- PLANTED: 16 words, not 8
    assign trap         = req & (misaligned | out_of_range);
    assign we_out       = we_in & req & ~misaligned & ~out_of_range;
    assign word_index   = byte_addr[4:2];
endmodule

`default_nettype wire
