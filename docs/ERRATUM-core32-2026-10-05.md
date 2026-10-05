# ERRATUM — the fabricated RISC-V core (`core32`), 2026-10-05

**Part:** `tt_um_saltworks_ndf_c32` on the Tiny Tapeout shuttle TTSKY26c. The same erratum is in
the chip's own datasheet (`docs/info.md` in
[`jyh/tt-neural-dataflow-fabric`](https://github.com/jyh/tt-neural-dataflow-fabric)); the text
below is lifted from it so the two cannot drift, with only the closing pointer adapted.

*Added after submission. It describes the fabricated design (commit `01e19f7`, the shuttle
slot's `commit_id`) and changes nothing in it.*

**The RISC-V core on this chip was not verified by the method the SaltWorks project describes.**
Lean proves a 7-instruction model of the core, but no theorem relates that model to the
fabricated design, and no instruction-conformance suite was run before tapeout. The first
conformance run, on 2026-10-04, after submission, found **3 of 31 in-scope instructions failing
on the signed-off netlist: SRA, SRAI and LW.** The other 28 conform: 26 pass their own tests
in the standard `riscv-tests` suite (`rv32ui`), and `LUI` and `SW` fail theirs only through an
`SRA` and an `LW` inside the test, passing once those two paths alone are corrected. The
fabricated RTL and the signed-off gate-level netlist agree cycle for cycle on every test.

*In scope* means RV32I without the sub-word loads and stores (`LB LBU LH LHU SB SH`, outside
this core's word-only bus by design) and without `FENCE`, `ECALL`, `EBREAK` and the CSR
instructions, which this core does not implement. Code for this chip must not use any of them.

| instruction | what the chip does | cause, in the fabricated source |
|---|---|---|
| `SRA` | shifts in **zeros** (a logical shift): `-16 >> 2` gives `0x3ffffffc`, not `0xfffffffc` | `src/core32.v` line 106: `$signed(rf1) >>> b_op[4:0]` sits in a `?:` chain whose other results are unsigned, so Verilog evaluates the whole expression unsigned and `>>>` becomes a logical shift |
| `SRAI` | the same | `src/core32.v` line 80: an immediate-form operation takes its ALU code from `funct3` alone and drops instruction bit 30, so `SRAI` decodes as `SRLI` — a second, separate cause; line 106 would also make it logical |
| `LW` | writes `rd` with the word read by the **previous** `LW` (`0x00000000` for the first `LW` after reset) | `src/busadapt8.v`: the loaded word is captured into `rdata_r` (line 230) on the same clock edge at which `src/core32.v` writes `rd` from it (line 260 connects the two). The fetch path has a bypass for exactly this timing (`c_instr`, line 257); the load path does not |

**Software workarounds — measured on the fabricated RTL and the signed-off netlist.**

```
# SRA rd, x, n    s and t are scratch registers, distinct from each other and from x and n
srli s, x, 31     # 1 if x is negative, else 0
sub  s, x0, s     # all ones if x is negative, else 0
xor  t, x, s      # x itself, or ~x if x is negative (either way non-negative)
srl  t, t, n      # a logical shift of a non-negative value is the arithmetic shift
xor  rd, t, s     # undo the complement
# SRAI rd, x, k: the same, with  srli t, t, k  in the fourth line

# LW rd, off(rs1): issue it twice, with rd != rs1 and no other load between the two
lw   rd, off(rs1) # rd receives the PREVIOUS load's word; this load's word is captured
lw   rd, off(rs1) # rd receives the word captured by the first
```

Every instruction in the `SRA` sequence is one that conforms. Measured at the pins: 15 of 15
workaround results are correct on the fabricated RTL and on the signed-off netlist (functional
sky130 cell models, unit delay); the same program on a corrected core gives identical results;
and a variant with a single `LW` stores `0x00000000`, so the measurement can fail. A store
between the two `LW`s was measured and is harmless; by the source, only a load replaces the
captured word. Simulation samples operands and is not a proof. A C compiler emits `SRA`/`SRAI`
for right shifts of signed values and `LW` for every word load, and we know of no compiler
option that avoids them, so compiled code for this core must be rewritten after compilation.

The conformance record is [`silicon-step0-core32-conformance-1004.md`](silicon-step0-core32-conformance-1004.md);
the workaround measurement is its section (D). Both reproduce from hash-verified objects:
`OUT=<scratch> sh SaltWorks/Silicon/Sim/conformance/run_step0.sh`.
