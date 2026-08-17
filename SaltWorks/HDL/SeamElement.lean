/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.SeamTrace

/-!
# ONE COMPARATOR AT FULL LOAD — the whole frame, arbitrary payload

The element-level premise the network induction must consume, in the form that
folds: at full load with **distinct** destinations, the element's two output
frames are its two input frames reordered by `cKeyLE` — headers included, payload
of any length, from **any** initial element state.
-/

namespace SaltWorks.HDL

/-- Two bit streams interleaved into the two-output-port shape `runTrace` returns. -/
def ceIL (f0 f1 : List Bool) : List (List Bool) :=
  List.zipWith (fun x y => [x, y]) f0 f1

/-- Payload cycles: `rst` low, one bit from each line. -/
def ceBody (p0 p1 : List Bool) : List (List Bool) :=
  List.zipWith (fun x y => [false, x, y]) p0 p1

/-- The element's input trace for two frames: `rst` high on cycle 0 only. This
is `bnCElemTrace`'s shape — `[rst, bit0, bit1]` per cycle. -/
def ceFrameTrace : List Bool → List Bool → List (List Bool)
  | x :: xs, y :: ys => [true, x, y] :: ceBody xs ys
  | _, _ => []

/-- The six header cycles of a convention-C frame. -/
def ceHdr (a : Bool) (d : Nat) : List Bool := cFrame a d []

-- ===================== FRAME ALGEBRA =====================

theorem cFrame_split (a : Bool) (d : Nat) (p : List Bool) :
    cFrame a d p = ceHdr a d ++ p := by
  simp [ceHdr, cFrame]

theorem ceHdr_length (a : Bool) (d : Nat) : (ceHdr a d).length = 6 := rfl

theorem ceHdr_ne_nil (a : Bool) (d : Nat) : ceHdr a d ≠ [] := by
  intro h
  have h6 := congrArg List.length h
  rw [ceHdr_length] at h6
  simp at h6

theorem cFrame_length (a : Bool) (d : Nat) (p : List Bool) :
    (cFrame a d p).length = 6 + p.length := by
  rw [cFrame_split]; simp [ceHdr_length]

theorem cFrame_ne_nil (a : Bool) (d : Nat) (p : List Bool) : cFrame a d p ≠ [] := by
  intro h
  have h6 := congrArg List.length h
  rw [cFrame_length] at h6
  simp at h6

theorem ceIL_append (h0 h1 p0 p1 : List Bool) (hlen : h0.length = h1.length) :
    ceIL h0 h1 ++ ceIL p0 p1 = ceIL (h0 ++ p0) (h1 ++ p1) :=
  (List.zipWith_append hlen).symm

theorem ceFrameTrace_append (h0 h1 p0 p1 : List Bool)
    (hne : h0 ≠ []) (hlen : h0.length = h1.length) :
    ceFrameTrace (h0 ++ p0) (h1 ++ p1) = ceFrameTrace h0 h1 ++ ceBody p0 p1 := by
  cases h0 with
  | nil => exact absurd rfl hne
  | cons x xs =>
    cases h1 with
    | nil => simp at hlen
    | cons y ys =>
      have hxy : xs.length = ys.length := by simpa using hlen
      simp only [List.cons_append, ceFrameTrace, ceBody]
      rw [List.zipWith_append hxy]

theorem ceIL_map_fst : ∀ (f0 f1 : List Bool), f0.length = f1.length →
    (ceIL f0 f1).map (fun o => o.getD 0 false) = f0 := by
  intro f0
  induction f0 with
  | nil => intro f1 _; simp [ceIL]
  | cons x xs ih =>
    intro f1 h
    cases f1 with
    | nil => simp at h
    | cons y ys =>
      simp only [ceIL, List.zipWith_cons_cons, List.map_cons, List.cons.injEq]
      refine ⟨rfl, ?_⟩
      simpa [ceIL] using ih ys (by simpa using h)

theorem ceIL_map_snd : ∀ (f0 f1 : List Bool), f0.length = f1.length →
    (ceIL f0 f1).map (fun o => o.getD 1 false) = f1 := by
  intro f0
  induction f0 with
  | nil =>
    intro f1 h
    have hf : f1 = [] := by
      cases f1 with
      | nil => rfl
      | cons _ _ => simp at h
    simp [ceIL, hf]
  | cons x xs ih =>
    intro f1 h
    cases f1 with
    | nil => simp at h
    | cons y ys =>
      simp only [ceIL, List.zipWith_cons_cons, List.map_cons, List.cons.injEq]
      refine ⟨rfl, ?_⟩
      simpa [ceIL] using ih ys (by simpa using h)

-- ===================== ONE CYCLE =====================

/-- With `dec = true` and `rst = false` the element is a pure two-way mux with a
constant select, and it stays decided. -/
theorem ceC_step_decided (s ph ba x y : Bool) :
    stepSeq ceC [true, s, ph, ba] [false, x, y]
      = ([if s then y else x, if s then x else y],
         [true, s, !ph, (!ph && (x && y)) || (ph && ba)]) := by
  cases s <;> cases ph <;> cases ba <;> cases x <;> cases y <;> decide +kernel

/-- ⭐ **THE RESET CYCLE ERASES THE STATE.** With `rst` high the next state and
the outputs do not depend on any of the four state bits. *This is what removes
the recorded hypothesis "pinned at the all-false initial element state".* -/
theorem ceC_step_reset (a b c d x y : Bool) :
    stepSeq ceC [a, b, c, d] [true, x, y]
      = stepSeq ceC [false, false, false, false] [true, x, y] := by
  cases a <;> cases b <;> cases c <;> cases d <;> cases x <;> cases y <;> decide +kernel

/-- …lifted to a whole frame: any initial state gives the same run, because
every `ceFrameTrace` begins with a reset cycle. -/
theorem ceFrameTrace_from_any_state (a b c d : Bool) (f0 f1 : List Bool)
    (h0 : f0 ≠ []) (h1 : f1 ≠ []) :
    runTrace ceC [a, b, c, d] (ceFrameTrace f0 f1)
      = runTrace ceC [false, false, false, false] (ceFrameTrace f0 f1) := by
  cases f0 with
  | nil => exact absurd rfl h0
  | cons x xs =>
    cases f1 with
    | nil => exact absurd rfl h1
    | cons y ys =>
      simp only [ceFrameTrace, runTrace, ceC_step_reset]

-- ===================== THE PAYLOAD LIFT =====================

theorem ceC_body_mux_raw : ∀ (p0 p1 : List Bool) (s ph ba : Bool),
    (runTrace ceC [true, s, ph, ba] (ceBody p0 p1)).1
      = List.zipWith (fun x y => [if s then y else x, if s then x else y]) p0 p1 := by
  intro p0
  induction p0 with
  | nil => intro p1 s ph ba; simp [ceBody, runTrace]
  | cons x xs ih =>
    intro p1 s ph ba
    cases p1 with
    | nil => simp [ceBody, runTrace]
    | cons y ys =>
      simp only [ceBody, List.zipWith_cons_cons, runTrace, ceC_step_decided]
      simp only [ceBody] at ih
      rw [ih]

/-- ⭐ **A DECIDED ELEMENT ROUTES A PAYLOAD OF ANY LENGTH** — the swap bit
latched by the header is a constant mux select for the rest of the frame. -/
theorem ceC_body_mux (p0 p1 : List Bool) (s ph ba : Bool) :
    (runTrace ceC [true, s, ph, ba] (ceBody p0 p1)).1
      = ceIL (if s then p1 else p0) (if s then p0 else p1) := by
  rw [ceC_body_mux_raw]
  cases s with
  | false => simp [ceIL]
  | true =>
    simp only [if_true, ceIL]
    exact List.zipWith_comm

-- ===================== THE HEADER =====================

/-- The six header cycles, over every ordered pair of DISTINCT destinations the
3-bit fabric can carry, at full load: 64 pairs, 56 checked. -/
def ceHdrOK : Bool :=
  (List.range 8).all fun d0 => (List.range 8).all fun d1 =>
    (d0 == d1) ||
    decide (runTrace ceC [false, false, false, false]
              (ceFrameTrace (ceHdr true d0) (ceHdr true d1))
            = (ceIL (if cKeyLE (cKey true d0) (cKey true d1) then ceHdr true d0
                     else ceHdr true d1)
                    (if cKeyLE (cKey true d0) (cKey true d1) then ceHdr true d1
                     else ceHdr true d0),
               [true, !(cKeyLE (cKey true d0) (cKey true d1)), false, true]))

/-- ⭐ **THE HEADER IS DECIDED AND ALREADY ROUTED AFTER SIX CYCLES.** The
element emits the *routed* headers — not merely the right payload later — and
leaves the state `[decided, swap, ph, ba] = [true, !cKeyLE, false, true]`.
*The mux can only flip at the first cycle where the two headers differ, and
before that cycle the two headers are equal, so the pre-decision mux choice is
invisible.* -/
theorem ceC_hdrOK : ceHdrOK = true := by decide +kernel

theorem ceC_header_routes (d0 d1 : Nat) (h0 : d0 < 8) (h1 : d1 < 8) (hne : d0 ≠ d1) :
    runTrace ceC [false, false, false, false]
        (ceFrameTrace (ceHdr true d0) (ceHdr true d1))
      = (ceIL (if cKeyLE (cKey true d0) (cKey true d1) then ceHdr true d0 else ceHdr true d1)
              (if cKeyLE (cKey true d0) (cKey true d1) then ceHdr true d1 else ceHdr true d0),
         [true, !(cKeyLE (cKey true d0) (cKey true d1)), false, true]) := by
  have hB := List.all_eq_true.mp
    (List.all_eq_true.mp ceC_hdrOK d0 (List.mem_range.mpr h0)) d1 (List.mem_range.mpr h1)
  simp only [Bool.or_eq_true, beq_iff_eq, decide_eq_true_eq] at hB
  exact hB.resolve_left hne

-- ===================== THE WHOLE FRAME =====================

/-- ⭐⭐ **ONE COMPARATOR AT FULL LOAD, WHOLE FRAME, ARBITRARY PAYLOAD.**
The element's two output frames ARE its two input frames reordered by `cKeyLE` —
header bits included, payload of any length. *This is the element-level premise
the network induction must consume; `ceC_realises_cKey_when_active` cannot
supply it, being `.drop 6` (header-blind) and pinned to two literal payload
tags.* -/
theorem ceC_pair_full_load (d0 d1 : Nat) (hd0 : d0 < 8) (hd1 : d1 < 8) (hne : d0 ≠ d1)
    (p0 p1 : List Bool) :
    (runTrace ceC [false, false, false, false]
        (ceFrameTrace (cFrame true d0 p0) (cFrame true d1 p1))).1
      = ceIL (if cKeyLE (cKey true d0) (cKey true d1) then cFrame true d0 p0
              else cFrame true d1 p1)
             (if cKeyLE (cKey true d0) (cKey true d1) then cFrame true d1 p1
              else cFrame true d0 p0) := by
  rw [cFrame_split true d0 p0, cFrame_split true d1 p1,
      ceFrameTrace_append _ _ _ _ (ceHdr_ne_nil true d0)
        (by rw [ceHdr_length, ceHdr_length]),
      runTrace_append, ceC_header_routes d0 d1 hd0 hd1 hne]
  simp only [ceC_body_mux]
  cases hsw : cKeyLE (cKey true d0) (cKey true d1) with
  | false => exact ceIL_append _ _ _ _ rfl
  | true => exact ceIL_append _ _ _ _ rfl

/-- ⭐ **…AND FROM ANY INITIAL ELEMENT STATE.** *Recorded hypothesis (1) — "the
discharge closes only for frames whose element state is all-false at frame
start" — is REMOVED: the frame's own reset cycle erases the state.* -/
theorem ceC_pair_full_load_any_state (a b c d : Bool)
    (d0 d1 : Nat) (hd0 : d0 < 8) (hd1 : d1 < 8) (hne : d0 ≠ d1) (p0 p1 : List Bool) :
    (runTrace ceC [a, b, c, d]
        (ceFrameTrace (cFrame true d0 p0) (cFrame true d1 p1))).1
      = ceIL (if cKeyLE (cKey true d0) (cKey true d1) then cFrame true d0 p0
              else cFrame true d1 p1)
             (if cKeyLE (cKey true d0) (cKey true d1) then cFrame true d1 p1
              else cFrame true d0 p0) := by
  rw [ceFrameTrace_from_any_state a b c d _ _ (cFrame_ne_nil true d0 p0)
        (cFrame_ne_nil true d1 p1)]
  exact ceC_pair_full_load d0 d1 hd0 hd1 hne p0 p1

-- ===================== THE FOLDABLE FORMS =====================

/-- At full load the key degenerates to numeric order on destinations. -/
theorem cKeyLE_full_load (d0 d1 : Nat) :
    cKeyLE (cKey true d0) (cKey true d1) = decide (d0 ≤ d1) := by
  simp [cKeyLE, cKey]

/-- ⭐ **`applyComp`'s SHAPE, AT THE ELEMENT** — the low port carries the frame
bound for `min d0 d1`, the high port the one bound for `max d0 d1`. *This is the
form the `runNet batcher8` fold consumes.* -/
theorem ceC_pair_full_load_minmax (d0 d1 : Nat) (hd0 : d0 < 8) (hd1 : d1 < 8)
    (hne : d0 ≠ d1) (p0 p1 : List Bool) :
    (runTrace ceC [false, false, false, false]
        (ceFrameTrace (cFrame true d0 p0) (cFrame true d1 p1))).1
      = ceIL (cFrame true (min d0 d1) (if d0 ≤ d1 then p0 else p1))
             (cFrame true (max d0 d1) (if d0 ≤ d1 then p1 else p0)) := by
  rw [ceC_pair_full_load d0 d1 hd0 hd1 hne, cKeyLE_full_load]
  by_cases h : d0 ≤ d1
  · simp [h]
  · have h' : d1 ≤ d0 := Nat.le_of_lt (Nat.lt_of_not_le h)
    simp [h, Nat.min_eq_right h', Nat.max_eq_left h']

/-- The low output port, de-interleaved — matches `ceCOut 0`'s shape. -/
theorem ceC_pair_full_load_out0 (d0 d1 : Nat) (hd0 : d0 < 8) (hd1 : d1 < 8)
    (hne : d0 ≠ d1) (p0 p1 : List Bool) (hp : p0.length = p1.length) :
    (runTrace ceC [false, false, false, false]
        (ceFrameTrace (cFrame true d0 p0) (cFrame true d1 p1))).1.map
        (fun o => o.getD 0 false)
      = if cKeyLE (cKey true d0) (cKey true d1) then cFrame true d0 p0
        else cFrame true d1 p1 := by
  rw [ceC_pair_full_load d0 d1 hd0 hd1 hne]
  refine ceIL_map_fst _ _ ?_
  cases cKeyLE (cKey true d0) (cKey true d1) <;>
    simp [cFrame_length, hp]

/-- The high output port, de-interleaved — matches `ceCOut 1`'s shape. -/
theorem ceC_pair_full_load_out1 (d0 d1 : Nat) (hd0 : d0 < 8) (hd1 : d1 < 8)
    (hne : d0 ≠ d1) (p0 p1 : List Bool) (hp : p0.length = p1.length) :
    (runTrace ceC [false, false, false, false]
        (ceFrameTrace (cFrame true d0 p0) (cFrame true d1 p1))).1.map
        (fun o => o.getD 1 false)
      = if cKeyLE (cKey true d0) (cKey true d1) then cFrame true d1 p1
        else cFrame true d0 p0 := by
  rw [ceC_pair_full_load d0 d1 hd0 hd1 hne]
  refine ceIL_map_snd _ _ ?_
  cases cKeyLE (cKey true d0) (cKey true d1) <;>
    simp [cFrame_length, hp]

-- ===================== NON-VACUITY AND CONTROLS =====================

/-- `ceFrameTrace` drives the element exactly as `ceCRun` does: the landed
fixture `ceC_frame_swaps_when_out_of_order` is reproduced through the new
driver, so the new statement is about the same hardware behaviour. -/
theorem ceFrameTrace_reproduces_landed_fixture :
    (runTrace ceC [false, false, false, false]
        (ceFrameTrace (cFrame true 5 [true, false])
                      (cFrame true 2 [false, true]))).1.map (fun o => o.getD 0 false)
      = cFrame true 2 [false, true] := by decide +kernel

/-- ⛔ **`hne` IS LOAD-BEARING, NOT DECORATION.** With two ACTIVE lines carrying
the SAME destination the headers are bit-identical, so no decision fires during
the six header cycles and the element latches on payload bit 0 instead. The
result is a spliced frame — one line's header with the other's payload — still a
well-formed `cFrame` for the right destination, so the defect is invisible to any
header-level invariant. `cKeyLE (cKey true 3) (cKey true 3) = true`, so
`ceC_pair_full_load` would demand `out0 = f0`; it is not. -/
theorem ceC_pair_tie_splices_the_payload :
    (runTrace ceC [false, false, false, false]
        (ceFrameTrace (cFrame true 3 [false, true, true])
                      (cFrame true 3 [true, false, false]))).1
      ≠ ceIL (cFrame true 3 [false, true, true]) (cFrame true 3 [true, false, false]) := by
  decide +kernel

/-- `cePairOut` with the two literal payload tags EXCHANGED. -/
def cePairOutSwapped (k : Nat) (a0 : Bool) (d0 : Nat) (a1 : Bool) (d1 : Nat) : List Bool :=
  let f0 := cFrame a0 d0 [false, true]
  let f1 := cFrame a1 d1 [true, false]
  (runTrace ceC [false, false, false, false]
    ((List.range 8).map fun t =>
      [t == 0, f0.getD t false, f1.getD t false])).1.map (fun o => o.getD k false)

/-- `ceKeyOK`'s exact predicate on the exchanged tags. -/
def ceKeyOKSwapped (skipTies : Bool) : Bool :=
  bools.all fun a0 => (List.range 8).all fun d0 =>
  bools.all fun a1 => (List.range 8).all fun d1 =>
    if (!a0 && !a1) || (skipTies && a0 && a1 && d0 == d1) then true else
    let f0 := cFrame a0 d0 [false, true]
    let f1 := cFrame a1 d1 [true, false]
    let sw := cKeyLE (cKey a0 d0) (cKey a1 d1)
    (cePairOutSwapped 0 a0 d0 a1 d1).drop 6 == (if sw then f0 else f1).drop 6
      && (cePairOutSwapped 1 a0 d0 a1 d1).drop 6 == (if sw then f1 else f0).drop 6

/-- ⛔ **`ceC_realises_cKey_when_active` IS GREEN PARTLY BECAUSE OF THE PAYLOAD
TAGS IT CHOSE.** Exchange the two literal payloads `[true,false]` / `[false,true]`
and the SAME exhaustive check FAILS. *So it is not a payload-general statement
waiting to be generalised — generalising it makes it false, which is why the
whole-frame lemma had to be built from a header/payload decomposition instead of
derived.* -/
theorem ceKeyOK_is_payload_tag_dependent : ceKeyOKSwapped false = false := by
  decide +kernel

/-- ✅ **…AND EXCLUDING DESTINATION TIES REPAIRS IT.** The same exchanged-tag
check passes once both-active-same-destination pairs are skipped — independent
confirmation that ties are the *only* obstruction, which is exactly the `hne`
hypothesis `ceC_pair_full_load` carries. -/
theorem ceKeyOK_swapped_tags_holds_off_ties : ceKeyOKSwapped true = true := by
  decide +kernel

#audit_axioms ceIL ceBody ceFrameTrace ceHdr
#audit_axioms cFrame_split ceHdr_length ceHdr_ne_nil cFrame_length cFrame_ne_nil
#audit_axioms ceIL_append ceFrameTrace_append ceIL_map_fst ceIL_map_snd
#audit_axioms ceC_step_decided ceC_step_reset ceFrameTrace_from_any_state
#audit_axioms ceC_body_mux_raw ceC_body_mux
#audit_axioms ceHdrOK ceC_hdrOK ceC_header_routes
#audit_axioms ceC_pair_full_load ceC_pair_full_load_any_state
#audit_axioms cKeyLE_full_load ceC_pair_full_load_minmax
#audit_axioms ceC_pair_full_load_out0 ceC_pair_full_load_out1
#audit_axioms ceFrameTrace_reproduces_landed_fixture ceC_pair_tie_splices_the_payload
#audit_axioms cePairOutSwapped ceKeyOKSwapped
#audit_axioms ceKeyOK_is_payload_tag_dependent ceKeyOK_swapped_tags_holds_off_ties

end SaltWorks.HDL
