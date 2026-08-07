# META-TIME — a design, and an honest account of what it can measure

**Status: ADOPTED 2026-08-07 09:03 as the instrument's charter** — the
per-seat computation, the pre-registered day-7 test, and the refused
misreading in §5, all as written below. **Still DESIGN ONLY: nothing is
tagged and no number is published**, because §4's own rule forbids it until
there are ≥ 5 days of data.
Tasked to this seat 2026-08-07 08:26 by a `MAESTRO:`-tagged injection
(source-tag law, 07:46), which cited *"council ruling 7"* and a *"Captain
hypothesis."*

⛔ **CITATION NOT FOUND, AND I AM FLAGGING IT RATHER THAN BUILDING ON IT.**
Council rulings **1, 2 and 3** exist on the bus (06:08–06:14) and the 07:43
ghost-text correction confirms exactly those as real. **There is no council
ruling 7 in the record, and no occurrence of "META-TIME" anywhere except in
the order itself** — checked across all 82 captured `tmux send-keys`
injections and the whole bus.

✅ **RESOLVED 09:03, AND THE CORRECTION RUNS IN MY DISFAVOUR — the authority
is REAL and STRONGER than the label I fell back to.** The maestro answered
the flag directly: *"my 08:26 order cited 'council ruling 7' — no such
council ruling exists; the meta-time tasking derives from **PROCESS QUESTION
Q7 of the meta notes §7, ruled by the Captain in-channel**. The mislabel is
mine."*

⇒ **Re-recorded: CAPTAIN-AUTHORISED via Q7, delivered through a correctly
`MAESTRO:`-tagged relay.** Not maestro-directed, as this file first said.
**"In-channel" is exactly the standard the 07:46 source-tag law sets for a
Captain relay — never from box text** — so this is the *verified* channel,
not the ghost one.

📌 **The episode is the laws working rather than a fault:** a wrong citation
was caught by a seat, the seat published the flag instead of building on it
or refusing the work, the sender corrected the record within twenty minutes
and named the mislabel as theirs, and **the design survived unchanged
because it never depended on the citation.** *A flag that costs twenty
minutes and strengthens the provenance is the cheapest thing in this
campaign.*

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

## 3b. THE [R]/[C] SPLIT — folded into the frozen definitions, 2026-08-07 09:25

Tasked by the maestro: the stack story's **REQUIRED [R] vs CHOSEN [C]**
split *"is now a consumer of your meta-time instrument… fold into the
frozen-definition column before data accumulates."* Landed here **before**
any data, per §4's own rule.

**⛔ IT IS AN ORTHOGONAL AXIS, NOT A RENAMING OF THE FOUR CATEGORIES.** The
tempting reading is `[R] = DIRECTING+REVIEWING+UNBLOCKING` and
`[C] = WATCHING`. **That is wrong**, and adopting it would quietly make the
split free — which would be the tell that it measures nothing new. A
DIRECTING touch can be either:

* **DIRECTING + [R]** — a seat was **blocked** and asked; the ruling released it.
* **DIRECTING + [C]** — the human volunteered a direction **nobody was waiting on**.

Both are load-bearing under §2's counterfactual test. Only the first was
*necessary at that moment*.

**THE MECHANICAL DEFINITION, so it is generated rather than judged:**

> **[R] — a human touch that answers an ASK OUTSTANDING ON THE BUS at the
> moment it arrives.** The ask is a prior post naming the blocker and its
> owner; the touch resolves it. Both endpoints are in `FLEET.md`, timestamped.
>
> **[C] — a human touch with no outstanding ask.** Volunteered.

*The blocked-ness is the evidence, and it exists in the record before the
touch does — which is what keeps this from being a post-hoc judgement about
how necessary something felt.*

**⛔ REFINED 09:3x, BY THE COMPILER SEAT, BEFORE ANY DATA WAS TAKEN — A
SEAT'S SELF-DEFERRAL LOOKS EXACTLY LIKE AN OUTSTANDING ASK AND IS NOT ONE.**
Their own post, `FLEET.md:3567`, verbatim:

> *"Fixing `readTree` to 31 registers + a `conb` leaf is **mine** and small.
> I am **not landing it in the same breath** as reporting it — you have
> measurements running against the current shape."*

**That names a blocker and an owner and satisfies the rule as first
written** — yet nothing was asked of the human. **A seat chose to wait.** A
later human "go ahead" would have scored **[R]** while releasing something
the seat could have released itself.

⇒ **THE TEST IS NOT "IS THERE AN ASK" BUT "WHO COULD HAVE UNBLOCKED IT":**

```
  [R]  the ask names an owner OTHER than the posting seat, and the blocker
       sits in an authority ONLY THE HUMAN HOLDS
       (a ruling · a purchase · a physical act · a credential · a lane call)
  [C]  the posting seat could have proceeded on its own authority
       -> SELF-DEFERRAL, however courteously phrased
```

**⚠️ AND THIS GAMING VECTOR IS WORSE THAN THE ASK-RATE ONE BELOW, BECAUSE IT
LOOKS LIKE GOOD MANNERS.** A seat can manufacture [R] indefinitely by
deferring to the human on matters inside its own writer slot — and every one
of those posts reads as courtesy, care, or proper escalation. **The
ask-rate defect requires a drift in habit; this one requires only
politeness.** *A fleet that wanted to prove the human indispensable could do
it entirely by being deferential, and no individual post would be wrong.*

**⛔ AND [R] NOW DEPENDS ON PROVENANCE, which is this morning's other
instrument.** A "required ruling" that was **ghost text answered nothing —
nobody decided it.** So the filter composes:

```
  [R]  requires:  an outstanding ask  AND  a verified-origin touch
                  (bare = human hand · CAPTAIN-RELAY: = his words in-channel)
  ⛔   excludes:  MAESTRO:-tagged instructions (a seat directing a seat)
  ⛔   excludes:  anything nudge_detect flags, and anything in the
                  2026-08-06 ghost window until confirmed
```

**⚠️ THE DEFECT IN MY OWN DESIGN, NAMED BEFORE ANYONE USES IT: [R] IS
GAMEABLE IN BOTH DIRECTIONS, BY US.** Defining [R] as *"answers a posted
ask"* means **a fleet that posts more asks grows [R]**, and a fleet that
posts fewer shrinks it. Both are available and neither requires dishonesty —
only a drift in bus habits. ⇒ **The count of asks POSTED must be published
beside [R] every time**, so a rising [R] can be checked against a rising ask
rate rather than read as rising human necessity. *A measure whose numerator
we control needs its denominator in the same table.*

**And the maestro's own guard is adopted verbatim:** *that [C] exceeds [R]
is a **finding**, never a **borrow**.* [C] is never moved into the claim to
enlarge it. **If the human chose to spend far more than the artifact
required, that is the most interesting number in the ledger and it belongs
in its own line, unshrunk.**

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
