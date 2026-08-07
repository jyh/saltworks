# THE FABRICATED NETLIST'S CELLS — census, specification, and the rule that keeps the check honest

### 2026-08-06, SILICON. Measured on `tt_submission/tt_um_saltworks_banyan.v`
### from the green HEAD run `31140274735` — **the artifact TinyTapeout will
### fabricate**, not a local proxy. Liberty read from the **hardening** PDK
### revision `8afc8346…`, which is the one that builds those bytes.

## Why this file exists

The seam doctrine says the equivalence proof must target TT's CI netlist. That
netlist existed for the first time tonight. Pointing the importer at it:

```
importer: no expansion for cell 'inv_2' (instance _170_) — add it to EXPAND and to Sky130.lean
```

## The census

**36 distinct cell types — 32 logic, 4 physical — against our 13 trusted models.
Overlap: ZERO.** That zero is misleading and should not be quoted alone. Split by
*function* rather than by name:

| | types | instances |
|---|---|---|
| same function, different **drive strength** — `and2_2`, `dfxtp_2`, `nand2_2` | 3 | 67 / 327 |
| **genuinely new functions** | 27 | 260 / 327 |

Our models are the `_1` family; the CI flow chose `_2` drives almost throughout.
`nand2_2` is `nand2_1`'s function with a bigger transistor — **an alias, not a
proof.**

⇒ **The trusted cell-model set must grow 13 → ~40 to cover what gets fabricated.**
This quantifies the evidence seat's 12:44 finding on our own artifact: *the
trusted model set grows with FLATTENING, not with design size.* The design did not
grow — 327 logic cells — the flow simply reached for three times as many types.

## ⛔ THE RULE THAT KEEPS THE CHECK HONEST — READ BEFORE WRITING ANY MODEL

**Write each model BY HAND from what the cell name means. Do NOT generate it from
the liberty functions below.**

Every model owes a `decide +kernel` theorem that it agrees with the vendor liberty
function. **If the model is generated from that same liberty, the theorem compares
a value with itself and proves nothing** — a green audit over a vacuous check,
which is precisely the failure this campaign spent 2026-08-06 cataloguing. The
liberty column is the **specification to be met**, and it earns its keep only
because something independent is checked against it.

## The specification — liberty `function` / `next_state`, verbatim

| cell | liberty function |
|---|---|
| `or2_2` | `(A) \| (B)` |
| `nor2_2` | `(!A&!B)` |
| `and2_2` | `(A&B)` |
| `and3_2` | `(A&B&C)` |
| `nand2_2` | `(!A) \| (!B)` |
| `nand3_2` | `(!A) \| (!B) \| (!C)` |
| `inv_2` | `(!A)` |
| `and2b_2` | `(!A_N&B)` |
| `and3b_2` | `(!A_N&B&C)` |
| `and4bb_2` | `(!A_N&!B_N&C&D)` |
| `nand2b_2` | `(A_N) \| (!B)` |
| `nand3b_2` | `(A_N) \| (!B) \| (!C)` |
| `nor3b_2` | `(!A&!B&C_N)` |
| `or3b_2` | `(A) \| (B) \| (!C_N)` |
| `a21o_2` | `(A1&A2) \| (B1)` |
| `a21oi_2` | `(!A1&!B1) \| (!A2&!B1)` |
| `a21boi_2` | `(!A1&B1_N) \| (!A2&B1_N)` |
| `a31o_2` | `(A1&A2&A3) \| (B1)` |
| `a32o_2` | `(A1&A2&A3) \| (B1&B2)` |
| `a211o_2` | `(A1&A2) \| (B1) \| (C1)` |
| `a211oi_2` | `(!A1&!B1&!C1) \| (!A2&!B1&!C1)` |
| `o21a_2` | `(A1&B1) \| (A2&B1)` |
| `o21ai_2` | `(!A1&!A2) \| (!B1)` |
| `o211a_2` | `(A1&B1&C1) \| (A2&B1&C1)` |
| `dfxtp_2` | `next_state=D`, `function=IQ` |
| `buf_2`, `clkbuf_2`, `clkbuf_4`, `clkbuf_16` | `(A)` |
| `dlygate4sd3_1`, `clkdlybuf4s25_1` | `(A)` |
| `conb_1` | `function=1` (HI) and `function=0` (LO) — two outputs |

## ⚠️ Three that are not one-liners just because their function is trivial

- **`dlygate4sd3_1` (24 instances)** and **`clkdlybuf4s25_1` (18)** are
  **hold-fixing delay cells**. Their *logic* is identity; their *presence* is a
  timing artifact the flow inserted. A trivial model for a delay buffer is
  trivially correct — **and that should be stated in the model's docstring rather
  than left for a reader to assume**, because "identity" is a claim about the
  logical view only and says nothing about why 42 of them are on the die.
- **`conb_1` (12)** is a **tie cell with TWO outputs**, `HI = 1` and `LO = 0`. It
  is the only cell here that is not a function of its inputs, and the existing
  model shape (`def f (args) : Bool`) does not fit it without thought.

## Then what

Import, then per-cone equivalence — **which is possible at all only because
ruling 4a closed YES tonight**: with `(* keep *)` surviving TT's CI and the census
cut at the stage boundaries, every cone in the fabricated netlist is **≤ 21
inputs**, three bits inside the measured 24-bit kernel ceiling.
