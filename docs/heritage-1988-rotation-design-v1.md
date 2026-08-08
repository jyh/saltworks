# THE 1988 ROTATING BANYAN CELL — design block v1 (maestro, 2026-08-08)
### Status: DRAFT-UNTIL-REFUTED. The ④ docket item, crowned: the frame
### study delivered as a THEOREM about the 1990 silicon, not as prose.
### Captain-sessioned 8/8 ("the full circle address rotation" — his
### words; the theorem is literally rot^k = id). Sequenced after ③'s
### waves; zero seat cost until dispatched.
### FIREWALL: the source is Marcus & Hickey, ISSCC 1990, WPM 2.4
### (pp. 32-33, Fig. 6 p. 258) — WORDS-ONLY citations, never the
### figures (Google-licensed PDFs; standing 8/7 ruling).
### Refutation state (8/8 13:4x): SILICON ④ COMPLETE (12:43) +
### MATH ④ COMPLETE (13:42, folded): cell timing TWICE REFUTED —
### carried UNFIXED-BY-PROSE, d_cell symbolic; the paper's §3.2
### prose states the rotation theorem VERBATIM (piece 1 = three
### ingredients incl. the address-length = k identification, a
### named premise); assumption A1 named (routing-stages-only,
### forced by the paper's cell dichotomy); §1 scope PINNED to the
### banyan chip alone; piece 3 one-directional,
### validity-antecedent, no packet index; wave controls fixed
### (uniform mutants vacuous, kernel-proved). Method law: grep the
### PROSE before artwork. COMPILER ④ pass OPEN (fires at its seam).

## 0. THE DESIGN, AS THE PAPER STATES IT

The 1990 chipset (1.2μm CMOS, 32 bit-serial channels at 170 Mb/s,
113/114 transistors per cell) runs the packet layout
`[validity][address MSB-first][payload]` — the three-field frame is
this doc's SYNTHESIS, marked derived at silicon's ④ pass: the paper's
words are "most significant bit first" and "packet address-validity
bit" — through arrays of identical 2×2 cells. The paper's pipelining
sentence is a GATE-DEPTH constraint ("the cell logic is pipelined to
allow no more than four logic gates between flip-flops"), not a
per-cell-per-clock rate — the rate was this doc's inference and its
banyan half is corrected below. Chip traversal, the paper's prose: a
16-bit time delay across the Batcher chip, 20 across the banyan
(Captain-confirmed 8/8: per-stage skew is how a single leading
validity bit stays fresh at every interior stage; contrast convention
C, which buys the same freshness by repeating ACT in the frame).

**The banyan cell's trick**: after its state decision, it "moves the
route bit for the subsequent Banyan cell directly after the packet
address-validity bit" — each stage consumes its route bit and CYCLES
the address, so every cell reads the same position. iSOP is
duration-specific: the pulse width tells cells how much to rotate.
THE PAPER STATES THE THEOREM ITSELF (§3.2, math's ④ find — the
doc's "reinsertion" inference is the paper's own word): "Each
element routes on the first bit of the address, rotates the first
bit to the end of the address, and moves the rest up. The address
will leave the banyan completely restored since it will have passed
through a rotation for every bit of the address." Head-to-tail
`rotate 1`; restoration indexed by ADDRESS LENGTH, not stage count.
And the paper's cell dichotomy ("either statically maintains a pass
state, or it routes the packet") means a statically-passing cell
moves NO route bit — hence assumption A1 in §1.

**Cell timing — TWICE REFUTED, NOW CARRIED AS UNFIXED-BY-PROSE
(silicon's ④ pass 12:43 killed the IIRC 2-clock; math's ④ pass
13:42 killed the 4-clock repair the maestro folded at 13:06): the
paper's prose numbers — 16 bit-times Batcher, 20 banyan — do NOT
determine per-cell delay. Math's arithmetic: "identical I/O pad
layout and die size" licenses ONE common overhead o; the Batcher
forces d_B = 1, o = 1 (d_B ≥ 2 gives o < 0), and then the banyan
yields 5·d_N + 1 = 20 ⇒ d_N = 3.8 — no consistent integer
assignment exists, so "5 × 4 = 20 EXACT" was an artefact of
granting the Batcher a spare the banyan was denied. Independent
second kill: 16/20 are PER-CHIP traversals and the prose hedges
chip-vs-network ("one or more Batcher chips"). WHAT SURVIVES: the
MECHANISM and its direction — banyan slower than Batcher, the
rotation's buffering price, confirmed by 20 > 16. The table carries
d_cell SYMBOLIC (d_B, d_N with d_N > d_B) until a citable source
fixes it. Control distribution: the strobes-by-flip-flop-chain
claim remains uncited recollection (silicon's ④ disclosure 3),
barred from the flagship until sourced; the 1988-pipelined vs
2026-frame-counter CONTRAST survives on the architecture (spec §6).**

**The Captain's observation, which is the theorem**: the per-stage
mutation composes to the IDENTITY. After k stages the address has made
one full revolution; the packet exits byte-identical to how it
entered, routed to the output it names. The mutation is a loan, repaid
at the last stage.

## 1. THE STATEMENT (shape)

Model the 1988 banyan cell as a small FSM over bit-serial frames
(idle → validity-seen → route-latched → locked-pass-with-rotation);
k-stage network with symbolic per-stage delay (§0). Under valid +
distinct addresses (the paper's own regime: "internally non-blocking
for a distinct set of addresses" — B4's hypothesis, stated in 1990):

SCOPE PINNED (math's ④ (G): "exit stream"/"de-skew"/"pipeline
depth" each occurred once in the whole docs tree, unscoped, and the
two-chip reading risks null-satisfiability via FabricRoutes'
sortedness law): the theorem is about the BANYAN CHIP ALONE,
directly fed with valid, distinct addresses in arbitrary order —
the Batcher and the two-chip composition are ③/B4's domain, out of
scope here. D is the banyan's own depth, symbolic.
NAMED ASSUMPTION A1 (forced by the paper's own cell dichotomy; the
column census is Figure-only and NOT citable): every stage a packet
traverses is a ROUTING stage — a statically-passing cell makes no
state decision and moves no route bit, so "header at stage m =
rotate m (header at 0)" is licensed only under A1. Carried as a
named assumption, never silently.

  (i)  ROUTING: packet i exits at output (address i)         [= B2M's
       abstract self-routing, reused, not re-proved]
  (ii) HEALING: the exit stream of packet i, de-skewed by the
       network's pipeline depth D (a per-design constant, SYMBOLIC:
       d_B per Batcher column, d_N per banyan stage, d_N > d_B the
       only prose-backed fact — §0's twice-refuted timing note; the
       rotation's buffering price), equals its entry stream
       — verbatim. The header healed:
       rotate^k = id.

## 2. THE FIVE PIECES, WITH CLASSES

1. **rot^k = id**: THREE ingredients, not one (math's ④):
   `rotate_rotate` (fold k unit rotations into one) +
   `List.rotate_length` + the IDENTIFICATION address-length = k =
   stage-count, which the paper indexes by ADDRESS LENGTH and this
   block must state as its own named premise. A-class still — the
   heart is library. (The full circle, in the kernel.)
2. **Cell denotation**: FSM + per-frame semantics (routes by the
   post-validity bit; rotates the address; forwards validity+payload
   untouched). B-class in the sequential Circ framework — same genre
   as the landed ceCcore work.
3. **The rotation invariant** (the soul): under A1, for every VALID
   packet — validity is the antecedent, static; an "in-flight"
   binder is dead weight, the σ-strike disease (math's own ④
   correction) — the header at stage m = the original address
   rotated by m; hence the bit each stage reads in its FIXED
   position is original bit k−1−m — the SAME bit convention C's
   stage m reads by TIMING at cycle 2s+1. Stated
   ONE-DIRECTIONALLY: the converse (recovering m from a healed
   header) needs `Nodup.rotate_eq_self_iff`, and an address
   BIT-list is never Nodup for k ≥ 3 by pigeonhole — a
   characterization is unavailable, not merely unneeded. NO packet
   indexing in the statement (a packet index smuggles a per-stage
   σ — the priced C-class object). WAVE CONTROLS (the
   mutation-control law; math self-caught its own violation: at
   k=3, rotate-2 and rotate-(k−1) are the SAME mutation — that
   pair is BARRED): (1) a NON-UNIFORM schedule with Σrᵢ ≢ 0
   (mod k) — any UNIFORM amount heals (`uniform_amount_always_heals`,
   kernel-proved), so uniform mutants are vacuous; (2) a
   length/stage-count mismatch — live precisely because piece 1's
   identification is a premise. C-class; the analogue of B2M's
   self-routing induction.
4. **Skew bookkeeping**: per-stage offsets in the trace statement,
   SYMBOLIC until §0's timing is fixed — the "+1-cycle" price was
   computed on the twice-dead timing model and is struck (math's ④
   (E)); RE-PRICE at wave time from the then-current d_N.
   Mechanical in style; B4's driven-trace induction carries it.
   (Convention C's zero-skew payload theorem — the ③ block — is
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
index agree because they must. Facade caveat CLEARED 8/8
(64f9311, same repair as ③ §4) — §2.1's resonance is citable directly.

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
