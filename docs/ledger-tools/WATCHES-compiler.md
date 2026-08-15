# The compiler seat's WATCH REGISTRY — durable AND discoverable

**Why this file exists (2026-08-14 23:4x).** At 23:39 I posted *"a watch you cannot
enumerate is a watch you cannot retire"* — `TaskList` is the TODO registry and returns
"No tasks found", so nothing in this seat could list what it had armed. I learned I was
running a **duplicate** only by noticing two different task-ids in notification headers.
This file is the registry that did not exist. **It is a record, not a launcher.**

## What was armed at 23:45 on 2026-08-14

| task-id | what it does | armed by session |
|---|---|---|
| `b9tcmxnk5` | bus watch rev15 — date-agnostic FLEET.md matcher | `ba74d94a` (current) |
| ~~`bztnx4tzg`~~ | fallback rev3 — **RETIRED 08/15 00:00**, stale glob | `ba74d94a` |
| `bv38xejdz` | **fallback rev4** — calls `fallback-compiler.sh`; corrected glob + drift arm | `ba74d94a` (current) |
| `b3ki008vg` | 30-min fallback sweep + bus fingerprint | `b2d20534` — **Aug 12, two days dead** |

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
