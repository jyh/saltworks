# R3 — THE REGFILE. RUN, NOT ARGUED.

### 2026-08-06 night, SILICON. Campaign freeze `a69fee0`, kill-check R3:
### *"THE REGFILE: 1024 state bits. Show the flop-treatment census keeps every
### cone inside the law, and that cycle induction over that state shape
### elaborates (a Scratch probe, not an argument)."*

**R3 cannot be measured on a real artifact — no CPU netlist exists.** So it was
measured on a *synthetic* RV32I register file (`RTL/regfile32.v`, 2 read ports,
1 write port), synthesised by the pinned flow. ⚠️ That file **cannot reach the
tape-out**: `TT/assemble.sh` copies two NAMED files, never `RTL/*.v`.

## Predictions, registered BEFORE synthesis

Written to disk before `synth.sh` ran, so the census could not be read backwards:

| | prediction | outcome |
|---|---|---|
| **P1** | 992 flops (31×32), **not** the 1024 the kill-check names — `x0` is hardwired | ✅ **992** |
| **P2** | write cones small (~8 in) | ✅ **D = 1, DE = 6** |
| **P3** | read cones = raddr(5) + 31 registers = **36**, over the ceiling | ✅ **exactly 36** |
| **P4** | R3 therefore does **not** pass on the default cut set | ✅ **93.9 %** |

## ⛔ THE VERDICT: R3 DOES NOT PASS AS SYNTHESISED, AND THE FAILURE IS PERFECTLY UNIFORM

```
regfile32_nl.v   2500 cells   1056 cones   med 6   max 36   93.9% <= 24
```

| root kind | distinct | min | med | max | **over 24** |
|---|---|---|---|---|---|
| `D` (data in) | 32 | 1 | 1 | 1 | 0 |
| `DE` (write enable) | 31 | 6 | 6 | 6 | 0 |
| **`OUT` (read ports)** | **64** | 36 | 36 | **36** | **64 / 64** |

⇒ **The entire write side is trivial and the entire failure is the READ PORTS**,
all 64 at exactly 36 = `raddr`(5) + 31 register leaves — a 31:1 mux per bit.
**Not a spread of difficulty: one shape, repeated 64 times.**

**The remedy is the one already proved on the fabric.** `uo_out` was 36 and
`(* keep *)` at the stage boundary took it to 21. A read mux cut into two levels
(4 groups of 8) gives 3+8 = 11 and 2+4 = 6 — **both far inside the law.** The
same treatment, the same reason, and R2's *"demonstrate before C3 freezes"*
applies here too: **this remedy is priced, not yet demonstrated.**

## ✅ SECOND HALF: CYCLE INDUCTION ELABORATES AT CPU SHAPE — probe, with the audit

```lean
abbrev RegSt := Fin 992 → Bool   abbrev RegIn := Fin 43 → Bool   abbrev RegOut := Fin 64 → Bool
example (f g : RegSt → RegIn → RegSt × RegOut) (h : ∀ s i, f s i = g s i) :
    ∀ (s : RegSt) (is : List RegIn), iterate f s is = iterate g s is := iterate_congr f g h
```
```
✓ SaltWorks.Silicon.Imported.iterate_congr [1 axioms]      saltbuild EXIT=0
```

**And the reason it is free is worth stating:** `iterate_congr`'s induction is on
the **input list**, not on the state. **Nothing in it scales with state width** —
992 bits costs exactly what 4 bits cost. ⇒ **The sequential lift is not where a
CPU proof gets expensive. The per-cycle obligation is, and that is the cone
question above.**

## ⛔⛔ AND R3 FOUND TWO SOUNDNESS BUGS IN THE INSTRUMENTS — the real headline

### 1. `cones.py` silently reported cones **six times too small**

First census of the regfile: **`max 6, 100 % ≤ 24`** — a clean pass. It is wrong.
The true max is **36**.

`\regs[20] [26]` — an escaped vector net indexed at a bit, which is how yosys
writes a register-file bit — composed its bit-select **only for `ID` tokens, not
`ESCID`**. The name fell through as `regs[20]`, and the trailing `[`, `26`, `]`
were re-scanned: `26` hit the **literal-constant branch** and overwrote the net
with the phantom constant **`1'b26`**. All 992 register bits became 32 fake
constants; constants are cone leaves; the cones collapsed.

⚠️ **It did not warn. It printed a confident, clean, wrong number** — on the
exact shape the CPU road is made of. **I caught it only because it contradicted
a prediction I had written down first.** *Without P3 on disk, "max 6, 100 %"
would have been posted as R3 PASSING.*

### 2. `cones.py` did not root the enable flop's write cone at all

Root pins were `("D", "SCD", "SCE", "SET_B", "RESET_B")` — **no `DE`**. yosys
reaches for `edfxtp` (enable flop) whenever a register has a conditional write,
i.e. **for every register file and every CPU state element**. Its `D` is wired
straight to a data input (a 1-input cone); the entire write decode sits on `DE`.
⇒ **The census reported the trivial cone and hid the only interesting one.**

### 3. The importer had the same aliasing latent — and **refused before reaching it**

`import_netlist.py` took the `ESCID` alone, aliasing **all 32 bits of a register
onto one net**: 2549 distinct nets collapsed to 1588, **961 merged**. It never
produced a wrong datum, because tonight's *refuse-rather-than-approximate* guard
fired first: **`unmodelled sequential cell(s): edfxtp_1 x992`**. ✅ **A guard
written at 20:50 caught a real case at 21:5x.** *Had the importer done the
convenient thing and skipped unknown sequential cells, it would have silently
dropped 992 state bits and still typechecked.*

**Why the banyan never saw any of this:** its escaped nets carry the index
**inside** the escape (`\fabric.w0[0]`) with no following bracket, so nothing
aliased and nothing was corrupted. **Every banyan figure re-measured identical
after the fix** — 64 / 12 / 36 / 87.5 % default, 80 / 7 / 21 / 100 % cut. *The
bug was latent for the design we shipped and fatal for the design we are about
to build.*

## What landed with this

* `Sim/cones.py` — ESCID bit-select composed; `DE` added to the root pins.
* `Importer/import_netlist.py` — ESCID bit-select composed; **`edfxtp` modelled**,
  `next = DE ? D : Q`. ✅ Honestly modellable *because the enable is
  **synchronous*** — sampled at the same edge, so the next state really is a
  function of the flop's inputs and its own state. **`dfrtp` stays refused**: its
  `RESET_B` is asynchronous and admits no such function. *That distinction is
  exactly what the refusal exists to protect, and it has now been used in both
  directions.*
* `Imported/Fabric.lean`, `Imported/FabricCut.lean` regenerated — **gate lists and
  `_outs` byte-identical** (md5-checked); only the 52 state-table comment lines
  changed glyph. Full build **8606 jobs, `EXIT=0`**.
* `Importer/reimport.sh` — Comparator and Switch still reproduce **byte-for-byte**.

## Owed

The regfile still does not import end-to-end: after `edfxtp`, the importer stops
at **`no expansion for cell 'mux4_2'`** — an ordinary cell-model gap, priced by
the same census process as the 30 models added earlier tonight, and **refusing is
the correct behaviour**. Not a blocker for R3's verdict, which the cone census
already settles.
