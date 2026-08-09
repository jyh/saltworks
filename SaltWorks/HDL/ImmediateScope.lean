/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Immediate

/-!
# THE SCOPE OF `immI_correct`, MADE A THEOREM

`Immediate.lean`'s `immI_correct` is **exhaustive over the immediate** — all 4096 field
values, kernel-checked — and it is stated at **one register pair**: `wordI v` fixes
`rd = 1`, `rs1 = 0`. Read literally it therefore certifies one fixture family. The step
everyone makes in their head — *"but the circuit cannot see `rd` or `rs1`"* — was **true
and nameless**, and the `ADDI` sign-extension path is the one the ISA's own docstring
calls *"the single most common formalisation bug"*. So it is named here.

⇒ ***`immICirc_extracts_the_field` (§2b) is what a `core` assembly actually needs, because
the assembled instruction word is not a fixture — it takes a WORD and no hypothesis.***
📌 *This sentence originally named §2's `immICirc_correct_on_any_word` and was corrected
20:3x in the same commit that landed §2b, per the standing law that when you land a fact you
grep the corpus for prose asserting otherwise. §2 still routes through the `wordI v`
fixture; that is precisely the shape mismatch §2b exists to fix.*

## ⛔ WHY THIS IS A SEPARATE FILE AND NOT THREE THEOREMS APPENDED TO `Immediate.lean`

**Measured 2026-08-08 20:0x, and it is a fact about the module, not a preference:**
```
SaltWorks/HDL/Immediate.lean, PRISTINE FROM GIT
  ../saltbuild.sh                → EXIT=134, lean::memory_exception at 'interpreter'
  ../saltbuild.sh --cap 24000    → EXIT=0   (80 s)
```
`saltbuild.sh`'s default cap is **12000 MB** and that module needs more. It is **not
broken** — it is correct and over the default. ⚠️ **So ANY edit to `Immediate.lean` forces
a re-elaboration that fails at the default cap, which would break the fleet's full-build
verdict.** The maestro ruled at 20:09 that the default does not move tonight and that
per-invocation `--cap` is the sanctioned mechanism — *but a per-invocation flag does not
help the full build, which runs at the default.*

⇒ ***So `Immediate.lean` is effectively FROZEN under the current default, and the remedy
is the one this file is: ADD BESIDE, DON'T ADD INSIDE.*** Importing it **replays** its
olean, so this module is cheap and the expensive module is never re-elaborated. *That is
expand-contract discipline applied to a MEMORY constraint rather than to an interface, and
it is the general move for any module sitting at the cap.*

📌 **The suspected cost, flagged as UNMEASURED:** four `decide +kernel` blocks in
`Immediate.lean`, each sweeping all 4096 immediate values through a 32-net circuit
simulation. **I did not bisect which one, or whether it is the sum** — the honest
long-term fix is probably to move those four certificates into their own module, which is
a restructuring of a rooted file and therefore a ruling, not a landing.
-/

namespace SaltWorks.HDL

/-! ## 1 · Which nets the circuit reads

📌 **Proved on CONCRETE DATA rather than symbolically, and that was not the first
attempt.** The natural form — `∀ k, 20 ≤ immI k ∧ immI k < 32` by `unfold immI; split <;>
omega` — **failed**, and kept failing after the conjunction was split by hand and the `if`
rewritten in both conjuncts. `trace_state` showed the goal was exactly `20 ≤ 20 + k ∧
20 + k < 32` under `h : k < 12`, and `omega` still could not close either half; its
counterexample constrained only `k` and never related it to the goal terms, which is the
documented tell for `omega` against `Net`-typed arithmetic in this corpus (`Net` is an
`abbrev` for `Nat`, `Syntax.lean:46`, and reducibility is not enough).
⇒ ***`immICirc.outs` is a concrete 32-element list, so the kernel can simply decide the
property. Three failed tactic attempts became one `by decide`.*** -/

/-- Every net `immICirc` reads lies in the I-type immediate field `20…31`. -/
theorem immI_outs_in_field :
    ((List.range 32).map immI).all (fun n => 20 ≤ n && n < 32) = true := by decide

/-- ⭐ **`immICirc` CANNOT SEE `rd`, `rs1`, `funct3` OR the opcode.** Two valuations that
agree on bits `20…31` produce the same output — so the fixed `rd`/`rs1` in `wordI` is not
a limitation of `immI_correct`, it is *irrelevant* to it.

**Zero gates is what makes this a statement about the OUT LIST alone**
(`immICirc_has_no_gates`): with `gates = []`, `run` is the identity and `sem` is just
`outs.map`. A gated circuit would need the same argument carried through every gate. -/
theorem immICirc_reads_only_the_imm_field (e₁ e₂ : Env)
    (h : ∀ n, 20 ≤ n → n < 32 → e₁ n = e₂ n) :
    sem immICirc e₁ = sem immICirc e₂ := by
  simp only [sem, immICirc, run_nil]
  apply List.map_congr_left
  intro n hn
  have hb := List.all_eq_true.mp immI_outs_in_field n hn
  simp only [Bool.and_eq_true, decide_eq_true_eq] at hb
  exact h n hb.1 hb.2

/-! ## 2 · The generalised certificate -/

/-- ⭐⭐ **`immICirc` SIGN-EXTENDS CORRECTLY ON ANY WORD CARRYING IMMEDIATE `v`** — whatever
its `rd`, `rs1`, `funct3` or opcode. `immI_correct` supplies the value (exhaustively, all
4096 field values); §1 supplies the independence.

⚠️ **`hagree` is a hypothesis about bits `20…31` only, and it is genuinely weaker than
`w = wordI v`** — that is the whole content. A word that is not even an `ADDI` still gets
the right sign-extended immediate out of this organ, which is correct: the organ does not
decode, it extracts. Whether the immediate should be *used* is the decoder's ruling. -/
theorem immICirc_correct_on_any_word (w : BitVec 32) (v : Nat) (hv : v < 4096)
    (hagree : ∀ n, 20 ≤ n → n < 32 → w.getLsbD n = (wordI v).getLsbD n) :
    sem immICirc (fun i => w.getLsbD i)
      = (List.range 32).map ((BitVec.ofNat 12 v).signExtend 32).getLsbD := by
  rw [immICirc_reads_only_the_imm_field (fun i => w.getLsbD i)
        (fun i => (wordI v).getLsbD i) hagree]
  have h := List.all_eq_true.mp immI_correct v (List.mem_range.mpr hv)
  exact eq_of_beq h

/-! ## 2b · ⭐⭐ THE CONSUMER'S SHAPE — added 20:3x, and it is a SELF-CATCH

⛔ **MATH'S 20:28 LAW, AIMED AT THIS FILE FIFTEEN MINUTES AFTER IT LANDED.** Their words:
*"A supply row stated in a shape its consumer does not use is a mismatch someone discovers
MID-WAVE"* — they found one in the row they were proudest of, and **the same disease was
in §2 above.**

`immICirc_correct_on_any_word` routes through the fixture: it wants a `v`, a proof that
`v < 4096`, and a proof that `w` agrees with **`wordI v`** on bits `20…31`. ⚠️ ***But a
`core` assembly does not have a `v` and an agreement proof. It has a WORD.*** So the
theorem was true and awkward — and nothing in the kernel was ever going to refuse it,
exactly as math observed. **The row was true, just unusable.**

⇒ ***Below is the shape a consumer actually uses: no fixture, no `v`, NO HYPOTHESIS AT
ALL.*** Given any word, the organ emits the sign extension of **that word's own** I-type
immediate field, `w.extractLsb' 20 12` — the same extraction idiom `ISA.lean`'s own field
lemmas use (`:386-411`). *§2 is kept, not deleted: it is the direct tie to `immI_correct`'s
exhaustive 4096-value kernel sweep, which is the provenance. But §2b is the one to cite.* -/

/-- ⭐⭐ **`immICirc` SIGN-EXTENDS THE WORD'S OWN IMMEDIATE FIELD — `∀ w`, no hypothesis.**
The consumer's shape. `w.extractLsb' 20 12` is the I-type immediate (`imm[11:0]` at word
bits `31:20`), and the organ's 32 outputs are exactly its sign extension.

The proof is the wiring read twice: for `k < 12` output `k` is word bit `20 + k`, which is
`getElem_extractLsb'`; for `k ≥ 12` it is word bit `31`, which is the extract's `msb`. **The
two branches of `immI` ARE the two branches of `signExtend`** — that correspondence is the
whole content, and it is why the organ needs zero gates. -/
theorem immICirc_extracts_the_field (w : BitVec 32) :
    sem immICirc (fun i => w.getLsbD i)
      = (List.range 32).map ((w.extractLsb' 20 12).signExtend 32).getLsbD := by
  simp only [sem, immICirc, run_nil, List.map_map]
  apply List.map_congr_left
  intro k hk
  have hk32 : k < 32 := List.mem_range.mp hk
  simp only [Function.comp_def, immI]
  rw [BitVec.getLsbD_eq_getElem hk32, BitVec.getElem_signExtend hk32]
  by_cases h : k < 12
  · rw [if_pos h, dif_pos h, BitVec.getElem_extractLsb' h]
  · rw [if_neg h, dif_neg h]
    simp [BitVec.getMsbD_eq_getLsbD]

/-! ## 3 · ⛔ WHAT THIS DOES NOT SAY

1. **It does not widen `immI_correct`'s coverage of the IMMEDIATE.** That was already
   exhaustive (4096 of 4096). This widens coverage of *the rest of the word*, which was
   previously one point.
2. **It says nothing about `immBCirc`.** The B-type path has a gate (`immBCirc_has_one_gate`)
   and its own scramble-and-double obligation; the argument in §1 does not transfer, since
   it depends on `gates = []`.
3. **It does not wire `immICirc` to anything.** `immICirc` remains built and consumed by no
   one — `docs/hdl-c4-core-assembly-plan-0807.md` §4's assembly order allocates `immBCirc`
   at row 2 and **no row for `immICirc`**, though Slice A contains `ADDI`. That gap, and
   the operand-B select it needs, are §3.5's block ② and are not closed here.
-/

#audit_axioms immI_outs_in_field
#audit_axioms immICirc_reads_only_the_imm_field
#audit_axioms immICirc_correct_on_any_word
#audit_axioms immICirc_extracts_the_field

end SaltWorks.HDL
