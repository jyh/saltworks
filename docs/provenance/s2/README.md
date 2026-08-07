# S2 — THE PROVENANCE BUNDLE (the artifact's birth record)

The STACK campaign's claim is **"unverified agent → verified code → verified compiler →
verified silicon."** *"Unverified agent"* is a claim about **provenance**, so the provenance is
part of the deliverable — not a note about the deliverable. This directory is that record, bound
to `SaltWorks/Stack/Program.lean` in the same commit so the artifact and its birth record cannot
drift apart or be separated later.

Adopted from the evidence seat's point, ordered by the maestro, 2026-08-07.

## How it is bound to the artifact

The program landed in **`bf2de34`**; this bundle in **`a5d2ef7`**, which has `bf2de34` as an
**ancestor** — so *the record provably cannot predate the artifact*. ⚠️ **That is an ordering
guarantee, not a containment one:** a later commit could edit `Program.lean` while this directory
sits unchanged. **Nothing here makes the pair self-enforcing**, and until something does, drift is
prevented by review rather than by mechanism. *(Corrected 13:57 — this section previously claimed
the two were bound "in the same commit", which is false and named the one mechanism that would
have made the promise self-enforcing. Found by the evidence seat.)*

## The three parts

| file | what it is |
|---|---|
| `s2-executor-transcript.jsonl` | The executor's **full transcript, verbatim and unredacted** — every prompt, tool call, and result, in the order they happened. **136 lines, 558,073 bytes (545.0 KiB)**. SHA-256 `eb3cf4e6fb69883232166f0239d4717c1d2697a62b644a549e64739a5bd5fc81`. |
| `s2-final-report.md` | The executor's own final report, including its **authorship record in its own words** — what it wrote by hand, what it derived, and what it got wrong first. |
| `s2-emitted-program.md` | The **emitted program as data**: all 120 assembled words, complete and untruncated, produced by `#eval` + `IO.println` against the committed module (`saltbuild EXIT=0`). |

## ⚠️ What this record does and does not certify

- **It is unredacted.** The maestro's order was *verbatim*, and a redacted provenance record
  defeats its own purpose. It therefore contains absolute machine paths and may contain account
  identifiers.
- ⛔ **The math seat did NOT read the transcript before committing it.** The file is large enough
  to overflow a working context, and the harness warns against reading it. So this bundle
  certifies **provenance, not contents**: it is a faithful copy of what the executor actually did,
  and nobody has vetted what is inside it. *That distinction is the honest one and it is stated
  here rather than implied away.*
- 📌 **PUBLICATION-GATE ITEM.** `saltworks` is **private** today, so committing this is not a
  publication. But this campaign aims at a public artifact, and **a verbatim transcript in git
  history is exactly the class of thing salt already carries a history-purge doctrine for.**
  Whoever cuts this repo public inherits this directory and should decide deliberately, not
  discover it.

## Why bind it at all, when the file already existed

It lived at `~/.claude/projects/<project>/<session>/subagents/agent-<id>.jsonl` — **outside git**,
in the same class of machine-local path that nearly lost the TS-1 wave in the 8/6 fleet migration.
*Staged is not saved.* Binding it into the repo **is** the preservation, not the ceremony.

## What the record shows, in one line

The executor was **wrong twice about arithmetic no build would have flagged** — it took a bad
branch immediate from its brief (`imm = 6`, actually `8`), and its own forwardness check first read
`0 < imm.toNat`, which accepts every backward branch. **Both were caught only by writing the claim
down as something the kernel could reject** — and both are committed as certificates
(`offset_six_does_not_sort`, `forwardness_must_be_signed`) rather than quietly deleted. That is the
strongest available evidence for what the campaign is actually claiming about agent-written code:
not that the agent was right, but that **the layers below it caught what it got wrong.**

## Corrections to this file (13:57, all three found by the evidence seat)

This bundle's own README carried three defects within an hour of landing. They are recorded here
rather than silently patched, because **a provenance record that quietly edits itself is the one
thing it must not be.**

1. **The binding mechanism was misstated** — "in the same commit" was false (two commits; see
   *How it is bound* above). The sentence named the one mechanism that would have made the promise
   self-enforcing, so the error was not cosmetic: it claimed a guarantee nobody had built.
2. ⛔ **The word list was 51 of 120 (42.5%) and ended in Lean's `⋯` truncation marker**, under a
   heading claiming all 120. **The one file whose entire purpose is to be the program *as data* was
   the one file not all there.** Regenerated with `IO.println`, which is not subject to `#eval`'s
   display truncation; now verified at 120 emitted lines with the marker absent.
3. **"548 KB" was a true reading of the wrong object** — `du` reports *allocation* (137 × 4096 B),
   `ls`/`wc` report *length*. The file is **558,073 bytes = 545.0 KiB**. Nothing turned on it; it is
   recorded because it is the same shape as the errors that do.

📌 **The pattern in 1 and 2 is one I had already written down elsewhere and then committed anyway:
I asserted a count I had not verified.** The `(120, 120)` header pair in the emitted-program file
was genuine, and *that is what made the truncated list look right* — a true adjacent number
standing in for the one that mattered. The line-count and the SHA-256 in the table above were exact
throughout; the two figures that were wrong were the two nobody would have checked.
