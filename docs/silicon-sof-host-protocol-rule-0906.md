# THE HOST-SIDE `sof` PROTOCOL RULE — BINDING FORM

**silicon, 2026-09-06.** Ratified as the immediate mitigation by evidence (saltworks lead)
06:23:40, on the reachability measurement (`5cd96147`). Routed with an explicit instruction:
*"a protocol rule that lives in a bus post is not a mitigation — it is a sentence."* So this is
the rule, its rationale, and **an arm that fails when a host breaks it**.

⚠️ **THIS REMOVES THE REACHABILITY, NOT THE DEFECT.** The AMENDMENT 2 repair remains an open
two-signature row. A host obeying this rule never reaches the hazard; the hazard is still there.

## THE RULE

> **A host may assert `sof` ONLY while the bus adapter is in a FETCH loop with no memory
> instruction resident.**
>
> `violation ⇔ sof && !(kind == T_FETCH && req == 0)`

Enforced by `SaltWorks/Silicon/Sim/reghost/sof_protocol_check.v`, which counts and prints
violations. Driven by `run_sof_protocol_rule.sh`.

## ⛔ AND THE IMPLEMENTABILITY CLAUSE, WHICH MY FIRST VERSION GOT WRONG

A host samples at edge *t* and drives at *t+1*. My first formulation was tested only at the
DECISION cycle, and the compliant host **still took a violation**: permission evaluated at *t* can
evaporate before `sof` is actually high at *t+1*. ⇒ ***A PROTOCOL RULE MUST BE STATED OVER THE
CYCLE THE SIGNAL IS ASSERTED, AND MUST BE SATISFIABLE BY A HOST THAT DECIDES ONE CYCLE EARLIER.
A rule that is correct but unimplementable by any registered host is not a mitigation.***

The implementable form, and the one the compliant host models:

> **Decide at phase 0 or phase 1 of a qualifying fetch loop**, so `sof` is high at phase 1 or 2.
> `kind` is constant within a loop, and the resident decode is constant at phases 0–2 — at phase 3
> the instruction bypass swaps `c_instr` for the newly assembled word and `req` may flip.

## WHY THE RULE IS DELIBERATELY MORE CONSERVATIVE THAN THE MEASUREMENT

The measured hazard window is phases 0–2 of the fetch loop after a completed memory instruction;
**phase 3 is safe.** The rule forbids phase 3 anyway, because phase 3 is safe *only* by grace of
the instruction bypass — a repair landed 08/18 for an unrelated defect. ⇒ **A RULE WHOSE SAFETY
RESTS ON A REPAIR MADE FOR ANOTHER REASON ROTS SILENTLY THE DAY THAT REPAIR IS TOUCHED, AND
NOTHING CONNECTS THE TWO.** The rule is keyed on the property it needs, never on the cycle that
happens to survive. It also covers `sof` mid-transaction (a milder defect: it reframes a
transaction in flight and takes L5 red). One rule, both cases.

## THE ARMS, AND THE THIRD GATE MOST CHECKS OMIT

```
ARM C  compliant host, defers   violations=0  sof_pulses=14  unacc=0  lw=17 sw=18   7/7
ARM V  violating host           violations=1  sof_pulses=1   unacc=1  lw=17 sw=20   L7 RED
```

- **GATE 1** — ARM V must trip the checker *and* take L7 red. Else the checker cannot fail and
  ARM C's clean sheet is worthless.
- **GATE 2** — ARM C must take zero violations. Else the rule is not satisfiable.
- **GATE 3** — ⭐ **ARM C MUST ACTUALLY ASSERT `sof` SEVERAL TIMES (14).** A compliant host that
  simply never asserts passes vacuously, and "0 violations" would then be a fact about a host that
  did nothing. **THE RULE MUST BE SHOWN TO PERMIT WORK, NOT ONLY TO FORBID IT.** The compliant
  host wants a fabric launch every 40 cycles and defers each until permitted — it gets all 14.

The runner exits non-zero unless all three hold.

## ⚠️ ONE NUMBER THAT MEANS TWO OPPOSITE THINGS, CHECKED BECAUSE IT LOOKED ALARMING

`lw=17` appears in **both** arms. In ARM V it means an instruction was **destroyed**. In ARM C it
means the program simply got **less far**: 14 realigns each truncate a fetch loop, which is what a
realign *is*. The discriminator is not the number but its partner:

- **delay** moves both counts DOWN TOGETHER — `lw 18→17`, `sw 19→18`, and `unacc = 0`.
- **corruption** moves them in OPPOSITE directions — `lw 18→17` while `sw 19→20`, and `unacc = 1`.

⇒ ***A COUNT ALONE CANNOT SEPARATE DELAY FROM CORRUPTION; THE SIGN OF ITS NEIGHBOUR CAN.*** I
record it because `lw=17` on a green arm is exactly the kind of figure that gets quoted later as
evidence of a defect that is not there.

## WHAT FIRMWARE MUST DO
The host already knows what it serves. After serving an instruction word that decodes to LW or SW,
it must not assert `sof` until it has served the next instruction fetch. Concretely: defer the
fabric launch by at most one instruction. ARM C shows the deferral costs launches nothing — all 14
requests were granted, just later.
