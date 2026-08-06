/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Banyan
import SaltWorks.HDL.Seq

/-!
# Dense SSA form — the normal form `emitN` translates from

## Why this exists

`Circ` names its nets explicitly (`Gate.out`), which is what makes dead-net
elimination a `List.filter` with no renumbering. The netlist normal form the
silicon seat consumes is **positional**: net `k` is defined by the `k`-th gate.
Translating between the two is, in general, a renaming — and a renaming is the
expensive proof the refuter pass warned about (`R1-dce-renumber`).

**Dense SSA form makes that translation the identity.** A circuit is *dense* when
gate `i` defines net `nIn + i`. Then the explicit name of every net already
equals its positional index, `emitN` is a structure-preserving map with no
renaming at all, and `emitN_sem` is a short induction rather than a renaming
lemma.

Density is a `Bool`, so a concrete circuit discharges it by `decide +kernel`, and
it is a *precondition* rather than an assumption baked into the type — the same
extrinsic discipline as `Circ.wf`.

## Every construction in this leg is already dense

Not by luck: gates are emitted in the order they are allocated, and the
allocators (`element`, `stagesFrom`) hand out consecutive nets. The `decide`
blocks below pin that, so a future edit that breaks density fails the build
instead of failing `emitN` mysteriously later.
-/

namespace SaltWorks.HDL

/-- Gate `i` defines net `nIn + i`. -/
def Circ.dense (c : Circ) : Bool :=
  (List.range c.gates.length).all fun i => (c.gates.getD i default).out == c.nIn + i

/-- **Density, unpacked.** The positional index of a gate *is* the name of the
net it defines, so a positional netlist and this `Circ` agree on net identity
with no renaming. -/
theorem dense_out {c : Circ} (h : c.dense = true) (i : Nat) (hi : i < c.gates.length) :
    (c.gates.getD i default).out = c.nIn + i := by
  rw [Circ.dense, List.all_eq_true] at h
  have := h i (List.mem_range.mpr hi)
  simpa using this

/-! ## Every construction in this leg is dense — kernel-checked -/

theorem halfAdder_dense : halfAdder.dense = true := by decide +kernel
theorem withDead_dense : withDead.dense = true := by decide +kernel
theorem xorA_dense : xorA.dense = true := by decide +kernel
theorem xorB_dense : xorB.dense = true := by decide +kernel
theorem xorC_dense : xorC.dense = true := by decide +kernel
theorem xorPrevCore_dense : xorPrevCore.dense = true := by decide +kernel

/-- The 72-gate 8×8 fabric is dense — the one that matters, since it is the
tapeout candidate and the only construction here that allocates nets across
three composed stages. -/
theorem fabric3_dense : (fabric 3).dense = true := by decide +kernel

/-- `withDead` survives `opt` still dense — but only by accident: its dead gates
are the TRAILING ones, so removing them shifts nothing. I claimed this was a
counterexample and `decide` refuted it. -/
theorem opt_withDead_stays_dense : (opt withDead).dense = true := by decide +kernel

/-- Three gates, one output, and the dead gate is in the MIDDLE. -/
def withMidDead : Circ where
  nIn   := 2
  gates := [⟨2, .xor 0 1⟩, ⟨3, .and 0 1⟩, ⟨4, .not 2⟩]
  outs  := [4]

/-- ⚠️ **`opt` does NOT preserve density**, and this is the finding of the file.
Dead-net elimination filters gates out, so survivors keep their old NAMES while
their POSITIONS shift — exactly the renaming that naming-the-output-net was
chosen to avoid, reappearing at the emission boundary. Here gate 1 survives with
name 4 at position 1, where density demands 3.

Consequence for the pipeline: `emitN` must run **before** `opt`, or `opt` must be
followed by a densifying renumber. The former is free and is what this leg does;
the latter is the expensive proof. -/
theorem opt_breaks_density : (opt withMidDead).dense = false := by decide +kernel

/-- The trap is that nothing warns you: the optimized circuit is well-formed,
correct, and smaller. Density is an EMISSION precondition, not a health
property. -/
theorem withMidDead_opt_is_fine :
    (withMidDead.wf && (opt withMidDead).wf) = true ∧
      (opt withMidDead).gates.length < withMidDead.gates.length := by decide +kernel

#audit_axioms dense_out
#audit_axioms halfAdder_dense withDead_dense xorA_dense xorB_dense xorC_dense
#audit_axioms xorPrevCore_dense fabric3_dense
#audit_axioms opt_withDead_stays_dense opt_breaks_density withMidDead_opt_is_fine

end SaltWorks.HDL
