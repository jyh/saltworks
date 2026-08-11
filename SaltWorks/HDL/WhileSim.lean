import SaltWorks.HDL.WhileScheme

/-! # L2 ROW A — THE SIMULATION THEOREM ACROSS LOOPS, `Reaches`-shaped

Block ① rung **L2**, the half that decides the rung. `compileS` now emits `while`
(`CompileS.lean`), and this file is the theorem that says what the emitted loop DOES.

## Why it is `Reaches`-shaped and cannot be `run`-shaped

`run`'s fuel is `code.length` — one tick per instruction — and **a loop needs more ticks
than the program has instructions**. `BlockCalc.run_has_too_little_fuel_for_a_loop` is the
landed proof: `loopCode` is two instructions and `run` stops mid-loop. *So a `run`-shaped
statement is correct exactly on the straight-line fragment, which is why L0 and L1 are
allowed one and this is not.* The ∃-fuel form composes unconditionally by `runFor_add`,
which is why the fuel was never L2's hard part.

## What the proof actually leans on

```
skip · assign      LIFTED, not re-proved — `assign` discharges by the landed
                   reaches_of_compileS_of_branchFree verbatim
seq · letmut       codeAt_append_left/right split the block; Reaches.trans chains
whileF             condition block runs straight-line, the guard is 0, the exit
                   branch is TAKEN and lands past the loop  (step_exit_taken)
whileT             guard is 1 so the exit branch FALLS THROUGH; the body runs by
                   the derivation's own IH; the BACKWARD branch closes the loop
                   (step_back_taken); and the RESIDUAL loop runs by the other IH
                   AT THE SAME POSITION with the SAME block
ite                still `none` — the fragment boundary that remains
```

🔑 ***THE INDUCTION IS ON THE `bigStep` DERIVATION, NOT ON THE STATEMENT.*** *That is the
whole reason `whileT` works: it hands you an IH for the body AND an IH for the residual
loop, so "the loop terminates" is supplied by the derivation rather than proved here.*

⭐ **AND L1 WAS NOT RE-PROVED.** `BlockCalc`'s docstring says that if L2's branch cases ever
force L1 to be re-proved, the calculus is wrong. They did not: the `assign` case is one line
citing the landed theorem.
-/

open SaltWorks.ISA
open SaltWorks.StraightLine
open SaltWorks.RegMap
open SaltWorks.HDL.TinyRustN0
open SaltWorks.CompileE
open SaltWorks.CompileS
open SaltWorks.BlockCalc

namespace SaltWorks.WhileSim

theorem reaches_of_compileS_including_while {reg : RegMap} {d : Nat} (hreg : RegOk reg d) :
    ∀ {Γ : Ctx} {p : Stmt} {σ σ' : State}, bigStep Γ p σ σ' → chkS Γ p = true →
      ∀ {image blk : List Instr} {q : Nat} {st : St},
        compileS reg d Γ p = some blk → codeAt image q blk →
        encodeOK Γ reg σ st → st.pc.toNat = 4 * q →
        4 * (q + blk.length) < 2 ^ 32 →
        ∃ st', Reaches image st st' ∧ encodeOK Γ reg σ' st' ∧
          st'.pc.toNat = 4 * (q + blk.length) := by
  intro Γ p σ σ' hbs
  induction hbs with
  | skip =>
      intro _ image blk q st h _ henc hpc _
      rw [← Option.some.inj h]
      exact ⟨st, Reaches.refl image st, by simpa using henc, by simpa using hpc⟩
  | @assign Γ x e σ =>
      intro hchk image blk q st h hat henc hpc hb
      exact reaches_of_compileS_of_branchFree hreg (.assign) rfl hchk h hat henc hpc hb
  | @seq Γ s t σ σ₁ σ' _ _ ihs iht =>
      intro hchk image blk q st h hat henc hpc hb
      obtain ⟨cs, ct, hs, ht, rfl⟩ := compileS_seq_shape h
      obtain ⟨hcs, hct⟩ := chkS_seq_inv hchk
      have hlen : (cs ++ ct).length = cs.length + ct.length := by simp
      rw [hlen] at hb
      obtain ⟨st₁, hr1, he1, hp1⟩ :=
        ihs hcs hs (codeAt_append_left hat) henc hpc (by omega)
      obtain ⟨st₂, hr2, he2, hp2⟩ :=
        iht hct ht (codeAt_append_right hat) he1 hp1 (by omega)
      refine ⟨st₂, Reaches.trans hr1 hr2, he2, ?_⟩
      rw [hp2, hlen]; omega
  | @letmut Γ x ty e body σ σ' _ ih =>
      intro hchk image blk q st h hat henc hpc hb
      obtain ⟨ce, rd, rl, cb, hce, hrd, hrl, hcb, rfl⟩ := compileS_letmut_shape h
      obtain ⟨hie, hbody⟩ := chkS_letmut_inv hchk
      obtain ⟨hlen, rfl⟩ := lvlReg_eq hrl
      have hlenP : (ce ++ [Instr.ADDI (reg ⟨Γ.length, hlen⟩) rd 0]).length = ce.length + 1 := by
        simp
      have hlenB : ((ce ++ [Instr.ADDI (reg ⟨Γ.length, hlen⟩) rd 0]) ++ cb).length
          = ce.length + 1 + cb.length := by
        simp only [List.length_append, List.length_cons, List.length_nil]
      rw [hlenB] at hb
      -- ① the prefix — expression code plus the one move — is straight-line
      have hfwdE : Forward ce = true := compileE_is_forward Γ reg e d ce hce
      have hfwdP : Forward (ce ++ [Instr.ADDI (reg ⟨Γ.length, hlen⟩) rd 0]) = true := by
        simp only [Forward] at hfwdE ⊢
        simp [List.all_append, isForward, hfwdE]
      have hr1 : Reaches image st (exec st (ce ++ [Instr.ADDI (reg ⟨Γ.length, hlen⟩) rd 0])) :=
        Reaches.straightline (codeAt_append_left hat) hfwdP hpc (by rw [hlenP]; omega)
      have hpc1 : (exec st (ce ++ [Instr.ADDI (reg ⟨Γ.length, hlen⟩) rd 0])).pc.toNat
          = 4 * (q + (ce ++ [Instr.ADDI (reg ⟨Γ.length, hlen⟩) rd 0]).length) := by
        rw [exec_pc_toNat _ st hfwdP (by rw [hlenP]; omega), hpc]; omega
      -- ② the binding lands at level Γ.length, ABOVE everything the outer context names
      have hval : (exec st ce).get rd = evalE Γ σ e :=
        exec_compileE_eq_evalE_scoped hie hce hrd henc hreg.below
      have hmid : encodeOK ((x, ty) :: Γ) reg (upd σ Γ.length (evalE Γ σ e))
          (exec st (ce ++ [Instr.ADDI (reg ⟨Γ.length, hlen⟩) rd 0])) := by
        rw [exec_append]
        intro i hi
        simp only [List.length_cons] at hi
        by_cases hsame : i.val = Γ.length
        · have hfin : i = (⟨Γ.length, hlen⟩ : Fin poolSize) := Fin.ext hsame
          rw [hfin, move_writes_level hreg hlen, hval]
          simp [upd]
        · rw [move_frames_other_levels hreg hlen i hsame,
              exec_compileE_preserves_below Γ reg e d ce st hce (reg i) (hreg.below i)]
          rw [henc i (by omega)]
          simp [upd, hsame]
      -- ③ the BODY, in the extended context, by the derivation's induction hypothesis
      obtain ⟨st3, hr3, he3, hp3⟩ :=
        ih hbody hcb (codeAt_append_right hat) hmid hpc1 (by rw [hlenP]; omega)
      refine ⟨st3, Reaches.trans hr1 hr3, ?_, ?_⟩
      · intro i hi; exact he3 i (by simp only [List.length_cons]; omega)
      · rw [hp3, hlenP, hlenB]; omega
  | iteT _ _ _ => intro _ _ _ _ _ h _ _ _ _; simp [compileS] at h
  | iteF _ _ _ => intro _ _ _ _ _ h _ _ _ _; simp [compileS] at h
  | @whileF Γ c body σ hc =>
      intro hchk image blk q st h hat henc hpc hb
      obtain ⟨cc, rd, cb, hcc, hrd, hcb, hfits, rfl⟩ := compileS_while_shape h
      obtain ⟨hie, _⟩ := chkS_while_inv hchk
      rw [compileS_while_length] at hb
      have hfwd : Forward cc = true := compileE_is_forward Γ reg c d cc hcc
      have hatcc : codeAt image q cc := codeAt_append_left hat
      have hr1 : Reaches image st (exec st cc) :=
        Reaches.straightline hatcc hfwd hpc (by omega)
      have hpc1 : (exec st cc).pc.toNat = 4 * (q + cc.length) := by
        rw [exec_pc_toNat cc st hfwd (by omega), hpc]; omega
      -- the guard register holds the condition, which is FALSE here
      have hz : (exec st cc).get rd = 0 := by
        rw [exec_compileE_eq_evalE_scoped hie hcc hrd henc hreg.below, hc]
      -- the exit branch sits at block index cc.length
      have hfetch : fetch image (exec st cc).pc
          = some (Instr.BEQ rd 0 (whileExit cb.length)) := by
        have := fetch_codeAt hat (i := cc.length)
          (by simp only [List.length_append, List.length_cons]; omega) (by omega)
        simpa using this
      refine ⟨step (exec st cc) (Instr.BEQ rd 0 (whileExit cb.length)),
        Reaches.trans hr1 (Reaches.one hfetch), ?_, ?_⟩
      · intro i hi
        rw [step_BEQ_get,
            exec_compileE_preserves_below Γ reg c d cc st hcc (reg i) (hreg.below i)]
        exact henc i hi
      · rw [SaltWorks.WhileScheme.step_exit_taken cb.length (q + cc.length) hz
              (by simp only [whileFits, Bool.and_eq_true, decide_eq_true_eq] at hfits
                  omega)
              hpc1 (by omega),
            compileS_while_length]
        omega
  | @whileT Γ c body σ σ₁ σ' hc _ _ ihb ihw =>
      intro hchk image blk q st h hat henc hpc hb
      obtain ⟨cc, rd, cb, hcc, hrd, hcb, hfits, hblk⟩ := compileS_while_shape h
      obtain ⟨hie, hbody⟩ := chkS_while_inv hchk
      subst hblk
      have hbf : 2 * (cb.length + 2) ≤ 2047 ∧ 2 * (cc.length + cb.length + 1) ≤ 2048 := by
        simp only [whileFits, Bool.and_eq_true, decide_eq_true_eq] at hfits; omega
      rw [compileS_while_length] at hb
      -- ① the condition block, straight-line
      have hfwd : Forward cc = true := compileE_is_forward Γ reg c d cc hcc
      have hr1 : Reaches image st (exec st cc) :=
        Reaches.straightline (codeAt_append_left hat) hfwd hpc (by omega)
      have hpc1 : (exec st cc).pc.toNat = 4 * (q + cc.length) := by
        rw [exec_pc_toNat cc st hfwd (by omega), hpc]; omega
      have henc1 : encodeOK Γ reg σ (exec st cc) := by
        intro i hi
        rw [exec_compileE_preserves_below Γ reg c d cc st hcc (reg i) (hreg.below i)]
        exact henc i hi
      -- ② the guard is TRUE, so the exit branch FALLS THROUGH
      have hone : (exec st cc).get rd = 1 := by
        rw [exec_compileE_eq_evalE_scoped hie hcc hrd henc hreg.below, hc]
      have hne : (exec st cc).get rd ≠ (exec st cc).get 0 := by
        rw [hone, show (exec st cc).get 0 = 0 from by simp [St.get]]; decide
      have hfetch1 : fetch image (exec st cc).pc
          = some (Instr.BEQ rd 0 (whileExit cb.length)) := by
        have := fetch_codeAt hat (i := cc.length)
          (by simp only [List.length_append, List.length_cons]; omega) (by omega)
        simpa using this
      have hstep1 : step (exec st cc) (Instr.BEQ rd 0 (whileExit cb.length))
          = (exec st cc).next := by simp only [step, if_neg hne]
      have hpc2 : (step (exec st cc) (Instr.BEQ rd 0 (whileExit cb.length))).pc.toNat
          = 4 * (q + cc.length + 1) := by
        rw [hstep1]
        show ((exec st cc).pc + 4).toNat = _
        rw [BitVec.toNat_add, show ((4 : BitVec 32)).toNat = 4 from by decide,
            Nat.mod_eq_of_lt (by omega)]
        omega
      -- ③ the BODY, by the derivation's own induction hypothesis
      have hatcb : codeAt image (q + cc.length + 1) cb := by
        have h1 := codeAt_append_right hat
        have h2 : codeAt image (q + cc.length + 1) (cb ++
            [Instr.BEQ 0 0 (whileBack cc.length cb.length)]) := by
          have := codeAt_append_right (a := [Instr.BEQ rd 0 (whileExit cb.length)]) h1
          simpa using this
        exact codeAt_append_left h2
      obtain ⟨st3, hr3, he3, hp3⟩ :=
        ihb hbody hcb hatcb
          (by intro i hi; rw [step_BEQ_get]; exact henc1 i hi) hpc2 (by omega)
      -- ④ the BACKWARD branch — the loop closes
      have hidx : (cc ++ Instr.BEQ rd 0 (whileExit cb.length) ::
          (cb ++ [Instr.BEQ 0 0 (whileBack cc.length cb.length)]))[cc.length + 1 + cb.length]?
          = some (Instr.BEQ 0 0 (whileBack cc.length cb.length)) := by
        rw [List.getElem?_append_right (by omega),
            show cc.length + 1 + cb.length - cc.length = cb.length + 1 from by omega]
        simp
      have hfetch2 : fetch image st3.pc
          = some (Instr.BEQ 0 0 (whileBack cc.length cb.length)) := by
        have h5 := fetch_codeAt hat (i := cc.length + 1 + cb.length)
          (by simp only [List.length_append, List.length_cons]; omega)
          (by rw [hp3]; omega)
        rw [h5, hidx]
      have hpc4 : (step st3 (Instr.BEQ 0 0 (whileBack cc.length cb.length))).pc.toNat
          = 4 * q :=
        SaltWorks.WhileScheme.step_back_taken cc.length cb.length q hbf.2
          (by rw [hp3]; omega) (by omega)
      -- ⑤ the RESIDUAL loop, by the other induction hypothesis, at the SAME position
      obtain ⟨st5, hr5, he5, hp5⟩ :=
        ihw hchk h hat (by intro i hi; rw [step_BEQ_get]; exact he3 i hi) hpc4
          (by rw [compileS_while_length]; omega)
      exact ⟨st5,
        Reaches.trans hr1 (Reaches.trans (Reaches.one hfetch1)
          (Reaches.trans hr3 (Reaches.trans (Reaches.one hfetch2) hr5))), he5, hp5⟩


#audit_axioms reaches_of_compileS_including_while

/-! ## THE END-TO-END CONTROLS — against GENERATED code, which is bar clause 2

`WhileScheme` §3's six configurations run `whileOf`, a HAND-BUILT block. The bar demanded
they be re-run "against generated code, not against `whileOf`", and this is that: a SOURCE
program, compiled by `compileS`, executed by the machine. -/

/-- `let x = 0 in while x < 3 do x := x + 1` — a source loop, compiled by the real emitter. -/
def wProg : Stmt :=
  .letmut 0 .i32 (.const 0)
    (.while (.slt (.var 0) (.const 3)) (.assign 0 (.add (.var 0) (.const 1))))

/-- ⭐⭐⭐ **THE EMITTER'S OWN OUTPUT RUNS THE LOOP AND HALTS.** Eleven instructions; the
counter reaches 3; the `pc` lands exactly past the image; and the state is STATIONARY there,
which is the halt check `WhileScheme` §3 made a clause of the bar because two of its three
mutants fail only by diverging. -/
theorem wProg_compiles_and_loops :
    (compileS regCanonical 16 [] wProg).map (fun c =>
      (c.length,
       ((runFor 200 c St.init).get 1).toNat,
       ((runFor 200 c St.init).pc.toNat == 4 * c.length),
       (runFor 200 c St.init).pc == (runFor 201 c St.init).pc))
      = some (11, 3, true, true) := by
  decide +kernel

/-- ⛔ **AND IT IS A LOOP, NOT STRAIGHT-LINE CODE THAT HAPPENS TO ANSWER 3.** At eight ticks
the counter is still `0` — the machine is mid-flight inside the loop. *Without this, the row
above is consistent with an emitter that unrolled, constant-folded, or ignored the body.* -/
theorem wProg_actually_iterates :
    (compileS regCanonical 16 [] wProg).map
      (fun c => ((runFor 8 c St.init).get 1).toNat) = some 0 := by
  decide +kernel

/-- ⭐⭐⭐ **A LOOP INSIDE A LOOP — the shape nothing in this corpus had ever compiled, and
the gap I publicly named as the one I would BET ON before measuring it.**

*`outer: while i < 3 do (inner: while k < 2 do k := k+1); i := i+1` — the inner loop drains
on the first outer pass and is false thereafter, so `i = 3` and `k = 2`.*

🔑 ***THIS IS WHY IT WORKS, AND IT IS NOT LUCK: `reaches_of_compileS_including_while`'s
`whileT` case takes `cb` from `compileS` of an ARBITRARY body and reasons from `cb.length`.
It never asks what produced that block.*** *So a compiled sub-block — including another
loop — is already inside the theorem's scope; this control CONFIRMS the theorem rather than
extending it, which is the honest way round.* -/
def pNested : Stmt :=
  .letmut 0 .i32 (.const 0)
    (.letmut 1 .i32 (.const 0)
      (.while (.slt (.var 0) (.const 3))
        (.seq (.while (.slt (.var 1) (.const 2))
                (.assign 1 (.add (.var 1) (.const 1))))
              (.assign 0 (.add (.var 0) (.const 1))))))

theorem nested_loops_compile_and_run :
    (compileS regCanonical 16 [] pNested).map (fun c =>
      (c.length,
       ((runFor 400 c St.init).get 1).toNat,
       ((runFor 400 c St.init).get 2).toNat,
       ((runFor 400 c St.init).pc.toNat == 4 * c.length),
       ((runFor 400 c St.init).pc == (runFor 401 c St.init).pc)))
      = some (22, 3, 2, true, true) := by
  decide +kernel

/-- …and a `letmut` RE-BOUND on every iteration inside a loop body, which is the other way a
body stops being straight-line. -/
def pLetInLoop : Stmt :=
  .letmut 0 .i32 (.const 0)
    (.while (.slt (.var 0) (.const 3))
      (.letmut 1 .i32 (.const 7)
        (.assign 0 (.add (.var 0) (.const 1)))))

theorem letmut_in_loop_body_compiles_and_runs :
    (compileS regCanonical 16 [] pLetInLoop).map (fun c =>
      (c.length,
       ((runFor 400 c St.init).get 1).toNat,
       ((runFor 400 c St.init).pc == (runFor 401 c St.init).pc)))
      = some (13, 3, true) := by
  decide +kernel

#audit_axioms wProg
#audit_axioms wProg_compiles_and_loops wProg_actually_iterates
#audit_axioms pNested pLetInLoop
#audit_axioms nested_loops_compile_and_run letmut_in_loop_body_compiles_and_runs

end SaltWorks.WhileSim
