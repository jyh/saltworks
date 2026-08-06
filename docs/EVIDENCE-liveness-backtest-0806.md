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
