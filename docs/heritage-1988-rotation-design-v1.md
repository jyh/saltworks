# THE 1988 ROTATING BANYAN CELL — design block v1 (maestro, 2026-08-08)
### Status: DRAFT-UNTIL-REFUTED. The ④ docket item, crowned: the frame
### study delivered as a THEOREM about the 1990 silicon, not as prose.
### Captain-sessioned 8/8 ("the full circle address rotation" — his
### words; the theorem is literally rot^k = id). Sequenced after ③'s
### waves; zero seat cost until dispatched.
### FIREWALL: the source is Marcus & Hickey, ISSCC 1990, WPM 2.4
### (pp. 32-33, Fig. 6 p. 258) — WORDS-ONLY citations, never the
### figures (Google-licensed PDFs; standing 8/7 ruling).

## 0. THE DESIGN, AS THE PAPER STATES IT

The 1990 chipset (1.2μm CMOS, 32 bit-serial channels at 170 Mb/s,
113/114 transistors per cell) runs the packet layout
`[validity][address MSB-first][payload]` through arrays of identical
2×2 cells, **pipelined one bit per cell per clock** (16-bit delay
across the Batcher chip, 20 across the banyan — Captain-confirmed
8/8: per-stage skew is how a single leading validity bit stays fresh
at every interior stage; contrast convention C, which buys the same
freshness by repeating ACT in the frame).

**The banyan cell's trick**: after its state decision, it "moves the
route bit for the subsequent Banyan cell directly after the packet
address-validity bit" — each stage consumes its route bit and CYCLES
the address, so every cell reads the same position. iSOP is
duration-specific: the pulse width tells cells how much to rotate.

**The Captain's observation, which is the theorem**: the per-stage
mutation composes to the IDENTITY. After k stages the address has made
one full revolution; the packet exits byte-identical to how it
entered, routed to the output it names. The mutation is a loan, repaid
at the last stage.

## 1. THE STATEMENT (shape)

Model the 1988 banyan cell as a small FSM over bit-serial frames
(idle → validity-seen → route-latched → locked-pass-with-rotation);
k-stage network with per-stage unit delay. Under valid + distinct
addresses (the paper's own regime: "internally non-blocking for a
distinct set of addresses" — B4's hypothesis, stated in 1990):

  (i)  ROUTING: packet i exits at output (address i)         [= B2M's
       abstract self-routing, reused, not re-proved]
  (ii) HEALING: the exit stream of packet i, de-skewed by k cycles,
       equals its entry stream — verbatim. The header healed:
       rotate^k = id.

## 2. THE FIVE PIECES, WITH CLASSES

1. **rot^k = id**: `List.rotate_length` (mathlib). A-class; the heart
   is a library one-liner. (The full circle, in the kernel.)
2. **Cell denotation**: FSM + per-frame semantics (routes by the
   post-validity bit; rotates the address; forwards validity+payload
   untouched). B-class in the sequential Circ framework — same genre
   as the landed ceCcore work.
3. **The rotation invariant** (the soul): at stage m, every in-flight
   header = its original address rotated by m; hence the bit each
   stage reads in its FIXED position is original bit k−1−m — the SAME
   bit convention C's stage m reads by TIMING at cycle 2s+1. C-class;
   the analogue of B2M's self-routing induction.
4. **Skew bookkeeping**: per-stage +1-cycle offsets in the trace
   statement. Mechanical; B4's driven-trace induction style carries
   it. (Convention C's zero-skew payload theorem — the ③ block — is
   the easier sibling; do it first, reuse its lemma shapes here.)
5. **The refinement bonus**: 1988-cell and bnC-element are TWO
   implementations of ONE abstract spec — `Banyan.line` never learns
   whether the route bit arrived by rotation or by clock phase.
   Statement: route₁₉₈₈ = route_bnC as functions of (address, stage).
   This is the frame study's thesis as a theorem: *uniformity bought
   with data-mutation and uniformity bought with timing refine the
   same mathematics.*

## 3. THE FRAME-STUDY TRIANGLE (the prose that survives, one page max)

Three solutions to "interior stages need fresh header info", each
pricing a different currency — 1988: SKEW + ROTATION (latency +
rewrite hardware; latency a non-price in context — Captain, 8/8);
the rejected parallel-activity spec: WIRES (a second topology copy);
convention C: HEADER LENGTH (2k cycles, the admitted 14%). Spec
§2.1's resonance (stage s consumes bit k−1−s, forced by the delta
topology) is the bridge fact — 1988's frame order and 2026's proof
index agree because they must. Facade duplicate-constant caveat
applies before citing (same prerequisite repair as ③ §4).

## 4. WHAT THIS IS FOR

The flagship's heritage arc, completed at every altitude: the element
certified both ways (B1, US 5,130,976); the composed switch
unconditional (B4); the 2026 payload certificate (③); and the 1990
banyan cell's algorithm certified sound 36 years later — by the
kernel, in the designer's own program. Words-only citation throughout.

## 5. REFUTATION ASSIGNMENTS

- SILICON: §0 against the paper's text (words faithful? any claim
  exceeding the digest?); the skew/timing table.
- COMPILER: the FSM model's fit in sequential Circ; piece-4 trace
  shapes; whether piece-5's statement is well-formed over the
  existing Banyan.line.
- MATH: pieces 1/3 statement forms; whether the invariant's "rotated
  by m" needs Nodup or works pointwise; the de-skew formulation.
