# C4 — THE `core` ASSEMBLY PLAN, AND THE ORGANS THAT DO NOT EXIST

### 2026-08-07, compiler seat (compiler-acct). Written after the assembly THEORY closed.

**Status of this document: a PLAN and a GAP CENSUS, not a construction.** Every
number in it was measured today; every `ssa`/`wf` claim is a landed theorem, not
a citation. *It exists because reading `AluSelect.lean`'s input layout before
building the datapath turned up **six** blocks that are not in the tree — and
finding that by reading is much cheaper than finding it at assembly time.*

⚠️ **FOUR OF THOSE SIX WERE BUILT AND LANDED WITHIN THE HOUR (`Bitwise.lean`), so
the counts below are REGENERATED and not original.** *A census that keeps its
first number after the number has moved is the exact defect this campaign has
found four times today — and it would be especially cheap to commit in the
document whose whole subject is missing pieces.* **Live count: 8 found, 6 closed; 0 open builds, 1 silicon decision (`sll`/`sra`).**

---

## 0. WHY THIS IS WRITTEN NOW

The assembly's **theory** is complete (`f49b5a4`, `5868b9f`):

```
Circ.wf_of_ssa           ssa -> wf, so a core-sized side condition is reachable
instGates_eq_renumFrom   the embedded gate list IS a renumFrom
inst_sem                 an instantiated block computes what the block computes
inst_compose_*           two blocks at off / instNext compose, neither disturbing
                         the other
```

⇒ **What remained was called "a construction, not a lemma."** *That was true and
incomplete: it is a construction whose inputs are not all present.*

---

## 1. THE INTERFACE, FIXED BY `StateCodec` AND NOT NEGOTIABLE HERE

`StateCodec.lean` fixed the layout FIRST, deliberately, so that `core` conforms to
the codec rather than the codec describing whatever got built:

```
core.nIn         = coreInWidth = 1088     state 0…1055, instruction word 1056…1087
core.outs.length = stWidth     = 1056     next state, in encD's order
                                          regs r bit k at 32*r + k ; pc at 1024+k
```

**Both constants are landed theorems** (`coreInWidth_value`,
`instrBase_is_above_the_state`). *`core` is required to conform; a mismatch is a
defect in `core`, never in the codec.*

---

## 2. ORGAN CENSUS — measured today, every row a landed theorem

| organ | gates | nIn | outs | `ssa` | `wf` | landed |
|---|---|---|---|---|---|---|
| `decoder` | 102 | 32 | 6 | ✅ | ✅ | prior |
| `regWrite` | 163 | 7 | 32 | ✅ | ✅ | prior |
| `immICirc` | 0 | 32 | 32 | ✅ | ✅ | prior |
| `immBCirc` | 1 | 32 | 32 | ✅ | ✅ | prior |
| `pcNext` | 99 | 97 | 33 | ✅ | ✅ | prior |
| `readTree` | 2,982 | 997 | 32 | ✅ | ✅ | **today** |
| `regNext` | 3,104 | 1,088 | 1,024 | ✅ | ✅ | **today** |
| `aluSelect` | 1,445 | 324 | 32 | ✅ | ✅ | **today** |
| `adder32` | 160 | 65 | 33 | ✅ | ✅ | **today** |
| `shifter32` | 486 | 37 | 32 | ✅ | ✅ | **today** |

**Every organ in the tree is dense SSA**, so every one satisfies `instOK`'s first
clause and is safe to embed. ⭐ **`regNext` and `readTree` had NO well-formedness
certificate at all before today** — `readTree.lean` carried no theorems whatever —
and `regNext.wf` was **unreachable by `decide +kernel`** (`EXIT=134` at `-M 20000`;
see the differential in `RegNext.lean`).

⚠️ **ONE EXCEPTION, FLAGGED: `inc32.ssa = false`.** *It is the only `Circ` in the
tree that is NOT dense, so it cannot be instantiated by `instGates` without
`normalize` first. It is not currently on `core`'s path — but a successor
reaching for it will find `instNext` silently under-reporting, which is exactly
the failure `Compose.instNext_under_reports_without_ssa` witnesses.*

---

## 3. ⛔ THE GAP — `aluSelect` NEEDS TEN OPERAND RESULTS; SIX HAD NO PRODUCER, FOUR NOW DO

`AluSelect.lean:56` is explicit: *"Ten op results: add, sub, and, or, xor, slt,
sltu, sll, srl, sra"*, at `asRes r k = r*32 + k`, plus four select bits. **It is a
pure mux tree. It computes none of its inputs.**

| # | result | producer | status |
|---|---|---|---|
| 0 | add | `adder32` | ✅ exists |
| 1 | sub | `adder32` on `(a, ~b)` with carry-in 1 | ✅ **`bitNot32` LANDED** |
| 2 | and | `bitAnd32` | ✅ **LANDED** |
| 3 | or | `bitOr32` | ✅ **LANDED** |
| 4 | xor | `bitXor32` | ✅ **LANDED** |
| 5 | slt | `sltCirc` | ✅ **LANDED** |
| 6 | sltu | `sltuCirc` | ✅ **LANDED** |
| 7 | sll | — | ⛔ **MISSING** — see below |
| 8 | srl | `shifter32` | ✅ exists |
| 9 | sra | — | ⛔ **MISSING** — see below |

**⇒ FOUR OF THE SIX CLOSED THE SAME DAY THIS CENSUS WAS WRITTEN**
(`SaltWorks/HDL/Bitwise.lean`): `bitAnd32`, `bitOr32`, `bitXor32` (the three
pointwise ALU results) and `bitNot32` (which is what makes `sub` out of
`adder32`). *All four `ssa`+`wf` by the structural route, correctness sampled
against `BitVec`'s own operations over the campaign's word spread, with a
distinctness control — they are built by ONE constructor, so the live risk was
that a proof about `and` is silently a proof about `or`, and
`bw_blocks_are_distinct` says each block FAILS the other two's specifications.*

**WHAT REMAINS IS TWO KINDS, and neither is pointwise:** `slt`/`sltu` are
DERIVED (from the adder's sign and carry-out — cheap, but they need `adder32`'s
output layout read rather than assumed), and `sll`/`sra` are the shifter-mode
question below, which is a decision rather than a build.

🔴 **`shifter32` HAS NO MODE INPUT.** `nIn = 37 = 32 data + 5 shamt`, and its own
docstring gives one equation: `out[i] = shamt[j] ? in[i + 2^j] : in[i]`. ⇒ ***It
is ONE direction, logical only.*** **`sll` and `sra` are two more organs, not two
more instances of this one** — unless `shifter32` is generalised with a mode bit,
which is a change to a landed, certified block and therefore a decision rather
than a detail.

📌 **THE SHAPE, AND IT IS THIS FILE'S REASON FOR EXISTING: `aluSelect` was built,
certified and landed as a SELECT — and a select over sources nobody has built is
100% complete and 0% usable.** *Same family as "there was no `Circ` composition
operator" (8/7 morning) and "`ceC` was a price, not an element" (8/7 afternoon):
**a component that satisfies its own specification exactly, while the thing it is
a component OF cannot be assembled.*** ⇒ **Three instances in one day. The
common cause is that our certificates are per-organ and nothing checks the
JOIN.**

---

## 4. THE ASSEMBLY ORDER, once §3 is filled

`instOK` requires every input wire `σ i < off` — so the order is forced by data
dependency, and each organ sits at the previous `instNext`:

```
off_0 = 1088                    (= coreInWidth; state and instruction below it)

 1  decoder     reads instr                                    102
 2  immBCirc    reads instr                                      1
 3  readTree×2  reads instr (rs1/rs2 fields) + state regs     5,964
 4  bitwise     and / or / xor over rs1,rs2                       96   ✅ LANDED
 5  bitNot32    invert b, for sub                                 32   ✅ LANDED
 6  adder32×2   add, and sub via (a, ~b, cin=1)                  320
                 ⛔ NOTE: these are the ALU's.  NO adder is allocated to the
                 PC PATH below, and that is the defect silicon refuted.
 7  sltCirc/sltuCirc  from sub's sign and carry                    7   ✅ LANDED
 8  shifterM    ONE mode-generalised organ: sll / srl / sra       679  (route ②)
 9  aluSelect   muxes the ten                                  1,445
10  regWrite    reads instr rd field + decoder                    163
11  pcAdd       THE PC PATH, COMPOSED AND LANDED (math, 0fb2d39):
                pcNext + an INSTANTIATED adder32 at offset 229.
                sem_pcAdd is unconditional over all 2^129 inputs.
                Replaces the bare pcNext; do NOT wire pcNext direct.  260
12  regNext     we <- regWrite, res <- aluSelect, cur <- state  3,104

core.outs = regNext's 1,024 ++ THE PC ADDER's low 32    = 1,056 = stWidth
            ^^^^^^^^^^^^^^^^^^ NOT pcNext's: pcNext emits the ADDEND
```

🔴 **THIS LINE IS REFUTED (silicon, `cefd93e`) AND THE PLAN IS WRONG AS WRITTEN.**
`pcNext` has **no pc input** (`PcNext.lean:63-67`: rs1, rs2, off, isBEQ — 97
nets, and the program counter is not among them) and `pcSpec` returns
`if take then off else 4`: ***an ADDEND, not a sum.*** ⇒ **Wiring `pcNext`'s
output straight onto `encD`'s pc field sets `pc' := 4` on every non-branch
instruction and `pc' := offset` on a taken branch** — *a machine that executes
instruction 1, then instruction 1, forever.*

✅ **THE FIX: the pc path needs an ADDER between `pcNext` and the pc field**, with
`pc` as one operand and `pcNext`'s output as the other. **`inc32` is not it
either — `incIn = adW = 32`, the word and nothing else, so there is NO ADDEND
PORT — and the pc path wants an `adder32` instance of its own, a THIRD one, with
the plan's gate total moving accordingly.** *`inc32` stays unreferenced after
assembly, for an architectural reason: `pcNext` SELECTS the addend, so a
select-then-add path needs one VARIABLE adder and has no role for a constant `+4`.*

📌 **AND THE JUSTIFICATION THAT RETIRED `inc32` WAS MINE AND WAS FALSE:** I cited
`pcNext_not_beq_adds_four` as evidence that `pcNext` increments. *It proves the
OUTPUT EQUALS 4.* ⇒ ***A theorem's NAME read as its STATEMENT — corrected in
`Adder.lean`.***

**TOTAL, re-derived on both accepted decisions rather than carried:**

```
plan of record (before either)                    ~12,700
route ② — shifter mode, accepted 15:50 fcea207       −779   (1,458 → 679)
pcNext (99) → pcAdd (260), MEASURED by math          +161
                                                  ────────
                                                  ~12,082
```
⚠️ **The pc delta is `+161`, not the `+160` I derived from `adder32.gates.length`
— `pcAdd` measures **260** and `pcNext` is **99**, so the composition costs one
gate of glue. *Taken from math's measurement rather than from my arithmetic on
the parts, because the parts are not the artifact.*
*Silicon's C5 amendment said ~12,060 from a rounded chain. My own first
derivation said 12,081 from `adder32`'s gate count. **Both were computed from
parts; 12,082 is computed from the landed block.***

🔴 **AND MATH'S `addend_as_pc_is_wrong_unless_pc_zero` EXPLAINS WHY THIS DEFECT
SURVIVED A DESIGN, A PLAN AND TWO SEATS' READING: the broken wiring agrees with
`stepT` EXACTLY AT `pc = 0`.** ⇒ ***A smoke test from reset would have PASSED.
The defect was invisible to precisely the test anyone runs first, and correct on
precisely the first cycle.***

⚠️ **`pcNext.outs.length = 33`, not 32** — 32 addend bits plus the take flag.
*Both go to the PC ADDER (the addend as one operand, the flag nowhere yet), and
it is the ADDER's low 32 that reach `core.outs`.* **`adder32.outs.length = 33`
too — 32 sum bits plus carry-out — so the same off-by-one lives at the new organ
as well, and a positional `outs` list cannot catch either by type.*

---

## 5. WHAT THIS DOES **NOT** SAY

* It does not say `core` is nearly done. **Every missing BUILD is now landed;
  what remains is one DECISION** — `sll`/`sra` need a shifter mode `shifter32`
  does not have, which is a change to a landed certified block and therefore
  silicon's call, not mine. *(Six were missing when this was written and closed
  the same day; this line is regenerated, not original — see §3.)*
* It does not certify any wiring. **No `σ` in §4 has been written or checked.**
* It does not settle C4's own statement, which still owes math's
  **`DeliversProgram`** hypothesis (`run` takes the program as an argument;
  `stepT` takes a fetched word on `instrNet`, and nothing yet says where that word
  comes from) and **`EntryLoaded`**.

⇒ ***The honest summary: C4's assembly is no longer blocked on THEORY, and is
now blocked on ONE SHIFTER DECISION and four statement hypotheses — all named,
none open research, and no unbuilt block on the critical path.***

---

## 6. STATEMENT OBLIGATIONS, as they stand tonight

```
netlist half         DISCHARGED, generically -- math's chain, verified at the
                     signature: emitPipeline'_sem takes `wf` as its ONLY
                     hypothesis and is fully general in `c`, so Circ.wf_of_ssa
                     feeds it directly.  The theorem was never missing; its
                     hypothesis was unreachable at scale.
C4's remaining form  sem (compile core) ins
                       = encD (stepT (decQ ins) (wordOf (fun k => ins (instrBase + k))))
owed as hypotheses   (compile core).ssa = true            -- checked structurally
                     (compile core).outs.length = 1056     -- BOTH sides are
                       `List Bool` at any length, so a 1055-output core is a
                       well-typed FALSE theorem and nothing notices
                     DeliversProgram                       -- math, 14:07
                     EntryLoaded                           -- math, 13:48
```
