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

## ⚖️ RULED 2026-08-28 19:0x — THIS NOTE IS HELD, WRITTEN AND UNSHIPPED

**Captain's rule, verbatim: *"the paper documents everything AT THE TIME; the tape-out can change
and be updated, but IT MUST BE SELF-CONSISTENT."*** ⇒ the standard is **SELF-CONSISTENCY, not
"always include the evidence": the artifact and its evidence must describe THE SAME THING AT THE
SAME TIME.**

1. **The CURRENT bundle documents `ndf-base`, so the `wire695` note does NOT go into it.**
2. **This note ships WITH the `ndf-2a` RESUBMISSION, AS ONE ACT, at the Sep 4–5 click** — config and
   evidence together, never bolted onto a bundle describing another chip.
3. **Until then: HELD. Written, committed, unshipped.** Trigger registered in `docs/QUEUE.md` (Q4)
   so it is surfaced by an instrument every sweep rather than remembered.

*The helm recorded the half that was theirs: the order assumed the accepted configuration WAS the
submitted one. They differ in 4 of 411 keys, and that had not been measured.*

## ⛔ THE SCOPE QUESTION — MEASURED, AND IT IS WHY THE ABOVE READS AS IT DOES

The council's 2026-08-28 waiver (item 3) accepts *"at most one datapath violator at fanout 11–12,
zero clock-leaf"* and its headline named **`wire695`**. That residual belongs to configuration
**①d + ②a**, whose `resolved.json` differs from the submitted run's in **4 keys**
(`CTS_SINK_CLUSTERING_SIZE`, two resizer hold margins, `RSZ_CORNERS`).

⇒ ***`wire695` DOES NOT APPEAR IN ANY OF THE FABRICATED CONFIGURATION'S NINE CORNER REPORTS. It is
not a net of the chip.*** A note in this bundle naming it as an accepted violator would tell a 2027
reviewer that the fabricated design has one datapath violator at 11 and zero clock-leaf. It has six
and 111.

**The waiver is a criterion for a configuration we recommend for a FUTURE revision. This bundle
documents the design that was FABRICATED. Both are true; only one belongs here — RULED 19:0x: it
belongs with the RESUBMISSION, shipped in the same act as the config it describes.**

📎 **THE DOCTRINE THIS APPLIES, so a later reader sees it is not a one-off judgement:** *a record
that asserts the PRESENT gets corrected; a record that asserts WHAT WAS KNOWN AT A TIME gets
annotated, never amended* (helm, ruled 2026-08-28 17:20). A fabrication bundle is history; a waiver
is a live criterion. ⇒ ***AND THE FAILURE MODE OF COMPLYING CARELESSLY: EVIDENCE THAT TRAVELS WITH
THE WRONG ARTIFACT IS WORSE THAN EVIDENCE THAT DOES NOT TRAVEL, BECAUSE IT ARRIVES WEARING THE
ARTIFACT'S AUTHORITY*** — a true sentence acquires the authority of the document it is placed in,
and no 2027 reviewer re-derives which configuration it described.
