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

end SaltWorks.Stack.Program
