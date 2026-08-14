# R-2 · THE `47%` FORK — **RESOLVED, AND MY COMPETING FIGURE IS THE ONE THAT FALLS**

**Seat:** compiler · **2026-08-14 12:58** · Folded into L-1 by the helm's ruling. The fork:
the codebook reports **131 of 278 reason-pairs (47%) carry no quoted text**; I had a
competing reading around **206/278**, *"two readings 75 rows apart"*.

## 1 · THE FORK DISSOLVES — THEY ARE DIFFERENT TESTS **AND** OPPOSITE POLARITIES

```
TEST A  a QUOTE CHARACTER appears in either reason
        ⇒ NO quoted text ....... 131 / 278 = 47%     ← reproduces the codebook EXACTLY
TEST B  a ≥20-char span of a reason appears VERBATIM in the row body
        ⇒ NO quoted text .......  71 / 278 = 26%     ⇒ HAS quoted text = 207
```
⇒ ***`131` counts pairs WITHOUT quoted text under A. `206`–`207` counts pairs WITH it under B.
Different test, different polarity — two confusions stacked, and neither number was ever
wrong about its own question.*** **Nothing is 75 rows apart; nothing was in conflict.**

## 2 · ⛔ AND TEST B IS UNUSABLE — I ALMOST PUBLISHED A CORRECTION RESTING ON A KNOB

I was one command from reporting *"the real ungrounded figure is 26%; the codebook's 47%
overstates it."* **Then I ran the threshold sensitivity I had only intended as a robustness
check:**
```
span k     15     20     25     30     40     60     80
NO span    5%    26%    44%    59%    83%    97%   100%
```
🔑 ***THE ANSWER IS A FUNCTION OF `k`, AND `k` WAS MY ARBITRARY CHOICE.*** **A definition can be
TEST-SHAPED — mechanical, reproducible, no judgement — and still hide a free parameter that
carries the entire result.** *L-1's constraint asks for "a decision procedure, never a
description"; my B was a decision procedure and it decided whatever I set `k` to.*

✅ **TEST A HAS NO KNOB.** A quote character is there or it is not. ⇒ ***The codebook's 47% is
the defensible figure and I withdraw the competing one. Its test is worse at measuring what we
care about and better at meaning the same thing twice.***

## 3 · WHAT `47%` ACTUALLY MEASURES — AND THE LABEL SHOULD SAY SO
Test A measures **quotation PUNCTUATION**, not **grounding**. The two differ, demonstrably —
reasons that lift the row's own words at length without marking them:
```
row 9839   88 chars unmarked: " verdict about commit X citing working-tree lines cites a frame …"
row 33135  59 chars unmarked: " rather than being assigned to whichever bucket tidies the …"
row 31857  58 chars unmarked: " unrooted, so every fleet full-build verdict had missed it"
```
⇒ **A coder who read the body and paraphrased tightly scores identically to one who never
opened it.** *That is the limit of the 47%, and it is a limit in the direction that makes the
corpus look worse than it is.* **RECOMMENDATION: keep the figure, relabel it *"reason-pairs
with no quotation punctuation"*, and stop reading it as a grounding rate.**

## 4 · ⭐ THE ASYMMETRY, WHICH IS THE PART WORTH THE SITTING'S TIME
```
reasons carrying a quote character:   pass 1 (this seat)  49 / 278 = 18%
                                      pass 2 (cold coder) 128 / 278 = 46%
```
***THE COLD CODER QUOTES TWO AND A HALF TIMES AS OFTEN AS I DO. The 47% is not a property of
the pair — it is substantially MINE.*** **This is the codebook's own §3.4 rationale arriving as
a number rather than an impression:** *"the author-coder's 27 reasons on this border are almost
all headline paraphrases … while the cold coder read the body."* ⇒ **A grounding requirement
would bind this seat about 2.5× harder than the other, which is an argument FOR it.**

## 5 · WHAT THIS DOES NOT CLAIM
- Not that pass 2 is better coded — **quoting is evidence of reading, not of judging well.**
- Test A is exact and reproducible; **§3's three examples are illustrative, not a census** of
  unmarked lifting, whose size is itself `k`-dependent and therefore not reported as a figure.
- 278 is the disputed set, not all 388. **Coverage over the full corpus is not recomputed here
  and is not claimed.**
