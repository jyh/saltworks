# C3 PROBE — FORMAL VERDICT, SILICON HALF (the flow side)

### 2026-08-07, SILICON. Council ruling 1 fired a measured probe of option (A),
### structural gate-level emission / synthesis-as-passthrough, with (B) algebraic
### per-cone proofs as fallback. **This scores my four pre-registrations, posted
### to the bus at 06:14 BEFORE any run, and states what is and is NOT established.**

## VERDICT: option (A) is **VIABLE on the flow side**, with one integration cost

## Evidence, pinned

| | |
|---|---|
| CI run | **`31182129057`**, conclusion **success** |
| head SHA | **`449d87e`** (branch `probe-c3-structural`; `main` untouched) |
| jobs | `gds` ✅ · `precheck` ✅ (blocking) · `gl_test` ✅ · `viewer` ✅ |
| artifact | `tt_submission/tt_um_saltworks_banyan.v`, md5 **`17a6586c9126edf6c196465cd9dff496`**, 2,123,437 bytes |

## The four pre-registrations, scored

| | prediction (06:14) | outcome | score |
|---|---|---|---|
| **P1** | TT CI **accepts** structural sky130 instantiations; `gds` + `precheck` green | all four jobs green, end to end | ✅ **HELD** |
| **P2** | cell names/counts **not** preserved — drive resizing, buffering | **49 cells in, 49 out; names, drives and counts exact** | ❌ **WRONG** |
| **P3** | per-slice structure **survives to the fabricated netlist**; cones ≈ 3 | 8 of 9 named carry nets present; cut → **17 cones, max 3, 100 %** | ✅ **HELD** |
| **P4** | *kill condition* — cones ≈ 62 ⇒ (A) dead | did not occur | ✅ **NOT TRIGGERED** |

**P2 was wrong in the conservative direction**: survival was *stronger* than I
predicted, not weaker. What the flow added was hold-fix delay cells, tie cells, a
clock tree and fill — all logically identity or constant, all already modelled.

## The A/B that carries the verdict

Both arms through the **identical** flow; same function and ports; verified equal
on 200 vectors against a Python reference **and** against each other.

| arm | cells | cut at the carries | carry nets present |
|---|---|---|---|
| **A — structural** | 40 | **16 cones, max 3** | **9 of 9** |
| **B — RTL control** | 24 | ⛔ **refused — no such nets exist** | **0** |

⇒ **RTL input dissolves every boundary; structural input keeps all of them.** And
**structural input needs no `(* keep *)` at all** — there is nothing for the
optimiser to re-derive, because the cells arrive already mapped.

**Mechanism, in one line:** `read_liberty -lib` **before** `read_verilog` declares
the cells as blackboxes, and **abc cannot restructure through a blackbox.**

## ⛔ The one real cost, unchanged since 06:30

**TT's `test` job — the RTL simulation — FAILS on structural input:**
`Unknown module type: sky130_fd_sc_hd__xor2_1`. That job compiles with **no PDK
cell models**, and under (A) **there is no RTL to simulate.** `gl_test` passes and
ran my 45-vector adder test **against the post-layout netlist**, which is the
stronger check. ⇒ **(A) collapses the RTL/GL distinction: a structural design has
exactly one simulation level.** The `test` job must be given the models or
dropped. **An integration decision, not a defect.**

## What the ten-block survey adds to the verdict

Since the probe I have measured every block of an RV32I machine-mode core.
**(A) is not needed everywhere** — that is a material narrowing:

| needs **NOTHING** | needs **(A)** |
|---|---|
| writeback **6** · control **13** · memory **11** · hazards **20** | read **36→11** · ALU **68→20** · adders **64/30→3** · fetch **100→6** · branch **68→16** · CSR **31→21** · traps **57→~11** |

**And the reason (A) is *required* where it is required:** `(* keep *)` was tested
in **six** blocks and **failed in every one** — carry chain wholly re-derived,
read path 1 bit, ALU 8 bits, fetch 4 entire vectors, CSR an 8-bit compare, traps
an interrupt flag. **Not once did it hold.** *That is the strongest argument for
(A), and it is six independent measurements rather than one.*

## ⚠️ What this verdict does NOT establish

1. **The emission half is compiler's and is not scored here.** I probed the flow
   with a hand-generated structural article, deliberately, so the two halves
   could run in parallel. **My result transfers to any structural emitter — but
   that an emitter exists and is correct is not my finding to report.**
2. **Area at CPU scale is measured but not proven** — the regfile is measured,
   the rest of the core is one flagged estimate with a sensitivity sweep.
3. **No per-cone equivalence proof has been attempted on a CPU block.** The
   ceiling is now clear; the proofs are C5, not C3.
4. **The probe design is an 8-bit adder, not a CPU.** Boundary survival was
   measured on 49 cells. **It has not been measured on a 5,000-cell design**, and
   nothing forbids the flow behaving differently at scale. *I would run that
   before C5 rather than assume it.*
