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
