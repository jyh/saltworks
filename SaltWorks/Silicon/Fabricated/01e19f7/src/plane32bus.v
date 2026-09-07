// plane32bus — THE LW/SW PLANE ON THE BYTE-PHASE BUS. Rung zero's composition
// object: core32 reaching memory OFF-CHIP through busadapt8, in the shape the
// 24-pin wrapper already sockets.
//
// ⭐ WHY THIS MODULE EXISTS AND WHAT IT IS FOR.
// Rung zero (§11′ of docs/silicon-offboard-data-block-0817.md) is "build and
// measure the COMPOSITION", and its CONTROL row is explicit: *any composed-area
// claim must cite a COMMITTED stat file whose netlist greps positive for BOTH a
// core/plane instance AND banyan_fabric. NO FILE, NO CLAIM.* This module is the
// plane half of that file. It is built to be SYNTHESIZED AND MEASURED.
//
// ⛔ SCOPE, INHERITED VERBATIM FROM THE TOP IT PLUGS INTO: a layout of this
// composition measures area / timing / DRC / LVS / antenna. **It is NOT a
// functional demo and NOT a tile-fit signoff. Functional correctness is
// fence-held.** Nothing here is a claim that this plane executes a program.
//
// ── THE SOCKET, MEASURED NOT ASSUMED ───────────────────────────────────────────
// tt_um_saltworks_ndf instantiates its core as
//     slicea16bma core (.clk, .rst_n, .instr_byte(ui_in), .addr_byte(uo_out),
//                       .phase_o(phase_o));
// and busadapt8's pin ports are pin_in[7:0] / pin_out[7:0] / phase_pins[1:0].
// ⇒ THE PIN SHAPES ALREADY AGREE. The 32-bit plane needs NO new pins: the
// byte-phase socket is occupied by a 16-bit core today, and this is the 32-bit
// tenant. §1's "there are no pins left" was withdrawn at §6, and this module is
// the constructive reason it did not need to be re-fought.
//
// ── `en`, AND I AM NOT SETTLING WHAT IS NOT MINE ───────────────────────────────
// ⚠️ `core32.en` IS WIRED TO `busadapt8.retire`, WHICH IS THE MARKED VALIDATION
// SHAPE AND **NOT A RATIFIED DESIGN**. core32.v's own port comment says "`en` is
// the adapter's `retire`", landed 5f25f53 and marked "shape awaiting compiler seam
// check"; two signatures are owed before it is ratified, and the 08/18 ruling
// found the enable NECESSARY AND NOT SUFFICIENT — `retire` appears nowhere in the
// loop arbitration, and what releases the fetch is `instr_r` committing UNGATED.
// **That repair is item 10 (kind-must-consult-retire), TWO-SIGNATURE, on the
// Captain's desk. It is deliberately NOT made here.** This module carries the
// marking forward rather than quietly adopting the shape.
// ⛔ AND `en` IS CONNECTED EXPLICITLY, NEVER LEFT OPEN: a floating `en` silently
// froze the core in all four consumers from 5f25f53 to 00ebe93, memplane8
// included. **A NEW INSTANTIATION IS EXACTLY WHERE THAT DEFECT RECURS, and
// Verilog will not say so.**
//
// ── WHAT THIS PLANE IS NOT ─────────────────────────────────────────────────────
// It is NOT memplane8. memplane8 terminates the data path ON-CHIP (core32 +
// dmem_addr8 + dmem8, single-cycle, combinational address path) and exposes no
// data-side ports; busadapt8 expects to BE the data path. **The two are
// ALTERNATIVE memory back-ends for the same core and do not chain.** Choosing
// between them is a design question this module does not settle either — it
// builds the off-chip arm so the composition can be priced against the on-chip
// one with receipts instead of estimates.
//
// NOT a submission artifact.
`default_nettype none

module plane32bus(clk, rst_n, sof, instr_byte, addr_byte, phase_o, retire);
    input  wire       clk, rst_n;
    input  wire       sof;         // uio_in[6] at the top — shared with the fabric
    input  wire [7:0] instr_byte;  // ui_in   — returned byte, low byte first
    output wire [7:0] addr_byte;   // uo_out  — address byte, then store-data byte
    output wire [1:0] phase_o;     // uio_out[1:0] — TYPE at phase 0, PHASE at 1..3
    output wire       retire;      // brought out: an unobserved strobe is the shape
                                   // a synthesiser deletes, and its flop count is
                                   // this module's own control.

    // ---- core -> adapter -------------------------------------------------------
    wire [31:0] c_imem_addr, c_dmem_addr, c_dmem_wdata;
    wire [3:0]  c_dmem_be;
    wire        c_dmem_req, c_dmem_we;
    // ---- adapter -> core -------------------------------------------------------
    wire [31:0] c_instr, c_dmem_rdata;

    core32 u_core(
        .clk(clk), .rst_n(rst_n),
        .en(retire),                    // ⚠️ MARKED shape — see the header block
        .instr(c_instr),
        .dmem_rdata(c_dmem_rdata),
        .dmem_addr(c_dmem_addr), .dmem_wdata(c_dmem_wdata), .dmem_be(c_dmem_be),
        .dmem_req(c_dmem_req), .dmem_we(c_dmem_we),
        .imem_addr(c_imem_addr));

    busadapt8 u_bus(
        .clk(clk), .rst_n(rst_n), .sof(sof),
        .c_imem_addr(c_imem_addr), .c_dmem_addr(c_dmem_addr),
        .c_dmem_wdata(c_dmem_wdata),
        .c_dmem_req(c_dmem_req), .c_dmem_we(c_dmem_we),
        .c_instr(c_instr), .c_dmem_rdata(c_dmem_rdata),
        .pin_in(instr_byte), .pin_out(addr_byte), .phase_pins(phase_o),
        .retire(retire));

    // `c_dmem_be` is UNUSED and that is not an oversight: under the word-only ISA
    // it is {4{isSW}}, which carries nothing `c_dmem_we` does not already carry,
    // and the byte-phase bus is word-granular with no byte-enable pins. It stays a
    // core32 port because the census and the D2 area rows name it. Tied off
    // observably rather than left dangling, exactly as memplane8 does.
    wire _unused_be = &{1'b0, c_dmem_be};
endmodule

`default_nettype wire
