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
