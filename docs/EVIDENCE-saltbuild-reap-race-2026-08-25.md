# The saltbuild lock reaper loses a live holder — reproduction, one-line fix, and the ordering constraint

**Filed 2026-08-25 by the evidence seat. `tools/saltbuild.sh` is the silicon/compiler
lane; this is a handover, not a change.** Everything below was driven, and the first
two attempts at driving it were wrong in a way worth reading before the fix.

## THE DEFECT

`tools/saltbuild.sh:16-25` reaps a lock whose holder is dead:

```sh
while ! mkdir "$LOCK" 2>/dev/null; do
  if [ -f "$LOCK/pid" ]; then
    if ! kill -0 "$(cat "$LOCK/pid" 2>/dev/null)" 2>/dev/null; then rm -rf "$LOCK"; continue; fi
  fi
  ...
```

The pid is read, judged dead, and **then** acted on. Between those, another waiter can
reap the same corpse, acquire, and become the live holder — and this waiter's `rm -rf`
then deletes **a live lock**. Both proceed. The lock is machine-global and the payload
is a Lean build.

## THE REPRODUCTION, AND THE CRITERION THAT MAKES IT ONE

⛔ **Two earlier harnesses "reproduced" this and neither did.** Their criterion was *did
both waiters print ACQUIRED* — and **correct serialization prints that too**: the first
holder finishes, exits, and the second legitimately reaps a now-dead lock. Both runs
passed and were read as failures.

***A CRITERION THAT BOTH ARMS PASS IS NOT A CRITERION.***

The discriminator that works: **the holder re-reads its own pid file DURING its hold.**
A clobber is then visible as the file naming somebody else while you still hold.

```sh
# both waiters started SIMULTANEOUSLY so both read the corpse before either reaps
echo "$$" > "$LOCK/pid"
for i in 1 2 3 4 5 6; do
  sleep 0.1
  now="$(cat "$LOCK/pid" 2>/dev/null || echo GONE)"
  [ "$now" != "$$" ] && { echo "CLOBBERED while holding: [$now], I am $$"; exit 1; }
done
```

Result, same harness and timings, one line of the reaper changed:

```
UNGUARDED (as written)     B CLOBBERED while holding — pid file [36296], I am 36295
                           C held cleanly          => two holders at once
GUARDED (one line added)   B held cleanly · C held cleanly
```

## THE FIX

```sh
DEAD="$(cat "$LOCK/pid" 2>/dev/null)"
if ! kill -0 "$DEAD" 2>/dev/null; then
    [ "$(cat "$LOCK/pid" 2>/dev/null)" = "$DEAD" ] && rm -rf "$LOCK"   # re-verify
    continue
fi
```

⚠️ **The obvious atomic fix does NOT work, and it is the first thing to reach for.**
Reaping by rename — only one racer wins a `rename(2)` — fails here: the loser's `mv`
succeeds because the winner has **already recreated** the lock, so it renames away a live
one. **Atomicity protects two simultaneous acts on ONE object; it does nothing when the
object has been REPLACED between your decision and your act.** Re-verify what you judged;
do not make the judging atomic.

## SEVERITY — ⛔ MY FIRST ESTIMATE WAS WRONG AND IS CORRECTED HERE

**Originally filed as:** *mechanism proven, probability not measured, low probability because
two waiters must reach the reap branch nearly together.* **That understated it, and the
correction is the compiler seat's, on their measurement rather than mine.**

⛔ **THERE IS A SECOND, FAR MORE REACHABLE PATH TO THE SAME OUTCOME.**
`trap … EXIT INT TERM` **runs at SIGNAL-DELIVERY, not at the exit line — and on a signal it
runs AGAIN at exit. It fires TWICE.** The second fire is an unguarded `rm -rf "$LOCK"` that
deletes **whatever is at the path now**. Between the two fires the process is still shutting
down and appending its audit line, so the window is not microseconds — it is the whole
shutdown, and it opens **on every SIGTERM**. Tonight produced an `EXIT=143`.

⇒ **The defect is not rare-and-severe. It is reachable on any signalled build**, and the
reap race I filed is the *narrower* of the two paths, not the main one.

⚠️ **STILL NOT MEASURED: whether it has ever actually fired.** No claim is made.

## ⛔ OPEN QUESTION — DO THE TWO GUARDS COVER EACH OTHER? UNVERIFIED.

There are two candidate one-line fixes and they sit in **different places**:

* **trap-side** (compiler's): release only what you own — guard the trap on the pid file
  still naming you. Aimed at the double-fire.
* **reap-side** (this file's): reap only the corpse you judged — re-verify before `rm -rf`.
  Aimed at the check-then-act race.

**I believe both are needed and neither subsumes the other. I could not demonstrate it.**
My composition harness produced *contradictory output* — one arm printed both "clobbered"
and "no clobber" — so I am recording the question as OPEN rather than publishing a
conclusion from an instrument I no longer trust.

🔑 **THREE OF MY HARNESSES FOR THIS DEFECT HAVE BEEN WRONG IN ONE EVENING:** two "reproduced"
it with a criterion that could not fail, and the third contradicted itself. **The single
differential in the section above is the only result here I stand behind** — same harness,
same timings, one line changed. *Treat everything else as a lead.*

## ⛔ THE ORDERING CONSTRAINT, AND IT HAS NO DETECTOR

Ruled 2026-08-25: the guard lands **after** the in-flight builds finish and **before** the
no-spin rule is lifted — *the rule is what holds the gap closed, so the gap must close
before the rule does.*

**Nothing watches that ordering.** The lift is a decision, not an event any tool emits, and
if it happens first the gap reopens **silently and immediately** — no waiter, no error, no
red. This is a deferral whose expiry event is a human ruling.

⇒ **Whoever lifts the no-spin rule must check this file first.** That sentence is the entire
mechanism, and it is a convention, which is what this repo has spent the day learning is
not a mechanism.
