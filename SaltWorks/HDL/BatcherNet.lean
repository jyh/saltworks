/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.CompareExchange
import SaltWorks.HDL.Compose
import SaltWorks.HDL.EmitS

/-!
# BB-1 · B2 — THE 8×8 SORTING NETWORK, AS A `Seq`

Silicon's 12:31 post names this as the blocker and the route:

> *B2 = emit `batcher_net` STRUCTURALLY (compiler's half, the same emitter C3
> validated at 128/128 and 100% on a 5,266-cell monolith), AND THEN THE 24
> OBLIGATIONS ARE 24 INSTANCES OF A THEOREM ALREADY IN THE KERNEL.*

**Their `(* keep *)` route did not close** — 96 element boundaries all survived
and the cones *did not shrink*: a 90-input cone against an element obligation
that should be seven. **The optimiser routed around the boundaries**, which is
the same failure measured in six blocks this morning, now at network scale.
*Structural emission is the campaign's ratified answer and this is its input.*

## The shape, and an unplanned cross-check

Built by instantiating `ceCore` once per comparator of the landed **bitonic**
`batcher8` (24 comparators, 6 layers of 4):

```
primary inputs   1 rst + 8 activity + 8 data                   =  17
state            24 elements × 2 bits (decided, swap)          =  48
core inputs      17 + 48                                       =  65
core outputs     16 (8 data + 8 activity) + 48 next-state      =  64
```

⭐ **Every one of those four numbers matches silicon's independently-built RTL
(`cee189e`: "65 primary inputs (17 design + 48 state), 64 outputs", 48 flops).**
*Two constructions from opposite ends — theirs in Verilog from the comparator
list, mine in `Circ` from the same list — agreeing on the interface without
either being derived from the other.* **That is the cheapest possible check that
we are building the same object, and it cost nothing because both numbers
already existed.**

## ⚠️ THE COMPARATOR LIST IS DUPLICATED HERE, DELIBERATELY

`batcher8` lives in `SaltWorks/Stack/ZeroOne.lean`, which uses `LinearOrder` and
therefore Mathlib. **Leg 2 is deliberately Mathlib-free** — it builds in 6 jobs
and its iteration does not compete for the fleet lock — so importing it here
would pay a large cost for 24 pairs of numbers.

⇒ **The list is transcribed, and the transcription is checked in a SEPARATE
module** (`SaltWorks/HDL/BatcherNetCheck.lean`) that imports both and confines
the Mathlib dependency to itself. *That is math's own `Bridge.lean` move —
the dependency boundary drawn where the conceptual one already is.*
**A transcription without that check would be exactly the `hbKappa` failure:
two records with a common ancestor, agreeing because one was copied from the
other.**
-/

namespace SaltWorks.HDL

/-! ### The network -/

/-- The landed **bitonic** `batcher8`'s comparator list, transcribed.
**Checked against `SaltWorks.Stack.batcher8` in `BatcherNetCheck`.** -/
def bnComps : List (Nat × Nat) :=
  [ (0, 1), (3, 2), (4, 5), (7, 6)
  , (0, 2), (1, 3), (6, 4), (7, 5)
  , (0, 1), (2, 3), (5, 4), (7, 6)
  , (0, 4), (1, 5), (2, 6), (3, 7)
  , (0, 2), (1, 3), (4, 6), (5, 7)
  , (0, 1), (2, 3), (4, 5), (6, 7) ]

def bnWires : Nat := 8
def bnElems : Nat := 24

/-- `rst` on 0; activity on `1…8`; data on `9…16`; state on `17…64`. -/
def bnRst : Net := 0
def bnActIn (w : Nat) : Net := 1 + w
def bnDatIn (w : Nat) : Net := 1 + bnWires + w
def bnIn : Nat := 1 + 2 * bnWires
def bnState (e : Nat) : Net := bnIn + 2 * e
def bnCoreIn : Nat := bnIn + 2 * bnElems
/-- Element `e`'s 31 gates start here. -/
def bnOff (e : Nat) : Nat := bnCoreIn + ceCore.gates.length * e

/-- The wiring for element `e` over comparator `(a,b)`, given the nets currently
carrying each wire's activity and data. `ceCore`'s inputs are
`rst, act0, act1, in0, in1, decided, swap`. -/
def bnSigma (e a b : Nat) (act dat : List Net) : Net → Net := fun i =>
  if i == 0 then bnRst
  else if i == 1 then act.getD a 0
  else if i == 2 then act.getD b 0
  else if i == 3 then dat.getD a 0
  else if i == 4 then dat.getD b 0
  else if i == 5 then bnState e
  else bnState e + 1

/-- Fold the comparators, threading the per-wire nets and the gate list.
Returns gates, final activity nets, final data nets, and the next-state nets in
element order. -/
def bnBuild : Nat → List (Nat × Nat) → List Net → List Net →
    List Gate × List Net × List Net × List Net
  | _, [],          act, dat => ([], act, dat, [])
  | e, (a, b) :: cs, act, dat =>
      let σ  := bnSigma e a b act dat
      let gs := instGates ceCore σ (bnOff e)
      let os := instOuts ceCore σ (bnOff e)
      -- ceCore.outs = [out0, out1, oact0, oact1, decided', swap']
      let dat' := dat.set a (os.getD 0 0) |>.set b (os.getD 1 0)
      let act' := act.set a (os.getD 2 0) |>.set b (os.getD 3 0)
      let (gs', actF, datF, st) := bnBuild (e + 1) cs act' dat'
      (gs ++ gs', actF, datF, (os.getD 4 0) :: (os.getD 5 0) :: st)

def bnResult : List Gate × List Net × List Net × List Net :=
  bnBuild 0 bnComps ((List.range bnWires).map bnActIn) ((List.range bnWires).map bnDatIn)

/-- **The network's combinational core.** -/
def bnCore : Circ :=
  { nIn := bnCoreIn
    gates := bnResult.1
    outs := bnResult.2.2.1 ++ bnResult.2.1 ++ bnResult.2.2.2 }

/-- **The 8×8 sorting network as a sequential machine.** Outputs are the eight
sorted data bits then the eight activity bits; state is 24 × (decided, swap). -/
def batcherNet : Seq :=
  { nIn := bnIn, nOut := 2 * bnWires, nState := 2 * bnElems, core := bnCore }

/-! ### The interface, pinned — and it is silicon's RTL's interface

*These four numbers were measured independently on the Verilog side before this
file existed. Pinning them here makes the agreement a check rather than a
coincidence noticed once.* -/

theorem bn_comps_count : bnComps.length = 24 := by decide +kernel
theorem bn_core_inputs : bnCore.nIn = 65 := by decide +kernel
theorem bn_core_outputs : bnCore.outs.length = 64 := by decide +kernel
theorem bn_state_bits : batcherNet.nState = 48 := by decide +kernel
theorem bn_design_inputs : batcherNet.nIn = 17 := by decide +kernel

/-- 24 elements × 31 gates. -/
theorem bn_gate_count : bnCore.gates.length = 744 := by decide +kernel

/-- **The machine is well-formed** — widths consistent, wiring closed. -/
theorem batcherNet_wf : batcherNet.wf = true := by decide +kernel

/-- **Every comparator addresses a real wire**, so no element is wired to a net
that does not exist. -/
theorem bn_comps_in_range :
    bnComps.all (fun c => c.1 < bnWires && c.2 < bnWires) = true := by decide +kernel

/-- **Every wire is touched** — a comparator list that ignored a wire would sort
seven of eight and pass a spot check. -/
theorem bn_every_wire_used :
    (List.range bnWires).all
      (fun w => bnComps.any (fun c => c.1 == w || c.2 == w)) = true := by decide +kernel


/-! ### STRUCTURAL EMISSION — silicon's actual ask

*Their `(* keep *)` route left 96 boundaries surviving with cones that did not
shrink: a 90-input cone against a seven-input element obligation, because the
optimiser routed around the attribute. **Structural emission does not ask the
optimiser for permission** — every gate is an instantiated cell, so the element
boundaries are cell outputs and cannot be merged away without deleting a cell.*

`emitSMux` is the peephole form — the one that took the C3 monolith from 5,270
to 2,006 cells — and it is what B2 should synthesise. -/

/-- The network's Verilog, structural, drive-1 cells. -/
def batcherNetV : String := emitSMux "1" "batcher_net" bnCore

/-- The element-boundary cut set: **the six outputs of every one of the 24
elements**, which is exactly the decomposition that turns the network's
obligation into 24 copies of `ce_step_eq`. -/
def bnElementCuts : List Net :=
  (List.range bnElems).flatMap fun e =>
    ceCore.outs.map (instMap ceCore (fun i => i) (bnOff e))

theorem bn_cut_count : bnElementCuts.length = 144 := by decide +kernel

-- Emission size, MEASURED (a String length, not a theorem about the design).
#eval batcherNetV.length
#eval bnElementCuts.length

#audit_axioms bnComps
#audit_axioms bnSigma
#audit_axioms bnBuild
#audit_axioms bnCore
#audit_axioms batcherNet
#audit_axioms bn_comps_count
#audit_axioms bn_core_inputs
#audit_axioms bn_core_outputs
#audit_axioms bn_state_bits
#audit_axioms bn_design_inputs
#audit_axioms bn_gate_count
#audit_axioms batcherNet_wf
#audit_axioms bn_comps_in_range
#audit_axioms bn_every_wire_used
#audit_axioms batcherNetV
#audit_axioms bnElementCuts
#audit_axioms bn_cut_count

end SaltWorks.HDL
