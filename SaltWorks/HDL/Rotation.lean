/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import Mathlib

/-!
# ④ piece 1 — the full circle: `rot^k = id`

Design block: `docs/heritage-1988-rotation-design-v1.md` (v2, `1f6f63e`), §2 piece 1.
Source: Marcus & Hickey, ISSCC 1990, WPM 2.4 — **WORDS-ONLY citation, never the figures**
(the block's standing firewall).

The 1990 banyan chip's cells each route on the leading address bit and then cycle that bit to
the end, so every cell reads the route bit in the *same fixed position*.  The paper states the
consequence itself, in §3.2 prose:

> "Each element routes on the first bit of the address, rotates the first bit to the end of the
> address, and moves the rest up.  The address will leave the banyan completely restored since
> it will have passed through a rotation for every bit of the address."

That is the theorem below — the Captain's *"full circle address rotation"*, literally
`rot^k = id`, certified 36 years after the silicon shipped.

## ⚠️ The named premise — and it is OURS, not the paper's

**The paper indexes restoration by ADDRESS LENGTH.  The block's claim is about the STAGE
COUNT.**  Identifying the two is this block's own assumption, so it appears as an explicit
hypothesis `hk : addr.length = k` rather than being spent silently by writing `addr.length`
everywhere.  Piece 3's second wave control (a length/stage-count mismatch) is live *precisely
because* this is a premise and not a definition.

It is load-bearing rather than decorative, and the witness is one line: a 4-bit address does
**not** heal in 3 stages (`rotStage^[3] [1,2,3,4] ≠ [1,2,3,4]`, by `decide`).

## The three ingredients (block §2, piece 1)

1. `rotStage_iterate` — fold `k` unit rotations into one, on mathlib's `List.rotate_rotate`;
2. `List.rotate_length` — the closing step;
3. the identification above, as the named premise `hk`.

`A`-class by the block's pricing, and it held: the heart is library.

## Assumption A1

The block's A1 (routing stages only) is what makes "one rotation per stage" the right count —
the paper's own cell dichotomy means a statically-passing cell moves no route bit.  A1 is not
consumed here: this file is about the rotation algebra, and `k` is whatever the caller proves
the routing-stage count to be.
-/

namespace SaltWorks.HDL

variable {α : Type*}

/-- **One banyan stage's action on the address**: the paper's *"rotates the first bit to the end
of the address, and moves the rest up"*.  mathlib's `List.rotate 1` is exactly that head-to-tail
move (`[1,2,3].rotate 1 = [2,3,1]`). -/
def rotStage (l : List α) : List α := l.rotate 1

@[simp] theorem rotStage_eq (l : List α) : rotStage l = l.rotate 1 := rfl

/-- **Ingredient 1 — `k` stages fold into one rotation by `k`.**  Each stage contributes a
single head-to-tail move, so passing through `n` of them rotates the address by `n`. -/
theorem rotStage_iterate (l : List α) (n : ℕ) : rotStage^[n] l = l.rotate n := by
  induction n with
  | zero => simp
  | succ m ih =>
      rw [Function.iterate_succ_apply', ih, rotStage_eq, List.rotate_rotate]

/-- **THE FULL CIRCLE — `rot^k = id`.**  An address of the stage-count length leaves the banyan
completely restored.

`hk : addr.length = k` is **the block's named premise**, not the paper's: the paper indexes
restoration by address length, and identifying that with the stage count `k` is ours to state.
-/
theorem rotate_full_circle (addr : List α) (k : ℕ) (hk : addr.length = k) :
    rotStage^[k] addr = addr := by
  rw [rotStage_iterate, ← hk, List.rotate_length]

/-- The same statement in the Captain's phrasing: on addresses of the stage-count length, the
`k`-fold stage map is the identity. -/
theorem rotStage_iterate_id (addr : List α) (k : ℕ) (hk : addr.length = k) :
    rotStage^[k] addr = id addr :=
  rotate_full_circle addr k hk

end SaltWorks.HDL
