/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Stack.Program

/-!
# The stall shape — T2's kernel half, and the witness that keeps it honest

**A SHAPE A CAPTAIN IS ASKED TO RATIFY CANNOT LIVE ON ONE DISK.** Until 2026-08-26 every
declaration below existed only in `Scratch*.lean` files, which are GITIGNORED: they built,
they audited clean, and `git` had never seen a line of them.

## What T2 is, and why `retire` is not a function of `Env`

silicon's criterion (c) asks whether `stalls : Env → Bool` is faithful when `retire` is not a
function of `Env`. **It is not, and the reason is measured rather than argued:**

* `Env := Net → Bool` (`Sem.lean`) — a total valuation of every net.
* `Circ` is **purely combinational**: `nIn`, a straight-line gate list, `outs`. There is no
  flop node in the kernel at all; sequential behaviour is a caller-supplied `cyc : Env → Env`.
* `stWidth = 32*32 + 32 = 1056` and `coreInWidth = stWidth + 32` (`StateCodec.lean`) — so the
  modelled domain is **architectural state plus one instruction word, and nothing else.**

⇒ An adapter FSM output cannot be a function of that domain. That is criterion (c).

## ⛔⛔ THE BUBBLE ROUTE IS STRUCK — REFUTED BY THE WIRE, 2026-08-26

This header used to say the resolution was *"not to widen the domain but to stop needing it"*,
with `stalls e = (seenWord e = bubble)` and an RTL obligation to present a bubble while the
adapter is busy. **THE MACHINE DOES THE OPPOSITE:**
```
busadapt8.v:215   c_instr = (kind==T_FETCH && phase==2'd3) ? {pin_in,in_acc[23:0]} : instr_r
                                                             ⇐ THE HELD PREVIOUS INSTRUCTION
grep bubble|nop over SaltWorks/Silicon/RTL/*.v               ⇐ NOTHING; no bubble mechanism
plane32bus.v:73   .en(retire)                                ⇐ the core is stalled by an ENABLE
```
⇒ **the instantiation is `stalls := ¬retire`**, which needs `retire`'s three adapter bits
(`kind`, `storeBeat`) inside `Env` — supplied by the state widening the Captain ratified on
2026-08-26. **T2's blocker and step 7's renumbering are the same item.**

⭐⭐ **AND WHAT SAVED THIS FILE IS THE PARAMETER.** `stalls` is an ARGUMENT of
`CycleRealisesStepOrStalls`, not a constant baked into it — so a wrong reading of the wire killed
one INSTANTIATION and left the shape, the witness, the reduction and the strict extension all
standing. ***PARAMETERISE THE PART THE OTHER LANE OWNS:*** the kernel owns what a stall MEANS, the
RTL owns which cycles ARE stalls, and writing that boundary into the TYPE rather than a comment is
what bounded the damage. *silicon named the parameterisation as load-bearing BEFORE the refutation
was found.* Full record: `docs/retire-two-contracts-0826.md` §2.1–§2.2. If the RTL cannot supply it, the fallback is widening the
state layout to carry the adapter's bits.

⚖️ **AND THE FALLBACK IS NOW PRICED, BY MEASUREMENT RATHER THAN BY MY ADJECTIVE.** I called it
"expensive"; silicon measured it (`saltworks 5baf27ae`) and the adjective was aimed at the wrong
thing:

* the three adapter bits are **ELEVEN GATES** (`adapterNext`, 5 in / 3 out, checked against
  `BusFSM.next` over all 32 inputs) — against `memOrgan`'s 1475. **The bits are not the cost.**
* the cost is a **SEQUENCING TRAP IN THE NUMBER**: step 7 moves `stWidth` 1056 → 1313 (+257) and
  the adapter makes it 1316 (+3). `two_widenings_land_short` states it as a theorem —
  `257 + 3 = 260 ∧ 1313 ≠ 1316` — so **each widening is correct on its own and the pair is
  wrong**: every offset derived against 1313 is short by exactly 3 once the adapter lands.

⇒ *So the fallback is not dear in gates and not blocked by the `C4Spec` pin; it is dangerous in
its ARITHMETIC, and only if the two widenings are sequenced separately.* **Whoever takes it takes
them as ONE act, or inherits offsets that are individually right and jointly short.**

📌 **THE PAIR IS NOW ONE DOCUMENT: `docs/retire-two-contracts-0826.md`.** Captain's ruling (a),
2026-08-26. **A signature on that document is a signature on BOTH of `retire`'s contracts**; the
earlier *"Yes, renumber"* was the width fallback only and is not one of them. Read it before
changing anything about `retire`'s timing.

⚠️ **AND IT IS A SECOND JOB FOR A PIN THAT ALREADY HAS ONE.** silicon's T5 proves
`retire_is_the_only_separator`: on a store, `retire` is low on the address beat and high on
the data beat, and *nothing else* distinguishes them — exhaustive over the state pairs. So the
store path's correctness already rests entirely on `retire`, and this file asks the same
unratified pin to carry the core's stall meaning too. **Two independent obligations, one pin,
two signatures owed. That is a fact for the ratification, not an objection to it.**

⛔⛔ **A NAMESPACE CAPTURE THIS FILE PAID FOR, RECORDED FOR THE NEXT MODULE IN `SaltWorks/HDL/`
THAT OPENS `SaltWorks.Stack.Program`.** `seenWord` is defined TWICE — `SaltWorks.HDL.seenWord`
(`C4.lean`) and `SaltWorks.Stack.Program.seenWord` — and `Program.lean` itself proves them equal
(`seenWord_eq_hdl := rfl`). Inside `namespace SaltWorks.HDL.StallShape` the ENCLOSING namespace
beats an `open`, so a bare `seenWord` binds to the HDL one. **They are DEFEQ but they are
DIFFERENT CONSTANTS: `show` succeeds and `rw` fails**, with "did not find an occurrence" against a
goal that looks identical on screen. That is why every use below says `Program.seenWord`.
⇒ *The tell is elaboration passing while rewriting fails. Two constants, one name, one defeq —
and only the syntactic tactic can see the difference.* Population walked, not sampled: `seenWord`
and `decQ_mem` are the only two names this module uses that are defined in BOTH namespaces, and
`decQ_mem` is harmless — both are `rfl` proofs of the same statement about the same `decQ`.

## Provenance — and a drift this file exists to end

Promoted from `ScratchStallArm.lean` and `ScratchMixedStall.lean`, which each carried copies of
five declarations. **Two of the five had already drifted** (`decQ_cyc_eq_of_stall`,
`decQ_cyc_eq_of_step`): statements byte-identical, proof bodies not. The later file had removed
two `simp` lemmas that *fired nothing* (`linter.unusedSimpArgs`, 08/17) and the copy never
followed. **The corrected text is what is below.** `ScratchMixedStall`'s own header predicted
exactly this — *"if those proofs change, THIS SECTION MUST BE RE-CHECKED"* — and both files
still built and audited clean, so nothing could have reported it. A reminder is an open defect
wearing a discharge marker; one tracked definition is the property that replaces it.
-/

namespace SaltWorks.HDL.StallShape
open SaltWorks.ISA SaltWorks.Stack SaltWorks.Stack.Program


/-! ## §0 — THE SHAPE ITSELF. Defined ONCE, here, and tracked. -/

/-- **THE PROPOSED SHAPE.** Every cycle either realises a `stepT`, or is a DECLARED
stall that holds `(regs, pc)`. -/
def CycleRealisesStepOrStalls (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env)
    (wordAt : SaltWorks.HDL.Env → Word) (stalls : SaltWorks.HDL.Env → Bool) : Prop :=
  ∀ ins,
    if stalls ins then
      (SaltWorks.HDL.decQ (cyc ins)).regs = (SaltWorks.HDL.decQ ins).regs
        ∧ (SaltWorks.HDL.decQ (cyc ins)).pc = (SaltWorks.HDL.decQ ins).pc
    else
      (SaltWorks.HDL.decQ (cyc ins)).regs
          = (stepT (SaltWorks.HDL.decQ ins) (wordAt ins)).regs
        ∧ (SaltWorks.HDL.decQ (cyc ins)).pc
          = (stepT (SaltWorks.HDL.decQ ins) (wordAt ins)).pc

/-- **How many ISA steps the first `n` CLOCKS actually realise.** -/
def stepsIn (stalls : SaltWorks.HDL.Env → Bool)
    (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env) (ins : SaltWorks.HDL.Env) : Nat → Nat
  | 0 => 0
  | n + 1 => stepsIn stalls cyc ins n + (if stalls (cycles cyc n ins) then 0 else 1)

/-! ## §0.1 — THE THREE PROPERTIES A RATIFICATION RESTS ON -/

/-- **(a) REDUCTION — an empty stall set gives back today's predicate, EXACTLY.**
*This is the property that keeps the 20-declaration cone alive.* -/
theorem stallArm_reduces (cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env)
    (wordAt : SaltWorks.HDL.Env → Word) :
    CycleRealisesStepOrStalls cyc wordAt (fun _ => false)
      ↔ CycleRealisesStepProj cyc wordAt :=
  Iff.rfl

/-- **(b) NON-EMPTINESS — the stall arm ADMITS the map today's predicate REJECTS.** -/
theorem stallArm_admits_stalledBits (nextW : SaltWorks.HDL.Env → Word)
    (pad : SaltWorks.HDL.Env) :
    CycleRealisesStepOrStalls (cycOfBits stalledBits nextW pad) Program.seenWord
      (fun _ => true) := by
  intro ins
  -- ⚠️ `simp only` with NO lemma list on purpose: the `ite` reduction here comes from
  -- simp's BUILT-IN machinery, not from any lemma. Naming `if_pos rfl` here fired NOTHING
  -- and read as load-bearing (linter.unusedSimpArgs, found 08/17 by an executor copying
  -- these lemmas verbatim). cf. the banked law: SIMP CAN REPORT SUCCESS APPLYING NO LEMMA.
  simp only
  rw [decQ_cycOfBits_stalled]
  exact ⟨rfl, rfl⟩

/-- ⭐ **THE DISCRIMINATION, IN ONE STATEMENT — the new predicate is STRICTLY weaker.**
*One and the same cycle map: ADMITTED by the stall arm, REFUTED by today's predicate.
Without this the restatement could be a rename.* -/
theorem stallArm_strictly_extends (nextW : SaltWorks.HDL.Env → Word)
    (pad : SaltWorks.HDL.Env) :
    CycleRealisesStepOrStalls (cycOfBits stalledBits nextW pad) Program.seenWord (fun _ => true)
      ∧ ¬ CycleRealisesStepProj (cycOfBits stalledBits nextW pad) Program.seenWord :=
  ⟨stallArm_admits_stalledBits nextW pad, not_cycleRealisesStep_stalledBits nextW pad⟩

/-! ## §1 — THE MIXED MACHINE

The stall set is read off the INSTRUCTION NETS: a cycle stalls exactly when the
word presented to the core is `mixWordHold`. That is a genuine predicate on `Env`
— it is `true` somewhere and `false` somewhere — and it is the kind of stall
signal a real tile has (a bubble is a word, not a global constant).

The next-word policy INVERTS it: a stalled cycle is followed by a real
instruction, a stepping cycle by a bubble. So the run alternates, and every
`stepsIn` `if` along the trajectory is decided by the ACTUAL wire state. -/

/-- The bubble: the word that declares a stall. `decode 0 = none`, so it is also
`MemFree` — a bubble cannot touch memory. -/
def mixWordHold : Word := 0#32

/-- The real instruction a stepping cycle executes: `addi x1, x0, 1`. -/
def mixWordGo : Word := encode (Instr.ADDI 1 0 1)

theorem mixWordGo_ne_hold : ¬ (mixWordGo = mixWordHold) := by
  show ¬ (encode (Instr.ADDI 1 0 1) = 0#32)
  decide +kernel

/-- **THE STALL SET — neither empty nor everything.** -/
def mixStalls (e : SaltWorks.HDL.Env) : Bool := decide (Program.seenWord e = mixWordHold)

/-- **THE NEXT-WORD POLICY — it inverts the stall signal.** -/
def mixNextW (e : SaltWorks.HDL.Env) : Word :=
  if mixStalls e then mixWordGo else mixWordHold

/-- **THE CORE'S OUTPUT BITS — stalled bits on a stall cycle, ideal bits otherwise.**
*Both halves come out of Program.lean's own apparatus: `decQ_cycOfBits_stalled`
(:2389) and `cycleRealisesStepProj_of_bits` (:2282).* -/
def mixBits (e : SaltWorks.HDL.Env) : List Bool :=
  if mixStalls e then stalledBits e else idealBits e

/-- **THE CYCLE MAP.** -/
def mixCyc (pad : SaltWorks.HDL.Env) : SaltWorks.HDL.Env → SaltWorks.HDL.Env :=
  cycOfBits mixBits mixNextW pad

/-- **THE RESET STATE** — any ISA state `s`, with a bubble on the instruction nets,
so clock 0 is a stall. -/
def mixIns (s : St) : SaltWorks.HDL.Env := envWith s mixWordHold

/-! ## §2 — THE STALL SET IS A GENUINE MIDDLE -/

theorem mixStalls_mixIns (s : St) : mixStalls (mixIns s) = true := by
  show decide (Program.seenWord (envWith s mixWordHold) = mixWordHold) = true
  rw [seenWord_envWith]
  exact decide_eq_true rfl

/-- The word the NEXT cycle sees is this cycle's `mixNextW` — `seenWord_envOfBits`. -/
theorem seenWord_mixCyc (pad e : SaltWorks.HDL.Env) :
    Program.seenWord (mixCyc pad e) = mixNextW e :=
  seenWord_envOfBits _ _ _

/-- ⭐ **THE ALTERNATION.** One cycle flips the stall signal, so no run of this
machine is all-stall and none is stall-free. -/
theorem mixStalls_mixCyc (pad e : SaltWorks.HDL.Env) :
    mixStalls (mixCyc pad e) = ! mixStalls e := by
  have h1 : mixStalls (mixCyc pad e) = decide (mixNextW e = mixWordHold) := by
    show decide (Program.seenWord (mixCyc pad e) = mixWordHold) = _
    rw [seenWord_mixCyc]
  cases hb : mixStalls e with
  | true =>
      have hw : mixNextW e = mixWordGo := by
        show (if mixStalls e then mixWordGo else mixWordHold) = mixWordGo
        rw [hb]; exact if_pos rfl
      rw [h1, hw]
      exact decide_eq_false mixWordGo_ne_hold
  | false =>
      have hw : mixNextW e = mixWordHold := by
        show (if mixStalls e then mixWordGo else mixWordHold) = mixWordHold
        rw [hb]; exact if_neg (by simp)
      rw [h1, hw]
      exact decide_eq_true rfl

/-- ⛔ **NEITHER CORNER.** The stall set is inhabited AND co-inhabited, so it is
neither `fun _ => false` nor `fun _ => true`. -/
theorem mixStalls_is_middle (s : St) (pad : SaltWorks.HDL.Env) :
    (∃ e, mixStalls e = true) ∧ (∃ e, mixStalls e = false) :=
  ⟨⟨mixIns s, mixStalls_mixIns s⟩,
   ⟨mixCyc pad (mixIns s), by rw [mixStalls_mixCyc, mixStalls_mixIns]; rfl⟩⟩

/-! ## §3 — THE MIXED MACHINE SATISFIES THE ARM -/

/-- ⭐⭐ **THE PREDICATE HOLDS**, at a stall set that is neither corner. -/
theorem mix_realises (pad : SaltWorks.HDL.Env) :
    CycleRealisesStepOrStalls (mixCyc pad) Program.seenWord mixStalls := by
  intro ins
  by_cases hcase : mixStalls ins = true
  · rw [if_pos hcase]
    have hb : mixBits ins = stalledBits ins := by
      show (if mixStalls ins then stalledBits ins else idealBits ins) = stalledBits ins
      rw [if_pos hcase]
    have h1 : mixCyc pad ins = cycOfBits stalledBits mixNextW pad ins := by
      show envOfBits (mixBits ins) pad (mixNextW ins)
          = envOfBits (stalledBits ins) pad (mixNextW ins)
      rw [hb]
    rw [h1, decQ_cycOfBits_stalled]
    exact ⟨rfl, rfl⟩
  · rw [if_neg hcase]
    have hb : mixBits ins = idealBits ins := by
      show (if mixStalls ins then stalledBits ins else idealBits ins) = idealBits ins
      rw [if_neg hcase]
    have h1 : mixCyc pad ins = cycOfBits idealBits mixNextW pad ins := by
      show envOfBits (mixBits ins) pad (mixNextW ins)
          = envOfBits (idealBits ins) pad (mixNextW ins)
      rw [hb]
    rw [h1]
    exact cycleRealisesStep_idealBits mixNextW pad ins

/-! ## §4 — ⭐⭐⭐ THE STRICT INEQUALITIES

`stepsIn_le` gives `≤ n` for free and `stepsIn_empty` gives `= n`; the all-stall
corner gives `= 0`. NEITHER of those is what a mixed run looks like. Below: two
clocks, ONE step — strictly more than the all-stall corner, strictly fewer than
the clock count. -/

/-- The two-clock count, unfolded against the actual trajectory. -/
theorem stepsIn_mix_two (s : St) (pad : SaltWorks.HDL.Env) :
    stepsIn mixStalls (mixCyc pad) (mixIns s) 2 = 1 := by
  have hs0 : mixStalls (mixIns s) = true := mixStalls_mixIns s
  have hs1 : mixStalls (mixCyc pad (mixIns s)) = false := by
    rw [mixStalls_mixCyc, hs0]; rfl
  have hunfold : stepsIn mixStalls (mixCyc pad) (mixIns s) 2
      = (0 + (if mixStalls (mixIns s) then 0 else 1))
        + (if mixStalls (mixCyc pad (mixIns s)) then 0 else 1) := rfl
  rw [hunfold, hs0, hs1]
  rfl

/-- ⭐ **BOTH KINDS OF CYCLE OCCUR INSIDE THE SAME RUN** — clock 0 holds, clock 1
steps. This is the fact the strict inequalities encode. -/
theorem mix_both_kinds (s : St) (pad : SaltWorks.HDL.Env) :
    mixStalls (cycles (mixCyc pad) 0 (mixIns s)) = true
      ∧ mixStalls (cycles (mixCyc pad) 1 (mixIns s)) = false := by
  refine ⟨mixStalls_mixIns s, ?_⟩
  show mixStalls (mixCyc pad (mixIns s)) = false
  rw [mixStalls_mixCyc, mixStalls_mixIns]; rfl

/-- ⭐⭐⭐ **NOT THE ALL-STALL CORNER: the run realises STRICTLY POSITIVE progress.** -/
theorem mix_stepsIn_pos (s : St) (pad : SaltWorks.HDL.Env) :
    0 < stepsIn mixStalls (mixCyc pad) (mixIns s) 2 := by
  rw [stepsIn_mix_two]
  exact Nat.zero_lt_one

/-- ⭐⭐⭐ **NOT THE EMPTY-STALL CORNER: the run realises STRICTLY FEWER steps than
clocks.** *`stepsIn_le` gives `≤ 2`; this gives `< 2`, and only a genuine stall
inside the run can.* -/
theorem mix_stepsIn_lt (s : St) (pad : SaltWorks.HDL.Env) :
    stepsIn mixStalls (mixCyc pad) (mixIns s) 2 < 2 := by
  rw [stepsIn_mix_two]
  exact Nat.one_lt_two

/-- ⭐⭐⭐ **THE DELIVERABLE COMPILER ASKED FOR, IN ONE STATEMENT.** -/
theorem mixed_stall_witness (s : St) (pad : SaltWorks.HDL.Env) :
    CycleRealisesStepOrStalls (mixCyc pad) Program.seenWord mixStalls
      ∧ (∃ e, mixStalls e = true) ∧ (∃ e, mixStalls e = false)
      ∧ 0 < stepsIn mixStalls (mixCyc pad) (mixIns s) 2
      ∧ stepsIn mixStalls (mixCyc pad) (mixIns s) 2 < 2 :=
  ⟨mix_realises pad, (mixStalls_is_middle s pad).1, (mixStalls_is_middle s pad).2,
   mix_stepsIn_pos s pad, mix_stepsIn_lt s pad⟩

/-! ## §5 — ⭐⭐⭐ THE ACT-1 DELIVERABLE ITSELF, DRIVEN AT A MIXED STALL SET

⛔ WHY §4 IS NOT ENOUGH. `allStall_holds_state` drives
`cycles_realise_steps_of_stalls` at `stalls = fun _ => true`, and there BOTH of
that theorem's hypotheses are discharged by `intro k hk; simp at hk` — the
antecedent `stalls … = false` is unsatisfiable, so `halign` and `hmf` are NEVER
TESTED and the conclusion degenerates to `decQ … = decQ ins`. A hypothesis that
is discharged by refuting its antecedent has not been met; it has been dodged.

⇒ Below, the same theorem is driven where BOTH hypotheses have to be PAID: the
alignment hypothesis is discharged on the non-stall cycles (they exist), the
`MemFree` hypothesis is discharged on a real instruction word, and the conclusion
is a `runWords` at a step count strictly between `0` and `n`.

⚠️ THE THREE LEMMAS IMMEDIATELY BELOW ARE COPIES of `ScratchStallArm.lean`'s
(`decQ_cyc_eq_of_stall`, `decQ_cyc_eq_of_step`, `cycles_realise_steps_of_stalls`),
reproduced verbatim because that file is live under another pen and is not
imported here. ⇒ If those proofs change, THIS SECTION MUST BE RE-CHECKED. -/

/-- COPY of `ScratchStallArm.lean`'s `decQ_cyc_eq_of_stall`. -/
theorem decQ_cyc_eq_of_stall {cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env}
    {wordAt : SaltWorks.HDL.Env → Word} {stalls : SaltWorks.HDL.Env → Bool}
    (h : CycleRealisesStepOrStalls cyc wordAt stalls)
    (e : SaltWorks.HDL.Env) (hs : stalls e = true) :
    SaltWorks.HDL.decQ (cyc e) = SaltWorks.HDL.decQ e := by
  have he := h e
  rw [hs] at he
  -- ⚠️ NO LEMMA LIST, ON PURPOSE: the `ite` reduction is simp's BUILT-IN machinery.
  -- `if_pos rfl` fired NOTHING and read as load-bearing (linter.unusedSimpArgs, 08/17).
  simp only at he
  obtain ⟨hr, hp⟩ := he
  refine St_eq_of_fields hr hp ?_ ?_
  · rw [decQ_mem, decQ_mem]
  · rw [decQ_trapped, decQ_trapped]

/-- COPY of `ScratchStallArm.lean`'s `decQ_cyc_eq_of_step`. -/
theorem decQ_cyc_eq_of_step {cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env}
    {wordAt : SaltWorks.HDL.Env → Word} {stalls : SaltWorks.HDL.Env → Bool}
    (h : CycleRealisesStepOrStalls cyc wordAt stalls)
    (e : SaltWorks.HDL.Env) (hs : stalls e = false) (hmf : MemFree (wordAt e)) :
    SaltWorks.HDL.decQ (cyc e) = stepT (SaltWorks.HDL.decQ e) (wordAt e) := by
  have he := h e
  rw [hs] at he
  -- the same correction: `if_neg` fired NOTHING here and was decoration.
  simp only [Bool.false_eq_true] at he
  obtain ⟨hr, hp⟩ := he
  refine St_eq_of_fields hr hp ?_ ?_
  · rw [decQ_mem, stepT_mem_frame_of_not_touchesMem _ _ hmf, decQ_mem]
  · rw [decQ_trapped, stepT_trapped_frame_of_not_touchesMem _ _ hmf, decQ_trapped]

/-- COPY of `ScratchStallArm.lean`'s `cycles_realise_steps_of_stalls` — the act-1
deliverable, reproduced so it can be driven at the mixed instance. -/
theorem cycles_realise_steps_of_stalls {cyc : SaltWorks.HDL.Env → SaltWorks.HDL.Env}
    {wordAt : SaltWorks.HDL.Env → Word} {stalls : SaltWorks.HDL.Env → Bool}
    (h : CycleRealisesStepOrStalls cyc wordAt stalls)
    (ws : Nat → Word) (ins : SaltWorks.HDL.Env)
    (halign : ∀ k, stalls (cycles cyc k ins) = false →
        ws (stepsIn stalls cyc ins k) = wordAt (cycles cyc k ins))
    (hmf : ∀ k, stalls (cycles cyc k ins) = false → MemFree (wordAt (cycles cyc k ins)))
    (n : Nat) :
    SaltWorks.HDL.decQ (cycles cyc n ins)
      = runWords ws (stepsIn stalls cyc ins n) (SaltWorks.HDL.decQ ins) := by
  induction n with
  | zero => rfl
  | succ m ih =>
      rw [cycles_succ]
      cases hcase : stalls (cycles cyc m ins) with
      | true =>
          rw [decQ_cyc_eq_of_stall h _ hcase, ih]
          simp [stepsIn, hcase]
      | false =>
          rw [decQ_cyc_eq_of_step h _ hcase (hmf m hcase), ih]
          have hstep : stepsIn stalls cyc ins (m + 1) = stepsIn stalls cyc ins m + 1 := by
            simp [stepsIn, hcase]
          rw [hstep, runWords_succ, halign m hcase]

/-! ### The two hypotheses, PAID -/

/-- **THE ALIGNMENT HYPOTHESIS IS PAID.** On the mixed trajectory a non-stall
cycle is looking at `mixWordGo` — so the constant stream `fun _ => mixWordGo`
aligns, and the alignment is DERIVED from the machine, not assumed. -/
theorem seenWord_of_step_on_traj (s : St) (pad : SaltWorks.HDL.Env) (k : Nat)
    (hk : mixStalls (cycles (mixCyc pad) k (mixIns s)) = false) :
    Program.seenWord (cycles (mixCyc pad) k (mixIns s)) = mixWordGo := by
  cases k with
  | zero =>
      have hk0 : mixStalls (mixIns s) = false := hk
      rw [mixStalls_mixIns s] at hk0
      exact absurd hk0 (by simp)
  | succ m =>
      have hk' : mixStalls (mixCyc pad (cycles (mixCyc pad) m (mixIns s))) = false := hk
      rw [mixStalls_mixCyc] at hk'
      have hm : mixStalls (cycles (mixCyc pad) m (mixIns s)) = true := by
        cases hb : mixStalls (cycles (mixCyc pad) m (mixIns s)) with
        | true => rfl
        | false => rw [hb] at hk'; exact absurd hk' (by simp)
      show Program.seenWord (mixCyc pad (cycles (mixCyc pad) m (mixIns s))) = mixWordGo
      rw [seenWord_mixCyc]
      show (if mixStalls (cycles (mixCyc pad) m (mixIns s)) then mixWordGo else mixWordHold)
          = mixWordGo
      rw [hm]
      exact if_pos rfl

/-- **THE `MemFree` HYPOTHESIS IS PAID** — on a REAL instruction, not on an
undecodable word that is vacuously memory-free. -/
theorem memFree_mixWordGo : MemFree mixWordGo := by
  intro i hi
  have hi' : SaltWorks.ISA.decode (encode (Instr.ADDI 1 0 1)) = some i := hi
  rw [decode_encode] at hi'
  injection hi' with hii
  subst hii
  rfl

/-- ⭐⭐⭐ **THE DELIVERABLE AT THE MIXED INSTANCE.** `n` clocks of a machine that
genuinely stalls and genuinely steps realise `stepsIn … n` steps of the word
stream — both hypotheses discharged on cycles that exist. -/
theorem mix_run (s : St) (pad : SaltWorks.HDL.Env) (n : Nat) :
    SaltWorks.HDL.decQ (cycles (mixCyc pad) n (mixIns s))
      = runWords (fun _ => mixWordGo)
          (stepsIn mixStalls (mixCyc pad) (mixIns s) n)
          (SaltWorks.HDL.decQ (mixIns s)) :=
  cycles_realise_steps_of_stalls (mix_realises pad) (fun _ => mixWordGo) (mixIns s)
    (fun k hk => (seenWord_of_step_on_traj s pad k hk).symm)
    (fun k hk => by rw [seenWord_of_step_on_traj s pad k hk]; exact memFree_mixWordGo)
    n

/-- ⭐ **TWO CLOCKS, EXACTLY ONE STEP.** *Neither `decQ … = decQ ins` (the
all-stall corner) nor two steps (the empty-stall corner).* -/
theorem mix_two_clocks_one_step (s : St) (pad : SaltWorks.HDL.Env) :
    SaltWorks.HDL.decQ (cycles (mixCyc pad) 2 (mixIns s))
      = stepT (SaltWorks.HDL.decQ (mixIns s)) mixWordGo := by
  rw [mix_run, stepsIn_mix_two]
  rfl

/-- ⭐⭐ **AND THE STATE ACTUALLY MOVES** — the sharpest separation from
`allStall_holds_state`, whose conclusion is that nothing happens. Two clocks from
reset with a bubble on the nets: `x1 = 1`. -/
theorem mix_run_moves_the_state (pad : SaltWorks.HDL.Env) :
    (SaltWorks.HDL.decQ (cycles (mixCyc pad) 2 (mixIns St.init))).get 1 = 1#32 := by
  rw [mix_two_clocks_one_step]
  show (stepT (SaltWorks.HDL.decQ (envWith St.init mixWordHold))
      (encode (Instr.ADDI 1 0 1))).get 1 = 1#32
  rw [decQ_envWith_eq, stepT_encode]
  decide +kernel

#audit_axioms decQ_cyc_eq_of_stall decQ_cyc_eq_of_step cycles_realise_steps_of_stalls
#audit_axioms seenWord_of_step_on_traj memFree_mixWordGo
#audit_axioms mix_run mix_two_clocks_one_step mix_run_moves_the_state

#audit_axioms CycleRealisesStepOrStalls stepsIn
#audit_axioms stallArm_reduces stallArm_admits_stalledBits stallArm_strictly_extends
#audit_axioms mixStalls mixNextW mixBits mixCyc mixIns
#audit_axioms mixWordGo_ne_hold mixStalls_mixCyc mixStalls_is_middle
#audit_axioms mix_realises stepsIn_mix_two mix_both_kinds
#audit_axioms mix_stepsIn_pos mix_stepsIn_lt mixed_stall_witness


-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.StallShape.mixStalls_mixIns SaltWorks.HDL.StallShape.seenWord_mixCyc
end SaltWorks.HDL.StallShape
