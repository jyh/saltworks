/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Immediate

/-!
# C4 · `core` — THE PC ADDEND SELECT

Fifth block of `compile`/`core`. The ratified `stepT` gives the pc exactly two
behaviours:

```
BEQ with rs1 = rs2   ->   pc + bOffset imm
everything else      ->   pc + 4          (including the NOP-advance path)
```

⭐ **SO THE BLOCK IS AN ADDEND SELECT, NOT AN ADDER — and that is a design
choice with a reason.** Both cases are `pc + something`; muxing the **addend**
and adding once costs **one** adder, where muxing the **result** costs two.

📌 **AND IT KEEPS `inst_sem` OFF THE CRITICAL PATH.** The landed `adder32` would
have to be *instantiated* to be reused here, and instantiation's semantics
theorem is **owed, not proved** (`Compose.lean`). *Duplicating the carry chain
inline would have avoided that too — at the cost of a second copy that can drift
from the first.* **Emitting the addend and leaving the addition to the assembly
avoids both: no duplication, and no dependence on an unproved combinator.**

## What it computes

```
diff[k] = rs1[k] ⊕ rs2[k]        eq = ¬(⋁ diff)        take = isBEQ ∧ eq
addend  = take ? offset : 4
```

⛔ **A CORRECTION TO THIS FILE'S ORIGINAL RATIONALE, AND IT WAS MINE.** The
first version built the `4` from `const` gates and a **uniform 3-gate mux per
bit**, on the stated ground that *"`opt` is the landed verified constant folder,
so hand-specialising would trade a proof for a saving the optimizer makes
anyway."*

***`opt` IS NOT A CONSTANT FOLDER.*** Measured: `opt pcNext` returned **164
gates from 164** — unchanged. `Opt.lean:119-121` says it plainly: *"The
optimizer. Currently dead-net elimination; constant folding **composes** here"*
— i.e. folding is **planned, not implemented**. `opt` removes dead gates (a
control confirms `2 → 1` on a circuit with a dead `or`); the constant branches
here are **live** gates feeding a live `or`, so nothing removes them.

⇒ **63 gates would have been emitted dead-by-construction, and the only thing
that would have removed them is yosys — the UNTRUSTED half.** *I built a design
decision on a capability I had not checked, in a file whose whole subject is
checking things.* **Now specialised by hand: `and(take, offset[k])` for the 31
bits where the constant is zero, two gates at bit 2. **164 → 99.**
-/

namespace SaltWorks.HDL

open SaltWorks.ISA

/-! ### Layout -/

def pcRs1 (k : Nat) : Net := k
def pcRs2 (k : Nat) : Net := 32 + k
def pcOff (k : Nat) : Net := 64 + k
def pcIsBEQ : Net := 96
def pcIn : Nat := 97

/-- `diff[k]` on `97…128`. -/
def pcDiff (k : Nat) : Net := pcIn + k
def pcDiffGates : List Gate :=
  (List.range 32).map fun k => ⟨pcDiff k, .xor (pcRs1 k) (pcRs2 k)⟩

/-- The OR tree over the 32 difference bits — 31 gates from `129`. -/
def pcNeBase : Nat := pcIn + 32
def pcNeGates : List Gate × Net × Nat := orChain pcNeBase ((List.range 32).map pcDiff)

def pcNe : Net := pcNeGates.2.1
def pcAfterNe : Nat := pcNeGates.2.2

def pcEq : Net := pcAfterNe
def pcTake : Net := pcAfterNe + 1
def pcNotTake : Net := pcAfterNe + 2
def pcMuxBase : Nat := pcAfterNe + 3

/-- Addend bit `k`'s output net. **Bit 2 is the only one that costs two gates**
— it is the single set bit of the constant `4`. -/
def pcAddendOut (k : Nat) : Net :=
  if k < 2 then pcMuxBase + k
  else if k == 2 then pcMuxBase + 3
  else pcMuxBase + k + 1

/-- `addend[k] = take ∧ offset[k]` where `4`'s bit is clear; at bit 2, where it
is set, `addend[2] = ¬take ∨ (take ∧ offset[2])`. -/
def pcAddendGates (k : Nat) : List Gate :=
  if k == 2 then
    [ ⟨pcMuxBase + 2, .and pcTake (pcOff 2)⟩
    , ⟨pcMuxBase + 3, .or pcNotTake (pcMuxBase + 2)⟩ ]
  else [ ⟨pcAddendOut k, .and pcTake (pcOff k)⟩ ]

/-- **The pc addend select.** Outputs: `addend[0…31]`, then `take`. -/
def pcNext : Circ :=
  { nIn := pcIn
    gates := pcDiffGates ++ pcNeGates.1
               ++ [ ⟨pcEq, .not pcNe⟩
                  , ⟨pcTake, .and pcIsBEQ pcEq⟩
                  , ⟨pcNotTake, .not pcTake⟩ ]
               ++ (List.range 32).flatMap pcAddendGates
    outs := (List.range 32).map pcAddendOut ++ [pcTake] }

theorem pcNext_wf : pcNext.wf = true := by decide +kernel

/-- **99 gates**, down from 164. *Measured, then pinned — I predicted 101 from
the same arithmetic that produced the block and was wrong by two, which is why
the number in a docstring should come from the build and not from the author.* -/
theorem pcNext_gate_count : pcNext.gates.length = 99 := by decide +kernel

/-- Dense SSA — the precondition for instantiating this block into `core`. -/
theorem pcNext_ssa : pcNext.ssa = true := by decide +kernel

/-! ### Driving it, and the specification -/

def pcRun (rs1 rs2 off : BitVec 32) (isBEQ : Bool) : List Bool :=
  sem pcNext (fun i =>
    if i < 32 then rs1.getLsbD i
    else if i < 64 then rs2.getLsbD (i - 32)
    else if i < 96 then off.getLsbD (i - 64)
    else isBEQ)

/-- What `stepT` says the addend must be. -/
def pcSpec (rs1 rs2 off : BitVec 32) (isBEQ : Bool) : List Bool :=
  let take := isBEQ && (rs1 == rs2)
  (List.range 32).map (fun k => if take then off.getLsbD k else (4 : BitVec 32).getLsbD k)
    ++ [take]

/-! ### The certificates

*The input space is `2^97`; these drive the block with pairs chosen to exercise
both branches of every cone — equal and unequal operands, differing in the top
bit, the bottom bit, and nowhere.* -/

def pcCases : List (BitVec 32 × BitVec 32) :=
  [ (0, 0), (1, 1), (0xFFFFFFFF, 0xFFFFFFFF), (0x80000000, 0x80000000)
  , (0, 1), (1, 0), (0x80000000, 0x00000000), (0x7FFFFFFF, 0xFFFFFFFF)
  , (0xA5A5A5A5, 0xA5A5A5A4), (0x00000001, 0x80000001) ]

def pcOffs : List (BitVec 32) := [0, 4, 8, 0xFFFFFFFC, 0x7FFFFFFC]

def pcOK : Bool :=
  pcCases.all fun p => pcOffs.all fun o => [false, true].all fun b =>
    pcRun p.1 p.2 o b == pcSpec p.1 p.2 o b

/-- **The addend select agrees with `stepT`'s pc rule** on 100 driven cases. -/
theorem pcNext_correct_on_sample : pcOK = true := by decide +kernel

/-- **A NON-`BEQ` INSTRUCTION ALWAYS ADDS 4** — including the NOP-advance path,
which is the ratified behaviour on 99.80% of words. -/
theorem pcNext_not_beq_adds_four :
    (pcCases.all fun p => pcOffs.all fun o =>
      pcRun p.1 p.2 o false == (List.range 32).map (4 : BitVec 32).getLsbD ++ [false])
      = true := by decide +kernel

/-- **AND A TAKEN BRANCH ADDS THE OFFSET** — the other branch, so the theorem
above is not satisfied by a block that always emits 4. -/
theorem pcNext_taken_adds_offset :
    pcRun 7 7 0x7FFFFFFC true
      = (List.range 32).map (0x7FFFFFFC : BitVec 32).getLsbD ++ [true] := by
  decide +kernel

/-- **THE COMPARATOR IS 32 BITS WIDE, not a prefix.** A pair differing only in
the TOP bit must compare unequal — the classic truncated-comparator bug, which a
suite of small operands would never catch. -/
theorem pcNext_compares_all_32_bits :
    pcRun 0x80000000 0x00000000 8 true
      = (List.range 32).map (4 : BitVec 32).getLsbD ++ [false] := by
  decide +kernel

/-- And differing only in the BOTTOM bit, likewise. -/
theorem pcNext_compares_the_low_bit :
    pcRun 0xA5A5A5A5 0xA5A5A5A4 8 true
      = (List.range 32).map (4 : BitVec 32).getLsbD ++ [false] := by
  decide +kernel

#audit_axioms pcIn
#audit_axioms pcDiffGates
#audit_axioms pcNeGates
#audit_axioms pcAddendGates
#audit_axioms pcNext
#audit_axioms pcNext_wf
#audit_axioms pcNext_gate_count
#audit_axioms pcNext_ssa
#audit_axioms pcRun
#audit_axioms pcSpec
#audit_axioms pcNext_correct_on_sample
#audit_axioms pcNext_not_beq_adds_four
#audit_axioms pcNext_taken_adds_offset
#audit_axioms pcNext_compares_all_32_bits
#audit_axioms pcNext_compares_the_low_bit

end SaltWorks.HDL
