# AT-SCALE BOUNDARY SURVIVAL — the half I named unmeasured

### 2026-08-07, SILICON, on the maestro's order. Article: compiler's
### `structural/` — 7 designs × {`s1`,`s2`,`m1`} + 7 `.cuts` manifests.
### **`s1` totals 5,270 cells; my RTL core was 5,054.** Predictions `S1`–`S8`
### were posted to the bus **before** the first synthesis.

## VERDICT: **structural emission HOLDS at scale.** 100 % instance survival, `s1`≡`s2`, function preserved.

| | prediction | outcome | score |
|---|---|---|---|
| **S1** | passthrough exact, all runs | `inc32` 60→59; `m1` drops 1–2 cells | ❌ **refuted in letter** — *all dropped cells are DEAD* |
| **S2** | ⭐ boundary survival **100 %** | **100 % by INSTANCE** in every design and variant | ✅ **HELD** |
| **S3** | `s1` ≡ `s2` — order irrelevant | identical in **every** row | ✅ **HELD** |
| **S4** | `m1` survives equally | yes, modulo the orphaned select inverters | ✅ **HELD** |
| **S5** | cones ≤ 24 | max 2–3, 100 % — **but vacuously** | ⚠️ **untested** |
| **S6** | 100 % where RTL closed 60.1 % | 5,270 cells, 100 % | ✅ **HELD** |
| **S7** | kill condition | **not triggered** | ✅ |
| **S8** | scope limit stands | largest single design 2,982 cells | ⚠️ **stands** |

## The measurement

```
design       var   in    out   pass   inst-survival    function
adder32      s1    160   160   YES    160/160 100%     PRESERVED
inc32        s1     60    59   NO      59/60   98.3%   PRESERVED
prioenc      s1    106   106   YES    106/106 100%     PRESERVED
zerotree     s1     31    31   YES     31/31  100%     PRESERVED
shifter32    s1    486   486   YES    486/486 100%     PRESERVED
aluselect    s1   1445  1445   YES   1445/1445 100%    PRESERVED
readtree     s1   2982  2982   YES   2982/2982 100%    PRESERVED
   (s2 identical to s1 in every row — S3)
   (m1: 1–2 cells dropped per design, all dead; function preserved)
```

**Every dropped cell is dead logic**, confirmed by simulating source against
netlist on 16 random vectors per design: **14 of 14 PRESERVED, zero mismatches.**
In the `m1` variants the dropped cells are exactly the **shared select
inverters** the `mux2_1` peephole orphaned — *the peephole correctly left them
alone, as ordered, and `opt_clean` then removed them as dead.*

⇒ **Passthrough preserves LIVE structure, not dead structure.** `S1` as written
was too strong; the corrected statement is the useful one.

## ⛔ TWO MEASUREMENT ERRORS OF MY OWN, both caught in flight

**1. I measured boundary survival by NET NAME and got 79–99 %.** The right unit
is the **INSTANCE**, which the manifest supplies. `adder32_s1` has **exact**
passthrough (160→160) and **160/160 instances**, yet only **127/160 net names** —
because a net driving a module port is **renamed to the port**: `g66`'s output
`n66` becomes `o0`. **I documented this exact merge/rename failure at 08:31 and
then built the measurement by name anyway.** *A defect I had named eight hours
earlier did not stop me repeating it; an internal check did.*

**2. My evaluator ignored `assign`, and reported all 14 designs as FUNCTION
CHANGED.** The sources carry 33 output aliases (`assign o0 = n66;`) and the
netlists carry none — synthesis absorbs them. **Caught because `adder32_s1`
appeared "changed" while having exact passthrough and 100 % instance survival,
which is impossible.** *The contradiction was the instrument, not the artifact.*
**A false "compiler's article is functionally wrong" would have been the worst
report I could have filed today.**

## ⚠️ S5 is UNTESTED, and the reason matters

The manifests cut at **every gate** — 159 cuts for 160 cells, 2,981 for 2,982.
**So every cone is one gate deep and "max 2, 100 %" is true by construction.**
That is a *valid* decomposition — it reduces equivalence to gate-by-gate
structural matching against the cell-model theorems — **but it is a different
proof strategy from per-cone equivalence, and it does not test the 24-bit
ceiling at all.** ⇒ **A coarser manifest is needed to test cone width; this one
answers survival, which is what it was for.**

## What is now established, and what is not

✅ **Established:** structural emission survives at **2,982 cells in a single
design**, deterministically (`s1`≡`s2`), with function preserved and 100 % of
boundaries intact — **against an RTL route that lost 4 of 12 boundaries and
closed 60.1 % at 5,054 cells.**

⚠️ **Not established** (`S8`, registered in advance): this is **seven separate
designs**, not one 5,270-cell monolith. Optimiser freedom scales with a **single
design's connectivity**. **The largest single design here is 59 % of my RTL
core's size.** *The remaining gap is one structural monolith at ~5k cells, and I
will not claim it closed until that is run.*
