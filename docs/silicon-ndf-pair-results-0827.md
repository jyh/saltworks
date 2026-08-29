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

---
# Part 3 · ② ON THE PAID CHIP — 117 → 1, AND NEITHER ARM REACHES ZERO
`ndf-2a` (`CTS_SINK_CLUSTERING_SIZE=10`) 12:50–12:58 · `ndf-2b` (`=8`) 12:59–13:07. Both hold ①d's
knobs; one axis each. Bar pre-registered at `silicon-cts-prereg-0827.md` §8 BEFORE either ran.

## 9 · THE FOUR-RUN TABLE — all on one image digest and TT's own PDK
```
metric          base (= paid chip)      ①d        ②a (=10)     ②b (=8)
max_fanout                    117       111            1            2
max_slew                    3,317       857          825          797
max_cap                        27         5            5            5
setup WS                 +5.66802  +7.88681     +7.85898     +7.79852
hold WS                  +0.11053  +0.19383     +0.19768     +0.19105
stdcell area              127,056   131,537      131,856      132,373
timing_repair_buffer        2,611     3,402        3,404        3,408
clock_buffer                  200       205          202          233
flops                       1,468     1,468        1,468        1,468
DRC · LVS · antenna         0/0/0     0/0/0        0/0/0        0/0/0
```

## 10 · ⛔ NEITHER ARM CLOSES — BY THE BAR PUBLISHED BEFORE THE RUNS
```
②a   max_fanout 1, bar is 0   ⛔        every other clause ✅
②b   max_fanout 2, bar is 0   ⛔  AND   hold 0.19105 < 0.19383 ⛔  (it REGRESSES hold vs ①d)
```
⇒ **②a IS STRICTLY BETTER THAN ②b** — fewer violators and hold *above* the ①d baseline rather than
below it. **A smaller clustering size is not monotonically better**, which is the kind of thing a
one-arm experiment would have got wrong.

## 11 · ⭐ THE ARMS ANSWER THE QUESTION THEY WERE RE-PURPOSED FOR: THE RESIDUAL IS PLACEMENT, NOT STRUCTURE
```
①d      0 datapath violators
②a      1  —  wire695/X @11        (a buf_8: 0 in synthesis, 1 in final ⇒ RESIZER-inserted)
②b      2  —  _05547_/X @12 · _11038_/X @11
```
***THE RESIDUAL SET IS DIFFERENT EVERY TIME, AND IN ALL THREE RUNS IT IS ZERO CLOCK-LEAF.*** Both
CTS arms **completely eliminate the 111 clock-leaf violators**; what remains is a small, *varying*
datapath remainder at fanout 11–12 that moves with placement. `_11038_` appears in `ndf-base` and
`ndf-2b` but not in `①d` or `②a` — it recurs, it does not persist.
## 11a · ⚖️ WAIVER — RULED BY COUNCIL 2026-08-28 (desk item 3, close 10:49; headline "1 wire695 ACCEPTED")

**ACCEPTED: ONE datapath net at fanout 11 against a limit of 10, in the recommended configuration
`①d + ②a`.** The ruling is an acceptance of a *residual*, not a relaxation of the constraint: the
clock tree closes COMPLETELY in both arms (111 clock-leaf violators → 0), and what is waived is the
small datapath remainder §11 measures.

⛔ **AND THE WAIVER MUST NOT BE READ AS BEING ABOUT `wire695` THE NAME.** §11 above measures the
residual set as **different in every run** — `①d` 0 · `②a` 1 (`wire695/X @11`) · `②b` 2
(`_05547_/X @12`, `_11038_/X @11`) — and `_11038_` *recurs without persisting*. The nets are
RESIZER-inserted and move with placement, so a re-run of the accepted configuration may legitimately
present a **different single violator at fanout 11–12**.
⇒ ***THE WAIVED OBJECT IS "AT MOST ONE DATAPATH VIOLATOR AT FANOUT 11–12, ZERO CLOCK-LEAF", NOT A
NAMED NET.*** *A name-shaped waiver would go stale on the next run and read as a NEW violation —
the identity error this fleet has already paid for: a name is not an identity, and it is least
stable exactly where synthesis invents the name.*
📌 **CHECK AT SUBMISSION: zero clock-leaf violators, and ≤1 datapath violator at fanout ≤12. If the
count rises or a clock-leaf appears, the waiver does NOT cover it and the row re-opens.**

⭐ **AND THAT CHECK IS NOW AN EXECUTABLE REFUSAL, NOT THIS SENTENCE — `docs/silicon-tools/drvgate.sh`
(2026-08-28 17:3x).** Until then the criterion above was prose, `harden_run.sh` PRINTED
`design__max_fanout_violation__count` inside a loop and consumed nothing, and the hand reading that
printout on 09-07 was mine, in a hurry. ⇒ ***A CORRECT CRITERION WHOSE EXIT STATUS NOTHING CONSUMES
IS A PRINTOUT.*** `harden_run.sh` now EXITS with the gate's status.
⛔ **AND THE METRIC CANNOT DECIDE IT — the gate reads the per-net STA tables, not the count.**
`design__max_fanout_violation__count` is a TOTAL, and the two populations need OPPOSITE verdicts:
measured on the archived runs, `①d` scores **111 and every one is a clock-tree leaf (REFUSE)** while
`②a` scores **1 and it is datapath (ACCEPT)**. A gate keyed on the total gives one number one verdict.
📌 **DRIVEN 13/13 (`drvgate_selftest.sh`): each limb — clock-leaf, count, fanout>12 — fires ALONE in
some arm; the PASS verdict is reachable; a blank, a missing summary line, and a parse that disagrees
with the report's own count all REFUSE rather than pass.** The four archived runs are production arms:
base ⛔ (111 clk + 6 dp, worst 14) · ①d ⛔ (111 clk, 0 dp) · **②a ✅** · ②b ⛔ (2 dp).
⚠️ **A TAPE-OUT MECHANIC THAT FALLS OUT OF THIS, and it decides WHEN the check can run: the submitted
bundle `tt_submission/` carries NO STA corner reports and its `metrics.csv` has NO fanout column at
all — the evidence does not travel with the artifact.** ⇒ **the gate must run on the LOCAL run
directory before the submission is cut; there is no re-checking it afterwards from what was shipped.**

⇒ **CTS KNOBS CANNOT REACH ZERO HERE, AND NOT BECAUSE THEY ARE SET WRONG: THE REMAINDER IS NOT A
CLOCK OBJECT.** Chasing it is a resizer/repair question, and **two clusterings producing two
different residual sets is evidence AGAINST convergence**, not merely absence of evidence for it.

## 12 · ⇒ WHAT GOES TO THE CAPTAIN, WITH THE COST OF THE ALTERNATIVE ATTACHED
**RECOMMENDED CONFIGURATION: ①d + ②a.** Against the chip that is currently on the shuttle:
```
max_fanout   117 -> 1     (-99.1%)      hold WS   +0.1105 -> +0.1977   (+79%, nearly DOUBLE)
max_slew   3,317 -> 825   (-75.1%)      setup WS  +5.6680 -> +7.8590   (+2.19 ns)
max_cap       27 -> 5     (-81.5%)      DRC · LVS · antenna   0/0/0 throughout
COST: stdcell 127,056 -> 131,856 = +3.8%; die and fit UNCHANGED (fill absorbs it); flops IDENTICAL
```
⛔ **THE ONE REMAINING VIOLATION IS A DATAPATH NET AT FANOUT 11 AGAINST A LIMIT OF 10.** Accepting
it is a **SPEC-ACCEPTANCE ACT AND IT IS THE CAPTAIN'S.** The cost of the alternative, measured:
**②b is the only other knob setting tried and it is WORSE on both counts** (2 violators, and hold
regresses below ①d); no CTS setting reaches zero because the residual is not in the clock tree.
📌 *Context for the judgement, offered and not decided: `max_fanout` is a PROXY constraint. Its
physical consequences — slew and cap — are measured separately and are down 75% and 81%. A fanout-11
net is a rule-report violation; whether that matters for this mask is his call, not a measurement.*
⛔ **THE RESUBMISSION CLICK REMAINS THE CAPTAIN'S. Nothing has been submitted from this seat.**
