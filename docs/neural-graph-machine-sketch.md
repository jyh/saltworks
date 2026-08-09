# THE NEURAL GRAPH MACHINE — the Captain's 3am direction, for council
### Maestro, 2026-08-09 ~03:1x. STATUS: EXPLORATION — a dream taken
### to the design team at the Captain's word, to be explored at
### council. Nothing here is dispatched, priced, or frozen. This doc
### EXTENDS docs/packet-io-demo-sketch.md (the port/packet substrate
### and its couplings all still apply); the APPLICATION evolved
### through the 02:1x–03:1x helm conversation: firewall → exchange →
### THIS. Those two variants move to the drawer, alive.

## 0. THE CAPTAIN'S WORDS (verbatim, 03:0x, the pull itself)

> "the one that seems to pull: the cpu as smart 'neuron', a small
> amount of storage is fine (both inst and data), we would need
> differentiability. so a graph network, dynamic, configurable,
> scalable. this is a 3am dream, but can you take this idea to the
> design team? we can explore the idea at council"

Design constraints as he stated them: CPU = smart NEURON · small
storage suffices, instruction AND data · DIFFERENTIABILITY required
· graph network: DYNAMIC, CONFIGURABLE, SCALABLE.

## 1. THE SHAPE (what the pieces already are)

- **The fabric is the synapse matrix.** The 8×8 banyan routes
  packets = messages between neurons; the routing state IS the
  graph's edge structure. DYNAMIC/CONFIGURABLE arrives for free at
  the architecture level: re-route ⇒ rewire. [The 1990 paper's own
  cells; the ④ campaign's landed theory.]
- **The CPU is the neuron.** Small core + small inst/data store
  runs the node update function in tiny-Rust. The Captain's
  "small storage is fine" names the SpiNNaker design point: many
  tiny neurons, not one big processor — and SpiNNaker (the
  million-core neuromorphic machine) is architecturally this exact
  cell: packet fabric + small CPUs. The 1990 chip anticipated it.
  [Precedent, not derivation.]
- **The butterfly is modern.** Butterfly factorizations (Monarch et
  al.) put dense NN layers in exactly this topology; all-reduce in
  distributed training is hypercube dimension-hopping = the
  banyan's stages. The architecture is not retro — it is the
  current sparsity/communication pattern with a verified pedigree.
  [Literature-anchored; cite at write-up time.]
- **SCALABLE**: banyans compose (larger butterflies / Clos out of
  8×8 blocks). TT demoes one tile; the architecture states its
  scaling law rather than gesturing. [INFERENCE — a scaling
  SECTION, not a scaling claim.]

THE CAPTAIN'S 03:1x ADDENDUM (verbatim: "we can of course put
multiple 'neurons' on a cpu. let's see where it goes"): neurons
VIRTUALIZE — one CPU time-multiplexes N neurons, which is exactly
B-EXEC's executive with tasks-as-neurons. The scheduler campaign's
theorems become neural guarantees: FAIRNESS = every neuron provably
steps; ISOLATION = no neuron's state perturbs another's. SpiNNaker
runs ~1000 neurons per small core the same way. Scaling becomes
two-axis: N neurons × M cores × the fabric. [The B-EXEC and neural
directions are one campaign seen from two ends — council should
weigh them together.]

## 2. DIFFERENTIABILITY — the deep requirement, and a gift already
## in the freeze

The Captain's one hard requirement. Three routes for the team:

(a) **Structural autodiff on the frozen AST.** CodegenSpec's freeze
    has NO while (compiler's held note, 02:5x: "what makes srcSem
    structural") ⇒ programs are finite straight-line + branching ⇒
    **differentiation is definable by structural recursion and
    provable by it.** The freeze that made semantics structural
    makes AUTODIFF structural. The compiler could emit BOTH the
    function and its tangent/adjoint program — Rows A/B then apply
    to the DERIVATIVE too: *the compiled gradient is the source's
    gradient*, as a theorem. Verified AD exists in PL research;
    verified AD DOWN TO SILICON does not. That theorem could be the
    campaign's flagship.
(b) **The backward pass is the fabric run backward.** A butterfly's
    inverse is a butterfly; gradient packets flow the reverse
    topology through the SAME switch. `bnC_payload_delivered` wears
    its fourth costume: gradients arrive intact. [SCOPED — needs
    the reverse-routing statement checked against the landed cells.]
(c) **The arithmetic honesty**: i32 fixed-point calculus. The
    honest theorem is exact derivatives OF THE FIXED-POINT PROGRAM
    (piecewise, branch boundaries named) or real-model derivatives
    WITH quantization bounds — math rules which statement is
    provable and worth proving. Note: differentiability points
    AWAY from spiking (discrete) toward continuous fixed-point
    updates — the Captain's requirement selects the GNN face over
    the neuromorphic face, unless surrogate gradients enter (v2
    question at most).

## 3. THE DEMO CANDIDATE (bench-visible, scale-honest)

Eight neurons on the fabric learn something a person can watch:
label propagation converging across a rewirable graph, or a tiny
fixed-point GNN doing one inference + ONE VERIFIED LEARNING STEP —
forward exact, gradient exact, update exact, all i32, every arrow a
theorem. "The smallest verified learning machine." [EXPLORATION —
council picks the exhibit; seats price it.]

## 4. QUESTIONS TO THE DESIGN TEAM (pre-listed; explore at council,
## nothing fires tonight)

- MATH: the differentiability statement forms — d(program)/d(input)
  for straight-line fixed-point tiny-Rust; the autodiff-correctness
  theorem shape; branch/piecewise boundaries; what loss + update
  rule is provable at demo scale. (Your F7-A wrap choice interacts:
  wrapping arithmetic vs gradient semantics — name the interaction.)
- COMPILER: a source-to-source tangent/adjoint transform on the
  frozen AST — feasibility, and whether Rows A/B lift to the
  transformed program unchanged. Your no-while note is §2(a)'s
  cornerstone; bring it.
- SILICON: the neuron-tile cost (core + port + small inst/data
  store) and the multi-neuron scaling table (neurons per tile
  family); fabric reverse-flow for gradient packets at the RTL.
- EVIDENCE: the claim fence FROM BIRTH — "verified learning" is the
  most over-claimable phrase this campaign will ever touch; the
  barred-phrasings list wants writing before the first measurement
  exists.

## 5. WHY THIS ONE (the era answer)

The firewall was this era's plumbing; the exchange was 1990's
glory; **this is the bridge**: the fabric Bellcore built to route
voices, routing messages between neurons whose every spike,
gradient, and update is a theorem — the Captain's own architecture
arriving at the present, with the kernel holding the pen.
