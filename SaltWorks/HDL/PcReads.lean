/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: compiler seat

# `PcDatapathOK` reduces to five named wires

`PcTransport` made the 33rd obligation a datapath sentence. This file pays most of it.

⭐ **`sem_pcAdd` (`Program.lean:4938`) already proves the pc path computes
`pc + (if BEQ-taken then off else 4)` on ALL 2^129 inputs — structurally, no `decide`, no
`native_decide`, no sample.** So the adder, the branch mux and the equality comparator are
**already discharged**; nothing about pc arithmetic remains.

```
pcDatapath_of_reads :
  (∀ ins, pcOf ins + (if isBEQOf' ins && rs1Of ins == rs2Of ins then immOf ins else 4)
            = (stepT (decQ ins) (seenWord ins)).pc)
  → PcDatapathOK
```
⇒ ***what is left of the pc obligation is only that the five wires `core` feeds `pcAdd`
carry what the ISA says they do*** — `pcOf` (a primary input, `pcNet k = 1024 + k`), `rs1Of`
/ `rs2Of` (the two read trees), `immOf` (the immediate block), `isBEQOf'` (`decOut 4`,
verified correct in the `a10f980` blast-radius sweep).

*The port layouts of `pcAddSig` and `pcAddEnv` were written independently and agree exactly,
which is what makes `pcEnv_agrees` a case split rather than a proof.*

⛔ Not C4, not a witness, does not close R9/B2, criterion (c) open. The five reads are not
proved here — `rs1Of`/`rs2Of`/`immOf` need the read-tree and immediate organs transported,
the same move this file makes for `pcAdd`.
-/
import SaltWorks.HDL.PcTransport

namespace SaltWorks.HDL.RegNextUniform
open SaltWorks.HDL SaltWorks.ISA
open SaltWorks.HDL.CorePlace
open SaltWorks.Stack.Program

theorem coreThruRw_sub : coreThruRw ⊆ core.gates := by
  intro g hg
  rw [core_gates_from13]
  rcases List.mem_append.mp hg with h | h
  · exact List.mem_append_left _ h
  · exact List.mem_append_right _ (List.mem_append_left _ (List.mem_append_left _ h))

theorem coreThruRw_input_stable (ins : Env) (n : Net) (hn : n < coreInWidth) :
    run ins coreThruRw n = ins n :=
  run_of_unwritten ins _ n (fun g hg hEq =>
    absurd (hEq ▸ core_gate_out_ge g (coreThruRw_sub hg)) (Nat.not_le.mpr hn))

/-! ### The five reads the pc path depends on -/

def pcOf    (ins : Env) : BitVec 32 := wordOf (fun k => ins (pcNet k))
def rs1Of   (ins : Env) : BitVec 32 := wordOf (fun k => run ins coreThruRw (rs1Out k))
def rs2Of   (ins : Env) : BitVec 32 := wordOf (fun k => run ins coreThruRw (rs2Out k))
def immOf   (ins : Env) : BitVec 32 := wordOf (fun k => run ins coreThruRw (immOut k))
def isBEQOf' (ins : Env) : Bool := run ins coreThruRw (decOut isBEQLine)

theorem pcAdd_nIn_129 : SaltWorks.Stack.Program.pcAdd.nIn = 129 := by decide +kernel

/-- **The environment `pcAdd` sees inside `core` IS `pcAddEnv` of the five reads.**
*`pcAddSig`'s port layout and `pcAddEnv`'s were written independently and agree exactly;
that is what makes this a case split rather than a proof.* -/
theorem pcEnv_agrees (ins : Env) (i : Nat) (hi : i < SaltWorks.Stack.Program.pcAdd.nIn) :
    run ins coreThruRw (pcAddSig i)
      = pcAddEnv (pcOf ins) (rs1Of ins) (rs2Of ins) (immOf ins) (isBEQOf' ins) i := by
  rw [pcAdd_nIn_129] at hi
  show run ins coreThruRw (pcAddSig i)
      = (if i < 32 then (pcOf ins).getLsbD i
         else if i < 64 then (rs1Of ins).getLsbD (i - 32)
         else if i < 96 then (rs2Of ins).getLsbD (i - 64)
         else if i < 128 then (immOf ins).getLsbD (i - 96)
         else isBEQOf' ins)
  by_cases h0 : i < 32
  · rw [if_pos h0, show pcAddSig i = pcNet i from by simp [pcAddSig, h0],
        coreThruRw_input_stable ins _ (by simp only [pcNet, coreInWidth, stWidth, Net]; omega),
        pcOf, wordOf_getLsbD _ _ h0]
  · rw [if_neg h0]
    by_cases h1 : i < 64
    · rw [if_pos h1, show pcAddSig i = rs1Out (i - 32) from by simp [pcAddSig, h0, h1],
          rs1Of, wordOf_getLsbD _ _ (by omega)]
    · rw [if_neg h1]
      by_cases h2 : i < 96
      · rw [if_pos h2, show pcAddSig i = rs2Out (i - 64) from by simp [pcAddSig, h0, h1, h2],
            rs2Of, wordOf_getLsbD _ _ (by omega)]
      · rw [if_neg h2]
        by_cases h3 : i < 128
        · rw [if_pos h3, show pcAddSig i = immOut (i - 96) from by simp [pcAddSig, h0, h1, h2, h3],
              immOf, wordOf_getLsbD _ _ (by omega)]
        · rw [if_neg h3, show pcAddSig i = decOut isBEQLine from by simp [pcAddSig, h0, h1, h2, h3],
              isBEQOf']

theorem pcAdd_out_bound (k : Nat) (hk : k < 32) :
    SaltWorks.Stack.Program.pcAdd.outs.getD k 0
      < SaltWorks.Stack.Program.pcAdd.nIn + SaltWorks.Stack.Program.pcAdd.gates.length := by
  revert k; decide +kernel

/-- ⭐⭐⭐ **THE PC OBLIGATION REDUCES TO FIVE NAMED READS.** `sem_pcAdd` proves the pc path
computes `pc + (if BEQ-taken then off else 4)` **on all 2^129 inputs, structurally, with no
`decide` and no sample** — so the adder, the branch mux and the equality comparator are
ALREADY DISCHARGED. What is left of `PcDatapathOK` is only that the five wires `core` feeds
`pcAdd` carry what the ISA says they do. -/
theorem pcDatapath_of_reads
    (h : ∀ ins : Env,
      pcOf ins + (if isBEQOf' ins && (rs1Of ins == rs2Of ins) then immOf ins else 4)
        = (SaltWorks.ISA.stepT (decQ ins) (seenWord ins)).pc) :
    PcDatapathOK := by
  intro ins k hk
  rw [run_agree_of_inputs_circ SaltWorks.Stack.Program.pcAdd
        SaltWorks.Stack.Program.pcAdd_ssa _
        (pcAddEnv (pcOf ins) (rs1Of ins) (rs2Of ins) (immOf ins) (isBEQOf' ins))
        (fun a ha => pcEnv_agrees ins a ha) _ (pcAdd_out_bound k hk)]
  have hs := congrArg (fun l : List Bool => l.getD k false)
    (SaltWorks.Stack.Program.sem_pcAdd (pcOf ins) (rs1Of ins) (rs2Of ins) (immOf ins)
      (isBEQOf' ins))
  simp only [sem] at hs
  rw [getD_map_lt _ _ _ (by rw [pcAdd_outs_len]; exact hk) 0 false] at hs
  -- ⚠️ do NOT let `simp` run before `h ins`: it normalises `(b && x == y) = true` into
  -- `b = true ∧ x = y`, after which the hypothesis no longer matches syntactically.
  rw [hs, getD_map_lt _ _ _ (by simpa using hk) 0 false,
      show (List.range 32).getD k 0 = k from by simp [hk],
      h ins]

#audit_axioms coreThruRw_input_stable pcEnv_agrees
#audit_axioms pcAdd_out_bound pcDatapath_of_reads

end SaltWorks.HDL.RegNextUniform
