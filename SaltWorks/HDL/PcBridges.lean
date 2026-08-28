/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# Two of the four pc bridges

`Wire5` ended the placement story for the pc half and left four SEMANTIC obligations. Two
of them are here, and both were cheaper than the framing I gave them.

```
ctrlSpec_isBEQ_true / _false_of_not_beq : ctrlSpec's bit 4 is TRUE exactly on a BEQ word
stepT_pc_beq                            : on BEQ, the ISA pc IS the branch rule
stepT_pc_not_beq                        : on everything else — INCLUDING an undecodable
                                          word — the pc advances by 4
```

⚠️ **A CORRECTION TO MY OWN FRAMING, worth more than the lemmas.** I closed `Wire5` saying
the remainder "changes kind" and was "different work" that deserved a fresh start. **The
first bridge landed on the first attempt and the second took two.** *Different in kind did
not mean harder, and I had let a real observation about the KIND of work imply something
about its COST that I had not measured.*

⛔ **THE TWO THAT REMAIN ARE THE FIELD-EXTRACTION ONES** — `rs1`/`rs2` address fields equal
`decode`'s `a` and `b`, and `immOf = bOffset (decoded imm)`. Those need `decode`'s bit
slicing to line up with the net indices this seat used (`instrNet (15 + j)`,
`instrNet (20 + j)`, `immB`), which is a genuinely different question from either bridge
here. *Priced, not attempted.*

*Not C4, not a witness, does not close R9/B2.*
-/
import SaltWorks.HDL.Wire5

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

/-- ⭐ **BRIDGE 1: `ctrlSpec`'s bit 4 is TRUE exactly on a `BEQ` word.** -/
theorem ctrlSpec_isBEQ_true (w : BitVec 32) (a b : Fin 32) (imm : BitVec 12)
    (h : decode w = some (.BEQ a b imm)) : (ctrlSpec w).getD 4 false = true := by
  simp [ctrlSpec, h]

/-- …and FALSE on every other decodable word, and on an undecodable one. -/
theorem ctrlSpec_isBEQ_false_of_not_beq (w : BitVec 32)
    (h : ∀ a b imm, decode w ≠ some (.BEQ a b imm)) :
    (ctrlSpec w).getD 4 false = false := by
  cases hd : decode w with
  | none => simp [ctrlSpec, hd]
  | some i =>
      cases i with
      | ADD rd x y => simp [ctrlSpec, hd]
      | ADDI rd x im => simp [ctrlSpec, hd]
      | XOR rd x y => simp [ctrlSpec, hd]
      | SLT rd x y => simp [ctrlSpec, hd]
      | BEQ x y im => exact absurd hd (h x y im)
      | LW rd x im => simp [ctrlSpec, hd]
      | SW x y im => simp [ctrlSpec, hd]

/-! ### Bridge 2 — the ISA's own pc rule -/

theorem St_next_pc (s : St) : s.next.pc = s.pc + 4 := rfl

/-- A register write does not move the pc. *Needed because every arithmetic case of `step`
is `(s.set rd v).next`, so the pc claim has to see through the write.* -/
theorem St_set_pc (s : St) (r : Fin 32) (v : BitVec 32) : (s.set r v).pc = s.pc := by
  simp only [St.set]; split <;> rfl

/-- ⭐ **BRIDGE 2a: on a `BEQ` word the ISA's pc is the branch rule.** -/
theorem stepT_pc_beq (s : St) (w : BitVec 32) (a b : Fin 32) (imm : BitVec 12)
    (h : decode w = some (.BEQ a b imm)) :
    (stepT s w).pc = (if s.get a = s.get b then s.pc + bOffset imm else s.pc + 4) := by
  rw [stepT_compat s w (step s (.BEQ a b imm)) (by simp [stepW, h])]
  simp only [step]
  split
  · rfl
  · exact St_next_pc s

/-- ⭐ **BRIDGE 2b: on everything else — including an undecodable word — the pc advances
by 4.** *That covers the NOP-advance the v1 semantics rules for garbage.* -/
theorem stepT_pc_not_beq (s : St) (w : BitVec 32)
    (h : ∀ a b imm, decode w ≠ some (.BEQ a b imm)) :
    (stepT s w).pc = s.pc + 4 := by
  cases hd : decode w with
  | none => rw [stepT_undecodable s w hd]; exact St_next_pc s
  | some i =>
      rw [stepT_compat s w (step s i) (by simp [stepW, hd])]
      cases i with
      | ADD rd x y => simp only [step, St_next_pc, St_set_pc]
      | ADDI rd x im => simp only [step, St_next_pc, St_set_pc]
      | XOR rd x y => simp only [step, St_next_pc, St_set_pc]
      | SLT rd x y => simp only [step, St_next_pc, St_set_pc]
      | BEQ x y im => exact absurd hd (h x y im)
      | LW rd x im => simp only [step]; split <;> simp only [St_next_pc, St_set_pc]
      | SW x y im => simp only [step]; split <;> simp only [St_next_pc, St_set_pc]

#audit_axioms ctrlSpec_isBEQ_true ctrlSpec_isBEQ_false_of_not_beq
#audit_axioms stepT_pc_beq stepT_pc_not_beq


-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.RegNextUniform.St_next_pc SaltWorks.HDL.RegNextUniform.St_set_pc
end SaltWorks.HDL.RegNextUniform
