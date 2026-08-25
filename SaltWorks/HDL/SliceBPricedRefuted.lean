/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.AluSelect
import SaltWorks.HDL.MemOrgan
import SaltWorks.HDL.Immediate

/-! # Slice-B B1/B3 against the corpus — MIG-4, the emitted-path measurements

The three things the block asked this seat to price, measured on the LANDED artifacts.

## 1. The memory organ in the EMITTED PATH — a THIRD instrument, same direction

`memOrgan` is **1475 gates** against the **−1,154 gates banked AT THE SELECT**: `1.28×` over.
⭐ B1 rules µm² "the only honest axis" and reports `1.50×` over by area, while noting that **by
cell COUNT it "falsely looks 42% under"**. The gate axis is a third instrument and it agrees
with AREA, not with cell count. ⇒ **The flattering reading is specific to cell-count; it does
not generalise to gates, so B1's verdict survives a third axis it was not measured on.**

## 2. BNE is not "near-free" — it is FREE, and CHEAPER than BEQ

`zeroTree` is an **OR-reduction** (31 gates) whose raw output is TRUE when the word is
NONZERO — measured, not read off the docstring. **That is exactly BNE's condition.** BEQ needs
one further inversion on top. So BNE taps the tree's native polarity and BEQ pays the inverter.

⛔ **BUT THE SAVING IS UNPRICED AT CORE LEVEL, BECAUSE THE COMPARE IS NOT PLACED.** `zeroTree`
and `zrOut` occur **ZERO** times in `CorePlace.lean` and `CoreAssembly.lean`. The organ is landed
and certified; it is in no datapath. **Adding BNE therefore requires first PLACING a compare, and
that cost is not in B1's number.** ⚠️ Same structural class as the flagship's `immICirc` defect:
certified, and placed nowhere.

## 3. The encoder extension is FREE in silicon; its cost is entirely proof-side

`immICirc` is **0 gates** and `immBCirc` is **1 gate** — the immediate "encoders" are rewirings
onto input nets, not logic. ⇒ B3's "encoder extension, one theorem each" prices out as **~0 gates
and N theorems**: the extension is a PROOF obligation wearing a datapath's name.

⛔ **AND ITS COMPARAND IS UNDEFINED.** "the c1 organ" occurs in exactly TWO places — this block's
assignment line and the QUEUE row copying it — and is defined NOWHERE. Several unrelated `C1`s
exist in other docs (a stack-campaign gate, a refuter item, others), **which is worse than none:
it invites a reader to pick one and believe they have matched the referent.** The measurement
above is what can be answered without guessing which `C1` was meant.
-/

namespace SaltWorks.HDL.MIG4
open SaltWorks.HDL

/-- The memory organ's emitted-path size. `1475 > 1154`, i.e. 1.28× the banked select saving. -/
theorem memOrgan_emitted_size :
    memOrgan.gates.length = 1475 ∧ memOrgan.outs.length = 288 := by
  refine ⟨by decide +kernel, by decide +kernel⟩

/-- ⭐ **THE COMPARE TREE'S POLARITY IS BNE's, NOT BEQ's** — measured in the kernel: the raw
output is `false` on an all-zero word and `true` as soon as any bit is set. -/
theorem zeroTree_is_nonzero_polarity :
    sem zeroTree (fun _ => false) = [false]
  ∧ sem zeroTree (fun n => n == 0) = [true]
  ∧ sem zeroTree (fun n => n == 31) = [true] := by
  refine ⟨by decide +kernel, by decide +kernel, by decide +kernel⟩

/-- The shared compare cone is 31 gates; BNE adds none of them. -/
theorem zeroTree_cone_size : zeroTree.gates.length = 31 := by decide +kernel

/-- The immediate encoders are rewirings, not logic. -/
theorem immediate_encoders_are_free :
    immICirc.gates.length = 0 ∧ immBCirc.gates.length = 1 := by
  refine ⟨by decide +kernel, by decide +kernel⟩

end SaltWorks.HDL.MIG4

#print axioms SaltWorks.HDL.MIG4.memOrgan_emitted_size
#print axioms SaltWorks.HDL.MIG4.zeroTree_is_nonzero_polarity
#print axioms SaltWorks.HDL.MIG4.immediate_encoders_are_free
