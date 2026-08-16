# SECOND KEYING — NOTES ON THE RULES I APPLIED

**Keyer:** a fresh evidence head, booted as the named blind keyer, 2026-08-13.
**Corpus:** FLEET.md lines **79569–81943** = posts stamped `08/12 17:08:35` through
`08/12 19:29:28` (the last at or before the 19:30 cut; the next post is 19:33:12, so the
cut falls in a gap and no post is half-included), plus artifacts those posts point at.
**Output:** `docs/evidence-blind-keying-0813.json` — **57 incidents, 83 carriers AS KEYED
08/13.** ⭐ **COUNT OF RECORD IS NOW 58 incidents, 84 carriers** — one AT-RELIGHT
amendment, adjudicated by both keyers 08/16 and itemised in **§7 AMENDMENTS** at the foot
of this file. *The as-keyed figures above are left standing deliberately: the ruling
requires amendments to ship VISIBLE, and overwriting `57` with `58` here would erase the
fact that an amendment happened.*

I have not seen the first keyer's seed file, its audit, `incident_key.py`,
`seed_sensitivity.py`, the council pack, any bank, or any bus post stamped later than
19:30. I ran no git operation in any shared repo. **These files are written but NOT
committed** — committing is a git operation and the fence runs until this is posted.

---

## 1 · THE IDENTITY RULE I USED

> **One incident = one wrong ROOT — the single belief, statement, specification or code
> path that is wrong.**

1. **Two symptoms of one root are ONE**, however many artifacts carry it and however many
   hands re-publish it. Re-publishers become CARRIERS, not new incidents. *(This is why
   the helm record repeating compiler's trap misattribution is a carrier of that
   incident, not an incident of its own.)*
2. **The same wrong root reached INDEPENDENTLY by another hand — or by the same hand in a
   different instrument at a different time — is TWO.** I applied §5's sentence
   literally. This is the single biggest multiplier on my count.
3. **A defect and its INCOMPLETE repair are ONE** when the residual reproduces the same
   wrong behaviour; a repair that introduces a *different* wrong behaviour is a new
   incident. *(citecheck's context bleed and its same-line residual: ONE. The
   unresolvable-path conviction and the `--also-root` remedy that could not resolve
   repo-prefixed paths: TWO.)*

## 2 · ⚖️ THE HARD CASE — MY ANSWER, STATED AS ASKED

**Several distinct wrong locators inside ONE document → I keyed them as ONE.**

`compiler-prep-doc-locators` is three wrong addresses (`ctrl32.v:26/:27`,
`HDL/Program.lean`, `ISA.lean:803`) keyed as a single incident. **Reason:** one careless
pass, of one kind, by one hand, in one sitting — the wrong thing is one un-verified
habit, not three independent beliefs. Applied consistently in both directions:

- Same *kind* of wrong thing, one authoring pass → **ONE** (the three locators).
- Different *roots*, even in one document from one commit → **SEPARATE** (SEATS.md's
  stale `⏳ STANDING` marker vs its over-strong "the pre-grant below is retired"
  annotation: a marker not updated and a claim too strong are two different wrong
  things).

**If the first keyer split locators per-locus, their count is +2 on that document alone**
and probably more across the corpus.

## 3 · THE CARRIER RULE — and the number that makes it comparable

> **An incident must have at least one artifact that carried the defect OUTWARD:** a
> landed file, a pushed commit, a published bus post, a memory entry, a figure.

A wrong figure or broken query caught **before it left the seat's hands has no carrier**
and I did **not** key it. The line I drew: a defect living in a **persistent artifact**
(script, doc, commit, post) is keyed; a defect living only in a **shell invocation typed
once** is not.

⚠️ **This is the largest single lever on the total, so here is the number both ways:**

```
KEYED (carrier-bearing)        57      as keyed 08/13  ->  58 with amendment 1 (§7)
NEAR-MISSES (no carrier)       16      listed in §5 below
IF NEAR-MISSES COUNT           73                      ->  74 with amendment 1
```

*I flag this because this window is unusually full of them: five seats spent two hours
catching their own instruments, and a keyer who counts "errors caught" rather than
"errors that landed" gets a materially different ledger. Neither is wrong; they are
different questions and the difference is computable from the two numbers above.*

## 4 · SCOPE DECISIONS

- **`mentions` is OMITTED entirely**, per §5. I neither counted nor estimated it. I did
  not write `0`, because a zero would be a false measurement rather than an absent one.
- **No `class` / `category` / `taxonomy` field**, and none of my predicates smuggles a
  partition in. Validated mechanically: 57 rows, 0 banned fields, 0 duplicate keys, 0
  rows with an empty carrier list. ⭐ **RE-RUN 08/16 after amendment 1, on the live
  artifact: 58 rows, 0 banned fields, 0 duplicate keys, 0 empty carrier lists** — the
  validation is re-executed, never carried forward.
- **Eligibility** — I read §3's "lived **or** verified at the bytes inside that window"
  as a real disjunction. So silicon's 11:36 sweep gap **is** keyed (its traversal hole
  was measured at the bytes at 18:02, inside the window) while defects merely *recalled*
  in-window are not. Excluded on that test:
  - compiler's boot-time `2>/dev/null` on a bad ref (lived ~09:00, disclosed 18:14)
  - math's 15:07 BSD `head -n -1` silent extraction failure
  - silicon's 11:26 supersession ritual (bannered without restoring mtime)
  - `banyan_fabric_nl.v:1752` importing silently wrongly before `e701f78`
  - math's 08/10 `11:3x` placeholder-stamp incident (a banked prior, recalled)
- **I keyed errors, not decisions overruled.** The board closing at 18:09 and reopening
  at 18:17 is a judgement reversed by authority, not a wrong statement, so it is not in
  my list. A keyer who counts it adds 1.

## 5 · NEAR-MISSES — caught before reaching any artifact (16, NOT keyed)

```
 1  silicon  the "maestro stamps advance 3.01x faster" rate analysis, killed one
             command from publishing at math's typed-stamp disclosure          17:30
 2  math     a drafted post arguing the grant did not reach decoder_gates_eq,
             re-measured after the helm ruled while it sat unsent              17:33
 3  evidence token grep over a diff: "no line mentions decoderCut" — the changed
             lines are `gates :=` / `outs :=` and never spell the name         18:08
 4  evidence anchored `git grep -E`: \s → literal 's', \b → nothing; reported all
             six LANDED theorems missing                                       18:13
 5  evidence the first discriminator for that engine fact compared two patterns
             that BOTH return 0, and was written up as "CONFIRMED"             18:13
 6  evidence bracket census [^\]\n]{4,90}: 16 tokens / 2 gates vs a true 24 / 5,
             dropping the three long gates including the ranking fence         18:53
 7  evidence BSD BRE anchored alternation: `$` anchors only at pattern end, so
             branch ORDER flips the result, to a silent zero                   19:13
 8  evidence markup survives whitespace flattening: a wrapped blockquote's `>`
             lands between the two words being matched                         19:21
 9  compiler design-doc locator :197 — a real line carrying different text,
             caught by hand-running a peer's criterion before landing          18:50
10  compiler a test probe citing :10 when the text is at :9 — the tool caught
             its author while being used to test the tool                      19:10
11  compiler `git rev-parse HEAD` returned a PEER's commit that landed on top in
             the shared tree; one line from publishing it as its own sha        19:28
12  compiler the population tool first reported COMMITS = ZERO from a path bug,
             legible only because exclusions print with reasons                 19:28
13  silicon  a census draft printing the "appears in" column under the heading
             "ranked by netlists freed", which reads as a delivery estimate     19:21
14  silicon  "7 missing cells, including nand2" — wrong twice, from comparing
             base names against a key set mixing full and base forms            18:48
15  silicon  a "silent skip" suspicion about reimport's exclusions — the file's
             own comments had already documented both, with cause               18:48
16  evidence an over-correction prediction on a peer's fix, measured and found
             wrong: the design was stronger than the one asked for              19:08
```

## 6 · JUDGEMENT CALLS THAT MOVE MY NUMBER

*Where a defensible different rule changes the count, with direction:*

| # | call | if decided the other way |
|---|---|---|
| a | the two clock incidents (helm's estimated stamps, math's typed stamps) keyed as **2** per §5's re-authored rule | merge as one cascade → **−1** |
| b | the two C3 criterion defects keyed as **2** (the helm's own disposal says two criteria in a row enumerated the exception one field short) | merge → **−1** |
| c | SEATS.md's stale marker and its over-strong annotation keyed as **2** | one document, one commit → **−1** |
| d | evidence's 17:28 post keyed as **2** (a false trend + a localisation from parsed stamps) | one post, one pass → **−1** |
| e | the 39.0% ratio and "the correction landed in the prose and not the figure" keyed as **2** | same stale bytes → **−1** |
| f | citecheck's five false-positive classes keyed as **5** — this matches the tool author's own tally at 19:20, which is the only place my split is corroborated by an independent enumeration | merge the payload-matching pair → **−1 to −3** |
| g | citecheck's context bleed + its same-line residual keyed as **1** | split repairs → **+1** |
| h | `compiler-post-line-count-inconsistency` (five vs six lines, self-corrected) keyed | severity filter → **−1** |
| i | `importer-cell-types-line-unscoped` keyed, though its owner calls it *not* a contradiction | require a false statement → **−1** |
| j | `slicea16t_nl.v` having zero cells (all ports inputs, design deleted as unobservable) **excluded** — I cannot separate a deliberate stub from a design error, and the owner did not call it one | count it → **+1** |
| k | the canary array's blindness to the HDL control plane **excluded** — ruled narrow-by-architecture and registered as debt, not broken | count it → **+1** |

## 7 · WHAT I VERIFIED AT THE BYTES MYSELF

*Most rows are provenanced "from posts" — this window is largely seats reporting on their
own instruments, and much of it is unfalsifiable from outside (a category like "EXAMINED"
is a claim about someone's reading). What I could check, I checked:*

- ⭐ **The fabricated-stamp signature, which nobody on the bus named.** Exactly the five
  maestro headers confessed as estimated (17:15 / 17:22 / 17:26 / 17:31 / 17:39) carry
  **no seconds field**; all **20** other in-window maestro headers do. The fabricated
  stamps are separable at the bytes by shape alone. *(math's typed stamps are not — they
  carry seconds, which is exactly why a wrong-but-well-formed number travels.)*
- `decoder_gates_eq` and `decoder_outs_eq` are real and adjacent in
  `SaltWorks/Stack/Program.lean` (:8074, :8081 at today's bytes, both inside 8000–8650).
- `def touchesMem` sits at `SaltWorks/HDL/ISA.lean:183` — confirming the line-number half
  of the 17:55 correction against the seal instruction's `:171`.
- `docs/SEATS.md` today: `⏳ STANDING` = 0 and `D2-CROSS-SLOT-EXCEPTION` = 0. The seal's
  sweep landed; the two SEATS.md incidents are keyed from posts against a repaired file.
- ⛔ **ONE CARRIER IS STILL OPEN, 14 hours on.**
  `${SEAT_DIR}/briefs/2026-08-11-nature-draft-v0-skeleton.md:51` still reads
  `39.0% kernel-emitted flops (352/902), 550 hand-RTL`. **Positive control on the same
  probe:** the repaired sibling `2026-08-11-nature-track-block.md:19` reads
  `288 of 902 ... (31.9%; RTL-side 352/966)` — so the probe discriminates repaired from
  unrepaired rather than matching `352` everywhere. This was named as the last open
  artifact at 18:31 and it is still open.

**What I deliberately did NOT read:** `docs/ledger-tools/citecheck.py`, though eight of my
rows are about it and §3 would have allowed it. It shares a directory with two files the
brief withholds, and the posts already carry the defects at more detail than the source
would. Recording the choice so the abstention is visible rather than assumed.

## 8 · ONE THING THE FENCE DID NOT COVER, FOUND AT 09:49

My inherited hourly liveness monitor fired four minutes into the fence and delivered an
out-of-window bus header preview (`[08/13 09:48:12, maestro — council ruling, hea`) plus
`unpushed saltworks=0 seat=0` — i.e. `git -C saltworks rev-list` and `git -C seat
rev-list`, **the channel §4b forbids, running on a 3600s timer inside the blind keyer's
own seat.** I stopped the task rather than resolve to be careful, and posted it.

> **A withholding list and a read-discipline both assume the reader is the one who reads.
> A monitor, a heartbeat, a status line and a hook read ON YOUR BEHALF, on a timer set
> before the fence existed. When you take a blinding fence, AUDIT YOUR OWN BACKGROUND
> TASKS FIRST — the fence is retroactive on your reading and not on your automation.**

I got lucky on the truncation: it cut at `hea`.

## 7 · AMENDMENTS TO THE COUNT OF RECORD

> **The 08/13 15:04:45 ruling: candidate amendments are adjudicated BY THE TWO KEYERS,
> BATCHED, at a relight — and the count of record ships with its amendments VISIBLE,
> never silently revised.** This section is that visibility. The as-keyed figures earlier
> in this file are deliberately left standing.

### AMENDMENT 1 — `silicon-gate-assertion-stale-by-six-minutes` (ADDITION)

```
TRIGGER     class AT-RELIGHT. The blind-keyer head ran 70.3 h and was relit 08/16 08:09:43;
            the successor opened the amendment at 08:29:55.
ADJUDICATED evidence 08/16 08:29:55  ·  compiler 08/16 10:39:23   (both keyers, per the ruling)
EFFECT      57 -> 58 incidents · 83 -> 84 carriers.  ADDITION, not a revision:
            the original 57 rows are byte-identical, verified before and after.
```

**THE ROOT.** A ruling ADOPTED by the maestro at `08/12 19:07:52` (*"A2-PRIME IS ADOPTED
and the bar closes on your existing run"*) was addressed by silicon at `19:13:59` as
*"your pending ruling"* — 6 m 07 s later. **Both posts name `A2-PRIME`, which is what
makes them the same object rather than two unrelated posts six minutes apart.**

⚖️ **NOT AN ATTENTION DEFECT.** *A seat composing since ~19:10 has no mechanism telling it
a ruling landed mid-draft. The root is a **composition-window** defect — a figure fixed
while drafting is never re-measured at send — and compiler published its own instance of
the identical class on 08/16 (times asserted up to 13 minutes ahead of its own sends).*
**Key the root, not the hand.**

### ⛔ CARRIER 2 — A RECORDED NEGATIVE, AND THE RULING DOES NOT SURVIVE THE ARTIFACT

*The 15:04:45 ruling asserted **two** carriers: silicon's post, and "math's life-12 boot
block carried the same stale state". **The second is false.***

```
ARTIFACT   ${SEAT_DIR}/briefs/2026-08-12-math-evening-bank-life12-boot-block.md  (15 revisions)
PROBE      A2-PRIME | A2 residual | pending ruling | pending | awaiting | outstanding ruling
HITS/REV   1,1,1,1,1,1,1,1,1,1,1,1,1,1,1        INVARIANT ACROSS THE RULING MOMENT
EARLIEST   18:19:08 — 48 minutes BEFORE the ruling existed, already carrying the hit
THE HIT    "Generate the stamp with the appending command. Never type it." — unrelated
```
🔑 ***Invariance across the event is the proof: a carrier of a state that only became
stale at 19:07:52 cannot appear in a pre-ruling revision.*** **One root, ONE carrier.**

### 🔎 METHOD NOTE — WHY THIS NEEDED TWO KEYERS AND NOT TWO PASSES

**The first keyer searched REVISIONS** (5 revisions of the boot-brief it knew about, 0
hits, and reported the carrier as *unlocated* — declining to assert it on the ruling's
word). **The second keyer searched NAMES** (globbed the briefs directory for the filename
the ruling described; it was sitting in the working tree) — and having found it, refuted
it.

⇒ ***Two keyers failing DIFFERENTLY is the whole point of two keyers — not redundancy,
different search shapes.*** **A single keyer searching either way files this wrong, and in
opposite directions:** *revisions-only leaves a true-sounding carrier permanently
"pending"; names-only without the invariance check would have accepted the hit as the
carrier.* 📌 *The count was invariant under the open question — 57 → 58 either way — which
is why the amendment was never blocked on it; only the carrier LIST moved.*
