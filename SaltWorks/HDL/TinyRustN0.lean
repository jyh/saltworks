/-!
# N0 — the tiny-Rust typing judgment, as data, with its three pre-registered controls

**Council ruling #2, 2026-08-09 08:43** (the Captain: *"Yes, fire the probes."*) — the N0
PROBE LAYER, compiler's slot, statements at **lang-design v1.4**.

**REPAIR WAVE, 2026-08-09 08:58** (maestro: *"your read is correct, the repair is YOURS"*) —
binders now map to **de Bruijn LEVELS**, an internal representation. The Captain's surface is
untouched: his sequence-typed notation, the assoc-list `Γ` of **names**, and
`let`-binds-over-its-continuation all stand. Only the mapping from binders to `State` cells
changed, and it changed because two independent findings turned out to be one defect.

## PRECONDITION PREAMBLE (mandatory per the wave law, QUEUE W2)

This file is a **PROBE** plus its **repair**, not the N0 wave. What it claims and what it does not:

* **CLAIMED** — the judgment exists as data and is decidable *by construction*; the three
  pre-registered controls are green at the kernel; the pool bound is a **separate** predicate
  the judgment never mentions; binders do not alias (`no_aliasing`); and the
  **bool-is-0/1 invariant holds for expressions** (`evalE_bool_is_01`) — the node that makes
  BEQ-on-bool sound.
* **NOT CLAIMED** — no full statement-level preservation over `bigStep` (that is N0's wave);
  no compile theorem; no completeness; Rows A/B untouched.
* **PRE-REGISTERED, before any result below was run:** T2-accept green · T2-reject **red**
  (`while 1`, an `i32` where `bool` is demanded) · F6 `bigStep` **inhabited**. A probe that
  cannot make T2-reject *fail* has tested nothing — the reject control is load-bearing.
* **SCOPE OF `decide`** — T2's controls are `Bool`-valued and decide by computation. F6 is an
  **inductive relation**: `decide` does not apply without an evaluator, so F6 is discharged by
  an **explicit derivation term**, which is strictly stronger than `decide` (a witness, not a
  decision procedure). Stated rather than quietly substituted.

## THE TWO FINDINGS THAT WERE ONE — math's refutation passes #1–#3, folded

1. **Pass #1** — `liveMax` can make Row B vacuous by being pessimistic. Discharged in §7 by
   an exhibited non-trivial witness with `liveMax` **pinned from above and below**, so a
   pessimistic `liveMax` would *fail* those theorems rather than satisfy Row B cheaply.
2. **Pass #2** — `liveMax (.assign _ _) = 0` for *any* expression while `Exp` is fully
   recursive, so expression cost was unbounded and scored zero. `expMaxNoSwap` (§6) is the second,
   **independent** term; independence is proved, so it cannot be a rescaling of `liveMax`.
3. **Pass #3, the one that changed the design** — *the scope defect and the `liveMax`
   falsifier are the same defect.* `liveMax` counts binders as registers; a `State` keyed by
   **source name** aliases two binders onto one cell. **The pool bound presumed α-freshness
   and the state denied it.** Repairing either half alone leaves the other broken and makes
   the surviving repair look redundant. ⇒ **de Bruijn levels repair both at once**, and make
   `liveMax` correct *by construction* rather than by an assumption the state contradicts.

*Rejected, with reasons, because both were on my own table: a **freshness side condition**
(makes preservation provable, leaves the semantics wrong, resurfaces as an aliasing bug in
register allocation — moves a defect rather than removing it); and **restore-on-block-exit**,
which was my own published choice and fixed only my half.*
-/

namespace SaltWorks.HDL.TinyRustN0

/-! ## 1. Types, expressions, statements — the Captain's surface, unchanged -/

/-- `τ ::= i32 | bool`. `bool` is represented at runtime as `0`/`1` — SLT's output IS the
bool representation, and that is what makes BEQ-on-bool sound. -/
inductive Ty where
  | i32
  | bool
  deriving DecidableEq, Repr

inductive Exp where
  | var   (x : Nat)
  | const (n : BitVec 32)
  | tt
  | ff
  | add   (a b : Exp)
  | xor   (a b : Exp)
  | slt   (a b : Exp)
  deriving DecidableEq, Repr

/-- `letmut` carries its **continuation** as `body`: scope end = liveness end. -/
inductive Stmt where
  | skip
  | letmut (x : Nat) (t : Ty) (e : Exp) (body : Stmt)
  | assign (x : Nat) (e : Exp)
  | seq    (s t : Stmt)
  | ite    (c : Exp) (thn els : Stmt)
  | while  (c : Exp) (body : Stmt)
  deriving DecidableEq, Repr

/-- `Γ` — an assoc list of **names**, the Captain's form. `Γ.length` = live bindings. -/
abbrev Ctx := List (Nat × Ty)

/-! ## 2. THE REPAIR — a binder's runtime slot is its LEVEL, not its name

`(y, t) :: rest` sits **above** `rest`, so its level is `rest.length`. No subtraction, and
shadowing necessarily lands on a fresh cell. -/

/-- Resolve a source name to `(level, type)`. Most recent binding shadows, and it shadows
onto a **different cell**. -/
def lookLvl : Ctx → Nat → Option (Nat × Ty)
  | [],             _ => none
  | (y, t) :: rest, x => if x = y then some (rest.length, t) else lookLvl rest x

/-- The type half of the lookup — this is what the judgment reads. -/
def look (Γ : Ctx) (x : Nat) : Option Ty := (lookLvl Γ x).map Prod.snd

/-- The slot half. Total; `0` on an unbound name, which `chkS` excludes. -/
def slotOf (Γ : Ctx) (x : Nat) : Nat :=
  match lookLvl Γ x with
  | some (l, _) => l
  | none        => 0

/-! ## 3. The judgment, as data — decidability by construction -/

/-- `Γ ⊢ e : τ`, as a computation into `Option Ty`. -/
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
  -- `slt` consumes two `i32` and PRODUCES a `bool`: the 0/1 representation entering the
  -- type system, and why the reject control is a genuine TYPE error, not a scope error.
  | .slt a b  => match inferE Γ a, inferE Γ b with
                 | some .i32, some .i32 => some .bool
                 | _, _ => none

/-- The classical sequence-typed statement judgment. Conditions are **`bool`** — Rust-faithful,
no truthy ints. -/
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

/-! ## 4. Semantics — `State` is indexed by LEVEL, and `bigStep` threads `Γ` -/

abbrev State := Nat → BitVec 32

def upd (σ : State) (l : Nat) (v : BitVec 32) : State :=
  fun k => if k = l then v else σ k

/-- Expression evaluation. Total, and it resolves names through `Γ` to levels. -/
def evalE (Γ : Ctx) (σ : State) : Exp → BitVec 32
  | .var x   => σ (slotOf Γ x)
  | .const n => n
  | .tt      => 1
  | .ff      => 0
  | .add a b => evalE Γ σ a + evalE Γ σ b
  | .xor a b => evalE Γ σ a ^^^ evalE Γ σ b
  | .slt a b => if (evalE Γ σ a).slt (evalE Γ σ b) then 1 else 0

/-- `bigStep Γ p σ σ'` — IMP-shaped, a **relation** so non-termination is representable
rather than assumed away. `letmut` writes at level `Γ.length`: **above** every level the
outer context can name, which is the whole content of the repair. -/
inductive bigStep : Ctx → Stmt → State → State → Prop where
  | skip   {Γ σ} : bigStep Γ .skip σ σ
  | letmut {Γ x t e body σ σ'} :
      bigStep ((x, t) :: Γ) body (upd σ Γ.length (evalE Γ σ e)) σ' →
      bigStep Γ (.letmut x t e body) σ σ'
  | assign {Γ x e σ} :
      bigStep Γ (.assign x e) σ (upd σ (slotOf Γ x) (evalE Γ σ e))
  | seq    {Γ s t σ σ₁ σ'} :
      bigStep Γ s σ σ₁ → bigStep Γ t σ₁ σ' → bigStep Γ (.seq s t) σ σ'
  | iteT   {Γ c thn els σ σ'} :
      evalE Γ σ c = 1 → bigStep Γ thn σ σ' → bigStep Γ (.ite c thn els) σ σ'
  | iteF   {Γ c thn els σ σ'} :
      evalE Γ σ c = 0 → bigStep Γ els σ σ' → bigStep Γ (.ite c thn els) σ σ'
  | whileF {Γ c body σ} :
      evalE Γ σ c = 0 → bigStep Γ (.while c body) σ σ
  | whileT {Γ c body σ σ₁ σ'} :
      evalE Γ σ c = 1 → bigStep Γ body σ σ₁ → bigStep Γ (.while c body) σ₁ σ' →
      bigStep Γ (.while c body) σ σ'

/-! ## 5. THE REPAIR, AS THEOREMS — what was false before is provable now -/

/-- Every level a context can name is **strictly below** its length. -/
theorem lookLvl_lt (Γ : Ctx) (x l : Nat) (t : Ty) :
    lookLvl Γ x = some (l, t) → l < Γ.length := by
  induction Γ with
  | nil => intro h; simp [lookLvl] at h
  | cons hd tl ih =>
      intro h
      simp only [lookLvl] at h
      split at h
      · -- the head binds `x`: its level IS `tl.length`, one below the extended length
        have hl : l = tl.length := by
          have hp := Option.some.inj h
          simpa using (congrArg Prod.fst hp).symm
        subst hl
        simp
      · -- the head does not bind `x`: recurse, and one more cell is below us
        have hrec := ih h
        simp only [List.length_cons]
        omega

/-- ⭐ **NO ALIASING — the theorem that was FALSE before the repair.** A `letmut` writes at
level `Γ.length`, so **every cell the outer context can name is untouched**. Shadowing can no
longer destroy an outer binding's value, and that is why the same repair fixes `liveMax`:
distinct binders genuinely occupy distinct cells, which `liveMax` was already assuming. -/
theorem no_aliasing (Γ : Ctx) (x l : Nat) (t : Ty) (σ : State) (v : BitVec 32)
    (h : lookLvl Γ x = some (l, t)) :
    upd σ Γ.length v l = σ l := by
  have : l ≠ Γ.length := Nat.ne_of_lt (lookLvl_lt Γ x l t h)
  simp [upd, this]

/-- "the state respects `Γ`": every `bool`-typed binding holds `0` or `1`. -/
def stateOK (Γ : Ctx) (σ : State) : Prop :=
  ∀ x l t, lookLvl Γ x = some (l, t) → t = .bool → (σ l = 0 ∨ σ l = 1)

/-- ⭐⭐ **THE BOOL-IS-0/1 INVARIANT FOR EXPRESSIONS — the node that makes BEQ-on-bool sound.**
A `bool`-typed expression evaluates to `0` or `1`, never to any other bit pattern. -/
theorem evalE_bool_is_01 (Γ : Ctx) (σ : State) (e : Exp)
    (hty : inferE Γ e = some .bool) (hok : stateOK Γ σ) :
    evalE Γ σ e = 0 ∨ evalE Γ σ e = 1 := by
  cases e with
  | var x =>
      simp only [inferE, look, Option.map_eq_some_iff] at hty
      obtain ⟨p, hp, hsnd⟩ := hty
      have : evalE Γ σ (.var x) = σ p.1 := by simp [evalE, slotOf, hp]
      rw [this]
      exact hok x p.1 p.2 (by rw [hp]) hsnd
  | const _ => simp [inferE] at hty
  | tt => right; simp [evalE]
  | ff => left; simp [evalE]
  | add a b =>
      simp only [inferE] at hty
      split at hty <;> simp_all
  | xor a b =>
      simp only [inferE] at hty
      split at hty <;> simp_all
  | slt a b =>
      by_cases h : (evalE Γ σ a).slt (evalE Γ σ b)
      · right; simp [evalE, h]
      · left; simp [evalE, h]

/-- **THE PREVIOUS FALSIFIER, NOW PASSING.** Before the repair, `Γ = [(0, bool)]` with
`letmut 0 i32 (const 7) skip` destroyed the outer `bool`'s cell and refuted preservation. Now
the inner binder writes level `1` and the outer `bool` lives at level `0`, untouched. -/
theorem shadowing_witness_now_preserves (σ : State) (hok : stateOK [(0, Ty.bool)] σ) :
    stateOK [(0, Ty.bool)] (upd σ 1 7) := by
  intro x l t hx hb
  have hlt : l < 1 := lookLvl_lt [(0, Ty.bool)] x l t hx
  have : l ≠ 1 := by omega
  rw [show upd σ 1 7 l = σ l from by simp [upd, this]]
  exact hok x l t hx hb

/-! ## 6. The resource terms — SEPARATE from the judgment, and two of them -/

/-- Maximum simultaneously-live bindings = maximum LEVEL reached. Correct by construction now
that levels are the cells. -/
def liveMax : Stmt → Nat
  | .skip              => 0
  | .letmut _ _ _ body => 1 + liveMax body
  | .assign _ _        => 0
  | .seq s t           => max (liveMax s) (liveMax t)
  | .ite _ thn els     => max (liveMax thn) (liveMax els)
  | .while _ body      => liveMax body

/-- **MATH'S PASS #2 TERM** — simultaneous intermediates of an expression, for a two-address
machine evaluating operands **left-to-right with no swapping**. `liveMax` scored this **zero**
for every expression.

⛔⛔ **THIS IS NOT THE SETHI–ULLMAN NUMBER, AND THE NAME IS IN THE IDENTIFIER SO IT CANNOT BE
MISREAD** (math's refutation pass #4 — a defect in a *name*, not in the arithmetic).

Classic Sethi–Ullman assumes the codegen may **swap operands** (`equal ⇒ n+1, else max`) and is
strictly **smaller**: for `a` a leaf and `b` an operation on two leaves, this function gives
`max 1 (1+2) = 3` where classic SU gives `2`. ⇒ ***The classic number is UNREACHABLE here
because `slt` is not commutative, so codegen cannot always swap.*** A reader who trusted a
"Sethi–Ullman" label and "corrected" this formula to the classic one would make it
**UNDER-count**, and Row B would go from true-and-conservative to **FALSE** — with a green
build and a correct-looking citation. The divergence is recorded as a theorem below, not left
in prose. -/
def expCostNoSwap : Exp → Nat
  | .var _ | .const _ | .tt | .ff => 1
  | .add a b | .xor a b | .slt a b => max (expCostNoSwap a) (1 + expCostNoSwap b)

/-- **THE DIVERGENCE FROM CLASSIC SETHI–ULLMAN, AS A FACT.** Math's witness: this function
says 3 where classic SU says 2. Kept as a theorem so the gap cannot be "tidied away" by a
future reader who recognises the shape but not the assumption. -/
theorem expCostNoSwap_exceeds_classic_SU :
    expCostNoSwap (.add (.var 0) (.add (.var 0) (.var 0))) = 3 := by decide

def expMaxNoSwap : Stmt → Nat
  | .skip              => 0
  | .letmut _ _ e body => max (expCostNoSwap e) (expMaxNoSwap body)
  | .assign _ e        => expCostNoSwap e
  | .seq s t           => max (expMaxNoSwap s) (expMaxNoSwap t)
  | .ite c thn els     => max (expCostNoSwap c) (max (expMaxNoSwap thn) (expMaxNoSwap els))
  | .while c body      => max (expCostNoSwap c) (expMaxNoSwap body)

/-- Completeness will read "well-typed AND pool-fitting AND temp-fitting compiles" — three
predicates, and the judgment mentions none of the resources. -/
def fitsAndTyped (poolSize tempBudget : Nat) (p : Stmt) : Bool :=
  wellFormed p && (liveMax p ≤ poolSize) && (expMaxNoSwap p ≤ tempBudget)

/-! ## 7. THE THREE PRE-REGISTERED CONTROLS, plus the folded refutations -/

def acceptProg : Stmt :=
  .letmut 0 .i32 (.const 7)
    (.while (.slt (.var 0) (.const 7))
      (.assign 0 (.xor (.var 0) (.const 1))))

/-- `while 1 { skip }` — the condition is an `i32` where `bool` is demanded. -/
def rejectProg : Stmt := .while (.const 1) .skip

theorem t2_accept : wellFormed acceptProg = true := by decide

theorem t2_reject : wellFormed rejectProg = false := by decide

/-- **POSITIVE CONTROL for the reject.** Swap `const 1` for `tt`, change nothing else, and it
is ACCEPTED — so the rejection is the condition's TYPE, not `while`, not `skip`. Without this,
a checker that rejected every `while` would pass `t2_reject`. -/
theorem t2_reject_is_load_bearing : wellFormed (.while .tt .skip) = true := by decide

theorem t2_slt_condition_accepted :
    wellFormed (.letmut 0 .i32 (.const 0) (.while (.slt (.var 0) (.const 1)) .skip)) = true := by
  decide

/-- **F6 — `bigStep` SHOWN NONEMPTY by explicit derivation.** A relation that steps nothing
turns every downstream row vacuously green. -/
theorem f6_bigStep_inhabited (σ : State) :
    bigStep [] (.seq .skip (.assign 0 (.add (.const 0) (.const 0)))) σ
            (upd σ (slotOf [] 0) (evalE [] σ (.add (.const 0) (.const 0)))) :=
  .seq .skip .assign

theorem f6_bigStep_while_inhabited (σ : State) : bigStep [] (.while .ff .skip) σ σ :=
  .whileF rfl

/-- **F6 POSITIVE CONTROL — a loop that actually ITERATES.** `whileF` alone would be satisfied
by a relation whose loop never enters the body. -/
theorem f6_bigStep_while_iterates (σ : State) :
    bigStep [(0, Ty.i32)] (.while (.xor (.var 0) (.const 1)) (.assign 0 (.const 1)))
            (upd σ 0 0) (upd (upd σ 0 0) 0 1) := by
  refine .whileT ?_ .assign (.whileF ?_)
  · simp [evalE, upd, slotOf, lookLvl]
  · simp [evalE, upd, slotOf, lookLvl]

/-- **MATH'S PASS #1 DEMAND, DISCHARGED.** An exhibited non-trivial witness with the resource
bounds HOLDING, and `liveMax`'s exact value pinned — so a *pessimistic* `liveMax` would fail
this theorem rather than satisfy Row B vacuously. -/
theorem liveMax_witness_nontrivial :
    liveMax acceptProg = 1 ∧ liveMax acceptProg ≤ 1 ∧ fitsAndTyped 1 3 acceptProg = true := by
  refine ⟨by decide, by decide, by decide⟩

/-- The bound must be able to BIND, in both directions. -/
theorem liveMax_binds_both_ways :
    liveMax (.letmut 0 .i32 (.const 0)
              (.letmut 1 .i32 (.const 0) (.letmut 2 .i32 (.const 0) .skip))) = 3
  ∧ fitsAndTyped 3 3 (.letmut 0 .i32 (.const 0)
              (.letmut 1 .i32 (.const 0) (.letmut 2 .i32 (.const 0) .skip))) = true
  ∧ fitsAndTyped 2 3 (.letmut 0 .i32 (.const 0)
              (.letmut 1 .i32 (.const 0) (.letmut 2 .i32 (.const 0) .skip))) = false := by
  refine ⟨by decide, by decide, by decide⟩

/-- **MATH'S PASS #2 WITNESS, MEASURED.** Their program: `liveMax` says one register, the
expression needs three simultaneous intermediates. -/
def mathP : Stmt :=
  .letmut 0 .i32 (.const 0)
    (.assign 0 (.add (.add (.var 0) (.var 0)) (.add (.var 0) (.var 0))))

theorem math_pass2_measured :
    liveMax mathP = 1 ∧ wellFormed mathP = true ∧ expMaxNoSwap mathP = 3 := by
  refine ⟨by decide, by decide, by decide⟩

/-- ⭐ **AND THE REPAIR IS A SECOND TERM, NOT A RESCALING** — proved, because rescaling was the
obvious wrong fix. Neither cost dominates the other, so no function of `liveMax` alone can
express `expMaxNoSwap`. -/
theorem the_two_costs_are_independent :
    (liveMax (.letmut 0 .i32 (.const 0) (.letmut 1 .i32 (.const 0) .skip)) = 2
     ∧ expMaxNoSwap (.letmut 0 .i32 (.const 0) (.letmut 1 .i32 (.const 0) .skip)) = 1)
  ∧ (liveMax mathP = 1 ∧ expMaxNoSwap mathP = 3) := by
  refine ⟨⟨by decide, by decide⟩, ⟨by decide, by decide⟩⟩

/-- **CONTROL: the two rejection causes are DISTINCT and separately characterizable.** Not a
claim of exhaustiveness — math's candidate third cause (instruction memory) is OPEN for Row B. -/
theorem pool_is_separate :
    wellFormed (.letmut 0 .i32 (.const 0) (.letmut 1 .i32 (.const 0) .skip)) = true
  ∧ liveMax (.letmut 0 .i32 (.const 0) (.letmut 1 .i32 (.const 0) .skip)) = 2
  ∧ fitsAndTyped 1 3 (.letmut 0 .i32 (.const 0) (.letmut 1 .i32 (.const 0) .skip)) = false := by
  refine ⟨by decide, by decide, by decide⟩

/-- **CONTROL: a smaller core does not change typing** — the v1.4 requirement as a theorem. -/
theorem typing_is_pool_independent (p : Stmt) (n t m : Nat)
    (h : fitsAndTyped n t p = true) :
    wellFormed p = true ∧ (liveMax p ≤ m → expMaxNoSwap p ≤ t → fitsAndTyped m t p = true) := by
  simp only [fitsAndTyped, Bool.and_eq_true, decide_eq_true_eq] at h
  exact ⟨h.1.1, fun hm ht => by simp [fitsAndTyped, h.1.1, hm, ht]⟩

end SaltWorks.HDL.TinyRustN0
