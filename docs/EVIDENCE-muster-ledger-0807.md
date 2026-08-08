# MUSTER — THE RESULTS LEDGER, day 2 (2026-08-07)

**SKELETON, built 12:1x. Structure now; EVERY NUMBER REGENERATES AT CLOSE.**
Assembled by the EVIDENCE seat per the maestro's split: this file is the
**results ledger**; the Captain-facing brief is written on top of it.
Format is the four-part order — **results · honest negatives with mechanism ·
in flight · cost**.

⛔ **READ THIS BEFORE QUOTING ANY FIGURE BELOW.** Every `⟨REGEN⟩` marker is a
number that **does not exist yet**. Yesterday's ledger taught the reason the
hard way: *a generated table stops being generated the moment it is pasted
into a document* — `landed.py`'s own output aged **23 → 25 commits in six
minutes** between generation and re-run. **So this skeleton carries commands,
not values**, and a `⟨REGEN⟩` still present at 07:00 means the section was
never run and must not be read.

## §0 — REGENERATE FIRST, then fill

```sh
cd ~/projects/claude/saltworks
python3 docs/ledger-tools/selftest.py                                  # gate: must be green
sh      docs/ledger-tools/nightly.sh                                   # §0 coverage + silence
python3 docs/ledger-tools/landed.py --since '2026-08-07 00:00' --summary-only
python3 docs/ledger-tools/token_meter.py --since '2026-08-07 00:00'
python3 docs/ledger-tools/human_time.py --since '2026-08-07 00:00'
python3 docs/ledger-tools/import-closure.py                            # exit 0/1/2 is the finding
python3 docs/ledger-tools/nudge_detect.py                              # provenance of "human" touches
```

---

## 1. WHAT LANDED — generated, never typed

**GENERATED 19:15 by `landed.py`, window `2026-08-07 00:00 → now`. 236 commits across 2 repos.**

| Lane | Commits | Lines added | `.lean` added |
|---|---:|---:|---:|
| compiler (leg 2) | 88 | 11,329 | 7,929 |
| silicon (leg 3) | 54 | 156,545 | 1,036 |
| evidence | 44 | 3,875 | **0** |
| docs (shared) | 35 | 12,734 | 7,435 |
| maestro (hub) | 11 | 39 | 30 |
| other | 1 | 743 | 743 |
| **saltworks total** | **233** | **185,265** | **17,173** |
| `salt` (3 commits) | 3 | 446 | 272 |

⚠️ **The evidence row is `.lean` = 0 BY CONSTRUCTION** — this seat writes instruments and
documents, never library modules. *It is excluded from any META aggregate for the same
reason: including it measures how busy the measurer was.*

**Window: `2026-08-07 00:00 → close`, both repos, all seats** — stated on the
section, because *a count without its window is the same defect as a
countdown without its date.*

⚠️ **Lane attribution is a PATH HEURISTIC**, not a claim about who typed
what. ⚠️ **The evidence row is EXCLUDED from any META aggregate** — this seat
is ~100% META by construction, so including it measures how busy I was.

---

## 1a. THE SEAM GATE — point the check at the DISCHARGE, not the OBLIGATION

⛔ **The obligation count reads `4` and always will — it counts hypotheses that stay
written whether or not anything discharges them.** *The maestro's own board line inherited
it and was corrected at 22:44.*

```sh
⛔  grep -cE '\(hseam :' SaltWorks/Silicon/Equiv/ComposedSwitch.lean     # 4, forever
⚠️  grep -cE '^theorem composed_switch_of_bnC_driven' SeamJoinB.lean     # 1 — TEXT exists
✅  ../saltbuild.sh SaltWorks/HDL/SeamJoinB.lean > /tmp/gate.txt 2>&1; echo "EXIT=$?"
    grep -c '✓ SaltWorks.HDL.composed_switch_of_bnC_driven' /tmp/gate.txt   # 1 — a PROOF exists
```

⭐ **THE BUILD LINE IS STRICTLY STRONGER AND IT IS THE ONE THE MUSTER USES.** *A source
grep still reads `1` if the proof is `sorry`, if the file does not build, or if a
neighbour's landing broke its closure. **The `✓` is emitted only if the declaration
ELABORATED and passed the axiom whitelist.*** *Text existing and a proof existing are
different facts, and only one of them is a gate.*

⛔ **AND I DID NOT ADOPT THE FORM AS PROPOSED — IT PIPED `saltbuild.sh`, WHICH FLEET LAW
FORBIDS BECAUSE THE PIPE DISCARDS THE EXIT CODE.** *With a pipe, `$?` is `grep`'s. A build
that FAILED and a theorem that is ABSENT both yield `0`, and the muster cannot tell a
broken tree from an open gate.* **Redirect, read `EXIT`, then grep the file — and report
the two failure modes separately.**

📊 **RUN AT 23:0x, no pipe: `saltbuild EXIT=0` · `✓ SaltWorks.HDL.composed_switch_of_bnC_driven [3 axioms]` = 1 · `Replayed 0` · `Built 0` · 16 audit ✓ lines this run.**
*The `<path>.lean` form re-elaborates, so the `✓` is this run's kernel and not a cache's
recollection — which is the only reason the tick is admissible as evidence at all.*

⚠️ **AND I CORRECTED THE PROPOSED CHECK BEFORE ADOPTING IT — compiler specified
`grep -c composed_switch_of_bnC_driven … → 1 ⇔ CLOSED`. MEASURED: it returns `2`.**
*`grep -c` counts LINES, and the name appears twice — the declaration at `:188` and its
`#audit_axioms` at `:203`.* ⇒ ***A muster testing `= 1` would read OPEN on a CLOSED gate:
the exact defect the fix was written to repair, reproduced inside the fix.*** **Anchor it
to the declaration (`^theorem`) and it is `1`.**

📌 **Status at close: the theorem is PRESENT and the file carries `0 sorry`.** *That is the
gate's own reading; whether the fleet calls the seam closed is compiler's and the
maestro's, not this ledger's.*

---

## 1b. LANDINGS INSIDE A SILENCE WINDOW — the measure that carries the claim

**GENERATED 19:14 by `silence_windows.py` (saltworks, fleet-wide presence):**

| Silence containing the landing | Commits | Share | `.lean` lines | All lines |
|---|---:|---:|---:|---:|
| **≥ 1 h** | **0** | **0.0%** | 0 | 0 |
| ≥ 2 h · ≥ 4 h · ≥ 8 h · ≥ 12 h | 0 | 0.0% | 0 | 0 |
| (all observed commits) | 430 | 100% | 24,098 | 235,132 |

⚠️ **The single-seat measure — the leg-1 harvest's unit — is printed beside it and is the
LARGER number and the WEAKER claim: `≥ 1 h → 37 commits, 8.7%, 1,637 .lean lines`.** *The
human may have been directing another seat at the time; the fleet-wide measure is the one
that carries the claim, and today it is zero.*

📌 **AND THE CAVEAT IS DISCHARGED FOR THIS WINDOW, which is rare enough to say: the fleet
received 716 human touches inside the commit window — 716 into this seat and 0 into every
other personal-lane seat combined. The two measures coincide.** ⛔ *Subject to §3's coverage
hole: 1 of 430 commits landed where no transcript record exists.*

---

## 2. THE GATES THAT MOVED

| Gate | State | Verification status |
|---|---|---|
| **BB-1 / B2M — the composed switch's mathematics** | `batcher8_banyan_selfrouting`; `StrictMonoOn` discharged **by the network**; four goal-FALSE controls | **VERIFIED AT THE BYTES 15:04 — theorem present · controls present · census clean** (`docs/EVIDENCE-refute-B2M-0807.md`). `#print axioms` run rather than `#audit_axioms` trusted: `[propext, Classical.choice, Quot.sound]`, **no `sorryAx`, no `native_decide`**. Four controls are TWO PAIRS, each exhibiting an input satisfying the *other* hypothesis. ⛔ **AND ONE FINDING: of the three conjuncts, the THIRD IS FREE** — `Banyan.line_zero` instantiated, elaborated for an arbitrary function with axioms `[propext]`. **The routing content is conjunct 1 alone; the same shape recurs verbatim in `partial_load_selfrouting`.** *Upstream statement shape, not a defect either lane introduced — but the muster line must say ONE result and TWO boundary identities.* |
| **C4 construction** | ungated under the ratified partiality spec | **assembly theory ✅; `core` construction open at close** |
| **C2 witnessed** | Spike **and** Sail, 120/120 | ✅ **VERIFIED at the bytes 8/7** — both pinned, `encode` absent from the generator path |
| **C3 finalized → v1.1** | structural emission; Route B ruled in | ✅ decision sound · ⚠️ **citation corrected**: `100%` boundary vs `60.1%` cone are different quantities |
| **The banyan is SUBMITTED** | in the TTSKY26c queue, tile 2×2 | ⚠️ **ATTESTED, not measured** — gates verified, the click cannot be |
| **Import closure** | **EXIT 1 — 63 tracked · 58 in closure · OUTSIDE 5 · 10 audit sites** | the exit code **is** the finding: 0 covered · 1 outside · 2 could not read |

⭐ **THE SWEEP LANDED TODAY AND IT IS THE GATE THAT MOVED FURTHEST: 9 modules / 55 audit
sites outside at 17:4x → 5 modules / 10 sites at 19:15.** *`Bitwise`, `BatcherNetC`,
`SeamC` and `PartialLoad` are in; the adder's only behavioural certificate and the four
theorems saying the sorter sorts are now read by the default build.* ⛔ **Still 5 outside
and the gate is still RED — `import-closure` exits 1 by design and will until the last
one is swept.**

---

## 3. HONEST NEGATIVES — results, with mechanism

- **The stale-board mode** — a fix landed 07:19, a touch ordered it later; open on the board, closed in the repo, **stale across a reboot**. *Maestro-side, recorded because the syllabus records modes wherever they live.*
- **The ghost-text injection class** — client autocomplete delivered as keystrokes, **no author at all**; closed by **protocol** (source tags + style filtering), not by a better detector.
- **`2027-03-27 chips expected` is UNSOURCED** — read at source 8/7: the runs table's `Chips expected` cell for TTSKY26c is **empty**.
- 🛡️ **THE FIREWALL HELD, AND IT WAS A SEAT THAT STOPPED IT — not a rule, not a reviewer.**
  Silicon halted its own heritage block (`fdb4474`, maestro-ratified 17:00): the Bellcore
  PDFs are **Google-licensed library copies**, so republishing Figure 6's IMAGE in a public
  repo would cross the outside-lane firewall — *the one category no purse inversion ever
  touched.* Remedy shipped: **our render alone, Figure 6 cited IN WORDS** (Marcus & Hickey,
  ISSCC 1990 Digest p.258). *Our polygons are ours; their reproduction is not.*
  📌 **CAPTAIN'S NOTE, per the maestro:** a side-by-side in print is available if you want
  it — an IEEE republication permission **for your own figure** is yours to request. *Your
  paper, your rights, your call, and never the fleet's to make for you.*
  ⭐ **Why it belongs among the NEGATIVES rather than the wins: nothing was published and
  nothing was caught by review. A seat stopped itself.** *The fleet now protects the LANES
  as reflexively as it protects the kernel, and that reflex is the result.*
- ⚖️ **MAESTRO'S RULING OWED — 49 THEOREMS NOBODY HAS EVER AUDITED, AND THE QUESTION IS
  WHOSE CONVENTION BINDS.** `audit_completeness.py` defaults to `SaltWorks/HDL`, so its
  *"every theorem is on an `#audit_axioms` list"* was **true of a DIRECTORY and read as
  true of the REPO** — three ledger entries said it unscoped (now annotated in place,
  `6c6e1ba`). Run at the repo root: **49 unaudited**, most in **other seats' slots** —
  `Silicon/Equiv` (18 in `PartialLoad` alone), `Banyan`, `Stack`. ⛔ **Nobody is calling
  them defective; nobody has ever looked.** *Whether the HDL seat's convention binds those
  files is the maestro's ruling — compiler declined it, and so do I.*
  📌 **And the shape is the day's: the ledger CAUGHT this before math did, and the catch
  never travelled back to the three lines it invalidated.** *A correction that lands only
  where it was found leaves every earlier statement standing.*
- ⛔ **THE SAMPLED/EXHAUSTIVE COLUMN IS BLOCKED ON INFRASTRUCTURE** — see
  `EVIDENCE-proof-debt-table-0807.md` §5. Three designs died in thirty minutes; an axis is
  exhaustive only with a **proved quotient lemma**, and the fanin-restricted congruence
  those need does not exist in the tree. **Blocked, with owners named, not merely open.**
- ⛔ **COVERAGE, §0 of tonight's run: 1 of 430 commits landed in a stretch with NO transcript
  record.** *Checked against 374,089 liveness records at 5-minute tolerance; nearest clean
  commit sits 22.19 min from a hole.* **Any window containing that commit is a LOWER BOUND on
  presence and must not be published as unattended.** *The 8/6 gap remains OPEN, cause
  UNDETERMINED.*
- ⛔⛔ **HUMAN TIME IS NOT COMPUTABLE TONIGHT AND THE NUMBER MUST NOT BE READ AS ZERO.**
  `human_time.py` reports **8 blocks, 11h 14m, 100% UNTAGGED**, and therefore
  **THE CLAIM (DIRECTING+REVIEWING+UNBLOCKING) = `0h 00m`.** ⇒ ***That zero is a TAGGING GAP, not a
  measurement.***

  ⚠️ **CORRECTED 19:5x — I first wrote that the zero was "nine detached tags", and that is
  the WRONG MECHANISM. There are two separate things and I merged them:**
  - **TODAY'S 8 BLOCKS WERE NEVER TAGGED AT ALL** — every one reads `UNTAGGED` in the
    worksheet. *That, and only that, is why the claim is `0h 00m`.*
  - **The 9 detached tags are ALL from 8/5–8/6** (`20260805T1759` … `20260806T1525`) —
    **outside this window entirely**, contributing nothing to today either way.

  📌 **Right conclusion, wrong reason — the same shape as the `inc32` route, twice in one
  day.** *The conclusion (do not publish the zero) never depended on the mechanism, which is
  exactly what let a wrong mechanism ride along unchecked.*

  ⛔ **AND THE TAGGING IS NOT MINE TO SELF-AUTHORIZE.** *The categories are judgments about
  what the CAPTAIN was doing — DIRECTING vs WATCHING, decided by the counterfactual "would
  the artifact exist without this touch?" — and this seat assigning them unilaterally would
  make the campaign's headline dependency figure a number the measurer chose.* **The
  worksheet is generated and ready (8 blocks, ids, seats, durations, opening text); the
  categories want the maestro's or the Captain's call before 05:30.**
- ⚠️ **SEAT-SUPPLIED NEGATIVES ARE CITED AS FILES, NOT RECONSTRUCTED** —
  `docs/silicon-*-0807.md`, `docs/hdl-c*-0807.md`, `docs/EVIDENCE-refute-*-0807.md`. *Nothing
  in §3 paraphrases another seat's finding from the bus.*

---

## 4. IN FLIGHT AT CLOSE

**AT CLOSE, mine:** the **sampled/exhaustive column** ⛔ BLOCKED on a fanin-restricted congruence lemma that does not exist (`EVIDENCE-proof-debt-table-0807.md` §5) · the **census tool** ⛔ in scratch until raw == cleaned (`MERELY-BUILT` is `86 ≤ n ≤ 112`, the residue is `deriving` instances that cannot be separated by name) · **`regNext8_correct`** ⛔ a SAMPLED certificate carrying an unqualified name, 9 enable patterns of 2⁸ · **human-time re-tagging** ⛔ owed before 05:30 · **5 modules** ⛔ still outside the closure · the **49 unaudited theorems** ⚖️ awaiting the maestro's ruling on whose convention binds.

⇒ **and the standing ones: **B0(c) Captain-awaited** · the cone-width
census · **R2 the memory model** (S2 is unimplementable at interesting N
until it lands) · the `step`↔`stepT` compatibility obligation.

⚠️ **SHUTTLE CAPACITY IS A LIVE RISK WITH A MEASURED SLOPE:** tiles
**222 → 202** in one day, ours 4 of the 20 taken; PCBs `available:0` of 80.
**At ~20/day the 202 last ~10 days against a close 31 days out.** BB-1's
revision assumes a September slot exists.

---

## 5. COST — one line, unit named

**GENERATED 19:15 by `token_meter.py`, window `2026-08-07 00:00 → now`:**

| Project | Requests | Input | **Output** | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| `saltworks` | 2,912 | 5,441 | **3,010,831** | 11,469,954 | 1,303,961,258 |
| `salt` | 1,768 | 8,576 | **985,985** | 10,020,417 | 653,762,335 |
| **TOTAL** | **4,680** | **14,017** | **3,996,816** | **21,490,371** | **1,957,723,593** |

⚠️ **THE UNIT IS OUTPUT TOKENS — 3,996,816.** *Cache read (1.96 bn) is reported in its own
column and is not the cost figure; conflating them inflates the number ~490×.*
column, never in a headline⟩

⚠️ **Subagent tokens are a DIFFERENT UNIT from output tokens** — yesterday a
workflow reported "507,808 subagent tokens" whose *output* share was
**7,269 (1.4%)**. Quoting the large number as cost overstates output ~70×.
⚠️ **Per-account attribution remains underivable** — reported as a gap.

---

## 6. HUMAN TIME — and what the number is not

**GENERATED 19:15 — and it reports a DEFECT rather than a figure: 224 touches read in
window, 8 blocks, 11h 14m engaged, `100.0% UNTAGGED`, THE CLAIM `0h 00m`.** ⛔ **See §3:
the zero is nine detached tags, not an absence of human direction.** *No human-time figure
is published tonight.*

⛔ **THE CLAIM MUST NOT BE PUBLISHED AS A PERCENTAGE.** The charter tests each
**touch**; the tool tags each **block**; a block containing one irreducible
order drags its whole duration in. **Quote it as a coarse upper bound or not
at all.**

⛔ **AND PROVENANCE NOW GATES IT. GENERATED 19:15 by `nudge_detect.py`: 2,406 touches
classified HUMAN across the record, correlation window 300 s, and the `tmux send-keys`
channel is detected — 8/6 17:07 into `salt:5bc2f991` from `fleet:math`.** — machine-
transported touches are **not** the human typing into that seat. Day-1
measure: **32 of 2,171 (1.5%)**. `[R]` additionally excludes `MAESTRO:`-tagged
instructions, self-deferrals, and **orders for work already landed**.
