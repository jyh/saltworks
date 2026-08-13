# THE IMPORTER "RANGE EXTENSION" — MEASURED, AND IT IS NOT A RANGE EXTENSION

> ## ⚖️ RULED 2026-08-13 05:40 BY MATH (docket call (4)) — READ THIS BEFORE THE QUESTION BELOW
>
> **(b) ADOPTED: the FLOW emits per-bit assigns; the TRUSTED IMPORTER KEEPS
> REFUSING.** *Option (a) — grow the trusted parser — is formally WITHDRAWN, not
> softened.* **Silicon's preference adopted on the argument, and the tiebreak is
> math's own and is better than anything either of us had:**
> 🔑 ***(b) IS REVERSIBLE AND (a) IS A ONE-WAY DOOR. Once the importer carries a
> bit-vector expression grammar, every datum imported afterwards rests its
> credibility on that grammar and you CANNOT RETROACTIVELY UN-TRUST IT — you
> would have to re-import and re-audit everything that passed through. A flow
> flag can be switched off tomorrow and leaves no residue.*** *On a genuinely
> close call, take the reversible option.*
>
> ⛔ **CONDITION, BINDING ON THIS IMPORTER AND NOT A LATER NICETY: WIDTH
> AGREEMENT IS A HARD ERROR EVERYWHERE.** *The ruling's stated reason is that (b)
> rests ENTIRELY on the refusal being right — **"a refusal that is lucky rather
> than principled is not a foundation, it is a coincidence that has not failed
> yet"** — and C-V1 is the measured proof that exactly this already happened
> once, at `EXIT=0` with readback GREEN.*
> ⇒ **That is §3's last row, which this document already called the soundness
> crux. It is now a STANDING OBLIGATION rather than a priced option.**


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

> ⛔ **ROW 1 IS DISCHARGED — corrected 2026-08-13 at math's finding (docket call
> (4) ruling, 05:40), with their receipt and not on my say-so.** *This table was
> written at `2dd0b22`, 18:47. Row 1 stopped being true **102 minutes later** at
> `af97825` 20:29 — my own C-V1 fix, which captures the bounds
> (`import_netlist.py:606-635`, "The BOUNDS are captured, not just the fact of
> being ranged") and consumes `vector_ports` at C-V1.*
> 🔑 ***MY OWN LATER FIX ROTTED MY OWN EARLIER DOC, and I did not notice — I was
> the author of both, 102 minutes apart, and it took another seat reading the
> bytes.*** *A doc does not rot only when SOMEONE ELSE moves; it rots hardest
> when the thing that moved was yours, because you are the one reader who
> "already knows" what it says.*
> ⚖️ **AND THE CORRECTION CUTS AGAINST MY OWN SIDE, which is why math checked it:**
> *removing the SMALL owed row leaves the remaining price sitting ENTIRELY on the
> two MEDIUM rows (RHS concat 17 lines, LHS concat 8) — **the reprice does not
> relieve option (a), it CONCENTRATES it.***


```
declaration parser -> capture (hi,lo) instead of discarding it     ✅ DISCHARGED
                      vector_ports becomes name -> (hi,lo)              af97825
                      unblocks: the 9 width-dependent lines             20:29
RHS concatenation  -> an expression parser + per-bit expansion     MEDIUM
                      unblocks: 17 lines
LHS concatenation  -> a concat as an ASSIGNMENT TARGET, i.e. bit-  MEDIUM, and the
                      slicing the RHS across several destinations  part nobody priced
                      unblocks: 8 lines
sized literals     -> N'hVAL -> per-bit constants                  SMALL (hex only)
width agreement    -> a mismatched width is a HARD ERROR, never a  ✅ DISCHARGED
                      silent truncate/zero-extend                  a0e2c4a 16:1x
                      C-V2, both doors: the caller's port list     08/13
                      AND every net the netlist names
```

> ⛔ **AND THIS TABLE ROTTED A SECOND TIME, THE SAME WAY, AND AGAIN ANOTHER SEAT
> READ THE BYTES BEFORE I DID.** *Row 1's correction above says it in my own
> words — "my own later fix rotted my own earlier doc, and I did not notice; I
> was the author of both."* **I then landed `a0e2c4a`, posted a receipt calling
> this row discharged, and left the table saying OWED.** *Compiler caught it
> within two minutes, offered the edit, and did not take it — correctly, it is
> my doc.*
> 🔑 ***THE PRICE TABLE IS THE LAST THING ITS AUTHOR RE-READS, BECAUSE THE AUTHOR
> IS THE ONE READER WHO ALREADY KNOWS WHAT IT SAYS.*** *Twice is not carelessness
> twice; it is a property of authorship.* ⇒ **When a landing discharges a priced
> row, the doc edit belongs IN THE LANDING COMMIT, not after the receipt — the
> receipt is exactly the moment the author stops looking.**
>
> ✅ **WHAT THE MEASURED HOLE WAS, since this row was only ever a price before:**
> *`d0` declared `[1:0]`, netlist reads `d0[7]` — not in `--inputs` it exits 1 by
> the **no-driver** check (a width fault diagnosed as a missing driver); LISTED in
> `--inputs` it **imported clean at EXIT=0** with a phantom input bit. The lucky
> refusal and the open door differed only in whether the caller mentioned the
> bad bit.*

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
