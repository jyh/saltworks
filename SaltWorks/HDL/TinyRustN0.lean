/-!
# N0 — the tiny-Rust typing judgment, as data, with its three pre-registered controls

**Council ruling #2, 2026-08-09 08:43** (the Captain: *"Yes, fire the probes."*) — the N0
PROBE LAYER, compiler's slot, statements at **lang-design v1.4**.

## PRECONDITION PREAMBLE (mandatory per the wave law, QUEUE W2)

This file is a **PROBE**, not a wave. What it claims and what it does not:

* **CLAIMED** — the judgment exists as data; it is decidable *by construction* (a total
  checker, not an assumed instance); the three pre-registered controls are green at the
  kernel; the pool bound is a **separate** predicate that the judgment never mentions.
* **NOT CLAIMED** — no soundness of the checker against an inductive rule relation (that
  is N0's own wave); no preservation; no compile theorem; no completeness. Rows A/B are
  untouched here.
* **PRE-REGISTERED, before any result below was run:** T2-accept green · T2-reject
  **red** (`while 1`, an `i32` where `bool` is demanded) · F6 `bigStep` **inhabited**.
  A probe that cannot make T2-reject *fail* has not tested the judgment, it has tested
  nothing — the reject control is the load-bearing one.
* **SCOPE OF `decide`** — T2's controls are `Bool`-valued and decide by computation. F6 is
  an **inductive relation**: `decide` does not apply to it without an evaluator, so F6 is
  discharged by an **explicit derivation term**, which is strictly stronger than `decide`
  (a witness, not a decision procedure). Stated here rather than quietly substituted.

## v1.4 FORM, as ruled

Two judgments: `Γ ⊢ e : τ` for expressions, and the **classical sequence-typed** statement
form (the Captain's form — no output contexts, no nonstandard turnstiles). `let` binds over
its **continuation**, so scope end = liveness end and the live-binding count reads straight
off the syntax. `Γ` is an assoc list: decidable lookup, structural recursion,
`Γ.length` = live bindings.

⚖️ **THE POOL BOUND IS SEPARATE AND NOT WELDED IN.** `liveMax p ≤ poolSize` is a *resource*
hypothesis beside the judgment. The judgment stays a pure SOURCE property — the same program
must not become ill-typed on a smaller core.

## MATH'S REFUTATION PASS #1 (08:45), FOLDED BEFORE THIS FILE WAS CAST

Both findings arrived while this file was written and before it was built. Folded, not deferred:

1. ⛔ **`liveMax` CONTROLS ROW B'S TRUTH AND CAN MAKE IT VACUOUS.** Row B
   (`∀ p, wellFormed p → liveMax p ≤ poolSize → ∃ code, …`) is satisfied by a *pessimistic*
   `liveMax`: define it large enough and the hypothesis is almost never met, so the `∀` is
   near-empty and the row proves easily. Too optimistic and the row is false instead.
   ⇒ **Math's pre-registered demand is met in §6 by `liveMax_witness_nontrivial`: an
   EXHIBITED non-trivial `p` with `liveMax p ≤ poolSize` holding by `decide`, plus the
   exact value of `liveMax` on it so the bound cannot be met by inflating the function.**
2. ⚠️ **"EXACTLY TWO REJECTION CAUSES" IS A COMPLETENESS CLAIM AND MATH HAS A CANDIDATE
   THIRD: INSTRUCTION MEMORY.** A program can be well-typed and pool-fitting and still emit
   more instructions than the machine holds (`code.length` is the machine bound). **This file
   therefore does NOT claim exhaustiveness.** It claims the two causes are *distinct and
   separately characterizable* (proved in §6), which is weaker and is all the probe earns.
   Whether imem capacity is a third hypothesis or is provably non-binding is **OPEN** and
   belongs to Row B's own wave, not to N0.
-/

namespace SaltWorks.HDL.TinyRustN0

/-! ## 1. Types, expressions, statements -/

/-- `τ ::= i32 | bool`. Two types, and `bool` is represented at runtime as `0`/`1`
(SLT's output IS the bool representation — the invariant that makes BEQ-on-bool sound). -/
inductive Ty where
  | i32
  | bool
  deriving DecidableEq, Repr

/-- Expressions. `tt`/`ff` are the bool literals v1.3's fold added. -/
inductive Exp where
  | var   (x : Nat)
  | const (n : BitVec 32)
  | tt
  | ff
  | add   (a b : Exp)
  | xor   (a b : Exp)
  | slt   (a b : Exp)
  deriving DecidableEq, Repr

/-- Statements. `letmut` carries its **continuation** as `body` — that is what makes scope
end = liveness end, and it is why `liveMax` needs no second analysis. -/
inductive Stmt where
  | skip
  | letmut (x : Nat) (t : Ty) (e : Exp) (body : Stmt)
  | assign (x : Nat) (e : Exp)
  | seq    (s t : Stmt)
  | ite    (c : Exp) (thn els : Stmt)
  | while  (c : Exp) (body : Stmt)
  deriving DecidableEq, Repr

/-- `Γ` — an assoc list. `Γ.length` is exactly the number of live bindings. -/
abbrev Ctx := List (Nat × Ty)

/-- Decidable lookup, structurally recursive. Most recent binding shadows. -/
def look : Ctx → Nat → Option Ty
  | [],            _ => none
  | (y, t) :: rest, x => if x = y then some t else look rest x

/-! ## 2. The judgment, as data

`inferE` IS `Γ ⊢ e : τ` presented as a total function into `Option Ty`. Decidability is by
construction: there is no `Decidable` instance to trust, only a computation. -/

/-- `Γ ⊢ e : τ` — returns `some τ` exactly when the expression is well-typed. -/
def inferE (Γ : Ctx) : Exp → Option Ty
  | .var x    => look Γ x
  | .const _  => some .i32
  | .tt       => some .bool
  | .ff       => some .bool
  | .add a b  => match inferE Γ a, inferE Γ b with
                 | some .i32, some .i32 => some .i32
                 | _, _ => none
  | .xor a b  => match inferE Γ a, inferE Γ b with
                 | some .i32, some .i32 => some .i32
                 | _, _ => none
  -- `slt` consumes two `i32` and PRODUCES a `bool`: this is the 0/1 bool representation
  -- entering the type system, and it is what makes the reject control a genuine TYPE error
  -- rather than a scope error.
  | .slt a b  => match inferE Γ a, inferE Γ b with
                 | some .i32, some .i32 => some .bool
                 | _, _ => none

/-- The sequence-typed statement judgment. `letmut` extends `Γ` over its continuation only.
Conditions are **`bool`** — Rust-faithful, no truthy ints. -/
def chkS (Γ : Ctx) : Stmt → Bool
  | .skip          => true
  | .letmut x t e body =>
      (inferE Γ e == some t) && chkS ((x, t) :: Γ) body
  | .assign x e    =>
      match look Γ x, inferE Γ e with
      | some tx, some te => tx == te
      | _, _ => false
  | .seq s t       => chkS Γ s && chkS Γ t
  | .ite c thn els =>
      (inferE Γ c == some .bool) && chkS Γ thn && chkS Γ els
  | .while c body  =>
      (inferE Γ c == some .bool) && chkS Γ body

/-- `wellFormed` IS the judgment, at the empty context. A pure SOURCE property. -/
def wellFormed (p : Stmt) : Bool := chkS [] p

/-! ## 3. The pool bound — SEPARATE, and it never appears in the judgment above -/

/-- Maximum simultaneously-live bindings. Reads straight off the syntax because `letmut`
scopes over its continuation; no second analysis, so F4's `c2` has nowhere to move back in. -/
def liveMax : Stmt → Nat
  | .skip              => 0
  | .letmut _ _ _ body => 1 + liveMax body
  | .assign _ _        => 0
  | .seq s t           => max (liveMax s) (liveMax t)
  | .ite _ thn els     => max (liveMax thn) (liveMax els)
  | .while _ body      => liveMax body

/-- Completeness will read "well-typed AND pool-fitting compiles" — two predicates, two
characterizable rejection causes. This is the conjunction, never a welded judgment. -/
def fitsAndTyped (poolSize : Nat) (p : Stmt) : Bool :=
  wellFormed p && (liveMax p ≤ poolSize)

/-! ## 4. Big-step semantics — a RELATION. Termination is NOT assumed. -/

/-- Values are 32-bit; `bool` inhabits `0`/`1`. -/
abbrev State := Nat → BitVec 32

def upd (σ : State) (x : Nat) (v : BitVec 32) : State :=
  fun y => if y = x then v else σ y

/-- Expression evaluation is total (all values are `BitVec 32`). -/
def evalE (σ : State) : Exp → BitVec 32
  | .var x   => σ x
  | .const n => n
  | .tt      => 1
  | .ff      => 0
  | .add a b => evalE σ a + evalE σ b
  | .xor a b => evalE σ a ^^^ evalE σ b
  | .slt a b => if (evalE σ a).slt (evalE σ b) then 1 else 0

/-- `bigStep p σ σ'` — IMP-shaped, and a relation precisely so that non-termination is
representable rather than assumed away. -/
inductive bigStep : Stmt → State → State → Prop where
  | skip   {σ} : bigStep .skip σ σ
  | letmut {x t e body σ σ'} :
      bigStep body (upd σ x (evalE σ e)) σ' → bigStep (.letmut x t e body) σ σ'
  | assign {x e σ} : bigStep (.assign x e) σ (upd σ x (evalE σ e))
  | seq    {s t σ σ₁ σ'} :
      bigStep s σ σ₁ → bigStep t σ₁ σ' → bigStep (.seq s t) σ σ'
  | iteT   {c thn els σ σ'} :
      evalE σ c = 1 → bigStep thn σ σ' → bigStep (.ite c thn els) σ σ'
  | iteF   {c thn els σ σ'} :
      evalE σ c = 0 → bigStep els σ σ' → bigStep (.ite c thn els) σ σ'
  | whileF {c body σ} :
      evalE σ c = 0 → bigStep (.while c body) σ σ
  | whileT {c body σ σ₁ σ'} :
      evalE σ c = 1 → bigStep body σ σ₁ → bigStep (.while c body) σ₁ σ' →
      bigStep (.while c body) σ σ'

/-! ## 5. THE THREE PRE-REGISTERED CONTROLS -/

/-- **T2-accept fixture.** `let mut x : i32 = 7; while (x < 7) { x := x ^ 1 }` — exercises a
binding, a `slt`-produced `bool` condition, an assignment, and a `while`. -/
def acceptProg : Stmt :=
  .letmut 0 .i32 (.const 7)
    (.while (.slt (.var 0) (.const 7))
      (.assign 0 (.xor (.var 0) (.const 1))))

/-- **T2-REJECT fixture — the load-bearing control.** `while 1 { skip }`: the condition is a
`const`, hence `i32`, where `bool` is demanded. A genuine TYPE mismatch, not a scope error —
which is why v1.3's bool fold supersedes the "with one type the judgment is a scope checker"
premise. -/
def rejectProg : Stmt :=
  .while (.const 1) .skip

/-- **T2-accept: GREEN.** -/
theorem t2_accept : wellFormed acceptProg = true := by decide

/-- **T2-reject: RED, as pre-registered.** -/
theorem t2_reject : wellFormed rejectProg = false := by decide

/-- **POSITIVE CONTROL for the reject.** The rejection must be caused by the TYPE of the
condition and nothing else. Swap `const 1` for the `bool` literal `tt`, change nothing else,
and the program is ACCEPTED — so `rejectProg` fails on its condition's type, not on `while`,
not on `skip`, not on emptiness. Without this, a checker that rejected every `while` would
pass `t2_reject`. -/
theorem t2_reject_is_load_bearing :
    wellFormed (.while .tt .skip) = true := by decide

/-- **SECOND POSITIVE CONTROL — the judgment is not vacuously false.** A `slt` condition
(bool by the 0/1 representation) is accepted where an `i32` is not, so the bool type is
genuinely inhabited at condition position. -/
theorem t2_slt_condition_accepted :
    wellFormed (.letmut 0 .i32 (.const 0) (.while (.slt (.var 0) (.const 1)) .skip)) = true := by
  decide

/-- **F6 — `bigStep` SHOWN NONEMPTY, by explicit derivation.** A mis-defined relation that
steps nothing turns every downstream row vacuously green; the relation is shown inhabited
before any wave fires, never assumed.

`skip; x := 0 + 0` runs from any `σ` to `upd σ 0 0`. The witness is a proof term, which is
strictly stronger than a decision procedure. -/
theorem f6_bigStep_inhabited (σ : State) :
    bigStep (.seq .skip (.assign 0 (.add (.const 0) (.const 0)))) σ
            (upd σ 0 (evalE σ (.add (.const 0) (.const 0)))) :=
  .seq .skip .assign

/-- **F6, the `while` arm too** — the loop form must be able to step, or every `while` row
is vacuous. `while ff { skip }` terminates immediately from any state. -/
theorem f6_bigStep_while_inhabited (σ : State) :
    bigStep (.while .ff .skip) σ σ :=
  .whileF rfl

/-- **F6 POSITIVE CONTROL — a loop that actually ITERATES.** `whileF` alone would be
satisfied by a relation whose loop never enters the body. Here the body runs once and then
the condition is false, so `whileT` is genuinely exercised. -/
theorem f6_bigStep_while_iterates (σ : State) :
    bigStep (.while (.xor (.var 0) (.const 1)) (.assign 0 (.const 1)))
            (upd σ 0 0) (upd (upd σ 0 0) 0 1) := by
  refine .whileT ?_ .assign (.whileF ?_)
  · simp [evalE, upd]
  · simp [evalE, upd]

/-! ## 6. The pool bound is genuinely separate — a control for that claim too -/

/-- **CONTROL: the judgment does not mention the pool.** A program can be well-typed and
pool-EXCEEDING at the same time, which is what makes the two rejection causes distinct. With
`poolSize = 1`, a two-binding program is well-typed yet does not fit. -/
theorem pool_is_separate :
    wellFormed (.letmut 0 .i32 (.const 0) (.letmut 1 .i32 (.const 0) .skip)) = true
  ∧ liveMax (.letmut 0 .i32 (.const 0) (.letmut 1 .i32 (.const 0) .skip)) = 2
  ∧ fitsAndTyped 1 (.letmut 0 .i32 (.const 0) (.letmut 1 .i32 (.const 0) .skip)) = false := by
  refine ⟨by decide, by decide, by decide⟩

/-- **MATH'S PRE-REGISTERED DEMAND (refutation pass #1, finding 1), DISCHARGED.**

An **exhibited non-trivial witness** with `liveMax p ≤ poolSize` HOLDING — without this,
Row B is satisfiable by making `liveMax` pessimistic enough that its hypothesis is near-empty,
and F1's own logic would apply to F1's own row.

`acceptProg` is non-trivial by construction: a binding, a `slt`-produced `bool` condition, a
`while`, and an assignment. **The exact value of `liveMax` is pinned too**, so the bound
cannot be met by inflating the function — a pessimistic `liveMax` would fail this theorem, not
satisfy it. -/
theorem liveMax_witness_nontrivial :
    liveMax acceptProg = 1
  ∧ liveMax acceptProg ≤ 1
  ∧ fitsAndTyped 1 acceptProg = true := by
  refine ⟨by decide, by decide, by decide⟩

/-- **AND THE OTHER DIRECTION OF THE SAME DEMAND — the bound must be able to BIND.** A
three-binding program fits at `poolSize = 3` and does not at `2`. Both arms by `decide`, so
`liveMax` is pinned from above and below and cannot be quietly re-tuned. -/
theorem liveMax_binds_both_ways :
    liveMax (.letmut 0 .i32 (.const 0)
              (.letmut 1 .i32 (.const 0)
                (.letmut 2 .i32 (.const 0) .skip))) = 3
  ∧ fitsAndTyped 3 (.letmut 0 .i32 (.const 0)
                     (.letmut 1 .i32 (.const 0)
                       (.letmut 2 .i32 (.const 0) .skip))) = true
  ∧ fitsAndTyped 2 (.letmut 0 .i32 (.const 0)
                     (.letmut 1 .i32 (.const 0)
                       (.letmut 2 .i32 (.const 0) .skip))) = false := by
  refine ⟨by decide, by decide, by decide⟩

/-- **CONTROL: a smaller core does not change typing — the v1.4 requirement, as a theorem.**

If a program fits and types at one pool size, then (a) it is **typed**, full stop, with no
pool mentioned; and (b) at any *other* pool size `m` it fits-and-types the moment the
**resource bound alone** holds. So moving to a smaller or larger core never requires
re-establishing the typing half.

*This is the honest content of "the judgment is a pure SOURCE property". An earlier draft
stated it with a second conjunct `wellFormed p = wellFormed p`, which is `rfl` and proves
nothing — a vacuous clause dressed as a claim, struck before this file was cast.* -/
theorem typing_is_pool_independent (p : Stmt) (n m : Nat)
    (h : fitsAndTyped n p = true) :
    wellFormed p = true ∧ (liveMax p ≤ m → fitsAndTyped m p = true) := by
  simp only [fitsAndTyped, Bool.and_eq_true, decide_eq_true_eq] at h
  exact ⟨h.1, fun hm => by simp [fitsAndTyped, h.1, hm]⟩

end SaltWorks.HDL.TinyRustN0
