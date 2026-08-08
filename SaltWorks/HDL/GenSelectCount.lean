/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.AluSelect

/-!
# `genSelect n b` — the closed-form gate count

**`genSelect_gates_length` : `(genSelect n b).gates.length = 96 * (2^b - 1) + b + 1`
— NO hypotheses at all.** `n` is genuinely absent, so a source is free and a
SELECT BIT is what costs. Every kernel anchor below is `rw`-recovered FROM this
identity rather than re-derived by an independent `decide`: three `decide`s that
agree is not evidence a formula holds; six anchors that fall out of it is.

Also here, because each is needed to read the identity correctly:
* `genSelect_zero_b_not_ssa` — `(genSelect 5 0).ssa = false`. `0 < b` is not
  decoration; the count is arithmetically fine at `b = 0` and the object is not
  a circuit.
* `gsPrev_zero_of_ge` + the read-set witnesses — `n ≤ 2^b` is needed for neither
  the count nor the SSA scaffolding, only for the sources to be READ.
* The `ssaFrom` scaffolding and net-ordering bounds, which the general
  well-formedness proof is built on.

## ⛔ SCOPE — what this module does NOT contain

**`genSelect_ssa` / `genSelect_wf` for general `(n, b)` are NOT here.** They were
written, and three `omega` goals inside `gsMux_ssaFrom` did not close; the
failed tactics filled their holes with `sorryAx`, so the whole chain was
withheld. **`b = 3` is therefore still proved well-formed at NO point** — the
open hole under the `aluSelect` sizing call, unchanged.

*Stated here rather than in a commit message because a module that carries the
count and the SSA scaffolding is exactly the one a reader would assume carries
the SSA theorem.*
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

/-- Every net a two-input gate reads is below its own net. -/
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

/-- **One mux is dense SSA at its own base.** -/
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

/-- At `b = 0` the tree has no levels, so `gsOut n 0 k (0-1) 0` names a net three
past the single gate. `Circ.ssa` is FALSE, and `genSelect n 0` is not a circuit
anyone may price. -/
theorem genSelect_zero_b_not_ssa : (genSelect 5 0).ssa = false := by decide +kernel

/-! ## The three kernel anchors, recovered FROM the closed form -/

theorem gate_count_two : (genSelect 2 1).gates.length = 98 := by
  rw [genSelect_gates_length]
  rfl

theorem gate_count_three : (genSelect 3 2).gates.length = 291 := by
  rw [genSelect_gates_length]
  rfl

theorem gate_count_ten : (genSelect 10 4).gates.length = 1445 := by
  rw [genSelect_gates_length]
  rfl

/-- The landed block's recorded size, now a corollary of the closed form. -/
theorem gate_count_aluSelect : aluSelect.gates.length = 1445 := by
  rw [← genSelect_ten]; exact gate_count_ten


/-- `b = 3` — the eight-source width, 676 gates. Recovered from the closed form,
not re-derived by an independent `decide`. -/
theorem gate_count_eight : (genSelect 8 3).gates.length = 676 := by
  rw [genSelect_gates_length]
  rfl
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

/-! ### Which sources a leaf actually reads — the kernel witnesses

⛔ A number repeated across three seats on 8/8 said `genSelect 20 4` *"silently
reads only ten of its twenty sources."* **That is wrong, and the conclusion it
was offered for is right.** Level-0 leaves are indexed `i < 2^b = 16`, and
`gsPrev … 0 i` pads only when `n ≤ i`. At `n = 20` no leaf pads: all sixteen
read real sources, and sources `16..19` are named by no leaf.

The `ten` belongs to `genSelect 10 4` — `aluSelect` — where six of the sixteen
leaves DO pad. The two configurations were conflated. -/

/-- At `n = 20, b = 4`: **no leaf is the pad.** All sixteen read real sources. -/
theorem twenty_no_leaf_pads (k i : Nat) (hi : i < 16) :
    gsPrev 20 4 k 0 i = gsRes i k := by
  show (if 20 ≤ i then gsZero 20 4 else gsRes i k) = gsRes i k
  rw [if_neg (by omega)]

/-- …and a source at or above `2^b` is read by NO leaf. Sources 16..19 are lost. -/
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

/-! ## Audit — ONE DECLARATION PER CALL.

`#audit_axioms A B C` abandons the REST OF ITS OWN LIST at the first failure,
so a name absent from the error list reads as clean when it was never reached.
Eight declarations were unreported that way in this file's scratch ancestor. -/

#audit_axioms psum_succ
#audit_axioms length_flatMap_range
#audit_axioms psum_const
#audit_axioms ssaFrom_append
#audit_axioms ssaFrom_singleton
#audit_axioms ssaFrom_triple
#audit_axioms ssaFrom_flatMap_range
#audit_axioms ssaFrom_map_range
#audit_axioms gsLevelWidth_pow
#audit_axioms gsLevelWidth_halve
#audit_axioms gsLevelWidth_zero
#audit_axioms gsBelow_eq
#audit_axioms gsBelow_top
#audit_axioms gsBelow_top_pad
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
#audit_axioms gsConstGate_ssaFrom
#audit_axioms gsNotGates_ssaFrom
#audit_axioms genSelect_zero_b_not_ssa
#audit_axioms gate_count_two
#audit_axioms gate_count_three
#audit_axioms gate_count_ten
#audit_axioms gate_count_aluSelect
#audit_axioms gate_count_eight
#audit_axioms gsPrev_zero_of_ge
#audit_axioms gate_count_twenty
#audit_axioms twenty_no_leaf_pads
#audit_axioms twenty_ignores_high
#audit_axioms ten_pads_six

end GSCount
end SaltWorks.HDL
