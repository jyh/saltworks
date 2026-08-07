/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.Vectors

/-!
# C2 — the WITNESSED vectors: `step` against Spike, kernel-checked

Council ruling 3 (Captain, 8/7 06:14): *"C2 = Spike-generated instruction-level
`(state, instr, state')` vectors, kernel-checked against `SaltWorks.ISA.step`"*,
with the trust posture ruled alongside it — **Spike is a WITNESS, not an
oracle.** Untrusted offline generator; disagreements are published, never
resolved in the witness's favour by default.

`SaltWorks/HDL/Vectors.lean` settled the consumer, and said what it was missing:

> *"They are hand-derived by the same seat that wrote `step`, so they are NOT a
> witness... A vector I computed from my own understanding cannot catch my own
> misunderstanding."*

**This file supplies the missing half.** Every vector below was produced by a
third-party RISC-V simulator that has never seen this repository.

## The witness, read at source

Read on 2026-08-07 by running the tools, not from memory — ruling 3's own
clause. *`brew search spike` returns a hit which is a **LEGO product**
(`education.lego.com`); the RISC-V simulator is not in Homebrew at all and was
built from source.*

```
Spike RISC-V ISA Simulator 1.1.1-dev
  github.com/riscv-software-src/riscv-isa-sim
  source commit 3ab575645442aa0ebb58c2d07ab98f1b546ac0bb  (2026-08-06)
  invoked as:  spike --isa=rv32i -d --debug-cmd=<script>
GNU assembler (GNU Binutils) 2.47.20260726
riscv64-elf-gcc (GCC) 16.1.0                 -- assembler/linker only
generator: docs/hdl-c2-tools/genvec.py       seed 20260807, n = 120

SAIL (ruling 3's SECOND reference) — the one-time cross-check, RUN:
Sail 0.20.2 (sail2 @ 41694abd58b27b687af5db275810dfeb8a88cfc0)
  built with `dune build @install` + `dune install --prefix` — opam's solver
  cannot place libsail's dev dependency on ocaml 5.4.1/arm64, and the prefix
  install is REQUIRED or the C++ backend plugin is undiscoverable
sail-riscv model commit 61266bd4dede6c7dd6e903e52dc80bcbf644b1b8 (2026-08-03)
  sail_riscv_sim --rv32 --trace-instr --trace-gpr --stop-at-pc <after>
z3 (sail dies `SMT solver returned unexpected status 127` without a solver)
cross-check: docs/hdl-c2-tools/sailcheck.py  ->  120 agree · 0 disagree · 0 skipped
```

## THE THREE RULES THE GENERATOR OBEYS, AND WHY EACH IS LOAD-BEARING

**R1 — the pre-state is READ BACK from the witness, never assumed.** The
prologue that materialises a register state is itself built from instructions
under test, and Spike's reset sequence leaves registers non-zero that we never
wrote (*measured:* `t0 = 0x80000000`, `a1 = 0x1020`). A vector asserting an
**assumed** pre-state describes a state the witness was never in — and would
pass anyway for every instruction that happens not to read those registers,
which is what makes it a latent falsehood rather than a visible one.

**R2 — the instruction word comes from the ASSEMBLER, not from our `encode`.**
The generator writes a mnemonic, `riscv64-elf-as` encodes it, and the 32 bits
are read back out of Spike's own disassembly line. **`SaltWorks.ISA.encode`
appears nowhere in the path**, so a bug in our encoder cannot manufacture
agreement. *This is what `decode_encode` was landed for.*

**R3 — only what the witness said is written down.** `post` is a diff of two
register dumps taken from Spike; `pc` and `pc'` likewise.

## What the sample covers, stated as counts rather than as a claim

```
add 24 · addi 24 · xor 24 · slt 24 · beq 24      <- STRATIFIED, not sampled:
                                                    a random draw left slt and
                                                    xor absent from the first 6
beq TAKEN            8 of 24     <- forced; a random 32-bit pair is never equal,
                                    so an unforced beq suite tests one direction
x0 as DESTINATION   20 of 120    <- silicon's P5, the strongest single shape
distinct words     120 of 120
pre-state           ALL 31 registers set per vector, corner-biased
                    (0, 1, -1, 0x7FFFFFFF, 0x80000000, random)
```

⚠️ **A NON-OBVIOUS DEFECT THE FIRST RUN HAD, RECORDED BECAUSE IT WAS SILENT AND
BIASED.** 44% of attempts were rejected with fesvr's `misaligned address`: the
`tohost` symbol is read as an 8-byte object, `.data`'s alignment follows
`.text`'s length, and `.text`'s length depends on **how many `li`s expand to
`lui`+`addi` — that is, on the random pre-state VALUES.** *So the rejection was
correlated with the value distribution being sampled, and a "120 vectors"
headline would have described a skewed sample.* Fixed with `.align 3`;
**rejections went 44% → 0, and the stratification became exactly even.**

## ⛔ What this file does NOT claim

**It does not claim `step` is the RISC-V ISA.** It claims exactly what ruling 3
licenses, and the two halves have DIFFERENT strengths, which is the distinction
most likely to be flattened when this is quoted:

```
step agrees with these 120 vectors          KERNEL-CHECKED  (decide +kernel,
                                                             spike_agrees below)
the 120 vectors are reproduced by SAIL      OFFLINE, UNTRUSTED script
                                            (docs/hdl-c2-tools/sailcheck.py:
                                             120 agree, 0 disagree, 0 skipped)
```

⇒ ***The kernel vouches for `step` against the vectors. It does not vouch for
SAIL.*** *The cross-check is a script; its own non-vacuity was established by
mutation — corrupting a landed `post` value by one bit, emptying a `post`,
advancing `pc'`, or flipping a `funct3` bit each produce DISAGREE.*

⚠️ **AND THREE-WAY AGREEMENT DOES NOT EXCLUDE A CORRELATED ERROR.** Spike and
SAIL are independent implementations, but they are **not independent of the
RISC-V manual**. Agreement excludes an error in any **one** of the three; it
cannot exclude an error the specification itself carries.

**Nor is the sample a proof of coverage.** 120 vectors out of a 2^32-word × 2^992
state space is a spot check whose value is in its corners, not its count.
-/

namespace SaltWorks.ISA

/-! **`maxRecDepth`, and what it is NOT.** A 120-element list literal exceeds the
ELABORATOR's default `whnf` recursion depth. The failure text is
`maximum recursion depth has been reached` — *an elaborator depth limit, not a
memory event and not a kernel refusal*; `docs/hdl-cap-rule-M2-0806.md` M-2.1's
memory strings do not appear. Raising the depth costs nothing and changes no
proof obligation.

⚠️ **And the first failing run printed `✓ ... [n axioms]` for all four
declarations while `saltbuild EXIT=1`.** *That is silicon's 8/6 catch exactly —
`#audit_axioms` reports a tick for declarations that never elaborated.* **The
EXIT text is the verdict; the ticks are not.** -/
set_option maxRecDepth 100000

/-- **120 vectors, every one produced by Spike.** See the header for provenance;
the trailing comment on each line is Spike's OWN disassembly of the word. -/
def spikeSuite : List Vec :=
 [
  { pre := [(1, 0x00000002), (2, 0x7251C67D), (3, 0x00000001), (5, 0x3AE32135), (6, 0x0000172E), (7, 0xFFFFFFFE), (8, 0xFFFFFFFE), (9, 0x9304DB81), (10, 0xFFFFFFFE), (11, 0xB4B55DC0), (12, 0xFFFFFFFF), (13, 0x7FFFFFFF), (14, 0xFFFFFFFF), (15, 0x00000002), (17, 0x6C3BF49C), (18, 0x00000002), (19, 0xFFFFFFFE), (20, 0xFFFFFFFF), (21, 0x4E512CCF), (22, 0xFFFFFFFF), (23, 0x7FFFFFFF), (24, 0x80000000), (25, 0x80000000), (26, 0x7B37BDAB), (27, 0xB0BCD298), (28, 0xFFFFFFFF), (29, 0xFFFFFFFF), (30, 0x7FFFFFFF)], pc := 0x800000AC, word := 0x01D18733,
    post := [(14, 0x00000000)], pc' := 0x800000B0 },   -- add     a4, gp, t4
  { pre := [(1, 0x00000085), (2, 0xFD0DC961), (3, 0x00000001), (4, 0x06973B7A), (5, 0x00000074), (6, 0xBC2EE25A), (7, 0x00000033), (8, 0x3E845B2C), (9, 0xFFFFFFFE), (10, 0x00000075), (11, 0x00000002), (12, 0x4B35CE51), (13, 0x00000002), (15, 0xFFFFFFFE), (16, 0x00000001), (17, 0x80000000), (18, 0x14733E58), (19, 0x000015D8), (20, 0x00000001), (21, 0xFFFFFFFE), (22, 0x000000F7), (23, 0xFFFFFFFE), (24, 0x00006E7F), (26, 0xFFFFFFFE), (27, 0x112FE88D), (28, 0xC58BFB67), (29, 0xFFFFFFFF), (30, 0x7FFFFFFF), (31, 0x00000001)], pc := 0x800000A8, word := 0xFFF58593,
    post := [(11, 0x00000001)], pc' := 0x800000AC },   -- addi    a1, a1, -1
  { pre := [(1, 0x5B550085), (3, 0xCA8350E7), (4, 0x00000001), (5, 0xFFFFFFFF), (6, 0xFFFFFFFF), (7, 0x7FFFFFFF), (8, 0x7FFFFFFF), (9, 0x000000FF), (10, 0xFFFFFFFF), (11, 0xFFFFFFFE), (13, 0x0000003A), (15, 0x00002876), (16, 0x00000009), (17, 0x00000002), (18, 0xFFFFFFFE), (19, 0xADDBA0E0), (20, 0xFFFFFFFE), (21, 0x00008AAD), (22, 0x00000001), (23, 0x00000001), (24, 0x18A8EB81), (25, 0x80000000), (26, 0xFFFFFFFE), (27, 0xFFFFFFFE), (28, 0x00000001), (29, 0x000012B9), (30, 0x0000006F), (31, 0x00000001)], pc := 0x800000A0, word := 0x00CAC033,
    post := [], pc' := 0x800000A4 },   -- xor     zero, s5, a2
  { pre := [(1, 0x80000000), (2, 0x00000001), (3, 0x80000000), (4, 0x00000001), (5, 0xAFA2ED1C), (6, 0x000000ED), (8, 0x7FFFFFFF), (9, 0xFFFFFFFE), (10, 0x80000000), (11, 0x5DBAF99B), (12, 0x00000068), (13, 0x0000349D), (14, 0x100A86C9), (15, 0xFFFFFFFE), (16, 0xFFFFFFFF), (17, 0xFFFFFFFF), (18, 0x7FFFFFFF), (19, 0x7FFFFFFF), (20, 0x00000001), (21, 0x80000000), (22, 0x00000002), (23, 0x00008430), (24, 0xFFFFFFFE), (25, 0x80000000), (26, 0x80000000), (27, 0xA7C97C9A), (28, 0xFFFFFFFE), (29, 0x7FFFFFFF), (30, 0x00000001), (31, 0x3AD79E98)], pc := 0x800000A8, word := 0x013E26B3,
    post := [(13, 0x00000001)], pc' := 0x800000AC },   -- slt     a3, t3, s3
  { pre := [(1, 0xFFFFFFFF), (2, 0x00000001), (3, 0x00000001), (4, 0x00000002), (5, 0x80000000), (7, 0x000054E2), (8, 0x00000001), (9, 0x7FFFFFFF), (10, 0x80000000), (11, 0xFFFFFFFE), (12, 0x000000E8), (13, 0xFFFFFFFE), (14, 0x0756784C), (15, 0x00000001), (16, 0x00000001), (17, 0x00000015), (18, 0x000000B2), (20, 0xE36A2B49), (21, 0x00000061), (22, 0xBED49E79), (23, 0x00000002), (24, 0x7FFFFFFF), (25, 0x2D5BEE80), (26, 0x00000002), (27, 0x6D223CB0), (28, 0xFFFFFFFF), (30, 0xFFFFFFFE), (31, 0xFFFFFFFF)], pc := 0x8000009C, word := 0x03768063,
    post := [], pc' := 0x800000A0 },   -- beq     a3, s7, pc + 32
  { pre := [(1, 0x80000000), (2, 0xFFFFFFFF), (3, 0x00000002), (4, 0x0000242C), (5, 0xFFFFFFFF), (6, 0x00003E93), (7, 0x00000001), (8, 0x603F4B11), (9, 0x00000001), (10, 0xFFFFFFFF), (11, 0x7FFFFFFF), (12, 0x7FFFFFFF), (13, 0x7FFFFFFF), (14, 0x48EF0194), (15, 0x80000000), (16, 0x00000091), (17, 0x000096AE), (19, 0x80000000), (20, 0x2E89311C), (21, 0x000000A7), (22, 0xFFFFFFFF), (23, 0x00000001), (25, 0x7FFFFFFF), (26, 0x7FFFFFFF), (27, 0xFFFFFFFE), (28, 0x00000069), (29, 0x7FFFFFFF), (30, 0x80000000), (31, 0x000006E5)], pc := 0x800000AC, word := 0x00A70033,
    post := [], pc' := 0x800000B0 },   -- add     zero, a4, a0
  { pre := [(1, 0x00000001), (2, 0x80000000), (4, 0x7FFFFFFF), (5, 0xFFFFFFFF), (6, 0x7FFFFFFF), (7, 0x80000000), (8, 0x00000001), (10, 0x80000000), (11, 0xE27B1F3B), (12, 0x00000002), (13, 0xFFFFFFFE), (14, 0xFFFFFFFE), (15, 0x7FFFFFFF), (16, 0xFFFFFFFE), (17, 0x000068F7), (18, 0xFFFFFFFF), (19, 0x80000000), (20, 0x8C3793ED), (21, 0x00000056), (22, 0x00000053), (24, 0xD738B716), (25, 0x00000001), (26, 0x654491F6), (27, 0x9D67E775), (28, 0x00000002), (29, 0x80000000), (30, 0x7FFFFFFF), (31, 0xFFFFFFFF)], pc := 0x800000A4, word := 0xD1D48B13,
    post := [(22, 0xFFFFFD1D)], pc' := 0x800000A8 },   -- addi    s6, s1, -739
  { pre := [(1, 0x00000002), (2, 0x80000000), (3, 0x00000001), (4, 0x00000002), (5, 0x80000000), (6, 0x00000002), (8, 0x00000002), (10, 0xD3624861), (12, 0x8169452A), (13, 0x0000E2C8), (14, 0x70E90A19), (15, 0x80000000), (17, 0x80000000), (18, 0xFFFFFFFF), (19, 0x02E3A73B), (20, 0x0000B7BB), (22, 0x000000D2), (23, 0x00000001), (24, 0x80000000), (25, 0xFFFFFFFF), (26, 0x00004805), (27, 0x00005802), (28, 0xFFFFFFFF), (29, 0x00000B33), (30, 0xFFFFFFFF), (31, 0x00003108)], pc := 0x800000A4, word := 0x01DACAB3,
    post := [(21, 0x00000B33)], pc' := 0x800000A8 },   -- xor     s5, s5, t4
  { pre := [(1, 0xC1923AE5), (2, 0x4B345EFF), (3, 0x00000002), (4, 0x7FFFFFFF), (5, 0xFFFFFFFE), (6, 0xFFFFFFFE), (7, 0x80000000), (8, 0xFFFFFFFF), (9, 0x00009555), (10, 0xFFFFFFFE), (11, 0x00000034), (12, 0x0000008B), (13, 0x80000000), (14, 0x0000F977), (15, 0xFFFFFFFE), (16, 0x00000002), (17, 0x00000001), (20, 0x1C3B83AD), (21, 0x00000002), (22, 0xFFFFFFFF), (23, 0x80000000), (24, 0x923436E8), (25, 0xFFFFFFFF), (26, 0x00000001), (29, 0x80000000), (30, 0x9C4A7D79), (31, 0x0000006F)], pc := 0x8000009C, word := 0x0098A133,
    post := [(2, 0x00000001)], pc' := 0x800000A0 },   -- slt     sp, a7, s1
  { pre := [(2, 0x00008439), (3, 0xE564D6D4), (4, 0xFFFFFFFE), (5, 0x00000002), (6, 0x0000E078), (8, 0x01480DB2), (9, 0x80000000), (10, 0x00000001), (11, 0x00000001), (12, 0x000087DC), (13, 0x00009097), (14, 0xFFFFFFFE), (15, 0x000000B5), (16, 0xA39135F8), (17, 0x00001762), (18, 0xFFFFFFFF), (19, 0x0000BA46), (20, 0xFFFFFFFE), (21, 0x7FFFFFFF), (22, 0x25A6AAAA), (23, 0x80000000), (24, 0x713EB83F), (25, 0x00000002), (26, 0x00000002), (27, 0xFFFFFFFF), (28, 0x80000000), (29, 0x80000000), (30, 0x00000001)], pc := 0x800000AC, word := 0x01428863,
    post := [], pc' := 0x800000B0 },   -- beq     t0, s4, pc + 16
  { pre := [(1, 0xBDAD640C), (2, 0x000000F4), (3, 0x00000030), (4, 0xFFFFFFFE), (7, 0x0000004C), (8, 0x00001CAB), (9, 0xE4D48A8F), (10, 0xE22535A1), (11, 0x2A81D698), (12, 0x7FB6E604), (13, 0x0000D71F), (14, 0x00000002), (15, 0x80000000), (16, 0x000000BE), (17, 0x00000002), (18, 0x00000001), (19, 0x00000002), (20, 0x00000001), (21, 0x0000C810), (22, 0x10B4953F), (24, 0x00000001), (25, 0xFFFFFFFE), (26, 0x00000001), (27, 0x7FFFFFFF), (28, 0xBEDEB4B8), (29, 0x00000001), (30, 0xFFFFFFFE), (31, 0xFFFFFFFF)], pc := 0x800000A8, word := 0x016A8033,
    post := [], pc' := 0x800000AC },   -- add     zero, s5, s6
  { pre := [(1, 0x80000000), (2, 0x0000F2CA), (3, 0x80000000), (4, 0x00000001), (5, 0xFFFFFFFF), (6, 0x80000000), (7, 0x7FFFFFFF), (8, 0x5389F68C), (11, 0x53436D65), (12, 0x0000A6B6), (13, 0xFFFFFFFF), (14, 0x00000001), (15, 0xFFFFFFFE), (16, 0x000000FE), (17, 0x00000002), (18, 0xD898FA24), (19, 0xDB86F9EA), (20, 0xDF3B0906), (21, 0x107F8615), (22, 0x0000C470), (23, 0xFFFFFFFF), (24, 0x9E7E0FCA), (25, 0xFFFFFFFE), (26, 0x00000002), (27, 0xFFFFFFFE), (28, 0x7FFFFFFF), (31, 0x7FFFFFFF)], pc := 0x800000B0, word := 0x7FF30793,
    post := [(15, 0x800007FF)], pc' := 0x800000B4 },   -- addi    a5, t1, 2047
  { pre := [(1, 0x00000009), (2, 0x000066FF), (3, 0x00000002), (4, 0x860E8D3C), (5, 0xB489E789), (6, 0x7FFFFFFF), (7, 0x000000F2), (8, 0x0000DDC8), (10, 0x00000001), (11, 0x00000001), (12, 0x00000011), (13, 0x7FFFFFFF), (14, 0xFFFFFFFF), (15, 0x00003D83), (17, 0xFFFFFFFF), (18, 0x00002921), (19, 0xFFFFFFFF), (21, 0x09BE2459), (24, 0x00000001), (25, 0x7FFFFFFF), (26, 0x7FFFFFFF), (27, 0xFFFFFFFE), (28, 0xC44EF439), (29, 0x80000000), (30, 0x7FFFFD9E), (31, 0xBBC3DE10)], pc := 0x800000B4, word := 0x0073C7B3,
    post := [(15, 0x00000000)], pc' := 0x800000B8 },   -- xor     a5, t2, t2
  { pre := [(1, 0x00000002), (2, 0x000016D8), (3, 0x80000000), (4, 0x9E644AA3), (5, 0x7FFFFFFF), (6, 0x80000000), (7, 0x425CDEC7), (8, 0x73226547), (9, 0x00000025), (11, 0x80000000), (12, 0xA8CE902A), (13, 0x00000001), (14, 0xFFFFFFFF), (15, 0xFFFFFFFF), (16, 0x00000001), (17, 0xFFFFFFFF), (18, 0x03374A1E), (19, 0xEC4AC7D2), (20, 0xED7074BE), (21, 0x7FFFFFFF), (22, 0x000000A3), (23, 0x0000002C), (24, 0xFFFFFFFF), (25, 0x0000A17F), (26, 0x7FFFFFFF), (27, 0x00000002), (28, 0x649729D9), (29, 0x00000002), (30, 0x0000FA24), (31, 0x00000002)], pc := 0x800000B4, word := 0x0074A4B3,
    post := [(9, 0x00000001)], pc' := 0x800000B8 },   -- slt     s1, s1, t2
  { pre := [(1, 0x0000874C), (2, 0x00000002), (3, 0x000000A2), (4, 0xFFFFFFFE), (5, 0x0000301C), (6, 0x7DCC7AEE), (7, 0x00000002), (8, 0x7FFFFFFF), (10, 0x0000002C), (11, 0x00000002), (12, 0x000059D7), (13, 0x80000000), (14, 0xA780492A), (15, 0xFFFFFFFF), (16, 0x80000000), (17, 0x574CF700), (18, 0x36FD5A65), (19, 0x000087F4), (20, 0x000000FD), (22, 0x7FFFFFFF), (23, 0xFFFFFFFF), (24, 0x000000FD), (25, 0xDF9B406D), (26, 0xFFFFFFFF), (27, 0x000000F1), (28, 0x80000000), (30, 0x1714EF09), (31, 0x00000001)], pc := 0x800000AC, word := 0x018A0863,
    post := [], pc' := 0x800000BC },   -- beq     s4, s8, pc + 16
  { pre := [(1, 0xED9A93A1), (2, 0x0000002B), (3, 0x00000002), (4, 0xFFFFFFFE), (5, 0x00000002), (7, 0x0000001A), (8, 0x00000002), (9, 0x0000848E), (10, 0x693F6FEF), (11, 0x00000001), (12, 0x73ABE6D3), (13, 0xF53C21B1), (15, 0x00000002), (16, 0xFF1470F7), (17, 0x00000067), (18, 0x2C4BCA13), (19, 0x00000002), (20, 0xCDFD2E1D), (21, 0x000000DB), (22, 0x71997C47), (23, 0xFFFFFFFF), (24, 0x7FFFFFFF), (25, 0xFFFFFFFF), (26, 0x72A07473), (27, 0x00006580), (28, 0x000000B2), (30, 0xFFFFFFFE), (31, 0xFFFFFFFF)], pc := 0x800000AC, word := 0x007F0433,
    post := [(8, 0x00000018)], pc' := 0x800000B0 },   -- add     s0, t5, t2
  { pre := [(1, 0x80000000), (2, 0xFFFFFFFF), (4, 0x18DC9DF1), (5, 0x00000032), (6, 0xFFFFFFFF), (7, 0x7FFFFFFF), (8, 0x00000069), (9, 0x0000F0A6), (10, 0x00000001), (12, 0x000000A7), (13, 0x00000002), (14, 0x80000000), (15, 0x00000002), (16, 0x00000002), (17, 0x00000002), (18, 0x80000000), (19, 0xFFFFFFFE), (20, 0x7FFFFFFF), (21, 0xACC2C67A), (22, 0x00000002), (23, 0xCC64EDD9), (24, 0x80000000), (25, 0xFFFFFFFE), (26, 0xFFFFFFFE), (27, 0x00000001), (28, 0x0000FCA8), (30, 0x000000DF), (31, 0x00000002)], pc := 0x80000098, word := 0x7FFE8713,
    post := [(14, 0x000007FF)], pc' := 0x8000009C },   -- addi    a4, t4, 2047
  { pre := [(1, 0x0000005F), (2, 0x00000002), (3, 0xFFFFFFFE), (4, 0x00007A44), (5, 0x00000002), (6, 0xFFFFFFFE), (7, 0xAD7CC56A), (8, 0x000000FD), (9, 0x00000002), (10, 0xFFFECC4E), (11, 0x0000004D), (12, 0x7FFFFFFF), (13, 0xFFFFFFFF), (14, 0xFFFFFFFF), (15, 0x00000001), (16, 0x00000002), (17, 0x00003CDB), (18, 0xFFFFFFFE), (19, 0xFFFFFFFF), (20, 0x7FFFFFFF), (21, 0x00000001), (22, 0xBBC330F6), (23, 0xFFFFFFFE), (24, 0xFFFFFFFF), (25, 0xF03C945E), (26, 0xF70C0C50), (27, 0x80000000), (28, 0xFFFFFFFE), (29, 0x0000F8A6), (31, 0x0000BFC9)], pc := 0x800000A8, word := 0x012FCD33,
    post := [(26, 0xFFFF4037)], pc' := 0x800000AC },   -- xor     s10, t6, s2
  { pre := [(1, 0x7FFFFFFF), (2, 0xDB8BB211), (3, 0x7FFFFFFF), (4, 0x80000000), (5, 0xABD052AD), (6, 0x7FFFFFFF), (7, 0x00000001), (8, 0x0000D373), (9, 0xABFD3A20), (10, 0x00000002), (11, 0xCE50AAA3), (12, 0x17087581), (13, 0xFFFFFFFF), (15, 0x00000001), (16, 0x7A28BC08), (17, 0xB3EF9C00), (18, 0x80000000), (19, 0x00000001), (20, 0x00000001), (21, 0xFFFFFFFF), (23, 0x80000000), (24, 0x80000000), (25, 0x0000F108), (26, 0x7FFFFFFF), (27, 0x00000001), (28, 0x00000002), (29, 0xFFFFFFFF), (30, 0x00003076), (31, 0xFFFFFFFF)], pc := 0x800000B4, word := 0x002FA7B3,
    post := [(15, 0x00000000)], pc' := 0x800000B8 },   -- slt     a5, t6, sp
  { pre := [(2, 0xFFFFFFFF), (3, 0x00000082), (4, 0xFFFFFFFF), (5, 0x09EFD60E), (6, 0xFFFFFFFE), (7, 0xA088A5DC), (8, 0x7FFFFFFF), (9, 0x0000002B), (10, 0x80000000), (11, 0x00000001), (12, 0x0000D5EB), (13, 0x00000002), (14, 0x80000000), (15, 0xFFFFFFFE), (16, 0x80000000), (18, 0x00001C60), (19, 0xFFFFFFFE), (21, 0xFFFFFFFE), (22, 0xFFFFFFFF), (23, 0x7FFFFFFF), (24, 0x7FFFFFFF), (25, 0xFFFFFFFE), (26, 0x4C75D49E), (27, 0x80000000), (28, 0x00007023), (29, 0x0000E641), (30, 0x00000002), (31, 0x000000F2)], pc := 0x800000A4, word := 0x01CC0463,
    post := [], pc' := 0x800000A8 },   -- beq     s8, t3, pc + 8
  { pre := [(1, 0x00000002), (2, 0xFFFFFFFE), (3, 0x00000001), (4, 0x7FFFFFFF), (5, 0xFFFFFFFF), (6, 0x00000001), (7, 0xFFFFFFFE), (8, 0xFFFFFFFF), (9, 0x00000002), (10, 0x0000007F), (12, 0x00000001), (13, 0xC03CEEE4), (14, 0x202A4578), (15, 0x00000002), (16, 0x00000002), (17, 0x80000000), (18, 0x000094D9), (19, 0x00000002), (20, 0x00000002), (21, 0x4501D3D6), (22, 0xA9D37E86), (23, 0x7FFFFFFF), (24, 0x7FFFFFFF), (25, 0xFFFFFFFF), (26, 0xFFFFFFFE), (27, 0xA9EA5531), (29, 0x7FFFFFFF), (30, 0x00000001), (31, 0x00000002)], pc := 0x800000A4, word := 0x01200033,
    post := [], pc' := 0x800000A8 },   -- add     zero, zero, s2
  { pre := [(1, 0xC58CD2ED), (2, 0x0000383E), (3, 0x7FFFFFFF), (4, 0x00000001), (5, 0xE1DD289E), (6, 0x0000DB30), (7, 0x00000001), (8, 0x0000007B), (9, 0x7FFFFFFF), (10, 0xB7AE39F5), (11, 0x00000002), (12, 0xFFFFFFFE), (13, 0x00000002), (14, 0x00000001), (15, 0x00000001), (16, 0x72A8BA3A), (17, 0x0000001E), (19, 0x00000017), (20, 0x0000C76A), (21, 0x00000001), (23, 0x000000E7), (24, 0xFFFFFFFE), (25, 0xFFFFFFFE), (26, 0xFFFFFFFF), (27, 0x00000045), (28, 0x6E5B18F5), (29, 0x00000001), (31, 0xFFFFFFFF)], pc := 0x800000A4, word := 0x80048493,
    post := [(9, 0x7FFFF7FF)], pc' := 0x800000A8 },   -- addi    s1, s1, -2048
  { pre := [(1, 0x00005387), (2, 0x00000002), (3, 0xFFFFFFFE), (4, 0x80000000), (5, 0xFB88A6F5), (6, 0x80000000), (7, 0xFFFFFFFE), (8, 0xFFFFFFFE), (9, 0x7FFFFFFF), (10, 0x00000001), (11, 0x80000000), (12, 0x00000020), (14, 0x0000003D), (15, 0xAEE6CECA), (16, 0xB6B307EA), (17, 0x7F3922A3), (18, 0x0000CE86), (19, 0x30D8D854), (20, 0x00000002), (21, 0x7FFFFFFF), (23, 0x00000001), (25, 0x36C47DD8), (26, 0x000000AC), (27, 0x6125D470), (28, 0x7FFFFFFF), (29, 0x80000000), (30, 0x5685C705), (31, 0x000000E0)], pc := 0x800000B0, word := 0x01E044B3,
    post := [(9, 0x5685C705)], pc' := 0x800000B4 },   -- xor     s1, zero, t5
  { pre := [(1, 0xFFFFFFFE), (2, 0xA07A8ECB), (3, 0x000000E3), (4, 0x8A7BCCC3), (5, 0x7FFFFFFF), (6, 0x00000174), (8, 0xC31F1D35), (9, 0xFFFFFFFE), (10, 0xFFFFFFFE), (11, 0x342965DD), (12, 0x00009AAD), (13, 0x7FFFFFFF), (16, 0x7FFFFFFF), (17, 0x00000002), (18, 0x000000E7), (19, 0x00000001), (20, 0xFFFFFFFE), (21, 0x00005E11), (22, 0xFFFFFFFF), (24, 0x0000003F), (26, 0x00000001), (27, 0x00000001), (28, 0x80000000), (29, 0x00000001), (30, 0x80000000), (31, 0x830C1A12)], pc := 0x800000A4, word := 0x011F2EB3,
    post := [], pc' := 0x800000A8 },   -- slt     t4, t5, a7
  { pre := [(1, 0x000000C4), (2, 0x0000007B), (3, 0x00000088), (4, 0x0000D24B), (5, 0xFFFFFFFE), (6, 0x395BA8A9), (7, 0xFFFFFFFE), (8, 0x00000001), (9, 0x0EB7B7E8), (10, 0x00000001), (12, 0x00000001), (15, 0x0000E850), (16, 0x000000A8), (17, 0x000000A5), (18, 0x000000A0), (19, 0x00000002), (20, 0xCA224730), (21, 0x80000000), (22, 0x277DDD10), (23, 0x00000002), (24, 0x055FF28E), (25, 0x722446F4), (26, 0x00000002), (27, 0xFFFFFFFE), (28, 0xFFFFFFFF), (29, 0x7FFFFFFF), (30, 0x80000000), (31, 0x000021A3)], pc := 0x800000A4, word := 0x00730263,
    post := [], pc' := 0x800000A8 },   -- beq     t1, t2, pc + 4
  { pre := [(1, 0x80000000), (3, 0x107E9133), (4, 0x8C307A78), (5, 0x000011D2), (6, 0xE8A0CDD4), (7, 0x7FFFFFFF), (8, 0x57DF47B1), (9, 0x16F08240), (10, 0x80000000), (11, 0xEFFBADD5), (12, 0x00000002), (13, 0x7FFFFFFF), (14, 0x00004DB3), (15, 0xFFFFFFFF), (16, 0x00000001), (17, 0x00000002), (18, 0x80000000), (20, 0x00007298), (21, 0x00000002), (22, 0x6DE0079C), (23, 0xCAA62E4E), (24, 0x00000001), (25, 0x0519252A), (26, 0x0000EC7A), (27, 0x00000002), (28, 0x80000000), (29, 0x00000002), (30, 0x0000005E), (31, 0x00000002)], pc := 0x800000B8, word := 0x00B888B3,
    post := [(17, 0xEFFBADD7)], pc' := 0x800000BC },   -- add     a7, a7, a1
  { pre := [(1, 0x00000001), (2, 0xFFFFFFFF), (3, 0x00000001), (4, 0x7FFFFFFF), (5, 0xFFFFFFFF), (6, 0x00000002), (7, 0x0000EBCF), (8, 0xFFFFFFFF), (9, 0x00001BB0), (11, 0x00000001), (13, 0x00000001), (14, 0xFFFFFFFE), (15, 0x0000630B), (16, 0xFFFFFFFF), (17, 0xFFFFFFFE), (19, 0xFFFFFFFE), (20, 0x00006DF9), (21, 0xFFFFFFFF), (22, 0x44E30E04), (23, 0x41E8D996), (24, 0x00000002), (25, 0x00000030), (26, 0x00000082), (27, 0xFFFFFFFE), (28, 0x80000000), (29, 0x80000000), (30, 0x00002DE7), (31, 0x00000002)], pc := 0x8000009C, word := 0x7FFF0913,
    post := [(18, 0x000035E6)], pc' := 0x800000A0 },   -- addi    s2, t5, 2047
  { pre := [(1, 0x80000000), (2, 0x0000006A), (3, 0x00000070), (4, 0xFFFFFFFF), (5, 0xFFFFFFFF), (6, 0xFFFFFFFE), (7, 0x00000002), (8, 0x7FFFFFFF), (9, 0x00001559), (10, 0x537C3678), (11, 0x7FFFFFFF), (12, 0x00000002), (13, 0x0000AAF9), (14, 0xFFFFFFFF), (15, 0x1DBA6957), (17, 0x0A0140F2), (18, 0x00000002), (19, 0x2350501C), (20, 0x915EE514), (21, 0x00000002), (22, 0x00000001), (23, 0x7FFFFFFF), (24, 0x00000069), (25, 0x80000000), (26, 0x627049A5), (27, 0x1F263A90), (28, 0x32F530E8), (29, 0xFFFFFFFF), (30, 0x80000000), (31, 0x80000000)], pc := 0x800000B0, word := 0x0026C433,
    post := [(8, 0x0000AA93)], pc' := 0x800000B4 },   -- xor     s0, a3, sp
  { pre := [(1, 0xFFFFFFFF), (2, 0xFFFFFFFE), (3, 0x80000000), (4, 0xDFE1564C), (5, 0xFFFFFFFE), (6, 0x0000009E), (7, 0x000000EA), (8, 0x80000000), (9, 0x22DF5EBF), (10, 0x00000001), (11, 0x00000090), (12, 0x00002463), (13, 0x00000001), (14, 0x8A569E51), (15, 0x00000002), (16, 0x00000001), (17, 0x80000000), (18, 0x7FFFFFFF), (19, 0x00000002), (20, 0x00000002), (21, 0x80000000), (22, 0x0000E06D), (23, 0x0000D356), (24, 0x80000000), (25, 0xFFFFFFFE), (26, 0x57A80D02), (27, 0x7FFFFFFF), (29, 0x00000048), (30, 0xFFFFFFFF), (31, 0xFFFFFFFF)], pc := 0x800000A0, word := 0x0157A7B3,
    post := [(15, 0x00000000)], pc' := 0x800000A4 },   -- slt     a5, a5, s5
  { pre := [(1, 0x80000000), (2, 0x7FFFFFFF), (3, 0x80000000), (4, 0x00000004), (5, 0x00000001), (6, 0x7FFFFFFF), (7, 0x0000937B), (8, 0x7FFFFFFF), (9, 0xD79D3941), (11, 0xFFFFFFFE), (12, 0x000000CD), (13, 0x0000005F), (14, 0x00000001), (15, 0x80000000), (16, 0x000000F4), (17, 0x80000000), (18, 0x00004472), (19, 0x80000000), (20, 0x00000001), (21, 0x830F7326), (22, 0x0000005B), (23, 0x00000001), (24, 0xFFFFFFFF), (25, 0x0000B5A2), (26, 0x0000008D), (27, 0x24EA04CB), (28, 0xEDFFFDA8), (29, 0x00000001), (30, 0x9D1159AC), (31, 0x00000001)], pc := 0x800000A8, word := 0x01178263,
    post := [], pc' := 0x800000AC },   -- beq     a5, a7, pc + 4
  { pre := [(3, 0x0000E17E), (4, 0x14ABFCCE), (6, 0x80000000), (7, 0x00000001), (8, 0xFFFFFFFF), (9, 0xFFFFFFFE), (10, 0x38020425), (11, 0x5B0A2193), (12, 0x000063E0), (14, 0xA1D30E36), (15, 0x00000001), (16, 0x7FFFFFFF), (17, 0x00000002), (18, 0x330978F0), (19, 0x0000009E), (20, 0x3AEE3298), (21, 0x00000002), (22, 0x00000001), (23, 0x00000001), (24, 0xFFFFFFFF), (25, 0x7FFFFFFF), (26, 0x000000FC), (27, 0x00003E54), (28, 0x00000060), (29, 0xFFFFFFFE), (30, 0x00000002), (31, 0x00000002)], pc := 0x800000A8, word := 0x018C8CB3,
    post := [(25, 0x7FFFFFFE)], pc' := 0x800000AC },   -- add     s9, s9, s8
  { pre := [(1, 0x00000002), (2, 0xFFFFFFFE), (3, 0x4AB8C418), (4, 0x000000B6), (5, 0x000000F0), (6, 0x00000001), (8, 0xFFFFFFFF), (9, 0x00000065), (11, 0x00000001), (12, 0xA6035D1C), (13, 0xFFFFFFFE), (14, 0x00000001), (15, 0x3A847B14), (16, 0x00000071), (17, 0x000000DB), (18, 0x80000000), (19, 0x727F16C4), (20, 0x7FFFFFFF), (21, 0xFFFFFFFF), (22, 0x00000002), (24, 0x00000001), (25, 0x91F94E6C), (26, 0xFFFFFFFE), (27, 0x72EC61E9), (28, 0x00000001), (29, 0x7FFFFFFF), (31, 0x00000002)], pc := 0x8000009C, word := 0x473F0C93,
    post := [(25, 0x00000473)], pc' := 0x800000A0 },   -- addi    s9, t5, 1139
  { pre := [(1, 0x00000002), (2, 0x00000001), (3, 0xFFFFFFFE), (4, 0x0000C8AA), (5, 0x000097FC), (6, 0xD65F8F15), (7, 0x00000001), (8, 0x000062CA), (9, 0x00000069), (10, 0x00000002), (11, 0xFFFFFFFE), (12, 0x80000000), (13, 0x434F0064), (14, 0x00000001), (15, 0x80000000), (16, 0x7FFFFFFF), (17, 0x000000AD), (18, 0x0000405D), (19, 0x80000000), (20, 0x000053B0), (21, 0x0000F815), (22, 0x00000001), (23, 0x00000001), (24, 0x00000001), (25, 0x7FFFFFFF), (26, 0x00000001), (27, 0x7FFFFFFF), (28, 0x0000AF83), (29, 0xAD496DBD), (30, 0xFFFFFFFF), (31, 0xACCC8A50)], pc := 0x800000B4, word := 0x018E4533,
    post := [(10, 0x0000AF82)], pc' := 0x800000B8 },   -- xor     a0, t3, s8
  { pre := [(1, 0x80000000), (2, 0x80000000), (3, 0x00000002), (4, 0x00002ADF), (5, 0xA08AF4D4), (6, 0x00000002), (8, 0x00000050), (9, 0xFFFFFFFE), (10, 0x00000002), (11, 0x7FFFFFFF), (12, 0x80000000), (13, 0x7FFFFFFF), (14, 0x559FBAC4), (15, 0xF36E5C21), (16, 0xFFFFFFFF), (17, 0xAD2C0443), (18, 0x00000002), (19, 0x00007A3F), (20, 0xA229CA98), (21, 0xFFFFFFFE), (22, 0xFC2E8882), (23, 0xFFFFFFFE), (24, 0x000076C0), (25, 0x00000001), (26, 0x2D8BC77C), (27, 0x00002342), (28, 0x00000002), (29, 0x80000000), (30, 0x00000002), (31, 0x00000001)], pc := 0x800000B0, word := 0x0060A0B3,
    post := [(1, 0x00000001)], pc' := 0x800000B4 },   -- slt     ra, ra, t1
  { pre := [(1, 0x00000002), (2, 0x80000000), (3, 0x000000F4), (4, 0x00000002), (5, 0xFFFFFFFF), (6, 0x0000283C), (7, 0x5E41C7C8), (8, 0xFFFFFFFE), (9, 0x80000000), (10, 0x80000000), (11, 0x0000E877), (12, 0x00000002), (13, 0x7F6E4A1D), (14, 0x80000000), (16, 0x7FFFFFFF), (17, 0x304E5544), (18, 0x00000001), (20, 0xFFFFFFFF), (21, 0xFFFFFFFF), (22, 0xE42FC5E2), (23, 0xFFFFFFFF), (24, 0x00000001), (25, 0x66E1C999), (27, 0xFFFFFFFF), (28, 0x00000002), (31, 0x00000002)], pc := 0x8000009C, word := 0x03108063,
    post := [], pc' := 0x800000A0 },   -- beq     ra, a7, pc + 32
  { pre := [(1, 0x00000041), (2, 0x000000F7), (3, 0x0000003B), (5, 0x000085A5), (6, 0x00000002), (7, 0x00000001), (8, 0x0000463D), (10, 0x7FFFFFFF), (11, 0x7FFFFFFF), (12, 0x80000000), (13, 0x00000001), (14, 0xD95A57B5), (15, 0xD9C7331F), (16, 0x00000001), (17, 0xFFFFFFFF), (18, 0x0000EAA6), (19, 0xFFFFFFFE), (20, 0x00000002), (21, 0x00000001), (22, 0xFFFFFFFE), (23, 0x6DA8965C), (24, 0x00000002), (25, 0xFFFFFFFE), (26, 0x80000000), (27, 0x7FFFFFFF), (28, 0x00000005), (29, 0x00000001), (30, 0x00000002), (31, 0x12B8572E)], pc := 0x800000A4, word := 0x004581B3,
    post := [(3, 0x7FFFFFFF)], pc' := 0x800000A8 },   -- add     gp, a1, tp
  { pre := [(1, 0x00009573), (2, 0x00000002), (3, 0xFFFFFFFE), (4, 0xFFFFFFFF), (6, 0xFFFFFFFF), (7, 0x0000EC0F), (8, 0x00000002), (9, 0x0000004B), (10, 0x7FFFFFFF), (11, 0x0000009A), (12, 0x00000001), (14, 0xFFFFFFFF), (15, 0x80000000), (16, 0x80000000), (17, 0xFFFFFFFE), (18, 0x00000001), (19, 0x00000046), (20, 0xFFFFFFFE), (21, 0xFFFFFFFF), (22, 0x180F78C9), (23, 0x00000002), (24, 0xFFFFFFFF), (25, 0x0000B3B4), (26, 0x3AEB5185), (27, 0xFFFFFFFF), (28, 0x00000077), (29, 0x7FFFFFFF), (30, 0x7FFFFFFF), (31, 0x7FFFFFFF)], pc := 0x800000A0, word := 0x00028D93,
    post := [(27, 0x00000000)], pc' := 0x800000A4 },   -- mv      s11, t0
  { pre := [(1, 0x993A6277), (2, 0x80000000), (3, 0x101972CE), (4, 0x05216B4C), (5, 0xFFFFFFFE), (7, 0x0000002A), (8, 0x529F89E1), (9, 0x80000000), (10, 0x00000002), (11, 0x00002A56), (12, 0x5B8F494F), (13, 0xFFFFFFFE), (14, 0xFFFFFFFE), (15, 0xD166BD5C), (16, 0xE76040EA), (17, 0x00000002), (18, 0xFFFFFFFE), (19, 0x3E4BC31A), (20, 0x00000002), (21, 0xCCF1E4AE), (22, 0xC7ADF301), (23, 0x7FFFFFFF), (24, 0xFFFFFFFF), (25, 0xFFFFFFFE), (26, 0x00000002), (27, 0xFFFFFFFF), (28, 0x819F22FE), (29, 0xFFFFFFFF), (30, 0xFFFFFFFF)], pc := 0x800000B0, word := 0x01BBCBB3,
    post := [(23, 0x80000000)], pc' := 0x800000B4 },   -- xor     s7, s7, s11
  { pre := [(1, 0x7FE7E710), (2, 0x00004343), (3, 0x71691D28), (4, 0xBF9F419F), (5, 0x1CEAB201), (6, 0x80000000), (7, 0x00000002), (8, 0x901DDD8C), (9, 0xE344C298), (10, 0x00000001), (11, 0x7FFFFFFF), (12, 0x00000062), (13, 0x7FFFFFFF), (14, 0x000000B9), (16, 0x0000715E), (17, 0xFFFFFFFF), (18, 0xFFFFFFFF), (19, 0x00007CEF), (20, 0x000000C9), (21, 0x00000001), (22, 0x9F0FDAD2), (23, 0x00000034), (24, 0x00000002), (25, 0xA7B0C4FB), (27, 0x296257D1), (28, 0x00000001), (30, 0xEA6DE533), (31, 0x00008BE8)], pc := 0x800000BC, word := 0x000AA1B3,
    post := [(3, 0x00000000)], pc' := 0x800000C0 },   -- slt     gp, s5, zero
  { pre := [(1, 0xE2AA0E91), (3, 0x0000BAF2), (4, 0x0000007C), (5, 0x00000002), (6, 0x7FFFFFFF), (7, 0x80000000), (8, 0x80000000), (11, 0x7FFFFFFF), (12, 0x00000002), (13, 0xFFFFFFFF), (14, 0x00000002), (15, 0x000000D2), (18, 0x80000000), (19, 0x00000002), (21, 0x80000000), (22, 0x0000F49F), (23, 0x0000225F), (24, 0xFFFFFFFE), (25, 0x00000007), (26, 0x00000005), (27, 0xFFFFFFFF), (28, 0xFFFFFFFE), (29, 0x80000000), (30, 0x00000035), (31, 0x00000002)], pc := 0x80000094, word := 0x00898863,
    post := [], pc' := 0x80000098 },   -- beq     s3, s0, pc + 16
  { pre := [(1, 0x7D02BBAC), (2, 0x00009AD8), (3, 0xFFFFFFFF), (4, 0x0000006D), (5, 0x00000002), (6, 0x1A2E832E), (7, 0x0000001B), (8, 0x7FFFFFFF), (10, 0x0000C286), (11, 0xE7AD3CF0), (12, 0x7FFFFFFF), (13, 0x0000BE50), (14, 0x00000002), (15, 0x00000002), (16, 0x00000041), (17, 0x00001E53), (18, 0x00000001), (19, 0x00000001), (20, 0x00001A2F), (21, 0xFFFFFFFF), (22, 0x80000000), (23, 0x00000002), (24, 0x00000001), (25, 0x000000D4), (26, 0x00000002), (27, 0x00000001), (28, 0x0000008D), (29, 0x00000001), (30, 0xFFFFFFFE), (31, 0x9ACAECD0)], pc := 0x800000A8, word := 0x01DF8933,
    post := [(18, 0x9ACAECD1)], pc' := 0x800000AC },   -- add     s2, t6, t4
  { pre := [(1, 0x0000ECC0), (2, 0x00000001), (3, 0xFFFFFFFF), (4, 0x00000002), (5, 0x76D62ED0), (6, 0x00000001), (7, 0x00000002), (8, 0x00000002), (10, 0x00000001), (11, 0x0000003C), (12, 0x000000F7), (13, 0x80000000), (14, 0x00000001), (15, 0x532EACFE), (16, 0x80000000), (17, 0x0000B089), (18, 0x00006B36), (19, 0x00000001), (20, 0x7FFFFFFF), (22, 0x1EB2379C), (23, 0xFFFFFFFF), (24, 0xFFFFFFFF), (25, 0x00000001), (26, 0x00000002), (27, 0x00000002), (29, 0xFFFFFFFF), (30, 0x80000000), (31, 0x00000002)], pc := 0x80000098, word := 0xF6C78793,
    post := [(15, 0x532EAC6A)], pc' := 0x8000009C },   -- addi    a5, a5, -148
  { pre := [(1, 0xFFFFFFFF), (2, 0x00000001), (3, 0x00009387), (4, 0x7FFFFFFF), (5, 0x80000000), (6, 0xD1FDFC97), (7, 0x00000002), (8, 0x00005812), (9, 0x7B9F3792), (10, 0x0000B68C), (11, 0x7FFFFFFF), (12, 0x7FFFFFFF), (13, 0xFFFFFFFE), (14, 0xCF85079A), (15, 0x17AD74D7), (16, 0x8331A7E9), (17, 0x7FFFFFFF), (18, 0xE26D11CE), (19, 0x7FFFFFFF), (20, 0x000000A5), (21, 0x00000030), (22, 0x00000002), (23, 0x96BFB0BE), (24, 0x00008A7C), (25, 0x0000001D), (26, 0x00000002), (27, 0x80000000), (28, 0x000000B5), (29, 0x00000001), (30, 0xFFFFFFFE), (31, 0x84E7D971)], pc := 0x800000C0, word := 0x004FC4B3,
    post := [(9, 0xFB18268E)], pc' := 0x800000C4 },   -- xor     s1, t6, tp
  { pre := [(1, 0x00000002), (2, 0x80000000), (3, 0x7FFFFFFF), (4, 0x80000000), (5, 0x08715AF8), (6, 0xFFFFFFFE), (7, 0x00000001), (8, 0x10E94DDD), (9, 0x00000002), (10, 0x68D37454), (11, 0x80000000), (12, 0x5021E804), (13, 0xFFFFFFFE), (15, 0x5427D7DC), (16, 0x00000002), (17, 0x7FFFFFFF), (18, 0x000000DF), (19, 0x00000002), (20, 0x14D83139), (21, 0x000009C6), (22, 0x7FFFFFFF), (23, 0x0000316B), (24, 0xFFFFFFFF), (26, 0x00003B2E), (27, 0x00000001), (29, 0x00000001), (30, 0x00000002), (31, 0x00000001)], pc := 0x800000AC, word := 0x00EA23B3,
    post := [(7, 0x00000000)], pc' := 0x800000B0 },   -- slt     t2, s4, a4
  { pre := [(1, 0x00000002), (2, 0x7FFFFFFF), (3, 0x80000000), (4, 0x10CED6DF), (5, 0x00000002), (6, 0x00000049), (7, 0x00000083), (8, 0x00000685), (9, 0x7FFFFFFF), (10, 0x98381118), (11, 0x0000004F), (12, 0x00000030), (14, 0xFFFFFFFF), (15, 0x00000044), (16, 0x00009849), (17, 0x00000038), (18, 0xFFFFFFFE), (19, 0x80000000), (20, 0x0000005A), (21, 0x658A7A76), (22, 0xFFFFFFFF), (24, 0x98381118), (25, 0x80000000), (26, 0x0000B1EA), (27, 0x000009B9), (28, 0x7FFFFFFF), (29, 0x00000002), (30, 0x7FFFFFFF), (31, 0x489BCFEE)], pc := 0x800000AC, word := 0x02AC0063,
    post := [], pc' := 0x800000CC },   -- beq     s8, a0, pc + 32
  { pre := [(1, 0xFFFFFFFF), (2, 0xD7578DE5), (3, 0xA5EE9CCA), (4, 0x80000000), (5, 0x00000002), (6, 0x00000002), (7, 0x00004E00), (8, 0x80000000), (9, 0x00000001), (10, 0x00000001), (11, 0x0000035B), (12, 0xFFFFFFFE), (13, 0x0000001B), (14, 0x00000010), (15, 0x65B71A5A), (17, 0xFFFFFFFE), (18, 0x0000004D), (19, 0xFFFFFFFF), (20, 0xFFFFFFFF), (21, 0x000000D2), (22, 0x7FFFFFFF), (23, 0xFFFFFFFE), (24, 0xFFFFFFFE), (25, 0x80000000), (26, 0x00000002), (27, 0x80000000), (28, 0x000000AE), (29, 0x7FFFFFFF), (30, 0x80000000), (31, 0x00007A36)], pc := 0x80000098, word := 0x00978033,
    post := [], pc' := 0x8000009C },   -- add     zero, a5, s1
  { pre := [(1, 0x7FFFFFFF), (2, 0x7FFFFFFF), (3, 0x00000002), (4, 0x0000019E), (5, 0x80000000), (6, 0x0000004F), (7, 0x000022F9), (8, 0x00002D5C), (9, 0xFFFFFFFF), (10, 0xFFFFFFFE), (11, 0x00009DC7), (12, 0xFFFFFFFE), (13, 0x7FFFFFFF), (14, 0x80000000), (16, 0x46F45073), (17, 0x0000A2B7), (18, 0x00000002), (19, 0xFCBE9B79), (20, 0xFAF84398), (21, 0x000000E5), (22, 0x00000002), (23, 0x00000002), (24, 0xFFFFFFFF), (25, 0x13029CAD), (26, 0x0EDC0C6E), (27, 0x00000001), (28, 0xFFFFFFFE), (29, 0x80000000), (30, 0x7FFFFFFF), (31, 0x993FB8F3)], pc := 0x800000B4, word := 0x00190913,
    post := [(18, 0x00000003)], pc' := 0x800000B8 },   -- addi    s2, s2, 1
  { pre := [(1, 0x00000002), (2, 0x00000002), (3, 0x000000E3), (4, 0x6E7EE59B), (5, 0x80000000), (6, 0x00000002), (7, 0xBA9DBD23), (8, 0x7FFFFFFF), (9, 0x00000001), (10, 0x00009D7D), (11, 0x000000E8), (12, 0x00000002), (13, 0xA265D70E), (14, 0x3E93ED5B), (15, 0x9EE1B7B8), (17, 0x80000000), (18, 0x000000E7), (20, 0x00000002), (21, 0xE913B9EB), (22, 0x00007B68), (23, 0x00000001), (24, 0x00000001), (25, 0x7FFFFFFF), (26, 0xFFFFFFFF), (27, 0x000000D0), (28, 0x7FFFFFFF), (29, 0x87F75C24), (30, 0x7FFFFFFF), (31, 0x000000DD)], pc := 0x800000B0, word := 0x0004C4B3,
    post := [], pc' := 0x800000B4 },   -- xor     s1, s1, zero
  { pre := [(1, 0x00000002), (3, 0x060F43C4), (4, 0x0000716B), (5, 0xB030BF1C), (6, 0xFFFFFFFE), (7, 0x000000C2), (8, 0x00007E86), (9, 0x00000001), (11, 0x00005AD5), (12, 0x0000A26E), (13, 0x00000001), (14, 0x7FFFFFFF), (15, 0x00000002), (16, 0x00000001), (17, 0xFFFFFFFF), (18, 0x00000002), (19, 0x83CE968E), (20, 0x00002B6C), (21, 0x00000001), (22, 0x80000000), (24, 0x2066F4AD), (25, 0x7FFFFFFF), (26, 0xFFFFFFFF), (27, 0x80000000), (28, 0x7FFFFFFF), (29, 0x0000966E), (30, 0x00000001), (31, 0x62A3CEF4)], pc := 0x800000B4, word := 0x0012ABB3,
    post := [(23, 0x00000001)], pc' := 0x800000B8 },   -- slt     s7, t0, ra
  { pre := [(1, 0xBE708E3E), (2, 0x0000006E), (3, 0x00000002), (4, 0xFFFFFFFF), (5, 0x000000E7), (6, 0xFFFFFFFE), (7, 0xFFFFFFFE), (9, 0xC9B0E528), (10, 0x00000002), (11, 0xFFFFFFFF), (12, 0x00000002), (13, 0x7FFFFFFF), (14, 0x000038EA), (15, 0x00000001), (16, 0x80000000), (17, 0x000000CD), (18, 0xC9D27BF8), (19, 0x80000000), (20, 0xFFFFFFFE), (21, 0x00000067), (22, 0x83F29A98), (23, 0x80000000), (25, 0xFFFFFFFE), (26, 0x00000002), (27, 0x7FFFFFFF), (28, 0xADD27E55), (29, 0x7FFFFFFF), (30, 0x80000000), (31, 0xE7E7F4D0)], pc := 0x800000A4, word := 0x00B20263,
    post := [], pc' := 0x800000A8 },   -- beq     tp, a1, pc + 4
  { pre := [(1, 0x00000001), (2, 0x00000021), (3, 0x5C20602F), (4, 0xFFFFFFFF), (5, 0x9EE3047D), (7, 0x00007044), (8, 0x00000001), (9, 0x80000000), (10, 0x7FFFFFFF), (11, 0x80000000), (12, 0x0000B4DC), (13, 0x00000001), (14, 0x368B23DC), (15, 0x00000001), (16, 0xFFFFFFFE), (18, 0x80000000), (19, 0x7FFFFFFF), (20, 0x00000002), (21, 0xFFFFFFFF), (23, 0x59FD64D7), (24, 0xFFFFFFFE), (25, 0x000000BE), (26, 0x00000002), (27, 0x00003AAE), (28, 0x00000002), (30, 0xFFFFFFFE), (31, 0x00000002)], pc := 0x800000A0, word := 0x01270B33,
    post := [(22, 0xB68B23DC)], pc' := 0x800000A4 },   -- add     s6, a4, s2
  { pre := [(1, 0xDA0C9FF2), (2, 0x0000005A), (3, 0x7FFFFFFF), (4, 0x00000007), (5, 0x00000001), (6, 0x80000000), (7, 0xFFFFFFFE), (8, 0x80000000), (9, 0x00000001), (10, 0x0000EE87), (11, 0x00000002), (13, 0x0000DE26), (14, 0x7FFFFFFF), (15, 0x7FFFFFFF), (16, 0xFFFFFFFE), (17, 0xFFFFFFFE), (18, 0x00000007), (19, 0xFFFFFFFE), (20, 0x00000002), (21, 0x0000C3A1), (22, 0x0000F652), (23, 0x80000000), (24, 0xA6C11E35), (25, 0x7FFFFFFF), (26, 0xC03898F3), (27, 0x00000002), (28, 0x00000008), (29, 0x80000000), (30, 0x00000002), (31, 0x00000002)], pc := 0x800000A8, word := 0xBA1E8A13,
    post := [(20, 0x7FFFFBA1)], pc' := 0x800000AC },   -- addi    s4, t4, -1119
  { pre := [(1, 0xFFFFFFFF), (2, 0xFFFFFFFE), (3, 0x1826F527), (4, 0x0000006A), (5, 0x00000001), (6, 0xFFFFFFFE), (7, 0xFFFFFFFE), (9, 0xF45AEEFE), (10, 0x495B6FDB), (12, 0x80000000), (13, 0x00000001), (15, 0x00000002), (16, 0x00000001), (17, 0x0000B2CD), (19, 0x00000002), (21, 0x00008C23), (22, 0xFFFFFFFE), (23, 0xFFFFFFFE), (24, 0x00000077), (25, 0x674F098F), (26, 0x00000001), (27, 0xFFFFFFFE), (28, 0x00000001), (30, 0x7FFFFFFF), (31, 0x00000001)], pc := 0x80000098, word := 0x00DD4D33,
    post := [(26, 0x00000000)], pc' := 0x8000009C },   -- xor     s10, s10, a3
  { pre := [(1, 0x00000001), (2, 0xFFFFFFFF), (3, 0x50700106), (5, 0x56225CE0), (6, 0x499168FA), (7, 0x0000ED69), (8, 0x00000001), (9, 0x7FFFFFFF), (10, 0xFFFFFFFF), (11, 0x7FFFFFFF), (12, 0xFFFFFFFF), (13, 0x80000000), (14, 0x00006E5F), (15, 0xFFFFFFFF), (16, 0xFFFFFFFF), (17, 0x0000C98E), (18, 0xFFFFFFFF), (19, 0x7FFFFFFF), (20, 0xB66F377A), (21, 0xE6C47AEC), (22, 0xFFFFFFFF), (23, 0xFFFFFFFE), (24, 0xFFFFFFFE), (25, 0x00000001), (26, 0x80000000), (27, 0x0000008E), (28, 0x00000002), (29, 0xFFFFFFFE), (30, 0x00000002), (31, 0x05AD3F16)], pc := 0x800000AC, word := 0x0104A033,
    post := [], pc' := 0x800000B0 },   -- slt     zero, s1, a6
  { pre := [(1, 0x00000002), (3, 0x7FFFFFFF), (4, 0xB9B5EDA9), (5, 0xFFFFFFFE), (6, 0x00000002), (7, 0x403B2637), (8, 0xFFFFFFFF), (9, 0x7FFFFFFF), (10, 0x01F38B25), (11, 0xFFFFFFFF), (12, 0x00000012), (13, 0xFFFFFFFF), (14, 0xFFFFFFFE), (16, 0x7FFFFFFF), (17, 0xFFFFFFFF), (18, 0x00000059), (19, 0x000083C0), (21, 0x000000C1), (23, 0x00000002), (24, 0x00000001), (25, 0x7FFFFFFF), (26, 0x00000001), (27, 0x1F5D13CC), (28, 0x0000A22A), (29, 0x72BD92D0), (30, 0xE5800A73), (31, 0x00004183)], pc := 0x800000B0, word := 0x03EF8063,
    post := [], pc' := 0x800000B4 },   -- beq     t6, t5, pc + 32
  { pre := [(1, 0x7FFFFFFF), (2, 0x0000AB9C), (3, 0x5AEF3287), (5, 0x00000001), (6, 0x8211375E), (7, 0x0000007D), (8, 0x0000E281), (9, 0x00000001), (10, 0x7FFFFFFF), (11, 0xFFFFFFFE), (12, 0xFFFFFFFE), (13, 0x0000F793), (14, 0x00000001), (15, 0x00000079), (16, 0x00001288), (17, 0xFFFFFFFF), (18, 0xD4986C9E), (19, 0xFFFFFFFE), (20, 0x00008D55), (21, 0x80000000), (22, 0x00009230), (23, 0xC5EC4AA7), (24, 0x80000000), (25, 0x00000002), (26, 0x00009ED0), (27, 0xEFDA05E9), (28, 0x7467827C), (29, 0x00000073), (30, 0x00000001), (31, 0x00000001)], pc := 0x800000B8, word := 0x00FA0A33,
    post := [(20, 0x00008DCE)], pc' := 0x800000BC },   -- add     s4, s4, a5
  { pre := [(2, 0x80000000), (3, 0xEA6832E1), (4, 0x000051F9), (5, 0x00003E7A), (6, 0x00000010), (7, 0x25645441), (8, 0xAA79B605), (9, 0x30AB87C9), (10, 0x7FFFFFFF), (11, 0xFFFFFFFF), (12, 0x00000002), (13, 0x0000002E), (14, 0xCAA9C24E), (15, 0x682D6767), (16, 0x7FFFFFFF), (18, 0xFFFFFFFF), (19, 0x00006626), (20, 0x0000004E), (22, 0x000000A2), (23, 0xFFFFFFFE), (24, 0x0000D7BF), (25, 0xD3BE986D), (26, 0x0000ADAF), (27, 0x80000000), (29, 0x00000002), (30, 0x0000005E), (31, 0x0000005B)], pc := 0x800000B4, word := 0x000B0093,
    post := [(1, 0x000000A2)], pc' := 0x800000B8 },   -- mv      ra, s6
  { pre := [(1, 0x00000002), (2, 0x000073B5), (3, 0xA2901E9E), (4, 0x0000693C), (5, 0x0000002B), (6, 0xFFFFFFFE), (7, 0x1271E39D), (8, 0x00007868), (9, 0x000000C6), (10, 0x80000000), (11, 0x80000000), (12, 0x80000000), (13, 0x7FFFFFFF), (14, 0x7FFFFFFF), (15, 0xFFFFFFFF), (17, 0xC873D498), (18, 0xAC8B3406), (19, 0x2BD67DA5), (20, 0xFFFFFFFE), (21, 0xD671BB60), (24, 0xFFFFFFFE), (25, 0x00000002), (26, 0x00000001), (27, 0x00000001), (29, 0xFFFFFFFF), (30, 0xFFFFFFFF), (31, 0x7FFFFFFF)], pc := 0x800000AC, word := 0x00184033,
    post := [], pc' := 0x800000B0 },   -- xor     zero, a6, ra
  { pre := [(1, 0x7FFFFFFF), (2, 0xFFFFFFFE), (3, 0xFFFFFFFE), (4, 0xBA17B38A), (5, 0x7FFFFFFF), (6, 0xFFFFFFFF), (7, 0x8239BCEB), (8, 0xFFFFFFFF), (9, 0x0000D832), (10, 0x80000000), (11, 0x00000002), (12, 0x46E5B289), (13, 0xFFFFFFFF), (14, 0x085E53B1), (15, 0x80000000), (16, 0x00000077), (17, 0x000000BB), (19, 0x00000001), (20, 0x0000083E), (21, 0x74549CE9), (22, 0xFFFFFFFF), (23, 0x7FFFFFFF), (24, 0x00000010), (25, 0x00000001), (26, 0x0000B2F0), (27, 0xB3F7FBAB), (28, 0x8EA64CF9), (29, 0x00000002), (30, 0x7FFFFFFF), (31, 0x7FFFFFFF)], pc := 0x800000B8, word := 0x010E2FB3,
    post := [(31, 0x00000001)], pc' := 0x800000BC },   -- slt     t6, t3, a6
  { pre := [(1, 0x00000001), (2, 0xFFFFFFFF), (3, 0x00000002), (4, 0xFFFFFFFE), (5, 0x0000FD79), (6, 0xFFFFFFFF), (8, 0x013208E3), (9, 0xDE4BB333), (10, 0x7FFFFFFF), (11, 0xFFFFFFFE), (12, 0x00000002), (13, 0x00000002), (14, 0x00000001), (15, 0x00000001), (16, 0x000075F0), (17, 0xFFFFFFFE), (18, 0xAC5CDF1A), (19, 0x0000002C), (20, 0x7CAA2A8B), (21, 0x00000002), (22, 0xFFFFFFFE), (23, 0x7FFFFFFF), (24, 0x80000000), (25, 0x000000E5), (26, 0x00000002), (27, 0x80000000), (28, 0x00000002), (29, 0xFFFFFFFE), (30, 0x0BDA4309), (31, 0x3C2EBA87)], pc := 0x800000A4, word := 0x019C8863,
    post := [], pc' := 0x800000B4 },   -- beq     s9, s9, pc + 16
  { pre := [(1, 0xE9EDF66F), (2, 0x00000002), (3, 0x00000002), (4, 0x00000001), (6, 0x00000002), (7, 0x00000001), (8, 0xBADD5883), (9, 0xCED24E76), (10, 0x00000002), (11, 0xFFFFFFFE), (13, 0x000000CE), (14, 0x000000D7), (15, 0x265555E0), (16, 0x00000001), (17, 0x7FFFFFFF), (18, 0x00000002), (19, 0x80000000), (20, 0xFFFFFFFE), (21, 0x00000002), (22, 0x00000001), (23, 0x80000000), (24, 0x2234111E), (25, 0x00000001), (26, 0x00000004), (27, 0xC91C33AB), (28, 0x00000002), (29, 0x00000002), (30, 0xFD34EE57), (31, 0x00000002)], pc := 0x8000009C, word := 0x008104B3,
    post := [(9, 0xBADD5885)], pc' := 0x800000A0 },   -- add     s1, sp, s0
  { pre := [(1, 0x00000001), (3, 0xF557B568), (4, 0x6C948756), (5, 0x0000C235), (6, 0xFFFFFFFF), (7, 0x7FFFFFFF), (9, 0x80000000), (10, 0x00000001), (12, 0x7FFFFFFF), (13, 0x5ED72800), (14, 0x00008F70), (15, 0x80000000), (16, 0xFFFFFFFF), (17, 0x80000000), (18, 0x7FFFFFFF), (19, 0x00000001), (20, 0xCB256357), (21, 0xFFFFFFFF), (23, 0x00000002), (24, 0x80000000), (25, 0x0000B936), (26, 0xFFFFFFFF), (29, 0xFFFFFFFF), (30, 0xFFFFFFFF), (31, 0x3B80CDA5)], pc := 0x800000A8, word := 0xFFF88513,
    post := [(10, 0x7FFFFFFF)], pc' := 0x800000AC },   -- addi    a0, a7, -1
  { pre := [(1, 0x0000004A), (3, 0x00000002), (5, 0x00000001), (7, 0xFFFFFFFE), (9, 0x000000F1), (11, 0x00000002), (13, 0xFFFFFFFE), (14, 0x954E71C2), (15, 0x7FFFFFFF), (16, 0x0000A8FA), (17, 0x7FFFFFFF), (18, 0xFFFFFFFE), (19, 0x0000D88B), (20, 0x7FFFFFFF), (21, 0xFFFFFFFF), (22, 0x4DF27172), (23, 0x000000F0), (24, 0x9FE40912), (25, 0x68BCB8F6), (26, 0x00000002), (27, 0xFFFFFFFE), (28, 0x000000F4), (29, 0x00000001), (30, 0xDDC00FE7), (31, 0x0000C852)], pc := 0x800000A8, word := 0x0128C8B3,
    post := [(17, 0x80000001)], pc' := 0x800000AC },   -- xor     a7, a7, s2
  { pre := [(1, 0x80000000), (3, 0x7FFFFFFF), (4, 0x00008ABF), (5, 0x58E34231), (6, 0x0000000C), (7, 0x00000004), (8, 0xFFFFFFFF), (9, 0x80000000), (10, 0x7FFFFFFF), (11, 0x00000001), (12, 0xB5BFC66B), (13, 0x00000002), (14, 0x7FFFFFFF), (15, 0xFFFFFFFF), (16, 0x60672A55), (17, 0x00000068), (18, 0x00000002), (19, 0x0000328E), (21, 0xE741DF9B), (22, 0x000013A6), (23, 0x00000002), (24, 0x00000042), (25, 0xB9D2D650), (26, 0xFFFFFFFF), (27, 0x80000000), (28, 0x0000ACA2), (29, 0x80000000), (30, 0x00000002), (31, 0xFFFFFFFF)], pc := 0x800000AC, word := 0x00ABA033,
    post := [], pc' := 0x800000B0 },   -- slt     zero, s7, a0
  { pre := [(1, 0x000000BB), (3, 0x00000002), (4, 0x7FFFFFFF), (5, 0x7FFFFFFF), (6, 0x00000001), (7, 0x00000001), (8, 0x000000AF), (9, 0x0000006E), (10, 0x00000002), (11, 0x7FFFFFFF), (12, 0x00000094), (14, 0x0000009C), (15, 0x80000000), (16, 0x00000003), (17, 0x80000000), (18, 0xFFFFFFFF), (19, 0x000000D7), (20, 0x80000000), (21, 0xFFFFFFFE), (22, 0x00000002), (23, 0x00000042), (24, 0x3C394F1A), (25, 0x80000000), (26, 0x00000001), (27, 0x00000028), (28, 0x00000022), (29, 0x80000000), (30, 0x00000002), (31, 0xFFFFFFFF)], pc := 0x8000008C, word := 0x00A18263,
    post := [], pc' := 0x80000090 },   -- beq     gp, a0, pc + 4
  { pre := [(1, 0x00000002), (2, 0x7FFFFFFF), (3, 0x80000000), (4, 0x80000000), (5, 0x00000002), (6, 0xFFFFFFFE), (7, 0x27F99EAD), (8, 0x7856F6A0), (10, 0x80000000), (11, 0x7FFFFFFF), (12, 0x38C1AD06), (13, 0x00000001), (14, 0x00000001), (15, 0x00000002), (16, 0x7FFFFFFF), (19, 0x7FFFFFFF), (20, 0x80000000), (21, 0x6BE46CC8), (22, 0x0B3AA459), (23, 0x00000025), (24, 0x00000002), (25, 0x00000002), (27, 0xA21D4093), (28, 0xFFFFFFFF), (29, 0x000000A2), (31, 0x80000000)], pc := 0x800000A4, word := 0x005F0033,
    post := [], pc' := 0x800000A8 },   -- add     zero, t5, t0
  { pre := [(1, 0x80C5B800), (2, 0x50033DD6), (3, 0x00000002), (4, 0xFFFFFFFF), (5, 0x000000A6), (6, 0x00000002), (7, 0xFFFFFFFF), (8, 0xFFFFFFFF), (9, 0x00000583), (10, 0x00000061), (11, 0x00000001), (12, 0xFFFFFFFF), (13, 0x0000009C), (14, 0x00000001), (15, 0x000000FD), (17, 0x0000003D), (18, 0x0000A06C), (19, 0x7FFFFFFF), (20, 0x37889883), (21, 0x80000000), (23, 0x802371C2), (24, 0x000099AD), (25, 0xFFFFFFFE), (26, 0x80000000), (27, 0x7FFFFFFF), (28, 0x000000C7), (29, 0x638AEDAE), (30, 0x0000CE86), (31, 0x40C63679)], pc := 0x800000A8, word := 0x7FF00013,
    post := [], pc' := 0x800000AC },   -- li      zero, 2047
  { pre := [(1, 0xFFFFFFFF), (2, 0x0000E5B7), (4, 0xD978A3ED), (6, 0x00000002), (8, 0xFFFFFFFF), (9, 0x00000002), (10, 0x00000001), (11, 0x4F6F6380), (12, 0xFFFFFFFF), (13, 0x00000001), (14, 0x80000000), (15, 0x7FFFFFFF), (16, 0xFFFFFFFE), (18, 0x00000001), (19, 0xFFFFFFFE), (20, 0x80000000), (21, 0x00000001), (22, 0x00000001), (23, 0x00000002), (24, 0x000000D8), (25, 0x31BB85BC), (26, 0xFFFFFFFE), (27, 0x00000001), (28, 0x7FFFFFFF), (29, 0x00000002), (30, 0x00000002), (31, 0x00000001)], pc := 0x80000094, word := 0x011ECAB3,
    post := [(21, 0x00000002)], pc' := 0x80000098 },   -- xor     s5, t4, a7
  { pre := [(1, 0xFFFFFFFF), (2, 0x0000F699), (3, 0x00000002), (4, 0x7FFFFFFF), (5, 0x00000001), (6, 0xFFFFFFFF), (7, 0xFFFFFFFE), (8, 0x116AC2CD), (10, 0x000029DF), (11, 0x00000002), (12, 0x32FF65B4), (13, 0x7FFFFFFF), (14, 0xFFFFFFFF), (15, 0x00000002), (16, 0x00000002), (17, 0x00000001), (18, 0x448823B0), (19, 0xFFFFFFFF), (20, 0x497AFF69), (21, 0x0000CE3B), (22, 0xFFFFFFFE), (23, 0x80000000), (24, 0x00000002), (25, 0x00007211), (26, 0x80000000), (27, 0x00000002), (28, 0xB922C234), (29, 0xFFFFFFFE), (31, 0x80000000)], pc := 0x800000A8, word := 0x01E3AF33,
    post := [(30, 0x00000001)], pc' := 0x800000AC },   -- slt     t5, t2, t5
  { pre := [(1, 0x00000001), (2, 0xFFFFFFFE), (3, 0x8AC309E7), (5, 0x00000001), (6, 0xFFFFFFFF), (7, 0x2D799CC5), (8, 0x00000002), (9, 0x0291514F), (10, 0x7FFFFFFF), (11, 0x00000001), (12, 0x80000000), (13, 0xFFFFFFFE), (14, 0x0000545E), (15, 0x00000002), (16, 0xFFFFFFFE), (17, 0x88CE049E), (18, 0x00000029), (19, 0x80000000), (20, 0x00000001), (21, 0x36306994), (22, 0x1384699F), (23, 0x00000001), (24, 0x7FFFFFFF), (25, 0xA53EB6A1), (26, 0x00000001), (27, 0x7FFFFFFF), (28, 0x0000003C), (29, 0x10D804D6), (30, 0x00008974)], pc := 0x800000B0, word := 0x03F00063,
    post := [], pc' := 0x800000D0 },   -- beq     zero, t6, pc + 32
  { pre := [(1, 0xFFFFFFFE), (2, 0x7FFFFFFF), (3, 0xF2F24787), (6, 0x00000063), (7, 0x00004357), (8, 0xFFFFFFFF), (9, 0x00000034), (10, 0xCF3C303F), (11, 0x00000001), (12, 0x000000D1), (13, 0x00007394), (14, 0xFFFFFFFF), (15, 0x000000B3), (16, 0x00000002), (17, 0x000000CD), (18, 0x00008B48), (19, 0x00000002), (20, 0x7FFFFFFF), (21, 0xFFFFFFFE), (22, 0xFFFFFFFE), (23, 0x80000000), (24, 0x00008980), (25, 0x00000002), (26, 0x00000001), (27, 0x0000063B), (29, 0xFFFFFFFE), (30, 0x00000001), (31, 0x80000000)], pc := 0x8000009C, word := 0x005387B3,
    post := [(15, 0x00004357)], pc' := 0x800000A0 },   -- add     a5, t2, t0
  { pre := [(1, 0xFFFFFFFE), (2, 0x7FFFFFFF), (3, 0x0000005E), (4, 0x00000001), (5, 0x00000001), (6, 0x000000D3), (7, 0xFFFFFFFF), (8, 0xFFFFFFFF), (9, 0x00000002), (10, 0xD3121317), (11, 0x000000CB), (12, 0xFFFFFFFE), (13, 0xFFFFFFFE), (14, 0xFFFFFFFE), (15, 0x00002396), (16, 0x3F4CF738), (17, 0xFFFFFFFE), (18, 0xFFFFFFFE), (19, 0x80000000), (20, 0x80000000), (21, 0x00000001), (22, 0x7FFFFFFF), (23, 0xE9D8C77C), (24, 0xFFFFFFFF), (25, 0x830049F7), (26, 0xFFFFFFFF), (27, 0x7FFFFFFF), (28, 0x00000001), (29, 0xFFFFFFFF), (30, 0x000000ED)], pc := 0x8000009C, word := 0x7FF18193,
    post := [(3, 0x0000085D)], pc' := 0x800000A0 },   -- addi    gp, gp, 2047
  { pre := [(1, 0x7FFFFFFF), (2, 0xEFED77FA), (3, 0x00006964), (4, 0x80000000), (5, 0xAD142409), (6, 0x00000001), (7, 0xFFFFFFFF), (8, 0x000000D7), (9, 0x80000000), (10, 0x0000005F), (11, 0xD7C3853B), (12, 0x7FFFFFFF), (13, 0x00000041), (14, 0x224748EB), (15, 0x672407AC), (16, 0x338FEE57), (17, 0x7FFFFFFF), (18, 0x00000002), (19, 0x00000001), (20, 0x7FFFFFFF), (21, 0x0000007A), (22, 0x0E033AB8), (23, 0x00000002), (24, 0x22A75E18), (25, 0x0000B91E), (26, 0xFFFFFFFE), (27, 0x7FFFFFFF), (29, 0x7FFFFFFF), (30, 0xFFFFFFFE), (31, 0xFFFFFFFE)], pc := 0x800000BC, word := 0x00334533,
    post := [(10, 0x00006965)], pc' := 0x800000C0 },   -- xor     a0, t1, gp
  { pre := [(1, 0xEEC4EE75), (2, 0x00000001), (3, 0xF77D6F04), (4, 0x00000002), (5, 0x7FFFFFFF), (7, 0x6CFE0F5B), (8, 0xFFFFFFFF), (9, 0x7FFFFFFF), (10, 0xB4C80AAB), (11, 0xFFFFFFFF), (12, 0xFFFFFFFF), (13, 0x00000002), (14, 0xFFFFFFFF), (15, 0xFFFFFFFE), (16, 0x00006629), (17, 0x00000002), (18, 0x000000DC), (20, 0x95C19F0D), (21, 0xFFFFFFFE), (22, 0xC2BD5975), (23, 0x7FFFFFFF), (24, 0x00000002), (25, 0x80000000), (26, 0x13693033), (27, 0x94143EBE), (28, 0xC6F8D21C), (29, 0x92CFBAD4), (30, 0x00000001), (31, 0x00000002)], pc := 0x800000B4, word := 0x00E4A433,
    post := [(8, 0x00000000)], pc' := 0x800000B8 },   -- slt     s0, s1, a4
  { pre := [(1, 0x00000001), (2, 0x00000001), (3, 0x00000001), (5, 0x0000350F), (6, 0x2576C2D3), (7, 0x00000001), (8, 0x00000001), (9, 0x00000001), (10, 0x00000001), (11, 0x73450184), (12, 0xFFFFFFFE), (13, 0x7FFFFFFF), (14, 0x80000000), (15, 0x00000002), (16, 0x0562E294), (17, 0x80000000), (18, 0x7FFFFFFF), (19, 0x00001593), (20, 0x00000001), (21, 0x07A25C10), (22, 0xDCD8CE4C), (23, 0x00000002), (24, 0xFFFFFFFF), (25, 0x7FFFFFFF), (26, 0x00000001), (27, 0x00000001), (28, 0x00000002), (29, 0x7FFFFFFF), (30, 0x00000002), (31, 0xFFFFFFFF)], pc := 0x800000A8, word := 0x03EF0063,
    post := [], pc' := 0x800000C8 },   -- beq     t5, t5, pc + 32
  { pre := [(1, 0xFFFFFFFE), (2, 0x00000002), (3, 0x00000002), (4, 0x7FFFFFFF), (5, 0x00000001), (6, 0x7FFFFFFF), (7, 0xFFFFFFFF), (8, 0x0000B3D0), (10, 0x13F918CD), (11, 0xFFFFFFFE), (13, 0x0000710E), (14, 0x7FFFFFFF), (15, 0x80000000), (16, 0x00000066), (17, 0x00000001), (18, 0x00000039), (19, 0xEF0C6655), (21, 0xB307FF47), (22, 0x00000002), (23, 0xE353F668), (24, 0x00000002), (25, 0xFFFFFFFF), (26, 0x2580CF3F), (27, 0xDE8E0073), (28, 0x7FFFFFFF), (29, 0xFFFFFFFF), (30, 0x0000483E)], pc := 0x800000B0, word := 0x01330CB3,
    post := [(25, 0x6F0C6654)], pc' := 0x800000B4 },   -- add     s9, t1, s3
  { pre := [(1, 0x7FFFFFFF), (2, 0xFFFFFFFE), (3, 0x00000088), (4, 0x00000047), (5, 0x00000002), (6, 0xAF7BDEE4), (7, 0x7FFFFFFF), (9, 0x00000002), (10, 0xFFFFFFFF), (11, 0xFFFFFFFE), (12, 0x7FFFFFFF), (13, 0x7FFFFFFF), (14, 0x8DD5A8AE), (15, 0xFFFFFFFE), (16, 0x30B8F1F8), (17, 0x0000001C), (18, 0xA220EF95), (19, 0x7FFFFFFF), (20, 0x5FB7AAAF), (21, 0x80000000), (22, 0x000000E7), (23, 0x00000001), (24, 0x00000001), (25, 0xFFFFFFFF), (26, 0x7FFFFFFF), (27, 0x56F08F3E), (28, 0x7FFFFFFF), (29, 0x80000000), (30, 0x00000F00), (31, 0x000000F5)], pc := 0x800000B4, word := 0x80000013,
    post := [], pc' := 0x800000B8 },   -- li      zero, -2048
  { pre := [(1, 0x00000002), (2, 0x00000002), (4, 0xFFFFFFFE), (5, 0x2237CD06), (6, 0x00000002), (7, 0x7FFFFFFF), (8, 0x80000000), (9, 0xFFFFFFFE), (10, 0x0000F594), (11, 0x80000000), (12, 0x00000002), (13, 0x000000A4), (14, 0xBB90A904), (15, 0xFFFFFFFE), (16, 0x000000C6), (17, 0x7FFFFFFF), (18, 0x00000002), (19, 0x8C1F8530), (20, 0x2E19BA2C), (21, 0x7FFFFFFF), (22, 0x40FC3B76), (23, 0x3222647F), (24, 0xFFFFFFFF), (25, 0xFFFFFFFE), (26, 0x0000FA3B), (27, 0x7FFFFFFF), (28, 0x7FFFFFFF), (29, 0xD58E8ED8), (30, 0x00000076), (31, 0x7FFFFFFF)], pc := 0x800000B8, word := 0x00DDCDB3,
    post := [(27, 0x7FFFFF5B)], pc' := 0x800000BC },   -- xor     s11, s11, a3
  { pre := [(1, 0xFFFFFFFF), (2, 0xFFFFFFFE), (3, 0xFFFFFFFE), (4, 0x00000001), (5, 0xF336D03B), (6, 0x00000023), (7, 0x0807A9CD), (8, 0x7FFFFFFF), (9, 0x00000002), (10, 0x00000014), (11, 0x0000003F), (12, 0xFFFFFFFE), (13, 0xAFB7BF6A), (14, 0x7FFFFFFF), (15, 0x00000001), (16, 0x00000001), (17, 0xFFFFFFFF), (18, 0x00000002), (19, 0xFF0323A7), (20, 0x80000000), (21, 0x00000002), (22, 0x00000002), (23, 0x00000001), (24, 0x00000002), (26, 0x05D64148), (28, 0x0000004F), (29, 0xFFFFFFFF), (30, 0x6AAF2528), (31, 0x0000C548)], pc := 0x800000A0, word := 0x01B02C33,
    post := [(24, 0x00000000)], pc' := 0x800000A4 },   -- slt     s8, zero, s11
  { pre := [(1, 0xBC1E413D), (2, 0x80000000), (3, 0xFFFFFFFE), (4, 0xFFFFFFFE), (5, 0xFFFFFFFE), (6, 0x00000001), (7, 0xD62CD4E1), (9, 0x80000000), (10, 0xFFFFFFFE), (11, 0xFFFFFFFE), (12, 0x9B5D18AF), (13, 0xAFCC932B), (14, 0x243DBD8D), (15, 0xFFFFFFFE), (16, 0xFFFFFFFE), (17, 0xFFFFFFFE), (18, 0x7FFFFFFF), (19, 0x0000AC2D), (20, 0x7FFFFFFF), (21, 0x00000001), (22, 0x0000A51B), (23, 0x00000002), (24, 0x0000784E), (25, 0x8D4E9C77), (26, 0x7FFFFFFF), (27, 0x00000063), (28, 0x00000001), (29, 0x00000002), (30, 0x80000000), (31, 0xFA0F1C75)], pc := 0x800000B0, word := 0x00F18263,
    post := [], pc' := 0x800000B4 },   -- beq     gp, a5, pc + 4
  { pre := [(1, 0x0000F7DA), (2, 0xFFFFFFFF), (3, 0x0000006C), (4, 0x00000002), (5, 0xFFFFFFFE), (6, 0x7FFFFFFF), (8, 0xFFFFFFFF), (9, 0x00000001), (10, 0x0000915B), (11, 0xBD5B3465), (12, 0x000039A8), (13, 0x000000D3), (14, 0x00000010), (15, 0x0000007F), (16, 0x7C9365B2), (17, 0x00000001), (18, 0xFFFFFFFE), (19, 0xFFFFFFFF), (20, 0x00000087), (21, 0x00000002), (22, 0x7FFFFFFF), (23, 0x0000D03D), (24, 0xF6BCA84A), (25, 0x7FFFFFFF), (26, 0x00000001), (27, 0x80000000), (28, 0xE11F91AA), (29, 0xFFFFFFFF), (30, 0x352B3D02), (31, 0x5F8C7D8D)], pc := 0x800000B0, word := 0x013506B3,
    post := [(13, 0x0000915A)], pc' := 0x800000B4 },   -- add     a3, a0, s3
  { pre := [(1, 0x0000B234), (2, 0xFFFFFFFE), (3, 0x021DDF9B), (4, 0x00000002), (5, 0xC8C41784), (6, 0x00003085), (7, 0x00000002), (8, 0xFFFFFFFF), (9, 0xFFFFFFFE), (10, 0x67572911), (11, 0x2121942D), (12, 0x80000000), (13, 0x00000002), (15, 0x1C36375A), (16, 0x00000001), (17, 0xFFFFFFFE), (18, 0xB1564C00), (19, 0xFFFFFFFF), (20, 0x80000000), (21, 0xF30B6BD0), (22, 0x00000001), (23, 0xFFFFFFFF), (24, 0xFFFFFFFF), (25, 0x00000001), (27, 0x6B8A4493), (28, 0x82879C00), (29, 0x00000002), (30, 0x80000000), (31, 0x00000002)], pc := 0x800000A8, word := 0x000D8093,
    post := [(1, 0x6B8A4493)], pc' := 0x800000AC },   -- mv      ra, s11
  { pre := [(1, 0xFFFFFFFE), (2, 0x7FFFFFFF), (4, 0xFFFFFFFF), (5, 0x54BF311E), (6, 0x000000D9), (7, 0xA0510476), (9, 0x00000002), (10, 0xFFFFFFFF), (11, 0x00000002), (12, 0x0000003A), (13, 0x80000000), (14, 0x00000009), (15, 0x00000002), (16, 0x0000F55C), (18, 0x8B1A1073), (19, 0x00000001), (20, 0x749A8E8C), (21, 0xA9AF1644), (23, 0xFFFFFFFE), (24, 0x00000001), (25, 0x80000000), (26, 0x08CF1A25), (27, 0x00000001), (28, 0xFFFFFFFF), (29, 0xFFFFFFFF), (30, 0x136BE733), (31, 0x00000001)], pc := 0x800000A0, word := 0x01604033,
    post := [], pc' := 0x800000A4 },   -- xor     zero, zero, s6
  { pre := [(1, 0xFFFFFFFE), (2, 0x00000001), (3, 0xFFFFFFFF), (5, 0x7FFFFFFF), (6, 0x80000000), (8, 0xDB786081), (9, 0x80000000), (10, 0x7FFFFFFF), (11, 0x80000000), (12, 0x7FFFFFFF), (14, 0xF6A469E8), (15, 0xFFFFFFFE), (17, 0x5F59DCA1), (18, 0x00000083), (19, 0xFFFFFFFE), (20, 0xFFFFFFFF), (21, 0x7FFFFFFF), (22, 0x00000001), (23, 0x589CEB7C), (24, 0x00000049), (25, 0x7FFFFFFF), (26, 0xFFFFFFFE), (27, 0x00000002), (28, 0xFFFFFFFF), (29, 0xFFFFFFFE), (30, 0x80000000), (31, 0x0000004D)], pc := 0x800000A0, word := 0x00C5A6B3,
    post := [(13, 0x00000001)], pc' := 0x800000A4 },   -- slt     a3, a1, a2
  { pre := [(1, 0x7FFFFFFF), (2, 0x101D4CFD), (3, 0xFFFFFFFF), (4, 0x00000002), (5, 0x7FFFFFFF), (6, 0x7FFFFFFF), (8, 0xFFFFFFFE), (9, 0x80000000), (10, 0x00000002), (11, 0x5D55330A), (12, 0x00000001), (13, 0x00000001), (14, 0x530E7FF7), (15, 0xAB653DFB), (16, 0x7FFFFFFF), (17, 0x000015C5), (20, 0x5B28652C), (21, 0x7FFFFFFF), (22, 0x00005CD5), (24, 0x00000002), (25, 0xFFFFFFFE), (26, 0xFFFFFFFE), (28, 0x00000018), (29, 0x7FFFFFFF), (30, 0x00000002), (31, 0x00005444)], pc := 0x800000B4, word := 0x02D78063,
    post := [], pc' := 0x800000B8 },   -- beq     a5, a3, pc + 32
  { pre := [(1, 0x00000007), (2, 0x6993BF07), (3, 0x07542CFC), (4, 0xFC69F212), (5, 0x7FFFFFFF), (6, 0x000070EA), (7, 0xFFFFFFFE), (8, 0xFFFFFFFF), (9, 0x000000B5), (10, 0x00000067), (11, 0xE22171F2), (12, 0xFFFFFFFF), (14, 0x00000095), (15, 0x00000001), (17, 0x50103CAC), (18, 0xFFFFFFFE), (19, 0x000065A6), (20, 0x00000002), (22, 0x0000007C), (23, 0xF680F283), (24, 0xFFFFFFFF), (25, 0x00000001), (26, 0xFFFFFFFE), (27, 0xFFFFFFFE), (28, 0x00007931), (29, 0x66D9B6A5), (30, 0x00000068), (31, 0xFFFFFFFF)], pc := 0x800000A8, word := 0x00420A33,
    post := [(20, 0xF8D3E424)], pc' := 0x800000AC },   -- add     s4, tp, tp
  { pre := [(1, 0x2D3F51B1), (2, 0x8FAA2E14), (3, 0xFFFFFFFF), (4, 0x00000076), (5, 0x000000C3), (6, 0x000000E0), (7, 0x00001633), (8, 0xFFFFFFFF), (10, 0x7FFFFFFF), (11, 0x91667D5C), (12, 0x0000D574), (13, 0xFFFFFFFE), (15, 0x80000000), (16, 0x80000000), (17, 0x00000007), (18, 0x0000F7C1), (19, 0xFFFFFFFF), (20, 0x00000001), (21, 0xFFFFFFFE), (22, 0x00000087), (23, 0x00000001), (24, 0xE63D557E), (25, 0x00000001), (27, 0x00000001), (29, 0xFFFFFFFE), (30, 0xF55EBADD), (31, 0x00000002)], pc := 0x800000A0, word := 0x7FF10713,
    post := [(14, 0x8FAA3613)], pc' := 0x800000A4 },   -- addi    a4, sp, 2047
  { pre := [(3, 0xFFFFFFFF), (4, 0x0000006C), (5, 0x00000001), (6, 0x00000001), (7, 0xFFFFFFFF), (8, 0xF7617D9F), (9, 0x7FFFFFFF), (10, 0xFFFFFFFE), (12, 0xDBA3C658), (13, 0x00000002), (14, 0x00001D67), (15, 0x00000001), (16, 0x7FFFFFFF), (17, 0x00000002), (18, 0x00000002), (19, 0x0000002D), (20, 0x00000075), (23, 0x00000002), (24, 0x00000043), (26, 0x00005D49), (27, 0xFFFFFFFE), (28, 0xEA08EEE9), (29, 0xFFFFFFFF), (30, 0x00009578), (31, 0x00000001)], pc := 0x8000009C, word := 0x009FC5B3,
    post := [(11, 0x7FFFFFFE)], pc' := 0x800000A0 },   -- xor     a1, t6, s1
  { pre := [(1, 0x00000002), (2, 0x00000001), (3, 0x00000001), (4, 0x00000058), (5, 0x00000010), (6, 0x00000001), (8, 0x0000005E), (9, 0x80000000), (10, 0xFFFFFFFF), (11, 0x41C3A14F), (12, 0x00001293), (13, 0xFFFFFFFE), (15, 0x000058C9), (16, 0xFFFFFFFF), (17, 0x0000CC19), (18, 0x3BD51BFE), (19, 0xFFFFFFFE), (20, 0x00009F9A), (22, 0x7FFFFFFF), (23, 0x083A57D8), (24, 0x29579B1F), (26, 0x00000001), (27, 0x7FFFFFFF), (28, 0x7FFFFFFF), (29, 0x7FFFFFFF), (30, 0x0000443B), (31, 0xFFFFFFFF)], pc := 0x800000B0, word := 0x0069A1B3,
    post := [], pc' := 0x800000B4 },   -- slt     gp, s3, t1
  { pre := [(1, 0x00000002), (2, 0x7FFFFFFF), (3, 0x00000001), (4, 0x0000005C), (5, 0x93FB27CE), (6, 0x00000002), (7, 0x9CE0B7EA), (9, 0x80000000), (10, 0x7FFFFFFF), (11, 0x00000002), (12, 0x183620B8), (14, 0x80000000), (15, 0xFFFFFFFF), (16, 0xFFFFFFFE), (17, 0x94C1D7F8), (18, 0x80000000), (19, 0x80000000), (20, 0xFFFFFFFF), (21, 0x80000000), (22, 0xFFFFFFFE), (23, 0xFFFFFFFF), (24, 0x00000001), (25, 0xE632839F), (26, 0x06961BDF), (27, 0x7FFFFFFF), (28, 0x00000002), (29, 0x0000001F), (30, 0x00000012), (31, 0xFFFFFFFE)], pc := 0x800000A0, word := 0x010B0263,
    post := [], pc' := 0x800000A4 },   -- beq     s6, a6, pc + 4
  { pre := [(2, 0xFFFFFFFF), (3, 0x0000000C), (4, 0xFFFFFFFF), (5, 0x80000000), (6, 0x00008F7D), (7, 0x80000000), (8, 0xFFFFFFFF), (9, 0xFFFFFFFE), (10, 0x000000A5), (11, 0x00000001), (12, 0x7FFFFFFF), (14, 0x40AADECD), (15, 0x00000002), (17, 0xA34A5951), (18, 0x000000B0), (19, 0x00000001), (20, 0xFFFFFFFF), (21, 0x000000D4), (22, 0xFFFFFFFF), (23, 0xFFFFFFFE), (24, 0xDDF8FE0D), (25, 0xFFFFFFFF), (26, 0xFFFFFFFE), (27, 0x0000009A), (28, 0x00000002), (29, 0x80000000), (30, 0x00000001), (31, 0x00000001)], pc := 0x80000090, word := 0x007A8433,
    post := [(8, 0x800000D4)], pc' := 0x80000094 },   -- add     s0, s5, t2
  { pre := [(1, 0xBA630F26), (3, 0x00000001), (4, 0xFFFFFFFF), (5, 0x80000000), (6, 0x00000001), (7, 0x000000BB), (8, 0x00000002), (9, 0x80000000), (11, 0xFFFFFFFF), (12, 0x00000001), (13, 0x680B8B8C), (14, 0x00000001), (15, 0x00000002), (16, 0xFFFFFFFF), (17, 0x0000887B), (18, 0x0000E0DB), (19, 0x74FEB6B5), (20, 0x80000000), (21, 0xFFFFFFFE), (22, 0x5ED8F0D8), (23, 0xB23002B5), (24, 0x7FFFFFFF), (25, 0xFFFFFFFF), (26, 0x00000002), (27, 0x00000002), (28, 0x0000B07D), (29, 0x00000002), (30, 0x3B651747), (31, 0x97314DE2)], pc := 0x800000A8, word := 0x800F0F93,
    post := [(31, 0x3B650F47)], pc' := 0x800000AC },   -- addi    t6, t5, -2048
  { pre := [(1, 0x713CB25F), (2, 0x00000001), (3, 0x00000001), (4, 0x00000001), (5, 0x00000001), (6, 0xFFFFFFFE), (7, 0xE93E1BAC), (8, 0x00000032), (9, 0xFFFFFFFF), (10, 0xFFFFFFFF), (11, 0x00000002), (12, 0x80000000), (13, 0x00009BCB), (14, 0x00000001), (15, 0x80000000), (16, 0x0000B621), (18, 0xFFFFFFFF), (19, 0xFFFFFFFF), (20, 0x7FFFFFFF), (21, 0x00000002), (22, 0x7FFFFFFF), (23, 0x23235747), (25, 0xFFFFFFFF), (26, 0x0000CFC3), (27, 0x00000001), (28, 0x7FFFFFFF), (29, 0x0000C52D), (30, 0x80000000), (31, 0x00000001)], pc := 0x800000A4, word := 0x0192C2B3,
    post := [(5, 0xFFFFFFFE)], pc' := 0x800000A8 },   -- xor     t0, t0, s9
  { pre := [(1, 0xFFFFFFFF), (2, 0xFFFFFFFF), (3, 0x7D38EBAD), (4, 0x80000000), (5, 0x00005637), (6, 0x000000EC), (7, 0xFFFFFFFE), (8, 0x4671D016), (10, 0xFFFFFFFF), (11, 0x7FFFFFFF), (12, 0xFFFFFFFE), (13, 0xDB00B845), (14, 0x00000001), (15, 0xFFFFFFFE), (16, 0x00000045), (17, 0xD4FB67D5), (18, 0xFFFFFFFE), (19, 0x4CAAC97E), (20, 0xFFFFFFFF), (21, 0x0000D267), (22, 0x00000002), (23, 0x00000002), (24, 0x000048FC), (25, 0xD3C33EB2), (26, 0x00000001), (27, 0x0000326E), (28, 0x7FFFFFFF), (29, 0x0000DB7A), (30, 0x80000000), (31, 0x7FFFFFFF)], pc := 0x800000B4, word := 0x01F0A0B3,
    post := [(1, 0x00000001)], pc' := 0x800000B8 },   -- slt     ra, ra, t6
  { pre := [(1, 0x798BA311), (2, 0xFFFFFFFF), (3, 0xFFFFFFFF), (4, 0x000000E5), (5, 0x5EE4B8BB), (6, 0xFFFFFFFE), (7, 0x50CBEF6D), (8, 0x7FFFFFFF), (9, 0x0000004A), (10, 0x00000040), (11, 0xFFFFFFFF), (14, 0x00000001), (15, 0xFFFFFFFE), (16, 0x00000001), (17, 0xFFFFFFFE), (18, 0xFFFFFFFE), (19, 0x80000000), (20, 0x9DDE4272), (22, 0x000000D9), (23, 0x000000CB), (24, 0x12EDA75F), (25, 0x000051CB), (27, 0x00000002), (28, 0x00000023), (29, 0x80000000), (31, 0xF2527D1C)], pc := 0x8000009C, word := 0x00F70863,
    post := [], pc' := 0x800000A0 },   -- beq     a4, a5, pc + 16
  { pre := [(1, 0x0000ACD0), (2, 0x00000001), (3, 0x80000000), (4, 0x00000001), (5, 0xFFFFFFFE), (6, 0x7FFFFFFF), (7, 0xFFFFFFFE), (8, 0xFFFFFFFE), (9, 0x00000002), (10, 0x00000092), (11, 0xFFFFFFFE), (12, 0xC0652B41), (13, 0x70D229F9), (14, 0x8D11FEA0), (15, 0x00000001), (16, 0x502AD692), (17, 0x00000001), (18, 0xFFFFFFFF), (19, 0x51FA2AF6), (20, 0x00000001), (21, 0xFFFFFFFF), (22, 0x0000242D), (23, 0xFFFFFFFE), (24, 0x7FFFFFFF), (25, 0x474F1DA7), (26, 0x00000059), (27, 0x80000000), (28, 0xFFFFFFFF), (30, 0xA2AB02D9), (31, 0x0000B3E0)], pc := 0x800000AC, word := 0x00AB8BB3,
    post := [(23, 0x00000090)], pc' := 0x800000B0 },   -- add     s7, s7, a0
  { pre := [(2, 0x80000000), (3, 0xC6776FB9), (4, 0xFFFFFFFE), (6, 0x7FFFFFFF), (7, 0x00000002), (8, 0xE08227E7), (9, 0xFFFFFFFE), (10, 0xE34B2E98), (11, 0x52CC05C7), (12, 0xFFFFFFFF), (13, 0xFFFFFFFE), (14, 0x7FFFFFFF), (16, 0xA3EF29E1), (17, 0x00000002), (18, 0x00000001), (19, 0x7FFFFFFF), (20, 0xC5B76CB1), (21, 0x80000000), (22, 0x80000000), (23, 0xFFFFFFFE), (24, 0x00000795), (25, 0x00000001), (27, 0x0D725DFF), (28, 0x80000000), (29, 0xFFFFFFFE), (30, 0x7B3813EF), (31, 0x80000000)], pc := 0x800000A8, word := 0xA0598293,
    post := [(5, 0x7FFFFA04)], pc' := 0x800000AC },   -- addi    t0, s3, -1531
  { pre := [(1, 0x0000DFBA), (3, 0xA4175450), (4, 0x0000006A), (5, 0x00000001), (6, 0x00000001), (7, 0xFFFFFFFE), (8, 0x0000BAAA), (9, 0x7FFFFFFF), (10, 0x8865273B), (11, 0xFFFFFFFF), (12, 0x0000F05E), (13, 0x00000001), (14, 0xFFFFFFFF), (15, 0x1366BFC7), (16, 0x00000002), (17, 0x00000001), (18, 0x00000002), (19, 0xFFFFFFFE), (20, 0x80000000), (21, 0x00004544), (22, 0xFFFFFFFE), (23, 0x7FFFFFFF), (24, 0x00000094), (25, 0xA6B70331), (26, 0x80000000), (27, 0x00002BD1), (28, 0xFFFFFFFF), (29, 0x0000006A), (30, 0x00000001), (31, 0x6C143A11)], pc := 0x800000AC, word := 0x0063C033,
    post := [], pc' := 0x800000B0 },   -- xor     zero, t2, t1
  { pre := [(1, 0xC67B6087), (2, 0x00000002), (3, 0x00000079), (4, 0x80000000), (5, 0x80000000), (6, 0x00000002), (7, 0x000067CF), (8, 0x00002C8E), (9, 0x00000001), (10, 0x00000002), (11, 0xFFFFFFFE), (12, 0x00000001), (13, 0x000091D4), (14, 0xCD3A83C0), (15, 0xAD08EBCF), (16, 0x80000000), (17, 0xFFFFFFFF), (18, 0xFFFFFFFF), (19, 0x4AAD8B15), (20, 0x000014DA), (21, 0x000000D9), (22, 0xA0F4180B), (23, 0xB73E9E04), (24, 0x00000001), (25, 0xFFFFFFFE), (26, 0x0F810BC0), (27, 0x00000001), (28, 0xF57E7D91), (29, 0x7FFFFFFF), (30, 0xFFFFFFFF), (31, 0xFFFFFFFE)], pc := 0x800000B0, word := 0x011D2033,
    post := [], pc' := 0x800000B4 },   -- slt     zero, s10, a7
  { pre := [(1, 0x000042D1), (2, 0x00000001), (3, 0xFFFFFFFE), (4, 0xFFFFFFFE), (5, 0x7FFFFFFF), (6, 0x31177441), (7, 0x8C4D98A8), (8, 0x00000002), (9, 0x9FF1D6AC), (10, 0xFFFFFFFE), (11, 0x00000002), (12, 0x0000000F), (13, 0x00000002), (14, 0xFFFFFFFF), (15, 0xFFFFFFFE), (16, 0x0000CB77), (17, 0x80000000), (18, 0x202C3A75), (19, 0x00000001), (20, 0x7FFFFFFF), (21, 0x1E3285B4), (22, 0x00000001), (23, 0x000000B3), (24, 0x3EB0C686), (25, 0xFFFFFFFE), (26, 0x00000089), (27, 0x04573306), (28, 0x0000DDB4), (31, 0x7FFFFFFF)], pc := 0x800000B0, word := 0x023C8063,
    post := [], pc' := 0x800000D0 },   -- beq     s9, gp, pc + 32
  { pre := [(2, 0x00000001), (3, 0x80000000), (4, 0x80000000), (5, 0x0000003B), (7, 0x00000001), (8, 0xFFFFFFFF), (9, 0x00000002), (10, 0xFFFFFFFE), (11, 0x00000002), (12, 0x000000B1), (13, 0xFFFFFFFF), (14, 0x000000E6), (15, 0xFFFFFFFE), (16, 0x80000000), (17, 0x00000001), (20, 0x00000001), (21, 0x00000002), (22, 0xA7EC209D), (23, 0x00000002), (24, 0x7FFFFFFF), (25, 0x506A8B0B), (26, 0x80000000), (27, 0xFFFFFFFE), (28, 0x0000E109), (29, 0x0000F064), (30, 0xFFFFFFFE)], pc := 0x80000090, word := 0x01330C33,
    post := [(24, 0x00000000)], pc' := 0x80000094 },   -- add     s8, t1, s3
  { pre := [(1, 0x80000000), (2, 0xFFFFFFFF), (3, 0x7FFFFFFF), (4, 0x80000000), (5, 0x80000000), (6, 0xB71D074D), (7, 0xFFFFFFFE), (8, 0x394371A2), (9, 0xFFFFFFFE), (10, 0x0000A18D), (11, 0x7FFFFFFF), (12, 0x7FFFFFFF), (13, 0x00000002), (14, 0x449167F3), (15, 0x00000048), (16, 0xFFFFFFFE), (17, 0x00000002), (20, 0xFFFFFFFE), (24, 0xFFFFFFFE), (25, 0x00000001), (26, 0xFFFFFFFF), (27, 0xFFFFFFFE), (28, 0x641523CA), (30, 0x7FFFFFFF), (31, 0x00000001)], pc := 0x800000A0, word := 0xFFF08093,
    post := [(1, 0x7FFFFFFF)], pc' := 0x800000A4 },   -- addi    ra, ra, -1
  { pre := [(2, 0x00000002), (3, 0x000000A0), (4, 0x80000000), (5, 0x00000001), (7, 0x00000073), (8, 0x7FFFFFFF), (9, 0x0DF12F3E), (10, 0xEC19E714), (11, 0x7FFFFFFF), (12, 0x7FFFFFFF), (13, 0x00000002), (14, 0x00000093), (15, 0x00000002), (16, 0x0000594E), (17, 0x00000002), (18, 0x00000001), (19, 0x31C6084E), (20, 0x43ED4FAB), (21, 0x0000003D), (22, 0x00000001), (23, 0x00000002), (24, 0x000000B5), (25, 0x0000698A), (26, 0x7FFFFFFF), (27, 0xE0657F1E), (28, 0xFFFFFFFE), (29, 0x00000001), (30, 0x80000000), (31, 0x00000002)], pc := 0x800000A8, word := 0x010FCFB3,
    post := [(31, 0x0000594C)], pc' := 0x800000AC },   -- xor     t6, t6, a6
  { pre := [(1, 0x80000000), (2, 0x00003603), (3, 0x80000000), (4, 0xE3C9E23C), (5, 0xF2574259), (6, 0x00000002), (9, 0x7FFFFFFF), (10, 0x000046DD), (11, 0x80000000), (12, 0x7FFFFFFF), (13, 0x00000002), (14, 0x00007E3B), (15, 0xFFFFFFFE), (16, 0x80000000), (17, 0xDC3BF3BD), (18, 0x000000C0), (19, 0x00000002), (20, 0x80000000), (21, 0xE39C2CEC), (22, 0xC36E88FB), (23, 0x00009B68), (24, 0x80000000), (25, 0x80000000), (26, 0x7FFFFFFF), (27, 0x00000002), (29, 0x0000634E), (30, 0x00000002), (31, 0x7F74C33E)], pc := 0x800000B4, word := 0x00F02033,
    post := [], pc' := 0x800000B8 },   -- slt     zero, zero, a5
  { pre := [(1, 0xFFFFFFFE), (2, 0x0000FA92), (4, 0xFFFFFFFF), (5, 0xAB578113), (6, 0x00000001), (7, 0x7FFFFFFF), (8, 0x9C44B12D), (9, 0x000011B2), (10, 0xFFFFFFFE), (11, 0xFFFFFFFE), (12, 0xFFFFFFFE), (13, 0x80000000), (14, 0x0000A3B8), (16, 0x0000005F), (17, 0x00003E94), (18, 0xFFFFFFFF), (19, 0x80000000), (20, 0x80000000), (21, 0xFFFFFFFF), (22, 0x0000008B), (24, 0x80000000), (26, 0x574F9F06), (27, 0x00000001), (28, 0x0000007C), (29, 0x00000001), (30, 0xFFFFFFFF), (31, 0x0000E70A)], pc := 0x800000A0, word := 0x02948063,
    post := [], pc' := 0x800000C0 },   -- beq     s1, s1, pc + 32
  { pre := [(1, 0x0000C911), (2, 0x7FFFFFFF), (3, 0x7FFFFFFF), (5, 0xFFFFFFFE), (6, 0x0000594E), (7, 0xD434C9D3), (8, 0x25D9FFB0), (10, 0x0000DD5C), (11, 0x053584F9), (12, 0x7FFFFFFF), (13, 0x00000001), (14, 0x00005FDE), (15, 0x0000BF25), (16, 0xFFFFFFFF), (17, 0x80000000), (18, 0x7FFFFFFF), (19, 0xFFFFFFFF), (20, 0x00B90F88), (21, 0xFFFFFFFE), (22, 0x7FFFFFFF), (24, 0xA2E8B102), (25, 0x0000445A), (26, 0x9FAF5675), (27, 0x365BBB40), (28, 0x0000604E), (29, 0x00000052), (30, 0xC192F871), (31, 0x0000F4E4)], pc := 0x800000D0, word := 0x00D88233,
    post := [(4, 0x80000001)], pc' := 0x800000D4 },   -- add     tp, a7, a3
  { pre := [(1, 0xD1FFF999), (2, 0xB57DAB33), (3, 0x00000002), (4, 0x7FFFFFFF), (5, 0x6333EFE6), (6, 0xFFFFFFFE), (7, 0xFFFFFFFF), (8, 0xFFFFFFFF), (10, 0xFFFFFFFE), (11, 0x0000614E), (14, 0x00000001), (15, 0x80000000), (16, 0xE52AECB7), (17, 0x57990C8F), (18, 0x000000B8), (19, 0xF2B59DD3), (20, 0xA038338C), (21, 0x00000002), (22, 0x00000001), (23, 0x7FFFFFFF), (24, 0x6C0E3023), (25, 0x669CA4DE), (27, 0x854B1BB2), (28, 0x80000000), (29, 0x7DE6773B), (30, 0x7FFFFFFF), (31, 0x00001A92)], pc := 0x800000BC, word := 0xFFF00793,
    post := [(15, 0xFFFFFFFF)], pc' := 0x800000C0 },   -- li      a5, -1
  { pre := [(1, 0xFFFFFFFE), (2, 0x00000002), (3, 0x00000026), (4, 0x0000B178), (5, 0x000000C9), (6, 0x3AD229EF), (7, 0x00000002), (8, 0x00000001), (9, 0x837482DF), (10, 0x2366C30E), (11, 0x00000001), (12, 0x9DABF1CA), (13, 0xC990063C), (14, 0x7FFFFFFF), (15, 0x80000000), (16, 0x0000EFAE), (17, 0x1DC959DC), (19, 0x00000023), (20, 0xFFFFFFFE), (21, 0xFFFFFFFE), (23, 0x00000001), (24, 0x7FFFFFFF), (25, 0x6527D53D), (26, 0x00000002), (27, 0xFFFFFFFE), (29, 0xABCE42DD), (30, 0x00008DB4), (31, 0x00000002)], pc := 0x800000B0, word := 0x010BCCB3,
    post := [(25, 0x0000EFAF)], pc' := 0x800000B4 },   -- xor     s9, s7, a6
  { pre := [(1, 0x80000000), (2, 0x00000002), (3, 0xFA48F249), (4, 0x00000001), (5, 0x7FFFFFFF), (6, 0x00000056), (7, 0xBAE70AF2), (8, 0x80000000), (9, 0x80000000), (10, 0x00000001), (12, 0x00000001), (13, 0xFFFFFFFF), (14, 0x95A1D8CA), (15, 0x7FFFFFFF), (16, 0xFFFFFFFF), (17, 0xFFFFFFFE), (18, 0x00000001), (19, 0x0000000B), (20, 0x7FFFFFFF), (21, 0xFFFFFFFF), (22, 0x00000002), (23, 0x7FFFFFFF), (24, 0xFFFFFFFF), (25, 0x00000001), (26, 0x7FFFFFFF), (28, 0xFFFFFFFF), (29, 0x00000001), (30, 0x80000000), (31, 0xB83671EC)], pc := 0x800000A0, word := 0x007B2033,
    post := [], pc' := 0x800000A4 },   -- slt     zero, s6, t2
  { pre := [(1, 0x00000001), (2, 0x00009255), (3, 0xFFFFFFFE), (4, 0x7FFFFFFF), (5, 0x742BBB5D), (6, 0x0000DEFF), (7, 0x7AE82835), (8, 0x00000001), (9, 0x00000001), (10, 0x0000004F), (11, 0xFFFFFFFE), (12, 0x4043D6BE), (13, 0x0000CFBB), (14, 0x00000002), (15, 0xFFFFFFFF), (16, 0x7FFFFFFF), (17, 0x0000679D), (18, 0x4031CE52), (19, 0x0000280F), (21, 0x2B9ECEE3), (22, 0x00001E0D), (23, 0x4F2DA2B7), (24, 0x7FFFFFFF), (25, 0xFFFFFFFE), (26, 0x7FFFFFFF), (27, 0x80000000), (28, 0x7FFFFFFF), (29, 0x00000002), (30, 0x69471B16)], pc := 0x800000C4, word := 0x014F8263,
    post := [], pc' := 0x800000C8 },   -- beq     t6, s4, pc + 4
  { pre := [(1, 0x000000ED), (2, 0xFFFFFFFF), (3, 0x80000000), (4, 0x00000002), (5, 0x0000AA2C), (6, 0x00000002), (7, 0x80000000), (8, 0xFFFFFFFE), (9, 0xBBA3C8CC), (10, 0x00000002), (11, 0x00000002), (12, 0x00000001), (13, 0x0000000E), (14, 0x00000001), (15, 0x0000FFF4), (16, 0xFFFFFFFE), (18, 0x7FFFFFFF), (19, 0x00000001), (20, 0xBDFE1CA6), (21, 0x48D71C0F), (22, 0xFFFFFFFE), (23, 0xFFFFFFFF), (24, 0x2EAB22E9), (25, 0x000096B3), (27, 0x00000001), (28, 0xACCE645F), (29, 0xFFFFFFFE), (30, 0x7FFFFFFF), (31, 0x00000001)], pc := 0x800000A4, word := 0x00430333,
    post := [(6, 0x00000004)], pc' := 0x800000A8 },   -- add     t1, t1, tp
  { pre := [(1, 0x0000006D), (3, 0x80000000), (4, 0x00000002), (5, 0x000000A9), (6, 0x00000002), (7, 0xFFFFFFFE), (8, 0x372F0572), (9, 0x0000005D), (10, 0x7FFFFFFF), (11, 0x00000001), (12, 0x00000404), (13, 0x0000C1C4), (14, 0x982C553E), (15, 0x0000DBC4), (16, 0xFFFFFFFE), (17, 0x36893744), (18, 0x7FFFFFFF), (19, 0x0C355472), (20, 0x7FFFFFFF), (21, 0xFFFFFFFE), (22, 0x00000054), (24, 0x000065CC), (26, 0x7FFFFFFF), (27, 0x0000398B), (28, 0x00000001), (29, 0x7FFFFFFF), (30, 0x00000002), (31, 0x00000088)], pc := 0x800000B0, word := 0x7FF98993,
    post := [(19, 0x0C355C71)], pc' := 0x800000B4 },   -- addi    s3, s3, 2047
  { pre := [(1, 0xBF2A16C1), (2, 0xFFFFFFFF), (3, 0x000077CB), (4, 0x000000E9), (6, 0x00000062), (7, 0x00000002), (9, 0x80000000), (10, 0x80000000), (11, 0xBB32945C), (12, 0x00006012), (13, 0x00000063), (14, 0xFFFFFFFF), (15, 0x00000001), (16, 0xFFFFFFFF), (17, 0x000000F1), (18, 0x7FFFFFFF), (19, 0x8EA7BD0A), (20, 0xFFFFFFFE), (21, 0xFFFFFFFE), (22, 0x7EC621F6), (23, 0x000000C4), (24, 0x00000002), (26, 0x80000000), (27, 0xFFFFFFFF), (28, 0xD5229D34), (29, 0x7FFFFFFF), (30, 0xFFFFFFFE), (31, 0x80000000)], pc := 0x800000A0, word := 0x01FA4233,
    post := [(4, 0x7FFFFFFE)], pc' := 0x800000A4 },   -- xor     tp, s4, t6
  { pre := [(1, 0xFFFFFFFE), (3, 0x80000000), (4, 0x00000002), (5, 0x80000000), (6, 0xCB4CA421), (7, 0x0000C346), (8, 0xFFFFFFFE), (9, 0x40392C39), (10, 0x80000000), (11, 0xFD067068), (12, 0x80000000), (14, 0x00824AEE), (15, 0xFFFFFFFF), (16, 0x8AA36665), (17, 0x00000001), (18, 0x00000002), (19, 0x80000000), (20, 0x00000052), (21, 0xFFFFFFFF), (22, 0x348A5857), (23, 0x00000001), (24, 0xFFFFFFFF), (25, 0x00000001), (26, 0x747EE7D6), (27, 0x7FFFFFFF), (28, 0x80000000), (29, 0x09B8420C), (30, 0x0000005F), (31, 0x00000002)], pc := 0x800000A4, word := 0x011BAFB3,
    post := [(31, 0x00000000)], pc' := 0x800000A8 },   -- slt     t6, s7, a7
  { pre := [(1, 0x7FFFFFFF), (2, 0x7FFFFFFF), (3, 0x80000000), (4, 0x00000002), (6, 0xFFFFFFFF), (7, 0xFFFFFFFF), (8, 0x0000BB7B), (9, 0x7FFFFFFF), (10, 0x0E3BF6AA), (11, 0xC8D684A2), (12, 0x00000001), (13, 0x80000000), (14, 0x00000002), (15, 0x80000000), (16, 0x7FFFFFFF), (17, 0x000000FB), (19, 0x80000000), (20, 0xF9C29FE4), (22, 0xFFFFFFFE), (23, 0x00000002), (24, 0x00009219), (25, 0x0000CDFC), (26, 0xFFFFFFFE), (27, 0x5CF345BA), (29, 0x00000002), (30, 0xAD705157), (31, 0xFEB6DF6E)], pc := 0x800000B0, word := 0x005F0463,
    post := [], pc' := 0x800000B4 },   -- beq     t5, t0, pc + 8
  { pre := [(1, 0xFFFFFFFF), (2, 0xC78B2EA2), (3, 0x000000CF), (5, 0x80000000), (6, 0x0000000D), (7, 0xFFFFFFFF), (8, 0xFFFFFFFF), (9, 0x01B2C7E9), (10, 0x00000001), (11, 0x00000002), (12, 0xFFFFFFFF), (13, 0x000025C1), (14, 0xFFFFFFFF), (15, 0xFFFFFFFF), (16, 0x80000000), (17, 0x22EAA91B), (18, 0x0406B6CB), (19, 0x000000AE), (20, 0x7FFFFFFF), (21, 0x00000002), (22, 0x00000001), (23, 0x7FFFFFFF), (25, 0x00000079), (26, 0x7FFFFFFF), (28, 0xFFFFFFFF), (29, 0x0000A964), (31, 0x0000B7BF)], pc := 0x800000A4, word := 0x00D80933,
    post := [(18, 0x800025C1)], pc' := 0x800000A8 },   -- add     s2, a6, a3
  { pre := [(1, 0x80000000), (2, 0x7FFFFFFF), (3, 0x0000B71B), (4, 0x3A8E35A2), (5, 0x9EEE3018), (6, 0x80000000), (7, 0x7FFFFFFF), (8, 0x7FFFFFFF), (9, 0xFFFFFFFF), (10, 0x6FE56F88), (12, 0x000050FC), (13, 0xFFFFFFFE), (14, 0x739E4D5F), (15, 0xFFFFFFFF), (16, 0x80000000), (17, 0x00000001), (18, 0x80000000), (19, 0xFFFFFFFF), (20, 0x0000A0FD), (21, 0x0000006C), (22, 0x00000001), (23, 0x2E5C7502), (24, 0x57D0AC37), (26, 0x00000001), (27, 0xB2AB0095), (28, 0xB33A2883), (30, 0xFFFFFFFE), (31, 0x0000202B)], pc := 0x800000B8, word := 0xFFFC8C93,
    post := [(25, 0xFFFFFFFF)], pc' := 0x800000BC },   -- addi    s9, s9, -1
  { pre := [(1, 0x00000002), (2, 0x00000002), (4, 0x80000000), (5, 0x00000001), (6, 0xFFFFFFFF), (7, 0x00000002), (8, 0x00000002), (9, 0x00000001), (10, 0x7FFFFFFF), (11, 0x0000009E), (13, 0x00000002), (14, 0x7FFFFFFF), (15, 0xDDD34427), (16, 0x00000002), (17, 0x00000002), (18, 0xFFFFFFFF), (20, 0x31635B55), (21, 0x00000065), (22, 0x00000002), (23, 0xFFFFFFFF), (24, 0x00000001), (25, 0x000000B8), (26, 0x000053E5), (27, 0x6B464139), (28, 0x7FFFFFFF), (29, 0xD3476A23), (30, 0x00000002), (31, 0x80000000)], pc := 0x8000009C, word := 0x016042B3,
    post := [(5, 0x00000002)], pc' := 0x800000A0 },   -- xor     t0, zero, s6
  { pre := [(1, 0xFFFFFFFF), (2, 0x7FFFFFFF), (3, 0x00000001), (4, 0x7FFFFFFF), (5, 0x00000001), (6, 0x7FFFFFFF), (7, 0x7FFFFFFF), (8, 0x80000000), (9, 0x69ACE790), (10, 0xFFFFFFFE), (11, 0xFFFFFFFE), (12, 0x46947F11), (13, 0x7FFFFFFF), (15, 0x00000001), (16, 0xFFFFFFFF), (17, 0xFFFFFFFE), (18, 0x80000000), (19, 0x000071B1), (20, 0xB4B3B6C7), (21, 0x41826835), (22, 0x80000000), (23, 0xDCB2D443), (25, 0x0000CB1F), (26, 0x7FFFFFFF), (27, 0x00000002), (28, 0x00000001), (29, 0x2B5CE2CB), (30, 0x00000001), (31, 0x00000001)], pc := 0x800000B4, word := 0x00A0A0B3,
    post := [(1, 0x00000000)], pc' := 0x800000B8 },   -- slt     ra, ra, a0
  { pre := [(1, 0xA2306BCD), (2, 0x00000001), (3, 0xFFFFFFFE), (6, 0xFFFFFFFE), (7, 0xFFFFFFFE), (8, 0xFFFFFFFE), (9, 0x7FFFFFFF), (10, 0x00000001), (11, 0x00000001), (12, 0xE4473237), (13, 0xFFFFFFFE), (14, 0xFFFFFFFF), (15, 0x7FFFFFFF), (16, 0x7FFFFFFF), (17, 0x13CF1F89), (18, 0x00000002), (19, 0xC4F99A4F), (20, 0xFFFFFFFE), (21, 0x00000095), (22, 0x7FFFFFFF), (23, 0xFFFFFFFF), (24, 0xFFFFFFFE), (25, 0x00000001), (26, 0x00000001), (27, 0x7FFFFFFF), (28, 0x7FFFFFFF), (29, 0xFFFFFFFE), (30, 0xA1201ED8), (31, 0x07805F3A)], pc := 0x800000AC, word := 0x00A50463,
    post := [], pc' := 0x800000B4 }   -- beq     a0, a0, pc + 8
 ]

/-! ## The check

`decide +kernel`, never bare `decide` — iron rule 6. **`Vec.checkFull`, not
`checkObs`**: the observable check is blind to a register the step should not
have touched, and with all 31 registers non-zero in every pre-state, a clobber
is exactly what this suite is positioned to catch. -/

/-- **THE CLAIM, and it is the whole point of C2: `step` agrees with Spike on
every one of the 120 witnessed vectors, checked by the kernel.** -/
theorem spike_agrees : spikeSuite.all Vec.checkFull = true := by decide +kernel

/-! ## MUTATION: what this suite CATCHES that nothing else in the repo does

**A green suite is not evidence until a real defect makes it fail**, and the
first mutation attempt was **VOID** — recorded because the void was silent.
Mutating `ADDI`'s `signExtend → zeroExtend` and `SLT`'s `slt → ult` broke
`ISA.lean`'s **own** certificates (`addi_sign_extends`, `slt_is_signed`), so
`ISA.lean` failed to build and the suite was never reached. *A mutation caught
upstream tests the upstream check, not the one you are trying to validate.*

**The mutations below were chosen to SURVIVE `ISA.lean` — so a failure can only
come from Spike.** Both were run; `ISA.lean` built clean under each.

```
MUT-A   XOR  ^^^  ->  |||     ISA.lean BUILDS   suite FAILS   EXIT=1
MUT-B   SLT  slt  ->  sle     ISA.lean BUILDS   suite FAILS   EXIT=1
restore                       ISA.lean BUILDS   suite GREEN   EXIT=0
```

⭐ **`MUT-A` was possible because, WHEN IT WAS RUN, `XOR` had no theorem anywhere
in `ISA.lean`** — of the five instructions it was the only one with no
certificate pinning it, and nothing in the repository would have noticed if it
computed `or`. *The witness found a hole in the hand-written certificates, which
is the first thing it was asked to do.* **That gap is now CLOSED** —
`xor_is_exclusive` and `xor_self_is_zero` landed in `ISA.lean` in response, so a
re-run of MUT-A today would be caught upstream as well. **The result above is
recorded as it was actually run, not as it would run now.**

**`MUT-B` is the sharper one and is unaffected: `sle` satisfies `slt_is_signed` (`-1 ≤ 1`
gives 1) AND `slt_is_signed'` (`1 ≤ -1` gives 0), so it passes both hand-written
SLT certificates** and is caught only by a witnessed vector where the two
operands are equal. *That is the corner-biased sampling earning its keep, and it
is the concrete answer to "what does a witness buy that a certificate does not".*

📌 *Both failures also tripped `#audit_axioms` with `sorryAx` on `spike_agrees`
— the `decide +kernel` refutation propagates to the audit gate, so the ban and
the differential test fire together rather than one masking the other.* -/

/-- **NON-VACUITY.** A suite that passed because the checker cannot fail would
be worthless. Take Spike's own first vector and corrupt its `pc'` by one word:
the checker must REJECT it. *The control is built from a REAL witnessed vector
rather than a hand-made one, so it exercises the same path the suite does.* -/
theorem spike_checker_rejects_a_corrupted_witness :
    (spikeSuite.head?.map fun v => Vec.checkFull { v with pc' := v.pc' + 4 })
      = some false := by decide +kernel

/-- **AND THE SUITE IS NOT SILENTLY EMPTY** — the failure mode that makes an
`all` vacuously true. -/
theorem spike_suite_size : spikeSuite.length = 120 := by decide +kernel

#audit_axioms spikeSuite
#audit_axioms spike_agrees
#audit_axioms spike_checker_rejects_a_corrupted_witness
#audit_axioms spike_suite_size

end SaltWorks.ISA
