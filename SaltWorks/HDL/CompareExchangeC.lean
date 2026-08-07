/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.CompareExchange

/-!
# PROBE — the compare-exchange element under OPTION C

**This is a price, not a replacement.** `docs/silicon-frame-protocol-0806.md`
§0.5 ruled **option C** — one wire per line, activity *repeated on the data wire*
before each address bit — over my `hdl-frame-protocol-v1.md`, which routes
activity on a parallel network. **I then built `ce`, `batcherNet` and the
structural emission on the losing convention** (`act0`/`act1` as separate
inputs), which is the `gl_test` mismatch silicon scoped to B4 at 12:51.

The ruling left a door: *"Open to objection. If the compiler seat can show the
parallel-activity design costs fewer GATES than two header cycles cost TIME — or
that it simplifies the sequential `Circ` semantics — I will switch."*

⇒ **Neither of us could price it on 8/6. This file prices it.**

## What option C forces on this element

Under option C a line carries **one** wire, alternating: even cycle = activity,
odd cycle = address bit. So the element must

* know which phase it is in — **a `phase` state bit**, and
* remember whether *both* lines were active, because the address comparison is
  gated on it and the activity arrived on the *previous* cycle —
  **a `bothAct` state bit**.

⇒ **4 state bits, against 2 for the parallel-activity element.** *That is the
cost, and it is a cost in FLOPS, which is the scarcest thing on a TT tile.*

**Everything about the ORDER carries over unchanged** — active-before-idle,
decide-at-first-difference, stability for two idle lines. *The idle-sorts-high
result is about the ordering, not the wiring, so `ce_rejects_idle_sorts_low`'s
content survives either ruling.*
-/

namespace SaltWorks.HDL

/-! ### Layout: `rst, in0, in1` on `0…2`; `decided, swap, phase, bothAct` on `3…6`. -/

/-- Option-C core. One wire per line; activity and address interleave. -/
def ceCcore : Circ where
  nIn := 7
  gates :=
    [ ⟨7,  .not 0⟩          -- ¬rst
    , ⟨8,  .and 3 7⟩        -- d    = decided ∧ ¬rst
    , ⟨9,  .not 8⟩          -- ¬d
    , ⟨10, .and 5 7⟩        -- p    = phase ∧ ¬rst     (rst forces the even phase)
    , ⟨11, .not 10⟩         -- even = ¬p
    , ⟨12, .and 6 7⟩        -- ba   = bothAct ∧ ¬rst
    , ⟨13, .xor 1 2⟩        -- diff = in0 ⊕ in1
    , ⟨14, .not 1⟩          -- ¬in0
    , ⟨15, .not 2⟩          -- ¬in1
    , ⟨16, .and 14 2⟩       -- swAct  = ¬in0 ∧ in1   (in0 idle ⇒ swap)
    , ⟨17, .and 1 15⟩       -- swAddr = in0 ∧ ¬in1   (in0 larger ⇒ swap)
    , ⟨18, .and 11 13⟩      -- even ∧ diff
    , ⟨19, .and 18 16⟩      -- even-phase decision
    , ⟨20, .and 10 12⟩      -- p ∧ ba
    , ⟨21, .and 20 13⟩      -- odd ∧ ba ∧ diff
    , ⟨22, .and 21 17⟩      -- odd-phase decision
    , ⟨23, .or 19 22⟩       -- newSw
    , ⟨24, .and 8 4⟩        -- d ∧ swap
    , ⟨25, .and 9 23⟩       -- ¬d ∧ newSw
    , ⟨26, .or 24 25⟩       -- sw
    , ⟨27, .not 26⟩         -- ¬sw
    , ⟨28, .and 27 1⟩
    , ⟨29, .and 26 2⟩
    , ⟨30, .or 28 29⟩       -- out0
    , ⟨31, .and 27 2⟩
    , ⟨32, .and 26 1⟩
    , ⟨33, .or 31 32⟩       -- out1
    , ⟨34, .or 18 21⟩       -- a decision happened this cycle
    , ⟨35, .or 8 34⟩        -- decided'
    , ⟨36, .and 1 2⟩        -- in0 ∧ in1
    , ⟨37, .and 11 36⟩      -- even ∧ (in0 ∧ in1)
    , ⟨38, .and 10 12⟩      -- p ∧ ba   (hold across the odd cycle)
    , ⟨39, .or 37 38⟩       -- bothAct'
    , ⟨40, .not 10⟩ ]       -- phase' = ¬p
  outs := [30, 33, 35, 26, 40, 39]   -- out0, out1, decided', swap', phase', bothAct'

/-- The option-C element: **2 primary inputs of data, 4 state bits.** -/
def ceC : Seq := { nIn := 3, nOut := 2, nState := 4, core := ceCcore }

theorem ceC_wf : ceC.wf = true := by decide +kernel

/-! ### THE PRICE, MEASURED -/

/-- Option C's element. -/
theorem ceC_gate_count : ceCcore.gates.length = 34 := by decide +kernel
/-- The landed parallel-activity element, for comparison. -/
theorem ce_gate_count' : ceCore.gates.length = 31 := by decide +kernel

/-- **The state cost, which is the one that matters: 4 bits against 2.** -/
theorem ceC_state_bits : ceC.nState = 4 := by decide +kernel
theorem ce_state_bits : ce.nState = 2 := by decide +kernel

/-- **Phase really is load-bearing** — the element's behaviour differs between
the two phases on the same inputs, so the extra state is not bookkeeping.
Even phase with `in0=0, in1=1` decides by ACTIVITY (idle `in0` swaps out);
odd phase with the same bits and `bothAct` decides by ADDRESS (`0 < 1`, no
swap). *Two different answers from one input pair — that is what the bit buys.* -/
theorem ceC_phase_is_load_bearing :
    (stepSeq ceC [false, false, false, true] [false, false, true]).1
      ≠ (stepSeq ceC [false, false, true, true] [false, false, true]).1 := by
  decide +kernel

#audit_axioms ceCcore
#audit_axioms ceC
#audit_axioms ceC_wf
#audit_axioms ceC_gate_count
#audit_axioms ce_gate_count'
#audit_axioms ceC_state_bits
#audit_axioms ce_state_bits
#audit_axioms ceC_phase_is_load_bearing

end SaltWorks.HDL
