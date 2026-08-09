/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.SortDemo

/-!
# THE WORD-LEVEL EXECUTIVE — and the simulation theorem that lifts the demo to it

`SaltWorks/HDL/SortDemo.lean`'s own fence, item (2), written an hour before this file:
*"The demo runs at the `Instr`/`step` level, not through `encode`/`stepT`.
`sortProg_round_trips` shows every instruction of the program decodes back to itself,
but a word-level `run` harness (a `runFor` over `List (BitVec 32)`) **does not exist in
the corpus** and is not built here."* This file is that harness, plus the theorem that
makes building it worth more than the harness itself.

⭐ **THE RESULT: `runW (code.map encode) s = run code s`, for every program and every
initial state, with NO side condition.** So every `Instr`-level theorem about `run` in
this corpus is *already* a theorem about machine words — and it lifts by `rw`, at zero
kernel cost. The 128-instruction sort demo does not get re-executed as `BitVec 32`; the
simulation carries it.

## The three levels, and which one the silicon sees

| level | step | what it consumes | who speaks here |
|---|---|---|---|
| abstract | `step` | `Instr` | `SortDemo`, `ISA` |
| **machine word** | **`stepT`** | **`BitVec 32`** | **this file, and `decoder_correct`** |
| gates | `sem`/`stepSeq` | nets | `Decoder`, `SelectCut32` |

⇒ ***The middle row is where `Decoder.decoder`'s certificate already speaks*** —
`decoder_correct` is `∀ w, ctrlOf w = ctrlSpec w`, unconditional, over `BitVec 32`. The
abstract level could not meet it; this level can.

## 🔴 WHAT THIS FILE DOES **NOT** DO — read before quoting it

1. **It does not prove universal sortedness.** `SortDemo`'s fence item (1) is untouched:
   that needs a `LinearOrder (BitVec 32)` for the SIGNED order plus a network simulation,
   both Mathlib, both out of scope for leg 2. This file changes the *level* of the
   existing certificates, not their *quantifier*.
2. **It does not assemble a `core` `Circ`.** `docs/compiler-inventory-0808.md` §Q1 —
   still no assembled datapath. That is the other half of "the executive" and it is a
   construction, not a theorem.
3. ⚠️ **The simulation covers `code.map encode`, NOT an arbitrary word image.** An
   undecodable word does not fault — `stepT` falls back to `s.next` and **SKIPS** it. §4
   exhibits that boundary with a witness rather than leaving §2 to be read as more than
   it is.
4. **`run`'s fuel is `code.length`, and that is inherited, not fixed here.** It is a
   *sufficient* bound only because every emitted branch is forward. Both sides of the
   simulation use the same bound, so the theorem is indifferent to it — but a program
   with a backward branch would be under-run at BOTH levels equally.
   ⇒ ***§7 makes that concrete and it is not a remark: `loop_image_exits_with_work_pending`
   exhibits an image where the bound is INSUFFICIENT, and it names the B-EXEC driver
   question (an executive loops; a fairness invariant quantifies over INFINITE runs; a
   length-fuel driver cannot express one).*** *Added 21:0x — this fence had four items and
   did not know §7 existed.*

## THE ROWS THIS FILE CARRIES, BY NAME

⛔ **This block exists because math's `docstring_coverage.py` (salt) found that THIS HEADER
NAMED NOT ONE THEOREM — zero of 25.** Their taxonomy calls that class (2), *"describes a row
but does not name it — a usability gap, not a lie."*
⭐ **I think it is more than that, and my own file is the evidence: CLASS (2) IS WHAT MAKES
CLASS (1) POSSIBLE.** A header that names no row is tied to no row, so it can drift freely and
nothing — not the kernel, not a grep, not their tool — can notice. ***Naming the rows is what
makes a header CHECKABLE; the prose was never the point.***

| § | row | says |
|---|---|---|
| 2 | `runForW_step`, `runForW_stop` | the unroll/stop pair, so §3's induction never unfolds a `match`. *Named though they are helpers: to the tool a DELIBERATE omission and an accidental one are identical, so naming them turns a permanent ambiguous flag into a clean baseline where silence means something.* |
| 3 | `stepT_encode` | `stepT s (encode i) = step s i`, unconditional |
| 3 | `fetchW_map` | the image's fetch IS the source's fetch, encoded |
| 3 | `runForW_map` | the simulation at fixed fuel |
| 3 | ⭐ `runW_map` | **the simulation theorem**, ∀ code ∀ s, no side condition |
| 4 | `undecodable_skips`, `zero_word_is_undecodable` | an undecodable word SKIPS; one exists |
| 4 | `undecodable_image_is_not_encoded`, `witness_image_outside_simulation` | the boundary is inhabited |
| 5 | `demoRunW_eq`, `caseOKW_eq` | where the simulation is spent |
| 5 | `demo_output_exact_at_word_level`, `sort_sweep_at_word_level`, `compiler_check_all_at_word_level`, `compiler_check_both_boundaries_at_word_level`, `compiler_check_no_zero_at_word_level` | the lifts |
| 6 | `demo_image_length`, `demo_image_head` | the lift is not vacuous |
| 7 | `loopProg`, `loop_image_length` | a two-word forever-loop |
| 7 | ⛔ `loop_image_exits_with_work_pending`, `more_fuel_changes_the_answer` | fuel exhaustion leaves work pending, and the bound is insufficient there |
| 7 | ✅ `demo_exit_has_no_work_pending`, `demo_is_not_truncated` | the sort demo is in the safe regime — **the premise §5's lifts rest on** |
-/

namespace SaltWorks.Executive

open SaltWorks.ISA SaltWorks.SortDemo

/-! ## 1 · The harness — `fetch`/`runFor`/`run`, one level down

Each definition mirrors its `Instr`-level twin line for line, deliberately: the
simulation proof below is a structural induction, and any asymmetry between the two
would have to be paid for inside it. -/

/-- Word-level fetch. **Same byte-address convention as `ISA.fetch`** — a misaligned
`pc` fetches nothing rather than rounding down. -/
def fetchW (img : List (BitVec 32)) (pc : BitVec 32) : Option (BitVec 32) :=
  if pc.toNat % 4 = 0 then img[pc.toNat / 4]? else none

/-- Bounded word-level iteration. **Structural on a `Nat`**, for the same reason
`ISA.runFor` is: well-founded recursion would not reduce in the kernel, and the
certificate suites depend on kernel reduction.

⚠️ **Note the two distinct failure modes, which this shape keeps apart:** `fetchW`
returning `none` STOPS the machine (off the end, or misaligned), whereas a word that is
fetched but does not *decode* is handled inside `stepT`, which SKIPS it. Collapsing
those would silently make an undecodable word a halt. -/
def runForW : Nat → List (BitVec 32) → St → St
  | 0,     _,   s => s
  | n + 1, img, s =>
      match fetchW img s.pc with
      | none   => s
      | some w => runForW n img (stepT s w)

/-- Whole-image execution, with the image's own length as the bound — exactly as
`ISA.run` does with the program's. -/
def runW (img : List (BitVec 32)) (s : St) : St := runForW img.length img s

/-! ## 2 · The step and stop lemmas, mirroring `SortDemo`'s

These exist so the induction in §3 never unfolds a `match`. -/

theorem runForW_step (n : Nat) (img : List (BitVec 32)) (s : St) (w : BitVec 32)
    (h : fetchW img s.pc = some w) : runForW (n + 1) img s = runForW n img (stepT s w) := by
  show (match fetchW img s.pc with
        | none => s | some w => runForW n img (stepT s w)) = _
  rw [h]

theorem runForW_stop (n : Nat) (img : List (BitVec 32)) (s : St)
    (h : fetchW img s.pc = none) : runForW n img s = s := by
  cases n with
  | zero => rfl
  | succ m =>
    show (match fetchW img s.pc with
          | none => s | some w => runForW m img (stepT s w)) = _
    rw [h]

/-! ## 3 · THE BRIDGE, in three steps — step, fetch, then the whole run -/

/-- **Step agreement, unconditional.** The only fact about the encoder this file needs,
and it is a corollary of `decode_encode` rather than a new obligation: a word that came
from `encode` decodes back, so the total `stepT` never reaches its `s.next` fallback. -/
theorem stepT_encode (s : St) (i : Instr) : stepT s (encode i) = step s i := by
  unfold stepT stepW
  rw [decode_encode]
  rfl

/-- **Fetch agreement:** fetching the image is fetching the program, encoded. The
alignment side-condition is discharged once, on both sides at the same time — which is
the payoff for mirroring the convention rather than re-choosing it. -/
theorem fetchW_map (code : List Instr) (p : BitVec 32) :
    fetchW (code.map encode) p = (fetch code p).map encode := by
  unfold fetchW fetch
  by_cases h : p.toNat % 4 = 0
  · rw [if_pos h, if_pos h, List.getElem?_map]
  · rw [if_neg h, if_neg h]; rfl

/-- The simulation at fixed fuel. Induction on the fuel, generalizing the state — the
state changes on every step, so it cannot be fixed by the induction. -/
theorem runForW_map (n : Nat) (code : List Instr) (s : St) :
    runForW n (code.map encode) s = runFor n code s := by
  induction n generalizing s with
  | zero => rfl
  | succ m ih =>
    cases hf : fetch code s.pc with
    | none =>
      rw [runForW_stop _ _ _ (by rw [fetchW_map, hf]; rfl), runFor_stop _ _ _ hf]
    | some i =>
      rw [runForW_step _ _ _ (encode i) (by rw [fetchW_map, hf]; rfl),
          runFor_step _ _ _ i hf, stepT_encode, ih]

/-- ⭐ **THE SIMULATION THEOREM. Running the encoded program on machine words is running
the program.** `∀ code, ∀ s`, no side condition, no fuel parameter — the two `length`s
agree because `List.length_map` says so, which is why the bound needed no hypothesis. -/
theorem runW_map (code : List Instr) (s : St) : runW (code.map encode) s = run code s := by
  unfold runW run
  rw [List.length_map, runForW_map]

/-! ## 4 · THE BOUNDARY — what §3 does NOT cover, with a witness

⛔ **`runW_map` speaks only about images in the range of `map encode`.** Left there, a
reader could take §3 for "the word-level executive agrees with the abstract one", full
stop. It does not: an arbitrary image may contain words that decode to nothing, and those
are **skipped, not rejected**. -/

/-- An undecodable word advances the machine by one instruction and changes no register.
**This is `stepT`'s totality showing its price:** it cannot report failure, so it must
choose a behaviour, and the behaviour is a skip. -/
theorem undecodable_skips (s : St) (w : BitVec 32) (h : decode w = none) :
    stepT s w = s.next := by
  unfold stepT stepW
  rw [h]
  rfl

/-- A concrete undecodable word, so the boundary above is inhabited rather than
hypothetical. -/
theorem zero_word_is_undecodable : decode 0 = none := by decide

/-- ⭐ **And the boundary is REAL, not merely unproved:** an image containing an
undecodable word is not the encoding of any program whatsoever. So `runW_map` cannot be
extended to arbitrary images by any choice of `code` — the hypothesis is doing work. -/
theorem undecodable_image_is_not_encoded (img : List (BitVec 32)) (w : BitVec 32)
    (hw : w ∈ img) (h : decode w = none) : ∀ code : List Instr, img ≠ code.map encode := by
  intro code heq
  rw [heq] at hw
  obtain ⟨i, _, hi⟩ := List.mem_map.mp hw
  rw [← hi, decode_encode] at h
  exact Option.some_ne_none i h

/-- The witness assembled: a two-word image whose second word decodes to nothing is
outside the simulation's reach, for every program. -/
theorem witness_image_outside_simulation :
    ∀ code : List Instr, [encode (.ADDI 1 0 7), 0] ≠ code.map encode :=
  undecodable_image_is_not_encoded _ 0 (by simp) zero_word_is_undecodable

/-! ## 5 · THE LIFT — the sort demo, on machine words

⭐ **Every proof in this section is `rw [runW_map]` followed by the existing
`Instr`-level certificate.** The 128-instruction program is NOT re-executed as `BitVec
32` by the kernel: the simulation carries it, so the word-level demo costs one rewrite.
*That is the whole argument for proving a simulation instead of re-running a suite.* -/

/-- The word-level twin of `demoRun`: encode the program, then run the image. -/
def demoRunW (gen : Fin 32 → Fin 32 → Fin 32 → List Instr) (vals : List Int) : St :=
  runW ((progOf gen vals).map encode) St.init

/-- `demoRunW` and `demoRun` are the same state. The bridge, specialised once so the
certificates below are one-liners. -/
theorem demoRunW_eq (gen : Fin 32 → Fin 32 → Fin 32 → List Instr) (vals : List Int) :
    demoRunW gen vals = demoRun gen vals := by
  unfold demoRunW demoRun
  rw [runW_map]

/-- ⭐ **THE SORT DEMO, EXECUTED AS MACHINE WORDS.** The exact eight output words, from a
program the machine read as `BitVec 32`. -/
theorem demo_output_exact_at_word_level :
    outWords (demoRunW cexSeq [5, -3, 0, 7, -8, 2, 2, -1])
      = [-8, -3, -1, 0, 2, 2, 5, 7].map (BitVec.ofInt 32) := by
  rw [demoRunW_eq]
  exact demo_output_exact

/-! ⛔ **A DEFECT CAUGHT IN THIS FILE BEFORE IT LANDED, RECORDED RATHER THAN QUIETLY
FIXED.** The two sweep lifts below were first written as

```lean
theorem sort_sweep_at_word_level :
    sweepCases.all (fun c => caseOK c.1 c.2) = true := sort_sweep
```

— which is `sort_sweep` **under a new name**. `caseOK` is defined over `demoRun`, the
`Instr` level, so the statement says nothing about words while the *name* claims the
lift. ⭐ *A true theorem supporting a false headline: the nouns in the name have to
appear in the statement, and `demoRunW` did not.* The repair is a word-level `caseOKW`,
so the sweep predicates are over the word machine and the equality below is what does
the lifting. -/

/-- The word-level twin of `caseOK` — same three checks (exit `pc`, exact output words,
sortedness), run on the machine that consumed `BitVec 32`. -/
def caseOKW (vals expect : List Int) : Bool :=
  let s := demoRunW cexSeq vals
  (s.pc == 512) && (outWords s == expect.map (BitVec.ofInt 32)) && sortedAsc s

/-- `caseOKW` and `caseOK` agree — and *this* is where the simulation is spent. -/
theorem caseOKW_eq (vals expect : List Int) : caseOKW vals expect = caseOK vals expect := by
  unfold caseOKW caseOK
  rw [demoRunW_eq]

/-- The eight-fixture sweep, genuinely at word level: the predicate is `caseOKW`. -/
theorem sort_sweep_at_word_level :
    sweepCases.all (fun c => caseOKW c.1 c.2) = true := by
  simp only [caseOKW_eq]
  exact sort_sweep

/-- ⭐ **My five adversarial inputs at word level — and this one carries content the
output-only theorems do not:** `caseOKW` checks the exit `pc`, so the word-level machine
is certified to leave the program at the same address, not merely to compute the same
registers. -/
theorem compiler_check_all_at_word_level :
    compilerCases.all (fun c => caseOKW c.1 c.2) = true := by
  simp only [caseOKW_eq]
  exact compiler_check_all

/-- The ADDI-boundary case at word level, stated separately because the immediate is the
one field whose *encoding* could plausibly disagree with its abstract meaning — a
sign-extension defect in `encode`/`decode` would surface exactly here and nowhere else
in the suite. -/
theorem compiler_check_both_boundaries_at_word_level :
    outWords (demoRunW cexSeq [2047, -2048, 0, 2047, -1, 2046, 1, -2047])
      = [-2048, -2047, -1, 0, 1, 2046, 2047, 2047].map (BitVec.ofInt 32) := by
  rw [demoRunW_eq]
  exact compiler_check_both_boundaries

/-- The no-zero control at word level — the control on the READOUT survives the lift,
which matters because the lift changes what produced the registers. -/
theorem compiler_check_no_zero_at_word_level :
    outWords (demoRunW cexSeq [5, -4, 3, -2, 2, -3, 4, -5])
      = [-5, -4, -3, -2, 2, 3, 4, 5].map (BitVec.ofInt 32) := by
  rw [demoRunW_eq]
  exact compiler_check_no_zero_in_output

/-! ## 6 · A NEGATIVE CONTROL ON THE LIFT ITSELF

⚠️ **Every theorem in §5 would still typecheck if `demoRunW_eq` were vacuous** — say, if
`demoRunW` had been defined as `demoRun` outright. Then the section would prove nothing
about words at all while reading exactly the same. So: the word image is exhibited as a
real, distinct object. -/

/-- The demo program really is 128 machine words, and they really are `BitVec 32` — the
image is a different object from the instruction list, not an abbreviation for it. -/
theorem demo_image_length :
    ((progOf cexSeq [5, -3, 0, 7, -8, 2, 2, -1]).map encode).length = 128 := by
  rw [List.length_map]
  exact demoProg_length

/-- And the image's words are the encoder's actual output, checked against a hand-read
instruction: the first word of the demo image is `ADDI x1, x0, 5`. **If the lift were
vacuous this would not be about the image at all.** -/
theorem demo_image_head :
    ((progOf cexSeq [5, -3, 0, 7, -8, 2, 2, -1]).map encode).head?
      = some (encode (.ADDI 1 0 5)) := by
  decide +kernel

/-! ## 7 · ⛔ FUEL EXHAUSTION IS NOT A HALT — the boundary PROVED, not described

**Added 20:4x on math's independent statement audit of this file (20:43), and the finding
is theirs.** They observed that §1's docstring separates *undecodable-word* from *halt*
deliberately and precisely — *"collapsing those would silently make an undecodable word a
halt"* — and that **fuel-exhaustion-vs-halt is the same class, one line up, and I did not
separate it.** That is correct and it was an oversight, not a choice.

📌 The header fence's item 4 does state that `run`'s `code.length` fuel is a *sufficient*
bound only because every emitted branch is forward. ⚠️ **But it says so in the FENCE, not on
`runW` — where a reader of the definition would actually meet it — and it never names the
CONFLATION.** `runForW 0 _ s => s` returns the mid-run state through the same door a genuine
halt uses, so the two are indistinguishable at the type.

⭐ **So rather than add a sentence, the boundary is exhibited — the same treatment §4 gives
the undecodable word, which is the part of this file math could audit at all.** -/

/-- A two-word program that loops forever: increment `x1`, then branch back. `x0 = x0`
holds unconditionally (`St.get` reads `x0` as zero by the READ PORT), so the branch is
always taken. `bOffset (-2) = -4`, so `pc = 4` returns to `pc = 0`. -/
def loopProg : List Instr := [.ADDI 1 1 1, .BEQ 0 0 (BitVec.ofInt 12 (-2))]

theorem loop_image_length : (loopProg.map encode).length = 2 := by decide +kernel

/-- ⛔⛔ **THE WITNESS: `runW` STOPS WITH AN INSTRUCTION STILL FETCHABLE.** `runW`'s fuel is
the WORD COUNT, and a program's STEP COUNT is not bounded by its word count — `BEQ` makes
loops. So on this image the machine runs out of fuel at `pc = 0` with word 0 available.

⇒ ***A genuine halt is `fetchW img s.pc = none`. This state's fetch is `some`. The two exits
are therefore DISTINGUISHABLE FROM OUTSIDE even though `runForW` returns both as `s` —
which is exactly what makes this statable rather than merely regrettable.*** 

⚠️ **RENAMED 20:5x from `fuel_exhaustion_is_not_a_halt`.** That name stated a GENERAL
proposition; this statement is a **single witness** — for *this* loop image the exit has a
fetchable word. The general claim is the docstring's argument above, and it is sound, but a
one-image theorem should not carry it in its name. -/
theorem loop_image_exits_with_work_pending :
    fetchW (loopProg.map encode) (runW (loopProg.map encode) St.init).pc ≠ none := by
  decide +kernel

/-- And the bound is genuinely insufficient here, not merely tight: more fuel computes a
different answer. `x1` counts loop iterations, so the word-count fuel truncates it. -/
theorem more_fuel_changes_the_answer :
    (runForW 6 (loopProg.map encode) St.init).get 1
      ≠ (runForW 2 (loopProg.map encode) St.init).get 1 := by
  decide +kernel

/-- ✅ **THE SORT DEMO'S EXIT HAS NO WORK PENDING** — nothing is fetchable there. Together
with the witness above this puts the demo in the safe regime, and it is the row that
licenses §5's lifts.

⛔ **RENAMED 20:4x FROM `demo_halts_rather_than_exhausting_fuel`, BECAUSE THAT NAME OUTRAN
THIS STATEMENT — my own defect, three minutes after math corrected theirs.** The
discriminator is **ASYMMETRIC**, and the asymmetry matters:
```
fetchW = some at the exit  ⇒ DEFINITELY TRUNCATED. Airtight: had fuel remained, runForW
                             would have taken the step, so fuel must have hit 0 with work
                             pending.
fetchW = none at the exit  ⇒ no work remained, so the machine COMPLETED.
                             ⚠️ It does NOT rule out fuel hitting 0 at that same moment.
```
⇒ ***So this theorem proves "no work pending", NOT "did not exhaust fuel". Those coincide
in effect and not in content, and the old name asserted the second.*** The clean
not-truncated certificate is the next theorem. -/
theorem demo_exit_has_no_work_pending :
    fetchW ((progOf cexSeq [5, -3, 0, 7, -8, 2, 2, -1]).map encode)
      (demoRunW cexSeq [5, -3, 0, 7, -8, 2, 2, -1]).pc = none := by
  decide +kernel

/-- ⭐ **AND THE DIRECT REFUTATION OF TRUNCATION: MORE FUEL COMPUTES THE SAME ANSWER.**
`400` against the image's own `128`, on both the output words and the exit `pc`. This needs
no reasoning about `fetchW` at all — **it observes the fixpoint instead of arguing for
it** — and it is what actually licenses §5. -/
theorem demo_is_not_truncated :
    outWords (runForW 400 ((progOf cexSeq [5, -3, 0, 7, -8, 2, 2, -1]).map encode) St.init)
        = outWords (demoRunW cexSeq [5, -3, 0, 7, -8, 2, 2, -1])
      ∧ (runForW 400 ((progOf cexSeq [5, -3, 0, 7, -8, 2, 2, -1]).map encode) St.init).pc
        = (demoRunW cexSeq [5, -3, 0, 7, -8, 2, 2, -1]).pc :=
  ⟨by decide +kernel, by decide +kernel⟩

/-! ⇒ ***THE REGIME, STATED WHERE IT BELONGS: `runW` (and `ISA.run`) execute to completion
ONLY on images whose step count is bounded by their word count — straight-line and
forward-branching programs.*** For those, `fetchW … = none` at the exit certifies it, as
`demo_exit_has_no_work_pending` does for the sort demo — with
`demo_is_not_truncated` as the stronger, `fetchW`-free form.

🎯 **AND THE OPEN ROW, named because math's Slice-B slate will meet it from the other side:
an EXECUTIVE schedules in LOOPS and its fairness invariant quantifies over INFINITE runs. A
driver whose fuel is the image length cannot express an infinite run at all.** ⇒ ***B-EXEC
needs a different driver — a coinductive/step-indexed relation or an explicit fuel
parameter — and that is a DESIGN row, not a lemma. It should be decided before B-EXEC's
statements are drafted against a driver that cannot carry them.*** *Math's E-5 ("does an
infinite run exist?") and the language block's §5 fuel deferral are this same gap arriving
from two other directions.* -/

#audit_axioms loopProg
#audit_axioms loop_image_length
#audit_axioms loop_image_exits_with_work_pending
#audit_axioms more_fuel_changes_the_answer
#audit_axioms demo_exit_has_no_work_pending
#audit_axioms demo_is_not_truncated

#audit_axioms fetchW
#audit_axioms runForW
#audit_axioms runW
#audit_axioms runForW_step
#audit_axioms runForW_stop
#audit_axioms stepT_encode
#audit_axioms fetchW_map
#audit_axioms runForW_map
#audit_axioms runW_map
#audit_axioms undecodable_skips
#audit_axioms zero_word_is_undecodable
#audit_axioms undecodable_image_is_not_encoded
#audit_axioms witness_image_outside_simulation
#audit_axioms demoRunW
#audit_axioms demoRunW_eq
#audit_axioms demo_output_exact_at_word_level
#audit_axioms caseOKW
#audit_axioms caseOKW_eq
#audit_axioms sort_sweep_at_word_level
#audit_axioms compiler_check_all_at_word_level
#audit_axioms compiler_check_both_boundaries_at_word_level
#audit_axioms compiler_check_no_zero_at_word_level
#audit_axioms demo_image_length
#audit_axioms demo_image_head

end SaltWorks.Executive
