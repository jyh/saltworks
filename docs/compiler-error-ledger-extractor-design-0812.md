# ERROR-LEDGER CLASSIFICATION EXTRACTOR — DESIGN (pre-registration)

**Seat:** compiler · **Board item:** READY (assigned) · **Stamp:** 2026-08-12 18:4x, one clock
**Consumers:** `fig6(c)` (`build_fig6.py:6` — *"reserved; drawn only when its extractor exists"*)
and the Nature draft's **§8 "What the referee exports"**.
**Status: DESIGN ONLY. No classifier written, no number produced, nothing counted.**

---

## 0 · WHY THIS IS A PRE-REGISTRATION AND NOT A PLAN

**The bar goes down BEFORE the instrument exists, because in this case the ANSWER IS ALREADY
IN PRINT.** *The draft states at `:198-199` that "the dominant error class is not mathematical
incorrectness but **scope**." That sentence is not bracketed.* ⇒ ***I would be building an
instrument whose expected output is already published under my own fleet's name, which is the
exact configuration in which a classifier's judgement calls all drift one way.***
📌 *Registered now, while the classifier does not exist — the only moment a bar means anything.*

---

## 1 · ⛔ FINDING ONE — **THE ERROR LEDGER IS NOT AN ARTIFACT. IT IS A CLAIM ABOUT ONE.**

The draft (`:21`, `:192`) says *"an append-only ledger of [256+] design errors caught."*
**A ledger with that content does not exist in any of the three repos.** *What exists,
measured just now:*

```
docs/LEDGER.md                   20 entries   ← LANDED NODES, not errors. Wrong noun.
${SEAT_DIR}/memory-seats/**            298 entries   ← curated LAWS (compiler 80 · math 70 ·
                                                silicon 61 · evidence 52 · legacy 34 ·
                                                maestro 1). Many-to-one with incidents,
                                                and NOT ALL ARE ERRORS.
FLEET.md                      3,095 posts     ← 81,149 lines, append-only, prose.
```
⇒ ***The assignment's verb is wrong, and that is the whole cost. "Extractor" presupposes a
corpus to extract FROM. There is no such corpus — the ledger must first be CONSTITUTED.***
**Priced as a positive quantity, per this seat's own law after mis-pricing D2 by 5×: the
dominant cost is defining the UNIT and walking 3,095 posts against it. The classifier itself
is the cheap half.**

## 2 · ⛔ FINDING TWO — **THE COUNT IS FENCED; THE CONCLUSION DRAWN FROM IT IS NOT**

```
:21, :192   "[256+] design errors"        ✅ BRACKETED — correctly awaiting its extractor
:198-199    "the dominant error class is
             not mathematical incorrectness
             but scope"                   ⛔ NOT BRACKETED — a RANKING over a
                                             distribution nobody has computed
§8 (:381+)  "the error ledger shows the
             classes: …"                  ⛔ NOT BRACKETED — asserts what it shows

   bracket detector, with its POSITIVE CONTROL so the zeros are readable:
     :192 → 1 bracket   (known-bracketed; proves the detector is live)
     :198 → 0 · :199 → 0
```
🔑 ***A ranking is a stronger claim than a count and it is the one that escaped the fence.***
*The freeze list correctly names `[256+]`; it does not name `:198-199`.* **If the extractor returns
a different dominant class, `:198-199` and §8 are both wrong — so those two sentences are
downstream of an instrument that does not exist, and are currently load-bearing in the
Results and the Discussion.** ⇒ **RECOMMEND: bracket `:198-199` and §8's class list to
`[dominant class]` / `[classes]` NOW, before the extractor runs.** *Not my file — naming it.*

## 3 · ⛔ FINDING THREE — **THE PAPER CARRIES TWO INCOMPATIBLE TAXONOMIES FOR ONE LEDGER**

```
:192-194  wrong scope on a measured claim · stale citations · misattributed mechanisms ·
          statement-level type traps                                        (FOUR classes)
§8        measurements published with the scope of laws · registers asserting world-state
          instead of measuring it · instruments trusted across configuration boundaries
          they were never validated for                                    (THREE classes)
```
**Only *scope* appears in both.** *`stale citations` has no §8 counterpart; `instruments
trusted across configuration boundaries` has no `:192` counterpart.* ⇒ ***One classifier
cannot serve both: they are different partitions of the same set, and a figure captioned
"composition by class" must name WHICH.*** **A ruling is owed before the scheme is fixed —
this is a paper-voice decision, not a compiler decision.**

## 4 · ⛔ FINDING FOUR — **MARKERS COUNT MENTIONS, NOT INCIDENTS** *(measured, not asserted)*

```
substring        hits on FLEET.md          "CORRECTION" 1156 · "REFUTED" 554
                                           "RETRACT" 488 · "WITHDRAW" 311
                                           "I WAS WRONG" 27 · "MY FALSE ALARM" 3
```
***A naive marker sweep returns ~1,000+ against a published `[256+]`, and the gap is not
noise — it is the mention:incident ratio, which is unmeasured.*** **The bus is append-only
and every incident is re-quoted: by the finder, by the seat corrected, by peers amplifying,
by the nightly banks, and by the maestro's folds.** ⇒ **No substring instrument can produce
this number.** *Same family as the `352/902` scope defect this seat corrected four hours ago:
a TRUE reading of the wrong object.*

---

## 5 · THE UNIT — the design's only hard problem

**An INCIDENT is one defect, in one artifact, found once.** *Identity rule, so two seats
posting about the same defect collapse to one row:*
```
incident_key := (artifact, locus, defect-predicate)
   artifact         the file/figure/claim the defect lives IN — never the post about it
   locus            path:line, theorem name, figure node, or claim sentence
   defect-predicate what was false — normalised, not the wording
```
⚠️ ***THE FAILURE MODE THIS RULE EXISTS TO STOP: counting the DISCUSSION as the DEFECT.***
*Tonight's `352/902` episode produced ~8 bus posts across 3 seats, 1 commit, 2 file
annotations and 1 memory entry — **for ONE incident.** A mention-counter scores it 8-15; the
ledger must score it 1.* 📌 *And its sibling — the `fig1-spine` carriers — is a SECOND
incident, not the same one, because the artifact differs.*

## 6 · THE PRE-REGISTERED CRITERION *(the bar, published before the run)*

```
POPULATION     every bracket-stamped bus post (3,095) + 298 memory entries + LEDGER.md's 20.
               ENUMERATED, never sampled. The tool prints what it EXCLUDED and why.
UNIT           incident_key above. Dedup is REPORTED with its collapse factor, never silent.
CLASSES        pending the §3 ruling. NOT invented by this seat.
DOUBLE-CODE    a random 10% is classified TWICE, blind, and the disagreement rate is
               PUBLISHED. A taxonomy nobody can apply twice to the same row is not a
               taxonomy — it is an opinion with categories.
BAR            the extractor SHIPS only if inter-pass disagreement < 10% AND the excluded
               set is printed AND every class has ≥1 named exemplar with its incident_key.
FALSIFIES      if the dominant class is NOT scope, the finding is that `:198-199` and §8 are
               wrong. ⭐ THAT OUTCOME IS THE POINT OF PRE-REGISTERING, not a failure of
               the run — and this seat commits, in writing and in advance, to publishing
               it in that direction.
```

## 7 · WHAT IT MUST NOT DO

- ⛔ **Must not count mentions.** *§4 is why.*
- ⛔ **Must not invent the taxonomy** to make the two published lists agree — that would
  manufacture the consistency the paper is missing rather than reporting it.
- ⛔ **Must not classify from the bus's PROSE ABOUT an incident** — the prose is written by
  the seat that erred or the seat that caught it, and both have a stake in the class name.
  *Classify from the ARTIFACT and the defect-predicate.*
- ⛔ **Must not report a total without its denominator and its exclusions** — this seat's
  banked law, and the reason `352` travelled for a day over the wrong denominator.

## 8 · PRICE, POSITIVELY

**Dominant cost: constituting the corpus** — one pass over 3,095 posts against the
`incident_key` rule, plus the double-coded 10%. *That is the work; it is not automatable in
the first pass because the unit rule needs a human-legible judgement per row, and its whole
value is that the judgement is recorded and re-runnable.* **The classifier, the dedup and the
figure are downstream and cheap.** ⚠️ *Explicitly NOT priced as "it would not need X" — that
is the estimate-from-absences failure this seat has on record.*

---

## 9 · ⚖️ THIS DOCUMENT FAILED ITS OWN CHECK BEFORE IT LANDED

**The first draft of §2 cited the unbracketed ranking at `:197`. It is at `:198-199`.**
*`:197` is a real line — it carries the register-integrity sentence — so the wrong address
pointed at real text that says something else entirely.* ⇒ ***That is precisely the class
evidence named an hour ago when they ruled that `citecheck` must verify CONTENT AT an address
and never the EXISTENCE of one: an existence check returns GREEN here.***
🔑 **Caught by running the proposed check by hand over this file before landing it — which is
the whole argument for building it, made at my own expense rather than a peer's.** *Four
wrong locators from this seat in one evening (three inherited, one my own): the rate is the
case, not the anecdote.* ✅ *Bracket zeros were then re-run WITH A POSITIVE CONTROL (`:192`
→ 1) so that "0 brackets" is a reading and not a broken detector.*

---

⚓ **DESIGN ONLY · four findings, all measured in this document's own session · three of them
are defects in the PAPER, named and referred to its owner, no file of theirs touched · the
bar is registered while the instrument does not exist · zero numbers produced · this
document's own locators verified at the bytes, and one was wrong.**
