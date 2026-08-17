/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.SeamElement

/-!
# JOIN A — THE FRAME INVARIANT, and `ElemSortsAt` discharged from it.

SCRATCH. DO NOT COMMIT. Executor A's file.

Both halves of the seam are landed:
* `SeamTrace.lean` — the network ladder, with `ElemSortsAt` **assumed**;
* `SeamElement.lean` — the element at full load, **proved**.

The gap was two hypotheses, neither about the circuit:
1. the **rst column** — the network drives the element with `tr.map (·.getD 0)`,
   the element theorem with `ceFrameTrace` (whose cycle 0 is `[true,x,y]`);
2. the **frame invariant** — `ElemSortsAt` is on arbitrary `List Bool`, the
   element theorem wants `cFrame true d p`.

(1) is a condition on the CALLER'S TRACE and is taken as a hypothesis here.
(2) is INDUCTIVE and is proved here: `ceC_pair_full_load_any_state`'s conclusion
is that the element's two outputs ARE its two inputs REORDERED, so the whole
stage-`k+1` frame vector is a PERMUTATION of the stage-`k` one — which is what
makes both "every wire carries a well-formed frame" and "the eight destinations
are pairwise distinct" (⚠️ `hne` is load-bearing) survive the step.
-/

namespace SaltWorks.HDL

set_option maxRecDepth 8000

/-! ## 0. The destination read-out

`cDestOf` is the `key : List Bool → ℕ` that `bnC_output_keys_are_runNetN` is
parametric in. (⚠️ `ScratchFrameB.lean` — route B, a sibling scratch file —
defines an identical `cDestOf`/`cHeader` pair; on integration keep ONE.) -/

/-- The six header cycles as a literal list. `cFrame`'s `flatMap` form is not a
literal, and `simp`/`getD` reasoning needs one. -/
def cHdrL (a : Bool) (d : Nat) : List Bool :=
  [a, a && d.testBit 2, a, a && d.testBit 1, a, a && d.testBit 0]

theorem cFrame_eq_hdrL (a : Bool) (d : Nat) (p : List Bool) :
    cFrame a d p = cHdrL a d ++ p := rfl

/-- Read a destination back out of the first six cycles of a stream. -/
def cDestOf (s : List Bool) : Nat :=
  (if s.getD 1 false then 4 else 0) + (if s.getD 3 false then 2 else 0)
    + (if s.getD 5 false then 1 else 0)

/-- ⭐ `cDestOf` lands in the fabric's range for ANY stream — three bits is three
bits. *This is why the invariant below needs no separate `d < 8` clause on the
read-out side.* -/
theorem cDestOf_lt_eight (s : List Bool) : cDestOf s < 8 := by
  simp only [cDestOf]
  split_ifs <;> omega

theorem cDestOf_cHdrL (d : Nat) (hd : d < 8) : cDestOf (cHdrL true d) = d := by
  interval_cases d <;> rfl

/-- ⛔ **THE PAYLOAD IS INVISIBLE TO `cDestOf`, AND THEREFORE TO B4's CONCLUSION**:
two frames differing in EVERY payload bit have the same read-out destination.

*`cDestOf` reads stream indices 1/3/5 and nothing else — payload-blind BY
CONSTRUCTION — so any conclusion phrased as `cDestOf ∘ output column` survives every
payload-mangling transformation. That is why the ③ block's L3 could not ride B4's
hseam discharge to a PAYLOAD theorem: the machinery it needed is
`bnC_output_frames_are_the_fold`, which is whole-frame and payload-CARRYING.*

📌 **LANDED HERE, BESIDE ITS SUBJECT, TO REPAIR A CITATION RATHER THAN A PROOF.**
*`docs/payload-delivery-design-v1.md` cited this by name as `kernel-exhibited` while
it existed only in a **gitignored** scratch file — so no reader of a committed ref
could follow it. Math found that at 16:09; I then compounded it by reporting the
scratch file DELETED (I had looked at the wrong directory) when it was present all
along, and the reason math's search missed it is that `grep` on this machine is
shimmed to a tool that obeys `.gitignore`.*
⚖️ ***The general rule earned: an evidentiary word — `kernel-exhibited` above all —
may not point at a gitignored file. Land it beside its subject, or write "measured in
scratch, not preserved".*** -/
theorem cDestOf_is_payload_blind :
    cDestOf (cFrame true 5 (List.replicate 8 false))
        = cDestOf (cFrame true 5 (List.replicate 8 true))
      ∧ cFrame true 5 (List.replicate 8 false) ≠ cFrame true 5 (List.replicate 8 true) := by
  decide +kernel

#audit_axioms cDestOf_is_payload_blind

/-- The read-out inverts an active frame with ANY payload. -/
theorem cDestOf_cFrame (d : Nat) (hd : d < 8) (p : List Bool) :
    cDestOf (cFrame true d p) = d := by
  rw [cFrame_eq_hdrL]
  have h1 : (cHdrL true d ++ p).getD 1 false = (cHdrL true d).getD 1 false := by
    simp [cHdrL, List.getD]
  have h3 : (cHdrL true d ++ p).getD 3 false = (cHdrL true d).getD 3 false := by
    simp [cHdrL, List.getD]
  have h5 : (cHdrL true d ++ p).getD 5 false = (cHdrL true d).getD 5 false := by
    simp [cHdrL, List.getD]
  rw [cDestOf, h1, h3, h5, ← cDestOf]
  exact cDestOf_cHdrL d hd

/-! ## 1. Every frame is as long as the trace -/

theorem bnCFrameAt_length (st : List Bool) (tr : List (List Bool)) (k w : Nat) :
    (bnCFrameAt st tr k w).length = tr.length := by
  induction tr generalizing st with
  | nil => rfl
  | cons inp is ih =>
    rw [bnCFrameAt_cons, List.length_cons, List.length_cons, ih]

/-! ## 2. HYPOTHESIS ①, THE RST COLUMN — `zip3Trace` with a one-shot `rst`
column IS `ceFrameTrace`.

`ElemSortsAt` drives the element with `zip3Trace (tr.map (·.getD 0)) x y`; the
element theorem drives it with `ceFrameTrace x y`, whose cycle 0 is
`[true, x₀, y₀]` and whose later cycles are `[false, xᵢ, yᵢ]`. The two coincide
EXACTLY when the caller asserts `rst` on cycle 0 and holds it low for the rest of
the frame — a condition on the caller's trace, taken as a hypothesis. -/

theorem zip3Trace_replicate_false : ∀ (n : Nat) (xs ys : List Bool),
    xs.length = n → ys.length = n →
    zip3Trace (List.replicate n false) xs ys = ceBody xs ys := by
  intro n
  induction n with
  | zero =>
    intro xs ys hx hy
    cases xs with
    | nil =>
      cases ys with
      | nil => rfl
      | cons _ _ => simp at hy
    | cons _ _ => simp at hx
  | succ m ih =>
    intro xs ys hx hy
    cases xs with
    | nil => simp at hx
    | cons x xs' =>
      cases ys with
      | nil => simp at hy
      | cons y ys' =>
        rw [List.replicate_succ, zip3Trace_cons,
            ih xs' ys' (by simpa using hx) (by simpa using hy)]
        simp only [ceBody, List.zipWith_cons_cons]

/-- ⭐ **HYPOTHESIS ① DISCHARGED, at the driver level.** -/
theorem zip3Trace_rst_once (n : Nat) (f0 f1 : List Bool)
    (h0 : f0.length = n + 1) (h1 : f1.length = n + 1) :
    zip3Trace (true :: List.replicate n false) f0 f1 = ceFrameTrace f0 f1 := by
  cases f0 with
  | nil => simp at h0
  | cons x xs =>
    cases f1 with
    | nil => simp at h1
    | cons y ys =>
      rw [zip3Trace_cons,
          zip3Trace_replicate_false n xs ys (by simpa using h0) (by simpa using h1)]
      simp only [ceFrameTrace]

/-- `ceCPort` hands the element an ARBITRARY state list, not a 4-element one, so
`ceFrameTrace_from_any_state` (which is stated at `[a,b,c,d]`) does not apply
directly. `ceC_reset_forgets` is stated at an arbitrary list and does. -/
theorem runTrace_ceC_frame_any_state (s : List Bool) (f0 f1 : List Bool)
    (h0 : f0 ≠ []) (h1 : f1 ≠ []) :
    runTrace ceC s (ceFrameTrace f0 f1)
      = runTrace ceC [false, false, false, false] (ceFrameTrace f0 f1) := by
  cases f0 with
  | nil => exact absurd rfl h0
  | cons x xs =>
    cases f1 with
    | nil => exact absurd rfl h1
    | cons y ys =>
      simp only [ceFrameTrace]
      rw [runTrace_cons, runTrace_cons, ceC_reset_forgets s x y]

/-! ## 3. THE ELEMENT, in the network's own vocabulary -/

/-- ⭐⭐ `ceCPort … 0` at full load, driven by a one-shot `rst` column, from the
arbitrary state slice the network hands it. -/
theorem ceCPort_full_load_out0 (s : List Bool) (n : Nat) (d0 d1 : Nat)
    (hd0 : d0 < 8) (hd1 : d1 < 8) (hne : d0 ≠ d1) (p0 p1 : List Bool)
    (hp : p0.length = p1.length) (hlen : (cFrame true d0 p0).length = n + 1) :
    ceCPort s (true :: List.replicate n false) (cFrame true d0 p0) (cFrame true d1 p1) 0
      = if cKeyLE (cKey true d0) (cKey true d1) then cFrame true d0 p0
        else cFrame true d1 p1 := by
  have hlen1 : (cFrame true d1 p1).length = n + 1 := by
    rw [cFrame_length] at hlen ⊢; omega
  rw [ceCPort, zip3Trace_rst_once n _ _ hlen hlen1,
      runTrace_ceC_frame_any_state s _ _ (cFrame_ne_nil true d0 p0)
        (cFrame_ne_nil true d1 p1)]
  exact ceC_pair_full_load_out0 d0 d1 hd0 hd1 hne p0 p1 hp

/-- ⭐⭐ …and `ceCPort … 1`. -/
theorem ceCPort_full_load_out1 (s : List Bool) (n : Nat) (d0 d1 : Nat)
    (hd0 : d0 < 8) (hd1 : d1 < 8) (hne : d0 ≠ d1) (p0 p1 : List Bool)
    (hp : p0.length = p1.length) (hlen : (cFrame true d0 p0).length = n + 1) :
    ceCPort s (true :: List.replicate n false) (cFrame true d0 p0) (cFrame true d1 p1) 1
      = if cKeyLE (cKey true d0) (cKey true d1) then cFrame true d1 p1
        else cFrame true d0 p0 := by
  have hlen1 : (cFrame true d1 p1).length = n + 1 := by
    rw [cFrame_length] at hlen ⊢; omega
  rw [ceCPort, zip3Trace_rst_once n _ _ hlen hlen1,
      runTrace_ceC_frame_any_state s _ _ (cFrame_ne_nil true d0 p0)
        (cFrame_ne_nil true d1 p1)]
  exact ceC_pair_full_load_out1 d0 d1 hd0 hd1 hne p0 p1 hp

/-! ## 4. HYPOTHESIS ②, THE FRAME INVARIANT -/

/-- **The frame invariant at stage `k`.** Every one of the eight wires carries a
well-formed ACTIVE frame with a payload of the common length `L`, and the eight
destinations are pairwise distinct.

⚠️ The distinctness clause is not decoration: `ceC_pair_tie_splices_the_payload`
is the control showing the element MISSORTS on a tie, so `hne` is load-bearing
in `ceC_pair_full_load` and the invariant must carry it. -/
def StageOK (st : List Bool) (tr : List (List Bool)) (L k : Nat) : Prop :=
  (∀ w, w < 8 → ∃ d p, d < 8 ∧ p.length = L ∧ bnCFrameAt st tr k w = cFrame true d p)
  ∧ (∀ w₁ w₂, w₁ < 8 → w₂ < 8 → w₁ ≠ w₂ →
      cDestOf (bnCFrameAt st tr k w₁) ≠ cDestOf (bnCFrameAt st tr k w₂))

/-- ⭐⭐⭐ **`ElemSortsAt` IS DERIVED**, at every stage the invariant holds,
under the caller's `rst`-once hypothesis. The `le` is `decide (cDestOf · ≤
cDestOf ·)` — exactly the shape `bnC_output_keys_are_runNetN` consumes with
`key := cDestOf`. -/
theorem elemSortsAt_of_stage (st : List Bool) (tr : List (List Bool)) (n L k : Nat)
    (hk : k < 24)
    (hrst : tr.map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (hSt : StageOK st tr L k) :
    ElemSortsAt st tr k (fun x y => decide (cDestOf x ≤ cDestOf y)) := by
  obtain ⟨hframes, hdist⟩ := hSt
  have ha : (bnCCompAt k).1 < 8 := (bnComps_lt_eight _ (bnCCompAt_mem k hk)).1
  have hb : (bnCCompAt k).2 < 8 := (bnComps_lt_eight _ (bnCCompAt_mem k hk)).2
  have hab : (bnCCompAt k).1 ≠ (bnCCompAt k).2 := bnCCompAt_ne k hk
  obtain ⟨da, pa, hda, hpa, hfa⟩ := hframes _ ha
  obtain ⟨db, pb, hdb, hpb, hfb⟩ := hframes _ hb
  have hdA : cDestOf (bnCFrameAt st tr k (bnCCompAt k).1) = da := by
    rw [hfa]; exact cDestOf_cFrame da hda pa
  have hdB : cDestOf (bnCFrameAt st tr k (bnCCompAt k).2) = db := by
    rw [hfb]; exact cDestOf_cFrame db hdb pb
  have hne : da ≠ db := by
    have h := hdist _ _ ha hb hab
    rw [hdA, hdB] at h
    exact h
  have hlenA : (cFrame true da pa).length = n + 1 := by
    have htr : tr.length = n + 1 := by
      have h := congrArg List.length hrst
      simpa using h
    rw [← hfa, bnCFrameAt_length, htr]
  have hpab : pa.length = pb.length := by rw [hpa, hpb]
  refine ⟨?_, ?_⟩
  · show ceCPort (bnCSlice st k) (tr.map (fun i => i.getD 0 false))
          (bnCFrameAt st tr k (bnCCompAt k).1) (bnCFrameAt st tr k (bnCCompAt k).2) 0
        = (if decide (cDestOf (bnCFrameAt st tr k (bnCCompAt k).1)
                      ≤ cDestOf (bnCFrameAt st tr k (bnCCompAt k).2))
           then bnCFrameAt st tr k (bnCCompAt k).1
           else bnCFrameAt st tr k (bnCCompAt k).2)
    rw [hdA, hdB, hrst, hfa, hfb,
        ceCPort_full_load_out0 (bnCSlice st k) n da db hda hdb hne pa pb hpab hlenA,
        cKeyLE_full_load]
  · show ceCPort (bnCSlice st k) (tr.map (fun i => i.getD 0 false))
          (bnCFrameAt st tr k (bnCCompAt k).1) (bnCFrameAt st tr k (bnCCompAt k).2) 1
        = (if decide (cDestOf (bnCFrameAt st tr k (bnCCompAt k).1)
                      ≤ cDestOf (bnCFrameAt st tr k (bnCCompAt k).2))
           then bnCFrameAt st tr k (bnCCompAt k).2
           else bnCFrameAt st tr k (bnCCompAt k).1)
    rw [hdA, hdB, hrst, hfa, hfb,
        ceCPort_full_load_out1 (bnCSlice st k) n da db hda hdb hne pa pb hpab hlenA,
        cKeyLE_full_load]

/-! ## 5. ONE STAGE IS A PERMUTATION OF THE PREVIOUS ONE

This is the step that makes the invariant INDUCTIVE rather than something to be
re-established: the element's two outputs ARE its two inputs, reordered. -/

/-- The transposition of two wire indices. -/
def wireSwap (a b w : Nat) : Nat := if w = a then b else if w = b then a else w

theorem wireSwap_involutive (a b w : Nat) : wireSwap a b (wireSwap a b w) = w := by
  simp only [wireSwap]
  split_ifs <;> omega

theorem wireSwap_lt (a b w : Nat) (ha : a < 8) (hb : b < 8) (hw : w < 8) :
    wireSwap a b w < 8 := by
  simp only [wireSwap]
  split_ifs <;> assumption

theorem wireSwap_inj (a b w₁ w₂ : Nat) (h : wireSwap a b w₁ = wireSwap a b w₂) :
    w₁ = w₂ := by
  calc w₁ = wireSwap a b (wireSwap a b w₁) := (wireSwap_involutive a b w₁).symm
    _ = wireSwap a b (wireSwap a b w₂) := by rw [h]
    _ = w₂ := wireSwap_involutive a b w₂

/-- ⭐⭐⭐ **THE STEP.** Given the element certificate at stage `k`, the whole
stage-`k+1` frame vector is the stage-`k` frame vector composed with a wire
permutation — the identity when the pair is already in order, the comparator's
transposition when it is not. *Nothing about frame WELL-FORMEDNESS is used here;
that is exactly why the invariant is preserved rather than re-established.* -/
theorem frames_succ_perm (st : List Bool) (tr : List (List Bool)) (k : Nat) (hk : k < 24)
    (le : List Bool → List Bool → Bool) (h : ElemSortsAt st tr k le) :
    ∃ σ : Nat → Nat,
      (∀ w, w < 8 → σ w < 8)
      ∧ (∀ w₁ w₂, w₁ < 8 → w₂ < 8 → w₁ ≠ w₂ → σ w₁ ≠ σ w₂)
      ∧ (∀ w, bnCFrameAt st tr (k + 1) w = bnCFrameAt st tr k (σ w)) := by
  have ha : (bnCCompAt k).1 < 8 := (bnComps_lt_eight _ (bnCCompAt_mem k hk)).1
  have hb : (bnCCompAt k).2 < 8 := (bnComps_lt_eight _ (bnCCompAt_mem k hk)).2
  by_cases hle : le (bnCFrameAt st tr k (bnCCompAt k).1)
                    (bnCFrameAt st tr k (bnCCompAt k).2) = true
  · refine ⟨fun w => w, ?_, ?_, ?_⟩
    · intro w hw; exact hw
    · intro w₁ w₂ _ _ hne; exact hne
    · intro w
      show bnCFrameAt st tr (k + 1) w = bnCFrameAt st tr k w
      rw [bnCFrameAt_succ_sorted st tr k le hk h w]
      simp only [applyCompF]
      by_cases h1 : w = (bnCCompAt k).1
      · rw [if_pos h1, if_pos hle, h1]
      · rw [if_neg h1]
        by_cases h2 : w = (bnCCompAt k).2
        · rw [if_pos h2, if_pos hle, h2]
        · rw [if_neg h2]
  · refine ⟨wireSwap (bnCCompAt k).1 (bnCCompAt k).2, ?_, ?_, ?_⟩
    · intro w hw; exact wireSwap_lt _ _ _ ha hb hw
    · intro w₁ w₂ _ _ hne hEq; exact hne (wireSwap_inj _ _ _ _ hEq)
    · intro w
      rw [bnCFrameAt_succ_sorted st tr k le hk h w]
      simp only [applyCompF]
      by_cases h1 : w = (bnCCompAt k).1
      · have hs : wireSwap (bnCCompAt k).1 (bnCCompAt k).2 w = (bnCCompAt k).2 := by
          simp only [wireSwap, if_pos h1]
        rw [if_pos h1, if_neg hle, hs]
      · by_cases h2 : w = (bnCCompAt k).2
        · have hs : wireSwap (bnCCompAt k).1 (bnCCompAt k).2 w = (bnCCompAt k).1 := by
            simp only [wireSwap, if_neg h1, if_pos h2]
          rw [if_neg h1, if_pos h2, if_neg hle, hs]
        · have hs : wireSwap (bnCCompAt k).1 (bnCCompAt k).2 w = w := by
            simp only [wireSwap, if_neg h1, if_neg h2]
          rw [if_neg h1, if_neg h2, hs]

/-! ## 6. THE INDUCTION -/

/-- ⭐⭐⭐ **THE INVARIANT IS INDUCTIVE.** Both clauses transport along the
permutation: well-formedness because wire `w` at `k+1` literally IS wire `σ w` at
`k`, and distinctness because `σ` is injective. -/
theorem stageOK_succ (st : List Bool) (tr : List (List Bool)) (n L k : Nat)
    (hk : k < 24)
    (hrst : tr.map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (hSt : StageOK st tr L k) :
    StageOK st tr L (k + 1) := by
  obtain ⟨σ, hσlt, hσinj, hσeq⟩ :=
    frames_succ_perm st tr k hk _ (elemSortsAt_of_stage st tr n L k hk hrst hSt)
  obtain ⟨hframes, hdist⟩ := hSt
  refine ⟨?_, ?_⟩
  · intro w hw
    rw [hσeq w]
    exact hframes _ (hσlt w hw)
  · intro w₁ w₂ hw₁ hw₂ hne
    rw [hσeq w₁, hσeq w₂]
    exact hdist _ _ (hσlt w₁ hw₁) (hσlt w₂ hw₂) (hσinj w₁ w₂ hw₁ hw₂ hne)

theorem stageOK_all (st : List Bool) (tr : List (List Bool)) (n L : Nat)
    (hrst : tr.map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (h0 : StageOK st tr L 0) :
    ∀ k, k ≤ 24 → StageOK st tr L k := by
  intro k
  induction k with
  | zero => intro _; exact h0
  | succ m ih =>
    intro hm
    exact stageOK_succ st tr n L m (by omega) hrst (ih (by omega))

/-- ⭐⭐⭐ **HYPOTHESIS ② DISCHARGED.** `bnC_output_keys_are_runNetN`'s premise
`∀ k < 24, ElemSortsAt …`, from a condition on the CALLER'S TRACE alone. -/
theorem elemSortsAt_all (st : List Bool) (tr : List (List Bool)) (n L : Nat)
    (hrst : tr.map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (h0 : StageOK st tr L 0) :
    ∀ k, k < 24 → ElemSortsAt st tr k (fun x y => decide (cDestOf x ≤ cDestOf y)) := by
  intro k hk
  exact elemSortsAt_of_stage st tr n L k hk hrst
    (stageOK_all st tr n L hrst h0 k (by omega))

/-! ## 7. THE PAYOFF -/

/-- The stage-0 invariant is a statement about the CALLER'S INPUT COLUMNS, by
`bnCFrameAt_zero`. -/
theorem stageOK_zero_of_inputs (st : List Bool) (tr : List (List Bool)) (L : Nat)
    (hin : ∀ w, w < 8 → ∃ d p, d < 8 ∧ p.length = L ∧
            tr.map (fun i => i.getD (1 + w) false) = cFrame true d p)
    (hdst : ∀ w₁ w₂, w₁ < 8 → w₂ < 8 → w₁ ≠ w₂ →
            cDestOf (tr.map (fun i => i.getD (1 + w₁) false))
              ≠ cDestOf (tr.map (fun i => i.getD (1 + w₂) false))) :
    StageOK st tr L 0 := by
  refine ⟨?_, ?_⟩
  · intro w hw
    rw [bnCFrameAt_zero st tr w hw]
    exact hin w hw
  · intro w₁ w₂ h1 h2 hne
    rw [bnCFrameAt_zero st tr w₁ h1, bnCFrameAt_zero st tr w₂ h2]
    exact hdst w₁ w₂ h1 h2 hne

/-- ⭐⭐⭐⭐ **THE SEAM, WITH NO ASSUMED ELEMENT CERTIFICATE.** The destination
the network delivers on wire `w` is `runNet`-over-`bnComps` applied to the eight
destinations it was fed — from two conditions on the caller's trace and NOTHING
else. *`ElemSortsAt` no longer appears.* -/
theorem bnC_output_dests_are_runNetN (st : List Bool) (tr : List (List Bool)) (n L : Nat)
    (hrst : tr.map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (h0 : StageOK st tr L 0) (w : Nat) (hw : w < 8) :
    cDestOf ((runTrace batcherNetC st tr).1.map (fun o => o.getD w false))
      = runNetN bnComps (fun i => cDestOf (bnCFrameAt st tr 0 i)) w :=
  bnC_output_keys_are_runNetN st tr cDestOf (elemSortsAt_all st tr n L hrst h0) w hw

/-- …and the seed of the fold, written on the caller's input columns. -/
theorem bnC_output_dests_of_inputs (st : List Bool) (tr : List (List Bool)) (n L : Nat)
    (hrst : tr.map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (hin : ∀ w, w < 8 → ∃ d p, d < 8 ∧ p.length = L ∧
            tr.map (fun i => i.getD (1 + w) false) = cFrame true d p)
    (hdst : ∀ w₁ w₂, w₁ < 8 → w₂ < 8 → w₁ ≠ w₂ →
            cDestOf (tr.map (fun i => i.getD (1 + w₁) false))
              ≠ cDestOf (tr.map (fun i => i.getD (1 + w₂) false)))
    (w : Nat) (hw : w < 8) :
    cDestOf ((runTrace batcherNetC st tr).1.map (fun o => o.getD w false))
      = runNetN bnComps
          (fun i => cDestOf (bnCFrameAt st tr 0 i)) w :=
  bnC_output_dests_are_runNetN st tr n L hrst
    (stageOK_zero_of_inputs st tr L hin hdst) w hw

/-! ## 8. NON-VACUITY — the two hypotheses are SATISFIABLE

Both premises of §7 are conditions on the caller's trace, so a statement of the
form "if the caller drives it right then the network routes" is worthless until
some trace drives it right. Here is one, exhibited and kernel-checked: eight
active frames, destinations `7,6,…,0` (distinct, and in the WORST order), a
two-bit payload, `rst` asserted on cycle 0 and low for the other seven. -/

/-- Eight reversed-destination frames, presented as `batcherNetC`'s input trace:
cycle `t` is `rst` followed by the eight wires' `t`-th bits. -/
def joinFixtureTr : List (List Bool) :=
  (List.range 8).map (fun t =>
    (t == 0) :: (List.range 8).map (fun w =>
      (cFrame true (7 - w) [true, false]).getD t false))

theorem joinFixture_rst :
    joinFixtureTr.map (fun i => i.getD 0 false) = true :: List.replicate 7 false := by
  decide +kernel

theorem joinFixture_cols (w : Nat) (hw : w < 8) :
    joinFixtureTr.map (fun i => i.getD (1 + w) false) = cFrame true (7 - w) [true, false] := by
  interval_cases w <;> decide +kernel

theorem joinFixture_stageOK (st : List Bool) : StageOK st joinFixtureTr 2 0 := by
  refine stageOK_zero_of_inputs st joinFixtureTr 2 ?_ ?_
  · intro w hw
    exact ⟨7 - w, [true, false], by omega, rfl, joinFixture_cols w hw⟩
  · intro w₁ w₂ h1 h2 hne
    rw [joinFixture_cols w₁ h1, joinFixture_cols w₂ h2,
        cDestOf_cFrame _ (by omega) _, cDestOf_cFrame _ (by omega) _]
    omega

/-- ⭐ **NON-VACUOUS.** The seam theorem, with EVERY hypothesis discharged
except the network's own initial state, which is arbitrary. -/
theorem bnC_output_dests_fixture (st : List Bool) (w : Nat) (hw : w < 8) :
    cDestOf ((runTrace batcherNetC st joinFixtureTr).1.map (fun o => o.getD w false))
      = runNetN bnComps (fun i => cDestOf (bnCFrameAt st joinFixtureTr 0 i)) w :=
  bnC_output_dests_are_runNetN st joinFixtureTr 7 2 joinFixture_rst
    (joinFixture_stageOK st) w hw

#audit_axioms joinFixtureTr joinFixture_rst joinFixture_cols
#audit_axioms joinFixture_stageOK bnC_output_dests_fixture

#audit_axioms cHdrL cFrame_eq_hdrL cDestOf cDestOf_lt_eight cDestOf_cHdrL cDestOf_cFrame
#audit_axioms bnCFrameAt_length zip3Trace_replicate_false zip3Trace_rst_once
#audit_axioms runTrace_ceC_frame_any_state ceCPort_full_load_out0 ceCPort_full_load_out1
#audit_axioms StageOK elemSortsAt_of_stage
#audit_axioms wireSwap wireSwap_involutive wireSwap_lt wireSwap_inj frames_succ_perm
#audit_axioms stageOK_succ stageOK_all elemSortsAt_all
#audit_axioms stageOK_zero_of_inputs bnC_output_dests_are_runNetN bnC_output_dests_of_inputs

end SaltWorks.HDL
