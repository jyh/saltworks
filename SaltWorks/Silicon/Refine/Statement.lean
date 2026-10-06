/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/

/-!
# AAU — the statement: the fabricated core refines "RV32I with erratum E"

Desk AAU, council 2026-10-06 ruling 4 (ii). **This file is the STATEMENT and nothing else.** It
defines the specification and the proposition `RefinesE`. It contains no proof of `RefinesE`, no
`sorry` and no axiom. It is posted for a non-author read BEFORE any proof is attempted, because
the statement is the artifact: a proof of the wrong proposition is worth nothing.

## What is claimed, in one paragraph

`core32` + `busadapt8` at `jyh/tt-neural-dataflow-fabric@01e19f7` are modelled as a `PinMachine`.
`W1` builds that model and links it to the fabricated RTL by SAT; this file does not. Take the
state one clock edge after reset, with ANY initial register file, and drive it with ANY stream of
host bytes on `ui_in`, with `sof` held low. Then, for every `k` such that the first `k` instructions
are in scope:

1. **the pins are equal.** Every `(uo_out, uio_out[1:0])` pair the machine drives in those cycles is
   the pair that `runSpec` predicts. That covers every fetch address, load address, store address
   and store datum.
2. **the architectural state agrees.** At the cycle where instruction `k` ends, `pc` and `x0..x31`
   equal the specification's.

The specification is `exec true`: RV32I as written in `exec false`, with exactly three changes, each
marked `ERRATUM` below. They are SRA and SRAI shifting logically, and LW writing the word of the
PREVIOUS load loop (0 if there has been none since reset). These are the three failures the
bus-level formal check measured (`docs/silicon-aaj-bus-formal-1005.md`).

## Scope (stated here and in `docs/silicon-aau-statement-1006.md`)

* `sof` low throughout. `rst_n` is low for exactly the one edge that `PinMachine.reset` denotes,
  then high.
* "In scope" is `stepH ≠ none`. The 31 RV32I instructions other than FENCE, ECALL, EBREAK and the
  sub-word loads and stores, decoded with RV32I's full field checks. A taken jump or branch whose
  target is not 4-aligned is out of scope, and so is a misaligned LW/SW address. In RV32I each of
  these traps, and the core has no traps. The claim ends at the first out-of-scope instruction.
* Memory belongs to the host. The spec does not model it. A load's word is whatever the host
  drives in the load loop, which is why the claim quantifies over every host.
-/

namespace SaltWorks.Silicon.Refine

/-- A 32-bit word. -/
abbrev W := BitVec 32

/-! ## 1 · Instructions and decode (RV32I, the 31 in scope) -/

/-- The 31 in-scope RV32I instructions. -/
inductive Op where
  | lui | auipc | jal | jalr
  | beq | bne | blt | bge | bltu | bgeu
  | lw | sw
  | addi | slti | sltiu | xori | ori | andi | slli | srli | srai
  | add | sub | sll | slt | sltu | xor | srl | sra | or | and
  deriving DecidableEq, Repr

/-- A decoded instruction. `imm` is already sign-extended (or shifted, for U-type). -/
structure Dec where
  op  : Op
  rd  : BitVec 5
  rs1 : BitVec 5
  rs2 : BitVec 5
  imm : W
  deriving DecidableEq, Repr

/-- RV32I immediates (ISA manual vol. I, Fig. 2.4). -/
def immI (i : W) : W := (i.extractLsb' 20 12).signExtend 32
def immS (i : W) : W := (i.extractLsb' 25 7 ++ i.extractLsb' 7 5).signExtend 32
def immB (i : W) : W :=
  (i.extractLsb' 31 1 ++ i.extractLsb' 7 1 ++ i.extractLsb' 25 6 ++ i.extractLsb' 8 4
    ++ (0 : BitVec 1)).signExtend 32
def immU (i : W) : W := (i.extractLsb' 12 20 ++ (0 : BitVec 12)).setWidth 32
def immJ (i : W) : W :=
  (i.extractLsb' 31 1 ++ i.extractLsb' 12 8 ++ i.extractLsb' 20 1 ++ i.extractLsb' 21 10
    ++ (0 : BitVec 1)).signExtend 32

/-- Decode with RV32I's FULL field checks. `none` means out of scope. That covers an illegal
encoding, FENCE/ECALL/EBREAK, the sub-word loads and stores, and a shift-immediate with nonzero
`imm[11:5]` other than SRAI's `0100000`. -/
def decode (i : W) : Option Dec :=
  let opc := i.extractLsb' 0 7
  let f3  := i.extractLsb' 12 3
  let f7  := i.extractLsb' 25 7
  let rd  := i.extractLsb' 7 5
  let rs1 := i.extractLsb' 15 5
  let rs2 := i.extractLsb' 20 5
  let mk (op : Op) (imm : W) : Option Dec := some ⟨op, rd, rs1, rs2, imm⟩
  if opc = 0b0110111#7 then mk .lui (immU i)
  else if opc = 0b0010111#7 then mk .auipc (immU i)
  else if opc = 0b1101111#7 then mk .jal (immJ i)
  else if opc = 0b1100111#7 then (if f3 = 0#3 then mk .jalr (immI i) else none)
  else if opc = 0b1100011#7 then
    (if f3 = 0#3 then mk .beq (immB i) else if f3 = 1#3 then mk .bne (immB i)
     else if f3 = 4#3 then mk .blt (immB i) else if f3 = 5#3 then mk .bge (immB i)
     else if f3 = 6#3 then mk .bltu (immB i) else if f3 = 7#3 then mk .bgeu (immB i)
     else none)
  else if opc = 0b0000011#7 then (if f3 = 2#3 then mk .lw (immI i) else none)
  else if opc = 0b0100011#7 then (if f3 = 2#3 then mk .sw (immS i) else none)
  else if opc = 0b0010011#7 then
    (if f3 = 0#3 then mk .addi (immI i) else if f3 = 2#3 then mk .slti (immI i)
     else if f3 = 3#3 then mk .sltiu (immI i) else if f3 = 4#3 then mk .xori (immI i)
     else if f3 = 6#3 then mk .ori (immI i) else if f3 = 7#3 then mk .andi (immI i)
     else if f3 = 1#3 then (if f7 = 0#7 then mk .slli (immI i) else none)
     else -- f3 = 5
       (if f7 = 0#7 then mk .srli (immI i)
        else if f7 = 0b0100000#7 then mk .srai (immI i) else none))
  else if opc = 0b0110011#7 then
    (if f7 = 0#7 then
       (if f3 = 0#3 then mk .add 0 else if f3 = 1#3 then mk .sll 0
        else if f3 = 2#3 then mk .slt 0 else if f3 = 3#3 then mk .sltu 0
        else if f3 = 4#3 then mk .xor 0 else if f3 = 5#3 then mk .srl 0
        else if f3 = 6#3 then mk .or 0 else mk .and 0)
     else if f7 = 0b0100000#7 then
       (if f3 = 0#3 then mk .sub 0 else if f3 = 5#3 then mk .sra 0 else none)
     else none)
  else none

/-! ## 2 · Architectural state -/

/-- `x 0` is never read: `get` returns 0 for `x0` and `set` discards writes to it. -/
structure Arch where
  pc : W
  x  : BitVec 5 → W

def Arch.get (s : Arch) (r : BitVec 5) : W := if r = 0 then 0 else s.x r

def Arch.set (s : Arch) (r : BitVec 5) (v : W) : Arch :=
  if r = 0 then s else { s with x := fun j => if j = r then v else s.x j }

/-- Agreement on everything RV32I can observe: `pc` and `x0..x31` through `get`. -/
def Arch.Agree (a b : Arch) : Prop := a.pc = b.pc ∧ ∀ r, a.get r = b.get r

/-- The specification's state. `lastLoad` is ghost state used ONLY by erratum E's LW: the word
the host returned in the most recent load loop, 0 after reset. RV32I proper (`exec false`) never
reads it. -/
structure EState where
  arch     : Arch
  lastLoad : W

/-! ## 3 · The bus, as the pins carry it -/

/-- The loop's TYPE, driven on `uio_out[1:0]` in phase 0 (`busadapt8`'s `T_FETCH/T_LOAD/T_STORE`). -/
inductive Kind where
  | fetch | load | store
  deriving DecidableEq, Repr

def Kind.code : Kind → BitVec 2
  | .fetch => 1 | .load => 2 | .store => 3

/-- One 4-cycle bus loop: its type and the word the core drives on `uo_out`, low byte first. -/
structure Loop where
  kind : Kind
  out  : W
  deriving DecidableEq, Repr

/-- The four `(uo_out, uio_out[1:0])` pairs of a loop. In phase 0 `uio_out[1:0]` carries the
TYPE; in phases 1-3 it carries the phase. -/
def Loop.emit (l : Loop) : List (BitVec 8 × BitVec 2) :=
  [(l.out.extractLsb' 0 8, l.kind.code), (l.out.extractLsb' 8 8, 1),
   (l.out.extractLsb' 16 8, 2), (l.out.extractLsb' 24 8, 3)]

/-- The word the host returns in the loop that starts at cycle `c` (`ui_in`, low byte first). -/
def hostWord (h : Nat → BitVec 8) (c : Nat) : W :=
  (h (c + 3) ++ h (c + 2) ++ h (c + 1) ++ h c : BitVec 32)

/-! ## 4 · One instruction: RV32I (`e = false`) and RV32I-with-erratum-E (`e = true`) -/

/-- Shift amount: the low five bits. -/
def shamt (v : W) : Nat := (v.extractLsb' 0 5).toNat

/-- A control transfer to `t`: out of scope unless `t` is 4-aligned (RV32I raises
instruction-address-misaligned; the core has no traps). -/
def jumpTo (t : W) : Option W := if t.extractLsb' 0 2 = 0 then some t else none

/-- Execute one decoded instruction fetched at `s.arch.pc`. `lword` is the host's word in the
load loop (read only by LW). It returns the new state and the bus loops the instruction makes,
fetch included. `none` means out of scope. -/
def exec (e : Bool) (s : EState) (d : Dec) (lword : W) : Option (EState × List Loop) :=
  let a   := s.arch
  let pc  := a.pc
  let v1  := a.get d.rs1
  let v2  := a.get d.rs2
  let f   := Loop.mk .fetch pc
  let alu (v : W) : Option (EState × List Loop) :=
    some ({ s with arch := { a.set d.rd v with pc := pc + 4 } }, [f])
  let br (taken : Bool) : Option (EState × List Loop) :=
    if taken then (jumpTo (pc + d.imm)).map fun t => ({ s with arch := { a with pc := t } }, [f])
    else some ({ s with arch := { a with pc := pc + 4 } }, [f])
  match d.op with
  | .lui   => alu d.imm
  | .auipc => alu (pc + d.imm)
  | .jal   => (jumpTo (pc + d.imm)).map fun t =>
                ({ s with arch := { a.set d.rd (pc + 4) with pc := t } }, [f])
  | .jalr  => (jumpTo ((v1 + d.imm) &&& ~~~1#32)).map fun t =>
                ({ s with arch := { a.set d.rd (pc + 4) with pc := t } }, [f])
  | .beq   => br (v1 == v2)
  | .bne   => br (v1 != v2)
  | .blt   => br (v1.slt v2)
  | .bge   => br (!(v1.slt v2))
  | .bltu  => br (v1.ult v2)
  | .bgeu  => br (!(v1.ult v2))
  | .lw    =>
      let addr := v1 + d.imm
      if addr.extractLsb' 0 2 ≠ 0 then none else
      -- ERRATUM (LW): the fabricated core writes the PREVIOUS load loop's word.
      let v := if e then s.lastLoad else lword
      some ({ arch := { a.set d.rd v with pc := pc + 4 }, lastLoad := lword },
            [f, Loop.mk .load addr])
  | .sw    =>
      let addr := v1 + d.imm
      if addr.extractLsb' 0 2 ≠ 0 then none else
      some ({ s with arch := { a with pc := pc + 4 } },
            [f, Loop.mk .store addr, Loop.mk .store v2])
  | .addi  => alu (v1 + d.imm)
  | .slti  => alu (if v1.slt d.imm then 1 else 0)
  | .sltiu => alu (if v1.ult d.imm then 1 else 0)
  | .xori  => alu (v1 ^^^ d.imm)
  | .ori   => alu (v1 ||| d.imm)
  | .andi  => alu (v1 &&& d.imm)
  | .slli  => alu (v1 <<< shamt d.imm)
  | .srli  => alu (v1 >>> shamt d.imm)
  -- ERRATUM (SRAI): the fabricated core shifts logically.
  | .srai  => alu (if e then v1 >>> shamt d.imm else v1.sshiftRight (shamt d.imm))
  | .add   => alu (v1 + v2)
  | .sub   => alu (v1 - v2)
  | .sll   => alu (v1 <<< shamt v2)
  | .slt   => alu (if v1.slt v2 then 1 else 0)
  | .sltu  => alu (if v1.ult v2 then 1 else 0)
  | .xor   => alu (v1 ^^^ v2)
  | .srl   => alu (v1 >>> shamt v2)
  -- ERRATUM (SRA): the fabricated core shifts logically.
  | .sra   => alu (if e then v1 >>> shamt v2 else v1.sshiftRight (shamt v2))
  | .or    => alu (v1 ||| v2)
  | .and   => alu (v1 &&& v2)

/-- One instruction against a host, starting at cycle `c`. The fetch loop is cycles `c..c+3`;
a load or store's loops follow it. It returns the new state, the cycle at which the instruction
ends, and its loops. -/
def stepH (e : Bool) (h : Nat → BitVec 8) (s : EState) (c : Nat) :
    Option (EState × Nat × List Loop) := do
  let d ← decode (hostWord h c)
  let (s', ls) ← exec e s d (hostWord h (c + 4))
  pure (s', c + 4 * ls.length, ls)

/-- The initial specification state: `pc = 0`, the given register file, `lastLoad = 0`
(`busadapt8` resets `rdata_r` to 0). -/
def EState.init (r0 : BitVec 5 → W) : EState := ⟨⟨0, r0⟩, 0⟩

/-- `k` instructions against host `h`: final state, end cycle, and every loop so far, in order. -/
def runSpec (e : Bool) (h : Nat → BitVec 8) (r0 : BitVec 5 → W) :
    Nat → Option (EState × Nat × List Loop)
  | 0     => some (EState.init r0, 0, [])
  | k + 1 => do
      let (s, c, ls) ← runSpec e h r0 k
      let (s', c', ls') ← stepH e h s c
      pure (s', c', ls ++ ls')

/-! ## 5 · The implementation side: a pin machine -/

/-- A synchronous machine seen from its pins. W1 instantiates it with the Lean model of
`core32` + `busadapt8` and links that model to the fabricated RTL by SAT.
* `reset r0` is the state ONE clock edge after `rst_n` low, with register file `r0`. The register
  file has no reset, so `r0` is arbitrary and the claim quantifies over it.
* `step σ b` is one clock edge with `rst_n` high, `sof` low and `ui_in = b`.
* `out σ b` is `(uo_out, uio_out[1:0])` during that cycle. It may depend on `b` (Mealy), so the
  statement makes no assumption that the outputs are registered.
* `arch σ` reads `pc_r` and `regs[1..31]`. -/
structure PinMachine where
  St    : Type
  reset : (BitVec 5 → W) → St
  step  : St → BitVec 8 → St
  out   : St → BitVec 8 → BitVec 8 × BitVec 2
  arch  : St → Arch

/-- The machine's state at cycle `t` under host `h`. -/
def PinMachine.run (M : PinMachine) (r0 : BitVec 5 → W) (h : Nat → BitVec 8) : Nat → M.St
  | 0     => M.reset r0
  | t + 1 => M.step (M.run r0 h t) (h t)

/-! ## 6 · THE STATEMENT -/

/-- **`M` refines RV32I-with-erratum-E.** Take any initial register file and any host byte stream.
Whenever the first `k` instructions are in scope, the pins in every cycle before the end of
instruction `k` are exactly the predicted ones, and at that cycle `pc` and `x0..x31` agree with
the specification. Black-box form: the pin clause alone is everything an observer at the pins can
see. -/
def RefinesE (M : PinMachine) : Prop :=
  ∀ (r0 : BitVec 5 → W) (h : Nat → BitVec 8) (k : Nat) (s : EState) (c : Nat) (ls : List Loop),
    runSpec true h r0 k = some (s, c, ls) →
      (∀ t, t < c → (ls.flatMap Loop.emit)[t]? = some (M.out (M.run r0 h t) (h t))) ∧
      Arch.Agree (M.arch (M.run r0 h c)) s.arch

/-- The same proposition against PLAIN RV32I. The fabricated core does NOT satisfy it: the bus
formal check refutes it on SRA, SRAI and LW. It is stated so that the difference between the two
claims is exactly the `e` flag. -/
def RefinesRV32I (M : PinMachine) : Prop :=
  ∀ (r0 : BitVec 5 → W) (h : Nat → BitVec 8) (k : Nat) (s : EState) (c : Nat) (ls : List Loop),
    runSpec false h r0 k = some (s, c, ls) →
      (∀ t, t < c → (ls.flatMap Loop.emit)[t]? = some (M.out (M.run r0 h t) (h t))) ∧
      Arch.Agree (M.arch (M.run r0 h c)) s.arch

end SaltWorks.Silicon.Refine
