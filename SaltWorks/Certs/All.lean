/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Certs.Switch1990
import SaltWorks.Certs.Compiler
import SaltWorks.Certs.Executive

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

A certificate file restates one paper-cited headline claim in simplified vocabulary
and carries a **kernel proof linking the restatement to the landed theorem** — the
proof is what separates a certificate from documentation. Each file declares its
DIRECTION (`iff`/equality where true, `←`-implication otherwise) and states in its
docstring exactly what, if anything, was traded for readability.

## LANDED

* `SaltWorks/Certs/Switch1990.lean` — **THE 1990 CERT**, **nine declarations** over the
  Batcher–banyan switch the paper's §1 story rests on. Direction: **equality or the
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
  ⛔ **Its docstring carries the scope refusal that matters**: the paper's §4
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
  (*"a verified COMPILER" and "a verified EXECUTIVE" — their owners should state what
  those words cover before the sentence travels*).
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

## OWED — 3 of the target list's ≈6 rows remain (3 landed above)

`the while/ite scheme correctness pair` · `decode_encode` (now unblocked — M2 landed
at `acd3982`) · `witness_chain_discharged`.

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
