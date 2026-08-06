// The bit-serial 2x2 banyan switch element — the tapeout target.
//
// FRAME FORMAT (maestro-ruled 8/6 11:13; JYH may override). Each serial line
// carries, MSB first:
//
//     cycle 0      ACTIVITY bit   1 = this line carries a packet this frame
//     cycle 1      this stage's DESTINATION bit
//     cycle 2..    payload, streamed transparently
//
// The activity bit is not decoration. Without it the element cannot tell an
// IDLE port from a port whose destination bit is 0 — which was a live routing
// bug in the previous version of this file, found by the compiler seat
// (8/6 10:52) by enumerating the element rather than reading it:
//
//     assign out0 = (sel0 == 1'b0) ? in0 : in1;    // WRONG
//
// With port 0 idle, sel0 stayed 0 and out0 took in0 unconditionally, so an
// active packet on in1 bound for out0 was SILENTLY DROPPED. One-sided: out0
// preferred in0 and out1 preferred in1, so only that corner failed, and both
// both-active cases routed correctly.
//
// Why `banyan_selfrouting` did not exclude it, which is the interesting part:
// `no_conflict` is `Set.InjOn` over `Set.Iio n` — it constrains the ACTIVE
// lines only. Idle ports are outside what the theorem says anything about, and
// "sources concentrated" is precisely what MAKES idle ports possible at
// interior stages. The theorem was true, the artifact was wrong, and nothing
// was violated.
//
// SELF-INITIALISATION. TinyTapeout power-gates unselected designs, so no flop
// state survives deselection, and the minimum reset pulse width is
// undocumented. This element therefore must not depend on a known reset state:
// every register is unconditionally reloaded from the wire at its own strobe,
// so an arbitrary power-up state is overwritten at the first frame. Reset is
// belt-and-braces here, not a correctness assumption — and that is a
// hypothesis of the D3.5 refinement, not a comment.
//
// TIMING ASSUMPTION, stated because D3.5 must carry it: the data path is
// TRANSPARENT (combinational in -> out), so this element's output is defined
// only from the cycle AFTER `sel_stb`. The header cycles are delivered to each
// stage in its own time slot by the fabric's strobe generator; a stage's
// output during its own header cycles is don't-care.

module bitserial_switch (
    input  wire clk,
    input  wire rst_n,
    input  wire act_stb,   // high for the cycle carrying the ACTIVITY bit
    input  wire sel_stb,   // high for the cycle carrying THIS stage's address bit
    input  wire in0,
    input  wire in1,
    output wire out0,
    output wire out1
);

    reg act0, act1, sel0, sel1;

    always @(posedge clk) begin
        if (!rst_n) begin
            act0 <= 1'b0;
            act1 <= 1'b0;
            sel0 <= 1'b0;
            sel1 <= 1'b0;
        end else begin
            if (act_stb) begin
                act0 <= in0;
                act1 <= in1;
            end
            if (sel_stb) begin
                sel0 <= in0;
                sel1 <= in1;
            end
        end
    end

    // Input i CLAIMS output j iff it is active and its address bit selects j.
    // Gating on activity is the whole fix: an idle input claims nothing.
    wire c00 = act0 & ~sel0;   // in0 -> out0
    wire c01 = act0 &  sel0;   // in0 -> out1
    wire c10 = act1 & ~sel1;   // in1 -> out0
    wire c11 = act1 &  sel1;   // in1 -> out1

    // An unclaimed output drives 0, so the activity bit seen downstream is 0
    // and idleness propagates correctly through the remaining stages.
    //
    // Under the no-conflict hypothesis at most one of {c00, c10} holds (and at
    // most one of {c01, c11}), so each OR is a clean two-way mux. That
    // hypothesis is exactly `banyan_selfrouting`'s conclusion, and it must be
    // VISIBLE in the D3.5 refinement statement even though no conflict-
    // resolution logic is needed: an FSM certificate that never exercises the
    // contended case while claiming to refine `line` is the sp1-lean failure
    // mode precisely.
    assign out0 = (c00 & in0) | (c10 & in1);
    assign out1 = (c01 & in0) | (c11 & in1);

endmodule
