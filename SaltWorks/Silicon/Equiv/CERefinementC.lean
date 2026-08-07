/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Silicon.Imported.CompareExchangeC

/-!
# BB-1 · B4 — the CONVENTION-C element, refined AT THE GATES

Compiler's `ceC_step_eq` proves the element at the `Circ`/`Seq` level. This
closes the span the `Circ` chain cannot reach: **the hardened gate netlist**.

`ceCNL` is compiler's `ceCcore` emitted by their own `emitS`, pushed through the
pinned flow in structural mode (**34 cells in, 34 out — exact passthrough**) and
imported, with the importer's readback agreeing with the vendor Liberty.

⚠️ **`ceCSpec` below is written from compiler's BEHAVIOURAL spec (`ceCSpecStep`),
not from their gate list.** Their circuit was derived from the protocol; mine is
derived from the same protocol independently, in a different gate order. *That is
what makes agreement a check rather than a transcription of a transcription.*

⚠️ **Why the reference is local and not imported.** `SaltWorks.HDL` imports
`SaltWorks.Silicon` (`emitN : Circ → Silicon.Netlist`), so a Silicon module
**cannot** import HDL — the dependency would cycle. The one-line theorem tying
`ceCNL` to `emitN ceCcore` therefore has to live in HDL, which is compiler's
writer slot. **`import owed`, and it is theirs to write.**

Input layout, matching the import: `0=rst 1=in0 2=in1 3=decided 4=swap 5=phase
6=bothAct`. Outputs: `out0, out1, decided', swap', phase', bothAct'`.
-/

namespace SaltWorks.Silicon.Imported

open SaltWorks.Silicon

/-- The reference element for convention C, from the protocol description. -/
def ceCSpec : Netlist :=
  [ .inp 0, .inp 1, .inp 2, .inp 3, .inp 4, .inp 5, .inp 6   -- 0..6
  , .not 0            -- 7   ¬rst
  , .and 3 7          -- 8   d = decided ∧ ¬rst
  , .and 5 7          -- 9   p = phase ∧ ¬rst
  , .and 6 7          -- 10  b = bothAct ∧ ¬rst
  , .xor 1 2          -- 11  diff
  , .not 1            -- 12  ¬in0
  , .not 2            -- 13  ¬in1
  , .and 12 2         -- 14  swAct  = ¬in0 ∧ in1
  , .and 1 13         -- 15  swAddr = in0 ∧ ¬in1
  , .not 9            -- 16  even = ¬p
  , .and 16 11        -- 17  evenD
  , .and 9 10         -- 18  p ∧ b
  , .and 18 11        -- 19  oddD
  , .and 17 14        -- 20  evenD ∧ swAct
  , .and 19 15        -- 21  oddD ∧ swAddr
  , .or 20 21         -- 22  newSw
  , .and 8 4          -- 23  d ∧ swap
  , .not 8            -- 24  ¬d
  , .and 24 22        -- 25  ¬d ∧ newSw
  , .or 23 25         -- 26  s
  , .not 26           -- 27  ¬s
  , .and 27 1, .and 26 2, .or 28 29    -- 28,29,30  out0
  , .and 27 2, .and 26 1, .or 31 32    -- 31,32,33  out1
  , .or 17 19         -- 34  a decision happened
  , .or 8 34          -- 35  decided'
  , .and 1 2          -- 36  in0 ∧ in1
  , .and 16 36        -- 37  even ∧ (in0 ∧ in1)
  , .or 37 18         -- 38  bothAct'
  , .not 9 ]          -- 39  phase' = ¬p

/-- `out0, out1, decided', swap', phase', bothAct'`. -/
def ceCSpec_outs : List Nat := [30, 33, 35, 26, 39, 38]

/-- All 128 valuations of 3 primary inputs and 4 state bits. -/
def ceCCases : List Nat := List.range 128

def ceCRead (nl : Netlist) (idx : List Nat) (j : Nat) : List Bool :=
  idx.map (fun k => (runP (fun i => j.testBit i) [] nl).getD k false)

/-- ⭐ **B4 — THE CONVENTION-C ELEMENT REFINES AT THE GATES.** For every one of
the 128 configurations of 3 primary inputs and 4 state bits, the hardened
netlist's two data outputs and four next-state bits agree with the reference.
**No reachability assumption**: unreachable states are quantified too. -/
theorem ceC_gate_eq :
    ceCCases.all (fun j => ceCRead ceCNL ceCNL_outs j == ceCRead ceCSpec ceCSpec_outs j)
      = true := by decide +kernel

/-- **Idle sorts high, at the gates.** On an activity cycle (`phase` low, not
reset) with line 0 idle and line 1 active, the element swaps — so the active
packet leaves on `out0`. This is the concentration fixture the composed switch
needs, now discharged on the hardened convention-C netlist. -/
theorem ceC_rejects_idle_sorts_low :
    (ceCCases.filter (fun j => !j.testBit 0 && !j.testBit 1 && j.testBit 2
                                && !j.testBit 3 && !j.testBit 5)).all
      (fun j => (ceCRead ceCNL ceCNL_outs j).getD 0 false == true) = true := by
  decide +kernel

end SaltWorks.Silicon.Imported

section Audit
open Salt.Tactic
#audit_axioms SaltWorks.Silicon.Imported.ceC_gate_eq
  SaltWorks.Silicon.Imported.ceC_rejects_idle_sorts_low
end Audit
