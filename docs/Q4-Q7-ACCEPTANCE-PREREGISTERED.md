# Q4/Q7 — THE ACCEPTANCE BAR, PRE-REGISTERED BEFORE THE RETURNS ARE READ

**Stamped `2026-08-20T13:01:37-0700`, tree at `f8b58ea`.** Seven executors are in flight; **no return has been read.**
This file exists because I am the seat that dispatched them, and a builder is a disqualified
auditor: a bar written after seeing the work is fitted to the work.

§3 says an executor result is a **CANDIDATE, never a landing**. This is what a candidate must
clear. Any row failing = the candidate does not land; it becomes a WALL report or a re-dispatch.

## The mechanical gates — necessary, and the easy half

1. **Builds via bare `../saltbuild.sh`, judged on the literal `saltbuild EXIT=0`.** Never piped:
   `$?` after a pipe is the last stage's status.
2. **`#audit_axioms` closure ⊆ `[propext, Classical.choice, Quot.sound]`**, read as TICKS.
   *The call ABORTS its list at the first failure, so a name that never printed reads as clean —
   audit one name per call and count the ticks against the names I expected.*
3. **No `sorry`, no `native_decide`, no new axiom.** ⚠️ A failed tactic ERRORS *and fills the
   hole*, so hygiene is EXIT=0 **plus** a clean audit — never a grep for "sorry".
4. **Zero warnings introduced**, against the count read BEFORE the work.

## ⛔ The gates that actually decide it — where I expect to reject

5. **THE STATEMENT MUST SAY WHAT THE BRIEF ASKED.** Grep the brief's nouns in the *statement*,
   not the name or the docstring. A FREE parameter beside a FIXED one certifies only an instance.
6. **THE HYPOTHESES MUST BE SATISFIABLE.** A theorem can be true, well-scoped and **vacuous on
   all real traffic**. For each candidate: instantiate its hypotheses at a concrete witness and
   EVALUATE. Build, audit and adequacy are all blind to this.
7. **PLACEMENT IS NOT VALUE.** An `instOK`-shaped certificate says an organ sits where the σ puts
   it *in time*; it does not say the right WIRE feeds it. Two placements already fed `rs2` where
   ADDI needed the immediate with every `instOK` TRUE. Read the next organ.
8. **A NEGATIVE ARM MUST BE ABLE TO FAIL.** For Q7's non-writers and x0 rows especially: mutate
   the subject and confirm the verdict MOVES. A control whose fixture falls outside the
   instrument's window passes loudly and proves nothing.
9. **DID IT ALREADY EXIST?** A name-grep answers "is this IDENTIFIER taken", never "is this
   STATEMENT proved". Grep the CONCLUSION SHAPE. A re-proof of a landed lemma is not a return.
10. **SCOPE FENCE HELD:** non-memory classes only. Any candidate whose route needs a load or
    store to work is a WALL by construction, however green it builds.

## What I will NOT do

- **Not weaken a candidate to land it.** If it will not clear the bar as stated, it is a wall.
- **Not land seven at once.** Each candidate is built and audited on its own; a failing module
  masks every consumer downstream, so a green world build over the whole batch would not tell me
  which rows earned it.
- **Not treat "no `sorry` in the file" as evidence.** That is a file observation, not a result.
