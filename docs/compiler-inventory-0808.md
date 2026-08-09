# COMPILER INVENTORY — the three night-shift questions, answered at the bytes

**Seat:** COMPILER · **2026-08-08 ~19:1x** · **Order:** maestro 19:02, front ②,
*"file-not-post the findings"*

Every claim below is a reading of the tracked corpus, with the file and declaration
named. Where the answer is **no artifact**, that is stated as a negative result with
the search that establishes it — not as a gap I expect someone to fill from memory.

⚠️ **ONE FINDING IS URGENT AND IT IS ABOUT THE STORY, NOT THE CODE.** See Q2.

---

## Q1 — Does ONE end-to-end core theorem crown the certified organs?

### **NO. And there is no `core` object to state one about.**

```
def core | def cpu | def riscvCore | def sliceACore   →  ZERO hits, tracked corpus
```
The only `core*` definitions are `C4.lean`'s `coreShort` / `coreNarrow` /
`coreShaped` / `coreShapedT` (composition *test fixtures*) and
`StateCodec.coreInWidth` (a width constant). **No assembled datapath exists.**

### What IS landed: the composition THEORY, complete

Per `docs/hdl-c4-core-assembly-plan-0807.md` §0, four lemmas:

| lemma | says |
|---|---|
| `Circ.wf_of_ssa` | `ssa → wf`, so a core-sized side condition is reachable |
| `instGates_eq_renumFrom` | the embedded gate list IS a `renumFrom` |
| `inst_sem` | an instantiated block computes what the block computes |
| `inst_compose_*` | two blocks at `off`/`instNext` compose, neither disturbing the other |

⇒ **The remaining work was called "a construction, not a lemma" — and that was
true and incomplete: it is a construction whose inputs were not all present.**

### ⭐ AND THE HEADLINE: PHASE 3 DISSOLVED THAT BLOCKER TODAY. The plan does not know.

`hdl-c4-core-assembly-plan-0807.md` is **dated 8/7 and carries pre-re-cut numbers**
(`:64` reads `aluSelect | 1,445 | 324 | 32`; `:225` reads `asIn = 324`). Its §3 is
titled *"`aluSelect` NEEDS TEN OPERAND RESULTS; SIX HAD NO PRODUCER, FOUR NOW DO"*,
and it names the two survivors:

```
operand 7  sll  ⛔ MISSING — needs a MODE BIT on shifter32 (a decision, not a build)
operand 9  sra  ⛔ MISSING — same
```

**Slice A's ruled select has THREE sources, not ten** — `{add, xor, slt}`
(`AluSelect.lean:409`, `SelectCut32.lean:452`, `Program.lean:6002`;
`EncoderE1.ruledCodes = [0, 1, 2]`). And all three producers are landed:

| ruled source | producer | where |
|---|---|---|
| add | `adder32` | `Adder.lean:97` |
| xor | `bitXor32` | `Bitwise.lean:68` |
| slt | `sltCirc` | `Bitwise.lean:193` |

⇒ ***`sll` and `sra` are operands 7 and 9 of the retired ten-source select. They are
OUTSIDE Slice A's source set. So the assembly's inputs are now ALL PRESENT, and the
gap the 8/7 plan describes closed not by building the missing organs but by the
re-cut REMOVING THE REQUIREMENT.***

### What it would take, as of tonight

1. **Build the `core` object** — instantiate decoder + regfile-read + the three ALU
   producers + `sliceASelect` + `ruledEnc` at `instNext` offsets per `StateCodec`'s
   fixed layout. Pure construction; the four composition lemmas are the tools.
2. **One `sem`-level theorem**: `∀ w s, sem core (encode-state s ++ w) = encode-state
   (ISA.stepT s w)` — i.e. *the circuit's step agrees with the ISA's step at every
   machine word*. The two halves it must join both exist: `decoder_correct`
   (`Program.lean:7487`, `∀ w, ctrlOf w = ctrlSpec w`, unconditional) and
   `ISA.stepT` (`ISA.lean:687`).
3. ⚠️ **Re-price §3.5 of the plan first.** It lists *"two blocks on the critical path
   that do not exist"* — that section is also pre-re-cut and I did not audit it here.
   **Do not read this document as saying the construction is unblocked; it says the
   OPERAND gap is closed. Those are different claims.**

---

## Q2 — The sort demo's program: hand-assembled or generated, and by what?

### ⛔ **NEITHER. THERE IS NO SORT PROGRAM IN THE CORPUS.**

`docs/two-weeks-story.md:49` states the ISA slice is *"demonstrated on a
**Batcher-sort program** using two proved **compile-around lowerings**."*

**The search, published so it is reproducible — `command grep` (shim bypassed, so
gitignored files ARE included), both repos, case-insensitive:**

```
compile-around      2 files — BOTH are docs: two-weeks-story.md, lang-design-v1.md
compileAround       0 files
sortProg            0 files
batcher.*sort.*prog 1 file  — docs/two-weeks-story.md
lowering           19 files — none of them a Slice-A lowering; salt/ blueprint prose
```

⇒ ***Zero `.lean` artifacts. The phrase exists only in prose written today.***

**The only `List Instr` values in the tracked corpus are three toy fixtures inside
`ISA.lean`'s own test block:**
```
:294  [.ADDI 1 0 20, .ADDI 2 0 22, .ADD 3 1 2]     (3 instructions)
:302  [.ADDI 1 0 1]                                 (1 instruction)
:310  [.BEQ 0 0 4, .ADDI 1 0 99, .ADDI 2 0 5]      (3 instructions, a branch test)
```
**There is no assembler, no code generator, no Batcher-sort program, and no lowering
theorem.** The ISA interpreter to run one *does* exist (`fetch` `:131`, `runFor`
`:139`, `run` `:153`) — so the demo is *runnable in principle* and *unwritten in fact*.

### ⚠️ WHY THIS IS THE URGENT ITEM

**The story is the document that goes to the Captain and its own rule is that it
quotes ONLY instrument readings. This sentence is not an instrument reading.** It is
the same class the fleet closed at 16:1x — a claim citing evidence a reader cannot
reach — except that class was *scratch-measured-and-unshareable*, and this one has no
measurement at all.

**Two honest repairs, either of which I can execute:**
- **(a) write the demo** — a Batcher-sort program in `List Instr` plus the two
  lowerings as theorems (the ISA lacks `SUB` and `BNE`, so a comparator lowers to
  `SLT` + `BEQ`; *that* is presumably what "compile-around" means, and it is
  provable);
- **(b) restate the sentence** to what exists: a 5-op ISA with an interpreter, an
  encoder, a decoder proved correct against the hardware, and three toy programs.

📌 *I recommend (a) — it is small, it is my slot, and it converts the story's boldest
demo claim from prose into an artifact. But (b) tonight and (a) tomorrow is honest;
(a) claimed-before-built is not.*

---

## Q3 — The exact op semantics the 5-op ISA exposes to a compiler backend

**Source of truth: `SaltWorks/HDL/ISA.lean`, namespace `SaltWorks.ISA`.** The op set
is taken verbatim from `docs/EVIDENCE-riscv-datapath-brief.md` §2.2.

### The five ops, with the semantics as the file states them

| op | constructor | semantics, verbatim from the docstring |
|---|---|---|
| ADD | `ADD (rd rs1 rs2 : Fin 32)` | `rd := rs1 + rs2`, **wrapping** |
| ADDI | `ADDI (rd rs1 : Fin 32) (imm : BitVec 12)` | `rd := rs1 + sext(imm)` — the 12-bit immediate is **SIGN-extended**; the brief calls this *"the single most common formalisation bug"* |
| XOR | `XOR (rd rs1 rs2 : Fin 32)` | `rd := rs1 ^^^ rs2` |
| SLT | `SLT (rd rs1 rs2 : Fin 32)` | `rd := if rs1 <ₛ rs2 then 1 else 0` — **SIGNED**; the file notes this is *"literally the instruction the sp1-lean audit found vacuously true"* |
| BEQ | `BEQ (rs1 rs2 : Fin 32) (imm : BitVec 12)` | `if rs1 = rs2 then pc += sext(imm ++ 0) else pc += 4` — `imm` holds `imm[12:1]`, **the low zero bit is structural** |

`deriving DecidableEq`. ⇒ **A backend can `decide` instruction equality.**

### The FOUR surfaces a backend can target — this is the useful part

```
ABSTRACT SYNTAX     Instr                 :80    the five constructors above
STATE               structure St          :72    regs + pc
                    St.get                :98    ⭐ x0 reads ZERO UNCONDITIONALLY —
                                                 a fact about the READ PORT, not an
                                                 invariant about regs[0], so `get_zero`
                                                 needs no hypothesis
STEP (abstract)     step : St → Instr → St        :120
                    fetch / runFor / run          :131 / :139 / :153
MACHINE WORDS       encode : Instr → BitVec 32    :549
                    decode : BitVec 32 → Option Instr  :561
                    stepW  : St → BitVec 32 → Option St :634
                    stepT  : St → BitVec 32 → St        :687   (TOTAL — the one a
                                                                circuit theorem wants)
HARDWARE            Decoder.decoder : Circ        Decoder.lean:170
                    decoder_correct               Program.lean:7487
                                                  ∀ w, ctrlOf w = ctrlSpec w
                                                  ⭐ UNCONDITIONAL
```

### What that means for a backend, stated plainly

✅ **A backend has everything it needs to emit and to be checked:** abstract syntax
with decidable equality, a total machine-word step (`stepT`), an encoder, a decoder,
and a hardware decoder proved correct against its spec unconditionally. **A lowering
theorem can be stated at either level** — over `Instr` (cheap, syntactic) or over
`BitVec 32` through `encode`/`decode` (the honest one, since it is what the silicon
sees).

⛔ **What is NOT exposed, and a backend must not assume it:**
1. **No SUB, no BNE, no BLT, no shifts, no loads/stores, no jumps.** Five ops is
   five. Every comparator, negation and loop must lower into `{ADD, ADDI, XOR, SLT,
   BEQ}` — which is exactly why the story's "compile-around lowerings" is the right
   *idea* and why it needs to exist as a theorem (Q2).
2. **No `x0`-write semantics stated as a separate obligation** — writes to `x0` are
   whatever `step` does with them; I did not audit that path and a backend that emits
   `rd = x0` as a discard is relying on unread behaviour. **Check before using.**
3. **No memory model at all.** There is no load/store, so "runs programs" means
   *register programs*, which is exactly how `docs/two-weeks-story.md:77` scopes v1 —
   that line is accurate.
4. **No pipeline/timing semantics.** `step` is one instruction, atomically. Anything
   about cycles belongs to the `Seq`/`runTrace` layer, not here.

---

## SUMMARY — the three answers in one line each

```
Q1  end-to-end core theorem?   NO, and no `core` object. Theory landed (4 lemmas);
                               construction unbuilt. ⭐ BUT phase 3 removed the
                               operand blocker: sll/sra are outside Slice A's ruled
                               {add, xor, slt}, all three producers landed. The 8/7
                               plan is pre-re-cut and does not know this.
Q2  the sort demo's program?   ⛔ DOES NOT EXIST. "compile-around" = 2 docs, 0 .lean.
                               No assembler, no generator, no lowering theorem. The
                               interpreter to run one DOES exist. The STORY asserts
                               the demo — that sentence needs (a) the artifact or
                               (b) restating, tonight.
Q3  the 5-op op semantics?     ADD/ADDI/XOR/SLT/BEQ, four targetable surfaces
                               (Instr · step · encode/decode/stepT · a hardware
                               decoder proved unconditionally correct). Sign-extension
                               on ADDI, SIGNED slt, structural low bit on BEQ. No SUB,
                               no BNE, no memory, no timing.
```

📌 **METHOD NOTE, because two of these three are negative results:** every "does not
exist" above is backed by a published invocation — `command grep` to bypass the
`.gitignore`-obeying shim, both repos, case-insensitive. *A negative search result is a
claim about an instrument plus a root plus a filter, never about the world; this seat
made that mistake twice today and the invocations are here so nobody has to trust me.*
