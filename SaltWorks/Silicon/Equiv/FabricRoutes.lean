/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.Silicon.Equiv.SwitchRefinement

/-!
# D4 — the fabric routes, kernel-checked, at PARTIAL LOAD

D3.5 proved one switch element correct. This composes twelve of them into the
8×8 banyan and checks that packets actually arrive where their addresses say —
inside the kernel, by `decide +kernel`.

## Why composition and not enumeration

The flattened fabric's output cones reach **36 inputs**; a sliced net at 36 bits
is 8.6 GB, and the monolithic state space (8 inputs + 12 elements × 4 state bits
= 56 bits) is ~9 PB. Enumerating the fabric is not merely slow, it is impossible.
See `Flow-docs/cone-census.md`.

So the fabric is certified **structurally**: one element proved once
(`switch_step_eq`, 512 configurations), then twelve instances composed by the
topology, and the composite exercised on concrete frames. Concrete runs cost
nothing — no quantification over the 56-bit state, just evaluation.

## PARTIAL LOAD, because full load is vacuous

The ruled test-design law, which the compiler seat's T4 failure established:
**certify at partial load or the certificate is vacuous.** At full load
(`n = 2^k`) sortedness forces `dest = id` and nothing moves — every switch sits
straight and a broken element passes. The certificate below runs **all 255
non-empty sorted, concentrated destination sets**, which is precisely the
hypothesis of `banyan_selfrouting` and precisely where idle ports appear at
interior stages. Idle ports are what the original routing bug exploited.

## The chain

    imported gate netlist  ==(D3.5, decide +kernel over all 512)==>  switchSpec
    switchSpec             ==(elem_matches_spec, decide +kernel)===>  elemStep
    twelve elemStep        ==(this file, decide +kernel)==========>  routes correctly
-/

namespace SaltWorks.Silicon.Imported

open SaltWorks.Silicon

/-! ## The element as a function

`switchSpec` is a `Netlist`, which is what the equivalence machinery consumes.
For composition a plain function is far more workable, so here is one, tied back
to the netlist by an exhaustive certificate rather than by assertion. -/

/-- Element state: `(act0, act1, sel0, sel1)`. -/
abbrev Elem := Bool × Bool × Bool × Bool

/-- Combinational outputs. Input `i` claims output `j` iff it is ACTIVE and its
address bit selects `j`; an unclaimed output drives 0, so idleness propagates. -/
def elemOut (e : Elem) (i0 i1 : Bool) : Bool × Bool :=
  let (a0, a1, s0, s1) := e
  (((a0 && !s0) && i0) || ((a1 && !s1) && i1),
   ((a0 &&  s0) && i0) || ((a1 &&  s1) && i1))

/-- Next state: reload from the wire at this element's strobe, hold otherwise,
clear on `¬rst_n`. -/
def elemNext (e : Elem) (rst i0 i1 astb sstb : Bool) : Elem :=
  let (a0, a1, s0, s1) := e
  (rst && (if astb then i0 else a0), rst && (if astb then i1 else a1),
   rst && (if sstb then i0 else s0), rst && (if sstb then i1 else s1))

set_option maxHeartbeats 2000000 in
/-- **The function agrees with the netlist-level specification**, on all 512
(state, input) combinations. This is what ties the composition below back to
D3.5, and through it to the imported gate netlist. -/
theorem elem_matches_spec :
    (List.range 512).all (fun j =>
      let b := fun i => Nat.testBit j i
      let e : Elem := (b 5, b 6, b 7, b 8)
      let outs := switchSpec_outs.map
        (fun k => (runP (fun i => Nat.testBit j i) [] switchSpec).getD k false)
      let (o0, o1) := elemOut e (b 3) (b 4)
      let (n0, n1, n2, n3) := elemNext e (b 0) (b 3) (b 4) (b 1) (b 2)
      outs == [o0, o1, n0, n1, n2, n3]) = true := by
  decide +kernel

/-! ## The fabric

Twelve elements, three stages. At stage `s` lines `i` and `i XOR 2^(2-s)` pair
up; output 0 goes to the lower line, output 1 to the upper. Stage 0 resolves
destination bit 2 (the MSB), stage 1 bit 1, stage 2 bit 0 — the descending index
of `SaltWorks.Banyan.line`. -/

/-- The pairings, stage by stage. -/
def pairs : Nat → List (Nat × Nat)
  | 0 => [(0,4), (1,5), (2,6), (3,7)]
  | 1 => [(0,2), (1,3), (4,6), (5,7)]
  | _ => [(0,1), (2,3), (4,5), (6,7)]

/-- Fabric state: 12 elements, stage-major (stage 0 first). -/
abbrev Fabric := List Elem

def initFabric : Fabric := List.replicate 12 (false, false, false, false)

/-- One stage applied to the 8 wires. -/
def stageOut (fs : Fabric) (s : Nat) (w : List Bool) : List Bool :=
  (pairs s).foldl (fun acc (p : Nat × Nat) =>
      let idx := s * 4 + ((pairs s).idxOf p)
      let e := fs.getD idx (false, false, false, false)
      let (o0, o1) := elemOut e (w.getD p.1 false) (w.getD p.2 false)
      acc.set p.1 o0 |>.set p.2 o1)
    w

/-- The whole combinational path: three stages, transparently. -/
def fabricOut (fs : Fabric) (din : List Bool) : List Bool :=
  stageOut fs 2 (stageOut fs 1 (stageOut fs 0 din))

/-- One clock edge: every element latches from the wire it sees. -/
def fabricNext (fs : Fabric) (rst : Bool) (din : List Bool) (cnt : Nat) : Fabric :=
  let w0 := din
  let w1 := stageOut fs 0 w0
  let w2 := stageOut fs 1 w1
  let wires := [w0, w1, w2]
  (List.range 12).map (fun idx =>
    let s := idx / 4
    let p := (pairs s).getD (idx % 4) (0, 0)
    let w := wires.getD s []
    elemNext (fs.getD idx (false, false, false, false)) rst
      (w.getD p.1 false) (w.getD p.2 false)
      (decide (cnt = 2 * s)) (decide (cnt = 2 * s + 1)))

/-- Run one 14-cycle frame, returning the output wire at each cycle. -/
def runFrame (fs : Fabric) (streams : List (List Bool)) : List (List Bool) :=
  let rec go (fs : Fabric) (t : Nat) (acc : List (List Bool)) : List (List Bool) :=
    match t with
    | 0 => acc.reverse
    | n + 1 =>
        let cnt := 14 - (n + 1)
        let din := (List.range 8).map (fun i => (streams.getD i []).getD cnt false)
        let out := fabricOut fs din
        go (fabricNext fs true din cnt) n (out :: acc)
  go fs 14 []

/-! ## The certificate -/

/-- The frame for one line: `[ACT, a₂, ACT, a₁, ACT, a₀, payload…]`. An idle line
is all zeros, so its activity bit is 0 and it claims nothing. -/
def mkFrame (active : Bool) (dest : Nat) (payload : List Bool) : List Bool :=
  (List.range 3).flatMap (fun s =>
    [active, active && Nat.testBit dest (2 - s)]) ++ payload

/-- A distinguishable payload per source line. -/
def payloadOf (i : Nat) : List Bool := (List.range 8).map (fun b => Nat.testBit (i + 1) b)

/-- Sources concentrated on `0…n-1`, destinations `ds` (sorted, distinct) — the
hypothesis of `banyan_selfrouting`, and the case where interior stages have idle
ports. -/
def scenario (ds : List Nat) : List (List Bool) :=
  (List.range 8).map (fun i =>
    if i < ds.length then mkFrame true (ds.getD i 0) (payloadOf i)
    else List.replicate 14 false)

/-- What line `d` should carry during the payload window. -/
def expected (ds : List Nat) (d : Nat) : List Bool :=
  match ds.idxOf? d with
  | some i => payloadOf i
  | none   => List.replicate 8 false

/-- All non-empty sorted, concentrated destination sets: every subset of
`{0,…,7}` in increasing order. 255 of them, and **most are partial load**. -/
def allScenarios : List (List Nat) :=
  ((List.range 256).map (fun m =>
    (List.range 8).filter (fun i => Nat.testBit m i))).filter (fun l => l ≠ [])

/-! ### Why this is proved in four chunks

Measured 2026-08-06: as ONE `decide +kernel` over all 255 scenarios this peaked
at **18.2 GiB / 78 s** — the largest single elaboration in the campaign, and it
FAILS at `--cap 12000` and at `--cap 16000` (`excessive memory consumption
detected at 'interpreter'`), which is the wrapper's own default.

The cost is **≈ 5.05 GiB fixed + 0.052 GiB per scenario**, i.e. linear in the
scenario count, while WALL TIME is superlinear. So splitting is not a concession
to the memory cap — it is strictly better on both axes: **8.8 GiB / 45 s**, a 52 %
cut in peak memory and 43 % in wall clock, and it passes at `--cap 12000`.

Both decomposition lemmas are **core, not Mathlib** (`List.all_append`,
`List.take_append_drop`), so the seam leg 2 imports stays Mathlib-free.

The statement of `fabric_routes` below is **unchanged**; only its proof is. -/

/-- The per-scenario predicate — verbatim the lambda in `fabric_routes`. -/
def routesOK (ds : List Nat) : Bool :=
  let trace := runFrame initFabric (scenario ds)
  (List.range 8).all (fun d =>
    ((List.range 8).map (fun t => (trace.getD (6 + t) []).getD d false))
      == expected ds d)

abbrev cA : List (List Nat) := allScenarios.take 64
abbrev cR : List (List Nat) := allScenarios.drop 64
abbrev cB : List (List Nat) := cR.take 64
abbrev cR2 : List (List Nat) := cR.drop 64
abbrev cC : List (List Nat) := cR2.take 64
abbrev cD : List (List Nat) := cR2.drop 64

/-- Reassembly. No fabric evaluation happens here — this is list arithmetic. -/
theorem split : cA ++ (cB ++ (cC ++ cD)) = allScenarios := by
  rw [List.take_append_drop, List.take_append_drop, List.take_append_drop]

set_option maxHeartbeats 4000000 in
set_option maxRecDepth 100000 in
theorem cA_ok : cA.all routesOK = true := by decide +kernel

set_option maxHeartbeats 4000000 in
set_option maxRecDepth 100000 in
theorem cB_ok : cB.all routesOK = true := by decide +kernel

set_option maxHeartbeats 4000000 in
set_option maxRecDepth 100000 in
theorem cC_ok : cC.all routesOK = true := by decide +kernel

set_option maxHeartbeats 4000000 in
set_option maxRecDepth 100000 in
theorem cD_ok : cD.all routesOK = true := by decide +kernel

/-- **D4.** For every one of the 255 sorted, concentrated destination sets, every
packet's payload arrives on the line its address names, and every unaddressed
line stays idle — checked inside the kernel.

Partial load throughout: a set of size `n < 8` leaves `8 - n` sources idle, which
is exactly the condition that produces idle ports at interior stages. -/
theorem fabric_routes :
    allScenarios.all (fun ds =>
      let trace := runFrame initFabric (scenario ds)
      (List.range 8).all (fun d =>
        ((List.range 8).map (fun t => (trace.getD (6 + t) []).getD d false))
          == expected ds d)) = true := by
  show allScenarios.all routesOK = true
  rw [← split]
  simp only [List.all_append, cA_ok, cB_ok, cC_ok, cD_ok, Bool.and_self]

#audit_axioms elem_matches_spec fabric_routes

end SaltWorks.Silicon.Imported
