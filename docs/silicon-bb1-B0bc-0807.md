# BB-1 · B0(b)+(c) — the seam, composition-checked, and the area, measured

### 2026-08-07, SILICON, probe grade. `K1`–`K7` pre-registered before the check.
### **B0(b): does the composed-switch statement match the LANDED banyan
### theorem's ACTUAL hypotheses? B0(c): area and pins.**

## B0(b) — KB1: the seam MATCHES, at the price of four things, one unforeseen

All composition-check statements **elaborate** (`saltbuild EXIT=0`). ✅ `K4`.

### 🆕 THE FINDING I DID NOT PREDICT: the seam module has NO sortedness predicate

`List.Sorted` **is not in scope** in `FabricRoutes.lean` — the leg is
deliberately **Mathlib-free**, and the decomposition lemmas were chosen as core
(`List.all_append`, `List.take_append_drop`) to keep it that way. **So the
"sortedness form" is not Perm-vs-Sorted-vs-concentrated at all: sortedness is
IMPLICIT IN THE CONSTRUCTION of `allScenarios`** (a `filter` over `testBit`) and
**is never stated as a predicate anywhere.**

⇒ **Any bridge lemma must either import Mathlib into the Mathlib-free leg — a
real cost the addendum does not price — or define a Mathlib-free predicate.** I
used a local `incr : List Nat → Bool` to state it at all.

### The three bridges, each verified to be statable and non-free (`K1` ✅)

| | what it needs | status |
|---|---|---|
| **(i) membership** | sorter output ≡ a member of the 255 | ✅ `decide`: all 255 are strictly increasing, non-empty, `< 8`; `length = 255` |
| **(ii) concentration** | active packets at `0…n-1` | ⚠️ **baked into `scenario`, NOT a hypothesis** — the sorter must *produce* this shape, and an idle-sentinel convention (idle sorts last) is required |
| **(iii) payload permutation** | relate pre-sort packets to post-sort positions | ⚠️ `expected` indexes payload by **post-sort index** (`ds.idxOf? d`), verified by `rfl` |

### ⚠️ `K2` CONFIRMED — THE PAYLOAD UNIVERSALITY GAP, and it is not in the addendum

`payloadOf i = testBit (i+1)` — **a fixed function of POSITION.** `fabric_routes`
is therefore a **distinguishability** argument: distinct tags arrive on the right
wires. **It is not payload-universal.** ⇒ The composed claim *"every packet
arrives on the wire its address names"* is supported **only up to that tagging**,
and the composed theorem should say so or be strengthened to arbitrary payloads.

### ⚠️ `K3` CONFIRMED — the full-load case is discharged by the SORTER, not the fabric

`(List.range 8) ∈ allScenarios` ✅ and its `idxOf?` is the identity ✅ (both by
`decide`). At full load sortedness forces `dest = id`, **the banyan sits straight
and does nothing.** ⇒ **The composed switch's headline case — an arbitrary 8×8
permutation — is discharged by the BATCHER; the banyan is idle exactly there.**
*The claim is still true and still worth having; but "the full 1990 system claim"
should not be read as the banyan doing the work at full load.*

## B0(c) — area and pins, MEASURED rather than estimated

| | cells | µm² | |
|---|---|---|---|
| `bitserial_switch` (landed element) | 18 | **172.7** | |
| **`cmpex` (compare-exchange, built for this probe)** | **14** | **116.4** | **0.67× the switch** |
| banyan fabric (landed) | 271 | **2,143.3** | |
| Batcher = 19 × `cmpex` | — | **2,211.0** | |
| **composed total** | — | **4,354.3** | **2.03× the banyan** |

⚠️ **`K5`: right number, WRONG REASON.** I predicted the element would be
*heavier* than a switch and the ratio therefore above 1.6×. **The element is
LIGHTER (0.67×)** — it carries 2 state bits where the switch carries 4 — **but
there are 19 of them against 12**, so the total still lands at **2.03×**, inside
my predicted 2–2.5×. *The addendum's ~1.6× is low; 2.0× is the measured figure.*

✅ **`K7`: 4,354 µm² = 9.6 % of one 2×2 tile's usable area.** Fits very
comfortably — better than my "≈23 % even at 3×".
✅ **`K6`: pins UNCHANGED** — sort→route in series behind the same 8-in/8-out, by
construction.

## Probe verdict

**BB-1 is feasible on both counts checked.** The seam closes with **four**
obligations, not three — the fourth being **the Mathlib-free statability of
sortedness**, which no one had priced. The two substantive cautions are
`K2` (payload universality) and `K3` (full load is the sorter's case), and
**both are about what the composed theorem should CLAIM, not about whether it can
be built.**
