# C5 — THE EXECUTION PLAN, pre-registered

### 2026-08-07 ~17:4x, SILICON, on the maestro's dispatch. **Draft until refuted.**
### C5 per the freeze: *"flow + re-import: the netlist through the flow; per-cone
### equivalence at flop boundaries; MUTATION CONTROLS that make the goal FALSE
### (inject a decode bug; the checker must catch it)."*
### **Every number below is measured or is declared unmeasured. Predictions
### `C5-1`…`C5-8` are registered HERE, before the run.**

---

## 0. THE ONE FACT THAT SHAPES EVERYTHING ELSE

```
largest netlist EVER imported by this seat   540 gates   (FabricCut.lean)
the freeze's elaboration law                ~1,300 gates  ("monolithic
                                                          elaboration dies
                                                          ~1300 — per-module
                                                          always")
the core, projected                        ~11,900 gates  (assembly plan's
                                                          ~12,700 estimate
                                                          − 779 from route ②)
```

⇒ ***The core is ~22× the largest thing this harness has ever imported and ~9×
the elaboration law's ceiling.*** **C5 is not the switch ceremony at a bigger
size. The switch fit in one `def`; the core cannot, and no amount of proof
cleverness changes that — it is an elaborator limit, upstream of any theorem.**

🔴 **AND I AM INHERITING THE ~1,300, WHICH IS THE WEAKEST LOAD-BEARING NUMBER IN
THIS PLAN.** *It appears in the freeze's "laws honored" as a bare figure; I have
not measured it and neither has anyone this leg.* ⇒ **C5's FIRST action is to
measure it (§2.1), because the entire chunking plan is a different plan on either
side of it.**

---

## 1. THE PER-CONE BUDGET AT CORE SCALE

### 1.1 What the census actually licenses

The cone census ran on the **5,266-cell structural monolith**: **151 cuts (2.9 %),
max cone 24, median 3** — greedy, so an **upper bound**. Its transferable finding
was `W4`, which I got exactly backwards and which is the reason this section is
per-block and not a percentage:

> **Cone width accumulates with DEPTH along a serial chain, not with the FAN-IN
> of a select.** A mux tree is shallow and wide — one wide cone at its output,
> cut once. A carry chain is deep and serial — cones grow at every position, cut
> constantly. **57× spread, measured.**

```
inc32     62.7%  ·  zerotree 35.5%  ·  prioenc 15.9%  ·  adder32 3.2%
shifter32  2.7%  ·  aluselect 2.5%  ·  readtree 1.1%
```

### 1.2 The core's budget, block by block

**Densities are transferred only to blocks that were IN the census — the same
blocks, not similar ones.** Everything else is declared unmeasured.

| block | gates | cut density | cuts | basis |
|---|---:|---:|---:|---|
| `readTree` ×2 | 5,964 | **1.1 %** | **66** | ✅ measured, same block |
| `aluSelect` | 1,445 | **2.5 %** | **36** | ✅ measured, same block |
| `shifter` (route ②) | 679 | **2.7 %** | **18** | ✅ measured; ⚠️ route ② adds two reversal-bank boundaries — **re-measure** |
| `adder32` ×2 | 320 | **3.2 %** | **10** | ✅ measured, same block |
| **measured subtotal** | **8,408** | **1.55 %** | **130** | |
| `regNext` | 3,104 | — | **0 extra** | **flop-bounded**: all 1,056 flops are already cut points |
| `decoder` | 102 | ⛔ | ? | never measured |
| `regWrite` | 163 | ⛔ | ? | never measured |
| `pcNext` | 99 | ⛔ | ? | never measured |
| `bitwise` / `bitNot32` / `slt`,`sltu` | 135 | ⛔ | ? | pointwise — expect ≈0, **not measured** |
| `immBCirc` | 1 | — | 0 | |

⭐ **PROJECTED: ~130 cone cuts + 1,056 flop boundaries, over an unmeasured tail of
499 gates.**

#### ⚠️ AMENDED ~19:4x — THE PC ADDER, applied to my own numbers

The pc-path refutation (`cefd93e`) adds a **third `adder32` instance** to the
core — **160 gates**, whether it is described as "a third adder32" (compiler) or
as "`adder32` instantiated through `inst_sem`" (math). *`Compose.lean:67`
relocates every gate and `:75` advances the host counter by the full
`gates.length`, so the instantiation route does not avoid the gates.*

```
core            ~11,900  →  ~12,060 gates
adder32 density    3.2 % (MEASURED, same block)  →  +5 cuts
cone budget        130   →  ~135 measured cuts
imported entries   ~18,400 → ~18,600
```
✅ **AND IT SLIGHTLY IMPROVES THE BUDGET'S CONFIDENCE, which is not the direction
I expected: the new block is `adder32`, whose density is MEASURED — so 160 gates
move INTO the measured column rather than into the unmeasured tail.**
📌 *I am applying this to my own projections in the same hour I told two other
seats their total moves by 160. `C5-9`'s band (15,000–21,000) is unchanged and
still contains the new figure.*

📌 **AND THE CORE IS *CHEAPER PER GATE* THAN THE MONOLITH, WHICH IS THE CENSUS'S
W4 LESSON PAYING OUT.** *A uniform 2.9 % on ~11,900 gates would predict ~345 cuts.
The weighted figure is **1.55 %** — because the core is dominated by `readTree`
(5,964 gates at the census's **sparsest** density) while the monolith carried
`inc32` and `zerotree`, its two **densest** blocks, which the core does not have
at all.* ⇒ ***Scaling the monolith's percentage would have overstated the core's
obligation count by ~2.7×.***

**`C5-1`** — the core's greedy cut set lands in **100–200**, not 300+.
**`C5-2`** — max cone ≤ 24 holds at core scale **without** sub-cone splitting.
**`C5-3`** — the four unmeasured blocks contribute **< 40** cuts between them.

---

## 2. THE CHUNKING PLAN

### 2.1 FIRST ACTION — measure the elaboration ceiling (it decides the rest)

**A ladder of synthetic `Netlist` `def`s: 540 → 1,000 → 2,000 → 3,000 → 4,000 →
6,000 → 12,000 gate entries**, each elaborated by `saltbuild.sh` on a unique
`Scratch` file, nothing landed. Record **wall time, peak RSS, and the verb**.

⚠️ **The ladder must use REALISTIC gates** — random `and/or/xor/not` over
previously-defined nets, not 12,000 `.inp`s. *A list of constructors is not what
elaboration struggles with; a deep net-reference graph is.*

⇒ **THE DECISION RULE, pre-registered so no second ruling is needed:**
* **ceiling ≥ 3,000** → **per-organ import**, 12 netlists, largest `readTree` at
  2,982. Clean, matches the assembly plan's own boundaries.
* **ceiling ~1,300** → `readTree` (2,982) and `regNext` (3,104) each need
  **sub-chunking**, and the plan becomes ~30 pieces with internal cut points that
  are *not* organ boundaries — **a materially harder ceremony**, because those
  seams have no design meaning and must be certified as arbitrary.
* **ceiling < 1,000** → the per-organ route is dead; escalate before building.

**`C5-4`** — the true ceiling is **above 1,300** (the freeze's number is a
remembered figure from a different context, and the largest thing actually
imported, 540, never tested it).

### 2.1b ⭐ THE LADDER HAS BEEN RUN — RESULT, ~18:0x — AND IT CORRECTS A FLEET LAW

**Fired immediately, as §5 said it should be, because it needed nobody.**
Synthetic `Netlist` defs, realistic net-reference graph (a 64-net sliding window,
so the graph is deep rather than flat), each on its own `Scratch` file.

| config | gates | verdict | time | failure |
|---|---:|:---:|---:|---|
| default | 540 | ✅ | 16 s | |
| default | 1,000 | ✅ | 2 s | |
| **default** | **2,000** | ❌ | 1 s | **`maximum recursion depth`** |
| `maxRecDepth 1e6` | 2,000 | ✅ | 2 s | |
| `maxRecDepth 1e6` | 4,000 | ✅ | 3 s | |
| **`maxRecDepth 1e6`** | **12,000** | ✅ | **6 s** | ⭐ **the core's size** |
| `maxRecDepth 1e6` | 24,000 | ❌ | 11 s | `«LCNF compiler»` heartbeats |
| **`+ noncomputable`** | **24,000** | ✅ | **23 s** | |
| `+ noncomputable` | 48,000 | ❌ | 13 s | `isDefEq` heartbeats |

⇒ ***THE "~1,300 ELABORATION LAW" IS A STATEMENT ABOUT A DEFAULT, NOT ABOUT A
CAPACITY.*** **It is exactly right at defaults — the wall is between 1,000 and
2,000 — and wrong as a claim about what Lean can hold. The core's ~11,900 gates
elaborate in SIX SECONDS behind one `set_option`.**

🔑 **AND THE CEILING IS A STAIRCASE OF THREE DIFFERENT DEFAULTS, each its own
knob:** ① `maxRecDepth` (512) → ~1,300 · ② the **code generator**'s heartbeats →
~24,000 · ③ `isDefEq` heartbeats → 24,000–48,000.
⭐ **② IS FREE TO SKIP, AND THAT IS THE TECHNIQUE WORTH KEEPING: mark the netlist
`noncomputable`.** *A netlist is a proof datum, not a program — `decide +kernel`
reduces in the KERNEL and never touches compiled code — so the code generator is
pure waste on it, and skipping it doubles the ceiling.*
⚠️ *I first tried to skip it by dropping `#eval`. **That was wrong** — Lean
compiles every plain `def` whether or not anything evaluates it. The knob is
`noncomputable`, not the absence of a consumer.*

📊 **SCORING `C5-4` HONESTLY: I predicted "the true ceiling is above 1,300."
REFUTED at defaults, CONFIRMED with the knobs — and the prediction did not say
which regime it meant.** *That ambiguity is a defect in my pre-registration, not
a subtlety in the result. A prediction that can be scored either way scored
nothing.*

⇒ 🎯 **§2's DECISION RULE RESOLVES TO THE FIRST BRANCH, AND FURTHER: chunking is
now a CHOICE, not a NECESSITY.** *The core could be imported as ONE netlist.*
**§2.2 stands anyway, and the reasons are now positive rather than forced —**
locality of failure, organs that can be certified in parallel, and a σ-wiring
certificate that stays small. ***But the plan must not claim the elaborator
forces it, because it does not.***

### 2.1c ⭐ THE WALL IS BROKEN BY RESTRUCTURE, NOT BY THE KNOB — AND THE HARNESS
### NOW DOES IT

**On the maestro's order: diagnose the recursion, then fix it — iterative
restructure preferred, `maxRecDepth` only as a measured fallback.**

**DIAGNOSIS.** A plain `List Nat` literal of 2,000 elements fails at default
depth **identically**. ⇒ ***It is generic list-literal elaboration — Lean
recursing once per element over a right-nested `List.cons` chain. Not `Gate`, not
`Netlist`, not the importer's parser, not the `runP` fold.*** *The failure site
was the `def` line itself, which said so all along.*

**THE FIX, and the iterative one wins outright.** Emit in chunks joined by `++`:
each literal stays shallow and the top-level chain is only `⌈n/CHUNK⌉` deep.
Measured **at DEFAULT `maxRecDepth`, chunk 500**, each rung carrying a
`decide +kernel` length proof so the datum is shown *reducible*, not merely
elaborable:

| gates | flat, default | flat + `maxRecDepth` | **chunked, DEFAULT** |
|---:|:---:|:---:|:---:|
| 2,000 | ❌ | ✅ 2 s | ✅ 2 s |
| 4,000 | — | ✅ 3 s | ✅ 2 s |
| **12,000** | — | ✅ 6 s | **✅ 7 s** |
| 24,000 | — | ❌ codegen | **✅ 22 s** |

⇒ **Core scale and 2× core scale clear with NO `set_option` at all.** *The knob
is recorded as the fallback and its numbers are in §2.1b — it is not adopted,
because it pushes the cost onto every consumer of the file and hides a
structural problem behind a default.*

**LANDED IN THE HARNESS**: `import_netlist.py` now chunks above **1,000** gates
(`CHUNK=500`, `THRESHOLD=1000`, both below the measured wall with margin).
✅ **Every file generated to date is byte-identical** — `reimport.sh` reproduces
both committed data.

### ⛔ AND IT EXPOSED A REGRESSION I INTRODUCED, WHICH IS THE PART WORTH READING

`readback.py` read the emitted datum as `src.split("Netlist := [", 1)[1]` — **the
FIRST block only.** On a chunked file that reads chunk 0 and calls the whole
datum verified.

🔴 ***It crashed here with an `IndexError` only because the outputs happened to
index past chunk 0. A netlist whose outputs all fell inside chunk 0 would have
PASSED a check that read a third of the gates.*** **A partial check that reports
success is worse than the crash that revealed it** — and `readback` is this
harness's entire trust anchor, the reason the file header can say *"the generator
is UNTRUSTED."*

✅ **Fixed: readback now follows the `++` chain — and takes the chunk ORDER from
the chain rather than from file order**, because "the chunks appear in join
order" is a *generator promise*, and the generator is exactly what this file
refuses to trust.

📌 **AND `reimport.sh` COULD NOT HAVE CAUGHT IT.** *Both committed data are below
the threshold, so they take the unchanged path.* ⇒ **A regression test built from
the existing corpus cannot see a bug that only fires above the corpus's size.**
*That is not a criticism of `reimport.sh`; it is the reason the end-to-end import
below had to be run.*

### ✅ END-TO-END, THROUGH THE REAL HARNESS

```
tt_um_saltworks_banyan.v  (post-layout, run 31226766476)   19,183 instances
  → 910 logic / 18,273 physical+sequential · 51 cell types
  → 1,389 gates emitted, 3 chunks of ≤500
  → 100 flops cut, ONE clock domain — root 'clk', parity 0, via 16 CLK nets
  → readback: 32 random vectors × 116 outputs, AGREES WITH VENDOR LIBERTY
  → elaborates at DEFAULT maxRecDepth, and `decide +kernel` reduces it
```

⚠️ **THE HONEST LIMIT ON "STEP 1 IS DONE": the SIZE is cleared — 12,000 and
24,000 synthetic, at default settings, reducible.** *But the largest **real**
artifact available is 1,389 gates, because `core` does not exist yet.* ⇒ **Step 1
is done for the size and must be re-run on the actual core when it lands.** *I
would rather say that than let a synthetic ladder stand in for the thing.*

### 2.2 The import unit is the ORGAN, and the seam is the WIRING

The core is a composition of 12 organs whose boundaries are already named by the
assembly plan's §4 order. **Import each organ separately; certify the wiring
separately.**

```
per-organ:   import  →  round-trip census  →  per-cone equivalence vs its Circ
the wiring:  σ-maps only — "organ k's input j is organ i's output m"
```
📌 **This is the same split that made the switch tractable, at 12 organs instead
of 2** — and it is why `instOK`'s `σ i < off` discipline in the assembly plan is
load-bearing rather than bookkeeping: **the wiring certificate is a statement
about offsets, and offsets are cheap.**

#### ⭐ AMENDED ~20:5x — `C5-5` HAS MEASURED CONTENT NOW, FROM THREE ORGANS

I registered `C5-5` as a guess. Three organs landing in one evening have given
the σ-wiring certificate its **seed set**, each with a known failure mode:

| # | obligation | found by |
|---|---|---|
| 1 | `pcAdd`'s **carry-in** must be driven by a host **zero** (`adder32.nIn = 65`) | compiler, PCADD ledger |
| 2 | `aluSelect`'s **three shift slots** have **one** producer after route ② | silicon |
| 3 | `regNext`'s **`we` ports** must come from `regWrite` **alone** | math, REGNEXT |

🔑 ***All three are one shape: an input port whose correctness is no organ's
theorem, only `core`'s wiring.*** **And `instOK` forbids leaving a port dangling
— so the assembly MUST map it somewhere, a wrong map stays well-formed and
`ssa`, and it passes every certificate that does not select it.**

*Math states the exposure exactly, for their own organ:* **"any assembly driving
`we` from anything but `regWrite` breaks P5 silently, and no core exists to check
it."**

⇒ **`M5` (swap two organs' σ offsets) is aimed at precisely this class, and it
now has three concrete targets rather than a hypothetical.** *`C5-5`'s < 5 %
estimate stands unchanged — but it is now an estimate ABOUT something, and the
three seeds are what the certificate must at minimum discharge.*

**`C5-5`** — the wiring certificate costs **< 5 %** of the total obligation
count. *If it costs more, the decomposition is wrong and I want to know at the
plan, not at the proof.*

### 2.3 ⭐ THE WALL DATA FOLDED IN — and it corrects the core's SIZE, not just
### its ceiling

**The `~11,900` figure is CIRC gates. That is not what gets imported.** Structural
emission is passthrough (1 Circ gate → 1 cell), but **the importer then EXPANDS
each sky130 cell into the 6-primitive `Gate` type**, and that factor is now
measured rather than guessed:

```
composed tile, measured (§2.1c):   910 logic cells → 1,389 entries
                                   less 118 primary inputs → 1,271 logic gates
                                   ⇒ EXPANSION ×1.40
core, projected:  ~11,900 cells ×1.45  ≈ 17,300 logic gates
                  + 1,056 state leaves + 18 design inputs
                  ⇒ ≈ 18,400 Netlist entries
```

⇒ ***The core's imported netlist is ~18,400 entries, not ~11,900 — about 1.5×
bigger than the number the assembly plan hands you, and nobody had applied the
expansion factor because until tonight it had never been measured at scale in this campaign.***

**Elaboration cost at that size, interpolated from the two measured rungs**
(12,000 → 7 s, 24,000 → 22 s; ⇒ ≈ n^1.65):
`(18,400 / 12,000)^1.65 × 7 s ≈ **14 s**` — **comfortably inside, chunked, at
default settings.**

**`C5-9`** — the core's imported netlist is **15,000–21,000** `Netlist` entries.
**`C5-10`** — it elaborates **chunked, at default `maxRecDepth`, in under 30 s**.
**`C5-11`** — the **readback** check is the cost that bites, not elaboration. *The
tile's readback ran 32 vectors × 116 outputs; the core is ~1,072 outputs over
~18,400 gates — **~14× the work per vector, ~9× the outputs**. This is the first
place I expect a wall I have not already broken.*

### 2.4 ⇒ THE DECOMPOSITION CHOICE, RE-COST AT MEASURED NUMBERS

| | one netlist | 12 organs |
|---|---|---|
| elaboration | ~14 s, **fits** | ~1–2 s each |
| a failure tells you | *"the core is wrong"* | **which organ** |
| readback | one 18,400-gate pass | 12 small passes, **parallelisable** |
| the σ-wiring seam | none | **a real obligation** (`C5-5`) |

⭐ **The elaborator no longer decides this — I do, and the reason is the middle
row.** ***At 18,400 gates a red is uninformative; at 1,500 it names the organ.***
**Per-organ stands, and now stands on a stated ground rather than a borrowed
constraint.**

---

## 3. THE MUTATION CONTROLS

The freeze requires *"MUTATION CONTROLS that make the goal FALSE (inject a decode
bug; the checker must catch it)"* under **math's banked validity law: the control
must make the goal FALSE, not merely UNREACHABLE.**

⚠️ **That distinction is the whole difficulty and it is where this kind of
control usually fails.** *A mutation that makes a `decide` time out, or that
makes a hypothesis unsatisfiable, proves nothing — the checker "caught" an
absence. **A valid control produces a well-typed FALSE goal that the checker
refutes.***

| # | injection | site | must go FALSE | catches |
|---|---|---|---|---|
| **M1** | swap two `funct3` arms in the decoder | `decoder` | `C4Spec` | the decode bug the freeze names |
| **M2** | invert one bit of the `rd` write-enable | `regWrite` | `C4Spec` | write-port addressing |
| **M3** | drop the carry into bit 17 of `adder32` | `adder32` | per-cone equivalence, **that cone only** | ⭐ **cone LOCALITY** — if a mid-adder mutation reddens cones it is not in, the decomposition leaks |
| **M4** | shift `pcNext` by +8 instead of +4 | `pcNext` | `C4Spec` | the sequencing path, which no ALU test reaches |
| **M5** | swap two organs' `σ` offsets | the **wiring**, not an organ | the wiring certificate — **every organ still passes** | ⭐ **that the wiring certificate is load-bearing at all** |
| **M6** | retype one cell `and2_1`→`or2_1` in the imported netlist | post-import datum | the round-trip census | the importer, not the design |

⭐ **M3 AND M5 ARE THE TWO THAT EARN THEIR PLACE.** *M1/M2/M4 test that the
checker notices a wrong core — necessary, and the easy half.* **M3 tests that a
local bug stays local, and M5 tests the seam that per-organ decomposition
CREATES.** ⇒ ***A decomposition's characteristic failure is not missing a bug;
it is passing every piece while the assembly is wrong. M5 is the only control
here that could fail while all twelve organs are green.***

**`C5-6`** — all six mutations produce a **FALSE** goal, not an unreachable or a
timeout. **Any that yields a timeout is REPLACED, not counted.**
**`C5-7`** — **M5 passes every per-organ check** and fails only the wiring
certificate. *If M5 also reddens an organ, my decomposition is not what I think it
is.*

---

## 4. THE IMPORT-HARNESS DELTAS — what the core needs beyond the fabrics

### 4.1 ✅ THE FEARED COST IS NOT THERE — cell coverage is COMPLETE

Measured, `Cells/Sky130.lean` against the composed tile's fabricated netlist:

```
cell families MODELLED (Liberty-checked)   53
families USED by the fabricated tile       32
MISSING                                     0        ← full coverage
modelled but unused (headroom)             21
```
⇒ **The AOI/OAI families the core's arithmetic will pull in — `a211o`, `a31o`,
`a32o`, `o211a`, `nand3b`, `and4bb` — are ALREADY modelled and already
Liberty-checked.** *I expected this to be C5's long pole. It is not there at all.*

**`C5-8`** — the core's netlist introduces **≤ 3** unmodelled cell families, and
plausibly zero.

### 4.2 ⛔ THE REAL DELTAS, in the order they will bite

**(a) SCALE OF THE FLOP TREATMENT — 52 → 1,056, a 20× jump.**
The Q-leaf/D-root treatment is established at **52 flops** (`cc401c9`, 70 inputs
= 18 design + 52 state, 76 outputs, 524 gates). The core has **1,056 state bits**
(`regNext`'s 1,024 ++ `pcNext`'s low 32 = `stWidth`). ⇒ *Every flop becomes a
primary input AND a root, so the core's imported netlist has **1,056 extra
leaves** before a single design input.* **Nothing about the method changes; the
sizes in every intermediate structure do.**

**(b) 🔴 THE SEQUENTIAL-CELL TRIPWIRE — a HARD ERROR, by design.**
The importer *"refuses rather than approximates: an unmodelled sequential cell …
is a hard error, not a warning."* **Exactly one flop is modelled —
`dfxtp_1_next`, with `dfxtp_1_next_liberty`.** And `Cells/Sky130.lean:66` records
that a design in this very repo maps to **`dfrtp_2` — asynchronous, active-low
reset — *not* `dfxtp_1`**.
✅ *The composed tile as fabricated uses `dfxtp` only, so today's designs are
covered.* ⛔ ***But which flop the core gets is decided by synthesis, from RTL
this seat does not write.*** ⇒ **PRE-FLIGHT CHECK, before any import attempt:
scan the core's netlist for sequential families and confirm every one is
modelled.** *Cheap, one grep, and it is the difference between a five-minute fix
and a mid-ceremony stop.*

**(c) THE COMMON-CLOCK OBLIGATION AT 1,056 FLOPS.** The treatment is only
well-defined if every flop latches on the same event, and after CTS the flops do
**not** share a CLK *net* — the fabric needed **8 CLK nets proved into one
domain** rather than assumed from net equality. **A core-scale clock tree will
have many more.** ⇒ *This scales with the tree, not with the design, and it is
the one harness cost I expect to grow super-linearly.*

**(d) 🟡 THE MONOLITH'S UNFINISHED BUSINESS, INHERITED HONESTLY.** *`M5` was only
**partially** established: my evaluator does not traverse module hierarchy, so
the monolith's end-to-end functional equivalence was never checked.* **A 12-organ
core is exactly a module hierarchy.** ⇒ **Either the evaluator learns hierarchy,
or every organ is evaluated flat and the wiring is carried by the σ-certificate
alone.** *The second is the plan of §2.2 and I prefer it — but it is a choice, and
it is being made HERE rather than discovered later.*

---

## 5. FIRING ORDER

| # | step | gate |
|---|---|---|
| 1 | ✅ **elaboration-ceiling ladder** (§2.1) — **DONE**, wall diagnosed and broken by restructure (§2.1b, §2.1c); harness chunks; readback repaired | — |
| 2 | pre-flight sequential-cell scan (§4.2b) | `core` netlist exists |
| 3 | per-organ import + round-trip census | ceiling known |
| 4 | greedy cut + cone census at core scale | organs imported |
| 5 | per-cone equivalence, organ by organ | §4 |
| 6 | the σ-wiring certificate | §5 |
| 7 | **mutation controls M1–M6** | §6 — *and they run LAST, against a green checker, because a control against a red checker proves nothing* |

⭐ **STEP 1 IS NOT GATED ON `core` AND SHOULD FIRE NOW.** *It needs no RTL, no
compiler deliverable, and no seam — only synthetic netlists — and it is the
number the rest of this plan branches on.* **That is the one piece of C5 that can
be paid for before the campaign starts, and paying for it early is the whole
reason to pre-register a plan.**

---

---

## 5b. THE PRE-REGISTRATION LEDGER — every prediction, and its state

**Registered before any C5 work. Scored as results arrive, including against
me.**

| # | prediction | state |
|---|---|---|
| `C5-1` | greedy cut set lands in **100–200** | ⏳ open — needs `core` |
| `C5-2` | max cone **≤ 24** holds at core scale without sub-cone splitting | ⏳ open |
| `C5-3` | the four unmeasured blocks contribute **< 40** cuts | ⏳ open |
| `C5-4` | the true elaboration ceiling is **above 1,300** | ⚠️ **SCORED — AMBIGUOUS, NO CREDIT.** Refuted at defaults (wall 1,000–2,000), confirmed with knobs, and the prediction never said which regime. *The defect is in my pre-registration, not the result.* |
| `C5-5` | the wiring certificate costs **< 5 %** of obligations | ⏳ open |
| `C5-6` | all six mutations produce a **FALSE** goal, not a timeout | ⏳ open |
| `C5-7` | **M5 passes every per-organ check** and fails only the wiring | ⏳ open — *the one I would least bet on* |
| `C5-8` | the core introduces **≤ 3** unmodelled cell families | ⏳ open — *cell coverage measured COMPLETE for the tile (53/32/0)* |
| `C5-9` | the core's imported netlist is **15,000–21,000** entries | ⏳ open — *from the ×1.40 expansion measured tonight* |
| `C5-10` | it elaborates **chunked, default settings, < 30 s** | ⏳ open |
| `C5-11` | **readback**, not elaboration, is the next wall | ⏳ open — *~14× the per-vector work of the tile* |

📌 **`C5-4` IS THE ONE TO LEARN FROM, AND THE LESSON IS ABOUT WRITING
PREDICTIONS, NOT ABOUT LEAN.** *"Above 1,300" was true and false at once because
it never named the regime it was measured in.* ⇒ **`C5-9`…`C5-11` each name their
configuration explicitly — "chunked, default `maxRecDepth`" — so none of them can
be scored both ways.**

---

## 6. WHAT THIS PLAN DOES NOT SAY

* It does **not** claim the core will pass. **Every prediction above is
  falsifiable and three of them (`C5-1`, `C5-4`, `C5-7`) I would not bet heavily
  on.**
* It does **not** cost the proof effort, only the **structure**. Per-cone
  equivalence at ~130 cones is a different question from whether each closes.
* The `~1,300` elaboration law and the `~11,900` gate projection are both
  **inherited**, from the freeze and from the assembly plan. *Neither is mine and
  neither has been re-measured; §2.1 fixes the first and `core`'s existence will
  fix the second.*
* It assumes the assembly plan's **12-organ decomposition survives contact**. If
  compiler's `core` composes differently, §1.2's per-block transfer is void — the
  densities are per-BLOCK, and they move with the blocks.
