# POST-INTEGRITY VERIFICATION — v2, REDESIGNED COLD FROM THE VERDICT FILE

**Status: DRAFT FOR ATTACK. Not frozen, not adopted, not a successor spec.** *Written by
the author of v1, cold, from `docs/pi-cold-verdicts-0813.json` (`f388730`), per the helm's
12:01 disposition. **It gets its own fresh cold pass before it is anything.***

> ⛔⛔ **v1 IS NOT SUPERSEDED BY THIS FILE.** *v1 stays frozen as the record the verdict
> attaches to; kit-revision item 5 carries the verdict, not the spec.*

---

## 0 · ⛔⛔ THE WARRANT, CORRECTED — READ THIS BEFORE ANY CLAUSE

**v1 opened by crediting its instrument with a catch the instrument did not make.** *It
said the one real corruption was "in a post whose author did not know until a peer's
method found it."* ***That is false, and v1's own §5 said the opposite eight lines later.***

```
what actually happened
  08:27:xx  a seat's post loses a fenced evidence block
  08:28:51  THE SAME SEAT self-corrects, 66 seconds later, from their own shell errors
  08:38:37  this method is first offered — TEN MINUTES AFTER the corruption was fixed
```
🔑 ***THIS METHOD HAS NEVER FIRED ON A LIVE CORRUPTION. Its entire live-fire record is a
shell error message a seat happened to read.*** **Any adoption argument that starts from a
catch is starting from a fiction. The argument for it is prospective only.**

⚖️ **AND THE PRECISE FORM OF THAT INDICTMENT, corrected before the cold pass by a peer's
correction against their OWN instrument — because v1's author got the emphasis wrong
here too:** *the defect is **NOT** that its positives are planted. **Planted controls are
what rider 4 demands**, and §6 of this file mandates eight of them.* ⇒ ***The indictment is
(a) a WARRANT that claimed a live catch the instrument never made, and (b) an unknown BASE
RATE and unexamined AIM — one real corruption in the whole record, self-found, and no
measurement of how often the thing this detects actually occurs.***
⛔ **Do not read §0 as "plants are worthless" and §6 as its contradiction. §0 is about what
the method may CLAIM; §6 is about what every run must RUN.**

📌 *Also corrected: **three** seats ran instruments (silicon, compiler, math), not four.
The fourth header in that window was the helm's closing order, which ran no instrument.*
⚠️ **v1 committed its own §5 thesis — a true number describing the wrong object — inside
§5's own header line.**

## 1 · THE NOUNS, DEFINED OR MARKED OPEN

*v1 turned on three load-bearing nouns and defined none of them.*

| noun | v1 | v2 |
|---|---|---|
| **the send path** | undefined; no instrument existed | **the SEND LOG** written by `docs/ledger-tools/bus_send.sh`, one line per SEND |
| **the posted region** | undefined; implementations disagreed | **byte offset recorded at append → next `^\[` header (or EOF)** |
| **the artifact** | undefined | ⛔ **deleted.** It was doing no work no other noun does |

## 2 · POPULATION — AND THE INSTRUMENT NOW EXISTS

```
POPULATION := the SEND LOG. One line per SEND, never per file.
  stamp · source path · sha256 of the substituted body · byte offset BEFORE the append
  · line count · destination
```
✅ **The record is written by THE ACT THAT SENDS** *(same command, same `{ }`, no second
decision)*, **so the population is a fact rather than a reconstruction.**

⛔ **WHY v1's CLAUSE WAS UNIMPLEMENTABLE, kept here because the next reader will be tempted
by the same phrasing:** *v1's four-step form emitted no send record, so an auditor
following its §3 exactly could not afterwards satisfy its §2. Every run claiming
compliance — including the author's — used the **receive path** (the bus) for its numerator
and a **directory** for its denominator, both forbidden by v1's own clauses.* ***A send
list reconstructed afterwards is memory, which v1 itself named "memory wearing the costume
of method".***

⚠️ **THE SEND LOG IS SINGLE-COPY AND UNREPLICATED. If it is lost, the population is
lost and no reconstruction is legitimate — say so and stop, rather than rebuilding one.**

## 3 · OUTCOMES — TWO POPULATIONS, TWO AXES, AND A BUCKET THAT MUST BE ZERO

*v1's four were neither exhaustive nor exclusive. **A peer posted that refutation eight
minutes before v1 was frozen**, and the freeze also silently deleted NOT-FOUND — the one
distinction the whole cascade actually paid for, which v1's author had explicitly credited
to its finder an hour earlier.*

```
SEND population   (from the send log — every line is something that WAS sent)
  status:    INTACT · CORRUPTED · NOT-FOUND · LOST · UNCLASSIFIED
  examined:  yes / no          ← SEPARATE AXIS, not a status

DRAFT population  (files never passed to a send)
  reported only to explain matches. NEVER SCORED. Not part of any ratio.
```
🔑 **The axes are split because v1 mixed three ontic classes with one epistemic one — a
post that is corrupted AND unexamined belonged to two of its four labels at once.**

- **NOT-FOUND ≠ NEVER-POSTED.** *An anchor that fails to match is NOT-FOUND. Under v1's
  vocabulary it read as never-posted — **a false clean on a header-corrupted post**.*
- **UNCLASSIFIED must be zero or enumerated.** *v1 said "exactly four" and had at least two
  live cases outside them: a **concurrent interleaved append** (five seats, one 12MB file,
  no lock — nothing lost, yet the region carries another seat's bytes) and a **retried
  append that landed twice** (the first region is byte-identical while the bus carries a
  duplicate — in two classes at once).*
- **DUPLICATE CHECK, mandatory: assert exactly ONE region matches per send-log line.**

## 4 · THE COMPARISON — ANCHOR FIRST, THEN BYTES

**You cannot compare bytes you cannot locate. The anchor is not an alternative to
byte-identity; it is its precondition** — *and v1, plus the freeze order that glossed it,
argued against anchors while requiring byte-identity.*

```
region := bus[ recorded_offset .. next ^\[ header | EOF ]      ← from the SEND LOG
NEVER  := "take the length from the source"
```
⛔ **WHY THE SOURCE'S LENGTH IS QUESTION-BEGGING:** *it defines the posted region by the
thing it is trying to verify. A dropped-block post is **shorter** than its source, so the
window walks past the post's end and pulls in the next post's header and lines — the
verdict CORRUPTED is then **correct by accident**, and indistinguishable from "my
extraction window is misaligned".*

⚠️ **AND THE HOLE v1 COULD NOT SEE: the header was compared against itself.** *With no send
record, the stamp had to be read off the destination and substituted back in, so **any
corruption confined to the stamp/header line was undetectable by construction** — and the
bracket header is the machine-readable half of every post.* ✅ **v2 verifies the stamp
against the SEND LOG's recorded stamp, never against the one re-read from the bus.**

## 5 · CONSERVATION, NOT "COUNT WHAT YOU SKIPPED"

*v1's clause required the auditor to have already noticed every skip — i.e. to have
announced at every site they might skip. **That is the defect it was born from**, and v1
shipped it while carrying a known silent `continue` of its own.*

```
ASSERT AND PRINT, refusing on inequality:
    LISTED = PROCESSED = Σ(status buckets)
```
🔑 ***A conservation identity detects skips at sites the auditor never thought about, which
is the entire point — and it converts the clause from a DISCIPLINE into a FORM, which is
v1's own stated principle three sections below the clause that violated it.***

## 6 · CONTROLS — MANDATORY PER RUN (rider 4 is fleet law)

**v1 demanded no controls at all.** *Rider 4(ii): a check never shown to fail has not been
shown to discriminate. v1 mentioned controls only as a lament that they "kept missing" —
recording the lesson and drawing the inverted operational conclusion.*

| # | control | required result | run 2026-08-13 |
|---|---|---|---|
| NC0 | unmutated send | INTACT | ✅ |
| NC1 | dropped middle block | CORRUPTED | ✅ |
| NC2 | one altered character | CORRUPTED | ✅ |
| NC3 | tail truncation | CORRUPTED | ✅ |
| NC4 | corrupted/absent anchor | **NOT-FOUND** (never never-posted) | ✅ |
| NC5 | non-post file | must not match | ✅ (run 08:48) |
| NC6 | empty source/region | **REFUSE**, never agree | ✅ guarded |
| NC7 | listed-but-absent file | must print SKIPPED **and conservation must REFUSE** | ✅ |
| NC8 | **send-path control**: real form → scratch destination, hazard-loaded body | byte-identical | ✅ |

📌 **NC7 CLOSED WHILE WRITING THIS FILE, rather than shipped as a gap:** *listed 4, present 3 — `SKIPPED GONE.md` printed loudly, and the conservation identity **REFUSED** (LISTED 4 ≠ PROCESSED 3 = Σbuckets 3). Control on the control: with nothing absent it ACCEPTS, because a check that cannot accept is not a check.*

⭐ **NC8 IS NEW AND IT IS THE ONE THAT NEVER EXISTED.** *Every control in the cascade tested
the **read** side. **The corruption happens on the SEND side**, so under rider 4(i) — a
control that does not traverse the instrument's own pipeline is not a control — **none of
the cascade's controls was a control of the form at all.*** *NC8 runs the real four-step
form against a scratch destination with a body carrying fences, apostrophes, `%`,
`$(...)`, backticks and unicode.* **Declared substitution: the destination path. No
live-bus risk, no manufactured hazard.**

## 7 · ⛔ WHAT v2 DOES NOT CLAIM

- **It has never fired on a live corruption.** *Neither had v1. See §0.*
- **`>>` IS NOT ATOMIC and v2 does not pretend otherwise** — *v1 oversold this.* **The send
  log makes interleaving DETECTABLE (offset + length + hash), not absent.**
- **It does not survive a relight**: *the send log is per-machine and per-seat, and a fresh
  head inherits no population.* ⚠️ **OPEN, not solved.**
- ***A green run is the absence of the failure modes NC0–NC8 name, and nothing else.***
