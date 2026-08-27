# PRIORITY-AWARE BUILD QUEUE — design, ahead of the code
silicon, 2026-08-27. Commissioned to this seat at the council (minute `bc381f78`, helm 11:5x,
"not urgent — NDF first"). This file is the design; **no code has been written and nothing
installed.** It is written now because the NDF measurement is blocked on the marker and design
costs no lock.

## 1 · ⛔ THE HAZARD THAT DECIDES WHEN THE CODE MAY LAND, NOT JUST WHAT IT SAYS
`saltbuild.sh` is **being executed right now** — math's `Salt.MR.All`, pid 41899. Measured with
`lsof`: bash holds it on **fd 255r**, i.e. the interpreter reads the script *incrementally* while
it runs. ⇒ **an in-place edit of a running copy can fault it at a line that lints clean**
(evidence's `an-edit-is-a-rebase-to-the-interpreter`, banked this morning; their own reproduction
attempt failed, so the incident is the measurement and the byte-offset story is the standard
account, not a measured one). **The risk is PER-INODE**, so writing new files is safe and editing
math's copy is not.
⇒ **LANDING RULE: the integration edit happens only when no build is running, and it is written
to a new file and moved into place, never edited in situ.**

⛔ **AND IT MUST REACH TEN COPIES.** Measured: `saltbuild.sh` exists at **10 paths** under
`~/projects/claude`, **all byte-identical today** (`sha256 6942473aaacd…`). *That they agree now is
luck, not a mechanism* — [[the-tool-you-patched-is-not-the-tool-they-run]]. The delivery step must
enumerate and verify all ten, and publish the sha every seat must see.

## 2 · THE RATIFIED SHAPE (recorded verbatim in substance, so a later hand need not re-derive it)
Two classes (P1 · P2/P3) · **ticket layer ABOVE the untouched `flock`+`mkdir`** — tickets decide
who may ATTEMPT, the primitives still guarantee exclusion · NO preemption · default class **P2**,
**P1 typed per build** · within-class **FIFO by ticket timestamp** · dead tickets **reaped by pid**,
**NO wait-timeout** (a long queue is a PLAN; anti-hostage lives in reaping) · census prints the
queue (class · age · seat) · **NO aging** (ripens-when = observed starvation hurting) ·
**supersedes the `TAPEOUT=1` lane**.

## 3 · WHY THIS IS SAFE, AND IT IS THE WHOLE ARCHITECTURE IN ONE SENTENCE
The head-of-queue test is **check-then-act**: between "I am head" and `flock`, a peer can acquire.
⭐ ***THAT IS FINE, AND IT IS THE POINT — CORRECTNESS NEVER DEPENDS ON THE TICKET ORDER.*** `flock(2)`
still provides exclusion and the 43 GB memory law; the tickets buy only FAIRNESS. A lost race costs
one out-of-order acquisition, never two concurrent builds.
⛔ *This is the one case where my banked "check-then-act needs SERIALIZATION, never re-verification"
does NOT apply, and the reason is worth stating: that law is about a race whose loss breaks a
GUARANTEE. Here the guarantee is held by a different mechanism, and only a preference is racing.*
⚠️ **PARTIAL ADOPTION STAYS SAFE BY CONSTRUCTION, exactly as the driven lane is:** a copy that has
not pulled the layer writes no ticket and waits for none — it races as before. **Fairness degrades;
exclusion and the memory law do not.** This property is inherited, not re-earned, and it is the
reason the layer may land in ten copies over time rather than atomically.

## 4 · THE REUSE SET — the lane's DRIVEN arms, named by the helm, kept
| lane arm (driven, in production since 08/27) | ticket form |
|---|---|
| marker-at-entry: `${LOCK}.prio.$$` written before acquiring | `${LOCK}.tkt.<class>.<ns>.<pid>` |
| `prio_live()` reaps by `kill -0`, so a crashed build cannot hold the fleet hostage | same, hardened (§6) |
| un-upgraded copy simply does not yield | un-upgraded copy simply writes no ticket |
| `trap … EXIT INT TERM` clears the marker | same |

## 5 · TICKET FORMAT AND THE ORDER
`${LOCK}.tkt.<class>.<nanoseconds>.<pid>` — every field is in the NAME, so the queue is readable
with `ls` and needs no parsing of file contents to order it.
Total order: **class ascending (P1 before P2), then timestamp ascending, then pid ascending.**
A waiter may attempt `flock` iff no *live* ticket sorts strictly before its own.
✅ **NANOSECONDS ARE AVAILABLE HERE AND I PROBED IT IN THE SHELL THAT WILL RUN IT, NOT BY TYPING**
([[your-shell-is-not-your-scripts-shell]]): `/bin/date +%s%N` returns real nanoseconds under the
tool shell, under `sh script.sh` **and** under `bash script.sh` — all three resolve to `/bin/date`,
which is BSD (`date --version` → *illegal option*) and still honours `%N` on Darwin 25.6.
The pid tiebreak makes the order **total**, so two waiters can never each believe the other is ahead.

## 6 · ⛔ REAPING BY PID IS NOT SUFFICIENT ON ITS OWN — AND THE RULING'S OWN REASONING SAYS SO
`kill -0 <pid>` succeeds for **any** live process the user owns. A **recycled pid** therefore makes
a dead ticket look alive **forever** — and with **no wait-timeout**, that is precisely the hostage
the ruling says reaping must prevent. The anti-hostage duty was moved *into* reaping, so reaping
has to actually carry it.
⇒ **Stamp the holder's process start time into the ticket at creation (`ps -o lstart= -p $$`) and
reap unless the pid is alive AND its start time still matches.** A recycled pid has a later start
time and the ticket is reaped.
⚠️ *Registered, not assumed: I have not yet driven a recycled-pid case. The arm ships with a test
that FABRICATES a ticket carrying a live pid and a mismatched start time and requires it to be
reaped — a check only ever run on passing input has not been shown to discriminate.*

## 7 · WHAT I WILL NOT BUILD, SO IT IS NOT INFERRED FROM SILENCE
* **No aging.** Ruled out; ripens-when is *observed starvation hurting*. A P2 behind a steady P1
  stream can wait indefinitely **by design** — that is the planning property, not a defect.
* **No wait-timeout.** The current lane's `MAXWAIT` yield-break is REMOVED for the queue; the
  ruling replaces it with reaping. ⚠️ *This is a behaviour change to a running mechanism and it is
  named here rather than slipped in: today a yielding build gives up after `MAXWAIT` and acquires;
  under the queue it waits for the queue instead.*
* **No preemption, and no change to `flock`/`mkdir`.** Not one acquisition primitive is touched.

## 8 · OPEN, FOR THE OWNER'S WORD AT INTEGRATION TIME
1. **`TAPEOUT=1` transition.** It is superseded, but ten copies adopt over time. Proposal: accept
   `TAPEOUT=1` as an alias for `P1` for the life of the lane (expires 20260908 by its own text) so a
   half-migrated fleet has one meaning, not two. *Not decided here.*
2. **Class of a tape-out Docker run.** My LibreLane runs take the **marker** but never the `flock`
   (they are not `saltbuild`). They should take a **ticket** too, or the census under-reports the
   real queue. That is a change to *my* runners, not to `saltbuild`, and it is mine.
