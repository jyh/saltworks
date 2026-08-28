/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import Mathlib.Tactic.NormNum
import Mathlib.Data.BitVec
import SaltWorks.Tactic.AuditAxioms

/-!
# THE BIT-SERIAL MAC INDUCTION — the arithmetic core

**Wave:** ruling #7's math probe, build wave opened 2026-08-09 13:30.
**Brief:** `docs/mac-induction-scope-v1.md` (this seat's own scope), with every
input since resolved by council:

* **width** — ruling #8: int8 values on the landed 32-bit datapath; the
  comparison rides `wordSignedOrder` **passed explicitly, never an `instance`**
  (`docs/the-order-invariant-v1.md`, and `Stack/Perm.lean:309` for why).
* **bias** — 11:37 ruling: the bias is the **first addend, streamed**, not a
  parallel preload. This is §E of the brief and it is why `macAfter 1 = b` and
  every partial-product index is shifted by one.
* **sign cycle** — §B3: a **separate composition lemma**, never folded into the
  recursion, so the induction stays uniform.
* **overflow** — §B5/D1: the int8 range and the demo fan-in give a bound with
  enormous margin; stated here as arithmetic, witnessed by `decide`.

## ⚠️ PRECONDITION PREAMBLE — WHAT THIS FILE CLAIMS, AND WHAT IT DOES NOT

**CLAIMED.** The cycle-indexed accumulation identity for a two's-complement
serial multiply-accumulate with a *streamed* bias: the uniform partial-sum
induction (`mac_partial`), the sign cycle as a separate step
(`mac_sign_cycle`), their composition (`mac_correct`), the identification of the
bit-stream's signed value with `BitVec.toInt` at int8 (`sval_eq_toInt`), the
ingress sign-extension lemma (`signExtend_toInt`), and the demo overflow bound.

**NOT CLAIMED — and this is a scope judgment I am flagging, not hiding.** The
brief asks for the induction *over `Seq.runTrace`, lifted by `runTrace_append`*.
This file proves the arithmetic at the **cycle level** over an explicit
cycle-indexed accumulator, and **does not** construct the `Circ`/`Seq`
realization or the simulation theorem linking it to `runTrace`. That bridge —
`macRun ≈ runTrace macSeq` — is **OWED and named**, and it is its own node: it
is bit-level carry reasoning, not this genre. Reported to the maestro rather
than silently substituted, per iron rule 1.

**MUTATION CONTROLS ARE RUN, NOT CITED** (§ at the end): a wrong-weight mutant
and a dropped-sign-cycle mutant, each shown **FALSE at an exhibited witness**.
-/

namespace SaltWorks.HDL.Mac

/-! ## 1. The partial sum — LSB-first, weight `W` -/

/-- `psum W x t` = `Σ_{j < t} W · x_j · 2^j`, accumulated LSB-first.
Structurally recursive: the recursion index **is** the cycle index (brief §B1,
"no fuel parameter"). -/
def psum (W : ℤ) (x : ℕ → Bool) : ℕ → ℤ
  | 0 => 0
  | t + 1 => psum W x t + (if x t then W * 2 ^ t else 0)

/-- Weight scales out of the partial sum. Needed because `mac_correct` compares a
`W`-weighted accumulation against `W ·` an unweighted signed value. -/
theorem psum_scale (W : ℤ) (x : ℕ → Bool) : ∀ t, psum W x t = W * psum 1 x t
  | 0 => by simp [psum]
  | t + 1 => by
      have ih := psum_scale W x t
      by_cases h : x t <;> simp [psum, h, ih, mul_add]

/-! ## 2. The streamed-bias accumulator — the cycle indexing of §E -/

/-- The accumulator after `t` cycles, with the bias **streamed as the first
addend**:

```
cycle 0 : 0            (nothing has arrived)
cycle 1 : b            (the bias is the first addend)
cycle 1+t : b + Σ_{j<t} W·x_j·2^j
```

A parallel preload would start at `b` and shift every index down by one — the
two mechanisms compute the same number and **index it differently**, and the
index is what the induction is about. -/
def macAfter (W b : ℤ) (x : ℕ → Bool) : ℕ → ℤ
  | 0 => 0
  | 1 => b
  | t + 2 => macAfter W b x (t + 1) + (if x t then W * 2 ^ t else 0)

/-- **THE UNIFORM INDUCTION (brief §B2).** One statement, one induction, no case
split — because the sign cycle is *not* folded in here. -/
theorem mac_partial (W b : ℤ) (x : ℕ → Bool) :
    ∀ t, macAfter W b x (t + 1) = b + psum W x t
  | 0 => by simp [macAfter, psum]
  | t + 1 => by
      have ih := mac_partial W b x t
      simp [macAfter, psum, ih, add_assoc]

/-! ## 3. The sign cycle — a SEPARATE composition step (brief §B3) -/

/-- The signed value of an `n`-bit two's-complement stream:
`Σ_{j<n-1} x_j 2^j − x_{n-1} 2^{n-1}`. -/
def sval (x : ℕ → Bool) (n : ℕ) : ℤ :=
  psum 1 x (n - 1) - (if x (n - 1) then 2 ^ (n - 1) else 0)

/-- The full MAC: `n` accumulation cycles, then the sign cycle **subtracts** the
top partial product. Separate by construction — folding it into `macAfter` would
make the recursion non-uniform at exactly one index. -/
def macFinal (W b : ℤ) (x : ℕ → Bool) (n : ℕ) : ℤ :=
  macAfter W b x n - (if x (n - 1) then W * 2 ^ (n - 1) else 0)

/-- **THE SIGN CYCLE, as its own composition lemma.** True by construction, and
stated so consumers cite *this* rather than unfolding `macFinal`. -/
theorem mac_sign_cycle (W b : ℤ) (x : ℕ → Bool) (n : ℕ) :
    macFinal W b x n = macAfter W b x n - (if x (n - 1) then W * 2 ^ (n - 1) else 0) :=
  rfl

/-- **THE COMPOSITION — `mac_partial` ∘ `mac_sign_cycle`.**
`acc = b + W · (signed value of the stream)`. -/
theorem mac_correct (W b : ℤ) (x : ℕ → Bool) (n : ℕ) (hn : 1 ≤ n) :
    macFinal W b x n = b + W * sval x n := by
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  simp only [macFinal, sval, Nat.add_sub_cancel, mac_partial, psum_scale W x m]
  by_cases h : x m <;> simp [h, mul_sub, add_sub_assoc]

/-! ## 4. The int8 ingress — the stream's value IS `BitVec.toInt`

Both lemmas below are the *conversion* rows of `docs/the-order-invariant-v1.md`:
the file's whole thesis is that a certified pipeline's numeric meaning lives in
its conversions, so these are stated rather than assumed. -/

/-- The 8-bit stream read LSB-first has signed value `w.toInt`. Exhaustive over
all 256 values — the honest instrument for a claim about *every* int8. -/
theorem sval_eq_toInt (w : BitVec 8) : sval (fun j => w.getLsbD j) 8 = w.toInt := by
  revert w; decide

/-- **THE INGRESS ROW (order-invariant instance 3).** Sign-extension into the
32-bit datapath preserves the value. `zeroExtend` would typecheck, cost the same
gates, and map every **negative** weight to a large positive one. -/
theorem signExtend_toInt (w : BitVec 8) : (w.signExtend 32).toInt = w.toInt := by
  revert w; decide

/-! ## 5. The overflow bound (brief §B5/D1) -/

/-- The demo's fan-in bound: `|W·h|` terms at int8, a 2-dimensional dot product,
`W_self` plus degree ≤ 3 message terms, plus the bias. -/
def demoBound : ℤ := 131200

/-- **THE BOUND, and it is not close.** The 32-bit accumulator cannot wrap at
demo scale — margin ≈ 16,000×. This is what turns §B5 from a hypothesis nobody
could satisfy into an arithmetic fact. -/
theorem demoBound_lt_two_pow_31 : demoBound < 2 ^ 31 := by
  unfold demoBound; norm_num

/-- The bound is itself derived, not asserted: `4` terms of a `2`-dimensional
int8 dot product, plus an int8 bias. -/
theorem demoBound_eq : demoBound = 4 * (2 * (128 * 128)) + 128 := by
  unfold demoBound; norm_num

/-! ## 6. MUTATION CONTROLS — RUN, NOT CITED

Each mutant is shown **FALSE at an exhibited witness**, per the standing law that
a control is valid only if the mutated statement is false with a witness in hand.
The witness is the same stream for both: `x = 1` at bit 7 only — i.e. int8
`-128`, the value that exists precisely to catch a dropped sign. -/

/-- The witness stream: the sign bit alone. -/
def wsign : ℕ → Bool := fun j => decide (j = 7)

/-- Its signed value is `-128`, computed not asserted. -/
theorem wsign_sval : sval wsign 8 = -128 := by decide

/-- **MUTANT 1 — WRONG WEIGHT.** Replacing `W` by `W+1` makes the correctness
statement FALSE, witnessed at `W = 1, b = 0`: the true value is `-128`, the
mutant claims `-256`. -/
theorem mutant_wrong_weight_is_false :
    ¬ (macFinal 1 0 wsign 8 = 0 + (1 + 1) * sval wsign 8) := by decide

/-- **MUTANT 2 — DROPPED SIGN CYCLE.** Using `macAfter` (no sign subtraction) in
place of `macFinal` makes the statement FALSE at the same witness: the
accumulator holds `0`, the truth is `-128`. **This is the mutant that matters —
a dropped sign cycle is invisible on every non-negative input.** -/
theorem mutant_dropped_sign_cycle_is_false :
    ¬ (macAfter 1 0 wsign 8 = 0 + 1 * sval wsign 8) := by decide

/-- And the unmutated statement HOLDS at that same witness — so the controls
above discriminate, rather than both arms failing for an unrelated reason. -/
theorem witness_positive_control : macFinal 1 0 wsign 8 = 0 + 1 * sval wsign 8 := by decide


-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.Mac.demoBound_eq SaltWorks.HDL.Mac.demoBound_lt_two_pow_31
#audit_axioms SaltWorks.HDL.Mac.mac_correct SaltWorks.HDL.Mac.mac_partial
#audit_axioms SaltWorks.HDL.Mac.mac_sign_cycle SaltWorks.HDL.Mac.mutant_dropped_sign_cycle_is_false
#audit_axioms SaltWorks.HDL.Mac.mutant_wrong_weight_is_false SaltWorks.HDL.Mac.psum_scale
#audit_axioms SaltWorks.HDL.Mac.signExtend_toInt SaltWorks.HDL.Mac.sval_eq_toInt
#audit_axioms SaltWorks.HDL.Mac.witness_positive_control SaltWorks.HDL.Mac.wsign_sval
end SaltWorks.HDL.Mac
