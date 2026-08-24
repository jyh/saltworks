# PORT-LIST NODUP — design block v1 (maestro, 2026-08-08)
### Status: DRAFT-UNTIL-REFUTED. The ⑦(2) muster deliverable (maestro-
### owed). Refutation assignments at the end; positive controls named.

## 0. THE HOLE, AS MEASURED (compiler, 8/8 morning; two fixtures)

> ⚖️ **2026-08-23 — the `- SEAT:` refutation rows in this doc are CLOSED** (council ruling 5).
> Live obligations migrated to `docs/QUEUE.md` §MIGRATED by object-liveness audit; rows below
> are HISTORY (ruling-#7 probes quote them verbatim — do not delete or edit them).

`Circ.wf` applies its nodup check to `c.gates.map Gate.out` — THE
GATES — and never to `c.outs` — THE PORT LIST. Kernel-verified: a
circuit may name the same net twice in its ports and pass `wf` AND
`ssa` (`adder32Dup`: sum[0] appended twice, both predicates true by
decide; replicated on `halfAdderLong`).

## 1. WHY LENGTH CLAUSES (①″) DO NOT ALREADY COVER THIS

①″ pins `outs.length`, which kills the APPEND-a-port impostor. It is
blind to the REPLACE-with-duplicate impostor: `[a,a,c,…]` has the same
length as `[a,b,c,…]`, passes every structural predicate, and passes a
sampled semantics cert whenever net a's value happens to match net b's
on the samples. Nodup is the clause that makes that impostor
unrepresentable. (Fourth sharpening of the criterion family: ①″
whole-list · ①‴ port axis · take-vs-drop · this.)

## 2. THE DESIGN — a NEW predicate, NOT a mutation of `wf`

⛔ REJECTED: strengthening `Circ.wf` in place. Every landed `wf`
theorem (elements, adders, genSelect's GENERAL wf, the organ suite)
would acquire a new proof obligation overnight; worse, the NAME `wf`
would silently change meaning under every theorem that cites it —
the instrument-vs-object sin, enacted in a predicate. `wf` keeps
meaning what it has always meant.

✅ ADOPTED:
```
def Circ.portsNodup (c : Circ) : Prop := c.outs.Nodup
```
- ACCEPTANCE BAR: new clause ①⁵ — every NEW block certifies
  `portsNodup`, route DIFFERENTIATED (math's ⑦(2) pass 13:42,
  kernel-backed):
  · generated lists: nodup lemmas — `genSelect_portsNodup (n b)
    (hb : 0 < b)` via `List.nodup_range` (core, `n` IMPLICIT) +
    `List.Nodup.map_on`. THE hb IS LOAD-BEARING: at b = 0 the port
    map's factor `gsPad b − 1` is zero, the map goes CONSTANT, and
    `¬ (genSelect 10 0).outs.Nodup` is kernel-proved — the drafted
    hypothesis-free form was FALSE (four boundary controls pass:
    b=0 is a boundary defect, not a broken definition). The (3,2)
    re-cut inherits free — no `as*` constant enters the injectivity.
  · literal port lists: `by decide` WITH THE PAIR NAMED. For the
    concatenated-list majority (PcNext, PriorityEnc, BatcherNet,
    BatcherNetC, Decoder, ReadTree) decide IS the right tool — the
    two-lemma route measurably fails on PcNext (Nodup.append +
    Disjoint + piecewise-if injectivity omega cannot do). A blanket
    never-decide clause is BARRED.
  · THE SILENT-REVERIFY TRAP (the clause's real reason): a
    `decide +kernel` nodup cert under the irreducibility device with
    NO numeral visible still elaborates — the kernel unfolds 10/4 —
    so it READS parametric, is not, and can NEVER break at a re-cut
    (nodup is true at every pair; no build signal ever). Any cert
    advertising parametricity uses the lemma route; precedent:
    `aluSelect_outs_eq` (`show` + `rw` through a named seed, zero
    decide).
- RETROFIT: opportunistic, organ-by-organ, cheapest-first (literal
  lists are one `decide` each); NOT a blocking wave. The corpus gap
  closes monotonically; the bar stops it growing.

## 3. POSITIVE CONTROLS (mutation-control law: FALSE, not unreachable)

`adder32Dup.portsNodup` and `halfAdderLong.portsNodup` must be
REFUTABLE — `decide` proves their negations. Both fixtures are kept
as the predicate's permanent controls; a future weakening that lets
either pass is caught at the bytes.

## 4. REFUTATION ASSIGNMENTS

- COMPILER: the ①⁵ clause text against your bar revision (does it
  compose with ①″/①‴? decide costs at scale?); the retrofit list.
- MATH: the general `genSelect_portsNodup` shape — is the injectivity
  lemma already in mathlib's `List.Nodup` API, and does the (3,2)
  re-cut inherit it for free?
- SILICON: the devil's-advocate pass — is there ANY legitimate design
  that WANTS a duplicated output port (fan-out modeling, test taps)?
  If yes, the bar clause needs an escape hatch with a disclosure
  marker, not a flat requirement.
