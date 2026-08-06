# THE CONE CENSUS — what replaces "equivalence per module"
### 2026-08-06, Silicon seat. Measured on **nine real TinyTapeout submission
### netlists**, three of them built by `librelane 3.0.5` for TTSKY26c itself.

## The problem

The evidence seat measured that **the flow flattens**: a TT submission netlist
contains exactly one `module` and one `endmodule`. So the freeze's
*"equivalence, per module, by `decide +kernel`"* **has no modules left to be
per**, and the decomposition it promises is stated nowhere.

## The answer, and it was always the real one

A flat *sequential* netlist decomposes at the **flop boundary**, not at a module
boundary. Every flop `D` pin and every primary output roots a **combinational
cone**, bounded below by flop `Q` pins, primary inputs, and tie cells. Those
cones are what get certified; they compose structurally.

This is available whether or not hierarchy survives — and it is why
`SaltWorks/Silicon/Equiv/BitSliced.lean` quantifies over a `List Gate` rather
than over a module. **The reflection theorem never needed the boundary.**

## The decisive number is INPUTS, not gates

A bit-sliced certificate costs `2^inputs` bits per net, and the compiler seat
established a **hard kernel ceiling at 24 input bits** (`Nat.pow` is
GMP-accelerated only to exponent `1 <<< 24`). Gate count is nearly free; input
count is the wall. So the question is: *what fraction of real cones have ≤ 24
inputs?*

## Measured

`SaltWorks/Silicon/Sim/cones.py` — run it on any powered netlist.

| design | logic cells | physical | cones | med. inputs | max | **≤24 inputs** | max gates |
|---|---:|---:|---:|---:|---:|---:|---:|
| aka_regfile_ecc | 1743 | 3601 | 488 | 5 | 226 | 97.5 % | 331 |
| dosci_500hz | 471 | 3239 | 130 | 1 | 29 | 96.2 % | 190 |
| factory_test (26a) | 90 | 4425 | 42 | 2 | 8 | 100 % | 11 |
| factory_test (26c) | 90 | 4425 | 42 | 2 | 8 | 100 % | 11 |
| LFSR | 290 | 3771 | 93 | 1 | 40 | 96.8 % | 50 |
| morse_converter | 627 | 2898 | 166 | 1 | 49 | 71.7 % | 150 |
| quick_bus | 3117 | 6578 | 463 | 14 | 52 | 74.1 % | 156 |
| SimpleCounter | 114 | 4389 | 9 | 9 | 12 | 100 % | 31 |
| snn_lif_neuron | 2208 | 3869 | 193 | 18 | 84 | 85.5 % | 973 |
| **all** | | | **1626** | | | **86.8 %** | |

And our own designs, same measure:

| design | cones | max inputs | ≤24 inputs |
|---|---:|---:|---:|
| `bitserial_switch` | 6 | **6** | **100 %** |
| `comparator` | 16 | **16** | **100 %** |

## Reading it

**For the tapeout, this is settled.** Every cone in the bit-serial switch element
has at most 6 inputs, and the fabric is twelve copies of that element. Per-cone
bit-sliced certification covers our design **completely**, with two orders of
magnitude of headroom against the 24-bit ceiling. The plan is a plan, not a hope.

**In general it is 86.8 %, and the tail is real.** The worst cone measured is
**226 inputs / 325 gates**, in a register-file ECC design — a wide XOR tree,
which is exactly the shape that defeats enumeration and exactly the shape that
yields to a *structural* proof. So the honest general statement is:

> Per-cone exhaustive certification covers ~87 % of cones in real designs of this
> class outright. The remaining ~13 % are wide combinational trees, and they need
> a structural argument rather than an exhaustive one — the same split the
> campaign already makes between `banyan_selfrouting` (structural, parametric in
> `k`) and the per-module certificates.

That split is not a weakness discovered late; it is the same architecture at one
level down. But it must be **stated**, because "per module by `decide +kernel`"
implied a uniform method and there is none.

## THE MEMORY LAW — the correction I owed my own repair

When I reported bit-slicing I published a **time** result and no memory result.
That was an omission, and the refuter pass caught it: slicing does not remove the
wall, it **moves it from time to memory**. Here is the law, measured.

Each net carries `2^n` bits, so

> **slice footprint ≈ (number of nets) × 2^n / 8 bytes**

on top of a fixed ~670 MB Lean+mathlib baseline. Measured peak RSS through
`saltbuild.sh`, ripple-carry adder, 5 gates per bit:

| input bits `n` | configurations | nets | predicted slice | **measured peak RSS** |
|---:|---:|---:|---:|---:|
| 8 | 256 | 20 | 640 B | 669 MB |
| 16 | 65,536 | 40 | 320 KB | 670 MB |
| 20 | 1,048,576 | 50 | 6.3 MB | 670 MB |
| 24 | 16,777,216 | 60 | **120 MB** | **869 MB** |

The first three are lost in the baseline; at `n = 24` the slice data is visible
and lands where the law predicts (the ~80 MB excess is intermediates).

**And there is a hard ceiling at `n = 24`, which is not mine** — the compiler
seat established it: `Nat.pow` is kernel-accelerated only to exponent `1 <<< 24`,
so a `2^n − 1` mask above 24 bits leaves the fast path. That is why my earlier
"24 input bits, 60 gates, seconds" hit exactly 24 and not 25; I had the number
and not the mechanism.

So the two routes differ in **shape**, not merely speed:

* pointwise `decide +kernel` has **no memory bound at all** — it materialises the
  reduction, which is how a probe elsewhere in the fleet reached 30 GB;
* bit-sliced is **bounded by construction** at ≤ 2 MB × #nets and *cannot* reach
  the fleet's memory cap.

### What this rules out, and what it leaves standing

**Monolithic fabric certification is impossible, and by a wide margin.** The 8×8
serial fabric has 8 primary inputs plus 12 elements × 4 state bits = **56 bits**,
so one net would be `2^56` bits ≈ 9 PB. Not 2 TB as I first estimated (I was
using 3 state bits per element before the activity bit was added) — worse. There
is no version of this that fits.

**Per-cone certification is comfortable, and by a wide margin.** Every cone in
the switch element has ≤ 6 inputs → 64 bits per net. The whole fabric's
certificate suite is kilobytes. The measured comparator equivalence (D3, 236
nets at `n = 16`) is ~1.9 MB of slice data and builds in about three seconds.

The gap between those two numbers — 9 PB against kilobytes — is the entire
argument for why the decomposition is not optional.

## Two incidental measurements worth keeping

**Physical cells dominate.** `factory_test` is 90 logic cells against 4,425
physical ones — TT pads every tile. The importer must therefore *discard* the
overwhelming majority of what it parses, and the discard rule must be by cell
identity, not by arity (see `docs/silicon-refuter-0806-addendum.md` §0: the
tap cell has two power pins, not four, and is absent from Liberty entirely).

**Cone count is small.** 1,626 cones across nine designs; 9 to 488 per design.
So the number of certificates per chip is in the hundreds, not the thousands —
which is what makes a per-cone `#audit_axioms` roll-up tractable.
