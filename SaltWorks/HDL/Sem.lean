/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Syntax

/-!
# `sem` — the meaning of a `Circ`

The environment is a **total function** `Net → Bool`, updated pointwise. Three
consequences, all of them the reason for the choice:

* `sem` is **total** with no side conditions — no lengths, no `getD` defaults, no
  well-formedness hypothesis. A gate that reads an undefined net reads `false`,
  which is a definite value, so every `Circ` has a meaning and theorems about
  `sem` never carry a `wf` premise they do not need.
* It is **structurally recursive**, so the kernel can reduce it. This is
  load-bearing: well-founded recursion does not reduce in the kernel (`Acc.rec`
  gets stuck on an opaque accessibility proof), which would make the whole
  executable-certificate suite impossible.
* Updating is `fun j => if j = n then v else env j`, so there is **no append**.

The frame lemmas below (`run_of_unwritten`, `run_congr`) are the whole point of
this file: they are what makes dead-net elimination, and later the seam's
per-output equivalence, provable without induction on circuit *structure*.
-/

namespace SaltWorks.HDL

/-- A valuation of every net. Total by construction. -/
abbrev Env := Net → Bool

/-- One operation, under a valuation. -/
def Op.eval (env : Env) : Op → Bool
  | .const b => b
  | .not a   => !(env a)
  | .and a b => env a && env b
  | .or  a b => env a || env b
  | .xor a b => env a ^^ env b

/-- An operation depends only on the nets it reads. -/
theorem Op.eval_congr {env₁ env₂ : Env} :
    (o : Op) → (∀ n ∈ o.fanin, env₁ n = env₂ n) → o.eval env₁ = o.eval env₂
  | .const _, _ => rfl
  | .not a,   h => by simp [Op.eval, h a (by simp [Op.fanin])]
  | .and a b, h => by simp [Op.eval, h a (by simp [Op.fanin]), h b (by simp [Op.fanin])]
  | .or  a b, h => by simp [Op.eval, h a (by simp [Op.fanin]), h b (by simp [Op.fanin])]
  | .xor a b, h => by simp [Op.eval, h a (by simp [Op.fanin]), h b (by simp [Op.fanin])]

/-- Point update. -/
def upd (env : Env) (n : Net) (v : Bool) : Env := fun j => if j = n then v else env j

@[simp] theorem upd_self (env : Env) (n : Net) (v : Bool) : upd env n v n = v := by
  simp [upd]

theorem upd_of_ne {env : Env} {n m : Net} (v : Bool) (h : m ≠ n) : upd env n v m = env m := by
  simp [upd, h]

/-- Run a gate list, threading the environment. Structural recursion on the list. -/
def run (env : Env) : List Gate → Env
  | []      => env
  | g :: gs => run (upd env g.out (g.op.eval env)) gs

@[simp] theorem run_nil (env : Env) : run env [] = env := rfl

@[simp] theorem run_cons (env : Env) (g : Gate) (gs : List Gate) :
    run env (g :: gs) = run (upd env g.out (g.op.eval env)) gs := rfl

/-- **The meaning of a circuit**: the primary outputs, in port order, as a
function of the input valuation. -/
def sem (c : Circ) (ins : Env) : List Bool :=
  c.outs.map (run ins c.gates)

theorem run_append (env : Env) (gs hs : List Gate) :
    run env (gs ++ hs) = run (run env gs) hs := by
  induction gs generalizing env with
  | nil => rfl
  | cons g gs ih => simp [ih]

/-! ## The frame lemmas -/

/-- **A net no gate writes keeps its value.** This is the lemma dead-net
elimination is built on: it says a gate's effect is confined to the net it
names, which is exactly what naming the output net buys us. -/
theorem run_of_unwritten (env : Env) (gs : List Gate) (n : Net)
    (h : ∀ g ∈ gs, g.out ≠ n) : run env gs n = env n := by
  induction gs generalizing env with
  | nil => rfl
  | cons g gs ih =>
    rw [run_cons, ih _ (fun g' hg' => h g' (by simp [hg']))]
    exact upd_of_ne _ (fun hEq => h g (by simp) (hEq ▸ rfl))

/-- **Running agrees on any net, given environments that agree on everything the
gates read and write.** Stated with agreement everywhere below, which is the
form the optimizer proofs want. -/
theorem run_congr {env₁ env₂ : Env} (gs : List Gate) (h : ∀ n, env₁ n = env₂ n) :
    ∀ n, run env₁ gs n = run env₂ gs n := by
  induction gs generalizing env₁ env₂ with
  | nil => exact h
  | cons g gs ih =>
    refine ih (fun n => ?_)
    have hop : g.op.eval env₁ = g.op.eval env₂ := by
      cases g.op <;> simp [Op.eval, h]
    by_cases hn : n = g.out
    · subst hn; simp [hop]
    · rw [upd_of_ne _ hn, upd_of_ne _ hn]; exact h n

/-- Extensional agreement of two circuits' meanings follows from agreement of
their input valuations. -/
theorem sem_congr (c : Circ) {ins₁ ins₂ : Env} (h : ∀ n, ins₁ n = ins₂ n) :
    sem c ins₁ = sem c ins₂ := by
  simp only [sem]
  exact List.map_congr_left (fun n _ => run_congr c.gates h n)

/-! ## Worked meaning, kernel-checked

`halfAdder` really is a half adder — proved by `decide +kernel` over its whole
input space, which at two inputs is four points. This is the smallest instance of
the certificate genre: a *test that is proved*. -/

/-- The input valuation that reads bit `i` of `j`. -/
def bitsOf (j : Nat) : Env := fun i => j.testBit i

theorem halfAdder_correct :
    [0, 1, 2, 3].all (fun j =>
      sem halfAdder (bitsOf j) ==
        [(j.testBit 0) ^^ (j.testBit 1), (j.testBit 0) && (j.testBit 1)]) = true := by
  decide +kernel

-- `#audit_axioms` takes a LIST OF NAMES, so it is a whitelist: it bounds what is
-- checked from above and **nothing enforces that the list is complete.** A
-- theorem nobody lists is a theorem nobody audits, and the build stays green.
-- `Op.eval_congr` was unlisted from the day this file landed; it was covered only
-- because `Opt.run_filter` uses it and IS listed, so its axioms appeared in that
-- closure — coverage by luck, not by design. (Silicon's 18:24: a whitelist cannot
-- distinguish a correct set from an empty one.) Checked across all of leg 2:
-- this was the only unaudited theorem; the completeness check is one `comm` over
-- declared-vs-listed names and belongs in CI rather than in anyone's memory.
--
-- ✅ THAT CHECK NOW EXISTS: `docs/hdl-tools/audit_completeness.py`.  Run today
-- over all 35 leg-2 files / 359 theorems: EVERY theorem is on an
-- `#audit_axioms` list, so the hole this note describes is closed rather than
-- merely recorded.  Three-way exit (0 complete / 1 unaudited / 2 could not
-- check) and mutation-verified in all three, because a checker that cannot fail
-- is the defect it exists to prevent.
--
-- ⚠️ AND ITS FIRST VERSION WAS WRONG IN THE INSTRUCTIVE WAY: it matched
-- declarations against the RAW source and so read prose inside docstrings as
-- code, reporting 149 unaudited "theorems" with names like `is`, `goes` and
-- `rather`.  A tool that scans Lean and does not strip comments is measuring the
-- prose.  The real number is zero.
#audit_axioms Op.eval_congr
#audit_axioms upd_self upd_of_ne run_append
#audit_axioms run_of_unwritten run_congr sem_congr
#audit_axioms halfAdder_correct

end SaltWorks.HDL
