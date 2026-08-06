# THE SERIAL FRAME PROTOCOL — spec v1 (Silicon seat, leg 3)
### 2026-08-06. Implements the maestro's 11:13 ruling (frame leads with an
### ACTIVITY BIT, routing gated on it). JYH may override; until then this
### governs. **This document blocks D3.5** — the FSM refinement statement
### cannot be written until the frame is pinned, because the refinement's
### hypotheses are frame facts.

---

## 0. WHY THIS DOCUMENT EXISTS

Two findings forced it:

1. **The routing bug** (compiler seat, 8/6 10:52). The element could not tell an
   idle port from a port whose destination bit is 0, and silently dropped
   packets. The maestro ruled the fix is a **frame-format decision, not a logic
   patch** — so the frame format had to become a real specification.
2. **Nothing anywhere specified the frame** (refuter finding O10). No delimiting,
   no latch-clear rule, no use for the 8 spare `uio` pins, no latency budget.

---

## 1. THE PROBLEM THE RULING LEAVES OPEN

The ruling says the frame leads with an activity bit. That is right, and it is
sufficient for **one** switch element. It is *not* sufficient for a fabric, and
the reason is worth stating because it drove the design:

> A stage-`s` element can only latch a **routed** activity bit — one that has
> already passed through stage `s-1`. But stage `s-1` does not know how to route
> until *it* has latched. So at cycle 0 the interior stages see their previous
> frame's routing, and a single leading activity bit reaches them as garbage.

Three ways out. I priced all three and took the third.

| option | element cost | header cost | proof cost |
|---|---|---|---|
| **A** — each stage *strips* its address bit and regenerates the activity bit downstream | output mux + regeneration logic; stage-dependent | `k+1` cycles | element is no longer transparent; a "what did it emit when" obligation per stage |
| **B** — pipeline: register every stage output, header travels with the packet | +1 flop per data path per stage (+8 flops) | `k+1` cycles | latency `k` and a cycle-offset in every statement |
| **C** — ✅ **repeat the activity bit**: header is `k` pairs of *(activity, address bit)* | **none** — the committed element already does this | `2k` cycles (6, not 4) | element stays transparent and **stage-agnostic**; strobes are the only per-stage data |

**Ruled: option C.** It costs two extra header cycles on a 14-cycle frame and
buys an element that is purely combinational in its data path, identical at
every stage, and whose refinement obligation is one cycle wide. The committed
`bitserial_switch.v` already implements it unchanged — `act_stb` and `sel_stb`
are exactly the two strobes option C needs.

The trade is deliberate and should be stated in the README as a design choice,
not hidden: **we spent silicon area's cheapest resource (two header cycles) to
buy the proof's most expensive one (a stage-invariant element).**

---

## 2. THE FRAME

For a `2^k × 2^k` fabric (the tapeout is `k = 3`, i.e. 8×8), each of the
`2^k` serial lines carries, **MSB first**:

```
 cycle   0     1     2     3     4     5     6 ...
        ┌─────┬─────┬─────┬─────┬─────┬─────┬───────────────┐
        │ ACT │ a₂  │ ACT │ a₁  │ ACT │ a₀  │ payload …     │
        └─────┴─────┴─────┴─────┴─────┴─────┴───────────────┘
          stage 0     stage 1     stage 2
```

* `ACT` — 1 if this line carries a packet in this frame, 0 if idle. It is
  repeated once per stage, and **all `k` copies are the same bit**.
* `a_m` — destination bit `m`, presented **most significant first**.
* payload — `P` bits, streamed transparently. `P` is a parameter; the tapeout
  uses `P = 8`, giving a **frame length of `2k + P` = 14 cycles**.

**Stage `s` consumes destination bit `k−1−s`** at cycle `2s+1`, having latched
that line's activity at cycle `2s`.

### 2.1 The resonance, now load-bearing rather than decorative

Stage 0 consumes bit `k−1` — the MSB. This is exactly the descending stage index
of the landed proof: `Facade.testBit_step` shows the transition
`line (m+1) → line m` consumes precisely destination bit `m`, so the first stage
consumes `k−1`. The 1988 frame order and the 2026 proof index agree.

They agree because **a delta network must resolve the coarsest partition first**
— it is forced by the topology, not a coincidence. (And note the correction in
`docs/silicon-refuter-0806-addendum.md` §0: `Facade`'s lemmas are currently
stated over a *duplicate* constant `ProbeFacade.line`, not `SaltWorks.Banyan.line`.
The bridge must be restated over the real constant before this paragraph is
quoted anywhere.)

## 3. IDLE SEMANTICS — the routing bug's actual fix

* An input with `ACT = 0` **claims no output**.
* An output claimed by no input **drives 0** for the whole frame.
* Therefore a downstream stage reads `ACT = 0` on that line and is itself idle.

Idleness is thus a *fixed point* of the routing rule, which is what makes the fix
compositional: it is repaired once in the element and holds for the whole fabric,
rather than needing a guard at every stage.

## 4. TIMING AND VALIDITY

The data path is **combinational** end to end — a bit presented at the fabric
input in cycle `t` leaves the fabric in cycle `t`, through `k` levels of
two-way muxing. There is **no pipeline latency**.

Validity, which D3.5 must carry as a hypothesis:

* stage `s`'s outputs are **defined from cycle `2s+2`** (after its `sel_stb`);
* so the **fabric's outputs are defined from cycle `2k`** — cycle 6 for `k = 3`;
* cycles `0 … 2k−1` at the fabric *output* are **don't-care**. The receiver
  ignores them. Nothing downstream may read them.

Consequently the payload window (`2k …`) is exactly the validity window, which
is not an accident — it is why the header length was chosen as `2k`.

## 5. RESET, AND WHY IT IS NOT A CORRECTNESS ASSUMPTION

TinyTapeout **power-gates unselected designs** (`tt_mux.v` drives the user `ena`
and the power-gate enable from one `l_ena`, cells `tt_pg_1v8`). No flop state
survives deselection, `/specs/powerup/` does not exist, and the **minimum reset
pulse width is undocumented**.

So the fabric must **self-initialise from an arbitrary state**:

* every routing register is **unconditionally reloaded** from its wire at its own
  strobe — there is no state-dependent path into the latch;
* therefore after one complete frame from any power-up state, all routing
  registers hold frame-determined values;
* `rst_n` is belt-and-braces, and the frame counter is the only element that
  needs it (§6).

**D3.5 hypothesis:** the refinement holds for frames beginning at or after the
*second* `act_stb` following power-up, from **any** initial register state. This
is stronger than "assume reset works" and it is the honest statement, because the
silicon does not guarantee the weaker one.

## 6. THE STROBE GENERATOR AND TT PIN MAP

The elements are stage-agnostic; all per-stage information lives in two strobes,
generated once at top level from a frame counter.

```
  cnt : 0 … (2k+P−1), free-running, reset by rst_n and re-aligned by sof
  stage s :  act_stb = (cnt == 2s)      sel_stb = (cnt == 2s+1)
```

TinyTapeout pin assignment (`ui_in[8]` + `uo_out[8]` + `uio[8]` + clk + rst_n):

| TT signal | width | use |
|---|---|---|
| `ui_in[7:0]` | 8 | the 8 serial **inputs**, one per fabric line |
| `uo_out[7:0]` | 8 | the 8 serial **outputs** |
| `clk`, `rst_n` | 1+1 | as supplied |
| `uio_in[0]` | 1 | **`sof`** — start-of-frame, re-aligns the counter to 0 |
| `uio_out[3:1]` | 3 | the frame counter, exposed for bring-up |
| `uio_out[4]` | 1 | `valid` — high during the payload window (cycle ≥ 2k) |
| `uio[7:5]` | 3 | reserved |

`sof` matters: without it the host cannot align to the fabric's frame after a
power-gate cycle, and §5 says no state survives one.

**⚠️ Clock.** The TT pad's maximum **output** rate is 33 MHz (half its input
ceiling) and a serial fabric toggles its outputs every cycle. Target **≤ 25 MHz**
against the template's 50 MHz default, and state the margin. Note also that
lowering the clock addresses *setup* and does nothing for **hold**, which is the
real risk here (LibreLane hard-fails hold on all corners).

## 7. WHAT D3.5 MUST CARRY

The refinement statement — bit-serial element FSM refines the word-level `line`
semantics — must make these **visible**, not implicit. Every one of them is a
place where a plausible-looking statement would be vacuous or false:

1. **No-conflict.** At most one *active* input selects each output. This is
   `banyan_selfrouting`'s conclusion under sorted + concentrated destinations.
   The conflict *logic* is unnecessary; the conflict *hypothesis* is mandatory.
   An FSM certificate that never exercises the contended case while claiming to
   refine `line` is the sp1-lean failure mode precisely.
2. **Activity.** The theorem says nothing about idle ports unless idleness is in
   the statement. `no_conflict` is `Set.InjOn` over `Set.Iio n` — it constrains
   the *active* lines only, which is exactly how the routing bug survived it.
3. **Self-initialisation** from an arbitrary register state (§5).
4. **Validity window** — outputs are meaningless before cycle `2s+2` (§4).
5. **Frame alignment** — the strobes are as in §6; a mis-aligned frame is
   outside the theorem.

## 8. VALIDATION — the protocol is executable, not just written down

`SaltWorks/Silicon/Sim/frame_sim.py` builds the 8×8 fabric out of the committed
element's exact logic, drives real frames through it, and checks that every
packet arrives on the line its destination names. Run it: no installs, seconds.

| # | check | result |
|---|---|---|
| 1 | **necessity census** — all 8! = 40,320 full-load permutations | **4,096 route correctly (10.159 %)** |
| 2 | all 255 sorted + concentrated cases, **with idle ports** | **PASS** |
| 3 | 200 arbitrary power-up states, one frame | **PASS** |
| 4 | control: same suite against the **old, buggy** element | **247 / 255 fail** |

Reading these:

**(1) is the honesty exhibit, and the number is exact.** 4,096 = 2¹² — the fabric
has 12 switch elements, each with one bit of state, so it realizes exactly one
permutation per switch setting. **The banyan can route 10 % of permutations and
no more.** The hypothesis `StrictMonoOn dest` is not decorative: an unsorted
input collides internally. This is precisely why the 1988 design puts a Batcher
sorter in front, and it is the measured form of the finding that *the chip
cannot exhibit its own theorem's hypothesis* — we tape out the proved half, and
something off-chip must pre-sort. That sentence now has a number behind it.

**(2) is the theorem's hypothesis, validated against the hardware model** rather
than against prose — and it includes the idle ports that the old element
silently dropped packets on.

**(4) is the control that makes (2) mean anything.** A suite that passes the
fixed element proves nothing unless it fails the broken one. It fails 247 of 255.
Without this row, rows 2 and 3 would be decoration — the same hole three seats
independently named this morning.

## 9. OPEN — needs a decision or a measurement

* **`P` (payload length).** 8 is a placeholder chosen to make a 14-cycle frame.
  Nothing in the proof depends on it. Decide when the testbench is written.
* **Multi-frame back-to-back.** This spec describes one frame. Whether frames
  may abut with no gap depends on the strobe generator only; the element is
  memoryless across frames by construction (§5), so I expect yes — but it is
  **unverified** and must not be claimed until the cocotb testbench shows it.
* **`sof` polarity and pulse width** — pin down with the testbench.
* The **cone-size distribution** of the padded 4–5 k-instance netlist, which
  decides whether per-cone certification is a plan or a hope (see the bus post
  of 12:31). This is a measurement, not a decision, and it is queued next.
