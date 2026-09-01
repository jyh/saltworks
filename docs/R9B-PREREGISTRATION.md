# R9b — PRE-REGISTRATION, WRITTEN BEFORE ANY LEAN

**Seat:** compiler. **Branch:** `compiler/r9b-restated-witness`, off master `1198af7`.
**Written:** 2026-08-31 17:47:24 PDT. **Authority:** the maestro's 08-31 17:39:57 standing law — *"R9b 'waits R10'
is a DATE, not a reason to sit: start R9b on a branch under your best reading of what R10 will
say (state the assumption in the branch's first commit)."*

⛔ **THIS FILE IS THE ASSUMPTION, AND IT IS WRITTEN TO BE WRONG CHEAPLY.** Every claim below
names which artifact dies if my reading of R10 is wrong. A pre-registration that cannot lose is
not one.

---

## §1 · MY READING OF R10 — STATED, NOT ASSUMED SILENTLY

§14's live table gives R10 three clauses. My reading of each, and what I am betting on:

```
R10 CLAUSE (§14, verbatim)              MY READING                        IF I AM WRONG
"bound stated in the units the          the cycle/step bound is           §3's claims are
 machine honors"                        expressed through stepsIn         UNAFFECTED — none
                                        (StallShape.lean:123), not by     of them mentions a
                                        a numeral                         bound at all
"no bare literal surviving the          the flagship moves from           §3 UNAFFECTED for the
 retired cycle=step identity"           CycleRealisesStepProj to the      same reason; §4's
                                        CycleRealisesStepOrStalls         POSITIVE half is the
                                        family (StallShape.lean:111)      half that depends on it
"the LW row's honest disposition        ⭐ THE ONE I AM ACTUALLY           §3 IS THE TEST OF THIS
 rides with it"                         BETTING ON: LW is disposed by     CLAUSE, and it is
                                        SCOPE — memory-touching words     designed to REFUTE my
                                        leave the kernel-backed claim     own reading if the
                                        (MemFree, Program.lean:1493)      disposition is a stall
                                        and ride at RUNG 1 — NOT by       instead. See §3.3.
                                        silence and NOT by a stall
```

⚠️ **THE HONEST SHAPE OF THE BET.** I am NOT betting that R10 picks any particular stall set,
scope predicate or bound. §3 is deliberately UNIVERSALLY QUANTIFIED over the part R10 owns, so
that R10's actual wording instantiates it rather than refutes it. **A refutation should kill one
instantiation, not the definition** — so the definition is the thing I am parameterising.

---

## §2 · WHAT IS ALREADY TRUE AT `1198af7`, RE-DERIVED, NOT RECALLED

```
C4Spec core                 FALSE   not_c4Spec_core_at_the_landed_witness (LwTrapRefuted)
RegDatapathOK               FALSE   regDatapathOK_is_false_at_the_LANDED_witness
the surviving witness       insL    C4Refuted.lean:293 — LW x1, x2, 4; NON-trapping
  prior x1                  = 4     sL = 2^66 ||| 2^34 ||| (wL.toNat * 2^1056), so x1 bit 2
  core writes x1 bit 3      TRUE    sel3_insL — the ADDRESS 4+4=8 = 0b1000 on the write bank
  ISA writes x1 bit 3       FALSE   isa3_insL — the loaded constant 0
stall arm reduces           Iff.rfl stallArm_reduces (StallShape.lean:133)
stall arm strictly extends  PROVED  stallArm_strictly_extends (StallShape.lean:156)
the bridge, contraposed     PROVED  not_C4Spec_of_not_cycleRealises (Certs/R9IdentityBridge)
```

---

## §3 · THE PRE-REGISTERED CLAIMS — R10-INDEPENDENT BY CONSTRUCTION

**These are what I will have built whatever R10 says. They are the negative half of R9b, and the
negative half is the half that does not need the ratified sentence to exist yet.**

### 3.1 — THE ARITHMETIC THAT DECIDES IT (stated BEFORE the proof, so it can be wrong)
At `insL` the core's new `x1` bit 3 is **set** (the address 8), the ISA's is **clear** (the
loaded 0), and **the PRIOR value's is also clear** (x1 = 4 = 0b100). ⇒ ***The core at `insL`
NEITHER REALISES THE STEP NOR HOLDS `(regs, pc)`.***

### 3.2 — CLAIM A (the load-bearing one)
```
∀ stalls : Env → Bool,  ¬ CycleRealisesStepOrStalls (cycOfCirc core nextW pad) seenWord stalls
```
**PASS BAR:** a kernel-checked theorem, universally quantified over `stalls`, `nextW` and
`pad`, `#audit_axioms` clean of `sorryAx`, `saltbuild EXIT=0`.
⇒ **NO CHOICE OF STALL SET RESCUES THE CORE.** R10 may declare any cycle a stall it likes; `insL`
fails whichever branch the declaration selects.

### 3.3 — CLAIM B, AND IT IS THE ONE THAT CAN REFUTE MY OWN READING OF R10
```
MemFree (seenWord insL)   ->   EXPECTED FALSE   (LW touches memory)
```
**PASS BAR:** kernel-checked, either way.
⭐ **THIS IS A DIFFERENTIAL, NOT A CONFIRMATION.** If it comes out **FALSE** as I expect, then
claim A's witness lies OUTSIDE any memory-free scope, and R10's LW disposition **must** be a
scope restriction (or a real memory-data input) — my §1 reading is supported. **If it comes out
TRUE, my §1 reading of the third clause is REFUTED**: a memory-free scope would not exclude the
witness, claim A would stand against the scoped sentence too, and R10 could not dispose LW by
scoping at all. **I will report that outcome in the same words if it happens.**

### 3.4 — MUST-BREAK CONTROLS (a claim with no failing arm is not tested)
```
C1  the IDEAL core must still SATISFY the restated predicate at the empty stall set
    (cycleRealisesStepProj_idealBits transports) — if it does not, my restatement is
    not a weakening of the landed one and the whole file is wrong
C2  the STALLED core (stalledBits) must be ADMITTED at stalls := fun _ => true and
    REFUTED at fun _ => false — if it is admitted at both, my predicate is degenerate
C3  claim A must FAIL to prove at a witness where the sides AGREE (bit 2, insL) —
    the harness must not be a blanket refuter
```

---

## §4 · WHAT I AM **NOT** CLAIMING TONIGHT, SAID NOW RATHER THAN DISCOVERED LATER

⛔ **The POSITIVE half of R9b — actually INHABITING the restated predicate for `core` on the
memory-free fragment — is NOT attempted on this branch and I am not going to imply that it is.**
It genuinely depends on R10's ratified wording (which scope, which bound), and it is the half the
rung's word *"inhabit it for the real circuit, not merely consume it"* is really about. What this
branch delivers is the half that R10 cannot move: **the proof that the LW obstruction is not
stall-shaped**, which is the fact R10's third clause has to be written around.

⛔ **I am not touching `issuance_markers.sh`** (live trial, n<20, to ~09/07).
⛔ **I am not re-dating any rung.** §14's table is the helm's.

## §5 · DISPOSITION
Green ⇒ merge to master. Red ⇒ abandon the branch and post the negative, which under the
17:39:57 law is an equally acceptable outcome. Either way the 09-04 word finds a draft, not a
sleeping seat.
