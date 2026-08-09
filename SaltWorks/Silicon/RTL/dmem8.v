// dmem8 — Slice-B's B1 memory organ at 8 words x 32 bits, REGISTER-BACKED.
//
// Priced for `slice-b-design-v1.md` B1: "silicon prices it in CELLS against
// the 1,154 banked AT THE SELECT". One of three sizes (8/16/32) so the answer
// is a CURVE — the design question is where the organ crosses the budget, and
// a single point cannot show that.
//
// SHAPE, and it is the honest minimum for LW/SW:
//   - word-addressed, 32-bit words (no byte enables; B4's alignment mask is a
//     separate row and is NOT priced here)
//   - SYNCHRONOUS write (SW), COMBINATIONAL read (LW) — one read port
//   - reset clears the array, because B-EXEC's isolation story wants a defined
//     initial state; this COSTS AREA and the no-reset variant is cheaper
//
// ⚠️ NOT AN SRAM MACRO. sky130 has compiled SRAM macros that are far denser per
// bit; this is the flop-backed form, which is what "register-backed memory at
// Slice-B scale" means in B1. The two are not comparable and must not be put in
// one column — the BB-switch §3 lesson about unlike regimes.
`default_nettype none

module dmem8 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        we,             // SW strobe
    input  wire [2:0]  addr, // word address
    input  wire [31:0] wdata,
    output wire [31:0] rdata           // LW, combinational
);
    reg [31:0] mem [0:7];
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1) mem[i] <= 32'd0;
        end else if (we) begin
            mem[addr] <= wdata;
        end
    end
    assign rdata = mem[addr];
endmodule

`default_nettype wire
