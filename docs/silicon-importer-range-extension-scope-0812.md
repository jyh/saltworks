# THE IMPORTER "RANGE EXTENSION" — MEASURED, AND IT IS NOT A RANGE EXTENSION

### SILICON seat · 2026-08-12 evening · night item (2)
### STATUS: **SCOPING + REPRICING. No grammar written — the grammar call is MATH'S.**

## 0 · ⛔ THE HEADLINE: MY OWN PRICE WAS UNDERSTATED A SECOND TIME

My state bank already carried the cost estimate as **on record as understated**,
with the stated reason: `vector_ports` is a bare NAME SET with no widths, so the
LHS bare-vector expansion needs the **declaration** parser changed, one layer
below the assign branch. *That reason is correct and it is confirmed at the
source* (`import_netlist.py:404,422` — `vector_ports.update(names)`; the
declaration parser at `:410-414` **skips the range tokens entirely**).

**It is also not the main cost.** Measured across the tree, the form I priced is
**2 of 31 lines.**

## 1 · THE POPULATION — 31 range-assign lines in 13 of 46 netlists

```
$ grep -lE '^\s*assign\s+.*\[[0-9]+:[0-9]+\]' *.v          # 13 files, of 46
ctrl32 6 · fetch32 3 · core32 3 · slicea16bma 3 · slicea16s 3 · slicea16b 3
alu32 2 · slicea16 2 · slicea32 2 · banyan_fabric 1 · memif 1
dmem_addr8 1 · dmem_addr16 1
```

### The forms, by what each one actually demands of the parser

| form | n | needs |
|---|---|---|
| `word_index = byte_addr[4:2]` — bare LHS ← RHS range | **2** | ⭐ **the form I priced** — LHS vector WIDTH |
| `pc_q = { imem_addr[31:2], pc_plus_4[1:0] }` — bare LHS ← concat | 6 | width **+** RHS concatenation |
| `{ instr[31:20], instr[14:7] } = { … }` — **LHS is a CONCAT** | 8 | concatenation as an assignment **TARGET** |
| `imm_i[31:5] = { funct7[6], …, funct7 }` — LHS range ← concat | 3 | RHS concatenation |
| `imem_addr[1:0] = 2'h0` — LHS range ← sized constant | 6 | sized literals |
| `pc[31:2] = imem_addr[31:2]` — LHS range ← RHS range | 5 | range-to-range width match |
| `cnt[2:0] = cnt_o` — LHS range ← bare RHS vector | 1 | RHS vector width |
| | **31** | |

⇒ **This is not a range extension. It is a bit-vector expression grammar**: ranges
on both sides, **concatenation on both sides including as an assignment target**,
and sized constant literals.

**Two features it does NOT need, measured rather than assumed:**
* **no replication operator** — `grep -hoE '\{[0-9]+\{' *.v` returns **nothing**;
  yosys expanded every repeat explicitly (the `imm_*` lines carry `funct7[6]`
  written out 19 times). One whole feature not owed.
* **one radix only** — all 18 sized literals are hex (`N'h…`). No binary, octal
  or decimal forms present.

## 2 · WHAT THE CURRENT IMPORTER DOES, AND WHY THAT IS RIGHT

All 31 lines currently **REFUSE** (`e701f78`, plus the pre-existing concatenation
refusal at the `len(cur) > 1` arm). That refusal is not a gap to be closed
quickly — it is what stopped a **real, live, silent defect**: `[4:2]` was being
parsed as its TOP BIT, collapsing a three-bit word address to one net with
`RC=0`, a file written, and nothing said.

✅ **`reimport` is green at 4 of 7 with the refusal in place**, so no committed
datum depends on the collapsed reading.

⚠️ **One consequence worth stating plainly: `banyan_fabric_nl.v:1752` carries
`assign cnt[2:0] = cnt_o;`, so that netlist no longer imports.** This is **not** a
regression — before `e701f78` it imported *silently wrongly*. `Fabric.lean` is
unaffected because its source is the pinned TT artifact, not this file.

## 3 · THE REPRICE

```
declaration parser -> capture (hi,lo) instead of discarding it     SMALL, and owed
                      vector_ports becomes name -> (hi,lo)
                      unblocks: the 9 width-dependent lines
RHS concatenation  -> an expression parser + per-bit expansion     MEDIUM
                      unblocks: 17 lines
LHS concatenation  -> a concat as an ASSIGNMENT TARGET, i.e. bit-  MEDIUM, and the
                      slicing the RHS across several destinations  part nobody priced
                      unblocks: 8 lines
sized literals     -> N'hVAL -> per-bit constants                  SMALL (hex only)
width agreement    -> a mismatched width is a HARD ERROR, never a  SMALL, and the
                      silent truncate/zero-extend                  soundness crux
```

🔑 ***The soundness crux is the last row, not the parsing.*** Verilog silently
zero-extends and truncates on width mismatch. An importer that inherits that
behaviour would produce a datum that parses, typechecks, and proves theorems
about the wrong machine — the exact failure the flop treatment's refusal doctrine
exists to prevent. **Every expansion must carry an explicit width check.**

## 4 · 📐 THE GRAMMAR CALL IS MATH'S, AND HERE IS THE ACTUAL QUESTION

Not "should the importer parse ranges" — measured, that under-describes it by
15×. The question is:

> **Does the trusted importer grow a bit-vector expression grammar, or does the
> flow emit per-bit assigns and the importer keep refusing?**

The second option keeps the trusted parser at its current size (the design freeze
prices it at **≤300 lines**) and moves the expansion upstream where it is not
trusted. The first is more convenient and enlarges the trusted base.

**This seat has a preference and no authority: keep the trusted parser small.**
The importer is the one component the whole chain's credibility rests on, and a
concatenation-target parser is a lot of surface to add to it for 31 lines that a
flow flag may remove entirely.

⚓ **Owed to math at muster, with this measurement, alongside the `dfrtp`
statement-shape call.**
