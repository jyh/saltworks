/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Tactic.AuditAxioms

/-!
# Slice A — the five-instruction RV32I datapath, as Lean

Maestro's 20:31 build order: *"the freeze's far side must EXIST before the
freeze finalizes: land the minimal ISA triple (`Instr`, `St`, `step`)."* Until
this file, `docs/hdl-codegen-freeze-v1.md` was a freeze about an absent seam —
`grep` returned **zero** hits fleet-wide for `inductive Instr`, `structure St`
and `def decode`, and three of its five kill-checks were unrunnable for that one
reason.

`St` is taken verbatim from `docs/EVIDENCE-riscv-datapath-brief.md:108-112`, and
the instruction set is that document's §2.2: `ADD`, `ADDI`, `XOR`, `SLT`, `BEQ`.

## Which `step` this is, and why BOTH signatures are here

I proposed landing only `step : St → Instr → St` — an interpreter over abstract
syntax — and stated the weakening out loud before building: *it cannot catch an
encoding bug, so the "RV32I" claim is correspondingly weaker.* **The evidence
seat, which owns W2.1, overruled that on a reason I had not considered and which
is decisive: W2.4's differential test (K2b) runs against an INDEPENDENT
third-party RV32I simulator, and such a simulator consumes 32-bit ENCODED WORDS
— so without `encode` the kill-check cannot be run at all.** The encoder is
therefore in this file, not on a manifest.

So both signatures are present and the relationship between them is a theorem:

* `step  : St → Instr    → St`        — the semantics, structural, total;
* `stepW : St → BitVec 32 → Option St` — the brief's own signature, `decode`
  followed by `step`, partial exactly where Slice A excludes an encoding;
* `decode_encode : decode (encode i) = some i` — the round-trip, and
* `stepW_encode` — the two agree.

**The round-trip is what makes "RV32I" a checkable claim rather than a label**,
and this file should be read as claiming exactly that and nothing more: *a
five-instruction RV32I subset*, in the brief's own naming fence.

## The two conventions this file PINS, because the freeze found both underneath a bug

1. **The branch offset is a BYTE displacement from the branch's own address**
   (brief:248 — `pc + sext(imm)`, fall-through `pc + 4`). The freeze's §4.1 had
   emitted `|S| + 1`, an *instruction* count relative to the *next* instruction;
   both offsets were short by exactly one instruction and, worse, C6 named "an
   off-by-one branch offset" as its mutation control — so the mutant was the
   bug. Pinned here in executable form so it can never again be pinned in prose
   only.
2. **`x0` reads as zero, and writes to `x0` are discarded.** Enforced on BOTH
   sides deliberately: on the read so `St.get_zero` is unconditional and needs
   no invariant about `regs[0]`, and on the write so the silent-no-op trap the
   silicon seat found (P5: `ADD x0 x0 t0` compiles, runs, and changes nothing)
   is a *theorem of the semantics* rather than an accident of a bad allocator.

The `B`-immediate is `BitVec 12` holding `imm[12:1]`, per the ISA manual's *"the
12-bit B-immediate encodes signed offsets in multiples-of-two bytes"*. The low
zero bit is structural: it cannot be set, so an odd offset is unrepresentable
rather than silently truncated.
-/

namespace SaltWorks.ISA

/-- The machine state. Verbatim from the datapath brief, §2.1.

`Vector`, not a function and not a `HashMap`: the brief's measurement `[V-ME]`
puts `Vector` best for kernel `decide` (2,048-case regfile check in 2.4 s) and
unusable under `bv_decide`, which is banned from shipped proofs anyway.

⬥ **M1 (memory block v1.4) — `mem` and `trapped` join the state and are INERT
here.** No arm of `step` reads or writes either field in this commit: the LW/SW
constructors, their arms, and every exhaustive `Instr` match ride the M2
Instr-atomic commit, because `decode_encode` is `∀`-quantified over `Instr` and a
stub `encode` arm would make a landed theorem FALSE. The fields land now so the
`St` type growth is one atomic commit with its own census (the boundary law:
*one type growth per atomic commit*).

Every existing arm is built from `s.set` / `s.next` / `s.get` and one
`{ s with pc := … }`, i.e. `with`-updates that copy what they do not name — so
**no slice-A instruction can dirty `mem` or `trapped`**, and cleanliness
propagates through arbitrary runs of the current machine with no extra lemma. -/
structure St where
  regs    : Vector (BitVec 32) 32
  pc      : BitVec 32
  /-- The data memory: EIGHT words (`dmem8`'s true size), never sixteen. -/
  mem     : Vector (BitVec 32) 8
  /-- Sticky trap flag. Set by a misaligned or out-of-range LW/SW at M2; nothing
  in this commit can set it. -/
  trapped : Bool
  deriving DecidableEq

/-- The address classification for LW/SW, a TOTAL function into three values so
no case can be missed. -/
inductive AddrClass where
  | ok
  | misaligned
  | outOfRange
  deriving DecidableEq, Repr

/-- **The kernel classification boundary** (memory block §0.3): `outOfRange ↔
byte address ≥ 32` — eight words, `dmem8`'s true size, never the 16-word figure
the existing mask would suggest.

⚠️ **The order of the tests is chosen so that boundary reads as stated**: a
misaligned address at or above 32 classifies `outOfRange`, not `misaligned`. Had
alignment been tested first, `outOfRange ↔ byte_addr ≥ 32` would be FALSE — the
block states the equivalence, so the range test comes first. -/
def addrClass (a : BitVec 32) : AddrClass :=
  if 32 ≤ a.toNat then .outOfRange
  else if a.toNat % 4 ≠ 0 then .misaligned
  else .ok

/-- **THE LOAD-BEARING SAFETY PROPERTY — a required M1 deliverable** (§0.3).
Totality is not what makes the classification safe; *this* is: an `ok` address
has a word index inside the eight-word file, which is the fact `step` will need
at M2 to construct the `Vector 8` index. The consumer arrives one commit later;
landing the definition and its lemma together is the cheap direction. -/
theorem addrClass_ok_lt {a : BitVec 32} (h : addrClass a = .ok) : a.toNat / 4 < 8 := by
  by_cases h32 : 32 ≤ a.toNat
  · simp [addrClass, h32] at h
  · omega

/-- Slice A **plus the two v1 memory ops (M2)**. Seven instructions, and the
stated exclusions are everything else: no `LUI`/`AUIPC`, no `JAL`/`JALR`, no
shifts, no `M`, no CSRs, no privilege modes.

⬥ **M2 amended this docstring's own claim.** It read *"no loads, no stores …
no memory model at all"*, and that sentence was true until this commit and is
false after it. **WORD-ONLY** (memory block §0.1): `LW`/`SW` and nothing else —
no `LB`/`LH`/`LBU`/`LHU`/`SB`/`SH`, so there are no byte semantics to get
wrong. The two new arms are the ONLY instructions that read or write `mem` or
can set `trapped`; `touchesMem` below is that fact as a decidable function. -/
inductive Instr where
  /-- `rd := rs1 + rs2`, wrapping. -/
  | ADD  (rd rs1 rs2 : Fin 32)
  /-- `rd := rs1 + sext(imm)`. The 12-bit immediate is SIGN-extended — the brief
  calls this "the single most common formalisation bug". -/
  | ADDI (rd rs1 : Fin 32) (imm : BitVec 12)
  /-- `rd := rs1 ^^^ rs2`. -/
  | XOR  (rd rs1 rs2 : Fin 32)
  /-- `rd := if rs1 <ₛ rs2 then 1 else 0`. SIGNED — this is literally the
  instruction the sp1-lean audit found vacuously true. -/
  | SLT  (rd rs1 rs2 : Fin 32)
  /-- `if rs1 = rs2 then pc += sext(imm ++ 0) else pc += 4`. `imm` holds
  `imm[12:1]`; the low zero bit is structural. -/
  | BEQ  (rs1 rs2 : Fin 32) (imm : BitVec 12)
  /-- ⬥ **M2 — `rd := mem[(rs1 + sext(imm)) / 4]`**, WORD-addressed into the
  eight-word file. I-type, opcode `0000011`, funct3 `010`. On a misaligned or
  out-of-range address the load is suppressed and `trapped` is set — see
  `step`'s docstring for the fence. -/
  | LW   (rd rs1 : Fin 32) (imm : BitVec 12)
  /-- ⬥ **M2 — `mem[(rs1 + sext(imm)) / 4] := rs2`**. S-type, opcode `0100011`,
  funct3 `010`. The immediate is split across two fields in the encoding; that
  scrambling lives in `wS`. -/
  | SW   (rs1 rs2 : Fin 32) (imm : BitVec 12)
  deriving DecidableEq

/-- ⬥ **M2 — THE MEMORY DISCRIMINATOR** (helm ruling, 2026-08-11 16:48). True
exactly on the two ops that can read or write `mem`, or set `trapped`.

🔑 **Why a named decidable function rather than a constructor enumeration in
each statement:** the frame laws below it are *conditional* — they hold for the
instructions that do not touch memory — and a statement that enumerated
`ADD/ADDI/XOR/SLT/BEQ` would have to be edited by every future op author, who
would have no way to know that omitting their constructor silently WIDENS a
theorem into falsity. **The discriminator makes the hypothesis mechanical: a
new memory op sets this true and every frame law narrows itself.**

⬥⬥ **D2 CONVERTED THE CATCH-ALL TO EXHAUSTIVE ARMS** (Captain's ruling 8/11
19:05: *exhaustive arms preferred; catch-alls only where enumeration is genuinely
impractical*, and this seat's standing disposition — `touchesMem` converts on
next touch, in its own file, needing no exception). **D2 is that touch.**

🔑 ***The catch-all was the hazard the ruling names: `| _ => false` silently
classifies EVERY future constructor as memory-free.*** *A new memory op added by
a later author would land as `touchesMem = false`, and every frame law
conditional on it would WIDEN INTO FALSITY without a single red build — the
author having no way to know the omission mattered.* **With the arms enumerated,
the same edit fails to compile until they answer the question.** -/
def touchesMem : Instr → Bool
  | .LW   _ _ _ => true
  | .SW   _ _ _ => true
  | .ADD  _ _ _ => false
  | .ADDI _ _ _ => false
  | .XOR  _ _ _ => false
  | .SLT  _ _ _ => false
  | .BEQ  _ _ _ => false

/-- Register read. **`x0` reads as zero unconditionally** — not as an invariant
about `regs[0]`, but as a fact about the read port, which is what the hardware
does and what makes `get_zero` need no hypothesis. -/
def St.get (s : St) (r : Fin 32) : BitVec 32 :=
  if r = 0 then 0 else s.regs[r.val]

/-- Register write. **A write to `x0` is DISCARDED.** This is P5 of the freeze,
found by the silicon seat: `compile (assign x e)` ends `[ADD (reg x) x0 t0]`, so
if the variable map ever sends a source variable to `x0` the assignment is a
silent no-op. Putting the suppression here makes that a provable property of the
machine rather than a latent surprise in the allocator. -/
def St.set (s : St) (r : Fin 32) (v : BitVec 32) : St :=
  if r = 0 then s else { s with regs := s.regs.set r.val v }

/-- Fall through: `pc + 4`. -/
def St.next (s : St) : St := { s with pc := s.pc + 4 }

/-- The byte displacement a `BEQ` immediate denotes: `imm` holds `imm[12:1]`, so
the displacement is `sext(imm) * 2`. Range `[-4096, 4094]`, even by
construction. -/
def bOffset (imm : BitVec 12) : BitVec 32 := (imm.signExtend 32) <<< 1

/-- **The ISA spec.** One instruction, one state transition, total, structurally
recursive, no fuel and no side conditions.

🔴 ⬥ **M2 — THE TRAP-SEMANTICS FENCE** (memory block §0.3, at O7 strength, placed
here because a reader meets the code before they meet the block):

> **On a misaligned or out-of-range LW/SW address this machine suppresses the
> write, advances PC+4, and sets a sticky `trapped` flag. That is a deliberate
> v1 semantics, NOT RV32I — RV32I raises a load/store-address-misaligned or
> access-fault exception.**

⚠️ **THIS IS THE SECOND NON-CONFORMANCE FENCE, AND IT DOES NOT RETIRE THE
FIRST.** The undecodable-word fence (at `stepT` below) still stands: a word
outside the decodable set advances PC+4 with **no** trap, while these two ops
carry real trap arms. ***Both must be said wherever either is quoted*** — they
bound different things (which instructions exist vs. what a bad address does),
and neither implies the other.

📌 **The suppression is the load-bearing term, not the flag** (the silicon
lesson): a trapped step writes no register and no memory cell. It is not a
no-op, though — it sets `trapped` and advances `pc`, which is why the frame
laws in `Stack/Program.lean` are conditional on `touchesMem`.

⚠️ **WHY THE ARMS BRANCH ON `= .ok` RATHER THAN MATCHING THE THREE CLASSES.**
`addrClass` remains the TOTAL three-valued classification — that is where "no
case can be missed" lives, and `addrClass_ok_lt` is what licenses the `Vector 8`
index. But **`misaligned` and `outOfRange` are specified to produce the IDENTICAL
response** (§0.3: write suppressed, `trapped := true`, pc advances; §2 restates
it as the fact the F4 bridge relates *responses*, not class labels). Writing one
`else` says that once, instead of duplicating a branch and inviting the two to
drift apart. *The classification is three-valued; the machine's answer to a bad
address is one-valued, and this is where that stops being a comment.* -/
def step (s : St) : Instr → St
  | .ADD  rd a b   => (s.set rd (s.get a + s.get b)).next
  | .ADDI rd a imm => (s.set rd (s.get a + imm.signExtend 32)).next
  | .XOR  rd a b   => (s.set rd (s.get a ^^^ s.get b)).next
  | .SLT  rd a b   => (s.set rd (if (s.get a).slt (s.get b) then 1 else 0)).next
  | .BEQ  a b imm  =>
      if s.get a = s.get b then { s with pc := s.pc + bOffset imm } else s.next
  | .LW   rd a imm =>
      let addr := s.get a + imm.signExtend 32
      if h : addrClass addr = .ok then
        (s.set rd (s.mem[addr.toNat / 4]'(addrClass_ok_lt h))).next
      else { s with trapped := true }.next
  | .SW   a b imm  =>
      let addr := s.get a + imm.signExtend 32
      if h : addrClass addr = .ok then
        { s with mem := s.mem.set (addr.toNat / 4) (s.get b) (addrClass_ok_lt h) }.next
      else { s with trapped := true }.next

/-- Instruction fetch. **`pc` is a BYTE address** and instructions are four bytes
wide, so a misaligned `pc` fetches nothing rather than rounding down. This is
convention 1 above, made executable. -/
def fetch (code : List Instr) (pc : BitVec 32) : Option Instr :=
  if pc.toNat % 4 = 0 then code[pc.toNat / 4]? else none

/-- Bounded iteration. **Structural on a `Nat`**, deliberately: the refuter pass
established that well-founded recursion on `code.length - pc` would not reduce in
the kernel (`Sem.lean:18-21`), which would make the certificate suite impossible.
This shape is kernel-reducible and puts **no fuel parameter in any theorem**,
because `run` supplies the bound itself. -/
def runFor : Nat → List Instr → St → St
  | 0,     _,    s => s
  | n + 1, code, s =>
      match fetch code s.pc with
      | none   => s
      | some i => runFor n code (step s i)

/-- **Whole-program execution** — the freeze's `step*`, and row 7 of its seam
manifest, which was unowned until now.

⛔⛔ **THIS DOCSTRING CLAIMED "every branch the code generator emits is forward", AND THAT
SENTENCE DIED WHEN L2's `while` CLAUSE LANDED.** `compileS` now emits a BACKWARD `BEQ` to
close a loop, so `pc` no longer strictly increases and `code.length` is **not** a sufficient
bound for a program containing one.

✅ **`run` IS STILL CORRECT — ON THE BRANCH-FREE FRAGMENT, which is exactly where it is now
used.** *`run_compileS_correct_of_branchFree` carries the `branchFree` hypothesis for this
reason, and `BlockCalc.run_has_too_little_fuel_for_a_loop` is the landed proof that no
`run`-shaped statement can cover a loop: `run` spends one tick per instruction and a loop
needs more ticks than the program has instructions.*

🔑 ***A LOOP'S CORRECTNESS IS THEREFORE `Reaches`-SHAPED, NEVER `run`-SHAPED*** — see
`reaches_of_compileS_including_while`. **The claim above was true for as long as the
fragment was straight-line, and it sat under a true theorem, which is the shape a green
build cannot catch: `run` itself never changed.** -/
def run (code : List Instr) (s : St) : St := runFor code.length code s

/-- The initial state: zeroed registers, `pc = 0`. -/
def St.init : St :=
  { regs := Vector.replicate 32 0, pc := 0,
    mem := Vector.replicate 8 0, trapped := false }

/-! ## The register-file laws

Proved structurally from the core `Vector` lemmas, not by enumeration. The
brief's 2,048-case check is a certificate, not the proof. -/

/-- `x0` reads zero. **No hypothesis** — this is the point of enforcing on the
read port rather than by an invariant on `regs`. -/
@[simp] theorem St.get_zero (s : St) : s.get 0 = 0 := by
  simp [St.get]

/-- A write to `x0` changes nothing at all. **This is P5, as a theorem.** -/
@[simp] theorem St.set_zero (s : St) (v : BitVec 32) : s.set 0 v = s := by
  simp [St.set]

/-- Read-over-write, same index — for any writable register. -/
theorem St.get_set_self (s : St) (r : Fin 32) (v : BitVec 32) (h : r ≠ 0) :
    (s.set r v).get r = v := by
  simp [St.get, St.set, h]

/-- Read-over-write, different index. Note it holds for `r' = 0` too, since both
sides are then `0`. -/
theorem St.get_set_ne (s : St) (r r' : Fin 32) (v : BitVec 32) (h : r' ≠ r) :
    (s.set r v).get r' = s.get r' := by
  by_cases hr : r = 0
  · simp [hr]
  · by_cases hr' : r' = 0
    · simp [hr']
    · simp only [St.get, St.set, hr, hr', if_false]
      exact Vector.getElem_set_ne r.isLt r'.isLt (fun hh => h (Fin.ext hh.symm))

/-- Writing `x0` cannot be observed, from any register. The frame fact the code
generator's C2 needs at `d = 0`, where C2 itself is vacuous. -/
theorem St.get_set_zero (s : St) (r : Fin 32) (v : BitVec 32) :
    (s.set 0 v).get r = s.get r := by
  simp

/-! ## The three traps the brief names, each as an executable certificate

`decide +kernel`, never bare `decide`. Each is stated about an OBSERVATION (a
`BitVec 32` or a `pc`) rather than about whole-state equality, so the kernel
compares words rather than a 32-element `Vector`. -/

/-- **TRAP 1 — `ADDI` SIGN-EXTENDS.** The brief calls this "the single most
common formalisation bug". `ADDI x1, x0, -1` must leave `0xFFFFFFFF`, not
`0x00000FFF`. -/
theorem addi_sign_extends :
    (step St.init (.ADDI 1 0 (BitVec.ofInt 12 (-1)))).get 1 = 0xFFFFFFFF := by
  decide +kernel

/-- **TRAP 2 — `SLT` IS SIGNED.** The sp1-lean audit found exactly this
instruction vacuously true. `-1 <ₛ 1` is TRUE; unsigned it would be false, since
`-1` is `0xFFFFFFFF`. Built with two `ADDI`s so the certificate exercises the
datapath rather than a hand-built state. -/
theorem slt_is_signed :
    let s₁ := step St.init (.ADDI 1 0 (BitVec.ofInt 12 (-1)))
    let s₂ := step s₁ (.ADDI 2 0 1)
    (step s₂ (.SLT 3 1 2)).get 3 = 1 := by
  decide +kernel

/-- **TRAP 2b — and it is not vacuous in the other direction either.** `1 <ₛ -1`
is false. Without this, `slt_is_signed` is satisfied by a `SLT` that always
returns 1. -/
theorem slt_is_signed' :
    let s₁ := step St.init (.ADDI 1 0 (BitVec.ofInt 12 (-1)))
    let s₂ := step s₁ (.ADDI 2 0 1)
    (step s₂ (.SLT 3 2 1)).get 3 = 0 := by
  decide +kernel

/-- **TRAP 2c — `XOR` IS EXCLUSIVE, AND UNTIL NOW NOTHING IN THIS REPOSITORY
SAID SO.** *Found by the C2 witness suite, not by review: `XOR` was the only one
of Slice A's five instructions with no certificate anywhere, so mutating it to
`|||` built clean and was caught solely by Spike* (`SaltWorks/HDL/SpikeVectors.lean`,
MUT-A). **`3 ^^^ 1 = 2`, where `or` gives 3 and `and` gives 1** — one certificate
separating XOR from both neighbours it is plausibly confused with. -/
theorem xor_is_exclusive :
    let s₁ := step St.init (.ADDI 1 0 3)
    let s₂ := step s₁ (.ADDI 2 0 1)
    (step s₂ (.XOR 3 1 2)).get 3 = 2 := by
  decide +kernel

/-- **And `XOR` is self-annihilating**, which `or` and `and` both fail — they
return `x`. *Without this, `xor_is_exclusive` alone is still satisfied by a
handful of wrong functions.* -/
theorem xor_self_is_zero :
    let s₁ := step St.init (.ADDI 1 0 7)
    (step s₁ (.XOR 3 1 1)).get 3 = 0 := by
  decide +kernel

/-- **TRAP 3 — `BEQ x0 x0` IS TAKEN.** The freeze's §4.1 compiles `ite` with an
always-true `BEQ` because Slice A excludes `JAL`, and kill-check R4 asked for
exactly this confirmation against `step` *as landed* — the half of R4 that was
unrunnable until this file existed. Offset `2` denotes `2 * 2 = 4` bytes. -/
theorem beq_x0_x0_taken :
    (step St.init (.BEQ 0 0 2)).pc = 4 := by
  decide +kernel

/-- **And `BEQ` on unequal registers falls through**, so the above is not
satisfied by a `BEQ` that always branches. -/
theorem beq_not_taken :
    let s₁ := step St.init (.ADDI 1 0 1)
    (step s₁ (.BEQ 1 0 2)).pc = 8 := by
  decide +kernel

/-- **P5 AS AN EXECUTABLE CERTIFICATE — the silent no-op.** `ADD x0 x0 x1` runs,
advances the `pc`, and leaves `x0` reading zero. A generator whose variable map
sends a source variable to `x0` produces a program that compiles, executes, and
never changes the variable. -/
theorem x0_write_is_a_silent_noop :
    let s₁ := step St.init (.ADDI 1 0 7)
    let s₂ := step s₁ (.ADD 0 0 1)
    s₂.get 0 = 0 ∧ s₂.pc = 8 := by
  decide +kernel

/-- **The byte convention, executable.** A `BEQ` with immediate `n` moves the
`pc` by `2 * n` bytes from the branch's OWN address — not `n`, and not from the
next instruction. This is the fact the freeze's §4.1 had wrong in prose. -/
theorem beq_offset_is_bytes_from_own_address :
    (step St.init (.BEQ 0 0 6)).pc = 12 := by
  decide +kernel

/-- **Backward branches are representable** — the offset is signed. Stated
because the code generator promises never to emit one, and a promise about a
thing the machine cannot do is not a promise. -/
theorem beq_offset_can_be_negative :
    let s₁ := step St.init (.BEQ 0 0 4)          -- pc := 8
    (step s₁ (.BEQ 0 0 (BitVec.ofInt 12 (-2)))).pc = 4 := by
  decide +kernel

/-! ## Non-vacuity of `run`

The K1 obligation: a theorem about `run` is worthless if `run` never executes
anything. -/

/-- `run` executes a whole program: two `ADDI`s and an `ADD`, ending with the
`pc` off the end of the code. -/
theorem run_executes :
    let code : List Instr := [.ADDI 1 0 20, .ADDI 2 0 22, .ADD 3 1 2]
    let s := run code St.init
    s.get 3 = 42 ∧ s.pc = 12 := by
  decide +kernel

/-- **`run` HALTS at the end rather than reading past it** — `fetch` returns
`none` and `runFor` stops, so the bound is sufficient and not merely large. -/
theorem run_halts_off_the_end :
    let code : List Instr := [.ADDI 1 0 1]
    (runFor 100 code St.init).pc = 4 := by
  decide +kernel

/-- **A forward `BEQ` skips**, which is the whole of the freeze's `ite` scheme in
one certificate: the branch is taken, the skipped instruction does not run, and
the register it would have written still reads zero. -/
theorem run_forward_branch_skips :
    let code : List Instr := [.BEQ 0 0 4, .ADDI 1 0 99, .ADDI 2 0 5]
    let s := run code St.init
    s.get 1 = 0 ∧ s.get 2 = 5 := by
  decide +kernel

/-! ## The encoding — `encode`, `decode`, and the round-trip

**Added on the evidence seat's ruling (20:38), which overrode my own proposal to
defer it, on a reason I had not considered and which is decisive:** W2.4 is
differential testing against an **independent third-party RV32I simulator**
(kill-check K2b), and such a simulator consumes **32-bit encoded words**. It
cannot be handed an abstract `Instr`. ⇒ **without `encode`, K2b cannot be run at
all** — and K2b is one of the three kill-checks the datapath brief was built
around. Two further reasons from the same ruling: W2.1's line item names
`decode` explicitly, and the brief's own naming fence (*"never say core — say
RV32I subset"*) is not honoured by a tower that never touches an RV32I encoding.

The field layouts below are the manual's, `src/unpriv/rv32.adoc`:

```
R-type   funct7[31:25] rs2[24:20] rs1[19:15] funct3[14:12] rd[11:7] opcode[6:0]
I-type   imm[11:0][31:20]         rs1[19:15] funct3[14:12] rd[11:7] opcode[6:0]
B-type   imm[12]|imm[10:5]        rs2 rs1 funct3  imm[4:1]|imm[11]  opcode
```

⚠️ **B-TYPE IS THE SCRAMBLED ONE AND IT IS WHY THIS SECTION EXISTS.** The
immediate's bits are split across two non-adjacent fields *and reordered*:
`imm[11]` sits alone at bit 7, below `imm[4:1]`, while `imm[12]` sits at bit 31.
This file's `imm : BitVec 12` holds `imm[12:1]`, so **this file's bit `j` is the
manual's `imm[j+1]`** — the one index shift that every RISC-V formalisation has
to get right exactly once. -/

/-- A register index as a 5-bit field. -/
def ofReg (r : Fin 32) : BitVec 5 := BitVec.ofNat 5 r.val

/-- A 5-bit field as a register index. Total: every 5-bit pattern names a
register, which is why the register fields need no validity check. -/
def toReg (b : BitVec 5) : Fin 32 := ⟨b.toNat, by simpa using b.isLt⟩

@[simp] theorem toReg_ofReg (r : Fin 32) : toReg (ofReg r) = r := by decide +kernel +revert

/-! ### The three word layouts, as definitions

Each is the manual's field order, right-nested. The nesting is not cosmetic: it
is the shape the core append-extraction lemmas peel, and it is what makes every
field lemma below a three-line rewrite instead of a bit-blast.

**Why the fields are separate lemmas rather than one `simp` call**, recorded
because it cost three attempts: `simp` cannot fire
`BitVec.extractLsb'_append_eq_of_add_le` on these goals at all — the widths in
the goal are literals (`25`, `12`) while the lemma's are unreduced sums
(`5 + (5 + (3 + (5 + 7)))`), and simp's matcher will not close that gap.
`rw` will, because its unifier reduces numerals. So the peeling happens once per
field, on a goal small enough to be cheap, and the resulting equations are
ordinary syntactic rewrites that `simp` *can* use. A single `repeat rw` over the
whole five-branch `decode` goal exhausted the heartbeat budget twice. -/

/-- R-type: `funct7 rs2 rs1 funct3 rd opcode`. -/
def wR (f3 : BitVec 3) (rd a b : Fin 32) : BitVec 32 :=
  0#7 ++ (ofReg b ++ (ofReg a ++ (f3 ++ (ofReg rd ++ 0b0110011#7))))

/-- I-type: `imm[11:0] rs1 funct3 rd opcode`.

⬥ **M2 GENERALIZED this layout**: `opcode` and `funct3` were baked in at
`(0b0010011, 000)` when `ADDI` was the only I-type instruction. `LW` is I-type
too, at `(0b0000011, 010)`, so both become parameters and the two field lemmas
that used to conclude with a literal now read the parameter back. -/
def wI (op : BitVec 7) (f3 : BitVec 3) (imm : BitVec 12) (rd a : Fin 32) : BitVec 32 :=
  imm ++ (ofReg a ++ (f3 ++ (ofReg rd ++ op)))

/-- S-type: `imm[11:5] rs2 rs1 funct3 imm[4:0] opcode`. **The immediate arrives
in TWO pieces** — fewer than B-type's four, but the low piece sits in the slot
an R-type would use for `rd`, which is the whole reason a store has no `rd`.

📌 *S-type and R-type have the SAME FIELD WIDTHS* (`7 · 5 · 5 · 3 · 5 · 7`);
only the meanings differ, which is why every field lemma below mirrors `wR`'s
script exactly. -/
def wS (i115 : BitVec 7) (i40 : BitVec 5) (a b : Fin 32) : BitVec 32 :=
  i115 ++ (ofReg b ++ (ofReg a ++ (0b010#3 ++ (i40 ++ 0b0100011#7))))

/-- B-type: `imm[12] imm[10:5] rs2 rs1 funct3 imm[4:1] imm[11] opcode`. **The
immediate arrives in four pieces and two of them are out of order** — this
definition is where that is written down once. -/
def wB (i11 : BitVec 1) (i94 : BitVec 6) (i30 : BitVec 4) (i10 : BitVec 1)
    (a b : Fin 32) : BitVec 32 :=
  i11 ++ (i94 ++ (ofReg b ++ (ofReg a ++ (0#3 ++ (i30 ++ (i10 ++ 0b1100011#7))))))

/-! ### The field lemmas — every field of every layout, read back out -/

/-- `funct7` is zero for all three R-type instructions of Slice A. -/
theorem wR_f7 (f3 : BitVec 3) (rd a b : Fin 32) :
    (wR f3 rd a b).extractLsb' 25 7 = 0#7 := by
  unfold wR
  rw [BitVec.extractLsb'_append_eq_left]

/-- `rs2`. -/
theorem wR_rs2 (f3 : BitVec 3) (rd a b : Fin 32) :
    (wR f3 rd a b).extractLsb' 20 5 = ofReg b := by
  unfold wR
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_left]

/-- `rs1`. -/
theorem wR_rs1 (f3 : BitVec 3) (rd a b : Fin 32) :
    (wR f3 rd a b).extractLsb' 15 5 = ofReg a := by
  unfold wR
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_left]

/-- `funct3` — the field that separates ADD from XOR from SLT. -/
theorem wR_f3 (f3 : BitVec 3) (rd a b : Fin 32) :
    (wR f3 rd a b).extractLsb' 12 3 = f3 := by
  unfold wR
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_left]

/-- `rd`. -/
theorem wR_rd (f3 : BitVec 3) (rd a b : Fin 32) :
    (wR f3 rd a b).extractLsb' 7 5 = ofReg rd := by
  unfold wR
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_left]

/-- The opcode. -/
theorem wR_op (f3 : BitVec 3) (rd a b : Fin 32) :
    (wR f3 rd a b).extractLsb' 0 7 = 0b0110011#7 := by
  unfold wR
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_right]

/-- The 12-bit immediate, whole and unscrambled — I-type is the easy one. -/
theorem wI_imm (op : BitVec 7) (f3 : BitVec 3) (imm : BitVec 12) (rd a : Fin 32) :
    (wI op f3 imm rd a).extractLsb' 20 12 = imm := by
  unfold wI
  rw [BitVec.extractLsb'_append_eq_left]

/-- `rs1`. -/
theorem wI_rs1 (op : BitVec 7) (f3 : BitVec 3) (imm : BitVec 12) (rd a : Fin 32) :
    (wI op f3 imm rd a).extractLsb' 15 5 = ofReg a := by
  unfold wI
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_left]

/-- `funct3` — ⬥ M2: was `= 0#3` (ADDI's literal); now reads the parameter back,
so `000` selects ADDI and `010` selects LW. -/
theorem wI_f3 (op : BitVec 7) (f3 : BitVec 3) (imm : BitVec 12) (rd a : Fin 32) :
    (wI op f3 imm rd a).extractLsb' 12 3 = f3 := by
  unfold wI
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_left]

/-- `rd`. -/
theorem wI_rd (op : BitVec 7) (f3 : BitVec 3) (imm : BitVec 12) (rd a : Fin 32) :
    (wI op f3 imm rd a).extractLsb' 7 5 = ofReg rd := by
  unfold wI
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_left]

/-- The opcode — ⬥ M2: was `= 0b0010011#7` (OP-IMM's literal); now reads the
parameter back, so the one layout serves OP-IMM and LOAD. -/
theorem wI_op (op : BitVec 7) (f3 : BitVec 3) (imm : BitVec 12) (rd a : Fin 32) :
    (wI op f3 imm rd a).extractLsb' 0 7 = op := by
  unfold wI
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_right]

/-! ### S-type's fields — ⬥ M2 -/

/-- The immediate's HIGH piece, `imm[11:5]`, in bits 31:25. -/
theorem wS_i115 (i115 : BitVec 7) (i40 : BitVec 5) (a b : Fin 32) :
    (wS i115 i40 a b).extractLsb' 25 7 = i115 := by
  unfold wS
  rw [BitVec.extractLsb'_append_eq_left]

/-- `rs2` — the value being stored. -/
theorem wS_rs2 (i115 : BitVec 7) (i40 : BitVec 5) (a b : Fin 32) :
    (wS i115 i40 a b).extractLsb' 20 5 = ofReg b := by
  unfold wS
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_left]

/-- `rs1` — the base address register. -/
theorem wS_rs1 (i115 : BitVec 7) (i40 : BitVec 5) (a b : Fin 32) :
    (wS i115 i40 a b).extractLsb' 15 5 = ofReg a := by
  unfold wS
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_left]

/-- `funct3` = `010` selects SW (word). -/
theorem wS_f3 (i115 : BitVec 7) (i40 : BitVec 5) (a b : Fin 32) :
    (wS i115 i40 a b).extractLsb' 12 3 = 0b010#3 := by
  unfold wS
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_left]

/-- **The immediate's LOW piece, `imm[4:0]`, in bits 11:7** — the S-type quirk:
this is the slot an R-type spends on `rd`, which is exactly why a store, having
no destination register, can afford to put immediate bits there. -/
theorem wS_i40 (i115 : BitVec 7) (i40 : BitVec 5) (a b : Fin 32) :
    (wS i115 i40 a b).extractLsb' 7 5 = i40 := by
  unfold wS
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_left]

/-- The STORE opcode. -/
theorem wS_op (i115 : BitVec 7) (i40 : BitVec 5) (a b : Fin 32) :
    (wS i115 i40 a b).extractLsb' 0 7 = 0b0100011#7 := by
  unfold wS
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_right]

/-- ⬥ **M2 — S-TYPE'S IMMEDIATE, PUT BACK TOGETHER**, as a NAMED fact rather
than as a step of `decode_encode`'s tactic.

📌 *Why named here when B-type's four-piece reassembly is left to the `repeat rw`
in `decode_encode`:* B-type needs the peel applied **iteratively** (`4 = 0+4`,
then `10 = 0+10`, then `11 = 0+11`), which is what `repeat` is for. S-type needs
it **exactly once** (`5 = 0+5`), and the `repeat rw` does not reach it under the
`SW` constructor — so the honest form is a one-line lemma that says what the
store's split immediate does, which is also the fact a reader wants stated. -/
theorem wS_imm_reassembles (imm : BitVec 12) :
    imm.extractLsb' 5 7 ++ imm.extractLsb' 0 5 = imm := by
  rw [BitVec.extractLsb'_append_extractLsb'_eq_extractLsb' (by omega)]
  simp

/-- Bit 31 carries the immediate's TOP bit — this file's bit 11. -/
theorem wB_i11 (i11 : BitVec 1) (i94 : BitVec 6) (i30 : BitVec 4) (i10 : BitVec 1) (a b : Fin 32) :
    (wB i11 i94 i30 i10 a b).extractLsb' 31 1 = i11 := by
  unfold wB
  rw [BitVec.extractLsb'_append_eq_left]

/-- Bits 30:25 carry this file's bits 9:4. -/
theorem wB_i94 (i11 : BitVec 1) (i94 : BitVec 6) (i30 : BitVec 4) (i10 : BitVec 1) (a b : Fin 32) :
    (wB i11 i94 i30 i10 a b).extractLsb' 25 6 = i94 := by
  unfold wB
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_left]

/-- `rs2`. -/
theorem wB_rs2 (i11 : BitVec 1) (i94 : BitVec 6) (i30 : BitVec 4) (i10 : BitVec 1) (a b : Fin 32) :
    (wB i11 i94 i30 i10 a b).extractLsb' 20 5 = ofReg b := by
  unfold wB
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_left]

/-- `rs1`. -/
theorem wB_rs1 (i11 : BitVec 1) (i94 : BitVec 6) (i30 : BitVec 4) (i10 : BitVec 1) (a b : Fin 32) :
    (wB i11 i94 i30 i10 a b).extractLsb' 15 5 = ofReg a := by
  unfold wB
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_left]

/-- `funct3` = 0 selects BEQ. -/
theorem wB_f3 (i11 : BitVec 1) (i94 : BitVec 6) (i30 : BitVec 4) (i10 : BitVec 1) (a b : Fin 32) :
    (wB i11 i94 i30 i10 a b).extractLsb' 12 3 = 0#3 := by
  unfold wB
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_left]

/-- Bits 11:8 carry this file's bits 3:0. -/
theorem wB_i30 (i11 : BitVec 1) (i94 : BitVec 6) (i30 : BitVec 4) (i10 : BitVec 1) (a b : Fin 32) :
    (wB i11 i94 i30 i10 a b).extractLsb' 8 4 = i30 := by
  unfold wB
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_left]

/-- **Bit 7 alone carries this file's bit 10** — the out-of-order one. -/
theorem wB_i10 (i11 : BitVec 1) (i94 : BitVec 6) (i30 : BitVec 4) (i10 : BitVec 1) (a b : Fin 32) :
    (wB i11 i94 i30 i10 a b).extractLsb' 7 1 = i10 := by
  unfold wB
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_left]

/-- The BRANCH opcode. -/
theorem wB_op (i11 : BitVec 1) (i94 : BitVec 6) (i30 : BitVec 4) (i10 : BitVec 1) (a b : Fin 32) :
    (wB i11 i94 i30 i10 a b).extractLsb' 0 7 = 0b1100011#7 := by
  unfold wB
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_of_add_le (by omega)]
  rw [BitVec.extractLsb'_append_eq_right]

/-- **The encoder**, in terms of the three layouts. -/
def encode : Instr → BitVec 32
  | .ADD  rd a b   => wR 0#3 rd a b
  | .XOR  rd a b   => wR 4#3 rd a b
  | .SLT  rd a b   => wR 2#3 rd a b
  | .ADDI rd a imm => wI 0b0010011#7 0#3 imm rd a
  | .BEQ  a b imm  =>
      wB (imm.extractLsb' 11 1) (imm.extractLsb' 4 6)
         (imm.extractLsb' 0 4)  (imm.extractLsb' 10 1) a b
  | .LW   rd a imm => wI 0b0000011#7 0b010#3 imm rd a
  | .SW   a b imm  => wS (imm.extractLsb' 5 7) (imm.extractLsb' 0 5) a b

/-- **The decoder.** Partial by construction: an encoding this slice does not
define returns `none` rather than a wrong instruction. That partiality is real
and is Slice A's stated exclusion list arriving as a function. -/
def decode (w : BitVec 32) : Option Instr :=
  let opcode := w.extractLsb' 0 7
  let rd     := toReg (w.extractLsb' 7 5)
  let funct3 := w.extractLsb' 12 3
  let rs1    := toReg (w.extractLsb' 15 5)
  let rs2    := toReg (w.extractLsb' 20 5)
  let funct7 := w.extractLsb' 25 7
  if opcode = 0b0110011#7 && funct7 = 0#7 then
    if funct3 = 0#3 then some (.ADD rd rs1 rs2)
    else if funct3 = 4#3 then some (.XOR rd rs1 rs2)
    else if funct3 = 2#3 then some (.SLT rd rs1 rs2)
    else none
  else if opcode = 0b0010011#7 && funct3 = 0#3 then
    some (.ADDI rd rs1 (w.extractLsb' 20 12))
  else if opcode = 0b1100011#7 && funct3 = 0#3 then
    -- Reassemble imm[12:1] from its four scrambled pieces, in THIS file's
    -- numbering: bit 11 from w[31], bit 10 from w[7], bits 9:4 from w[30:25],
    -- bits 3:0 from w[11:8].
    some (.BEQ rs1 rs2
      (w.extractLsb' 31 1 ++ (w.extractLsb' 7 1 ++
        (w.extractLsb' 25 6 ++ w.extractLsb' 8 4))))
  -- ⬥ M2. LOAD is I-type, so the immediate is whole and needs no reassembly.
  else if opcode = 0b0000011#7 && funct3 = 0b010#3 then
    some (.LW rd rs1 (w.extractLsb' 20 12))
  -- ⬥ M2. STORE is S-type: imm[11:5] from w[31:25], imm[4:0] from w[11:7].
  else if opcode = 0b0100011#7 && funct3 = 0b010#3 then
    some (.SW rs1 rs2 (w.extractLsb' 25 7 ++ w.extractLsb' 7 5))
  else none

/-- **THE ROUND-TRIP.** `decode` inverts `encode` on every instruction of Slice
A — the theorem that makes "RV32I" a checkable claim rather than a label, and
kill-check K2b's precondition.

The field lemmas do the extraction; the `repeat rw` then reassembles B-type's
immediate out of its four pieces, each step justified by
`start₂ = start₁ + len₁` (`4 = 0+4`, then `10 = 0+10`, then `11 = 0+11`), ending
at `imm.extractLsb' 0 12`, which is `imm`. -/
theorem decode_encode (i : Instr) : decode (encode i) = some i := by
  cases i <;>
    simp only [encode, decode, wR_f7, wR_rs2, wR_rs1, wR_f3, wR_rd, wR_op,
      wI_imm, wI_rs1, wI_f3, wI_rd, wI_op,
      wB_i11, wB_i94, wB_rs2, wB_rs1, wB_f3, wB_i30, wB_i10, wB_op,
      wS_i115, wS_rs2, wS_rs1, wS_f3, wS_i40, wS_op, wS_imm_reassembles,
      toReg_ofReg] <;>
    (repeat rw [BitVec.extractLsb'_append_extractLsb'_eq_extractLsb' (by omega)]) <;>
    simp

/-- **NON-VACUITY OF THE ROUND-TRIP.** `decode_encode` would be satisfied by an
`encode` that mapped everything to one word and a `decode` that guessed, if the
guess happened to agree — so the certificate that matters is that the words are
the ones the MANUAL specifies. Hand-checked against `rv32.adoc`:
`add x3, x1, x2` is `0x002081B3`. -/
theorem encode_add_matches_manual : encode (.ADD 3 1 2) = 0x002081B3#32 := by
  decide +kernel

/-- `addi x1, x0, 1` is `0x00100093`. -/
theorem encode_addi_matches_manual : encode (.ADDI 1 0 1) = 0x00100093#32 := by
  decide +kernel

/-- `beq x1, x2, +8` is `0x00208463`. The immediate field here is `4`, denoting
`4 * 2 = 8` bytes — the scrambled B-type layout, checked on a real word. -/
theorem encode_beq_matches_manual : encode (.BEQ 1 2 4) = 0x00208463#32 := by
  decide +kernel

/-- **`encode` IS INJECTIVE**, which is what the differential test needs: two
different instructions never present the same word to the third-party
simulator. Immediate from the round-trip. -/
theorem encode_injective {i j : Instr} (h : encode i = encode j) : i = j := by
  have : decode (encode i) = decode (encode j) := by rw [h]
  rw [decode_encode, decode_encode] at this
  exact Option.some.inj this

/-- **`decode` REJECTS what Slice A excludes** — a `LUI` word (opcode `0110111`)
is not silently read as something else. The partiality is real, not decorative. -/
theorem decode_rejects_lui : decode 0x000010B7#32 = none := by
  decide +kernel

/-! ## ⬥ M2 — THE CONTROLS ROSTER, as pre-registered in the memory block §4

Every control below was named in the block BEFORE this commit was written. They
are here rather than in a Scratch because a one-time check is not a standing
gate: a Scratch is deleted by rule and its result becomes an assertion. -/

/-- `lw ra, 0(sp)` is `0x00012083` — hand-derived from the manual's I-type
layout, and one of the two rows this commit deletes from `sliceAExcluded`. -/
theorem encode_lw_matches_manual : encode (.LW 1 2 0) = 0x00012083#32 := by
  decide +kernel

/-- `sw ra, 0(sp)` is `0x00112023` — the S-type word the block triple-sourced,
and the other deleted row. -/
theorem encode_sw_matches_manual : encode (.SW 2 1 0) = 0x00112023#32 := by
  decide +kernel

/-- The two new opcodes collide with none of the three landed accepting ones,
which is what lets them be appended to `decode`'s if-chain without shadowing. -/
theorem new_opcodes_are_fresh :
    (0b0000011#7 ≠ 0b0110011#7) ∧ (0b0000011#7 ≠ 0b0010011#7) ∧
    (0b0000011#7 ≠ 0b1100011#7) ∧ (0b0100011#7 ≠ 0b0110011#7) ∧
    (0b0100011#7 ≠ 0b0010011#7) ∧ (0b0100011#7 ≠ 0b1100011#7) ∧
    (0b0000011#7 ≠ 0b0100011#7) := by
  decide +kernel

/-- The witness state for the arm-inhabitance controls: `x1 = 5`, `mem[1] = 7`,
everything else zero and `trapped = false`. **Distinct values throughout**, so
an observation cannot pass by coincidence. -/
def m2Witness : St :=
  { St.init.set 1 5 with mem := (Vector.replicate 8 0).set 1 7 }

/-! ### Arm inhabitance ×3 — each observing SPECIFIC fields

The block's discipline: a control that observes the whole state proves the arm
was *taken*; one that observes `mem[a]` / `trapped` / a register proves the arm
did **what it says**. -/

/-- **THE `ok` ARM, LOAD.** `LW x2, 4(x0)` reads word 1 and lands `7` in `x2` —
the value came from MEMORY, which no register held. `trapped` stays clear. -/
theorem lw_ok_arm_is_inhabited :
    (step m2Witness (.LW 2 0 4)).get 2 = 7 ∧
      (step m2Witness (.LW 2 0 4)).trapped = false := by
  decide +kernel

/-- **THE `ok` ARM, STORE — and it writes EXACTLY ONE WORD.** `SW x1, 0(x0)`
puts `5` in word 0 and leaves word 1's `7` alone. *Observing the untouched
neighbour is the half that makes this a frame check and not just a write
check.* -/
theorem sw_ok_arm_is_inhabited :
    (step m2Witness (.SW 0 1 0)).mem[0] = 5 ∧
      (step m2Witness (.SW 0 1 0)).mem[1] = 7 ∧
      (step m2Witness (.SW 0 1 0)).trapped = false := by
  decide +kernel

/-- **THE `misaligned` ARM.** Byte address 1. The load is SUPPRESSED — `x2` is
still `0`, not `7` and not garbage — `trapped` is set, and `pc` advances. *The
suppression is the load-bearing term; the flag is the announcement.* -/
theorem lw_misaligned_arm_is_inhabited :
    (step m2Witness (.LW 2 0 1)).trapped = true ∧
      (step m2Witness (.LW 2 0 1)).get 2 = 0 ∧
      (step m2Witness (.LW 2 0 1)).pc = m2Witness.pc + 4 := by
  decide +kernel

/-- **THE `outOfRange` ARM, WITNESSED AT AN *ALIGNED* ADDRESS** — byte 32, word
8, the first word past the eight-word file.

⚠️ **This is r-trap KC1c and it is the reason the witness is 32 and not 33.**
`addrClass` tests range BEFORE alignment, so a misaligned-and-out-of-range
address would classify `outOfRange` too — and the arm would be witnessed by an
address that is bad for TWO reasons, proving nothing about range alone. The
aligned witness isolates the range test. The second conjunct states the
alignment explicitly so the isolation is on the record, not in a comment. -/
theorem sw_out_of_range_arm_is_inhabited :
    addrClass 32#32 = .outOfRange ∧ (32#32 : BitVec 32).toNat % 4 = 0 ∧
      (step m2Witness (.SW 0 1 32)).trapped = true ∧
      (step m2Witness (.SW 0 1 32)).mem[0] = 0 ∧
      (step m2Witness (.SW 0 1 32)).mem[1] = 7 := by
  decide +kernel

/-! ### ⬥ THE ADDRESSING CONTROL — the hole the four arms above do NOT cover

⛔ **FOUND BY THE AUTHOR WHILE PINNING INPUTS FOR THE ADEQUACY REVIEW, after the
four controls above had already landed green.** Every one of them uses `rs1 = x0`
(`.LW 2 0 4` · `.SW 0 1 0` · `.LW 2 0 1` · `.SW 0 1 32`), so `s.get a` is
**identically zero** in all four and the effective address is carried entirely by
the immediate. ⇒ ***TWO MUTANTS PASSED ALL FOUR:*** dropping the base register
(`addr := imm.signExtend 32`) and zero-extending the offset
(`addr := s.get a + imm.zeroExtend 32`).

🔑 ***THE SECOND IS THIS FILE'S OWN NAMED "single most common formalisation bug"
— `ADDI`'s docstring says so and `addi_sign_extends` controls it. LW/SW shipped
a sign-extended offset with no such control.*** *A control set can be exhaustive
over the ARMS and blind on an OPERAND: the four above pin the classifier, the
suppression, the flag and the untouched neighbour, and say nothing whatever
about the base register.* -/

/-- **THE ADDRESSING CONTROL: nonzero base AND negative immediate, so both terms
of `s.get rs1 + sext(imm)` are load-bearing.** `LW x2, -1(x1)` on the witness
(`x1 = 5`, `mem[1] = 7`) has effective address `5 + (-1) = 4` — word 1 — so `x2`
receives `7` from memory. Under the drop-base mutant the address is `sext(-1)`
and under the zero-extend mutant it is `4100`; **both are out of range, both
trap, and both leave `x2 = 0 ≠ 7`.** One witness, two mutants dead. -/
theorem lw_uses_base_register_and_sign_extends :
    (step m2Witness (.LW 2 1 (BitVec.ofInt 12 (-1)))).get 2 = 7 ∧
      (step m2Witness (.LW 2 1 (BitVec.ofInt 12 (-1)))).trapped = false := by
  decide +kernel

/-- The two mutants' addresses, exhibited as arithmetic rather than described —
per the house mutation law, a control is valid only if the mutation is FALSE and
the witness is shown. -/
theorem addressing_mutants_are_out_of_range :
    addrClass ((BitVec.ofInt 12 (-1)).signExtend 32) = .outOfRange ∧
      addrClass (5#32 + (BitVec.ofInt 12 (-1)).zeroExtend 32) = .outOfRange := by
  decide +kernel

/-- …and the honest address is IN range at word 1, so the control above cannot be
passing for want of a trap. *The positive half of a negative control is the half
people forget.* -/
theorem honest_address_is_in_range_at_word_one :
    addrClass (5#32 + (BitVec.ofInt 12 (-1)).signExtend 32) = .ok ∧
      (5#32 + (BitVec.ofInt 12 (-1)).signExtend 32).toNat / 4 = 1 := by
  decide +kernel

/-! ### The swapped-immediate mutant — a control is valid only if it FALSIFIES -/

/-- **THE MUTANT**: S-type with its two immediate pieces exchanged. It must
COMPILE (a non-compiling mutant is not a control) and it must BREAK the
round-trip on an exhibited witness. -/
def wS_mutant (i115 : BitVec 7) (i40 : BitVec 5) (a b : Fin 32) : BitVec 32 :=
  (i40 ++ (0#2)) ++ (ofReg b ++ (ofReg a ++ (0b010#3 ++
    ((i115.extractLsb' 0 5) ++ 0b0100011#7))))

/-- ⛔ **THE MUTANT IS KILLED, ON A WITNESS.** At `imm = 1` the swapped encoder
produces a word that decodes to `SW x2, x1, 128` — not `1`. So `decode_encode`
genuinely pins the field ORDER; it is not satisfied by any self-consistent pair
of encoder and decoder. *Per the house mutation law: a mutant that merely fails
to prove is not a control — this one makes the statement FALSE, and the value it
decodes to is exhibited rather than described.* -/
theorem wS_mutant_breaks_the_round_trip :
    decode (wS_mutant ((1 : BitVec 12).extractLsb' 5 7)
      ((1 : BitVec 12).extractLsb' 0 5) 2 1) = some (.SW 2 1 128) ∧
    (128 : BitVec 12) ≠ 1 := by
  decide +kernel

/-- **The brief's own signature**, `step : St → BitVec 32 → St`, recovered as a
derived definition: decode the word, then step. `Option` because Slice A's
exclusions are real — a word this subset does not define has no transition. -/
def stepW (s : St) (w : BitVec 32) : Option St := (decode w).map (step s)

/-! ## `stepT` — THE TOTAL STEP-ON-WORDS (campaign freeze v1.1, option 1)

Ruled 8/7 11:21 (**DRAFT — Captain ratification pending**, since it defines what
the chip MEANS on garbage words). C4 needs a step the hardware can implement:
**a netlist observation is `List Bool` and TOTAL, while `stepW` is `Option St`
and PARTIAL**, and no encoding reconciles them — there is no `List Bool` that
means *"this word did not decode"*.

**v1 SEMANTICS, stated as a sentence because it is a specification choice and
not a proof detail: an undecodable word is a DEFINED NOP-ADVANCE — the register
file is unchanged and `pc` advances by 4.**

🔴 **THE FENCE, at the evidence seat's strength (11:26) and placed HERE because a
reader meets the code before they meet the freeze:**

> **On the 99.61% of 32-bit words outside the seven-instruction subset, this chip
> advances `PC+4`. That is a deliberate v1 semantics, NOT RV32I behaviour —
> RV32I raises an illegal-instruction trap. An equivalence theorem covering the
> whole word space certifies, on those words, agreement with OUR CHOSEN
> SEMANTICS — not conformance to the ISA.**

⚠️ ***TOTAL IS NOT CONFORMANT.*** *"The theorem covers every 32-bit word" is a
true statement about COVERAGE and reads as one about CONFORMANCE.* The datapath
brief's existing fence — *"never say core, say RV32I subset"* — bounds **which
instructions are implemented**; this one bounds **what happens when you feed it
anything else**, and the first does not imply the second.

```
decodable   16,875,520 words  =  0.3929 %   (ADD/XOR/SLT 2^15 each; ADDI/BEQ/LW/SW 2^22)
undecodable  4,278,091,776    = 99.6071 %   <- PC+4 by OUR choice, not by RV32I
```

*Superseded when trap machinery arrives; until then this is what the silicon
does and the claim must say so.*

⛔ **CORRECTED 2026-08-15 06:5x (compiler).** *This fence read FIVE instructions /
0.1976% / 99.80% — the pre-M2 figures — while `decode` (this file, 797-824) has
accepted SEVEN since LW and SW landed, both arms commented `⬥ M2` above. Understated
the decodable space by a factor of 1.988. Figures recomputed from the decoder's arms,
not transcribed.

⛔ **AND THE SENTENCE THAT STOOD HERE WAS ITSELF UNMEASURED — struck 12:2x.** *It read
"The 10 downstream sites quoting `0.1976` are NOT yet corrected." **I never counted the
10, and "not yet corrected" was false by then.** Walked repo-wide over `git ls-files`
at 12:2x — not over any inherited list:*

⛔⛔ **AND THE WALK I PUT HERE AT 12:2x WAS ITSELF WRONG — RETRACTED 12:3x, refuted by the
math seat.** *It reported "21 occurrences · 7 files · 3 stale-only" and accused the 08/07
citation list of naming files that never carried the figure.* ***Both wrong, and from one
cause: THE FENCE HAS TWO DOWNSTREAM FORMS AND I SEARCHED ONE.***
```
I searched ....... 0.1976 · 8,486,912 · 99.8024
they say ......... "99.80% of the word space is undecodable"
  RegWrite.lean:36,116          carry it
  riscv-core-campaign-v0.md:96,100  carry it — AT THE LINES I CALLED INVENTED
⇒ `git log -S "0.1976"` returning nothing was TRUE AND IRRELEVANT.
  "No commit added that string" is not "this file never carried the claim".
```
⚠️ ***THE 08/07 LEDGER LIST WAS CORRECT AND MY ACCUSATION AGAINST IT IS WITHDRAWN IN FULL.***

✅ **RE-MEASURED — numeric forms only, `git ls-files`, hand-checked for false positives**
*(`five instruction` dropped: it matches a comparator's size in `SortDemo.lean`, and the
CORRECT "five-instruction Slice A subset" — Slice A **is** five; `decode` accepts seven):*
```
STALE-ONLY (7)  PcNext.lean · RegWrite.lean · Stack/Program.lean
                docs/EVIDENCE-campaign.md · docs/LEDGER.md
                docs/hdl-c4-composition-check-0807.md · docs/riscv-core-campaign-v0.md
corrected (4)   ISA.lean · QUEUE.md · memory-design-v1.md · s0-r2-memory-census-0807.md
11 files · 37 occurrences · SEVEN stale-only
```
📌 ***THE LESSON, and it is not the one I published: I BUILT A POPULATION WALK TO ESCAPE AN
INHERITED LIST, THEN RAN THE WALK WITH A PATTERN THAT COULD NOT SEE THE THING.*** *A walk
with the wrong pattern is an inherited list with better manners.* **And the wrong story was
the dramatic and self-flattering one — everyone else the defect, me the auditor. That is the
finding that needed the most testing and got the least.**

⚠️ **Why not the alternatives, per the pricing in
`docs/hdl-c4-composition-check-0807.md`:** a hypothesis restricting inputs to
decodable words would silence C4 on a **measured 99.61%** of the word space
(`decode` accepts `3·2^15 + 4·2^22 = 16,875,520` of `2^32`); putting the decoder
inside the boundary needs a validity bit and pays gates on **every** instruction.
-/

/-- **The total step.** Decodable words behave exactly as `step`; everything else
advances the `pc` and touches nothing.

📌 **Defined AS `stepW` with a default, deliberately.** Writing it as an
independent `match` would make the compatibility obligation a theorem that could
be *wrong*; written this way the agreement is **definitional**, and
`stepT_compat` below is the one-line consequence rather than the load-bearing
proof. *The obligation is no less real — it is discharged by construction, which
is the strongest way to discharge it.* -/
def stepT (s : St) (w : BitVec 32) : St := (stepW s w).getD s.next

/-- **THE COMPATIBILITY OBLIGATION, as the named theorem the ruling requires.**
Wherever `stepW` is defined, `stepT` agrees with it. *Without this, a total
`stepT` could disagree with `stepW` on a **decodable** word — which would make
C4 true and the ISA claim false. It is the whole price of option 1 and it is one
line.* -/
theorem stepT_compat (s : St) (w : BitVec 32) (s' : St) (h : stepW s w = some s') :
    stepT s w = s' := by
  simp [stepT, h]

/-- **The v1 semantics, executable.** An undecodable word is a NOP-advance. -/
theorem stepT_undecodable (s : St) (w : BitVec 32) (h : decode w = none) :
    stepT s w = s.next := by
  simp [stepT, stepW, h]

/-- **And `stepT` still runs the ISA on everything the encoder produces**, so
option 1 did not quietly widen or narrow Slice A. -/
theorem stepT_encode (s : St) (i : Instr) : stepT s (encode i) = step s i := by
  simp [stepT, stepW, decode_encode]

/-- **NON-VACUITY — the NOP branch is REACHABLE, on a word this file already
proves is rejected.** `LUI` is legal RV32I that Slice A excludes, so this is
also the exact case where `stepT` and a RISC-V simulator part company, by
design. -/
theorem stepT_nop_is_reachable (s : St) :
    stepT s 0x000010B7#32 = s.next := stepT_undecodable s _ decode_rejects_lui

/-- And the two are genuinely different functions — `stepW` has no value here. -/
theorem stepW_none_where_stepT_advances (s : St) :
    stepW s 0x000010B7#32 = none := by
  simp [stepW, decode_rejects_lui]

/-- **The two `step`s agree**, which is the whole content of having both: the
code generator may reason over `Instr` while the differential test runs over
encoded words, and this theorem is the bridge. -/
theorem stepW_encode (s : St) (i : Instr) : stepW s (encode i) = some (step s i) := by
  simp [stepW, decode_encode]

/-! ## Axiom audit — every definition and every theorem, per the iron rules -/

-- ⬥ M1: the two new declarations join the standing roll-call. They were
-- audited with `#print axioms` at the landing, but that ran in a Scratch that
-- is deleted by rule — a one-time audit is not a STANDING gate, and a
-- declaration with no audit line is SILENT rather than failing.
#audit_axioms addrClass
#audit_axioms addrClass_ok_lt
#audit_axioms St.get
#audit_axioms St.set
#audit_axioms St.next
#audit_axioms bOffset
#audit_axioms step
#audit_axioms fetch
#audit_axioms runFor
#audit_axioms run
#audit_axioms St.init
#audit_axioms St.get_zero
#audit_axioms St.set_zero
#audit_axioms St.get_set_self
#audit_axioms St.get_set_ne
#audit_axioms St.get_set_zero
#audit_axioms addi_sign_extends
#audit_axioms slt_is_signed
#audit_axioms slt_is_signed'
#audit_axioms xor_is_exclusive
#audit_axioms xor_self_is_zero
#audit_axioms beq_x0_x0_taken
#audit_axioms beq_not_taken
#audit_axioms x0_write_is_a_silent_noop
#audit_axioms beq_offset_is_bytes_from_own_address
#audit_axioms beq_offset_can_be_negative
#audit_axioms run_executes
#audit_axioms run_halts_off_the_end
#audit_axioms run_forward_branch_skips
#audit_axioms ofReg
#audit_axioms toReg
#audit_axioms toReg_ofReg
#audit_axioms wR
#audit_axioms wI
#audit_axioms wB
#audit_axioms wR_f7
#audit_axioms wR_rs2
#audit_axioms wR_rs1
#audit_axioms wR_f3
#audit_axioms wR_rd
#audit_axioms wR_op
#audit_axioms wI_imm
#audit_axioms wI_rs1
#audit_axioms wI_f3
#audit_axioms wI_rd
#audit_axioms wI_op
#audit_axioms wB_i11
#audit_axioms wB_i94
#audit_axioms wB_rs2
#audit_axioms wB_rs1
#audit_axioms wB_f3
#audit_axioms wB_i30
#audit_axioms wB_i10
#audit_axioms wB_op
#audit_axioms encode
#audit_axioms decode
#audit_axioms decode_encode
#audit_axioms encode_add_matches_manual
#audit_axioms encode_addi_matches_manual
#audit_axioms encode_beq_matches_manual
#audit_axioms encode_injective
#audit_axioms decode_rejects_lui
#audit_axioms stepW
#audit_axioms stepW_encode
#audit_axioms stepT
#audit_axioms stepT_compat
#audit_axioms stepT_undecodable
#audit_axioms stepT_encode
#audit_axioms stepT_nop_is_reachable
#audit_axioms stepW_none_where_stepT_advances

-- ⬥ M2: every declaration this commit adds enters the standing roll-call in the
-- SAME commit, per the block §4 ruling (⬥v1.5). An absent audit line is SILENT:
-- a green build is exactly as green without it.
#audit_axioms touchesMem
#audit_axioms wS
#audit_axioms wS_i115
#audit_axioms wS_rs2
#audit_axioms wS_rs1
#audit_axioms wS_f3
#audit_axioms wS_i40
#audit_axioms wS_op
#audit_axioms wS_imm_reassembles
#audit_axioms encode_lw_matches_manual
#audit_axioms encode_sw_matches_manual
#audit_axioms new_opcodes_are_fresh
#audit_axioms m2Witness
#audit_axioms lw_ok_arm_is_inhabited
#audit_axioms sw_ok_arm_is_inhabited
#audit_axioms lw_misaligned_arm_is_inhabited
#audit_axioms sw_out_of_range_arm_is_inhabited
#audit_axioms wS_mutant
#audit_axioms wS_mutant_breaks_the_round_trip
#audit_axioms lw_uses_base_register_and_sign_extends
#audit_axioms addressing_mutants_are_out_of_range
#audit_axioms honest_address_is_in_range_at_word_one

end SaltWorks.ISA
