import SaltWorks.HDL.ISA

/-!
# THE REGISTER MAP — A2's inhabitance control, landed BEFORE anything consumes it

Block ① §A **A2** amends the drafted reg-map hypothesis and attaches a
precondition to it in the same breath:

> `Function.Injective (reg : Nat → Fin 32)` is pigeonhole-UNSATISFIABLE; every
> theorem carrying `RegOk` as drafted would be vacuously green. **AMENDED:**
> `reg : Fin poolSize → Fin 32` (poolSize = 15, RTL-mirrored) … **an
> INHABITANCE control (exhibit one `reg`) lands before any theorem consumes it.**

This file is that control, and its negative twin. Nothing here is used yet —
that is the point: **A2 says the control lands FIRST, so it lands first.**

`compileE` needs this because the ISA has **no load/store**: a source `var`
lives in a state slot and the machine has only registers, so compilation of a
variable is a move from the register that slot is mapped to. The map is
therefore an input to L0, not an L1 detail.
-/

namespace SaltWorks.RegMap

open SaltWorks.ISA

/-- RTL-mirrored pool size, per A2. -/
def poolSize : Nat := 15

/-- The finite-domain register map A2 replaces the `Nat`-domain one with. -/
abbrev RegMap := Fin poolSize → Fin 32

/-! ⛔ **THE VACUITY BOMB IS NOT RE-PROVED HERE, AND THAT IS DELIBERATE.**
`¬ ∃ f : Nat → Fin 32, Function.Injective f` is pigeonhole and needs
`Mathlib.Data.Finite.Basic`, whose olean **is not in this build** (`bad import`,
measured — the module appears in the corpus's import list but does not resolve).
It is the REFUTERS' finding and A2 rests on it; re-proving it is not what A2
asks for. **What A2 asks for is the INHABITANCE control, and that needs no
mathlib at all.** *Left as a named gap rather than an unremarked omission; if a
later rung wants it, the missing dependency is the thing to fix first.* -/

/-- A concrete map: pool slot `i` ↦ register `i + 1`. **Register `x0` is
deliberately skipped** — it reads as zero unconditionally (`St.get`'s own law),
so it can hold no value and must not be an allocation target. -/
def regCanonical : RegMap := fun i => ⟨i.val + 1, by have h := i.isLt; unfold poolSize at h; omega⟩

/-- ⭐ **THE INHABITANCE CONTROL A2 REQUIRES: the amended hypothesis IS
satisfiable, exhibited.** Without this the amendment would have traded one
vacuity for an unchecked assumption. -/
theorem regCanonical_injective : Function.Injective regCanonical := by
  intro a b h
  have : a.val + 1 = b.val + 1 := congrArg Fin.val h
  exact Fin.ext (by omega)

/-- …and it never allocates `x0`, which is the property that makes it usable
rather than merely injective. -/
theorem regCanonical_ne_zero (i : Fin poolSize) : regCanonical i ≠ 0 := by
  intro h
  have : (regCanonical i).val = 0 := congrArg Fin.val h
  simp [regCanonical] at this

#audit_axioms poolSize RegMap
#audit_axioms regCanonical
#audit_axioms regCanonical_injective
#audit_axioms regCanonical_ne_zero

end SaltWorks.RegMap
