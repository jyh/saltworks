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

## 3.5. ⛔ TWO BLOCKS ON THE CRITICAL PATH THAT DO NOT EXIST

**Found by math 8/7 19:59 (§3), re-verified here at the bytes before acceptance.**
*§3's table has TEN rows — one per operand **RESULT** — and no row for
`aluSelect`'s four **CONTROL** inputs. The census counted the data side and
omitted the control side, and that is how both of these hid.*

### ① THE ALU-SELECT ENCODER — nothing drives `aluSelect`'s select bits

```
AluSelect.lean:67   asSel j = asOps * asW + j = 320 + j      ← INPUT nets (asIn = 324)
                    consumed at :96 (asNot) and :105 (asMux)
Decoder.lean:128    decoder.outs = [isADD, isXOR, isSLT, isADDI, isBEQ, valid]
                    FIVE one-hot CLASS signals — NOT an encoded ALU op
grep asSel outside AluSelect.lean → only Stack/Program.lean, which PROVES ABOUT
                    aluSelect and drives nothing
```
⇒ ***A block converting five one-hot class signals into four select bits is not
in the tree, and no §4 row allocates one.***

📌 **It is CHEAP — slice A's demand set is three slots — but the encoding is
where a wrong map would be well-formed and wrong.** ⚠️ ***The bit ORDER must be
READ from `asPrev`/`asLeafOf`/`asLevelWidth`, never assumed***: the tree consumes
`asSel 0` at width 8 and `asSel 3` at width 1, so which `j` is the LSB is a fact
about the tree, not a convention. **No number is published here because none has
been measured.**

### ② THE OPERAND-B PATH FOR `ADDI` — nothing muxes rs2 against the immediate

```
ISA.lean:121   ADD  rd a b   => s.get a + s.get b
ISA.lean:122   ADDI rd a imm => s.get a + imm.signExtend 32
```
⇒ ***`adder32`'s `b` port must carry `readTree`'s rs2 output OR `immICirc`'s 32
wires, and NOTHING SELECTS BETWEEN THEM.*** §4 allocates exactly two `adder32`s
and no mux. **97 gates** — `32 × 3 + 1`, silicon's arithmetic from the shifter's
reversal banks, *which supersedes my own "~96, derived from `asMux`'s shape": the
`+1` is the shared inverter and their basis is measured where mine was inferred.*

⏳ **AND BLOCK ② MAY STOP BEING A BLOCK AT ALL — CONDITIONAL, NOT YET TRUE.**
*Math proposed at 21:18 parametrising `sem_aluSelect` over the source count `n`
(it currently threads literals `329 + 45k + 42`, `pfr (320+j)`, `< 324`, with
level 3 baked into the lemma NAMES). **If that lands, silicon's `n = 2` row IS
this mux** — and I checked the identity rather than relaying it:*
```
asMux            = 3 gates: .and (prev even) (¬sel) · .and (prev odd) (sel) · .or
genSelect 2 1    = 96 (muxes) + 1 (inverter) + 1 (pad constant)  = 98   ⬅ CORRECTED
operand-B mux    = 32 × 3 + 1 (shared inverter), bespoke          = 97
```
🔴 **CORRECTED 8/7 22:0x — the row above read `97` and the generator is `98`.**
*Math found it, silicon confirmed at `AluSelect.lean:101-108`: the pad constant
`⟨asZero, .const false⟩` is **prepended UNCONDITIONALLY**, so silicon's `[n < pad]`
term described what a shrunken generator WOULD do, not what the code does. At
`n = 2^b` the constant is still emitted — it is simply DEAD.*

⇒ ***The BLOCK-IDENTITY claim stands and "exact to the gate" is STRUCK: the
generator is ONE GATE WORSE than a hand-built 2:1 mux, and only at exact powers
of two.*** **It would still INHERIT the proof shape rather than need its own —
which is the load-bearing half — at a cost of one dead constant.**
📌 *The `97` for the bespoke operand-B mux above is UNAFFECTED and stands. Two
different objects, one gate apart, and the plan now names both.*
⚖️ **AND THE HEADLINE SIZING IS UNMOVED: `10 → 3` is still `−1,154`, because
`3 < 4` means the constant IS charged at both ends.** ⚠️ **STATED AS A CONDITIONAL BECAUSE THE PARAMETRISATION IS NOT DONE —
math is holding for the maestro's word. Until it lands, block ② is unbuilt and
owes 97 gates and a proof.** *Recorded here because it changes what the sizing
ruling is choosing between: not "1,154 gates against re-proving an organ", but
"…against re-proving an organ that would ALSO discharge one of the two blocks on
the critical path."*

📌 **And `immICirc` is BUILT AND WIRED TO NO ONE** — `grep` outside
`Immediate.lean` returns nothing. *The block exists; the path does not.*

### ⭐ WHY BOTH OF THESE EXIST — a property of the METHOD, not of any seat

**Silicon, 8/7 20:12, from `AluSelect.lean:18-24` — which is a CONE-WIDTH table,
and the cone budget is theirs:**
```
| ALU op select, one-hot  | 20 |   10 op results + 10 select lines
| ALU op select, encoded  | 14 |   10 op results +  4 select bits
:61  asSelBits = 4 — "the seat's measured saving over a one-hot ten."   ← MY note
```
🔴 ***The encoding was chosen to cut `aluSelect`'s cone width from 20 to 14 — the
≤ 24 ceiling the whole C4/C5 decomposition rests on — and its cost is an ENCODER
OUTSIDE THE ORGAN, which no cone budget counts.*** **The saving is real inside
the organ and the bill is posted where the instrument cannot read it.**

⇒ **THIS IS THE *CAUSE* OF THE `C5-5` FAMILY RATHER THAN ANOTHER MEMBER:**
```
aluSelect  encoded select    saves cone width 20→14   needs an ENCODER       unbuilt
pcNext     addend-select     saves one adder          needed an ADDER        was unallocated
ADDI       operand B         —                        needs a 2:1 MUX BANK   unbuilt
```
***A per-organ budget creates pressure to push complexity across the organ
boundary, and the budget is structurally blind to exactly what crosses.***

📉 **AND IT INVERTS THE GATE DIRECTION POSTED AT 19:5x.** Slice A removes 679;
these two add it back:
```
~11,403  +  97 (operand-B mux, measured basis)  +  encoder (UNPRICED)  ⇒  ~11,500+
```
📐 **AND THE `aluSelect` SIZING IS NO LONGER UNPRICED — silicon measured it
(`79bb72a`, 8/7 20:53), and the reason it sat unmeasured for six hours is that
the quantity everyone was reaching for DOES NOT EXIST:**
```
gates(n) = 32×(pad−1)×3 + ⌈log₂ n⌉ + [n < pad],  pad = 2^⌈log₂ n⌉

n    pad  gates    Δ vs 10
10    16  1,445       —     as built
 9    16  1,445       0     ⚠️ a source can cost NOTHING
 8     8    675    −770
 3     4    291  −1,154     ⭐ SLICE A'S ACTUAL DEMAND {add, xor, slt}
 2     2     97  −1,348     = the ADDI operand-B mux, EXACTLY
```
🔑 ***There is no per-source cost. It is a STEP FUNCTION on the doubling — a
source costs 0 gates seven times in ten and 770 once*** — which is precisely the
shape that defeats an eyeball estimate, and why two attempts to make one produced
nothing. ✅ **Cross-checked at two independent points before use: `n = 10`
reproduces the 1,445 recorded at `:64`/`:151`, and `n = 2` reproduces the 97
above — a number derived hours earlier by a completely different route.**

⚖️ **BOTH COLUMNS ARE NOW PRICED, AND I AM STILL NOT RULING:**
```
SHRINK 10 → 3   −1,154 gates    COSTS: sem_aluSelect is NOT parametric — literals
                                 (329 + 45k + 42, pfr (320+j), < 324) and level 3
                                 baked into lemma NAMES. It does not transfer, and
                                 neither does aluSelectCut.
KEEP 10         ~1,154 dead      COSTS: nothing. The organ is proved unconditional
                gates            over 2^324 and its dead slots are provably INERT.
```
⚠️ **AND SILICON'S OWN COMPARISON IS THE ONE THAT SHOULD REACH WHOEVER RULES:
route ② was ACCEPTED at 15:50 for saving 779 gates; dropping `aluSelect` 10 → 8
saves 770 — within nine gates — and was dismissed in one clause as unmeasured.**
*That asymmetry was not judgement; it was an artefact of one number existing and
the other not.* **Silicon's block, my plan, the maestro's call.
```
*The encoder stays unpriced: it is small, nobody has a measured basis, and
inventing a coefficient is the error three seats have now refused today.*

🔑 **BOTH ARE THE `C5-5` FAMILY AGAIN, AND BOTH ARE WORSE THAN THE FOUR ALREADY
LOGGED:** *`instOK` forbids a dangling input, so the assembly MUST map these
somewhere — and a wrong map stays well-formed, stays `ssa`, and passes every
certificate that does not select the mis-fed slot.* ⛔ **The difference is that
the earlier four were mis-WIRINGS of blocks that exist. These two blocks do not
exist at all, so there is nothing to mis-wire yet — which is exactly why a census
of landed organs could not see them.**

## 5. WHAT THIS DOES **NOT** SAY

* It does not say `core` is nearly done. ⛔ **AND THE "ONE DECISION" THIS BULLET
  USED TO NAME — the shifter mode — IS NOT ON SLICE A'S PATH AT ALL.**

  > 🔴 **CORRECTED 8/7 ~20:0x. Math measured the DEMAND side from `Instr`, not
  > from the mux; silicon re-scoped their ruling (`744a120`); I am correcting the
  > plan that carried the claim.** `Instr` has **five** constructors and its own
  > docstring says *"no shifts"*; `decode` rejects `funct7 = 0100000` and sends
  > `SLL`/`SRL`/`SRA` to `none`.
  > ```
  > ADD  -> slot 0 add     ADDI -> slot 0 add     XOR -> slot 4 xor
  > SLT  -> slot 5 slt     BEQ  -> writes no register (we = 0)
  > garbage (99.8 % of words) -> we = 0
  > ⇒ SLICE A'S DEMAND SET IS {0, 4, 5}
  > ```
  > **Slots 1 `sub` · 2 `and` · 3 `or` · 6 `sltu` · 7 `sll` · 8 `srl` · 9 `sra`
  > are UNREACHABLE — including `srl`, so `shifter32` is off the path ENTIRELY,
  > not merely its two missing modes.**
  >
  > 🔑 **And the don't-cares are a THEOREM, not a hand-wave:** `sem_aluSelect` is
  > unconditional over 2^324 and its RHS is
  > `if asSelOf E < asOps then E (asRes (asSelOf E) k) else false` — ***the
  > unselected slots' 96 wires do not occur in it***, so the output is provably
  > independent of whatever they carry.
  >
  > ⚖️ **I AM NOT RULING ON THE SIZING, and math's second column is why the gate
  > count alone would mislead:** keeping ten slots costs ~1,000 provably-inert
  > gates and **ZERO proof**; shrinking to four saves them and **re-proves the
  > organ** — a 2-bit tree is a different `Circ`, so neither `sem_aluSelect` nor
  > `aluSelectCut` transfers. ***The gates say shrink; the proofs say keep; the
  > proof side is the one already banked.*** Silicon's block, my plan, maestro's
  > call.
  >
  > 📉 **Gate consequence if `core` is built to slice A: `~12,082 − 679 = ~11,403`.**

  *(Six blocks were missing when this was written and closed the same day; that
  line is regenerated, not original — see §3.)*
* It does not certify any wiring. **No `σ` in §4 has been written or checked.**
* It does not settle C4's own statement, which still owes math's
  **`DeliversProgram`** hypothesis (`run` takes the program as an argument;
  `stepT` takes a fetched word on `instrNet`, and nothing yet says where that word
  comes from) and **`EntryLoaded`**.

⇒ ***The honest summary, CORRECTED TWICE: C4's assembly is no longer blocked on
THEORY. It is blocked on FOUR STATEMENT HYPOTHESES **and on TWO BLOCKS THAT DO
NOT EXIST** (§3.5).***

⛔ **THIS SENTENCE HAS NOW BEEN WRONG IN TWO DIFFERENT WAYS AND THE SECOND IS THE
INSTRUCTIVE ONE.**
* *First it read "blocked on **ONE SHIFTER DECISION** and four statement
  hypotheses". The shifter is not a blocker — slice A never selects it.*
* 🔴 *Then it read "…four statement hypotheses — all named, none open research,
  and **NO UNBUILT BLOCK ON THE CRITICAL PATH**." **That last clause was false,
  and it was false BEFORE the first correction too.** A correction pass rewrote
  this exact sentence and **carried the false clause through untouched.***

🔑 ***AND REMOVING THE SHIFTER MADE THE SURVIVING CLAUSE STRICTLY MORE
MISLEADING, not less.*** *Before: one false clause standing beside one real (if
mis-scoped) blocker. After: one false clause **alone**, in a summary that reads
as fully closed — so a reader staffing off it concludes `core` is a wiring
exercise. It is not: two blocks have to be BUILT first.* (Math, 8/7 20:07, whose
§3 I took only half of.)

⚠️ ***REWRITING A SENTENCE IS NOT RE-CHECKING ITS CLAUSES.*** **When a correction
touches a summary, every OTHER clause in that summary is now unverified too — and
closing one gap can promote a surviving falsehood from "one of the problems" to
"the whole picture."** *Both wordings are left visible above rather than deleted;
the counts in this sentence were quoted elsewhere.*

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
