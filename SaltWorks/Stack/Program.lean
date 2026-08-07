/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Stack.Spec
import SaltWorks.Stack.Perm
import SaltWorks.Stack.ZeroOne

/-!
# STACK-S2 — THE PROGRAM: an agent-written bitonic sort in Slice A

This is the application the STACK campaign runs on the verified tower: Batcher's
bitonic sorting network at `n = 8`, fully unrolled, as a straight-line `List
Instr` in the five-instruction Slice A subset, assembled to RV32I words by
`SaltWorks.ISA.encode`.

## ⭐ AUTHORSHIP — this is part of the artifact, not a footnote

The campaign's claim is *"unverified agent → verified code → verified compiler →
verified silicon."* The first link is a claim about **provenance**, so the
provenance is a deliverable and is recorded here rather than in a changelog.

**Everything below this docstring was written by an AI agent** (Claude, Opus
tier, one session, 2026-08-07) working from a written brief. Specifically:

* **Written by the agent, by hand:** `cmpEx` — the five-instruction
  compare-exchange block, including the choice of the 3-XOR swap (Slice A has no
  temporary-free alternative and no `SUB`), the register allocation (`x1`–`x8`
  data, `x9` scratch, `x0` as the `BEQ` comparand), and the branch immediate.
* **Derived, not written:** the 24-comparator order. `batcherSort` is
  `batcher8.flatMap cmpEx` — the program is *emitted from the same
  `SaltWorks.Stack.batcher8` literal that math already proved sorts*
  (`batcher8_sorts_bool`). No comparator was transcribed by hand, so the
  correspondence between the abstract network and the program is **structural**
  rather than a coincidence S3(b) would have to re-establish. `emit` is generic
  in the network; nothing here is specialised to `batcher8` except
  `batcherSort` itself.
* **Checked by the kernel, not by the agent:** every numeric claim in this file.

### ⭐ WHAT THE AGENT GOT WRONG

**The branch immediate.** The brief specified `BEQ t, x0, +3` with the note
*"skipping 3 instructions (12 bytes) needs `imm = 6`, not 12"*. **That is wrong,
and the agent's first draft used it.** `step`'s `BEQ` case adds `bOffset imm` to
the pc **of the branch itself**, and `bOffset imm = 2 * imm`, so skipping the
three `XOR`s that follow the branch needs `2 * imm = 16`, i.e. **`imm = 8`**.
`imm = 6` lands *on the third `XOR`*, which then executes alone — turning the
compare-exchange into a corruption. Both halves are pinned below
(`skip_immediate_is_eight`, `skip_immediate_six_is_wrong`), and
`offset_six_does_not_sort` shows the resulting program provably fails the spec.

The failure mode is the one the brief itself warned about and is worth restating:
**`run` is total, so a wrong branch is silent.** A truncated run and a completed
run are the same *kind* of value; nothing errors. The only defence is a
certificate, which is why the wrong immediate is committed here as a theorem
rather than deleted.

**A near-miss of the agent's own making.** The first draft of `branchIsForward`
tested `0 < imm.toNat`. That check is **vacuous** — a backward immediate has a
large *positive* `toNat` (`-2` is `4094`), so it would have passed every
backward branch. This is S1's signed/unsigned trap (`Stack/Spec.lean`) recurring
one layer up, and it is pinned as `forwardness_must_be_signed`.

**Two tooling misreadings**, recorded for completeness and of no consequence:
`fin_cases` is not in scope in this import set (a redundant lemma was dropped),
and `decide` cannot close a `List.ofFn` goal containing a free variable
(`List.ofFn_succ` does).

## Why the compare-exchange MUST branch

Slice A is exactly `ADD, ADDI, XOR, SLT, BEQ` (`ISA.lean:80–93`) — verified by
reading the constructor list, not assumed. There is **no `AND`, no `OR`, no
`SUB`, and no shift instruction**; the single `<<<` in `ISA.lean` is inside
`bOffset`, which is the immediate's own scaling and not something a program can
execute. The standard branchless compare-exchange builds a mask from the
comparison and *ands* it against the difference; without `AND` the mask cannot be
applied, and without `SUB` there is no difference to apply it to. So the
branchless form is not merely less clean here — **it is not expressible**, and
the block below branches by necessity.

## Why every branch must be FORWARD

`run`'s use of `code.length` as a sufficient step bound rests on the sentence at
`ISA.lean:149`: *"every branch the code generator emits is forward, so `pc`
strictly increases."* That sentence is **prose — it is not a hypothesis, and no
predicate enforces it** (S0/R2 confirmed this, and `ISA.beq_offset_can_be_negative`
shows the machine can violate it). A backward branch would not error; `runFor`
would simply exhaust its bound mid-program and return a state that looks exactly
like a finished one.

This file therefore states forwardness as a checkable property and proves it
**structurally, for every network**, not just for `batcher8`:
`emit_branches_forward` says every instruction `emit` ever produces passes
`branchIsForward`. The concrete corollary is `batcherSort_branches_forward`. On
top of that, every concrete run below asserts `pc = 480 = 4 * 120` — the pc
**off the end of the program** — which is a direct receipt that the run was not
truncated.

## The register story: in place, as `SortsRegs` assumes

Data lives in `x1`–`x8` (wire `i` ↦ register `i+1`), the same eight registers
before and after — a register-resident network sorts in place by construction,
since the 3-XOR swap writes back to the pair it read. That is exactly what
`SortsRegs` assumes, so there is no mismatch to report. `x9` is scratch for the
`SLT` result and is clobbered; it is deliberately *not* in `dataRegs`, and
`SortsRegs` says nothing about it, which is the honest content. `x0` is never a
data register and never a temporary — it is only ever the `BEQ` comparand, where
`St.get_zero` makes it a reliable constant zero.

## What this file does NOT do

**It does not prove the program sorts.** That is S3(b). The obligation is
*stated* here as `SortsAllInputs`, and — this is the one piece of real leverage
the file adds — it is **reduced** to a refinement obligation against math's
abstract network: `sortsAllInputs_of_refinesNetwork` proves

  `RefinesNetwork → SortsAllInputs`

outright, by composing with `Stack.batcher8_sortsTo_word` (already landed). So
S3(b) never has to argue about sortedness or permutation at all; it has to prove
that 120 instructions under `step` compute what `runNetW batcher8` computes. The
sorting half is already done, and the two halves meet at the *same network
literal*.
-/

namespace SaltWorks.Stack.Program

open SaltWorks.ISA SaltWorks.Stack

/-! ## Register allocation -/

/-- Wire `i` of the network lives in register `x(i+1)`. Never `x0`: a write to
`x0` is discarded (`ISA.St.set_zero`), so a data wire mapped there would be a
silent no-op — the freeze's P5. -/
def dataReg (i : Fin 8) : Fin 32 := ⟨i.val + 1, by have := i.isLt; omega⟩

/-- The scratch register holding the `SLT` result. Not a data register, so it is
outside `dataRegs` and the spec says nothing about it. -/
def tmpReg : Fin 32 := 9

/-- The eight data registers, in wire order — the `rs` argument `SortsRegs`
takes. Read from the same eight registers before and after: the sort is in
place. -/
def dataRegs : List (Fin 32) := [1, 2, 3, 4, 5, 6, 7, 8]

/-- `dataRegs.map` and `List.ofFn ∘ dataReg` are the same read, definitionally.
The bridge between the spec's `List`-of-registers view and the network's
`Fin 8 → Word` view, and it costs nothing. -/
theorem dataRegs_map_get (s : St) :
    dataRegs.map s.get = List.ofFn (fun i : Fin 8 => s.get (dataReg i)) := rfl

/-! ## The branch immediate

Derived from `step`, not from prose. See the authorship record above. -/

/-- The immediate that skips the three `XOR`s of a compare-exchange.

`bOffset imm = (imm.signExtend 32) <<< 1 = 2 * imm`, added to the pc **of the
branch**. Branch at `p`; the `XOR`s at `p+4`, `p+8`, `p+12`; the next block at
`p+16`. So `2 * imm = 16` and `imm = 8`. -/
def skipImm : BitVec 12 := 8

/-- `bOffset skipImm` is sixteen bytes — four instructions from the branch's own
address, i.e. the three `XOR`s skipped. -/
theorem bOffset_skipImm : bOffset skipImm = 16 := by decide +kernel

/-- ⭐ **THE IMMEDIATE, CERTIFIED.** `imm = 8` skips exactly three instructions:
the three that would have run are provably untouched, the fourth runs, and the
run ends off the end of the code. -/
theorem skip_immediate_is_eight :
    let code : List Instr :=
      [.BEQ 0 0 skipImm, .ADDI 1 0 11, .ADDI 2 0 22, .ADDI 3 0 33, .ADDI 4 0 44]
    let s := run code St.init
    s.get 1 = 0 ∧ s.get 2 = 0 ∧ s.get 3 = 0 ∧ s.get 4 = 44 ∧ s.pc = 20 := by
  decide +kernel

/-- ⚠️ **AND THE BRIEF'S NUMBER, CERTIFIED WRONG.** `imm = 6` lands *on* the
third instruction, which then executes. Committed rather than deleted: this is
the shape of the off-by-one, and `run`'s totality means nothing else would ever
report it. -/
theorem skip_immediate_six_is_wrong :
    let code : List Instr :=
      [.BEQ 0 0 6, .ADDI 1 0 11, .ADDI 2 0 22, .ADDI 3 0 33, .ADDI 4 0 44]
    (run code St.init).get 3 = 33 := by
  decide +kernel

/-- **The branch advances the pc either way.** Taken it moves `+16`, not taken
`+4`; both are forward, and neither depends on the data. -/
theorem beq_skipImm_advances (s : St) (a b : Fin 32) :
    (step s (.BEQ a b skipImm)).pc = s.pc + 16 ∨
      (step s (.BEQ a b skipImm)).pc = s.pc + 4 := by
  by_cases h : s.get a = s.get b
  · exact Or.inl (by simp [step, h, bOffset_skipImm])
  · exact Or.inr (by simp [step, h, St.next])

/-! ## The compare-exchange block -/

/-- ⭐ **THE COMPARE-EXCHANGE**, five instructions, written by hand.

For comparator `(c.1, c.2)`: the low slot `a` must end holding the `min` and the
high slot `b` the `max`. `SLT t, b, a` sets `t = 1` exactly when `b <ₛ a`, i.e.
exactly when the pair is out of order; `BEQ t, x0` is then taken when `t = 0`
(already ordered) and skips the swap.

The swap is the classical 3-XOR, which needs no temporary — and Slice A gives no
choice: with only 32 registers and no `SUB`, a temporary-based swap costs an
extra live register per comparator for no benefit. It is correct exactly when
`a ≠ b`, which holds for every comparator of `batcher8` (no self-comparators).

`SLT` is **signed**, which is what makes this program meet S1's `wle` order
rather than `BitVec`'s unsigned `≤`. -/
def cmpEx (c : Comparator 8) : List Instr :=
  let a := dataReg c.1
  let b := dataReg c.2
  [ .SLT tmpReg b a,          -- t := (b <ₛ a) — out of order?
    .BEQ tmpReg 0 skipImm,    -- t = 0 ⇒ ordered ⇒ skip the swap.  FORWARD, +16.
    .XOR a a b,               -- a := a ^ b
    .XOR b a b,               -- b := (a^b) ^ b = old a
    .XOR a a b ]              -- a := (a^b) ^ old a = old b

theorem cmpEx_length (c : Comparator 8) : (cmpEx c).length = 5 := rfl

/-- **The emitter**, generic in the network. Nothing here knows about
`batcher8`. -/
def emit (net : Network 8) : List Instr := net.flatMap cmpEx

/-- The program is five instructions per comparator — so its length is a fact
about the *network*, not a number anyone counted. -/
theorem emit_length (net : Network 8) : (emit net).length = 5 * net.length := by
  induction net with
  | nil => rfl
  | cons c cs ih =>
      simp only [emit, List.flatMap_cons, List.length_append, cmpEx_length,
        List.length_cons] at ih ⊢
      omega

/-! ## Forwardness -/

/-- Is this instruction's branch forward? Non-branches trivially pass.

⚠️ `imm.toInt`, **not** `imm.toNat`: see `forwardness_must_be_signed`. -/
def branchIsForward : Instr → Bool
  | .BEQ _ _ imm => 0 < imm.toInt
  | _            => true

/-- ⚠️ **THE VACUOUS CHECK, PINNED.** A backward immediate has a large positive
`toNat`, so `0 < imm.toNat` accepts it. `branchIsForward` must read the
immediate signed or it checks nothing at all. -/
theorem forwardness_must_be_signed :
    (0 : Int) < ((BitVec.ofInt 12 (-2)).toNat : Int) ∧
      ¬ ((0 : Int) < (BitVec.ofInt 12 (-2)).toInt) := by
  decide +kernel

/-- Every instruction of a compare-exchange block is forward — by cases on the
five, so it is a property of the block's *shape*. -/
theorem cmpEx_branches_forward (c : Comparator 8) :
    ∀ i ∈ cmpEx c, branchIsForward i = true := by
  intro i hi
  simp only [cmpEx, List.mem_cons, List.not_mem_nil, or_false] at hi
  rcases hi with rfl | rfl | rfl | rfl | rfl <;> rfl

/-- ⭐ **EVERY BRANCH THIS EMITTER EVER PRODUCES IS FORWARD** — for every network,
not merely for `batcher8`. This is the hypothesis `run`'s `code.length` bound
rests on, discharged for the whole family of programs this file can generate. -/
theorem emit_branches_forward (net : Network 8) :
    ∀ i ∈ emit net, branchIsForward i = true := by
  intro i hi
  rw [emit, List.mem_flatMap] at hi
  obtain ⟨c, _, hc⟩ := hi
  exact cmpEx_branches_forward c i hc

/-! ## ⭐ The program -/

/-- ⭐ **THE PROGRAM.** Batcher's bitonic sort on eight registers, in Slice A,
fully unrolled: 120 instructions, no loop, no memory, no `sorry`.

Emitted from `SaltWorks.Stack.batcher8` — *the same literal* that
`batcher8_sorts_bool` proves sorts. -/
def batcherSort : List Instr := emit batcher8

/-- 120 = 5 × 24, and the 24 is `batcher8_length`. -/
theorem batcherSort_length : batcherSort.length = 120 := by
  rw [batcherSort, emit_length, batcher8_length]

theorem batcherSort_branches_forward :
    ∀ i ∈ batcherSort, branchIsForward i = true := emit_branches_forward batcher8

/-! ## The assembled words

`encode` is total on Slice A and `decode_encode` inverts it, so the word list
below is the program with nothing lost — which is what the differential harness
(kill-check K2b) hands to a third-party RV32I simulator. -/

/-- **The program as RV32I machine words.** -/
def batcherSortWords : List (BitVec 32) := batcherSort.map encode

theorem batcherSortWords_length : batcherSortWords.length = 120 := by
  rw [batcherSortWords, List.length_map, batcherSort_length]

/-- **The assembly loses nothing.** Structural, from `decode_encode` — not an
enumeration over 120 words. -/
theorem decode_batcherSortWords :
    batcherSortWords.map decode = batcherSort.map some := by
  simp [batcherSortWords, List.map_map, Function.comp_def, decode_encode]

/-- **The first block, as real machine words**, hand-checked against the RV32I
manual's field layout and then kernel-checked:

```
001124b3   slt  x9, x2, x1
00048863   beq  x9, x0, 16
0020c0b3   xor  x1, x1, x2
0020c133   xor  x2, x1, x2
0020c0b3   xor  x1, x1, x2
```

The `beq` word is the one worth reading: `0x00048863` has bit 8 set, which is
`imm[4]`, which is a byte displacement of 16. -/
theorem batcherSortWords_first_block :
    batcherSortWords.take 5 =
      [0x001124B3#32, 0x00048863#32, 0x0020C0B3#32, 0x0020C133#32, 0x0020C0B3#32] := by
  decide +kernel

/-! ## Concrete runs

`step` and `run` are executable, so a concrete input is a kernel-computable
certificate. **These are checks, not the theorem** — the theorem is
`SortsAllInputs`, which is S3(b) and is not proved here.

Every one of them also asserts `pc = 480 = 4 * 120`: the pc **off the end of the
program**. That is the receipt that the run completed rather than exhausting
`run`'s bound part-way, which is the failure a backward branch would cause and
which is otherwise invisible. -/

/-- Load eight words into the data registers. -/
def stOfFn (v : Fin 8 → Word) : St :=
  ((((((((St.init.set 1 (v 0)).set 2 (v 1)).set 3 (v 2)).set 4 (v 3)).set 5
    (v 4)).set 6 (v 5)).set 7 (v 6)).set 8 (v 7))

/-- The loader loads: reading the data registers back gives the vector. -/
theorem dataRegs_map_stOfFn (v : Fin 8 → Word) :
    dataRegs.map (stOfFn v).get = List.ofFn v := by
  simp [dataRegs, stOfFn, St.get, St.set, List.ofFn_succ, List.ofFn_zero]

/-- **Mixed signs.** S1's own witness vector. Signed-sorted, and it would come
out differently under the unsigned order — see `run_mixed_not_unsigned_sorted`. -/
theorem run_mixed :
    let s := run batcherSort (stOfFn ![3, -1, 7, 0, -5, 2, 9, -2])
    dataRegs.map s.get = [-5, -2, -1, 0, 2, 3, 7, 9] ∧ s.pc = 480 := by
  decide +kernel

/-- ⭐ **AND THE OUTPUT IS NOT UNSIGNED-SORTED.** The program computes the signed
order, demonstrably — `-5` is `0xFFFFFFFB`, the *largest* word unsigned. If
`SLT` were ever silently replaced by an unsigned compare, this fails. -/
theorem run_mixed_not_unsigned_sorted :
    ¬ List.Pairwise (· ≤ · : Word → Word → Prop)
        (dataRegs.map (run batcherSort (stOfFn ![3, -1, 7, 0, -5, 2, 9, -2])).get) := by
  decide +kernel

/-- **Already sorted** — the identity case, and the strongest forwardness
receipt in the file: no comparator swaps, so **all 24 branches are taken**. If a
single one of them were backward the run would not reach `pc = 480`. -/
theorem run_already_sorted :
    let s := run batcherSort (stOfFn ![-5, -2, -1, 0, 2, 3, 7, 9])
    dataRegs.map s.get = [-5, -2, -1, 0, 2, 3, 7, 9] ∧ s.pc = 480 := by
  decide +kernel

/-- **Reverse sorted** — the other extreme of the branch-pattern space. -/
theorem run_reverse_sorted :
    let s := run batcherSort (stOfFn ![9, 7, 3, 2, 0, -1, -2, -5])
    dataRegs.map s.get = [-5, -2, -1, 0, 2, 3, 7, 9] ∧ s.pc = 480 := by
  decide +kernel

/-- **All equal** — every comparison is `¬ (a <ₛ a)`, so nothing swaps and the
3-XOR path never runs. -/
theorem run_all_equal :
    let s := run batcherSort (stOfFn ![4, 4, 4, 4, 4, 4, 4, 4])
    dataRegs.map s.get = [4, 4, 4, 4, 4, 4, 4, 4] ∧ s.pc = 480 := by
  decide +kernel

/-- **Duplicates**, interleaved — a sorting network with repeats is where a
`min`/`max` element that dropped a value instead of moving it would show up. -/
theorem run_duplicates :
    let s := run batcherSort (stOfFn ![2, 1, 2, 1, 2, 1, 2, 1])
    dataRegs.map s.get = [1, 1, 1, 1, 2, 2, 2, 2] ∧ s.pc = 480 := by
  decide +kernel

/-- **The signed extremes**, with repeats at both ends: `INT_MIN` and `INT_MAX`.
Unsigned, `INT_MIN = 0x80000000` sorts *above* `INT_MAX = 0x7FFFFFFF`; signed it
is the least word there is. -/
theorem run_extremes :
    let s := run batcherSort
      (stOfFn ![2147483647, -2147483648, 1, -1, 0, 2147483647, -2147483648, 42])
    dataRegs.map s.get =
      [-2147483648, -2147483648, -1, 0, 1, 42, 2147483647, 2147483647] ∧ s.pc = 480 := by
  decide +kernel

/-! ### ⭐ The program computes what the abstract network computes

Stronger than "the output is sorted": on these inputs the program's registers
equal `runNetW batcher8` — math's own network at S1's signed order — element for
element. This is `RefinesNetwork` at a point, and it is the statement S3(b)
generalises. -/

theorem run_mixed_matches_network :
    dataRegs.map (run batcherSort (stOfFn ![3, -1, 7, 0, -5, 2, 9, -2])).get
      = List.ofFn (runNetW batcher8 ![3, -1, 7, 0, -5, 2, 9, -2]) := by
  decide +kernel

theorem run_reverse_matches_network :
    dataRegs.map (run batcherSort (stOfFn ![9, 7, 3, 2, 0, -1, -2, -5])).get
      = List.ofFn (runNetW batcher8 ![9, 7, 3, 2, 0, -1, -2, -5]) := by
  decide +kernel

theorem run_duplicates_matches_network :
    dataRegs.map (run batcherSort (stOfFn ![2, 1, 2, 1, 2, 1, 2, 1])).get
      = List.ofFn (runNetW batcher8 ![2, 1, 2, 1, 2, 1, 2, 1]) := by
  decide +kernel

/-! ### Non-vacuity: two mutants that provably FAIL

The runs above are worth only as much as the predicate they satisfy. These two
say that `SortsRegs dataRegs s (run · s)` is a property a wrong program can
*fail*, so the positive certificates are not trivially true.

Both mutants are one token away from the real thing, and both build clean. -/

/-- The block with the brief's immediate: `6` instead of `8`. -/
private def cmpEx6 (c : Comparator 8) : List Instr :=
  let a := dataReg c.1
  let b := dataReg c.2
  [ .SLT tmpReg b a, .BEQ tmpReg 0 6, .XOR a a b, .XOR b a b, .XOR a a b ]

/-- ⭐ **THE OFF-BY-ONE IS FATAL AND SILENT.** The `imm = 6` program runs to
completion, returns a perfectly ordinary state, and **does not sort**. Nothing
but a certificate would have caught it. -/
theorem offset_six_does_not_sort :
    ¬ SortsRegs dataRegs (stOfFn ![3, -1, 7, 0, -5, 2, 9, -2])
        (run (batcher8.flatMap cmpEx6) (stOfFn ![3, -1, 7, 0, -5, 2, 9, -2])) := by
  decide +kernel

/-- The block with the `SLT` operands the other way round — `a <ₛ b` instead of
`b <ₛ a`, i.e. swap-when-already-ordered. -/
private def cmpExFlip (c : Comparator 8) : List Instr :=
  let a := dataReg c.1
  let b := dataReg c.2
  [ .SLT tmpReg a b, .BEQ tmpReg 0 skipImm, .XOR a a b, .XOR b a b, .XOR a a b ]

/-- **The comparand order is load-bearing.** Flipping the `SLT` operands gives a
program that also builds, also runs to the end, and does not sort. -/
theorem flipped_comparand_does_not_sort :
    ¬ SortsRegs dataRegs (stOfFn ![3, -1, 7, 0, -5, 2, 9, -2])
        (run (batcher8.flatMap cmpExFlip) (stOfFn ![3, -1, 7, 0, -5, 2, 9, -2])) := by
  decide +kernel

/-! ## ⭐ S3(b) — the obligation, stated and reduced

Not proved here. What *is* done here is the reduction: the sortedness and
permutation halves are already math's, so S3(b) is left with a pure refinement
question about `step`. -/

/-- ⭐ **THE S3(b) OBLIGATION.** From any state, running the program leaves the
eight data registers holding a signed-sorted permutation of what they held
before — in place, on the same eight registers, which is what `SortsRegs`
assumes and what a register-resident network does.

Stated as a `Prop` rather than a `sorry`-ed theorem so that it is committed,
named, and axiom-clean today, and so S3(b) has a target to *prove* rather than a
statement to reinvent. -/
def SortsAllInputs : Prop := ∀ s : St, SortsRegs dataRegs s (run batcherSort s)

/-- ⭐ **THE REFINEMENT OBLIGATION** — what S3(b) should actually prove. The
program under `step` computes what the abstract network computes at the signed
order. Nothing about sortedness appears: this is a statement about 120
instructions and a fold. -/
def RefinesNetwork : Prop :=
  ∀ s : St, dataRegs.map (run batcherSort s).get
          = List.ofFn (runNetW batcher8 (fun i => s.get (dataReg i)))

/-- ⭐ **THE REDUCTION, PROVED.** `RefinesNetwork → SortsAllInputs`.

`batcher8_sortsTo_word` (math's lane, landed) already says the abstract network
takes any word vector to a signed-sorted permutation of it. So S3(b) need never
argue about `SortedW` or `PermW` at all — it inherits both, and the two lanes
meet at the *same* `batcher8` literal because `batcherSort` was emitted from it.

This is the one theorem in this file that does real work. -/
theorem sortsAllInputs_of_refinesNetwork (h : RefinesNetwork) : SortsAllInputs := by
  intro s
  rw [SortsRegs, dataRegs_map_get s, h s]
  exact batcher8_sortsTo_word _

/-! ## Axiom audit -/

open Salt.Tactic

#audit_axioms dataReg tmpReg dataRegs dataRegs_map_get
#audit_axioms skipImm bOffset_skipImm skip_immediate_is_eight
#audit_axioms skip_immediate_six_is_wrong beq_skipImm_advances
#audit_axioms cmpEx cmpEx_length emit emit_length
#audit_axioms branchIsForward forwardness_must_be_signed
#audit_axioms cmpEx_branches_forward emit_branches_forward
#audit_axioms batcherSort batcherSort_length batcherSort_branches_forward
#audit_axioms batcherSortWords batcherSortWords_length decode_batcherSortWords
#audit_axioms batcherSortWords_first_block
#audit_axioms stOfFn dataRegs_map_stOfFn
#audit_axioms run_mixed run_mixed_not_unsigned_sorted run_already_sorted
#audit_axioms run_reverse_sorted run_all_equal run_duplicates run_extremes
#audit_axioms run_mixed_matches_network run_reverse_matches_network
#audit_axioms run_duplicates_matches_network
#audit_axioms offset_six_does_not_sort flipped_comparand_does_not_sort
#audit_axioms SortsAllInputs RefinesNetwork sortsAllInputs_of_refinesNetwork

end SaltWorks.Stack.Program
