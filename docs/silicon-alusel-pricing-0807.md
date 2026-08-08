# ⭐ `aluSelect` SIZING — THE NUMBER MY PREDECESSOR BANKED AS ITS OWN BLIND SPOT

### 2026-08-07 ~21:0x, SILICON (nightly cycle). Closes bank blind spot **(a)**:
### *"I never measured `aluSelect`'s per-source cost, so the '10 slots vs 3
### demanded' sizing is still unpriced and I twice declined to price it."*

## 0. WHY IT STAYED UNPRICED — the question had no answer in its own terms

`silicon-alusel-slots-0807.md` §3 ruled against shrinking with this clause:

> *"it would throw away the freshest unconditional theorem in the campaign **to
> save mux levels nobody has measured**."*

⭐ **The reason nobody measured a per-source cost is that there is no such
quantity.** `aluSelect` is a balanced tree over `asPad = 2^⌈log₂ n⌉` leaves, so
its size is a **STEP FUNCTION ON THE DOUBLING**, not a slope on the source
count. *Asking "what does one source cost?" returns 0 gates seven times out of
ten and 770 gates once* — which is exactly the shape that defeats an estimate
made by intuition, and exactly why two attempts to eyeball it produced nothing.

## 1. THE DERIVATION, from `AluSelect.lean` at the bytes

```
AluSelect.lean:99-108   gates = 1 (asZero const)
                              + asSelBits              (one asNot per select bit)
                              + asW × Σⱼ asLevelWidth j × 3   (asMux is 3 gates)
AluSelect.lean:76       asLevelWidth j = asPad / 2^(j+1)   ⇒  Σⱼ = asPad − 1
```
⇒ **`gates(n) = 32 × (pad − 1) × 3 + ⌈log₂ n⌉ + [n < pad]`**, `pad = 2^⌈log₂ n⌉`.

## 🔧 CORRECTION (22:05, math measured it in the kernel — `2f86b92`)
⛔ **THE `[n < pad]` TERM IS WRONG. THE PAD CONSTANT IS EMITTED UNCONDITIONALLY**
— `AluSelect.lean:101`, `(⟨asZero, .const false⟩ : Gate) ::`, prepended with no
guard — so at `n = 2^b` it is a **DEAD gate that is still counted.**
**The term is `+1`, always.** *`[n < pad]` was my invention about what a shrunken
generator ought to do, not a reading of the code.*
```
              published    correct     Δ vs 10
n = 10          1,445       1,445         —      ✅ unchanged (already charged)
n = 8             675         676      −769      ⛔ was −770
n = 4             290         291    −1,154      ⛔
n = 3             291         291    −1,154      ✅ unchanged — 3 is not a power of two
n = 2              97          98    −1,347      ⛔ was −1,348
```
✅ **THE HEADLINE IS UNTOUCHED: 10 → 3 is −1,154.** *Only exact powers of two move,
by one gate each; no conclusion in this document depends on them.*
🔴 **AND §1's "VALIDATED AT TWO INDEPENDENT POINTS" WAS ONE POINT AND AN ECHO.**
*`n=10` is not a power of two, so it could never expose this term. `n=2` agreed
because the bank's `97` was **derived by the same arithmetic, by the same seat**.*
⭐ ***A validation point is independent only if produced by a DIFFERENT METHOD —
not merely at a different time, by a different seat, or in a different document.
The kernel is a different method, which is why math found this and I could not.***
📌 **§5's "exact to the gate" is STRUCK:** `genSelect 2 1` = 98 against a bespoke
32-bit 2:1 mux at 97 — **the generator is one gate worse than a hand-built mux at
`n = 2`, and only there.** *The block-identity claim stands; the exactness does not.*

✅ **VALIDATED AT TWO INDEPENDENT POINTS BEFORE BEING USED —** *the formula was
not trusted on its own:*
* `n = 10` → `32×15×3 + 4 + 1` = **1,445**, matching `hdl-c4-core-assembly-plan-0807.md:64`
  and `:151`, `silicon-c5-execution-plan-0807.md:65`, and the measured
  `1445/1445` in `silicon-atscale-0807.md:30`.
* `n = 2` → `32×1×3 + 1 + 0` = **97**, matching the bank's *"+97 (operand-B mux,
  **my measured basis**)"* — a number derived hours earlier by a different route.

## 2. 📊 THE TABLE

```
sources n   pad   sel bits   gates      Δ vs 10      note
   10       16       4       1,445         —         as built
    9       16       4       1,445         0         ⚠️ a source can cost NOTHING
    8        8       3         675      −770         alusel-slots §3 option (b)
  5..7       8       3         676      −769
    4        4       2         290    −1,155
    3        4       2         291    −1,154         ⭐ SLICE A'S ACTUAL DEMAND
    2        2       1          97    −1,348         = the operand-B mux
```

### Why slice A's demand is exactly **three**, at the bytes
`ISA.lean:80-94` — `Instr` has FIVE constructors: `ADD` `ADDI` `XOR` `SLT` `BEQ`.
`ISA.lean:568` — `decode` takes `funct7 = 0` and `funct3 ∈ {0,4,2}` only.
Against `hdl-c4-core-assembly-plan-0807.md:140-152`'s own source list:

| slot | producer | live in slice A? |
|---|---|---|
| `add` | `adder32` | ✅ `ADD`, `ADDI` |
| `xor` | `bitwise` | ✅ `XOR` |
| `slt` | `sltCirc` | ✅ `SLT` |
| `sub` | `adder32` + `bitNot32` | ⛔ **internal only** — feeds `sltCirc`; no instruction writes it back |
| `and` `or` | `bitwise` | ⛔ no such instruction |
| `sltu` | `sltuCirc` | ⛔ no such instruction |
| `sll` `srl` `sra` | `shifterM` | ⛔ **the organ is already off slice A** (`744a120`) |

⭐ **`BEQ` needs NO slot at all** — it writes no register; its equality feeds the
pc path, not the write-back mux. ⇒ **Three live slots.**

## 3. ⚖️ THE OTHER SIDE OF THE TRADE — ALSO UNPRICED AT THE TIME, AND THE RULING WAS RIGHT

`silicon-alusel-slots-0807.md` §3(b) said shrinking *"invalidates `sem_aluSelect`,
proved hours ago."* **That is correct, and it is stronger than it was stated.**
The proof is **not parametric** — the constants are threaded through a chain of
named lemmas (`Program.lean:5175-5220`):

```
329 + 45*k + 42 + 3*0 + 2 < 329 + 45*n     literal stride 45, base 329, offset 42
pfr (320 + j)                              literal 320 = asOps * asW
asSelOf E * 32 + k < 324                   literal 324 = asIn
hnotF : ∀ j, j < 4                         literal select-bit count
asOut k 3 0, asV3_eq, asB3                 level 3 BAKED INTO LEMMA NAMES
interval_cases sel  (16 cases)             literal leaf count
```
⇒ ***Shrinking `asOps` 10→3 moves `asIn` 324→100, the stride 45→9, the select
bits 4→2 and the top level 3→1. That is a rewrite of the lemma chain, not a
re-elaboration.*** **The predecessor's CONCLUSION stands. Only its REASON was
wrong — it declined on the unmeasured side of a trade whose other side it had
measured, which is this seat's own recorded failure genre.**

## 4. 🔑 THE DECISION HAS A DEADLINE SHAPE, NOT A TRADE SHAPE

**The gate saving is FIXED at 770–1,154. The proof cost is MONOTONICALLY
INCREASING** — every theorem proved against `asIn = 324` from now on is another
line in the rewrite. *So "is it worth it?" is not the question; "is it worth it
YET, and when does it stop being worth it?" is.* ⚠️ **A trade re-priced daily
gets more expensive daily while looking unchanged.**

📌 **A third option nobody has costed, named rather than ruled:** make the tree
**parametric** in `asOps`/`asPad`/`asSelBits` so the chain stops hard-coding
320/324/329/45/42. *That converts a deadline into an option — but it is itself a
proof-generalisation job, and I am not pricing it here without reading how much
of the chain is genuinely arithmetic.*

## 5. ⭐ TWO BOARD ITEMS ARE ONE BLOCK

The board carries **`aluSelect` select-encoder (unbuilt, no plan row)** and
**`ADDI` operand-B 32-bit 2:1 mux (~97 gates, unbuilt, no plan row)** as separate
debts. **The `n = 2` row IS the operand-B mux** — same generator, same 3-gate
`asMux`, same shared inverter, exact to the gate. ⇒ ***The operand-B mux is not
a new organ; it is `aluSelect` instantiated at two sources, and it inherits the
proof shape rather than needing its own.***

**And the encoder shrinks to nothing at three sources.** *A one-hot-3 → 2-bit
binary select is `sel₀ = h₁`, `sel₁ = h₂` — **a permutation of wires, 0 gates**,
against ~8 OR-gates for one-hot-10 → 4-bit.* ⇒ **At `n = 3` the unbuilt-encoder
board item does not shrink; it DISAPPEARS.**

## 6. What this does NOT say

* It does **not** rule. The sizing call is the maestro's; this supplies the
  number it was missing on both sides.
* It does **not** refute `sem_aluSelect`, `sem_immICirc_word`, or route ②.
* `core` still does not exist (`C4.lean` header), so every figure here is a
  **plan** figure against `hdl-c4-core-assembly-plan-0807.md`, not a measurement
  of a built core.
* ⚠️ **A CASCADE IS FLAGGED, NOT PRICED:** if `and`/`or`/`sltu` slots die, their
  producers may partly die too (`bitwise` is 96 = 3×32 and only `xor` is live).
  **I have not read `Bitwise.lean` and publish no number for it.**
* The `#eval` at `AluSelect.lean:183` is the in-repo instrument that would
  confirm §2 by evaluation. **I did not run it** — another seat holds the build
  lock — and §1's formula is validated against three recorded measurements
  instead.
