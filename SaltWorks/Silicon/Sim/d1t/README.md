# D1t — the dmem_addr8 address checker, and its pre-registered bar

Stage ③, silicon's lane. Decides whether a candidate Verilog module is a correct
8-word LW/SW address mask **per the ruling**, and is itself gated by seven arms
each of which requires a planted failure that it catches.

```
./run_bar.sh              every arm, full per-arm report
./run_bar.sh -q           the verdict table only
./d1t_check.sh <file> <module>      one candidate
```

`run_bar.sh` exits 0 **only** if every arm behaves as registered. That exit
status is the gate — `./run_bar.sh && <land>`. A criterion whose result nothing
consumes is a printout.

---

## The bar

| arm | expectation | plant | caught by |
|-----|-------------|-------|-----------|
| T1  | REJECT | `RTL/dmem_addr16.v`, the sibling **unmodified** | [A] port width |
| T1b | REJECT | the 16-word **bound** with the port already fixed | [B] proof, at byte 32 |
| T2  | REJECT | trap raised, write **not** suppressed | [B] proof, at byte 2 |
| T3  | REJECT | `out_of_range` absent, `misaligned` correct | [B] proof |
| T4  | REJECT | `misaligned` absent, `out_of_range` correct | [B] proof |
| T5  | ACCEPT | `RTL/dmem_addr8.v`, the real module | both arms |
| T6  | REJECT | both assignments correct, port left `[3:0]` | [A] port width |
| S   | — | the checker prints what it examined **and what it could not reach** | — |

**T5 and the reject arms are the discriminating pair.** T1–T4/T6 alone are
satisfied by a tool that rejects everything; T5 alone by one that accepts
everything. A bar without both discriminates nothing.

---

## Registration history — read this before trusting the bar

A bar written after the build is a bar fitted to it (evidence's form and reason).
So the timing of every arm is on the record, and two arms were added late.

| when | what | was the checker written? |
|------|------|--------------------------|
| 8/12 10:00 | **T1–T5 and S** registered, on the bus and in the seat bank `e13c99f` | **no** |
| 8/12 10:1x | **T6** registered | **no** |
| 8/12 10:1x | **T1b** registered | **no** |
| 8/12 10:2x | first line of `d1t_check.sh` written | — |

Nothing has been removed, and no arm has been narrowed. Both additions
**strengthen** the bar, and both were fixed before the instrument existed, which
is the same standard the original five met.

### Why T6 was added — a hole in my own bar, found by building the wrong file

T6 plants a file differing from the accepted one in **exactly one line**: the
`word_index` port declaration, left at `[3:0]`. Measured on that controlled pair:

```
                          port bits   chip area µm²   144-point sim trace
  dmem_addr16 (16 words)     42         83.8304       —
  dmem_addr8, TWO sites      42         85.0816       IDENTICAL to below
  dmem_addr8, THREE sites    41         85.0816       —          ← the real module
```

* `iverilog` warns (`expects 4 bit(s), given 3 — padding 1 high bits`) and
  **exits 0**. It warns without `-Wall`, and no `Sim/*/run.sh` here passes `-Wall`.
* **Simulation cannot see it**: 144 stimulus points, store-then-load over bytes
  0–71, **zero divergence**. The padded bit is constant zero.
* **Area cannot see it**: 85.0816 µm² either way.
* Its **port count is 42 — the sixteen-word sibling's figure, exactly.**

The interface announces a sixteen-word memory while the logic implements eight.
T1 does not subsume it: T1's plant has *both assignments* wrong, so a checker
examining only the assignment expressions rejects T1, accepts T5, and passes T6.

*The hole was invisible while the only artifact under test was the one that
already had the port right — `criterion-weaker-than-artifact`. It was found by
building the wrong version on purpose.*

### Why T1b was added — T1 passes for a reason other than the one claimed for it

T1 was registered with the rationale *"the ONLY arm that can catch the 16-word
bound being inherited."* Measured while prototyping: the unmodified sibling is
rejected by arm **[A]** on its 4-bit port, **before any proof runs** — so T1 as
written is satisfied *without the bound ever being tested.* The arm and its
stated reason had come apart.

T1 is kept **verbatim** and still runs. T1b is the arm that tests the rationale:
the sibling's bound (`|byte_addr[31:6]`) with the port width **already fixed** —
an engineer who corrects the thing the tool warns about and misses the thing it
does not. Arm [B] refutes it at `byte_addr = 32`, which is the exact boundary
`memory-design-v1.md` ⬥v1.1 names when it kills the pairing.

---

## Why the checker has two arms and three outcomes

**Arm [A], structural.** Reads the port record from yosys's own JSON — not a
regex over the source, which would be a second and worse parser, and is the
instrument the T6 defect hides from. Checks the ruled signature and the absence
of state.

**Arm [B], behavioural.** `miter -equiv` + `sat -prove-asserts` against
`ref_dmem_addr8.v`. **Exhaustive**: the proof covers all 2³⁴ input assignments
(`byte_addr`[32] × `req` × `we_in`). Not a testbench; no coverage claim needed.

**Three outcomes, and the third is why this is not a one-liner.** Measured 8/12
while prototyping: `miter -equiv` **exits 1 without proving anything** when port
widths differ — `ERROR: No matching port in gate module was found for
\word_index!`. Both the sibling and the wrong-port variant produced that exit. A
checker reading only the exit code would have called both REJECTED and been
**right by accident**: a construction error and a refutation are the same status
byte. A later yosys that learned to zero-extend mismatched ports would silently
flip those arms to ACCEPT. So the arms are separated, each reports its own
verdict, and a tool failure yields **INCONCLUSIVE** — never either answer.

**An unreached arm is printed as unreached.** When [A] rejects on the port
signature, [B] *cannot be built*. The report says so. A silent skip reads exactly
like a pass; that is the S line.

---

## What this instrument does NOT establish

* **The F4 bridge.** It compares a candidate to a *transcription* of the ruling
  written by the same hand as the candidate. A mistranscription is invisible to
  it in both directions. `ref_dmem_addr8.v` cites the kernel text line by line so
  the transcription is checkable by reading, and is written in a deliberately
  different idiom (`byte_addr >= 32`, not `|byte_addr[31:5]`) so the equivalence
  is *proved* rather than assumed — but two files in one hand share a confound
  and this paragraph is the disclosure, not the fix. The fix is math's.
* **Timing, area, power, the fabbed netlist.** This reads RTL. The die is built
  by TinyTapeout CI from other bytes.
* **Composition with `dmem8`.** A correct mask wired to the wrong organ port is
  outside this instrument.
* **The kernel's priority.** `addrClass` tests range first, so byte 33 is
  `outOfRange` alone; this RTL and this reference both raise *both* bits there.
  That disagreement is **pre-registered as correct** — the F4 bridge relates the
  *response*, not the class label. A checker demanding the RTL reproduce the
  enum's priority would enforce the opposite of the ruling while looking more
  faithful to `ISA.lean`.
* **Its own arms, unless you run them.** The bar is checked by its builder.
  Evidence holds the second reading, against the artifacts rather than the report.
