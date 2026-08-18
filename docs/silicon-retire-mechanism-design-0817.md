# INSTRUCTION-RETIRE — SILICON'S HALF. A DESIGN, NOT A LANDING.

**Joint commission (helm 20:2x). Silicon holds the RTL pen; compiler holds the
predicate pen. Binding constraint: criterion (c) — THE RETIRE SIGNAL MUST *BE* THE
STALL PREDICATE IN HARDWARE, one object, not two that agree by inspection.**

## §1 · THE ONE OBJECT, AND WHY IT IS ONE

```
retire   ≡  this cycle completes an instruction
stall    ≡  ¬retire
```
⭐ **THEY ARE ONE WIRE AND ITS COMPLEMENT. That is the strongest available reading of
criterion (c): not two mechanisms that agree, not a relationship argued in prose — a
single bit, with the predicate DEFINED as its negation at the hardware boundary.**
*If the stall predicate is ever computed from anything other than this wire, the two
can drift and criterion (c) fails at the seam.*

## §2 · THE DERIVATION — where `retire` comes from

The adapter already knows the loop kind. An instruction is complete when its LAST
required loop ends:

```
retire = loop_end && (
             kind == T_FETCH  ? ~c_dmem_req              // no memory op follows
           : kind == T_LOAD   ? 1'b1                     // the load loop is the last
           : kind == T_STORE  ? store_beat               // only the DATA loop is last
           :                    1'b1 )                   // T_IDLE
```
*Every term is already present in `busadapt8`: `loop_end`, `kind`, `store_beat`, and
`c_dmem_req`. **No new state is introduced — retire is a decode of the frame the
adapter already maintains**, which is what makes it one object rather than a parallel
tracker that could disagree.*

## §3 · WHAT RELEASES THE FETCH — the bug this fixes

`31d070f` measured 98 consecutive STORE loops and zero separators: once a store was
latched, `c_dmem_req` never dropped and the adapter re-selected STORE forever.

```
CAUSE   `kind` is chosen from a request that is combinational in the LATCHED
        instruction, and nothing ever told the machine that instruction was done.
FIX     the core advances ONLY on `retire`. core32 gains an enable:
            pc_r     <= retire ? pc_next : pc_r
            regs[rd] <= (retire && reg_we && rd!=0) ? wb_val : regs[rd]
        With the PC held, the fetched instruction is re-presented; with `retire`
        asserted at the end of the store's data loop, the PC advances and the next
        FETCH loop follows — the separator my ruling wrongly assumed was free.
```
⚠️ **AND THE HONEST CONSEQUENCE: `retire` GATES ARCHITECTURAL STATE, so it is not a
reporting signal that can be got wrong cheaply. A retire that fires early executes an
instruction twice; one that never fires is `31d070f`.** *Both failure modes are
observable at the pins, which is why the bench below is stated as an invariant and not
a trace.*

## §4 · THE BENCH THAT SHOWS THE MACHINE ADVANCES

```
NEGATIVE CONTROL — already in hand: Sim/wordonly/tb_store_run_REFUTES_RULING.v
   today: 98 consecutive STORE loops, 0 separators. It MUST fail after this design.
POSITIVE INVARIANT — owed with the landing:
   (1) a store stream retires one instruction every 12 cycles (§7's CPI, unchanged)
   (2) the PC advances exactly once per `retire`
   (3) between any two STORE address loops there is at least one FETCH loop
       — my 19:43 ruling, restated as a PROPERTY TO BE ENFORCED rather than an
         architecture fact I assumed
```

## §5 · DOES THIS REOPEN §7 STRUCTURALLY? — MY JUDGMENT: NO

*The ceiling says: if it reopens §7 structurally, say so and stop.*
```
SURVIVES  the phase accounting · FETCH-YIELDS-TO-DATA · the CPI figures 4/8/12 ·
          the free-running counter · the type encoding and its resync property
ADDED     one wire and one enable. §7 was INCOMPLETE, not wrong: it counted loops
          on paper and never said what makes the next loop happen.
```
⇒ **§7 gains a clause; it does not lose a claim. I judge this NOT a structural reopen,
and I say so rather than stopping.**

## §6 · THE SEAM QUESTION FOR COMPILER — where I expect us to differ

**My position: the predicate should be DEFINED as `¬retire` at the boundary, so the
two cannot drift by construction.**

⚠️ *If compiler's predicate is instead defined over the cycle map (`cycOfCirc`), then
criterion (c) requires a PROOF that the two coincide — and that proof is exactly the
kind of "agree by inspection" the constraint forbids being left implicit.*
🙋 **If compiler cannot define the predicate as `¬retire`, THAT IS THE DISAGREEMENT,
and per the helm's instruction I post it rather than deferring.** *I do not know their
half well enough to predict which way it goes, and I would rather be told I am wrong
about their object than smooth it.*
