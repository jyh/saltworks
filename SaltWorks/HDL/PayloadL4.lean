import SaltWorks.HDL.SeamJoinC
import SaltWorks.HDL.SeamJoinB
import SaltWorks.HDL.BatcherNetCheck

/-!
# ③ NODE L4 — THE PAYLOAD THEOREM

The summit of the payload-delivery block: under B4's own binder set, the fabric **delivers** —
the output frame on wire `w` IS the input frame of the line whose destination is `w`, payload
intact.  `bnC_payload_delivered`.

**Re-priced from C-class to B-class, and the route has NO σ object.**  The block priced L4 as
"compose the 24 existential σ's of `frames_succ_perm`, plus prove frame-σ/key-σ agreement".
Neither is needed:

* `bnCFrameAt_succ_frames` (SeamJoinC) already gives the per-stage step **explicitly and
  payload-carryingly** — the two comparator wires take `min`/`max` of the destinations with the
  payloads riding along, and **every other wire is untouched**.
* So the induction carries the invariant **J(k) := "every wire holds one of the ORIGINAL eight
  frames, verbatim"** (`j_all`), whose step never constructs a permutation.
* The `k = 24` close goes through the KEY level: `runNetN_bnComps_id` says a distinct, in-range
  destination assignment is mapped to the identity, via `bnComps_eq_batcher8` +
  `runNetN_map_val` + `runNet_perm`/`runNet_injective` and eight values of `omega`.

**Controls (goal-level, witnesses stated before running):**
* payload `p i → p ⟨0,_⟩`: FALSE at `d = id`, `p 0 = [true]`, `p 1 = [false]`, `w = 1`.
* drop `hdi`: FALSE at `d ≡ 0`, `w = 5` — the conclusion asserts `∃ i, d i = 5`.
Both fail to elaborate; restore verified byte-identical.

⚠️ **`import owed:` — `SaltWorks.lean` is maestro-only, so this module is not yet in the hub
closure and carries a targeted-build verdict, not a full-build one.**
-/


namespace SaltWorks.HDL

/-- J is preserved by one stage. (No σ object is constructed anywhere.) -/
private theorem j_step
    (st : List Bool) (inp : List Bool) (is : List (List Bool)) (k : Nat) (hk : k < 24)
    (hrst0 : inp.getD 0 false = true) (hrst : ∀ i ∈ is, i.getD 0 false = false)
    (D : Nat → Nat) (P : Nat → List Bool) (hD : ∀ j, j < 8 → D j < 8)
    (hJ : ∀ w, w < 8 → ∃ j, j < 8 ∧
        bnCFrameAt st (inp :: is) k w = cFrame true (D j) (P j))
    (hdist : ∀ w₁ w₂, w₁ < 8 → w₂ < 8 → w₁ ≠ w₂ →
        cDestOf (bnCFrameAt st (inp :: is) k w₁) ≠ cDestOf (bnCFrameAt st (inp :: is) k w₂)) :
    ∀ w, w < 8 → ∃ j, j < 8 ∧
        bnCFrameAt st (inp :: is) (k + 1) w = cFrame true (D j) (P j) := by
  obtain ⟨hc1, hc2⟩ := bnComps_lt_eight _ (bnCCompAt_mem k hk)
  obtain ⟨j0, hj0, hf0⟩ := hJ (bnCCompAt k).1 hc1
  obtain ⟨j1, hj1, hf1⟩ := hJ (bnCCompAt k).2 hc2
  have hcne : (bnCCompAt k).1 ≠ (bnCCompAt k).2 := bnCCompAt_ne k hk
  have hne : D j0 ≠ D j1 := by
    have hx := hdist _ _ hc1 hc2 hcne
    rw [hf0, hf1, cDestOf_cFrame _ (hD _ hj0), cDestOf_cFrame _ (hD _ hj1)] at hx
    exact hx
  obtain ⟨e1, e2, erest⟩ := bnCFrameAt_succ_frames st inp is k hk hrst0 hrst
      (D j0) (D j1) (P j0) (P j1) (hD _ hj0) (hD _ hj1) hne hf0 hf1
  intro w hw
  by_cases h1 : w = (bnCCompAt k).1
  · subst h1
    by_cases h : D j0 ≤ D j1
    · exact ⟨j0, hj0, by rw [e1]; simp [h]⟩
    · have h' : D j1 ≤ D j0 := Nat.le_of_lt (Nat.lt_of_not_le h)
      exact ⟨j1, hj1, by rw [e1]; simp [Nat.min_eq_right h', h]⟩
  · by_cases h2 : w = (bnCCompAt k).2
    · subst h2
      by_cases h : D j0 ≤ D j1
      · exact ⟨j1, hj1, by rw [e2]; simp [h]⟩
      · have h' : D j1 ≤ D j0 := Nat.le_of_lt (Nat.lt_of_not_le h)
        exact ⟨j0, hj0, by rw [e2]; simp [Nat.max_eq_left h', h]⟩
    · obtain ⟨j, hj, hfj⟩ := hJ w hw
      exact ⟨j, hj, by rw [erest w h1 h2]; exact hfj⟩

/-- **J holds at every stage `k ≤ 24`**: every wire carries one of the ORIGINAL eight frames,
verbatim.  Induction on `k`, step by `j_step`, dest-distinctness carried by `stageOK_all`. -/
theorem j_all (st : List Bool) (inp : List Bool) (is : List (List Bool)) (n L : Nat)
    (hrst0 : inp.getD 0 false = true) (hrst : ∀ i ∈ is, i.getD 0 false = false)
    (hrstT : (inp :: is).map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (h0 : StageOK st (inp :: is) L 0)
    (D : Nat → Nat) (P : Nat → List Bool) (hD : ∀ j, j < 8 → D j < 8)
    (hJ0 : ∀ w, w < 8 → ∃ j, j < 8 ∧
        bnCFrameAt st (inp :: is) 0 w = cFrame true (D j) (P j)) :
    ∀ k, k ≤ 24 → ∀ w, w < 8 → ∃ j, j < 8 ∧
        bnCFrameAt st (inp :: is) k w = cFrame true (D j) (P j) := by
  intro k
  induction k with
  | zero => intro _; exact hJ0
  | succ m ih =>
      intro hm
      have hm24 : m < 24 := by omega
      have hSO := stageOK_all st (inp :: is) n L hrstT h0 m (by omega)
      exact j_step st inp is m hm24 hrst0 hrst D P hD (ih (by omega)) hSO.2

end SaltWorks.HDL


namespace SaltWorks.HDL
open SaltWorks.Stack

/-- Eight strictly increasing naturals below 8 ARE `0..7`. Pure `ℕ` — no `Fin` atoms for
`omega` to trip over. -/
private theorem eight_sorted_id {a0 a1 a2 a3 a4 a5 a6 a7 : ℕ}
    (h0 : a0 < a1) (h1 : a1 < a2) (h2 : a2 < a3) (h3 : a3 < a4)
    (h4 : a4 < a5) (h5 : a5 < a6) (h6 : a6 < a7) (h7 : a7 < 8) :
    a0 = 0 ∧ a1 = 1 ∧ a2 = 2 ∧ a3 = 3 ∧ a4 = 4 ∧ a5 = 5 ∧ a6 = 6 ∧ a7 = 7 := by omega

private theorem sorted_inj_lt_eight_id (g : Fin 8 → ℕ)
    (hlt : ∀ i, g i < 8) (hinj : Function.Injective g)
    (hsorted : ∀ i j : Fin 8, i < j → g i ≤ g j) (i : Fin 8) : g i = i.val := by
  have hs : ∀ a b : Fin 8, a < b → g a < g b := fun a b hab =>
    lt_of_le_of_ne (hsorted a b hab) (fun h => absurd (hinj h) (ne_of_lt hab))
  obtain ⟨q0, q1, q2, q3, q4, q5, q6, q7⟩ :=
    eight_sorted_id (a0 := g ⟨0, by omega⟩) (a1 := g ⟨1, by omega⟩) (a2 := g ⟨2, by omega⟩)
      (a3 := g ⟨3, by omega⟩) (a4 := g ⟨4, by omega⟩) (a5 := g ⟨5, by omega⟩)
      (a6 := g ⟨6, by omega⟩) (a7 := g ⟨7, by omega⟩)
      (hs _ _ (by decide)) (hs _ _ (by decide)) (hs _ _ (by decide)) (hs _ _ (by decide))
      (hs _ _ (by decide)) (hs _ _ (by decide)) (hs _ _ (by decide)) (hlt _)
  obtain ⟨iv, ih⟩ := i
  show g ⟨iv, ih⟩ = iv
  interval_cases iv <;> assumption

/-- **The `k = 24` close at the KEY level**: the fabric maps a distinct, in-range destination
assignment to the identity — wire `w` carries destination `w`. -/
theorem runNetN_bnComps_id (vN : Nat → Nat)
    (hlt : ∀ w, w < 8 → vN w < 8)
    (hinj : ∀ w₁ w₂, w₁ < 8 → w₂ < 8 → w₁ ≠ w₂ → vN w₁ ≠ vN w₂)
    (w : Nat) (hw : w < 8) :
    runNetN bnComps vN w = w := by
  have hv : Function.Injective (fun i : Fin 8 => vN i.val) := by
    intro a b hab
    by_contra hne
    exact hinj a.val b.val a.isLt b.isLt (fun h => hne (Fin.ext h)) hab
  have htr := runNetN_map_val batcher8 (fun i : Fin 8 => vN i.val) vN (fun _ => rfl) ⟨w, hw⟩
  rw [bnComps_eq_batcher8, htr]
  obtain ⟨σ, hσ⟩ := runNet_perm batcher8 (fun i : Fin 8 => vN i.val)
  refine sorted_inj_lt_eight_id _ (fun i => ?_) (runNet_injective batcher8 hv) (fun i j hij => ?_)
      ⟨w, hw⟩
  · rw [hσ]; exact hlt _ (σ i).isLt
  · obtain ⟨hp, -⟩ := batcher8_sorts_perm ℕ (fun i : Fin 8 => vN i.val)
    exact (isSorted_iff_pairwise_ofFn _).mpr hp i j (le_of_lt hij)

end SaltWorks.HDL

namespace SaltWorks.HDL
open SaltWorks.Stack

/-- **③ L4 — THE PAYLOAD THEOREM.**  Under B4's own binder set, the fabric delivers: the output
frame on wire `w` IS the input frame of the line whose destination is `w`, payload intact. -/
theorem bnC_payload_delivered
    (st : List Bool) (inp : List Bool) (is : List (List Bool)) (n L : Nat)
    (hrst0 : inp.getD 0 false = true) (hrst : ∀ i ∈ is, i.getD 0 false = false)
    (hrstT : (inp :: is).map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (d : Fin 8 → Nat) (p : Fin 8 → List Bool)
    (hd : ∀ i, d i < 8) (hdi : Function.Injective d)
    (hL : ∀ i : Fin 8, (p i).length = L)
    (hin : ∀ i : Fin 8, (inp :: is).map (fun c => c.getD (1 + i.val) false)
             = cFrame true (d i) (p i))
    (w : Nat) (hw : w < 8) :
    ∃ i : Fin 8, d i = w ∧
      (runTrace batcherNetC st (inp :: is)).1.map (fun o => o.getD w false)
        = cFrame true w (p i) := by
  classical
  have hcol : ∀ (v : Nat) (hv : v < 8),
      cDestOf (bnCFrameAt st (inp :: is) 0 v) = d ⟨v, hv⟩ := by
    intro v hv
    rw [bnCFrameAt_zero st (inp :: is) v hv, hin ⟨v, hv⟩, cDestOf_cFrame _ (hd _)]
  have hdst : ∀ w₁ w₂, w₁ < 8 → w₂ < 8 → w₁ ≠ w₂ →
      cDestOf ((inp :: is).map (fun i => i.getD (1 + w₁) false))
        ≠ cDestOf ((inp :: is).map (fun i => i.getD (1 + w₂) false)) := by
    intro w₁ w₂ h1 h2 hne
    rw [hin ⟨w₁, h1⟩, hin ⟨w₂, h2⟩, cDestOf_cFrame _ (hd _), cDestOf_cFrame _ (hd _)]
    exact fun h => hne (congrArg Fin.val (hdi h))
  have hinE : ∀ v, v < 8 → ∃ dd pp, dd < 8 ∧ pp.length = L ∧
      (inp :: is).map (fun i => i.getD (1 + v) false) = cFrame true dd pp :=
    fun v hv => ⟨d ⟨v, hv⟩, p ⟨v, hv⟩, hd _, hL _, hin ⟨v, hv⟩⟩
  have h0 : StageOK st (inp :: is) L 0 :=
    stageOK_zero_of_inputs st (inp :: is) L hinE hdst
  -- the destination arriving on wire w is w itself
  have hkey : runNetN bnComps (fun i => cDestOf (bnCFrameAt st (inp :: is) 0 i)) w = w := by
    refine runNetN_bnComps_id _ (fun v hv => ?_) (fun v₁ v₂ h1 h2 hne => ?_) w hw
    · rw [hcol v hv]; exact hd _
    · rw [hcol v₁ h1, hcol v₂ h2]
      exact fun h => hne (congrArg Fin.val (hdi h))
  have hout := bnC_output_dests_of_inputs st (inp :: is) n L hrstT hinE hdst w hw
  rw [hkey] at hout
  -- J at stage 24
  set D : Nat → Nat := fun k => if h : k < 8 then d ⟨k, h⟩ else 0 with hDdef
  set P : Nat → List Bool := fun k => if h : k < 8 then p ⟨k, h⟩ else [] with hPdef
  have hDlt : ∀ k, k < 8 → D k < 8 := by
    intro k hk; simp only [hDdef, dif_pos hk]; exact hd _
  have hJ0 : ∀ v, v < 8 → ∃ j, j < 8 ∧
      bnCFrameAt st (inp :: is) 0 v = cFrame true (D j) (P j) := by
    intro v hv
    refine ⟨v, hv, ?_⟩
    rw [bnCFrameAt_zero st (inp :: is) v hv]
    simp only [hDdef, hPdef, dif_pos hv]
    exact hin ⟨v, hv⟩
  obtain ⟨j, hj, hfj⟩ :=
    j_all st inp is n L hrst0 hrst hrstT h0 D P hDlt hJ0 24 (le_refl 24) w hw
  have hDj : D j = d ⟨j, hj⟩ := by simp only [hDdef, dif_pos hj]
  have hPj : P j = p ⟨j, hj⟩ := by simp only [hPdef, dif_pos hj]
  rw [hDj, hPj] at hfj
  rw [← bnCFrameAt_24 st (inp :: is) w hw, hfj, cDestOf_cFrame _ (hd _)] at hout
  exact ⟨⟨j, hj⟩, hout, by rw [← bnCFrameAt_24 st (inp :: is) w hw, hfj, hout]⟩

end SaltWorks.HDL


#audit_axioms SaltWorks.HDL.j_all SaltWorks.HDL.runNetN_bnComps_id SaltWorks.HDL.bnC_payload_delivered
