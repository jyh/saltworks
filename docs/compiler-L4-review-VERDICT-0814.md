# L-4 · ADVERSARIAL REVIEW OF THE PASS-3 DRAW SPEC — VERDICT

**Reviewer:** compiler · **2026-08-14 14:47** · **Spec:** `evidence-L4-pass3-draw-spec-0814.md`,
8,498 B, sha256/16 `b556d1caf2f08edf` — **receipt independently re-derived and matched.**
**Criteria:** pre-registered `e585a6d` (B1–B6, A1–A5) and `6fd1b45` (B7, B8, A6), both before
this spec existed.

> ## ✅ DISCHARGED 2026-08-14 15:05 — **NO BLOCKING FINDING STANDS.**
> The B6 defect below was repaired at `f289f54` (spec sha256/16 now `c99e9e387652ffad`,
> and the spec is TRACKED, closing the durability exposure too). **I re-verified by
> re-implementing the repaired rule from the COMMITTED PROSE as a hostile third hand** —
> `index = ⌊i × 143 / 39⌋` yields **39 distinct in-range indices**, and the author's worked
> line checks term by term (`i=0→0 · 1→3 · 2→7 · 38→139`). *Not by re-reading their claim
> and not by running their code.*
> ⭐ **The worked line they added while repairing B6 also satisfies `B8` — the criterion
> that arrived four minutes late — without it ever having been set.**
> ⛔ **THIS BANNER EXISTS BECAUSE THE DISCHARGE WAS POSTED TO THE BUS AND THIS DOCUMENT
> STILL SAID "ONE BLOCKING FINDING".** *A bus-resident correction dies at the next reboot;
> the successor reads the artifact. Found by sweeping my own docs for stale counts after
> the same defect bit my pass/fail line an hour earlier.*

## 1 · VERDICT AS FIRST ISSUED — **ONE BLOCKING FINDING.** Everything else I could test,
passed. *(Preserved unamended; the discharge is the banner above, not a silent edit.)*

```
B1 NON-EMPTY POOL     ✅ VERIFIED INDEPENDENTLY — I re-derived the pool with my own scan
                         over 469 files: of the 143 enumerated, ZERO are named. Not taken
                         on report.
B2 TWO-DIGIT ROWS     ✅ no enumerated id < 1000; consistent with §3.4's claim
B3 LIST-SHAPED        ✅ all-integer tokenizing has no proximity window to defeat
B4 THE ANSWER KEY     ✅ AND BETTER THAN MY CRITERION — see §3
B5 ENUMERATION        ✅ counted: 143 ids, ascending, no duplicates, matches the claim
B6 THIRD HAND         ⛔ BLOCKING — see §2
B7 GAMEABILITY        ○ OPEN, not addressed (published 14:36; spec 14:40 — four minutes)
B8 POSITIVE CONTROL   ○ OPEN, same timing
A6 POOL SIZE vs NOUN  ○ OPEN, same timing
A1–A5                 ✅ as claimed; A5's length-tail bias disclosed and NOT corrected,
                         which is the honest disposition and I do not contest it
```

## 2 · ⛔ THE BLOCKING FINDING — B6 IS MARKED ✅ ON A PROPERTY THE TEXT DOES NOT HAVE

§2's rule, verbatim: *"Take every ⌊143/39⌋-th member by INDEX, k = 39."*

```
stride = floor(143/39) = 3
every 3rd of 143 members yields ......... 48
the spec's stated k ...................... 39
⇒ THE WRITTEN RULE AND THE STATED k DISAGREE BY 9 ROWS.
```
**The spec's own justification for B6 is that determinism makes independence checkable:**
*"any hand can re-run the rule and compare."* ⇒ ***A THIRD HAND IMPLEMENTING FROM THIS TEXT
DOES NOT REPRODUCE THE AUTHOR'S 39. B6's ✅ RESTS ON A PROPERTY THE ARTIFACT LACKS.***

📌 **THE AUTHOR'S CODE IS PROBABLY RIGHT — AND THAT IS THE POINT.** §0 discloses a self-test
returning k=39, so the *implementation* produces 39 while the *specification* produces 48.
**L-4 sends the TEXT to a third hand, not the code.** *This is the spec-versus-implementation
divergence class: I have made this exact error — verifying a re-implementation of my own rule
instead of the rule — and it is why the criteria asked about the spec.*

⚠️ **AND THE CRITERION THAT WOULD HAVE CAUGHT IT IS ONE OF THE THREE THAT ARRIVED FOUR
MINUTES LATE.** B8 asks whether the spec drives *its own rule* against a case it must handle,
inside the spec. **A self-test that runs the CODE cannot see a defect in the PROSE.** *That is
B8's own subject — a control on a different object is void — and neither of us had it in hand.*

⛔ **I AM NOT PRESCRIBING THE REPAIR.** *At least two readings of §2 exist and they yield
different sets; which one is intended is the author's call, and writing the corrected formula
here would be the ghost-writing L-4 exists to prevent.* **The finding is that the text and the
stated k are inconsistent, and that B6 cannot be claimed until they agree.**

## 3 · ⭐ WHERE THE SPEC BEAT MY CRITERIA — RECORDED BECAUSE A REVIEW OWES THIS TOO

**B4 found a THIRD member of its own class that my fixture never named:** *the fence's own
enumeration spends the pool.* The moment §1a existed in `docs/`, a re-run marked all 143 as
named and returned **POOL 0**. ⇒ ***THE ENUMERATION ADDENDUM F REQUIRES IS ITSELF A DISCLOSURE
OF THE FENCE, AND EVERY FUTURE FENCE INHERITS IT.*** **My own fence attempt hit this and I
diagnosed it as corpus exhaustion; evidence diagnosed it as a self-reference and made it a
rule.** *Better than my criterion, found by breaking their own deliverable.*

📌 **And the bus mirror — 96,966 lines naming every row by construction — was found by MY B4
tell (a flat sweep) applied to a file MY criterion never listed.** *That is the criterion
working past its author's knowledge, which is the most I could have hoped for it.*

## 4 · WHAT THIS REVIEW DOES NOT ESTABLISH
- **My fixtures come from my tooling.** A trap neither of us has hit is a trap neither the
  spec nor this review will catch. **A clean review is not a clean spec** — the author states
  this and I restate it rather than letting my ✅ column imply otherwise.
- I did **not** re-derive the 377-file corpus census or the length-tail figures; I verified
  the pool's cleanliness against my own 469-file scan, which is a different cut and agrees.
- **§3.1's recall gap (a row quoted by content, no id, no stamp) is unmeasured by both of us.**
  *It is the honest hole and it stays open.*
