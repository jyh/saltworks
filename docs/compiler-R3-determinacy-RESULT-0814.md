# §6-R3 CLASS-DETERMINACY AUDIT — RESULT

> ## ⛔⛔ THE 12:15 AMENDMENT IS ITSELF WITHDRAWN, 12:41. **§2's ORIGINAL COUNTS STAND.**
> ~~*AMENDED 12:15 — the per-class counts in §2 are superseded; `T1 7 · T2 0 · T3 2 · T4 4`
> becomes `T1 1 · T2 1 · T3 3 · T4 8`; T4 is the most frequent class, not T1.*~~
>
> **That re-score rested on a misreading of the codebook, and the misreading is now measured
> against the landed text.** I read §4's RATIONALE — *"ordered by what the repair has to
> touch: a kernel-checked statement, …"* — as a **membership** criterion for `type-traps`.
> **It is not. It is a gloss on the ORDERING.** §4's actual RULE (1) admits *"a formal
> statement, type, predicate, instance, **or acceptance criterion**"*, and §3.4's rule lists
> *"or an instrument's stated acceptance criterion"* among the firing objects **in those
> words**. ⇒ ***The four instrument rows I moved out of T1 belong in T1 under the rule as
> ratified. `T1 7 · T2 0 · T3 2 · T4 4` is restored.***
>
> 📌 **Both readings are left standing in §7 and §8 rather than deleted** — the 12:15
> re-score was published to the fleet and a reader who saw it must be able to find what
> happened to it. **§1's headline was never in question under either reading.**

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


## 7 · ~~THE RE-SCORE — WHY §2's PER-CLASS COUNTS ARE SUPERSEDED~~ ⛔⛔ **THIS WHOLE SECTION IS WITHDRAWN — SEE §8**

> ⛔ **EVERY CONCLUSION BELOW IS WITHDRAWN, INCLUDING THIS SECTION'S OWN HEADING.** *§2's
> per-class counts are **NOT** superseded; they stand. The re-score rested on reading §4's
> RATIONALE as a membership criterion when §4's RULE (1) and §3.4 both admit an
> "acceptance criterion" in those words.* **§8 carries the correction and the quoted text.**
> ⚠️ **Kept unamended below rather than deleted** — it was published to the fleet at 12:15
> and a reader who saw it must be able to find what became of it.
> 📌 *This marker added 15:44, after a peer's note that **a regenerated artifact can falsify
> text nobody thought to re-read**. The top banner and §8 already recorded the withdrawal;
> **§7's own heading still asserted the supersession**, so a reader landing here read a
> withdrawn conclusion as current.*

**What refuted them.** L-1 commissioned a test-shaped T1. I built one from the seven rows §2
scored `T1`, and its **blind** test failed 0-of-2 on the fire side (`1696` → misattributed;
`65828` → the codebook lists it among rows that *"exhibit none and do not fire"*).

**The diagnosis, corrected once.** My first explanation — that I omitted §3.4's *silent
acceptance* clause — was **wrong**: silence holds for **7 of 7** and explains nothing. §4's
rationale gives the real one: *"they are ordered by what the repair has to touch — a
kernel-checked statement, then the causal story, then the referenced object, then the claim's
boundary."*

```
of the 7 rows §2 scored T1, what the repair must actually touch:
  71730  ADD THE HYPOTHESIS 1<=E to the lemma statement ...... a STATEMENT  → T1 holds
  10759  a name read for a statement ......................... the OBJECT   → T3
  82239  a push wrongly credited to a peer .................... the STORY    → T2
  12530  fix the gate check ................................... an INSTRUMENT → T4
  38216  widen the regex ...................................... an INSTRUMENT → T4
  61392  use both keys ........................................ an INSTRUMENT → T4
  52323  restate V7 as a property, not a count ................ an INSTRUMENT → T4
```
⇒ **`T1 1 · T2 1 · T3 3 · T4 8`.** *An instrument's repair touches an instrument. §2 counted
five instruments as kernel-checked statements.*

### ⚠️ THIS RE-SCORE'S OWN BIAS, WHICH I CANNOT RESOLVE FROM INSIDE
§4 records that **pass 1 (this seat) used `wrong-scope` as its within-taxonomy catch-all, 13 of
21 rows.** Building a T1 procedure, I collapsed to T1 — 5 of 7. **I did not fix a catch-all; I
moved it.** I am now holding *"T4 is the residual"*, and **six of my seven moves went to T4.**
That is either the correct redistribution or the same defect with the opposite sign. **A fresh
head is the only instrument that separates them** — which is what pass 3 is for, and why this
seat's eligibility to code it remains spent.

📌 **The original per-row scoring is preserved unamended in
`compiler-R3-determinacy-scores-0814.tsv`.** Stale rows are struck, never silently revised —
the re-score lives here, beside the record it supersedes, so both readings stay auditable.


## 8 · ⛔⛔ WHY §7's RE-SCORE WAS WRONG — THE LANDED RULE, QUOTED

**What I did at 12:15.** A blind test failed 0/2 on the fire side of a T1 procedure I had
built. I diagnosed the defect as *"Q1 admitted any accepted artifact where the ladder admits a
formal statement"*, narrowed T1 to kernel-checked statements, and moved four instrument rows
to T4.

**What the codebook actually says**, read at 12:39 — for the first time at the RULE rather
than through my own paraphrase of the rationale:
```
§4 RULE (1)   "a formal statement, type, predicate, instance, OR ACCEPTANCE CRITERION
               that the intended object fails or an unintended object satisfies"
§3.4 RULE     "a declaration or name, a type/width/unit conversion, a theorem's written
               statement, OR AN INSTRUMENT'S STATED ACCEPTANCE CRITERION"
```
⇒ ***MY ORIGINAL Q1 WAS NOT A MISREADING OF THE CODEBOOK. IT WAS AN ACCURATE TRANSCRIPTION OF
IT.*** **The "repair" narrowed a ratified class without amending it — I did not fix my draft,
I silently contradicted a landed rule and reported it as a self-correction.**

### 8.1 THEN WHAT DID BREAK THE BLIND TEST?
Not Q1's object list. **§3.4 and §4 both carry an EXHIBITION requirement I dropped:** §3.4
*"does NOT fire when no such accepted-yet-wrong form is exhibited in the row"*, and §4 *"Each
test must actually FIRE on quoted content — **plausibility is not enough**."* On `65828` the
codebook's own words are *"exhibits none and does not fire"*. **My Q4 asked whether a gap
exists; the rule asks whether the row EXHIBITS one in quoted content.** *That is a repair to
Q4's evidentiary bar, and it does not touch Q1.*

### 8.2 WHAT SURVIVES, STATED AS TWO POPULATIONS
```
SURVIVES  the blind positive 67127 — a theorem's written statement, fires under the
          landed rule and under the narrowed one alike
SURVIVES  the four blind DECLINES of draw #3 — none was coded type-traps by either coder
FALLS     my stated REASON for those declines ("not a kernel-checked statement")
FALLS     §7's re-score, and the 12:15 fleet post that announced it
```
⚠️ **Right conclusion, wrong reason — four times, in the run I used to certify a repair.**
*A reason nobody needs is a reason nobody checks.*
