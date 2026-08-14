# §6-R3 CLASS-DETERMINACY AUDIT — RESULT

**Seat:** compiler · **Pre-registration:** `f63975e`, committed 09:15:56, **before any
drawn row was opened.** Nothing in the pre-registration was edited afterwards; where
it turned out defective (§5 below) the defect is reported, not repaired.

## 1. HEADLINE — THE GAP B-3 EXISTS TO INVESTIGATE IS SUBSTANTIALLY **DEFINITIONAL**

B-3 asks why DRAFT 1 claimed **90.3%** mechanically decided while its refuter measured
**5/20 = 25%**. Scoring 30 fresh, unnamed, length-stratified rows produced **both
numbers from the same work**, differing only in what counts as a decision:

```
a class TEST FIRES (ladder reaches a specific class) ...... 13/30 = 43.3%
+ NO test fires ⇒ row rests in the residual OTHER (§1.1) ... 26/30 = 86.7%
```
🔑 **86.7% sits next to DRAFT 1's 90.3%; 43.3% is the same order as the refuter's 25%.**
Neither party need have been wrong about the corpus. **"Mechanically decided" was never
defined, and it silently carries a factor of two.**

⇒ **RECOMMENDATION: §6 should not ratify a determinacy figure until the term is defined.
Whichever definition the sitting picks, the OTHER number must ship beside it** — a bare
percentage here is the withdrawn-90.3% failure repeating with a new value.

## 2. THE MEASUREMENT

```
pool          120 free rows (measured; the file's "~120" is exact)
draw          N=30, LENGTH-STRATIFIED, absence from the ratified file re-verified for all 30
read          75,290 B, every body in full, header-to-next-header

a class test FIRES ..... 13    T1 ×7 · T4 ×4 · T3 ×2 · T2 ×0
NO test fires .......... 13    (⇒ residual OTHER)
AMBIGUOUS .............. 4     (two tests arguable, neither with a clean trigger)
⚠️ CONTESTED ........... 11/30 = 37%   ← ships beside every figure above, per B-4(2)
gate-dependent ......... 4     (flagged, not silently scored, per the pre-registration)
```

## 3. ⭐ THE SECOND FINDING, AND IT CONVICTS THIS SEAT

```
                    mech   pass1   pass2
T1 fires 7 of the 13 deciding rows — the MOST FREQUENT deciding class
PASS 1 (this seat) assigned type-traps to .......... 0 of those 7
ALL 13 deciding rows were coded OTHER in pass 1 .... 13 of 13
mechanical verdict reached by NEITHER coder ........ 6 of 13 (46%)
```
**The type-trap blind spot this seat banked on 08-13 — a class that drew zero rows from
me across 388 while a blind second coder assigned it 34 times — is reproduced here
mechanically, on fresh rows, by the codebook's own tests.** It is no longer an inference
from a disagreement; it is a measured property of this coder against a written rule.

⚠️ **And the sharper half: 46% of the mechanical verdicts were reached by neither coder.**
The tests do not merely adjudicate between two coders' answers — **on nearly half the
rows they decide something both coders missed.** That is an argument for the ladder and
against both passes, and it is why this seat's eligibility to code the pass-3 sample
remains spent.

📌 **T2 (`misattributed-mechanisms`) decided ZERO of 30.** It fired once (82239) and was
outranked by T1. *A class that never decides on a fresh 30-row draw is either rare or
structurally shadowed by T1's precedence — worth the sitting's eye, and not something
this run can separate.*

## 4. ✅ THE PRE-REGISTERED PREDICTION — CONFIRMED

Registered at `f63975e`: **40–70% mechanically decided (12–21 of 30)**, with both failure
directions named in advance. **Result: 13/30 = 43.3% — inside the band, near its lower
edge.** The reasoning given in advance (an explicit precedence order should beat DRAFT 1's
25%, but nothing suggests class calls are categorically easier than the 70%-contested gate
calls of §6-R1) survives the measurement.

## 5. ⛔ TWO DEFECTS IN MY OWN CONDUCT OF THE RUN, REPORTED NOT REPAIRED

**(a) My pre-registered definition was defective.** It classed "no test fires" as NOT
DECIDED, when the codebook's ladder treats it as a determinate outcome — the row rests in
the residual. **I followed the wording as written and report both readings** rather than
amending a definition after seeing data. *The defect turned out to be the finding: it is
exactly the ambiguity §1 is about.*

**(b) I began scoring from truncated bodies.** A 1,900-char display cap hid **34.7% of the
corpus across 70% of the draw**, and the four tests can fire anywhere in a post (§1.5 runs
precedence over all findings), so truncation can only hide triggers — biasing toward NOT
DECIDED and toward the first finding in each post. **Caught after the first 10 rows; all
30 were then read in full and re-scored.** *Same defect I published against at 08:36 the
same morning, committed inside the next task.*

## 6. WHAT THIS RUN DOES NOT CLAIM

- **N=30 is B-3's floor.** 13/30 carries a standard error of about ±9 points; 43.3% should
  be read as "roughly two in five", never as a third significant figure.
- It says nothing about **which coder was right** on any row (B-3: "not side-determinacy").
- The 4 gate-dependent rows are flagged, not scored — their class turns on §2.2, which is
  before the sitting as pack item 8.
- Row-level bases for all 30 verdicts are in the run's score table and can be re-read
  against the bodies by anyone who disagrees; **every verdict names the test and the span
  that fires it, or says why nothing fires.**
