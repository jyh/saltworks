import SaltWorks.HDL.SeamJoinA

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

This file proves why the landed comparator cannot simply be extended, and it is
the sharpest form of the seam I can state: **`cDestOf` is activity-blind.**
-/

namespace SaltWorks.HDL

/-- **An idle convention-C frame reads as destination 0** — the most-preferred
slot — because `cDestOf` samples only the address bits (1, 3, 5) and an idle
line holds all six header bits low. *Stated at every destination the sender
might have intended: an idle line bound for 7 is indistinguishable from an idle
line bound for 0, and from an ACTIVE line bound for 0.* -/
theorem cDestOf_idle_is_zero :
    ((List.range 8).all fun d =>
      cDestOf (cFrame false d [true, false]) == 0) = true := by decide +kernel

/-- ⭐ **THE COMPARATOR CANNOT SEE THE DISTINCTION CONCENTRATION DEPENDS ON.**
An idle line and an active line bound for 0 carry the same `cDestOf`. -/
theorem cDestOf_blind_to_activity :
    cDestOf (cFrame false 0 [true, false]) = cDestOf (cFrame true 0 [true, false]) := by
  decide +kernel

/-- ⛔ **AND THEREFORE `cDestOf ≤` IS THE ORDER THE CORPUS ALREADY REFUTED.**
Under it an idle line bound for 0 sorts at or before an active line bound for 7
— idle-sorts-low, which `ceC_rejects_idle_sorts_low` refutes at the element and
`cKey_partial_load_differs_from_dest` refutes at the key. *Both orderings sort;
only one concentrates. Extending the landed network theorem to partial load by
keeping its comparator would adopt the losing one.* -/
theorem cDestOf_order_is_idle_sorts_low :
    decide (cDestOf (cFrame false 0 [true, false])
            ≤ cDestOf (cFrame true 7 [true, false])) = true := by decide +kernel

/-- **The control: at FULL LOAD the same comparator is sound**, which is exactly
the regime `StageOK` restricts to. *So the landed theorem is not wrong — it is
narrow, and this pair of facts is the whole seam.* Companion to
`cKey_degenerates_at_full_load`. -/
theorem cDestOf_sound_at_full_load :
    ((List.range 8).all fun d => (List.range 8).all fun e =>
      decide (cDestOf (cFrame true d [true, false])
              ≤ cDestOf (cFrame true e [true, false])) == decide (d ≤ e)) = true := by
  decide +kernel

#audit_axioms cDestOf_idle_is_zero
#audit_axioms cDestOf_blind_to_activity
#audit_axioms cDestOf_order_is_idle_sorts_low
#audit_axioms cDestOf_sound_at_full_load

/-!
## The fixture — MEASURED, NOT KERNEL-CHECKED, and the distinction is the point

`docs/hdl-tools/` has no arm for this; the run is in the design block. Driving
`batcherNetC` with eight convention-C frames — five active (dest 5, 2, 7, 0, 3)
and three idle, `rst` high on cycle 0 only — the network emits the five actives
on wires 0..4 in destination order 0, 2, 3, 5, 7, each carrying the payload of
the line it entered on, and the three idles on wires 5, 6, 7.

⭐ **So the HARDWARE concentrates correctly at partial load.** The gap above is a
PROOF gap, not a defect — which is the good direction for it to be.

⚠️ **That paragraph is a `#eval`, i.e. COMPILED evaluation, and it is not a
theorem.** `decide +kernel` on `runTrace batcherNetC` over 14 cycles was killed
by the OS at 24 GB (EXIT=137) — 816 gates × 14 cycles of `run` is not a kernel
computation, and that is precisely why the corpus proves its network results
structurally (`bnC_output_frames_are_the_fold`) rather than by evaluation.
**A brute-force fixture is not available at this object's scale; the partial-load
network theorem has to be earned the same structural way.**
-/

end SaltWorks.HDL
