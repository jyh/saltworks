/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Silicon.Refine.Statement

/-!
# AAU — the statement is not vacuous, and the flag is the whole difference

`RefinesE` is an implication from `runSpec … = some _`. If the spec never ran, it would hold of every
machine. These kernel-checked computations drive a four-instruction program through `runSpec` under
both flags. They show that each erratum is reached and that it changes the state: SRAI gives
`0x7FFFFFFC` instead of `0xFFFFFFFC`, and LW gives the previous load loop's word. They also pin the
loop sequence and the pin trace that the claim asserts.

Program (fetched at 0, 4, 8, 12):
`ADDI x1,x0,-8` = `0xFF800093` · `SRAI x2,x1,1` = `0x4010D113` · `LW x3,0(x0)` = `0x00002183` ·
`LW x4,0(x0)` = `0x00002203`. The host returns `0xDEADBEEF` in the first load loop and `0x12345678`
in the second.
-/

namespace SaltWorks.Silicon.Refine.Checks
open SaltWorks.Silicon.Refine

/-- The host's word for each 4-cycle loop, in order. -/
def loopWords : List W :=
  [0xFF800093#32, 0x4010D113#32, 0x00002183#32, 0xDEADBEEF#32, 0x00002203#32, 0x12345678#32]

/-- Byte `c % 4` of the word for loop `c / 4`; zero past the end. -/
def host (c : Nat) : BitVec 8 := ((loopWords.getD (c / 4) 0) >>> (8 * (c % 4))).setWidth 8

def r0 : BitVec 5 → W := fun _ => 0

/-- Under erratum E: x2 = SRAI logical, x3 = 0 (no earlier load), x4 = the FIRST load's word. -/
example : (runSpec true host r0 4).map (fun (s, c, _) =>
    (s.arch.get 1, s.arch.get 2, s.arch.get 3, s.arch.get 4, s.arch.pc, c)) =
    some (0xFFFFFFF8#32, 0x7FFFFFFC#32, 0#32, 0xDEADBEEF#32, 16#32, 24) := by decide

/-- Plain RV32I, same host: x2 arithmetic, x3/x4 their own loads' words. -/
example : (runSpec false host r0 4).map (fun (s, c, _) =>
    (s.arch.get 1, s.arch.get 2, s.arch.get 3, s.arch.get 4, s.arch.pc, c)) =
    some (0xFFFFFFF8#32, 0xFFFFFFFC#32, 0xDEADBEEF#32, 0x12345678#32, 16#32, 24) := by decide

/-- The loops the claim pins: four fetches at pc, two load loops at address 0. -/
example : (runSpec true host r0 4).map (fun (_, _, ls) => ls) =
    some [⟨.fetch, 0#32⟩, ⟨.fetch, 4#32⟩, ⟨.fetch, 8#32⟩, ⟨.load, 0#32⟩,
          ⟨.fetch, 12#32⟩, ⟨.load, 0#32⟩] := by decide

/-- The pin trace at the cycles of the third fetch (pc = 8): byte 8 with TYPE 01, then 0/1, 0/2, 0/3. -/
example : (runSpec true host r0 4).map (fun (_, _, ls) => (ls.flatMap Loop.emit).drop 8 |>.take 4) =
    some [(8#8, 1#2), (0#8, 1#2), (0#8, 2#2), (0#8, 3#2)] := by decide

/-- Out of scope ends the run: a fifth fetch reads word 0 (illegal), so `runSpec … 5 = none`. -/
example : runSpec true host r0 5 = none := by decide

end SaltWorks.Silicon.Refine.Checks
