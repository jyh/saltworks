/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.SpikeVectors
import SaltWorks.HDL.CompileS

/-!
# COMPREHENSIBILITY CERTIFICATE — the encoding, the witness, and one whole program

Campaign: `docs/cert-layer-design-0811.md` (the fifth deliverable).
Landed by the **COMPILER seat**. **Closes TWO target-list rows** (`decode_encode` and
`witness_chain_discharged`) and adds the external-witness rows that make the first of
them mean what a reader will think it means.

| certificate | proved from | in |
| --- | --- | --- |
| `cert_encode_decode_round_trip` | `decode_encode` | `HDL/ISA.lean` |
| `cert_no_two_instructions_share_an_encoding` | `encode_injective` | `HDL/ISA.lean` |
| `cert_the_bits_and_the_instruction_agree` | `stepT_encode` | `HDL/ISA.lean` |
| `cert_an_outside_simulator_agrees` | `spike_agrees` | `HDL/SpikeVectors.lean` |
| `cert_the_witness_suite_is_not_vacuous` | `suite_words_decode` / `spike_suite_size` | `HDL/SpikeVectors.lean` |
| `cert_illegal_words_are_rejected` | `spike_illegal_rejected` | `HDL/SpikeVectors.lean` |
| `cert_what_this_machine_does_not_implement` | `slice_a_excluded_rejected` | `HDL/SpikeVectors.lean` |
| `cert_one_whole_program_end_to_end` | `witness_chain_discharged` | `HDL/CompileS.lean` |

## ⛔⛔ THE SCOPE REFUSAL THIS FILE EXISTS FOR: **"RV32I" IS NOT WHAT IS PROVED**

`cert_encode_decode_round_trip` says the corpus's **own** encoder and decoder are
inverse on the corpus's **own** instruction type. **It does not say this encoding
agrees with the RISC-V specification**, and no theorem in this repository does.

```
⛔ FALSE reading   "the RISC-V instruction encoding is verified"
✅ HONEST reading  "every instruction THIS MACHINE DEFINES turns into a 32-bit word
                    and back again unchanged — and separately, a third-party RISC-V
                    simulator agrees with this machine on 120 witnessed steps"
```
**The second clause is where conformance evidence actually lives, and it is evidence
rather than proof.** *The corpus's own ruling on it: **Spike is a WITNESS, not an
oracle** — an untrusted offline generator that has never seen this repository;
disagreements are published, never resolved in the witness's favour by default.*

## ⭐ AND THE MACHINE PROVES WHAT IT DOES **NOT** IMPLEMENT

`cert_what_this_machine_does_not_implement` is the rarest kind of row in the corpus:
**twenty real RV32I encodings that Spike executes and this decoder REFUSES** — `lui`,
`auipc`, `jal`, `jalr`, `lb`, `sb`, the shifts, `sub`, the other branches. *A reader
sizing "a verified RISC-V processor" can read the gap instead of guessing at it.*

⏰ **That list carries an expiry enforced by the build rather than by memory, and it
FIRED**: when `M2` landed `LW`/`SW`, the two word-load/store rows stopped being
excluded, `decode` began accepting them, and the theorem broke the build **on the
day** — exactly as its author predicted in 2026-08-07. *Nobody had to remember.* `lb`
and `sb` stay excluded because v1 is word-only.

## ⚠️ SCOPE LIMITS

* **120 vectors is FINITE.** `cert_an_outside_simulator_agrees` is evidence of
  agreement on the steps that were run, not a proof of agreement on all steps.
* **The round-trip is over THIS corpus's `Instr`**, which since `M2` is slice A plus
  `LW`/`SW` — a small subset of RV32I, as the exclusion list makes explicit.
* **`cert_one_whole_program_end_to_end` is ONE program.** It is a non-vacuity
  witness — every hypothesis of the L1 theorem discharged on a real input, with a real
  number coming out — not a claim about programs in general.
* **The rejection rows are about `decode` alone**, not about what the silicon does with
  a word it cannot decode.

## DIRECTION (iron rule 3)

Every certificate here is the **same proposition** as its landed theorem (or the
conjunction of two), closing by `exact`. Nothing is generalised, nothing is weakened.

## AXIOMS (iron rule 4)

Measured at the landing of this file, from the `#print axioms` block below:

```
cert_encode_decode_round_trip                [propext, Quot.sound]
cert_no_two_instructions_share_an_encoding   [propext, Quot.sound]
cert_the_bits_and_the_instruction_agree      [propext, Quot.sound]
cert_an_outside_simulator_agrees             [propext, Quot.sound]
cert_the_witness_suite_is_not_vacuous        [propext, Quot.sound]
cert_illegal_words_are_rejected              [propext, Quot.sound]
cert_what_this_machine_does_not_implement    [propext, Quot.sound]
cert_one_whole_program_end_to_end            [propext, Classical.choice, Quot.sound]
```

No `sorryAx`, no corpus-local axiom; seven of the eight are stronger than the
campaign's bar. *Built against `ac3bf77` — the tree with `M2`'s `LW`/`SW` and `M4`'s
memory frame rows landed, which is the tree these statements are about.*
-/

namespace SaltWorks.Certs

open SaltWorks.ISA SaltWorks.RegMap SaltWorks.CompileS

/-! ## 1. THE ENCODING — internal consistency, stated as such -/

/-- ⭐⭐ **EVERY INSTRUCTION SURVIVES THE ROUND TRIP.** Turn any instruction this
machine defines into its 32-bit word, decode that word, and you get **exactly the
instruction you started with**.

⚠️ *This is the corpus's own encoder against the corpus's own decoder. It is internal
consistency — a necessary condition for calling the encoding real, and not conformance
to the RISC-V specification. For evidence about that, see §2.*

Direction: **same proposition** as `SaltWorks.ISA.decode_encode`. -/
theorem cert_encode_decode_round_trip (i : Instr) : decode (encode i) = some i :=
  decode_encode i

/-- **NO TWO INSTRUCTIONS SHARE AN ENCODING.** If two instructions produce the same
word, they were the same instruction.

Direction: **same proposition** as `SaltWorks.ISA.encode_injective`. -/
theorem cert_no_two_instructions_share_an_encoding {i j : Instr}
    (h : encode i = encode j) : i = j :=
  encode_injective h

/-- ⭐⭐ **THE BITS AND THE INSTRUCTION DO THE SAME THING.** Running the machine on the
32-bit *word* leaves exactly the state that running it on the *instruction* leaves.

*This is the bridge that makes the abstract instruction type an account of a bit-level
machine rather than a parallel story about it.*

Direction: **same proposition** as `SaltWorks.ISA.stepT_encode`. -/
theorem cert_the_bits_and_the_instruction_agree (s : St) (i : Instr) :
    stepT s (encode i) = step s i :=
  stepT_encode s i

/-! ## 2. THE EXTERNAL WITNESS — where conformance evidence actually lives -/

/-- ⭐⭐⭐ **A THIRD-PARTY SIMULATOR AGREES, ON EVERY ONE OF 120 WITNESSED STEPS.**
Each vector is a `(state, instruction, state')` triple produced by a RISC-V simulator
that has never seen this repository; the kernel checks this machine's `step` against
all 120, comparing the **full** state — every register, not just the one the
instruction was expected to touch, so a clobber cannot hide.

⚠️ **EVIDENCE, NOT PROOF, AND THE CORPUS SAYS SO: Spike is a WITNESS, not an oracle.**
*Untrusted offline generator; disagreements get published, never resolved in the
witness's favour by default. 120 is finite.*

Direction: **same proposition** as `SaltWorks.ISA.spike_agrees`. -/
theorem cert_an_outside_simulator_agrees : spikeSuite.all Vec.checkFull = true :=
  spike_agrees

/-- **AND THE SUITE IS NOT VACUOUS.** All 120 witnessed words actually decode — so the
agreement above is not the agreement of a decoder that returns `none` for everything —
and the suite really is 120 vectors.

Direction: **the conjunction of** `suite_words_decode` **and** `spike_suite_size`. -/
theorem cert_the_witness_suite_is_not_vacuous :
    spikeSuite.all (fun v => (decode v.word).isSome) = true
  ∧ spikeSuite.length = 120 :=
  ⟨suite_words_decode, spike_suite_size⟩

/-- **WORDS THAT ARE NOT INSTRUCTIONS ARE REFUSED.** Forty words that both witnesses
reject, and this decoder rejects them too.

Direction: **same proposition** as `SaltWorks.ISA.spike_illegal_rejected`. -/
theorem cert_illegal_words_are_rejected :
    spikeIllegal.all (fun w => (decode w).isNone) = true :=
  spike_illegal_rejected

/-- ⭐⭐⭐ **WHAT THIS MACHINE DOES NOT IMPLEMENT, AS A THEOREM.** Twenty **real,
legal RV32I encodings** — `lui`, `auipc`, `jal`, `jalr`, `lb`, `sb`, the shifts, `sub`,
`sltu`, the immediate-logic ops, `bne`/`blt`/`bge` — **which Spike executes and this
decoder REFUSES.**

*The disagreement is the specification working.* **A reader sizing the phrase "a
verified RISC-V processor" can read this gap instead of estimating it**, and that is
worth more to them than any of the positive rows.

⏰ *The list carries an expiry enforced by the BUILD rather than by memory, and it
fired: when `M2` landed `LW`/`SW` the two word-sized rows stopped being excluded, this
theorem went false, and the build broke on the day — exactly as predicted on
2026-08-07. **A caveat that refuses to outlive its own subject, without anyone
remembering to check.***

Direction: **same proposition** as `SaltWorks.ISA.slice_a_excluded_rejected`. -/
theorem cert_what_this_machine_does_not_implement :
    sliceAExcluded.all (fun w => (decode w).isNone) = true :=
  slice_a_excluded_rejected

/-! ## 3. ONE WHOLE PROGRAM, END TO END -/

/-- ⭐⭐⭐ **A REAL PROGRAM, COMPILED AND RUN, PRODUCING A REAL NUMBER.** The source
statement `x := x + 5`, in a context where `x` holds `7`, compiles to **four**
instructions, and running them leaves **12** in the register the compiler assigned to
`x`.

*Every hypothesis of the L1 simulation theorem is discharged here on a concrete input:
the register map's well-formedness, the source semantics' derivation, the type check,
the encoding of the starting state, `pc = 0`, and the code-length bound.* **Without a
row like this, every theorem in the compiler pillar is satisfiable by a `compileS` that
nobody can run.**

⚠️ *It is ONE program. Non-vacuity, not generality.*

Direction: **same proposition** as `SaltWorks.CompileS.witness_chain_discharged`. -/
theorem cert_one_whole_program_end_to_end :
    ∃ c, compileS regCanonical 16 ctx1 witnessAssign = some c ∧ c.length = 4
      ∧ (run c st7).get 1 = 12 :=
  witness_chain_discharged

#audit_axioms cert_encode_decode_round_trip
#audit_axioms cert_no_two_instructions_share_an_encoding
#audit_axioms cert_the_bits_and_the_instruction_agree
#audit_axioms cert_an_outside_simulator_agrees
#audit_axioms cert_the_witness_suite_is_not_vacuous
#audit_axioms cert_illegal_words_are_rejected
#audit_axioms cert_what_this_machine_does_not_implement
#audit_axioms cert_one_whole_program_end_to_end

#print axioms cert_encode_decode_round_trip
#print axioms cert_the_bits_and_the_instruction_agree
#print axioms cert_an_outside_simulator_agrees
#print axioms cert_what_this_machine_does_not_implement
#print axioms cert_no_two_instructions_share_an_encoding
#print axioms cert_the_witness_suite_is_not_vacuous
#print axioms cert_illegal_words_are_rejected
#print axioms cert_one_whole_program_end_to_end

end SaltWorks.Certs
