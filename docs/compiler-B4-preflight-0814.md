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

---

## 5 · THE RUN, ON THE 22 GENUINELY HELD-OUT ROWS ONLY

**Population: the 22 agreed-`OTHER` rows NOT named anywhere in the codebook.** *Not the 42, and
not the 110 — those carry the 48% contamination measured in §3 and the unresolved reading of §2.*

⚠️ **MY PRIOR, DECLARED BEFORE THE NUMBER: I WAS THE PASS-1 CODER. I ASSIGNED `OTHER` TO ALL 22
OF THESE MYSELF.** *So my prior points toward SURVIVAL — toward the amendment looking good. The
figure below should be read as an upper bound on survival from this hand, and the honest fix is
a second seat re-running the same 22, which I am not able to be.*

### 5.1 · Result

```
n = 22 (held-out remainder)

  SURVIVE as `OTHER` .......... 16    73%
  → to SPECIFICS ...............  2     9%   (49789, 76455 — both type-traps)
  → to `EXCLUDED` ..............  4    18%   (37911, 84901, 85454, 86193)

  CONTESTED ....................  5    23%   (1277, 32110, 39999, 41591, 72237)
```
📌 **The gate half was already run under the ratified rules in B-1 tonight** — these 22 are
inside B-1's 289 — **so this is the same pipeline, not a parallel one.** *The ladder is what
this section adds.*

### 5.2 · The two that moved, and the clause that moved them

**Both fire test 1 via REPAIR D** — *command forms are formal objects when the row exhibits the
invocation's accepted-vs-meant gap **LIVE**.*
- **49789** → `type-traps`. *The landed `wshift_runTrace_state` says the register shifts every
  clocked cycle unconditionally; the claim it was taken to support is that a PARKED WEIGHT
  HOLDS. Accepted form, weaker than the claim — and the row exhibits the consequence: the weight
  meets its stream as `W·2^gap`.*
- **76455** → `type-traps`. *A backtick pair was COMMAND-SUBSTITUTED and ATE A CONSTANT; the
  sentence landed missing `E ≥ 1`, the shell printed its error, and the author read past it.
  The accepted-vs-meant gap, exhibited live, in the row's own text.*

⚠️ **87679 did NOT move on the same clause** — it CITES two past corruptions rather than
exhibiting one live, and repair D requires LIVE. *That distinction is the whole of why one moved
and the other did not, and I record it because it is the kind of line that drifts.*

### 5.3 · Reading the 73% against the refuter's 40%

**The refuter's pre-repair figure was 8/20 = 40% survival.** *The codebook says why a
post-repair run must be higher:*
> *"R-A recovers 72058 and R-B recovers 72396 and 39087 in the 20 rows already examined, **so
> the standing 40% is an UPPER BOUND ON THE LOSS**, not the measurement the sitting rules on."*

⇒ **73% post-repair against 40% pre-repair is the direction the codebook predicts.** ⚠️ *But my
prior points the same way, and I cannot separate the two from this seat. **The figure is
reported with its bias direction attached, and it is not the amendment's vindication until a
second hand runs the same 22.***

### 5.4 · What is still owed on B-4

```
OWED   the 20 contaminated agreed-`OTHER` rows — runnable, but reported SEPARATELY,
       never pooled with these 22
OWED   the reading (§2): all 110, or the 42? The denominator is the sitting's to fix
OWED   a SECOND HAND on these 22, because the pass-1 coder cannot be the held-out scorer
```
