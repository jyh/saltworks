/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.BatcherNet
import SaltWorks.HDL.CompareExchangeC
import SaltWorks.HDL.Compose
import SaltWorks.HDL.EmitS

/-!
# BB-1 · B2(C) — THE 8×8 SORTING NETWORK ON THE RATIFIED CONVENTION

**Silicon's B4 (`7012d3d`) ratified convention C and assigned the sorter's side
to this seat.** `CompareExchangeC` certified the ELEMENT (`457af25`). *This is the
NETWORK — the other half of "the sorter's side", and the half silicon is actually
blocked on: their D4 ceremony at 36 elements waits on it, and a composed theorem
over a seam whose two sides disagree at the bytes would prove nothing.*

## What changes, and it is not only the element

`BatcherNet.lean` builds the same 24-comparator bitonic network out of `ceCore`
on convention P. Under C the ACTIVITY WIRES DISAPPEAR — activity travels
interleaved on the data wire — so the change is visible at the top-level
interface, not merely inside each element:

```
                        convention P            convention C (this file)
primary inputs          1 rst + 8 act + 8 dat   1 rst + 8 dat          =  9
state                   24 × 2 = 48             24 × 4 = 96
core inputs             65                      105
core outputs            16 + 48 = 64            8 + 96 = 104
gates                   24 × 31 = 744           24 × 34 = 816
```

⚠️ **THE PIN COUNT IS THE POINT AND IT MOVES THE RIGHT WAY: 17 primary inputs
become 9.** *That is silicon's own ② (wire budget) showing up at network scale —
one wire per line rather than two, on an 8-input tile where pins are the binding
constraint.* **The gate count moves the wrong way (+72) and the flop count moves
the wrong way (+48); both were priced and neither binds at 21.3% of a 2×2.**

📌 **`wf` IS DISCHARGED STRUCTURALLY HERE, NOT BY `decide` ALONE.** *`Circ.wf`'s
`nodupB` is O(n²) and dies at ~3,000 gates. This core is 816 gates — under the
wall, but the wall is the reason `Circ.wf_of_ssa` (`f49b5a4`) exists, and using it
here is the first time an assembled network takes that route.*
-/

namespace SaltWorks.HDL

/-! ### The network -/

def bnCWires : Nat := 8
def bnCElems : Nat := 24

/-- `rst` on 0; data on `1…8`; state on `9…104`. **No activity wires.** -/
def bnCRst : Net := 0
def bnCDatIn (w : Nat) : Net := 1 + w
def bnCIn : Nat := 1 + bnCWires
/-- Element `e`'s four state bits: `decided, swap, phase, bothAct`. -/
def bnCState (e : Nat) : Net := bnCIn + 4 * e
def bnCCoreIn : Nat := bnCIn + 4 * bnCElems
/-- Element `e`'s 34 gates start here. -/
def bnCOff (e : Nat) : Nat := bnCCoreIn + ceCcore.gates.length * e

/-- The wiring for element `e` over comparator `(a,b)`, given the nets currently
carrying each wire. `ceCcore`'s inputs are
`rst, in0, in1, decided, swap, phase, bothAct`. -/
def bnCSigma (e a b : Nat) (dat : List Net) : Net → Net := fun i =>
  if i == 0 then bnCRst
  else if i == 1 then dat.getD a 0
  else if i == 2 then dat.getD b 0
  else if i == 3 then bnCState e
  else if i == 4 then bnCState e + 1
  else if i == 5 then bnCState e + 2
  else bnCState e + 3

/-- Fold the comparators, threading the per-wire nets and the gate list.
Returns gates, the final data nets, and the next-state nets in element order. -/
def bnCBuild : Nat → List (Nat × Nat) → List Net →
    List Gate × List Net × List Net
  | _, [],           dat => ([], dat, [])
  | e, (a, b) :: cs, dat =>
      let σ  := bnCSigma e a b dat
      let gs := instGates ceCcore σ (bnCOff e)
      let os := instOuts ceCcore σ (bnCOff e)
      -- ceCcore.outs = [out0, out1, decided', swap', phase', bothAct']
      let dat' := dat.set a (os.getD 0 0) |>.set b (os.getD 1 0)
      let (gs', datF, st) := bnCBuild (e + 1) cs dat'
      (gs ++ gs', datF,
        (os.getD 2 0) :: (os.getD 3 0) :: (os.getD 4 0) :: (os.getD 5 0) :: st)

def bnCResult : List Gate × List Net × List Net :=
  bnCBuild 0 bnComps ((List.range bnCWires).map bnCDatIn)

/-- **The network's combinational core.** -/
def bnCCore : Circ :=
  { nIn := bnCCoreIn
    gates := bnCResult.1
    outs := bnCResult.2.1 ++ bnCResult.2.2 }

/-- **The 8×8 sorting network on convention C.** Outputs are the eight data
wires; state is 24 × (decided, swap, phase, bothAct). -/
def batcherNetC : Seq :=
  { nIn := bnCIn, nOut := bnCWires, nState := 4 * bnCElems, core := bnCCore }

/-! ### The interface, pinned -/

theorem bnC_comps_count : bnComps.length = 24 := by decide +kernel
theorem bnC_core_inputs : bnCCore.nIn = 105 := by decide +kernel
theorem bnC_core_outputs : bnCCore.outs.length = 104 := by decide +kernel
theorem bnC_state_bits : batcherNetC.nState = 96 := by decide +kernel
theorem bnC_gate_count : bnCCore.gates.length = 816 := by decide +kernel

/-- ⭐ **THE PIN BUDGET, WHICH IS THE ARGUMENT SILICON PICKED C ON: 17 → 9.** -/
theorem bnC_design_inputs : batcherNetC.nIn = 9 ∧ batcherNet.nIn = 17 := by
  decide +kernel

/-! ### Well-formedness, discharged STRUCTURALLY

*The instances are laid out at `bnCCoreIn + 34·e`, so the gate outputs are dense
from `bnCCoreIn` — which is exactly `ssa`. `Circ.wf_of_ssa` then gives `wf`
without the kernel walking `nodupB`'s quadratic.* -/

theorem bnC_ssa : bnCCore.ssa = true := by decide +kernel

/-- **`wf` by the structural route** — the first assembled network to take it. -/
theorem bnCCore_wf : bnCCore.wf = true := Circ.wf_of_ssa bnC_ssa

theorem batcherNetC_wf : batcherNetC.wf = true := by
  -- `batcherNetC.core` is `bnCCore` only definitionally, so `rw` needs it restated
  -- at the projection first.
  have h : batcherNetC.core.wf = true := bnCCore_wf
  rw [Seq.wf, h]
  decide +kernel

/-! ### Sanity on the wiring -/

theorem bnC_comps_in_range :
    bnComps.all (fun c => c.1 < bnCWires && c.2 < bnCWires) = true := by decide +kernel

/-- Every wire is touched by at least one comparator — no line is left unsorted. -/
theorem bnC_every_wire_used :
    (List.range bnCWires).all
      (fun w => bnComps.any (fun c => c.1 == w || c.2 == w)) = true := by
  decide +kernel

/-- The 24 instances occupy disjoint, contiguous net ranges. -/
theorem bnC_instances_are_disjoint :
    (List.range bnCElems).all
      (fun e => bnCOff (e + 1) == bnCOff e + ceCcore.gates.length) = true := by
  decide +kernel

/-! ### ⭐ THE BEHAVIOURAL CERTIFICATES — because structure is not behaviour

⛔ **NEITHER NETWORK HAD ONE.** *`BatcherNet.lean` (convention P) carries `wf`, a
gate count, a cut census and two wiring sanity checks — and **no trace**. So does
this file, up to here.* ⇒ ***The 8×8 sorter has never been RUN in the kernel on
either convention.*** **That is the same defect as `ceC` being a price rather than
an element, one level up, and it is worth naming as a general shape: a structural
certificate suite reads as completeness right up until you ask what the thing
DOES.**

## The delivery window is real and it is six cycles

*Each element's crossbar is combinational, so there is no pipeline delay — but the
routing is not SETTLED until the addresses have streamed.* Under convention C the
header is six cycles (`act, a2, act, a1, act, a0`), **so cycles 0…5 carry
not-yet-latched routing and only the payload window `t ≥ 6` is deliverable.**
*This is `Seq.lean`'s "delivery window" hypothesis, instantiated: a statement of
the form `∀ t, out[dest](t) = in[src](t)` would be false, and the `.drop 6` below
is exactly why.*
-/

/-- Line `i` is active, bound for `7-i` — **fully reversed, the worst case for a
sorting network** — carrying its own index as a 3-bit payload so routing is
traceable rather than merely sorted. -/
def bnCFrames : List (List Bool) :=
  (List.range 8).map fun i => cFrame true (7 - i) ((List.range 3).map (Nat.testBit i))

/-- Drive the network: `rst` on cycle 0, then the eight streams in parallel. -/
def bnCRun (fs : List (List Bool)) : List (List Bool) :=
  (runTrace batcherNetC (List.replicate 96 false)
    ((List.range 9).map fun t =>
      (decide (t == 0)) :: (List.range 8).map (fun w => (fs.getD w []).getD t false))).1

/-- Output wire `k`'s stream. -/
def bnCOutWire (k : Nat) (fs : List (List Bool)) : List Bool :=
  (bnCRun fs).map (fun o => o.getD k false)

/-! #### ⚠️ THE FORMULATION IS THE COST, AND THE FIRST ONE DID NOT FIT

**Stating this as `(List.range 8).all fun j => (bnCOutWire j fs).drop 6 == …`
RE-RUNS THE WHOLE 816-GATE NETWORK ONCE PER WIRE — eight full traces — and it
dies `EXIT=137` (OOM kill) at `-M 20000`.** *The same claim stated as ONE run
compared against the whole output matrix costs a few seconds.* ⇒ ***The
certificate was not too expensive; the way I wrote it was.*** **Resource lesson,
and it generalises: `decide +kernel` shares nothing between the iterations of an
`all`, so a per-output quantifier over an expensive shared computation multiplies
that computation by the number of outputs.**
-/

/-- The payload window, as a matrix: row `b` is payload bit `b` across the eight
wires. Wire `j` should hold the frame bound for `j`, which entered on line `7-j`. -/
def bnCExpectedPayload : List (List Bool) :=
  (List.range 3).map fun b => (List.range 8).map fun j => Nat.testBit (7 - j) b

/-- ⭐ **THE 8×8 NETWORK SORTS — kernel-checked, on the fully reversed input, in
ONE run.** *Every payload arrives on the wire its destination names, so this
certifies ROUTING and not merely that the output is in order.* -/
theorem bnC_sorts_reversed_input :
    (bnCRun bnCFrames).drop 6 = bnCExpectedPayload := by decide +kernel

/-! #### Concentration — the `Set.Iio n` conjunct, at network scale -/

/-- Three active lines scattered across the inputs (2, 5, 7), bound for 0, 1, 2. -/
def bnCSparse : List (List Bool) :=
  (List.range 8).map fun i =>
    if i == 2 then cFrame true 0 [true, false, false]
    else if i == 5 then cFrame true 1 [false, true, false]
    else if i == 7 then cFrame true 2 [false, false, true]
    else cFrame false 0 [false, false, false]

/-- The three actives land on wires 0,1,2 and the other five stay silent. -/
def bnCSparseExpected : List (List Bool) :=
  [ [true,  false, false, false, false, false, false, false]
  , [false, true,  false, false, false, false, false, false]
  , [false, false, true,  false, false, false, false, false] ]

/-- ⭐ **IDLE SORTS HIGH AT NETWORK SCALE: three actives scattered over lines
2, 5, 7 land on wires 0, 1, 2 — CONTIGUOUS FROM ZERO — and the remaining five
wires stay silent.** *This is the banyan's second conjunct — sources concentrated
on `Set.Iio n` — DISCHARGED by the sorter rather than assumed of it, and the
five silent wires say the network cannot manufacture activity.* -/
theorem bnC_concentrates_actives :
    (bnCRun bnCSparse).drop 6 = bnCSparseExpected := by decide +kernel

#audit_axioms bnCWires bnCElems bnCRst bnCDatIn bnCIn bnCState bnCCoreIn bnCOff
#audit_axioms bnCSigma bnCBuild bnCResult bnCCore batcherNetC
#audit_axioms bnC_comps_count
#audit_axioms bnC_core_inputs
#audit_axioms bnC_core_outputs
#audit_axioms bnC_state_bits
#audit_axioms bnC_gate_count
#audit_axioms bnC_design_inputs
#audit_axioms bnC_ssa
#audit_axioms bnCCore_wf
#audit_axioms batcherNetC_wf
#audit_axioms bnC_comps_in_range
#audit_axioms bnC_every_wire_used
#audit_axioms bnC_instances_are_disjoint
#audit_axioms bnCFrames bnCRun bnCOutWire bnCExpectedPayload
#audit_axioms bnC_sorts_reversed_input
#audit_axioms bnCSparse bnCSparseExpected
#audit_axioms bnC_concentrates_actives

end SaltWorks.HDL
