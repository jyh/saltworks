# THE RV32I ALU — measured, and it needs FOUR cut families plus one the regfile never did

### 2026-08-07, SILICON, on the Captain's order, after the read and writeback
### paths. Predictions `A1`–`A6` were written to disk **before** synthesis.

## The three states of the ALU

| | cones | median | **max** | ≤ 24 |
|---|---|---|---|---|
| **monolithic** (no cuts) | 33 | 54 | **68** | **0 %** |
| **RTL + `(* keep *)`** at the ten op results | 287 | 13 | **275** | 68.6 % |
| **structural emission + 4 cut families** | — | — | **20** | **100 %** |

The monolithic figure is the whole point: **68 = 32 + 32 + 4**, every ALU output
bit depends on every input, and **not one cone of 33 is inside the ceiling.**

## ⛔ RTL + `keep` fails again — and this time NINE outputs stay over

Cutting at the ten named op results takes 24 of 33 outputs inside the ceiling
(median 13) and leaves **nine over**:

```
zero=275 · y[0]=75 · y[15]=32 · y[16]=31 · y[20]=28 · y[19]=28
y[11]=27 · y[21]=26 · y[10]=26
```

⚠️ **Two DIFFERENT causes, and separating them matters:**

1. **`zero` = 275 is architectural, not a keep failure.** It is a genuine
   32-input reduction over `y`, and each `y[k]` pulls in ten op results. **No
   amount of cutting at op results can help a reduction that sits downstream of
   all of them.** It needs its own boundary — see below.
2. **The eight `y[k]` are the keep failure**, the same pathology the read path
   showed: all eight full-width op-result vectors survive **32/32 bits**, and
   synthesis still **routed around them** for those bits. *(`r_slt`/`r_sltu` show
   1 of 32 bits, and that is CORRECT — bits 31:1 are constant zero and were
   folded. Not a defect; I checked before counting it as one.)*

⇒ **Third block, third time: `keep` preserves the net and not the dependency.**
R2's carry chain (wholly re-derived), the read path (one bit routed around), the
ALU (eight). **The failure rate rises with the design's freedom to re-associate.**

## ✅ Structural emission + four cut families ⇒ max 20, 100 %

| component | max cone | provenance |
|---|---|---|
| add/sub, per-slice carry cuts | **3** | MEASURED — `adder8s`, the C3 probe |
| shifts, tree cuts | **11** | MEASURED — `readtree`; a barrel shifter is the *same* 32:1-select shape as a register read |
| bitwise AND/OR/XOR | **2** | trivial |
| op-select mux (one-hot) | **20** | MEASURED — `alutail` |
| `zero` reduction, tree cuts | **8** | MEASURED — `alutail` |

`alutail` (the 10:1 op select + the zero tree, emitted structurally) measured
**69 cones, median 20, MAX 20, 100 % ≤ 24** when cut at **both** `y` and the
zero-tree groups. Cutting only at the zero groups leaves **90** — because `y`
itself must be a boundary. **`y` is both the ALU's result and the input to
`zero`, so it is exactly the sort of net that has to be named.**

## 🆕 The finding the regfile did not produce: FLAGS NEED THEIR OWN TREE

`zero` is a **32-input reduction**, and every status flag has that shape — zero,
overflow, parity, any "is the whole word …" predicate. **A reduction sits
downstream of every bit of the result, so it can never be fixed by cutting
upstream.** It needs a boundary at the result **and** a tree through the
reduction itself.

⇒ **Add a fifth obligation to the C3 emitter list: name the result vector, and
emit wide reductions as trees with named levels.** Neither the read path nor the
writeback path needed this, so it would not have been discovered from them.

## ⚠️ Headroom: 20 of 24 is tight, and one design choice buys 6 bits back

The op-select mux at **20** is the ALU's worst cone, and it is 20 because I
emitted a **one-hot** select: 10 sources + 10 select lines. An **encoded** 4-bit
select gives **10 + 4 = 14**. ⇒ **Encode the op select.** Six bits of headroom
for free, and the ALU stops being the block that sits closest to the ceiling.

## What this adds to the C3 picture

| block | needs structural emission? | worst cone treated |
|---|---|---|
| writeback | **no** — 6 in plain RTL | 6 |
| register read | **yes** | 11 |
| **ALU** | **yes** | **20**, or 14 with an encoded select |

**Two of the three datapath blocks require option (A), and both for the same
reason: they SELECT across a wide operand set, which is what `keep` cannot
protect.** The writeback path enables rather than selects, and needs nothing.
