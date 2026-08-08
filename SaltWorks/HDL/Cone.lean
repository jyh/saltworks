/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.SeamTrace

/-!
# THE CONE LEMMA — a circuit is independent of an input no output's cone reaches

**Why this lemma exists, and why the obvious routes do not reach it.**
`run_congr_on` asks for agreement on every net any gate READS — and an inverter
bank puts EVERY input in some gate's fanin, so its hypothesis is unsatisfiable
for a block that ignores some of its inputs (math measured this on the decoder,
8/7 21:16). `run_agree_of_inputs` (`SeamTrace.lean`) removes the GATE-OUTPUT nets
from the obligation, not unread INPUTS. **This is the missing third thing**, and
it is what a sampled-vs-exhaustive detector needs: an enumeration covers an axis
only if the block cannot read the nets it leaves out.

*Two formulations were built independently. The BACKWARD one asks: which inputs
can net `n` reach? — a reachability closure running against the gate list's
order, whose induction must carry a relation through a list traversed the wrong
way. This file asks* **forwards**: *which nets can input `i` reach?*  The answer is a
**set of nets, transported one gate at a time, in the gate list's own order** —
which is exactly `ssaFrom`'s order and exactly `run`'s order.  The induction is
then the same induction `run` itself is defined by, and the invariant is the
one-liner

> *two environments that agree off the set stay agreeing off the transported
> set.*

The step is an **exact** update, not a monotone one: net `g.out` is in the new
set **iff** `g`'s fanin meets the old set.  A gate whose fanin misses the set
*removes* its output net from the set, because that net's value has just been
overwritten by something independent of `i`.  The kill costs nothing in the
induction (the `n = g.out` branch has to be discharged either way) and it buys
precision that a purely-growing set cannot have — see `cone_kills_redefined`.
-/

namespace SaltWorks.HDL

/-! ## The forward step -/

/-- **One gate's forward transport of a dependency set.**  Net `g.out` is in the
new set exactly when `g` reads something in the old set; every other net keeps
its membership.  The `else`-branch of the `if` is where the *kill* lives: if
`g.out` was in `S` but `g`'s fanin is not, `g.out` leaves. -/
def coneStep (S : Net → Bool) (g : Gate) : Net → Bool :=
  fun n => if n = g.out then g.op.fanin.any S else S n

/-- **The forward dependency cone.**  `cone S gs` is the set of nets whose value
after `run env gs` can depend on the nets in `S`. -/
def cone : (Net → Bool) → List Gate → Net → Bool
  | S, []      => S
  | S, g :: gs => cone (coneStep S g) gs

/-- The cone of a single input net — the object the task names "the cone of `i`". -/
def coneOf (i : Net) (gs : List Gate) : Net → Bool := cone (fun m => m == i) gs

theorem cone_nil (S : Net → Bool) : cone S [] = S := rfl

theorem cone_cons (S : Net → Bool) (g : Gate) (gs : List Gate) :
    cone S (g :: gs) = cone (coneStep S g) gs := rfl

/-- The cone of a concatenation is the cone of the cone — the fold really is a
fold, so a `pre ++ suffix` split of a gate list splits its cone too. -/
theorem cone_append : ∀ (gs hs : List Gate) (S : Net → Bool),
    cone S (gs ++ hs) = cone (cone S gs) hs := by
  intro gs
  induction gs with
  | nil => intro hs S; rfl
  | cons g gs ih =>
    intro hs S
    simp only [List.cons_append, cone_cons]
    exact ih hs (coneStep S g)

/-! ## `List.any`, in the two directions the step needs -/

/-- `any` is false exactly when every element is. Re-derived rather than fished
out of core, because the induction step needs *both* directions and the core
lemma's exact statement shape has moved between toolchains. -/
theorem cone_any_false_iff (S : Net → Bool) :
    ∀ (l : List Net), l.any S = false ↔ ∀ a ∈ l, S a = false := by
  intro l
  induction l with
  | nil => simp
  | cons b t ih =>
    constructor
    · intro h a ha
      cases hb : S b with
      | true => rw [List.any_cons, hb] at h; simp at h
      | false =>
        rw [List.any_cons, hb, Bool.false_or] at h
        rcases List.mem_cons.mp ha with rfl | ht
        · exact hb
        · exact (ih.mp h) a ht
    · intro h
      rw [List.any_cons, h b (by simp), Bool.false_or]
      exact ih.mpr (fun a ha => h a (by simp [ha]))

/-! ## ⭐ THE CONE LEMMA

The whole content of the file. Everything below it is a specialisation. -/

/-- ⭐ **A NET OUTSIDE THE CONE CANNOT SEE THE SET.**  Two environments that
agree everywhere off `S` still agree, after running the gates, at every net off
`cone S gs`.

*The induction is `run`'s own.*  At the cons step there are exactly two cases,
and each is one line of content:

* `n = g.out` — then `n ∉ coneStep S g` says `g`'s fanin misses `S`, so the two
  environments agree on everything `g` reads, so `Op.eval_congr` makes the two
  written values equal;
* `n ≠ g.out` — then membership is unchanged and `upd_of_ne` peels the write off
  both sides.

No well-formedness, no SSA, no length hypothesis, no ordering assumption: the
statement is about an arbitrary gate list. -/
theorem run_agree_off_cone : ∀ (gs : List Gate) (S : Net → Bool) (env₁ env₂ : Env),
    (∀ m, S m = false → env₁ m = env₂ m) →
    ∀ n, cone S gs n = false → run env₁ gs n = run env₂ gs n := by
  intro gs
  induction gs with
  | nil => intro S e₁ e₂ h n hn; exact h n hn
  | cons g gs ih =>
    intro S e₁ e₂ h n hn
    rw [run_cons, run_cons]
    refine ih (coneStep S g) _ _ ?_ n hn
    intro m hm
    by_cases hEq : m = g.out
    · subst hEq
      have hany : g.op.fanin.any S = false := by
        simpa [coneStep] using hm
      have hfan : ∀ a ∈ g.op.fanin, e₁ a = e₂ a :=
        fun a ha => h a ((cone_any_false_iff S g.op.fanin).mp hany a ha)
      rw [upd_self, upd_self]
      exact Op.eval_congr g.op hfan
    · rw [upd_of_ne _ hEq, upd_of_ne _ hEq]
      exact h m (by simpa [coneStep, hEq] using hm)

/-! ## The independence conclusions -/

/-- **A net outside `i`'s cone is independent of `i`**, in the two-environment
form: any two environments differing only at `i` agree there. -/
theorem run_indep_of_net (gs : List Gate) (i : Net) (env₁ env₂ : Env)
    (h : ∀ m, m ≠ i → env₁ m = env₂ m)
    (n : Net) (hn : coneOf i gs n = false) :
    run env₁ gs n = run env₂ gs n := by
  refine run_agree_off_cone gs _ _ _ ?_ n hn
  intro m hm
  exact h m (by simpa using hm)

/-- **A net outside `i`'s cone is independent of `i`**, in the point-update form:
poking net `i` to any value changes nothing there. -/
theorem run_upd_off_cone (gs : List Gate) (env : Env) (i : Net) (b : Bool)
    (n : Net) (hn : coneOf i gs n = false) :
    run (upd env i b) gs n = run env gs n :=
  run_indep_of_net gs i _ _ (fun _ hm => upd_of_ne _ hm) n hn

/-- **A circuit's meaning is independent of an input no output's cone contains.**
The `sem`-level form: the dead-input theorem. -/
theorem sem_indep_of_input (c : Circ) (i : Net) (env : Env) (b : Bool)
    (ho : ∀ n ∈ c.outs, coneOf i c.gates n = false) :
    sem c (upd env i b) = sem c env := by
  simp only [sem]
  exact List.map_congr_left (fun n hn => run_upd_off_cone c.gates env i b n (ho n hn))

/-! ## Structure of the cone -/

/-- The cone only ever grows at gate outputs: a net no gate writes is in the cone
exactly when it started there. -/
theorem cone_of_not_written : ∀ (gs : List Gate) (S : Net → Bool) (n : Net),
    S n = false → (∀ g ∈ gs, g.out ≠ n) → cone S gs n = false := by
  intro gs
  induction gs with
  | nil => intro S n hS _; exact hS
  | cons g gs ih =>
    intro S n hS hg
    rw [cone_cons]
    refine ih (coneStep S g) n ?_ (fun g' hg' => hg g' (by simp [hg']))
    have hne : ¬ (n = g.out) := fun hEq => hg g (by simp) hEq.symm
    simpa [coneStep, hne] using hS

/-- An empty set has an empty cone — the sanity check that the step never
invents dependence out of nothing. -/
theorem cone_of_empty : ∀ (gs : List Gate) (S : Net → Bool),
    (∀ m, S m = false) → ∀ n, cone S gs n = false := by
  intro gs
  induction gs with
  | nil => intro S h n; exact h n
  | cons g gs ih =>
    intro S h n
    rw [cone_cons]
    refine ih (coneStep S g) (fun m => ?_) n
    by_cases hEq : m = g.out
    · subst hEq
      simpa [coneStep] using (cone_any_false_iff S g.op.fanin).mpr (fun a _ => h a)
    · simpa [coneStep, hEq] using h m

/-- The cone is monotone in its seed set. -/
theorem cone_mono : ∀ (gs : List Gate) (S T : Net → Bool),
    (∀ m, S m = true → T m = true) →
    ∀ n, cone S gs n = true → cone T gs n = true := by
  intro gs
  induction gs with
  | nil => intro S T h n hn; exact h n hn
  | cons g gs ih =>
    intro S T h n hn
    rw [cone_cons] at hn ⊢
    refine ih (coneStep S g) (coneStep T g) (fun m hm => ?_) n hn
    by_cases hEq : m = g.out
    · subst hEq
      simp only [coneStep] at hm ⊢
      rcases List.any_eq_true.mp hm with ⟨a, ha, hSa⟩
      exact List.any_eq_true.mpr ⟨a, ha, h a hSa⟩
    · simp only [coneStep, if_neg hEq] at hm ⊢
      exact h m hm

/-- The contrapositive of `cone_mono`, which is the form a caller uses: proving a
net outside a *bigger* cone puts it outside every smaller one. -/
theorem cone_false_mono (gs : List Gate) (S T : Net → Bool)
    (hST : ∀ m, S m = true → T m = true)
    (n : Net) (h : cone T gs n = false) : cone S gs n = false := by
  cases hc : cone S gs n with
  | false => rfl
  | true => rw [cone_mono gs S T hST n hc] at h; exact Bool.noConfusion h

/-! ## The dense-SSA corollary — the cone respects the base -/

/-- **Under dense SSA, nothing below the base can enter the cone.**  `ssaFrom`
puts every gate output at or above `base`, so the gate list writes nothing below
it, so `cone_of_not_written` applies to every such net at once.

This is the shape the seam wants: the network's primary inputs and its state
nets all live below `bnCCoreIn`, so a fact about them survives the whole gate
list untouched. -/
theorem cone_below_base (gs : List Gate) (base : Nat) (hssa : ssaFrom base gs = true)
    (S : Net → Bool) (n : Net) (hn : n < base) (hS : S n = false) :
    cone S gs n = false := by
  refine cone_of_not_written gs S n hS (fun g hg hEq => ?_)
  have hge : base ≤ g.out := ssaFrom_out_ge gs base hssa g hg
  rw [hEq] at hge
  exact absurd hge (Nat.not_le.mpr hn)

/-- The same, for a single input: an input net below the base is outside the cone
of any *other* net below the base. -/
theorem coneOf_below_base (gs : List Gate) (base : Nat) (hssa : ssaFrom base gs = true)
    (i n : Net) (hn : n < base) (hne : n ≠ i) : coneOf i gs n = false :=
  cone_below_base gs base hssa _ n hn (by simpa using hne)

/-! ## The definition is not vacuous, and the kill is not decoration -/

/-- A three-gate example: net 3 is reachable from input 0, nets 1 and 4 are not. -/
def coneEx : List Gate := [⟨2, .and 0 1⟩, ⟨3, .not 2⟩, ⟨4, .const true⟩]

theorem coneEx_cone :
    (coneOf 0 coneEx 0, coneOf 0 coneEx 1, coneOf 0 coneEx 2,
     coneOf 0 coneEx 3, coneOf 0 coneEx 4)
      = (true, false, true, true, false) := by decide

/-- ⛔ **A NET INSIDE THE CONE GENUINELY MOVES** — so the cone is not an
over-approximation that has been proved trivially by being everything. -/
theorem coneEx_inside_is_live :
    run (upd (fun _ => true) 0 false) coneEx 3 ≠ run (fun _ => true) coneEx 3 := by
  decide

/-- ⛔ **THE KILL IS LOAD-BEARING.**  A gate that redefines a net already in the
cone, reading nothing in the cone, takes that net back *out* — and it must, since
the net's value is now a constant.  A purely-growing forward analysis would
report net 2 as dependent on input 0 and would be wrong. -/
def coneKill : List Gate := [⟨2, .and 0 1⟩, ⟨2, .const false⟩]

theorem cone_kills_redefined : coneOf 0 coneKill 2 = false := by decide

theorem cone_kill_is_sound (env : Env) (b : Bool) :
    run (upd env 0 b) coneKill 2 = run env coneKill 2 :=
  run_upd_off_cone coneKill env 0 b 2 cone_kills_redefined

/-! ## ⚠️ THE FUNCTION-VALUED CONE CANNOT BE EVALUATED — MEASURED, TWICE

`cone` is a **tower of closures**: `cone S₀ gs` is `coneStep (… (coneStep S₀ g₁) …) g₈₁₆`.
Querying it descends the tower to the level that writes the queried net, then
spawns **one query per fanin**, each of which descends again — a DAG walk with no
memoisation.  Both halves of that were measured on `bnCCore` (816 gates), and
they are *different* failures:

| probe | result |
|---|---|
| `coneOf 0 bnCCore.gates 0 = true` by `decide` (zero fanout — net 0 is written by no gate, so this is a pure 816-deep descent) | **`maximum recursion depth`, 8 s** |
| `coneOf 0 bnCCore.gates 920 = true` by `decide` (net 920 is the last gate, so the full DAG walk runs) | **`maximum recursion depth`, 292 s** |

The first says the closure tower is deeper than the default `maxRecDepth` (512)
*before any fanout at all*, so raising the option is a prerequisite, not a fix.
The second says that with the fanout in play the reducer burns 292 s of work
before hitting the same wall — 36× the no-fanout cost, which is the
memoisation-free walk showing itself.  **Neither was disambiguated further, and
neither needs to be**, because:

The same set carried as a **list** is a linear fold, and `coneL_contains` says the
two agree pointwise.  All three `coneL` certificates below — including two full
816-gate folds — elaborate and kernel-check inside a **7 s** whole-file run.

⭐ **Prove with `cone`, compute with `coneL`.** -/

/-- The list-carried forward step.  Same content as `coneStep`: cons on a hit,
**filter the output net out** on a miss (that is the kill). -/
def coneLStep (S : List Net) (g : Gate) : List Net :=
  if g.op.fanin.any (fun a => S.contains a) then g.out :: S
  else S.filter (fun m => m != g.out)

/-- The list-carried forward cone: a left fold over the gate list, in the gate
list's own order. -/
def coneL : List Net → List Gate → List Net
  | S, []      => S
  | S, g :: gs => coneL (coneLStep S g) gs

theorem coneL_nil (S : List Net) : coneL S [] = S := rfl

theorem coneL_cons (S : List Net) (g : Gate) (gs : List Gate) :
    coneL S (g :: gs) = coneL (coneLStep S g) gs := rfl

/-- Filtering one net out of a list, at the level of `contains`. -/
theorem contains_filter_ne (x n : Net) (l : List Net) :
    (l.filter (fun m => m != x)).contains n = (!(n == x) && l.contains n) := by
  by_cases hx : n = x
  · subst hx; simp [List.mem_filter]
  · simp [List.mem_filter, hx]

/-- The list step and the function step agree pointwise. -/
theorem coneLStep_contains (S : List Net) (g : Gate) (n : Net) :
    (coneLStep S g).contains n = coneStep (fun m => S.contains m) g n := by
  simp only [coneLStep, coneStep]
  cases hany : g.op.fanin.any (fun a => S.contains a) with
  | true =>
    simp only [if_true]
    by_cases hn : n = g.out
    · subst hn; simp
    · simp [hn]
  | false =>
    simp only [Bool.false_eq_true, if_false]
    by_cases hn : n = g.out
    · subst hn; simp
    · simp [hn]

/-- ⭐ **THE LIST CONE IS THE CONE.**  Compute with the left fold, reason with the
closure — the two are the same set at every net. -/
theorem coneL_contains : ∀ (gs : List Gate) (S : List Net) (n : Net),
    (coneL S gs).contains n = cone (fun m => S.contains m) gs n := by
  intro gs
  induction gs with
  | nil => intro S n; rfl
  | cons g gs ih =>
    intro S n
    rw [coneL_cons, cone_cons, ih]
    have hfun : (fun m => (coneLStep S g).contains m) = coneStep (fun m => S.contains m) g := by
      funext m; exact coneLStep_contains S g m
    rw [hfun]

/-- The computable cone of one input net. -/
def coneOfL (i : Net) (gs : List Gate) : List Net := coneL [i] gs

theorem coneOfL_contains (i : Net) (gs : List Gate) (n : Net) :
    (coneOfL i gs).contains n = coneOf i gs n := by
  rw [coneOfL, coneL_contains]
  have hfun : (fun m => ([i] : List Net).contains m) = (fun m => m == i) := by
    funext m
    apply Bool.eq_iff_iff.mpr
    simp
  rw [hfun, coneOf]

/-- ⭐ **THE FORM A CALLER USES.**  `hn` is a `decide`-able Boolean check on a
concrete gate list; the conclusion is independence of input `i`. -/
theorem run_upd_off_coneL (gs : List Gate) (env : Env) (i : Net) (b : Bool)
    (n : Net) (hn : (coneOfL i gs).contains n = false) :
    run (upd env i b) gs n = run env gs n :=
  run_upd_off_cone gs env i b n (by rwa [coneOfL_contains] at hn)

theorem coneEx_coneL : coneOfL 0 coneEx = [3, 2, 0] := by decide

/-- Scale probe: the fold really does run in the kernel on a real circuit's gate
list.  `0` is below `ceCcore.nIn`, so no gate can ever filter it out — the answer
is known in advance and the point of the theorem is the **cost**, not the fact. -/
theorem coneOfL_ceCcore_runs : (coneOfL 0 ceCcore.gates).contains 0 = true := by
  decide +kernel

/-- SCALE PROBE at the real thing: `bnCCore` is 816 gates, and `bnCRst = 0` is
read by every one of the 24 elements, so this fold grows the set to the whole
circuit and scans it once per gate.  Known-true in advance (`bnCCore` is SSA from
105, so no gate can ever filter net 0 out); what is being measured is whether the
kernel can afford the fold at all. -/
theorem coneOfL_bnCCore_runs : (coneOfL 0 bnCCore.gates).contains 0 = true := by
  decide +kernel

/-- ⭐ **THE MACHINERY DOING REAL WORK ON THE REAL CIRCUIT.**  Net `101` is
`bnCState 23`, the first state bit of the *last* comparator element; net `105` is
`bnCOff 0`, the first gate of the *first* element.  `bnCSigma` hands net 101 to
element 23 and to nothing else, so it cannot reach element 0 — and the forward
cone says so by construction, with no hand argument about who reads what. -/
theorem coneOfL_bnCState23_misses_elem0 :
    (coneOfL 101 bnCCore.gates).contains 105 = false := by
  decide +kernel

/-- …and the cone is not empty: net 101 is in its own cone, so the `false` above
is a real miss and not a fold that returned nothing. **Stated separately rather
than as a pair with the line above** — pairing them forces the elaborator to
`whnf` an 816-gate term through `Prod.snd` at the use site, which is a
`maximum recursion depth` (trap 6, measured here). -/
theorem coneOfL_bnCState23_hits_itself :
    (coneOfL 101 bnCCore.gates).contains 101 = true := by
  decide +kernel

/-- The semantic payoff: **element 0's first gate cannot see element 23's first
state bit**, for every environment and every value poked onto that state bit.
Every argument is explicit so that the hypothesis matches *syntactically* and no
defeq check ever looks inside `bnCCore.gates`. -/
theorem bnCCore_elem0_indep_of_elem23_state (env : Env) (b : Bool) :
    run (upd env 101 b) bnCCore.gates 105 = run env bnCCore.gates 105 :=
  run_upd_off_coneL bnCCore.gates env 101 b 105 coneOfL_bnCState23_misses_elem0

#audit_axioms coneOfL_bnCCore_runs coneOfL_bnCState23_misses_elem0
#audit_axioms coneOfL_bnCState23_hits_itself bnCCore_elem0_indep_of_elem23_state
#audit_axioms coneLStep coneL coneL_nil coneL_cons contains_filter_ne
#audit_axioms coneLStep_contains coneL_contains coneOfL coneOfL_contains
#audit_axioms run_upd_off_coneL coneEx_coneL coneOfL_ceCcore_runs

#audit_axioms coneStep cone coneOf cone_nil cone_cons cone_append
#audit_axioms cone_any_false_iff run_agree_off_cone
#audit_axioms run_indep_of_net run_upd_off_cone sem_indep_of_input
#audit_axioms cone_of_not_written cone_of_empty cone_mono cone_false_mono
#audit_axioms cone_below_base coneOf_below_base
#audit_axioms coneEx coneEx_cone coneEx_inside_is_live
#audit_axioms coneKill cone_kills_redefined cone_kill_is_sound

end SaltWorks.HDL
