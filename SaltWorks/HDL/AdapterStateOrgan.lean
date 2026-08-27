/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude

# PRICING THE FALLBACK'S UNMEASURED HALF — the three adapter bits as an assembly obligation

`retire` is not a function of `Env`: it reads `kind` (2 bits) and `storeBeat` (1 bit), which are
ADAPTER registers. The fallback is to widen the state layout so those three bits are in the
domain. `StateCodec.lean:134` already measured the CODEC half of that widening and it PASSES.
**This file measures the half nobody had: `c4Spec_iff_fieldwise`'s first conjunct is
`c.outs.length = stWidth`, so the assembly must EMIT the three bits — and `core.outs` has no
producer for them.**

⭐ **THE PRODUCER IS THE FSM TRANSITION, WHICH IS ALREADY MODELLED** (`BusFSM.next`). So this is
a measurement, not a design: build the transition as gates, prove it equals the model over the
whole input space, and count.

⛔ **AND THE RENUMBERING MUST BE ONE ACT.** Step 7 already moves `stWidth` 1056 → 1313. These
three bits make it 1316. **Two independently-correct widenings land a wrong number**: an offset
computed against 1313 is wrong by 3 once the adapter bits land, and nothing in the type system
notices — both intermediate states are internally consistent.
-/
import SaltWorks.HDL.BusFSM
import SaltWorks.HDL.CoreAssemblyD

namespace SaltWorks.HDL.AdapterStateOrgan
open SaltWorks.HDL SaltWorks.HDL.BusFSM

/-! ### The encoding: `kind` as two bits, `idle=00 fetch=01 load=10 store=11` (busadapt8.v:76) -/

def encKind : Kind → Bool × Bool
  | .idle  => (false, false)
  | .fetch => (false, true)
  | .load  => (true,  false)
  | .store => (true,  true)

/-- Inputs: `k1 k0 b req we` on nets 0-4. -/
def k1N : Net := 0
def k0N : Net := 1
def bN  : Net := 2
def reqN : Net := 3
def weN : Net := 4

/-- ⭐ **THE ORGAN.** `k1' = (F∧req) ∨ (S∧¬b)` · `b' = S∧¬b` ·
`k0' = ¬k1' ∨ (S∧¬b) ∨ (F∧req∧we)`, where `F` is `fetch` and `S` is `store`. -/
def adapterNext : Circ :=
  { nIn := 5
  , gates :=
      [ ⟨5,  .not k1N⟩                 -- ¬k1
      , ⟨6,  .and 5 k0N⟩               -- F = fetch  = ¬k1 ∧ k0
      , ⟨7,  .and k1N k0N⟩             -- S = store  = k1 ∧ k0
      , ⟨8,  .not bN⟩                  -- ¬b
      , ⟨9,  .and 7 8⟩                 -- Sb = S ∧ ¬b        (the store's address beat)
      , ⟨10, .and 6 reqN⟩              -- Fr = F ∧ req       (a committed memory instruction)
      , ⟨11, .or 10 9⟩                 -- k1' = Fr ∨ Sb      (= ¬retire)
      , ⟨12, .and 10 weN⟩              -- Frw = Fr ∧ we
      , ⟨13, .not 11⟩                  -- retire
      , ⟨14, .or 13 9⟩
      , ⟨15, .or 14 12⟩ ]              -- k0' = retire ∨ Sb ∨ Frw
  , outs := [11, 15, 9] }              -- k1', k0', b'

/-- ⭐⭐ **THE PRICE, MEASURED: ELEVEN GATES.** -/
theorem adapterNext_gate_count : adapterNext.gates.length = 11 := by decide +kernel

theorem adapterNext_ports : adapterNext.nIn = 5 ∧ adapterNext.outs.length = 3 := by decide +kernel

theorem adapterNext_wf : adapterNext.wf = true := by decide +kernel
theorem adapterNext_ssa : adapterNext.ssa = true := by decide +kernel

/-- Inputs as an `Env`, for the exhaustive sweep. -/
def insOf (k1 k0 b req we : Bool) : Env := fun i =>
  if i = k1N then k1 else if i = k0N then k0 else if i = bN then b
  else if i = reqN then req else if i = weN then we else false

/-- ⭐⭐⭐ **THE ORGAN COMPUTES `BusFSM.next`, OVER ALL 32 INPUTS.** *Both sides are evaluated —
the gate net and the model — so this can fail.* -/
theorem adapterNext_correct :
    ([false,true].all fun k1 => [false,true].all fun k0 => [false,true].all fun b =>
     [false,true].all fun req => [false,true].all fun we =>
       let s : BusState := ⟨(match k1, k0 with
                             | false, false => .idle | false, true => .fetch
                             | true,  false => .load | true,  true  => .store), b⟩
       let t := next s req we
       sem adapterNext (insOf k1 k0 b req we)
         == [(encKind t.kind).1, (encKind t.kind).2, t.storeBeat]) = true := by
  decide +kernel

/-- ⛔ **NEGATIVE CONTROL — a mutated organ must NOT match.** Swapping the two `k1'` operands'
gate for an AND breaks it, so `adapterNext_correct` is not true of any circuit. -/
def adapterNextWrong : Circ :=
  { adapterNext with gates := adapterNext.gates.map (fun g =>
      if g.out = 11 then ⟨11, .and 10 9⟩ else g) }

theorem adapterNextWrong_disagrees :
    ([false,true].all fun k1 => [false,true].all fun k0 => [false,true].all fun b =>
     [false,true].all fun req => [false,true].all fun we =>
       let s : BusState := ⟨(match k1, k0 with
                             | false, false => .idle | false, true => .fetch
                             | true,  false => .load | true,  true  => .store), b⟩
       let t := next s req we
       sem adapterNextWrong (insOf k1 k0 b req we)
         == [(encKind t.kind).1, (encKind t.kind).2, t.storeBeat]) = false := by
  decide +kernel

/-! ## ⛔⛔ THE COMBINED RENUMBERING — ONE ACT, NOT TWO -/

/-- The widened state width: the D layout plus the three adapter bits. -/
def stWidthA : Nat := SaltWorks.HDL.StateCodecD.stWidthD + 3

theorem stWidthA_value : stWidthA = 1316 := by decide +kernel

/-- ⭐⭐ **THE THREE NUMBERS, AND THE SHIFT THAT MATTERS IS THE COMBINED ONE.** -/
theorem combined_renumbering :
    stWidth = 1056 ∧ SaltWorks.HDL.StateCodecD.stWidthD = 1313 ∧ stWidthA = 1316
    ∧ stWidthA - stWidth = 260 := by
  decide +kernel

/-- ⛔⛔ **WHY IT MUST BE ONE ACT.** The step-7 shift is 257 and the adapter shift is 3. Doing
them separately means an intermediate layout at 1313 whose offsets are **wrong by exactly 3**
for the final one — and each widening is internally consistent, so nothing refuses the
intermediate. *This theorem is the arithmetic of that trap.* -/
theorem two_widenings_land_short :
    (SaltWorks.HDL.StateCodecD.stWidthD - stWidth) + 3 = stWidthA - stWidth
    ∧ SaltWorks.HDL.StateCodecD.stWidthD ≠ stWidthA := by
  decide +kernel

/-- ⭐ **THE FULL ASSEMBLY OBLIGATION AT THE WIDENED LAYOUT.** Registers, pc, memory, trap and
the three adapter bits sum to `stWidthA` exactly. -/
theorem adapter_closes_the_widened_width :
    CorePlace.core.outs.length + (memOrgan.outs.drop 32).length + 1 + adapterNext.outs.length
      = stWidthA := by
  rw [CorePlace.core_outs_length, CoreAssemblyD.memOrgan_next_length]
  decide +kernel

#audit_axioms encKind adapterNext adapterNext_gate_count adapterNext_ports
#audit_axioms adapterNext_wf adapterNext_ssa insOf adapterNext_correct
#audit_axioms adapterNextWrong adapterNextWrong_disagrees
#audit_axioms stWidthA stWidthA_value combined_renumbering two_widenings_land_short
#audit_axioms adapter_closes_the_widened_width

/-! ## THE WIDENED LAYOUT'S ARITHMETIC — landed as ONE act at 1316, with the intermediate FENCED

⛔⛔ **THE 1313 INTERMEDIATE IS ALREADY IN THE TREE.** `StateCodecD.lean:319-326` lands
`instrBaseD := stWidthD` (= 1313) and `renumbering_offsets`, which pins `coreInWidth` at
1088 → 1345 and the shift at 257. **Those constants are correct for step 7 ALONE and WRONG by
exactly 3 if the adapter bits are adopted** — and nothing in the tree says so, because each is
internally consistent. This section says it, in the kernel.

⭐ **THIS FILE ADDS NO OFFSETS AT 1313.** The A constants are derived from `stWidthA` directly.
*Defining a gate anchor against `instrBaseD` and then "adjusting" it is exactly the two-step the
helm fenced, and it is avoidable by never writing the intermediate down as a base.* -/

/-- Where the instruction word sits under the widened layout. -/
def instrBaseA : Nat := stWidthA

/-- The gate-chain anchor under the widened layout. -/
def coreInWidthA : Nat := stWidthA + 32

theorem widened_anchors : instrBaseA = 1316 ∧ coreInWidthA = 1348 := by decide +kernel

/-- ⭐ **THE FIELD DECOMPOSITION AT 1316** — registers, pc, memory, trap, and the three adapter
bits, each accounted once. -/
theorem widened_fields : 1024 + 32 + 256 + 1 + 3 = stWidthA := by decide +kernel

/-- The three adapter bits occupy the top of the layout, above the trap flag. -/
def kindHiNet : Nat := 1313
def kindLoNet : Nat := 1314
def beatNet   : Nat := 1315

theorem adapter_bits_are_the_top_three :
    kindHiNet = SaltWorks.HDL.StateCodecD.stWidthD
    ∧ beatNet + 1 = stWidthA
    ∧ kindHiNet < kindLoNet ∧ kindLoNet < beatNet := by
  decide +kernel

/-- ⭐ **THE COMBINED SHIFT IS 260**, and the instruction nets stay disjoint from the state at
the new base — the same property `instrD_nets_disjoint_from_state` states for the D layout,
re-established here rather than assumed to survive a second widening. -/
theorem widened_shift_and_disjointness :
    instrBaseA - instrBase = 260
    ∧ coreInWidthA - coreInWidth = 260
    ∧ ((List.range 32).all fun k => instrBaseA + k ≥ stWidthA) = true := by
  decide +kernel

/-- ⛔⛔ **THE FENCE. The landed D constants are SHORT BY EXACTLY THREE under this layout.**
*Both are internally consistent, so no build refuses the intermediate; this theorem is the only
thing in the tree that does.* -/
theorem D_constants_are_short_by_three :
    instrBaseA - SaltWorks.HDL.StateCodecD.instrBaseD = 3
    ∧ coreInWidthA - (SaltWorks.HDL.StateCodecD.instrBaseD + 32) = 3
    ∧ SaltWorks.HDL.StateCodecD.instrBaseD ≠ instrBaseA := by
  decide +kernel

/-- ⛔ **AND THE TRAP STATED AS THE SUM IT IS:** doing step 7's widening and the adapter's
widening as two acts gives 257 then 3; the layout that results is only correct if EVERY offset
was computed against 1316, never against 1313. -/
theorem one_act_or_none :
    (SaltWorks.HDL.StateCodecD.stWidthD - stWidth) = 257
    ∧ (stWidthA - SaltWorks.HDL.StateCodecD.stWidthD) = 3
    ∧ (stWidthA - stWidth) = 260 := by
  decide +kernel

#audit_axioms instrBaseA coreInWidthA widened_anchors widened_fields
#audit_axioms kindHiNet kindLoNet beatNet adapter_bits_are_the_top_three
#audit_axioms widened_shift_and_disjointness D_constants_are_short_by_three one_act_or_none

end SaltWorks.HDL.AdapterStateOrgan
