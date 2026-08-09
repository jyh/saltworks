// `Banyan.element` — THE ORACLE ROW of the BB-switch account, in RTL so it can
// be priced in cells and µm² beside `ceCcore` and `cell88core`.
//
// TRANSCRIBED FROM THE KERNEL OBJECT, and the correspondence is checkable by
// inspection in ten seconds — which is the only reason I am willing to put a
// synthesized number for it in a Captain-facing pack:
//
//   Banyan.lean:56  def pick (s₀ s₁ a b base) :=
//                     [ ⟨base,     .and s₀ a⟩
//                     , ⟨base + 1, .and s₁ b⟩
//                     , ⟨base + 2, .or base (base + 1)⟩ ]
//   Banyan.lean:95  def element (s₀lo s₁lo s₀hi s₁hi a b base) :=
//                     pick s₀lo s₁lo a b base ++ pick s₀hi s₁hi a b (base + 3)
//
//   ⇒ SIX gates: four AND, two OR. Zero state. Exactly the two lines below.
//
// ⚠️ WHAT THIS IS NOT. This is a TRANSCRIPTION BY MY HAND, not a proof of
// correspondence. `emitS` is the fleet's verified path from `Circ` to Verilog and
// it was not used here; nothing checks this file against `Banyan.element` except
// a reader's eyes. It exists to answer ONE question — what does the oracle cost
// in standard cells — and it must not be cited as the verified element.
//
// ⚠️ AND IT IS NOT A MUX (compiler's §2, load-bearing): the structure is a
// CLAIM-GATED OR. Transparency holds only under `act0 ∧ act1 ∧ sel0 ≠ sel1`; with
// both claims true the outputs MERGE rather than select, and with neither the
// output is `false`, which is the idle convention. The hypothesis does the
// selecting, not the circuit — so a reader who sees "2:1 mux" here has read it
// wrong, and the gate count is small for exactly that reason.
`default_nettype none

module banyan_element (
    input  wire s0lo,   // claim: port 0 routes to the LOW output
    input  wire s1lo,   // claim: port 1 routes to the LOW output
    input  wire s0hi,   // claim: port 0 routes to the HIGH output
    input  wire s1hi,   // claim: port 1 routes to the HIGH output
    input  wire a,      // port 0 data
    input  wire b,      // port 1 data
    output wire ylo,    // LOW output
    output wire yhi     // HIGH output
);
    // pick s0lo s1lo a b  — gates base, base+1, base+2
    assign ylo = (s0lo & a) | (s1lo & b);
    // pick s0hi s1hi a b  — gates base+3, base+4, base+5
    assign yhi = (s0hi & a) | (s1hi & b);
endmodule

`default_nettype wire
