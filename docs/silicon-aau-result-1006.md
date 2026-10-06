# AAU — the fabricated core refines "RV32I with erratum E": PROVED (W1–W4); W5 owed

silicon, 2026-10-06. Desk AAU, council 2026-10-06 ruling 4 (ii). The statement was read by kent
before the proof (bus, 10:17: the five hard points agree with the RTL; one wording note, taken).
It is in [silicon-aau-statement-1006.md](silicon-aau-statement-1006.md). Seat-days used: about 1.3
of the 9 cap.

## Verdict, with its limits beside it

| claim | status | how it is checked | limits |
|---|---|---|---|
| **`core32bus_refinesE : RefinesE core32bus`** | **PROVED, Lean kernel** | `SaltWorks/Silicon/Refine/Main.lean`; `#print axioms` = `propext, Classical.choice, Quot.sound` | `core32bus` is the Lean transcription; the row below ties it to the RTL |
| **the transcription IS the fabricated RTL** | **PROVED, ABC (SAT)** | `Formal/refine_link/run_link.sh`: transition + pin functions equal, over all state, inputs and the gold's `x` bits; UNSAT in 1.8 s | trusted: yosys's reading of the Verilog, the printer's per-constructor meaning (table in `Emit.lean`), ABC |
| control: the link sees the erratum | **REFUSED as it must be** | the same run, model with SRA/SRAI as `ashr`: SAT in 1.8 s | — |
| control: freed bits | **closes** | 1,126 state + 10 input + 64 `regs[0]` read-leaf bits, and nothing else | `regs` is `[1:31]`; the leaf is `x` and muxed away by `rs == 0` |
| control: the theorem separates E from RV32I | **PROVED, Lean kernel** | `core32bus_not_refinesRV32I` (ADDI; SRAI) | — |
| reset convention = the RTL's | **PROVED, Lean kernel** | `reset_edge`: any `rst_n`-low edge lands in `core32bus.reset _` | — |
| W2: the spec against a third party | **0 mismatches / 8,000** | `Formal/refine_w2/run_w2.sh` vs riscv-formal `insns/*.v` at c992aa6 | random vectors are EVIDENCE, not proof; 343 are the declared misaligned-LW/SW scope |
| W2 control | **moves only where E differs** | the same vectors under `exec true`: 181 disagree, only in LW and the funct3=5 shifts | — |
| **W5: RTL ↔ signed-off netlist** | **NOT DONE** | — | the theorem reaches the RTL, not yet the die |

## What the theorem says

Take the composed core at `01e19f7`, one edge after reset, with any register file. Drive it with
any host byte stream on `ui_in`, with `sof` low. Then, as long as the first `k` instructions are in
scope:

- every `(uo_out, uio_out[1:0])` pair up to the end of instruction `k` is the one `runSpec true`
  predicts;
- `pc` and `x0..x31` match at that point.

The spec is RV32I with exactly three changes: SRA and SRAI shift logically, and LW returns the
previous load loop's word. Scope, as stated before the proof: `sof` low; the 31 RV32I instructions
other than FENCE/ECALL/EBREAK and the sub-word memory operations; no misaligned control transfer
or LW/SW. The claim ends at the first instruction out of scope.

## How the proof is built (all kernel-checked, no `bv_decide`, no `native_decide`)

`Loop.lean` (phases 0–2) · `Step.lean` (FETCH phase 3, all 29 non-memory instructions, one proof
over `decode`'s 31-way split) · `Mem.lean` (LW/SW decode inversion; LOAD and STORE phase 3; pins per
loop kind) · `Run.lean` (byte assembly equals `hostWord`; the boundary invariant; pins per cycle) ·
`Inst.lean` (one instruction, each class) · `Main.lean` (induction on `k`; the controls).

## Reproduce

`../saltbuild.sh SaltWorks.Silicon.Refine.Main` · `OUT=<scratch> sh SaltWorks/Silicon/Formal/refine_link/run_link.sh`
· `OUT=<scratch> sh SaltWorks/Silicon/Formal/refine_w2/run_w2.sh`. The last two need the tape-out
clone (`TTDIR`) and riscv-formal at c992aa6 (`RVF`).

## What this does NOT claim

Anything with `sof` pulsing, behaviour on out-of-scope instructions, the fabric/MAC complex, timing,
or analogue behaviour. Nothing about the netlist or the die until W5. W2 is a differential test, so
it is evidence about the spec's text, not a proof of it.

## Two process corrections, recorded where the result lives

- The first SAT link used `equiv_simple -seq 5` and then `equiv_induct`. Neither finished in 25
  minutes on this design; I killed both by pid and retired their registry rows. The method that
  finished cuts the flops open and gives ABC one combinational miter, which proves the same
  transition-function equality.
- My first W2 vectors gave `x0` a nonzero value, and riscv-formal (correctly, under its RVFI
  contract) used it. That produced 271 false mismatches, which were the bench's, not the spec's.
  Fixed by the RVFI convention (x0 reads 0; one register, one value). The run and the control above
  are the corrected ones.
