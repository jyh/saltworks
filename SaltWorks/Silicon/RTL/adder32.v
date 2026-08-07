// R2 TEST ARTICLE — a 32-bit add/sub, for the campaign freeze's kill-check R2
// ("THE ALU CONE: 32-bit add/sub cones exceed the per-cone law by construction.
// The claimed answer — bit-slice with per-slice carry obligations (the fabric's
// own pattern) — must be DEMONSTRATED on one slice before C3 freezes").
//
// ⚠️ NOT PART OF ANY SUBMISSION. `TT/assemble.sh` copies two NAMED files, never
// `RTL/*.v`, so this cannot reach the tape-out.
//
// The carry chain is `(* keep *)` for exactly the reason the fabric's stage
// boundaries are: a cut point that the flow dissolves is not a cut point. This
// is the treatment under test, not an optimisation.
module adder32(a, b, sub, sum, cout);
    input  [31:0] a;
    input  [31:0] b;
    input         sub;          // 1 => a - b (two's complement: invert b, carry in 1)
    output [31:0] sum;
    output        cout;

    wire [31:0] bx;
    (* keep *) wire [32:0] carry;

    assign bx = b ^ {32{sub}};
    assign carry[0] = sub;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : slice
            assign sum[i]      = a[i] ^ bx[i] ^ carry[i];
            assign carry[i+1]  = (a[i] & bx[i]) | (a[i] & carry[i]) | (bx[i] & carry[i]);
        end
    endgenerate

    assign cout = carry[32];
endmodule
