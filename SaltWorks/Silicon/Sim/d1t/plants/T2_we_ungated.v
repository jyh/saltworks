// T2 — THE TRAP RAISES AND THE WRITE STILL LANDS. MUST REJECT.
//
// dmem_addr16.v's own stated hazard, planted: "A trap that raises a flag but
// still lets `we` through writes to a wrong word and then reports an error — the
// isolation frame theorem would be FALSE while the trap logic looked correct."
//
// THE DEFECT: `we_out` is no longer gated on the trap predicate. `trap` is
// still raised, correctly, on every bad address — so a reader checking "does it
// detect bad addresses?" sees a correct module. The suppression is the
// load-bearing term and it is the one that is gone.
//
// Caught by arm [B]: at any bad address with req & we_in, the reference
// suppresses the write and this does not.
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
    assign out_of_range = |byte_addr[31:5];
    assign trap         = req & (misaligned | out_of_range);
    assign we_out       = we_in & req;        // <-- PLANTED: suppression removed
    assign word_index   = byte_addr[4:2];
endmodule

`default_nettype wire
