# S0/R2 — THE MEMORY-MODEL CENSUS

### Opus executor, 2026-08-07. READ-ONLY node: no `.lean` written, no build run,
### no existing file changed. Deliverable is this document plus a `docs/LEDGER.md`
### append.
### Format PRE-REGISTERED on the fleet bus before any answer existed — six
### sections, in the order below, so the census cannot be shaped to its
### conclusions.

**Scope.** R2 of `docs/stack-campaign-v0.md`: *"does `St` support load/store
today, or is that C1 completion work that gates S2?"* The evidence seat already
answered that at the type
(`docs/EVIDENCE-stack-refuter-0807.md` §1: **CONFIRMED HARD GATE**). §1 below
re-verifies it at the bytes; **the census's job is §2–§6 — pricing what
follows.**

**Method notes, because two of them changed what this document says.**
`grep -F` throughout (BSD `grep` silently returns zero matches on `^`
mid-pattern). Every absence claim was run in a batch carrying a positive control
in the same invocation, and the control's non-zero count is reported beside it.
Every cited line was re-located by name, not trusted from an earlier read — five
seats commit into this tree concurrently. `USE` means live code; `PROSE` means
docstring or comment.

---

## §1 — WHAT EXISTS TODAY

Every claim below carries a fully-qualified name at `file:line`.

### 1.1 `St`'s fields — re-verified at the bytes

`SaltWorks.ISA.St` — `SaltWorks/HDL/ISA.lean:72` **[USE]**

```lean
structure St where          -- :72
  regs : Vector (BitVec 32) 32   -- :73
  pc   : BitVec 32               -- :74
  deriving DecidableEq           -- :75
```

**Two fields. No third.** The reported fact is confirmed exactly as reported.

`deriving DecidableEq` at `:75` is **[USE]**, not decoration: it is consumed by
`SaltWorks.ISA.Vec.checkFull` (`SaltWorks/HDL/Vectors.lean:72`), which is
`v.actual == some v.expected` — `BEq` on `Option St` — and by every
`decide +kernel` certificate that compares whole states.

Accessors and constructors, all mentioning `regs` and `pc` and nothing else:
`SaltWorks.ISA.St.get` `:99` **[USE]** (`if r = 0 then 0 else s.regs[r.val]`),
`St.set` `:107` **[USE]** (`if r = 0 then s else { s with regs := … }`),
`St.next` `:111` **[USE]**, `St.init` `:156` **[USE]**.

The `Vector`-not-function choice is argued at `:64–71` **[PROSE]**, sourced to
the brief's measurement `[V-ME]`.

### 1.2 The complete `Instr`

`SaltWorks.ISA.Instr` — `ISA.lean:80` **[USE]**, five constructors and no others:

| constructor | line | shape |
|---|---|---|
| `ADD`  | `:82` | `(rd rs1 rs2 : Fin 32)` |
| `ADDI` | `:85` | `(rd rs1 : Fin 32) (imm : BitVec 12)` |
| `XOR`  | `:87` | `(rd rs1 rs2 : Fin 32)` |
| `SLT`  | `:90` | `(rd rs1 rs2 : Fin 32)` |
| `BEQ`  | `:93` | `(rs1 rs2 : Fin 32) (imm : BitVec 12)` |

`deriving DecidableEq` at `:94`. The docstring at `:77–79` **[PROSE]** states the
exclusions in terms: *"no loads, no stores, no `LUI`/`AUIPC`, no `JAL`/`JALR`, no
shifts, no `M`, no CSRs, no traps, no privilege modes, **no memory model at
all**."* Confirmed as reported.

### 1.3 Every case of `step`

`SaltWorks.ISA.step` — `ISA.lean:120` **[USE]**, total, structural, no fuel:

| case | line | effect |
|---|---|---|
| `.ADD rd a b`   | `:121` | `(s.set rd (s.get a + s.get b)).next` |
| `.ADDI rd a imm`| `:122` | `(s.set rd (s.get a + imm.signExtend 32)).next` — **sign**-extend |
| `.XOR rd a b`   | `:123` | `(s.set rd (s.get a ^^^ s.get b)).next` |
| `.SLT rd a b`   | `:124` | `(s.set rd (if (s.get a).slt (s.get b) then 1 else 0)).next` — **signed** |
| `.BEQ a b imm`  | `:125–126` | `if s.get a = s.get b then { s with pc := s.pc + bOffset imm } else s.next` |

`SaltWorks.ISA.bOffset` `:116` **[USE]** = `(imm.signExtend 32) <<< 1`.

⇒ **Every case touches exactly `regs` (through `St.set`) and `pc` (through
`St.next` or the `BEQ` update). There is no case that reads or writes anything
else, because there is nothing else.**

### 1.4 `fetch`'s source of instructions — the fact §3 turns on

`SaltWorks.ISA.fetch` — `ISA.lean:131–132` **[USE]**

```lean
def fetch (code : List Instr) (pc : BitVec 32) : Option Instr :=
  if pc.toNat % 4 = 0 then code[pc.toNat / 4]? else none
```

Three things, each load-bearing later:

1. **The instruction source is a Lean `List Instr` passed as an argument.** It is
   not a field of `St`, not a memory, not even words. It is a host-language value
   that the machine's state cannot name.
2. **`pc` is a BYTE address** and the alignment gate is executable
   (`:128–130` **[PROSE]** pins the convention; the failure mode is *halt*, not
   round-down).
3. **The run path never touches `decode`.** `fetch` yields an `Instr` directly.
   `SaltWorks.ISA.decode` is used by `stepW`/`stepT` and by the differential
   harness — never by `runFor`.

### 1.5 `runFor` / `run`, and the precondition its bound rests on

`SaltWorks.ISA.runFor` — `ISA.lean:139–144` **[USE]**, structural on a `Nat`,
stopping when `fetch` returns `none`.
`SaltWorks.ISA.run` — `ISA.lean:153` **[USE]**: `run code s := runFor code.length code s`.

The bound's justification is `ISA.lean:149–152`, **[PROSE] — it is the docstring
of `run`**, verbatim:

> *"`code.length` is a sufficient bound rather than a fuel parameter: every
> branch the code generator emits is forward (confirmed by kill-check R4 under
> all four candidate offset conventions), so `pc` strictly increases and at most
> `code.length` instructions can be fetched before it leaves the program."*

**Nothing in Lean carries it.** No hypothesis on `run` (`:153`), no
`Forward`/`NoBackwardBranch` predicate anywhere in `SaltWorks/**`, no theorem of
the form `n ≥ code.length → runFor n code s = run code s`. Searched with `grep -F`
across `SaltWorks/`; the only hits for `runFor`/`run` in this sense are
`ISA.lean:139,144,152,153` (definitions), `:295`, `:303`, `:311` (three
certificates) and `:733–736` (audit lines). *(Note the F3 ambiguity the C4
composition check names: `SaltWorks.HDL.Sem.run` at `Sem.lean:61` is a different
`run` — gate evaluation — and is not this one.)*

Landed certificates about `run`: `run_executes` `:293`, `run_halts_off_the_end`
`:301`, `run_forward_branch_skips` `:309` — all **[USE]**, all `decide +kernel`,
all on concrete straight-line or forward-branching programs.

**And the machine can violate the assumption:**
`SaltWorks.ISA.beq_offset_can_be_negative` — `ISA.lean:281` **[USE]** — is a
kernel certificate that a *backward* branch executes correctly. Its own docstring
(`:277–280` **[PROSE]**) says why it is there: *"Stated because the code generator
promises never to emit one, and a promise about a thing the machine cannot do is
not a promise."*

Verdict deferred to §5C.

### 1.6 `decode` / `encode`, and exactly what the round-trip covers

- `SaltWorks.ISA.ofReg` `:343`, `toReg` `:347`, `toReg_ofReg` `:349` — **[USE]**.
- Three word layouts, **[USE]**: `wR` `:368` (opcode `0110011` baked in),
  `wI` `:372` (**opcode `0010011` and funct3 `0#3` baked in**), `wB` `:378`
  (opcode `1100011` baked in).
- Twenty field lemmas, `:385–546` **[USE]** — `wR_f7`/`wR_rs2`/`wR_rs1`/`wR_f3`/
  `wR_rd`/`wR_op`; `wI_imm`/`wI_rs1`/`wI_f3` (states `= 0#3`)/`wI_rd`/`wI_op`
  (states `= 0b0010011#7`); `wB_i11`/`wB_i94`/`wB_rs2`/`wB_rs1`/`wB_f3`/`wB_i30`/
  `wB_i10`/`wB_op`.
- `SaltWorks.ISA.encode` `:549–557` **[USE]** — five cases onto the three layouts.
- `SaltWorks.ISA.decode` `:561–586` **[USE]** — three accepting branches:
  `opcode = 0110011 ∧ funct7 = 0` (funct3 ∈ {0,4,2}); `opcode = 0010011 ∧ funct3 = 0`;
  `opcode = 1100011 ∧ funct3 = 0`. Everything else `none`.

**`SaltWorks.ISA.decode_encode` — `ISA.lean:592` [USE]:** `∀ i : Instr, decode
(encode i) = some i`.

**Exactly what it covers:** the five constructors of `Instr`, i.e. the image of
`encode`. It says nothing about words outside that image, and nothing about any
layout that is not `wR`/`wI`/`wB`. **No S-type layout appears in it, because none
exists** (§2, O8).

Round-trip's neighbours, all **[USE]**: `encode_add_matches_manual` `:607`,
`encode_addi_matches_manual` `:612`, `encode_beq_matches_manual` `:618`,
`encode_injective` `:622`, `decode_rejects_lui` `:631`, `stepW` `:634`,
`stepT` `:687`, `stepT_compat` `:694`, `stepT_undecodable` `:700`,
`stepT_encode` `:705`, `stepT_nop_is_reachable` `:709`, `stepW_encode` `:718`.

The ratified totality fence sits at `ISA.lean:648–670` **[PROSE]**, with the
measured word-space split printed at `:664–665`:
`decodable 8,486,912 = 0.1976 %`, `undecodable 4,286,480,384 = 99.8024 %`.

### 1.7 What else in the tree consumes `St` — the blast radius map for §5

| name | file:line | tag | what it is |
|---|---|---|---|
| `SaltWorks.HDL.stWidth` | `StateCodec.lean:60` | USE | `32*32 + 32` = **1056** state bits |
| `SaltWorks.HDL.stBit` | `StateCodec.lean:76` | USE | bit `j` of the state under the frozen layout |
| `SaltWorks.HDL.encD` | `StateCodec.lean:81` | USE | `St → List Bool`, the D-root order |
| `SaltWorks.HDL.decQ` | `StateCodec.lean:84` | USE | `Env → St`, the Q-leaf decoding |
| `SaltWorks.HDL.decQ_encD` | `StateCodec.lean:97` | USE | the codec round-trip |
| the layout freeze | `StateCodec.lean:34,42–46` | PROSE | *"SILICON: this is the flop layout your Q-leaf/D-root treatment will see"* |
| `SaltWorks.ISA.Vec` | `Vectors.lean:43` | USE | differential-test vector: `pre`, `pc`, `word`, `post`, `pc'` — **no memory columns** |
| `SaltWorks.ISA.ofSparse` | `Vectors.lean:54` | USE | builds an `St` from a sparse register list |
| `SaltWorks.ISA.Vec.checkFull` | `Vectors.lean:72` | USE | full-state equality via `==` |
| `SaltWorks.ISA.spikeSuite` | `SpikeVectors.lean:140` | USE | the 120 witnessed vectors |
| `SaltWorks.ISA.sliceAExcluded` | `SpikeVectors.lean:530` | USE | 22 legal-RV32I words Slice A excludes — **`lw` `:536`, `sw` `:537`, `lb` `:538`, `sb` `:539`** |
| `slice_a_excluded_rejected` | `SpikeVectors.lean:558` | USE | `decode` rejects all 22, `decide +kernel` |
| `SaltWorks.Codegen.Stmt` | `CodegenSpec.lean:86` | USE | source language — `assign`/`seq`/`ite`, **no loop form** (`:83` PROSE) |
| `SaltWorks.Codegen.C3Statement` | `CodegenSpec.lean:161` | USE | conclusion includes `(run code st).pc = 4 * code.length` |
| `SaltWorks.Stack.SortsRegs` | `Stack/Spec.lean:329` | USE | **the register-level sort spec** |
| `Stack/Spec.lean:57–63` | | PROSE | *"Slice A has 32 registers and **no memory** … `n ≤ ~24`, and the program is a fully-unrolled fixed-`n` network"* |
| `SaltWorks.Stack.batcher8_sortsToV_word` | `Stack/Perm.lean:396` | USE | S3(a) at `n = 8` over `Word` — landed |

### 1.8 The hardware side — what the second consumer actually is

| name | file:line | tag | note |
|---|---|---|---|
| `SaltWorks.HDL.Seq` | `Seq.lean:52` | USE | `nIn`, `nOut`, `nState`, `core : Circ` — the Mealy shape |
| `SaltWorks.HDL.stepSeq` | `Seq.lean:71` | USE | one cycle |
| `SaltWorks.HDL.dcIn` | `Decoder.lean:68` | USE | **`= 32` — the decoder's inputs are the instruction word as PRIMARY INPUTS** |
| the projection argument | `Decoder.lean:40–56` | PROSE | control depends on the word only through opcode, funct3, and `funct7 = 0` |
| `we` | `RegWrite.lean:27` PROSE, `:61–63` USE | | `valid ∧ ¬isBEQ ∧ (rd = r) ∧ r ≠ 0` |
| the 99.80 % figure | `RegWrite.lean:35–36` | PROSE | `valid` is not defensive |
| immediate wiring | `Immediate.lean:55` (`immI`), `:79` (`immB`) | USE | zero gates / one gate |
| *"almost no gates and most of the risk"* | `Immediate.lean:11–20` | PROSE | a wiring block cannot fail a gate-level check |

**`compile` and `core` do not exist.** `grep -F 'def compile'` → **0 files**;
`grep -F 'def core'` → **0 files**; controls in the same batch: `grep -F 'def
step'` → 4 files, `grep -F 'structure St'` → 1 file, `grep -F 'BitVec 32'` → 9
files. Independently recorded at `docs/hdl-c4-composition-check-0807.md` §1
(silicon's F1, 8/6, *"still stands"*).

**Nothing in `SaltWorks/**` names a memory, a memory port, or a bus.** Batch with
controls: `def wS` → 0, `Mem` → 0, `.LW` → 0, `.SW` → 0; `mem :` → 1 file, all 19
hits are `have hmem :` in `Renumber.lean`; `LOAD` → 4 files, all the phrase
"LOAD-BEARING" or "PARTIAL LOAD"; `STORE` → 1 file, the phrase *"`x0` IS NOT
STORED"* at `ReadTree.lean:64`. Controls non-zero as above. **The negatives are
evidence.**

---

## §2 — WHAT RV32I LOADS/STORES NEED THAT IS ABSENT

Eight obligations. Each: the RV32I requirement, the current gap, and where the
change lands.

⚠️ **Provenance fence on this section.** The RV32I facts below are from
knowledge, **not read at source** — I did not have `src/unpriv/rv32.adoc` open
(read-only node, no network assumed). The fleet's own law is that external facts
are read at their source. **O5 and O6 in particular must be re-read there before
any freeze consumes this section.** Where an in-tree source exists I cite it
instead, and those are marked.

### O1 — A data memory in the state
**RV32I:** `LB/LH/LW/LBU/LHU` read and `SB/SH/SW` write a byte-addressed data
memory.
**Gap:** `St` (`ISA.lean:72`) has two fields, neither of them memory.
**Lands:** `St`; transitively `St.init` (`:156`), `stWidth`/`stBit`/`encD`/`decQ`/
`decQ_encD` (`StateCodec.lean:60,76,81,84,97`), `ofSparse`/`Vec`/`Vec.checkFull`
(`Vectors.lean:54,43,72`).

### O2 — Eight constructors
**RV32I:** five loads, three stores.
**Gap:** `Instr` (`:80`) has five constructors, none of them.
**Lands:** `Instr`, `step`, `encode`, `decode`, `decode_encode`.

### O3 — Effective-address arithmetic
**RV32I:** `addr = rs1 + sext(imm12)`.
**Gap:** none in substance — this is exactly what `.ADDI` already computes
(`step`, `ISA.lean:122`, `imm.signExtend 32`).
**Lands:** `step`'s new cases. **The cheapest obligation in this section, and the
only one that is genuinely free.**

### O4 — BYTE-vs-WORD addressing ⚠️ **a decision, not a gap**
**RV32I:** the data memory is byte-addressed; `LB`/`SB` address individual bytes.
**Current:** the instruction side is *already* byte-addressed —
`fetch` divides by 4 (`ISA.lean:132`) and the docstring pins it (`:128–130`). The
register file is word-only.
**The fork inside the fork:**
- `mem : … → BitVec 8` (byte memory) — `LB`/`SB` are free; every `LW` costs a
  four-piece assemble and every `SW` a four-piece split, plus the endianness
  ruling (O6) on each.
- `mem : Vector (BitVec 32) N` (word memory) — `LW`/`SW` are free; `LB`/`SB`
  cannot be expressed without a byte-select mux and a shift, **and Slice A has no
  shifts**.
**Lands:** `St` and every load/store case of `step`.
⚠️ **This is the sp1-lean failure's exact address.** The Ethereum Foundation
audit found `LH`, `LHU`, `LW`, `LWU` *"proved against byte-load semantics"* —
correct proofs of the wrong statement
(`docs/EVIDENCE-riscv-datapath-brief.md:211–213` **[PROSE, in-tree source]**).
**The census cannot make this choice; it can only say that making it late is how
the audited project got its haircut.**

### O5 — Alignment
**RV32I:** naturally-aligned accesses; misaligned behaviour is EEI-dependent and
may raise a load/store address-misaligned exception. *(From knowledge — re-read
at source.)*
**Gap:** the instruction side has an alignment gate whose failure mode is **halt**
(`fetch`, `ISA.lean:132`; demonstrated by
`SaltWorks.Codegen.frozen_offsets_halt_the_machine_misaligned`,
`CodegenSpec.lean:251` **[USE]** — the machine stops at `pc = 22` having written
nothing). There is no data-side analogue.
**Lands:** `step`'s new cases.
⛔ **And it re-opens the partiality fork one level down.** `step : St → Instr →
St` is **total and has no failure value**. A misaligned data access has nowhere
to go inside it unless the semantics *defines* somewhere — which is precisely the
shape of the `stepT` ruling (Captain-ratified 8/7, `ISA.lean:648–670`). Expect to
pay the same fence again, on a new axis.

### O6 — Endianness
**RV32I:** the base ISA is little-endian. *(From knowledge — re-read at source.)*
**Gap:** **nothing in the tree states an endianness at all**, because nothing
multi-byte exists. Note what does *not* settle it: `wR`/`wI`/`wB`
(`ISA.lean:368,372,378`) are **bit orders inside one word**, not byte orders in
memory.
**Lands:** `step`'s load/store cases; and, if the core ever gets a memory port,
`encD`'s byte order too.

### O7 — Out-of-range reads
**RV32I:** an access outside physical memory traps (excluded by the campaign's
R5).
**Gap:** with a total-function memory every address reads *something*; with a
`Vector` memory an out-of-range index needs a default (`getD`/`!`) or a proof
obligation. Neither exists.
**Lands:** `step`.
**Precedent and required fence:** identical in kind to the ratified NOP-advance.
Whatever is chosen — zero-fill, wrap, hold — needs a sentence of the strength of
`ISA.lean:651`: *"this is a deliberate v1 semantics, NOT RV32I behaviour."*

### O8 — ENCODING WORK the landed round-trip does **not** cover
Two distinct items, and the first is the one that is easy to under-price.

**(a) I-type is NOT already covered.** `wI` (`ISA.lean:372`) hardcodes **both**
the opcode and the funct3:

```lean
def wI (imm : BitVec 12) (rd a : Fin 32) : BitVec 32 :=
  imm ++ (ofReg a ++ (0#3 ++ (ofReg rd ++ 0b0010011#7)))
```

and its field lemmas state the constants — `wI_f3 … = 0#3` (`:487`), `wI_op … =
0b0010011#7` (`:503`). Loads are opcode `0000011` with a **varying** funct3.
*(Verified in-tree rather than from memory:* `SpikeVectors.lean:536` is
`0x00012083 -- lw ra, 0(sp)`, opcode `0000011`, funct3 `010`; `:538` is
`0x00410183 -- lb gp, 4(sp)`, funct3 `000`.*)* ⇒ **`wI` must be generalised to
take `(opcode, funct3)` as parameters and both lemmas restated**, with every use
in `encode` and in `decode_encode`'s `simp only` set riding along.

**(b) S-type does not exist.** `grep -F 'def wS'` → **0 files** (control:
`grep -F 'def step'` → 4 files). S-type is
`imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode` — a **split** immediate (two
contiguous pieces), not a scrambled one. The work is: one `wS` definition, six
field lemmas in the established pattern, one `decode` branch reassembling two
pieces, one `decode_encode` case.
**This is bounded, not research.** B-type is the harder cousin and it is landed:
`wB` (`:378`), eight field lemmas (`:510–546`), and the reassembly chain in
`decode_encode` (`:592–600`) — `repeat rw
[BitVec.extractLsb'_append_extractLsb'_eq_extractLsb' (by omega)]`. The S-type
reassembly is strictly easier than the one already proved.

**(c) And the word-space arithmetic moves.** *(ARITHMETIC, NOT KERNEL-CHECKED —
labelled as such, following `hdl-c4-composition-check-0807.md`'s own discipline.)*
Each load is I-type with 22 free bits (`rd` 5 + `rs1` 5 + `imm` 12); each store is
S-type with 22 free bits (`rs1` 5 + `rs2` 5 + `imm` 12).

```
today                                 8,486,912 / 2^32  =  0.1976 %   (undec. 99.8024 %)
+ LW, SW only        +2 × 2^22  =    16,875,520 / 2^32  =  0.3929 %   (undec. 99.607  %)
+ all 5 loads, 3 st. +8 × 2^22  =    42,041,344 / 2^32  =  0.9788 %   (undec. 99.021  %)
```

Every sentence carrying **99.80 %** must be recomputed: `ISA.lean:651`,
`:664–665`, `RegWrite.lean:35–36`, `docs/hdl-c4-composition-check-0807.md`
ADDENDUM, `docs/riscv-core-campaign-v0.md` §C4. *This fleet has already been bitten
by a number that propagated through three documents (the 13-day clock,
`EVIDENCE-stack-refuter-0807.md` §2).*

---

## §3 — THE FORK

### 3.1 The true shape, stated before the options

**The machine is neither Harvard nor von Neumann.** Harvard has two memories; von
Neumann has one. This machine has **zero**:

- **Data** lives in 32 registers (`St.regs`, `ISA.lean:73`) and nowhere else.
- **Code** is a Lean `List Instr` passed as an argument to `fetch`
  (`ISA.lean:131`) — a **host-language value the machine's state cannot name**.
  It is not memory, not words, and not part of `St`.

So `docs/stack-campaign-v0.md`'s S2 — *"assembled via `encode`: `List Instr` →
memory image"* — names a thing that has **no representation anywhere in the
tower**. Not a missing feature: a missing *type*.

Three options, not two.

### 3.2 Option (0) — NO MEMORY. S2 is register-resident.

**Cost to the landed theorems: ZERO.**

And the finding that moves this from "fallback" to "recommendation": **the S1/S3
lane has already built it.**

- `SaltWorks.Stack.SortsRegs` (`Stack/Spec.lean:329` **[USE]**) — *"the spec where
  the machine keeps its data"*: read the words at register addresses `rs` before
  and after. Landed, with `SortsRegs.unique` and a non-vacuity lemma.
- `Stack/Spec.lean:57–63` **[PROSE]** already states the design: *"Slice A has 32
  registers and no memory… The data therefore lives in registers, `n ≤ ~24`, and
  the program is a fully-unrolled fixed-`n` network."*
- `SaltWorks.Stack.batcher8_sortsToV_word` (`Stack/Perm.lean:396` **[USE]**) —
  S3(a) at `n = 8` over `Word`, landed.

This is exactly the evidence seat's constructive form
(`EVIDENCE-stack-refuter-0807.md` §1: *"a register-resident sort of ≤8 words…
matches the 8×8 banyan's width, and can ship while the memory model is built"*)
— **already half-executed, in the tree, kernel-checked.**

**What it costs the campaign, and it is one sentence:** S2's own text is wrong and
must be rewritten. There is no memory image; the assembler is `encode` over a
`List Instr`, which is what the differential harness already does
(`Vectors.lean:85` and following). `n` is capped at 8 (banyan-matched, and what
S3(a) has proved) up to perhaps ~24.

### 3.3 Option (A) — DATA MEMORY ONLY. `fetch` untouched.

**ISA side — bounded, named, pattern-following:**
`St` +1 field; `Instr` +8 constructors; `step` +8 cases; `encode`/`decode`/
`decode_encode` per §2 O8; `St.init` a default memory.

**What it breaks by name** (detail in §5): `slice_a_excluded_rejected`
(`SpikeVectors.lean:558`) goes **false**; the `Vec` format
(`Vectors.lean:43`) has no memory columns; `StateCodec`'s layout freeze
(`:40–46`, `:60–97`) reopens; `RegWrite`'s `we` needs `∧ ¬isStore`
(`RegWrite.lean:27,61–63`).

**What it does *not* touch:** `fetch` (`:131`), `runFor` (`:139`), `run`
(`:153`), and the forward-branch argument — none of them mention data.

**Silicon side — cheap in logic, and then it stops being cheap:**
- `Decoder.lean`'s one-hot set widens 5 → 13 and `valid` with it, but **the
  projection argument survives** (`Decoder.lean:40–56` **[PROSE]**): loads and
  stores dispatch on `opcode` + `funct3` too, so the 1024 + 1024 + 128-case
  certificates still exhaust what the logic depends on. **Genuinely cheap.**
- `Immediate.lean` needs an `immS` block — zero or one gate, and therefore the
  file's own named hazard (`:11–20` **[PROSE]**: *"a wiring block cannot fail a
  gate-level check because it has no gates to get wrong"*).
- ⛔ **And then the memory has to live somewhere.** If it is *state*, `stWidth`
  grows 8 bits per byte and the next-state array grows ~3 gates per bit
  (measured: 3 × 1024 muxes + 32 inverters = 3,104 gates for the 1,024 register
  bits — commit `22ea383`). **1 KiB = 8,192 flops + ~24,576 gates.** Against
  TinyTapeout's measured per-tile capacity — *"about 1000 digital logic gates"*
  and *"about 320 DFFs (40 bytes of memory)"*
  (`docs/tinytapeout-dossier.md:206–207` **[PROSE, quoting TT's own specs]**) —
  with the register file already at **992 stored flops**
  (`ReadTree.lean:79–83`). ⇒ **On-chip data memory is off the table above a few
  dozen bytes, for a measured reason.** If it is *not* state it is a **port**,
  and then `step : St → Instr → St` is no longer the semantics, because a load's
  result is not a function of `St` (§4, F3).

### 3.4 Option (B) — UNIFIED MEMORY. `fetch` reads `St.mem`.

Everything in (A), plus:

1. **`fetch` changes type and the run path acquires `decode`.** Today nothing in
   `runFor`'s path touches `decode` (§1.4). Under (B), `fetch` reads a
   `BitVec 32` from memory and must `decode` it — which drops the ratified
   NOP-advance semantics (`ISA.lean:648–670`) **inside the execution loop**, for
   every fetched word.
2. ⛔ **`run_halts_off_the_end` (`ISA.lean:301`) DIES.** With a memory image
   there is no "off the end": every address holds a word, zero decodes to
   nothing, and the ratified semantics says undecodable = `PC+4`. **The machine
   would run off into zero-filled memory advancing forever until fuel expires.**
   The halting behaviour that makes `run`'s bound *sufficient* is a property of
   `List Instr` indexing, not of the machine.
3. **`run`'s bound loses its referent.** `code.length` has no meaning without
   `code`. `run` needs an explicit fuel parameter — which the `runFor` docstring
   (`:137–138` **[PROSE]**) says was deliberately avoided: *"puts no fuel
   parameter in any theorem, because `run` supplies the bound itself."*
   Reintroducing it touches `:293`, `:301`, `:309` and
   `C3Statement` (`CodegenSpec.lean:161`), whose conclusion is literally
   `(run code st).pc = 4 * code.length`.
4. **A real assembler appears, and one genuinely new theorem with it:**
   `List Instr → memory image`, plus `fetch (image code) (4*i) = code[i]?` — which
   is `decode_encode` lifted through a memory layout. *That theorem is exactly
   what `decode_encode` was built to enable, so it is the one honest attraction
   of (B).*
5. **Silicon: single-cycle dies.** One memory port serving both fetch and
   load/store is a structural hazard; the core becomes multi-cycle. The campaign
   objective says *"Single-cycle v1"* (`docs/riscv-core-campaign-v0.md`,
   Objective). This is a campaign-level change, not a file-level one.

### 3.5 ⭐ RECOMMENDATION

> **(0) NOW. (A) when a consumer states an `N` that registers cannot hold.
> NOT (B) inside this campaign.**

- **(0) now**, because both the S1 spec and S3(a) are *already* register-resident
  and landed. S2 is unblocked **today** at `n = 8` with **zero** changes to any
  landed theorem, and the Aug-12 story survives intact.
- **(A) when needed**, because its cost is a bounded named list and it leaves
  `fetch`/`run`/the branch argument alone. The thing that actually gates it is
  **the C2 `Vec` format**, not the ISA — see §5D.
- **NOT (B)**, because it kills `run_halts_off_the_end`, reintroduces the fuel
  parameter the refuter pass removed, puts the 99.8 %-of-word-space NOP semantics
  inside the execution loop, and makes the core multi-cycle — for a benefit S2
  wants only as a *phrase*.

⭐ **So the campaign's gating question resolves as: S2's assembler story
changes, not `fetch`.** One sentence of `docs/stack-campaign-v0.md` is rewritten,
and nothing else moves.

---

## §4 — STATEMENT FORMS BOTH LANES CONSUME

Each candidate `St.mem` shape judged **simultaneously** against
**(i)** S2's program semantics (`run` over a program that loads and stores) and
**(ii)** the core's memory port (the hardware interface).

### F1 — `mem : BitVec 32 → BitVec 8` (total function, byte-addressed)
- **(i) S2 lane — BEST.** Total, no bounds obligations, and it is the datapath
  brief's own recommendation, in terms: *"`BitVec addrWidth → BitVec dataWidth`
  as a plain function, LNSym's `mem_separate'` disjointness pushed into `Nat`
  linear arithmetic and discharged by `omega` (axiom-clean) — not an SMT array
  theory"* (`docs/EVIDENCE-riscv-datapath-brief.md:151–156` **[PROSE]**).
- **(ii) Core lane — IMPOSSIBLE AS STATED.** `encD : St → List Bool`
  (`StateCodec.lean:81`) is a **finite** list of `stWidth` bits. A function-typed
  field has no finite bit encoding, so `encD` cannot be written and `decQ_encD`
  (`:97`) cannot be *stated* in its landed shape. Predicted also to break
  `deriving DecidableEq` (`ISA.lean:75`) and every whole-state `decide +kernel`
  certificate (see §6.2 — predicted, not verified).
- ⇒ **Serves one lane. FINDING, not a proposal.**

### F2 — `mem : Vector (BitVec 8) N` (finite byte array)
- **(i) S2 lane — workable, with friction.** Every access carries `i < N`; `step`
  is total, so out-of-range needs a default and therefore a fence (§2 O7).
- **(ii) Core lane — encodable.** `stWidth` becomes `1056 + 8N`; `stBit` gets a
  third region; `decQ_encD`'s proof gains a third case in the same pattern as the
  two it has.
- ⛔ **But the size that serves one lane does not serve the other.** `N = 64`
  → 512 extra flops (on top of 1056) and ~1,536 extra gates — more than a full TT
  tile's DFF budget (`tinytapeout-dossier.md:207`) for **64 bytes**, which sorts
  16 words. The register file already sorts 8 **with no new silicon at all**.
- ⇒ **Serves both lanes only at a size that serves neither application.**

### F3 — memory as a PORT, not a field: `stepM : St → Instr → MemResp → St × MemReq`
- **(i) S2 lane — WORSE.** `run` stops being a function of the program and the
  initial state; S3(b)'s invariants must thread a memory oracle, and
  `SortsRegs`-shaped specs (`Stack/Spec.lean:329`) become specs over traces.
  **Everything landed in `SaltWorks/Stack/**` is stated over `St`.**
- **(ii) Core lane — BEST.** It is exactly `Seq`'s existing shape
  (`Seq.lean:52`: `nIn`/`nOut`/`nState`; `stepSeq` `:71`). Memory lives off-tile,
  `encD`/`decQ` stay at 1056 bits, and it is the honest answer to the campaign's
  own **R4** (`riscv-core-campaign-v0.md`: *"TT pin budget for a CPU: what
  memory/debug interface fits the tile?"*).
- ⇒ **Serves one lane. FINDING.**

### F4 — TWO objects, bridged
`St.mem` for the ISA lane (F1), and the core's C4 statement quantified over a
memory-response stream with `encD` covering only `(regs, pc)`.
- **The only form that serves both**, and its price is stated plainly: the ISA
  `step` and the hardware `step` **stop being the same function**. C4's sentence —
  *"the state encoding of `SaltWorks.ISA.step` applied at the Q-leaves'
  decoding"* (`riscv-core-campaign-v0.md` §C4) — becomes a statement relating a
  Mealy machine to a memory-parameterised `step`, i.e. **a new composition
  obligation needing a new coercion pair**. That is exactly the class the C4
  composition check found *absent and on no manifest as owed*
  (`hdl-c4-composition-check-0807.md` §1, for `decQ`/`encD`).

### ⭐ §4 VERDICT

> **No single form serves both lanes.** F1 serves the ISA lane and is
> *unstateable* for the core; F3 serves the core and *dissolves* the landed Stack
> specs; F2 serves both only at sizes that serve no application.

**Recommendation:** **F0 — no `St.mem` at all for v1**, consistent with §3.5. If
memory must land, **F1 for the ISA lane with the explicit written statement that
the core lane does not consume it and gets F3 instead**, and **F4's bridging
obligation written down before either side is built** — which is the seam
doctrine this tree already paid for once
(`StateCodec.lean:27–33` **[PROSE]**: *"agree the interface BEFORE building…
the alternative makes the codec a description of whatever was built, which cannot
then catch a layout mistake"*).

---

## §5 — WHAT BREAKS

### A. The register-file laws — **ALL FIVE SURVIVE, unchanged**

`St.get_zero` (`:165`), `St.set_zero` (`:169`), `St.get_set_self` (`:173`),
`St.get_set_ne` (`:179`), `St.get_set_zero` (`:190`).

**Structural reason, not luck.** `St.get` (`:99`) and `St.set` (`:107`) mention
only `regs`; `St.set` is `{ s with regs := … }`, so a new field rides through the
`with` untouched; the proofs are `simp [St.get, St.set]` plus
`Vector.getElem_set_ne`. Nothing in any of the five mentions the number of fields.

⚠️ **Caveat, and it is not pedantry:** they survive as *statements*. Whether they
still **elaborate** depends on `St` retaining the instances the file needs — see
§6.2 on `deriving DecidableEq`, which I could not verify without building.

### B. `run`'s `code.length` sufficiency

- **Under (0) and (A): untouched.** `fetch`/`runFor`/`run` never mention data.
- **Under (B): dead**, three ways — §3.4 items 2 and 3.
- **And independently of memory: it was never proved.** See C.

### C. ⭐ THE FORWARD-BRANCH PRECONDITION — **ASSUMED, NOT ENFORCED**

**Verdict: ASSUMPTION. Verified, with the specific negatives run under control.**

1. **It is prose and nothing else.** `ISA.lean:149–152`, the docstring of `run`
   (`:153`). No hypothesis on `run`; no `Forward`/`NoBackwardBranch` predicate
   anywhere in `SaltWorks/**`; no theorem `n ≥ code.length → runFor n code s =
   run code s`.
2. **The machine can violate it, and the tree proves so on purpose.**
   `beq_offset_can_be_negative` (`ISA.lean:281` **[USE]**, `decide +kernel`) — a
   backward branch executes correctly.
3. **What actually discharges it today is the *source language*, not the
   machine.** `SaltWorks.Codegen.Stmt` (`CodegenSpec.lean:86`) has
   `assign`/`seq`/`ite` and **no loop form**; the docstring at `:83` **[PROSE]**
   says so and says why: *"No `while` — the freeze's largest scoping decision, and
   it is what makes `srcSem` structural and the machine bound `code.length`."*
   ⇒ **The assumption holds for code-generator output because the source language
   cannot express a loop. It is discharged nowhere at all for hand-written
   assembly.**
4. ⛔ **AND HERE IS THE TRAP FOR S2, which matters more than the missing
   hypothesis.** If an agent-written program branches backward, `run` does not
   fail, warn, or return `none`. `runFor` exhausts its budget and returns the
   state it happens to be in — **type-identical to a completed run.**
   `run_halts_off_the_end` (`:301`) certifies that a program which *does* finish
   stops. **Nothing certifies that a returned state means finished. A silently
   truncated run and a completed run are the same value.**
5. **Consequence for the recommended S2:** a fully-unrolled register-resident
   Batcher is straight-line or forward-branching only (the evidence seat's
   compare-exchange scheme, `EVIDENCE-stack-refuter-0807.md` §5), so the
   assumption *holds* — **by construction of the program, checked by nobody.**
6. **The cheapest fix, available today, no memory work involved:** a decidable
   `Bool` predicate on `List Instr` saying every `BEQ` immediate is non-negative,
   plus the theorem that under it `runFor n code s = run code s` for
   `n ≥ code.length`. That is the missing object. It is out of scope for a
   read-only census; it is the top handoff item (§6.7).

### D. Landed theorems that break if load/store are added — **decoder, not state**

These break under **(A) or (B) equally**, and they break even if `St` never gains
a field, because they are about `decode`:

| what | where | why |
|---|---|---|
| ⛔ `slice_a_excluded_rejected` | `SpikeVectors.lean:558` | **becomes FALSE** — 4 of its 22 words (`lw` `:536`, `sw` `:537`, `lb` `:538`, `sb` `:539`) would decode |
| `rejected_disjoint_from_suite` | `SpikeVectors.lean:569` | survives only if the 4 rows are *removed*, not merely re-labelled |
| `slice_a_excluded_size` | `SpikeVectors.lean:574` | survives as arithmetic; its *meaning* changes |
| `suite_words_decode` | `SpikeVectors.lean:565` | survives |
| every 99.80 % / 0.1976 % figure | `ISA.lean:651,664–665`; `RegWrite.lean:35–36`; `hdl-c4-composition-check-0807.md` ADDENDUM; `riscv-core-campaign-v0.md` §C4 | recomputed in §2 O8(c) |
| `we` | `RegWrite.lean:27,61–63` | needs `∧ ¬isStore` — stores have no `rd` |
| `Vec` / `checkFull` | `Vectors.lean:43,72` | the format has no memory columns |
| `stWidth`/`stBit`/`encD`/`decQ`/`decQ_encD` and the layout freeze | `StateCodec.lean:60,76,81,84,97`, `:40–46` | any new `St` field reopens a bit-exact freeze |
| **NOT broken:** the decoder projection | `Decoder.lean:40–56` | loads/stores dispatch on opcode + funct3, already inside the projection |

⭐ **The item worth carrying out of §5:** fixing `slice_a_excluded_rejected`
means moving four rows from "rejected" into the witnessed suite **with
Spike-confirmed post-state — including memory**, which the `Vec` format cannot
express. ⇒ **The C2 differential harness, not the ISA, is on the critical path of
any memory work.** That is not where anyone has been looking.

---

## §6 — WHAT I COULD NOT DETERMINE

Not optional, and this is where the next seat's work comes from.

**6.1 — I could not determine the core's memory-port requirements, because the
core has no memory port and there is no `core`.**
`compile` and `core` have **zero declarations** in the tree (grep with non-zero
controls, §1.8; independently recorded at `hdl-c4-composition-check-0807.md` §1).
What exists is four blocks — `Decoder`, `RegWrite`, `Immediate`, `RegNext` — plus
`StateCodec`, and **none has a memory interface**. So §4's second consumer was
judged against *constraints* (`encD`'s finiteness, `Seq`'s `nIn`/`nOut`, TT's
flops-per-tile), not against a port. **The honest answer to "what does the core's
memory port require" is: it does not exist yet, and the constraint that will
decide it is flops-per-tile, not proof shape.**

**6.2 — Whether `deriving DecidableEq` (`ISA.lean:75`) survives each candidate
`mem` field. NOT VERIFIED — this node ran no build.**
F1 (function type) is **predicted to break it**: `ISA.lean` imports only
`SaltWorks.Tactic.AuditAxioms`, so no mathlib `Fintype`-based `DecidablePi`
instance is in scope, and even in scope it would be 2^32 cases. F2 (`Vector`) is
predicted fine. **Both are predictions. A three-line `Scratch` probe settles them
in a minute and should run before anything is written.**

**6.3 — Whether `decide +kernel` stays feasible on a state carrying memory.**
The brief's `[V-ME]` measurement is at 32 registers (2,048 cases, 2.4 s). Nothing
measures a `Vector (BitVec 8) N` field inside a whole-state `decide +kernel`
comparison, and this tree has **two measured O(n²) walls at core scale**
(`RegNext.lean:36–48`: `Circ.wf`'s `nodupB`, and `sem`'s per-output list walk).
**Unmeasured. Do not assume it scales.**

**6.4 — Whether my RV32I facts in §2 O5/O6 are right.**
I did not have `src/unpriv/rv32.adoc` open. "Misaligned behaviour is
EEI-dependent" and "the base ISA is little-endian" are from knowledge, and this
fleet's law is that external facts are read at their source. **Re-read before any
freeze consumes §2.** (The opcode/funct3 values I quote *are* source-grounded —
they are read off `SpikeVectors.lean:536–539`, which are assembler output
confirmed executable by Spike.)

**6.5 — Whether the `n ≤ ~24` ceiling in `Stack/Spec.lean:57–63` is right.**
It is prose in another seat's file and I did not check it against an actual
compare-exchange schedule. The evidence seat's scheme
(`EVIDENCE-stack-refuter-0807.md` §5) needs `c`, `neg1`, `mask` and at least one
temp live at once, so the true ceiling may be nearer 24 than 30 — **but I did not
count it, and the number matters exactly when someone asks for an `N`.**

**6.6 — Whether S2 needs more than 8 elements. NOBODY HAS STATED THE `N`.**
`stack-campaign-v0.md` says "Batcher sort" without one. `n = 8` matches the 8×8
banyan and is what S3(a) has landed. **If a consumer wants `n = 16`, the register
file is out and option (A) becomes mandatory the same day.** The entire urgency
of §3's fork rests on a number no document contains.

**6.7 — The forward-branch object is not built, and I could not build it.**
§5C names it: a decidable no-backward-branch predicate plus
`n ≥ code.length → runFor n code s = run code s`. **Without it, "the program
finished" is not a checkable claim about any `run`.** Whether that theorem is
routine or awkward — in particular whether the `pc`-strictly-increases argument
survives `BitVec 32` wraparound near the top of the address space — **I did not
attempt and cannot report.**

**6.8 — The `AND` question is not mine but it collides here, and the two
decisions should be taken together.**
`EVIDENCE-stack-refuter-0807.md` §5 measured that **one** missing primitive —
`AND` — makes compare-exchange branch-free: *"one constructor, one `sem` case,
one `encode`/`decode` case, one round-trip case."* **A branch-free S2 has no
branches at all**, which discharges §5C's assumption *completely* rather than by
construction of a particular program. I did not price `AND` — it is not this
census's node — but **it looks like a cheaper way to buy the same safety than any
memory work**, and deciding memory without deciding `AND` decides them in the
wrong order.
