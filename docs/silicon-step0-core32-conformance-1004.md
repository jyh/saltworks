# STEP 0 — the FABRICATED core32 measured against RV32I

silicon, 2026-10-04 (helm route @75,145,900, the Captain's word 15:1x: *"we've made mistakes here before,
I'm not that confident we have a SRA/SRAI bug"*). **Status: NOT PUBLIC.** This file lives on a local branch
of saltworks and in the private seat record; whether any of it reaches a public surface is council's.

## Verdict, with its limits beside it

| item | verdict | limit that rides with it |
|---|---|---|
| **(A) SRA / SRAI** | **DEFECT CONFIRMED on the signed-off gate-level netlist.** Both return a LOGICAL shift: `-16 >>> 2` = `3ffffffc` (RV32I: `fffffffc`). | Functional sky130 cell models, unit delay, no SDF. The die is the GDS; the netlist is what signoff LVS matched it to. |
| (A) refinement | **Two independent defects, and SRAI carries both.** (1) OP-IMM `alu_op = {1'b0,funct3}` drops funct7[5], so SRAI decodes as SRLI. (2) `$signed(rf1) >>> …` sits inside a `?:` chain whose other arms are unsigned, so Verilog's context rules make it logical. Fix only (1): SRAI still logical. Fix only (2): SRA right, SRAI still logical. | Both proven by single-edit RTL controls through the identical bench, not by reading. |
| **NEW — LW** | **DEFECT on RTL and GL: LW writes the PREVIOUS load's word.** `busadapt8` captures the in-flight word into `rdata_r` at the load loop's phase-3 edge; `core32` writes `rd` from `rdata_r` at that same edge. Three loads of `11111111/22222222/33333333` give `00000000/11111111/22222222`. | Under the datasheet's own in-phase host (§7). No host protocol can repair it in general: the word written is always the one captured one load earlier. **Measured workaround: issue the LW twice; the second returns the right word** (if no other load intervenes). |
| **(B) rv32ui** | **27 PASS / 5 FAIL of 32 scored tests**, RTL and GL **identical, cycle for cycle**, on all 32 (and on the 9 excluded ones in a pre-runner pass). Per instruction (below): **28 of 31 in-scope instructions conform; SRA, SRAI, LW do not.** | Self-checking riscv-tests, not riscv-arch-test signatures (see Population). Simulation samples operands; it is not a proof. |
| (B) attribution | `lui` fails only because its test 3 uses SRA; `sw` fails only because its readback is a LW. Each passes when ONLY the guilty path is patched. | Attribution is by control, not by reading the test. |
| **(C) riscv-formal** | **PRICED, NOT RUN** (below). Core-level ≈ half a day and would NOT see the LW defect; plane-level ≈ 1–2 days and would. | Estimates, not measurements. |

## Window, tools, objects

- **DUT (RTL):** `jyh/tt-neural-dataflow-fabric @ 01e19f7` (the shuttle slot's `commit_id`), sources by `git show`, never a checkout. `core32.v` = blob `e8a91801` (verified by `git hash-object` in the runner), `busadapt8.v` = `c06e10a3`, `plane32bus.v` = `d13825ee`. Top `tt_um_saltworks_ndf_c32`.
- **DUT (GL):** gds run `34058427540` (headSha `01e19f7`, conclusion success), artifact `tt_submission`; `tt_um_saltworks_ndf_c32.v` sha256 `38a4686f264fe814…209c`, 5,418,922 B, powered netlist. Its `pdk.json`: LibreLane 3.0.5, sky130A `8afc8346…`; **the cell models used are that exact PDK version** (the runner refuses otherwise).
- **Tools:** Icarus Verilog 13.0 · riscv64-elf-gcc 16.1.0 (`-march=rv32i -mabi=ilp32`) · riscv-tests `bcffa2b` · Python 3 for the expected values. Yosys was NOT used for any GL reading here (the helm's earlier GL-like reading was a yosys `synth -flatten`; this one is the signed-off netlist).
- **Bench:** `SaltWorks/Silicon/Sim/conformance/tb_host.v` — one host for RTL and GL. **Results are read ONLY at the pins:** every result is a SW reassembled from `uo_out` over its address and data loops, typed by `uio_out[1:0]`. The host keeps its own phase counter and checks it against the pins at phases 1–3 (`phase_mismatch=0` on every run). Address: probes use pins only (image < 256 B, low address byte latched); rv32ui uses `+addrnet`, taking the full address from the keep-nets `pc_q`/`alu_y`, which survive by name in the GL netlist — that read chooses WHICH word is served and never touches a result.
- **Reproduce:** `OUT=<scratch> sh SaltWorks/Silicon/Sim/conformance/run_step0.sh` (≈60 s; fetches the artifact and riscv-tests if absent, verifies every object's hash first). The tables below are its output, pasted unedited.

## Population and the excluded set (declared before scoring)

- **Suite:** riscv-tests `rv32ui`, self-checking: each test compares against values its authors wrote, and reports through its own pass/fail store to `tohost`. Minimal env (`env/riscv_test.h`): no CSRs, traps or ECALL — core32 has none.
- **Why not riscv-arch-test:** its current head (`fa1debd`) is the generator framework; reference signatures come from running Sail through it, and the clone carries **0** `*.reference_output` files. Neither Sail nor Spike is on this box. Self-checking tests need no reference model, which is the reason they were chosen; it is also their limit (coverage is the authors' operand choice).
- **EXCLUDED, not scored:** `lb lbu lh lhu sb sh` and `ld_st st_ld ma_data` (sub-word: memory-inert by the 08-12 word-only ruling); `fence_i` (Zifencei, not RV32I base). FENCE / ECALL / EBREAK / CSR match no opcode and have no rv32ui test here. ⚠️ In simulation an inert load leaves `rd` unwritten and the regfile has no reset, so those tests X-propagate and TIME OUT; on silicon `rd` would hold an arbitrary old value. Either way they are outside the claim.

## Per-instruction verdict (31 in scope)

| instruction | verdict | evidence |
|---|---|---|
| ADD SUB AND OR XOR SLL SRL SLT SLTU | PASS | their rv32ui tests, RTL = GL |
| ADDI ANDI ORI XORI SLLI SRLI SLTI SLTIU | PASS | their rv32ui tests, RTL = GL |
| BEQ BNE BLT BGE BLTU BGEU · JAL JALR · AUIPC | PASS | their rv32ui tests, RTL = GL |
| LUI | PASS (attributed) | `lui` FAILS test 3 = `lui; sra`; PASSES whole under `ctl_shift`, which edits only the shifter |
| SW | PASS (attributed) | every probe store lands the right word at the right address at the pins; `sw` PASSES under `ctl_all`, whose only non-shift edit is the LOAD path |
| **SRA** | **FAIL** | rv32ui test 3; probe rows; GL = RTL |
| **SRAI** | **FAIL** | rv32ui test 3; probe rows; GL = RTL |
| **LW** | **FAIL** | rv32ui test 2; `lw_probe`; GL = RTL |

**Controls** (`patch_variants.py`, RTL only, each edit must match exactly once or it refuses): `ctl_imm` decode fix · `ctl_sra` signed-context fix · `ctl_shift` both · `ctl_all` both + a `c_dmem_rdata` bypass mirroring `c_instr`'s. **`ctl_all` passes every scored test, so the bench can say PASS for every row it says FAIL.** These are controls, not proposed design changes.

## Measured tables (run_step0.sh output, unedited)

### sra_probe  (pins-only; every value is a STORE reassembled from uo_out)
| row | RV32I expects | rtl | gl | ctl_imm | ctl_sra | ctl_shift | ctl_all |
|---|---|---|---|---|---|---|---|
| SRAI -16,2 | `fffffffc` | `3ffffffc` ❌ | `3ffffffc` ❌ | `3ffffffc` ❌ | `3ffffffc` ❌ | `fffffffc` ✅ | `fffffffc` ✅ |
| SRA  -16,2 | `fffffffc` | `3ffffffc` ❌ | `3ffffffc` ❌ | `3ffffffc` ❌ | `fffffffc` ✅ | `fffffffc` ✅ | `fffffffc` ✅ |
| SRLI -16,2 (ctl) | `3ffffffc` | `3ffffffc` ✅ | `3ffffffc` ✅ | `3ffffffc` ✅ | `3ffffffc` ✅ | `3ffffffc` ✅ | `3ffffffc` ✅ |
| SRL  -16,2 (ctl) | `3ffffffc` | `3ffffffc` ✅ | `3ffffffc` ✅ | `3ffffffc` ✅ | `3ffffffc` ✅ | `3ffffffc` ✅ | `3ffffffc` ✅ |
| SRAI 15,1 (ctl) | `00000007` | `00000007` ✅ | `00000007` ✅ | `00000007` ✅ | `00000007` ✅ | `00000007` ✅ | `00000007` ✅ |
| SRAI -16,31 | `ffffffff` | `00000001` ❌ | `00000001` ❌ | `00000001` ❌ | `00000001` ❌ | `ffffffff` ✅ | `ffffffff` ✅ |
| SRA  -16,31 | `ffffffff` | `00000001` ❌ | `00000001` ❌ | `00000001` ❌ | `ffffffff` ✅ | `ffffffff` ✅ | `ffffffff` ✅ |
| SRAI -16,0 (ctl) | `fffffff0` | `fffffff0` ✅ | `fffffff0` ✅ | `fffffff0` ✅ | `fffffff0` ✅ | `fffffff0` ✅ | `fffffff0` ✅ |
| SRAI 0x80000000,4 | `f8000000` | `08000000` ❌ | `08000000` ❌ | `08000000` ❌ | `08000000` ❌ | `f8000000` ✅ | `f8000000` ✅ |
| SUB 0-2 (ctl) | `fffffffe` | `fffffffe` ✅ | `fffffffe` ✅ | `fffffffe` ✅ | `fffffffe` ✅ | `fffffffe` ✅ | `fffffffe` ✅ |
| ADDI -1024 (ctl) | `fffffc00` | `fffffc00` ✅ | `fffffc00` ✅ | `fffffc00` ✅ | `fffffc00` ✅ | `fffffc00` ✅ | `fffffc00` ✅ |
| run | | halted=1 phase_mismatch=0 | halted=1 phase_mismatch=0 | halted=1 phase_mismatch=0 | halted=1 phase_mismatch=0 | halted=1 phase_mismatch=0 | halted=1 phase_mismatch=0 |

### lw_probe  (pins-only; every value is a STORE reassembled from uo_out)
| row | RV32I expects | rtl | gl | ctl_imm | ctl_sra | ctl_shift | ctl_all |
|---|---|---|---|---|---|---|---|
| LW dat[0] | `11111111` | `00000000` ❌ | `00000000` ❌ | `00000000` ❌ | `00000000` ❌ | `00000000` ❌ | `11111111` ✅ |
| LW dat[1] | `22222222` | `11111111` ❌ | `11111111` ❌ | `11111111` ❌ | `11111111` ❌ | `11111111` ❌ | `22222222` ✅ |
| LW dat[2] | `33333333` | `22222222` ❌ | `22222222` ❌ | `22222222` ❌ | `22222222` ❌ | `22222222` ❌ | `33333333` ✅ |
| LW dat[2] again | `33333333` | `33333333` ✅ | `33333333` ✅ | `33333333` ✅ | `33333333` ✅ | `33333333` ✅ | `33333333` ✅ |
| LW dat[0] | `11111111` | `33333333` ❌ | `33333333` ❌ | `33333333` ❌ | `33333333` ❌ | `33333333` ❌ | `11111111` ✅ |
| ADDI 77 (ctl) | `0000004d` | `0000004d` ✅ | `0000004d` ✅ | `0000004d` ✅ | `0000004d` ✅ | `0000004d` ✅ | `0000004d` ✅ |
| run | | halted=1 phase_mismatch=0 | halted=1 phase_mismatch=0 | halted=1 phase_mismatch=0 | halted=1 phase_mismatch=0 | halted=1 phase_mismatch=0 | halted=1 phase_mismatch=0 |

### rv32ui @ riscv-tests bcffa2b  (PASS = the test's own pass store reached tohost)
| test | fabricated RTL | signed-off GL | ctl_shift | ctl_all |
|---|---|---|---|---|
| add | PASS (1716 cyc) | PASS (1716 cyc) | PASS (1716 cyc) | PASS (1716 cyc) |
| addi | PASS (824 cyc) | PASS (824 cyc) | PASS (824 cyc) | PASS (824 cyc) |
| and | PASS (1796 cyc) | PASS (1796 cyc) | PASS (1796 cyc) | PASS (1796 cyc) |
| andi | PASS (648 cyc) | PASS (648 cyc) | PASS (648 cyc) | PASS (648 cyc) |
| auipc | PASS (92 cyc) | PASS (92 cyc) | PASS (92 cyc) | PASS (92 cyc) |
| beq | PASS (1020 cyc) | PASS (1020 cyc) | PASS (1020 cyc) | PASS (1020 cyc) |
| bge | PASS (1092 cyc) | PASS (1092 cyc) | PASS (1092 cyc) | PASS (1092 cyc) |
| bgeu | PASS (1192 cyc) | PASS (1192 cyc) | PASS (1192 cyc) | PASS (1192 cyc) |
| blt | PASS (1020 cyc) | PASS (1020 cyc) | PASS (1020 cyc) | PASS (1020 cyc) |
| bltu | PASS (1120 cyc) | PASS (1120 cyc) | PASS (1120 cyc) | PASS (1120 cyc) |
| bne | PASS (1020 cyc) | PASS (1020 cyc) | PASS (1020 cyc) | PASS (1020 cyc) |
| fence_i | EXCLUDED | EXCLUDED | | |
| jal | PASS (76 cyc) | PASS (76 cyc) | PASS (76 cyc) | PASS (76 cyc) |
| jalr | PASS (316 cyc) | PASS (316 cyc) | PASS (316 cyc) | PASS (316 cyc) |
| lb | EXCLUDED | EXCLUDED | | |
| lbu | EXCLUDED | EXCLUDED | | |
| ld_st | EXCLUDED | EXCLUDED | | |
| lh | EXCLUDED | EXCLUDED | | |
| lhu | EXCLUDED | EXCLUDED | | |
| lui | **FAIL test 3** | **FAIL test 3** | PASS (116 cyc) | PASS (116 cyc) |
| lw | **FAIL test 2** | **FAIL test 2** | **FAIL test 2** | PASS (988 cyc) |
| ma_data | EXCLUDED | EXCLUDED | | |
| or | PASS (1808 cyc) | PASS (1808 cyc) | PASS (1808 cyc) | PASS (1808 cyc) |
| ori | PASS (676 cyc) | PASS (676 cyc) | PASS (676 cyc) | PASS (676 cyc) |
| sb | EXCLUDED | EXCLUDED | | |
| sh | EXCLUDED | EXCLUDED | | |
| simple | PASS (20 cyc) | PASS (20 cyc) | PASS (20 cyc) | PASS (20 cyc) |
| sll | PASS (1828 cyc) | PASS (1828 cyc) | PASS (1828 cyc) | PASS (1828 cyc) |
| slli | PASS (820 cyc) | PASS (820 cyc) | PASS (820 cyc) | PASS (820 cyc) |
| slt | PASS (1692 cyc) | PASS (1692 cyc) | PASS (1692 cyc) | PASS (1692 cyc) |
| slti | PASS (804 cyc) | PASS (804 cyc) | PASS (804 cyc) | PASS (804 cyc) |
| sltiu | PASS (804 cyc) | PASS (804 cyc) | PASS (804 cyc) | PASS (804 cyc) |
| sltu | PASS (1692 cyc) | PASS (1692 cyc) | PASS (1692 cyc) | PASS (1692 cyc) |
| sra | **FAIL test 3** | **FAIL test 3** | PASS (1904 cyc) | PASS (1904 cyc) |
| srai | **FAIL test 3** | **FAIL test 3** | PASS (880 cyc) | PASS (880 cyc) |
| srl | PASS (1880 cyc) | PASS (1880 cyc) | PASS (1880 cyc) | PASS (1880 cyc) |
| srli | PASS (856 cyc) | PASS (856 cyc) | PASS (856 cyc) | PASS (856 cyc) |
| st_ld | EXCLUDED | EXCLUDED | | |
| sub | PASS (1684 cyc) | PASS (1684 cyc) | PASS (1684 cyc) | PASS (1684 cyc) |
| sw | **FAIL test 2** | **FAIL test 2** | **FAIL test 2** | PASS (2180 cyc) |
| xor | PASS (1804 cyc) | PASS (1804 cyc) | PASS (1804 cyc) | PASS (1804 cyc) |
| xori | PASS (684 cyc) | PASS (684 cyc) | PASS (684 cyc) | PASS (684 cyc) |

## (D) The erratum's software workarounds — measured 2026-10-05 (desk AAL)

*Added the day after the verdict, for the chip datasheet's erratum. Same bench, same objects, same pins-only reading; `+addrnet` for the address because the program exceeds 256 B. Reproduced by section (D) of `run_step0.sh`.*

- **SRA / SRAI → five instructions, every one of them conforming** (SRLI, SUB, XOR, SRL/SRLI): `srli s,x,31 ; sub s,x0,s ; xor t,x,s ; srl t,t,n ; xor rd,t,s` (SRAI: `srli t,t,k` in the fourth slot). `s` and `t` must be distinct from each other and from `x` and `n`.
- **LW → issue it twice**, `rd ≠ rs1`, with no other LOAD between the two. By the RTL only a load loop writes `rdata_r` (busadapt8.v :230), so stores and other instructions may sit between them; a store between was MEASURED (row 3), the rest is read from the code.
- **Controls:** the same program on `ctl_all` (a corrected core) gives byte-identical stores, so the sequences are right on a conforming core too; and a MUTANT probe with the first pair reduced to a single LW stores `00000000` for that row on RTL, so this table can say ❌.
- **Limit:** simulation samples operands (15 rows); it is not a proof that the sequences hold for every input. The SRA identity itself (`x >>a n == ((x ^ s) >>l n) ^ s`, `s` = the sign mask) is standard and holds for all 32-bit `x` and `n` in 0..31.

### workaround_probe  (+addrnet for the address; every value is a STORE reassembled from uo_out)
| row | RV32I expects | rtl | gl | ctl_all |
|---|---|---|---|---|
| LW×2 dat[0], first load after reset | `11111111` | `11111111` ✅ | `11111111` ✅ | `11111111` ✅ |
| LW×2 dat[1] | `22222222` | `22222222` ✅ | `22222222` ✅ | `22222222` ✅ |
| LW×2 dat[2], a store between | `33333333` | `33333333` ✅ | `33333333` ✅ | `33333333` ✅ |
| LW×2 dat[0] again | `11111111` | `11111111` ✅ | `11111111` ✅ | `11111111` ✅ |
| SRA_W -16,2 | `fffffffc` | `fffffffc` ✅ | `fffffffc` ✅ | `fffffffc` ✅ |
| SRA_W -16,31 | `ffffffff` | `ffffffff` ✅ | `ffffffff` ✅ | `ffffffff` ✅ |
| SRA_W -16,0 | `fffffff0` | `fffffff0` ✅ | `fffffff0` ✅ | `fffffff0` ✅ |
| SRA_W 0x80000000,4 | `f8000000` | `f8000000` ✅ | `f8000000` ✅ | `f8000000` ✅ |
| SRA_W 15,1 | `00000007` | `00000007` ✅ | `00000007` ✅ | `00000007` ✅ |
| SRA_W 0x7fffffff,31 | `00000000` | `00000000` ✅ | `00000000` ✅ | `00000000` ✅ |
| SRAI_W -16,2 | `fffffffc` | `fffffffc` ✅ | `fffffffc` ✅ | `fffffffc` ✅ |
| SRAI_W -16,31 | `ffffffff` | `ffffffff` ✅ | `ffffffff` ✅ | `ffffffff` ✅ |
| SRAI_W 0x80000000,4 | `f8000000` | `f8000000` ✅ | `f8000000` ✅ | `f8000000` ✅ |
| SRAI_W 0x12345678,8 | `00123456` | `00123456` ✅ | `00123456` ✅ | `00123456` ✅ |
| SRAI_W 0x87654321,8 | `ff876543` | `ff876543` ✅ | `ff876543` ✅ | `ff876543` ✅ |
| run | | halted=1 phase_mismatch=0 | halted=1 phase_mismatch=0 | halted=1 phase_mismatch=0 |

## (C) riscv-formal — the price (not run)

- **Missing pieces:** core32 has no RVFI port; `sby` is ABSENT here (pip/source, minutes); `boolector`/`bitwuzla` ABSENT; `z3` and `yosys-smtbmc` present (z3 is the slow default).
- **Core level (core32 alone):** an `ifdef RISCV_FORMAL` RVFI block (~80 lines: `rvfi_valid = en`, insn, rs1/rs2, rd, pc, mem with full-word masks), a config with **the six sub-word checks excluded** (inert ≠ spec, by ruling — they would fail by design), `rvfi_trap = 0`. Single-cycle, so insn checks are shallow (depth ~2–3). **≈ 3–5 h seat time + ≈ 1–3 h compute on z3.** Would prove SRA/SRAI wrong for all operands (known) and the other 28 right **for all operands** — that, not the bugs, is its value. ⛔ **It would NOT see the LW defect:** at core level `dmem_rdata` is a same-cycle input; the defect lives in the adapter↔core coupling.
- **Plane level (plane32bus):** RVFI qualified by `retire`, memory data taken from the pins across the fetch+load loops; depth ~8–12. **≈ 1–2 days.** This is the level that catches the LW class.
- **Recommendation:** if council wants a formal statement for the paper, plane level is the one that would have caught what simulation of core32 alone missed.

## What this does NOT claim

- Nothing about the die's analogue behaviour, timing margins, or the fabric/MAC complex (not exercised; `sof` held low throughout).
- That no other defect exists: rv32ui samples operands; illegal encodings, reset behaviour beyond the first fetch, and `sof` interactions were not exercised here.
- Anything about the lab tree (`SaltWorks/Silicon/RTL`), which carries option (2) and was not fabricated. Its `tb_plane32bus_lwsw` 7/7 is consistent with the LW defect: that program loops, so every LW after the first returns the right word by repetition.

## The bench's own defect, caught before any verdict

The first host latched the phase-0 address byte at a NEGEDGE. After reset the first phase 0 is only the half-cycle between release and the first posedge, so the latch raced the release and served `X` for bytes 1–3 of the very first fetch — `x1` read as X and every shift result was X. Fixed by latching at the posedge that ends phase 0 (comment in `tb_host.v`). No verdict above was taken on the broken bench.
