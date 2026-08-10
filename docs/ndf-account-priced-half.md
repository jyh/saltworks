# NDF ACCOUNT — THE PRICED HALF (silicon)

**Order ② of the 10:32 submission push. Compiler owns the KERNEL half
(`docs/ndf-account.md`); this is the artifact-side ledger it pairs with.**

⚠️ **EVERY FIGURE HERE CARRIES ITS SCOPE CLAUSE, AND THE CLAUSES ARE NOT
DECORATION.** This document is written to be read by TT's public page and by the
Captain before a click that spends money. Evidence's fence governs it: **no
sentence stronger than the artifacts.** Where a number is a PROJECTION it says so
on the same line; where it is MEASURED it names the run.

---

## 1 · THE COMPOSED NDF AT 6x2 — MEASURED (run `465c669`)

```
die                    232,623 um2   = 1030.40 x 225.76, the 6x2 tile
stdcell                 69,776.9 um2 = 30.0% OF THE DIE
  sequential            19,185.9      combinational 31,159.9
  timing-repair         13,269.0      (fill 138,173 is DIE PADDING, not design)
instances               48,028 (39,218 of them fill) · 902 flops · 3,280 comb cells
SETUP __ws              +8.1891 ns at the SLOW corner — MET
HOLD  __ws              +0.1073 ns · setup violations 0 · hold violations 0
DRC 0 (magic AND klayout) · LVS 0 · antenna 0 · inferred latches 0
```

✅ **AND THE TILE-FIT IS DONE — RE-RUN ON TT'S OWN POWER GRID (run `tilefit6x2`,
`FP_DEF_TEMPLATE = tt_block_6x2_pg.def` from TinyTapeout's public tt-support-tools):**
```
                   LibreLane PDN     TT PDN (REAL)
  stdcell             69,776.90         69,673.10   = 30.0% of die
  SETUP __ws slow         +8.19             +8.13 ns  — MET
  magic DRC / klayout / LVS / antenna    0 / 0 / 0 / 0   BOTH RUNS
  max-slew                1,757             1,895   (+138: the real grid is STRICTER)
```
⛔⛔ **THIS PARAGRAPH PREVIOUSLY READ "THIS IS NOT A TILE-FIT SIGNOFF … the run
remains OWED AND BLOCKED on that DEF". THAT WAS FALSE AND IT WAS MINE.** *I never
tested whether the DEF was obtainable — it ships publicly and one `git clone` got
it. **I struck the false blocker on the bus at 10:50 and left it standing HERE, in
the Captain-facing document, for an hour.** One end is never enough, and the end I
left is the one that gets read.*
📌 **WHAT IS STILL TRUE AND STILL BINDS: the DRV debt GREW under the real grid
(1,757 → 1,895 slew), so the earlier figure was an UNDERESTIMATE, not a defect. And
this is a LOCAL LibreLane run at my committed knobs — TT's own CI is the
fabrication path and its result is theirs, not mine.**

⛔ **THE `+8.1891 ns` RESTS ON AN UNREPAIRED CLOCK TREE — see §3.** It is the
tool's honest output and it is computed on a clock whose worst leaf slew is 25%
of the period. **The margin should not travel without this clause.**

📌 **MEASUREMENT #1 — ENDPOINTS REFUTED, MIDDLE CONFIRMED.** The critical path is
`uio_in[2] (edge_in_data) → ser0.q30`. The named candidate chain
(SER→fabric→AND→XOR→ripple→acc) is **93% of that path** (cell0 199 hops of 213);
what the measurement refuted was the predicted ENDPOINTS. It is an **I/O path**,
so the number moves with the input-delay model in a way an internal
register-to-register path would not.

## 2 · THE BATCHER — UNWIRED, NOT MISSING, AND ITS COST IS A PROJECTION

```
batcher_c.v       1,569 lines · 624 sky130 cells   COMPLETE, ON THE TREE
batcher_struct.v  1,209 lines · 504 sky130 cells   COMPLETE, ON THE TREE
instantiated in tt_um_saltworks_ndf.v              ZERO
```
🔑 **The organ exists and is emitted; what does not exist is a wrapper connection
to it. That is a COMPOSITION decision (R1's v1.1 seam), not an organ to build.**

⚠️ **PROJECTED, NOT MEASURED — labelled as the order requires:**
```
composed run cell density   31,159.9 um2 / 3,280 comb cells = 9.500 um2/cell
624 cells x that density                        ~5,928 um2   PROJECTION
projected stdcell with batcher      ~75,705 um2 = 32.5% of die   PROJECTION
```
⛔ **DO NOT READ 32.5% AS A FIT RESULT.** *It is a linear area projection at one
run's average cell density. It says nothing about ROUTING, about the sort-then-route
seam's effect on the timing arc, or about the critical path — **which is already 93%
inside a single cell.** Whether the batcher fits and closes is a MEASUREMENT nobody
has run.*

## 3 · THE DRV DEBT — TWO POPULATIONS, ZERO OVERLAP

```
slow corner, slew limit 0.750 ns:
  EXTREME  >10 ns     67 pins   ALL 67 ARE CLOCK-TREE (clkbuf_leaf_*_clk)
                                0 datapath.  Worst 14.00 ns = 18.7x limit
                                            = 25% OF THE 55 ns PERIOD
  MILD    <=10 ns  1,788 pins   ALL datapath, 0 clock.  Body 1.7-2.2 ns
  max-cap             31 pins   ss corners ONLY; zero at tt and ff
```
🔑 **The partition by instance type is PERFECT — not one clock cell in the mild
band, not one datapath pin in the extreme band. "1,757 violations" is two faults
with two causes and two repairs, and the severe one is the clock, not the logic.**

⚠️ **HYPOTHESES, NEITHER TESTED, each with the experiment that would settle it:**
- **CLOCK** — the run set `RUN_CTS 1` with no CTS constraints on a 1030 um-wide
  die at 30% utilisation. *TEST: re-run with CTS max-slew/max-cap set. If the 67
  collapse, it was configuration and not the design.*
- **DATAPATH** — R2 rules `_1` drive for combinational cells; minimum drive at the
  slow corner is exactly a 2-3x mild overshoot. *TEST: one organ at `_2`
  combinational. **If that is the cause, the debt is the drive ruling's PRICE and
  belongs in front of the Captain as a trade — not fixed silently.***

📌 **UNRESOLVED, stated rather than smoothed: the metric reports 1,757 slew
violations; the report lists 1,855 rows (67 + 1,788). I used the report's rows and
do not know what the 98 difference counts.**

## 4 · BB AT 1x1 — **MEASURED BY RUN**, AND ITS PRICE

*(This section replaced a 1x2 PROJECTION after the Captain's 10:35 refinement to a
1x1 and the maestro's instruction to confirm by RUN. The projection is kept below
only to score it.)*

```
MEASURED — LibreLane 3.0.5, pinned PDK, DIE_AREA 161.00 x 111.52 (dossier:182):
  die              17,954.70 um2   = the 1x1 tile, exactly
  stdcell           3,824.92 um2   sequential 1,106.06 · comb 1,537.72 · repair 565.54
  flops                    52
  SETUP __ws          +20.1426 ns at the SLOW corner, 40 ns clock — MET, large margin
  HOLD  __ws           +0.1065 ns · setup violations 0
  DRC 0 (magic AND klayout) · LVS 0 · antenna 0 · max-slew 11
```
⭐ **UTILISATION — AND THE DENOMINATOR IS PART OF THE NUMBER:**
```
stdcell 3,824.92  vs DIE  17,954.70  = 21.3%
                  vs CORE 13,460.40  = 28.4%   ← design__core__area, the usable area
```
🔑 ***One measurement, two percentages, only the divisor differing. A utilisation
figure without its denominator is not a number. The maestro's independent estimate
of 26-28% against ~14.5k usable lands dead centre of the core-relative figure.***
📌 **MY EARLIER PROJECTION SCORED: 4,031.56 um2 projected (2,143.31 x 1.881) vs
3,824.92 MEASURED — the projection ran +5.4% HIGH, i.e. conservative. It is now
RETIRED in favour of the measurement.**

✅ **THE BB FITS A 1x1 WITH ROOM. Size-up remains allowed, so the batcher-wired
variant not fitting a 1x1 costs nothing today — the growth path stays open.**

⚠️ **THE NAMED PRICE OF THE RESIZE, so it is bought with open eyes:**
1. **NOT A TILE-FIT SIGNOFF** — no TT power-grid DEF; this is LibreLane's PDN.
2. **`test.py:247`** — the cocotb bench is STALE against the 8/8 `cnt[3]` ruling:
   it asserts `(uio >> 5) == 0` while `project.v:60` drives `cnt_o[3]` there.
   `FRAME=14`, so the FIRST FAILURE IS `t=8`. **The RTL is correct; one bench line
   is not.** Diagnosed 8/9 20:13; **the fix is still UNOWNED.**
3. **11 max-slew violations** on this run — small, real, unrepaired.

## 5 · WHAT THIS HALF DOES NOT CLAIM

- ⛔ **THIS BULLET'S REASON WAS FALSE AND MATH CAUGHT IT (13:53).** It read
  "not a tile-fit signoff (§1 and §4 — NEITHER RUN USED TT'S POWER-GRID DEF)".
  **§1's run DID use it** (`tilefit6x2`, `tt_block_6x2_pg.def`). The conclusion
  survives; the REASON given for it did not. Restated on its true ground:
- **§1 IS A TILE-FIT AND IS NOT A SIGNOFF** — it used TT's real power grid on the
  real 6x2 die and passed, but a SIGNOFF is TinyTapeout's CI verdict on the
  fabrication path, not a local LibreLane run at my knobs. *§4 (BB at 1x1) has
  `tt_block_1x1_pg.def` in hand but has NOT been re-run with it — that one is
  still not a tile-fit at all.*
- **Not a batcher fit result** (§2, a linear area projection) · **not a DRV
  diagnosis** (§3 — two hypotheses, zero tests run).
- ⚠️ **§4 IS a measured BB post-layout number** (1x1, run complete). This bullet
  previously said it was NOT — written when §4 held a 1x2 projection, and left
  standing for one commit after §4 became a measurement. **A disclaimer falsified
  by the section it points at is worse than no disclaimer**, because it invites a
  reader to discount a number that is real. Caught on re-reading my own file.
- The clock-tree finding **post-dates** the layout it describes; nothing here has
  been re-run since.
- ***Every number that is a projection says so on its own line. If a sentence in
  the public README is stronger than the line it came from, the line is right and
  the sentence is wrong.***
