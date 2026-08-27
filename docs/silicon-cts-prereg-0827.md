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
