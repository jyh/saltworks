# NDF PAIR — RESULTS. Part 1: the baseline reproduces the paid chip EXACTLY
silicon, 2026-08-27. Criterion pre-registered at `docs/silicon-ndf-pair-prereg-0827.md`
BEFORE either run; run 1 failed it and the failure analysis is appended there.

## 1 · ✅ `ndf-base` RUN 2 — A BIT-EXACT REPRODUCTION OF THE SUBMITTED SIGNOFF
12:21:42–12:29:37 (8 min). Image `sha256:ecabd075…`, PDK `8afc8346…` (TT's own), top
`tt_um_saltworks_ndf_c32`, 6×2 on TT's real power grid.

**THE GATE, which is configuration identity and not my judgement:**
```
resolved_diff.py  reference 411 keys · mine 411 keys · 0 NON-PATH difference(s)   ✅ EMPTY
```
**THE REPORT, which is now a consequence rather than the criterion:**
```
                                   TT signoff (run 32284710003)        my ndf-base
design__max_slew_violation__count                        3317                 3317
design__max_cap_violation__count                           27                   27
design__max_fanout_violation__count                       117                  117
timing__setup__ws                            5.66802087974297     5.66802087974297
timing__hold__ws                          0.11053214212320611  0.11053214212320611
design__instance__area                                 225802               225802
design__instance__area__stdcell                        127056               127056
design__instance__count                                 43884                43884
magic DRC · LVS · antenna                               0/0/0                0/0/0
```
⭐ ***ALL 320 SHARED METRICS ARE BIT-IDENTICAL.*** Setup slack agrees to fifteen significant
figures. This is not "within the bar" — it is the same numbers.

## 2 · WHAT THAT BUYS, STATED PRECISELY
1. **The ①d delta will transfer to TT's own figures directly.** §5(a)'s weaker "SIGNATURE-ONLY"
   branch — *delta valid, absolutes do not transfer* — **does not apply**; I can quote an ①d
   result against the submitted chip's numbers without a caveat about my environment.
2. **LibreLane 3.0.5 at a pinned PDK is DETERMINISTIC across machines** — a GitHub runner and this
   box produced identical floating-point timing. That is a fact worth having: it means a local
   pre-check can stand in for a CI round-trip for this design, at 8 minutes instead of a push.
3. **Run 1's +2.13 ns setup advantage was ENTIRELY the five misconfigurations** — nothing about
   the environment, the PDK path, or the host. The pre-registered bar attributed it correctly
   before I knew the cause.

⛔ **WHAT IT DOES NOT BUY, because an exact match invites over-reading.** It says my harness
reproduces the SIGNOFF FLOW's numbers. It says nothing about whether those numbers are GOOD, and
nothing about silicon behaviour: `max_fanout 117`, `max_slew 3,317` and `max_cap 27` are the paid
chip's REAL residuals and they are unchanged by having been reproduced. It is a statement about
**instrument fidelity**, not about the chip.

## 3 · 📌 THE METHOD POINT, WHICH OUTLIVES THIS CHIP
The gate that worked is **configuration identity**, not metric proximity:
> ***A CONFIG YOU WROTE IS A HYPOTHESIS; THE `resolved.json` IS WHAT RAN.***

Run 1 sat inside ±5% on all three DRV counts while the routing layer (met5 vs met4), the power-grid
pitch (153.6 vs 38.87) and the IO pin geometry were all wrong. **Metric proximity would have
certified it.** `resolved_diff.py` returns a set, not a similarity, and an empty set is the only
passing value — which is why the second run's agreement is worth something.

---
# Part 2 · ①d ON THE PAID CHIP — IT DOMINATES, AND THE PRICE IS ~3% STDCELL, NOT ZERO
`ndf-1d`, 12:30:06–12:38:52 (8.8 min), same image and PDK as the baseline.

## 4 · TREATMENT VERIFIED APPLIED — AND ONLY THE TREATMENT
```
resolved_diff vs the SUBMITTED chip:  EXACTLY 3 non-path differences
   RSZ_CORNERS                     ref=None   me=[nom_tt, max_ss, nom_ss, min_ss]
   PL_RESIZER_HOLD_SLACK_MARGIN    ref=0.1    me=0.45
   GRT_RESIZER_HOLD_SLACK_MARGIN   ref=0.05   me=0.30
```
⭐ **THREE, AND EXACTLY THE THREE I SET.** The same gate that returned EMPTY for the baseline
returns precisely the treatment for the arm — so the treatment applied *and* nothing else drifted.
That is a stronger statement than "the config file says 0.45".

## 5 · THE RESULT — against a baseline BIT-EXACT to the submitted signoff
```
metric              base (= paid chip)     ndf-1d        delta
max_slew                        3,317         857     -74.2%   ✅
max_cap                            27           5     -81.5%   ✅
max_fanout                        117         111      -5.1%   ✅
setup WS                    +5.66802    +7.88681    +2.219 ns  ✅ IMPROVED
hold WS                     +0.11053    +0.19383     +75.4%    ✅ IMPROVED
DRC · LVS · antenna             0/0/0       0/0/0                ✅
die area                      232,623     232,623   unchanged
stdcell area                  127,056     131,537     +3.5%    ⛔ THE COST
timing_repair_buffer            2,611       3,402     +30.3%   ⛔ THE MECHANISM
sequential (flops)              1,468       1,468   IDENTICAL  ✅ state conserved
```
**All seven §5(b) bars PASS ⇒ the arm CLOSES.** ⛔ **But one passed for a bad reason and it is
recorded rather than banked: `area <= base × 1.03` keyed on `design__instance__area`, which EQUALS
`design__core__area` on an absolute-die run and CANNOT MOVE.** Keyed on `__stdcell` it is 1.0353 and
**would have failed, marginally.** See the correction appended to `silicon-drv-A-results-0827.md`;
the same non-measurement is in this seat's bank and in the inherited headline.

## 6 · ⭐ THE FANOUT RESULT IS MECHANISTIC, AND IT WAS PREDICTED BEFORE IT WAS MEASURED
```
                  clock-leaf   datapath   total
ndf-base                 111          6     117
ndf-1d                   111          0     111
```
***①d CLOSED EXACTLY THE SIX DATAPATH VIOLATORS AND LEFT THE CLOCK TREE UNTOUCHED.*** Four of the
six were resizer-inserted `fanout*` buffers (verified: **0 occurrences in the synthesis netlist,
874 in the final** — control: `dfxtp` is 1,468 in both, so the zero is a measurement); two were
yosys datapath nets. **The resizer fixed what the resizer owns; CTS owns the remainder.**
⚠️ *This number was first parsed with an unterminated `awk` section that ran past the fanout table
into the next one and returned 112 with a bogus row. The tell was the count disagreeing with
`design__max_fanout_violation__count` (111). Re-parsed with a bounded section; both runs now agree
with their own metric. A section-scanner without a terminator is a silent over-count.*

## 7 · ⇒ WHAT ② BECOMES
**②'s pre-registered premise was refuted and is now RESTORED, at a different number and only after
①d.** On the 3×2 every violator was a clock leaf. On the paid chip's *baseline* that was FALSE —
6 of 117 were datapath, so CTS knobs alone could never have reached zero. **After ①d the residual is
111 of 111 clock-leaf, ZERO datapath**, so `CTS_SINK_CLUSTERING_SIZE` is once again the whole
remaining question — against **111 leaves at fanout 12–15**, not the 3×2's 37 at 11–12.
📌 ② should therefore run **on the NDF, after ①d**, not on the 3×2. Its arms (10, then 8) still fit:
552 flops over ≤10 sinks needed ≥56 leaves on the 3×2; **1,468 flops need ≥147 leaves here.**

## 8 · ⛔ WHAT IS NOT MINE
The resubmission click is the Captain's (public + money). This seat has produced a measured,
audited pair on the artifact that ships and reports it. **Nothing has been submitted.**
