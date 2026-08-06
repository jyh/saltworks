/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Sem

/-!
# `opt` — the verified optimizer, and T1

This is the campaign's **spectrum-point 1**: the amortized end of the seam
doctrine. `opt_sem` is proved once, for every circuit, and then runs on every
circuit forever — as against the per-instance certificates of T3/T5, which are
re-earned for each artifact.

## The shape of the theorem, and why it is unconditional

`opt` is a **validated** optimizer. Dead-net elimination needs its liveness
analysis to be closed under fanin; rather than *prove* the analysis correct, `opt`
CHECKS the property it needs (`keepClosedB`, a `Bool`) and falls back to the
identity when the check fails. So:

    dce_sem : sem (dce c) = sem c

holds for **every** `c`, with no well-formedness hypothesis and no assumption
about the analysis. A bug in `liveOf` can cost optimization; it cannot cost
correctness. This is translation validation applied inside the compiler, and it
is the same move the campaign makes at the silicon seam one level down.

## Why dead-net elimination is not a nicety here

Yosys deletes what a design does not use. If `emitV` emits gates that the
synthesized netlist does not contain, the two sides of the leg-3 equivalence
disagree structurally before any proof begins. DCE is what keeps the emitted
Verilog and the imported netlist talking about the same circuit.
-/

namespace SaltWorks.HDL

/-! ## Liveness -/

/-- `keep` is closed under fanin: everything a kept gate reads is itself kept. -/
def KeepClosed (keep : Net → Bool) (gs : List Gate) : Prop :=
  ∀ g ∈ gs, keep g.out = true → ∀ n ∈ g.op.fanin, keep n = true

/-- The decidable check. -/
def keepClosedB (keep : Net → Bool) (gs : List Gate) : Bool :=
  gs.all (fun g => !keep g.out || g.op.fanin.all keep)

theorem keepClosedB_sound {keep : Net → Bool} {gs : List Gate}
    (h : keepClosedB keep gs = true) : KeepClosed keep gs := by
  intro g hg hk n hn
  rw [keepClosedB, List.all_eq_true] at h
  have hg' := h g hg
  rw [hk] at hg'
  simp only [Bool.not_true, Bool.false_or, List.all_eq_true] at hg'
  exact hg' n hn

/-- **The frame theorem for filtering.** If `keep` is closed under fanin, then
running only the kept gates computes, at every kept net, what running all the
gates computes — provided the two starting environments agree on kept nets.

This is the lemma that naming the output net buys: no renumbering, no
index-shifting, and no well-formedness hypothesis. -/
theorem run_filter {keep : Net → Bool} {gs : List Gate} (hc : KeepClosed keep gs)
    {env₁ env₂ : Env} (hag : ∀ n, keep n = true → env₁ n = env₂ n) :
    ∀ n, keep n = true → run env₁ (gs.filter (fun g => keep g.out)) n = run env₂ gs n := by
  induction gs generalizing env₁ env₂ with
  | nil => intro n hn; exact hag n hn
  | cons g gs ih =>
    intro n hn
    have hc' : KeepClosed keep gs := fun g' hg' => hc g' (by simp [hg'])
    by_cases hk : keep g.out = true
    · -- the gate is kept: both sides run it, and its operands are kept, so it
      -- evaluates the same on both sides
      have hfil : (g :: gs).filter (fun g => keep g.out)
          = g :: gs.filter (fun g => keep g.out) := by simp [hk]
      rw [hfil, run_cons, run_cons]
      refine ih hc' (fun m hm => ?_) n hn
      by_cases hmo : m = g.out
      · subst hmo
        rw [upd_self, upd_self]
        exact Op.eval_congr g.op
          (fun x hx => hag x (hc g (by simp) hk x hx))
      · rw [upd_of_ne _ hmo, upd_of_ne _ hmo]; exact hag m hm
    · -- the gate is dropped: it writes an unkept net, so no kept net moves
      have hk' : keep g.out = false := by simpa using hk
      have hfil : (g :: gs).filter (fun g => keep g.out)
          = gs.filter (fun g => keep g.out) := by simp [hk']
      rw [hfil, run_cons]
      refine ih hc' (fun m hm => ?_) n hn
      have hne : m ≠ g.out := fun hEq => by rw [hEq, hk'] at hm; exact Bool.noConfusion hm
      rw [upd_of_ne _ hne]; exact hag m hm

/-! ## The analysis

A single backward sweep. Under well-formedness a gate reads only nets defined
earlier, so one reverse pass reaches a fixpoint — but `opt` does not *rely* on
that, it checks it. -/

/-- Add a gate's operands to the live set when the gate's output is live. The
append is of a ≤2-element list onto the accumulator, so it is O(1), not the
O(n) append-extension the refuter pass ruled out. -/
def liveStep (acc : List Net) (g : Gate) : List Net :=
  if acc.contains g.out then g.op.fanin ++ acc else acc

/-- Live nets, by one backward sweep from the primary outputs. -/
def liveOf (gs : List Gate) (outs : List Net) : List Net :=
  gs.reverse.foldl liveStep outs

/-- **Dead-net elimination**, validated: optimize only when the computed live set
is genuinely closed under fanin and genuinely covers the outputs. -/
def dce (c : Circ) : Circ :=
  let keep := fun n => (liveOf c.gates c.outs).contains n
  if keepClosedB keep c.gates && c.outs.all keep then
    { c with gates := c.gates.filter (fun g => keep g.out) }
  else c

/-- The optimizer. Currently dead-net elimination; constant folding composes
here, and composition preserves T1 by transitivity. -/
def opt (c : Circ) : Circ := dce c

/-! ## T1 -/

/-- **T1 — `opt` preserves meaning.** Unconditional: no well-formedness
hypothesis, no assumption that the liveness analysis is correct. -/
theorem opt_sem (c : Circ) : sem (opt c) = sem c := by
  funext ins
  rw [opt, dce]
  split
  · next h =>
    rw [Bool.and_eq_true] at h
    obtain ⟨hclosed, houts⟩ := h
    rw [sem, sem]
    refine List.map_congr_left (fun n hn => ?_)
    exact run_filter (keepClosedB_sound hclosed) (fun _ _ => rfl) n
      (List.all_eq_true.mp houts n hn)
  · rfl

/-! ## The non-triviality exhibit

T1 is satisfied by `opt = id`, so the theorem alone is not a deliverable. What
makes it one is a kernel-checked witness that `opt` actually fires and actually
shrinks something — the refuter pass named this as a missing obligation on
T1, T2 and T5 alike. -/

/-- Three gates, one output. Net 4 is dead, and net 3 is dead only because net 4
is — so a single-pass analysis has to propagate. -/
def withDead : Circ where
  nIn   := 2
  gates := [⟨2, .xor 0 1⟩, ⟨3, .and 0 1⟩, ⟨4, .or 2 3⟩]
  outs  := [2]

/-- `opt` fires here: three gates in, one gate out. -/
theorem opt_fires : withDead.gates.length = 3 ∧ (opt withDead).gates.length = 1 := by
  decide +kernel

/-- …and the surviving circuit still computes what it should, over its whole
input space. Meaning preserved *and* work removed — the two halves of a real
optimizer, both kernel-checked. -/
theorem opt_withDead_correct :
    [0, 1, 2, 3].all (fun j =>
      sem (opt withDead) (bitsOf j) == [(j.testBit 0) ^^ (j.testBit 1)]) = true := by
  decide +kernel

/-- The optimized circuit is still well-formed. -/
theorem opt_withDead_wf : (opt withDead).wf = true := by decide +kernel

#audit_axioms keepClosedB_sound run_filter
#audit_axioms opt_sem
#audit_axioms opt_fires opt_withDead_correct opt_withDead_wf

end SaltWorks.HDL
