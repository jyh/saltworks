/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.CompileS
import Mathlib.Data.Fintype.Pigeonhole
import Mathlib.Data.Finite.Prod
import SaltWorks.Tactic.AuditAxioms

/-! # Row A's hypothesis F2 is FALSE for the landed types — MIG-3(a)

`docs/lang-design-v1.md` §2 rules ROW A with the conclusion as **function equality**,
`machRun code (encode s) = encode s'`, and carries in the statement the hypothesis

  **F2**  `Function.Injective encode`

where *"`encode` is the register-file embedding"*.

## What this file adds, and what it does NOT re-mint

⭐ **`CompileS` ALREADY EXHIBITS THE OTHER HALF, IN THE KERNEL — cited by NAME, not re-proved:**
`the_final_state_is_not_an_encoding` runs the witness and reads back a dirty scratch register
and a live `pc`, neither of which any `encode σ'` mentions. That is the *machine-state* reason
the conclusion cannot be an equality, and it is landed.

⛔ **THE REASON BELOW IS DIFFERENT AND SHARPER, AND IT IS ABOUT THE HYPOTHESIS RATHER THAN THE
CONCLUSION.** `State` is `Nat → BitVec 32` — an infinite type. `St` is a structure of four
finite fields (32 registers, a `pc`, eight memory words, a flag) — a finite type. **No function
from an infinite type to a finite type is injective.** So F2 is not merely unproved: it is
REFUTABLE, for *any* candidate `encode` whatsoever.

⇒ **ROW A AS RULED IS THEREFORE VACUOUS, NOT FALSE.** An implication with an unsatisfiable
hypothesis is trivially true, so a proof of Row A in its ruled form would certify nothing about
the compiler. That is a worse failure than an unproved row, because it *looks* dischargeable and
a discharge would be worthless.

⚠️ **AND THE CORPUS ALREADY MADE THE REPAIR, WHICH IS WHY THIS IS NOT AN INDICTMENT.**
`encodeOK` is a *relation* scoped to the live levels of the pool, and `regState` falls back to
`σ` above `poolSize` precisely because the machine cannot hold the rest. The landed shape is the
correct one; it is §2's ruled text that never caught up.

📌 **A THIRD, SEPARATE DEFECT IN THE SAME LINE, RECORDED NOT PROVED:** the name `encode` is
already taken in the corpus by `SaltWorks.ISA.encode : Instr → BitVec 32`, the *instruction*
encoder. §2 applies `encode` to a STATE. The two cannot be the same function.
-/

namespace SaltWorks.HDL.MIG3
open SaltWorks.ISA SaltWorks.HDL.TinyRustN0

/-- Mathlib's `Finite (Vector _ _)` instance is about `List.Vector`; `St` uses the CORE
`Vector`, which has none. Built here by indexing into `Fin n → α`. -/
instance instFiniteVector {α : Type} [Finite α] {n : Nat} : Finite (Vector α n) := by
  apply Finite.of_injective (fun (v : Vector α n) (i : Fin n) => v[i.val])
  intro a b h
  apply Vector.ext
  intro i hi
  exact congrFun h ⟨i, hi⟩

/-- `St` is finite: `regs`, `pc`, `mem` and `trapped` are all finite. -/
instance instFiniteSt : Finite St := by
  apply Finite.of_injective (fun s : St => (s.regs, s.pc, s.mem, s.trapped))
  intro a b h
  cases a; cases b
  simp only [Prod.mk.injEq] at h
  simp_all

/-- `State = Nat → BitVec 32` is infinite: the point-masses are pairwise distinct. -/
instance instInfiniteState : Infinite State :=
  Infinite.of_injective (fun n : Nat => (fun m => if m = n then (1 : BitVec 32) else 0)) (by
    intro a b h
    by_contra hne
    have hb := congrFun h b
    simp at hb
    exact hne hb.symm)

/-- ⛔ **MIG-3(a): F2 IS UNSATISFIABLE.** No state encoding is injective, so Row A's ruled
hypothesis `Function.Injective encode` cannot hold for ANY `encode : State → St`, and Row A
as ruled is VACUOUS. -/
theorem no_injective_state_encoding (f : State → St) : ¬ Function.Injective f := by
  intro hinj
  obtain ⟨a, b, hne, heq⟩ := Finite.exists_ne_map_eq_of_infinite f
  exact hne (hinj heq)


-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.MIG3.no_injective_state_encoding
end SaltWorks.HDL.MIG3
