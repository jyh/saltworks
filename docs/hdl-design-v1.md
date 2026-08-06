# LEG 2 DESIGN FREEZE v1 — the verified circuit compiler (seat: compiler-acct)
### 2026-08-06, Fable (Sancho). STATUS: frozen pending the seat's own
### refuter pass (your FIRST act — attack this doc before building).

## The object
A deep-embedded combinational circuit language in Lean, a semantics,
an optimizer, and TWO backends — with the THEOREMS that make it a
verified compiler:

  Circ : the syntax. Gate-level: input wires, const, not/and/or/xor,
         shared subterms (let-bound nets — a DAG, not a tree).
         Width-indexed buses as `Vector` of nets. Combinational ONLY
         in v1 (sequential = v2, not this fortnight's promise).
  sem  : Circ → (inputs → Bool outputs). The meaning. Total.
  opt  : Circ → Circ  (constant folding, dead-net elim — small but real)
  emitV : Circ → Verilog string   [UNTRUSTED by design — see leg 3]
  emitN : Circ → the netlist normal form leg 3's checker consumes

## The theorems (the deliverables, in order)
  T1  opt_sem   : sem (opt c) = sem c              (the verified optimizer)
  T2  emitN_sem : the normal form's evaluator agrees with sem
  T3  the executable-certificate suite: concrete circuits evaluated by
      `decide +kernel` — the "test that is proved" genre, N≤16-bit
      input spaces per module (measured law: 2^16 ≈ 12 s, 2^8 instant)
  T4  banyan_circ : the Banyan fabric AS a Circ, + proof its sem
      realizes `line`-routing (ties leg 2 to leg 3a's theorem)

## What is deliberately NOT claimed
- emitV (the Verilog printer) is UNTRUSTED — stated loudly in README.
  Leg 3 closes the loop by importing the SYNTHESIZED netlist back and
  checking equivalence; a printer bug is CAUGHT downstream, not trusted.
- No sequential logic in v1. No timing. Say so.

## Iron rules
salt's: no sorry / no native_decide / no new axioms; #audit_axioms on
every theorem (SaltWorks/Tactic/AuditAxioms.lean, already in-repo);
`decide +kernel` never bare decide; A/B/C classification before
attempts; 3-attempt budget then flag in docs/LEDGER.md; bv_decide
ONLY as a dev accelerant, never in a shipped proof (JYH-ruled 8/6).

## Files: SaltWorks/HDL/{Syntax,Sem,Opt,EmitV,EmitN,Certs,Banyan}.lean
## Refuter kill-checks for your opening pass
R1 is the DAG/let representation right for both sem-reasoning AND
   emission, or does proof pain force a different carrier? (compare:
   plain exprs + hash-consing later)
R2 does T2's normal form match what leg 3's importer (Silicon design
   doc §importer) actually consumes? Read their doc — the SEAM is the
   risk, agree the interface BEFORE building.
R3 is Vector-of-nets the right bus type for kernel-decide at 2^16?
R4 sp1-lean failure modes: vacuous hypotheses, wrong-width semantics,
   missing theorems — audit MY statements above for all three.

## ADDENDUM (Council I, 8/6) — ruled additions
- T5 THE FUNGIBILITY EXHIBIT: one banyan-router spec, ≥3 deliberately
  different implementations (iterative/unrolled/re-encoded), each
  proved equivalent to the SAME spec by decide +kernel. The README
  line: the certificate outlives every implementation.
- FRAMING (the seam doctrine, salt triple-campaign §10): this leg is
  spectrum-point 1 (amortized); leg 3 is point 2 (per-instance);
  present them as ONE doctrine, not two demos.
- Week-2 stretch (separate freeze to come): mini-language → RV32I
  codegen w/ simulation proof — THE TOWER's keystone.

## ADDENDUM 2 (8/6, bit-serial ruling): v1 gains a MINIMAL sequential
extension — registers + cycle semantics — scoped to the bit-serial
switch element (see silicon-design-v1 Addendum 1). Seam rule: agree
the sequential interface with the Silicon seat on the bus first.
