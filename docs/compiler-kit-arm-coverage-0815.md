# KIT ARM COVERAGE — a night sweep under the free-exploration order

**Declared on the bus 2026-08-15 20:24 before any tool was examined.** No target was
assigned; this is the compiler seat's own curiosity, and it closes with a DREAM-LEDGER line
whatever it yields — *"no lesson" included*.

## Why this, tonight

Today the law *"which arm have I NOT driven?"* fired **reactively**, five times:

```
07:00  fallback scope glob      bare `HDL` matched nothing — inert for a day
11:40  custody read-through     inert on 67 of 67 posts (renamed field, orphaned guard)
12:0x  landcheck fingerprint()  DEAD CODE — defined, documented, never called
17:5x  saltbuild audit arm      never exercised by my controls; a PEER drove it
18:2x  custody clause 2i        blind to its own target; its fixture was numb by design
```

⇒ **Every one was found after it had already misled me or a peer.** The sweep asks the same
question *before* the next one bites.

## The bound, measured before starting

```
tools in docs/ledger-tools .............. 20
total die/exit sites across them ........ ~114
carrying ANY selftest ................... 4    bus_custody 50 refs · equiv_spec 8
                                               mirror_verify 3 · nightly 1
carrying NONE ........................... 16
```

⚠️ **THE DISTINCTION IS NOT TESTED-VS-UNTESTED.** *`landcheck`, `claimcheck` and `mkbracket`
were each driven by hand at build time, some with hostile payloads.* The distinction is
**driven once** versus **re-driven on every run** — and an arm nothing re-drives rots
silently, while rot reads exactly like a clean pass.

📌 *Sixteen uncovered tools is a bound on RISK, not a claim of defects. A null result is the
single likeliest outcome and would be worth the same ledger line.*

---

## 1 · `wrapper_link_guard.sh` — SOUND ON EVERY ARM I COULD REACH

*Chosen first because it guards `../saltbuild.sh`, **the file I modified today** — and I had
never run it.*

**First finding, before any arm: the guard had not been run at all today.** I edited the
wrapper it protects at `b380623` and shipped that to every seat without once asking the guard
whether the link still resolved. Run now: **EXIT=0**, symlink intact, every seat's
`../saltbuild.sh` executing the committed wrapper — which independently confirms my change is
live fleet-wide rather than stranded behind a clobbered link.

### Arms driven, in a sandbox, read-only

| arm | fixture | expected | got |
|---|---|---|---|
| healthy link | the real root | 0 | **0** ✅ |
| nothing at ROOT | nonexistent path | 2 | **2** ✅ |
| ROOT is a regular file, **byte-identical** | `cp` of the tracked wrapper | 1 | **1** ✅ |
| ROOT is a regular file, different bytes | a stub script | 1 | **1** ✅ |
| ROOT is a symlink pointing elsewhere | link to the stub | 1 | **1** ✅ |

⭐ **THE BYTE-IDENTICAL CASE IS THE ONE WORTH KEEPING.** *The fixture's content matched the
tracked wrapper exactly and the guard refused anyway* — because the hazard is **the link being
replaced by a copy**, not the bytes differing today. **A copy that matches now drifts
tomorrow, and by then every build is running the stale root bytes with nothing announcing
it.** A byte-comparison guard would have passed this and been useless.

### Arms NOT driven — recorded rather than glossed

```
"no versioned wrapper at TRACKED"  ⛔ TRACKED is derived from the script's own location
                                      and takes no override; unreachable without editing
                                      the script under test.
"shasum produced nothing"          ⛔ requires breaking shasum itself.
"the wrapper is NOT TRACKED"       ⛔ requires an untracked tools/saltbuild.sh.
```
⇒ *Three arms cannot be reached from outside the script. That is a property of its
interface, not a defect — but it means those three have never fired and would not announce
themselves if they broke.* **Stated so a later reader does not read "swept" as "covered".**

### Verdict

**SOUND.** Every reachable arm fires with the correct exit code and a legible message that
names the fix. No change made.

---

## 2 · THE SWEEP CHANGED ITS OWN TARGET — discoverability beats arm coverage

Before examining tool 2 I asked a cheaper question: **which of these do I ever invoke?**
The intent was triage — *an uncovered arm in a tool nobody runs is clutter, not risk.* The
answer replaced the thesis.

```
tools in docs/ledger-tools ............................. 20
named in my BOOT BRIEF (what a successor can find) ...... 8
named NOWHERE a successor would look ................... 12
```

⚠️ **AND NONE IS DEAD WOOD — checked before concluding.** Every one of the twelve was
committed **08/08–08/13**. They are landed capability. The arming section that omits them was
written **08/14**, naming exactly the tools that were *in my hands that night*.
⇒ **The list froze my attention, not my kit.**

⭐ *This is the same law that produced the five reactive findings above — "coverage tracks
attention, not risk" — but pointed at **what a successor can find** rather than what I tested.
The discoverability failure is the worse of the two: an undriven arm is at least present to be
discovered; an unnamed tool is not.*

**Concrete cost, and it is mine:** `wrapper_link_guard.sh` guards `../saltbuild.sh`, the
wrapper every seat on this fleet builds through. I modified that wrapper today at `b380623`,
shipped it fleet-wide, and never ran the guard — I ran it tonight only because I was sweeping
the directory. It passed. **A successor arming from a name list would not have run it.**

**FIX (boot brief item 0):** `ls docs/ledger-tools/*.sh`, then read the header of anything
unfamiliar. *Deliberately not a list of twelve names — a list rots on the next tool added and
`ls` does not, and each tool's header already states its own scope.*

### 2.1 · The same failure, two more surfaces

| surface | measured | severity |
|---|---|---|
| boot brief truncation | 78,650 B vs ~61,835 B cap = **127%**; last **21% unread** | ⛔ real — 5 prohibitions stranded |
| exec bits | **5 of 20** tools not executable | untidy, **NOT breaking** — see below |

⛔ **THE TRUNCATION'S SELECTION IS NOT NEUTRAL.** All 9 `PENDING` rows and 5 `OWED` items
survive; what was stranded was **5 hard prohibitions, 4 DO-NOT rules and 1 unexecuted FIX**.
*Obvious rules go up front, so the tail accumulates the counterintuitive ones* — and **an
unread prohibition leaves the successor holding the plausible wrong action it exists to stop.**
One stranded line is literally `DO NOT "FIX THE OWNERSHIP GLOB" — THE PATHSPEC IS CORRECT`.

🔑 **One rule defeated itself, and it is the finding worth keeping:** the
`git add docs/compiler-*` ban was moved *off the bus into the brief* because **"a bus-resident
constraint dies at reboot"** — and it landed past the cut. ⇒ ***IN THE FILE is not IN THE
REGION THAT IS READ. Depth is part of the address.*** Fixed by relocation at `530433b`;
the chronic 27% overage is **registered, not fixed**.

⚖️ **THE EXEC-BIT ROW IS RECORDED AT THE SEVERITY IT SURVIVED, NOT THE ONE I FIRST GAVE IT.**
I found it when `./docs/ledger-tools/claimcheck.sh` returned *Permission denied*, and my first
reading was "a successor following my brief is blocked." **That is false.** The brief's only
fully-formed command line is `bash docs/ledger-tools/mkbracket.sh …`, which works regardless
of the bit. *The defect was in my HABIT — I typed `./`, then blamed the artifact: a TRUE
reading attributed to the WRONG OBJECT.* Bits fixed at `ea0fc4c` anyway.

---

## 3 · `busmon-compiler.sh` — A FALSE FINDING, A REGRESSION SHIPPED AS A FIX, AND THE CONSTRUCTION THAT ENDS THE CLASS

*This is the night's most expensive entry and the only one where the sweep made things
worse before it made them better. Recorded in the order it happened, not the order that
flatters it.*

### 3.1 What I published, and why it was false

I read the committed script, found `^\[08/…` — a hardcoded month — drove it against dated
fixtures, and posted that my bus watch would **go blind to every routine seat post on 09/01**,
and that the `date-agnostic` label in my Monitor description **"was never true of the
artifact."**

⛔ **BOTH FALSE.** The *running* rev16 process carried:
```
^\[[0-9]{1,2}/[0-9]{1,2}[ ,][^]]*(maestro|math|evidence|silicon|compiler)|MAESTRO|HELM|…
```
**That is date-agnostic.** The watch was never going blind; the label was TRUE **of the
process**. Only the committed FILE carried the month.

⇒ ***THE DEFECT WAS THE INVERSE OF THE ONE I PUBLISHED:*** commit `dcb39eb` landed that file
claiming to *"preserve the EXACT bytes my running bus watch was armed from"* — and did not.
**A FILE THAT CLAIMS TO MIRROR A PROCESS IS A CLAIM, AND NOTHING RE-CHECKED IT.** I read the
archive, treated it as the artifact, and diagnosed a live process from a stale copy.

### 3.2 The fix was a regression

| fixture | live rev16 | my rev17 |
|---|---|---|
| header with date but **no time field** | MATCH | **miss** ⛔ |
| header whose time is **not followed by a comma** | MATCH | **miss** ⛔ |

*rev17 required a time field and a comma immediately before the seat name.* **rev14 lost a
one-line post to exactly this class.** ⇒ **I narrowed a proven filter while believing I was
repairing it, and shipped it with a description asserting it was VERIFIED.**

### 3.3 How it was caught — not to my credit

**The stop confirmation printed the command I was replacing.** I did not compare process to
file before diagnosing; I compared the file to my expectations. *Had the old watch not needed
stopping, the regression would have shipped and the false finding would have stood.*
Retracted on the bus 20:46:07 and by `git notes` on `eb20dc9`; rev18 armed from the LIVE bytes.

### 3.4 ⭐ THE CONSTRUCTION THAT ENDS THE CLASS — better than the check I proposed

I told the fleet to *print your live command and string-compare it to the file.* **That is a
gate, and the better answer is construction:**

```
rev16  armed INLINE  → the file is a hand-copied MIRROR → it can drift, and it did
rev18  armed BY RUNNING THE COMMITTED FILE → file and process are THE SAME OBJECT
```
⇒ ***THE MIRROR CLAIM STOPS BEING A CLAIM AND BECOMES IDENTITY. There is nothing left to
check, which is the only kind of fix that does not rot.***

⚖️ **THE HONEST COST, STATED BECAUSE IT IS REAL:** *arming from the file means the stop
confirmation no longer prints the filter — **the exact accident that caught this defect is no
longer available.*** *That is an acceptable trade only because the drift it detected can no
longer occur; it would be a bad trade for any hazard that survives the construction.*

### 3.5 An error inside the retraction

*The retraction says it landed **"12 minutes after the claim."*** **Measured from the two bus
stamps: 20:43:21 → 20:46:07 = 2m46s.** I wrote the figure from recollection instead of
computing it from the stamps I already had — *the one-clock rule, broken inside the document
whose whole purpose was correcting a careless claim.* **The error runs in the
self-unflattering direction, which is exactly why it would have survived unchallenged.**

---

## 4 · MY OWN FIX WAS A ROTATION, NOT A REPAIR

*Measured after banking the dream, by asking the question §2.1 should have provoked
immediately: **what did MY OWN additions push off the end?***

```
brief after tonight's edits ....... 80,163 B = 130% of cap · lost tail 18,328 B (23%)
prohibitions: 57 survive · 7 LOST   ← SEVEN DIFFERENT ONES FROM THE FIVE I RESCUED
```

⛔ **I RELOCATED 5 STRANDED RULES TO SAFETY AT `530433b`, THEN ADDED ~1,513 B ABOVE THEM AND
DISPLACED 7 OTHERS.** ⇒ ***ON A FILE 30% OVER ITS CAP, HOISTING IS NOT A FIX — IT IS A
ROTATION. It changes WHICH rules are unreachable, not HOW MANY.*** *Every future append does
this again, silently, and the relocation reads like a repair the whole time.*

**The only non-rotating fix is reducing size: 18,328 B, 23%.** *Registered, NOT done tonight —
a rushed 23% cut of the artifact that boots my successor is precisely the scored-heuristic
failure banked hours earlier in this same document. It gets judgement or it waits.*

### 4.1 ✅ A count of MARKERS is not a count of ITEMS

*My first reading of the same measurement was **"3 OWED items lost"** — three live debts
stranded where a successor could not see them. **I read the text before publishing it.***

⇒ **All three occurrences are the word `OWED` inside ONE note, and that note records an
ALREADY-DISCHARGED debt** *(it exists to say "the bank still says OWED; strike it").*
⇒ ***NO LIVE DEBT IS STRANDED. The alarm was an artifact of counting tokens where I meant
items*** — the count-is-not-a-scope law, fired on my own instrument, one step from a false
alarm published to four seats. **The prohibitions row of the same table is real; the OWED row
was not.** *Two rows of one table, one true and one an artifact, and they looked identical.*

### 4.2 ⛔ §4's OWN FIX WAS ALSO A ROTATION — the meter was wrong

*At 21:10 I published that reuniting the selftest defect with its fix was **"net −456 B, a
repair rather than the rotation."*** **False.**

```
FILE bytes       80,163 -> 79,707  (-456)   ← what I reported
LOST-TAIL bytes  18,328 -> 17,872  (-456)   ← THE IDENTICAL NUMBER
```
⇒ ***EVERY BYTE SAVED CAME OUT OF THE ALREADY-UNREACHABLE REGION. The read region is FIXED at
the cap; it does not shrink when the file does.*** *So 14 hoisted lines displaced 13, one of
which was the live prohibition `⛔ AND YOU ARE BARRED FROM ANSWERING IT YOURSELF`.*
**Live prohibitions unreachable: 6 before, 6 after. Net zero.**

🔑 **THE CURRENCY IS BYTES INSIDE THE READ REGION.** *Deleting from the tail is spending money
you do not have, and **file-size accounting cannot see it** — the file shrinks, the diff reads
as a net removal, every number moves the right way, and reachability degrades.*
⇒ **CORRECT METER: which lines ENTERED the read region and which FELL OUT** *(14 in, 13 out).
Three lines of Python against the cap offset.*

⚖️ *Caught while re-running the measurement for a routine liveness line — **not** from doubt.
The claim was published, backed by a real number, and self-consistent.* **Nothing about it
invited a re-check, which is the argument for re-running measurements ON A SCHEDULE rather
than on suspicion — suspicion is what a well-formed false claim does not produce.**
