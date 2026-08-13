# RESULTS — the `dfrtp` async-reset pre-registration

### SILICON seat · run 2026-08-12 evening · companion to
### `silicon-dfrtp-async-reset-prereg-0812.md`, which is FROZEN and unedited.
### Helm ruling 18:28 approved **M1** as shape; condition (4) cleared the
### importer-side mechanics to build tonight, emitter shape waiting on math.

## ⛔ VERDICT FIRST: **THE BAR IS NOT MET. NO DATUM LANDS.**

**C3 fails as literally registered, and C6's first form was a check that could not
fail.** Both are recorded below with what was done about them. The *mechanics*
land (default is still refusal, so nothing is loosened); the *certified dmem
datum* does not, and is not requested.

---

## 1 · THE SIX CHECKS

| | check | result | evidence |
|---|---|---|---|
| **C1** | all `RESET_B` reach the one named net; it is a primary input, not driven | ✅ **GREEN** | passes on `dmem8_nl.v` (execution proceeds past it) and on the fixture |
| **C2** | report every other consumer of the pinned net | ✅ **GREEN** | `0` on base/dmem; `1` **named** (`_06_.A (and2_1)`) on the planted arms |
| **C3** | pinned datum byte-identical to the `dfrtp`→`dfxtp` rewrite | ⛔ **FAILS AS REGISTERED** | §2 — diff published, cause named, **found a real defect** |
| **C4** | without the flag, `dfrtp` still refuses | ✅ **GREEN** | `EXIT=1` on `dmem8_nl.v` (`dfrtp_1 x256`) and on the fixture |
| **C5** | no path takes `RESET_B` as a data input | ✅ **GREEN** | 0 occurrences reach a gate constructor; **query shown to discriminate** on a planted line |
| **C6** | state-bit conservation | ✅ **GREEN, after being rebuilt** | §3 — the first version was tautological |

## 2 · ⛔ C3 — FAILS AS REGISTERED, AND IT EARNED ITS KEEP

Registered prediction: **byte-identical**, on the grounds that under `RESET_B ≡ 1`
the vendor `ff` group reduces to `dfxtp`'s field for field. **The full-file
comparison is RED.** The diff, published as the pre-registration requires:

**⭐ The first run showed a REAL defect, not a cosmetic one:**
```
  /-- fxNL: 7 gates ... -/        <- dfxtp arm
  /-- fxNL: 8 gates ... -/        <- pinned arm      + a stray  .const true
  def fxNL_outs := [3, 4, 6, 2]   vs   [3, 4, 7, 2]  + every index shifted
```
The pinned constant was seeded **eagerly**, so a `.const` was emitted even when
nothing read it — and when the reset feeds only reset pins (which the flop
treatment never reads) that constant is **dead**, yet it still inflated the gate
count and shifted every later index. ***The check caught precisely the thing it
was registered to catch, and I would not have looked.***

**Fixed**: the pinned net now binds **on first read**. Re-run:

| | |
|---|---|
| gate list, `_outs`, all indices | ✅ **identical** |
| `-- source:` filename | differs — two input files; artifact of the test method |
| the scope-marker header block | differs — **required by helm condition (2)** |
| flop table's cell-name column | differs — `dfrtp_1` vs `dfxtp_1`, documentary |

⚖️ **So the SUBSTANTIVE claim is verified — the pinned datum is GATE-FOR-GATE the
`dfxtp` reading — while the criterion AS WRITTEN cannot pass**, because it demands
byte-identity of a header the ruling itself requires to differ.

⛔ **I am not amending the criterion.** The bar stands as registered (ruling,
condition 1), so C3 is RED and the datum does not land. **The amendment I would
propose, for the helm to rule on:** C3 compares the gate list, `_outs`, and the
state-pairing table — the datum's *content* — and explicitly exempts the header
and the cell-name column. *A criterion I rewrite after seeing the result is worth
nothing, which is the entire reason it was published first.*

## 3 · ⛔ C6 — THE FIRST VERSION WAS A CHECK THAT COULD NOT FAIL

As first written it compared `len(ins) + len(auto) + len(cuts)` against
`len(ins_all)` — **and `ins_all` IS that sum.** An identity. It printed
`expected 5 measured 5 OK` and would have printed OK on every input forever.

*It read exactly like a check. It was decoration.* [[a-check-never-shown-to-fail]]

**Rebuilt** against a genuinely independent measurement — a raw regex over the
netlist **text**, sharing no code with the tokenizer or the instance assembly, in
the same spirit as `cones.py`'s independent cone census:
```
conservation : sequential instances — text scan 2, parsed 2, cut 2 + 0 caller-listed  OK
```
**And SHOWN to go red**, which the first version never could:
```
planted: one COMMENTED-OUT dfrtp instance
result : text scan 3, parsed 2  ⛔ MISMATCH   EXIT=1
```
⚠️ **That control also exposes the check's sensitivity direction, recorded in the
source rather than hidden:** a commented-out flop is a **false positive**. That is
the chosen direction — refusing on a commented flop is noisy; missing a dropped
one loses a state bit silently, and every doctrine in this importer prefers noise.

## 4 · THE CONTROLS — six planted defects, run through the REAL command

| control | must | observed |
|---|---|---|
| **NC1** reset pins split across two nets | RED | ✅ `exit=1` — "span 2 nets" |
| **NC1b** single reset net, but **driven** by `inv_1` | RED | ✅ `exit=1` — "derived reset, not a primary input" |
| **NC2** extra consumer of the pinned net | report, **not** block | ✅ `exit=0`, names `_06_.A (and2_1)` |
| **NC2b** extra consumer that **reaches an output** | constant emitted **and used** | ✅ `exit=0`, `.const true` = 1 (base: 0), 9 gates |
| **NCx** pinned net also listed in `--inputs` | RED | ✅ `exit=1` |
| **NCy** `--pin-reset` on a netlist with no flops | RED | ✅ `exit=1` — no silent no-op |
| **NC6** commented-out sequential instance | RED | ✅ `exit=1` (§3) |

**NC2 + NC2b are a controlled PAIR**, and the pair is the point: reset feeding
only reset pins ⇒ **no constant, gate-for-gate identical to `dfxtp`**; reset
feeding live logic ⇒ **constant emitted and genuinely used**. Either alone proves
nothing about the lazy binding.

## 5 · 📌 THE REMAINING BLOCKER FOR D1a IS NOT `dfrtp` — IT IS ONE COMBINATIONAL CELL

With `--pin-reset rst_n`, `dmem8_nl.v` clears the flop gate, C1, C2 and the clock
domain, then stops on:
```
importer: no expansion for cell 'nand4_1' (instance _0397_) — add it to EXPAND and to Sky130.lean
```
**Measured against the resolver's own rule** (exact key, else drive-stripped):
`dmem8` uses **11 distinct cell types; exactly ONE is unmodelled — `nand4_1`.**

⚠️ *My first two attempts at that number said "7 missing" and included `nand2` —
wrong both times, because I compared base names against a key set that mixes
`nand2_1` (full) and `and3` (base). **The cure each time was to read the
resolver's own function instead of assuming its convention.***

Adding `nand4` is **not** part of this pre-registration: cell models carry their
own discipline (full truth-table simulation against vendor Liberty, plus a proved
model in `Cells/Sky130.lean`). Named here, priced at one cell, not half-done.

## 6 · WHAT LANDED, AND WHAT DID NOT

```
LANDED    the mechanics: --pin-reset, the gated SEQ_MODELS entry, C1/C2/C4/C5/C6,
          the scope marker on the emitted datum, the lazy constant binding
          DEFAULT IS STILL REFUSAL — nothing is loosened for a caller who does
          not ask, and C4 proves it on the real artifact
NOT       any certified dmem datum. C3 is red as registered and the bar governs.
NOT       the Lean statement shape — math's call, untouched, no emitter pre-empted
REGRESSION  reimport 4 of 7 committed data, ALL REPRODUCE, EXIT=0, before and after
```

⚓ **Two of the six checks failed in a way that improved the artifact, and neither
would have been visible without registering them first.**
