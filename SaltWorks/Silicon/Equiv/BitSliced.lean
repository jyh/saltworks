/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Tactic.AuditAxioms

/-!
# Bit-sliced netlist evaluation, and the reflection theorem that justifies it

## The problem this solves

Leg 3's obligation is: the gate netlist that came back from synthesis computes
the same function as the design we proved things about. The shipped decision
procedure is `decide +kernel` — `bv_decide` is banned from shipped proofs because
it emits a per-theorem native axiom.

The freeze priced this using a "2^16 ≈ 6 min" law borrowed from the routing
certificates. That law does not transfer: it was measured on **ℕ** arithmetic,
which the Lean kernel accelerates with GMP, and a gate netlist is **Bool**, where
every gate is a genuine iota-reduction paid once per input configuration. See
`docs/silicon-refuter-0806.md` §3.

## The idea

Evaluate every net **once**, carrying its entire truth table as a single natural
number: bit `j` of net `w` is `w`'s value under input configuration `j`. Then

* `and`/`or`/`xor`/`not` become `Nat.land`/`lor`/`xor` on big numbers — *exactly*
  the kernel-accelerated primitives, and
* there is **no enumeration at all**. An `n`-gate module costs `n` bignum
  operations rather than `n · 2^inputs` reductions.

Measured: 24 input bits (16,777,216 configurations), 60 gates, exhaustive,
kernel-checked, axiom-clean, in seconds.

## Why the theorem below is the point

Speed is worthless if the fast object is not the object we care about.
`reflect` is what makes a sliced computation a statement about pointwise
behaviour: it says the two evaluators agree bit-for-bit, for any netlist. It is
proved **once, generically, by induction over the gate list** — which is the
reason the importer emits *data* rather than generated code. Generated `def`s
cannot be inducted over, and would force a fresh obligation per design.

Deliberately, `reflect` does **not** know how input columns are built: it takes
their defining property as a hypothesis (`hinp`). That keeps the theorem
independent of the column construction, which is a separate obligation.
-/

namespace SaltWorks.Silicon

open Salt.Tactic

/-! ## The netlist -/

/-- A gate in a flat, structural netlist. Operands are **indices into the net
environment** — a netlist is a straight-line program, which is exactly what
post-synthesis Verilog is.

The sky130 cells are not primitives here: the importer expands each cell into
these via its model in `SaltWorks.Silicon.Cells`, so this type stays small and
the induction below stays short. -/
inductive Gate where
  | inp   (i : Nat)
  | const (b : Bool)
  | not   (a : Nat)
  | and   (a b : Nat)
  | or    (a b : Nat)
  | xor   (a b : Nat)
  deriving Repr, DecidableEq

/-- A netlist: net `k` is defined by the `k`-th gate. -/
abbrev Netlist := List Gate

/-! ## Pointwise semantics — the meaning we care about -/

/-- One gate, on Bool nets. -/
def stepP (ins : Nat → Bool) (env : List Bool) : Gate → Bool
  | .inp i    => ins i
  | .const b  => b
  | .not a    => !(env.getD a false)
  | .and a b  => (env.getD a false) && (env.getD b false)
  | .or  a b  => (env.getD a false) || (env.getD b false)
  | .xor a b  => (env.getD a false) ^^ (env.getD b false)

/-- Run a netlist pointwise, under one input configuration. -/
def runP (ins : Nat → Bool) (env : List Bool) : Netlist → List Bool
  | []      => env
  | g :: gs => runP ins (env ++ [stepP ins env g]) gs

/-! ## Sliced semantics — the meaning we can afford

A net is a `Nat` whose bit `j` is the net's value under configuration `j`.
`W` is the slice width (the number of configurations); `not` must mask against
`2^W - 1`, since a `Nat` has infinitely many zero bits above `W`. -/

/-- One gate, on sliced ℕ nets. -/
def stepS (W : Nat) (cols : Nat → Nat) (env : List Nat) : Gate → Nat
  | .inp i    => cols i
  | .const b  => if b then 2 ^ W - 1 else 0
  | .not a    => (2 ^ W - 1) ^^^ (env.getD a 0)
  | .and a b  => (env.getD a 0) &&& (env.getD b 0)
  | .or  a b  => (env.getD a 0) ||| (env.getD b 0)
  | .xor a b  => (env.getD a 0) ^^^ (env.getD b 0)

/-- Run a netlist sliced — every configuration at once, in one pass. -/
def runS (W : Nat) (cols : Nat → Nat) (env : List Nat) : Netlist → List Nat
  | []      => env
  | g :: gs => runS W cols (env ++ [stepS W cols env g]) gs

/-! ## The relation between them -/

/-- Sliced environment `envS` agrees with pointwise environment `envP` at
configuration `j`. -/
def Agree (j : Nat) (envS : List Nat) (envP : List Bool) : Prop :=
  envS.length = envP.length ∧
    ∀ k, (envS.getD k 0).testBit j = envP.getD k false

theorem agree_nil (j : Nat) : Agree j [] [] := by
  refine ⟨rfl, fun k => ?_⟩
  simp [List.getD]

/-- Reading past a one-element extension: at the new index you get the new
element, everywhere else the original list answers — including out of range,
where both sides give the default. One lemma instead of a three-way case split,
and core-only, which is what keeps this module free of Mathlib. -/
private theorem getD_snoc {α : Type _} (l : List α) (x d : α) :
    ∀ k, (l ++ [x]).getD k d = if k = l.length then x else l.getD k d := by
  induction l with
  | nil => intro k; cases k <;> simp
  | cons a t ih =>
    intro k
    cases k with
    | zero => simp
    | succ m => simpa using ih m

/-- Appending one agreeing net preserves agreement. -/
theorem agree_snoc {j : Nat} {envS envP} (h : Agree j envS envP)
    {x : Nat} {b : Bool} (hx : x.testBit j = b) :
    Agree j (envS ++ [x]) (envP ++ [b]) := by
  obtain ⟨hlen, hget⟩ := h
  refine ⟨by simp [hlen], fun k => ?_⟩
  rw [getD_snoc, getD_snoc]
  by_cases hk : k = envS.length
  · have hk' : k = envP.length := by omega
    rw [if_pos hk, if_pos hk', hx]
  · have hk' : ¬ k = envP.length := by omega
    rw [if_neg hk, if_neg hk']
    exact hget k

/-! ## The bit lemmas

`testBit` distributes over the bitwise operations; the only subtlety is `not`,
which needs the mask to be all-ones below `W`. -/

theorem testBit_mask_xor {W j a : Nat} (hj : j < W) :
    ((2 ^ W - 1) ^^^ a).testBit j = !(a.testBit j) := by
  rw [Nat.testBit_xor, Nat.testBit_two_pow_sub_one, decide_eq_true hj, Bool.true_xor]

theorem testBit_mask {W j : Nat} (hj : j < W) : (2 ^ W - 1).testBit j = true := by
  rw [Nat.testBit_two_pow_sub_one, decide_eq_true hj]

/-- One gate, evaluated sliced then read at bit `j`, equals the same gate
evaluated pointwise at configuration `j`. -/
theorem stepS_testBit {W j : Nat} (hj : j < W) {cols : Nat → Nat} {ins : Nat → Bool}
    (hinp : ∀ i, (cols i).testBit j = ins i)
    {envS envP} (h : Agree j envS envP) (g : Gate) :
    (stepS W cols envS g).testBit j = stepP ins envP g := by
  obtain ⟨_, hget⟩ := h
  cases g with
  | inp i    => exact hinp i
  | const b  => cases b <;> simp [stepS, stepP, testBit_mask hj]
  | not a    => rw [stepS, stepP, testBit_mask_xor hj, hget a]
  | and a b  => rw [stepS, stepP, Nat.testBit_and, hget a, hget b]
  | or  a b  => rw [stepS, stepP, Nat.testBit_or, hget a, hget b]
  | xor a b  => rw [stepS, stepP, Nat.testBit_xor, hget a, hget b]

/-! ## THE REFLECTION THEOREM -/

/-- **Sliced evaluation is pointwise evaluation, at every configuration.**

For any netlist, at any configuration `j < W`, reading bit `j` out of the sliced
run gives exactly the pointwise run under the inputs that configuration
describes.

The hypothesis `hinp` is the *only* thing assumed about the input columns, so
this theorem is independent of how they are constructed. -/
theorem reflect {W j : Nat} (hj : j < W) {cols : Nat → Nat} {ins : Nat → Bool}
    (hinp : ∀ i, (cols i).testBit j = ins i) :
    ∀ (gs : Netlist) {envS envP}, Agree j envS envP →
      Agree j (runS W cols envS gs) (runP ins envP gs) := by
  intro gs
  induction gs with
  | nil => intro envS envP h; exact h
  | cons g gs ih =>
    intro envS envP h
    exact ih (agree_snoc h (stepS_testBit hj hinp h g))

/-- The form the equivalence proofs actually use: if two netlists have equal
**sliced** runs, they agree pointwise at every configuration — so a single ℕ
equality, decided once by the kernel, certifies the whole input space. -/
theorem eq_of_sliced_eq {W : Nat} {cols : Nat → Nat}
    (hcols : ∀ j, j < W → ∀ i, (cols i).testBit j = (fun i => j.testBit i) i)
    {gs hs : Netlist}
    (hrun : runS W cols [] gs = runS W cols [] hs) :
    ∀ j, j < W → ∀ k,
      (runP (fun i => j.testBit i) [] gs).getD k false
        = (runP (fun i => j.testBit i) [] hs).getD k false := by
  intro j hj k
  have hg := reflect hj (hcols j hj) gs (agree_nil j)
  have hh := reflect hj (hcols j hj) hs (agree_nil j)
  rw [← hg.2 k, ← hh.2 k, hrun]

#audit_axioms agree_nil agree_snoc
#audit_axioms testBit_mask testBit_mask_xor stepS_testBit
#audit_axioms reflect eq_of_sliced_eq getD_snoc

end SaltWorks.Silicon
