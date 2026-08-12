/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.ISA
import SaltWorks.HDL.Sem

import SaltWorks.HDL.EmitN

/-!
# C4 · `core` — THE DECODER, as a `Circ`

The first block of `compile`/`core`, and the one the ratified semantics pins
exactly: option 1 (Captain-ratified 8/7) makes an undecodable word a **defined
NOP-advance**, so the decoder's `valid` output is not an error flag — it is a
control signal with a specified meaning, and every gate downstream of it is
reachable.

## What it computes

Five one-hot control signals plus their disjunction, from the 32-bit
instruction word alone:

```
isADD   opcode = 0110011 ∧ funct7 = 0 ∧ funct3 = 000
isXOR   opcode = 0110011 ∧ funct7 = 0 ∧ funct3 = 100
isSLT   opcode = 0110011 ∧ funct7 = 0 ∧ funct3 = 010
isADDI  opcode = 0010011 ∧ funct3 = 000
isBEQ   opcode = 1100011 ∧ funct3 = 000
valid   the disjunction — ¬valid ⇒ the NOP-advance path
```

**These are exactly `SaltWorks.ISA.decode`'s cases**, read off the landed
definition rather than from the manual, because `decode` is what `stepT` uses
and `stepT` is what C4 compares against.

## The projection, and why the certificate is complete despite being small

⭐ **The control signals depend on the word ONLY through `opcode` (7 bits),
`funct3` (3 bits), and the single predicate `funct7 = 0`.** Every other bit of
the word is data — `rd`, `rs1`, `rs2` and the immediates — and no gate here
reads them. *So an exhaustive check over `2^32` words would be checking the same
1024 × 2 cases four million times each.*

The certificates below therefore cover:

```
all 2^10 (opcode, funct3) pairs at funct7 = 0     1024 cases
all 2^10 (opcode, funct3) pairs at funct7 = 1     1024 cases   (a non-zero rep.)
all 2^7  funct7 values, for the zero-detector      128 cases
```

⇒ **Together these exhaust the projection the logic actually depends on**, and
the third is what licenses treating `funct7 = 1` as representative of every
non-zero `funct7`. *Stating the projection is the whole argument; a reader who
does not accept it should reject the certificate, which is why it is written
down rather than implied.*
-/

namespace SaltWorks.HDL

open SaltWorks.ISA

/-! ### Net layout: the word on `0…31`, its inverters on `32…63`, logic above. -/

/-- Instruction word width, and the block's input count. -/
def dcIn : Nat := 32

/-- `¬w[i]`, one inverter per word bit, shared by every match below. -/
def dcNot (i : Nat) : Net := dcIn + i

/-- The inverter bank. -/
def dcInvs : List Gate := (List.range dcIn).map fun i => ⟨dcNot i, .not i⟩

/-- First net available to the matching logic. -/
def dcBase : Nat := dcIn + dcIn

/-- A left-associated AND chain over `ns`, allocating from `b`.
Returns the gates, the output net, and the next free net. -/
def andChain (b : Nat) : List Net → List Gate × Net × Nat
  | []          => ([], 0, b)
  | [x]         => ([], x, b)
  | x :: y :: r =>
      let (gs, o, b') := andChain (b + 1) (b :: r)
      (⟨b, .and x y⟩ :: gs, o, b')
  termination_by ns => ns.length

/-- A left-associated OR chain. -/
def orChain (b : Nat) : List Net → List Gate × Net × Nat
  | []          => ([], 0, b)
  | [x]         => ([], x, b)
  | x :: y :: r =>
      let (gs, o, b') := orChain (b + 1) (b :: r)
      (⟨b, .or x y⟩ :: gs, o, b')
  termination_by ns => ns.length

/-! ### ⛔ THE EMPTY-LIST HAZARD, COMMITTED AS A THEOREM RATHER THAN A COMMENT

*Silicon's `C-D3`, pre-registered against `DECODER-UNCOND` 8/7 20:56 and verified
here at the bytes.* **`andChain b [] = ([], 0, b)` and `orChain b [] = ([], 0, b)`
both return NET 0 — and net 0 is WORD BIT 0**, the opcode's LSB, because `dcIn`
lays the 32 word bits at nets `0…31`. ⇒ ***A match built from an EMPTY literal
list would silently take `w[0]` as its match signal: well-formed, `ssa`-valid,
and wrong.***

⚖️ **THE HAZARD IS NOT CLOSED BY CHANGING `andChain`** — allocating a real
constant-true in the nil case shifts every gate number downstream and
invalidates the whole certificate suite for a case that never occurs. **It is
closed by the TABLE, and the table is what gets edited.** *So the fact is stated
as a theorem and the invariant is stated beside `dcMatches` below, in the same
spirit as math's `regNext_writes_x0_when_enabled`: commit the hazard, then close
it.*

📌 **Same genre as `bnCSigma`'s catch-all `else` (silicon, 19:52): a total
function whose default is silently WRONG for an input its author did not expect.
There it was fixed at the source because that was free; here it is not, so it is
fenced instead.** -/

/-- ⛔ **THE HAZARD: an empty literal list yields word bit 0 as the match net.** -/
theorem andChain_nil_is_word_bit_zero (b : Nat) : (andChain b []).2.1 = 0 := by
  simp [andChain]

/-- …and `orChain` likewise. -/
theorem orChain_nil_is_word_bit_zero (b : Nat) : (orChain b []).2.1 = 0 := by
  simp [orChain]

/-- The literal for "word bit `i` equals `v`": the bit itself, or its inverter. -/
def dcLit (i : Nat) (v : Bool) : Net := if v then i else dcNot i

/-- The literals matching a field: `w[lo … lo+n-1]` against `val`'s low `n` bits. -/
def dcField (lo n val : Nat) : List Net :=
  (List.range n).map fun j => dcLit (lo + j) (val.testBit j)

/-- `opcode` occupies bits 0…6, `funct3` bits 12…14, `funct7` bits 25…31 —
`ISA.decode`'s own `extractLsb'` offsets. -/
def dcOpcode (v : Nat) : List Net := dcField 0 7 v
def dcFunct3 (v : Nat) : List Net := dcField 12 3 v
/-- `funct7 = 0` is seven inverters ANDed — the only way `funct7` is read. -/
def dcFunct7Zero : List Net := dcField 25 7 0

/-- The five matches, in allocation order, each an AND chain over its literals. -/
def dcMatches : List (List Net) :=
  [ dcOpcode 0b0110011 ++ dcFunct7Zero ++ dcFunct3 0b000    -- ADD
  , dcOpcode 0b0110011 ++ dcFunct7Zero ++ dcFunct3 0b100    -- XOR
  , dcOpcode 0b0110011 ++ dcFunct7Zero ++ dcFunct3 0b010    -- SLT
  , dcOpcode 0b0010011 ++ dcFunct3 0b000                    -- ADDI
  , dcOpcode 0b1100011 ++ dcFunct3 0b000 ]                  -- BEQ

/-- ✅ **THE INVARIANT THAT CLOSES `andChain_nil_is_word_bit_zero` — every match
in the table has literals.** *This is a property of `dcMatches`, NOT of
`andChain`, and it must be re-checked whenever the table is edited. That is
exactly why it is a theorem and not a comment.* -/
theorem dcMatches_all_nonempty : dcMatches.all (fun m => !m.isEmpty) = true := by
  decide +kernel

/-- The margin the invariant is standing on, measured rather than asserted. -/
theorem dcMatches_literal_counts :
    dcMatches.map List.length = [17, 17, 17, 10, 10] := by decide +kernel

/-- Lay the matches out one after another, collecting their output nets. -/
def dcLayout : Nat → List (List Net) → List Gate × List Net × Nat
  | b, []      => ([], [], b)
  | b, m :: ms =>
      let (gs, o, b')   := andChain b m
      let (gs', os, b'') := dcLayout b' ms
      (gs ++ gs', o :: os, b'')

/-- **The decoder.** Outputs `[isADD, isXOR, isSLT, isADDI, isBEQ, valid]`. -/
def decoder : Circ :=
  let (mgs, outs, b) := dcLayout dcBase dcMatches
  let (ogs, v, _)    := orChain b outs
  { nIn := dcIn, gates := dcInvs ++ mgs ++ ogs, outs := outs ++ [v] }

theorem decoder_wf : decoder.wf = true := by decide +kernel

/-! ### The specification — read off `ISA.decode`'s SLICE-A cases, not off the
manual (⬥ M2: the qualifier is new, and it is the honest one — `decode` also
accepts `LW`/`SW`, which this plane deliberately does not implement) -/

/-- **The SLICE-A control plane's reading of `ISA.decode`** — the five op-class
bits plus `valid`, and nothing else.

⬥ **M2 RE-CUT THIS DOCSTRING, NOT THIS DEFINITION** (helm ruling 16:48/17:07).
The old sentence, *"what `ISA.decode` says the control signals should be"*, was
stated as if total, and it was an overclaim waiting for a bigger ISA. `decode`
now accepts `LW`/`SW`; **this control plane does not, BY DESIGN — there is no
memory datapath in the v1 core, no port, no decode row in `dcMatches`, and no
bit in this six-signal vocabulary that could name one.** Every decoded
instruction outside the five op-classes maps to the not-decoded word.

⛔ **SO THE KERNEL DECODER AND THIS PLANE ARE NO LONGER THE SAME PARTIAL
FUNCTION**, and that disagreement is stated as a theorem
(`ctrlSpec_not_decoded_of_touchesMem`) rather than left to prose. *The memory
control plane — port, decode rows, control bits — is **stage ③'s commissioned
addition**, priced beside the `dmem8` door, not a gap in this file.* -/
def ctrlSpec (w : BitVec 32) : List Bool :=
  match decode w with
  | some (.ADD _ _ _)  => [true, false, false, false, false, true]
  | some (.XOR _ _ _)  => [false, true, false, false, false, true]
  | some (.SLT _ _ _)  => [false, false, true, false, false, true]
  | some (.ADDI _ _ _) => [false, false, false, true, false, true]
  | some (.BEQ _ _ _)  => [false, false, false, false, true, true]
  -- ⬥ M2 (ruled 17:07). The memory ops are DELIBERATELY not decoded by this
  -- plane: no port, no row, no control bit. Stated as a theorem just below.
  | some (.LW _ _ _)   => [false, false, false, false, false, false]
  | some (.SW _ _ _)   => [false, false, false, false, false, false]
  | none               => [false, false, false, false, false, false]

/-- ⬥⬥ **M2 — THE GUARD THEOREM: the kernel/plane divergence, made
kernel-visible instead of prose-silent** (helm ruling 17:07).

A word that `ISA.decode` accepts as a MEMORY op is reported by this control
plane as *not decoded*. **That is a deliberate boundary of the v1 core, and
stating it as a theorem is what stops it being a lie waiting for a reader**: a
disagreement you can `#print axioms` is a specification; the same disagreement
living only in a docstring is an omission.

📌 *This is also why `decoder_plane_f7_zero`/`_one` still certify 2048 exhaustive
points: the circuit already emits the invalid word on these opcodes, so spec and
silicon agree — they agree that this core does not implement them.* -/
theorem ctrlSpec_not_decoded_of_touchesMem (w : BitVec 32) (i : Instr)
    (hd : decode w = some i) (ht : SaltWorks.ISA.touchesMem i = true) :
    ctrlSpec w = [false, false, false, false, false, false] := by
  simp only [ctrlSpec, hd]
  cases i
  case LW => rfl
  case SW => rfl
  all_goals exact absurd ht (by simp [SaltWorks.ISA.touchesMem])

/-- The circuit's answer for a concrete word. -/
def ctrlOf (w : BitVec 32) : List Bool := sem decoder (fun i => w.getLsbD i)

/-- A word carrying only `opcode`, `funct3` and `funct7` — the projection. -/
def dcWord (op f3 f7 : Nat) : BitVec 32 :=
  BitVec.ofNat 32 (op ||| (f3 <<< 12) ||| (f7 <<< 25))

/-! ### The certificates -/

/-- Exhaustive over `(opcode, funct3)` at a fixed `funct7`. -/
def dcPlaneOK (f7 : Nat) : Bool :=
  (List.range 128).all fun op => (List.range 8).all fun f3 =>
    ctrlOf (dcWord op f3 f7) == ctrlSpec (dcWord op f3 f7)

/-- **All 1024 `(opcode, funct3)` pairs with `funct7 = 0`.** -/
theorem decoder_plane_f7_zero : dcPlaneOK 0 = true := by decide +kernel

/-- **All 1024 with `funct7 = 1`** — the non-zero representative. -/
theorem decoder_plane_f7_one : dcPlaneOK 1 = true := by decide +kernel

/-- **And `funct7` is read ONLY through "is it zero"**: exhaustive over all 128
values, at the one opcode where `funct7` is consulted. *This is what licenses
`funct7 = 1` standing for every non-zero `funct7`.* -/
def dcFunct7OK : Bool :=
  (List.range 128).all fun f7 => (List.range 8).all fun f3 =>
    ctrlOf (dcWord 0b0110011 f3 f7) == ctrlSpec (dcWord 0b0110011 f3 f7)

theorem decoder_funct7_exhaustive : dcFunct7OK = true := by decide +kernel

/-! ### Non-vacuity — the signals must not be constant -/

/-- Each of the five is actually asserted by some word, and `valid` is false for
some word. *Without this the certificates are satisfied by an all-`false`
decoder.* -/
theorem decoder_signals_are_reachable :
    ctrlOf (encode (.ADD 3 1 2))  = [true, false, false, false, false, true] ∧
    ctrlOf (encode (.XOR 3 1 2))  = [false, true, false, false, false, true] ∧
    ctrlOf (encode (.SLT 3 1 2))  = [false, false, true, false, false, true] ∧
    ctrlOf (encode (.ADDI 1 0 5)) = [false, false, false, true, false, true] ∧
    ctrlOf (encode (.BEQ 1 2 4))  = [false, false, false, false, true, true] ∧
    ctrlOf 0x000010B7#32          = [false, false, false, false, false, false] := by
  decide +kernel

/-- **Dense SSA — the precondition for instantiating this block into `core`.**
`Compose.instOK` needs `ssa`, not merely `wf`: under `wf` alone the gate outputs
may be sparse and `instNext` would under-report the region occupied. *Checked
here rather than assumed at the assembly site.* -/
theorem decoder_ssa : decoder.ssa = true := by decide +kernel

#audit_axioms decoder_ssa
#audit_axioms dcIn
#audit_axioms dcNot
#audit_axioms dcInvs
#audit_axioms andChain
#audit_axioms orChain
#audit_axioms dcLit
#audit_axioms dcField
#audit_axioms dcMatches
#audit_axioms dcLayout
#audit_axioms decoder
#audit_axioms decoder_wf
#audit_axioms ctrlSpec
#audit_axioms ctrlSpec_not_decoded_of_touchesMem
#audit_axioms ctrlOf
#audit_axioms decoder_plane_f7_zero
#audit_axioms decoder_plane_f7_one
#audit_axioms decoder_funct7_exhaustive
#audit_axioms decoder_signals_are_reachable
#audit_axioms andChain_nil_is_word_bit_zero orChain_nil_is_word_bit_zero
#audit_axioms dcMatches_all_nonempty dcMatches_literal_counts

end SaltWorks.HDL
