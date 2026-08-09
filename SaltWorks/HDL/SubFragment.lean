/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Adder
import SaltWorks.HDL.Bitwise
import SaltWorks.HDL.Compose
import SaltWorks.HDL.SingleLevel

/-!
# THE FIRST ASSEMBLED FRAGMENT — `bitNot32` → `adder32`, instantiated

⭐ **Two of this corpus's organs, INSTANTIATED into one `Circ` and proved to compose.**
`docs/compiler-inventory-0808.md` §Q1 records that no assembled datapath exists and that the
remaining work is *"a construction, not a lemma."* **Nobody had ever instantiated two of these
organs.** This is a PROBE of that claim — ruled in-slot 21:20, and it does **not** open the
core-construction campaign, which stays gated.

**Why this pair:** it is §4's rows 5→6 of the assembly plan and a genuine Slice-A requirement —
`SLT` needs `a − b`, which this corpus computes as `a + ~b + 1`.
```
host    a:0…31   b:32…63   one:64                      off = 65
inst1   bitNot32  σ₁ i = 32+i                        → instNext = 97
inst2   adder32   σ₂ i = i | 65+(i−32) | 64
composite: 192 gates (32 + 160), 33 outputs
```

## THE PRE-REGISTERED BAR (bus 21:20), ANSWERED LINE BY LINE

| # | bar | verdict |
|---|---|---|
| 1 | the composite is constructed and measured | ✅ **MET** — 192 gates, 33 outs, `instNext` = 97 |
| 2 | `instOK bitNot32 σ₁ 65` discharges | ✅ **MET** (`ok1`) |
| 3 | `instOK adder32 σ₂ 97` — *"the one I expect to bite"* | ✅ **MET** (`ok2`) — the one-gate margin (max σ₂ = 96 < 97) held |
| 4 | the two organs' specs COMPOSE | ✅ **MET IN FULL, 21:4x — `frag_subtraction`** |
| 5 | the composition is REFUTABLE by mis-wiring | ✅ **MET, after my first control proved VACUOUS** |

## ✅ BAR 4 WAS PARTIAL FOR TWO HOURS, AND WHY IT WAS IS THE PROBE'S MOST USEFUL RESULT

**Closed at 21:4x by `frag_subtraction`:**
```lean
frag_subtraction (env) : sem subFragment env = sem adder32 (subOperands env)
subOperands env a = if a < 32 then env a else if a < 64 then !(env a) else env 64
```
***∀ env, no side condition, no fixture: the composite computes `adder32` on `a`, `~b`, `one`.
THE TWO ORGANS' SPECS COMPOSE.***

⛔ **BUT THE REASON IT TOOK TWO HOURS IS THE FINDING, AND IT IS NOT ABOUT THIS FILE.** The
missing premise was `bitNot32`'s semantics at every input — **which this corpus did not have.**
`bitNot32_correct_on_sample` is a Bool sweep over fixtures. It took a new module
(`SingleLevel.lean`, `run_level_map` + `bitNot32_sem`) to supply it.
⇒ ***`Compose.lean`'s four lemmas did everything asked of them. THE SAMPLED CERTIFICATES BECAME
LOAD-BEARING THE MOMENT TWO ORGANS MET*** — a different repair from what *"a construction, not a
lemma"* implies. ⚠️ **And `bitXor32`, `bitAnd32`, `bitOr32` are STILL sampled-only, so the next
organ pair will hit the same wall.**

📌 **AND THE SECOND OBSTRUCTION, WHICH COST MORE THAN THE FIRST: `omega` DOES NOT WORK ON
`Net`-ASCRIBED GOALS.** Measured with `pp.all`: `Net` occupies the TYPE ARGUMENT of `LT.lt` and
`OfNat.ofNat` (`@LT.lt.{0} SaltWorks.HDL.Net instLTNat …`) while the *instance* is the `Nat` one —
and omega matches syntactically on `Nat`, so it collects **no constraints at all**.
```
✅ CURED BY   simp only [Net] at h ⊢          (unfolds the reducible type in the type slot)
✅ OR BY      explicit Nat.* lemmas, no omega  (the instances are already Nat's)
⛔ NOT BY     `show (a : Nat) …`  — defeq no-op, does not change the elaborated term
⛔ NOR BY     rebinding through a Nat-typed `have`
```
*Every layout constant here is also a `Nat`-valued `def`, which is a SEPARATE omega failure cured
by `simp only [<the def>]`. The proofs below use both cures.*

## ⛔ AND MY FIRST CONTROL WAS VACUOUS — the kernel caught it, not me

I mis-wired by **swapping the adder's two operand ranges** (`a`-port ← `~b`, `b`-port ← `a`).
`decide` refuted the control: ***addition COMMUTES, so that "mis-wiring" is a NO-OP.***
🔑 **The obvious perturbation was the one perturbation that CANNOT fail — for a structural
reason, invisible until measured.** ⇒ *A mutation control has to break something the SPEC
depends on, and "obviously different wiring" is not the same as "different behaviour". The
replacements target the two things that actually make this a subtractor: the negation
(`control_negation_is_load_bearing`) and the carry-in (`control_carry_in_is_load_bearing`).*

## THE ROWS, BY NAME

| row | says |
|---|---|
| `hOff`, `sig1`, `n1`, `sig2` | the layout |
| `subFragment` | the composite `Circ` |
| `sig1_bounded`, `sig2_bounded` | the σ bounds, decided on concrete ranges |
| `ok1`, `ok2` | ⭐ **`instOK` discharges for both instances** |
| `fedEnv` | the env `adder32` sees — **circuit-defined; this is why bar 4 is partial** |
| `adder_outs_are_gates` | every `adder32` output is a gate output (`inst_compose_sem`'s side condition) |
| `frag_sem` | ⭐ **∀ env, the composite computes `adder32` on `fedEnv`** |
| `frag_is_subtraction_on_sample` | the content on one concrete pair — kept as the provenance |
| `notInst_shape` | the instantiated `bitNot32` is ITSELF single-level at `hOff`, so `run_level_map` applies with **no `inst_sem` detour** |
| `notInst_fanin`, `below_untouched` | the side condition, and: the composite leaves every net below `hOff` untouched |
| `fedEnv_closed`, `subOperands`, `fedEnv_eq_subOperands` | ⭐ what the composite feeds `adder32`, IN CLOSED FORM, ∀ a |
| ⭐⭐ `frag_subtraction` | **BAR 4: `sem subFragment env = sem adder32 (subOperands env)`, ∀ env** |
| `fragNoNot`, `control_negation_is_load_bearing` | drop the negation ⇒ refuted |
| `hostEnvNoCin`, `control_carry_in_is_load_bearing` | drop the carry-in ⇒ refuted |

## ⛔ WHAT THIS IS NOT

**Two organs of fourteen. NOT a `core`. NO `StateCodec` conformance. Nothing about the register
file, the pc path, the decoder or the select.** The Slice-A assembly is **10,372** gates
(`docs/compiler-slicea-assembly-reprice-0808.md`); this fragment is **192** of them.
-/

namespace SaltWorks.HDL
namespace SubFrag

def hOff : Nat := 65
def sig1 (i : Net) : Net := 32 + i
def n1 : Nat := instNext bitNot32 hOff
def sig2 (i : Net) : Net := if i < 32 then i else if i < 64 then hOff + (i - 32) else 64

def subFragment : Circ :=
  { nIn := 65
  , gates := instGates bitNot32 sig1 hOff ++ instGates adder32 sig2 n1
  , outs := instOuts adder32 sig2 n1 }


-- BAR 2 and 3: the sigma side conditions
theorem sig1_bounded : ((List.range 32).all fun i => sig1 i < hOff) = true := by decide
theorem sig2_bounded : ((List.range 65).all fun i => sig2 i < n1) = true := by decide

theorem ok1 : instOK bitNot32 sig1 hOff := by
  refine ⟨bitNot32_ssa, bitNot32_wf, ?_⟩
  intro i hi
  have hi' : i < 32 := hi
  have := List.all_eq_true.mp sig1_bounded i (List.mem_range.mpr hi')
  simpa using this

theorem ok2 : instOK adder32 sig2 n1 := by
  refine ⟨adder32_ssa, adder32_wf, ?_⟩
  intro i hi
  have hi' : i < 65 := hi
  have := List.all_eq_true.mp sig2_bounded i (List.mem_range.mpr hi')
  simpa using this




-- the env adder32 SEES inside the composite, defined by the circuit
def fedEnv (env : Env) (a : Net) : Bool :=
  run env (instGates bitNot32 sig1 hOff) (sig2 a)

-- every adder32 out is a gate output, so inst_compose_sem's side condition holds
theorem adder_outs_are_gates :
    (adder32.outs.all fun a => (adder32.gates.map Gate.out).contains a) = true := by
  decide +kernel

set_option maxRecDepth 8000 in
theorem frag_sem (env : Env) : sem subFragment env = sem adder32 (fedEnv env) := by
  simp only [sem, subFragment, instOuts, List.map_map]
  apply List.map_congr_left
  intro a ha
  have hg : (adder32.gates.map Gate.out).contains a = true :=
    List.all_eq_true.mp adder_outs_are_gates a ha
  exact inst_compose_sem bitNot32 adder32 sig1 sig2 hOff ok2 env (fedEnv env)
    (fun i _ => rfl) a (Or.inr hg)

-- SAMPLED: the fragment really computes a + ~b + 1, on a concrete pair
def hostEnv (a b : BitVec 32) (n : Net) : Bool :=
  if n < 32 then a.getLsbD n else if n < 64 then b.getLsbD (n - 32) else true

def subEnv (a b : BitVec 32) (n : Net) : Bool :=
  if n < 32 then a.getLsbD n else if n < 64 then !(b.getLsbD (n - 32)) else true

set_option maxRecDepth 100000 in
theorem frag_is_subtraction_on_sample :
    sem subFragment (hostEnv 100 37) = sem adder32 (subEnv 100 37) := by
  decide +kernel

-- ⛔ CONTROL, SECOND ATTEMPT. My first was VACUOUS and `decide` caught it:
--    sig2bad swapped the adder's two operand ranges, computing ~b + a + 1 instead of
--    a + ~b + 1 — and ADDITION COMMUTES, so the "mis-wiring" is a NO-OP. The obvious
--    perturbation was the one perturbation that cannot fail.
-- These two break the two things that actually MAKE it a subtractor:

-- (i) skip the negation: b feeds the adder directly ⇒ a + b + 1, not a − b
def sig2noNot (i : Net) : Net := if i < 32 then i else if i < 64 then i else 64
def fragNoNot : Circ :=
  { nIn := 65
  , gates := instGates bitNot32 sig1 hOff ++ instGates adder32 sig2noNot n1
  , outs := instOuts adder32 sig2noNot n1 }

set_option maxRecDepth 100000 in
theorem control_negation_is_load_bearing :
    sem fragNoNot (hostEnv 100 37) ≠ sem adder32 (subEnv 100 37) := by
  decide +kernel

-- (ii) drop the carry-in: a + ~b + 0 ⇒ off by one (a − b − 1)
def hostEnvNoCin (a b : BitVec 32) (n : Net) : Bool :=
  if n < 32 then a.getLsbD n else if n < 64 then b.getLsbD (n - 32) else false

set_option maxRecDepth 100000 in
theorem control_carry_in_is_load_bearing :
    sem subFragment (hostEnvNoCin 100 37) ≠ sem adder32 (subEnv 100 37) := by
  decide +kernel

theorem notInst_shape :
    instGates bitNot32 sig1 hOff
      = (List.range 32).map (fun k => (⟨hOff + k, Op.not (32 + k)⟩ : Gate)) := by
  simp only [instGates, bitNot32, List.map_map]
  apply List.map_congr_left
  intro k hk
  have hk32 : k < 32 := List.mem_range.mp hk
  have h1 : ¬ (32 + k < 32) := Nat.not_lt.mpr (Nat.le_add_right 32 k)
  simp [instMap, sig1, Op.rename, hk32, h1]

theorem notInst_fanin (k : Nat) (hk : k < 32) :
    ∀ x ∈ (Op.not (32 + k)).fanin, x < hOff := by
  intro x hx
  simp only [Op.fanin, List.mem_singleton] at hx
  subst hx
  show 32 + k < hOff
  simp only [hOff]; omega

/-- the composite leaves every net below `hOff` untouched -/
theorem below_untouched (env : Env) (x : Net) (hx : x < hOff) :
    run env (instGates bitNot32 sig1 hOff) x = env x := by
  refine run_of_unwritten env _ x (fun g hg => ?_)
  rw [notInst_shape] at hg
  obtain ⟨k, _, hgk⟩ := List.mem_map.mp hg
  subst hgk
  show hOff + k ≠ x
  intro hc
  exact absurd (hc ▸ hx) (Nat.not_lt.mpr (Nat.le_add_right hOff k))

/-- ⭐ what the composite feeds `adder32`, IN CLOSED FORM -/
theorem fedEnv_closed (env : Env) (a : Net) :
    fedEnv env a = (if a < 32 then env a else if a < 64 then !(env a) else env 64) := by
  unfold fedEnv sig2
  by_cases h1 : a < 32
  · rw [if_pos h1, if_pos h1]
    exact below_untouched env a (by simp only [hOff, Net] at h1 ⊢; omega)
  · rw [if_neg h1, if_neg h1]
    by_cases h2 : a < 64
    · rw [if_pos h2, if_pos h2, notInst_shape]
      have ha32 : 32 ≤ a := Nat.not_lt.mp h1
      have ha64 : a < 64 := h2
      have hk : a - 32 < 32 := by simp only [Net] at ha32 ha64 ⊢; omega
      rw [run_level_map hOff 32 (fun k => Op.not (32 + k)) env
            (fun k hk' => notInst_fanin k hk') (a - 32) hk]
      have he : 32 + (a - 32) = a := Nat.add_sub_cancel' ha32
      simp [Op.eval, he]
    · rw [if_neg h2, if_neg h2]
      exact below_untouched env 64 (by simp only [hOff]; decide)

/-- the closed-form environment: `a`, then `~b`, then the carry-in -/
def subOperands (env : Env) (a : Net) : Bool :=
  if a < 32 then env a else if a < 64 then !(env a) else env 64

theorem fedEnv_eq_subOperands (env : Env) : fedEnv env = subOperands env :=
  funext (fun a => fedEnv_closed env a)

/-- ⭐⭐⭐ BAR 4, FULLY MET: the composite computes `adder32` on `a`, `~b`, `one` —
`∀ env`, no side condition, no fixture. THE TWO ORGANS' SPECS COMPOSE. -/
theorem frag_subtraction (env : Env) :
    sem subFragment env = sem adder32 (subOperands env) := by
  rw [frag_sem, fedEnv_eq_subOperands]

#audit_axioms hOff
#audit_axioms sig1
#audit_axioms n1
#audit_axioms sig2
#audit_axioms subFragment
#audit_axioms sig1_bounded
#audit_axioms sig2_bounded
#audit_axioms ok1
#audit_axioms ok2
#audit_axioms fedEnv
#audit_axioms adder_outs_are_gates
#audit_axioms frag_sem
#audit_axioms hostEnv
#audit_axioms subEnv
#audit_axioms frag_is_subtraction_on_sample
#audit_axioms sig2noNot
#audit_axioms fragNoNot
#audit_axioms control_negation_is_load_bearing
#audit_axioms hostEnvNoCin
#audit_axioms control_carry_in_is_load_bearing
#audit_axioms notInst_shape
#audit_axioms notInst_fanin
#audit_axioms below_untouched
#audit_axioms fedEnv_closed
#audit_axioms subOperands
#audit_axioms fedEnv_eq_subOperands
#audit_axioms frag_subtraction

end SubFrag
end SaltWorks.HDL
