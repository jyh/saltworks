# AAJ — the FABRICATED core32 + busadapt8, checked FORMALLY at the bus level

silicon, 2026-10-05 (desk AAJ; council 2026-10-05, ruling 2 (ii): *"yes, we need to do the formal check —
after all, the salt method was supposed to prevent failures of this kind"*). **Status: NOT PUBLIC.** This
file is on a local branch of saltworks. Whether it reaches a public surface is council's (AAK's route).

## Verdict, with its limits beside it

| item | verdict | the limit that rides with it |
|---|---|---|
| **riscv-formal, 31 in-scope RV32I instructions, bus level** | **FAIL on exactly three: SRA, SRAI, LW.** PASS on the other 28. | Bounded: the checked retirement sits at cycle 24 (6 bus loops after reset), re-run at cycle 48 (§ Deep run). All operand values and all register states are covered; only canonical encodings are checked (riscv-formal decodes the full word). |
| consistency checks | **PASS**: reg · pc_fwd · pc_bwd · causal · unique · liveness | Same bounds (riscv-formal windows: trigger at cycle 8, check at 24; liveness 8 → 32). |
| **LW, by its exact SHAPE** | **PROVED, UNBOUNDED (k-induction):** every LW (rd ≠ x0) writes the word the host returned on the pins in the **previous** load loop, or 0 if there was none since reset. | Same scope assumptions as below. The proof needs five helper invariants that tie the host's pin view to the adapter's registers; each is itself proved in the same run. |
| non-vacuity | **every PASS is REACHED** in cover mode under its own assumptions (34/34 on the fabricated core; 37/37 on the control). | The vacuity instrument has its own control: a check moved to a cycle with no retirement reads UNREACHED. |
| control | step 0's `ctl_all` patches (both shift fixes plus a load bypass), through the identical harness: **37/37 PASS**. On that core the LW-shape assertion FAILS (bmc and prove). | The patches are controls, not proposed design changes. |

**So LW is settled formally, both ways round.** riscv-formal shows it is not RV32I (`insn_lw`, which fails only
on `rd_wdata`). The shape proof shows what it is instead, for traces of any length. On a core with the load
bypass, both results flip.

## What the solver produced (decoded from its counterexamples; `cex.py`)

| check | the retirement | RV32I requires | the chip |
|---|---|---|---|
| `insn_lw` | the first load after reset: `lw x4, 2004(x1)` at pc `0ff8`, address `c3ffffe8`; the host returns `80000000` on the pins | x4 = `80000000` | x4 = `00000000` (`rdata_r`'s reset value: the "previous load" when there was none) |
| `insn_sra` | `sra x1, x16, x20` with x16 = `c0015f4a`, x20 = 31 | `ffffffff` | `00000001` |
| `insn_srai` | `srai x1, x20, 10` with x20 = `c1ff8000` | `fff07fe0` | `00307fe0` |

## The bench (`SaltWorks/Silicon/Formal/rvfi_bus/`)

- **DUT:** `plane32bus` = `core32` + `busadapt8` at `jyh/tt-neural-dataflow-fabric @ 01e19f7`, read by
  `git show` and hash-checked (core32 `e8a91801`, busadapt8 `c06e10a3`, plane32bus `d13825ee`). At the chip
  top these ports ARE the pins: `ui_in → instr_byte`, `uo_out ← addr_byte`, and `uio_out[1:0] ← phase_o`,
  which is output-enabled (`uio_oe = 8'b1011_0011`).
- **What comes from where.** Everything the BUS carries is read at the pins by a host model in
  `wrapper.sv`: `rvfi_insn`, `rvfi_pc_rdata`, `rvfi_mem_addr/rdata/wdata`. The host keeps its own phase
  counter, as the datasheet says a host does. The register file and the next pc are on no pin, so they
  come from read-only TAPS (`tap.py`). The host is unconstrained: `ui_in` is an arbitrary byte every
  cycle. A protocol assertion (`uio_out[1:0]` = the phase number at phases 1–3) runs in every check.
- **The taps changed nothing, and that is proved, not argued.** Open-source yosys cannot read a
  hierarchical reference (measured: `u.inner` is silently declared as a new wire), so `tap.py` adds output
  ports that read existing nets. `run_aaj.sh` proves the tapped plane equivalent to the fabricated plane on
  every original output (yosys `equiv_simple -seq 5` + `equiv_induct`: 2,251 of 2,251 cells proven). A
  one-edit mutant of the core fails the same script (1 unproven, rc 1).
- **Tools:** yosys 0.68 (the box's, unchanged) · SymbiYosys v0.68 from source (Homebrew's `sby` is 0.69 and
  depends on Homebrew's yosys, so installing it risked moving the box's shared yosys) · bitwuzla 0.9.1 · yices2 2.7.0 · riscv-formal `c992aa6`.
- **Reproduce:** `OUT=<scratch> sh run_aaj.sh` (≈1 min) · `DUT=ctl_all` for the control ·
  `CFG=checks-deep.cfg TAG=deep` for the deep run · `sh vac.sh <core dir> <out>` for non-vacuity ·
  `sh lw_shape.sh <OUT>/tap <out>` for the LW shape (bmc · prove · cover · mutant).

## Scope — the assumptions, each stated where a reader of the verdict meets it

1. **`sof` is held low.** A realign truncates the loop in flight (datasheet). Its interaction with
   retirement is outside this check, as it was outside step 0.
2. **The trace before the checked retirement is trap-free.** core32 has no traps. RV32I traps on a
   misaligned jump target (and, under `RISCV_FORMAL_ALIGNED_MEM`, on a misaligned LW/SW); core32 runs on
   with a misaligned pc. The wrapper drives `rvfi_trap` exactly when the core's own next pc, or the pins'
   memory address, is misaligned. For the checked retirement riscv-formal still compares `spec_trap ==
   trap`, so a core that misaligns where RV32I does not (or the reverse) still FAILS. **What is not checked
   is the register and memory effect of a retirement RV32I says must trap**, nor anything after one.
3. **Out of scope by design:** `LB LBU LH LHU SB SH` (word-only bus), `FENCE`, `ECALL`, `EBREAK`, CSRs, and
   illegal encodings (core32 decodes and retires them as something; no `ill` check was run).
4. **Bounded, except the LW shape.** See the depths above. The register file is unconstrained at reset, so
   the bound limits the HISTORY, not the operand values.
5. **What links this to silicon.** This is the fabricated RTL. Its link to the die is the signoff flow (LVS)
   and step 0's gate-level simulation, which agreed with the RTL cycle for cycle on every rv32ui test. No
   formal equivalence between the RTL and the signed-off netlist was run here.

## Deep run (insn checks at cycle 48)

Re-run from the committed bench (`CFG=checks-deep.cfg TAG=deep`): every insn check at **cycle 48** (12 bus loops),
consistency windows 8 → 48, liveness 8 → 56. **Same verdict: FAIL insn_lw · insn_sra · insn_srai; PASS the other 34.**
Non-vacuity: **34/34 REACHED** (`vac.sh`). Doubling the history changed nothing.

**Every figure in this file was reproduced from the committed bench (saltworks `cd180b4f`)** after the bench was
final: fab 3 FAIL / 34 PASS (taps 2,251/2,251 proven) · ctl_all 37/37 PASS (taps 2,283/2,283) · vac 34/34 and
37/37 REACHED · LW shape: bmc PASS, prove PASS (k-induction), cover REACHED, mutant FAIL on the fab; on ctl_all,
bmc and prove FAIL on `shape`.

## The salt-method remedy — PRICED, not started

*Asked: the price of a Lean theorem that relates the fabricated core to the instruction semantics.*

**What exists.** `SaltWorks/HDL/ISA.lean` is the corpus's own instruction subset, not RV32I. Its link to
RISC-V is 120 Spike witness vectors: evidence, not proof (`Certs/EndToEnd.lean`, "RV32I IS NOT WHAT IS
PROVED"). `CorePlace` builds a gate-level `Circ` core from proved organs, and no theorem relates it to
`core32.v`. The house method for netlists (`Silicon/Equiv/`) is kernel `decide` over flop-boundary cones,
with a **24-input cone ceiling**; `bv_decide` is **banned** from shipped proofs (it adds a per-theorem
native axiom).

**Why the gate-level route is not the price.** A 32-bit core's datapath cones are far past 24 inputs (an
adder's top bit sees 64, a barrel-shifter bit 37, a comparator 64). Every such cone would need slicing in the
style of `AdderSlice`/`Columns`. That is weeks of work with high risk, and it is not recommended.

**The route that fits the house rules: word-level Lean, linked to the netlist by SAT.**

| step | what | seat-days |
|---|---|---|
| W1 | Lean model of `core32` + `busadapt8` at word level, transcribed from the RTL; its Verilog re-emitted and proved equivalent to the fabricated RTL by yosys SAT (today's tap-equivalence harness) | 1 |
| W2 | a Lean RV32I spec for the 31 in-scope instructions (word memory, no traps), checked against Spike vectors (the `SpikeVectors` infrastructure) and against this run's riscv-formal models | 1–1.5 |
| W3 | the bus protocol in Lean (the host's loop view) and the adapter invariants, by induction on cycles (today's five LW-shape invariants are the template) | 1–2 |
| W4 | the theorem: from reset, with `sof` low, every retirement refines **RV32I-with-erratum-E** (SRA/SRAI logical, LW = the previous load's word), with the 28 conforming instructions as plain RV32I. Kernel-checked BitVec reasoning, no `bv_decide` | 2–3 |
| W5 | RTL ↔ signed-off netlist equivalence (SAT, outside the kernel) to close the gap to the die | 0.5–1 |
| | **total** | **≈ 6–9 seat-days** (≈ 2 calendar weeks for one seat under the current budget) |

**Trusted base, stated:** the Lean kernel; yosys SAT for W1 and W5 (the same class of link the MAC cells
use); LVS for netlist → GDS. **The risk is concentrated in W2** (a spec written by the party being checked).
That is why W2 is cross-checked two independent ways, Spike and riscv-formal's own models.
**It would not change the chip.** Its value is a theorem stating precisely what the fabricated core does,
erratum included, which is what the public record now says in prose.

## What this does NOT claim

- Anything with `sof` pulsing, anything after a trap-requiring retirement, illegal encodings, or sub-word
  memory.
- Anything about the fabric or MAC complex, timing, or analogue behaviour.
- That the deep run's bound is a proof for all lengths. Only the LW shape is unbounded.
