/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.RotationInvariant

/-!
# ④ piece 4 — the skew bookkeeping

Design block: `docs/heritage-1988-rotation-design-v1.md` §2 piece 4, dispatched 18:14 as the
campaign's last wave.  Source: Marcus & Hickey, ISSCC 1990, WPM 2.4 — **words-only citation**.

## ⚠️ The symbolic/fixture split, labelled — which is the block's actual instruction

The block's disposition is explicit: *"state piece 4 SYMBOLICALLY over a free trace, PIN the
fixture at the tapeout instance, and name the driver's hardcoded 14 as the price of any ∀-D
claim — never let a symbolic statement and a hardcoded fixture sit unlabelled in one block."*
So, plainly:

* **SYMBOLIC (this file, `skew_ge_stage_count`)** — over a *free* list of per-stage offsets and
  a *free* stage count.  No fixture, no width, no destination range.
* **PINNED FIXTURE (`Cell1988`, already landed)** — `chain88_heals_with_three_cycle_offset`
  exhibits the `k = 3` tapeout instance: three real cells, gate by gate, all eight
  destinations, offset **exactly** three.
* ⛔ **NOT CLAIMED: any ∀-D statement.**  Its price is the driver — `runFrame`'s **hardcoded
  14** (`SaltWorks/HDL/PayloadL1.lean:40`, the ③ finding: *"the ∀-P price is the DRIVER … not
  the element"*).  The same driver shape bounds ④, so a ∀-D claim is not available here and is
  not made.  **This paragraph is the label the block asked for.**

## Where the lower bound comes from — a framework law, not a model number

The `+1`-cycle price was struck as a model artefact (§0's timing is twice-refuted and
`d_cell` stays symbolic) and then **revived on causality grounds**, which is a different and
stronger footing.  `Cell1988.zero_offset_rotation_is_impossible` says it for **every** `Seq`
machine from **every** initial state: a bit-serial rotate-by-1 cannot be realised at zero
offset, because the first output bit is the second input bit.

⇒ Every *rotating* stage costs at least one cycle.  The bookkeeping below is then arithmetic —
and that is the point: **`D` is bounded below by the rotating-stage count, and the bound is a
consequence of causality rather than of anybody's timing table.**

A1 again scopes it: a statically-passing cell moves no route bit and is not a rotating stage,
so `os` lists the *rotating* stages only.
-/

namespace SaltWorks.HDL

/-- The accumulated skew across a fabric: the per-stage output offsets, summed.
Free — no width, no fixture, no destination range. -/
def totalSkew (os : List Nat) : Nat := os.sum

@[simp] theorem totalSkew_nil : totalSkew [] = 0 := rfl

@[simp] theorem totalSkew_cons (o : Nat) (os : List Nat) :
    totalSkew (o :: os) = o + totalSkew os := rfl

/-- ⭐ **PIECE 4, THE SYMBOLIC STATEMENT.**  If every rotating stage costs at least one cycle
— which `zero_offset_rotation_is_impossible` forces for *any* machine, of any state width, from
any initial state — then the accumulated skew across the fabric is at least the number of
rotating stages.

`hfloor` is the causality floor **as a hypothesis**, so the arithmetic here never has to know
which machine supplies it. -/
theorem skew_ge_stage_count (os : List Nat) (hfloor : ∀ o ∈ os, 1 ≤ o) :
    os.length ≤ totalSkew os := by
  induction os with
  | nil => simp
  | cons o rest ih =>
      have h1 : 1 ≤ o := hfloor o (by simp)
      have hrest : ∀ x ∈ rest, 1 ≤ x := fun x hx => hfloor x (by simp [hx])
      have := ih hrest
      simp only [List.length_cons, totalSkew_cons]
      omega

/-- The same bound in the form a fabric of `m` rotating stages uses it: `m` stages, each at the
causality floor or worse, accumulate at least `m` cycles of skew. -/
theorem skew_ge_of_replicate_floor (m : Nat) (os : List Nat)
    (hlen : os.length = m) (hfloor : ∀ o ∈ os, 1 ≤ o) :
    m ≤ totalSkew os := by
  rw [← hlen]; exact skew_ge_stage_count os hfloor

/-- **The tapeout instance, pinned and labelled as a fixture.**  At `k = 3` every stage sits
exactly at the floor, so the accumulated skew is exactly three — and `Cell1988`'s
`chain88_heals_with_three_cycle_offset` is the *machine-level* exhibit of the same three, for
all eight destinations, gate by gate.  ⚠️ This is `k = 3`, not `∀ k`. -/
theorem tapeout_skew_is_three : totalSkew [1, 1, 1] = 3 := rfl

/-- The fixture meets the symbolic bound with equality: three stages at the floor cost exactly
three, so the lower bound is **attained**, not merely valid. -/
theorem tapeout_skew_attains_the_floor :
    ([1, 1, 1] : List Nat).length ≤ totalSkew [1, 1, 1]
      ∧ totalSkew [1, 1, 1] = ([1, 1, 1] : List Nat).length := by
  refine ⟨skew_ge_stage_count _ ?_, rfl⟩
  intro o ho
  fin_cases ho <;> omega

#audit_axioms totalSkew
#audit_axioms totalSkew_nil
#audit_axioms totalSkew_cons
#audit_axioms skew_ge_stage_count
#audit_axioms skew_ge_of_replicate_floor
#audit_axioms tapeout_skew_is_three
#audit_axioms tapeout_skew_attains_the_floor

end SaltWorks.HDL
