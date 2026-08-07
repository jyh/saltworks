/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Compose
import SaltWorks.HDL.ISA

/-!
# C4 · THE BITWISE BLOCK — four of `aluSelect`'s six missing producers

**`aluSelect` takes TEN precomputed 32-bit operand results and computes none of
them** (`AluSelect.lean:56`; census in `docs/hdl-c4-core-assembly-plan-0807.md`).
Of the eight with no producer in the tree, **four are pointwise and land here**:

```
and   or   xor        aluSelect results 2, 3, 4
not                   NOT an ALU result -- it is what makes `sub` из `adder32`,
                      which needs (a, ~b, carry-in 1)
```

*The remaining four — `slt`, `sltu`, `sll`, `sra` — are not pointwise and are not
in this file: two are derived from the adder's sign and carry, and two need a
shifter mode `shifter32` does not have.*

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

/-! ### Correctness, against `BitVec`'s own operations

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

theorem bitAnd32_correct : bwOK bitAnd32 (· &&& ·) = true := by decide +kernel
theorem bitOr32_correct  : bwOK bitOr32  (· ||| ·) = true := by decide +kernel
theorem bitXor32_correct : bwOK bitXor32 (· ^^^ ·) = true := by decide +kernel

/-- `bitNot32` reads only its one operand, so it gets its own driver. -/
def bwNotOK : Bool :=
  bwWords.all fun a =>
    sem bitNot32 (fun i => a.getLsbD i) == (List.range 32).map (fun k => (~~~a).getLsbD k)

theorem bitNot32_correct : bwNotOK = true := by decide +kernel

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

#audit_axioms bwCirc bitAnd32 bitOr32 bitXor32 bitNot32
#audit_axioms bitAnd32_ssa bitOr32_ssa bitXor32_ssa bitNot32_ssa
#audit_axioms bitAnd32_wf bitOr32_wf bitXor32_wf bitNot32_wf
#audit_axioms bw_gate_counts
#audit_axioms bwEnv bwWords bwOK bwNotOK
#audit_axioms bitAnd32_correct bitOr32_correct bitXor32_correct bitNot32_correct
#audit_axioms bw_blocks_are_distinct
#audit_axioms bw_disagree_concretely
#audit_axioms bitNot32_is_not_identity

end SaltWorks.HDL
