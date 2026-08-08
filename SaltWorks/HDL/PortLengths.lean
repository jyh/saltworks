/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks

/-!
# ScratchPortLens — port-list LENGTH certificates

⛔⛔ **READ THIS BEFORE COUNTING ANYTHING IN THIS FILE.** ⛔⛔

**EVERY theorem below is NEW, written on 2026-08-08 to fill an ABSENCE.**
Each one says `X.outs.length = N` for a block that, at the moment this file was
written, had **no explicit `outs.length` theorem anywhere in the corpus**. The
theorems are here *because the corpus did not have them* — they are not evidence
that the corpus ever did.

⚠️ **AND THIS FILE IS `Scratch*`, THEREFORE GITIGNORED, THEREFORE NOT IN THE
BUILD GRAPH.** `SaltWorks.lean` does not import it; `lake build` of the corpus
never elaborates it; nothing downstream can cite it. It becomes corpus only when
the maestro sweeps it into a real module and adds the import.

⇒ ⛔ **A CENSUS ASKING "WHAT DOES THE CORPUS PROVE ABOUT PORT-LIST LENGTHS" MUST
EXCLUDE `Scratch*`.** A tree-wide `command grep` (which, unlike the shimmed
`grep`, *does* see gitignored files) will find `adder32_outs_len` here and can
conclude `adder32` was always pinned. It was not. The sweep that produced the
order for this file contaminated its own evidence base in exactly this way; this
header exists so the next pass does not repeat it.

## Why a length certificate is not redundant with `wf`/`ssa`

`Circ.wf` (`Syntax.lean:110-114`) does not constrain `c.outs.length` at all —
its `nodupB` is applied to `c.gates.map Gate.out`, the GATES, so `wf` does not
even require the ports to be *distinct*. `Circ.ssa` bounds each port's net
*number*, never the port *count*. Only `Seq.wf` (`Seq.lean:60-61`) carries a
width, via `core.outs.length == nOut + nState`. So an index-wise certificate
(`∀ k < 32, …`) is blind to a port list that is too LONG: append a port with
byte-identical gates and the cert still holds. The general theorem is already in
the corpus and predates this file — `Stack/Program.lean:2558`
`length_conjunct_is_necessary`, universally quantified in `c`.

## ⚠️ WHAT THE SWEEP FOUND, AND IT IS NOT WHAT THE ORDER EXPECTED

Every block in section A was ALREADY PINNED — implicitly — by a whole-list
`sem`-level certificate it already carried. `sem c ins` unfolds to
`c.outs.map (run ins c.gates)` (`Sem.lean:72-73`), so any theorem of the form
`sem c ins = <list of literal length N>` pins `c.outs.length = N` on the spot.
That is the `①⁗` table's first row (`OperandBMux.lean:100`), and it fires for
`adder32` (`sem_adder32_gen`), `inc32` (`incAddsFourOK`), the four `bw` blocks
(`bwOK`), `sltCirc`/`sltuCirc` (`cmpWord`), `shifter32` (`bsOK`) and `immICirc`
(`sem_immICirc`) alike.

⇒ These theorems make the pin **explicit and citable in one step**. They do not
close a hole in what the corpus knows. `OperandBMux.lean:74`'s standing claim
that `adder32` has "`outs.length` unpinned in the corpus" is **stale**:
`sem_adder32_gen` (`Stack/Program.lean:3147`) pins it at 33.

The REAL holes are in section C.
-/

namespace PortLengths

open SaltWorks.HDL

/-! ## Section A — the cert-carrying combinational blocks

Each of these carries a behavioural certificate and had no explicit
`outs.length` theorem. See the header: each was already pinned *implicitly* by
its own whole-list `sem` cert; these state the number. -/

/-- `Adder.lean:97`. Ports: `sum[0…31]` then `cout`. -/
theorem adder32_outs_len : adder32.outs.length = 33 := by decide +kernel

/-- `Adder.lean:138`. Bits 0,1 pass through; no carry-out port. -/
theorem inc32_outs_len : inc32.outs.length = 32 := by decide +kernel

/-- `Bitwise.lean:64`. -/
theorem bitAnd32_outs_len : bitAnd32.outs.length = 32 := by decide +kernel

/-- `Bitwise.lean:66`. -/
theorem bitOr32_outs_len : bitOr32.outs.length = 32 := by decide +kernel

/-- `Bitwise.lean:68`. -/
theorem bitXor32_outs_len : bitXor32.outs.length = 32 := by decide +kernel

/-- `Bitwise.lean:72`. -/
theorem bitNot32_outs_len : bitNot32.outs.length = 32 := by decide +kernel

/-- `Bitwise.lean:193`. A full word: the answer on bit 0, then 31 copies of one
shared `const false` net. **The port list names net 7 thirty-one times, and `wf`
permits that** — which is the concrete instance of `nodupB` being applied to the
gates rather than to `outs`. -/
theorem sltCirc_outs_len : sltCirc.outs.length = 32 := by decide +kernel

/-- `Bitwise.lean:204`. Same shape: net 2 repeated 31 times. -/
theorem sltuCirc_outs_len : sltuCirc.outs.length = 32 := by decide +kernel

/-- `Shifter.lean:99`. The last stage's 32 outputs. -/
theorem shifter32_outs_len : shifter32.outs.length = 32 := by decide +kernel

/-- `Immediate.lean:60`. Zero gates — every port is an input net, and ports
20…31 all name net 31 (the sign bit). -/
theorem immICirc_outs_len : immICirc.outs.length = 32 := by decide +kernel

/-! ## Section B — blocks whose only stated length was an `#eval`

`RegNext.lean:203-207` measures `regNext.outs.length` with `#eval` and labels the
measurement "MEASURED, not proved … nothing should cite them as if they were".
The number is nonetheless *proved* elsewhere: `sem_regNextN`
(`Stack/Program.lean:7209`) is a whole-list equality universal in `R` and `W`, so
it pins `(regNextN R W).outs.length = R * W`. This states the shipping
instance. -/

/-- `RegNext.lean:106` — `regNextN 32 32`. 32 registers × 32 bits. -/
theorem regNext_outs_len : regNext.outs.length = 1024 := by decide +kernel

/-! ## Section C — ⭐ THE REAL HOLES: blocks with NO CERTIFICATE OF ANY KIND

⛔⛔ **DO NOT READ THE TWO THEOREMS BELOW AS "THIS BLOCK IS CERTIFIED".** ⛔⛔

`zeroTree` and `priorityEnc` are shipped combinational blocks that, as of
2026-08-08, carry **no theorem whatsoever** anywhere in the corpus — not a
behavioural certificate, not a gate count, not even `wf` or `ssa`. Their files
carry `#eval` cone measurements and `#audit_axioms` of their *definitions*, and
nothing else. `PriorityEnc.lean:53` says so in its own prose: *"No theorem says
this encodes the highest-priority interrupt."*

⇒ **A length pin on an uncertified block pins the shape of an unchecked thing.**
It is worth having — a future certificate can cite it — but it is the *least*
of what these two blocks are missing, and citing it as coverage would be the
`①″`-by-luck failure one level down. -/

/-- `AluSelect.lean:135`. A single port: the root of the 5-level OR reduction.
⚠️ **UNCERTIFIED BLOCK** — see the section header. -/
theorem zeroTree_outs_len : zeroTree.outs.length = 1 := by decide +kernel

/-- `PriorityEnc.lean:116`. Ports: `irq_id[0…3]` then `valid`.
⚠️ **UNCERTIFIED BLOCK** — see the section header. -/
theorem priorityEnc_outs_len : priorityEnc.outs.length = 5 := by decide +kernel

/-! ## What is deliberately NOT here

* **`genSelect n b` and `aluSelect`** — `genSelect_outs_eq`
  (`Stack/Program.lean:5642`) is `rfl` and pins the port list at *every* `(n,b)`;
  `aluSelect_outs_eq` (`:5754`) likewise. A `decide +kernel` cert here would be
  strictly weaker than what exists.
* **`obMux` (32), `bnCore` (64), `bnCCore` (104), `ceCcore` (6), `fabric 3` (8),
  `genSelect 3 2` (32)** — all already carry an explicit kernel-proved
  `outs.length` theorem in the corpus.
* **`decoder` (6), `pcNext` (33), `readTree` (32), `regWrite` (32),
  `immBCirc` (32), `haChain` (4), `muxCell` (1), `aluSelect` (32)** — pinned by a
  whole-list certificate they already carry (`decoder_outs_eq`,
  `pcNext_taken_adds_offset`, `sem_readTree_uncond`, `weOK`, `immB_OK`,
  `haChainOK`, `sliced_muxCell`, `aluSelect_outs_eq`).
* **`xorPrevCore` (2), `ceCore` (6)** — sequential cores. `Seq.wf` carries
  `core.outs.length == nOut + nState`, and `xorPrev_wf` / `ce_wf` are proved, so
  the width is pinned for free.
* **`halfAdder`, `ha`, `xorA`, `xorB`, `xorC`, `xorMutant`, `sparse`** — the port
  list is a literal in the definition, so the length is `rfl`.
* **Mutants and fixtures** (`immBshiftedCirc`, `obMuxm1`…`obMuxm5`,
  `adder32Cut`, `pcNextCut`, `bitAnd32Cut`, `aluSelectCut`, `genSelectCut2`,
  `readTreeCutA`/`B`, `regNextNCut`, `decoderCut`, `immIoffCirc`, `pcAdd`,
  `pcAddCut`, `pcAddCutB`, `coreShort`, `coreNarrow`, `coreShaped`,
  `coreShapedT`, `withDead`, `withMidDead`, `denseButUnordered`, `outOfRange`,
  `ceCcoreIdleLow`, `ceCcoreUngated`) — controls, not shipped blocks. Pinning a
  mutant's port count certifies nothing.
-/

#audit_axioms adder32_outs_len
#audit_axioms inc32_outs_len
#audit_axioms bitAnd32_outs_len
#audit_axioms bitOr32_outs_len
#audit_axioms bitXor32_outs_len
#audit_axioms bitNot32_outs_len
#audit_axioms sltCirc_outs_len
#audit_axioms sltuCirc_outs_len
#audit_axioms shifter32_outs_len
#audit_axioms immICirc_outs_len
#audit_axioms regNext_outs_len
#audit_axioms zeroTree_outs_len
#audit_axioms priorityEnc_outs_len

/-! ### On the two `[1 axioms]` rows

`shifter32_outs_len` and `zeroTree_outs_len` audit as `✓ … [1 axioms]` rather
than `[0 axioms]`. The axiom is **`propext`** — measured with `#print axioms`,
not inferred — and it enters through the `Nat.pow` / `Nat.div` in `bsMux`'s
`i + 2 ^ j` and `zrLevelWidth`'s `asW / 2 ^ (j + 1)`. It is one of the three
Lean-foundational axioms on `auditWhitelist`, which is why the tick prints; the
command *throws* on anything else, including the `sorryAx` a failed tactic
would have left behind. No `sorry`, no `native_decide`, no project axiom. -/

end PortLengths
