import SaltWorks.HDL.CorePlace

/-! # §1 MEASUREMENT HARNESS for `docs/core-account.md` — compiler's slot

Every number in the account's §1 is produced HERE, by the elaborator reading the real `Circ`
artifacts, and then transcribed into the document. **Nothing in §1 is copied from `CoreOffsets`'
literals, from the assembly plan, or from a memory** — that is the account's inherited discipline
and this file is the instrument it names.

**TRACKED** (evidence's §4 finding 1, 2026-08-09 13:41): v1 of this harness was named
`Scratch*`, which `.gitignore:2` excludes — so every figure in §1 named an instrument **no one
outside this machine could re-run**. Naming a tool answers "which tool"; it does not answer
"can another party reproduce it". Renamed and committed.

It is deliberately **NOT rooted in the hub** — an `#eval`-only module would print on every fleet
build. It is run explicitly: `../saltbuild.sh SaltWorks/HDL/AccountMeasure.lean`. **No
`import owed`** — this is an instrument, not a build target. -/

namespace SaltWorks.HDL.AccountMeasure

open SaltWorks.HDL SaltWorks.HDL.CorePlace SaltWorks.Stack.Program

/-- One row of §1.1, as the elaborator sees it. -/
def measRow (nm : String) (c : Circ) (off : Nat) : String :=
  s!"| {nm} | {c.gates.length} | {c.nIn} | {c.outs.length} | {off} |"

#eval show IO Unit from do
  IO.println "=== §1.1 ROWS — organ | gates | nIn | outs | offset"
  IO.println (measRow "tieCells"      tieCells                     offTie)
  IO.println (measRow "decoder"       decoder                      off0)
  IO.println (measRow "immBCirc"      immBCirc                     off1)
  IO.println (measRow "readTree.rs1"  readTree                     off2)
  IO.println (measRow "readTree.rs2"  readTree                     off3)
  IO.println (measRow "bitXor32"      bitXor32                     off4)
  IO.println (measRow "bitNot32"      bitNot32                     off5)
  IO.println (measRow "obMux"         OperandB.obMux               offOb)
  IO.println (measRow "adder32.add"   adder32                      offAdd)
  IO.println (measRow "adder32.sub"   adder32                      offSub)
  IO.println (measRow "sltCirc"       sltCirc                      offSlt)
  IO.println (measRow "sliceASelect"  SelectCut32.sliceASelect     offSel)
  IO.println (measRow "ruledEnc"      EncoderE1.ruledEnc           offEnc)
  IO.println (measRow "regWrite"      regWrite                     offRw)
  IO.println (measRow "pcAdd"         SaltWorks.Stack.Program.pcAdd offPc)
  IO.println (measRow "regNext"       regNext                      offRegNext)

#eval show IO Unit from do
  let gs : List Nat :=
    [ tieCells.gates.length, decoder.gates.length, immBCirc.gates.length,
      readTree.gates.length, readTree.gates.length, bitXor32.gates.length,
      bitNot32.gates.length, OperandB.obMux.gates.length, adder32.gates.length,
      adder32.gates.length, sltCirc.gates.length, SelectCut32.sliceASelect.gates.length,
      EncoderE1.ruledEnc.gates.length, regWrite.gates.length,
      SaltWorks.Stack.Program.pcAdd.gates.length, regNext.gates.length ]
  IO.println "=== §1.2 TOTALS"
  IO.println s!"rows                      = {gs.length}"
  IO.println s!"total gates (incl. ties)   = {gs.foldl (· + ·) 0}"
  IO.println s!"total gates (organs only)  = {gs.foldl (· + ·) 0 - tieCells.gates.length}"
  IO.println s!"coreInWidth (input nets)   = {coreInWidth}"
  IO.println s!"stWidth (state bits)       = {stWidth}"
  IO.println s!"instrBase                  = {instrBase}"
  IO.println s!"first gate net (offTie)    = {offTie}"
  IO.println s!"last net (end of chain)    = {instNext regNext offRegNext - 1}"
  IO.println s!"total nets                 = {instNext regNext offRegNext}"
  IO.println s!"regfile state bits         = {32 * 32}"
  IO.println s!"pc state bits              = {stWidth - 32 * 32}"

#eval show IO Unit from do
  IO.println "=== §1.1 PORT MAPS — the source-port map as the file records it"
  for r in pcAddPortMap do
    IO.println s!"| pcAdd | {r.loNet}…{r.hiNet} | {r.source} |"
  IO.println "=== regNext banks (RegNext.lean:76-81), stated as nets"
  IO.println s!"| regNext | 0…31 | we[r] <- regWrite outs |"
  IO.println s!"| regNext | 32…63 | res[k] <- sliceASelect outs |"
  IO.println s!"| regNext | 64…{regNext.nIn - 1} | cur[r][k] <- core input 32r+k (shift i-64) |"

#eval show IO Unit from do
  IO.println "=== §1.2 CROSS-CHECK: does the derived chain match CoreOffsets' literal table?"
  IO.println s!"CorePlace offRegNext + regNext gates = {instNext regNext offRegNext}"
  IO.println s!"CoreOffsets chain_last literal        = 11459"
  IO.println s!"expected = 11459 + tie cells = {11459 + tieCells.gates.length}"
  IO.println s!"RECONCILES = {instNext regNext offRegNext == 11459 + tieCells.gates.length}"
  IO.println s!"coverage invariant holds = {instNext regNext offRegNext == offTie + placedGateTotal}"

end SaltWorks.HDL.AccountMeasure
