/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat (brief and landing); compiler seat executor (proof)

# Bridge 4 — the immediate `core` feeds the pc adder IS `bOffset` of `decode`'s immediate

The last of the four semantic bridges `Wire5` left open. **Produced by an executor against a
written brief; verified here by building it, not by reading its report.** Four attempts,
unrounded; no `native_decide`; three-axiom closure on all eight declarations.

```
immOf_is_bOffset : decode (seenWord ins) = some (.BEQ a b imm) → immOf ins = bOffset imm
```

⭐ **THE SATURATION REGION IS CHECKED, NOT ASSUMED — which is what the brief asked for.**
`interval_cases k` splits all 32 bits into independent goals, and the 19 goals `k = 13…31`
each close on their own: `getLsbD_signExtend`'s msb branch lands on `imm` bit 11, `decode`'s
reassembly sends `imm` bit 11 to `w[31]`, and `immB k = immBField 11 = 31` for every
`k ≥ 13`. The verified map:

```
k = 0        ↦ false (the structural zero)      k = 5…10  ↦ w[25 + (k-5)]
k = 1…4      ↦ w[8 + (k-1)]                     k = 11    ↦ w[7]
                                                k = 12…31 ↦ w[31]
```

🔧 **THE TACTIC LESSON, KEPT BECAUSE IT COST TWO OF THE FOUR ATTEMPTS:**
`simp only [getLsbD_*] <;> simp`. Phase 1 unfolds the whole `shiftLeft`/`signExtend`/
`append`/`extractLsb'` tower in `getLsbD` form **precisely because `simp only` skips the
numeral simprocs**; phase 2 does the arithmetic. *A single plain `simp` cannot do this* — it
rewrites `getLsbD → getElem` the moment the index is a numeral, after which
`getLsbD_signExtend`/`getLsbD_append` never fire and the append is stuck
(`getElem_append` will not discharge its own `i < n + m`).

✅ **TWO CONTROLS, BOTH LOAD-BEARING.** `the_hypothesis_is_reachable` exhibits an `Env` that
really does decode to a `BEQ`, so the bridge is not vacuously true for want of one. And the
mutation control is *the off-by-one this campaign already shipped once*: `immBmut` forgets
the doubling, and the two cases print **different values** (`true` vs `false`) rather than
failing in different ways — exhibited at `k = 4`, where the real wiring reads net 11 and the
mutant reads net 25.

📌 **ADJACENT BUT NOT SUBSUMING.** `Immediate.lean:110 immB_correct` already checks
`sem immBCirc` against `bOffset` exhaustively over 4096 field values — but through `encode`'s
round-trip, i.e. the circuit-semantics side on **encoder-produced** words. This is the
**decode** direction on an **arbitrary** `w`, through `immOf`/`coreThruRw`. *Neither implies
the other; they corroborate from opposite ends.*

*Not C4, not a witness, does not close R9/B2.*
-/
import SaltWorks.HDL.Bridge3

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

/-! ### Step 1 — the pure bit fact: `bOffset` of decode's reassembly IS the `immB` wiring.

⚠️ Covers ALL 32 `k`, so the sign-replication region `k ≥ 13` (where `immB` saturates at
`immBField 11 = 31`) is checked, not assumed: `interval_cases` produces those 19 goals
separately and each is closed on its own. -/

theorem beq_imm_bit (w : BitVec 32) (k : Nat) (hk : k < 32) :
    (bOffset (w.extractLsb' 31 1 ++ (w.extractLsb' 7 1 ++
      (w.extractLsb' 25 6 ++ w.extractLsb' 8 4)))).getLsbD k
      = (if k = 0 then false else w.getLsbD (immB k)) := by
  -- ⚠️ TWO PHASES ON PURPOSE. Plain `simp` rewrites `getLsbD` to `getElem` the moment the
  -- index is a numeral, after which none of the `getLsbD_*` structural lemmas can fire and
  -- the append is stuck (`getElem_append` will not discharge its own `i < n + m`). Phase 1
  -- is `simp only`, which does NOT run the numeral simprocs, so the whole shift/signExtend/
  -- append/extract tower unfolds in `getLsbD` form; phase 2 then does the arithmetic.
  interval_cases k <;>
    simp only [bOffset, immB, immBField, immBZero,
               BitVec.getLsbD_shiftLeft, BitVec.getLsbD_signExtend,
               BitVec.msb_eq_getLsbD_last, BitVec.getLsbD_append,
               BitVec.getLsbD_extractLsb'] <;>
    simp

/-! ### Step 2 — invert `decode` on the BEQ arm. -/

theorem decode_beq_imm (w : BitVec 32) (a b : Fin 32) (imm : BitVec 12)
    (h : decode w = some (.BEQ a b imm)) :
    imm = (w.extractLsb' 31 1 ++ (w.extractLsb' 7 1 ++
      (w.extractLsb' 25 6 ++ w.extractLsb' 8 4))) := by
  simp only [decode, Bool.and_eq_true, decide_eq_true_eq] at h
  split_ifs at h <;> simp_all

/-! ### Step 3 — BRIDGE 4. -/

theorem immOf_is_bOffset_bit (ins : Env) (a b : Fin 32) (imm : BitVec 12)
    (k : Nat) (hk : k < 32)
    (h : decode (seenWord ins) = some (.BEQ a b imm)) :
    (immOf ins).getLsbD k = (bOffset imm).getLsbD k := by
  rw [immOf_bits ins k hk, decode_beq_imm _ a b imm h,
      beq_imm_bit (seenWord ins) k hk]
  by_cases h0 : k = 0
  · simp [h0]
  · rw [if_neg h0, if_neg h0, seenWord_bit ins _ (immB_lt_32_of_ne_zero h0)]

/-- ⭐⭐⭐ **BRIDGE 4.** The immediate `core` feeds the pc adder IS `bOffset` of the
immediate `decode` reads out of the very word the core saw. -/
theorem immOf_is_bOffset (ins : Env) (a b : Fin 32) (imm : BitVec 12)
    (h : decode (seenWord ins) = some (.BEQ a b imm)) :
    immOf ins = bOffset imm :=
  BitVec.eq_of_getLsbD_eq_iff.mpr (fun i hi => immOf_is_bOffset_bit ins a b imm i hi h)

#audit_axioms beq_imm_bit decode_beq_imm immOf_is_bOffset_bit immOf_is_bOffset

/-! ### Non-vacuity: the theorem's hypothesis is SATISFIABLE.
Without this the bridge could be true because no `ins` ever decodes to a `BEQ`. -/

theorem the_hypothesis_is_reachable :
    ∃ (ins : Env) (a b : Fin 32) (imm : BitVec 12),
      decode (seenWord ins) = some (.BEQ a b imm) := by
  refine ⟨fun n => (encode (.BEQ 1 2 (8 : BitVec 12))).getLsbD (n - instrBase),
          1, 2, (8 : BitVec 12), ?_⟩
  have hw : seenWord (fun n => (encode (.BEQ 1 2 (8 : BitVec 12))).getLsbD (n - instrBase))
      = encode (.BEQ 1 2 (8 : BitVec 12)) := by
    apply BitVec.eq_of_getLsbD_eq_iff.mpr
    intro i hi
    rw [seenWord, wordOf_getLsbD _ _ hi]
    simp [instrNet]
  rw [hw, decode_encode]

/-! ### MUTATION CONTROL — the off-by-one that this campaign already shipped once.

`immBmut` is `immB` with the doubling forgotten (bit `k` reads field bit `k`, not `k-1`).
It must NOT satisfy `beq_imm_bit`. Stated as an EXHIBITED disagreement on a concrete word,
so the good and bad cases print different values rather than merely failing differently. -/

def immBmut (k : Nat) : Net := if k < 12 then immBField k else immBField 11

/-- The witness word: `BEQ x1, x2, +16` (field value 8, byte displacement 16). -/
def mutWord : BitVec 32 := encode (.BEQ 1 2 (8 : BitVec 12))

/-- **GOOD CASE** — the real wiring satisfies `beq_imm_bit`'s equation on this word at
every `k < 32`. Output: `true`. -/
theorem real_beq_imm_bit_holds :
    ((List.range 32).all fun k =>
      (bOffset (mutWord.extractLsb' 31 1 ++ (mutWord.extractLsb' 7 1 ++
        (mutWord.extractLsb' 25 6 ++ mutWord.extractLsb' 8 4)))).getLsbD k
        == (if k = 0 then false else mutWord.getLsbD (immB k))) = true := by
  decide +kernel

/-- **BAD CASE** — the same equation with the doubling forgotten. Output: `false`.
*Different output, not merely a different failure mode.* -/
theorem mutant_beq_imm_bit_fails :
    ((List.range 32).all fun k =>
      (bOffset (mutWord.extractLsb' 31 1 ++ (mutWord.extractLsb' 7 1 ++
        (mutWord.extractLsb' 25 6 ++ mutWord.extractLsb' 8 4)))).getLsbD k
        == (if k = 0 then false else mutWord.getLsbD (immBmut k))) = false := by
  decide +kernel

/-- The exhibited disagreeing bit: `k = 4`. Real wiring reads net 11 (`true`); the mutant
reads net 25 (`false`); `bOffset`'s own bit 4 is `true`. -/
theorem mutation_control_bit4 :
    mutWord.getLsbD (immB 4) = true ∧ mutWord.getLsbD (immBmut 4) = false
      ∧ (bOffset (8 : BitVec 12)).getLsbD 4 = true :=
  ⟨by decide +kernel, by decide +kernel, by decide +kernel⟩

#audit_axioms the_hypothesis_is_reachable
#audit_axioms real_beq_imm_bit_holds mutant_beq_imm_bit_fails mutation_control_bit4


end SaltWorks.HDL.RegNextUniform
