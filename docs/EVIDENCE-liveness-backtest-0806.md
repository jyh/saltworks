# SEAT-LIVENESS — the first six hours, and what BACKTESTING found that the output never showed

EVIDENCE seat, 2026-08-06, written on the Mac Mini after the relight.
Subject: `docs/ledger-tools/fleet_hygiene.py`'s seat-liveness half — the
table that says which of the five seats is alive, working, or gone.

---

## 1. What it claimed, all day

The detector pairs two independent signals per seat:

* **transcript idle** — has the seat's own session written anything? (If not:
  **STALLED**; nobody is driving it, and that is the one that needs a human.)
* **bus post age** — has it posted to `FLEET.md`? (If not: **SILENT**; the
  seat is working, the bus is stale.)

Threshold for both: **6 hours**. Over roughly six hours of operation it
reported **`✅ Every seat is both alive and reporting`**, and **it never
raised a single flag.**

That report was wrong twice, and **neither error was visible in its output.**

---

## 2. The method: score the detector against the day it watched

Rather than read the detector's verdicts, reconstruct the ground truth
independently — every bus post by every seat, and every session's record
stream — and ask what the detector *would* have said at each half-hour mark.

**A detector nobody has scored is a detector nobody should quote.** This is
the day-1 principle turned on the instrument that watches the seats:
*what would it say if the thing it watches were broken?*

---

## 3. ⛔ DEFECT 1 — the parser was blind to 26% of the bus, and it punished the most rigorous seat

`POST_RE` required the closing bracket **immediately after the seat name**:

```
^\[(\d{1,2})/(\d{1,2})\s+([^,\]]*?),\s*([A-Za-z][\w -]*)\]
                                                        ^ this
```

So a post of the form

```
[8/6 13:58, math — `date`-verified] ⛔ MIGRATION CATCH — …
```

**did not match at all.** That annotation is *the fleet's own timestamp-hygiene
convention*, adopted after the clock-drift finding, and math uses it on
essentially every post.

⭐ **The seat that follows the timestamp rule most rigorously is the seat this
detector reported as most stale.**

| Seat | Reported last post | Actual last post | Understated by |
|---|---|---|---:|
| **math** | 12:22 | **15:52** | **210 min — 58% of the threshold** |
| evidence | 14:30 | 15:49 | 79 min |
| compiler | 14:55 | 15:51 | 56 min |
| maestro | 15:36 | 15:36 | — |
| silicon | 15:26 | 15:26 | — |

**22 of 144 bracket posts dropped.** And a second, disjoint miss: the
maestro's own convention — `- 08-06 13:52 MAESTRO: …` — was matched by *no*
pattern in the file, costing **22 more**. Between them the scanner read
**122 of 166 posts: it was blind to 26% of the bus.**

Two more hours of the same and it would have raised a **false STALL against
math**, on the strength of a missing character.

✅ **Fixed:** the seat name no longer has to be followed by `]`, and `DASH_RE`
parses the maestro's convention. math's reported staleness went from
**3.4 h → 0.2 h** on the next run.

---

## 4. ⛔ DEFECT 2 — the threshold is 3.2× the largest event that has ever happened

Measured across the whole day's bus traffic (168 posts, five seats):

| Bus posting, 2026-08-06 | Value |
|---|---:|
| Median gap between posts | **6 min** |
| p95 | 39 min |
| **Largest real gap, any seat, all day** | **111 min** |
| Threshold | **360 min** |
| **Headroom** | **3.2×** |

**The alarm could not have fired, whatever happened.** Its clean report
therefore carries *no information about seat health* — it says only that
nothing exceeded a bound that nothing came near.

This is the **unbreached `-M` cap**, exactly, in a different file: *an
instrument that cannot distinguish UNTESTED from WORKING rated the day green.*
The fleet spent four hours today on that distinction for the memory cap while
the same defect sat unremarked in the liveness detector.

✅ **Fixed — by printing the ratio, not by moving the number.** Every report
now carries the calibration table above and, when headroom exceeds 2×, states
in the report itself that the green verdict is uninformative. **A threshold
chosen to make an alarm fire is not a measurement either**, so the number was
left alone and the reader was told where it sits.

---

## 5. The two defects compound, and that is the part worth publishing

Either alone is minor. Together:

* the parser **inflated** every seat's apparent staleness (by up to 3.5 h), and
* the threshold sat **so far above real behaviour** that even a 3.5-hour
  inflation could not push a seat across it.

⇒ **The second defect HID the first.** A tighter threshold would have fired a
false STALL on math and the parser bug would have been found in the morning.
The loose threshold suppressed the alarm that would have exposed the parser —
**two defects that each made the other invisible, in one 900-line file, both
reporting green.**

*Neither was discoverable from the detector's output. Both fell out of one
backtest.*

---

## 6. What is now covered, and what still is not

`selftest.py` is at **85 checks**, up from 67 this morning. New this pass:

* the bus parser — plain, annotated, dash-convention, and a negative case
  (a prose line that must **not** parse as a post);
* the calibration — it must show large headroom on a tight day and
  **headroom < 1** on a day with a gap past the threshold;
* the record-coverage detector and its blindness guard (see
  `EVIDENCE-ledger-latest.md` §0).

⚠️ **Still uncovered, and stated rather than left to be found:** the rest of
`fleet_hygiene` — process detection, lock state, the memory readout — plus
`token_meter`, `human_time` and `landed`. **The swap defect fixed earlier
today lives in exactly that uncovered region**, which is not a coincidence.

⚠️ **And the standing blind spot is unchanged:** this reads only
`~/.claude/projects/` for the user running it. A seat driven from another
account or machine is invisible — absence from the table is not evidence a
seat is down.

---

## 7. The tally this seat owes

Instruments I built today that reported success or danger they had not
verified: the fleet-hygiene detector printing two contradictory lines in one
report · `human_time` silently dropping its own tags · `free`-vs-`available`
in the report, then the monitor, then `--brief` · the swap threshold, which
the Mini falsified in two minutes · the bus parser · the liveness threshold ·
and the silence ledger reading a migration truncation as the campaign's
longest silence window.

**Every one was found by asking what the instrument would say if the thing it
watches were broken — and every one was in a tool I had already shipped and
believed.** The rate is not falling, which suggests it is a property of
building instruments rather than a run of bad luck; what has changed is that
the interval between shipping and catching is now measured in hours rather
than left to a postmortem.

---

# ADDENDUM — scored against TONIGHT's traffic (maestro's 19:16 order)

The afternoon backtest scored this detector against a régime whose largest
inter-post gap was **111 min against a 360-min threshold** — 3.2× headroom,
so it could not fire whatever happened. The order was to score it against
tonight instead: a genuinely different régime, five seats, **109 bus posts
between 17:00 and 20:00**. What that found is not what I expected.

## 1. ⛔ I MISREMEMBERED MY OWN TIMELINE, AND THE LEDGER CORRECTED ME

I set out to use my own 18:0x jam as the detector's **first ground-truth
positive** — a seat that demonstrably needed intervention, since the maestro
had to nudge me. I recalled the gap as **82 minutes** (17:23 → 18:45).

**It was not.** Measured from the bus: `17:23 → 18:08` = **45 min**, then
`18:12 → 18:45` = **33 min**. I had forgotten two posts I made at 18:08 and
18:12. **My largest real gap tonight was 45 minutes** — inside the evening's
normal range.

*The seat that owns the ledger misremembered its own timeline by 82%, in the
direction that made its story better, about events three hours old.* Caught
only because the claim was checked before it was published. **That is the
argument for the ledger, made against its author.**

## 2. THE TWO SIGNALS DIFFER BY ~300×, AND SHARE ONE THRESHOLD

`fleet_hygiene` pairs two independent signals and applies **the same
`QUIET_HOURS = 6.0`** to both:

| Signal | Verdict it drives | median | p90 | **max, whole day** | headroom to 360 min |
|---|---|---:|---:|---:|---:|
| **bus-post gap** (per seat) | **SILENT** | 6.0 min | 28 min | **111 min** | **3.2×** |
| **transcript idle** (per session) | **STALLED** | **0.02 min** (1.2 s) | 0.3 min | **67.4 min** | **5.3×** |

Evening only, bus posts: median **3.0 min**, p90 16 min, max **45 min**.

⛔ **One constant governs two quantities whose medians are 300× apart.** A
threshold merely loose for human-paced bus posts is absurd for machine-paced
transcript activity, where the normal gap is **just over a second**. Neither
can fire — for different reasons, at different scales — and the shared
constant hides that.

## 3. THE HUMAN'S THRESHOLD IS ~45 MIN. THE INSTRUMENT'S IS 360.

The only intervention that actually happened tonight was the **maestro
nudging this seat**, triggered by reading tmux panes, at a bus gap of about
**45 minutes**.

⇒ **The fleet operates to a ~45-minute standard and its instrument is
calibrated to 360** — **8× looser than the standard the humans in the loop
actually apply**, which is why every intervention today came from a person
and none from the tool.

## 4. THE HONEST NEGATIVE: NO BUS-GAP THRESHOLD WORKS ALONE

The tempting fix is to lower `QUIET_HOURS`. Measured, it does not survive:
at **80 min** (two missed posts under the visibility law's ~40-min cadence)
it fires **three times today** — math 111 min, maestro 104, silicon 104.
**None was stalled; all three were deep in work.** *A seat mid-build and a
seat that has stopped look identical on the bus.*

**That is precisely why the detector has two signals** — and why the one I
never scored, transcript idle, is the load-bearing half. It is the only one
that can tell them apart, its normal value is **1.2 seconds**, and a
67-minute transcript silence is genuinely abnormal rather than a busy
afternoon.

⇒ **RECOMMENDATION, derived rather than guessed: split the constant.**
`STALLED` from the transcript distribution (max observed 67 min ⇒ ~3 h is
meaningful and rarely false); `SILENT` from the visibility law's own
published cadence (~40 min ⇒ two missed posts ≈ 80 min, **reported as a
notice, not an alarm**, since it is a bus-hygiene fact rather than a health
fact). **Neither number is invented: one comes from measured behaviour, the
other from a rule the fleet already adopted.**

⚠️ **Not implemented tonight.** Changing an alarm threshold on the evening
the fleet goes unattended is the wrong moment to discover I was wrong about
it. Filed with its measurements, for a ruling at muster.
