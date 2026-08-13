# ERROR-LEDGER POPULATION — PHASE 1 DISCLOSURE

**Board item:** LEDGER CONSTITUTION phase 1 (compiler seat) — *population disclosed before counting.*
**Frame stamped:** 2026-08-12 19:26:16 PDT · **reproduce:** `python3 docs/ledger-tools/ledger_population.py`

The scope as assigned is the FRAME, not a count. This document therefore states what
is IN the population, what is EXCLUDED and why, and emits **no incident count** —
phase 2 (the `incident_key` collapse) is a judgement per row, not a regex.

```
==============================================================================
ERROR-LEDGER POPULATION — PHASE 1 DISCLOSURE (no incident count is emitted)
==============================================================================

[BUS]  3051 member(s)
  RULE      lines matching ^[MM/DD HH:MM(:SS), <seat> — …] in FLEET.md
  UNIT      one bracket-stamped POST (not an incident)
  NOTE      by seat: compiler 599 · evidence 578 · maestro 606 · math 485 · silicon 783
  CONTROL   a known seat header appears → compiler=599
  EXCLUDED  78829    lines that are POST BODY, not post headers (the bus is prose; a body line is part of its post, never a separate member)

[MEMORY]  299 member(s)
  RULE      ${SEAT_DIR}/memory-seats/<seat>/*.md, excluding each seat's index
  UNIT      one curated LAW (MANY-TO-ONE with incidents; NOT all are errors)
  NOTE      by seat: compiler 80 · evidence 53 · legacy-saltworks-frozen-0808 34 · math 70 · salt-maestro 1 · silicon 61
  CONTROL   a known seat mirror is non-empty → compiler=80
  EXCLUDED  5        per-seat MEMORY.md index files (pointers to members, not members)

[LEDGER]  20 member(s)
  RULE      ^## headings in saltworks/docs/LEDGER.md
  UNIT      one LANDED NODE (⚠️ THE WRONG NOUN — these are landings, not errors)
  NOTE      ⚠️ INCLUDED FOR DISCLOSURE, NOT AS ERROR RECORDS: this file records what LANDED. Its per-node 'what was FOUND vs PROVED / left undetermined' sections may CONTAIN incidents; the file itself is not a list of them.
  CONTROL   the file parses to >0 nodes → 20
  EXCLUDED  156      ### subsections inside a node (What landed / bridge lemma / …)

[COMMITS]  4892 member(s)
  RULE      git log --oneline across the named repos
  UNIT      one COMMIT (a correction may be described in its message)
  NOTE      by repo: salt 2111 · saltworks 1434 · seat 1347
  CONTROL   at least one repo yielded commits → max=2111
  EXCLUDED  0        (nothing excluded from this source)

------------------------------------------------------------------------------
FRAME TOTAL: 8262 members across 4 sources.
------------------------------------------------------------------------------
⏱  THE POPULATION IS LIVE. The bus is append-only and grew BY ONE POST between two
   runs of this tool while it was being written. A frame is therefore valid only AT
   ITS TIMESTAMP, and any count quoted from it must carry that stamp — otherwise two
   honest measurements disagree and someone hunts a defect that is not there.
⛔ THIS IS NOT AN ERROR COUNT AND MUST NOT BE QUOTED AS ONE.
   These are CANDIDATE RECORDS that may each contain zero, one, or several
   incidents, and the same incident appears in many of them. Collapsing members
   to incidents is PHASE 2 and requires the incident_key judgement per row.
   Run with --why-no-count for the measured reason.
✅ Every source above is ENUMERATED, not sampled; exclusions are printed with
   their reasons; --list <SOURCE> dumps any source in full with no truncation.
```

## What this disclosure is NOT

- **Not an error count.** `8,262` is CANDIDATE RECORDS. One incident tonight (the
  `352/902` scope defect) appears in ~8 bus posts, 3 seats, 1 commit, 2 file
  annotations and 1 memory entry. A member-counter scores it 8-15; the ledger must
  score it 1.
- **Not stable.** The bus grew by one post between two runs during authoring. Quote
  the stamp with the number or two honest measurements will disagree.
- **Not the taxonomy.** The paper carries TWO incompatible class lists (`:192-194`
  four classes, §8 three, sharing only *scope*); that conflict is bracketed for the
  Captain and is not resolved here.

## The one defect this tool caught in itself

The `COMMITS` source first reported **0 members** — a path bug resolved the repos to
`~/projects/salt` instead of `~/projects/claude/salt`. It was legible only because the
tool prints its EXCLUSIONS (`repo has no .git and was NOT read`) beside a POSITIVE
CONTROL (`max=0`). A silent enumerator would have published a frame with an entire
source missing and nothing to show for it. **A zero needs a positive control** — and
the control must be able to fail for the same reason the probe would.
