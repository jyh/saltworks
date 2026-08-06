# PRE-REGISTERED EXPERIMENT — does `(* keep *)` survive TinyTapeout's OWN CI?

**Owner of the question:** silicon (open ruling 4a, `docs/EVIDENCE-campaign.md`).
**Owner of this design:** the EVIDENCE seat. Written 2026-08-06, on the Mac
Mini, **before either run is fired** — the readout is fixed here so that it
cannot be chosen after the answer is visible.

This is not a recommendation to run something. It is the *shape* the run has
to have to be worth anything, plus the three things that would make a green
result meaningless.

---

## 1. The question, stated narrowly enough to be answerable

Ruling 4a established, by measurement (`002abc1`), that marking the fabric's
stage boundaries `(* keep *)` makes them survive **our local** synthesis as
real nets — `wire [7:0] w0; wire [7:0] w1;` appear in
`SaltWorks/Silicon/Flow/banyan_fabric_nl.v:261-262`, driven by real cells
(`.Y(w0[7])`, `.A(w0[3])`, …) — at a **1.7 % area cost** (2,108 → 2,143 µm²),
raising per-cone coverage **86.9 % → 94.8 %**.

⚠️ **None of that is evidence about the netlist we will fabricate.** Dossier
§6 is unambiguous: *"The netlist that gets fabricated is produced by
TinyTapeout's CI, not by our LibreLane run."* The `gds` job runs
**`librelane==3.0.5`**; the devcontainer pins **`librelane==2.4.2`**. Local
and CI hardening **are not the same major version**.

**THE QUESTION IS THEREFORE:** does the CI flow that produces
`tt_submission/tt_um_saltworks_banyan.v` preserve the stage boundaries as
nets — and, more to the point, does it leave the **combinational cones small**?

---

## 2. ⛔ THE PRIMARY READOUT IS NOT THE NET NAME

The obvious test is to grep the CI netlist for `w0`. **That answers a
narrower question than the one that matters**, and this seat has spent the
day cataloguing exactly that error in other people's instruments.

| What we would measure | What it actually tells us |
|---|---|
| `w0` appears in the CI netlist | a *name* survived |
| **max inputs per combinational cone** | **whether per-cone certification closes** |

The proof architecture does not depend on a name. It depends on ruling 4c's
number: the **flattened** fabric's `dout` cones reach **36 inputs**, one
sliced net at 36 bits is **8.6 GB**, and the hard kernel ceiling is **24 bits**
(`Nat.pow` is GMP-accelerated only to exponent `1 <<< 24`). A netlist could
retain a net called `w0` and still present 36-input output cones if that net
is not acting as a cut point.

⇒ **PRIMARY READOUT: the cone census over `tt_submission/<top>.v` — the same
census that produced the 86.9 % / 94.8 % figures, run on the CI artifact.**
**SECONDARY (mechanism): the net-name grep**, which explains *why* the census
came out as it did. Report both; lead with the census.

---

## 3. ⛔ AND A SINGLE RUN CANNOT ANSWER IT — THE A/B PAIR IS THE DESIGN

If we fire one CI run with `(* keep *)` in place and the boundaries survive,
we have learned **nothing about the attribute**. The nets might have survived
anyway — because they are wide, because they feed many loads, because the
wrapper's port structure pins them. *A certificate without a control can be
vacuous and still look green* — the D3/D3.5/D4 mutation discipline, applied
to a flow experiment instead of a Lean theorem.

**So: two CI runs, differing in exactly one character-level edit.**

| Arm | RTL | Everything else |
|---|---|---|
| **A (treatment)** | `banyan_fabric.v:63` as it stands: `(* keep *) wire [7:0] w0, w1;` | identical |
| **B (control)** | the attribute deleted: `wire [7:0] w0, w1;` | identical |

**The control IS the experiment.** Run B is the mutation, and it plays exactly
the role that putting the 10:52 routing bug back plays in D4.

---

## 4. The pre-registered outcome table

Fixed now, before either run exists.

| # | Census (primary) | Names (mechanism) | Verdict | Consequence |
|---|---|---|---|---|
| **(a)** | cones small in **A**, large in **B** | `w0`/`w1` in A, absent in B | ✅ **`(* keep *)` survives CI and does the work.** Ruling 4a closes YES | the fabricated netlist may be certified per cone at the stage boundaries |
| **(b)** | cones large in **both** | absent in both | ⛔ **CI strips it.** Ruling 4a closes NO | **the expensive outcome.** Per-cone certification of the CI netlist does **not** close (ruling 4c: 36-input cones, 8.6 GB/net). The proof architecture needs a different cut, and D5 must not be planned as though this were settled |
| **(c)** | cones small in **both** | `w0`/`w1` in both | ⚠️ **VOID as an attribute test.** The boundaries survive for a reason that is not the attribute | good news for the proof, no information about `(* keep *)`. Re-run the control against a net that would *certainly* be optimised away, or accept the good news and stop asking the attribute question |
| **(d)** | one arm's GDS action **fails** | — | ⚠️ a finding in its own right | the attribute changes flow behaviour beyond net naming; report before interpreting anything else |

**(b) is the outcome that costs the most, which is exactly why this runs
early rather than at D5.** An experiment scheduled after the architecture
depends on its result is not an experiment.

---

## 5. ⚠️ THREE CONFOUNDS, one of which nobody has named

**5.1 — THE CI HARDENS A DIFFERENT TOP MODULE THAN THE LOCAL RUN DID.**
Silicon's local measurement hardened **`banyan_fabric`**. TT's CI hardens
**`tt_um_saltworks_banyan`** (`info.yaml: top_module`), which *instantiates*
`banyan_fabric` and adds the pad/enable/power-gating wrapper. **The CI run
therefore flattens across one more level of hierarchy than the local run
did**, and flattening across a boundary is precisely the operation under test.
⇒ **A and B must both harden the TT top module.** Comparing a CI wrapper run
against the local fabric run would confound the attribute with the extra
hierarchy level, and the difference would be reported as an attribute effect.
*This is the confound most likely to be missed, because both numbers would
look like "the fabric".*

**5.2 — TOOLING SKEW BETWEEN THE TWO ARMS.** Dossier §6.4: the shuttle repo
pins its `tt` submodule at `ff75e34`, and a reproducible claim requires
pinning `tools-ref` to a commit SHA in the workflow. **If A and B are fired
days apart against a floating ref, a tooling change is indistinguishable from
the attribute.** ⇒ pin `tools-ref` identically in both arms and fire them
close together; record both `commit_id.json` values from the artifacts and
**check they match before reading anything else.**

**5.3 — POST-P&R RENAMING.** Post-place-and-route nets are largely
machine-named (`_000_`, `_001_`, … dominate the local netlist). The absence of
`w0` is therefore only meaningful *relative to a run where it is present* —
which is the A/B pair again, and the reason a single-arm grep would be
uninterpretable even for the mechanism question.

---

## 6. The readout, by artifact and by line

**Source of truth: the `tt_submission` artifact from the `gds` job.** Per
dossier §6 it contains `<top_module>.v` (the gate-level netlist),
`stats/metrics.csv`, `pdk.json`, `resolved.json`, `commit_id.json`. Both
`precheck` and `gl_test` consume that artifact, so it is the object TT itself
treats as the design — and consequence #1 of §6 already says the equivalence
proof must be against it rather than against a local
`runs/RUN_*/final/nl/*.logical_nl.v`.

| # | Readout | From | Recorded as |
|---|---|---|---|
| 1 | **cone census: count, max inputs, distribution** | `tt_submission/<top>.v` | the primary table; compare against the ≤ 24-input ceiling and against 4b's 86.8 % baseline over 1,626 cones |
| 2 | declared nets matching `w0`/`w1` | same file | present / absent, per arm |
| 3 | cell count, cell types, area | `stats/metrics.csv` | secondary; see §7 |
| 4 | `commit_id.json` | artifact | **checked equal across arms before anything else is read** |
| 5 | `gl_test` result | gds workflow | a control on the control: the attribute must not change *function* |
| 6 | the GDS action's **text** | workflow log | judged as text, never by a bare exit code — the fleet's exit-taxonomy rule |

---

## 7. Area is not a decision variable at our size — stated so nobody trades correctness for it

The local cost was **1.7 %** (2,108 → 2,143 µm²). The fabric is **259 cells /
2,108 µm² = 11.8 % of ONE tile**, against **four tiles bought**. 1.7 % of
11.8 % is **≈ 0.2 % of a single tile, ≈ 0.05 % of the purchase.**

⇒ **If the census says `(* keep *)` buys a certifiable netlist, the area
question is closed by arithmetic, not by judgement.** Record the CI figure
because it is free to record, and do not let it enter the decision.

---

## 8. What this experiment CANNOT tell us — named, per the house rule

- **It cannot tell us the fabricated netlist is correct.** It tells us whether
  the *shape* we intend to certify survives to the artifact. The equivalence
  proof is a separate obligation, against the same artifact.
- **It cannot generalise to the next shuttle.** `librelane==3.0.5` and the
  pinned PDK are this shuttle's. A result here is dated and versioned, and
  should be quoted with both.
- **A green (a) does not prove the cones stay small under a later RTL
  change.** The census is a property of a netlist, not of the design; it is
  re-measured per submission, the same way the trusted cell set is
  (4c: 21 cell types flattened against 6 per element — *the trusted model set
  grows with flattening, not with design size*).
- ⚠️ **And it cannot be run by this seat.** EVIDENCE owns no RTL, no
  `info.yaml` and no workflow. This document is a design handed to silicon;
  the numbers in §6 are theirs to produce, and the outcome table above is
  binding on the reading, not on the running.

---

## 9. Cost and scheduling

A typical small design's GDS action takes **~5 minutes** (dossier §5). Two
arms on branches ≈ **10 minutes of CI**, zero shuttle cost, zero risk to the
submission — *the GDS action gates **submission**, not experimentation.*

**Against the tapeout clock** (hard deadline 2026-09-07 13:00 PDT; internal
target 2026-08-31), ten minutes of CI to settle whether the proof
architecture holds is the cheapest item on the board — and outcome (b) is
one whose discovery cost rises every day it is deferred.
