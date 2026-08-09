/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Rotation
import SaltWorks.HDL.Cell1988

/-!
# ④ piece 3 — the rotation invariant (the soul)

Design block: `docs/heritage-1988-rotation-design-v1.md` §2 piece 3.  Dispatched 18:08 over
**`Cell1988`'s landed semantics** (pieces 2/5, `499360d`).  Source: Marcus & Hickey, ISSCC 1990,
WPM 2.4 — **words-only citation, never the figures**.

The block's sentence, and this file's content:

> under A1, for every VALID packet, the header at stage `m` = the original address rotated by
> `m`; hence the bit each stage reads in its FIXED position is original bit `k−1−m`.

## The four discipline constraints, each visible in the statements

* **VALIDITY-ANTECEDENT, not a binder.** `v = true` is a hypothesis. There is no "in-flight"
  predicate — that was the σ-strike disease, and an idle line is already covered by
  `cell88_idle_is_silent`.
* **ONE-DIRECTIONAL.** We state *stage `m` ⇒ rotated by `m`*, never the converse.  Recovering
  `m` from a healed header would need `Nodup.rotate_eq_self_iff`, and an address BIT-list is
  never `Nodup` for `k ≥ 3` by pigeonhole (`[true,false,true]` is a witness), so a
  characterization is **unavailable, not merely unneeded**.
* **NO PACKET INDEX.** No statement here is indexed by packet; a packet index smuggles a
  per-stage `σ`, the priced `C`-class object the block bars.
* **A1** (routing stages only) is the caller's, exactly as in piece 1: a statically-passing
  cell moves no route bit, so `m` counts *routing* stages.

## ⚠️ `k = 3` is not a simplification — it is `Cell1988`'s frame language

`addr88 v d = [v && d.testBit 2, v && d.testBit 1, v && d.testBit 0]` is a **3-bit, MSB-first**
address, so everything here is at `k = 3` concretely.  Two consequences, both load-bearing:

1. **MSB-first is what makes list index `m` equal numeric bit `k−1−m`.**  That identification is
   the whole content of `stage_reads_original_bit` — at `k = 3`, list position `m` is
   `d.testBit (2 - m)`.
2. **The block's BARRED PAIR is live here**: at `k = 3`, `rotate 2` and `rotate (k−1)` are the
   *same* mutation, so they may not be run as two independent controls.  The wave controls used
   are therefore (1) a non-uniform schedule with `Σrᵢ ≢ 0 (mod 3)` and (2) a length/stage-count
   mismatch — the barred-pair-fixed pair the block specifies.

⚠️ Measured during the pre-flight and worth carrying: **"non-uniform" is NOT the operative
condition in control (1)** — the schedule `[1,1,2]` at `k = 4` is non-uniform, sums to `≡ 0`,
and heals.  `Σrᵢ ≢ 0 (mod k)` is the discriminator.
-/

namespace SaltWorks.HDL

/-- **The header after `m` rotating stages.**  No packet index, by design. -/
def hdr88 (v : Bool) (d : Nat) (m : Nat) : List Bool := (addr88 v d).rotate m

@[simp] theorem hdr88_zero (v : Bool) (d : Nat) : hdr88 v d 0 = addr88 v d := by
  simp [hdr88]

/-- Each stage advances the header by exactly one head-to-tail move — the cell's own action,
`rotStage` from piece 1. -/
theorem hdr88_succ (v : Bool) (d : Nat) (m : Nat) :
    hdr88 v d (m + 1) = rotStage (hdr88 v d m) := by
  simp [hdr88, rotStage, List.rotate_rotate]

/-- **The invariant, in iterate form**: the header at stage `m` is the original address put
through `m` stages. -/
theorem hdr88_eq_iterate (v : Bool) (d : Nat) (m : Nat) :
    hdr88 v d m = rotStage^[m] (addr88 v d) := by
  rw [rotStage_iterate]; rfl

/-- The address field is 3 bits — `Cell1988`'s frame language. -/
@[simp] theorem addr88_length (v : Bool) (d : Nat) : (addr88 v d).length = 3 := rfl

/-- **The full circle, instantiated at the fabric's own width.**  Piece 1's `rot^k = id` with
its named premise discharged by `addr88_length`: three routing stages restore the address. -/
theorem hdr88_full_circle (v : Bool) (d : Nat) : hdr88 v d 3 = addr88 v d := by
  rw [hdr88_eq_iterate]
  exact rotate_full_circle (addr88 v d) 3 (addr88_length v d)

/-- ⭐ **THE SOUL — the bit each stage reads in its FIXED position is original bit `k−1−m`.**

The cell routes on the head of the header (`cell88_routes_on_first_address_bit` reads exactly
that bit off the pins at stage 0).  At stage `m` the head is the `m`-th list entry of the
original address, and MSB-first framing makes that numeric bit `2 - m`.

`hv : v = true` is the **validity antecedent**; stated one-directionally. -/
theorem stage_reads_original_bit (v : Bool) (d : Nat) (m : Nat) (hv : v = true) (hm : m < 3) :
    (hdr88 v d m).head? = some (d.testBit (2 - m)) := by
  subst hv
  interval_cases m <;> simp [hdr88, addr88]

/-- The link to the cell's own forwarded frame: what `Cell1988` forwards carries exactly the
stage-1 header.  (`cell88_rotates_with_one_cycle_offset` is the kernel-checked statement that
the hardware does this; this is the bookkeeping that names it as the invariant's step.) -/
theorem rotFrame88_hdr (v : Bool) (d : Nat) (p : List Bool) :
    rotFrame88 v d p = (v :: hdr88 v d 1) ++ p := rfl

/-! ### Wave control (1), landed rather than left in scratch

The block's control is *"a NON-UNIFORM schedule with `Σrᵢ ≢ 0 (mod k)`"*.  Both halves are
load-bearing, and the pre-flight measured that **the first half alone is not a control** — a
non-uniform schedule whose amounts sum to `≡ 0` heals.  Both facts are put in the kernel here so
the next reader inherits the discriminator rather than the short reading.

Neither row is the block's BARRED PAIR: the bar forbids running `rotate 2` and `rotate (k−1)`
as two *independent* controls at `k = 3`, and these are one live schedule and one vacuous one. -/

/-- A schedule of per-stage rotation amounts, applied in order. -/
def applySchedule (l : List Bool) (rs : List Nat) : List Bool :=
  rs.foldl (fun a r => a.rotate r) l

/-- **The LIVE control**: the non-uniform schedule `[1,1]` at `k = 3` sums to `2 ≢ 0 (mod 3)`
and does **not** heal. -/
theorem schedule_11_does_not_heal :
    applySchedule (addr88 true 4) [1, 1] ≠ addr88 true 4 := by decide

/-- ⚠️ **The VACUOUS one, and this is why "non-uniform" is not the condition**: `[1,2]` is
non-uniform, sums to `3 ≡ 0 (mod 3)`, and **heals**.  `Σrᵢ ≢ 0 (mod k)` is the discriminator. -/
theorem schedule_12_heals :
    applySchedule (addr88 true 4) [1, 2] = addr88 true 4 := by decide

#audit_axioms hdr88
#audit_axioms hdr88_zero
#audit_axioms hdr88_succ
#audit_axioms hdr88_eq_iterate
#audit_axioms addr88_length
#audit_axioms hdr88_full_circle
#audit_axioms stage_reads_original_bit
#audit_axioms rotFrame88_hdr
#audit_axioms applySchedule
#audit_axioms schedule_11_does_not_heal
#audit_axioms schedule_12_heals

end SaltWorks.HDL
