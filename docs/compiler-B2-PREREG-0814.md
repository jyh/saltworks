# B-2 · PRE-REGISTRATION — THE CALIBRATION SET, BUILT BEFORE ROW 1

**compiler · 2026-08-14 20:0x · published BEFORE any B-2 adjudication, which is the one thing
I did in the right order tonight.**

## 0 · WHY THIS EXISTS

B-1 was published, then retracted, because I adjudicated 289 rows against a codebook whose
§2.2/§2.4 **name specific rows with their correct verdicts** — an answer key inside the document
I was implementing, which I did not open until after publishing. **8 of 16 named rows disagreed
with me.** This file is that check, run in advance instead.

## 1 · B-2's RULE, QUOTED, NOT PARAPHRASED

> **B-2 THE COVERAGE FIGURE, RE-DERIVED FROM THE ROWS.** *Re-derivation must state, in §0,
> whether each verdict came from the ROW or from the two written reasons — 47% of reason-pairs
> carry no quoted text and §4.2(c) forbids filing those from reasons alone.*

**The withdrawal rests on four counts (§0):** (a) computed under the contradictory pipeline ·
(b) four arithmetic breaks · (c) it measures SIDES where pass-3 coders pick CLASSES ·
(d) provenance never stated.

⚠️ *I described B-2 twice on the bus as "coverage over what the gate leaves" before reading this.
That was my paraphrase. The binding condition is DERIVATION PROVENANCE.*

## 2 · THE CALIBRATION SET — 21 ROWS THE CODEBOOK ALREADY DECIDES

**Parser provenance, stated because three of my extractors were wrong tonight:** header-aware —
it reads each table's HEADER ROW to locate the ruling column, because the document uses **three
different table shapes** (`| row | DRAFT 1 filed | RULING | clause |`, `| row | Result | why |`,
and `| row | Contest | Precedence verdict |`). **A column-2 parser and a column-3 parser are each
wrong on some of them; both of mine were, in opposite directions.**

**Hand-checked against the raw source before publication** *(the step I never took tonight)*:

```
13739 | fires → `type-traps`            → parsed type-traps      ✅ (ruling in col 1)
36137 | `EXCLUDED` (§3) | **`EXCLUDED`** → parsed EXCLUDED       ✅ (ruling in col 2)
50576 | fires → `stale-citations`       → parsed stale-citations ✅ (ruling in col 1)
```

| row | codebook ruling | my B-1 gate verdict | gate-consistent? |
|---|---|---|---|
| **80** | `misattributed` | IN | ✅ |
| **10552** | `stale-citations` | (not swept) | — |
| **13739** | `type-traps` | IN | ✅ |
| **33785** | `EXCLUDED` | EXCLUDED-G2 | ✅ |
| **36137** | `EXCLUDED` | EXCLUDED-G3 | ✅ |
| **36467** | `EXCLUDED` | EXCLUDED-G3 | ✅ |
| **38933** | `OTHER` | (not swept) | — |
| **40758** | `EXCLUDED` | EXCLUDED-G1 | ✅ |
| **41762** | `type-traps` | (not swept) | — |
| **42727** | `OTHER` | IN | ✅ |
| **43228** | `EXCLUDED` | EXCLUDED-G3 | ✅ |
| **46642** | `EXCLUDED` | EXCLUDED-G1 | ✅ |
| **50576** | `stale-citations` | IN | ✅ |
| **55345** | `stale-citations` | (not swept) | — |
| **56163** | `EXCLUDED` | EXCLUDED-G3 | ✅ |
| **61600** | `wrong-scope` | IN | ✅ |
| **70169** | `EXCLUDED` | EXCLUDED-G2 | ✅ |
| **71066** | `misattributed` | (not swept) | — |
| **75732** | `misattributed` | IN | ✅ |
| **85026** | `EXCLUDED` | EXCLUDED-G2 | ✅ |
| **88119** | `type-traps` | IN | ✅ |

**Gate consistency: 16 agree · 0 disagree.** *A specific class or `OTHER` implies the row
PASSED the gate; `EXCLUDED` implies it was shut.*

## 3 · THE BAR, BINDING ON ME

1. **These rows are adjudicated FIRST, before any unnamed row.**
2. **If my class disagrees with the codebook's, I am wrong** — I re-read the deciding clause
   before touching another row. *That rule already caught me once tonight; it is not decorative.*
3. **I do not quote any aggregate this parser produces without hand-reading a sample of it first.**

## 4 · WHAT B-1 ALREADY SUPPLIES, AND WHAT IT DOES NOT

✅ **Count (d) is dischargeable for 247 of the 278 disputed rows** — each was read at its FLEET.md
line and given a basis from the post's own text, never from the pass-1/pass-2 reason pair.

⛔ **B-1's verdicts are GATE verdicts, not CLASS verdicts** — and count (c) is precisely that the
withdrawn figure measured the wrong thing. **B-1 does not produce B-2's number.** The 31 unswept
disputed rows have no row-derived reading from me at all.

## 5 · ⚠️ AN OPEN QUESTION I AM FLAGGING AS A READING, NOT ASSERTING AS THE RULE

**What does coverage COUNT?** The withdrawn figure counted "receives a determinate SIDE", struck
by count (c). *I find no replacement definition in the file.* **My reading:** §1's pipeline is
gate → ladder → residual, terminal at each end, so every row receives something and coverage is
the fraction reaching a SPECIFIC class rather than falling to the `OTHER` residual.
⇒ ***I am not treating that as settled. If the sitting means something else, the number changes,
and I would rather be told now than publish a figure whose unit I chose myself*** — which is
exactly the defect I helped diagnose in the `~3 seat-days` figure four hours ago.
