/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Certs.Switch1990
import SaltWorks.Certs.Compiler
import SaltWorks.Certs.Executive
import SaltWorks.Certs.ControlFlow
import SaltWorks.Certs.EndToEnd
import SaltWorks.Certs.MemTrapResponse

/-!
# `SaltWorks/Certs/` — the comprehensibility-certificate layer, roll-call

Campaign: `docs/cert-layer-design-0811.md`, opened at the Captain's word 2026-08-11
as the workflow's **fifth deliverable** (implementation · specification · proof ·
tests · **certificates**). The salt-side twin is `Salt/Certs/All.lean`.

⚠️ **EVERY FILE IN THIS DIRECTORY RECORDS THE SEAT THAT LANDED IT, in its own header.**
*The campaign has four hands landing into two repos under one campaign name, and the
standard file header (`Authors: Jason Hickey, Claude`) does not distinguish them — so
authorship was being inferred from memory of who announced what, and that key failed
six times on 2026-08-11 alone. A one-line seat stamp costs nothing and is the only
copy that survives the announcement.*

⚠️ **"THE PAPER" IS NOT A REFERENCE IN THIS HOUSE — every cert names its source.** *At least NINE paper-shaped
documents exist — three `.tex` under `salt/papers/` and six `nature-*` drafts in `${SEAT_DIR}/briefs/`,
two of them sharing a directory and a date-prefix — so name the PATH, not the paper. The
saltworks rows quote `${SEAT_DIR}/briefs/2026-08-11-nature-draft-v0.md`; its section numbers are
draft-relative and will move.*

A certificate file restates one paper-cited headline claim in simplified vocabulary
and carries a **kernel proof linking the restatement to the landed theorem** — the
proof is what separates a certificate from documentation. Each file declares its
DIRECTION (`iff`/equality where true, `←`-implication otherwise) and states in its
docstring exactly what, if anything, was traded for readability.

## LANDED

* `SaltWorks/Certs/Switch1990.lean` — **THE 1990 CERT**, **nine declarations** over the
  Batcher–banyan switch the Nature-track draft's §1 story rests on. Direction: **equality or the
  same proposition** throughout — with the one exception named in the file and closed
  by proof rather than by wording (`cert_payload_delivery`, below).
  - `cert_full_circle` / `cert_address_restored_after_three_stages` — `rot^k = id`
    in plain vocabulary (`moveHeadToTail`, `afterStages`, both proved equal to the
    corpus's `rotStage`/`Function.iterate`), certifying
    `SaltWorks.HDL.rotate_full_circle`.
  - `cert_length_premise_is_load_bearing` — the one line showing the corpus's own
    `addr.length = k` identification is not decoration.
  - `cert_head_after_stages` — ⭐ the self-routing consequence **at any width**: after
    `m` stages the head is the original entry at index `m`. *Added at the refuter's
    17:50 finding — the file's prose stated the reading rule generally (`k−1−m`) while
    its only backing theorem was pinned at `k = 3`.*
  - `cert_stage_reads_original_bit` — the same fact in the fabric's 3-bit MSB-first
    numbering, certifying `SaltWorks.HDL.stage_reads_original_bit`. **Its `k = 3` scope
    is now stated in its own docstring**, and the width-general content sits in the row
    above rather than in a sentence.
  - `cert_payload_delivery` — the Batcher half at the tapeout instance `P = 8`,
    certifying `L1Payload.l1_full_load_payload_delivery`, read one payload cycle at
    a time. ⭐ **Its no-trade claim is KERNEL-PROVED, not asserted**: the per-cycle
    form is on its own strictly weaker (it fixes no length), so
    `cert_payload_delivery_length` + `cert_payload_delivery_loses_nothing` recover
    the landed statement in `cert_payload_delivery_recovers_the_landed_statement`.
    *The first version of this file asserted "nothing traded" there in prose.*
  ⛔ **Its docstring carries the scope refusal that matters**: that draft's §4
  sentence conjoins *"proven in the kernel"* with *"rides on the die"* and *"drives
  the taped-out switch"*. **The certificate covers the kernel clause and explicitly
  disclaims the other two**, which are silicon's evidence about a netlist and a
  shuttle submission and are not Lean theorems.

* `SaltWorks/Certs/Compiler.lean` — **THE COMPILER'S SIMULATION THEOREMS**, four
  certificates. Direction: **same proposition** throughout, each closing by `exact`.
  ⭐ **Its one move is that `encodeOK` is UNFOLDED INTO EVERY STATEMENT** — the landed
  theorems are stated through that defined predicate, whose name reads like *"the
  machine state encodes the source state"* while its definition constrains REGISTERS
  and says nothing about `mem` or the trap flag. With the quantifier written out, the
  scope is visible in the theorem instead of in a docstring a reader must trust.
  - `cert_compileE_value` · `cert_compileS_simulation` ·
    `cert_compileS_simulation_with_loops` — L0, L1 and the loop-carrying L2 shape.
  - `cert_the_fragment_boundary` — ⛔ **what the compiler REFUSES**, exhibited: a
    sequence compiles, a **conditional does not**, a loop does. *A cert layer that only
    restated what was proved would leave the most important fact about this compiler —
    that it refuses half of control flow — visible nowhere.*
  - ⭐ **THREE MORE REFUSALS, added at evidence's 18:14 observation** that a certificate
    over a landed NEGATIVE CONTROL proves a hypothesis is load-bearing rather than that
    a claim holds: `cert_branchFree_does_not_imply_compiles` (a branch-free assignment
    with an oversized constant is REFUSED — so `branchFree` is necessary, not
    sufficient) · `cert_pool_exhaustion_is_a_real_limit` (level 14 has a register, level
    15 does not) · `cert_the_fragment_exceeds_branch_free` (a loop compiles and is not
    branch-free — the witness that the two notions have PARTED).

* `SaltWorks/Certs/Executive.lean` — **THE EXECUTIVE'S ISOLATION CLAIMS**, four
  certificates, answering the second half of the evidence seat's 03:45 pillar flag
  (*"a verified COMPILER" and "a verified EXECUTIVE" … their owners should state what
  those words cover before the sentence travels*). ⚠️ *The ellipsis is a provenance
  repair (2026-08-12): as landed, an em-dash here implied contiguity across ~20 elided
  words. **SOURCE PIN: the EVIDENCE seat, 2026-08-11 03:45**, on `FLEET.md` — seat and
  stamp, not a line number, because the bus is append-only and versioned nowhere. Second
  of two sites; the full note is in `Certs/Executive.lean`.*
  - `cert_side_condition_meaning` — ⭐ an **`iff`**: the decidable `writesWithin` test
    and its plain-English reading are proved the same claim, so the vocabulary
    translation is kernel-checked rather than asserted.
  - `cert_step_frame` · `cert_task_isolation` — a task's instruction cannot move a
    register outside its own set; disjoint tasks cannot disturb each other. **Read
    through the SHARED register file**, which is what makes it a theorem rather than a
    fact about the type.
  - `cert_isolation_needs_disjointness` — ⛔ delete the disjointness hypothesis and
    isolation is FALSE, with a kernel-executed witness (`5` becomes `9`).
  ⚠️ **Its scope limits are the point: REGISTERS ONLY** (nothing about memory, the
  trap flag, or `pc`), **ONE STEP**, partitions **given not derived**, and **no
  liveness**. *Since M2 the machine has real load/store, so memory isolation is not
  merely unproved here — it is not addressed.*

* `SaltWorks/Certs/ControlFlow.lean` — **THE `while` / `ite` OFFSET SCHEMES**, ten
  certificates.
  ⛔ **ITS HEADLINE IS A SCOPE REFUSAL: the `ite` half is PROVED AND NOT WIRED.** *A
  reader who sees "the while/ite scheme pair is certified" will conclude the compiler
  handles conditionals. It does not — `compileS` returns `none` on every `ite`, which
  `Certs/Compiler.lean` proves. This file certifies the ite OFFSET ARITHMETIC and
  nothing about a compiler path that does not exist.*
  - `cert_exit_branch_lands` · `cert_back_branch_lands` — the offsets land correctly at
    **every block size** (the backward one gets there by WRAPPING, which is why it
    needed a proof rather than an inspection), plus the same pair at the machine's own
    `step`.
  - `cert_the_bound_is_tight_on_both_sides` · `cert_the_two_directions_differ_by_one` —
    ⭐ the 12-bit bound is **asymmetric and DERIVED, not chosen**: past the backward
    limit a back-edge becomes a forward jump; past the forward limit an exit becomes a
    re-entry. *Same off-by-one, opposite catastrophes.*
  - `cert_while_scheme_runs` · `cert_ite_scheme_runs` — finite, kernel-executed
    non-vacuity, each loop row carrying its own HALT proof.
  - `cert_a_wrong_backward_offset_never_terminates` ·
    `cert_a_wrong_ite_offset_keeps_the_right_value` — ⛔ the two mutants where **the
    observable value is CORRECT and the program is BROKEN**. *Only the halt check
    separates the first; only observing the right thing separates the second.*

* `SaltWorks/Certs/EndToEnd.lean` — **THE ENCODING, THE WITNESS, AND ONE WHOLE
  PROGRAM**, eight certificates. **Closes the last TWO target rows** (`decode_encode`,
  `witness_chain_discharged`) and adds the external-witness rows that make the first
  mean what a reader will think it means.
  ⛔ **ITS SCOPE REFUSAL: "RV32I" IS NOT WHAT IS PROVED.** *`cert_encode_decode_round_trip`
  says THIS corpus's encoder and decoder are inverse on THIS corpus's `Instr`. It does
  **not** say the encoding conforms to the RISC-V specification, and no theorem in this
  repository does.* **The conformance EVIDENCE is Spike** — `cert_an_outside_simulator_agrees`,
  120 vectors from a third-party simulator that has never seen this repository, full-state
  compared — *and the corpus's own ruling on it is that **Spike is a WITNESS, not an
  oracle**.*
  - ⭐⭐ `cert_what_this_machine_does_not_implement` — **twenty legal RV32I encodings that
    Spike executes and this decoder REFUSES** (`lui`, `auipc`, `jal`, `jalr`, `lb`, `sb`,
    the shifts, `sub`, `bne`/`blt`/`bge`). *A reader sizing "a verified RISC-V processor"
    can read the gap instead of estimating it.* ⏰ *That list's expiry is enforced by the
    BUILD: when M2 landed `LW`/`SW` the two word-sized rows stopped being excluded and the
    theorem broke on the day, exactly as predicted on 2026-08-07.*
  - `cert_the_bits_and_the_instruction_agree` — running the 32-bit WORD leaves the state
    running the INSTRUCTION leaves; the bridge that makes the abstract type an account of a
    bit-level machine rather than a parallel story about it.
  - `cert_one_whole_program_end_to_end` — `x := x + 5` with `x = 7` compiles to four
    instructions and leaves **12**. *Without a row like this, every theorem in the compiler
    pillar is satisfiable by a `compileS` nobody can run.*

## ✅ TARGET LIST v1 — **COMPLETE**. All six saltworks rows landed.

*`the compileE/compileS simulation theorems` · `the while/ite scheme correctness pair` ·
`decode_encode` · `witness_chain_discharged` · `step_frame/writesInstr` · the 1990 cert.*
**Any paper-quoted claim added later gets its cert in the same wave (the block's
freeze-week rule).**

⚠️ **THE TRAP FOR EVERY REMAINING ROW IN THIS DIRECTORY, and it is on the DOCSTRING
surface only.** Iron rule 3 makes the Lean side mechanical — a certificate is *proved
from* its landed theorem, so the kernel cannot admit a stronger statement and an
overstating certificate simply does not build. **The docstring is checked by nothing
but a reader.** The concrete instance from this seat's own lane, carried here so the
next hand meets it before writing rather than after:

```
encodeOK Γ reg σ st  ≡  ∀ i : Fin poolSize, i.val < Γ.length → st.get (reg i) = σ i.val
  ⛔ FALSE prose  "the compiled code computes what the source program says"
     — `St` also carries `mem`/`trapped`; encodeOK mentions NEITHER.
  ✅ HONEST prose "for every variable the source has IN SCOPE, the register the
     compiler assigned to it ends up holding that variable's value"
```

## ⚖️ WITNESS KINDS — rule 6 as amended at council 2026-08-12 (`b1c7677`)

*Rule 6 asks each certificate to DECLARE what its witness proves, because a satisfiability
witness and a non-degeneracy witness are different controls: a binder inhabited only by
degenerate points survives "instantiate and evaluate" untouched.* **Every declaration below
carries a `Witness:` line. Counts, RE-DERIVED at this landing (2026-08-12 11:0x):**

```
EXEMPT           20    no witness — universal statements
NON-DEGENERACY   13    a witness chosen so a degenerate one would prove nothing
SATISFIABILITY    5    a binder exhibited as inhabited
                ───
                 38    certificates.  OPEN ROWS: NONE.
plus              4    NAMED witness_ declarations, all in the axiom census
```
⚠️ ***THIS BLOCK FIRST LANDED WITH A FIFTH ROW — "SATISFIABILITY — NOT WITNESSED, QUESTION: 1"
— AND IT WENT STALE WITHIN THE HOUR WHEN THE ROW CLOSED. It is re-derived here rather than
edited in place, because a COUNT and a MISSING-LIST are both derived facts and both rot; a
missing-list rots in ONE direction only, always over-reporting what is owed, which is why it
reads as conservative and survives review.***

### THE ROW THAT WAS OPEN, and how it closed — kept because the argument is the useful part
*`cert_task_isolation` CONJOINS `Disjoint Pcur Pother` with the writes-within condition over
shared objects — the same shape as the one vacuous certificate this tier has caught (the
`ControlFlow` exit/back split, contradictory in ℕ). Both hypotheses are satisfiable ALONE, and
`cert_isolation_needs_disjointness` witnesses only the OVERLAPPING case, which is the refutation
rather than an inhabitant. **So the certificate was landed declaring the question OPEN rather
than asserting a kind.***

✅ **CLOSED BY TWO SEATS, and the division of labour is the lesson:** *the EVIDENCE seat proposed
the assignment and stated plainly they had not typechecked it; **this seat typechecked it.** The
DESIGN judgement was the declined part — a degenerate fixture would have passed — and a peer
supplying it turned the remainder into a build.* **A decline that names WHICH PART is hard is
answerable; "wants a fresh head" is not.**
⭐ **AND IT WAS STRENGTHENED AFTER LANDING, by its own designer reading it harder for that reason:**
*the first witness used `.ADD 1 1 1`, which on a zeroed register file computes `0 + 0 = 0` — the
write happened and **nothing moved.** With `.ADDI 1 0 5` register 1 goes `0 → 5` while register 2
holds at `0`. **A witness that writes without changing anything cannot distinguish "isolation
holds" from "the step did nothing", and those are the two readings a reader must tell apart.***

📛 **THE WITNESSES ARE NAMED, NOT `example`s (evidence, 11:04).** *`#audit_axioms` takes a NAME, so
an anonymous witness sits OUTSIDE the axiom census — a certificate could read `[3 axioms]` clean
while the control proving it non-vacuous was invisible to the audit. **Rule 6 made witnesses
mandatory and thereby made an unaudited declaration mandatory with them.*** *Fixed while every
witness still closes by `decide` and the answer costs nothing.*

## ✅ ROOTED — and ⛔ **THE GREP THAT FALSE-PASSED IT**

`SaltWorks.lean:8` imports `SaltWorks.Certs.All` (maestro, `5afc305`, 2026-08-11), so
the hub build replays this tree rather than reaching it only when a file here is named
as a target. *This paragraph replaced an "import owed" note that went false within
minutes of being written — a present-tense caveat rots in the flattering direction the
moment the obligation is met.*

⛔⛔ **THE DECOY IS PERMANENT AND WORTH KEEPING AFTER THE FIX: DO NOT CHECK THIS
ROOTING BY GREPPING `SaltWorks.lean` FOR "Certs".** *It also imports
`SaltWorks.HDL.Certs` — a **different, pre-existing, unrelated module**, three lines
above — so a name-grep hits, the check reads PASSED, and it would have read PASSED
just as loudly while this tree sat outside the closure.* **Grep the full string
`SaltWorks.Certs.All`, or check the closure rather than the text.** *(Measured by the
silicon seat on `f327798` at 16:42, before the rooting: the adjacent-object law living
in the import graph — the right query, the wrong object, and the wrong object named
almost the same thing.)*
-/

#audit_axioms SaltWorks.Certs.cert_full_circle
#audit_axioms SaltWorks.Certs.cert_head_after_stages
#audit_axioms SaltWorks.Certs.cert_length_premise_is_load_bearing
#audit_axioms SaltWorks.Certs.cert_address_restored_after_three_stages
#audit_axioms SaltWorks.Certs.cert_stage_reads_original_bit
#audit_axioms SaltWorks.Certs.cert_payload_delivery
#audit_axioms SaltWorks.Certs.cert_payload_delivery_length
#audit_axioms SaltWorks.Certs.cert_payload_delivery_loses_nothing
#audit_axioms SaltWorks.Certs.cert_payload_delivery_recovers_the_landed_statement

#audit_axioms SaltWorks.Certs.cert_compileE_value
#audit_axioms SaltWorks.Certs.cert_compileS_simulation
#audit_axioms SaltWorks.Certs.cert_compileS_simulation_with_loops
#audit_axioms SaltWorks.Certs.cert_the_fragment_boundary
#audit_axioms SaltWorks.Certs.cert_branchFree_does_not_imply_compiles
#audit_axioms SaltWorks.Certs.cert_pool_exhaustion_is_a_real_limit
#audit_axioms SaltWorks.Certs.cert_the_fragment_exceeds_branch_free

#audit_axioms SaltWorks.Certs.cert_side_condition_meaning
#audit_axioms SaltWorks.Certs.cert_step_frame
#audit_axioms SaltWorks.Certs.cert_task_isolation
#audit_axioms SaltWorks.Certs.cert_isolation_needs_disjointness

#audit_axioms SaltWorks.Certs.cert_exit_branch_lands
#audit_axioms SaltWorks.Certs.cert_back_branch_lands
#audit_axioms SaltWorks.Certs.cert_exit_branch_lands_at_the_machine
#audit_axioms SaltWorks.Certs.cert_back_branch_lands_at_the_machine
#audit_axioms SaltWorks.Certs.cert_the_bound_is_tight_on_both_sides
#audit_axioms SaltWorks.Certs.cert_the_two_directions_differ_by_one
#audit_axioms SaltWorks.Certs.cert_while_scheme_runs
#audit_axioms SaltWorks.Certs.cert_ite_scheme_runs
#audit_axioms SaltWorks.Certs.cert_a_wrong_backward_offset_never_terminates
#audit_axioms SaltWorks.Certs.cert_a_wrong_ite_offset_keeps_the_right_value

#audit_axioms SaltWorks.Certs.cert_encode_decode_round_trip
#audit_axioms SaltWorks.Certs.cert_no_two_instructions_share_an_encoding
#audit_axioms SaltWorks.Certs.cert_the_bits_and_the_instruction_agree
#audit_axioms SaltWorks.Certs.cert_an_outside_simulator_agrees
#audit_axioms SaltWorks.Certs.cert_the_witness_suite_is_not_vacuous
#audit_axioms SaltWorks.Certs.cert_illegal_words_are_rejected
#audit_axioms SaltWorks.Certs.cert_what_this_machine_does_not_implement
#audit_axioms SaltWorks.Certs.cert_one_whole_program_end_to_end
