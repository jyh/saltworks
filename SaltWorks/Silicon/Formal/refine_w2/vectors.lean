import SaltWorks.Silicon.Refine.Statement
/-!
W2 differential vectors: `exec false` (RV32I, no erratum; `W2_E=1` for `exec true`) on pseudo-random inputs, for comparison
against riscv-formal's per-instruction models (`run_w2.sh`). Each line, in hex:
`insn rs1v rs2v pc memr  status rd rdval pcnext kind memaddr memwdata`
* status: `S` (in scope; outputs follow) or `N` (`decode` none, or exec none). The outputs are 0 for N.
* kind: 0 none, 1 load, 2 store. `rd`/`rdval` are normalised as riscv-formal does: 0/0 for no write.
-/
open SaltWorks.Silicon.Refine

def lcg (x : Nat) : Nat := (x * 6364136223846793005 + 1442695040888963407) % 2 ^ 64
def hx (v : Nat) : String := let s := String.ofList (Nat.toDigits 16 v); String.ofList (List.replicate (8 - s.length) '0') ++ s

/-- (opcode, funct3, funct7) per op; funct7 = 128 means "random". -/
def enc : List (Nat × Nat × Nat) :=
  [(0x37,8,128),(0x17,8,128),(0x6F,8,128),(0x67,0,128),
   (0x63,0,128),(0x63,1,128),(0x63,4,128),(0x63,5,128),(0x63,6,128),(0x63,7,128),
   (0x03,2,128),(0x23,2,128),
   (0x13,0,128),(0x13,2,128),(0x13,3,128),(0x13,4,128),(0x13,6,128),(0x13,7,128),
   (0x13,1,0),(0x13,5,0),(0x13,5,0x20),
   (0x33,0,0),(0x33,0,0x20),(0x33,1,0),(0x33,2,0),(0x33,3,0),(0x33,4,0),(0x33,5,0),(0x33,5,0x20),
   (0x33,6,0),(0x33,7,0)]

def force (r : Nat) (e : Nat × Nat × Nat) : Nat :=
  let (op, f3, f7) := e
  let w := r % 2 ^ 32
  let w := (w / 128) * 128 + op
  let w := if f3 < 8 then (w % 2 ^ 12) + f3 * 2 ^ 12 + (w / 2 ^ 15) * 2 ^ 15 else w
  if f7 < 128 then (w % 2 ^ 25) + f7 * 2 ^ 25 else w

def oneLine (e : Bool) (insn rs1v rs2v pc memr : Nat) : String :=
  let iw : W := BitVec.ofNat 32 insn
  let ins := s!"{hx insn} {hx rs1v} {hx rs2v} {hx pc} {hx memr}"
  match decode iw with
  | none => ins ++ " N 0 00000000 00000000 0 00000000 00000000"
  | some d =>
    let x : BitVec 5 → W := fun j =>
      if j = d.rs1 then BitVec.ofNat 32 rs1v else if j = d.rs2 then BitVec.ofNat 32 rs2v else 0
    let s : EState := ⟨⟨BitVec.ofNat 32 pc, x⟩, 0⟩
    match exec e s d (BitVec.ofNat 32 memr) with
    | none => ins ++ " N 0 00000000 00000000 0 00000000 00000000"
    | some (s', ls) =>
      let writes := match d.op with
        | .beq | .bne | .blt | .bge | .bltu | .bgeu | .sw => false | _ => true
      let rd := if writes = true then d.rd.toNat else 0
      let rdv := if (writes && d.rd != 0) = true then (s'.arch.get d.rd).toNat else 0
      let (kind, ma, mw) := match ls with
        | [_, ⟨.load, a⟩] => (1, a.toNat, 0)
        | [_, ⟨.store, a⟩, ⟨.store, v⟩] => (2, a.toNat, v.toNat)
        | _ => (0, 0, 0)
      ins ++ s!" S {rd} {hx rdv} {hx s'.arch.pc.toNat} {kind} {hx ma} {hx mw}"

def gen (e : Bool) (n : Nat) : List String := Id.run do
  let mut x := 20261006
  let mut out : List String := []
  for i in [0:n] do
    x := lcg x; let r1 := x
    x := lcg x; let r2 := x
    x := lcg x; let r3 := x
    x := lcg x; let r4 := x
    x := lcg x; let r5 := x
    -- 31 forced families, then 1 in 8 fully random words
    let insn := if i % 8 = 7 then r1 % 2 ^ 32 else force r1 (enc.getD (i % 31) (0,0,0))
    -- small operands one time in four, so x0, equal registers and edge values occur
    let rs1v := if r2 % 4 = 0 then r2 / 4 % 8 else r2 / 4 % 2 ^ 32
    let rs2v := if r3 % 4 = 0 then r3 / 4 % 8 else r3 / 4 % 2 ^ 32
    let pc := (r4 % 2 ^ 32) / 4 * 4
    -- RVFI convention: a read of x0 reports 0, and two reads of one register report one value
    let f1 := insn / 2 ^ 15 % 32
    let f2 := insn / 2 ^ 20 % 32
    let rs1v := if f1 = 0 then 0 else rs1v
    let rs2v := if f2 = 0 then 0 else if f2 = f1 then rs1v else rs2v
    out := oneLine e insn rs1v rs2v pc (r5 % 2 ^ 32) :: out
  return out.reverse

def main' : IO Unit := do
  let d := (← IO.getEnv "OUT_DIR").getD "."
  let n := ((← IO.getEnv "W2_N").bind String.toNat?).getD 8000
  -- W2_E=1 is the comparator's CONTROL: the erratum spec must disagree on SRA, SRAI, LW only
  let e := (← IO.getEnv "W2_E") == some "1"
  IO.FS.writeFile s!"{d}/w2_vectors.txt" (String.intercalate "\n" (gen e n) ++ "\n")
  IO.println s!"wrote {n} vectors to {d}/w2_vectors.txt"
#eval main'
