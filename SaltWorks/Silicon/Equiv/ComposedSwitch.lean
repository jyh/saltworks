/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Stack.Bridge

/-!
# BB-1 — THE COMPOSED SWITCH, stated against the one seam compiler owes

The composed claim needs three links (bus, 14:31). Two are compiler's and one
was math's; **math's landed** as `batcher8_banyan_selfrouting`. This file states
the composed theorem **conditionally on the single remaining seam**, so that the
seam's required SHAPE is not a description on a bus line but a Lean hypothesis
compiler can discharge and delete.

⚠️ **Why this can live here.** `SaltWorks.Stack` does **not** import
`SaltWorks.Silicon`, so importing Stack from Silicon does not cycle — unlike
`SaltWorks.HDL`, which does import Silicon (`emitN : Circ → Silicon.Netlist`) and
therefore cannot be imported back. **That asymmetry is why link ① must live in
HDL and this may live here.**

## What silicon has banked underneath this

* the convention-C element **refined at the gates** — `ceC_gate_eq`, all 128
  configurations, no reachability assumption (`CERefinementC.lean`);
* `ceC_rejects_idle_sorts_low` — idle never wins the low port, on the hardened
  netlist: the **concentration** fixture;
* the network **hardened and re-imported** — 576 cells, live-cell survival
  100.00 %, readback against vendor Liberty;
* the **decomposition**: 28 cut points, every cone ≤ 24, median 5.
-/

namespace SaltWorks.Silicon

open SaltWorks.Stack

/-- ⭐ **THE COMPOSED SWITCH, modulo one seam.**

`hw` is what the fabricated sorter computes on a vector of destinations. Given
**exactly one fact** — that `hw` agrees with `runNet batcher8`, which is link ②
and is compiler's to supply — the banyan routes it without a single internal
conflict, every source reaching the line its address names.

The conclusion is `banyan_selfrouting`'s three conjuncts verbatim, through math's
`batcher8_banyan_selfrouting`: **sortedness is discharged by the hardware**, and
the caller is left owing only injectivity and the address bound. -/
theorem composed_switch_of_seam {k : ℕ} (hn : 8 ≤ 2 ^ k) {v hw : Fin 8 → ℕ}
    (hi : Function.Injective v) (hlt : ∀ i, v i < 2 ^ k)
    (hseam : hw = runNet batcher8 v) :
    (∀ m ≤ k,
        Set.InjOn (fun s => Banyan.line m s (extendIio 0 hw s)) (Set.Iio 8)) ∧
      (∀ s < 8, Banyan.line k s (extendIio 0 hw s) = s) ∧
      (∀ s, Banyan.line 0 s (extendIio 0 hw s) = extendIio 0 hw s) := by
  subst hseam
  exact batcher8_banyan_selfrouting hn hi hlt

/-- The `Nodup` entry point, for a caller holding the list-side distinctness
statement rather than `Function.Injective` — the shape BB-1's `KB3` names. -/
theorem composed_switch_of_seam_nodup {k : ℕ} (hn : 8 ≤ 2 ^ k) {v hw : Fin 8 → ℕ}
    (hi : (List.ofFn v).Nodup) (hlt : ∀ i, v i < 2 ^ k)
    (hseam : hw = runNet batcher8 v) :
    (∀ m ≤ k,
        Set.InjOn (fun s => Banyan.line m s (extendIio 0 hw s)) (Set.Iio 8)) ∧
      (∀ s < 8, Banyan.line k s (extendIio 0 hw s) = s) ∧
      (∀ s, Banyan.line 0 s (extendIio 0 hw s) = extendIio 0 hw s) :=
  composed_switch_of_seam hn (List.nodup_ofFn.mp hi) hlt hseam

end SaltWorks.Silicon

section Audit
open Salt.Tactic
#audit_axioms SaltWorks.Silicon.composed_switch_of_seam
  SaltWorks.Silicon.composed_switch_of_seam_nodup
end Audit
