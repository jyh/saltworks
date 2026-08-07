/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Decoder

/-!
# C4 · `core` — THE WRITE-ENABLE DECODER

The second block of `compile`/`core`. Silicon's measurement is why this side is
cheap and the read side is not:

> *A read **selects** one of 31 registers — its cone grows with the file. A write
> **enables** one of 31 — its cone does not.*

**And this block is where P5 stops being a theorem about `St.set` and becomes a
gate that is not there.** `St.set 0 v = s` is landed (`ISA.lean`); here the
corresponding fact is that **`we 0` is the constant `false`**, so no write port
on register `x0` exists in the silicon at all.

## What it computes

```
we r  =  valid ∧ ¬isBEQ ∧ (rd = r) ∧ r ≠ 0
```

`¬isBEQ` because `BEQ` is the one Slice A instruction with no destination — it
writes the `pc` and nothing else. `valid` because an undecodable word is the
ratified **NOP-advance**: the register file must be untouched, and that is
enforced here rather than downstream.

⚠️ **`valid` is doing real work and is not defensive.** Under the ratified
option-1 semantics **99.80% of the word space is undecodable**, so the `¬valid`
path is not an edge case — *it is the overwhelmingly common input*, and a
missing `valid` term would corrupt the register file on almost every word a
fuzzer could hand it.
-/

namespace SaltWorks.HDL

open SaltWorks.ISA

/-! ### Layout: `rd` on `0…4`, `valid` on `5`, `isBEQ` on `6`. -/

def rwIn : Nat := 7
def rwRd (i : Nat) : Net := i
def rwValid : Net := 5
def rwIsBEQ : Net := 6

/-- `¬rd[i]` on `7…11`, `¬isBEQ` on `12`. -/
def rwNotRd (i : Nat) : Net := rwIn + i
def rwNotBEQ : Net := rwIn + 5
/-- `wrEn = valid ∧ ¬isBEQ` on `13`; matching logic allocates from `14`. -/
def rwWrEn : Net := rwIn + 6
def rwBase : Nat := rwIn + 7

/-- The fixed prefix: five inverters, `¬isBEQ`, and the common enable. -/
def rwPrefix : List Gate :=
  (List.range 5).map (fun i => (⟨rwNotRd i, .not (rwRd i)⟩ : Gate))
    ++ [⟨rwNotBEQ, .not rwIsBEQ⟩, ⟨rwWrEn, .and rwValid rwNotBEQ⟩]

/-- The literals selecting `rd = r`. -/
def rwMatch (r : Nat) : List Net :=
  (List.range 5).map fun i => if r.testBit i then rwRd i else rwNotRd i

/-- Registers `1 … 31`, each an address match ANDed with the common enable.
`x0` is handled separately and is not in this list. -/
def rwLayout : Nat → List Nat → List Gate × List Net × Nat
  | b, []      => ([], [], b)
  | b, r :: rs =>
      let (gs, m, b') := andChain b (rwMatch r)
      let (gs', os, b'') := rwLayout (b' + 1) rs
      (gs ++ [⟨b', .and m rwWrEn⟩] ++ gs', b' :: os, b'')

/-- **The write-enable decoder.** Output `r` is register `r`'s enable, in order
`0 … 31`; output `0` is the constant `false` — **P5, as an absent write port.** -/
def regWrite : Circ :=
  let (gs, outs, b) := rwLayout rwBase (List.range 31 |>.map (· + 1))
  { nIn := rwIn
    gates := rwPrefix ++ gs ++ [⟨b, .const false⟩]
    outs := b :: outs }

theorem regWrite_wf : regWrite.wf = true := by decide +kernel

/-! ### The specification and its certificate -/

/-- What the enables should be, from the semantics rather than from the gates. -/
def weSpec (rd : Nat) (valid isBEQ : Bool) : List Bool :=
  (List.range 32).map fun r => valid && !isBEQ && (rd == r) && !(r == 0)

/-- The circuit's answer. -/
def weOf (rd : Nat) (valid isBEQ : Bool) : List Bool :=
  sem regWrite (fun i =>
    if i < 5 then rd.testBit i
    else if i == 5 then valid
    else isBEQ)

/-- **Exhaustive: every `rd`, every control combination — 32 × 2 × 2 = 128.** -/
def weOK : Bool :=
  (List.range 32).all fun rd => [false, true].all fun v => [false, true].all fun b =>
    weOf rd v b == weSpec rd v b

theorem regWrite_correct : weOK = true := by decide +kernel

/-! ### The three facts this block exists to guarantee -/

/-- **P5 IN GATES — `x0` is never enabled, under any input whatsoever.** -/
theorem regWrite_x0_never_enabled :
    ((List.range 32).all fun rd => [false, true].all fun v => [false, true].all fun b =>
      (weOf rd v b).getD 0 false == false) = true := by decide +kernel

/-- **The NOP-advance path touches no register** — the ratified semantics, in
gates, on the 99.80% of words that are undecodable. -/
theorem regWrite_invalid_writes_nothing :
    ((List.range 32).all fun rd => [false, true].all fun b =>
      (weOf rd false b).all (· == false)) = true := by decide +kernel

/-- **`BEQ` writes no register** — it is the one Slice A instruction with no
destination. -/
theorem regWrite_beq_writes_nothing :
    ((List.range 32).all fun rd =>
      (weOf rd true true).all (· == false)) = true := by decide +kernel

/-- **NON-VACUITY — the enables are not constant `false`.** A valid non-`BEQ`
instruction with `rd = 3` enables exactly register 3. -/
theorem regWrite_enables_exactly_one :
    weOf 3 true false = (List.range 32).map (· == 3) := by decide +kernel

#audit_axioms rwIn
#audit_axioms rwPrefix
#audit_axioms rwMatch
#audit_axioms rwLayout
#audit_axioms regWrite
#audit_axioms regWrite_wf
#audit_axioms weSpec
#audit_axioms weOf
#audit_axioms regWrite_correct
#audit_axioms regWrite_x0_never_enabled
#audit_axioms regWrite_invalid_writes_nothing
#audit_axioms regWrite_beq_writes_nothing
#audit_axioms regWrite_enables_exactly_one

end SaltWorks.HDL
