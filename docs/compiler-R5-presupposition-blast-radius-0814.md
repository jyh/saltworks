# §6-R5 — THE PRESUPPOSITION RULE'S BLAST RADIUS, MEASURED

**Seat:** compiler · **2026-08-14** · The hazard was flagged **before** the run, on the
bus at 09:29:33: *"§6-R5 is a token sweep over a speech-act rule, which is a class I have
failed at twice today."* It fired twice more. Both are recorded in §3.

## 1. THE ANSWER

B-5's concern: the presupposition rule *("never … again" / "no longer" / "can never hide
again" licenses the prior instance as stated)* is **"cheap prose and it is everywhere"**,
so every `EXCLUDED` row carrying a trigger is a row the rule moves back onto the ladder.

**Measured, it is not everywhere.**

```
POPULATION A — the EXCLUDED side (B-5's stated subject)         23 rows
  pass2's EXCLUDED (15) ∪ the ratified file's adjudicated EXCLUDED (9), 1 overlap
  (pass 1 excluded ZERO — this seat never used the class, the blind spot §6-R3
   measured; a sweep over pass 1 alone would have been vacuous by construction)

  rows carrying a trigger ..................... 1 of 23
  and it is 43903 — "the occupied-net class can never hide again"
  §2.1 NAMES 43903 as the rule's own birth case.
```
🔑 ***THE BLAST RADIUS ON THE EXCLUDED SIDE IS ITS OWN BIRTH CASE. THE RULE MOVES ZERO ROWS
IT HAD NOT ALREADY MOVED.*** *B-5 asked for this count "with the ratification papers" — it
is one, and the one is the row the rule was written from.*

## 2. THE WIDER POPULATION, AND WHY THE RAW COUNT IS NOT THE ANSWER

```
POPULATION B — all 388 coded rows (a DIFFERENT population, reported for context)
  raw trigger hits ......................... 14 of 388 (3.6%)
  GENUINE presupposition-triggers .......... 1  (43903)
  FALSE POSITIVES .......................... 13 (93%)
```
**Every false positive is `no longer` in a mundane state-change sense** — and reading them
is the only way to know:
```
968    "T2 no longer rests on an olean this machine never read"   ← a FIX reporting itself
60377  "decQ_encD NO LONGER EXISTS"                                ← a rename, executed
71379  ".gitignore:4 … no longer inert"                            ← a repair verified
42447  "B5 IS NO LONGER A HYPOTHESIS — IT IS ARITHMETIC"           ← a proof landing
28760  "the item is no longer blocked on anything mathematical"    ← a status change
81151  "banyan_fabric_nl.v:1752 no longer imports"                 ← and NOT a regression
```
⇒ ***"NO LONGER" IS OVERWHELMINGLY THE VOCABULARY OF A REPAIR ANNOUNCING ITSELF, NOT OF A
PRESUPPOSITION LICENSING A PRIOR DEFECT.*** *The two readings are the same eight characters.*

📌 **One near-miss worth naming: `63730` — "…AND THEN NEVER MENTIONED IT AGAIN FOR FIVE DAYS
AND 63,465 LINES." That row's prior instance is ASSERTED OUTRIGHT, not presupposed.** The
rule governs sentences whose *presupposition* does the work of stating the instance; a
sentence that states it plainly needs no rule. **Scored as a false positive for this rule
and it is still a real finding — the two questions are different.**

## 3. ⛔ THE TWO INSTRUMENT DEFECTS, BOTH PREDICTED, BOTH CAUGHT

**(a) `\bagain` matched inside "against".** The first sweep returned row `33785` on *"the
invariants state … never against length-fuel"*. **Third substring failure of the day** —
after `9` matching inside `1905`/`39087`, and after the morning's `^\[08/` missing
single-digit months. Fixed to `\bagain\b`; the hit vanished.

**(b) A raw count of 14 would have been reported as the blast radius.** It is 1. **A token
sweep over a speech-act rule has a false-positive rate set by how common the token is in
its other senses**, and `no longer` is the vocabulary of every repair this fleet has ever
announced.

✅ **WHAT CAUGHT BOTH: printing every member and reading it.** *The count was small enough
to read precisely because it contradicted an expectation — the standing rule that a
surprising count is an invitation to read, not to report.* ⚖️ **The pre-run flag was not
decoration: I named the failure class before the evidence existed, and the class arrived.**

## 4. WHAT THIS DOES NOT CLAIM

- **Population A is 23 rows and that is small.** Its size is itself a finding: the
  `EXCLUDED` class is barely populated today, so the blast radius could grow if a full
  sweep moves rows into it. **This measures the rule against the corpus as it stands, not
  against a post-sweep corpus that does not exist.**
- It does not evaluate whether §2.1 is *correct* — only how many rows it moves.
- 13 false positives are listed by row so any reader can re-judge them; **I read all 14 and
  a second reader may score the border differently on `63730`.**
