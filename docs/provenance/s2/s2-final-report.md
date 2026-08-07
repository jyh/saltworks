# S2 — the executor's final report, verbatim

Reproduced as delivered by the STACK-S2 executor (Opus), 2026-08-07. Commit `bf2de34`.
Part 2 of the three-part provenance bundle; see `README.md`.

---

## The program

**120 instructions = 5 × 24**, and both factors are theorems: `emit_length` supplies the 5,
`batcher8_length` the 24. **Emitted from `batcher8`, not transcribed** —
`batcherSort = emit batcher8 = batcher8.flatMap cmpEx`. No comparator was typed by hand, so the
abstract-network correspondence is structural. `emit` is generic in the network. Assembled by
`encode` to 120 words; `decode_batcherSortWords` inverts the whole list structurally from
`decode_encode` (no 120-way enumeration).

## ⛔ The immediate: the brief was wrong, and my first draft used it

**`imm = 8`, not 6.** `bOffset imm = 2*imm` is added to the pc *of the branch*, so skipping three
XORs is `2*imm = 16`. `imm = 6` lands *on* the third XOR, which then executes alone. Both halves
are committed as certificates rather than deleted, and `offset_six_does_not_sort` proves the
`imm = 6` program **builds clean, runs to completion, returns an ordinary state, and does not
sort.** `run` is total; nothing else would ever have reported it.

## Branch direction

**Branchless is not expressible** — verified against the constructor list, not assumed: five
constructors, no AND/OR/SUB/shift; the only `<<<` is inside `bOffset`, which no program executes.
A mask needs AND to apply and SUB to apply it to.

**Forwardness is proved structurally for *every* network**: `emit_branches_forward : ∀ i ∈ emit
net, branchIsForward i = true` for any `net`; `batcherSort_branches_forward` is the corollary;
`beq_skipImm_advances` gives taken `+16` / not-taken `+4`, both forward, neither data-dependent.
Semantic receipt on top: all seven runs assert `pc = 480 = 4×120`, the pc off the end.
`run_already_sorted` is the sharpest — nothing swaps, so all 24 branches are taken.

## Runs verified

`run_mixed` `[3,-1,7,0,-5,2,9,-2]`; `run_already_sorted`; `run_reverse_sorted`; `run_all_equal`;
`run_duplicates`; `run_extremes` (INT_MIN/INT_MAX with repeats); plus
`run_mixed_not_unsigned_sorted` (the output is **not** unsigned-sorted). Three are stated in the
stronger form `= List.ofFn (runNetW batcher8 v)` — equal to the abstract network element for
element. Two committed mutants provably **fail** `SortsRegs`, so the positives aren't vacuous;
three further negative controls fired in scratch.

**The anticipated kernel cost did not materialise** — the whole file elaborates in 3.4 s. Not a
finding against the approach.

## S3(b): stated, and reduced

It typechecks, probed three ways. Better than that:
`sortsAllInputs_of_refinesNetwork : RefinesNetwork → SortsAllInputs` is **proved**, by composing
with math's landed `batcher8_sortsTo_word`. **S3(b) never has to argue about `SortedW` or
`PermW`** — it inherits both and is left with a pure refinement question about 120 instructions
under `step`. The lanes meet at the same network literal precisely because the program was emitted
from it. Both obligations are committed as sorry-free `Prop`s.

`SortsRegs`' in-place assumption **confirmed, no mismatch**: the 3-XOR swap writes back to the pair
it read; `x9` scratch is deliberately outside the spec; `x0` never data, never a temp.

## Build/audit

`saltbuild EXIT=0` targeted, no warnings in the file, **41 declarations audited clean** at
`[propext, Classical.choice, Quot.sound]`, re-checked by `#print axioms` in a scratch that was
deleted. `import owed: SaltWorks.Stack.Program` is in the commit message — **maestro sweep
needed**; `SaltWorks.lean` untouched. No existing file modified.

## Authorship record — in my own words

Everything in `SaltWorks/Stack/Program.lean` was written by me. By hand: `cmpEx` — the 3-XOR swap
(Slice A leaves no alternative), the register allocation, the immediate. Derived: the comparator
order. Neither: every numeric claim, which the kernel checked.

What I got wrong: **I took the brief's `imm = 6` into my first draft** and only caught it by
computing the offset from `step` — which the brief had explicitly told me to do. And a near-miss
entirely my own: `branchIsForward` first read `0 < imm.toNat`, which **accepts every backward
branch** (`-2` has `toNat` 4094). That is S1's signed/unsigned trap recurring one layer up, inside
the check whose only job was to prevent it — pinned now as `forwardness_must_be_signed`. Two
tooling misreadings of no consequence: `fin_cases` isn't in scope in this import set, and `decide`
can't close a `List.ofFn` goal with a free variable.

The pattern in both real errors is the same, and it is worth the campaign noting: I was wrong
about arithmetic that no build would have flagged, in a machine whose `run` is total. Neither
mistake was caught by review or by taste. Both were caught by writing the claim down as something
the kernel could reject.
