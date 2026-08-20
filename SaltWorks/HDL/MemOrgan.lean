/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.SsaGateSem
import SaltWorks.HDL.StateCodec

/-!
# Q3 · HORN D, part 1 — THE MEMORY ORGAN, PRICED BY CONSTRUCTION

⛔ **THIS FILE DOES NOT TOUCH `stWidth`.** Horn D's real form widens
`SaltWorks/HDL/StateCodec.lean`'s `stWidth` from 1056 to 1313, and
`instrBase := stWidth` DEFINITIONALLY, so that change renumbers every instruction
net and every gate offset in the tree. **The organ below is built ALONGSIDE the
landed codec, in its own net space**, so its cost and its proofs are known BEFORE
anything in the tracked tree moves. Nothing here is imported by anything.

## What is priced here

An 8-word × 32-bit memory organ as one `Circ`:

* a **READ port** — a 3-bit word address drives an 8:1 mux per output bit, all
  32 bits;
* a **WRITE path** — address decode, a per-word write enable, and a 2:1 mux per
  stored bit, producing all 256 next-state bits.

**THE GATE COUNT IS `memOrgan_gate_count`: 1,475, by `decide +kernel`.** Its
decomposition, which `memOrgan_block_sizes` pins block by block:

```
  3    address inverters              ¬a0 ¬a1 ¬a2, SHARED by every mux
 16    word selects                   8 words × 2 gates (a 3-literal AND chain)
  8    per-word write enables         wen w = sel w ∧ we
  8    write-enable inverters         ¬wen w, SHARED by that word's 32 bit-muxes
────
 35    decode
672    read port                      32 bits × 7 muxes × 3 gates
768    write path                     8 words × 32 bits × 3 gates
────
1475
```

## `Op` IS SUFFICIENT — and the reason is the encoding, not luck

`Op` is `const / not / and / or / xor` and there is **no sequential
constructor**. It does not need one. **A flop is not a gate**: the current memory
contents arrive as *primary input nets* (the Q-leaves, `mQ w k`) and the next
contents leave as *primary outputs* (the D-roots, `mNextNet w k`). The state
lives in the encoding across a step — exactly as `encD`/`decQ` already carry
`regs` and `pc` — so this organ is combinational like every other block in the
corpus.

⇒ **NO WALL ON THE LANGUAGE.** The organ uses `not / and / or` only; `const` is
not even needed, because unlike `readTree` (whose leaf 0 is the `x0` tie) all 8
words here are real storage.

## Net layout

```
0 … 2        addr[0..2]        the word address
3            we                write enable
4 … 35       wdata[0..31]      write data
36 … 291     mem[w][k]         Q-leaf of word w bit k, at 36 + 32*w + k
             mIn = 292
292 … 326    decode            35 gates
327 … 998    read port         672 gates
999 … 1766   write path        768 gates
```

Port order is **part of the data, not a convention**: outputs `0 … 31` are the
read port LSB-first; outputs `32 … 287` are the next-state bits in the same
`32*w + k` order the Q-leaves use.
-/

namespace SaltWorks.HDL

-- ⚠️ The gate list is 1,475 long and `run` is structural on it, so any defeq the
-- elaborator resolves by UNFOLDING `run` recurses 1,475 deep. 4000 is a real ceiling
-- (not a blank cheque): a genuine loop still fails, and fast.
set_option maxRecDepth 4000

/-! ### Sizes -/

/-- Words of memory. Matches `St.mem : Vector (BitVec 32) 8`. -/
def mWords : Nat := 8
/-- Bits per word. -/
def mWidth : Nat := 32
/-- Address bits: 3 bits select one of 8 words. -/
def mAddrBits : Nat := 3

/-! ### The input nets -/

/-- Address bit `j`, on nets `0 … 2`. -/
def mAddrNet (j : Nat) : Nat := j
/-- The write enable, on net `3`. -/
def mWeNet : Nat := 3
/-- Write-data bit `k`, on nets `4 … 35`. -/
def mWData (k : Nat) : Nat := 4 + k
/-- **The Q-leaf of word `w`, bit `k`** — the current memory contents, on nets
`36 … 291`. -/
def mQ (w k : Nat) : Nat := 36 + 32 * w + k
/-- Primary input width: `3 + 1 + 32 + 256`. -/
def mIn : Nat := 292

theorem mIn_value : mIn = 3 + 1 + 32 + 256 := by decide +kernel

/-! ### The decode block — 35 gates from `mIn` -/

/-- `¬addr[j]`, on nets `292 … 294`. **One per address bit, SHARED by every mux
at that level** — the sharp edge `ReadTree.lean` records: a peephole that ate one
would corrupt every mux selecting on that bit. -/
def mNotA (j : Nat) : Nat := mIn + j
/-- The partial AND of word `w`'s first two address literals. -/
def mSelT (w : Nat) : Nat := mIn + 3 + 2 * w
/-- `sel w` — the one-hot word select, true exactly when `addr = w`. -/
def mSel (w : Nat) : Nat := mIn + 4 + 2 * w
/-- `wen w = sel w ∧ we`. -/
def mWen (w : Nat) : Nat := mIn + 19 + w
/-- `¬wen w`, shared by word `w`'s 32 bit-muxes. -/
def mNWen (w : Nat) : Nat := mIn + 27 + w

/-- Address literal `j` for word `w`: the address bit itself when `w` has that
bit set, otherwise its (shared) inverter. -/
def mLit (j w : Nat) : Nat := if w.testBit j then mAddrNet j else mNotA j

/-- The decode block, in allocation order. -/
def mDecodeG : List Gate :=
  [⟨mNotA 0, .not (mAddrNet 0)⟩, ⟨mNotA 1, .not (mAddrNet 1)⟩,
   ⟨mNotA 2, .not (mAddrNet 2)⟩]
  ++ (List.range 8).flatMap (fun w =>
       [(⟨mSelT w, .and (mLit 0 w) (mLit 1 w)⟩ : Gate),
        (⟨mSel w, .and (mSelT w) (mLit 2 w)⟩ : Gate)])
  ++ (List.range 8).map (fun w => (⟨mWen w, .and (mSel w) mWeNet⟩ : Gate))
  ++ (List.range 8).map (fun w => (⟨mNWen w, .not (mWen w)⟩ : Gate))

/-! ### The 2:1 mux — three gates, the corpus's own idiom

`ReadTree.lean`'s `rtMux` exactly: `and(x, ¬s)`, `and(y, s)`, `or`. Output `b+2`
carries `x` when `s` is low and `y` when `s` is high. -/

/-- Three gates forming one 2:1 mux at base net `b`; the output is `b + 2`. -/
def mMux (b x y s ns : Nat) : List Gate :=
  [⟨b, .and x ns⟩, ⟨b + 1, .and y s⟩, ⟨b + 2, .or b (b + 1)⟩]

/-! ### The read port — 21 gates per output bit -/

/-- First net of the read port. -/
def mReadBase : Nat := mIn + 35
/-- Base of level-0 mux `j` (`j < 4`) of output bit `k`. -/
def mL0 (k j : Nat) : Nat := mReadBase + 21 * k + 3 * j
/-- Base of level-1 mux `i` (`i < 2`) of output bit `k`. -/
def mL1 (k i : Nat) : Nat := mReadBase + 21 * k + 12 + 3 * i
/-- Base of the level-2 (root) mux of output bit `k`. -/
def mL2 (k : Nat) : Nat := mReadBase + 21 * k + 18
/-- **The read port's bit `k`** — the root of that bit's 8:1 tree. -/
def mReadNet (k : Nat) : Nat := mL2 k + 2

/-- Output bit `k`'s 8:1 mux tree: four muxes on `addr[0]`, two on `addr[1]`,
one on `addr[2]`. Written as seven explicit `mMux`es rather than through a
recursive builder — the universal proof below reads each one by membership, and
an explicit list makes every membership a `List.mem_append`. -/
def mBitGates (k : Nat) : List Gate :=
  mMux (mL0 k 0) (mQ 0 k) (mQ 1 k) (mAddrNet 0) (mNotA 0) ++
  mMux (mL0 k 1) (mQ 2 k) (mQ 3 k) (mAddrNet 0) (mNotA 0) ++
  mMux (mL0 k 2) (mQ 4 k) (mQ 5 k) (mAddrNet 0) (mNotA 0) ++
  mMux (mL0 k 3) (mQ 6 k) (mQ 7 k) (mAddrNet 0) (mNotA 0) ++
  mMux (mL1 k 0) (mL0 k 0 + 2) (mL0 k 1 + 2) (mAddrNet 1) (mNotA 1) ++
  mMux (mL1 k 1) (mL0 k 2 + 2) (mL0 k 3 + 2) (mAddrNet 1) (mNotA 1) ++
  mMux (mL2 k) (mL1 k 0 + 2) (mL1 k 1 + 2) (mAddrNet 2) (mNotA 2)

/-- All 32 read trees. -/
def mReadG : List Gate := (List.range 32).flatMap mBitGates

/-! ### The write path — one 2:1 mux per stored bit -/

/-- First net of the write path. -/
def mWriteBase : Nat := mIn + 707
/-- Base of word `w` bit `k`'s next-state mux. -/
def mWNet (w k : Nat) : Nat := mWriteBase + 3 * (32 * w + k)
/-- **The D-root of word `w`, bit `k`.** -/
def mNextNet (w k : Nat) : Nat := mWNet w k + 2

/-- The write path: hold `mem[w][k]` when `¬wen w`, take `wdata[k]` when
`wen w`. **The data is broadcast to every word and only the enable is decoded** —
silicon's measured read/write asymmetry, in gates. -/
def mWriteG : List Gate :=
  (List.range 8).flatMap (fun w =>
    (List.range 32).flatMap (fun k =>
      mMux (mWNet w k) (mQ w k) (mWData k) (mWen w) (mNWen w)))

/-! ### The organ -/

def mGates : List Gate := mDecodeG ++ mReadG ++ mWriteG

/-- The 256 D-roots, in `32*w + k` order. -/
def mNextOuts : List Net :=
  (List.range 8).flatMap (fun w => (List.range 32).map (mNextNet w))

/-- Read port first (32), then the 256 next-state bits. -/
def mOuts : List Net := (List.range 32).map mReadNet ++ mNextOuts

/-- ⭐ **THE ORGAN.** -/
def memOrgan : Circ := { nIn := mIn, gates := mGates, outs := mOuts }

/-! ## ⭐⭐ THE NUMBER — the hole in the price, MEASURED

`decide +kernel`, so this is a kernel-checked evaluation of `List.length` over
the gate list an emitter would consume — not an estimate, and not an `#eval`. -/

/-- ⭐⭐⭐ **THE MEMORY ORGAN IS 1,475 GATES.** -/
theorem memOrgan_gate_count : memOrgan.gates.length = 1475 := by decide +kernel

/-- The three blocks, priced separately — so a read-only or write-only variant
can be priced without re-deriving anything. -/
theorem memOrgan_block_sizes :
    mDecodeG.length = 35 ∧ mReadG.length = 672 ∧ mWriteG.length = 768 := by
  decide +kernel

/-- 292 primary inputs, 288 primary outputs. -/
theorem memOrgan_ports :
    memOrgan.nIn = 292 ∧ memOrgan.outs.length = 288 := by decide +kernel

/-! ## ⭐⭐ RECONCILIATION AGAINST THE LANDED SILICON MEASUREMENT

⛔ **THIS NUMBER IS NOT A HOLE-FILL — SILICON PRICED THIS ORGAN ON 2026-08-08 AND I
FOUND THAT ONLY AFTER MEASURING.** `docs/silicon-slice-b-memory-cells-0808.md` and
`SaltWorks/Silicon/Flow/dmem8_stat.txt` price `SaltWorks/Silicon/RTL/dmem8.v` — **the same
microarchitecture as this organ**: 8 words × 32 bits, word-addressed, no byte enables, one
combinational read port, synchronous write.

```
                                    THIS FILE (kernel Circ)     SILICON (yosys+abc, sky130)
write path      8 × 32 2:1 muxes    256 muxes = 768 gates       256 sky130…__mux2_1   ⬅ EXACT
read port       32 × 8:1 trees      224 muxes = 672 gates    ⎫  161 AOI/NAND cells
address decode  3 inv + selects      35 gates                ⎭  (a222oi/a22oi/nand3/nand4…)
the array       256 bits            NOT IN THE Circ             256 sky130…__dfrtp_1
                                    ────────────────────       ────────────────────
                                    1,475 gates                 673 cells (417 comb + 256 flop)
```

⭐ **THE WRITE PATH AGREES EXACTLY AND BY TWO INSTRUMENTS: 256 muxes here, 256 `mux2_1`
there** — one derived from this `Circ`, the other by `abc` from Verilog, with no shared
input. That is the same two-tools-one-structure signal silicon recorded for `dmem32` vs
`readTree`, and it is pinned as a theorem below.

⚠️ **THE TWO COUNTS ARE DIFFERENT COLUMNS AND MUST NOT BE SUBTRACTED.** 1,475 is *pre-abc
kernel gates* (a 2:1 mux is three `Op`s); 673 is *post-abc standard cells* and includes the
256 flops this `Circ` cannot contain, because state lives in the encoding across a step.
Silicon's §2 names exactly this trap. The ratio 1475 : 417 combinational cells is 3.54×,
which is the doc's own "one `mux2_1` does the work of three kernel gates" plus AOI
compression on the read tree.

🔑 **AND THE LIKE-FOR-LIKE COMPARISON THE DOC COULD NOT MAKE IS NOW AVAILABLE.** The
banked budget is **1,154 GATES** — a *pre-abc, structural* figure. Silicon had only a
post-abc cell count to set beside it, and wrote: *"673 CELLS against a 1,154-GATE budget.
By COUNT it looks like the organ fits with 42% to spare. IT DOES NOT — by AREA it is
1.50× over."* ⇒ ***In the budget's OWN unit the organ is 1,475 gates: 1.28× over, 321
gates short. The count axis now agrees with the area axis instead of contradicting it.***

⚠️ **ONE DIFFERENCE, STATED BECAUSE IT MOVES THE NUMBER IN THE UNFAVOURABLE DIRECTION:**
`dmem8.v` has an ASYNC RESET clearing the array; this `Circ` has none. Adding it is
per-flop reset logic, so 1,475 is a **lower bound** on the reset-bearing variant, not an
estimate of it. -/

/-- ⭐⭐ **TWO INSTRUMENTS, ONE STRUCTURE: the write path is exactly 256 2:1 muxes.**
`yosys`+`abc` on `dmem8.v` emitted exactly **256 `sky130_fd_sc_hd__mux2_1`*
(`SaltWorks/Silicon/Flow/dmem8_stat.txt`). Same number, no shared input. -/
theorem memOrgan_write_is_256_muxes : mWriteG.length = 3 * 256 := by decide +kernel

/-- The read port is 224 muxes — `32 bits × (4 + 2 + 1)`. -/
theorem memOrgan_read_is_224_muxes : mReadG.length = 3 * 224 := by decide +kernel

/-- ⛔ **THE ORGAN EXCEEDS THE 1,154-GATE BANKED BUDGET**, in the budget's own pre-abc
unit. *Stated as a theorem so the comparison cannot drift: both sides are gates.* -/
theorem memOrgan_exceeds_banked_budget : 1154 < memOrgan.gates.length := by decide +kernel

/-! ## Structural certificates -/

/-- **Dense SSA** — gate `i` defines net `mIn + i` and every fanin is below its
own output. This is the precondition `Compose.instOK` needs to place the organ
inside a host, and it is what `run_gate_val` consumes below. -/
theorem memOrgan_ssa : memOrgan.ssa = true := by decide +kernel

theorem memOrgan_ssaFrom : ssaFrom mIn memOrgan.gates = true := by decide +kernel

/-- **Well-formed**, via `Circ.wf_of_ssa` — `nodupB` is O(n²) and a direct
`decide` on it at this size is the wall `ReadTree.lean` measured. -/
theorem memOrgan_wf : memOrgan.wf = true := Circ.wf_of_ssa memOrgan_ssa

/-! ## ⭐⭐ THE SEMANTIC CERTIFICATE — UNIVERSAL, NOT SAMPLED

⛔ **READ THIS BEFORE QUOTING THE THEOREMS BELOW.** `mem_read_correct`,
`mem_next_correct` and `sem_memOrgan_read_port` are quantified over
**`∀ ins : Env`** — every valuation of every net, and every one of the 32 (resp.
256) output bits. They are **not** driver-sampled certificates like
`readTree_selects_correctly_on_sample`, and they carry no `_on_sample` suffix
because there is no sample: no one-cold fixture, no enumerated address list, no
`decide` over a driver.

**The tool that makes it affordable is `SsaGateSem.run_gate_val`:** in a dense-SSA
gate list a gate's output net holds its op applied to the *final* environment, so
1,475 gates read as 1,475 simultaneous equations and each output bit's tree
collapses in seven rewrites. -/

/-- The organ's final net valuation, under primary inputs `ins`. -/
def mV (ins : Env) : Env := run ins memOrgan.gates

/-- Every gate's output net holds its operation. -/
theorem mGateVal (ins : Env) (g : Gate) (hg : g ∈ memOrgan.gates) :
    mV ins g.out = g.op.eval (mV ins) :=
  run_gate_val ins memOrgan.gates mIn memOrgan_ssaFrom hg

/-- A primary input keeps its value through the whole organ. -/
theorem mInputVal (ins : Env) (n : Nat) (hn : n < mIn) : mV ins n = ins n :=
  run_below_base ins memOrgan.gates mIn n memOrgan_ssaFrom hn

/-! ### Membership plumbing -/

theorem mDecode_mem {g : Gate} (hg : g ∈ mDecodeG) : g ∈ memOrgan.gates := by
  simp only [memOrgan, mGates, List.mem_append]
  exact Or.inl (Or.inl hg)

theorem mRead_mem {g : Gate} (hg : g ∈ mReadG) : g ∈ memOrgan.gates := by
  simp only [memOrgan, mGates, List.mem_append]
  exact Or.inl (Or.inr hg)

theorem mWrite_mem {g : Gate} (hg : g ∈ mWriteG) : g ∈ memOrgan.gates := by
  simp only [memOrgan, mGates, List.mem_append]
  exact Or.inr hg

theorem mBitGates_mem {k : Nat} (hk : k < 32) {g : Gate} (hg : g ∈ mBitGates k) :
    g ∈ memOrgan.gates :=
  mRead_mem (List.mem_flatMap.mpr ⟨k, List.mem_range.mpr hk, hg⟩)

theorem mWriteMux_mem {w k : Nat} (hw : w < 8) (hk : k < 32) {g : Gate}
    (hg : g ∈ mMux (mWNet w k) (mQ w k) (mWData k) (mWen w) (mNWen w)) :
    g ∈ memOrgan.gates :=
  mWrite_mem (List.mem_flatMap.mpr
    ⟨w, List.mem_range.mpr hw,
      List.mem_flatMap.mpr ⟨k, List.mem_range.mpr hk, hg⟩⟩)

/-! ### One mux, read universally -/

/-- ⭐ **A 2:1 MUX AT `b` COMPUTES A 2:1 MUX** — for every environment. -/
theorem mMuxVal (ins : Env) (b x y s ns : Nat)
    (hsub : ∀ g ∈ mMux b x y s ns, g ∈ memOrgan.gates) :
    mV ins (b + 2) = ((mV ins x && mV ins ns) || (mV ins y && mV ins s)) := by
  have h0 : mV ins b = (mV ins x && mV ins ns) :=
    mGateVal ins ⟨b, .and x ns⟩ (hsub ⟨b, .and x ns⟩ (by simp [mMux]))
  have h1 : mV ins (b + 1) = (mV ins y && mV ins s) :=
    mGateVal ins ⟨b + 1, .and y s⟩ (hsub ⟨b + 1, .and y s⟩ (by simp [mMux]))
  have h2 : mV ins (b + 2) = (mV ins b || mV ins (b + 1)) :=
    mGateVal ins ⟨b + 2, .or b (b + 1)⟩ (hsub ⟨b + 2, .or b (b + 1)⟩ (by simp [mMux]))
  rw [h2, h0, h1]

/-! ### The address, as a number -/

/-- The word address the primary inputs name. -/
def mAddrOf (ins : Env) : Nat :=
  (if ins (mAddrNet 0) then 1 else 0)
  + 2 * (if ins (mAddrNet 1) then 1 else 0)
  + 4 * (if ins (mAddrNet 2) then 1 else 0)

theorem mAddrOf_lt (ins : Env) : mAddrOf ins < 8 := by
  simp only [mAddrOf]
  split <;> split <;> split <;> omega

/-! ### The shared inverters and the decode literals -/

theorem mNotA_val (ins : Env) (j : Nat) (hj : j < 3) :
    mV ins (mNotA j) = !(ins (mAddrNet j)) := by
  have hmem : (⟨mNotA j, .not (mAddrNet j)⟩ : Gate) ∈ mDecodeG := by
    simp only [mDecodeG, List.mem_append]
    refine Or.inl (Or.inl (Or.inl ?_))
    interval_cases j <;> simp
  have h : mV ins (mNotA j) = !(mV ins (mAddrNet j)) :=
    mGateVal ins ⟨mNotA j, .not (mAddrNet j)⟩ (mDecode_mem hmem)
  rw [h, mInputVal ins (mAddrNet j) (by simp only [mAddrNet, mIn]; omega)]

theorem mLit_val (ins : Env) (j w : Nat) (hj : j < 3) :
    mV ins (mLit j w)
      = (if w.testBit j then ins (mAddrNet j) else !(ins (mAddrNet j))) := by
  by_cases h : w.testBit j
  · rw [mLit, if_pos h, if_pos h]
    exact mInputVal ins (mAddrNet j) (by simp only [mAddrNet, mIn]; omega)
  · rw [mLit, if_neg h, if_neg h]
    exact mNotA_val ins j hj

/-! ## ⭐⭐⭐ THE READ PORT RETURNS THE ADDRESSED WORD — ∀ ins, ∀ bit -/

/-- ⭐⭐⭐ **THE READ PORT, UNIVERSALLY.** For **every** environment and **every**
one of the 32 output bits, the read port's bit `k` is bit `k` of the memory word
the address names.

⚠️ **NOT A SAMPLE.** `ins` is universally quantified. Compare
`readTree_selects_correctly_on_sample`, which is one file content and one port
bit. -/
theorem mem_read_correct (ins : Env) (k : Nat) (hk : k < 32) :
    mV ins (mReadNet k) = ins (mQ (mAddrOf ins) k) := by
  have ha0 : mV ins (mAddrNet 0) = ins (mAddrNet 0) := mInputVal ins _ (by decide)
  have ha1 : mV ins (mAddrNet 1) = ins (mAddrNet 1) := mInputVal ins _ (by decide)
  have ha2 : mV ins (mAddrNet 2) = ins (mAddrNet 2) := mInputVal ins _ (by decide)
  have hn0 : mV ins (mNotA 0) = !(ins (mAddrNet 0)) := mNotA_val ins 0 (by decide)
  have hn1 : mV ins (mNotA 1) = !(ins (mAddrNet 1)) := mNotA_val ins 1 (by decide)
  have hn2 : mV ins (mNotA 2) = !(ins (mAddrNet 2)) := mNotA_val ins 2 (by decide)
  have hq : ∀ w : Nat, w < 8 → mV ins (mQ w k) = ins (mQ w k) := by
    intro w hw
    exact mInputVal ins _ (by simp only [mQ, mIn]; omega)
  have e00 := mMuxVal ins (mL0 k 0) (mQ 0 k) (mQ 1 k) (mAddrNet 0) (mNotA 0)
    (fun g hg => mBitGates_mem hk (by
      simp only [mBitGates, List.mem_append]
      exact Or.inl (Or.inl (Or.inl (Or.inl (Or.inl (Or.inl hg)))))))
  have e01 := mMuxVal ins (mL0 k 1) (mQ 2 k) (mQ 3 k) (mAddrNet 0) (mNotA 0)
    (fun g hg => mBitGates_mem hk (by
      simp only [mBitGates, List.mem_append]
      exact Or.inl (Or.inl (Or.inl (Or.inl (Or.inl (Or.inr hg)))))))
  have e02 := mMuxVal ins (mL0 k 2) (mQ 4 k) (mQ 5 k) (mAddrNet 0) (mNotA 0)
    (fun g hg => mBitGates_mem hk (by
      simp only [mBitGates, List.mem_append]
      exact Or.inl (Or.inl (Or.inl (Or.inl (Or.inr hg))))))
  have e03 := mMuxVal ins (mL0 k 3) (mQ 6 k) (mQ 7 k) (mAddrNet 0) (mNotA 0)
    (fun g hg => mBitGates_mem hk (by
      simp only [mBitGates, List.mem_append]
      exact Or.inl (Or.inl (Or.inl (Or.inr hg)))))
  have e10 := mMuxVal ins (mL1 k 0) (mL0 k 0 + 2) (mL0 k 1 + 2) (mAddrNet 1) (mNotA 1)
    (fun g hg => mBitGates_mem hk (by
      simp only [mBitGates, List.mem_append]
      exact Or.inl (Or.inl (Or.inr hg))))
  have e11 := mMuxVal ins (mL1 k 1) (mL0 k 2 + 2) (mL0 k 3 + 2) (mAddrNet 1) (mNotA 1)
    (fun g hg => mBitGates_mem hk (by
      simp only [mBitGates, List.mem_append]
      exact Or.inl (Or.inr hg)))
  have e2 := mMuxVal ins (mL2 k) (mL1 k 0 + 2) (mL1 k 1 + 2) (mAddrNet 2) (mNotA 2)
    (fun g hg => mBitGates_mem hk (by
      simp only [mBitGates, List.mem_append]
      exact Or.inr hg))
  simp only [mReadNet]
  rw [e2, e10, e11, e00, e01, e02, e03,
      ha0, ha1, ha2, hn0, hn1, hn2,
      hq 0 (by decide), hq 1 (by decide), hq 2 (by decide), hq 3 (by decide),
      hq 4 (by decide), hq 5 (by decide), hq 6 (by decide), hq 7 (by decide)]
  cases h0 : ins (mAddrNet 0) <;> cases h1 : ins (mAddrNet 1) <;>
    cases h2 : ins (mAddrNet 2) <;> simp [mAddrOf, h0, h1, h2]

/-! ## ⭐⭐ THE WRITE PATH, UNIVERSALLY -/

/-- Word `w`'s write enable is `addr = w` ANDed with `we`. -/
theorem mWen_val (ins : Env) (w : Nat) (hw : w < 8) :
    mV ins (mWen w) = (decide (mAddrOf ins = w) && ins mWeNet) := by
  have hwe : mV ins mWeNet = ins mWeNet := mInputVal ins _ (by decide)
  have hmT : (⟨mSelT w, .and (mLit 0 w) (mLit 1 w)⟩ : Gate) ∈ mDecodeG := by
    simp only [mDecodeG, List.mem_append]
    exact Or.inl (Or.inl (Or.inr
      (List.mem_flatMap.mpr ⟨w, List.mem_range.mpr hw, by simp⟩)))
  have hmS : (⟨mSel w, .and (mSelT w) (mLit 2 w)⟩ : Gate) ∈ mDecodeG := by
    simp only [mDecodeG, List.mem_append]
    exact Or.inl (Or.inl (Or.inr
      (List.mem_flatMap.mpr ⟨w, List.mem_range.mpr hw, by simp⟩)))
  have hmW : (⟨mWen w, .and (mSel w) mWeNet⟩ : Gate) ∈ mDecodeG := by
    simp only [mDecodeG, List.mem_append]
    exact Or.inl (Or.inr (List.mem_map.mpr ⟨w, List.mem_range.mpr hw, rfl⟩))
  have eT : mV ins (mSelT w) = (mV ins (mLit 0 w) && mV ins (mLit 1 w)) :=
    mGateVal ins ⟨mSelT w, .and (mLit 0 w) (mLit 1 w)⟩ (mDecode_mem hmT)
  have eS : mV ins (mSel w) = (mV ins (mSelT w) && mV ins (mLit 2 w)) :=
    mGateVal ins ⟨mSel w, .and (mSelT w) (mLit 2 w)⟩ (mDecode_mem hmS)
  have eW : mV ins (mWen w) = (mV ins (mSel w) && mV ins mWeNet) :=
    mGateVal ins ⟨mWen w, .and (mSel w) mWeNet⟩ (mDecode_mem hmW)
  rw [eW, eS, eT, hwe, mLit_val ins 0 w (by decide), mLit_val ins 1 w (by decide),
      mLit_val ins 2 w (by decide)]
  interval_cases w <;>
    cases h0 : ins (mAddrNet 0) <;> cases h1 : ins (mAddrNet 1) <;>
      cases h2 : ins (mAddrNet 2) <;> simp +decide [mAddrOf, h0, h1, h2]

theorem mNWen_val (ins : Env) (w : Nat) (hw : w < 8) :
    mV ins (mNWen w) = !(mV ins (mWen w)) := by
  have hmem : (⟨mNWen w, .not (mWen w)⟩ : Gate) ∈ mDecodeG := by
    simp only [mDecodeG, List.mem_append]
    exact Or.inr (List.mem_map.mpr ⟨w, List.mem_range.mpr hw, rfl⟩)
  exact mGateVal ins ⟨mNWen w, .not (mWen w)⟩ (mDecode_mem hmem)

/-- ⭐⭐⭐ **THE WRITE PATH, UNIVERSALLY.** For every environment, every word and
every bit: the D-root takes the write data exactly when the write is enabled and
the address names that word, and otherwise holds. -/
theorem mem_next_correct (ins : Env) (w k : Nat) (hw : w < 8) (hk : k < 32) :
    mV ins (mNextNet w k)
      = (if (mAddrOf ins = w ∧ ins mWeNet = true) then ins (mWData k)
         else ins (mQ w k)) := by
  have e := mMuxVal ins (mWNet w k) (mQ w k) (mWData k) (mWen w) (mNWen w)
    (fun g hg => mWriteMux_mem hw hk hg)
  have hq : mV ins (mQ w k) = ins (mQ w k) :=
    mInputVal ins _ (by simp only [mQ, mIn]; omega)
  have hd : mV ins (mWData k) = ins (mWData k) :=
    mInputVal ins _ (by simp only [mWData, mIn]; omega)
  simp only [mNextNet]
  rw [e, mNWen_val ins w hw, mWen_val ins w hw, hq, hd]
  by_cases haddr : mAddrOf ins = w
  · cases hwe : ins mWeNet <;> simp [haddr]
  · simp [haddr]

/-! ## The `sem`-level statement — what a reader of `memOrgan` should quote -/

/-- ⭐⭐⭐ **THE ORGAN'S MEANING, IN PORT ORDER.** The first 32 ports of
`sem memOrgan` are the addressed word, bit by bit, for **every** environment.
*Stated as an equality of the whole output list so that PORT ORDER is pinned:
the refuter pass measured port-order blindness as one of three vacuity modes, and
a per-index statement cannot see it.* -/
theorem sem_memOrgan_read_port (ins : Env) :
    sem memOrgan ins
      = (List.range 32).map (fun k => ins (mQ (mAddrOf ins) k))
        ++ mNextOuts.map (mV ins) := by
  -- ⚠️ EVERY step below keeps the head symbol `mV`. Writing the tail as
  -- `run ins memOrgan.gates` instead makes `isDefEq` unfold `run` through all
  -- 1,475 gates: MEASURED as `(deterministic) timeout at whnf` on attempt 2.
  show ((List.range 32).map mReadNet ++ mNextOuts).map (mV ins) = _
  rw [List.map_append]
  -- ⛔ `Function.comp_def` IS LOAD-BEARING. `List.map_map` leaves `mV ins ∘ mReadNet`,
  -- and `(mV ins ∘ mReadNet) k =?= mV ins (mReadNet k)` puts `Function.comp` head-to-head
  -- with `mV`: lazy delta unfolds the taller one — `mV`, then `run` — through all 1,475
  -- gates. MEASURED: `(deterministic) timeout at whnf` on attempts 2 AND 3. Normalising
  -- the composition away first leaves a beta-redex and the check is instant.
  simp only [List.map_map, Function.comp_def]
  exact congrArg (· ++ mNextOuts.map (mV ins))
    (List.map_congr_left (fun k hk => mem_read_correct ins k (List.mem_range.mp hk)))

/-! ## NON-VACUITY — the certificates DISCRIMINATE

*A universal theorem about a circuit I also wrote can hold because both sides are
wrong in the same way. These two say the organ is not constant and that the
address axis is real — kernel-checked over the WHOLE address space through the
packed evaluator (`semB_eq` proves `semB` IS `sem`).* -/

/-- Address `a` on nets `0…2`, no write, and memory word `w` holding the value
`w`. Reading address `a` must therefore return the number `a`. -/
def mProbe (a : Nat) : Nat :=
  (a % 8) ||| ((List.range 8).foldl (fun acc w =>
    acc ||| ((List.range 32).foldl (fun acc' k =>
      if w.testBit k then acc' ||| 2 ^ (mQ w k) else acc') 0)) 0)

/-- ⛔ **THE ADDRESS AXIS IS REAL** — all 8 addresses, all 32 port bits. -/
theorem memOrgan_address_axis_is_real :
    ((List.range 8).all fun a =>
      ((List.range 32).all fun k =>
        (semB memOrgan (mProbe a)).getD k false == a.testBit k)) = true := by
  decide +kernel

/-- ⛔ **SCORED ONE ADDRESS OFF, THE SAME CHECK IS `false`** — so it is not a
predicate that passes for everything. -/
theorem memOrgan_address_check_discriminates :
    ((List.range 8).all fun a =>
      ((List.range 32).all fun k =>
        (semB memOrgan (mProbe a)).getD k false == (a + 1).testBit k)) = false := by
  decide +kernel

/-! ## ⚠️ WHAT THIS FILE DOES NOT PRICE

**Stated positively, because an unstated omission reads as coverage.** The organ
above is the 8×32 array and its ports. A Horn-D core also needs, and this file
does **not** contain and does **not** cost:

* **effective-address formation** — `LW`/`SW` compute `rs1 + imm` in a 32-bit
  adder and take `[4:2]` as the word index. The adder exists (`Adder.lean`); the
  *slice*, the alignment check and the range check do not.
* **out-of-range / misaligned behaviour** — an address outside `0 … 7` words must
  do something definite. Whatever it is, it is enable logic this organ has no
  port for, and it is where `St.trapped` would be driven.
* **the load path back into the register file** — the read port's 32 bits still
  have to reach the ALU-select mux as another 32-bit operand.
* **the 257 extra FLOPS** — 256 `mem` bits plus `trapped`. This organ prices
  GATES, not flops. The flop budget is the codec's, and it is exactly what
  `decQ`'s ⬥M1a note says extending `encD` to 1313 would reopen.
-/

#audit_axioms mWords
#audit_axioms mWidth
#audit_axioms mAddrBits
#audit_axioms mAddrNet
#audit_axioms mWeNet
#audit_axioms mWData
#audit_axioms mQ
#audit_axioms mIn
#audit_axioms mIn_value
#audit_axioms mNotA
#audit_axioms mSelT
#audit_axioms mSel
#audit_axioms mWen
#audit_axioms mNWen
#audit_axioms mLit
#audit_axioms mDecodeG
#audit_axioms mMux
#audit_axioms mReadBase
#audit_axioms mL0
#audit_axioms mL1
#audit_axioms mL2
#audit_axioms mReadNet
#audit_axioms mBitGates
#audit_axioms mReadG
#audit_axioms mWriteBase
#audit_axioms mWNet
#audit_axioms mNextNet
#audit_axioms mWriteG
#audit_axioms mGates
#audit_axioms mNextOuts
#audit_axioms mOuts
#audit_axioms memOrgan
#audit_axioms memOrgan_gate_count
#audit_axioms memOrgan_block_sizes
#audit_axioms memOrgan_ports
#audit_axioms memOrgan_write_is_256_muxes
#audit_axioms memOrgan_read_is_224_muxes
#audit_axioms memOrgan_exceeds_banked_budget
#audit_axioms memOrgan_ssa
#audit_axioms memOrgan_ssaFrom
#audit_axioms memOrgan_wf
#audit_axioms mV
#audit_axioms mGateVal
#audit_axioms mInputVal
#audit_axioms mDecode_mem
#audit_axioms mRead_mem
#audit_axioms mWrite_mem
#audit_axioms mBitGates_mem
#audit_axioms mWriteMux_mem
#audit_axioms mMuxVal
#audit_axioms mAddrOf
#audit_axioms mAddrOf_lt
#audit_axioms mNotA_val
#audit_axioms mLit_val
#audit_axioms mem_read_correct
#audit_axioms mWen_val
#audit_axioms mNWen_val
#audit_axioms mem_next_correct
#audit_axioms sem_memOrgan_read_port
#audit_axioms mProbe
#audit_axioms memOrgan_address_axis_is_real
#audit_axioms memOrgan_address_check_discriminates

end SaltWorks.HDL
