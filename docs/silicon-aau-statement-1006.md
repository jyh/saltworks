# AAU — the STATEMENT, for a non-author read before any proof

silicon, 2026-10-06. Desk AAU, council 2026-10-06 ruling 4 (ii) (*"yes to both"*): a Lean theorem
that the fabricated core refines "RV32I with this erratum", linked to the netlist by SAT, capped at
9 seat-days. The desk row requires a non-author read of the statement before the proof. This is
that statement.

## The files

| file | what | state |
|---|---|---|
| `SaltWorks/Silicon/Refine/Statement.lean` | the spec (`decode`, `exec e`, `stepH`, `runSpec`), the implementation interface (`PinMachine`), and the propositions `RefinesE` and `RefinesRV32I` | builds; **no proof, no `sorry`, no axiom** |
| `SaltWorks/Silicon/Refine/StatementChecks.lean` | five kernel `decide` checks showing the spec is not vacuous and that each erratum is reached | builds; a mutant (SRAI's E value set to the arithmetic one) is REFUSED at line 38 |

`import owed:` neither module is in the `SaltWorks.lean` hub yet. Both build by module name through
`saltbuild.sh`.

## The claim, in words

Let `M` be the composed `core32` + `busadapt8` at `jyh/tt-neural-dataflow-fabric@01e19f7`, seen
from its pins. Start one clock edge after reset, with ANY register file. Drive it with ANY stream
of host bytes on `ui_in`, with `sof` held low. Whenever the first `k` instructions are in scope:

1. **the pins match.** In every cycle up to the end of instruction `k`, `(uo_out, uio_out[1:0])`
   equals the spec's prediction. That covers every fetch address, load and store address, store
   datum and loop type.
2. **the state matches.** At that cycle, `pc` and `x0..x31` agree with the spec.

The spec is `exec true`, which is RV32I with three changes, each marked `ERRATUM` in the source:
SRA and SRAI shift logically, and LW writes the word the host returned in the previous load loop
(0 if there was none since reset). `RefinesRV32I` is the same proposition with the flag false. The
core does not satisfy it, which is the point of the erratum.

## What the reader should check hardest

1. **Is "any host byte stream" the right quantifier?** The host has no protocol obligation in this
   statement. Every byte sequence is legal and the core must behave for all of them. I believe this
   is right for `sof` low: `busadapt8`'s loop sequencing does not depend on `ui_in`, except through
   the fetched instruction word.
2. **The in-scope boundary.** `decode` applies RV32I's full field checks. Out of scope: FENCE,
   ECALL, EBREAK, LB/LH/LBU/LHU/SB/SH, any illegal encoding, a taken jump or branch to a
   non-4-aligned target, and a misaligned LW/SW address. The claim ends at the first one. RV32I lets
   misaligned word accesses either trap or be handled; excluding them is a scope choice, not a
   reading of the ISA.
3. **The ghost `lastLoad`.** Only LW under `e = true` reads it, and every in-scope LW updates it. It
   models `busadapt8`'s `rdata_r`, which latches at phase 3 of every load loop and is reset to 0.
4. **The reset convention.** `reset r0` is the state one edge after `rst_n` low. The register file
   has no reset, so it is quantified. `pc`, the bus phase and `rdata_r` reset to 0.
5. **Mealy outputs.** `out` may depend on the current `ui_in`. The statement makes no assumption
   that the outputs are registered.

## What it does NOT claim

Anything with `sof` pulsing. What the core does on an out-of-scope instruction (the excluded loads
and stores are memory-inert by design; that is not stated here). Timing, the fabric or MAC complex,
and analogue behaviour.

## How it will be closed (the plan is in `silicon-aaj-bus-formal-1005.md`, "remedy")

* **W1** defines `core32bus : PinMachine` in Lean, transcribed from the RTL. Its re-emitted Verilog
  is proved equivalent to the fabricated RTL by yosys SAT, with `arch` tied to `pc_r` and `regs`.
* **W2** cross-checks `exec false` against Spike vectors and riscv-formal's instruction models. The
  spec is written by the party being checked, so this is where the risk sits.
* **W3/W4** prove `RefinesE core32bus` in the kernel, with no `bv_decide`.
* **W5** closes RTL ↔ signed-off netlist by SAT.

Trusted base: the Lean kernel, yosys SAT (W1, W5), and LVS (netlist → GDS).
