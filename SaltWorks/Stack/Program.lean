/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Stack.Spec
import SaltWorks.Stack.Perm
import SaltWorks.Stack.ZeroOne
import SaltWorks.HDL.StateCodec
import SaltWorks.HDL.C4

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

⚠️ **READ THE S3(b) VERDICT SECTION AT THE BOTTOM OF THIS FILE BEFORE USING
`RefinesNetwork` OR `SortsAllInputs`.** Both are `∀ s : St` with nothing said
about `s.pc`, and at a pc off the end of the program `run` is the identity — so
**both are false**, and the refutation is committed
(`refinesNetwork_is_false`, `sortsAllInputs_is_false`). The content S3(b) was
after is proved there from the entry point the program actually has:
`refinesNetwork_of_pc_zero` and `sortsRegs_of_pc_zero`. The two `def`s above are
left exactly as committed; repairing them is a statement change and is not this
node's to make.
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

/-- **Already sorted** — the identity case: the output equals the input, and the
run still reaches `pc = 480`.

⚠️ **This is NOT the all-branches-taken case, although this docstring originally
claimed it was.** `batcher8` contains *descending* comparators (`(3, 2)`,
`(7, 6)`, `(5, 4)`, …), and an ascending input is out of order for every one of
them: **ten of the 24 comparators swap here**, so the run costs 78 ticks rather
than 48. Pinned as `already_sorted_input_still_swaps` below, and the input on
which all 24 branches really are taken is `run_all_equal`. -/
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

/-! ## ⭐ S3(b) — THE VERDICT

**`RefinesNetwork` and `SortsAllInputs`, as committed above, are FALSE.** Not
hard, not open — false, and the refutation is a kernel certificate
(`refinesNetwork_is_false`, `sortsAllInputs_is_false`). Both are stated `∀ s :
St`, and `St` carries a `pc`. Nothing constrains it. At `s.pc = 480` — the pc
**off the end of the program**, which is exactly where every certificate above
proudly ends — `fetch` returns `none` on the first tick, `runFor` returns `s`
unchanged, and the obligation degenerates to *"the eight data registers are
already sorted"*, which is false for any unsorted `s`.

⚠️ **THIS IS THE SAME FAILURE MODE THE FILE ALREADY NAMES ONE LAYER UP.** The
authorship record says *"`run` is total, so a wrong branch is silent"*. The same
totality makes a **wrong starting pc** silent: `run` at a pc outside the code is
not an error, it is the identity, and the identity satisfies nothing. The
statement inherited an entry-point assumption from the concrete runs — every one
of which starts from `stOfFn v`, whose `pc` is `0` — and the assumption was never
written down because in the concrete runs it was never a variable.

The statements above are **left exactly as committed**, per the iron rule. What
is added here is (1) the refutation, so the falsity is a theorem rather than a
note, and (2) the content S3(b) was actually after, proved from the entry point
the program has: `refinesNetwork_of_pc_zero`. Repairing the two `def`s is a
statement change and belongs to the seat that owns them.

## What the proof needed, and why the obvious route does not work

⚠️ **THE STEP COUNT IS DATA-DEPENDENT.** Each comparator is five instructions,
but the `BEQ` skips the three `XOR`s, so an ordered pair costs **2** steps and a
swap costs **5**. Over 24 comparators the real cost runs from **48** (all equal —
every branch taken) to **90** (reverse sorted), while `run` always spends the
same bound of 120; `step_count_data_dependent` pins three of those numbers. So
there is no fixed per-comparator step budget, and no induction that assumes one
can close. **What saves it is that the two paths reconverge**: taken lands at
`base + 20` via `bOffset skipImm = 16`, not-taken walks the three `XOR`s to the
same `base + 20`. The comparator is a 20-byte block with a single exit, and
`cmpEx_block` is that sentence.

Gluing blocks whose step counts differ then needs an algebra for `runFor`'s fuel,
which did not exist. `runFor_add` is it, and it is **unconditional** — no
"enough fuel" side condition — because halting is a fixed point: once `fetch`
returns `none` the state stops changing, so surplus fuel is a no-op
(`runFor_of_fetch_none`). That one observation is what makes the whole
decomposition cheap.
-/

/-! ### The refutation -/

/-- The witness: reverse-sorted data, and a `pc` already off the end of the
program. Nothing in `RefinesNetwork` excludes it. -/
def offEndState : St := { stOfFn ![9, 7, 3, 2, 0, -1, -2, -5] with pc := 480 }

/-- ⭐ **`RefinesNetwork` IS FALSE.** At `offEndState` the program executes zero
instructions, so the left side is the *input* and the right side is the sorted
output. -/
theorem refinesNetwork_is_false : ¬ RefinesNetwork := by
  intro h; have := h offEndState; revert this; decide +kernel

/-- ⭐ **AND SO IS `SortsAllInputs`** — for the same reason and at the same
witness. `sortsAllInputs_of_refinesNetwork` above is still a true implication;
both of its endpoints are simply false as stated. -/
theorem sortsAllInputs_is_false : ¬ SortsAllInputs := by
  intro h; have := h offEndState; revert this; decide +kernel

/-! ### The fuel algebra for `runFor`

`ISA.lean` supplies `runFor` and `run` and nothing else — there is no
decomposition lemma for the ISA anywhere in the tower (`run_append` in
`HDL/Sem.lean` is the *gate-level* `run`, a different function). These five
declarations are that missing algebra, and they are generic in `code`: nothing
here knows about comparators. -/

/-- `runFor`'s step equation, as a rewrite rule. -/
theorem runFor_succ (n : Nat) (code : List Instr) (s : St) :
    runFor (n + 1) code s = match fetch code s.pc with
      | none => s
      | some i => runFor n code (step s i) := rfl

/-- ⭐ **HALTING IS A FIXED POINT.** Once `pc` leaves the program, *no* amount of
fuel changes the state. This is the fact that makes surplus fuel harmless and
`runFor_add` unconditional. -/
theorem runFor_of_fetch_none {code : List Instr} {s : St}
    (h : fetch code s.pc = none) (n : Nat) : runFor n code s = s := by
  cases n with
  | zero => rfl
  | succ m => rw [runFor_succ, h]

/-- One tick, when the fetch is known. -/
theorem runFor_step {code : List Instr} {s : St} {i : Instr} (n : Nat)
    (h : fetch code s.pc = some i) :
    runFor (n + 1) code s = runFor n code (step s i) := by
  rw [runFor_succ, h]

/-- ⭐ **THE FUEL ALGEBRA.** Fuel splits, **with no side condition at all**. If
the run halts inside the first `m` ticks the remaining `n` are spent on a state
that fetches `none`, which `runFor_of_fetch_none` says is the identity; if it
does not, the two halves compose. This is what lets blocks costing 2 and blocks
costing 5 be glued into one run. -/
theorem runFor_add (m n : Nat) (code : List Instr) (s : St) :
    runFor (m + n) code s = runFor n code (runFor m code s) := by
  induction m generalizing s with
  | zero => rw [Nat.zero_add]; rfl
  | succ k ih =>
      rw [Nat.succ_add, runFor_succ, runFor_succ]
      cases h : fetch code s.pc with
      | none => exact (runFor_of_fetch_none h n).symm
      | some i => exact ih (step s i)

/-- **Fuel slack.** A run that has already halted at `m` ticks answers the same
at any larger bound — which is how a `k`-step result is transported to `run`'s
own `code.length` bound. -/
theorem runFor_eq_of_halted {code : List Instr} {s : St} {m n : Nat}
    (h : fetch code (runFor m code s).pc = none) (hmn : m ≤ n) :
    runFor n code s = runFor m code s := by
  obtain ⟨d, rfl⟩ := Nat.exists_eq_add_of_le hmn
  rw [runFor_add, runFor_of_fetch_none h]

/-- ⭐ **THE STEP COUNT IS DATA-DEPENDENT, KERNEL-CHECKED.** 48 ticks finish the
all-equal input (24 comparators × 2, every branch taken) and provably **do not**
finish the reverse-sorted one, which needs 90. `run` spends 120 on both.

*This is the certificate that the fuel algebra is load-bearing rather than
decorative*: with a fixed per-comparator budget there is nothing to prove and
also nothing that is true. -/
theorem step_count_data_dependent :
    (runFor 48 batcherSort (stOfFn ![4, 4, 4, 4, 4, 4, 4, 4])).pc = 480 ∧
      (runFor 48 batcherSort (stOfFn ![9, 7, 3, 2, 0, -1, -2, -5])).pc ≠ 480 ∧
      (runFor 90 batcherSort (stOfFn ![9, 7, 3, 2, 0, -1, -2, -5])).pc = 480 := by
  decide +kernel

/-- ⚠️ **AND THE "ALREADY SORTED" INPUT IS NOT THE ALL-TAKEN CASE.** It costs 78
ticks, i.e. **ten of its 24 comparators swap** — `batcher8` contains descending
comparators (`(3,2)`, `(7,6)`, `(5,4)`, …), and an ascending input is out of
order for every one of them. The input on which all 24 branches are taken is the
constant one, above. -/
theorem already_sorted_input_still_swaps :
    (runFor 48 batcherSort (stOfFn ![-5, -2, -1, 0, 2, 3, 7, 9])).pc ≠ 480 := by
  decide +kernel

/-! ### Register bookkeeping

The allocation facts the block lemma leans on, and the two `XOR` cancellations
that make the 3-XOR swap a swap. -/

theorem dataReg_ne_zero (i : Fin 8) : dataReg i ≠ 0 := by
  revert i; decide +kernel

theorem dataReg_ne_tmp (i : Fin 8) : dataReg i ≠ tmpReg := by
  revert i; decide +kernel

/-- Distinct wires live in distinct registers — so a write to one data register
is invisible from every other. -/
theorem dataReg_inj {i j : Fin 8} (h : dataReg i = dataReg j) : i = j := by
  revert h; revert i j; decide +kernel

theorem set_pc (s : St) (r : Fin 32) (w : Word) : (s.set r w).pc = s.pc := by
  unfold St.set; split <;> rfl

theorem next_get_eq (s : St) (r : Fin 32) : s.next.get r = s.get r := rfl

theorem pc_upd_get (s : St) (p : BitVec 32) (r : Fin 32) :
    ({ s with pc := p } : St).get r = s.get r := rfl

theorem xor_cancel_right (x y : Word) : x ^^^ y ^^^ y = x := by
  rw [BitVec.xor_assoc, BitVec.xor_self, BitVec.xor_zero]

theorem xor_cancel_left (x y : Word) : x ^^^ y ^^^ x = y := by
  rw [BitVec.xor_comm x y, BitVec.xor_assoc, BitVec.xor_self, BitVec.xor_zero]

/-! ### One instruction at a time

`step`'s five cases, split into the pc effect and the register effect, so the
block lemma below is a chain of rewrites rather than a chain of `simp`s. -/

theorem step_slt_pc (s : St) (rd x y : Fin 32) :
    (step s (Instr.SLT rd x y)).pc = s.pc + 4 := by
  simp only [step, St.next, set_pc]

theorem step_xor_pc (s : St) (rd x y : Fin 32) :
    (step s (Instr.XOR rd x y)).pc = s.pc + 4 := by
  simp only [step, St.next, set_pc]

theorem step_slt_get_ne (s : St) (rd x y r : Fin 32) (h : r ≠ rd) :
    (step s (Instr.SLT rd x y)).get r = s.get r := by
  simp only [step, next_get_eq]
  exact St.get_set_ne _ _ _ _ h

theorem step_slt_get_self (s : St) (rd x y : Fin 32) (h : rd ≠ 0) :
    (step s (Instr.SLT rd x y)).get rd = (if (s.get x).slt (s.get y) then 1 else 0) := by
  simp only [step, next_get_eq]
  exact St.get_set_self _ _ _ h

theorem step_xor_get_ne (s : St) (rd x y r : Fin 32) (h : r ≠ rd) :
    (step s (Instr.XOR rd x y)).get r = s.get r := by
  simp only [step, next_get_eq]
  exact St.get_set_ne _ _ _ _ h

theorem step_xor_get_self (s : St) (rd x y : Fin 32) (h : rd ≠ 0) :
    (step s (Instr.XOR rd x y)).get rd = s.get x ^^^ s.get y := by
  simp only [step, next_get_eq]
  exact St.get_set_self _ _ _ h

theorem step_beq_taken (s : St) (x y : Fin 32) (imm : BitVec 12) (h : s.get x = s.get y) :
    step s (Instr.BEQ x y imm) = { s with pc := s.pc + bOffset imm } := by
  simp only [step, if_pos h]

theorem step_beq_not (s : St) (x y : Fin 32) (imm : BitVec 12) (h : s.get x ≠ s.get y) :
    step s (Instr.BEQ x y imm) = s.next := by
  simp only [step, if_neg h]

/-! ### ⭐ The comparator block -/

/-- `applyComp` at the signed-word order with `min`/`max` already resolved into
the `toInt` comparison the datapath computes. Both selects turn on the *same*
test, which is what makes the two machine paths line up with the two branches of
the abstract comparator. -/
theorem applyCompW_eq (c : Comparator 8) (v : Fin 8 → Word) (i : Fin 8) :
    @applyComp 8 Word wordSignedOrder c v i =
      if i = c.1 then (if (v c.1).toInt ≤ (v c.2).toInt then v c.1 else v c.2)
      else if i = c.2 then (if (v c.1).toInt ≤ (v c.2).toInt then v c.2 else v c.1)
      else v i := by
  simp only [applyComp, wordSignedOrder_min, wordSignedOrder_max]

/-- ⭐ **THE BLOCK LEMMA — a comparator is a 20-byte block with ONE exit.**

Given the five instructions of `cmpEx c` at `pc, pc+4, …, pc+16`, there is a step
count `k ≤ 5` after which the pc is at `pc + 20` and the eight data registers
hold `applyComp c` of what they held. **`k` is 2 or 5 and which one is a fact
about the data** — that is the whole difficulty, and the reason the conclusion
quantifies over `k` instead of naming it.

Three things this proof does not need, each worth stating:

* **no hypothesis that `c.1 ≠ c.2`.** A self-comparator makes `SLT` compute
  `¬ (x <ₛ x)`, so the branch is always taken and the 3-XOR — which would zero
  the register — is never reached. The abstract `applyComp` is likewise the
  identity there. They agree for free.
* **no hypothesis that the registers are distinct.** In the swapping branch
  `SLT` has already certified `v c.2 <ₛ v c.1`, hence `v c.1 ≠ v c.2`, hence
  `dataReg c.1 ≠ dataReg c.2` — the 3-XOR's side condition is *derived from the
  branch being taken*, not assumed.
* **no hypothesis about `x9`.** `dataReg_ne_tmp` keeps the scratch register out
  of the data, so the `SLT` write is invisible to the conclusion. -/
theorem cmpEx_block (code : List Instr) (c : Comparator 8) (s : St)
    (h0 : fetch code s.pc = some (Instr.SLT tmpReg (dataReg c.2) (dataReg c.1)))
    (h1 : fetch code (s.pc + 4) = some (Instr.BEQ tmpReg 0 skipImm))
    (h2 : fetch code (s.pc + 8) =
      some (Instr.XOR (dataReg c.1) (dataReg c.1) (dataReg c.2)))
    (h3 : fetch code (s.pc + 12) =
      some (Instr.XOR (dataReg c.2) (dataReg c.1) (dataReg c.2)))
    (h4 : fetch code (s.pc + 16) =
      some (Instr.XOR (dataReg c.1) (dataReg c.1) (dataReg c.2))) :
    ∃ k, k ≤ 5 ∧ (runFor k code s).pc = s.pc + 20 ∧
      ∀ i : Fin 8, (runFor k code s).get (dataReg i)
        = @applyComp 8 Word wordSignedOrder c (fun j => s.get (dataReg j)) i := by
  have htmp : tmpReg ≠ 0 := by decide
  have hane : dataReg c.1 ≠ 0 := dataReg_ne_zero c.1
  have hbne : dataReg c.2 ≠ 0 := dataReg_ne_zero c.2
  -- instruction 0: the SLT
  obtain ⟨s1, hs1⟩ :
      ∃ t, step s (Instr.SLT tmpReg (dataReg c.2) (dataReg c.1)) = t := ⟨_, rfl⟩
  have hs1pc : s1.pc = s.pc + 4 := by rw [← hs1]; exact step_slt_pc _ _ _ _
  have hs1get : ∀ r : Fin 32, r ≠ tmpReg → s1.get r = s.get r := by
    intro r hr; rw [← hs1]; exact step_slt_get_ne _ _ _ _ _ hr
  have hs1tmp : s1.get tmpReg =
      (if (s.get (dataReg c.2)).slt (s.get (dataReg c.1)) then 1 else 0) := by
    rw [← hs1]; exact step_slt_get_self _ _ _ _ htmp
  have hstep0 : ∀ n, runFor (n + 1) code s = runFor n code s1 := by
    intro n; rw [runFor_step n h0, hs1]
  by_cases hcmp : (s.get (dataReg c.2)).slt (s.get (dataReg c.1)) = true
  · -- OUT OF ORDER: the branch falls through, the three XORs run.  k = 5.
    have hlt : (s.get (dataReg c.2)).toInt < (s.get (dataReg c.1)).toInt :=
      (slt_iff_wlt _ _).mp hcmp
    have hnotle : ¬ ((s.get (dataReg c.1)).toInt ≤ (s.get (dataReg c.2)).toInt) :=
      Int.not_le.mpr hlt
    have hab : dataReg c.1 ≠ dataReg c.2 := by
      intro h; rw [h] at hlt; exact absurd hlt (Int.lt_irrefl _)
    have hba : dataReg c.2 ≠ dataReg c.1 := fun h => hab h.symm
    have hnot : s1.get tmpReg ≠ s1.get 0 := by
      rw [hs1tmp, St.get_zero, if_pos hcmp]; decide
    -- instruction 1: the BEQ, not taken
    obtain ⟨s2, hs2⟩ : ∃ t, step s1 (Instr.BEQ tmpReg 0 skipImm) = t := ⟨_, rfl⟩
    have hs2eq : s2 = s1.next := by rw [← hs2]; exact step_beq_not _ _ _ _ hnot
    have hs2pc : s2.pc = s.pc + 8 := by
      rw [hs2eq]; show s1.pc + 4 = s.pc + 8; rw [hs1pc]; bv_omega
    have hs2get : ∀ r : Fin 32, s2.get r = s1.get r := by
      intro r; rw [hs2eq]; exact next_get_eq _ _
    have hstep1 : ∀ n, runFor (n + 1) code s1 = runFor n code s2 := by
      intro n; rw [runFor_step n (by rw [hs1pc]; exact h1), hs2]
    -- instruction 2: XOR a a b
    obtain ⟨s3, hs3⟩ :
        ∃ t, step s2 (Instr.XOR (dataReg c.1) (dataReg c.1) (dataReg c.2)) = t := ⟨_, rfl⟩
    have hs3pc : s3.pc = s.pc + 12 := by
      rw [← hs3, step_xor_pc, hs2pc]; bv_omega
    have hs3a : s3.get (dataReg c.1) = s.get (dataReg c.1) ^^^ s.get (dataReg c.2) := by
      rw [← hs3, step_xor_get_self _ _ _ _ hane, hs2get, hs2get,
        hs1get _ (dataReg_ne_tmp c.1), hs1get _ (dataReg_ne_tmp c.2)]
    have hs3ne : ∀ r : Fin 32, r ≠ dataReg c.1 → s3.get r = s2.get r := by
      intro r hr; rw [← hs3]; exact step_xor_get_ne _ _ _ _ _ hr
    have hstep2 : ∀ n, runFor (n + 1) code s2 = runFor n code s3 := by
      intro n; rw [runFor_step n (by rw [hs2pc]; exact h2), hs3]
    -- instruction 3: XOR b a b
    obtain ⟨s4, hs4⟩ :
        ∃ t, step s3 (Instr.XOR (dataReg c.2) (dataReg c.1) (dataReg c.2)) = t := ⟨_, rfl⟩
    have hs4pc : s4.pc = s.pc + 16 := by
      rw [← hs4, step_xor_pc, hs3pc]; bv_omega
    have hs4b : s4.get (dataReg c.2) = s.get (dataReg c.1) := by
      rw [← hs4, step_xor_get_self _ _ _ _ hbne, hs3a, hs3ne _ hba, hs2get,
        hs1get _ (dataReg_ne_tmp c.2), xor_cancel_right]
    have hs4ne : ∀ r : Fin 32, r ≠ dataReg c.2 → s4.get r = s3.get r := by
      intro r hr; rw [← hs4]; exact step_xor_get_ne _ _ _ _ _ hr
    have hstep3 : ∀ n, runFor (n + 1) code s3 = runFor n code s4 := by
      intro n; rw [runFor_step n (by rw [hs3pc]; exact h3), hs4]
    -- instruction 4: XOR a a b
    obtain ⟨s5, hs5⟩ :
        ∃ t, step s4 (Instr.XOR (dataReg c.1) (dataReg c.1) (dataReg c.2)) = t := ⟨_, rfl⟩
    have hs5pc : s5.pc = s.pc + 20 := by
      rw [← hs5, step_xor_pc, hs4pc]; bv_omega
    have hs5a : s5.get (dataReg c.1) = s.get (dataReg c.2) := by
      rw [← hs5, step_xor_get_self _ _ _ _ hane, hs4ne _ hab, hs3a, hs4b, xor_cancel_left]
    have hs5ne : ∀ r : Fin 32, r ≠ dataReg c.1 → s5.get r = s4.get r := by
      intro r hr; rw [← hs5]; exact step_xor_get_ne _ _ _ _ _ hr
    have hstep4 : ∀ n, runFor (n + 1) code s4 = runFor n code s5 := by
      intro n; rw [runFor_step n (by rw [hs4pc]; exact h4), hs5]
    have hrun : runFor 5 code s = s5 := by
      rw [show (5 : Nat) = 4 + 1 from rfl, hstep0 4,
        show (4 : Nat) = 3 + 1 from rfl, hstep1 3,
        show (3 : Nat) = 2 + 1 from rfl, hstep2 2,
        show (2 : Nat) = 1 + 1 from rfl, hstep3 1,
        show (1 : Nat) = 0 + 1 from rfl, hstep4 0]
      rfl
    refine ⟨5, le_refl 5, by rw [hrun]; exact hs5pc, ?_⟩
    intro i
    rw [hrun, applyCompW_eq]
    simp only [if_neg hnotle]
    by_cases hi1 : i = c.1
    · subst hi1; rw [if_pos rfl, hs5a]
    · rw [if_neg hi1]
      have hri1 : dataReg i ≠ dataReg c.1 := fun h => hi1 (dataReg_inj h)
      rw [hs5ne _ hri1]
      by_cases hi2 : i = c.2
      · subst hi2; rw [if_pos rfl, hs4b]
      · rw [if_neg hi2]
        have hri2 : dataReg i ≠ dataReg c.2 := fun h => hi2 (dataReg_inj h)
        rw [hs4ne _ hri2, hs3ne _ hri1, hs2get, hs1get _ (dataReg_ne_tmp i)]
  · -- ALREADY ORDERED: the branch is taken, the swap is skipped.  k = 2.
    have hle : (s.get (dataReg c.1)).toInt ≤ (s.get (dataReg c.2)).toInt := by
      have hnw : ¬ wlt (s.get (dataReg c.2)) (s.get (dataReg c.1)) := by
        rw [← slt_iff_wlt]; exact hcmp
      exact not_wlt.mp hnw
    have htaken : s1.get tmpReg = s1.get 0 := by
      rw [hs1tmp, St.get_zero, if_neg hcmp]
    obtain ⟨s2, hs2⟩ : ∃ t, step s1 (Instr.BEQ tmpReg 0 skipImm) = t := ⟨_, rfl⟩
    have hs2eq : s2 = { s1 with pc := s1.pc + bOffset skipImm } := by
      rw [← hs2]; exact step_beq_taken _ _ _ _ htaken
    have hs2pc : s2.pc = s.pc + 20 := by
      rw [hs2eq]; show s1.pc + bOffset skipImm = s.pc + 20
      rw [bOffset_skipImm, hs1pc]; bv_omega
    have hs2get : ∀ r : Fin 32, s2.get r = s1.get r := by
      intro r; rw [hs2eq]; exact pc_upd_get _ _ _
    have hstep1 : ∀ n, runFor (n + 1) code s1 = runFor n code s2 := by
      intro n; rw [runFor_step n (by rw [hs1pc]; exact h1), hs2]
    have hrun : runFor 2 code s = s2 := by
      rw [show (2 : Nat) = 1 + 1 from rfl, hstep0 1,
        show (1 : Nat) = 0 + 1 from rfl, hstep1 0]
      rfl
    refine ⟨2, by omega, by rw [hrun]; exact hs2pc, ?_⟩
    intro i
    rw [hrun, applyCompW_eq, hs2get, hs1get _ (dataReg_ne_tmp i)]
    simp only [if_pos hle]
    by_cases hi1 : i = c.1
    · subst hi1; rw [if_pos rfl]
    · rw [if_neg hi1]
      by_cases hi2 : i = c.2
      · subst hi2; rw [if_pos rfl]
      · rw [if_neg hi2]

/-! ### The induction over the network

⚠️ **A PREFIX DOES NOT RUN IN ISOLATION.** `fetch code pc` indexes the *whole*
list by the absolute `pc`, so peeling comparators off the front of the network
would change the code the machine sees. The induction therefore holds `code`
fixed and moves an *offset*: `EmbedsAt code net off` says the instructions of
`emit net` sit in `code` starting at instruction index `off`, and the recursion
advances `off` by five rather than shortening the program. -/

/-- Reading a fetch off a pc whose byte address is known. -/
theorem fetch_of_toNat {code : List Instr} {p : BitVec 32} {n : Nat}
    (h : p.toNat = 4 * n) : fetch code p = code[n]? := by
  unfold fetch
  rw [h, if_pos (by omega), show 4 * n / 4 = n by omega]

/-- The pc arithmetic, non-wrapping under an explicit bound. The bound is real:
`pc` is a `BitVec 32` and its addition wraps. -/
theorem toNat_add_of (p q : BitVec 32) (n m : Nat)
    (hp : p.toNat = n) (hq : q.toNat = m) (h : n + m < 2 ^ 32) :
    (p + q).toNat = n + m := by
  rw [BitVec.toNat_add, hp, hq, Nat.mod_eq_of_lt h]

/-- `code` carries the instructions of `emit net` starting at instruction index
`off`. Stated with `getElem?` so it needs no length side conditions, and stated
about an arbitrary `code` so the program may extend beyond the network in either
direction. -/
def EmbedsAt (code : List Instr) (net : Network 8) (off : Nat) : Prop :=
  ∀ j, j < 5 * net.length → code[off + j]? = (emit net)[j]?

theorem emit_cons (c : Comparator 8) (cs : Network 8) :
    emit (c :: cs) = cmpEx c ++ emit cs := rfl

theorem embeds_head {code : List Instr} {c : Comparator 8} {cs : Network 8} {off : Nat}
    (h : EmbedsAt code (c :: cs) off) (j : Nat) (hj : j < 5) :
    code[off + j]? = (cmpEx c)[j]? := by
  have hj' : j < 5 * (c :: cs).length := by
    rw [List.length_cons]; omega
  rw [h j hj', emit_cons]
  exact List.getElem?_append_left (by rw [cmpEx_length]; exact hj)

theorem embeds_tail {code : List Instr} {c : Comparator 8} {cs : Network 8} {off : Nat}
    (h : EmbedsAt code (c :: cs) off) : EmbedsAt code cs (off + 5) := by
  intro j hj
  have hj' : 5 + j < 5 * (c :: cs).length := by
    rw [List.length_cons]; omega
  have hh := h (5 + j) hj'
  rw [show off + (5 + j) = off + 5 + j by omega, emit_cons] at hh
  rw [hh, List.getElem?_append_right (by rw [cmpEx_length]; omega), cmpEx_length]
  congr 1
  omega

/-- ⭐ **THE EMITTED CODE COMPUTES THE NETWORK**, for every network and at every
offset in every enclosing program. Induction on the network, gluing the blocks
with `runFor_add`; the step count `k` is again existential, since it is the sum
of 24 independently data-dependent 2-or-5s.

Generic in `net`, exactly as `emit` is: nothing here is specialised to
`batcher8`, so a different network compiled by the same emitter inherits this
theorem. -/
theorem emit_runs (code : List Instr) : ∀ (net : Network 8) (off : Nat) (s : St),
    EmbedsAt code net off → s.pc.toNat = 4 * off →
    4 * off + 20 * net.length < 2 ^ 32 →
    ∃ k, k ≤ 5 * net.length ∧
      (runFor k code s).pc.toNat = 4 * off + 20 * net.length ∧
      ∀ i : Fin 8, (runFor k code s).get (dataReg i)
        = runNetW net (fun j => s.get (dataReg j)) i := by
  intro net
  induction net with
  | nil =>
      intro off s _ hpc _
      refine ⟨0, by simp, ?_, fun i => rfl⟩
      show s.pc.toNat = 4 * off + 20 * 0
      omega
  | cons c cs ih =>
      intro off s hemb hpc hb
      rw [List.length_cons] at hb ⊢
      have hb20 : 4 * off + 20 < 2 ^ 32 := by omega
      have h4 : (4 : BitVec 32).toNat = 4 := by decide
      have h8 : (8 : BitVec 32).toNat = 8 := by decide
      have h12 : (12 : BitVec 32).toNat = 12 := by decide
      have h16 : (16 : BitVec 32).toNat = 16 := by decide
      have e1 : (s.pc + 4).toNat = 4 * (off + 1) := by
        rw [toNat_add_of s.pc 4 (4 * off) 4 hpc h4 (by omega)]; omega
      have e2 : (s.pc + 8).toNat = 4 * (off + 2) := by
        rw [toNat_add_of s.pc 8 (4 * off) 8 hpc h8 (by omega)]; omega
      have e3 : (s.pc + 12).toNat = 4 * (off + 3) := by
        rw [toNat_add_of s.pc 12 (4 * off) 12 hpc h12 (by omega)]; omega
      have e4 : (s.pc + 16).toNat = 4 * (off + 4) := by
        rw [toNat_add_of s.pc 16 (4 * off) 16 hpc h16 (by omega)]; omega
      have f0 : fetch code s.pc = some (Instr.SLT tmpReg (dataReg c.2) (dataReg c.1)) := by
        rw [fetch_of_toNat hpc, show off = off + 0 by omega, embeds_head hemb 0 (by omega)]
        rfl
      have f1 : fetch code (s.pc + 4) = some (Instr.BEQ tmpReg 0 skipImm) := by
        rw [fetch_of_toNat e1, embeds_head hemb 1 (by omega)]; rfl
      have f2 : fetch code (s.pc + 8) =
          some (Instr.XOR (dataReg c.1) (dataReg c.1) (dataReg c.2)) := by
        rw [fetch_of_toNat e2, embeds_head hemb 2 (by omega)]; rfl
      have f3 : fetch code (s.pc + 12) =
          some (Instr.XOR (dataReg c.2) (dataReg c.1) (dataReg c.2)) := by
        rw [fetch_of_toNat e3, embeds_head hemb 3 (by omega)]; rfl
      have f4 : fetch code (s.pc + 16) =
          some (Instr.XOR (dataReg c.1) (dataReg c.1) (dataReg c.2)) := by
        rw [fetch_of_toNat e4, embeds_head hemb 4 (by omega)]; rfl
      obtain ⟨k1, hk1, hk1pc, hk1reg⟩ := cmpEx_block code c s f0 f1 f2 f3 f4
      have hs'pc : (runFor k1 code s).pc.toNat = 4 * (off + 5) := by
        rw [hk1pc, toNat_add_of s.pc 20 (4 * off) 20 hpc (by decide) (by omega)]; omega
      obtain ⟨k2, hk2, hk2pc, hk2reg⟩ :=
        ih (off + 5) (runFor k1 code s) (embeds_tail hemb) hs'pc (by omega)
      refine ⟨k1 + k2, by omega, ?_, ?_⟩
      · rw [runFor_add, hk2pc]; omega
      · intro i
        rw [runFor_add, hk2reg i]
        have hv : (fun j => (runFor k1 code s).get (dataReg j))
            = @applyComp 8 Word wordSignedOrder c (fun j => s.get (dataReg j)) := by
          funext j; exact hk1reg j
        rw [hv]
        rfl

/-! ### ⭐ The refinement, from the entry point the program actually has -/

theorem batcherSort_embeds : EmbedsAt batcherSort batcher8 0 := by
  intro j _; rw [Nat.zero_add]; rfl

/-- ⭐ **S3(b), PROVED — from `pc = 0`.** The 120 instructions under `step`
compute exactly what `runNetW batcher8` computes, for **every** word vector, at
S1's signed order.

This is `RefinesNetwork` with the one hypothesis it was missing. Read together
with `refinesNetwork_is_false`, the pair says precisely how much the entry point
was carrying: **everything**. -/
theorem refinesNetwork_of_pc_zero (s : St) (hpc : s.pc = 0) :
    dataRegs.map (run batcherSort s).get
      = List.ofFn (runNetW batcher8 (fun i => s.get (dataReg i))) := by
  have hpc0 : s.pc.toNat = 4 * 0 := by rw [hpc]; rfl
  have hbnd : 4 * 0 + 20 * batcher8.length < 2 ^ 32 := by
    rw [batcher8_length]; omega
  obtain ⟨k, hk, hkpc, hkreg⟩ :=
    emit_runs batcherSort batcher8 0 s batcherSort_embeds hpc0 hbnd
  rw [batcher8_length] at hk hkpc
  have hhalt : fetch batcherSort (runFor k batcherSort s).pc = none := by
    unfold fetch
    rw [hkpc, if_pos (by omega), show (4 * 0 + 20 * 24) / 4 = 120 by omega]
    exact List.getElem?_eq_none (by rw [batcherSort_length])
  have hrun : run batcherSort s = runFor k batcherSort s := by
    rw [run, runFor_eq_of_halted hhalt (by rw [batcherSort_length]; omega)]
  rw [hrun, dataRegs_map_get]
  congr 1
  funext i
  exact hkreg i

/-- ⭐ **AND THEREFORE IT SORTS** — the S3(b) deliverable, at the same entry
point. Same composition as `sortsAllInputs_of_refinesNetwork`: sortedness and
permutation are inherited from `batcher8_sortsTo_word`, and the two lanes meet at
the same `batcher8` literal. -/
theorem sortsRegs_of_pc_zero (s : St) (hpc : s.pc = 0) :
    SortsRegs dataRegs s (run batcherSort s) := by
  rw [SortsRegs, dataRegs_map_get s, refinesNetwork_of_pc_zero s hpc]
  exact batcher8_sortsTo_word _

/-- `stOfFn` enters at the top, which is why every concrete run above was a run
of the whole program — and why the missing hypothesis was invisible. -/
theorem stOfFn_pc (v : Fin 8 → Word) : (stOfFn v).pc = 0 := rfl

/-- ⭐ **CONTROL — the repaired statement is one a wrong program FAILS.** The
`imm = 6` mutant enters at `pc = 0` like everything else, runs to completion, and
does not compute the network. So `refinesNetwork_of_pc_zero` is a claim with
content, not a shape that any 120 instructions would satisfy. -/
theorem cmpEx6_does_not_refine :
    ¬ ∀ s : St, s.pc = 0 →
        dataRegs.map (run (batcher8.flatMap cmpEx6) s).get
          = List.ofFn (runNetW batcher8 (fun i => s.get (dataReg i))) := by
  intro h
  have := h (stOfFn ![3, -1, 7, 0, -5, 2, 9, -2]) (stOfFn_pc _)
  revert this
  decide +kernel

/-- **CONTROL, the other mutant.** Flipping the `SLT` comparands likewise fails
the repaired statement. -/
theorem cmpExFlip_does_not_refine :
    ¬ ∀ s : St, s.pc = 0 →
        dataRegs.map (run (batcher8.flatMap cmpExFlip) s).get
          = List.ofFn (runNetW batcher8 (fun i => s.get (dataReg i))) := by
  intro h
  have := h (stOfFn ![3, -1, 7, 0, -5, 2, 9, -2]) (stOfFn_pc _)
  revert this
  decide +kernel

/-! ## ⭐ STACK-LOADER — how `s.pc = 0` arrives, and what S5 needs at the entry

S3(b) left `refinesNetwork_of_pc_zero` carrying an `hpc : s.pc = 0` and the
ledger left *"how do the eight words arrive in the registers on real silicon"*
as the open seam. This section is the demand trace that answers it, and the
answer is not the one the seam's name suggests.

### ⛔ THE FIRST FINDING: THERE CAN BE NO LOADER, BECAUSE SLICE A CANNOT LOAD

The obvious repair is a *prelude* — a few instructions in front of `batcherSort`
that put the input into `x1`–`x8` and leave the pc at the sort's first word.
**Slice A cannot express one.** Read off the instruction set rather than
argued:

* `ADDI rd rs1 (imm : BitVec 12)` is the only instruction that introduces a
  constant, and `step`'s `ADDI` case adds `imm.signExtend 32`. **The reachable
  constants are `[-2048, 2047]`** — the 32-bit word `0x000010B7` is not among
  them, and neither is most of any input.
* There is **no `LW`, no `LB`, no `LUI`, no `AUIPC`** — `Instr` has exactly five
  constructors (`ADD`, `ADDI`, `XOR`, `SLT`, `BEQ`) and `ISA.lean`'s own
  docstring lists the exclusions. `decode_rejects_lui` is the same fact from the
  decoder's side.
* There is **no memory** at all, so there is nowhere for a load to load from.

⇒ **A prelude could only install eight assembly-time constants inside ±2047.**
That is not `∀ v : Fin 8 → Word`; it is one example. *The prelude option does
not weaken the theorem — it destroys it*, and that is why the entry point is
`stOfFn` and not a program.

### ⭐ THE SECOND FINDING: `stOfFn` IS NOT A LOADER, IT IS A RESET

`stOfFn` builds a state from `St.init`, whose `pc` is already `0`. Nothing
*runs* to establish `pc = 0`; the state simply has it. So at the software level
the hypothesis is discharged for free (`stOfFn_pc`, `rfl`), and everything below
`stOfFn_sorts` is bookkeeping.

⚠️ **But that means the obligation did not disappear — it changed lanes.** C4
observes the machine state as `SaltWorks.HDL.decQ ins`, *decoded from the
netlist's primary inputs* (`docs/c4-statement-composition-check-0807.md` §2:
the Q-leaves, at the flop boundary). On silicon there is no `St.init` and no
`stOfFn`: the state at cycle 0 is **whatever the flops hold out of reset**. ⇒
*`pc = 0` and "the data is in the registers" are a **hardware initialisation**
obligation, not a software one.* `EntryLoaded` below is that obligation, named.

### And a second obligation the trace exposes, which was not on anyone's list

Slice A's `run` takes the program as a `List Instr` *argument*. On silicon it
does not: C4's `stepT` takes a **fetched word** on the instruction nets
(`instrNet`, `StateCodec.lean`). So S5 needs the netlist to be *fed the program*
as well as reset into the right state. `DeliversProgram` is that second
obligation, and it is the larger of the two — see the note on it below. -/

/-! ### The entry state, read at the data registers -/

/-- The eight data registers of `stOfFn v`, as a function — the exact shape
`refinesNetwork_of_pc_zero`'s right-hand side wants. Derived from
`dataRegs_map_stOfFn` through `dataRegs_map_get` (which is `rfl`) rather than by
unfolding eight `St.set`s. -/
theorem stOfFn_dataReg_eq (v : Fin 8 → Word) :
    (fun i : Fin 8 => (stOfFn v).get (dataReg i)) = v :=
  List.ofFn_inj.mp (by rw [← dataRegs_map_get, dataRegs_map_stOfFn])

/-- The same, pointwise. -/
theorem stOfFn_get_dataReg (v : Fin 8 → Word) (i : Fin 8) :
    (stOfFn v).get (dataReg i) = v i := congrFun (stOfFn_dataReg_eq v) i

/-! ### ⭐ S2 + S3(b), CLOSED AT THE SOFTWARE LEVEL — no hypothesis survives -/

/-- ⭐ **THE PROGRAM COMPUTES THE NETWORK, unconditionally in the input.** No
`s`, no `pc`, no hypothesis: for **every** vector of eight words, loading it and
running the 120 instructions leaves the data registers holding exactly
`runNetW batcher8 v`.

This is `RefinesNetwork` with the false generality removed rather than repaired
— `refinesNetwork_of_pc_zero` instantiated at the entry state the program
actually has, with `hpc` discharged by `rfl`. -/
theorem stOfFn_refines_network (v : Fin 8 → Word) :
    dataRegs.map (run batcherSort (stOfFn v)).get
      = List.ofFn (runNetW batcher8 v) := by
  rw [refinesNetwork_of_pc_zero _ (stOfFn_pc v), stOfFn_dataReg_eq]

/-- ⭐⭐ **AND THEREFORE IT SORTS — the S2/S3(b) deliverable, unconditional.**
*For every eight-word input, the agent-written program's output registers are a
signed-sorted permutation of the input.* The input appears as `v` on both sides:
nothing is read back out of a state, so there is no entry-point assumption left
to hide in.

This is the sentence the campaign's first link was after, and it is now free of
side conditions at the software level. What remains is not a gap in this
theorem; it is `EntryLoaded` below, which is a different lane's. -/
theorem stOfFn_sorts (v : Fin 8 → Word) :
    SortsTo (List.ofFn v) (dataRegs.map (run batcherSort (stOfFn v)).get) := by
  rw [stOfFn_refines_network]
  exact batcher8_sortsTo_word v

/-- The same claim in `SortsRegs` form — the before/after register reading
`Spec.lean` defines, for callers that want the spec's own vocabulary. -/
theorem stOfFn_sortsRegs (v : Fin 8 → Word) :
    SortsRegs dataRegs (stOfFn v) (run batcherSort (stOfFn v)) :=
  sortsRegs_of_pc_zero _ (stOfFn_pc v)

/-! ### ⭐ THE SEAM — the entry contract the silicon lane owes S5 -/

/-- ⭐ **THE ENTRY CONTRACT.** *The netlist's primary inputs at cycle 0 decode to
a machine state whose `pc` is `0` and whose eight data registers hold `v`.*

Phrased against `SaltWorks.HDL.decQ` — C4's own reading of the Q-leaves — so the
silicon lane can consume it without a translation step, and stated as a `def …
: Prop` rather than a `sorry`-ed theorem for the same reason `RefinesNetwork`
was: so it is committed, named and axiom-clean today.

**Deliberately minimal.** It says nothing about `tmpReg`, nothing about the
other 23 registers, and nothing about `St.init`. `refinesNetwork_of_pc_zero`
needs the pc and the eight registers and nothing else, so asking hardware for
anything more would be asking for what the proof does not use. In particular
this is *weaker* than `decQ ins = stOfFn v`, which would also pin the scratch
register — a reset that leaves `x9` dirty still satisfies this.

**Who owes it: the silicon lane (reset / power-on state), not the compiler and
not this file.** Nothing in the tower models a reset today, which is why this is
stated and not proved. **What would discharge it:** a reset model that pins the
flops' power-on values, plus the input-map obligation C4's composition check
already lists (`docs/c4-statement-composition-check-0807.md` §4, row 3 —
*"primary inputs 0 … 1055 are the Q-leaves in `StateCodec`'s layout"*). Given
those, `EntryLoaded` follows the way `entryLoaded_encD_stOfFn` below does. -/
def EntryLoaded (ins : SaltWorks.HDL.Env) (v : Fin 8 → Word) : Prop :=
  (SaltWorks.HDL.decQ ins).pc = 0 ∧
    ∀ i : Fin 8, (SaltWorks.HDL.decQ ins).get (dataReg i) = v i

/-- ⭐ **THE SEAM IS SUFFICIENT** — this is what makes `EntryLoaded` the right
statement rather than a plausible one. Given only the entry contract, the
program sorts from the decoded state. So S5 may compose against `EntryLoaded`
and never mention `stOfFn`, `St.init` or `pc` again. -/
theorem sorts_of_entryLoaded {ins : SaltWorks.HDL.Env} {v : Fin 8 → Word}
    (h : EntryLoaded ins v) :
    SortsTo (List.ofFn v)
      (dataRegs.map (run batcherSort (SaltWorks.HDL.decQ ins)).get) := by
  obtain ⟨hpc, hreg⟩ := h
  have hv : (fun i : Fin 8 => (SaltWorks.HDL.decQ ins).get (dataReg i)) = v :=
    funext hreg
  rw [refinesNetwork_of_pc_zero _ hpc, hv]
  exact batcher8_sortsTo_word v

/-- ⭐ **AND IT IS SATISFIABLE** — a `Prop` nothing can meet is not a contract.
The wire configuration is `stOfFn v`'s own encoding, and the proof is the landed
round trip `decQ_encD`. *This is the discharge, modulo the one thing missing:
a theorem that says the flops actually come out of reset holding these bits.*
Everything downstream of that is already here. -/
theorem entryLoaded_encD_stOfFn (v : Fin 8 → Word) :
    EntryLoaded (fun j => (SaltWorks.HDL.encD (stOfFn v)).getD j false) v := by
  refine ⟨?_, ?_⟩ <;> rw [SaltWorks.HDL.decQ_encD]
  · exact stOfFn_pc v
  · exact fun i => stOfFn_get_dataReg v i

/-! ### The controls — the seam discriminates

Per this file's standing practice: a contract satisfied by everything is not a
contract. `offEndState` — the witness that refuted `RefinesNetwork` — is a
perfectly good machine state, so its encoding is a perfectly good wire
configuration, and it **fails** `EntryLoaded` and **fails** the conclusion. The
two theorems below are that pair. -/

/-- The refutation witness, as an input environment. -/
def offEndEnv : SaltWorks.HDL.Env :=
  fun j => (SaltWorks.HDL.encD offEndState).getD j false

/-- **The contract rejects it** — `pc = 480`, not `0`. -/
theorem not_entryLoaded_offEndEnv :
    ¬ EntryLoaded offEndEnv ![9, 7, 3, 2, 0, -1, -2, -5] := by
  rintro ⟨hpc, -⟩
  unfold offEndEnv at hpc
  rw [SaltWorks.HDL.decQ_encD] at hpc
  exact absurd hpc (by decide +kernel)

/-- ⭐ **AND THE CONCLUSION REALLY IS FALSE THERE.** Not merely unproved: at
`offEndEnv` the machine fetches nothing, the registers keep their reverse-sorted
contents, and `SortsTo` fails. ⇒ *`sorts_of_entryLoaded`'s hypothesis is doing
work, and a reset that got the pc wrong would be caught here rather than
silently produce an unsorted chip.* -/
theorem offEndEnv_does_not_sort :
    ¬ SortsTo (List.ofFn ![9, 7, 3, 2, 0, -1, -2, -5])
        (dataRegs.map (run batcherSort (SaltWorks.HDL.decQ offEndEnv)).get) := by
  unfold offEndEnv
  rw [SaltWorks.HDL.decQ_encD]
  decide +kernel

/-! ### ⛔ THE SECOND OBLIGATION — the program has to reach the silicon too

**This one was not on the seam list and it is the bigger of the two.** `run`
takes `batcherSort : List Instr` as an *argument*: in the software model the
program is a parameter of the semantics. C4's `stepT : St → BitVec 32 → St`
takes a **word**, delivered on `instrNet 0 … instrNet 31`. So a netlist that
satisfies `EntryLoaded` and then reads garbage on the instruction nets computes
garbage, and nothing stated so far notices.

⚠️ **And there is no memory to fetch from** (`docs/s0-r2-memory-census-0807.md`;
Slice A's own exclusion list). So `DeliversProgram` cannot be discharged by an
instruction-memory model that does not exist — it will be met either by a ROM
added to the tile or by hard-wiring the 120 words, and **that is a tile-level
design decision nobody has made.** Stating it here is the point: it is the
difference between S5 being a composition and S5 being a surprise. -/

/-- The program word at a byte address, in `fetch`'s own convention — including
its alignment rule, so the two cannot drift. -/
def fetchWord (pc : BitVec 32) : Option Word :=
  if pc.toNat % 4 = 0 then batcherSortWords[pc.toNat / 4]? else none

/-- **`fetchWord` is `fetch`, one decode later.** The bridge that makes the
obligation below a statement about *this* program rather than about a list of
words that happens to be lying around. Structural, from `decode_encode`. -/
theorem fetchWord_decodes (pc : BitVec 32) :
    (fetchWord pc).bind decode = fetch batcherSort pc := by
  unfold fetchWord fetch
  by_cases h : pc.toNat % 4 = 0
  · simp only [if_pos h, batcherSortWords, List.getElem?_map]
    cases batcherSort[pc.toNat / 4]? with
    | none => rfl
    | some i => simp [decode_encode]
  · simp [h]

/-- ⭐ **THE INSTRUCTION-DELIVERY OBLIGATION.** *Whenever the machine's pc names
a word of the program, the tile presents that word on the instruction nets.*

`env` is the tile's input map as a function of the machine state, which is the
shape C5's cycle induction will have anyway: each cycle it must say what the
core sees. Written with `wordOf (fun k => env s (instrNet k))` and **not**
`wordOf (env s)` — the latter typechecks and reads register `x0`, the trap
`StateCodec.word_at_zero_is_register_x0` exists to make visible.

**Who owes it: the tile's assembly (a ROM, or hard-wired words), together with
whatever `Compose.lean`'s input map turns out to be.** Not the compiler: C4 is a
statement about one cycle given a word, and is silent on where the word came
from. **What would discharge it:** a tile-level netlist that includes the 120
words of `batcherSortWords` as constants indexed by the pc, plus the proof that
its output lands on `instrNet`. Nothing in the tree does this today. -/
def DeliversProgram (env : St → SaltWorks.HDL.Env) : Prop :=
  ∀ (s : St) (w : Word), fetchWord s.pc = some w →
      SaltWorks.HDL.wordOf (fun k => env s (SaltWorks.HDL.instrNet k)) = w

/-! ## ⭐ C5IND — THE CYCLE INDUCTION, over an abstract per-cycle hypothesis

C4 is *"one cycle of the emitted netlist equals one `ISA.stepT`"*. **It cannot be
stated against a real core today: `compile` and `core` do not exist**
(`grep -rnE "^(def|theorem|abbrev) (core|compile)\b"` over `SaltWorks/` returns
nothing). This section is the layer *above* C4 that does not depend on it: given
one-cycle equivalence **as a hypothesis**, `n`-cycle equivalence, and then the
whole program. When C4 lands it discharges `CycleRealisesStep` and the two halves
meet with nothing left over.

### ⛔ THE FINDING: `stepT`-ITERATION AND `runFor` ARE **NOT** THE SAME OBJECT

This node's assignment asked whether the two lanes' notions of *"n steps"* line
up. They do not, and the divergence is exactly one thing:

```
runFor  : fetch code s.pc = none  ⇒  HALT, and halting is a FIXED POINT
runWords: every cycle steps.  stepT is TOTAL.  There is no halting word.
```

`runFor` gets its `pc` from a `List Instr` it is *handed*; `stepT` gets a word
*presented on the instruction nets* and has, by the v1 ruling
(`ISA.lean:636-676`), a defined NOP-advance on everything it cannot decode. So
the netlist has **no halt state at all** — it steps forever. `runWords_eq_runFor`
below is the agreement, and it is conditional: it holds for exactly as many
cycles as the pc keeps naming a program word. `runFor_halts_where_runWords_runs_on`
is the divergence, kernel-checked at `offEndState`, where `runFor` is the identity
at *every* bound and ten cycles have moved the pc forty bytes further on.

⚠️ **AND THE BOUNDARY IS NOT A CORNER CASE — IT IS THE COMMON CASE.**
`step_count_data_dependent` already pins that this program finishes in **48 to 90**
steps depending on the data, while `run` spends 120. So on a fixed-length silicon
run the machine is *past the end of its own program* for between 30 and 72 cycles
of every execution. `runFor`'s fixed point covers that silently; the tile does not.

⇒ **A THIRD ENTRY-SIDE OBLIGATION, alongside `EntryLoaded` and
`DeliversProgram`: what the tile presents on the instruction nets AFTER the
program ends.** `DeliversProgram` is stated only where `fetchWord` returns
`some`, so it is *silent* there — and a tile that presents live instructions past
the end computes garbage while satisfying every obligation stated before today.
`FeedsProgram`'s second conjunct is that obligation, named.

**The good news, and it is a theorem rather than a hope:** the obligation is
cheap. `runWords_get_of_undecodable` says an undecodable word touches no
register at all, so *any* word the decoder rejects is a safe filler — and
`decode_zero` says the all-zero word is one. ⇒ **a ROM that reads zero outside
`[0, 480)` discharges it**, and `noisy_tail_overwrites` is the control showing a
tile that instead re-presents a live instruction destroys the answer.

### What "n cycles" is, on each side

`cycles` (netlist) and `runWords` (ISA) are both left folds, so they compose
index-by-index. Note the contrast their `_add` lemmas make with `runFor_add`
above: `cycles_add` and `runWords_add` are unconditional **trivially**, because
nothing halts; `runFor_add` is unconditional for a *substantive* reason, that
halting is a fixed point. Same shape, different content — which is the divergence
again, seen from the algebra. -/

/-! ### The two `n`-step objects -/

/-- **`n` ISA steps driven by a word stream**: at cycle `k` the core is handed
`ws k`. This is the ISA-side meaning of *"n cycles"*, and it is **not** `runFor`
— see the section note. Left fold, to match `cycles` below. -/
def runWords (ws : Nat → Word) : Nat → St → St
  | 0,     s => s
  | n + 1, s => stepT (runWords ws n s) (ws n)

theorem runWords_succ (ws : Nat → Word) (n : Nat) (s : St) :
    runWords ws (n + 1) s = stepT (runWords ws n s) (ws n) := rfl

/-- The stream splits with a shift, since the second leg's cycle `k` is the
whole run's cycle `m + k`. Unconditional — but for the trivial reason that
`stepT` never stops, not for `runFor_add`'s reason. -/
theorem runWords_add (ws : Nat → Word) (m n : Nat) (s : St) :
    runWords ws (m + n) s = runWords (fun k => ws (m + k)) n (runWords ws m s) := by
  induction n with
  | zero => rfl
  | succ d ih =>
      show stepT (runWords ws (m + d) s) (ws (m + d))
          = runWords (fun k => ws (m + k)) (d + 1) (runWords ws m s)
      rw [runWords_succ, ih]

/-- **`n` netlist cycles** — the primary inputs after `n` applications of the
one-cycle map. ⚠️ `SaltWorks.HDL.Env`, fully qualified: `SaltWorks.Codegen.Env`
is `Nat → BitVec 32`, i.e. WORDS, and both are reducible `abbrev`s, so a
wrong-but-well-typed composition would elaborate silently. -/
def cycles (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env) :
    Nat → SaltWorks.HDL.Env → SaltWorks.HDL.Env
  | 0,     ins => ins
  | n + 1, ins => cyc (cycles cyc n ins)

theorem cycles_succ (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env) (n : Nat)
    (ins : SaltWorks.HDL.Env) : cycles cyc (n + 1) ins = cyc (cycles cyc n ins) := rfl

theorem cycles_add (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env) (m n : Nat)
    (ins : SaltWorks.HDL.Env) :
    cycles cyc (m + n) ins = cycles cyc n (cycles cyc m ins) := by
  induction n with
  | zero => rfl
  | succ d ih =>
      show cyc (cycles cyc (m + d) ins) = cycles cyc (d + 1) (cycles cyc m ins)
      rw [cycles_succ, ih]

/-! ### The abstract per-cycle hypothesis -/

/-- **The word the core sees this cycle**, read off the instruction nets.

🔴 **Written `wordOf (fun k => ins (instrNet k))` and NOT `wordOf ins`.** The
latter typechecks — `Env`, `Net` and `Nat` are all reducible — and reads bits
`0 … 31`, **which is register `x0`**
(`SaltWorks.HDL.word_at_zero_is_register_x0`). `not_cycleRealisesStep_wordOf`
below is that trap as a refutation rather than a warning. -/
def seenWord (ins : SaltWorks.HDL.Env) : Word :=
  SaltWorks.HDL.wordOf (fun k => ins (SaltWorks.HDL.instrNet k))

/-- ⭐ **THE ABSTRACT PER-CYCLE HYPOTHESIS — C4, as a `Prop` the layer above can
consume today.** *One netlist cycle, read through the codec, is one `stepT` on
the word the core saw.*

Parameterised in **both** the cycle map and the word source, so it commits to no
core, no netlist and no fetch path. C4 will instantiate `cyc` at the emitted
netlist's one-cycle observation and `wordAt` at `seenWord`. -/
def CycleRealisesStep (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env)
    (wordAt : SaltWorks.HDL.Env → Word) : Prop :=
  ∀ ins, SaltWorks.HDL.decQ (cyc ins) = stepT (SaltWorks.HDL.decQ ins) (wordAt ins)

/-- ⭐⭐ **THE DELIVERABLE — `n` CYCLES REALISE `n` STEPS.** One cycle of induction
over the hypothesis; the stream the ISA side is driven by is read off the cycle
sequence itself, which is what makes the statement need no fetch model. -/
theorem cycles_realise_steps {cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env}
    {wordAt : SaltWorks.HDL.Env → Word} (h : CycleRealisesStep cyc wordAt)
    (n : Nat) (ins : SaltWorks.HDL.Env) :
    SaltWorks.HDL.decQ (cycles cyc n ins)
      = runWords (fun k => wordAt (cycles cyc k ins)) n (SaltWorks.HDL.decQ ins) := by
  induction n with
  | zero => rfl
  | succ m ih => rw [cycles_succ, h (cycles cyc m ins), ih, runWords_succ]

/-! ### ⭐ NON-VACUITY — the hypothesis is satisfiable, and the neighbours break

Per this file's standing practice: a green `∀` over a hypothesis nothing can meet
is not evidence. Below: a concrete cycle map that **meets** `CycleRealisesStep`,
and two adjacent maps that **provably fail** it. -/

/-- The wire configuration presenting state `s` on the Q-leaves and word `w` on
the instruction nets — the shape a tile's input map has. -/
def envWith (s : St) (w : Word) : SaltWorks.HDL.Env := fun j =>
  if j < SaltWorks.HDL.stWidth then (SaltWorks.HDL.encD s).getD j false
  else w.getLsbD (j - SaltWorks.HDL.instrBase)

/-- `wordOf` reads 32 bits, so it only cares about 32 bits. -/
theorem wordOf_congr {f g : Nat → Bool} (h : ∀ k, k < 32 → f k = g k) :
    SaltWorks.HDL.wordOf f = SaltWorks.HDL.wordOf g := by
  apply BitVec.eq_of_getLsbD_eq
  intro k hk
  rw [SaltWorks.HDL.wordOf_getLsbD _ _ hk, SaltWorks.HDL.wordOf_getLsbD _ _ hk, h k hk]

/-- **`decQ` reads only the state nets** — `0 … 1055`, per `StateCodec`'s layout.
This is the fact that makes the instruction nets free to carry anything at all
without disturbing the decoded state, and it is why `instrBase = stWidth` was the
right pin. -/
theorem decQ_congr {a b : SaltWorks.HDL.Env}
    (hab : ∀ j, j < SaltWorks.HDL.stWidth → a j = b j) :
    SaltWorks.HDL.decQ a = SaltWorks.HDL.decQ b := by
  simp only [SaltWorks.HDL.decQ, St.mk.injEq]
  refine ⟨?_, wordOf_congr (fun k hk => hab (1024 + k) (by show 1024 + k < 1056; omega))⟩
  apply Vector.ext
  intro i hi
  rw [Vector.getElem_ofFn, Vector.getElem_ofFn]
  exact wordOf_congr (fun k hk => hab (32 * i + k) (by show 32 * i + k < 1056; omega))

theorem decQ_envWith (s : St) (w : Word) : SaltWorks.HDL.decQ (envWith s w) = s := by
  rw [decQ_congr (b := fun j => (SaltWorks.HDL.encD s).getD j false)
        (fun j hj => by simp only [envWith, if_pos hj])]
  exact SaltWorks.HDL.decQ_encD s

theorem seenWord_envWith (s : St) (w : Word) : seenWord (envWith s w) = w := by
  apply BitVec.eq_of_getLsbD_eq
  intro k hk
  rw [seenWord, SaltWorks.HDL.wordOf_getLsbD _ _ hk]
  show (if SaltWorks.HDL.instrNet k < SaltWorks.HDL.stWidth
        then (SaltWorks.HDL.encD s).getD (SaltWorks.HDL.instrNet k) false
        else w.getLsbD (SaltWorks.HDL.instrNet k - SaltWorks.HDL.instrBase))
      = w.getLsbD k
  have hsub : SaltWorks.HDL.instrNet k - SaltWorks.HDL.instrBase = k := by
    show 1056 + k - 1056 = k
    omega
  rw [if_neg (by show ¬ (1056 + k < 1056); omega), hsub]

/-- **A one-cycle machine**: decode the Q-leaves, read the instruction nets,
step, and present the new state together with whatever word comes next.

*This is the trivial witness and it is offered as one* — it is `encD ∘ stepT ∘
decQ` and it proves nothing about any netlist. Its job is to show
`CycleRealisesStep` is a satisfiable constraint rather than a shape, and it is
generic in the next-word policy so it does not smuggle a fetch model in. -/
def cycOf (nextW : St → Word) (ins : SaltWorks.HDL.Env) : SaltWorks.HDL.Env :=
  envWith (stepT (SaltWorks.HDL.decQ ins) (seenWord ins)) (nextW (SaltWorks.HDL.decQ ins))

theorem decQ_cycOf (nextW : St → Word) (ins : SaltWorks.HDL.Env) :
    SaltWorks.HDL.decQ (cycOf nextW ins)
      = stepT (SaltWorks.HDL.decQ ins) (seenWord ins) := decQ_envWith _ _

/-- ⭐ **SATISFIABLE**, for every next-word policy. -/
theorem cycleRealisesStep_cycOf (nextW : St → Word) :
    CycleRealisesStep (cycOf nextW) seenWord := fun ins => decQ_cycOf nextW ins

/-- ⛔ **CONTROL 1 — A STALLED CYCLE FAILS.** A netlist whose flops do not change
satisfies nothing: at a wire configuration holding `St.init` with `addi x1, x0, 1`
on the instruction nets, the ISA writes `x1 = 1` and the stall does not. ⇒ the
hypothesis has content, and `cycles_realise_steps` is not true of every `cyc`. -/
theorem not_cycleRealisesStep_id : ¬ CycleRealisesStep id seenWord := by
  intro h
  have hh := h (envWith St.init (encode (Instr.ADDI 1 0 1)))
  rw [id_eq, decQ_envWith, seenWord_envWith, stepT_encode] at hh
  revert hh
  decide +kernel

/-- 🔴 **CONTROL 2 — THE WRONG 32 WIRES, AS A REFUTATION.** The *same* machine
`cycOf`, paired with `wordOf ins` instead of `seenWord ins`, fails — because
`wordOf ins` reads nets `0 … 31`, which are register `x0`, which is zero, which
the decoder rejects, so the machine appears to NOP while the ISA executes.

*`wordOf ins` typechecks and Lean says nothing.* This theorem is what says
something. -/
theorem not_cycleRealisesStep_wordOf (nextW : St → Word) :
    ¬ CycleRealisesStep (cycOf nextW) (fun ins => SaltWorks.HDL.wordOf ins) := by
  intro h
  have hh := h (envWith St.init (encode (Instr.ADDI 1 0 1)))
  rw [decQ_cycOf, decQ_envWith, seenWord_envWith, stepT_encode] at hh
  revert hh
  decide +kernel

/-! ### ⛔ AGREEMENT WITH `runFor`, AND THE DIVERGENCE -/

/-- One tick, at a known fetch. -/
theorem runFor_one_of_fetch {code : List Instr} {t : St} {i : Instr}
    (h : fetch code t.pc = some i) : runFor 1 code t = step t i :=
  runFor_step 0 h

/-- The `n`-th tick of a run, at a known fetch — `runFor_step` seen from the
other end, which is the end a left fold needs. -/
theorem runFor_succ_of_fetch {code : List Instr} {s : St} {i : Instr} (n : Nat)
    (h : fetch code (runFor n code s).pc = some i) :
    runFor (n + 1) code s = step (runFor n code s) i := by
  rw [runFor_add n 1, runFor_one_of_fetch h]

/-- ⭐ **THE AGREEMENT, AND ITS EXACT PRICE.** `runWords` and `runFor` are the
same for `n` cycles **iff the stream is the program's own fetch for all `n` of
them** — every cycle must both find an instruction and be handed its encoding.
There is no version of this without the `k < n` hypothesis: the moment the fetch
returns `none`, `runFor` stops and `runWords` does not. -/
theorem runWords_eq_runFor {code : List Instr} {ws : Nat → Word} {s : St} (n : Nat) :
    (∀ k, k < n → ∃ i, fetch code (runFor k code s).pc = some i ∧ ws k = encode i) →
    runWords ws n s = runFor n code s := by
  induction n with
  | zero => intro _; rfl
  | succ m ih =>
      intro h
      obtain ⟨i, hf, hw⟩ := h m (by omega)
      rw [runWords_succ, ih (fun k hk => h k (by omega)), hw, stepT_encode,
        runFor_succ_of_fetch m hf]

/-- ⭐ **AND THE OVERRUN IS HARMLESS, IF THE WORDS ARE UNDECODABLE.** `stepT` on a
word the decoder rejects advances the pc and touches no register, so a tile that
keeps cycling past the end of its program still holds the answer — *in the
registers*, which is where the observation is taken. This is the theorem that
makes the third obligation cheap rather than a redesign. -/
theorem runWords_get_of_undecodable {ws : Nat → Word} {s : St} (n : Nat) (r : Fin 32) :
    (∀ k, k < n → decode (ws k) = none) → (runWords ws n s).get r = s.get r := by
  induction n with
  | zero => intro _; rfl
  | succ m ih =>
      intro h
      rw [runWords_succ, stepT_undecodable _ _ (h m (by omega)), next_get_eq]
      exact ih (fun k hk => h k (by omega))

/-- ⭐ **THE INSTRUCTION-STREAM CONTRACT, IN TWO HALVES — and the second half is
the one nobody had written down.**

1. *while the program runs* (`k < K`): the nets carry the fetched instruction —
   this is `DeliversProgram`, indexed by cycle rather than by state;
2. *afterwards* (`K ≤ k`): the nets carry something the decoder **rejects**.

⚠️ **Half 2 is not bookkeeping.** `run` is total and `runFor` halts, so the
software model never had to say what happens after the last instruction. The tile
has no halt, so it must be told. `noisy_tail_overwrites` below is what half 2
buys. -/
def FeedsProgram (code : List Instr) (ws : Nat → Word) (s : St) (K : Nat) : Prop :=
  (∀ k, k < K → ∃ i, fetch code (runFor k code s).pc = some i ∧ ws k = encode i)
    ∧ ∀ k, K ≤ k → decode (ws k) = none

/-- ⭐ **THE TWO NOTIONS AGREE AT THE REGISTERS, AT ANY SUFFICIENT CYCLE COUNT.**
Given the stream contract, running the wires for **any** `N ≥ K` reads the same
registers as running the software model for `K`. The pc does *not* agree — it has
run away — and the statement says so by being about `St.get` only. -/
theorem runWords_get_eq_runFor {code : List Instr} {ws : Nat → Word} {s : St}
    {K : Nat} (hfeed : FeedsProgram code ws s K) {N : Nat} (hN : K ≤ N) (r : Fin 32) :
    (runWords ws N s).get r = (runFor K code s).get r := by
  obtain ⟨d, rfl⟩ := Nat.exists_eq_add_of_le hN
  rw [runWords_add, runWords_eq_runFor K hfeed.1]
  exact runWords_get_of_undecodable d r (fun k _ => hfeed.2 (K + k) (by omega))

/-- **The all-zero word is undecodable** — so a ROM reading zero off the end of
the program discharges `FeedsProgram`'s second half. The cheapest possible
answer to the obligation the section note names. -/
theorem decode_zero : decode 0 = none := by decide +kernel

/-- ⛔ **THE DIVERGENCE, KERNEL-CHECKED.** At `offEndState` — the pc off the end
of the program, which is where *every* completed run of this program sits —
`runFor` is the identity at **every** bound, and ten cycles of the wires have
moved the pc from 480 to 520. *These are not two views of one object; they are
two different functions that agree on a region.* -/
theorem runFor_halts_where_runWords_runs_on :
    (∀ n, runFor n batcherSort offEndState = offEndState)
      ∧ (runWords (fun _ => 0) 10 offEndState).pc = 520 := by
  refine ⟨fun n => runFor_of_fetch_none (by decide +kernel) n, by decide +kernel⟩

/-! ### The bridge to `DeliversProgram` -/

/-- Every word this program's fetch produces is an `encode` — because
`batcherSortWords` is `batcherSort.map encode` and nothing else. The step that
turns `DeliversProgram`'s conclusion into the shape `runWords_eq_runFor` wants. -/
theorem fetchWord_eq_encode {pc : BitVec 32} {w : Word} (h : fetchWord pc = some w) :
    ∃ i, fetch batcherSort pc = some i ∧ w = encode i := by
  unfold fetchWord at h
  by_cases ha : pc.toNat % 4 = 0
  · rw [if_pos ha, batcherSortWords, List.getElem?_map] at h
    cases hb : batcherSort[pc.toNat / 4]? with
    | none => rw [hb] at h; exact absurd h (by simp)
    | some i =>
        rw [hb] at h
        exact ⟨i, by unfold fetch; rw [if_pos ha, hb], by simpa using h.symm⟩
  · rw [if_neg ha] at h; exact absurd h (by simp)

/-- ⭐ **`DeliversProgram` IS `FeedsProgram`'s FIRST HALF** — for a tile whose
input map is a function of the machine state and whose pc stays inside the
program for `K` cycles. So the obligation already stated is exactly the one the
induction consumes, and the only thing this node adds to the demand list is the
second half.

⚠️ **What is still owed and is NOT here:** the coherence fact that the tile's
input map at cycle `k` really is the `k`-th iterate — `env (runFor k code s) =
cycles cyc k ins`. That is a statement about a netlist, so it belongs with C4 and
the tile assembly, not here. -/
theorem feedsFst_of_deliversProgram {env : St → SaltWorks.HDL.Env}
    (hdel : DeliversProgram env) (s : St) (K : Nat)
    (hin : ∀ k, k < K → (fetchWord (runFor k batcherSort s).pc).isSome) :
    ∀ k, k < K → ∃ i, fetch batcherSort (runFor k batcherSort s).pc = some i
      ∧ seenWord (env (runFor k batcherSort s)) = encode i := by
  intro k hk
  obtain ⟨w, hw⟩ := Option.isSome_iff_exists.mp (hin k hk)
  obtain ⟨i, hfetch, hwe⟩ := fetchWord_eq_encode hw
  exact ⟨i, hfetch, (hdel _ w hw).trans hwe⟩

/-! ### ⭐ NON-VACUITY OF `FeedsProgram` — and the control on its second half -/

/-- A one-instruction program, so the stream contract can be met concretely
rather than argued about. -/
def addiOnly : List Instr := [Instr.ADDI 1 0 1]

/-- Its stream: the instruction on cycle 0, zeros thereafter — the zero-filled
ROM, written out. -/
def addiStream : Nat → Word := fun k => if k = 0 then encode (Instr.ADDI 1 0 1) else 0

/-- ⭐ **`FeedsProgram` IS SATISFIABLE**, both halves, on a real program. -/
theorem feedsProgram_addi : FeedsProgram addiOnly addiStream St.init 1 := by
  refine ⟨fun k hk => ?_, fun k hk => ?_⟩
  · have hk0 : k = 0 := by omega
    subst hk0
    exact ⟨Instr.ADDI 1 0 1, by decide +kernel, rfl⟩
  · unfold addiStream
    rw [if_neg (by omega)]
    exact decode_zero

/-- ⭐ **AND THE WHOLE MACHINERY RUNS ON IT: the answer is stable at every
sufficient cycle count.** For *any* `N ≥ 1` the register holds `1` — one cycle of
real work and `N - 1` cycles of harmless overrun. This is the shape a fixed-length
silicon run has, exercised end to end through `runWords_get_eq_runFor`. -/
theorem feedsProgram_addi_runs (N : Nat) (hN : 1 ≤ N) :
    (runWords addiStream N St.init).get 1 = 1 := by
  rw [runWords_get_eq_runFor feedsProgram_addi hN 1]
  decide +kernel

/-- ⛔ **AND THE SECOND HALF IS DOING WORK.** Replace the quiet tail with a live
instruction and the answer is overwritten a little more on every cycle: `1` after
one cycle, `4` after four. So *"run it a bit longer, it can't hurt"* is false on
this machine, and `FeedsProgram`'s second conjunct is what rules it out. -/
theorem noisy_tail_overwrites :
    ¬ (∀ k, 1 ≤ k → decode ((fun _ : Nat => encode (Instr.ADDI 1 1 1)) k) = none)
      ∧ (runWords (fun _ => encode (Instr.ADDI 1 1 1)) 1 St.init).get 1 = 1
      ∧ (runWords (fun _ => encode (Instr.ADDI 1 1 1)) 4 St.init).get 1 = 4 := by
  refine ⟨fun h => ?_, by decide +kernel, by decide +kernel⟩
  have := h 1 (by omega)
  rw [decode_encode] at this
  exact absurd this (by simp)

/-! ### ⭐⭐ THE PAYOFF — given C4, the tile sorts -/

/-- **The cycle count, exposed.** `refinesNetwork_of_pc_zero` discards the `k`
that `emit_runs` produces, because `run`'s `code.length` bound is a software
convenience. Silicon has no such bound — it runs for a number of cycles — so the
`k` is the load-bearing quantity here and this states it: **at most 120 cycles,
after which the machine has halted and the registers hold the network's output.**
(`step_count_data_dependent`: the real number is between 48 and 90, and depends
on the data.) -/
theorem exists_halting_count (s : St) (hpc : s.pc = 0) :
    ∃ K, K ≤ 120 ∧ fetch batcherSort (runFor K batcherSort s).pc = none ∧
      ∀ i : Fin 8, (runFor K batcherSort s).get (dataReg i)
        = runNetW batcher8 (fun j => s.get (dataReg j)) i := by
  have hpc0 : s.pc.toNat = 4 * 0 := by rw [hpc]; rfl
  have hbnd : 4 * 0 + 20 * batcher8.length < 2 ^ 32 := by rw [batcher8_length]; omega
  obtain ⟨k, hk, hkpc, hkreg⟩ :=
    emit_runs batcherSort batcher8 0 s batcherSort_embeds hpc0 hbnd
  rw [batcher8_length] at hk hkpc
  refine ⟨k, by omega, ?_, hkreg⟩
  unfold fetch
  rw [hkpc, if_pos (by omega), show (4 * 0 + 20 * 24) / 4 = 120 by omega]
  exact List.getElem?_eq_none (by rw [batcherSort_length])

/-- ⭐⭐ **THE C5 SENTENCE, over C4 as a hypothesis.** *Given one-cycle
equivalence, a netlist reset into the entry state and fed the program for `K`
cycles and quiet words after, the eight data registers — read off the wires
through `decQ` at ANY cycle count `N ≥ K` — are a signed-sorted permutation of
the input.*

Everything on the right of the turnstile is already in the kernel: `emit_runs`
supplies `K`, `batcher8_sortsTo_word` supplies the sort. What is hypothesised is
exactly three things, and each is owned by a named lane:

* `CycleRealisesStep` — **C4**, the compiler lane. Satisfiable
  (`cycleRealisesStep_cycOf`), discriminating (`not_cycleRealisesStep_id`,
  `not_cycleRealisesStep_wordOf`).
* `EntryLoaded` — the reset, the silicon lane. Satisfiable
  (`entryLoaded_encD_stOfFn`), discriminating (`not_entryLoaded_offEndEnv`).
* `FeedsProgram` — the instruction path, the tile lane. Satisfiable
  (`feedsProgram_addi`), discriminating (`noisy_tail_overwrites`); its first half
  is `DeliversProgram` (`feedsFst_of_deliversProgram`) and its second half is new
  today.

Nothing else is assumed, and no statement above this one was weakened to get
here. -/
theorem cycles_sort {cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env}
    {wordAt : SaltWorks.HDL.Env → Word} (h : CycleRealisesStep cyc wordAt)
    {ins : SaltWorks.HDL.Env} {v : Fin 8 → Word} (hentry : EntryLoaded ins v) :
    ∃ K, K ≤ 120 ∧ ∀ N, K ≤ N →
      FeedsProgram batcherSort (fun k => wordAt (cycles cyc k ins))
        (SaltWorks.HDL.decQ ins) K →
      SortsTo (List.ofFn v)
        (dataRegs.map (SaltWorks.HDL.decQ (cycles cyc N ins)).get) := by
  obtain ⟨hpc, hreg⟩ := hentry
  obtain ⟨K, hK, _, hregs⟩ := exists_halting_count (SaltWorks.HDL.decQ ins) hpc
  refine ⟨K, hK, fun N hN hfeed => ?_⟩
  have hv : (fun j => (SaltWorks.HDL.decQ ins).get (dataReg j)) = v := funext hreg
  have key : (fun i : Fin 8 => (SaltWorks.HDL.decQ (cycles cyc N ins)).get (dataReg i))
      = runNetW batcher8 v := by
    funext i
    rw [cycles_realise_steps h N ins, runWords_get_eq_runFor hfeed hN (dataReg i),
      hregs i, hv]
  rw [dataRegs_map_get, key]
  exact batcher8_sortsTo_word v

/-! ## ⭐⭐ C4BRIDGE — THE MISSING LINK BETWEEN `C4Spec` AND `CycleRealisesStep`

**The two lanes wrote two halves of one sentence and nothing joined them.**

* Compiler's `HDL.C4Spec c` is about **`sem c ins`** — a `List Bool`, the
  circuit's output ports in port order.
* Math's `CycleRealisesStep cyc wordAt` is about a **cycle function**
  `cyc : Env → Env` on wires.

⇒ *Even with C4 in hand, `cycles_sort` could not consume it*, because no
definition said which wires `sem c ins` lands on. This section is that
definition and the two theorems that ride on it, so that **the day C4 is proved
the end-to-end theorem fires with no further work.**

### The content is the codec round trip, and one obligation the type system cannot see

`cycOfCirc` puts output port `j` on state net `j` — the D→Q flop transfer, in
`StateCodec`'s own layout — and `nextW ins` on the instruction nets. `C4Spec`
says the port list *is* `encD (stepT …)`, and `decQ_encD` turns that back into
the state. **That step is legal only because the two lists have the same length**
(C4.lean's 14:17 hazard: 1055 against 1056, well-typed either way), and this
section does not assume the length — it *carries the failure mode in the model*.
`envOfBits` takes a `pad : Env` for the state nets **the output list does not
reach**, because a core with too few outputs leaves those flops undriven and
`false` would be a fiction. Every theorem below is universally quantified in
`pad`; `cycOfBits_pad_irrelevant` says the pad is invisible when the length is
right, and `cycOfBits_shortBits_pad_dependent` says it is visible when it is not.

### ⚠️ THE FINDING — the bridge needs `C4Spec` and **not** `CoreConforms`

The brief expected `CoreConforms`'s `outs.length = stWidth` to be what makes the
round trip legal. It *is* the fact that makes it legal — but it is **implied by
`C4Spec` itself**, because `C4Spec` is an equality of *lists* and `encD`'s length
is `stWidth` unconditionally. `outs_length_of_C4Spec` below is that derivation.
⇒ **Nothing was weakened and nothing was restated**: the bridge is stated from
the `spec` field alone, which is the stronger theorem, and
`cycleRealisesStep_of_C4` is the `C4`-structure interface compiler's own
docstring asks callers to use. `CoreConforms` is still owed — its `ssa` conjunct
feeds `Circ.wf_of_ssa` and the emission layer, and its `nIn = coreInWidth`
conjunct is the input-map obligation — but **neither of those is a debt of the
codec round trip**, and saying otherwise would have been a fake dependency.

### ⛔ Non-vacuity, and what cannot be witnessed today

`cycleRealisesStep_of_C4Spec`'s premise is C4, so **no `Circ` can witness it**
until `core` exists. What the bridge's proof actually consumes is the *bits*
hypothesis, and that is witnessed (`cycleRealisesStep_idealBits`) and
discriminating (`not_cycleRealisesStep_stalledBits`,
`cycOfBits_shortBits_pad_dependent`) — three controls through the same code path.
At the `Circ` level, `not_both_coreShaped_C4Spec` is the strongest thing that can
be said and it is said: compiler's two conforming circuits compute different
things, so **at most one of them can ever be bridged.** -/

/-- The two seats wrote the same 32 wires. `HDL.seenWord` (C4.lean:66) and this
file's `seenWord` are the same function, so `C4Spec`'s word and
`CycleRealisesStep`'s word need no translation. *Stated rather than assumed: the
one thing a bridge between two lanes must not get wrong is which wires it is
about, and `not_cycleRealisesStep_wordOf` is what the wrong answer looks like.* -/
theorem seenWord_eq_hdl : seenWord = SaltWorks.HDL.seenWord := rfl

/-- `encD` is `stWidth` bits, unconditionally — the fact the padding argument
turns on. -/
theorem encD_length (s : St) : (SaltWorks.HDL.encD s).length = SaltWorks.HDL.stWidth := by
  rw [SaltWorks.HDL.encD, List.length_map, List.length_range]

/-- **The wire configuration a bit list induces.** State net `j` carries element
`j` of `bs`; ⚠️ **a state net the list does not reach carries `pad j`**, because a
core with too few outputs leaves that flop undriven and there is no honest
default; instruction nets carry `w`. *Compare `envWith`, which is this at
`bs = encD s` — see `envOfBits_encD`.* -/
def envOfBits (bs : List Bool) (pad : SaltWorks.HDL.Env) (w : Word) : SaltWorks.HDL.Env :=
  fun j =>
    if j < SaltWorks.HDL.stWidth then bs.getD j (pad j)
    else w.getLsbD (j - SaltWorks.HDL.instrBase)

/-- ⭐ **THE LENGTH OBLIGATION, DISCHARGING THE PADDING.** A list long enough to
cover the state nets makes the undriven-wire model invisible. -/
theorem envOfBits_of_length {bs : List Bool} (hlen : SaltWorks.HDL.stWidth ≤ bs.length)
    (pad pad' : SaltWorks.HDL.Env) (w : Word) : envOfBits bs pad w = envOfBits bs pad' w := by
  funext j
  show (if j < SaltWorks.HDL.stWidth then bs.getD j (pad j) else _)
      = (if j < SaltWorks.HDL.stWidth then bs.getD j (pad' j) else _)
  by_cases hj : j < SaltWorks.HDL.stWidth
  · have h1 : j < bs.length := Nat.lt_of_lt_of_le hj hlen
    rw [if_pos hj, if_pos hj, List.getD_eq_getElem?_getD, List.getD_eq_getElem?_getD,
      List.getElem?_eq_getElem h1]
    rfl
  · rw [if_neg hj, if_neg hj]

/-- At a full state encoding this **is** `envWith`, for every pad — so the whole
existing witness apparatus (`decQ_envWith`, `seenWord_envWith`) applies. -/
theorem envOfBits_encD (s : St) (pad : SaltWorks.HDL.Env) (w : Word) :
    envOfBits (SaltWorks.HDL.encD s) pad w = envWith s w := by
  rw [envOfBits_of_length (le_of_eq (encD_length s).symm) pad (fun _ => false) w]
  rfl

/-- The instruction half is faithful: whatever `w` was put on the instruction
nets is what `seenWord` reads back. *`seenWord_envWith`'s argument, at an
arbitrary bit list.* -/
theorem seenWord_envOfBits (bs : List Bool) (pad : SaltWorks.HDL.Env) (w : Word) :
    seenWord (envOfBits bs pad w) = w := by
  apply BitVec.eq_of_getLsbD_eq
  intro k hk
  rw [seenWord, SaltWorks.HDL.wordOf_getLsbD _ _ hk]
  show (if SaltWorks.HDL.instrNet k < SaltWorks.HDL.stWidth
        then bs.getD (SaltWorks.HDL.instrNet k) (pad (SaltWorks.HDL.instrNet k))
        else w.getLsbD (SaltWorks.HDL.instrNet k - SaltWorks.HDL.instrBase))
      = w.getLsbD k
  have hsub : SaltWorks.HDL.instrNet k - SaltWorks.HDL.instrBase = k := by
    show 1056 + k - 1056 = k
    omega
  rw [if_neg (by show ¬ (1056 + k < 1056); omega), hsub]

/-- **The cycle map an output-bit function induces**, with the instruction-net
policy left as an arbitrary `nextW : Env → Word`. *Arbitrary on purpose: a ROM
indexed by the old pc and a ROM indexed by the new one are both functions of the
current wire state, so this commits to neither, and `FeedsProgram` is where the
policy is constrained.* -/
def cycOfBits (f : SaltWorks.HDL.Env → List Bool) (nextW : SaltWorks.HDL.Env → Word)
    (pad : SaltWorks.HDL.Env) (ins : SaltWorks.HDL.Env) : SaltWorks.HDL.Env :=
  envOfBits (f ins) pad (nextW ins)

/-- ⭐ **THE BRIDGE, at the level its proof actually works at.** A bit function
that agrees with `encD ∘ stepT ∘ decQ` induces a cycle map realising the step —
for every next-word policy and every pad. -/
theorem cycleRealisesStep_of_bits {f : SaltWorks.HDL.Env → List Bool}
    (h : ∀ ins, f ins
      = SaltWorks.HDL.encD (stepT (SaltWorks.HDL.decQ ins) (seenWord ins)))
    (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env) :
    CycleRealisesStep (cycOfBits f nextW pad) seenWord := by
  intro ins
  rw [cycOfBits, h ins, envOfBits_encD]
  exact decQ_envWith _ _

/-- ⭐ **THE CYCLE MAP A CIRCUIT INDUCES** — output port `j` becomes state net
`j`, which is the D→Q transfer in `StateCodec`'s layout and is the definition
that was missing. -/
def cycOfCirc (c : SaltWorks.HDL.Circ) (nextW : SaltWorks.HDL.Env → Word)
    (pad : SaltWorks.HDL.Env) : SaltWorks.HDL.Env → SaltWorks.HDL.Env :=
  cycOfBits (SaltWorks.HDL.sem c) nextW pad

/-- What the core sees next cycle is exactly `nextW` of this cycle's wires. The
reading that makes `sorts_of_C4`'s `FeedsProgram` hypothesis legible. -/
theorem seenWord_cycOfCirc (c : SaltWorks.HDL.Circ) (nextW : SaltWorks.HDL.Env → Word)
    (pad ins : SaltWorks.HDL.Env) : seenWord (cycOfCirc c nextW pad ins) = nextW ins :=
  seenWord_envOfBits _ _ _

/-- ⭐⭐ **THE BRIDGE — `C4Spec` DISCHARGES `CycleRealisesStep`.** The theorem
whose absence meant a proved C4 would still not reach `cycles_sort`. -/
theorem cycleRealisesStep_of_C4Spec {c : SaltWorks.HDL.Circ} (h : SaltWorks.HDL.C4Spec c)
    (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env) :
    CycleRealisesStep (cycOfCirc c nextW pad) seenWord :=
  cycleRealisesStep_of_bits (f := SaltWorks.HDL.sem c) h nextW pad

/-- The same, through the `C4` structure — *"C4 as it should be USED"*, in
compiler's words. -/
theorem cycleRealisesStep_of_C4 {c : SaltWorks.HDL.Circ} (hC4 : SaltWorks.HDL.C4 c)
    (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env) :
    CycleRealisesStep (cycOfCirc c nextW pad) seenWord :=
  cycleRealisesStep_of_C4Spec hC4.spec nextW pad

/-- ⚠️ **`CoreConforms`'S THIRD CONJUNCT IS IMPLIED BY `C4Spec`.** The output
count the type system cannot see is pinned by the specification itself, because
`C4Spec` is an equality of *lists*. *So the bridge above owes nothing to
`CoreConforms`, and the honest statement is the one that does not ask for it.
`CoreConforms` remains owed for `ssa` (the emission layer) and for the input
width — different obligations, different consumers.* -/
theorem outs_length_of_C4Spec {c : SaltWorks.HDL.Circ} (h : SaltWorks.HDL.C4Spec c) :
    c.outs.length = SaltWorks.HDL.stWidth := by
  have hh := congrArg List.length (h (fun _ => false))
  rwa [SaltWorks.HDL.sem, List.length_map, encD_length] at hh

/-- ⭐⭐⭐ **THE END-TO-END THEOREM — GIVEN C4, THE COMPILED CIRCUIT SORTS.**

*A circuit satisfying C4, wired so its output ports drive the state flops, reset
into the entry state and fed the program: the eight data registers, read off the
wires through `decQ` at any cycle count `N ≥ K`, are a signed-sorted permutation
of the input.*

⭐ **THE SURVIVING HYPOTHESES ARE EXACTLY THREE, AND EACH IS A NAMED LANE'S:**

1. `SaltWorks.HDL.C4 c` — the **compiler**. Unwitnessable today (`core` does not
   exist); `outs_length_of_C4Spec` shows the bridge uses only its `spec` field.
2. `EntryLoaded ins v` — the **reset**, the silicon lane. Satisfiable
   (`entryLoaded_encD_stOfFn`), discriminating (`not_entryLoaded_offEndEnv`).
3. `FeedsProgram batcherSort (fun k => seenWord (cycles … k ins)) … K` — the
   **instruction path**, the tile lane. Satisfiable (`feedsProgram_addi`),
   discriminating (`noisy_tail_overwrites`); by `seenWord_cycOfCirc` the stream
   it constrains is literally `nextW` along the cycle sequence, so it is a
   demand on the tile's ROM and on nothing else.

**Nothing else is assumed.** `nextW` and `pad` are universally quantified — the
theorem holds for *every* instruction-net policy and *every* behaviour of
undriven state flops — so neither is a hypothesis, and no statement above this
one was weakened to get here. -/
theorem sorts_of_C4 {c : SaltWorks.HDL.Circ} (hC4 : SaltWorks.HDL.C4 c)
    (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env)
    {ins : SaltWorks.HDL.Env} {v : Fin 8 → Word} (hentry : EntryLoaded ins v) :
    ∃ K, K ≤ 120 ∧ ∀ N, K ≤ N →
      FeedsProgram batcherSort
        (fun k => seenWord (cycles (cycOfCirc c nextW pad) k ins))
        (SaltWorks.HDL.decQ ins) K →
      SortsTo (List.ofFn v)
        (dataRegs.map (SaltWorks.HDL.decQ (cycles (cycOfCirc c nextW pad) N ins)).get) :=
  cycles_sort (cycleRealisesStep_of_C4 hC4 nextW pad) hentry

/-! ### ⭐ NON-VACUITY AND THE CONTROLS

Per this file's standing practice. The `Circ`-level premise is C4 itself and
cannot be witnessed until `core` exists — that is a fact about the campaign, not
a gap in this section — so the witnesses are placed where the bridge's proof
actually consumes its hypothesis: at `cycleRealisesStep_of_bits`. Same code path,
same conclusion. -/

/-- The ideal core's output list — `encD ∘ stepT ∘ decQ`, offered as the trivial
witness it is. -/
def idealBits (ins : SaltWorks.HDL.Env) : List Bool :=
  SaltWorks.HDL.encD (stepT (SaltWorks.HDL.decQ ins) (seenWord ins))

/-- ✅ **THE BRIDGE IS NOT VACUOUS** — its hypothesis is met, for every next-word
policy and every pad, and the conclusion comes out through
`cycleRealisesStep_of_bits`. -/
theorem cycleRealisesStep_idealBits (nextW : SaltWorks.HDL.Env → Word)
    (pad : SaltWorks.HDL.Env) :
    CycleRealisesStep (cycOfBits idealBits nextW pad) seenWord :=
  cycleRealisesStep_of_bits (fun _ => rfl) nextW pad

/-- A core whose outputs re-present the state it was given: the stall. -/
def stalledBits (ins : SaltWorks.HDL.Env) : List Bool :=
  SaltWorks.HDL.encD (SaltWorks.HDL.decQ ins)

theorem decQ_cycOfBits_stalled (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env)
    (ins : SaltWorks.HDL.Env) :
    SaltWorks.HDL.decQ (cycOfBits stalledBits nextW pad ins) = SaltWorks.HDL.decQ ins := by
  rw [cycOfBits, stalledBits, envOfBits_encD]
  exact decQ_envWith _ _

/-- ⛔ **CONTROL 1 — THE STALLED CORE FAILS THROUGH THE BRIDGE.** `cycOfBits` is
not a construction that makes anything realise a step: at `St.init` with
`addi x1, x0, 1` on the instruction nets the ISA writes `x1 = 1` and the stall
does not. *`not_cycleRealisesStep_id`'s witness, now aimed at the circuit-level
cycle map instead of the abstract one.* -/
theorem not_cycleRealisesStep_stalledBits (nextW : SaltWorks.HDL.Env → Word)
    (pad : SaltWorks.HDL.Env) :
    ¬ CycleRealisesStep (cycOfBits stalledBits nextW pad) seenWord := by
  intro h
  have hh := h (envWith St.init (encode (Instr.ADDI 1 0 1)))
  rw [decQ_cycOfBits_stalled, decQ_envWith, seenWord_envWith, stepT_encode] at hh
  revert hh
  decide +kernel

/-- 🔴 **The 1055-output core of `C4.lean`'s hazard, at the bit level** — the
ideal core with its last output port removed. -/
def shortBits (ins : SaltWorks.HDL.Env) : List Bool :=
  (idealBits ins).take (SaltWorks.HDL.stWidth - 1)

theorem shortBits_length (ins : SaltWorks.HDL.Env) :
    (shortBits ins).length = SaltWorks.HDL.stWidth - 1 := by
  rw [shortBits, List.length_take, idealBits, encD_length]
  omega

theorem shortBits_reads_the_pad (ins pad : SaltWorks.HDL.Env) (w : Word) :
    envOfBits (shortBits ins) pad w (SaltWorks.HDL.stWidth - 1)
      = pad (SaltWorks.HDL.stWidth - 1) := by
  have hlen := shortBits_length ins
  show (if SaltWorks.HDL.stWidth - 1 < SaltWorks.HDL.stWidth then _ else _) = _
  rw [if_pos (by decide +kernel), List.getD_eq_getElem?_getD,
    List.getElem?_eq_none (by omega)]
  rfl

/-- ⛔ **CONTROL 2 — ONE OUTPUT SHORT AND THE UNDRIVEN FLOP IS WHAT THE MACHINE
RUNS ON.** The two cycle maps differ at net 1055 — the pc's top bit — purely in
the pad, so *what the tile computes is decided by a wire the circuit does not
drive.* **This is C4.lean's 1055-against-1056 hazard, propagated through the
bridge and refuted rather than warned about**, and it is why `envOfBits` carries
a pad instead of quietly defaulting to `false`. -/
theorem cycOfBits_shortBits_pad_dependent (nextW : SaltWorks.HDL.Env → Word)
    (ins : SaltWorks.HDL.Env) :
    cycOfBits shortBits nextW (fun _ => false) ins
      ≠ cycOfBits shortBits nextW (fun _ => true) ins := by
  intro h
  have hh := congrFun h (SaltWorks.HDL.stWidth - 1)
  rw [cycOfBits, cycOfBits, shortBits_reads_the_pad, shortBits_reads_the_pad] at hh
  exact absurd hh (by simp)

/-- ✅ **AND THE OTHER SIDE OF CONTROL 2 — with the length right, the pad is
invisible.** So the padding is not a modelling assumption smuggled into the
bridge: it is a failure mode the bridge's own hypothesis excludes. -/
theorem cycOfBits_pad_irrelevant {f : SaltWorks.HDL.Env → List Bool}
    (hlen : ∀ ins, SaltWorks.HDL.stWidth ≤ (f ins).length)
    (nextW : SaltWorks.HDL.Env → Word) (pad pad' : SaltWorks.HDL.Env) :
    cycOfBits f nextW pad = cycOfBits f nextW pad' := by
  funext ins
  exact envOfBits_of_length (hlen ins) pad pad' _

/-- ⭐ **AND `C4Spec` SUPPLIES THE LENGTH** — a bridged circuit's cycle map does
not depend on the pad at all. -/
theorem cycOfCirc_pad_irrelevant {c : SaltWorks.HDL.Circ} (h : SaltWorks.HDL.C4Spec c)
    (nextW : SaltWorks.HDL.Env → Word) (pad pad' : SaltWorks.HDL.Env) :
    cycOfCirc c nextW pad = cycOfCirc c nextW pad' :=
  cycOfBits_pad_irrelevant
    (fun ins => le_of_eq ((congrArg List.length (h ins)).trans (encD_length _)).symm)
    nextW pad pad'

/-- ⛔ **CONTROL 3 — CONFORMING IS NOT BEING BRIDGEABLE.** Compiler's two
structurally-conforming circuits compute different things
(`conformance_does_not_determine_semantics`), so **at most one of them can ever
satisfy `C4Spec`** and be carried into `sorts_of_C4`. *The `Circ`-level statement
that the premise of the bridge is a real constraint and not a shape — which is
the strongest thing sayable while `core` does not exist.* -/
theorem not_both_coreShaped_C4Spec :
    ¬ (SaltWorks.HDL.C4Spec SaltWorks.HDL.coreShaped
        ∧ SaltWorks.HDL.C4Spec SaltWorks.HDL.coreShapedT) := by
  rintro ⟨h1, h2⟩
  exact SaltWorks.HDL.conformance_does_not_determine_semantics
    ((h1 (fun _ => false)).trans (h2 (fun _ => false)).symm)

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
#audit_axioms offEndState refinesNetwork_is_false sortsAllInputs_is_false
#audit_axioms runFor_succ runFor_of_fetch_none runFor_step runFor_add
#audit_axioms runFor_eq_of_halted
#audit_axioms step_count_data_dependent already_sorted_input_still_swaps
#audit_axioms dataReg_ne_zero dataReg_ne_tmp dataReg_inj
#audit_axioms set_pc next_get_eq pc_upd_get xor_cancel_right xor_cancel_left
#audit_axioms step_slt_pc step_xor_pc step_slt_get_ne step_slt_get_self
#audit_axioms step_xor_get_ne step_xor_get_self step_beq_taken step_beq_not
#audit_axioms applyCompW_eq cmpEx_block
#audit_axioms fetch_of_toNat toNat_add_of EmbedsAt emit_cons
#audit_axioms embeds_head embeds_tail emit_runs
#audit_axioms batcherSort_embeds refinesNetwork_of_pc_zero sortsRegs_of_pc_zero
#audit_axioms stOfFn_pc cmpEx6_does_not_refine cmpExFlip_does_not_refine
#audit_axioms stOfFn_dataReg_eq stOfFn_get_dataReg
#audit_axioms stOfFn_refines_network stOfFn_sorts stOfFn_sortsRegs
#audit_axioms EntryLoaded sorts_of_entryLoaded entryLoaded_encD_stOfFn
#audit_axioms offEndEnv not_entryLoaded_offEndEnv offEndEnv_does_not_sort
#audit_axioms fetchWord fetchWord_decodes DeliversProgram
#audit_axioms runWords runWords_succ runWords_add
#audit_axioms cycles cycles_succ cycles_add
#audit_axioms seenWord CycleRealisesStep cycles_realise_steps
#audit_axioms envWith wordOf_congr decQ_congr decQ_envWith seenWord_envWith
#audit_axioms cycOf decQ_cycOf cycleRealisesStep_cycOf
#audit_axioms not_cycleRealisesStep_id not_cycleRealisesStep_wordOf
#audit_axioms runFor_one_of_fetch runFor_succ_of_fetch runWords_eq_runFor
#audit_axioms runWords_get_of_undecodable FeedsProgram runWords_get_eq_runFor
#audit_axioms decode_zero runFor_halts_where_runWords_runs_on
#audit_axioms fetchWord_eq_encode feedsFst_of_deliversProgram
#audit_axioms addiOnly addiStream feedsProgram_addi feedsProgram_addi_runs
#audit_axioms noisy_tail_overwrites exists_halting_count cycles_sort
#audit_axioms seenWord_eq_hdl encD_length envOfBits envOfBits_of_length envOfBits_encD
#audit_axioms seenWord_envOfBits cycOfBits cycleRealisesStep_of_bits
#audit_axioms cycOfCirc seenWord_cycOfCirc
#audit_axioms cycleRealisesStep_of_C4Spec cycleRealisesStep_of_C4
#audit_axioms outs_length_of_C4Spec sorts_of_C4
#audit_axioms idealBits cycleRealisesStep_idealBits
#audit_axioms stalledBits decQ_cycOfBits_stalled not_cycleRealisesStep_stalledBits
#audit_axioms shortBits shortBits_length shortBits_reads_the_pad
#audit_axioms cycOfBits_shortBits_pad_dependent
#audit_axioms cycOfBits_pad_irrelevant cycOfCirc_pad_irrelevant
#audit_axioms not_both_coreShaped_C4Spec

end SaltWorks.Stack.Program
