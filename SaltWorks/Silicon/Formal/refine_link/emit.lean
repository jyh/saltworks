import SaltWorks.Silicon.Refine.Emit
-- Writes the Lean model as Verilog: the faithful module, and the ALU_ASHR mutant control.
-- Run by run_link.sh through saltbuild's file form; OUT_DIR names the destination.
def emitAll : IO Unit := do
  let d := (← IO.getEnv "OUT_DIR").getD "."
  IO.FS.writeFile s!"{d}/model.v" (SaltWorks.Silicon.Refine.Emit.module false)
  IO.FS.writeFile s!"{d}/model_ashr.v" (SaltWorks.Silicon.Refine.Emit.module true)
  IO.FS.writeFile s!"{d}/model_comb.v" (SaltWorks.Silicon.Refine.Emit.moduleComb false)
  IO.FS.writeFile s!"{d}/model_comb_ashr.v" (SaltWorks.Silicon.Refine.Emit.moduleComb true)
  IO.println s!"emitted {d}/model.v, {d}/model_ashr.v and {d}/model_comb.v"

#eval emitAll
