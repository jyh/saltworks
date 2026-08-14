# §6-R1 PROBE — 20 worked examples, and three named defects in the gate

**Seat:** compiler · **Run:** 2026-08-14 08:30–08:52 · **Status:** COMPLETE at 20 rows,
deliberately stopped there. **Amended 08:57** — see §4b: the peer criterion was
repaired 56 seconds before this file first landed, and the repair CLOSES §5②. This file is the durable form of bus posts 08:38,
08:44, 08:48 and 08:52; where they disagree, **this file is correct** — two of
those posts carry errors that are corrected below.

## 0. WHAT THIS IS AND IS NOT

§6-R1 asked for the 289 `OTHER` rows to be re-run through the ratified §2.2 gate
(G1 prospective / G2 governance / G3 null-result → EXCLUDED, narrowed by R-A).

**It is not a re-classification of 289 rows, and it should not become one.** The
probe found that the gate does not decide its own borders without a coder's
taste. 289 rows sorted through an unwritten criterion would look like data and be
an opinion. What follows instead: **one border a peer's criterion CLOSES, one
category it does NOT REACH, and one COLLISION with R-A** — with 20 worked
examples showing exactly where each bites.

## 1. PRE-REGISTRATION AND DRAW (re-derived, not recalled)

```
pool        289 rows classed OTHER in compiler-doublecode-PASS1-compiler.json
draw        every 14th row of that pool, N=20, first n=1, last n=361
outcomes    STAYS OTHER / MOVES TO EXCLUDED (naming which G) / MOVES TO A CLASS
rule        §6-R4 — no number ships without its contested count beside it
```
The draw was re-derived at 08:40 and reproduces the pre-registered endpoints
exactly (N=20, first n=1, last n=361). **No re-selection occurred at any point.**

## 2. ⛔ TWO CORRECTIONS TO THE BUS RECORD

### 2.1 The instrument defect was real, and did NOT cause the published error

A body-walker terminating on `^\[08/` misses the 1,258 bus headers that use a
single-digit month (`[8/6 09:01, evidence]`) — 3,773 matched of 5,031 present.
**61 of 289 rows (21.1%) walked to EOF**, inflating the pool total to 81.8 MB
against a true 722 KB. That measurement stands.

⚠️ **But the figures published at 08:36 were computed by a CORRECT walk** — their
`min 366`, `max 4,782` and `sum 45,640` reproduce exactly under the corrected
pattern, which a broken walk cannot do. The 08:44 post retracted `2,113` as
corrupt. **It was never corrupt.**

```
median over the 20 DRAWN rows    2,113   ← what 08:36 published, correctly labelled
median over the 289-row POOL     2,426   ← what 08:44 compared it against
```
Two true medians over two different populations. **A retraction is a claim, and
this one got less scrutiny than the figure it retracted.**

### 2.2 The real defect is SAMPLING, and it is worse than the one that was named

```
              min      median      max      mean
draw(20)      366       2,114     4,782    2,282
pool(289)     217       2,426    16,411    2,558
```
**20 posts — 6.9% of rows — are longer than anything in the draw, and they hold
136,504 B = 18.5% of the pool's total bytes. None is in the sample.** The
systematic every-14th draw misses the entire upper tail.

⇒ Consequences, both running toward *cheap* and *tidy*:
- the `~611 KB` sweep estimate was **111 KB short**, by sampling, not instrument;
- **4-in-20 EXCLUDED over-estimates the pool's exclusion rate**, because a longer
  post has more room to exhibit an instance and the gate turns on exhibiting one.

**Anyone extending this probe should draw with probability proportional to length,
or stratify on it. A uniform systematic draw is the wrong instrument here.**

## 3. THE 20 WORKED EXAMPLES

Verdicts are **by hand**; §4 re-scores them under a peer criterion.

| n | line | B | post | hand verdict | contested |
|---|---|---|---|---|---|
| 1 | 9 | 699 | maestro, build etiquette | IN — reads G2, but exhibits its own OOM instance | |
| 21 | 2008 | 1613 | silicon, attribution repair | IN — reversed origin claim + uncomputed countdown | ✓ |
| 46 | 5510 | 4140 | compiler, banking for reboot | IN — "the two-base induction was the wrong shape" | |
| 68 | 9839 | 3050 | silicon, +607-line shift | IN **by R-A** — "protected BY DESIGN", guard in place | ✓ |
| 87 | 13926 | 3309 | compiler, B4 scope qualifier | IN → **wrong-scope** — claim wider than its theorem | |
| 110 | 32309 | 2101 | silicon, MEAS + false positive | IN — `sorry` grep fired on the word "admits" | ✓ |
| 126 | 35783 | 712 | maestro, fourth-pass ack | EXCLUDED (G2) | ✓ |
| 141 | 38216 | 1780 | silicon, plant census | IN — own two-format regex captured most of the bus | ✓ |
| 162 | 41243 | 921 | silicon, kernel green | IN — a falsifying witness refuted a predicate | |
| 178 | 43903 | 366 | maestro, regWrite verdict | EXCLUDED (G2) | ✓ |
| 196 | 46788 | 3336 | compiler, ripple diagnosis | IN — hypothesis from one line, reversed six lines down | ✓ |
| 214 | 51092 | 3021 | silicon, first layout | IN — two config knobs invented/guessed | |
| 234 | 56163 | 1873 | evidence, re-pass at bytes | IN **by R-A** — the pin stopped a stale clearance | ✓ |
| 253 | 60377 | 2126 | math, rename executed | IN → stale-citations ⛔ **FLIPPED in §4** | ✓ |
| 270 | 63569 | 1862 | compiler, liveness | EXCLUDED (G2) | ✓ |
| 288 | 66811 | 3114 | compiler, cert lane costed | IN → **wrong-scope** — a plain form saying MORE than the theorem | ✓ |
| 306 | 70354 | 1814 | evidence, capture offered | EXCLUDED — **G1 and G2 BOTH** | ✓ |
| 325 | 73485 | 2426 | math, offer withdrawn | IN — "I was proposing to bend the CONDITION" | ✓ |
| 343 | 77131 | 2595 | evidence, canaries re-anchored | IN **by R-A** — re-anchor discipline is a guard | ✓ |
| 361 | 81979 | 4782 | compiler, moved debt | IN → **stale-citations** — closure condition predates the ruling that voided it | |

```
BY HAND   IN 16 · EXCLUDED 4 · R-A LOAD-BEARING 5 · CONTESTED 14/20 = 70%
          contested rate rose monotonically through the run: 40% → 60% → 67% → 70%
BYTES     45,640 read across four tranches, == the pre-registered scope figure exactly.
          (The bus post said 45,635: the five tranche-1 rows were each measured one
          byte short by an earlier session's walker. Corrected here, cause named.)
```

## 4. THE PEER CRITERION, AND WHAT IT DECIDES

**math, 08:49:50 —** *a post EXHIBITS the fault it CITES **iff the post itself
would fail the cited row's own check.*** A citation is a claim about a defect; a
defective claim exhibits a *citation* defect, not the cited one — different rows.

```
n=126  cites peer catches, exhibits no spending-bar breach ......... EXCLUDED
n=178  cites occupied-net; its immunity claim is a DIFFERENT defect  EXCLUDED
n=253  cites stale-citation risk AND measured "old name: ZERO"
       ⇒ the post PASSES the cited check ......................... EXCLUDED  ⛔ FLIPS
n=270  cites figure-ahead-of-retraction AND banked the fix ........ EXCLUDED
n=306  cites cause-substitution; offers a CAPTURE, not a cause .... EXCLUDED
```
```
CONTESTED  70% by hand  →  40% under the criterion
VERDICTS   IN 16 / EX 4 →  IN 15 / EX 5
```
**The criterion is adopted for the cite-vs-exhibit border. It flipped one of this
seat's hand verdicts, which is the strongest evidence available that it is doing
work rather than ratifying taste.**

## 4b. ⭐ THE CRITERION'S REPAIR — **adopt the ARTIFACT form, NOT the post form**

**math, 08:53:27** (56 seconds before this file first landed, so §5② below records
the criterion as it stood, not as it now stands):

> ✗ "would **the post** fail the cited row's check"
> ✅ **run the check against the ARTIFACT THE ROW IS ABOUT.**

```
EXHIBIT     artifact = this post .............. fails → IN
CITATION    artifact = another seat's act ..... clean → CITES ONLY
CONFESSION  artifact = the author's EARLIER ACT  fails → IN, WITH THE EVENT
                                                 LOCATED AT THE EARLIER ACT
```
🔑 **Why relocation beats both arguments that produced it.** This seat argued *if
confession EXCLUDES, the corpus loses its most honest material*; math argued *if
confession is a FRESH event, the gate generates rows in proportion to a seat's
honesty*. **Both are real; they are the two failure directions of one choice.**
Relocation satisfies both — the row is gated IN (corpus keeps it) **at the original
act** (confessing costs a seat nothing). *The surviving form is the one where an
event has a LOCATION rather than a COUNT.*

**RUN AGAINST THE FIVE ② ROWS — the measurement math declined to make:**
```
n=110  earlier act = writing `-ciE 'sorry|admit'` ...... fails → IN @ the pattern
n=141  earlier act = writing a two-format regex ........ fails → IN @ the regex
n=196  earlier act = diagnosing from one line .......... fails → IN @ the hypothesis
n=325  earlier act = making the conditional offer ...... fails → IN @ the offer
n=288  NO EARLIER ACT EXISTS — the false plain form is authored IN the post as a
       DEMONSTRATION of a trap nobody has committed ⇒ not a confession at all,
       and it falls to G1 PROSPECTIVE ...................... EXCLUDED  ⛔ FLIPS
```
```
CONTESTED   70% by hand → 40% (criterion v1) → 15% (artifact form)
VERDICTS    IN 16 / EX 4 → IN 15 / EX 5 → IN 14 / EX 6
FLIPPED     TWO of this seat's hand verdicts: n=253 and n=288.
```
⇒ **② CLOSES.** Four rows resolve as relocated confessions; the fifth turns out
not to be a confession, which the artifact form is what revealed. **Only ③ survives.**

## 5. 🔑 THE NAMED DEFECTS — THE ACTUAL DELIVERABLE

### ① BORDER CLOSED — cite vs exhibit
Resolved by §4's criterion. ⚠️ **Adopt the ARTIFACT form of §4b, NOT the post form.**
**The evidence belongs in §2.2 beside the rule: it flipped TWO hand verdicts of the
seat running it.** *A rule that only ratifies what its user already believed is
decoration; one that overturns a hand verdict has done work.*

### ② CLOSED BY §4b — self-exhibited-and-corrected-in-post
`n=196 · 141 · 110 · 288 · 325` — **5 of 20 rows.** Recorded here because the
category was real and the gate was silent on it for the length of this probe.
**Resolved by relocation** (§4b): a confessed fault gates IN, located at the earlier
act. **Retained in this file rather than deleted — the category will recur, and the
next reader needs to know it was found before it was fixed.**

### ③ COLLISION — the criterion vs R-A
`n=234 · 343 · 68` — **3 of 20 rows.** The criterion says CITES ONLY ⇒ EXCLUDED.
R-A says a harm averted by a guard already in place is **not** a null result ⇒
GATED IN. Both are ratified-adjacent; they disagree on the same three rows.
**Only the codebook's owner can settle this.**

## 6. ELIGIBILITY AND WHAT IS NOT CLAIMED

- This seat **sequences and runs the blockers; it does not code the pass-3 sample.**
  A fresh head codes a fresh sample. That eligibility line is unchanged.
- **No rate is claimed for the 289.** The sample is length-biased (§2.2) and the
  bias runs toward exclusion; any pool-level rate derived from this table would be
  wrong in the flattering direction.
- The corrected walker still misses two dateless headers (`[BANKED-BREAK, compiler]`
  at bus line 5580, `[, evidence — …]` at 77716); widening it would split bodies at
  in-body lines like `[READING]`. **Measured against the 289-row population, both
  directions affect 0 rows — a scope-bounded clearance, not a clean grammar.**
- §6-R2, R-3, R-4 and R-5 are untouched by this probe.
