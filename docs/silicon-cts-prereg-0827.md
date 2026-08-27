# ② CTS EXPERIMENT — PRE-REGISTRATION (criterion published BEFORE the run)
silicon, 2026-08-27. Authorized at the council (item ⑦ / ruling 11:0x); this file is written
BEFORE any CTS run so the bar cannot be fitted to the outcome.

## 1 · THE TARGET, MEASURED ON ①d ITSELF — NOT CARRIED FROM AN EARLIER RUN
`55-openroad-stapostpnr/nom_tt_025C_1v80/checks.rpt`, ①d:

```
max fanout violation count 37
  33 pins   clkbuf_leaf_*_clk/X   limit 10   fanout 12   slack -2
   4 pins   clkbuf_leaf_*_clk/X   limit 10   fanout 11   (violated)
   0 pins   datapath
```
⛔ **THIS CORRECTS THE FIGURE THE BANK CARRIES.** The bank says *"38 of 38 violating pins are
CTS clock-leaf buffers at 12–13 vs limit 10."* On ①d it is **37 of 37, at 11–12** — the count and
the range both moved with the repair, and the earlier reading was of an earlier run. The
load-bearing half is unchanged and re-confirmed: **every violator is a clock-leaf buffer; zero are
datapath.**
📌 Corroborating datum: the count is **37 at all nine corners**, identical. A fanout violation is
topological, not timing-dependent — consistent with CTS structure and not with corner coverage
(which is what ①d fixed for slew: 680 at max_ss vs 104 at max_tt).

## 2 · THE KNOB — DERIVED FROM THE RUN'S OWN VARIABLE LIST, NOT FROM THE SUGGESTION
The helm's fire order named `CTS_SINK_BUFFER_MAX_CAP_DERATE_PCT`, `CTS_CLK_BUFFERS`,
`CTS_DISTANCE_BETWEEN_BUFFERS`. Reading the CTS variables the flow actually resolved (①d
`resolved.json`):

```
CTS_SINK_CLUSTERING_ENABLE        True
CTS_SINK_CLUSTERING_SIZE          None     <- UNSET; observed leaf fanout is 11-12
CTS_SINK_CLUSTERING_MAX_DIAMETER  None
CTS_SINK_BUFFER_MAX_CAP_DERATE_PCT None
CTS_CLK_BUFFERS      [clkbuf_8, clkbuf_4, clkbuf_2]      CTS_ROOT_BUFFER  clkbuf_16
CTS_DISTANCE_BETWEEN_BUFFERS 0            CTS_CLK_MAX_WIRE_LENGTH 0
```
⇒ **`CTS_SINK_CLUSTERING_SIZE` is the knob that names the measured defect** — sinks per leaf
buffer — and it is the one variable the suggested list did not contain. The observed 11–12 sinks
per leaf is exactly what a clustering size the flow chose for itself would produce.
*Derived from the interface, not from a sibling run.*

## 3 · THE ARMS — ONE AXIS PER RUN (the ①c/①d discipline that dissolved the last false trade-off)
```
②a   CTS_SINK_CLUSTERING_SIZE = 10      the limit itself
②b   CTS_SINK_CLUSTERING_SIZE = 8       margin below the limit
```
②b runs only if ②a leaves violations. Nothing else changes; ①d's resizer settings are held.

## 4 · ⛔ THE BAR, PRE-STATED — PASS/FAIL AND THE COST CEILING
A CTS arm **CLOSES** the item iff, at every one of the nine corners:
1. `design__max_fanout_violation__count` = **0**; and
2. no metric regresses past these ceilings, all measured against **①d**, not against baseline:
```
max_slew           <= 680      (①d)          hold WS      >= 0.150 ns   (①d 0.2214)
max_cap            <=   6      (①d)          setup WS     >= 15.00 ns   (①d 15.6706)
DRC · LVS · antenna =  0/0/0                 inst area    <= 104,000    (①d 101,535, +2.4%)
```
⇒ **A run that zeroes fanout while breaching ANY ceiling is NOT a pass — it is the measured cost
of the alternative**, and it is reported as such.
⛔ **AND THE SPEC-ACCEPTANCE ACT IS NOT MINE.** Only if neither arm closes it does *"a clock leaf
at 12 sinks is acceptable"* become live, and that is **the Captain's**, to arrive with the measured
cost attached. This seat reports; it does not accept a spec deviation and it submits nothing.

## 5 · WHAT WOULD MAKE ME DISTRUST A GREEN
- Fanout 0 with **flop count ≠ 552** ⇒ CTS restructured state; the §4 audit re-runs and the arm
  is void regardless of its metrics.
- Fanout 0 with **cell count unchanged** ⇒ suspect the knob was silently discarded rather than
  applied (the `resolved.json` must show the value I set — read the artifact, never the report).
- A clean sweep on the first arm with no metric moving at all ⇒ verify the treatment applied
  before believing it.

## 6 · RESOURCE PROTOCOL, PRE-STATED
Docker daemon is **DOWN** at writing; the fleet build lock is **HELD** by math (`pid 41899`,
`../saltbuild.sh Salt.MR.All`). A LibreLane Docker run does **not** take that lock, so it would run
concurrently with a peer's Lean build against the 43 GB memory law. ⇒ **Wait for the holder to
finish — the priority lane is "acquire next", NO PREEMPTION** (council item ③). Then: interop
marker held for the WHOLE window · daemon up · run · daemon down · **RSS checked after**, because
"daemon down" is not "memory returned" (774 MB lesson).

---
# ⛔ RE-AIMED TO THE PAID CHIP — PRE-REGISTERED 12:5x, BEFORE THE RUN
The §1–§6 pre-registration above targets `slicea16bma` 3×2. **The helm ruled the clicked artifact is
the 6×2 NDF, and measurement then refuted §1's premise for it.** This section supersedes the OBJECT
and the BAR; the method (one axis per run, knobs before spec-acceptance) is unchanged.

## 7 · THE OBJECT AND WHY IT MOVED
```
                        clock-leaf   datapath   total    ⇒ can CTS knobs alone reach 0?
3x2 ①d                          37          0      37    YES  (§1's premise)
NDF ndf-base (paid chip)       111          6     117    NO   ⛔ §1's premise is FALSE here
NDF ndf-1d                     111          0     111    YES  — restored, but only AFTER ①d
```
⇒ **② runs on the NDF *with the ①d knobs held*, because the clock-leaf-only residual EXISTS ONLY
AFTER ①d.** Baseline for this arm is **`ndf-1d`**, not `ndf-base` and not the 3×2.
Arm **`ndf-2a`** = `config-ndf-1d.json` + `CTS_SINK_CLUSTERING_SIZE = 10`; ONE axis.
Sink budget: 1,468 flops at ≤10 sinks needs **≥147 leaves** (there are 111 now, at fanout 12–15).

## 8 · ⛔ THE BAR — judged against `ndf-1d`, and keyed on `__stdcell` DELIBERATELY
```
max_fanout   == 0 at ALL NINE corners          ← the object of the experiment
max_slew     <= 857        (ndf-1d)            hold WS   >= 0.19383 ns  (ndf-1d)
max_cap      <=   5        (ndf-1d)            setup WS  >  0 AND >= 3.00 ns
stdcell area <= 131,537 × 1.03 = 135,483       DRC · LVS · antenna = 0/0/0
flops        == 1,468 exactly
```
⛔⛔ **`design__instance__area` IS NOT USED AND MUST NOT BE.** It equals `design__core__area` on an
absolute-die run and CANNOT MOVE — it reported a false ✅ for the NDF pair's area clause this
morning. **This bar keys on `design__instance__area__stdcell`, which is free to move.**
*Direct application of today's correction: ask of every clause whether its metric has a degree of
freedom to fail in.*
⇒ **A run that zeroes fanout while breaching any ceiling is NOT a pass — it is the MEASURED COST of
the alternative**, and only then does "a clock leaf at 12–15 sinks is acceptable" become live. **That
act is the CAPTAIN'S**, to arrive with this cost attached. This seat reports and submits nothing.

## 9 · ⚠️ AUTHORITY, STATED PLAINLY
② was authorized by the council and the helm said it "proceeds as pre-registered". **The RE-AIM from
the 3×2 to the NDF is MINE, from measurement, and is not yet ruled on.** I am running it because the
helm's own ruling made the NDF the artifact of record, so running §1's 3×2 arm would knowingly
measure the diagnosis object. **A measurement is not a commitment — if the helm prefers the 3×2 arm,
this costs 8 minutes and I run that instead.**

## 10 · ②a RESULT AND WHY ②b STILL RUNS — recorded BEFORE ②b, 13:0x
`ndf-2a` (`CTS_SINK_CLUSTERING_SIZE=10`): **fanout 111 → 1.** All **111 clock-leaf violators
closed**; the single residual is **`wire695/X` at fanout 11**, and it is **DATAPATH, not a clock
leaf**. ⇒ **BY THE §8 BAR (`max_fanout == 0` at all nine corners) THE ARM DOES NOT CLOSE.** Every
other clause passes: slew 857→825 · cap 5→5 · hold 0.19383→0.19768 · setup 7.8868→7.8590 ·
stdcell 131,537→131,856 (+0.24%) · flops 1,468 · DRC/LVS/antenna 0/0/0.

⛔ **②b IS MIS-AIMED AT THIS RESIDUAL AND I AM SAYING SO BEFORE RUNNING IT.** `wire695` is a
`sky130_fd_sc_hd__buf_8` — **0 occurrences in the synthesis netlist, 1 in the final** (control:
`dfxtp` 1,468 in both), present in `ndf-1d` and ABSENT from `ndf-base`, i.e. **a RESIZER repair
buffer that ①d created.** Smaller sink clustering acts on the CLOCK TREE, and **there are zero
clock-leaf violators left for it to fix.**
✅ **IT RUNS ANYWAY, FOR A DIFFERENT AND STATED REASON: to discriminate STRUCTURAL from PLACEMENT
NOISE.** A different clustering perturbs placement and load distribution. If `wire695` lands at 11
again under `=8`, the residual is a real structural feature of the repaired datapath; if it moves or
disappears, it is placement noise and the "1" is not a stable property of the design. **That is
worth 8 minutes and it is not the same claim as "②b will fix it" — if it closes, that is
INCIDENTAL and will be reported as incidental.**
📌 The §8 bar is UNCHANGED for ②b. If neither arm reaches 0, the live question becomes whether
**117 → 1** is accepted, and that is a SPEC-ACCEPTANCE act belonging to the CAPTAIN, arriving with
the cost of the alternative attached — which is what these two arms measure.
