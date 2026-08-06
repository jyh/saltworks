# LEG 2 — REFUTER VERDICTS on `docs/hdl-design-v1.md`
### 2026-08-06, the HDL seat (compiler-acct). The seat's first act, per the freeze.
### Method: 6 independent attacks (R1-R4 + SEQ + HYGIENE), each then
### COUNTER-attacked by a hostile adversary instructed to kill it, plus a
### completeness critic asking what all six missed. 13 agents, 0 errors.
### Every load-bearing claim below was re-verified by this seat first-hand.

## 0. THE HEADLINE

**The freeze is sound in intent and wrong in three of its four engineering
choices, and the reason is that it prices the wrong axis.** R1's counter put it
best by killing its own refuter: the carrier syntax is worth ~2x, the
environment representation ~2x, and the EVALUATION STRATEGY ~10^3-10^4x. The
freeze legislates the first (`Vector` of nets), never names the second, and does
not know the third exists.

The strategy that supersedes it — **bit-slicing**, carrying each net's whole
truth table as one `Nat` — was found INDEPENDENTLY and within the same hour by
this panel's R1 and R3 lanes and by the Silicon seat (FLEET.md 09:31). Three
derivations, one answer, is the strongest evidence this pass produced.

## 1. VERDICTS

| Kill-check | Verdict | The one sentence |
|---|---|---|
| R1 representation | **SURVIVES-AMENDED** | Carrier decided on an axis the freeze never names; the DAG rationale is vindicated, the `Vector` ruling is not. |
| R2 the seam | **KILLED as written, CONVERGED in flight** | T2 had no referent; both seats independently reached the same answer while the pass ran, and the landed version has one fatal-but-small defect (§3). |
| R3 `Vector` at 2^16 | **KILLED — wrong question** | The enumerate-the-input-space architecture is obsolete; 2^26 configurations certify in ~240 ms. |
| R4 sp1-lean modes | **SURVIVES-AMENDED** | `banyan_selfrouting` is genuinely non-vacuous and 3-axiom clean; but T1/T2/T5 as written are each satisfied by a one-line trivial witness, and T4 cannot be stated against the declared `sem` at all. |
| SEQ (Addendum 2) | **SURVIVES-AMENDED** | The sequential extension needs ZERO new `Circ` constructors — but the FSM it is scoped to is specified wrong, and the committed RTL has a live routing bug (§4). |
| HYGIENE | **SURVIVES-AMENDED** | Three of the four artifacts the "Iron rules" paragraph depends on do not exist, and the whole iron-rule stack passes a certificate that proves nothing. |

## 2. WHAT I GOT WRONG — retracted before anything else

I posted to FLEET.md at 09:30 that the environment representation was worth
**≥100x** (`Nat` bitmask vs `List Bool`, 5.5 s vs >540 s). **That number was an
artifact of my own probe.** My list version extended the environment with
`env ++ [v]` — an O(n) append per gate — so I measured my own quadratic append
and attributed it to lists. With a PREPEND list, same circuit, same space, same
access pattern: **2.0x**. Withdrawn; the counter-refuter that killed it was right.

**The corrected rule is sharper, and it bites the artifact that is already
landed.** The rule is not "never `List`" — it is **never an append-extended
environment**. `SaltWorks/Silicon/Equiv/BitSliced.lean:88,:107` builds both
evaluators as `env ++ [step … g]` with `List.getD` reads, so **both landed
evaluators are O(g²) by construction** — visible in the source, not merely
measured. Both bit-slice write-ups published a LINEAR gate law; the measured
curve is g^2 (117 nets/2^16 = 301 ms against 217 nets = 1.11 s, 3.7x for 2x
gates). At D4's stated 1299 gates the linear law predicts ~6.6 s and the truth is
~40 s. The fix is one line (`Array`, or cons-and-reverse) and it should land
before the law is written into any document.

This is the pass's own best argument for the adversarial structure: the
refuter's headline number and the seat's bus post were the same error, and only
the counter-refuter caught it.

## 3. THE SEAM (R2) — converged, with one defect that must be repaired first

**Where it converged.** The seam question is settled and both seats agree,
having got there separately: the importer emits **DATA** (a `List Gate`), not
generated `def`s; evaluation is **bit-sliced**; and the reflection lemma
(sliced ⟺ pointwise) is **proved once, generically, by induction over the gate
list** — which is precisely why data beats code generation, since a generated
`def` cannot be inducted over and would force a per-design obligation. That is
the amortization the seam doctrine tells us to buy.

**The defect — verified first-hand against the landed file** (probe
`kathy-seam-check.lean`, `saltbuild EXIT=0`, all six theorems `[propext]`):

`eq_of_sliced_eq`'s hypothesis is `runS W cols [] gs = runS W cols [] hs` —
equality of the **whole net environment**, every internal net. `Netlist :=
List Gate` carries no output list and `Agree` requires equal lengths. Three
correct NAND implementations:

```
nandA = [inp 0, inp 1, and 0 1, not 2]         runS = [10, 12, 8, 7]
nandC = [inp 1, inp 0, and 0 1, not 2]         runS = [12, 10, 8, 7]   -- same gate count
nandB = [inp 0, inp 1, not 0, not 1, or 2 3]   runS = [10, 12, 5, 3, 7] -- De Morgan
```

Output net is **7** in all three — the same Boolean function — yet
`hyp_false_AC` and `hyp_false_AB` are both PROVED. The hypothesis is satisfiable
essentially only when two netlists are net-for-net identical. **So it cannot
state T5** (≥3 deliberately different implementations of one spec — the
Council-ruled headline of this leg), **nor T2, nor leg 3's own D3** (hand-written
spec against synthesized netlist).

**The stone is good; only the handle is wrong.** `reflect` is exactly right and
should be kept. What is missing is an output list on the netlist and a corollary
comparing only output nets. Demonstrated in the same probe:
`slicedOuts W cols gs outs := outs.map (fun k => (runS W cols [] gs).getD k 0)`,
after which `slicedOuts .. nandA [3] = slicedOuts .. nandC [3]` and
`= slicedOuts .. nandB [4]` both discharge by `decide +kernel`, `[propext]`.
~10 lines, not a redesign.

**Three seam facts neither freeze records, measured on REAL artifacts.** Three
genuine TTSKY26c submissions on this machine (`/private/tmp/ttsub/*/tt_submission/*.v`):

| | modules | cell instances | distinct cell types |
|---|---|---|---|
| asaad | 1 | 4220 | 15 |
| obstacle | 1 | 4645 | 13 |
| sub | 1 | 5344 | **68** |

- **The flow FLATTENS.** One module each. "Equivalence per module by
  `decide +kernel`" (silicon-design-v1:14-16) has no modules left to be per, and
  no document states an alternative decomposition. This is the largest unpriced
  item in either freeze.
- **1299 gates is off by ~4x** against a real tile.
- **"~30 one-line cell models"** is right in the median, wrong in the tail: one
  real submission needs 68.

## 4. THE SEQUENTIAL LEG (SEQ) — a live bug in the committed RTL

The good news first: the extension is genuinely minimal. It needs **zero new
`Circ` constructors** — a Mealy record over two combinational `Circ`s
(next-state and output) suffices, so the combinational core is not disturbed.

**The bug.** `SaltWorks/Silicon/RTL/bitserial_switch.v:25-26`:

```verilog
assign out0 = (sel0 == 1'b0) ? in0 : in1;
assign out1 = (sel1 == 1'b1) ? in1 : in0;
```

The element is correct whenever both ports are active with differing
destination bits — the `no_conflict` regime — and I confirmed both those cases
pass. **It is wrong when a port is IDLE**, and `banyan_selfrouting` does not
exclude that: `no_conflict` gives `Set.InjOn` over `Set.Iio n`, constraining the
**active** lines only. An idle port 0 leaves `sel0 = 0`, and `out0` then takes
`in0` unconditionally — so an active packet on `in1` bound for `out0` is
**dropped, and `out0` carries the idle wire**. Enumerated: exactly this case
fails, and it is one-sided (`out0` prefers `in0`; `out1` prefers `in1`).

**The fix is a frame-format decision, not a logic patch.** The element cannot
distinguish "idle" from "destination bit 0" because nothing in the frame says
so. The classical answer, and the one the 1988 design's own framing implies, is
a **leading ACTIVITY bit** ahead of the address bits, with the routing gated on
it. That must be decided before D3.5's refinement statement is written, because
the hypothesis "sources concentrated" is exactly what makes idle ports possible
at interior stages.

The corollary for the proof: **the no-conflict hypothesis must appear in the
statement.** Conflict LOGIC is unnecessary under sorted+concentrated traffic;
the conflict HYPOTHESIS is not optional, and an FSM certificate that never
exercises the conflict path while claiming to refine `line` is the sp1-lean
failure mode exactly.

## 5. R4 — the vacuity audit, turned on our own claims

**The landed theorem holds up.** `banyan_selfrouting` is non-vacuous (a witness
at k=3, n=4 typechecks), its hypotheses are used, and it is genuinely 3-axiom
clean. Three qualifications belong in the README rather than being discovered by
a reader:

- **Conjunct 3** (`∀ s, line 0 s (dest s) = dest s`) holds for every `dest`, for
  ALL `s`, with zero hypotheses — it is `line 0 = d` by definition. It inflates
  the apparent content of a three-conjunct theorem.
- **At full load** (n = 2^k) the hypotheses force `dest = id`, and the conclusion
  degenerates to `Set.InjOn id`. The theorem's content lives at partial load.
- **No object in the repo means "switch", "link", or "network".** Those words
  occur only in docstrings. The theorem is about a `line` function; calling it
  "no internal link conflict anywhere in the network" is an interpretation, and
  interpretations are what the sp1-lean audit convicted.

**On our own five theorems.** T1, T2 and T5 as stated are each satisfied by a
one-line trivial witness (`opt = id`; `emitN` = relabelling; three
alpha-renamings). That is true of every extensional correctness statement and is
not fatal — but it means **none of the three is a deliverable until it carries a
non-triviality exhibit**: a certificate that `opt` actually fires and shrinks
something, and gate counts PRINTED for each T5 implementation so "deliberately
different" is checkable rather than asserted.

**T4 cannot be stated against the declared `sem`.** `sem c : inputs → Bool
outputs` exposes only the fabric's output ports — that is stage boundary m = 0,
where `line 0 s d = d` holds unconditionally. The routing content of
`banyan_selfrouting` lives at the INTERIOR boundaries, which `sem` cannot see.
T4 needs an occupancy-at-stage-m statement, and the freeze's `sem` type must
widen or T4 must be stated against a different observation function. This is the
single most important correction to the theorem list.

**T3's third vacuity mode, CONFIRMED and enlarged by its adversary: port-order
blindness.** A certificate over a commutative module passes unchanged with its
input buses swapped. The repo's first module is a comparator — commutative in
exactly the wrong way. Every certificate must pin port ORDER, not just port
count.

## 6. HYGIENE — the rules cannot fire

- `docs/LEDGER.md`, the A/B/C classification (which is in fact A/B/C/**D**), and
  the README that "loudly" disclaims `emitV` **do not exist in this repo**.
- **`#audit_axioms` cannot fire on anything under `SaltWorks/HDL/`** because
  nothing there is in the build graph — and as of this writing neither is the
  entire landed Silicon leg. `SaltWorks.lean` imports only
  `SaltWorks.Banyan.SelfRouting`; the green build compiles one file.
  **import owed: SaltWorks.Silicon.Equiv.{BitSliced,Columns},
  SaltWorks.Silicon.Cells.Sky130, SaltWorks.Tactic.AuditAxioms,
  SaltWorks.Banyan.Facade.**
- `SaltWorks/Banyan/Facade.lean` proves `testBit_line` about its own duplicate
  `ProbeFacade.line`, not about `SaltWorks.Banyan.line`. The bit-routing facade
  — the public-facing reading of the whole result — does not currently connect
  to the landed theorem. (Maestro-owned; reported, not touched.)
- **The whole iron-rule stack passes a vacuous certificate.** No `sorry`, no
  `native_decide`, `decide +kernel`, `#audit_axioms` green — on a theorem with
  contradictory hypotheses. The rules audit the PROOF; nothing audits the
  STATEMENT. That gap is the campaign's own advertised failure mode.

## 7. AMENDMENTS TO THE FREEZE (ready to apply)

1. **Strike** "measured law: 2^16 ≈ 12 s, 2^8 instant" (L22-24). It is the cost
   of the QUANTIFIER over a trivial predicate, not of a circuit. Replace with the
   two-regime law: pointwise ~10^4 gate-evaluations/s; bit-sliced, the input
   space is nearly free and the cost is the gate count — currently **quadratic**
   in it, and linear once the append is repaired.
2. **Strike** "Combinational ONLY in v1" (L12-13) and "No sequential logic in
   v1. Say so." (L32). Both are dead text under the JYH bit-serial ruling; the
   frozen body still asserts the opposite of its own Addendum 2.
3. **Amend L12**: keep `Vector` for buses (syntax, and free — measured: reading
   8 bus bits costs +1.0% over reading 1), but NAME the runtime environment and
   forbid append-extension.
4. **Amend T1** to carry its non-triviality exhibit, and **amend T4** to an
   occupancy statement at stage m (§5).
5. **Add** to the file list: a home for the shared netlist type and for `Wf`.
   Neither exists in `{Syntax,Sem,Opt,EmitV,EmitN,Certs,Banyan}`.
6. **Record** the flattening fact and its consequence for decomposition (§3).

## 8. WHAT THIS SEAT OWES

The fair criticism from the completeness critic, accepted without argument:
**leg 2 has produced a great deal of refutation and zero Lean.**
`SaltWorks/HDL/` does not exist. Syntax and Sem land next, against the corrected
carrier, and this seat runs no more exhaustive sweeps to get there — bit-slicing
is the reason it no longer needs to.

One ruling is owed by the maestro before `EmitN` can be written by anyone: the
shared netlist type belongs to **neither** writer slot under `docs/SEATS.md`, and
both seats have been filling that vacuum privately. Requested on the bus at
10:35.
