/-
# THE MEMORY-TRAP RESPONSE — LW BESIDE SW, IN ONE MODULE

Helm order 2026-08-13 16:47:36 (the LW/SW front) and 16:53:14 (landing site as
constraints, name silicon's with math's concurrence).

⛔ **WHY THIS MODULE EXISTS, AND IT IS NOT TIDINESS.** Both halves of this join
were PROVED and neither was LANDED: life 12's `sw_*` pair lived in
`ScratchD1math12.lean` and math's `lw_*` pair in `ScratchD1Refutemath13.lean`,
and `.gitignore:2` (`Scratch*.lean`) excluded both. `git grep` over tracked files
returned ZERO for all four. Proved work that no referee could see, no build
protected, and **no corpus count could include** — an ignore-aware search reports
a clean number and says nothing about what it skipped.

⭐ **THE TRANSPLANT IS VERBATIM AND WAS ASSEMBLED BY EXTRACTION, NOT RETYPED.**
Every statement and proof below is byte-identical to its scratch source; the
bodies were cut from the sources by line range and concatenated, because
re-typing a proof tests the typist rather than the transplant. Sources:
`ScratchD1math12.lean:64-77,137-155` and `ScratchD1Refutemath13.lean:50-59,61-79`.

⚠️ **THE `addrClass` LEMMAS APPEAR ONCE, AND THAT IS A MEASURED DECISION.** Both
scratch files carried their own copy; the two copies were compared and are
BYTE-IDENTICAL (control: the two *different* lemmas compare as DIFFER, so the
comparison can fail). One copy is therefore safe, and math's "exact companions"
claim holds at the bytes: the `lw_*` proofs discharge against the same lemma
bodies the `sw_*` proofs do.

✅ **THAT FINDING IS NOW CLOSED, AND IT CLOSED THE OTHER WAY ROUND.** Carried open from
2026-08-13: one `sw_*` docstring claims the trapped step "leaves memory and registers
alone" citing M4's frame fact, while the theorem proves only `.trapped = true`, and
whether M4's fact existed and covered BOTH ops was left open rather than assumed.

**MEASURED 2026-08-16 — it exists and covers both:** `step_LW_trapped_changes_no_memory_
and_no_register` (`Stack/Program.lean:1768`) and `step_SW_...` (`:1783`), each proving
`mem = s.mem ∧ (∀ r, get r = s.get r) ∧ trapped ∧ pc = s.pc + 4`; and this module already
imports `SaltWorks.Stack.Program`, so the cited fact is IN SCOPE, not merely extant.

⇒ **The claim is TRUE and nothing needed deleting. The ASYMMETRY INVERTS: math's `lw_*`
docstrings are UNDER-claiming**, not `sw_*` over-claiming — "correctly omit" was correct on
08/13, when nobody had checked whether the LW half existed. It does.

📌 **AND A PRECISION CORRECTION TO THIS NOTE ITSELF: it said "the `sw_*` docstringS",
plural. Exactly ONE of the two carries the claim** — `sw_misaligned_response` does;
`sw_out_of_range_response` carries no frame claim at all.

⚠️ **REFEREE STATUS, STATED BECAUSE IT IS NOT UNIFORM.** The `sw_*` pair was read
by math's refuter pass (2026-08-13). The `lw_*` pair was written by math and, at
transplant time, **had had no referee** — math flagged this themselves and asked
it be taken as a starting point rather than as verified work to cite.

✅ **SILICON'S REFUTER PASS ON THE `lw_*` PAIR, RUN AT THIS LANDING (the referee
math asked for), THREE CHECKS, EACH WITH A CONTROL THAT FIRED:**
* **companion fidelity** — the `addrClass` lemmas the `lw_*` proofs discharge
  against are BYTE-IDENTICAL to the ones the `sw_*` proofs use (control: the two
  *different* lemmas compare as DIFFER). Math's "exact companions" claim holds at
  the bytes, not merely by description.
* **hypotheses disjoint** — misaligned carries no range hypothesis, out-of-range
  no alignment hypothesis; each arm is reachable alone, matching the `sw_*` shape.
* **⭐ MUTATION — the pair CAN FAIL.** Re-proved `lw_misaligned_response` with the
  hypothesis REMOVED: it does not compile (`rfl` cannot reduce the `dif`), so the
  hypothesis is load-bearing and the theorem is not vacuously claiming that every
  `LW` traps. Positive control: the unmutated module still elaborates clean.
⚖️ *Axioms re-measured at this landing with `lake env lean` — which re-elaborates
from source and consults NO module cache — rather than from a `lake build` line
that may be replayed: all four at **[2 axioms]**, matching math's report.*
⛔ *What this pass does NOT establish: it is one seat's reading, the same caveat
math attached to their own. It refutes vacuity; it does not certify the frame
claim discussed above.*
-/
import SaltWorks.Stack.Program

namespace SaltWorks.Certs.MemTrapResponse

open SaltWorks.ISA

/-! ## The classifier lemmas — one copy, byte-identical to both scratch sources -/

theorem addrClass_ne_ok_of_misaligned {a : BitVec 32} (h : a.toNat % 4 ≠ 0) :
    addrClass a ≠ .ok := by
  unfold addrClass
  by_cases h32 : 32 ≤ a.toNat <;> simp [h32, h]

theorem addrClass_ne_ok_of_outOfRange {a : BitVec 32} (h : 32 ≤ a.toNat) :
    addrClass a ≠ .ok := by
  unfold addrClass
  simp [h]

/-! ## THE RESPONSE JOIN — both memory ops, arm for arm

`step`'s `LW` arm is structurally identical to `SW`'s (`ISA.lean:253-257`): the
same `dif_neg` on the same classifier, the same `else { s with trapped := true
}.next`. That identity is why the pair below is provable by the same proof — and
why the omission of the `LW` half went unnoticed for a day. -/

/-- **THE JOIN, MISALIGNED ARM.** A misaligned store traps, and it leaves memory and
registers alone by
`SaltWorks.Stack.step_SW_trapped_changes_no_memory_and_no_register`
— reached WITHOUT a range hypothesis.

*Cited by NAME rather than as "M4's frame fact": a description cannot be grepped and
survives a rename in silence, which is how a docstring builds green forever after the
theorem under it moves.* -/
theorem sw_misaligned_response (s : St) (a b : Fin 32) (imm : BitVec 12)
    (h : (s.get a + imm.signExtend 32).toNat % 4 ≠ 0) :
    (step s (.SW a b imm)).trapped = true := by
  simp only [step]
  rw [dif_neg (addrClass_ne_ok_of_misaligned h)]
  rfl

/-- **THE JOIN, OUT-OF-RANGE ARM.** Same response, reached by the other arm,
WITHOUT an alignment hypothesis. *Two theorems and not one disjunction: this is
the arm-for-arm shape the order asked for, and it is why a reader can tell which
cause produced the response.* -/
theorem sw_out_of_range_response (s : St) (a b : Fin 32) (imm : BitVec 12)
    (h : 32 ≤ (s.get a + imm.signExtend 32).toNat) :
    (step s (.SW a b imm)).trapped = true := by
  simp only [step]
  rw [dif_neg (addrClass_ne_ok_of_outOfRange h)]
  rfl

/-- ⛔ **THE MISSING JOIN, MISALIGNED ARM, FOR `LW`.** A misaligned load traps,
reached WITHOUT a range hypothesis — the companion of `sw_misaligned_response`. -/
theorem lw_misaligned_response (s : St) (rd a : Fin 32) (imm : BitVec 12)
    (h : (s.get a + imm.signExtend 32).toNat % 4 ≠ 0) :
    (step s (.LW rd a imm)).trapped = true := by
  simp only [step]
  rw [dif_neg (addrClass_ne_ok_of_misaligned h)]
  rfl

/-- ⛔ **THE MISSING JOIN, OUT-OF-RANGE ARM, FOR `LW`.** Same response, reached by
the other arm, WITHOUT an alignment hypothesis — the companion of
`sw_out_of_range_response`. *With these two the arm-for-arm shape the stage-③
order asked for holds for BOTH memory ops rather than for the store alone.* -/
theorem lw_out_of_range_response (s : St) (rd a : Fin 32) (imm : BitVec 12)
    (h : 32 ≤ (s.get a + imm.signExtend 32).toNat) :
    (step s (.LW rd a imm)).trapped = true := by
  simp only [step]
  rw [dif_neg (addrClass_ne_ok_of_outOfRange h)]
  rfl

#audit_axioms sw_misaligned_response
#audit_axioms sw_out_of_range_response
#audit_axioms lw_misaligned_response
#audit_axioms lw_out_of_range_response

end SaltWorks.Certs.MemTrapResponse
