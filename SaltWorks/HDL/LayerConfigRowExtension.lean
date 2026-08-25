/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.LangRowARefuted
import Mathlib.Data.Fintype.EquivFin

/-! # MIG-9: do Rows A/B extend to layer configs? — the verdict, and it INVERTS

`docs/neural-graph-machine-sketch.md` §6 asks this seat: *"the configuration compiler
(weights/routing as compiled artifacts; does Rows A/B extend to layer configs?)"*, and §2
proposes that Rows A/B *"then apply to the DERIVATIVE too — the compiled gradient is the
source's gradient, as a theorem."*

⛔ **THE QUESTION HAS A PRECONDITION NOBODY STATED, AND AT THE ORIGINAL DOMAIN IT FAILS.**
MIG-3 established that Row A **as ruled** is VACUOUS: its stated hypothesis F2
(`Function.Injective encode`) is UNSATISFIABLE, because `State = Nat → BitVec 32` is infinite
and the machine state `St` is finite. **You cannot extend a row that does not hold where it
already stands** — an extension inherits the unsatisfiable hypothesis and is vacuous too.

⭐⭐ **AND THAT IS WHY THE VERDICT INVERTS RATHER THAN SIMPLY SAYING NO.** The vacuity is a
CARDINALITY fact, not a fact about compilers — `no_injective_of_infinite_to_finite` below. A
LAYER CONFIG is weights/routing for a **fixed** fabric, "exact in i32" (§6): finitely many
elements, each with a finite setting. ⇒ **THE SOURCE IS FINITE, SO THE PIGEONHOLE THAT KILLS
ROW A AT TINY-RUST DOES NOT APPLY, AND AN INJECTIVE ENCODING CAN EXIST.**

## ⇒ THE VERDICT, IN ONE LINE
**Rows A/B extend to layer configs in a way they DO NOT extend to tiny-Rust state — but the
extension is CONDITIONAL ON A COUNTING INEQUALITY THE SKETCH NEVER ASKS FOR**, and the
condition is exactly decidable rather than a matter of judgement:

  `card Config ≤ card MachineState` ⟺ an injective encoding exists  (`extends_iff_card_le`)

⛔ **SO F2 CHANGES STATUS, NOT TRUTH-VALUE: at tiny-Rust it is REFUTABLE; at layer configs it is
SATISFIABLE-BUT-UNPROVED.** It must be DISCHARGED by the counting fact, never assumed — and a
config space is exactly where "finite" quietly stops being true (unbounded layer count,
arbitrary-precision weights, a dynamically sized fabric). **Whoever takes A1 owes that count.**

⚠️ **AND THE SHAPE STILL NEEDS THE REPAIR THE CORPUS ALREADY CARRIES.** Even with F2 discharged,
the *conclusion* cannot be a state EQUALITY while the machine holds a `pc` and dirty scratch that
no encoding mentions (`CompileS.the_final_state_is_not_an_encoding`). The landed `encodeOK`
RELATION is the correct shape at both domains; §2's ruled text is what never caught up.
-/

namespace SaltWorks.HDL.MIG9
open SaltWorks.HDL.MIG3

/-- ⛔ **THE VACUITY IS STRUCTURAL, NOT AN ARTIFACT OF THE TINY-RUST TYPES.** No function from an
infinite source to a finite target is injective — so ANY correctness row carrying an injectivity
hypothesis on such a map is vacuous, at any domain, however it is dressed. This is the general
form of MIG-3's `no_injective_state_encoding`. -/
theorem no_injective_of_infinite_to_finite
    {α β : Type} [Infinite α] [Finite β] (f : α → β) : ¬ Function.Injective f := by
  intro hinj
  obtain ⟨a, b, hne, heq⟩ := Finite.exists_ne_map_eq_of_infinite f
  exact hne (hinj heq)

/-- ✅ **AND THE POSITIVE HALF, WHICH IS WHAT MAKES THE VERDICT AN INVERSION RATHER THAN A
REFUSAL.** Between FINITE types an injective encoding exists **exactly when** the counting
inequality holds. For layer configs the source is finite, so the question is decidable
arithmetic — not a judgement call, and not something to assume. -/
theorem extends_iff_card_le {α β : Type} [Fintype α] [Fintype β] :
    (∃ f : α → β, Function.Injective f) ↔ Fintype.card α ≤ Fintype.card β := by
  constructor
  · rintro ⟨f, hf⟩; exact Fintype.card_le_of_injective f hf
  · intro h
    obtain ⟨e⟩ := Function.Embedding.nonempty_of_card_le h
    exact ⟨e, e.injective⟩

end SaltWorks.HDL.MIG9

#print axioms SaltWorks.HDL.MIG9.no_injective_of_infinite_to_finite
#print axioms SaltWorks.HDL.MIG9.extends_iff_card_le
