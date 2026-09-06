`timescale 1ns/1ps
// ============================================================================
// sof_protocol_check — THE BINDING FORM OF THE HOST-SIDE `sof` RULE.
//
// Ratified as the immediate mitigation by evidence (saltworks lead) 2026-09-06
// 06:23:40, on silicon's reachability measurement (`5cd96147`). It exists because
// a protocol rule that lives in a bus post or a README is a SENTENCE, not a
// mitigation: nothing fails when it is broken. This module fails.
//
// ── THE RULE ────────────────────────────────────────────────────────────────
//   A host may assert `sof` ONLY while the adapter is in a FETCH loop whose
//   RESIDENT INSTRUCTION IS NOT A MEMORY INSTRUCTION.
//
//   violation  <=>  sof && !(kind == T_FETCH && req == 0)
//
// ── WHY THIS SHAPE, AND WHY IT IS DELIBERATELY CONSERVATIVE ─────────────────
// Measured (`run_sof_window_census.sh`), the hazard window is the first THREE
// cycles of the fetch loop following a completed memory instruction; PHASE 3 of
// that loop is SAFE. This rule forbids phase 3 too, and that is on purpose:
//   phase 3 is safe ONLY because the instruction bypass (ratified 08/18 for an
//   UNRELATED defect) happens to put a freshly assembled word in front of the
//   decode. A protocol rule whose safety rests on a repair landed for another
//   reason ROTS SILENTLY THE DAY THAT REPAIR IS TOUCHED, and nothing would
//   connect the two. ⇒ THE RULE IS KEYED ON THE PROPERTY IT NEEDS (no memory
//   instruction resident), NEVER ON THE CYCLE THAT HAPPENS TO SURVIVE.
// It also forbids `sof` mid-transaction (kind == T_LOAD/T_STORE), which is a
// milder but real defect: a realign there reframes a transaction in flight and
// takes L5 red. One rule covers both.
//
// ⚠️ SCOPE: this constrains the HOST. It does NOT repair busadapt8 — the
//    AMENDMENT 2 repair remains an open two-signature row. This removes the
//    REACHABILITY of the defect, not the defect.
// ============================================================================
module sof_protocol_check(clk, rst_n, sof, kind, phase, req, violations, first_viol_phase);
    input        clk, rst_n, sof, req;
    input  [1:0] kind, phase;
    output reg [31:0] violations;
    output reg [1:0]  first_viol_phase;

    localparam T_FETCH = 2'b01;

    // The permission, stated positively: a fetch loop with nothing memory-shaped resident.
    wire permitted = (kind == T_FETCH) && (req == 1'b0);

    reg seen;
    always @(posedge clk) begin
        if (!rst_n) begin violations <= 32'd0; seen <= 1'b0; first_viol_phase <= 2'd0; end
        else if (sof && !permitted) begin
            violations <= violations + 32'd1;
            if (!seen) begin seen <= 1'b1; first_viol_phase <= phase; end
            // A violation is REPORTED, never suppressed: the checker must not also
            // be the thing that hides the traffic it is judging.
            $display("    SOF-PROTOCOL VIOLATION #%0d @%0t  kind=%b phase=%0d req=%b",
                     violations + 32'd1, $time, kind, phase, req);
        end
    end
endmodule
