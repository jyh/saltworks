/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Silicon.Refine.Statement

/-!
# AAU W1 — the fabricated `core32` + `busadapt8`, as a Lean pin machine

`plane32bus` at `jyh/tt-neural-dataflow-fabric@01e19f7` is transcribed signal by signal into `Ex`, a
small width-typed expression language. It is NOT an ISA model written from the spec. Every
definition below names the RTL wire it transcribes, and keeps the RTL's structure, bugs included.

The link to the fabricated RTL is not this file's prose. `Emit.moduleComb` prints the same
expressions as a combinational Verilog module (every flop's current value an input, its next value
an output). `SaltWorks/Silicon/Formal/refine_link/run_link.sh` cuts the gold's flops open, ties every
alias of each flop to one state input, and has ABC prove the transition and output functions EQUAL
to those of the fabricated `core32.v` + `busadapt8.v` + `plane32bus.v`. The proof covers every value
of state, inputs and the gold's `x` bits. A mutant control follows, and a freed-bit accounting that
must close.

**Trusted, and small:** that `Ex.eval` and the printer give each constructor the same meaning (one
line per constructor, side by side in `Emit.lean`), the yosys SAT run, and the Lean kernel.

⚠️ **One transcription choice the SAT link exists to check:** `core32.v`'s ALU chain writes
`$signed(rf1) >>> b_op[4:0]` inside an UNSIGNED conditional, so Verilog evaluates it as a LOGICAL
shift. That is erratum E's SRA/SRAI cause. It is transcribed here as `lshr`. Were it transcribed
as `ashr`, the equivalence run would fail; the mutant control (`moduleComb true`) shows it does.
-/

namespace SaltWorks.Silicon.Refine.Model
open SaltWorks.Silicon.Refine

/-! ## The expression language -/

/-- Named state and input signals, with their widths. -/
inductive Sig : Nat → Type where
  | pc : Sig 32 | phase : Sig 2 | kind : Sig 2 | storeBeat : Sig 1 | fetchOwed : Sig 1
  | inAcc : Sig 32 | instrR : Sig 32 | rdataR : Sig 32
  | rstn : Sig 1 | sof : Sig 1 | pin : Sig 8

/-- Width-typed combinational expressions. -/
inductive Ex : Nat → Type where
  | lit  {w} (v : BitVec w) : Ex w
  | sig  {w} (s : Sig w) : Ex w
  | rf   (i : Ex 5) : Ex 32                       -- `u_core.regs[i]`; index 0 is never selected unguarded
  | add  {w} (a b : Ex w) : Ex w
  | sub  {w} (a b : Ex w) : Ex w
  | band {w} (a b : Ex w) : Ex w
  | bor  {w} (a b : Ex w) : Ex w
  | bxor {w} (a b : Ex w) : Ex w
  | bnot {w} (a : Ex w) : Ex w
  | shl  {w} (a : Ex w) (b : Ex 5) : Ex w
  | lshr {w} (a : Ex w) (b : Ex 5) : Ex w
  | ashr {w} (a : Ex w) (b : Ex 5) : Ex w
  | eq   {w} (a b : Ex w) : Ex 1
  | ult  {w} (a b : Ex w) : Ex 1
  | slt  {w} (a b : Ex w) : Ex 1
  | mux  {w} (c : Ex 1) (a b : Ex w) : Ex w       -- `c ? a : b`
  | ext  {w} (a : Ex w) (lo len : Nat) : Ex len   -- `a[lo+len-1:lo]`
  | cat  {m n} (a : Ex m) (b : Ex n) : Ex (m + n) -- `{a, b}`
  | zext {m} (a : Ex m) (w : Nat) : Ex w
  | sext {m} (a : Ex m) (w : Nat) : Ex w

/-- The state of `plane32bus`: every flop, by its RTL name. `regs 0` is unused (the RTL declares
`regs [1:31]`). -/
structure St where
  pc        : BitVec 32       -- u_core.pc_r
  regs      : BitVec 5 → BitVec 32   -- u_core.regs[1..31]
  phase     : BitVec 2        -- u_bus.phase
  kind      : BitVec 2        -- u_bus.kind
  storeBeat : BitVec 1        -- u_bus.store_beat
  fetchOwed : BitVec 1        -- u_bus.fetch_owed
  inAcc     : BitVec 32       -- u_bus.in_acc
  instrR    : BitVec 32       -- u_bus.instr_r
  rdataR    : BitVec 32       -- u_bus.rdata_r

/-- The inputs of one cycle: `rst_n`, `sof`, `instr_byte` (= `ui_in`). -/
structure In where
  rstn : BitVec 1
  sof  : BitVec 1
  pin  : BitVec 8

def Sig.eval (σ : St) (x : In) : Sig w → BitVec w
  | .pc => σ.pc | .phase => σ.phase | .kind => σ.kind | .storeBeat => σ.storeBeat
  | .fetchOwed => σ.fetchOwed | .inAcc => σ.inAcc | .instrR => σ.instrR | .rdataR => σ.rdataR
  | .rstn => x.rstn | .sof => x.sof | .pin => x.pin

def Ex.eval (σ : St) (x : In) : Ex w → BitVec w
  | .lit v    => v
  | .sig s    => s.eval σ x
  | .rf i     => σ.regs (i.eval σ x)
  | .add a b  => a.eval σ x + b.eval σ x
  | .sub a b  => a.eval σ x - b.eval σ x
  | .band a b => a.eval σ x &&& b.eval σ x
  | .bor a b  => a.eval σ x ||| b.eval σ x
  | .bxor a b => a.eval σ x ^^^ b.eval σ x
  | .bnot a   => ~~~ a.eval σ x
  | .shl a b  => a.eval σ x <<< (b.eval σ x).toNat
  | .lshr a b => a.eval σ x >>> (b.eval σ x).toNat
  | .ashr a b => (a.eval σ x).sshiftRight (b.eval σ x).toNat
  | .eq a b   => if a.eval σ x = b.eval σ x then 1 else 0
  | .ult a b  => if (a.eval σ x).ult (b.eval σ x) then 1 else 0
  | .slt a b  => if (a.eval σ x).slt (b.eval σ x) then 1 else 0
  | .mux c a b => if c.eval σ x = 1 then a.eval σ x else b.eval σ x
  | .ext a lo len => (a.eval σ x).extractLsb' lo len
  | .cat a b  => a.eval σ x ++ b.eval σ x
  | .zext a w => (a.eval σ x).setWidth w
  | .sext a w => (a.eval σ x).signExtend w

/-! ## Notation helpers (each is one constructor; nothing here is semantic) -/

def k {w} (n : Nat) : Ex w := .lit (BitVec.ofNat w n)
def and1 (a b : Ex 1) : Ex 1 := .band a b
def or1  (a b : Ex 1) : Ex 1 := .bor a b
def not1 (a : Ex 1) : Ex 1 := .bnot a
def eqk {w} (a : Ex w) (n : Nat) : Ex 1 := .eq a (k n)
def anyOf : List (Ex 1) → Ex 1
  | [] => k 0
  | [a] => a
  | a :: as => or1 a (anyOf as)

/-! ## busadapt8 — the combinational half that `core32` reads -/

def T_FETCH := 1
def T_LOAD := 2
def T_STORE := 3

def phase : Ex 2 := .sig .phase
def kind : Ex 2 := .sig .kind
def storeBeat : Ex 1 := .sig .storeBeat
def pin : Ex 8 := .sig .pin
def inAcc : Ex 32 := .sig .inAcc

/-- `c_instr = (kind == T_FETCH && phase == 3) ? {pin_in, in_acc[23:0]} : instr_r` -/
def c_instr : Ex 32 :=
  .mux (and1 (eqk kind T_FETCH) (eqk phase 3)) (.zext (.cat pin (.ext inAcc 0 24)) 32) (.sig .instrR)

/-! ## core32 -/

def instr := c_instr
def opcode : Ex 7 := .ext instr 0 7
def funct3 : Ex 3 := .ext instr 12 3
def f7 : Ex 1 := .ext instr 30 1
def rs1 : Ex 5 := .ext instr 15 5
def rs2 : Ex 5 := .ext instr 20 5
def rd  : Ex 5 := .ext instr 7 5

def is_lui   := eqk opcode 0b0110111
def is_auipc := eqk opcode 0b0010111
def is_jal   := eqk opcode 0b1101111
def is_jalr  := eqk opcode 0b1100111
def is_br    := eqk opcode 0b1100011
def is_load  := eqk opcode 0b0000011
def is_store := eqk opcode 0b0100011
def is_immop := eqk opcode 0b0010011
def is_regop := eqk opcode 0b0110011

def is_word    := eqk funct3 2
def is_load_w  := and1 is_load is_word
def is_store_w := and1 is_store is_word

def reg_we := anyOf [is_lui, is_auipc, is_jal, is_jalr, is_load_w, is_immop, is_regop]
def alu_src := anyOf [is_immop, is_load, is_store, is_jalr]
/-- `alu_op = is_regop ? {f7,funct3} : is_immop ? {1'b0,funct3} : 4'd0` -/
def alu_op : Ex 4 :=
  .mux is_regop (.zext (.cat f7 funct3) 4) (.mux is_immop (.zext funct3 4) (k 0))

def imm_i : Ex 32 := .sext (.ext instr 20 12) 32
def imm_s : Ex 32 := .sext (.cat (.ext instr 25 7) (.ext instr 7 5)) 32
def imm_b : Ex 32 :=
  .sext (.cat (.cat (.cat (.cat (.ext instr 31 1) (.ext instr 7 1)) (.ext instr 25 6))
    (.ext instr 8 4)) (k (w := 1) 0)) 32
def imm_u : Ex 32 := .zext (.cat (.ext instr 12 20) (k (w := 12) 0)) 32
def imm_j : Ex 32 :=
  .sext (.cat (.cat (.cat (.cat (.ext instr 31 1) (.ext instr 12 8)) (.ext instr 20 1))
    (.ext instr 21 10)) (k (w := 1) 0)) 32
def imm : Ex 32 :=
  .mux is_store imm_s (.mux is_br imm_b (.mux (or1 is_lui is_auipc) imm_u (.mux is_jal imm_j imm_i)))

def rf1 : Ex 32 := .mux (eqk rs1 0) (k 0) (.rf rs1)
def rf2 : Ex 32 := .mux (eqk rs2 0) (k 0) (.rf rs2)

def b_op : Ex 32 := .mux alu_src imm rf2
def sh : Ex 5 := .ext b_op 0 5

/-- The ALU chain, in the RTL's order. `4'hd` is `lshr` — see the header. -/
def alu_y : Ex 32 :=
  .mux (eqk alu_op 0x0) (.add rf1 b_op) <|
  .mux (eqk alu_op 0x8) (.sub rf1 b_op) <|
  .mux (eqk alu_op 0x1) (.shl rf1 sh) <|
  .mux (eqk alu_op 0x2) (.zext (.slt rf1 b_op) 32) <|
  .mux (eqk alu_op 0x3) (.zext (.ult rf1 b_op) 32) <|
  .mux (eqk alu_op 0x4) (.bxor rf1 b_op) <|
  .mux (eqk alu_op 0x5) (.lshr rf1 sh) <|
  .mux (eqk alu_op 0xd) (.lshr rf1 sh) <|
  .mux (eqk alu_op 0x6) (.bor rf1 b_op) (.band rf1 b_op)

def br_taken : Ex 1 :=
  and1 is_br <|
  .mux (eqk funct3 0) (.eq rf1 rf2) <|
  .mux (eqk funct3 1) (not1 (.eq rf1 rf2)) <|
  .mux (eqk funct3 4) (.slt rf1 rf2) <|
  .mux (eqk funct3 5) (not1 (.slt rf1 rf2)) <|
  .mux (eqk funct3 6) (.ult rf1 rf2) (not1 (.ult rf1 rf2))

def pc_q : Ex 32 := .sig .pc
def pc_plus_4 : Ex 32 := .add pc_q (k 4)
def pc_plus_imm : Ex 32 := .add pc_q imm
def pc_next : Ex 32 :=
  .mux is_jalr (.band (.add rf1 imm) (k 0xFFFFFFFE)) (.mux (or1 is_jal br_taken) pc_plus_imm pc_plus_4)
def imem_addr : Ex 32 := .zext (.cat (.ext pc_q 2 30) (k (w := 2) 0)) 32

def dmem_addr : Ex 32 := alu_y
def dmem_wdata : Ex 32 := rf2
def dmem_req : Ex 1 := or1 is_load_w is_store_w
def dmem_we : Ex 1 := is_store_w
def ld_out : Ex 32 := .sig .rdataR

def wb_val : Ex 32 :=
  .mux is_load_w ld_out (.mux (or1 is_jal is_jalr) pc_plus_4 (.mux is_lui imm (.mux is_auipc pc_plus_imm alu_y)))

/-! ## busadapt8 — the rest -/

def loop_end : Ex 1 := eqk phase 3
/-- `retire = loop_end && (FETCH ? ~req : LOAD ? 1 : STORE ? store_beat : 1)` -/
def retire : Ex 1 :=
  and1 loop_end <|
  .mux (eqk kind T_FETCH) (not1 dmem_req) <|
  .mux (eqk kind T_LOAD) (k 1) <|
  .mux (eqk kind T_STORE) storeBeat (k 1)

def instr_avail : Ex 1 := and1 (eqk kind T_FETCH) (eqk phase 3)
def mem_retire_now : Ex 1 :=
  and1 (and1 loop_end retire) (or1 (eqk kind T_STORE) (eqk kind T_LOAD))
def stale_decode : Ex 1 := and1 (or1 (.sig .fetchOwed) mem_retire_now) (not1 instr_avail)

def phase_pins : Ex 2 := .mux (eqk phase 0) kind phase
def out_word : Ex 32 :=
  .mux (eqk kind T_FETCH) imem_addr (.mux (and1 (eqk kind T_STORE) storeBeat) dmem_wdata dmem_addr)
def pin_out : Ex 8 :=
  .mux (eqk phase 0) (.ext out_word 0 8) <|
  .mux (eqk phase 1) (.ext out_word 8 8) <|
  .mux (eqk phase 2) (.ext out_word 16 8) (.ext out_word 24 8)

/-! ## Next state, flop by flop (`rstn` low is the synchronous reset) -/

def rstn : Ex 1 := .sig .rstn
def sof : Ex 1 := .sig .sof
def lowRst : Ex 1 := not1 rstn

def n_pc : Ex 32 := .mux lowRst (k 0) (.mux retire pc_next pc_q)
def n_phase : Ex 2 := .mux lowRst (k 0) (.mux sof (k 0) (.add phase (k 1)))
def n_fetchOwed : Ex 1 :=
  .mux lowRst (k 0) (.mux instr_avail (k 0) (.mux mem_retire_now (k 1) (.sig .fetchOwed)))
def n_kind : Ex 2 :=
  .mux lowRst (k T_FETCH) <|
  .mux sof (.mux (and1 (not1 stale_decode) dmem_req) (.mux dmem_we (k T_STORE) (k T_LOAD)) (k T_FETCH)) <|
  .mux loop_end (.mux retire (k T_FETCH) (.mux (eqk kind T_FETCH) (.mux dmem_we (k T_STORE) (k T_LOAD)) kind))
  kind
def n_storeBeat : Ex 1 :=
  .mux lowRst (k 0) <|
  .mux sof (k 0) <|
  .mux loop_end (.mux retire (k 0) (.mux (eqk kind T_FETCH) (k 0) (k 1))) storeBeat
def acc32 : Ex 32 := .zext (.cat pin (.ext inAcc 0 24)) 32
def n_inAcc : Ex 32 :=
  .mux lowRst (k 0) <|
  .mux (eqk phase 0) (.zext (.cat (.ext inAcc 8 24) pin) 32) <|
  .mux (eqk phase 1) (.zext (.cat (.cat (.ext inAcc 16 16) pin) (.ext inAcc 0 8)) 32) <|
  .mux (eqk phase 2) (.zext (.cat (.cat (.ext inAcc 24 8) pin) (.ext inAcc 0 16)) 32) inAcc
def n_instrR : Ex 32 :=
  .mux lowRst (k 0) (.mux (and1 (eqk phase 3) (eqk kind T_FETCH)) acc32 (.sig .instrR))
def n_rdataR : Ex 32 :=
  .mux lowRst (k 0) (.mux (and1 (eqk phase 3) (eqk kind T_LOAD)) acc32 (.sig .rdataR))
/-- Register-file write port: `en && reg_we && rd != 0` (NOT gated by `rst_n`, as in the RTL). -/
def rf_we : Ex 1 := and1 (and1 retire reg_we) (not1 (eqk rd 0))

/-- One clock edge of `plane32bus`. -/
def step (σ : St) (x : In) : St where
  pc        := n_pc.eval σ x
  regs      := fun j => if rf_we.eval σ x = 1 ∧ j = rd.eval σ x then wb_val.eval σ x else σ.regs j
  phase     := n_phase.eval σ x
  kind      := n_kind.eval σ x
  storeBeat := n_storeBeat.eval σ x
  fetchOwed := n_fetchOwed.eval σ x
  inAcc     := n_inAcc.eval σ x
  instrR    := n_instrR.eval σ x
  rdataR    := n_rdataR.eval σ x

/-- The pin machine the statement quantifies over: `rst_n` high and `sof` low in every cycle after
the reset edge. `reset r0` is the state that edge produces (every flop but the register file is
reset). -/
def core32bus : PinMachine where
  St    := St
  reset := fun r0 => ⟨0, r0, 0, 1, 0, 0, 0, 0, 0⟩
  step  := fun σ b => step σ ⟨1, 0, b⟩
  out   := fun σ b => (pin_out.eval σ ⟨1, 0, b⟩, phase_pins.eval σ ⟨1, 0, b⟩)
  arch  := fun σ => ⟨σ.pc, σ.regs⟩

end SaltWorks.Silicon.Refine.Model
