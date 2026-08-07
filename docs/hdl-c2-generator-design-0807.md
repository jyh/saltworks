# C2 GENERATOR — design record (seat: compiler/compiler-acct)

### 2026-08-07. STATUS: **probe-validated and LANDED** (`a00b651`), not a proposal.
### Companion to `docs/hdl-c2-vector-design-0807.md`, which designed the CONSUMER.

Council ruling 3 (Captain, 06:14): *"C2 = Spike-generated instruction-level
`(state, instr, state')` vectors, kernel-checked against `SaltWorks.ISA.step`"*,
with the trust posture ruled alongside it — **Spike is a WITNESS, not an
oracle.** This document records the decisions behind the generator: what was
chosen, what was rejected, and what each alternative would have changed about
the *claim*. The tool is `docs/hdl-c2-tools/`; the artifact is
`SaltWorks/HDL/SpikeVectors.lean`.

---

## §1 THE WITNESS — selection, and the trap in the selection

At 07:00 this blocker read *"spike is NOT on PATH; the generator does not exist
on this machine"*. Ruling 3 attached a clause to the queue item: **read the tool
versions and formats AT SOURCE, no remembered facts.** That clause did the work.

⛔ **`brew search spike` RETURNS A HIT, AND IT IS A LEGO PRODUCT.**

```
==> spike (Lego SPIKE): 3.6.1
    Develop with Scratch and Python for your LEGO Spike set
    https://education.lego.com/          <- homebrew-cask, an .app bundle
```

A seat acting on the search result installs an education app, reports the
blocker cleared, and every downstream claim inherits a witness that does not
exist. The distance between that and the correct outcome is one `brew info`.
**The RISC-V simulator is not in Homebrew at all.**

### The three candidate witnesses, and what each would have meant

| candidate | availability | what the claim becomes |
|---|---|---|
| **Spike** (`riscv-isa-sim`) | source build, 86 s | *"agrees with Spike"* — ruling 3's own sentence |
| SAIL (`sail-riscv`) | opam + model build | *"agrees with the official formal spec"* — stronger |
| qemu-riscv32 | brew | *"agrees with an emulator"* — weakest; qemu is not a spec |

**Spike chosen as primary** because ruling 3 names it and because substituting
silently *changes the claim* — *"agrees with Spike"* and *"agrees with a model I
also wrote"* are different sentences. **SAIL is the ordered one-time
cross-check, not a substitute.** qemu was not pursued: it would have added a
third emulator without adding a second *kind* of authority.

```
Spike RISC-V ISA Simulator 1.1.1-dev
  source commit 3ab575645442aa0ebb58c2d07ab98f1b546ac0bb   (2026-08-06)
GNU assembler (GNU Binutils) 2.47.20260726 · riscv64-elf-gcc 16.1.0
sail 0.20.1 (opam) · z3 (required — sail dies `status 127` without a solver)
sail-riscv model commit 61266bd4dede6c7dd6e903e52dc80bcbf644b1b8 (2026-08-03)
```

---

## §2 THE HARNESS — how a triple is obtained

Spike cannot be handed a register state directly: it loads an ELF and runs it.
So a `(state, instr, state')` triple needs a **prologue** that materialises the
pre-state — and the prologue is built from **instructions under test**.

**Rejected: `--log-commits` delta parsing.** Spike's commit log reports each
writeback, so the state could be *reconstructed* by replaying deltas. Rejected
because reconstruction is a second model of the machine, written by us, sitting
between the witness and the vector — precisely the thing C2 exists to remove.

**Chosen: `-d --debug-cmd` with full register dumps at two points.**

```
until pc 0 <test_instr>     # stop BEFORE the instruction under test
reg 0 ; pc 0                # dump all 32 registers + pc   -> PRE
run 1                       # execute exactly one instruction
reg 0 ; pc 0                # dump all 32 registers + pc   -> POST
```

`post` is then a *diff of two things the witness said*. Nothing is reconstructed.

---

## §3 THE THREE RULES, and why each is load-bearing rather than stylistic

**R1 — THE PRE-STATE IS READ BACK FROM THE WITNESS, NEVER ASSUMED.**
This is the rule the whole design turns on. The prologue is itself made of
instructions under test; if our understanding of `ADDI`/`LUI` is wrong, the
state we *think* we set is not the state Spike set. And it is not hypothetical:

```
measured — registers Spike's reset leaves non-zero that we never wrote:
   t0 = 0x80000000     a1 = 0x1020
```

A vector asserting an **assumed** pre-state describes a state the witness was
never in — **and it passes anyway** for every instruction that happens not to
read those registers. That is what makes it a *latent* falsehood rather than a
visible one: it would surface later, intermittently, on an unrelated change.
Reading the state back converts a **correctness** hazard into a **coverage**
hazard, which is the right trade.

**R2 — THE WORD COMES FROM THE ASSEMBLER, NOT FROM OUR `encode`.**
The generator writes a mnemonic, `riscv64-elf-as` encodes it, and the 32 bits
are read back out of Spike's own disassembly line. `SaltWorks.ISA.encode`
appears nowhere in the path, so an encoder bug cannot manufacture agreement.
*(Soundness would survive either way — both sides decode the same word
independently — but coverage would not: our encoder can only reach words our
encoder can produce.)* **This is what `decode_encode` was landed for.**

**R3 — ONLY WHAT THE WITNESS SAID IS WRITTEN DOWN.**

---

## §4 SAMPLING — three corrections the first draft needed

**Stratification.** An unstratified random draw left `SLT` and `XOR` absent from
the first six vectors. Round-robin over the five instructions: **24 each**.

**Forced branch equality.** A random 32-bit pair is essentially never equal, so
an unforced `BEQ` suite tests exactly one direction. Half the `BEQ` cases force
equality (same register, or the pre-state made equal): **8 of 24 taken**.

**Corner-biased values.** Register values drawn from
`{0, 1, -1, 0x7FFFFFFF, 0x80000000, 2, random}` rather than uniform. All 31
registers are set per vector, which is what gives `checkFull` its teeth: a
clobbered register is visible against a non-zero background.

⚠️ **AND A SILENT 44% REJECTION THAT WAS CORRELATED WITH THE THING BEING
SAMPLED.** The first run dropped 78 of 178 attempts to fesvr's
`misaligned address`. `tohost` is read as an 8-byte object; `.data`'s alignment
follows `.text`'s length; and **`.text`'s length depends on how many `li`s
expand to `lui`+`addi` — that is, on the random pre-state VALUES.** The sample
was being skewed by its own value distribution, and a "120 vectors" headline
would have described a biased set. `.align 3` took it **44% → 0%**. *It was
noticed only because 178-attempts-for-100 is not a number a clean harness
produces.*

---

## §5 THE OBLIGATION AND ITS PRICE

`Vec.checkFull` (all 32 registers + pc), not `checkObs` — the consumer's §3
decision, and `observable_is_blind_to_a_clobber` is the theorem that prices it.

```
spike_agrees : spikeSuite.all Vec.checkFull = true := by decide +kernel
120 vectors · saltbuild EXIT=0 · 11.8 s wall (≈1.5 s of that is import baseline)
```

⚠️ **`maxRecDepth` is required and is NOT a memory event.** A 120-element list
literal exceeds the *elaborator's* default `whnf` depth; the text is
`maximum recursion depth has been reached`, and M-2.1's memory strings do not
appear. **The first failing run printed `✓ … [n axioms]` for all four
declarations while `saltbuild EXIT=1`** — silicon's 8/6 catch exactly. *The EXIT
text is the verdict; the ticks are not.*

⛔ **THE OLD COST CEILING DOES NOT TRANSFER — MEASURED, NOT ARGUED.** The 09:09
harness measured *~57 ms per distinct vector, 400 fine, 800 FAILS* — but that was
on **sparse** vectors carrying a handful of named registers. **These carry ~30
register entries each.** Different object, different price. Re-measured for this
shape at the fleet's standard `-M 12000`:

```
N = 120   EXIT=0   11.8 s
N = 240   EXIT=0   23.7 s        <- ~99 ms/vector, linear
N = 360   EXIT=0   34.2 s
N = 480   EXIT=1   50.0 s   (kernel) excessive memory consumption detected
```

⇒ **The ceiling for this shape is between 360 and 480, where the old harness's
was between 400 and 800.** *Roughly half, and in the direction the denser
vectors predict.* **The 480 failure is a genuine cap event — M-2.1's definitive
string appears, so M-2.3's differential test is not needed.**

📌 **N = 120 IS KEPT DELIBERATELY, with 3× headroom now measured rather than
assumed.** *The suite's value is in its corners, not its count*, and the right
use of the headroom is targeted corners later, not 3× more of the same random
draw. **The number is the maestro's to raise; the ceiling is no longer unknown.**

---

## §6 WHAT IS NOT CLAIMED — the fences, stated so they travel

1. **NOT "`step` is the ISA."** The licensed sentence is exactly *"`step` agrees
   with Spike on 120 vectors, kernel-checked."*
2. **A correlated error is not excluded by agreement.** Both this spec and Spike
   could be wrong the same way. That is why ruling 3 also orders the one-time
   SAIL cross-check — **which has not run, so the claim may not carry SAIL's
   name.**
3. **120 vectors is a spot check**, not coverage: 2^32 words against a 2^992
   state space. Its value is in its corners, not its count.
4. **Mutually-agreed-ILLEGAL words are not representable.** `Vec.actual` is
   `Option St` and `checkFull` compares against `some`, so *"our `decode`
   rejects this word AND Spike traps on it"* — real agreement, and the case
   where a third-party word is most informative — has no `Vec`. The generator
   emits only words both sides accept. **Closing this needs a consumer-side
   change and is not the generator's to make.**
5. **No backward branches**, per the consumer's stated promise.

---

## §7 WHAT THE WITNESS HAS ALREADY BOUGHT

Within an hour of existing it found a hole the hand-written certificates had
left: **`XOR` was the only one of Slice A's five instructions with no theorem
anywhere in `ISA.lean`.** Mutating `^^^ → |||` built the file clean and was
caught solely by Spike. Closed in `e71e9a3` (`xor_is_exclusive`,
`xor_self_is_zero`), mutation-verified.

**The generalisation is the part worth keeping.** The certificates were written
by the seat that wrote `step`, and they cover the instructions that seat was
worried about — `ADDI` because the brief called sign-extension the commonest
bug, `SLT` because the sp1-lean audit found it vacuous. ***The one nobody was
worried about is the one that went uncovered. Worry is not a coverage metric,
and an outside witness is how you find out where yours was pointed.***

And the second mutation is the standing demonstration: **`SLT`'s `slt → sle`
satisfies BOTH hand-written SLT certificates** (`-1 ≤ 1` gives 1; `1 ≤ -1` gives
0) and is caught only by a witnessed vector whose operands are equal. *That is
the concrete answer to "what does a witness buy that a certificate does not."*
