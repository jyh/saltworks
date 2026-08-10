import SaltWorks.HDL.SeamElement
import SaltWorks.HDL.SeamJoinA

/-!
# THE PARTIAL-LOAD LIFT — the keystone

The sort-then-route seam's remaining gap is that every element-level premise the
network induction consumes is proved at **full load**, where the two-field key
`(¬active, dest)` degenerates to plain `dest` (`cKey_degenerates_at_full_load`).
The NDF's traffic is partial: idle lines are normal, and concentration is the
whole point of sorting first.

**The network layer needs no work.** `bnC_output_frames_are_the_fold` takes the
comparator `le` as an explicit parameter, so the whole 24-instance fold is
already generic. `cDestOf` enters the chain at exactly one place —
`elemSortsAt_of_stage` — and the port lemmas it rests on
(`ceCPort_full_load_out0/1`) are *already stated in `cKeyLE` form*; the
degeneration to `cDestOf` happens only at a final `cKeyLE_full_load` rewrite.

So the lift reduces to the element's **header phase** off full load. That is
this file. Once the header decides, `ceC_body_mux` makes the payload phase a
static 2-permutation — which is why payload generality comes for free rather
than needing a quantifier over payloads.
-/

open SaltWorks.HDL

namespace SaltWorks.HDL.PartialLift

/-- The six header cycles over **both activities, independently** — 256
configurations against the full-load certificate's 64.

Two families are excluded, and each is excluded for a proved reason rather than
for convenience:

* **active vs active with the same destination** — the headers are bit-identical,
  nothing decides in the header window, and the element latches on payload bit 0
  (`ceC_pair_tie_splices_the_payload`). This is the hazard `StageOK`'s
  distinctness clause exists to prevent, and it must survive the weakening.
* **idle vs idle** — likewise never decides (`idle_idle_never_decides` below),
  but harmlessly: the two headers are *the same bits*
  (`idle_headers_are_identical`), so both ports carry the same header whatever
  the element does. -/
def ceHdrOKP : Bool :=
  [false, true].all fun a0 => (List.range 8).all fun d0 =>
  [false, true].all fun a1 => (List.range 8).all fun d1 =>
    (a0 && a1 && (d0 == d1)) || (!a0 && !a1) ||
    decide (runTrace ceC [false, false, false, false]
              (ceFrameTrace (ceHdr a0 d0) (ceHdr a1 d1))
            = (ceIL (if cKeyLE (cKey a0 d0) (cKey a1 d1) then ceHdr a0 d0
                     else ceHdr a1 d1)
                    (if cKeyLE (cKey a0 d0) (cKey a1 d1) then ceHdr a1 d1
                     else ceHdr a0 d0),
               [true, !(cKeyLE (cKey a0 d0) (cKey a1 d1)), false, a0 && a1]))

set_option maxRecDepth 8000 in
/-- ⭐⭐ **THE HEADER DECIDES AND ROUTES OFF FULL LOAD.** The element emits the
*routed* headers after six cycles and latches `decided`.

⚠️ **The `bothAct` state bit is `a0 && a1`, not `true`.** The full-load
statement's `true` is that regime's degenerate value; `decide` refuted the first
version of this theorem on exactly that component, which is the kind of thing a
transcribed statement shape hides. -/
theorem ceC_hdrOKP : ceHdrOKP = true := by decide +kernel

/-- **Why idle-vs-idle is excluded, measured rather than asserted:** it never
decides — the state after the header is still all-false. -/
theorem idle_idle_never_decides :
    ((runTrace ceC [false, false, false, false]
        (ceFrameTrace (ceHdr false 3) (ceHdr false 5))).2
      == [false, false, false, false]) = true := by decide +kernel

/-- **…and why that costs nothing:** two idle headers are the same bits, so an
undecided element still puts the right header on both ports. *An idle line is
silent — `cFrame_idle_is_silent` — so its destination field is not observable.* -/
theorem idle_headers_are_identical : ceHdr false 3 = ceHdr false 5 := by
  decide +kernel

/-- ⭐ **THE EXTRACTED FORM** — the partial-load analogue of
`ceC_header_routes`, ready for the port lemmas to consume. The two exclusions
appear as the two `Bool` hypotheses, in exactly the shape the invariant will
discharge them. -/
theorem ceC_header_routes_partial (a0 a1 : Bool) (d0 d1 : Nat)
    (h0 : d0 < 8) (h1 : d1 < 8)
    (hact : (a0 && a1 && (d0 == d1)) = false) (hidle : (!a0 && !a1) = false) :
    runTrace ceC [false, false, false, false]
        (ceFrameTrace (ceHdr a0 d0) (ceHdr a1 d1))
      = (ceIL (if cKeyLE (cKey a0 d0) (cKey a1 d1) then ceHdr a0 d0
               else ceHdr a1 d1)
              (if cKeyLE (cKey a0 d0) (cKey a1 d1) then ceHdr a1 d1
               else ceHdr a0 d0),
         [true, !(cKeyLE (cKey a0 d0) (cKey a1 d1)), false, a0 && a1]) := by
  have h := ceC_hdrOKP
  rw [ceHdrOKP] at h
  have hm0 : a0 ∈ [false, true] := by cases a0 <;> simp
  have hm1 : a1 ∈ [false, true] := by cases a1 <;> simp
  have hB := List.all_eq_true.mp
    (List.all_eq_true.mp
      (List.all_eq_true.mp
        (List.all_eq_true.mp h a0 hm0) d0 (List.mem_range.mpr h0))
      a1 hm1) d1 (List.mem_range.mpr h1)
  rw [hact, hidle] at hB
  simpa using hB

#audit_axioms ceC_hdrOKP
#audit_axioms idle_idle_never_decides
#audit_axioms idle_headers_are_identical
#audit_axioms ceC_header_routes_partial

end SaltWorks.HDL.PartialLift
