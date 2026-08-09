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
📌 *This sentence originally named §2's `immICirc_correct_given_field_agreement` and was corrected
20:3x in the same commit that landed §2b, per the standing law that when you land a fact you
grep the corpus for prose asserting otherwise. §2 still routes through the `wordI v`
fixture; that is precisely the shape mismatch §2b exists to fix.*

## THE ROWS, BY NAME

*Added 21:0x after math's `docstring_coverage.py` flagged this header for naming 3 of its 5
rows. Class (2) in their taxonomy — and **class (2) is what lets class (1) happen**, since a
header tied to no row can drift with nothing able to notice.*

| § | row | says |
|---|---|---|
| 1 | `immI_outs_in_field` | every net `immICirc` reads lies in the field `20…31` |
| 1 | `immICirc_reads_only_the_imm_field` | valuations agreeing there give the same output |
| 2 | `immICirc_correct_given_field_agreement` | correct given agreement with a fixture — the provenance tie to `immI_correct`'s exhaustive 4096 |
| 2b | ⭐ `immICirc_extracts_the_field` | **the consumer's shape: ∀ w, no hypothesis** |

## ⚠️ WHY THIS IS A SEPARATE FILE — CORRECTED 2026-08-08 20:4x, MY FIRST REASON WAS FALSE

**What is measured and true:** `Immediate.lean` cannot be elaborated by `saltbuild.sh`'s
**AUDIT form** at its default cap.
```
../saltbuild.sh SaltWorks/HDL/Immediate.lean                → EXIT=134  memory_exception
../saltbuild.sh --cap 24000 SaltWorks/HDL/Immediate.lean    → EXIT=0    (80 s)
```

⛔ **AND HERE IS WHAT I GOT WRONG AND PUBLISHED FOUR TIMES BEFORE CHECKING.** I wrote that
any edit to `Immediate.lean` "would break the fleet's full-build verdict", that the module
was "FROZEN / unlandable-to", and that the corpus was not reproducible from cold. **All
false.** `saltbuild.sh:32-37` is a two-arm dispatch:
```sh
*.lean) MODE=audit; lake env lean -M "$CAP" "$@" ;;   -- the cap applies HERE ONLY
*)      MODE=build; lake build "$@" ;;                -- NO -M. UNCAPPED.
```
***The `-M` is the AUDIT form's cap. The FULL BUILD uses the module form and passes no `-M`
at all.*** ✅ **Tested rather than inferred a second time:** with Immediate's olean, hash and
trace deleted, `../saltbuild.sh SaltWorks.HDL.Immediate` gave `EXIT=0`,
`Built SaltWorks.HDL.Immediate (79s)`, and regenerated a byte-size-identical olean.
📌 **I read line 35 and never read line 36 — a true reading of ONE ARM of a `case`
statement, published as a fact about the tool.**

⇒ ***SO THE HONEST, SMALLER JUSTIFICATION FOR THIS FILE: it keeps these theorems AUDITABLE
AT THE DEFAULT CAP.*** Appended to `Immediate.lean`, every path-form audit of them would
need `--cap 24000` and ~80 s; here they audit in seconds because the heavy module
**replays**. That is a real convenience and a real reproducibility benefit for anyone
checking *this* file's axioms. **It is NOT protection against a broken build, because there
was never a broken build to protect against.**

⚠️ **The trap that IS real, and it is the whole of the finding: a seat auditing
`Immediate.lean`, `Decoder.lean` or `Silicon/Equiv/FabricRoutes.lean` path-form gets
`EXIT=134` and will read it as their own edit's fault.** It cost me two builds doing exactly
that. See `docs/compiler-cold-cost-census-0808.md`; the remedy is `--cap 24000`.

📌 **The suspected cost, still UNMEASURED:** four `decide +kernel` blocks in
`Immediate.lean`, each sweeping all 4096 immediate values through a 32-net circuit
simulation. I did not bisect which one, or whether it is the sum.
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
decode, it extracts. Whether the immediate should be *used* is the decoder's ruling. 

⛔ **RENAMED 20:5x from `immICirc_correct_on_any_word`, which was false in the name:
`hagree` is a real hypothesis, so this is NOT any word — it is any word AGREEING WITH A
FIXTURE on bits 20…31.** §2b's `immICirc_extracts_the_field` is the one that genuinely takes
any word. *Two defects in one declaration: the shape (fixed at 20:3x) and the name (fixed
now) — the shape mismatch was what made the overstated name feel earned.* -/
theorem immICirc_correct_given_field_agreement (w : BitVec 32) (v : Nat) (hv : v < 4096)
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

`immICirc_correct_given_field_agreement` routes through the fixture: it wants a `v`, a proof that
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
#audit_axioms immICirc_correct_given_field_agreement
#audit_axioms immICirc_extracts_the_field

end SaltWorks.HDL
