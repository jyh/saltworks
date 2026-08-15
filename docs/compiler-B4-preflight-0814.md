# B-4 · PREFLIGHT — THREE THINGS MEASURED BEFORE THE RUN, NOT AFTER

**compiler · 2026-08-14 20:4x · B-4 is BLOCKING and its output must be PRINTED BESIDE any
coverage figure (`:503-515`, `§6 B-4`). This file is what I found checking its premises first.**

## 1 · ✅ THE AGREEMENT SET REPRODUCES EXACTLY

Derived independently from `PASS1-compiler.json` and `PASS2-coder2.json`:
```
pass1 coded 388 · pass2 coded 388 · AGREEMENTS 110   ✅ COMPARE-0813 says 110
agreed classes:  OTHER 42 · wrong-scope 52 · stale-citations 10 · misattributed 6
```

## 2 · ⚠️ THE AGREED-`OTHER` SET IS **42**, NOT 110 — AND B-4's WORDING IS AMBIGUOUS

> *"Run this pipeline over all **110** and PRINT the **agreed-`OTHER`** survival rate."*

**Only an `OTHER` row can SURVIVE as `OTHER`, and only 42 of the 110 are `OTHER`.** *The
refuter's own cited sample — two 10-row draws scored `3/3/4` and `5/1/4`, i.e. survive /
to-specifics / to-`EXCLUDED` — only makes sense over the `OTHER` subset.*

⇒ ***I AM NOT RESOLVING THIS BY CHOOSING.*** **Two readings, and the denominator of the headline
figure differs by 2.6×:**
```
READING A   run over all 110; "survival" = stays in the class both coders gave it
            ⇒ denominator 110, and the figure is agreement-stability, not OTHER-survival
READING B   run over the 42 agreed-`OTHER`; "survival" = still `OTHER` after the gate
            ⇒ denominator 42, and it matches the refuter's 3/3/4 shape exactly
```
📌 **I read B as intended — it fits the cited sample — but the phrase says 110, so the sitting
should say which, because the published number changes by more than a factor of two.**

## 3 · ⛔ THE "FREE HELD-OUT SET" PREMISE HAS DECAYED, MEASURED

> *"110 agreements exist as a free held-out set and were never used: **not one of them appears
> anywhere in DRAFT 1**."*

**True of DRAFT 1. Tested against DRAFT 2/3 — the file that now governs:**
```
all 110 agreed .......... mentioned in the codebook  20/110
the 42 agreed-`OTHER` ... mentioned                  20/42   = 48%
                          class-disclosed (±220)     20/42   = 48%
```
⇒ ***NEARLY HALF OF THE SET B-4 CALLS HELD-OUT IS NAMED, WITH A CLASS, IN THE CURRENT DRAFT.***
*The property was true when written and is not true now — the later drafts spent it. **Running
B-4 over all 42 and reporting the result as a held-out survival rate would publish a
contaminated figure**, and the contamination is 48%, not a rounding error.*

## 4 · WHAT I PROPOSE, AND WHAT I WILL NOT DO UNASKED

```
CAN RUN NOW    the 22 agreed-`OTHER` rows NOT named in the codebook — a genuinely
               held-out remainder, reported as n=22 with that limit stated
CAN RUN NOW    all 42, reported as TWO figures: the 22 clean and the 20 disclosed,
               never pooled into one "survival rate"
WILL NOT DO    pool them and print one number. That is the figure B-4 exists to prevent.
WILL NOT DO    choose between reading A and reading B on my own authority (§2)
```
⚠️ **AND THE TWO DRAFT-3 CONDITIONS ARE NOTED AND WILL BE HONOURED WHEN THE RUN HAPPENS:**
*(1) re-score AFTER R-A and R-B — both have landed; (2) **print the CONTESTED count beside the
verdict count**, because "a survival figure that hides its coin-flips" is exactly what that
clause exists to stop.*
