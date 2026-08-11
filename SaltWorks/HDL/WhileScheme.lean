import SaltWorks.HDL.IteScheme

/-! # THE `while` OFFSET SCHEME — PRE-REGISTERED, and the first BACKWARD branch in the corpus

⛔⛔ **HEADER CORRECTION, AND IT BELONGS AT THE TOP RATHER THAN 426 LINES DOWN — math's
first-refuter finding, 08-11 07:39, and they are right: the two sentences below were FALSE
from `a8582b8` onward, the correction lived only in §7, and A READER ARRIVES AT LINE 8, NOT
AT LINE 434. A header is the part of a file people read INSTEAD of the rest.**
*The clause IS written and `compileS` DOES emit `while`. See §7 for what that closed. The
original text stands below so anyone who quoted it lands here and not on a gap.*

> ~~L2's `while` clause is not written.~~ **This file publishes the offset formulas, the
> checks, the mutants and the pass/fail bar first**, exactly as `IteScheme` did for `ite`,
> per the house law that a criterion published before the work sometimes fixes the work.
> ~~It emits nothing and changes no `compileS` clause — `compileS` still returns `none` for
> `.while`.~~ *(That was true when this file was written and is the point of a
> pre-registration: it describes the world BEFORE the work.)*

## What is NEW here, and it is not "the same thing pointing the other way"

`ite`'s two displacements each skip a block and depend on **that block's length alone**.
`while` breaks both properties, and each break is a defect class `IteScheme`'s bar cannot
see:

```
 (N1) THE BACK BRANCH IS NEGATIVE     nothing in this corpus has ever emitted one. The
      landed evidence is a machine fact (beq_offset_can_be_negative, loopCode), never a
      COMPILED one.
 (N2) whileBack DEPENDS ON n_c        the condition block's length enters an offset. Every
      ite offset is a function of the block being skipped; this one is not, so an emitter
      that threads only "the block I am jumping over" is wrong in a way ite never punishes.
 (N3) A WRONG OFFSET CAN FAIL BY NON-TERMINATION rather than by a wrong value. TWO of §4's
      three mutants diverge, and one of them leaves the observed counter EXACTLY CORRECT.
      **A certificate that reads a register out of a fixed fuel budget reports a plausible
      number for a machine that never halts** — so §3 carries a HALT check, and
      `whileHalts` is the control that makes the rest of the row mean anything.
      *Measured, not anticipated: this file's first draft was refuted by the kernel and the
      second one found a defect in its own FIXTURE — see `condBlk`.*
```

## The layout, for a block starting at instruction index `p`

```
 p .. p+n_c-1            condition code, result in t0 (x10)
 p+n_c                   BEQ t0 x0 (whileExit n_b)      taken when the condition is FALSE
 p+n_c+1 .. p+n_c+n_b    BODY block
 p+n_c+n_b+1             BEQ x0 x0 (whileBack n_c n_b)  unconditional, BACKWARD to p
 p+n_c+n_b+2             end — the exit branch lands here
```

`bOffset imm = sext(imm) <<< 1`, measured **from the branch's own address**, so a
displacement is *half* the byte distance. Both formulas mention only block LENGTHS, so both
are position-independent and `compileS` still needs no position parameter — the property
`BlockCalc`'s `codeAt` exists to exploit. *`p` appears in the layout above and in neither
formula below; that is the claim, and §5 is where it is exercised against a real offset.*
-/

open SaltWorks.ISA
open SaltWorks.StraightLine

open SaltWorks.CompileS

namespace SaltWorks.WhileScheme

/-! ## 1. The formulas — ⚠️ THEY NOW LIVE AT THE EMITTER, AND THIS FILE TESTS *THOSE*

`whileExit`, `whileBack` and `whileFits` **moved into `SaltWorks/HDL/CompileS.lean`** when
the emitter was written. The move was FORCED — `WhileScheme → IteScheme → BlockCalc →
CompileS`, so the emitter cannot reference constants defined here without a cycle — and it
is the better placement anyway:

🔑 ***§7's bar, clause 1, demands that the emitted immediates be LITERALLY these functions
and not numbers that agree on a sample. With ONE definition serving both, that clause holds
BY CONSTRUCTION, and everything below — the six configurations, the three mutants, and §5b's
all-sizes landing theorems — now tests THE EMITTER'S OWN CONSTANTS instead of copies.***

⛔ *Defining them twice would have minted the mirror-constant hazard by my own hand, after
writing the guard for it. The cure for a mirror is not a second guard; it is not having a
second constant.* -/

/-! ## 2. ⛔ THE REPRESENTABILITY BOUND — AND IT IS ASYMMETRIC

`imm` is 12-bit signed: `[-2048, 2047]`. **The two directions do NOT get the same room**,
and the off-by-one in that asymmetry is the classic two's-complement trap.
*`whileFits` is the emitter's LOCAL check: forward `2*(n_b+2) ≤ 2047`, backward
`2*(n_c+n_b+1) ≤ 2048`.* -/

/-- ⭐ **THE ASYMMETRY IS REAL AND IT IS EXACTLY ONE STEP.** `-2048` is representable and
`+2048` is not, so a bound written symmetrically is wrong on one side. *Recorded as a
theorem because "12-bit signed" is the kind of fact everyone knows and half of everyone
off-by-ones.* -/
theorem imm_range_is_asymmetric :
    ((BitVec.ofInt 12 (-2048)).toInt == -2048) = true
  ∧ ((BitVec.ofInt 12 2048).toInt == 2048) = false := by
  refine ⟨by decide, by decide⟩

/-- …and the guard binds where the asymmetry says it should: the backward direction accepts
a loop the forward direction would refuse at the same size. -/
theorem whileFits_binds :
    whileFits 1 1021 = true ∧ whileFits 1 1022 = false ∧ whileFits 1023 0 = true := by
  refine ⟨by decide, by decide, by decide⟩

/-- **The bound is REAL, not notional.** One past the backward limit the immediate has
wrapped to a POSITIVE displacement — a backward branch that jumps forwards, i.e. a loop that
falls out of itself. *This is why the guard is a `≤` on the `Nat` and not a check on the
`BitVec`, which would be checking the symptom.* -/
theorem whileBack_wraps_past_the_bound :
    (whileBack 1024 0).msb = false ∧ (whileBack 1023 0).msb = true := by
  refine ⟨by decide, by decide⟩

/-! ### ⭐⭐ C5 — IS THE 2048/2047 ASYMMETRY **DERIVED** OR **ASSERTED**? — math's owed row

*Their criterion, run 08-11 07:39, left exactly one row without a verdict and named it rather
than dropping it: is `whileFits`'s asymmetry a fact about the encoding, or a number somebody
chose? **Compiler's own item 4 sharpened it: no certificate sat near either boundary, which
is precisely the condition under which an off-by-one in either direction passes everything.***

✅ **ANSWER: DERIVED, AND TIGHT ON BOTH SIDES — and the two sides fail in DIFFERENT WAYS.**
```
DERIVED  the bound is not asserted anywhere: it is the HYPOTHESIS §5b's landing
         theorems require. back_branch_lands needs 2*(n_c+n_b+1) ≤ 2048 to prove
         msb = true (via whileBack_msb) — one past, msb is false and the proof
         has no case. The number is what the arithmetic needs, not a choice.
TIGHT    below, at the exact last-accepted and first-rejected sizes.
```
⚠️ ***AND THE FAILURE MODES ARE NOT MIRROR IMAGES, which is why one bound is 2048 and the
other 2047: past the BACKWARD limit a back-edge becomes a FORWARD jump (the loop falls out of
itself); past the FORWARD limit an exit branch becomes a BACKWARD jump — an EXIT THAT RE-ENTERS,
i.e. non-termination. Same off-by-one, opposite catastrophes.*** -/

/-- The BACKWARD boundary, at the exact last-accepted and first-rejected sizes. -/
theorem whileBack_boundary_is_tight :
    whileFits 1023 0 = true ∧ (whileBack 1023 0).msb = true
  ∧ whileFits 1024 0 = false ∧ (whileBack 1024 0).msb = false := by
  refine ⟨by decide, by decide, by decide, by decide⟩

/-- ⭐ The FORWARD boundary — **and one past it the EXIT branch points BACKWARD**, so an
over-long body turns the loop's escape into a re-entry. *This is the mode `whileFits` exists
to refuse, and nothing in §3 or §4 sits close enough to see it.* -/
theorem whileExit_boundary_is_tight :
    whileFits 1 1021 = true ∧ (whileExit 1021).msb = false
  ∧ whileFits 1 1022 = false ∧ (whileExit 1022).msb = true := by
  refine ⟨by decide, by decide, by decide, by decide⟩

/-- …and the asymmetry is REAL rather than a rounding of one rule: at the size where the
BACKWARD direction is still legal, the FORWARD direction with the same magnitude is not. -/
theorem the_two_directions_differ_by_exactly_one :
    (2 * (1023 + 0 + 1) = 2048 ∧ 2 * (1021 + 2) = 2046)
  ∧ whileFits 1023 0 = true ∧ whileFits 1 1022 = false := by
  refine ⟨⟨by decide, by decide⟩, by decide, by decide⟩

-- whileExit / whileBack / whileFits are audited at their new home, in CompileS.lean
#audit_axioms imm_range_is_asymmetric
#audit_axioms whileFits_binds
#audit_axioms whileBack_wraps_past_the_bound
#audit_axioms whileBack_boundary_is_tight whileExit_boundary_is_tight
#audit_axioms the_two_directions_differ_by_exactly_one

/-! ## 3. THE CERTIFICATES — SIX CONFIGURATIONS, AND A HALT CHECK THAT CARRIES THE ROW

`whileBack` is a function of TWO lengths, so it needs its points spread in two directions:
`n_b ∈ {1,2,3}` at `n_c = 1`, and `n_c ∈ {1,2,3}` at `n_b = 1`, plus `(2,3)` to break the
"one of them is 1" coincidence every other row shares. *Three points per variable kills the
linear rivals in each direction; the off-diagonal row kills the ones that agree whenever a
length is 1.* -/

/-- The scheme's shape with both immediates left FREE, so a mutant differs from the real
thing in nothing but a number. -/
def whileBlock (condB : List Instr) (i1 i2 : BitVec 12) (bodyB : List Instr) : List Instr :=
  condB ++ (.BEQ 10 0 i1) :: (bodyB ++ [.BEQ 0 0 i2])

/-- The scheme with the DERIVED immediates. -/
def whileOf (condB bodyB : List Instr) : List Instr :=
  whileBlock condB (whileExit bodyB.length) (whileBack condB.length bodyB.length) bodyB

/-- A condition block of `n` instructions leaving the guard in `t0`. **Its FIRST instruction
is LOAD-BEARING**: it copies the live counter into the register the test reads, so a jump
that re-enters the block below its first instruction leaves a STALE guard operand.

⛔⛔ ***THIS IS THE SECOND VERSION AND THE FIRST ONE COST A BUILD — the lesson is worth more
than the block.*** My first condition block padded with inert writes (`.ADDI 4 0 50`) placed
BEFORE the test, chosen precisely so that padding could not disturb the guard. **The kernel
then refuted §4's off-by-one mutant: with the back offset one instruction short, the loop
re-enters at the test, skips only an instruction that does nothing, and computes THE RIGHT
ANSWER.** *I had built a condition block whose prefix was unobservable, and then asked a
mutant to be observed by skipping exactly that prefix.*

🔑 ***A MUTANT IS ONLY A MUTANT AGAINST A FIXTURE THAT CAN FEEL IT. The inertness I designed
for safety is the same property that made the defect invisible — and no amount of care about
the OFFSET would have found it, because the fault was in the FIXTURE.*** -/
def condBlk : Nat → List Instr
  | 0 => [.SLT 10 1 2]
  | 1 => [.SLT 10 1 2]
  | n+2 => (.ADD 5 1 0) ::
      ((List.range n).map (fun k => .ADDI 4 0 (BitVec.ofNat 12 (50 + k))) ++ [.SLT 10 5 2])

/-- A body of `n` instructions that increments the counter EXACTLY ONCE — the padding writes
a different register, so body length cannot change the iteration count. -/
def bodyBlk (n : Nat) : List Instr :=
  (.ADDI 1 1 1) :: (List.range (n - 1)).map (fun k => .ADDI 3 0 (BitVec.ofNat 12 (70 + k)))

/-- `x2 := 3`, then the loop. The prelude puts the loop at index 1, so **every certificate
below runs the scheme at a non-zero position** and the back branch's target is `p`, not `0`. -/
def loopImage (n_c n_b : Nat) : List Instr :=
  (.ADDI 2 0 3) :: whileOf (condBlk n_c) (bodyBlk n_b)

/-- ⭐⭐⭐ **HALTING IS OBSERVABLE AT ONE TICK.** Every instruction in this ISA changes `pc`
(`ADD`/`ADDI`/`XOR`/`SLT` and an untaken `BEQ` advance four; a taken `BEQ` moves by a
non-zero even displacement), so the machine is halted at tick `n` **iff** its `pc` is
unchanged at tick `n+1`. *This is the cheap decidable form of `fetch = none`, and it is the
control that (N3) demands: without it, a register read out of a fixed budget cannot tell a
finished loop from a spinning one.* -/
def whileHalts (image : List Instr) (n : Nat) : Bool :=
  (runFor n image St.init).pc == (runFor (n + 1) image St.init).pc

/-- ⭐⭐⭐ **SIX CONFIGURATIONS, ALL KERNEL-EXECUTED, EACH CARRYING ITS OWN HALT PROOF.**
The counter reaches the limit, the scratch registers show the blocks actually ran, the `pc`
lands exactly past the image, **and the machine is stationary there**. -/
theorem while_certificates :
    ([(1,1), (1,2), (1,3), (2,1), (3,1), (2,3)] : List (Nat × Nat)).all (fun cfg =>
      let n_c := cfg.1
      let n_b := cfg.2
      let img := loopImage n_c n_b
      let s   := runFor 64 img St.init
      (s.get 1 == 3) &&
      (s.pc == BitVec.ofNat 32 (4 * img.length)) &&
      whileHalts img 64) = true := by
  decide +kernel

/-- …and the row is not vacuously green: the loop **entered and ran**, so a scheme that
exited immediately could not produce it. `x5` is the condition block's load-bearing copy,
`x3` the body's padding write at `(2,3)`, `x4` the condition's padding write at `(3,1)` —
*read off the machine, not predicted: at `(2,3)` there is no condition padding and `x4` is
`0`, which is why this theorem names two configurations instead of one.* -/
theorem while_certificate_is_load_bearing :
    let s := runFor 64 (loopImage 2 3) St.init
    let t := runFor 64 (loopImage 3 1) St.init
    (s.get 1 == 3, s.get 3 == 71, s.get 5 == 3, t.get 4 == 50, t.get 5 == 3)
      = (true, true, true, true, true) := by
  decide +kernel

/-- **AND THE COUNTER IS NOT A CONSTANT** — at a different limit the same scheme answers
differently, so `x1 = 3` above is the loop's work and not the prelude's. -/
theorem while_counter_tracks_the_limit :
    ((runFor 64 ((.ADDI 2 0 5) :: whileOf (condBlk 1) (bodyBlk 1)) St.init).get 1 == 5)
      = true := by
  decide +kernel

#audit_axioms whileBlock whileOf condBlk bodyBlk loopImage whileHalts
#audit_axioms while_certificates
#audit_axioms while_certificate_is_load_bearing
#audit_axioms while_counter_tracks_the_limit

/-! ## 4. THE MUTANTS — same shape, ONE number different

*Run at `(n_c, n_b) = (2,3)`, the off-diagonal configuration, where every rival differs from
the derived value in both formulas.* -/

/-- **RIVAL `whileBack = -(2*(n_c+n_b))`, the off-by-one.** Lands one instruction INTO the
condition block, so the block's load-bearing first instruction is skipped on every iteration
after the first: the guard operand `x5` freezes at its initial value, the test stays true,
and **the loop diverges** — at fuel 64 the counter has run away to 10.

⚠️ ***AND THE HALT CLAUSE IS THE ONLY FUEL-ROBUST HALF OF THIS ROW.*** *A diverging counter
passes through every value on its way up, including the correct one — so `get 1 == 3` is
`false` HERE because 64 is where I stopped, and at some smaller fuel it would read `true`.*
**`whileHalts` does not have that defect: divergence is a property of the machine, not of
the budget.** *Recorded because the same trap is one line away in any future fixture that
checks a register against an expected value out of a fixed budget.* -/
theorem backOffByOne_diverges_on_a_stale_guard :
    let img := (.ADDI 2 0 3) :: whileBlock (condBlk 2) (whileExit 3)
                 (BitVec.ofInt 12 (-(2 * (2 + 3) : Int))) (bodyBlk 3)
    ((runFor 64 img St.init).get 1 == 3, whileHalts img 64) = (false, false) := by
  decide +kernel

/-- ⭐⭐ **RIVAL `whileBack = +(2*(n_c+n_b+1))`, THE SIGN ERROR — the likeliest mistake in the
corpus's first backward branch, and it fails LOUDLY only because someone checks the counter.**
The magnitude is right and only the direction is wrong: the "loop" runs its body once and
jumps forward out of the program. -/
theorem backSignError_runs_the_body_once :
    let img := (.ADDI 2 0 3) :: whileBlock (condBlk 2) (whileExit 3)
                 (BitVec.ofNat 12 (2 * (2 + 3 + 1))) (bodyBlk 3)
    ((runFor 64 img St.init).get 1 == 1) = true := by decide +kernel

/-- ⭐⭐⭐ **RIVAL `whileExit = 2*(n_b+1)` — THE ONE TO KEEP IF ONLY ONE COULD BE KEPT, and it
is a different KIND of failure from anything `ite` produces.** The exit branch lands ON the
backward branch instead of past it, so taking the exit immediately jumps back to the
condition: **the loop never terminates.** `x1` is still exactly 3 — *the value a register
check would read is CORRECT* — and the machine is still running.

🔑 ***THIS IS (N3), EXECUTED: the observable is right and the program is broken. Only the
halt check separates them, which is why `whileHalts` is a clause of the bar and not a
nicety.*** -/
theorem exitShort_never_terminates :
    let img := (.ADDI 2 0 3) :: whileBlock (condBlk 2) (BitVec.ofNat 12 (2 * (3 + 1)))
                 (whileBack 2 3) (bodyBlk 3)
    ((runFor 64 img St.init).get 1 == 3, whileHalts img 64) = (true, false) := by
  decide +kernel

#audit_axioms backOffByOne_diverges_on_a_stale_guard
#audit_axioms backSignError_runs_the_body_once
#audit_axioms exitShort_never_terminates

/-! ## 5. POSITION-INDEPENDENCE, EXERCISED AGAINST A REAL BACKWARD OFFSET

`BlockCalc` §5 exercised relocation on straight-line code and said plainly that the
branch-displacement property was NOT thereby paid for, and that the control belonged with
the emitter. **This is that control for the backward direction**: the same loop, moved by
three instructions, computes the same answer and halts — with no immediate changed. -/

/-- ⭐⭐ **THE LOOP IS POSITION-INDEPENDENT.** `prefixJunk` shifts every address by three
instructions; the back branch still lands on its condition block, because its displacement
was never a function of position. *This is the property that lets `compileS` keep no position
parameter, exercised for the first time on a branch rather than on a fold.* -/
theorem loop_relocates :
    let img  := loopImage 2 3
    let img' := SaltWorks.BlockCalc.prefixJunk ++ img
    ((runFor 64 img St.init).get 1 == (runFor 64 img' St.init).get 1,
     whileHalts img' 64) = (true, true) := by
  decide +kernel

#audit_axioms loop_relocates

/-! ## 5b. ⭐⭐⭐ THE OFFSETS, PROVED FOR **ALL** BLOCK SIZES — the six configurations are a
SAMPLE, and this is the theorem they were sampling

§7's caveat said plainly that three points per formula are *"a discriminating test, not a
proof"*, and named the obligation: **a theorem about `bOffset`**. Here it is, in both
directions, for every block size inside the representability bound.

🔑 ***THE BACKWARD DIRECTION IS THE ONE THAT NEEDED PROVING.*** *A negative immediate reaches
its target by WRAPPING: the displacement's `toNat` is `2^32 - 4*(n_c+n_b+1)`, and the landing
is `(pc + that) mod 2^32`. **The loop closes because the arithmetic overflows, and no sample
can show that it does so for every size.*** -/

/-- The negative immediate, as a `Nat`: two's complement of the byte-halved distance. -/
theorem whileBack_toNat (n_c n_b : Nat) (hk : 2 * (n_c + n_b + 1) ≤ 2048) :
    (whileBack n_c n_b).toNat = 2 ^ 12 - 2 * (n_c + n_b + 1) := by
  unfold whileBack
  rw [BitVec.toNat_ofInt]
  omega

theorem whileBack_msb (n_c n_b : Nat) (hk : 2 * (n_c + n_b + 1) ≤ 2048) :
    (whileBack n_c n_b).msb = true := by
  have h : ¬ ((whileBack n_c n_b).msb = false) := by
    rw [BitVec.msb_eq_false_iff_two_mul_lt, whileBack_toNat n_c n_b hk]
    omega
  simpa using h

/-- ⭐⭐ **THE EXIT BRANCH LANDS PAST THE LOOP, FOR EVERY BODY SIZE.** From the branch's own
address at block-relative index `n_c`, taking it puts the `pc` exactly one instruction past
the backward branch — the first instruction after the loop. -/
theorem exit_branch_lands {pc : BitVec 32} (n_b q : Nat)
    (hb : 2 * (n_b + 2) ≤ 2047) (hq : pc.toNat = 4 * q)
    (hp : 4 * (q + n_b + 2) < 2 ^ 32) :
    (pc + bOffset (whileExit n_b)).toNat = 4 * (q + n_b + 2) := by
  have hmsb : (whileExit n_b).msb = false := by
    unfold whileExit
    rw [BitVec.msb_eq_false_iff_two_mul_lt, BitVec.toNat_ofNat]
    omega
  unfold bOffset
  rw [BitVec.toNat_add, BitVec.toNat_shiftLeft,
      BitVec.signExtend_eq_setWidth_of_msb_false hmsb, BitVec.toNat_setWidth, hq]
  unfold whileExit
  rw [BitVec.toNat_ofNat]
  omega

/-- ⭐⭐⭐ **THE BACKWARD BRANCH LANDS ON THE CONDITION'S FIRST INSTRUCTION, FOR EVERY PAIR OF
BLOCK SIZES — AND IT GETS THERE BY WRAPPING.** From its own address at block-relative index
`n_c+n_b+1`, the loop closes onto index `0` of the block.

*`2^32 - 4*(n_c+n_b+1)` is added, not subtracted; the `mod` in `BitVec.toNat_add` is doing
the work. **This is the first COMPILED backward branch in this corpus, and this corpus's
first proof that one lands where it is aimed.***

⚖️ *Scope made explicit 08-11 under the ratified claim-language law: the original read "…in
the corpus and the first proof that one lands where it is aimed", where the scope attached to
the first conjunct and a reader could take the second as a claim about the world. **It is a
claim about THIS repository and nothing wider — I have surveyed no other.*** -/
theorem back_branch_lands {pc : BitVec 32} (n_c n_b q : Nat)
    (hk : 2 * (n_c + n_b + 1) ≤ 2048) (hq : pc.toNat = 4 * (q + n_c + n_b + 1))
    (hp : 4 * (q + n_c + n_b + 1) < 2 ^ 32) :
    (pc + bOffset (whileBack n_c n_b)).toNat = 4 * q := by
  unfold bOffset
  rw [BitVec.toNat_add, BitVec.toNat_shiftLeft, BitVec.toNat_signExtend,
      if_pos (whileBack_msb n_c n_b hk), BitVec.toNat_setWidth,
      whileBack_toNat n_c n_b hk, hq]
  omega

/-- ⭐⭐ **AND AT THE `step` LEVEL, WHICH IS WHAT THE EMITTER'S PROOF WILL CONSUME.** The exit
branch is taken exactly when the guard register holds zero — the condition being FALSE — and
`x0` reads zero unconditionally, so no hypothesis about the register file is needed. -/
theorem step_exit_taken {st : St} {rd : Fin 32} (n_b q : Nat)
    (hz : st.get rd = 0) (hb : 2 * (n_b + 2) ≤ 2047) (hq : st.pc.toNat = 4 * q)
    (hp : 4 * (q + n_b + 2) < 2 ^ 32) :
    (step st (.BEQ rd 0 (whileExit n_b))).pc.toNat = 4 * (q + n_b + 2) := by
  have h0 : st.get 0 = 0 := by simp [St.get]
  simp only [step, hz, h0, if_pos rfl]
  exact exit_branch_lands n_b q hb hq hp

/-- …and the backward branch is UNCONDITIONAL (`BEQ x0 x0`), so it needs no guard at all. -/
theorem step_back_taken {st : St} (n_c n_b q : Nat)
    (hk : 2 * (n_c + n_b + 1) ≤ 2048) (hq : st.pc.toNat = 4 * (q + n_c + n_b + 1))
    (hp : 4 * (q + n_c + n_b + 1) < 2 ^ 32) :
    (step st (.BEQ 0 0 (whileBack n_c n_b))).pc.toNat = 4 * q := by
  simp only [step, if_pos rfl]
  exact back_branch_lands n_c n_b q hk hq hp

#audit_axioms whileBack_toNat whileBack_msb
#audit_axioms exit_branch_lands back_branch_lands
#audit_axioms step_exit_taken step_back_taken

/-! ## 6. WHY `whileExit` IS NOT `iteThenSkip`, THOUGH THEY ARE EQUAL TODAY

`whileExit n = iteThenSkip n` **as functions**, and it is deliberate that this file defines
its own rather than citing the `ite` one. The two are equal by COINCIDENCE OF LAYOUT — both
skip a block plus one trailing branch — and they answer to different owners: `iteThenSkip`
is pinned by `IteScheme`'s bar to the ite layout, `whileExit` by this file's bar to the loop
layout. *A later change to either layout (an epilogue instruction, a different branch
polarity) must be free to move one without silently moving the other.*

⚠️ **The equality is recorded as a theorem rather than left implicit, so that if it ever
becomes false the change is visible instead of merely absent.** -/
theorem whileExit_agrees_with_iteThenSkip_today :
    ([0,1,2,3,7,1021] : List Nat).all
      (fun n => whileExit n == SaltWorks.IteScheme.iteThenSkip n) = true := by
  decide

#audit_axioms whileExit_agrees_with_iteThenSkip_today

/-! ## 7. THE PASS/FAIL BAR, PRE-REGISTERED

When L2's `while` clause lands, it passes only if **all** of these hold:

1. its emitted immediates are literally `whileExit n_b` and `whileBack n_c n_b` — *not
   numbers that happen to agree on some sample*;
2. §3's six configurations still pass **against generated code**, not against `whileOf`,
   **and each still carries its halt check**;
3. the §4 mutants still fail, each in its own recorded way — the sign error by HALTING with
   the wrong count, the other two by DIVERGING — and `exitShort` still fails ONLY on the
   halt clause, which is the clause that proves the bar can see (N3). ⚠️ **A mutant that
   fails on the counter alone is not evidence the bar works: for a diverging machine the
   counter reading is an artifact of the fuel budget** (see the off-by-one's note);
4. `whileFits` is checked by the emitter with its ASYMMETRIC bound, and an over-long loop
   returns `none` — the same fourth rejection cause `IteScheme` named, now with a second
   direction that has one more code point than the first;
5. the top-level statement is `Reaches`-shaped, never `run`-shaped (`BlockCalc` §6:
   `run` has too little fuel for a loop). **For `while` this is not a style rule — `run`
   cannot express a terminating loop at all**;
6. `ISA.lean`'s `run` docstring, which today asserts *every branch the code generator emits
   is forward*, is corrected IN THE SAME COMMIT as the emitter. **That sentence is true
   until the `while` clause lands and false the moment it does** — it sits under a true
   theorem, which is the shape a green build cannot catch.

✅ **UPDATED WHEN §5b LANDED — AND THE OLD TEXT WAS ROTTING IN THE SAFE-LOOKING DIRECTION.**
*This section said the file "does NOT establish that the formulas are correct for all block
sizes". **§5b now proves exactly that**, in both directions, for every size inside the
representability bound (`exit_branch_lands`, `back_branch_lands`, and their `step`-level
corollaries). A caveat that has been discharged reads as caution and is nobody's job to
re-check, so it is corrected in the commit that discharged it rather than left to be
believed.*

✅✅ **ALL THREE ITEMS BELOW WERE CLOSED BY `a8582b8` (the emitter + `WhileSim`), AND THIS
BLOCK WAS LEFT READING AS THREE LIVE GAPS FOR SEVERAL HOURS AFTER THEY DIED.**

⚠️ ***THE DEFECT IN THE PROSE IS WORTH MORE THAN THE ITEMS: THIS IS A FILE-SCOPED CAVEAT
PHRASED AS A CORPUS-WIDE GAP.*** *Every sentence is TRUE OF THIS FILE — `WhileScheme`'s
certificates do run straight-line bodies and this file emits nothing. But "what is STILL not
established" is a claim about THE CORPUS, and another file closed all three.* **A caveat rots
in the SAFE-LOOKING direction: it reads as caution, nobody re-reads it, and the next refuter
spends their pass on three phantom gaps.** *Corrected in the same commit that measured the
first one.*

1. ~~**A loop whose body itself contains control flow.**~~ ✅ **CLOSED — AND IT WAS ALREADY
   IN SCOPE, WHICH I HAD MISSED IN MY OWN THEOREM.** *`reaches_of_compileS_including_while`
   inducts on the `bigStep` DERIVATION and its `whileT` case takes `cb` from `compileS` of an
   ARBITRARY body, reasoning from `cb.length` without ever asking what produced that block.*
   **So the LAYOUT for nested loops is PROVED, not merely plausible** — `nested_loops_compile_
   and_run` and `letmut_in_loop_body_compiles_and_runs` (`WhileSim`) are CONFIRMATIONS of the
   theorem, not extensions of it. *I had written that the arithmetic "should survive" and the
   layout was "untested"; the layout was the half already covered.*
2. ~~**That the emitter emits this scheme at all.**~~ ✅ **CLOSED — `compileS_while_eq` is
   the forward equation and its immediates ARE `whileExit`/`whileBack`, so bar clause 1 holds
   by construction rather than by inspection.** *Originally: §5b proves where these land;
   it says nothing about which immediates `compileS` chooses. *That is bar clause 1, and it
   is discharged by the emitter's own forward equation, not here.*
3. ~~**The simulation relation across the loop.**~~ ✅ **CLOSED — it IS
   `reaches_of_compileS_including_while`, and it was the last real risk in this rung.**

⚖️ **THE HEADER OF THIS FILE ALSO STILL SAYS "L2's `while` clause is not written" AND
"`compileS` still returns `none` for `.while`". BOTH FALSE SINCE `a8582b8`** — left standing
with this correction attached rather than silently rewritten, because a reader who quoted
either sentence needs to find THIS and not a gap. *A pre-registration file describes the
world before the work; the moment the work lands, its present tense is a lie in the
flattering direction.*
-/

end SaltWorks.WhileScheme
