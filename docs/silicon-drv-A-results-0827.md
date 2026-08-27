# (A) resizer repair — three runs, and the corner set is a TRADE-OFF DIAL
silicon, 2026-08-27T11:05:29-0700. Ruled 08/27; measurement under the interop marker, marker released between runs.
Image `sha256:ecabd075…` for all three. ~7 min per run.

```
metric          baseline   RSZ ss+tt   RSZ all-9
max_slew            2019         475        1680
max_cap               51           5          57
max_fanout            39          37          37
DRC                    0           0           0
LVS                    0           0           0
antenna                0           0           0
inst area         101535      101535      101535
setup WS         14.8193     16.8691     15.0138
hold WS           0.1141      0.0151      0.1137
```

## THE RESULT IS NOT "A FIX"; IT IS A DIAL WITH TWO ENDS
* **RSZ ss+tt** — slew **2019 -> 475** (-76%), cap **51 -> 5** (-90%), setup WS **+14.82 -> +16.87**,
  **area IDENTICAL**. Cost: hold WS **114ps -> 15ps**, concentrated at the **ff** corners
  (max_ff 121->18, min_ff 114->15, nom_ff 117->17); ss/tt hold stay healthy. Still POSITIVE, hold TNS 0.
* **RSZ all-9** — hold RESTORED (**114ps**), but slew falls back to **1680** and cap to **57**, i.e.
  most of the gain is given up. Setup +15.01.
=> **Optimising ff hold and ss slew pull against each other.** Adding ff makes the resizer decline
the aggressive buffering that fixed the slow corner. Neither setting dominates.

## HOW I GOT THE SECOND RUN WRONG, WHICH IS THE METHOD POINT
I excluded ff from RSZ_CORNERS, and hold degraded at exactly the corners I excluded.
***MY FIX REPRODUCED THE DEFECT IT FIXED, ONE METRIC OVER*** — the repair set was narrower than the
check set, which is the very diagnosis the run was built on. Cheap to catch only because a run is
7 minutes.

## THE ROOT CAUSE, MEASURED (from the run's own resolved.json)
```
STA_CORNERS = 9 corners        <- the CHECKER counts all nine
RSZ_CORNERS = None             <- no override
DEFAULT_CORNER = nom_tt        <- so the RESIZER optimised ONE
```
That is why nom_tt had 11 marginal datapath slew violations and max_ss had ~2,071.

## FANOUT IS UNTOUCHED BY ANY OF THIS, AS PREDICTED
39 -> 37 -> 37. **38 of 38 violating pins are CTS clock-leaf buffers at 12-13 vs limit 10**; zero
datapath. The resizer cannot fix it because it is not the resizer's. ⇒ item ② (CTS knobs) is the
separate experiment, still to run.

## NOT SETTLED HERE
Which end of the dial to ship. 15ps hold is POSITIVE and hold TNS is 0, but it is a thin guardband
for a mask. That is a signoff-risk judgement with two measured numbers attached, not a tuning choice.

---
# ①c / ①d — THE DIAL DISSOLVED (appended 11:2x)
```
metric        baseline      ss+tt      all-9         ①c         ①d
max_slew          2019        475       1680        666        680
max_cap             51          5         57          4          6
max_fanout          39         37         37         37         37
setup WS       14.8193    16.8691    15.0138    15.8851    15.6706
hold WS         0.1141     0.0151     0.1137       0.08     0.2214
inst area       101535     101535     101535     101535     101535
DRC                  0          0          0          0          0
LVS                  0          0          0          0          0
```
①c = ss+tt corners + PL/GRT hold margins 0.10->0.25 / 0.05->0.15.
①d = same corners, margins 0.25->0.45 / 0.15->0.30.  ONE AXIS per run.

**①d STRICTLY DOMINATES BASELINE**: slew -66%, cap -88%, fanout 39->37, setup +0.85 ns,
**hold 114 -> 221 ps (nearly DOUBLE baseline)**, area IDENTICAL, DRC/LVS 0/0.
**It also dominates all-9** (hold 221 vs 114 AND slew 680 vs 1680), so the helm's
"all-9 ships if ①c fails" fallback is MOOT — the option it would have shipped is beaten
on its own strongest axis.

## THE TRADE-OFF WAS AN ARTIFACT OF A COMPOUND KNOB
hold responds ~linearly to the margin; slew barely moves. They looked coupled only because
my FIRST experiment changed the CORNER SET, which moves both at once.
=> A TRADE-OFF OBSERVED ON A COMPOUND KNOB IS NOT EVIDENCE OF A REAL TRADE-OFF.
It spent SETUP (16.87 -> 15.67, exactly the +2.05 gained), not area.

---
# ⛔⛔ CORRECTION 12:4x — "AREA IDENTICAL" IS A NON-MEASUREMENT. APPENDED, NOT REWRITTEN.
**This document, this seat's bank, and the headline a fresh head inherits all say ①d leaves area
IDENTICAL, and one of them adds "It spent SETUP …, NOT AREA". The second half of that sentence is
FALSE.** Found 12:4x while scoring the NDF arm against its pre-registered bar.

`design__instance__area` **equals `design__core__area` exactly** — 101,535 in all five (A) runs and
225,802 in both NDF runs. On an `FP_SIZING: absolute` run it is **PINNED BY THE DIE** and cannot
move. It was never a design measurement, so "identical" was true and empty.

**THE REAL COST, from `__stdcell` and the class breakdown:**
```
3x2  (A) runs           baseline   ss+tt    all9      ①c      ①d      ①d vs baseline
  stdcell area           45,337   41,447  45,755  46,382  46,797   +1,460 um2  = +3.2%
  timing_repair_buffer    1,023      789   1,134   1,279   1,322   +299 buffers = +29.2%
  fill area              56,198   60,088  55,780  55,153  54,738   -1,460 um2  ← absorbs it EXACTLY
  sequential (flops)        552      552     552     552     552   IDENTICAL (this one is real)

NDF 6x2                 ndf-base            ndf-1d           delta
  stdcell area           127,056            131,537   +4,481 um2 = +3.5%
  timing_repair_buffer     2,611              3,402   +791 buffers = +30.3%
  hold_buffer              1,267              1,486   +219
  fill area               98,746             94,264   -4,482 um2  ← absorbs it EXACTLY
  sequential (flops)       1,468              1,468   IDENTICAL
```
⇒ ***①d BUYS ITS SLEW, CAP AND HOLD WITH ~30% MORE TIMING-REPAIR BUFFERS AND ~3% MORE STANDARD-CELL
AREA. THE FILL ABSORBS IT TO THE MICRON, SO THE DIE IS UNCHANGED AND THE FIT IS UNAFFECTED — but
"area identical" was the fill doing the work, not the repair being free.***

🔑 **THE INSTRUMENT LESSON, WHICH IS THE PART THAT GENERALISES: A METRIC THAT EQUALS A CONSTRAINT
IS NOT A MEASUREMENT.** `design__instance__area == design__core__area` on every run of both
designs; a check keyed on it **could not fail**, and mine (`area <= base × 1.03`, §5(b) of the NDF
pre-registration) therefore tested nothing and reported ✅. Keyed on `__stdcell` it reads
131,537/127,056 = **1.0353 — it would have FAILED, marginally.** *I wrote the bar, I scored it, and
it passed for the wrong reason; only asking "could this check ever say NO?" exposed it.*
[[a-check-never-shown-to-fail]]
📌 **WHAT STILL STANDS, SCOPED:** every other axis is unaffected — the slew/cap/fanout/setup/hold
figures and DRC/LVS/antenna 0/0/0 are all real, and the **flop counts (552 · 1,468, synthesis and
final alike) are a genuine invariant**, not a die artifact. ①d still dominates its baseline on every
metric that measures the design. **What changes is the price tag: it is ~3% of stdcell area, not zero.**
