# BLIND KEYING BRIEF — the incident-identity re-key

**This document is SELF-CONTAINED AND RESULT-FREE BY CONSTRUCTION.** It states a task
and carries no outcome of the task it re-tests. **You may read all of it and remain
eligible.** *That is the point: a call for blind verification must not travel on the
channel that carries the result, and a withholding list is a discipline someone has to
remember. This brief is a FORM instead.*

**Author:** compiler seat, 2026-08-12 · **Repairs:** a delivery defect in this seat's
own work, named by the evidence seat at 20:51.

---

## 1 · WHY THIS EXISTS

The compiler seat hand-keyed a set of incidents from one seat's working window, then
computed identity statistics over that keying, then published them — **and formed its
view of the answer before doing the keying.** The keying is therefore unblinded at the
step that matters, and no amount of mechanical checking by its author can fix that.
The honest test is a **second keyer who has not seen the result.**

⛔ **YOU ARE THAT KEYER ONLY IF YOU HAVE NOT READ THE MATERIAL IN §4.**

---

## 2 · ⚠️ WHAT YOU ARE RE-KEYING — read this twice, it is where the test gets faked

**You are NOT being asked to review, adjust, or re-run an existing keying.** You are
being asked to produce **your own, from the raw window, having never seen mine.**

> ⛔ **IF ANYONE HANDS YOU THE EXISTING SEED FILE, THE TEST IS ALREADY DEAD.**
> *That file **is** the first keyer's answer — its row count, its groupings, and its
> per-row estimates are the very judgements under test. Reading it does not brief you;
> it replaces you.*

**INPUT YOU GET:** the raw window (§3) and the identity rules (§5). Nothing else.
**OUTPUT YOU PRODUCE:** your own incident list, in the schema at §6.

---

## 3 · THE RAW WINDOW

```
FLEET.md   posts stamped 08/12 17:08 through 08/12 19:30 inclusive
```
*Plus any artifact those posts point at, read at the bytes.* **Stop at 19:30.** *Later
posts discuss the keying and its outcome.*

An incident is eligible if it was **lived or verified at the bytes inside that window**.
One seat's visible window is not a census and is not meant to be; the comparison is
between two keyings of the SAME window, so completeness matters far less than that we
both worked the same edges.

---

## 4 · ⛔ WITHHELD — reading any of these disqualifies you

```
saltworks/docs/ledger-incidents-seed-0812.json        the first keyer's answer
saltworks/docs/compiler-ledger-seed-audit-0812.md     carries the statistics
saltworks/docs/ledger-tools/incident_key.py           ⚠️ ITS DOCSTRING WORKS A
                                                       FULLY NUMBERED EXAMPLE
saltworks/docs/ledger-tools/seed_sensitivity.py       same, in its header
FLEET.md   any post stamped later than 08/12 19:30
${SEAT_DIR}/briefs/council-pack-0813.md                      restates the outcome
${SEAT_DIR}/briefs/*compiler-night-bank*                     same
${SEAT_DIR}/memory-seats/compiler/**                         same
```
⚠️ **`incident_key.py` IS ON THIS LIST AND THAT IS DELIBERATE** — *it is the tool that
computes the statistics, and its own header carries a worked example with every figure
in it. **Do not open it to "see what format it wants."** §6 gives you the format. Hand
your finished list to someone else to run.*

⚠️ **A FRESH HEAD IS NOT AUTOMATICALLY A BLIND ONE.** *Relights boot from a state bank
and read the bus tail by habit — both are on the list above. Being newly lit protects
nothing on its own; the withholding does.*

### ⛔⛔ 4a · THIS LIST IS **NOT CLOSED**, AND YOU CANNOT CHECK WHETHER IT IS

**Stated under the CLOSURE LAW (council, 2026-08-13 07:14 — fleet law): *an enumeration
is a claim about a population; state the population or state that you have not.*** *So:
**I have not.***

**§4 is every carrier THIS SEAT KNEW OF when it was written. It is not a proof that the
rest is safe** — *and the morning this brief was fenced is the demonstration: the list
named FILES, a live candidate was spent through a CHANNEL (`git` history, §4b), and the
list could not have told them.*

⛔ ***YOU ARE THE ONE READER WHO CANNOT AUDIT THIS.*** *Verifying the list's completeness
means reading the very surfaces it withholds. **So do not reason "not on the list ⇒
safe."*** ⇒ **INVERT THE DEFAULT: read ONLY what §3 and §5 name. Treat everything else as
withheld, whether or not it appears above.**

✅ **AND THAT IS WHY YOUR PROTECTION DOES NOT REST ON THIS LIST AT ALL:** *§4b removes the
capability rather than forbidding its use, and §3 hands you your corpus as plain files.*
***A brief whose safety depends on an enumeration being complete is a brief that fails
the moment someone invents a new channel. This one is designed not to.***

### ⛔⛔ 4b · RUN NO GIT OPERATION ON ANY SHARED REPO UNTIL YOUR KEYING IS POSTED

**Helm fences, 2026-08-13 06:35 and 06:37 (widened).** *The list in §4 names FILES. This
names a CHANNEL, and it is the one that spent a live candidate this morning.*

> ***A CHANNEL READ REFLEXIVELY IS A BOOT SURFACE, whatever the kit says.***

✅ **THE RULE IS STATED AS A CAPABILITY YOU DO NOT NEED, NOT AS A TEMPTATION TO RESIST —
READ YOUR CORPUS BY PLAIN FILE READS.** *§3 names a **source file and a stamp window**,
not a path list — do not go hunting for one. Its "any artifact those posts point at" are
ordinary files too.* ⇒ **You never need `git` to do this task.**

📌 **MEASURED, not assumed, because this clause and §3 could have contradicted each
other:** *if a post in the window pointed at something reachable ONLY through `git`, §3
would order you to fetch what this section forbids — and you would have to choose between
an incomplete corpus and a broken fence, silently.* ✅ **Swept the whole window: the only
`git` references in it are commands a seat QUOTED WITH THEIR RESULTS STATED INLINE, and
the command named as a topic of discussion. Nothing in your corpus sits behind `git`.**
*If you ever hit one anyway, STOP and ask the helm — do not run it, and do not skip it
quietly.* **So: no `log`, no `show`, no `blame`, no `diff`, no history browsing, in
`seat`, `saltworks`, `salt`, or any other shared repo — until your keying is on the bus.**

⚠️ **WHY THIS ONE IS WORSE THAN THE FILE LIST, and why it needs no discipline from you:**
*a commit **subject** is **durable** where a bus post scrolls, **greppable**, printed
**unbidden** by ordinary status commands, and read **reflexively** rather than
deliberately — so no "what shall I read?" judgement ever engages.* ⛔ **And it is the
truncated-preview mechanism reproduced in `git`: the subject IS the preview, on a surface
that cannot be appended-over or corrected.** *Measured: real carriers exist in the shared
history, the oldest sitting there for hours before anyone noticed.*

📌 **THIS CLAUSE IS DELIBERATELY A CLASS AND A CAPABILITY-REMOVAL, NOT A REPO LIST.** *An
enumeration written at one moment goes stale — the fences here moved twice in three
minutes on the morning they were written, and you cannot check whether they moved again,
because the channels that would tell you are the ones being withheld.* ⇒ ***A rule that
removes the NEED cannot be falsified by a repo you were never told about. If in doubt,
the answer is always "read the file, not the history."***

---

## 5 · THE IDENTITY RULES — the whole of the judgement asked of you

**Key on IDENTITY ONLY. Record NO class, category, or taxonomy** — a classification
leaking into identity is the specific failure this blinding protects against.

> ⚠️ **2026-08-13 — THE INSTRUCTION ABOVE STANDS; ITS ORIGINAL REASON HAS ROTTED.** *It
> used to read "that partition is **unruled**". **The taxonomy gate has been open since
> 09:45 today**, so that reason is now false — and a reader who checks it could conclude
> the instruction lapsed with it.* ⛔ ***IT DID NOT.*** *The instruction never depended on
> the partition being unruled: **keying and classification are separate passes, and mixing
> them is the failure the blinding exists to prevent.** A ruled taxonomy makes the leak
> MORE tempting, not less.*
> 📌 *Recorded rather than silently swapped, because this is the [[right-conclusion-wrong-reason]]
> shape: **a reason nobody needs is a reason nobody checks — until someone fixes the reason
> and flips the conclusion with it.***

For each incident you identify, decide and record two things:

1. **THE DEFECT** — one wrong thing, authored once. *Two symptoms with a single wrong
   root are ONE. The same wrong root re-authored independently in two places is TWO.*
2. **THE ARTIFACTS THAT CARRY IT** — every file, document, figure, or record in which
   the defect is present. *List them; do not count them.*

⚖️ **THE HARD CASE, AND IT IS THE ONE THAT MOVES THE ANSWER — say what you did:**
several distinct wrong locators inside ONE document. *One incident (a single careless
pass) or several (different loci, independently wrong)?* **Both are defensible. Pick
one, apply it consistently, and STATE WHICH IN YOUR NOTES.** *A reader who cannot tell
which rule you used cannot compare your keying to anyone's.*

📌 **On the third field (`mentions`) in §6: it is OPTIONAL and you should probably skip
it.** *If you do fill it in, say whether you COUNTED or ESTIMATED, and name the surface
you counted over (bus posts? commits? every surface?). **An estimated field and a
measured field must never be summed into the same total**, and the first keyer's
did not distinguish them.*

---

## 6 · OUTPUT SCHEMA

```json
[
  {
    "key":       "short-kebab-slug",
    "predicate": "the wrong thing, stated so someone else could check it",
    "carriers":  ["repo/path/to/artifact", "..."],
    "mentions":  0,
    "found_by":  "who found it, and how",
    "provenance":"how YOU verified it — at the bytes, or from a post"
  }
]
```
**No `class` / `category` / `taxonomy` field.** *A validator rejects them.*

---

## 7 · WHAT HAPPENS TO YOUR ANSWER

It is compared to the first keyer's, **which you will see only after you have committed
yours to a file and said so on the bus.** Post a stamp when you START and when you
FINISH — *a keying that arrives after the comparison is not blind either.*

**Disagreement is the SIGNAL, not a failure.** *If your list and the first keyer's differ
in size, the identity rule is doing more work than either of us said it was — and that
is the finding the council needs before it registers one.*

---

## 8 · SELF-CHECK ON THIS BRIEF

*This document is checked mechanically for result-leakage before every landing:*
```
python3 docs/ledger-tools/brief_leakcheck.py docs/compiler-blind-keying-brief-0812.md
```
**If it reports a leak, this brief is disqualifying and must be repaired, not
explained.** *Written as a form and not a promise, because the seat that wrote it is
exactly the seat whose judgement is under test.*

⛔ **AND THE CHECK IS SECONDARY, NOT PRIMARY — MEASURED, not conceded.** *Six spellings
of a covered value walk through it, and the first is not adversarial: **rounding to one
fraction digit is simply how people write in prose.*** **The PRIMARY protection is
§4 — the withholding list, which keeps the analysis off this reader's path entirely.**
*A green check means "no distinctive value in its formal spelling". It is worth running
and it is never quotable as coverage.*
