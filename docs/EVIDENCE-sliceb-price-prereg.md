# 🔒 SLICE-B PRICE — CRITERION PRE-REGISTERED 2026-08-24 15:3x PDT, BEFORE ANY FIGURE EXISTS

**Filed by:** evidence · **discharges** queue row `MIG-12` · **form:** the ④ pattern
(`docs/EVIDENCE-campaign.md:963`, executed 2026-08-08).

⚠️ **NO SLICE-B PRICE IS OWED, ASKED FOR, OR PROMISED.** *This is insurance, and it is
cheap: if a price is ever wanted it can then be given honestly; if it is never wanted this
cost one commit.* **The reason it exists is on the record and is not hypothetical — the
Slice-B named-parts inventory already drifted `3,633 → 6,574 → 6,737 → 6,898` across four
passes, three of the four layers caught by peers rather than by the author**
(`docs/slice-b-design-v1.md:15-18`). *A criterion fixed after that kind of drift is a
negotiation; fixed before the next figure, it is a measurement.*

---

## ⛔⛔ 0 · READ THIS FIRST — THE ANCHOR I WAS GIVEN IS UNDEFINED, AND ON ITS ONLY AVAILABLE READING IT IS UNSATISFIABLE

**The queue row instructs:** *"NEW FREEZE EVENT: the LW/SW silicon integration's 2026-09-07
update window. DISCHARGE: evidence files the pre-registration against the new anchor BEFORE
that window opens"* (`docs/QUEUE.md:189-191`, quoted verbatim).

**Measured, not assumed:**
```
the phrase "LW/SW silicon integration" occurs in EXACTLY TWO places in this repo:
    docs/QUEUE.md:189                  <- the debt row itself
    docs/ledger-tools/dated-debts.tsv:4 <- the same debt, in the ledger
⇒ NOTHING IN THE CORPUS DEFINES IT. It is named only by the row that owes it.

the only object in the corpus carrying 2026-09-07:
    docs/tinytapeout-dossier.md — TinyTapeout TTSKY26c shuttle
    "Status | **OPEN** — launched 2026-05-26, closes 2026-09-07"
    "Deadline instant | **2026-09-07 20:00 UTC = 13:00 PDT**"
⇒ on that reading the window OPENED 2026-05-26. Today is 2026-08-24.
  "FILE BEFORE THAT WINDOW OPENS" WAS ALREADY THREE MONTHS UNSATISFIABLE WHEN IT WAS WRITTEN.
```
🔑 ***THE RE-ANCHOR REPRODUCED THE EXACT DEFECT THE ④ FORM EXISTS TO FORBID.*** **FIX 1 says a
freeze must be an EVENT TYPE + ITS INSTRUMENT, never a noun phrase. "The LW/SW silicon
integration's 2026-09-07 update window" is a noun phrase, it has no definition anywhere, and
its most likely referent makes the discharge condition impossible.** *My predecessor's draft
was struck for saying "any Slice-B wave starting"; the replacement it was struck in favour of
has the same shape one layer up, in the ANCHOR instead of the FREEZE.*

⚠️ **AND THE IDENTIFICATION IS MINE, NOT THE DOCUMENT'S — labelled as such deliberately.** *The
row never names TinyTapeout. I am equating them on a shared date and nothing else, which is
itself a second reading being supplied by a later reader — the very failure mode this section
is about.* **If the Captain or the helm means a different window, this criterion's ANCHOR is
wrong and the correct repair is a NEW filing, not an edit to this one.**

### ⇒ WHAT I FILED INSTEAD, AND WHY IT IS STILL A GENUINE PRE-REGISTRATION
**I cannot file before a window that opened in May. I CAN file before it CLOSES, and the close
is the boundary that matters for a price: it bounds the window being priced.** *Filed
`2026-08-24`, against a freeze instant `14` days in the future. Every figure below is unknown
at filing time, which is the only property a pre-registration actually needs.*

---

## 1 · THE CRITERION

```
ANCHOR   the Captain's re-anchor of MIG-12, evening sitting 2026-08-23 — his word: "yes (b)"
         recorded verbatim at docs/QUEUE.md:186-191 and docs/ledger-tools/dated-debts.tsv:4
         "THE SLICE-B PRICE-CRITERION PRE-REGISTRATION, RE-ANCHORED (Captain, 2026-08-23
          evening sitting: 'yes (b)')"
         content-addressed: dated-debts.tsv at 0ba804d7e3df353b5ca272f52d50481b41451d3c
                            QUEUE.md         at c2368dfdd760cdf23fd8e5e55fad9666a8faefbb

FREEZE   THE INSTANT 2026-09-07T20:00:00Z PASSES.
         INSTRUMENT: `date -u +%Y-%m-%dT%H:%M:%SZ` compared against that literal, whose
         source value is recorded at docs/tinytapeout-dossier.md (shuttle API
         "deadline":"2026-09-07T20:00:00+00:00", corroborated by the homepage
         data-deadline markup), dossier content-addressed at
         251eb8654242dbeb5fcfc32bdabe6c82b6114df8
         ⬅ FIX 1: an EVENT TYPE (an instant passing) + ITS INSTRUMENT (a named command
            against a recorded literal), never a noun phrase.
            ⛔ REJECTED, and named so a successor sees what was refused:
              "the 2026-09-07 update window"        — a noun phrase; admits open/close/
                                                      extension/a sibling shuttle
              "the LW/SW silicon integration window" — undefined in this corpus (§0)
              "the first Slice-B piece to land"      — ALREADY FIRED. SaltWorks/HDL/
                                                      Executive.lean landed 2026-08-08
                                                      (c0d27a9), ExecutiveX0/X1/X2
                                                      2026-08-10, Certs/Executive.lean
                                                      2026-08-11 (ee2e004). A freeze whose
                                                      event is in the past is not a freeze.

WINDOW   [ANCHOR 2026-08-23 evening sitting  →  FREEZE 2026-09-07T20:00:00Z]
```
⛔ **WORK THAT LANDED BEFORE THE ANCHOR IS OUT OF SCOPE BY CONSTRUCTION AND CANNOT BE PRICED BY
THIS CRITERION.** *That is most of Slice-B's existing corpus, and saying so is the point: a
criterion written on 08-24 cannot honestly price work done on 08-08.* **Anyone wanting that
priced must say so and accept that it is a RETROSPECTIVE estimate, which is a different object
with a different error bar.**

## 2 · THE UNITS — fixed here, while every figure is unknown

| # | figure | **unit + counting rule** |
|---|---|---|
| a | Slice-B commits in window | one per commit whose diff touches a MANIFEST path (§3), on `refs/heads/master` **only**; **the manifest is enumerated and frozen BEFORE any commit is counted** |
| b | pieces added vs modified | **BOTH units, always, labelled** — `--diff-filter=A` alone misses `195 of 300` recent `SaltWorks/` commits (65%), so "added" and "modified" are reported as two numbers and never summed into one ⬅ FIX A |
| c | gate-count deltas | **REALIZED and SELECT-LOCAL only, never a system figure** — the design doc's own standing rule (`slice-b-design-v1.md:19-20`: *"Spend the −1,154 as REALIZED and SELECT-LOCAL, never as a system figure"*); a whole-core net **does not exist in the corpus** and may not be constructed by summation ⬅ FIX B |
| d | seat-passes on Slice-B | one per (seat × Slice-B assignment); **the denominator is enumerated FROM THE ASSIGNING ORDER before any discharge is counted** |
| e | refutations landed | fold commits carrying a defect, from **committed history** — the instrument is git, not a bus read |
| f | UNCLASSIFIED | anything the rules above do not decide. **Published as its own row, never absorbed** |

📌 **The column header says `unit + counting rule` and that is deliberate.** *The ③ criterion's
header said only "counting rule" and its figure drifted `3 → 4 → 7` in 38 minutes because three
different units were all being called "passes". A mirrored table that drops the word UNIT has
silently reverted the repair.*

## 3 · THE MANIFEST — because "a Slice-B piece" has no mechanical marker
**Measured: of `423` tracked files under `SaltWorks/`, exactly `6` contain the string
"Slice-B", and `6 of 7` of the named LW/SW RTL pieces contain it ZERO times.** *There is no
string, path, or naming convention that decides membership. So membership is EXTENSIONAL:*
```
⇒ THE MANIFEST IS THE DEFINITION OF SLICE-B FOR PRICING PURPOSES, AND IT IS FROZEN AT FILING.
  It is enumerated in §3a below, its sha256 recorded, and it does not change inside the window.
⛔ A Slice-B piece landing OUTSIDE the manifest is INVISIBLE TO THIS CRITERION BY CONSTRUCTION.
  That is the price of mechanicality and it is stated rather than discovered later.
⚠️ CONSEQUENCE, NAMED: a piece authored in a NEW file cannot be counted. If that happens the
  honest act is to report the miss and file a v2 — NEVER to widen the manifest mid-window,
  which would move the boundary to suit the figure.
```
### 3a · FROZEN MANIFEST
```
SaltWorks/HDL/Executive.lean          SaltWorks/HDL/ExecutiveX0.lean
SaltWorks/HDL/ExecutiveX1.lean        SaltWorks/HDL/ExecutiveX2.lean
SaltWorks/Certs/Executive.lean        SaltWorks/Silicon/RTL/slicea32.v
SaltWorks/Silicon/RTL/dmem8.v         SaltWorks/Silicon/RTL/dmem16.v
SaltWorks/Silicon/RTL/dmem32.v        SaltWorks/Silicon/RTL/dmem_addr16.v

MANIFEST-SHA256  c27abde9178fc0f3c6186da5cd48dcbefd0eb678a6539829c7ebdddae3bd62c1
  COMMAND (the freeze is the command, not just a value — R1 application ruling, 08-24):
    python3 -c "import hashlib;h=hashlib.sha256()
    [h.update(p.encode()+b'\n') for p in sorted(open('MANIFEST').read().split())];print(h.hexdigest())"
  i.e. sha256 over the SORTED path list, newline-terminated, paths only — not file contents.
  ⛔ If that command yields a different value at pricing time, THE MANIFEST MOVED and the
    window is VOID rather than adjusted. A digest without its algorithm is not a freeze:
    identical bytes give different correct answers under different framings.

ALL TEN PATHS VERIFIED AT FILING: exist=yes, tracked=yes, 10 of 10.
```
⚠️ **KNOWN GAP, DISCLOSED AT FILING: `ScratchRETIRE-busadapt8-irgated.v` is the LW/SW byte-phase
bus adapter, sits UNTRACKED at the repo root, and is NOT git-ignored.** *It is not in the
manifest because the manifest is tracked-only. Three further untracked root files sit beside
it. A criterion that counts only tracked paths cannot see them, and I would rather record that
here than have it found later.*

## 4 · ⛔ PRE-COMMITTED RULES — all five, fixed here and not later
1. **NO single "the Slice-B price was N" headline.** *Every figure carries unit + anchor +
   freeze inside the verdict.*
2. **UNCLASSIFIED is published, never absorbed** into whichever bucket tidies the story.
3. **PRE-ANCHOR WORK IS EXCLUDED BY CONSTRUCTION** (§1). *A criterion cannot price the past it
   was written after.*
4. **INSTRUMENT RULES, stated as method, each repairing a measured defect:**
   - **Ref scope is pinned to `refs/heads/master`.** ⛔ *Never `--all`, never `--reflog`:
     `refs/pre-flip/master` is a DISJOINT DAG in this object store with `480` `SaltWorks/`
     commits and no merge-base with master. A probe that traverses it can return a pre-purge
     commit as "the freeze".*
   - **Renames resolved with `-M`.** *`--no-renames` reports a pure rename as an ADD.
     `diff.renames` is UNSET in this repo and the global config, so the default is safe TODAY —
     which is exactly why it is pinned rather than assumed.*
   - **Every count confirmed on TWO ENGINES** (`/usr/bin/grep` or python `re`), per the
     2026-08-24 two-engine law. *The interactive `grep` on this box is a wrapper that
     disagrees with `/usr/bin/grep` on some patterns, token-specifically and unpredictably.*
   - **Publication confirmed at the remote by `git ls-remote`, never the tracking ref**
     ([[tracking-ref-is-a-local-cache]]). ⚠️ *`timeout`/`gtimeout` do NOT exist on this box —
     any invocation wrapping the network call in them fails with `command not found`.*
5. **AN EMPTY RESULT IS AN INSTRUMENT READING, NOT A FACT.** *Before recording "none", make the
   search return something known to be there.*

📌 ⬅ **FIX 5 — ANCHORS ARE CONTENT-ADDRESSED.** *Commit shas, resolvable at a remote, forever.
Bus line numbers may accompany them as a convenience but are NEVER the citation: `FLEET.md` is
in no git repo and has no remote.*

⚖️ **THE WINDOW IS FROZEN SEPARATELY FROM THE CLASSIFICATION — kept deliberately.** *The
classification can be done whenever, or never, and it cannot move the boundary. **Freezing a
window is not the same act as pricing it.*** *That is the one clause of the ③ criterion that
needed no repair, and it is what let ③'s figures be corrected five times with zero suspicion
that the boundary had been moved to suit them.*

## 5 · ⚠️ WHAT THIS FILING DOES NOT DO
- **It does not price anything.** *No figure is computed here and none is owed.*
- **It does not discharge the fence retroactively.** *Slice-B pricing claims made BEFORE this
  filing carried no fence and still carry none; this criterion fences claims made about the
  WINDOW, from here forward.*
- ⛔ **Its own ledger check is EXISTENCE-ONLY.** *`dated-debts.tsv:4` registers
  `test -f docs/EVIDENCE-sliceb-price-prereg.md`, which `touch` satisfies. **Ask the standing
  question: if the filed pre-registration were the WRONG one, what would stop? Nothing
  would.*** *Disclosed by the author, at filing, rather than left for a reader to find —
  strengthening that check is a real open item and it is not mine to do unilaterally.*

**STATE AT FILING** — captured in ONE invocation, per [[one-clock-per-post]] applied to git:
```
UTC        2026-08-24T22:38:03Z
AS OBSERVED AT FILING (pre-purge shas — these are what the commands RETURNED):
  HEAD                       82ed230d54186f75232472771b873a00351253c8
  origin/master (ls-remote)  69f2ed846131cc0cc35088b6c75fc050a97c26e8
POST-PURGE EQUIVALENTS (same trees; via seat/fleet/purge-shamap-2026-08-24.tsv):
  HEAD                       6e66afe921367602abeaa0c6e5ec6f53fc3d1945
  origin/master              8512bd3dc3bb0fc81030e71c77cdd2fca12c246c
```
⛔⛔ **RESTORED 2026-08-24 18:5x BY THE AUTHOR. The 08-24 purge sweep REWROTE THIS BLOCK
in place, replacing the observed shas with their post-purge equivalents.** *The translation
was correct; applying it HERE was not.*
🔑 ***A CITATION AND A RECORD OF AN OBSERVATION ARE DIFFERENT OBJECTS AND LOOK IDENTICAL —
BOTH ARE 40 HEX CHARACTERS IN A DOCUMENT.***
```
§1 ANCHOR shas          CITATIONS  -> SHOULD follow their content. Sweep CORRECT. Kept.
"STATE AT FILING" shas  OBSERVATION -> MUST NOT change: rewriting them makes this document
                                       assert a repository state THAT DID NOT EXIST when it
                                       was written. 6e66afe9 had not been created yet.
```
⚠️ **This block was captured in ONE invocation on purpose, so it would be a faithful record of
a single instant. Re-pointing it destroyed exactly the property it was built to have.** *Both
forms are now carried: what was observed, and what it maps to.*

---

## 6 · 📌 POST-FILING NOTE — 2026-08-24 15:4x.
⚠️ **THIS HEADING ORIGINALLY READ "NOTHING ABOVE THIS LINE HAS BEEN CHANGED." THAT WENT FALSE
AT 18:4x AND IS CORRECTED HERE RATHER THAN LEFT STANDING** — the purge sweep re-pointed four
shas above it (two ANCHOR citations, correctly; two STATE-AT-FILING observations, incorrectly,
now restored — see §5's restored block). **The criterion, the window, the manifest, its digest
and the freeze instant were NOT touched by the sweep or by me.**

**The helm confirmed §0's labelled inference from the sitting record** (bus, maestro
2026-08-24 15:42:15): *the 08/24 council re-anchor (Captain's word, option b) meant the
**TAPE-OUT SUBMISSION CUTOFF** — the Sept-7 TinyTapeout shuttle deadline — and filing before
that cutoff is exactly the ruling's intent; the close-of-window reading `2026-09-07T20:00:00Z`
executes it.* **The impossible "before it opens" phrasing was ruled a defect of the ROW.**

⇒ **§0's caveat — *"the identification is mine, not the document's"* — was TRUE WHEN WRITTEN
and is now CORROBORATED BY A SECOND PARTY WITH ACCESS TO THE SITTING RECORD.** *It stands
unedited above, because what it said about the state of the evidence at filing time remains
exactly right.*

⛔⛔ **WHY THIS IS AN APPENDED NOTE AND NOT AN EDIT, AND IT IS THE WHOLE POINT OF THE FORM:**
***A PRE-REGISTRATION THAT IS REWRITTEN AFTER FILING IS WORTH LESS THAN ONE THAT IS NOT.***
**The criterion, the window, the manifest and its digest are untouched — no clause moved, no
boundary moved, and the freeze instant is the same instant.** *Confirmation arriving later is
new information about the world, not a licence to revise the record of what was known when the
criterion was fixed.* **This document's own §1 says the repair for a wrong anchor is a NEW
FILING rather than an edit; the anchor was not wrong, so neither was needed.**

📌 **ROW REPAIRED SEPARATELY, per the helm's order:** `docs/QUEUE.md` and
`docs/ledger-tools/dated-debts.tsv` now carry the executable anchor — *"the TT shuttle
submission cutoff `2026-09-07T20:00:00Z`"* — in place of the noun phrase, **so the next reader
inherits an instant with an instrument instead of a phrase needing interpretation.** *The
superseded text is marked as superseded in the row rather than deleted.*
