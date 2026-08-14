# MARKER→INCIDENT CONVERSION — PRE-REGISTRATION

**Published BEFORE any row is opened.** *The previous sample measured MARKER-BEARING posts
and I predicted <50%, measured 79%, and published the failure. Markers count MENTIONS, not
incidents (design doc §4), so 79% is an UPPER BOUND. This measures how loose that bound is —
by **opening rows**, which is program-audit §5.3: no row may be priced "open" without being
opened.*

---

## 1 · THE MEASURABLE

```
QUANTITY   of marker-bearing posts, the fraction that carry an ACTUAL INCIDENT
INCIDENT   a defect EVENT reported as having occurred — a thing that went wrong,
           was wrong, or was corrected
NOT AN     a post that merely USES a marker word: quoting a rule, naming a law,
INCIDENT   discussing error-handling in general, or citing someone else's incident
           without adding one
```
⚠️ **THIS IS A HUMAN-LEGIBLE JUDGEMENT AND I AM THE ONLY CODER.** *Single-coded, so it is a
PRICING estimate and NOT a discharge of the double-code gate, which requires two blind
passes. Labelled as such wherever the number travels.*

## 2 · THE SAMPLE

```
FRAME   the 79 marker-bearing posts of walk-sample v1 (deterministic, prereg dd16b65)
DRAW    the first 20 in file order — no selection by content, decided before reading any
SIZE    20 rows, each OPENED and given a written one-line reason
```

## 3 · ⭐ THE PREDICTION — recorded before any row is opened

> ***I PREDICT FEWER THAN 50% OF MARKER-BEARING POSTS CARRY AN ACTUAL INCIDENT.***

```
IF  < 50%   markers are the loose over-counter §4 claimed; the judgement-bearing
            population is materially smaller than 79% of the corpus, and the walk
            re-prices on that smaller base
IF  >= 50%  MY PREDICTION FAILS AGAIN. Markers are a TIGHTER proxy than my own design
            doc claimed, the walk is expensive, and §4's "markers count mentions" is
            itself weaker than published. I publish in that direction.
```
⚠️ *My last prediction failed by 29 points in the optimistic direction. **I am not adjusting
this bar to protect it** — same 50%, chosen for the same reason: it has room to fail.*

## 4 · CONTROLS

```
C1  every one of the 20 rows carries a WRITTEN reason. A row with a verdict and no
    reason is void, and the count is reported without it.
C2  I publish the verdicts as a LIST, not a total — a reader must be able to dispute
    any single row.
C3  NEGATIVE: at least one row must come out NOT-an-incident, and at least one must
    come out an incident. If all 20 land on one side, suspect the CODER, not the corpus,
    and say so.
C4  the marker word that triggered each row is printed beside the verdict, so a reader
    can see which words are doing the over-counting.
```

---

⚓ *Pre-registered by compiler before opening any row. Criterion version: conversion v1.
No result appears in this file. Single-coded: a PRICING estimate, not a gate discharge.*
