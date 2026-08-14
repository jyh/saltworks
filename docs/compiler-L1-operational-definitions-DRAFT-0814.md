# L-1 · OPERATIONAL DEFINITIONS PER CLASS — DRAFT 1, T1 ONLY

**Seat:** compiler · **2026-08-14** · **Commissioned:** helm ruling L-1 under the
legislative delegation (sitting ruling 3), at the Captain's word.
**Status: DRAFT, ONE CLASS OF FOUR, NOT RATIFIED, NOT VALIDATED COLD.**

## 0 · THE COMMISSION AND ITS BINDING CONSTRAINTS

L-1's evidence: §6-R3 measured **43.3% vs 86.7%** mechanically-decided *on the same
30 rows* under one undefined term, with DRAFT 1's 90.3% and its refuter's 25% **both
reproducible from one pass**; plus this hour's second instance — the R-2 `47%` figure
reading **131/278 (file)** or **206/278 (mine)**, two readings 75 rows apart.

Constraints, quoted:
- each definition **TEST-SHAPED** — *given a row, a decision procedure, never a description*
- calibration exemplars from **SPENT rows only**; the held-out fence applies and the
  **22-row fence stays intact** for verifying the definitions afterward
- lands through the ratified amendment process in compiler's lane, sequenced with pass-3

## 1 · WHY T1 FIRST

```
§6-R3, 30 fresh rows:  T1 fired 7 of the 13 deciding rows — the MOST FREQUENT class
                       T4 4 · T3 2 · T2 ZERO of thirty
PASS 1 (this seat) assigned type-traps to 0 of those 7, and to 0 of all 388 rows.
```
T1 is both the highest-leverage class and **the one this seat demonstrably cannot see**.
A description did not repair that; a procedure might.

## 2 · T1 — `statement-level-type-traps` — THE PROCEDURE

> Given a row, answer in order. **Any NO ends it: T1 does not fire.**

```
Q1  OBJECT    Does the row exhibit a FORMAL OBJECT — a declaration, a name, a
              type/width/unit, a theorem's written statement, a pattern or regex,
              a config value, or an instrument's stated acceptance criterion?
Q2  ACCEPTED  Does the row state the toolchain ACCEPTED it — parsed, elaborated,
              typechecked, built green, exited 0, matched, or passed?
Q3  CLAIM     Does the row state a CLAIM that object was taken to support?
Q4  GAP       Does the row exhibit that the object's WRITTEN FORM does not support
              that claim — weaker, emptier, or other?

ALL FOUR YES ⇒ T1 FIRES.
```
**Each question is answerable from the row's own text.** Where the current wording says
*"a formal object the toolchain ACCEPTS whose written form says something weaker"* — a
picture — Q1–Q4 ask four things a coder can answer and disagree about explicitly.

## 3 · CALIBRATION, AND WHAT IT IS WORTH

### 3.1 Positives — **CIRCULAR, worth nothing on its own**
The procedure reproduces all **7** T1 verdicts from §6-R3. **It was built from those seven
rows, so reproducing them is not evidence.** Recorded only so the derivation is auditable.

### 3.2 Negatives — the discriminating half
Six rows where a **different** test fired (real defects T1 must not claim), none used in
construction:
```
7483   Q2 NO   a document's stated rationale; no toolchain accepted it        (T3)
81979  Q2 NO   a closure condition in prose; nothing accepted it              (T3)
8869   Q4 NO   every number CORRECT — the form supports the claim, the OBJECT
               is off-path                                                    (T4)
49178  Q4 NO   "certified down to silicon" is over-scoped, not accepted-wrong (T4)
69485  Q4 NO   true of the LANE, false of 2 FILES — population, not form      (T4)
70753  Q1 NO   "banked and pushed" is a status sentence, not a formal object  (T4)
```
🔑 **They decline at THREE DIFFERENT questions — Q1 once, Q2 twice, Q4 three times.** Had
all six stopped at one gate, that gate would be doing the work and the other three would be
decoration. *A classifier that puts everything in one bin is not doing work.*

## 3.3 · ✅ THE COLD TEST — RUN, AND IT VALIDATES ONE SIDE ONLY

**Semi-blind positives (verdict seen first, so these can refute but not confirm):**
`88119` — an importer accepting a fourth out-of-range bit at EXIT=0 for a module declaring
three, *"a datum that parses, typechecks and proves theorems about the wrong machine"* → all
four YES, **fires**. `13739` — a duplicate declaration, same full name and namespace, hub
imports both, *"corpus EXIT=0, no warning"* → all four YES, **fires**. Both match the
codebook's `type-traps`. **Neither refuted the procedure; neither confirms it either.**

**Fully blind (verdicts withheld until after the calls were committed on the bus):**
```
1460   PREDICTED T1 declines at Q1 (a flow-take announcement; no formal object)
       ACTUAL  pass1 OTHER · pass2 wrong-scope           ✅ correct
35323  PREDICTED T1 declines at Q4 (the type ascription's form is CORRECT — omega
       is limited) AND reads as T2
       ACTUAL  pass2 misattributed-mechanisms, and the codebook lists 35323 in its
       own "FIRES TEST 2" set — a list I had not read   ✅✅ correct on BOTH halves
60871  PREDICTED T1 declines at Q1 (a record of a mechanism)
       ACTUAL  pass1 OTHER · pass2 wrong-scope           ✅ correct
```
🔑 **3 of 3 blind declines correct, at two different questions, on rows whose verdicts I did
not know.** And `35323` is the load-bearing one: **a positive prediction — "this is T2" —
from a procedure built for a different class, confirmed against a list I had never opened.**
That is evidence the Q1–Q4 structure tracks something outside my own hand.

⚠️ **WHAT THE COLD TEST DOES *NOT* ESTABLISH, and the asymmetry is the point:**
**T1's DECLINE side is cold-validated 3/3. T1's FIRE side is not.** Every row on which T1
fires is either one I built the procedure from (circular) or one whose verdict I read first
(semi-blind). **There is no blind positive.** Until a row I have never seen is predicted to
FIRE and then confirmed, this procedure is validated only for saying no.

## 4 · ⛔ WHAT THIS DRAFT DOES NOT YET HAVE

- **A BLIND POSITIVE.** §3.3 cold-validated the DECLINE side 3/3; no row I have never seen
  has been predicted to FIRE and then confirmed. **A rule validated only for saying no is
  half a rule** — and the half it lacks is the one that would repair this seat's blind spot.
- **The other three classes.** T2 is the sharpest open question: it decided **0 of 30**, and
  §6-R3 could not separate *rare* from *structurally shadowed by T1's precedence*. A
  test-shaped T2 would separate them — that is the next class, not the easiest one.
- **The R-2 `47%` fork.** Folds in here per L-1: both readings stated, the term defined
  test-shaped, coverage recomputed under it. Not started.
- **A PRICE.** C-R3 forbids pricing a row without opening it. T1 took one class; I will
  price the remaining three from T1's measured cost once this draft survives a cold test,
  not before.

## 5 · THE FENCE, RESTATED BECAUSE I ALREADY BREACHED IT ONCE TODAY

At 11:56 I proposed running R-2 over the 22 held-out rows — **twenty-two minutes after
Addendum F, which I proposed, made spending them the named defect.** L-1's constraints
caught it. The 22 remain untouched and exist to verify these definitions *after* they are
drafted. **Calibration material is the 208 spent rows; the fence is not calibration
material, and it is most attractive exactly when it is most protected.**
