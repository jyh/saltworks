# THE SWITCH CELLS AT GATE AND STATE LEVEL — from our own artifacts

**Seat:** COMPILER · **2026-08-08 ~19:2x** · **For:** the BB switch account, council
deliverable ① · **Order:** maestro 19:19, *"the cell gate-structure + state-bit account
from HDL (ceC core, the banyan claim-gated element) — file-not-post, PRE-AUTH"*

The ISSCC paper's *kind* of presentation — cells shown at gate and state level — but
**our cells, from the corpus**, with every count `#eval`'d on the real object. The
words-only firewall on the 1990 paper is untouched: nothing here is traced from, or
compared against, its figures.

⚠️ **READ THIS FIRST OR THE GATE LISTS WILL NOT PARSE.** In the `Seq` framework
(`SaltWorks/HDL/Seq.lean`) a machine is `{nIn, nOut, nState, core : Circ}`, and **the
core's `nIn` is the machine's `nIn` PLUS its `nState`** — state arrives as ordinary
input nets. So `ceC` reads `nIn = 3` while `ceCcore` reads `nIn = 7`: three data nets
and four state nets. Both numbers are correct and they count different things.

---

## 1. THE THREE CELLS, SIDE BY SIDE — measured, not quoted

| cell | core nIn | gates | core outs | state bits | kind |
|---|---:|---:|---:|---:|---|
| `Banyan.element` | — | **6** | — | **0** | combinational (`Circ`) |
| `ceCcore` / `ceC` | 7 = 3+4 | **34** | 6 | **4** | sequential (`Seq`) |
| `cell88core` / `cell88` | 7 = 2+5 | **40** | 7 | **5** | sequential (`Seq`) |

⭐ **That table is the frame study's whole thesis in three rows: the same routing
decision is bought three ways — by an ORACLE (6 gates, no state), by TIMING (34 gates,
4 state bits), and by DATA MUTATION (40 gates, 5 state bits).**

---

## 2. THE BANYAN ELEMENT — 6 gates, ZERO state, a CLAIM-GATED OR

```lean
def pick (s₀ s₁ a b base : Net) : List Gate :=
  [ ⟨base,     .and s₀ a⟩
  , ⟨base + 1, .and s₁ b⟩
  , ⟨base + 2, .or base (base + 1)⟩ ]

def element (s₀lo s₁lo s₀hi s₁hi a b base : Net) : List Gate :=
  pick s₀lo s₁lo a b base ++ pick s₀hi s₁hi a b (base + 3)
```
**Six gates. Low-line output `base+2`, high-line output `base+5`. No state at all** —
`fabric` is a `Circ`, so there is no cycle index and no "after sel_stb".

### ⛔ IT IS NOT A MUX, AND THE DIFFERENCE IS LOAD-BEARING

*The draft design block called this "a locked element is a wire". That was refuted
twice.* **The structure is a claim-gated OR: each output ORs two AND-gated claims.**
Under the no-conflict hypothesis at most one claim is true and the OR *behaves* as a
selection — but the hypothesis is doing the work, not the circuit.

```
measured, PayloadRefutations + PayloadL2:
  a 2-permutation in 2 of 16 latched claim states          (l2_..._two_of_sixteen)
  isWire ↔ act0 ∧ act1 ∧ (sel0 ≠ sel1), EXACTLY over all 16
  full-load conflict MERGES, non-injectively                (l2_full_load_conflict_merges)
  with NEITHER claim the output is `false` — the idle convention
```
⇒ ***So the element is transparent only under `act0 ∧ act1 ∧ sel0 ≠ sel1`, and that
hypothesis is exactly the wire condition rather than merely sufficient for it. The
account should present the 2-of-16 as the cell's honest characterisation.***

📌 **A structural asymmetry worth showing, because it reads as a bug and is not:**
`pick_spec` needs `s₁ < base` and `b < base` and **not** the symmetric conditions on
`s₀`/`a`. Gate `base` reads `s₀` and `a` *before anything is written*, so those
operands cannot have been clobbered — `s₀` may even BE `base`. *Three "for symmetry"
hypotheses were carried for a leg and dropped when the linter's standing warnings were
finally read; dropping them makes the theorem strictly stronger.*

---

## 3. `ceCcore` — 34 gates, 4 state bits, the compare-exchange by TIMING

`nIn = 7`: `rst` (net 0), `in0` (1), `in1` (2), then the four state nets `decided` (3),
`swap` (4), `phase` (5), `bothAct` (6).
`outs = [30, 33, 35, 26, 40, 39]` = `out0, out1, decided', swap', phase', bothAct'`.

### The cell in five functional groups, as the gate list itself annotates

```
RESET GATING     7 ¬rst · 8 d = decided∧¬rst · 10 p = phase∧¬rst · 12 ba = bothAct∧¬rst
                 ⭐ EVERY state bit is ANDed with ¬rst on the way in — so a reset
                    pulse ANYWHERE erases the decision, which is why the payload
                    certificate needs H3 (one pulse at cycle 0, none after).
COMPARE          13 diff = in0⊕in1 · 16 swAct = ¬in0∧in1 · 17 swAddr = in0∧¬in1
DECIDE           18/19 EVEN-phase decision (activity: idle line sorts low)
                 20/21/22 ODD-phase decision (address bit, gated on bothAct)
                 23 newSw = the OR of the two
LATCH-OR-HOLD    24 d∧swap · 25 ¬d∧newSw · 26 sw   ⭐ decided ⇒ HOLD, else adopt
DATAPATH         27–30 out0 = (¬sw∧in0)∨(sw∧in1) · 31–33 out1 = the mirror
NEXT STATE       34/35 decided' · 36–39 bothAct' · 40 phase' = ¬p
```

### ⭐ THE TWO FACTS THIS CELL'S SHAPE FORCES, both proved today

1. **The decision is made once and then held** — `26 sw = (d∧swap) ∨ (¬d∧newSw)`. Once
   `decided` is set, `sw` is the *latched* `swap` and the compare gates cannot change
   it. That is what makes the element a static 2-permutation for the rest of the frame
   (`PayloadL1`, L1 under H3).
2. **Reset is not a boundary condition, it is a hazard.** Because all four state bits
   are `∧ ¬rst`, a mid-frame pulse re-opens the decision and the element re-decides on
   **payload** bits — producing a well-formed frame, for the right destination, with the
   wrong payload tail (`l1_negative_control_is_a_mid_frame_flip`). *That failure is
   invisible to any header-level invariant, which is why the payload theorem exists.*

📌 **`bothAct'` (nets 36–39) samples the data wires on EVERY EVEN CYCLE, payload cycles
included.** So "the control latches are a function of the frame's HEADER bits" is
literally false of the full latch vector — true of `[decided, swap]`, which is what
routes. Bit 3 is proved to be read by nothing under the protocol
(`ceC_fourth_state_bit_is_dead`). *Worth showing: it is a real state bit that carries no
protocol meaning, and the honest account says so rather than presenting four equal bits.*

---

## 4. `cell88core` — 40 gates, 5 state bits, the same decision by DATA MUTATION

**Landed today (`499360d`, `SaltWorks/HDL/Cell1988.lean`) as ④ piece 2.** `nIn = 7`
= 2 data (`rst`, `inp`) + 5 state. Six FSM states — `IDLE, VSEEN, R1, R2, WRAP, LOCK`
— in 3 bits, plus `prev` and `rt`.

### ⛔ WHY SIX STATES AND NOT THE FOUR THE DESIGN BLOCK ASSUMED

The block modelled it as `idle → validity-seen → route-latched → locked-pass`. **At
k = 3 that does not close:** `route-latched` must *count out* the remaining `k−1 = 2`
address bits, and `locked-pass` has a distinguished first cycle — the wrap emission.
*`cell88_rejects_early_wrap` shows the two-cycle pass window is load-bearing.*

### ⭐ AND THE RESULT WORTH PUTTING IN THE ACCOUNT: THE ONE-CYCLE OFFSET IS FORCED

```lean
zero_offset_rotation_is_impossible :
  NO `Seq` machine, of ANY state width, from ANY initial state, rotates at zero offset
```
**A framework-level theorem, not a fact about this cell.** `stepSeq` is strictly causal
— output at cycle `t` is a function of (input at `t`, state at `t`), with no lookahead
anywhere — and `List.rotate _ 1` sends the head to the tail, so the first output bit is
the *second* input bit, which at cycle 0 has not arrived.

⇒ ***So the rotation's "+1 cycle" is not a cost to be optimised away in a better
timing model. It is a theorem of the stream semantics.*** And the sharper reading:
**the offset BUYS the routing.** The validity bit leaves at cycle 1, in the same cycle
its route bit is on the wire; a zero-offset cell would have to route the validity bit
*before its route bit existed*.

📌 **One flop serves two purposes**: at rotate-1 the wrapped bit IS the route bit, so
the storage is shared with the routing latch rather than additive to it.
⚠️ **DO NOT PRICE "40 vs 34" AS A CELL COMPARISON.** `cell88core` is a **one-port
slice**; `ceCcore` is a **two-input compare-exchange element**. The composed 2×2 of the
1988 cell is ten state bits, not five. *Different objects; the account must not put them
in one column and imply a delta.*

---

## 5. WHAT THIS ACCOUNT DOES **NOT** CLAIM

1. **Nothing here is a claim about the fabricated 1990 silicon.** `cell88` is the
   *paper's own cell model*, and ④'s theorems hold for that model under a named premise
   (address length = stage count) with A1 (routing stages only) owed by the caller. The
   rotation algebra, given the paper's design — not a verification of the chip.
2. **No timing number appears.** The offsets counted here are `stepSeq` cycles. The
   paper's traversal figures were twice refuted and are carried symbolically; nothing in
   this file prices `d_N` or µm.
3. **The `2×2` 1988 cell is composed only SEMANTICALLY**, not as a single `Circ`. The
   ③ elements (`ceC`, `Banyan.element`) *are* in the assembled fabric; `cell88`'s 2×2 is
   not.
4. **Cell counts, µm², and sequential fraction are silicon's** — this file is gates and
   state bits from the Lean artifacts, which is a different measurement of a different
   object. *A gate count is not a cell count and the two must not be mixed in one table.*
