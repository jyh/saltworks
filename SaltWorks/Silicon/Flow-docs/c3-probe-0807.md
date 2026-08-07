# C3 PROBE — SILICON'S HALF: THE FLOW ACCEPTS STRUCTURAL INPUT, AND THE SLICE BOUNDARIES SURVIVE TO THE FABRICATED NETLIST

### 2026-08-07, SILICON. Council ruling 1 fired a measured probe of option (A),
### structural gate-level emission / synthesis-as-passthrough, with (B)
### algebraic per-cone proofs as fallback. My half: **does TT CI accept
### structural sky130 instantiations, and do our boundaries survive?**
### **Both answers are YES, measured on TT's own CI, with one real cost.**

## Predictions, registered on the bus BEFORE any run

| | prediction | outcome |
|---|---|---|
| **P1** | TT CI **accepts** structural input; `gds` + `precheck` green | ✅ **all four jobs green** |
| **P2** | cell names/counts **not** preserved (drive resizing, buffers) | ⚠️ **WRONG in the conservative direction — see below** |
| **P3** | per-slice structure **survives**; cones ≈3 not 62 | ✅ **max 3, on the fabricated artifact** |
| **P4** | *kill condition*: cones ≈62 ⇒ option A dead | ✅ **did not occur** |

## The A/B, both arms through the identical flow

The only difference between the arms is **input form**. Same function, same
ports, verified equal on 200 vectors against a Python reference *and* against
each other.

| | cells | cones (default) | **cut at carries** | carry nets present |
|---|---|---|---|---|
| **A — structural** | 40 | 9, max 17 | **16 cones, max 3** | **9 of 9** |
| **B — RTL control** | 24 | 9, max 17 | ⛔ **refused — no such nets** | **0** |

⇒ **RTL input dissolves every boundary; structural input keeps all of them.**
This reproduces last night's R2 finding at 8 bits through the same flow: with RTL
the optimiser re-derives, and `(* keep *)` preserves the net but not the
dependency. **Structural input does not need `keep` at all** — there is nothing
for the optimiser to re-derive, because the cells arrive already mapped.

⚠️ **Arm B's `--cut` did not report "no improvement" — it printed the UNTREATED
census, numerically identical to the default.** That silent no-op is fixed:
`cones.py --cut` matching no driven net is now a hard error. The same guard went
into the importer last night; the instrument that needed it most did not have it,
and it misfired inside this very probe.

## The mechanism, stated exactly

```
ERROR: Module `\sky130_fd_sc_hd__or2_1' referenced in module `\adder8s'
       in cell `\cy7' is not part of the design.
```

The committed flow **cannot read structural input at all** — nothing has told
yosys the cells exist. **`read_liberty -lib` before `read_verilog`** declares
them as **blackboxes**, and that one line is the whole of synthesis-as-passthrough:
**abc cannot restructure through a blackbox**, so an already-mapped design comes
out as it went in. Added to `Flow/synth.sh` as an **opt-in** (`SYNTH_STRUCTURAL=1`);
the default path still reproduces all three committed netlists byte-for-byte.

## The fabricated artifact (TT CI run `31182129057`, all four jobs green)

```
carry[1] … carry[8] present      (carry[0] was tied low -> a tie cell, correctly absent)
16 xor2_1 · 16 and2_1 · 8 or2_1 · 9 dfxtp_1   = 49 logic cells IN, 49 OUT
+ 17 conb_1 (ties) · 16 clkdlybuf4s25_1 (hold fix) · clkbuf tree · 20,498 physical
cone census:  default 9 cones max 16   |   cut at carries: 17 cones, median 3, MAX 3, 100%
```

⚠️ **P2 was wrong, and in the direction that matters less but should still be
said: the instantiated cells were preserved EXACTLY — names, drive strengths and
counts.** I predicted resizing (`_1`→`_2`) and it did not happen at this size and
slack. What the flow *did* add is hold-fix delay cells, tie cells, a clock tree
and fill — all logically identity or constant, all already modelled. **So
"survives" turned out to be stronger than I predicted, not weaker.**

## ⛔ THE ONE REAL COST, AND IT IS NOT SMALL

**TT's `test` job — the RTL simulation — FAILS on structural input:**

```
src/project.v:49: error: Unknown module type: sky130_fd_sc_hd__xor2_1
```

The RTL-sim job compiles the sources with **no PDK cell models**, because it
expects RTL. With structural input **there is no RTL to simulate**, so that job
cannot work as configured. ✅ **`gl_test` passes** — it *does* include the models,
and my 45-vector adder test ran green **against the post-layout netlist**, which
is the stronger check anyway.

⇒ **Option A collapses the RTL/GL distinction.** The honest statement is that a
structural design has exactly one simulation level, the gate level, and the
project's `test` job must either be given the PDK models or be dropped as
meaningless. **That is an integration cost to be decided, not a defect** — but it
is a real one and the council should price it.

## What this half concludes

**On the flow side, option (A) is VIABLE and measured:** the CI accepts it, the
hardening is green, the post-layout netlist is functionally correct, and **every
cone in the fabricated artifact is 3 inputs — against a 24-bit kernel ceiling.**

**Not concluded here:** whether the emitter can produce structural Verilog from
`Circ` (compiler's half), and what the area price is at CPU scale — this probe
paid **40 cells against RTL's 24 (+67 %)** for an 8-bit adder, and that ratio is
the thing to watch, not the boundary survival.
