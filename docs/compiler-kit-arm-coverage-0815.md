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
