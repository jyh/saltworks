# The compiler seat's WATCH REGISTRY — durable AND discoverable

## ⛔ THE WORD "COMPLETE" BELOW IS WITHDRAWN (00:4x) — TWO HOLES, ONE FATAL BY CONSTRUCTION

**(a) MY DISCRIMINATOR KNEW ONLY 2 OF 5 SEAT PATHS.** *It matched `${SEAT_CONFIG_DIR}` and
`/.claude/` and nothing else — so `${SEAT_CONFIG_DIR}`, `${SEAT_CONFIG_DIR}` and
`${SEAT_CONFIG_DIR}` all fell into a bucket I labelled **UNKNOWN** and read as orphans.*
```
what I published .... COMPILER 5 · other-seat 5 · UNKNOWN 7
what is true ........ compiler 13 · maestro-lane 12 · math 7 · silicon 6 · evidence 5
                      · UNATTRIBUTABLE 3
```
**The "unknowns" were mostly my SIBLINGS, unrecognised because I only taught the walk two names.**

**(b) ANCESTRY IS BLIND TO ORPHANS BY CONSTRUCTION (evidence, 00:42) — AND ORPHANS ARE THE HUNT.**
*A watch whose parent shell died is reparented to `ppid 1`; the chain to a seat shell no longer
exists, so **no amount of walking will attribute it**. Machine-wide there is currently **1** such
orphan (pid 5629, a salt-project script, already claimed by math).* ⇒ ***A COMPILER ORPHAN WOULD
BE INVISIBLE TO EVERYTHING IN THIS FILE.*** **That hole cannot be closed by a better walk — only
by a legible command string, which is a convention, not a guarantee.**

⚖️ *So this is the FIFTH count in this file and the first one that names what it cannot see.*
**Read the table below as: identified, attributable, and non-orphaned — three qualifiers, all
load-bearing.**

## IDENTIFIED CENSUS (2026-08-15 00:4x) — produced by the three-hop method

**DETECT** (`ps`, no name filter) → **ATTRIBUTE** (walk `ppid` to the shell whose snapshot path
names the seat) → **IDENTIFY** (read that shell's eval'd command). *All five were read from LIVE
PROCESSES, not from transcripts, memory, or descriptions.*

| age | shell | task-id | what it actually matches |
|---|---|---|---|
| 3d 08h | 59892/59907 | `bd1bcdlzl` | `cert_\|CERT\|Certs/\|comprehensib\|payload\|rotation\|compileS\|WhileSim\|IteScheme\|hub RED\|first-refuter` — cert-lane topic arm |
| 3d 05h | 94851 | — | `nohup /bin/sh /tmp/busstate-compiler.sh` — **forensic logger**, samples bus INODE/LINES/TAILPIDS every minute to `/tmp/busstate-compiler.log` |
| 2d 07h | 21686 | `b3ki008vg` | `b2d20534/scratchpad/fallback-compiler.sh` — 30-min sweep. **Its source file exists**, in a dead session's scratchpad |
| 13h | 78344/78359 | `b9tcmxnk5` | `^\[[0-9]{1,2}/[0-9]{1,2}[ ,][^]]*(maestro\|math\|evidence\|silicon\|compiler)\|MAESTRO\|HELM\|KILL\|REFUT\|CANARY` |
| 37m | 4013 | `bv38xejdz` | `fallback-compiler.sh` from the repo — corrected glob + drift arm |

⛔ **EVERY EARLIER COUNT IN THIS FILE WAS WRONG, AND EACH WAS WRONG THE SAME WAY:**
```
23:4x  3 watches   — from OBSERVED deliveries only
00:2x  4 watches   — after one more happened to fire
00:3x  5 leaves    — ps, but NAME-BOUNDED on `sleep` and `tail -F`
00:4x  8 shells / 19 processes — UNBOUNDED, and only this one is a census
```
*Each version was a floor presented as a total. **The fix was never a bigger grep — it was
dropping the name filter and walking one hop to an owner.***

✅ **TWO CAVEATS DISCHARGED BY THIS CENSUS, both of which I had published as permanent:**
1. *"I cannot identify which of 14 candidates is the live rev15."* — **Identified: shell 78344.**
   Its pattern has **no hardcoded month**, confirmed FROM SOURCE, and driven across 08/31,
   09/01, 12/31 and 01/01 it matches all four. **The month-boundary caveat is dead.**
2. *"bd1bcdlzl's filter is uncharacterisable."* — **Read directly; predicts 5/5 observations.**

📌 *silicon reported 78358's filter as `maestro|HELM|KILL|REFUT|CANARY` — that is the **tail of
the alternation**; the full pattern leads with the date-agnostic header clause. A partial read of
a long alternation looks complete because it ends where the eye stops.*

## ⛔ OPERATIONAL CONSEQUENCE — THE APPEND-ONLY LAW IS LOAD-BEARING ON THIS SEAT RIGHT NOW

*silicon, 00:34: `tail -F FLEET.md` is live on two seats, so an in-place rewrite would REPLAY
DAYS OF BUS.* **Measured here: 2 of the 3 live tails are THIS seat's** (pid 78358 at 13h, pid
59906 at 3d08h). ⇒ ***IF ANYONE REWRITES FLEET.md IN PLACE, MY SEAT EATS THE REPLAY.***
**Never truncate, never rewrite-in-place, never `>` the bus** — append only, per
`write-idiom-follows-the-reader`: append-only for a STREAMING reader, atomic temp+replace for a
SNAPSHOT reader, and truncate-in-place is correct for NOBODY. *The streaming readers are not
hypothetical; two of them are mine and one has been running for three days.*

## ✅ THERE *IS* AN ENUMERATION METHOD — evidence found it 00:31, and it REFUTES what this file said

**I wrote below that the only way to learn a watch exists is to observe it fire. THAT IS FALSE.**
*evidence's method: `ps` for the long-running loops and compare ages against the session's own
age. It works, and it found watches on this seat that no delivery had ever revealed.*

⛔⛔ **ITS LIMITS, STATED BY ITS AUTHOR BEFORE I COULD HARDEN IT INTO A CENSUS (evidence, 00:34):**
***IT IS A FLOOR, NOT A CENSUS.*** *It cannot see:*
```
· a watch armed INSIDE a session by a prior head   — no age signal distinguishes it
· a cron or scheduled agent                        — not a process at all
· anything on another machine                      — ps is local
```
⚠️ **"AN ADOPTED FENCE OUTRUNS ITS INSTRUMENT."** *This file previously said the only method was
to observe a delivery — an UNDER-claim. The correction risks the OPPOSITE error, and would have
made it without this note: **a floor published as a census is the same defect pointing the other
way.*** **Both bounds are recorded here on purpose.**

⚠️ **IT NEEDS TWO REFINEMENTS, BOTH MEASURED HERE, AND WITHOUT THEM IT MISATTRIBUTES:**

**(1) `ps` IS MACHINE-WIDE, NOT SEAT-SCOPED.** *Five seats share this machine. A flat count of
`tail -n 0 -F FLEET.md` returns **3** — and they do not all belong to one seat.*

**(2) THE LEAF CARRIES NO IDENTITY — WALK `ppid` TO THE OWNING SHELL.** *A bare `sleep 1800` or
`tail -F` has nothing in its command line to attribute. Its PARENT shell sources a snapshot from
the seat's config dir, and THAT is the discriminator:*
```
${SEAT_CONFIG_DIR}/shell-snapshots  ⇒ COMPILER          /.claude/shell-snapshots ⇒ another seat
```
*Flat grep: 18 leaves UNATTRIBUTED. After the ppid-walk: COMPILER 5 · other-seat 5 · UNKNOWN 7.*

**THE THREE BUS TAILS, EACH RESOLVED IN ONE HOP:**
```
pid 78358  age 13:11:36     → 78344 ← COMPILER
pid 54242  age 08:20:48     → 54228 ← other-seat
pid 59906  age 3d 08:03:12  → 59892 ← COMPILER     ⛔ THREE DAYS OLD, NEVER IN THIS REGISTRY,
                                                      and no delivery ever revealed it
```
⇒ ***THE OBSERVATION METHOD MISSED A THREE-DAY-OLD WATCH ON MY OWN SEAT.*** *That is the cost of
the lower bound this file used to call the only option.*

📌 **evidence reported "my seat carries 3 bus tails, one 3d08h old." By the chain above, 2 of the
3 trace to `${SEAT_CONFIG_DIR}` — this seat — and 1 to another.** *I state that as my
measurement, not their error: they know their own config dir and I do not. **If the 3d08h tail is
theirs, then my discriminator is wrong and I want to know.***

## ⛔ COMPLETENESS BASIS (SUPERSEDED IN PART — see the enumeration method above)

**THIS IS A LOWER BOUND, NOT A CENSUS.** *There is no enumeration API — `TaskList` is the TODO
registry and returns "No tasks found" — so every row below was learned by **OBSERVING A WATCH
FIRE** and reading its task-id out of a notification header.* **A watch that has not fired since
you started looking is invisible to this method, and so is one whose output you did not
recognise as a watch.**

⛔ **PROVEN INCOMPLETE WITHIN ONE HOUR OF BEING WRITTEN.** *I published this table at 23:4x with
three rows. At 00:23 a **fourth** task, `bd1bcdlzl` ("bus arm 2 — cert-lane topics"), delivered a
post — and I only noticed because it duplicated one my main watch had also delivered. **Had it
carried unique traffic I would still not know it exists.***
⚠️ *And the recovery method documented below **could not recover its definition** — it found 7
others by shape+name and returned nothing for this one. **The instrument that makes watches
discoverable does not reach every watch.***

⇒ ***A MEMBERSHIP LIST IS NOT A CLOSURE.*** *Treat this table as "at least these", never "these".*

## What was armed at 23:45 on 2026-08-14 (revised 00:2x — see the basis above)

| task-id | what it does | armed by session |
|---|---|---|
| `b9tcmxnk5` | bus watch rev15 — date-agnostic FLEET.md matcher | `ba74d94a` (current) |
| ~~`bztnx4tzg`~~ | fallback rev3 — **RETIRED 08/15 00:00**, stale glob | `ba74d94a` |
| `bv38xejdz` | **fallback rev4** — calls `fallback-compiler.sh`; corrected glob + drift arm | `ba74d94a` (current) |
| `b3ki008vg` | 30-min fallback sweep + bus fingerprint | `b2d20534` — **Aug 12, two days dead** |
| `bd1bcdlzl` | "bus arm 2 — cert-lane topics, payload/rotation, hub red" — **DEFINITION NOT RECOVERED**; filter **UNCHARACTERISED** (see below); first observed 00:23 08/15 | unknown |

### ✅ `bd1bcdlzl` — IDENTIFIED AND FULLY CHARACTERISED (00:3x), superseding everything below it

**The `ps` trail did not just DETECT it — reading its PARENT shell's command line IDENTIFIED it.**
*It is the 3d08h tail, pid 59906 / parent 59892, and it belongs to this seat:*
```bash
tail -n 0 -F ${BUS} | command grep -E --line-buffered \
 'cert_|CERT|Certs/|comprehensib|payload|Payload|rot\^k|rotation|compileS|CompileS|WhileSim|IteScheme|hub RED|hub is red|HUB RED|first-refuter'
```
⇒ **The full method is three hops, and only the first two were known an hour ago:**
`DETECT (ps + age)` → `ATTRIBUTE (walk ppid to the snapshot path)` → **`IDENTIFY (read the parent's eval'd command)`**

**VALIDATED AGAINST EVERY OBSERVATION — 5/5, no exceptions:**
```
post        observed    filter predicts    matched token
c17         quiet       quiet              —
c18         quiet       quiet              —
c19         FIRED       FIRE               payload
c20         FIRED       FIRE               CERT
math 00:23  FIRED       FIRE               CERT   (inside "CERTIFY")
```
📌 **AND IT RESOLVES THE CORPUS PUZZLE THAT MADE ME CALL IT UNCHARACTERISABLE.** *I argued a
`cert` filter was refuted because "Transport certified" appears **255 times**. **The pattern is
CASE-SENSITIVE and has no bare lowercase `cert`** — only `cert_` and `CERT`. So it never matched
that string. **My reasoning was sound and aimed at a pattern that did not exist.***

⚖️ **NOT A DUPLICATE AND NOT FOR RETIREMENT:** *it is a topic-filtered arm on cert-lane subjects,
distinct from the general bus watch. It has been doing its job for three days.* **The defect was
never the watch — it was that I could not see it.**

### (superseded) `bd1bcdlzl` — what two samples did and did not establish
```
delivery 1  00:23  math's rollover post      shared token: CERTIFY
delivery 2  00:25  MY OWN registry post      contains cert-lane, payload, rotation, hub red
                                             — because I QUOTED ITS DESCRIPTION
```
⛔ **The filter is NOT characterised and I will not guess it.** *A bare `cert` match is refuted
by the corpus: "Transport certified" appears **249 times across ~494 posts**, so such a filter
would fire on most traffic, and I have seen this task twice.* **n=2, one of them self-caused.**

⚠️ ***DOCUMENTING A WATCH CAUSED THAT WATCH TO FIRE.*** *Writing its description into a post put
its own keywords on the bus, and it matched them.* **Your notes about your instruments become
traffic that your instruments observe** — the same law that made this file shadow the search
that finds watches, in its other mode: **a registry SHADOWS recovery searches and TRIGGERS the
monitors it documents.** *Expect both when you write one.*

⛔ **`b3ki008vg` is an ORPHAN and a DUPLICATE of `bztnx4tzg`.** It was left running
deliberately: it delivers, and silicon lost a cadence alarm the same night to their own
cleanup command — the cure ate the vital sign. **If you retire one, retire the orphan, and
prove the other alive first.**

## ✅ The rev3 → rev4 swap (08/15 00:00), done as a SWAP and not a gamble

**Order matters and this is the whole discipline: ARM, GET A RECEIPT, THEN RETIRE.** *rev3 was
publishing a wrong figure every 30 minutes — `my-landing=ef50705` (22:02) when the truth was
`ba7e486` (23:5x) — but a wrong-and-alive instrument still beats an unproven replacement plus
a retired original, which is how a seat loses its heartbeat.*

```
1. armed rev4 with an IMMEDIATE first tick, so the receipt costs seconds not 30 minutes
2. receipt   00:00:23  my-landing=ba7e486   ← CORRECT, and rev3 said ef50705 at 23:59:35
                                              both observable side by side
3. THEN retired bztnx4tzg
```
📌 **The stop returned rev3's full definition, byte-for-byte identical to what I had recovered
from a two-day-old transcript** — an independent validation of the recovery method documented
below, from a source that could not have been influenced by it.

⚠️ **rev4 is thin ON PURPOSE**: it calls `fallback-compiler.sh` from the repo rather than
carrying its own copy of the logic. **That is the whole point of this file** — when the glob
next needs fixing, you edit a tracked file and the watch picks it up, instead of a definition
being frozen inside a Monitor nobody can enumerate.

## ⛔ The claim I got wrong, and the correction

I published *"my fallback has NO SOURCE — readable output, unfindable source."* **Half right
and the wrong half was the loud one:**

- **TRUE:** there is no *script file*. That is why `fallback-compiler.sh` now exists.
- **FALSE:** that the definition was lost. **Every watch definition is recorded verbatim in
  the session transcript that armed it**, under
  `${SEAT_CONFIG_DIR}/projects/<project>/<session-uuid>.jsonl`. I recovered **7**,
  including the complete lineage of my own fallback (rev1 → rev2 → rev3) and the orphan's.

⇒ ***DURABLE ≠ DISCOVERABLE*** (math's law, 23:26). *The definitions were never volatile.
They sit behind a session UUID nobody can guess, in a config directory nobody thinks to
grep. **Recoverable in principle, unfindable in practice** — which is why this file is in
the repo instead.*

## ⚠️ How I nearly missed it: three extractors, three different failures

```
1. JSON field parse ("command"/"input") ....... 0 recovered  (wrong field)
2. regex  session…done  with [^"] ............. 0 recovered  (escaped quotes inside)
3. plain find-substring + slice ............... ALL 7 recovered
```
**The crude instrument beat the two sophisticated ones**, and both failures returned **0** —
*the exact number that confirmed the "no source" story I had already published.* A confirming
failure is unsought, not hidden. **I only kept digging because a bare `grep -l` had already
shown the string was in the file, so 0 was known to be wrong.**

## Recovery method (tested, not described)

⚠️ **RUN IT AND YOU WILL GET 36, NOT 7 — AND BOTH ARE RIGHT.** *The snippet below prints
every `while true; do … done` block it finds: **36 raw occurrences**. The **7** above is
the count of **DISTINCT** definitions after keying on the first line — the same watch recurs
across many transcript lines (tool call, tool result, later quotation). `len(x)` is not
`len(set(x))`, and the label always wants to claim distinct.* **I found this by running the
snippet I had just written into this file, which is the only reason the two numbers are
reconciled here instead of confusing you.**

```bash
# List every watch definition this seat has ever armed:
python3 - <<'PY'
import glob, os
D=os.path.expanduser("${SEAT_CONFIG_DIR}/projects/-Users-jyh-projects-claude-saltworks")
for p in sorted(glob.glob(D+"/*.jsonl"), key=os.path.getmtime, reverse=True):
    for line in open(p, encoding='utf-8', errors='replace'):
        i=line.find("while true; do")
        if i<0: continue
        j=line.find("done", i)
        if 0 < j-i < 1600:
            print(f"--- {os.path.basename(p)[:8]} ---")
            print(line[max(0,i-120):j+4].replace('\\n','\n').replace('\\"','"'), "\n")
PY
```

## The definitions, verbatim as recovered

**`b3ki008vg` — the orphan sweep (session b2d20534):**
```bash
BUS=${BUS}
while true; do
  sleep 1800
  echo "FALLBACK-SWEEP $(date '+%H:%M') lines=$(wc -l < "$BUS") last-bus: $(tail -1 "$BUS" | cut -c1-110)"
done
```

**`bztnx4tzg` — fallback rev3.** ⛔ **Its glob is the defect corrected at `351ae5c`** — it
reads `SaltWorks/HDL SaltWorks/Certs 'docs/compiler-*' 'docs/post-integrity-*'`, which
**excludes `docs/ledger-tools/`**, where every landing of 2026-08-14 went. Reading it here
in its SOURCE confirms what I had previously diagnosed only from its OUTPUT.
```bash
cd /Users/jyh/projects/claude/saltworks
while true; do
  sleep 1800
  D=$(date '+%m/%d %H:%M:%S')
  MINE=$(git status --porcelain --untracked-files=no -- SaltWorks/HDL SaltWorks/Certs docs | wc -l | tr -d ' ')
  OTH=$(git status --porcelain --untracked-files=all -- SaltWorks/HDL SaltWorks/Certs docs | grep -c '^??' || true)
  UNP=$(git log --oneline origin/master..HEAD 2>/dev/null | wc -l | tr -d ' ')
  MYLAND=$(git log -1 --format=%h -- SaltWorks/HDL SaltWorks/Certs 'docs/compiler-*' 'docs/post-integrity-*' 2>/dev/null)
  ANYLAND=$(git log -1 --format=%h -- SaltWorks/HDL SaltWorks/Certs docs 2>/dev/null)
  SEED=$(shasum -a 256 docs/ledger-incidents-seed-0812.json 2>/dev/null | cut -c1-12)
  echo "FALLBACK3 $D · my-landing=$MYLAND (glob: HDL,Certs,docs/compiler-*,docs/post-integrity-*) · last-touch-in-shared-paths=$ANYLAND (ANY seat) · MY-tracked-dirty=$MINE · untracked-not-mine=$OTH · unpushed=$UNP · seed=$SEED"
done
```

**The replacement** is `docs/ledger-tools/fallback-compiler.sh` (`351ae5c`, corrected glob +
a drift arm that names directories touched outside its own scope, so the next time the scope
goes stale it says so). **Arm it in a loop; do not re-type the glob from memory.**
