# PHASE 3 — the cross-boundary patch request for `SaltWorks/Stack/Program.lean`

**From:** COMPILER seat · **To:** MATH seat (or whoever holds `SaltWorks/Stack/**`)
**Raised:** 2026-08-08 13:54, re-tiered 14:0x · **Status when written:** open

## Why this is a FILE and not just a bus post

It was a bus post first (13:54). Then math banked at a seam and rebooted, and a
successor re-reads its BANK, not nine thousand bus lines. Two of today's laws say
the same thing from different sides — *durable is not delivered*, and
*bus-resident fixes die at reboot* — so the payload lives here, in the repo, and
the bus carries only a pointer to it. **If you are math's successor and found this
from a one-line bus reference: this is the whole request; nothing else is owed to
you verbally.**

## The situation in four lines

Phase 3 re-cuts the ALU output select from `(asOps, asSelBits, asPad) = (10, 4, 16)`
to the ruled `(3, 2, 4)`. Compiler's side is **landed and green**:

| commit | what |
|---|---|
| `1d9e7d6` | EXPAND — consumers repointed off the numeral-bound bridge, statement shapes preserved |
| `52c51e5` | CONTRACT — the eleven-theorem numeral-bound ladder DELETED, kernel census clean, `EXIT=0`, 8657 jobs |

**The constant flip itself is NOT committed.** It is saved reappliable at
`${LOCAL_SEAT}/PHASE3-FLIP-compiler-1349.patch` (44 lines: `asOps 10→3`,
`asPad 16→4`, `asSelBits 4→2`, and `GSCount.gate_count_aluSelect`'s numeral
`1445→291`). It was reverted so the shared tree would not sit red while this
request is open.

**Applying that patch leaves exactly one failing module: `Stack/Program.lean`** —
47 unique error sites (31 proof failures + 16 `#audit_axioms` catches of the
`sorryAx` those failures installed). That is this request.

## Two verdicts compiler still OWES, and cannot produce alone

`SelectCut32` and `C1Organ` are **UNREACHED**, not green: `SelectCut32.lean:7`
imports `Stack.Program`, so a failing `Program` masks both. Confirmed two ways —
`docs/compiler-census.py` (import-graph trichotomy) and silicon's independent
import-graph walk (13:56), same two modules. **They can only be measured after
`Program.lean` compiles at the ruled pair**, so the phase-3 census closes on that
landing, not on compiler's.

Compiler's kernel *predictions* for them (`ScratchP3CUT.lean`): `aluSelect_nIn`
`324 → 98`; `gate_saving` `1154 → 0`; `span_delta` `1380 → 0`; `C1Organ` flip-inert
(stated entirely against `rs*` names). ⚠️ Three of that file's six theorems were
refuted as tautologies by silicon at 14:01 and by compiler's own extension — the
surviving substantive ones are `p3c_control_today`, `p3c_nIn_dies`,
`p3c_nIn_becomes_slice`. Treat the rest as expectations, not results.

## ⚠️ This map is an AIMING map, not a coverage claim

The tiering below matches MIGPATCH's theorem NAMES against the failing declaration
names. Nothing here was built against the ruled constants. **Grep aims; the kernel
confirms.** Compiler has been the loudest seat on that distinction today and it
applies to this document.

## TIER 1 — ⭐ **NOT WORK. ALREADY LANDED, AND ALREADY PASSING AT THE RULED PAIR.**

**Corrected 14:29 after reading the census output properly. MIGLAND (`b5943f0`)
landed the parametric family into `Program.lean` before this request was raised —
in `section AluSelectParametric` / `…Sem` / `…Drive`, with the probe's prime
suffixes dropped.** My first draft of this table cited `ScratchMIGPATCH.lean`'s
probe names (`sem_aluSelect'`, `asDrive_eq''`, …), **which do not exist in the
file** — it would have sent math looking for theorems that had already shipped
under different names.

⭐ **And they do not merely exist — they SURVIVE THE FLIP, with positive evidence
from the same census build in which the module failed:**

```
✓ SaltWorks.Stack.Program.sem_aluSelect              [3 axioms]   :8986
✓ SaltWorks.Stack.Program.aluSelect_outs_eq          [1 axioms]   :8986
✓ SaltWorks.Stack.Program.asDrive_eq                 [1 axioms]   :8990
✓ SaltWorks.Stack.Program.asDrive_sel                [1 axioms]   :8990
✓ SaltWorks.Stack.Program.asDrive_res                [2 axioms]   :8990
✓ SaltWorks.Stack.Program.sem_aluSelect_drive        [3 axioms]   :8991
✓ SaltWorks.Stack.Program.aluSelect_word             [3 axioms]   :8991
✓ SaltWorks.Stack.Program.aluField_is_aluSelect_add  [3 axioms]   :8991
landed at :5827-:6088 — seeds asSelBits_pos/asOps_le_pad/asOps_pos, aluSelect_outs_eq,
sem_aluSelect :5906, gsSelOf_of_testBit :5928, asSelOf_of_testBit' :5947, the drive family
```

⇒ ***`sem_aluSelect` — unconditional semantics over all valuations and the single
most expensive theorem in the blast radius — is already parametric and already
clean at `(3,2)`.*** **These are ticks with axiom counts, not absences of errors:
the audit RAN on them and found no `sorryAx`.**

⚠️ **AND ONE INSTRUMENT TRAP ALMOST HID IT, worth recording because it will recur:**
`#audit_axioms` **aborts its own list at the first failure**, and `Program.lean` has
227 multi-name audit calls. At `:5958` the call is
`#audit_axioms sem_aluSelect_direct gsSelOf_ten sem_aluSelect` — the *old* twin
fails first, so `sem_aluSelect` was **NOT REACHED** on that line and its status read
as silence. Only the **duplicate** audit at `:8986` produced the tick. *A redundant
audit call saved the reading; without it "no tick" would have been indistinguishable
from "poisoned".*

⇒ **So the shape of this whole tier is expand-contract working one level up: the
OLD numeral-bound twins fail (`sem_aluSelect_direct`, `gsSelOf_ten`,
`asSelOf_of_testBit`) while their LANDED PARAMETRIC counterparts pass. TIER 1's
remaining work is RETIREMENT of the old twins, not authorship of new proofs.**

*(Compiler's standing word to land any further MIGPATCH material is unchanged:
verify the build, fire each negative control personally, math's authorship in the
commit message, report anything changed.)*

## TIER 2 — NOT covered: `Program.lean`'s own numeral-bound ladder

```
asOps_eq · asBase_eq · asPrev_0 · asPrev_0_val · asL_eq · asB_mono01 · asNot_lt
asPreGates_eq · asOneHot_eq · asOffEnv_eq · asSelOf_expand · run_asBit
:4878  "Not a definitional equality: asOps is not definitionally equal to 10"
```

Structurally identical to the eleven compiler deleted: each bridges an `as*`
constant to its OLD LITERAL, so the re-cut **falsifies** it rather than merely
unproving it. **Recommendation, from having just done it:** check whether each
exists only to reach the numerals. If so they retire *wholesale* against
`genSelect_eq_aluSelect` — eleven of compiler's cost zero re-proofs and the census
came back clean on the first build. Anything load-bearing elsewhere gets restated
parametrically instead.

## TIER 3 — the Cut-mutant family; compiler's sample-point fix transfers verbatim

```
aluSelectCut_gate_count : … = 1445                  decide: FALSE
aluSelectCut_passes_the_certificate · asMuxCut_site_exists
asSelectsOKCut 3 = true · asSelectsOKCut 9 = true   decide: FALSE   (:6178)
:6140  asMuxCut filter length = 1                   new asLevelWidth
```

`3` is a real operand at ten sources and the **first padding slot** at three; `9` is
far outside. Compiler moved its own to `asSelectsOK 0` and
`asSelectsOK (asOps - 1)` — flip-safe at every admissible pair, and `asOps - 1`
still elaborates to the point it always named (`1d9e7d6`). Two lines, same fix.

## TIER 4 — a duplicated definition body, worth a hard look

```
:6023  asSelectsOK 10 = (List.range 16).all fun sel ↦ asBit0 10 sel == decide (sel = 10)
:8989  asSelectsOK_of_lt
```

`Program.lean` **transcribes `asSelectsOK`'s body including the literal `16`** — the
old pad, duplicated across the seat boundary. Compiler changed the definition's `16`
to `asPad` in `1d9e7d6`; it stayed green only because `asPad` was still 16 then. A
hardcoded pad numeral was living in two files and **no pad guard could see either
copy, because neither is a constant** — `rsPad_eq_two_pow` and `asPad_two_pow` guard
a pad CONSTANT against its select width, which is a different thing.

## The landing shape (maestro's 13:26 ruling)

Expand-contract, every commit green, patch-to-owner, and *"the census closes only
when the THIRD file lands green."* So: math patches `Program.lean`, compiler
reapplies the flip patch, and the joint landing is verified as below.

**THE EXACT INVOCATIONS — published rather than described, because a named
instrument with an unnamed invocation is how a check gets skipped or mis-run:**

```bash
cd ~/projects/claude/saltworks

# 1. the flip patch must still apply — RE-CHECK, do not cite an earlier check.
#    (It applied cleanly at 14:19; any later edit near AluSelect.lean:54-65
#     invalidates that silently.)
git apply --check ${LOCAL_SEAT}/PHASE3-FLIP-compiler-1349.patch
git apply         ${LOCAL_SEAT}/PHASE3-FLIP-compiler-1349.patch

# 2. the build. NEVER PIPE IT — $? after a pipe is the tail's status, and it
#    fails in the reassuring direction. Redirect, then read the EXIT text.
/Users/jyh/projects/claude/saltbuild.sh > /tmp/joint.txt 2>&1
grep 'saltbuild EXIT' /tmp/joint.txt          # must read EXIT=0

# 3. the trichotomy. Same rule: unpiped, and read the rc.
python3 docs/compiler-census.py /tmp/joint.txt
#    PASS bar: FAIL 0 · UNREACHED 0 · PASS = all tracked modules
#    rc: 0 on a clean run, 2 on misuse (bare call / missing file)
```

⚠️ **`UNREACHED 0` is the load-bearing half, not `FAIL 0`.** A build can report no
errors while modules behind a failure were never elaborated — that is how
`SelectCut32` and `C1Organ` read as green in the 13:49 census when neither had run.
**This is the first run in which those two get real verdicts rather than masked
ones**, and the trichotomy is what proves it.

📌 *Both "never pipe" notes above are there because this seat piped `saltbuild.sh`
once and piped the census tool once, in the same session, having banked the law.
The wrapper's own EXIT text caught the first; the second produced two bogus `rc=0`
readings that briefly looked like a defect in the tool.*
