# Post-mortem: the RISC-V core that was called verified and was not

**Status: DRAFT for a non-author read (2026-10-05).** Commissioned at council on 2026-10-05; the
Captain's words: *"We worked on this, and discussed it, for an entire month -- so how is it that we
made this mistake."* And: *"the salt method was supposed to prevent failures of this kind, so the
answer is: we didn't use the salt method, and now we pay the price."*

Written by the evidence seat, which is the saltworks lead and is itself one of the parties below.
Every claim cites a commit, a file and line, or a dated record. Anything inferred is marked
**INFERRED**.

## 1. What went wrong — two errors, kept apart

**Error 1, in the design.** The RISC-V core on the chip (`core32.v`, blob `e8a91801`, in the
design of record `jyh/tt-neural-dataflow-fabric@01e19f7`, submitted 2026-09-07) does not implement
three of its 31 in-scope RV32I instructions: **SRA, SRAI and LW**
([step 0](silicon-step0-core32-conformance-1004.md), [erratum](ERRATUM-core32-2026-10-05.md)).
A bus-level riscv-formal run on 2026-10-05 fails on exactly those three instructions; each of its 34
checks that pass (28 instructions + 6 consistency checks) was shown reachable in cover mode, so none
is vacuous
([AAJ](silicon-aaj-bus-formal-1005.md), "Non-vacuity").

**Error 2, in the public record.** From 2026-08-16 to 2026-10-05 this repository's README said the
stack runs "to a **verified** RISC-V processor taped out on a community silicon shuttle". Nothing
ever verified that processor. The sentence was corrected on 2026-10-05 (README, "Correction,
2026-10-05").

The two are independent. Had the core been perfect, the sentence would still have been false,
because nothing checked the core. Had the sentence said "a RISC-V processor", the defects would still
be in the silicon. The salt method addresses Error 2 directly. It reaches Error 1 only if the method
is applied to the core, and it was not.

## 2. Timeline

| date | what happened | source |
|---|---|---|
| 08-07 | The standalone ALU block computes SRA correctly: `alu32.v:19` `assign r_sra = $signed(a) >>> b[4:0];`. Re-simulated for this report: `fffffff0 >>> 2` gives `fffffffc`. | `6deaeb2` |
| 08-07 | The control block decodes OP-IMM as `{1'b0, funct3}`, which drops the bit that tells SRAI from SRLI. **SRAI is wrong from its first line.** | `84a10d5`, `ctrl32.v:35` |
| 08-07 | `core32.v` is assembled from the blocks as a synthesis-census specimen. Its header says *"NOT a submission artifact."* Inlining the ALU into one `?:` chain whose other arms are unsigned turns the shift logical. **SRA regresses here.** Neither line is edited again before tapeout. | `46bb4fa`; `git log -S` on both lines |
| 08-07 | Council: the Lean ISA model gets Spike-generated vectors now; `riscv-tests` is "promoted to the C5-era integration tier". The vectors check the Lean model. The C5 tier, as later defined, contains no ISA suite, and no suite ever ran on the RTL. | `docs/riscv-core-campaign-v0.md:69-70`; `docs/hdl-c2-vector-design-0807.md:1-6` |
| 08-09 | **The evidence seat's claim fence** sorts uses of "verified" and grades the phrase *"verified RISC-V core"* as *"A LANDED PROOF ARTIFACT. Real, checkable, has a commit."* Its referent was the Lean model, but the phrase it blessed was the one that later went public. | `docs/EVIDENCE-neural-claim-fence-0809.md:24-25` (`300607b`) |
| 08-11 | The machine-checked certificate states the scope correctly: *"'RV32I' IS NOT WHAT IS PROVED"*. It lists the shifts among the encodings the model refuses, written so that a reader sizing "a verified RISC-V processor" can see the gap. | `SaltWorks/Certs/All.lean:143-152` (`5015407`) |
| 08-11/12 | The paper draft's abstract takes the Captain's sentence "a formally verified RISC-V processor **design** taped out". A compression pass (577 → 189 words) checks that every claim it cuts survives in the body. It does not check whether the surviving sentence got **stronger**. "Formally" and "design" go, and "verified RISC-V processor" stays. | the paper's draft history |
| 08-16 | The public flip. The README opener is drawn from that abstract, and this sentence enters the repo. The flip-day review checks the README's **table rows**, each seat its own row. Nobody checks the **opening sentence**. A "processor-vs-slice noun check" on the opener is left to the Captain's glance, with no owner, no release condition and no recorded resolution. | `9a8f5ec`; the 08-16 sitting record |
| 08-17 | The bus adapter `busadapt8.v` is written with a registered load output, `assign c_dmem_rdata = rdata_r;`. `rdata_r` captures the loaded word on the same clock edge at which the core writes `rd` from it. **LW is wrong from here.** | `f0a1e18`, `busadapt8.v:118` |
| 08-18 | The **same off-by-one on the instruction path** is found (*"IT IS OFF BY ONE"*) and fixed with a phase-3 bypass on `c_instr`. The data path gets no bypass. The LW probe, re-run for this report on the 08-18 adapter, gives results byte-identical to the fabricated one, so the LW defect predates every later adapter change. | `f18f7bd`; `25127f3` |
| 08-18 | `core32` becomes the shipping core on a **fit** ruling: *"I believe at 70-88% it will fit. Let's show it."* No ISA-correctness bar is stated. The "NOT a submission artifact" header stays, and is still in the fabricated file. | `1f18fae`; `01e19f7:src/core32.v:4` |
| 08-20 | **The gap is found and half-fixed.** A venue review says of the abstract's "verified RISC-V processor": "Strike 'verified'", because it contradicts the 08-10 scope sentence. The paper is fixed. The same day an evidence sweep for the second paper records as MEASURED that the shipped README's "verified RISC-V processor" *"sits above the tree's own `c4Spec_core_is_false`"*. Neither finding becomes a task with an owner, and **the README, the copy the public reads, keeps the sentence for 45 more days.** | the paper's history; the 08-20 sweep |
| 08-29 | Council finds a load-address defect in the Lean model, not the RTL: *"the RTL computed the address correctly throughout."* Retold the same morning as *"the RTL was right throughout."* **INFERRED:** this widening is the earliest form of the belief that the defects lived in the model. | the 08-29 minute and its bus close |
| 09-02–09-09 | Two seats repeat the correct fence a dozen times: the netlist the Lean side reasons about *"is NOT core32.v … and no theorem relates them."* Each instance is a caveat on an internal Lean claim; none is applied to the README. On 09-09 a load-path claim, *"the fabricated RTL does NOT share that defect"*, is measured on `core32` **alone**, where load data arrives in the same cycle. The LW defect lives at the core-to-adapter seam that this bench leaves out. | `CoreConformsClosed.lean:24-28`; the 09-02..09-09 record |
| 09-05–09-07 | Submission. The lead's (evidence's) submission audit is deep on the bus protocol: `sof` resync, the GDS run, the datasheet's resync warning. **The core's ISA behaviour is never on its list** (in that window's record `sof` appears ~350 times and `riscv`/`rv32` not at all). The datasheet's "what is proved and what is not" names the core in neither list. | `01e19f7:docs/info.md:63-70` |
| 10-04 | A talk-preparation seat flags that the README's "verified RISC-V processor" is not backed. The Captain defends it (*"it isn't verified in lean, but across a variety of hardware tools"*). The helm traces every method to answer him and finds SRA/SRAI in simulation. He doubts it (*"we've made mistakes here before"*), and step 0 confirms SRA/SRAI on the signed-off netlist and finds LW. | step 0 |
| 10-05 | Council orders this post-mortem, the formal check, and the public correction, which merged the same day. | README; the erratum |

## 3. The six questions

**(1) When did "verified RISC-V processor" enter the README, and what evidence existed that day?**
On 2026-08-16 (`9a8f5ec`), drawn from the paper abstract. That day the evidence was a Lean model of
seven instructions (ADD, ADDI, XOR, SLT, BEQ, LW, SW; `HDL/ISA.lean:126-158`; shifts excluded, LW
atomic with no bus), checked against its own encoder and 120 Spike vectors. There was also a
synthesis specimen, `core32.v`, that carried both shift defects and called itself not a submission
artifact. **Nothing on that day was simultaneously verified, a RISC-V processor, and taped out.**
The sentence described an intention: the campaign plan was a Lean-emitted, verified CPU.

**(2) What was checked at each date, and against what?**

| object | checked by | what that reaches |
|---|---|---|
| the Lean ISA model (7 instructions) | kernel: encoder/decoder round trip; 120 Spike vectors | the model only |
| the Lean-emitted circuit | kernel: `emitted_core_realises_the_step`, memory-free words only (`CoreConformsClosed.lean:178-184`) | a circuit that is **not** `core32.v` |
| the MAC cells | exhaustive SAT miters | the MAC cells only; `core32` appears 0 times in the SAT tools |
| `core32.v` + `busadapt8.v` (fabricated) | RTL/GL simulation of **bus-protocol** properties: retire, store accounting, `sof` resync, traps | protocol, never instruction semantics |
| the fabricated top | the chip CI's `test.py` | *"All this asserts is that the pins are not stuck"* (`01e19f7:test/test.py:120`); functional checking is deferred to `tb_plane32bus_lwsw` |

No theorem and no suite ever related `core32.v` to RV32I before 2026-10-04.

**(3) Where was the gap visible, and who saw it?** In at least five places before tapeout: the
fabricated file's own header (08-07 onward), the certificate's scope refusal (08-11), the 08-20
venue review and evidence sweep (which named the README itself), and the "no theorem relates" fence
repeated on 09-02–09-09. Silicon, compiler, evidence and the helm each saw part of it. **Every one of
them saw it as a limit on an internal claim, and nobody carried it to the public sentence.** The
one place that did name the README (08-20) produced a finding, not a task.

**(4) Why did the tests pass?**
- **No bench ever issued SRA or SRAI.** Decoding every instruction word in every pre-tapeout bench
  that touches `core32` finds zero of either.
- **Every bench that issued LW either served constant data or looped one program over one
  address.** `tb_plane32bus_lwsw` (the bench the chip CI defers to) aliases a four-word
  ADDI/SW/LW/NOP program over the whole address space and runs it 600 times. A load that returns the
  previous load's word returns the right word on every pass after the first. Before 09-04 it passed
  for a second reason: memory was all zeros.
- The 08-18 commit that fixed the instruction-path twin of the LW defect wrote down this exact blind
  spot: *"A one-instruction lag is INVISIBLE to the type stream."* It was applied to one path of two.

**(5) Why did no gate stop a public claim outrunning its evidence?** Because no gate read public
**prose** for verification claims. The scrub gates read public text for private paths, session
trailers and lane names, which is what they were built for, and they did that job. The claim fence
that does read verification words (`claim_fence.py`) carries a fixed phrase list without this phrase,
and its own author had graded the phrase "real". The flip-day review was organised by table row, and
the opener was nobody's row. When the gap was named on 08-20, the fleet's rule that a finding lives on
a swept surface with an owner was not applied, so the finding reached a paper and not the README.

**(6) What changes, so it cannot recur?** Below.

## 4. What the salt method would have required, and what we did instead

The method's rule is that a claim travels as a kernel-checked artifact, and human attention goes to
**statements**. Applied here:

- **"Verified" is a claim about a theorem, so it must name one.** The README sentence named none,
  and none existed. Under the method, a public "verified X" with no theorem whose subject is X is a
  defect on sight.
- **The core needed a statement relating it to RV32I.** It had one about a different object (the
  model), plus a fence saying so. The method would have made "no theorem relates the model to
  `core32.v`" a blocking condition on any claim about `core32.v`, not a caveat beside it.
- **Where a theorem was out of reach in the time, a conformance run is the measured substitute.**
  It costs about a minute (step 0 reproduces in ~60 s), and a bus-level formal check costs one to two
  days. Neither was run, because the core was never the object of the verification campaign. It was
  promoted into the chip on a fit ruling while still labelled a specimen.

The Captain's sentence is accurate: we did not use the salt method on the core, and the README
spoke as if we had.

## 5. Recommendations (for council; none is adopted by this document)

1. **A public verification claim names its check.** Every "verified" / "proved" / "machine-checked"
   in a public README or abstract cites the theorem or suite whose subject it is, and a CI arm
   refuses such a word in public prose without a citation. *Wrong if:* a public sentence asserting
   verification passes CI with no cited check.
2. **A finding about a public surface is a task with an owner, on a swept surface, and names every
   copy.** The 08-20 fix reached one copy of two. *Wrong if:* a correction to one public copy lands
   while another copy of the same sentence remains.
3. **"NOT a submission artifact" is machine-read at submission.** A submission gate refuses any
   submitted source carrying that marker, or a stated equivalent, until the marker is resolved by
   name. *Wrong if:* a submitted design carries the marker.
4. **A processor is not submitted without an ISA conformance run at the level that includes its bus**
   (core + adapter, where LW lives), and a load bench must load **distinct** words from **distinct**
   addresses, never one looped program. *Wrong if:* a core reaches tapeout with an in-scope
   instruction no bench issued.
5. **A fence is applied where it binds.** When a record says "no theorem relates A to B", the public
   text is searched for claims about B the same day. *Wrong if:* a fence stands while public prose
   claims what it fences.
6. **The evidence seat's 08-09 claim fence is corrected in place** (annotated, not rewritten), so the
   document that graded the phrase "real" says what it got wrong.

## 6. What this does not establish

- That no other defect exists in the core (see the erratum's limits). The formal run's 34 passes are
  non-vacuous but BOUNDED (checks at cycle 24 and 48); only LW's failure shape is proved for all
  trace lengths ([AAJ](silicon-aaj-bus-formal-1005.md)).
- Who, if anyone, would have caught Error 2 had the 08-20 finding been routed. The record shows the
  route was missing, not that it would have worked.
- **INFERRED, not shown:** that the depth of the bus-protocol audit at submission was read as "the
  core was checked". No record says so.
