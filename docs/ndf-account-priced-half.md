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

⛔⛔ **THIS PARAGRAPH READ: "THE `+8.1891 ns` RESTS ON AN UNREPAIRED CLOCK TREE …
computed on a clock whose worst leaf slew is 25% of the period. The margin should
not travel without this clause." ⇒ WITHDRAWN 8/10 17:4x — THE CLAUSE WAS FALSE.**
*The final STA reports **ZERO slew violations on clock pins**; the "25% of the
period" came from reading a fanout COUNT as nanoseconds (§3). **I hung a scary
caveat on a GOOD result and suppressed a real +8.19 ns margin for a day** — the
underclaim direction, which nobody complains about and nobody checks.*
📌 **What survives, on its true ground: the clock tree carries 67 max-FANOUT
violations (12-14 against a limit of 10). That is a real debt and it is not a
slew debt, and it does not qualify the setup margin.**

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

✅ **THE ORGAN'S AREA IS NOW EXACT, AND IT NEEDED NO RUN — it is the sum of its own
cells' liberty areas, which is precisely what `design__instance__area__stdcell`
counts:**
```
batcher_c        624 cells   4,023.8592 um2   EXACT
batcher_struct   504 cells   3,573.4272 um2   EXACT
```
⭐ **METHOD VALIDATED ON TWO ALREADY-MEASURED RUNS BEFORE BEING TRUSTED HERE** —
it reproduces the BB at 1x1 on both power grids to **±0.003 um2** and its cell
count exactly (529/529):
```
  BB 1x1 LibreLane PDN   computed 3,824.9184  vs flow 3,824.92   ✅
  BB 1x1 TT grid         computed 3,829.9232  vs flow 3,829.92   ✅
```
*Two corrections the controls forced, neither of which I would have found by
inspection: `fill` and `decap` must be EXCLUDED (2,443 decaps inflated the first
attempt by 233%), and `tapvpwrvgnd` must be INCLUDED at one site (1.2512 um2) —
the liberty gives it no area at all, so the sum silently ran 240.23 um2 light
while the cell COUNT already matched exactly.*

⛔⛔ **THE OLD PROJECTION RAN +47.3% HIGH AND IT IS RETIRED:**
```
WAS: 624 cells x 9.500 um2/cell (composed-run average) = ~5,928 um2   PROJECTION
IS:  the organ's own cells                             = 4,023.86 um2  EXACT
```
🔑 ***The average came from a MIXED population — flops and timing-repair buffers
included — and was applied to a HOMOGENEOUS one of small combinational cells
(inv/and2/xor2/or2/mux2), whose true average is 6.449 um2/cell. An average density
is a property of the population it was measured on.***

⚠️ **STILL A PROJECTION, and the part that is: `69,776.9 + 4,023.86 = 73,800.76
um2 = 31.7% of the 6x2 die` assumes composition ADDS ONLY THE ORGAN'S OWN CELLS.
It will not — glue, taps, and the flow's own repair buffers scale with it.** *The
organ's area is exact; the COMPOSED total is a floor, not a forecast.*
⛔ **DO NOT READ 32.5% AS A FIT RESULT.** *It is a linear area projection at one
run's average cell density. It says nothing about ROUTING, about the sort-then-route
seam's effect on the timing arc, or about the critical path — **which is already 93%
inside a single cell.** Whether the batcher fits and closes is a MEASUREMENT nobody
has run.*

## 3 · THE DRV DEBT — ⛔⛔ THIS SECTION WAS WRONG AND I REFUTED IT MYSELF (8/10 17:4x)

⛔⛔ **THE PREVIOUS TEXT CLAIMED TWO SLEW POPULATIONS: "EXTREME >10 ns, 67 pins,
ALL CLOCK-TREE, worst 14.00 ns = 18.7x limit = 25% OF THE 55 ns PERIOD" and a
mild datapath band. THE EXTREME POPULATION DOES NOT EXIST. I read a
DIMENSIONLESS FANOUT COUNT AS NANOSECONDS.** The report rows say so verbatim:
```
max fanout
Pin                                   Limit Fanout  Slack
clkbuf_leaf_57_clk/X                     10     14     -4 (VIOLATED)
```
*`14` is a FANOUT of 14 against a LIMIT of 10. I divided it by the 0.750 ns SLEW
limit to manufacture "18.7x", then expressed that as a fraction of the clock
period — **a physical quantity built out of a pin count.***

✅ **WHAT THE FINAL POST-PnR STA ACTUALLY REPORTS (`ndf6x2c`, stage 55,
`max_ss_100C_1v60` — the corner the headline metric comes from):**
```
  max slew        1,757 VIOLATED   worst 2.2254 ns vs 0.750 limit = 2.97x
                                   ZERO on clock pins · ZERO above 10 ns
                                   body 1.7-2.2 ns — ALL DATAPATH
  max fanout         67 VIOLATED   ALL clock-tree (clkbuf_leaf_*), 12-14 vs 10
  max capacitance    31 VIOLATED   ss corners only; zero at tt and ff
```
🔑 ***AND THAT CLOSES THE "UNRESOLVED 98" EXACTLY: 1,757 + 67 + 31 = 1,855. The
"1,855 rows" I could not reconcile was me SUMMING THREE DIFFERENT CHECKS and
calling the total "slew rows". The discrepancy was never in the tool.***

📌 **THE TRUE PICTURE, which is better news than the false one:** there IS still a
clean partition, but it is **BETWEEN CHECKS, not between two slew bands** — every
slew violation is datapath, every fanout violation is clock. **The worst slew is
2.97x its limit, not 18.7x; it is 4.0% of the period, not 25%.**

⛔ **AND THE DATAPATH HYPOTHESIS IS REFUTED TOO — BY THE POPULATION, BEFORE ANY
RUN.** It blamed R2's `_1` drive ruling. But that ruling governs only the EMITTED
organs (485 mapped cells), and the violations are overwhelmingly elsewhere:
```
origin of the 1,757                       count   share   worst slew
  synthesised logic (yosys _NNNN_)         1327   75.5%     2.2254 ns
  flow-inserted fanout-repair buffers       307   17.5%     2.2238 ns
  emitted organs (what R2 governs)          123    7.0%     1.0223 ns
```
🔑 ***THE RULED CELLS ARE 7% OF THE DEBT AND THE HEALTHIEST POPULATION IN IT.***
*Upgrading an organ to `_2` could move at most 7%, and it would move the pins
that are already closest to compliant. **The drive ruling is not the cause, and
the experiment I had queued would have measured that at the price of a 6x2 run.***

⭐ **AND THE BAR ITSELF IS NOT THE PDK'S — THIS IS THE NUMBER THAT ANSWERS "WOULD
IT FABRICATE":**
```
MAX_TRANSITION_CONSTRAINT = 0.75 ns   <- LibreLane's own bar, set by the flow
sky130_fd_sc_hd default_max_transition = 1.50 ns   <- the PDK's actual limit

  violations vs the FLOW's 0.750 bar : 1,757
  violations vs the PDK's 1.500 limit:   336   (19.1%)
      296 synthesised · 40 repair buffers · ZERO in the emitted organs
  worst 2.2254 ns = 1.48x the PDK limit
```
📌 **BOTH NUMBERS ARE HONEST AND THEY ANSWER DIFFERENT QUESTIONS. 1,757 is the
count against a deliberately conservative margin (half the PDK limit) and is the
right number for judging design quality. 336 is the count against the limit the
library actually states.** *The organs are clean against the PDK limit outright.*
⚠️ **40 of the buffers the flow INSERTED to repair fanout are themselves over the
PDK's slew limit** — which was the clue that sent me to the stage trace.

## 3b · WHERE THE SLEW DEBT IS BORN — THE STAGE TRACE SETTLES IT, NO RUN NEEDED

**Same run, same corner (`nom_tt_025C_1v80`), every STA stage in order:**
```
12-openroad-staprepnr      1627   pre-PnR, on wire-load estimates
31-openroad-stamidpnr      3223   after placement, before repair
36-openroad-stamidpnr-1       0   <- DESIGN REPAIR FIXES ALL OF THEM
38-openroad-stamidpnr-2       0
43-openroad-stamidpnr-3       0   after antenna repair, BEFORE detailed routing
55-openroad-stapostpnr      564   after DETAILED ROUTING + RC EXTRACTION
```
🔑 ***THE REPAIR WORKS PERFECTLY. 3,223 → 0. THE ENTIRE DEBT IS CREATED BY
POST-ROUTE PARASITICS, AND REPAIR NEVER SEES THEM BECAUSE IT RUNS BEFORE
ROUTING.*** **`GRT_DESIGN_REPAIR_RUN_GRT` is True and it did its job — the same
netlist had ZERO slew violations three stages before the number we have been
quoting all day.**

⛔ **THIS RETIRES THE DRIVE-STRENGTH AND SYNTHESIS-QUALITY STORIES OUTRIGHT, not
by argument but by timing: a netlist cannot have a drive-strength defect at stage
55 and not at stage 43. It is the same netlist.** *What changed between them is
wire RC on a **1030 µm-wide die at 30% utilisation**.*
⭐ **AND THE CROSS-CHECK WAS ALREADY IN THIS DOCUMENT: the BB at 1x1 — a 161 µm
die — carries ELEVEN slew violations and zero against the PDK limit. Same flow,
same PDK, same knobs, 1/6th the width.** *Wire length is the variable.*

📌 **THE LEVER, NAMED PRECISELY AND NOT PULLED:** `GRT_DESIGN_REPAIR_MAX_WIRE_LENGTH`
and `DESIGN_REPAIR_MAX_WIRE_LENGTH` are both **0 (disabled)**, so nothing buffers a
long net in anticipation of the RC that routing will add. *Setting them requires
choosing a length, and choosing it is a design decision with an area cost — **not
a knob I should pick unilaterally and quietly**. The alternatives are denser
placement (shorter nets) or accepting the debt against a bar that is already half
the PDK's.* ⚠️ **UNTESTED. I am naming the lever and its exact config keys; I have
not run it, and 336-against-the-PDK-limit is what it would be trying to move.**
- ⛔ **THE "CLOCK" HYPOTHESIS IS WITHDRAWN.** It proposed re-running with CTS
  max-slew/max-cap to collapse "the 67". *The 67 are a **max-fanout** check —
  neither knob addresses them — and `Flow/harden.sh` already banks a controlled
  pair showing `MAX_FANOUT_CONSTRAINT` changing NOTHING (bit-identical slew, area
  and slack). **I would have spent a 6x2 run testing the wrong knob against a
  population that was never in the final netlist.***

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
✅ **AND THE TILE-FIT IS NOW DONE HERE TOO — RE-RUN ON TT'S OWN POWER GRID
(run `bb1x1_tilefit`, `FP_DEF_TEMPLATE = tt_block_1x1_pg.def`; invocation banked
at `Flow/tilefit.sh`):**
```
                   LibreLane PDN     TT PDN (REAL)
  die / core        17,954.70          17,954.70   / 13,460.40  IDENTICAL
  stdcell            3,824.92           3,829.92   (+5.00 um2, +0.13%)
  flops / cells         52 / 529           52 / 529             IDENTICAL
  SETUP __ws slow      +20.1426           +20.0047 ns — MET (40 ns clock)
  HOLD  __ws            +0.1065            +0.1089 ns
  max-slew / max-cap      11 / 0             11 / 0
  magic DRC / klayout / LVS / antenna   0 / 0 / 0 / 0   BOTH RUNS
```
🔑 ***THE BB FITS A 1x1 ON TINYTAPEOUT'S REAL GRID.*** *The real grid costs
5 um² and 138 ps here — the 6x2 paid a larger slew price (+138 violations); this
design is small enough that the straps cost it almost nothing.*
⚖️ **CONTROL ON MY OWN HARNESS, because the baseline predates it: the LibreLane-PDN
run was RE-RUN through the same script and reproduced the published figures on
**308 of 308 comparable metrics, zero differing**. So the TT-grid column is a
difference in the GRID and not in the way I invoked the tool.**

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
1. ⛔ **AMENDED — this read "NOT A TILE-FIT SIGNOFF — no TT power-grid DEF; this
   is LibreLane's PDN." The DEF half is now FALSE: the run above used
   `tt_block_1x1_pg.def` and passed.** *The SIGNOFF half stands and is restated
   on its true ground: a signoff is TinyTapeout's CI verdict on the fabrication
   path, not a local run at my knobs.*
2. ✅ **`test.py:247` — REPAIRED 8/10 (silicon), and it was TWO defects, not the
   one diagnosed.** The bench was stale against the 8/8 `cnt[3]` ruling in both
   directions at once: it asserted `(uio >> 5) == 0` while `project.v:60` drives
   `cnt_o[3]` there (**measured first failure `t=8`**, as diagnosed 8/9 20:13) —
   *and* it read only THREE counter bits, so `cnt == t % 8` aliased cycles 8..13
   onto 0..5 and **PASSED all 14 cycles**. ⛔ **The silent half is the worse one:
   that aliasing is precisely the defect `cnt_o[3]` was added to eliminate, so
   the bench could not tell cycle 8 from cycle 0 — the belief every other test in
   the file rests on. A repair chasing only the red assert would have left it
   certifying the pre-ruling design.** *The RTL was correct throughout; the
   criterion was weaker than the artifact.* **Verified by re-running both forms
   against the RTL under iverilog — `Sim/tt_bench_check/run.sh`, 5/5 expectations
   — because cocotb does not import on this host and the bench itself CANNOT be
   run here.**
3. **11 max-slew violations** on this run — small, real, unrepaired — **and now
   scoped against both bars as §3 requires: worst 0.7827 ns, which is over
   LibreLane's self-imposed 0.750 and CLEANLY UNDER the PDK's stated 1.500.
   ZERO of the 11 exceed the library's actual limit.**

## 5 · WHAT THIS HALF DOES NOT CLAIM

- ⛔ **THIS BULLET'S REASON WAS FALSE AND MATH CAUGHT IT (13:53).** It read
  "not a tile-fit signoff (§1 and §4 — NEITHER RUN USED TT'S POWER-GRID DEF)".
  **§1's run DID use it** (`tilefit6x2`, `tt_block_6x2_pg.def`). The conclusion
  survives; the REASON given for it did not. Restated on its true ground:
- **§1 IS A TILE-FIT AND IS NOT A SIGNOFF** — it used TT's real power grid on the
  real 6x2 die and passed, but a SIGNOFF is TinyTapeout's CI verdict on the
  fabrication path, not a local LibreLane run at my knobs. ✅ ***§4 (BB at 1x1) is
  NOW a tile-fit as well*** *— re-run on `tt_block_1x1_pg.def` and passed. This
  clause previously read "has NOT been re-run with it — that one is still not a
  tile-fit at all"; it was true when written and is retired by the run.* **Both
  §1 and §4 are now tile-fits; NEITHER is a signoff.**
- **Not a batcher fit result** (§2, a linear area projection). ⛔ **This bullet
  also read "not a DRV diagnosis (§3 — two hypotheses, zero tests run)" — RETIRED
  8/10: §3 IS now a diagnosis. Both hypotheses were REFUTED by measuring the
  violating population, and neither refutation needed a run.** *What §3 still does
  NOT claim is the remaining lever: the synthesis/resizer configuration behind the
  1,327 synthesised and 307 flow-inserted violations is NAMED and UNTESTED.*
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
