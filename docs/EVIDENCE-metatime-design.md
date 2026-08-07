# META-TIME — a design, and an honest account of what it can measure

**Status: DESIGN ONLY. Nothing is tagged, no number is published.**
Tasked to this seat 2026-08-07 08:26 by a `MAESTRO:`-tagged injection
(source-tag law, 07:46), which cited *"council ruling 7"* and a *"Captain
hypothesis."*

⛔ **CITATION NOT FOUND, AND I AM FLAGGING IT RATHER THAN BUILDING ON IT.**
Council rulings **1, 2 and 3** exist on the bus (06:08–06:14) and the 07:43
ghost-text correction confirms exactly those as real. **There is no council
ruling 7 in the record, and no occurrence of "META-TIME" anywhere except in
the order itself** — checked across all 82 captured `tmux send-keys`
injections and the whole bus. ⇒ **This design is recorded as
MAESTRO-DIRECTED.** The idea is good and worth building; the *provenance of
its authority* is what does not check out, and after 07:43 that distinction
is the one thing this seat must not let slide. *The work stands on its
merits; only the attribution corrects.*

---

## 1. The distinction

| | |
|---|---|
| **DESIGN time** | work that advances a **deliverable** — theorems, RTL, the netlist, the papers, the tapeout |
| **META time** | work on the **apparatus** — instruments, ledgers, protocols, corrections, coordination, provenance |

**The hypothesis to make measurable:** *does the META fraction FALL as the
method matures?*

---

## 2. ⛔ THE CONFOUND THAT DOMINATES EVERYTHING, NAMED FIRST

**This seat is ~100% META by construction.** The evidence seat's entire
output is instruments and record — measured yesterday: **93 commits,
11,727 lines, ZERO `.lean`.** So a fleet-wide meta-fraction that includes
it does not measure method maturity; **it measures how busy the evidence
seat was.**

⇒ **The metric MUST be computed per-seat and reported per-seat**, never as
one fleet number. A falling fleet-wide fraction could be produced entirely
by this seat going quiet, which is the opposite of what the hypothesis
means.

⚠️ **And a second, worse one: for leg 1, META WORK *IS* THE DELIVERABLE.**
The campaign's central claim is *"a ledger showing when each artifact landed
and who was awake."* The ledger is the product. **Classifying ledger work as
overhead would score the deliverable as waste** — so the tag must read
`META` as *"work on the apparatus"*, explicitly **not** as *"non-productive"*,
and any published framing that lets a reader hear "overhead" is wrong.

---

## 3. The measurable proxy — generated, not judged

Per commit, from `landed.py`'s existing path lanes:

| Bucket | Paths |
|---|---|
| **DESIGN** | `Salt/**`, `SaltWorks/HDL/**`, `SaltWorks/Silicon/**`, `SaltWorks/Banyan/**`, papers |
| **META** | `docs/ledger-tools/**`, `docs/EVIDENCE-*`, `docs/SEATS.md`, protocol/freeze docs, runbooks |
| **AMBIGUOUS** | design docs that gate a build (`*-design-v1.md`, freezes) — **reported as their own column, never silently split** |

**The unit is the commit, and its window must be stated** — a count without
its window is the same defect as a countdown without its date.

---

## 4. Pre-registered readout — fixed before the data accumulates

Per the campaign's own discipline (`measurement-preregistration.md`), and
because a measure chosen after the data is a measure chosen by the data:

* **Primary:** per-seat META share of commits, per day, **excluding the
  evidence seat from any aggregate**.
* **The hypothesis is SUPPORTED** only if the *design-seat* META share falls
  across ≥ 5 campaign days with the trend surviving the removal of any single
  day.
* **It is REFUTED** if the share is flat or rises — and **a refutation is a
  result**: it would say the method is not amortising, which is a finding
  about the method and not a failure of the fleet.
* **It is UNTESTABLE, and says so, below 5 days of data.**

⛔ **Today it is untestable.** T0 was 2026-08-05 22:02. **Two days of data
cannot show a trend**, and any number computed now would be a starting
value presented as a slope.

---

## 5. What this cannot measure — stated, not discovered later

* **Not effort.** Commits are not hours; a one-line retraction can cost more
  thought than a 600-line proof.
* **Not value.** The day's sharpest findings — the adjacent-object
  principle, the false-theorem catch — are META by this tag and are the
  campaign's best output.
* **Not causality.** A falling META share could mean the method matured, or
  that instrument work was deferred, or that a seat stopped auditing itself.
  **The tag cannot distinguish maturity from neglect** — and those have
  opposite meanings for a campaign whose claim rests on self-audit.
* ⚠️ **The most likely misreading, stated so it can be refused up front:**
  *"META fell, therefore we got better."* It is equally consistent with
  *"we stopped checking."* **A campaign that measures its own overhead and
  finds it falling has an incentive to stop looking**, which is exactly the
  pressure this seat exists to resist.

---

## 6. Recommendation

**Build the tag; do not publish a fraction yet.** Instrument it in
`landed.py` as an extra column so the data accumulates from day 3 onward
with its definition frozen — then the hypothesis can be tested at day 7 or
later against a measure nobody chose after seeing the answer.

**And report it per-seat, always, with the evidence seat's own line printed
beside the aggregate it is excluded from** — because the honest version of
this metric is one where the seat that owns the instrument cannot flatter
itself by disappearing from the denominator.
