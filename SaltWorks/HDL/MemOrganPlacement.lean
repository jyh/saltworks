/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.AdapterPlacement
import SaltWorks.HDL.CoreAssemblyD

/-!
# memOrgan's σ — 256 of its 292 inputs are LAYOUT, not design

`CoreAssemblyD`'s header calls memOrgan's σ *"a datapath design question"* over **292 inputs**, and
`AdapterPlacement` carries it as the one debt still standing between that file and a placed
assembly. **Measured, the 292 are not alike.**

```
mAddrNet j = j        j < 3     3 address bits    ← datapath's
mWeNet     = 3                  1 write-enable    ← datapath's
mWData k   = 4 + k    k < 32    32 write-data     ← datapath's
mQ w k     = 36 + 32*w + k      256 Q-LEAVES      ← THE MEMORY'S OWN CURRENT STATE
```
**The 256 Q-leaves are not a design question at all — they are the memory field of the state
layout, read back.** Registers occupy 0–1023, pc 1024–1055, so memory occupies 1056–1311, and the
organ-local index `36 + 32*w + k` maps to the host net `1056 + 32*w + k`. One affine map,
`i ↦ i + 1020`, over five sixths of the input list.

⇒ **the free part is THIRTY-SIX WIRES, not 292** — and they are the datapath's, exactly as `req`
and `we` were in `AdapterPlacement`. Same lift, same reason.

⛔ **WHAT THIS DOES NOT DO.** It does not supply the 36 datapath nets and it does not assemble the
core. It discharges `instOK memOrgan` down to those 36, and it removes the memory-length hypothesis
from the 1316 arithmetic by PLACING the organ rather than assuming a list of the right size.
-/

namespace SaltWorks.HDL.MemOrganPlacement

open SaltWorks.HDL SaltWorks.HDL.AdapterPlacement SaltWorks.HDL.AdapterStateOrgan

/-! ## §1 — THE MEMORY FIELD'S BASE, DERIVED -/

/-- Registers (1024) then pc (32). The memory field starts here and runs 256 bits. -/
def memBaseA : Nat := 1056

/-- ⭐ The field decomposition already landed in `AdapterStateOrgan` pins this: the memory field
sits directly above pc and directly below the trap flag. -/
theorem memBaseA_is_above_pc_and_below_trap :
    1024 + 32 = memBaseA
    ∧ memBaseA + 256 = 1312
    ∧ memBaseA + 256 + 1 = SaltWorks.HDL.AdapterStateOrgan.kindHiNet := by
  decide +kernel

/-! ## §2 — THE WIRING: 256 LAYOUT, 36 FREE -/

/-- memOrgan's σ. The Q-leaf tail is a single affine map into the layout's memory field; only the
first 36 indices are the datapath's to choose. -/
def memSigma (addr : Nat → Net) (weNet : Net) (wdata : Nat → Net) : Net → Net := fun i =>
  if i < 3 then addr i
  else if i = 3 then weNet
  else if i < 36 then wdata (i - 4)
  else i + 1020

/-- ⭐⭐ **THE Q-LEAF AT `(w,k)` READS THE HOST'S MEMORY BIT `(w,k)`.** This is the whole content
of "256 of the inputs are layout": the organ's view and the state layout agree, index for index. -/
theorem memSigma_reads_the_memory_field (addr : Nat → Net) (weNet : Net) (wdata : Nat → Net)
    (w k : Nat) :
    memSigma addr weNet wdata (mQ w k) = memBaseA + 32 * w + k := by
  -- ⚠️ `abbrev Net := Nat` is NOT transparent to omega's preprocessing: it DROPS a goal whose
  -- `<` sits at `Net`, then reports a "counterexample" built only from the hypotheses. That tell
  -- is in this seat's own card and in three sites in this tree. THE CURE: prove every bound at
  -- `Nat` and supply it as a TERM.
  have n1 : ¬ ((36 + 32 * w + k : Nat) < 3) := by omega
  have n2 : ¬ ((36 + 32 * w + k : Nat) = 3) := by omega
  have n3 : ¬ ((36 + 32 * w + k : Nat) < 36) := by omega
  have hval : (36 + 32 * w + k : Nat) + 1020 = 1056 + 32 * w + k := by omega
  have hq : mQ w k = 36 + 32 * w + k := rfl
  rw [hq]
  simp only [memSigma, memBaseA, if_neg n1, if_neg n2, if_neg n3]
  exact hval

/-- ⭐⭐⭐ **`instOK memOrgan` DISCHARGED DOWN TO THIRTY-SIX WIRES.** `memOrgan` is already `ssa`
and `wf`, so the whole side condition is the input bound — and 256 of the 292 discharge by
arithmetic, because the layout puts them below the trap flag. -/
theorem mem_instOK (addr : Nat → Net) (weNet : Net) (wdata : Nat → Net) (off : Nat)
    (hoff : memBaseA + 256 ≤ off)
    (haddr : ∀ j, j < 3 → addr j < off) (hwe : weNet < off)
    (hwd : ∀ k, k < 32 → wdata k < off) :
    instOK memOrgan (memSigma addr weNet wdata) off := by
  -- Same cure as above: every bound restated at `Nat` and supplied as a term.
  have hoffN : (1312 : Nat) ≤ off := by simp only [memBaseA] at hoff; exact hoff
  refine ⟨memOrgan_ssa, memOrgan_wf, ?_⟩
  intro i hi
  rw [memOrgan_ports.1] at hi
  have hiN : (i : Nat) < 292 := hi
  simp only [memSigma]
  split_ifs with h1 h2 h3
  · exact haddr i h1
  · exact hwe
  · have h3N : (i : Nat) < 36 := h3
    exact hwd (i - 4) (by omega)
  · have h3N : ¬ ((i : Nat) < 36) := h3
    have hb : (i : Nat) + 1020 < off := by omega
    exact hb

/-! ## §3 — THE 1316 ARITHMETIC, WITH MEMORY GENUINELY PLACED -/

/-- ⭐⭐⭐ **THE MEMORY-LENGTH HYPOTHESIS IS GONE.** `AdapterPlacement.widenedOuts_length` took
`memPlaced.length = 256` on trust. Placing the organ discharges it outright, for **every** σ and
offset — so the 1316 receipt no longer rests on a list somebody promises is the right size. -/
theorem widened_length_with_memory_placed
    (trapNet : Net) (σm σa : Net → Net) (offm offa : Nat) :
    (widenedOuts ((instOuts memOrgan σm offm).drop 32) trapNet σa offa).length
      = SaltWorks.HDL.AdapterStateOrgan.stWidthA :=
  widenedOuts_length _ (CoreAssemblyD.memOrgan_next_length_placed σm offm) trapNet σa offa

/-- ⭐⭐ **AND THE ADAPTER BITS STILL LAND ON TOP** once memory is really placed. -/
theorem adapter_bits_on_top_with_memory_placed
    (trapNet : Net) (σm σa : Net → Net) (offm offa : Nat) :
    (widenedOuts ((instOuts memOrgan σm offm).drop 32) trapNet σa offa).drop 1313
      = instOuts adapterNext σa offa :=
  adapter_bits_are_the_top_outputs _ (CoreAssemblyD.memOrgan_next_length_placed σm offm)
    trapNet σa offa

/-! ## §4 — CONTROLS -/

/-- ⛔ **THE OFFSET BOUND IS LOAD-BEARING.** Placed at the memory field's own base, the Q-leaves
are not below the offset and `instOK` fails — so `mem_instOK`'s `hoff` is doing work. -/
theorem control_mem_instOK_needs_the_offset (addr : Nat → Net) (weNet : Net) (wdata : Nat → Net) :
    ¬ instOK memOrgan (memSigma addr weNet wdata) memBaseA := by
  rintro ⟨-, -, h3⟩
  have h := h3 (mQ 7 31) (by rw [memOrgan_ports.1]; show (36 + 32 * 7 + 31) < 292; omega)
  rw [memSigma_reads_the_memory_field] at h
  simp only [memBaseA] at h
  have hN : (1056 + 32 * 7 + 31 : Nat) < 1056 := h
  omega

/-- ⛔ **THE Q-LEAF MAP IS NOT THE IDENTITY**, so §2 is not a restatement of `fun i => i`. -/
theorem control_q_leaf_map_moves (addr : Nat → Net) (weNet : Net) (wdata : Nat → Net) :
    memSigma addr weNet wdata (mQ 0 0) ≠ mQ 0 0 := by
  rw [memSigma_reads_the_memory_field]
  show ¬ (1056 + 32 * 0 + 0 = 36 + 32 * 0 + 0)
  decide

#audit_axioms memBaseA memBaseA_is_above_pc_and_below_trap memSigma
#audit_axioms memSigma_reads_the_memory_field mem_instOK
#audit_axioms widened_length_with_memory_placed adapter_bits_on_top_with_memory_placed
#audit_axioms control_mem_instOK_needs_the_offset control_q_leaf_map_moves

end SaltWorks.HDL.MemOrganPlacement
