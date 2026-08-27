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
#audit_axioms control_confinement_needs_its_hypothesis control_retire_is_not_req_blind

end SaltWorks.HDL.ReqWordSource
