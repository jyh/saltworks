/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.WhileScheme
import SaltWorks.HDL.IteScheme

/-!
# COMPREHENSIBILITY CERTIFICATE — the control-flow offset schemes (`while` / `ite`)

Campaign: `docs/cert-layer-design-0811.md` (the fifth deliverable).
Landed by the **COMPILER seat**.

| certificate | proved from | in |
| --- | --- | --- |
| `cert_exit_branch_lands` | `exit_branch_lands` | `HDL/WhileScheme.lean` |
| `cert_back_branch_lands` | `back_branch_lands` | `HDL/WhileScheme.lean` |
| `cert_exit_branch_lands_at_the_machine` | `step_exit_taken` | `HDL/WhileScheme.lean` |
| `cert_back_branch_lands_at_the_machine` | `step_back_taken` | `HDL/WhileScheme.lean` |
| `cert_the_bound_is_tight_on_both_sides` | `whileBack_boundary_is_tight` / `whileExit_boundary_is_tight` | `HDL/WhileScheme.lean` |
| `cert_the_two_directions_differ_by_one` | `the_two_directions_differ_by_exactly_one` | `HDL/WhileScheme.lean` |
| `cert_while_scheme_runs` | `while_certificates` | `HDL/WhileScheme.lean` |
| `cert_ite_scheme_runs` | `ite_certificates` | `HDL/IteScheme.lean` |
| `cert_a_wrong_backward_offset_never_terminates` | `exitShort_never_terminates` | `HDL/WhileScheme.lean` |
| `cert_a_wrong_ite_offset_keeps_the_right_value` | `shortJump_falls_into_the_else_tail` | `HDL/IteScheme.lean` |

## ⛔⛔ READ THIS BEFORE THE TABLE: **THE `ite` HALF IS PROVED AND NOT WIRED**

A reader who sees *"the while/ite scheme correctness pair is certified"* will reasonably
conclude the compiler handles conditionals. **It does not.**

```
while   scheme proved  ✅   AND EMITTED by compileS   ✅
ite     scheme proved  ✅   ⛔ NOT EMITTED — compileS returns `none` on every `ite`
```
*`Certs/Compiler.lean`'s `cert_the_fragment_boundary` is the kernel-executed proof of
that refusal.* **So this file certifies that the `ite` OFFSET ARITHMETIC is right, and
certifies nothing about a compiler path that does not exist.** *The formulas are
correct and waiting; the wire is missing. Both halves of that sentence are load-bearing
and neither implies the other.*

## WHAT THE `while` SCHEME'S CORRECTNESS MEANS

A compiled loop is four things laid end to end: the condition's code, a branch that
**leaves** the loop when the condition is false, the body's code, and a branch that
goes **back** to the start. Each branch carries a number — how far to jump — and those
numbers are computed by a formula from the block sizes.

**The two landing certificates say the formulas are right for EVERY block size, not
for the sizes someone tried:**
* `cert_exit_branch_lands` — taking the exit branch puts the `pc` exactly one
  instruction past the backward branch: the first instruction after the loop.
* `cert_back_branch_lands` — taking the backward branch puts the `pc` exactly on the
  condition's first instruction. *It gets there by WRAPPING — `2^32 − 4·(…)` is added,
  not subtracted — which is why it needed a proof rather than an inspection.*

## ⭐ THE BOUND IS ASYMMETRIC, AND THE ASYMMETRY IS DERIVED RATHER THAN CHOSEN

The offsets are 12-bit signed, so `−2048` is representable and `+2048` is not. **The
guard is therefore not symmetric, and the two sides fail in different ways** — which is
why one bound is `2048` and the other `2047`:

```
past the BACKWARD limit  a back-edge becomes a FORWARD jump — the loop falls out of itself
past the FORWARD limit   an exit branch becomes a BACKWARD jump — AN EXIT THAT RE-ENTERS
```
*Same off-by-one, opposite catastrophes.* **The number is not a choice: it is the
hypothesis the landing proofs require** — one past it, the sign bit flips and the proof
has no case. `cert_the_bound_is_tight_on_both_sides` pins the exact last-accepted and
first-rejected sizes on each side, and `cert_the_two_directions_differ_by_one` shows a
size the backward direction accepts and the forward direction refuses.

## ⚠️ SCOPE LIMITS

* **These are the OFFSETS, not the emitter.** The `while` emitter's own correctness is
  `reaches_of_compileS_including_while`, certified in `Certs/Compiler.lean`. *This file
  is about the arithmetic those proofs consume.*
* **`cert_while_scheme_runs` / `cert_ite_scheme_runs` are FINITE**: six loop
  configurations and four conditional configurations, kernel-executed. *They are
  non-vacuity evidence — the schemes really run and halt where predicted — not
  universal claims. The universal claims are the two landing certificates.*
* **The mutants are two of several landed.** *`Certs/ControlFlow` keeps the two that
  matter most: in each, **the observable value is CORRECT and the program is BROKEN**.*

## DIRECTION (iron rule 3)

Every certificate here is the **same proposition** as its landed theorem (or the
conjunction of two), closing by `exact`. Nothing is generalised and nothing is weakened.

## AXIOMS (iron rule 4)

Measured at the landing of this file, from the `#print axioms` block below:

```
cert_exit_branch_lands                        [propext, Classical.choice, Quot.sound]
cert_back_branch_lands                        [propext, Classical.choice, Quot.sound]
cert_exit_branch_lands_at_the_machine         [propext, Classical.choice, Quot.sound]
cert_back_branch_lands_at_the_machine         [propext, Classical.choice, Quot.sound]
cert_the_bound_is_tight_on_both_sides         [propext]
cert_the_two_directions_differ_by_one          depends on no axioms at all
cert_while_scheme_runs                        [propext, Quot.sound]
cert_ite_scheme_runs                          [propext, Quot.sound]
cert_a_wrong_backward_offset_never_terminates [propext, Quot.sound]
cert_a_wrong_ite_offset_keeps_the_right_value [propext, Quot.sound]
```

No `sorryAx`, no corpus-local axiom; six of the ten are stronger than the campaign's
bar, and one depends on nothing at all.
-/

namespace SaltWorks.Certs

-- ⚠️ `whileExit` / `whileBack` / `whileFits` live at the EMITTER (`CompileS`), not in
-- `WhileScheme` — forced by an import cycle, and the reason the scheme files are
-- CONSUMERS of the emitter rather than the other way round.
open SaltWorks.ISA SaltWorks.CompileS SaltWorks.WhileScheme SaltWorks.IteScheme

/-! ## 1. THE OFFSETS LAND — for every block size, not for the sizes someone tried -/

/-- ⭐⭐ **THE EXIT BRANCH LANDS PAST THE LOOP, AT EVERY BODY SIZE.** From the branch's
own address, taking it puts the `pc` exactly one instruction past the backward branch.

Direction: **same proposition** as `SaltWorks.WhileScheme.exit_branch_lands`. -/
theorem cert_exit_branch_lands {pc : BitVec 32} (n_b q : Nat)
    (hb : 2 * (n_b + 2) ≤ 2047) (hq : pc.toNat = 4 * q)
    (hp : 4 * (q + n_b + 2) < 2 ^ 32) :
    (pc + bOffset (whileExit n_b)).toNat = 4 * (q + n_b + 2) :=
  exit_branch_lands n_b q hb hq hp

/-- ⭐⭐⭐ **THE BACKWARD BRANCH LANDS ON THE CONDITION'S FIRST INSTRUCTION, AT EVERY
PAIR OF BLOCK SIZES — AND IT GETS THERE BY WRAPPING.** `2^32 − 4·(n_c+n_b+1)` is
**added**, not subtracted; the modular arithmetic is doing the work.

*That is why a backward branch needs a proof and not an inspection.*

Direction: **same proposition** as `SaltWorks.WhileScheme.back_branch_lands`. -/
theorem cert_back_branch_lands {pc : BitVec 32} (n_c n_b q : Nat)
    (hk : 2 * (n_c + n_b + 1) ≤ 2048) (hq : pc.toNat = 4 * (q + n_c + n_b + 1))
    (hp : 4 * (q + n_c + n_b + 1) < 2 ^ 32) :
    (pc + bOffset (whileBack n_c n_b)).toNat = 4 * q :=
  back_branch_lands n_c n_b q hk hq hp

/-- ⭐⭐ **AND AT THE MACHINE'S OWN `step`, which is what an emitter's proof consumes.**
The exit branch is taken exactly when the guard register holds zero — the condition
being false — and the backward branch is unconditional (`BEQ x0 x0`), so it needs no
guard at all.

⛔⛔ **THESE ARE TWO CERTIFICATES AND NOT ONE, AND THAT IS THE POINT.** *My first draft
stated them as a single conjunction over one machine state — which required
`st.pc.toNat = 4*q` **and** `st.pc.toNat = 4*(q+n_c+n_b+1)` simultaneously. Those are
contradictory in `ℕ` (they force `n_c+n_b+1 = 0`), so the conjunction was **VACUOUSLY
TRUE**: it built green, audited clean, and said nothing.* **The two branches sit at
DIFFERENT addresses in the image — that is what makes them a loop — so no single `st`
can satisfy both hypotheses.**

Direction: **same proposition** as `step_exit_taken` / `step_back_taken` respectively. -/
theorem cert_exit_branch_lands_at_the_machine {st : St} {rd : Fin 32} (n_b q : Nat)
    (hz : st.get rd = 0) (hb : 2 * (n_b + 2) ≤ 2047) (hq : st.pc.toNat = 4 * q)
    (hp : 4 * (q + n_b + 2) < 2 ^ 32) :
    (step st (.BEQ rd 0 (whileExit n_b))).pc.toNat = 4 * (q + n_b + 2) :=
  step_exit_taken n_b q hz hb hq hp

/-- …and the backward branch, **from its own address** at block-relative index
`n_c+n_b+1`. Unconditional (`BEQ x0 x0`), so it needs no guard at all. -/
theorem cert_back_branch_lands_at_the_machine {st : St} (n_c n_b q : Nat)
    (hk : 2 * (n_c + n_b + 1) ≤ 2048)
    (hq : st.pc.toNat = 4 * (q + n_c + n_b + 1))
    (hp : 4 * (q + n_c + n_b + 1) < 2 ^ 32) :
    (step st (.BEQ 0 0 (whileBack n_c n_b))).pc.toNat = 4 * q :=
  step_back_taken n_c n_b q hk hq hp

/-! ## 2. THE BOUND — asymmetric, tight on both sides, and DERIVED -/

/-- ⭐ **THE LAST SIZE THAT WORKS AND THE FIRST THAT DOES NOT, ON BOTH SIDES.**
Backward: `1023` blocks is accepted and its offset is genuinely negative; `1024` is
refused and its offset has **wrapped positive** — a loop that falls out of itself.
Forward: `1021` is accepted and its offset is positive; `1022` is refused and has
wrapped **negative** — an exit that re-enters.

*Neither bound is asserted anywhere; each is the hypothesis the landing proofs above
require, and one past it the sign bit flips and the proof has no case.*

Direction: **the conjunction of** `whileBack_boundary_is_tight` **and**
`whileExit_boundary_is_tight`. -/
theorem cert_the_bound_is_tight_on_both_sides :
    (whileFits 1023 0 = true ∧ (whileBack 1023 0).msb = true
      ∧ whileFits 1024 0 = false ∧ (whileBack 1024 0).msb = false)
  ∧ (whileFits 1 1021 = true ∧ (whileExit 1021).msb = false
      ∧ whileFits 1 1022 = false ∧ (whileExit 1022).msb = true) :=
  ⟨whileBack_boundary_is_tight, whileExit_boundary_is_tight⟩

/-- ⭐ **AND THE ASYMMETRY IS REAL, NOT A ROUNDING OF ONE RULE**: at a size the BACKWARD
direction still accepts, the FORWARD direction with the same magnitude is refused.

Direction: **same proposition** as `the_two_directions_differ_by_exactly_one`. -/
theorem cert_the_two_directions_differ_by_one :
    (2 * (1023 + 0 + 1) = 2048 ∧ 2 * (1021 + 2) = 2046)
  ∧ whileFits 1023 0 = true ∧ whileFits 1 1022 = false :=
  the_two_directions_differ_by_exactly_one

/-! ## 3. THE SCHEMES REALLY RUN — finite, kernel-executed, halting -/

/-- **SIX LOOP CONFIGURATIONS, EACH CARRYING ITS OWN HALT PROOF.** The counter reaches
the limit, the `pc` lands exactly past the image, **and the machine is stationary
there** — the last clause is what distinguishes a loop that finished from one still
running.

⚠️ *Finite: this is non-vacuity evidence, not a universal claim. The universal claims
are §1.* Direction: **same proposition** as `while_certificates`. -/
theorem cert_while_scheme_runs :
    ([(1,1), (1,2), (1,3), (2,1), (3,1), (2,3)] : List (Nat × Nat)).all (fun cfg =>
      let n_c := cfg.1
      let n_b := cfg.2
      let img := loopImage n_c n_b
      let s   := runFor 64 img St.init
      (s.get 1 == 3) &&
      (s.pc == BitVec.ofNat 32 (4 * img.length)) &&
      whileHalts img 64) = true :=
  while_certificates

/-- **FOUR CONDITIONAL CONFIGURATIONS, BOTH BRANCHES EACH.** The taken side writes its
value and the other side stays zero, and both paths land on the same `pc` past the
whole conditional.

⛔ ***AND THIS IS THE ROW THE SCOPE WARNING IS ABOUT: these programs are hand-built
from the scheme, NOT emitted by the compiler. `compileS` returns `none` on every
`ite`.*** Direction: **same proposition** as `ite_certificates`. -/
theorem cert_ite_scheme_runs :
    ([(1,3), (2,2), (3,1), (2,4)] : List (Nat × Nat)).all (fun cfg =>
      let ns := cfg.1
      let nt := cfg.2
      let sT := run (iteOf 1 (thenBlk ns) (elseBlk nt)) St.init
      let sF := run (iteOf 0 (thenBlk ns) (elseBlk nt)) St.init
      (sT.get 2 == BitVec.ofNat 32 (100 + ns - 1)) && (sT.get 3 == 0) &&
      (sF.get 2 == 0) && (sF.get 3 == BitVec.ofNat 32 (200 + nt - 1)) &&
      (sT.pc == BitVec.ofNat 32 (4 * (ns + nt + 3))) &&
      (sF.pc == BitVec.ofNat 32 (4 * (ns + nt + 3)))) = true :=
  ite_certificates

/-! ## 4. WRONG FORMULAS PRODUCE WRONG PROGRAMS — and the dangerous ones look right

*Both certificates below are chosen for the same property: **the observable value is
CORRECT and the program is BROKEN.** A mutant that fails loudly proves little, because
any check would have caught it.* -/

/-- ⛔⛔ **A WRONG EXIT OFFSET GIVES A LOOP THAT NEVER TERMINATES — WITH THE RIGHT
ANSWER IN THE REGISTER.** Shorten the exit branch by one instruction and it lands ON
the backward branch instead of past it, so taking the exit immediately jumps back to
the condition. **`x1` still holds exactly `3`** — the value a register check would read
is correct — and the machine is still running.

🔑 ***Only the HALT check separates them.*** *This is why "the loop produced the right
value" is not a test of a loop scheme, and why `whileHalts` is a clause of the bar.*

Direction: **same proposition** as `exitShort_never_terminates`. -/
theorem cert_a_wrong_backward_offset_never_terminates :
    let img := (.ADDI 2 0 3) :: whileBlock (condBlk 2) (BitVec.ofNat 12 (2 * (3 + 1)))
                 (whileBack 2 3) (bodyBlk 3)
    ((runFor 64 img St.init).get 1 == 3, whileHalts img 64) = (true, false) :=
  exitShort_never_terminates

/-- ⛔⛔ **A WRONG CONDITIONAL OFFSET FALLS THROUGH INTO THE ELSE TAIL — WITH THE RIGHT
ANSWER IN THE REGISTER.** Count the else block instead of skipping past it and the
then-path lands INSIDE the else block: **`x2` is still `100`, exactly right**, and `x3`
has been written by code that should never have run.

*A mutant that leaves the observed value correct is the only kind that tests whether
the check observes the right thing at all.*

Direction: **same proposition** as `shortJump_falls_into_the_else_tail`. -/
theorem cert_a_wrong_ite_offset_keeps_the_right_value :
    let s := run (iteBlock 1 (iteThenSkip 1) 6 (thenBlk 1) (elseBlk 3)) St.init
    (s.get 2 == BitVec.ofNat 32 100, s.get 3 == BitVec.ofNat 32 202) = (true, true) :=
  shortJump_falls_into_the_else_tail

#audit_axioms cert_exit_branch_lands
#audit_axioms cert_back_branch_lands
#audit_axioms cert_exit_branch_lands_at_the_machine
#audit_axioms cert_back_branch_lands_at_the_machine
#audit_axioms cert_the_bound_is_tight_on_both_sides
#audit_axioms cert_the_two_directions_differ_by_one
#audit_axioms cert_while_scheme_runs
#audit_axioms cert_ite_scheme_runs
#audit_axioms cert_a_wrong_backward_offset_never_terminates
#audit_axioms cert_a_wrong_ite_offset_keeps_the_right_value

#print axioms cert_exit_branch_lands
#print axioms cert_back_branch_lands
#print axioms cert_the_bound_is_tight_on_both_sides
#print axioms cert_while_scheme_runs
#print axioms cert_ite_scheme_runs
#print axioms cert_exit_branch_lands_at_the_machine
#print axioms cert_back_branch_lands_at_the_machine
#print axioms cert_the_two_directions_differ_by_one
#print axioms cert_a_wrong_backward_offset_never_terminates
#print axioms cert_a_wrong_ite_offset_keeps_the_right_value

end SaltWorks.Certs
