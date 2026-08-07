# BB-1 · B4 — THE FRAME CONVENTION AT THE SEAM, ADJUDICATED

### 2026-08-07, SILICON. The maestro: state both conventions at the bytes, pick
### with mechanism, rebuild the loser's side. **`gl_test`'s green cannot
### adjudicate this and must not be cited for it — see §4.**

## 1. The two conventions, AT THE BYTES

**Convention C** — my 8/6 ruling (`docs/silicon-frame-protocol-0806.md`, option
C), and what the **landed, kernel-checked** banyan is proved on. `mkFrame true 5 p`:

```
1 1 1 0 1 1 | 0 0 0 0 0 0 0 0
^   ^   ^     payload
(act,a2)(act,a1)(act,a0)      dest 5 = 101, MSB first
```
**ONE wire per line. 6 header cycles = k pairs of (activity, address bit).**
Inactive line: all zeros — activity suppresses the address.

**Convention P** — what the **sorter** is built on. `ceFrame true true [1,0,1] [0,1,0]`,
each row `(rst, act0, act1, in0, in1)`:

```
row0: 1 1 1 1 0      rst=1, act HELD high, data = a2
row1: 0 1 1 0 1                            data = a1
row2: 0 1 1 1 0                            data = a0
```
**TWO wires per line (data + activity). 3 header cycles; activity is a separate
HELD wire, never interleaved.**

⇒ **They differ at the bytes, not merely in spirit: 6 header cycles against 3,
and 1 wire per line against 2.** Neither can be fed to the other without a shim.

## 2. The pick: **CONVENTION C.** Rebuild the sorter's side.

**Mechanism, in order of force:**

1. ⭐ **COST ASYMMETRY, and it is decisive.** C is the convention
   `fabric_routes` is **proved on** — 255 scenarios, `decide +kernel`, about the
   netlist **being fabricated**. Moving the banyan to P **invalidates a landed
   theorem about the shipping artifact.** Moving the sorter to C costs
   `ce_step_eq` (128 cases) and `ce_frame_3/4` — *mechanical re-runs of
   compiler's own pattern.* **One side's proof is about silicon; the other's is
   about 128 rows of a truth table.**
2. **Wire budget.** C is 1 wire/line, P is 2. The tile is 8-in/8-out; C matches
   the pinout natively. P's activity has to travel on **a second network** — and
   that network then owes its own correctness proof.
3. **The 8/6 ruling already decided it on that exact ground** — *"the routing is
   the banyan and nothing else"* — and nothing measured since has weakened it.

## 3. What the rebuild costs (compiler's side, and it is small)

The element must sample **activity on even header cycles and address on odd**
rather than reading a held wire. That is a phase bit: **2 state bits → 3**, so the
per-cycle obligation goes **128 → 256 cases** — still trivial for
`decide +kernel`. *My own `RTL/cmpex.v` carried exactly this signal (`addr_win`),
so the shape is known to work.*

⚠️ **And the composed tile I pushed at B3 silently adopted P** — it feeds `act`
from `uio_in` on separate pins. **That wrapper must be rebuilt too**; it is not a
C-convention tile and should not be read as one.

## 4. ⛔ WHY `gl_test`'s GREEN CANNOT ADJUDICATE THIS

The composed run went green at 13:2x. **It is worth nothing here**, and the
reason is my own finding: **the Batcher is TRANSPARENT when every activity bit is
low** (`idleSw = act1 & ¬act0` never fires, no element swaps), **and low activity
is exactly what the existing bench drives.** ⇒ **The vectors never exercise the
disagreement.** *A green that cannot distinguish the hypotheses is not evidence
about them — citing it either way would be the "certificate at full load"
failure this campaign spent 8/6 cataloguing.*
