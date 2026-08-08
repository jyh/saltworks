/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.SeamElement

/-!
# L1 OF THE PAYLOAD-DELIVERY BLOCK — the Batcher element under H3, at P = 8

`docs/payload-delivery-design-v1.md` §3, L1 (v2.3):

> Under H3, after its decide the compare-exchange element is a **static
> 2-permutation of its two lines for the rest of the frame**. The undecided cases
> are THREE, not two.

SCOPE: the tapeout instance **P = 8** — frame = 6 header cycles + 8 payload
cycles = 14. ∀-P is not attempted (§5's deferral).

## ⛔ THREE FINDINGS THIS FILE CARRIES AGAINST THE BLOCK'S OWN v2.3 TEXT

**(1) CASE (a) AS v2.3 WORDS IT IS FALSE OFF-PROTOCOL — counterexample PROVED.**
*"Two idles = straight-through"* is TRUE, but not for the stated reason. It holds
because an on-protocol idle line is silent for the WHOLE frame — **not** because
idleness stops the decide. `l1_case_a_needs_silent_payloads`: two lines with idle
headers and DIFFERING payloads decide on payload bit 0 by the even-phase activity
rule (`bothAct` gates only the ODD-phase decision) and **swap the payloads**.
⇒ ***Right conclusion, wrong reason — and the reason is what a partial-load successor
inherits, where idle lines are no longer guaranteed silent.***

**(2) CASES (a) AND (b) ARE ONE MECHANISM, and the case list is provably complete.**
Undecided-after-header ⟺ the two headers are BIT-IDENTICAL ⟺ two idles ∨ an active
tie (`l1_undecided_iff_headers_identical`, `l1_the_three_cases_are_exhaustive`, over
all 256 header pairs). **There is no fourth case**, and (a) is just the sub-case where
the splice is unobservable because both payloads are zero.

**(3) THE ELEMENT LEG OF L1 IS ALREADY ∀-P.** `l1_decided_after_any_prefix` is
parametric in `(n, m)` with no 6/8/14 anywhere; the 14 enters ONLY through H3's literal
reset column and the concrete controls. ⇒ ***This independently sharpens the R1
finding that the ∀-P price is the DRIVER (`runFrame`'s hardcoded 14), not the element.***

## ⭐ WHY A NEW `elemTrace` EXISTS RATHER THAN REUSING THE LANDED DRIVER

The landed element lemmas **bake H3 into their driver**: `ceFrameTrace` is
`[true,x,y] :: ceBody xs ys` — `rst` high at cycle 0 and structurally low forever
after. **So there is no reset column to vary, and `ceC_pair_full_load` cannot even
STATE the H3-dropped mutant.** This file lifts the reset column to a free variable,
proves its columns ARE B4's columns, and proves `elemTrace h3Hdr x y = ceFrameTrace x y`
so every landed header theorem still instantiates. *A hypothesis cannot be shown
load-bearing against a driver that hardcodes it.*

## Why this file exists at all, given `ceC_pair_full_load` is landed

⛔ **THE LANDED ELEMENT LEMMAS BAKE H3 INTO THEIR DRIVER, WHICH IS WHY H3 WAS
INVISIBLE UNTIL THE ③ PASS.** `ceFrameTrace` (`SeamElement.lean:24`) is

```
| x :: xs, y :: ys => [true, x, y] :: ceBody xs ys        -- ceBody: [false, x, y]
```

— `rst` HIGH on cycle 0 and structurally LOW ever after. There is no reset column
to vary, so `ceC_pair_full_load` cannot *state* the H3-dropped mutant, let alone
be refuted by it. **This file lifts the reset column to a free variable `r`**
(`elemTrace` below), states H3 as the hypothesis `r = h3Rst`, and pays for it with
the negative control at the end: with one extra `rst` pulse mid-payload the
conclusion is FALSE at the kernel. *A device that cannot fail proves nothing.*

## What is instantiated, not re-proved

* `ceC_step_decided` (`SeamElement.lean:110`) — decided ⇒ constant-select mux,
  and `decided' = true`, `swap' = s`: the staying power;
* `ceC_body_mux` / `ceC_body_mux_raw` (`:157` / `:140`) — the payload lift;
* `ceC_step_reset` (`:119`) — the reset cycle erases the state (⇒ ∀ initial state);
* `ceC_header_routes` (`:190`) — the six header cycles, so `hdec` is DISCHARGED
  rather than assumed (non-vacuity);
* `ceC_frame_two_idle_stable` (`CompareExchangeC.lean:232`) — case (a)'s landed
  form. ⚠️ `ceC_rejects_idle_sorts_low` (`:249`) is a MUTATION CONTROL about
  `ceCIdleLow`, a one-gate mutant — a DIFFERENT DEVICE, not this statement;
* `ceC_pair_tie_splices_the_payload` (`:307`) — case (b)'s landed form.

## THREE FINDINGS THIS FILE ADDS (all measured on `ceC`, none of them design text)

1. **The undecided condition is "the two headers are bit-identical"**, and that is
   exhaustively equivalent to (both idle) ∨ (both active, equal destination) —
   `l1_the_three_cases_are_exhaustive`, `l1_undecided_iff_headers_identical`. So
   the case list is COMPLETE: there is no fourth case.
2. ⛔ **CASE (a) AS THE DESIGN WORDS IT IS FALSE OFF-PROTOCOL.** "Two idles =
   straight-through" holds because an on-protocol idle line is silent for the
   WHOLE frame (payload included), not because idleness stops the decide. Two
   lines with idle HEADERS and DIFFERING payloads decide on payload bit 0 by the
   even-phase activity rule and **swap** — `l1_case_a_needs_silent_payloads`.
   Cases (a) and (b) are therefore ONE mechanism (identical headers ⇒ decide on
   the payload); (a) is the sub-case where the splice is unobservable because both
   payloads are zero.
3. **`hdec` is not an assumption at full load** — `l1_hdec_from_landed_header`
   discharges it from `ceC_header_routes`, so `l1_full_load_payload_delivery`
   carries only H3 + distinctness + the P = 8 lengths.
-/

namespace L1Payload

open SaltWorks.HDL

/-! ## 0. THE DRIVER, WITH THE RESET COLUMN FREE -/

/-- The element's input trace with the reset column **as a free variable**: one
`[rst, in0, in1]` cycle per entry — `bnCElemTrace`'s shape (`SeamTrace.lean:521`),
and the shape B4's binders read (`rst` at column 0, line `i` at column `1 + i`).
*Contrast `ceFrameTrace`, which hardcodes the reset column and so cannot express
H3's negation.* -/
def elemTrace (r x y : List Bool) : List (List Bool) :=
  List.zipWith (fun rr c => rr :: c) r (ceIL x y)

/-- H3's reset column over the six HEADER cycles. -/
def h3Hdr : List Bool := [true, false, false, false, false, false]

/-- ⭐ **H3 AT P = 8**, in the split form the proof consumes: six header cycles,
then eight payload cycles all LOW. -/
def h3Rst : List Bool := h3Hdr ++ List.replicate 8 false

/-- ⭐ **H3 IS B4's `hrst` BINDER AT `n = 13`, CHARACTER FOR CHARACTER**
(`SeamJoinB.lean:192`: `tr.map (fun i => i.getD 0 false) = true ::
List.replicate n false`). -/
theorem h3Rst_is_b4_hrst : h3Rst = true :: List.replicate 13 false := by rfl

/-- One pulse, at cycle 0, and none after — 14 cycles, exactly one `true`. -/
theorem h3Rst_is_one_pulse_at_cycle_zero :
    h3Rst.length = 14 ∧ h3Rst.countP id = 1 ∧ h3Rst.getD 0 false = true := by
  decide +kernel

theorem elemTrace_cons (r0 x0 y0 : Bool) (rs xs ys : List Bool) :
    elemTrace (r0 :: rs) (x0 :: xs) (y0 :: ys) = [r0, x0, y0] :: elemTrace rs xs ys := by
  simp [elemTrace, ceIL]

theorem ceBody_cons (x0 y0 : Bool) (xs ys : List Bool) :
    ceBody (x0 :: xs) (y0 :: ys) = [false, x0, y0] :: ceBody xs ys := by
  simp [ceBody]

theorem elemTrace_length (r x y : List Bool) :
    (elemTrace r x y).length = min r.length (min x.length y.length) := by
  simp [elemTrace, ceIL]

/-- The output trace has one cycle per input cycle. *Needed so the payload
window's UPPER bound is pinned: 14 cycles total, `drop 6` leaves exactly 8.* -/
theorem runTrace_length (m : Seq) : ∀ (st : List Bool) (tr : List (List Bool)),
    (runTrace m st tr).1.length = tr.length := by
  intro st tr
  induction tr generalizing st with
  | nil => rfl
  | cons i is ih =>
    have h : runTrace m st (i :: is)
        = ((stepSeq m st i).1 :: (runTrace m (stepSeq m st i).2 is).1,
           (runTrace m (stepSeq m st i).2 is).2) := rfl
    rw [h]
    simpa using ih (stepSeq m st i).2

/-! ### The trace's columns ARE B4's columns -/

theorem map_getD0_zipWith_cons : ∀ (r : List Bool) (l : List (List Bool)),
    r.length = l.length →
    (List.zipWith (fun rr c => rr :: c) r l).map (fun c => c.getD 0 false) = r := by
  intro r
  induction r with
  | nil => intro l _; simp
  | cons a as ih =>
    intro l h
    cases l with
    | nil => simp at h
    | cons b bs => simpa using ih bs (by simpa using h)

theorem map_getD_succ_zipWith_cons (j : Nat) : ∀ (r : List Bool) (l : List (List Bool)),
    r.length = l.length →
    (List.zipWith (fun rr c => rr :: c) r l).map (fun c => c.getD (j + 1) false)
      = l.map (fun c => c.getD j false) := by
  intro r
  induction r with
  | nil =>
    intro l h
    cases l with
    | nil => simp
    | cons _ _ => simp at h
  | cons a as ih =>
    intro l h
    cases l with
    | nil => simp at h
    | cons b bs => simpa using ih bs (by simpa using h)

/-- ⭐ **COLUMN 0 IS THE RESET COLUMN** — so `hrst` on `elemTrace r x y` says
exactly `r = …`, and H3 is a hypothesis about the stimulus, not about the driver. -/
theorem elemTrace_rst_column (r x y : List Bool)
    (hr : r.length = x.length) (hxy : x.length = y.length) :
    (elemTrace r x y).map (fun c => c.getD 0 false) = r := by
  refine map_getD0_zipWith_cons r (ceIL x y) ?_
  simp [ceIL, hr, hxy]

/-- Column 1 is line 0 — B4's `hin` at `i = 0`. -/
theorem elemTrace_line0_column (r x y : List Bool)
    (hr : r.length = x.length) (hxy : x.length = y.length) :
    (elemTrace r x y).map (fun c => c.getD 1 false) = x := by
  rw [elemTrace, map_getD_succ_zipWith_cons 0 r (ceIL x y) (by simp [ceIL, hr, hxy])]
  exact ceIL_map_fst x y hxy

/-- Column 2 is line 1 — B4's `hin` at `i = 1`. -/
theorem elemTrace_line1_column (r x y : List Bool)
    (hr : r.length = x.length) (hxy : x.length = y.length) :
    (elemTrace r x y).map (fun c => c.getD 2 false) = y := by
  rw [elemTrace, map_getD_succ_zipWith_cons 1 r (ceIL x y) (by simp [ceIL, hr, hxy])]
  exact ceIL_map_snd x y hxy

/-! ## 1. THE FRAME ALGEBRA H3 IS SPENT ON -/

/-- The frame splits at any cycle: at P = 8 the split of interest is
6 header cycles ++ 8 payload cycles. -/
theorem elemTrace_split (n : Nat) (r0 r1 h0 h1 p0 p1 : List Bool)
    (hr : r0.length = n) (hh0 : h0.length = n) (hh1 : h1.length = n) :
    elemTrace (r0 ++ r1) (h0 ++ p0) (h1 ++ p1)
      = elemTrace r0 h0 h1 ++ elemTrace r1 p0 p1 := by
  have hlen : r0.length = (ceIL h0 h1).length := by simp [ceIL, hr, hh0, hh1]
  simp only [elemTrace]
  rw [← ceIL_append h0 h1 p0 p1 (by rw [hh0, hh1])]
  exact List.zipWith_append hlen

/-- ⭐ **THIS IS WHERE H3 IS SPENT.** With the reset column LOW the trace *is*
`ceBody` — the rst-free payload trace `ceC_body_mux` is stated over. H3's whole
work in L1 is to make this rewrite legal. -/
theorem elemTrace_replicate_false : ∀ (n : Nat) (p0 p1 : List Bool),
    p0.length = n → p1.length = n →
    elemTrace (List.replicate n false) p0 p1 = ceBody p0 p1 := by
  intro n
  induction n with
  | zero =>
    intro p0 p1 h0 h1
    cases p0 with
    | nil => cases p1 with
      | nil => rfl
      | cons _ _ => simp at h1
    | cons _ _ => simp at h0
  | succ m ih =>
    intro p0 p1 h0 h1
    cases p0 with
    | nil => simp at h0
    | cons x xs => cases p1 with
      | nil => simp at h1
      | cons y ys =>
        have hx : xs.length = m := by simpa using h0
        have hy : ys.length = m := by simpa using h1
        rw [List.replicate_succ, elemTrace_cons, ceBody_cons, ih xs ys hx hy]

/-- ⭐ **H3's CONTENT, AT EVERY SPLIT POINT.** From cycle 1 to the end of the
frame the reset column is LOW, so for any decide point `j ∈ [1, 14]` H3 hands the
general theorem below exactly the shape it consumes: an arbitrary prefix followed
by lows. *This is the whole of H3's work in L1.* -/
theorem h3Rst_suffix_is_low (j : Nat) (hj : 1 ≤ j) (hj' : j ≤ 14) :
    h3Rst = h3Rst.take j ++ List.replicate (14 - j) false := by
  interval_cases j <;> decide +kernel

/-- Any reset column that pulses on cycle 0 erases the element state, so every
statement below holds from ANY initial element state (`ceC_step_reset`). -/
theorem elemTrace_any_state (a b c d : Bool) : ∀ (r x y : List Bool),
    r.getD 0 false = true → x ≠ [] → y ≠ [] →
    runTrace ceC [a, b, c, d] (elemTrace r x y)
      = runTrace ceC [false, false, false, false] (elemTrace r x y) := by
  intro r x y hr hx hy
  cases r with
  | nil => simp at hr
  | cons r0 rs =>
    cases x with
    | nil => exact absurd rfl hx
    | cons x0 xs => cases y with
      | nil => exact absurd rfl hy
      | cons y0 ys =>
        have hr0 : r0 = true := by simpa using hr
        subst hr0
        rw [elemTrace_cons]
        simp only [runTrace, ceC_step_reset]

/-- The free-reset-column driver AGREES with the landed one over the header, so
the landed header theorem can be instantiated here. -/
theorem elemTrace_h3Hdr_eq_ceFrameTrace (x y : List Bool)
    (hx : x.length = 6) (hy : y.length = 6) :
    elemTrace h3Hdr x y = ceFrameTrace x y := by
  cases x with
  | nil => simp at hx
  | cons x0 xs => cases y with
    | nil => simp at hy
    | cons y0 ys =>
      have hxs : xs.length = 5 := by simpa using hx
      have hys : ys.length = 5 := by simpa using hy
      show elemTrace (true :: [false, false, false, false, false]) (x0 :: xs) (y0 :: ys) = _
      rw [elemTrace_cons]
      show [true, x0, y0] :: elemTrace (List.replicate 5 false) xs ys = _
      rw [elemTrace_replicate_false 5 xs ys hxs hys]
      rfl

/-! ## 2. ⭐⭐ L1 — CASE (c), THE MAIN STATEMENT

**Under H3, once the element has decided, its two output lines are a static
permutation of its two input lines for every remaining cycle of the frame.**

Read the shape: the conclusion is a WHOLE-LIST equality whose right side is
`(the 6 header output cycles) ++ (the 8 payload output cycles)`, so the window
`[6, 14)` appears with BOTH bounds — the lower as the header prefix, the upper as
`ceIL`'s length-8 payload (`l1_payload_window` states both explicitly). The header
window `[0, 6)` is left as the element's own output there and is NOT claimed: §2's
don't-care rider. **STATIC** = the select `s` in the conclusion carries no cycle
index. **PORT-WHOLE** = `ceIL` emits a 2-list every cycle and `ceC.nOut = 2`
(`l1_output_is_two_ports_every_cycle`). -/

/-- ⭐ **L1 WITH THE DECIDE POINT FREE — "for the REST of the frame" in general.**
After ANY prefix of `n` cycles at whose end the element is decided with swap `s`,
and for a reset column that is LOW over the remaining `m` cycles (which is what H3
supplies at every split point — `h3Rst_suffix_is_low`), the remaining `m` output
cycles are the static `s`-permutation of the two input columns. *No reference to
6, 8 or 14: the decide point is a parameter, and the only reset hypothesis is
`List.replicate m false` — H3 in the exact form the conclusion needs.* -/
theorem l1_decided_after_any_prefix
    (st : List Bool) (n m : Nat) (r0 h0 h1 p0 p1 : List Bool)
    (hr0 : r0.length = n) (hh0 : h0.length = n) (hh1 : h1.length = n)
    (hp0 : p0.length = m) (hp1 : p1.length = m)
    (s ph ba : Bool)
    (hdec : (runTrace ceC st (elemTrace r0 h0 h1)).2 = [true, s, ph, ba]) :
    (runTrace ceC st
        (elemTrace (r0 ++ List.replicate m false) (h0 ++ p0) (h1 ++ p1))).1
      = (runTrace ceC st (elemTrace r0 h0 h1)).1
        ++ ceIL (if s then p1 else p0) (if s then p0 else p1) := by
  rw [elemTrace_split n r0 (List.replicate m false) h0 h1 p0 p1 hr0 hh0 hh1]
  simp only [runTrace_append, hdec]
  rw [elemTrace_replicate_false m p0 p1 hp0 hp1, ceC_body_mux]

/-- ⭐⭐ **L1 AT THE TAPEOUT INSTANCE, P = 8** — the general theorem at
`n = 6, m = 8`, with H3 as the hypothesis `r = h3Rst`. -/
theorem l1_decided_is_a_static_permutation
    (st : List Bool) (r h0 h1 p0 p1 : List Bool)
    (hrst : r = h3Rst)
    (hh0 : h0.length = 6) (hh1 : h1.length = 6)
    (hp0 : p0.length = 8) (hp1 : p1.length = 8)
    (s ph ba : Bool)
    (hdec : (runTrace ceC st (elemTrace h3Hdr h0 h1)).2 = [true, s, ph, ba]) :
    (runTrace ceC st (elemTrace r (h0 ++ p0) (h1 ++ p1))).1
      = (runTrace ceC st (elemTrace h3Hdr h0 h1)).1
        ++ ceIL (if s then p1 else p0) (if s then p0 else p1) := by
  subst hrst
  show (runTrace ceC st
      (elemTrace (h3Hdr ++ List.replicate 8 false) (h0 ++ p0) (h1 ++ p1))).1 = _
  exact l1_decided_after_any_prefix st 6 8 h3Hdr h0 h1 p0 p1 rfl hh0 hh1 hp0 hp1 s ph ba hdec

/-- Every output cycle carries both ports: `ceIL` is a list of 2-lists, and the
element declares 2 outputs. *The port axis is whole, not sampled.* -/
theorem l1_output_is_two_ports_every_cycle : ∀ (a b : List Bool), ∀ c ∈ ceIL a b,
    c.length = 2 ∧ ceC.nOut = 2 := by
  intro a
  induction a with
  | nil => intro b c hc; simp [ceIL] at hc
  | cons x xs ih =>
    intro b c hc
    cases b with
    | nil => simp [ceIL] at hc
    | cons y ys =>
      simp only [ceIL, List.zipWith_cons_cons, List.mem_cons] at hc
      rcases hc with h | h
      · subst h; exact ⟨rfl, rfl⟩
      · exact ih ys c (by simpa [ceIL] using h)

/-- ⭐ **THE WINDOW, WITH BOTH BOUNDS IN THE STATEMENT.** 14 output cycles;
cycles `[6, 14)` are the static permutation of the two payload columns. -/
theorem l1_payload_window (st : List Bool) (h0 h1 p0 p1 : List Bool)
    (hh0 : h0.length = 6) (hh1 : h1.length = 6)
    (hp0 : p0.length = 8) (hp1 : p1.length = 8)
    (s ph ba : Bool)
    (hdec : (runTrace ceC st (elemTrace h3Hdr h0 h1)).2 = [true, s, ph, ba]) :
    (runTrace ceC st (elemTrace h3Rst (h0 ++ p0) (h1 ++ p1))).1.length = 14
      ∧ (runTrace ceC st (elemTrace h3Rst (h0 ++ p0) (h1 ++ p1))).1.drop 6
          = ceIL (if s then p1 else p0) (if s then p0 else p1) := by
  have hmain := l1_decided_is_a_static_permutation st h3Rst h0 h1 p0 p1 rfl
    hh0 hh1 hp0 hp1 s ph ba hdec
  have hhdr : (runTrace ceC st (elemTrace h3Hdr h0 h1)).1.length = 6 := by
    rw [runTrace_length, elemTrace_length]
    simp [h3Hdr, hh0, hh1]
  refine ⟨?_, ?_⟩
  · rw [runTrace_length, elemTrace_length]
    simp [h3Rst, h3Hdr, hh0, hh1, hp0, hp1]
  · rw [hmain, List.drop_left' hhdr]

/-! ### The permutation OBJECT, so "2-permutation" is not a figure of speech -/

/-- The 2-permutation the latched `swap` bit names: the identity when `s = false`,
the transposition when `s = true`. An `Equiv.Perm (Fin 2)` — a permutation object,
carrying its own inverse. -/
def swapPerm (s : Bool) : Equiv.Perm (Fin 2) :=
  if s then Equiv.swap 0 1 else Equiv.refl (Fin 2)

theorem swapPerm_bijective (s : Bool) : Function.Bijective (swapPerm s) :=
  (swapPerm s).bijective

/-- …and it is a NON-TRIVIAL permutation in the swapped case, so the object is
not secretly `id`. -/
theorem swapPerm_true_is_the_transposition :
    swapPerm true (0 : Fin 2) = 1 ∧ swapPerm true (1 : Fin 2) = 0
      ∧ swapPerm false (0 : Fin 2) = 0 ∧ swapPerm false (1 : Fin 2) = 1 := by
  refine ⟨?_, ?_, ?_, ?_⟩ <;> simp [swapPerm]

/-- The two input lines, indexed by port. -/
def lineOf (p0 p1 : List Bool) : Fin 2 → List Bool := fun j => if j = 0 then p0 else p1

theorem ceIL_getD : ∀ (a b : List Bool), a.length = b.length → ∀ u, u < a.length →
    (ceIL a b).getD u [] = [a.getD u false, b.getD u false] := by
  intro a
  induction a with
  | nil => intro b _ u hu; simp at hu
  | cons x xs ih =>
    intro b hb u hu
    cases b with
    | nil => simp at hb
    | cons y ys =>
      cases u with
      | zero => simp [ceIL]
      | succ v => simpa [ceIL] using ih ys (by simpa using hb) v (by simpa using hu)

/-- ⭐ **THE PAYLOAD WINDOW READ THROUGH THE PERMUTATION OBJECT**: at every cycle
of `[6, 14)`, output port `j` carries input line `swapPerm s j`. *One `σ` for the
whole window — that is what "static" means, and `swapPerm_bijective` is what
"2-permutation" means.* -/
theorem l1_payload_window_is_the_permutation (s : Bool) (p0 p1 : List Bool)
    (hp0 : p0.length = 8) (hp1 : p1.length = 8) (u : Nat) (hu : u < 8) (j : Fin 2) :
    ((ceIL (if s then p1 else p0) (if s then p0 else p1)).getD u []).getD j.val false
      = (lineOf p0 p1 (swapPerm s j)).getD u false := by
  have hlen : (if s then p1 else p0).length = (if s then p0 else p1).length := by
    cases s <;> simp [hp0, hp1]
  have hu' : u < (if s then p1 else p0).length := by cases s <;> simp [hp0, hp1, hu]
  rw [ceIL_getD _ _ hlen u hu']
  cases s <;> fin_cases j <;> simp [swapPerm, lineOf]

/-! ## 3. NON-VACUITY — `hdec` is DISCHARGED, not assumed -/

/-- `hdec` from the LANDED header theorem: two active lines with distinct
destinations are decided after six cycles, with `swap = !cKeyLE`. -/
theorem l1_hdec_from_landed_header (d0 d1 : Nat) (hd0 : d0 < 8) (hd1 : d1 < 8)
    (hne : d0 ≠ d1) :
    (runTrace ceC [false, false, false, false]
        (elemTrace h3Hdr (ceHdr true d0) (ceHdr true d1))).2
      = [true, !(cKeyLE (cKey true d0) (cKey true d1)), false, true] := by
  rw [elemTrace_h3Hdr_eq_ceFrameTrace _ _ (ceHdr_length true d0) (ceHdr_length true d1),
      ceC_header_routes d0 d1 hd0 hd1 hne]

/-- ⭐⭐ **L1 AT FULL LOAD, EVERYTHING DISCHARGED.** The only hypotheses left are
H3 (in `h3Rst`), the destination distinctness B4 carries as its own binder
(`hne` — via `StageOK`'s distinctness clause at stage 0, transported inward by
`stageOK_succ`; NOT a consequence of H1), and the P = 8 payload lengths. The
payload window is the two payload columns, ordered by destination. -/
theorem l1_full_load_payload_delivery (d0 d1 : Nat) (hd0 : d0 < 8) (hd1 : d1 < 8)
    (hne : d0 ≠ d1) (p0 p1 : List Bool) (hp0 : p0.length = 8) (hp1 : p1.length = 8) :
    (runTrace ceC [false, false, false, false]
        (elemTrace h3Rst (cFrame true d0 p0) (cFrame true d1 p1))).1.drop 6
      = ceIL (if d0 ≤ d1 then p0 else p1) (if d0 ≤ d1 then p1 else p0) := by
  have hdec := l1_hdec_from_landed_header d0 d1 hd0 hd1 hne
  have h := (l1_payload_window [false, false, false, false] (ceHdr true d0) (ceHdr true d1)
      p0 p1 (ceHdr_length true d0) (ceHdr_length true d1) hp0 hp1
      (!(cKeyLE (cKey true d0) (cKey true d1))) false true hdec).2
  rw [cFrame_split true d0 p0, cFrame_split true d1 p1, h, cKeyLE_full_load]
  by_cases hle : d0 ≤ d1 <;> simp [hle]

/-! ## 4. THE THREE CASES, AND THAT THERE IS NO FOURTH -/

/-- Is the element decided at the end of the six header cycles? -/
def l1DecidedAfterHeader (a0 : Bool) (d0 : Nat) (a1 : Bool) (d1 : Nat) : Bool :=
  (runTrace ceC [false, false, false, false]
    (elemTrace h3Hdr (ceHdr a0 d0) (ceHdr a1 d1))).2.getD 0 false

/-- Every header pair the 3-bit fabric can carry: 2 activities × 8 destinations,
twice. -/
def l1TrichotomyOK : Bool :=
  bools.all fun a0 => (List.range 8).all fun d0 =>
  bools.all fun a1 => (List.range 8).all fun d1 =>
    l1DecidedAfterHeader a0 d0 a1 d1 == !((!a0 && !a1) || (a0 && a1 && d0 == d1))

/-- ⭐ **THE CASE LIST IS COMPLETE — 256 header pairs.** The element is decided
after the header **iff** the pair is neither two idles nor an active tie. *So the
cases are exactly three: (a) two idles, (b) the tie, (c) decided. There is no
fourth.* -/
theorem l1_the_three_cases_are_exhaustive : l1TrichotomyOK = true := by decide +kernel

def l1HdrIdenticalOK : Bool :=
  bools.all fun a0 => (List.range 8).all fun d0 =>
  bools.all fun a1 => (List.range 8).all fun d1 =>
    l1DecidedAfterHeader a0 d0 a1 d1 == !(ceHdr a0 d0 == ceHdr a1 d1)

/-- ⭐ **AND THE MECHANISM IS ONE THING, NOT TWO**: undecided-after-header ⟺ the
two headers are BIT-IDENTICAL. *(a) and (b) are the same failure of the header to
carry a difference — which is why both of them latch on payload bit 0.* -/
theorem l1_undecided_iff_headers_identical : l1HdrIdenticalOK = true := by decide +kernel

/-! ### CASE (a) — two idle lines -/

/-- An on-protocol idle line is silent for the WHOLE frame, payload included
(§3: unclaimed outputs drive 0 all frame). `cFrame_idle_is_silent` at P = 8. -/
theorem l1_idle_frame_is_silent :
    cFrame false 0 (List.replicate 8 false) = List.replicate 14 false
      ∧ cFrame false 5 (List.replicate 8 false) = List.replicate 14 false := by
  decide +kernel

/-- ⭐ **CASE (a): TWO IDLE LINES ARE STRAIGHT THROUGH** — nothing is
manufactured, from ANY initial element state. *This is
`ceC_frame_two_idle_stable`'s content at P = 8; the landed form is at P = 2 and is
restated below.* -/
theorem l1_case_a_two_idles_are_straight_through (a b c d : Bool) :
    (runTrace ceC [a, b, c, d]
        (elemTrace h3Rst (cFrame false 0 (List.replicate 8 false))
                         (cFrame false 0 (List.replicate 8 false)))).1
      = List.replicate 14 [false, false] := by
  rw [elemTrace_any_state a b c d h3Rst
      (cFrame false 0 (List.replicate 8 false)) (cFrame false 0 (List.replicate 8 false))
      rfl (cFrame_ne_nil false 0 (List.replicate 8 false))
      (cFrame_ne_nil false 0 (List.replicate 8 false))]
  decide +kernel

/-- The landed form, at its own P = 2, cited so the two are visibly one content. -/
theorem l1_case_a_landed_form :
    ceCRun (cFrame false 0 [false, false]) (cFrame false 0 [false, false])
      = List.replicate 8 [false, false] :=
  ceC_frame_two_idle_stable

/-- ⚠️ **AND THE MUTATION CONTROL IS NOT THIS STATEMENT.**
`ceC_rejects_idle_sorts_low` is about `ceCIdleLow` — a one-gate mutant, i.e. a
DIFFERENT DEVICE. *Right conclusion, wrong reason, is how this gets cited.* -/
theorem l1_case_a_control_is_a_different_device : ceCIdleLow.core ≠ ceC.core := by
  decide +kernel

/-- Line 0's payload for the splice fixtures. Bit 0 is `false`. -/
def tieP0 : List Bool := [false, true, true, false, true, false, false, true]
/-- Line 1's payload. Bit 0 is `true`, so the two differ at payload bit 0. -/
def tieP1 : List Bool := [true, false, false, true, false, true, true, false]

/-- ⛔⛔ **CASE (a) HOLDS BECAUSE THE PAYLOAD IS SILENT, NOT BECAUSE IDLENESS
STOPS THE DECIDE — measured.** Two lines with IDLE headers and DIFFERING payloads
are NOT straight-through: the headers are bit-identical, nothing decides in
`[0, 6)`, and at cycle 6 the even-phase activity rule fires on payload bit 0
(`bothAct` gates only the ODD-phase decision, `ceCcore` gate ⟨21⟩), so the element
**swaps the two payloads**. *Such a frame is off-protocol — an idle line must be
silent all frame — so this is a scope statement, not a hardware defect; but "two
idles = straight-through" is the wrong REASON, and a successor who carries the
reason instead of the scope will lose the theorem at partial load.* -/
theorem l1_case_a_needs_silent_payloads (a b c d : Bool) :
    (runTrace ceC [a, b, c, d]
        (elemTrace h3Rst (cFrame false 0 tieP0) (cFrame false 0 tieP1))).1
      = ceIL (cFrame false 0 tieP1) (cFrame false 0 tieP0)
    ∧ (runTrace ceC [a, b, c, d]
        (elemTrace h3Rst (cFrame false 0 tieP0) (cFrame false 0 tieP1))).1
      ≠ ceIL (cFrame false 0 tieP0) (cFrame false 0 tieP1) := by
  rw [elemTrace_any_state a b c d h3Rst (cFrame false 0 tieP0) (cFrame false 0 tieP1)
      rfl (cFrame_ne_nil false 0 tieP0) (cFrame_ne_nil false 0 tieP1)]
  exact ⟨by decide +kernel, by decide +kernel⟩

/-! ### CASE (b) — two ACTIVE lines with EQUAL destinations: the tie SPLICES -/

/-- ⭐ **CASE (b): THE TIE SPLICES THE PAYLOAD, EXACTLY.** Two active lines bound
for destination 3: the headers are bit-identical, so the element latches on
payload bit 0 and **exchanges the two payloads** under identical headers. The
result is a well-formed `cFrame` for the right destination carrying the WRONG
payload — invisible to any header-level invariant (`cDestOf_is_payload_blind`).
Second conjunct: `cKeyLE (cKey true 3) (cKey true 3) = true`, so L1's conclusion
would demand `out = ceIL f0 f1`; it is not. *This is why
`l1_full_load_payload_delivery` carries `hne`.* -/
theorem l1_case_b_tie_splices_the_payload (a b c d : Bool) :
    (runTrace ceC [a, b, c, d]
        (elemTrace h3Rst (cFrame true 3 tieP0) (cFrame true 3 tieP1))).1
      = ceIL (cFrame true 3 tieP1) (cFrame true 3 tieP0)
    ∧ (runTrace ceC [a, b, c, d]
        (elemTrace h3Rst (cFrame true 3 tieP0) (cFrame true 3 tieP1))).1
      ≠ ceIL (cFrame true 3 tieP0) (cFrame true 3 tieP1)
    ∧ cKeyLE (cKey true 3) (cKey true 3) = true := by
  rw [elemTrace_any_state a b c d h3Rst (cFrame true 3 tieP0) (cFrame true 3 tieP1)
      rfl (cFrame_ne_nil true 3 tieP0) (cFrame_ne_nil true 3 tieP1)]
  exact ⟨by decide +kernel, by decide +kernel, by decide +kernel⟩

/-- The landed form of case (b), at its own P = 3. -/
theorem l1_case_b_landed_form :
    (runTrace ceC [false, false, false, false]
        (ceFrameTrace (cFrame true 3 [false, true, true])
                      (cFrame true 3 [true, false, false]))).1
      ≠ ceIL (cFrame true 3 [false, true, true]) (cFrame true 3 [true, false, false]) :=
  ceC_pair_tie_splices_the_payload

/-! ## 5. ⛔ THE NEGATIVE CONTROL — L1 MUST BE ABLE TO FAIL, AND IT DOES

The device: hold everything fixed and drop H3 alone. One extra `rst` pulse at
cycle 8 (mid-payload) clears `decided` (`ceCcore` gate ⟨8, .and 3 7⟩ = `decided ∧
¬rst`), `rst` forces the even phase (gate ⟨10, .and 5 7⟩), and the element
re-decides **on payload bits** — a well-formed frame for the right destination
with the wrong payload tail. -/

/-- Line 0's payload; payload bit 2 (cycle 8) is `false`. -/
def payA : List Bool := [true, true, false, true, false, false, false, false]
/-- Line 1's payload; payload bit 2 (cycle 8) is `true`. -/
def payB : List Bool := [false, false, true, false, true, true, true, true]

/-- The H3-violating reset column: pulses at cycle 0 **and cycle 8**. -/
def midRst : List Bool := (List.range 14).map (fun t => t == 0 || t == 8)

/-- ⭐ **THE MUTANT ISOLATES H3 AND NOTHING ELSE**: 14 cycles like `h3Rst`,
IDENTICAL over the six header cycles (so `hdec` is the very same proposition,
`l1_hdec_from_landed_header` still discharges it), and one single bit apart. *A
differential is only evidence if the mutant is one edit from the control.* -/
theorem midRst_isolates_h3 :
    midRst.length = 14
      ∧ midRst.take 6 = h3Hdr
      ∧ (midRst.zip h3Rst).countP (fun q => q.1 != q.2) = 1
      ∧ midRst ≠ h3Rst := by
  decide +kernel

/-- …stated on the runs: the mid-frame pulse cannot change the post-header state,
so the mutant keeps L1's `hdec` and loses only H3. -/
theorem midRst_leaves_hdec_intact (st x y : List Bool) :
    runTrace ceC st (elemTrace (midRst.take 6) x y)
      = runTrace ceC st (elemTrace h3Hdr x y) := by
  rw [show midRst.take 6 = h3Hdr from by decide +kernel]

/-- ✅ **CONTROL — UNDER H3 THE CONCLUSION HOLDS**, and it is proved *by the
general theorem*, not by a fixture: `l1_full_load_payload_delivery` at
`d0 = 2 < 5 = d1`. -/
theorem l1_control_holds_under_h3 :
    (runTrace ceC [false, false, false, false]
        (elemTrace h3Rst (cFrame true 2 payA) (cFrame true 5 payB))).1.drop 6
      = ceIL payA payB := by
  have h := l1_full_load_payload_delivery 2 5 (by decide) (by decide) (by decide)
    payA payB rfl rfl
  simpa using h

/-- ⛔⛔ **L1 IS FALSE WITHOUT H3 — KERNEL-REFUTED.** Same element, same two
frames, same `hdec`; only the reset column changes, and the payload window is no
longer the static permutation. *This is the failure class the block exists to
certify against.* -/
theorem l1_negative_control_fails_without_h3 :
    (runTrace ceC [false, false, false, false]
        (elemTrace midRst (cFrame true 2 payA) (cFrame true 5 payB))).1.drop 6
      ≠ ceIL payA payB := by
  decide +kernel

/-- …and the damage is exactly a mid-frame permutation FLIP, not noise: cycles
`0…7` are still correct, cycles `8…13` are the OTHER line's bits. *So the frame
that emerges is a well-formed `cFrame` for the right destination carrying the
wrong payload tail.* -/
theorem l1_negative_control_is_a_mid_frame_flip :
    (runTrace ceC [false, false, false, false]
        (elemTrace midRst (cFrame true 2 payA) (cFrame true 5 payB))).1.take 8
        = (ceIL (cFrame true 2 payA) (cFrame true 5 payB)).take 8
      ∧ (runTrace ceC [false, false, false, false]
        (elemTrace midRst (cFrame true 2 payA) (cFrame true 5 payB))).1.drop 8
        = (ceIL (cFrame true 5 payB) (cFrame true 2 payA)).drop 8 := by
  decide +kernel

#audit_axioms elemTrace
#audit_axioms h3Hdr
#audit_axioms h3Rst
#audit_axioms h3Rst_is_b4_hrst
#audit_axioms h3Rst_is_one_pulse_at_cycle_zero
#audit_axioms elemTrace_cons
#audit_axioms ceBody_cons
#audit_axioms elemTrace_length
#audit_axioms runTrace_length
#audit_axioms map_getD0_zipWith_cons
#audit_axioms map_getD_succ_zipWith_cons
#audit_axioms elemTrace_rst_column
#audit_axioms elemTrace_line0_column
#audit_axioms elemTrace_line1_column
#audit_axioms elemTrace_split
#audit_axioms elemTrace_replicate_false
#audit_axioms h3Rst_suffix_is_low
#audit_axioms l1_decided_after_any_prefix
#audit_axioms elemTrace_any_state
#audit_axioms elemTrace_h3Hdr_eq_ceFrameTrace
#audit_axioms l1_decided_is_a_static_permutation
#audit_axioms l1_output_is_two_ports_every_cycle
#audit_axioms l1_payload_window
#audit_axioms swapPerm
#audit_axioms swapPerm_bijective
#audit_axioms swapPerm_true_is_the_transposition
#audit_axioms lineOf
#audit_axioms ceIL_getD
#audit_axioms l1_payload_window_is_the_permutation
#audit_axioms l1_hdec_from_landed_header
#audit_axioms l1_full_load_payload_delivery
#audit_axioms l1DecidedAfterHeader
#audit_axioms l1TrichotomyOK
#audit_axioms l1_the_three_cases_are_exhaustive
#audit_axioms l1HdrIdenticalOK
#audit_axioms l1_undecided_iff_headers_identical
#audit_axioms l1_idle_frame_is_silent
#audit_axioms l1_case_a_two_idles_are_straight_through
#audit_axioms l1_case_a_landed_form
#audit_axioms l1_case_a_control_is_a_different_device
#audit_axioms tieP0
#audit_axioms tieP1
#audit_axioms l1_case_a_needs_silent_payloads
#audit_axioms l1_case_b_tie_splices_the_payload
#audit_axioms l1_case_b_landed_form
#audit_axioms payA
#audit_axioms payB
#audit_axioms midRst
#audit_axioms midRst_isolates_h3
#audit_axioms midRst_leaves_hdec_intact
#audit_axioms l1_control_holds_under_h3
#audit_axioms l1_negative_control_fails_without_h3
#audit_axioms l1_negative_control_is_a_mid_frame_flip

end L1Payload
