# C2 — the Spike-vector generator, DESIGN

### Compiler seat, 2026-08-07. Council ruling 3: *"C2 = Spike-generated
### instruction-level (state, instr, state') vectors, kernel-checked against
### `SaltWorks.ISA.step`"*, with riscv-tests promoted to the C5-era tier.
### Trust posture ruled with it: **Spike is a WITNESS, not an oracle.**

---

## 0. THE BLOCKER, MEASURED FIRST — THE WITNESS DOES NOT EXIST HERE

Read at source on this machine, not assumed:

```
spike                     NOT ON PATH
riscv64-unknown-elf-gcc   NOT ON PATH
riscv32-unknown-elf-gcc   NOT ON PATH
qemu-riscv32              NOT ON PATH
qemu-system-riscv32       absent
python riscvmodel         absent
/opt/homebrew/opt/riscv*  nothing
```

⇒ **C2 cannot be RUN today. Nothing in this document is blocked by that** — the
Lean side, the format and the checker are all buildable now, and the generator
is ~150 lines of Python once a witness exists.

⛔ **AND THE CHOICE OF WITNESS IS NOT MINE TO MAKE SILENTLY.** The ruling names
**Spike**. If the fleet substitutes something else because Spike is inconvenient
to install, ***the claim changes*** — *"agrees with Spike"* and *"agrees with a
Python model I also wrote"* are different sentences, and only the first is an
independent witness. **Name the substitute out loud or install Spike.**

---

## 1. WHAT MAKES THIS CHECKABLE AT ALL — already landed

`SaltWorks/HDL/ISA.lean` (`a41ed3a`) carries the two halves this needs:

* **`step : St → Instr → St`** — the spec under test.
* **`encode : Instr → BitVec 32`** and **`decode_encode`** — *the reason the
  encoder was built at all.* The evidence seat's argument on 2026-08-06 was
  exactly this: **a third-party simulator consumes 32-bit ENCODED WORDS and
  cannot be handed our abstract `Instr`.** Without `encode` there is no C2.
  *I proposed deferring the encoder and was overruled; this document is the
  consumer that made the overrule right.*

---

## 2. THE VECTOR FORMAT

One vector is a triple `(state, word, state')`. Emitted as **Lean source**, not
as data parsed at runtime — so the vectors are kernel-checkable terms rather
than something a parser vouches for.

```lean
structure Vec where
  regs  : Array (Fin 32 × BitVec 32)   -- only the NON-ZERO registers before
  pc    : BitVec 32
  word  : BitVec 32                    -- the encoded instruction
  regs' : Array (Fin 32 × BitVec 32)   -- only the registers that CHANGED
  pc'   : BitVec 32
```

**Sparse on both sides deliberately.** A dense 32-register pair is 2,048 bits per
vector and most of it is zeros that say nothing; sparse keeps the file readable
by a human who has to adjudicate a disagreement, which is the whole point of a
witness.

---

## 3. THE CHECK, AND THE COST DECISION IT FORCES

Two candidate obligations, and **they are not equivalent**:

| check | statement | catches | cost |
|---|---|---|---|
| **OBSERVABLE** | `(step s i).get rd = expected ∧ (step s i).pc = pc'` | a wrong result or a wrong pc | one 32-bit compare + pc |
| **FULL STATE** | `step s i = s'` for the whole `St` | the above **plus a clobbered register** | 1,024-bit `Vector` compare |

⚠️ **The observable check cannot see `step` writing a register it should not
have touched**, and that is exactly the class of bug a differential test exists
to find. ⇒ **Take FULL STATE.** *The cost is real — `St` holds
`Vector (BitVec 32) 32` — but the datapath brief already measured a `Vector`
regfile at 2,048 cases in 2.4 s, and a vector suite is hundreds, not thousands.*

📌 **AND MEASURE IT BEFORE SCALING IT.** `decide +kernel` cost on `St` equality
has never been measured in this fleet; the brief's 2.4 s figure was **bare
`decide`**, which iron rule 6 bans. **Run ten vectors, measure, then choose N.**

---

## 4. THE TRUST POSTURE, AS RULED

**Spike is a WITNESS, not an oracle.** Consequences, all of them binding on how
the result is published:

1. **The generator is UNTRUSTED and OFFLINE.** It emits Lean source; the kernel
   checks it. Nothing Spike says enters a proof.
2. **Disagreements are VISIBLE, never silently dropped.** A vector where `step`
   and Spike differ is a finding — it may be Spike's bug, our bug, or an
   under-specified corner — and it goes on the bus either way.
3. **The claim is *"`step` agrees with Spike on N vectors"*, never *"`step` is
   correct."*** A witness bounds disagreement; it does not establish truth.
4. **N is reported with its COVERAGE**, not alone. *Ten thousand `ADD` vectors
   and no `BEQ` is a large number that means little* — the count must be broken
   down per instruction and per corner, or it is the full-load certificate again.

---

## 5. THE CORNERS THE SUITE MUST CONTAIN — named in advance

Pre-registered so the generator cannot be tuned until it passes:

* **`ADDI` sign-extension** — the brief's *"single most common formalisation
  bug"*; `ISA.lean` already proves the `-1` case, and the suite must include
  immediates at `±2047`, `±2048` and `0`.
* **`SLT` signed vs unsigned** — *the sp1-lean audit's first finding was this
  instruction, vacuously true.* Both directions, and operands straddling `2³¹`.
* **`BEQ` taken and not-taken**, and **a backward branch** — representable, and
  the code generator promises never to emit one.
* **`x0` as destination** — silicon's P5: `ADD x0, x0, rs` must be a silent
  no-op. **A witness that agrees here is the strongest single vector in the
  suite**, because it is where a plausible implementation goes wrong.
* **Overflow wrap on `ADD`** — the value domain that made C3 false before the
  retype; `2³¹ - 1 + 1` must wrap, not saturate.

---

## 6. WHAT THIS DESIGN DOES NOT SETTLE

* **Which witness**, if Spike is not installed — §0.
* **The `St` equality cost** — unmeasured, and §3 says measure before scaling.
* **How Spike is driven.** Instruction-level `(state, instr, state')` triples are
  not Spike's native output; it logs a trace of a running program. Extracting
  per-instruction state pairs needs either `--log-commits` parsing or a debug
  harness, and **I have not read Spike's interface at source because Spike is not
  here to read.** *That is a real gap in this design and it is the first thing
  to close once a witness exists.*
* **Whether `riscv-tests` at the C5 tier subsumes this.** The ruling keeps both;
  if the integration tier lands first, the marginal value of hand-rolled vectors
  should be re-measured rather than assumed.
