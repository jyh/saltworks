import SaltWorks.HDL.SeamJoinA
import SaltWorks.HDL.SeamJoinB

/-!
# THE SORTER SEAM, LOCATED — and it is the PARTIAL-LOAD gap

The sort-then-route seam is not an order tie waiting to be written. The
element-level tie is landed (`ceC_realises_cKey_when_active`), the abstract
sort is landed (math's `cSorted_*`), and there IS a network-level theorem —
`bnC_output_frames_driven`, whose conclusion is `runNetF (cDestOf · ≤ cDestOf ·)`.

**The gap is that the network theorem's hypothesis is FULL LOAD.** `StageOK`'s
first clause demands `bnCFrameAt … w = cFrame true d p` on **every** wire, and
its second demands distinct destinations. So the landed statement covers a
permutation of eight active lines — and the NDF's actual traffic is partial:
idle lines are the normal case, and concentration is the whole point.

## ⛔ WHAT THIS FILE ORIGINALLY GOT WRONG

Its first version proved `cDestOf_idle_is_zero` from scratch, over a sample of
eight destinations at one fixed payload. **`SeamJoinB.lean:54` already had it,
`∀ d p`, by `rfl`** — and that theorem's own docstring already draws the
consequence I posted as a finding: *"every idle frame decodes to 0, so partial
load makes the input key vector non-injective."* The duplicate declaration was
invisible to a standalone module build and broke the hub on import.

Everything below is now **derived from the landed general lemmas** instead of
re-decided, and each statement is stronger for it (arbitrary payloads, all
destinations) while claiming less novelty.
-/

namespace SaltWorks.HDL

/-- ⭐ **THE COMPARATOR CANNOT SEE THE DISTINCTION CONCENTRATION DEPENDS ON.**
An idle line and an active line bound for 0 carry the same `cDestOf`, for every
intended destination and every payload. *Immediate from `cDestOf_idle_is_zero`
(SeamJoinB) and `cDestOf_cFrame`; stated here because it is the form the seam
argument consumes.* -/
theorem cDestOf_blind_to_activity (d : Nat) (p : List Bool) :
    cDestOf (cFrame false d p) = cDestOf (cFrame true 0 p) := by
  rw [cDestOf_idle_is_zero, cDestOf_cFrame 0 (by omega) p]

/-- ⛔ **AND THEREFORE `cDestOf ≤` IS THE ORDER THE CORPUS ALREADY REFUTED.**
An idle line sorts at or before EVERY active line — idle-sorts-low, which
`ceC_rejects_idle_sorts_low` refutes at the element and
`cKey_partial_load_differs_from_dest` refutes at the key. *Both orderings sort;
only one concentrates. Extending the landed network theorem to partial load by
keeping its comparator would adopt the losing one.* -/
theorem cDestOf_order_is_idle_sorts_low (d e : Nat) (he : e < 8) (p q : List Bool) :
    cDestOf (cFrame false d p) ≤ cDestOf (cFrame true e q) := by
  rw [cDestOf_idle_is_zero, cDestOf_cFrame e he q]
  exact Nat.zero_le e

/-- **The control: at FULL LOAD the same comparator is sound**, which is exactly
the regime `StageOK` restricts to. *So the landed theorem is not wrong — it is
narrow, and this pair of facts is the whole seam.* Companion to
`cKey_degenerates_at_full_load`. -/
theorem cDestOf_sound_at_full_load (d e : Nat) (hd : d < 8) (he : e < 8)
    (p q : List Bool) :
    decide (cDestOf (cFrame true d p) ≤ cDestOf (cFrame true e q)) = decide (d ≤ e) := by
  rw [cDestOf_cFrame d hd p, cDestOf_cFrame e he q]

#audit_axioms cDestOf_blind_to_activity
#audit_axioms cDestOf_order_is_idle_sorts_low
#audit_axioms cDestOf_sound_at_full_load

/-!
## The fixture — MEASURED, NOT KERNEL-CHECKED, and the distinction is the point

Driving `batcherNetC` with eight convention-C frames — five active (dest 5, 2,
7, 0, 3) and three idle, `rst` high on cycle 0 only — the network emits the five
actives on wires 0..4 in destination order 0, 2, 3, 5, 7, each carrying the
payload of the line it entered on, and the three idles on wires 5, 6, 7.

⭐ **So the HARDWARE concentrates correctly at partial load.** The gap above is a
PROOF gap, not a defect — which is the good direction for it to be.

⚠️ **That paragraph is a `#eval`, i.e. COMPILED evaluation, and it is not a
theorem.** `decide +kernel` on `runTrace batcherNetC` over 14 cycles was killed
by the OS at 24 GB (EXIT=137) — 816 gates × 14 cycles of `run` is not a kernel
computation, and that is precisely why the corpus proves its network results
structurally (`bnC_output_frames_are_the_fold`) rather than by evaluation.
-/

end SaltWorks.HDL
