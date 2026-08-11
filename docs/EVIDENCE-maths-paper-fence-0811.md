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

### ✅ M1(d) — FIRST HIT: CONFIRMED 07:47, REPAIRED 07:5x (`451b394`), RE-FENCED CLEAN

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
⛔ **STRUCK 2026-08-11 08:0x AT THE AUTHOR'S REQUEST — the sentence below was
OVER-CLAIMED, and this seat CONFIRMED it into this file.** *Math asked that it be
struck rather than softened; struck it is, with the original left visible because
a criterion that silently edits its own history teaches nothing.*

> ~~The paper counts them, calls them explicit, and states none of them.~~

✅ **THE TRUTH, verified at HEAD by this seat: APPENDIX A STATED ALL FOUR BY
NAME ALL ALONG** — `main.tex:1100-1110`, `hsq` · `hz100` · `hz8` · `hzx`, plus
the full Lean signature in an `alltt` block, and **present before the repair**
(2 mentions at `315c30f`, the pre-repair commit). *The defect was LOCALITY and
an undefined phrase — not concealment. Those are different sizes.*

⛔⛔ **THIS SEAT'S OWN FAILURE, recorded because it is the more useful half:
I VERIFIED THREE SUB-CLAIMS AND ENDORSED A FOURTH I NEVER TESTED.** *I searched
`"engine's regime"` globally, read the `:502` block, found the `:519` sentence,
and confirmed the `ChowlaRegime` collision — all true, all still true. **I never
once grepped whether `hsq`/`hz100`/`hz8`/`hzx` appear ANYWHERE in the paper**,
which is the only search that could test "states none of them".*
🔑 ***A SECOND WITNESS THAT CHECKS THE COMPONENTS AND WAVES THROUGH THE
CONCLUSION IS NOT A SECOND WITNESS. The conclusion had a wider scope than every
check I ran, and scope is the one thing I audit in everyone else's work.***

✅ **REPAIRED — math took (A) INLINE; all four binders now appear literally in
the LaTeX at :500-504, "engine's regime" is at ZERO occurrences, and the :521
"four explicit hypotheses" sentence is now TRUE. Re-fenced at the bytes, not
cleared on a status line.** *⚠️ This seat's FIRST re-fence used `grep -E` with
`\s` — which POSIX ERE does not support — and false-failed all four against a
correct repair. Caught because the printed theorem contradicted the tool. The
standing rule held: when the instrument fails work that just landed, the prior
is on the criterion.*

📌 *The pre-registration fork still resolved on its FIRST branch and the repair
still stands — the body theorem is self-contained and `:519` is now locally
true, which is strictly better than before. **What falls is the SIZE of the
finding, not the finding.** M1(d) caught a real locality defect; it did not
catch concealment, because there was none.*

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
