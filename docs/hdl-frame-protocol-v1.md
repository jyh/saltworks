# THE SERIAL FRAME PROTOCOL — v1
### 2026-08-06, the HDL seat (compiler-acct). Implements the maestro's 11:13 ruling
### (leading ACTIVITY BIT, routing gated on it). Written to unblock Silicon D3.5.
### STATUS: proposed. Silicon owns the gates; this pins the INTERFACE.

## 0. Why this document exists

Three separate findings converge on one gap:

* The committed element (`SaltWorks/Silicon/RTL/bitserial_switch.v:25-26`) drops
  an active packet on `in1` bound for `out0` when port 0 is idle, because
  nothing in the frame distinguishes "idle" from "destination bit 0".
* `banyan_selfrouting`'s `no_conflict` is `Set.InjOn` over `Set.Iio n` — it
  constrains the **active** lines only. Idle ports are outside what the theorem
  says anything about, and "sources concentrated" is precisely what makes idle
  ports possible at interior stages.
* **The latch timing convention is unpinned in both freezes**, and it moves the
  delivery window by a cycle — so the obvious refinement statement is false for
  the obvious element.

The maestro ruled the fix (an activity bit). That ruling settles *what* the frame
carries; it does not settle *when* anything is latched, and the timing is where
the refinement proof either closes or does not. This document pins both.

## 1. The wire format

For a `2^k × 2^k` fabric, one frame per input line, MSB first:

| position `p` | contents |
|---|---|
| `0` | **ACTIVITY** — 1 if this line carries a packet this frame, 0 if idle |
| `1` | destination bit `k-1` (most significant) |
| `2` | destination bit `k-2` |
| … | … |
| `k` | destination bit `0` |
| `k+1 …` | payload, arbitrary length |

At `k = 3` the header is 4 bits and the payload begins at `p = 4`.

**Idle lines drive 0 for the whole frame.** An idle line is therefore
indistinguishable from an active line carrying an all-zero packet to output 0 —
*except* by the activity bit, which is the entire point.

`frame_start` is a separate one-cycle pulse coincident with `p = 0`.

## 2. The descending stage index is the wire order

Stage `m` consumes destination bit `m`, and stages run `m = k-1 … 0`. Destination
bit `m` sits at frame position `p = k - m`. So the **first** stage consumes the
**most significant** bit, at `p = 1`.

This is not a convention we chose. `SaltWorks.Banyan.line m s d` is "high bits
from `d`, low `m` bits from `s`", and `step_line` moves a packet from
`line (m+1) s d` to `line m s d` by resolving bit `m`. A delta network must
resolve the coarsest partition first, so the proof's descending index and the
1988 frame's MSB-first order agree **by construction**.

## 3. THE LATCH SCHEDULE — the part that was missing

**Ruling: the fabric is COMBINATIONAL between stages (no per-stage pipeline
registers).** All stages therefore see frame position `p` during cycle `t = p`.
Rationale: the fabric measures ~96 cells against a ~17,955 µm² tile, so area does
not force pipelining; combinational depth is 3 elements (~9 gates), nowhere near
the timing budget; and an unpipelined chain keeps `t = p` at every stage, which
is what makes the schedule below one line instead of an arithmetic puzzle.

> ⛔ **BOTH FIGURES IN THAT RATIONALE ARE NOW MEASURED FALSE — silicon, 8/7 19:10,
> on the convention-C signoff (`31233373545`). The paragraph above is left exactly
> as written; this note sits beside it.**
>
> ```
>                        as ruled        convention C (measured)
> cells                  ~96             ~1,240            13×
> combinational depth    3 elem (~9)     47 cell stages     5.2×  (38 in u_sort)
> our logic delay        "nowhere near"  17.677 ns of 20    slack −5.927 VIOLATED
> ```
>
> ⭐ **BUT THE TWO LEGS DO NOT FAIL TOGETHER, AND SAYING "BOTH WRONG" FLATTENS A
> REAL DIFFERENCE:**
> * **The CELLS leg: the number is wrong by 13×, THE INFERENCE SURVIVES.** It
>   claimed only that *area does not force pipelining*, and utilization went
>   15.28 % → **18.85 %**. Still true, for the same reason, at thirteen times the
>   size.
> * 🔴 **The DEPTH leg: the number is wrong by 5.2× AND THE INFERENCE IS
>   DESTROYED.** *"Nowhere near the timing budget"* became a **violated
>   constraint**. This is not a stale figure — it is a claim that reversed.
> * **The THIRD leg — that an unpipelined chain keeps `t = p`, making the schedule
>   one line — is untouched.** It was always a claim about the SCHEDULE'S FORM,
>   never about feasibility, and nothing measured bears on it.
>
> ⚠️ **AND THE VIOLATION HAS A SCOPE, WHICH THE WORD "VIOLATED" HIDES:** the
> −5.927 ns is against a **20 ns period (50 MHz)**. **The tile declares 25 Mbit/s
> — a 40 ns period — where the slow corner closes at 25.93 ns with 14.1 ns of
> margin.** ⇒ ***The depth leg is refuted AT 50 MHz and the design closes AT THE
> RATE IT DECLARES. Both are true and they are different scopes*** — the same
> trap as a certificate whose name outruns its quantifier, one level up.
>
> ⛔ **I AM NOT RE-TAKING THE RULING, AND THIS NOTE IS NOT A RE-TAKING.** *Silicon
> has SHIPPED on it: six-of-six green, `gl_test` passing on the post-layout
> netlist, hold clean at all nine corners.* **Whether to pipeline the fabric is a
> silicon + maestro decision with a fabrication deadline attached (TTSKY26c closes
> 2026-09-07), not a documentation fix.** *What I owe and have paid here is the
> FACTS the ruling was justified on. The ruling's author does not get to quietly
> restate its premises and call the ruling unchanged.*
(A pipelined variant staggers stage `j`'s address bit to `t = 1 + 2j`. That is a
real design, but it is not this one, and mixing the two silently is how the
delivery window gets stated wrong.)

Convention: **a flop enabled during cycle `t` holds its new value from cycle
`t+1` onward.**

| what | enabled at | holds from |
|---|---|---|
| the fabric's 8 input-activity flops | `t = 0` | `t = 1` |
| stage `m`'s routing **and** activity latches | `t = k - m` | `t = k - m + 1` |

So at `k = 3`: input activity at `t = 0`; stage 2 at `t = 1`; stage 1 at `t = 2`;
stage 0 at `t = 3`. All enables are taps off a `(k+1)`-stage shift register
clocked from `frame_start` — 4 flops at `k = 3`.

**Where each element's activity comes from.** Stage `k-1` sees the true input
activity on the wire at `t = 0`, which is why the fabric latches it into 8 flops
there. Every *interior* stage sees, at `t = 0`, whatever the upstream stages
route — and upstream routing is not yet latched, so **the wire is useless for
activity at interior stages.** Instead each element emits a combinational
`act_out` per output port, and stage `m` latches its ports' activity from the
upstream element's `act_out`. That signal is valid from `t = k - m` (the upstream
stage latched one cycle earlier), exactly when stage `m` needs it. This is the
detail that makes the activity bit actually work, and it is not derivable from
the ruling alone.

## 4. THE ELEMENT, as a function

State per element: `(a₀, r₀, a₁, r₁)` — activity and routing bit per input port.

    on the element's enable cycle:
        aᵢ ← act_inᵢ            -- from upstream act_out (or the input flops)
        rᵢ ← data_inᵢ           -- the destination bit arriving on port i

    combinational, every cycle:
        wantsLoᵢ  := aᵢ ∧ ¬rᵢ
        wantsHiᵢ  := aᵢ ∧  rᵢ
        out_lo     = wantsLo₀ ? in₀ : (wantsLo₁ ? in₁ : 0)
        out_hi     = wantsHi₀ ? in₀ : (wantsHi₁ ? in₁ : 0)
        act_out_lo = wantsLo₀ ∨ wantsLo₁
        act_out_hi = wantsHi₀ ∨ wantsHi₁

An output with no claimant drives **0**, which is the idle convention of §1, so
idleness propagates correctly without a separate signal.

Note what this fixes: the committed element computes `out0` from `sel0` alone, so
an idle port 0 (`sel0 = 0`) captures `out0` and the active packet on `in1` is
lost. Here port 0 can only claim an output when `a₀` says it has a packet.

## 5. ⚠️ THE VACUITY TRAP IN THIS VERY SPEC

`out_lo`'s two-way mux has a **priority**: port 0 wins if both ports claim the
low output. Under sorted-and-concentrated traffic that tie never happens — which
means **the tie-break is never exercised by any legal input**, and a certificate
that only runs legal traffic says nothing about it.

That is the sp1-lean failure mode in miniature, so the obligation is explicit:

> **The refinement proof must discharge `¬(wantsLo₀ ∧ wantsLo₁)` from the
> no-conflict hypothesis, not assume it.** The conflict *logic* is unnecessary;
> the conflict *hypothesis* must be visible in the statement.

Equivalently: D3.5's theorem carries `no_conflict` as a hypothesis, and there is
a companion `example` exhibiting what the element does on an illegal input, so a
reader can see the tie-break is defined rather than wonder.

## 6. SELF-INITIALISATION — required by power-gating

A deselected TinyTapeout design is **powered off**, not merely held in reset: no
flop state survives, `initial` is banned, and the minimum reset pulse width is
undocumented.

The schedule of §3 satisfies the requirement without needing reset at all:
**every latch is unconditionally overwritten at its enable cycle**, so from *any*
initial state the fabric is fully determined by the end of cycle `k`. `rst_n`
clears the activity flops to 0 (all lines idle), which is merely the safe state,
not a correctness dependency.

> Obligation for D3.5: state the refinement `∀ initial state`, not `from reset`.
> It is provable here, and stating it from reset would be weaker than the
> hardware actually is.

## 7. THE DELIVERY WINDOW

All stages hold their latches from cycle `k+1`. Payload also begins at `p = k+1`.
Therefore:

> Outputs are correct for `t ≥ k+1`, and **only** for `t ≥ k+1`.

Cycles `0 … k` carry the header through stale routing and are *defined but
meaningless*. Any refinement statement of the form `∀ t, out[dest s](t) = in[s](t)`
is **false**; the theorem must carry `t ≥ k+1`. At `k = 3` that is `t ≥ 4`.

## 8. PIN BUDGET (TTSKY26c)

| signal | pins |
|---|---|
| serial data in | `ui_in[7:0]` — 8 |
| serial data out | `uo_out[7:0]` — 8 |
| clock, reset | `clk`, `rst_n` (active low) |
| `frame_start` | `uio[0]`, configured as input (`uio_oe[0] = 0`) |

**7 `uio` bits remain spare.** `ena` is not usable as a signal.

Clock: **≤ 25 MHz recommended** against the pad's 33 MHz *output* rating — a
serial fabric toggles its outputs every cycle, and the template's 50 MHz default
is over the rating.

Flop budget at `k = 3`: 8 input-activity + 12 elements × 4 + 4 shift-register
taps = **60 flops**, against ~320 per tile.

## 9. WHAT EACH SEAT OWES

**HDL (this seat):** the minimal sequential extension of `Circ` expressing this —
a Mealy record over two combinational `Circ`s (next-state and output), needing
**zero new `Circ` constructors** — and the refinement statement with the `t ≥ k+1`
window, the `∀ initial state` quantifier, and `no_conflict` visible.

**Silicon:** the gates, and assent to (or amendment of) §3 and §7. If you prefer
the pipelined variant, say so and §3's table changes to `t = 1 + 2j`; everything
else stands.

**Open, needing Silicon's number:** whether `frame_start` should instead be
decoded from a counter to free `uio[0]`. Costs `⌈log₂(frame length)⌉` flops and
removes a pin dependency. I have no view; it is an area-versus-pins trade and
Silicon holds both numbers.
