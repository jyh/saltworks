/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.SeamElement
import SaltWorks.HDL.SeamJoinA
import SaltWorks.HDL.SeamJoinB

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

/-! ## The mirrors

Everything from here is the full-load chain with `true` replaced by `a0`/`a1`
and the final `cKeyLE_full_load` rewrite *omitted* — that rewrite is the only
place `cDestOf` ever entered. Each went through first try, which is the evidence
for calling the rest of the lift bookkeeping rather than content. -/

/-- The whole frame at partial load — the mirror of `ceC_pair_full_load`.
**Payload generality is free**: `cFrame_split` peels the header, the header
decides, and `ceC_body_mux` makes the rest a static 2-permutation. -/
theorem ceC_pair_partial (a0 a1 : Bool) (d0 d1 : Nat) (h0 : d0 < 8) (h1 : d1 < 8)
    (hact : (a0 && a1 && (d0 == d1)) = false) (hidle : (!a0 && !a1) = false)
    (p0 p1 : List Bool) :
    (runTrace ceC [false, false, false, false]
        (ceFrameTrace (cFrame a0 d0 p0) (cFrame a1 d1 p1))).1
      = ceIL (if cKeyLE (cKey a0 d0) (cKey a1 d1) then cFrame a0 d0 p0
              else cFrame a1 d1 p1)
             (if cKeyLE (cKey a0 d0) (cKey a1 d1) then cFrame a1 d1 p1
              else cFrame a0 d0 p0) := by
  rw [cFrame_split a0 d0 p0, cFrame_split a1 d1 p1,
      ceFrameTrace_append _ _ _ _ (ceHdr_ne_nil a0 d0)
        (by rw [ceHdr_length, ceHdr_length]),
      runTrace_append, ceC_header_routes_partial a0 a1 d0 d1 h0 h1 hact hidle]
  simp only [ceC_body_mux]
  cases hsw : cKeyLE (cKey a0 d0) (cKey a1 d1) with
  | false => exact ceIL_append _ _ _ _ rfl
  | true => exact ceIL_append _ _ _ _ rfl

theorem ceC_pair_partial_out0 (a0 a1 : Bool) (d0 d1 : Nat) (h0 : d0 < 8) (h1 : d1 < 8)
    (hact : (a0 && a1 && (d0 == d1)) = false) (hidle : (!a0 && !a1) = false)
    (p0 p1 : List Bool) (hp : p0.length = p1.length) :
    (runTrace ceC [false, false, false, false]
        (ceFrameTrace (cFrame a0 d0 p0) (cFrame a1 d1 p1))).1.map
        (fun o => o.getD 0 false)
      = if cKeyLE (cKey a0 d0) (cKey a1 d1) then cFrame a0 d0 p0
        else cFrame a1 d1 p1 := by
  rw [ceC_pair_partial a0 a1 d0 d1 h0 h1 hact hidle]
  refine ceIL_map_fst _ _ ?_
  cases cKeyLE (cKey a0 d0) (cKey a1 d1) <;> simp [cFrame_length, hp]

theorem ceC_pair_partial_out1 (a0 a1 : Bool) (d0 d1 : Nat) (h0 : d0 < 8) (h1 : d1 < 8)
    (hact : (a0 && a1 && (d0 == d1)) = false) (hidle : (!a0 && !a1) = false)
    (p0 p1 : List Bool) (hp : p0.length = p1.length) :
    (runTrace ceC [false, false, false, false]
        (ceFrameTrace (cFrame a0 d0 p0) (cFrame a1 d1 p1))).1.map
        (fun o => o.getD 1 false)
      = if cKeyLE (cKey a0 d0) (cKey a1 d1) then cFrame a1 d1 p1
        else cFrame a0 d0 p0 := by
  rw [ceC_pair_partial a0 a1 d0 d1 h0 h1 hact hidle]
  refine ceIL_map_snd _ _ ?_
  cases cKeyLE (cKey a0 d0) (cKey a1 d1) <;> simp [cFrame_length, hp]

/-- ⭐ **THE PORT FORM, FROM ANY INITIAL ELEMENT STATE** — the frame's own reset
cycle erases the state, so an interior comparator inherits nothing from the
previous frame. This is the shape `ElemSortsAt` consumes. -/
theorem ceCPort_partial_out0 (s : List Bool) (n : Nat) (a0 a1 : Bool) (d0 d1 : Nat)
    (h0 : d0 < 8) (h1 : d1 < 8)
    (hact : (a0 && a1 && (d0 == d1)) = false) (hidle : (!a0 && !a1) = false)
    (p0 p1 : List Bool) (hp : p0.length = p1.length)
    (hlen : (cFrame a0 d0 p0).length = n + 1) :
    ceCPort s (true :: List.replicate n false) (cFrame a0 d0 p0) (cFrame a1 d1 p1) 0
      = if cKeyLE (cKey a0 d0) (cKey a1 d1) then cFrame a0 d0 p0
        else cFrame a1 d1 p1 := by
  have hlen1 : (cFrame a1 d1 p1).length = n + 1 := by
    rw [cFrame_length] at hlen ⊢; omega
  rw [ceCPort, zip3Trace_rst_once n _ _ hlen hlen1,
      runTrace_ceC_frame_any_state s _ _ (cFrame_ne_nil a0 d0 p0)
        (cFrame_ne_nil a1 d1 p1)]
  exact ceC_pair_partial_out0 a0 a1 d0 d1 h0 h1 hact hidle p0 p1 hp

theorem ceCPort_partial_out1 (s : List Bool) (n : Nat) (a0 a1 : Bool) (d0 d1 : Nat)
    (h0 : d0 < 8) (h1 : d1 < 8)
    (hact : (a0 && a1 && (d0 == d1)) = false) (hidle : (!a0 && !a1) = false)
    (p0 p1 : List Bool) (hp : p0.length = p1.length)
    (hlen : (cFrame a0 d0 p0).length = n + 1) :
    ceCPort s (true :: List.replicate n false) (cFrame a0 d0 p0) (cFrame a1 d1 p1) 1
      = if cKeyLE (cKey a0 d0) (cKey a1 d1) then cFrame a1 d1 p1
        else cFrame a0 d0 p0 := by
  have hlen1 : (cFrame a1 d1 p1).length = n + 1 := by
    rw [cFrame_length] at hlen ⊢; omega
  rw [ceCPort, zip3Trace_rst_once n _ _ hlen hlen1,
      runTrace_ceC_frame_any_state s _ _ (cFrame_ne_nil a0 d0 p0)
        (cFrame_ne_nil a1 d1 p1)]
  exact ceC_pair_partial_out1 a0 a1 d0 d1 h0 h1 hact hidle p0 p1 hp

/-! ## (A) THE IDLE-VS-IDLE CASE

The keystone excludes idle-vs-idle because nothing ever decides there. That
costs nothing, and this is why: with both inputs carrying the same bit, both
ports carry that bit **whatever the state**, so `ElemSortsAt` holds at such a
comparator for ANY comparator function.

The invariant will pin idle lines to the *silent* (all-false) payload, which by
`cFrame_idle_is_silent` makes two idle frames literally the same bits — exactly
the hypothesis these lemmas need. -/

/-- Both output gates are `(!s && i0) || (s && i1)` and its mirror; at `i0 = i1`
each collapses to `i0` for either `s`, so the swap decision is invisible. -/
theorem ceC_step_identical (a b c d r x : Bool) :
    (stepSeq ceC [a, b, c, d] [r, x, x]).1 = [x, x] := by
  revert a b c d r x; decide +kernel

theorem ceC_step_state_length (st inp : List Bool) :
    (stepSeq ceC st inp).2.length = 4 := by
  simp [stepSeq, sem, ceC]
  decide +kernel

theorem ceC_state_is_four_bits {l : List Bool} (h : l.length = 4) :
    ∃ a b c d, l = [a, b, c, d] := by
  match l, h with
  | [a, b, c, d], _ => exact ⟨a, b, c, d, rfl⟩

/-- ⭐ **IDENTICAL INPUT STREAMS PASS STRAIGHT THROUGH, ON BOTH PORTS.** -/
theorem runTrace_ceC_identical (j : Nat) (hj : j < 2) :
    ∀ (r f st : List Bool), st.length = 4 → r.length = f.length →
      (runTrace ceC st (zip3Trace r f f)).1.map (fun o => o.getD j false) = f := by
  intro r
  induction r with
  | nil => intro f st _ hlen
           cases f with
           | nil => rfl
           | cons _ _ => simp at hlen
  | cons x xs ih =>
    intro f st hst hlen
    cases f with
    | nil => simp at hlen
    | cons y ys =>
      obtain ⟨a, b, c, d, rfl⟩ := ceC_state_is_four_bits hst
      rw [zip3Trace_cons]
      show (stepSeq ceC [a,b,c,d] [x,y,y]).1.getD j false ::
            (runTrace ceC (stepSeq ceC [a,b,c,d] [x,y,y]).2 (zip3Trace xs ys ys)).1.map
              (fun o => o.getD j false) = y :: ys
      rw [ceC_step_identical a b c d x y,
          ih ys _ (ceC_step_state_length _ _) (by simpa using hlen)]
      congr 1
      interval_cases j <;> rfl

/-- ⭐ **THE PORT FORM FOR AN IDLE-VS-IDLE COMPARATOR** — the state comes in at
length 4 from `bnCSlice_length`, and the conclusion holds for either port. -/
theorem ceCPort_identical (s : List Bool) (hs : s.length = 4) (r f : List Bool)
    (hlen : r.length = f.length) (j : Nat) (hj : j < 2) :
    ceCPort s r f f j = f := by
  rw [ceCPort]
  exact runTrace_ceC_identical j hj r f s hs hlen

/-! ## (B) THE INVARIANT AND (D) THE PER-STAGE LEMMA -/

/-- The key a frame actually presents: its activity bit and its decoded
destination. -/
def cKeyOfFrame (f : List Bool) : Bool × Nat := (!(f.getD 0 false), cDestOf f)

/-- The comparator the partial-load chain concludes in — the two-field key,
never `cDestOf` alone. -/
def frameLE (x y : List Bool) : Bool := cKeyLE (cKeyOfFrame x) (cKeyOfFrame y)

/-- An idle line is silent: `cFrame_idle_is_silent`, and its destination field
is unobservable anyway (`ceC_idle_dest_is_unobservable`), so the invariant pins
it to 0. -/
def SilentIdle (L : Nat) : List Bool := cFrame false 0 (List.replicate L false)

/-- A frame's leading bit IS its activity bit. -/
theorem cFrame_getD0 (a : Bool) (d : Nat) (p : List Bool) :
    (cFrame a d p).getD 0 false = a := rfl

theorem cKeyOfFrame_active (d : Nat) (hd : d < 8) (p : List Bool) :
    cKeyOfFrame (cFrame true d p) = cKey true d := by
  rw [cKeyOfFrame, cKey, cFrame_getD0, cDestOf_cFrame d hd p]

theorem cKeyOfFrame_idle (L : Nat) : cKeyOfFrame (SilentIdle L) = cKey false 0 := by
  rw [SilentIdle, cKeyOfFrame, cKey, cFrame_getD0, cDestOf_idle_is_zero]

/-- **The frame invariant at partial load.** Every wire carries either an ACTIVE
frame or the SILENT idle frame; and any two distinct wires carrying ACTIVE
frames carry distinct destinations.

⚠️ The active-distinctness clause is load-bearing exactly as `StageOK`'s was:
`ceC_pair_tie_splices_the_payload` shows a genuine active tie misroutes, and
invisibly to any header-level invariant. What is dropped is only the demand that
every wire be active — the clause `cDestOf_idle_is_zero` made unsatisfiable the
moment two lines went idle. -/
def PartialStageOK (st : List Bool) (tr : List (List Bool)) (L k : Nat) : Prop :=
  (∀ w, w < 8 →
      (∃ d p, d < 8 ∧ p.length = L ∧ bnCFrameAt st tr k w = cFrame true d p)
      ∨ bnCFrameAt st tr k w = SilentIdle L)
  ∧ (∀ w₁ w₂, w₁ < 8 → w₂ < 8 → w₁ ≠ w₂ →
      ∀ d₁ p₁ d₂ p₂, bnCFrameAt st tr k w₁ = cFrame true d₁ p₁ →
        bnCFrameAt st tr k w₂ = cFrame true d₂ p₂ → d₁ ≠ d₂)

/-- ⭐⭐⭐ **`ElemSortsAt` AT PARTIAL LOAD, under `frameLE`.** The three cases a
comparator can see are discharged by the three element lemmas: two actives and
active-vs-idle by `ceCPort_partial_out0/1`, idle-vs-idle by `ceCPort_identical`. -/
theorem elemSortsAt_of_partial_stage (st : List Bool) (tr : List (List Bool))
    (n L k : Nat) (hk : k < 24)
    (hrst : tr.map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (hSt : PartialStageOK st tr L k) :
    ElemSortsAt st tr k frameLE := by
  obtain ⟨hframes, hdist⟩ := hSt
  have ha : (bnCCompAt k).1 < 8 := (bnComps_lt_eight _ (bnCCompAt_mem k hk)).1
  have hb : (bnCCompAt k).2 < 8 := (bnComps_lt_eight _ (bnCCompAt_mem k hk)).2
  have hab : (bnCCompAt k).1 ≠ (bnCCompAt k).2 := bnCCompAt_ne k hk
  have htr : tr.length = n + 1 := by
    have h := congrArg List.length hrst; simpa using h
  -- the two frames, each active or silent-idle
  have hlenAny : ∀ w, (bnCFrameAt st tr k w).length = n + 1 := by
    intro w; rw [bnCFrameAt_length, htr]
  rcases hframes _ ha with ⟨da, pa, hda, hpa, hfa⟩ | hfa <;>
    rcases hframes _ hb with ⟨db, pb, hdb, hpb, hfb⟩ | hfb
  · -- ACTIVE vs ACTIVE, distinct destinations
    have hne : da ≠ db := hdist _ _ ha hb hab da pa db pb hfa hfb
    have hlenA : (cFrame true da pa).length = n + 1 := by rw [← hfa]; exact hlenAny _
    have hpab : pa.length = pb.length := by rw [hpa, hpb]
    have hkey : frameLE (bnCFrameAt st tr k (bnCCompAt k).1)
                        (bnCFrameAt st tr k (bnCCompAt k).2)
        = cKeyLE (cKey true da) (cKey true db) := by
      rw [frameLE, hfa, hfb, cKeyOfFrame_active da hda pa, cKeyOfFrame_active db hdb pb]
    refine ⟨?_, ?_⟩
    · rw [hkey, hfa, hfb, hrst,
          ceCPort_partial_out0 (bnCSlice st k) n true true da db hda hdb
            (by simp [hne]) (by simp) pa pb hpab hlenA]
    · rw [hkey, hfa, hfb, hrst,
          ceCPort_partial_out1 (bnCSlice st k) n true true da db hda hdb
            (by simp [hne]) (by simp) pa pb hpab hlenA]
  · -- ACTIVE vs IDLE
    have hlenA : (cFrame true da pa).length = n + 1 := by rw [← hfa]; exact hlenAny _
    have hlenB : (SilentIdle L).length = n + 1 := by rw [← hfb]; exact hlenAny _
    have hpab : pa.length = (List.replicate L false).length := by
      rw [hpa, List.length_replicate]
    have hkey : frameLE (bnCFrameAt st tr k (bnCCompAt k).1)
                        (bnCFrameAt st tr k (bnCCompAt k).2)
        = cKeyLE (cKey true da) (cKey false 0) := by
      rw [frameLE, hfa, hfb, cKeyOfFrame_active da hda pa, cKeyOfFrame_idle L]
    refine ⟨?_, ?_⟩
    · rw [hkey, hfa, hfb, hrst, SilentIdle,
          ceCPort_partial_out0 (bnCSlice st k) n true false da 0 hda (by omega)
            (by simp) (by simp) pa _ hpab hlenA]
    · rw [hkey, hfa, hfb, hrst, SilentIdle,
          ceCPort_partial_out1 (bnCSlice st k) n true false da 0 hda (by omega)
            (by simp) (by simp) pa _ hpab hlenA]
  · -- IDLE vs ACTIVE
    have hlenA : (SilentIdle L).length = n + 1 := by rw [← hfa]; exact hlenAny _
    have hpab : (List.replicate L false).length = pb.length := by
      rw [hpb, List.length_replicate]
    have hkey : frameLE (bnCFrameAt st tr k (bnCCompAt k).1)
                        (bnCFrameAt st tr k (bnCCompAt k).2)
        = cKeyLE (cKey false 0) (cKey true db) := by
      rw [frameLE, hfa, hfb, cKeyOfFrame_idle L, cKeyOfFrame_active db hdb pb]
    refine ⟨?_, ?_⟩
    · rw [hkey, hfa, hfb, hrst, SilentIdle,
          ceCPort_partial_out0 (bnCSlice st k) n false true 0 db (by omega) hdb
            (by simp) (by simp) _ pb hpab hlenA]
    · rw [hkey, hfa, hfb, hrst, SilentIdle,
          ceCPort_partial_out1 (bnCSlice st k) n false true 0 db (by omega) hdb
            (by simp) (by simp) _ pb hpab hlenA]
  · -- IDLE vs IDLE — the swap decision is invisible, so ANY comparator works
    have hlenA : (SilentIdle L).length = n + 1 := by rw [← hfa]; exact hlenAny _
    have hrl : (true :: List.replicate n false).length = (SilentIdle L).length := by
      rw [hlenA]; simp
    refine ⟨?_, ?_⟩ <;>
      rw [hfa, hfb, hrst,
          ceCPort_identical (bnCSlice st k) (bnCSlice_length st k) _ _ hrl _ (by omega)] <;>
      simp

/-! ## (C) PRESERVATION — and the payoff -/

/-- (C) **PRESERVATION.** A comparator permutes the two frames on its own wires
and leaves the other six alone, so both clauses of the invariant transport along
`σ`. `frames_succ_perm` supplies the permutation and — like every other object in
this chain — takes the comparator as a parameter. -/
theorem partialStageOK_succ (st : List Bool) (tr : List (List Bool)) (n L k : Nat)
    (hk : k < 24)
    (hrst : tr.map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (hSt : PartialStageOK st tr L k) :
    PartialStageOK st tr L (k + 1) := by
  obtain ⟨σ, hσlt, hσinj, hσeq⟩ :=
    frames_succ_perm st tr k hk _ (elemSortsAt_of_partial_stage st tr n L k hk hrst hSt)
  obtain ⟨hframes, hdist⟩ := hSt
  refine ⟨?_, ?_⟩
  · intro w hw
    rw [hσeq w]
    exact hframes _ (hσlt w hw)
  · intro w₁ w₂ hw₁ hw₂ hne d₁ p₁ d₂ p₂ h₁ h₂
    rw [hσeq w₁] at h₁
    rw [hσeq w₂] at h₂
    exact hdist _ _ (hσlt w₁ hw₁) (hσlt w₂ hw₂) (hσinj w₁ w₂ hw₁ hw₂ hne) d₁ p₁ d₂ p₂ h₁ h₂

theorem partialStageOK_all (st : List Bool) (tr : List (List Bool)) (n L : Nat)
    (hrst : tr.map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (h0 : PartialStageOK st tr L 0) :
    ∀ k, k ≤ 24 → PartialStageOK st tr L k := by
  intro k
  induction k with
  | zero => intro _; exact h0
  | succ m ih =>
    intro hm
    exact partialStageOK_succ st tr n L m (by omega) hrst (ih (by omega))

theorem elemSortsAt_all_partial (st : List Bool) (tr : List (List Bool)) (n L : Nat)
    (hrst : tr.map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (h0 : PartialStageOK st tr L 0) :
    ∀ k, k < 24 → ElemSortsAt st tr k frameLE := by
  intro k hk
  exact elemSortsAt_of_partial_stage st tr n L k hk hrst
    (partialStageOK_all st tr n L hrst h0 k (by omega))

/-- ⭐⭐⭐ **THE NETLIST REFINES THE ABSTRACT FOLD AT PARTIAL LOAD, UNDER THE
TWO-FIELD KEY** — from a condition on the caller's trace alone, with idle lines
permitted throughout.

⚠️ **This does NOT say "the Batcher sorts".** Its nouns are `runTrace
batcherNetC` and `runNetF frameLE bnComps`: it says the 24-instance NETLIST
computes what the abstract comparator fold computes. *Whether that fold sorts is
a separate statement about `bnComps` as a sorting network, and connecting it to
math's `cSorted` (= `runNet batcher8 (cKey act dst)`) is a further seam.* **What
is closed here is the refinement, which is the half that was owed.** -/
theorem bnC_output_frames_partial (st : List Bool) (tr : List (List Bool)) (n L : Nat)
    (hrst : tr.map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (h0 : PartialStageOK st tr L 0) (w : Nat) (hw : w < 8) :
    (runTrace batcherNetC st tr).1.map (fun o => o.getD w false)
      = runNetF frameLE bnComps (fun i => bnCFrameAt st tr 0 i) w :=
  bnC_output_frames_are_the_fold st tr frameLE
    (elemSortsAt_all_partial st tr n L hrst h0) w hw

/-! ## THE KEY LEVEL — the form math's abstract layer consumes -/

/-- The two-field key `(¬active, dest)` encoded as a single `Nat`. Sound because
`cDestOf` is three bits for ANY stream (`cDestOf_lt_eight`, no hypotheses), so
the 8-weighted activity bit dominates the destination exactly as the product
order does. -/
def natKey (f : List Bool) : Nat := (if f.getD 0 false then 0 else 8) + cDestOf f

/-- ⭐ **THE `cKey` ORDER *IS* THE `natKey` ORDER** — the two-field lexicographic
key and the single-`Nat` key are the same object at two radixes, `cKey`'s
activity field being the high bit of a base-8 numeral. *(Math's framing, 11:54,
better than the one this proof was written under.)*

📌 **THIS DISCHARGES THE SORT-THEN-ROUTE SEAM'S ORDER-PRESERVATION OBLIGATION.**
It was first landed as unadvertised scaffolding under the name `key_bridge`,
which named neither of its nouns — so a peer searching for "cKey order ≡ natKey
order" could not find it, and listed it as owed while its name sat in their own
terminal output. Renamed so the search that needs it will hit it.

Proved about ABSTRACT data — no frames, no `getD`, hence no stuck decidable
instances; the frame-level statement is an instantiation. -/
theorem cKey_order_is_natKey_order (ax ay : Bool) (dx dy : Nat) (hx : dx < 8) (hy : dy < 8) :
    cKeyLE (!ax, dx) (!ay, dy)
      = decide ((if ax then 0 else 8) + dx ≤ (if ay then 0 else 8) + dy) := by
  cases ax <;> cases ay <;> simp [cKeyLE] <;> omega

theorem frameLE_eq_natKey (x y : List Bool) :
    frameLE x y = decide (natKey x ≤ natKey y) :=
  cKey_order_is_natKey_order _ _ _ _ (cDestOf_lt_eight x) (cDestOf_lt_eight y)

theorem frameLE_eq : frameLE = fun x y => decide (natKey x ≤ natKey y) := by
  funext x y; exact frameLE_eq_natKey x y

/-- ⭐⭐⭐ **THE KEY-LEVEL STATEMENT AT PARTIAL LOAD** — the form math's abstract
layer consumes. The netlist's output key on wire `w` is the abstract `runNetN`
fold of the input keys. -/
theorem bnC_output_keys_partial (st : List Bool) (tr : List (List Bool)) (n L : Nat)
    (hrst : tr.map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (h0 : PartialStageOK st tr L 0) (w : Nat) (hw : w < 8) :
    natKey ((runTrace batcherNetC st tr).1.map (fun o => o.getD w false))
      = runNetN bnComps (fun i => natKey (bnCFrameAt st tr 0 i)) w := by
  refine bnC_output_keys_are_runNetN st tr natKey ?_ w hw
  intro k hk
  have h := elemSortsAt_all_partial st tr n L hrst h0 k hk
  rw [frameLE_eq] at h
  exact h

#audit_axioms natKey
#audit_axioms cKey_order_is_natKey_order
#audit_axioms frameLE_eq_natKey
#audit_axioms bnC_output_keys_partial
#audit_axioms partialStageOK_succ
#audit_axioms partialStageOK_all
#audit_axioms elemSortsAt_all_partial
#audit_axioms bnC_output_frames_partial
#audit_axioms cFrame_getD0
#audit_axioms cKeyOfFrame_active
#audit_axioms cKeyOfFrame_idle
#audit_axioms elemSortsAt_of_partial_stage
#audit_axioms ceC_step_identical
#audit_axioms ceC_step_state_length
#audit_axioms runTrace_ceC_identical
#audit_axioms ceCPort_identical
#audit_axioms ceC_hdrOKP
#audit_axioms idle_idle_never_decides
#audit_axioms idle_headers_are_identical
#audit_axioms ceC_header_routes_partial
#audit_axioms ceC_pair_partial
#audit_axioms ceC_pair_partial_out0
#audit_axioms ceC_pair_partial_out1
#audit_axioms ceCPort_partial_out0
#audit_axioms ceCPort_partial_out1

end SaltWorks.HDL.PartialLift
