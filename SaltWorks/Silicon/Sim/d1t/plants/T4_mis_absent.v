// T4 — misaligned ABSENT, out_of_range CORRECT. MUST REJECT.
//
// The mirror of T3. The eight-word bound is enforced exactly; alignment is not,
// so byte 1 reads word 0 and byte 3 writes it. `word_index` silently drops the
// low two bits, which is what makes a misaligned access UNEXPRESSIBLE at the
// organ and is the whole reason the trap lives in the address path (the finding
// in dmem_addr16.v's header, lines 8-18).
//
// T3+T4 together are what prove the checker looks at the two bits SEPARATELY
// rather than at their OR.
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
    assign misaligned   = 1'b0;               // <-- PLANTED: the alignment test is gone
    assign out_of_range = |byte_addr[31:5];
    assign trap         = req & (misaligned | out_of_range);
    assign we_out       = we_in & req & ~misaligned & ~out_of_range;
    assign word_index   = byte_addr[4:2];
endmodule

`default_nettype wire
