// T6 — BOTH ASSIGNMENTS CORRECT, THE PORT LEFT AT [3:0]. MUST REJECT.
//
// ⭐ THE HARDEST ARM, AND IT WAS NOT IN THE ORIGINAL FIVE. Registered 8/12 10:1x,
// before one line of the checker existed, after the measurement below.
//
// This file differs from the accepted `RTL/dmem_addr8.v` in EXACTLY ONE LINE —
// the `word_index` port declaration. Measured on that controlled pair:
//
//     iverilog   WARNS ("expects 4 bit(s), given 3 — padding 1 high bits") and
//                EXITS 0. It warns without -Wall, and no Sim/*/run.sh in this
//                tree passes -Wall.
//     simulation 144 stimulus points, store-then-load over byte 0..71:
//                ZERO DIVERGENCE from the correct file. The padded bit is
//                constant zero, so the composed machine behaves identically.
//                NO TESTBENCH CAN REACH THIS DEFECT.
//     synthesis  85.0816 um2 — IDENTICAL to the correct file. Yosys ties the
//                constant bit off; area cannot see it either.
//     port bits  42 — WHICH IS THE SIXTEEN-WORD SIBLING'S FIGURE, EXACTLY
//                (dmem_addr8 correct: 41; dmem_addr16: 42).
//
// ⇒ INDISTINGUISHABLE FROM THE RIGHT FILE by area and by simulation, and
//   INDISTINGUISHABLE FROM THE 16-WORD MASK by the port census. The interface
//   announces a sixteen-word memory while the logic implements eight.
//
// ⛔ NOT SUBSUMED BY T1. T1 plants the unmodified sibling, in which BOTH
// assignments are also wrong — so a checker that examines only the two
// assignment expressions REJECTS T1, ACCEPTS T5, and PASSES THIS FILE. That is
// the hole this arm closes, and it was invisible while the only artifact under
// test was the one that already had the port right
// ([[criterion-weaker-than-artifact]]).
//
// Caught by arm [A] on the port record. Arm [B] is NOT REACHED for this plant —
// the miter cannot be built against a mismatched port — and the checker prints
// that rather than omitting it.
`default_nettype none

module dmem_addr8 (
    input  wire [31:0] byte_addr,
    input  wire        req,
    input  wire        we_in,
    output wire        misaligned,
    output wire        out_of_range,
    output wire        trap,
    output wire        we_out,
    output wire [3:0]  word_index    // <-- PLANTED: 4 bits. THE ONLY CHANGED LINE.
);
    assign misaligned   = byte_addr[1] | byte_addr[0];
    assign out_of_range = |byte_addr[31:5];
    assign trap         = req & (misaligned | out_of_range);
    assign we_out       = we_in & req & ~misaligned & ~out_of_range;
    assign word_index   = byte_addr[4:2];
endmodule

`default_nettype wire
