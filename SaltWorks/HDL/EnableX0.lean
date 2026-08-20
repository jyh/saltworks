/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat (Q7 executor, x0 arm)

# Q7 — the ENABLE HALF, x0 ARM

The question posed: *what does `run ins core.gates (rwOut 0)` do versus what the ISA does to
`regs[0]`, under each non-memory class* — and if they disagree, exhibit the witness.

**THEY AGREE, AND THE AGREEMENT WAS ALREADY LANDED** — `core_rwOut0_false` (x0's enable is a
hardwired `.const false`) against `stepT_regs_zero` (the ISA never writes x0), joined in
`regDatapath_holds_at_zero`. That is `r = 0`, all seven classes, no defect.

So this file answers the *other* half of the same question, which was open: **not the register
x0, but the DESTINATION x0** — the instruction whose `rd` field is `00000`. Every positive
enable theorem in `DecoderTransport` (`core_writes_on_ADD/_XOR/_SLT/_ADDI`, `core_does_write_on_LW`)
carries the hypothesis `hne : ¬ (rdOf ins = 0)`, so *that* is the hole the x0 arm actually leaves,
and it is where a defect could have hidden: the write predicate is HIGH and the write must not
happen.

```
rdField_toNat            the enable's address IS decode's rd field   (bridge, at 7)
writesReg_is_rd_field    every writing ISA arm names that same field
core_rwOut_false_off_target   circuit: no register but rd is enabled
isa_off_target                ISA:     no register but rd is written
regDatapath_off_target   ⇒ THE OBLIGATION HOLDS AT EVERY NON-TARGET REGISTER
regDatapath_rd_zero      ⇒ rd = x0 ⇒ it holds at ALL THIRTY-TWO
regDatapathOK_of_on_target  ⇒ RegDatapathOK now rests on ONE REGISTER PER INPUT
on_target_case_is_false  ⇒ …and so does its known REFUTATION: the load witness is on target
```

⛔ **WHAT THIS IS NOT.** It proves no value. `selOut` is never evaluated here — the `if` is
killed on the false side every time — so the ALU, the immediate, the select and the encoder are
untouched, exactly as in `IsaHold`. What it buys is that the *residue* of `RegDatapathOK` is
`r.val = rdOf ins`, and nothing else.

⚠️ **IN SCOPE DESPITE THE MEMORY FENCE.** LW and SW appear in these statements and neither
needs to WORK: `SW` names no register at all, and `LW` with `rd = x0` writes through
`St.set 0 v`, which is `s`. Nothing here reads `mem`, so Horn D is not touched.

⚠️ **DUPLICATION, DECLARED.** `rdField_toNat` is `Bridge3`'s script at offset 7 and is the same
statement as `rdOf_is_decode_field` in the concurrently-running `ScratchQ7writersEx.lean`
(the positive arm of the same queue item). Two executors needed the same brick; the seat should
land ONE copy. Mine sits in a nested `Q7x0` namespace so the two scratch modules cannot clash.

*Not C4, not a witness, does not close R9/B2.*
-/
import SaltWorks.HDL.DecoderTransport
import SaltWorks.HDL.Bridge3
import SaltWorks.HDL.C4Refuted

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

set_option maxHeartbeats 4000000
set_option maxRecDepth 8000

namespace X0

/-! ## 1. The bridge — the enable's address IS `decode`'s `rd` field

`Bridge3` did this for `rs1` (offset 15) and `rs2` (offset 20). The enable needs it at 7.
`core_rd_is_the_instruction` already says the five wires are primary inputs; this says the
NUMBER they carry is the field `decode` slices, which is what lets an ISA hypothesis and a
circuit hypothesis meet. -/

theorem rdField_toNat (ins : Env) :
    ((seenWord ins).extractLsb' 7 5).toNat = rdOf ins := by
  have hb : ∀ j, j < 5 → ((seenWord ins).extractLsb' 7 5).getLsbD j
      = (rdOf ins).testBit j := by
    intro j hj
    rw [BitVec.getLsbD_extractLsb', seenWord_bit ins (7 + j) (by omega),
        rdOf_testBit ins j hj]
    simp [hj]
  refine Nat.eq_of_testBit_eq (fun j => ?_)
  by_cases hj : j < 5
  · exact hb j hj
  · have h1 : ((seenWord ins).extractLsb' 7 5).toNat < 32 := by
      have := ((seenWord ins).extractLsb' 7 5).isLt
      simpa using this
    have h2 : rdOf ins < 32 := rdOf_lt ins
    have hp : (32 : Nat) ≤ 2 ^ j := by
      calc (32 : Nat) = 2 ^ 5 := by norm_num
        _ ≤ 2 ^ j := Nat.pow_le_pow_right (by norm_num) (by omega)
    rw [Nat.testBit_eq_false_of_lt (by omega), Nat.testBit_eq_false_of_lt (by omega)]

#audit_axioms rdField_toNat

/-! ## 2. The ISA side — every writing arm names that same field

`writesReg` is `IsaHold`'s over-approximation, and this is stated over ALL SEVEN classes at
once rather than four times: `decode` computes `rd` in ONE `let`, so the fact is about the
decoder's shape, not about any instruction. `BEQ` and `SW` are covered vacuously — they
return `none` and the hypothesis `writesReg i = some rd` is unsatisfiable for them. -/

theorem writesReg_is_rd_field (w : BitVec 32) (i : Instr) (h : decode w = some i)
    (rd : Fin 32) (hw : writesReg i = some rd) : rd = toReg (w.extractLsb' 7 5) := by
  simp only [decode, Bool.and_eq_true, decide_eq_true_eq] at h
  cases i with
  | ADD rd' a b =>
      have hr : rd' = rd := by simpa [writesReg] using hw
      subst hr; split_ifs at h <;> simp_all
  | ADDI rd' a im =>
      have hr : rd' = rd := by simpa [writesReg] using hw
      subst hr; split_ifs at h <;> simp_all
  | XOR rd' a b =>
      have hr : rd' = rd := by simpa [writesReg] using hw
      subst hr; split_ifs at h <;> simp_all
  | SLT rd' a b =>
      have hr : rd' = rd := by simpa [writesReg] using hw
      subst hr; split_ifs at h <;> simp_all
  | LW rd' a im =>
      have hr : rd' = rd := by simpa [writesReg] using hw
      subst hr; split_ifs at h <;> simp_all
  | BEQ a b im => simp [writesReg] at hw
  | SW a b im => simp [writesReg] at hw

#audit_axioms writesReg_is_rd_field

/-- **THE ISA HOLDS EVERY REGISTER THE `rd` FIELD DOES NOT NAME** — in the exact shape
`regDatapath_hold_arm` consumes. -/
theorem isa_off_target (ins : Env) (r : Fin 32) (hne : r.val ≠ rdOf ins) :
    ∀ i, decode (seenWord ins) = some i → writesReg i ≠ some r := by
  intro i hi hcon
  refine hne ?_
  rw [writesReg_is_rd_field (seenWord ins) i hi r hcon]
  exact rdField_toNat ins

#audit_axioms isa_off_target

/-! ## 3. The circuit side — no register but `rd` is enabled

Straight out of `core_rwOut_spec`: the enable carries `(rdOf ins == k)` as a conjunct, so a
register the instruction does not name cannot be enabled *whatever the decoder says*. Neither
`writesRegOf` nor `isBEQOf` is unfolded here, which is the point — this half needs no decoder
correctness at all. -/

theorem core_rwOut_false_off_target (ins : Env) (r : Fin 32) (hne : r.val ≠ rdOf ins) :
    run ins core.gates (rwOut r.val) = false := by
  have hb : (rdOf ins == r.val) = false := by
    simp only [beq_eq_false_iff_ne, ne_eq]
    exact fun hh => hne hh.symm
  rw [core_rwOut_spec ins r.val r.isLt, hb]
  simp

#audit_axioms core_rwOut_false_off_target

/-! ## 4. ⭐⭐ THE OBLIGATION HOLDS AT EVERY NON-TARGET REGISTER -/

/-- ⭐⭐ **`RegDatapathOK`'s equation, at every register the instruction does not name.**
Thirty-one of the thirty-two registers, for EVERY input, discharged with no ALU, no select,
no immediate and no adder — `selOut` is never evaluated, because the `if` is killed on the
false side each time. -/
theorem regDatapath_off_target (ins : Env) (r : Fin 32) (k : Nat) (hk : k < 32)
    (hne : r.val ≠ rdOf ins) :
    (if run ins core.gates (rwOut r.val) then run ins core.gates (selOut k)
     else ins (32 * r.val + k))
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[r.val]).getLsbD k :=
  regDatapath_hold_arm ins r k hk (core_rwOut_false_off_target ins r hne)
    (isa_off_target ins r hne)

#audit_axioms regDatapath_off_target

/-! ## 5. ⭐⭐⭐ THE x0 DESTINATION — ALL THIRTY-TWO REGISTERS, ALL SEVEN CLASSES

This is the hole every positive enable theorem in `DecoderTransport` leaves open by hypothesis
(`hne : ¬ (rdOf ins = 0)`). The two sides agree, and they agree for DIFFERENT reasons on the
two halves of the register file, which is why it needed saying:

* `r ≠ 0`: the circuit's `(rdOf ins == r.val)` conjunct is false, and the ISA's `rd` is a
  different register.
* `r = 0`: the circuit's `!(k == 0)` MASK is false — a second, independent kill — and the ISA
  writes through `St.set 0 v`, which is the identity.

⭐ *The second row is the one a real machine gets wrong.* `regWrite` output 0 being a
`.const false` and `weSpec`'s `!(k == 0)` mask are two separate guards, and this says the ISA
needs neither: `St.set 0 v = s` already. -/

theorem core_rwOut_false_of_rd_zero (ins : Env) (h0 : rdOf ins = 0) (k : Nat) (hk : k < 32) :
    run ins core.gates (rwOut k) = false := by
  by_cases hk0 : k = 0
  · subst hk0; exact core_rwOut0_false ins
  · exact core_rwOut_false_off_target ins ⟨k, hk⟩ (by show k ≠ rdOf ins; rw [h0]; exact hk0)

#audit_axioms core_rwOut_false_of_rd_zero

theorem isa_regs_hold_of_rd_zero (ins : Env) (h0 : rdOf ins = 0) (r : Fin 32) :
    (SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[r.val] = ((decQ ins).regs[r.val]) := by
  by_cases hr : r.val = 0
  · have hr0 : r = 0 := Fin.ext hr
    subst hr0
    exact SaltWorks.Stack.Program.stepT_regs_zero _ _
  · exact stepT_regs_of_ne (decQ ins) (seenWord ins) r (isa_off_target ins r (by omega))

#audit_axioms isa_regs_hold_of_rd_zero

/-- ⭐⭐⭐ **THE x0-DESTINATION FRAGMENT OF `RegDatapathOK`, CLOSED.** When the instruction's
`rd` field is `00000`, the circuit and the ISA agree about **every one of the thirty-two
registers**, on **every class** — `ADD`, `ADDI`, `XOR`, `SLT`, `BEQ`, `LW`, `SW`, and an
undecodable word. **No disagreement; nothing to refute.**

⚠️ `LW`/`SW` are inside this statement and neither needs to WORK: `SW` names no register, and
`LW` with `rd = x0` writes through `St.set 0 v = s`. **Nothing here reads `mem`**, so the
memory horn is not touched. -/
theorem regDatapath_rd_zero (ins : Env) (h0 : rdOf ins = 0) (r : Fin 32) (k : Nat) (hk : k < 32) :
    (if run ins core.gates (rwOut r.val) then run ins core.gates (selOut k)
     else ins (32 * r.val + k))
      = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[r.val]).getLsbD k := by
  rw [core_rwOut_false_of_rd_zero ins h0 r.val r.isLt, if_neg (by simp),
      isa_regs_hold_of_rd_zero ins h0 r, decQ_reg_bit ins r k hk]

#audit_axioms regDatapath_rd_zero

/-! ## 6. ⭐⭐⭐ THE RESIDUE — one register per input

Putting §4 beside `regDatapath_holds_at_zero` leaves exactly one open case. -/

/-- ⭐⭐⭐ **`RegDatapathOK` NOW RESTS ON THE ON-TARGET REGISTER ALONE.** Everything off-target
is discharged; what is owed is the single register `r.val = rdOf ins`, and only there does the
value half — the ALU, the immediate, the select — have to be right.

⛔ **AND THE RESIDUE IS THE EXPENSIVE ONE.** This is a narrowing of the obligation, not
progress on the datapath: the one register left is precisely the one whose `selOut` must be
evaluated. Said plainly so nobody reads a 31/32 as 97% done. -/
theorem regDatapathOK_of_on_target
    (h : ∀ (ins : Env) (r : Fin 32) (k : Nat), k < 32 → r.val = rdOf ins →
      (if run ins core.gates (rwOut r.val) then run ins core.gates (selOut k)
       else ins (32 * r.val + k))
        = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[r.val]).getLsbD k) :
    RegDatapathOK := by
  intro ins r k hk
  by_cases hr : r.val = rdOf ins
  · exact h ins r k hk hr
  · exact regDatapath_off_target ins r k hk hr

#audit_axioms regDatapathOK_of_on_target

/-- ⛔⛔ **AND THEREFORE THE RESIDUE IS WHERE THE REFUTATION LIVES.** `RegDatapathOK` is already
FALSE — `C4Refuted.regDatapathOK_is_false_on_LW_either_way`, the load witness. Contraposing the
theorem above, its hypothesis must be false too, so **every counterexample to `RegDatapathOK`,
present or future, sits at `r.val = rdOf ins`.** The off-target thirty-one cannot host one.

⭐ *This is the honest reading of §4–§6.* Not *"97% done"* — the fraction is meaningless, since
the residue is exactly the case that needs the value half. What it says is that **the whole
defect is confined to the register the instruction names**, which is a statement about WHERE to
look, and it is the only thing §4–§6 buy. -/
theorem on_target_case_is_false :
    ¬ (∀ (ins : Env) (r : Fin 32) (k : Nat), k < 32 → r.val = rdOf ins →
      (if run ins core.gates (rwOut r.val) then run ins core.gates (selOut k)
       else ins (32 * r.val + k))
        = ((SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).regs[r.val]).getLsbD k) :=
  fun h => SaltWorks.HDL.C4Refuted.regDatapathOK_is_false_on_LW_either_way
    (regDatapathOK_of_on_target h)

#audit_axioms on_target_case_is_false

/-- **AND THE LANDED WITNESS OBEYS IT** — stated as a theorem rather than as prose, because a
citation is a measurement. `C4Refuted`'s `LW` refutation names register `x1`, and `x1` is the
`rd` field of the word its environment presents: the witness is ON TARGET, inside the residue,
exactly where `on_target_case_is_false` predicts it must be. -/
theorem c4refuted_lw_witness_is_on_target :
    rdOf SaltWorks.HDL.C4Refuted.insL = SaltWorks.HDL.C4Refuted.r1.val := by decide +kernel

#audit_axioms c4refuted_lw_witness_is_on_target

/-! ## 7. THE FRAGMENT IS NOT VACUOUS, AND THE FIXTURE CAN FEEL A MUTANT

⛔ **A hypothesis can be true, scoped and unsatisfiable on its own traffic.** `rdOf ins = 0` is
satisfied by garbage words, and a fragment covering only garbage would prove nothing about the
machine. Worse, a fixture on which BOTH arms of the `if` return the same bit cannot tell a
correct enable from an enable stuck high — it would pass either way.

⭐ **SO THE WITNESS IS BUILT TO FAIL IF THE ENABLE WERE WRONG.** `ADD x0, x1, x2` with
`x1 = x2 = 1` **and `x0` HOLDING 1** — the layout trap `CorePlace`:76 names, where net `0` in an
arbitrary `Env` is unconstrained and x0-reads-zero is enforced only at the READ port:

```
run insA core.gates (selOut 0)  = false     the ALU's 1 + 1 = 2, bit 0
insA 0                          = true      x0's HELD bit 0
```

**The two arms disagree**, so the obligation at this point is decided entirely by the enable, and
an enable stuck high would make it FALSE. It is true, and `regDatapath_rd_zero` is what makes it
true. -/

/-- `ADD x0, x1, x2` — a decodable, register-WRITING class whose destination is x0. -/
def wA : BitVec 32 := SaltWorks.ISA.encode (Instr.ADD 0 1 2)

/-- `x0 = 1`, `x1 = 1`, `x2 = 1`, pc `0`, and the word on the instruction nets.
⚠️ **`x0` IS DELIBERATELY NONZERO** — the state the RTL cannot express and this model can. -/
def sA : Nat := 2 ^ 0 ||| 2 ^ 32 ||| 2 ^ 64 ||| (wA.toNat * 2 ^ 1056)

def insA : Env := fun n => sA.testBit n

theorem seen_insA : seenWord insA = wA := by decide +kernel

theorem dec_insA : decode (seenWord insA) = some (Instr.ADD 0 1 2) := by
  rw [seen_insA]; exact decode_encode _

/-- **THE WITNESS IS IN THE FRAGMENT.** -/
theorem rdOf_insA : rdOf insA = 0 := by decide +kernel

/-- **THE LAYOUT TRAP, CONCRETE: `x0` HOLDS A ONE.** -/
theorem x0_is_nonzero : insA 0 = true := by decide +kernel

/-- **THE WRITE PREDICATE IS HIGH** — the fragment is not being carried by a dead decoder.
`ADD` raises `isADD`, so `weSpec`'s first conjunct is `true` and only the x0 masks stop the
write. -/
theorem writesRegOf_insA : writesRegOf insA = true := by
  rw [writesRegOf, isADDOf_spec, isXOROf_spec, isSLTOf_spec, isADDIOf_spec, isLWOf_spec,
      seen_insA]
  simp [ctrlSpec, wA, decode_encode]

/-- **THE `then` ARM: the ALU's `1 + 1 = 2`, whose bit 0 is `false`.** -/
theorem sel0_insA : run insA core.gates (selOut 0) = false :=
  (runB_eq core.gates sA (selOut 0)).symm.trans (by decide +kernel)

/-- ⭐ **THE FIXTURE CAN FEEL A MUTANT: THE TWO ARMS OF THE `if` DISAGREE.** An enable stuck
high would make the obligation FALSE at this point, so the witness is not passing by accident. -/
theorem branches_disagree_insA : run insA core.gates (selOut 0) ≠ insA 0 := by
  rw [sel0_insA, x0_is_nonzero]; simp

/-- **THE ISA SIDE — `x0` KEEPS ITS ONE**, computed rather than evaluated: `stepT_regs_zero`
against the held bit. -/
theorem isa_insA : ((SaltWorks.ISA.stepT (decQ insA) (seenWord insA)).regs[0]).getLsbD 0
    = true := by
  rw [SaltWorks.Stack.Program.stepT_regs_zero, decQ_reg0_bit insA 0 (by omega)]
  exact x0_is_nonzero

/-- ⭐⭐ **THE WITNESS, DECIDED BY `regDatapath_rd_zero` AND NOT BY HAND.** -/
theorem addA_sides_agree :
    (if run insA core.gates (rwOut (0 : Fin 32).val) then run insA core.gates (selOut 0)
     else insA (32 * (0 : Fin 32).val + 0))
      = ((SaltWorks.ISA.stepT (decQ insA) (seenWord insA)).regs[(0 : Fin 32).val]).getLsbD 0 :=
  regDatapath_rd_zero insA rdOf_insA 0 0 (by omega)

/-- ⭐ **AND THE CONTROL IN ONE STATEMENT: WRITE PREDICATE HIGH, EVERY ENABLE LOW.** -/
theorem insA_is_discriminating :
    writesRegOf insA = true
      ∧ (∀ k, k < 32 → run insA core.gates (rwOut k) = false)
      ∧ run insA core.gates (selOut 0) ≠ insA 0 :=
  ⟨writesRegOf_insA, fun k hk => core_rwOut_false_of_rd_zero _ rdOf_insA k hk,
   branches_disagree_insA⟩

#audit_axioms seen_insA
#audit_axioms dec_insA
#audit_axioms rdOf_insA
#audit_axioms x0_is_nonzero
#audit_axioms writesRegOf_insA
#audit_axioms sel0_insA
#audit_axioms branches_disagree_insA
#audit_axioms isa_insA
#audit_axioms addA_sides_agree
#audit_axioms insA_is_discriminating

end X0
end SaltWorks.HDL.RegNextUniform
