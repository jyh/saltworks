/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.SeamElement
-- `bnCFrameAt_length` comes from here.  This file used to declare its OWN copy —
-- same namespace, identical statement AND proof — and the hub imported both.
-- Lean accepts that silently (`EXIT=0`, no warning), and math measured 2026-08-08
-- that the environment keeps the FIRST-imported copy, which made the LINE ORDER
-- of `SaltWorks.lean` semantically load-bearing: an alphabetise would have
-- swapped which proof downstream code sees.  Deleting the duplicate is what
-- makes the order question stop existing.  Do not re-declare it here.
import SaltWorks.HDL.SeamJoinA

/-!
# THE DRIVER BRIDGE — `zip3Trace` (network side) vs `ceFrameTrace` (element side)

Both halves of the seam are landed. `ElemSortsAt` drives a standalone `ceC` with
`zip3Trace (rst column) x y`; `ceC_pair_full_load_*` drives it with
`ceFrameTrace x y`, whose cycle 0 is `[true, x₀, y₀]` and whose later cycles are
`[false, xᵢ, yᵢ]`. **They are the same trace exactly when the caller's rst column
is `true` on cycle 0 and `false` afterwards** — a condition on the caller's
trace, which is hypothesis ① of the recorded gap.

This file proves that bridge, the payload-length bookkeeping it needs, and then
uses it to DISCHARGE `ElemSortsAt` outright from a frame-shape hypothesis.
-/

namespace SaltWorks.HDL

/-! ## 0. LENGTH BOOKKEEPING — `bnCFrameAt_length` is imported from `SeamJoinA`.
This file's own copy was an EXACT duplicate (statement and proof) and was deleted
2026-08-08; see the import header. -/

/-! ## 1. THE BRIDGE -/

/-- An all-`false` rst column drives `zip3Trace` exactly as `ceBody` does. The
length side condition is needed because `zip3Trace` truncates on the SHORTEST of
its three arguments while `ceBody` truncates on the shorter of its two. -/
theorem zip3Trace_eq_ceBody : ∀ (r x y : List Bool),
    (∀ b ∈ r, b = false) → x.length ≤ r.length →
    zip3Trace r x y = ceBody x y := by
  intro r
  induction r with
  | nil =>
    intro x y _ hlen
    cases x with
    | nil => simp [zip3Trace, ceBody]
    | cons a as => simp at hlen
  | cons b rs ih =>
    intro x y hall hlen
    have hb : b = false := hall b (by simp)
    subst hb
    cases x with
    | nil => simp [zip3Trace, ceBody]
    | cons x0 xs =>
      cases y with
      | nil => simp [zip3Trace, ceBody]
      | cons y0 ys =>
        rw [zip3Trace_cons,
            ih xs ys (fun c hc => hall c (List.mem_cons_of_mem _ hc)) (by simpa using hlen)]
        simp [ceBody]

/-- ⭐⭐ **THE DRIVER BRIDGE.** A trace whose rst column is `true` on cycle 0 and
`false` on every later cycle drives the element with EXACTLY `ceFrameTrace`. This
is the sentence that lets `ceC_pair_full_load_*` be applied to `ElemSortsAt`. -/
theorem zip3Trace_eq_ceFrameTrace (rs x y : List Bool)
    (hrt : ∀ b ∈ rs, b = false) (hlen : x.length ≤ rs.length + 1) :
    zip3Trace (true :: rs) x y = ceFrameTrace x y := by
  cases x with
  | nil => simp [zip3Trace, ceFrameTrace]
  | cons x0 xs =>
    cases y with
    | nil => simp [zip3Trace, ceFrameTrace]
    | cons y0 ys =>
      rw [zip3Trace_cons]
      simp only [ceFrameTrace]
      rw [zip3Trace_eq_ceBody rs xs ys hrt (by simpa using hlen)]

/-- The bridge, in `ceCPort`'s vocabulary: the network's own rst column
(`tr.map (·.getD 0 false)`) is `ceFrameTrace`'s driver. -/
theorem ceCPort_eq_frameTrace (s : List Bool) (inp : List Bool) (is : List (List Bool))
    (x y : List Bool) (j : Nat)
    (hrst0 : inp.getD 0 false = true)
    (hrst : ∀ i ∈ is, i.getD 0 false = false)
    (hlen : x.length ≤ (inp :: is).length) :
    ceCPort s ((inp :: is).map (fun i => i.getD 0 false)) x y j
      = (runTrace ceC s (ceFrameTrace x y)).1.map (fun o => o.getD j false) := by
  simp only [ceCPort, List.map_cons]
  rw [hrst0,
      zip3Trace_eq_ceFrameTrace (is.map (fun i => i.getD 0 false)) x y
        (by
          intro b hb
          obtain ⟨i, hi, hbi⟩ := List.mem_map.mp hb
          rw [← hbi]
          exact hrst i hi)
        (by simpa using hlen)]

/-! ### Controls — BOTH side conditions of the bridge are load-bearing -/

/-- The bridge is about the same object on both sides: three cycles, `rst` on
cycle 0 only. -/
theorem zip3Trace_bridge_fixture (a b c d e f : Bool) :
    zip3Trace [true, false, false] [a, b, c] [d, e, f]
      = [[true, a, d], [false, b, e], [false, c, f]] := by
  simp only [zip3Trace]

/-- ⛔ **`hrt` IS NOT DECORATION.** An rst column that re-asserts mid-frame gives
a trace `ceFrameTrace` cannot produce — and it is exactly the trace that would
restart the element's decision inside a frame. -/
theorem zip3Trace_needs_rst_low :
    zip3Trace [true, true] [true, false] [false, true]
      ≠ ceFrameTrace [true, false] [false, true] := by decide +kernel

/-- ⛔ **AND NEITHER IS THE LENGTH SIDE CONDITION.** `zip3Trace` truncates on the
SHORTEST of its three arguments; `ceFrameTrace` only on its two. A short rst
column silently drops the tail of the frame. -/
theorem zip3Trace_needs_length :
    zip3Trace [true] [true, false] [false, true]
      ≠ ceFrameTrace [true, false] [false, true] := by decide +kernel

/-! ## 2. THE STATE SLICE — `ceFrameTrace` erases an ARBITRARY state list

`ceFrameTrace_from_any_state` is stated for a four-element literal `[a,b,c,d]`;
the network hands the element `bnCSlice st k`, an arbitrary `List Bool`.
`ceC_reset_forgets` (SeamTrace) covers arbitrary lists, so the two compose. -/

theorem runTrace_ceC_frameTrace_any_state (s : List Bool) (f0 f1 : List Bool)
    (h0 : f0 ≠ []) (h1 : f1 ≠ []) :
    runTrace ceC s (ceFrameTrace f0 f1)
      = runTrace ceC [false, false, false, false] (ceFrameTrace f0 f1) := by
  cases f0 with
  | nil => exact absurd rfl h0
  | cons x xs =>
    cases f1 with
    | nil => exact absurd rfl h1
    | cons y ys =>
      simp only [ceFrameTrace, runTrace, ceC_reset_forgets s x y]

/-! ## 3. THE DESTINATION DECODER — the `key` the seam transports -/

/-- Read a destination back out of a convention-C frame's three ODD header
cycles. (Same function as `ScratchFrameB.cDestOf`; restated here because that
file is unpromoted scratch.) -/
def cDestRd (s : List Bool) : Nat :=
  (if s.getD 1 false then 4 else 0) + (if s.getD 3 false then 2 else 0)
    + (if s.getD 5 false then 1 else 0)

/-- The decoder inverts an ACTIVE frame's header, for any payload. -/
theorem cDestRd_cFrame (d : Nat) (hd : d < 8) (p : List Bool) :
    cDestRd (cFrame true d p) = d := by
  interval_cases d <;> rfl

/-! ## 4. ⭐⭐⭐ `ElemSortsAt` DISCHARGED — the element half consumed by the
network half

Everything the network fold assumed about one comparator is now PROVED from:
  * hypothesis ①  the caller's rst column (`hrst0` + `hrst`), and
  * hypothesis ②  the frame shape on the comparator's two input wires
                  (`hf0` + `hf1`), with distinct destinations.
No further fact about the circuit is used. -/

theorem ElemSortsAt_of_cFrames
    (st : List Bool) (inp : List Bool) (is : List (List Bool)) (k : Nat)
    (key : List Bool → Nat)
    (hrst0 : inp.getD 0 false = true)
    (hrst : ∀ i ∈ is, i.getD 0 false = false)
    (d0 d1 : Nat) (p0 p1 : List Bool)
    (hd0 : d0 < 8) (hd1 : d1 < 8) (hne : d0 ≠ d1)
    (hk0 : key (cFrame true d0 p0) = d0) (hk1 : key (cFrame true d1 p1) = d1)
    (hf0 : bnCFrameAt st (inp :: is) k (bnCCompAt k).1 = cFrame true d0 p0)
    (hf1 : bnCFrameAt st (inp :: is) k (bnCCompAt k).2 = cFrame true d1 p1) :
    ElemSortsAt st (inp :: is) k (fun x y => decide (key x ≤ key y)) := by
  have hL0 : (cFrame true d0 p0).length = (inp :: is).length := by
    rw [← hf0]; exact bnCFrameAt_length st (inp :: is) k (bnCCompAt k).1
  have hL1 : (cFrame true d1 p1).length = (inp :: is).length := by
    rw [← hf1]; exact bnCFrameAt_length st (inp :: is) k (bnCCompAt k).2
  have hp : p0.length = p1.length := by
    have h := hL0.trans hL1.symm
    rw [cFrame_length, cFrame_length] at h
    omega
  refine ⟨?_, ?_⟩ <;>
    simp only [hf0, hf1,
      ceCPort_eq_frameTrace (bnCSlice st k) inp is (cFrame true d0 p0) (cFrame true d1 p1)
        0 hrst0 hrst (le_of_eq hL0),
      ceCPort_eq_frameTrace (bnCSlice st k) inp is (cFrame true d0 p0) (cFrame true d1 p1)
        1 hrst0 hrst (le_of_eq hL0),
      runTrace_ceC_frameTrace_any_state (bnCSlice st k) (cFrame true d0 p0)
        (cFrame true d1 p1) (cFrame_ne_nil true d0 p0) (cFrame_ne_nil true d1 p1),
      ceC_pair_full_load_out0 d0 d1 hd0 hd1 hne p0 p1 hp,
      ceC_pair_full_load_out1 d0 d1 hd0 hd1 hne p0 p1 hp,
      cKeyLE_full_load, hk0, hk1]

/-! ## 5. THE CAPSTONE — the whole network theorem, element premise removed

`bnC_output_keys_are_runNetN`'s hypothesis was `∀ k < 24, ElemSortsAt …`, i.e.
the sorting fact ASSUMED. Here it is replaced by the two hypotheses the recorded
gap named, neither of which is about the circuit. -/

theorem bnC_output_keys_of_frames
    (st : List Bool) (inp : List Bool) (is : List (List Bool))
    (hrst0 : inp.getD 0 false = true)
    (hrst : ∀ i ∈ is, i.getD 0 false = false)
    (hframes : ∀ k, k < 24 → ∃ d0 d1 : Nat, ∃ p0 p1 : List Bool,
        d0 < 8 ∧ d1 < 8 ∧ d0 ≠ d1 ∧
        bnCFrameAt st (inp :: is) k (bnCCompAt k).1 = cFrame true d0 p0 ∧
        bnCFrameAt st (inp :: is) k (bnCCompAt k).2 = cFrame true d1 p1)
    (w : Nat) (hw : w < 8) :
    cDestRd ((runTrace batcherNetC st (inp :: is)).1.map (fun o => o.getD w false))
      = runNetN bnComps (fun i => cDestRd (bnCFrameAt st (inp :: is) 0 i)) w := by
  refine bnC_output_keys_are_runNetN st (inp :: is) cDestRd ?_ w hw
  intro k hk
  obtain ⟨d0, d1, p0, p1, hd0, hd1, hne, hf0, hf1⟩ := hframes k hk
  exact ElemSortsAt_of_cFrames st inp is k cDestRd hrst0 hrst d0 d1 p0 p1 hd0 hd1 hne
    (cDestRd_cFrame d0 hd0 p0) (cDestRd_cFrame d1 hd1 p1) hf0 hf1

/-! ## 6. ⭐ THE FRAME INVARIANT'S INDUCTION STEP

Hypothesis ② is *preserved*, not re-established: if comparator `k`'s two input
wires carry active frames with DISTINCT destinations, then after stage `k` its
two output wires carry active frames again (destinations `min`/`max`, payloads
swapped with them), and every other wire is untouched. Destinations stay
distinct because `{min d0 d1, max d0 d1} = {d0, d1}`. -/

theorem bnCFrameAt_succ_frames
    (st : List Bool) (inp : List Bool) (is : List (List Bool)) (k : Nat) (hk : k < 24)
    (hrst0 : inp.getD 0 false = true)
    (hrst : ∀ i ∈ is, i.getD 0 false = false)
    (d0 d1 : Nat) (p0 p1 : List Bool)
    (hd0 : d0 < 8) (hd1 : d1 < 8) (hne : d0 ≠ d1)
    (hf0 : bnCFrameAt st (inp :: is) k (bnCCompAt k).1 = cFrame true d0 p0)
    (hf1 : bnCFrameAt st (inp :: is) k (bnCCompAt k).2 = cFrame true d1 p1) :
    bnCFrameAt st (inp :: is) (k + 1) (bnCCompAt k).1
        = cFrame true (min d0 d1) (if d0 ≤ d1 then p0 else p1)
      ∧ bnCFrameAt st (inp :: is) (k + 1) (bnCCompAt k).2
        = cFrame true (max d0 d1) (if d0 ≤ d1 then p1 else p0)
      ∧ ∀ w, w ≠ (bnCCompAt k).1 → w ≠ (bnCCompAt k).2 →
          bnCFrameAt st (inp :: is) (k + 1) w = bnCFrameAt st (inp :: is) k w := by
  have hES := ElemSortsAt_of_cFrames st inp is k cDestRd hrst0 hrst d0 d1 p0 p1 hd0 hd1 hne
    (cDestRd_cFrame d0 hd0 p0) (cDestRd_cFrame d1 hd1 p1) hf0 hf1
  have hstep : ∀ w, bnCFrameAt st (inp :: is) (k + 1) w
      = applyCompF (fun x y => decide (cDestRd x ≤ cDestRd y)) (bnCCompAt k)
          (fun i => bnCFrameAt st (inp :: is) k i) w := fun w =>
    bnCFrameAt_succ_sorted st (inp :: is) k
      (fun x y => decide (cDestRd x ≤ cDestRd y)) hk hES w
  have hc : (bnCCompAt k).1 ≠ (bnCCompAt k).2 := bnCCompAt_ne k hk
  refine ⟨?_, ?_, ?_⟩
  · rw [hstep (bnCCompAt k).1]
    by_cases h : d0 ≤ d1
    · simp [applyCompF, hf0, hf1, cDestRd_cFrame d0 hd0 p0, cDestRd_cFrame d1 hd1 p1, h]
    · have h' : d1 ≤ d0 := Nat.le_of_lt (Nat.lt_of_not_le h)
      simp [applyCompF, hf0, hf1, cDestRd_cFrame d0 hd0 p0, cDestRd_cFrame d1 hd1 p1,
        h, Nat.min_eq_right h']
  · rw [hstep (bnCCompAt k).2]
    by_cases h : d0 ≤ d1
    · simp [applyCompF, if_neg (Ne.symm hc), hf0, hf1, cDestRd_cFrame d0 hd0 p0,
        cDestRd_cFrame d1 hd1 p1, h]
    · have h' : d1 ≤ d0 := Nat.le_of_lt (Nat.lt_of_not_le h)
      simp [applyCompF, if_neg (Ne.symm hc), hf0, hf1, cDestRd_cFrame d0 hd0 p0,
        cDestRd_cFrame d1 hd1 p1, h, Nat.max_eq_left h']
  · intro w hw1 hw2
    rw [hstep w]
    simp only [applyCompF, if_neg hw1, if_neg hw2]

/-- The step keeps the destinations in range and DISTINCT — so the invariant's
`hne`, which `ceC_pair_full_load` needs, survives the stage that consumes it. -/
theorem minmax_lt_eight_ne (d0 d1 : Nat) (hd0 : d0 < 8) (hd1 : d1 < 8) (hne : d0 ≠ d1) :
    min d0 d1 < 8 ∧ max d0 d1 < 8 ∧ min d0 d1 ≠ max d0 d1 := by
  omega

#audit_axioms zip3Trace_eq_ceBody zip3Trace_eq_ceFrameTrace
#audit_axioms zip3Trace_bridge_fixture zip3Trace_needs_rst_low zip3Trace_needs_length
#audit_axioms ceCPort_eq_frameTrace runTrace_ceC_frameTrace_any_state
#audit_axioms cDestRd cDestRd_cFrame
#audit_axioms ElemSortsAt_of_cFrames bnC_output_keys_of_frames
#audit_axioms bnCFrameAt_succ_frames minmax_lt_eight_ne

/-! ### ③ node L3 — the composition (the fold leg of §2's CLAIM)

The payload-delivery block routes L3 through two theorems that were **already landed before
the block was written**: `bnC_output_frames_are_the_fold` (SeamTrace — whole-frame,
payload-carrying, with a free comparison `le`) and `elemSortsAt_all` (SeamJoinA — which
produces exactly that theorem's `ElemSortsAt` premise, with `le` fixed at
`decide (cDestOf · ≤ cDestOf ·)`).  Composing them pins the free `le` and is the whole content.

**It needs nothing from L0/L1/L2.**  The wave-gates map placed L3 behind the element lemmas;
that dependency came from the decomposition's shape, not its substance.

Scope, so the label is not overread: this is the **fold leg** — *output column `w` = the network
fold of the stage-0 input frames*.  §2's CLAIM (`output (dest i) t = input i t`) needs two more
steps: evaluating the fold at `dest i`, which is L4, and reading the payload out of the frame,
which is `cFrame_true_expand` (a `rfl`; the payload sits at indices `6..`). -/
theorem bnC_output_frames_of_stageOK (st : List Bool) (tr : List (List Bool)) (n L : Nat)
    (hrst : tr.map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (h0 : StageOK st tr L 0) (w : Nat) (hw : w < 8) :
    (runTrace batcherNetC st tr).1.map (fun o => o.getD w false)
      = runNetF (fun x y => decide (cDestOf x ≤ cDestOf y)) bnComps
          (fun i => bnCFrameAt st tr 0 i) w :=
  bnC_output_frames_are_the_fold st tr _ (elemSortsAt_all st tr n L hrst h0) w hw

#audit_axioms bnC_output_frames_of_stageOK

end SaltWorks.HDL
