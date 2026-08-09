# THE BB SWITCH ACCOUNT — our cells, at every level we can measure
### Council deliverable ① · assembled by the MAESTRO on the seats' files
### Status: DRAFT-UNTIL-REFUTED, SILICON'S HALF STILL OWED (slot §3 open)
### Assembled 2026-08-08 night (the Captain's morning read; full throttle)
### FIREWALL (standing 8/7 ruling, inherited verbatim): the ISSCC 1990
### paper is cited WORDS-ONLY, never figures. Nothing in this account is
### traced from, or compared against, the paper's numbers. This is the
### paper's KIND of presentation — cells at gate and state level —
### applied to OUR cells, from the corpus, measured on the real objects.

## 0. WHAT THIS ACCOUNT IS

The heritage-account pattern, applied forward: the 1990 paper presented
its switch as cells — each shown at gate and state level, with the
design decisions readable in the structure. This account does the same
for the cells WE built and proved this campaign, at two measurement
levels that must never be blended:

- **§1–2 (COMPILER's half, landed 19:21 as
  `compiler-cell-account-0808.md`)**: gates and state bits, from the
  Lean artifacts, every count `#eval`'d on the real object, every
  structural claim a kernel theorem.
- **§3 (SILICON's half, OWED — dispatched 19:19, PRE-AUTH, file-not-post)**:
  standard-cell counts, area, sequential fraction, from synthesis of
  the same objects. *A gate count is not a cell count; the two levels
  get separate tables and no derived ratios until both halves are in.*

## 1. THE THESIS IN THREE ROWS (compiler's table, folded verbatim)

| cell | core nIn | gates | core outs | state bits | kind |
|---|---:|---:|---:|---:|---|
| `Banyan.element` | — | **6** | — | **0** | combinational (`Circ`) |
| `ceCcore` / `ceC` | 7 = 3+4 | **34** | 6 | **4** | sequential (`Seq`) |
| `cell88core` / `cell88` | 7 = 2+5 | **40** | 7 | **5** | sequential (`Seq`) |

**The same routing decision is bought three ways — by an ORACLE
(6 gates, no state), by TIMING (34 gates, 4 state bits), and by DATA
MUTATION (40 gates, 5 state bits).** That row-triple is the frame
study's whole thesis, now measured rather than argued.

Reading convention (compiler's, load-bearing): in `Seq`, a machine's
core `nIn` counts data nets PLUS state nets — `ceC` reads `nIn = 3`
while `ceCcore` reads `nIn = 7`; both are correct and count different
things.

## 2. THE THREE CELLS — the load-bearing facts, one paragraph each
### (full gate lists and functional-group annotations: the source file)

**`Banyan.element` — 6 gates, zero state, and it is NOT a mux.** The
structure is a claim-gated OR (each output ORs two AND-gated claims);
transparency holds exactly under `act0 ∧ act1 ∧ sel0 ≠ sel1` — the
2-of-16 latched claim states are the cell's honest characterisation
(`l2_*_two_of_sixteen`), full-load conflict MERGES non-injectively,
and the hypothesis does the selecting, not the circuit.

**`ceCcore` — 34 gates, 4 state bits: the decision by TIMING.** Two
facts the shape forces, both proved: (i) the decision is made once and
then HELD (`sw = (d∧swap) ∨ (¬d∧newSw)` — the latch makes the element
a static 2-permutation for the rest of the frame, PayloadL1 under H3);
(ii) reset is a HAZARD, not a boundary condition — every state bit is
`∧ ¬rst`, so a mid-frame pulse re-decides on payload bits, producing a
well-formed frame with the wrong tail — invisible to header-level
invariants, which is why the payload theorem exists. Honest bit: the
fourth state bit is proved dead under the protocol
(`ceC_fourth_state_bit_is_dead`).

**`cell88core` — 40 gates, 5 state bits: the same decision by DATA
MUTATION** (the paper's own cell model, landed `499360d`). Six FSM
states, not four — at k = 3 the route-latched state must count out
`k−1` address bits and the pass state has a distinguished wrap cycle
(`cell88_rejects_early_wrap`). And the account's crown: the one-cycle
offset is FORCED at framework level —
`zero_offset_rotation_is_impossible`, for ANY `Seq` machine of ANY
state width — so the "+1 cycle" is a theorem of strictly-causal stream
semantics, and the offset BUYS the routing (the wrapped bit IS the
route bit; one flop serves two purposes).

⚠️ **Do not price "40 vs 34" as a cell comparison** — `cell88core` is a
one-port slice, `ceCcore` a two-input compare-exchange; the composed
2×2 of the 1988 cell is ten state bits, not five. Different objects,
never one column.

## 3. SILICON'S HALF (landed 20:11 as `silicon-bb-switch-cells-0808.md`,
## folded same hour; full provenance rows and fences: the source file)

⛔ **Read before the table (silicon's §0, folded verbatim in substance):
the CELL column is NOT an independent measurement.** Two of the three
objects enter synthesis as STRUCTURAL netlists emitted by `emitS` from
the kernel `Circ`; in that regime abc cannot restructure through
blackboxed cells, so **cell count equals gate count BY CONSTRUCTION —
the 6/34/40 below is compiler's own column wearing different units,
one witness printed twice, never corroboration.** The independent
silicon contribution is the AREA column.

```
object              cells   area µm²   µm²/gate   state
Banyan.element          6         38       6.3      0
ceCcore                34        198       5.8      4*
cell88core             40        235       5.9      5*
     * state bits live in the sequential wrappers — NO flop area is
       in any row; these are CORES ONLY, matching §1's scope
all three: SYNTH_STRUCTURAL=1, sky130_fd_sc_hd, pinned PDK, one flow
```

⭐ **One optimisation datum, standing ALONE (no cross-row ratio — it
comes from a different flow):** `Banyan.element` written behaviourally
through the default flow is **2 cells / 18 µm²** — sky130 carries
`a22o_1`, an AND-AND-OR compound that implements the claim-gated OR in
one cell. **The library already contains the oracle's exact shape.**
The comparable same-regime pair remains 6 vs 34.

Provenance (silicon's §3): `cell88core.v` and `banyan_element_s.v`
emitted by `emitS` — the verified path, not a hand; the 6-input core
wrapping is silicon's and flagged; the behavioural element is
hand-written, two `assign` lines, marked NOT the verified element.
`ce_c.v` identified against compiler's `ceCcore` by exact
port-and-count agreement (7 in / 6 out / 34). Not measured: flops,
routing, placement, anything post-layout.

## 4. THE JOINT READING — both halves in, the level-crossing stated

1. **The thesis, now priced in two units.** The same routing decision
   at three price points: ORACLE 6 gates / 0 state / 38 µm² · TIMING
   34 / 4 / 198 · DATA MUTATION 40 / 5 / 235. The gate and state
   columns are kernel measurements (compiler, `#eval` on the real
   objects); the area column is silicon's pre-layout mapping. The
   cells column is struck from the joint table on silicon's own
   warning — it is the gate column restated, and quoting it as
   agreement would read one witness as two.
2. **µm²/gate is flat (5.8–6.3), and that is the finding:** at this
   scale all three designs are built from the same kind of small
   gate, so the cost differences are ARCHITECTURAL — gate count and
   state discipline — not gate-type effects. The oracle is not cheap
   per gate; it is cheap because it has six gates.
3. **The state axis is UNPRICED in silicon.** The 0/4/5 state bits
   live in sequential wrappers no row measures, so the most
   interesting economic question — what TIMING vs DATA MUTATION cost
   in flops and area — is open, named here rather than smoothed. If
   the account is extended, that is the next measurement.
4. **The library-shape datum reads with the heritage result:** the
   claim-gated OR is not an exotic structure — a commodity 2026 PDK
   implements it as one compound cell. The 1990 paper's KIND of cell
   remains an ordinary citizen of a modern library. (Words-only; no
   figure of the paper is compared.)
5. **None of these numbers enters the tile argument** (silicon's §4
   fence): the live co-tenancy limit is PINS, not area, and the tile
   decision stays on the honest numbers already before the Captain.

## 4b. WHAT §4 DELIBERATELY DOES NOT SAY

No cells-vs-gates corroboration claim · no cross-flow ratio (the 2-cell
datum stands alone) · no flop/sequential pricing · no tile inference ·
no claim about the 1990 silicon.

## 5. WHAT THIS ACCOUNT DOES NOT CLAIM (inherited + assembly-level)

1. Nothing here is a claim about the fabricated 1990 silicon; `cell88`
   is the paper's own cell model, its theorems scoped by the named
   premise (address length = stage count) with A1 owed by the caller.
2. No timing number appears; offsets are `stepSeq` cycles; the paper's
   traversal figures were twice refuted and are carried symbolically.
3. The 1988 2×2 is composed only semantically, not as a single `Circ`.
4. §1–2 and §3 measure DIFFERENT OBJECTS with different units; this
   assembly enforces the separation compiler's §5.4 demands.
5. The assembly adds no new measurements of its own — every number
   above is compiler's, `#eval`'d in its file; every §3 number will be
   silicon's, from its runs.
