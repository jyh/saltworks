/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Silicon.Equiv.BitSliced
import SaltWorks.Silicon.Equiv.Columns
import SaltWorks.Silicon.Imported.Comparator
import SaltWorks.Silicon.Imported.RefComparator
import SaltWorks.Tactic.AuditAxioms

/-!
# D3 — the comparator, end to end, kernel-checked

**The claim this file makes:** the gate netlist that came back from `yosys` +
`abc` against the sky130 standard-cell library computes *exactly* the same
function as the design, on **all 65,536 input configurations** — checked by the
Lean kernel, with no `bv_decide`, no `native_decide`, and no `sorry`.

## What is being compared

* `comparatorNL` — **imported** from `SaltWorks/Silicon/Flow/comparator_nl.v`,
  the real synthesis output: 36 sky130 cells over 12 distinct cell types
  (including two `lpflow` power-isolation cells that `abc` pressed into service
  as ordinary logic), expanded to 127 primitive gates.
* `refComparator` — the **design**: a ripple magnitude compare from the LSB
  followed by two multiplexers, 109 gates. Deliberately a *different structure*,
  so this is a real equivalence and not a syntactic identity.

Same function, two structures, one kernel-checked equality.

## How it is affordable

Naively this is 2^16 evaluations of a 127-gate netlist. Instead every net carries
its **whole truth table** as one `Nat` (`runS`), so each netlist is evaluated
**once** — 127 GMP operations on 65,536-bit numbers — and the comparison is a
single list-of-`Nat` equality.

`reflect` (proved once, generically, in `Equiv/BitSliced.lean`) is what makes
that a statement about pointwise behaviour rather than merely a fast
computation, and `col_testBit` (`Equiv/Columns.lean`) discharges its only
hypothesis. Nothing here is taken on faith.

## What this does NOT claim

It does not say the netlist computes *min and max*. It says the netlist computes
what the **design** computes. That the design computes min/max is a separate,
structural obligation — and keeping the two apart is the point: synthesis is
checked per-instance, arithmetic meaning is proved once.

It also does not cover the flow beyond synthesis. The equivalence target for
tapeout is TinyTapeout CI's `tt_submission/<top>.v` (see
`SaltWorks/Silicon/Flow-docs/hardware-versions.md`); this is the same machinery
pointed at a local run.
-/

namespace SaltWorks.Silicon.Imported

open SaltWorks.Silicon

/-- 16 primary inputs ⇒ 2^16 configurations ⇒ a 65,536-bit slice. -/
abbrev W : Nat := 2 ^ 16

/-- The input columns, from the proved construction. -/
abbrev cols : Nat → Nat := col 16

/-- Read a run's outputs at the given net indices. -/
def outsOf (run : List Nat) (idx : List Nat) : List Nat :=
  idx.map (fun k => run.getD k 0)

/-- **The certificate.** One `Nat`-list equality, decided by pure kernel
reduction, covering all 65,536 input configurations at once. -/
theorem comparator_sliced_eq :
    outsOf (runS W cols [] comparatorNL) comparatorNL_outs
      = outsOf (runS W cols [] refComparator) refComparator_outs := by
  decide +kernel

/-- Every input column has its defining property — including the indices above
the design's input count, where the column is zero and so is the bit. -/
theorem cols_agree (j : Nat) (hj : j < W) : ∀ i, (cols i).testBit j = j.testBit i := by
  intro i
  by_cases h : i < 16
  · exact col_testBit 16 i j h hj
  · have h0 : cols i = 0 := col_of_le 16 i (by omega)
    have hjt : j.testBit i = false :=
      Nat.testBit_lt_two_pow (lt_of_lt_of_le hj (Nat.pow_le_pow_right (by norm_num) (by omega)))
    simp [h0, hjt]

/-- **D3.** The synthesized netlist and the design agree at **every** one of the
65,536 input configurations, on every output bit.

This is the statement a skeptic should read: fix any configuration `j`; evaluate
the imported gate netlist pointwise, evaluate the design pointwise, read off the
16 outputs of each — they are equal. -/
theorem comparator_equiv (j : Nat) (hj : j < W) :
    comparatorNL_outs.map
        (fun k => (runP (fun i => j.testBit i) [] comparatorNL).getD k false)
      = refComparator_outs.map
        (fun k => (runP (fun i => j.testBit i) [] refComparator).getD k false) := by
  have hcols := cols_agree j hj
  have hg := reflect hj hcols comparatorNL (agree_nil j)
  have hr := reflect hj hcols refComparator (agree_nil j)
  have e1 : ∀ k, (runP (fun i => j.testBit i) [] comparatorNL).getD k false
      = ((runS W cols [] comparatorNL).getD k 0).testBit j := fun k => (hg.2 k).symm
  have e2 : ∀ k, (runP (fun i => j.testBit i) [] refComparator).getD k false
      = ((runS W cols [] refComparator).getD k 0).testBit j := fun k => (hr.2 k).symm
  simp only [e1, e2]
  have : ∀ (r : List Nat) (idx : List Nat),
      idx.map (fun k => (r.getD k 0).testBit j)
        = (outsOf r idx).map (fun c => c.testBit j) := by
    intro r idx; simp [outsOf, List.map_map, Function.comp]
  rw [this, this, comparator_sliced_eq]

#audit_axioms comparator_sliced_eq comparator_equiv cols_agree

end SaltWorks.Silicon.Imported
