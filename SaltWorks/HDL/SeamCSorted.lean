/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Stack.ZeroOne
import SaltWorks.Silicon.Equiv.PartialLoad
import SaltWorks.HDL.PartialLift

/-!
# THE ABSTRACT-FOLD ↔ `cSorted` SEAM — P1 day 0

Compiler's `bnC_output_keys_partial` puts the netlist's emitted key at
`runNetN bnComps` over the **`ℕ`** carrier (`natKey`). Math's `cSorted` is
`runNet batcher8` over **`Bool ×ₗ ℕ`** (`cKey`). This module joins them.

The index half was already landed (`runNetN_map_val`, `SeamJoinB`). The open
half was the **carrier**, and `runNet_comp_monotone` could not do it:

```
toLex (false, 100) < toLex (true, 0)      but      keyEnc gives 100 > 8
```

`keyEnc` is order-preserving only where the destination is `< 8` — exactly
`cKey_order_is_natKey_order`'s hypothesis. So the missing lemma was
`runNet_comp_monotoneOn`: a sorting network commutes with a map monotone **only
on a set**. The set-closure side is free (in a linear order `min x y` is `x` or
`y`); the content is carrying `∀ i, v i ∈ S` through the fold.

`not_monotone_keyEnc` is the positive control: it exhibits the witness that makes
the ungeneralised statement false, so the `MonotoneOn` strengthening is load-
bearing rather than stylistic.

⚠️ **IMPORT OWED — maestro's call, not mine:** this module is not in the hub
closure. Recommended follow-up, non-blocking: hoist the `SaltWorks.Stack`
section below to `Stack/ZeroOne.lean` beside its parent `runNet_comp_monotone`,
which it strictly generalises (`runNet_comp_monotone_of_monotoneOn` proves the
faithfulness). Deferred here only because `ZeroOne` is low in the import graph
and a rebuild would land on every seat mid-campaign.
-/

namespace SaltWorks.Stack

variable {n : ℕ}

section MonotoneOn

variable [LinearOrder α] [LinearOrder β] {f : α → β} {S : Set α}

/-- `min` lands on one of its arguments — the free half of set-closure. -/
theorem min_mem_of_mem {x y : α} (hx : x ∈ S) (hy : y ∈ S) : min x y ∈ S := by
  rcases le_total x y with h | h
  · rwa [min_eq_left h]
  · rwa [min_eq_right h]

theorem max_mem_of_mem {x y : α} (hx : x ∈ S) (hy : y ∈ S) : max x y ∈ S := by
  rcases le_total x y with h | h
  · rwa [max_eq_right h]
  · rwa [max_eq_left h]

/-- A `MonotoneOn` map preserves `min` **between points of the set**. -/
theorem map_min_of_monotoneOn (hf : MonotoneOn f S) {x y : α} (hx : x ∈ S) (hy : y ∈ S) :
    f (min x y) = min (f x) (f y) := by
  rcases le_total x y with h | h
  · rw [min_eq_left h, min_eq_left (hf hx hy h)]
  · rw [min_eq_right h, min_eq_right (hf hy hx h)]

theorem map_max_of_monotoneOn (hf : MonotoneOn f S) {x y : α} (hx : x ∈ S) (hy : y ∈ S) :
    f (max x y) = max (f x) (f y) := by
  rcases le_total x y with h | h
  · rw [max_eq_right h, max_eq_right (hf hx hy h)]
  · rw [max_eq_left h, max_eq_left (hf hy hx h)]

/-- ⭐ **ONE COMPARATOR, ON THE SET.** -/
theorem applyComp_comp_monotoneOn (hf : MonotoneOn f S) (c : Comparator n)
    (v : Fin n → α) (hv : ∀ i, v i ∈ S) :
    applyComp c (f ∘ v) = f ∘ applyComp c v := by
  funext i
  simp only [applyComp, Function.comp_apply]
  split
  · exact (map_min_of_monotoneOn hf (hv c.1) (hv c.2)).symm
  · split
    · exact (map_max_of_monotoneOn hf (hv c.1) (hv c.2)).symm
    · rfl

/-- The set is preserved by a comparator: `applyComp` only ever emits a `min`, a
`max`, or an untouched entry. **This is what makes the induction go.** -/
theorem applyComp_mem (c : Comparator n) (v : Fin n → α) (hv : ∀ i, v i ∈ S) :
    ∀ i, applyComp c v i ∈ S := by
  intro i
  simp only [applyComp]
  split
  · exact min_mem_of_mem (hv c.1) (hv c.2)
  · split
    · exact max_mem_of_mem (hv c.1) (hv c.2)
    · exact hv i

/-- The whole network preserves the set. -/
theorem runNet_mem : ∀ (net : Network n) (v : Fin n → α), (∀ i, v i ∈ S) → ∀ i, runNet net v i ∈ S := by
  intro net
  induction net with
  | nil => intro v hv i; exact hv i
  | cons c cs ih =>
      intro v hv i
      rw [runNet_cons]
      exact ih (applyComp c v) (applyComp_mem c v hv) i

/-- ⭐⭐ **THE COMMUTATION LEMMA, ON A SET.** `runNet` commutes with
post-composition by a map that is monotone only on a set containing the input's
values. Strictly generalises `runNet_comp_monotone` (take `S = Set.univ`). -/
theorem runNet_comp_monotoneOn (hf : MonotoneOn f S) :
    ∀ (net : Network n) (v : Fin n → α), (∀ i, v i ∈ S) →
      runNet net (f ∘ v) = f ∘ runNet net v := by
  intro net
  induction net with
  | nil => intro v _; rfl
  | cons c cs ih =>
      intro v hv
      rw [runNet_cons, runNet_cons, applyComp_comp_monotoneOn hf c v hv]
      exact ih (applyComp c v) (applyComp_mem c v hv)

/-- ✅ **THE GENERALISATION IS FAITHFUL** — the global lemma is the `Set.univ`
case, so nothing that used `runNet_comp_monotone` needs restating. -/
theorem runNet_comp_monotone_of_monotoneOn {g : α → β} (hg : Monotone g)
    (net : Network n) (v : Fin n → α) :
    runNet net (g ∘ v) = g ∘ runNet net v :=
  runNet_comp_monotoneOn (S := Set.univ) (hg.monotoneOn _) net v (fun _ => Set.mem_univ _)

end MonotoneOn

end SaltWorks.Stack

-- AXIOM AUDIT (#print axioms: the `decide`-blind #audit_axioms is not evidence here)
#print axioms SaltWorks.Stack.applyComp_comp_monotoneOn
#print axioms SaltWorks.Stack.applyComp_mem
#print axioms SaltWorks.Stack.runNet_mem
#print axioms SaltWorks.Stack.runNet_comp_monotoneOn
#print axioms SaltWorks.Stack.runNet_comp_monotone_of_monotoneOn

/-! ## THE INSTANTIATION — the natKey encoding, at the destination bound -/

namespace SaltWorks.HDL

open SaltWorks.Stack SaltWorks.HDL.PartialLift

/-- The `natKey` encoding, as a map on the ABSTRACT key carrier: `cKey`'s pair
`(!act, dst)` sent to `8 * (!act) + dst`. Matches `PartialLift.natKey`, which
reads `(if active then 0 else 8) + dest`. -/
def keyEnc (p : Bool ×ₗ ℕ) : ℕ := (if (ofLex p).1 then 8 else 0) + (ofLex p).2

/-- The set where the encoding is faithful: destination inside the fabric. -/
def keyLt8 : Set (Bool ×ₗ ℕ) := {p | (ofLex p).2 < 8}

/-- ⭐ **THE ENCODING IS MONOTONE EXACTLY HERE.** Off this set it inverts —
`toLex (false, 100) < toLex (true, 0)` while `100 > 8`. -/
theorem monotoneOn_keyEnc : MonotoneOn keyEnc keyLt8 := by
  intro x hx y hy hxy
  simp only [keyLt8, Set.mem_setOf_eq] at hx hy
  rcases Prod.Lex.le_iff.mp hxy with h | ⟨h1, h2⟩
  · -- the ACTIVE/IDLE bit strictly increases: x is active (`false`), y idle (`true`)
    have hb : (ofLex x).1 = false ∧ (ofLex y).1 = true := by
      revert h; cases (ofLex x).1 <;> cases (ofLex y).1 <;> simp
    have ex : keyEnc x = (ofLex x).2 := by simp [keyEnc, hb.1]
    have ey : keyEnc y = 8 + (ofLex y).2 := by simp [keyEnc, hb.2]
    rw [ex, ey]
    omega
  · -- same bit: the offsets are the SAME atom, so the destinations decide
    simp only [keyEnc, h1]
    omega

/-- ⭐⭐ **THE ABSTRACT SEAM.** Running the network on the ENCODED keys is the
encoding of running it on the keys — for any input vector inside the fabric's
destination bound. This is the arrow compiler's `ℕ`-carrier fold needs to reach
math's `Bool ×ₗ ℕ` sort. -/
theorem runNet_keyEnc {n : ℕ} (net : Network n) (v : Fin n → Bool ×ₗ ℕ)
    (hv : ∀ i, (ofLex (v i)).2 < 8) :
    runNet net (keyEnc ∘ v) = keyEnc ∘ runNet net v :=
  runNet_comp_monotoneOn monotoneOn_keyEnc net v hv

/-- ⭐⭐⭐ **AT `cSorted`.** The `ℕ`-keyed batcher run on the encoded `cKey`
vector IS the encoding of `cSorted` — the object `cSorted_strictMonoOn` is about.
The only hypothesis is the destination bound the decoder already guarantees. -/
theorem runNet_keyEnc_cKey (act : Fin 8 → Bool) (dst : Fin 8 → ℕ)
    (hd : ∀ i, dst i < 8) (i : Fin 8) :
    runNet batcher8 (fun j => keyEnc (SaltWorks.Silicon.cKey act dst j)) i = keyEnc (SaltWorks.Silicon.cSorted act dst i) :=
  congrFun (runNet_keyEnc batcher8 (SaltWorks.Silicon.cKey act dst) (fun j => hd j)) i

/-! ### END TO END — compiler's netlist key theorem meets `cSorted` -/

/-- `natKey` of a frame **is** the encoded convention-C key of that frame. The
two encodings were written independently, four hours apart, by two seats; this
says they agree. -/
theorem natKey_eq_keyEnc (f : List Bool) :
    natKey f = keyEnc (toLex (!(f.getD 0 false), cDestOf f)) := by
  simp only [natKey, keyEnc, ofLex_toLex]
  cases h : f.getD 0 false <;> simp

set_option maxHeartbeats 1000000 in
/-- ⭐⭐⭐⭐ **THE DAY-0 SEAM, CLOSED END TO END.** The key the NETLIST emits on
wire `w`, at partial load with idle lines permitted, is the encoding of `cSorted`
— the abstract sorted key vector `cSorted_strictMonoOn` is about.

Left side: `runTrace batcherNetC`, 24 hardware instances.
Right side: `runNet batcher8`, the abstract fold.
Nothing between them is assumed; the bridge is `runNet_comp_monotoneOn`. -/
theorem bnC_output_keys_are_cSorted (st : List Bool) (tr : List (List Bool)) (n L : Nat)
    (hrst : tr.map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (h0 : PartialStageOK st tr L 0)
    (act : Fin 8 → Bool) (dst : Fin 8 → ℕ)
    (hact : ∀ j : Fin 8, act j = (bnCFrameAt st tr 0 j.val).getD 0 false)
    (hdst : ∀ j : Fin 8, dst j = cDestOf (bnCFrameAt st tr 0 j.val))
    (w : Nat) (hw : w < 8) :
    natKey ((runTrace batcherNetC st tr).1.map (fun o => o.getD w false))
      = keyEnc (SaltWorks.Silicon.cSorted act dst ⟨w, hw⟩) := by
  have hag : ∀ i : Fin 8,
      (fun i => natKey (bnCFrameAt st tr 0 i)) i.val
        = (fun j : Fin 8 => keyEnc (SaltWorks.Silicon.cKey act dst j)) i := by
    intro i
    simp only [SaltWorks.Silicon.cKey, hact i, hdst i]
    exact natKey_eq_keyEnc _
  have hrun := runNetN_map_val batcher8 (fun j : Fin 8 => keyEnc (SaltWorks.Silicon.cKey act dst j))
      (fun i => natKey (bnCFrameAt st tr 0 i)) hag ⟨w, hw⟩
  simp only [Fin.val_mk] at hrun
  rw [bnC_output_keys_partial st tr n L hrst h0 w hw, bnComps_eq_batcher8, hrun]
  exact runNet_keyEnc_cKey act dst (fun i => by rw [hdst i]; exact cDestOf_lt_eight _) ⟨w, hw⟩

/-! ### TWO CONTROLS -/

/-- ⛔ **POSITIVE CONTROL — THE GENERALISATION IS NECESSARY, WITH A WITNESS.**
`runNet_comp_monotone` cannot prove any of the above, because `keyEnc` is **not**
monotone. An idle line with a large destination outranks an active one in the
`ℕ` encoding while sorting BELOW it in the lex order. This is the mutation that
makes the statement FALSE, exhibited rather than asserted. -/
theorem not_monotone_keyEnc : ¬ Monotone keyEnc := by
  intro hmono
  have hle : (toLex (false, 100) : Bool ×ₗ ℕ) ≤ toLex (true, 0) :=
    Prod.Lex.le_iff.mpr (Or.inl (by decide))
  have := hmono hle
  simp [keyEnc, ofLex_toLex] at this

/-- ✅ **NON-VACUITY — the two interface hypotheses discharge by `rfl`.** The
seam holds with `act`/`dst` read straight off the input frames, so nothing above
is waiting on an unsuppliable premise; what remains is exactly the binder set
compiler's `bnC_output_keys_partial` already carries. -/
theorem bnC_output_keys_are_cSorted_of_frames (st : List Bool) (tr : List (List Bool))
    (n L : Nat)
    (hrst : tr.map (fun i => i.getD 0 false) = true :: List.replicate n false)
    (h0 : PartialStageOK st tr L 0) (w : Nat) (hw : w < 8) :
    natKey ((runTrace batcherNetC st tr).1.map (fun o => o.getD w false))
      = keyEnc (SaltWorks.Silicon.cSorted
          (fun j : Fin 8 => (bnCFrameAt st tr 0 j.val).getD 0 false)
          (fun j : Fin 8 => cDestOf (bnCFrameAt st tr 0 j.val)) ⟨w, hw⟩) :=
  bnC_output_keys_are_cSorted st tr n L hrst h0 _ _ (fun _ => rfl) (fun _ => rfl) w hw

end SaltWorks.HDL

#print axioms SaltWorks.HDL.natKey_eq_keyEnc
#print axioms SaltWorks.HDL.bnC_output_keys_are_cSorted
#print axioms SaltWorks.HDL.monotoneOn_keyEnc
#print axioms SaltWorks.HDL.runNet_keyEnc
#print axioms SaltWorks.HDL.runNet_keyEnc_cKey
#print axioms SaltWorks.HDL.not_monotone_keyEnc
#print axioms SaltWorks.HDL.bnC_output_keys_are_cSorted_of_frames
