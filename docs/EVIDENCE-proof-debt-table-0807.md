# THE PROOF-DEBT TABLE — proven-about vs merely-built, over the library closure

**Duty:** the maestro's 16:0x order — *"run it and post the payoff… C4's honesty
baseline, a muster centrepiece, and the input for tomorrow's proof-debt queue."*

⏱️ **Measured at 16:1x, against the tree as it is** — **not** the 15:53 run.
`c55e6db` landed at 16:07 and closed two of that run's headline names, so the earlier
table was invalidated by its own effect. **Every number below is post-`c55e6db`.**

⚠️ **Instrument status: NOT LANDED.** `ScratchEVIDENCEDEPS.lean` is gitignored scratch,
held back because `MERELY-BUILT` cannot yet separate `deriving` instances from
hand-written `instGates`/`instOuts` by name. The run is reproducible; the tool is not
committed. **The `MERELY-BUILT` total carries that residue; the two certified classes
do not.**

---

## §1 The census

| class | count |
|---|---:|
| PROVEN-ABOUT | **518** |
| UNCERTIFIED-IN-DEFAULT-BUILD (literal) | **0** |
| MERELY-BUILT | **106** |
| — of which behaviourally certified (B-PROVEN) | 429 |
| — **B-UNCERTIFIED** | **1** |
| — B-NONE | 194 |

## §2 THE `adder32` CLASS — now a single member

| def | declared | in-closure behavioural certs | behavioural certs OUT of build |
|---|---|---:|---|
| **`bnComps`** | `HDL/BatcherNet.lean` | **0** | **4**, in `HDL/BatcherNetC.lean`: `bnC_rotation_routes`, `bnC_concentrates_actives`, `bnC_identity_is_fixed`, `bnC_sorts_reversed_input` |

⭐ **`adder32` LEFT THIS CLASS AT 16:07.** It now carries `adder32_adds` and
`adder32_carry_out` in `Adder.lean` — in the closure — alongside `adder32_ssa`/`_wf`.
**`inc32` left `MERELY-BUILT` in the same commit** (`inc32_adds_four`).

⇒ ***The class is one import from empty. `BatcherNetC` is the whole remaining
membership, and the four theorems saying the sorter sorts are the cost.***

## §3 THE PROOF-DEBT QUEUE — 106 definitions no theorem anywhere mentions

Ranked, which is the order to work it:

| module | count | note |
|---|---:|---|
| `HDL.PriorityEnc` | **20** | the whole block, `priorityEnc` and every helper |
| `HDL.EmitS` | **15** | the emitter — `#eval`-checked only |
| `HDL.AluSelect` | 11 | helpers; `aluSelect` itself is B-PROVEN |
| `HDL.Syntax` | 9 | |
| `Stack.Spec` | 8 | |
| `HDL.CodegenSpec` | 7 | |
| `Silicon.Imported.FabricCut` | 6 | imported netlist shape defs |
| `Silicon.Imported.Fabric` | 5 | |
| `HDL.EmitV` | 4 | the Verilog emitter |
| `Tactic.AuditAxioms` · `Stack.Perm` · `HDL.Shifter` · `HDL.Adder` | 3 each | |
| `Stack.ZeroOne` · `Silicon.Equiv.BitSliced` | 2 each | |
| `HDL.Seq` · `ReadTree` · `ISA` · `C4` · `BatcherNet` | 1 each | |

📌 **`PriorityEnc` (20) and `EmitS` (15) are a third of the debt between them, and
both are `#eval`-checked-only files.**

## §4 STRUCTURAL-ONLY — 88 certified, but nothing says what they compute

| module | count |
|---|---:|
| `Silicon.Cells.Sky130` | **54** — ⚠️ **instrument artefact**, see below |
| `HDL.BatcherNet` | **15** |
| `HDL.SpikeVectors` | 3 |
| `Syntax` · `StateCodec` · `C4` | 2 each |
| 8 further modules | 1 each |

⚠️ **The 54 Sky130 cells are a FALSE POSITIVE of the behavioural axis**, which is a
24-name heuristic (`sem`, `run*`, `step*`, `eval*`). A cell's certificate
(`and3 A B C = (A && B && C)`) *is* behavioural, but its semantics is direct `Bool`
algebra with no named evaluator. **Subtract them: the real structural-only count is
~34, and `HDL.BatcherNet`'s 15 are then the largest genuine block.**

---

## What this says for C4

**Four tiers, and only the first is an import problem:**

| tier | population | cure |
|---|---|---|
| ① behavioural cert exists, out of build | **`bnComps`** | **an import** |
| ② certified structurally only | ~34 real (+15 in `BatcherNet`) | a proof |
| ③ no theorem at all | **106** | a proof |
| ④ on every instruction's path | *(was `inc32` — CLOSED 16:07)* | — |

⇒ ***The import sweep closes tier ① and nothing else. Tiers ②③ are ~140 definitions
that no import will reach, and that is the honest size of the proof debt.***

⭐ **AND THE DAY'S RESULT IN ONE LINE: the census was published at 15:53 and by 16:07
two of its four headline names were closed by the seat that owned them.** *The table
above is what remains after the fleet read the first one.* **A measurement that moves
its own subject is the only kind worth posting at a muster.**
