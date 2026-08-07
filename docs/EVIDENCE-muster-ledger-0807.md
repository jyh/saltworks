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

⟨REGEN: `landed.py` per-lane table — commits · lines · `.lean` · **and the
new META/DESIGN/AMBIGUOUS column**, frozen 8/7 and pinned by 9 self-tests⟩

**Window: `2026-08-07 00:00 → close`, both repos, all seats** — stated on the
section, because *a count without its window is the same defect as a
countdown without its date.*

⚠️ **Lane attribution is a PATH HEURISTIC**, not a claim about who typed
what. ⚠️ **The evidence row is EXCLUDED from any META aggregate** — this seat
is ~100% META by construction, so including it measures how busy I was.

---

## 2. THE GATES THAT MOVED

| Gate | State | Verification status |
|---|---|---|
| **BB-1 / B2M — the composed switch's mathematics** | `batcher8_banyan_selfrouting`; `StrictMonoOn` discharged **by the network**; four goal-FALSE controls | ⟨REGEN: verify at the bytes — theorem present, controls present, `#audit_axioms` clean⟩ |
| **C4 construction** | ungated under the ratified partiality spec | ⟨REGEN⟩ |
| **C2 witnessed** | Spike **and** Sail, 120/120 | ✅ **VERIFIED at the bytes 8/7** — both pinned, `encode` absent from the generator path |
| **C3 finalized → v1.1** | structural emission; Route B ruled in | ✅ decision sound · ⚠️ **citation corrected**: `100%` boundary vs `60.1%` cone are different quantities |
| **The banyan is SUBMITTED** | in the TTSKY26c queue, tile 2×2 | ⚠️ **ATTESTED, not measured** — gates verified, the click cannot be |
| **Import closure** | ⟨REGEN: `import-closure.py`⟩ | the exit code **is** the finding: 0 covered · 1 outside · 2 could not read |

---

## 3. HONEST NEGATIVES — results, with mechanism

- **The stale-board mode** — a fix landed 07:19, a touch ordered it later; open on the board, closed in the repo, **stale across a reboot**. *Maestro-side, recorded because the syllabus records modes wherever they live.*
- **The ghost-text injection class** — client autocomplete delivered as keystrokes, **no author at all**; closed by **protocol** (source tags + style filtering), not by a better detector.
- **`2027-03-27 chips expected` is UNSOURCED** — read at source 8/7: the runs table's `Chips expected` cell for TTSKY26c is **empty**.
- ⟨REGEN: any §0 coverage hole; the 8/6 `e3ea8f1` gap remains OPEN, cause UNDETERMINED⟩
- ⟨REGEN: seat-supplied negatives — silicon's, compiler's, math's own muster lines, **cited as files, not reconstructed**⟩

---

## 4. IN FLIGHT AT CLOSE

⟨REGEN⟩ — and the standing ones: **B0(c) Captain-awaited** · the cone-width
census · **R2 the memory model** (S2 is unimplementable at interesting N
until it lands) · the `step`↔`stepT` compatibility obligation.

⚠️ **SHUTTLE CAPACITY IS A LIVE RISK WITH A MEASURED SLOPE:** tiles
**222 → 202** in one day, ours 4 of the 20 taken; PCBs `available:0` of 80.
**At ~20/day the 202 last ~10 days against a close 31 days out.** BB-1's
revision assumes a September slot exists.

---

## 5. COST — one line, unit named

⟨REGEN: `token_meter.py` — requests · **OUTPUT tokens** · cache in its own
column, never in a headline⟩

⚠️ **Subagent tokens are a DIFFERENT UNIT from output tokens** — yesterday a
workflow reported "507,808 subagent tokens" whose *output* share was
**7,269 (1.4%)**. Quoting the large number as cost overstates output ~70×.
⚠️ **Per-account attribution remains underivable** — reported as a gap.

---

## 6. HUMAN TIME — and what the number is not

⟨REGEN: `human_time.py` totals + the tagging worksheet⟩

⛔ **THE CLAIM MUST NOT BE PUBLISHED AS A PERCENTAGE.** The charter tests each
**touch**; the tool tags each **block**; a block containing one irreducible
order drags its whole duration in. **Quote it as a coarse upper bound or not
at all.**

⛔ **AND PROVENANCE NOW GATES IT.** ⟨REGEN: `nudge_detect.py`⟩ — machine-
transported touches are **not** the human typing into that seat. Day-1
measure: **32 of 2,171 (1.5%)**. `[R]` additionally excludes `MAESTRO:`-tagged
instructions, self-deferrals, and **orders for work already landed**.
