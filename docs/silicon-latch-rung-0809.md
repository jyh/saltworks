# The memory ladder's MIDDLE RUNG — latch arrays, 2026-08-09

**The Captain's word (council, 09:0x):** *"let's probe the latch-ram, so we have a
good ladder."* Three regimes on one axis:

```
flops (dmem8/16/32)  ->  LATCH ARRAY (this doc)  ->  SRAM macro (scouted below)
```

## ⛔ FIRST, THE NUMBER I ALMOST PUBLISHED — AND WHY IT WAS GARBAGE

The flow reported `lmem8` at **1,236 µm²** against `dmem8`'s **10,484 µm²**.
That reads as an **8.5× win**. It is an artifact.

```
   422 cells
   256   $_DLATCH_PN0_          <- GENERIC. Never mapped to a PDK cell.
   Area for cell type $_DLATCH_PN0_ is unknown!
   Chip area for module '\lmem8': 1236.185600
     of which used for sequential elements: 0.000000 (0.00%)
```

🔑 ***THE TELL: A MEMORY REPORTED AS 0.00% SEQUENTIAL.*** *A memory that is 0%
sequential is impossible — the storage is the point of the object. The reported
area counted the decode/mux logic and silently omitted every storage cell.*

**ROOT CAUSE, measured not guessed:** `dfflibmap` maps **flip-flops only** — its
own help text says *"Map internal flip-flop cells to the flip-flop cells in the
technology library."* The 256 `$_DLATCH_PN0_` cells pass through it untouched.
⇒ **This flow cannot price an INFERRED latch.** Confirmed by running
`read_verilog; synth; dfflibmap -liberty …; stat` directly: the latches survive.

## ✅ THE PRICE, TAKEN FROM THE LIBERTY — WITH THE METHOD VALIDATED FIRST

Before trusting cell-area arithmetic for a cell the flow could not synthesize, it
was checked against a number measured independently by the ordinary flow:

```
dmem8's MEASURED sequential area   6,406 µm² ÷ 256 flops = 25.023 µm²/flop
liberty `sky130_fd_sc_hd__dfrtp_1`                       = 25.024 µm²   ← EXACT
⇒ the method reproduces a measured figure, so it is trusted for `dlrtp_1`.
```

**STORAGE ARRAY ONLY** — `dfrtp_1` vs `dlrtp_1`, both *with* reset, so the only
variable is the storage element:

| words | bits | flop µm² | latch µm² | saving | ratio |
|---:|---:|---:|---:|---:|---:|
| 8 | 256 | 6,406 | 4,164 | 2,242 | 0.650 |
| 16 | 512 | 12,812 | 8,328 | 4,484 | 0.650 |
| 32 | 1024 | 25,625 | 16,656 | 8,969 | 0.650 |

**Per bit: 25.0240 → 16.2656 µm² = 35.0% smaller**, flat across all three sizes.

⚠️ **NOT CLAIMED: the COMBINATIONAL half.** *The decode/read-mux logic was
synthesized with the latches unmapped, which changes what `abc` optimises around.
`lmem`'s combinational figure is therefore NOT comparable to `dmem`'s, and the two
must not appear in one column — the same unlike-regimes rule that separates flop
memory from an SRAM macro.*

## PATH TO A FULL FIGURE

**Instantiate the library cells explicitly** (`sky130_fd_sc_hd__dlrtp_1`) instead
of inferring latches — which is what real DFFRAM does. Bounded RTL change; makes
the design PDK-specific, as DFFRAM already is.

## THE TOP RUNG, for the ladder's completeness

`[V-SRC, tinytapeout-dossier.md:400-402]` — *"Latches are ALLOWED (TT documents
latch-based memory as an area win)"* and *"hardened macros are ALLOWED on sky130
(DFFRAM `RAM32`, 401×136 µm, fits 3x2)."* **Both upper rungs are sanctioned.**

⛔ **But "fits 3x2" means the macro fits a 3×2 ALONE.** Against measured geometry:

```
3×2 core (MEASURED 101,535 µm²)   RAM32 54,536  remainder 46,999  stdcells need 96.5%  ⛔
4×2 core (est. 136,237 µm²)       RAM32 54,536  remainder 81,701  stdcells need 55.5%  ✅
```
⇒ **The SRAM rung costs a TILE UPGRADE, not just a design change.** *(4×2 core
estimated from the 3×2's measured core/die ratio — `[INF]` until a run confirms.)*

## REPRODUCING

```sh
sh SaltWorks/Silicon/Flow/synth.sh lmem8      # and lmem16, lmem32
```
⚠️ **`lmem*_stat.txt` and `lmem*_nl.v` are deliberately NOT committed**: their
`Chip area` line is the void figure above, and a generated artifact carrying a
number this misleading should not sit in the tree where it can be quoted. They
regenerate from the command above in under a second.
