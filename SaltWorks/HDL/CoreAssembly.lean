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

-- ⚠️ FILE-LEVEL, not `set_option … in` after a docstring: C4.lean:95-98 records that Lean
-- rejects the latter ("wants the docstring on a declaration"). Its note saved the rediscovery.
set_option maxHeartbeats 4000000

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

/-! ## THE OUTPUT MAP — what all 33 remaining obligations read positionally

`RegField c r` is about output bits `32r … 32r+31`; `PcField` about `1024 … 1055`. Both
read `core.outs` BY POSITION. ⛔ An off-by-one here would not fail loudly — it would make
all 32 `RegField`s false about the registers they NAME while each stayed a well-formed
statement, and the first symptom would be 32 unprovable goals with no sign which end was
wrong. So it is proved before any field is attempted. -/

/-- The register half of `core.outs` is exactly `regNext`'s outputs, embedded. -/
theorem core_outs_reg_half :
    (core.outs.take 1024) = instOuts regNext regNextSig offRegNext := by
  have hlen : (instOuts regNext regNextSig offRegNext).length = 1024 := by
    simp only [instOuts, List.length_map]; decide +kernel
  simp only [core, List.take_left' hlen]

/-- The pc half is exactly `pcAdd`'s outputs, embedded. -/
theorem core_outs_pc_half :
    (core.outs.drop 1024) = instOuts SaltWorks.Stack.Program.pcAdd pcAddSig offPc := by
  have hlen : (instOuts regNext regNextSig offRegNext).length = 1024 := by
    simp only [instOuts, List.length_map]; decide +kernel
  simp only [core, List.drop_left' hlen]

/-- ⭐⭐ **THE PER-REGISTER INDEX — register `r`'s bit `k` is at position `32r + k`.**
*This is what makes `RegField r` a statement about `rnOut 32 32 r k` rather than about an
opaque list position, and it is where a TRANSPOSED bank would show up.*

⚠️ *Proved by exhaustion over the 1,024 (r,k) pairs rather than by a `flatMap` indexing
lemma — `List.flatMap_eq_join_map` is not in this mathlib and the bounded shape makes the
brute route available. It is a decision procedure over a closed finite set, not a sample.* -/
theorem regNext_outs_index : ∀ r, r < 32 → ∀ k, k < 32 →
    regNext.outs.getD (32 * r + k) 0 = rnOut 32 32 r k := by
  decide +kernel

#audit_axioms core core_gate_count core_outs_length
#audit_axioms core_outs_reg_half core_outs_pc_half regNext_outs_index

end SaltWorks.HDL.CorePlace
