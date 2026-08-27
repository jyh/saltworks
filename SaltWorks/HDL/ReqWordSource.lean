/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.StallsAtWidened

/-!
# The `req` word source, PARAMETERISED — and the off-by-one confined to one state

`StallsAtWidened` names an obligation it cannot see:

> *"If it is off by one, the equation below still holds — it is stated over whatever `reqAt`
> returns — but the FUNCTION would be reading the wrong word, and no theorem here would notice."*

**Why no theorem there notices is structural, not an oversight.** `stallsAt_eq_not_retire` reads

```
stallsAt e = !(retire s (reqAt e))
```

with `reqAt e` on BOTH sides. It is an IDENTITY in the `req` argument, so it is true for every
word source whatsoever — including one that reads uninitialised memory. **A theorem that mentions
the suspect quantity on both sides of its own equation cannot be evidence about that quantity.**

## What this file does

It applies the technique this seat already owns — **parameterise the part the other lane owns** —
to the word source itself, and then proves three things the identity could not:

1. **CONFINEMENT.** `retire` consults `req` in the `fetch` state and NOWHERE ELSE. So for any two
   word sources, `stalls` can differ only where the adapter is fetching.
2. **SENSITIVITY.** In the `fetch` state the word source DECIDES the answer, exhibited on two
   concrete RV32I words. The obligation is real, not cosmetic.
3. **THE BOUNDED SIDE CONDITION.** If the presented word and the previously-held word agree on
   `req` *whenever the adapter is fetching*, then `stalls` is the same function either way — so
   the RTL's timing question does not have to be settled in general, only on that one state.

⛔ **THIS PROVES NOTHING ABOUT `busadapt8.v`.** Which word the RTL actually presents is silicon's
lane and is still unproved. What changes is that the Lean side can now SEE the difference, and the
surface silicon's successor must settle has shrunk from "the `req` correspondence" to "the `req`
correspondence *in the fetch state*".
-/

namespace SaltWorks.HDL.ReqWordSource

open SaltWorks.HDL SaltWorks.HDL.BusFSM SaltWorks.HDL.StallsAtWidened

/-! ## §1 — THE PARAMETERISED FUNCTION -/

/-- `stallsAt` with its WORD SOURCE lifted to a parameter. The boundary between the lanes is
now in the TYPE: everything about *which word* is `word`'s business. -/
def stallsFrom (word : Env → BitVec 32) (e : Env) : Bool :=
  !(retire (adapterAt e) (reqOfWord (word e)))

/-- The landed function is this one at the presented word. Definitional — no new content. -/
theorem stallsAt_eq_stallsFrom_seenWordFull : stallsAt = stallsFrom seenWordFull := rfl

/-! ## §2 — CONFINEMENT: `req` is consulted in ONE state -/

/-- ⭐ **`retire` ignores `req` unless the adapter is fetching.** -/
theorem retire_req_irrelevant_off_fetch (s : BusState) (r₁ r₂ : Bool) (h : s.kind ≠ Kind.fetch) :
    retire s r₁ = retire s r₂ := by
  cases hk : s.kind
  all_goals first | exact absurd hk h | simp [retire, hk]

/-- ⭐⭐ **THE BLAST RADIUS OF THE OPEN OBLIGATION.** Two word sources — the presented word and
whatever the RTL actually holds — can disagree about `stalls` ONLY where the adapter is fetching.
Every `load`, `store` and `idle` state is immune to the off-by-one. -/
theorem stallsFrom_agrees_off_fetch (w₁ w₂ : Env → BitVec 32) (e : Env)
    (h : (adapterAt e).kind ≠ Kind.fetch) :
    stallsFrom w₁ e = stallsFrom w₂ e := by
  simp only [stallsFrom]
  exact congrArg (fun b => !b) (retire_req_irrelevant_off_fetch _ _ _ h)

/-! ## §3 — SENSITIVITY: in the fetch state the word source DECIDES -/

/-- In the fetch state `retire` is exactly `!req`, so distinct `req` give distinct answers. -/
theorem retire_fetch_separates (s : BusState) (h : s.kind = Kind.fetch) (r₁ r₂ : Bool)
    (hne : r₁ ≠ r₂) : retire s r₁ ≠ retire s r₂ := by
  simp only [retire, h]
  simpa using hne

/-- A word the RTL would answer `req = true` for: a load. -/
def loadWord : BitVec 32 := SaltWorks.ISA.encode (.LW 1 2 0)

/-- A word the RTL would answer `req = false` for: an ALU op. -/
def aluWord : BitVec 32 := SaltWorks.ISA.encode (.ADD 1 2 3)

theorem reqOfWord_loadWord : reqOfWord loadWord = true := by
  simp [reqOfWord, loadWord, SaltWorks.ISA.decode_encode]

theorem reqOfWord_aluWord : reqOfWord aluWord = false := by
  simp [reqOfWord, aluWord, SaltWorks.ISA.decode_encode]

/-- ⛔⛔ **THE OBLIGATION IS REAL — HERE IS THE WITNESS.** In the fetch state, reading the load
word and reading the ALU word give OPPOSITE stall decisions. So "off by one" is not a harmless
relabelling: it flips the machine's behaviour on a state the core actually occupies. -/
theorem word_source_decides_at_fetch (pad : Env) :
    stallsFrom (fun _ => loadWord) (envWithAdapter ⟨Kind.fetch, false⟩ pad)
      ≠ stallsFrom (fun _ => aluWord) (envWithAdapter ⟨Kind.fetch, false⟩ pad) := by
  simp only [stallsFrom, envWithAdapter_reads_back, reqOfWord_loadWord, reqOfWord_aluWord]
  decide

/-! ## §4 — THE BOUNDED SIDE CONDITION, WHICH IS THE POINT OF THE FILE -/

/-- ⭐⭐⭐ **THE OFF-BY-ONE, CONFINED.** If the two candidate readings agree on `req` *whenever
the adapter is in the fetch state*, then they define the SAME stall function everywhere.

⇒ silicon's successor does not have to prove that `instr_r` presents the current instruction in
general. They have to settle it **on the fetch state only** — and this theorem is what converts
that reduction from a plausible argument into a checked one. -/
theorem off_by_one_confined_to_fetch (w₁ w₂ : Env → BitVec 32)
    (h : ∀ e, (adapterAt e).kind = Kind.fetch → reqOfWord (w₁ e) = reqOfWord (w₂ e)) :
    ∀ e, stallsFrom w₁ e = stallsFrom w₂ e := by
  intro e
  by_cases hk : (adapterAt e).kind = Kind.fetch
  · simp only [stallsFrom, h e hk]
  · exact stallsFrom_agrees_off_fetch w₁ w₂ e hk

/-! ## §4.2 — THE EXACT CHARACTERISATION: not just WHERE it can differ, but WHEN -/

/-- ⭐ **AT A FETCH, `stalls` IS EXACTLY `req`.** `retire` is `!req` there and `stalls` is
`!retire`, so the two negations cancel. This is what makes the off-by-one legible: at a fetch the
stall decision IS the memory-ness of whichever word is read, nothing more. -/
theorem stallsFrom_at_fetch (w : Env → BitVec 32) (e : Env)
    (hk : (adapterAt e).kind = Kind.fetch) :
    stallsFrom w e = reqOfWord (w e) := by
  simp only [stallsFrom, retire, hk]
  cases reqOfWord (w e) <;> rfl

/-- ⭐⭐⭐ **THE DISCRIMINATING SET, EXACTLY — AN IFF, NOT A CONTAINMENT.** Two word sources
give different stall decisions **precisely** when the adapter is fetching AND the two words
disagree on memory-ness. Confinement gives one direction, sensitivity the other; together they
pin the set rather than bound it.

⇒ **this is the form silicon's successor can act on with a waveform instead of a proof:** the
cycles to examine are the FETCH cycles at which the presented word and the held word differ in
being a `LW`/`SW`. Everywhere else the two readings are provably indistinguishable, so a
disagreement there cannot exist to be found. -/
theorem stalls_differ_iff_fetch_and_memness_differs (w₁ w₂ : Env → BitVec 32) (e : Env) :
    (stallsFrom w₁ e ≠ stallsFrom w₂ e)
      ↔ ((adapterAt e).kind = Kind.fetch ∧ reqOfWord (w₁ e) ≠ reqOfWord (w₂ e)) := by
  constructor
  · intro hne
    by_cases hk : (adapterAt e).kind = Kind.fetch
    · refine ⟨hk, fun heq => hne ?_⟩
      simp only [stallsFrom, heq]
    · exact absurd (stallsFrom_agrees_off_fetch w₁ w₂ e hk) hne
  · rintro ⟨hk, hr⟩
    rw [stallsFrom_at_fetch w₁ e hk, stallsFrom_at_fetch w₂ e hk]
    exact hr

/-- ⛔ **CONTROL FOR §4.2.** The right-hand side is not always true, so the iff is not a
disguised tautology: at a STORE state the condition fails no matter what the words are. -/
theorem control_discriminating_set_is_not_everything (pad : Env) (w₁ w₂ : Env → BitVec 32) :
    ¬ ((adapterAt (envWithAdapter ⟨Kind.store, false⟩ pad)).kind = Kind.fetch
        ∧ reqOfWord (w₁ (envWithAdapter ⟨Kind.store, false⟩ pad))
            ≠ reqOfWord (w₂ (envWithAdapter ⟨Kind.store, false⟩ pad))) := by
  rintro ⟨hk, -⟩
  rw [envWithAdapter_reads_back] at hk
  exact absurd hk (by decide)

/-! ## §4.1 — WHERE THE LANDED NON-VACUITY WITNESS DOES NOT REACH

Found by an identity audit of this seat's own T2/T5 surface, criterion pre-registered before
the probes were built: *generalise the suspect quantity and see whether the theorem still
proves.* `stallsAt_eq_not_retire` flagged, as expected — it is the defect this file exists for.
**`stallsAt_is_middle` flagged too, and that one was not expected.**
-/

/-- ⛔⛔ **THE LANDED MIDDLE WITNESS DOES NOT CONSTRAIN THE WORD, AND HERE IS THE PROOF.**
`stallsAt_is_middle` exhibits its middle at two **store** states — and by
`stallsFrom_agrees_off_fetch`, `retire` ignores `req` there. So the very same pair of equations
holds for **every word source whatsoever**, including a constant one.

⇒ *the file's own non-vacuity evidence lives entirely inside the region its header flags as
unsettled being irrelevant to.* The witness is real and the stall set is a genuine middle; what
it cannot do is bear any weight about the word.

**Stated as a theorem rather than a remark so that the limitation is machine-checked and cannot
rot into a comment nobody re-derives.** -/
theorem landed_middle_holds_for_every_word_source (pad : Env) (w : Env → BitVec 32) :
    stallsFrom w (envWithAdapter ⟨Kind.store, false⟩ pad) = true
      ∧ stallsFrom w (envWithAdapter ⟨Kind.store, true⟩ pad) = false := by
  constructor
  · rw [stallsFrom, envWithAdapter_reads_back]; rfl
  · rw [stallsFrom, envWithAdapter_reads_back]; rfl

/-- ⭐⭐ **THE MIDDLE AT THE FETCH STATE — THE ARM THAT WAS MISSING, AND THE WORD IS WHAT MOVES
IT.** At one fixed adapter state, a load word stalls the core and an ALU word does not. This is
the non-vacuity witness the landed one could not be: it is FALSIFIABLE BY THE WORD.

⇒ **the two middles have different mechanisms, which is why one cannot substitute for the other:**
at a store the middle is a function of the BEAT, at a fetch it is a function of the WORD, and only
the second touches the quantity `busadapt8.v:130-136` leaves open — struck 08/26 19:4x and
answered at `:137` onward; the strike header sits at `:126-129`, where this file's older citation
pointed. -/
theorem stalls_is_middle_at_fetch (pad : Env) :
    stallsFrom (fun _ => loadWord) (envWithAdapter ⟨Kind.fetch, false⟩ pad) = true
      ∧ stallsFrom (fun _ => aluWord) (envWithAdapter ⟨Kind.fetch, false⟩ pad) = false := by
  constructor
  · rw [stallsFrom, envWithAdapter_reads_back, reqOfWord_loadWord]; rfl
  · rw [stallsFrom, envWithAdapter_reads_back, reqOfWord_aluWord]; rfl

/-! ## §4.3 — A CROSS-LANE CONSISTENCY CHECK, AND EXACTLY WHAT IT IS WORTH -/

/-- The instruction word carried by the failure signature silicon's `45c9c56` reproduced on
ARM B, with the instruction bypass deliberately defeated: `st_data=00000000, instr=0000a183,
rs2=0`, matching the signature recorded on 08/18. -/
def armBSignatureWord : BitVec 32 := 0x0000a183#32

/-- ⭐⭐ **THE LEAN SIDE PREDICTED THE SHAPE OF THAT FAILURE BEFORE READING IT.** §4.2 says, from
the model alone, that two word sources can differ **only** at a fetch where the words disagree on
memory-ness. So for a bench failure caused by reading the wrong word to exist at all, the
CURRENT and PREVIOUS words must differ in memory-ness — **at least one of the pair is a memory
instruction, and a pair of ALU words could not produce a failure at all.** silicon's ARM B
signature carries `0000a183`, and this seat's decoder says it is a load. -/
theorem armB_signature_is_a_memory_instruction : reqOfWord armBSignatureWord = true := by
  decide +kernel

/-- ⛔ **THE CONTROL — the prediction was falsifiable.** Not every word is in the discriminating
set: an ALU word is outside it, so had ARM B's signature carried one, this check would have failed
and §4.2 would have been in trouble. -/
theorem armB_check_could_have_failed : reqOfWord aluWord = false := reqOfWord_aluWord

/-! ⛔⛔ **WHAT §4.3 IS NOT.** Two independently-derived facts agreeing is EVIDENCE OF AGREEMENT,
not a proof of correspondence. This does not establish `sem (bridge nl outs) = runP`; that bridge
induction is routed off this seat and remains the blocker it was. A matching signature would also
be produced by two models that are wrong in the same way — **what it rules out is the cheap
failure where the Lean side's discriminating set and the RTL's actual failure mode are simply
about different things.** That is worth stating and worth no more than that. -/

/-! ## §5 — CONTROLS: each theorem above must be able to fail -/

/-- ⛔ **CONTROL FOR §4.** Drop the fetch-state hypothesis and the conclusion is FALSE — witnessed
by the very pair §3 exhibits. Without this, `off_by_one_confined_to_fetch` could be passing
because its conclusion is trivially true. -/
theorem control_confinement_needs_its_hypothesis :
    ¬ (∀ (w₁ w₂ : Env → BitVec 32) (e : Env), stallsFrom w₁ e = stallsFrom w₂ e) := by
  intro hbad
  exact word_source_decides_at_fetch (fun _ => false)
    (hbad (fun _ => loadWord) (fun _ => aluWord) _)

/-- ⛔ **CONTROL FOR §2.** `retire` genuinely DOES depend on `req` somewhere — otherwise
`retire_req_irrelevant_off_fetch` would be a statement about a constant function and the
confinement result would be vacuous. -/
theorem control_retire_is_not_req_blind :
    ¬ (∀ (s : BusState) (r₁ r₂ : Bool), retire s r₁ = retire s r₂) := by
  intro hbad
  exact absurd (hbad ⟨Kind.fetch, false⟩ true false) (by decide)

#audit_axioms stallsFrom stallsAt_eq_stallsFrom_seenWordFull
#audit_axioms retire_req_irrelevant_off_fetch stallsFrom_agrees_off_fetch
#audit_axioms retire_fetch_separates reqOfWord_loadWord reqOfWord_aluWord
#audit_axioms word_source_decides_at_fetch off_by_one_confined_to_fetch
#audit_axioms landed_middle_holds_for_every_word_source stalls_is_middle_at_fetch
#audit_axioms stallsFrom_at_fetch stalls_differ_iff_fetch_and_memness_differs
#audit_axioms control_discriminating_set_is_not_everything
#audit_axioms armB_signature_is_a_memory_instruction armB_check_could_have_failed
#audit_axioms control_confinement_needs_its_hypothesis control_retire_is_not_req_blind

end SaltWorks.HDL.ReqWordSource
