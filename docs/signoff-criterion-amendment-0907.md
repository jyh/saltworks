# The signoff count clause, amended — and the three table numbers re-published

*Council 09/07 ruling **A2** (desk row **GR**). Executed by `evidence` as saltworks lead,
2026-09-07. The zero-clock-leaf clause and the 11–12 band are untouched; only the COUNT moved.*

## 1 · The amendment, in one line

> **2026-08-28 (council item 3), the waived object was:** *"at most **one** datapath violator at
> fanout 11–12, zero clock-leaf."*
>
> **2026-09-07 (council 09/07 A2), the count clause reads:** *"at most **three** datapath violators
> at fanout 11–12, zero clock-leaf."*

**Why the count and nothing else.** The `fetch_owed` repair in `src/busadapt8.v` adds one flip-flop;
the additional violators are a placement consequence of it, not a fanout its logic demands. The
repair's own net is fanout 1. The clause §11a of `docs/silicon-ndf-pair-results-0827.md` calls *the
serious one* — zero clock-leaf — was never at issue and is unchanged, and the band is unchanged:
a fourth violator, or any violator at 13, still refuses.

## 2 · The three table numbers, RE-MEASURED AT THE SHIPPED RUN

⛔ **These are not copied from the bundle that asserts them.** They are read from the `tt_submission`
artifact of the GDS run named by the shuttle slot itself:

```
shuttle slot   projects/tt_um_saltworks_ndf_c32/commit_id.json      HTTP 200 (bogus-dir control: 404)
   commit      01e19f7ef1d1c68255ea424265251c0a377e4b7e             == origin/main (git ls-remote)
   project_id  5500        workflow run 34058427540                 conclusion success
   run headSha 01e19f7ef1d1c68255ea424265251c0a377e4b7e             == the slot's commit
```

`stats/metrics.csv`, nine STA corners:

```
                                        08-19 submission   THE SHIPPED CHIP
  design__max_fanout_violation__count            117              3
     of which clock-tree leaves                  111              0
     of which datapath                             6              3    fanout 11, 12, 12
  design__max_slew_violation__count             3317           1051
  design__max_cap_violation__count                27             13
  timing__setup__ws (55 ns period)         +5.668 ns      +8.023 ns
  timing__hold__ws                         +0.111 ns      +0.190 ns
  timing__setup__tns                             0.0            0.0
  magic__drc_error__count · lvs · antenna      0/0/0          0/0/0
```

📌 **The top-line figure is the WORST CORNER, not a total** — measured, because a reader can easily
take `3` for a sum over nine corners. Per corner the fanout count is **3 in every one of the nine**;
slew ranges 34–1051 and cap 0–13, both peaking at `max_ss_100C_1v60`. The 08-19 column uses the same
convention, so the two columns are comparable.

## 3 · ⭐ THE THREE NETS — AND `wire695` IS NOT AMONG THEM

Read from the shipped run's own nine corner reports by `docs/silicon-tools/drvgate.sh`:

```
  clock-leaf violators : 0
  datapath violators   : 3   [('fanout937/X', 11), ('fanout939/X', 12), ('wire754/X', 12)]
  worst datapath fanout: 12
```

The 08-28 headline named **`wire695`**, and `wire695` is not a net of the chip that shipped. §11a
refused to let the waiver be about a NAME, on the measured ground that resizer-inserted nets move
with placement on every run. ⇒ ***THE SHIPPED RUN VINDICATES THAT CHOICE: A NAME-SHAPED WAIVER WOULD
HAVE GONE STALE AT TAPE-OUT ITSELF***, and would have read as a new violation rather than the same
accepted residual.

## 4 · ⛔⛔ THE FINDING THAT MADE THIS MORE THAN A PROSE EDIT

**The bundle's prose already recorded the amendment. The executable refusal still said ONE.**

`docs/info.md` §Signoff in the shipped bundle states the count clause as amended to three. But the
criterion's enforcer — `drvgate.sh`, built 2026-08-28 17:3x precisely *because* the criterion had
been a sentence — carried `if len(data) > 1`. Driven against the shipped run **before any edit was
made**:

```
⛔ DRV GATE: REFUSED — the council waiver does NOT cover this run.       rc=1
    3 datapath violators — the waiver covers AT MOST ONE
```

⇒ 🔑 ***A RULING LANDS IN THE PROSE AND THE ENFORCER KEEPS THE OLD NUMBER. THE PROSE CANNOT REFUSE
ANYTHING, AND IT IS THE ENFORCER THAT ANSWERS AT THE NEXT SUBMISSION.*** Amending the sentence alone
would have left the fleet with a gate that refuses its own tape-out — discovered not on a quiet day
but by whoever next ran `harden_run.sh`, which consumes this gate's exit status.

📌 This repo's own law, from the header of the gate that exhibited it: *a correct criterion whose
exit status nothing consumes is a printout.* The mirror image is this section: **a correct ruling
that no enforcer consumes is a sentence.**

## 5 · What was driven

```
BEFORE  drvgate.sh  vs the shipped run                      rc=1  REFUSED (3 dp vs "AT MOST ONE")
        drvgate_selftest.sh (old suite) vs AMENDED gate     8 passed, 1 failed
                └─ the single failure is `count ALONE (2 datapath)` — one arm, exactly the limb
                   that moved. An amendment that reddened nothing would have meant the arm was dead.
AFTER   drvgate.sh  vs the shipped run                      rc=0  MEETS (0 clock-leaf, 3 dp <=12)
        drvgate.sh  vs ndf-base  (refusing control)         rc=1  111 clock-leaf, 6 dp, worst 14
        drvgate_selftest.sh                                 16 passed, 0 failed
                └─ 12 fixture arms + all FOUR archived production runs, 9 STA corners each
```

Three arms were **added**, not just re-pointed: `count ALONE (4 datapath)` re-establishes the count
limb at its new boundary, `band ALONE (3 dp, one @13)` proves the band still refuses once the count
is satisfied, and `THE SHIPPED SHAPE: 3 dp @11,12,12` pins the suite to the part that was fabricated.
⛔ **Without those, moving the threshold would have RETIRED the count limb silently** — the suite
would have stayed green with nothing testing the count at all.

## 6 · ⚖️ Provenance, and one date that must not be smoothed over

The shipped `docs/info.md` says the count clause *"was amended on **2026-09-06**"*, and records
honestly that the Captain's `ship (B)` ruling *"covered the ship only; the count clause was not put
to him, and it took the helm's stated default-if-silent."* **Council 09/07 A2 has now ruled it.**

⇒ **The shipped sentence did not become false — its authority was upgraded**, from a default taken
in the lead's own recommendation to a council ruling. Both dates are real and they mean different
things: **09-06 is when the default was taken, 09-07 is when it was ruled.**

⛔ **The shipped copy is not edited and cannot be.** `01e19f7` is the submitted artefact, the same
standing `4226396` has. Per this campaign's own doctrine — *a record that asserts the PRESENT gets
corrected; a record that asserts WHAT WAS KNOWN AT A TIME gets annotated, never amended* (helm,
2026-08-28 17:20) — the fabrication record is annotated here and left alone there.

## 7 · Surfaces this amendment touched, and the one it deliberately did not

```
AMENDED   docs/silicon-tools/drvgate.sh              the enforcer: len(data) > 1  ->  > 3
AMENDED   docs/silicon-tools/drvgate_selftest.sh     2 arms invert, 3 added, 13/13 -> 16/16
AMENDED   docs/silicon-tools/README.md               the row that states the criterion
AMENDED   docs/signoff-fanout-note-FOR-BUNDLE.md     the live criterion carrier (§scope question)
ANNOTATED docs/silicon-ndf-pair-results-0827.md      §11a — a record of what was known on 08-27
NOT TOUCHED  the shipped bundle's docs/info.md       frozen: it is the submitted artefact
```

The census was taken by grepping the count clause across `origin/master` rather than by repairing
the file someone named: the two prose carriers and the three tool surfaces were found together, and
**the enforcer was found only because §11a says in its own text that the check is executable.**
