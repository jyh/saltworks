/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Silicon.Imported.CompareExchange

/-!
# BB-1 · B1 — the compare-exchange element, GATE NETLIST refined

The silicon half of B1. Compiler's `SaltWorks/HDL/CompareExchange.lean`
(`d762dbc`) proves the element sorts **at the `Circ`/`Seq` level**:
`ce_step_eq` over all 128 configurations, `ce_frame_3`, `ce_frame_4`.
**That chain does not reach the gates.** This file closes that span, by the
`SwitchRefinement` pattern:

    synthesised gate netlist  ==(this file, decide +kernel over all 128)==>  ceSpec

`ceNL` is the **flow's** netlist — `RTL/ce_elem.v` transcribed equation-by-equation
from `ceCore`, synthesised by the pinned flow (16 cells, 2 flops), imported by the
flop treatment (5 design inputs + 2 state; 4 design outputs + 2 next-state) and
checked by the importer's readback against the vendor Liberty.

`ceSpec` below is written **independently, in the primitive basis, in a different
shape** — the way `refComparator` is written against `comparatorNL`. Agreement is
therefore a real check and not a restatement.

⚠️ **What this file does NOT claim.** It refines the ELEMENT. The network is B2,
and the composed-switch claim additionally needs the four seam obligations of
`docs/silicon-bb1-B0bc-0807.md` — including the one nobody had priced, that the
banyan leg is Mathlib-free and has no sortedness predicate at all.
-/

namespace SaltWorks.Silicon.Imported

open SaltWorks.Silicon

/-- The reference element, written directly from the behavioural description
rather than from the netlist: `sw` decides once and holds; the smaller key goes
low; an idle line is treated as larger than any active one.

Inputs `0=rst 1=act0 2=act1 3=in0 4=in1 5=decided 6=swap` — the same layout the
importer emitted, which is what makes the two comparable. -/
def ceSpec : Netlist :=
  [ .inp 0, .inp 1, .inp 2, .inp 3, .inp 4, .inp 5, .inp 6   -- 0..6
  , .not 0                     -- 7   ¬rst
  , .and 5 7                   -- 8   d = decided ∧ ¬rst
  , .not 8                     -- 9   ¬d
  , .not 1                     -- 10  ¬act0
  , .and 2 10                  -- 11  idleSw = act1 ∧ ¬act0
  , .and 1 2                   -- 12  bothAct
  , .not 4                     -- 13  ¬in1
  , .and 3 13                  -- 14  addrSw = in0 ∧ ¬in1
  , .and 12 14                 -- 15  bothAct ∧ addrSw
  , .or 11 15                  -- 16  newSw
  , .and 8 6                   -- 17  d ∧ swap
  , .and 9 16                  -- 18  ¬d ∧ newSw
  , .or 17 18                  -- 19  sw
  , .not 19                    -- 20  ¬sw
  , .and 20 3, .and 19 4, .or 21 22   -- 21,22,23  out0
  , .and 20 4, .and 19 3, .or 24 25   -- 24,25,26  out1
  , .and 20 1, .and 19 2, .or 27 28   -- 27,28,29  oact0
  , .and 20 2, .and 19 1, .or 30 31   -- 30,31,32  oact1
  , .xor 3 4                   -- 33  addrDiff
  , .and 12 33                 -- 34  bothAct ∧ addrDiff
  , .xor 1 2                   -- 35  actDiff
  , .or 35 34                  -- 36
  , .or 8 36 ]                 -- 37  decided'

/-- Output indices of `ceSpec`: `out0, out1, oact0, oact1, decided', swap'`. -/
def ceSpec_outs : List Nat := [23, 26, 29, 32, 37, 19]

/-- All 128 valuations of the seven inputs, as bit patterns. -/
def ceCases : List Nat := List.range 128

/-- Read a netlist's chosen outputs under the valuation encoded by `j`. -/
def ceRead (nl : Netlist) (idx : List Nat) (j : Nat) : List Bool :=
  idx.map (fun k => (runP (fun i => j.testBit i) [] nl).getD k false)

/-- **B1 — THE ELEMENT REFINES, AT THE GATES.** For every one of the 128
configurations of 5 primary inputs and 2 state bits, the synthesised netlist's
four outputs and two next-state bits agree with the reference. No reachability
assumption: every state is quantified, including unreachable ones. -/
theorem ce_step_eq :
    ceCases.all (fun j => ceRead ceNL ceNL_outs j == ceRead ceSpec ceSpec_outs j)
      = true := by decide +kernel

/-- **The stability law.** Once the element has decided and reset is low, the
decision is held: `decided'` stays high and `swap'` reproduces `swap`, whatever
arrives on the address lines. This is what lets the payload window inherit the
address window's verdict. -/
theorem ce_stable :
    (ceCases.filter (fun j => j.testBit 5 && !j.testBit 0)).all (fun j =>
      let o := ceRead ceNL ceNL_outs j
      o.getD 4 false == true && o.getD 5 false == j.testBit 6) = true := by
  decide +kernel

/-- ⭐ **`ce_rejects_idle_sorts_low`** — an idle line never wins the low port.
When line 0 is idle and line 1 is active, the element swaps, so the ACTIVE
packet leaves on `out0`/`oact0`. This is the fixture the composed switch needs:
it is exactly the idle-sentinel convention that makes a Batcher's output
*concentrated*, which `scenario` assumes and does not prove. -/
theorem ce_rejects_idle_sorts_low :
    (ceCases.filter (fun j => !j.testBit 1 && j.testBit 2 && !j.testBit 5)).all
      (fun j => (ceRead ceNL ceNL_outs j).getD 2 false == true) = true := by
  decide +kernel

end SaltWorks.Silicon.Imported

section Audit
open Salt.Tactic
#audit_axioms SaltWorks.Silicon.Imported.ce_step_eq
  SaltWorks.Silicon.Imported.ce_stable
  SaltWorks.Silicon.Imported.ce_rejects_idle_sorts_low
end Audit
