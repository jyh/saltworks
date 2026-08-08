# ⛔ ROUTE ② LEFT `aluSelect` MUXING TEN — AND ONE SHIFTER FEEDS THREE OF THEM

### 2026-08-07 ~19:0x, SILICON, conveyor pass 6, fired against `ec21bb5` (ALUSEL).
### **This is my own debt: I ruled route ②, I named this consequence, and I
### declined to price it. Four hours on, nothing has reconciled it.**

## 0. The theorem survives — it is the ASSEMBLY that does not

`sem_aluSelect (E : Env)` (`Program.lean:5191`) is **genuinely unconditional**:
quantified over an arbitrary `Env`, no hypotheses, and **total** — it even pins
the out-of-range selector to `false` rather than leaving it undefined. ✅ **No
defect in it.**

## 1. ⛔ The gap

```
AluSelect.lean:57   "Ten op results: add, sub, and, or, xor, slt, sltu,
                     sll, srl, sra."    asOps = 10,  asIn = 324
plan §4 item 8      shifterM   ONE mode-generalised organ: sll / srl / sra   679
plan §4 item 9      aluSelect  muxes the ten                               1,445
Shifter.lean:217    "aluSelect's `srl` slot is fed by this; its `sll` and
                     `sra` slots have no producer"     ← PRE-route-② text
```
⇒ ***Item 8 emits ONE result. Item 9 has THREE shift slots — 96 nets — and route
② left only one producer for them.***

📌 **`grep asOps` outside `AluSelect.lean` returns only `Program.lean`'s proofs.
Nothing in the tree reconciles ten slots with one shifter.**

## 2. 🔴 IT IS THE CARRY-IN HAZARD AT 64× THE WIDTH

The PCADD ledger (`4baf825`) just characterised this exact shape at **one** net:
*"the unallocated flag sitting one wire from an unsourced carry-in port is the
hazard; `pcAddCut_fails_the_theorem` is that hazard as a theorem."*
⇒ **`instOK` requires `∀ i < c.nIn, σ i < off` — every input wire must map to an
already-computed net. An unsourced slot cannot be left dangling; the assembly
must map it to SOMETHING, and the nearest something is whatever net sits at that
index.** ***Here that is 64 nets instead of one, and a wrong map is still
well-formed, still `ssa`, and still passes any certificate that does not select
the mis-fed slot.***

## 3. THE FIX — and the cheap one is also the right one

| | route | cost |
|---|---|---|
| **(a)** | wire `shifterM`'s single output to **all three** shift slots | **0 gates, 0 re-proof** |
| (b) | drop `asOps` 10 → 8, selector 4 → 3 bits | smaller tree, **but it redefines `asIn` 324 → 260 and invalidates `sem_aluSelect`, proved hours ago** |

✅ **(a) IS SEMANTICALLY CORRECT, not merely cheap.** *`aluSelect` returns
`E (asRes sel k)` — result number `sel`. The decoder that picks selector 7, 8 or
9 is the same decoder that drives `shifterM`'s mode bits, so **whichever shift
slot is selected, the value there is the shift that instruction asked for.***
⇒ **All three slots carrying one producer is not a hack; it is the moded
shifter's contract, spelled out in wiring.**
🔑 **And (b)'s real cost is the one worth naming: it would throw away the
freshest unconditional theorem in the campaign to save mux levels nobody has
measured.** *That is the trade I refused to price at 15:20 and can now price:
**don't**.*

## 4. What this does NOT say

* It does **not** refute `sem_aluSelect`, and it does not refute route ②.
* `core` does not exist — this is a **plan** gap, like the pc one, and it is
  cheap now.
* **The debt is mine.** *`Shifter.lean:194` records obligation 6 in my own words
  — "aluSelect drops from 10 sources to 8. Silicon publishes NO number for it" —
  and declining to price a consequence is not the same as discharging it.*
