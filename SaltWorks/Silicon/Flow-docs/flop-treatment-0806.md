# THE FLOP TREATMENT — Q-pins as leaves, D-pins as roots

### 2026-08-06, SILICON. Ordered by the Captain. The importer was combinational-only;
### the artifact TinyTapeout will fabricate has 52 flops. This is what closed that gap.

## The decomposition

A post-P&R netlist is sequential; a Lean `Netlist` is combinational. Rather than
teach the datum about time, **cut every flop**:

* its **`Q`** becomes a primary input — a cone **LEAF**, the current state;
* its **`D`** becomes an output — a cone **ROOT**, the next state.

What remains between the cuts is pure combinational logic, which is what
`decide +kernel` can decide. This is not a new idea in this campaign — it is the
decomposition **D3.5 and D4 already use**, applied one level up. The switch
netlist was imported this way in the first place; the caller simply typed the
four `Q` and `D` net names by hand, and nothing recorded that they had.

**The pairing is the point.** State input `i` and next-state output `i` are the
same flop, so a one-cycle obligation can be stated by lining the two vectors up.
Flops are ordered by **`Q` net name**, which survives resynthesis; the `D` nets
are machine-generated (`_000_`, `_017_`) and do not. That asymmetry is the whole
argument for discovering the cut here instead of asking a caller to type it.

## ⚠️ The soundness condition, checked rather than assumed

"Next state" is only well defined if every flop latches on the **same event**.
The obvious test — do all flops share a CLK net? — is **wrong**, and on this
artifact it would have raised a false alarm: after clock-tree synthesis the 52
flops sit on **eight** different CLK nets (`clknet_3_0__leaf_clk` … `_3_7_`).

So each CLK is traced back through the buffer/inverter tree to its source, and
all flops must arrive at the same **(root, inversion-parity)** pair. Measured on
the artifact: **one domain — root `clk`, parity 0, via 8 CLK nets.** A clock that
passes through real combinational logic (a gated clock) is a hard error, because
then the flops do not latch together and the decomposition is simply invalid.

## ⛔ What the treatment REFUSES, and why refusing is the point

Skipping a flop does not lose a gate — **it loses a STATE BIT**, and the netlist
would still parse, still typecheck, and still prove theorems about the wrong
machine. So:

* an **unmodelled sequential cell** is a hard error naming it and its count;
* a **connected pin the model does not account for** is a hard error — which is
  how a silently-dropped reset would be caught;
* a flop cut **by hand on one side only** (Q listed, D not) is a hard error,
  because it would pair a state input with the wrong next-state output.

**`dfrtp` is deliberately absent** though one line would make it import. Its
`RESET_B` is *asynchronous*: it acts between edges, so it is not a next-state
function of the flop's inputs at all. The tempting `next = D & RESET_B` is a
*synchronous* reset — correct only under an assumption about reset being held
across an edge that nothing in the netlist states. The RV32I work will bring
resettable flops; when it does, that is a question to answer, not a line to type.

## The artifact, pinned

Re-downloaded from the green HEAD run rather than taken from a scratch copy —
three copies were on disk with three different checksums, so "the one I had" was
not an answer.

| | |
|---|---|
| repo / run | `jyh/tt-verified-banyan-switch`, run **`31140274735`** |
| file | `tt_submission/tt_um_saltworks_banyan.v` |
| md5 / bytes | `0e043b432690f783669cc12a3a404458` / **2,094,688** |

```
python3 SaltWorks/Silicon/Importer/import_netlist.py <artifact> \
  --top tt_um_saltworks_banyan --out SaltWorks/Silicon/Imported/Fabric.lean \
  --name fabricNL \
  --inputs  ena,rst_n,ui_in[0..7],uio_in[0..7] \
  --outputs uo_out[0..7],uio_out[0..7],uio_oe[0..7]
```

## The result

```
instances     : 20122  (275 logic, 19847 physical/sequential)
primary inputs: 70  (18 design + 52 state)
outputs       : 76  (24 design + 52 next-state)
gates emitted : 524
flops cut     : 52   clock domain: one — root 'clk', parity 0, via 8 CLK nets
```

**`Fabric.lean` typechecks (`saltbuild EXIT=0`) and is in the hub's import
closure** — not merely on disk, which is the failure three seats hit tonight.

## Cross-validation: two independent implementations agree exactly

`Sim/cones.py` implements the same decomposition independently. It is not a
wrapper around the importer and shares no code with it beyond the tokenizer.

| | `cones.py` | importer |
|---|---|---|
| logic / physical instances | 327 / 19795 | 275 + 52 flops / 19847 − 52 |
| cones **with logic** | **64** | 76 roots − 12 constant = **64** |
| support median / max | **12 / 36** | **12 / 36** |
| ≤ 24 inputs | **87.5 %** | **87.5 %** |

The 12 roots the census does not count are genuinely constant: **`uio_oe[0..7]`
all tie to 0** (the tile drives nothing bidirectional) plus four `uio_out` bits.

## 🎯 The fact this makes visible for the first time

Splitting the supports by KIND — which needs the treatment, because before
tonight the next-state cones did not exist as roots at all:

| roots | count | min | median | max | inside the 24-bit ceiling |
|---|---|---|---|---|---|
| **next-state** (`D`) | 52 | 6 | 12 | **22** | **52 / 52 — all of them** |
| `uo_out` | 8 | 36 | 36 | **36** | 0 / 8 |
| other design outputs | 16 | 0 | 0 | 3 | 16 / 16 |

⇒ **The entire sequential half of the fabricated chip is already kernel-decidable
as it stands.** The only cones over the ceiling are the eight `uo_out` bits, and
those are precisely what ruling 4a's `(* keep *)` cut addresses — max 21, 100 %.
The 87.5 % headline is not a uniform difficulty spread across the design; it is
**52 easy cones, 16 trivial ones, and 8 hard ones that already have a treatment.**

## Two defects found while doing this

**1. The importer's docstring claimed a check that never existed.** It said
"every run is CHECKED per-instance (`--check`, on by default)" and described a
readback pass comparing the emitted Lean against a second tokenizer census. **No
such flag and no such pass exist**, and none ever did. What the run prints is a
*census report* — and a report cannot fail. Corrected in place; the readback
check is genuinely owed and is now recorded as open work rather than as a
finished feature.

**2. `build()` indexed primary inputs with `.index()`**, which returns the first
match, so a repeated net name would have aliased two inputs onto one gate and
shifted every later input's position. Harmless while the list was short and
hand-written; a real hazard now that the treatment appends 52 discovered nets.
Replaced with positional indexing plus an explicit duplicate rejection — which
then **caught negative control B below**, so it was load-bearing, not cosmetic.

## The regression that makes "unaffected" a proof rather than a sample

`Importer/reimport.sh` records the exact command line for every committed datum
and byte-compares. **The command lines existed nowhere before tonight** — each
file said "GENERATED by import_netlist.py" while the input order, which is the
caller's choice and which D3.5's proofs depend on bit-for-bit, was unrecorded.
They were recovered by reading the bit assignments back out of
`SwitchRefinement.lean` and re-deriving until the bytes matched.

```
✅ Comparator.lean reproduces byte-for-byte     (0 flops)
✅ Switch.lean     reproduces byte-for-byte     (4 flops, cut by hand)
```

Backward compatibility is what makes this provable: a flop the caller has
already cut on **both** sides is left exactly where the caller put it, so the
switch's original command still yields the committed bytes.

**Negative controls — a check that cannot fail is worth nothing:**

| mutation | expected | observed |
|---|---|---|
| perturb gate emission | both differ | ✗ Comparator, ✗ Switch |
| force auto-append over a hand-cut flop | switch only | ✅ Comparator, ✗ Switch |

The second is the exact regression the flop treatment could have caused, and it
was caught by the duplicate-input guard.

## Owed

* the **readback census check** the docstring used to claim (defect 1 above);
* `dfrtp` / async reset, before the RV32I netlist needs it;
* per-cone equivalence against the RTL — the next step, and the reason the
  ≤ 22-input next-state result above matters.
