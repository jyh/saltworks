# THE Q3 SWAP'S ERROR TEXT UNDER THE STAGED `StateCodec` PATCH — MEASURED, PINNED, RE-DERIVABLE

⛔ **ANCHOR: measured on `02b72ae`, with `docs/Q3-SWAP-STAGED-STATECODEC-0822.diff` applied and the
working diff verified BYTE-IDENTICAL to that patch first.** `SaltWorks/Stack/Program.lean` was
unchanged between that commit and the measurement, so the line numbers are the tree's, not just
mine. ⚠️ **THEY EXPIRE ON THE FIRST EDIT TO `Program.lean` — INCLUDING THE PREPARER'S OWN.**
Re-derive rather than trust this file once you start editing; helm's landing condition (2)
requires a fresh census in the landing commit for exactly this reason.

    RE-DERIVE:  git worktree add <dir> HEAD && cp -Rc .lake <dir>/.lake
                cd <dir> && git apply docs/Q3-SWAP-STAGED-STATECODEC-0822.diff
                <repo>/tools/saltbuild.sh SaltWorks.Stack.Program

⭐ **9 REAL ERRORS AT 8 DISTINCT LINES, PLUS 26 `sorryAx` CASCADE LINES THAT ARE NOT WORK.**
A failed tactic errors *and* fills the hole, so every downstream `#audit_axioms` tick errors too.
The cascade vanishes when the real ones are fixed. Handing over the raw total would hand over
26 phantoms.

## THE REAL ERRORS
```
Program.lean:1505:0  maximum recursion depth has been reached
    use `set_option maxRecDepth <num>` to increase limit
    use `set_option diagnostics true` to get diagnostic information

Program.lean:1507:57  Type mismatch
      rfl
    has type
      ?m.8 = ?m.8
    but is expected to have type
      (HDL.decQ e).mem = Vector.replicate 8 0

Program.lean:1509:0  Not a definitional equality: the left-hand side
      (HDL.decQ e).trapped
    is not definitionally equal to the right-hand side
      false

Program.lean:1510:46  Type mismatch
      rfl
    has type
      ?m.3 = ?m.3
    but is expected to have type
      (HDL.decQ e).trapped = false

Program.lean:1567:82  omega could not prove the goal:
    a possible counterexample may satisfy the constraints
      d ≥ 1313
      0 ≤ c ≤ 31
    where
     c := ↑k
     d := ↑(?m.116 k)

Program.lean:1598:13  Application type mismatch: The argument
      hp
    has type
      (HDL.wordOf fun k ↦ envWith s w (1024 + k)) = s.pc
    but is expected to have type
      (HDL.wordOf fun k ↦ envWith s w (1024 + k)) = s.pc ∧
        (Vector.ofFn fun w_1 ↦ HDL.wordOf fun k ↦ envWith s w (1056 + 32 * ↑w_1 + k)) = Vector.replicate 8 0 ∧
          envWith s w 1312 = false
    in the application
      ⟨hr, hp⟩

Program.lean:2435:5  unsolved goals
    nextW : HDL.Env → Word
    pad ins : HDL.Env
    ⊢ (Vector.ofFn fun w ↦ HDL.wordOf fun k ↦ ins (1056 + 32 * ↑w + k)) = Vector.replicate 8 0#32

Program.lean:2435:36  unsolved goals
    nextW : HDL.Env → Word
    pad ins : HDL.Env
    ⊢ ins 1312 = false

Program.lean:2768:36  omega could not prove the goal:
    a possible counterexample may satisfy the constraints
      32 ≤ b ≤ 288
      a ≥ 0
      a - b ≥ 1025
    where
     a := ↑HDL.stWidth
     b := ↑(j - 1024)

```

## THE CASCADE — DO NOT WORK THESE
```
Program.lean:9250:0  #audit_axioms: 'SaltWorks.Stack.Program.cycles_realise_steps_of_memFree' depends on non-whitelisted 
Program.lean:9251:0  #audit_axioms: 'SaltWorks.Stack.Program.decQ_mem' depends on non-whitelisted axiom(s): sorryAx. Allo
Program.lean:9252:0  #audit_axioms: 'SaltWorks.Stack.Program.decQ_congr' depends on non-whitelisted axiom(s): sorryAx. Al
Program.lean:9253:0  #audit_axioms: 'SaltWorks.Stack.Program.decQ_envWith_of_clean' depends on non-whitelisted axiom(s): 
Program.lean:9263:0  #audit_axioms: 'SaltWorks.Stack.Program.decQ_cycOf_proj' depends on non-whitelisted axiom(s): sorryA
Program.lean:9264:0  #audit_axioms: 'SaltWorks.Stack.Program.not_cycleRealisesStep_id' depends on non-whitelisted axiom(s
Program.lean:9270:0  #audit_axioms: 'SaltWorks.Stack.Program.cycles_sort' depends on non-whitelisted axiom(s): sorryAx. A
Program.lean:9272:0  #audit_axioms: 'SaltWorks.Stack.Program.cycleRealisesStepProj_of_bits' depends on non-whitelisted ax
Program.lean:9274:0  #audit_axioms: 'SaltWorks.Stack.Program.cycleRealisesStep_of_C4Spec' depends on non-whitelisted axio
Program.lean:9275:0  #audit_axioms: 'SaltWorks.Stack.Program.sorts_of_C4' depends on non-whitelisted axiom(s): sorryAx. A
Program.lean:9276:0  #audit_axioms: 'SaltWorks.Stack.Program.cycleRealisesStep_idealBits' depends on non-whitelisted axio
Program.lean:9277:0  #audit_axioms: 'SaltWorks.Stack.Program.decQ_cycOfBits_stalled' depends on non-whitelisted axiom(s):
Program.lean:9284:0  #audit_axioms: 'SaltWorks.Stack.Program.c4Spec_iff_fieldwise' depends on non-whitelisted axiom(s): s
Program.lean:9285:0  #audit_axioms: 'SaltWorks.Stack.Program.c4Spec_of_fieldwise' depends on non-whitelisted axiom(s): so
Program.lean:9286:0  #audit_axioms: 'SaltWorks.Stack.Program.not_C4Spec_of_not_regField' depends on non-whitelisted axiom
Program.lean:9289:0  #audit_axioms: 'SaltWorks.Stack.Program.not_regField_one_coreShaped' depends on non-whitelisted axio
Program.lean:9290:0  #audit_axioms: 'SaltWorks.Stack.Program.not_pcField_coreShaped' depends on non-whitelisted axiom(s):
Program.lean:9292:0  #audit_axioms: 'SaltWorks.Stack.Program.not_pcField_coreShapedT' depends on non-whitelisted axiom(s)
Program.lean:9297:0  #audit_axioms: 'SaltWorks.Stack.Program.xorField_is_bitXor32' depends on non-whitelisted axiom(s): s
Program.lean:9299:0  #audit_axioms: 'SaltWorks.Stack.Program.sltField_is_sltCirc' depends on non-whitelisted axiom(s): so
Program.lean:9300:0  #audit_axioms: 'SaltWorks.Stack.Program.bitAnd32_fails_the_xorField' depends on non-whitelisted axio
Program.lean:9315:0  #audit_axioms: 'SaltWorks.Stack.Program.addField_is_adder32' depends on non-whitelisted axiom(s): so
Program.lean:9338:0  #audit_axioms: 'SaltWorks.Stack.Program.pcField_is_pcNext_beq' depends on non-whitelisted axiom(s): 
Program.lean:9347:0  #audit_axioms: 'SaltWorks.Stack.Program.pcField_is_pcAdd_beq' depends on non-whitelisted axiom(s): s
Program.lean:9356:0  #audit_axioms: 'SaltWorks.Stack.Program.aluField_is_aluSelect_add' depends on non-whitelisted axiom(
Program.lean:9358:0  #audit_axioms: 'SaltWorks.Stack.Program.addend_as_pc_is_wrong_unless_pc_zero' depends on non-whiteli
```

