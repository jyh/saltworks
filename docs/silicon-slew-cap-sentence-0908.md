# ARE `1051` SLEW AND `13` CAP BENIGN? — THE SENTENCE, AND WHAT IS BEHIND IT

silicon, 2026-09-08, on the council 09/08 ①b commission (FINISH-THEN-DARK).
**The owed item** (evidence, 09/06 bank §3 and the 09/06 residuals post): *"silicon owes one
sentence on whether `1051` slew / `13` cap are benign — now a real question, because the control
attributed them to (B)."*

## ⚖️ THE SENTENCE

> **Yes, benign for function — and the load-bearing reason is not the size of the margin but the
> location of the violations: ZERO of the 1051 slew and 13 cap violators sit on the clock network,
> in any of the nine corners, so every one of them delays DATA, which spends the setup margin the
> chip has 8.02 ns of and buys the hold margin it has only 0.190 ns of.**

⛔ **What that sentence does NOT say, stated because a benign verdict travels further than its
scope:** it is not a claim that the margin is sufficient — that is STA's answer, not this gate's —
and it is not a claim about DRC, LVS, antenna, or power.

## 📊 THE MEASUREMENT — `docs/silicon-tools/slewcapgate.sh`, shipped run `34058427540` (`01e19f7`)

```
  CORNER                     SLEW CLK-slew worst-slack      CAP  CLK-cap
  max_ff_n40C_1v95            116        0     -0.266        0        0
  max_ss_100C_1v60           1051        0     -1.376       13        0     <- the datasheet's column
  max_tt_025C_1v80            264        0     -0.604        0        0
  min_ff_n40C_1v95             34        0     -0.073        0        0
  min_ss_100C_1v60            769        0     -1.000        5        0
  min_tt_025C_1v80            162        0     -0.349        0        0
  nom_ff_n40C_1v95             69        0     -0.174        0        0
  nom_ss_100C_1v60            914        0     -1.202       10        0
  nom_tt_025C_1v80            210        0     -0.476        0        0
  ✅ ZERO clock-network slew and cap violators across all 9 corners.
```

The nine-corner slew range **34–1051** and cap range **0–13** reproduce the figures recorded in
`docs/signoff-criterion-amendment-0907.md:49` exactly, from the run's own reports.

**Timing this sits inside**, read from `ws.max.rpt`/`ws.min.rpt`, not quoted:

```
  period                      55.000 ns
  setup worst slack            8.023 ns   (max_ss_100C_1v60 — the SAME corner as the worst slew)
  hold  worst slack            0.190 ns   (min_ff_n40C_1v95)
  worst slew                   2.126 ns against a 0.750 ns limit = 2.83x
  worst cap                    0.136 pF against a 0.0943 pF limit = 1.44x
  slew violator population   728 logic cell · 255 fanout buffer · 55 antenna diode ·
                             8 input port buffer · 5 wire buffer   (worst corner, sums to 1051)
```

## 🔑 WHY LOCATION IS THE LOAD-BEARING FACT AND THE COUNT IS NOT

§11a of `docs/silicon-ndf-pair-results-0827.md` already calls **zero clock-leaf** the serious half
of the fanout waiver. The same split is right for slew and cap for a **structural** reason rather
than by analogy:

- a **datapath** slew violation makes data arrive LATER → spends **setup** (8.02 ns available)
  and **buys hold**;
- a **clock-network** slew violation moves the sampling EDGE → spends **hold**, which is the tight
  number here (0.190 ns) and which a slow 55 ns period does nothing to protect.

⇒ ***THE TWO POPULATIONS NEED OPPOSITE VERDICTS FROM THE SAME COUNT.*** `1051` on the clock tree
would have been a different answer at the same magnitude. This is why the sentence took a
classifier and not an opinion.

## ⛔⛔ THE FINDING THAT ALMOST WENT THE OTHER WAY — AN INHERITED CLASSIFIER

`drvgate.sh` classifies clock pins as `startswith("clkbuf_") or "clknet" in pin`. That is CORRECT
for the population it was driven on (ndf-1d's 111 violators, all `clkbuf_leaf_*/X`). **A slew
violator can also sit on a flop's own `CLK` input pin, which carries neither token.** Reusing that
classifier unchanged would have counted a clock violation as datapath and printed the benign
answer. `slewcapgate.sh` widens it to `/CLK` and `/GCLK` — and the injected-violator control below
lands on `_12329_/CLK`, a pin the narrower classifier does not match.
⇒ 🔑 ***A CLASSIFIER IS VALID FOR THE POPULATION IT WAS DRIVEN ON, AND A NEW CHECK IS A NEW
POPULATION.***

## ✅ THE CONTROLS — "ZERO VIOLATORS" AND "A CLASSIFIER THAT MATCHES NOTHING" PRINT THE SAME ZERO

```
  POSITIVE   is_clock() matches 1436 of 7778 distinct pins in this run's own reports
             => the zero in the violator list is a fact about the design, not the classifier.
             The gate REFUSES rc 2 if this control returns 0.
  REFUSAL 1  a /CLK slew violator injected, declared count bumped to match  => rc 1, "CLOCK-NETWORK
             DRV VIOLATORS PRESENT"
  REFUSAL 2  declared count left inconsistent with the parsed rows          => rc 2, no verdict
  OBJECT     drvgate.sh re-run on the same run dir reproduces the recorded fanout verdict exactly
             (3 datapath: fanout937/X@11, fanout939/X@12, wire754/X@12; zero clock-leaf)
             => this is the shipped run, checked rather than assumed from the directory name.
```

## ⚠️ THE TWO RESIDUALS I AM NOT DISMISSING

1. **The delay numbers on those paths are extrapolated.** `0.750 ns` is the sky130 library's
   characterised max transition; at `2.126 ns` STA is computing delay outside the characterised
   table. **The 8.02 ns of setup margin defending this verdict is itself partly computed from
   extrapolated cells.** The margin is ~4x the worst transition, so the conclusion is robust to a
   large extrapolation error — but the number is not exact and should not be quoted as if it were.
2. **I cannot explain the improvement's mechanism, and I am not inventing one.** The DRV counts
   went `3317 -> 1051` slew and `27 -> 13` cap between the 08-19 submission and the shipped chip,
   and a control re-hardening the unchanged design under today's environment reproduced the OLD
   numbers exactly — so the shift is attributable to (B), a +136 cell / +1 flop change. **(B)
   REDUCED these violations 3.2x.** That direction is the safe one and it is still a large swing
   for a small edit; the plausible cause is different resizer buffering and placement, and
   *plausible* is the honest word. It is recorded as unexplained rather than narrated.

📌 **Neither residual reopens the chip.** It is fabricated. This answers the paper-trail question
the lead left open, and both residuals are notes for the bring-up when the shuttle returns.
