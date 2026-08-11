import SaltWorks.Silicon.Equiv.FabricRoutes
/-!
# A0 — THE 2-2-1's SIX ROUTES, CERTIFIED IN THE KERNEL

**Silicon seat, 2026-08-10. P1 item A0 of the two-track ruling (`65705fe`:
`SILICON: A0 (the 2-2-1 V10 fixtures)`).** The artifact half is
`Silicon/Sim/a0_fixtures/` (iverilog on the emitted fabric, 6 PASS / 0 FAIL);
this is the kernel half. Both halves are silicon's — compiler declined an A0
half at 17:00 quoting the ruling, and the ruling says what they say it says.

## Why `fabric_routes` does not already cover this

`FabricRoutes.lean` proves D4 over all 255 destination sets — but its
`scenario` binds **source to list index**:

    scenario ds = (List.range 8).map (fun i =>
      if i < ds.length then mkFrame true (ds.getD i 0) (payloadOf i) else idle)

so the active sources are always the prefix `0…n-1` ("sources concentrated",
the `banyan_selfrouting` hypothesis), and `expected ds d = payloadOf (ds.idxOf? d)`
is index-keyed to match. **A 2-2-1 route like `src 4 → dst 0` is not
expressible**: it needs line 4 active while lines 0–3 are idle. Five of the six
routes are outside the certified set for that reason — the SOURCE-concentration
hypothesis, not the destination sorting that was being quoted for it.

`scenarioAt` below drops the hypothesis: each route names its own source line.

## Scope, stated inside the file

⚠️ **Each route is certified IN ISOLATION — one route per frame.** That is the
right model and not a shortcut: the three routes out of cell 2 (`4→0`, `4→1`,
`4→2`) share source line 4, and one line cannot address three destinations in
one frame. Concurrent multi-route load is a DIFFERENT theorem and this file does
not claim it.

## Cost — MEASURED, because a `decide +kernel` over a multi-cycle organ can be
infeasible rather than slow

Compiler handed over the hazard at 17:00 before this was priced: `decide +kernel`
on `runTrace batcherNetC` (816 gates × 14 cycles) was **OS-killed at 24 GB
(EXIT=137)**. That number does not transfer — A0's organ is `runFrame initFabric`,
the same organ `fabric_routes` proves — but the hazard class does, so it was
measured before six routes were committed to:

    1 route   5.30 GiB · 4.17 s
    6 routes  5.56 GiB · 4.88 s      marginal 0.052 GiB/route

**That marginal cost is `FabricRoutes.lean:181`'s 8/6 figure (5.05 GiB fixed +
0.052 GiB/scenario) reproduced on a scenario constructor that did not exist when
it was measured.** The fixed term dominates completely; the wall is ~4.3× away.
-/

namespace SaltWorks.Silicon.Imported
namespace A0

/-- Sources are **not** concentrated on `0…n-1`: each route names its own source
line. Dropping that hypothesis is the whole content of this file. -/
def scenarioAt (rs : List (Nat × Nat)) : List (List Bool) :=
  (List.range 8).map (fun i =>
    match rs.find? (fun p => p.1 == i) with
    | some p => mkFrame true p.2 (payloadOf i)
    | none   => List.replicate 14 false)

/-- Payload is keyed by SOURCE, so a delivery names who sent it. -/
def expectedAt (rs : List (Nat × Nat)) (d : Nat) : List Bool :=
  match rs.find? (fun p => p.2 == d) with
  | some p => payloadOf p.1
  | none   => List.replicate 8 false

/-- Every line carries what it should during the payload window, and every
unaddressed line stays idle. -/
def routesAtOK (rs : List (Nat × Nat)) : Bool :=
  let trace := runFrame initFabric (scenarioAt rs)
  (List.range 8).all (fun d =>
    ((List.range 8).map (fun t => (trace.getD (6 + t) []).getD d false))
      == expectedAt rs d)

/-- The 2-2-1's six routes, each as its own frame. Mirrors the six in
`Silicon/Sim/a0_fixtures/tb_a0_221_routes.v` exactly:
`edge→cell0/1/2`, `cell0→cell2`, `cell1→cell2`, `cell2→edge`. -/
def routes221 : List (List (Nat × Nat)) :=
  [[(4,0)], [(4,1)], [(4,2)], [(0,2)], [(1,2)], [(2,5)]]

set_option maxHeartbeats 4000000 in
set_option maxRecDepth 100000 in
/-- **A0.** Every route of the 2-2-1 delivers its payload to the line its
address names, with every other line idle — checked inside the kernel. -/
theorem a0_221_routes : routes221.all routesAtOK = true := by decide +kernel

/-! ### The instrument can fail

⛔ A fixture that has only ever been run on a passing input has not been shown to
discriminate — and today the artifact half of A0 produced **6/6 false failures**
against a fabric that was fine, so this is not a theoretical worry. `mutantOK`
is `routesAtOK` with the expectation keyed to the WRONG source. It must refute,
and it is proved to refute rather than observed to. -/
def mutantOK (rs : List (Nat × Nat)) : Bool :=
  let trace := runFrame initFabric (scenarioAt rs)
  (List.range 8).all (fun d =>
    ((List.range 8).map (fun t => (trace.getD (6 + t) []).getD d false))
      == (match rs.find? (fun p => p.2 == d) with
          | some p => payloadOf (p.1 + 1)
          | none   => List.replicate 8 false))

-- `.any … = false` is the STRONG form: not "some mutant refutes" but "no mutant
-- survives". `.all … = false` would be satisfied by a single refutation.
theorem a0_mutant_refutes : routes221.any mutantOK = false := by decide +kernel

/-! ### `cell0 → cell2` was already proved — this is the citation, machine-checked

Route `(0,2)` has its source on line 0, so it IS the concentrated singleton
`scenario [2]`, already inside `fabric_routes`'s 255. Rather than assert the
correspondence in prose, it is checked: the stimulus and the expectation agree
pointwise with the originals.

⇒ **A0 is FIVE new fixtures and one CITATION.** -/
theorem a0_cell0_to_cell2_is_scenario_2 :
    (scenarioAt [(0,2)] == scenario [2]) = true := by decide +kernel

theorem a0_cell0_to_cell2_expectation_agrees :
    ((List.range 8).all (fun d => expectedAt [(0,2)] d == expected [2] d)) = true := by
  decide +kernel

#audit_axioms a0_221_routes a0_mutant_refutes
#audit_axioms a0_cell0_to_cell2_is_scenario_2 a0_cell0_to_cell2_expectation_agrees

end A0
end SaltWorks.Silicon.Imported
