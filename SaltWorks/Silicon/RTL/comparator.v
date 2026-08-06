// The Batcher comparator cell: 8-bit unsigned, emits (min,max).
// 16 input bits -- the design doc's "the comparator cell is 16".
module comparator (
    input  wire [7:0] a,
    input  wire [7:0] b,
    output wire [7:0] lo,
    output wire [7:0] hi
);
    wire swap = (a > b);
    assign lo = swap ? b : a;
    assign hi = swap ? a : b;
endmodule
