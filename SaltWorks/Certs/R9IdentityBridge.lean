/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# The R9 identity bridge — act 0's kernel residue

Round 4 act 0 asked whether R9 (the `C4Spec` witness) and the stall-arm obligation are
ONE obligation under two names. Two arms derived independently and both answered **TWO**,
naming the same seam: the bridge `cycleRealisesStep_of_C4Spec` (`Stack/Program.lean:2306`).

This file lands the one kernel object that came out of that adjudication and was not
already in the tree: **the bridge's contrapositive**. It is a one-liner, and its value is
entirely in the direction it lets you argue.

⚠️ **WHY IT IS WORTH A NAME.** `:2306` reads *covariantly*: a `C4Spec` witness transports
into the step arm. Read the other way it says something the campaign needs constantly:
**a circuit whose induced cycle map fails the predicate cannot inhabit `C4Spec` at all.**
Same theorem, and the fleet spent an afternoon discovering that the two readings answer
different questions — the covariant one answers *"what does a witness buy?"*, this one
answers *"can a witness exist?"*.

⛔ **THE DATE INDEX, because this theorem's ANTECEDENT is what moves and not the theorem.**
The implication holds at every date. Whether it ever FIRES depends on the core:

* **today's core32** is single-cycle — no stalled cycle exists in the RTL, every cycle
  realises a step, and the antecedent is never satisfied;
* **after the 08-27 freeze**, arbitration gives CPI 4/8/12, stalled cycles exist, and one
  stalled cycle refutes the predicate (`CycleRealisesStepProj` is `∀ ins`, so a single
  input witnesses the negation) — at which point this theorem makes `C4Spec`-as-written
  **false** for the composed core, not merely unproved.

*A claim about "the core" that carries no date is two claims sharing a noun; that lesson
cost a retraction on 08-17 and is written here so the next reader gets it for free.*
-/
import SaltWorks.Stack.Program

namespace SaltWorks.Stack.Program

/-- ⭐ **THE BRIDGE, CONTRAPOSED — a circuit whose induced cycle map fails the
which-cycle predicate cannot inhabit `C4Spec`.**

*Dual of `cycleRealisesStep_of_C4Spec` (`Stack/Program.lean:2306`); no new mathematics,
and that is the point — the impossibility was already in the tree and nobody had read it
in this direction.* -/
theorem not_C4Spec_of_not_cycleRealises {c : SaltWorks.HDL.Circ}
    (nextW : SaltWorks.HDL.Env → Word) (pad : SaltWorks.HDL.Env)
    (h : ¬ CycleRealisesStepProj (cycOfCirc c nextW pad) seenWord) :
    ¬ SaltWorks.HDL.C4Spec c :=
  fun hc => h (cycleRealisesStep_of_C4Spec hc nextW pad)

#audit_axioms not_C4Spec_of_not_cycleRealises

end SaltWorks.Stack.Program
