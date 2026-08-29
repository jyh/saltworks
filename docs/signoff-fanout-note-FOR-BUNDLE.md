# Max-fanout DRV at signoff — `tt_um_saltworks_ndf_c32`

*Prepared 2026-08-28 for addition to the submitted bundle (TT commit `7d2b2756`, run
`32284710003`). **NOT YET ADDED — see the scope question at the foot.***

## What the fabricated design actually reports

The submitted artifact carries **no STA corner reports and no fanout column in `metrics.csv`**, so
these rows come from the local run whose `resolved.json` differs from the submitted run's in
**0 of 411 keys** — a reproduction of the fabricated configuration, not an exploration of it.

Nine STA corners, identical in each; limit 10:

```
  clock-tree leaves   111 violators   clkbuf_leaf_<n>_clk/X, fanout 14-15
  datapath              6 violators
      _09736_/X    14   (-4)
      fanout672/X  12   (-2)
      _11038_/X    11
      fanout556/X  11
      fanout663/X  11
      fanout674/X  11
  worst setup slack  +5.668 ns on a 55 ns period      hold  +0.111 ns
```

**`design__max_fanout_violation__count` is a TOTAL and cannot express the distinction below.** It
reports 117 here; a reader holding only that number cannot tell a clock-tree object from a datapath
one, and the two carry different consequences.

## Why a datapath net over the limit is not a clock leaf over the limit

**MEASURED:** every violator's slack is absorbed — setup closes at **+5.668 ns of margin on a 55 ns
period**, hold at +0.111 ns, across all nine corners. A datapath net at fanout 11–14 costs transition
time on one combinational path that has that margin to spend.
**REASONING, marked as such:** a clock-tree leaf's fanout is not a local cost — it lands on skew and
insertion delay for every flop beneath it, so the same number means a distributed timing-integrity
risk rather than one slow path. That asymmetry, not the count, is why the two are judged separately.
**AND IT IS FIXABLE, WHICH THE COUNT ALSO HIDES:** CTS clustering arms run on this design eliminate
**all 111** clock-leaf violators, while the datapath remainder is resizer-inserted and moves with
placement — a different set on every run.

## ⛔ THE SCOPE QUESTION THIS NOTE WILL NOT DECIDE

The council's 2026-08-28 waiver (item 3) accepts *"at most one datapath violator at fanout 11–12,
zero clock-leaf"* and its headline named **`wire695`**. That residual belongs to configuration
**①d + ②a**, whose `resolved.json` differs from the submitted run's in **4 keys**
(`CTS_SINK_CLUSTERING_SIZE`, two resizer hold margins, `RSZ_CORNERS`).

⇒ ***`wire695` DOES NOT APPEAR IN ANY OF THE FABRICATED CONFIGURATION'S NINE CORNER REPORTS. It is
not a net of the chip.*** A note in this bundle naming it as an accepted violator would tell a 2027
reviewer that the fabricated design has one datapath violator at 11 and zero clock-leaf. It has six
and 111.

**The waiver is a criterion for a configuration we recommend for a FUTURE revision. This bundle
documents the design that was FABRICATED. Both are true; only one belongs here, and which one is
the Captain's to say.**
