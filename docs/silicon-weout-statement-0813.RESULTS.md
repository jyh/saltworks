# SILICON — THE we_out STATEMENT LAYER: RESULTS AND CONTROLS

**Authority:** helm night order, 2026-08-13 20:10:39 — *"Point the night at the
LW/SW front's statement layer: the we_out chain you measured end to end at
17:04, built forward on your own receipts."*

**Criterion pre-registered on the bus at 20:15:52, BEFORE the proof existed:**
*"the honest proof generalises those two nets rather than enumerating the
address space. That is a total statement, no subspace restriction. If it will
not carry, I will land the declared-subspace version and SAY it is one."*
⇒ **IT CARRIED. The landed theorem is total; no fallback was used.**

## WHAT LANDED

    SaltWorks/Silicon/Imported/DmemAddr8.lean       the datum (importer-generated)
    SaltWorks/Silicon/Equiv/DmemAddr8Suppress.lean  8 theorems
    reimport.sh                                     +1 datum: 5 of 8 now reproduce

`dmemAddr8_we_out_excludes_trap` — for EVERY input configuration, the emitted
netlist never raises `we_out` and `trap` together. This is the property
`dmem_addr8.v:59-65` had carried in PROSE since it was written: *"a trap that
raises a flag but still lets `we` through writes to a wrong word and then
reports an error — the isolation frame would be FALSE while the trap logic
looked correct."* It is the F4 bridge's RESPONSE relation — and this file
claims nothing about the CLASS LABEL, which the ruling says the RTL and the
kernel are *supposed* to disagree on.

## WHY IT WAS UNREACHABLE UNTIL TONIGHT — both halves are my own receipts

1. the netlist carrying `we_out` did not import (range grammar) — cured by call
   (4) option (b) at `61fcc74`.
2. the datum bound outputs BY ORDER ONLY, so `outs[3]` meant `we_out` by an
   argument no proof could read — cured by the name table at `cc32a96`.
   `dmemAddr8_we_out_is_index_3` now CHECKS that binding before it is used.

## THE COST WAS THE QUANTIFIER, NOT THE CIRCUIT (the seat's oldest defect)

    misaligned    net 34 ->  2 inputs      trap    net 72 -> 30 inputs
    out_of_range  net 69 -> 27 inputs      we_out  net 78 -> 31 inputs
    JOINT trap+we_out: 31 ⇒ 2^31 — exhaustive `decide +kernel` is out at any budget.

Both nets touch the 27 high address bits ONLY through net 69, so the proposition
is a tautology in THREE atoms. Nets 71 and 74 are DUPLICATE gates abc never
merged; rendering each as an expression in `ins` yields THE SAME 362 CHARACTERS,
which is how the shared atom is established by construction rather than asserted.

⛔ FOUR DEAD ENDS, RECORDED BECAUSE THE FIX IS INVISIBLE ONCE APPLIED:
    plain `simp` on the goal        unfolds fine, then splits into Prop thickets
    `rfl` shape lemmas             maxRecDepth FIRST, then whnf timeout
    maxHeartbeats 2M → 4M          2m20s, still red — brute force was the wrong road
    3 mentions of `dmemAddr8_env`  each mention re-runs the 79-gate netlist
⇒ WHAT WORKED: shape lemmas by `simp` (REWRITING, not whnf) with machine-generated
  right-hand sides, and the Bool core by `cases`, not `decide` (free variables).
  The first error printed was `maximum recursion depth`, and the heartbeat
  timeout underneath it was DOWNSTREAM — I spent two builds raising the wrong
  budget because I read the second error instead of the first.

## CONTROLS — a criterion never shown to fail has not been shown to discriminate

MUTATION: net 77 `.or 74 76` → `.or 76 76`, dropping the `(mis|oor)` term, so
`we_out` becomes `we_in && req`, ungated by the trap predicate.

    NC1  TRIPWIRE     mutate the netlist, shapes untouched
                      -> dmemAddr8_net78_eq RED (unsolved goals) and
                         #audit_axioms catches sorryAx                    FIRED
    NC2  DISCRIMINATION  regenerate the shapes to MATCH the mutant, so only the
                      PROPERTY can fail
                      -> dmemAddr8_we_out_excludes_trap RED, sorryAx caught FIRED
    NC2b IS THE MUTANT ACTUALLY BAD, or did my proof merely stop working?
                      Independent Python simulation of the same gates finds a
                      counterexample: byte_addr[0]=1 byte_addr[1]=1 req=1
                      we_in=1 -> we_out=1 AND trap=1.                     SHOWN
    CORROBORATION     the ORIGINAL netlist, same Python simulator (a mechanism
                      that is NOT Lean): 0 violations in 300,000 random +
                      256 directed vectors covering both `oor` polarities.
    RESTORATION       both files restored from backup and verified BYTE-IDENTICAL
                      by `cmp` before anything was committed.

## RECEIPTS

    saltbuild BARE (redirection, not a pipe — $? is saltbuild's own)  RC=0, EXIT=0
    3381 audited declarations corpus-wide; 8 new ones, 0-1 axioms each, no sorry
    ⚠️ the bare build REPLAYED this module, which proves the cache, not the kernel
    meas_build.sh (PATH form)   KERNEL-CHECKED under this hand, 4s, EXIT=0
    reimport.sh                 DmemAddr8 reproduces BYTE-FOR-BYTE; 5 of 8, debt named
    instrument_selftest         EXIT=0, 12 rows, every guard fired
    pinreset_controls           EXIT=0, 25 rows, 0 red

⚠️ ONE INVOCATION HAZARD MET IN PASSING, not repaired (law work is complete by
order): `sh pinreset_controls.sh` dies at line 265 on `diff <(...)` — process
substitution is bash, and the file's shebang is `#!/bin/bash`. It exits 2, but
only AFTER printing a run of ✅ rows, so a reader who checks the tail for red
rows and finds none reads a crash as a pass. Invoke it with `bash`.
