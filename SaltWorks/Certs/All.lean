/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Certs.Switch1990

/-!
# `SaltWorks/Certs/` — the comprehensibility-certificate layer, roll-call

Campaign: `docs/cert-layer-design-0811.md`, opened at the Captain's word 2026-08-11
as the workflow's **fifth deliverable** (implementation · specification · proof ·
tests · **certificates**). The salt-side twin is `Salt/Certs/All.lean`.

A certificate file restates one paper-cited headline claim in simplified vocabulary
and carries a **kernel proof linking the restatement to the landed theorem** — the
proof is what separates a certificate from documentation. Each file declares its
DIRECTION (`iff`/equality where true, `←`-implication otherwise) and states in its
docstring exactly what, if anything, was traded for readability.

## LANDED

* `SaltWorks/Certs/Switch1990.lean` — **THE 1990 CERT**, five certificates over the
  Batcher–banyan switch the paper's §1 story rests on. Direction: **equality or the
  same proposition** throughout, nothing traded.
  - `cert_full_circle` / `cert_address_restored_after_three_stages` — `rot^k = id`
    in plain vocabulary (`moveHeadToTail`, `afterStages`, both proved equal to the
    corpus's `rotStage`/`Function.iterate`), certifying
    `SaltWorks.HDL.rotate_full_circle`.
  - `cert_length_premise_is_load_bearing` — the one line showing the corpus's own
    `addr.length = k` identification is not decoration.
  - `cert_stage_reads_original_bit` — the self-routing consequence, one-directional,
    certifying `SaltWorks.HDL.stage_reads_original_bit`.
  - `cert_payload_delivery` — the Batcher half at the tapeout instance `P = 8`,
    certifying `L1Payload.l1_full_load_payload_delivery`, read one payload cycle at
    a time.
  ⛔ **Its docstring carries the scope refusal that matters**: the paper's §4
  sentence conjoins *"proven in the kernel"* with *"rides on the die"* and *"drives
  the taped-out switch"*. **The certificate covers the kernel clause and explicitly
  disclaims the other two**, which are silicon's evidence about a netlist and a
  shuttle submission and are not Lean theorems.

## OWED (target list v1, ≈6 saltworks files)

`the compileE/compileS simulation theorems` · `the while/ite scheme correctness pair`
· `decode_encode` (behind M2) · `witness_chain_discharged` ·
`step_frame/writesInstr` (the executive's isolation claims, plain form).

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

## ⚖️ IMPORT OWED

`SaltWorks.lean` is the maestro's file (`docs/SEATS.md`). This module is left for the
maestro's sweep; until it is imported there, the hub build reaches this tree only when
a file here is named as a build target. **The certificates below were built and
audited at their landing regardless** — `Built SaltWorks.Certs.Switch1990`, EXIT=0,
axioms measured and quoted in the file's own header.
-/

#audit_axioms SaltWorks.Certs.cert_full_circle
#audit_axioms SaltWorks.Certs.cert_length_premise_is_load_bearing
#audit_axioms SaltWorks.Certs.cert_address_restored_after_three_stages
#audit_axioms SaltWorks.Certs.cert_stage_reads_original_bit
#audit_axioms SaltWorks.Certs.cert_payload_delivery
