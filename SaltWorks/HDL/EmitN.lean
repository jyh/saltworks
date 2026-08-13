/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Dense
import SaltWorks.Silicon.Equiv.BitSliced

/-!
# T2 — `emitN`, and the theorem that the netlist normal form means what `Circ` means

`SaltWorks.Silicon.Netlist` is **positional**: net `k` is defined by the `k`-th
gate, and the primary inputs are gates too (`Gate.inp i` at position `i`).
`Circ` is **nominal**: every gate names the net it defines, which is what makes
dead-net elimination a `List.filter` with no renumbering (`Opt.lean`).

Translating between the two is, in general, a renaming, and a renaming is the
expensive proof. `Dense.lean` is the escape: a circuit is *dense* when gate `i`
defines net `nIn + i`, and then the explicit name of every net already **is** its
positional index. `emitN` is a structure-preserving map with no renaming at all,
and this file's induction is four cases long.

## The precondition, and why it is not `dense` alone

`Circ.dense` pins where each gate WRITES. It says nothing about where a gate
READS, and the two evaluators disagree exactly there: a `Circ` gate that reads an
undefined net reads the input valuation (`sem` is total — `Sem.lean`), while the
netlist reads `List.getD`'s `false`. `denseButUnordered` below is dense, and its
netlist and its `sem` differ — kernel-checked, so this is a fact rather than a
caveat.

So the emission precondition is `Circ.ssa`: dense **and** each gate reads only
nets already defined, **and** every primary output names a net that exists. It is
a `Bool`, so a concrete circuit discharges it by `decide +kernel`, and it is
extrinsic — the same discipline as `Circ.wf` and `Circ.dense`. `ssa` implies
`dense` (`Circ.dense_of_ssa`), so nothing landed is orphaned by it.

## The `opt` trap, and the third answer to it

`Dense.lean` found that `opt` does **not** preserve density: dead-net elimination
filters gates out, so survivors keep their old NAMES while their POSITIONS shift.
It offered two answers — emit before `opt`, or follow `opt` with a densifying
renumber (the expensive proof). There is a third, and it is the move `dce`
already makes on itself: **CHECK**. `emitPipeline` optimizes, tests `ssa` on the
result, and falls back to the unoptimized circuit when `opt` has broken it.
`emitPipeline_sem` holds either way, so correctness never depends on which
branch was taken — a bug in the check can cost optimization, it cannot cost
soundness.

## What is NOT claimed

`emitN` is the seam to leg 3's checker, not to Verilog: `emitV` remains
UNTRUSTED by design. And the densifying renumber is still unwritten — the open
item is stated at `emitPipeline`, with its price.
-/

namespace SaltWorks.HDL

/-! ## Dense SSA, in the form the induction consumes

`Circ.dense` is positional (`getD i`), which is the right shape for a `decide`
block and the wrong shape for an induction over the gate list. `ssaFrom` is the
same property written recursively, so it *is* the induction hypothesis. -/

/-- `ssaFrom base gs`: gate `i` of `gs` defines net `base + i` and reads only
nets below its own position — dense SSA, starting at net `base`. -/
def ssaFrom (base : Nat) : List Gate → Bool
  | []      => true
  | g :: gs => (g.out == base) && g.op.fanin.all (fun a => a < base) && ssaFrom (base + 1) gs

/-- **The emission precondition.** Gates are dense SSA from `nIn`, and every
primary output names a net the netlist will actually contain. -/
def Circ.ssa (c : Circ) : Bool :=
  ssaFrom c.nIn c.gates && c.outs.all (fun n => n < c.nIn + c.gates.length)

/-! ### EXTENT — the two halves `Compose.lean`'s siblings do not carry

`ssaFrom_out_ge` (outputs at or above the base) and `ssaFrom_defined` live in
`Compose.lean`. **They sit HERE instead, beside `ssaFrom` itself, because
`Decoder.lean` imports this file and NOT `Compose.lean`** — a consumer that cannot
reach a lemma has to restate the fact as a literal, which is exactly the debt these
retire. *Density says WHERE gate `k` goes; these say HOW MANY there are, so together
they pin a net layout with no net number in either statement.*

Drafted by the math seat (`ScratchD2math13.lean`, kernel-green, axiom-clean) at the
compiler seat's request; landed here by the owning seat, helm order 08/13 05:36. -/

/-- Every gate output is strictly below `base + length` — the upper bound whose
absence left every cut-site fact pinned to a literal. Mirrors `ssaFrom_out_ge`'s
induction exactly. -/
theorem ssaFrom_out_lt : ∀ (gs : List Gate) (base : Nat), ssaFrom base gs = true →
    ∀ g ∈ gs, g.out < base + gs.length := by
  intro gs
  induction gs with
  | nil => intro base _ g hg; simp at hg
  | cons g gs ih =>
    intro base hssa x hx
    simp only [ssaFrom, Bool.and_eq_true, beq_iff_eq] at hssa
    obtain ⟨⟨hout, _⟩, hrest⟩ := hssa
    -- ⚠️⚠️ `unfold Net at <hyp> ⊢` IS LOAD-BEARING, AND `at <hyp>` IS THE HALF THAT
    -- IS EASY TO MISS. `Gate.out : Net`, and although `abbrev Net := Nat` is
    -- reducible, `omega` does not unfold it — it reports "No usable constraints"
    -- on goals as trivial as `x.out + 0 = x.out`.
    -- ⛔ UNFOLDING THE GOAL ALONE FAILS QUIETLY IN THE WORST WAY: omega then parses
    -- the goal, prints a plausible counterexample, and SILENTLY IGNORES every
    -- `Net`-typed hypothesis — so a true statement looks FALSE rather than
    -- under-hypothesised. Measured over six probe forms by the math seat, at a cost
    -- of two builds; a `(· : Nat)` ascription does NOT help (`Net` is an abbrev, so
    -- it is a no-op). 📌 Very likely why this layer proves so much by
    -- `decide +kernel`: the tactic structural induction needs is blind here.
    have hlen : (g :: gs).length = gs.length + 1 := rfl
    rcases List.mem_cons.mp hx with h | h
    · subst h
      rw [hlen]; unfold Net at hout ⊢; omega
    · have hlt := ih (base + 1) hrest x h
      rw [hlen]; unfold Net at hlt ⊢; omega

/-- Every net in `[base, base + length)` IS some gate's output — density in the
surjective direction. **This is what makes "is net `n` occupied?" answerable without
naming a number.** -/
theorem ssaFrom_out_surj : ∀ (gs : List Gate) (base : Nat), ssaFrom base gs = true →
    ∀ n, base ≤ n → n < base + gs.length → ∃ g ∈ gs, g.out = n := by
  intro gs
  induction gs with
  | nil => intro base _ n _ hlt; simp only [List.length_nil] at hlt; omega
  | cons g gs ih =>
    intro base hssa n hge hlt
    simp only [ssaFrom, Bool.and_eq_true, beq_iff_eq] at hssa
    obtain ⟨⟨hout, _⟩, hrest⟩ := hssa
    by_cases hn : n = base
    · exact ⟨g, List.mem_cons_self .., by rw [hout, hn]⟩
    · have hge' : base + 1 ≤ n := by omega
      have hlt' : n < base + 1 + gs.length := by
        simp only [List.length_cons] at hlt; omega
      obtain ⟨x, hx, hxout⟩ := ih (base + 1) hrest n hge' hlt'
      exact ⟨x, List.mem_cons_of_mem _ hx, hxout⟩

#audit_axioms ssaFrom_out_lt
#audit_axioms ssaFrom_out_surj

/-! ## The translation -/

/-- One `Circ` operation as a netlist gate. Net names are carried through
unchanged — that is the whole content of density. -/
def emitOp : Op → Silicon.Gate
  | .const b => .const b
  | .not a   => .not a
  | .and a b => .and a b
  | .or  a b => .or  a b
  | .xor a b => .xor a b

/-- **`emitN`.** The primary inputs become the first `nIn` netlist gates — net
`i` is `inp i` — and then each `Circ` gate in order. Under `ssa` this is the
identity on net names. -/
def emitN (c : Circ) : Silicon.Netlist :=
  (List.range c.nIn).map Silicon.Gate.inp ++ c.gates.map (fun g => emitOp g.op)

/-! ## Plumbing

Four small lemmas about the netlist evaluator. `getD_snoc` is a re-derivation:
the Silicon seat's copy is `private`, and it is eight lines, so this file
re-proves rather than reaching across the seam for it. -/

/-- Reading past a one-element extension: at the new index you get the new
element, everywhere else the original list answers — including out of range,
where both sides give the default. -/
theorem getD_snoc {α : Type _} (l : List α) (x d : α) :
    ∀ k, (l ++ [x]).getD k d = if k = l.length then x else l.getD k d := by
  induction l with
  | nil => intro k; cases k <;> simp
  | cons a t ih =>
    intro k
    cases k with
    | zero => simp
    | succ m => simpa using ih m

theorem runP_append (ins : Nat → Bool) :
    ∀ (gs hs : Silicon.Netlist) (env : List Bool),
      Silicon.runP ins env (gs ++ hs) = Silicon.runP ins (Silicon.runP ins env gs) hs := by
  intro gs
  induction gs with
  | nil => intro hs env; rfl
  | cons g gs ih => intro hs env; exact ih hs (env ++ [Silicon.stepP ins env g])

/-- The input prefix evaluates to the input valuation, in port order. -/
theorem runP_inps (ins : Nat → Bool) :
    ∀ (n : Nat) (env : List Bool),
      Silicon.runP ins env ((List.range n).map Silicon.Gate.inp) = env ++ (List.range n).map ins := by
  intro n
  induction n with
  | zero => intro env; simp [Silicon.runP]
  | succ n ih =>
    intro env
    rw [List.range_succ, List.map_append, runP_append, ih]
    simp [Silicon.runP, Silicon.stepP]

theorem getD_map_range (f : Nat → Bool) :
    ∀ (n k : Nat), k < n → ((List.range n).map f).getD k false = f k := by
  intro n
  induction n with
  | zero => intro k hk; omega
  | succ n ih =>
    intro k hk
    rw [List.range_succ, List.map_append]
    simp only [List.map_cons, List.map_nil]
    rw [getD_snoc]
    simp only [List.length_map, List.length_range]
    by_cases hkn : k = n
    · subst hkn; rw [if_pos rfl]
    · rw [if_neg hkn]; exact ih k (by omega)

/-- **One gate, translated.** A netlist gate on an agreeing environment computes
what the `Circ` operation computes — provided the operation reads only nets the
two environments agree on, which is exactly what `ssaFrom` guarantees. -/
theorem stepP_emitOp {ins : Nat → Bool} {envP : List Bool} {envC : Env} {base : Nat}
    (hag : ∀ k, k < base → envP.getD k false = envC k) :
    ∀ (o : Op), o.fanin.all (fun a => a < base) = true →
      Silicon.stepP ins envP (emitOp o) = o.eval envC := by
  intro o
  cases o with
  | const b => intro _; simp [emitOp, Silicon.stepP, Op.eval]
  -- NB: `simp` must NOT be let near these goals. It normalises `envP.getD a false`
  -- into the `getElem?` form `envP[a]?.getD false`, after which `hag` — stated with
  -- `List.getD` — no longer matches, and the rewrite silently does nothing. The
  -- first version of this proof failed exactly there, and Lean said so in a
  -- warning ("This simp argument is unused: hag a ha") rather than in the error.
  -- `show` puts each goal in the shape `hag` is stated in, and `rw` then bites.
  | not a =>
    intro h
    have ha : a < base := by simpa [Op.fanin] using h
    -- The parentheses around the LHS are LOAD-BEARING: `show !A = !B` parses as
    -- `!(A = !B)`, coercing the equation itself to `Bool` via `decide`. The `&&`
    -- cases below are safe only because their left sides were already bracketed.
    show (!(envP.getD a false)) = (!(envC a))
    rw [hag a ha]
  | and a b =>
    intro h
    simp only [Op.fanin, List.all_cons, List.all_nil, Bool.and_true, Bool.and_eq_true,
      decide_eq_true_eq] at h
    show (envP.getD a false && envP.getD b false) = (envC a && envC b)
    rw [hag a h.1, hag b h.2]
  | or a b =>
    intro h
    simp only [Op.fanin, List.all_cons, List.all_nil, Bool.and_true, Bool.and_eq_true,
      decide_eq_true_eq] at h
    show (envP.getD a false || envP.getD b false) = (envC a || envC b)
    rw [hag a h.1, hag b h.2]
  | xor a b =>
    intro h
    simp only [Op.fanin, List.all_cons, List.all_nil, Bool.and_true, Bool.and_eq_true,
      decide_eq_true_eq] at h
    show (envP.getD a false ^^ envP.getD b false) = (envC a ^^ envC b)
    rw [hag a h.1, hag b h.2]

/-! ## THE INDUCTION

Four cases, one of them `nil`. This is what density is *for*: without it the
same statement carries an index-translation function and its inverse, and every
line below acquires a renaming side condition. -/

/-- **The invariant.** A netlist environment of length `base` that agrees with a
`Circ` environment below `base` keeps agreeing, net for net, as both evaluators
run the same dense-SSA gate list. -/
theorem runP_ssaFrom (ins : Env) :
    ∀ (gs : List Gate) (base : Nat) (envP : List Bool) (envC : Env),
      envP.length = base →
      (∀ k, k < base → envP.getD k false = envC k) →
      ssaFrom base gs = true →
      ∀ k, k < base + gs.length →
        (Silicon.runP ins envP (gs.map (fun g => emitOp g.op))).getD k false = run envC gs k := by
  intro gs
  induction gs with
  | nil =>
    intro base envP envC _ hag _ k hk
    simpa [Silicon.runP] using hag k (by simpa using hk)
  | cons g gs ih =>
    intro base envP envC hlen hag hssa k hk
    simp only [ssaFrom, Bool.and_eq_true] at hssa
    obtain ⟨⟨hout, hfan⟩, hrest⟩ := hssa
    have hout' : g.out = base := by simpa using hout
    have hstep : Silicon.stepP ins envP (emitOp g.op) = g.op.eval envC :=
      stepP_emitOp hag g.op hfan
    have hlen' : (envP ++ [Silicon.stepP ins envP (emitOp g.op)]).length = base + 1 := by
      simp [hlen]
    have hag' : ∀ j, j < base + 1 →
        (envP ++ [Silicon.stepP ins envP (emitOp g.op)]).getD j false
          = upd envC g.out (g.op.eval envC) j := by
      intro j hj
      rw [getD_snoc, hlen]
      by_cases hjb : j = base
      · subst hjb
        rw [if_pos rfl, hout', upd_self, hstep]
      · rw [if_neg hjb, upd_of_ne _ (by rw [hout']; exact hjb)]
        exact hag j (by omega)
    have hk' : k < (base + 1) + gs.length := by
      simp only [List.length_cons] at hk; omega
    exact ih (base + 1) _ _ hlen' hag' hrest k hk'

/-! ## T2 -/

/-- **T2 — `emitN_sem`.** The netlist normal form's evaluator agrees with `sem`,
output for output, at every input valuation.

The one hypothesis is `Circ.ssa`, a `Bool`, discharged for every construction in
this leg by `decide +kernel` below. -/
theorem emitN_sem (c : Circ) (h : c.ssa = true) (ins : Env) :
    c.outs.map (fun n => (Silicon.runP ins [] (emitN c)).getD n false) = sem c ins := by
  rw [Circ.ssa, Bool.and_eq_true] at h
  obtain ⟨hgates, houts⟩ := h
  have hlen0 : ((List.range c.nIn).map ins).length = c.nIn := by simp
  have key : ∀ k, k < c.nIn + c.gates.length →
      (Silicon.runP ins [] (emitN c)).getD k false = run ins c.gates k := by
    intro k hk
    rw [emitN, runP_append, runP_inps]
    simpa using
      runP_ssaFrom ins c.gates c.nIn ((List.range c.nIn).map ins) ins hlen0
        (getD_map_range ins c.nIn) hgates k hk
  simp only [sem]
  refine List.map_congr_left (fun n hn => ?_)
  exact key n (by simpa using List.all_eq_true.mp houts n hn)

/-! ## `ssa` implies the landed `dense` — nothing is orphaned -/

theorem ssaFrom_out :
    ∀ (gs : List Gate) (base i : Nat), ssaFrom base gs = true → i < gs.length →
      (gs.getD i default).out = base + i := by
  intro gs
  induction gs with
  | nil => intro base i _ hi; simp at hi
  | cons g gs ih =>
    intro base i hssa hi
    simp only [ssaFrom, Bool.and_eq_true] at hssa
    obtain ⟨⟨hout, _⟩, hrest⟩ := hssa
    cases i with
    | zero => simpa using hout
    | succ m =>
      have hm : m < gs.length := by simp only [List.length_cons] at hi; omega
      have hcons : (g :: gs).getD (m + 1) default = gs.getD m default := by simp [List.getD]
      rw [hcons, ih (base + 1) m hrest hm]
      -- `omega` DIES here on a goal it can obviously do (`base + 1 + m = base + (m+1)`),
      -- because `Gate.out : Net` types the equation as `Net`, and omega's preprocessing
      -- is syntactic in the type even though `Net` is a reducible abbrev for `Nat`.
      -- Same defect `Banyan.lean:68` records for `<` facts. Restating at `Nat` first
      -- is the fix; it is not cosmetic, the direct call FAILS.
      have harith : base + 1 + m = base + (m + 1) := by omega
      exact harith

/-- The emission precondition is a strengthening of the landed density
predicate, not a competitor to it. -/
theorem Circ.dense_of_ssa {c : Circ} (h : c.ssa = true) : c.dense = true := by
  rw [Circ.ssa, Bool.and_eq_true] at h
  rw [Circ.dense, List.all_eq_true]
  intro i hi
  simpa using ssaFrom_out c.gates c.nIn i h.1 (List.mem_range.mp hi)

/-! ## The `opt` trap, and the validated pipeline -/

/-- `opt` never touches the port list — it filters gates. -/
theorem opt_outs (c : Circ) : (opt c).outs = c.outs := by
  rw [opt, dce]; split <;> rfl

/-- **The emission pipeline, validated.** Optimize; test `ssa` on the result;
fall back to the unoptimized circuit if `opt` has broken it.

This is the third answer to `Dense.lean`'s trap, and it is the move `dce` makes
on itself one level up: rather than *prove* that `opt` preserves density (it does
not) or *renumber* after it (the expensive proof, still unwritten — it needs an
index-translation function, its inverse, and a renaming lemma on `run`), `opt` is
applied exactly when the property it must preserve is observed to hold. -/
def emitPipeline (c : Circ) : Silicon.Netlist :=
  if (opt c).ssa then emitN (opt c) else emitN c

/-- **The pipeline is correct on both branches**, so soundness does not depend on
which one was taken. A bug in the check costs optimization; it cannot cost
correctness. -/
theorem emitPipeline_sem (c : Circ) (h : c.ssa = true) (ins : Env) :
    c.outs.map (fun n => (Silicon.runP ins [] (emitPipeline c)).getD n false) = sem c ins := by
  rw [emitPipeline]
  split
  · next hh =>
    have hopt := emitN_sem (opt c) hh ins
    rw [opt_outs] at hopt
    rw [hopt, opt_sem]
  · exact emitN_sem c h ins

/-! ## The seam, concretely

`emitN halfAdder` is written out in full so that the leg-2/leg-3 interface is
pinned by a kernel-checked value and not only by a theorem. -/

theorem emitN_halfAdder :
    emitN halfAdder = [.inp 0, .inp 1, .xor 0 1, .and 0 1] := by decide +kernel

/-! ## Every construction in this leg is emittable — kernel-checked -/

theorem halfAdder_ssa : halfAdder.ssa = true := by decide +kernel
theorem withDead_ssa : withDead.ssa = true := by decide +kernel
theorem xorA_ssa : xorA.ssa = true := by decide +kernel
theorem xorB_ssa : xorB.ssa = true := by decide +kernel
theorem xorC_ssa : xorC.ssa = true := by decide +kernel
theorem xorPrevCore_ssa : xorPrevCore.ssa = true := by decide +kernel

/-- The one that matters: the 72-gate 8×8 fabric — the tapeout candidate — is
emittable, so T2 applies to the artifact leg 3 actually checks. -/
theorem fabric3_ssa : (fabric 3).ssa = true := by decide +kernel

/-! ## Non-vacuity — every conjunct of the precondition, violated on purpose

A precondition nobody can violate proves nothing, and `emitN_sem` would be
satisfied by a circuit with no outputs. `Circ.ssa` has three conjuncts, and each
gets a circuit below that violates **only** that one and on which the two
evaluators then genuinely disagree: `opt withMidDead` (density), `denseButUnordered`
(fanin ordering), `outOfRange` (the port list). All are `decide +kernel`
refutations, not warnings. -/

/-- Dense, well-named, and it reads a net that does not exist yet. -/
def denseButUnordered : Circ where
  nIn   := 1
  gates := [⟨1, .not 5⟩]
  outs  := [1]

/-- **Density is not the emission precondition.** This circuit is dense and is
not `ssa`; `wf` rejects it too, which is why `ssa` is a strengthening of the pair
rather than a new assumption. -/
theorem denseButUnordered_dense_not_ssa :
    (denseButUnordered.dense, denseButUnordered.ssa, denseButUnordered.wf) = (true, false, false) := by
  decide +kernel

/-- …and the two evaluators really do disagree on it: `sem` reads the input
valuation at net 5, the netlist reads `getD`'s `false`. Emitting a dense
non-`ssa` circuit is wrong, not merely unproved. -/
theorem denseButUnordered_emitN_wrong :
    denseButUnordered.outs.map
        (fun n => (Silicon.runP (fun _ => true) [] (emitN denseButUnordered)).getD n false)
      ≠ sem denseButUnordered (fun _ => true) := by
  decide +kernel

/-- **The `opt` trap, at the emission boundary.** `withMidDead` is emittable;
`opt withMidDead` is not, because dead-net elimination shifted a survivor's
position out from under its name. -/
theorem withMidDead_ssa_opt_not :
    (withMidDead.ssa, (opt withMidDead).ssa) = (true, false) := by decide +kernel

/-- …and emitting the optimized circuit anyway gives the WRONG answer at the
all-false valuation: output net 4 no longer exists in the netlist, so the
positional read returns `false` where `sem` returns `true`. This is the
`emitPipeline` check earning its keep. -/
theorem emitN_after_opt_wrong :
    (opt withMidDead).outs.map
        (fun n => (Silicon.runP (bitsOf 0) [] (emitN (opt withMidDead))).getD n false)
      ≠ sem (opt withMidDead) (bitsOf 0) := by
  decide +kernel

/-- Perfect dense SSA in the gates, and a port list that names a net the netlist
does not contain. -/
def outOfRange : Circ where
  nIn   := 1
  gates := []
  outs  := [7]

/-- **The third conjunct is load-bearing too**, and this is the exhibit that says
so. `ssaFrom` alone passes this circuit; `Circ.ssa` rejects it on the port list —
which is the conjunct that would be easiest to drop as bureaucratic. -/
theorem outOfRange_ssaFrom_but_not_ssa :
    (ssaFrom outOfRange.nIn outOfRange.gates, outOfRange.ssa) = (true, false) := by
  decide +kernel

/-- …and dropping it is not free: `sem` reads the input valuation at net 7, the
netlist reads past the end of its environment. Every conjunct of the emission
precondition now has a kernel-checked circuit that violates only it. -/
theorem outOfRange_emitN_wrong :
    outOfRange.outs.map
        (fun n => (Silicon.runP (fun _ => true) [] (emitN outOfRange)).getD n false)
      ≠ sem outOfRange (fun _ => true) := by
  decide +kernel

/-- The pipeline takes the fallback branch here and is correct anyway — the
`emitPipeline_sem` guarantee, on the circuit that breaks the naive one. -/
theorem emitPipeline_withMidDead :
    withMidDead.outs.map
        (fun n => (Silicon.runP (bitsOf 0) [] (emitPipeline withMidDead)).getD n false)
      = sem withMidDead (bitsOf 0) := by
  decide +kernel

#audit_axioms ssaFrom Circ.ssa emitOp emitN emitPipeline
#audit_axioms getD_snoc runP_append runP_inps getD_map_range stepP_emitOp
#audit_axioms runP_ssaFrom
#audit_axioms emitN_sem
#audit_axioms ssaFrom_out Circ.dense_of_ssa
#audit_axioms opt_outs emitPipeline_sem
#audit_axioms emitN_halfAdder
#audit_axioms halfAdder_ssa withDead_ssa xorA_ssa xorB_ssa xorC_ssa xorPrevCore_ssa fabric3_ssa
#audit_axioms denseButUnordered_dense_not_ssa denseButUnordered_emitN_wrong
#audit_axioms outOfRange outOfRange_ssaFrom_but_not_ssa outOfRange_emitN_wrong
#audit_axioms withMidDead_ssa_opt_not emitN_after_opt_wrong emitPipeline_withMidDead

end SaltWorks.HDL
