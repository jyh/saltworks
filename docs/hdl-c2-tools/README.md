# C2 generator — Spike-witnessed vectors

`genvec.py` is the **untrusted offline generator** of council ruling 3. It
drives a third-party RISC-V simulator and prints Lean `Vec` literals; every
claim it supports is kernel-checked downstream by `Vec.checkFull` in
`SaltWorks/HDL/SpikeVectors.lean`. Nothing here is trusted.

## Reproducing the landed suite

```
spike       github.com/riscv-software-src/riscv-isa-sim
            source commit 3ab575645442aa0ebb58c2d07ab98f1b546ac0bb (2026-08-06)
            built from source: ./configure --prefix=$PREFIX && make && make install
            NOT available in Homebrew — `brew search spike` returns a LEGO product
assembler   riscv64-elf-gcc 16.1.0 / GNU as 2.47.20260726  (brew install riscv64-elf-gcc)
dtc         1.8.1  (brew install dtc)   -- spike build dependency

python3 genvec.py 120 20260807 > vecs.txt      # n, seed
```

`SPIKE` is resolved relative to this file (`inst/bin/spike`); point it at your
build. Deterministic for a fixed `(n, seed)` and a fixed toolchain.

## The three rules, and why they are not style choices

* **R1 the pre-state is READ BACK from the witness.** The prologue is built from
  instructions under test, and Spike's reset leaves `t0`/`a1` non-zero. An
  assumed pre-state describes a state the witness was never in.
* **R2 the word comes from the ASSEMBLER**, read back out of Spike's own
  disassembly. `SaltWorks.ISA.encode` is nowhere in the path.
* **R3 only what the witness said is written down.** `post` is a diff of two
  Spike register dumps.

## `.align 3` is load-bearing

`fesvr` reads `tohost` as an 8-byte object. `.data`'s alignment follows
`.text`'s length, which depends on how many `li`s expand to `lui`+`addi` — i.e.
**on the random pre-state values**. Without the alignment directive ~44% of
vectors are rejected with `misaligned address`, and *the rejection is correlated
with the value distribution being sampled*. Measured: 44% -> 0%.

## Known gaps, named rather than implied

* **Mutually-agreed-ILLEGAL words are not representable.** `Vec.actual` is
  `Option St` and `checkFull` compares against `some`, so "our `decode` rejects
  this word AND Spike traps on it" — real agreement — cannot be written as a
  `Vec`. The generator therefore only emits words both sides accept, and
  `decode`'s rejection behaviour is left to `decode_rejects_lui`.
* **Backward branches are not emitted**, per the consumer's stated promise.
* **The SAIL cross-check HAS run** — `sailcheck.py`, **120 agree · 0 disagree ·
  0 skipped** against the *landed* suite (not against a fresh Spike run: the
  point is to tie SAIL to the artifact the kernel checks). Mutation-controlled:
  a one-bit `post` corruption, an emptied `post`, a shifted `pc'`, and a
  `funct3` flip each produce DISAGREE.
  ⚠️ **Method asymmetry, stated because it is a real weakness:** Spike's debug
  mode dumps the whole register file, so nothing is reconstructed there. SAIL
  offers no register dump — only a write trace — so the state IS rebuilt by
  replaying the `reg <- value` events SAIL itself emits. That is bookkeeping
  over the witness's own statements rather than a second model of the machine,
  but it is a weaker instrument than Spike's.
  ⚠️ **And three-way agreement does not exclude a correlated error**: Spike and
  SAIL are independent of each other, not of the RISC-V manual.
