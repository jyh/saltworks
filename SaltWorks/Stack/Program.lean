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
import SaltWorks.HDL.Bitwise
import SaltWorks.HDL.PcNext
import SaltWorks.HDL.AluSelect
import SaltWorks.HDL.ReadTree
import SaltWorks.HDL.RegNext

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

⚠️ `imm.toInt`, **not** `imm.toNat`: see `forwardness_must_be_signed`.

⬥⬥ **THE CATCH-ALL IS GONE (Captain's ruling, 2026-08-11 19:05: exhaustive arms
preferred in all cases). SEMANTICS UNCHANGED — these arms return exactly what
`| _ => true` returned.**

⛔ **WHY IT MATTERED HERE MORE THAN AT THE OTHER TWO CATCH-ALL SITES, measured
at the refuter pass:** `isForward` and `touchesMem` are FENCED — each has a
downstream theorem that is `cases i`-exhaustive and goes RED on a wrongly
absorbed constructor. **This one was NOT.** Every consumer
(`cmpEx_branches_forward`, `emit_branches_forward`,
`batcherSort_branches_forward`) quantifies over MEMBERSHIP IN A CONCRETE LIST —
`∀ i ∈ emit net, …` — never over `Instr`. So a new constructor was classified
forward, **nothing went red, and every theorem stayed TRUE**, right up until the
day someone emitted it.

🔑 ***A catch-all is safe exactly when some downstream theorem is exhaustive over
the same type and would break. List-membership consumers are not that theorem —
they are the shape that makes the silence permanent.*** *Today the absorbed arms
were genuinely forward (`LW`/`SW` are not branches). The hazard was a future
branch-like op — `JAL`, `JALR`, a trap-return — which the ③ datapath campaign
makes considerably less hypothetical.* -/
def branchIsForward : Instr → Bool
  | .BEQ  _ _ imm => 0 < imm.toInt
  | .ADD  _ _ _   => true
  | .ADDI _ _ _   => true
  | .XOR  _ _ _   => true
  | .SLT  _ _ _   => true
  | .LW   _ _ _   => true
  | .SW   _ _ _   => true

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
round trip `decQ_encD_proj`. *This is the discharge, modulo the one thing missing:
a theorem that says the flops actually come out of reset holding these bits.*
Everything downstream of that is already here. -/
theorem entryLoaded_encD_stOfFn (v : Fin 8 → Word) :
    EntryLoaded (fun j => (SaltWorks.HDL.encD (stOfFn v)).getD j false) v := by
  refine ⟨?_, ?_⟩ <;> rw [SaltWorks.HDL.decQ_encD_of_clean _ rfl rfl]
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
  rw [SaltWorks.HDL.decQ_encD_of_clean _ rfl rfl] at hpc
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
  rw [SaltWorks.HDL.decQ_encD_of_clean _ rfl rfl]
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
whole program. When C4 lands it discharges `CycleRealisesStepProj` and the two halves
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
netlist's one-cycle observation and `wordAt` at `seenWord`.

⬥⬥ **M2 — RE-CUT TO THE (regs,pc) PROJECTION, and the old name
`CycleRealisesStep` IS RETIRED** (helm ruling 16:59).

⛔ **THE WHOLE-St FORM IS NOT MERELY UNPROVED UNDER M2 — IT IS UNSATISFIABLE.**
`decQ` CONSTRUCTS `mem := replicate 8 0` and `trapped := false` (M1a: `encD`
encodes 1056 bits, regs and pc only), so the left side is clean **for every
`cyc`, always**. Once `stepT` can execute a store the right side is dirty. No
cycle map could meet it — the constraint would be a shape with no inhabitants,
which is exactly what the non-vacuity section below exists to prevent.

🔑 ***THE PROJECTION IS NOT A WEAKENING, IT IS THE CODEC'S ACTUAL COVERAGE.***
§0.2 of the memory block always priced this: the core codec covers **(regs, pc)
ONLY**; `mem` lives in the `dmem8` organ across the F4 bridge, deliberately not
mirrored. *Memory realisation is stage ③'s commissioned obligation at that
bridge — this predicate now says what it can honestly say, and no more.* -/
def CycleRealisesStepProj (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env)
    (wordAt : SaltWorks.HDL.Env → Word) : Prop :=
  ∀ ins, (SaltWorks.HDL.decQ (cyc ins)).regs
           = (stepT (SaltWorks.HDL.decQ ins) (wordAt ins)).regs
       ∧ (SaltWorks.HDL.decQ (cyc ins)).pc
           = (stepT (SaltWorks.HDL.decQ ins) (wordAt ins)).pc

/-- ⬥ **M2 — A WORD THAT CANNOT TOUCH MEMORY.** The hypothesis finding 4 showed
the n-step deliverable needs: stated on the WORD, because that is what a cycle
map sees. An undecodable word is vacuously memory-free — it is a NOP-advance. -/
def MemFree (w : Word) : Prop :=
  ∀ i, SaltWorks.ISA.decode w = some i → SaltWorks.ISA.touchesMem i = false

/-- Field-wise extensionality for `St`, used to rebuild a whole-state equality
from the projection once cleanliness supplies the other two fields. -/
theorem St_eq_of_fields {a b : St} (hr : a.regs = b.regs) (hp : a.pc = b.pc)
    (hm : a.mem = b.mem) (ht : a.trapped = b.trapped) : a = b := by
  obtain ⟨r1, p1, m1, t1⟩ := a
  obtain ⟨r2, p2, m2, t2⟩ := b
  simp_all

/-- `decQ` builds both new fields as literals, so cleanliness is definitional. -/
theorem decQ_mem (e : SaltWorks.HDL.Env) :
    (SaltWorks.HDL.decQ e).mem = Vector.replicate 8 0 := rfl

theorem decQ_trapped (e : SaltWorks.HDL.Env) :
    (SaltWorks.HDL.decQ e).trapped = false := rfl



/-! ### ⭐ NON-VACUITY — the hypothesis is satisfiable, and the neighbours break

Per this file's standing practice: a green `∀` over a hypothesis nothing can meet
is not evidence. Below: a concrete cycle map that **meets** `CycleRealisesStepProj`,
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
  simp only [SaltWorks.HDL.decQ, St.mk.injEq, and_true]
  refine ⟨?_, wordOf_congr (fun k hk => hab (1024 + k) (by show 1024 + k < 1056; omega))⟩
  apply Vector.ext
  intro i hi
  rw [Vector.getElem_ofFn, Vector.getElem_ofFn]
  exact wordOf_congr (fun k hk => hab (32 * i + k) (by show 32 * i + k < 1056; omega))

/-- ⬥ **M1a — THE HUB, RESTATED.** `decQ (envWith s w) = s` is a whole-`St`
equality and goes FALSE once `St` carries `mem`/`trapped`: `envWith` presents
1056 encoded bits, so the decoder rebuilds the new fields at their defaults. The
honest unconditional form names exactly that state — `s` with the defaults
installed — and it serves every consumer, including the ten that quantify over an
arbitrary `s` and so have no cleanliness hypothesis to discharge. -/
theorem decQ_envWith_eq (s : St) (w : Word) :
    SaltWorks.HDL.decQ (envWith s w)
      = { s with mem := Vector.replicate 8 0, trapped := false } := by
  rw [decQ_congr (b := fun j => (SaltWorks.HDL.encD s).getD j false)
        (fun j hj => by simp only [envWith, if_pos hj])]
  obtain ⟨hr, hp⟩ := SaltWorks.HDL.decQ_encD_proj s
  simp only [SaltWorks.HDL.decQ, St.mk.injEq, and_true] at hr hp ⊢
  exact ⟨hr, hp⟩

/-- ⬥ **M1a — THE (A)-FORM, per the 18:53 ruling: per-constructor projection
facts, no predicate.** Every slice-A arm is built from `.set` / `.next` / `.get`
and one `{ s with pc := … }` — all `with`-updates that copy what they do not name
— so installing different `mem`/`trapped` cannot move either projection.

⬥⬥ **M2 — RE-CUT (helm ruling 2026-08-11 16:48), and the old name
`step_regs_of_with` IS RETIRED rather than kept.**

⛔ **WHY THE RENAME IS NOT COSMETIC.** The unconditional form was TRUE for the
memory-less machine and is FALSE the moment `LW` exists: `LW` writes `rd` FROM
MEMORY, so installing a different `mem` moves the `regs` projection. Witness —
`LW x2, 0(x0)` at an ok address with `m = replicate 8 1` against
`s.mem = replicate 8 0` puts `1` in `x2` on one side and `0` on the other.
**A narrowed meaning may not keep its name** (the restatement-renames law): every
pre-M2 citation of `step_regs_of_with` must FAIL LOUDLY rather than resolve to a
weaker theorem it never asked for. -/
theorem step_regs_of_with_of_not_touchesMem (s : St) (m : Vector (BitVec 32) 8)
    (t : Bool) (i : Instr) (h : SaltWorks.ISA.touchesMem i = false) :
    (SaltWorks.ISA.step { s with mem := m, trapped := t } i).regs
      = (SaltWorks.ISA.step s i).regs := by
  cases i
  case LW rd a imm => simp [SaltWorks.ISA.touchesMem] at h
  case SW a b imm  => simp [SaltWorks.ISA.touchesMem] at h
  all_goals
    (simp only [SaltWorks.ISA.step, St.set, St.next, St.get]; split_ifs <;> rfl)

/-- **This one SURVIVES UNCHANGED, and the reason is worth a sentence rather
than a silence:** every new arm — the `ok` branch AND both trap branches — ends
in `.next`, so `LW`/`SW` advance `pc` by four whatever the address does and
whatever `mem` holds. `pc` never depends on memory. *It kept its name because it
kept its meaning.* -/
theorem step_pc_of_with (s : St) (m : Vector (BitVec 32) 8) (t : Bool) (i : Instr) :
    (SaltWorks.ISA.step { s with mem := m, trapped := t } i).pc
      = (SaltWorks.ISA.step s i).pc := by
  cases i <;>
    simp only [SaltWorks.ISA.step, St.set, St.next, St.get] <;>
    split_ifs <;> rfl

/-- ⬥⬥ **M2 — RE-CUT.** Was `step_mem_eq`, unconditional; that name is RETIRED.
`SW` at an ok address writes `mem[a/4]`, so the unconditional form asserted that
a memory write does not write memory. **There is no arm that proves it** — this
is a statement whose era ended, not a proof obligation. Its positive complement
(`step_SW_ok_writes_the_addressed_word`) lands below: the frame law and the
write-characterization are the two halves of one truth. -/
theorem step_mem_frame_of_not_touchesMem (s : St) (i : Instr)
    (h : SaltWorks.ISA.touchesMem i = false) :
    (SaltWorks.ISA.step s i).mem = s.mem := by
  cases i
  case LW rd a imm => simp [SaltWorks.ISA.touchesMem] at h
  case SW a b imm  => simp [SaltWorks.ISA.touchesMem] at h
  all_goals (simp only [SaltWorks.ISA.step, St.set, St.next]; split_ifs <;> rfl)

/-- ⬥⬥ **M2 — RE-CUT.** Was `step_trapped_eq`. Falsified by BOTH trap arms of
BOTH new ops: a misaligned or out-of-range address sets the sticky flag. -/
theorem step_trapped_frame_of_not_touchesMem (s : St) (i : Instr)
    (h : SaltWorks.ISA.touchesMem i = false) :
    (SaltWorks.ISA.step s i).trapped = s.trapped := by
  cases i
  case LW rd a imm => simp [SaltWorks.ISA.touchesMem] at h
  case SW a b imm  => simp [SaltWorks.ISA.touchesMem] at h
  all_goals (simp only [SaltWorks.ISA.step, St.set, St.next]; split_ifs <;> rfl)

/-- ⬥⬥ **M2 — RE-CUT of the `stepT` twin.** The hypothesis has to be about the
word's DECODING rather than about an instruction, because `stepT` takes a word:
whatever this word decodes to must not touch memory. On an undecodable word the
NOP-advance keeps both fields, so that branch needs no hypothesis at all. -/
theorem stepT_mem_frame_of_not_touchesMem (s : St) (w : Word)
    (h : ∀ i, SaltWorks.ISA.decode w = some i → SaltWorks.ISA.touchesMem i = false) :
    (SaltWorks.ISA.stepT s w).mem = s.mem := by
  simp only [SaltWorks.ISA.stepT, SaltWorks.ISA.stepW]
  cases hd : SaltWorks.ISA.decode w with
  | none   => simp [St.next]
  | some i => simp [step_mem_frame_of_not_touchesMem s i (h i hd)]

/-- ⬥⬥ **M2 — RE-CUT of the `stepT` twin.** -/
theorem stepT_trapped_frame_of_not_touchesMem (s : St) (w : Word)
    (h : ∀ i, SaltWorks.ISA.decode w = some i → SaltWorks.ISA.touchesMem i = false) :
    (SaltWorks.ISA.stepT s w).trapped = s.trapped := by
  simp only [SaltWorks.ISA.stepT, SaltWorks.ISA.stepW]
  cases hd : SaltWorks.ISA.decode w with
  | none   => simp [St.next]
  | some i => simp [step_trapped_frame_of_not_touchesMem s i (h i hd)]

/-- ⭐ ⬥ **M2 — WHERE THE PROJECTION BECOMES A WHOLE-STATE EQUALITY AGAIN.** On a
memory-free word both sides are clean — the left by `decQ`'s construction, the
right because a memory-free `stepT` preserves what it started with — so the two
missing fields agree for free and the projection carries the rest.

🔑 ***THIS IS THE SEAM FINDING 4 WAS ABOUT.*** *The projection is sound for ONE
step whatever the word; it is COMPOSITION that leaks, because a store is
invisible to the projection yet feeds a later load that writes a register. This
lemma is exactly the point where the leak is plugged by hypothesis rather than
by hope.* -/
theorem decQ_cyc_eq_of_memFree {cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env}
    {wordAt : SaltWorks.HDL.Env → Word} (h : CycleRealisesStepProj cyc wordAt)
    (ins : SaltWorks.HDL.Env) (hmf : MemFree (wordAt ins)) :
    SaltWorks.HDL.decQ (cyc ins) = stepT (SaltWorks.HDL.decQ ins) (wordAt ins) := by
  obtain ⟨hr, hp⟩ := h ins
  refine St_eq_of_fields hr hp ?_ ?_
  · rw [decQ_mem, stepT_mem_frame_of_not_touchesMem _ _ hmf, decQ_mem]
  · rw [decQ_trapped, stepT_trapped_frame_of_not_touchesMem _ _ hmf, decQ_trapped]

/-- ⭐⭐ **THE DELIVERABLE — `n` CYCLES REALISE `n` STEPS.** One cycle of induction
over the hypothesis; the stream the ISA side is driven by is read off the cycle
sequence itself, which is what makes the statement need no fetch model.

⬥⬥ **M2 — GAINS THE MEMORY-FREE-STREAM HYPOTHESIS, and the old name
`cycles_realise_steps` IS RETIRED** (helm ruling 17:13, finding 4).

⛔ **THE PROJECTION ALONE DOES NOT COMPOSE, AND THE WITNESS IS SHARP:** a store
writes no register, so it is invisible to the projection; a later load reads
what the store left and writes it INTO A REGISTER. On the ISA side `runWords`
threads memory forward; on the cycle side `decQ` wipes it every cycle, because
memory is not in the codec. *Run `SW x1 → mem[0]` with `x1 = 5`, then
`LW x2 ← mem[0]`: the ISA side has `x2 = 5`, the cycle side `x2 = 0` — **the
divergence lands inside the projection**, two cycles in.*

🔑 ***SO THE PROJECTION LEAKS AT THE SEAM BETWEEN STEPS, NOT INSIDE ONE.*** This
hypothesis is the honest scope until stage ③'s bridge realises memory; it
discharges by `decide` on any slice-A stream, which is every stream the compiler
emits. -/
theorem cycles_realise_steps_of_memFree {cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env}
    {wordAt : SaltWorks.HDL.Env → Word} (h : CycleRealisesStepProj cyc wordAt)
    (n : Nat) (ins : SaltWorks.HDL.Env)
    (hmf : ∀ k, MemFree (wordAt (cycles cyc k ins))) :
    SaltWorks.HDL.decQ (cycles cyc n ins)
      = runWords (fun k => wordAt (cycles cyc k ins)) n (SaltWorks.HDL.decQ ins) := by
  induction n with
  | zero => rfl
  | succ m ih =>
      rw [cycles_succ, decQ_cyc_eq_of_memFree h (cycles cyc m ins) (hmf m), ih,
        runWords_succ]

/-! ### ⬥ M2 — THE POSITIVE COMPLEMENTS (helm ruling 16:48, item 3)

*A frame law says what an instruction leaves alone. On its own that is only half
a specification — it is satisfied by an instruction that does nothing. These say
what the two new ops actually DO, so the pair pins the semantics from both
sides.* -/

/-- ⭐ **WHAT A STORE WRITES: EXACTLY ONE WORD, AT THE CHECKED ADDRESS.** The
`Vector.set` form is the "exactly one" — every other slot is copied — and the
index carries `addrClass_ok_lt`, so the theorem cannot be stated at all for an
address the classifier rejected. -/
theorem step_SW_ok_writes_the_addressed_word (s : St) (a b : Fin 32) (imm : BitVec 12)
    (hok : SaltWorks.ISA.addrClass (s.get a + imm.signExtend 32) = .ok) :
    (SaltWorks.ISA.step s (.SW a b imm)).mem
      = s.mem.set ((s.get a + imm.signExtend 32).toNat / 4) (s.get b)
          (SaltWorks.ISA.addrClass_ok_lt hok) := by
  simp only [SaltWorks.ISA.step]
  split_ifs
  · rfl

/-- ⭐ **WHAT A LOAD READS: the addressed word, into `rd`.** Stated at `rd ≠ 0`
because a load into `x0` is discarded by `St.set`'s own law — which is the
x0-discard guard `writesInstr` keeps for exactly this arm. -/
theorem step_LW_ok_loads_the_addressed_word (s : St) (rd a : Fin 32) (imm : BitVec 12)
    (hok : SaltWorks.ISA.addrClass (s.get a + imm.signExtend 32) = .ok) (hrd : rd ≠ 0) :
    (SaltWorks.ISA.step s (.LW rd a imm)).get rd
      = s.mem[(s.get a + imm.signExtend 32).toNat / 4]'(SaltWorks.ISA.addrClass_ok_lt hok) := by
  simp only [SaltWorks.ISA.step]
  split_ifs
  · simpa [St.next, St.get] using St.get_set_self s rd _ hrd

/-- ⭐ **A TRAPPED STEP CHANGES NO MEMORY CELL** — the suppression, which is the
load-bearing term (the flag is only the announcement). Stated for both new ops
at once via the classifier being non-`ok`. -/
theorem step_SW_trapped_suppresses_the_write (s : St) (a b : Fin 32) (imm : BitVec 12)
    (hbad : SaltWorks.ISA.addrClass (s.get a + imm.signExtend 32) ≠ .ok) :
    (SaltWorks.ISA.step s (.SW a b imm)).mem = s.mem ∧
      (SaltWorks.ISA.step s (.SW a b imm)).trapped = true := by
  simp only [SaltWorks.ISA.step]
  split_ifs with h
  · exact absurd h hbad
  · exact ⟨rfl, rfl⟩

/-! ## ⬥⬥ M4 — THE MEMORY FRAME ROWS (memory block :351, "math owns")

*M2 landed the two complements the 16:48 ruling commissioned — what SW writes,
what LW reads. **M4 is the rest of the block's commissioned list**, and it is
here rather than at M2 because the plan puts it here: `M0 → M1(+M1a) → M2 →
M3/M4 → M5`.*

```
"SW-ok writes exactly mem[a/4]"                         ✅ landed at M2 above
"LW writes no memory"                                    ⬥ here
"a trapped step changes NO MEMORY CELL and NO REGISTER"  ⬥ here, BOTH ops
the r-trap KC2 mutant discipline + its pre-registered witness
                                                         ⬥ here
```
⚠️ **The restated form matters: NEVER "a trapped step writes nothing"** — it
DOES set the sticky flag and advance `pc`, so the literal form would be a false
theorem. That correction is ⬥v1.1's own, made at the refuter fold. -/

/-- ⬥ **M4 — LW WRITES NO MEMORY**, and unconditionally: on the `ok` path it
writes a register, on the trap path it writes nothing at all. *No address
hypothesis is needed, which is the cleanest evidence that a load is a load.* -/
theorem step_LW_writes_no_memory (s : St) (rd a : Fin 32) (imm : BitVec 12) :
    (SaltWorks.ISA.step s (.LW rd a imm)).mem = s.mem := by
  simp only [SaltWorks.ISA.step, St.set, St.next]
  split_ifs <;> rfl

/-- ⬥ **M4 — A TRAPPED LOAD CHANGES NO MEMORY CELL AND NO REGISTER.** The
suppression is the load-bearing term; the flag is the announcement; and `pc`
still advances, which is why this is stated as four conjuncts and not as
"writes nothing". -/
theorem step_LW_trapped_changes_no_memory_and_no_register
    (s : St) (rd a : Fin 32) (imm : BitVec 12)
    (hbad : SaltWorks.ISA.addrClass (s.get a + imm.signExtend 32) ≠ .ok) :
    (SaltWorks.ISA.step s (.LW rd a imm)).mem = s.mem
    ∧ (∀ r, (SaltWorks.ISA.step s (.LW rd a imm)).get r = s.get r)
    ∧ (SaltWorks.ISA.step s (.LW rd a imm)).trapped = true
    ∧ (SaltWorks.ISA.step s (.LW rd a imm)).pc = s.pc + 4 := by
  simp only [SaltWorks.ISA.step]
  split_ifs with h
  · exact absurd h hbad
  · exact ⟨rfl, fun _ => rfl, rfl, rfl⟩

/-- ⬥ **M4 — AND THE SAME FOR A TRAPPED STORE.** *This is the full commissioned
sentence; the M2 complement above (`step_SW_trapped_suppresses_the_write`) is its
memory half and remains true — it was landed as a control before M4 opened.* -/
theorem step_SW_trapped_changes_no_memory_and_no_register
    (s : St) (a b : Fin 32) (imm : BitVec 12)
    (hbad : SaltWorks.ISA.addrClass (s.get a + imm.signExtend 32) ≠ .ok) :
    (SaltWorks.ISA.step s (.SW a b imm)).mem = s.mem
    ∧ (∀ r, (SaltWorks.ISA.step s (.SW a b imm)).get r = s.get r)
    ∧ (SaltWorks.ISA.step s (.SW a b imm)).trapped = true
    ∧ (SaltWorks.ISA.step s (.SW a b imm)).pc = s.pc + 4 := by
  simp only [SaltWorks.ISA.step]
  split_ifs with h
  · exact absurd h hbad
  · exact ⟨rfl, fun _ => rfl, rfl, rfl⟩

/-! ### ⬥ M4's MUTANT DISCIPLINE (r-trap KC2) — it must COMPILE, and it must FALSIFY -/

/-- The write-in-the-trapped-arm mutant. **It uses the TOTAL setter, because a
non-compiling mutant is not a control** — the block's own requirement.

📌 *The block names this form `Vector.setD`; in this toolchain it is
`Vector.setIfInBounds` (Lean 4.31 core). Pin recorded rather than silently
substituted.* -/
def stepSW_mutant (s : St) (a b : Fin 32) (imm : BitVec 12) : St :=
  let addr := s.get a + imm.signExtend 32
  if h : SaltWorks.ISA.addrClass addr = .ok then
    let m := s.mem.set (addr.toNat / 4) (s.get b) (SaltWorks.ISA.addrClass_ok_lt h)
    { s with mem := m }.next
  else
    let m := s.mem.setIfInBounds (addr.toNat / 4) (s.get b)
    { s with mem := m, trapped := true }.next

/-- ⛔ **THE MUTANT IS KILLED, on the block's PRE-REGISTERED witness.** Byte
address 5 is MISALIGNED **AND IN RANGE** (word 1 < 8), and `mem[1] = 7` differs
from `x1 = 5`, so the write the honest machine suppresses is OBSERVABLE. -/
theorem mutant_killed_at_misaligned_in_range :
    (SaltWorks.ISA.step SaltWorks.ISA.m2Witness (.SW 0 1 5)).mem[1] = 7
    ∧ (stepSW_mutant SaltWorks.ISA.m2Witness 0 1 5).mem[1] = 5 := by
  decide +kernel

/-- The witness's own preconditions, stated rather than trusted — misaligned, in
range, and writing a value that differs from what is already there. -/
theorem witness_is_misaligned_and_in_range :
    SaltWorks.ISA.addrClass 5#32 = .misaligned
    ∧ (5#32 : BitVec 32).toNat / 4 = 1
    ∧ SaltWorks.ISA.m2Witness.mem[1] ≠ SaltWorks.ISA.m2Witness.get 1 := by
  decide +kernel

/-- ⚠️⚠️ **AND WHY ONE MISALIGNED MUTANT MUST NOT STAND IN FOR BOTH TRAP ARMS —
the block's warning, promoted from prose to a kernel fact.** At an out-of-range
address the truncating write is a NO-OP (word 8 has no slot in a `Vector 8`), so
the mutant AGREES with `step` there and **would pass spuriously**.

🔑 ***The out-of-range arm is free-by-typing in the kernel; its real control
lives at the F4 bridge (stage ③'s dropped-gate RTL mutant). This theorem is what
makes that a KNOWN gap rather than a covered one*** — a control roster that
cannot say which arm it fails to test is a roster that reads complete. -/
theorem out_of_range_mutant_passes_spuriously :
    (stepSW_mutant SaltWorks.ISA.m2Witness 0 1 32).mem
      = (SaltWorks.ISA.step SaltWorks.ISA.m2Witness (.SW 0 1 32)).mem := by
  decide +kernel

/-- The `= s` form survives exactly on clean states — which is every state the
codec is fed. -/
theorem decQ_envWith_of_clean (s : St) (w : Word)
    (hm : s.mem = Vector.replicate 8 0) (ht : s.trapped = false) :
    SaltWorks.HDL.decQ (envWith s w) = s := by
  rw [decQ_envWith_eq]
  obtain ⟨regs, pc, mem, tr⟩ := s
  subst hm; subst ht; rfl

theorem seenWord_envWith (s : St) (w : Word) : seenWord (envWith s w) = w := by
  apply BitVec.eq_of_getLsbD_eq
  intro k hk
  rw [seenWord, SaltWorks.HDL.wordOf_getLsbD _ _ hk]
  try simp only [step_regs_of_with_of_not_touchesMem, SaltWorks.ISA.touchesMem]
  try simp only [step_pc_of_with]
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
`CycleRealisesStepProj` is a satisfiable constraint rather than a shape, and it is
generic in the next-word policy so it does not smuggle a fetch model in. -/
def cycOf (nextW : St → Word) (ins : SaltWorks.HDL.Env) : SaltWorks.HDL.Env :=
  envWith (stepT (SaltWorks.HDL.decQ ins) (seenWord ins)) (nextW (SaltWorks.HDL.decQ ins))

/-- ⬥⬥ **M2 — RE-CUT to the projection; `decQ_cycOf` is RETIRED.** The old proof
discharged cleanliness through `stepT_mem_eq` on an ARBITRARY word — which is
precisely the discharge M2 removes, since the word may be a store. On the two
projected fields no discharge is needed at all: `decQ ∘ envWith` returns the
state it was handed with only `mem`/`trapped` reset, and neither is a projection
field. *This one gets SHORTER under M2, which is the tell that the projection is
the natural statement rather than a retreat.* -/
theorem decQ_cycOf_proj (nextW : St → Word) (ins : SaltWorks.HDL.Env) :
    (SaltWorks.HDL.decQ (cycOf nextW ins)).regs
        = (stepT (SaltWorks.HDL.decQ ins) (seenWord ins)).regs
    ∧ (SaltWorks.HDL.decQ (cycOf nextW ins)).pc
        = (stepT (SaltWorks.HDL.decQ ins) (seenWord ins)).pc := by
  rw [cycOf, decQ_envWith_eq]
  exact ⟨rfl, rfl⟩

/-- ⭐ **SATISFIABLE**, for every next-word policy — and now satisfiable for
every WORD too, including stores, which the whole-St form could not be. -/
theorem cycleRealisesStepProj_cycOf (nextW : St → Word) :
    CycleRealisesStepProj (cycOf nextW) seenWord := fun ins => decQ_cycOf_proj nextW ins

/-- ⛔ **CONTROL 1 — A STALLED CYCLE FAILS.** A netlist whose flops do not change
satisfies nothing: at a wire configuration holding `St.init` with `addi x1, x0, 1`
on the instruction nets, the ISA writes `x1 = 1` and the stall does not. ⇒ the
hypothesis has content, and `cycles_realise_steps` is not true of every `cyc`. -/
theorem not_cycleRealisesStep_id : ¬ CycleRealisesStepProj id seenWord := by
  intro h
  have hh := h (envWith St.init (encode (Instr.ADDI 1 0 1)))
  rw [id_eq, decQ_envWith_eq, seenWord_envWith, stepT_encode] at hh
  revert hh
  decide +kernel

/-- 🔴 **CONTROL 2 — THE WRONG 32 WIRES, AS A REFUTATION.** The *same* machine
`cycOf`, paired with `wordOf ins` instead of `seenWord ins`, fails — because
`wordOf ins` reads nets `0 … 31`, which are register `x0`, which is zero, which
the decoder rejects, so the machine appears to NOP while the ISA executes.

*`wordOf ins` typechecks and Lean says nothing.* This theorem is what says
something. -/
theorem not_cycleRealisesStep_wordOf (nextW : St → Word) :
    ¬ CycleRealisesStepProj (cycOf nextW) (fun ins => SaltWorks.HDL.wordOf ins) := by
  intro h
  have hh := (h (envWith St.init (encode (Instr.ADDI 1 0 1)))).1
  rw [(decQ_cycOf_proj nextW _).1, decQ_envWith_eq, seenWord_envWith,
    stepT_encode] at hh
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

* `CycleRealisesStepProj` — **C4**, the compiler lane. Satisfiable
  (`cycleRealisesStepProj_cycOf`), discriminating (`not_cycleRealisesStep_id`,
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
    {wordAt : SaltWorks.HDL.Env → Word} (h : CycleRealisesStepProj cyc wordAt)
    {ins : SaltWorks.HDL.Env} {v : Fin 8 → Word} (hentry : EntryLoaded ins v)
    (hmf : ∀ k, MemFree (wordAt (cycles cyc k ins))) :
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
    rw [cycles_realise_steps_of_memFree h N ins hmf,
      runWords_get_eq_runFor hfeed hN (dataReg i),
      hregs i, hv]
  rw [dataRegs_map_get, key]
  exact batcher8_sortsTo_word v

/-! ## ⭐⭐ C4BRIDGE — THE MISSING LINK BETWEEN `C4Spec` AND `CycleRealisesStepProj`

**The two lanes wrote two halves of one sentence and nothing joined them.**

* Compiler's `HDL.C4Spec c` is about **`sem c ins`** — a `List Bool`, the
  circuit's output ports in port order.
* Math's `CycleRealisesStepProj cyc wordAt` is about a **cycle function**
  `cyc : Env → Env` on wires.

⇒ *Even with C4 in hand, `cycles_sort` could not consume it*, because no
definition said which wires `sem c ins` lands on. This section is that
definition and the two theorems that ride on it, so that **the day C4 is proved
the end-to-end theorem fires with no further work.**

### The content is the codec round trip, and one obligation the type system cannot see

`cycOfCirc` puts output port `j` on state net `j` — the D→Q flop transfer, in
`StateCodec`'s own layout — and `nextW ins` on the instruction nets. `C4Spec`
says the port list *is* `encD (stepT …)`, and `decQ_encD_proj` turns that back into
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
`CycleRealisesStepProj`'s word need no translation. *Stated rather than assumed: the
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
existing witness apparatus (`decQ_envWith_eq`, `seenWord_envWith`) applies. -/
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
for every next-word policy and every pad.

⬥⬥ **M2 — RE-CUT to the projection; `cycleRealisesStep_of_bits` is RETIRED.**
Same discharge, same removal, same shortening as `decQ_cycOf_proj`. -/
theorem cycleRealisesStepProj_of_bits {f : SaltWorks.HDL.Env → List Bool}
    (h : ∀ ins, f ins
      = SaltWorks.HDL.encD (stepT (SaltWorks.HDL.decQ ins) (seenWord ins)))
    (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env) :
    CycleRealisesStepProj (cycOfBits f nextW pad) seenWord := by
  intro ins
  rw [cycOfBits, h ins, envOfBits_encD, decQ_envWith_eq]
  exact ⟨rfl, rfl⟩

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

/-- ⭐⭐ **THE BRIDGE — `C4Spec` DISCHARGES `CycleRealisesStepProj`.** The theorem
whose absence meant a proved C4 would still not reach `cycles_sort`. -/
theorem cycleRealisesStep_of_C4Spec {c : SaltWorks.HDL.Circ} (h : SaltWorks.HDL.C4Spec c)
    (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env) :
    CycleRealisesStepProj (cycOfCirc c nextW pad) seenWord :=
  cycleRealisesStepProj_of_bits (f := SaltWorks.HDL.sem c) h nextW pad

/-- The same, through the `C4` structure — *"C4 as it should be USED"*, in
compiler's words. -/
theorem cycleRealisesStep_of_C4 {c : SaltWorks.HDL.Circ} (hC4 : SaltWorks.HDL.C4 c)
    (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env) :
    CycleRealisesStepProj (cycOfCirc c nextW pad) seenWord :=
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
    {ins : SaltWorks.HDL.Env} {v : Fin 8 → Word} (hentry : EntryLoaded ins v)
    (hmf : ∀ k, MemFree (seenWord (cycles (cycOfCirc c nextW pad) k ins))) :
    ∃ K, K ≤ 120 ∧ ∀ N, K ≤ N →
      FeedsProgram batcherSort
        (fun k => seenWord (cycles (cycOfCirc c nextW pad) k ins))
        (SaltWorks.HDL.decQ ins) K →
      SortsTo (List.ofFn v)
        (dataRegs.map (SaltWorks.HDL.decQ (cycles (cycOfCirc c nextW pad) N ins)).get) :=
  cycles_sort (cycleRealisesStep_of_C4 hC4 nextW pad) hentry hmf

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
    CycleRealisesStepProj (cycOfBits idealBits nextW pad) seenWord :=
  cycleRealisesStepProj_of_bits (fun _ => rfl) nextW pad

/-- A core whose outputs re-present the state it was given: the stall. -/
def stalledBits (ins : SaltWorks.HDL.Env) : List Bool :=
  SaltWorks.HDL.encD (SaltWorks.HDL.decQ ins)

theorem decQ_cycOfBits_stalled (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env)
    (ins : SaltWorks.HDL.Env) :
    SaltWorks.HDL.decQ (cycOfBits stalledBits nextW pad ins) = SaltWorks.HDL.decQ ins := by
  rw [cycOfBits, stalledBits, envOfBits_encD]
  -- ⬥ M2: cleanliness here comes from `decQ`'s own construction, NOT from
  -- `stepT` — `stalledBits` never steps. The retired `stepT_mem_eq` was a
  -- gratuitous simp argument, which is why this theorem survives untouched.
  exact decQ_envWith_of_clean _ _
    (by simp [SaltWorks.HDL.decQ]) (by simp [SaltWorks.HDL.decQ])

/-- ⛔ **CONTROL 1 — THE STALLED CORE FAILS THROUGH THE BRIDGE.** `cycOfBits` is
not a construction that makes anything realise a step: at `St.init` with
`addi x1, x0, 1` on the instruction nets the ISA writes `x1 = 1` and the stall
does not. *`not_cycleRealisesStep_id`'s witness, now aimed at the circuit-level
cycle map instead of the abstract one.* -/
theorem not_cycleRealisesStep_stalledBits (nextW : SaltWorks.HDL.Env → Word)
    (pad : SaltWorks.HDL.Env) :
    ¬ CycleRealisesStepProj (cycOfBits stalledBits nextW pad) seenWord := by
  intro h
  have hh := h (envWith St.init (encode (Instr.ADDI 1 0 1)))
  rw [decQ_cycOfBits_stalled, decQ_envWith_eq, seenWord_envWith, stepT_encode] at hh
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

/-! ## ⭐⭐ C4, FIELDWISE — 33 OBLIGATIONS IN PLACE OF ONE 1056-BIT EQUATION

`C4Spec c` is **one equation between two `List Bool`s of length 1056, about a
circuit of ~3,000 gates.** Compiler's measured lesson is that a core-sized object
cannot be certified as one thing: the monolithic well-formedness route hit
`EXIT=134`, *"excessive memory consumption"*, on an O(n²) `wf` check, and was
broken instead by proving `Circ.wf_of_ssa` **structurally**. **C4 needs the same
treatment and this section is it** — not an attempt at C4, which is impossible
today (`grep -rE "^(def|theorem|abbrev|noncomputable def) (core|compile)\b"` over
`SaltWorks/` still returns nothing), but the *decomposition* that turns C4 from a
fresh proof into an assembly the day its subject exists.

## The split, and why it is the layout's split rather than an arbitrary one

`stWidth = 1056 = 32 registers × 32 bits + 32 pc bits`, and `encD` writes exactly
that layout (`StateCodec.lean`). So the 1056 output bits fall into **33 fields**,
each 32 bits wide, each with an independent meaning:

```
RegField c r   (r : Fin 32)   output bits 32r … 32r+31  =  (stepT …).regs[r]
PcField  c                    output bits 1024 … 1055   =  (stepT …).pc
```

`c4Spec_iff_fieldwise` is the equivalence. **Both directions are proved, and they
do different jobs:**

* **`→` isolates.** A failing core fails *some field*, and the field names the
  datapath slice at fault. `coreShaped_isolation` below is that made real: one
  circuit that meets field 0, fails field 1, and fails the pc.
* **`←` assembles.** *This is the theorem compiler applies once `core` exists*:
  33 per-field lemmas, each about 32 bits and each checkable on its own, compose
  into `C4Spec` with no further work — and `sorts_of_fieldwise` carries them all
  the way to "the machine sorts".

## ⚠️ THE LENGTH IS NOT SYMMETRIC BETWEEN THE DIRECTIONS

**`c.outs.length = stWidth` is a conjunct of the fieldwise side, and it must
be.** Both sides of C4 are `List Bool` at *any* length (C4.lean's 14:17 hazard).

* Forward, it is **free**: `outs_length_of_C4Spec` derives it from `C4Spec`
  itself, since `C4Spec` is an equality of lists and `encD`'s length is `stWidth`
  unconditionally. The `→` direction therefore *produces* the length.
* Reverse, it must be **assumed**: the 33 field obligations are statements about
  `getD`, which is total, and a 1055-output core can satisfy every one of them by
  reading the default `false` at the last index. **Without the length conjunct the
  `←` direction is FALSE**, and `outs_length_is_not_implied_by_the_fields` below
  refutes the version without it rather than warning about it.

⇒ *The `iff` is stated with the length on the fieldwise side, which is the only
placement that makes both directions true.*
-/

-- The 1056-element `outs` lists below exceed the default elaboration depth —
-- C4.lean carries the same `set_option` for the same reason, and it does not
-- cross the module boundary.
set_option maxRecDepth 8000

/-- **Output bit `j` of `c`**, read positionally off `sem`. Total: an index past
the end reads `false`, which is exactly the hazard the length conjunct exists to
exclude. -/
def outBit (c : SaltWorks.HDL.Circ) (ins : SaltWorks.HDL.Env) (j : Nat) : Bool :=
  (SaltWorks.HDL.sem c ins).getD j false

/-- **The register-`r` output field** — the 32 output bits `StateCodec` assigns to
register `r`, read back as a word. -/
def outReg (c : SaltWorks.HDL.Circ) (ins : SaltWorks.HDL.Env) (r : Fin 32) : Word :=
  SaltWorks.HDL.wordOf (fun k => outBit c ins (32 * r.val + k))

/-- **The pc output field** — output bits `1024 … 1055`. -/
def outPc (c : SaltWorks.HDL.Circ) (ins : SaltWorks.HDL.Env) : Word :=
  SaltWorks.HDL.wordOf (fun k => outBit c ins (1024 + k))

/-- ⭐ **ONE OF THE 32 REGISTER OBLIGATIONS.** A statement about `c` alone, about
32 output bits, provable and checkable without reference to the other 32. -/
def RegField (c : SaltWorks.HDL.Circ) (r : Fin 32) : Prop :=
  ∀ ins, outReg c ins r = (stepT (SaltWorks.HDL.decQ ins) (seenWord ins)).regs[r.val]

/-- ⭐ **THE 33RD OBLIGATION** — the program counter. -/
def PcField (c : SaltWorks.HDL.Circ) : Prop :=
  ∀ ins, outPc c ins = (stepT (SaltWorks.HDL.decQ ins) (seenWord ins)).pc

/-! ### The layout arithmetic, once

`stBit` is `StateCodec`'s bit-level reader; these two lemmas are the only places
the index arithmetic `32 * r + k` / `1024 + k` is done. -/

/-- Register `r`'s bit `k` of the encoded state. -/
theorem stBit_reg (s : St) (r : Fin 32) (k : Nat) (hk : k < 32) :
    SaltWorks.HDL.stBit s (32 * r.val + k) = (s.regs[r.val]).getLsbD k := by
  have hr := r.isLt
  have hdiv : (32 * r.val + k) / 32 = r.val := by omega
  have hmod : (32 * r.val + k) % 32 = k := by omega
  rw [SaltWorks.HDL.stBit, if_pos (by omega), hdiv, hmod, getElem!_pos s.regs r.val hr]

/-- The pc's bit `k` of the encoded state. -/
theorem stBit_pc (s : St) (k : Nat) (hk : k < 32) :
    SaltWorks.HDL.stBit s (1024 + k) = s.pc.getLsbD k := by
  have hsub : 1024 + k - 1024 = k := by omega
  rw [SaltWorks.HDL.stBit, if_neg (by omega), hsub]

/-- **A register field IS 32 independent bit obligations** — the sentence that
makes "each field is checkable on its own" concrete rather than rhetorical. -/
theorem regField_iff_bits (c : SaltWorks.HDL.Circ) (r : Fin 32) :
    RegField c r ↔ ∀ ins, ∀ k < 32,
      outBit c ins (32 * r.val + k)
        = ((stepT (SaltWorks.HDL.decQ ins) (seenWord ins)).regs[r.val]).getLsbD k := by
  constructor
  · intro h ins k hk
    have hh : (outReg c ins r).getLsbD k
        = ((stepT (SaltWorks.HDL.decQ ins) (seenWord ins)).regs[r.val]).getLsbD k := by
      rw [h ins]
    rwa [outReg, SaltWorks.HDL.wordOf_getLsbD _ _ hk] at hh
  · intro h ins
    apply BitVec.eq_of_getLsbD_eq
    intro k hk
    rw [outReg, SaltWorks.HDL.wordOf_getLsbD _ _ hk]
    exact h ins k hk

/-- The pc field, likewise. -/
theorem pcField_iff_bits (c : SaltWorks.HDL.Circ) :
    PcField c ↔ ∀ ins, ∀ k < 32,
      outBit c ins (1024 + k)
        = ((stepT (SaltWorks.HDL.decQ ins) (seenWord ins)).pc).getLsbD k := by
  constructor
  · intro h ins k hk
    have hh : (outPc c ins).getLsbD k
        = ((stepT (SaltWorks.HDL.decQ ins) (seenWord ins)).pc).getLsbD k := by
      rw [h ins]
    rwa [outPc, SaltWorks.HDL.wordOf_getLsbD _ _ hk] at hh
  · intro h ins
    apply BitVec.eq_of_getLsbD_eq
    intro k hk
    rw [outPc, SaltWorks.HDL.wordOf_getLsbD _ _ hk]
    exact h ins k hk

/-- ⭐ **THE POSITIONAL FORM — `C4Spec` is a length plus 1056 bit equations.**
Stated separately from the fieldwise form because it is where the *list* reasoning
lives (`List.ext_getElem`, `encD_getD`); the fieldwise theorem is then pure index
arithmetic on top of it.

⚠️ **The length conjunct is on the right-hand side.** Forward it is free
(`outs_length_of_C4Spec`); reverse it is indispensable, since `getD` is total. -/
theorem c4Spec_iff_bitwise (c : SaltWorks.HDL.Circ) :
    SaltWorks.HDL.C4Spec c ↔
      c.outs.length = SaltWorks.HDL.stWidth ∧
        ∀ ins, ∀ j < SaltWorks.HDL.stWidth,
          outBit c ins j
            = SaltWorks.HDL.stBit (stepT (SaltWorks.HDL.decQ ins) (seenWord ins)) j := by
  constructor
  · intro h
    refine ⟨outs_length_of_C4Spec h, ?_⟩
    intro ins j hj
    rw [outBit, seenWord_eq_hdl, h ins, SaltWorks.HDL.encD_getD _ _ hj]
  · rintro ⟨hlen, hbits⟩ ins
    apply List.ext_getElem
    · rw [SaltWorks.HDL.sem, List.length_map, hlen, encD_length]
    · intro i h1 h2
      have hi : i < SaltWorks.HDL.stWidth := by rwa [encD_length] at h2
      have hL : (SaltWorks.HDL.sem c ins)[i]'h1 = outBit c ins i := by
        rw [outBit, List.getD_eq_getElem _ _ h1]
      have hR : (SaltWorks.HDL.encD
            (stepT (SaltWorks.HDL.decQ ins) (SaltWorks.HDL.seenWord ins)))[i]'h2
          = SaltWorks.HDL.stBit
            (stepT (SaltWorks.HDL.decQ ins) (SaltWorks.HDL.seenWord ins)) i := by
        rw [← List.getD_eq_getElem _ false h2, SaltWorks.HDL.encD_getD _ _ hi]
      rw [hL, hR]
      exact hbits ins i hi

/-- ⭐⭐ **THE DECOMPOSITION — `C4Spec` IS A FIELDWISE CONJUNCTION.** One 1056-bit
equation about a ~3,000-gate circuit becomes **33 obligations of 32 bits each**,
plus the output count. *This is what makes a core-sized C4 tractable at all: each
conjunct is provable, checkable and re-checkable on its own, and a failure names
the field it came from.* -/
theorem c4Spec_iff_fieldwise (c : SaltWorks.HDL.Circ) :
    SaltWorks.HDL.C4Spec c ↔
      c.outs.length = SaltWorks.HDL.stWidth
        ∧ (∀ r : Fin 32, RegField c r)
        ∧ PcField c := by
  rw [c4Spec_iff_bitwise]
  constructor
  · rintro ⟨hlen, hbits⟩
    refine ⟨hlen, ?_, ?_⟩
    · intro r
      rw [regField_iff_bits]
      intro ins k hk
      have hr := r.isLt
      rw [hbits ins (32 * r.val + k) (by show 32 * r.val + k < 1056; omega),
        stBit_reg _ r k hk]
    · rw [pcField_iff_bits]
      intro ins k hk
      rw [hbits ins (1024 + k) (by show 1024 + k < 1056; omega), stBit_pc _ k hk]
  · rintro ⟨hlen, hregs, hpc⟩
    refine ⟨hlen, ?_⟩
    intro ins j hj
    have hj56 : j < 1056 := hj
    by_cases h1 : j < 1024
    · have hlt : j / 32 < 32 := by omega
      have hk : j % 32 < 32 := by omega
      have hd : 32 * (⟨j / 32, hlt⟩ : Fin 32).val + j % 32 = j := by
        show 32 * (j / 32) + j % 32 = j
        omega
      have hs := stBit_reg (stepT (SaltWorks.HDL.decQ ins) (seenWord ins))
        ⟨j / 32, hlt⟩ (j % 32) hk
      have hb := (regField_iff_bits c ⟨j / 32, hlt⟩).mp (hregs _) ins (j % 32) hk
      rw [hd] at hs hb
      exact hb.trans hs.symm
    · have hk : j - 1024 < 32 := by omega
      have hd : 1024 + (j - 1024) = j := by omega
      have hs := stBit_pc (stepT (SaltWorks.HDL.decQ ins) (seenWord ins)) (j - 1024) hk
      have hb := (pcField_iff_bits c).mp hpc ins (j - 1024) hk
      rw [hd] at hs hb
      exact hb.trans hs.symm

/-! ### ⭐ THE ASSEMBLY DIRECTION — what compiler applies once `core` exists -/

/-- ⭐⭐ **33 FIELD LEMMAS AND AN OUTPUT COUNT GIVE C4.** *The theorem this whole
section exists for: no further proof work between "every field is right" and
`C4Spec`.* -/
theorem c4Spec_of_fieldwise {c : SaltWorks.HDL.Circ}
    (hlen : c.outs.length = SaltWorks.HDL.stWidth)
    (hregs : ∀ r : Fin 32, RegField c r) (hpc : PcField c) : SaltWorks.HDL.C4Spec c :=
  (c4Spec_iff_fieldwise c).mpr ⟨hlen, hregs, hpc⟩

/-- ⭐⭐ **AND STRAIGHT THROUGH THE BRIDGE.** Fields ⇒ `C4Spec` ⇒
`CycleRealisesStepProj`, for every next-word policy and every pad. -/
theorem cycleRealisesStep_of_fieldwise {c : SaltWorks.HDL.Circ}
    (hlen : c.outs.length = SaltWorks.HDL.stWidth)
    (hregs : ∀ r : Fin 32, RegField c r) (hpc : PcField c)
    (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env) :
    CycleRealisesStepProj (cycOfCirc c nextW pad) seenWord :=
  cycleRealisesStep_of_C4Spec (c4Spec_of_fieldwise hlen hregs hpc) nextW pad

/-- ⭐⭐⭐ **THE END-TO-END THEOREM, FROM THE FIELDS.** `sorts_of_C4` with its
`C4Spec` premise replaced by the 33 field obligations — so the surviving
hypotheses are `CoreConforms` (whose own `outs.length` conjunct supplies the
count), the 33 fields, the reset and the instruction path. *Nothing about the
statement was weakened: this is `sorts_of_C4` composed with
`c4Spec_of_fieldwise`.* -/
theorem sorts_of_fieldwise {c : SaltWorks.HDL.Circ} (hconf : SaltWorks.HDL.CoreConforms c)
    (hregs : ∀ r : Fin 32, RegField c r) (hpc : PcField c)
    (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env)
    {ins : SaltWorks.HDL.Env} {v : Fin 8 → Word} (hentry : EntryLoaded ins v)
    (hmf : ∀ k, MemFree (seenWord (cycles (cycOfCirc c nextW pad) k ins))) :
    ∃ K, K ≤ 120 ∧ ∀ N, K ≤ N →
      FeedsProgram batcherSort
        (fun k => seenWord (cycles (cycOfCirc c nextW pad) k ins))
        (SaltWorks.HDL.decQ ins) K →
      SortsTo (List.ofFn v)
        (dataRegs.map (SaltWorks.HDL.decQ (cycles (cycOfCirc c nextW pad) N ins)).get) :=
  sorts_of_C4 ⟨hconf, c4Spec_of_fieldwise hconf.2.2 hregs hpc⟩ nextW pad hentry hmf

/-! ### ⭐ THE ISOLATION DIRECTION — a failing core fails a NAMED field -/

/-- A failing register field refutes C4 on its own. -/
theorem not_C4Spec_of_not_regField {c : SaltWorks.HDL.Circ} {r : Fin 32}
    (h : ¬ RegField c r) : ¬ SaltWorks.HDL.C4Spec c :=
  fun hc => h (((c4Spec_iff_fieldwise c).mp hc).2.1 r)

/-- A failing pc field refutes C4 on its own. -/
theorem not_C4Spec_of_not_pcField {c : SaltWorks.HDL.Circ}
    (h : ¬ PcField c) : ¬ SaltWorks.HDL.C4Spec c :=
  fun hc => h (((c4Spec_iff_fieldwise c).mp hc).2.2)

/-! ## ⛔ NON-VACUITY — a circuit that meets SOME fields and not others

*The isolation property is worth nothing unless the fields can come apart. They
can, and compiler's own conforming shapes are the witnesses: `coreShaped` is the
1056-output pass-through, which **gets register `x0` exactly right** (a write to
`x0` is discarded, so `x0` never changes and passing it through is correct
behaviour) and **gets `x1` and the pc wrong** (both move under `ADDI x1, x0, 1`).*

⇒ ***Three fields of the same circuit, decided three different ways** — which is
the whole content of the claim that 33 obligations are independent.* -/

/-- `coreShaped` is the pass-through: no gates, output `j` reads net `j`. -/
theorem sem_coreShaped (ins : SaltWorks.HDL.Env) :
    SaltWorks.HDL.sem SaltWorks.HDL.coreShaped ins
      = (List.range SaltWorks.HDL.stWidth).map ins := rfl

theorem outBit_coreShaped (ins : SaltWorks.HDL.Env) (j : Nat)
    (hj : j < SaltWorks.HDL.stWidth) :
    outBit SaltWorks.HDL.coreShaped ins j = ins j := by
  have hl : j < ((List.range SaltWorks.HDL.stWidth).map ins).length := by
    rw [List.length_map, List.length_range]; exact hj
  rw [outBit, sem_coreShaped, List.getD_eq_getElem _ _ hl, List.getElem_map,
    List.getElem_range]

theorem outReg_coreShaped (ins : SaltWorks.HDL.Env) (r : Fin 32) :
    outReg SaltWorks.HDL.coreShaped ins r = (SaltWorks.HDL.decQ ins).regs[r.val] := by
  have hr := r.isLt
  have h1 : outReg SaltWorks.HDL.coreShaped ins r
      = SaltWorks.HDL.wordOf (fun k => ins (32 * r.val + k)) :=
    wordOf_congr (fun k hk =>
      outBit_coreShaped ins _ (by show 32 * r.val + k < 1056; omega))
  have h2 : (SaltWorks.HDL.decQ ins).regs[r.val]
      = SaltWorks.HDL.wordOf (fun k => ins (32 * r.val + k)) := by
    show (Vector.ofFn (fun r : Fin 32 =>
      SaltWorks.HDL.wordOf (fun k => ins (32 * r.val + k))))[r.val] = _
    rw [Vector.getElem_ofFn]
  rw [h1, h2]

theorem outPc_coreShaped (ins : SaltWorks.HDL.Env) :
    outPc SaltWorks.HDL.coreShaped ins = (SaltWorks.HDL.decQ ins).pc :=
  wordOf_congr (fun k hk => outBit_coreShaped ins _ (by show 1024 + k < 1056; omega))

/-! #### `x0` never changes — the fact that makes field 0 satisfiable today -/

theorem set_regs_zero (s : St) (r : Fin 32) (v : BitVec 32) :
    (s.set r v).regs[0] = s.regs[0] := by
  by_cases h : r = 0
  · rw [h, St.set_zero]
  · have hne : r.val ≠ 0 := fun hh => h (Fin.ext hh)
    simp only [St.set, if_neg h]
    exact Vector.getElem_set_ne r.isLt (by omega) hne

theorem step_regs_zero (s : St) (i : Instr) : (step s i).regs[0] = s.regs[0] := by
  cases i with
  | ADD rd a b => exact set_regs_zero s rd _
  | ADDI rd a imm => exact set_regs_zero s rd _
  | XOR rd a b => exact set_regs_zero s rd _
  | SLT rd a b => exact set_regs_zero s rd _
  | BEQ a b imm => simp only [step]; split <;> rfl
  -- ⬥ M2. LW's `ok` branch writes `rd` and so goes through `set_regs_zero`; its
  -- two trap branches touch only `trapped`/`pc`. SW writes no register at all.
  -- x0 is preserved on every path, which is what field 0 of the core needs.
  | LW rd a imm =>
      simp only [step]
      split_ifs
      · exact set_regs_zero s rd _
      · rfl
  | SW a b imm => simp only [step]; split_ifs <;> rfl

/-- ⭐ **`x0` IS INVARIANT UNDER THE WHOLE TOTAL STEP** — decodable or not. This
is `St.set_zero` (P5) propagated to `stepT`, and it is why the pass-through
circuit satisfies register field 0 exactly. -/
theorem stepT_regs_zero (s : St) (w : BitVec 32) : (stepT s w).regs[0] = s.regs[0] := by
  cases h : decode w with
  | none => rw [stepT_undecodable s w h]; rfl
  | some i =>
    rw [stepT_compat s w (step s i) (by simp [stepW, h])]
    exact step_regs_zero s i

/-- ✅ **FIELD 0 HOLDS.** The pass-through core computes register `x0` correctly —
because `x0` never changes and passing it through is exactly right. -/
theorem regField_zero_coreShaped : RegField SaltWorks.HDL.coreShaped 0 := by
  intro ins
  rw [outReg_coreShaped]
  simp only [Fin.val_zero]
  exact (stepT_regs_zero _ _).symm

/-- ⛔ **FIELD 1 FAILS.** `ADDI x1, x0, 1` from the entry state writes `1` into
`x1`; the pass-through re-presents `0`. -/
theorem not_regField_one_coreShaped : ¬ RegField SaltWorks.HDL.coreShaped 1 := by
  intro h
  have hh := h (envWith St.init (encode (Instr.ADDI 1 0 1)))
  rw [outReg_coreShaped, decQ_envWith_eq, seenWord_envWith, stepT_encode] at hh
  revert hh
  decide +kernel

/-- ⛔ **THE PC FIELD FAILS.** The pc advances by 4 and the pass-through does
not move it. -/
theorem not_pcField_coreShaped : ¬ PcField SaltWorks.HDL.coreShaped := by
  intro h
  have hh := h (envWith St.init (encode (Instr.ADDI 1 0 1)))
  rw [outPc_coreShaped, decQ_envWith_eq, seenWord_envWith, stepT_encode] at hh
  revert hh
  decide +kernel

/-- ⭐⭐ **THE ISOLATION PROPERTY, MADE REAL.** One conforming circuit; three of
its 33 obligations decided three different ways. *So the decomposition is not a
restatement — the conjuncts genuinely come apart, and a `C4Spec` failure has a
named location rather than being a 1056-bit disagreement somewhere.* -/
theorem coreShaped_isolation :
    RegField SaltWorks.HDL.coreShaped 0
      ∧ ¬ RegField SaltWorks.HDL.coreShaped 1
      ∧ ¬ PcField SaltWorks.HDL.coreShaped :=
  ⟨regField_zero_coreShaped, not_regField_one_coreShaped, not_pcField_coreShaped⟩

/-- ⛔ **AND THEREFORE `coreShaped` IS NOT BRIDGEABLE** — refuted outright, via a
named field, rather than only in the pair. -/
theorem not_C4Spec_coreShaped : ¬ SaltWorks.HDL.C4Spec SaltWorks.HDL.coreShaped :=
  not_C4Spec_of_not_pcField not_pcField_coreShaped

/-! #### The second conforming shape falls the same way -/

theorem sem_coreShapedT (ins : SaltWorks.HDL.Env) :
    SaltWorks.HDL.sem SaltWorks.HDL.coreShapedT ins
      = List.replicate SaltWorks.HDL.stWidth true := by
  show (List.replicate SaltWorks.HDL.stWidth SaltWorks.HDL.coreInWidth).map
    (SaltWorks.HDL.run ins [⟨SaltWorks.HDL.coreInWidth, .const true⟩]) = _
  rw [List.map_replicate]
  rfl

theorem outBit_coreShapedT (ins : SaltWorks.HDL.Env) (j : Nat)
    (hj : j < SaltWorks.HDL.stWidth) :
    outBit SaltWorks.HDL.coreShapedT ins j = true := by
  have hl : j < (List.replicate SaltWorks.HDL.stWidth true).length := by
    rw [List.length_replicate]; exact hj
  rw [outBit, sem_coreShapedT, List.getD_eq_getElem _ _ hl, List.getElem_replicate]

theorem outPc_coreShapedT (ins : SaltWorks.HDL.Env) :
    outPc SaltWorks.HDL.coreShapedT ins = SaltWorks.HDL.wordOf (fun _ => true) :=
  wordOf_congr (fun k hk => outBit_coreShapedT ins _ (by show 1024 + k < 1056; omega))

theorem not_pcField_coreShapedT : ¬ PcField SaltWorks.HDL.coreShapedT := by
  intro h
  have hh := h (envWith St.init (encode (Instr.ADDI 1 0 1)))
  rw [outPc_coreShapedT, decQ_envWith_eq, seenWord_envWith, stepT_encode] at hh
  revert hh
  decide +kernel

/-- ⭐ **NEITHER conforming shape is bridgeable.** `not_both_coreShaped_C4Spec`
above says *at most one* of the two can satisfy `C4Spec` — the strongest thing
sayable without the decomposition. **With the decomposition, both are refuted
individually, each by a named field.** *That is the isolation property paying for
itself immediately: the pair argument could never have said which one, or
why.* -/
theorem neither_coreShape_C4Spec :
    ¬ SaltWorks.HDL.C4Spec SaltWorks.HDL.coreShaped
      ∧ ¬ SaltWorks.HDL.C4Spec SaltWorks.HDL.coreShapedT :=
  ⟨not_C4Spec_coreShaped, not_C4Spec_of_not_pcField not_pcField_coreShapedT⟩

/-! ### ⛔ THE LENGTH CONJUNCT IS LOAD-BEARING, and here is the refutation

*The `←` direction cannot drop `c.outs.length = stWidth`, and the reason is not
that the 33 obligations are hard to satisfy — it is that **they say nothing
whatever about output ports past index 1055.** Appending one more port to a
circuit leaves every one of the 33 obligations untouched (they read `getD` at
indices below 1056) and destroys `C4Spec` outright (it is an equality of lists,
and `encD` has exactly 1056 elements).*

⇒ ***The refutation is UNCONDITIONAL and needs no correct core.*** *It says that
for **any** `c` of the right output count, the fieldwise conjunction cannot tell
`c` from `extendOut c m`, while `C4Spec` tells them apart always — so the fields
alone cannot imply `C4Spec`, and the length conjunct is exactly the difference.
Stating it this way is what lets it be proved today: a witness satisfying all 33
fields would have to BE a correct core.* -/

/-- One more output port, reading net `m`. Nothing else changes. -/
def extendOut (c : SaltWorks.HDL.Circ) (m : SaltWorks.HDL.Net) : SaltWorks.HDL.Circ :=
  { c with outs := c.outs ++ [m] }

theorem sem_extendOut (c : SaltWorks.HDL.Circ) (m : SaltWorks.HDL.Net)
    (ins : SaltWorks.HDL.Env) :
    SaltWorks.HDL.sem (extendOut c m) ins
      = SaltWorks.HDL.sem c ins ++ [SaltWorks.HDL.run ins c.gates m] := by
  show (c.outs ++ [m]).map (SaltWorks.HDL.run ins c.gates)
    = c.outs.map (SaltWorks.HDL.run ins c.gates) ++ [SaltWorks.HDL.run ins c.gates m]
  simp

theorem extendOut_outs_length (c : SaltWorks.HDL.Circ) (m : SaltWorks.HDL.Net) :
    (extendOut c m).outs.length = c.outs.length + 1 := by
  show (c.outs ++ [m]).length = c.outs.length + 1
  simp

/-- **The fields cannot see the extra port.** -/
theorem outBit_extendOut (c : SaltWorks.HDL.Circ) (m : SaltWorks.HDL.Net)
    (ins : SaltWorks.HDL.Env) (j : Nat) (hj : j < c.outs.length) :
    outBit (extendOut c m) ins j = outBit c ins j := by
  have hl : j < (SaltWorks.HDL.sem c ins).length := by
    rw [SaltWorks.HDL.sem, List.length_map]; exact hj
  simp only [outBit]
  rw [sem_extendOut, List.getD_append _ _ _ _ hl]

/-- ⛔ **THE REFUTATION — every field survives the extension, and `C4Spec` does
not.** So **the fieldwise conjunction ALONE does not imply `C4Spec`**, and the
length conjunct of `c4Spec_iff_fieldwise` is precisely what closes the gap.
*Stated for an arbitrary `c` with the right output count, so it does not wait on
a correct core to exist.* -/
theorem length_conjunct_is_necessary (c : SaltWorks.HDL.Circ) (m : SaltWorks.HDL.Net)
    (hlen : c.outs.length = SaltWorks.HDL.stWidth) :
    (∀ r : Fin 32, RegField c r → RegField (extendOut c m) r)
      ∧ (PcField c → PcField (extendOut c m))
      ∧ ¬ SaltWorks.HDL.C4Spec (extendOut c m) := by
  refine ⟨?_, ?_, ?_⟩
  · intro r h ins
    have hr := r.isLt
    have he : outReg (extendOut c m) ins r = outReg c ins r :=
      wordOf_congr (fun k hk => outBit_extendOut c m ins (32 * r.val + k)
        (by rw [hlen]; show 32 * r.val + k < 1056; omega))
    rw [he]
    exact h ins
  · intro h ins
    have he : outPc (extendOut c m) ins = outPc c ins :=
      wordOf_congr (fun k hk => outBit_extendOut c m ins (1024 + k)
        (by rw [hlen]; show 1024 + k < 1056; omega))
    rw [he]
    exact h ins
  · intro hc
    have hh := outs_length_of_C4Spec hc
    rw [extendOut_outs_length, hlen] at hh
    omega

/-! ## ⭐⭐ C4FIELDS — THE CERTIFIED BLOCKS, AGAINST THE FIELD OBLIGATIONS

`c4Spec_iff_fieldwise` turned C4 into **33 obligations stated in the ISA's own
operations**, and some of the datapath blocks that will discharge them are landed
and certified in `HDL/Bitwise.lean`. This section is the link between the two.
The first thing it has to do is say **how strong those certificates actually
are**, because their names promise more than their statements deliver.

## ⭐ WHAT `bwOK` AND `sltOK` QUANTIFY OVER: 100 PAIRS, NOT 2^64

```
bwOK c f  =  bwWords.all fun a => bwWords.all fun b => sem c (bwEnv a b) == …
sltOK     =  bwWords.all fun a => bwWords.all fun b => sltDrive a b == cmpWord …
```

**`bwWords` is a TEN-WORD list** — `bwWords_sample_size` pins that in the kernel
rather than by reading it. So each of `bitXor32_correct`, `sltCirc_correct`,
`sltuCirc_correct` and `sub_via_adder_correct` is a check on **100 ordered
operand pairs out of 2^64 ≈ 1.8 × 10^19**, a 5 × 10^-18 slice of the input space.
*Compiler said so in that file's own docstring — "sampled rather than exhaustive"
— so this is not a discovery. It is the fact that decides what the bridges below
may claim, and it belongs where the bridges are rather than only where the
certificates are.*

⇒ ***`bitXor32_correct` does NOT establish that `bitXor32` computes `^^^`.***

## ⇒ SO THE XOR BRIDGE IS PROVED, NOT SAMPLED

**`bitXor32` is a POINTWISE block — 32 independent gates over disjoint bit pairs
— so its meaning is provable STRUCTURALLY, for all 2^64 operand pairs, with no
`decide` anywhere.** `sem_bitXor32` is that proof, and it *supersedes* the
sampled certificate rather than leaning on it: the certificate is 100 points of a
theorem that now holds everywhere. `sem_bitXor32_off_the_sample` exhibits a pair
outside `bwWords` where the general statement applies and the certificate says
nothing.

## ⚠️ THE SLT BRIDGE IS SAMPLED, AND THE SAMPLE IS IN ITS TYPE

**The gap is not in the comparator.** `sltCirc` takes **three input bits**, so its
own semantics is exhaustively decidable — `sem_sltCirc` covers all 8 valuations
by `decide +kernel` — and it computes exactly `s31 ⊕ ((a31 ⊕ b31) ∧ (a31 ⊕ s31))`.

**The sampling enters one layer down.** `sltDrive` feeds that block the *real*
`adder32`'s 31st output, and the only statement connecting that output to `a - b`
is `sub_via_adder_correct`, at the same 100 pairs — because **`adder32` has no
semantic theorem at all**, only `ssa` and `wf`. ⇒ *`sltField_is_sltCirc` carries
`s.get x ∈ bwWords` and `s.get y ∈ bwWords` as hypotheses.* **Those membership
premises ARE the sample.** *They put the weakness in the type, where a caller
must discharge it, instead of in a comment; and they are exactly what a real
adder theorem would delete.*

## ⛔ OUT OF SCOPE HERE, FOR THE SAME REASON

**`ADD`, `ADDI` and `PcField` are untouched.** All three run through `adder32`, so
there is nothing to bridge them to yet. That gap is the compiler seat's lane and
is not claimed here.

## What the bridges say, in `RegField`'s idiom

`RegField c r` asks that `outReg c ins r` — 32 output bits of the core, read back
as a word — equal `(stepT (decQ ins) (seenWord ins)).regs[r]`. **There is no
`core`, so these theorems state the OTHER side of that equation**: for an `XOR`
(resp. `SLT`) instruction word, the destination register's field of the stepped
state is *what the certified block computes on the source registers*, read back
through `wordOf` in exactly the shape `outReg` uses. **The assembly into a
`RegField` is then whatever `core` has to supply, and nothing about the ISA side
is left to negotiate later.**
-/

/-! ### Word helpers -/

theorem wordOf_getLsbD_self (w : Word) :
    SaltWorks.HDL.wordOf (fun k => w.getLsbD k) = w := by
  apply BitVec.eq_of_getLsbD_eq
  intro k hk
  rw [SaltWorks.HDL.wordOf_getLsbD _ _ hk]

theorem wordOf_getD_map_range (f : Nat → Bool) :
    SaltWorks.HDL.wordOf (fun k => ((List.range 32).map f).getD k false)
      = SaltWorks.HDL.wordOf f := by
  apply wordOf_congr
  intro k hk
  have hl : k < ((List.range 32).map f).length := by
    rw [List.length_map, List.length_range]; exact hk
  rw [List.getD_eq_getElem _ _ hl, List.getElem_map, List.getElem_range]

/-- **The size of the certificates' input sample, in the kernel.** Ten words, so
`bwOK`/`sltOK`/`sltuOK`/`subOK` each check 100 ordered pairs. -/
theorem bwWords_sample_size :
    SaltWorks.HDL.bwWords.length = 10
      ∧ SaltWorks.HDL.bwWords.length * SaltWorks.HDL.bwWords.length = 100 := by
  decide +kernel

/-! ### ⭐ THE XOR BLOCK, FOR EVERY OPERAND PAIR

*Structural, by induction over the gate list, using `Sem.lean`'s frame lemma: the
`k`-th gate writes net `64 + k`, which no earlier gate reads, so the operand nets
`0 … 63` survive the whole run untouched.* -/

/-- Running the pointwise `xor` gate list: output net `64 + k` is the `xor` of
the two operand nets, for every `k` below the prefix length. -/
theorem run_xorGates (env : SaltWorks.HDL.Env) :
    ∀ n, n ≤ 32 → ∀ k, k < n →
      SaltWorks.HDL.run env
          ((List.range n).map (fun i => (⟨64 + i, .xor i (32 + i)⟩ : SaltWorks.HDL.Gate)))
          (64 + k)
        = (env k ^^ env (32 + k)) := by
  intro n
  induction n with
  | zero => intro _ k hk; exact absurd hk (Nat.not_lt_zero k)
  | succ n ih =>
    intro hn k hk
    have hn' : n ≤ 32 := by omega
    have hn32 : n < 32 := by omega
    have hfr : ∀ m, m < 64 →
        SaltWorks.HDL.run env
          ((List.range n).map (fun i => (⟨64 + i, .xor i (32 + i)⟩ : SaltWorks.HDL.Gate))) m
          = env m := by
      intro m hm
      refine SaltWorks.HDL.run_of_unwritten env _ m ?_
      intro g hg
      rw [List.mem_map] at hg
      obtain ⟨i, _, hgi⟩ := hg
      subst hgi
      show 64 + i ≠ m
      exact Nat.ne_of_gt (Nat.lt_of_lt_of_le hm (Nat.le_add_right 64 i))
    have hstep : SaltWorks.HDL.run env
        ((List.range (n + 1)).map (fun i => (⟨64 + i, .xor i (32 + i)⟩ : SaltWorks.HDL.Gate)))
        = SaltWorks.HDL.upd
            (SaltWorks.HDL.run env
              ((List.range n).map (fun i => (⟨64 + i, .xor i (32 + i)⟩ : SaltWorks.HDL.Gate))))
            (64 + n)
            ((SaltWorks.HDL.Op.xor n (32 + n)).eval
              (SaltWorks.HDL.run env
                ((List.range n).map
                  (fun i => (⟨64 + i, .xor i (32 + i)⟩ : SaltWorks.HDL.Gate))))) := by
      rw [List.range_succ, List.map_append, SaltWorks.HDL.run_append]
      rfl
    rw [hstep]
    rcases Nat.lt_or_ge k n with hkn | hkn
    · rw [SaltWorks.HDL.upd_of_ne (n := 64 + n) (m := 64 + k) _
        (show 64 + k ≠ 64 + n by omega)]
      exact ih hn' k hkn
    · have hkeq : k = n := by omega
      subst hkeq
      have h1 : k < 64 := by omega
      have h2 : 32 + k < 64 := by omega
      rw [SaltWorks.HDL.upd_self]
      simp only [SaltWorks.HDL.Op.eval]
      rw [hfr k h1, hfr (32 + k) h2]

/-- ⭐⭐ **THE XOR BLOCK COMPUTES `^^^`, ON ALL 2^64 OPERAND PAIRS.** *Not
`decide`d: 2^64 pairs is not a kernel computation. Proved from the gate list's
shape, which is what a pointwise block makes possible and what the sampled
`bitXor32_correct` could not reach.* -/
theorem sem_bitXor32 (a b : Word) :
    SaltWorks.HDL.sem SaltWorks.HDL.bitXor32 (SaltWorks.HDL.bwEnv a b)
      = (List.range 32).map (fun k => (a ^^^ b).getLsbD k) := by
  have h : SaltWorks.HDL.sem SaltWorks.HDL.bitXor32 (SaltWorks.HDL.bwEnv a b)
      = (List.range 32).map (fun k =>
          SaltWorks.HDL.run (SaltWorks.HDL.bwEnv a b) SaltWorks.HDL.bitXor32.gates (64 + k)) := by
    show ((List.range 32).map (fun k => 64 + k)).map
        (SaltWorks.HDL.run (SaltWorks.HDL.bwEnv a b) SaltWorks.HDL.bitXor32.gates) = _
    rw [List.map_map]
    rfl
  rw [h]
  apply List.map_congr_left
  intro k hk
  have hk32 : k < 32 := List.mem_range.mp hk
  have hgates : SaltWorks.HDL.bitXor32.gates
      = (List.range 32).map (fun i => (⟨64 + i, .xor i (32 + i)⟩ : SaltWorks.HDL.Gate)) := rfl
  rw [hgates, run_xorGates _ 32 le_rfl k hk32, BitVec.getLsbD_xor]
  have ha : SaltWorks.HDL.bwEnv a b k = a.getLsbD k := by
    show (if k < 32 then a.getLsbD k else b.getLsbD (k - 32)) = _
    rw [if_pos hk32]
  have hb : SaltWorks.HDL.bwEnv a b (32 + k) = b.getLsbD k := by
    have h1 : ¬(32 + k < 32) := Nat.not_lt.mpr (Nat.le_add_right 32 k)
    have h2 : 32 + k - 32 = k := Nat.add_sub_cancel_left 32 k
    show (if 32 + k < 32 then a.getLsbD (32 + k) else b.getLsbD (32 + k - 32)) = _
    rw [if_neg h1, h2]
  rw [ha, hb]

/-- ⭐ **THE GENERAL THEOREM REACHES WHERE THE CERTIFICATE DOES NOT** — an operand
pair with neither word in the sample. *Without this, "for all 2^64" and "for the
100 checked" are indistinguishable from the outside.* -/
theorem sem_bitXor32_off_the_sample :
    (0x0F0F0F0F : Word) ∉ SaltWorks.HDL.bwWords
      ∧ (0x33333333 : Word) ∉ SaltWorks.HDL.bwWords
      ∧ SaltWorks.HDL.sem SaltWorks.HDL.bitXor32
            (SaltWorks.HDL.bwEnv 0x0F0F0F0F 0x33333333)
          = (List.range 32).map
              (fun k => ((0x0F0F0F0F : Word) ^^^ 0x33333333).getLsbD k) :=
  ⟨by decide +kernel, by decide +kernel, sem_bitXor32 _ _⟩

/-! ### ⭐ THE ISA SIDE — the `XOR` destination field -/

/-- ⭐⭐ **THE XOR FIELD BRIDGE.** For an `XOR rd, x, y` instruction word, the
destination register's field of the stepped state **is what `bitXor32` computes on
the source registers**, read back in `outReg`'s own shape. *No `core` is needed:
this is the equation's right-hand side meeting the block, with only the assembly
left to C4. Unconditional in the operands — it inherits `sem_bitXor32`.* -/
theorem xorField_is_bitXor32 (s : St) (rd x y : Fin 32) (hrd : rd ≠ 0) :
    (stepT (SaltWorks.HDL.decQ (envWith s (encode (Instr.XOR rd x y))))
           (seenWord (envWith s (encode (Instr.XOR rd x y))))).regs[rd.val]
      = SaltWorks.HDL.wordOf (fun k =>
          (SaltWorks.HDL.sem SaltWorks.HDL.bitXor32
            (SaltWorks.HDL.bwEnv (s.get x) (s.get y))).getD k false) := by
  rw [decQ_envWith_eq, seenWord_envWith, stepT_encode, sem_bitXor32,
    wordOf_getD_map_range, wordOf_getLsbD_self]
  try simp only [step_regs_of_with_of_not_touchesMem, SaltWorks.ISA.touchesMem]
  try simp only [step_pc_of_with]
  show ((s.set rd (s.get x ^^^ s.get y)).next).regs[rd.val] = _
  show (s.set rd (s.get x ^^^ s.get y)).regs[rd.val] = _
  simp only [St.set, if_neg hrd]
  exact Vector.getElem_set_self rd.isLt

/-! ### ⭐ THE COMPARATOR, EXHAUSTIVELY OVER ITS THREE INPUTS

*Three input bits is 8 valuations, so unlike the 32-bit blocks this one CAN be
decided outright. Doing so separates the two questions the sampled
`sltCirc_correct` runs together: what the comparator computes from its inputs
(settled here, for every input) and whether the sign bit it is fed is the
subtraction's (open, and blocked on the adder).* -/

/-- ⭐ **THE COMPARATOR BLOCK, FOR ALL EIGHT INPUT VALUATIONS.** -/
theorem sem_sltCirc (a31 b31 s31 : Bool) :
    SaltWorks.HDL.sem SaltWorks.HDL.sltCirc
        (fun i => if i == 0 then a31 else if i == 1 then b31 else s31)
      = SaltWorks.HDL.cmpWord (s31 ^^ ((a31 ^^ b31) && (a31 ^^ s31))) := by
  revert a31 b31 s31
  decide +kernel

/-- ⭐ **AND THEREFORE `sltDrive` IS THE SIGN FORMULA, FOR ALL 2^64 PAIRS** — with
the adder's 31st output left as an opaque term. *This is the exact shape of what
remains: the comparator is discharged unconditionally, and the ONLY thing between
this and `BitVec.slt` is that `(subOut a b).getD 31 false` be the sign bit of
`a - b`, which today is `sub_via_adder_correct` at 100 pairs.* -/
theorem sltDrive_eq_sign_formula (a b : Word) :
    SaltWorks.HDL.sltDrive a b
      = SaltWorks.HDL.cmpWord
          (((SaltWorks.HDL.subOut a b).getD 31 false) ^^
            ((a.getLsbD 31 ^^ b.getLsbD 31)
              && (a.getLsbD 31 ^^ ((SaltWorks.HDL.subOut a b).getD 31 false)))) :=
  sem_sltCirc _ _ _

/-! ### ⚠️ THE ISA SIDE — the `SLT` destination field, at the sample's strength -/

/-- **The sampled certificate, unpacked.** `sltCirc_correct` gives the comparison
only for operands drawn from `bwWords`; this is that `List.all` read back as the
statement it is. -/
theorem sltDrive_eq_of_mem {a b : Word}
    (ha : a ∈ SaltWorks.HDL.bwWords) (hb : b ∈ SaltWorks.HDL.bwWords) :
    SaltWorks.HDL.sltDrive a b = SaltWorks.HDL.cmpWord (BitVec.slt a b) := by
  have h := SaltWorks.HDL.sltCirc_correct
  unfold SaltWorks.HDL.sltOK at h
  have h1 := (List.all_eq_true.mp h) a ha
  have h2 := (List.all_eq_true.mp h1) b hb
  exact eq_of_beq h2

/-- **The widening the ISA needs and the block does not do.** `sltCirc` answers in
one bit; `SLT` writes a 32-bit `0`/`1` word. `cmpWord` is the padding and this is
the word it denotes. -/
theorem wordOf_cmpWord (r : Bool) :
    SaltWorks.HDL.wordOf (fun k => (SaltWorks.HDL.cmpWord r).getD k false)
      = (if r then 1 else 0 : Word) := by
  cases r <;> decide +kernel

/-- ⭐⭐ **THE SLT FIELD BRIDGE — WITH THE SAMPLE AS A HYPOTHESIS.** For an
`SLT rd, x, y` word whose *source registers hold sampled words*, the destination
field is what the `sltCirc` datapath computes, widened to 32 bits.

⚠️ **The two membership premises are not decoration: they are precisely the
strength of `sltCirc_correct`, which checks 100 operand pairs.** *Deleting them
needs a semantic theorem for `adder32`, which does not exist. Stating them makes
the bridge true today and makes the debt visible to every caller.* -/
theorem sltField_is_sltCirc (s : St) (rd x y : Fin 32) (hrd : rd ≠ 0)
    (hx : s.get x ∈ SaltWorks.HDL.bwWords) (hy : s.get y ∈ SaltWorks.HDL.bwWords) :
    (stepT (SaltWorks.HDL.decQ (envWith s (encode (Instr.SLT rd x y))))
           (seenWord (envWith s (encode (Instr.SLT rd x y))))).regs[rd.val]
      = SaltWorks.HDL.wordOf (fun k =>
          (SaltWorks.HDL.sltDrive (s.get x) (s.get y)).getD k false) := by
  rw [decQ_envWith_eq, seenWord_envWith, stepT_encode, sltDrive_eq_of_mem hx hy, wordOf_cmpWord]
  try simp only [step_regs_of_with_of_not_touchesMem, SaltWorks.ISA.touchesMem]
  try simp only [step_pc_of_with]
  show ((s.set rd (if (s.get x).slt (s.get y) then 1 else 0)).next).regs[rd.val] = _
  show (s.set rd (if (s.get x).slt (s.get y) then 1 else 0)).regs[rd.val] = _
  simp only [St.set, if_neg hrd]
  exact Vector.getElem_set_self rd.isLt

/-! ### ⛔ NON-VACUITY — the WRONG block fails each bridge

*Both bridges are equations between a field of `stepT` and a block's output. If
any block satisfied them they would say nothing about which block belongs in the
datapath, so each gets the neighbour it is most likely to be confused with.* -/

/-- ⛔ **THE AND BLOCK DOES NOT MEET THE XOR FIELD.** *Same constructor, same
layout, one `Op` apart — the copy-paste `bwCirc` exists to make unlikely, refuted
at the field rather than only at the circuit.* -/
theorem bitAnd32_fails_the_xorField (s : St) (rd x y : Fin 32) (hrd : rd ≠ 0)
    (hx : s.get x = 0xAAAAAAAA) (hy : s.get y = 0x55555555) :
    (stepT (SaltWorks.HDL.decQ (envWith s (encode (Instr.XOR rd x y))))
           (seenWord (envWith s (encode (Instr.XOR rd x y))))).regs[rd.val]
      ≠ SaltWorks.HDL.wordOf (fun k =>
          (SaltWorks.HDL.sem SaltWorks.HDL.bitAnd32
            (SaltWorks.HDL.bwEnv (s.get x) (s.get y))).getD k false) := by
  rw [xorField_is_bitXor32 s rd x y hrd, hx, hy]
  decide +kernel

/-- ⛔⭐ **THE SIGNED/UNSIGNED TRAP, AT THE FIELD.** RISC-V `SLT` is the **signed**
comparison, and `sltuCirc` — the unsigned comparator, landed and certified beside
it — **fails the `SLT` field on `(0x80000000, 1)`**: as signed, `0x80000000` is the
most negative word and the ISA writes `1`; as unsigned it is the largest and the
block answers `0`.

*This is the sharpest control the tree affords, because the wrong block here is
not a typo — it is a real, correct, certified circuit that differs from the right
one only in signedness, and every test whose spread omits a sign-straddling pair
accepts it.* -/
theorem sltuCirc_fails_the_sltField (s : St) (rd x y : Fin 32) (hrd : rd ≠ 0)
    (hx : s.get x = 0x80000000) (hy : s.get y = 1) :
    (stepT (SaltWorks.HDL.decQ (envWith s (encode (Instr.SLT rd x y))))
           (seenWord (envWith s (encode (Instr.SLT rd x y))))).regs[rd.val]
      ≠ SaltWorks.HDL.wordOf (fun k =>
          (SaltWorks.HDL.sltuDrive (s.get x) (s.get y)).getD k false) := by
  have hxm : s.get x ∈ SaltWorks.HDL.bwWords := by rw [hx]; decide
  have hym : s.get y ∈ SaltWorks.HDL.bwWords := by rw [hy]; decide
  rw [sltField_is_sltCirc s rd x y hrd hxm hym, hx, hy]
  decide +kernel

/-- **The controls' operand hypotheses are satisfiable** — a state meeting each
pair exists, so neither refutation is vacuous. -/
theorem control_states_exist :
    ((St.init.set 1 0xAAAAAAAA).set 2 0x55555555).get 1 = 0xAAAAAAAA
      ∧ ((St.init.set 1 0xAAAAAAAA).set 2 0x55555555).get 2 = 0x55555555
      ∧ ((St.init.set 1 0x80000000).set 2 1).get 1 = 0x80000000
      ∧ ((St.init.set 1 0x80000000).set 2 1).get 2 = 1 := by
  decide +kernel

/-! ### ⭐⭐ THE ADDER, UNCONDITIONALLY — and the sample premises come off

## What was missing, in one line

**`adder32` carried `adder32_ssa` and `adder32_wf` and nothing else: structure,
no semantics.** Its behavioural statements were `adder32_adds_on_sample` and
`adder32_carry_out_on_sample`, at 49 ordered pairs of `addWords`; the SLT path's
was `sub_via_adder_correct`, at 100 pairs of `bwWords`. *Both are tripwires and
neither is a theorem — 100 pairs is 5 × 10⁻¹⁸ of 2^64, and `Adder.lean`'s own
docstring names the hazard they cannot catch: **"a generator producing the right
cone shape and the wrong sum would pass every check here."***

⇒ ***That is why `sltField_is_sltCirc` carries `s.get x ∈ bwWords` and
`s.get y ∈ bwWords`: the premises ARE the sample.*** And it is why `ADD` and
`ADDI` had no bridge at all.

## What this section adds

`sem_adder32` — **the 32 sum bits of `a + b`, then the carry-out, for every one
of the 2^64 operand pairs, with no `decide` and no `native_decide`.** Everything
under it follows: the subtraction path (`subOut_bits`), both comparators
(`sltDrive_uncond`, `sltuDrive_uncond`), and three ISA field bridges
(`addField_is_adder32`, `addiField_is_adder32`,
`sltField_is_sltCirc_unconditional` — *the last is `sltField_is_sltCirc` with
both membership premises deleted; the landed premise-carrying version is left
exactly as it stands*).

## How, and what came from core

**The circuit is a ripple chain, so `run_of_unwritten` — the frame lemma
`sem_bitXor32` runs on — does not apply across slices**: slice `i` reads the net
slice `i-1` wrote. The proof is an induction over slices carrying a genuine
invariant (stated at `run_adGates`), and ⭐ **the carry recurrence is Lean core's,
not this file's**: `BitVec.carry`, `carry_zero`, `carry_succ`,
`getLsbD_add_add_bool`, `carry_width`, `ult_eq_not_carry` and `slt_eq_not_carry`
supply every arithmetic fact about addition, subtraction and comparison. What is
built here is exactly the identification of the CIRCUIT's named carry net `adC i`
with `BitVec.carry i a b cin`, plus three Bool identities of eight valuations
each.

📌 **`Silicon/Equiv/AdderSlice.lean`'s `slice_ok` was NOT reusable and the reason
is structural**: it is stated over `SaltWorks.Silicon.Netlist`/`runP`, a
different carrier and a different evaluator from `HDL.Circ`/`sem`, so importing
it would have bought a bridge obligation rather than a lemma. *Its content — the
majority function — is `Bool.atLeastTwo`, and it is re-derived here in one
`decide` over 8 valuations (`atLeastTwo_eq`).*
-/

section AdderSemantics

-- `SaltWorks.ISA.run` and `SaltWorks.Stack.Program.seenWord` are already in
-- scope, so those two HDL names stay qualified; everything else opens.
open SaltWorks.HDL hiding run seenWord

/-! #### The two Bool identities the slice needs — 8 valuations each -/

theorem atLeastTwo_eq : ∀ x y c : Bool,
    Bool.atLeastTwo x y c = ((x && y) || ((x ^^ y) && c)) := by decide

theorem xor3 : ∀ x y c : Bool, ((x ^^ y) ^^ c) = (x ^^ (y ^^ c)) := by decide

/-! #### The input valuation, with the carry-in as a parameter

*`bwEnv` pins the carry-in to `false` (net 64 reads `b.getLsbD 32`, which is
`false` at width 32). `subOut` drives the SAME circuit with carry-in `true` and
`~~~b` on the `b` port. One theorem has to cover both, so the carry-in is a
parameter here and `bwEnv` is recovered as the `false` instance.* -/

/-- `a` on nets `0…31`, `b` on `32…63`, and `cin` on every net from `64` up. -/
def adEnv (a b : Word) (cin : Bool) : Env :=
  fun i => if i < 32 then a.getLsbD i else if i < 64 then b.getLsbD (i - 32) else cin

/-! #### The generic five-gate slice

*Stated over four raw `Nat` net names rather than over `adSlice n`, because the
only facts the reduction needs are that the three READ nets sit strictly below
the five WRITTEN ones. `simp` then discharges all five `upd`s at once.*

⚠️ **`omega` cannot read a goal whose `<` sits at `HDL.Net`** (`abbrev Net :=
Nat`; it reports *"No usable constraints found"* and silently drops every
`Net`-typed hypothesis). Every bound below is therefore either stated at `Nat`
or `show`n into `Nat` first — that is what the `show` lines in `adA_lt`,
`adB_lt` and `adC_lt` are for, and they are not decoration. -/

theorem run_five (E : Env) (na nb nc P : Nat)
    (hA : na < P) (hB : nb < P) (hC : nc < P) (m : Nat) :
    SaltWorks.HDL.run E
        [(⟨P, .xor na nb⟩ : Gate), ⟨P + 1, .xor P nc⟩, ⟨P + 2, .and na nb⟩,
         ⟨P + 3, .and P nc⟩, ⟨P + 4, .or (P + 2) (P + 3)⟩] m
      = if m = P + 4 then ((E na && E nb) || ((E na ^^ E nb) && E nc))
        else if m = P + 3 then ((E na ^^ E nb) && E nc)
        else if m = P + 2 then (E na && E nb)
        else if m = P + 1 then ((E na ^^ E nb) ^^ E nc)
        else if m = P then (E na ^^ E nb)
        else E m := by
  have h1 : ¬ (na = P) := by omega
  have h2 : ¬ (nb = P) := by omega
  have h3 : ¬ (nc = P) := by omega
  have h4 : ¬ (na = P + 1) := by omega
  have h5 : ¬ (nb = P + 1) := by omega
  have h6 : ¬ (nc = P + 1) := by omega
  have h7 : ¬ (nc = P + 2) := by omega
  simp [run_cons, run_nil, Op.eval, upd, h1, h2, h3, h4, h5, h6, h7]

/-! #### Slice arithmetic -/

theorem adBase_eq (i : Nat) : adBase i = 65 + 5 * i := by
  unfold adBase adIn adW; omega

theorem adA_lt (n : Nat) : adA n < adBase n := by
  show n < 65 + 5 * n
  omega

theorem adB_lt (n : Nat) : adB n < adBase n := by
  show 32 + n < 65 + 5 * n
  omega

theorem adC_lt (n : Nat) : adC n < adBase n := by
  cases n with
  | zero => show (64 : Nat) < 65 + 5 * 0; omega
  | succ m => show 65 + 5 * m + 4 < 65 + 5 * (m + 1); omega

theorem adC_succ (n : Nat) : adC (n + 1) = adBase n + 4 := rfl

theorem adS_eq (n : Nat) : adS n = adBase n + 1 := rfl

/-! #### The gate prefix — the first `n` slices -/

def adGates (n : Nat) : List Gate := (List.range n).flatMap adSlice

theorem adGates_succ (n : Nat) : adGates (n + 1) = adGates n ++ adSlice n := by
  simp [adGates, List.range_succ]

/-- One slice, SaltWorks.HDL.run over the prefix environment. -/
theorem run_adSlice (E : Env) (n : Nat) (m : Nat) :
    SaltWorks.HDL.run E (adSlice n) m
      = if m = adBase n + 4 then
            ((E (adA n) && E (adB n)) || ((E (adA n) ^^ E (adB n)) && E (adC n)))
        else if m = adBase n + 3 then ((E (adA n) ^^ E (adB n)) && E (adC n))
        else if m = adBase n + 2 then (E (adA n) && E (adB n))
        else if m = adBase n + 1 then ((E (adA n) ^^ E (adB n)) ^^ E (adC n))
        else if m = adBase n then (E (adA n) ^^ E (adB n))
        else E m :=
  run_five E (adA n) (adB n) (adC n) (adBase n) (adA_lt n) (adB_lt n) (adC_lt n) m

theorem run_adSlice_cout (E : Env) (n : Nat) :
    SaltWorks.HDL.run E (adSlice n) (adBase n + 4)
      = ((E (adA n) && E (adB n)) || ((E (adA n) ^^ E (adB n)) && E (adC n))) := by
  rw [run_adSlice, if_pos rfl]

theorem run_adSlice_sum (E : Env) (n : Nat) :
    SaltWorks.HDL.run E (adSlice n) (adBase n + 1)
      = ((E (adA n) ^^ E (adB n)) ^^ E (adC n)) := by
  rw [run_adSlice, if_neg (by omega), if_neg (by omega), if_neg (by omega), if_pos rfl]

theorem run_adSlice_frame (E : Env) (n : Nat) (m : Nat) (h : m < adBase n) :
    SaltWorks.HDL.run E (adSlice n) m = E m := by
  rw [run_adSlice, if_neg (by omega), if_neg (by omega), if_neg (by omega),
    if_neg (by omega), if_neg (by omega)]

/-! #### ⭐ THE CARRY INVARIANT — the node

**`bitXor32` is POINTWISE and `adder32` IS NOT.** *Slice `i` READS `adC i`, which
slice `i-1` WROTE, so `run_of_unwritten` — the frame lemma the `xor` proof runs
on — does not apply across slices and there is nothing to induct on but the
chain itself.* ⇒ **The induction carries a three-part invariant: after the first
`n` slices, (1) every primary input net still holds its input, (2) the named
carry net `adC n` holds `BitVec.carry n a b cin`, and (3) sum nets `adS 0 …
adS (n-1)` hold the low sum bits.**

⭐ **The carry recurrence is NOT hand-rolled.** *Lean core already defines the
ripple model (`Init.Data.BitVec.Bitblast`: `carry`, `carry_zero`, `carry_succ`,
`getLsbD_add_add_bool`, `carry_width`, `ult_eq_not_carry`, `slt_eq_not_carry`),
so the whole proof is the identification of the CIRCUIT's carry net with core's
`BitVec.carry i a b cin` — and every arithmetic fact about addition comes from
core rather than from this file.* -/

/-- **The invariant, by induction on the number of slices run.** -/
theorem run_adGates (a b : Word) (cin : Bool) :
    ∀ n, n ≤ 32 →
      (∀ m : Nat, m < 65 → SaltWorks.HDL.run (adEnv a b cin) (adGates n) m = adEnv a b cin m)
      ∧ SaltWorks.HDL.run (adEnv a b cin) (adGates n) (adC n) = BitVec.carry n a b cin
      ∧ (∀ k : Nat, k < n → SaltWorks.HDL.run (adEnv a b cin) (adGates n) (adS k)
            = (a.getLsbD k ^^ (b.getLsbD k ^^ BitVec.carry k a b cin))) := by
  intro n
  induction n with
  | zero =>
    intro _
    refine ⟨fun m _ => rfl, ?_, fun k hk => absurd hk (Nat.not_lt_zero k)⟩
    show adEnv a b cin 64 = BitVec.carry 0 a b cin
    rw [BitVec.carry_zero]
    simp [adEnv]
  | succ n ih =>
    intro hn
    have hn32 : n < 32 := by omega
    obtain ⟨hfr, hc, hs⟩ := ih (by omega)
    have hbn : adBase n = 65 + 5 * n := adBase_eq n
    have hAv : SaltWorks.HDL.run (adEnv a b cin) (adGates n) (adA n) = a.getLsbD n := by
      have h65 : adA n < 65 := by show n < 65; omega
      rw [hfr _ h65]
      show (if n < 32 then a.getLsbD n
              else if n < 64 then b.getLsbD (n - 32) else cin) = a.getLsbD n
      rw [if_pos hn32]
    have hBv : SaltWorks.HDL.run (adEnv a b cin) (adGates n) (adB n) = b.getLsbD n := by
      have h65 : adB n < 65 := by show 32 + n < 65; omega
      rw [hfr _ h65]
      show (if 32 + n < 32 then a.getLsbD (32 + n)
              else if 32 + n < 64 then b.getLsbD (32 + n - 32) else cin) = b.getLsbD n
      rw [if_neg (by omega), if_pos (by omega), show 32 + n - 32 = n by omega]
    refine ⟨?_, ?_, ?_⟩
    · intro m hm
      rw [adGates_succ, run_append, run_adSlice_frame _ _ _ (by omega)]
      exact hfr m hm
    · rw [adGates_succ, run_append, adC_succ, run_adSlice_cout, hAv, hBv, hc,
        BitVec.carry_succ, atLeastTwo_eq]
    · intro k hk
      rw [adGates_succ, run_append, adS_eq]
      rcases Nat.lt_or_ge k n with hkn | hkn
      · have hbk : adBase k = 65 + 5 * k := adBase_eq k
        rw [run_adSlice_frame _ _ _ (by omega)]
        rw [← adS_eq]
        exact hs k hkn
      · have hkeq : k = n := by omega
        subst hkeq
        rw [run_adSlice_sum, hAv, hBv, hc, xor3]

/-! #### ⭐⭐ THE THEOREM -/

/-- ⭐⭐ **`adder32` ADDS — every operand pair, every carry-in.** The 32 sum bits
of `a + b + cin` in port order, then the carry-out. *Not `decide`d: 2^64 pairs is
not a kernel computation.* -/
theorem sem_adder32_gen (a b : Word) (cin : Bool) :
    sem adder32 (adEnv a b cin)
      = (List.range 32).map
            (fun k => (a + b + BitVec.setWidth 32 (BitVec.ofBool cin)).getLsbD k)
          ++ [BitVec.carry 32 a b cin] := by
  obtain ⟨-, hc, hs⟩ := run_adGates a b cin 32 le_rfl
  have houts : adder32.outs = (List.range 32).map adS ++ [adC 32] := rfl
  have hgates : adder32.gates = adGates 32 := rfl
  have h1 : ((List.range 32).map adS).map (SaltWorks.HDL.run (adEnv a b cin) (adGates 32))
      = (List.range 32).map
          (fun k => (a + b + BitVec.setWidth 32 (BitVec.ofBool cin)).getLsbD k) := by
    rw [List.map_map]
    refine List.map_congr_left ?_
    intro k hk
    have hk32 : k < 32 := List.mem_range.mp hk
    show SaltWorks.HDL.run (adEnv a b cin) (adGates 32) (adS k) = _
    rw [hs k hk32]
    exact (BitVec.getLsbD_add_add_bool hk32 a b cin).symm
  have h2 : [adC 32].map (SaltWorks.HDL.run (adEnv a b cin) (adGates 32))
      = [BitVec.carry 32 a b cin] := by
    show [SaltWorks.HDL.run (adEnv a b cin) (adGates 32) (adC 32)] = _
    rw [hc]
  unfold sem
  rw [houts, hgates, List.map_append, h1, h2]

/-- ⭐ **THE ADDER'S ARITHMETIC BIT** — `adder32`'s run at sum-bit `k` **is** bit `k`
of `a + b + cin`. This is `sem_adder32_gen` read at one index: `adder32.outs` is 32
sum bits then the carry-out, so `k < 32` selects `adS k` on the left and the
arithmetic bit on the right, leaving the carry-out tail untouched.

⚖️ **HOISTED HERE at the Captain's ruling (2026-08-10 07:31), beside its parent.**
It had been proved TWICE — `MacBridge`'s (math's) and `MacCell.sc_adder_bit`
(compiler's, disclosed in its own docstring). Neither was careless: **a Lean file
may use what it imports and never the reverse**, and the fact was first proved in
`MacBridge`, which sits DOWNSTREAM of `MacCell`, so the upstream file could not
borrow it and re-proved it. Living beside `sem_adder32_gen` — above both — it is
reachable from either, and both copies retire by repointing.

⚠️ `run` is qualified: this region opens `SaltWorks.HDL` **hiding `run`** (:2968). -/
theorem adder_run_is_sum_bit (a b : Word) (cin : Bool) (k : Nat) (hk : k < 32) :
    SaltWorks.HDL.run (adEnv a b cin) adder32.gates (adS k)
      = (a + b + BitVec.setWidth 32 (BitVec.ofBool cin)).getLsbD k := by
  have h := congrArg (fun l : List Bool => l.getD k false) (sem_adder32_gen a b cin)
  have houts : adder32.outs = (List.range 32).map adS ++ [adC 32] := rfl
  simpa [sem, houts, List.getD_eq_getElem?_getD, List.getElem?_append, List.getElem?_map,
         List.getElem?_range, hk] using h


theorem bwEnv_eq_adEnv (a b : Word) (n : Nat) : bwEnv a b n = adEnv a b false n := by
  show (if n < 32 then a.getLsbD n else b.getLsbD (n - 32))
      = (if n < 32 then a.getLsbD n else if n < 64 then b.getLsbD (n - 32) else false)
  by_cases h1 : n < 32
  · rw [if_pos h1, if_pos h1]
  · rw [if_neg h1, if_neg h1]
    by_cases h2 : n < 64
    · rw [if_pos h2]
    · rw [if_neg h2]
      apply BitVec.getLsbD_of_ge
      omega

/-- ⭐⭐ **THE 32-BIT RIPPLE ADDER ADDS, ON ALL 2^64 OPERAND PAIRS** — the
carry-in `bwEnv` supplies is `false`, so this is `a + b` outright. *This
supersedes `adder32_adds_on_sample` and `adder32_carry_out_on_sample` (49 pairs
of `addWords`) the way `sem_bitXor32` superseded `bitXor32_correct`: the
certificates are points of a theorem that now holds everywhere.* -/
theorem sem_adder32 (a b : Word) :
    sem adder32 (bwEnv a b)
      = (List.range 32).map (fun k => (a + b).getLsbD k) ++ [BitVec.carry 32 a b false] := by
  rw [sem_congr adder32 (bwEnv_eq_adEnv a b), sem_adder32_gen]
  simp

/-! #### Reading the 33-element output list

⚠️ **`adder32.outs` is 32 sum bits THEN the carry-out, so `sem` returns 33
values, not 32.** *Every reader below is indexed against that length.* -/

theorem getD_of_range_append (f : Nat → Bool) (t : List Bool) (k : Nat) (hk : k < 32) :
    (((List.range 32).map f) ++ t).getD k false = f k := by
  have hl1 : ((List.range 32).map f).length = 32 := by simp
  have hlt : k < (((List.range 32).map f) ++ t).length := by
    rw [List.length_append, hl1]; omega
  rw [List.getD_eq_getElem _ _ hlt, List.getElem_append_left (by rw [hl1]; exact hk)]
  simp

theorem getD_32_of_range_append (f : Nat → Bool) (x : Bool) :
    (((List.range 32).map f) ++ [x]).getD 32 false = x := by
  have hl1 : ((List.range 32).map f).length = 32 := by simp
  have hlt : 32 < (((List.range 32).map f) ++ [x]).length := by
    rw [List.length_append, hl1]; simp
  rw [List.getD_eq_getElem _ _ hlt, List.getElem_append_right (by rw [hl1])]
  simp [hl1]

theorem sem_adder32_getD (a b : Word) (k : Nat) (hk : k < 32) :
    (sem adder32 (bwEnv a b)).getD k false = (a + b).getLsbD k := by
  rw [sem_adder32]; exact getD_of_range_append _ _ k hk

theorem sem_adder32_cout (a b : Word) :
    (sem adder32 (bwEnv a b)).getD 32 false = decide (a.toNat + b.toNat ≥ 2 ^ 32) := by
  rw [sem_adder32, getD_32_of_range_append, BitVec.carry_width]
  simp

/-! #### ⭐ THE SUBTRACTION PATH, UNCONDITIONALLY

*`subOut` is the SAME `adder32`, driven with `~~~b` and carry-in `1`. Its only
previous statement was `sub_via_adder_correct` at 100 pairs — and that sample is
exactly what put `∈ bwWords` into `sltField_is_sltCirc`'s type.* -/

theorem subEnv_eq (a b : Word) (n : Nat) :
    (if n < 32 then a.getLsbD n else if n < 64 then !(b.getLsbD (n - 32)) else true)
      = adEnv a (~~~b) true n := by
  show _ = (if n < 32 then a.getLsbD n
              else if n < 64 then (~~~b).getLsbD (n - 32) else true)
  by_cases h1 : n < 32
  · rw [if_pos h1, if_pos h1]
  · rw [if_neg h1, if_neg h1]
    by_cases h2 : n < 64
    · have h3 : n - 32 < 32 := by omega
      rw [if_pos h2, if_pos h2]
      simp [h3]
    · rw [if_neg h2, if_neg h2]

theorem subOut_eq_sem (a b : Word) : subOut a b = sem adder32 (adEnv a (~~~b) true) :=
  sem_congr adder32 (fun n => subEnv_eq a b n)

theorem setWidth_ofBool_true : BitVec.setWidth 32 (BitVec.ofBool true) = (1 : Word) := by decide

theorem add_not_one (a b : Word) :
    a + ~~~b + BitVec.setWidth 32 (BitVec.ofBool true) = a - b := by
  rw [setWidth_ofBool_true, BitVec.sub_eq_add_neg, BitVec.neg_eq_not_add, BitVec.add_assoc]
  rfl

/-- ⭐ **`a - b` THROUGH THE REAL ADDER, FOR ALL 2^64 PAIRS.** -/
theorem subOut_bits (a b : Word) :
    subOut a b = (List.range 32).map (fun k => (a - b).getLsbD k)
        ++ [BitVec.carry 32 a (~~~b) true] := by
  rw [subOut_eq_sem, sem_adder32_gen, add_not_one]

theorem sub_via_adder_unconditional (a b : Word) :
    (subOut a b).take 32 = (List.range 32).map (fun k => (a - b).getLsbD k) := by
  rw [subOut_bits]; exact List.take_left' (by simp)

theorem subOut_sign (a b : Word) : (subOut a b).getD 31 false = (a - b).getLsbD 31 := by
  rw [subOut_bits]; exact getD_of_range_append _ _ 31 (by omega)

theorem subOut_cout (a b : Word) :
    (subOut a b).getD 32 false = BitVec.carry 32 a (~~~b) true := by
  rw [subOut_bits]; exact getD_32_of_range_append _ _

/-! #### ⭐ THE COMPARATORS, WITH THE SAMPLE PREMISES GONE

*`sem_sltCirc` already settled what the comparator computes FROM its inputs, for
all 8 valuations; what was open was whether the sign bit it is fed is the
subtraction's. That is now closed, so both comparators are unconditional.*
**`sltu` is core's `ult_eq_not_carry` read off the 33rd output; `slt` is core's
`slt_eq_not_carry` plus one 8-case Bool identity relating the circuit's
overflow correction to the `msb`/carry form.** -/

theorem sem_sltuCirc : ∀ x : Bool, sem sltuCirc (fun _ => x) = cmpWord (!x) := by decide

theorem sltuDrive_uncond (a b : Word) : sltuDrive a b = cmpWord (BitVec.ult a b) := by
  unfold sltuDrive
  rw [subOut_cout, sem_sltuCirc, ← BitVec.ult_eq_not_carry]

theorem msb31 (a : Word) : a.msb = a.getLsbD 31 := BitVec.msb_eq_getLsbD_last a

theorem carry32_expand (a b : Word) :
    BitVec.carry 32 a (~~~b) true
      = Bool.atLeastTwo (a.getLsbD 31) (!(b.getLsbD 31)) (BitVec.carry 31 a (~~~b) true) := by
  have h : BitVec.carry 32 a (~~~b) true
      = Bool.atLeastTwo (a.getLsbD 31) ((~~~b).getLsbD 31) (BitVec.carry 31 a (~~~b) true) :=
    BitVec.carry_succ 31 a (~~~b) true
  rw [h]; simp

theorem subOut_sign_formula (a b : Word) :
    (subOut a b).getD 31 false
      = (a.getLsbD 31 ^^ ((!(b.getLsbD 31)) ^^ BitVec.carry 31 a (~~~b) true)) := by
  rw [subOut_sign, ← add_not_one, BitVec.getLsbD_add_add_bool (show 31 < 32 by omega)]
  simp

theorem slt_bool : ∀ x y c : Bool,
    ((x ^^ ((!y) ^^ c)) ^^ ((x ^^ y) && (x ^^ (x ^^ ((!y) ^^ c)))))
      = ((x == y) ^^ Bool.atLeastTwo x (!y) c) := by decide

theorem slt_sign_formula (a b : Word) :
    ((a.getLsbD 31 ^^ ((!(b.getLsbD 31)) ^^ BitVec.carry 31 a (~~~b) true))
        ^^ ((a.getLsbD 31 ^^ b.getLsbD 31)
            && (a.getLsbD 31
                ^^ (a.getLsbD 31 ^^ ((!(b.getLsbD 31)) ^^ BitVec.carry 31 a (~~~b) true)))))
      = BitVec.slt a b := by
  rw [slt_bool, BitVec.slt_eq_not_carry, msb31, msb31, carry32_expand]

theorem sltDrive_uncond (a b : Word) : sltDrive a b = cmpWord (BitVec.slt a b) := by
  rw [sltDrive_eq_sign_formula, subOut_sign_formula, slt_sign_formula]

/-! #### ⭐ THE ISA BRIDGES — `ADD`, `ADDI`, and `SLT` without the sample

*Same shape as `xorField_is_bitXor32`: for an instruction word, the destination
register's field of the stepped state is what the certified block computes on the
source registers, read back through `wordOf` in `outReg`'s own shape. All three
are unconditional in the operands.*

⛔ **`PcField` is NOT closed by this and the reason is worth recording**: it is a
statement about a whole `core`'s output bits `1024…1055`, and the pc path does
not run through `adder32` at all — `pcNext` implements the increment itself
(`pcNext_not_beq_adds_four`), and `inc32` is unreferenced. *`sem_adder32` gives
`PcField` nothing; the debt there is `core`, not the adder.* -/

theorem wordOf_getD_range_append (f : Nat → Bool) (t : List Bool) :
    wordOf (fun k => (((List.range 32).map f) ++ t).getD k false)
      = wordOf f :=
  wordOf_congr (fun k hk => getD_of_range_append f t k hk)

theorem addField_is_adder32 (s : St) (rd x y : Fin 32) (hrd : rd ≠ 0) :
    (stepT (decQ (envWith s (encode (Instr.ADD rd x y))))
           (seenWord (envWith s (encode (Instr.ADD rd x y))))).regs[rd.val]
      = wordOf (fun k =>
          (sem adder32 (bwEnv (s.get x) (s.get y))).getD k false) := by
  rw [decQ_envWith_eq, seenWord_envWith, stepT_encode, sem_adder32,
    wordOf_getD_range_append, wordOf_getLsbD_self]
  try simp only [step_regs_of_with_of_not_touchesMem, SaltWorks.ISA.touchesMem]
  try simp only [step_pc_of_with]
  show ((s.set rd (s.get x + s.get y)).next).regs[rd.val] = _
  show (s.set rd (s.get x + s.get y)).regs[rd.val] = _
  simp only [St.set, if_neg hrd]
  exact Vector.getElem_set_self rd.isLt

theorem addiField_is_adder32 (s : St) (rd x : Fin 32) (imm : BitVec 12) (hrd : rd ≠ 0) :
    (stepT (decQ (envWith s (encode (Instr.ADDI rd x imm))))
           (seenWord (envWith s (encode (Instr.ADDI rd x imm))))).regs[rd.val]
      = wordOf (fun k =>
          (sem adder32 (bwEnv (s.get x) (imm.signExtend 32))).getD k false) := by
  rw [decQ_envWith_eq, seenWord_envWith, stepT_encode, sem_adder32,
    wordOf_getD_range_append, wordOf_getLsbD_self]
  try simp only [step_regs_of_with_of_not_touchesMem, SaltWorks.ISA.touchesMem]
  try simp only [step_pc_of_with]
  show ((s.set rd (s.get x + imm.signExtend 32)).next).regs[rd.val] = _
  show (s.set rd (s.get x + imm.signExtend 32)).regs[rd.val] = _
  simp only [St.set, if_neg hrd]
  exact Vector.getElem_set_self rd.isLt

theorem sltField_is_sltCirc_unconditional (s : St) (rd x y : Fin 32) (hrd : rd ≠ 0) :
    (stepT (decQ (envWith s (encode (Instr.SLT rd x y))))
           (seenWord (envWith s (encode (Instr.SLT rd x y))))).regs[rd.val]
      = wordOf (fun k => (sltDrive (s.get x) (s.get y)).getD k false) := by
  rw [decQ_envWith_eq, seenWord_envWith, stepT_encode, sltDrive_uncond, wordOf_cmpWord]
  try simp only [step_regs_of_with_of_not_touchesMem, SaltWorks.ISA.touchesMem]
  try simp only [step_pc_of_with]
  show ((s.set rd (if (s.get x).slt (s.get y) then 1 else 0)).next).regs[rd.val] = _
  show (s.set rd (if (s.get x).slt (s.get y) then 1 else 0)).regs[rd.val] = _
  simp only [St.set, if_neg hrd]
  exact Vector.getElem_set_self rd.isLt

/-! #### ⛔ NON-VACUITY

*An adder theorem that any circuit satisfied would say nothing about which
circuit belongs in the datapath, and a theorem that only reached the checked
pairs would be the certificate under another name.* -/

/-- ⛔ ONE SLICE MUTATED: slice 16's carry-out gate is `and`, not `or`. -/
def adSliceCut (i : Nat) : List Gate :=
  if i == 16 then
    [⟨adP i, .xor (adA i) (adB i)⟩,
     ⟨adS i, .xor (adP i) (adC i)⟩,
     ⟨adG i, .and (adA i) (adB i)⟩,
     ⟨adT i, .and (adP i) (adC i)⟩,
     ⟨adBase i + 4, .and (adG i) (adT i)⟩]
  else adSlice i

def adder32Cut : Circ :=
  { nIn := adIn
    gates := (List.range adW).flatMap adSliceCut
    outs := (List.range adW).map adS ++ [adC adW] }

theorem adder32Cut_is_ssa : adder32Cut.ssa = true := by decide +kernel

/-- ⛔ **ONE GATE WRONG AND THE THEOREM REFUSES IT.** *`adder32Cut` is `adder32`
with slice 16's carry-out gate changed from `or` to `and` — which makes that
carry identically `false`, since `a&&b` and `a^^b` are disjoint. It is still
`ssa`, still `wf`, still 160 gates, still the right cone shape. The pair
`(0x00010000, 0x00010000)` generates a carry at exactly that slice.* -/
theorem adder32Cut_fails_the_adder :
    sem adder32Cut (bwEnv 0x00010000 0x00010000)
      ≠ (List.range 32).map (fun k => ((0x00010000 : Word) + 0x00010000).getLsbD k)
          ++ [BitVec.carry 32 (0x00010000 : Word) 0x00010000 false] := by decide +kernel

/-- ⛔ **AND THE CARRY-FREE "ADDER" FAILS IT TOO.** *`bitXor32` is addition
without carries — it agrees with `adder32` on every operand pair that generates
none, which is why `1 + 1` is the whole refutation.* -/
theorem bitXor32_fails_the_adder :
    sem bitXor32 (bwEnv 1 1)
      ≠ (List.range 32).map (fun k => ((1 : Word) + 1).getLsbD k)
          ++ [BitVec.carry 32 (1 : Word) 1 false] := by decide +kernel

/-- ⭐ **THE THEOREM REACHES WHERE NEITHER CERTIFICATE DOES** — an operand pair
in neither `bwWords` (the 100-pair spread) nor `addWords` (the 49-pair spread),
with a carry-out that is genuinely `true`. *Without this, "for all 2^64" and
"for the pairs someone listed" are indistinguishable from the outside.* -/
theorem sem_adder32_off_the_sample :
    (0xF0F0F0F0 : Word) ∉ bwWords ∧ (0xF0F0F0F0 : Word) ∉ addWords
      ∧ sem adder32 (bwEnv 0xF0F0F0F0 0xF0F0F0F0)
          = (List.range 32).map (fun k => ((0xF0F0F0F0 : Word) + 0xF0F0F0F0).getLsbD k)
              ++ [BitVec.carry 32 (0xF0F0F0F0 : Word) 0xF0F0F0F0 false]
      ∧ BitVec.carry 32 (0xF0F0F0F0 : Word) 0xF0F0F0F0 false = true :=
  ⟨by decide +kernel, by decide +kernel, sem_adder32 _ _, by decide +kernel⟩

end AdderSemantics

/-! ## ⭐⭐ THE ORGANS — `pcNext`, AND THE THREE POINTWISE BLOCKS

**A sampled certificate is a tripwire; C4 rests on organ theorems.** `adder32`
left the sampled tier at `752675c`; this section takes four more blocks with it.

## ⚠️ WHAT THE FOUR STANDING `pcNext` THEOREMS ACTUALLY QUANTIFY OVER, MEASURED

*Read before assuming any of them was already general — none of them is:*

```
pcNext_correct_on_sample     pcCases x pcOffs x [false,true]   =  100 driven points
pcNext_not_beq_adds_four     pcCases x pcOffs, isBEQ := false  =   50 driven points
pcNext_taken_adds_offset     pcRun 7 7 0x7FFFFFFC true         =    1 point
pcNext_compares_all_32_bits  pcRun 0x80000000 0 8 true         =    1 point
pcNext_compares_the_low_bit  pcRun 0xA5A5A5A5 0xA5A5A5A4 8 true=    1 point
```

⇒ **All five are `decide +kernel` over FIXED operand lists.** The last three read
like universally quantified claims about the comparator's width and are single
points; `..._not_beq_adds_four` binds `p` and `o` but only over the ten pairs and
five offsets the file lists. The input space is `2^97`. **They are lemmas of
`sem_pcNext` below, not competition for it, and none of them was reusable as a
step in its proof.**

## How, and what is genuinely different from the adder

**`pcNext` is neither pointwise nor a ripple chain — it is three shapes in
series**, and the proof has one lemma per shape:

* the 32 `xor` difference gates are POINTWISE (`run_pointwise`, which is also
  what closes the three bitwise organs below — one lemma, four blocks);
* the 31-gate OR tree is a CHAIN, so `run_of_unwritten` does not apply across it
  and it needs its own induction (`run_orChain`). ⭐ **It is proved over
  `orChain` GENERICALLY** rather than over the concrete 32-input instance, so any
  later block built from `Decoder.lean`'s chain inherits it;
* the addend mux is 32 INDEPENDENT blocks, one of which (bit 2, the single set
  bit of the constant `4`) is two gates instead of one — so its induction carries
  a disjointness obligation the pointwise lemma does not have.

⭐ **`sem_adder32`'s machinery did NOT transfer, and the reason is the block's
own design decision.** `PcNext.lean:19` emits the *addend* and leaves the
addition to the assembly, precisely so the block does not instantiate `adder32`.
There is therefore no carry chain here and `BitVec.carry` appears nowhere; what
transferred is the *method* — a frame lemma plus an induction carrying an
invariant — not a line of the adder's arithmetic.

⚠️ **`omega` CANNOT READ A GOAL AT `Net`.** `abbrev Net := Nat`, and `omega`
still drops the goal and then tries to derive `False` from the context —
observed here on `163 + k = 163 + k`, which it reported as a possible
counterexample for `0 ≤ k ≤ 1`. Every net-arithmetic obligation below therefore
goes through `pcOut : Nat → Nat`, a `Nat`-valued mirror of `pcAddendOut`, or a
`show` into `Nat`. This is the trap that cost the adder node three cycles,
restated because it is not a `Net`-vs-`Nat` *coercion* problem: it is that a
`def`-headed bound is an opaque atom to `omega` whatever its type.

⛔ **`PcField` IS NOT CLOSED BY THIS, and the shape of the remaining debt is
exactly the adder's.** `PcField` is a statement about a whole `core`'s output
bits `1024 … 1055`, and no `core` exists. What lands here is the block-level
theorem plus the three bridge lemmas a `core` assembly would apply — the same
service `addField_is_adder32` performs for `ADD`. *The debt is `core`, not
`pcNext`.*
-/

section OrganSemantics

open SaltWorks.HDL hiding seenWord

/-! ## The generic pointwise block -/

theorem run_pointwise (E : Env) (base : Nat) (mk : Nat → Op) :
    ∀ n : Nat, (∀ i : Nat, i < n → ∀ a ∈ (mk i).fanin, a < base) →
      (∀ m : Nat, m < base →
          run E ((List.range n).map (fun i => (⟨base + i, mk i⟩ : Gate))) m = E m)
      ∧ (∀ k : Nat, k < n →
          run E ((List.range n).map (fun i => (⟨base + i, mk i⟩ : Gate))) (base + k)
            = (mk k).eval E) := by
  intro n
  induction n with
  | zero =>
    intro _
    exact ⟨fun m _ => rfl, fun k hk => absurd hk (Nat.not_lt_zero k)⟩
  | succ n ih =>
    intro hread
    obtain ⟨hfr, hval⟩ := ih (fun i hi => hread i (Nat.lt_succ_of_lt hi))
    have hsplit : (List.range (n + 1)).map (fun i => (⟨base + i, mk i⟩ : Gate))
        = (List.range n).map (fun i => (⟨base + i, mk i⟩ : Gate)) ++ [⟨base + n, mk n⟩] := by
      rw [List.range_succ, List.map_append]
      rfl
    have hstep : ∀ m : Nat,
        run E ((List.range (n + 1)).map (fun i => (⟨base + i, mk i⟩ : Gate))) m
          = upd (run E ((List.range n).map (fun i => (⟨base + i, mk i⟩ : Gate))))
              (base + n)
              ((mk n).eval (run E ((List.range n).map (fun i => (⟨base + i, mk i⟩ : Gate))))) m := by
      intro m
      rw [hsplit, run_append]
      rfl
    refine ⟨?_, ?_⟩
    · intro m hm
      rw [hstep m, upd_of_ne _ (Nat.ne_of_lt (Nat.lt_of_lt_of_le hm (Nat.le_add_right base n)))]
      exact hfr m hm
    · intro k hk
      rw [hstep (base + k)]
      rcases Nat.lt_or_ge k n with hkn | hkn
      · rw [upd_of_ne _ (fun hEq => absurd (Nat.add_left_cancel hEq) (Nat.ne_of_lt hkn))]
        exact hval k hkn
      · have hkeq : k = n := Nat.le_antisymm (Nat.le_of_lt_succ hk) hkn
        subst hkeq
        rw [upd_self]
        exact Op.eval_congr (mk k) (fun a ha => hfr a (hread k hk a ha))

theorem any_congr_mem {α : Type} {l : List α} {p q : α → Bool} (h : ∀ x ∈ l, p x = q x) :
    l.any p = l.any q := by
  induction l with
  | nil => rfl
  | cons a as ih =>
    rw [List.any_cons, List.any_cons, h a (by simp), ih (fun x hx => h x (by simp [hx]))]

/-! ## TASK 2 — the three bitwise organs, from the one lemma -/

theorem sem_bwCirc (mk : Net → Net → Op) (f : Bool → Bool → Bool)
    (hfan : ∀ i : Nat, i < 32 → ∀ a ∈ (mk i (32 + i)).fanin, a < 64)
    (hev : ∀ (E : Env) (i : Nat), (mk i (32 + i)).eval E = f (E i) (E (32 + i)))
    (a b : Word) :
    sem (bwCirc mk) (bwEnv a b)
      = (List.range 32).map (fun k => f (a.getLsbD k) (b.getLsbD k)) := by
  have hgates : (bwCirc mk).gates
      = (List.range 32).map (fun i => (⟨64 + i, mk i (32 + i)⟩ : Gate)) := rfl
  have hrun := (run_pointwise (bwEnv a b) 64 (fun i => mk i (32 + i)) 32 hfan).2
  have h : sem (bwCirc mk) (bwEnv a b)
      = (List.range 32).map (fun k => run (bwEnv a b) (bwCirc mk).gates (64 + k)) := by
    show ((List.range 32).map (fun k => 64 + k)).map
        (run (bwEnv a b) (bwCirc mk).gates) = _
    rw [List.map_map]
    rfl
  rw [h]
  refine List.map_congr_left ?_
  intro k hk
  have hk32 : k < 32 := List.mem_range.mp hk
  rw [hgates, hrun k hk32, hev]
  have ha : bwEnv a b k = a.getLsbD k := by
    show (if k < 32 then a.getLsbD k else b.getLsbD (k - 32)) = _
    rw [if_pos hk32]
  have hb : bwEnv a b (32 + k) = b.getLsbD k := by
    show (if 32 + k < 32 then a.getLsbD (32 + k) else b.getLsbD (32 + k - 32)) = _
    rw [if_neg (Nat.not_lt.mpr (Nat.le_add_right 32 k)), Nat.add_sub_cancel_left]
  rw [ha, hb]

theorem sem_bitAnd32 (a b : Word) :
    sem bitAnd32 (bwEnv a b) = (List.range 32).map (fun k => (a &&& b).getLsbD k) := by
  rw [show bitAnd32 = bwCirc .and from rfl,
    sem_bwCirc .and (· && ·)
      (fun i hi c hc => by
        simp only [Op.fanin, List.mem_cons, List.not_mem_nil, or_false] at hc
        rcases hc with rfl | rfl
        · exact Nat.lt_of_lt_of_le hi (by norm_num)
        · exact Nat.lt_of_lt_of_le (Nat.add_lt_add_left hi 32) (by norm_num))
      (fun _ _ => rfl)]
  exact List.map_congr_left (fun k _ => by simp)

theorem sem_bitOr32 (a b : Word) :
    sem bitOr32 (bwEnv a b) = (List.range 32).map (fun k => (a ||| b).getLsbD k) := by
  rw [show bitOr32 = bwCirc .or from rfl,
    sem_bwCirc .or (· || ·)
      (fun i hi c hc => by
        simp only [Op.fanin, List.mem_cons, List.not_mem_nil, or_false] at hc
        rcases hc with rfl | rfl
        · exact Nat.lt_of_lt_of_le hi (by norm_num)
        · exact Nat.lt_of_lt_of_le (Nat.add_lt_add_left hi 32) (by norm_num))
      (fun _ _ => rfl)]
  exact List.map_congr_left (fun k _ => by simp)

theorem sem_bitNot32 (a : Word) :
    sem bitNot32 (fun i => a.getLsbD i) = (List.range 32).map (fun k => (~~~a).getLsbD k) := by
  have hgates : bitNot32.gates
      = (List.range 32).map (fun i => (⟨32 + i, Op.not i⟩ : Gate)) := rfl
  have hrun := (run_pointwise (fun i => a.getLsbD i) 32 (fun i => Op.not i) 32
      (fun i hi c hc => by
        simp only [Op.fanin, List.mem_cons, List.not_mem_nil, or_false] at hc
        exact hc ▸ hi)).2
  have h : sem bitNot32 (fun i => a.getLsbD i)
      = (List.range 32).map (fun k => run (fun i => a.getLsbD i) bitNot32.gates (32 + k)) := by
    show ((List.range 32).map (fun k => 32 + k)).map
        (run (fun i => a.getLsbD i) bitNot32.gates) = _
    rw [List.map_map]
    rfl
  rw [h]
  refine List.map_congr_left ?_
  intro k hk
  have hk32 : k < 32 := List.mem_range.mp hk
  rw [hgates, hrun k hk32]
  show (!(a.getLsbD k)) = _
  rw [BitVec.getLsbD_not]
  simp [hk32]

/-! ## TASK 1 — `sem_pcNext` -/

theorem pcNe_eq : pcNe = 159 := by decide +kernel
theorem pcEq_eq : pcEq = 160 := by decide +kernel
theorem pcTake_eq : pcTake = 161 := by decide +kernel
theorem pcNotTake_eq : pcNotTake = 162 := by decide +kernel
theorem pcMuxBase_eq : pcMuxBase = 163 := by decide +kernel

/-- The addend output nets, as a `Nat`-valued function `omega` can read. -/
def pcOut (k : Nat) : Nat := if k < 2 then 163 + k else if k = 2 then 166 else 164 + k

theorem pcAddendOut_eq (k : Nat) : pcAddendOut k = pcOut k := by
  simp only [pcAddendOut, pcMuxBase_eq, pcOut, beq_iff_eq]
  split_ifs
  · rfl
  · rfl
  · show (163 : Nat) + k + 1 = 164 + k
    omega

/-! ### The OR chain -/

theorem orChain_nil (b : Nat) : orChain b ([] : List Net) = ([], 0, b) := by
  conv_lhs => rw [orChain]

theorem orChain_one (b : Nat) (x : Net) : orChain b [x] = ([], x, b) := by
  conv_lhs => rw [orChain]

theorem orChain_cons2 (b : Nat) (x y : Net) (r : List Net) :
    orChain b (x :: y :: r)
      = (⟨b, .or x y⟩ :: (orChain (b + 1) (b :: r)).1,
         (orChain (b + 1) (b :: r)).2.1, (orChain (b + 1) (b :: r)).2.2) := by
  conv_lhs => rw [orChain]

theorem orChain_out_ge : ∀ (fuel : Nat) (ns : List Net) (b : Nat), ns.length ≤ fuel →
    ∀ g ∈ (orChain b ns).1, b ≤ g.out := by
  intro fuel
  induction fuel with
  | zero =>
    intro ns b h g hg
    rw [List.eq_nil_of_length_eq_zero (Nat.le_zero.mp h), orChain_nil] at hg
    exact absurd hg (List.not_mem_nil)
  | succ f ih =>
    intro ns b h g hg
    match ns with
    | [] => rw [orChain_nil] at hg; exact absurd hg (List.not_mem_nil)
    | [x] => rw [orChain_one] at hg; exact absurd hg (List.not_mem_nil)
    | x :: y :: r =>
      rw [orChain_cons2] at hg
      simp only [List.mem_cons] at hg
      rcases hg with rfl | hg
      · exact Nat.le_refl b
      · have hlen : (b :: r).length ≤ f := by
          simp only [List.length_cons] at h ⊢
          omega
        exact Nat.le_of_succ_le (ih (b :: r) (b + 1) hlen g hg)

theorem run_orChain_frame (fuel : Nat) (E : Env) (ns : List Net) (b : Nat)
    (h : ns.length ≤ fuel) (m : Nat) (hm : m < b) : run E (orChain b ns).1 m = E m :=
  run_of_unwritten E _ m (fun g hg =>
    Nat.ne_of_gt (Nat.lt_of_lt_of_le hm (orChain_out_ge fuel ns b h g hg)))

theorem run_orChain : ∀ (fuel : Nat) (E : Env) (ns : List Net) (b : Nat),
    ns.length ≤ fuel → ns ≠ [] → (∀ m ∈ ns, m < b) →
    run E (orChain b ns).1 ((orChain b ns).2.1) = ns.any E := by
  intro fuel
  induction fuel with
  | zero =>
    intro E ns b h hne _
    exact absurd (List.eq_nil_of_length_eq_zero (Nat.le_zero.mp h)) hne
  | succ f ih =>
    intro E ns b h hne hlt
    match ns with
    | [] => exact absurd rfl hne
    | [x] =>
      rw [orChain_one]
      simp
    | x :: y :: r =>
      rw [orChain_cons2]
      show run (upd E b ((Op.or x y).eval E)) (orChain (b + 1) (b :: r)).1
          ((orChain (b + 1) (b :: r)).2.1) = _
      have hlen : (b :: r).length ≤ f := by
        simp only [List.length_cons] at h ⊢
        omega
      have hlt' : ∀ m ∈ (b :: r), m < b + 1 := by
        intro m hm
        rcases List.mem_cons.mp hm with rfl | hm
        · exact Nat.lt_succ_self m
        · exact Nat.lt_succ_of_lt (hlt m (by simp [hm]))
      rw [ih (upd E b ((Op.or x y).eval E)) (b :: r) (b + 1) hlen (by simp) hlt']
      rw [List.any_cons, List.any_cons, List.any_cons, upd_self,
        any_congr_mem (l := r) (p := upd E b ((Op.or x y).eval E)) (q := E)
          (fun m hm => upd_of_ne _ (Nat.ne_of_lt (hlt m (by simp [hm]))))]
      show ((E x || E y) || r.any E) = (E x || (E y || r.any E))
      exact Bool.or_assoc (E x) (E y) (r.any E)

/-! ### The three stages -/

theorem run_pcDiffGates (E : Env) :
    (∀ m : Nat, m < 97 → run E pcDiffGates m = E m)
    ∧ (∀ k : Nat, k < 32 → run E pcDiffGates (97 + k) = (E k ^^ E (32 + k))) := by
  have hgates : pcDiffGates
      = (List.range 32).map (fun i => (⟨97 + i, Op.xor i (32 + i)⟩ : Gate)) := rfl
  obtain ⟨hfr, hval⟩ := run_pointwise E 97 (fun i => Op.xor i (32 + i)) 32
    (fun i hi c hc => by
      simp only [Op.fanin, List.mem_cons, List.not_mem_nil, or_false] at hc
      rcases hc with rfl | rfl
      · exact Nat.lt_of_lt_of_le hi (by norm_num)
      · exact Nat.lt_of_lt_of_le (Nat.add_lt_add_left hi 32) (by norm_num))
  exact ⟨fun m hm => by rw [hgates]; exact hfr m hm,
         fun k hk => by rw [hgates]; exact hval k hk⟩

theorem run_pcNeGates (E : Env) :
    (∀ m : Nat, m < 129 → run E pcNeGates.1 m = E m)
    ∧ run E pcNeGates.1 159 = (List.range 32).any (fun k => E (97 + k)) := by
  have hgs : pcNeGates.1 = (orChain 129 ((List.range 32).map (fun k => (97 + k : Net)))).1 := rfl
  have hout : (orChain 129 ((List.range 32).map (fun k => (97 + k : Net)))).2.1 = 159 := by
    decide +kernel
  have hlen : ((List.range 32).map (fun k => (97 + k : Net))).length ≤ 32 := by simp
  have hne : ((List.range 32).map (fun k => (97 + k : Net))) ≠ [] := by
    intro hc
    have hl := congrArg List.length hc
    simp at hl
  have hlt : ∀ m ∈ ((List.range 32).map (fun k => (97 + k : Net))), m < 129 := by
    intro m hm
    simp only [List.mem_map, List.mem_range] at hm
    obtain ⟨k, hk, hkm⟩ := hm
    exact hkm ▸ Nat.lt_of_lt_of_le (Nat.add_lt_add_left hk 97) (by norm_num)
  refine ⟨fun m hm => by rw [hgs]; exact run_orChain_frame 32 E _ 129 hlen m hm, ?_⟩
  rw [hgs, ← hout, run_orChain 32 E _ 129 hlen hne hlt]
  simp [List.any_map, Function.comp_def]

abbrev pcCtrlGates : List Gate :=
  [(⟨160, .not 159⟩ : Gate), ⟨161, .and 96 160⟩, ⟨162, .not 161⟩]

theorem run_pcCtrl_161 (E : Env) : run E pcCtrlGates 161 = (E 96 && !(E 159)) := by
  simp [run_cons, run_nil, Op.eval, upd]

theorem run_pcCtrl_162 (E : Env) : run E pcCtrlGates 162 = !(E 96 && !(E 159)) := by
  simp [run_cons, run_nil, Op.eval, upd]

theorem run_pcCtrl_frame (E : Env) (m : Nat) (h : m < 160) : run E pcCtrlGates m = E m :=
  run_of_unwritten E pcCtrlGates m (by
    intro g hg
    have hge : (160 : Nat) ≤ g.out := by
      simp only [pcCtrlGates, List.mem_cons, List.not_mem_nil, or_false] at hg
      rcases hg with rfl | rfl | rfl <;> norm_num
    exact Nat.ne_of_gt (Nat.lt_of_lt_of_le h hge))

/-! ### The addend block -/

def pcAddGates (n : Nat) : List Gate := (List.range n).flatMap pcAddendGates

theorem pcAddGates_succ (n : Nat) : pcAddGates (n + 1) = pcAddGates n ++ pcAddendGates n := by
  simp [pcAddGates, List.range_succ]

theorem pcAddendGates_two :
    pcAddendGates 2 = [(⟨165, .and 161 66⟩ : Gate), ⟨166, .or 162 165⟩] := by decide +kernel

theorem pcAddendGates_ne {k : Nat} (h : k ≠ 2) :
    pcAddendGates k = [(⟨pcOut k, .and 161 (64 + k)⟩ : Gate)] := by
  unfold pcAddendGates
  rw [if_neg (by simpa using h), pcTake_eq, pcAddendOut_eq]
  rfl

theorem pcAddendGates_out_ge (n : Nat) : ∀ g ∈ pcAddendGates n, 163 ≤ g.out := by
  intro g hg
  by_cases h2 : n = 2
  · subst h2
    rw [pcAddendGates_two] at hg
    simp only [List.mem_cons, List.not_mem_nil, or_false] at hg
    rcases hg with rfl | rfl <;> norm_num
  · rw [pcAddendGates_ne h2] at hg
    simp only [List.mem_cons, List.not_mem_nil, or_false] at hg
    subst hg
    show (163 : Nat) ≤ pcOut n
    unfold pcOut
    split_ifs <;> omega

theorem pcAddendGates_out_ne {k n : Nat} (h : k < n) :
    ∀ g ∈ pcAddendGates n, g.out ≠ pcOut k := by
  intro g hg
  by_cases h2 : n = 2
  · subst h2
    rw [pcAddendGates_two] at hg
    simp only [List.mem_cons, List.not_mem_nil, or_false] at hg
    have hp : pcOut k = 163 + k := by unfold pcOut; rw [if_pos h]
    rcases hg with rfl | rfl
    · show (165 : Nat) ≠ pcOut k
      rw [hp]; omega
    · show (166 : Nat) ≠ pcOut k
      rw [hp]; omega
  · rw [pcAddendGates_ne h2] at hg
    simp only [List.mem_cons, List.not_mem_nil, or_false] at hg
    subst hg
    show pcOut n ≠ pcOut k
    unfold pcOut
    split_ifs <;> omega

theorem run_pcAddGates (E : Env) : ∀ n : Nat, n ≤ 32 →
    (∀ m : Nat, m < 163 → run E (pcAddGates n) m = E m)
    ∧ (∀ k : Nat, k < n → run E (pcAddGates n) (pcOut k)
        = if k = 2 then (E 162 || (E 161 && E 66)) else (E 161 && E (64 + k))) := by
  intro n
  induction n with
  | zero =>
    intro _
    exact ⟨fun m _ => rfl, fun k hk => absurd hk (Nat.not_lt_zero k)⟩
  | succ n ih =>
    intro hn
    obtain ⟨hfr, hval⟩ := ih (Nat.le_of_succ_le hn)
    have hn32 : n < 32 := Nat.lt_of_lt_of_le (Nat.lt_succ_self n) hn
    refine ⟨?_, ?_⟩
    · intro m hm
      rw [pcAddGates_succ, run_append,
        run_of_unwritten _ _ m (fun g hg =>
          Nat.ne_of_gt (Nat.lt_of_lt_of_le hm (pcAddendGates_out_ge n g hg)))]
      exact hfr m hm
    · intro k hk
      rw [pcAddGates_succ, run_append]
      rcases Nat.lt_or_ge k n with hkn | hkn
      · rw [run_of_unwritten _ _ (pcOut k) (pcAddendGates_out_ne hkn)]
        exact hval k hkn
      · have hkeq : k = n := Nat.le_antisymm (Nat.le_of_lt_succ hk) hkn
        subst hkeq
        by_cases h2 : k = 2
        · subst h2
          rw [pcAddendGates_two, if_pos rfl, show pcOut 2 = 166 from rfl,
            show run (run E (pcAddGates 2))
                [(⟨165, .and 161 66⟩ : Gate), ⟨166, .or 162 165⟩] 166
              = ((run E (pcAddGates 2)) 162
                  || ((run E (pcAddGates 2)) 161 && (run E (pcAddGates 2)) 66)) by
              simp [run_cons, run_nil, Op.eval, upd],
            hfr 162 (by norm_num), hfr 161 (by norm_num), hfr 66 (by norm_num)]
        · rw [pcAddendGates_ne h2, if_neg h2,
            show run (run E (pcAddGates k)) [(⟨pcOut k, .and 161 (64 + k)⟩ : Gate)] (pcOut k)
              = ((run E (pcAddGates k)) 161 && (run E (pcAddGates k)) (64 + k)) by
              simp [run_cons, run_nil, Op.eval, upd],
            hfr 161 (by norm_num),
            hfr (64 + k) (Nat.lt_of_lt_of_le (Nat.add_lt_add_left hn32 64) (by norm_num))]

/-! ### The whole block, over an arbitrary valuation -/

/-- The `take` signal, as a function of the input valuation. -/
def takeOf (E : Env) : Bool := E 96 && !((List.range 32).any (fun k => E k ^^ E (32 + k)))

theorem pcNext_gates_eq : pcNext.gates
    = pcDiffGates ++ (pcNeGates.1 ++ (pcCtrlGates ++ pcAddGates 32)) := by decide +kernel

theorem pcNext_outs_eq : pcNext.outs = (List.range 32).map pcAddendOut ++ [161] := by
  decide +kernel

theorem run_pcNext (E : Env) :
    (∀ k : Nat, k < 32 → run E pcNext.gates (pcOut k)
        = if k = 2 then (!(takeOf E) || (takeOf E && E 66)) else (takeOf E && E (64 + k)))
      ∧ run E pcNext.gates 161 = takeOf E := by
  obtain ⟨hf1, hv1⟩ := run_pcDiffGates E
  obtain ⟨hf2, hv2⟩ := run_pcNeGates (run E pcDiffGates)
  obtain ⟨hf4, hv4⟩ :=
    run_pcAddGates (run (run (run E pcDiffGates) pcNeGates.1) pcCtrlGates) 32 le_rfl
  have hE96 : run (run E pcDiffGates) pcNeGates.1 96 = E 96 := by
    rw [hf2 96 (by norm_num), hf1 96 (by norm_num)]
  have hE159 : run (run E pcDiffGates) pcNeGates.1 159
      = (List.range 32).any (fun k => E k ^^ E (32 + k)) := by
    rw [hv2]
    exact any_congr_mem (fun k hk => hv1 k (List.mem_range.mp hk))
  have hC161 : run (run (run E pcDiffGates) pcNeGates.1) pcCtrlGates 161 = takeOf E := by
    rw [run_pcCtrl_161, hE96, hE159]
    rfl
  have hC162 : run (run (run E pcDiffGates) pcNeGates.1) pcCtrlGates 162 = !(takeOf E) := by
    rw [run_pcCtrl_162, hE96, hE159]
    rfl
  have hClow : ∀ m : Nat, m < 96 →
      run (run (run E pcDiffGates) pcNeGates.1) pcCtrlGates m = E m := by
    intro m hm
    rw [run_pcCtrl_frame _ m (by omega), hf2 m (by omega), hf1 m (by omega)]
  have hgates : ∀ m : Nat, run E pcNext.gates m
      = run (run (run (run E pcDiffGates) pcNeGates.1) pcCtrlGates) (pcAddGates 32) m := by
    intro m
    rw [pcNext_gates_eq, run_append, run_append, run_append]
  refine ⟨?_, ?_⟩
  · intro k hk
    rw [hgates, hv4 k hk, hC161, hC162, hClow 66 (by norm_num),
      hClow (64 + k) (Nat.add_lt_add_left hk 64)]
  · rw [hgates, hf4 161 (by norm_num), hC161]

/-! ### The driver, and the theorem -/

def pcEnvOf (rs1 rs2 off : Word) (isBEQ : Bool) : Env :=
  fun i => if i < 32 then rs1.getLsbD i
           else if i < 64 then rs2.getLsbD (i - 32)
           else if i < 96 then off.getLsbD (i - 64) else isBEQ

theorem pcRun_eq (rs1 rs2 off : Word) (isBEQ : Bool) :
    pcRun rs1 rs2 off isBEQ = sem pcNext (pcEnvOf rs1 rs2 off isBEQ) := rfl

theorem pcEnvOf_rs1 (rs1 rs2 off : Word) (isBEQ : Bool) (k : Nat) (h : k < 32) :
    pcEnvOf rs1 rs2 off isBEQ k = rs1.getLsbD k := by
  show (if k < 32 then rs1.getLsbD k else _) = _
  rw [if_pos h]

theorem pcEnvOf_rs2 (rs1 rs2 off : Word) (isBEQ : Bool) (k : Nat) (h : k < 32) :
    pcEnvOf rs1 rs2 off isBEQ (32 + k) = rs2.getLsbD k := by
  show (if 32 + k < 32 then rs1.getLsbD (32 + k)
        else if 32 + k < 64 then rs2.getLsbD (32 + k - 32)
        else if 32 + k < 96 then off.getLsbD (32 + k - 64) else isBEQ) = _
  rw [if_neg (Nat.not_lt.mpr (Nat.le_add_right 32 k)),
    if_pos (Nat.add_lt_add_left h 32), Nat.add_sub_cancel_left]

theorem pcEnvOf_off (rs1 rs2 off : Word) (isBEQ : Bool) (k : Nat) (h : k < 32) :
    pcEnvOf rs1 rs2 off isBEQ (64 + k) = off.getLsbD k := by
  show (if 64 + k < 32 then rs1.getLsbD (64 + k)
        else if 64 + k < 64 then rs2.getLsbD (64 + k - 32)
        else if 64 + k < 96 then off.getLsbD (64 + k - 64) else isBEQ) = _
  rw [if_neg (by omega), if_neg (by omega), if_pos (by omega)]
  congr 1
  omega

theorem pcEnvOf_66 (rs1 rs2 off : Word) (isBEQ : Bool) :
    pcEnvOf rs1 rs2 off isBEQ 66 = off.getLsbD 2 :=
  pcEnvOf_off rs1 rs2 off isBEQ 2 (by norm_num)

theorem pcEnvOf_96 (rs1 rs2 off : Word) (isBEQ : Bool) :
    pcEnvOf rs1 rs2 off isBEQ 96 = isBEQ := by
  show (if (96 : Nat) < 32 then rs1.getLsbD 96
        else if (96 : Nat) < 64 then rs2.getLsbD (96 - 32)
        else if (96 : Nat) < 96 then off.getLsbD (96 - 64) else isBEQ) = _
  norm_num

theorem any_range_xor (a b : Word) :
    (List.range 32).any (fun k => a.getLsbD k ^^ b.getLsbD k) = !(a == b) := by
  rcases eq_or_ne a b with rfl | hne
  · simp
  · have hex : ∃ k, k < 32 ∧ a.getLsbD k ≠ b.getLsbD k := by
      by_contra hc
      refine hne (BitVec.eq_of_getLsbD_eq (fun k hk => ?_))
      by_contra hd
      exact hc ⟨k, hk, hd⟩
    obtain ⟨k, hk, hne2⟩ := hex
    have hany : (List.range 32).any (fun k => a.getLsbD k ^^ b.getLsbD k) = true := by
      rw [List.any_eq_true]
      refine ⟨k, List.mem_range.mpr hk, ?_⟩
      cases h1 : a.getLsbD k <;> cases h2 : b.getLsbD k <;> simp_all
    rw [hany]
    simp [hne]

theorem takeOf_pcEnvOf (rs1 rs2 off : Word) (isBEQ : Bool) :
    takeOf (pcEnvOf rs1 rs2 off isBEQ) = (isBEQ && (rs1 == rs2)) := by
  unfold takeOf
  rw [pcEnvOf_96,
    any_congr_mem (l := List.range 32)
      (p := fun k => pcEnvOf rs1 rs2 off isBEQ k ^^ pcEnvOf rs1 rs2 off isBEQ (32 + k))
      (q := fun k => rs1.getLsbD k ^^ rs2.getLsbD k)
      (fun k hk => by
        rw [pcEnvOf_rs1 _ _ _ _ k (List.mem_range.mp hk),
          pcEnvOf_rs2 _ _ _ _ k (List.mem_range.mp hk)]),
    any_range_xor, Bool.not_not]

theorem four_getLsbD (k : Nat) : (4 : Word).getLsbD k = decide (k = 2) := by
  match k with
  | 0 => decide
  | 1 => decide
  | 2 => decide
  | (n + 3) =>
      have h4 : (4 : Nat) < 2 ^ (n + 3) := by
        calc (4 : Nat) < 2 ^ 3 := by norm_num
        _ ≤ 2 ^ (n + 3) := Nat.pow_le_pow_right (by norm_num) (by omega)
      have ht : (4 : Word).toNat = 4 := by decide
      show Nat.testBit (4 : Word).toNat (n + 3) = _
      rw [ht, Nat.testBit_lt_two_pow h4]
      simp

/-- ⭐⭐ **THE PC ADDEND SELECT AGREES WITH `stepT`'s PC RULE, ON ALL 2^97
INPUTS.** -/
theorem sem_pcNext (rs1 rs2 off : Word) (isBEQ : Bool) :
    pcRun rs1 rs2 off isBEQ = pcSpec rs1 rs2 off isBEQ := by
  obtain ⟨hout, htake⟩ := run_pcNext (pcEnvOf rs1 rs2 off isBEQ)
  have hsem : sem pcNext (pcEnvOf rs1 rs2 off isBEQ)
      = (List.range 32).map
            (fun k => run (pcEnvOf rs1 rs2 off isBEQ) pcNext.gates (pcOut k))
          ++ [run (pcEnvOf rs1 rs2 off isBEQ) pcNext.gates 161] := by
    show (pcNext.outs).map (run (pcEnvOf rs1 rs2 off isBEQ) pcNext.gates) = _
    rw [pcNext_outs_eq, List.map_append, List.map_map]
    simp only [Function.comp_def, pcAddendOut_eq]
    rfl
  rw [pcRun_eq, hsem, htake, takeOf_pcEnvOf]
  show _ = (List.range 32).map
      (fun k => if (isBEQ && (rs1 == rs2)) then off.getLsbD k else (4 : Word).getLsbD k)
      ++ [isBEQ && (rs1 == rs2)]
  congr 1
  refine List.map_congr_left ?_
  intro k hk
  have hk32 : k < 32 := List.mem_range.mp hk
  rw [hout k hk32, takeOf_pcEnvOf, four_getLsbD, pcEnvOf_66,
    pcEnvOf_off _ _ _ _ k hk32]
  by_cases h2 : k = 2
  · subst h2
    cases hb : (isBEQ && (rs1 == rs2))
    · simp
    · simp
  · cases hb : (isBEQ && (rs1 == rs2))
    · simp [h2]
    · simp [h2]

/-! ### NON-VACUITY — task 1 -/

/-- ⛔ ONE GATE MUTATED: difference bit 5 is tied to `false`. -/
def pcDiffGatesCut : List Gate :=
  (List.range 32).map fun k =>
    ⟨pcDiff k, if k == 5 then .const false else .xor (pcRs1 k) (pcRs2 k)⟩

def pcNextCut : Circ :=
  { pcNext with
    gates := pcDiffGatesCut ++ pcNeGates.1
               ++ [ ⟨pcEq, .not pcNe⟩
                  , ⟨pcTake, .and pcIsBEQ pcEq⟩
                  , ⟨pcNotTake, .not pcTake⟩ ]
               ++ (List.range 32).flatMap pcAddendGates }

theorem pcNextCut_ssa : pcNextCut.ssa = true := by decide +kernel
theorem pcNextCut_gate_count : pcNextCut.gates.length = 99 := by decide +kernel

def pcOKCut : Bool :=
  pcCases.all fun p => pcOffs.all fun o => [false, true].all fun b =>
    sem pcNextCut (pcEnvOf p.1 p.2 o b) == pcSpec p.1 p.2 o b

theorem pcNextCut_passes_the_certificate : pcOKCut = true := by decide +kernel

theorem pcNextCut_fails_the_theorem :
    sem pcNextCut (pcEnvOf 0x20 0 8 true) ≠ pcSpec 0x20 0 8 true := by decide +kernel

theorem sem_pcNext_off_the_sample :
    ((0x20 : Word), (0 : Word)) ∉ pcCases
      ∧ ((0x0F0F0F0F : Word), (0x0F0F0F0F : Word)) ∉ pcCases
      ∧ (0x12345678 : Word) ∉ pcOffs
      ∧ pcRun 0x20 0 8 true = pcSpec 0x20 0 8 true
      ∧ pcRun 0x0F0F0F0F 0x0F0F0F0F 0x12345678 true
          = pcSpec 0x0F0F0F0F 0x0F0F0F0F 0x12345678 true :=
  ⟨by decide +kernel, by decide +kernel, by decide +kernel,
   sem_pcNext _ _ _ _, sem_pcNext _ _ _ _⟩

/-! ### NON-VACUITY — task 2 -/

def bitAnd32Cut : Circ :=
  { nIn := 64
    gates := (List.range 32).map fun k =>
      ⟨64 + k, if k == 7 then .or k (32 + k) else .and k (32 + k)⟩
    outs := (List.range 32).map (fun k => 64 + k) }

theorem bitAnd32Cut_ssa : bitAnd32Cut.ssa = true := by decide +kernel

theorem bitAnd32Cut_fails_the_theorem :
    sem bitAnd32Cut (bwEnv 0xFFFFFFFF 0x00000000)
      ≠ (List.range 32).map (fun k => ((0xFFFFFFFF : Word) &&& 0x00000000).getLsbD k) := by
  decide +kernel

theorem sem_bitAnd32_off_the_sample :
    (0x0F0F0F0F : Word) ∉ bwWords ∧ (0x33333333 : Word) ∉ bwWords
      ∧ sem bitAnd32 (bwEnv 0x0F0F0F0F 0x33333333)
          = (List.range 32).map (fun k => ((0x0F0F0F0F : Word) &&& 0x33333333).getLsbD k)
      ∧ sem bitOr32 (bwEnv 0x0F0F0F0F 0x33333333)
          = (List.range 32).map (fun k => ((0x0F0F0F0F : Word) ||| 0x33333333).getLsbD k)
      ∧ sem bitNot32 (fun i => (0x0F0F0F0F : Word).getLsbD i)
          = (List.range 32).map (fun k => (~~~(0x0F0F0F0F : Word)).getLsbD k) :=
  ⟨by decide +kernel, by decide +kernel, sem_bitAnd32 _ _, sem_bitOr32 _ _, sem_bitNot32 _⟩

/-! ### ⭐ THE ISA SIDE — the pc field, through the block

*The block emits the ADDEND, so the bridge is `s.pc + <what the block computes>`
rather than an equality with the block's output. All three branches of `stepT`'s
pc rule are covered: the taken branch, a representative non-branch, and the
NOP-advance on an undecodable word.*
-/

theorem pcSpec_eq (rs1 rs2 off : Word) (isBEQ : Bool) :
    SaltWorks.HDL.pcSpec rs1 rs2 off isBEQ
      = (List.range 32).map (fun k =>
          if (isBEQ && (rs1 == rs2)) = true then off.getLsbD k else (4 : Word).getLsbD k)
        ++ [isBEQ && (rs1 == rs2)] := rfl

/-- ⭐ **THE ADDEND, AS A WORD.** -/
theorem pcAddend_word (rs1 rs2 off : Word) (isBEQ : Bool) :
    SaltWorks.HDL.wordOf (fun k => (SaltWorks.HDL.pcRun rs1 rs2 off isBEQ).getD k false)
      = if (isBEQ && (rs1 == rs2)) = true then off else 4 := by
  rw [sem_pcNext, pcSpec_eq, wordOf_getD_range_append]
  by_cases hb : (isBEQ && (rs1 == rs2)) = true
  · simp only [if_pos hb]
    exact wordOf_getLsbD_self off
  · simp only [if_neg hb]
    exact wordOf_getLsbD_self 4

/-- ⭐⭐ **THE TAKEN/NOT-TAKEN BRANCH, THROUGH THE BLOCK.** -/
theorem pcField_is_pcNext_beq (s : St) (x y : Fin 32) (imm : BitVec 12) :
    (stepT (SaltWorks.HDL.decQ (envWith s (encode (Instr.BEQ x y imm))))
           (seenWord (envWith s (encode (Instr.BEQ x y imm))))).pc
      = s.pc + SaltWorks.HDL.wordOf (fun k =>
          (SaltWorks.HDL.pcRun (s.get x) (s.get y) (bOffset imm) true).getD k false) := by
  rw [decQ_envWith_eq, seenWord_envWith, stepT_encode, pcAddend_word]
  try simp only [step_regs_of_with_of_not_touchesMem, SaltWorks.ISA.touchesMem]
  try simp only [step_pc_of_with]
  show (if s.get x = s.get y then { s with pc := s.pc + bOffset imm } else s.next).pc = _
  by_cases h : s.get x = s.get y
  · rw [if_pos h, if_pos (by simp [h])]
  · rw [if_neg h, if_neg (by simp [h])]
    rfl

/-- ⭐ **AND EVERY NON-BRANCH ADDS 4** — the block driven with `isBEQ = false`. -/
theorem pcField_is_pcNext_add (s : St) (rd x y : Fin 32) :
    (stepT (SaltWorks.HDL.decQ (envWith s (encode (Instr.ADD rd x y))))
           (seenWord (envWith s (encode (Instr.ADD rd x y))))).pc
      = s.pc + SaltWorks.HDL.wordOf (fun k =>
          (SaltWorks.HDL.pcRun (s.get x) (s.get y) 0 false).getD k false) := by
  rw [decQ_envWith_eq, seenWord_envWith, stepT_encode, pcAddend_word, if_neg (by simp)]
  try simp only [step_regs_of_with_of_not_touchesMem, SaltWorks.ISA.touchesMem]
  try simp only [step_pc_of_with]
  show ((s.set rd (s.get x + s.get y)).next).pc = _
  show (s.set rd (s.get x + s.get y)).pc + 4 = _
  rw [set_pc]

/-- ⭐ **INCLUDING THE UNDECODABLE WORDS** — `stepT`'s NOP-advance path. -/
theorem pcField_is_pcNext_undecodable (s : St) (w : Word) (h : decode w = none) :
    (stepT s w).pc
      = s.pc + SaltWorks.HDL.wordOf (fun k =>
          (SaltWorks.HDL.pcRun 0 0 0 false).getD k false) := by
  rw [stepT_undecodable s w h, pcAddend_word, if_neg (by simp)]
  rfl

/-! ## ⭐⭐ PCADD — THE PC INCREMENT, RESTORED BY COMPOSITION

⛔ **THE DEFECT THIS SECTION EXISTS TO FIX, AND IT WAS REFUTED AT THE BYTES**
(`cefd93e` / `625009b`). `pcNext` emits the **addend** and the take flag —
`PcNext.lean:27` says so: *"Emitting the addend and leaving the addition to the
assembly."* **The assembly is `core`, and `core` does not exist.** So on the plan
as it stood nothing added, and reading `pcNext`'s output *as* the next pc sets
`pc := 4` every cycle. **That is now a theorem, not a memo**
(`addend_read_as_pc_is_four`, `addend_as_pc_is_wrong_unless_pc_zero`,
`the_defect_and_the_fix`) — the same service `offset_six_does_not_sort` performs
for the branch immediate. *A bug that is a theorem cannot be re-introduced
quietly.*

## ⭐ THE FIX IS COMPOSITION, AND THE DESIGN'S OWN OBJECTION HAS EXPIRED

`PcNext.lean:23-28` gave the reason for the addend-select verbatim: *"The landed
`adder32` would have to be instantiated to be reused here, and instantiation's
semantics theorem is **owed, not proved**."* **Both premises are now false**:
`inst_sem` is proved (`Compose.lean:397`) and `sem_adder32` holds
unconditionally over all 2^64 operand pairs.

⇒ ⭐ **THIS IS THE THIRD `adder32` THE ASSEMBLY PLAN ASKS FOR**
(`hdl-c4-core-assembly-plan-0807.md:168-171`) — the same silicon, reached by
instantiating the proved block instead of standing up a new one. **`inc32` is not
it and was not resurrected**: `Adder.lean:115` gives it 32 inputs and no addend
port, so it cannot do the branch case.

⚠️ **AND THE REUSE IS AT THE DEFINITION LEVEL, NOT THE GATE LEVEL — measured,
because the opposite reading moves a number.** `instGates` maps *every* gate into
the host, so **the carry chain IS duplicated in the netlist**: `pcAdd` is 260
gates and 160 of them are the adder instance. *`pcAdd_gate_count` is the kernel's
confirmation of the `+160` that `docs/silicon-refute-pcpath-0807.md` §6.1(b)
derived from `instGates`/`instNext`.* **What is not duplicated is the SOURCE:
one `adder32`, one `sem_adder32`, no second copy that can drift — which is
exactly what `PcNext.lean:28` feared, and it is the whole saving.**

📌 **AND THE SHAPE SILICON PRICED AS "a bigger change than it looks" IS REACHED
WITHOUT MAKING IT.** §3 of that refutation put the alternative as *"`pcNext`
needs the pc among its inputs … `pcIn` goes 97 → 129 and the block stops being
99 gates."* `pcAdd.nIn` **is** 129 — and `pcNext` is untouched, still 97 inputs,
still 99 gates. *The width moved to the composite; the block did not.*

```
host inputs   pc 0…31   rs1 32…63   rs2 64…95   off 96…127   isBEQ 128
net 129       ⟨const false⟩                    <- the adder's carry-in
nets 130…228  instGates pcNext  σ₁ = (32 + ·)  <- 99 gates, the addend + take
nets 229…388  instGates adder32 σ₂             <- 160 gates, a := pc, b := addend
outs          the 32 sum nets, 230 + 5k
```

**260 gates. `ssa` structurally, `wf` through `Circ.wf_of_ssa`** — the quadratic
`nodupB` is never walked.

## ⭐ WHAT `inst_sem` ACTUALLY ASKS FOR, AND WHERE EACH CLAUSE WAS PAID

*The brief flagged this as the likely failure mode, and it is the load-bearing
part of the node. Both hypotheses were satisfiable; neither was free.*

* **`instOK c σ off`** — `c.ssa`, `c.wf`, and ⭐ **`∀ i < c.nIn, σ i < off`**.
  The third clause is what makes the frame argument available at all, and it is
  why the host's inputs are laid out **pc first**: `σ₁ = (32 + ·)` is then a
  uniform shift and every wire lands below `130`. *A layout that interleaved the
  pc with `pcNext`'s ports would have satisfied nothing.*
* **`hin : ∀ a < c.nIn, envN (σ a) = envC a`** — the host environment, read
  through `σ`, agrees with what the block would see standalone. `hin_pcNext`
  discharges it for `pcNext` (one shift, four `if` branches).
* ⭐ **For the SECOND instance the hypothesis moves**: `inst_compose_sem` asks
  for agreement **after the first instance has run** —
  `run env (instGates c₁ σ₁ off) (σ₂ a) = envC₂ a`. `hin_adder` is that proof and
  it splits three ways, one per port group: the `a` port (the pc) needs the
  **frame** lemma — the `pcNext` instance must not have disturbed nets `0…31`;
  the `b` port needs **`inst_sem` on `pcNext` itself** — the addend nets read what
  `pcNext` computes; and the carry-in needs the frame again, at net `129`, which
  is below `130` for exactly the `instOK` reason.

⚠️ **THE `Net` TRAP WAS AT ITS WORST HERE, AS THE BRIEF PREDICTED, AND THE FIX
WAS STRUCTURAL RATHER THAN TACTICAL.** Instantiation renumbers nets, so every
wire in `σ₂` is an arithmetic expression in `pcOut`. **`addendNet : Nat → Nat`
is the `Nat` mirror** — `σ₂` is defined *through it*, and `instMap_pcOut` proves
once that the mirror is the real wire. Every bound below is then plain `Nat`
arithmetic. *`pcOut` did the same job for `sem_pcNext`; this is that lesson
applied one level up.*

## ⛔ `PcField` IS NOT CLOSED BY THIS

`PcField` is a statement about a whole `core`'s output bits `1024…1055`, and no
`core` exists. What lands here is **the block-level theorem plus the three
bridges a `core` assembly applies** — `pcField_is_pcAdd_beq` / `_add` /
`_undecodable`, the landed `pcField_is_pcNext_*` trio with the addition now
included, so the `s.pc + …` on their right-hand sides is gone. *The debt is
`core`, not the pc path.*
-/

/-! ### The layout -/

/-- Host inputs: `pc` on `0…31`, `rs1` on `32…63`, `rs2` on `64…95`,
`off` on `96…127`, `isBEQ` at `128`. -/
def pcAddIn : Nat := 129

/-- The constant-zero net — the adder's carry-in. **The one gate this composite
adds of its own**, and it is not decoration: `adder32.nIn = 65` and net `64` is a
real carry-in port, so something below the instance has to hold `false`. -/
def pcAddZero : Nat := 129

/-- `pcNext`'s 97 inputs are the host's, shifted past the pc. *A uniform shift
because the pc was put FIRST; see the section header.* -/
def pcSigma (i : Nat) : Nat := 32 + i

/-- Where the `pcNext` instance starts — one past the constant-zero gate. -/
def pcAddOff : Nat := 130

/-- ⭐ **The `Nat` mirror of the addend wire.** `pcAddendOut` is not contiguous
(bit 2 costs two gates), so this is `pcOut` shifted by the instantiation — and
`σ₂` is defined THROUGH it so that every bound below is `Nat` arithmetic. -/
def addendNet (k : Nat) : Nat := 130 + (pcOut k - 97)

/-- `adder32`'s wiring: `a` := the pc, `b` := `pcNext`'s addend, carry-in := 0. -/
def adSigma (i : Nat) : Nat :=
  if i < 32 then i else if i < 64 then addendNet (i - 32) else pcAddZero

/-- ⭐⭐ **THE COMPOSITE.** `pcNext`'s addend, added to the pc by an instantiated
`adder32`. -/
def pcAdd : Circ :=
  { nIn := pcAddIn
    gates := ⟨pcAddZero, .const false⟩
               :: (instGates pcNext pcSigma pcAddOff
                     ++ instGates adder32 adSigma (instNext pcNext pcAddOff))
    outs := (List.range 32).map
              (fun k => instMap adder32 adSigma (instNext pcNext pcAddOff) (adS k)) }

theorem pcAdd_ssa : pcAdd.ssa = true := by decide +kernel

/-- Through `Circ.wf_of_ssa`, not through `decide` — `wf`'s `nodupB` is O(n²). -/
theorem pcAdd_wf : pcAdd.wf = true := Circ.wf_of_ssa pcAdd_ssa

/-- **260 gates: 1 + 99 + 160.** Measured, then pinned. -/
theorem pcAdd_gate_count : pcAdd.gates.length = 260 := by decide +kernel

theorem pcAdd_adder_off : instNext pcNext pcAddOff = 229 := by decide +kernel

/-! ### The wiring facts -/

/-- **The mirror IS the wire.** Every addend net is internal to `pcNext`
(`pcOut k ≥ 163 > 97`), so `instMap` takes the shifted branch. -/
theorem instMap_pcOut (k : Nat) : instMap pcNext pcSigma pcAddOff (pcOut k) = addendNet k := by
  have h : ¬ (pcOut k < pcNext.nIn) := by
    show ¬ (pcOut k < 97)
    unfold pcOut
    split_ifs <;> omega
  rw [instMap_internal pcNext pcSigma pcAddOff (pcOut k) h]
  rfl

theorem addendNet_lt (k : Nat) (hk : k < 32) : addendNet k < 229 := by
  unfold addendNet pcOut
  split_ifs <;> omega

theorem adSigma_lt (i : Nat) (hi : i < 65) : adSigma i < 229 := by
  unfold adSigma pcAddZero
  split_ifs with h1 h2
  · omega
  · exact addendNet_lt (i - 32) (by omega)
  · omega

theorem instOK_pcNext : instOK pcNext pcSigma pcAddOff := by
  refine ⟨pcNext_ssa, pcNext_wf, ?_⟩
  intro i hi
  have hi' : i < 97 := hi
  show (32 + i : Nat) < 130
  omega

/-- ⭐ **The offset is the hypothesis, not a convenience** — the highest addend
wire is `228` and the adder sits at `229`, one net above it. -/
theorem instOK_adder : instOK adder32 adSigma (instNext pcNext pcAddOff) := by
  refine ⟨adder32_ssa, adder32_wf, ?_⟩
  intro i hi
  have hi' : i < 65 := hi
  show adSigma i < instNext pcNext pcAddOff
  rw [pcAdd_adder_off]
  exact adSigma_lt i hi'

theorem pcOut_mem_gates :
    ((List.range 32).all fun k => (pcNext.gates.map Gate.out).contains (pcOut k)) = true := by
  decide +kernel

theorem adS_mem_gates :
    ((List.range 32).all fun k => (adder32.gates.map Gate.out).contains (adS k)) = true := by
  decide +kernel

theorem pcOut_mem (k : Nat) (hk : k < 32) :
    (pcNext.gates.map Gate.out).contains (pcOut k) = true :=
  (List.all_eq_true.mp pcOut_mem_gates) k (List.mem_range.mpr hk)

theorem adS_mem (k : Nat) (hk : k < 32) :
    (adder32.gates.map Gate.out).contains (adS k) = true :=
  (List.all_eq_true.mp adS_mem_gates) k (List.mem_range.mpr hk)

/-! ### The environments -/

/-- The host valuation. `pcAddEnv … 129` is `isBEQ`, which is exactly why the
constant-zero gate exists rather than a convention. -/
def pcAddEnv (pc rs1 rs2 off : Word) (isBEQ : Bool) : Env :=
  fun i => if i < 32 then pc.getLsbD i
           else if i < 64 then rs1.getLsbD (i - 32)
           else if i < 96 then rs2.getLsbD (i - 64)
           else if i < 128 then off.getLsbD (i - 96)
           else isBEQ

/-- …after the constant-zero gate has run. -/
def pcAddEnv0 (pc rs1 rs2 off : Word) (isBEQ : Bool) : Env :=
  upd (pcAddEnv pc rs1 rs2 off isBEQ) pcAddZero false

theorem pcAddEnv_pc (pc rs1 rs2 off : Word) (isBEQ : Bool) (k : Nat) (h : k < 32) :
    pcAddEnv pc rs1 rs2 off isBEQ k = pc.getLsbD k := by
  show (if k < 32 then pc.getLsbD k else _) = _
  rw [if_pos h]

/-- ⭐ **The layout's whole payoff, in one lemma**: the host, shifted by 32, IS
`pcNext`'s own driver. -/
theorem pcAddEnv_shift (pc rs1 rs2 off : Word) (isBEQ : Bool) (a : Nat) (ha : a < 97) :
    pcAddEnv pc rs1 rs2 off isBEQ (32 + a) = pcEnvOf rs1 rs2 off isBEQ a := by
  show (if 32 + a < 32 then pc.getLsbD (32 + a)
        else if 32 + a < 64 then rs1.getLsbD (32 + a - 32)
        else if 32 + a < 96 then rs2.getLsbD (32 + a - 64)
        else if 32 + a < 128 then off.getLsbD (32 + a - 96) else isBEQ)
      = (if a < 32 then rs1.getLsbD a
         else if a < 64 then rs2.getLsbD (a - 32)
         else if a < 96 then off.getLsbD (a - 64) else isBEQ)
  rw [if_neg (by omega)]
  by_cases h1 : a < 32
  · rw [if_pos (by omega), if_pos h1]; congr 1; omega
  · rw [if_neg (by omega), if_neg h1]
    by_cases h2 : a < 64
    · rw [if_pos (by omega), if_pos h2]; congr 1; omega
    · rw [if_neg (by omega), if_neg h2]
      by_cases h3 : a < 96
      · rw [if_pos (by omega), if_pos h3]; congr 1; omega
      · rw [if_neg (by omega), if_neg h3]

theorem pcAddEnv0_low (pc rs1 rs2 off : Word) (isBEQ : Bool) (n : Nat) (h : n < 129) :
    pcAddEnv0 pc rs1 rs2 off isBEQ n = pcAddEnv pc rs1 rs2 off isBEQ n :=
  upd_of_ne _ (Nat.ne_of_lt h)

theorem pcAddEnv0_zero (pc rs1 rs2 off : Word) (isBEQ : Bool) :
    pcAddEnv0 pc rs1 rs2 off isBEQ pcAddZero = false := upd_self _ _ _

theorem adEnv_a (a b : Word) (cin : Bool) (k : Nat) (h : k < 32) :
    adEnv a b cin k = a.getLsbD k := by
  show (if k < 32 then a.getLsbD k else _) = _
  rw [if_pos h]

theorem adEnv_b (a b : Word) (cin : Bool) (k : Nat) (h1 : 32 ≤ k) (h2 : k < 64) :
    adEnv a b cin k = b.getLsbD (k - 32) := by
  show (if k < 32 then a.getLsbD k else if k < 64 then b.getLsbD (k - 32) else cin) = _
  rw [if_neg (by omega), if_pos h2]

theorem adEnv_cin (a b : Word) (cin : Bool) (k : Nat) (h : 64 ≤ k) :
    adEnv a b cin k = cin := by
  show (if k < 32 then a.getLsbD k else if k < 64 then b.getLsbD (k - 32) else cin) = _
  rw [if_neg (by omega), if_neg (by omega)]

/-! ### The addend, as a net-level fact

*`sem_pcNext` is a statement about `sem` — the output LIST. The composition needs
it one level lower, at the net the adder's `b` port is wired to. This reads it
back out of the landed theorem rather than re-deriving it: nothing about
`pcNext`'s internals is touched.* -/

def pcAddend (rs1 rs2 off : Word) (isBEQ : Bool) : Word :=
  if isBEQ && (rs1 == rs2) then off else 4

theorem run_pcNext_addend (rs1 rs2 off : Word) (isBEQ : Bool) (k : Nat) (hk : k < 32) :
    run (pcEnvOf rs1 rs2 off isBEQ) pcNext.gates (pcOut k)
      = (pcAddend rs1 rs2 off isBEQ).getLsbD k := by
  have h : (sem pcNext (pcEnvOf rs1 rs2 off isBEQ)).getD k false
      = run (pcEnvOf rs1 rs2 off isBEQ) pcNext.gates (pcOut k) := by
    show (pcNext.outs.map (run (pcEnvOf rs1 rs2 off isBEQ) pcNext.gates)).getD k false = _
    rw [pcNext_outs_eq, List.map_append, List.map_map]
    simp only [Function.comp_def, pcAddendOut_eq]
    exact getD_of_range_append _ _ k hk
  rw [← h, ← pcRun_eq, sem_pcNext, pcSpec_eq, getD_of_range_append _ _ k hk]
  unfold pcAddend
  by_cases hb : (isBEQ && (rs1 == rs2)) = true
  · rw [if_pos hb, if_pos hb]
  · rw [if_neg hb, if_neg hb]

/-! ### ⭐ THE WIRING HYPOTHESES — what `inst_sem` charged, and the payment -/

theorem hin_pcNext (pc rs1 rs2 off : Word) (isBEQ : Bool) :
    ∀ a, a < pcNext.nIn →
      pcAddEnv0 pc rs1 rs2 off isBEQ (pcSigma a) = pcEnvOf rs1 rs2 off isBEQ a := by
  intro a ha
  have ha' : a < 97 := ha
  show pcAddEnv0 pc rs1 rs2 off isBEQ (32 + a) = _
  rw [pcAddEnv0_low _ _ _ _ _ _ (by omega), pcAddEnv_shift _ _ _ _ _ a ha']

/-- ⭐⭐ **THE JOIN.** The adder's three port groups, each paid by a different
lemma: the `a` port by the FRAME (`pcNext`'s instance leaves nets `0…31` alone),
the `b` port by `inst_sem` **on `pcNext`** (the addend nets read what `pcNext`
computes), the carry-in by the frame again at net `129`. -/
theorem hin_adder (pc rs1 rs2 off : Word) (isBEQ : Bool) :
    ∀ a, a < adder32.nIn →
      run (pcAddEnv0 pc rs1 rs2 off isBEQ) (instGates pcNext pcSigma pcAddOff) (adSigma a)
        = adEnv pc (pcAddend rs1 rs2 off isBEQ) false a := by
  intro a ha
  have ha' : a < 65 := ha
  by_cases h1 : a < 32
  · have hs : adSigma a = a := by unfold adSigma; rw [if_pos h1]
    rw [hs, inst_frame_below pcNext pcSigma pcAddOff pcNext_ssa _ a (by show (a : Nat) < 130; omega),
      pcAddEnv0_low _ _ _ _ _ _ (by omega), pcAddEnv_pc _ _ _ _ _ _ h1, adEnv_a _ _ _ _ h1]
  · by_cases h2 : a < 64
    · have hs : adSigma a = instMap pcNext pcSigma pcAddOff (pcOut (a - 32)) := by
        rw [instMap_pcOut]; unfold adSigma; rw [if_neg h1, if_pos h2]
      rw [hs, inst_sem pcNext pcSigma pcAddOff _ (pcEnvOf rs1 rs2 off isBEQ) instOK_pcNext
            (hin_pcNext pc rs1 rs2 off isBEQ) (pcOut (a - 32))
            (Or.inr (pcOut_mem (a - 32) (by omega))),
        run_pcNext_addend _ _ _ _ (a - 32) (by omega), adEnv_b _ _ _ _ (by omega) h2]
    · have hs : adSigma a = pcAddZero := by unfold adSigma; rw [if_neg h1, if_neg h2]
      rw [hs, inst_frame_below pcNext pcSigma pcAddOff pcNext_ssa _ pcAddZero
            (by show (129 : Nat) < 130; omega),
        pcAddEnv0_zero, adEnv_cin _ _ _ _ (by omega)]

/-! ### The adder, per net

*`sem_adder32` is about the output LIST; the composite needs the sum net. Both
come from the same landed `run_adGates` invariant.* -/

theorem run_adder32_adS (a b : Word) (k : Nat) (hk : k < 32) :
    run (adEnv a b false) adder32.gates (adS k) = (a + b).getLsbD k := by
  have hg : adder32.gates = adGates 32 := rfl
  rw [hg, (run_adGates a b false 32 le_rfl).2.2 k hk, ← BitVec.getLsbD_add_add_bool hk a b false]
  simp

/-! ### ⭐⭐ THE COMPOSITE THEOREM -/

theorem pcAdd_gates_eq : pcAdd.gates
    = (⟨pcAddZero, .const false⟩ : Gate)
        :: (instGates pcNext pcSigma pcAddOff
              ++ instGates adder32 adSigma (instNext pcNext pcAddOff)) := rfl

/-- Peeling the constant-zero gate.

⚠️ **AND THE `rfl` HAS TO GO THROUGH `pcAdd_gates_eq` FIRST — MEASURED, NOT
STYLE.** Stating this as one `rfl` from `run E pcAdd.gates` to
`run E₀ (G₁ ++ G₂)` puts a cons on the left and an append on the right, the
argument-wise heuristic fails, and both sides get unfolded: **`(kernel)
deterministic timeout`**. Rewriting the gate list first makes the two `run`s
agree on their second argument syntactically, and the check is instant. -/
theorem run_pcAdd_peel (E : Env) :
    run E pcAdd.gates
      = run (upd E pcAddZero false)
          (instGates pcNext pcSigma pcAddOff
             ++ instGates adder32 adSigma (instNext pcNext pcAddOff)) := by
  rw [pcAdd_gates_eq, run_cons]
  rfl

theorem run_pcAdd_out (pc rs1 rs2 off : Word) (isBEQ : Bool) (k : Nat) (hk : k < 32) :
    run (pcAddEnv pc rs1 rs2 off isBEQ) pcAdd.gates
        (instMap adder32 adSigma (instNext pcNext pcAddOff) (adS k))
      = (pc + pcAddend rs1 rs2 off isBEQ).getLsbD k := by
  rw [run_pcAdd_peel, show upd (pcAddEnv pc rs1 rs2 off isBEQ) pcAddZero false
        = pcAddEnv0 pc rs1 rs2 off isBEQ from rfl,
    inst_compose_sem pcNext adder32 pcSigma adSigma pcAddOff instOK_adder
      (pcAddEnv0 pc rs1 rs2 off isBEQ) (adEnv pc (pcAddend rs1 rs2 off isBEQ) false)
      (hin_adder pc rs1 rs2 off isBEQ) (adS k) (Or.inr (adS_mem k hk))]
  exact run_adder32_adS pc (pcAddend rs1 rs2 off isBEQ) k hk

/-- ⭐⭐ **THE PC PATH COMPUTES `stepT`'s PC RULE, ON ALL 2^129 INPUTS.** BEQ with
`rs1 = rs2` gives `pc + bOffset imm`; everything else — including the
NOP-advance on an undecodable word — gives `pc + 4`. *No `decide`, no
`native_decide`, no sample.* -/
theorem sem_pcAdd (pc rs1 rs2 off : Word) (isBEQ : Bool) :
    sem pcAdd (pcAddEnv pc rs1 rs2 off isBEQ)
      = (List.range 32).map
          (fun k => (pc + (if isBEQ && (rs1 == rs2) then off else 4 : Word)).getLsbD k) := by
  show (pcAdd.outs.map (run (pcAddEnv pc rs1 rs2 off isBEQ) pcAdd.gates)) = _
  show (((List.range 32).map
      (fun k => instMap adder32 adSigma (instNext pcNext pcAddOff) (adS k))).map
        (run (pcAddEnv pc rs1 rs2 off isBEQ) pcAdd.gates)) = _
  rw [List.map_map]
  refine List.map_congr_left ?_
  intro k hk
  exact run_pcAdd_out pc rs1 rs2 off isBEQ k (List.mem_range.mp hk)

/-! ### ⭐ THE ISA SIDE — the pc field, through the composite

*The landed `pcField_is_pcNext_*` trio reads `s.pc + wordOf …` because the block
emitted an addend. **These three have no `s.pc +` on the right**: the addition is
inside the circuit now, which is the whole point of the node.* -/

theorem pcAdd_word (pc rs1 rs2 off : Word) (isBEQ : Bool) :
    wordOf (fun k => (sem pcAdd (pcAddEnv pc rs1 rs2 off isBEQ)).getD k false)
      = pc + (if isBEQ && (rs1 == rs2) then off else 4) := by
  rw [sem_pcAdd, wordOf_getD_map_range, wordOf_getLsbD_self]

/-- ⭐⭐ **THE TAKEN/NOT-TAKEN BRANCH, THROUGH THE COMPOSITE.** -/
theorem pcField_is_pcAdd_beq (s : St) (x y : Fin 32) (imm : BitVec 12) :
    (stepT (SaltWorks.HDL.decQ (envWith s (encode (Instr.BEQ x y imm))))
           (seenWord (envWith s (encode (Instr.BEQ x y imm))))).pc
      = wordOf (fun k =>
          (sem pcAdd (pcAddEnv s.pc (s.get x) (s.get y) (bOffset imm) true)).getD k false) := by
  rw [decQ_envWith_eq, seenWord_envWith, stepT_encode, pcAdd_word]
  try simp only [step_regs_of_with_of_not_touchesMem, SaltWorks.ISA.touchesMem]
  try simp only [step_pc_of_with]
  show (if s.get x = s.get y then { s with pc := s.pc + bOffset imm } else s.next).pc = _
  by_cases h : s.get x = s.get y
  · rw [if_pos h, if_pos (by simp [h])]
  · rw [if_neg h, if_neg (by simp [h])]
    rfl

/-- ⭐ **AND EVERY NON-BRANCH ADVANCES BY FOUR** — the composite driven with
`isBEQ = false`. -/
theorem pcField_is_pcAdd_add (s : St) (rd x y : Fin 32) :
    (stepT (SaltWorks.HDL.decQ (envWith s (encode (Instr.ADD rd x y))))
           (seenWord (envWith s (encode (Instr.ADD rd x y))))).pc
      = wordOf (fun k =>
          (sem pcAdd (pcAddEnv s.pc (s.get x) (s.get y) 0 false)).getD k false) := by
  rw [decQ_envWith_eq, seenWord_envWith, stepT_encode, pcAdd_word, if_neg (by simp)]
  try simp only [step_regs_of_with_of_not_touchesMem, SaltWorks.ISA.touchesMem]
  try simp only [step_pc_of_with]
  show ((s.set rd (s.get x + s.get y)).next).pc = _
  show (s.set rd (s.get x + s.get y)).pc + 4 = _
  rw [set_pc]

/-- ⭐ **INCLUDING THE UNDECODABLE WORDS** — `stepT`'s NOP-advance path, the
measured 99.61%. -/
theorem pcField_is_pcAdd_undecodable (s : St) (w : Word) (h : decode w = none) :
    (stepT s w).pc
      = wordOf (fun k => (sem pcAdd (pcAddEnv s.pc 0 0 0 false)).getD k false) := by
  rw [stepT_undecodable s w h, pcAdd_word, if_neg (by simp)]
  rfl

/-! ### ⛔⛔ THE DEFECT, AS A THEOREM

*The artifact that stops this being re-introduced. `offset_six_does_not_sort`
did it for the branch immediate; this does it for the pc path.* -/

/-- ⛔ **THE ADDEND IS `4` ON EVERY NON-BRANCH — AND IT DOES NOT MENTION THE
PC.** So a `core` that took `pcNext`'s output *as* its next pc would set
`pc := 4`, forever, whatever the pc was. -/
theorem addend_read_as_pc_is_four (rs1 rs2 off : Word) :
    wordOf (fun k => (SaltWorks.HDL.pcRun rs1 rs2 off false).getD k false) = 4 := by
  rw [pcAddend_word, if_neg (by simp)]

/-- ⛔⛔ **AND THAT IS WRONG AT EVERY PC BUT ZERO.** *The plan as it stood agreed
with `stepT` only on the first cycle out of reset — which is exactly why a
smoke-test from `pc = 0` would not have caught it.* -/
theorem addend_as_pc_is_wrong_unless_pc_zero (s : St) (rd x y : Fin 32) (h : s.pc ≠ 0) :
    wordOf (fun k => (SaltWorks.HDL.pcRun (s.get x) (s.get y) 0 false).getD k false)
      ≠ (stepT (SaltWorks.HDL.decQ (envWith s (encode (Instr.ADD rd x y))))
                (seenWord (envWith s (encode (Instr.ADD rd x y))))).pc := by
  rw [addend_read_as_pc_is_four, pcField_is_pcAdd_add, pcAdd_word, if_neg (by simp)]
  intro he
  refine h (add_right_cancel (b := (4 : Word)) ?_)
  rw [zero_add]
  exact he.symm

/-- ⛔ **THE DEFECT AND THE FIX, SIDE BY SIDE, AT ONE PC.** -/
theorem the_defect_and_the_fix :
    wordOf (fun k => (SaltWorks.HDL.pcRun 0 0 0 false).getD k false) = 4
      ∧ wordOf (fun k => (sem pcAdd (pcAddEnv 0x1000 0 0 0 false)).getD k false) = 0x1004
      ∧ (0x1004 : Word) ≠ 4 :=
  ⟨addend_read_as_pc_is_four 0 0 0, by rw [pcAdd_word]; decide, by decide⟩

/-- The 260-gate netlist, walked by the kernel — an independent check of
`sem_pcAdd`, since it goes through the circuit rather than through the proof. -/
theorem pcAdd_netlist_advances_the_pc :
    sem pcAdd (pcAddEnv 0x1000 0 0 0 false)
      = (List.range 32).map (fun k => (0x1004 : Word).getLsbD k) := by decide +kernel

theorem pcAdd_netlist_takes_the_branch :
    sem pcAdd (pcAddEnv 0x1000 7 7 0x40 true)
      = (List.range 32).map (fun k => (0x1040 : Word).getLsbD k) := by decide +kernel

/-! ### ⛔ CONTROL BAR — two mutants the certificates ACCEPT

*The campaign standard set by `pcNextCut_passes_the_certificate` /
`pcNextCut_fails_the_theorem`: a mutant a sampled suite cannot tell from the real
thing, and the unconditional theorem can. Two here, because the composite has two
distinct defect surfaces — **its own wiring**, and **the organ it embeds**.* -/

/-- ⛔ **MUTANT A — ONE WIRE.** The adder's carry-in reads `pcNext`'s TAKE flag
(host net `194`) instead of the constant-zero net `129`. *The most available
error in this node: "which net is the zero?"* -/
def adSigmaCut (i : Nat) : Nat := if i < 64 then adSigma i else 194

def pcAddCut : Circ :=
  { pcAdd with
    gates := ⟨pcAddZero, .const false⟩
               :: (instGates pcNext pcSigma pcAddOff
                     ++ instGates adder32 adSigmaCut (instNext pcNext pcAddOff)) }

theorem pcAddCut_ssa : pcAddCut.ssa = true := by decide +kernel
theorem pcAddCut_gate_count : pcAddCut.gates.length = 260 := by decide +kernel

def pcAddPcs : List Word := [0, 4, 0x1000]
def pcAddPairs : List (Word × Word) := [(0, 0), (1, 1), (0, 1), (0x80000000, 0)]
def pcAddOffs : List Word := [0, 8, 0x40]

/-- The NOT-TAKEN suite — `pcNext_not_beq_adds_four`'s coverage, lifted to the
composite: the ratified behaviour on **99.61%** of the word space. -/
def pcAddOKCut : Bool :=
  pcAddPcs.all fun p => pcAddPairs.all fun q => pcAddOffs.all fun o =>
    sem pcAddCut (pcAddEnv p q.1 q.2 o false)
      == (List.range 32).map (fun k => (p + 4).getLsbD k)

/-- ⛔ **36 DRIVEN POINTS, AND THE MUTANT PASSES ALL OF THEM** — the carry-in it
reads is `false` on every non-branch, so the wire is invisible on the path the
core spends 99.61% of its life on. -/
theorem pcAddCut_passes_the_certificate : pcAddOKCut = true := by decide +kernel

/-- ⭐ **AND `sem_pcAdd` REFUSES IT** at one taken branch: `0x1000 + 0x40` comes
back `0x1041`. -/
theorem pcAddCut_fails_the_theorem :
    sem pcAddCut (pcAddEnv 0x1000 7 7 0x40 true)
      ≠ (List.range 32).map (fun k => ((0x1000 : Word) + 0x40).getLsbD k) := by decide +kernel

/-- ⛔ **MUTANT B — THE ORGAN.** The same composite around the landed
`adder32Cut` (slice 16's carry-out `or` → `and`). *This one survives BOTH branch
directions: the certificate below drives taken and not-taken alike, and the
mutation is only visible when a carry crosses bit 16 — which realistic pcs and
short branch offsets never do.* -/
def pcAddCutB : Circ :=
  { pcAdd with
    gates := ⟨pcAddZero, .const false⟩
               :: (instGates pcNext pcSigma pcAddOff
                     ++ instGates adder32Cut adSigma (instNext pcNext pcAddOff)) }

theorem pcAddCutB_ssa : pcAddCutB.ssa = true := by decide +kernel

def pcAddOKCutB : Bool :=
  pcAddPcs.all fun p => pcAddOffs.all fun o => [false, true].all fun b =>
    sem pcAddCutB (pcAddEnv p 7 7 o b)
      == (List.range 32).map (fun k => (p + (if b then o else 4)).getLsbD k)

/-- ⛔ **18 DRIVEN POINTS, BOTH BRANCH DIRECTIONS, AND THE MUTANT PASSES.** -/
theorem pcAddCutB_passes_the_certificate : pcAddOKCutB = true := by decide +kernel

/-- ⭐ **AND `sem_pcAdd` REFUSES IT** at a pc where the carry crosses bit 16:
`0x0001FFFC + 4` should be `0x00020000` and the mutant loses the carry. -/
theorem pcAddCutB_fails_the_theorem :
    sem pcAddCutB (pcAddEnv 0x0001FFFC 0 0 0 false)
      ≠ (List.range 32).map (fun k => ((0x0001FFFC : Word) + 4).getLsbD k) := by decide +kernel

/-- ⭐ **THE CERTIFICATE IS NOT BROKEN — THE MUTANT IS INDISTINGUISHABLE FROM THE
REAL COMPOSITE ON IT.** *Without this, "the mutant passes" and "the suite is
malformed" look the same from outside.* -/
def pcAddOK : Bool :=
  pcAddPcs.all fun p => pcAddPairs.all fun q => pcAddOffs.all fun o =>
    sem pcAdd (pcAddEnv p q.1 q.2 o false)
      == (List.range 32).map (fun k => (p + 4).getLsbD k)

theorem pcAdd_passes_the_certificate : pcAddOK = true := by decide +kernel

/-- ⭐ **THE THEOREM REACHES WHERE NEITHER CERTIFICATE DOES.** -/
theorem sem_pcAdd_off_the_sample :
    (0x0001FFFC : Word) ∉ pcAddPcs
      ∧ sem pcAdd (pcAddEnv 0x0001FFFC 0 0 0 false)
          = (List.range 32).map (fun k => ((0x0001FFFC : Word) + 4).getLsbD k)
      ∧ sem pcAdd (pcAddEnv 0x1000 7 7 0x40 true)
          = (List.range 32).map (fun k => ((0x1000 : Word) + 0x40).getLsbD k) :=
  ⟨by decide +kernel, by rw [sem_pcAdd]; norm_num, by rw [sem_pcAdd]; norm_num⟩


end OrganSemantics

/-! ## ⭐⭐ THE ALU OUTPUT SELECT — AND WHAT ITS CERTIFICATE QUANTIFIES OVER

⚠️ **READ THIS BEFORE ASSUMING `aluSelect` WAS ALREADY GENERAL.**
`SaltWorks/HDL/AluSelect.lean:460-507` carries a driver, a predicate and two
theorems:

```
-- ⛔⛔ VERBATIM QUOTE OF `SaltWorks/HDL/AluSelect.lean:460-507`. NOT A
-- DEFINITION SITE. These five declarations are ALIVE and are defined in that
-- file; this fence is prose about them. A name-grep that lands here is reading
-- a quotation, and a census that treats this as their definition site will
-- conclude they have no consumers — which on 2026-08-08 nearly licensed a
-- wrong deletion of the whole sample layer. To change them, edit AluSelect.lean.
def asOneHot (m sel : Nat) : Env := ...      -- result m all-ones, the other nine all-zero
def asBit0 (m sel : Nat) : Bool := (sem aluSelect (asOneHot m sel)).getD 0 false
def asSelectsOK (m : Nat) : Bool := (List.range 16).all fun sel => asBit0 m sel == decide (sel = m)
theorem aluSelect_selects_on_sample      : asSelectsOK 3 = true := by decide +kernel
theorem aluSelect_selects_on_sample_last : asSelectsOK 9 = true := by decide +kernel
```

and a docstring reading *"all sixteen select values, kernel-checked"*. **That
sentence is true about `sel` and silent about everything else.** Measured:

| axis | size of the axis | what the two theorems cover |
|---|---:|---|
| `sel`, the select value | 16 | ⭐ **ALL 16 — genuinely exhaustive** |
| `m`, which operand is live | unbounded | ⛔ **TWO POINTS: `m = 3` and `m = 9`** |
| the 320 operand-result bits | `2^320` | ⛔ **one pattern per `m`** — all-ones in slot `m`, all-zero elsewhere; the driver cannot paint any other picture |
| the 4 select-input bits | 16 | ✅ covered, and this is the `sel` axis |
| the output | 32 bits | ⛔ **BIT 0 ONLY** — `asBit0` is `getD 0` |

⇒ **`aluSelect` has `2^324` input valuations and 32 outputs. The certificate
drives 32 of them and reads one output bit.** *`sel` is the universal argument;
`m` is the sampled one; the operand bits are not an axis of the certificate at
all.*

⛔ **AND `asSelectsOK` IS NOT A UNIVERSALLY TRUE STATEMENT ABOUT `m`.**
`asSelectsOK_fails_at_ten` below proves `asSelectsOK 10 = false`: at the first
PAD slot the tree correctly returns `false` while `decide (10 = 10)` is `true`.
The predicate holds exactly on `m < 10 ∨ 16 ≤ m`, and both proved points sit
inside the first range. *So "the certificate passes" is not even a property the
block has for all `m` — it is a property of the ten real operand slots, which is
what `asSelectsOK_of_lt` proves outright.*

## What lands here

`sem_aluSelect` is universal in **every one of the 324 inputs** — arbitrary
operand bits, arbitrary select bits, arbitrary garbage on the internal nets —
and pins **all 32 outputs**:

```
sem aluSelect E = (List.range 32).map fun k =>
  if asSelOf E < asOps then E (asRes (asSelOf E) k) else false
```

read in the block's own vocabulary (`asSelOf` is the four select nets as a
number, LSB first; `asRes r k` is bit `k` of result `r`; `asOps = 10`). It says
the block is a 16:1 mux whose top six sources are tied low — which is exactly
the design claim `asPad = 16` makes and which nothing checked. `asSelectsOK_of_lt`
then recovers the sampled predicate for **all ten** real operands as a corollary,
so this supersedes the certificate rather than restating it.

## ⭐ WHICH LANDED MACHINERY TRANSFERRED, AND WHICH DID NOT

*Measured before proving, per the two briefs that were wrong about this:*

* `run_pointwise` — **did NOT transfer.** `aluSelect` has no pointwise block.
  Apart from one `const` and four inverters, every gate is part of a mux triple
  whose fanin is another gate's output, so there is no row of gates that all read
  only primary inputs.
* `run_orChain` — **did NOT transfer.** `aluSelect` contains no `orChain`; its
  reduction is a **tree**, not a chain, and a tree's levels are independent
  blocks in series rather than a fold.
* `sem_adder32`'s carry induction — **no.** No carry, no arithmetic.
* What DID transfer is the **method**: a frame lemma plus an induction carrying
  an invariant, and `Sem.lean`'s `run_of_unwritten` / `run_append`.

⭐ **THE NEW GENERIC PIECE IS `run_muxRow`** — a row of `n` two-to-one muxes,
three gates each, proved generically over the base net, both source functions,
both select nets and `n`. It is to selectors what `run_pointwise` is to bitwise
blocks: `aluSelect`'s 1,440 mux gates are **four instances of it** (widths
8/4/2/1), and any later block emitting `and/and/or` mux triples inherits it.

## The three shapes, in series

```
1 gate     const false                        the shared pad source
4 gates    not sel[j]                         one inverter per select bit, shared by every mux
1440 gates 32 independent 4-level mux trees   45 gates per output bit, 15 muxes of 3 gates
```

Bit `k`'s tree occupies nets `329 + 45k … 329 + 45k + 44` and reads only primary
inputs, the pad and the four inverters — so the 32 trees are proved once,
generically in `k`, and composed by an induction whose frame is `m < 329`.

⛔ **`C4Spec` IS NOT CLOSED BY THIS, AND NOTHING HERE CLAIMS IT IS.** `core` does
not exist. `aluField_is_aluSelect_add` is the service a `core` assembly would
apply, in the shape `addField_is_adder32` performs for the adder.

⚠️ **THE `Net` TRAP COST THIS NODE ITS ONLY REWORK.** `abbrev Net := Nat`, and
`omega` drops a `Net`-typed goal on the floor — it reported "no usable
constraints" for `320 + j < 320`. Every net-arithmetic obligation below therefore
goes through a `Nat` mirror (`gsB`) or a `Nat`-binder restatement
(`asOneHot_eq`, `asDrive_eq`, `asOffEnv_eq`), whose whole content is to move a
definition's own binder from `Net` to `Nat`.
-/

section AluSelectSemantics

open SaltWorks.HDL hiding seenWord

/-! ## The generic mux row -/

def muxRow (base : Nat) (p q : Nat → Net) (s t : Net) (n : Nat) : List Gate :=
  (List.range n).flatMap fun i =>
    [(⟨base + 3 * i,     .and (p i) s⟩ : Gate),
     ⟨base + 3 * i + 1, .and (q i) t⟩,
     ⟨base + 3 * i + 2, .or (base + 3 * i) (base + 3 * i + 1)⟩]

theorem muxRow_succ (base : Nat) (p q : Nat → Net) (s t : Net) (n : Nat) :
    muxRow base p q s t (n + 1)
      = muxRow base p q s t n
          ++ [(⟨base + 3 * n,     .and (p n) s⟩ : Gate),
              ⟨base + 3 * n + 1, .and (q n) t⟩,
              ⟨base + 3 * n + 2, .or (base + 3 * n) (base + 3 * n + 1)⟩] := by
  simp [muxRow, List.range_succ]

theorem run_three (F : Env) (b : Nat) (a1 a2 s t : Net) (h2 : a2 < b) (ht : t < b) :
    run F [(⟨b, .and a1 s⟩ : Gate), ⟨b + 1, .and a2 t⟩, ⟨b + 2, .or b (b + 1)⟩] (b + 2)
      = ((F a1 && F s) || (F a2 && F t)) := by
  have e4 : ¬ (a2 = b) := Nat.ne_of_lt h2
  have e5 : ¬ (t = b) := Nat.ne_of_lt ht
  simp [Op.eval, upd, e4, e5]

theorem run_three_frame (F : Env) (b m : Nat) (a1 a2 s t : Net)
    (hm : ¬ (b ≤ m ∧ m ≤ b + 2)) :
    run F [(⟨b, .and a1 s⟩ : Gate), ⟨b + 1, .and a2 t⟩, ⟨b + 2, .or b (b + 1)⟩] m = F m := by
  have e0 : ¬ (m = b) := by omega
  have e1 : ¬ (m = b + 1) := by omega
  have e2 : ¬ (m = b + 2) := by omega
  simp [Op.eval, upd, e0, e1, e2]

theorem run_muxRow (E : Env) (base : Nat) (p q : Nat → Net) (s t : Net)
    (hs : s < base) (ht : t < base) :
    ∀ n : Nat, (∀ i : Nat, i < n → p i < base ∧ q i < base) →
      (∀ m : Nat, m < base → run E (muxRow base p q s t n) m = E m)
      ∧ (∀ i : Nat, i < n → run E (muxRow base p q s t n) (base + 3 * i + 2)
           = ((E (p i) && E s) || (E (q i) && E t))) := by
  intro n
  induction n with
  | zero => intro _; exact ⟨fun m _ => rfl, fun i hi => absurd hi (Nat.not_lt_zero i)⟩
  | succ n ih =>
    intro hb
    obtain ⟨hfr, hval⟩ := ih (fun i hi => hb i (Nat.lt_succ_of_lt hi))
    obtain ⟨hpn, hqn⟩ := hb n (Nat.lt_succ_self n)
    refine ⟨?_, ?_⟩
    · intro m hm
      rw [muxRow_succ, run_append, run_three_frame _ _ _ _ _ _ _ (by omega)]
      exact hfr m hm
    · intro i hi
      rw [muxRow_succ, run_append]
      rcases Nat.lt_or_ge i n with hin | hin
      · rw [run_three_frame _ _ _ _ _ _ _ (by omega)]
        exact hval i hin
      · have hEq : i = n := Nat.le_antisymm (Nat.le_of_lt_succ hi) hin
        subst hEq
        rw [run_three _ (base + 3 * i) (p i) (q i) s t
            (Nat.lt_of_lt_of_le hqn (Nat.le_add_right base (3 * i)))
            (Nat.lt_of_lt_of_le ht (Nat.le_add_right base (3 * i))),
          hfr (p i) hpn, hfr s hs, hfr (q i) hqn, hfr t ht]

theorem mux_pick (a b c : Bool) : ((a && !c) || (b && c)) = (if c then b else a) := by
  cases c <;> simp

/-! ## The block's arithmetic, in `Nat`

⛔ **PHASE 3 CONTRACTION — the literal-width route is RETIRED (math seat).**
What stood here between `asRes_eq` and `run_asBit` was the route written at ONE
WIDTH: `asOps_eq`, `asSel_eq`, `asNot_eq`, `asZero_eq`, the `Nat` mirror
`asB k j = 329 + 45*k + 3*asBelow j` with `asB0`–`asB3`, `asBase_eq`, `asOut_eq`,
`asB_mono01`–`asB_mono23`, `asPrev_0` at `10`/`324`, `asPrev_1'`–`asPrev_3'`,
the gate-list defs `asL`/`asBitGates`/`asBodyGates`/`asPreGates` with
`asBitGates_eq` and `aluSelect_gates_eq`, `asL_eq` and the four widths
`asL0_eq`–`asL3_eq` (`8/4/2/1`), `asLeafOf`, `asV0`–`asV3`, the six `asPrev*_lt`
bounds, and `run_asBit`.

Each bridged an `as*` constant to the numeral it carried at
`(asOps, asSelBits, asPad) = (10, 4, 16)`, so the ruled re-cut to `(3, 2, 4)`
**FALSIFIES** them rather than merely unproving them — `decide` and `rfl` report
them false, which is the tripwire doing its job.

⇒ **RETIRED, not restated.** The pair-independent route is the `gs*` family below
— `gsB`/`gsBase_eq`/`gsOut_eq`, `gsL_eq`, `run_gsLevels`, `run_gsBody`,
`run_gsPre`, `sem_genSelect` — which proves the same statements at EVERY `(n, b)`
and is already what `sem_aluSelect` rests on. *`muxRow` and its four lemmas above
STAY: `gsL_eq` uses them.* -/

theorem asW_eq : asW = 32 := rfl
theorem asRes_eq (r k : Nat) : asRes r k = r * 32 + k := rfl

/-! ## The select value, and the closed form of a bit tree

⚠️ **`gsSelUpTo`/`gsSelOf` are defined HERE, ahead of the generic section below,
because `asSelOf` is literally `gsSelOf` at the live pair** — the general
definition has to precede the special one. Nothing else about them is local to
the literal width; the rest of the `gs*` family stays with `sem_genSelect`. -/

/-- The low `j` select nets read as a number, `sel[0]` the LSB. -/
def gsSelUpTo (n b : Nat) (F : Env) : Nat → Nat
  | 0     => 0
  | j + 1 => gsSelUpTo n b F j + (if F (gsSel n b j) then 2 ^ j else 0)

def gsSelOf (n b : Nat) (F : Env) : Nat := gsSelUpTo n b F b

/-- The select nets read as a number — `sel[0]` is the LSB.

⇒ **This is `gsSelOf` at the live pair, not a second definition of the same
thing.** `asOps` and `asSelBits` are plain `def`s, so `asSelOf E` and
`gsSelOf asOps asSelBits E` are the same term up to delta, and re-sizing the
block moves this line by changing the constants rather than by re-typing a
fixed-width sum.

⛔ **PHASE 3: `asSelOf_expand` IS GONE**, together with `asV3_eq`,
`asSelOf_congr`, `asV3_congr`, `asPreGates_eq`, `run_asPre` and `run_asBody`.
Each spelled the old width out — a four-term sum, `< 324`, `∀ j, j < 4`, the
five-gate prefix list, `m < 329` — so the ruled re-cut falsifies them.
`gsSelUpTo`/`gsSelOf` above carry the same content at every pair. -/
def asSelOf (E : Env) : Nat := gsSelOf asOps asSelBits E

/-! ## ⭐⭐⭐ THE SAME BLOCK AT EVERY SOURCE COUNT — `sem_genSelect`

*Everything above this point is written at ONE WIDTH.* `329 + 45*k + 42`,
`pfr (320 + j)`, `< 324`, `∀ j, j < 4`, and **level 3 in the lemma names**
(`asV3_eq`, `asB3`, `asOut k 3 0`). That is why the ALU sizing question was a
**deadline rather than a trade** (silicon, `79bb72a`): the gate saving is fixed
at 770–1,154 and the proof cost is monotonically increasing, because every
theorem proved against `asIn = 324` is another line in the eventual rewrite.

⇒ **The deadline is not a property of the decision. It is a property of one
proof having been written at a literal width.** What follows re-proves the block
at `genSelect n b` (`HDL/AluSelect.lean`) — `n` sources, `b` encoded select bits,
`2^b` padded leaves — and `sem_aluSelect` becomes the `n = 10, b = 4` corollary.
Shrinking the ALU to three sources is now an INSTANTIATION.

## The induction the shape actually wants, and the one it does not

⛔ **The four levels above are NOT four instances of one lemma that could be
`induction`-ed directly.** Level `j`'s inputs are level `j-1`'s *outputs*, so an
induction whose invariant is "level `j` is correct" cannot state its own
hypothesis: at `j = 0` the inputs are leaf nets and at `j > 0` they are gate
nets, two different naming functions.

⭐ **What closes it is indexing on the INPUTS rather than the outputs.**
`run_gsLevels` carries

    ∀ l < gsWidth b j,  run G (gsPre n b k j) (gsPrev n b k j l) = gsV n b G k j l

— *what feeds level `j`* — and `gsPrev` is exactly the function that is leaf
naming at `0` and `gsOut` above it, so the base case and the step case are the
same sentence. The muxRow lemma then supplies the step and the frame together.

The closed form falls out of that by a second induction: `gsV n b F k j i` is the
leaf at `i * 2^j + (the low j select bits)`, so the root at `j = b` is the leaf
at `gsSelOf`, and the padding above `n` reads the tie constant. -/

theorem gsWidth_top (b : Nat) : gsWidth b b = 1 := by
  show 2 ^ b / 2 ^ b = 1
  rw [Nat.pow_div le_rfl (by norm_num)]
  simp

theorem gsWidth_of_le (b j : Nat) (h : j ≤ b) : gsWidth b j = 2 ^ (b - j) := by
  show 2 ^ b / 2 ^ j = _
  rw [Nat.pow_div h (by norm_num)]

theorem gsLevelWidth_two (b j : Nat) (h : j < b) : gsLevelWidth b j * 2 = gsWidth b j := by
  rw [show gsLevelWidth b j = gsWidth b (j + 1) from rfl,
    gsWidth_of_le b (j + 1) h, gsWidth_of_le b j (Nat.le_of_lt h), ← Nat.pow_succ]
  congr 1
  omega

theorem gsBelow_zero (b : Nat) : gsBelow b 0 = 0 := rfl

theorem gsBelow_succ (b j : Nat) : gsBelow b (j + 1) = gsBelow b j + gsLevelWidth b j := rfl

theorem gsBelow_of_le (b : Nat) : ∀ j, j ≤ b → gsBelow b j = 2 ^ b - 2 ^ (b - j) := by
  intro j
  induction j with
  | zero => intro _; show (0 : Nat) = 2 ^ b - 2 ^ (b - 0); simp
  | succ j ih =>
    intro hj
    have hjb : j < b := hj
    rw [gsBelow_succ, ih (Nat.le_of_lt hjb),
      show gsLevelWidth b j = gsWidth b (j + 1) from rfl, gsWidth_of_le b (j + 1) hj]
    have hp : 2 ^ (b - j) = 2 ^ (b - (j + 1)) * 2 := by
      rw [← Nat.pow_succ]; congr 1; omega
    have hle : 2 ^ (b - j) ≤ 2 ^ b := Nat.pow_le_pow_right (by norm_num) (by omega)
    omega

/-- **A whole bit tree is `2^b - 1` muxes** — the geometric sum, so the bits tile
the net space without a gap. -/
theorem gsBelow_top (b : Nat) : gsBelow b b = gsPad b - 1 := by
  rw [gsBelow_of_le b b le_rfl]
  show 2 ^ b - 2 ^ (b - b) = 2 ^ b - 1
  simp

/-- Base of level `j` of bit `k`'s tree, as a plain `Nat` — `abbrev Net := Nat`
defeats `omega`, so every arithmetic obligation below is stated at `Nat`. -/
def gsB (n b k j : Nat) : Nat := gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b j) * 3

theorem gsBase_eq (n b k j i : Nat) : gsBase n b k j i = gsB n b k j + 3 * i := by
  show gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b j + i) * 3
      = gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b j) * 3 + 3 * i
  omega

theorem gsOut_eq (n b k j i : Nat) : gsOut n b k j i = gsB n b k j + 3 * i + 2 := by
  show gsBase n b k j i + 2 = _
  rw [gsBase_eq]

theorem gsB_step (n b k j : Nat) : gsB n b k (j + 1) = gsB n b k j + 3 * gsLevelWidth b j := by
  show gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b (j + 1)) * 3
      = gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b j) * 3 + 3 * gsLevelWidth b j
  rw [gsBelow_succ]
  omega

theorem gsB_zero_le (n b k j : Nat) : gsB n b k 0 ≤ gsB n b k j := by
  show gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b 0) * 3
      ≤ gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b j) * 3
  rw [gsBelow_zero]
  omega

/-- **Bit `k`'s tree ends exactly where bit `k+1`'s begins.** -/
theorem gsB_bit (n b k : Nat) : gsB n b k b = gsB n b (k + 1) 0 := by
  have h2 : (k + 1) * (gsPad b - 1) = k * (gsPad b - 1) + (gsPad b - 1) := Nat.succ_mul _ _
  show gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b b) * 3
      = gsIn n b + 1 + b + ((k + 1) * (gsPad b - 1) + gsBelow b 0) * 3
  rw [gsBelow_top, gsBelow_zero, h2]
  omega

theorem gsB_bit_mono (n b k k' : Nat) (h : k ≤ k') : gsB n b k 0 ≤ gsB n b k' 0 := by
  have : k * (gsPad b - 1) ≤ k' * (gsPad b - 1) := Nat.mul_le_mul_right _ h
  show gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b 0) * 3
      ≤ gsIn n b + 1 + b + (k' * (gsPad b - 1) + gsBelow b 0) * 3
  rw [gsBelow_zero]
  omega

theorem gsB00 (n b : Nat) : gsB n b 0 0 = gsIn n b + 1 + b := by
  show gsIn n b + 1 + b + (0 * (gsPad b - 1) + gsBelow b 0) * 3 = _
  rw [gsBelow_zero]
  omega

theorem gsSel_lt_in (n b j : Nat) (hj : j < b) : gsSel n b j < gsIn n b := by
  show n * 32 + j < n * 32 + b
  omega

theorem gsRes_lt_in (n b r k : Nat) (hr : r < n) (hk : k < 32) : gsRes r k < gsIn n b := by
  show r * 32 + k < n * 32 + b
  have : r * 32 + 32 ≤ n * 32 := by
    have := Nat.mul_le_mul_right 32 hr
    omega
  omega

theorem gsNot_lt (n b k j : Nat) (hj : j < b) : gsNot n b j < gsB n b k 0 := by
  show gsIn n b + 1 + j < gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b 0) * 3
  rw [gsBelow_zero]
  omega

theorem gsSel_lt (n b k j : Nat) (hj : j < b) : gsSel n b j < gsB n b k 0 := by
  have h := gsSel_lt_in n b j hj
  show gsSel n b j < gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b 0) * 3
  rw [gsBelow_zero]
  omega

theorem gsZero_lt (n b k : Nat) : gsZero n b < gsB n b k 0 := by
  show gsIn n b < gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b 0) * 3
  rw [gsBelow_zero]
  omega

/-- ⭐ **Every net level `j` reads lies below level `j`'s base** — the ONE
obligation that is genuinely different at `j = 0` and above, and the reason the
induction is indexed on inputs. -/
theorem gsPrev_lt (n b k j l : Nat) (hk : k < 32) (hl : l < gsWidth b j) :
    gsPrev n b k j l < gsB n b k j := by
  cases j with
  | zero =>
    show (if n ≤ l then gsZero n b else gsRes l k) < gsB n b k 0
    split_ifs with h
    · exact gsZero_lt n b k
    · exact Nat.lt_of_lt_of_le (gsRes_lt_in n b l k (by omega) hk)
        (Nat.le_of_lt (gsZero_lt n b k))
  | succ j =>
    show gsOut n b k j l < gsB n b k (j + 1)
    rw [gsOut_eq, gsB_step]
    have : l < gsLevelWidth b j := hl
    omega

/-! ### The tree's value

*(`gsSelUpTo` and `gsSelOf` are not missing — they are defined ABOVE `asSelOf`,
which is their instance at `(asOps, asSelBits)`; see the note there.)* -/

/-- Leaf `l` of bit `k`'s tree: a real source below `n`, the shared pad above. -/
def gsLeafOf (n b : Nat) (F : Env) (k l : Nat) : Bool :=
  if n ≤ l then F (gsZero n b) else F (gsRes l k)

/-- `gsV … j i` is what feeds position `i` of level `j`: at `j = 0` a leaf, above
it the value level `j-1` computed. -/
def gsV (n b : Nat) (F : Env) (k : Nat) : Nat → Nat → Bool
  | 0,     i => gsLeafOf n b F k i
  | j + 1, i => if F (gsSel n b j) then gsV n b F k j (2 * i + 1) else gsV n b F k j (2 * i)

/-- ⭐ **THE CLOSED FORM** — position `i` of level `j` holds leaf
`i * 2^j + (the low j select bits)`. -/
theorem gsV_eq (n b : Nat) (F : Env) (k : Nat) :
    ∀ j i : Nat, gsV n b F k j i = gsLeafOf n b F k (i * 2 ^ j + gsSelUpTo n b F j) := by
  intro j
  induction j with
  | zero => intro i; show gsLeafOf n b F k i = gsLeafOf n b F k (i * 1 + 0); congr 1; omega
  | succ j ih =>
    intro i
    show (if F (gsSel n b j) then gsV n b F k j (2 * i + 1) else gsV n b F k j (2 * i)) = _
    rw [ih (2 * i + 1), ih (2 * i)]
    show _ = gsLeafOf n b F k (i * 2 ^ (j + 1)
        + (gsSelUpTo n b F j + (if F (gsSel n b j) then 2 ^ j else 0)))
    have hp : (2 : Nat) ^ (j + 1) = 2 ^ j * 2 := Nat.pow_succ 2 j
    split_ifs with hs <;> · congr 1; rw [hp]; ring

theorem gsV_top (n b : Nat) (F : Env) (k : Nat) :
    gsV n b F k b 0 = gsLeafOf n b F k (gsSelOf n b F) := by
  rw [gsV_eq]
  congr 1
  show 0 * 2 ^ b + gsSelUpTo n b F b = gsSelUpTo n b F b
  omega

theorem gsSelUpTo_congr (n b : Nat) (F G : Env)
    (h : ∀ j : Nat, j < b → F (gsSel n b j) = G (gsSel n b j)) :
    ∀ j, j ≤ b → gsSelUpTo n b F j = gsSelUpTo n b G j := by
  intro j
  induction j with
  | zero => intro _; rfl
  | succ j ih =>
    intro hj
    show gsSelUpTo n b F j + (if F (gsSel n b j) then 2 ^ j else 0)
        = gsSelUpTo n b G j + (if G (gsSel n b j) then 2 ^ j else 0)
    rw [ih (Nat.le_of_lt hj), h j hj]

theorem gsSelOf_congr (n b : Nat) (F G : Env) (h : ∀ m : Nat, m < gsIn n b → F m = G m) :
    gsSelOf n b F = gsSelOf n b G :=
  gsSelUpTo_congr n b F G (fun j hj => h _ (gsSel_lt_in n b j hj)) b le_rfl

theorem gsV_top_congr (n b : Nat) (F G : Env) (k : Nat) (hk : k < 32)
    (h : ∀ m : Nat, m < gsB n b 0 0 → F m = G m) :
    gsV n b F k b 0 = gsV n b G k b 0 := by
  have hin : ∀ m : Nat, m < gsIn n b → F m = G m := by
    intro m hm
    refine h m ?_
    rw [gsB00]
    omega
  rw [gsV_top, gsV_top, gsSelOf_congr n b F G hin]
  show (if n ≤ gsSelOf n b G then F (gsZero n b) else F (gsRes (gsSelOf n b G) k))
      = (if n ≤ gsSelOf n b G then G (gsZero n b) else G (gsRes (gsSelOf n b G) k))
  split_ifs with hlt
  · refine h (gsZero n b) ?_
    rw [gsB00]
    show gsIn n b < gsIn n b + 1 + b
    omega
  · exact hin _ (gsRes_lt_in n b _ k (by omega) hk)

/-! ### The gate list, cut into a prefix and 32 independent bit trees -/

def gsL (n b k j : Nat) : List Gate := (List.range (gsLevelWidth b j)).flatMap (gsMux n b k j)

/-- Levels `0 … j-1` of bit `k`, in emission order. -/
def gsPre (n b k : Nat) : Nat → List Gate
  | 0     => []
  | j + 1 => gsPre n b k j ++ gsL n b k j

def gsBitGates (n b k : Nat) : List Gate := gsPre n b k b

def gsBodyGates (n b c : Nat) : List Gate := (List.range c).flatMap (gsBitGates n b)

def gsPreGates (n b : Nat) : List Gate :=
  (⟨gsZero n b, .const false⟩ : Gate)
    :: (List.range b).map (fun j => (⟨gsNot n b j, .not (gsSel n b j)⟩ : Gate))

theorem gsPre_eq (n b k : Nat) : ∀ j, (List.range j).flatMap (gsL n b k) = gsPre n b k j := by
  intro j
  induction j with
  | zero => rfl
  | succ j ih =>
    rw [List.range_succ, List.flatMap_append, ih]
    show gsPre n b k j ++ (gsL n b k j ++ []) = gsPre n b k j ++ gsL n b k j
    rw [List.append_nil]

theorem genSelect_gates_eq (n b : Nat) :
    (genSelect n b).gates = gsPreGates n b ++ gsBodyGates n b 32 := by
  have h : (fun k => (List.range b).flatMap fun j =>
              (List.range (gsLevelWidth b j)).flatMap (gsMux n b k j))
         = gsBitGates n b := by
    funext k
    show (List.range b).flatMap (gsL n b k) = gsPre n b k b
    exact gsPre_eq n b k b
  show gsPreGates n b ++ (List.range 32).flatMap
      (fun k => (List.range b).flatMap fun j =>
        (List.range (gsLevelWidth b j)).flatMap (gsMux n b k j)) = _
  rw [h]
  rfl

theorem gsL_eq (n b k j : Nat) :
    gsL n b k j = muxRow (gsB n b k j) (fun i => gsPrev n b k j (2 * i))
        (fun i => gsPrev n b k j (2 * i + 1)) (gsNot n b j) (gsSel n b j) (gsLevelWidth b j) := by
  have h : gsMux n b k j = fun i =>
      [(⟨gsB n b k j + 3 * i, .and (gsPrev n b k j (2 * i)) (gsNot n b j)⟩ : Gate),
       ⟨gsB n b k j + 3 * i + 1, .and (gsPrev n b k j (2 * i + 1)) (gsSel n b j)⟩,
       ⟨gsB n b k j + 3 * i + 2, .or (gsB n b k j + 3 * i) (gsB n b k j + 3 * i + 1)⟩] := by
    funext i
    show [(⟨gsBase n b k j i, .and (gsPrev n b k j (2 * i)) (gsNot n b j)⟩ : Gate),
          ⟨gsBase n b k j i + 1, .and (gsPrev n b k j (2 * i + 1)) (gsSel n b j)⟩,
          ⟨gsOut n b k j i, .or (gsBase n b k j i) (gsBase n b k j i + 1)⟩] = _
    rw [gsOut_eq, gsBase_eq]
  rw [gsL, h, muxRow]

/-! ### ⭐ THE LEVEL INDUCTION — the heart of the parametrisation -/

theorem gsPrev_zero_val (n b : Nat) (F : Env) (k l : Nat) :
    F (gsPrev n b k 0 l) = gsLeafOf n b F k l := by
  show F (if n ≤ l then gsZero n b else gsRes l k) = _
  rw [gsLeafOf]
  split_ifs <;> rfl

/-- ⭐⭐ **ONE BIT'S TREE, AT EVERY DEPTH.** Indexed on level `j`'s INPUTS, so
the base case (leaf nets) and the step case (the level below's outputs) are the
same sentence — `gsPrev` is the function that changes shape, not the invariant. -/
theorem run_gsLevels (n b : Nat) (G : Env) (k : Nat) (hk : k < 32)
    (hnot : ∀ j : Nat, j < b → G (gsNot n b j) = !(G (gsSel n b j))) :
    ∀ j : Nat, j ≤ b →
      (∀ m : Nat, m < gsB n b k 0 → run G (gsPre n b k j) m = G m)
      ∧ (∀ l : Nat, l < gsWidth b j →
           run G (gsPre n b k j) (gsPrev n b k j l) = gsV n b G k j l) := by
  intro j
  induction j with
  | zero =>
    intro _
    refine ⟨fun m _ => rfl, fun l _ => ?_⟩
    exact gsPrev_zero_val n b G k l
  | succ j ih =>
    intro hj
    have hjb : j < b := hj
    obtain ⟨hfr, hval⟩ := ih (Nat.le_of_lt hjb)
    have hbase : gsB n b k 0 ≤ gsB n b k j := gsB_zero_le n b k j
    have L := run_muxRow (run G (gsPre n b k j)) (gsB n b k j)
        (fun i => gsPrev n b k j (2 * i)) (fun i => gsPrev n b k j (2 * i + 1))
        (gsNot n b j) (gsSel n b j)
        (Nat.lt_of_lt_of_le (gsNot_lt n b k j hjb) hbase)
        (Nat.lt_of_lt_of_le (gsSel_lt n b k j hjb) hbase)
        (gsLevelWidth b j)
        (fun i hi => ⟨gsPrev_lt n b k j (2 * i) hk (by
            have := gsLevelWidth_two b j hjb; omega),
          gsPrev_lt n b k j (2 * i + 1) hk (by
            have := gsLevelWidth_two b j hjb; omega)⟩)
    rw [← gsL_eq n b k j] at L
    have hsucc : gsPre n b k (j + 1) = gsPre n b k j ++ gsL n b k j := rfl
    refine ⟨?_, ?_⟩
    · intro m hm
      rw [hsucc, run_append, L.1 m (Nat.lt_of_lt_of_le hm hbase)]
      exact hfr m hm
    · intro l hl
      have hlw : l < gsLevelWidth b j := hl
      rw [hsucc, run_append]
      show run (run G (gsPre n b k j)) (gsL n b k j) (gsOut n b k j l) = _
      rw [gsOut_eq, L.2 l hlw,
        hfr (gsNot n b j) (gsNot_lt n b k j hjb), hfr (gsSel n b j) (gsSel_lt n b k j hjb),
        hnot j hjb, mux_pick, hval (2 * l) (by have := gsLevelWidth_two b j hjb; omega),
        hval (2 * l + 1) (by have := gsLevelWidth_two b j hjb; omega)]
      rfl

/-! ### The 32 bit trees, in series -/

theorem run_gsBody (n b : Nat) (hb : 0 < b) (F : Env)
    (hnot : ∀ j : Nat, j < b → F (gsNot n b j) = !(F (gsSel n b j))) :
    ∀ c : Nat, c ≤ 32 →
      (∀ m : Nat, m < gsB n b 0 0 → run F (gsBodyGates n b c) m = F m)
      ∧ (∀ k : Nat, k < c →
           run F (gsBodyGates n b c) (gsOut n b k (b - 1) 0) = gsV n b F k b 0) := by
  have hlw1 : gsLevelWidth b (b - 1) = 1 := by
    show gsWidth b (b - 1 + 1) = 1
    rw [show b - 1 + 1 = b from by omega]
    exact gsWidth_top b
  have hb1 : (b - 1) + 1 = b := by omega
  have hroot : ∀ k : Nat, gsOut n b k (b - 1) 0 + 1 = gsB n b (k + 1) 0 := by
    intro k
    have e1 := gsB_step n b k (b - 1)
    rw [hb1] at e1
    rw [gsOut_eq, ← gsB_bit n b k, e1, hlw1]
  intro c
  induction c with
  | zero => intro _; exact ⟨fun m _ => rfl, fun k hk => absurd hk (Nat.not_lt_zero k)⟩
  | succ c ih =>
    intro hc
    obtain ⟨hfr, hval⟩ := ih (Nat.le_of_succ_le hc)
    have hc32 : c < 32 := Nat.lt_of_lt_of_le (Nat.lt_succ_self c) hc
    have hsucc : gsBodyGates n b (c + 1) = gsBodyGates n b c ++ gsBitGates n b c := by
      simp [gsBodyGates, List.range_succ]
    have hzero_le : gsB n b 0 0 ≤ gsB n b c 0 := gsB_bit_mono n b 0 c (Nat.zero_le c)
    have hnot' : ∀ j : Nat, j < b → run F (gsBodyGates n b c) (gsNot n b j)
        = !(run F (gsBodyGates n b c) (gsSel n b j)) := by
      intro j hj
      rw [hfr (gsNot n b j) (gsNot_lt n b 0 j hj), hfr (gsSel n b j) (gsSel_lt n b 0 j hj)]
      exact hnot j hj
    obtain ⟨bfr, bval⟩ :=
      run_gsLevels n b (run F (gsBodyGates n b c)) c hc32 hnot' b le_rfl
    refine ⟨?_, ?_⟩
    · intro m hm
      rw [hsucc, run_append]
      show run (run F (gsBodyGates n b c)) (gsPre n b c b) m = F m
      rw [bfr m (Nat.lt_of_lt_of_le hm hzero_le)]
      exact hfr m hm
    · intro k hk
      rw [hsucc, run_append]
      show run (run F (gsBodyGates n b c)) (gsPre n b c b) (gsOut n b k (b - 1) 0) = _
      rcases Nat.lt_or_ge k c with hkc | hkc
      · rw [bfr (gsOut n b k (b - 1) 0) ?_]
        · exact hval k hkc
        · have h1 := hroot k
          have h2 : gsB n b (k + 1) 0 ≤ gsB n b c 0 := gsB_bit_mono n b (k + 1) c hkc
          omega
      · have hEq : k = c := Nat.le_antisymm (Nat.le_of_lt_succ hk) hkc
        subst hEq
        have hb0 := bval 0 (by rw [gsWidth_top]; omega)
        show run (run F (gsBodyGates n b k)) (gsPre n b k b) (gsOut n b k (b - 1) 0) = _
        rw [show gsOut n b k (b - 1) 0 = gsPrev n b k b 0 from by
              rw [show b = (b - 1) + 1 from by omega]
              rfl]
        rw [hb0]
        exact gsV_top_congr n b _ _ k hc32 hfr

/-! ### The constant and the `b` shared inverters

⭐ **`run_pointwise` transfers exactly** — the inverters are
`(List.range b).map fun j => ⟨gsIn n b + 1 + j, .not (gsSel n b j)⟩`, the
pointwise shape on the nose, and the tie constant is peeled off as one `upd`. -/

theorem run_gsPre (n b : Nat) (E : Env) :
    (∀ m : Nat, m < gsIn n b → run E (gsPreGates n b) m = E m)
    ∧ run E (gsPreGates n b) (gsZero n b) = false
    ∧ (∀ j : Nat, j < b → run E (gsPreGates n b) (gsNot n b j) = !(E (gsSel n b j))) := by
  have hstep : run E (gsPreGates n b)
      = run (upd E (gsIn n b) false)
          ((List.range b).map (fun j => (⟨gsIn n b + 1 + j, Op.not (gsSel n b j)⟩ : Gate))) := by
    show run (upd E (gsZero n b) ((Op.const false).eval E)) _ = _
    rfl
  have P := run_pointwise (upd E (gsIn n b) false) (gsIn n b + 1) (fun j => Op.not (gsSel n b j)) b
      (by
        intro i hi a ha
        show a < gsIn n b + 1
        have : a = gsSel n b i := by
          revert ha
          show a ∈ [gsSel n b i] → _
          intro ha
          simpa using ha
        rw [this]
        exact Nat.lt_of_lt_of_le (gsSel_lt_in n b i hi) (Nat.le_succ _))
  obtain ⟨pfr, pval⟩ := P
  refine ⟨?_, ?_, ?_⟩
  · intro m hm
    have hne : ¬ (m = gsIn n b) := by omega
    rw [hstep, pfr m (by omega)]
    exact upd_of_ne false hne
  · rw [hstep, show gsZero n b = gsIn n b from rfl, pfr (gsIn n b) (by omega)]
    simp [upd]
  · intro j hj
    have hne : ¬ (gsSel n b j = gsIn n b) := by
      have := gsSel_lt_in n b j hj; omega
    rw [hstep, show gsNot n b j = gsIn n b + 1 + j from rfl, pval j hj]
    show (!(upd E (gsIn n b) false (gsSel n b j))) = (!(E (gsSel n b j)))
    rw [upd_of_ne false hne]

/-! ### ⭐⭐ THE PARAMETRIC THEOREM -/

theorem genSelect_outs_eq (n b : Nat) :
    (genSelect n b).outs = (List.range 32).map (fun k => gsOut n b k (b - 1) 0) := rfl

/-- ⭐⭐⭐ **THE BLOCK SELECTS, AT EVERY SOURCE COUNT.** No driver, no sample:
for every `n`, every `b ≥ 1`, and EVERY valuation of the `n * 32 + b` input nets,
`genSelect n b` delivers all 32 bits of the source the select nets name, and
`false` at every bit when they name a padding slot. `sem_aluSelect` is the
`n = 10, b = 4` line of this. -/
theorem sem_genSelect (n b : Nat) (hb : 0 < b) (E : Env) :
    sem (genSelect n b) E
      = (List.range 32).map (fun k =>
          if gsSelOf n b E < n then E (gsRes (gsSelOf n b E) k) else false) := by
  obtain ⟨pfr, pzero, pnot⟩ := run_gsPre n b E
  have hnotF : ∀ j : Nat, j < b → run E (gsPreGates n b) (gsNot n b j)
      = !(run E (gsPreGates n b) (gsSel n b j)) := by
    intro j hj
    rw [pnot j hj, pfr (gsSel n b j) (gsSel_lt_in n b j hj)]
  obtain ⟨bfr, bval⟩ := run_gsBody n b hb (run E (gsPreGates n b)) hnotF 32 le_rfl
  have hsem : sem (genSelect n b) E
      = (List.range 32).map (fun k => run E (genSelect n b).gates (gsOut n b k (b - 1) 0)) := by
    show (genSelect n b).outs.map (run E (genSelect n b).gates) = _
    rw [genSelect_outs_eq, List.map_map]
    simp only [Function.comp_def]
  rw [hsem]
  refine List.map_congr_left ?_
  intro k hk
  have hk32 : k < 32 := List.mem_range.mp hk
  rw [genSelect_gates_eq, run_append, bval k hk32, gsV_top,
    gsSelOf_congr n b (run E (gsPreGates n b)) E pfr]
  show (if n ≤ gsSelOf n b E then run E (gsPreGates n b) (gsZero n b)
        else run E (gsPreGates n b) (gsRes (gsSelOf n b E) k)) = _
  by_cases hlt : gsSelOf n b E < n
  · rw [if_neg (by omega), if_pos hlt]
    exact pfr _ (gsRes_lt_in n b _ k hlt hk32)
  · rw [if_pos (by omega), if_neg hlt]
    exact pzero

/-! ### ⭐ THE ADMISSIBILITY GUARD — `n ≤ 2 ^ b`

`sem_genSelect` holds at EVERY `n` and `b`, and that generality hides a trap:
`gsSelOf` is `b` bits wide, so it ranges over `[0, 2 ^ b)` and nothing more. At
`n > 2 ^ b` the circuit is still well-formed and still correctly gate-counted —
it simply has sources `2 ^ b … n - 1` that no valuation of the select nets can
ever name, and the ALU operations sitting there are dropped in silence. No
theorem above catches that, because none of them says a source is *reachable*.

`genSelect_sources_reachable` is the missing statement, and it carries `n ≤ 2 ^ b`
as a hypothesis so an inadmissible `(n, b)` fails to elaborate at the call site
instead of losing operations quietly. -/

/-- The select valuation that names `t`: `sel[j] := bit j of t`, matching
`gsSelUpTo`'s `sel[0]`-is-LSB order. Its first `m` bits read as `t % 2 ^ m`. -/
theorem gsSelUpTo_testBit (n b t : Nat) :
    ∀ m, gsSelUpTo n b (fun x => Nat.testBit t (x - n * 32)) m = t % 2 ^ m := by
  have hsel : ∀ m : Nat, Nat.testBit t (gsSel n b m - n * 32) = Nat.testBit t m := by
    intro m
    show Nat.testBit t (n * 32 + m - n * 32) = Nat.testBit t m
    congr 1
    omega
  intro m
  induction m with
  | zero => show 0 = t % 1; omega
  | succ m ih =>
    show gsSelUpTo n b (fun x => Nat.testBit t (x - n * 32)) m
        + (if Nat.testBit t (gsSel n b m - n * 32) then 2 ^ m else 0) = t % 2 ^ (m + 1)
    rw [ih, hsel m, Nat.mod_pow_succ, ← Nat.toNat_testBit]
    cases Nat.testBit t m <;> simp

/-- ⭐⭐ **EVERY SOURCE IS REACHABLE, EXACTLY WHEN `n ≤ 2 ^ b`.** For an
admissible pair, each source `j < n` is named by some valuation of the select
nets — so no operation of `genSelect n b` is silently unreachable. The
hypothesis is load-bearing: without it the statement is FALSE (take `n = 5`,
`b = 2`, `j = 4`, where `gsSelOf 5 2 E < 4` for every `E` by
`gsSelOf_lt_pad`). -/
theorem genSelect_sources_reachable (n b : Nat) (hn : n ≤ 2 ^ b) :
    ∀ j, j < n → ∃ E : Env, gsSelOf n b E = j := by
  intro j hj
  refine ⟨fun x => Nat.testBit j (x - n * 32), ?_⟩
  show gsSelUpTo n b (fun x => Nat.testBit j (x - n * 32)) b = j
  rw [gsSelUpTo_testBit n b j b]
  exact Nat.mod_eq_of_lt (Nat.lt_of_lt_of_le hj hn)

/-- The converse half of the guard: `b` select bits can never name `2 ^ b` or
above, which is why `n > 2 ^ b` drops sources. -/
theorem gsSelOf_lt_pad (n b : Nat) (F : Env) : gsSelOf n b F < 2 ^ b := by
  show gsSelUpTo n b F b < 2 ^ b
  have : ∀ m : Nat, gsSelUpTo n b F m < 2 ^ m := by
    intro m
    induction m with
    | zero => show 0 < 1; omega
    | succ m ih =>
      show gsSelUpTo n b F m + (if F (gsSel n b m) then 2 ^ m else 0) < 2 ^ (m + 1)
      have hp : (2 : Nat) ^ (m + 1) = 2 ^ m + 2 ^ m := by
        rw [Nat.pow_succ]; omega
      split_ifs <;> omega
  exact this b

/-! ### ⭐ The guard, applied to the live pair

`genSelect_sources_reachable` is a lemma *about* admissibility; the two theorems
below make it admissibility *enforced*. Both are stated against the named
constants of `SaltWorks.HDL.AluSelect`, so a re-cut that breaks either one breaks
the BUILD rather than passing silently. -/

/-- ⭐ **ADMISSIBILITY, ENFORCED.** The live pair is `(asOps, asSelBits)`; if it is ever
re-cut to an inadmissible pair (n > 2^b) the `by decide` fails and the BUILD BREAKS.
That failure is the entire point of this theorem. -/
theorem asPair_admissible :
    ∀ j, j < asOps → ∃ E : Env, gsSelOf asOps asSelBits E = j :=
  genSelect_sources_reachable asOps asSelBits (by decide)

/-- ⭐ **THE PAD TRACKS THE WIDTH.** `asPad` and `asSelBits` are separate definitions;
nothing currently forces them to agree, so a re-cut that changes one and not the other
is silent. This makes it loud. -/
theorem asPad_eq_two_pow : asPad = 2 ^ asSelBits := by decide

#audit_axioms gsWidth_top gsWidth_of_le gsLevelWidth_two
#audit_axioms gsBelow_zero gsBelow_succ gsBelow_of_le gsBelow_top
#audit_axioms gsB gsBase_eq gsOut_eq gsB_step gsB_zero_le gsB_bit gsB_bit_mono gsB00
#audit_axioms gsSel_lt_in gsRes_lt_in gsNot_lt gsSel_lt gsZero_lt gsPrev_lt
#audit_axioms gsLeafOf gsV gsSelUpTo gsSelOf
#audit_axioms gsV_eq gsV_top gsSelUpTo_congr gsSelOf_congr gsV_top_congr
#audit_axioms gsL gsPre gsBitGates gsBodyGates gsPreGates
#audit_axioms gsPre_eq genSelect_gates_eq gsL_eq
#audit_axioms gsPrev_zero_val run_gsLevels run_gsBody run_gsPre
#audit_axioms genSelect_outs_eq sem_genSelect
#audit_axioms gsSelUpTo_testBit genSelect_sources_reachable gsSelOf_lt_pad
#audit_axioms asPair_admissible asPad_eq_two_pow

/-! ## ⭐⭐ THE THEOREM -/

/-! ### ⭐ THE PARAMETRIC SEEDS AND THE HONESTY DEVICE

The `aluSelect_*` family below is restated and reproved with **no numeral standing
for the pair `(asOps, asSelBits) = (10, 4)`**. What keeps that claim honest is the
device the parametric hinge uses: inside each `section AluSelectParametric*`,
`asW`/`asOps`/`asPad`/`asSelBits` are made **locally irreducible**, so no `rfl`,
`norm_num` or `decide` can compute its way through them. The only numeric input is
the named seed facts, harvested *before* the attribute fires.

⛔ **The device is an ELABORATOR hint, and the KERNEL ignores it.** Measured:
`asOps = 10 := by decide +kernel` SUCCEEDS under the device while `:= rfl` FAILS.
So the device certifies elaborated proofs only; a `decide +kernel` certificate is
numeral-bound whether or not it sits inside one of these sections. The sections
exist so a later edit cannot silently re-numeralize an elaborated proof — and they
are kept tight so the attribute never reaches the literal-width cross-checks
(`sem_aluSelect_direct`, `gsSelOf_ten`) or the sampled certificate layer, all of
which are numeral-bound BY DESIGN and would not elaborate under it.

*`asW`'s 32 may remain throughout: the hinge is not parametric in datapath width.* -/

section AluSelectParametric

/-- Seed 3: at least one select bit — `sem_genSelect`'s side condition.
*(Seeds 1 and 2 are already landed above: `asW_eq` and `asPad_eq_two_pow`.)* -/
theorem asSelBits_pos : 0 < asSelBits := by decide

/-- Seed 4 — ADMISSIBILITY: every source is addressable. `rsPair_admissible` is the
ruled pair's copy of this; this is the live pair's. -/
theorem asOps_le_pad : asOps ≤ asPad := by decide

/-- Seed 5: there is at least one operand slot. -/
theorem asOps_pos : 0 < asOps := by decide

/-- Seed 6 — **THE PAD IS STRICTLY WIDER THAN THE SOURCE COUNT**, so a first
padding slot `sel = asOps` always exists. True at the old pair (`10 < 16`) and at
the ruled one (`3 < 4`); it is what `asSelectsOK_fails_at_the_pad_slot` names, in
place of the retired numeral `10`. -/
theorem asOps_lt_pad : asOps < asPad := by decide

#audit_axioms asSelBits_pos asOps_le_pad asOps_pos asOps_lt_pad

attribute [local irreducible] asW asOps asPad asSelBits

/-- ⭐ **THE OUTPUT PORT LIST, PARAMETRICALLY.** The level index is `asSelBits - 1`,
not the literal `3`. *`List.range 32` here is the OUTPUT COUNT — `asW`, the datapath
width — and stays: the hinge is not parametric in width.* -/
theorem aluSelect_outs_eq :
    aluSelect.outs = (List.range 32).map (fun k => asOut k (asSelBits - 1) 0) := by
  show (List.range asW).map (fun k => asOut k (asSelBits - 1) 0) = _
  rw [asW_eq]

end AluSelectParametric

/-! ⛔ **`sem_aluSelect_direct` AND `gsSelOf_ten` WERE RETIRED AT PHASE 3, AND
THE FIRST OF THEM IS THE ONE THING THIS PHASE COSTS RATHER THAN SAVES.**

*`sem_aluSelect_direct` re-derived `sem_aluSelect` by the literal-width route —
`329 + 45*k + 42`, `pfr (320 + j)`, `< 324`, level 3 in the lemma names — and was
kept precisely because it shared nothing with the parametric one, which is a
stronger check than either alone. That route no longer exists: every lemma it
stood on bridges an `as*` constant to its old numeral and the re-cut falsifies
them. ⇒ **The independent second route is GONE; `sem_aluSelect` below is now the
only one.** `gsSelOf_ten` (`gsSelOf 10 4 E = asSelOf E`) went with it — there the
numerals WERE the statement.* -/

section AluSelectParametricSem

attribute [local irreducible] asW asOps asPad asSelBits

/-- ⭐⭐ **THE THEOREM — NOW A COROLLARY, STATED VERBATIM.** Unconditional over
all `2^324` valuations and all 32 outputs, exactly as before; what changed is
that it is no longer *where the work is*. It is `sem_genSelect` at `n = asOps`,
`b = asSelBits`, transported by `genSelect_eq_aluSelect` — **and the proof runs
under the honesty device, so not one step of it reads a `10` or a `4`.**
⇒ **Nothing downstream moves, and the sizing question below is now an
instantiation.**

*(The literal-width proof survives as `sem_aluSelect_direct` above, an independent
second route to the same statement — that one IS pinned at ten, by design.)* -/
theorem sem_aluSelect (E : Env) :
    sem aluSelect E
      = (List.range 32).map (fun k =>
          if asSelOf E < asOps then E (asRes (asSelOf E) k) else false) := by
  have h : (fun k => if gsSelOf asOps asSelBits E < asOps
                     then E (gsRes (gsSelOf asOps asSelBits E) k) else false)
         = (fun k => if asSelOf E < asOps then E (asRes (asSelOf E) k) else false) := by
    funext k
    rw [gsRes_eq]
    rfl
  rw [← genSelect_eq_aluSelect, sem_genSelect asOps asSelBits asSelBits_pos E, h]

/-! ### ⭐ THE SELECT-VALUE READER, PARAMETRICALLY

The sampled layer used to read the select through `asSelOf_of_testBit`, pinned
three ways — `sel < 16`, `j < 4`, and `asSelOf_expand`'s four-term sum finished by
`interval_cases`. This pair replaces all three with one general fact about
`gsSelOf`, assembled from the landed parametric `gsSelUpTo_congr` and
`gsSelUpTo_testBit`. ⛔ *The pinned one did NOT survive phase 3, and it is worth
being exact about why: at the ruled pair `sel < 16` admits values no two-bit
select can ever name, so the statement is FALSE there rather than merely
unproved. The sampled layer below was repointed onto `asSelOf_of_testBit'`.* -/

/-- `gsSelOf` reads back exactly the number whose bits drive the select nets —
for **every** `(n, b)`, with no numeral anywhere. -/
theorem gsSelOf_of_testBit (n b : Nat) (F : Env) (sel : Nat) (hs : sel < 2 ^ b)
    (hb : ∀ j : Nat, j < b → F (gsSel n b j) = sel.testBit j) :
    gsSelOf n b F = sel := by
  have hG : ∀ j : Nat, j < b →
      F (gsSel n b j) = (fun x => Nat.testBit sel (x - n * 32)) (gsSel n b j) := by
    intro j hj
    show F (gsSel n b j) = Nat.testBit sel (gsSel n b j - n * 32)
    rw [hb j hj]
    show sel.testBit j = Nat.testBit sel (n * 32 + j - n * 32)
    congr 1
    omega
  show gsSelUpTo n b F b = sel
  rw [gsSelUpTo_congr n b F (fun x => Nat.testBit sel (x - n * 32)) hG b (Nat.le_refl b),
    gsSelUpTo_testBit n b sel b]
  exact Nat.mod_eq_of_lt hs

/-- ⭐ The live pair's corollary, and since phase 3 the ONLY one: the hypotheses
are `sel < asPad` and `j < asSelBits`, never a numeral. -/
theorem asSelOf_of_testBit' (E : Env) (sel : Nat) (hs : sel < asPad)
    (hb : ∀ j : Nat, j < asSelBits → E (asSel j) = sel.testBit j) : asSelOf E = sel := by
  rw [asPad_eq_two_pow] at hs
  show gsSelOf asOps asSelBits E = sel
  refine gsSelOf_of_testBit asOps asSelBits E sel hs ?_
  intro j hj
  rw [gsSel_eq]
  exact hb j hj

end AluSelectParametricSem

#audit_axioms sem_aluSelect
#audit_axioms gsSelOf_of_testBit asSelOf_of_testBit'

/-! ## ⭐ WHAT THE SAMPLED CERTIFICATE ACTUALLY QUANTIFIES OVER -/

theorem getD_map_range_zero (f : Nat → Bool) : ((List.range 32).map f).getD 0 false = f 0 := by
  rw [List.getD_eq_getElem _ _ (by simp)]
  simp

/-- ⚠️ `asOneHot`'s own binder is at `Net`, and `omega` cannot read a `Net`-typed
goal; this restatement binds `n : Nat` and is what every proof below rewrites by.
*Parametric since phase 3 — it used to spell the top of the operand block as the
literal `320` and the datapath width as `32`.* -/
theorem asOneHot_eq (m sel n : Nat) :
    asOneHot m sel n
      = if n < asOps * asW then decide (m * asW ≤ n ∧ n < m * asW + asW)
        else decide (sel.testBit (n - asOps * asW)) := rfl

/-- ⚠️ *The old `j < 4` hypothesis is GONE — it was never needed: the select nets
sit above the operand block by construction, for every `j`. Same correction
`asDrive_sel` already carries.* -/
theorem asOneHot_sel (m sel j : Nat) : asOneHot m sel (asSel j) = sel.testBit j := by
  have hs : asSel j = asOps * asW + j := rfl
  rw [asOneHot_eq m sel (asSel j), hs,
    if_neg (Nat.not_lt.mpr (Nat.le_add_right (asOps * asW) j)), Nat.add_sub_cancel_left]
  simp

/-- ⚠️ *Hypothesis shape changed at phase 3: `sel < asOps` and `k < asW`, not
`sel < 10` and `k < 32`.* -/
theorem asOneHot_res (m sel k : Nat) (hs : sel < asOps) (hk : k < asW) :
    asOneHot m sel (asRes sel k) = decide (sel = m) := by
  have hk32 : k < 32 := by rw [asW_eq] at hk; exact hk
  rw [asOneHot_eq, asRes_eq, asW_eq, if_pos (show sel * 32 + k < asOps * 32 by omega),
    decide_eq_decide]
  omega

/-- ⚠️ *Hypothesis shape changed at phase 3: `m < asOps` and `sel < asPad`, not
`m < 10` and `sel < 16`.* -/
theorem asBit0_eq (m sel : Nat) (hm : m < asOps) (h : sel < asPad) :
    asBit0 m sel = decide (sel = m) := by
  show (sem aluSelect (asOneHot m sel)).getD 0 false = _
  rw [sem_aluSelect,
    asSelOf_of_testBit' _ sel h (fun j _ => asOneHot_sel m sel j), getD_map_range_zero]
  rcases Nat.lt_or_ge sel asOps with hs | hs
  · rw [if_pos hs]
    exact asOneHot_res m sel 0 hs (by rw [asW_eq]; norm_num)
  · rw [if_neg (Nat.not_lt.mpr hs)]
    exact (decide_eq_false (by omega)).symm

/-- ⭐ **THE CERTIFICATE, FOR EVERY REAL OPERAND** — `asSelectsOK` is proved at a
sample of two points; it holds at all `asOps` of them, as a corollary of
`sem_aluSelect`.

⛔ *Phase 3, TIER 4: this proof used to transcribe `asSelectsOK`'s body with the
literal `16` in it — the OLD PAD, duplicated across the seat boundary from
`AluSelect.lean`, where the definition already reads `asPad`. No pad guard could
see this copy, because it was not a constant. It reads `asPad` now.* -/
theorem asSelectsOK_of_lt (m : Nat) (hm : m < asOps) : asSelectsOK m = true := by
  show ((List.range asPad).all fun sel => asBit0 m sel == decide (sel = m)) = true
  rw [List.all_eq_true]
  intro sel hsel
  rw [beq_iff_eq]
  exact asBit0_eq m sel hm (List.mem_range.mp hsel)

/-- ⛔ **AND IT IS NOT A UNIVERSALLY TRUE STATEMENT ABOUT `m`** — at the FIRST
PADDING SLOT, `m = asOps`, `asSelectsOK` is FALSE: select value `asOps` reads the
shared tie constant, so bit 0 comes back `false` where the certificate demands
`true`. The sampled points sit inside the range where it happens to hold.

*Phase 3 restated this from the numeral-bound `asSelectsOK 10 = false`. `10` was
the old first pad slot; the re-cut moves that slot to `3`, so the numeral form is
FALSIFIED while the named form is true at both pairs — `asOps_lt_pad` is exactly
the hypothesis that makes a first pad slot exist.* -/
theorem asSelectsOK_fails_at_the_pad_slot : asSelectsOK asOps = false := by
  have h : asBit0 asOps asOps = false := by
    show (sem aluSelect (asOneHot asOps asOps)).getD 0 false = false
    rw [sem_aluSelect,
      asSelOf_of_testBit' _ asOps asOps_lt_pad (fun j _ => asOneHot_sel asOps asOps j),
      getD_map_range_zero, if_neg (Nat.lt_irrefl asOps)]
  rw [Bool.eq_false_iff]
  intro hc
  rw [show asSelectsOK asOps
        = ((List.range asPad).all fun sel => asBit0 asOps sel == decide (sel = asOps))
      from rfl, List.all_eq_true] at hc
  have hpad := hc asOps (List.mem_range.mpr asOps_lt_pad)
  rw [beq_iff_eq, h] at hpad
  simp at hpad

/-! ## ⭐ THE GENERAL DRIVER AND THE WORD BRIDGE -/

/-- **The general driver**: ten arbitrary operand results and a select value.
`asOneHot` is the sub-family in which exactly one result is live. -/
def asDrive (res : Nat → Word) (sel : Nat) : Env := fun n =>
  if n < asOps * asW then (res (n / asW)).getLsbD (n % asW)
  else decide (sel.testBit (n - asOps * asW))

section AluSelectParametricDrive

attribute [local irreducible] asW asOps asPad asSelBits

/-- The driver, unfolded with the block's own names — **no `320`, no `32`.** -/
theorem asDrive_eq (res : Nat → Word) (sel n : Nat) :
    asDrive res sel n
      = if n < asOps * asW then (res (n / asW)).getLsbD (n % asW)
        else decide (sel.testBit (n - asOps * asW)) := rfl

/-- ⚠️ *The old `j < 4` hypothesis is GONE — it was never needed: the select nets
sit above the operand block by construction, for every `j`.* -/
theorem asDrive_sel (res : Nat → Word) (sel j : Nat) :
    asDrive res sel (asSel j) = sel.testBit j := by
  have hs : asSel j = asOps * asW + j := rfl
  rw [asDrive_eq res sel (asSel j), hs,
    if_neg (Nat.not_lt.mpr (Nat.le_add_right (asOps * asW) j)), Nat.add_sub_cancel_left]
  simp

/-- ⚠️ *Hypothesis shape changed: `r < asOps` and `k < asW`, not `r < 10` and
`k < 32`.* -/
theorem asDrive_res (res : Nat → Word) (sel r k : Nat) (hr : r < asOps) (hk : k < asW) :
    asDrive res sel (asRes r k) = (res r).getLsbD k := by
  have hk32 : k < 32 := by rw [asW_eq] at hk; exact hk
  have hres : asRes r k = r * 32 + k := by show r * asW + k = _; rw [asW_eq]
  rw [asDrive_eq res sel (asRes r k), hres, asW_eq,
    if_pos (show r * 32 + k < asOps * 32 by omega),
    show (r * 32 + k) / 32 = r by omega, show (r * 32 + k) % 32 = k by omega]

/-- ⭐ **THE BLOCK IS AN `asOps`-WAY SELECT ON ARBITRARY OPERANDS** — the
certificate's one-hot family is one line of this. -/
theorem sem_aluSelect_drive (res : Nat → Word) (sel : Nat) (h : sel < asOps) :
    sem aluSelect (asDrive res sel) = (List.range 32).map (fun k => (res sel).getLsbD k) := by
  have hsel : asSelOf (asDrive res sel) = sel :=
    asSelOf_of_testBit' (asDrive res sel) sel (Nat.lt_of_lt_of_le h asOps_le_pad)
      (fun j _ => asDrive_sel res sel j)
  rw [sem_aluSelect, hsel]
  refine List.map_congr_left ?_
  intro k hk
  rw [if_pos h]
  exact asDrive_res res sel sel k h (by rw [asW_eq]; exact List.mem_range.mp hk)

/-- ⭐ **THE SELECTED OPERAND, AS A WORD** — the form a `core` assembly applies. -/
theorem aluSelect_word (res : Nat → Word) (sel : Nat) (h : sel < asOps) :
    SaltWorks.HDL.wordOf (fun k => (sem aluSelect (asDrive res sel)).getD k false) = res sel := by
  rw [sem_aluSelect_drive res sel h, wordOf_getD_map_range, wordOf_getLsbD_self]

/-- ⭐⭐ **THE `rd` FIELD, THROUGH THE SELECT.** An `ADD` presents its result in
operand slot `0` (`add` is the first of the ten) and drives `sel = 0`; the block
then delivers exactly the word `stepT` writes. ⛔ *This does NOT close any
`C4Spec` field: `core` does not exist, and this is the service the assembly would
apply, in the shape `addField_is_adder32` performs for the adder.* -/
theorem aluField_is_aluSelect_add (s : St) (rd x y : Fin 32) (hrd : rd ≠ 0)
    (res : Nat → Word) (h0 : res 0 = s.get x + s.get y) :
    (stepT (SaltWorks.HDL.decQ (envWith s (encode (Instr.ADD rd x y))))
           (seenWord (envWith s (encode (Instr.ADD rd x y))))).regs[rd.val]
      = SaltWorks.HDL.wordOf (fun k =>
          (sem aluSelect (asDrive res 0)).getD k false) := by
  rw [aluSelect_word res 0 asOps_pos, h0,
    decQ_envWith_eq, seenWord_envWith, stepT_encode]
  try simp only [step_regs_of_with_of_not_touchesMem, SaltWorks.ISA.touchesMem]
  try simp only [step_pc_of_with]
  show ((s.set rd (s.get x + s.get y)).next).regs[rd.val] = _
  show (s.set rd (s.get x + s.get y)).regs[rd.val] = _
  simp only [St.set, if_neg hrd]
  exact Vector.getElem_set_self rd.isLt

end AluSelectParametricDrive

/-! ## ⭐ THE CONTROLS -/

/-! ## ⭐ THE CONTROLS

⛔⛔ **THE `aluSelectCut` MUTATION CONTROL WAS RETIRED AT PHASE 3, AND NOTHING
REPLACES IT AT THE LIVE PAIR. THIS IS A LOSS, RECORDED RATHER THAN PAPERED OVER.**

*What stood here: `asMuxCut` (bit 0's level-0 mux at position `i = 2`, rewired to
read leaf 4 on both inputs), `aluSelectCut`, `asBit0Cut`, `asSelectsOKCut`, and
six theorems — `asMuxCut_site_exists` (the differing-position count is `1`),
`asMuxCut_witness_exists` (`5 < asOps ∧ 5 < asPad`), `aluSelectCut_ssa`,
`aluSelectCut_gate_count` (`= 1445`), `aluSelectCut_is_one_gate` (`= 1`),
`aluSelectCut_passes_the_certificate` (`asSelectsOKCut 3` and `9`), and
`aluSelectCut_fails_the_theorem` (`asSelectsOKCut 5 = false ∧ asSelectsOK 5 =
true`). Its content was: A MUTANT CAN PASS THE SAMPLED CERTIFICATE AND STILL BE
REFUTED BY THE ORGAN THEOREM — the argument for proving rather than sampling.*

⛔ **Why it cannot be repaired at `(asOps, asSelBits, asPad) = (3, 2, 4)`.** The
site is at `i = 2` and level 0 holds only `asPad / 2 = 2` muxes there, so the
site is outside the level and the "mutant" is the original, gate for gate — the
count goes to `0` and `aluSelectCut_gate_count`'s `1445` goes to `291`. Re-siting
does not rescue it and the reason is structural, not a failure of effort:

* the refuting witness `m = 5` needs operand `5` to be REAL and select value `5`
  to be REACHABLE; at three sources over a two-bit select, neither is;
* the surviving sample is `{0, asOps - 1}` = `{0, 2}` out of three real operands,
  so only `m = 1` is unsampled. Every admissible one-gate site is visible at a
  SAMPLED point: level-0 `i = 0` rewires leaf 1 to leaf 0 and shows at `m ∈ {0,1}`;
  level-0 `i = 1` rewires the pad leaf 3 to leaf 2 and shows at `m = 2`; level-1
  `i = 0` collapses the high half and shows at `m = 0`.

⇒ **A mutant that passes the sample and fails the theorem does not exist at the
ruled pair** — sampling two of three operands leaves almost nothing to hide in.
Re-siting would be a re-witnessing, i.e. a statement change, not a repair.

⭐ **WHAT SURVIVES, AND THE RULED WIDTH IS COVERED.** Three controls carry the
job, all of them flip-inert because all of them are stated against literals
rather than against `asOps`/`asSelBits`/`asPad`:

* ⭐ `SelectCut32.mutLeafCut_fails_cert` — **the mutation control AT THE RULED
  SELECT'S OWN WIDTH.** `mutLeafCut` is the one-gate mutant of
  `sliceASelect = genSelect 3 2`, refuted against the whole-list spec `Cert`. It
  was written for the ruled block and it does not care what `asOps` becomes.
  *MEASURED: it elaborates and ticks with the flip applied.*
* `genSelectCut2_fails_the_theorem` below — the identical mutation at `n = 2,
  b = 1`, the ADDI operand-B mux.
* `pcAddCut_fails_the_theorem` / `pcAddCutB_fails_the_theorem` — the PC adder.

⇒ **What is lost is this particular mutant, not mutation coverage of the select.**
`aluSelectCut` was the control for a TEN-source block, and at three sources over
a two-bit select there is nothing left to hide from a two-point sample — the
coverage moved to `SelectCut32`, where it was written against the ruled pair from
the start. -/

/-- An operand picture NO `asOneHot` driver can produce: **two operand results
live at once**. -/
def asOffEnv : Env := fun n =>
  if n < asOps * asW then decide (n % 2 = 0) else decide (n = asSel 1)

theorem asOffEnv_eq (n : Nat) :
    asOffEnv n
      = if n < asOps * asW then decide (n % 2 = 0) else decide (n = asSel 1) := rfl

/-- ⭐ **THE THEOREM REACHES WHERE THE CERTIFICATE'S DRIVER CANNOT GO.** -/
theorem sem_aluSelect_off_the_sample :
    asOffEnv (asRes 0 0) = true ∧ asOffEnv (asRes 2 0) = true
      ∧ (∀ m sel : Nat,
          ¬(asOneHot m sel (asRes 0 0) = true ∧ asOneHot m sel (asRes 2 0) = true))
      ∧ sem aluSelect asOffEnv = (List.range 32).map (fun k => decide (k % 2 = 0)) := by
  refine ⟨by decide, by decide, ?_, ?_⟩
  · rintro m sel ⟨h1, h2⟩
    rw [asOneHot_eq, asRes_eq, asW_eq, if_pos (by decide), decide_eq_true_eq] at h1
    rw [asOneHot_eq, asRes_eq, asW_eq, if_pos (by decide), decide_eq_true_eq] at h2
    omega
  · rw [sem_aluSelect, show asSelOf asOffEnv = 2 from by decide]
    have h2ops : (2 : Nat) < asOps := by decide
    refine List.map_congr_left ?_
    intro k hk
    have hk32 : k < 32 := List.mem_range.mp hk
    rw [if_pos h2ops, asOffEnv_eq, asRes_eq, asW_eq, if_pos (by omega), decide_eq_decide]
    omega

/-! ## ⭐⭐⭐ THE TWO SHRUNK INSTANCES — WHAT THE PARAMETRISATION BUYS

*Both are `sem_genSelect` with `n` and `b` filled in. Neither needed a line of
new proof, which is the whole claim of the exercise.*

### Where the mutation control lives now

⛔ **`aluSelectCut` DIED AT PHASE 3** (see the retirement note above: at three
sources over a two-bit select there is no one-gate mutant that passes the sample
and fails the theorem). **`genSelectCut2` below is what carries the control**, and
it always could: it is the same mutation at `n = 2`, stated against literals, so
it is refuted at its own size rather than by inheritance from the ten-source
block — and it is INERT under a re-cut of `(asOps, asSelBits, asPad)`.

⭐ *That is the parametrisation paying twice: the shrunk instances cost no proof,
and the control that survives the shrink is the one that was never written at the
live pair's width.* -/

/-! ### `n = 2` — THE ADDI OPERAND-B MUX -/

theorem gsSelOf_two (E : Env) : gsSelOf 2 1 E = if E (gsSel 2 1 0) then 1 else 0 := by
  show 0 + (if E (gsSel 2 1 0) then 2 ^ 0 else 0) = _
  norm_num

/-- ⭐⭐ **THE OPERAND-B MUX ORGAN THEOREM.** The one select net picks between the
two 32-bit sources, at every one of the `2^65` valuations and on all 32 outputs.
*Silicon established and the compiler seat checked (`f61f023`) that the `n = 2`
row IS this mux — same generator, same three-gate cell, same shared inverter — so
it inherits the proof rather than needing one, and one of the two unbuilt blocks
on C4's critical path stops being unbuilt.* ⚠️ **`n = 2 = 2^1` means there are no
padding leaves: the `else false` arm of `sem_genSelect` is unreachable here, and
the tie constant is a dead net.** -/
theorem sem_operandBMux (E : Env) :
    sem (genSelect 2 1) E
      = (List.range 32).map (fun k =>
          if E (gsSel 2 1 0) then E (gsRes 1 k) else E (gsRes 0 k)) := by
  rw [sem_genSelect 2 1 (by norm_num) E]
  refine List.map_congr_left ?_
  intro k _
  rw [gsSelOf_two]
  cases h : E (gsSel 2 1 0) <;> norm_num

/-- Two words on the two source buses, the select on net `64`. -/
def gsDrive2 (x y : Word) (s : Bool) : Env := fun m =>
  if m < 32 then x.getLsbD m else if m < 64 then y.getLsbD (m - 32) else s

/-- ⭐ **THE SELECTED OPERAND, AS A WORD** — the form a `core` assembly applies,
the shape `aluSelect_word` performs for the ten-source block. -/
theorem operandBMux_word (x y : Word) (s : Bool) :
    SaltWorks.HDL.wordOf (fun k => (sem (genSelect 2 1) (gsDrive2 x y s)).getD k false)
      = if s then y else x := by
  rw [sem_operandBMux, wordOf_getD_map_range]
  have hsel : gsDrive2 x y s (gsSel 2 1 0) = s := rfl
  rw [hsel]
  cases s
  · show SaltWorks.HDL.wordOf (fun k => gsDrive2 x y false (gsRes 0 k)) = x
    have h : ∀ k : Nat, k < 32 → gsDrive2 x y false (gsRes 0 k) = x.getLsbD k := by
      intro k hk
      show (if 0 * 32 + k < 32 then x.getLsbD (0 * 32 + k)
            else if 0 * 32 + k < 64 then y.getLsbD (0 * 32 + k - 32) else false) = x.getLsbD k
      rw [if_pos (by omega), show 0 * 32 + k = k from by omega]
    rw [wordOf_congr h]
    exact wordOf_getLsbD_self x
  · show SaltWorks.HDL.wordOf (fun k => gsDrive2 x y true (gsRes 1 k)) = y
    have h : ∀ k : Nat, k < 32 → gsDrive2 x y true (gsRes 1 k) = y.getLsbD k := by
      intro k hk
      show (if 1 * 32 + k < 32 then x.getLsbD (1 * 32 + k)
            else if 1 * 32 + k < 64 then y.getLsbD (1 * 32 + k - 32) else true) = y.getLsbD k
      rw [if_neg (by omega), if_pos (by omega), show 1 * 32 + k - 32 = k from by omega]
    rw [wordOf_congr h]
    exact wordOf_getLsbD_self y

/-! ### The mutation control at the NEW width -/

/-- ⛔ **ONE GATE MUTATED** in the `n = 2` instance: bit 0's only mux reads leaf
`0` on both of its inputs, so source 1 is unreachable at bit 0. Still `ssa`,
still 98 gates. -/
def gsMuxCut2 (k j i : Nat) : List Gate :=
  if k == 0 && j == 0 && i == 0 then
    [⟨gsBase 2 1 k j i,     .and (gsPrev 2 1 k j (2 * i)) (gsNot 2 1 j)⟩,
     ⟨gsBase 2 1 k j i + 1, .and (gsPrev 2 1 k j (2 * i)) (gsSel 2 1 j)⟩,
     ⟨gsOut 2 1 k j i,      .or (gsBase 2 1 k j i) (gsBase 2 1 k j i + 1)⟩]
  else gsMux 2 1 k j i

def genSelectCut2 : Circ :=
  { genSelect 2 1 with
    gates :=
      (⟨gsZero 2 1, .const false⟩ : Gate)
        :: (List.range 1).map (fun j => (⟨gsNot 2 1 j, .not (gsSel 2 1 j)⟩ : Gate))
        ++ (List.range 32).flatMap fun k =>
             (List.range 1).flatMap fun j =>
               (List.range (gsLevelWidth 1 j)).flatMap (gsMuxCut2 k j) }

theorem genSelectCut2_ssa : genSelectCut2.ssa = true := by decide +kernel
theorem genSelectCut2_gate_count : genSelectCut2.gates.length = 98 := by decide +kernel

/-- ⭐ **EXACTLY ONE GATE DIFFERS.** -/
theorem genSelectCut2_is_one_gate :
    (List.zip genSelectCut2.gates (genSelect 2 1).gates).countP (fun p => p.1 != p.2) = 1 := by
  decide +kernel

/-- Source 1 alone live at bit 0, select high. -/
def gsOffEnv2 : Env := fun m => decide (m = 32 ∨ m = 64)

/-- ⭐ **AND THE ORGAN THEOREM REFUTES IT AT ITS OWN WIDTH** — the mutant answers
`false` where `sem_operandBMux` forces `true`. -/
theorem genSelectCut2_fails_the_theorem :
    (sem genSelectCut2 gsOffEnv2).getD 0 false = false
      ∧ (sem (genSelect 2 1) gsOffEnv2).getD 0 false = true := by
  refine ⟨by decide +kernel, ?_⟩
  rw [sem_operandBMux, getD_map_range_zero, if_pos (by decide)]
  decide

/-! ### `n = 3` — SLICE A'S ALU SELECT `{add, xor, slt}` -/

theorem gsSelOf_three (E : Env) :
    gsSelOf 3 2 E = (if E (gsSel 3 2 0) then 1 else 0) + (if E (gsSel 3 2 1) then 2 else 0) := by
  show 0 + (if E (gsSel 3 2 0) then 2 ^ 0 else 0) + (if E (gsSel 3 2 1) then 2 ^ 1 else 0) = _
  norm_num

/-- ⭐⭐ **SLICE A'S ALU SELECT, SPELLED OUT.** Three real sources and one padding
slot: select `3` reads the tie constant and every output bit is `false`. That
last arm is the behaviour the padding design decision is responsible for, and it
is proved here rather than sampled. **−1,154 gates against the ten-source block,
and the shrink cost no proof.** -/
theorem sem_sliceASelect (E : Env) :
    sem (genSelect 3 2) E
      = (List.range 32).map (fun k =>
          if E (gsSel 3 2 1) then (if E (gsSel 3 2 0) then false else E (gsRes 2 k))
          else (if E (gsSel 3 2 0) then E (gsRes 1 k) else E (gsRes 0 k))) := by
  rw [sem_genSelect 3 2 (by norm_num) E]
  refine List.map_congr_left ?_
  intro k _
  rw [gsSelOf_three]
  cases h0 : E (gsSel 3 2 0) <;> cases h1 : E (gsSel 3 2 1) <;> norm_num

#audit_axioms gsSelOf_two sem_operandBMux gsDrive2 operandBMux_word
#audit_axioms gsMuxCut2 genSelectCut2 genSelectCut2_ssa genSelectCut2_gate_count
#audit_axioms genSelectCut2_is_one_gate gsOffEnv2 genSelectCut2_fails_the_theorem
#audit_axioms gsSelOf_three sem_sliceASelect

end AluSelectSemantics

/-! ## ⭐⭐ READTREE — THE REGISTER READ PORT, UNCONDITIONALLY

**A sampled certificate is a tripwire; C4 rests on organ theorems.** `readTree`
is the register-file READ PATH — the block `ReadTree.lean:30` calls the place
where *"the whole difficulty of the register file — verification and area —
lives"*, and the second-most-consumed unproved block in the tower.

## ⚠️ WHAT `rtSelectsOK` AND `readTree_x0_is_zero` QUANTIFY OVER, MEASURED

*Read before assuming either was already general. Neither is, and the shape is
`asSelectsOK`'s exactly: EXHAUSTIVE IN ONE ARGUMENT AND SILENT ABOUT THE REST.*

```
readTree.nIn = 997                    ⇒ 2^997 input valuations
readTree.outs.length = 32             ⇒ 32 output bits, one 32:1 tree each

rtSelectsOK m = (List.range 32).all fun a => rtBit0 m a == decide (a ≠ m ∧ a ≠ 0)
  a    THE ADDRESS   EXHAUSTIVE — all 32, and five address bits IS 32, so total
  m    THE CONTENTS  TWO POINTS (7, 19), each a ONE-COLD file: all-ones but x_m
  bit  THE PORT      rtBit0 = (sem …).getD 0 — OUTPUT BIT 0 AND NOTHING ELSE

readTree_x0_is_zero = rtBit0 7 0 = false ∧ rtBit0 19 0 = false
  ⇒ literally TWO POINTS: address 0 fixed, two file contents, one output bit.
```

⛔ **`readTree_x0_is_zero` READS AS A TOTAL ISA CLAIM AND IS TWO POINTS.**
`St.get_zero` is unconditional in the state and holds at every bit; the circuit's
version was pinned at two one-cold files and bit 0. **Between them the four
standing certificates drive 64 of `2^997` valuations, and 1 of the 32 outputs.**

📌 **AND THAT IS NOT A HYPOTHETICAL GAP — the two one-gate mutants at the foot of
this section exploit it, and the certificate accepts both.** `readTreeCutB` ties
the ROOT of output bit **1**'s tree low: every check in `ReadTree.lean` passes
unchanged, because none of them ever reads output 1. `readTreeCutA` makes address
3 read `x2`, and the certificates pass because at `m = 7` and `m = 19` registers
2 and 3 hold the same word.

## ⭐ WHAT LANDS

* `sem_readTree_uncond` — **the organ theorem, with no driver at all**: for EVERY
  valuation of the 997 input nets, `sem readTree E` is the 32 bits of the
  register the five address nets name, and `false` at every bit when they name
  `x0`. The address is read off the valuation by `rtSel`, so nothing is pinned.
* `sem_readTree` / `sem_readTree_St` — the same statement through a driver, then
  through the ISA: **the port IS `St.get`**, every state, every register, every
  bit.
* `readTree_reads_x0_zero` — ⭐ `readTree_x0_is_zero` **at every file contents and
  on all 32 output bits**, as a corollary of `St.get_zero` rather than a sample.
* `rtSelectsOK_uncond` — ⭐ **the sampled certificate is now a COROLLARY, at all
  31 stored registers rather than two**, via `rtOneCold_eq`: the one-cold driver
  is `rtEnvOf` at one particular file, so the organ theorem SUPERSEDES the
  certificate instead of restating it.
* `rtWord_is_get` — the consumer bridge in the shape a `core` assembly applies.

⛔ **NO `C4Spec` FIELD IS CLOSED BY THIS, and the shape of the debt is the
adder's.** A register-field claim is about a whole `core`'s output bits, and no
`core` exists. *The debt is `core`, not `readTree`.*

## What transferred from the landed organs, and what did not

⭐ **`run_pointwise` transferred EXACTLY ONCE, and there it was an exact fit**:
the five SHARED inverters are `(List.range 5).map fun j => ⟨998 + j, .not j⟩`,
which is the pointwise shape on the nose (`rtInvGates`).

⛔ **`sem_pcNext`'s OR-chain did NOT transfer, and neither did its mux array.**
Measured against `ReadTree.lean`'s gates rather than assumed:

* **There is no OR chain.** `readTree`'s 992 `or` gates are each the THIRD gate
  of a mux, never a fold — `orChain` appears nowhere in `ReadTree.lean`, so
  `run_orChain` has nothing to apply to.
* **`run_pcAddGates` is the wrong shape for a tree.** `pcNext`'s mux array is 32
  INDEPENDENT one-gate selects off one shared control net, so its induction needs
  only a frame over a flat list. `readTree` is a 5-deep TREE: level `n+1`'s
  outputs ARE level `n`'s inputs, so the induction must carry the input-NAMING
  function forward (`run_rtLevels` quantifies over `f : Nat → Nat`) and prove the
  new names lie below the new base. That obligation does not exist in `pcNext`.
* **No adder, so no carry** — as with `pcNext`, and for the same reason.

⇒ ***What transferred is the METHOD — a frame lemma plus an induction carrying an
invariant — together with `run_of_unwritten`, `run_append` and `sem_congr`
themselves.*** **What is new and reusable is
`run_rtMux`/`run_rtLevel`/`run_rtLevels`: a MUX-TREE induction, generic in the
leaf-naming function and in the base net**, which a crossbar or a barrel shifter
built the same way would inherit.

⚠️ **`decide` IS NOT AVAILABLE HERE AND THAT IS THE DESIGN CONSTRAINT.**
`readTree` reads a 32×32 file: `2^1024` file contents. Every step below is
structural, and the only `decide +kernel` in this section is on the two mutants,
where the circuits are closed terms.

⛔ **THE `Net` TRAP FIRED THREE MORE TIMES**, each on a goal whose head was
`rtZero`, `rtNotSel jj`, or an element of a `List Net`: `omega` DROPPED THE GOAL
and reported a counterexample derived from the hypotheses alone. Every fix is the
same — `show` the goal at `Nat` with the constants spelled out (`rtReg_lt`,
`run_rtLevels`'s `hnsb`, `run_rtBits`'s head-of-list step).
-/

section ReadTreeSemantics

open SaltWorks.HDL hiding seenWord

/-! ## Net-arithmetic mirrors (the `Net` trap: everything below is `Nat`-bound) -/

theorem rtIn_eq : rtIn = 997 := by decide +kernel

theorem rtZero_eq : rtZero = 997 := by decide +kernel

theorem rtNotSel_eq (j : Nat) : rtNotSel j = 998 + j := by
  show rtIn + 1 + j = 998 + j
  rw [rtIn_eq]

theorem rtReg_lt (i k : Nat) (hi : i < 32) (hk : k < 32) : rtReg i k < 998 := by
  unfold rtReg
  split
  · rw [rtZero_eq]; decide
  · show (5 : Nat) + (i - 1) * 32 + k < 998
    omega

theorem rtReg_ne (i k : Nat) (hi : 1 ≤ i) : rtReg i k = 5 + (i - 1) * 32 + k := by
  show (if i == 0 then rtZero else rtAddrBits + (i - 1) * rtWidth + k) = _
  rw [if_neg (by simp; omega)]
  rfl

theorem rtReg_lt_stored (i k : Nat) (hi : 1 ≤ i) (hi2 : i < 32) (hk : k < 32) :
    rtReg i k < 997 := by
  rw [rtReg_ne i k hi]
  show (5 : Nat) + (i - 1) * 32 + k < 997
  omega

/-! ## The address value a valuation carries on nets `lo … lo+n-1`, LSB first -/

def rtSel (E : Env) (lo : Nat) : Nat → Nat
  | 0     => 0
  | n + 1 => (if E lo then 1 else 0) + 2 * rtSel E (lo + 1) n

theorem rtSel_succ (E : Env) (lo n : Nat) :
    rtSel E lo (n + 1) = (if E lo then 1 else 0) + 2 * rtSel E (lo + 1) n := rfl

theorem rtSel_lt (E : Env) : ∀ (n lo : Nat), rtSel E lo n < 2 ^ n := by
  intro n
  induction n with
  | zero => intro lo; show 0 < 1; norm_num
  | succ n ih =>
    intro lo
    have h := ih (lo + 1)
    have hp : (2 : Nat) ^ (n + 1) = 2 * 2 ^ n := by rw [Nat.pow_succ]; omega
    rw [rtSel_succ, hp]
    split <;> omega

theorem rtSel_congr {E E' : Env} (h : ∀ m : Nat, m < 5 → E' m = E m) :
    ∀ (n lo : Nat), lo + n ≤ 5 → rtSel E' lo n = rtSel E lo n := by
  intro n
  induction n with
  | zero => intro lo _; rfl
  | succ n ih =>
    intro lo hlo
    rw [rtSel_succ, rtSel_succ, h lo (by omega), ih (lo + 1) (by omega)]

theorem rtSel_testBit (a : Nat) : ∀ (n lo : Nat),
    rtSel (fun i => a.testBit i) lo n = a / 2 ^ lo % 2 ^ n := by
  intro n
  induction n with
  | zero => intro lo; show 0 = _; rw [Nat.pow_zero, Nat.mod_one]
  | succ n ih =>
    intro lo
    have hd : a / 2 ^ (lo + 1) = a / 2 ^ lo / 2 := by
      rw [Nat.div_div_eq_div_mul, ← Nat.pow_succ]
    have hb : (if (fun i => a.testBit i) lo then (1 : Nat) else 0) = a / 2 ^ lo % 2 := by
      show (if a.testBit lo then (1 : Nat) else 0) = _
      rw [Nat.testBit_eq_decide_div_mod_eq]
      have h2 : a / 2 ^ lo % 2 < 2 := Nat.mod_lt _ (by norm_num)
      by_cases hh : a / 2 ^ lo % 2 = 1
      · simp [hh]
      · simp [hh]; omega
    rw [rtSel_succ, ih (lo + 1), hd, hb]
    generalize hx : a / 2 ^ lo = x
    have hM : 0 < (2 : Nat) ^ n := Nat.one_le_two_pow
    have hp : (2 : Nat) ^ (n + 1) = 2 * 2 ^ n := by rw [Nat.pow_succ]; omega
    rw [hp]
    have h1 : x = 2 * 2 ^ n * (x / 2 / 2 ^ n) + (2 * (x / 2 % 2 ^ n) + x % 2) := by
      conv_lhs => rw [← Nat.div_add_mod x 2, ← Nat.div_add_mod (x / 2) (2 ^ n)]
      ring
    have h2 : 2 * (x / 2 % 2 ^ n) + x % 2 < 2 * 2 ^ n := by
      have ha := Nat.mod_lt (x / 2) hM
      have hb2 := Nat.mod_lt x (show 0 < 2 by norm_num)
      omega
    have hkey : x % (2 * 2 ^ n) = 2 * (x / 2 % 2 ^ n) + x % 2 := by
      conv_lhs => rw [h1]
      rw [Nat.mul_add_mod]
      exact Nat.mod_eq_of_lt h2
    rw [hkey]
    omega

theorem sel_bit (c : Bool) (F : Nat → Bool) (S : Nat) :
    (if c then F (2 * S + 1) else F (2 * S)) = F ((if c then 1 else 0) + 2 * S) := by
  cases c
  · show F (2 * S) = F (0 + 2 * S)
    exact congrArg F (by omega)
  · show F (2 * S + 1) = F (1 + 2 * S)
    exact congrArg F (by omega)

/-! ## `rtLevel` — one level of the mux tree -/

theorem rtLevel_nil (s ns b : Nat) : rtLevel s ns b [] = ([], [], b) := rfl

theorem rtLevel_cons2 (s ns b x y : Nat) (rest : List Net) :
    rtLevel s ns b (x :: y :: rest)
      = (rtMux b x y s ns ++ (rtLevel s ns (b + 3) rest).1,
         (b + 2) :: (rtLevel s ns (b + 3) rest).2.1,
         (rtLevel s ns (b + 3) rest).2.2) := rfl

/-- One 2:1 mux. **`x` and `ns` need no bound**: the first gate reads them from
the incoming valuation, before anything has been written. -/
theorem run_rtMux (E : Env) (b x y s ns : Nat) (hy : y < b) (hs : s < b) :
    (∀ m : Nat, m < b → run E (rtMux b x y s ns) m = E m)
    ∧ run E (rtMux b x y s ns) (b + 2) = ((E x && E ns) || (E y && E s)) := by
  refine ⟨fun m hm => run_of_unwritten E _ m (fun g hg => ?_), ?_⟩
  · simp only [rtMux, List.mem_cons, List.not_mem_nil, or_false] at hg
    rcases hg with rfl | rfl | rfl
    · show b ≠ m; omega
    · show b + 1 ≠ m; omega
    · show b + 2 ≠ m; omega
  · have h3 : y ≠ b := by omega
    have h4 : s ≠ b := by omega
    simp [rtMux, Op.eval, upd, h3, h4]

theorem range_map_two (n : Nat) (f : Nat → Nat) :
    (List.range (n + 2)).map f = f 0 :: f 1 :: (List.range n).map (fun i => f (i + 2)) := by
  rw [show n + 2 = (n + 1) + 1 from rfl, List.range_succ_eq_map, List.map_cons,
    List.map_map, List.range_succ_eq_map, List.map_cons, List.map_map]
  rfl

/-- **One level of the tree, over `2 * m` inputs named by `f`.** -/
theorem run_rtLevel (s ns : Nat) :
    ∀ (m b : Nat) (f : Nat → Nat) (E : Env),
      (∀ i : Nat, i < 2 * m → f i < b) → s < b → ns < b → E ns = !(E s) →
      ((rtLevel s ns b ((List.range (2 * m)).map f)).2.1
          = (List.range m).map (fun p => b + 3 * p + 2))
      ∧ ((rtLevel s ns b ((List.range (2 * m)).map f)).2.2 = b + 3 * m)
      ∧ (∀ n : Nat, n < b →
          run E (rtLevel s ns b ((List.range (2 * m)).map f)).1 n = E n)
      ∧ (∀ p : Nat, p < m →
          run E (rtLevel s ns b ((List.range (2 * m)).map f)).1 (b + 3 * p + 2)
            = (if E s then E (f (2 * p + 1)) else E (f (2 * p)))) := by
  intro m
  induction m with
  | zero =>
    intro b f E _ _ _ _
    refine ⟨?_, ?_, ?_, ?_⟩
    · simp [rtLevel_nil]
    · simp [rtLevel_nil]
    · intro n _; simp [rtLevel_nil]
    · intro p hp; exact absurd hp (Nat.not_lt_zero p)
  | succ m ih =>
    intro b f E hf hs hns hE
    have hx : f 0 < b := hf 0 (by omega)
    have hy : f 1 < b := hf 1 (by omega)
    obtain ⟨hmfr, hmval⟩ := run_rtMux E b (f 0) (f 1) s ns hy hs
    have h2m : 2 * (m + 1) = 2 * m + 2 := by omega
    have hf' : ∀ i : Nat, i < 2 * m → (fun i => f (i + 2)) i < b + 3 := by
      intro i hi
      have := hf (i + 2) (by omega)
      show f (i + 2) < b + 3
      omega
    have hE' : run E (rtMux b (f 0) (f 1) s ns) ns
        = !(run E (rtMux b (f 0) (f 1) s ns) s) := by
      rw [hmfr ns hns, hmfr s hs]; exact hE
    obtain ⟨ho, hb', hfr, hval⟩ :=
      ih (b + 3) (fun i => f (i + 2)) (run E (rtMux b (f 0) (f 1) s ns))
        hf' (by omega) (by omega) hE'
    rw [h2m, range_map_two, rtLevel_cons2]
    refine ⟨?_, ?_, ?_, ?_⟩
    · rw [ho, List.range_succ_eq_map, List.map_cons, List.map_map]
      refine congrArg₂ List.cons (by omega) (List.map_congr_left (fun p _ => by
        show b + 3 + 3 * p + 2 = b + 3 * (p + 1) + 2
        omega))
    · rw [hb']; omega
    · intro n hn
      rw [run_append, hfr n (by omega), hmfr n hn]
    · intro p hp
      rw [run_append]
      match p with
      | 0 =>
        rw [show b + 3 * 0 + 2 = b + 2 from by omega, hfr (b + 2) (by omega), hmval, hE]
        show _ = if E s then E (f 1) else E (f 0)
        cases hEs : E s <;> simp
      | q + 1 =>
        have hq : q < m := by omega
        rw [show b + 3 * (q + 1) + 2 = b + 3 + 3 * q + 2 from by omega, hval q hq,
          hmfr s hs, hmfr (f (2 * q + 1 + 2)) (hf _ (by omega)),
          hmfr (f (2 * q + 2)) (hf _ (by omega))]
        show (if E s then E (f (2 * q + 1 + 2)) else E (f (2 * q + 2))) = _
        rw [show 2 * q + 1 + 2 = 2 * (q + 1) + 1 from by omega,
          show 2 * q + 2 = 2 * (q + 1) from by omega]

/-! ## `rtLevels` — the folded tree -/

theorem rtLevels_zero (b : Nat) (ins : List Net) : rtLevels 0 b ins = ([], ins, b) := rfl

/-- The level `rtLevels (n+1)` runs first: it selects on address bit `5 - (n+1)`. -/
def rtLevAt (n b : Nat) (ins : List Net) : List Gate × List Net × Nat :=
  rtLevel (5 - (n + 1)) (rtNotSel (5 - (n + 1))) b ins

theorem rtLevels_succ (n b : Nat) (ins : List Net) :
    rtLevels (n + 1) b ins
      = ((rtLevAt n b ins).1 ++ (rtLevels n (rtLevAt n b ins).2.2 (rtLevAt n b ins).2.1).1,
         (rtLevels n (rtLevAt n b ins).2.2 (rtLevAt n b ins).2.1).2.1,
         (rtLevels n (rtLevAt n b ins).2.2 (rtLevAt n b ins).2.1).2.2) := rfl

/-- **The whole `n`-level tree over `2^n` inputs named by `f`.** -/
theorem run_rtLevels : ∀ (n : Nat), n ≤ 5 → ∀ (b : Nat) (f : Nat → Nat) (E : Env),
    1003 ≤ b → (∀ i : Nat, i < 2 ^ n → f i < b) →
    (∀ j : Nat, j < 5 → E (998 + j) = !(E j)) →
    ((rtLevels n b ((List.range (2 ^ n)).map f)).2.1
        = [if n = 0 then f 0 else b + (3 * 2 ^ n - 4)])
    ∧ ((rtLevels n b ((List.range (2 ^ n)).map f)).2.2 = b + 3 * (2 ^ n - 1))
    ∧ (∀ m : Nat, m < b → run E (rtLevels n b ((List.range (2 ^ n)).map f)).1 m = E m)
    ∧ (run E (rtLevels n b ((List.range (2 ^ n)).map f)).1
          ((rtLevels n b ((List.range (2 ^ n)).map f)).2.1.headD 0)
        = E (f (rtSel E (5 - n) n))) := by
  intro n
  induction n with
  | zero =>
    intro _ b f E _ hf _
    refine ⟨?_, ?_, ?_, ?_⟩
    · simp [rtLevels_zero]
    · simp [rtLevels_zero]
    · intro m _; simp [rtLevels_zero]
    · simp [rtLevels_zero]
      rfl
  | succ n ih =>
    intro hn5 b f E hb hf hinv
    have hn : n ≤ 5 := by omega
    have hK : (1 : Nat) ≤ 2 ^ n := Nat.one_le_two_pow
    have hp : (2 : Nat) ^ (n + 1) = 2 * 2 ^ n := by rw [Nat.pow_succ]; omega
    have hjlt : 5 - (n + 1) < 5 := by omega
    have hjb : 5 - (n + 1) < b := by omega
    have hnsb : rtNotSel (5 - (n + 1)) < b := by
      rw [rtNotSel_eq]
      show (998 : Nat) + (5 - (n + 1)) < b
      omega
    have hjE : E (rtNotSel (5 - (n + 1))) = !(E (5 - (n + 1))) := by
      rw [rtNotSel_eq]; exact hinv _ hjlt
    obtain ⟨hLo, hLb, hLfr, hLval⟩ :=
      run_rtLevel (5 - (n + 1)) (rtNotSel (5 - (n + 1))) (2 ^ n) b f E
        (fun i hi => hf i (by omega)) hjb hnsb hjE
    have hAt : rtLevAt n b ((List.range (2 * 2 ^ n)).map f)
        = rtLevel (5 - (n + 1)) (rtNotSel (5 - (n + 1))) b ((List.range (2 * 2 ^ n)).map f) := rfl
    rw [← hAt] at hLo hLb hLfr hLval
    obtain ⟨hRo, hRb, hRfr, hRval⟩ :=
      ih hn (b + 3 * 2 ^ n) (fun p => b + 3 * p + 2)
        (run E (rtLevAt n b ((List.range (2 * 2 ^ n)).map f)).1)
        (by omega)
        (fun i hi => by show b + 3 * i + 2 < b + 3 * 2 ^ n; omega)
        (fun jj hjj => by
          rw [hLfr (998 + jj) (by omega), hLfr jj (by omega)]; exact hinv jj hjj)
    have hins : (List.range (2 ^ (n + 1))).map f = (List.range (2 * 2 ^ n)).map f := by rw [hp]
    rw [hins, rtLevels_succ, hLo, hLb]
    refine ⟨?_, ?_, ?_, ?_⟩
    · rw [hRo, if_neg (show ¬(n + 1 = 0) by omega)]
      by_cases h0 : n = 0
      · subst h0
        norm_num
      · rw [if_neg h0]
        have h2K : (2 : Nat) ≤ 2 ^ n := by
          calc (2 : Nat) = 2 ^ 1 := by norm_num
          _ ≤ 2 ^ n := Nat.pow_le_pow_right (by norm_num) (by omega)
        congr 1
        rw [hp]
        omega
    · rw [hRb, hp]; omega
    · intro m hm
      rw [run_append, hRfr m (by omega), hLfr m hm]
    · rw [run_append, hRval]
      have hsel : rtSel (run E (rtLevAt n b ((List.range (2 * 2 ^ n)).map f)).1) (5 - n) n
          = rtSel E (5 - n) n :=
        rtSel_congr (fun m hm => hLfr m (by omega)) n (5 - n) (by omega)
      show run E (rtLevAt n b ((List.range (2 * 2 ^ n)).map f)).1
          (b + 3 * rtSel (run E (rtLevAt n b ((List.range (2 * 2 ^ n)).map f)).1) (5 - n) n + 2)
        = E (f (rtSel E (5 - (n + 1)) (n + 1)))
      rw [hsel, hLval _ (rtSel_lt E n (5 - n)), rtSel_succ,
        show 5 - (n + 1) + 1 = 5 - n from by omega]
      exact sel_bit _ (fun z => E (f z)) _

/-! ## `rtBit` — one output bit's 32:1 tree -/

theorem rtBit_gates (k b : Nat) :
    (rtBit k b).1 = (rtLevels 5 b ((List.range (2 ^ 5)).map (fun i => rtReg i k))).1 := rfl

theorem rtBit_out (k b : Nat) :
    (rtBit k b).2.1
      = (rtLevels 5 b ((List.range (2 ^ 5)).map (fun i => rtReg i k))).2.1.headD 0 := rfl

theorem rtBit_next (k b : Nat) :
    (rtBit k b).2.2 = (rtLevels 5 b ((List.range (2 ^ 5)).map (fun i => rtReg i k))).2.2 := rfl

theorem run_rtBit (k b : Nat) (E : Env) (hk : k < 32) (hb : 1003 ≤ b)
    (hinv : ∀ j : Nat, j < 5 → E (998 + j) = !(E j)) :
    ((rtBit k b).2.1 = b + 92)
    ∧ ((rtBit k b).2.2 = b + 93)
    ∧ (∀ m : Nat, m < b → run E (rtBit k b).1 m = E m)
    ∧ (run E (rtBit k b).1 (b + 92) = E (rtReg (rtSel E 0 5) k)) := by
  obtain ⟨ho, hb', hfr, hval⟩ :=
    run_rtLevels 5 (le_refl 5) b (fun i => rtReg i k) E hb
      (fun i hi => Nat.lt_of_lt_of_le (rtReg_lt i k (by norm_num at hi; omega) hk)
        (by omega)) hinv
  have ho' : (rtLevels 5 b ((List.range (2 ^ 5)).map (fun i => rtReg i k))).2.1 = [b + 92] := by
    rw [ho]; norm_num
  have h92 : (rtLevels 5 b ((List.range (2 ^ 5)).map (fun i => rtReg i k))).2.1.headD 0
      = b + 92 := by rw [ho']; rfl
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [rtBit_out, h92]
  · rw [rtBit_next, hb']; norm_num
  · intro m hm; rw [rtBit_gates]; exact hfr m hm
  · rw [rtBit_gates, ← h92]; exact hval

/-! ## `rtBits` — the 32 independent trees -/

theorem rtBits_zero (b : Nat) : rtBits 0 b = ([], []) := rfl

theorem rtBits_succ (n b : Nat) :
    rtBits (n + 1) b
      = ((rtBit (32 - (n + 1)) b).1 ++ (rtBits n (rtBit (32 - (n + 1)) b).2.2).1,
         (rtBit (32 - (n + 1)) b).2.1 :: (rtBits n (rtBit (32 - (n + 1)) b).2.2).2) := rfl

theorem run_rtBits : ∀ (n b : Nat) (E : Env), n ≤ 32 → 1003 ≤ b →
    (∀ j : Nat, j < 5 → E (998 + j) = !(E j)) →
    ((rtBits n b).2 = (List.range n).map (fun t => b + 93 * t + 92))
    ∧ (∀ m : Nat, m < b → run E (rtBits n b).1 m = E m)
    ∧ (∀ t : Nat, t < n → run E (rtBits n b).1 (b + 93 * t + 92)
        = E (rtReg (rtSel E 0 5) (32 - n + t))) := by
  intro n
  induction n with
  | zero =>
    intro b E _ _ _
    exact ⟨by simp [rtBits_zero], fun m _ => rfl, fun t ht => absurd ht (Nat.not_lt_zero t)⟩
  | succ n ih =>
    intro b E hn hb hinv
    obtain ⟨hBo, hBb, hBfr, hBval⟩ :=
      run_rtBit (32 - (n + 1)) b E (by omega) hb hinv
    obtain ⟨hSo, hSfr, hSval⟩ :=
      ih (b + 93) (run E (rtBit (32 - (n + 1)) b).1) (by omega) (by omega)
        (fun jj hjj => by
          rw [hBfr (998 + jj) (by omega), hBfr jj (by omega)]; exact hinv jj hjj)
    have hsel : rtSel (run E (rtBit (32 - (n + 1)) b).1) 0 5 = rtSel E 0 5 :=
      rtSel_congr (fun m hm => hBfr m (by omega)) 5 0 (by omega)
    have hS : rtSel E 0 5 < 32 := by have := rtSel_lt E 5 0; norm_num at this; omega
    rw [hsel] at hSval
    rw [rtBits_succ, hBb, hBo]
    refine ⟨?_, ?_, ?_⟩
    · rw [hSo, List.range_succ_eq_map, List.map_cons, List.map_map]
      refine congrArg₂ List.cons ?_ ?_
      · norm_num
      · exact List.map_congr_left (fun p _ => by
          show b + 93 + 93 * p + 92 = b + 93 * (p + 1) + 92
          omega)
    · intro m hm
      rw [run_append, hSfr m (by omega), hBfr m hm]
    · intro t ht
      rw [run_append]
      match t with
      | 0 =>
        rw [show b + 93 * 0 + 92 = b + 92 from by omega, hSfr (b + 92) (by omega), hBval]
        exact congrArg (fun z => E (rtReg (rtSel E 0 5) z)) (by omega)
      | q + 1 =>
        have hq : q < n := by omega
        rw [show b + 93 * (q + 1) + 92 = b + 93 + 93 * q + 92 from by omega, hSval q hq,
          hBfr (rtReg (rtSel E 0 5) (32 - n + q))
            (Nat.lt_of_lt_of_le (rtReg_lt (rtSel E 0 5) (32 - n + q) hS (by omega))
              (by omega))]
        exact congrArg (fun z => E (rtReg (rtSel E 0 5) z)) (by omega)

/-! ## `readTree` — the whole read path -/

theorem readTree_gates_eq : readTree.gates
    = (⟨997, Op.const false⟩ : Gate)
      :: ((List.range 5).map (fun j => (⟨998 + j, Op.not j⟩ : Gate)) ++ (rtBits 32 1003).1) :=
  rfl

theorem readTree_outs_eq : readTree.outs = (rtBits 32 1003).2 := rfl

/-- The valuation the 32 trees actually see: the input valuation with the shared
`x0` tie driven low and the five shared inverters evaluated. -/
def rtPre (E : Env) : Env :=
  run (upd E 997 false) ((List.range 5).map (fun j => (⟨998 + j, Op.not j⟩ : Gate)))

/-- ⭐ **`run_pointwise` TRANSFERRED HERE, AND ONLY HERE** — the five SHARED
inverters are a pointwise block on the nose. -/
theorem rtInvGates (E : Env) :
    (∀ m : Nat, m < 998 →
        run E ((List.range 5).map (fun j => (⟨998 + j, Op.not j⟩ : Gate))) m = E m)
    ∧ (∀ k : Nat, k < 5 →
        run E ((List.range 5).map (fun j => (⟨998 + j, Op.not j⟩ : Gate))) (998 + k)
          = (Op.not k).eval E) :=
  run_pointwise E 998 (fun i => Op.not i) 5
    (fun i hi c hc => by
      simp only [Op.fanin, List.mem_cons, List.not_mem_nil, or_false] at hc
      subst hc
      exact Nat.lt_of_lt_of_le hi (by norm_num))

theorem rtPre_lt (E : Env) (m : Nat) (hm : m < 997) : rtPre E m = E m := by
  rw [rtPre, (rtInvGates (upd E 997 false)).1 m (Nat.lt_trans hm (by norm_num))]
  exact upd_of_ne (n := 997) (m := m) false (Nat.ne_of_lt hm)

theorem rtPre_zero (E : Env) : rtPre E 997 = false := by
  rw [rtPre, (rtInvGates (upd E 997 false)).1 997 (by norm_num)]
  exact upd_self _ _ _

theorem rtPre_inv (E : Env) (j : Nat) (hj : j < 5) : rtPre E (998 + j) = !(rtPre E j) := by
  rw [rtPre_lt E j (Nat.lt_trans hj (by norm_num)), rtPre,
    (rtInvGates (upd E 997 false)).2 j hj]
  show (!(upd E 997 false j)) = _
  rw [upd_of_ne (n := 997) (m := j) false (Nat.ne_of_lt (Nat.lt_trans hj (by norm_num)))]

theorem run_readTree_gates (E : Env) (m : Nat) :
    run E readTree.gates m = run (rtPre E) (rtBits 32 1003).1 m := by
  rw [readTree_gates_eq, run_cons, run_append]
  rfl

/-- ⭐⭐ **THE READ PATH READS THE REGISTER ITS ADDRESS NAMES** — for every one of
the `2^997` input valuations, at every one of the 32 output bits. *No driver, no
sample: the address is read off the valuation by `rtSel`.* -/
theorem sem_readTree_uncond (E : Env) :
    sem readTree E = (List.range 32).map (fun t =>
      if rtSel E 0 5 = 0 then false else E (rtReg (rtSel E 0 5) t)) := by
  obtain ⟨hBo, hBfr, hBval⟩ :=
    run_rtBits 32 1003 (rtPre E) (le_refl 32) (by norm_num) (rtPre_inv E)
  have hsel : rtSel (rtPre E) 0 5 = rtSel E 0 5 :=
    rtSel_congr (fun m hm => rtPre_lt E m (by omega)) 5 0 (by omega)
  rw [hsel] at hBval
  have hS : rtSel E 0 5 < 32 := by have := rtSel_lt E 5 0; norm_num at this; omega
  have key : ∀ t : Nat, t < 32 → run E readTree.gates (1003 + 93 * t + 92)
      = (if rtSel E 0 5 = 0 then false else E (rtReg (rtSel E 0 5) t)) := by
    intro t ht
    rw [run_readTree_gates, hBval t ht, show (32 : Nat) - 32 + t = t from by omega]
    by_cases h0 : rtSel E 0 5 = 0
    · rw [if_pos h0, h0]
      show rtPre E rtZero = false
      rw [rtZero_eq]
      exact rtPre_zero E
    · rw [if_neg h0]
      exact rtPre_lt E _ (rtReg_lt_stored _ _ (by omega) hS ht)
  show readTree.outs.map (run E readTree.gates) = _
  rw [readTree_outs_eq, hBo, List.map_map]
  simp only [Function.comp_def]
  exact List.map_congr_left (fun t ht => key t (List.mem_range.mp ht))

/-! ## The driver, and the ISA bridge -/

/-- The read port's input valuation: address `a` on nets `0…4`, and STORED
register `i`'s bit `k` on net `5 + (i-1)*32 + k`. -/
def rtEnvOf (regs : Nat → Word) (a : Nat) : Env :=
  fun n => if n < rtAddrBits then a.testBit n
           else (regs ((n - rtAddrBits) / rtWidth + 1)).getLsbD ((n - rtAddrBits) % rtWidth)

theorem rtEnvOf_addr (regs : Nat → Word) (a j : Nat) (hj : j < 5) :
    rtEnvOf regs a j = a.testBit j := by
  show (if j < rtAddrBits then a.testBit j else _) = _
  rw [if_pos (show j < rtAddrBits from hj)]

theorem rtEnvOf_else (regs : Nat → Word) (a n : Nat) (hn : 5 ≤ n) :
    rtEnvOf regs a n = (regs ((n - 5) / 32 + 1)).getLsbD ((n - 5) % 32) := by
  show (if n < rtAddrBits then a.testBit n
        else (regs ((n - 5) / 32 + 1)).getLsbD ((n - 5) % 32)) = _
  rw [if_neg (Nat.not_lt.mpr (show rtAddrBits ≤ n from hn))]

theorem rtEnvOf_reg (regs : Nat → Word) (a i k : Nat) (hi : 1 ≤ i) (hk : k < 32) :
    rtEnvOf regs a (rtReg i k) = (regs i).getLsbD k := by
  rw [rtReg_ne i k hi, rtEnvOf_else regs a _ (by omega),
    show (5 : Nat) + (i - 1) * 32 + k - 5 = 32 * (i - 1) + k by omega,
    Nat.mul_add_div (by norm_num), Nat.mul_add_mod, Nat.div_eq_of_lt hk,
    Nat.mod_eq_of_lt hk, show i - 1 + 0 + 1 = i by omega]

theorem rtSel_rtEnvOf (regs : Nat → Word) (a : Nat) (ha : a < 32) :
    rtSel (rtEnvOf regs a) 0 5 = a := by
  rw [rtSel_congr (E := fun i => a.testBit i) (fun m hm => rtEnvOf_addr regs a m hm) 5 0
      (by norm_num), rtSel_testBit]
  norm_num
  omega

/-- ⭐ **THE READ PORT, DRIVEN** — every address `a < 32`, every register file. -/
theorem sem_readTree (regs : Nat → Word) (a : Nat) (ha : a < 32) :
    sem readTree (rtEnvOf regs a)
      = (List.range 32).map (fun t => (if a = 0 then (0 : Word) else regs a).getLsbD t) := by
  rw [sem_readTree_uncond, rtSel_rtEnvOf regs a ha]
  refine List.map_congr_left (fun t ht => ?_)
  have ht32 : t < 32 := List.mem_range.mp ht
  by_cases h0 : a = 0
  · rw [if_pos h0, if_pos h0]
    simp
  · rw [if_neg h0, if_neg h0]
    exact rtEnvOf_reg regs a a t (by omega) ht32

/-- The port driven by an ISA machine state, addressed by `a`. -/
def rtEnvOfSt (s : St) (a : Fin 32) : Env :=
  rtEnvOf (fun i => s.get ⟨i % 32, Nat.mod_lt i (by norm_num)⟩) a.val

/-- ⭐⭐ **THE PORT IS `St.get`** — every state, every ISA register, every bit. -/
theorem sem_readTree_St (s : St) (a : Fin 32) :
    sem readTree (rtEnvOfSt s a) = (List.range 32).map (fun t => (s.get a).getLsbD t) := by
  rw [rtEnvOfSt, sem_readTree _ _ a.isLt]
  refine List.map_congr_left (fun t _ => ?_)
  by_cases h : (a : Nat) = 0
  · rw [if_pos h, show a = 0 from Fin.ext h, St.get_zero]
  · rw [if_neg h]
    exact congrArg (fun w : Word => w.getLsbD t)
      (congrArg s.get (Fin.ext (Nat.mod_eq_of_lt a.isLt)))

/-- ⭐ **`x0` READS ZERO AT EVERY FILE CONTENTS AND ON EVERY OUTPUT BIT** — the
`St.get_zero` law, on the circuit. *`readTree_x0_is_zero` is this at two file
contents and one bit.* -/
theorem readTree_reads_x0_zero (s : St) :
    sem readTree (rtEnvOfSt s 0) = List.replicate 32 false := by
  rw [sem_readTree_St, St.get_zero]
  decide +kernel

/-- **The consumer bridge, in the shape a `core` assembly applies.** -/
theorem rtWord_is_get (s : St) (a : Fin 32) :
    SaltWorks.HDL.wordOf (fun k => (sem readTree (rtEnvOfSt s a)).getD k false) = s.get a := by
  rw [sem_readTree_St]
  have h := wordOf_getD_map_range (fun t => (s.get a).getLsbD t)
  rw [h, wordOf_getLsbD_self]

/-! ## ⭐ THE SAMPLED CERTIFICATE, SUPERSEDED -/

theorem getD_map_range (f : Nat → Bool) (k : Nat) (hk : k < 32) :
    ((List.range 32).map f).getD k false = f k := by
  have h := getD_of_range_append f [] k hk
  rwa [List.append_nil] at h

theorem rtOneCold_else (m a n : Nat) (hn : 5 ≤ n) :
    rtOneCold m a n
      = decide (¬ ((5 : Nat) + (m - 1) * 32 ≤ n ∧ n < (5 : Nat) + (m - 1) * 32 + 32)) := by
  show (if n < rtAddrBits then a.testBit n
        else decide (¬ ((5 : Nat) + (m - 1) * 32 ≤ n
                        ∧ n < (5 : Nat) + (m - 1) * 32 + 32))) = _
  rw [if_neg (Nat.not_lt.mpr (show rtAddrBits ≤ n from hn))]

/-- ⭐ **THE ONE-COLD DRIVER IS `rtEnvOf` AT ONE FILE** — which is what lets the
organ theorem SUPERSEDE the certificate instead of restating it. -/
theorem rtOneCold_eq (m : Nat) (hm : 1 ≤ m) (a n : Nat) :
    rtOneCold m a n = rtEnvOf (fun i => if i = m then (0 : Word) else BitVec.allOnes 32) a n := by
  by_cases hn : n < 5
  · show (if n < rtAddrBits then a.testBit n else _) = _
    rw [if_pos (show n < rtAddrBits from hn)]
    exact (rtEnvOf_addr _ a n hn).symm
  · have h5 : 5 ≤ n := by omega
    have hqr : 32 * ((n - 5) / 32) + (n - 5) % 32 = n - 5 := Nat.div_add_mod _ _
    have hr32 : (n - 5) % 32 < 32 := Nat.mod_lt _ (by norm_num)
    rw [rtOneCold_else m a n h5, rtEnvOf_else _ a n h5]
    by_cases hmq : (n - 5) / 32 + 1 = m
    · have hin : ((5 : Nat) + (m - 1) * 32 ≤ n ∧ n < (5 : Nat) + (m - 1) * 32 + 32) := by omega
      simp [hin, hmq]
    · have hout : ¬ ((5 : Nat) + (m - 1) * 32 ≤ n ∧ n < (5 : Nat) + (m - 1) * 32 + 32) := by omega
      rw [if_neg hmq, BitVec.getLsbD_allOnes, decide_eq_true hr32, decide_eq_true hout]

theorem rtBit0_uncond (m : Nat) (hm : 1 ≤ m) (a : Nat) (ha : a < 32) :
    rtBit0 m a = decide (a ≠ m ∧ a ≠ 0) := by
  have hsem : sem readTree (rtOneCold m a)
      = sem readTree (rtEnvOf (fun i => if i = m then (0 : Word) else BitVec.allOnes 32) a) :=
    sem_congr readTree (fun n => rtOneCold_eq m hm a n)
  show (sem readTree (rtOneCold m a)).getD 0 false = _
  rw [hsem, sem_readTree _ a ha, getD_map_range _ 0 (by norm_num)]
  by_cases h0 : a = 0
  · simp [h0]
  · by_cases hM : a = m
    · simp [hM]
    · simp [h0, hM]

/-- ⭐⭐ **`rtSelectsOK` HOLDS AT EVERY STORED REGISTER, NOT TWO** — the sampled
certificate is now a COROLLARY of the organ theorem. -/
theorem rtSelectsOK_uncond (m : Nat) (hm : 1 ≤ m) : rtSelectsOK m = true := by
  show ((List.range 32).all fun a => rtBit0 m a == decide (a ≠ m ∧ a ≠ 0)) = true
  refine List.all_eq_true.mpr (fun a ha => ?_)
  rw [rtBit0_uncond m hm a (List.mem_range.mp ha)]
  simp

/-- Off the `{7, 19}` sample, and with no `decide` anywhere in the proof. -/
theorem sem_readTree_off_the_sample :
    rtSelectsOK 2 = true ∧ rtSelectsOK 31 = true :=
  ⟨rtSelectsOK_uncond 2 (by norm_num), rtSelectsOK_uncond 31 (by norm_num)⟩

/-! ### ⛔ NON-VACUITY — two ONE-GATE mutants the CERTIFICATE ACCEPTS -/

/-- ⛔ ONE GATE MUTATED. Net 1007 is the `and` leg carrying `x3`'s bit 0 into the
level-0 mux of output bit **0**'s tree; it now reads `x2`'s bit 0 (net 37), so
**address 3 reads `x2`**. Still `ssa`. -/
def readTreeCutA : Circ :=
  { readTree with
    gates := readTree.gates.map fun g => if g.out == 1007 then ⟨g.out, .and 37 0⟩ else g }

/-- ⛔ ONE GATE MUTATED. Net 1188 is the ROOT of output bit **1**'s tree, tied
low, so **the port's bit 1 is always zero**. Still `ssa`. -/
def readTreeCutB : Circ :=
  { readTree with
    gates := readTree.gates.map fun g => if g.out == 1188 then ⟨g.out, .const false⟩ else g }

/-- `rtSelectsOK`'s check, run against an arbitrary circuit. -/
def rtSelectsCut (c : Circ) (m : Nat) : Bool :=
  (List.range 32).all fun a => (sem c (rtOneCold m a)).getD 0 false == decide (a ≠ m ∧ a ≠ 0)

theorem readTreeCutA_ssa : readTreeCutA.ssa = true := by decide +kernel

theorem readTreeCutB_ssa : readTreeCutB.ssa = true := by decide +kernel

/-- ⛔ **THE CERTIFICATE ACCEPTS THE MUTANT AT BOTH ITS SAMPLE POINTS.** At
`m = 7` and `m = 19` registers 2 and 3 hold the same word, so reading the wrong
one is invisible. -/
theorem readTreeCutA_passes_the_certificate :
    rtSelectsCut readTreeCutA 7 = true ∧ rtSelectsCut readTreeCutA 19 = true := by
  decide +kernel

/-- ⛔ **AND ACCEPTS THE BIT-1 MUTANT AT EVERY SAMPLE POINT THERE IS** — `rtBit0`
reads output 0, so 31 of the 32 trees are outside the certificate entirely. -/
theorem readTreeCutB_passes_the_certificate :
    rtSelectsCut readTreeCutB 7 = true ∧ rtSelectsCut readTreeCutB 19 = true := by
  decide +kernel

/-- ✅ **AND THE ORGAN THEOREM REFUTES IT**, one register off the sample. -/
theorem readTreeCutA_fails_the_theorem :
    (sem readTreeCutA (rtOneCold 2 3)).getD 0 false = false
      ∧ (sem readTree (rtOneCold 2 3)).getD 0 false = true := by decide +kernel

/-- ✅ **AND REFUTES THE BIT-1 MUTANT**, one output bit off the sample. -/
theorem readTreeCutB_fails_the_theorem :
    (sem readTreeCutB (rtOneCold 7 3)).getD 1 false = false
      ∧ (sem readTree (rtOneCold 7 3)).getD 1 false = true := by decide +kernel

end ReadTreeSemantics

/-! # REGNEXT — THE REGISTER WRITE PATH, UNCONDITIONAL

`RegNext.lean`'s `regNext` is the fourth block of `core` and **the bulk of it by
gate count**: 32 inverters and 3 × 1,024 mux gates, 3,104 in all. It is what
`St.set rd v` *is* in silicon.

⛔ **IT HAS ONE REFERENCING FILE AND THAT IS NOT A REASON TO SKIP IT.** The
fleet nearly shipped a core pinning `pc := 4` forever because `inc32` was
retired for having no consumers. The corrected metric is **"unproved AND
(consumed OR REQUIRED-BY-SPEC)"**, and a machine whose ISA says `s.set rd v`
requires a write port whatever the reference count says.

## ⭐ WHAT THE BLOCK'S CERTIFICATES ACTUALLY QUANTIFY OVER

Read before proving; the reading is a deliverable in its own right.

| certificate | universal in | PINNED | covers |
|---|---|---|---|
| `regNext4_correct_on_all_enables` | **all 16 `we` vectors** | datum `rnResPat`, file `rnCurPat`, size 4×4 | 16 of 2^24 |
| `regNext8_correct` | 8 one-hot `we`, plus all-zero | the same two patterns, size 8×8 | **9 of 2^80** |
| `regNext8_writes_only_the_enabled` | all 64 output bits | ONE `we` vector (`r = 5`), both patterns | 1 of 2^80 |
| `regNext8_no_enable_holds_state` | all 64 output bits | `we ≡ false`, both patterns | 1 of 2^80 |
| `regNext32_*_on_sample` (three) | nothing | **output 0 only**, uniform `res`/`cur` | **3 of 2^1088** |

⇒ **`regNext8_correct` — the one Evidence flagged UNCLASSIFIED — is exactly the
`asSelectsOK m` shape**: universal in one axis (*which single register is
enabled*) and pinned in three (the datum, the incoming file, the array size).
Nine points of a 2^80 space, and **not one of them is about `regNext` itself**,
which is `regNextN 32 32`.

⭐ **AND THE THREE 32×32 CERTIFICATES ARE HONESTLY NAMED, WHICH THE `pcNext`
TRIO WAS NOT.** `regNext32_writes_when_enabled_on_sample` says `on_sample` in
its own name and `RegNext.lean:217-227` says why: reading all 1,024 outputs is
the OOM zone, so `rnBit` reads output 0 — register 0, bit 0 — and nothing else.
*A block that documents its own sampling is a different object from one whose
names overclaim.*

## ⛔ THE `x0` FINDING — THE DISCARD IS NOT IN THIS BLOCK

`St.set_zero` (P5) is a landed **universal** ISA law: a write to `x0` is
discarded. **`regNext` does not implement it.** `rnMux` is uniform in `r`,
`r = 0` included, so `next[0][k] = we[0] ? result[k] : cur[0][k]` — raise
`we[0]` and `x0` latches, at every one of its 32 bits
(`regNext_writes_x0_when_enabled`, and `regNext_x0_is_not_self_enforcing` gives
a valuation where it is observable).

⭐ **THAT IS NOT A DEFECT, AND THE DIFFERENCE FROM THE `pc` CASE IS THE POINT.**
The suppression exists — one block upstream, as `regWrite`'s output 0 wired to
`.const false` (`RegWrite.lean:83`), certified by `regWrite_x0_never_enabled`
over all 128 control inputs. The write path enforces P5 **on the ENABLE side and
nowhere else**. So:

* `regNext_x0_holds` — ⭐ with `regWrite`'s enables, `x0` holds its incoming
  contents at **every** bit, every destination, every datum. P5 at all 32 bits
  rather than at sampled ones, and *stronger than the ISA law*, since
  `St.get_zero` makes `regs[0]` unobservable while the array must still leave it
  alone.
* ⛔ **and the standing exposure is real**: any assembly that drives `regNext`'s
  `we` ports from anything but `regWrite` breaks P5 silently, because this block
  cannot refuse. **`core` does not exist, so nothing yet checks that wiring.**
  That is the `pc` defect's shape with the sign flipped — there a spec law had no
  implementation; here it has exactly one, in a different block, unbridged.

## What transferred, and what did not

* ⭐ **`run_pointwise` transferred exactly once and exactly**: the 32 write-enable
  inverters are `(List.range R).map fun r => ⟨rnIn + r, .not r⟩`.
* ⛔ **`run_muxRow` did NOT transfer, and the reason was visible before any proof
  attempt.** `muxRow`'s cells are `.and (p i) s` — *selector second*. `rnMux`'s
  are `.and (notWe r) (cur r k)` — *selector FIRST*. Same circuit, transposed
  operands, and no instantiation of `p q s t` produces it. What lands instead is
  `run_cellRow`, generic over two arbitrary `Op`s ORed into a third net, which
  **subsumes `run_muxRow`'s shape as well as this one**.
* ⛔ **`sem_pcAdd`'s composition template did not apply**: `regNext` instantiates
  nothing — it is a flat generator — so there is no `instOK` to discharge.
* ⛔ **`decide` over the array is not available and never was.** 32×32 is 2^1088
  states; `RegNext.lean`'s header records the `EXIT=134` that established it.
  **This proof is structural throughout** and the only `decide +kernel` below is
  on the 8×8 mutant controls.

## ⛔ THE DEBT THIS DOES NOT PAY

**No `C4Spec` field is closed.** A register-field claim is about a whole `core`'s
output bits and no `core` exists. What lands is the block theorem, the ISA
bridge, and the shape a `core` assembly applies. *The debt is `core`.*
-/

section RegNextSemantics

open SaltWorks.HDL hiding seenWord

/-! ## The generic OR-cell array -/

def cellRow (base : Nat) (p q : Nat → Op) (n : Nat) : List Gate :=
  (List.range n).flatMap fun i =>
    [(⟨base + 3 * i, p i⟩ : Gate),
     ⟨base + 3 * i + 1, q i⟩,
     ⟨base + 3 * i + 2, .or (base + 3 * i) (base + 3 * i + 1)⟩]

theorem cellRow_succ (base : Nat) (p q : Nat → Op) (n : Nat) :
    cellRow base p q (n + 1)
      = cellRow base p q n
          ++ [(⟨base + 3 * n, p n⟩ : Gate),
              ⟨base + 3 * n + 1, q n⟩,
              ⟨base + 3 * n + 2, .or (base + 3 * n) (base + 3 * n + 1)⟩] := by
  simp [cellRow, List.range_succ]

theorem run_cell (F : Env) (b : Nat) (o1 o2 : Op) (h2 : ∀ a ∈ o2.fanin, a < b) :
    run F [(⟨b, o1⟩ : Gate), ⟨b + 1, o2⟩, ⟨b + 2, .or b (b + 1)⟩] (b + 2)
      = (o1.eval F || o2.eval F) := by
  have he : o2.eval (upd F b (o1.eval F)) = o2.eval F :=
    Op.eval_congr o2 (fun a ha => upd_of_ne _ (Nat.ne_of_lt (h2 a ha)))
  have hne : b ≠ b + 1 := Nat.ne_of_lt (Nat.lt_succ_self b)
  simp only [run_cons, run_nil, upd_self]
  show (upd (upd F b (o1.eval F)) (b + 1) (o2.eval (upd F b (o1.eval F))) b
        || upd (upd F b (o1.eval F)) (b + 1) (o2.eval (upd F b (o1.eval F))) (b + 1)) = _
  rw [upd_of_ne _ hne, upd_self, upd_self, he]

theorem run_cell_frame (F : Env) (b m : Nat) (o1 o2 : Op) (hm : ¬ (b ≤ m ∧ m ≤ b + 2)) :
    run F [(⟨b, o1⟩ : Gate), ⟨b + 1, o2⟩, ⟨b + 2, .or b (b + 1)⟩] m = F m := by
  have e0 : ¬ (m = b) := by omega
  have e1 : ¬ (m = b + 1) := by omega
  have e2 : ¬ (m = b + 2) := by omega
  simp [upd, e0, e1, e2]

theorem run_cellRow (E : Env) (base : Nat) (p q : Nat → Op) :
    ∀ n : Nat, (∀ i : Nat, i < n →
        (∀ a ∈ (p i).fanin, a < base) ∧ (∀ a ∈ (q i).fanin, a < base)) →
      (∀ m : Nat, m < base → run E (cellRow base p q n) m = E m)
      ∧ (∀ i : Nat, i < n → run E (cellRow base p q n) (base + 3 * i + 2)
           = ((p i).eval E || (q i).eval E)) := by
  intro n
  induction n with
  | zero => intro _; exact ⟨fun m _ => rfl, fun i hi => absurd hi (Nat.not_lt_zero i)⟩
  | succ n ih =>
    intro hb
    obtain ⟨hfr, hval⟩ := ih (fun i hi => hb i (Nat.lt_succ_of_lt hi))
    obtain ⟨hpn, hqn⟩ := hb n (Nat.lt_succ_self n)
    refine ⟨?_, ?_⟩
    · intro m hm
      rw [cellRow_succ, run_append, run_cell_frame _ _ _ _ _ (by omega)]
      exact hfr m hm
    · intro i hi
      rw [cellRow_succ, run_append]
      rcases Nat.lt_or_ge i n with hin | hin
      · rw [run_cell_frame _ _ _ _ _ (by omega)]
        exact hval i hin
      · have hEq : i = n := Nat.le_antisymm (Nat.le_of_lt_succ hi) hin
        subst hEq
        rw [run_cell _ (base + 3 * i) (p i) (q i)
              (fun a ha => Nat.lt_of_lt_of_le (hqn a ha) (Nat.le_add_right base (3 * i))),
          Op.eval_congr (p i) (fun a ha => hfr a (hpn a ha)),
          Op.eval_congr (q i) (fun a ha => hfr a (hqn a ha))]

/-! ## `regNextN`'s arithmetic, in `Nat` -/

def rnInN (R W : Nat) : Nat := R + W + R * W
def rnBaseN (R W : Nat) : Nat := R + W + R * W + R
def rnOutN (R W r k : Nat) : Nat := R + W + R * W + R + 3 * (W * r) + 3 * k + 2

theorem rnInN_eq (R W : Nat) : rnIn R W = rnInN R W := rfl
theorem rnBaseN_eq (R W : Nat) : rnBase R W = rnBaseN R W := rfl
theorem rnNotWe_eq (R W r : Nat) : rnNotWe R W r = rnInN R W + r := rfl
theorem rnWe_eq (r : Nat) : rnWe r = r := rfl
theorem rnRes_eq (R k : Nat) : rnRes R k = R + k := rfl
theorem rnCur_eq (R W r k : Nat) : rnCur R W r k = R + W + W * r + k := rfl

theorem rnOut_eq (R W r k : Nat) : rnOut R W r k = rnOutN R W r k := by
  show (rnBase R W + 3 * (W * r + k) + 2 : Nat) = rnOutN R W r k
  simp only [rnBase, rnIn, rnOutN]
  omega

/-! ## The mux array -/

def rnPOp (R W r k : Nat) : Op := .and (rnNotWe R W r) (rnCur R W r k)
def rnQOp (R _W r k : Nat) : Op := .and (rnWe r) (rnRes R k)

def rnArr (R W n : Nat) : List Gate :=
  (List.range n).flatMap (fun r => (List.range W).flatMap (rnMux R W r))

theorem rnArr_succ (R W n : Nat) :
    rnArr R W (n + 1) = rnArr R W n ++ (List.range W).flatMap (rnMux R W n) := by
  simp [rnArr, List.range_succ]

theorem rnRow_eq (R W r : Nat) :
    (List.range W).flatMap (rnMux R W r)
      = cellRow (rnBaseN R W + 3 * (W * r)) (rnPOp R W r) (rnQOp R W r) W := by
  unfold cellRow
  refine List.flatMap_congr ?_
  intro k _
  have h1 : rnMuxBase R W r k = rnBaseN R W + 3 * (W * r) + 3 * k := by
    show (rnBase R W + 3 * (W * r + k) : Nat) = _
    simp only [rnBase, rnIn, rnBaseN]
    omega
  show [(⟨rnMuxBase R W r k, Op.and (rnNotWe R W r) (rnCur R W r k)⟩ : Gate),
        ⟨rnMuxBase R W r k + 1, Op.and (rnWe r) (rnRes R k)⟩,
        ⟨rnMuxBase R W r k + 2, Op.or (rnMuxBase R W r k) (rnMuxBase R W r k + 1)⟩] = _
  rw [h1]
  rfl

theorem run_rnArr (R W : Nat) (E : Env) : ∀ n : Nat, n ≤ R →
    (∀ m : Nat, m < rnBaseN R W → run E (rnArr R W n) m = E m)
    ∧ (∀ r k : Nat, r < n → k < W →
        run E (rnArr R W n) (rnOutN R W r k)
          = ((E (rnNotWe R W r) && E (rnCur R W r k)) || (E (rnWe r) && E (rnRes R k)))) := by
  intro n
  induction n with
  | zero => intro _; exact ⟨fun m _ => rfl, fun r k hr _ => absurd hr (Nat.not_lt_zero r)⟩
  | succ n ih =>
    intro hn
    obtain ⟨hfr, hval⟩ := ih (Nat.le_of_succ_le hn)
    have hnR : n < R := hn
    have hRpos : 0 < R := Nat.lt_of_le_of_lt (Nat.zero_le n) hnR
    have hW : W ≤ R * W := Nat.le_mul_of_pos_left W hRpos
    have hWn : W * n + W ≤ R * W := by
      calc W * n + W = W * (n + 1) := by ring
        _ ≤ W * R := Nat.mul_le_mul (Nat.le_refl W) hn
        _ = R * W := Nat.mul_comm W R
    have hfan : ∀ i : Nat, i < W →
        (∀ a ∈ (rnPOp R W n i).fanin, a < rnBaseN R W + 3 * (W * n))
        ∧ (∀ a ∈ (rnQOp R W n i).fanin, a < rnBaseN R W + 3 * (W * n)) := by
      intro i hi
      refine ⟨?_, ?_⟩
      · intro a ha
        simp only [rnPOp, Op.fanin, List.mem_cons, List.not_mem_nil, or_false] at ha
        rcases ha with rfl | rfl
        · show (rnInN R W + n : Nat) < _
          simp only [rnInN, rnBaseN]; omega
        · show (R + W + W * n + i : Nat) < _
          simp only [rnBaseN]; omega
      · intro a ha
        simp only [rnQOp, Op.fanin, List.mem_cons, List.not_mem_nil, or_false] at ha
        rcases ha with ha | ha
        · rw [ha]
          show (n : Nat) < _
          simp only [rnBaseN]; omega
        · rw [ha]
          show (R + i : Nat) < _
          simp only [rnBaseN]; omega
    refine ⟨?_, ?_⟩
    · intro m hm
      rw [rnArr_succ, run_append, rnRow_eq,
        (run_cellRow (run E (rnArr R W n)) (rnBaseN R W + 3 * (W * n))
          (rnPOp R W n) (rnQOp R W n) W hfan).1 m (by omega)]
      exact hfr m hm
    · intro r k hr hk
      rw [rnArr_succ, run_append, rnRow_eq]
      rcases Nat.lt_or_ge r n with hrn | hrn
      · have hkey : W * r + W ≤ W * n := by
          calc W * r + W = W * (r + 1) := by ring
            _ ≤ W * n := Nat.mul_le_mul (Nat.le_refl W) hrn
        rw [(run_cellRow (run E (rnArr R W n)) (rnBaseN R W + 3 * (W * n))
              (rnPOp R W n) (rnQOp R W n) W hfan).1 (rnOutN R W r k)
              (by simp only [rnOutN, rnBaseN]; omega)]
        exact hval r k hrn hk
      · have hEq : r = n := Nat.le_antisymm (Nat.le_of_lt_succ hr) hrn
        subst hEq
        rw [show rnOutN R W r k = rnBaseN R W + 3 * (W * r) + 3 * k + 2 from rfl,
          (run_cellRow (run E (rnArr R W r)) (rnBaseN R W + 3 * (W * r))
            (rnPOp R W r) (rnQOp R W r) W hfan).2 k hk]
        have h1 : (rnNotWe R W r : Nat) < rnBaseN R W := by
          show (rnInN R W + r : Nat) < _
          simp only [rnInN, rnBaseN]; omega
        have h2 : (rnCur R W r k : Nat) < rnBaseN R W := by
          show (R + W + W * r + k : Nat) < _
          simp only [rnBaseN]; omega
        have h3 : (rnWe r : Nat) < rnBaseN R W := by
          show (r : Nat) < _
          simp only [rnBaseN]; omega
        have h4 : (rnRes R k : Nat) < rnBaseN R W := by
          show (R + k : Nat) < _
          simp only [rnBaseN]; omega
        simp only [rnPOp, rnQOp, Op.eval]
        rw [hfr _ h1, hfr _ h2, hfr _ h3, hfr _ h4]

/-! ## ⭐ THE ORGAN THEOREM -/

theorem regNextN_gates_eq (R W : Nat) :
    (regNextN R W).gates
      = (List.range R).map (fun i => (⟨rnInN R W + i, Op.not i⟩ : Gate)) ++ rnArr R W R := rfl

theorem run_regNextN (R W : Nat) (E : Env) (r k : Nat) (hr : r < R) (hk : k < W) :
    run E (regNextN R W).gates (rnOut R W r k)
      = (if E (rnWe r) then E (rnRes R k) else E (rnCur R W r k)) := by
  have hkey : W * r + W ≤ R * W := by
    calc W * r + W = W * (r + 1) := by ring
      _ ≤ W * R := Nat.mul_le_mul (Nat.le_refl W) hr
      _ = R * W := Nat.mul_comm W R
  obtain ⟨hifr, hival⟩ := run_pointwise E (rnInN R W) (fun i => Op.not i) R
    (fun i hi a ha => by
      simp only [Op.fanin, List.mem_cons, List.not_mem_nil, or_false] at ha
      subst ha
      exact Nat.lt_of_lt_of_le hi (by show (R : Nat) ≤ rnInN R W; simp only [rnInN]; omega))
  rw [regNextN_gates_eq, run_append, rnOut_eq,
    (run_rnArr R W (run E ((List.range R).map (fun i => (⟨rnInN R W + i, Op.not i⟩ : Gate))))
      R (Nat.le_refl R)).2 r k hr hk]
  have e1 : run E ((List.range R).map (fun i => (⟨rnInN R W + i, Op.not i⟩ : Gate)))
      (rnNotWe R W r) = !(E r) := by
    rw [rnNotWe_eq]
    exact hival r hr
  have e2 : run E ((List.range R).map (fun i => (⟨rnInN R W + i, Op.not i⟩ : Gate)))
      (rnCur R W r k) = E (rnCur R W r k) :=
    hifr _ (by show (R + W + W * r + k : Nat) < _; simp only [rnInN]; omega)
  have e3 : run E ((List.range R).map (fun i => (⟨rnInN R W + i, Op.not i⟩ : Gate)))
      (rnWe r) = E (rnWe r) :=
    hifr _ (by show (r : Nat) < _; simp only [rnInN]; omega)
  have e4 : run E ((List.range R).map (fun i => (⟨rnInN R W + i, Op.not i⟩ : Gate)))
      (rnRes R k) = E (rnRes R k) :=
    hifr _ (by show (R + k : Nat) < _; simp only [rnInN]; omega)
  rw [e1, e2, e3, e4]
  show ((!(E (rnWe r)) && E (rnCur R W r k)) || (E (rnWe r) && E (rnRes R k))) = _
  cases E (rnWe r) <;> simp

/-- ⭐⭐ **THE REGISTER WRITE PATH, UNCONDITIONAL.** For EVERY array size and
EVERY valuation of its `R + W + R·W` input nets — every write-enable vector (not
just the one-hot ones), every result word, every incoming file — the next-state
file is `we r ? result : current`, register by register and bit by bit. -/
theorem sem_regNextN (R W : Nat) (E : Env) :
    sem (regNextN R W) E
      = (List.range R).flatMap (fun r =>
          (List.range W).map (fun k =>
            if E (rnWe r) then E (rnRes R k) else E (rnCur R W r k))) := by
  show ((List.range R).flatMap (fun r => (List.range W).map (rnOut R W r))).map
      (run E (regNextN R W).gates) = _
  rw [List.map_flatMap]
  refine List.flatMap_congr ?_
  intro r hr
  rw [List.map_map]
  refine List.map_congr_left ?_
  intro k hk
  exact run_regNextN R W E r k (List.mem_range.mp hr) (List.mem_range.mp hk)

/-- The shipping instance, with the nets spelled out: `we` on `0…31`, `result`
on `32…63`, register `r`'s current bit `k` on `64 + 32r + k`. -/
theorem sem_regNext (E : Env) :
    sem regNext E
      = (List.range 32).flatMap (fun r =>
          (List.range 32).map (fun k =>
            if E r then E (32 + k) else E (64 + 32 * r + k))) := by
  rw [show regNext = regNextN 32 32 from rfl, sem_regNextN]
  refine List.flatMap_congr ?_
  intro r _
  refine List.map_congr_left ?_
  intro k _
  show (if E (rnWe r) then E (rnRes 32 k) else E (rnCur 32 32 r k)) = _
  simp only [rnWe, rnRes, rnCur]

/-! ## Indexing -/

theorem getD_map_range_gen (W : Nat) (g : Nat → Bool) (k : Nat) (hk : k < W) :
    ((List.range W).map g).getD k false = g k := by
  have hl : k < ((List.range W).map g).length := by simp [hk]
  rw [List.getD_eq_getElem _ _ hl, List.getElem_map, List.getElem_range]

theorem length_flatMap_range_map (W : Nat) (f : Nat → Nat → Bool) : ∀ n : Nat,
    ((List.range n).flatMap (fun r => (List.range W).map (f r))).length = n * W := by
  intro n
  induction n with
  | zero => simp
  | succ n ih => simp [List.range_succ, ih, Nat.succ_mul]

theorem getD_flatMap_range_map (W : Nat) (f : Nat → Nat → Bool) :
    ∀ n r k : Nat, r < n → k < W →
      ((List.range n).flatMap (fun r => (List.range W).map (f r))).getD (W * r + k) false
        = f r k := by
  intro n
  induction n with
  | zero => intro r k hr _; exact absurd hr (Nat.not_lt_zero r)
  | succ n ih =>
    intro r k hr hk
    have hsplit : (List.range (n + 1)).flatMap (fun r => (List.range W).map (f r))
        = (List.range n).flatMap (fun r => (List.range W).map (f r))
            ++ (List.range W).map (f n) := by
      simp [List.range_succ]
    have hlen := length_flatMap_range_map W f n
    have hcomm : W * n = n * W := Nat.mul_comm W n
    rw [hsplit]
    rcases Nat.lt_or_ge r n with hrn | hrn
    · have hkey : W * r + W ≤ W * n := by
        calc W * r + W = W * (r + 1) := by ring
          _ ≤ W * n := Nat.mul_le_mul (Nat.le_refl W) hrn
      have hlt : W * r + k
          < ((List.range n).flatMap (fun r => (List.range W).map (f r))).length := by
        rw [hlen]; omega
      rw [List.getD_append _ _ _ _ hlt]
      exact ih r k hrn hk
    · have hEq : r = n := Nat.le_antisymm (Nat.le_of_lt_succ hr) hrn
      subst hEq
      have hge : ((List.range r).flatMap (fun r => (List.range W).map (f r))).length
          ≤ W * r + k := by rw [hlen]; omega
      rw [List.getD_append_right _ _ _ _ hge, hlen, show W * r + k - r * W = k from by omega]
      exact getD_map_range_gen W (f r) k hk

/-- **Bit `k` of register `r` of the next-state file** — the form a consumer
indexes. -/
theorem regNext_getD (E : Env) (r k : Nat) (hr : r < 32) (hk : k < 32) :
    (sem regNext E).getD (32 * r + k) false
      = if E (rnWe r) then E (rnRes 32 k) else E (rnCur 32 32 r k) := by
  rw [show regNext = regNextN 32 32 from rfl, sem_regNextN]
  exact getD_flatMap_range_map 32 _ 32 r k hr hk

/-! ## ⛔ THE `x0` FINDING -/

/-- ⛔ **`regNext` DOES NOT IMPLEMENT P5.** Raise `we[0]` and register `x0`
latches the result, at every one of its 32 bits. The discard lives one block
upstream, in `regWrite`'s constant-`false` output 0. -/
theorem regNext_writes_x0_when_enabled (E : Env) (h : E (rnWe 0) = true)
    (k : Nat) (hk : k < 32) :
    (sem regNext E).getD k false = E (rnRes 32 k) := by
  have h1 := regNext_getD E 0 k (by norm_num) hk
  rw [show (32 : Nat) * 0 + k = k from by omega, h, if_pos rfl] at h1
  exact h1

/-- ⛔ **AND THAT IS OBSERVABLE**: a valuation whose `x0` output disagrees with
`x0`'s incoming contents. -/
theorem regNext_x0_is_not_self_enforcing :
    ∃ E : Env, E (rnWe 0) = true ∧ (sem regNext E).getD 0 false ≠ E (rnCur 32 32 0 0) := by
  refine ⟨fun n => decide (n < 64), rfl, ?_⟩
  rw [regNext_writes_x0_when_enabled _ rfl 0 (by norm_num)]
  decide

/-! ## The driver, and the ISA bridge -/

/-- The array driven with an arbitrary enable vector, result word and file. -/
def rnEnvOf (regs : Nat → Word) (we : Nat → Bool) (v : Word) : Env := fun n =>
  if n < 32 then we n
  else if n < 64 then v.getLsbD (n - 32)
  else (regs ((n - 64) / 32)).getLsbD ((n - 64) % 32)

theorem rnEnvOf_we (regs : Nat → Word) (we : Nat → Bool) (v : Word) (r : Nat) (hr : r < 32) :
    rnEnvOf regs we v (rnWe r) = we r := by
  show (if r < 32 then we r else _) = _
  rw [if_pos hr]

theorem rnEnvOf_res (regs : Nat → Word) (we : Nat → Bool) (v : Word) (k : Nat) (hk : k < 32) :
    rnEnvOf regs we v (rnRes 32 k) = v.getLsbD k := by
  show (if (32 + k : Nat) < 32 then we (32 + k)
        else if (32 + k : Nat) < 64 then v.getLsbD (32 + k - 32)
        else (regs ((32 + k - 64) / 32)).getLsbD ((32 + k - 64) % 32)) = _
  rw [if_neg (by omega), if_pos (by omega), show 32 + k - 32 = k from by omega]

theorem rnEnvOf_cur (regs : Nat → Word) (we : Nat → Bool) (v : Word) (r k : Nat) (hk : k < 32) :
    rnEnvOf regs we v (rnCur 32 32 r k) = (regs r).getLsbD k := by
  show (if (32 + 32 + 32 * r + k : Nat) < 32 then we (32 + 32 + 32 * r + k)
        else if (32 + 32 + 32 * r + k : Nat) < 64 then v.getLsbD (32 + 32 + 32 * r + k - 32)
        else (regs ((32 + 32 + 32 * r + k - 64) / 32)).getLsbD
               ((32 + 32 + 32 * r + k - 64) % 32)) = _
  rw [if_neg (by omega), if_neg (by omega),
    show (32 + 32 + 32 * r + k - 64 : Nat) = 32 * r + k from by omega,
    Nat.mul_add_div (by norm_num), Nat.mul_add_mod, Nat.div_eq_of_lt hk, Nat.mod_eq_of_lt hk,
    Nat.add_zero]

/-- ⭐ **THE WRITE PORT, DRIVEN** — every enable vector, every datum, every file,
every register, every bit. -/
theorem sem_regNext_drive (regs : Nat → Word) (we : Nat → Bool) (v : Word) (r k : Nat)
    (hr : r < 32) (hk : k < 32) :
    (sem regNext (rnEnvOf regs we v)).getD (32 * r + k) false
      = if we r then v.getLsbD k else (regs r).getLsbD k := by
  rw [regNext_getD _ r k hr hk, rnEnvOf_we regs we v r hr, rnEnvOf_res regs we v k hk,
    rnEnvOf_cur regs we v r k hk]

/-- `regWrite`'s enables for a valid, non-`BEQ` instruction with destination
`rd`: **`x0` is excluded here, and nowhere else in the write path.** -/
def rnWeOf (rd : Nat) : Nat → Bool := fun r => decide (rd = r) && !decide (r = 0)

/-- **These ARE `regWrite`'s outputs** — the spec `regWrite_correct` certifies
exhaustively, read at the array's enable ports. -/
theorem rnWeOf_is_weSpec (rd r : Nat) (hr : r < 32) :
    (weSpec rd true false).getD r false = rnWeOf rd r := by
  show ((List.range 32).map (fun r => true && !false && (rd == r) && !(r == 0))).getD r false = _
  rw [getD_map_range_gen 32 _ r hr]
  by_cases h : rd = r <;> by_cases h2 : r = 0 <;> simp [rnWeOf, h, h2]

/-- ⭐⭐ **THE WRITE PORT IS `St.set`** — every state, every destination, every
datum, at all 31 writable registers and all 32 bits. -/
theorem regNext_is_St_set (s : St) (rd : Fin 32) (v : Word) (r k : Nat)
    (hr0 : 0 < r) (hr : r < 32) (hk : k < 32) :
    (sem regNext (rnEnvOf (fun i => s.regs[i]!) (rnWeOf rd.val) v)).getD (32 * r + k) false
      = ((s.set rd v).get ⟨r, hr⟩).getLsbD k := by
  rw [sem_regNext_drive _ _ _ r k hr hk]
  have hrne : (⟨r, hr⟩ : Fin 32) ≠ 0 := by
    intro hc
    have hv : r = 0 := congrArg Fin.val hc
    omega
  by_cases h0 : rd = 0
  · have h0' : (rd : Nat) = 0 := by rw [h0]; rfl
    have hwe : rnWeOf rd.val r = false := by
      simp [rnWeOf, h0', show ¬ ((0 : Nat) = r) from by omega]
    rw [hwe, if_neg (by simp), show s.set rd v = s from by rw [h0]; exact St.set_zero s v]
    show (s.regs[r]!).getLsbD k = _
    rw [getElem!_pos s.regs r hr]
    show _ = (if (⟨r, hr⟩ : Fin 32) = 0 then (0 : Word) else s.regs[r]).getLsbD k
    rw [if_neg hrne]
  · by_cases hrd : r = rd.val
    · have hwe : rnWeOf rd.val r = true := by
        simp [rnWeOf, hrd.symm, show ¬ (r = 0) from by omega]
      rw [hwe, if_pos rfl, show (⟨r, hr⟩ : Fin 32) = rd from Fin.ext hrd,
        St.get_set_self s rd v h0]
    · have hne : ¬ ((rd : Nat) = r) := fun hc => hrd hc.symm
      have hwe : rnWeOf rd.val r = false := by simp [rnWeOf, hne]
      rw [hwe, if_neg (by simp),
        St.get_set_ne s rd ⟨r, hr⟩ v (fun hc => hrd (congrArg Fin.val hc)),
        show s.get ⟨r, hr⟩ = s.regs[r] from by
          show (if (⟨r, hr⟩ : Fin 32) = 0 then (0 : Word) else s.regs[r]) = _
          rw [if_neg hrne]]
      show (s.regs[r]!).getLsbD k = _
      rw [getElem!_pos s.regs r hr]

/-- ⭐ **P5 AT EVERY BIT OF `x0`, AS A COROLLARY** — with `regWrite`'s enables,
register `x0` HOLDS, whatever the destination and whatever the datum. This is
`St.set_zero` on the silicon, and it is stronger than the ISA law, because
`St.get_zero` makes `regs[0]` unobservable while the array must still not
disturb it. -/
theorem regNext_x0_holds (regs : Nat → Word) (rd : Nat) (v : Word) (k : Nat) (hk : k < 32) :
    (sem regNext (rnEnvOf regs (rnWeOf rd) v)).getD k false = (regs 0).getLsbD k := by
  have h := sem_regNext_drive regs (rnWeOf rd) v 0 k (by norm_num) hk
  rw [show (32 : Nat) * 0 + k = k from by omega] at h
  rw [h, show rnWeOf rd 0 = false from by simp [rnWeOf], if_neg (by simp)]

/-! ## ⭐ THE SAMPLED CERTIFICATES, SUPERSEDED -/

def rnDrive (R W : Nat) (we : Nat → Bool) : Env := fun i =>
  if i < R then we i
  else if i < R + W then rnResPat (i - R)
  else rnCurPat ((i - R - W) / W) ((i - R - W) % W)

theorem rnRun_eq_drive (R W : Nat) (we : Nat → Bool) :
    rnRun R W we = sem (regNextN R W) (rnDrive R W we) := rfl

theorem rnDrive_we (R W : Nat) (we : Nat → Bool) (r : Nat) (hr : r < R) :
    rnDrive R W we (rnWe r) = we r := by
  show (if r < R then we r else _) = _
  rw [if_pos hr]

theorem rnDrive_res (R W : Nat) (we : Nat → Bool) (k : Nat) (hk : k < W) :
    rnDrive R W we (rnRes R k) = rnResPat k := by
  show (if (R + k : Nat) < R then we (R + k)
        else if (R + k : Nat) < R + W then rnResPat (R + k - R)
        else rnCurPat ((R + k - R - W) / W) ((R + k - R - W) % W)) = _
  rw [if_neg (by omega), if_pos (by omega), show R + k - R = k from by omega]

theorem rnDrive_cur (R W : Nat) (hW : 0 < W) (we : Nat → Bool) (r k : Nat) (hk : k < W) :
    rnDrive R W we (rnCur R W r k) = rnCurPat r k := by
  show (if (R + W + W * r + k : Nat) < R then we (R + W + W * r + k)
        else if (R + W + W * r + k : Nat) < R + W then rnResPat (R + W + W * r + k - R)
        else rnCurPat ((R + W + W * r + k - R - W) / W)
               ((R + W + W * r + k - R - W) % W)) = _
  rw [if_neg (by omega), if_neg (by omega),
    show (R + W + W * r + k - R - W : Nat) = W * r + k from by omega,
    Nat.mul_add_div hW, Nat.mul_add_mod, Nat.div_eq_of_lt hk, Nat.mod_eq_of_lt hk,
    Nat.add_zero]

/-- ⭐ **THE DRIVEN ARRAY MEETS ITS SPEC AT EVERY SIZE AND EVERY ENABLE VECTOR** —
the statement the two kernel certificates sample. -/
theorem rnRun_eq_rnSpec (R W : Nat) (hW : 0 < W) (we : Nat → Bool) :
    rnRun R W we = rnSpec R W we := by
  rw [rnRun_eq_drive, sem_regNextN]
  unfold rnSpec
  refine List.flatMap_congr ?_
  intro r hr
  refine List.map_congr_left ?_
  intro k hk
  rw [rnDrive_we R W we r (List.mem_range.mp hr),
    rnDrive_res R W we k (List.mem_range.mp hk),
    rnDrive_cur R W hW we r k (List.mem_range.mp hk)]

/-- ⭐ `regNext4_correct_on_all_enables`, now a corollary. -/
theorem rnAllWeOK_uncond : rnAllWeOK = true := by
  unfold rnAllWeOK
  refine List.all_eq_true.mpr (fun m _ => ?_)
  rw [rnRun_eq_rnSpec 4 4 (by norm_num)]
  exact beq_self_eq_true _

/-- ⭐ `regNext8_correct`, now a corollary — and no longer only at the nine
sampled enable vectors. -/
theorem rnOneHotOK_uncond : rnOneHotOK = true := by
  unfold rnOneHotOK
  refine (Bool.and_eq_true _ _).mpr ⟨?_, ?_⟩
  · refine List.all_eq_true.mpr (fun r0 _ => ?_)
    rw [rnRun_eq_rnSpec 8 8 (by norm_num)]
    exact beq_self_eq_true _
  · rw [rnRun_eq_rnSpec 8 8 (by norm_num)]
    exact beq_self_eq_true _

/-- ⭐ The three 32×32 point certificates, at EVERY write-enable index and both
data polarities. -/
theorem rnBit_uncond (wr : Nat) (resBit curBit : Bool) :
    rnBit wr resBit curBit = if wr = 0 then resBit else curBit := by
  have h := regNext_getD (rnEnv wr resBit curBit) 0 0 (by norm_num) (by norm_num)
  rw [show (32 : Nat) * 0 + 0 = 0 from rfl] at h
  rw [show rnBit wr resBit curBit
        = (sem regNext (rnEnv wr resBit curBit)).getD 0 false from rfl, h,
    show rnEnv wr resBit curBit (rnWe 0) = decide (0 = wr) from rfl,
    show rnEnv wr resBit curBit (rnRes 32 0) = resBit from rfl,
    show rnEnv wr resBit curBit (rnCur 32 32 0 0) = curBit from rfl]
  by_cases hw : wr = 0
  · simp [hw]
  · have hw' : ¬ ((0 : Nat) = wr) := fun hc => hw hc.symm
    simp [hw, hw']

/-! ## ⛔ THE CONTROL — a mutant the certificates accept -/

/-- ⛔ **ONE FANIN MUTATED**: cell `(5,5)`'s result leg reads the CURRENT bit, so
that cell holds instead of writing. `regNextN 4 4` has no such cell; at
`regNextN 8 8` the sampled patterns agree there (`rnResPat 5 = rnCurPat 5 5`);
and the three 32×32 certificates read output 0 only. -/
def rnMuxCut (R W r k : Nat) : List Gate :=
  [ ⟨rnMuxBase R W r k,     .and (rnNotWe R W r) (rnCur R W r k)⟩
  , ⟨rnMuxBase R W r k + 1,
      .and (rnWe r) (if r == 5 && k == 5 then rnCur R W r k else rnRes R k)⟩
  , ⟨rnOut R W r k,         .or (rnMuxBase R W r k) (rnMuxBase R W r k + 1)⟩ ]

def regNextNCut (R W : Nat) : Circ :=
  { regNextN R W with
    gates := (List.range R).map (fun r => (⟨rnNotWe R W r, .not (rnWe r)⟩ : Gate))
               ++ (List.range R).flatMap (fun r => (List.range W).flatMap (rnMuxCut R W r)) }

def rnRunCut (R W : Nat) (we : Nat → Bool) : List Bool :=
  sem (regNextNCut R W) (rnDrive R W we)

def rnAllWeOKCut : Bool :=
  (List.range 16).all fun m =>
    rnRunCut 4 4 (fun r => Nat.testBit m r) == rnSpec 4 4 (fun r => Nat.testBit m r)

def rnOneHotOKCut : Bool :=
  ((List.range 8).all fun r0 => rnRunCut 8 8 (· == r0) == rnSpec 8 8 (· == r0))
    && (rnRunCut 8 8 (fun _ => false) == rnSpec 8 8 (fun _ => false))

def rnBitCut (wr : Nat) (resBit curBit : Bool) : Bool :=
  (sem (regNextNCut 32 32) (rnEnv wr resBit curBit)).getD 0 false

theorem regNextCut_ssa : (regNextNCut 8 8).ssa = true := by decide +kernel

theorem regNextCut_gate_count : (regNextNCut 32 32).gates.length = 3104 := by decide +kernel

/-- ⛔ **THE MUTANT PASSES EVERY BEHAVIOURAL CERTIFICATE THE BLOCK CARRIES** —
both `rnRun`/`rnSpec` sweeps, the frame certificate, the no-enable certificate,
and all three 32×32 samples. -/
theorem regNextCut_passes_the_certificate :
    rnAllWeOKCut = true ∧ rnOneHotOKCut = true := ⟨by decide +kernel, by decide +kernel⟩

theorem regNextCut_passes_the_frame_certificate :
    ((List.range 8).all fun r => (List.range 8).all fun k =>
      (rnRunCut 8 8 (· == 5)).getD (8 * r + k) false
        == (if r == 5 then rnResPat k else rnCurPat r k)) = true := by decide +kernel

theorem regNextCut_passes_the_hold_certificate :
    rnRunCut 8 8 (fun _ => false)
      = (List.range 8).flatMap (fun r => (List.range 8).map (rnCurPat r)) := by decide +kernel

theorem regNextCut_passes_the_32_samples :
    rnBitCut 0 true false = true ∧ rnBitCut 1 true false = false
      ∧ rnBitCut 1 false true = true :=
  ⟨by decide +kernel, by decide +kernel, by decide +kernel⟩

def rnCutWitness : Env := fun n => decide (n < 16)

/-- ⭐ **AND THE UNCONDITIONAL THEOREM REFUTES IT** — at an enable vector no
sample contains (all eight raised at once), cell `(5,5)` holds where the
specification writes. -/
theorem regNextCut_fails_the_theorem :
    sem (regNextNCut 8 8) rnCutWitness
      ≠ (List.range 8).flatMap (fun r =>
          (List.range 8).map (fun k =>
            if rnCutWitness (rnWe r) then rnCutWitness (rnRes 8 k)
            else rnCutWitness (rnCur 8 8 r k))) := by
  decide +kernel

/-! ## Off every sample -/

def rnOffEnv : Env := fun n =>
  if n < 32 then (n == 17 || n == 3)
  else if n < 64 then Nat.testBit 0xF0F0F0F0 (n - 32)
  else Nat.testBit 0x0F0F0F0F ((n - 64) % 32)

/-- ⭐ **TWO ENABLES AT ONCE, READ AT A BIT NO CERTIFICATE TOUCHES.** The 32×32
certificates read output 0; the 8×8 sweep is one-hot-or-empty; this is neither. -/
theorem sem_regNext_off_the_sample :
    (rnOffEnv (rnWe 17) = true ∧ rnOffEnv (rnWe 3) = true)
      ∧ (32 * 17 + 5 ≠ 0 ∧ 32 * 2 + 5 ≠ 0)
      ∧ (sem regNext rnOffEnv).getD (32 * 17 + 5) false = true
      ∧ (sem regNext rnOffEnv).getD (32 * 2 + 5) false = false := by
  refine ⟨⟨rfl, rfl⟩, ⟨by norm_num, by norm_num⟩, ?_, ?_⟩
  · rw [regNext_getD rnOffEnv 17 5 (by norm_num) (by norm_num)]; decide
  · rw [regNext_getD rnOffEnv 2 5 (by norm_num) (by norm_num)]; decide

end RegNextSemantics

section DecoderSemantics

open SaltWorks.HDL hiding seenWord
open Salt.Tactic

/-!
## DECODER-UNCOND — the decoder, off the sample and over the whole word space

`HDL/Decoder.lean`'s certificates are `decide +kernel` over **3,056 words**, every
one of them built by `dcWord op f3 f7`, which leaves bits 7-11, 15-19 and 20-24 at
zero. The file's docstring (`Decoder.lean:38-58`) argues that this is enough
because *"the control signals depend on the word ONLY through `opcode`, `funct3`
and the single predicate `funct7 = 0`"* — and then concedes, in the same
paragraph, ***"Stating the projection is the whole argument."***

⛔ **IT WAS NEVER STATED.** Not for the circuit, not for `ctrlSpec`. Until it is,
3,056 points say nothing about the other 4,294,964,240 words, and
`RegField`/`PcField` quantify over **every** environment. This section states it,
on both sides, and then does not need it: the route below computes the circuit's
six outputs symbolically, so the projection falls out as a corollary of a
*stronger* fact rather than being assumed as a lemma.

### What is actually here, in dependency order

1. **The `andChain` lemma set** (`andChain_nil` … `run_andChain`), mirroring the
   five `orChain` lemmas at `:3640`. ⭐ *This asymmetry was backwards from where
   the gates are*: `orChain` contributes 4 of the decoder's 102 gates and had a
   complete lemma set; `andChain` contributes **66** and had none — `grep -F
   andChain` returned its own definition, its own recursive call, one use site and
   two audit lines. The proofs transfer from `orChain` line for line with
   `any → all` and `Bool.or_assoc → Bool.and_assoc`.
2. **`sem_decoder`** — the six outputs as an explicit `Bool` formula in
   `w`'s opcode / funct3 / funct7-zero predicates, for a **symbolic** `w`.
3. **`ctrlSpec_eq`** — the same six, read off `ISA.decode`'s nested `if`-chain.
   This is where opcode-disjointness and the **two distinct paths to `none`** are
   discharged (`ISA.lean:572`'s interior `else none` for a bad `funct3` at
   `funct7 = 0`, and `ISA.lean:582`'s fallthrough for `funct7 ≠ 0`).
4. **`decoder_correct`** — `∀ w, ctrlOf w = ctrlSpec w`, unconditional.
5. Controls: the theorem **implies** all three landed sampled certificates, and
   **rejects** a mutant decoder that passes none of them.

### The reduction facts, and why they are `decide +kernel`

`andChain` and `orChain` are well-founded recursive (`Decoder.lean:87`, `:96`),
and `Sem.lean:20-22` states the consequence: WF recursion does not reduce during
elaboration. The gate list is nevertheless a **closed** term, so the kernel can
be asked for its value directly; what it cannot do is reduce it under a binder.
Hence the shape below — `decide +kernel` for the layout constants (net numbers,
gate lists), `run_andChain`/`run_orChain` for everything under `∀ w`.
-/

/-! ### The `andChain` lemma set -/

/-- `List.all` respects pointwise agreement on membership — the `List.any`
counterpart is `any_congr_mem` (`:3535`). -/
theorem all_congr_mem {α : Type} {l : List α} {p q : α → Bool} (h : ∀ x ∈ l, p x = q x) :
    l.all p = l.all q := by
  induction l with
  | nil => rfl
  | cons a as ih =>
    rw [List.all_cons, List.all_cons, h a (by simp), ih (fun x hx => h x (by simp [hx]))]

theorem andChain_nil (b : Nat) : andChain b ([] : List Net) = ([], 0, b) := by
  conv_lhs => rw [andChain]

theorem andChain_one (b : Nat) (x : Net) : andChain b [x] = ([], x, b) := by
  conv_lhs => rw [andChain]

theorem andChain_cons2 (b : Nat) (x y : Net) (r : List Net) :
    andChain b (x :: y :: r)
      = (⟨b, .and x y⟩ :: (andChain (b + 1) (b :: r)).1,
         (andChain (b + 1) (b :: r)).2.1, (andChain (b + 1) (b :: r)).2.2) := by
  conv_lhs => rw [andChain]

/-- Every gate an `andChain` emits lands at or above its base. The `fuel`
argument is the induction measure: `andChain`'s recursive argument `b :: r` is
not a subterm of `x :: y :: r`, so the recursion is on **length**, not structure.
-/
theorem andChain_out_ge : ∀ (fuel : Nat) (ns : List Net) (b : Nat), ns.length ≤ fuel →
    ∀ g ∈ (andChain b ns).1, b ≤ g.out := by
  intro fuel
  induction fuel with
  | zero =>
    intro ns b h g hg
    rw [List.eq_nil_of_length_eq_zero (Nat.le_zero.mp h), andChain_nil] at hg
    exact absurd hg (List.not_mem_nil)
  | succ f ih =>
    intro ns b h g hg
    match ns with
    | [] => rw [andChain_nil] at hg; exact absurd hg (List.not_mem_nil)
    | [x] => rw [andChain_one] at hg; exact absurd hg (List.not_mem_nil)
    | x :: y :: r =>
      rw [andChain_cons2] at hg
      simp only [List.mem_cons] at hg
      rcases hg with rfl | hg
      · exact Nat.le_refl b
      · have hlen : (b :: r).length ≤ f := by
          simp only [List.length_cons] at h ⊢
          omega
        exact Nat.le_of_succ_le (ih (b :: r) (b + 1) hlen g hg)

/-- Nothing below the base moves. -/
theorem run_andChain_frame (fuel : Nat) (E : Env) (ns : List Net) (b : Nat)
    (h : ns.length ≤ fuel) (m : Nat) (hm : m < b) : run E (andChain b ns).1 m = E m :=
  run_of_unwritten E _ m (fun g hg =>
    Nat.ne_of_gt (Nat.lt_of_lt_of_le hm (andChain_out_ge fuel ns b h g hg)))

/-- ⭐ **The chain computes the conjunction.** Stated over `andChain`
generically, exactly as `run_orChain` is stated over `orChain`, so it is not
specialised to the decoder's five instances. -/
theorem run_andChain : ∀ (fuel : Nat) (E : Env) (ns : List Net) (b : Nat),
    ns.length ≤ fuel → ns ≠ [] → (∀ m ∈ ns, m < b) →
    run E (andChain b ns).1 ((andChain b ns).2.1) = ns.all E := by
  intro fuel
  induction fuel with
  | zero =>
    intro E ns b h hne _
    exact absurd (List.eq_nil_of_length_eq_zero (Nat.le_zero.mp h)) hne
  | succ f ih =>
    intro E ns b h hne hlt
    match ns with
    | [] => exact absurd rfl hne
    | [x] =>
      rw [andChain_one]
      simp
    | x :: y :: r =>
      rw [andChain_cons2]
      show run (upd E b ((Op.and x y).eval E)) (andChain (b + 1) (b :: r)).1
          ((andChain (b + 1) (b :: r)).2.1) = _
      have hlen : (b :: r).length ≤ f := by
        simp only [List.length_cons] at h ⊢
        omega
      have hlt' : ∀ m ∈ (b :: r), m < b + 1 := by
        intro m hm
        rcases List.mem_cons.mp hm with rfl | hm
        · exact Nat.lt_succ_self m
        · exact Nat.lt_succ_of_lt (hlt m (by simp [hm]))
      rw [ih (upd E b ((Op.and x y).eval E)) (b :: r) (b + 1) hlen (by simp) hlt']
      rw [List.all_cons, List.all_cons, List.all_cons, upd_self,
        all_congr_mem (l := r) (p := upd E b ((Op.and x y).eval E)) (q := E)
          (fun m hm => upd_of_ne _ (Nat.ne_of_lt (hlt m (by simp [hm]))))]
      show ((E x && E y) && r.all E) = (E x && (E y && r.all E))
      exact Bool.and_assoc (E x) (E y) (r.all E)

/-! ### ⭐ THE CIRCUIT'S SIX OUTPUTS, SYMBOLICALLY, FOR A **SYMBOLIC** WORD

The landed certificates evaluate the netlist at 3,056 concrete points. Nothing
below evaluates it anywhere: `decoder`'s **gate list is a closed term**, so the
kernel can be asked for the layout constants once (`decide +kernel` on net
numbers), while everything under `∀ w` goes through `run_andChain` /
`run_orChain` / `run_pointwise`. That is the only route available — `andChain`
and `orChain` are well-founded recursive and will not reduce under a binder.

⛔ **C-D2 — DO THE THREE CERTIFIED SLICES TILE THE CUBE? THEY DO NOT, AND THIS
ROUTE DOES NOT NEED THEM TO.** `decoder_funct7_exhaustive` sweeps 128 `funct7`
values **at one opcode** (`Decoder.lean:173` — `dcWord 0b0110011 f3 f7`), so the
"funct7 is read only through is-it-zero" factorisation that would license
`funct7 = 1` standing for every non-zero `funct7` is certified on a single
opcode plane, not on the product. The theorem below is proved over `∀ w :
BitVec 32` directly, so it never asks whether the slices tile. -/

/-! ### The layout as concrete constants -/

def dcL1 : List Net := dcOpcode 0b0110011 ++ dcFunct7Zero ++ dcFunct3 0b000
def dcL2 : List Net := dcOpcode 0b0110011 ++ dcFunct7Zero ++ dcFunct3 0b100
def dcL3 : List Net := dcOpcode 0b0110011 ++ dcFunct7Zero ++ dcFunct3 0b010
def dcL4 : List Net := dcOpcode 0b0010011 ++ dcFunct3 0b000
def dcL5 : List Net := dcOpcode 0b1100011 ++ dcFunct3 0b000
-- ⬥ D2. The two memory rows, APPENDED. Opcode and funct3 only, no `funct7`.
def dcL6 : List Net := dcOpcode 0b0000011 ++ dcFunct3 0b010
def dcL7 : List Net := dcOpcode 0b0100011 ++ dcFunct3 0b010

def dcG1 : List Gate := (andChain 64 dcL1).1
def dcG2 : List Gate := (andChain 80 dcL2).1
def dcG3 : List Gate := (andChain 96 dcL3).1
def dcG4 : List Gate := (andChain 112 dcL4).1
def dcG5 : List Gate := (andChain 121 dcL5).1
def dcG6 : List Gate := (andChain 130 dcL6).1
def dcG7 : List Gate := (andChain 139 dcL7).1
def dcGM : List Gate := dcG1 ++ (dcG2 ++ (dcG3 ++ (dcG4 ++ (dcG5 ++ (dcG6 ++ dcG7)))))
/-- ⬥ **D2 — the memory-access aggregate's OR chain.** *One gate: `req = isLW ∨
isSW`. It is allocated BEFORE `valid`'s chain, which is what puts `req` at
index 7 and keeps `valid` on the tail.* -/
def dcGR : List Gate := (orChain 148 [138, 147]).1
def dcGO : List Gate := (orChain 149 [79, 95, 111, 120, 129, 138, 147]).1

/-- ⬥ **D2 re-cut this: 70 gates → 123, and the STRUCTURE gained a layer.**
*`dcGM` grew by two AND chains; `dcGR` is new; `dcGO` moved base and widened from
five inputs to seven. **The inverter bank and `dcG1…dcG5` are untouched** — that
is `decoder_gate_prefix` in `HDL/Decoder.lean`, and it is why the ~25 net-numbered
declarations below this line did not move.* -/
theorem decoder_gates_eq : decoder.gates = dcInvs ++ (dcGM ++ (dcGR ++ dcGO)) := by
  decide +kernel

/-- ⬥ **D2 re-cut this, and `run_decoder_out` moved WITH it, in this commit.**
*They are one fact in two shapes: the output NET list and what each net carries.
Splitting them across commits leaves a window where the file says where to look
and lies about what is there.* -/
theorem decoder_outs_eq :
    decoder.outs = [79, 95, 111, 120, 129, 138, 147, 148, 154] := by decide +kernel

theorem dcOut1 : (andChain 64 dcL1).2.1 = 79 := by decide +kernel
theorem dcOut2 : (andChain 80 dcL2).2.1 = 95 := by decide +kernel
theorem dcOut3 : (andChain 96 dcL3).2.1 = 111 := by decide +kernel
theorem dcOut4 : (andChain 112 dcL4).2.1 = 120 := by decide +kernel
theorem dcOut5 : (andChain 121 dcL5).2.1 = 129 := by decide +kernel
theorem dcOut6 : (andChain 130 dcL6).2.1 = 138 := by decide +kernel
theorem dcOut7 : (andChain 139 dcL7).2.1 = 147 := by decide +kernel
theorem dcOutR : (orChain 148 [138, 147]).2.1 = 148 := by decide +kernel
theorem dcOutO :
    (orChain 149 [79, 95, 111, 120, 129, 138, 147]).2.1 = 154 := by decide +kernel

theorem dcL1_lt : ∀ m ∈ dcL1, m < 64 := by decide
theorem dcL2_lt : ∀ m ∈ dcL2, m < 64 := by decide
theorem dcL3_lt : ∀ m ∈ dcL3, m < 64 := by decide
theorem dcL4_lt : ∀ m ∈ dcL4, m < 64 := by decide
theorem dcL5_lt : ∀ m ∈ dcL5, m < 64 := by decide
theorem dcL6_lt : ∀ m ∈ dcL6, m < 64 := by decide
theorem dcL7_lt : ∀ m ∈ dcL7, m < 64 := by decide

theorem dcL1_ne : dcL1 ≠ [] := by decide
theorem dcL2_ne : dcL2 ≠ [] := by decide
theorem dcL3_ne : dcL3 ≠ [] := by decide
theorem dcL4_ne : dcL4 ≠ [] := by decide
theorem dcL5_ne : dcL5 ≠ [] := by decide
theorem dcL6_ne : dcL6 ≠ [] := by decide
theorem dcL7_ne : dcL7 ≠ [] := by decide

/-! ### Frames and values, one per chain -/

theorem dcG1_frame (E : Env) (m : Nat) (h : m < 64) : run E dcG1 m = E m :=
  run_andChain_frame 17 E dcL1 64 (by decide) m h
theorem dcG2_frame (E : Env) (m : Nat) (h : m < 80) : run E dcG2 m = E m :=
  run_andChain_frame 17 E dcL2 80 (by decide) m h
theorem dcG3_frame (E : Env) (m : Nat) (h : m < 96) : run E dcG3 m = E m :=
  run_andChain_frame 17 E dcL3 96 (by decide) m h
theorem dcG4_frame (E : Env) (m : Nat) (h : m < 112) : run E dcG4 m = E m :=
  run_andChain_frame 10 E dcL4 112 (by decide) m h
theorem dcG5_frame (E : Env) (m : Nat) (h : m < 121) : run E dcG5 m = E m :=
  run_andChain_frame 10 E dcL5 121 (by decide) m h
theorem dcG6_frame (E : Env) (m : Nat) (h : m < 130) : run E dcG6 m = E m :=
  run_andChain_frame 10 E dcL6 130 (by decide) m h
theorem dcG7_frame (E : Env) (m : Nat) (h : m < 139) : run E dcG7 m = E m :=
  run_andChain_frame 10 E dcL7 139 (by decide) m h
theorem dcGR_frame (E : Env) (m : Nat) (h : m < 148) : run E dcGR m = E m :=
  run_orChain_frame 2 E [138, 147] 148 (by decide) m h
theorem dcGO_frame (E : Env) (m : Nat) (h : m < 149) : run E dcGO m = E m :=
  run_orChain_frame 7 E [79, 95, 111, 120, 129, 138, 147] 149 (by decide) m h

theorem dcG1_val (E : Env) : run E dcG1 79 = dcL1.all E := by
  have := run_andChain 17 E dcL1 64 (by decide) dcL1_ne (fun m hm => dcL1_lt m hm)
  rw [dcOut1] at this
  exact this
theorem dcG2_val (E : Env) : run E dcG2 95 = dcL2.all E := by
  have := run_andChain 17 E dcL2 80 (by decide) dcL2_ne
    (fun m hm => Nat.lt_trans (dcL2_lt m hm) (by norm_num))
  rw [dcOut2] at this
  exact this
theorem dcG3_val (E : Env) : run E dcG3 111 = dcL3.all E := by
  have := run_andChain 17 E dcL3 96 (by decide) dcL3_ne
    (fun m hm => Nat.lt_trans (dcL3_lt m hm) (by norm_num))
  rw [dcOut3] at this
  exact this
theorem dcG4_val (E : Env) : run E dcG4 120 = dcL4.all E := by
  have := run_andChain 10 E dcL4 112 (by decide) dcL4_ne
    (fun m hm => Nat.lt_trans (dcL4_lt m hm) (by norm_num))
  rw [dcOut4] at this
  exact this
theorem dcG5_val (E : Env) : run E dcG5 129 = dcL5.all E := by
  have := run_andChain 10 E dcL5 121 (by decide) dcL5_ne
    (fun m hm => Nat.lt_trans (dcL5_lt m hm) (by norm_num))
  rw [dcOut5] at this
  exact this
theorem dcG6_val (E : Env) : run E dcG6 138 = dcL6.all E := by
  have := run_andChain 10 E dcL6 130 (by decide) dcL6_ne
    (fun m hm => Nat.lt_trans (dcL6_lt m hm) (by norm_num))
  rw [dcOut6] at this
  exact this
theorem dcG7_val (E : Env) : run E dcG7 147 = dcL7.all E := by
  have := run_andChain 10 E dcL7 139 (by decide) dcL7_ne
    (fun m hm => Nat.lt_trans (dcL7_lt m hm) (by norm_num))
  rw [dcOut7] at this
  exact this
/-- ⬥ **D2 — `req`'s value.** *The aggregate is one OR of the two memory
matchers; `dmem_addr8.v:80` takes exactly this wire as its access strobe.* -/
theorem dcGR_val (E : Env) : run E dcGR 148 = [138, 147].any E := by
  have := run_orChain 2 E [138, 147] 148 (by decide) (by decide) (by decide)
  rw [dcOutR] at this
  exact this
theorem dcGO_val (E : Env) :
    run E dcGO 154 = [79, 95, 111, 120, 129, 138, 147].any E := by
  have := run_orChain 7 E [79, 95, 111, 120, 129, 138, 147] 149
    (by decide) (by decide) (by decide)
  rw [dcOutO] at this
  exact this

/-! ### The match block, composed -/

theorem run_dcGM (E : Env) :
    run E dcGM 79 = dcL1.all E ∧ run E dcGM 95 = dcL2.all E
    ∧ run E dcGM 111 = dcL3.all E ∧ run E dcGM 120 = dcL4.all E
    ∧ run E dcGM 129 = dcL5.all E ∧ run E dcGM 138 = dcL6.all E
    ∧ run E dcGM 147 = dcL7.all E := by
  have hM : dcGM
      = dcG1 ++ (dcG2 ++ (dcG3 ++ (dcG4 ++ (dcG5 ++ (dcG6 ++ dcG7))))) := rfl
  rw [hM, run_append, run_append, run_append, run_append, run_append, run_append]
  set A1 := run E dcG1 with hA1
  set A2 := run A1 dcG2 with hA2
  set A3 := run A2 dcG3 with hA3
  set A4 := run A3 dcG4 with hA4
  set A5 := run A4 dcG5 with hA5
  set A6 := run A5 dcG6 with hA6
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · rw [dcG7_frame A6 79 (by norm_num), hA6, dcG6_frame A5 79 (by norm_num), hA5,
      dcG5_frame A4 79 (by norm_num), hA4, dcG4_frame A3 79 (by norm_num),
      hA3, dcG3_frame A2 79 (by norm_num), hA2, dcG2_frame A1 79 (by norm_num),
      hA1, dcG1_val E]
  · rw [dcG7_frame A6 95 (by norm_num), hA6, dcG6_frame A5 95 (by norm_num), hA5,
      dcG5_frame A4 95 (by norm_num), hA4, dcG4_frame A3 95 (by norm_num),
      hA3, dcG3_frame A2 95 (by norm_num), hA2, dcG2_val A1, hA1]
    exact all_congr_mem (fun m hm => dcG1_frame E m (dcL2_lt m hm))
  · rw [dcG7_frame A6 111 (by norm_num), hA6, dcG6_frame A5 111 (by norm_num), hA5,
      dcG5_frame A4 111 (by norm_num), hA4, dcG4_frame A3 111 (by norm_num),
      hA3, dcG3_val A2, hA2, hA1]
    refine all_congr_mem (fun m hm => ?_)
    rw [dcG2_frame (run E dcG1) m (Nat.lt_trans (dcL3_lt m hm) (by norm_num)),
      dcG1_frame E m (dcL3_lt m hm)]
  · rw [dcG7_frame A6 120 (by norm_num), hA6, dcG6_frame A5 120 (by norm_num), hA5,
      dcG5_frame A4 120 (by norm_num), hA4, dcG4_val A3, hA3, hA2, hA1]
    refine all_congr_mem (fun m hm => ?_)
    rw [dcG3_frame (run (run E dcG1) dcG2) m (Nat.lt_trans (dcL4_lt m hm) (by norm_num)),
      dcG2_frame (run E dcG1) m (Nat.lt_trans (dcL4_lt m hm) (by norm_num)),
      dcG1_frame E m (dcL4_lt m hm)]
  · rw [dcG7_frame A6 129 (by norm_num), hA6, dcG6_frame A5 129 (by norm_num), hA5,
      dcG5_val A4, hA4, hA3, hA2, hA1]
    refine all_congr_mem (fun m hm => ?_)
    rw [dcG4_frame (run (run (run E dcG1) dcG2) dcG3) m
        (Nat.lt_trans (dcL5_lt m hm) (by norm_num)),
      dcG3_frame (run (run E dcG1) dcG2) m (Nat.lt_trans (dcL5_lt m hm) (by norm_num)),
      dcG2_frame (run E dcG1) m (Nat.lt_trans (dcL5_lt m hm) (by norm_num)),
      dcG1_frame E m (dcL5_lt m hm)]
  · rw [dcG7_frame A6 138 (by norm_num), hA6, dcG6_val A5, hA5, hA4, hA3, hA2, hA1]
    refine all_congr_mem (fun m hm => ?_)
    rw [dcG5_frame (run (run (run (run E dcG1) dcG2) dcG3) dcG4) m
        (Nat.lt_trans (dcL6_lt m hm) (by norm_num)),
      dcG4_frame (run (run (run E dcG1) dcG2) dcG3) m
        (Nat.lt_trans (dcL6_lt m hm) (by norm_num)),
      dcG3_frame (run (run E dcG1) dcG2) m (Nat.lt_trans (dcL6_lt m hm) (by norm_num)),
      dcG2_frame (run E dcG1) m (Nat.lt_trans (dcL6_lt m hm) (by norm_num)),
      dcG1_frame E m (dcL6_lt m hm)]
  · rw [dcG7_val A6, hA6, hA5, hA4, hA3, hA2, hA1]
    refine all_congr_mem (fun m hm => ?_)
    rw [dcG6_frame (run (run (run (run (run E dcG1) dcG2) dcG3) dcG4) dcG5) m
        (Nat.lt_trans (dcL7_lt m hm) (by norm_num)),
      dcG5_frame (run (run (run (run E dcG1) dcG2) dcG3) dcG4) m
        (Nat.lt_trans (dcL7_lt m hm) (by norm_num)),
      dcG4_frame (run (run (run E dcG1) dcG2) dcG3) m
        (Nat.lt_trans (dcL7_lt m hm) (by norm_num)),
      dcG3_frame (run (run E dcG1) dcG2) m (Nat.lt_trans (dcL7_lt m hm) (by norm_num)),
      dcG2_frame (run E dcG1) m (Nat.lt_trans (dcL7_lt m hm) (by norm_num)),
      dcG1_frame E m (dcL7_lt m hm)]

theorem dcGM_frame (E : Env) (m : Nat) (h : m < 64) : run E dcGM m = E m := by
  have hM : dcGM
      = dcG1 ++ (dcG2 ++ (dcG3 ++ (dcG4 ++ (dcG5 ++ (dcG6 ++ dcG7))))) := rfl
  rw [hM, run_append, run_append, run_append, run_append, run_append, run_append,
    dcG7_frame _ m (by omega), dcG6_frame _ m (by omega),
    dcG5_frame _ m (by omega), dcG4_frame _ m (by omega), dcG3_frame _ m (by omega),
    dcG2_frame _ m (by omega), dcG1_frame E m h]

/-! ### The inverter bank and the literal fields -/

theorem run_dcInvs (E : Env) :
    (∀ m : Nat, m < 32 → run E dcInvs m = E m)
    ∧ (∀ k : Nat, k < 32 → run E dcInvs (32 + k) = !(E k)) := by
  have hgates : dcInvs = (List.range 32).map (fun i => (⟨32 + i, Op.not i⟩ : Gate)) := rfl
  obtain ⟨hfr, hval⟩ := run_pointwise E 32 (fun i => Op.not i) 32
    (fun i hi c hc => by
      simp only [Op.fanin, List.mem_cons, List.not_mem_nil, or_false] at hc
      exact hc ▸ hi)
  exact ⟨fun m hm => by rw [hgates]; exact hfr m hm,
         fun k hk => by rw [hgates]; exact hval k hk⟩

theorem run_dcInvs_lit (E : Env) (i : Nat) (hi : i < 32) (v : Bool) :
    run E dcInvs (dcLit i v) = (E i == v) := by
  cases v with
  | true =>
    show run E dcInvs i = (E i == true)
    rw [(run_dcInvs E).1 i hi]
    simp
  | false =>
    show run E dcInvs (32 + i) = (E i == false)
    rw [(run_dcInvs E).2 i hi]
    simp

theorem run_dcInvs_field (E : Env) (lo n val : Nat) (h : lo + n ≤ 32) :
    (dcField lo n val).all (run E dcInvs)
      = (List.range n).all (fun j => E (lo + j) == val.testBit j) := by
  show ((List.range n).map (fun j => dcLit (lo + j) (val.testBit j))).all (run E dcInvs) = _
  rw [List.all_map]
  refine all_congr_mem (fun j hj => ?_)
  have hj' : lo + j < 32 := by
    have := List.mem_range.mp hj
    omega
  exact run_dcInvs_lit E (lo + j) hj' (val.testBit j)

theorem field_all_eq_extract (w : BitVec 32) (lo n val : Nat) :
    ((List.range n).all (fun j => (w.getLsbD (lo + j)) == val.testBit j))
      = decide (w.extractLsb' lo n = BitVec.ofNat n val) := by
  rw [Bool.eq_iff_iff]
  simp only [List.all_eq_true, List.mem_range, beq_iff_eq, decide_eq_true_eq]
  rw [BitVec.eq_of_getLsbD_eq_iff]
  constructor
  · intro hh j hj
    simp only [BitVec.getLsbD_extractLsb', BitVec.getLsbD_ofNat, hj, decide_true, Bool.true_and]
    exact hh j hj
  · intro hh j hj
    have hx := hh j hj
    simp only [BitVec.getLsbD_extractLsb', BitVec.getLsbD_ofNat, hj, decide_true,
      Bool.true_and] at hx
    exact hx

def dcOpIs (w : BitVec 32) (val : Nat) : Bool := decide (w.extractLsb' 0 7 = BitVec.ofNat 7 val)
def dcF3Is (w : BitVec 32) (val : Nat) : Bool := decide (w.extractLsb' 12 3 = BitVec.ofNat 3 val)
def dcF7Z  (w : BitVec 32) : Bool := decide (w.extractLsb' 25 7 = BitVec.ofNat 7 0)

theorem dcOpcode_all (w : BitVec 32) (val : Nat) :
    (dcOpcode val).all (run (fun i => w.getLsbD i) dcInvs) = dcOpIs w val := by
  show (dcField 0 7 val).all (run (fun i => w.getLsbD i) dcInvs) = _
  rw [run_dcInvs_field _ 0 7 val (by norm_num)]
  exact field_all_eq_extract w 0 7 val

theorem dcFunct3_all (w : BitVec 32) (val : Nat) :
    (dcFunct3 val).all (run (fun i => w.getLsbD i) dcInvs) = dcF3Is w val := by
  show (dcField 12 3 val).all (run (fun i => w.getLsbD i) dcInvs) = _
  rw [run_dcInvs_field _ 12 3 val (by norm_num)]
  exact field_all_eq_extract w 12 3 val

theorem dcFunct7Zero_all (w : BitVec 32) :
    dcFunct7Zero.all (run (fun i => w.getLsbD i) dcInvs) = dcF7Z w := by
  show (dcField 25 7 0).all (run (fun i => w.getLsbD i) dcInvs) = _
  rw [run_dcInvs_field _ 25 7 0 (by norm_num)]
  exact field_all_eq_extract w 25 7 0

/-! ### The six outputs, symbolically -/

def dcADDm  (w : BitVec 32) : Bool := dcOpIs w 0b0110011 && dcF7Z w && dcF3Is w 0b000
def dcXORm  (w : BitVec 32) : Bool := dcOpIs w 0b0110011 && dcF7Z w && dcF3Is w 0b100
def dcSLTm  (w : BitVec 32) : Bool := dcOpIs w 0b0110011 && dcF7Z w && dcF3Is w 0b010
def dcADDIm (w : BitVec 32) : Bool := dcOpIs w 0b0010011 && dcF3Is w 0b000
def dcBEQm  (w : BitVec 32) : Bool := dcOpIs w 0b1100011 && dcF3Is w 0b000
-- ⬥ D2. The two memory matchers. `decode`'s LW/SW arms consult OPCODE and
-- FUNCT3 only, so neither predicate mentions `dcF7Z`.
def dcLWm   (w : BitVec 32) : Bool := dcOpIs w 0b0000011 && dcF3Is w 0b010
def dcSWm   (w : BitVec 32) : Bool := dcOpIs w 0b0100011 && dcF3Is w 0b010
/-- ⬥ **D2 — the memory-access aggregate.** *The ONE derived control bit: it is
not a `dcMatches` row because it aggregates, and `dmem_addr8.v:80` needs a single
access strobe. `dcSWm` reaches the port's `we_in` directly, needing no
combinator — the port takes one of each kind.* -/
def dcReqm  (w : BitVec 32) : Bool := dcLWm w || dcSWm w
/-- ⬥ **D2 widened this: `valid` now includes the memory ops.** *That is the
positive counterpart of M2's retired guard — the plane and `ISA.decode` are the
same partial function again.* -/
def dcValidm (w : BitVec 32) : Bool :=
  dcADDm w || dcXORm w || dcSLTm w || dcADDIm w || dcBEQm w || dcLWm w || dcSWm w

theorem dcL1_all (w : BitVec 32) : dcL1.all (run (fun i => w.getLsbD i) dcInvs) = dcADDm w := by
  show ((dcOpcode 0b0110011 ++ dcFunct7Zero) ++ dcFunct3 0b000).all _ = _
  rw [List.all_append, List.all_append, dcOpcode_all, dcFunct7Zero_all, dcFunct3_all]
  rfl

theorem dcL2_all (w : BitVec 32) : dcL2.all (run (fun i => w.getLsbD i) dcInvs) = dcXORm w := by
  show ((dcOpcode 0b0110011 ++ dcFunct7Zero) ++ dcFunct3 0b100).all _ = _
  rw [List.all_append, List.all_append, dcOpcode_all, dcFunct7Zero_all, dcFunct3_all]
  rfl

theorem dcL3_all (w : BitVec 32) : dcL3.all (run (fun i => w.getLsbD i) dcInvs) = dcSLTm w := by
  show ((dcOpcode 0b0110011 ++ dcFunct7Zero) ++ dcFunct3 0b010).all _ = _
  rw [List.all_append, List.all_append, dcOpcode_all, dcFunct7Zero_all, dcFunct3_all]
  rfl

theorem dcL4_all (w : BitVec 32) : dcL4.all (run (fun i => w.getLsbD i) dcInvs) = dcADDIm w := by
  show (dcOpcode 0b0010011 ++ dcFunct3 0b000).all _ = _
  rw [List.all_append, dcOpcode_all, dcFunct3_all]
  rfl

theorem dcL5_all (w : BitVec 32) : dcL5.all (run (fun i => w.getLsbD i) dcInvs) = dcBEQm w := by
  show (dcOpcode 0b1100011 ++ dcFunct3 0b000).all _ = _
  rw [List.all_append, dcOpcode_all, dcFunct3_all]
  rfl

theorem dcL6_all (w : BitVec 32) : dcL6.all (run (fun i => w.getLsbD i) dcInvs) = dcLWm w := by
  show (dcOpcode 0b0000011 ++ dcFunct3 0b010).all _ = _
  rw [List.all_append, dcOpcode_all, dcFunct3_all]
  rfl

theorem dcL7_all (w : BitVec 32) : dcL7.all (run (fun i => w.getLsbD i) dcInvs) = dcSWm w := by
  show (dcOpcode 0b0100011 ++ dcFunct3 0b010).all _ = _
  rw [List.all_append, dcOpcode_all, dcFunct3_all]
  rfl

theorem run_decoder_out (w : BitVec 32) :
    run (fun i => w.getLsbD i) decoder.gates 79 = dcADDm w
    ∧ run (fun i => w.getLsbD i) decoder.gates 95 = dcXORm w
    ∧ run (fun i => w.getLsbD i) decoder.gates 111 = dcSLTm w
    ∧ run (fun i => w.getLsbD i) decoder.gates 120 = dcADDIm w
    ∧ run (fun i => w.getLsbD i) decoder.gates 129 = dcBEQm w
    ∧ run (fun i => w.getLsbD i) decoder.gates 138 = dcLWm w
    ∧ run (fun i => w.getLsbD i) decoder.gates 147 = dcSWm w
    ∧ run (fun i => w.getLsbD i) decoder.gates 148 = dcReqm w
    ∧ run (fun i => w.getLsbD i) decoder.gates 154 = dcValidm w
    ∧ run (fun i => w.getLsbD i) decoder.gates 41 = !(w.getLsbD 9) := by
  have hg : ∀ n : Nat, run (fun i => w.getLsbD i) decoder.gates n
      = run (run (run (run (fun i => w.getLsbD i) dcInvs) dcGM) dcGR) dcGO n := by
    intro n
    rw [decoder_gates_eq, run_append, run_append, run_append]
  obtain ⟨v1, v2, v3, v4, v5, v6, v7⟩ := run_dcGM (run (fun i => w.getLsbD i) dcInvs)
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
  · rw [hg, dcGO_frame _ 79 (by norm_num), dcGR_frame _ 79 (by norm_num), v1, dcL1_all]
  · rw [hg, dcGO_frame _ 95 (by norm_num), dcGR_frame _ 95 (by norm_num), v2, dcL2_all]
  · rw [hg, dcGO_frame _ 111 (by norm_num), dcGR_frame _ 111 (by norm_num), v3, dcL3_all]
  · rw [hg, dcGO_frame _ 120 (by norm_num), dcGR_frame _ 120 (by norm_num), v4, dcL4_all]
  · rw [hg, dcGO_frame _ 129 (by norm_num), dcGR_frame _ 129 (by norm_num), v5, dcL5_all]
  · rw [hg, dcGO_frame _ 138 (by norm_num), dcGR_frame _ 138 (by norm_num), v6, dcL6_all]
  · rw [hg, dcGO_frame _ 147 (by norm_num), dcGR_frame _ 147 (by norm_num), v7, dcL7_all]
  · rw [hg, dcGO_frame _ 148 (by norm_num), dcGR_val]
    simp only [List.any_cons, List.any_nil, Bool.or_false]
    rw [v6, v7, dcL6_all, dcL7_all]
    rfl
  · rw [hg, dcGO_val]
    simp only [List.any_cons, List.any_nil, Bool.or_false]
    rw [dcGR_frame _ 79 (by norm_num), dcGR_frame _ 95 (by norm_num),
      dcGR_frame _ 111 (by norm_num), dcGR_frame _ 120 (by norm_num),
      dcGR_frame _ 129 (by norm_num), dcGR_frame _ 138 (by norm_num),
      dcGR_frame _ 147 (by norm_num),
      v1, v2, v3, v4, v5, v6, v7,
      dcL1_all, dcL2_all, dcL3_all, dcL4_all, dcL5_all, dcL6_all, dcL7_all]
    simp [dcValidm, Bool.or_assoc]
  · rw [hg, dcGO_frame _ 41 (by norm_num), dcGR_frame _ 41 (by norm_num),
      dcGM_frame _ 41 (by norm_num)]
    exact (run_dcInvs (fun i => w.getLsbD i)).2 9 (by norm_num)

theorem sem_decoder (w : BitVec 32) :
    sem decoder (fun i => w.getLsbD i)
      = [dcADDm w, dcXORm w, dcSLTm w, dcADDIm w, dcBEQm w,
         dcLWm w, dcSWm w, dcReqm w, dcValidm w] := by
  obtain ⟨a1, a2, a3, a4, a5, a6, a7, a8, a9, _⟩ := run_decoder_out w
  show decoder.outs.map (run (fun i => w.getLsbD i) decoder.gates) = _
  rw [decoder_outs_eq]
  simp only [List.map_cons, List.map_nil, a1, a2, a3, a4, a5, a6, a7, a8, a9]

/-! ### The spec side, read off `ISA.decode`'s nested `if`-chain

⭐ **Hazard (E) — the PARALLEL/SEQUENTIAL mismatch — is discharged HERE, by case
analysis, not by an appeal to opcode-disjointness.** The circuit computes five
matches in parallel and ORs them; `decode` is a nested `if`-chain with an
interior `else none` (`ISA.lean:572`) *and* a fallthrough `none`
(`ISA.lean:582`). `split_ifs` produces one goal per path — including both `none`
paths — and each is closed by substituting the branch condition and evaluating
the resulting concrete `BitVec` disequalities. Opcode-disjointness is what makes
those disequalities discharge, and it is named separately below. -/

theorem ctrlSpec_eq (w : BitVec 32) :
    ctrlSpec w = [dcADDm w, dcXORm w, dcSLTm w, dcADDIm w, dcBEQm w,
                  dcLWm w, dcSWm w, dcReqm w, dcValidm w] := by
  simp only [ctrlSpec, SaltWorks.ISA.decode, dcADDm, dcXORm, dcSLTm, dcADDIm, dcBEQm,
    dcLWm, dcSWm, dcReqm, dcValidm, dcOpIs, dcF3Is, dcF7Z]
  split_ifs <;> simp_all

/-! ### ⭐ THE UNCONDITIONAL THEOREM -/

theorem decoder_correct (w : BitVec 32) : ctrlOf w = ctrlSpec w := by
  rw [ctrlOf, sem_decoder, ctrlSpec_eq]

theorem sem_decoder_eq_ctrlSpec (w : BitVec 32) :
    sem decoder (fun i => w.getLsbD i) = ctrlSpec w := by
  rw [sem_decoder, ctrlSpec_eq]

/-! ### ⭐ C-D1 / hazard (A) — THE PROJECTION, STATED, ON BOTH SIDES

*"Stating the projection is the whole argument"* (`Decoder.lean:56`) — and it was
never stated. Here it is, twice. Two words that agree on the **17 bits the
decoder is allowed to read** (opcode `0…6`, funct3 `12…14`, funct7 `25…31`) give
the same six control bits — from the CIRCUIT (`decoder_ignores_rd_rs1_rs2`) and
from the SPEC (`ctrlSpec_ignores_rd_rs1_rs2`). The 15 bits carrying `rd` (`7…11`),
`rs1` (`15…19`) and `rs2` (`20…24`) may differ arbitrarily.

⚠️ **`sem_congr_on` (`Sem.lean:157`) CANNOT PROVE THIS, and it is worth knowing
why**: the inverter bank has one gate per word bit, *including the 15 data bits*,
so "agreement on every net any gate reads" already forces agreement on all 32
bits. The unread inverters are dead nets, and only computing the outputs shows
it. -/

theorem ctrl_projection (w w' : BitVec 32)
    (hop : ∀ i, i < 7 → w.getLsbD i = w'.getLsbD i)
    (hf3 : ∀ i, 12 ≤ i → i < 15 → w.getLsbD i = w'.getLsbD i)
    (hf7 : ∀ i, 25 ≤ i → i < 32 → w.getLsbD i = w'.getLsbD i) :
    sem decoder (fun i => w.getLsbD i) = sem decoder (fun i => w'.getLsbD i)
      ∧ ctrlSpec w = ctrlSpec w' := by
  have e0 : w.extractLsb' 0 7 = w'.extractLsb' 0 7 := by
    rw [BitVec.eq_of_getLsbD_eq_iff]
    intro j hj
    simp only [BitVec.getLsbD_extractLsb', hj, decide_true, Bool.true_and, Nat.zero_add]
    exact hop j hj
  have e12 : w.extractLsb' 12 3 = w'.extractLsb' 12 3 := by
    rw [BitVec.eq_of_getLsbD_eq_iff]
    intro j hj
    simp only [BitVec.getLsbD_extractLsb', hj, decide_true, Bool.true_and]
    exact hf3 (12 + j) (by omega) (by omega)
  have e25 : w.extractLsb' 25 7 = w'.extractLsb' 25 7 := by
    rw [BitVec.eq_of_getLsbD_eq_iff]
    intro j hj
    simp only [BitVec.getLsbD_extractLsb', hj, decide_true, Bool.true_and]
    exact hf7 (25 + j) (by omega) (by omega)
  have hADD : dcADDm w = dcADDm w' := by simp [dcADDm, dcOpIs, dcF3Is, dcF7Z, e0, e12, e25]
  have hXOR : dcXORm w = dcXORm w' := by simp [dcXORm, dcOpIs, dcF3Is, dcF7Z, e0, e12, e25]
  have hSLT : dcSLTm w = dcSLTm w' := by simp [dcSLTm, dcOpIs, dcF3Is, dcF7Z, e0, e12, e25]
  have hADI : dcADDIm w = dcADDIm w' := by simp [dcADDIm, dcOpIs, dcF3Is, e0, e12]
  have hBEQ : dcBEQm w = dcBEQm w' := by simp [dcBEQm, dcOpIs, dcF3Is, e0, e12]
  -- ⬥ D2. The memory matchers read the same two fields, so the projection
  -- extends to them with no new hypothesis — `funct7` never enters.
  have hLW : dcLWm w = dcLWm w' := by simp [dcLWm, dcOpIs, dcF3Is, e0, e12]
  have hSW : dcSWm w = dcSWm w' := by simp [dcSWm, dcOpIs, dcF3Is, e0, e12]
  have hReq : dcReqm w = dcReqm w' := by simp only [dcReqm, hLW, hSW]
  have hVal : dcValidm w = dcValidm w' := by
    simp only [dcValidm, hADD, hXOR, hSLT, hADI, hBEQ, hLW, hSW]
  exact ⟨by rw [sem_decoder, sem_decoder, hADD, hXOR, hSLT, hADI, hBEQ,
                hLW, hSW, hReq, hVal],
         by rw [ctrlSpec_eq, ctrlSpec_eq, hADD, hXOR, hSLT, hADI, hBEQ,
                hLW, hSW, hReq, hVal]⟩

theorem ctrl_ignores_the_data_bits (w w' : BitVec 32)
    (h : ∀ i, i < 32 → (i < 7 ∨ (12 ≤ i ∧ i < 15) ∨ 25 ≤ i) → w.getLsbD i = w'.getLsbD i) :
    sem decoder (fun i => w.getLsbD i) = sem decoder (fun i => w'.getLsbD i)
      ∧ ctrlSpec w = ctrlSpec w' :=
  ctrl_projection w w'
    (fun i hi => h i (by omega) (Or.inl hi))
    (fun i h1 h2 => h i (by omega) (Or.inr (Or.inl ⟨h1, h2⟩)))
    (fun i h1 h2 => h i h2 (Or.inr (Or.inr h1)))

/-! ### Hazard (E) — disjointness, and BOTH paths to `none` -/

theorem dc_opcodes_disjoint :
    (0b0110011#7 ≠ 0b0010011#7) ∧ (0b0110011#7 ≠ 0b1100011#7)
      ∧ (0b0010011#7 ≠ (0b1100011#7 : BitVec 7)) := by decide

theorem dc_both_none_paths (w : BitVec 32) :
    (w.extractLsb' 0 7 = 0b0110011#7 → w.extractLsb' 25 7 = 0#7 →
      w.extractLsb' 12 3 ≠ 0#3 → w.extractLsb' 12 3 ≠ 4#3 → w.extractLsb' 12 3 ≠ 2#3 →
      ctrlOf w = [false, false, false, false, false, false, false, false, false])
    ∧ (w.extractLsb' 0 7 = 0b0110011#7 → w.extractLsb' 25 7 ≠ 0#7 →
      ctrlOf w = [false, false, false, false, false, false, false, false, false]) := by
  constructor
  · intro hop hz h0 h4 h2
    rw [ctrlOf, sem_decoder]
    simp [dcADDm, dcXORm, dcSLTm, dcADDIm, dcBEQm, dcLWm, dcSWm, dcReqm, dcValidm,
      dcOpIs, dcF3Is, dcF7Z, hop, hz, h0, h4, h2]
  · intro hop hz
    rw [ctrlOf, sem_decoder]
    simp [dcADDm, dcXORm, dcSLTm, dcADDIm, dcBEQm, dcLWm, dcSWm, dcReqm, dcValidm,
      dcOpIs, dcF3Is, dcF7Z, hop, hz]

/-! ### Control 1 — the theorem IMPLIES the landed certificates, and more

`decoder_plane_f7_zero` and `decoder_plane_f7_one` are `dcPlaneOK` at two values
of `funct7`. What follows is `dcPlaneOK` at **every** `funct7`. -/

theorem decoder_correct_implies_the_certificates :
    (∀ f7 : Nat, dcPlaneOK f7 = true) ∧ dcFunct7OK = true := by
  constructor
  · intro f7
    simp only [dcPlaneOK, List.all_eq_true]
    intro op _ f3 _
    simp [decoder_correct]
  · simp only [dcFunct7OK, List.all_eq_true]
    intro f7 _ f3 _
    simp [decoder_correct]

theorem plane_f7_zero_is_now_a_corollary : dcPlaneOK 0 = true :=
  decoder_correct_implies_the_certificates.1 0
theorem plane_f7_one_is_now_a_corollary : dcPlaneOK 1 = true :=
  decoder_correct_implies_the_certificates.1 1
theorem funct7_exhaustive_is_now_a_corollary : dcFunct7OK = true :=
  decoder_correct_implies_the_certificates.2

/-! ### ⭐ Control 2 — A MUTANT THE WHOLE SAMPLE ACCEPTS AND THE THEOREM REJECTS

`decoderCut` is `decoder` with **one gate appended**: `isADD` additionally
requires word bit 9 to be low. Bit 9 is `rd`'s bit 2 — one of the 15 bits hazard
(A) is about.

⛔ **The mutant is INVISIBLE TO THE ENTIRE SAMPLE, and this is proved rather than
sampled**: `decoderCut_passes_the_whole_dcWord_family` says it agrees with
`ctrlSpec` at **every** `dcWord op f3 f7` with `op < 512` — not merely at the
3,056 certified points but at every point the certificates' *shape* can reach.
It also passes all six reachability witnesses (`rd = 3` and `rd = 1` both have
bit 9 low). And `decoderCut_fails_the_theorem` exhibits `ADD x4, x1, x2`, where
it is wrong.

*This control is symbolic on purpose.* The brute-force version — re-certifying
the mutant over the 3,056 points by `decide +kernel` — was built first and
**hit the memory cap** on the `funct7` sweep. So did the REAL `dcFunct7OK`, run
as a control from an importing module: see the note at the end of this section. -/

/-- ⬥ **D2 RE-CUT THIS MUTANT RATHER THAN ASSUMING IT SURVIVED.**

*The cut net was `134` — one past the old `valid`. After D2 that net is INSIDE
the circuit (it is an inverter-fed AND in the `LW` chain), so the old mutant
would have silently collided with real logic instead of extending it.* ⇒ ***A
negative control is only a control while it is still the mutation it claims to
be; re-cutting is the work, and "it still fails" would have been the wrong
check.*** **The fresh cut is `155`, one past the new `valid` at `154`.** -/
def decoderCut : Circ :=
  { nIn := dcIn
  , gates := decoder.gates ++ [(⟨155, .and 79 (dcNot 9)⟩ : Gate)]
  , outs := [155, 95, 111, 120, 129, 138, 147, 148, 154] }

def ctrlOfCut (w : BitVec 32) : List Bool := sem decoderCut (fun i => w.getLsbD i)

theorem sem_decoderCut (w : BitVec 32) :
    ctrlOfCut w = [dcADDm w && !(w.getLsbD 9), dcXORm w, dcSLTm w, dcADDIm w,
                   dcBEQm w, dcLWm w, dcSWm w, dcReqm w, dcValidm w] := by
  obtain ⟨a1, a2, a3, a4, a5, a6, a7, a8, a9, a10⟩ := run_decoder_out w
  have hg : ∀ n : Nat, run (fun i => w.getLsbD i) decoderCut.gates n
      = upd (run (fun i => w.getLsbD i) decoder.gates) 155
          ((Op.and 79 (dcNot 9)).eval (run (fun i => w.getLsbD i) decoder.gates)) n := by
    intro n
    show run (fun i => w.getLsbD i) (decoder.gates ++ _) n = _
    rw [run_append]
    rfl
  show ([155, 95, 111, 120, 129, 138, 147, 148, 154] : List Net).map
      (run (fun i => w.getLsbD i) decoderCut.gates) = _
  simp only [List.map_cons, List.map_nil, hg, upd_self,
    upd_of_ne _ (by norm_num : (95 : Nat) ≠ 155),
    upd_of_ne _ (by norm_num : (111 : Nat) ≠ 155),
    upd_of_ne _ (by norm_num : (120 : Nat) ≠ 155),
    upd_of_ne _ (by norm_num : (129 : Nat) ≠ 155),
    upd_of_ne _ (by norm_num : (138 : Nat) ≠ 155),
    upd_of_ne _ (by norm_num : (147 : Nat) ≠ 155),
    upd_of_ne _ (by norm_num : (148 : Nat) ≠ 155),
    upd_of_ne _ (by norm_num : (154 : Nat) ≠ 155)]
  show [(run (fun i => w.getLsbD i) decoder.gates 79
          && run (fun i => w.getLsbD i) decoder.gates 41), _, _, _, _, _, _, _, _] = _
  rw [a1, a2, a3, a4, a5, a6, a7, a8, a9, a10]

theorem decoderCut_agrees_where_bit9_is_low (w : BitVec 32) (h : w.getLsbD 9 = false) :
    ctrlOfCut w = ctrlOf w := by
  rw [sem_decoderCut, ctrlOf, sem_decoder, h]
  simp

theorem dcWord_bit9 (op f3 f7 : Nat) (hop : op < 512) :
    (dcWord op f3 f7).getLsbD 9 = false := by
  simp only [dcWord, BitVec.getLsbD_ofNat, Nat.testBit_or, Nat.testBit_shiftLeft,
    Nat.testBit_lt_two_pow (show op < 2 ^ 9 by norm_num; omega)]
  norm_num

theorem decoderCut_passes_the_whole_dcWord_family (op f3 f7 : Nat) (hop : op < 512) :
    ctrlOfCut (dcWord op f3 f7) = ctrlSpec (dcWord op f3 f7) := by
  rw [decoderCut_agrees_where_bit9_is_low _ (dcWord_bit9 op f3 f7 hop), decoder_correct]

theorem decoderCut_passes_the_reachability_witnesses :
    ctrlOfCut (SaltWorks.ISA.encode (.ADD 3 1 2))
      = [true, false, false, false, false, false, false, false, true] ∧
    ctrlOfCut (SaltWorks.ISA.encode (.XOR 3 1 2))
      = [false, true, false, false, false, false, false, false, true] ∧
    ctrlOfCut (SaltWorks.ISA.encode (.SLT 3 1 2))
      = [false, false, true, false, false, false, false, false, true] ∧
    ctrlOfCut (SaltWorks.ISA.encode (.ADDI 1 0 5))
      = [false, false, false, true, false, false, false, false, true] ∧
    ctrlOfCut (SaltWorks.ISA.encode (.BEQ 1 2 4))
      = [false, false, false, false, true, false, false, false, true] ∧
    -- ⬥ D2. The mutant passes the MEMORY witnesses too — it cuts only the ADD
    -- output, so the new rows give it no extra chance to be caught. Stated so
    -- nobody reads the D2 rows as strengthening this control.
    ctrlOfCut (SaltWorks.ISA.encode (.LW 3 1 8))
      = [false, false, false, false, false, true, false, true, true] ∧
    ctrlOfCut (SaltWorks.ISA.encode (.SW 1 2 8))
      = [false, false, false, false, false, false, true, true, true] ∧
    ctrlOfCut 0x000010B7#32
      = [false, false, false, false, false, false, false, false, false] := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;>
    (rw [decoderCut_agrees_where_bit9_is_low _ (by decide +kernel)]; decide +kernel)

theorem decoderCut_fails_the_theorem :
    ctrlOfCut (SaltWorks.ISA.encode (.ADD 4 1 2))
      ≠ ctrlSpec (SaltWorks.ISA.encode (.ADD 4 1 2)) := by
  decide +kernel

theorem decoderCut_is_rejected : ¬ (∀ w : BitVec 32, ctrlOfCut w = ctrlSpec w) :=
  fun h => decoderCut_fails_the_theorem (h _)

theorem decoder_correct_implies_reachability :
    ctrlOf (SaltWorks.ISA.encode (.ADD 3 1 2))
      = [true, false, false, false, false, false, false, false, true] ∧
    ctrlOf (SaltWorks.ISA.encode (.XOR 3 1 2))
      = [false, true, false, false, false, false, false, false, true] ∧
    ctrlOf (SaltWorks.ISA.encode (.SLT 3 1 2))
      = [false, false, true, false, false, false, false, false, true] ∧
    ctrlOf (SaltWorks.ISA.encode (.ADDI 1 0 5))
      = [false, false, false, true, false, false, false, false, true] ∧
    ctrlOf (SaltWorks.ISA.encode (.BEQ 1 2 4))
      = [false, false, false, false, true, false, false, false, true] ∧
    ctrlOf (SaltWorks.ISA.encode (.LW 3 1 8))
      = [false, false, false, false, false, true, false, true, true] ∧
    ctrlOf (SaltWorks.ISA.encode (.SW 1 2 8))
      = [false, false, false, false, false, false, true, true, true] ∧
    ctrlOf 0x000010B7#32
      = [false, false, false, false, false, false, false, false, false] := by
  simp only [decoder_correct]
  decide +kernel

/-! ### Pre-registered checks C-D3, C-D6, C-D7

**C-D3 is NAMED, not fixed.** `andChain`'s empty arm returns net **0**, and net 0
is word bit 0 — the opcode's LSB, not a fresh constant. A match built from an
empty literal list would silently take `w[0]` as its match signal. Today that is
unreachable because every `dcMatches` entry has at least ten literals — **a fact
about the current table, not a property of `andChain`** — so the fact is stated
and the table invariant is stated beside it. (The compiler seat states the
net-number half in `Decoder.lean` itself; the half below is about the
SEMANTICS: running the empty gate list leaves net 0 holding the input bit.)

**C-D4 (dead inverters) is the compiler seat's, corrected at `f287785` to 17 —
and 17 is what an independent count here gives too**: bits 0 and 1 are set in all
three opcodes, so their inverters are dead for the same reason as bits 7-11 and
15-24. Nothing further is spent on it. -/

theorem andChain_empty_arm_is_word_bit_zero (b : Nat) (E : Env) :
    (andChain b ([] : List Net)).2.1 = 0
      ∧ run E (andChain b ([] : List Net)).1 0 = E 0 := by
  rw [andChain_nil]
  exact ⟨rfl, rfl⟩

theorem dcMatches_are_all_long : dcMatches.all (fun m => 10 ≤ m.length) = true := by decide

theorem decoder_out_length (w : BitVec 32) :
    (sem decoder (fun i => w.getLsbD i)).length = 9 := by
  rw [sem_decoder]
  rfl

/-- ⬥ **D2 widened this to nine falses, and the theorem's CONTENT is unchanged:**
an undecodable word asserts nothing — not the op classes, not the memory bits,
not `req`, not `valid`. *`req = false` here is what stops the `dmem_addr8` mask
trapping on a word the ISA never accepted.* -/
theorem valid_is_false_on_every_undecodable_word (w : BitVec 32)
    (h : SaltWorks.ISA.decode w = none) :
    ctrlOf w = [false, false, false, false, false, false, false, false, false] := by
  rw [decoder_correct, ctrlSpec, h]

/-! ### C-D1, split so each side is its own named theorem -/

theorem decoder_ignores_rd_rs1_rs2 (w w' : BitVec 32)
    (hop : ∀ i, i < 7 → w.getLsbD i = w'.getLsbD i)
    (hf3 : ∀ i, 12 ≤ i → i < 15 → w.getLsbD i = w'.getLsbD i)
    (hf7 : ∀ i, 25 ≤ i → i < 32 → w.getLsbD i = w'.getLsbD i) :
    sem decoder (fun i => w.getLsbD i) = sem decoder (fun i => w'.getLsbD i) :=
  (ctrl_projection w w' hop hf3 hf7).1

theorem ctrlSpec_ignores_rd_rs1_rs2 (w w' : BitVec 32)
    (hop : ∀ i, i < 7 → w.getLsbD i = w'.getLsbD i)
    (hf3 : ∀ i, 12 ≤ i → i < 15 → w.getLsbD i = w'.getLsbD i)
    (hf7 : ∀ i, 25 ≤ i → i < 32 → w.getLsbD i = w'.getLsbD i) :
    ctrlSpec w = ctrlSpec w' :=
  (ctrl_projection w w' hop hf3 hf7).2


/-! ### ⚠️ A MEASURED LIMIT OF THE CERTIFICATE SUITE, found while building Control 2

The first version of the mutant control re-certified `decoderCut` over the 3,056
sampled points by `decide +kernel`, mirroring `Decoder.lean`'s three theorems.
Two of the three go through from here; the third does not:

* `dcPlaneOKCut 0` and `dcPlaneOKCut 1` — 1,024 points each — **pass**.
* the `funct7` sweep (128 `funct7` × 8 `funct3` at one opcode) **hits the memory
  cap**: `excessive memory consumption detected at 'interpreter'`.

⛔ **AND THE CONTROL SAYS IT IS NOT THE MUTANT'S FAULT.** Re-proving the REAL,
LANDED `dcFunct7OK = true` — verbatim, by `decide +kernel` — from a module that
merely *imports* `Decoder.lean` hits the same cap. So **`decoder_funct7_exhaustive`
is module-local: it reduces inside `Decoder.lean` and is out of reach of any
importing module.** The plausible mechanism is `dcWord`'s `|||` over 128 distinct
`funct7 <<< 25` values — `Nat.lor` is not a kernel-accelerated operation and
nothing is shared across the sweep, whereas the two plane certificates hold
`funct7` fixed and share one shifted value.

⇒ The control above is therefore **symbolic**, which is strictly stronger anyway:
it covers the whole `dcWord` family rather than 3,056 of its points, and it costs
no memory. *Recorded because a downstream node that plans to re-use a landed
`decide +kernel` certificate by re-deriving it should expect this.*
-/

#audit_axioms all_congr_mem
#audit_axioms andChain_nil andChain_one andChain_cons2 andChain_out_ge
#audit_axioms run_andChain_frame run_andChain
#audit_axioms dcL1 dcL2 dcL3 dcL4 dcL5 dcG1 dcG2 dcG3 dcG4 dcG5 dcGM dcGO
#audit_axioms decoder_gates_eq decoder_outs_eq
#audit_axioms dcOut1 dcOut2 dcOut3 dcOut4 dcOut5 dcOutO
#audit_axioms dcL1_lt dcL2_lt dcL3_lt dcL4_lt dcL5_lt
#audit_axioms dcL1_ne dcL2_ne dcL3_ne dcL4_ne dcL5_ne
#audit_axioms dcG1_frame dcG2_frame dcG3_frame dcG4_frame dcG5_frame dcGO_frame
#audit_axioms dcG1_val dcG2_val dcG3_val dcG4_val dcG5_val dcGO_val
#audit_axioms run_dcGM dcGM_frame
#audit_axioms run_dcInvs run_dcInvs_lit run_dcInvs_field field_all_eq_extract
#audit_axioms dcOpIs dcF3Is dcF7Z dcOpcode_all dcFunct3_all dcFunct7Zero_all
#audit_axioms dcADDm dcXORm dcSLTm dcADDIm dcBEQm dcValidm
#audit_axioms dcL1_all dcL2_all dcL3_all dcL4_all dcL5_all
#audit_axioms run_decoder_out sem_decoder ctrlSpec_eq
#audit_axioms decoder_correct sem_decoder_eq_ctrlSpec
#audit_axioms ctrl_projection ctrl_ignores_the_data_bits
#audit_axioms decoder_ignores_rd_rs1_rs2 ctrlSpec_ignores_rd_rs1_rs2
#audit_axioms dc_opcodes_disjoint dc_both_none_paths
#audit_axioms decoder_correct_implies_the_certificates
#audit_axioms plane_f7_zero_is_now_a_corollary plane_f7_one_is_now_a_corollary
#audit_axioms funct7_exhaustive_is_now_a_corollary
#audit_axioms decoderCut ctrlOfCut sem_decoderCut decoderCut_agrees_where_bit9_is_low
#audit_axioms dcWord_bit9 decoderCut_passes_the_whole_dcWord_family
#audit_axioms decoderCut_passes_the_reachability_witnesses
#audit_axioms decoderCut_fails_the_theorem decoderCut_is_rejected
#audit_axioms decoder_correct_implies_reachability
#audit_axioms andChain_empty_arm_is_word_bit_zero dcMatches_are_all_long
#audit_axioms decoder_out_length valid_is_false_on_every_undecodable_word

end DecoderSemantics

section ImmediateSemantics

open SaltWorks.HDL hiding seenWord
open Salt.Tactic

/-!
## IMM-UNCOND — the immediate extractors, for every 32-bit word

`HDL/Immediate.lean`'s two certificates are `decide +kernel` over **4096 words
each**, and every one of those words is `encode (.ADDI 1 0 v)` or
`encode (.BEQ 1 2 v)` — i.e. the `rd`/`rs1`/`rs2` fields are **PINNED**. That is
a 4096-member family inside 2^32.

⛔ **`RegField`/`PcField` quantify over `∀ ins`** — an arbitrary environment, so
an arbitrary instruction word. A certificate over a pinned family cannot feed
that obligation, however exhaustive it is *within* the family.

### The route, and why it is short

`immICirc` has **zero gates**, so `run ins [] = ins` and `sem` is nothing but a
re-indexing of the input valuation through `immI`. `immBCirc` has **one** gate,
`⟨32, .const false⟩`, and every net its outputs read other than 32 is `< 32`
(`immBField_lt_32`) — so the single `upd` hits output 0 and frames past all the
others. Both facts are stated below *before* any bit-level reasoning, which is
what keeps the arithmetic to twelve `interval_cases`.

📌 **The environment's value at net 32 is IRRELEVANT, and that is a theorem here
rather than an assumption** — `sem_immBCirc` writes `false` at output 0
outright, and `sem_immBCirc_ignores_net32` says two valuations agreeing only
below 32 give the same meaning.
-/

/-! ### The wiring, at the level of `sem` -/

/-- Every net `immBField` names is a **primary input** — below the one gate's
output net. *This is what makes the `B` block's single `upd` frame past all
outputs but the zero.* ⚠️ `abbrev Net := Nat` and `omega` does not see through
it: every branch is mirrored into `Nat` by `show` first. -/
theorem immBField_lt_32 (j : Nat) : immBField j < 32 := by
  unfold immBField
  split
  · show 8 + j < 32; omega
  · split
    · show 25 + (j - 4) < 32; omega
    · split
      · show (7 : Nat) < 32; omega
      · show (31 : Nat) < 32; omega

/-- And so is every net `immB` names, except output 0's. -/
theorem immB_lt_32_of_ne_zero {k : Nat} (hk : k ≠ 0) : immB k < 32 := by
  unfold immB
  rw [if_neg hk]
  split
  · exact immBField_lt_32 _
  · exact immBField_lt_32 _

/-- ⭐ **THE `I` BLOCK IS A RE-INDEXING AND NOTHING ELSE, FOR EVERY VALUATION.**
Zero gates means `run ins [] = ins`, so `sem` is `outs.map ins`. -/
theorem sem_immICirc (E : Env) :
    sem immICirc E = (List.range 32).map (fun k => E (immI k)) := by
  simp [sem, immICirc, List.map_map, Function.comp_def]

/-- ⭐ **THE `B` BLOCK, FOR EVERY VALUATION**: output 0 is `false` — written by
the block's only gate, whatever `E` says at net 32 — and every other output is
the input net `immB` names. -/
theorem sem_immBCirc (E : Env) :
    sem immBCirc E = (List.range 32).map (fun k => if k = 0 then false else E (immB k)) := by
  show ((List.range 32).map immB).map (run E [⟨immBZero, .const false⟩]) = _
  rw [List.map_map]
  apply List.map_congr_left
  intro k _
  show run E [⟨immBZero, .const false⟩] (immB k) = _
  rw [run_cons, run_nil]
  by_cases hk : k = 0
  · subst hk
    show upd E immBZero false immBZero = _
    simp
  · rw [if_neg hk]
    exact upd_of_ne _ (Nat.ne_of_lt (immB_lt_32_of_ne_zero hk))

/-- ⭐ **NET 32 IS NOT AN INPUT**, said precisely: valuations that agree only on
the 32 primary inputs already agree on the block's meaning. *Stated rather than
assumed, because the gate writes net 32 and a reader cannot tell from the `Circ`
alone whether the pre-existing value leaks.* -/
theorem sem_immBCirc_ignores_net32 {E₁ E₂ : Env} (h : ∀ n : Nat, n < 32 → E₁ n = E₂ n) :
    sem immBCirc E₁ = sem immBCirc E₂ := by
  rw [sem_immBCirc, sem_immBCirc]
  apply List.map_congr_left
  intro k _
  by_cases hk : k = 0
  · rw [if_pos hk, if_pos hk]
  · rw [if_neg hk, if_neg hk]
    exact h _ (immB_lt_32_of_ne_zero hk)

/-! ### The bits — the wiring against `sext` and against the scramble -/

/-- Output `k` of the `I` block is bit `k` of `sext(w[31:20])`, for a **symbolic**
`w`. -/
theorem immI_bit (w : BitVec 32) {k : Nat} (hk : k < 32) :
    w.getLsbD (immI k) = ((w.extractLsb' 20 12).signExtend 32).getLsbD k := by
  rw [BitVec.getLsbD_signExtend]
  by_cases h : k < 12
  · rw [BitVec.getLsbD_extractLsb']
    simp [immI, h, hk]
  · rw [BitVec.msb_eq_getLsbD_last, BitVec.getLsbD_extractLsb']
    simp [immI, h, hk]

/-- **`w`'s `B`-type immediate field, reassembled** — character for character the
expression `ISA.decode` uses at `ISA.lean:580`, so a reader can check the
transcription by eye against the decoder rather than against the prose table. -/
def bImmOf (w : BitVec 32) : BitVec 12 :=
  w.extractLsb' 31 1 ++ (w.extractLsb' 7 1 ++ (w.extractLsb' 25 6 ++ w.extractLsb' 8 4))

/-- ⚠️ **A WIDTH-INDEX BRIDGE, AND IT IS LOAD-BEARING.** `bImmOf w` is declared at
`BitVec 12` while its body is at `BitVec (1 + (1 + (6 + 4)))`; the two are
definitionally equal, but `simp` will **not** fire `BitVec.getLsbD_append`
through the literal `12`. Re-stating the projection at the sum-shaped width is
what makes the append lemmas apply at all. -/
theorem bImmOf_getLsbD (w : BitVec 32) (j : Nat) :
    (bImmOf w).getLsbD j
      = (w.extractLsb' 31 1 ++
          (w.extractLsb' 7 1 ++ (w.extractLsb' 25 6 ++ w.extractLsb' 8 4))).getLsbD j := rfl

/-- ⭐ **THE SCRAMBLE, BIT BY BIT, AGAINST THE DECODER'S OWN REASSEMBLY.** Twelve
cases because the field is twelve bits and its pieces are not contiguous. -/
theorem bImmOf_bit (w : BitVec 32) {j : Nat} (hj : j < 12) :
    (bImmOf w).getLsbD j = w.getLsbD (immBField j) := by
  rw [bImmOf_getLsbD]
  interval_cases j <;>
    (repeat rw [BitVec.getLsbD_append]) <;>
    norm_num [immBField, BitVec.getLsbD_extractLsb']

/-- Output `k > 0` of the `B` block is bit `k` of `bOffset` — **the scramble AND
the doubling**, for a symbolic `w`. -/
theorem immB_bit (w : BitVec 32) {k : Nat} (hk : k < 32) (hk0 : k ≠ 0) :
    w.getLsbD (immB k) = (bOffset (bImmOf w)).getLsbD k := by
  have h1 : ¬ (k < 1) := by omega
  have h2 : k - 1 < 32 := by omega
  rw [bOffset, BitVec.getLsbD_shiftLeft, BitVec.getLsbD_signExtend,
    BitVec.msb_eq_getLsbD_last, decide_eq_true hk, decide_eq_false h1, decide_eq_true h2]
  simp only [Bool.not_false, Bool.true_and, Bool.and_true, Nat.reduceSub]
  unfold immB
  rw [if_neg hk0]
  by_cases h13 : k < 13
  · rw [if_pos h13, if_pos (show k - 1 < 12 by omega),
      bImmOf_bit w (show k - 1 < 12 by omega)]
  · rw [if_neg h13, if_neg (show ¬ (k - 1 < 12) by omega),
      bImmOf_bit w (show (11 : Nat) < 12 by omega)]

/-! ### ⭐⭐ THE UNCONDITIONAL THEOREMS -/

/-- ⭐⭐ **THE `I` IMMEDIATE IS `sext(w[31:20])`, ON ALL 2^32 WORDS.** *Not
`decide`d — 2^32 words is not a kernel computation, and the existing certificate
reaches 4096 of them with `rd`/`rs1` pinned.* -/
theorem sem_immICirc_word (w : BitVec 32) :
    sem immICirc (fun i => w.getLsbD i)
      = (List.range 32).map ((w.extractLsb' 20 12).signExtend 32).getLsbD := by
  rw [sem_immICirc]
  exact List.map_congr_left (fun k hk => immI_bit w (List.mem_range.mp hk))

/-- ⭐⭐ **THE `B` DISPLACEMENT IS `bOffset` OF THE REASSEMBLED FIELD, ON ALL 2^32
WORDS** — including the structural low zero, which the statement carries as
`bOffset`'s own `<<< 1` rather than as a side remark. -/
theorem sem_immBCirc_word (w : BitVec 32) :
    sem immBCirc (fun i => w.getLsbD i)
      = (List.range 32).map (bOffset (bImmOf w)).getLsbD := by
  rw [sem_immBCirc]
  refine List.map_congr_left (fun k hk => ?_)
  have hk32 : k < 32 := List.mem_range.mp hk
  by_cases hk0 : k = 0
  · subst hk0
    rw [if_pos rfl, bOffset, BitVec.getLsbD_shiftLeft]
    simp
  · rw [if_neg hk0]
    exact immB_bit w hk32 hk0

/-! ### The specification-facing forms — against `ISA.decode`'s own immediate -/

/-- Whatever immediate `decode` reports for an `ADDI` word is `w[31:20]`. -/
theorem iImm_of_decode {w : BitVec 32} {rd rs1 : Fin 32} {imm : BitVec 12}
    (h : decode w = some (.ADDI rd rs1 imm)) : w.extractLsb' 20 12 = imm := by
  simp only [decode] at h
  split_ifs at h <;>
    simp only [Option.some.injEq, Instr.ADDI.injEq, reduceCtorEq] at h
  exact h.2.2

/-- Whatever immediate `decode` reports for a `BEQ` word is `bImmOf w`. -/
theorem bImm_of_decode {w : BitVec 32} {a b : Fin 32} {imm : BitVec 12}
    (h : decode w = some (.BEQ a b imm)) : bImmOf w = imm := by
  simp only [decode] at h
  split_ifs at h <;>
    simp only [Option.some.injEq, Instr.BEQ.injEq, reduceCtorEq] at h
  exact h.2.2

/-- ⭐ **THE FORM A FIELD OBLIGATION CONSUMES**: for **any** word the decoder
reads as `ADDI`, with **any** `rd`/`rs1`, the block's meaning is `sext` of *that
instruction's* immediate. -/
theorem sem_immICirc_of_decode {w : BitVec 32} {rd rs1 : Fin 32} {imm : BitVec 12}
    (h : decode w = some (.ADDI rd rs1 imm)) :
    sem immICirc (fun i => w.getLsbD i) = (List.range 32).map (imm.signExtend 32).getLsbD := by
  rw [sem_immICirc_word, iImm_of_decode h]

/-- ⭐ **AND FOR `BEQ`** — the byte displacement `ISA.step` actually adds to `pc`. -/
theorem sem_immBCirc_of_decode {w : BitVec 32} {a b : Fin 32} {imm : BitVec 12}
    (h : decode w = some (.BEQ a b imm)) :
    sem immBCirc (fun i => w.getLsbD i) = (List.range 32).map (bOffset imm).getLsbD := by
  rw [sem_immBCirc_word, bImm_of_decode h]

/-! ### ⭐ NON-VACUITY 1 — the unconditional theorems IMPLY the certificates

*The direction that matters: a "more general" theorem that did not recover the
checked points would be a different claim wearing the same name. These re-prove
`immI_OK`/`immB_OK` with **no** `decide` — only the word theorems and
`decode_encode`.* -/

/-- ⭐ **`Immediate.lean:112`'s 4096 points, derived rather than computed.** -/
theorem immI_correct_of_uncond : immI_OK = true := by
  simp only [immI_OK, List.all_eq_true]
  intro v _
  rw [beq_iff_eq]
  exact sem_immICirc_of_decode (by unfold wordI; exact decode_encode _)

/-- ⭐ **`Immediate.lean:121`'s 4096 points, likewise.** -/
theorem immB_correct_of_uncond : immB_OK = true := by
  simp only [immB_OK, List.all_eq_true]
  intro v _
  rw [beq_iff_eq]
  exact sem_immBCirc_of_decode (by unfold wordB; exact decode_encode _)

/-! ### ⭐ NON-VACUITY 2 — words the certificates cannot reach

*`wordI v` pins `rd = 1, rs1 = 0`; `wordB v` pins `rs1 = 1, rs2 = 2`. These words
are well-formed instructions of the same two kinds with **different register
fields**, so they lie outside both 4096-member families — by `encode_injective`,
not by inspection.* -/

def immIWordOff : BitVec 32 := encode (.ADDI 31 30 0x5A5#12)
def immBWordOff : BitVec 32 := encode (.BEQ 31 30 0x5A5#12)

theorem immIWordOff_off_the_family (v : Nat) : immIWordOff ≠ wordI v := by
  intro h
  unfold immIWordOff wordI at h
  have h2 := encode_injective h
  injection h2 with e1 _ _
  exact absurd e1 (by decide)

theorem immBWordOff_off_the_family (v : Nat) : immBWordOff ≠ wordB v := by
  intro h
  unfold immBWordOff wordB at h
  have h2 := encode_injective h
  injection h2 with e1 _ _
  exact absurd e1 (by decide)

/-- ⭐ **OFF THE SAMPLE, `I` SIDE** — `addi x31, x30, 0x5A5` is in no `immI_OK`
point, and the wiring still delivers `sext(0x5A5)`. -/
theorem sem_immICirc_off_the_sample :
    (∀ v : Nat, immIWordOff ≠ wordI v)
      ∧ sem immICirc (fun i => immIWordOff.getLsbD i)
          = (List.range 32).map ((0x5A5#12 : BitVec 12).signExtend 32).getLsbD :=
  ⟨immIWordOff_off_the_family,
   sem_immICirc_of_decode (by unfold immIWordOff; exact decode_encode _)⟩

/-- ⭐ **OFF THE SAMPLE, `B` SIDE.** -/
theorem sem_immBCirc_off_the_sample :
    (∀ v : Nat, immBWordOff ≠ wordB v)
      ∧ sem immBCirc (fun i => immBWordOff.getLsbD i)
          = (List.range 32).map (bOffset (0x5A5#12 : BitVec 12)).getLsbD :=
  ⟨immBWordOff_off_the_family,
   sem_immBCirc_of_decode (by unfold immBWordOff; exact decode_encode _)⟩

/-! ### ⭐ NON-VACUITY 3 — the mutants the unconditional theorems reject -/

/-- **The `I`-side mutant: the field read one bit high.** The commonest wiring
slip in a block with no gates to get wrong. -/
def immIoff (k : Nat) : Net := if k < 12 then 21 + k else 31

def immIoffCirc : Circ :=
  { nIn := 32, gates := [], outs := (List.range 32).map immIoff }

/-- ⭐ **AND `sem_immICirc_word` REFUTES IT**, at `addi x1, x0, 1`. -/
theorem immIoffCirc_fails_the_theorem :
    ¬ (∀ w : BitVec 32, sem immIoffCirc (fun i => w.getLsbD i)
        = (List.range 32).map ((w.extractLsb' 20 12).signExtend 32).getLsbD) := by
  intro h
  have hw := h (encode (.ADDI 1 0 1))
  revert hw
  decide +kernel

/-- ⭐ **AND `sem_immBCirc_word` REFUTES THE OFF-BY-ONE MUTANT** the freeze
actually shipped — `Immediate.lean:138`'s undoubled wiring, here rejected by the
theorem rather than by a 4096-point sweep. -/
theorem immBshiftedCirc_fails_the_theorem :
    ¬ (∀ w : BitVec 32, sem immBshiftedCirc (fun i => w.getLsbD i)
        = (List.range 32).map (bOffset (bImmOf w)).getLsbD) := by
  intro h
  have hw := h (encode (.BEQ 1 2 4))
  revert hw
  decide +kernel

/-- And the two blocks are genuinely different circuits, on a word the manual
pins (`ISA.lean:615`): `beq x1, x2, +8`. -/
theorem immBCirc_ne_immBshiftedCirc :
    sem immBCirc (fun i => (encode (Instr.BEQ 1 2 4)).getLsbD i)
      ≠ sem immBshiftedCirc (fun i => (encode (Instr.BEQ 1 2 4)).getLsbD i) := by
  decide +kernel

end ImmediateSemantics

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
#audit_axioms seenWord CycleRealisesStepProj cycles_realise_steps_of_memFree
#audit_axioms MemFree St_eq_of_fields decQ_mem decQ_trapped decQ_cyc_eq_of_memFree
#audit_axioms envWith wordOf_congr decQ_congr decQ_envWith_eq seenWord_envWith
#audit_axioms decQ_envWith_of_clean step_regs_of_with_of_not_touchesMem step_pc_of_with
#audit_axioms step_mem_frame_of_not_touchesMem step_trapped_frame_of_not_touchesMem
#audit_axioms stepT_mem_frame_of_not_touchesMem stepT_trapped_frame_of_not_touchesMem
#audit_axioms step_SW_ok_writes_the_addressed_word step_LW_ok_loads_the_addressed_word
#audit_axioms step_LW_writes_no_memory
#audit_axioms step_LW_trapped_changes_no_memory_and_no_register
#audit_axioms step_SW_trapped_changes_no_memory_and_no_register
#audit_axioms stepSW_mutant mutant_killed_at_misaligned_in_range
#audit_axioms witness_is_misaligned_and_in_range out_of_range_mutant_passes_spuriously
#audit_axioms step_SW_trapped_suppresses_the_write
#audit_axioms cycOf decQ_cycOf_proj cycleRealisesStepProj_cycOf
#audit_axioms not_cycleRealisesStep_id not_cycleRealisesStep_wordOf
#audit_axioms runFor_one_of_fetch runFor_succ_of_fetch runWords_eq_runFor
#audit_axioms runWords_get_of_undecodable FeedsProgram runWords_get_eq_runFor
#audit_axioms decode_zero runFor_halts_where_runWords_runs_on
#audit_axioms fetchWord_eq_encode feedsFst_of_deliversProgram
#audit_axioms addiOnly addiStream feedsProgram_addi feedsProgram_addi_runs
#audit_axioms noisy_tail_overwrites exists_halting_count cycles_sort
#audit_axioms seenWord_eq_hdl encD_length envOfBits envOfBits_of_length envOfBits_encD
#audit_axioms seenWord_envOfBits cycOfBits cycleRealisesStepProj_of_bits
#audit_axioms cycOfCirc seenWord_cycOfCirc
#audit_axioms cycleRealisesStep_of_C4Spec cycleRealisesStep_of_C4
#audit_axioms outs_length_of_C4Spec sorts_of_C4
#audit_axioms idealBits cycleRealisesStep_idealBits
#audit_axioms stalledBits decQ_cycOfBits_stalled not_cycleRealisesStep_stalledBits
#audit_axioms shortBits shortBits_length shortBits_reads_the_pad
#audit_axioms cycOfBits_shortBits_pad_dependent
#audit_axioms cycOfBits_pad_irrelevant cycOfCirc_pad_irrelevant
#audit_axioms not_both_coreShaped_C4Spec
#audit_axioms outBit outReg outPc RegField PcField
#audit_axioms stBit_reg stBit_pc regField_iff_bits pcField_iff_bits
#audit_axioms c4Spec_iff_bitwise c4Spec_iff_fieldwise
#audit_axioms c4Spec_of_fieldwise cycleRealisesStep_of_fieldwise sorts_of_fieldwise
#audit_axioms not_C4Spec_of_not_regField not_C4Spec_of_not_pcField
#audit_axioms sem_coreShaped outBit_coreShaped outReg_coreShaped outPc_coreShaped
#audit_axioms set_regs_zero step_regs_zero stepT_regs_zero
#audit_axioms regField_zero_coreShaped not_regField_one_coreShaped
#audit_axioms not_pcField_coreShaped coreShaped_isolation not_C4Spec_coreShaped
#audit_axioms sem_coreShapedT outBit_coreShapedT outPc_coreShapedT
#audit_axioms not_pcField_coreShapedT neither_coreShape_C4Spec
#audit_axioms extendOut sem_extendOut extendOut_outs_length outBit_extendOut
#audit_axioms length_conjunct_is_necessary
#audit_axioms wordOf_getLsbD_self wordOf_getD_map_range bwWords_sample_size
#audit_axioms run_xorGates sem_bitXor32 sem_bitXor32_off_the_sample
#audit_axioms xorField_is_bitXor32
#audit_axioms sem_sltCirc sltDrive_eq_sign_formula
#audit_axioms sltDrive_eq_of_mem wordOf_cmpWord sltField_is_sltCirc
#audit_axioms bitAnd32_fails_the_xorField sltuCirc_fails_the_sltField
#audit_axioms control_states_exist

#audit_axioms atLeastTwo_eq xor3 adEnv run_five
#audit_axioms adBase_eq adA_lt adB_lt adC_lt adC_succ adS_eq
#audit_axioms adGates adGates_succ run_adSlice run_adSlice_cout run_adSlice_sum
#audit_axioms run_adSlice_frame run_adGates
#audit_axioms sem_adder32_gen bwEnv_eq_adEnv sem_adder32
#audit_axioms getD_of_range_append getD_32_of_range_append
#audit_axioms sem_adder32_getD sem_adder32_cout
#audit_axioms subEnv_eq subOut_eq_sem setWidth_ofBool_true add_not_one subOut_bits
#audit_axioms sub_via_adder_unconditional subOut_sign subOut_cout
#audit_axioms sem_sltuCirc sltuDrive_uncond msb31 carry32_expand
#audit_axioms subOut_sign_formula slt_bool slt_sign_formula sltDrive_uncond
#audit_axioms wordOf_getD_range_append
#audit_axioms addField_is_adder32 addiField_is_adder32 sltField_is_sltCirc_unconditional
#audit_axioms adSliceCut adder32Cut adder32Cut_is_ssa adder32Cut_fails_the_adder
#audit_axioms bitXor32_fails_the_adder sem_adder32_off_the_sample

#audit_axioms run_pointwise any_congr_mem sem_bwCirc
#audit_axioms sem_bitAnd32 sem_bitOr32 sem_bitNot32
#audit_axioms pcNe_eq pcEq_eq pcTake_eq pcNotTake_eq pcMuxBase_eq
#audit_axioms pcOut pcAddendOut_eq
#audit_axioms orChain_nil orChain_one orChain_cons2 orChain_out_ge
#audit_axioms run_orChain_frame run_orChain
#audit_axioms run_pcDiffGates run_pcNeGates pcCtrlGates
#audit_axioms run_pcCtrl_161 run_pcCtrl_162 run_pcCtrl_frame
#audit_axioms pcAddGates pcAddGates_succ pcAddendGates_two pcAddendGates_ne
#audit_axioms pcAddendGates_out_ge pcAddendGates_out_ne run_pcAddGates
#audit_axioms takeOf pcNext_gates_eq pcNext_outs_eq run_pcNext
#audit_axioms pcEnvOf pcRun_eq pcEnvOf_rs1 pcEnvOf_rs2 pcEnvOf_off pcEnvOf_66 pcEnvOf_96
#audit_axioms any_range_xor takeOf_pcEnvOf four_getLsbD sem_pcNext
#audit_axioms pcDiffGatesCut pcNextCut pcNextCut_ssa pcNextCut_gate_count
#audit_axioms pcOKCut pcNextCut_passes_the_certificate pcNextCut_fails_the_theorem
#audit_axioms sem_pcNext_off_the_sample
#audit_axioms bitAnd32Cut bitAnd32Cut_ssa bitAnd32Cut_fails_the_theorem
#audit_axioms sem_bitAnd32_off_the_sample
#audit_axioms pcSpec_eq pcAddend_word
#audit_axioms pcField_is_pcNext_beq pcField_is_pcNext_add pcField_is_pcNext_undecodable
#audit_axioms pcAddIn pcAddZero pcSigma pcAddOff addendNet adSigma pcAdd
#audit_axioms pcAdd_ssa pcAdd_wf pcAdd_gate_count pcAdd_adder_off
#audit_axioms instMap_pcOut addendNet_lt adSigma_lt instOK_pcNext instOK_adder
#audit_axioms pcOut_mem_gates adS_mem_gates pcOut_mem adS_mem
#audit_axioms pcAddEnv pcAddEnv0 pcAddEnv_pc pcAddEnv_shift pcAddEnv0_low pcAddEnv0_zero
#audit_axioms adEnv_a adEnv_b adEnv_cin pcAddend run_pcNext_addend
#audit_axioms hin_pcNext hin_adder run_adder32_adS
#audit_axioms pcAdd_gates_eq run_pcAdd_peel run_pcAdd_out sem_pcAdd
#audit_axioms pcAdd_word pcField_is_pcAdd_beq pcField_is_pcAdd_add pcField_is_pcAdd_undecodable

#audit_axioms muxRow muxRow_succ run_three run_three_frame run_muxRow mux_pick
#audit_axioms asW_eq asRes_eq
#audit_axioms aluSelect_outs_eq sem_aluSelect
#audit_axioms asSelOf getD_map_range_zero
#audit_axioms asOneHot_eq asOneHot_sel asOneHot_res asBit0_eq
#audit_axioms asSelectsOK_of_lt asSelectsOK_fails_at_the_pad_slot
#audit_axioms asDrive asDrive_eq asDrive_sel asDrive_res
#audit_axioms sem_aluSelect_drive aluSelect_word aluField_is_aluSelect_add
#audit_axioms asOffEnv asOffEnv_eq sem_aluSelect_off_the_sample
#audit_axioms addend_read_as_pc_is_four addend_as_pc_is_wrong_unless_pc_zero
#audit_axioms the_defect_and_the_fix pcAdd_netlist_advances_the_pc pcAdd_netlist_takes_the_branch
#audit_axioms adSigmaCut pcAddCut pcAddCut_ssa pcAddCut_gate_count
#audit_axioms pcAddPcs pcAddPairs pcAddOffs pcAddOKCut
#audit_axioms pcAddCut_passes_the_certificate pcAddCut_fails_the_theorem
#audit_axioms pcAddCutB pcAddCutB_ssa pcAddOKCutB
#audit_axioms pcAddCutB_passes_the_certificate pcAddCutB_fails_the_theorem
#audit_axioms pcAddOK pcAdd_passes_the_certificate sem_pcAdd_off_the_sample

#audit_axioms rtIn_eq rtZero_eq rtNotSel_eq rtReg_lt rtReg_ne rtReg_lt_stored
#audit_axioms rtSel rtSel_succ rtSel_lt rtSel_congr rtSel_testBit sel_bit
#audit_axioms rtLevel_nil rtLevel_cons2 run_rtMux range_map_two run_rtLevel
#audit_axioms rtLevels_zero rtLevAt rtLevels_succ run_rtLevels
#audit_axioms rtBit_gates rtBit_out rtBit_next run_rtBit
#audit_axioms rtBits_zero rtBits_succ run_rtBits
#audit_axioms readTree_gates_eq readTree_outs_eq rtPre rtInvGates
#audit_axioms rtPre_lt rtPre_zero rtPre_inv run_readTree_gates sem_readTree_uncond
#audit_axioms rtEnvOf rtEnvOf_addr rtEnvOf_else rtEnvOf_reg rtSel_rtEnvOf sem_readTree
#audit_axioms rtEnvOfSt sem_readTree_St readTree_reads_x0_zero rtWord_is_get
#audit_axioms getD_map_range rtOneCold_else rtOneCold_eq rtBit0_uncond
#audit_axioms rtSelectsOK_uncond sem_readTree_off_the_sample
#audit_axioms readTreeCutA readTreeCutB rtSelectsCut readTreeCutA_ssa readTreeCutB_ssa
#audit_axioms readTreeCutA_passes_the_certificate readTreeCutB_passes_the_certificate
#audit_axioms readTreeCutA_fails_the_theorem readTreeCutB_fails_the_theorem

#audit_axioms cellRow cellRow_succ run_cell run_cell_frame run_cellRow
#audit_axioms rnInN rnBaseN rnOutN rnInN_eq rnBaseN_eq rnNotWe_eq
#audit_axioms rnWe_eq rnRes_eq rnCur_eq rnOut_eq
#audit_axioms rnPOp rnQOp rnArr rnArr_succ rnRow_eq run_rnArr
#audit_axioms regNextN_gates_eq run_regNextN sem_regNextN sem_regNext
#audit_axioms getD_map_range_gen length_flatMap_range_map getD_flatMap_range_map
#audit_axioms regNext_getD regNext_writes_x0_when_enabled regNext_x0_is_not_self_enforcing
#audit_axioms rnEnvOf rnEnvOf_we rnEnvOf_res rnEnvOf_cur sem_regNext_drive
#audit_axioms rnWeOf rnWeOf_is_weSpec regNext_is_St_set regNext_x0_holds
#audit_axioms rnDrive rnRun_eq_drive rnDrive_we rnDrive_res rnDrive_cur rnRun_eq_rnSpec
#audit_axioms rnAllWeOK_uncond rnOneHotOK_uncond rnBit_uncond
#audit_axioms rnMuxCut regNextNCut rnRunCut rnAllWeOKCut rnOneHotOKCut rnBitCut
#audit_axioms regNextCut_ssa regNextCut_gate_count regNextCut_passes_the_certificate
#audit_axioms regNextCut_passes_the_frame_certificate regNextCut_passes_the_hold_certificate
#audit_axioms regNextCut_passes_the_32_samples rnCutWitness regNextCut_fails_the_theorem
#audit_axioms rnOffEnv sem_regNext_off_the_sample

#audit_axioms immBField_lt_32 immB_lt_32_of_ne_zero
#audit_axioms sem_immICirc sem_immBCirc sem_immBCirc_ignores_net32
#audit_axioms immI_bit bImmOf bImmOf_getLsbD bImmOf_bit immB_bit
#audit_axioms sem_immICirc_word sem_immBCirc_word
#audit_axioms iImm_of_decode bImm_of_decode
#audit_axioms sem_immICirc_of_decode sem_immBCirc_of_decode
#audit_axioms immI_correct_of_uncond immB_correct_of_uncond
#audit_axioms immIWordOff immBWordOff
#audit_axioms immIWordOff_off_the_family immBWordOff_off_the_family
#audit_axioms sem_immICirc_off_the_sample sem_immBCirc_off_the_sample
#audit_axioms immIoff immIoffCirc immIoffCirc_fails_the_theorem
#audit_axioms immBshiftedCirc_fails_the_theorem immBCirc_ne_immBshiftedCirc

end SaltWorks.Stack.Program
