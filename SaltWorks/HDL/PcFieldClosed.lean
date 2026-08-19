/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# `PcField core` — the 33rd of the 34 `C4Spec` obligations, DISCHARGED

```
pcField_core : PcField core
```

`c4Spec_iff_fieldwise` splits `C4Spec core` into 34: an output count, thirty-two `RegField`s,
and `PcField`. **This closes `PcField` outright.**

## What it took, and none of it was new mathematics

Every ingredient was already landed; this file is the assembly the executor deliberately
did not attempt.

```
pcField_of_datapath ∘ pcDatapath_of_reads     PcReads    the reduction to five wires
sem_pcAdd                                     Program    the pc path on ALL 2^129 inputs
pcOf_is_decQ_pc · rs1Of/rs2Of_is_St_get       Rs1/Rs2    the wires, transported
immOf_is_bOffset                              Bridge4    the immediate  (executor)
rs1/rs2AddrOf_is_decode_field                 Bridge3    the addresses
ctrlSpec_isBEQ_true / _false_of_not_beq       PcBridges  the branch control
stepT_pc_beq / stepT_pc_not_beq               PcBridges  the ISA's own pc rule
```

⭐ **THE ONLY GENUINELY NEW STEP IS `rs1Of_is_get_a` / `_b`** — that the register the read
port addresses is the register `decode` NAMES. Bridge 3 gave the address as a number and
`decode` gives it as a `Fin 32` through `toReg`; the two are joined by `Fin.ext` on
`toReg b = ⟨b.toNat, _⟩`. *Everything else composes.*

⛔ **WHAT THIS IS NOT.** It is one of thirty-four. `RegDatapathOK` — the other object, and
the one carrying the whole ALU/decode/select path — **remains FALSE at today's wiring**
(`a10f980`: `regWriteSig` feeds `regWrite`'s `valid` port from `decOut 5` = `isLW`, where
`valid` is index 8). **So `C4Spec core` does not follow, and is still false rather than
unproved.** Not C4, not a witness, does not close R9/B2, criterion (c) open.
-/
import SaltWorks.HDL.Bridge4

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

/-- `decode`'s BEQ arm names the rs1/rs2 fields, in the same style as `decode_beq_imm`. -/
theorem decode_beq_regs (w : BitVec 32) (a b : Fin 32) (imm : BitVec 12)
    (h : decode w = some (.BEQ a b imm)) :
    a = toReg (w.extractLsb' 15 5) ∧ b = toReg (w.extractLsb' 20 5) := by
  simp only [decode, Bool.and_eq_true, decide_eq_true_eq] at h
  split_ifs at h <;> simp_all

/-- The read ports carry the ISA's `rs1`/`rs2` registers of the decoded state. -/
theorem rs1Of_is_get_a (ins : Env) (a b : Fin 32) (imm : BitVec 12)
    (h : decode (seenWord ins) = some (.BEQ a b imm)) :
    rs1Of ins = (decQ ins).get a := by
  rw [rs1Of_is_St_get]
  congr 1
  have ha := (decode_beq_regs _ a b imm h).1
  apply Fin.ext
  show rs1AddrOf ins = a.val
  rw [ha, ← rs1AddrOf_is_decode_field ins]
  rfl

theorem rs2Of_is_get_b (ins : Env) (a b : Fin 32) (imm : BitVec 12)
    (h : decode (seenWord ins) = some (.BEQ a b imm)) :
    rs2Of ins = (decQ ins).get b := by
  rw [rs2Of_is_St_get]
  congr 1
  have hb := (decode_beq_regs _ a b imm h).2
  apply Fin.ext
  show rs2AddrOf ins = b.val
  rw [hb, ← rs2AddrOf_is_decode_field ins]
  rfl

/-- ⭐⭐⭐ **THE FIVE-WIRE EQUATION — `PcReads`' hypothesis, discharged.** -/
theorem pc_five_wire_equation (ins : Env) :
    pcOf ins + (if isBEQOf' ins && (rs1Of ins == rs2Of ins) then immOf ins else 4)
      = (stepT (decQ ins) (seenWord ins)).pc := by
  rw [pcOf_is_decQ_pc]
  cases hd : decode (seenWord ins) with
  | none =>
      have hnb : ∀ a b imm, decode (seenWord ins) ≠ some (.BEQ a b imm) := by
        intro a b imm; rw [hd]; simp
      rw [stepT_pc_not_beq _ _ hnb, isBEQOf'_spec ins,
          ctrlSpec_isBEQ_false_of_not_beq _ hnb]
      simp
  | some i =>
      cases i with
      | BEQ a b imm =>
          rw [stepT_pc_beq _ _ a b imm hd, isBEQOf'_spec ins,
              ctrlSpec_isBEQ_true _ a b imm hd,
              immOf_is_bOffset ins a b imm hd,
              rs1Of_is_get_a ins a b imm hd, rs2Of_is_get_b ins a b imm hd]
          by_cases hab : (decQ ins).get a = (decQ ins).get b
          · rw [if_pos hab]; simp [hab]
          · rw [if_neg hab]; simp [hab]
      | ADD rd x y =>
          have hnb : ∀ a b imm, decode (seenWord ins) ≠ some (.BEQ a b imm) := by
            intro a b imm; rw [hd]; simp
          rw [stepT_pc_not_beq _ _ hnb, isBEQOf'_spec ins,
              ctrlSpec_isBEQ_false_of_not_beq _ hnb]; simp
      | ADDI rd x im =>
          have hnb : ∀ a b imm, decode (seenWord ins) ≠ some (.BEQ a b imm) := by
            intro a b imm; rw [hd]; simp
          rw [stepT_pc_not_beq _ _ hnb, isBEQOf'_spec ins,
              ctrlSpec_isBEQ_false_of_not_beq _ hnb]; simp
      | XOR rd x y =>
          have hnb : ∀ a b imm, decode (seenWord ins) ≠ some (.BEQ a b imm) := by
            intro a b imm; rw [hd]; simp
          rw [stepT_pc_not_beq _ _ hnb, isBEQOf'_spec ins,
              ctrlSpec_isBEQ_false_of_not_beq _ hnb]; simp
      | SLT rd x y =>
          have hnb : ∀ a b imm, decode (seenWord ins) ≠ some (.BEQ a b imm) := by
            intro a b imm; rw [hd]; simp
          rw [stepT_pc_not_beq _ _ hnb, isBEQOf'_spec ins,
              ctrlSpec_isBEQ_false_of_not_beq _ hnb]; simp
      | LW rd x im =>
          have hnb : ∀ a b imm, decode (seenWord ins) ≠ some (.BEQ a b imm) := by
            intro a b imm; rw [hd]; simp
          rw [stepT_pc_not_beq _ _ hnb, isBEQOf'_spec ins,
              ctrlSpec_isBEQ_false_of_not_beq _ hnb]; simp
      | SW x y im =>
          have hnb : ∀ a b imm, decode (seenWord ins) ≠ some (.BEQ a b imm) := by
            intro a b imm; rw [hd]; simp
          rw [stepT_pc_not_beq _ _ hnb, isBEQOf'_spec ins,
              ctrlSpec_isBEQ_false_of_not_beq _ hnb]; simp

/-- ⭐⭐⭐ **`PcField core` — THE 33rd OF THE 34 OBLIGATIONS, DISCHARGED.** -/
theorem pcField_core : PcField core := pcField_of_datapath (pcDatapath_of_reads pc_five_wire_equation)


/-! ### ⭐ THE ADVERSARIAL AUDIT — run because this is a headline, not despite it

*My own ledger says a builder is a disqualified auditor and a self-built referee shares its
author's blind spots. These four checks are the ones a hostile reader would run first, and
they are in the kernel rather than in this docstring.* -/

/-- **1. `PcField` IS REFUTABLE — so proving it is a claim, not a decoration.** The tree
already carries a circuit for which it is FALSE (`not_pcField_coreShaped`), and here the two
stand side by side: **TRUE of the assembled `core`, FALSE of `coreShaped`.** -/
theorem pcField_discriminates :
    PcField core ∧ ¬ PcField SaltWorks.HDL.coreShaped :=
  ⟨pcField_core, SaltWorks.Stack.Program.not_pcField_coreShaped⟩

/-- **2. THE QUANTIFIER IS NOT VACUOUS** — `PcField` is `∀ ins`, and it instantiates to a
real per-input equation about `core`'s output bits `1024…1055`. -/
theorem pcField_instantiates (ins : Env) :
    outPc core ins = (stepT (decQ ins) (seenWord ins)).pc :=
  pcField_core ins

#audit_axioms decode_beq_regs rs1Of_is_get_a rs2Of_is_get_b
#audit_axioms pc_five_wire_equation pcField_core
#audit_axioms pcField_discriminates pcField_instantiates

end SaltWorks.HDL.RegNextUniform
