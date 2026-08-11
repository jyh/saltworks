# The MATHS-PAPER FENCE — criterion, pre-registered 2026-08-11 01:2x

**Status: CRITERION ONLY. No instrument exists yet, and that is deliberate.**

Written at math's 01:24 acceptance ("build it, and before the arXiv posting
rather than before the morning read"). This file is the *criterion*, published
before the tool, because this seat's own law says a fence that changes the work
is cheaper than one that judges it — and because at 01:2x, thirteen hours in,
this seat has published that its form-keeping degrades after hour eight. Writing
a criterion is checkable by anyone; mechanising one at 01:30 is how tonight's
three tools each shipped with two to four self-inflicted defects.

⚠️ **A successor with a fresh head builds the instrument. The bar is fixed here
first so it cannot be fitted to whatever the draft happens to say.**

---

## Scope, stated before anything else

This fence is for a **mathematics paper whose results are formalised in a
machine-checked corpus.** It is NOT the chip fence (`claim_fence.py`, F1–F7),
which measures claims about a die and returns a **vacuous green** on this paper
— zero of its seven phrases can appear in a twin-primes text, and this seat
declared that green worthless on the bus at 01:23.

```
COVERS      the gap between what the CORPUS proves and what the PAPER says
DOES NOT    the mathematics itself · referee-grade correctness · exposition
```

## M1 — THE FINAL THEOREM'S HYPOTHESIS DISCIPLINE ✅ mechanisable

*The law math discovered had never loaded at any boot of their seat: "the
flagship's final theorem carries NO named external hypotheses; disclosure-
fallbacks are OFF THE TABLE."*

```
M1 CLEARS when, for the paper's headline theorem:
  (a) the Lean statement it corresponds to is NAMED, with file:line
  (b) `#print axioms <name>` returns EXACTLY [propext, Classical.choice,
      Quot.sound] — read from the line, not from a status word
  (c) the theorem's own binders carry NO hypothesis that names an unproved
      external result (no `(hRH : RiemannHypothesis)`-shaped assumption)
  (d) every hypothesis that IS carried appears in the PAPER's statement too
```
⛔ **(d) is the one that catches the real failure**: a paper may state a theorem
cleanly while the Lean version carries a rider. The gap is invisible from either
side alone, and this is exactly the class the corpus's own name-gate does not
check — it verifies that cited names RESOLVE, not that their statements MATCH.

### ⭐ M1(d)'s PREDICTED FIRST TARGET — pre-registered by MATH at 01:26, before the tool

*Named by the seat that wrote the sentence, which is the only seat that knows
where it cut a corner if it cut one. Verified at HEAD by this seat — the Lean
side is exactly as described:*

```
Salt/HB/L2cMasterUncond.lean:85   theorem hb_l2c_master_unconditional
  LEAN BINDERS   (hsq : χ ^ 2 = 1) · (hz100 : 100 ^ 16 ≤ z)
                 (hz8 : Lwin x ^ 8 ≤ z) · (hzx : (z : ℝ) ^ 3 ≤ x)
                 ⇒ all four confirmed present at the bytes, 2026-08-11 01:2x
  PAPER (Thm 6.1) states them as PROSE: "at parameters (z,x) IN THE ENGINE'S
                 REGIME"
```
⚠️ **NOT yet a defect — "the engine's regime" may be defined elsewhere in the
paper as exactly those inequalities, and nobody has checked.** *It is the site
to look at first, fixed here before the instrument exists so the first run is a
TEST OF A PREDICTION rather than a scan.*

🔑 ***AND IT IS WHY M1(d) EXISTS: a rider hidden inside a prose noun is
invisible from BOTH sides alone. The Lean looks complete, the paper looks clean,
and only the PAIR shows the gap. Math's own name-gate passes it — that gate
verifies a cited name RESOLVES, never that the two SENTENCES agree.***

📌 **Outcome discipline for the eventual run:** *finds it ⇒ the instrument
works and the site gets a ruling. Finds nothing ⇒ either the tool is broken or
"the engine's regime" is properly defined, and those must be distinguished
before either is claimed. **A prediction that cannot fail would tell us nothing
about the tool.***

### ✅ M1(d) — FIRST HIT, CONFIRMED 2026-08-11 07:47 (before the instrument existed)

*Math's successor closed the LaTeX half; this seat verified all three claims at
HEAD independently.*
```
"engine's regime"  main.tex:502, count = 1, DEFINED NOWHERE
:519, 17 lines below — "the estimate holds from its FOUR EXPLICIT
                        HYPOTHESES alone"
COLLISION          `structure ChowlaRegime` (Salt/Entropy/Chowla/Regime.lean:56)
                   is a real defined object of a DIFFERENT track, rendered in
                   the paper at :1319 :1325 :1337 :1341
```
⭐ **SHARPER THAN THE PREDICTION, and the sharpening is the finding: an undefined
term costs a reader a lookup; a term left undefined WHILE THE PROSE CERTIFIES
ITS EXPLICITNESS costs them the belief that they missed something — and an
honest reader concludes the fault is theirs.**

📌 *The pre-registration fork resolved on its FIRST branch: the tool works, and
it surfaced a defect NEITHER seat predicted — which is the only outcome that
proves a criterion was not fitted to its target. Repair is math's: state the
four inline, define the phrase, or rename away from the collision. All three
clear M1(d).*

## M2 — DISCLOSURE-FALLBACK BAN ✅ mechanisable

*A "disclosure fallback" is prose that softens a claim the theorem does not
support: "morally", "essentially", "up to routine verification", "we expect",
"it is standard that", "the interested reader can check".*

```
M2 CLEARS when no such hedge appears in the SAME sentence as, or the sentence
   following, a claim that cites a formalised name. Hedges in genuinely
   informal sections (motivation, history) are FINE and must not be flagged —
   the discriminator is PROXIMITY TO A CITED NAME, never the word alone.
```

## M3 — PRIORITY CLAIMS ⛔ NOT MECHANISABLE, and this is the honest half

```
MEASURED at HEAD, papers/flagship/main.tex:
  :106  "first formalization"        :241  "none had been"
  :149  "to our knowledge"           :259  "To our knowledge"
  :261  "first formalization"
```
***NO INSTRUMENT INSIDE THIS REPOSITORY CAN CHECK A CLAIM ABOUT THE
LITERATURE.*** A tool can only do two things here, and it must do both rather
than pretend to a third:

```
1  ENUMERATE every priority claim with file:line — a WORK LIST, never a verdict
2  REQUIRE, beside each, a stated SEARCH: what was searched, where, when, by
   whom. "To our knowledge" with no recorded search is an unfalsifiable claim
   wearing a hedge.
```
⚠️ **M3 can never return a green. Its output is "N priority claims, each with /
without a recorded search." The paper's authors clear it; the fence only makes
the absence visible.**

## M4 — THE FENCE MUST DISCLOSE ITS OWN FRAME

The tool's output must state, every run: which of M1–M3 it measured, that M3 is
enumeration rather than verification, and that a green covers **the text it was
run on**, not the version that gets posted. *This seat spent 2026-08-10
discovering that its own instruments' coverage figures were parser artifacts
twice; the frame line is not decoration.*

---

## Pre-registration

**This bar is fixed at 2026-08-11 01:2x, before the instrument exists and
before it is run on any draft.** If a later run finds the flagship clean, that
result means something because the criterion could not have been fitted to it.
If the bar is later changed, the change and its reason go in this file with a
date — never a silent edit.

📌 **Known limits, named now rather than discovered later:** M1(d) requires
reading a Lean statement against a LaTeX one, which no regex does — it needs a
structured comparison or a human. M2's proximity rule will produce false
positives in survey sections. M3 is not a check. **A fence that claimed to
close all three would be lying about the third.**
