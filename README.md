# SaltWorks

SaltWorks is a demonstration of a machine-verified full-stack implementation from
application code, through a verified compiler and executive, to a verified RISC-V
processor taped out on a community silicon shuttle; no proof passed through human
review, and no RTL was written by a human. The working discipline — the Salt
method — rests on a proof kernel no hallucinated proof can pass: mathematical
claims travel between agents as kernel-checked artifacts, and human attention is
reserved for statements, designs, and rulings. Verification is stated link by
link, from the Lean 4 kernel to SAT-checked equivalence at the silicon boundary.
We include the complete accounting: theorem provenance, a pre-registered token
meter, and an error ledger, constituted from the campaign's append-only logs.

## The stack, layer by layer

| Layer | Where | What is proved |
|---|---|---|
| Application | [`SaltWorks/Stack/`](SaltWorks/Stack/) | application programs and their specifications, with the bridge theorems connecting them to the layers below |
| Compiler | [`SaltWorks/HDL/`](SaltWorks/HDL/) | the verified compiler: expressions, straight-line code, and loops, down through the circuit DSL to Verilog, with the ISA semantics |
| Executive | [`SaltWorks/HDL/`](SaltWorks/HDL/) | the executive's isolation theorems (`Executive*.lean`), with the certificate restatement in [`SaltWorks/Certs/`](SaltWorks/Certs/) |
| CPU / silicon | [`SaltWorks/Silicon/`](SaltWorks/Silicon/) | the flow, the netlist importer, and SAT-checked equivalence at the silicon boundary |
| The switch | [`SaltWorks/Banyan/`](SaltWorks/Banyan/) | the Batcher–banyan self-routing switch, sort-then-route closed end to end |
| Certificates | [`SaltWorks/Certs/`](SaltWorks/Certs/) | the comprehensibility layer: headline theorems restated in primitive vocabulary, the restatement kernel-proved equivalent |

## What is here

- [`SaltWorks/`](SaltWorks/) — a Lean 4 library: the machine-checked artifacts
  of the program (definitions, theorems, and the audit stanzas that certify
  them). Every proof is checked by the Lean kernel; `lake build` replays the
  entire check.
- [`docs/`](docs/) — the program's registers and records: preregistrations,
  evidence ledgers, design documents, and seat records, kept as the work
  happened.
- [`tools/`](tools/) — scripts used to build, audit, and maintain the records
  above.

## Building

Requires [elan](https://github.com/leanprover/elan); the toolchain is pinned in
`lean-toolchain`.

    lake build

## The Salt method

The method makes three commitments. Truth is machine-checked only: every claim
lands in the kernel, and nothing unverified accumulates into the record. Whatever
the kernel cannot check is checked by structured opposition: designs receive
adversarial refuter passes before execution, landings are witnessed
independently, and measurements travel with the commands that produced them.
Human attention is treated as the scarcest resource in the system, spent
exclusively on statements, designs, and rulings.

**Every objective returns five artifacts:**

| Artifact | |
|---|---|
| implementation | *P* |
| specification | *S* |
| correctness proof | ⊢ *P* ∈ *S* |
| adversarial tests | *T(P)* |
| comprehensibility certificates *S′* | ⊢ *S* ⇒ *S′* |

The certificates *S′* are easily comprehensible properties that justify the
specification *S*. A common example of such an *S′* is that the tests are
formally proved: ⊢ *S* ⇒ *T(P)*, in other words, the system tests are formally
proved.

**Six required invariants** (tool-agnostic — what the method *is*):

- **R1** — there are five artifacts (listed above), at every level from project
  design to component design.
- **R2** — no claim is admitted without its checker: the kernel for mathematics,
  the named instrument for measurements, structured opposition for designs.
- **R3** — all design decisions, including human choices, are recorded in an
  append-only ledger whose distinctive content is the errors and retractions,
  amended at their source and recorded as first-class results.
- **R4** — no statement is ever weakened to admit a proof; statement changes are
  design-tier acts, never taken by an executor agent.
- **R5** — a small class of irreversible, outward-facing acts is reserved to
  human hands; the system's job is to reduce each to a prepared click and stop.
- **R6** — conditional objectives are allowed: a statement may name hypotheses it
  does not discharge, provided each is named in the statement itself with a
  declared disposition — *to be discharged* (ledger-owed) or *out of domain* (a
  stated trust boundary with another discipline). A program's final deliverable
  carries no undischarged in-domain hypotheses.

**Six advisory articles** (the reference configuration this case study ran and
measured):

- **A1** — a single orchestrator agent on the top model class performs the most
  complex design work, passes routine work to executor agents, and owns the
  referee's own infrastructure; audit tooling is never owned by a seat it
  audits.
- **A2** — executor agents are the workhorses — building, verifying, proving,
  refuting — and every task is classified by difficulty and priced before it is
  attempted.
- **A3** — attempts are budgeted small, and an agent that exhausts its budget
  stops and announces its failure rather than grinding on.
- **A4** — every major design phase has an exploration part and an adversarial
  refutation part, iterated until dry, with acceptance criteria pre-registered
  before the artifact exists.
- **A5** — human interaction is periodic and scheduled; this program held a
  daily council with recorded rulings.
- **A6** — every landing is verified by a second agent that did not produce it.

## Reading the record

This repository is a record first and a library second. Three kinds of documents
live in `docs/`, and they are read differently:

- **Preregistrations** ([`docs/measurement-preregistration.md`](docs/measurement-preregistration.md)
  and the `*-PREREG-*` files): commitments written before their measurements ran —
  including the token meter named above. Read these first when evaluating any
  claimed result; the matching scores and retractions sit beside them under the
  same name stem.
- **Evidence ledgers** (`docs/EVIDENCE-*.md`, [`docs/ledger-tools/`](docs/ledger-tools/)): the error
  ledger and measurement records named above, kept append-only, corrections
  landed as corrections rather than edits. Errors are part of the record by
  design.
- **Design documents** (`*-design-*.md`, the `aim-high-*` series): what each
  campaign intended, written before it ran. Theorem provenance travels in the
  library's audit stanzas: every public theorem is roll-called with its axiom
  audit, and `lake build` replays the certification.

The submission-state snapshot of this repository is preserved as an annotated
tag and a release bundle; the default branch continues past it as the program
continues.

## Provenance

The work in this repository was produced by a human-directed fleet of AI agents
(Claude, by Anthropic), with human direction, review, and rulings throughout, and
the Lean kernel as the final referee for all formal claims. The collaboration
methodology and its numbers of record are described in the paper.

## License

Apache License 2.0 — see `LICENSE`.

## Data availability

The complete formal development — all Lean sources, proofs, certificate
restatements, and build configuration — is available at
https://github.com/jyh/saltworks (tag `nature-2026-08`). The tagged
snapshot is the submission record; the repository's live branch continues
beyond it. Every theorem can be re-verified from source with a single
build command; the certificate layer restates the headline results in
primitive vocabulary, with the restatements themselves kernel-checked.
