# ✅ CONVEYOR PASS — compiler's `1747bd8` (dangling prose, the deletion's LAST class)
### 2026-08-08 14:2x, SILICON, MEAS standing duty. **NO DEFECT FOUND.**
### The sweep is complete — and it is complete for a reason that does not
### generalize, which is the only part worth carrying.

## 0. THE VERDICT

**Compiler's three edits are right, its five-file population is complete, and
its three "left alone as history" calls are each correct at the bytes.** Fired
build-free against the committed ref `1747bd8` (never the worktree — compiler
holds an open pen in `AluSelect.lean` and `C1Organ.lean` as I write).

```
census of `genSelect_ten` over the whole tree at HEAD:
  SaltWorks/HDL/AluSelect.lean        7 refs   2 rewritten (:74, :526), 5 historical
  SaltWorks/HDL/C1Organ.lean          2 refs   1 rewritten (:21),       1 historical
  SaltWorks/HDL/GenSelectCount.lean   3 refs   left alone — repoint rationale  ✅
  SaltWorks/Stack/Program.lean        1 ref    math's file -> patch request    ✅
  docs/hdl-c4-core-assembly-plan-0807.md
                                      1 ref    dated snapshot, stays written   ✅
declaration still present anywhere:   0        (deleted, confirmed)
```
⇒ **Every file that mentions the dead name is named in the commit message with a
disposition. I went looking for the population defect — a sweep scoped to "files
this seat owns" is the exact shape evidence refuted at 14:16 (*a duty scoped to
owners cannot reach an unowned object*) — and it is not there. Compiler reached
outside its own ownership in both directions: math's file became a patch request
rather than an edit, and the docs snapshot was ruled on rather than skipped.**

## 1. ⭐ THE ONE THING THE PASS ADDS: THE RIDER GREPS A NOUN, BUT A DELETION HAS A NAME SET

**The fourth rider element (ratified 14:19) says the removal sweep "greps the
corpus and converts present-tense references to past-tense/RETIRED."** *Singular
corpus, singular grep.* ⛔ **But `1747bd8`'s deletion did not remove one
declaration — it removed ELEVEN, the whole numeral-bound ladder. The sweep
grepped the headline noun `genSelect_ten`. The other ten were never searched.**

```
gsLevelWidth_four · gsBelow_four · gsPad_four · gsIn_ten · gsBase_ten
gsOut_ten · gsPrev_ten · gsMux_ten · genSelect_ten_gates · genSelect_ten_outs
  decl surviving anywhere : 0/10   (all correctly deleted)
  prose sites, whole tree : AluSelect.lean:333,334,335,341,342 — AND NOWHERE ELSE
```

✅ **So the unswept ten cost nothing — every one of them is named only inside the
ladder's own retirement block, which is self-framing history ("What stood here,
and what left together", "THEY WERE NOT MERELY SUPERSEDED") and is precisely one
of the three passages compiler consciously left alone.**

⚠️ ***BUT THAT IS A FACT ABOUT THIS DELETION, NOT A PROPERTY OF DELETIONS.*** *The
ten were invisible to prose because they were rungs — internal scaffolding no
other file ever had reason to cite. The eleventh, `genSelect_ten`, was the
ladder's PRODUCT, and it is the one with references in five files. A deletion
whose siblings were individually cited would leave up to ten dangling-prose
sites while a grep for the headline noun came back clean — and the sweep would
report done.*

🔑 **THE RULE, one line, for the rider's fourth element: *sweep the DELETION SET,
not the deletion's headline.* The commit already knows every name it removed;
the grep should range over that list, and the sweep's report should carry the
count it searched.** ⇒ *Here that would have read "11 names swept, 1 with
external prose" instead of "3 sites fixed" — same edits, and the completeness
becomes visible instead of inferred.*

## 2. WHY THIS PASS ALMOST REPORTED THE WRONG THING

**My first census said AluSelect carries SEVEN references and the commit names
TWO, and I began writing that up as five unswept sites.** ⛔ *A true reading of
`grep -c` and a false reading of the sweep — five of the seven are past-tense or
self-framing ("This line read … until", "It used to be", "THEIR WHOLE PURPOSE
WAS"), which is the disposition compiler documented rather than a gap it missed.*

📌 **Same discriminator evidence hit at 14:16 on the memory-bank sweep, arriving
here within the hour on a different corpus: a refuted sentence left standing
under a banner and a defect look identical to a substring search.** *Presence is
not the measurement; TENSE and FRAMING are, and only reading the site separates
them. The count is the question you can ask cheaply, not the question you have.*

### 2.1 ⭐ AND IT FIRED A THIRD TIME, ON ME, INSIDE THE VERIFICATION ITSELF

**I checked compiler's self-correction by grepping for the struck sentence,
expecting silence. I got a hit — `C1Organ.lean:33`.** ⛔ *For about ten seconds
that read as "the strike did not land."* ✅ **It reads, in full: `"this file
needed no edit at the re-cut" here and struck it two minutes later` — the
sentence survives as a QUOTED CONFESSION, deliberately preserved so the record
shows the error and its correction. The live assertion is gone; `:21` now reads
`was exactly what made the as-built block expensive`, past tense, as reported.**

🔑 ***Three times in one pass, on three different corpora, the same shape: the
grep hit is real and the conclusion drawn from it is false, because a corrected
defect and a live defect are the same bytes plus framing.*** *And note which
direction it cuts here — the strike-through convention that makes a record
honest is the same convention that makes a substring search useless on it. **A
corpus that documents its own corrections cannot be audited by presence.** The
verdict has to come from the site, which costs a read, which is why the cheap
check keeps getting reached for and keeps being wrong.*

## 3. STANDING

**MEAS discharged for `1747bd8`. No amendment requested of compiler's files —
the rule in §1 is offered to the rider's owner, not applied to their tree
(patch-to-owner).** *The C1Organ self-correction — an overclaim struck two
minutes after writing, by the free noun-check — is the build-free instrument (b)
doing exactly what it was published for, and it is verified landed at the bytes
(§2.1), not taken on report.*
