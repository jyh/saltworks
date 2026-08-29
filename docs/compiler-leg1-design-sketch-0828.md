# Leg ① — design sketch and priced proof delta

**Seat:** compiler · **Date:** 2026-08-28 · **For:** the Aug 31 checkpoint, which judges DESIGN and
PRICE, not a landing (helm reframe 11:0x) · **Status:** sketch complete, ONE FREEZE OPEN

## 0 · What leg ① actually requires

`core32.v` — verified byte-identical to the FABRICATED commit by silicon at 11:07 — computes a store
address as `rf1 + imm_s`. The Lean model does not, because its operand-B mux selects the immediate on
`decOut isADDILine` alone. **Leg ① is closing that gap in the MODEL. No RTL changes.**

## 1 · The change is three pieces, and two of them cost nothing new

**① `immS` IS A WIRING FUNCTION, NOT AN ORGAN — ZERO GATES.**
The landed `immI` is `def immI (k : Nat) : Net := if k < 12 then 20 + k else 31` — a *net map* from
immediate bit to instruction bit, consumed as `instrNet (immI j)`. S-type is the same shape:
```lean
def immS (k : Nat) : Net := if k < 5 then 7 + k else if k < 12 then 25 + (k - 5) else 31
```
*(ISA.lean: "imm[4:0] in bits 11:7", "imm[11:5] in bits 31:25"; k ≥ 12 is the sign bit, 31.)*

**② THE IMMEDIATE SELECT REUSES A CERTIFIED ORGAN — NO NEW CIRCUIT, NO NEW CERTIFICATE.**
Choosing between `immI` and `immS` is a 32-bit 2:1 mux with one select — **which is exactly what
`OperandB.obMux` already is**, with `out_sem_obMux` already landed. Place a SECOND INSTANCE:
`a = instrNet ∘ immI`, `b = instrNet ∘ immS`, `sel = decOut isSWLine`.

**③ ⭐ THE OPERAND-B SELECT IS ONE OR GATE, BECAUSE THE DECODER ALREADY EMITS THE SIGNAL.**
The RTL's `alu_src = is_immop|is_load|is_store|is_jalr`. This ISA has no JALR, so the model needs
`isADDI ∨ isLW ∨ isSW`. **`ctrlSpec`'s `reqLine` (index 7) is TRUE exactly on LW and SW and FALSE on
everything else including `none`** — read off the table in `Decoder.lean:307-319`. Therefore:
```
select = decOut isADDILine  ∨  decOut reqLine        ← ONE two-input OR gate
```
*The signal the widening needs is already on a wire; nobody has to build it.*

⇒ **TOTAL NEW SILICON IN THE MODEL: one OR gate, one reused organ instance, one wiring function.**

## 2 · ⛔ THE FREEZE — WHERE the new organs are placed, and it is an 18× decision

Both new organs must produce their outputs BEFORE the consumer reads them, so placement is not free.

**OPTION A — INSERT IN PLACE (structurally faithful).** New organs go before `obMux`; the model keeps
core32's single-ALU shape. ⛔ **Every offset after the insertion point moves.**
```
mid-chain offset occurrences   460   across 20 files
kernel-pinned facts in tree   1414   across 127 files (an unknown fraction index-specific)
```

**OPTION B — APPEND AT THE END (cheap).** New organs plus a SECOND adder instance are appended past
`offRegNext`; the memory port's address nets read the new adder. **Nothing existing moves.**
```
whole-core size facts            26   across 7 files
```
⚠️ **But the model then carries TWO adders where the die carries one plus a mux.**

***THE QUESTION, AND IT IS NOT MINE TO SETTLE: does the mask certificate require the model to mirror
the chip's STRUCTURE, or only to agree with it at VALUES?*** `bridge_sem_eq` is a value theorem;
`instOK` is structural but only per-organ. **If values suffice, B is ~18× cheaper on the surface that
actually costs. If the certificate's claim is "this model IS that chip", A is required and B is a
quiet lie in the artifact whose whole purpose is not to contain one.**

## 3 · Proof delta, per option

```
                                    OPTION A            OPTION B
new organ instOK proofs             2 (+1 adder in A? no) 3 (2 + second adder)
existing offsets invalidated        460 sites / 20 files  0
whole-core size facts to re-pin     26 / 7 files          26 / 7 files
bridge induction (bridge_agrees)    UNCHANGED             UNCHANGED   ← Netlist→Circ, no obMux
legs ②/③ (memWe, memWData)          UNCHANGED             UNCHANGED   ← strobe and rs2, not address
leg ① correspondence proof          the same either way — the address leg, over the new nets
```
⛔ **HOURS: STILL NOT GIVEN, AND DELIBERATELY.** The two options differ by ~18× on the only surface
that dominates, so a single number would be a number for a design nobody has chosen. **I will price
the chosen option within hours of the freeze being ruled, and publish the basis with it.** *This item
has already cost the helm one hope-priced-as-a-cost; I am not supplying the mirror-image error.*

## 4 · What is NOT at risk
Nothing physical waits on this. The Aug 29 DRV run carries nothing from leg ①. `bridge_agrees`, and
legs ②/③, survive both options untouched — so the correspondence work already landed is not at stake
in this decision.

## 5 · ⛔ THE RE-PIN SET, ENUMERATED — and it refutes my own count

I priced component ① off a COUNT (~16 theorems across 14 files). **Naming the members refutes it.**
```
MUST CHANGE — all in this seat's glob, all mechanical
  CorePlace.adder_offsets          offAdd = 7339 ∧ offSub = 7499
  CorePlace.offSlt_value           offSlt  = 7659
  CorePlace.offSel_value           offSel  = 7664
  AccountMeasure.chain_end_is_11486  instNext regNext offRegNext = 11486
  CorePlace.placedGateTotal        a DEFINITION, must gain the new organs' gate lengths
                                   (core_gate_count is symbolic and re-derives once it does)
⇒ FOUR theorems and ONE definition, in THREE files.

NOT AFFECTED — matched by my grep, refuted by reading them
  Stack/Program.pcAdd_adder_off    pcAddOff := 130 is pcAdd's OWN internal chain, in math's
                                   glob; a core insertion does not reach it
  Cell1988.cell88_gate_count       a different circuit (cell88core)
  CompareExchangeC.ceC_gate_count  a different circuit (ceCcore)
```
⇒ ***THE COUNT WAS 4× THE SURFACE, AND EVERY EXCESS MEMBER WAS AN ADJACENT OBJECT MY PATTERN
MATCHED*** — another circuit's gate count, another chain's offset. **Component ① revises from 2–4 h
to under an hour of edits plus build cycles. Total revises 12–24 h → 11–21 h, and the range is now
entirely component ③.** *The total barely moves; the BASIS moved a lot, which is the part a
reviewer needs.*

📌 **AND THE FORM THAT CAUGHT IT IS THE ONE MY OWN CARD PRESCRIBES: PRINT THE LIST, NOT THE TOTAL.**
A count cannot be checked; five named theorems can be opened by anyone in a minute. **This section is
also the implementation checklist — the offset pass is now five items, not a search.**

## 6 · ⛔⛔ THE RE-PIN SET, CORRECTED A SECOND TIME — and the pattern is the finding

§5 said FOUR theorems and one definition. **That was also wrong.** A declaration-aware scan finds
**SEVEN theorems and one definition, in TWO files**:
```
SaltWorks/HDL/AccountMeasure.lean   offsets_pinned · chain_end_is_11486
                                    chain_reconciles_with_CoreOffsets · reconciliation_is_not_vacuous
SaltWorks/HDL/CorePlace.lean        adder_offsets · offSlt_value · offSel_value
                                    placedGateTotal (a DEFINITION)
NOT AFFECTED  Stack/Program.pcAdd_adder_off — pcAdd's OWN chain, math's glob (unchanged verdict)
```
**Three of the four I missed have their statement on the line AFTER `theorem`**, and my pattern
required it on the same line. *Two of them are in the very file whose docstring says "a name
carrying a literal is a maintenance obligation, not a description" — a file renamed once already
for exactly this class.*

⇒ ***THREE COUNTS, THREE WRONG, IN BOTH DIRECTIONS: ~16 (adjacent objects the pattern swept in),
4 (multi-line statements the pattern could not see), 7 (correct).*** **The constant is not the
arithmetic — it is that a LINE-ORIENTED pattern was allowed to define a DECLARATION-ORIENTED
population, three times, by me, after I banked the card that says so.**
✅ **The cure that actually worked: parse the LANGUAGE — walk from `theorem <name>` to the first
`:=`, and test THAT block.** Line-grep is an instrument for text; a declaration is not text.

📊 **PRICE IMPACT: none worth restating.** Seven mechanical re-pins instead of four is still under an
hour, and component ③ is untouched. **The number moved; the estimate did not. I am publishing it
because the design doc is what the checkpoint reads, not because 11–21 h has changed.**
