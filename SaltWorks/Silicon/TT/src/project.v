/*
 * SPDX-FileCopyrightText: 2026 Jason Hickey
 * SPDX-License-Identifier: Apache-2.0
 *
 * TinyTapeout wrapper for the 8x8 bit-serial banyan fabric.
 *
 * The pin map is `docs/silicon-frame-protocol-0806.md` §6. The whole reason the
 * fabric is bit-serial is that TT's 8-in/8-out pinout cannot carry a
 * word-parallel 8x8 switch (64+ pins), while a serial fabric fits it exactly:
 * 8 serial in, 8 serial out, clk from TT, and all 8 `uio` still spare.
 *
 * CLOCK: `info.yaml` requests 25 MHz deliberately. The pad's maximum OUTPUT
 * rate is 33 MHz -- half its input ceiling -- and a bit-serial fabric toggles
 * every output every cycle, so the template's 50 MHz default is over the
 * rating. 25 MHz leaves ~24% margin. (Lowering the clock fixes setup, not
 * hold; hold is checked by the flow and is the residual risk.)
 *
 * POWER GATING: TT drives `ena` and the power-gate enable from one signal, so
 * an unselected design loses ALL flop state and the reset pulse width is
 * undocumented. Every register here is unconditionally reloaded at its own
 * strobe, so an arbitrary power-up state is overwritten by the first frame.
 * That is a hypothesis of the D3.5 refinement, discharged by quantifying over
 * all 16 element states rather than assuming a reset value.
 */

`default_nettype none

module tt_um_saltworks_banyan (
    input  wire [7:0] ui_in,    // dedicated inputs  — the 8 serial lines in
    output wire [7:0] uo_out,   // dedicated outputs — the 8 serial lines out
    input  wire [7:0] uio_in,   // bidirectional: input path
    output wire [7:0] uio_out,  // bidirectional: output path
    output wire [7:0] uio_oe,   // bidirectional: 1 = drive
    input  wire       ena,      // high while this design is selected
    input  wire       clk,
    input  wire       rst_n     // active low
);

    wire [3:0] cnt_o;
    wire       valid;

    banyan_fabric #(.PAYLOAD(8)) fabric (
        .clk   (clk),
        .rst_n (rst_n),
        .sof   (uio_in[0]),     // start of frame, from the host
        .din   (ui_in),
        .dout  (uo_out),
        .cnt_o (cnt_o),
        .valid (valid)
    );

    // uio[0] is an input (sof); uio[5:1] report frame state for bring-up;
    // uio[7:6] are reserved and driven low.
    //
    // uio[5] = cnt[3], added 8/8 on the maestro's ruling. Three counter bits
    // cannot identify the phase of a 14-cycle frame — cycles 8..13 alias onto
    // 0..5 — and the amended spec §5 makes well-phasedness the whole
    // correctness premise, so the pin that reports phase must not alias.
    // Observability only: one assign, no logic, nothing in the datapath.
    assign uio_out = {2'b00, cnt_o[3], valid, cnt_o[2:0], 1'b0};
    assign uio_oe  = 8'b0011_1110;

    // `ena` is not used: TT holds it high whenever we are selected, and the
    // design has no power-down behaviour of its own. Tie it off explicitly so
    // the flow does not warn about an unused input.
    wire _unused = &{ena, uio_in[7:1], 1'b0};

endmodule
