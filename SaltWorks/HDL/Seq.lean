/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Opt

/-!
# The minimal sequential extension

Addendum 2 of the leg-2 freeze, and §9 of `docs/hdl-frame-protocol-v1.md`.

## It needs ZERO new `Circ` constructors

A synchronous machine is a **Mealy record over one combinational `Circ`**: the
core's inputs are `(this cycle's primary inputs, the current state bits)` and its
outputs are `(this cycle's primary outputs, the next state bits)`. Registers are
not a gate kind — they are the boundary at which the core's outputs are fed back
to its inputs one cycle later.

That is the whole extension. `Circ`, `sem`, `opt`, `opt_sem`, the bit-sliced
certificates and `emitV` are all untouched and continue to apply to the core,
which is the point of doing it this way: the combinational theory does not fork.

## What this buys the silicon leg

D3.5 must prove the bit-serial switch element refines the word-level `line`
semantics, "per-cycle obligation by `decide +kernel`, lifted by induction over
cycles". `stepSeq` is the per-cycle obligation — a `Circ` evaluation, so every
existing certificate mechanism applies unchanged — and `runTrace_append` is the
lifting: it is what lets a proof about a whole frame be assembled from proofs
about its pieces.

## Two hypotheses the refinement statement must carry

Both are established in `docs/hdl-frame-protocol-v1.md` and neither is optional:

* **The delivery window.** Outputs are correct only for `t ≥ k+1`; cycles
  `0 … k` carry the header through not-yet-latched routing. A statement of the
  form `∀ t, out[dest s](t) = in[s](t)` is false.
* **Any initial state.** A deselected TinyTapeout design is powered off, not
  merely reset, so no flop state survives and `initial` is banned. The refinement
  must be stated `∀ st₀`, not `from reset`. `runTrace` takes the initial state as
  an argument precisely so that quantifier is available.
-/

namespace SaltWorks.HDL

/-- A synchronous machine. `core` has `nIn + nState` inputs — primary inputs
first, then the current state — and produces `nOut + nState` outputs: this
cycle's outputs, then the next state. -/
structure Seq where
  nIn    : Nat
  nOut   : Nat
  nState : Nat
  core   : Circ

/-- The core is wired consistently with the declared widths. Decidable, so a
concrete machine discharges it by `decide +kernel`. -/
def Seq.wf (m : Seq) : Bool :=
  m.core.wf && m.core.nIn == m.nIn + m.nState && m.core.outs.length == m.nOut + m.nState

/-- The core's input valuation for one cycle: primary inputs on nets
`0 ..< nIn`, state bits immediately after. -/
def Seq.env (m : Seq) (inp st : List Bool) : Env := fun j =>
  if j < m.nIn then inp.getD j false else st.getD (j - m.nIn) false

/-- **One cycle.** Returns this cycle's outputs and the next state. This is the
per-cycle obligation D3.5 discharges by `decide +kernel`; it is an ordinary
`Circ` evaluation, so nothing new is needed to certify it. -/
def stepSeq (m : Seq) (st inp : List Bool) : List Bool × List Bool :=
  let o := sem m.core (m.env inp st)
  (o.take m.nOut, o.drop m.nOut)

/-- Run an input trace from a given initial state, collecting the output trace.
The initial state is an argument so refinement statements can quantify over it —
power-gating means we may not assume reset. -/
def runTrace (m : Seq) : List Bool → List (List Bool) → List (List Bool) × List Bool
  | st, []      => ([], st)
  | st, i :: is =>
    let (o, st') := stepSeq m st i
    let (os, stf) := runTrace m st' is
    (o :: os, stf)

/-- **The lifting lemma.** Running a concatenated trace is running the first part
and then continuing from the state it leaves. This is what turns per-cycle
obligations into a statement about a whole frame, and it is the induction D3.5's
"lifted by induction over cycles" refers to. -/
theorem runTrace_append (m : Seq) (st : List Bool) (is js : List (List Bool)) :
    runTrace m st (is ++ js)
      = (((runTrace m st is).1 ++ (runTrace m (runTrace m st is).2 js).1),
         (runTrace m (runTrace m st is).2 js).2) := by
  induction is generalizing st with
  | nil => simp [runTrace]
  | cons i is ih =>
    simp only [List.cons_append, runTrace, ih]

/-- The output at cycle `t`, which is what a delivery-window statement talks
about. -/
def outAt (m : Seq) (st : List Bool) (tr : List (List Bool)) (t : Nat) : List Bool :=
  (runTrace m st tr).1.getD t []

/-! ## A worked machine, kernel-checked

The smallest thing with real sequential content: a one-bit machine whose output
is the XOR of its input with the previous input. It has state, it needs the
state, and its behaviour on cycle 0 depends on the initial state — so it also
exhibits why `∀ st₀` is the honest quantifier. -/

/-- Core: input net 0, state net 1. Output = in ^^ state; next state = in. -/
def xorPrevCore : Circ where
  nIn   := 2
  gates := [⟨2, .xor 0 1⟩]
  outs  := [2, 0]

def xorPrev : Seq := { nIn := 1, nOut := 1, nState := 1, core := xorPrevCore }

theorem xorPrev_wf : xorPrev.wf = true := by decide +kernel

/-- From state `false`, the trace `1,1,0,1` produces `1,0,1,1`. -/
theorem xorPrev_trace :
    (runTrace xorPrev [false] [[true], [true], [false], [true]]).1
      = [[true], [false], [true], [true]] := by
  decide +kernel

/-- **Cycle 0 depends on the initial state** — the concrete reason a refinement
proved "from reset" would be weaker than the hardware, and why `runTrace` takes
`st₀`. -/
theorem xorPrev_initial_state_matters :
    (runTrace xorPrev [false] [[true]]).1 ≠ (runTrace xorPrev [true] [[true]]).1 := by
  decide +kernel

/-- …but from cycle 1 onward the two agree: the machine self-initialises after
one cycle, because its next-state function ignores the old state. This is the
shape of the self-initialisation obligation the frame protocol imposes on the
switch element, in its smallest instance. -/
theorem xorPrev_self_initialises :
    (runTrace xorPrev [false] [[true], [true], [false]]).1.drop 1
      = (runTrace xorPrev [true] [[true], [true], [false]]).1.drop 1 := by
  decide +kernel

#audit_axioms runTrace_append
#audit_axioms xorPrev_wf xorPrev_trace
#audit_axioms xorPrev_initial_state_matters xorPrev_self_initialises

end SaltWorks.HDL
