# ORGAN REFERENCE — for silicon's Slice-A 5-op RTL cut

**Seat:** COMPILER · **2026-08-08 ~19:1x** · **Order:** maestro 19:12 front ②,
*"COMPILER supports with the organ reference and the ISA semantics surface"*

**Every width below is `#eval` on the real `Circ`, not a number from a document.**
Port counts taken from prose are a guess; these are readings of the artifact
(`ScratchORGANREF.lean`). The ISA semantics surface is
`docs/compiler-inventory-0808.md` §Q3 and is not repeated here.

---

## 1. THE WIDTHS — `(nIn, gates, outs)`, measured

| organ | nIn | gates | outs | where |
|---|---:|---:|---:|---|
| `adder32` | 65 | 160 | 33 | `Adder.lean:97` |
| `bitXor32` | 64 | 32 | 32 | `Bitwise.lean:68` |
| `bitAnd32` | 64 | 32 | 32 | `Bitwise.lean` |
| `bitNot32` | 32 | 32 | 32 | `Bitwise.lean` |
| `sltCirc` | **3** | 5 | 32 | `Bitwise.lean:193` |
| `sltuCirc` | **1** | 2 | 32 | `Bitwise.lean` |
| `sliceASelect` | 98 | 291 | 32 | `SelectCut32.lean:75` |
| `ruledEnc` | 3 | **0** | 2 | `EncoderE1.lean:244` |
| `decoder` | 32 | 102 | 6 | `Decoder.lean:170` |
| `zeroTree` | 32 | 31 | 1 | `AluSelect.lean:206` |

**Slice-A organ gate sum** (add + xor + slt + select + enc + decoder + zeroTree) =
**621**. ⚠️ *That is a GATE SUM, not an area estimate and not a cell count — it prices
nothing about the register file, the wiring, or the flow. Silicon owns the CELLS
number; this is a floor to sanity-check it against.*

---

## 2. ⛔ THE THREE THINGS THAT WILL BITE AN RTL AUTHOR

### (a) `sltCirc` IS NOT A STANDALONE COMPARATOR. `SLT` is a THREE-ORGAN CHAIN.

```
def sltCirc : Circ := { nIn := 3, … }
  /-- Inputs: `a31`, `b31`, `s31` (the subtraction's sign bit). -/
```
**Its three inputs are bit 31 of `a`, bit 31 of `b`, and bit 31 of `a − b`.** The third
comes from a SUBTRACTION, which this corpus performs as `a + ~b + 1` through the real
adder. So:
```
SLT rd rs1 rs2   ⇒   bitNot32(rs2) → adder32(rs1, ~rs2, cin=1) → sltCirc(a31, b31, s31)
                     THREE organs, wired in that order.
```
⇒ ***Instantiating `sltCirc` alone gives a 3-input block with no indication where the
inputs come from. `sltCirc_correct_on_sample` certifies the block, NOT the chain —
and the certificate's own docstring says it drives the sample "through `adder32`
ITSELF rather than through a hand-derived carry", which is the reason to trust it and
also the reason it presumes the chain.***
📌 `sltuCirc` is worse: **nIn = 1**, its single input being the subtraction's
**carry-out** (`adder32` output 32). Not in Slice A's ruled set, listed so nobody
reaches for it.

### (b) BOTH COMPARATORS BROADCAST — 32 outputs, ONE meaningful bit.

`sltCirc.outs = 6 :: List.replicate 31 7`, where net 7 is `const false`. **So outputs
1…31 are a shared constant-zero net, by construction.** That matches the ISA
(`rd := if rs1 <ₛ rs2 then 1 else 0`) and it means an RTL cut must NOT synthesise 32
independent comparator outputs — it is one bit and 31 ties to ground.

### (c) `ruledEnc` HAS **ZERO GATES**. It is pure wiring.

`nIn = 3, gates = 0, outs = 2`, and `ruledEnc_cert (env) : sem ruledEnc env =
[env lineXOR, env lineSLT] := rfl`. ⇒ ***The instruction encoder at the ruled pair costs
NOTHING — it is two wires from the decoder's class lines to the select's two select
nets.*** *EncoderE1 landed this as "zero gates, zero cells", and its own file warns that
a zero-gate block is invisible to every structural instrument, so the CERT is the only
thing that can catch a mis-wiring. For RTL: do not emit a module; emit the two nets.*

---

## 3. THE CERTIFICATE EACH ORGAN CARRIES — what an RTL cut is allowed to claim

| organ | the theorem to cite | what it says, and its LIMIT |
|---|---|---|
| `adder32` | `adder32_adds_on_sample`, `adder32_carry_out_on_sample` | **SAMPLED**, not ∀-input. `adder32_outs_len = 33` is total. |
| `bitXor32` | `bitXor32_correct_on_sample` + `_ssa` / `_wf` | sampled against `(· ^^^ ·)`; structure is total |
| `sltCirc` | `sltCirc_correct_on_sample` + `_ssa` / `_wf` | sampled, driven through the REAL adder; **certifies the block, not the chain** |
| `sliceASelect` | `sliceASelect_cert` | ⭐ **UNCONDITIONAL, ∀ Env** — the strongest certificate in the set |
| | `sliceASelect_selects` | **GUARDED** on `gsSelOf 3 2 E < 3` |
| `ruledEnc` | `ruledEnc_cert` | `rfl`, exact, ∀ env |
| `decoder` | `decoder_correct` (`Program.lean:7487`) | ⭐ **UNCONDITIONAL**, `∀ w, ctrlOf w = ctrlSpec w` |
| | `decoder_wf` | total |

⚠️ **SO THE HONEST SUMMARY OF CERTIFICATE STRENGTH, because an RTL datasheet will want
to overstate it: `sliceASelect` and `decoder` are UNCONDITIONAL; the adder, the bitwise
blocks and the comparators are SAMPLED.** *"Certified organs" is true and does not mean
"∀-input verified" for all of them. `docs/LEDGER.md` is the flags-style record.*

## 4. ⛔ WHAT SILICON MUST NOT TAKE FROM THIS

1. **The 5-op ISA has no shifts, no memory, no jumps** — `sll`/`sra` have NO producer
   in the corpus and are outside Slice A. Do not leave holes for them in the top module
   expecting a block to arrive.
2. **`select = 3` is REACHABLE and defined.** At `(3,2)` the two select bits encode a
   value the three sources do not have; `sliceASelect_at_select_three` proves the block
   emits **32 proved zeros** there. It is not "don't care" and it is not undefined. The
   seam obligation — that the decoder never drives `select = 3` — is **UNPROVED in this
   corpus** (`SelectCut32.lean` §"AND THAT SEAM OBLIGATION IS CURRENTLY UNPROVED"), and
   at the ruled pair it corresponds to a one-hot violation on the class lines.
3. **There is no assembled `core`** — see `docs/compiler-inventory-0808.md` §Q1. The RTL
   cut is being built from organs whose JOIN has no theorem yet. That is a known and
   stated position, not an oversight, but the datasheet must not imply a verified core.

🟢 *Ask for anything missing. The ISA surface, the four backend-targetable layers and the
`x0`-write caveat are in the inventory; this file is only the organs and their widths.*
