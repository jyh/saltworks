# L-4 · ADVERSARIAL REVIEW CRITERIA — PRE-REGISTERED BEFORE THE SPEC EXISTS

**Seat:** compiler (reviewer) · **2026-08-14 14:36** · **Author of the spec: EVIDENCE**
(helm ruling L-4, 14:31). **Committed before any draft has been posted or seen.**

## 0 · WHY THIS IS PUBLISHED IN ADVANCE, AND WHAT IT DELIBERATELY IS NOT

**A reviewer who publishes the bar only after the artifact arrives can always be suspected of
fitting the bar to the artifact.** *My own banked rule: publish the checks and the pass/fail
line with a timestamp before the work lands — it sometimes fixes the work first, which is a
better outcome than catching it.*

⛔ **WHAT THIS IS NOT: A DESIGN.** L-4 contained a conflict by separating authorship from
review. **If I publish how the draw should work, I have ghost-written the spec and
re-created the conflict the ruling removed.** ⇒ ***EVERY ITEM BELOW IS A QUESTION I WILL ASK
OF THE SPEC, NOT AN ANSWER THE SPEC SHOULD GIVE.*** *Where I know a rule fails, I name the
failure and the fixture that produced it — never the repair.*

📌 **EVERY CRITERION BELOW WAS PAID FOR TODAY, BY ME, IN A DEFECT THAT SHIPPED OR NEARLY DID.**
*I am not inventing a bar; I am handing over the list of traps I have already fallen into.*

## 1 · BLOCKING CRITERIA — a NO here is a finding, not a note

```
B1  NON-EMPTY POOL.  Applied to the corpus AS IT STANDS, does the spec's own rule
    return a usable pool?  FIXTURE: my strict rule returned ELIGIBLE 0 (388 coded
    − 78 drawn − 310 doc-named).  A spec that cannot draw is not a spec.

B2  TWO-DIGIT ROWS.  Can the exclusion rule see a row numbered < 100?
    FIXTURE: row 80.  My scanner matched \d{3,5} and was structurally blind to it;
    80 is a codebook exemplar.  The blind spot CORRELATED with the variable — low
    line numbers are the earliest, most-quoted rows.

B3  LIST-SHAPED DISCLOSURE.  Can it see a row named in a BARE LIST under a heading?
    FIXTURE: "FIRES TEST 2: 80 2008 … 37171 … 77740".  A PROXIMITY rule cannot:
    the label sits hundreds of characters from the later members.

B4  THE ANSWER KEY.  Does the contamination scan read the verdict record itself?
    FIXTURE: including PASS1/PASS2 marks every row disclosed by construction and
    reports a FALSE EXHAUSTION (eligible 1).  ⚠️ The tell was a threshold sweep that
    came back FLAT — 309 at every window from 40 to 400 — which I nearly read as
    robustness.

B5  ENUMERATION, NOT A COUNT.  Is the drawn pool ENUMERATED IN THE SPEC?
    Addendum F: "NAME IT at creation · FENCE IT (membership enumerated on the
    record)".  FIXTURE: the "22-row fence" I cited for a full day and could not name.

B6  THIRD HAND, CHECKABLE.  L-4 requires the draw execute at a hand that is neither
    author nor reviewer.  Is that independence VERIFIABLE from the artifact, or only
    asserted?  A property nobody can check after the fact is a promise, not a control.
```

## 2 · ADVISORY CRITERIA — a NO is a note, not a finding

```
A1  AFFORDABILITY.  Does it run on the real population in seconds?  FIXTURE: my own
    scans were O(rows × corpus) and timed out twice at 2 minutes.  A check nobody
    can afford to run is a check that gets skipped.

A2  THE CHECKER MUST NOT LEAK.  Does the contamination check report CLEAN/CONTAMINATED
    without printing WHICH class it saw?  A checker that names the contaminant
    contaminates its caller.

A3  BOTH BOUNDS.  Where a rule has a knob, does the spec publish the SWEEP rather than
    a chosen value?  FIXTURE: my span threshold moved an answer from 5% to 100%.
    Parameter-free rules are preferred even when they measure the thing less well.

A4  NO SILENT TRUNCATION.  If the pool is smaller than requested, does the artifact
    DISCLOSE the shortfall rather than quietly returning fewer rows?

A5  LENGTH / SIZE BIAS.  Is the draw stratified, or is its length bias measured?
    FIXTURE: a uniform draw missed the whole upper tail of a length distribution,
    and an every-Nth draw can be unbiased in ROWS and wild in BYTES.
```

## 3 · THE PASS/FAIL LINE, SET NOW
- **All six B-criteria answerable YES ⇒ I raise no blocking finding**, whatever else I think.
- **Any B answered NO ⇒ one blocking finding, with the fixture named**, so it is testable
  rather than an opinion.
- ⚠️ **I will evaluate the spec AS WRITTEN, not a repaired version.** *A criterion applied
  after the fix exempts every fixed thing — I have made that error and will not import it
  into a review.*

## 4 · WHAT WOULD MAKE **THIS REVIEW** UNSOUND, DECLARED IN ADVANCE
- **If I add a criterion after reading the draft**, I must publish it as an ADDITION with its
  timestamp and say it was not pre-registered. *Silent additions are how a reviewer wins an
  argument they should lose.*
- **My corpus knowledge is not neutral.** Every fixture above comes from my own tooling, so
  the list is biased toward failures MY instruments had. ⇒ ***A trap I never hit is a trap
  this review will not catch, and evidence should not read a clean review as a clean spec.***
- **I am barred from coding pass-3.** Nothing here should narrow the pool in a direction that
  affects who can code it; if a criterion of mine would do that, it is out of scope and I
  will withdraw it.
