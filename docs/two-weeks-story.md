# TWO WEEKS WITH THE SALT METHOD — the story (LIVING DRAFT v0)
### Maestro-drafted 2026-08-08 (day 3 of 14; the clock lands Aug 20).
### Purpose: if anyone comes early with an inquiry, this
### account is ready. Revised as we go; every strong adjective must be
### paid by a number from evidence's receipts table before this leaves
### the repo. Voice: the ratified PNAS register (claims short,
### mechanism long; scoped sentences only; hedge only real
### uncertainty). STATUS MARKS: [DONE] carries a commit; [PLAN] is the
### remaining horizon and says so.

## The claim being demonstrated

Designing verified hardware and systems software has historically cost
person-years per artifact. We set a two-week window to measure what
one person directing a fleet of AI seats — under the Salt method:
kernel-refereed proofs, pre-registered criteria, draft-until-refuted
design, adversarial cross-reads — can produce end to end. This
document is the running account.

## Days 1–3 [DONE — every claim commit-anchored]

**A verified 8×8 bit-serial packet switch, hardened to GDS.** The
Batcher–banyan architecture of US Patent 4,910,730 (1988), recreated
as a single 2×2 TinyTapeout tile on sky130A (130 nm) at 25 MHz. The
scope, stated exactly: the gate netlist is proved equivalent to its
Lean specification inside the Lean kernel; header delivery
(`composed_switch_of_bnC_driven`) and payload delivery
(`bnC_payload_delivered` — every output frame is the input frame of
the line destined for it, payload verbatim) are kernel theorems over
the Lean model; the RTL is tied to the spec by exhaustive simulation
cross-check (255/255 cases, two configurations, mutant kill-rate
247/255 agreeing across two independent instruments). Hardened
through LibreLane with a six-of-six-green CI run. Physical silicon
awaits one human submission click.

**A 36-year-old published assertion, proved.** The 1990 ISSCC paper
states of its banyan cell: "the address will leave the banyan
completely restored since it will have passed through a rotation for
every bit of the address." That sentence now holds in the kernel for
the paper's own cell model, with the stage count a named premise and
the routing-stages-only assumption (A1) owed by the caller. Found on
the way: a framework-level law — no sequential machine, of any state
width, rotates a bit-serial stream at zero offset — so the 1988
design's one-cycle offset was causally forced, not a pipelining cost.

**A 5-op RISC-V ISA slice with a certified spine.** ADD/ADDI/XOR/
SLT/BEQ, with a certified ALU-select and instruction-encoder (each
carrying its own semantics theorem and mutation controls) and an
executing interpreter in the corpus. The Batcher-sort demonstration
is DEMONSTRATED: its program is generated from the silicon sorter's
own 24-comparator list, its two compile-around lowerings are theorems
over the real interpreter, and it is certified on 13 kernel-checked
inputs — a certificate suite, not a universal sortedness proof, which
needs Mathlib and is out of scope for this leg. [Twice revised 8/8:
first DOWN when the claim outran the corpus, then UP when the
artifact landed at 5f3e622 eight minutes later — a corrected claim
rots exactly like the claim it replaced, and this one failed safe.] A
same-day re-sizing of the select (10 sources → the ruled (3,2) pair)
ran ruling-to-census-close in one day — 99.65% of surviving theorem
statements byte-identical across the swap — with the freed 1,154
gates (a kernel theorem, not a slide figure) banked for the next
slice.

**The verified HDL compiler beneath all of it.** Lean circuit
descriptions compiled to gate netlists with semantics-preservation
theorems; its census now classifies every module PASS / FAIL /
UNREACHED / UNWIRED by walking import roots to a transitive closure.

**Three flagship number-theory landings the same day** (the method's
home repo): a sharpened Fourier-coefficient bound, its L¹ row, and a
gap-dossier row — two of three unblocked by re-pricing alone after a
probe killed two false constants before any proof was attempted.

**The method's own receipts** (evidence's table, acca901 — traps
disarmed before quoting): 2,126 kernel declarations added in days
1–3; 2,013 standing (at `6d0d0e8`) in a repo three days old; the
payload block
refuted 8× and the heritage block 4× BEFORE either reached the
kernel; every §2 hypothesis of the payload theorem traceable to a
specific refutation; ~17.9M output tokens (17,864,849, measured
across all five seat transcript roots); a dozen instrument
defects caught in one day, each now a mechanical law in the fleet's
kit; the full seat complement cycled through authored mortality
(bank → clear → reboot) without losing a fact.

## Days 4–14 [PLAN — stated as plan]

- **TINY-RUST, with a verified compiler** to the 5-op ISA — the
  language is DESIGNED and Captain-shaped (night of day 3): typed
  (i32/bool, judgment-structured, the judgment IS the correctness
  theorem's hypothesis), multiple functions by verified inlining
  with a DAG-checked call graph, Rust surface syntax, nineteen
  refutation findings folded before any proving. v1 registers-only;
  v2 grows memory + ownership-as-isolation with Slice B.
- **A verified executive** (cooperative first) with fairness and
  isolation invariants stated on a total-transition ISA spec.
- **The RISC-V slice laid out** — the Slice-A RTL now EXISTS and is
  SYNTHESIZED (night of day 3, both register-file widths, same flow
  as every number in the tree); hardening next. Co-tenancy: the
  serialized-feed escape measured −0.2%, then was REFUTED by its own
  author within the hour — the 2-pin variant synthesizes to ZERO
  cells (an undriven design the optimizer pruned whole; a vacuous
  synthesis, caught before the claim settled). The tile question
  stands at the register-file/pin wall on honest numbers; the
  Captain decides. [The "88% headroom" that briefly stood here was
  an adjacent-object misread; struck 8/8 19:1x — this bullet has now
  been corrected twice in one evening, each time by the fleet
  refuting its own most recent answer, which is the method.]
- Slice B of the ISA (LW/SW/JAL/JALR/BNE) against the banked gates.

## Why this is repeatable (the method, one paragraph)

The kernel referees everything; no proof is accepted on any agent's
word, including the director's. Designs are drafted, then refuted by
every seat before a token of proving is spent — the payload theorem's
block survived six defect-bearing refutation rounds before any
proving began (eight before it reached the kernel) and emerged
stronger at each.
Criteria are pre-registered while outcomes are unknown. Claims travel
only with their scope. And the fleet's coordination — a pre-authorized
work queue, optimistic-concurrency preconditions on every wave brief,
ownership boundaries with patch-to-owner transfer — ran a full day of
two simultaneous campaigns with zero blocking round-trips after
dispatch.

## Revision log
- v0, 8/8 evening (day 3): born. Numbers marked pending await
  evidence's receipts table; nothing above outruns its commit.
