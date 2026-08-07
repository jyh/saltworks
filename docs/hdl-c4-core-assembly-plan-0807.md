# C4 — THE `core` ASSEMBLY PLAN, AND THE ORGANS THAT DO NOT EXIST

### 2026-08-07, compiler seat (compiler-acct). Written after the assembly THEORY closed.

**Status of this document: a PLAN and a GAP CENSUS, not a construction.** Every
number in it was measured today; every `ssa`/`wf` claim is a landed theorem, not
a citation. *It exists because reading `AluSelect.lean`'s input layout before
building the datapath turned up six blocks that are not in the tree — and finding
that by reading is much cheaper than finding it at assembly time.*

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

## 3. ⛔ THE GAP — `aluSelect` NEEDS TEN OPERAND RESULTS AND SIX HAVE NO PRODUCER

`AluSelect.lean:56` is explicit: *"Ten op results: add, sub, and, or, xor, slt,
sltu, sll, srl, sra"*, at `asRes r k = r*32 + k`, plus four select bits. **It is a
pure mux tree. It computes none of its inputs.**

| # | result | producer | status |
|---|---|---|---|
| 0 | add | `adder32` | ✅ exists |
| 1 | sub | `adder32` on `(a, ~b)` with carry-in 1 | ⛔ **needs a 32-gate inverter block** |
| 2 | and | — | ⛔ **MISSING** (32 gates) |
| 3 | or | — | ⛔ **MISSING** (32 gates) |
| 4 | xor | — | ⛔ **MISSING** (32 gates) |
| 5 | slt | sub's sign bit, corrected for overflow | ⛔ **MISSING** |
| 6 | sltu | sub's carry-out | ⛔ **MISSING** |
| 7 | sll | — | ⛔ **MISSING** — see below |
| 8 | srl | `shifter32` | ✅ exists |
| 9 | sra | — | ⛔ **MISSING** — see below |

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
 4  bitwise     and / or / xor over rs1,rs2                    ~96   ⛔ MISSING
 5  invert b    for sub                                          32   ⛔ MISSING
 6  adder32×2   add, and sub via (a, ~b, cin=1)                  320
 7  slt/sltu    from sub's sign and carry                        ~8   ⛔ MISSING
 8  shifters×3  sll / srl / sra                                1,458  ⛔ 2 MISSING
 9  aluSelect   muxes the ten                                  1,445
10  regWrite    reads instr rd field + decoder                    163
11  pcNext      reads rs1, rs2, immB, decoder isBEQ                99
12  regNext     we <- regWrite, res <- aluSelect, cur <- state  3,104

core.outs = regNext's 1,024 ++ pcNext's low 32          = 1,056 = stWidth
```

**Measured subtotal of what EXISTS: 11,038 gates. Estimated total with §3
filled: ~12,700.**

⚠️ **`pcNext.outs.length = 33`, not 32.** *`core.outs` must take the low 32 and
the successor must check which end the extra bit is on before wiring it — this is
the kind of off-by-one that a positional `outs` list cannot catch by type.*

---

## 5. WHAT THIS DOES **NOT** SAY

* It does not say `core` is nearly done. **Six blocks are missing** and the two
  shift modes may be a modification to a landed organ.
* It does not certify any wiring. **No `σ` in §4 has been written or checked.**
* It does not settle C4's own statement, which still owes math's
  **`DeliversProgram`** hypothesis (`run` takes the program as an argument;
  `stepT` takes a fetched word on `instrNet`, and nothing yet says where that word
  comes from) and **`EntryLoaded`**.

⇒ ***The honest summary: C4's assembly is no longer blocked on THEORY, and is
now blocked on SIX SMALL ORGANS and one statement hypothesis — all named, none
open research.***
