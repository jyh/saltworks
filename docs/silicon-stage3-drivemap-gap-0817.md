# ③ · THE DRIVEMAP GAP — WIRING THE PLANE THE OBVIOUS WAY FALSIFIES ITS OWN HYPOTHESIS

**silicon, 2026-08-17, on the narrow channel. Written BEFORE any integration RTL
exists, because that is the only time it is cheap.**

③ was ordered as *dmem8 + memif + layout integration*, and its scope "carries F4's
`DriveMap` hypothesis-discharge — the plane `DriveMap` describes has no realization
until ③'s integration builds it." This note is what I found reading the two ends
before building anything between them.

---

## §1 · THE FINDING, IN ONE PAIR OF LINES

```
KERNEL   SaltWorks/HDL/Decoder.lean:31-33
         isLW  =  opcode 0000011 ∧ funct3 = 010
         isSW  =  opcode 0100011 ∧ funct3 = 010
         req   =  isLW ∨ isSW                        ← FUNCT3-GATED

RTL      SaltWorks/Silicon/RTL/core32.v:34-35
         is_load  = (opcode == 7'b0000011)
         is_store = (opcode == 7'b0100011)           ← OPCODE ONLY
```

⛔ **`DriveMap` (Certs/DmemKernelBridge.lean:50-52) asks for the funct3-gated
signals:**

```lean
structure DriveMap (w : BitVec 32) (ins : Nat → Bool) : Prop where
  we  : ins 33 = (ctrlSpec w)[6]!   -- we_in ← isSW
  req : ins 32 = (ctrlSpec w)[7]!   -- req   ← isLW ∨ isSW
```

⇒ **IF ③ WIRES `we_in ← is_store` AND `req ← is_load|is_store` — THE OBVIOUS
WIRING, AND THE ONLY STROBES core32 EXPOSES — THEN `DriveMap` IS FALSE.**

Worked instance, `SB` (opcode `0100011`, funct3 `000`):

```
kernel :  isSW = false,  req = false,  decode w = none
core32 :  is_store = TRUE
⇒ ins 33 = true ≠ (ctrlSpec w)[6]! = false          DriveMap.we VIOLATED
```

## §2 · WHY THAT IS WORSE THAN A FAILED PROOF

F4 door 1 (`dmem_we_out_implies_decoded_touchesMem`) proves the gate-level write
strobe cannot rise for a word the kernel does not decode as a memory op — **under
`DriveMap` as a hypothesis.** A false hypothesis does not make the theorem wrong; it
makes it *silent*. The certificate would still be green, still be citable, and would
cover nothing about the fabricated part.

> ⚠️ The bridge file says this itself, and it is worth quoting because it predicted
> exactly this: *"A SEAM THEOREM SAYS WHAT CROSSES, NOT WHAT CANNOT … `instOK`-style
> certification of the wrong wire is exactly what an assumed port map buys you, which
> is why the assumption is a named structure rather than a `rfl` hidden in a proof."*

**The named structure did its job.** The gap is visible only because the port map was
written down as a hypothesis instead of being buried in a proof.

## §3 · THE WIDER FACT BEHIND IT: THE SILICON IS WIDER THAN THE ISA

`ISA.lean:126-135` rules the kernel **WORD-ONLY**: *"`LW`/`SW` and nothing else — no
`LB`/`LH`/`LBU`/`LHU`/`SB`/`SH`, so there are no byte semantics to get wrong."*

The RTL disagrees, and not by accident — it implements those six in full:

```
core32.v:84-85   dmem_wdata  byte/half replication on funct3 000/001
core32.v:86-88   dmem_be     lane enables on funct3 000/001
core32.v:89-93   lb/lh/ld_out  extract + sign/zero extend on funct3 000/001/100/101
```

That is `RTL/memif.v` inlined. **The 8/12 word-only ruling foreclosed the standalone
`memif` MODULE** (`silicon-pre-D2-area-baseline-0812.md:56-58`, which corrects the D1
composed figure to exclude it) **and left the COPY inside `core32`.** `memif.v` is
instantiated nowhere; its logic ships anyway.

⇒ **A program containing `SB` executes in silicon and is outside everything the
kernel proves.** Nothing in the RTL refuses it.

## §4 · MEASURED: WHAT THE WORD-ONLY REDUCTION IS WORTH

Not a proposal — a price tag, so the decision below is made against a number.

```
core32 as committed   5,054 cells    57,606.4992 µm²
core32 word-only      4,434 cells    56,462.9024 µm²
delta                  −620 (−12.3%)  −1,143.5968 µm²  (−1.98%)
```

*Word-only variant = `dmem_wdata ← rf2`, `dmem_be ← {4{is_store}}`,
`ld_out ← dmem_rdata`.*

✅ **CONTROL, and it is what makes the delta comparable:** the baseline arm of this
run reproduces the COMMITTED figure to the digit — 5,054 cells / 57,606.4992 µm²,
identical to `silicon-pre-D2-area-baseline-0812.md`. Same `synth.sh`, same pinned PDK,
mirrored into a scratch tree so the repo was never touched.

⚠️ **AND THE HONEST SHAPE OF THAT NUMBER: 12.3% OF CELLS BUT 2.0% OF AREA.** The
removed cells are small ones. Quoting "12% fewer cells" for an area argument would be
the wrong figure for the question; area is what a tape-out spends.

## §5 · THE OPTIONS — NOT MINE TO PICK

This touches the tape-out artifact and the kernel↔silicon seam at once, so it is
recorded for the helm and the Captain rather than decided here.

```
(a) NARROW core32 to word-only.   RTL matches the ISA; DriveMap becomes wirable
                                  directly; −1,143.6 µm². Changes behaviour for the
                                  six excluded instructions from full byte/half
                                  semantics to word semantics — they stop being
                                  "wrong but defined" and become "silently wrong".

(b) GATE the strobes on funct3.   we_in ← is_store & (funct3==010), likewise req.
                                  DriveMap holds by construction, core32's byte
                                  logic stays, area unchanged-ish. The excluded six
                                  simply never reach memory. SMALLEST CHANGE THAT
                                  MAKES THE CERTIFICATE TRUE OF THE PART.

(c) TRAP them.                    dmem_addr8 already raises `trap` on misaligned /
                                  out_of_range; a funct3 arm is the same shape. The
                                  exclusion becomes REFUSABLE rather than assumed —
                                  this fleet's own preference for gates that can say
                                  no. Costs the most logic.

(d) DOCUMENT ONLY.                Record that the silicon is wider than the proof.
                                  Cheapest, and the only option that leaves a
                                  known-false hypothesis wired into the part.
```

⚖️ **My reading, offered as a reading and not a decision: (b) is the smallest change
that makes F4's certificate TRUE OF THE BUILT SILICON, and it is separable from the
area question in (a).** They can be taken independently or together; (a) alone does
NOT fix the seam, because opcode-only strobes stay opcode-only.

## §6 · WHAT THIS DOES NOT SAY

- It does **not** say the RTL is wrong. Opcode-only decode is ordinary RV32I; the
  divergence is between the RTL and a deliberately narrowed ISA.
- It does **not** say F4 door 1 is wrong. It is correct and its hypothesis is
  explicit; that explicitness is what surfaced this.
- It does **not** price ③'s integration. It prices ONE reduction inside one module.
- The word-only variant was measured, **not** proved equivalent under the ISA's
  restriction. A proof obligation ("no reachable trace presents funct3 ∉ {010} with
  a load/store opcode") is exactly what the RTL cannot currently supply, since its
  own decode does not test funct3 — which is §1 again, from the other side.
