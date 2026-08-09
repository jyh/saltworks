// lmem8 — the LATCH-ARRAY rung of the memory ladder, 8 words x 32 bits.
//
// Council ruling, the Captain 09:0x: "let's probe the latch-ram, so we have a
// good ladder." This is the MIDDLE rung: flops (dmem8) -> LATCH ARRAY (here)
// -> SRAM macro (scouted; needs a 4x2 tile, see silicon-3x2-realdie-0809.md).
//
// [V-SRC, tinytapeout-dossier.md:400] "Latches are ALLOWED (TT documents
// latch-based memory as an area win)." So this rung is sanctioned by the shuttle.
//
// ⚠️ ONE-VARIABLE PARITY WITH `dmem8.v`, deliberately — same interface, same
// SYNCHRONOUS write / COMBINATIONAL read, and the SAME RESET-CLEARS-THE-ARRAY
// behaviour. dmem's own header notes that the reset COSTS AREA and that a
// no-reset variant is cheaper; carrying that cost here too is what makes the
// flop-vs-latch delta attributable to the STORAGE ELEMENT and nothing else.
//
// ⛔ WHAT THIS PRICES AND WHAT IT DOES NOT. It prices AREA under the same flow
// as the flop rung. It does NOT certify latch timing: transparency is gated on
// the clock-low phase (`~clk`), which is the DFFRAM-style discipline, but
// glitch/hold behaviour on a real floorplan needs its own check before any
// latch array is trusted in a datapath. Priced, not blessed.
`default_nettype none

module lmem8 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        we,             // SW strobe
    input  wire [2:0]  addr,           // word address
    input  wire [31:0] wdata,
    output wire [31:0] rdata           // LW, combinational
);
    wire [31:0] dout [0:7];

    genvar w;
    generate
        for (w = 0; w < 8; w = w + 1) begin : bank
            // Each bank owns its OWN reg: no shared array, so no ambiguity
            // about which generate block drives which element.
            wire wen = we & (addr == w[2:0]) & ~clk;
            reg [31:0] q;
            always @* begin
                if (!rst_n)     q = 32'd0;
                else if (wen)   q = wdata;
            end
            assign dout[w] = q;
        end
    endgenerate

    assign rdata = dout[addr];
endmodule

`default_nettype wire
