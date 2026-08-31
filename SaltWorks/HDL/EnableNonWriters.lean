/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat (Q7 executor — enable-half, NEGATIVE arm)

# Q7 · the enable-half's NEGATIVE arm — the non-writers, swept

`DecoderTransport` proves the enable low on each non-writing class ONE CLASS AT A TIME
(`core_writes_nothing_on_BEQ`, `core_writes_nothing_on_SW`, `core_writes_nothing_on_garbage`).
Nothing yet says the general sentence, and nothing yet CASHES any of them into
`RegDatapathOK`'s body. This file does both:

```
core_enable_false_of_isa_nonwriter   ISA writes no register ⇒ EVERY enable is low   (uniform)
regDatapath_on_isa_nonwriter         ⇒ the two sides AGREE, every register, every bit
regDatapath_on_BEQ / _on_SW / _on_garbage    the three instances, named
```

⛔ **SCOPE.** `LW` and `SW` values are out of scope (Horn D — `decQ`'s memory is all-zero).
Nothing here needs a load or a store to COMPUTE anything: `SW` appears only as a class that
writes NO register, so its obligation is discharged by the HOLD arm, which is memory-free.
`LW` is NOT covered — it is a writer, and its VALUE is what Horn D exists for.
⛔ **CORRECTED 2026-08-29.** This line read *"and `regDatapathOK_is_false_on_LW_either_way`
stands"*. **THAT THEOREM WAS RETIRED THE SAME DAY** (council item (f), option ③, bus `28710859`,
commit `d7bb56a`): leg ① wired operand B through the placed immediate mux and the LW witness's
select bit flipped to the value the ISA demands. ⇒ **`RegDatapathOK` is OPEN — not proved and no
longer refuted** — so `LW` is uncovered by ABSENCE OF A PROOF, which is a weaker reason than the
one this line used to give, and the difference is what the next reader needs.
⚠️ *This sentence was missed by the retirement's own corpus sweep: the sweep grepped the FLAGSHIP
name and `C4Spec core`, and this line names only the LW dependent. A retraction reaches the
strings you thought to grep for.*

## ⚠️ THE FAILURE MODE THIS FILE IS BUILT AGAINST

A negative arm can pass for the wrong reason: if the `if`'s two branches happened to agree at
every point the statement is tested, the theorem would be TRUE with the enable wired EITHER
way, and would certify nothing about the enable. So the discrimination is proved, not argued —
`enable_high_mutant_is_false` below takes the SAME sentence at the SAME environment with the
enable forced HIGH and refutes it in the kernel, against the landed `SW x1,x2,4` witness
(`C4Refuted.ins0`), where `selOut 0` is `false` and the held bit of register 4 is `true`.
-/
import SaltWorks.HDL.C4Refuted

namespace SaltWorks.HDL.RegNextUniform.NonWriters

open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.HDL.RegNextUniform
open SaltWorks.Stack.Program

/-! ## 1 · The ISA-side predicate, and the uniform enable-low theorem -/

/-- **The ISA writes NO register on this word.** True on `BEQ`, on `SW`, and on every
undecodable word; false on all five writers (`writesReg` names an `rd` for each, `LW`
included — it is the over-approximation `IsaHold` warns about, and the negative direction
is the safe one). -/
def isaWritesNoReg (w : BitVec 32) : Prop :=
  ∀ i, decode w = some i → writesReg i = none

theorem beq_is_a_nonwriter (w : BitVec 32) (a b : Fin 32) (imm : BitVec 12)
    (h : decode w = some (.BEQ a b imm)) : isaWritesNoReg w := by
  intro i hi
  rw [h] at hi
  cases hi
  rfl

theorem sw_is_a_nonwriter (w : BitVec 32) (a b : Fin 32) (imm : BitVec 12)
    (h : decode w = some (.SW a b imm)) : isaWritesNoReg w := by
  intro i hi
  rw [h] at hi
  cases hi
  rfl

theorem garbage_is_a_nonwriter (w : BitVec 32) (h : decode w = none) : isaWritesNoReg w := by
  intro i hi
  rw [h] at hi
  exact absurd hi (by simp)

/-- ⭐⭐ **THE NEGATIVE ARM, UNIFORMLY: WHERE THE ISA WRITES NOTHING, EVERY ENABLE IS LOW.**
One sentence over the ISA's own write predicate, covering `BEQ`, `SW` and the undecodable
words at once — the three landed per-class theorems are now its instances rather than its
statement. The exhaustiveness is the whole content: the proof must dispose of all five
WRITING classes too, and it does so from `hnw`, not from the circuit. -/
theorem core_enable_false_of_isa_nonwriter (ins : Env) (k : Nat) (hk : k < 32)
    (hnw : isaWritesNoReg (seenWord ins)) :
    run ins core.gates (rwOut k) = false := by
  cases hd : decode (seenWord ins) with
  | none => exact core_writes_nothing_on_garbage ins k hk hd
  | some i =>
      have hn := hnw i hd
      cases i with
      | ADD rd a b   => exact absurd hn (by simp [writesReg])
      | ADDI rd a im => exact absurd hn (by simp [writesReg])
      | XOR rd a b   => exact absurd hn (by simp [writesReg])
      | SLT rd a b   => exact absurd hn (by simp [writesReg])
      | LW rd a im   => exact absurd hn (by simp [writesReg])
      | BEQ a b im   => exact core_writes_nothing_on_BEQ ins k hk a b im hd
      | SW a b im    => exact core_writes_nothing_on_SW ins k hk a b im hd

/-! ## 2 · The store case AGAIN, by a second and independent route

`core_writes_nothing_on_SW` reaches the answer through `weOf_eq_weSpec`, i.e. through
`regWrite_correct`'s 2048-point table read as an EQUATION. `regWrite_store_writes_nothing` is a
DIFFERENT landed kernel fact about the same organ — *"on a store every enable is false"*, taken
directly rather than via `weSpec`. Routing the store case through it gives two derivations that
share `core_rwOut_eq_weOf` and nothing downstream of it; they agree. -/

theorem weOf_length (rd : Nat) (a b c d e f : Bool) :
    (weOf rd a b c d e f).length = 32 := by
  simp [weOf, semB, regWrite_outs_len]

theorem getD_of_all_false (l : List Bool) (h : l.all (· == false) = true)
    (k : Nat) (hk : k < l.length) : l.getD k false = false := by
  rw [List.getD_eq_getElem _ _ hk]
  have hm := List.all_eq_true.mp h l[k] (List.getElem_mem hk)
  simpa using hm

/-- The five write flags are all `false` on a store — read off `ctrlSpec`'s `SW` row. -/
theorem sw_flags_low (ins : Env) (a b : Fin 32) (imm : BitVec 12)
    (h : decode (seenWord ins) = some (.SW a b imm)) :
    isADDOf ins = false ∧ isXOROf ins = false ∧ isSLTOf ins = false
      ∧ isADDIOf ins = false ∧ isLWOf ins = false := by
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · rw [isADDOf_spec ins];  simp [ctrlSpec, h]
  · rw [isXOROf_spec ins];  simp [ctrlSpec, h]
  · rw [isSLTOf_spec ins];  simp [ctrlSpec, h]
  · rw [isADDIOf_spec ins]; simp [ctrlSpec, h]
  · rw [isLWOf_spec ins];   simp [ctrlSpec, h]

/-- ⭐ **THE STORE CASE THROUGH THE ORGAN THEOREM.** Same conclusion as
`core_writes_nothing_on_SW`, reached through `regWrite_store_writes_nothing` instead of
through `weSpec` — a cross-check on the enable's negative arm at the store. -/
theorem core_enable_false_on_SW_via_organ (ins : Env) (k : Nat) (hk : k < 32)
    (a b : Fin 32) (imm : BitVec 12)
    (h : decode (seenWord ins) = some (.SW a b imm)) :
    run ins core.gates (rwOut k) = false := by
  obtain ⟨hA, hX, hS, hI, hL⟩ := sw_flags_low ins a b imm h
  rw [core_rwOut_eq_weOf ins k hk, lwWrOf_spec ins, hA, hX, hS, hI, hL]
  simp only [Bool.false_and]
  have hall := regWrite_store_writes_nothing
  have h1 := List.all_eq_true.mp hall (rdOf ins) (List.mem_range.mpr (rdOf_lt ins))
  have h2 := List.all_eq_true.mp h1 (isBEQOf ins) (by cases isBEQOf ins <;> simp)
  exact getD_of_all_false _ h2 k (by rw [weOf_length]; exact hk)

/-! ## 3 · Cashing the enable into `RegDatapathOK`'s body -/

/-- `regDatapath_hold_arm`'s second hypothesis, from the ISA-side predicate. -/
theorem hold_arm_hyp (ins : Env) (r : Fin 32) (hnw : isaWritesNoReg (seenWord ins)) :
    ∀ i, decode (seenWord ins) = some i → writesReg i ≠ some r := by
  intro i hi
  rw [hnw i hi]
  simp

/-- On a non-writing word the ISA's answer for EVERY register is the HELD bit. Memory-free:
`SW`'s memory effect and `BEQ`'s pc effect are both invisible to `regs`. -/
theorem isa_holds_of_nonwriter (ins : Env) (r : Fin 32) (k : Nat) (hk : k < 32)
    (hnw : isaWritesNoReg (seenWord ins)) :
    ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[r.val]).getLsbD k
      = ins (32 * r.val + k) := by
  rw [stepT_regs_of_ne (decQ ins) (seenWord ins) r (hold_arm_hyp ins r hnw),
      decQ_reg_bit ins r k hk]

/-- ⭐⭐⭐ **THE NEGATIVE ARM OF `RegDatapathOK`, CLOSED.** On any word the ISA answers with
no register write, the circuit and the ISA agree — **every register, every bit**, and with no
appeal to the ALU, the select bank, the immediate, the adder or the memory. -/
theorem regDatapath_on_isa_nonwriter (ins : Env) (r : Fin 32) (k : Nat) (hk : k < 32)
    (hnw : isaWritesNoReg (seenWord ins)) :
    (if run ins core.gates (rwOut r.val) then run ins core.gates (selOut k)
     else ins (32 * r.val + k))
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[r.val]).getLsbD k :=
  regDatapath_hold_arm ins r k hk
    (core_enable_false_of_isa_nonwriter ins r.val r.isLt hnw)
    (hold_arm_hyp ins r hnw)

/-- **BEQ — the `rwNotBEQ` term, cashed.** -/
theorem regDatapath_on_BEQ (ins : Env) (r : Fin 32) (k : Nat) (hk : k < 32)
    (a b : Fin 32) (imm : BitVec 12)
    (h : decode (seenWord ins) = some (.BEQ a b imm)) :
    (if run ins core.gates (rwOut r.val) then run ins core.gates (selOut k)
     else ins (32 * r.val + k))
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[r.val]).getLsbD k :=
  regDatapath_on_isa_nonwriter ins r k hk (beq_is_a_nonwriter _ a b imm h)

/-- **SW — the class the 08-19 repair removed from the enable, cashed.** -/
theorem regDatapath_on_SW (ins : Env) (r : Fin 32) (k : Nat) (hk : k < 32)
    (a b : Fin 32) (imm : BitVec 12)
    (h : decode (seenWord ins) = some (.SW a b imm)) :
    (if run ins core.gates (rwOut r.val) then run ins core.gates (selOut k)
     else ins (32 * r.val + k))
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[r.val]).getLsbD k :=
  regDatapath_on_isa_nonwriter ins r k hk (sw_is_a_nonwriter _ a b imm h)

/-- **The undecodable word — the ratified NOP-advance, cashed.** -/
theorem regDatapath_on_garbage (ins : Env) (r : Fin 32) (k : Nat) (hk : k < 32)
    (h : decode (seenWord ins) = none) :
    (if run ins core.gates (rwOut r.val) then run ins core.gates (selOut k)
     else ins (32 * r.val + k))
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[r.val]).getLsbD k :=
  regDatapath_on_isa_nonwriter ins r k hk (garbage_is_a_nonwriter _ h)

/-! ## 4 · ⛔ THE DISCRIMINATION CONTROL — would this BREAK if the enable were wired high?

The obligation's body with the enable made a PARAMETER. `RegDatapathOK` is exactly the
`en := run ins core.gates (rwOut r.val)` instantiation — `shape_is_the_flagship` proves that
by `Iff.rfl`, so what follows is a statement about the flagship's own sentence and not about
an adjacent one. -/

def obligationAt (ins : Env) (r : Fin 32) (k : Nat) (en : Bool) : Prop :=
  (if en then run ins core.gates (selOut k) else ins (32 * r.val + k))
    = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[r.val]).getLsbD k

theorem shape_is_the_flagship :
    RegDatapathOK ↔ ∀ (ins : Env) (r : Fin 32) (k : Nat), k < 32 →
      obligationAt ins r k (run ins core.gates (rwOut r.val)) := Iff.rfl

/-- The fixture: `C4Refuted.ins0` is `SW x1, x2, 4` with register 4's bit 0 HELD HIGH. -/
def r4 : Fin 32 := ⟨4, by decide⟩

theorem held4 : C4Refuted.ins0 (32 * r4.val + 0) = true := by
  have h := C4Refuted.held_ins0
  rw [C4Refuted.rd_ins0] at h
  exact h

/-- The select bank delivers `false` at bit 0 on this word — the landed packed evaluation
(`C4Refuted.bFull`, every one of `core`'s 10496 gates forced by the kernel). -/
theorem sel0_ins0 : run C4Refuted.ins0 core.gates (selOut 0) = false :=
  (runB_eq core.gates C4Refuted.s0 (selOut 0)).symm.trans
    (by rw [C4Refuted.selOut0_net]; exact C4Refuted.bFull)

/-- The ISA holds register 4 across the store, so the obligation's right-hand side is `true`
— **the opposite of what the select bank carries.** This is what makes the fixture able to
feel the mutation. -/
theorem isa_ins0_reg4 :
    ((SaltWorks.ISA.stepT (decQ C4Refuted.ins0) (seenWord C4Refuted.ins0)).regs[r4.val]).getLsbD 0
      = true := by
  rw [isa_holds_of_nonwriter C4Refuted.ins0 r4 0 (by decide)
        (sw_is_a_nonwriter _ 1 2 4 C4Refuted.dec_ins0)]
  exact held4

/-- The enable really is the LOW one at this point — the arm the theorems above take. -/
theorem enable_is_low_here : run C4Refuted.ins0 core.gates (rwOut r4.val) = false :=
  core_enable_false_of_isa_nonwriter C4Refuted.ins0 r4.val (by decide)
    (sw_is_a_nonwriter _ 1 2 4 C4Refuted.dec_ins0)

/-- ✅ **THE POSITIVE ARM AT THE FIXTURE** — the sentence this file proves, at this point. -/
theorem enable_low_holds_here : obligationAt C4Refuted.ins0 r4 0 false := by
  show (if false then run C4Refuted.ins0 core.gates (selOut 0)
        else C4Refuted.ins0 (32 * r4.val + 0)) = _
  rw [if_neg (by simp), held4, isa_ins0_reg4]

/-- ⛔⛔ **THE MUTANT: THE SAME SENTENCE WITH THE ENABLE WIRED HIGH IS FALSE.**

`enable_low_holds_here : obligationAt ins0 r4 0 false` and
`enable_high_mutant_is_false : ¬ obligationAt ins0 r4 0 true` are the same proposition at the
same environment, differing ONLY in the enable — so the negative arm above is not passing
because the two branches of the `if` happen to coincide. **`ins0`'s discriminating set is
non-empty**, and a core that write-enabled on a store would fail `regDatapath_on_SW` here. -/
theorem enable_high_mutant_is_false : ¬ obligationAt C4Refuted.ins0 r4 0 true := by
  show ¬ ((if true then run C4Refuted.ins0 core.gates (selOut 0)
           else C4Refuted.ins0 (32 * r4.val + 0)) = _)
  rw [if_pos rfl, sel0_ins0, isa_ins0_reg4]
  simp

/-- ⭐ **AND THE TWO ARMS DISAGREE, IN ONE STATEMENT.** -/
theorem the_enable_is_load_bearing :
    obligationAt C4Refuted.ins0 r4 0 false ∧ ¬ obligationAt C4Refuted.ins0 r4 0 true :=
  ⟨enable_low_holds_here, enable_high_mutant_is_false⟩

/-! ## 5 · A second discrimination check, class-shaped rather than point-shaped

The mutant above shows the `if` matters at one point. This shows the CLASS test matters: the
uniform theorem is FALSE if `isaWritesNoReg` is dropped, because `ADD` does enable a write. -/

theorem the_class_test_is_load_bearing :
    ¬ (∀ (ins : Env) (k : Nat), k < 32 → run ins core.gates (rwOut k) = false) := by
  intro h
  have hx := C4Refuted.ctl_enable
  rw [h C4Refuted.insC C4Refuted.r1.val C4Refuted.r1.isLt] at hx
  exact absurd hx (by simp)

/-! ## 6 · The mutant's cost, stated generally — one wire cannot be every register

⛔ **AND A BUILD-ENGINEERING WALL, RECORDED BECAUSE IT COST TWO RUNS.** A `BEQ` counterpart of
§4's fixture was attempted twice and ABANDONED, both times exceeding 600 s and ~6 GB RSS in
the build arm: first with a `C4Refuted`-style packed witness, then with a witness-free
`envWith s (encode (.BEQ a b imm))` block. The blow-up is **NARROWED, NOT PINNED**, and the
narrowing was done by RE-LANDING pieces one at a time rather than by an instrument: a capped
audit run (`--cap 4000`) died with `memory_exception … at 'interpreter'` on the *known-green*
content of this file too, so that instrument cannot separate the arms and was abandoned.

```
MEASURED   this file without the witness block        builds in seconds, EXIT=0
MEASURED   with it (two different versions)           each >600 s at ~6 GB RSS, killed
EXONERATED enable_high_forces_registers_to_agree      green below — was in BOTH failures
EXONERATED envWith / seenWord_envWith witnesses       green in §7 — were in the second failure
SUSPECT    decQ_envWith_eq + the `{s with …}.regs` rfl in the abandoned `beq_env_held`
SUSPECT    a concrete `St`/`Vector` literal under `decide +kernel`
SUSPECT    an `obligationAt … (run ins core.gates (rwOut …))` at a CLOSED `ins`
```

⇒ what is still owed is a BEQ *point* fixture (two registers differing at one bit), not any of
the reasoning. A successor should bisect the three suspects in the BUILD arm, not the audit arm.

⇒ What survives is the part that needs no environment at all, and it is the general form of
§4's point mutant. -/

/-- ⭐ **THE MUTANT'S COST, WITHOUT A SINGLE GATE OR A SINGLE WITNESS.** If the enable were
high on a non-writing word, the obligation at two registers would force ONE wire — `selOut k`
— to equal the held bit of BOTH. `enable_high_mutant_is_false` is this at a measured point;
this is why no point could have saved it. -/
theorem enable_high_forces_registers_to_agree (ins : Env)
    (hnw : isaWritesNoReg (seenWord ins)) (r r' : Fin 32) (k : Nat) (hk : k < 32)
    (h1 : obligationAt ins r k true) (h2 : obligationAt ins r' k true) :
    ins (32 * r.val + k) = ins (32 * r'.val + k) := by
  have e1 : run ins core.gates (selOut k)
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[r.val]).getLsbD k := h1
  have e2 : run ins core.gates (selOut k)
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[r'.val]).getLsbD k := h2
  rw [isa_holds_of_nonwriter ins r k hk hnw] at e1
  rw [isa_holds_of_nonwriter ins r' k hk hnw] at e2
  exact e1.symm.trans e2

/-- ⛔⛔ **THE ENABLE-HIGH MUTANT DIES WHEREVER TWO REGISTERS DISAGREE AT ONE BIT** — on any
non-writing word, for any two registers, with nothing evaluated. `C4Refuted.ins0` is a
concrete environment satisfying the hypothesis (register 4 bit 0 is high, register 0's is
not), so this is not a vacuous refutation. -/
theorem enable_high_mutant_dies_wherever_registers_differ (ins : Env)
    (hnw : isaWritesNoReg (seenWord ins)) (r r' : Fin 32) (k : Nat) (hk : k < 32)
    (hdiff : ins (32 * r.val + k) ≠ ins (32 * r'.val + k)) :
    ¬ (obligationAt ins r k true ∧ obligationAt ins r' k true) := by
  rintro ⟨h1, h2⟩
  exact hdiff (enable_high_forces_registers_to_agree ins hnw r r' k hk h1 h2)

/-! ## 7 · NON-VACUITY of the `BEQ` theorem — the smallest witness that survived

⚠️ **A HYPOTHESIS CAN BE VACUOUS.** `regDatapath_on_BEQ` would build even if no environment
ever presented a branch to `core`. The witness is quantified over the prior state `s`, so it
evaluates nothing: `seenWord_envWith` is a rewrite, not a measurement. This is the ONLY piece
of §6's abandoned witness block that was re-attempted, and it is deliberately the smallest —
no `St` literal, no `decQ_envWith_eq`, no packed `Nat`. -/

theorem beq_env_decodes (s : St) (a b : Fin 32) (imm : BitVec 12) :
    decode (seenWord (envWith s (encode (.BEQ a b imm)))) = some (.BEQ a b imm) := by
  have h : seenWord (envWith s (encode (Instr.BEQ a b imm))) = encode (Instr.BEQ a b imm) :=
    SaltWorks.Stack.Program.seenWord_envWith s _
  rw [h]; exact decode_encode _

/-- ⭐ **`regDatapath_on_BEQ` IS NOT VACUOUS** — here it is, at environments that really do
present a branch, for every prior state, every register and every bit. -/
theorem regDatapath_at_a_BEQ_environment (s : St) (a b : Fin 32) (imm : BitVec 12)
    (r : Fin 32) (k : Nat) (hk : k < 32) :
    (if run (envWith s (encode (.BEQ a b imm))) core.gates (rwOut r.val)
     then run (envWith s (encode (.BEQ a b imm))) core.gates (selOut k)
     else (envWith s (encode (.BEQ a b imm))) (32 * r.val + k))
      = ((SaltWorks.ISA.stepT (decQ (envWith s (encode (.BEQ a b imm))))
            (seenWord (envWith s (encode (.BEQ a b imm))))).regs[r.val]).getLsbD k :=
  regDatapath_on_BEQ _ r k hk a b imm (beq_env_decodes s a b imm)

/-- …and the enable is provably LOW at every one of them. -/
theorem beq_env_enable_low (s : St) (a b : Fin 32) (imm : BitVec 12) (k : Nat) (hk : k < 32) :
    run (envWith s (encode (.BEQ a b imm))) core.gates (rwOut k) = false :=
  core_enable_false_of_isa_nonwriter _ k hk
    (beq_is_a_nonwriter _ a b imm (beq_env_decodes s a b imm))

#audit_axioms isaWritesNoReg
#audit_axioms beq_is_a_nonwriter
#audit_axioms sw_is_a_nonwriter
#audit_axioms garbage_is_a_nonwriter
#audit_axioms core_enable_false_of_isa_nonwriter
#audit_axioms weOf_length
#audit_axioms getD_of_all_false
#audit_axioms sw_flags_low
#audit_axioms core_enable_false_on_SW_via_organ
#audit_axioms hold_arm_hyp
#audit_axioms regDatapath_on_isa_nonwriter
#audit_axioms regDatapath_on_BEQ
#audit_axioms regDatapath_on_SW
#audit_axioms regDatapath_on_garbage
#audit_axioms obligationAt
#audit_axioms shape_is_the_flagship
#audit_axioms r4
#audit_axioms held4
#audit_axioms sel0_ins0
#audit_axioms isa_ins0_reg4
#audit_axioms enable_is_low_here
#audit_axioms enable_low_holds_here
#audit_axioms enable_high_mutant_is_false
#audit_axioms the_enable_is_load_bearing
#audit_axioms the_class_test_is_load_bearing
#audit_axioms isa_holds_of_nonwriter
#audit_axioms enable_high_forces_registers_to_agree
#audit_axioms enable_high_mutant_dies_wherever_registers_differ
#audit_axioms beq_env_decodes
#audit_axioms regDatapath_at_a_BEQ_environment
#audit_axioms beq_env_enable_low

end SaltWorks.HDL.RegNextUniform.NonWriters
