// T3 — out_of_range ABSENT, misaligned CORRECT. MUST REJECT.
//
// Half the trap semantics, and the half that is harder to notice: alignment is
// the check people remember, so a module that gets alignment exactly right reads
// as careful. Every address on the machine is now "in range", including the ones
// that are not in the eight-word file at all.
//
// T3 and T4 are a PAIR, and together they are math's D1c bridge constraint
// reaching the checker: they prove the two trap bits are examined INDEPENDENTLY.
// A checker that only tested `trap` — the OR of the two — would pass both, since
// each plant still raises `trap` on its own half of the bad addresses.
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
    assign out_of_range = 1'b0;               // <-- PLANTED: the range test is gone
    assign trap         = req & (misaligned | out_of_range);
    assign we_out       = we_in & req & ~misaligned & ~out_of_range;
    assign word_index   = byte_addr[4:2];
endmodule

`default_nettype wire
