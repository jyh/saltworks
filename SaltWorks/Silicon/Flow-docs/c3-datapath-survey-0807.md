# THE C3 DATAPATH SURVEY — five blocks measured, and a rule that was TESTED and CORRECTED

### 2026-08-07, SILICON, on the Captain's orders (read path → writeback → ALU →
### control → memory interface). Every block synthesised through the pinned flow and censused;
### predictions written to disk before each synthesis. Kernel ceiling = 24 bits.

## The survey

| block | worst cone, **untreated** | ≤ 24 | needs option (A)? | worst cone, **treated** |
|---|---|---|---|---|
| **writeback** (result mux + write decode) | **6** | **100 %** | **NO** | 6 |
| **control** (decode + immgen + branch) | **13** | **100 %** | **NO** | 13 |
| **memory interface** (load/store/BE) | **11** | **100 %** | **NO** | 11 |
| **register read** (2 × 32:1) | 36 | 93.9 % | **YES** | **11** |
| **ALU** (10 ops + flags) | 68 | **0 %** | **YES** | **20** *(14 encoded)* |
| **PC adders** (`pc+imm`, `pc+4`) | 64 / 30 | — | **YES** | **3** |
| **fetch** (PC reg + next-PC select + JALR) | 100 | 21.2 % | **YES** *(its adders)* | **6** |

## THE FETCH PATH — no new mechanism, but the worst `keep` bypass measured

Predictions `F1`–`F4` on disk first. The **corrected rule held**: it predicts the
adders over (carry) and the next-PC mux fine (3 sources + 3 selects = 6), and
both are what the netlist shows. **`F4` was refuted** — not by a new mechanism,
but because **RTL + `keep` could not deliver the decomposition at all.**

```
cut at pc_plus_4 | pc_plus_imm | jalr_target          max 74, 58.7%
cut at those THREE *plus* pc_next                     max 73, 66.5%
```

**Four `keep`-marked 32-bit vectors, all surviving as nets, and the flop `D` pins
read `_018_`, `_017_`, `_016_` — machine-named nets that recompute the value and
bypass every one of them.** *(`pc_plus_4` survives 30 of 32 bits, correctly: bits
0–1 are unchanged by +4 and were folded.)*

⇒ **Fourth block, fourth bypass, and the severity is still rising**: carry chain
wholly re-derived → read path one bit → ALU eight bits → **fetch, four entire
vectors.** The treated figure of **6** is what structural emission gives, by the
same mechanism proven on `readtree`, `adder8s` and `alutail`.

### ⚠️ And an error in MY OWN diagnostic, caught before it was reported

My first pass showed `imem_addr` cones at **74** and I nearly published it. It is
an artifact: synthesis merged `pc_q` and `imem_addr` into one net, so the flop's
`.Q()` **is** `imem_addr[5]` — and rooting a cone **at a flop output** made my
traversal walk *through* the flop into its `D` logic. **The cone of a register
output is the register, not the logic feeding it.**

📌 `Sim/cones.py` shares this behaviour: when a primary output is directly a flop
`Q`, it roots a cone there and traverses into `D`, **double-counting that cone.**
It inflates a census and can only ever report a cone *larger* than it is — so it
produces **false failures, never false passes.** Recorded rather than fixed
mid-probe; the fetch figures above are quoted from the untouched instrument.

## ⛔ THE RULE I PUBLISHED AT 07:08 WAS IMPRECISE, AND THE MEMORY INTERFACE REFUTED IT AT 07:1x

I derived a rule from four blocks and then tested it on a fifth that was **not in
the derivation sample** — the memory interface — with the predictions written
down first. **It predicted the wrong way, twice.**

| | predicted | measured |
|---|---|---|
| load extract + extend | **OVER**, ~37 | **11 — fine** |
| store alignment | **OVER**, ~29 | **6 — fine** |
| byte enables | fine, ~6 | 6 — fine |

**Why.** `load_out[0]`'s leaves are exactly
`rdata_raw[0], [8], [16], [24], addr[0], addr[1], funct3[0], funct3[1]`. **A
byte-lane extract is BIT-SLICED**: output bit *k* depends on input bits
*k, k+8, k+16, k+24* — **four sources per bit, not thirty-two.** I had counted
the *word* as the operand set when what matters is the count **per output bit**.

⇒ **"Wide operand set" was the wrong phrase.** A 32-bit word selected **four
ways** is cheap; a 5-bit address selecting among **thirty-two words** is not.
*The width of the data is irrelevant; the number of sources per output bit is
everything.* **Corrected rule below.**

## 🎯 THE RULE, CORRECTED AND QUANTITATIVE

> **A cone exceeds the ceiling iff (sources per OUTPUT BIT) + (select/control
> bits) > 24.** Two mechanisms produce many sources per bit — **selecting among
> many operands**, and **carry/serial dependency**. Nothing else in this datapath
> does.

| block | sources per output bit | + control | total | verdict |
|---|---|---|---|---|
| register read | **31** registers | 5 | **36** | ✗ |
| barrel shift | **32** possible source positions | 5 | **37** | ✗ |
| ALU op mux | 10 op results | 10 one-hot | 20 | ✓ *(tight)* |
| **byte-lane extract** | **4** lanes | 4 | **8** | ✓ |
| writeback mux | 4 results | 2 | 6 | ✓ |
| adder / incrementer | *carry: all lower bits* | — | 30–65 | ✗ |
| decode / immgen | instruction field | — | ≤ 13 | ✓ |
| write enable | *broadcast — none* | 6 | 6 | ✓ |

**The superseded formulation is left above deliberately, with its refutation, so
the record shows a rule that was tested rather than a rule that was asserted.**

### The superseded version, for the record

> ~~A block needs structural emission if it SELECTS across a wide operand set, or
> ADDS across a wide word. A block that DECODES or ENABLES does not.~~

| what the block does | examples measured | cone behaviour |
|---|---|---|
| **selects** | register read (36), ALU op mux (68), barrel shifts (37) | grows with the **operand count** |
| **adds** | ALU adder (65), `pc+imm` (64), `pc+4` (30) | grows with the **word width**, via the carry chain |
| **decodes** | control signals (≤ 8), immediates (≤ 10), branch (13) | bounded by the **instruction field**, ~17 bits, and does not grow |
| **enables** | regfile write port (6) | **constant** — data is broadcast, only the enable is decoded |

*(That table is the superseded rule's evidence, kept with it.)*

⇒ **THREE of the five blocks need nothing at all** — writeback, control, and the
memory interface. A real narrowing of option (A)'s obligations, and **the third
one arrived by refuting my own prediction.**

## ⚠️ EVEN A `+4` INCREMENT NEEDS THE TREATMENT

`pc_plus_4` measured **max 30**: `pc_plus_4[31]` depends on `pc[2..31]` because
the carry ripples the whole way. **An incrementer is a degenerate adder and
inherits the carry chain in full.** *Anything that carries needs per-slice cuts —
not just the ALU's adder, and it would be easy to exempt an increment by
assumption.* The treated figure of **3** is measured on `adder8s` from the C3
probe, and the PC adders are the same structure.

## The control path in detail (measured 07:1x)

```
alu_op  4 roots  max  8   OK      imm      31 roots  max 10   OK
alu_src 1 root   max  7   OK      reg_we    1 root   max  7   OK
br_taken 1 root  max 13   OK      mem_we/re 1 each   max  7   OK
wb_sel  1 root   max  6   OK      pc_next  31 roots  max 67   OVER -> the adders
```

Cutting at the two named PC terms isolates them exactly: **`pc_next` becomes 15
(the select mux), and the two adders stand alone at 64 and 30.** ⇒ **The control
*logic* is not the problem and never was; the adders it contains are.**

## THE BRANCH PATH — no new mechanism, and a reduction that is TWICE as wide

Predictions `B1`–`B5` on disk first. The comparator is the piece `ctrl32` took as
a given input, so it had never been measured.

```
eq  = (rs1 == rs2)   cone 64   OVER      taken   cone 68   OVER
lt  = signed  <      cone 64   OVER      tgt[*]  cone 64   OVER  (known adder)
ltu = unsigned <     cone 64   OVER
```

**B1 and B2 exactly.** ⚠️ Cutting *at* `eq`/`lt`/`ltu` does **not** help them —
a cut makes a net a root, and a root's own cone is unchanged. **It helps only
their consumers.** The comparator must be treed **internally**.

**Treated** (`cmptree`, structural: per-bit XNOR row + a named AND-reduction
tree, cut at 4 group boundaries): **5 cones, MAX 16, 100 %** — from 64.

⚠️ **I predicted 8–11 and measured 16.** The XNOR row is *not* cut, so each group
cone reaches through it to **both** operands: 8 bit-positions × 2 operands = 16
leaves. **A two-operand reduction is twice as wide as a one-operand one** — the
ALU's `zero` flag reduced one 32-bit result (treated 8); the branch comparator
reduces *two* 32-bit operands (treated 16). ⇒ **Halve the group size for
two-operand reductions, or accept 16 — which is inside the ceiling either way.**

⇒ **No new mechanism.** The branch path is reduction (the ALU's `zero` shape),
carry (the adder's shape) and select (the mux shape) — all three already
enumerated. **What is new is only that the reduction is the block's PRIMARY
function here rather than a side flag.**

## THE CSR PATH (Zicsr) — priced for R5, and CHEAPER than an exclusion would suggest

⚠️ **Campaign `R5` lists CSRs as a candidate v1 exclusion. This prices that
decision; it does not presume it.** Measured on a 16-CSR machine-mode file with
CSRRW/CSRRS/CSRRC. Predictions `CS1`–`CS5` on disk first.

```
untreated                    1088 cones, median 31, MAX 31, 47.1%
  csr_rdata (read mux)  28   OVER    <- CS1 predicted 28, exactly
  FLOP.D    (write)     31   OVER    <- CS2 predicted 4-6. WRONG.
  FLOP.DE   (enable)    13   OK
cut at csr_rdata:  write path -> 4   OK
```

**CS2 was wrong for a structural reason worth keeping.** Unlike the register
file — whose write is a pure broadcast, cone **1** — **CSRRS/CSRRC are
READ-MODIFY-WRITE, so the CSR write data contains the entire read cone**
(28 + `rs1` + op = 31). ⇒ **`csr_rdata` must be a cut point, and then the write
path collapses to 4.** *A block whose write reads first inherits its own read
problem; nothing else in this datapath does that.*

### ⭐ CS5 confirmed: the 12-bit address is the distinctive cost

`csr_rdata`'s 28 leaves are **16 CSR operands + 12 address bits**. **Everywhere
else in this datapath the control term was 2–5; here it is 12** — 43 % of the
cone spent before a single operand is counted. ⇒ **With a 12-bit address, a CSR
file larger than ~12 registers is over the ceiling on that ground alone**, where
a 12-way *register* read would be trivial.

⚠️ **And naming the address compare does NOT fix it under RTL.** `addr_match`
survives as a net and **`csr_rdata`'s cone contains all 12 raw `csr_addr` bits
and not `addr_match`** — recomputed inline. **Fifth block, fifth bypass.**

⇒ **Pricing for R5: including CSRs costs ONE more read-mux tree and ONE more cut
point (`csr_rdata`). No new mechanism.** Under option (A) the read mux is
16 + 4 + 1 = **21**, inside the ceiling without even treeing it. **CSRs are not
an expensive exclusion to reverse — that is the number, whatever the council
decides with it.**

## What this means for C3

1. **Option (A) is required for three things**: the register read path, the ALU,
   and every adder/incrementer. **Not** for decode, immediates, branch logic, the
   register write port, or **the whole memory interface** — load extract, store
   alignment and byte enables are all natively inside the ceiling.
2. **The emitter's structural obligations are bounded and enumerable** — that is
   the useful form of this result. The five obligations now measured:
   * name the **carry chain**, per slice (adders, incrementers)
   * name the **mux-tree levels** (register read, barrel shifts)
   * name each **op result** before an output select (ALU)
   * name the **result vector** itself (`y`, feeding flags)
   * emit wide **reductions as trees** with named levels (`zero`, and every flag)
3. **`keep` does not substitute for any of them.** Three blocks, three failures:
   R2's carry chain wholly re-derived, the read path one bit routed around, the
   ALU eight. **The failure rate rises with the design's freedom to re-associate**,
   which is exactly why the *select* and *add* blocks are the ones that fail.
