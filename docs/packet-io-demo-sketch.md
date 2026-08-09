# PACKET-IO + THE VERIFIED FIREWALL — demo sketch for council
### Maestro, 2026-08-09 ~02:3x, from the Captain's 02:1x speculation
### ("for 2 pins, we could equip the cpu with packet io ports. then
### we could communicate through the bb. could we imagine a useful
### demo?") and the 02:2x conversation. STATUS: SKETCH FOR
### DISCUSSION — nothing here is dispatched, priced, or frozen.
### Every claim is marked LANDED / SCOPED / INFERENCE.

## 1. THE REFRAME (the Captain's move, and why it revives co-tenancy)

The co-tenancy analysis died on pin CONTENTION: a CPU bringing its
own interface needs 10+ signals against 7 reclaimable beside the
switch's 16. [LANDED: silicon 20:16/21:26.]

The Captain's move dissolves the contention instead of fighting it:
**a CPU that speaks PACKETS needs only a packet port — serial-in,
serial-out, 2–3 signals — and talks to the world THROUGH the
banyan.** The switch stops being the CPU's rival for pins and
becomes its network front-end. Switch 16 + CPU port 2–3 ≈ 18–19 of
24 signals. [INFERENCE — silicon builds before any pin count is
claimed; the zero-cell law stands.]

Area: the fabric is 2,143 µm² — 11.9% of ONE 1×1 tile [LANDED,
silicon]. Beside the core on the 3×2 it is a rounding error.

## 2. WHY THE THEORY IS ALREADY WAITING (the part nobody planned)

- The packet frame `[validity][address MSB-first][payload]` is the
  ④ heritage campaign's own object. [LANDED]
- `rot^k = id` — the Captain's 1990 sentence — means addresses
  self-restore through the fabric; the CPU's port reads clean
  addresses. [LANDED, scoped form]
- `bnC_payload_delivered` — payloads arrive intact. [LANDED 8/8]
- The verified compiler chain (tiny-Rust Rows A/B) and the
  word-level executive (`runW_map`, unconditional) are the CPU-side
  arrows. [LANDED / statements post-slate]

None of these were built for this demo. They compose into it.

## 3. THE APPLICATION — THE WORLD'S SMALLEST VERIFIED FIREWALL

Packets stream into the banyan; one destination routes through the
CPU, which runs a tiny-Rust POLICY PROGRAM — pass, drop, or rewrite
by header fields — and re-injects survivors. The policy is a dozen
lines of readable source, compiled by the verified compiler, and
**loaded into the chip as packets through the same fabric it will
police.**

THE BENCH DEMO: the host sends a labeled mix; the chip emits
exactly the allowed packets. Then live: edit the policy source,
recompile (verified, seconds), ship the new program down the wire
as packets — the chip's behavior changes in front of the audience.
A firewall whose rules are provably what the source says, updated
through its own dataplane.

THE THEOREM IT CARRIES [SCOPED — each arrow named]:
> No packet violating policy P escapes, and every emitted packet is
> P-sanctioned.
Composed from: `bnC_payload_delivered` (fabric corrupts nothing —
LANDED) ∘ compiler Rows A/B (the program means what the source
says) ∘ B2's no-silent-default coverage (an unclassified packet
hits a NAMED arm — drop — never a forgotten one). B-EXEC later
extends it: two policies as two tasks, provably non-interfering —
multi-tenant filtering with isolation as a theorem.

SCALE HONESTY [INFERENCE — priced before promised]: a rule set fits
in 16 registers + 16 dmem words; per-packet work is tens of
instructions against a bit-serial line rate — the CPU is fast
relative to the wire, the regime where tiny suffices. The genre is
real: middleboxes are where the systems world most wants
verification, because a firewall bug is a breach.

THE HERITAGE SENTENCE: *Bellcore built this fabric to switch the
world's packets in 1990; in 2026 its descendant carries a policy
engine whose every behavior is a theorem.*

Variants in the drawer: the sort service (hardware Batcher vs
compiled tiny-Rust sort behind one fabric, same comparator spec —
gates vs code selected by packet address) and the telemetry
aggregator (verified counting). The filter is the one with teeth.

## 4. HONEST OPENS (what council decides / seats price)

1. The PORT ORGAN does not exist: a small FSM speaking the cell
   dichotomy (validity, address consume, payload passthrough) —
   compiler-shaped; likely modest beside tonight's landings.
   [UNPRICED]
2. FEED vs IO split: packets as the I/O channel with the byte-wide
   feed for program load, or program-load BY PACKET (purer, slower).
   Design fork, council's taste. [OPEN]
3. Tile interaction: this composes WITH the 3×2 own-tile word (the
   port adds ~2–3 signals to the CPU's 18) OR revives single-tile
   co-tenancy (switch + packet-CPU on one 2×2 — area was never the
   switch-side constraint [LANDED]). Two shapes, both honest;
   silicon prices both if council wants numbers. [UNPRICED]
4. The policy language subset: header-field reads + compares +
   the drop/pass/rewrite arms — v1 tiny-Rust already suffices
   [INFERENCE — math checks the statement shapes].
5. Every pin, cell, and rate number above dies until built — the
   night's iron law, pre-applied.

## 4b. MATH'S AST CHECK (02:30 — the sketch's own open #4, answered
## against CodegenSpec.lean, not the intent)

1. **Opens 1 and 4 are COUPLED — council decides them together.**
   v1 has no AND and no SHIFT (neither derivable from add/xor), so
   packed header words cannot be field-extracted in the language.
   Either the PORT ORGAN delivers each field in its own variable
   (v1 then suffices) or the language grows two operators.
2. **SECURITY-RELEVANT: `slt` is signed; addresses are not.** An
   address with the top bit set is negative under slt, so an
   unsigned range check silently inverts on the entire upper half
   of the space. Fix is one constructor (`ult`) or a documented
   bias-by-2³¹ idiom — cheap now, invisible later. [Math: reasoned
   from the semantics, analytic.]
3. **Scope line: no loops ⇒ fixed-offset headers only** (no
   options-style variable headers in v1). The drop/pass/rewrite
   arms are fine, and B2's no-silent-default is STRUCTURAL — ite
   always carries an else.
4. **THE THEOREM, restated honestly — two premises were missing:**
   containment = fabric INTEGRITY (bnC_payload_delivered) ∘
   compiler correctness (Rows A/B) ∘ arm totality (B2) ∘
   **source ⊨ P** (or P is DEFINED as the policy source's
   denotation — say which) ∘ **COMPLETE MEDIATION** (every
   ingress→egress path passes the filter — a port/topology
   obligation, not given by integrity). Integrity alone does not
   yield containment; mediation is the port organ's design burden
   and must be its own row.

## 5. WHAT THIS BUYS THE CAMPAIGN (why it may be the crown demo)

The two-week story's stack — language → compiler → ISA → core →
fabric — currently composes on paper. This demo composes it IN
SILICON, END TO END, with the Captain's own 1990 architecture as
the load-bearing network layer, and ships an APPLICATION a systems
audience recognizes as serious. One packet's journey, every hop
kernel-checked.
