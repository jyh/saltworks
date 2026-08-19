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

/-! ## ⭐ A CIRCUIT DEPENDS ONLY ON WHAT IT READS

**`run_congr` and `sem_congr` above ask for agreement on EVERY net**, which is
more than the semantics needs and is why they cannot see the commonest fact
about a circuit: *changing a wire it never looks at changes nothing.*

📌 **THIS WAS PRICED BEFORE IT WAS BUILT AND THE PRICE WAS THE POINT.** *Evidence
needed a sampled/exhaustive detector; the detector needs to know when an
enumeration covers an axis; that needs a QUOTIENT lemma (e.g. `shifter32` reads
five shamt nets, so `List.range 32` IS the whole shift axis); and every such
lemma needs exactly this — because the two environments agree on what the circuit
reads and DIFFER elsewhere.* ⇒ **Four separate findings on 8/7 turned on "what
does this thing actually read": the `Dest 3` door, the idle-destination
refutation, the shift axis, and the detector. This is that question, once.** -/

/-- **A gate list depends only on what it READS** — agreement on every net any
gate takes as fanin, plus the queried net, is enough. *The `upd` step preserves
it: a later gate's fanin is either an earlier gate's output, where both sides
hold the same computed value, or an original net covered by the hypothesis.* -/
theorem run_congr_on (gs : List Gate) : ∀ {env₁ env₂ : Env},
    (∀ g ∈ gs, ∀ a ∈ g.op.fanin, env₁ a = env₂ a) →
    ∀ n, env₁ n = env₂ n → run env₁ gs n = run env₂ gs n := by
  induction gs with
  | nil => intro e₁ e₂ _ n hn; exact hn
  | cons g gs ih =>
    intro e₁ e₂ hf n hn
    have hop : g.op.eval e₁ = g.op.eval e₂ :=
      Op.eval_congr g.op (fun a ha => hf g (by simp) a ha)
    rw [run_cons, run_cons, hop]
    refine ih (fun g' hg' a ha => ?_) n ?_
    · by_cases hEq : a = g.out
      · subst hEq; simp [upd]
      · rw [upd_of_ne _ hEq, upd_of_ne _ hEq]
        exact hf g' (by simp [hg']) a ha
    · by_cases hEq : n = g.out
      · subst hEq; simp [upd]
      · rw [upd_of_ne _ hEq, upd_of_ne _ hEq]; exact hn

/-- ⭐ **A CIRCUIT DEPENDS ONLY ON WHAT IT READS.** Two input valuations agreeing
on every net the gates consume, and on the primary outputs, give the same
meaning — however wildly they differ on nets the circuit never looks at. -/
theorem sem_congr_on (c : Circ) {ins₁ ins₂ : Env}
    (hf : ∀ g ∈ c.gates, ∀ a ∈ g.op.fanin, ins₁ a = ins₂ a)
    (ho : ∀ n ∈ c.outs, ins₁ n = ins₂ n) :
    sem c ins₁ = sem c ins₂ := by
  simp only [sem]
  exact List.map_congr_left (fun n hn => run_congr_on c.gates hf n (ho n hn))

/-- ⛔ **THE FANIN HYPOTHESIS IS LOAD-BEARING** — two valuations agreeing at the
output net and differing on what a gate reads give different answers. -/
theorem reads_hypothesis_is_load_bearing :
    run (fun i => i == 0) [(⟨2, .and 0 1⟩ : Gate)] 2
      ≠ run (fun i => i == 1) [(⟨2, .and 0 1⟩ : Gate)] 2 ∨
    run (fun i => decide (i < 2)) [(⟨2, .and 0 1⟩ : Gate)] 2
      ≠ run (fun _ => false) [(⟨2, .and 0 1⟩ : Gate)] 2 := by
  decide +kernel

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
#audit_axioms run_congr_on sem_congr_on reads_hypothesis_is_load_bearing
#audit_axioms halfAdder_correct

/-! ## THE PACKED EVALUATOR — the same meaning, at a cost the kernel can pay

⛔⛔ **WHY THIS EXISTS, MEASURED TWICE ON 2026-08-19.** `Env = Net → Bool` and `run` threads it
as a NESTED `upd` CLOSURE CHAIN, so every lookup walks the chain. Under `decide +kernel` that
is quadratic in the gate count AND the cached whnf pairs are the memory. Two independent
blowups in one day, both `lean::memory_exception`, exit 134:

* `run ins core.gates <net>` directly — died at 190 s with RSS past 23 GB against `-M 24000`;
* `regWrite`'s exhaustive certificate at 32 × 2⁶ = 2048 points — died at 75 s against
  `-M 20000`, and again after flattening six nested `List.all` closures into one range, which
  rules out closure depth as the cause.

⭐ **THE CURE IS THE ENVIRONMENT REPRESENTATION, NOT THE CIRCUIT.** Pack the whole net
valuation into ONE `Nat`, because `Nat.land / lor / xor / pow / testBit` are GMP-accelerated
in the kernel. The first blowup fell to this immediately: three full 10394-gate kernel
evaluations of `core` in **25 s**.

⚠️ **THIS BUYS SPEED, NOT TRUST.** `runB_eq` and `semB_eq` below are what make it sound —
they prove the packed evaluator IS `run` and IS `sem`, by induction, so a proof routed through
`semB` is a proof about `sem`. Never use `runB`/`semB` in a STATEMENT you intend someone to
read as being about the circuit; state it with `sem`/`run` and discharge it with these. -/

/-- Write bit `n` of `s` to `v`. -/
def bset (s n : Nat) (v : Bool) : Nat :=
  (s ^^^ (s &&& 2 ^ n)) ||| (if v then 2 ^ n else 0)

theorem testBit_bset (s n : Nat) (v : Bool) (j : Nat) :
    (bset s n v).testBit j = if j = n then v else s.testBit j := by
  by_cases h : j = n
  · subst h
    simp only [bset, Nat.testBit_or, Nat.testBit_xor, Nat.testBit_and, Nat.testBit_two_pow]
    cases v <;> cases hs : s.testBit j <;> simp
  · have h' : ¬ (n = j) := fun hh => h hh.symm
    simp only [bset, Nat.testBit_or, Nat.testBit_xor, Nat.testBit_and, Nat.testBit_two_pow,
      if_neg h, decide_eq_false h']
    cases v <;> cases hs : s.testBit j <;> simp [h']

/-- One operation, read out of the packed state. -/
def opEvalN (s : Nat) : Op → Bool
  | .const b => b
  | .not a   => !(s.testBit a)
  | .and a b => s.testBit a && s.testBit b
  | .or  a b => s.testBit a || s.testBit b
  | .xor a b => s.testBit a ^^ s.testBit b

theorem opEvalN_eq (s : Nat) (o : Op) : opEvalN s o = o.eval (fun n => s.testBit n) := by
  cases o <;> rfl

/-- `run`, with the valuation packed into a `Nat`. -/
def runB (s : Nat) : List Gate → Nat
  | []      => s
  | g :: gs => runB (bset s g.out (opEvalN s g.op)) gs

/-- ⭐ **SOUNDNESS: the packed evaluator IS `run`.** -/
theorem runB_eq (gs : List Gate) : ∀ (s : Nat) (j : Nat),
    (runB s gs).testBit j = run (fun n => s.testBit n) gs j := by
  induction gs with
  | nil => intro s j; rfl
  | cons g gs ih =>
    intro s j
    have hfun : (fun n => (bset s g.out (opEvalN s g.op)).testBit n)
        = upd (fun n => s.testBit n) g.out (g.op.eval (fun n => s.testBit n)) := by
      funext n
      rw [testBit_bset, opEvalN_eq]
      simp only [upd]
    show (runB (bset s g.out (opEvalN s g.op)) gs).testBit j
        = run (upd (fun n => s.testBit n) g.out (g.op.eval (fun n => s.testBit n))) gs j
    rw [ih, hfun]

/-- `sem`, evaluated through the packed representation. -/
def semB (c : Circ) (s : Nat) : List Bool :=
  c.outs.map (fun o => (runB s c.gates).testBit o)

/-- ⭐⭐ **SOUNDNESS: the packed meaning IS `sem`.** An exhaustive organ certificate may
therefore be stated over `sem` and DISCHARGED over `semB`. -/
theorem semB_eq (c : Circ) (s : Nat) : semB c s = sem c (fun n => s.testBit n) := by
  simp only [semB, sem, List.map_inj_left]
  intro o _
  exact runB_eq c.gates s o

#audit_axioms testBit_bset opEvalN_eq runB_eq semB_eq

end SaltWorks.HDL
