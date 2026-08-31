/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# Do the 32 `RegField`s share a schema?

`c4Spec_iff_fieldwise` splits `C4Spec core` into 34 obligations: the output count (landed,
`core_outs_length`), thirty-two `RegField`s, and `PcField`. The helm asked the question that
decides how the remaining 33 are priced — **is there one general lemma plus 32 cheap
instantiations, or 32 independent grinds?**

**ANSWER: A SCHEMA EXISTS, and the useful half of the answer is that it INVERTS the cost.**
`r` enters the register datapath in exactly two places, and neither is expensive; the
register-INDEPENDENT half is the whole ALU/decode result path, and that is the campaign.

⛔ **WHAT THIS FILE DOES NOT DO.** It discharges no `RegField`. It proves the *wiring* is
uniform — which is what makes a general lemma possible — not that the wiring is *correct*.
Not C4, not a witness, does not close R9/B2.
-/
import SaltWorks.HDL.CoreAssembly

set_option maxHeartbeats 1000000

namespace SaltWorks.HDL.CorePlace
open SaltWorks.HDL

/-- ⭐⭐⭐ **THE SCHEMA, STATED AND PROVED. `regNextSig`'s three banks are each UNIFORM in the
register index, and `r` enters through EXACTLY TWO PLACES.**

```
we   bank   input r        ↦ rwOut r            -- a LOOKUP, uniform in r
res  bank   input 32+k     ↦ selOut k           -- SHARED by every register: NO r AT ALL
cur  bank   input 64+32r+k ↦ 32r+k              -- the state, a SHIFT, uniform in r
```
⇒ ***`RegField core r` can depend on `r` ONLY through `rwOut r` and the state offset `32r+k`.
Nothing else in the register datapath sees `r`.*** -/
theorem regNextSig_banks_are_uniform (r k : Nat) (hr : r < 32) (hk : k < 32) :
    regNextSig r = rwOut r
      ∧ regNextSig (32 + k) = selOut k
      ∧ regNextSig (64 + (32 * r + k)) = 32 * r + k := by
  refine ⟨?_, ?_, ?_⟩
  · simp only [regNextSig, if_pos hr]
  · have h1 : ¬ (32 + k < 32) := Nat.not_lt.mpr (Nat.le_add_right 32 k)
    have h2 : 32 + k < 64 := by omega
    simp only [regNextSig, if_neg h1, if_pos h2]
    congr 1
    exact Nat.add_sub_cancel_left 32 k
  · have h1 : ¬ (64 + (32 * r + k) < 32) := Nat.not_lt.mpr (by omega)
    have h2 : ¬ (64 + (32 * r + k) < 64) := Nat.not_lt.mpr (Nat.le_add_right 64 _)
    simp only [regNextSig, if_neg h1, if_neg h2]
    -- ⚠️ `Nat.add_sub_cancel_left`, NOT omega: the subtraction sits at `Net` and omega's
    -- preprocessing drops it (this seat's `omega-net-typed-equations`, hit TWICE today).
    exact Nat.add_sub_cancel_left 64 (32 * r + k)

/-- ⭐ **THE RESULT BANK CARRIES NO `r` AT ALL** — the written value is computed ONCE and
broadcast to every register. *This is the half that makes the schema worth having: 32
registers SHARE one result datapath, so a `RegField` proof re-uses the select's correctness
instead of re-deriving it thirty-two times.* -/
theorem res_bank_is_register_independent (k : Nat) (hk : k < 32) :
    regNextSig (32 + k) = selOut k := by
  -- ⚠️ `hk` IS REQUIRED and I first wrote this without it: for k ≥ 32 the bank boundary
  -- moves and `32 + k < 64` is simply FALSE. The theorem was unprovable as first stated,
  -- which is the honest reason it failed rather than a tactic problem.
  have h1 : ¬ (32 + k < 32) := Nat.not_lt.mpr (Nat.le_add_right 32 k)
  have h2 : 32 + k < 64 := by omega
  simp only [regNextSig, if_neg h1, if_pos h2]
  congr 1
  exact Nat.add_sub_cancel_left 32 k

#audit_axioms regNextSig_banks_are_uniform res_bank_is_register_independent

/-! ### What the retire change will touch — measured, not argued -/

/-- ⭐⭐ **`regWrite` HAS NO RETIRE PORT, AND THIS IS THE NUMBER THAT SAYS SO.** Its seven
inputs are `rd[0..4]`, `decOut 5` and `decOut 4` (`regWriteSig`) — *all seven are decode
bits.* `weSpec rd valid isBEQ` likewise takes no stall or retire parameter.

⇒ ***A retire-gated write cannot be expressed by rewiring: item 10's hardware change must
WIDEN this interface.*** And since `rwOut r` is the ONLY register-dependent half of the
schema above, the consequence is sharp and worth the Captain's attention:

* the **shared** half (`selOut k` = the result datapath, register-independent, the expensive
  one) is **untouched** by the retire change and can be proved now;
* the **per-register** half (`rwOut r`, the cheap one) is **exactly where retire must enter**,
  so a `RegField` proved against today's `regWrite` is DATED — the `R9IdentityBridge` lesson
  about undated claims, arriving a second time at a different file.

⛔⛔ **THE INTERFACE HAS NOW WIDENED — FOR A DIFFERENT REASON (2026-08-19) — WHICH CHANGES THIS
ARGUMENT'S BASELINE, NOT ITS CONCLUSION.** The `SW` enable repair took `regWrite.nIn` from 7 to
11: port 5 became `isADD` and 7…10 carry `isXOR/isSLT/isADDI/isLW`, because `valid` meant
*decodes* and let every store write a register. **None of the eleven is a retire net** — five
`rd` bits, six decode flags — so *"a retire-gated write must WIDEN this interface"* still holds,
and the widening it predicted has now happened once for someone else's reason. *A retire change
no longer gets to treat the widening itself as the hard part.* -/
theorem regWrite_has_no_retire_input : regWrite.nIn = 11 := by decide +kernel

#audit_axioms regWrite_has_no_retire_input

/-! ### The core's primary inputs are stable — closing the executor's LIMIT 2 -/

/-- **Every gate in `core` writes a net at or above `coreInWidth`** — nineteen blocks (R9a added the trap gate), each
bounded below by its own offset, and every offset at or above `offTie = coreInWidth`. -/
theorem core_gate_out_ge : ∀ g ∈ core.gates, coreInWidth ≤ g.out := by
  have key : ∀ (c : Circ) (σ : Net → Net) (off : Nat), c.ssa = true → coreInWidth ≤ off →
      ∀ g ∈ instGates c σ off, coreInWidth ≤ g.out :=
    fun c σ off hssa hoff g hg =>
      Nat.le_trans hoff (instGates_out_range c σ off hssa g hg).1
  intro g hg
  -- ⚠️ TWO shape traps, both silent until they aren't. `simp only [core]` unfolds PAST the
  -- append into concrete gate terms; and `++` is LEFT-associated, so `mem_append` peels the
  -- LAST organ first, not the first. Hence: one definitional peel for `regNext`, then flatten
  -- the remaining fifteen with `or_assoc` to get a right-nested disjunction `rcases` can read.
  rcases List.mem_append.mp hg with hg | h
  · simp only [List.mem_append, or_assoc] at hg
    rcases hg with h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h|h
    · exact key _ _ _ tieCells_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
    · exact key _ _ _ decoder_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
    · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
    · exact key _ _ _ readTree_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
    · exact key _ _ _ readTree_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
    · exact key _ _ _ bitXor32_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
    · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
    · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
    · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
    · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
    · exact key _ _ _ adder32_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
    · exact key _ _ _ adder32_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
    · exact key _ _ _ sltCirc_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
    · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
    · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
    · exact key _ _ _ lwWrCirc_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
    · exact key _ _ _ regWrite_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
    · exact key _ _ _ SaltWorks.Stack.Program.pcAdd_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ regNext_ssa (by first | (simp only [offRegNext, offPc, offRw, offLwWr, offEnc, offSel, offSlt, offSub, offAdd, offOb, offImmMux, offSelOr, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h

/-- ⭐⭐ **A PRIMARY INPUT READS THE SAME IN `core` AS IN THE INPUT VALUATION.** This is the
executor's declared LIMIT 2 on `ScratchRegNextUniform.lean`, discharged: it reported that
reducing `run ins core.gates (32r+k)` to `ins (32r+k)` *"needs a gate-out-range lemma over
all sixteen blocks WHICH DOES NOT EXIST YET."* It exists now. -/
theorem core_input_stable (ins : Env) (n : Net) (hn : n < coreInWidth) :
    run ins core.gates n = ins n :=
  run_of_unwritten ins _ n (fun g hg hEq =>
    absurd (hEq ▸ core_gate_out_ge g hg) (Nat.not_le.mpr hn))

/-- **The register state bits, specifically** — `32r + k ≤ 1023 < 1088 = coreInWidth`. -/
theorem core_state_bit_stable (ins : Env) (r k : Nat) (hr : r < 32) (hk : k < 32) :
    run ins core.gates (32 * r + k) = ins (32 * r + k) := by
  refine core_input_stable ins _ ?_
  simp only [coreInWidth, stWidth, Net]
  omega

#audit_axioms core_gate_out_ge core_input_stable core_state_bit_stable

end SaltWorks.HDL.CorePlace
