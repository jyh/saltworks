/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.SeamElement
import SaltWorks.HDL.BatcherNetCheck
import SaltWorks.Silicon.Equiv.ComposedSwitch

/-!
# J2 — THE TRANSPORT END: `runNetN` at `ℕ`-indices ⇒ `composed_switch_of_seam_k3`

Everything AFTER `bnC_output_keys_are_runNetN`. `ElemSortsAt` stays a hypothesis.
-/

namespace SaltWorks.HDL

open SaltWorks.Stack

set_option maxRecDepth 8000

/-! ## 1. The destination decoder — the `key : List Bool → ℕ` the seam is run at -/

/-- The destination a convention-C frame names: bits 1, 3, 5 of the header are
the address MSB-first (`cFrame`'s odd cycles). -/
def cDestOf (f : List Bool) : Nat :=
  (if f.getD 1 false then 4 else 0) + (if f.getD 3 false then 2 else 0)
    + (if f.getD 5 false then 1 else 0)

/-- ⭐ The address bound is FREE: a three-bit decode cannot exceed 7, so
`composed_switch_of_seam_k3`'s `hlt` never reaches the caller. -/
theorem cDestOf_lt_eight (f : List Bool) : cDestOf f < 8 := by
  unfold cDestOf
  split <;> split <;> split <;> decide

/-- `cFrame` at full activity, unfolded to its six header cycles. -/
theorem cFrame_true_expand (d : Nat) (p : List Bool) :
    cFrame true d p
      = true :: d.testBit 2 :: true :: d.testBit 1 :: true :: d.testBit 0 :: p := rfl

/-- The decoder reads the header bits back. -/
theorem cDestOf_cFrame_bits (d : Nat) (p : List Bool) :
    cDestOf (cFrame true d p)
      = (if d.testBit 2 then 4 else 0) + (if d.testBit 1 then 2 else 0)
        + (if d.testBit 0 then 1 else 0) := rfl

/-- ⭐ **THE DECODER INVERTS THE FRAME** below the fabricated width. -/
theorem cDestOf_cFrame (d : Nat) (hd : d < 8) (p : List Bool) :
    cDestOf (cFrame true d p) = d := by
  rw [cDestOf_cFrame_bits]
  interval_cases d <;> decide

/-- ⭐ **THE ORDER THE TRANSPORT RUNS AT IS THE ELEMENT'S OWN ORDER** on
full-load frames — this is what J1's `ElemSortsAt` obligation gets to consume. -/
theorem cDestOf_le_eq_cKeyLE (d0 d1 : Nat) (hd0 : d0 < 8) (hd1 : d1 < 8)
    (p0 p1 : List Bool) :
    decide (cDestOf (cFrame true d0 p0) ≤ cDestOf (cFrame true d1 p1))
      = cKeyLE (cKey true d0) (cKey true d1) := by
  rw [cDestOf_cFrame d0 hd0, cDestOf_cFrame d1 hd1, cKeyLE_full_load]

/-- ⛔ **CONTROL — the decoder is pinned to the bytes silicon's B4 adjudicated.**
`cFrame_matches_adjudicated_bytes` fixes `mkFrame true 5 p = 1 1 1 0 1 1 | p`;
this reads `5` back out of exactly that string, so the decoder cannot have been
fitted to `cFrame`'s definition rather than to the ruling. -/
theorem cDestOf_adjudicated_bytes : cDestOf [true, true, true, false, true, true] = 5 := by
  decide

/-- ⛔ **CONTROL — EVERY IDLE FRAME DECODES TO 0.** So partial load makes the
input key vector non-injective, and `Silicon.repeated_input_code_refutes_no_conflict`
then *refutes* the conclusion. The `Function.Injective` hypothesis below is
load-bearing, not decoration. -/
theorem cDestOf_idle_is_zero (d : Nat) (p : List Bool) : cDestOf (cFrame false d p) = 0 := rfl

/-! ## 2. `ℕ`-indexed run ⇒ `Fin 8`-indexed run -/

/-- One comparator, transported across the index change. -/
theorem applyCompN_val (c : Comparator 8) (v : Fin 8 → ℕ) (vN : Nat → Nat)
    (hag : ∀ i : Fin 8, vN i.val = v i) (i : Fin 8) :
    applyCompN (c.1.val, c.2.val) vN i.val = applyComp c v i := by
  simp only [applyCompN, applyComp, hag, Fin.val_inj]

/-- ⭐ **THE WHOLE NETWORK, TRANSPORTED.** `runNetN` over the `Nat`-erased
comparator list agrees, index by index, with `runNet` over the `Fin 8` one. -/
theorem runNetN_map_val : ∀ (net : Network 8) (v : Fin 8 → ℕ) (vN : Nat → Nat),
    (∀ i : Fin 8, vN i.val = v i) →
    ∀ i : Fin 8,
      runNetN (net.map (fun c => (c.1.val, c.2.val))) vN i.val = runNet net v i := by
  intro net
  induction net with
  | nil => intro v vN hag i; exact hag i
  | cons c cs ih =>
    intro v vN hag i
    have h1 : runNetN ((c :: cs).map (fun c : Comparator 8 => (c.1.val, c.2.val))) vN
        = runNetN (cs.map (fun c : Comparator 8 => (c.1.val, c.2.val)))
            (applyCompN (c.1.val, c.2.val) vN) := rfl
    have h2 : runNet (c :: cs) v = runNet cs (applyComp c v) := rfl
    rw [h1, h2]
    exact ih (applyComp c v) (applyCompN (c.1.val, c.2.val) vN)
      (fun j => applyCompN_val c v vN hag j) i

/-! ## 3. The seam in `composed_switch_of_seam_k3`'s vocabulary -/

/-- The destinations the network EMITS, as a `Fin 8`-indexed vector of `ℕ`. -/
def bnCOutKey (st : List Bool) (tr : List (List Bool)) : Fin 8 → ℕ :=
  fun w => cDestOf ((runTrace batcherNetC st tr).1.map (fun o => o.getD w.val false))

/-- The destinations the network is FED, as a `Fin 8`-indexed vector of `ℕ`. -/
def bnCInKey (st : List Bool) (tr : List (List Bool)) : Fin 8 → ℕ :=
  fun i => cDestOf (bnCFrameAt st tr 0 i.val)

/-- ⭐⭐⭐ **`hseam`, DISCHARGED.** -/
theorem bnC_seam_runNet (st : List Bool) (tr : List (List Bool))
    (h : ∀ k, k < 24 → ElemSortsAt st tr k (fun x y => decide (cDestOf x ≤ cDestOf y))) :
    bnCOutKey st tr = runNet batcher8 (bnCInKey st tr) := by
  funext w
  have hk := bnC_output_keys_are_runNetN st tr cDestOf h w.val w.isLt
  show cDestOf ((runTrace batcherNetC st tr).1.map (fun o => o.getD w.val false)) = _
  rw [hk, bnComps_eq_batcher8]
  exact runNetN_map_val batcher8 (bnCInKey st tr)
    (fun i => cDestOf (bnCFrameAt st tr 0 i)) (fun i => rfl) w

/-! ## 4. The composed conclusion -/

/-- ⭐⭐⭐ **THE COMPOSED SWITCH, ON THE FABRICATED SORTER.** `ElemSortsAt` is
still a hypothesis — J1 supplies it; the address bound is discharged by the
decoder's own arithmetic. -/
theorem composed_switch_of_bnC_seam (st : List Bool) (tr : List (List Bool))
    (hinj : Function.Injective (bnCInKey st tr))
    (h : ∀ k, k < 24 → ElemSortsAt st tr k (fun x y => decide (cDestOf x ≤ cDestOf y))) :
    (∀ m ≤ 3, Set.InjOn
        (fun s => Banyan.line m s (extendIio 0 (bnCOutKey st tr) s)) (Set.Iio 8)) ∧
      (∀ s < 8, Banyan.line 3 s (extendIio 0 (bnCOutKey st tr) s) = s) ∧
      (∀ s, Banyan.line 0 s (extendIio 0 (bnCOutKey st tr) s)
              = extendIio 0 (bnCOutKey st tr) s) :=
  SaltWorks.Silicon.composed_switch_of_seam_k3 hinj
    (fun _ => cDestOf_lt_eight _) (bnC_seam_runNet st tr h)

/-- The input key vector, read off well-formed input frames. -/
theorem bnCInKey_of_frames (st : List Bool) (tr : List (List Bool))
    (d : Fin 8 → Nat) (hd : ∀ i, d i < 8) (p : Fin 8 → List Bool)
    (hin : ∀ i : Fin 8, bnCFrameAt st tr 0 i.val = cFrame true (d i) (p i)) :
    bnCInKey st tr = d := by
  funext i
  show cDestOf (bnCFrameAt st tr 0 i.val) = d i
  rw [hin i, cDestOf_cFrame (d i) (hd i)]

/-- ⭐⭐ **THE CALLER'S DOOR.** Destinations given as the frames the input
columns actually carry: the caller owes injectivity of the destination vector
and `ElemSortsAt`, and nothing else. -/
theorem composed_switch_of_bnC_frames (st : List Bool) (tr : List (List Bool))
    (d : Fin 8 → Nat) (hd : ∀ i, d i < 8) (hdi : Function.Injective d)
    (p : Fin 8 → List Bool)
    (hin : ∀ i : Fin 8, bnCFrameAt st tr 0 i.val = cFrame true (d i) (p i))
    (h : ∀ k, k < 24 → ElemSortsAt st tr k (fun x y => decide (cDestOf x ≤ cDestOf y))) :
    (∀ m ≤ 3, Set.InjOn
        (fun s => Banyan.line m s (extendIio 0 (bnCOutKey st tr) s)) (Set.Iio 8)) ∧
      (∀ s < 8, Banyan.line 3 s (extendIio 0 (bnCOutKey st tr) s) = s) ∧
      (∀ s, Banyan.line 0 s (extendIio 0 (bnCOutKey st tr) s)
              = extendIio 0 (bnCOutKey st tr) s) :=
  composed_switch_of_bnC_seam st tr
    (by rw [bnCInKey_of_frames st tr d hd p hin]; exact hdi) h

/-- Stage-0 frames ARE the input trace's data columns (column 0 is `rst`). -/
theorem bnCFrameAt_zero_col (st : List Bool) (tr : List (List Bool)) (i : Fin 8) :
    bnCFrameAt st tr 0 i.val = tr.map (fun c => c.getD (1 + i.val) false) :=
  bnCFrameAt_zero st tr i.val i.isLt

/-- ⭐⭐⭐ **THE DOOR IN THE CALLER'S OWN VOCABULARY.** The hypothesis is about
the driven trace `tr` — column `1+i` of the stimulus is the frame for
destination `d i` — and nothing about internal wires. -/
theorem composed_switch_of_bnC_trace (st : List Bool) (tr : List (List Bool))
    (d : Fin 8 → Nat) (hd : ∀ i, d i < 8) (hdi : Function.Injective d)
    (p : Fin 8 → List Bool)
    (hin : ∀ i : Fin 8,
      tr.map (fun c => c.getD (1 + i.val) false) = cFrame true (d i) (p i))
    (h : ∀ k, k < 24 → ElemSortsAt st tr k (fun x y => decide (cDestOf x ≤ cDestOf y))) :
    (∀ m ≤ 3, Set.InjOn
        (fun s => Banyan.line m s (extendIio 0 (bnCOutKey st tr) s)) (Set.Iio 8)) ∧
      (∀ s < 8, Banyan.line 3 s (extendIio 0 (bnCOutKey st tr) s) = s) ∧
      (∀ s, Banyan.line 0 s (extendIio 0 (bnCOutKey st tr) s)
              = extendIio 0 (bnCOutKey st tr) s) :=
  composed_switch_of_bnC_frames st tr d hd hdi p
    (fun i => (bnCFrameAt_zero_col st tr i).trans (hin i)) h

#audit_axioms cDestOf cDestOf_lt_eight cFrame_true_expand cDestOf_cFrame_bits
#audit_axioms cDestOf_cFrame cDestOf_le_eq_cKeyLE
#audit_axioms cDestOf_adjudicated_bytes cDestOf_idle_is_zero
#audit_axioms applyCompN_val runNetN_map_val
#audit_axioms bnCOutKey bnCInKey bnC_seam_runNet
#audit_axioms composed_switch_of_bnC_seam bnCInKey_of_frames
#audit_axioms composed_switch_of_bnC_frames bnCFrameAt_zero_col
#audit_axioms composed_switch_of_bnC_trace

end SaltWorks.HDL
