# THE C3 DATAPATH SURVEY — four blocks measured, and a rule that says where option (A) is required

### 2026-08-07, SILICON, on the Captain's orders (read path → writeback → ALU →
### control). Every block synthesised through the pinned flow and censused;
### predictions written to disk before each synthesis. Kernel ceiling = 24 bits.

## The survey

| block | worst cone, **untreated** | ≤ 24 | needs option (A)? | worst cone, **treated** |
|---|---|---|---|---|
| **writeback** (result mux + write decode) | **6** | **100 %** | **NO** | 6 |
| **control** (decode + immgen + branch) | **13** | **100 %** | **NO** | 13 |
| **register read** (2 × 32:1) | 36 | 93.9 % | **YES** | **11** |
| **ALU** (10 ops + flags) | 68 | **0 %** | **YES** | **20** *(14 encoded)* |
| **PC adders** (`pc+imm`, `pc+4`) | 64 / 30 | — | **YES** | **3** |

## 🎯 THE RULE THE FOUR BLOCKS AGREE ON

> **A block needs structural emission if it SELECTS across a wide operand set, or
> ADDS across a wide word. A block that DECODES or ENABLES does not.**

| what the block does | examples measured | cone behaviour |
|---|---|---|
| **selects** | register read (36), ALU op mux (68), barrel shifts (37) | grows with the **operand count** |
| **adds** | ALU adder (65), `pc+imm` (64), `pc+4` (30) | grows with the **word width**, via the carry chain |
| **decodes** | control signals (≤ 8), immediates (≤ 10), branch (13) | bounded by the **instruction field**, ~17 bits, and does not grow |
| **enables** | regfile write port (6) | **constant** — data is broadcast, only the enable is decoded |

⇒ **Two of the four blocks need nothing at all.** That is a real narrowing of
option (A)'s obligations, and it was not obvious in advance — I predicted the
writeback and control results and would not have bet heavily on either.

## ⚠️ EVEN A `+4` INCREMENT NEEDS THE TREATMENT

`pc_plus_4` measured **max 30**: `pc_plus_4[31]` depends on `pc[2..31]` because
the carry ripples the whole way. **An incrementer is a degenerate adder and
inherits the carry chain in full.** *Anything that carries needs per-slice cuts —
not just the ALU's adder, and it would be easy to exempt an increment by
assumption.* The treated figure of **3** is measured on `adder8s` from the C3
probe, and the PC adders are the same structure.

## The control path in detail (measured 07:1x)

```
alu_op  4 roots  max  8   OK      imm      31 roots  max 10   OK
alu_src 1 root   max  7   OK      reg_we    1 root   max  7   OK
br_taken 1 root  max 13   OK      mem_we/re 1 each   max  7   OK
wb_sel  1 root   max  6   OK      pc_next  31 roots  max 67   OVER -> the adders
```

Cutting at the two named PC terms isolates them exactly: **`pc_next` becomes 15
(the select mux), and the two adders stand alone at 64 and 30.** ⇒ **The control
*logic* is not the problem and never was; the adders it contains are.**

## What this means for C3

1. **Option (A) is required for three things**: the register read path, the ALU,
   and every adder/incrementer. **Not** for decode, immediates, branch logic, or
   the register write port.
2. **The emitter's structural obligations are bounded and enumerable** — that is
   the useful form of this result. The five obligations now measured:
   * name the **carry chain**, per slice (adders, incrementers)
   * name the **mux-tree levels** (register read, barrel shifts)
   * name each **op result** before an output select (ALU)
   * name the **result vector** itself (`y`, feeding flags)
   * emit wide **reductions as trees** with named levels (`zero`, and every flag)
3. **`keep` does not substitute for any of them.** Three blocks, three failures:
   R2's carry chain wholly re-derived, the read path one bit routed around, the
   ALU eight. **The failure rate rises with the design's freedom to re-associate**,
   which is exactly why the *select* and *add* blocks are the ones that fail.
