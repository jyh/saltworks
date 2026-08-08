/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.EmitS
import SaltWorks.HDL.Compose

/-!
# The RV32I register-file READ PATH, as a `Circ`

The first CPU-scale `Circ` in this campaign, and the artifact that lets the
emitter be checked against the silicon seat's oracle end to end rather than on
four hand-built cases.

## Why the read path and nothing else

Measured by the silicon seat on 2026-08-07, and it is a structural asymmetry
rather than an accident of this design:

> *A read **selects** one of 31 registers — its cone grows with the file. A write
> **enables** one of 31 — its cone does not.* The data is broadcast to every
> register and only the enable is decoded.

| path | cells | area | max cone | needs |
|---|---:|---:|---:|---|
| read | 1508 | 15,222 um² | **36** | a tree AND structural emission |
| write | 183 | 922 um² | **6** | nothing |

⇒ **The whole difficulty of the register file — verification and area — lives on
the read side.** This file builds that side and no more.

## The shape, and the arithmetic that pins it

One read port of a 32×32 register file: a **32:1 multiplexer per output bit**,
built as a **5-level binary tree of 2:1 muxes** driven by the five address bits.

```
per bit   16 + 8 + 4 + 2 + 1  =  31 muxes
32 bits   32 × 31             =  992 muxes          <- the oracle's cell count
gates     992 × 3 + 5 shared inverters = 2981        <- the oracle's primitive count
```

**The mux count is `readtreem.v`'s 992 exactly.** The primitive count is
**2982**, not the oracle's 2981, and the extra gate is the shared `const` tie
that replaces `x0` — see the note below on why 32 register leaves was wrong.

⚠️ **The five inverters are SHARED — one per address bit, not one per mux.** That
is the silicon seat's measured sharp edge and the reason the peephole must never
consume a `not`: eating one would corrupt every other mux selecting on that
address bit. *This file is the test case that would expose it.*

## What this file does NOT claim

It builds a `Circ` and nothing else. **No theorem here says the tree reads the
right register** — that obligation belongs with the code generator's correctness
argument, and stating it would need the register-file semantics this campaign
has not yet frozen. *A generator that produces the right cell count and the wrong
function would pass every check in this file, and saying so is cheaper than
discovering it.*
-/

namespace SaltWorks.HDL

/-! ### `x0` IS NOT STORED, AND THAT IS THE WHOLE OF THIS FILE'S CORRECTION

The first version of this file built **32 register leaves**. That was wrong, and
the cell counts could not catch it — a 32:1 tree needs 31 muxes whether leaf 0 is
a register or a constant, so it matched the oracle's 992 and 2981 while
describing the wrong object. ***A number matching exactly is not evidence the
object is right.***

Two independent facts say 31:

* **This campaign's own ISA.** `SaltWorks/HDL/ISA.lean` enforces read-as-zero **on
  the read port, unconditionally** — `St.get s r = if r = 0 then 0 else
  s.regs[r.val]` — deliberately a fact about the port rather than an invariant on
  `regs[0]`, which is what lets `get_zero` need no hypothesis. **A read of `x0`
  therefore never consults storage.**
* **The silicon seat's measurement:** a real regfile stores **992 flops, not
  1024**. *"`x0` is hardwired, so storing it is 32 flops that can only ever hold
  zero. 1024 counts ISA REGISTERS, not hardware STATE."*

⇒ **31 registers are stored; leaf 0 of every tree is a CONSTANT ZERO.** That is
the same substitution the flow already made on its own when `carry[0]` was tied
low and correctly became a `conb` tie cell.

**Consequence, stated because it moves a published number:** the primitive count
goes **2981 → 2982** — one shared `const` gate appears — while the **mux count
stays 992**. *The mux count was never able to distinguish the two designs, which
is exactly why it agreed before the correction.* -/

/-- Address width: 5 bits select one of 32 ISA registers. -/
def rtAddrBits : Nat := 5
/-- ISA registers addressed. `x0` is among them and is NOT stored. -/
def rtRegs : Nat := 32
/-- Registers actually held in flops: `x1 … x31`. -/
def rtStored : Nat := rtRegs - 1
def rtWidth : Nat := 32

/-- Input layout: `raddr` occupies nets `0 … 4`; **stored** register `i`
(`1 ≤ i ≤ 31`) bit `k` is at `rtAddrBits + (i-1) * rtWidth + k`. -/
def rtIn : Nat := rtAddrBits + rtStored * rtWidth

/-- The shared constant-zero leaf that stands in for `x0`. One gate for the whole
file — `x0` is one value, not thirty-two. -/
def rtZero : Net := rtIn

/-- The inverter for address bit `j` — **one per address bit, shared by every
mux at that level**. Allocated above the tie cell. -/
def rtNotSel (j : Nat) : Net := rtIn + 1 + j

/-- The net carrying ISA register `i`'s bit `k`. **`i = 0` is the constant-zero
leaf, not an input** — the read port never consults storage for `x0`. -/
def rtReg (i k : Nat) : Net :=
  if i == 0 then rtZero else rtAddrBits + (i - 1) * rtWidth + k

/-- Three gates forming one 2:1 mux at base net `b`: `b` and `b+1` are the two
`and`s and `b+2` is the `or`. The output is `b+2`.

The operand order is the one `muxAt` recognises — `and(x, ¬s)` then `and(y, s)`
then `or` — but the matcher tries all four commutations, so this file is not
relying on a convention the peephole depends on. -/
def rtMux (b : Nat) (x y s ns : Net) : List Gate :=
  [⟨b, .and x ns⟩, ⟨b + 1, .and y s⟩, ⟨b + 2, .or b (b + 1)⟩]

/-- Mux one level of a tree: pair up `ins` and emit a mux per pair, allocating
from `b`. Returns the gates, the next level's nets, and the next free net. -/
def rtLevel (s ns : Net) : Nat → List Net → List Gate × List Net × Nat
  | b, x :: y :: rest =>
      let (gs, os, b') := rtLevel s ns (b + 3) rest
      (rtMux b x y s ns ++ gs, (b + 2) :: os, b')
  | b, _ => ([], [], b)

/-- Fold `n` levels of the tree. -/
def rtLevels : Nat → Nat → List Net → List Gate × List Net × Nat
  | 0,     b, ins => ([], ins, b)
  | n + 1, b, ins =>
      let j := rtAddrBits - (n + 1)
      let (gs, os, b') := rtLevel j (rtNotSel j) b ins
      let (gs', os', b'') := rtLevels n b' os
      (gs ++ gs', os', b'')

/-- The 32:1 tree for output bit `k`, allocating from `b`. -/
def rtBit (k : Nat) (b : Nat) : List Gate × Net × Nat :=
  let leaves := (List.range rtRegs).map fun i => rtReg i k
  let (gs, os, b') := rtLevels rtAddrBits b leaves
  (gs, os.headD 0, b')

/-- All 32 bits, threaded through one net counter. -/
def rtBits : Nat → Nat → List Gate × List Net
  | 0,     _ => ([], [])
  | n + 1, b =>
      let k := rtWidth - (n + 1)
      let (gs, o, b') := rtBit k b
      let (gs', os) := rtBits n b'
      (gs ++ gs', o :: os)

/-- **The read path.** Five shared inverters, then 32 independent 32:1 trees. -/
def readTree : Circ :=
  let zero := (⟨rtZero, .const false⟩ : Gate)
  let invs := (List.range rtAddrBits).map fun j => (⟨rtNotSel j, .not j⟩ : Gate)
  let (gs, outs) := rtBits rtWidth (rtIn + 1 + rtAddrBits)
  { nIn := rtIn, gates := zero :: invs ++ gs, outs := outs }


/-- The read tree's cut set: **the output of every mux at every level**. The
silicon seat's treated figure of 11 comes from a COARSER grouping; taking every
level gives the finest decomposition and a cone of 3, and a coarser census is
obtained by keeping only every k-th level of this list. -/
def readTreeCuts : List Net :=
  (readTree.gates.filterMap fun g =>
    match g.op with | .or _ _ => some g.out | _ => none)

/-! ## The oracle check — MEASUREMENTS, deliberately not theorems

These compare the emitter against the silicon seat's two committed numbers. They
are `#eval`, and the reason is not convenience.

⛔ **`decide +kernel` ON THESE IS BOTH INFEASIBLE AND POINTLESS, and I tried it
first.** `muxCount` calls `readCount` once per gate and `readCount` traverses
every gate, so recognising sites is **O(n²) — about 1.8 × 10⁷ list traversals at
n = 2981**, inside the kernel. Measured: `saltbuild EXIT=134` with
`excessive memory consumption detected at 'interpreter'`, unchanged at double the
cap.

📌 **AND EVEN IF IT FIT, IT WOULD BUY NOTHING.** `emitS`, `emitSMux` and `muxAt`
produce a `String`; they sit **outside `emitN_sem`** and are untrusted by
construction. *A kernel proof about an untrusted emitter's cell count is not
evidence the silicon is right — the evidence is that the flow returns what we
emitted, and that is measured downstream by the importer.* **Using
`decide +kernel` here would have been ceremony that costs 18 million kernel
traversals and proves nothing about the artifact.**

*(The rule that names this: `docs/hdl-cap-rule-M2-0806.md`. Applying M-2 caught
the failure immediately — and caught me applying it in the wrong order, since
M-2.1's string is definitive and M-2.3's differential test is only for failures
where no string appears. Run out of order it reports "not a cap event", which is
false.)*

**Expected, from `RTL/readtree.v` and `RTL/readtreem.v`:**
`gates = 2981` (992 muxes × 3 + 5 shared inverters) and `muxCount = 992`. -/

-- Gate count. 992 muxes x 3 + 5 inverters + 1 tie = 2982.  MEASURED: 2982.
-- (readtree.v is 2981; the difference is the x0 tie cell, and it is the FIX.)
#eval readTree.gates.length

-- Mux sites against `readtreem.v`'s 992.  MEASURED: 992.
#eval muxCount readTree

-- The five inverters are SHARED, not consumed: each is read by every mux at its
-- level, so the peephole's fanout guard never fires on them. A `1` here would
-- mean the guard was about to eat a shared inverter and corrupt every other mux
-- selecting on that address bit.  MEASURED: [512, 256, 128, 64, 32].
#eval (List.range rtAddrBits).map fun j => readCount readTree (rtNotSel j)


/-! ## ⭐ WELL-FORMEDNESS — AND THE O(n²) WALL, MEASURED ON BOTH SIDES

**This circuit is the one the campaign recorded as the wall.** `Circ.wf`'s
`nodupB` is O(n²), and this seat's 8/7 note reads *"a core-sized `Circ` CANNOT be
certified as one circuit — `EXIT=134` at 3,104 gates."* ⇒ ***That was a citation.
Here is the differential, run today on this machine at the module build's own
budget:***

```
route                                    budget      result
decide +kernel  on  wf   (direct)        -M 20000    EXIT=134, memory_exception
                                                     "excessive memory
                                                     consumption at 'interpreter'"
                                                     after 76 s
Circ.wf_of_ssa  on  ssa  (structural)    -M 20000    PROVED, ~5 s
```

**Same circuit, same claim, same machine, same cap. One route dies and the other
closes.** *The first run was at `-M 6000` and also died; it was re-run at 20000
because a wall measured at MY OWN cap would be the adjacent object rather than the
wall.*

🔑 **WHY THE STRUCTURAL ROUTE IS CHEAP: `ssa` is a LINEAR scan** — gate `i`'s
output must be exactly `base + i` and its fanin below it — **whereas `wf` asks
`nodupB`, which compares every output against every other.** *The density that
`ssa` demands is precisely what makes the distinctness `wf` demands free, so the
quadratic never has to be walked.*

📌 **Note the failure site: `at 'interpreter'`, not `(kernel)`.** *The
`hdl-cap-rule-M2` note records the two diagnostic texts; this is the elaboration
site rather than the kernel one, and the rule's own advice applies — classify by
the DIFFERENTIAL, not by the string.* -/

theorem readTree_ssa : readTree.ssa = true := by decide +kernel

/-- **`wf` for a circuit `decide` cannot reach.** -/
theorem readTree_wf : readTree.wf = true := Circ.wf_of_ssa readTree_ssa

#audit_axioms rtAddrBits
#audit_axioms rtRegs
#audit_axioms rtStored
/-! ## ⭐ DOES IT READ? — the behavioural certificate this file did not have

⚠️ **THIS FILE'S `#eval` ARGUMENT ABOVE IS CORRECT AND IT IS ABOUT SOMETHING
ELSE.** *It argues — rightly — that `decide +kernel` on `muxCount`/`readCount` is
infeasible (O(n²), ~1.8 × 10⁷ traversals) **and pointless** (they are about an
untrusted string emitter that sits outside `emitN_sem`).* ⛔ **Every word of that
stands. It simply says nothing about whether the read path READS THE RIGHT
REGISTER — and until today, nothing else did either.**

📌 **THAT IS THE SHAPE, AND IT IS WORTH NAMING BECAUSE IT IS NOT A WRONG CLAIM:
a well-argued "we deliberately did not prove X" sitting next to an unstated "we
also never proved Y" READS AS COVERAGE.** *A reader comes away believing
`decide +kernel` was considered and rejected for this circuit. True for the
emitter oracle; never asked for correctness.*

### The formulation is the cost — for the second time today

⛔ **My first attempt drove all 32 outputs from an environment computing `/` and
`%` per net lookup: `EXIT=134`, OOM, 76 s.** ✅ **The one-cold driver below reads
ONE output bit from an environment that does one comparison per net: ALL 32
ADDRESSES in 7 s.** ⇒ ***Same lesson as `BatcherNetC`'s sorting certificate, hit
twice in one afternoon: the certificate was never too expensive, the way I wrote
it was.*** *`sem` rebuilds a ~3,000-deep environment chain and then walks it once
per output, so output count multiplies the dominant cost.*

### The driver, and why one cold register is a discriminating test

*Every stored register holds all-ones except register `m`, which holds zeros. Then
bit 0 of the port is `false` **exactly when** the port selected `m` — or selected
`x0`, which is the constant-zero leaf and never consults storage.* **One bit
distinguishes all 32 addresses, which is what makes this cheap AND total over the
address space.** -/

/-- Address `a` on nets `0…4`; every stored register all-ones except `m`. -/
def rtOneCold (m a : Nat) : Env := fun n =>
  if n < rtAddrBits then a.testBit n
  else decide (¬ (rtAddrBits + (m - 1) * rtWidth ≤ n
                  ∧ n < rtAddrBits + (m - 1) * rtWidth + rtWidth))

/-- Bit 0 of the read port. -/
def rtBit0 (m a : Nat) : Bool := (sem readTree (rtOneCold m a)).getD 0 false

/-- Every address selects the register it names. -/
def rtSelectsOK (m : Nat) : Bool :=
  (List.range 32).all fun a => rtBit0 m a == decide (a ≠ m ∧ a ≠ 0)

/-- ⭐ **THE READ PATH READS — all 32 ADDRESSES, kernel-checked** *(including
`x0`, which must read zero without consulting storage: the address that is not a
register)*.

⚠️ **AND THE ADDRESS IS THE ONLY AXIS THIS IS EXHAUSTIVE IN. Corrected 8/7 19:1x
after math measured all three:**
```
a   the ADDRESS         ALL 32   genuinely exhaustive — five address bits IS 32
m   the FILE CONTENTS   ONE      m = 7, one-cold, of the 2^992 the 31 registers hold
the PORT                ⛔ BIT 0 ONLY — `rtBit0`; 31 of the 32 mux trees are
                         outside this certificate entirely
```
**`readTree.nIn = 997`.** *This certificate and its sibling drive 64 of 2^997
valuations and read 1 of 32 outputs.* ⇒ ***"all 32, kernel-checked" is TRUE and
names the one axis where it is true.***

✅ **SUPERSEDED — use math's `sem_readTree_St` / `sem_readTree_uncond`
(`SaltWorks/Stack/Program.lean`): the block tied to `St.get` at EVERY state,
register and bit, with no driver at all.** *`rtOneCold_eq` proves this
certificate's own one-cold driver IS `rtEnvOf` at one file, so the sampled
predicate now holds for all 31 stored registers rather than two — supersession,
not restatement.* **What follows is a tripwire. That is the theorem.**

🔑 **AND THE MUTANT THAT PROVES THE PORT AXIS IS REAL: `readTreeCutB` ties the
root of OUTPUT BIT 1's tree to `.const false` — one gate, still `ssa` — and this
certificate accepts it EVERYWHERE.** *Not a gap in the sample: an entire axis the
certificate does not have.* -/
theorem readTree_selects_correctly_on_sample : rtSelectsOK 7 = true := by decide +kernel

/-- …and again with a different cold register, so the first is not an accident of
where `7` sits in the mux tree. -/
theorem readTree_selects_correctly_on_sample' : rtSelectsOK 19 = true := by decide +kernel

/-- ⛔⛔ **TWO POINTS WEARING A TOTAL LAW'S NAME — AND IT IS THE ONLY THEOREM IN
THIS CORPUS THAT SKIPPED THE `_on_sample` SUFFIX.** *(Math asked for this one to
be flagged loudly, 8/7 19:02. They were right.)*

**The ISA's version, `St.get_zero` (`ISA.lean:165`), is
`@[simp] theorem St.get_zero (s : St) : s.get 0 = 0` — TOTAL, no hypothesis.
The circuit's version below is `rtBit0 7 0 = false ∧ rtBit0 19 0 = false`: two
file contents, address 0, BIT 0.** ⇒ ***A name that matches an unconditional ISA
law, on a statement that is two points of 2^997 × 32.***

🔑 **THE NAMING CONVENTION IS THE FINDING, NOT THE THEOREM.** *Twenty certificates
in `SaltWorks/HDL/**` carry `_on_sample`, and every one of them warns a reader in
its own name. **This is the single theorem that skipped it, and it is the single
one that misled.*** ⇒ ***That is evidence FOR the convention, so: `_on_sample` is
not decoration — a certificate whose name does not say `sample` will be read as a
law, by me, within the day.***

✅ **SUPERSEDED by math's `readTree_reads_x0_zero`: `x0` reads zero at EVERY file
contents and ALL 32 bits, no driver.** *Kept here, unrenamed, because other seats'
prose cites this name — annotated rather than rewritten, per evidence's ruling
that a record which silently repairs its past is worth less than one that shows
where it was wrong.*

*(The underlying claim is still the right one to state separately: `x0` is the
one address whose answer does not come from the register file, and the
`rtStored = 31` / `rtRegs = 32` distinction exists entirely for it.)* -/
theorem readTree_x0_is_zero : rtBit0 7 0 = false ∧ rtBit0 19 0 = false := by
  decide +kernel

/-- ⛔ **NON-VACUITY — the check DISCRIMINATES.** *Scored against the wrong
expectation (off by one address) it is `false`, so `rtSelectsOK` is not a
predicate that passes for everything.* -/
theorem readTree_check_discriminates :
    ((List.range 32).all fun a => rtBit0 7 a == decide (a ≠ 8 ∧ a ≠ 0)) = false := by
  decide +kernel

#audit_axioms rtZero
#audit_axioms rtWidth
#audit_axioms rtIn
#audit_axioms rtReg
#audit_axioms rtNotSel
#audit_axioms rtMux
#audit_axioms rtLevel
#audit_axioms rtLevels
#audit_axioms rtBit
#audit_axioms rtBits
#audit_axioms readTree
#audit_axioms rtOneCold rtBit0 rtSelectsOK
#audit_axioms readTree_selects_correctly_on_sample
#audit_axioms readTree_selects_correctly_on_sample'
#audit_axioms readTree_x0_is_zero
#audit_axioms readTree_check_discriminates
#audit_axioms readTree_ssa
#audit_axioms readTree_wf
#audit_axioms readTreeCuts

end SaltWorks.HDL
