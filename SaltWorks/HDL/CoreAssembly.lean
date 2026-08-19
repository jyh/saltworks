/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude

# THE ASSEMBLY — `core : Circ`, the subject C4 has never had.

Program.lean:2487 says C4 is "impossible today (`grep -rE "^(def|theorem|abbrev|noncomputable
def) (core|compile)\b"` over SaltWorks/ still returns nothing) — but the DECOMPOSITION that
turns C4 from a fresh proof into an assembly THE DAY ITS SUBJECT EXISTS."

Compose.lean's header says the same from the other side:
  "THE ASSEMBLY IS NO LONGER GATED ON THIS FILE … `core` is an iteration of exactly that step."
  "WHAT REMAINS IS NOT A LEMMA, IT IS A CONSTRUCTION: `core` itself — the wiring σ for each
   organ, and the `outs` list. NO NEW THEORY IS OWED."

CorePlace.lean has all sixteen σ's and all sixteen offsets, each with an `instOK` proof and a
chain-coverage theorem. So this file does the one thing nobody had done: WRITE IT DOWN.

⛔ **WHAT THIS IS AND IS NOT.** `c4Spec_iff_fieldwise` splits `C4Spec` into THIRTY-FOUR
obligations: the output count, thirty-two `RegField`s, and `PcField`. **This file discharges
ONE — the count — and supplies the SUBJECT the other thirty-three are about.** It is not C4,
it is not a witness, and it does not close R9/B2. *What it changes is that R9/B2's remaining
cost is now ENUMERABLE rather than unknown: thirty-three field proofs against a definite
circuit, each independent, each about thirty-two bits.*
-/
import SaltWorks.HDL.CorePlace

namespace SaltWorks.HDL.CorePlace
open SaltWorks.HDL

/-- ⭐⭐⭐ **THE COMPOSED CORE.** Sixteen organs, in the chain order `placedGateTotal`
enumerates, each embedded by `instGates` at the offset `CorePlace` proved it placeable at. -/
def core : Circ :=
  { nIn   := coreInWidth
  , gates := instGates tieCells id offTie
          ++ instGates decoder decoderSig off0
          ++ instGates immBCirc immBSig off1
          ++ instGates readTree readTreeRs1Sig off2
          ++ instGates readTree readTreeRs2Sig off3
          ++ instGates bitXor32 bitXor32Sig off4
          ++ instGates bitNot32 bitNot32Sig off5
          ++ instGates OperandB.obMux obSig offOb
          ++ instGates adder32 addSig offAdd
          ++ instGates adder32 subSig offSub
          ++ instGates sltCirc sltSig offSlt
          ++ instGates SelectCut32.sliceASelect selSig offSel
          ++ instGates EncoderE1.ruledEnc encSig offEnc
          ++ instGates regWrite regWriteSig offRw
          ++ instGates SaltWorks.Stack.Program.pcAdd pcAddSig offPc
          ++ instGates regNext regNextSig offRegNext
  , outs  := instOuts regNext regNextSig offRegNext
          ++ instOuts SaltWorks.Stack.Program.pcAdd pcAddSig offPc }

/-- The gate count is exactly the sum the chain invariant already accounts for. -/
theorem core_gate_count : core.gates.length = placedGateTotal := by
  simp only [core, placedGateTotal, instGates, List.length_append, List.length_map]

/-- ⭐⭐ **THE FIRST REAL `C4Spec` OBLIGATION: the output count.** *`c4Spec_iff_fieldwise`'s
first conjunct is `c.outs.length = stWidth`, and C4.lean records why it must be stated —
both sides of C4 are `List Bool` at ANY length, so the type system is silent about it.* -/
theorem core_outs_length : core.outs.length = stWidth := by
  simp only [core, instOuts, List.length_append, List.length_map]
  decide +kernel

#audit_axioms core core_gate_count core_outs_length

end SaltWorks.HDL.CorePlace
