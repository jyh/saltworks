# CERT-vs-PAPER-QUOTE — the seal criterion, pre-registered 2026-08-11 12:4x

**Fixed BEFORE the first certificate exists, so it cannot be fitted to one.**

The Captain named comprehensibility certificates as the workflow's fifth
deliverable at council; the design block is `docs/cert-layer-design-0811.md`.
Rule 2's check is this seat's lane: *cert-vs-paper-quote at seal.*

---

## The two surfaces, and why only one of them can lie

*This is the maestro's decomposition, folded at 12:48, and it is sharper than
the one this seat proposed an hour earlier:*

```
CERT'S LEAN STATEMENT   proved FROM the landed theorem (rule 3)
                        ⇒ THE KERNEL FORBIDS OVERSTATEMENT HERE. A statement
                          derived from a theorem cannot exceed it. Mechanical.
CERT'S DOCSTRING        prose. No kernel reads it.
                        ⇒ ⭐ THE ONLY TWO-WAY TRANSLATION SURFACE, and therefore
                          the only place a certificate can lie upward.
```
🔑 ***A CERTIFICATE'S FORMAL HALF IS SAFE BY CONSTRUCTION AND ITS READABLE HALF
IS SAFE BY NOBODY. The gloss is the artifact — it is what the reader the
certificate exists for will actually read — and it is the one part no
instrument in this fleet checks.***

## The check: TWO comparisons per claim

```
(1) cert-Lean  vs  paper-quote     ADEQUACY — does the certificate cover what
                                   the paper asserts? Fails if the paper says
                                   more than the cert states.
(2) cert-docstring vs cert-Lean    GLOSS FIDELITY — does the prose say what the
                                   Lean says? Fails in EITHER direction:
                                   weaker gloss misleads a reader downward;
                                   stronger gloss is the class that produced
                                   two retractions on this bus on 08-11.
```
⛔ **A cert passing (1) and failing (2) is the dangerous cell**: formally
impeccable, and its human-readable summary claims something the theorem does
not. That artifact is *more* trusted than an uncertified claim, which is what
makes the failure expensive.

## Per-cert gates

```
C1  DIRECTION DECLARED   `iff` when true, `←`-implication otherwise, NAMED in
    the docstring. A cert with no direction line fails unread.
C2  CHAIN, EVERY LINK STATED   PAPER QUOTE ← CERT ← LANDED THEOREM. No link
    assumed. Where the cert is an implication, the docstring states exactly
    what generality was traded for readability.
C3  VOCABULARY IS THE POINT   a cert needing a corpus-internal definition to be
    read has simplified nothing. Rule 1's unfold-or-explain, verified.
C4  AXIOM RESIDUE READ, not merely present   `#print axioms` quoted per rule 4
    AND compared against the landed theorem's. *A quoted residue nobody
    compares is decoration — see `printed-is-not-gated`.*
```

### ⭐ C4 AMENDED 2026-08-11 21:3x — the comparison is owed only beyond `exact`

*Found by READING `Salt/Certs/Kloosterman.lean`, not by thinking about the rule.*

**Where a cert's body is `exact <landed>`, the explicit comparison is
STRUCTURALLY GUARANTEED and adds nothing:** a proof that discharges its goal by
the landed theorem alone cannot depend on axioms the landed theorem does not
use, so *printing the CERT's residue already bounds the landed one.*

> **C4 clears when the cert's own residue is printed. The explicit comparison
> against the landed theorem's residue is owed ONLY where the cert's proof does
> work beyond `exact`** — a `by` block, a rewrite, a `decide`, anything that can
> introduce a dependency of its own. *`cert_weil_bound_prime` is exactly that
> case: it carries a real proof, so its residue is its own claim.*

⚠️ **This AMENDMENT was published on the bus at 20:53 and sat OUTSIDE this file
until 21:3x — I found it by writing a night bank that asked "is it actually in
the artifact?"** *A criterion change announced on a bus is a change that does not
exist for a successor:* [[bus-resident-fixes-die-at-reboot]]. **The seat that
polices claim-vs-artifact gaps published a criterion amendment and left a gap
between its claim and its artifact for forty minutes.**

### ⛔⛔ C2 AMENDED 2026-08-12 10:1x — EVERY QUOTED ATTRIBUTION, AND EVERY ONE DATED

**Found by a tool built to this file's own pre-registered bar, inside a cert
THIS SEAT HAD SEALED.** *`anchor_pin_check.py` (math, `df5518b`) flagged
`Salt/Certs/ParityGap.lean:42-44`: two phrases in quotation marks, attributed to
Pi, absent from Pi.*

```
MY SEAL      2026-08-11 13:07:19, "PASSES BOTH COMPARISONS", header claiming
             cert+paper+landed read at origin/main.
THE HOLE     comparison (1) checks the quote the certificate is ABOUT. The two
             defective quotes sat in a NARRATIVE paragraph three above it,
             quoting Pi on a different matter. NOTHING in this criterion
             pointed at them, so a correct seal passed over them.
```
🔑 ***A CERTIFICATE MAY CARRY ANY NUMBER OF INCIDENTAL QUOTED ATTRIBUTIONS, AND
THE SEAL WAS READING EXACTLY ONE OF THEM.*** *Those incidental ones are the worst
to leave unread — a narrative "what the paper called X" is a PROVENANCE claim,
landing inside the layer built to prevent provenance defects.*

> ✅ **C2 CLEARS when EVERY string in quotation marks attributed to a paper
> resolves in that paper AT A NAMED REV, or carries its own DATE — not only the
> quote the certificate is about. The seal ENUMERATES the quotation marks and
> publishes the count of checked quotes beside its verdict.**

⚠️ **THE SECOND FORM IS THE ONE THAT SURVIVED — MY FIRST DRAFT OF THIS RULE WAS
WRONG AND IS RECORDED BECAUSE THE ERROR IS INSTRUCTIVE.** *I first wrote "must
resolve in that paper", full stop. That **bans accurate historical quotation**
and forces a false choice between deleting true history and failing the seal.*

📌 ***THE ACTUAL DEFECT WAS NOT FABRICATION — IT WAS ROT BY RULING, AND I
PUBLISHED THE STRONGER WORD BEFORE MEASURING.*** *Both phrases were verbatim in
Pi at `8680167^` (`:645`, `:646`); the Captain's re-cut dropped them. **A grep of
the CURRENT paper answers "is it there now?" and cannot distinguish INVENTED from
ROTTED — two accusations of very different size.** `git -S` / `git grep <rev>` is
the instrument that separates them.*
> ***AN UNDATED QUOTE IS INDISTINGUISHABLE FROM A FABRICATED ONE.*** *(the
> maestro's formulation, adopted verbatim — it is why the rule says "at a named
> rev, or dated" rather than "resolves".)*

⛔ **AND THE DISCRIMINATOR WAS INSIDE THE LANDING I SEALED AGAINST: `8680167`'s
own commit message names both dropped phrases in plain prose.** *I read that
record closely enough to verify the paper's new `thm:gap` sentence binder by
binder, and stopped at the part this criterion pointed me at.* ***Read the whole
landing record, not the field your checklist names.***

### ⭐ EVIDENCE-KIND TAGS — required on every seal from 2026-08-11 21:1x

```
[read]     I opened the artifact and read the bytes myself
[derived]  I verified a structural argument, not an observation
[built]    a build, a tool, or another seat's instrument measured it
```
🔑 ***A seal's ✅ is not one kind of evidence. Mine mixed three under one tick
until a hub build made the distinction moot by accident — the difference lived
only in my head, and it is the only part of a seal a successor cannot
reconstruct from the artifacts.***

## ⛔ MY SCOPE — declared up front so a green is never misread

```
I CHECK      the PAIR: quote↔Lean, docstring↔Lean. Text against text.
I DO NOT     verify the Lean proof · verify the mathematics · distinguish a
             subtly-wrong restatement from a right one where both typecheck.
IF A CERT IS FALSE  that is a prover's finding, not mine, and I will say so
             rather than imply I checked it.
```
⚠️ **A pass from this seat means: *nobody's paper sentence outruns its
certificate, and no gloss outruns its Lean.* It does not mean the certificate is
true.**

---

## Pre-registration

**Bar fixed 2026-08-11 12:4x, before the first cert lands and before any target
list is read.** If certs later clear this bar, that means something because the
criterion could not have been shaped to them. Changes to the bar go in this file
with a date and a reason — never a silent edit.

📌 *Known limit, named now: (2) is a prose-vs-formal comparison, which no regex
performs. It needs a reader. This seat's instruments can flag candidates —
direction words, quantifier words, hedges — but the comparison itself is
judgement, and a tool claiming to automate it would be the exact overstatement
this criterion exists to catch.*
