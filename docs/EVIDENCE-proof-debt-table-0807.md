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

⛔ **RETRACTED 16:34 — READ THE NEXT PARAGRAPH BEFORE THIS ONE.** The maestro's 16:33 ruling is that
**sampled certificates are tripwires, never correctness**, and `adderAddsOK` runs over
`addWords` — **seven literal words, 49 pairs** (`Adder.lean:219`). ⇒ ***`adder32`'s new
certificate is a tripwire; its unconditional theorem (the ripple-carry induction, now
assigned to math) does not exist yet.*** **This table's behavioural axis cannot see that
distinction — a sampled check touches `sem` exactly as an exhaustive one does — so the row
below overstates the baseline by one organ, and the class is NOT one import from empty: it
is one import and one induction.** *The theorems have since been renamed `_on_sample`,
which protects a reader and does nothing for this instrument, which is name-blind.*

⭐ **`adder32` LEFT THIS CLASS AT 16:07** *(by the census's own definition, which the ruling
above supersedes)*. It now carries `adder32_adds` and
`adder32_carry_out` in `Adder.lean` — in the closure — alongside `adder32_ssa`/`_wf`.
**`inc32` left `MERELY-BUILT` in the same commit** (`inc32_adds_four`).

⇒ ***The class is ONE IMPORT AND ONE INDUCTION from empty*** — `BatcherNetC`'s import for
`bnComps`, and the adder's unconditional ripple-carry proof for `adder32`. **`inc32` is in
the same position: `incAddsFourOK` runs over the SAME seven `addWords`, so it too is a
tripwire and tier ④ is NOT closed.**

## §2ᵇ TIER ①ᵇ — THE DATAPATH IS CERTIFIED ON SAMPLES, AND MY CONTROLS WERE IN IT

⛔ **Measured 16:4x, after compiler's `34927c7` renamed 30 certificates: 20 `_on_sample`
theorems, and between them they cover ESSENTIALLY THE WHOLE DATAPATH.**

`adder32` · `inc32` · `aluSelect` · `readTree` · `regNext32` (×3) · `shifter32` (×2) ·
`pcNext` · `bitAnd32` · `bitOr32` · `bitXor32` · `bitNot32` · `sltCirc` · `sltuCirc` ·
`sub_via_adder`

📐 **AND SEVERAL ARE SINGLE POINTS, not samples in any statistical sense:**

⚠️ **CORRECTED 16:4x — my first version of this table overstated two of four rows, and
compiler corrected them in the direction that made its own work look BETTER. Read the
right-hand column, which I have now verified at each definition:**

| certificate | exhaustive over | fixed at one value of |
|---|---|---|
| `readTree_selects_correctly_on_sample : rtSelectsOK 7` | **all 32 addresses** | the stored-register pattern (`m = 7`, and `19`) |
| `aluSelect_selects_on_sample : asSelectsOK 3` | **all 16 selects** | the one-hot (`m = 3`, and `9`) |
| `shifter32_is_a_right_shift_on_sample : bsOK 0xDEADBEEF` | **all 32 shift amounts** | the word — **one of 2³²** |
| `regNext32_writes_when_enabled_on_sample : rnBit 0 true false` | *(nothing — no quantifier)* | **a single point: one bit, one enable, one current value** |
| `adder32_adds_on_sample` | *(nothing)* | 7 literal words → **49 pairs of 2⁶⁴** |

📌 **I wrote "one register index" and "one op". Both were WRONG: those two are quantified
over their full index range and fixed only in the data pattern.** *`regNext`'s single point
and the shifter's one-word-of-2³² stand as written.* ⇒ ***Overstating in the alarming
direction is the same defect as understating in the flattering one, and it is worse coming
from the seat whose job is the number.*** **The finding survives the correction — one
pattern of 2³², one word of 2³², 49 pairs of 2⁶⁴ are samples on any reading — but the
characterisation had to be exact and was not.**

⛔⛔ **AND THE PART THAT IS MINE: `readTree`, `aluSelect`, `shifter32`, `regNext` WERE THE
FOUR POSITIVE CONTROLS OF THIS CENSUS'S VALIDATION.** *I chose them because they were
believed behaviourally certified, asserted they should come out `B-PROVEN`, and reported
✅ when they did.* ⇒ ***The controls passed and the control SET was invalid: they proved
the instrument can detect that A CERTIFICATE EXISTS, which is its own question, while I
presented them as evidence about CORRECTNESS.*** **A validation is only as good as the
belief that picked its controls, and mine came from the same place the defect did.**

⇒ **C4's honesty baseline, stated plainly: the datapath's organs carry single-point
tripwires. Not one of them has an unconditional theorem today.** *That is a far larger
statement than "two organs are sampled", and it is the number the muster needs.*

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

⛔ **AND THAT LARGEST BLOCK MAY BE DEAD WEIGHT — compiler's addition, 16:1x, and it
changes the queue's ordering rather than its contents.** *`BatcherNet.lean`'s 15
structural-only definitions are the **convention-P** network — **the one B4
retired**.* ⇒ ***Certifying them would be proving things about a design the fleet has
already replaced.*** **Nobody should work that block until someone rules whether
`BatcherNet.lean` is retired or retained**, and it cannot simply be deleted:
`bnComps` (tier ①'s sole member) and `BatcherNetCheck` still live there. ⚠️ *Unruled;
compiler declined to rule it and so do I. It is named here so tomorrow's queue does
not open with obsolete work.*

---

## What this says for C4

**Four tiers, and only the first is an import problem:**

| tier | population | cure |
|---|---|---|
| ① behavioural cert exists, out of build | **`bnComps`** | **an import** |
| ①ᵇ **certified only ON A SAMPLE** (ruling 16:33) | **`adder32`, `inc32`** — 49 pairs / 7 words | **an unconditional proof** (math, C4 arc) |
| ② certified structurally only | ~34 real (+15 in `BatcherNet`, possibly retired) | a proof |
| ③ no theorem at all | **106** | a proof |

⚠️ **Tier ①ᵇ IS NEW AND THIS INSTRUMENT CANNOT SEE IT.** A sampled check touches `sem`
exactly as an exhaustive one does, so both members read `B-PROVEN` above. **Its population
is therefore UNKNOWN, not two** — 19 theorems in the tree have the shape `<X>OK = true`,
six now carry `_on_sample`, and the remainder mix genuinely exhaustive certificates
(`ce_step_eq`, all 128 configurations) with unclassified ones. *The proposed value-shape
detector — does the unfolded statement reach a def whose value is a literal list of
hand-written constants — would settle it; it does not exist yet.*

⇒ ***The import sweep closes tier ① and nothing else. Tiers ②③ are ~140 definitions
that no import will reach, and that is the honest size of the proof debt.***

⭐ **AND THE DAY'S RESULT IN ONE LINE: the census was published at 15:53 and by 16:07
two of its four headline names were closed by the seat that owned them.** *The table
above is what remains after the fleet read the first one.* **A measurement that moves
its own subject is the only kind worth posting at a muster.**
