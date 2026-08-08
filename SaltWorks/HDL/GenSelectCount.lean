/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.AluSelect

/-!
# `genSelect n b` — the closed-form gate count, and dense SSA at every `(n, b)`

Two general theorems about the parametric output select, plus the exact
hypotheses each one needs and a kernel refutation for the one that is necessary.

* `genSelect_gates_length` : `(genSelect n b).gates.length = 96 * (2^b - 1) + b + 1`
  — **NO hypotheses at all.** `n` is genuinely absent: a source is free, a
  SELECT BIT is what costs. Every anchor below is `rw`-recovered FROM this
  identity rather than re-derived by an independent `decide` — three `decide`s
  that agree is not evidence a formula holds; six anchors that fall out of it is.
* `genSelect_ssa` / `genSelect_wf` : dense SSA and well-formedness for **every**
  `n` and **every** `b > 0`. `0 < b` is not decoration: `genSelect_zero_b_not_ssa`
  refutes `b = 0` in the kernel.

All statements stay general in `(n b)`; `b = 3` and `b = 4` are corollaries by
instantiation, not separate proofs. Before this module, `wf`/`ssa` existed at
exactly three POINTS — `(2,1)`, `(3,2)`, `(10,4)` — and `b = 3` was proved at
none, which is the width an `aluSelect` sizing call was most likely to choose.

## The three hypotheses, separated — they are not interchangeable

| condition  | needed for the COUNT | needed for `ssa`/`wf` | needed for the SEMANTICS |
| ---------- | -------------------- | --------------------- | ------------------------ |
| `0 < b`    | no                   | **YES** (and refuted below without it) | yes |
| `n ≤ 2^b`  | no                   | no                    | **YES** — to read every source |

`genSelect 20 4` is a well-formed, dense-SSA, 1,445-gate circuit that reads
sixteen of its twenty sources. Well-formedness and correctness-of-capacity are
different claims and this module closes only the first.

## ⚠️ A number this module corrects, with witnesses

Three seats stated on 8/8 that `genSelect 20 4` *"silently reads only ten of its
twenty sources."* **The conclusion it was offered for is right and the number is
wrong.** Level-0 leaves are indexed `i < 2^b = 16` and pad only when `n ≤ i`, so
at `n = 20` NO leaf pads: sixteen sources are read and `16..19` are named by no
leaf. The `ten` belongs to `genSelect 10 4` — `aluSelect` — where six of the
sixteen leaves DO pad. See `twenty_no_leaf_pads`, `twenty_ignores_high`,
`ten_pads_six`.

## Why `gsMux_ssaFrom` was hard, and the fleet rule it refines

Its three `omega` goals failed with counterexamples built purely from hypothesis
atoms, **no goal variable present** — the classic signature of omega folding a
compound term into an atom. That diagnosis is wrong here.

`simp only [...]` correctly reduces the fanin obligation to a conjunction which
`pp.all` reveals as

    And (@LT.lt SaltWorks.HDL.Net instLTNat x base)
        (@LT.lt SaltWorks.HDL.Net instLTNat y base)

— the `<` sits at the **abbrev `Net`**, not `Nat`, because the fanin list is
`List Net`. `omega` matches comparisons by the *literal* type argument. At a
goal's top level it applies reducible whnf first, which sees through the abbrev;
but when the goal is `And p q` it recurses into the conjuncts **without** that
whnf, the `Nat` match fails, and the goal facts are discarded wholesale. omega
is then asked to derive `False` from hypotheses alone — hence a counterexample
with every goal variable absent.

Five probes, each changing exactly one thing (`ScratchOmegaProbe.lean`). A rival
diagnosis was live — *"the `simp only` leaves a Bool equation `(… && …) = true`
and omega cannot act on that"* — and it predicts the same fix, so only a probe
can separate them:

| # | goal                                             | omega  |
| - | ------------------------------------------------ | ------ |
| 1 | `x < base ∧ y < base`  (both at `Nat`)            | ✓      |
| 2 | `@LT.lt Net .. x base` (single, no `∧`)           | ✓      |
| 3 | `@LT.lt Net .. ∧ @LT.lt Net ..`                   | ✗ FAIL |
| 4 | `(decide (x<base) && decide (y<base)) = true`     | ✗ FAIL |
| 5 | the real site: the goal + `simp only` from below  | ✗ FAIL |

Probe 1 kills *"omega cannot do conjunctions"*; probe 2 kills *"omega cannot do
`Net`"*. It takes **both** — an `abbrev`-typed comparison *underneath* a logical
connective. Probe 4 shows the Bool-equation obstruction is real but is NOT what
happens here, because `Bool.and_eq_true` and `decide_eq_true_eq` are in the simp
set and remove it: `trace_state` at probe 5 prints `⊢ x < base ∧ y < base`, a
Prop conjunction.

**⚠️ And that is the trap.** Probe 5's printed goal is *character-for-character
identical* to probe 1's, and probe 1 succeeds where probe 5 fails. `Net` is
reducible, so **the pretty-printer erases the one difference that decides the
outcome** — `trace_state` shows a goal omega can obviously do, and omega cannot
do it. Use `set_option pp.all true` before believing a goal display here.

**The refined rule:** *"the counterexample omits a goal variable"* does not mean
omega folded an atom — it means omega **dropped the goal**. Atom-folding is one
cause; a type synonym under `∧`/`∨` is another, and for that one rebinding to
`: Nat` genuinely does not help. The fix is to stop handing omega the
connective: `all_pair` ends in `exact ⟨hx, hy⟩`. No bridging fact was missing —
the layout lemmas were already sufficient, and only the SHAPE of the final goal
was the obstruction.
-/

namespace SaltWorks.HDL
namespace GSCount

/-! ## Generic scaffolding: chunked gate lists under `ssaFrom` -/

/-- Prefix sum of chunk lengths — the SSA base offset at which chunk `m` starts. -/
def psum (f : Nat → List Gate) (m : Nat) : Nat :=
  ((List.range m).map (fun t => (f t).length)).sum

theorem psum_succ (f : Nat → List Gate) (m : Nat) :
    psum f (m + 1) = psum f m + (f m).length := by
  simp [psum, List.range_succ, List.sum_append]

theorem length_flatMap_range (f : Nat → List Gate) (m : Nat) :
    ((List.range m).flatMap f).length = psum f m := by
  rw [List.length_flatMap]
  rfl

theorem psum_const (f : Nat → List Gate) (c : Nat) (hf : ∀ t, (f t).length = c) (m : Nat) :
    psum f m = m * c := by
  induction m with
  | zero => show (0 : Nat) = 0 * c; omega
  | succ m ih => rw [psum_succ, ih, hf, Nat.succ_mul]

/-- `ssaFrom` splits along `++`: the second chunk simply starts `l₁.length` later. -/
theorem ssaFrom_append : ∀ (l₁ l₂ : List Gate) (base : Nat),
    ssaFrom base l₁ = true → ssaFrom (base + l₁.length) l₂ = true →
    ssaFrom base (l₁ ++ l₂) = true := by
  intro l₁
  induction l₁ with
  | nil => intro l₂ base _ h₂; simpa using h₂
  | cons g gs ih =>
    intro l₂ base h₁ h₂
    have e₁ : ssaFrom base (g :: gs)
        = (((g.out == base) && g.op.fanin.all (fun a => a < base))
           && ssaFrom (base + 1) gs) := rfl
    have e₂ : ssaFrom base ((g :: gs) ++ l₂)
        = (((g.out == base) && g.op.fanin.all (fun a => a < base))
           && ssaFrom (base + 1) (gs ++ l₂)) := rfl
    rw [e₁, Bool.and_eq_true] at h₁
    rw [e₂, Bool.and_eq_true]
    refine ⟨h₁.1, ih l₂ (base + 1) h₁.2 ?_⟩
    have hlen : base + 1 + gs.length = base + (g :: gs).length := by
      rw [List.length_cons]; omega
    rw [hlen]; exact h₂

theorem ssaFrom_singleton (g : Gate) (base : Nat) (h1 : g.out = base)
    (h2 : g.op.fanin.all (fun a => a < base) = true) : ssaFrom base [g] = true := by
  have e : ssaFrom base [g]
      = (((g.out == base) && g.op.fanin.all (fun a => a < base))
         && ssaFrom (base + 1) ([] : List Gate)) := rfl
  have e2 : ssaFrom (base + 1) ([] : List Gate) = true := rfl
  rw [e, h1, h2, e2]
  simp

/-- **THE REPAIR.** Every net a two-input gate reads is below its own net.

`simp only` reduces the `List.all` to a conjunction of two `Net`-typed `<`.
The original closed it with `omega`, which silently discards a goal whose
comparisons sit at an abbrev underneath `∧` (see the module docstring).
`exact ⟨hx, hy⟩` is the right closer: it discharges the connective directly and
needs no arithmetic at all. -/
theorem all_pair {x y base : Nat} (hx : x < base) (hy : y < base) :
    ([x, y] : List Net).all (fun a => a < base) = true := by
  simp only [List.all_cons, List.all_nil, Bool.and_true, decide_eq_true_eq, Bool.and_eq_true]
  exact ⟨hx, hy⟩

theorem ssaFrom_triple (g1 g2 g3 : Gate) (base : Nat)
    (o1 : g1.out = base) (o2 : g2.out = base + 1) (o3 : g3.out = base + 1 + 1)
    (f1 : g1.op.fanin.all (fun a => a < base) = true)
    (f2 : g2.op.fanin.all (fun a => a < base + 1) = true)
    (f3 : g3.op.fanin.all (fun a => a < base + 1 + 1) = true) :
    ssaFrom base [g1, g2, g3] = true := by
  have e : [g1, g2, g3] = [g1] ++ ([g2] ++ [g3]) := rfl
  rw [e]
  refine ssaFrom_append _ _ _ (ssaFrom_singleton g1 base o1 f1) ?_
  show ssaFrom (base + 1) ([g2] ++ [g3]) = true
  refine ssaFrom_append _ _ _ (ssaFrom_singleton g2 (base + 1) o2 f2) ?_
  show ssaFrom (base + 1 + 1) [g3] = true
  exact ssaFrom_singleton g3 (base + 1 + 1) o3 f3

theorem ssaFrom_flatMap_range (f : Nat → List Gate) (base : Nat) : ∀ m,
    (∀ t, t < m → ssaFrom (base + psum f t) (f t) = true) →
    ssaFrom base ((List.range m).flatMap f) = true := by
  intro m
  induction m with
  | zero => intro _; rfl
  | succ m ih =>
    intro h
    have hsplit : (List.range (m + 1)).flatMap f = (List.range m).flatMap f ++ f m := by
      rw [List.range_succ]; simp
    rw [hsplit]
    refine ssaFrom_append _ _ _ (ih fun t ht => h t (Nat.lt_succ_of_lt ht)) ?_
    rw [length_flatMap_range]
    exact h m (Nat.lt_succ_self m)

theorem ssaFrom_map_range (f : Nat → Gate) (base : Nat) : ∀ m,
    (∀ t, t < m → (f t).out = base + t ∧
      (f t).op.fanin.all (fun a => a < base + t) = true) →
    ssaFrom base ((List.range m).map f) = true := by
  intro m
  induction m with
  | zero => intro _; rfl
  | succ m ih =>
    intro h
    rw [List.range_succ, List.map_append]
    refine ssaFrom_append _ _ _ (ih fun t ht => h t (Nat.lt_succ_of_lt ht)) ?_
    have hlen : ((List.range m).map f).length = m := by simp
    rw [hlen]
    show ssaFrom (base + m) [f m] = true
    exact ssaFrom_singleton (f m) (base + m) (h m (Nat.lt_succ_self m)).1
      (h m (Nat.lt_succ_self m)).2

/-! ## The shape of the level widths -/

/-- Level `j` is `2^(b-1-j)` muxes wide — for `j < b`; the division is exact. -/
theorem gsLevelWidth_pow {b j : Nat} (h : j < b) : gsLevelWidth b j = 2 ^ (b - (j + 1)) :=
  Nat.pow_div h (by decide)

/-- Each level is half the one below it. Needs `j + 1 < b` (there IS a level above). -/
theorem gsLevelWidth_halve {b j : Nat} (h : j + 1 < b) :
    gsLevelWidth b j = 2 * gsLevelWidth b (j + 1) := by
  rw [gsLevelWidth_pow (Nat.lt_of_succ_lt h), gsLevelWidth_pow h]
  have e : b - (j + 1) = (b - (j + 1 + 1)) + 1 := by omega
  rw [e, Nat.pow_succ]
  omega

/-- The bottom level has `2^b / 2 = 2^(b-1)` muxes, so the tree has `2^b` leaves. -/
theorem gsLevelWidth_zero {b : Nat} (hb : 0 < b) : 2 * gsLevelWidth b 0 = 2 ^ b := by
  rw [gsLevelWidth_pow hb]
  have e : (2 : Nat) ^ b = 2 ^ (b - (0 + 1)) * 2 := by
    rw [← Nat.pow_succ]
    congr 1
    omega
  rw [e]
  omega

/-- **The telescope, in closed form.** -/
theorem gsBelow_eq (b : Nat) : ∀ m, m ≤ b → gsBelow b m = 2 ^ b - 2 ^ (b - m) := by
  intro m
  induction m with
  | zero =>
    intro _
    show (0 : Nat) = 2 ^ b - 2 ^ (b - 0)
    simp
  | succ m ih =>
    intro h
    have hm : m ≤ b := Nat.le_of_succ_le h
    have hb : gsBelow b (m + 1) = gsBelow b m + gsLevelWidth b m := rfl
    rw [hb, ih hm, gsLevelWidth_pow h]
    have e1 : b - m = (b - (m + 1)) + 1 := by omega
    have e2 : (2 : Nat) ^ (b - m) = 2 * 2 ^ (b - (m + 1)) := by
      rw [e1, Nat.pow_succ]; omega
    have e3 : (2 : Nat) ^ (b - m) ≤ 2 ^ b := Nat.pow_le_pow_right (by decide) (by omega)
    omega

/-- `∑_{j<b} gsLevelWidth b j = 2^b - 1` — the sum silicon derived by hand. -/
theorem gsBelow_top (b : Nat) : gsBelow b b = 2 ^ b - 1 := by
  rw [gsBelow_eq b b (Nat.le_refl b)]
  simp

theorem gsBelow_top_pad (b : Nat) : gsBelow b b = gsPad b - 1 := gsBelow_top b

/-! ## The gate list, in named chunks -/

def gsConstGate (n b : Nat) : Gate := ⟨gsZero n b, .const false⟩

def gsNotGates (n b : Nat) : List Gate :=
  (List.range b).map (fun j => (⟨gsNot n b j, .not (gsSel n b j)⟩ : Gate))

def gsMuxLevel (n b k j : Nat) : List Gate :=
  (List.range (gsLevelWidth b j)).flatMap (gsMux n b k j)

def gsMuxBit (n b k : Nat) : List Gate := (List.range b).flatMap (gsMuxLevel n b k)

def gsMuxGates (n b : Nat) : List Gate := (List.range 32).flatMap (gsMuxBit n b)

theorem genSelect_gates_eq (n b : Nat) :
    (genSelect n b).gates = (gsConstGate n b :: gsNotGates n b) ++ gsMuxGates n b := rfl

/-! ## Lengths -/

theorem gsMux_length (n b k j i : Nat) : (gsMux n b k j i).length = 3 := rfl

theorem gsMuxLevel_length (n b k j : Nat) :
    (gsMuxLevel n b k j).length = gsLevelWidth b j * 3 := by
  show ((List.range (gsLevelWidth b j)).flatMap (gsMux n b k j)).length = _
  rw [length_flatMap_range, psum_const _ 3 (gsMux_length n b k j)]

theorem psum_gsMuxLevel (n b k : Nat) : ∀ t, psum (gsMuxLevel n b k) t = gsBelow b t * 3 := by
  intro t
  induction t with
  | zero => rfl
  | succ t ih =>
    rw [psum_succ, ih, gsMuxLevel_length]
    have hb : gsBelow b (t + 1) = gsBelow b t + gsLevelWidth b t := rfl
    rw [hb]
    omega

theorem gsMuxBit_length (n b k : Nat) : (gsMuxBit n b k).length = (gsPad b - 1) * 3 := by
  show ((List.range b).flatMap (gsMuxLevel n b k)).length = _
  rw [length_flatMap_range, psum_gsMuxLevel, gsBelow_top_pad]

/-- ⭐ **THE CLOSED FORM — with no hypotheses whatsoever.**
`n` does not appear, and `b = 0` is covered (`1` gate, the dead pad constant). -/
theorem genSelect_gates_length (n b : Nat) :
    (genSelect n b).gates.length = 96 * (2 ^ b - 1) + b + 1 := by
  rw [genSelect_gates_eq]
  rw [List.length_append, List.length_cons]
  show (gsNotGates n b).length + 1 + (gsMuxGates n b).length = _
  have hN : (gsNotGates n b).length = b := by
    show ((List.range b).map _).length = b
    simp
  have hK : (gsMuxGates n b).length = 32 * ((gsPad b - 1) * 3) := by
    show ((List.range 32).flatMap (gsMuxBit n b)).length = _
    rw [length_flatMap_range, psum_const _ ((gsPad b - 1) * 3) (gsMuxBit_length n b)]
  have hP : gsPad b = 2 ^ b := rfl
  rw [hN, hK, hP]
  omega

/-! ## Dense SSA at every `(n, b)`

The net-numbering obligations, one per fanin. `omega` sees `gsIn n b`,
`gsBase n b k j i`, `gsBelow b j` and `k * (gsPad b - 1)` as atoms; the
inequalities are linear in those atoms once the layout is unfolded. -/

theorem gsBase_lb (n b k j i : Nat) : gsIn n b + 1 + b ≤ gsBase n b k j i := by
  show gsIn n b + 1 + b ≤ gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b j + i) * 3
  omega

theorem gsNot_lt_base {n b k j i : Nat} (hj : j < b) : gsNot n b j < gsBase n b k j i := by
  have h := gsBase_lb n b k j i
  show gsIn n b + 1 + j < gsBase n b k j i
  omega

theorem gsSel_lt_base {n b k j i : Nat} (hj : j < b) : gsSel n b j < gsBase n b k j i := by
  have h := gsBase_lb n b k j i
  have hI : gsIn n b = n * 32 + b := rfl
  show n * 32 + j < gsBase n b k j i
  omega

/-- A level-`j` mux reads a level-`(j-1)` output that is strictly earlier. -/
theorem gsOut_lt_gsBase_succ {n b k j i i' : Nat} (h : i' < gsLevelWidth b j) :
    gsOut n b k j i' < gsBase n b k (j + 1) i := by
  have hb : gsBelow b (j + 1) = gsBelow b j + gsLevelWidth b j := rfl
  show gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b j + i') * 3 + 2
      < gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b (j + 1) + i) * 3
  rw [hb]
  omega

/-- Every net a mux reads is strictly below the mux's own first net. -/
theorem gsPrev_lt {n b k j i i' : Nat} (hk : k < 32) (hj : j < b)
    (hi' : i' < 2 * gsLevelWidth b j) : gsPrev n b k j i' < gsBase n b k j i := by
  cases j with
  | zero =>
    show (if n ≤ i' then gsZero n b else gsRes i' k) < gsBase n b k 0 i
    have hlb := gsBase_lb n b k 0 i
    have hI : gsIn n b = n * 32 + b := rfl
    by_cases h : n ≤ i'
    · rw [if_pos h]
      show gsIn n b < gsBase n b k 0 i
      omega
    · rw [if_neg h]
      show i' * 32 + k < gsBase n b k 0 i
      omega
  | succ j' =>
    have hh : gsLevelWidth b j' = 2 * gsLevelWidth b (j' + 1) := gsLevelWidth_halve hj
    show gsOut n b k j' i' < gsBase n b k (j' + 1) i
    exact gsOut_lt_gsBase_succ (by omega)

/-- ⭐ **One mux is dense SSA at its own base.** — THE REPAIRED THEOREM.

The three fanin obligations are discharged by `all_pair`, not by `omega`. Each
one is a two-element `List.all` over `List Net`, which `simp only` turns into a
conjunction of two `Net`-typed comparisons — a shape `omega` discards wholesale,
leaving it to hunt for `False` in the hypotheses alone. Nothing arithmetic was
missing: the five layout lemmas above already give every inequality needed, and
`all_pair` simply pairs them. -/
theorem gsMux_ssaFrom (n b k j i : Nat) (hk : k < 32) (hj : j < b)
    (hi : i < gsLevelWidth b j) :
    ssaFrom (gsBase n b k j i) (gsMux n b k j i) = true := by
  have h1 : gsPrev n b k j (2 * i) < gsBase n b k j i := gsPrev_lt hk hj (by omega)
  have h2 : gsPrev n b k j (2 * i + 1) < gsBase n b k j i := gsPrev_lt hk hj (by omega)
  have h3 : gsNot n b j < gsBase n b k j i := gsNot_lt_base hj
  have h4 : gsSel n b j < gsBase n b k j i := gsSel_lt_base hj
  -- The three fanin lists, each already lifted to the base its own gate reads at.
  have h2' : gsPrev n b k j (2 * i + 1) < gsBase n b k j i + 1 := by omega
  have h4' : gsSel n b j < gsBase n b k j i + 1 := by omega
  have h5 : gsBase n b k j i < gsBase n b k j i + 1 + 1 := by omega
  have h6 : gsBase n b k j i + 1 < gsBase n b k j i + 1 + 1 := by omega
  show ssaFrom (gsBase n b k j i)
      [(⟨gsBase n b k j i, .and (gsPrev n b k j (2 * i)) (gsNot n b j)⟩ : Gate),
       ⟨gsBase n b k j i + 1, .and (gsPrev n b k j (2 * i + 1)) (gsSel n b j)⟩,
       ⟨gsBase n b k j i + 2, .or (gsBase n b k j i) (gsBase n b k j i + 1)⟩] = true
  refine ssaFrom_triple _ _ _ _ rfl rfl ?_ ?_ ?_ ?_
  · show gsBase n b k j i + 2 = gsBase n b k j i + 1 + 1
    omega
  · show ([gsPrev n b k j (2 * i), gsNot n b j] : List Net).all
        (fun a => a < gsBase n b k j i) = true
    exact all_pair h1 h3
  · show ([gsPrev n b k j (2 * i + 1), gsSel n b j] : List Net).all
        (fun a => a < gsBase n b k j i + 1) = true
    exact all_pair h2' h4'
  · show ([gsBase n b k j i, gsBase n b k j i + 1] : List Net).all
        (fun a => a < gsBase n b k j i + 1 + 1) = true
    exact all_pair h5 h6

theorem gsMuxLevel_ssaFrom (n b k j : Nat) (hk : k < 32) (hj : j < b) :
    ssaFrom (gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b j) * 3)
      (gsMuxLevel n b k j) = true := by
  show ssaFrom _ ((List.range (gsLevelWidth b j)).flatMap (gsMux n b k j)) = true
  refine ssaFrom_flatMap_range _ _ _ ?_
  intro t ht
  rw [psum_const _ 3 (gsMux_length n b k j) t]
  have heq : gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b j) * 3 + t * 3
      = gsBase n b k j t := by
    show _ = gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b j + t) * 3
    omega
  rw [heq]
  exact gsMux_ssaFrom n b k j t hk hj ht

theorem gsMuxBit_ssaFrom (n b k : Nat) (hk : k < 32) :
    ssaFrom (gsIn n b + 1 + b + k * ((gsPad b - 1) * 3)) (gsMuxBit n b k) = true := by
  have hassoc : k * ((gsPad b - 1) * 3) = k * (gsPad b - 1) * 3 := (Nat.mul_assoc _ _ _).symm
  rw [hassoc]
  show ssaFrom _ ((List.range b).flatMap (gsMuxLevel n b k)) = true
  refine ssaFrom_flatMap_range _ _ _ ?_
  intro t ht
  rw [psum_gsMuxLevel n b k t]
  have heq : gsIn n b + 1 + b + k * (gsPad b - 1) * 3 + gsBelow b t * 3
      = gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b t) * 3 := by omega
  rw [heq]
  exact gsMuxLevel_ssaFrom n b k t hk ht

theorem gsMuxGates_ssaFrom (n b : Nat) :
    ssaFrom (gsIn n b + 1 + b) (gsMuxGates n b) = true := by
  show ssaFrom _ ((List.range 32).flatMap (gsMuxBit n b)) = true
  refine ssaFrom_flatMap_range _ _ _ ?_
  intro t ht
  rw [psum_const _ ((gsPad b - 1) * 3) (gsMuxBit_length n b) t]
  exact gsMuxBit_ssaFrom n b t ht

theorem gsConstGate_ssaFrom (n b : Nat) : ssaFrom (gsIn n b) [gsConstGate n b] = true :=
  ssaFrom_singleton _ _ rfl rfl

theorem gsNotGates_ssaFrom (n b : Nat) : ssaFrom (gsIn n b + 1) (gsNotGates n b) = true := by
  show ssaFrom (gsIn n b + 1)
    ((List.range b).map (fun j => (⟨gsNot n b j, .not (gsSel n b j)⟩ : Gate))) = true
  refine ssaFrom_map_range _ _ _ ?_
  intro t _
  refine ⟨rfl, ?_⟩
  show ([gsSel n b t] : List Net).all (fun a => a < gsIn n b + 1 + t) = true
  have hI : gsIn n b = n * 32 + b := rfl
  have hlt : gsSel n b t < gsIn n b + 1 + t := by
    show n * 32 + t < gsIn n b + 1 + t
    omega
  simp only [List.all_cons, List.all_nil, Bool.and_true, decide_eq_true_eq]
  exact hlt

/-- ⭐ **THE GATE LIST IS DENSE SSA FROM `nIn`, AT EVERY `n` AND EVERY `b`.**
No hypothesis — not even `0 < b`, and not `n ≤ 2^b`. -/
theorem genSelect_ssaFrom (n b : Nat) : ssaFrom (gsIn n b) (genSelect n b).gates = true := by
  rw [genSelect_gates_eq]
  refine ssaFrom_append _ _ _ ?_ ?_
  · have h : (gsConstGate n b :: gsNotGates n b) = [gsConstGate n b] ++ gsNotGates n b := rfl
    rw [h]
    refine ssaFrom_append _ _ _ (gsConstGate_ssaFrom n b) ?_
    show ssaFrom (gsIn n b + 1) (gsNotGates n b) = true
    exact gsNotGates_ssaFrom n b
  · have hlen : (gsConstGate n b :: gsNotGates n b).length = b + 1 := by
      show (gsNotGates n b).length + 1 = b + 1
      show ((List.range b).map _).length + 1 = b + 1
      simp
    rw [hlen]
    have he : gsIn n b + (b + 1) = gsIn n b + 1 + b := by omega
    rw [he]
    exact gsMuxGates_ssaFrom n b

/-- ⭐ **`Circ.ssa` — dense SSA *and* every primary output inside the netlist.**
`0 < b` IS required here (and only here): at `b = 0` the recorded output net
`gsOut n 0 k 0 0` lies three past the only gate. Refuted below. -/
theorem genSelect_ssa (n b : Nat) (hb : 0 < b) : (genSelect n b).ssa = true := by
  have hnIn : (genSelect n b).nIn = gsIn n b := rfl
  show (ssaFrom (genSelect n b).nIn (genSelect n b).gates
      && (genSelect n b).outs.all
          (fun m => m < (genSelect n b).nIn + (genSelect n b).gates.length)) = true
  rw [Bool.and_eq_true, hnIn, genSelect_gates_length]
  refine ⟨genSelect_ssaFrom n b, ?_⟩
  show ((List.range 32).map (fun k => gsOut n b k (b - 1) 0)).all
      (fun m => m < gsIn n b + (96 * (2 ^ b - 1) + b + 1)) = true
  rw [List.all_eq_true]
  intro x hx
  simp only [List.mem_map, List.mem_range] at hx
  obtain ⟨k, hk, rfl⟩ := hx
  simp only [decide_eq_true_eq]
  have hbel : gsBelow b (b - 1) = 2 ^ b - 2 ^ (b - (b - 1)) := gsBelow_eq b (b - 1) (by omega)
  have he : b - (b - 1) = 1 := by omega
  rw [he] at hbel
  have hP : 1 < 2 ^ b := Nat.one_lt_two_pow (by omega)
  have hkP : k * (2 ^ b - 1) ≤ 31 * (2 ^ b - 1) :=
    Nat.mul_le_mul (by omega) (Nat.le_refl _)
  have hpad : gsPad b = 2 ^ b := rfl
  show gsIn n b + 1 + b + (k * (gsPad b - 1) + gsBelow b (b - 1) + 0) * 3 + 2
      < gsIn n b + (96 * (2 ^ b - 1) + b + 1)
  rw [hpad, hbel]
  omega

/-- ⭐ **AND THEREFORE WELL-FORMED, AT EVERY `n` AND EVERY `b > 0`.** -/
theorem genSelect_wf (n b : Nat) (hb : 0 < b) : (genSelect n b).wf = true :=
  Circ.wf_of_ssa (genSelect_ssa n b hb)

/-! ## `0 < b` is necessary — the refutation, in the kernel -/

/-- At `b = 0` the tree has no levels, so `gsOut n 0 k (0-1) 0` names a net three
past the single gate. `Circ.ssa` is FALSE, and `genSelect n 0` is not a circuit
anyone may price. -/
theorem genSelect_zero_b_not_ssa : (genSelect 5 0).ssa = false := by decide +kernel

/-! ## The three kernel anchors, recovered FROM the closed form -/

/-- 98 at the operand-B pair. *(ALIAS since 16:3x — silicon's six-pair divergence sweep. Two independent proofs of one proposition can DIVERGE at a re-cut: one gets updated, the other stays kernel-checked, audited, ticked, and false. The alias forecloses it.)* -/
theorem gate_count_two : (genSelect 2 1).gates.length = 98 :=
  genSelect_two_gate_count

/-- 291 at the ruled pair. *(ALIAS since 16:3x — silicon's six-pair divergence sweep. Two independent proofs of one proposition can DIVERGE at a re-cut: one gets updated, the other stays kernel-checked, audited, ticked, and false. The alias forecloses it.)* -/
theorem gate_count_three : (genSelect 3 2).gates.length = 291 :=
  genSelect_three_gate_count

theorem gate_count_ten : (genSelect 10 4).gates.length = 1445 := by
  rw [genSelect_gates_length]
  rfl

/-- The landed block's recorded size, now a corollary of the closed form — and
stated with **no numeral**, so the phase-3 re-cut cannot falsify it.

⚠️ **THIS THEOREM WAS THE ONE PHASE 3'S ESTIMATE MISSED.** *It read
`aluSelect.gates.length = 1445` and was proved `rw [← genSelect_ten]; exact
gate_count_ten` — so BOTH halves were re-cut hazards, and the statement was the
worse one. The proof rode `genSelect_ten`, the numeral-bound bridge phase 3
retires; the STATEMENT carried the `(10,4)` gate count, so moving the constants
would have made a LANDED THEOREM FALSE rather than merely unproved. A "zero
consumers" reading of the bridge missed it because the census asked what the
bridge PROVES, never who `rw`s with it.*

✅ **THE PROOF IS REPOINTED AT MATH'S PARAMETRIC HINGE AND THE STATEMENT IS LEFT
EXACTLY AS IT WAS** — `= 1445`, unchanged to the byte. That is the expand half of
expand-contract: the `genSelect_ten` dependency is gone, so the ladder can be
deleted in the next commit, and no consumer of THIS theorem sees any difference.
The numeral moves to `291` in the flip commit, where it belongs, beside the
tripwires that are supposed to fire.

⛔ **AND IT MUST STAY `= 1445` UNTIL THEN — I TRIED THE PARAMETRIC STATEMENT HERE
AND IT BROKE TWO LANDED THEOREMS.** *`SelectCut32.gate_saving` and
`SelectCut32.span_delta` both do `have h1 := gate_count_aluSelect; omega`. Stated
as `96 * (2 ^ asSelBits - 1) + asSelBits + 1` the equation is still TRUE at
`(10,4)` — but `omega` cannot use it, because `2 ^ asSelBits` is not linear
arithmetic. Both proofs failed, and `#audit_axioms` caught the `sorryAx` their
failed `omega` installed.* ⇒ 🔑 ***A truth-preserving change of a statement's
SHAPE is still a breaking change. Expand-contract has to preserve what consumers
can USE, not merely what is true — and a tactic's reach is part of the interface.***

📌 **THE NUMERAL MOVED `1445 → 291` AT THE FLIP, WHICH IS THE ONE EDIT THIS
THEOREM WAS SUPPOSED TO COST.** *`decide` reported it precisely — "proved that the
proposition is false" — so the literal is doing its job as a tripwire while
`gate_count_aluSelect_param` below carries the pair-independent form.* -/
theorem gate_count_aluSelect : aluSelect.gates.length = 291 := by
  rw [← genSelect_eq_aluSelect, genSelect_gates_length]
  decide

/-- The same count with **no numeral**, for the post-re-cut world: true at every
pair, and the form `gate_count_aluSelect` takes once the constants move.

📌 *Landed BESIDE the literal one rather than replacing it — the phase-1 pattern,
applied to a theorem instead of a block. Consumers migrate to this at their own
pace; `omega`-based ones cannot migrate at all and must be given a literal.* -/
theorem gate_count_aluSelect_param :
    aluSelect.gates.length = 96 * (2 ^ asSelBits - 1) + asSelBits + 1 := by
  rw [← genSelect_eq_aluSelect, genSelect_gates_length]

/-- ⭐ **THE GAP BETWEEN THE TWO PROVED POINTS, CLOSED**: `b = 3`, the
eight-source width, 676 gates — and now `ssa`/`wf` as well. -/
theorem gate_count_eight : (genSelect 8 3).gates.length = 676 := by
  rw [genSelect_gates_length]
  rfl

/-- ⭐ **THE MUSTER'S CONFIGURATION.** `b = 3` is an instance of the general
theorem, not a separate `decide` point. -/
theorem genSelect_eight_ssa : (genSelect 8 3).ssa = true := genSelect_ssa 8 3 (by decide)
theorem genSelect_eight_wf : (genSelect 8 3).wf = true := genSelect_wf 8 3 (by decide)

/-! ## `n ≤ 2^b` is NOT needed for the count, and NOT needed for well-formedness

It is needed for the circuit to READ every source. Leaf indices run `0 ..< 2^b`
(`gsLevelWidth_zero`), and a leaf whose index is `≥ n` reads the shared pad
constant (`gsPrev_zero_of_ge`). So a source `r` with `2^b ≤ r` is wired to no
leaf at all — `genSelect 20 4` is a perfectly well-formed 1,445-gate circuit
that silently ignores four of its twenty sources. -/

theorem gsPrev_zero_of_ge {n b k i : Nat} (h : n ≤ i) : gsPrev n b k 0 i = gsZero n b := by
  show (if n ≤ i then gsZero n b else gsRes i k) = gsZero n b
  rw [if_pos h]

theorem gate_count_twenty : (genSelect 20 4).gates.length = 1445 := by
  rw [genSelect_gates_length]
  rfl

theorem genSelect_twenty_ssa : (genSelect 20 4).ssa = true := genSelect_ssa 20 4 (by decide)
theorem genSelect_twenty_wf : (genSelect 20 4).wf = true := genSelect_wf 20 4 (by decide)

/-! ### Which sources a leaf actually reads — the kernel witnesses -/

/-- At `n = 20, b = 4`: **no leaf is the pad.** All sixteen read real sources. -/
theorem twenty_no_leaf_pads (k i : Nat) (hi : i < 16) :
    gsPrev 20 4 k 0 i = gsRes i k := by
  show (if 20 ≤ i then gsZero 20 4 else gsRes i k) = gsRes i k
  rw [if_neg (by omega)]

/-- …and a source at or above `2^b` is read by NO leaf: `16..19` are lost. -/
theorem twenty_ignores_high (k r i : Nat) (hr : 16 ≤ r) (hi : i < 16) :
    gsPrev 20 4 k 0 i ≠ gsRes r k := by
  rw [twenty_no_leaf_pads k i hi]
  show i * 32 + k ≠ r * 32 + k
  omega

/-- The `ten` in the mis-stated claim is `genSelect 10 4`: there, six of the
sixteen leaves pad. Same `b`, different `n`, different read-set. -/
theorem ten_pads_six (k i : Nat) (h1 : 10 ≤ i) (h2 : i < 16) :
    gsPrev 10 4 k 0 i = gsZero 10 4 :=
  gsPrev_zero_of_ge h1
/-! ## Axiom audit — ONE declaration per call.

`#audit_axioms` aborts the rest of its own argument list at the first failure,
so a multi-name call silently hides the status of every name after a failure.
One name per call makes "not reported" impossible. -/

#audit_axioms psum
#audit_axioms psum_succ
#audit_axioms length_flatMap_range
#audit_axioms psum_const
#audit_axioms ssaFrom_append
#audit_axioms ssaFrom_singleton
#audit_axioms all_pair
#audit_axioms ssaFrom_triple
#audit_axioms ssaFrom_flatMap_range
#audit_axioms ssaFrom_map_range
#audit_axioms gsLevelWidth_pow
#audit_axioms gsLevelWidth_halve
#audit_axioms gsLevelWidth_zero
#audit_axioms gsBelow_eq
#audit_axioms gsBelow_top
#audit_axioms gsBelow_top_pad
#audit_axioms gsConstGate
#audit_axioms gsNotGates
#audit_axioms gsMuxLevel
#audit_axioms gsMuxBit
#audit_axioms gsMuxGates
#audit_axioms genSelect_gates_eq
#audit_axioms gsMux_length
#audit_axioms gsMuxLevel_length
#audit_axioms psum_gsMuxLevel
#audit_axioms gsMuxBit_length
#audit_axioms genSelect_gates_length
#audit_axioms gsBase_lb
#audit_axioms gsNot_lt_base
#audit_axioms gsSel_lt_base
#audit_axioms gsOut_lt_gsBase_succ
#audit_axioms gsPrev_lt
#audit_axioms gsMux_ssaFrom
#audit_axioms gsMuxLevel_ssaFrom
#audit_axioms gsMuxBit_ssaFrom
#audit_axioms gsMuxGates_ssaFrom
#audit_axioms gsConstGate_ssaFrom
#audit_axioms gsNotGates_ssaFrom
#audit_axioms genSelect_ssaFrom
#audit_axioms genSelect_ssa
#audit_axioms genSelect_wf
#audit_axioms genSelect_zero_b_not_ssa
#audit_axioms gate_count_two
#audit_axioms gate_count_three
#audit_axioms gate_count_ten
#audit_axioms gate_count_aluSelect
#audit_axioms gate_count_eight
#audit_axioms genSelect_eight_ssa
#audit_axioms genSelect_eight_wf
#audit_axioms gsPrev_zero_of_ge
#audit_axioms gate_count_twenty
#audit_axioms genSelect_twenty_ssa
#audit_axioms genSelect_twenty_wf
#audit_axioms twenty_no_leaf_pads
#audit_axioms twenty_ignores_high
#audit_axioms ten_pads_six

end GSCount
end SaltWorks.HDL
