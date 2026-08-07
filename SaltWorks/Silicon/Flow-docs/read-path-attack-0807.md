# THE READ PATH, ATTACKED — four architectures measured through one flow

### 2026-08-07, SILICON, on the Captain's order. R3 showed the regfile's READ
### path is where the cones exceed the kernel ceiling; the area work showed the
### same regfile is 99% of a TinyTapeout tile. **One structure, both problems.**
### Every row below is synthesised through the pinned flow and censused.

## The result

| variant | max cone | ≤ 24 | regfile µm² | tiles (2×2) |
|---|---|---|---|---|
| **RV32I flat, RTL** — the baseline | **36** | 93.9 % | 45,011 | 0.99 |
| RV32I 2-level tree, **RTL + `(* keep *)`** | **29** | 99.9 % | 40,295 | 0.89 |
| RV32I 2-level tree, **STRUCTURAL** (primitive basis) | **11** | **100 %** | 67,025 | 1.48 |
| RV32I 2-level tree, **STRUCTURAL** (`mux2_1` cells) | **11** | **100 %** | **52,130** | **1.15** |
| **RV32E flat, RTL** (16 registers) | **19** | **100 %** | **21,592** | **0.48** |

## ⛔ RTL restructuring is not enough — and it fails in an instructive way

Writing the read path as an explicit two-level tree in RTL, with the eight group
boundaries `(* keep *)`-marked, **does** improve things: max cone 36 → 29, and
the area actually *drops* to 40,295 µm². **All 8 boundaries survive synthesis.**

⚠️ **But exactly one cone of 1312 stays over the ceiling**, and its leaves say why:

```
worst cone: rdata1[30]  (29 leaves)
  g1_3[30], r[1][30], r[10][30], r[11][30], … r[21][30], …
```

It mixes **one** group output with **~26 raw registers**. ⇒ **The optimiser kept
the named nets and then routed around three of the four of them for that bit.**

This is R2's law in a subtler form. R2 found `keep` preserving a net whose
dependency was wholly re-derived; here the dependency is **partially** preserved
— which is worse to reason about, because the census looks nearly right. **99.9 %
is not 100 %, and one 29-input cone is as fatal to a per-cone proof as a hundred.**

## ✅ Structural emission fixes it, and the measurement is unambiguous

The same two-level tree **emitted as cell instantiations** (option A, per the C3
probe earlier today):

```
128 of 128 group boundaries survive · 2981 cells in -> 2981 out
default cut set : 32 cones, max 37, 0% <= 24      <- the flat read path is hopeless
cut at groups   : 160 cones, median 11, MAX 11, 100% <= 24
```

**Nothing routes around a boundary that the optimiser never had the chance to
re-derive.** This is the C3 probe's finding landing exactly where it is needed.

## 🎯 The primitive basis is costing 40 %, and the fix needs no new trusted base

My emission used `Circ`'s basis (`and`/`or`/`not`), where a 2:1 mux is 3 cells:

| a 2:1 mux | µm² |
|---|---|
| `and2_1 + and2_1 + or2_1` (the primitive expansion) | **18.77** |
| the `mux2_1` **cell** | **11.26** — *40 % smaller* |

The read path is 1,984 muxes (2 ports × 32 bits × 31). Primitive basis: 37,254 µm²
predicted, **37,273 measured** — a 0.05 % cross-check. As `mux2_1` cells: **22,341 µm²**.

⇒ **Emitting `mux2_1` instead of its expansion takes the verifiable RV32I regfile
from 1.48 tiles to 1.15** — against the *unverifiable* baseline's 0.99. **Full
per-cone verifiability of the read path costs +16 % area, not +48 %.**

✅ **And it costs NOTHING in trusted base: `mux2_1` is already there** —
`Cells/Sky130.lean:142 mux2_1_liberty`, proved `decide +kernel`, and already in
the importer's expansion table. *The cell is emitted, the proof uses the
expansion, and the liberty theorem is the bridge. That is what that file is for.*

⚠️ **What it does cost is an emitter change**: `Gate` has no `mux` constructor, so
`Circ` cannot name one. The emitter must recognise the mux idiom and emit the
cell — **compiler's half, and worth pricing before C3 freezes.**

## 🥇 RV32E dissolves both problems, and it is not my call

**16 architectural registers (15 stored) — the standard embedded RV32 profile:**

* **max cone 19, 100 % ≤ 24 — with NO cut and NO tree.** The flat read path is
  natively inside the kernel ceiling, because the cone is 4 address bits + 15
  registers instead of 5 + 31.
* **21,592 µm² = 0.48 tiles** — less than half the RV32I baseline, and under a
  third of the verifiable RV32I tree.

⇒ **RV32E is verifiable *and* small with no structural trickery at all.** ⚠️ **But
it is a DIFFERENT ISA from the one the Captain named** ("RV32I, entire"), and
swapping the target to make the proof easier is exactly the move this campaign
should be suspicious of. **Recorded as a measured option for the Captain, not a
recommendation I am entitled to make.**

## THE EMITTER CHANGE, PRICED (Captain's order, 2026-08-07; RV32I confirmed as the target)

### Cost: zero in trust, zero in proof, ~30 lines in a file that is already untrusted

| what it might have cost | actual |
|---|---|
| new cell model + liberty theorem | **ZERO** — `mux2_1_liberty` is proved at `Cells/Sky130.lean:142` and `mux2_1` is already in the importer's `EXPAND` |
| a `mux` constructor on `Gate` | **ZERO** — not needed; see below |
| re-proving the equivalence | **ZERO** — the theorem compares **values**, not structure |
| trusted-base growth | **ZERO** |

**Why `Gate` needs no `mux` constructor.** The importer expands a `mux2_1` cell
into exactly `not S · and A0 ¬S · and A1 S · or` — **the same four primitives a
`Circ` mux produces**. So the emitted Verilog carries one *cell*, both Lean
netlists carry the same four *gates*, and they meet. The cell is emitted, the
proof uses the expansion, and the liberty theorem is the bridge.

**Why no proof changes.** `comparator_equiv` already relates two **structurally
different** netlists — synthesis output against a hand-written ripple reference —
by comparing `outs.map (runP …)` at output indices. **Structure is not what the
theorem constrains.** A peephole that changes gate shape cannot disturb it.

**Where it lands, and why that makes it safe.** In `emitV` (`EmitV.lean:76`),
which produces Verilog text and sits **outside** `emitN_sem`. The trusted chain
is `Circ --emitN--> Netlist` versus `fabricated --importer--> Netlist`. ⇒ **A
wrong peephole cannot produce a false theorem — it produces a FAILING proof.**

### Benefit: measured, one read port, identical tree and boundaries

| emission | cells | area µm² | boundaries | max cone |
|---|---|---|---|---|
| `Circ` primitive basis (`and`/`or`/`not`) | 2981 | 18,637 | 128/128 | 11 |
| **`mux2_1` cells** | **992** | **11,171** | **128/128** | **11** |

**3.0× fewer cells, 40 % less area, and the verifiability is unchanged.**
Passthrough exact both ways (992 in → 992 out).

⭐ **Cross-check: I computed 22,341 µm² for two ports BEFORE building the variant;
the measurement is 2 × 11,170.7 = 22,341.4 — agreement to 0.002 %.**

| regfile, 2 read ports + 992 flops | µm² | tiles |
|---|---|---|
| structural tree, primitive basis | 67,062 | 1.48 |
| **structural tree, `mux2_1`** | **52,130** | **1.15** |
| RTL baseline — **unverifiable**, max cone 36 | 45,011 | 0.99 |

⇒ **Full per-cone verifiability of the RV32I read path costs +16 % area over a
baseline that cannot be verified at all.**

### ⚠️ Yield is design-dependent, and I measured that rather than assuming it

Counting the 4-gate mux idiom in the netlists we already have:

| netlist | logic gates | mux idioms | gates collapsing |
|---|---|---|---|
| `Fabric.lean` (banyan, synthesis-derived) | 454 | **0** | 0 % |
| `Comparator.lean` | 111 | 14 | **50.5 %** |
| `Switch.lean` | 44 | 4 | 36.4 % |
| the read tree (by construction) | — | all | **100 %** |

**Zero on the banyan** — synthesis reached for compound cells (`a21oi`, `o21ai`)
whose expansions are not mux-shaped. ⇒ **The peephole pays where muxes are built
deliberately, which is exactly the CPU datapath** (operand select, ALU select,
writeback, PC) **and not where a synthesiser has already chosen a different
form.** *Quoting a single yield figure for "a CPU" would be an extrapolation, and
I have not made one.*

## What I would tell the council

1. **The read path is solvable at full RV32I.** Two-level tree, emitted
   structurally, `mux2_1` cells: **every cone 11 inputs, +16 % area.**
2. **It is solvable ONLY under option (A).** The RTL route reaches 29 and stops,
   because `keep` does not stop the optimiser routing around a boundary. ⇒ **This
   makes the read path an argument FOR (A) that is independent of C3's own.**
3. **RV32E would make it free** — 0.48 tiles, no cut — at the price of the ISA.
