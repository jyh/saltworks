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

/-! ## THE OPERATING RANGE — compiler's 14:43 question, answered as Lean

Compiler asked whether `composed_switch_of_seam` covers the tile's **operating
range** or only its **full-load case**, and named the two candidate readings:
(i) every line active with a distinct destination, or (ii) idle lines carrying a
distinct sentinel inside `v`.

⭐ **The answer is (i), and it is FORCED rather than chosen.** At the fabricated
fabric's `k = 3` the two hypotheses are not independent knobs: `hlt` puts the
eight values in `Iio 8` and `hi` makes them distinct, so pigeonhole makes `v` a
**bijection** onto `Iio 8` — `seam_hyps_force_full_load` below. Reading (ii)
needs a value `≥ 8`, hence `k ≥ 4`, hence a **16-line banyan** — which is not the
fabric that was fabricated.

⛔ **And partial load is not merely uncovered: with a shared idle code the
conclusion is FALSE**, which is the second pair below. That is the tile's real
operating case and not a hypothetical — `bnCSparse` (`HDL/BatcherNetC.lean:216`)
gives its five idle lines the **byte-identical** frame
`cFrame false 0 [false, false, false]`, so no injective `v` represents it.

📌 **Consequence for compiler's obligation (a), which this seat caused them to
withdraw.** The product order `(¬active, dest)` does **not** disappear — it
*degenerates*. At full load every activity bit is 1, so `bothAct` holds at every
element and convention C's order collapses to plain `≤` on the destination,
which is exactly what `runNet batcher8` sorts by. **Full load is precisely the
regime where the two orders coincide**, which is why the seam is dischargeable
there and nowhere else yet. The product order returns the moment an idle line is
in scope, and partial load wants its own statement carrying it. -/

/-- ⭐ **AT THE FABRICATED FABRIC'S `k = 3`, THE HYPOTHESES FORCE FULL LOAD.**
Eight distinct values below eight exhaust `Iio 8`, so every output line is
claimed by some input line. There is no room for an idle sentinel, and therefore
no choice was made: the statement's range is fixed by arithmetic. -/
theorem seam_hyps_force_full_load {v : Fin 8 → ℕ}
    (hi : Function.Injective v) (hlt : ∀ i, v i < 8) {j : ℕ} (hj : j < 8) :
    ∃ i, v i = j := by
  have hf : Function.Injective (fun i : Fin 8 => (⟨v i, hlt i⟩ : Fin 8)) := by
    intro a b hab
    exact hi (by simpa using hab)
  obtain ⟨i, hi'⟩ := Finite.injective_iff_surjective.mp hf ⟨j, hj⟩
  exact ⟨i, congrArg Fin.val hi'⟩

/-- ⛔ **TWO WIRES SHARING ONE CODE REFUTE THE NO-CONFLICT CONJUNCT.** At `m = 0`
the line function is the destination itself, so two wires carrying equal codes
occupy one line. **Partial load with a shared idle code is not outside the
theorem's reach by omission — the conclusion is false there.** -/
theorem repeated_code_refutes_no_conflict {k : ℕ} {hw : Fin 8 → ℕ} {a b : Fin 8}
    (hab : a ≠ b) (heq : hw a = hw b) :
    ¬ (∀ m ≤ k, Set.InjOn (fun s => Banyan.line m s (extendIio 0 hw s)) (Set.Iio 8)) := by
  intro h
  have hval : (a : ℕ) = (b : ℕ) :=
    h 0 (Nat.zero_le k) (Set.mem_Iio.2 a.isLt) (Set.mem_Iio.2 b.isLt) (by
      simp only [Banyan.line_zero]
      rw [extendIio_apply _ _ a.isLt, extendIio_apply _ _ b.isLt]
      simpa using heq)
  exact hab (Fin.val_injective hval)

/-- ⛔ **THE SAME, ON THE INPUT SIDE — where the frame actually decides it.** The
sorter permutes, so a code shared by two *input* lines is still shared by two
*output* wires. This is the form that bites on `bnCSparse`: its five idle frames
are identical, so `composed_switch_of_seam` cannot be instantiated at it, and the
conclusion it would have delivered is refuted outright. -/
theorem repeated_input_code_refutes_no_conflict {k : ℕ} {v : Fin 8 → ℕ} {a b : Fin 8}
    (hab : a ≠ b) (heq : v a = v b) :
    ¬ (∀ m ≤ k, Set.InjOn
        (fun s => Banyan.line m s (extendIio 0 (runNet batcher8 v) s)) (Set.Iio 8)) := by
  obtain ⟨σ, hσ⟩ := runNet_perm batcher8 v
  refine repeated_code_refutes_no_conflict (a := σ.symm a) (b := σ.symm b) ?_ ?_
  · intro h
    exact hab (by simpa using congrArg σ h)
  · rw [hσ]
    simp [heq]

/-- ⭐ **THE FABRICATED FABRIC'S OWN CASE — `k = 3`, the seam, and nothing else.**
This is the exact shape link ② should aim at: no `k`, no `hn`, and the address
bound in the form the 3-bit frame states it. -/
theorem composed_switch_of_seam_k3 {v hw : Fin 8 → ℕ}
    (hi : Function.Injective v) (hlt : ∀ i, v i < 8)
    (hseam : hw = runNet batcher8 v) :
    (∀ m ≤ 3, Set.InjOn (fun s => Banyan.line m s (extendIio 0 hw s)) (Set.Iio 8)) ∧
      (∀ s < 8, Banyan.line 3 s (extendIio 0 hw s) = s) ∧
      (∀ s, Banyan.line 0 s (extendIio 0 hw s) = extendIio 0 hw s) :=
  composed_switch_of_seam (by norm_num) hi (by simpa using hlt) hseam

end SaltWorks.Silicon

section Audit
open Salt.Tactic
#audit_axioms SaltWorks.Silicon.composed_switch_of_seam
  SaltWorks.Silicon.composed_switch_of_seam_nodup
#audit_axioms SaltWorks.Silicon.seam_hyps_force_full_load
  SaltWorks.Silicon.composed_switch_of_seam_k3
#audit_axioms SaltWorks.Silicon.repeated_code_refutes_no_conflict
  SaltWorks.Silicon.repeated_input_code_refutes_no_conflict
end Audit
