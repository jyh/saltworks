# CONE-WIDTH CENSUS — the number C4 needs

### 2026-08-07, SILICON, on the maestro's dispatch. Run on the **5,266-cell
### structural monolith**. `W1`–`W5` posted to the bus **before** the census.

## THE RESULT: **151 obligations, max cone 24, median 3**

⚠️ **Framing, stated before the run:** cutting at *every* gate — the manifests as
delivered — makes the census **definable but vacuous**: max 2–3 by construction
with 5,266 obligations. **The number C4 needs is the trade-off: how FEW cut
points suffice to keep every cone ≤ 24.** Measured by **greedy topological
cutting**. ⚠️ **Greedy, NOT minimal** — a minimum cut set is an optimisation
problem; **151 is an upper bound, and the true minimum may be lower.**

| | prediction | measured | |
|---|---|---|---|
| **W1** | no cuts ⇒ max > 1000 | **max 1061**, median 4 | ✅ |
| **W2** | 400–900 cuts (8–17 %) | **151 cuts (2.9 %)** | ❌ **far better** |
| **W3** | max 24, median ≤ 12 | max 24, **median 3** | ✅ |
| **W4** | density highest in the wide selects | **INVERTED — see below** | ❌ |
| **W5** | 1/6 – 1/10 of the every-gate count | **1 / 34.9** | ✅ **far better** |

## ⛔ W4 WAS NOT JUST WRONG — IT WAS EXACTLY BACKWARDS

I predicted cut density would be **highest** in `readtree`/`aluselect` (31-way and
10-way selects) and **lowest** in `adder32`/`inc32` (3-input carry slices).

```
inc32       37/59   = 62.7%   <- HIGHEST   (carry chain)
zerotree    11/31   = 35.5%                (reduction)
prioenc     17/107  = 15.9%                (priority chain)
adder32      5/157  =  3.2%
shifter32   13/487  =  2.7%
aluselect   36/1446 =  2.5%
readtree    32/2983 =  1.1%   <- LOWEST    (31-way select)
```

**The serial structures need the densest cutting; the wide selects need the
sparsest** — a 57× spread, in the opposite direction to my prediction.

**Why, and this is the transferable part.** Cone width accumulates with **DEPTH
along a serial chain**, not with the **fan-in of a select**:

* a **mux tree** is *shallow and wide*: it has one wide cone at its **output**,
  and every gate beneath it has a small cone. **Cut once per tree.**
* a **carry chain** is *deep and serial*: **every** successive bit accumulates
  all the bits below it, so cones grow at **every** position. **Cut constantly.**

⇒ **My per-block survey measured the WIDTH at each block's output (readtree 36,
adder 65) and I generalised that to cut DENSITY. They are different quantities,
and they rank the blocks in opposite orders.** *`readtree` has the widest cone in
the core and needs the fewest cuts in it.*

## What this gives C4

**A 5,266-cell design decomposes into 151 per-cone obligations, every one ≤ 24
inputs, median 3.** Against the every-gate manifest's 5,266, that is **1/35 the
obligations** — and against the untreated monolith's **max 1061**, it is the
difference between impossible and routine.

⚠️ **Caveats, unchanged:** the count is **greedy, not minimal**; the monolith's
end-to-end functional equivalence is **still** unestablished (my evaluator does
not traverse module hierarchy); and the cut points a **proof** would choose may
differ from the ones a greedy chooses — *these are widths that are ACHIEVABLE,
not widths that are FORCED.*
