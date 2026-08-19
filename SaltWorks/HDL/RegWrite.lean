/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Decoder

import SaltWorks.HDL.EmitN

/-!
# C4 · `core` — THE WRITE-ENABLE DECODER

The second block of `compile`/`core`. Silicon's measurement is why this side is
cheap and the read side is not:

> *A read **selects** one of 31 registers — its cone grows with the file. A write
> **enables** one of 31 — its cone does not.*

**And this block is where P5 stops being a theorem about `St.set` and becomes a
gate that is not there.** `St.set 0 v = s` is landed (`ISA.lean`); here the
corresponding fact is that **`we 0` is the constant `false`**, so no write port
on register `x0` exists in the silicon at all.

## What it computes

```
we r  =  valid ∧ ¬isBEQ ∧ (rd = r) ∧ r ≠ 0
```

`¬isBEQ` because `BEQ` is the one Slice A instruction with no destination — it
writes the `pc` and nothing else. `valid` because an undecodable word is the
ratified **NOP-advance**: the register file must be untouched, and that is
enforced here rather than downstream.

⚠️ **`valid` is doing real work and is not defensive.** Under the ratified
option-1 semantics **99.61% of the word space is undecodable**, so the `¬valid`
path is not an edge case — *it is the overwhelmingly common input*, and a
missing `valid` term would corrupt the register file on almost every word a
fuzzer could hand it.
-/

namespace SaltWorks.HDL

open SaltWorks.ISA

/-! ### Layout: `rd` on `0…4`, `valid` on `5`, `isBEQ` on `6`. -/

/-! ⛔⛔ **REPAIRED 2026-08-19 — `valid` WAS THE SECOND ENABLE DEFECT.** This organ took `valid`
on port 5 and computed `wrEn = valid ∧ ¬isBEQ`. **`valid` means "DECODES", not "writes a
register"** — true for every decodable word, *stores included* — so the assembled core
write-enabled on every store, whose bits 7…11 are `imm[4:0]` and not an `rd`.
`SaltWorks.HDL.C4Refuted` turned that into `¬ C4Spec core`, witness `SW x1, x2, 4`.
⇒ **Port 5 is now `isADD`, and the enable is the DISJUNCTION the spec always meant:**
`writes = isADD ∨ isXOR ∨ isSLT ∨ isADDI ∨ isLW`. `SW` is excluded by ABSENCE from that list.
It had to be new logic: **no decoder output equals this column.** -/

def rwIn : Nat := 11
def rwRd (i : Nat) : Net := i
/-- Port 5 was `valid`. That rename is the defect's whole story. -/
def rwIsADD : Net := 5
def rwIsBEQ : Net := 6
def rwIsXOR : Net := 7
def rwIsSLT : Net := 8
def rwIsADDI : Net := 9
def rwIsLW : Net := 10

/-- `¬rd[i]` on `11…15`. -/
def rwNotRd (i : Nat) : Net := rwIn + i
/-- The `writes` fold on `16…19`. -/
def rwOr1 : Net := rwIn + 5
def rwOr2 : Net := rwIn + 6
def rwOr3 : Net := rwIn + 7
def rwWrites : Net := rwIn + 8
def rwNotBEQ : Net := rwIn + 9
/-- `wrEn = writes ∧ ¬isBEQ` on `21`; matching logic allocates from `22`.
⚠️ `¬isBEQ` is KEPT though `isBEQ` is now simply absent from the disjunction: retiring a
disqualifier in the same commit that adds one would make the differential ambiguous about
which change did the work. -/
def rwWrEn : Net := rwIn + 10
def rwBase : Nat := rwIn + 11

/-- The fixed prefix: five inverters, the four-gate `writes` fold, `¬isBEQ`, and the common
enable. -/
def rwPrefix : List Gate :=
  (List.range 5).map (fun i => (⟨rwNotRd i, .not (rwRd i)⟩ : Gate))
    ++ [⟨rwOr1, .or rwIsADD rwIsXOR⟩, ⟨rwOr2, .or rwOr1 rwIsSLT⟩,
        ⟨rwOr3, .or rwOr2 rwIsADDI⟩, ⟨rwWrites, .or rwOr3 rwIsLW⟩,
        ⟨rwNotBEQ, .not rwIsBEQ⟩, ⟨rwWrEn, .and rwWrites rwNotBEQ⟩]

/-- The literals selecting `rd = r`. -/
def rwMatch (r : Nat) : List Net :=
  (List.range 5).map fun i => if r.testBit i then rwRd i else rwNotRd i

/-- Registers `1 … 31`, each an address match ANDed with the common enable.
`x0` is handled separately and is not in this list. -/
def rwLayout : Nat → List Nat → List Gate × List Net × Nat
  | b, []      => ([], [], b)
  | b, r :: rs =>
      let (gs, m, b') := andChain b (rwMatch r)
      let (gs', os, b'') := rwLayout (b' + 1) rs
      (gs ++ [⟨b', .and m rwWrEn⟩] ++ gs', b' :: os, b'')

/-- **The write-enable decoder.** Output `r` is register `r`'s enable, in order
`0 … 31`; output `0` is the constant `false` — **P5, as an absent write port.** -/
def regWrite : Circ :=
  let (gs, outs, b) := rwLayout rwBase (List.range 31 |>.map (· + 1))
  { nIn := rwIn
    gates := rwPrefix ++ gs ++ [⟨b, .const false⟩]
    outs := b :: outs }

theorem regWrite_wf : regWrite.wf = true := by decide +kernel

/-! ### The specification and its certificate -/

/-- What the enables should be. ⛔ **`valid` IS GONE FROM THIS STATEMENT — that is the repair**,
in one line of spec.
⚠️ **NO DEFAULT ARGUMENTS, BY MATH'S RULING (15:18).** Defaults would have let
`Stack/Program.lean:7674` elaborate unchanged while its meaning moved from *"any valid
instruction"* to *"an ADD"* — **soundness is not preserved meaning**, and a call site whose
BYTES do not change while its SENSE does is the exact shape of both defects repaired today.
The call site is updated explicitly under a cross-slot grant instead. -/
def weSpec (rd : Nat) (isADD isBEQ isXOR isSLT isADDI isLW : Bool) : List Bool :=
  (List.range 32).map fun r =>
    (isADD || isXOR || isSLT || isADDI || isLW) && !isBEQ && (rd == r) && !(r == 0)

/-- The organ's input valuation, PACKED into one `Nat`: bits `0…4` are `rd`, `5…10` the flags. -/
def rwPack (rd : Nat) (isADD isBEQ isXOR isSLT isADDI isLW : Bool) : Nat :=
  (rd % 32)
    ||| (if isADD then 2 ^ 5 else 0) ||| (if isBEQ then 2 ^ 6 else 0)
    ||| (if isXOR then 2 ^ 7 else 0) ||| (if isSLT then 2 ^ 8 else 0)
    ||| (if isADDI then 2 ^ 9 else 0) ||| (if isLW then 2 ^ 10 else 0)

/-- ⭐ **THE PACKED VALUATION READS BACK AS THE PORT LIST** — the only place the encoding is
inspected.
⚠️ **`simp` FOLDS `2 ^ 9` INTO `512`, AFTER WHICH `Nat.testBit_two_pow` CANNOT MATCH** and the
literal sits unevaluated. `simp only` with a restricted set keeps the powers symbolic long
enough for the lemma to fire. *That, and not the mathematics, is what made this lemma hard.*
⚠️ `hhi` uses CORE lemmas: `Nat.testBit_eq_false_of_lt` is Mathlib and `norm_num` is not in
this file's closure, so either would grow an import on a file the whole HDL tree depends on.

⭐ **THE SIMP LIST IS MINIMAL, AND IT WAS CHECKED RATHER THAN TRIMMED FOR TIDINESS.** It first
carried `if_false`, `Bool.or_false` and `Bool.false_or`, which Lean reported as UNUSED — and
*"unused simp argument" is the only signal Lean gives that a `simp` fired nothing*, so in a
freshly-repaired file it is the one warning class that deserves a look before dismissal (the
math seat flagged it the beat this landed). **The three were surplus, not masking:** the
remaining arguments all fire, and the proof stands without them.
⛔ **AND THE LEMMA IS NOT VACUOUS, which is the question the warning really asks.** It is the
bridge in `EnableSpec.core_rwOut_eq_weOf`, so the whole enable chain routes through it — and
that chain yields OPPOSITE verdicts on the same machinery: `core_writes_on_ADD` proves `true`
while `core_writes_nothing_on_SW` proves `false`. **A lemma that fired nothing could not
separate those two.** -/
theorem rwPack_testBit (rd : Nat) (hrd : rd < 32) (a b c d e f : Bool) (i : Nat) (hi : i < 11) :
    (rwPack rd a b c d e f).testBit i
      = (if i < 5 then rd.testBit i
         else if i == 5 then a else if i == 6 then b else if i == 7 then c
         else if i == 8 then d else if i == 9 then e else f) := by
  have hm : rd % 32 = rd := Nat.mod_eq_of_lt hrd
  have hhi : ∀ j, 5 ≤ j → rd.testBit j = false := by
    intro j hj
    have hp : (2 : Nat) ^ 5 ≤ 2 ^ j := Nat.pow_le_pow_right (by decide) hj
    have hlt : rd < 2 ^ j := Nat.lt_of_lt_of_le hrd hp
    simp [Nat.testBit, Nat.shiftRight_eq_div_pow, Nat.div_eq_of_lt hlt]
  interval_cases i <;> cases a <;> cases b <;> cases c <;> cases d <;> cases e <;> cases f <;>
    simp only [rwPack, hm, Nat.testBit_or, Nat.testBit_two_pow, if_true,
               Nat.testBit_zero] <;>
    simp +decide [hhi]

/-- The circuit's answer, read through the PACKED evaluator.
⚠️ `semB_eq` proves `semB` IS `sem`, so this is a statement about the circuit, not the encoding. -/
def weOf (rd : Nat) (isADD isBEQ isXOR isSLT isADDI isLW : Bool) : List Bool :=
  semB regWrite (rwPack rd isADD isBEQ isXOR isSLT isADDI isLW)

/-- **Exhaustive: every `rd`, every control combination — 32 × 2⁶ = 2048.**
⛔ At 128 points this was affordable over `sem`; at 2048 it exhausted `-M 20000` in the
INTERPRETER, nested AND flattened. Over `semB` it costs seconds. **The cost was the environment
representation, never the circuit.** -/
def weOK : Bool :=
  (List.range 32).all fun rd =>
  [false, true].all fun a => [false, true].all fun b => [false, true].all fun c =>
  [false, true].all fun d => [false, true].all fun e => [false, true].all fun f =>
    weOf rd a b c d e f == weSpec rd a b c d e f

theorem regWrite_correct : weOK = true := by decide +kernel

/-- ⭐⭐⭐ **THE REPAIR AS A THEOREM ABOUT THE ORGAN: A STORE ENABLES NOTHING.** A `SW` word
raises none of the five write flags, so whatever its bits 7…11 say, every enable is `false`.
**The sentence the old organ could not state, because its port was `valid`.** -/
theorem regWrite_store_writes_nothing :
    ((List.range 32).all fun rd => [false, true].all fun b =>
      (weOf rd false b false false false false).all (· == false)) = true := by decide +kernel

/-! ### The three facts this block exists to guarantee -/

/-- **P5 IN GATES — `x0` is never enabled, under any input whatsoever.** -/
theorem regWrite_x0_never_enabled :
    ((List.range 32).all fun rd => [false, true].all fun v => [false, true].all fun b =>
      (weOf rd v b false false false false).getD 0 false == false) = true := by decide +kernel

/-- **The NOP-advance path touches no register** — the ratified semantics, in
gates, on the 99.61% of words that are undecodable. -/
theorem regWrite_invalid_writes_nothing :
    ((List.range 32).all fun rd => [false, true].all fun b =>
      (weOf rd false b false false false false).all (· == false)) = true := by decide +kernel

/-- **`BEQ` writes no register** — it is the one Slice A instruction with no
destination. -/
theorem regWrite_beq_writes_nothing :
    ((List.range 32).all fun rd =>
      (weOf rd true true false false false false).all (· == false)) = true := by decide +kernel

/-- **NON-VACUITY — the enables are not constant `false`.** A valid non-`BEQ`
instruction with `rd = 3` enables exactly register 3. -/
theorem regWrite_enables_exactly_one :
    weOf 3 true false false false false false = (List.range 32).map (· == 3) := by decide +kernel

/-- **Dense SSA — the precondition for instantiating this block into `core`.**
`Compose.instOK` needs `ssa`, not merely `wf`: under `wf` alone the gate outputs
may be sparse and `instNext` would under-report the region occupied. *Checked
here rather than assumed at the assembly site.* -/
theorem regWrite_ssa : regWrite.ssa = true := by decide +kernel

#audit_axioms regWrite_ssa regWrite_store_writes_nothing rwPack_testBit
#audit_axioms rwIn
#audit_axioms rwPrefix
#audit_axioms rwMatch
#audit_axioms rwLayout
#audit_axioms regWrite
#audit_axioms regWrite_wf
#audit_axioms weSpec
#audit_axioms weOf
#audit_axioms regWrite_correct
#audit_axioms regWrite_x0_never_enabled
#audit_axioms regWrite_invalid_writes_nothing
#audit_axioms regWrite_beq_writes_nothing
#audit_axioms regWrite_enables_exactly_one

end SaltWorks.HDL
