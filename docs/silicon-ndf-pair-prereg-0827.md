# NDF PAIR — PRE-REGISTRATION, and the SUBMITTED CHIP'S REAL NUMBERS
silicon, 2026-08-27. Ordered by the helm 11:5x: the clicked artifact is the paid 6×2 NDF, so the
①d knobs must be measured against the NDF's OWN baseline on a named toolchain. Written BEFORE the
runs produce anything.

## 1 · ⛔ THE OBJECT, AND TWO WAYS THIS SEAT COULD HAVE AIMED AT THE WRONG ONE
**The paid top is `tt_um_saltworks_ndf_c32`.** Derived from `info.yaml @ 7d2b275` (`top_module`,
`tiles: "6x2"`, an 8-file `source_files` list) — and independently corroborated by the ①-audit RTL
hierarchy walk, which derived the same 7-module closure from the instantiation graph before this
manifest was read. **Two methods, not two readings.**

⛔ **TRAP 1 — THE REPO'S OWN CONFIG NAMES THE OTHER TOP.** `Flow/librelane/ndf_6x2_config.json`
sets `"DESIGN_NAME": "tt_um_saltworks_ndf"`. Its *filename* is still true — it names the TILE, and
the tile did not change — so nothing about it looks stale. It is the obvious file to reach for and
it would have hardened a design nobody paid for.

⛔ **TRAP 2 — `ndf-account-priced-half.md` §1's FIGURES ARE THE PREDECESSOR TOP'S.** §1 is headed
*"THE COMPOSED NDF AT 6x2 — MEASURED (run 465c669)"* and reports stdcell 69,673 · setup +8.13 ·
max-slew 1,895 · 902 flops. That run is **2026-08-10**. `tt_um_saltworks_ndf_c32.v` FIRST ENTERED
GIT ON **2026-08-18** (`f27965d0`) — eight days later. **Those numbers cannot be the submitted
chip's, and they sit in the same file as the submission receipt that names `_c32`.**
⇒ **THEY ARE NOT USED AS AN EXPECTATION HERE.** Measured: `Flow/layout-metrics/` contains **no NDF
or c32 entry at all** (control: it does contain `slicea16bma_3x2_metrics.json` and four others), so
**this seat holds no local post-PnR measurement of the submitted chip.** `ndf-base` will be the first.

## 2 · THE SUBMITTED CHIP'S ACTUAL SIGNOFF — READ FROM TT'S OWN RUN, NOT INFERRED
`gh run download 32284710003 -n tt_submission` → `tt_submission/stats/metrics.csv` (320 metrics)
and `tt_submission/resolved.json` (411 keys — the merged config that actually ran):
```
tt_um_saltworks_ndf_c32, TT signoff, run 32284710003, commit 7d2b275
  max_slew      3,317   max_ss  ·  2,963 nom_ss · 2,512 min_ss  ·  768 max_tt · 574 nom_tt · 230 max_ff
  max_cap          27   max_ss  ·     20 nom_ss ·    16 min_ss  ·  ZERO at every tt and ff corner
  max_fanout      117   IDENTICAL at all nine corners
  setup WS    +5.6680 ns      hold WS  +0.1105 ns      setup TNS 0.0   hold TNS 0.0
  inst area    225,802        stdcell 127,056          die 232,623      instances 43,884
  DRC 0 (magic) · LVS 0 · antenna 0 · inferred latches 0
```
⭐ **THE CORNER SIGNATURE IS THE (A) DEFECT, MEASURED ON THE PAID CHIP RATHER THAN ARGUED:**
`STA_CORNERS = 9` · `RSZ_CORNERS = None` · `DEFAULT_CORNER = nom_tt_025C_1v80` ·
`PL_RESIZER_HOLD_SLACK_MARGIN = 0.1` · `GRT_RESIZER_HOLD_SLACK_MARGIN = 0.05` ·
`MAX_FANOUT_CONSTRAINT = 10`. **The checker counts nine corners and the resizer optimises one** —
hence slew 5.8× worse at max_ss than max_tt, and cap violations at ss corners ONLY. This is the
same shape ①d fixed on the 3×2, now confirmed on the artifact that ships.
📌 **AND IT RE-AIMS ②: the shuttle's fanout residual is 117, not 37.** 37@11-12 is the 3×2 standalone
clock tree; the NDF's is a different tree (55 ns, 6×2, PL density 60, seven instantiated modules).

## 3 · TOOLCHAIN — CHANGED DELIBERATELY, AND SAID OUT LOUD
`tt_submission/pdk.json`: **`FLOW_VERSION 3.0.5`** and **`PDK_VERSION 8afc8346a57fe1ab7934ba5a6056ea8b43078e71`**.
* Flow: my pinned image `ghcr.io/librelane/librelane:3.0.5` @ `sha256:ecabd075…` — **same version as TT's.**
* PDK: **SWITCHED from `c6d73a35…` (which all five (A) runs used) to TT's `8afc8346…`**, which is
  present on this box (4.2 GB). ⛔ **CONSEQUENCE, STATED SO NOBODY DISCOVERS IT LATER: the NDF pair
  is NOT PDK-comparable to the five (A) runs.** It is internally controlled (both arms share the
  PDK) and it is comparable to the SUBMITTED CHIP, which is worth more.

## 4 · THE ARMS — the pair differs by exactly the ①d treatment, verified by set-diff
Both configs are the submitted `src/config.json` verbatim plus only the fields TT injects from
`tiles: 6x2` (DESIGN_NAME, VERILOG_FILES, DIE_AREA 1030.40×225.76, FP_DEF_TEMPLATE). Four keys
present in the submitted config but ABSENT from TT's 411-key resolved set (`FP_IO_HLENGTH`,
`FP_IO_VLENGTH`, `FP_PDN_MULTILAYER`, `FP_PDN_VPITCH`) were **dropped**, because matching what
actually ran beats matching what was written.
```
ndf-base   as submitted                                    (RSZ_CORNERS absent, margins 0.1/0.05)
ndf-1d     + RSZ_CORNERS[4] + margins 0.45/0.30            set-diff: 1 key added, 2 values changed
```

## 5 · ⛔ THE BAR, PRE-STATED — INCLUDING WHAT MAKES ME *NOT* RUN THE SECOND ARM
**(a) `ndf-base` — does my harness model the submitted chip?**
* **STRONG** — max_slew, max_cap and max_fanout each within ±5% of §2, and setup/hold WS within
  ±0.20 ns. ⇒ absolute numbers transfer; an ①d delta can be quoted against TT's own figures.
* **SIGNATURE-ONLY** — counts differ by more, but ALL of: fanout equal across all nine corners ·
  cap zero at every tt/ff corner and non-zero at ss · max_slew at max_ss with ss/tt ratio > 3 ·
  DRC/LVS/antenna 0/0/0. ⇒ **the delta is still valid (both arms share my environment) but the
  ABSOLUTE numbers do not transfer to TT's CI, and I will say so in the same sentence as the delta.**
* **FAIL** — DRC/LVS/antenna non-zero, or the signature does not reproduce. ⇒ **DO NOT RUN `ndf-1d`.**
  Report that the harness does not model the shipped artifact. A null is a finding.

**(b) `ndf-1d` — do ①d's knobs dominate on the paid chip?** Judged against `ndf-base`, not against §2:
```
max_slew   <  base      max_cap  <  base      max_fanout  <=  base
hold WS    >= base      setup WS >  0 AND >= 3.00 ns      area <= base x 1.03
DRC · LVS · antenna  =  0 / 0 / 0
```
⚠️ **THE NAMED RISK, PRICED BEFORE THE RUN: SETUP HEADROOM IS 2.8× TIGHTER HERE.** ①d bought its
hold and slew by spending **2.05 ns of setup**, and slicea16bma had **+15.67 ns** to spend from. The
NDF has **+5.668 ns** at a 55 ns clock. A 2 ns spend still leaves ≈3.6 ns — hence the 3.00 ns floor
above, set NOW rather than after seeing the number. ⛔ **`CLOCK_PERIOD 55` is bound to
`info.yaml: clock_hz 18181818` by the agreement law; setup slack is not free to trade for a slower
clock without a manifest change, and that is not this seat's act.**

⛔ **NOT MINE EITHER WAY: the resubmission click (public + money). This seat produces the measured
pair and the report.** If ①d's knobs do not dominate `ndf-base`, that is a REPORT, not a failure —
the paid NDF stands and (B) ships at the declared clock.

---
# ⛔ RUN 1 OF `ndf-base` FAILED ITS OWN PRE-REGISTERED BAR — AND THE BAR WAS RIGHT
Appended 12:2x, not rewritten. **The criterion in §5 did exactly the job it exists for: it
refused a result I would otherwise have called a reproduction.**

## What came back (12:10–12:19, 9 min, digest `ecabd075…`, PDK `8afc8346…`)
```
metric                     TT signoff     ndf-base run 1      delta        §5 STRONG bar
max_slew                        3,317              3,250     -2.0%         ±5%   ✅
max_cap                            27                 27      0.0%         ±5%   ✅
max_fanout                        117                112     -4.3%         ±5%   ✅
hold WS                     +0.11053           +0.10653     -0.004 ns     ±0.20  ✅
setup WS                    +5.66802           +7.80022     +2.132 ns     ±0.20  ⛔
inst area / die area      225,802 / 232,623   IDENTICAL      —
DRC · LVS · antenna              0/0/0              0/0/0     —
```
**STRONG: FAILED** on setup (+37.6%). **SIGNATURE-ONLY: ALSO FAILED**, on one clause — my run
put **2 max_cap violations at `max_tt_025C_1v80`** where the submitted chip has **zero at every
tt and ff corner**. Fanout was flat across nine corners ✅ and the slew ss/tt ratio was 5.09 ✅.
⇒ By §5(a) the verdict is **FAIL ⇒ DO NOT RUN `ndf-1d`**. Not run.

## ⛔ THE CAUSE, AND IT IS MINE: "ABSENT FROM WHAT RAN" DID NOT MEAN "NOT A VARIABLE"
§4 dropped four keys present in the submitted `config.json` but absent from its 411-key
`resolved.json`, reasoning that matching what RAN beats matching what was WRITTEN. **The
principle was right and I applied it by DELETING instead of TRANSLATING. They were RENAMED.**
```
submitted config.json      LibreLane 3.0.5 name      TT        my run 1
FP_IO_HLENGTH         ->   IO_PIN_H_LENGTH           2         None
FP_IO_VLENGTH         ->   IO_PIN_V_LENGTH           2         None
FP_PDN_MULTILAYER     ->   PDN_MULTILAYER            False     True
FP_PDN_VPITCH         ->   PDN_VPITCH                38.87     153.6
(never set at all)         RT_MAX_LAYER              met4      met5
```
⛔ **`RT_MAX_LAYER` IS THE WORST OF THE FIVE AND THE REPO TOLD ME.** `ndf_6x2_config.json`'s own
comment lists **seven** fields TT injects from `tiles:` — *DESIGN_NAME, VERILOG_FILES, DIE_AREA,
FP_DEF_TEMPLATE, **VDD_PIN, GND_PIN and RT_MAX_LAYER***. I supplied four. `VDD_PIN`/`GND_PIN`
defaulted correctly by luck; `RT_MAX_LAYER` did not, so **my run routed on met5 where the shuttle
routes on met4** — TinyTapeout reserves met5 for the harness.
⭐ ***EVERY ONE OF THE FIVE MAKES ROUTING EASIER: an extra metal layer, a 4× sparser power grid,
no multilayer PDN. The run came back with 2.13 ns MORE setup slack than the chip it claimed to
reproduce — the FLATTERING direction, which is the one that gets believed.*** Had the bar been
"within 5% on the DRV counts" alone, this passes on three of three and ships a false baseline.

## ✅ THE REPLACEMENT CRITERION IS STRICTLY STRONGER, AND IT IS A TOOL, NOT A JUDGEMENT
`docs/silicon-tools/resolved_diff.py` (selftested, four arms, driven both ways). It compares two
`resolved.json` files and **requires the NON-PATH difference set to be EMPTY**; path-valued entries
encode the host, not the design, and are ignored.
⇒ ***A CONFIG YOU WROTE IS A HYPOTHESIS; THE `resolved.json` IS WHAT RAN.*** Metric proximity is a
weak proxy for configuration identity — run 1 was within 5% on three of five metric axes while the
routing layer, the power-grid pitch and the IO pin geometry were all different.
**§5(a) is amended: `ndf-base` reproduces iff `resolved_diff.py` returns EMPTY against the submitted
`resolved.json`.** The metric table stays, as a *report*, not as the gate. §5(b) is unchanged —
`ndf-1d` is still judged against `ndf-base`, never against the signoff.
📌 Run 2 fired 12:2x with all five corrected **read from TT's `resolved.json`, not typed from this
page**, the gate wired into the runner, and — per helm ruling ③ — a **P1 ticket** taken before the
marker, since a marker-holder without a ticket makes the census a lie.
