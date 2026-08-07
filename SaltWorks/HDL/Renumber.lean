/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.EmitN

/-!
# The densifying renumber — ALL FIVE OBLIGATIONS

`Dense.lean` found that `opt` does not preserve density: dead-net elimination
filters gates out, so survivors keep their old NAMES while their POSITIONS
shift. `EmitN.lean` answered by CHECKING (`emitPipeline` falls back when `opt`
breaks density). That is sound and it is shipping — but it means the emitted
netlist is the UNOPTIMIZED one exactly when optimization would have helped.

`normalize` is the repair: rename every net to the position of the gate that
defines it, so the result is dense SSA by construction and `emitN` applies to
the OPTIMIZED circuit.

## Status — complete

`docs/hdl-renumber-design-0806.md` scoped five obligations. All five land here:

* **(1) injective on defined nets** — `renum_out`, via `posOf_getD` and the
  `nodup` conjunct of `Circ.wf`.
* **(2) the frame lemma** — `run_renumFrom`. ⭐ The scoping note predicted this
  would need `σ` INJECTIVE, carried and re-applied at every gate, and called it
  "the expensive one". **It does not.** Carrying *"σ maps every DEFINED net
  strictly below the next new name"* is strictly weaker, is exactly what the
  circuit's own topological order already gives, and yields the disjointness for
  free: the net about to be written is `base`, and everything already defined
  renames below it. The predicted difficulty was an artefact of the predicted
  formulation.
* **(3) meaning preserved** — `normalize_sem`. The port list is renamed too, so
  the two `sem`s agree POSITIONALLY, output `k` for output `k`, which is the form
  the refuter pass ruled the seam must use.
* **(4) `normalize` establishes `ssa`** — `normalize_ssa`. The scoping note
  flagged this as *the step most likely to be false as written*. It is true, and
  the reason is `renum_fanin_lt`: the renaming is monotone on defined nets
  BECAUSE it maps each net to the position of the gate that defined it, and `wf`
  orders those positions.
* **(5) the pipeline law** — `emitPipeline'_sem`. Optimize, renumber, emit; no
  check, no fallback, no unoptimized branch.

**`EmitN.emitPipeline` is deliberately left in place.** It is sound, it needs no
`wf` hypothesis, and a validated fallback that never fires costs nothing. This
file adds the route that does not have to fall back; it does not delete the one
that cannot fail.

## What the two landed bridges buy the remaining work

Both are the reusable half. `wfGates_fanin_mem` converts `wfGates`'s PREPEND
LIST — the right shape for `opt`'s filter proof, the wrong one here — into the
POSITION of the defining gate, which is what the frame lemma's injectivity step
needs at every gate rather than once. `ssaFrom_of_pos` is the converse of
`EmitN`'s `ssaFrom_out`: `EmitN` needed positional-from-recursive, the renumber
needs recursive-from-positional.
-/

namespace SaltWorks.HDL

/-! ## The renaming map -/

/-- Position of `n` in `l`, or `l.length` if absent. Self-defined rather than
`List.idxOf` so the induction below has equations I control. -/
def posOf : List Net → Net → Nat
  | [],      _ => 0
  | m :: ms, n => if m == n then 0 else posOf ms n + 1

theorem posOf_cons_self (ms : List Net) (n : Net) : posOf (n :: ms) n = 0 := by
  simp [posOf]

theorem posOf_cons_ne {m n : Net} (ms : List Net) (h : ¬ m = n) :
    posOf (m :: ms) n = posOf ms n + 1 := by
  simp [posOf, h]

/-- On a duplicate-free list, `posOf` inverts `getD`. -/
theorem posOf_getD : ∀ (l : List Net), nodupB l = true → ∀ i, i < l.length →
    posOf l (l.getD i 0) = i := by
  intro l
  induction l with
  | nil => intro _ i hi; simp at hi
  | cons a t ih =>
    intro hnd i hi
    rw [nodupB, Bool.and_eq_true] at hnd
    obtain ⟨hna, hndt⟩ := hnd
    cases i with
    | zero => show posOf (a :: t) a = 0; exact posOf_cons_self t a
    | succ m =>
      have hm : m < t.length := by simp only [List.length_cons] at hi; omega
      have hmem : t.getD m 0 ∈ t := by
        have : t.getD m 0 = t[m]'hm := by simp [List.getD, hm]
        rw [this]; exact List.getElem_mem hm
      have hne : ¬ a = t.getD m 0 := by
        intro heq
        have hc : t.contains a = true := by rw [heq]; simpa using hmem
        rw [hc] at hna
        simp at hna
      have hcons : (a :: t).getD (m + 1) 0 = t.getD m 0 := by simp [List.getD]
      rw [hcons, posOf_cons_ne t hne, ih hndt m hm]

/-! ## The renumber -/

/-- Gate `i`'s output net becomes `nIn + i`; inputs fix themselves. Nets that are
neither get a junk value, harmless because `sem` is total. -/
def renum (c : Circ) (n : Net) : Net :=
  if n < c.nIn then n else c.nIn + posOf (c.gates.map Gate.out) n

/-- An operation with its operands renamed. -/
def Op.rename (f : Net → Net) : Op → Op
  | .const b => .const b
  | .not a   => .not (f a)
  | .and a b => .and (f a) (f b)
  | .or  a b => .or  (f a) (f b)
  | .xor a b => .xor (f a) (f b)

/-- Renumbered gates: the `i`-th gate of `gs` becomes net `nIn + i`, operands
renamed by `σ`. Hand-rolled rather than `List.mapIdx` so the inductions below get
equations this file controls — the same reason `posOf` is not `List.idxOf`. -/
def renumGates (nIn : Nat) (σ : Net → Net) : Nat → List Gate → List Gate
  | _, []      => []
  | i, g :: gs => ⟨nIn + i, g.op.rename σ⟩ :: renumGates nIn σ (i + 1) gs

theorem renumGates_length (nIn : Nat) (σ : Net → Net) :
    ∀ (i : Nat) (gs : List Gate), (renumGates nIn σ i gs).length = gs.length := by
  intro i gs; induction gs generalizing i with
  | nil => rfl
  | cons g gs ih => simp [renumGates, ih]

theorem renumGates_getD (nIn : Nat) (σ : Net → Net) :
    ∀ (gs : List Gate) (i k : Nat), k < gs.length →
      (renumGates nIn σ i gs).getD k default
        = ⟨nIn + i + k, (gs.getD k default).op.rename σ⟩ := by
  intro gs
  induction gs with
  | nil => intro i k hk; simp at hk
  | cons g gs ih =>
    intro i k hk
    cases k with
    | zero => show (⟨nIn + i, _⟩ : Gate) = _; simp [List.getD]
    | succ m =>
      have hm : m < gs.length := by simp only [List.length_cons] at hk; omega
      have hL : (renumGates nIn σ i (g :: gs)).getD (m + 1) default
          = (renumGates nIn σ (i + 1) gs).getD m default := by simp [renumGates, List.getD]
      have hR : ((g :: gs).getD (m + 1) default) = gs.getD m default := by simp [List.getD]
      rw [hL, ih (i + 1) m hm, hR]
      have : nIn + (i + 1) + m = nIn + i + (m + 1) := by omega
      rw [this]

/-- **The densifying renumber.** -/
def normalize (c : Circ) : Circ where
  nIn   := c.nIn
  gates := renumGates c.nIn (renum c) 0 c.gates
  outs  := c.outs.map (renum c)

/-! ## `renum` computes the position it promises -/

theorem renum_out (c : Circ) (h : c.wf = true) (i : Nat) (hi : i < c.gates.length) :
    renum c (c.gates.getD i default).out = c.nIn + i := by
  rw [Circ.wf, Bool.and_eq_true, Bool.and_eq_true, Bool.and_eq_true] at h
  obtain ⟨⟨⟨_, _⟩, hnd⟩, hge⟩ := h
  have hmem : (c.gates.getD i default) ∈ c.gates := by
    have : c.gates.getD i default = c.gates[i]'hi := by simp [List.getD, hi]
    rw [this]; exact List.getElem_mem hi
  have hge' : c.nIn ≤ (c.gates.getD i default).out :=
    by simpa using List.all_eq_true.mp hge _ hmem
  have hlen : i < (c.gates.map Gate.out).length := by simpa using hi
  have hgetD : (c.gates.map Gate.out).getD i 0 = (c.gates.getD i default).out := by
    simp [List.getD, hi]
  -- `omega` fails here: `Gate.out : Net`, and omega's preprocessing is syntactic
  -- in the type even though `Net` is a reducible abbrev for `Nat`. Third time in
  -- this leg (Banyan.lean:68, EmitN.lean:262). Restate at `Nat`, then an explicit
  -- term rather than a tactic.
  have hge2 : (c.nIn : Nat) ≤ ((c.gates.getD i default).out : Nat) := hge'
  rw [renum, if_neg (Nat.not_lt.mpr hge2), hgetD.symm, posOf_getD _ hnd i hlen]

/-! ## The bridge both remaining obligations need

`wfGates` threads its defined-set as a PREPEND LIST, which is the right shape for
`opt`'s filter proof and the wrong shape here: this file needs the POSITION of the
gate that defined a net, not merely that some gate did. This lemma converts one
into the other, and it is where the `nodup` half of `Circ.wf` starts earning its
keep. -/
theorem wfGates_fanin_mem : ∀ (gs : List Gate) (defined : List Net) (i : Nat),
    wfGates defined gs = true → i < gs.length →
    ∀ a ∈ (gs.getD i default).op.fanin,
      defined.contains a = true ∨ ∃ j, j < i ∧ a = (gs.getD j default).out := by
  intro gs
  induction gs with
  | nil => intro _ i _ hi; simp at hi
  | cons g gs ih =>
    intro defined i hwf hi a ha
    rw [wfGates, Bool.and_eq_true] at hwf
    obtain ⟨hfan, hrest⟩ := hwf
    cases i with
    | zero =>
      left
      exact List.all_eq_true.mp hfan a (by simpa using ha)
    | succ m =>
      have hm : m < gs.length := by simp only [List.length_cons] at hi; omega
      have ha' : a ∈ (gs.getD m default).op.fanin := by
        have : (g :: gs).getD (m + 1) default = gs.getD m default := by simp [List.getD]
        rwa [this] at ha
      rcases ih (g.out :: defined) m hrest hm a ha' with hc | ⟨j, hj, hje⟩
      · -- NB: do NOT unfold `List.contains` with `BEq.comm` in the simp set — it
        -- loops to maxRecDepth. Going through membership avoids the orientation
        -- question that tempted the commutativity lemma in the first place.
        have hmem : a ∈ g.out :: defined := by simpa using hc
        rcases List.mem_cons.mp hmem with h1 | h2
        · exact Or.inr ⟨0, by omega, by show a = g.out; exact h1⟩
        · exact Or.inl (by simpa using h2)
      · refine Or.inr ⟨j + 1, by omega, ?_⟩
        show a = (gs.getD j default).out
        exact hje

/-- **Operands rename strictly below their own gate's new position.** This is the
whole content of "the renumber respects the topological order", and it is what
`normalize` needs to land in `ssa` rather than merely in `dense`. -/
theorem renum_fanin_lt (c : Circ) (h : c.wf = true) (i : Nat) (hi : i < c.gates.length)
    (a : Net) (ha : a ∈ (c.gates.getD i default).op.fanin) :
    renum c a < c.nIn + i := by
  have hwfg : wfGates c.inputs c.gates = true := by
    rw [Circ.wf, Bool.and_eq_true, Bool.and_eq_true, Bool.and_eq_true] at h
    exact h.1.1.1
  rcases wfGates_fanin_mem c.gates c.inputs i hwfg hi a ha with hc | ⟨j, hj, hje⟩
  · have hmem : a ∈ c.inputs := by simpa using hc
    have hlt : a < c.nIn := by rw [Circ.inputs] at hmem; exact List.mem_range.mp hmem
    rw [renum, if_pos hlt]
    exact Nat.lt_of_lt_of_le hlt (Nat.le_add_right _ _)
  · subst hje
    rw [renum_out c h j (by omega)]
    exact Nat.add_lt_add_left hj c.nIn

/-- The converse of `ssaFrom_out`: positional facts rebuild the recursive
predicate. `EmitN` needed one direction; the renumber needs the other. -/
theorem ssaFrom_of_pos : ∀ (gs : List Gate) (base : Nat),
    (∀ i, i < gs.length → (gs.getD i default).out = base + i) →
    (∀ i, i < gs.length → ∀ a ∈ (gs.getD i default).op.fanin, a < base + i) →
    ssaFrom base gs = true := by
  intro gs
  induction gs with
  | nil => intro base _ _; rfl
  | cons g gs ih =>
    intro base hout hfan
    have h0len : 0 < (g :: gs).length := by simp
    have hg0 : (g :: gs).getD 0 default = g := by simp [List.getD]
    rw [ssaFrom, Bool.and_eq_true, Bool.and_eq_true]
    refine ⟨⟨?_, ?_⟩, ?_⟩
    · have := hout 0 h0len
      rw [hg0] at this
      simpa using this
    · have hf := hfan 0 h0len
      rw [hg0] at hf
      rw [List.all_eq_true]
      intro a ha
      have : a < base + 0 := hf a ha
      simpa using this
    · refine ih (base + 1) (fun i hi => ?_) (fun i hi a ha => ?_)
      -- The arithmetic below is forced to `Nat` before use. `Gate.out : Net` and
      -- `Op.fanin : List Net`, so any goal mentioning them is Net-typed and omega
      -- refuses it — fourth occurrence in this leg (Banyan:68, EmitN:262,
      -- renum_out above). A `have` at `Nat` is the whole fix.
      · have hi1 : i + 1 < (g :: gs).length := by simpa using Nat.succ_lt_succ hi
        have hcons : (g :: gs).getD (i + 1) default = gs.getD i default := by simp [List.getD]
        have hthis := hout (i + 1) hi1
        rw [hcons] at hthis
        have harith : base + 1 + i = base + (i + 1) := by omega
        rw [harith, hthis]
      · have hi1 : i + 1 < (g :: gs).length := by simpa using Nat.succ_lt_succ hi
        have hcons : (g :: gs).getD (i + 1) default = gs.getD i default := by simp [List.getD]
        have hf := hfan (i + 1) hi1 a (by rw [hcons]; exact ha)
        have harith : base + 1 + i = base + (i + 1) := by omega
        rw [harith]
        exact hf

theorem posOf_lt : ∀ (l : List Net) (n : Net), l.contains n = true → posOf l n < l.length := by
  intro l
  induction l with
  | nil => intro n h; simp at h
  | cons a t ih =>
    intro n h
    by_cases hae : a = n
    · rw [hae, posOf_cons_self]; simp
    · rw [posOf_cons_ne t hae]
      have ht : t.contains n = true := by
        have hmem : n ∈ a :: t := by simpa using h
        rcases List.mem_cons.mp hmem with h1 | h2
        · exact absurd h1.symm hae
        · simpa using h2
      have := ih n ht
      simp only [List.length_cons]; omega

theorem Op.rename_fanin (f : Net → Net) : ∀ (o : Op), (o.rename f).fanin = o.fanin.map f := by
  intro o; cases o <;> simp [Op.rename, Op.fanin]

theorem defined_mem : ∀ (gs : List Gate) (acc : List Net) (n : Net),
    (gs.foldl (fun acc g => g.out :: acc) acc).contains n = true →
    acc.contains n = true ∨ (gs.map Gate.out).contains n = true := by
  intro gs
  induction gs with
  | nil => intro acc n h; exact Or.inl h
  | cons g gs ih =>
    intro acc n h
    rcases ih (g.out :: acc) n h with hc | hr
    · have hmem : n ∈ g.out :: acc := by simpa using hc
      rcases List.mem_cons.mp hmem with h1 | h2
      · exact Or.inr (by simp [h1])
      · exact Or.inl (by simpa using h2)
    · exact Or.inr (by simp; right; simpa using hr)

/-- **OBLIGATION 4 — `normalize` lands in `ssa`, not merely in `dense`.**
I flagged this in the scoping note as the step most likely to be false as
written. It holds, and the reason it holds is `renum_fanin_lt`: the renaming is
monotone on defined nets *because* it maps each net to the position of the gate
that defined it, and `wf` orders those positions. -/
theorem normalize_ssa (c : Circ) (h : c.wf = true) : (normalize c).ssa = true := by
  have hlen : (normalize c).gates.length = c.gates.length := renumGates_length _ _ 0 _
  rw [Circ.ssa, Bool.and_eq_true]
  constructor
  · refine ssaFrom_of_pos _ _ (fun i hi => ?_) (fun i hi a ha => ?_)
    · rw [hlen] at hi
      show ((renumGates c.nIn (renum c) 0 c.gates).getD i default).out = c.nIn + i
      rw [renumGates_getD _ _ _ 0 i hi]
      show c.nIn + 0 + i = c.nIn + i
      omega
    · rw [hlen] at hi
      rw [show (normalize c).gates = renumGates c.nIn (renum c) 0 c.gates from rfl,
        renumGates_getD _ _ _ 0 i hi] at ha
      rw [show ((⟨c.nIn + 0 + i, (c.gates.getD i default).op.rename (renum c)⟩ : Gate)).op
            = (c.gates.getD i default).op.rename (renum c) from rfl,
        Op.rename_fanin] at ha
      obtain ⟨b, hb, hbe⟩ := List.mem_map.mp ha
      have : renum c b < c.nIn + i := renum_fanin_lt c h i hi b hb
      rw [← hbe]; exact this
  · rw [List.all_eq_true]
    intro n hn
    obtain ⟨m, hm, hme⟩ := List.mem_map.mp hn
    rw [Circ.wf, Bool.and_eq_true, Bool.and_eq_true, Bool.and_eq_true] at h
    obtain ⟨⟨⟨_, houts⟩, _⟩, hge⟩ := h
    have hdef : c.defined.contains m = true := List.all_eq_true.mp houts m hm
    rw [Circ.defined] at hdef
    have hlt : renum c m < c.nIn + c.gates.length := by
      rcases defined_mem c.gates c.inputs m hdef with hin | hg
      · have hmem : m ∈ c.inputs := by simpa using hin
        have hml : m < c.nIn := by rw [Circ.inputs] at hmem; exact List.mem_range.mp hmem
        rw [renum, if_pos hml]
        exact Nat.lt_of_lt_of_le hml (Nat.le_add_right _ _)
      · -- `h` is already destructured here; re-`rw`ing `Circ.wf` at it was a stale
        -- edit and Lake said so. The `nIn ≤ out` conjunct is `hge`, taken above.
        have hmem : m ∈ c.gates.map Gate.out := by simpa using hg
        obtain ⟨g, hgm, hgeq⟩ := List.mem_map.mp hmem
        have hnIn : (c.nIn : Nat) ≤ (g.out : Nat) := by
          simpa using List.all_eq_true.mp hge g hgm
        have hnlt : ¬ m < c.nIn := by rw [← hgeq]; exact Nat.not_lt.mpr hnIn
        rw [renum, if_neg hnlt]
        have hp := posOf_lt (c.gates.map Gate.out) m hg
        simp only [List.length_map] at hp
        exact Nat.add_lt_add_left hp c.nIn
    rw [← hme]
    simp only [decide_eq_true_eq]
    show renum c m < c.nIn + (normalize c).gates.length
    rw [hlen]
    exact hlt



/-- Renumbering keyed on the ABSOLUTE next name rather than an index. The frame
lemma inducts on this: `base` is exactly "the name the next gate will take", which
is the quantity the disjointness argument needs. -/
def renumFrom (σ : Net → Net) : Nat → List Gate → List Gate
  | _, []      => []
  | b, g :: gs => ⟨b, g.op.rename σ⟩ :: renumFrom σ (b + 1) gs

theorem renumGates_eq_renumFrom (nIn : Nat) (σ : Net → Net) :
    ∀ (i : Nat) (gs : List Gate), renumGates nIn σ i gs = renumFrom σ (nIn + i) gs := by
  intro i gs
  induction gs generalizing i with
  | nil => rfl
  | cons g gs ih =>
    show (⟨nIn + i, _⟩ : Gate) :: renumGates nIn σ (i + 1) gs
       = (⟨nIn + i, _⟩ : Gate) :: renumFrom σ (nIn + i + 1) gs
    rw [ih (i + 1)]
    have : nIn + (i + 1) = nIn + i + 1 := by omega
    rw [this]

/-- One renamed operation, on environments that agree via `σ` on everything the
operation reads. -/
theorem eval_rename {σ : Net → Net} {envN envC : Env} {D : List Net}
    (hag : ∀ a, D.contains a = true → envN (σ a) = envC a) :
    ∀ (o : Op), o.fanin.all D.contains = true →
      (o.rename σ).eval envN = o.eval envC := by
  intro o
  cases o with
  | const b => intro _; rfl
  | not a =>
    intro hf
    have ha : D.contains a = true := by simpa [Op.fanin] using hf
    show (!(envN (σ a))) = (!(envC a))
    rw [hag a ha]
  | and a b =>
    intro hf
    simp only [Op.fanin, List.all_cons, List.all_nil, Bool.and_true, Bool.and_eq_true] at hf
    show (envN (σ a) && envN (σ b)) = (envC a && envC b)
    rw [hag a hf.1, hag b hf.2]
  | or a b =>
    intro hf
    simp only [Op.fanin, List.all_cons, List.all_nil, Bool.and_true, Bool.and_eq_true] at hf
    show (envN (σ a) || envN (σ b)) = (envC a || envC b)
    rw [hag a hf.1, hag b hf.2]
  | xor a b =>
    intro hf
    simp only [Op.fanin, List.all_cons, List.all_nil, Bool.and_true, Bool.and_eq_true] at hf
    show (envN (σ a) ^^ envN (σ b)) = (envC a ^^ envC b)
    rw [hag a hf.1, hag b hf.2]

/-! ## THE FRAME LEMMA (obligation 2)

The scoping note predicted this would need `σ` injective, carried and re-applied
at every gate. It does not. Carrying **"σ maps every DEFINED net strictly below
the next new name"** is strictly weaker, is what the circuit's own topological
order already gives, and yields the disjointness for free: the net about to be
written is `base`, and everything already defined renames below it. -/
theorem run_renumFrom (σ : Net → Net) :
    ∀ (gs : List Gate) (base : Nat) (D : List Net) (envN envC : Env),
      (∀ a, D.contains a = true → envN (σ a) = envC a) →
      (∀ a, D.contains a = true → σ a < base) →
      wfGates D gs = true →
      (∀ i, i < gs.length → σ (gs.getD i default).out = base + i) →
      ∀ a, (D.contains a = true ∨ (gs.map Gate.out).contains a = true) →
        run envN (renumFrom σ base gs) (σ a) = run envC gs a := by
  intro gs
  induction gs with
  | nil =>
    intro base D envN envC hag _ _ _ a ha
    rcases ha with h | h
    · exact hag a h
    · simp at h
  | cons g gs ih =>
    intro base D envN envC hag hlt hwf hout a ha
    rw [wfGates, Bool.and_eq_true] at hwf
    obtain ⟨hfan, hrest⟩ := hwf
    have hg0 : σ g.out = base := by
      have := hout 0 (by simp)
      simpa [List.getD] using this
    have hstep : (g.op.rename σ).eval envN = g.op.eval envC := eval_rename hag g.op hfan
    -- the two updated environments still agree via σ, on the enlarged defined set
    have hag' : ∀ b, (g.out :: D).contains b = true →
        upd envN base ((g.op.rename σ).eval envN) (σ b)
          = upd envC g.out (g.op.eval envC) b := by
      intro b hb
      have hmem : b ∈ g.out :: D := by simpa using hb
      rcases List.mem_cons.mp hmem with h1 | h2
      · subst h1
        rw [hg0, upd_self, upd_self, hstep]
      · have hbD : D.contains b = true := by simpa using h2
        have hne : σ b ≠ base := Nat.ne_of_lt (hlt b hbD)
        have hne2 : b ≠ g.out := by
          intro hc; rw [hc, hg0] at hne; exact hne rfl
        rw [upd_of_ne _ hne, upd_of_ne _ hne2]
        exact hag b hbD
    have hlt' : ∀ b, (g.out :: D).contains b = true → σ b < base + 1 := by
      intro b hb
      have hmem : b ∈ g.out :: D := by simpa using hb
      rcases List.mem_cons.mp hmem with h1 | h2
      -- omega again refuses these: `σ : Net → Net`, so both goals are Net-typed.
      -- Fifth and sixth occurrences in this leg. Explicit terms instead.
      · subst h1; rw [hg0]; exact Nat.lt_succ_self base
      · exact Nat.lt_succ_of_lt (hlt b (by simpa using h2))
    have hout' : ∀ i, i < gs.length → σ (gs.getD i default).out = base + 1 + i := by
      intro i hi
      have hcons : (g :: gs).getD (i + 1) default = gs.getD i default := by simp [List.getD]
      have hh := hout (i + 1) (by simp only [List.length_cons]; omega)
      rw [hcons] at hh
      have harith : base + 1 + i = base + (i + 1) := by omega
      rw [harith, hh]
    have hnew : (g.out :: D).contains a = true ∨ (gs.map Gate.out).contains a = true := by
      rcases ha with hD | hO
      · exact Or.inl (by
          have : a ∈ g.out :: D := List.mem_cons_of_mem _ (by simpa using hD)
          simpa using this)
      · -- keep the LIST shape: `simpa` alone destructures the membership into a
        -- disjunction with an existential, after which `List.mem_cons` no longer
        -- applies. `map_cons` first, then the cons lemma.
        have h0 : a ∈ (g :: gs).map Gate.out := by simpa using hO
        rw [List.map_cons] at h0
        rcases List.mem_cons.mp h0 with h1 | h2
        · exact Or.inl (by simp [h1])
        · exact Or.inr (by simpa using h2)
    exact ih (base + 1) (g.out :: D) _ _ hag' hlt' hrest hout' a hnew

/-! ## OBLIGATION 3 — the renumber preserves meaning -/

/-- **`normalize` preserves meaning.** The port list is renamed too, so the two
`sem`s agree POSITIONALLY — output `k` of the normalized circuit is output `k` of
the original — which is the form the refuter pass ruled the seam must use. -/
theorem normalize_sem (c : Circ) (h : c.wf = true) (ins : Env) :
    sem (normalize c) ins = sem c ins := by
  have h' := h
  rw [Circ.wf, Bool.and_eq_true, Bool.and_eq_true, Bool.and_eq_true] at h'
  obtain ⟨⟨⟨hwfg, houts⟩, _⟩, _⟩ := h'
  have hin : ∀ a, c.inputs.contains a = true → renum c a = a := by
    intro a ha
    have hmem : a ∈ c.inputs := by simpa using ha
    have hlt : a < c.nIn := by rw [Circ.inputs] at hmem; exact List.mem_range.mp hmem
    rw [renum, if_pos hlt]
  have hinlt : ∀ a, c.inputs.contains a = true → renum c a < c.nIn := by
    intro a ha
    have hmem : a ∈ c.inputs := by simpa using ha
    have hlt : a < c.nIn := by rw [Circ.inputs] at hmem; exact List.mem_range.mp hmem
    rw [renum, if_pos hlt]; exact hlt
  have key : ∀ n, c.defined.contains n = true →
      run ins (renumFrom (renum c) c.nIn c.gates) (renum c n) = run ins c.gates n := by
    intro n hn
    refine run_renumFrom (renum c) c.gates c.nIn c.inputs ins ins
      (fun a ha => by rw [hin a ha]) hinlt hwfg (fun i hi => renum_out c h i hi) n ?_
    rw [Circ.defined] at hn
    exact defined_mem c.gates c.inputs n hn
  show ((c.outs.map (renum c)).map (run ins (renumGates c.nIn (renum c) 0 c.gates)))
      = c.outs.map (run ins c.gates)
  rw [renumGates_eq_renumFrom, show c.nIn + 0 = c.nIn from rfl, List.map_map]
  refine List.map_congr_left (fun n hn => ?_)
  exact key n (List.all_eq_true.mp houts n hn)

/-! ## The motivating case, kernel-checked

`withMidDead` is the circuit `Dense.lean` built to exhibit the trap: `opt` fires,
the survivor keeps name 4 at position 1, and density breaks. `normalize` repairs
it — so the pipeline that `emitPipeline` has to refuse is now constructible. -/

theorem opt_withMidDead_wf' : (opt withMidDead).wf = true := by decide +kernel

theorem normalize_opt_withMidDead_ssa : (normalize (opt withMidDead)).ssa = true :=
  normalize_ssa _ opt_withMidDead_wf'

/-- …and the fabric, so the construction is exercised on the tapeout candidate
rather than only on the two-gate exhibit. -/
theorem normalize_fabric3_ssa : (normalize (fabric 3)).ssa = true :=
  normalize_ssa _ fabric3_wf

#audit_axioms posOf posOf_cons_self posOf_cons_ne posOf_getD posOf_lt
#audit_axioms renum Op.rename renumGates normalize
#audit_axioms renum_out renumGates_length renumGates_getD
#audit_axioms Op.rename_fanin defined_mem wfGates_fanin_mem
#audit_axioms renum_fanin_lt ssaFrom_of_pos
#audit_axioms normalize_ssa
#audit_axioms renumFrom renumGates_eq_renumFrom eval_rename
#audit_axioms run_renumFrom normalize_sem
#audit_axioms opt_withMidDead_wf' normalize_opt_withMidDead_ssa normalize_fabric3_ssa

/-! ## `opt` preserves well-formedness

`emitPipeline'_sem` originally took `(opt c).wf`. `Opt.lean` never proved that
`opt` preserves well-formedness, so the hypothesis could not be discharged from
`c.wf` and every caller paid a separate `decide`.

`opt_wf` closes it, and the hypothesis is now the natural one. The load-bearing
step is `wfGates_filter`: the narrowing it performs is NOT monotonicity — my
first attempt reached for a `wfGates_mono` that does not exist and would have
been false in the direction needed. It is sound for exactly one reason, and that
reason is the lemma's content: **a KEPT gate cannot read a DROPPED gate's
output**, because `KeepClosed` puts every operand of a kept gate in `keep` and a
dropped gate's output is not. Hence two threaded defined-lists rather than one.
-/

/-- **Filtering preserves `wfGates`.** Two defined-lists are threaded, not one:
`D` is what the ORIGINAL list has defined, `Dk` what the FILTERED list has. `Dk`
is a subset, and the hypothesis says it retains everything kept. The narrowing
is sound for one reason, and it is the whole content of the lemma: a KEPT gate
cannot read a DROPPED gate's output, because `KeepClosed` puts every operand of
a kept gate in `keep` and a dropped gate's output is not. -/
theorem wfGates_filter {keep : Net → Bool} :
    ∀ (gs : List Gate) (D Dk : List Net),
      wfGates D gs = true →
      KeepClosed keep gs →
      (∀ a, keep a = true → D.contains a = true → Dk.contains a = true) →
      wfGates Dk (gs.filter (fun g => keep g.out)) = true := by
  intro gs
  induction gs with
  | nil => intro D Dk _ _ _; rfl
  | cons g gs ih =>
    intro D Dk hwf hc hsub
    rw [wfGates, Bool.and_eq_true] at hwf
    obtain ⟨hfan, hrest⟩ := hwf
    have hc' : KeepClosed keep gs := fun g' hg' => hc g' (by simp [hg'])
    by_cases hk : keep g.out = true
    · have hfil : (g :: gs).filter (fun g => keep g.out)
          = g :: gs.filter (fun g => keep g.out) := by simp [hk]
      rw [hfil, wfGates, Bool.and_eq_true]
      refine ⟨?_, ?_⟩
      · rw [List.all_eq_true]
        intro a ha
        have haD : D.contains a = true := List.all_eq_true.mp hfan a ha
        have hak : keep a = true := hc g (by simp) hk a ha
        exact hsub a hak haD
      · refine ih (g.out :: D) (g.out :: Dk) hrest hc' ?_
        intro a hak haD
        have hmem : a ∈ g.out :: D := by simpa using haD
        rcases List.mem_cons.mp hmem with h1 | h2
        · exact (by simp [h1])
        · have := hsub a hak (by simpa using h2)
          have : a ∈ Dk := by simpa using this
          simpa using List.mem_cons_of_mem g.out this
    · have hk' : keep g.out = false := by simpa using hk
      have hfil : (g :: gs).filter (fun g => keep g.out)
          = gs.filter (fun g => keep g.out) := by simp [hk']
      rw [hfil]
      refine ih (g.out :: D) Dk hrest hc' ?_
      intro a hak haD
      have hmem : a ∈ g.out :: D := by simpa using haD
      rcases List.mem_cons.mp hmem with h1 | h2
      · rw [h1, hk'] at hak; exact absurd hak (by simp)
      · exact hsub a hak (by simpa using h2)



theorem contains_filter_out {p : Gate → Bool} : ∀ (gs : List Gate) (a : Net),
    ((gs.filter p).map Gate.out).contains a = true → (gs.map Gate.out).contains a = true := by
  intro gs
  induction gs with
  | nil => intro a h; simp at h
  | cons g gs ih =>
    intro a h
    by_cases hp : p g = true
    · rw [List.filter_cons_of_pos hp, List.map_cons] at h
      have hmem : a ∈ g.out :: (gs.filter p).map Gate.out := by simpa using h
      rcases List.mem_cons.mp hmem with h1 | h2
      · simp [h1]
      · have := ih a (by simpa using h2)
        have hm : a ∈ gs.map Gate.out := by simpa using this
        simpa using List.mem_cons_of_mem g.out hm
    · have hp' : p g = false := by simpa using hp
      rw [List.filter_cons_of_neg (by simp [hp'])] at h
      have := ih a h
      have hm : a ∈ gs.map Gate.out := by simpa using this
      simpa using List.mem_cons_of_mem g.out hm

theorem nodupB_filter_out {p : Gate → Bool} : ∀ (gs : List Gate),
    nodupB (gs.map Gate.out) = true → nodupB ((gs.filter p).map Gate.out) = true := by
  intro gs
  induction gs with
  | nil => intro h; exact h
  | cons g gs ih =>
    intro h
    rw [List.map_cons, nodupB, Bool.and_eq_true] at h
    obtain ⟨hne, hrest⟩ := h
    by_cases hp : p g = true
    · rw [List.filter_cons_of_pos hp, List.map_cons, nodupB, Bool.and_eq_true]
      refine ⟨?_, ih hrest⟩
      by_cases hc : ((gs.filter p).map Gate.out).contains g.out = true
      · exact absurd (contains_filter_out gs g.out hc) (by simpa using hne)
      · simpa using hc
    · rw [List.filter_cons_of_neg (by simpa using hp)]
      exact ih hrest

theorem mem_defined : ∀ (gs : List Gate) (acc : List Net) (n : Net),
    (acc.contains n = true ∨ (gs.map Gate.out).contains n = true) →
    (gs.foldl (fun acc g => g.out :: acc) acc).contains n = true := by
  intro gs
  induction gs with
  | nil =>
    intro acc n h
    rcases h with h | h
    · exact h
    · simp at h
  | cons g gs ih =>
    intro acc n h
    show (gs.foldl (fun acc g => g.out :: acc) (g.out :: acc)).contains n = true
    refine ih (g.out :: acc) n ?_
    rcases h with hA | hO
    · left
      have hm : n ∈ acc := by simpa using hA
      simpa using List.mem_cons_of_mem g.out hm
    · rw [List.map_cons] at hO
      have hmem : n ∈ g.out :: gs.map Gate.out := by simpa using hO
      rcases List.mem_cons.mp hmem with h1 | h2
      · left; simp [h1]
      · right; simpa using h2

/-- **`opt` preserves well-formedness.** Discharges the hypothesis
`emitPipeline'_sem` was taking. -/
theorem opt_wf (c : Circ) (h : c.wf = true) : (opt c).wf = true := by
  rw [opt, dce]
  split
  · next hcond =>
    rw [Bool.and_eq_true] at hcond
    obtain ⟨hclosed, houtsk⟩ := hcond
    rw [Circ.wf, Bool.and_eq_true, Bool.and_eq_true, Bool.and_eq_true] at h ⊢
    obtain ⟨⟨⟨hwfg, houts⟩, hnd⟩, hge⟩ := h
    refine ⟨⟨⟨?_, ?_⟩, ?_⟩, ?_⟩
    · exact wfGates_filter _ _ _ hwfg (keepClosedB_sound hclosed) (fun a _ ha => ha)
    · rw [List.all_eq_true]
      intro n hn
      have hkeep := List.all_eq_true.mp houtsk n hn
      have hdef := List.all_eq_true.mp houts n hn
      show (Circ.defined _).contains n = true
      rw [Circ.defined]
      refine mem_defined _ _ n ?_
      rw [Circ.defined] at hdef
      rcases defined_mem c.gates c.inputs n hdef with hin | hg
      · exact Or.inl hin
      · right
        have hmem : n ∈ c.gates.map Gate.out := by simpa using hg
        obtain ⟨g, hgm, hge2⟩ := List.mem_map.mp hmem
        have : g ∈ c.gates.filter (fun g => (liveOf c.gates c.outs).contains g.out) := by
          refine List.mem_filter.mpr ⟨hgm, ?_⟩
          rw [hge2]; simpa using hkeep
        have : n ∈ (c.gates.filter
            (fun g => (liveOf c.gates c.outs).contains g.out)).map Gate.out := by
          rw [← hge2]; exact List.mem_map_of_mem this
        simpa using this
    · exact nodupB_filter_out _ hnd
    · rw [List.all_eq_true]
      intro g hg
      exact List.all_eq_true.mp hge g (List.mem_of_mem_filter hg)
  · exact h

/-! ## OBLIGATION 5 — the pipeline that could not be written this afternoon

`EmitN.emitPipeline` optimizes, checks `ssa`, and falls back to the UNOPTIMIZED
circuit when `opt` has broken density — sound, but it emits the larger netlist
exactly when optimization would have helped. With `normalize` proved, the
fallback is no longer the only option: optimize, RENUMBER, emit. -/

/-- **Optimize, normalize, emit.** No check, no fallback, no unoptimized branch. -/
def emitPipeline' (c : Circ) : Silicon.Netlist := emitN (normalize (opt c))

/-- **The pipeline law.** The emitted netlist means what the ORIGINAL circuit
means, with `opt` actually applied. Note the port list is the normalized one —
the two agree positionally, output `k` for output `k`, which is the form the
refuter pass ruled the seam must use. -/
theorem emitPipeline'_sem (c : Circ) (h : c.wf = true) (ins : Env) :
    (normalize (opt c)).outs.map
        (fun n => (Silicon.runP ins [] (emitPipeline' c)).getD n false) = sem c ins := by
  have h' := opt_wf c h
  rw [emitPipeline', emitN_sem _ (normalize_ssa _ h') ins, normalize_sem _ h' ins, opt_sem]

#audit_axioms emitPipeline' emitPipeline'_sem
#audit_axioms wfGates_filter contains_filter_out nodupB_filter_out
#audit_axioms mem_defined opt_wf

end SaltWorks.HDL
