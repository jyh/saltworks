# S2 — THE PROVENANCE BUNDLE (the artifact's birth record)

The STACK campaign's claim is **"unverified agent → verified code → verified compiler →
verified silicon."** *"Unverified agent"* is a claim about **provenance**, so the provenance is
part of the deliverable — not a note about the deliverable. This directory is that record, bound
to `SaltWorks/Stack/Program.lean` in the same commit so the artifact and its birth record cannot
drift apart or be separated later.

Adopted from the evidence seat's point, ordered by the maestro, 2026-08-07.

## The three parts

| file | what it is |
|---|---|
| `s2-executor-transcript.jsonl` | The executor's **full transcript, verbatim and unredacted** — every prompt, tool call, and result, in the order they happened. 136 lines / 548 KB. SHA-256 `eb3cf4e6fb69883232166f0239d4717c1d2697a62b644a549e64739a5bd5fc81`. |
| `s2-final-report.md` | The executor's own final report, including its **authorship record in its own words** — what it wrote by hand, what it derived, and what it got wrong first. |
| `s2-emitted-program.md` | The **emitted program as data**: all 120 assembled words, produced by `#eval` against the committed module (`saltbuild EXIT=0`). |

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
