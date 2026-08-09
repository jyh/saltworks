# SLICE B — the ISA extension + the verified executive (block pair v1)
### Maestro-drafted 8/8 night. Status: DRAFT-UNTIL-REFUTED. Two blocks
### in one file because their seam IS the design: B-ISA lands first,
### B-EXEC states its invariants against B-ISA's total-transition
### spec. Captain-ratified roadmap (muster ruling ①/②): +LW/SW/JAL/
### JALR/BNE, ALU op-set UNCHANGED — the (3,2) select carries it;
### cooperative first; the −1,154 gates banked AT THE SELECT are the
### budget (evidence 20:04: a SELECT delta, verified 1445→291 exact;
### the whole-core net is UNVERIFIED — the corpus holds no whole-core
### total — silicon's one-line answer owed before the budget is spent
### as a system figure).
### PRECONDITIONS: phase 3+3b closed (constants at the ruled pair);
### the census at PASS/FAIL/UNREACHED/UNWIRED; compiler's night
### inventory may amend §B1. Scope audit: evidence 20:04,
### preconditions 3/3 verified.

## B-ISA — the datapath extension

B1. SCOPE: five new ops — LW, SW (the FIRST memory; a small SRAM or
   register-backed memory at Slice-B scale — silicon prices it in
   CELLS against the banked 1,154), JAL, JALR (the FIRST link
   register discipline), BNE (BEQ's dual — likely near-free against
   the existing compare). ALU op-set UNCHANGED (ruled): the (3,2)
   select carries the whole slice.
B2. THE SPEC FORM (the block's soul): the ISA becomes a
   TOTAL-TRANSITION function — every (state, instruction) pair steps,
   including every ill-formed case, by an explicit rule (trap,
   no-op, or defined wrap — CHOSEN, not inherited). Totality is what
   B-EXEC's invariants quantify over; partial specs are barred here
   the way c2 was barred at the muster (staging that cannot
   terminate against a ∀-spec).
B3. DECOMPOSITION: per-op semantics + encoder extension (the c1
   organ pattern, one theorem each, B-class) · the memory unit's
   certified organ (B/C — the one genuinely new datapath) · the
   total-transition wrapper theorem (B) · census + CELLS pricing at
   each landing (silicon's conveyor).
B4. TRAPS: address alignment/width at LW/SW (state the mask, prove
   the mask); JAL(R)'s link-then-jump ordering (a classic
   read-after-write hazard in the SPEC, not just the datapath);
   the memory organ must not silently widen the state the executive
   later quantifies over — its state enters the total-transition
   spec EXPLICITLY.

## B-EXEC — the verified executive

E1. SCOPE (cooperative v1): N tasks, each a Slice-B program; a YIELD
   convention (JAL to the executive's entry — no interrupts in v1);
   the executive selects the next runnable task round-robin.
E2. THE TWO INVARIANTS (stated on B-ISA's total-transition spec):
   - FAIRNESS: in any infinite run where every task yields
     infinitely often, every task steps infinitely often (the
     cooperative form; the preemptive form is v2, and needs the
     small-step/fuel semantics named in the language block §5).
   - ISOLATION: task i's registers-and-memory partition is untouched
     by task j's steps (j ≠ i) except through declared channels —
     stated as a frame theorem over the transition function. The
     partition is BY CONSTRUCTION (static memory ranges at Slice-B
     scale), so isolation is provable without an MMU — say so
     honestly; an MMU is a different artifact.
E3. DECOMPOSITION: the executive as a Slice-B PROGRAM (compiled by
   the language when ready — hand-assembled as the fallback, and the
   theorem is about the MACHINE CODE either way, so the language is
   an on-ramp, not a dependency) · the scheduler-step lemma ·
   fairness by induction on yield events · isolation as the frame
   lemma family.
E4. TRAPS: the executive's own state must live INSIDE the isolation
   story (it is task 0, not a ghost); yield-entry re-entrancy (the
   link register at nested entry — JAL's B4 trap arriving one level
   up); "runnable" must be total (a task that never becomes runnable
   is a fairness counterexample the spec must either exclude by
   hypothesis or handle by rule).

## SEQUENCING + GATES

B-ISA blocks draft-refute NOW; its waves after the language block's
slate (shared executor capacity, maestro's call). B-EXEC's statements
refine against B-ISA's landed spec; its waves after B-ISA closes.
The language's v2 (memory) lands in the same window as B-ISA — one
campaign, two files, per §B1.

## REFUTATION ASSIGNMENTS

- COMPILER: B1/B3 against the corpus (what the memory organ costs in
  the emitted path; BNE against the landed compare; the encoder
  extension against the c1 organ); E3's executive-as-program
  feasibility at Slice-B's op budget.
- SILICON: B1's memory pricing IN CELLS vs the banked 1,154; the
  tile question interaction (does Slice B still fit co-tenant?);
  B4's alignment mask at the RTL.
- MATH: B2's totality form (the trap/no-op/wrap trichotomy — is it
  exhaustive and is each arm satisfiable); E2's invariant statements
  (fairness's infinite-run quantification; isolation's frame form —
  the σ-strike lesson applies: no object stronger than the property).
- EVIDENCE: pre-register the Slice-B price criterion BEFORE any wave
  (the ④ pattern); the claim-scope audit on E2 (an "OS" this is not
  — the story must say executive, cooperative, and why that is still
  real).
