/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.StateCodec
import SaltWorks.HDL.Compose

/-!
# C4 — THE STATEMENT, WRITTEN BEFORE THE PROOF

**Math's 14:17: *"it wants to be a hypothesis of C4 or a lemma about `compile`,
and it should be written down BEFORE the proof, not after."*** *This file is that,
and it is deliberately a statement file: it contains the target, the obligations
that make the target meaningful, and controls showing each obligation bites. It
proves nothing about `core`, because `core` does not exist.*

## Why a predicate over an arbitrary `Circ` and not a theorem about `core`

`grep -rE "^(def|theorem|abbrev) (core|compile)\b"` over `SaltWorks/` returns
**nothing** — math's census, re-confirmed today. ⇒ **A theorem about `compile
core` cannot be written.** *But the SHAPE can, as a predicate any candidate must
satisfy, and writing it now is what stops the shape being negotiated later by
whoever happens to finish the construction.*

## ⛔ THE OBLIGATION THAT IS INVISIBLE TO THE TYPE SYSTEM

**Both sides of C4 are `List Bool` AT ANY LENGTH.** ⇒ ***A core one output short
yields a well-typed, FALSE theorem, and nothing in the elaborator notices.***
*Math flagged this at 14:17 and it is the reason `CoreConforms` exists as a
separate, checkable predicate rather than as a comment: the layout was pinned by
`StateCodec` in every dimension EXCEPT length, which is the one dimension a
positional `outs` list cannot carry in its type.*

## The netlist half is NOT here, and that is a result rather than an omission

`emitPipeline'_sem` takes `wf` as its only hypothesis and is fully general in
`c`; chained with `Circ.wf_of_ssa` it discharges the entire emission layer for
any `ssa` circuit. *So C4's remaining content is a pure compiler-correctness
statement with no netlist in it — math's decomposition, verified at the
signature before it was accepted.*
-/

namespace SaltWorks.HDL

open SaltWorks.ISA

/-! ### The conformance obligations -/

/-- **What `core` must satisfy for C4 to MEAN what it says.** Three conditions,
all decidable, none of them implied by C4's own type.

* `ssa` — feeds `Circ.wf_of_ssa` and thence the whole emission layer, and is the
  side condition `instOK` needs for the assembly to be sound.
* the input width — `core` reads the state and one instruction word.
* ⭐ **the output length — the one the type system cannot see.** -/
def CoreConforms (c : Circ) : Prop :=
  c.ssa = true ∧ c.nIn = coreInWidth ∧ c.outs.length = stWidth

instance (c : Circ) : Decidable (CoreConforms c) := by
  unfold CoreConforms; infer_instance

/-- The word `core` sees on its instruction nets. **Not `wordOf ins`** — that
reads nets `0…31`, which are register `x0` (`word_at_zero_is_register_x0`), and
it typechecks. -/
def seenWord (ins : Env) : BitVec 32 := wordOf (fun k => ins (instrNet k))

/-! ### The statement -/

/-- ⭐ **C4.** The compiled core's meaning is the ISA's transition, read through
the codec: `sem ∘ c` agrees with `encD ∘ stepT ∘ decQ`.

*The emission, renumbering, optimisation and flop-boundary layers are behind this
statement, not inside it — `emitPipeline'_sem` covers them generically for any
`ssa` circuit, so what remains is compiler correctness and nothing else.* -/
def C4Spec (c : Circ) : Prop :=
  ∀ ins : Env, sem c ins = encD (stepT (decQ ins) (seenWord ins))

/-- **C4 as it should be USED: the specification together with the conformance
that makes it meaningful.** *A `C4Spec` without `CoreConforms` is the well-typed
false theorem this file exists to prevent.* -/
structure C4 (c : Circ) : Prop where
  conforms : CoreConforms c
  spec     : C4Spec c

/-- Under conformance, both sides of C4 have length `stWidth` — which is the
sentence the type system was silent about. -/
theorem C4_lengths_agree {c : Circ} (h : CoreConforms c) (ins : Env) :
    (sem c ins).length = stWidth ∧ (encD (stepT (decQ ins) (seenWord ins))).length = stWidth := by
  constructor
  · rw [sem, List.length_map]; exact h.2.2
  · rw [encD, List.length_map, List.length_range]

-- The 1056-element `outs` lists below exceed the default elaboration depth.
-- NOTE the shape of the fix: `set_option ... in` immediately after a `/-- -/`
-- docstring is REJECTED — Lean wants the docstring on a declaration. That is the
-- same reflex this seat recorded four times on 8/7 for `/--` before `#check`,
-- arriving in a fifth costume. File-level `set_option` sidesteps it entirely.
set_option maxRecDepth 8000

/-! ### ⚠️ ONE CONJUNCT OF `CoreConforms` IS IMPLIED, NOT REQUIRED (math, 15:04)

*I wrote `outs.length = stWidth` in as a hypothesis on math's 14:17 flag, and
math then corrected their own brief: it is a CONSEQUENCE.* **`C4Spec` is an
equality of LISTS, and `encD`'s length is `stWidth` unconditionally — so one
`congrArg List.length` recovers it.**

⇒ ***So the conjunct is belt-and-braces rather than necessity.*** **It stays,
deliberately: `CoreConforms` is meant to be checkable on a CANDIDATE `core`
BEFORE anyone has proved `C4Spec` about it, and at that moment the implication
below is unavailable.** *A hypothesis that is redundant given the conclusion is
still load-bearing before the conclusion exists.* -/

/-- **The length obligation falls out of the specification itself.** -/
theorem outs_length_of_C4Spec {c : Circ} (h : C4Spec c) : c.outs.length = stWidth := by
  have := congrArg List.length (h (fun _ => false))
  rwa [sem, List.length_map, encD, List.length_map, List.length_range] at this

/-! ### CONTROLS — every obligation must be able to FAIL

*`CoreConforms` is a predicate I wrote about a circuit that does not exist yet.
The risk is that it is vacuous or unfalsifiable, so each conjunct gets a witness
that violates exactly it.* -/

/-- A circuit of the right shape in every respect except that it emits **one output
too few** — `stWidth - 1` instead of `stWidth`.

⛔ **THE WITNESS IS DERIVED FROM `stWidth`, AND THAT IS THE WHOLE POINT.** It was
hardcoded at `1055`, the off-by-one against a 1056-bit state. **A hardcoded witness
stops being an off-by-one the moment the width moves — while `coreShort_is_rejected`
below KEEPS PROVING, because a wrong count is still wrong.** *A control that keeps
passing for a NEW REASON is worse than one that breaks, because nothing announces it.*
At the width this landed on (1056) it reduced to `List.range 1055`, byte-for-byte the
old witness — **proved, not asserted: `stWidth - 1 = 1055` by `decide +kernel`** — so
the change was a NO-OP at landing and the difference appears only when `stWidth` moves.
*Phrased as history on purpose: a sentence saying "today" goes stale on the day it
describes, and this one is about a control whose entire defect was going stale.* Its sibling `coreNarrow` was already
derived; this row now matches it. -/
def coreShort : Circ :=
  { nIn := coreInWidth, gates := [], outs := List.range (stWidth - 1) }

/-- A circuit with the right output count and the wrong input width. -/
def coreNarrow : Circ :=
  { nIn := coreInWidth - 1, gates := [], outs := List.range stWidth }

/-- ⛔ **THE OFF-BY-ONE CORE IS REJECTED — and it is rejected by `CoreConforms`
alone, since nothing in C4's type distinguishes it.** *This is math's 14:17
hazard as a decided fact: `stWidth - 1` against `stWidth`, well-typed either way.
⭐ Stated in the DERIVED form deliberately — the witness above is derived, and a
docstring that re-pins it to literals would go stale at the width the definition
was just made to survive.* -/
theorem coreShort_is_rejected : ¬ CoreConforms coreShort := by decide +kernel

/-- ⛔ And the narrow core is rejected on the input width. -/
theorem coreNarrow_is_rejected : ¬ CoreConforms coreNarrow := by decide +kernel

/-- ✅ **The obligation is SATISFIABLE — a shape meeting all three exists**, so
`CoreConforms` is not accidentally empty. *This circuit is not `core` and computes
nothing useful; it exists to show the predicate can be met.* -/
def coreShaped : Circ :=
  { nIn := coreInWidth, gates := [], outs := List.range stWidth }

theorem coreShaped_conforms : CoreConforms coreShaped := by decide +kernel

/-- A second conforming circuit: one constant-true gate, every output reading it. -/
def coreShapedT : Circ :=
  { nIn   := coreInWidth
    gates := [⟨coreInWidth, .const true⟩]
    outs  := List.replicate stWidth coreInWidth }

theorem coreShapedT_conforms : CoreConforms coreShapedT := by decide +kernel

/-- ⛔ **CONFORMANCE DOES NOT DETERMINE SEMANTICS — two circuits satisfy every
structural obligation and compute different things.** *So at most one of them can
satisfy `C4Spec`, and the two fields of the `C4` structure are genuinely
independent: neither can be dropped, and passing `CoreConforms` says nothing
whatever about what the circuit computes.* -/
theorem conformance_does_not_determine_semantics :
    sem coreShaped (fun _ => false) ≠ sem coreShapedT (fun _ => false) := by
  decide +kernel

#audit_axioms CoreConforms seenWord C4Spec
#audit_axioms C4_lengths_agree
#audit_axioms outs_length_of_C4Spec
#audit_axioms coreShort coreNarrow coreShaped
#audit_axioms coreShort_is_rejected
#audit_axioms coreNarrow_is_rejected
#audit_axioms coreShaped_conforms
#audit_axioms coreShapedT coreShapedT_conforms
#audit_axioms conformance_does_not_determine_semantics

end SaltWorks.HDL
