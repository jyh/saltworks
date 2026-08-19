/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat


# The decoder transport — the defect it exposed, and the repair that closed it

This file lifts the decoder's landed correctness (`sem_decoder_eq_ctrlSpec`) onto the
placement, so `core`'s control reads become `ctrlSpec` bits of the instruction word. It was
written to close the enable arm; what it actually did first was expose a mis-wiring. Both
halves are recorded here because **the discharge record is what stops the work being
redone** — and because the identification control at the foot of this file exists only
because the defect got past everything else.

## ✅ REPAIRED 2026-08-19 (`2813add`) — the history, in past tense

`CorePlace.regWriteSig` used to feed `regWrite`'s **`valid`** port from **`decOut 5`**.
`sem_decoder_eq_ctrlSpec` pins `decOut j` to `ctrlSpec` index `j`, and `ctrlSpec`'s row is

```
index    0      1      2      3      4      5      6     7     8
       isADD  isXOR  isSLT  isADDI isBEQ  isLW   isSW  req  valid
```

⇒ ***the assembled core write-enabled on "this is a LOAD", not on "this instruction writes
a register"*** — so it never wrote a register on `ADD`, `ADDI`, `XOR` or `SLT`. The port now
reads `decOut 8`. **The receipt is a DIFFERENTIAL, not a re-assertion:**
`core_never_writes_on_ADD` / `_XOR` / `_ADDI` were provable BEFORE the repair and are FALSE
after it; they are replaced below by `core_writes_on_ADD` / `_XOR` / `_SLT` / `_ADDI`, plus
two negatives that a correct repair must LEAVE STANDING (`core_writes_nothing_on_BEQ`,
`_on_garbage`) so that a fix which merely turned every enable on would fail here.

## ⚠️ WHY NOTHING CAUGHT IT, and the answer is uncomfortable

`regWrite_correct` is exhaustive over 128 control combinations — **of `regWrite`'s own
ports.** It cannot see what those ports are CONNECTED to. `decoder_correct` is likewise
about the decoder alone. `instOK` certifies that σ lands in range, not that it lands on the
right net. And `CorePlace`'s own control, `valid_and_isBEQ_are_distinct_and_ordered`, is
**named** for this exact hazard — its docstring says *"`valid` is output 5 and `isBEQ` is
output 4"* — but its STATEMENT proves only `regWriteSig 5 = decOut 5`, `regWriteSig 6 =
decOut 4`, and `decOut 4 ≠ decOut 5`: **the wiring and the distinctness, never the
identification.** A control whose docstring names the defect and whose statement cannot
express it. ⇒ `valid_is_decoder_output_8` at the foot of this file is the control that did
not exist: it pins the INDEX to its MEANING, not to another index.

*This seat's ledger already carries the shape — `instOK-certifies-in-time-not-right-wire`,
recorded after two placements fed `rs2` where `ADDI` needed the immediate. This was the third
instance, found the same way: by transporting an organ theorem and reading what came out.*

⛔ **STATUS — AND A SECOND DEFECT OF THE SAME FAMILY, FOUND 11:3x THE SAME DAY.**
`RegDatapathOK` is still **UNPROVED rather than refuted** (no value witness stands against
it yet), but ***one of its two remaining halves is now FALSE IN THE KERNEL***: the circuit's
enable does NOT agree with the ISA's write decision, because **`SW` write-enables a
register**. `valid` (index 8) is true for EVERY decodable instruction, `SW` included, and
the enable term set is `valid && !isBEQ && (rdOf == k) && k≠0` — **`isBEQ` disqualifies
branches and NOTHING disqualifies stores.** A store's bits 7…11 are `imm[4:0]`, not an `rd`,
so any store with a nonzero low immediate writes the register those bits happen to name.
See `core_writes_on_SW` and `sw_forces_selOut_to_equal_held` below. The structural reduction in `C4Reduction` was never affected, and neither
was `RegField core 0` (x0 never writes under either wiring).

⚠️ **AND THE ELEVEN-HOUR LESSON, kept because it is not derivable from the code:** the
pre-repair text of this file ended *"this file does not make it, because `CorePlace` is not
this seat's to edit unilaterally"* — and on that belief this seat asked another seat to make
the fix thirteen times. **It was ours the whole time** (`docs/SEATS.md:8` —
`SaltWorks/HDL/** : COMPILER seat`; helm ruling 08/17 *"R9 OWNER = COMPILER, ownership
follows the ARTIFACT"*). The silence was correct and there was nothing for anyone to do.
⇒ **BEFORE DIAGNOSING A DELIVERY FAILURE, READ `docs/SEATS.md` AND ASK WHETHER THE SILENCE
IS CORRECT.**

*Not C4, not a witness, does not close R9/B2. No new `RegField` is discharged here.*
-/
import SaltWorks.HDL.EnableSpec

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

def coreThru2 : List Gate :=
  instGates tieCells id offTie ++ instGates decoder decoderSig off0

def coreRest11 : List Gate :=
  instGates immBCirc immBSig off1
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

theorem coreThru13_split : coreThru13 = coreThru2 ++ coreRest11 := by
  simp only [coreThru13, coreThru2, coreRest11, List.append_assoc]

/-- Every gate of the eleven organs AFTER the decoder writes at or above `off1`. -/
theorem coreRest11_out_ge : ∀ g ∈ coreRest11, off1 ≤ g.out := by
  have key : ∀ (c : Circ) (σ : Net → Net) (off : Nat), c.ssa = true → off1 ≤ off →
      ∀ g ∈ instGates c σ off, off1 ≤ g.out :=
    fun c σ off hssa hoff g hg =>
      Nat.le_trans hoff (instGates_out_range c σ off hssa g hg).1
  intro g hg
  -- ⚠️ the bullet after `rcases _ with hg | h` focuses the FIRST goal, where `h` is NOT
  -- bound. Flatten to a right-nested disjunction with `or_assoc` and take the cases in
  -- source order instead.
  simp only [coreRest11, List.mem_append, or_assoc] at hg
  rcases hg with h|h|h|h|h|h|h|h|h|h|h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ readTree_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ readTree_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ bitXor32_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ adder32_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ adder32_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ sltCirc_ssa (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h
  · exact key _ _ _ (by decide +kernel) (by first | (simp only [offRegNext, offPc, offRw, offEnc, offSel, offSlt, offSub, offAdd, offOb, off5, off4, off3, off2, off1, off0, offTie, instNext]; omega) | exact Nat.le_refl _) g h

theorem decOut_lt_off1 (j : Nat) (hj : j < 9) : decOut j < off1 := by revert j; decide +kernel
theorem decoder_outs_len : decoder.outs.length = 9 := by decide +kernel
theorem decoder_nIn_32 : decoder.nIn = 32 := by decide +kernel
theorem decoder_out_mem (j : Nat) (hj : j < 9) :
    (decoder.gates.map Gate.out).contains (decoder.outs.getD j 0) = true := by
  revert j; decide +kernel

theorem decoder_out_bound (j : Nat) (hj : j < 9) :
    decoder.outs.getD j 0 < decoder.nIn + decoder.gates.length := by revert j; decide +kernel

/-- A primary input survives the tie-cell block. -/
theorem tie_input_stable (ins : Env) (n : Net) (hn : n < offTie) :
    run ins (instGates tieCells id offTie) n = ins n :=
  run_of_unwritten ins _ n (fun g hg hEq =>
    absurd (hEq ▸ (instGates_out_range tieCells id offTie tieCells_ssa g hg).1)
      (Nat.not_le.mpr hn))

theorem instrNet_lt (i : Nat) (hi : i < 32) : instrNet i < offTie := by revert i; decide +kernel

/-- ⭐⭐⭐ **THE DECODER'S OUTPUTS, INSIDE `core`, ARE `ctrlSpec` OF THE INSTRUCTION WORD.**
The organ's landed correctness (`sem_decoder_eq_ctrlSpec`) lifted onto the placement. -/
theorem core_decOut_spec (ins : Env) (j : Nat) (hj : j < 9) :
    run ins coreThru13 (decOut j) = (ctrlSpec (seenWord ins)).getD j false := by
  -- peel the eleven organs after the decoder
  rw [coreThru13_split, run_append,
      run_of_unwritten _ _ _ (fun g hg hEq => by
        have hge := coreRest11_out_ge g hg
        rw [hEq] at hge
        exact absurd hge (Nat.not_le.mpr (decOut_lt_off1 j hj)))]
  -- read the decoder's own output through the placement
  rw [decOut, instOuts, getD_map_lt _ _ _ (by rw [decoder_outs_len]; exact hj) 0 0,
      coreThru2, run_append,
      inst_sem decoder decoderSig off0 _
        (fun a => run ins (instGates tieCells id offTie) (decoderSig a))
        decoder_instOK (fun _ _ => rfl)
        (decoder.outs.getD j 0) (Or.inr (decoder_out_mem j hj))]
  -- swap that environment for the instruction word's bits, then use the organ theorem
  rw [show (ctrlSpec (seenWord ins)).getD j false
        = (sem decoder (fun i => (seenWord ins).getLsbD i)).getD j false from by
        rw [sem_decoder_eq_ctrlSpec], sem,
      getD_map_lt _ _ _ (by rw [decoder_outs_len]; exact hj) 0 false]
  refine run_agree_of_inputs_circ decoder decoder_ssa _ _ (fun a ha => ?_) _
    (decoder_out_bound j hj)
  rw [decoder_nIn_32] at ha
  rw [show decoderSig a = instrNet a from rfl, tie_input_stable ins _ (instrNet_lt a ha),
      seenWord, wordOf_getLsbD _ _ ha]

theorem isADDOf_spec  (ins : Env) : isADDOf ins  = (ctrlSpec (seenWord ins)).getD 0 false :=
  core_decOut_spec ins 0 (by omega)
theorem isXOROf_spec  (ins : Env) : isXOROf ins  = (ctrlSpec (seenWord ins)).getD 1 false :=
  core_decOut_spec ins 1 (by omega)
theorem isSLTOf_spec  (ins : Env) : isSLTOf ins  = (ctrlSpec (seenWord ins)).getD 2 false :=
  core_decOut_spec ins 2 (by omega)
theorem isADDIOf_spec (ins : Env) : isADDIOf ins = (ctrlSpec (seenWord ins)).getD 3 false :=
  core_decOut_spec ins 3 (by omega)
theorem isLWOf_spec   (ins : Env) : isLWOf ins   = (ctrlSpec (seenWord ins)).getD 5 false :=
  core_decOut_spec ins 5 (by omega)

theorem validOf_spec (ins : Env) : validOf ins = (ctrlSpec (seenWord ins)).getD 8 false :=
  core_decOut_spec ins 8 (by omega)

theorem isBEQOf_spec (ins : Env) : isBEQOf ins = (ctrlSpec (seenWord ins)).getD 4 false :=
  core_decOut_spec ins 4 (by omega)

/-! ### ✅ WHAT THE TRANSPORT REVEALED, AND THE REPAIR THAT ANSWERED IT

⛔ **HISTORY, KEPT BECAUSE THE MECHANISM OUTLIVES THE BUG.** Until 08-19 this section held
`core_never_writes_on_ADD` / `_XOR` / `_ADDI`, which **PROVED** that the assembled core never
wrote a register on any arithmetic instruction: `regWriteSig` fed `regWrite`'s `valid` port
from `decOut 5`, and `decOut j` is `ctrlSpec` index `j`, where **index 5 is `isLW`** and
`valid` is **8**. The core write-enabled on *"this is a load"*.

***THOSE THREE THEOREMS NO LONGER COMPILE, AND THAT IS THE RECEIPT FOR THE FIX.*** They were
provable before the repair and are FALSE after it — a differential nobody has to take on
trust. The wiring was corrected at `CorePlace.regWriteSig` on 08-19 by this seat, which owns
`SaltWorks/HDL/**` (`docs/SEATS.md:8`; helm ruling 08/17 *"R9 OWNER = COMPILER"*). -/

/-- ⭐ **THE DEFECT AND ITS REPAIR, EXHIBITED IN ONE KERNEL STATEMENT.** On an `ADD` word the
OLD index reads FALSE and the NEW index reads TRUE — *same word, two indices, opposite
values.* This is why the mis-wiring silenced every arithmetic write, and it is cheap enough
that no successor need reconstruct it. -/
theorem the_repair_is_observable (w : BitVec 32) (rd a b : Fin 32)
    (h : decode w = some (.ADD rd a b)) :
    (ctrlSpec w).getD 5 false = false ∧ (ctrlSpec w).getD 8 false = true := by
  simp [ctrlSpec, h]

/-- ⭐⭐ **`core` NOW WRITES THE REGISTER `ADD` NAMES.** The positive form of the theorem this
section used to carry in the negative. -/
theorem core_writes_on_ADD (ins : Env) (rd a b : Fin 32)
    (h : decode (seenWord ins) = some (.ADD rd a b)) (hne : ¬ (rdOf ins = 0)) :
    run ins core.gates (rwOut (rdOf ins)) = true := by
  rw [core_rwOut_spec ins (rdOf ins) (rdOf_lt ins), writesRegOf, isADDOf_spec ins,
      isXOROf_spec ins, isSLTOf_spec ins, isADDIOf_spec ins, isLWOf_spec ins, isBEQOf_spec ins]
  simp [ctrlSpec, h, hne]

theorem core_writes_on_XOR (ins : Env) (rd a b : Fin 32)
    (h : decode (seenWord ins) = some (.XOR rd a b)) (hne : ¬ (rdOf ins = 0)) :
    run ins core.gates (rwOut (rdOf ins)) = true := by
  rw [core_rwOut_spec ins (rdOf ins) (rdOf_lt ins), writesRegOf, isADDOf_spec ins,
      isXOROf_spec ins, isSLTOf_spec ins, isADDIOf_spec ins, isLWOf_spec ins, isBEQOf_spec ins]
  simp [ctrlSpec, h, hne]

theorem core_writes_on_SLT (ins : Env) (rd a b : Fin 32)
    (h : decode (seenWord ins) = some (.SLT rd a b)) (hne : ¬ (rdOf ins = 0)) :
    run ins core.gates (rwOut (rdOf ins)) = true := by
  rw [core_rwOut_spec ins (rdOf ins) (rdOf_lt ins), writesRegOf, isADDOf_spec ins,
      isXOROf_spec ins, isSLTOf_spec ins, isADDIOf_spec ins, isLWOf_spec ins, isBEQOf_spec ins]
  simp [ctrlSpec, h, hne]

theorem core_writes_on_ADDI (ins : Env) (rd a : Fin 32) (imm : BitVec 12)
    (h : decode (seenWord ins) = some (.ADDI rd a imm)) (hne : ¬ (rdOf ins = 0)) :
    run ins core.gates (rwOut (rdOf ins)) = true := by
  rw [core_rwOut_spec ins (rdOf ins) (rdOf_lt ins), writesRegOf, isADDOf_spec ins,
      isXOROf_spec ins, isSLTOf_spec ins, isADDIOf_spec ins, isLWOf_spec ins, isBEQOf_spec ins]
  simp [ctrlSpec, h, hne]

/-- **AND THE NEGATIVE THAT MUST SURVIVE THE REPAIR: `BEQ` STILL WRITES NOTHING.** It is the
one Slice A instruction with no destination, so a repair that turned every enable on would be
a different defect wearing the fix's clothes. Every register, not just `rd`. -/
theorem core_writes_nothing_on_BEQ (ins : Env) (k : Nat) (hk : k < 32)
    (a b : Fin 32) (imm : BitVec 12)
    (h : decode (seenWord ins) = some (.BEQ a b imm)) :
    run ins core.gates (rwOut k) = false := by
  rw [core_rwOut_spec ins k hk, writesRegOf, isADDOf_spec ins, isXOROf_spec ins,
      isSLTOf_spec ins, isADDIOf_spec ins, isLWOf_spec ins, isBEQOf_spec ins]
  simp [ctrlSpec, h]

/-- **AND AN UNDECODABLE WORD STILL WRITES NOTHING** — the v1 NOP-advance, in gates. -/
theorem core_writes_nothing_on_garbage (ins : Env) (k : Nat) (hk : k < 32)
    (h : decode (seenWord ins) = none) :
    run ins core.gates (rwOut k) = false := by
  rw [core_rwOut_spec ins k hk, writesRegOf, isADDOf_spec ins, isXOROf_spec ins,
      isSLTOf_spec ins, isADDIOf_spec ins, isLWOf_spec ins, isBEQOf_spec ins]
  simp [ctrlSpec, h]

/-- **`LW` writes its destination** — unchanged by the repair, and it is the arm that proved
the wire was LIVE rather than dead back when it was aimed at `isLW`. -/
theorem core_does_write_on_LW (ins : Env) (rd a : Fin 32) (imm : BitVec 12)
    (h : decode (seenWord ins) = some (.LW rd a imm))
    (hne : ¬ (rdOf ins = 0)) :
    run ins core.gates (rwOut (rdOf ins)) = true := by
  rw [core_rwOut_spec ins (rdOf ins) (rdOf_lt ins), writesRegOf, isADDOf_spec ins,
      isXOROf_spec ins, isSLTOf_spec ins, isADDIOf_spec ins, isLWOf_spec ins, isBEQOf_spec ins]
  simp [ctrlSpec, h, hne]

/-- ⭐⭐⭐ **THE REPAIR'S RECEIPT, AND IT IS A DIFFERENTIAL: `SW` NOW WRITES NOTHING.**

⛔ **THIS THEOREM REPLACES `core_writes_on_SW`, WHICH WAS PROVABLE HERE UNTIL THE REPAIR AND IS
FALSE AFTER IT.** That inversion is the receipt — nobody has to take the repair on trust:
```
  BEFORE  core_writes_on_SW      : run ins core.gates (rwOut (rdOf ins)) = true    -- PROVED
  AFTER   core_writes_nothing_on_SW : ... = false                                  -- PROVED
```
The old theorem's own docstring said *"a repair that leaves this compiling has not been made."*
It no longer compiles, and this is what took its place.

**WHY IT NOW HOLDS:** the enable reads `writesReg = isADD ∨ isXOR ∨ isSLT ∨ isADDI ∨ isLW`, and
`ctrlSpec`'s `SW` row raises NONE of those five. Previously it read `valid`, which `SW` raises
like every decodable word — so the store's `imm[4:0]`, sitting in bits 7…11 where the enable
looks for an `rd`, selected a register to clobber. **Every register, not just the one the
immediate names.** -/
theorem core_writes_nothing_on_SW (ins : Env) (k : Nat) (hk : k < 32)
    (a b : Fin 32) (imm : BitVec 12)
    (h : decode (seenWord ins) = some (.SW a b imm)) :
    run ins core.gates (rwOut k) = false := by
  rw [core_rwOut_spec ins k hk, writesRegOf, isADDOf_spec ins, isXOROf_spec ins,
      isSLTOf_spec ins, isADDIOf_spec ins, isLWOf_spec ins, isBEQOf_spec ins]
  simp [ctrlSpec, h]

/-- **AND THE ISA WRITES NOTHING ON A STORE** — `rfl`, so the disagreement is not a matter
of interpretation. Paired with `core_writes_on_SW` this is the enable-agreement half of
`RegDatapathOK`, refuted. -/
theorem isa_writes_nothing_on_SW (a b : Fin 32) (imm : BitVec 12) :
    writesReg (.SW a b imm) = none := rfl

/-- ⭐⭐⭐ **THE IDENTIFICATION CONTROL THAT DID NOT EXIST — `decOut 8` IS `valid`, PROVED
SEMANTICALLY.** `CorePlace.valid_and_isBEQ_are_distinct_and_ordered` pins the σ to an INDEX
and can only catch a swap; this pins the index to its MEANING through
`sem_decoder_eq_ctrlSpec`. *This is the control whose absence let the original defect live,
and it is stated here because `ctrlSpec` is not in scope where the σ is written.* -/
theorem valid_is_decoder_output_8 (ins : Env) :
    run ins coreThru13 (decOut 8) = (ctrlSpec (seenWord ins)).getD 8 false :=
  core_decOut_spec ins 8 (by omega)

#audit_axioms coreThru13_split coreRest11_out_ge
#audit_axioms core_decOut_spec validOf_spec isBEQOf_spec
#audit_axioms the_repair_is_observable valid_is_decoder_output_8
#audit_axioms core_writes_on_ADD core_writes_on_XOR core_writes_on_SLT core_writes_on_ADDI
#audit_axioms core_writes_nothing_on_BEQ core_writes_nothing_on_garbage core_does_write_on_LW
#audit_axioms core_writes_nothing_on_SW isa_writes_nothing_on_SW
#audit_axioms isADDOf_spec isXOROf_spec isSLTOf_spec isADDIOf_spec isLWOf_spec

end SaltWorks.HDL.RegNextUniform
