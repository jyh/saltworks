/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Opt

/-!
# T3 — the executable certificate suite, bit-sliced

## Why not enumeration

`docs/hdl-design-v1.md:22-24` scoped T3 as "concrete circuits evaluated by
`decide +kernel`" over "N≤16-bit input spaces per module", on a "measured law:
2^16 ≈ 12 s". The refuter pass killed the law and the architecture together: 12 s
is the cost of the *quantifier* over a bare `BitVec` identity, not of a circuit.
Measured on a real netlist, pointwise kernel evaluation runs at ~10^4
gate-evaluations per second, so a 12 s budget over 2^16 points buys **1.8 gates**.

**Bit-slicing** replaces it. Give every net its whole truth table as one `Nat` —
bit `j` of net `w` is `w`'s value under input configuration `j` — and the gates
become `Nat.land`/`lor`/`xor`, which are among the fifteen primitives the kernel
accelerates with GMP. There is then no enumeration at all: an `n`-gate module
costs `n` bignum operations rather than `n · 2^inputs` reductions.

This was derived independently by two lanes of this seat's refuter panel and by
the Silicon seat within the same hour (FLEET.md 09:31) — three derivations, one
answer.

## What is different here from the Silicon seat's copy

`SaltWorks/Silicon/Equiv/BitSliced.lean` carries the same idea for the *netlist*
normal form. This file carries it for `Circ`, and differs in two ways that came
out of the refuter pass:

* **Environments are functions, not lists.** Silicon's `Agree` needs
  `envS.length = envP.length` and their evaluators extend with `env ++ [·]`,
  which is O(g²). Here `runS` updates a function pointwise, so the reflection
  theorem below carries no length hypothesis and no quadratic cost.
* **Reflection is per-net**, so the corollary can compare *outputs only*. That is
  the repair the pass found necessary: comparing whole environments makes the
  hypothesis satisfiable essentially only for net-for-net identical circuits,
  which cannot state T5.

## The ceiling, and why it is a *safety* property

`Nat.pow` is kernel-accelerated only up to exponent `1 <<< 24`. A slice of width
`W = 2^n` needs the mask `2^W - 1`, so **`n = 24` input bits is the hard kernel
ceiling** — and at `n = 24` a single net is 2 MB, so a sliced certificate's
memory is bounded by roughly `2 MB × nets`. Pointwise `decide +kernel` has no
such bound: it materialises the reduction, and this seat drove a probe of under
60 lines to 30 GB that way. Bit-slicing is therefore not only ~10^3 times
faster, it is the memory-*bounded* route.
-/

namespace SaltWorks.HDL

/-! ## Sliced semantics -/

/-- A sliced valuation: each net carries its whole truth table as one `Nat`. -/
abbrev EnvS := Net → Nat

/-- One operation, sliced. `not` masks against `2^W - 1` because a `Nat` has
infinitely many zero bits above `W`. -/
def Op.evalS (W : Nat) (env : EnvS) : Op → Nat
  | .const b => if b then 2 ^ W - 1 else 0
  | .not a   => (2 ^ W - 1) ^^^ env a
  | .and a b => env a &&& env b
  | .or  a b => env a ||| env b
  | .xor a b => env a ^^^ env b

/-- Point update on a sliced valuation. -/
def updS (env : EnvS) (n : Net) (v : Nat) : EnvS := fun j => if j = n then v else env j

@[simp] theorem updS_self (env : EnvS) (n : Net) (v : Nat) : updS env n v n = v := by
  simp [updS]

theorem updS_of_ne {env : EnvS} {n m : Net} (v : Nat) (h : m ≠ n) : updS env n v m = env m := by
  simp [updS, h]

/-- Run a gate list sliced — every configuration at once, in one pass. -/
def runS (W : Nat) (env : EnvS) : List Gate → EnvS
  | []      => env
  | g :: gs => runS W (updS env g.out (g.op.evalS W env)) gs

@[simp] theorem runS_nil (W : Nat) (env : EnvS) : runS W env [] = env := rfl

@[simp] theorem runS_cons (W : Nat) (env : EnvS) (g : Gate) (gs : List Gate) :
    runS W env (g :: gs) = runS W (updS env g.out (g.op.evalS W env)) gs := rfl

/-! ## The bit lemmas -/

theorem testBit_mask {W j : Nat} (hj : j < W) : (2 ^ W - 1).testBit j = true := by
  rw [Nat.testBit_two_pow_sub_one, decide_eq_true hj]

theorem testBit_mask_xor {W j a : Nat} (hj : j < W) :
    ((2 ^ W - 1) ^^^ a).testBit j = !(a.testBit j) := by
  rw [Nat.testBit_xor, testBit_mask hj, Bool.true_xor]

/-- One operation, sliced then read at bit `j`, is that operation pointwise. -/
theorem evalS_testBit {W j : Nat} (hj : j < W) {envS : EnvS} {envP : Env}
    (h : ∀ n, (envS n).testBit j = envP n) (o : Op) :
    (o.evalS W envS).testBit j = o.eval envP := by
  cases o with
  | const b => cases b <;> simp [Op.evalS, Op.eval, testBit_mask hj]
  | not a   => rw [Op.evalS, Op.eval, testBit_mask_xor hj, h a]
  | and a b => rw [Op.evalS, Op.eval, Nat.testBit_and, h a, h b]
  | or  a b => rw [Op.evalS, Op.eval, Nat.testBit_or, h a, h b]
  | xor a b => rw [Op.evalS, Op.eval, Nat.testBit_xor, h a, h b]

/-! ## THE REFLECTION THEOREM

The stone this file exists for: sliced evaluation *is* pointwise evaluation, at
every configuration, for every circuit — proved once, generically, by induction
over the gate list. That genericity is why the seam carries **data** rather than
generated `def`s: a generated `def` cannot be inducted over, and would force a
fresh obligation per design, which is exactly the amortization the seam doctrine
tells us to buy. -/

/-- **Sliced evaluation reflects pointwise evaluation, net by net.**

No length hypothesis, because environments are functions. -/
theorem reflect {W j : Nat} (hj : j < W) :
    ∀ (gs : List Gate) {envS : EnvS} {envP : Env},
      (∀ n, (envS n).testBit j = envP n) →
      ∀ n, (runS W envS gs n).testBit j = run envP gs n := by
  intro gs
  induction gs with
  | nil => intro _ _ h n; exact h n
  | cons g gs ih =>
    intro envS envP h n
    refine ih (fun m => ?_) n
    by_cases hm : m = g.out
    · subst hm; rw [updS_self, upd_self]; exact evalS_testBit hj h g.op
    · rw [updS_of_ne _ hm, upd_of_ne _ hm]; exact h m

/-- **The corollary the certificates use: OUTPUTS ONLY.**

Two circuits with the same port list whose sliced *output* nets agree compute the
same function at every configuration. Comparing whole environments instead — the
shape the first landed version of the seam used — is satisfiable essentially only
for net-for-net identical circuits, and so cannot state T5. -/
theorem eq_of_slicedOuts_eq {W : Nat} {c d : Circ} {envS : EnvS} {insP : Nat → Env}
    (hcols : ∀ j, j < W → ∀ n, (envS n).testBit j = insP j n)
    (h : c.outs.map (runS W envS c.gates) = d.outs.map (runS W envS d.gates)) :
    ∀ j, j < W → sem c (insP j) = sem d (insP j) := by
  intro j hj
  have hc := reflect hj c.gates (hcols j hj)
  have hd := reflect hj d.gates (hcols j hj)
  have : (c.outs.map (runS W envS c.gates)).map (fun w => w.testBit j)
       = (d.outs.map (runS W envS d.gates)).map (fun w => w.testBit j) := by rw [h]
  simpa [sem, List.map_map, Function.comp_def, hc, hd] using this

/-! ## T5 — the fungibility exhibit

One spec, three deliberately different implementations, each certified against
the SAME spec. The refuter pass insisted this be checkable rather than asserted,
so the gate counts are proved too: three implementations that were the same
implementation renamed would have the same count. -/

/-- The columns for a 2-input circuit: 4 configurations. Bit `j` of column `i` is
bit `i` of `j`. -/
def cols2 : EnvS := fun i => if i = 0 then 10 else if i = 1 then 12 else 0

theorem cols2_spec : ∀ j, j < 4 → ∀ i, i < 2 → (cols2 i).testBit j = (j.testBit i) := by
  decide +kernel

/-- XOR, implementation A: the primitive. -/
def xorA : Circ := { nIn := 2, gates := [⟨2, .xor 0 1⟩], outs := [2] }

/-- XOR, implementation B: `(a ∨ b) ∧ ¬(a ∧ b)`. -/
def xorB : Circ :=
  { nIn := 2
    gates := [⟨2, .or 0 1⟩, ⟨3, .and 0 1⟩, ⟨4, .not 3⟩, ⟨5, .and 2 4⟩]
    outs  := [5] }

/-- XOR, implementation C: `(a ∧ ¬b) ∨ (¬a ∧ b)`. -/
def xorC : Circ :=
  { nIn := 2
    gates := [⟨2, .not 0⟩, ⟨3, .not 1⟩, ⟨4, .and 0 3⟩, ⟨5, .and 2 1⟩, ⟨6, .or 4 5⟩]
    outs  := [6] }

/-- All three are well-formed. -/
theorem fungible_wf : xorA.wf && xorB.wf && xorC.wf = true := by decide +kernel

/-- **They are deliberately different**, and the gate counts prove it rather than
asserting it: 1, 4 and 5 gates for the same Boolean function. -/
theorem fungible_distinct :
    (xorA.gates.length, xorB.gates.length, xorC.gates.length) = (1, 4, 5) := by
  decide +kernel

/-- **T5, bit-sliced.** All three agree with the spec on every configuration —
one sliced `Nat` comparison per implementation, no enumeration. -/
theorem fungible_AB : xorA.outs.map (runS 4 cols2 xorA.gates)
    = xorB.outs.map (runS 4 cols2 xorB.gates) := by decide +kernel

theorem fungible_AC : xorA.outs.map (runS 4 cols2 xorA.gates)
    = xorC.outs.map (runS 4 cols2 xorC.gates) := by decide +kernel

/-- The sliced value is the XOR truth table `0b0110 = 6`, so the certificate is
pinned to a stated function rather than merely to agreement between the three. -/
theorem fungible_is_xor : xorA.outs.map (runS 4 cols2 xorA.gates) = [6] := by decide +kernel

/-- A MUTATION CONTROL. Replacing the `xor` with an `or` must break the
certificate — otherwise the certificate is vacuous and proves nothing about the
circuit. This is the check the refuter pass found missing from the design. -/
def xorMutant : Circ := { nIn := 2, gates := [⟨2, .or 0 1⟩], outs := [2] }

theorem mutation_detected :
    xorMutant.outs.map (runS 4 cols2 xorMutant.gates)
      ≠ xorA.outs.map (runS 4 cols2 xorA.gates) := by decide +kernel

#audit_axioms updS_self updS_of_ne testBit_mask testBit_mask_xor evalS_testBit
#audit_axioms reflect eq_of_slicedOuts_eq
#audit_axioms cols2_spec fungible_wf fungible_distinct
#audit_axioms fungible_AB fungible_AC fungible_is_xor mutation_detected

end SaltWorks.HDL
