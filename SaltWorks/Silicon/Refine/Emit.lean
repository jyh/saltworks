/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Silicon.Refine.Model

/-!
# AAU W1 — print the Lean model as flat Verilog, for the SAT link

Each `Ex` node becomes its own sized wire, so no Verilog expression ever mixes widths or
signedness. That context rule is the one that produced erratum E's SRA. The table below is the
whole trusted correspondence. Each row pairs `Ex.eval`'s meaning (`Model.lean`) with the Verilog
printed for it, where `a`, `b` and `c` are wires of the node's declared widths:

| node | `Ex.eval` | Verilog |
|---|---|---|
| `lit v` | `v` | `W'hHEX` |
| `add/sub/band/bor/bxor` | `+ - &&& \|\|\| ^^^` (mod 2^w) | `a + b` … into a `w`-bit wire |
| `bnot` | `~~~a` | `~a` |
| `shl/lshr` | `a <<< b.toNat` / `a >>> b.toNat` | `a << b` / `a >> b` (b is 5-bit unsigned) |
| `ashr` | `a.sshiftRight b.toNat` | `$signed(a) >>> b`, alone in its assignment |
| `eq/ult/slt` | `1` iff `=` / `ult` / `slt` | `a == b` / `a < b` / `$signed(a) < $signed(b)` |
| `mux c a b` | `if c = 1 then a else b` | `c ? a : b` |
| `ext a lo len` | `extractLsb' lo len` | `a[lo+len-1:lo]` (printer refuses lo+len > width) |
| `cat a b` | `a ++ b` | `{a, b}` |
| `zext a w` / `sext a w` | `setWidth` / `signExtend` | `{0s, a}` / `{{k{a[m-1]}}, a}`, or `a[w-1:0]` when `w ≤ m` |
| `rf i` | `regs i` | a 31-way select over `u_core.regs[1..31]`; `i = 0` selects 0 |

`rf 0` is the one row where the two sides differ: `regs 0` is a Lean value, the Verilog gives 0. It
is safe because every `rf` in `Model.lean` sits under `mux (rs = 0) 0 (rf rs)`. The SAT run checks
the whole design, so a misuse would show up there as a mismatch.
-/

namespace SaltWorks.Silicon.Refine.Emit
open SaltWorks.Silicon.Refine.Model

/-- Escaped Verilog identifier (trailing space is part of the syntax). -/
def esc (s : String) : String := "\\" ++ s ++ " "

def _root_.SaltWorks.Silicon.Refine.Model.Sig.vname : Sig w → String
  | .pc => esc "u_core.pc_r" | .phase => esc "u_bus.phase" | .kind => esc "u_bus.kind"
  | .storeBeat => esc "u_bus.store_beat" | .fetchOwed => esc "u_bus.fetch_owed"
  | .inAcc => esc "u_bus.in_acc" | .instrR => esc "u_bus.instr_r" | .rdataR => esc "u_bus.rdata_r"
  | .rstn => "rst_n" | .sof => "sof" | .pin => "instr_byte"

def regName (j : Nat) : String := esc s!"u_core.regs[{j}]"

def hex (w n : Nat) : String :=
  let digits := Nat.toDigits 16 n
  s!"{w}'h" ++ String.ofList digits

structure PS where
  n : Nat := 0
  lines : Array String := #[]

abbrev P := StateM PS

def fresh (w : Nat) (rhs : String) : P String := do
  let s ← get
  let nm := s!"n{s.n}"
  set { s with n := s.n + 1, lines := s.lines.push s!"  wire [{w - 1}:0] {nm} = {rhs};" }
  pure nm

/-- Print one node; returns the wire (or signal) name carrying it. -/
def _root_.SaltWorks.Silicon.Refine.Model.Ex.pr : {w : Nat} → Ex w → P String
  | w, .lit v => fresh w (hex w v.toNat)
  | _, .sig s => pure s.vname
  | _, .rf i => do
      let a ← i.pr
      let sel := (List.range 31).foldr (fun j acc => s!"({a} == 5'd{j + 1}) ? {regName (j + 1)} : " ++ acc) "32'h0"
      fresh 32 sel
  | w, .add a b => do let x ← a.pr; let y ← b.pr; fresh w s!"{x} + {y}"
  | w, .sub a b => do let x ← a.pr; let y ← b.pr; fresh w s!"{x} - {y}"
  | w, .band a b => do let x ← a.pr; let y ← b.pr; fresh w s!"{x} & {y}"
  | w, .bor a b => do let x ← a.pr; let y ← b.pr; fresh w s!"{x} | {y}"
  | w, .bxor a b => do let x ← a.pr; let y ← b.pr; fresh w s!"{x} ^ {y}"
  | w, .bnot a => do let x ← a.pr; fresh w s!"~{x}"
  | w, .shl a b => do let x ← a.pr; let y ← b.pr; fresh w s!"{x} << {y}"
  | w, .lshr a b => do let x ← a.pr; let y ← b.pr; fresh w s!"{x} >> {y}"
  | w, .ashr a b => do let x ← a.pr; let y ← b.pr; fresh w s!"$signed({x}) >>> {y}"
  | _, .eq a b => do let x ← a.pr; let y ← b.pr; fresh 1 s!"{x} == {y}"
  | _, .ult a b => do let x ← a.pr; let y ← b.pr; fresh 1 s!"{x} < {y}"
  | _, .slt a b => do let x ← a.pr; let y ← b.pr; fresh 1 s!"$signed({x}) < $signed({y})"
  | w, .mux c a b => do let z ← c.pr; let x ← a.pr; let y ← b.pr; fresh w s!"{z} ? {x} : {y}"
  | _, @Ex.ext w a lo len => do
      if lo + len > w then panic! s!"ext out of range: [{lo}+{len}] of {w}"
      let x ← a.pr; fresh len s!"{x}[{lo + len - 1}:{lo}]"
  | _, @Ex.cat m n a b => do let x ← a.pr; let y ← b.pr; fresh (m + n) s!"\{{x}, {y}}"
  | _, @Ex.zext m a w => do
      let x ← a.pr
      if w ≤ m then fresh w s!"{x}[{w - 1}:0]" else fresh w s!"\{{w - m}'b0, {x}}"
  | _, @Ex.sext m a w => do
      let x ← a.pr
      if w ≤ m then fresh w s!"{x}[{w - 1}:0]" else fresh w s!"\{\{{w - m}\{{x}[{m - 1}]}}, {x}}"

/-- `alu_ashr` swaps `4'hd`'s `lshr` for `ashr`: the MUTANT CONTROL for the SAT link. -/
def module (alu_ashr : Bool := false) : String := Id.run do
  let alu := if alu_ashr then
      -- the same chain with the one transcription the header names flipped
      Ex.mux (eqk alu_op 0x0) (.add rf1 b_op) <|
      .mux (eqk alu_op 0x8) (.sub rf1 b_op) <|
      .mux (eqk alu_op 0x1) (.shl rf1 sh) <|
      .mux (eqk alu_op 0x2) (.zext (.slt rf1 b_op) 32) <|
      .mux (eqk alu_op 0x3) (.zext (.ult rf1 b_op) 32) <|
      .mux (eqk alu_op 0x4) (.bxor rf1 b_op) <|
      .mux (eqk alu_op 0x5) (.lshr rf1 sh) <|
      .mux (eqk alu_op 0xd) (.ashr rf1 sh) <|
      .mux (eqk alu_op 0x6) (.bor rf1 b_op) (.band rf1 b_op)
    else alu_y
  -- the mutant reaches the regfile through wb_val; rebuild it over `alu`
  let wb : Ex 32 :=
    .mux is_load_w ld_out (.mux (or1 is_jal is_jalr) pc_plus_4 (.mux is_lui imm (.mux is_auipc pc_plus_imm alu)))
  let prog : P (List (String × String)) := do
    let a ← pin_out.pr
    let p ← phase_pins.pr
    let r ← retire.pr
    let npc ← n_pc.pr
    let nph ← n_phase.pr
    let nk ← n_kind.pr
    let nsb ← n_storeBeat.pr
    let nfo ← n_fetchOwed.pr
    let nia ← n_inAcc.pr
    let nir ← n_instrR.pr
    let nrd ← n_rdataR.pr
    let we ← rf_we.pr
    let wa ← rd.pr
    let wd ← wb.pr
    pure [("a", a), ("p", p), ("r", r), ("npc", npc), ("nph", nph), ("nk", nk), ("nsb", nsb),
          ("nfo", nfo), ("nia", nia), ("nir", nir), ("nrd", nrd), ("we", we), ("wa", wa), ("wd", wd)]
  let (names, st) := prog.run {}
  let g (key : String) : String := (names.lookup key).getD "?"
  let regDecls := (List.range 31).map fun j => s!"  reg [31:0] {regName (j + 1)};"
  let regWrites := (List.range 31).map fun j =>
    s!"    if ({g "we"} && {g "wa"} == 5'd{j + 1}) {regName (j + 1)} <= {g "wd"};"
  let lines : List String :=
    [ "// GENERATED by SaltWorks/Silicon/Refine/Emit.lean from Model.lean. Do not edit.",
      "module plane32bus(clk, rst_n, sof, instr_byte, addr_byte, phase_o, retire);",
      "  input wire clk, rst_n, sof;", "  input wire [7:0] instr_byte;",
      "  output wire [7:0] addr_byte;", "  output wire [1:0] phase_o;", "  output wire retire;",
      s!"  reg [31:0] {Sig.vname .pc};", s!"  reg [1:0] {Sig.vname .phase};",
      s!"  reg [1:0] {Sig.vname .kind};", s!"  reg {Sig.vname .storeBeat};",
      s!"  reg {Sig.vname .fetchOwed};", s!"  reg [31:0] {Sig.vname .inAcc};",
      s!"  reg [31:0] {Sig.vname .instrR};", s!"  reg [31:0] {Sig.vname .rdataR};" ]
    ++ regDecls ++ st.lines.toList ++
    [ s!"  assign addr_byte = {g "a"};", s!"  assign phase_o = {g "p"};", s!"  assign retire = {g "r"};",
      "  always @(posedge clk) begin",
      s!"    {Sig.vname .pc} <= {g "npc"};", s!"    {Sig.vname .phase} <= {g "nph"};",
      s!"    {Sig.vname .kind} <= {g "nk"};", s!"    {Sig.vname .storeBeat} <= {g "nsb"};",
      s!"    {Sig.vname .fetchOwed} <= {g "nfo"};", s!"    {Sig.vname .inAcc} <= {g "nia"};",
      s!"    {Sig.vname .instrR} <= {g "nir"};", s!"    {Sig.vname .rdataR} <= {g "nrd"};" ]
    ++ regWrites ++ [ "  end", "endmodule", "" ]
  return String.intercalate "\n" lines

end SaltWorks.Silicon.Refine.Emit
