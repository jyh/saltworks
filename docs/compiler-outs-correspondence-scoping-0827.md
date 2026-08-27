# The ISA-level `outs` correspondence — scoping pass

**Seat:** compiler · **Date:** 2026-08-27 · **Status:** SCOPING ONLY, no proof attempted yet
**Commission:** helm 13:0x — post-tape-out flagship, no deadline. Convert the memory organ's
**MEASURED** placement claim into a **PROVED** one.

## 0 · Why this exists

`bridge_sem_eq_of_bridgeable` (landed `fdde237`) certifies that a bridged circuit's `sem` agrees
with the netlist's `runP` **at the declared `outs`**. It says nothing about whether the RIGHT NETS
were declared as `outs`. `instOK` has the same shape one level up: it is a TIMING AND STRUCTURE
property and says nothing about whether the right wire was chosen. **This seat holds the receipt:
two placements once fed `rs2` where `ADDI` needs the immediate, and every `instOK` was TRUE.**

## 1 · What the statement would have to say

For the memory organ, the correspondence is three legs. Written against `ISA.lean`'s
`SW rs1 rs2 imm  ⟶  mem[(rs1 + sext(imm)) / 4] := rs2` (`ISA.lean:155`):

```lean
theorem mem_outs_correspondence (ins : Env) (rs1 rs2 : Fin 32) (imm : BitVec 12)
    (hw : seenWord ins = encode (Instr.SW rs1 rs2 imm)) :
    -- ① ADDRESS — the three nets carry bits [4:2] of the ISA effective address
    (∀ j, j < 3 → run ins core.gates (MemWiring.memAddrNet j)
        = ((decQ ins).get rs1 + BitVec.signExtend 32 imm).getLsbD (j + 2)) ∧
    -- ② WRITE ENABLE — the strobe is high exactly on a store
    run ins core.gates MemWiring.memWeNet = true ∧
    -- ③ WRITE DATA — the 32 nets carry the rs2 register value
    (∀ k, k < 32 → run ins core.gates (MemWiring.memWDataNet k)
        = ((decQ ins).get rs2).getLsbD k)
```
*The shape to copy is `SelValueADD.selOut_is_isa_written_bit_ADD` — it already proves "a placed net
carries the ISA value" for one instruction class. This is that, for the store port.*

## 2 · What MemWiring already gives me — and what it does not

⛔ **EVERY THEOREM IN `MemWiring.lean` IS ABOUT NET INDICES, NOT VALUES.** `= rfl`, `< offMem`,
`≠`. That is not a criticism of the file — it is exactly what the file claims — but it means the
placement contributes **zero** of the three legs above, and its four negative controls
(`control_we_is_not_isLW`, `control_addr_is_not_byte_indexed`, `control_addr_bits_distinct`,
`control_offset_matters`) are all structural and would all stay TRUE under a wrong-value wiring.

**THE VALUE-LEVEL MATERIAL THAT DOES EXIST, and it is most of two legs:**
```
LEG ② write enable   DecoderTransport.core_decOut_spec  — decOut j INSIDE core is
                     (ctrlSpec (seenWord ins)).getD j   ⇒ leg ② is a short hop
LEG ③ write data     Rs2Close.rs2Of_is_St_get           — "THE rs2 PORT, CLOSED":
                     rs2Of ins = (decQ ins).get ⟨rs2AddrOf ins, _⟩
LEG ① address        ⛔ NOTHING. `SelValueShared.addOut_eq` is a NET-INDEX identity, not a
                     value spec; the only `addOut` value work is in GITIGNORED scratch.
```

## 3 · ⛔⛔ THE BLOCKER — LEG ① IS NOT MERELY UNPROVED. AS WIRED IT IS FALSE.

**Kernel-checked structural chain (`ScratchSWADDR.lean`, 6/6 ticks, 0 `sorryAx`):**
```
① memAddrNet j      = addOut (j + 2)                  the address is the ADDER's bits [4:2]
② addSig (32 + k)   = obOut k                         the adder's operand-B bank is obMux
③ obSig k           = rs2Out k          (k < 32)      obMux's a-input is rs2
④ obSig (32 + j)    = instrNet (immI j) (j < 32)      obMux's b-input is the I-TYPE immediate
⑤ obSig 64          = decOut isADDILine               ⭐ THE SELECT LINE IS isADDI, AND NOTHING ELSE
⑥ decOut isADDILine ≠ decOut isSWLine                 a store does not assert that select
```
Compose with the **landed** organ theorem `OperandBMux.out_sem_obMux`:
`(sem obMux ins).getD k false = if ins 64 then ins (32+k) else ins k`.

⇒ ***UNDER A STORE, `isADDI` IS LOW, SO OPERAND B IS `rs2`, AND THE MEMORY ORGAN'S ADDRESS IS
BITS [4:2] OF `rs1 + rs2`. THE ISA CALLS FOR `rs1 + sext(imm_S)`.*** They coincide only when
`rs2 = sext(imm_S)` — accidentally.

### ⛔⛔ CORRECTED SAME DAY, 13:1x — I NAMED THE WRONG OBJECT, AND THE RTL IS RIGHT

**This section first read: *"the S-type immediate is not placed anywhere in the datapath."* That is
true of the LEAN datapath. IT IS FALSE OF THE RTL, and I wrote it as though about THE DESIGN.**

```verilog
core32.v:79   wire alu_src = is_immop|is_load|is_store|is_jalr;   ← A STORE SELECTS THE IMMEDIATE
core32.v:88   assign imm = is_store ? imm_s : is_br ? imm_b : ...
core32.v:98   wire [31:0] b_op = alu_src ? imm : rf2;
core32.v:134  assign dmem_addr = alu_y;
ctrl32.v:40   assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
```
⇒ **IN THE RTL A STORE COMPUTES `rf1 + imm_s`, WHICH IS THE ISA.** The S-type immediate is built,
sign-extended and selected, in two independent modules.

⭐ ***SO THE DIVERGENCE IS LEAN-MODEL-vs-RTL, AND THE LEAN MODEL IS THE NARROWER ARTIFACT:*** its
operand-B select is `decOut isADDILine` alone where the RTL's is a four-way
`is_immop | is_load | is_store | is_jalr`. **Not a silicon defect and not an absent feature — a Lean
`obMux` modelling one case of a four-case select.**

**AND `memOrgan` IS NOT IN `core.gates` AT ALL** (0 occurrences in `CoreAssembly.lean`; `core` is
sixteen blocks and the organ is not among them). `mem_instOK_placed` proves a placement would be
LEGAL at `offMem`; **it does not place it.** So nothing in the Lean core acts on that address either.

📌 **THE §3 CHAIN IS UNAFFECTED — all six links are statements about Lean nets and all six still
hold.** What was wrong was the sentence around them, which named the design when it had measured the
model. ⚠️ **NOT MEASURED BY ME, and it is the half that decides chip risk: which RTL top was
fabricated, and whether the netlist imported into Lean corresponds to `core32.v`. That is silicon's
to answer.** Do not carry *"the chip is fine"* from this file — carry *"the RTL in this tree computes
the store address correctly, and the Lean model does not."*

⚠️ **WHAT THE ITEM IS NOW:** a VERIFICATION-GAP item, post-tape-out, no mask implication — moved
there from *"a fabricated chip may compute a silent wrong store address"*. **And it makes this work
more valuable, not less: the divergence is exactly what an ISA-level `outs` theorem exists to catch,
and it was invisible to `instOK`, to four negative controls, and to me until I read the Verilog.**

*(Original wording preserved below, struck, because a correction that erases its subject leaves the
next reader unable to check it.)*
> ~~`obMux` selects the immediate on `isADDI` alone; the S-type immediate is **not placed anywhere in
> the datapath**. Whether that is a DEFECT or an UNBUILT ROADMAP ITEM is not mine to rule —
> `docs/QUEUE.md:156` records Slice-B's `LW/SW/JAL/JALR` as carrying sign-extended immediates on
> *arrival*, which reads as roadmap.~~ **Leg ① still cannot be PROVED for `SW` in Lean until the
> model's operand-B select covers the store case.**

📌 **NOT THE SAME AS TWO NEARBY RECORDED FINDINGS, checked before claiming novelty:**
`C4Refuted.lean:113` states its two further refutations are *"NEITHER ABOUT STORES"*, and its `SW`
horn was the ENABLE, repaired. `docs/silicon-candidate-instr-bypass-0818.md:21` is a bus-adapter
pipelining defect (`instr_r` holding the previous instruction), since patched — silicon's note that
*"the store ADDRESS looked correct only by coincidence"* is about the BASE REGISTER, not the
immediate. **Same class, three different mechanisms.**

## 4 · What I have NOT done, so nobody reads more into this than it is

- **No value-level witness yet.** §3's chain is STRUCTURAL. The refutation it implies is an
  argument over a landed organ theorem, not a kernel exhibit. ⇒ **FIRST WORK ITEM: a concrete
  `ins` encoding a real `SW` with `rs2 ≠ sext(imm)`, and `decide +kernel` showing the address nets
  disagree with the ISA.** Until that exists §3 is a very good reason to look, not a proof.
- **Legs ② and ③ are "a short hop" by inspection of their statements, which is exactly the kind of
  estimate this seat has been wrong about before.** Not priced.
- **No claim about LW**, which shares the adder and therefore probably shares leg ①'s problem —
  unchecked.

## 5 · Routes, for whoever rules on it

1. **Place an S-type immediate** into operand B (widen `obMux`'s select, or add a stage). Datapath
   change; silicon/design lane. Leg ① then becomes provable by the `SelValueADD` template.
2. **Scope the theorem to the classes that hold.** State the correspondence for the instruction
   classes whose operand B is already correct, and record `SW` as excluded WITH §3 as the reason.
   *Cheap, honest, and it makes the exclusion a theorem-adjacent fact rather than a silence.*
3. **Prove legs ② and ③ now, unconditionally.** They do not depend on leg ①, and the strobe and the
   write-data path are two thirds of the port. *This is the work available today with no ruling.*

**I recommend 3 now and 2 alongside it, with 1 registered as the design question it is.**
