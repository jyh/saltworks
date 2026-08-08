# MUSTER — THE RESULTS LEDGER, day 3 (2026-08-08)

**Assembled 08:1x–08:2x by the EVIDENCE seat, AFTER a five-hour machine
outage that ate the 05:30 muster-prep window.** Format is the frozen four-part
order — **results · honest negatives with mechanism · in flight · cost**.

⛔ **THE DO-NOT-PUBLISH LAWS STAND AND ARE RESTATED HERE RATHER THAN
REFERENCED**, because a law that lives one hop away is a law nobody re-reads:

1. **The block-unit human-time percentage NEVER APPEARS.** Not in this file,
   not in a brief built on it, not as "about" or "roughly". ADDENDUM 1 §K:
   the charter tests each **touch**, the tool tags each **block**, and one
   irreducible order drags a whole block into THE CLAIM. It is a coarse upper
   bound; it is quoted as one or not at all.
2. **`[R]` / `[C]` CARRY NO FRACTIONS BEFORE DAY 7.** Today is **day 3**
   (T0 = 2026-08-05 22:02). Counts only. A ratio over three days of a
   changing instrument measures the instrument.

## §0 — REGENERATE FIRST, then fill

```sh
cd ~/projects/claude/saltworks
python3 docs/ledger-tools/selftest.py                     # gate: must be green
sh      docs/ledger-tools/nightly.sh                      # §0 coverage + silence, BOTH repos
python3 docs/ledger-tools/landed.py     --since '2026-08-08 00:00' --summary-only
python3 docs/ledger-tools/token_meter.py --since '2026-08-08 00:00'
python3 docs/ledger-tools/human_time.py  --since '2026-08-08 00:00'
python3 docs/ledger-tools/import-closure.py               # THE EXIT CODE IS THE FINDING
python3 docs/ledger-tools/nudge_detect.py                 # provenance of "human" touches
```

⛔ **NEVER PIPE `import-closure.py`, AND I DID IT THIS MORNING.** The recipe
above already said *the exit code is the finding*; I ran it into `tail` anyway
and read `$?` — **which is `tail`'s status, not the tool's.**

```
python3 import-closure.py > file ; echo $?   →  1   ← THE FINDING
python3 import-closure.py | tail  ; echo $?   →  0   ← tail exited fine
```

*This is the fleet's `saltbuild.sh`-is-never-piped law, in a different tool,
broken by the seat that audits compliance with it. A pipe replaces the exit
status of the thing you are measuring with the exit status of the thing you
are measuring it WITH.* **[[instrument-inside-the-system]], instance six.**

---

## 1. WHAT LANDED — generated, never typed

**GENERATED 08:13 by `landed.py`, window `2026-08-08 00:00 → 08:13`.**

| Lane | Commits | Lines added | `.lean` added |
|---|---:|---:|---:|
| compiler (leg 2) | 7 | 302 | 12 |
| evidence | 4 | 2,585 | **0** |
| silicon (leg 3) | 1 | 46 | 0 |
| **saltworks total** | **12** | **2,933** | **12** |
| `salt` | **0** | 0 | 0 |

⚠️ **Read this table against the clock, not as a day.** The window is
**8h 13m long and the machine was down for 5h 06m of it.** Working time on
day 3 so far is roughly three hours, of which the first hour is pre-crash and
the rest is relight. **A per-day comparison against days 1–2 is invalid** and
is not drawn here.

⚠️ The evidence row is `.lean = 0` **by construction** — this seat writes
instruments and documents, never library modules — and is excluded from any
META aggregate, since including it measures how busy the measurer was.

⚠️ Lane attribution is a **path heuristic**, never a claim about who typed what.

---

## 1b. LANDINGS INSIDE A SILENCE WINDOW — the measure that carries the claim

From the 08:06 nightly (`EVIDENCE-ledger-2026-08-08.md`), campaign window
`2026-08-05 22:00 → now`, fleet-wide presence:

| Silence containing the landing | Commits | Share |
|---|---:|---:|
| ≥ 1 h | 22 | 4.2% |
| ≥ 2 h | 22 | 4.2% |
| ≥ 4 h | **0** | **0.0%** |
| (all observed commits) | 526 | 100% |

**Record coverage:** 390,012 liveness records · median commit→record **0.3 s**
· p99 **2.9 s** · nearest hole **22.19 min** · separation **378.8×**, so the
5-minute tolerance still sits in a measured void. **Exactly 1 commit of 526
lands with no transcript record** — unchanged, and still published as a lower
bound on presence rather than as absence.

> **SPEAK SILENCE WINDOWS, NEVER NIGHT HOURS.** The night share is thin and a
> skeptic finds it with `git log` in thirty seconds.

---

## 2. THE OUTAGE, AS SEVEN READINGS

**Every value below comes from `sysctl`, `stat`, `find`, `git`, or
`/Library/Logs/DiagnosticReports`. None comes from an account of the night,
including the maestro's and including mine.**

| Reading | Value | Instrument |
|---|---|---|
| Last commit | 00:57 `f4825d7` | `git log` |
| Last bus post | 02:31 | `FLEET.md` |
| **Last file written** | **02:42:16** | `find -newermt` / `stat` |
| Diagnostic cascade opens | 02:50 | DiagnosticReports |
| apfsd CPU resource event | 03:08–03:10 | same |
| Shutdown stalls | 07:44:29 · 07:47:50 | same |
| Boot | **07:48:22** | `sysctl kern.boottime` |

**Outage = 02:42:16 → 07:48:22 = 5 h 06 m.** Charter consequences are written
up as **ADDENDUM 4 (M and N)** in `docs/measurement-preregistration.md`:

- **M — an outage is a THIRD thing a silence window can be**, and §0's hole
  detector is blind to it *by construction* (ADDENDUM 2 §H printed that limit
  in advance). Zero commits landed inside, so §2 moves in neither numerator
  nor denominator. **A span is not autonomy unless something ran inside it.**
- **N — the bus is not the clock.** Five `Scratch*.lean`, 111 KB, written
  02:30:46 → 02:42:16, *after* the last bus post. Hang onset is between
  **02:42 and 02:50**, not "after 02:31."

**AND THE NIGHT WAS NOT UNATTENDED.** `human_time.py` puts a human block at
**01:49 → 02:18**, and `nudge_detect.py` puts a **`MAESTRO: CAPTAIN-DIRECTED
RE-TASK`** at **02:16**, inside it. *The Captain was directing roughly half an
hour before the machine stopped.* This is not offered as a cause; it is
offered because "the fleet ran overnight unattended" is the sentence this
ledger exists to prevent, and on this night it is false.

---

## 3. HONEST NEGATIVES — results, with mechanism

**⛔ (a) `import-closure.py` EXITS 1. Ten audit sites never fire in the
default build.**

```
hub: SaltWorks.lean   tracked .lean: 69   in closure: 64   OUTSIDE: 5
  SaltWorks.Silicon.Equiv.CERefinement          1 audit site
  SaltWorks.Silicon.Equiv.CERefinementC         1 audit site
  SaltWorks.Silicon.Equiv.PartialLoad           8 audit sites
  SaltWorks.Silicon.Equiv.ScenarioComplete      0
  SaltWorks.Silicon.Imported.CompareExchange    0
TOTAL audit sites outside the default build: 10
```

*A module outside the hub's import closure is not built by the default build,
so its audit sites cannot fire, so a green default build says nothing about
them.* **This is silicon's** `PartialLoad` **carrying 8 of the 10.**

**⛔ (b) THE TILE-DRAIN SERIES STILL PRINTS NO SLOPE.** 5 readings, all
`202 / 0`, spanning **6.7 h against the 36 h the slope needs.** Readings this
close together measure the clock, not the shuttle. *A gap is honest; a
fabricated slope is not.*

**⛔ (c) NINE HUMAN-TIME TAGS MATCH NO BLOCK and contribute nothing** —
`20260805T1759`, `20260805T2039`, `20260805T2201`, `20260806T0055`,
`20260806T0629`, `20260806T0757`, `20260806T1243`, `20260806T1456`,
`20260806T1525`. A block id is its first touch's timestamp, so a changed
`--since`, or one new message landing in a former gap, merges blocks and
detaches their tags. **Unresolved since day 2.** Tags are matched by
containment rather than exact id *precisely so this is visible instead of
silent* — but a detached tag still needs re-pointing by hand.

**⛔ (d) THE WATCH THIS SEAT REPORTED AS ARMED ALL OF 8/7 IMPLEMENTED TWO OF
FOUR REQUIRED CLASSES.** CAPTAIN and HALT/STAND DOWN were absent; four PPID
checks confirmed "running" and none asked "what will wake me?" Widened at
08:0x — whereupon it **fired three times and was wrong three times**, every
hit a seat quoting its own filter config. Now owner-gated: halt words are read
only from a maestro-owned view (`112353b`, `2154010`). *Measured by owner over
the whole bus: math 11 · silicon 10 · compiler 5 · evidence 2 · **maestro 1***
— the gate keeps 1 and drops 28.

**⛔ (e) AND I WROTE THAT MEASUREMENT INTO THE CODE BEFORE TAKING IT.** The
first draft of the comment claimed *"27 seat-owned, 0 maestro-owned"* and
described itself as *"measured before arming"*. The real split has a maestro
line in it. **Had it shipped, the comment would have argued the gate discards
nothing, when the gate's entire value is the single line it keeps.**

---

## 4. IN FLIGHT AT CLOSE OF THIS LEDGER

- **PUSH IS BLOCKED FLEET-WIDE.** The login keychain did not come back with
  the machine: `git push` → *Interaction with the Security Server is not
  allowed*; `gh auth` → *token invalid*; `security` → *User interaction is not
  allowed*. **Not the sandbox** — identical with the sandbox disabled, while
  the GUI console is live (`jyh` and `silicon-acct`, both 07:48). **4 evidence
  commits are safe locally and cannot leave this machine.** Needs one unlock
  in a GUI Terminal, by the Captain.
- **A LIVE DISK-WRITE CONDITION.** Five `node` disk-write diagnostics span the
  crash window and, enumerated by pattern, **all five belong to third-party AI
  apps** — `ai.elementlabs.lmstudio` (02:50, 03:01, 07:52, 08:01) and
  `ai.openclaw.gateway` (03:50) — each dirtying ~8.6 GB of file-backed memory,
  against a data volume that is **91% full**. The 07:52 and 08:01 events are
  **post-boot**. *The "node diagnostic at 03:50" is a true reading of an
  adjacent object: it is not our node.* **Correlation with a named mechanism,
  not a proven cause** — `Action taken: none` marks these as threshold notices
  rather than kills.
- **Compiler's five surviving `Scratch*.lean`** (111 KB, zero `sorry` by grep,
  not by build) are on the bus, gitignored, and should be checked before any
  executor is re-dispatched for work already on disk.

---

## 4b. DISPOSITIONS — all three §4 items closed between 08:48 and 10:05

**§4 was written at 08:15 and every bullet in it has since been overtaken. The
original text is kept above and marked here rather than edited, per this
record's standing rule — a reader who acted on §4 needs to find the correction,
not a gap. ⚠️ Two of the three closed in a direction OPPOSITE to what §4
predicted.**

| §4 item | disposition |
|---|---|
| **PUSH IS BLOCKED — "needs one unlock in a GUI Terminal, by the Captain"** | ⛔ **THE DIAGNOSIS WAS RIGHT AND THE PRESCRIPTION WAS WRONG.** Push was restored **08:48:24** by **SSH remotes on a fresh on-disk ed25519 key** — *no keychain in the path, and the keychain was **never unlocked***. Verified from this seat, same process: `managername` still `Background`, `security` still refusing, `gh` still failing, `git ls-remote` returning refs. **All four evidence commits (six by then) reached origin.** ⚠️ **`gh` REMAINS DOWN** — HTTPS + keychain — so any duty routed through `gh api` is unavailable |
| **A LIVE DISK-WRITE CONDITION** (five `node` diagnostics, `ai.openclaw.gateway` 03:50) | ✅ **CLOSED AT THE CAUSE, and it was a security matter rather than a capacity one.** OpenClaw **eradicated**; revocations **DONE** (Captain, 09:3x — client and every token dead at the source); the `silicon-acct` **unix user deleted** (09:29). **Separately, the WindowServer error storm has a named author — iStat Menus** (bootout dropped the invalid-window rate 4.8/s → 0.7/s, held through a verified-dead window). ⚠️ **Cause-vs-symptom of the WEDGE itself stays honestly open**; the discriminating measurement — the invalid-window rate series *before* 02:42:16 — has not been taken |
| **Five surviving `Scratch*.lean`, "zero `sorry` by grep, not by build"** | ⭐ **THE CAVEAT WAS CASHED BY THE KERNEL, EXACTLY AS WRITTEN.** Builds: `ScratchMuxCAudit` EXIT=0 (29/29 clean) · `ScratchMuxC` EXIT=0 · `ScratchMuxA` EXIT=1 (57 errors) · `ScratchMuxB` EXIT=134 · `ScratchGSCount` EXIT=1 (41 ✓, 4 TAINTED). 🔑 ***`grep -c sorry` = 0 AND the file depends on `sorryAx` — a failed tactic fills the hole. "0 `sorry`" is a property of the TEXT and never a hygiene result;*** `#audit_axioms` + `saltbuild EXIT=0` is |

🔑 **THE ONE SENTENCE THIS TABLE IS FOR:** ***every item §4 flagged as needing
the Captain's hand was closed without it, and the item §4 hedged most carefully
is the one the kernel proved.*** *A close-of-ledger snapshot is a prediction, and
these three were scored the same day — which is the only reason anyone can tell.*

---

## 5. COST — one line, unit named

**GENERATED 08:13 by `token_meter.py`, window `2026-08-08 00:00 → 08:13`,
5 personal-lane projects, subagent transcripts INCLUDED.**

| Quantity | Tokens |
|---|---:|
| API requests (deduplicated) | 991 |
| Input | 9,942 |
| **Output** | **743,847** |
| Cache created | 3,070,578 |
| Cache read | 327,596,329 |

| Project | Requests | Output |
|---|---:|---:|
| `saltworks` | 736 | 532,690 |
| `salt` | 255 | 211,157 |

**Unit is TOKENS.** The records carry no prices and **no account identifier**,
so no dollar figure and no per-account split is derivable from them
(ADDENDUM 1 §D). On a subscription, dollars are a flat envelope — the two
framings are reported separately or not at all, never blended. **Cache is its
own column and never enters a headline.**

---

## 6. HUMAN TIME — and what the number is NOT

**GENERATED 08:13 by `human_time.py`. Window `2026-08-08 00:00 → 08:13`:
2 blocks, 0h 47m engaged, `100.0% UNTAGGED`, THE CLAIM `0h 00m`.**

| Block id | Seat | Start | End | Duration | Msgs |
|---|---|---|---|---:|---:|
| `20260808T0149` | salt | 01:49 | 02:18 | 0h 28m | 9 |
| `20260808T0752` | salt | 07:52 | 08:11 | 0h 18m | 12 |

⛔ **NO HUMAN-TIME FIGURE IS PUBLISHED TODAY, AND THE ZERO IS NOT AN ABSENCE.**
THE CLAIM reads `0h 00m` because **both blocks are UNTAGGED**, not because no
human directed anything — §2 above shows a `CAPTAIN-DIRECTED RE-TASK` inside
the first block. *An untagged block is never silently folded into a category;
that is the design working, and the tagging is owed.*

⛔ **THE BLOCK-UNIT PERCENTAGE IS NOT QUOTED HERE OR ANYWHERE** (ADDENDUM 1 §K).

⚠️ **Both blocks are labelled `salt`, and the label is the block's FIRST
touch, not where its mass sits** (ADDENDUM 1 §L). The 07:52 block spans the
five-seat relight; reading it as salt-seat time would be wrong.

⚠️ **`[R]` and `[C]` are reported as COUNTS ONLY — day 3 of 7.**
`nudge_detect.py` flags machine-transported touches across the record; today's
window contains **1** such record (the 02:16 `MAESTRO: CAPTAIN-DIRECTED
RE-TASK` into saltworks). **No fraction is computed.**

⛔ **AND THE DISTINCTION `nudge_detect` CANNOT MAKE, restated because it is
the one most likely to be lost downstream:** it establishes that the
**TRANSPORT** was mechanical. It says **nothing** about whether the
**DECISION** was. A maestro relaying the Captain's order verbatim through
`send-keys` produces a record byte-identical to a maestro composing that order
itself — *the first is genuine human direction with a machine courier; the
second is not human direction at all.* The counterfactual test applies to the
DECISION, and this instrument cannot see decisions.
