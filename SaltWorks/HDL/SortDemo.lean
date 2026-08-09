/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.ISA
import SaltWorks.HDL.BatcherNet

/-!
# THE BATCHER-SORT DEMO — the two compile-around LOWERINGS, as theorems

`docs/compiler-inventory-0808.md` §Q2 recorded the gap in one line: *"the sort
demo's program ⛔ DOES NOT EXIST — 'compile-around' = 2 docs, 0 `.lean`. No
assembler, no generator, no lowering theorem."* This file is that artifact.

Slice A has **five** instructions (`ADD`, `ADDI`, `XOR`, `SLT`, `BEQ`) and
therefore **no `SUB`, no `BNE`, no conditional move, no memory, no shifts**. A
sorting network needs two things the machine does not have — *swap two
registers* and *branch when a flag is NOT set* — so both are **compiled around**,
and the two lowerings are the heart of this file:

| what the network wants | how Slice A gets it | the theorem |
|---|---|---|
| `swap rᵃ rᵇ`, no temporary | `XOR a a b; XOR b b a; XOR a a b` | `swap_lowering` |
| `cmpex (i,j)` | `SLT t rⱼ rᵢ; BEQ t x0 +16; ⟨swap⟩` | `cex_lowering` |

⭐ **THE PROGRAM IS GENERATED FROM `SaltWorks.HDL.bnComps` — the comparator list
of the SILICON Batcher sorter (`SaltWorks/HDL/BatcherNet.lean:67`, pinned at 24
by `bn_comps_count`).** `bnComps : List (Nat × Nat)` is a plain list of index
pairs, so it is directly usable: nothing was hand-written. **The software demo
and the 744-gate hardware sorter now share one comparator spec**, and the two
consume it with the same orientation convention — `ZeroOne.applyComp` puts `min`
at `c.1` and `max` at `c.2` (`SaltWorks/Stack/ZeroOne.lean:101`), and
`cex_lowering` concludes `rᶜ·¹ ≤ₛ rᶜ·²`. *That agreement is the load-bearing
detail: `bnComps` is a **bitonic** network, so six of its 24 pairs are
descending (`(3,2)`, `(7,6)`, `(6,4)`, `(7,5)`, `(5,4)`, `(7,6)`), and a lowering
that silently normalised pair order would sort nothing.*

## 🔴 WHAT THIS FILE DOES **NOT** PROVE — read before quoting it

1. **There is NO universally-quantified sortedness theorem for the program.**
   `sort_sweep` is **8 concrete inputs, kernel-checked** — a certificate suite,
   not a proof that `sortProg` sorts every input. The route to the universal
   statement is named and unbuilt: `Stack.ZeroOne.batcher8_sorts` already gives
   *"the network sorts every `LinearOrder`"*, so what is missing is (a) a
   `LinearOrder (BitVec 32)` for the SIGNED order and (b) a simulation theorem
   `run sortProg ≈ runNet batcher8`. Both need Mathlib, which leg 2 excludes.
2. **The demo runs at the `Instr`/`step` level, not through `encode`/`stepT`.**
   `sortProg_round_trips` shows every instruction of the program decodes back to
   itself, but a word-level `run` harness (a `runFor` over `List (BitVec 32)`)
   **does not exist in the corpus** and is not built here.
3. **The swap lowering needs `a ≠ b`.** `XOR a a b` with `a = b` zeroes the
   register; the three-XOR trick is *false* on aliased operands, and the
   hypothesis is not decoration. `bnComps_hyps_ok` discharges it for the real
   comparator list rather than assuming it.
-/

namespace SaltWorks.SortDemo

open SaltWorks.ISA

/-! ## 0 · The projection lemmas — what one `step` does to one register

Every proof below is built from these. They are stated per-instruction and
per-register so that no proof in this file ever unfolds `St.set` or reasons about
`Vector` equality — a swap writes the same register twice, and a state-level
equality would drag in `Vector.set` commutation for no gain. -/

theorem get_next (s : St) (r : Fin 32) : s.next.get r = s.get r := rfl

theorem pc_next (s : St) : s.next.pc = s.pc + 4 := rfl

theorem set_pc (s : St) (d : Fin 32) (v : BitVec 32) : (s.set d v).pc = s.pc := by
  unfold St.set; split <;> rfl

theorem get_step_xor (s : St) (d a b r : Fin 32) (hd : d ≠ 0) :
    (step s (.XOR d a b)).get r = if r = d then s.get a ^^^ s.get b else s.get r := by
  show (St.set s d (s.get a ^^^ s.get b)).next.get r = _
  rw [get_next]
  by_cases h : r = d
  · subst h; rw [St.get_set_self _ _ _ hd, if_pos rfl]
  · rw [St.get_set_ne _ _ _ _ h, if_neg h]

theorem get_step_xor_self (s : St) (d a b : Fin 32) (hd : d ≠ 0) :
    (step s (.XOR d a b)).get d = s.get a ^^^ s.get b := by
  rw [get_step_xor _ _ _ _ _ hd, if_pos rfl]

theorem get_step_xor_ne (s : St) (d a b r : Fin 32) (hd : d ≠ 0) (hr : r ≠ d) :
    (step s (.XOR d a b)).get r = s.get r := by
  rw [get_step_xor _ _ _ _ _ hd, if_neg hr]

theorem get_step_slt (s : St) (d a b r : Fin 32) (hd : d ≠ 0) :
    (step s (.SLT d a b)).get r
      = if r = d then (if (s.get a).slt (s.get b) then 1 else 0) else s.get r := by
  show (St.set s d _).next.get r = _
  rw [get_next]
  by_cases h : r = d
  · subst h; rw [St.get_set_self _ _ _ hd, if_pos rfl]
  · rw [St.get_set_ne _ _ _ _ h, if_neg h]

theorem get_step_slt_self (s : St) (d a b : Fin 32) (hd : d ≠ 0) :
    (step s (.SLT d a b)).get d = if (s.get a).slt (s.get b) then 1 else 0 := by
  rw [get_step_slt _ _ _ _ _ hd, if_pos rfl]

theorem get_step_slt_ne (s : St) (d a b r : Fin 32) (hd : d ≠ 0) (hr : r ≠ d) :
    (step s (.SLT d a b)).get r = s.get r := by
  rw [get_step_slt _ _ _ _ _ hd, if_neg hr]

/-- **A `BEQ` never touches the register file.** The half of the branch lowering
that makes the skip a control-flow fact and nothing else. -/
theorem get_step_beq (s : St) (a b : Fin 32) (imm : BitVec 12) (r : Fin 32) :
    (step s (.BEQ a b imm)).get r = s.get r := by
  show (if s.get a = s.get b then { s with pc := s.pc + bOffset imm } else s.next).get r = _
  split <;> rfl

theorem pc_step_xor (s : St) (d a b : Fin 32) : (step s (.XOR d a b)).pc = s.pc + 4 := by
  show (St.set s d _).next.pc = _
  rw [pc_next, set_pc]

theorem pc_step_slt (s : St) (d a b : Fin 32) : (step s (.SLT d a b)).pc = s.pc + 4 := by
  show (St.set s d _).next.pc = _
  rw [pc_next, set_pc]

theorem pc_step_beq_taken (s : St) (a b : Fin 32) (imm : BitVec 12)
    (h : s.get a = s.get b) : (step s (.BEQ a b imm)).pc = s.pc + bOffset imm := by
  show (if s.get a = s.get b then { s with pc := s.pc + bOffset imm } else s.next).pc = _
  rw [if_pos h]

theorem pc_step_beq_not (s : St) (a b : Fin 32) (imm : BitVec 12)
    (h : s.get a ≠ s.get b) : (step s (.BEQ a b imm)).pc = s.pc + 4 := by
  show (if s.get a = s.get b then { s with pc := s.pc + bOffset imm } else s.next).pc = _
  rw [if_neg h]; rfl

/-! ## 1 · `fetch` and `runFor`, at a known `pc`

`runFor` is structural on a `Nat`, so a fixed-length fragment is unrolled by
these two lemmas and a `fetch` fact per instruction. **No fuel parameter appears
in any statement below** — `run` supplies its own bound. -/

/-- The only `fetch` fact anything needs: at a byte address that is `4 * k`, the
fetch is the `k`-th instruction (or `none` past the end). The `% 4 = 0`
side-condition of `fetch` is discharged arithmetically, once. -/
theorem fetch_at (code : List Instr) (p : BitVec 32) (k : Nat) (h : p.toNat = 4 * k) :
    fetch code p = code[k]? := by
  unfold fetch
  have h1 : 4 * k % 4 = 0 := by omega
  have h2 : 4 * k / 4 = k := by omega
  rw [h, h1, h2, if_pos rfl]

theorem runFor_step (n : Nat) (code : List Instr) (s : St) (ins : Instr)
    (h : fetch code s.pc = some ins) : runFor (n + 1) code s = runFor n code (step s ins) := by
  show (match fetch code s.pc with
        | none => s | some i => runFor n code (step s i)) = _
  rw [h]

theorem runFor_stop (n : Nat) (code : List Instr) (s : St)
    (h : fetch code s.pc = none) : runFor n code s = s := by
  cases n with
  | zero => rfl
  | succ m =>
    show (match fetch code s.pc with
          | none => s | some i => runFor m code (step s i)) = _
    rw [h]

/-! ## 2 · The two algebras the lowerings run on

`XOR` self-annihilation is what makes a temporary-free swap possible; signed
antisymmetry is what makes `SLT` + `BEQ` an *ordering*. Both are stated over the
real `BitVec 32`, not over an abstraction. -/

theorem bv_xor_cancel_left (A B : BitVec 32) : A ^^^ (A ^^^ B) = B := by
  rw [← BitVec.xor_assoc, BitVec.xor_self, BitVec.zero_xor]

/-- The second XOR recovers `A` in `b`. -/
theorem bv_xor_swap_b (A B : BitVec 32) : B ^^^ (A ^^^ B) = A := by
  rw [BitVec.xor_comm A B, bv_xor_cancel_left]

/-- The third XOR recovers `B` in `a`. -/
theorem bv_xor_swap_a (A B : BitVec 32) : (A ^^^ B) ^^^ (B ^^^ (A ^^^ B)) = B := by
  rw [bv_xor_swap_b]

/-- `a <ₛ b → a ≤ₛ b`. Used on the exchange branch. -/
theorem sle_of_slt {a b : BitVec 32} (h : a.slt b = true) : a.sle b = true := by
  simp only [BitVec.slt_eq_decide, decide_eq_true_eq] at h
  simp only [BitVec.sle, decide_eq_true_eq]
  omega

/-- `¬ (b <ₛ a) → a ≤ₛ b`. Used on the no-exchange branch — this is the step that
makes "`SLT` said no" mean "already ordered", and it is SIGNED. -/
theorem sle_of_slt_false {a b : BitVec 32} (h : b.slt a = false) : a.sle b = true := by
  simp only [BitVec.slt_eq_decide, decide_eq_false_iff_not] at h
  simp only [BitVec.sle, decide_eq_true_eq]
  omega

/-! ## 3 · LOWERING ONE — `swap` → THREE XORs, no temporary

⚠️ **The no-other-register clause is the load-bearing half.** A "swap" that
clobbers a third register is not a swap, and in a sorting network the third
register is another wire — the bug would be invisible on any single comparator
and fatal on the network. It is the `∀ r, r ≠ a → r ≠ b → …` conjunct. -/

/-- The lowering, as code. **Three instructions, no temporary** — which matters
because Slice A has no spare architectural scratch beyond what the allocator
hands out, and the compare-exchange below already spends one on the `SLT`. -/
def swapSeq (a b : Fin 32) : List Instr := [.XOR a a b, .XOR b b a, .XOR a a b]

/-- The same three instructions as a `step` composition, so the fragment can be
reused inside the compare-exchange without re-running `fetch`. -/
def swapExec (s : St) (a b : Fin 32) : St :=
  step (step (step s (.XOR a a b)) (.XOR b b a)) (.XOR a a b)

/-- **The complete register semantics of the three-XOR swap**: `a` and `b` hold
each other's original values and **every other register is untouched**. -/
theorem swapExec_get (a b : Fin 32) (ha : a ≠ 0) (hb : b ≠ 0) (hab : a ≠ b)
    (s : St) (r : Fin 32) :
    (swapExec s a b).get r = if r = a then s.get b else if r = b then s.get a else s.get r := by
  unfold swapExec
  by_cases hra : r = a
  · subst hra
    rw [get_step_xor_self _ _ _ _ ha, get_step_xor_ne _ _ _ _ _ hb hab,
        get_step_xor_self _ _ _ _ hb, get_step_xor_self _ _ _ _ ha,
        get_step_xor_ne _ _ _ _ _ ha (Ne.symm hab), if_pos rfl]
    exact bv_xor_swap_a _ _
  · by_cases hrb : r = b
    · subst hrb
      rw [get_step_xor_ne _ _ _ _ _ ha hra, get_step_xor_self _ _ _ _ hb,
          get_step_xor_self _ _ _ _ ha, get_step_xor_ne _ _ _ _ _ ha hra,
          if_neg hra, if_pos rfl]
      exact bv_xor_swap_b _ _
    · rw [get_step_xor_ne _ _ _ _ _ ha hra, get_step_xor_ne _ _ _ _ _ hb hrb,
          get_step_xor_ne _ _ _ _ _ ha hra, if_neg hra, if_neg hrb]

theorem swapExec_pc (s : St) (a b : Fin 32) : (swapExec s a b).pc = s.pc + 4 + 4 + 4 := by
  unfold swapExec
  rw [pc_step_xor, pc_step_xor, pc_step_xor]

/-- `run` on the three-instruction fragment IS the three-step composition: the
program is straight-line, so the bound `code.length = 3` is exact. -/
theorem swap_reduce (a b : Fin 32) (s : St) (hpc : s.pc = 0) :
    run (swapSeq a b) s = swapExec s a b := by
  have e0 : fetch (swapSeq a b) s.pc = some (.XOR a a b) := by
    rw [fetch_at _ _ 0 (by rw [hpc]; decide)]; rfl
  have p1 : (step s (.XOR a a b)).pc = 0 + 4 := by rw [pc_step_xor, hpc]
  have e1 : fetch (swapSeq a b) (step s (.XOR a a b)).pc = some (.XOR b b a) := by
    rw [fetch_at _ _ 1 (by rw [p1]; decide)]; rfl
  have p2 : (step (step s (.XOR a a b)) (.XOR b b a)).pc = 0 + 4 + 4 := by
    rw [pc_step_xor, p1]
  have e2 : fetch (swapSeq a b) (step (step s (.XOR a a b)) (.XOR b b a)).pc
      = some (.XOR a a b) := by
    rw [fetch_at _ _ 2 (by rw [p2]; decide)]; rfl
  show runFor (2 + 1) (swapSeq a b) s = _
  rw [runFor_step _ _ _ _ e0]
  show runFor (1 + 1) (swapSeq a b) (step s (.XOR a a b)) = _
  rw [runFor_step _ _ _ _ e1]
  show runFor (0 + 1) (swapSeq a b) (step (step s (.XOR a a b)) (.XOR b b a)) = _
  rw [runFor_step _ _ _ _ e2]
  rfl

/-- ⭐ **LOWERING ONE, over the real `run`.** After `XOR a a b; XOR b b a;
XOR a a b`, the two registers hold each other's original values, **no other
register changes**, and the `pc` is 12 bytes on (so the fragment is straight-line
and composes). `a ≠ b` is required and is not decoration: on `a = b` the first
instruction zeroes the register. -/
theorem swap_lowering (a b : Fin 32) (ha : a ≠ 0) (hb : b ≠ 0) (hab : a ≠ b)
    (s : St) (hpc : s.pc = 0) :
    (run (swapSeq a b) s).get a = s.get b
    ∧ (run (swapSeq a b) s).get b = s.get a
    ∧ (∀ r : Fin 32, r ≠ a → r ≠ b → (run (swapSeq a b) s).get r = s.get r)
    ∧ (run (swapSeq a b) s).pc = 12 := by
  rw [swap_reduce _ _ _ hpc]
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [swapExec_get _ _ ha hb hab, if_pos rfl]
  · rw [swapExec_get _ _ ha hb hab, if_neg (Ne.symm hab), if_pos rfl]
  · intro r hra hrb
    rw [swapExec_get _ _ ha hb hab, if_neg hra, if_neg hrb]
  · rw [swapExec_pc, hpc]; decide

/-! ## 4 · LOWERING TWO — `compare-exchange (i,j)` → `SLT` + `BEQ` + the swap

```
SLT t rj ri        -- t := 1  iff  rj <ₛ ri  iff  ri > rj  ⇒ exchange needed
BEQ t x0 +16       -- t = 0 ⇒ jump PAST the three XORs (bOffset 8 = 16 bytes)
XOR i i j          --
XOR j j i          --  the swap
XOR i i j          --
```

⚠️ **THE OPERAND ORDER IS `SLT t rj ri`, NOT `SLT t ri rj`.** `SLT` is SIGNED
and Slice A has no `SUB` and no `BNE`, so the *only* way to test "out of order"
with one instruction and skip on the negative is to compute `rj <ₛ ri` and branch
on **equal to `x0`**. Reversing the two operands compiles, runs, and sorts
**descending** — see `neg_slt_order_descending_on_the_sample`.

⚠️ **`bOffset 8 = 16`, not 8.** The `BEQ` immediate holds `imm[12:1]`; the low
zero bit is structural. Three skipped instructions are 12 bytes measured from the
branch's *own* address plus its own 4 — see `neg_short_skip_*` /
`neg_long_skip_*`. -/

/-- The compare-exchange lowering, as code. `t` is the one scratch register the
lowering spends. -/
def cexSeq (t i j : Fin 32) : List Instr :=
  [ .SLT t j i, .BEQ t 0 8, .XOR i i j, .XOR j j i, .XOR i i j ]

/-- The `BEQ` is taken exactly when no exchange is needed. Shared by the two
reduction lemmas and the two `pc` lemmas so the condition is computed once. -/
theorem cex_beq_taken (t i j : Fin 32) (ht : t ≠ 0) (s : St)
    (h : (s.get j).slt (s.get i) = false) :
    (step s (.SLT t j i)).get t = (step s (.SLT t j i)).get 0 := by
  rw [St.get_zero, get_step_slt_self _ _ _ _ ht, h, if_neg (by decide)]

/-- ⛔ **RENAMED 20:5x from `cex_beq_not_taken`, which named the CONSEQUENCE while the
statement proves the ANTECEDENT.** What is proved is that the `SLT` result register differs
from `x0`'s value; *that* is what `pc_step_beq_not` then consumes to conclude the branch is
not taken. **The old name asserted the conclusion of a step this theorem only enables** —
found by running the name-vs-statement read over my own landings after math ran it on theirs
(3 hits in 15 for them; 4 in 120 here). -/
theorem cex_slt_result_differs_from_x0 (t i j : Fin 32) (ht : t ≠ 0) (s : St)
    (h : (s.get j).slt (s.get i) = true) :
    (step s (.SLT t j i)).get t ≠ (step s (.SLT t j i)).get 0 := by
  rw [St.get_zero, get_step_slt_self _ _ _ _ ht, h, if_pos rfl]
  decide

/-- **No exchange needed ⇒ the machine executes TWO instructions and leaves.**
The branch is taken and the three XORs never run. -/
theorem cex_reduce_keep (t i j : Fin 32) (ht : t ≠ 0) (s : St) (hpc : s.pc = 0)
    (h : (s.get j).slt (s.get i) = false) :
    run (cexSeq t i j) s = step (step s (.SLT t j i)) (.BEQ t 0 8) := by
  have e0 : fetch (cexSeq t i j) s.pc = some (.SLT t j i) := by
    rw [fetch_at _ _ 0 (by rw [hpc]; decide)]; rfl
  have p1 : (step s (.SLT t j i)).pc = 0 + 4 := by rw [pc_step_slt, hpc]
  have e1 : fetch (cexSeq t i j) (step s (.SLT t j i)).pc = some (.BEQ t 0 8) := by
    rw [fetch_at _ _ 1 (by rw [p1]; decide)]; rfl
  have p2 : (step (step s (.SLT t j i)) (.BEQ t 0 8)).pc = 20 := by
    rw [pc_step_beq_taken _ _ _ _ (cex_beq_taken t i j ht s h), p1]; decide
  have e2 : fetch (cexSeq t i j) (step (step s (.SLT t j i)) (.BEQ t 0 8)).pc = none := by
    rw [fetch_at _ _ 5 (by rw [p2]; decide)]; rfl
  show runFor (4 + 1) (cexSeq t i j) s = _
  rw [runFor_step _ _ _ _ e0]
  show runFor (3 + 1) (cexSeq t i j) (step s (.SLT t j i)) = _
  rw [runFor_step _ _ _ _ e1]
  exact runFor_stop _ _ _ e2

/-- **Exchange needed ⇒ the machine falls through and runs the swap.** The result
is `swapExec` applied to the post-`SLT` state — which is why LOWERING ONE is
literally reused here rather than re-proved. -/
theorem cex_reduce_swap (t i j : Fin 32) (ht : t ≠ 0) (s : St) (hpc : s.pc = 0)
    (h : (s.get j).slt (s.get i) = true) :
    run (cexSeq t i j) s = swapExec (step (step s (.SLT t j i)) (.BEQ t 0 8)) i j := by
  have e0 : fetch (cexSeq t i j) s.pc = some (.SLT t j i) := by
    rw [fetch_at _ _ 0 (by rw [hpc]; decide)]; rfl
  have p1 : (step s (.SLT t j i)).pc = 0 + 4 := by rw [pc_step_slt, hpc]
  have e1 : fetch (cexSeq t i j) (step s (.SLT t j i)).pc = some (.BEQ t 0 8) := by
    rw [fetch_at _ _ 1 (by rw [p1]; decide)]; rfl
  have p2 : (step (step s (.SLT t j i)) (.BEQ t 0 8)).pc = 0 + 4 + 4 := by
    rw [pc_step_beq_not _ _ _ _ (cex_slt_result_differs_from_x0 t i j ht s h), p1]
  have e2 : fetch (cexSeq t i j) (step (step s (.SLT t j i)) (.BEQ t 0 8)).pc
      = some (.XOR i i j) := by
    rw [fetch_at _ _ 2 (by rw [p2]; decide)]; rfl
  have p3 : (step (step (step s (.SLT t j i)) (.BEQ t 0 8)) (.XOR i i j)).pc
      = 0 + 4 + 4 + 4 := by rw [pc_step_xor, p2]
  have e3 : fetch (cexSeq t i j)
      (step (step (step s (.SLT t j i)) (.BEQ t 0 8)) (.XOR i i j)).pc
      = some (.XOR j j i) := by
    rw [fetch_at _ _ 3 (by rw [p3]; decide)]; rfl
  have p4 : (step (step (step (step s (.SLT t j i)) (.BEQ t 0 8)) (.XOR i i j))
      (.XOR j j i)).pc = 0 + 4 + 4 + 4 + 4 := by rw [pc_step_xor, p3]
  have e4 : fetch (cexSeq t i j)
      (step (step (step (step s (.SLT t j i)) (.BEQ t 0 8)) (.XOR i i j))
        (.XOR j j i)).pc = some (.XOR i i j) := by
    rw [fetch_at _ _ 4 (by rw [p4]; decide)]; rfl
  show runFor (4 + 1) (cexSeq t i j) s = _
  rw [runFor_step _ _ _ _ e0]
  show runFor (3 + 1) (cexSeq t i j) (step s (.SLT t j i)) = _
  rw [runFor_step _ _ _ _ e1]
  show runFor (2 + 1) (cexSeq t i j) (step (step s (.SLT t j i)) (.BEQ t 0 8)) = _
  rw [runFor_step _ _ _ _ e2]
  show runFor (1 + 1) (cexSeq t i j)
      (step (step (step s (.SLT t j i)) (.BEQ t 0 8)) (.XOR i i j)) = _
  rw [runFor_step _ _ _ _ e3]
  show runFor (0 + 1) (cexSeq t i j)
      (step (step (step (step s (.SLT t j i)) (.BEQ t 0 8)) (.XOR i i j))
        (.XOR j j i)) = _
  rw [runFor_step _ _ _ _ e4]
  rfl

/-- ⭐ **LOWERING TWO, over the real `run`.** Four conjuncts, and the first two
are the ones the task calls out as both mandatory:

* **ORDERED** — `rᵢ ≤ₛ rⱼ` afterwards, SIGNED;
* **VALUES PRESERVED** — the pair is either untouched or exchanged, so the
  two-element multiset is unchanged. *Ordered-without-preserving is the bug that
  sorts by overwriting, and it would satisfy conjunct 1 alone.* (Stated as
  kept-or-exchanged rather than with `Multiset`, which is Mathlib and would cost
  leg 2 its Mathlib-free build; the disjunction is strictly stronger.)
* **FRAME** — every register other than `t`, `rᵢ`, `rⱼ` is untouched;
* **EXIT** — `pc` is 20 bytes on **whichever way the branch went**, which is what
  makes the fragments composable back-to-back. -/
theorem cex_lowering (t i j : Fin 32) (ht : t ≠ 0) (hi : i ≠ 0) (hj : j ≠ 0)
    (hij : i ≠ j) (hit : i ≠ t) (hjt : j ≠ t) (s : St) (hpc : s.pc = 0) :
    ((run (cexSeq t i j) s).get i).sle ((run (cexSeq t i j) s).get j) = true
    ∧ (((run (cexSeq t i j) s).get i = s.get i ∧ (run (cexSeq t i j) s).get j = s.get j)
       ∨ ((run (cexSeq t i j) s).get i = s.get j ∧ (run (cexSeq t i j) s).get j = s.get i))
    ∧ (∀ r : Fin 32, r ≠ t → r ≠ i → r ≠ j → (run (cexSeq t i j) s).get r = s.get r)
    ∧ (run (cexSeq t i j) s).pc = 20 := by
  cases hslt : (s.get j).slt (s.get i) with
  | false =>
    rw [cex_reduce_keep t i j ht s hpc hslt]
    have gi : (step (step s (.SLT t j i)) (.BEQ t 0 8)).get i = s.get i := by
      rw [get_step_beq, get_step_slt_ne _ _ _ _ _ ht hit]
    have gj : (step (step s (.SLT t j i)) (.BEQ t 0 8)).get j = s.get j := by
      rw [get_step_beq, get_step_slt_ne _ _ _ _ _ ht hjt]
    refine ⟨?_, ?_, ?_, ?_⟩
    · rw [gi, gj]; exact sle_of_slt_false hslt
    · exact Or.inl ⟨gi, gj⟩
    · intro r hrt _ _
      rw [get_step_beq, get_step_slt_ne _ _ _ _ _ ht hrt]
    · rw [pc_step_beq_taken _ _ _ _ (cex_beq_taken t i j ht s hslt), pc_step_slt, hpc]
      decide
  | true =>
    rw [cex_reduce_swap t i j ht s hpc hslt]
    have gi : (step (step s (.SLT t j i)) (.BEQ t 0 8)).get i = s.get i := by
      rw [get_step_beq, get_step_slt_ne _ _ _ _ _ ht hit]
    have gj : (step (step s (.SLT t j i)) (.BEQ t 0 8)).get j = s.get j := by
      rw [get_step_beq, get_step_slt_ne _ _ _ _ _ ht hjt]
    have hgi : (swapExec (step (step s (.SLT t j i)) (.BEQ t 0 8)) i j).get i = s.get j := by
      rw [swapExec_get _ _ hi hj hij, if_pos rfl, gj]
    have hgj : (swapExec (step (step s (.SLT t j i)) (.BEQ t 0 8)) i j).get j = s.get i := by
      rw [swapExec_get _ _ hi hj hij, if_neg (Ne.symm hij), if_pos rfl, gi]
    refine ⟨?_, ?_, ?_, ?_⟩
    · rw [hgi, hgj]; exact sle_of_slt hslt
    · exact Or.inr ⟨hgi, hgj⟩
    · intro r hrt hri hrj
      rw [swapExec_get _ _ hi hj hij, if_neg hri, if_neg hrj, get_step_beq,
        get_step_slt_ne _ _ _ _ _ ht hrt]
    · rw [swapExec_pc, pc_step_beq_not _ _ _ _ (cex_slt_result_differs_from_x0 t i j ht s hslt),
        pc_step_slt, hpc]
      decide

/-! ## 5 · THE PROGRAM — generated from the SILICON comparator list

`bnComps` is `List (Nat × Nat)`, so the generator is one `flatMap`. Wire `w` is
register `x(w+1)`; the `SLT` scratch is `x9`, which is why eight wires need nine
registers and why `x0` is never a wire (a write to `x0` is discarded — `x0` as a
wire would make one comparator a silent no-op, which is exactly freeze trap P5). -/

/-- Wire `w` ↦ register `x(w+1)`. The `% 32` is what makes this total; wires are
`0…7` in every use, so it never fires. -/
def wireReg (w : Nat) : Fin 32 := ⟨(w + 1) % 32, Nat.mod_lt _ (by decide)⟩

/-- The one scratch register the compare-exchange lowering spends. -/
def tReg : Fin 32 := 9

/-- The generator: one comparator ↦ five instructions. -/
def cexOf (c : Nat × Nat) : List Instr := cexSeq tReg (wireReg c.1) (wireReg c.2)

/-- ⭐ **THE PROGRAM.** `SaltWorks.HDL.bnComps` is the silicon Batcher sorter's
own comparator list; this is that list lowered into Slice A. -/
def sortProg : List Instr := SaltWorks.HDL.bnComps.flatMap cexOf

theorem sortProg_length : sortProg.length = 120 := by decide +kernel

/-- The comparator list this program was generated from is the one the hardware
uses — restated here so the dependency is visible in this file's own theorems. -/
theorem sortProg_source_is_bnComps : SaltWorks.HDL.bnComps.length = 24 := by decide +kernel

/-- **`cex_lowering`'s six hypotheses, discharged for every comparator of the real
list.** Without this the lowering theorem is true and inapplicable: `bnComps` is
data, and nothing about it guarantees distinct non-zero registers that avoid the
scratch. -/
def cexHypsOK (c : Nat × Nat) : Bool :=
  let i := wireReg c.1
  let j := wireReg c.2
  !(tReg == 0) && !(i == 0) && !(j == 0) && !(i == j) && !(i == tReg) && !(j == tReg)

theorem bnComps_hyps_ok : SaltWorks.HDL.bnComps.all cexHypsOK = true := by decide +kernel

/-- And the scope of that check, inside the verdict: 24 comparators, all of them. -/
theorem bnComps_hyps_ok_scope : (SaltWorks.HDL.bnComps.filter cexHypsOK).length = 24 := by
  decide +kernel

/-- **Six of the 24 pairs are DESCENDING** (`bnComps` is bitonic). Pinned because
a lowering that normalised pair order would pass every ascending comparator and
sort nothing — and because it is the reason `cex_lowering`'s conclusion had to be
`rᶜ·¹ ≤ₛ rᶜ·²` and not `min/max` by register index. -/
theorem bnComps_has_descending_pairs :
    (SaltWorks.HDL.bnComps.filter (fun c => c.2 < c.1)).length = 6 := by decide +kernel

/-- **Every instruction of the program is real machine code** — it encodes to a
32-bit word that decodes back to itself. A corollary of `decode_encode`, stated
because "a `List Instr`" and "a program the silicon could fetch" are different
claims. ⛔ *This is NOT a word-level execution: no `runFor` over
`List (BitVec 32)` exists in the corpus, so the demo below runs `step`, not
`stepT`.* -/
theorem sortProg_round_trips :
    sortProg.map (fun i => decode (encode i)) = sortProg.map some := by
  simp [decode_encode]

/-! ## 6 · THE DEMO — `ISA.run`, kernel-checked

The loader is `ADDI xk, x0, v` per wire: eight instructions, and it is part of
the program, so `run` executes the load and the sort together from `St.init`.
`ADDI` sign-extends, so the negative fixtures below are loaded by the same
instruction that Slice A's `addi_sign_extends` trap certificate pins. -/

def loadSeq (vals : List Int) : List Instr :=
  (List.range vals.length).map
    (fun k => Instr.ADDI (wireReg k) 0 (BitVec.ofInt 12 (vals.getD k 0)))

/-- The whole demo program for one input, parameterised by the comparator
lowering so that the negative controls below are the SAME program with ONE
mutation. -/
def progOf (gen : Fin 32 → Fin 32 → Fin 32 → List Instr) (vals : List Int) : List Instr :=
  loadSeq vals ++ SaltWorks.HDL.bnComps.flatMap
    (fun c => gen tReg (wireReg c.1) (wireReg c.2))

def demoRun (gen : Fin 32 → Fin 32 → Fin 32 → List Instr) (vals : List Int) : St :=
  run (progOf gen vals) St.init

def outWords (s : St) : List (BitVec 32) := (List.range 8).map (fun k => s.get (wireReg k))

def outInts (s : St) : List Int := (outWords s).map BitVec.toInt

/-- Sortedness of the eight wires, SIGNED and adjacent-pairwise. -/
def sortedAsc (s : St) : Bool :=
  (List.range 7).all (fun k => (s.get (wireReg k)).sle (s.get (wireReg (k + 1))))

/-- **The demo program IS the loader followed by `sortProg`.** `progOf` is
parameterised by the lowering so the mutants below are one-change variants of the
same generator; this equation is what keeps the honest instance tied to the named
program rather than to a re-spelled copy of it. -/
theorem progOf_cexSeq_is_sortProg (vals : List Int) :
    progOf cexSeq vals = loadSeq vals ++ sortProg := rfl

theorem demoProg_length : (progOf cexSeq [5, -3, 0, 7, -8, 2, 2, -1]).length = 128 := by
  decide +kernel

/-- **The headline demo.** One concrete unsorted 8-register state, run through
`ISA.run`, ends sorted. -/
theorem demo_sorts : sortedAsc (demoRun cexSeq [5, -3, 0, 7, -8, 2, 2, -1]) = true := by
  decide +kernel

/-- **And the output is the input's values, not merely a sorted list** — the
exact eight words. `demo_sorts` alone is satisfied by a program that zeroes the
register file. -/
theorem demo_output_exact :
    outWords (demoRun cexSeq [5, -3, 0, 7, -8, 2, 2, -1])
      = [-8, -3, -1, 0, 2, 2, 5, 7].map (BitVec.ofInt 32) := by
  decide +kernel

/-- **And the program RAN TO COMPLETION.** `run`'s bound is `code.length = 128`
and the all-exchange path needs exactly 128 steps, so a `pc` short of 512 would
mean `runFor` ran out of bound mid-network — a truncated run that could still
look sorted. -/
theorem demo_pc_off_the_end : (demoRun cexSeq [5, -3, 0, 7, -8, 2, 2, -1]).pc = 512 := by
  decide +kernel

/-! ### The sweep

Each case checks all three at once — exit `pc`, the exact output words, and
sortedness. ⚠️ **This is a SAMPLE, not a proof:** eight inputs, named below, and
`sort_sweep_scope` puts the count inside the verdict. -/

def caseOK (vals expect : List Int) : Bool :=
  let s := demoRun cexSeq vals
  (s.pc == 512) && (outWords s == expect.map (BitVec.ofInt 32)) && sortedAsc s

/-- The fixtures: mixed · already-sorted · reverse-sorted · all-equal ·
all-negative · the full `ADDI` signed range · negatives with duplicates ·
alternating signs. **Five of the eight carry negative entries, which is where a
wrong (unsigned) `SLT` lowering hides.**

📌 *The `= 5` below was written `= 4` first and `decide` refuted it — the count in
a scope claim is exactly the kind of number that gets asserted from memory. It is
in the file so nobody has to trust my counting.* -/
def sweepCases : List (List Int × List Int) :=
  [ ([5, -3, 0, 7, -8, 2, 2, -1],                 [-8, -3, -1, 0, 2, 2, 5, 7])
  , ([1, 2, 3, 4, 5, 6, 7, 8],                    [1, 2, 3, 4, 5, 6, 7, 8])
  , ([8, 7, 6, 5, 4, 3, 2, 1],                    [1, 2, 3, 4, 5, 6, 7, 8])
  , ([3, 3, 3, 3, 3, 3, 3, 3],                    [3, 3, 3, 3, 3, 3, 3, 3])
  , ([-1, -2, -3, -4, -5, -6, -7, -8],            [-8, -7, -6, -5, -4, -3, -2, -1])
  , ([-2048, 2047, -1, 0, 1, -2047, 2046, -1024],
     [-2048, -2047, -1024, -1, 0, 1, 2046, 2047])
  , ([0, -1, 1, -1, 1, 0, -1, 1],                 [-1, -1, -1, 0, 0, 1, 1, 1])
  , ([-1, 1, -2, 2, -3, 3, -4, 4],                [-4, -3, -2, -1, 1, 2, 3, 4]) ]

theorem sort_sweep : sweepCases.all (fun c => caseOK c.1 c.2) = true := by decide +kernel

theorem sort_sweep_scope : sweepCases.length = 8 := by decide +kernel

theorem sort_sweep_negatives_scope :
    (sweepCases.filter (fun c => c.1.any (fun v => v < 0))).length = 5 := by decide +kernel

/-! ## 7 · NEGATIVE CONTROLS — each lowering decision, shown NECESSARY

*A lowering nobody can show is necessary is decoration.* Each mutant below
changes exactly ONE thing and is run through the same generator on the same
input. -/

/-- MUTANT 1 — the `SLT` operands reversed. -/
def cexBadOrder (t i j : Fin 32) : List Instr :=
  [ .SLT t i j, .BEQ t 0 8, .XOR i i j, .XOR j j i, .XOR i i j ]

/-- MUTANT 2 — one XOR dropped. Replaced by `ADDI x0 x0 0`, a genuine NOP in this
ISA (writes to `x0` are discarded, freeze trap P5), so the fragment keeps its
length and its branch offset: the ONLY difference is the missing XOR. -/
def cexDropXor (t i j : Fin 32) : List Instr :=
  [ .SLT t j i, .BEQ t 0 8, .XOR i i j, .XOR j j i, .ADDI 0 0 0 ]

/-- MUTANT 3 — the skip is one instruction too short (`bOffset 6 = 12` bytes). -/
def cexShortSkip (t i j : Fin 32) : List Instr :=
  [ .SLT t j i, .BEQ t 0 6, .XOR i i j, .XOR j j i, .XOR i i j ]

/-- MUTANT 4 — the skip is one instruction too long (`bOffset 10 = 20` bytes). -/
def cexLongSkip (t i j : Fin 32) : List Instr :=
  [ .SLT t j i, .BEQ t 0 10, .XOR i i j, .XOR j j i, .XOR i i j ]

/-- **MUTANT 1 is not sorted** … -/
theorem neg_slt_order_not_sorted :
    sortedAsc (demoRun cexBadOrder [5, -3, 0, 7, -8, 2, 2, -1]) = false := by decide +kernel

/-- … and the failure is *informative*: with the `SLT` operands reversed the
network sorts **DESCENDING**. The operand order is not a detail, it is the sort
direction, and this is the exact shape a "the network sorts, ship it" spot check
on `≤` would have caught only by luck. 

⚠️ **RENAMED 20:5x from `neg_slt_order_sorts_descending`: one input's output being
descending is a SAMPLE, and the old name stated it as a PROPERTY of the mutant.** The
statement is unchanged and is exactly as strong as it was; only the promise shrank. -/
theorem neg_slt_order_descending_on_the_sample :
    outWords (demoRun cexBadOrder [5, -3, 0, 7, -8, 2, 2, -1])
      = [7, 5, 2, 2, 0, -1, -3, -8].map (BitVec.ofInt 32) := by decide +kernel

/-- **MUTANT 2 is not sorted** … -/
theorem neg_drop_xor_not_sorted :
    sortedAsc (demoRun cexDropXor [5, -3, 0, 7, -8, 2, 2, -1]) = false := by decide +kernel

/-- … and it **destroys values**: `-3` was in the input and is nowhere in the
output. Two XORs leave `rᵢ = A ^^^ B` — a residue, not a value — so the mutant
does not merely mis-order, it loses data. -/
theorem neg_drop_xor_loses_a_value :
    (outInts (demoRun cexDropXor [5, -3, 0, 7, -8, 2, 2, -1])).contains (-3) = false := by
  decide +kernel

/-- The general fact behind it: **after only two XORs, `rᵃ` holds the XOR
residue** `A ^^^ B`, and `rᵃ` is corrupted for good. This is why the third XOR
exists. -/
theorem two_xors_leave_a_residue (a b : Fin 32) (ha : a ≠ 0) (hb : b ≠ 0) (hab : a ≠ b)
    (s : St) :
    (step (step s (.XOR a a b)) (.XOR b b a)).get a = s.get a ^^^ s.get b
    ∧ (step (step s (.XOR a a b)) (.XOR b b a)).get b = s.get a := by
  refine ⟨?_, ?_⟩
  · rw [get_step_xor_ne _ _ _ _ _ hb hab, get_step_xor_self _ _ _ _ ha]
  · rw [get_step_xor_self _ _ _ _ hb, get_step_xor_self _ _ _ _ ha,
      get_step_xor_ne _ _ _ _ _ ha (Ne.symm hab)]
    exact bv_xor_swap_b _ _

/-- And the residue is a value that was in NEITHER register: `1 ^^^ 2 = 3`. Run
on the real machine — two XORs leave `x1 = 3`, where the swap would have left
`x1 = 2`. -/
theorem two_xors_witness :
    let s := run [Instr.ADDI 1 0 1, .ADDI 2 0 2, .XOR 1 1 2, .XOR 2 2 1] St.init
    s.get 1 = 3 ∧ s.get 2 = 1 := by decide +kernel

/-- And the three-XOR swap on the same fixture leaves `2` and `1` — the contrast
that makes the previous certificate a corruption rather than a coincidence. -/
theorem three_xors_witness :
    let s := run [Instr.ADDI 1 0 1, .ADDI 2 0 2, .XOR 1 1 2, .XOR 2 2 1, .XOR 1 1 2] St.init
    s.get 1 = 2 ∧ s.get 2 = 1 := by decide +kernel

/-- **MUTANT 3 is not sorted** — a skip 4 bytes short lands ON the third XOR, so
the no-exchange path executes one XOR anyway. -/
theorem neg_short_skip_not_sorted :
    sortedAsc (demoRun cexShortSkip [5, -3, 0, 7, -8, 2, 2, -1]) = false := by decide +kernel

/-- … and it **fabricates a value that was never in the input**: `-6`, which is
`-8 ^^^ 2`. The input was `{5, -3, 0, 7, -8, 2, 2, -1}`. -/
theorem neg_short_skip_fabricates :
    (outInts (demoRun cexShortSkip [5, -3, 0, 7, -8, 2, 2, -1])).contains (-6) = true := by
  decide +kernel

/-- **MUTANT 4 is not sorted** — a skip 4 bytes long jumps over the NEXT
comparator's `SLT`, so that comparator branches on a stale flag. -/
theorem neg_long_skip_not_sorted :
    sortedAsc (demoRun cexLongSkip [5, -3, 0, 7, -8, 2, 2, -1]) = false := by decide +kernel

/-- … and the control-flow damage is visible in the `pc`: the program exits at
516, not 512, i.e. it left the code from the wrong place. -/
theorem neg_long_skip_wrong_exit :
    (demoRun cexLongSkip [5, -3, 0, 7, -8, 2, 2, -1]).pc = 516 := by decide +kernel

/-- **The mutants are the same program with one change** — same length, same
loader, same 24 comparators. Without this, "the mutant is not sorted" could be a
program that never ran. -/
theorem mutants_are_same_length :
    (progOf cexBadOrder [5, -3, 0, 7, -8, 2, 2, -1]).length = 128
    ∧ (progOf cexDropXor [5, -3, 0, 7, -8, 2, 2, -1]).length = 128
    ∧ (progOf cexShortSkip [5, -3, 0, 7, -8, 2, 2, -1]).length = 128
    ∧ (progOf cexLongSkip [5, -3, 0, 7, -8, 2, 2, -1]).length = 128 := by decide +kernel

/-! ## 8 · Axiom audit — every declaration, ONE PER CALL -/

#audit_axioms get_next
#audit_axioms pc_next
#audit_axioms set_pc
#audit_axioms get_step_xor
#audit_axioms get_step_xor_self
#audit_axioms get_step_xor_ne
#audit_axioms get_step_slt
#audit_axioms get_step_slt_self
#audit_axioms get_step_slt_ne
#audit_axioms get_step_beq
#audit_axioms pc_step_xor
#audit_axioms pc_step_slt
#audit_axioms pc_step_beq_taken
#audit_axioms pc_step_beq_not
#audit_axioms fetch_at
#audit_axioms runFor_step
#audit_axioms runFor_stop
#audit_axioms bv_xor_cancel_left
#audit_axioms bv_xor_swap_b
#audit_axioms bv_xor_swap_a
#audit_axioms sle_of_slt
#audit_axioms sle_of_slt_false
#audit_axioms swapSeq
#audit_axioms swapExec
#audit_axioms swapExec_get
#audit_axioms swapExec_pc
#audit_axioms swap_reduce
#audit_axioms swap_lowering
#audit_axioms cexSeq
#audit_axioms cex_beq_taken
#audit_axioms cex_slt_result_differs_from_x0
#audit_axioms cex_reduce_keep
#audit_axioms cex_reduce_swap
#audit_axioms cex_lowering
#audit_axioms wireReg
#audit_axioms tReg
#audit_axioms cexOf
#audit_axioms sortProg
#audit_axioms sortProg_length
#audit_axioms sortProg_source_is_bnComps
#audit_axioms cexHypsOK
#audit_axioms bnComps_hyps_ok
#audit_axioms bnComps_hyps_ok_scope
#audit_axioms bnComps_has_descending_pairs
#audit_axioms sortProg_round_trips
#audit_axioms loadSeq
#audit_axioms progOf
#audit_axioms demoRun
#audit_axioms outWords
#audit_axioms outInts
#audit_axioms sortedAsc
#audit_axioms progOf_cexSeq_is_sortProg
#audit_axioms demoProg_length
#audit_axioms demo_sorts
#audit_axioms demo_output_exact
#audit_axioms demo_pc_off_the_end
#audit_axioms caseOK
#audit_axioms sweepCases
#audit_axioms sort_sweep
#audit_axioms sort_sweep_scope
#audit_axioms sort_sweep_negatives_scope
#audit_axioms cexBadOrder
#audit_axioms cexDropXor
#audit_axioms cexShortSkip
#audit_axioms cexLongSkip
#audit_axioms neg_slt_order_not_sorted
#audit_axioms neg_slt_order_descending_on_the_sample
#audit_axioms neg_drop_xor_not_sorted
#audit_axioms neg_drop_xor_loses_a_value
#audit_axioms two_xors_leave_a_residue
#audit_axioms two_xors_witness
#audit_axioms three_xors_witness
#audit_axioms neg_short_skip_not_sorted
#audit_axioms neg_short_skip_fabricates
#audit_axioms neg_long_skip_not_sorted
#audit_axioms neg_long_skip_wrong_exit
#audit_axioms mutants_are_same_length

end SaltWorks.SortDemo

namespace SaltWorks.SortDemo

/-! ## 9 · SECOND-PARTY VERIFICATION — five inputs chosen to break it

⛔ **§ "WHAT THIS FILE DOES NOT PROVE" ① STILL STANDS: this is a bigger SAMPLE, not
the universal theorem.** `sort_sweep`'s eight fixtures were chosen by the same party
that wrote the lowering, and *a test table is a sample* — the standing lesson is a
fence guard that passed four constructed cases and swallowed 22% of real headers. So
these five were chosen by the COMPILER seat, adversarially, against a program already
claimed to work, and each was PREDICTED before it was read.

Together with `sort_sweep` the certified input count is **13**. Recorded as
`compiler_check_scope` so the number lives inside the verdict rather than in prose.

📌 **The last one carries no zero anywhere in its sorted form, and that is the point.**
If `outWords` read a region the program never wrote, every case above it would print a
tidy list of zeros and the all-equal fixture would have called that "sorted". An
output with no zero in it cannot be faked by a zeroed register file. *That control is
on MY instrument, not on the program — the reading I would have trusted wrongly.* -/

/-- Wide magnitudes, symmetric about zero. -/
theorem compiler_check_wide :
    outWords (demoRun cexSeq [1, -1, 100, -100, 50, -50, 3, -3])
      = [-100, -50, -3, -1, 1, 3, 50, 100].map (BitVec.ofInt 32) := by
  decide +kernel

/-- One element maximally out of place: the smallest value in the LAST slot, which is
the longest path through the network. -/
theorem compiler_check_last_slot :
    outWords (demoRun cexSeq [1, 2, 3, 4, 5, 6, 8, -7])
      = [-7, 1, 2, 3, 4, 5, 6, 8].map (BitVec.ofInt 32) := by
  decide +kernel

/-- A three-way tie plus a straddle — ties are where a comparator's orientation
convention shows, since `≤` and `<` differ only here. -/
theorem compiler_check_three_way_tie :
    outWords (demoRun cexSeq [4, 11, 4, -9, 7, 4, 11, 0])
      = [-9, 0, 4, 4, 4, 7, 11, 11].map (BitVec.ofInt 32) := by
  decide +kernel

/-- ⭐ **The `ADDI` immediate boundary in BOTH directions in one input**, with a
duplicate at the positive limit. `sort_sweep` covers the range; this covers both ENDS
simultaneously, where a sign-extension defect in the loader would surface as a
wrapped value rather than a mis-order. -/
theorem compiler_check_both_boundaries :
    outWords (demoRun cexSeq [2047, -2048, 0, 2047, -1, 2046, 1, -2047])
      = [-2048, -2047, -1, 0, 1, 2046, 2047, 2047].map (BitVec.ofInt 32) := by
  decide +kernel

/-- A control on the INSTRUMENT: no zero appears in the sorted output, so a readout of
never-written registers cannot produce it. -/
theorem compiler_check_no_zero_in_output :
    outWords (demoRun cexSeq [5, -4, 3, -2, 2, -3, 4, -5])
      = [-5, -4, -3, -2, 2, 3, 4, 5].map (BitVec.ofInt 32) := by
  decide +kernel

/-- The same five as a list, so the count below is a reading of a real object rather
than a literal I typed — and so they go through `caseOK`, which checks the exit `pc`,
the exact output words AND sortedness at once, i.e. strictly more than the five
output-only theorems above. -/
def compilerCases : List (List Int × List Int) :=
  [ ([1, -1, 100, -100, 50, -50, 3, -3],        [-100, -50, -3, -1, 1, 3, 50, 100])
  , ([1, 2, 3, 4, 5, 6, 8, -7],                 [-7, 1, 2, 3, 4, 5, 6, 8])
  , ([4, 11, 4, -9, 7, 4, 11, 0],               [-9, 0, 4, 4, 4, 7, 11, 11])
  , ([2047, -2048, 0, 2047, -1, 2046, 1, -2047],
       [-2048, -2047, -1, 0, 1, 2046, 2047, 2047])
  , ([5, -4, 3, -2, 2, -3, 4, -5],              [-5, -4, -3, -2, 2, 3, 4, 5]) ]

theorem compiler_check_all : compilerCases.all (fun c => caseOK c.1 c.2) = true := by
  decide +kernel

/-- The scope, inside the verdict, read off BOTH lists — not asserted about them. -/
theorem compiler_check_scope : compilerCases.length + sweepCases.length = 13 := by
  decide +kernel

/-- ⚠️ And the two lists are DISJOINT, which the count alone does not establish: 13 is
only 13 distinct inputs if no case was recertified under a second name. -/
theorem compiler_check_disjoint :
    (compilerCases.filter (fun c => sweepCases.any (fun d => d.1 = c.1))).length = 0 := by
  decide +kernel

#audit_axioms compiler_check_wide
#audit_axioms compiler_check_last_slot
#audit_axioms compiler_check_three_way_tie
#audit_axioms compiler_check_both_boundaries
#audit_axioms compiler_check_no_zero_in_output
#audit_axioms compilerCases
#audit_axioms compiler_check_all
#audit_axioms compiler_check_scope
#audit_axioms compiler_check_disjoint

end SaltWorks.SortDemo
