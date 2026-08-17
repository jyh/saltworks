/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Seq
import SaltWorks.HDL.Compose

/-! # `serSeq` — THE OUTPUT ORGAN: activation, then serialize

**R8 item ③, the night council 2026-08-10.** The cell's accumulator produces a 32-bit word in
parallel; the fabric consumes ONE BIT PER CYCLE. This organ closes that gap and applies the
activation on the way through.

```
   nIn 33      load · d0…d31 (the accumulator word)
   nState 32   the shift register
   nOut 1      serial bit out — state bit 0, LSB-first, matching the cell's own stream order
```

## The activation is an AND row, and that is not a shortcut

ReLU at the signed order is `max(x, 0)`, and in two's complement the sign IS bit 31:

```
   act_k = and2(d_k, inv(d31))     msb set (negative) ⇒ 0 ; otherwise passthrough
```

⚠️ **The SPEC this is owed against is the LANDED `wordSignedOrder_max` (`Stack/Perm.lean`), stated
EXPLICITLY in the term and never as an instance** — D4(d)'s wording, and V5's signed-activation
discipline. **That theorem is NOT in this file.** R8 puts it behind the layout; what is here is the
organ, and *"emits"* is the only claim it carries.

## Zero constant gates — the weight-shift organ's trick, used a second time

The vacated top bit needs `0` during a shift. Rather than a `conb`, it is **`and2(load, d31)`**:
`0` exactly when it is READ (shift cycles have `load = 0`), and ignored on load cycles because the
mux selects the activated word there. *`wsLsb` did this first ("no longer a constant: `and load
x`"); a second instance makes it a pattern worth naming rather than re-deriving.*

## The mux is built from `Op`, not from a mux cell

`mux2` is not one of the five `Op` constructors, so each select is `or(and(a0, ¬s), and(a1, s))` —
and `emitSMux`'s peephole recognises exactly that shape and collapses it to one `sky130_fd_sc_hd__mux2_1`.
The gate count and the CELL count therefore differ by design. -/

namespace SaltWorks.HDL.Ser

open SaltWorks.HDL

/-! ### Layout -/

def sLoad : Net := 0
/-- The parallel word in — the accumulator's 32 bits. -/
def sD (k : Nat) : Net := 1 + k
/-- The shift register — the organ's STATE. -/
def sQ (k : Nat) : Net := 33 + k
/-- `nIn + nState`. -/
def sCoreIn : Nat := 65

/-! ### Gate net numbering, contiguous from `sCoreIn` so `ssa` holds -/

def sNLoad : Net := 65            -- inv(load)
def sNMsb  : Net := 66            -- inv(d31)
def sAct (k : Nat) : Net := 67 + k   -- 67…98   the activated word
def sVac   : Net := 99            -- and(load, d31) — the shift-in, 0 when read
def sT0 (k : Nat) : Net := 100 + 3 * k   -- and(a0, nload)
def sT1 (k : Nat) : Net := 101 + 3 * k   -- and(act, load)
def sNs (k : Nat) : Net := 102 + 3 * k   -- or(t0, t1)  — the next state bit

/-- The shift-in for bit `k`: the bit above it, or the vacated top. -/
def sA0 (k : Nat) : Net := if k < 31 then sQ (k + 1) else sVac

def serGates : List Gate :=
  ⟨sNLoad, Op.not sLoad⟩
  :: ⟨sNMsb, Op.not (sD 31)⟩
  :: (List.range 32).map (fun k => (⟨sAct k, Op.and (sD k) sNMsb⟩ : Gate))
  ++ [⟨sVac, Op.and sLoad (sD 31)⟩]
  ++ ((List.range 32).map (fun k =>
        [ (⟨sT0 k, Op.and (sA0 k) sNLoad⟩ : Gate),
          (⟨sT1 k, Op.and (sAct k) sLoad⟩ : Gate),
          (⟨sNs k, Op.or (sT0 k) (sT1 k)⟩ : Gate) ])).flatten

def serCore : Circ :=
  { nIn := sCoreIn
    gates := serGates
    outs := sQ 0 :: (List.range 32).map sNs }

/-- ⭐⭐ **THE ORGAN.** -/
def serSeq : Seq := { nIn := 33, nOut := 1, nState := 32, core := serCore }

/-! ### Shape -/

theorem serCore_ssa : serCore.ssa = true := by decide +kernel
theorem serCore_wf : serCore.wf = true := Circ.wf_of_ssa serCore_ssa
theorem serSeq_wf : serSeq.wf = true := by decide +kernel

theorem serCore_gate_count : serCore.gates.length = 131 := by decide +kernel

/-- **ZERO constant gates** — the vacated bit is a function of ports, not a tie cell. -/
theorem serCore_has_no_constant_gates :
    serCore.gates.filter (fun g => match g.op with | .const _ => true | _ => false) = [] := by
  decide +kernel

theorem serSeq_dimensions :
    serSeq.nIn = 33 ∧ serSeq.nOut = 1 ∧ serSeq.nState = 32 ∧ serCore.nIn = 65 := by
  refine ⟨rfl, rfl, rfl, rfl⟩

/-- ⛔ **BIRTH-ASSERTION: the vacated shift-in is LOW on every cycle that READS it.** On a shift
cycle `load = 0`, so `and(load, d31) = 0` — the property that lets this organ carry no constant. -/
theorem vacated_bit_is_low_when_read (d31 : Bool) :
    (Op.and sLoad (sD 31)).eval (fun n => if n = sLoad then false
                                          else if n = sD 31 then d31 else false) = false := by
  cases d31 <;> rfl

/-- **CONTROL: the activation reads the SIGN bit, not bit 0.** Wiring `inv` to `d0` places just as
cleanly and computes nonsense. -/
theorem activation_reads_the_sign_bit :
    (serGates.getD 1 default).op = Op.not (sD 31) ∧ sD 31 ≠ sD 0 := by
  refine ⟨by decide +kernel, by decide +kernel⟩

#audit_axioms serCore_ssa
#audit_axioms serCore_wf
#audit_axioms serSeq_wf
#audit_axioms serCore_gate_count
#audit_axioms serCore_has_no_constant_gates
#audit_axioms serSeq_dimensions
#audit_axioms vacated_bit_is_low_when_read
#audit_axioms activation_reads_the_sign_bit

end SaltWorks.HDL.Ser
