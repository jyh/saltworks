/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.EmitS

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

**Those two numbers are `readtreem.v` (992) and `readtree.v` (2981) exactly**,
which is why this file is a check on the emitter rather than a new design: if
`emitSMux` does not turn this `Circ` into 992 mux cells, one of us is wrong and
the disagreement is visible immediately.

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

/-- Address width: 5 bits select one of 32 registers. -/
def rtAddrBits : Nat := 5
/-- 32 registers of 32 bits, flattened. -/
def rtRegs : Nat := 32
def rtWidth : Nat := 32

/-- Input layout: `raddr` occupies nets `0 … 4`; register `i` bit `k` is at
`rtAddrBits + i * rtWidth + k`. -/
def rtIn : Nat := rtAddrBits + rtRegs * rtWidth

/-- The net carrying register `i`'s bit `k`. -/
def rtReg (i k : Nat) : Net := rtAddrBits + i * rtWidth + k

/-- The inverter for address bit `j` — **one per address bit, shared by every
mux at that level**. Allocated immediately above the inputs. -/
def rtNotSel (j : Nat) : Net := rtIn + j

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
  let invs := (List.range rtAddrBits).map fun j => (⟨rtNotSel j, .not j⟩ : Gate)
  let (gs, outs) := rtBits rtWidth (rtIn + rtAddrBits)
  { nIn := rtIn, gates := invs ++ gs, outs := outs }

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

-- Gate count against `readtree.v`'s 2981.  MEASURED: 2981.
#eval readTree.gates.length

-- Mux sites against `readtreem.v`'s 992.  MEASURED: 992.
#eval muxCount readTree

-- The five inverters are SHARED, not consumed: each is read by every mux at its
-- level, so the peephole's fanout guard never fires on them. A `1` here would
-- mean the guard was about to eat a shared inverter and corrupt every other mux
-- selecting on that address bit.  MEASURED: [512, 256, 128, 64, 32].
#eval (List.range rtAddrBits).map fun j => readCount readTree (rtNotSel j)

#audit_axioms rtAddrBits
#audit_axioms rtRegs
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

end SaltWorks.HDL
