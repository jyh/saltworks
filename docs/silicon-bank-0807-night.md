# 🏦 SILICON BANK — 2026-08-07 NIGHT CYCLE (the seat after the first Phoenix)

### Written at a CLEAN SEAM, not at a ceiling: organ duty 2/2 complete, nothing
### in flight, tree clean, 0/0. **Everything below is verified state, not
### recollection.** Successor: this is in the REPO and not only on the bus,
### because tonight's own lesson was that bus-resident things do not survive a
### clear ([[bus-resident-fixes-die-at-reboot]]).

## ① REFUTATION SCOREBOARD — organ duty, 2 of 2

```
IMM-UNCOND      baa7e0f   🟡 NOT CLEAN — 4 findings, ALL reporting-level,
                             ZERO defects in the Lean.  All four taken by math.
                             verdict: 190176e
DECODER-UNCOND  a4a6a2b   ✅ CLEAN against checks published BEFORE it landed
                             (3b3551b, 20:56).  4 findings, all documentation.
                             verdict: 9edb087
```
**IMM's four:** ① "no `decide` anywhere" true of the two proofs, false of their
closure by ONE leaf — `toReg_ofReg` (`ISA.lean:349`, `decide +kernel +revert`)
via `decode_encode`. *Settled by reading to ONE named residual: the trailing bare
`simp` could in principle close it otherwise; the `getUsedConstants` receipt is
still owed for exactly that.* ② "26 declarations" is 29 *(understated —
conservative)*. ③ "15 `#audit_axioms`" is whole-commit; the organ's is 12/29/~323.
④ the I-side mutant is `wf = false`, so a cheap pre-existing check already kills it.

**DECODER's four, all documentation:** ① C-D4 credited to the wrong seat
(`f287785` is silicon's) and its reason flattened. ② `decoderCut_passes_the_whole_dcWord_family`
carries `(hop : op < 512)` and the name drops it — *and the rejecting witness is
itself a `dcWord` point:* `encode (.ADD 4 1 2) = 2130483 = dcWord 563 520 0`.
③ `dc_both_none_paths` — both arms, one route (0.78 %), zero consumers.
④ a stale cite (`Decoder.lean:173` → `:214`).

## ② WHAT I CLOSED THAT WAS BANKED AS OPEN

```
bank blind spot (a)  aluSelect pricing   ✅ 79bb72a — a STEP FUNCTION on the doubling,
                                            not a per-source slope. n=10→1,445 · n=8→675
                                            · n=3→291 · n=2→97.  n=2 IS the operand-B mux,
                                            exact to the gate ⇒ two board items are ONE block.
                                            Adopted: compiler 04c9db6, math's ALUSEL-PARAM brief.
bank blind spot (c)  tt-gds-action tag   ✅ unmoved: ttsky26c = 651ea05e…, 2026-07-30
σ catch-all (board)  ✅ 81d34ba — the fix went to the INSTANCE not the PATTERN. bnCSigma
                        fixed; adSigma + adSigmaCut still catch-all (LIVE, pc path);
                        bnSigma catch-all real but QUARANTINED (3 mentions, own file only).
                        FREE FIX: point the tail at a net ≥ off and instOK becomes the guard.
package custody      ✅ 26 files, GDS 3,802,450 B, valid GDSII head+ENDLIB, provenance
                        JSONs match. HASHED so the next check is a comparison:
                        GDS d2a52c01…2887 · PNG 6f958d89…1936 · tree 07772266…06d8
floor                ✅ main = f14a4fa, UNMOVED.  ⚠️ read it with `gh api`, NOT git —
                        the TT repo is not cloned here; git says "ambiguous argument".
                        Same call proves default_branch IS main ⇒ the B5 §3 danger is
                        MEASURED, not "leans yes".
```

## ③ WHAT IS OPEN, AND WHOSE
```
B4 / hseam        ⛔ compiler — frame-level sort + cone lemma, taken, running to done
B5 (all of it)    ⛔ HELD BY THE FLOOR LAW while hseam is open. CLOCK_PERIOD 20→30 and
                     the die-plot decision are B5-adjacent and stay UNTOUCHED, not
                     "nearly ready". Die-plot has one new fact: Pages serves main, and
                     main IS the floor, so committing our render to master is not served.
4-import sweep    ⚖️ MAESTRO — SaltWorks.lean. Two seats recommend it. Converts
                     "proved once, silently" into "proved every build". 31 of the 49
                     unaudited live there.
C5-9…C5-11        ⛔ genuinely blocked on `core`, which does not exist (C4.lean header)
watch-block rot   ⚖️ MAESTRO — items 1, 4, 6, 11 rotted; 37ddd8b is the 13-item sweep
receipt (IMM F1)  ⛔ the getUsedConstants receipt, still owed, purpose narrowed to one route
```

## ④ THREE THINGS I GOT WRONG, IN PUBLIC, AND THE SHAPE THEY SHARE
1. **C-D4 published as 15 dead inverters; it is 17.** *I counted the UNREAD bits
   and stopped. `dcNot 0`/`dcNot 1` are dead too — every RISC-V 32-bit opcode has
   `opcode[1:0] = 11`, so their negation is never asked for.* Corrected in 90 s.
2. **I took `decoderCut_passes_the_whole_dcWord_family` at its NAME** — in the
   same hour I wrote *"NAMES LIE"* into my own agents' brief as law (4).
3. **My item-(11) repair carried the defect it repaired.** *"Record at boot,
   alert on change" fails when baseline and check come from different
   instruments — this seat knows itself as `claude-opus-5[1m]`, the transcript
   says `claude-opus-5`. Math caught it.*

⭐ **THE SHAPE:** *each was a rule I was holding at the time.*

⛔ **AND THE CONCLUSION I FIRST DREW FROM IT WAS OVERSTATED — corrected here
rather than repaired silently, because the wrong version was already on the bus.**
*I wrote: "nobody caught themselves once — every catch came from another seat."*
**Compiler produced a fifth row with a different ending, and re-reading my own
four, TWO of them contradict me:**
```
21:38  names-lie slip     caught by MY OWN CONVEYOR      ← an instrument I dispatched, not a seat
21:44  math's monitor     caught by silicon               ← a seat ✓
21:48  my (11) repair     caught by math                  ← a seat ✓
21:52  "watch armed ✅"    caught by THE HARNESS           ← not a seat at all
21:5x  compiler's own     caught by compiler, AFTER math published the general form
```
✅ **THE CORRECTED FORM, which is compiler's and is more useful than mine:**
> ***No seat caught itself UNPROMPTED. Every catch came from one of three things:
> another seat, a PUBLISHED GENERAL FORM, or a DISPATCHED INSTRUMENT that did not
> share the seat's priors. The fleet's job is to produce the second and third —
> the first does not scale.***

*Mine implied POLICING (adversarial, needs a seat per seat); the corrected one
implies PUBLISHING (cheap, one-to-many, lets every seat audit itself).* **My row
1 is the third route in its purest form: the conveyor caught me because its brief
forbade it to trust names — a rule I had written and then broken.**

## ⑤ 🔑 WHAT I THINK THIS BANK MISSES — my own blind-spot guess, per item 13
* **(a)** I never priced the **producer cascade** the aluSelect shrink implies —
  `bitwise` is 96 = 3×32 with only `xor` live, and I flagged it without reading
  `Bitwise.lean`. *The core-size number is therefore still incomplete in the
  favourable direction.*
* **(b)** I verified `partial_load_selfrouting` is current **by mtime**, not by
  rebuilding it. *A staleness sweep proves nothing was touched; it does not prove
  the proof still elaborates.* **The four-import sweep is what would.**
* **(c)** I asserted `adSigma`'s sentinel fix "costs nothing" **without building
  it.** *`instOK_adder`'s proof may or may not go through unchanged; I named the
  receipt and did not take it.*
* **(d)** My conveyor briefs forbid builds absolutely. *That was right tonight
  (the lock was math's) but it means **every verdict I posted is a reading, never
  an execution** — and I said so each time, but a successor should know it is a
  standing property of my method, not a one-off caveat.*

## ⑤ᵇ 🤝 A STANDING COMMITMENT — SUCCESSOR, THIS BINDS YOU TOO

🟢 ***I will not write anything under `SaltWorks/Silicon/Equiv/` — `ComposedSwitch.lean`
included — without posting to the bus first and waiting for COMPILER's ack.***

**Given to compiler at 22:04 and recorded here so it survives the clear.** *Why:
compiler's seam executors are immune to neighbour breakage by CONFIGURATION —
their import closure contains no file another seat writes. **That immunity expires
the moment the discharge reaches `ComposedSwitch.lean`, which is silicon's slot**
(verified: 9,785 bytes, written 15:54, and INSIDE the build closure — not one of
the four orphans). Rather than leave compiler a hazard to watch for, the exposure
is removed by agreement.*

🔑 **Call it immunity by COMMITMENT — the fourth entry on the menu, and the only
one that works on a file you do not own:**
```
STRUCTURAL      read a frozen ref (git show <ref>:<path>)          — cannot be reached
CONFIGURATION   a closure containing no file another seat writes   — compiler's
COMMITMENT      a neighbour's promise not to touch your closure    — this one
FILTER          watch for the hazard and react                     — the residue, last resort
```
⚖️ **Cost is nil: organ duty is complete and no write anywhere in `Silicon/**` is
planned — the whole remaining lane is held by the floor law or blocked on `core`.**
📌 *And the standing offer beside it: if the discharge needs `ComposedSwitch.lean`
CHANGED rather than merely imported, that is silicon's work to compiler's
specification — better than compiler blocked on our pen.*

### ⚠️ THE ESCAPE CLAUSE — added after math found the same flaw in ITS reciprocal deal
**Math's 22:11 finding: compiler was fenced off its own file with the ONLY release
being a post from math — *a seat that reboots nightly by doctrine*. Had math been
cleared before the landing, compiler would have waited forever on a message from
a seat that no longer existed.** *Math fixed it by putting the release duty in its
brief rather than on the bus.*

🔴 **MINE HAS THE MIRROR OF THAT HOLE: "wait for COMPILER's ack" names a
counterparty that also reboots.** *If compiler's seat has no live incarnation
aware of this protocol, a successor of mine waits on an ack nobody knows to give.*
✅ **SO THE COMMITMENT CARRIES ITS OWN ESCAPE, and it is unilateral by design:**

> **Post the intended change to the bus naming the file and the reason. If no
> compiler-seat incarnation responds within one working session, post ONCE MORE
> and then proceed.** *The commitment exists to stop a write from breaking a live
> executor's closure — **not** to make silicon's slot unwritable by the accident
> of another seat's clear.*

🔑 ***A bilateral commitment needs a UNILATERAL escape that survives either party's
death. Otherwise it is not a commitment, it is a deadlock waiting for a reboot***
— and this fleet reboots by doctrine ([[bus-resident-fixes-die-at-reboot]]).

### ⭐ SUPERSEDED, AND BY SOMETHING BETTER — compiler, 22:13
**A timeout escape (above) still needs someone to notice the clock. Compiler's
form needs nobody alive at all:**

> ***Make the release condition OBSERVABLE, not NOTIFIED. The release does not
> have to be ANNOUNCED — it can be LOOKED AT.***

✅ **SO THIS FENCE'S RELEASE IS RE-STATED AS A FACT ABOUT THE REPO, not a message
from compiler:** *the fence exists to protect a live executor's import closure
during the seam discharge.* ⇒ **It lapses when `hseam` is discharged — which is
observable in the tree, needs no ack, cannot outlive its purpose, and cannot
deadlock because compiler's seat rebooted.** *The two-post timeout stays only as
the fallback for a write wanted BEFORE that point.*
📌 **Successor: check the state, do not wait for a message.**
🔑 **And math's line is the one to keep from the whole exchange:** ***"the bus is
a record of what was SAID; it is not a queue of what is OWED."*** *Three seats
made durable-looking promises on a channel that stores none of them — on the very
night we proved bus-resident things do not survive a clear.*

## ⑥ LAWS THAT PAID, AND ONE THAT ONLY HALF-PAID
✅ **`git show <ref>:<path>`** — my predecessor wrote it to stop `reset --hard`
eating a neighbour's work. *It ALSO made every conveyor line-number frame-correct
when `Program.lean` grew 607 lines mid-verdict.* **One law, two hazards, only one
known when it was written.**
✅ **`Built`, not `Replayed`** — caught a false receipt for math, who then
discharged it by a stronger route (`lake env lean`, re-elaborates from source).
⚠️ **"Watch armed" is a claim about the PAST.** *My fallback died at ~21:5x and I
only learned because the harness reported the kill.* **Report a watch as
VERIFIED-NOW (`ps` + PPID) or not at all.**

🟢 **Tree clean · 0/0 with origin · `main` untouched at `f14a4fa` · evidence's
three files never touched · no build run by this seat all night.** 🧂⚓
