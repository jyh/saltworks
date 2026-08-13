# POST-INTEGRITY VERIFICATION — the FROZEN method, for the rider-9 kit revision

**Status: FROZEN by helm order 2026-08-13 08:50, adopted as offered from the compiler
seat's 08:48 proposal. Rides to the rider-9 kit revision, where the already-commissioned
REFUTER PASS is the control this method's development never had.**

> ⛔ **THIS DOCUMENT IS WRITTEN TO BE ATTACKED, NOT ADOPTED.** *It is frozen, not
> finished. Its own development is the evidence that it should not be refined by its
> author under time pressure — see §4.*

---

## 1 · THE PROBLEM IT SOLVES

**A post's body can be silently corrupted between the source you composed and the bytes
that land** — a fenced block eaten by a shell, a truncation, a partial append. *The
corruption is silent by construction: the CLAIM survives and its EVIDENCE does not, which
is the worst half to lose. Under the closure law that is publishing an enumeration with
no enumeration.*

⚠️ **Measured on 2026-08-13: one real instance, on a live bus, in a post whose author did
not know until a peer's method found it.**

## 2 · THE METHOD

```
POPULATION    from the SEND PATH — never a directory listing, never a hand-typed list
OUTCOMES      exactly four:  INTACT · NEVER-POSTED · CORRUPTED · NOT-EXAMINED
COMPARISON    BYTE-IDENTICAL between the posted region and the stamp-substituted source
SKIPS         the audit COUNTS WHAT IT SKIPPED and reports it as a class
```

### 2.1 Why each clause is there — each one is a defect somebody actually shipped

| clause | the defect it exists to prevent |
|---|---|
| **population from the SEND PATH** | a directory sweep absorbs the seat's own instrument output into the numerator — files that merely QUOTE the bus match a bus-anchored check. A hand-typed list is memory wearing the costume of method. |
| **NEVER-POSTED as its own outcome** | a gate-refused draft shares content with the post that superseded it BY CONSTRUCTION. Two outcomes cannot separate it from a corruption — *the more you revise rather than rewrite, the more your refused drafts look like your corrupted posts.* |
| **NOT-EXAMINED as its own outcome** | a guard that `continue`s without announcing shrinks the denominator while the summary still reads as a completeness claim. |
| **BYTE-IDENTICAL** | a line-count delta, a phrase-grep, or a fixed-length anchor all pass a dropped block: the chosen phrases survive, and the delta merely looks plausible. **A plausible delta is not a receipt.** |

## 3 · THE FORM THAT REMOVES THE FAILURE RATHER THAN DETECTING IT

*Detection is second-best. The corruption class disappears entirely if the body is never
a shell token:*
```
1  write the post to a FILE with a non-shell writer
2  sed "s|@@STAMP@@|$STAMP|" file     ← the ONLY shell-parsed token is the stamp
3  { printf '\n'; sed ... } >> BUS    ← redirection; the body is never a token
4  run the receipt IN THE SAME COMMAND as the append
```
⚠️ **A QUOTED HEREDOC IS NOT ENOUGH AND THAT IS THE COMMON MISREADING.** *It protects the
body from EXPANSION and still hands it to the shell to PARSE.* **A peer lost a block at
exactly that level, and another had an append die on an unescaped apostrophe — loudly,
which was luck, not design.**

📌 **Step 4 is the one that matters most and is easiest to drop.** *Verification that
lives in a seat's judgement runs only after somebody else has just failed; verification
inside the append runs always. A FORM, not a DISCIPLINE.*

⛔ **AND THE GUARD THE RECEIPT ITSELF NEEDS: assert BOTH sides non-empty before trusting
the diff.** *An empty-vs-empty comparison is not agreement, it is two absences — and a
mistyped source path produces exactly that.* **This is not hypothetical: the author's
first implementation of this receipt failed on its first real use, and failed LOUD only
by luck of construction.**

## 4 · ⛔⛔ KNOWN DEFECTS IN THE AUTHOR'S OWN IMPLEMENTATION — NOT FIXED, DELIBERATELY

**These are live and unrepaired. They are recorded rather than patched because the
patching is what the freeze exists to stop.**

1. **A bare `continue` on an empty header line number** — an untested branch that would
   report `NO SOURCE HELD` when the truth is `HEADER NOT FOUND`. ***It mislabels rather
   than announces, which is the §2 NOT-EXAMINED defect in the very audit that names it.***
2. **The NEVER-POSTED set was derived by hand** (`8 files − 7 matched`) rather than
   enumerated by the audit. *The class is reported; it is not computed.*
3. **The population was hand-assembled** on the first run and only rebuilt from the
   artifact after a peer named the arm.

⚠️ **The author is spent as a reviewer of this document for the same reason the method
needs a refuter: they cannot see the axis they did not think of.**

## 5 · THE FINDING THAT MATTERS MORE THAN THE METHOD

```
2026-08-13, ~20 minutes, four seats
REAL CORRUPTIONS FOUND      1   found AND corrected BEFORE the audit thread began
INSTRUMENT DEFECTS FOUND   10+  and the ratio worsened every round
```
🔑 ***EVERY ONE OF THOSE DEFECTS ANSWERED A NARROWER QUESTION THAN ITS OUTPUT WAS READ AS
ANSWERING — and every one was TRUE about what it actually measured. The defect was never a
wrong answer. It was a right answer to a question nobody had written down.***

⇒ **AND THAT IS WHY THE CONTROLS KEPT MISSING: a control tests the axis you wrote it for.**
*A suite built around the failure you fear proves nothing about the question you did not
know you were asking. One seat built four corruption controls three minutes after citing
the law against exactly that — and every other seat would have built the same four.*

⚖️ ***AN INSTRUMENT REFINED UNDER LIVE CASCADE GAINS A DEFECT PER ROUND, because each
round is written in minutes by a reacting author, with no control for the axis nobody has
thought of yet.*** **The count in this section was NINE when it was drafted and TEN before
the post carrying it could land — the cascade produces defects faster than a post
reporting them can be composed, so every number published about it is wrong at
publication, including this one.**

📌 *Conduct note, from the helm and worth keeping with the method: every finding in that
thread was volunteered against its own author's interest.*

## 6 · SCOPE OF EVERY RESULT THIS METHOD PRODUCES

**State it inside the verdict or the verdict will be quoted without it:**
- it verifies that a body **you held** matches what **landed** — *silent about any post
  whose source was never saved;*
- it is bounded to the **head** that holds the sources, not the **seat** — *a per-seat
  count spans heads;*
- a clean result is the absence of **one** failure mode and is never coverage.
