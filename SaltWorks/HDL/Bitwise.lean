/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Adder
import SaltWorks.HDL.Compose
import SaltWorks.HDL.ISA

/-!
# C4 · THE OPERAND BLOCKS — six of `aluSelect`'s eight missing producers

**`aluSelect` takes TEN precomputed 32-bit operand results and computes none of
them** (`AluSelect.lean:56`; census in `docs/hdl-c4-core-assembly-plan-0807.md`).
Eight had no producer in the tree. **Six of them land here:**

```
and   or   xor        aluSelect results 2, 3, 4        pointwise
slt   sltu            aluSelect results 5, 6           derived from the adder
not                   NOT an ALU result -- it is what makes `sub` out of
                      `adder32`, which needs (a, ~b, carry-in 1)
```

⚠️ **THIS FILE'S TITLE SAID "BITWISE" AND "FOUR" WHEN IT WAS COMMITTED AN HOUR
AGO, AND BOTH WENT STALE THE MOMENT `slt`/`sltu` LANDED IN IT.** *Regenerated
rather than left — the same reflex this campaign has now caught five times in two
days, and a file that names the reflex is the worst place to commit it.*

*The remaining two — `sll` and `sra` — are NOT here and are not a build: they
need a shifter mode `shifter32` does not have, which is a change to a landed,
certified block and therefore silicon's decision.*

## Why one constructor and not three files

**A pointwise binary block is the same circuit three times with one `Op`
changed**, so the risk is not in any one of them — it is that a copy-paste of the
third gets an index wrong and still looks right. `bwCirc` takes the operation and
builds the layout once; the three ALU blocks are instances of it, and the
**differential control below shows the three are genuinely different circuits**
rather than the same one named thrice.

## Layout

```
operand a   nets  0 … 31
operand b   nets 32 … 63
results     nets 64 … 95      dense SSA from nIn = 64, so instantiable as-is
```
-/

namespace SaltWorks.HDL

open SaltWorks.ISA

/-! ### The constructor -/

/-- A pointwise binary block over two 32-bit operands. -/
def bwCirc (mk : Net → Net → Op) : Circ :=
  { nIn   := 64
    gates := (List.range 32).map fun k => ⟨64 + k, mk k (32 + k)⟩
    outs  := (List.range 32).map (fun k => 64 + k) }

/-- `aluSelect` result 2. -/
def bitAnd32 : Circ := bwCirc .and
/-- `aluSelect` result 3. -/
def bitOr32  : Circ := bwCirc .or
/-- `aluSelect` result 4. -/
def bitXor32 : Circ := bwCirc .xor

/-- **Not an ALU result** — this is what turns `adder32` into a subtractor:
`a - b = a + ~b + 1`. One operand, 32 gates. -/
def bitNot32 : Circ :=
  { nIn   := 32
    gates := (List.range 32).map fun k => ⟨32 + k, .not k⟩
    outs  := (List.range 32).map (fun k => 32 + k) }

/-! ### Instantiability — the precondition for embedding in `core` -/

theorem bitAnd32_ssa : bitAnd32.ssa = true := by decide +kernel
theorem bitOr32_ssa  : bitOr32.ssa  = true := by decide +kernel
theorem bitXor32_ssa : bitXor32.ssa = true := by decide +kernel
theorem bitNot32_ssa : bitNot32.ssa = true := by decide +kernel

theorem bitAnd32_wf : bitAnd32.wf = true := Circ.wf_of_ssa bitAnd32_ssa
theorem bitOr32_wf  : bitOr32.wf  = true := Circ.wf_of_ssa bitOr32_ssa
theorem bitXor32_wf : bitXor32.wf = true := Circ.wf_of_ssa bitXor32_ssa
theorem bitNot32_wf : bitNot32.wf = true := Circ.wf_of_ssa bitNot32_ssa

theorem bw_gate_counts :
    bitAnd32.gates.length = 32 ∧ bitOr32.gates.length = 32
      ∧ bitXor32.gates.length = 32 ∧ bitNot32.gates.length = 32 := by
  decide +kernel

/-! ### Correctness, against `BitVec`'s own operations — SAMPLED, AND THE NAMES SAY SO

⚠️ **MATH'S 16:22 FINDING, AND IT IS RIGHT ABOUT THE PART THAT MATTERS.**
`bwWords` is TEN words, so every certificate below checks **100 ordered pairs out
of 2^64 ≈ 1.8 × 10^19 — a 5 × 10^-18 slice.** *This file said "sampled rather
than exhaustive" at the definition site from the day it landed, so the honesty
was there.* ⛔ **THE DEFECT IS THAT THE CAVEAT DID NOT TRAVEL WITH THE NAME:
`bitXor32_correct` reads at a call site exactly like a correctness theorem, and a
consumer is one `import` away from the docstring that qualifies it.**

✅ **FIXED THE ONLY WAY THAT TRAVELS: every sampled certificate is now
`…_on_sample`.** *A reader who never opens this file still cannot mistake it.*
📌 **AND WHERE THE SAMPLE COULD BE REMOVED, MATH REMOVED IT** — `sem_bitXor32`
(`Stack/Program.lean`, `d4fe922`) proves the XOR block for **all 2^64 pairs,
structurally, with no `decide` at all**, and SUPERSEDES the sampled version
rather than consuming it. *The remaining samples are where the gap is real, and
it enters one layer down: `adder32` has no structural semantics, so anything
driven through it inherits the sample.*

*Sampled rather than exhaustive — 2^64 input pairs is not a proof obligation, it
is a category error. The words below are the campaign's standard spread: zero,
all-ones, alternating in both phases, a low mask, a high mask, and two
asymmetric patterns that distinguish `and`/`or`/`xor` from each other and from a
constant.* -/

/-- The input valuation: `a` on nets `0…31`, `b` on `32…63`. -/
def bwEnv (a b : BitVec 32) : Env :=
  fun i => if i < 32 then a.getLsbD i else b.getLsbD (i - 32)

/-- The campaign's word spread. -/
def bwWords : List (BitVec 32) :=
  [0, 0xFFFFFFFF, 0xAAAAAAAA, 0x55555555, 0x0000FFFF, 0xFFFF0000,
   0x12345678, 0xDEADBEEF, 1, 0x80000000]

/-- A block computes a `BitVec` operation on every pair from the spread. -/
def bwOK (c : Circ) (f : BitVec 32 → BitVec 32 → BitVec 32) : Bool :=
  bwWords.all fun a => bwWords.all fun b =>
    sem c (bwEnv a b) == (List.range 32).map (fun k => (f a b).getLsbD k)

theorem bitAnd32_correct_on_sample : bwOK bitAnd32 (· &&& ·) = true := by decide +kernel
theorem bitOr32_correct_on_sample  : bwOK bitOr32  (· ||| ·) = true := by decide +kernel
theorem bitXor32_correct_on_sample : bwOK bitXor32 (· ^^^ ·) = true := by decide +kernel

/-- `bitNot32` reads only its one operand, so it gets its own driver. -/
def bwNotOK : Bool :=
  bwWords.all fun a =>
    sem bitNot32 (fun i => a.getLsbD i) == (List.range 32).map (fun k => (~~~a).getLsbD k)

theorem bitNot32_correct_on_sample : bwNotOK = true := by decide +kernel

/-! ### NON-VACUITY — the three blocks are genuinely different circuits

*They are built by one constructor from one layout, so the live risk is that a
proof about `and` is silently a proof about `or`. These controls say the three
disagree, and that each rejects the others' specification.* -/

/-- ⛔ **Each block FAILS the other two's specifications.** -/
theorem bw_blocks_are_distinct :
    bwOK bitAnd32 (· ||| ·) = false ∧ bwOK bitAnd32 (· ^^^ ·) = false
      ∧ bwOK bitOr32 (· &&& ·) = false ∧ bwOK bitXor32 (· &&& ·) = false := by
  decide +kernel

/-- And they disagree on a concrete pair, so the distinction is a value and not
merely a failed check. -/
theorem bw_disagree_concretely :
    sem bitAnd32 (bwEnv 0xAAAAAAAA 0x55555555)
      ≠ sem bitOr32 (bwEnv 0xAAAAAAAA 0x55555555) := by
  decide +kernel

/-- ⛔ **`bitNot32` is not the identity** — the control that a `.not` mistyped as
a pass-through would fail. -/
theorem bitNot32_is_not_identity :
    sem bitNot32 (fun i => (0xDEADBEEF : BitVec 32).getLsbD i)
      ≠ (List.range 32).map (fun k => (0xDEADBEEF : BitVec 32).getLsbD k) := by
  decide +kernel

/-! ## `slt` and `sltu` — the two DERIVED results

*`aluSelect` results 5 and 6. They are not pointwise and they are not new
arithmetic: both fall out of the subtraction `adder32` already computes as
`a + ~b + 1` (which is what `bitNot32` above is for).*

```
sltu a b  =  ¬cout                       unsigned: the borrow IS the comparison
ovf       =  (a31 ⊕ b31) ∧ (a31 ⊕ s31)   subtraction overflows when the operands
                                         differ in sign and the result takes b's
slt  a b  =  s31 ⊕ ovf                   signed: the sign, corrected for overflow
```

⚠️ **RISC-V `SLT`/`SLTU` write a full word — `1` or `0` — so bits 1…31 are a
shared constant, not a copy of anything.** *One `const` gate for the whole block,
the same trick `readTree` uses for `x0`.*

📌 **AND THE CERTIFICATES BELOW DRIVE THESE THROUGH `adder32` ITSELF rather than
through a hand-derived carry.** *Deriving the carry by hand in the test would be
assuming exactly the relationship under test; running the real adder and taking
its 33rd output is an independent computation of the same quantity.* -/

/-- Inputs: `a31`, `b31`, `s31` (the subtraction's sign bit). -/
def sltCirc : Circ :=
  { nIn   := 3
    gates :=
      [ ⟨3, .xor 0 1⟩        -- a31 ⊕ b31
      , ⟨4, .xor 0 2⟩        -- a31 ⊕ s31
      , ⟨5, .and 3 4⟩        -- overflow
      , ⟨6, .xor 2 5⟩        -- slt = s31 ⊕ ovf
      , ⟨7, .const false⟩ ]
    outs  := 6 :: List.replicate 31 7 }

/-- Input: the subtraction's carry-out. -/
def sltuCirc : Circ :=
  { nIn   := 1
    gates := [⟨1, .not 0⟩, ⟨2, .const false⟩]
    outs  := 1 :: List.replicate 31 2 }

theorem sltCirc_ssa  : sltCirc.ssa  = true := by decide +kernel
theorem sltuCirc_ssa : sltuCirc.ssa = true := by decide +kernel
theorem sltCirc_wf   : sltCirc.wf   = true := Circ.wf_of_ssa sltCirc_ssa
theorem sltuCirc_wf  : sltuCirc.wf  = true := Circ.wf_of_ssa sltuCirc_ssa

/-- `a - b` through the REAL adder: `a + ~b + 1`. Outputs `0…31` are the
difference; output `32` is the carry-out. -/
def subOut (a b : BitVec 32) : List Bool :=
  sem adder32 (fun i =>
    if i < 32 then a.getLsbD i
    else if i < 64 then !(b.getLsbD (i - 32))
    else true)

def sltDrive (a b : BitVec 32) : List Bool :=
  sem sltCirc (fun i =>
    if i == 0 then a.getLsbD 31
    else if i == 1 then b.getLsbD 31
    else (subOut a b).getD 31 false)

def sltuDrive (a b : BitVec 32) : List Bool :=
  sem sltuCirc (fun _ => (subOut a b).getD 32 false)

/-- The word: bit 0 carries the answer, bits 1…31 are zero. -/
def cmpWord (r : Bool) : List Bool := r :: List.replicate 31 false

/-- ⭐ **The subtraction path really is a subtraction** — checked before the
comparators are, so a failure downstream cannot be blamed on it. -/
def subOK : Bool :=
  bwWords.all fun a => bwWords.all fun b =>
    (subOut a b).take 32 == (List.range 32).map (fun k => (a - b).getLsbD k)

theorem sub_via_adder_correct_on_sample : subOK = true := by decide +kernel

def sltOK  : Bool := bwWords.all fun a => bwWords.all fun b =>
  sltDrive a b == cmpWord (BitVec.slt a b)
def sltuOK : Bool := bwWords.all fun a => bwWords.all fun b =>
  sltuDrive a b == cmpWord (BitVec.ult a b)

/-- ⭐ **Signed comparison, against `BitVec.slt`**, driven through the real adder. -/
theorem sltCirc_correct_on_sample : sltOK = true := by decide +kernel
/-- ⭐ **Unsigned comparison, against `BitVec.ult`.** -/
theorem sltuCirc_correct_on_sample : sltuOK = true := by decide +kernel

/-! ### NON-VACUITY — signed and unsigned must DISAGREE

*The spread contains `0x80000000` and `1`, which is exactly the pair that
separates them: as signed, `0x80000000` is the most negative word; as unsigned it
is the largest. A `slt` that silently computed `sltu` would pass every test that
did not include such a pair.* -/

/-- ⛔ **`slt` and `sltu` disagree on `(0x80000000, 1)`** — so the overflow
correction is doing real work and is not decoration. -/
theorem slt_differs_from_sltu :
    sltDrive 0x80000000 1 ≠ sltuDrive 0x80000000 1 := by decide +kernel

/-- ⛔ **…and neither block satisfies the other's specification.** -/
theorem cmp_blocks_are_distinct :
    (bwWords.all fun a => bwWords.all fun b => sltDrive a b == cmpWord (BitVec.ult a b)) = false
      ∧ (bwWords.all fun a => bwWords.all fun b =>
           sltuDrive a b == cmpWord (BitVec.slt a b)) = false := by
  decide +kernel

/-- The upper 31 bits really are constant zero — `SLT` writes a word, not a bit. -/
theorem cmp_upper_bits_are_zero :
    (sltDrive 0x80000000 1).drop 1 = List.replicate 31 false
      ∧ (sltuDrive 1 0x80000000).drop 1 = List.replicate 31 false := by
  decide +kernel

#audit_axioms sltCirc sltuCirc
#audit_axioms sltCirc_ssa sltuCirc_ssa sltCirc_wf sltuCirc_wf
#audit_axioms subOut sltDrive sltuDrive cmpWord
#audit_axioms subOK sub_via_adder_correct_on_sample
#audit_axioms sltOK sltuOK sltCirc_correct_on_sample sltuCirc_correct_on_sample
#audit_axioms slt_differs_from_sltu
#audit_axioms cmp_blocks_are_distinct
#audit_axioms cmp_upper_bits_are_zero


/-! ### Compatibility aliases — the OLD names, kept so no other seat's file breaks

*Math's `Stack/Program.lean` imports four of these under their previous names.
Renaming without an alias would have broken another seat's build in a shared
worktree, which is the hazard the writer-slot law exists to prevent.*

⚠️ **These are the MISLEADING names and they are deliberately not the primary
ones.** *Drop them once `Program.lean` migrates; that is math's call and their
file.* -/

alias bitXor32_correct := bitXor32_correct_on_sample
alias sub_via_adder_correct := sub_via_adder_correct_on_sample
alias sltCirc_correct := sltCirc_correct_on_sample
alias sltuCirc_correct := sltuCirc_correct_on_sample

#audit_axioms bwCirc bitAnd32 bitOr32 bitXor32 bitNot32
#audit_axioms bitAnd32_ssa bitOr32_ssa bitXor32_ssa bitNot32_ssa
#audit_axioms bitAnd32_wf bitOr32_wf bitXor32_wf bitNot32_wf
#audit_axioms bw_gate_counts
#audit_axioms bwEnv bwWords bwOK bwNotOK
#audit_axioms bitAnd32_correct_on_sample bitOr32_correct_on_sample bitXor32_correct_on_sample bitNot32_correct_on_sample
#audit_axioms bw_blocks_are_distinct
#audit_axioms bw_disagree_concretely
#audit_axioms bitNot32_is_not_identity

end SaltWorks.HDL
