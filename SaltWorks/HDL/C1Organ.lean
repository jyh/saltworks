/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.SelectCut32
import SaltWorks.HDL.EncoderE1

/-!
# C1ORGAN — the encoder composition organ at the ruled pair `(rsOps, rsSelBits)`

Phase 2 of the `(3, 2)` expand-contract. Phase 1 landed two blocks beside the
old ones — `SelectCut32.sliceASelect` (the select) and `EncoderE1.ruledEnc` (the
encoder) — plus the ruled constants `rsOps` / `rsSelBits` (`AluSelect.lean:77-93`).
This file is the **organ that joins them to the DECODER**: it says which ALU
source the select block reads, as a function of the instruction word alone.

⭐ **EVERY STATEMENT HERE IS AGAINST A NAMED CONSTANT, NOT A NUMERAL.** The pair
enters as `rsOps` / `rsSelBits`, the select block as `sliceASelect`, the encoder
as `ruledEnc`, and the encoder's input nets as `lineXOR` / `lineSLT`. That is
deliberate: the numeral-bound bridge `genSelect_ten : genSelect 10 4 = aluSelect`
was exactly what made the as-built block expensive to migrate. Nothing below would
need restating if the pair or the blocks were renamed.

📌 **AND THE POLICY WAS VINDICATED AT PHASE 3, `52c51e5`:** *`genSelect_ten` turned
out to be the top of an **eleven**-theorem numeral-bound ladder, every rung an
equation between the generator at the literal `(10,4)` and the `as*` block — so the
re-cut FALSIFIES all eleven rather than merely unproving them, and they retired
wholesale against math's parametric hinge.*

⚠️ **AND THIS FILE'S OWN VERDICT AT THE RULED PAIR IS A PREDICTION, NOT A
MEASUREMENT — SAID PLAINLY BECAUSE THE TEMPTING SENTENCE IS FALSE.** *I first wrote
"this file needed no edit at the re-cut" here and struck it two minutes later. This
module imports `SelectCut32`, which imports `Stack.Program`, which does NOT yet
compile at the ruled pair — so in the flip census this file was **UNREACHED**, never
elaborated, and an absence of errors from a module that never ran is byte-identical
to a pass.* ⇒ ***The prediction is flip-inert, and the grounds are the policy in the
paragraph above (no numerals to falsify). The CONFIRMATION is owed by the joint
landing, and `docs/compiler-census.py` is what will report it.***

## The three pieces

| # | name | says |
| - | ---- | ---- |
| ⓪ | `alu_classes_atMostOne` | the three ALU class signals are pairwise exclusive, for EVERY word |
| ① | `opIndex` | the TOTAL spec function: word ↦ the source index the select should read |
| ② | `ruledEnc_drives_opIndex`, `gsSelOf_of_decoder_driven`, `sliceASelect_of_decoder_driven` | driven by the decoder, the encoder/select pair reads exactly `opIndex w` |

## ⛔ Why ⓪ is a THEOREM and not a hypothesis

It was drafted as a hypothesis to be carried into the consuming spec. That is
hypothesis-staging into a `∀`-unconditional obligation, and it is barred: a spec
that assumes one-hotness is satisfied by a decoder that never asserts anything.
So it is **proved here and consumed internally**. The mathematical content is
one line: `ADD` / `XOR` / `SLT` share `opcode = 0110011` and `funct7 = 0`, and
differ only in `funct3` (word bits 12-14) — `000` / `100` / `010`. A single
word's bits 12-14 cannot equal two distinct 3-bit literals.

## The wiring, and the three independent routes that agree on it

`gsSel n _b j = n * 32 + j` (`AluSelect.lean:247`) and `gsSelUpTo`
(`Program.lean:5368`) is LSB-first with bit `j` at weight `2 ^ j`, so at
`b = 2` the select value is `bit0 + 2 * bit1` — `sliceASelOf`
(`SelectCut32.lean:140`) states exactly that. Codes `{ADD, XOR, SLT} = {0, 1, 2}`
(`EncoderE1.ruledCodes`) therefore force **bit 0 ← `xor`, bit 1 ← `slt`, and
`add` drives nothing**, which is what `EncoderE1.selDrivers = [lineXOR, lineSLT]`
says in code. `add` is the all-low default, so a word that is no ALU op at all
(a `BEQ`) reads source 0 — defined, not stray.

📌 **The wiring is load-bearing and it is CONTROLLED.** Swapping the two drivers
in `hdrive` does not merely make ② unprovable — `decide` reports the resulting
goal is FALSE, on both ② forms. Checked, not assumed.
-/

namespace SaltWorks.HDL
namespace C1Organ

open SaltWorks.Stack.Program
open SaltWorks.HDL.SelectCut32
open SaltWorks.HDL.EncoderE1

/-! ## ⓪ THE ONE-HOT LEMMA — unconditional, every word -/

/-- `funct3` is a FUNCTION of the word, so it cannot match two distinct
literals. This is the whole content of `alu_classes_atMostOne`; the opcode and
`funct7` conjuncts of the three class signals are never consulted. -/
theorem dcF3_atMostOne (w : BitVec 32) {a b : Nat}
    (hab : (BitVec.ofNat 3 a) ≠ (BitVec.ofNat 3 b))
    (h1 : dcF3Is w a = true) (h2 : dcF3Is w b = true) : False := by
  rw [dcF3Is, decide_eq_true_eq] at h1 h2
  exact hab (h1.symm.trans h2)

/-- ⭐⭐ **AT MOST ONE ALU CLASS SIGNAL IS ASSERTED, FOR EVERY 32-BIT WORD.** No
hypothesis, no fixture, no decoder-reachability side condition — the three
signals are the decoder's own `dcADDm` / `dcXORm` / `dcSLTm`
(`Program.lean:7962-7964`), which `decoder_correct` proves are what the circuit
emits. -/
theorem alu_classes_atMostOne (w : BitVec 32) :
    ¬(dcXORm w ∧ dcSLTm w) ∧ ¬(dcADDm w ∧ dcXORm w) ∧ ¬(dcADDm w ∧ dcSLTm w) := by
  refine ⟨?_, ?_, ?_⟩ <;> rintro ⟨h1, h2⟩ <;>
      simp only [dcADDm, dcXORm, dcSLTm, Bool.and_eq_true] at h1 h2
  · exact dcF3_atMostOne w (by decide) h1.2 h2.2
  · exact dcF3_atMostOne w (by decide) h1.2 h2.2
  · exact dcF3_atMostOne w (by decide) h1.2 h2.2

/-! ## ① THE SPEC FUNCTION — total, so ② needs no hypothesis to be STATED -/

/-- **The source index the select block should read, as a function of the word.**
Total by construction: `slt ↦ 2`, `xor ↦ 1`, everything else ↦ `0` (`add`, the
all-low default). Totality is the point — a partial spec would have to be
guarded by one-hotness at every use site, and the guard would then be an
assumption rather than ⓪'s conclusion. -/
def opIndex (w : BitVec 32) : Nat := if dcSLTm w then 2 else if dcXORm w then 1 else 0

/-- `opIndex` never names the padding leaf. This is what discharges
`sliceASelect_selects`' guard at every word. -/
theorem opIndex_lt_rsOps (w : BitVec 32) : opIndex w < rsOps := by
  show opIndex w < 3
  unfold opIndex; split_ifs <;> omega

/-! ## ② THE COMPOSITION ORGAN

Three sentences, each unconditional apart from the wiring hypothesis it names:
the ENCODER produces `opIndex`, the WIRE carries it to the select's select nets,
and the SELECT BLOCK then delivers the source `opIndex` names. -/

/-- ⭐⭐ **ENCODER SIDE, IN NAMED NETS ONLY.** Drive `ruledEnc`'s two one-hot
lines from the decoder's `xor` and `slt` signals and its two output ports, read
LSB-first by `selVal`, are exactly `opIndex w`. No numeral appears in the
statement. The `xor ∧ slt` case — the one that would emit the spare code `3`
(`ruled_spare_needs_two_hot`) — is killed by ⓪, not assumed away. -/
theorem ruledEnc_drives_opIndex (w : BitVec 32) (env : Env)
    (hdrive : env lineXOR = dcXORm w ∧ env lineSLT = dcSLTm w) :
    selVal (sem ruledEnc env) = opIndex w := by
  obtain ⟨h0, h1⟩ := hdrive
  rw [ruledEnc_cert, h0, h1]
  simp only [opIndex]
  cases hx : dcXORm w <;> cases hs : dcSLTm w
  · decide
  · decide
  · decide
  · exact absurd ⟨hx, hs⟩ (alu_classes_atMostOne w).1

/-- ⭐ **THE WIRE.** Encoder output port `k` drives select net `k`; then the
number the select block reads IS the number the encoder emitted. This is the
only place the two blocks' net spaces meet, and it is stated rather than left to
an assembly to imply. -/
theorem gsSelOf_eq_selVal_of_wired (E env : Env)
    (hwire : E (gsSel rsOps rsSelBits 0) = env lineXOR
           ∧ E (gsSel rsOps rsSelBits 1) = env lineSLT) :
    gsSelOf rsOps rsSelBits E = selVal (sem ruledEnc env) := by
  obtain ⟨h0, h1⟩ := hwire
  simp only [rsOps, rsSelBits, asOps, asSelBits] at h0 h1 ⊢
  rw [sliceASelOf, ruledEnc_cert, h0, h1]
  cases hx : env lineXOR <;> cases hs : env lineSLT <;> decide

/-- ⭐⭐ **SELECT SIDE — THE INDEX EQUATION.** With the select nets driven by the
decoder's `xor` and `slt` signals, the select value is `opIndex w` for EVERY
word: no one-hotness hypothesis, because ⓪ supplies it. -/
theorem gsSelOf_of_decoder_driven (w : BitVec 32) (E : Env)
    (hdrive : E (gsSel rsOps rsSelBits 0) = dcXORm w
            ∧ E (gsSel rsOps rsSelBits 1) = dcSLTm w) :
    gsSelOf rsOps rsSelBits E = opIndex w := by
  obtain ⟨h0, h1⟩ := hdrive
  simp only [rsOps, rsSelBits, asOps, asSelBits] at h0 h1 ⊢
  rw [sliceASelOf, h0, h1]
  simp only [opIndex]
  cases hx : dcXORm w <;> cases hs : dcSLTm w
  · decide
  · decide
  · decide
  · exact absurd ⟨hx, hs⟩ (alu_classes_atMostOne w).1

/-- ⭐⭐ **BLOCK LEVEL — `sliceASelect` DELIVERS THE SOURCE THE DECODER NAMED.**
The payoff: all 32 ports, arbitrary `Env`, no fixture, and **the guard is gone**
— `sliceASelect_selects` is stated under `gsSelOf … < 3`, and `opIndex_lt_rsOps`
discharges it at every word. The `false`-arm hazard of
`sliceASelect_at_select_three` is therefore unreachable from a decoder-driven
select, which is the sentence a `core` assembly needs. -/
theorem sliceASelect_of_decoder_driven (w : BitVec 32) (E : Env)
    (hdrive : E (gsSel rsOps rsSelBits 0) = dcXORm w
            ∧ E (gsSel rsOps rsSelBits 1) = dcSLTm w) :
    sem sliceASelect E = (List.range 32).map (fun k => E (gsRes (opIndex w) k)) := by
  have hsel : gsSelOf 3 2 E = opIndex w := gsSelOf_of_decoder_driven w E hdrive
  have hg : gsSelOf 3 2 E < 3 := hsel ▸ opIndex_lt_rsOps w
  rw [sliceASelect_selects E hg, hsel]

/-! ## ⭐ THE CHAIN CLOSED AT THE GATES — added 2026-08-08 19:5x

⛔ **THIS SECTION EXISTS BECAUSE ITS ABSENCE COST A PEER REAL WORK.** Everything
above is stated over the **matcher predicates** `dcXORm w` / `dcSLTm w`, which are
pure functions of the word (bit-field tests, `Program.lean:7813`) — *not* the
decoder's gate outputs. So a reader auditing the seam found "the select is proved
correct when driven by `dcXORm`" and could not tell whether the **circuit** drives
that value. I was that reader, twice: first I published the seam as UNPROVED
(wrong — §above proves it), then, correcting myself, I wrote that the
matcher-to-gates link was *"cited, not audited."* **It was neither: it was proved,
in a third file, and no statement anywhere composed the two.**

⇒ ***The bridge is `Program.lean`'s `ctrlSpec_eq` — `ctrlSpec w` IS the matcher
list — which with the unconditional `decoder_correct` makes the GATE-LEVEL decoder
outputs literally the matchers.*** Nobody had written that down, so establishing
it required holding two files in your head, which is exactly how I got it wrong.
**One name, stated once, so no one has to do that again.** -/

/-- **The gate-level decoder's output list IS the matcher list**, `∀ w`, no
hypothesis. `ctrlOf` is `sem decoder` on the word's bits (`Decoder.lean:190`) — a
real circuit evaluation, not a definition in terms of the matchers, which is what
makes this an equation rather than a restatement. -/
theorem ctrlOf_eq_matchers (w : BitVec 32) :
    ctrlOf w = [dcADDm w, dcXORm w, dcSLTm w, dcADDIm w, dcBEQm w,
                dcLWm w, dcSWm w, dcReqm w, dcValidm w] := by
  rw [decoder_correct, ctrlSpec_eq]

/-! ### ⬥⬥ D2 — THE MAGIC NUMBERS, NAMED

⚠️ **The two theorems below exist because the docstring immediately following
promises a NAME-to-INDEX binding — *"output nets 1 and 2 … `isXOR` and `isSLT`"* —
and until now that binding lived ONLY IN PROSE.**

*Under a reorder of `dcMatches` the seam theorems stay TRUE and GREEN (their
proofs re-derive whatever is at positions 1 and 2), while that sentence goes
false — **and the assembler wires by the sentence.*** ⇒ *The kernel does catch a
reorder today, but only inside another theorem's anonymous `rfl`, which reports
"some proof broke" rather than "the isXOR wire moved".*

✅ **Named, a reorder breaks a theorem whose NAME says what it meant.** *D2 is the
first edit that could have moved them — it did not (`decoder_out_prefix`), and
that is exactly when the guard is cheap to install.* -/

/-- **Output index 1 is `isXOR`** — the binding `sliceASelect_of_gate_decoder`
reads by number, stated by name. -/
theorem ctrlOf_index1_is_isXOR (w : BitVec 32) : (ctrlOf w)[1]! = dcXORm w := by
  rw [ctrlOf_eq_matchers]; rfl

/-- **Output index 2 is `isSLT`.** -/
theorem ctrlOf_index2_is_isSLT (w : BitVec 32) : (ctrlOf w)[2]! = dcSLTm w := by
  rw [ctrlOf_eq_matchers]; rfl

/-- ⭐⭐ **THE SEAM, WITH THE CIRCUIT IN THE HYPOTHESIS.** Wire the two select nets
to output nets **1** and **2** of the *actual decoder* — `isXOR` and `isSLT`, in
`decoder.outs` order — and `sliceASelect` delivers the source the ISA names, at all
32 ports, for arbitrary `Env`, at **every** word.

⇒ ***This is the sentence a `core` assembly can be built against:*** it mentions no
spec predicate. `sliceASelect_of_decoder_driven` above needed the assembler to
*believe* the decoder emits `dcXORm`; this needs them only to wire net 1 to net 1. -/
theorem sliceASelect_of_gate_decoder (w : BitVec 32) (E : Env)
    (h0 : E (gsSel rsOps rsSelBits 0) = (ctrlOf w)[1]!)
    (h1 : E (gsSel rsOps rsSelBits 1) = (ctrlOf w)[2]!) :
    sem sliceASelect E = (List.range 32).map (fun k => E (gsRes (opIndex w) k)) :=
  sliceASelect_of_decoder_driven w E
    ⟨by rw [h0, ctrlOf_eq_matchers]; rfl, by rw [h1, ctrlOf_eq_matchers]; rfl⟩

/-- And the select index itself, from the gates — the `< 3` fact an assembly needs
in order to know the fourth arm is dead, now with no matcher in sight. -/
theorem gsSelOf_of_gate_decoder (w : BitVec 32) (E : Env)
    (h0 : E (gsSel rsOps rsSelBits 0) = (ctrlOf w)[1]!)
    (h1 : E (gsSel rsOps rsSelBits 1) = (ctrlOf w)[2]!) :
    gsSelOf rsOps rsSelBits E = opIndex w ∧ gsSelOf rsOps rsSelBits E < 3 :=
  let h := gsSelOf_of_decoder_driven w E
    ⟨by rw [h0, ctrlOf_eq_matchers]; rfl, by rw [h1, ctrlOf_eq_matchers]; rfl⟩
  ⟨h, h ▸ opIndex_lt_rsOps w⟩

/-! ## THE AUDIT

One name per line: `#audit_axioms` abandons the rest of its own argument list at
the first failure, so a batched list can hide everything after the first entry. -/

#audit_axioms dcF3_atMostOne
#audit_axioms alu_classes_atMostOne
#audit_axioms opIndex
#audit_axioms opIndex_lt_rsOps
#audit_axioms ruledEnc_drives_opIndex
#audit_axioms gsSelOf_eq_selVal_of_wired
#audit_axioms gsSelOf_of_decoder_driven
#audit_axioms sliceASelect_of_decoder_driven
#audit_axioms ctrlOf_eq_matchers
#audit_axioms sliceASelect_of_gate_decoder
#audit_axioms gsSelOf_of_gate_decoder

end C1Organ

-- completeness sweep 2026-08-28 (compiler): these carried no build-failing axiom gate.
#audit_axioms SaltWorks.HDL.C1Organ.ctrlOf_index1_is_isXOR SaltWorks.HDL.C1Organ.ctrlOf_index2_is_isSLT
end SaltWorks.HDL
