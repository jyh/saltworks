# ①d BINDING AUDIT — the netlist-binding audits, re-run against the repaired netlist
silicon, 2026-08-27. Discharges the Captain's condition on ruling 11:0x: *the proof gates the
mask, so a resizer that moved buffers must not have moved what the Lean bindings bind to.*

**VERDICT: NOTHING THE LEAN BINDINGS BIND TO WAS MOVED — AND THE REASON IS STRONGER THAN A PASS.
No Lean binding lies inside the repaired design at all.** Four measurements below, each with a
control that could have returned the other answer. One residual is NAMED, not closed.

## 0 · WHAT WAS AUDITED, NAMED BEFORE THE RESULT
Repaired artifact: `slicea16bma`, standalone 3×2 harden, config ①d
(`RSZ_CORNERS = [nom_tt, max_ss, nom_ss, min_ss]`, `PL_RESIZER_HOLD_SLACK_MARGIN 0.45`,
`GRT_RESIZER_HOLD_SLACK_MARGIN 0.30`), run dir `/tmp/silicon-meas/work/runs/1d`.
Bindings audited: **all nine** `SaltWorks/Silicon/Imported/*.lean` and the netlists they cite.

## 1 · REACHABILITY — NO BOUND MODULE IS INSIDE THE REPAIRED DESIGN
Hierarchy walk over **61 parsed RTL modules** (`SaltWorks/Silicon/RTL/*.v`), instantiation graph,
transitive closure from each top:

```
slicea16bma              reaches  0 modules   LEAF        bound modules inside: NONE
tt_um_saltworks_ndf      reaches  5 modules               bound modules inside: bitserial_switch banyan_fabric
tt_um_saltworks_ndf_c32  reaches  7 modules               bound modules inside: bitserial_switch banyan_fabric
plane32bus               reaches  2 modules               bound modules inside: NONE
```

`slicea16bma.v` is 109 lines of behavioural RTL and instantiates nothing.
⭐ **CONTROL — THE WALKER CAN RETURN A HIT:** it finds two bound modules inside both NDF tops.
A blank from this query is therefore a measurement, not a broken query.

## 2 · THE BOUND ARTIFACTS ARE UNMODIFIED
Every `Imported/*.lean` and every netlist it cites, at this hand:

```
Comparator.lean       <- comparator_nl.v         sha aa478834ea0551f1
CompareExchange.lean  <- ce_elem_nl.v            sha a80a2fcf32504958
CompareExchangeC.lean <- ce_c_nl.v               sha 18a3d26e51d3f8ae
Dmem8.lean            <- dmem8_nl.v              sha 14899c2cb4b2b1a3
DmemAddr8.lean        <- dmem_addr8_nl.v         sha 4cf57ceae274590e
Switch.lean           <- bitserial_switch_nl.v   sha 44d14996baad266d
Fabric.lean · FabricCut.lean <- tt_um_saltworks_banyan.v   (not under Flow/)
RefComparator.lean    <- (no source line)
```
`git status --porcelain SaltWorks/Silicon/Flow SaltWorks/Silicon/Imported` → **empty**.
⭐ **CONTROL:** the same command without the pathspec reports four untracked files, so it can speak.
📌 The `_nl.v` files are `synth.sh` (yosys) outputs committed in git. **A LibreLane run neither
produces nor consumes them** — it synthesises `rtl/slicea16bma.v` itself into its own run tree.

## 3 · THE REPAIR IS STRICTLY POST-SYNTHESIS — MEASURED, NOT REASONED
sha256 of `06-yosys-synthesis/slicea16bma.nl.v`, all five runs:

```
baseline-repro · rsz-sscorners · all9 · 1c · 1d
  e3d7983df8faca80c62986043a22259e8dc83a76c8cef1d41a4a04faec830c28   ← ONE value, all five
```
⭐ **CONTROL — THE SAME INSTRUMENT RETURNS "DIFFERENT" WHERE IT SHOULD:** the five *final*
netlists carry five distinct hashes (`f0d7ff7c…` `76499319…` `e1c230d5…` `7ca20797…` `2a082919…`).
⇒ The resizer knobs move the post-synthesis netlist and leave synthesis untouched.

**INPUT PROVENANCE** (so the identity is of a known object, not of a coincidence): the RTL fed to
all five runs is byte-identical to the committed, unmodified `SaltWorks/Silicon/RTL/slicea16bma.v`
(`c9644c605300b3ba…`), landed `afe94c0c`, 2026-08-08. All five `resolved.json` record the same
`VERILOG_FILES`.

## 4 · THE REPAIRED NETLIST'S OWN STRUCTURE — STATE IS CONSERVED
`docs/silicon-tools/netlist_check.sh`, both halves, on every final netlist:

```
run              cells    flops   D driven exactly once   Q distinct   dfxtp_1
baseline-repro   21247     552          552/552  ✅          ✅            0
rsz-sscorners    22125     552          552/552  ✅          ✅            0
all9             21228     552          552/552  ✅          ✅            0
1c               21208     552          552/552  ✅          ✅            0
1d               21117     552          552/552  ✅          ✅            0
synthesis (×5)    2663     552          552/552  ✅          ✅            0
```
⭐ **CONTROL — the tool's 3-arm selftest was run ON THIS VERY NETLIST and passes:** orphan cell
caught by COUNT and missed by PROPERTY (21247→21248); double-driven D caught by PROPERTY and
not by COUNT (552→551); multi-line instances visible to the parser. Both halves discriminate here.
⭐ **AND THE COUNT HALF IS DEMONSTRABLY LIVE:** cell counts differ across all five runs while
flop count does not. **552 flops in every run and at synthesis** — the resizer added and deleted
buffers and never touched state ([[unobservable-state-is-deleted]] is the card this arm exists for).
📌 Incidental, and it corroborates the bank: **zero `dfxtp_1` survive to the final netlist in any
run, baseline included** — the datapath min-drive flops named off the *synthesis* netlist were
already repaired by the resizer before any of this work. Pre- and post-repair are different
populations under one noun.

## 5 · ⛔ THE RESIDUAL, NAMED RATHER THAN CLOSED
**Nothing in this flow checks that the final netlist computes what the synthesis netlist computes.**
Measured: of the run's 72 stages, **zero** match `equiv|lec|cec|formal` (control: 28 match
`openroad`, so the grep can hit). `netgen-lvs` compares GDS-extracted spice against the final
netlist — it is downstream of the resizer and cannot see a resizer-introduced function change.
`netlist_check`'s property half is a **structural invariant, not an equivalence**: it would pass a
netlist whose buffers were correctly connected and whose logic was wrong.

⇒ **WHAT §1–§4 ESTABLISH IS THAT THE REPAIR CANNOT HAVE MOVED A BOUND OBJECT, NOT THAT THE REPAIR
IS FUNCTION-PRESERVING.** For this artifact the first is what the Captain's condition asked for,
because the proof chain does not reach `slicea16bma` at all (§1). It is stated here so that a
later hand does not read "binding audits green" as "the resizer is proved harmless."
📌 The instrument for the harder claim exists — `docs/silicon-tools/equiv_synth.sh`, SAT miter via
yosys, link (4) of the four-link chain — but it is built for **combinational** miters and this
design carries 552 flops. Whether it can be pointed at synthesis-vs-final is **unmeasured**;
pricing it is a separate act and it was not attempted here.

## 6 · ⚠️ A SCOPE QUESTION FOR THE HELM, WITH THE MEASUREMENT ATTACHED — NOT A FINDING AGAINST ANYONE
The ①d numbers are **`slicea16bma` hardened STANDALONE on its own 3×2 die**. That is the right
object for the DRV row: the Captain's executable word is *"BYTE-WIDE -ma ON ITS OWN 3×2"*
(QUEUE, council ruling #1 of 08/09), and the row's own figures were re-derived against
`slicea16bma_3x2_metrics.json` on 08/27 00:2x.

Ruling 11:0x describes the resubmission as *"updated NDF to the TT shuttle."* **`tt_um_saltworks_ndf`
and `slicea16bma` are different hardens**: NDF instantiates `slicea16bma` as `core` (§1) but is a
6×2 die at `CLOCK_PERIOD 55`, while ①d is a 3×2 at 40. ⇒ **If the artifact the Captain clicks is an
NDF harden, what transfers from this work is the CONFIG — `RSZ_CORNERS` plus the two hold margins —
and NOT the measurements.** No run has measured what ①d's knobs do to an NDF harden; the slew/cap/
hold/fanout figures in the bank are `slicea16bma`-3×2 figures and say nothing about NDF's.
**Which artifact is being resubmitted is not this seat's call, and the answer changes what is owed
before Sept 4–5.** If it is NDF, one NDF harden under the ①d knobs is the missing measurement.
