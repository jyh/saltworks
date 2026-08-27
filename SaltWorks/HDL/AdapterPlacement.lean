/-
Copyright (c) 2026 Jason Hickey. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jason Hickey, Claude
-/
import SaltWorks.HDL.AdapterStateOrgan

/-!
# The adapter bits' PLACEMENT — separated from the two things that actually block it

`StallsAtWidened` records the placement as *"waits on the `Netlist → Circ` bridge"*. **Measured,
that is not what blocks it.** `bridge` converts a Silicon NETLIST into a `Circ`
(`NetlistBridge.lean`); it is how RTL-derived material enters this world. Placing an organ that is
already a `Circ` into an assembly that is already a `Circ` does not go through it.

What `CoreAssemblyD` actually names as missing, in its own header, is three things: **memOrgan's
σ** (a 292-input datapath question), **`instOK memOrgan _ _`**, and **the trap bit** (no gate-level
producer exists in any landed module). None of those is the bridge, and none of them is the
adapter.

## What this file does

The adapter organ has **five** inputs, not 292, and three of them are the layout's own top three
nets fed back. So its placement side condition is dischargeable today, and the parts that are not
mine are lifted into parameters — the technique that worked on the `req` question one file over.

```
adapterSigma        the 5-input wiring, PARAMETERISED on where the decode puts req/we
adapter_instOK      the side condition DISCHARGED, given only that the two decode nets and
                    the layout's top three sit below the offset
widenedOuts         the assembly's output list, PARAMETERISED on memOrgan's placement and the
                    trap net — the two things this seat cannot supply
```

## ⛔⛔ THE HYPOTHESES ARE OWED BY SOMEONE, AND HERE IS WHO — READ BEFORE QUOTING THE 1316 RECEIPT

**`widenedOuts` takes `memPlaced` and `trapNet` as ARGUMENTS. Parameterising an obligation does
not discharge it, and this file can go kernel-green while the assembly stays open** — at which
point the 1316 receipt reads like progress on the thing it does not close. So the parameters are
named here as debts with an owner, per the helm's 21:1x ruling.

```
memOrgan's σ        ✅ DISCHARGED — `SaltWorks/HDL/MemOrganPlacement.lean`. It was never a
                    292-input design question: 256 of the 292 are the memory field of the state
                    layout read back, one affine map `i ↦ i + 1020`. THE FREE PART IS 36 WIRES,
                    and they are the datapath's, exactly as `req`/`we` are here.
instOK memOrgan σ o ✅ DISCHARGED down to those 36 — `mem_instOK`, same shape as
                    `adapter_instOK`, since memOrgan is already ssa and wf.
the trap producer   ✅ DISCHARGED 2026-08-26 16:45, `a6dc687` — `SaltWorks/HDL/TrapOrgan.lean`.
                    One OR gate; `trapOrgan_sem` proved over every input, plus stickiness, clear,
                    wf, ssa, and `trap_closes_the_width` kernel-checked.
```
⚠️ **THAT THIRD ROW WAS ALSO CARRIED AS MISSING.** `CoreAssemblyD:21` says *"There is no
gate-level trap next-state producer in any landed module."* It landed at **14:41**; `TrapOrgan`
landed at **16:45 the same day**. ***A "WHAT THIS DOES NOT DO" LIST IS A DATED CLAIM ABOUT THE REST
OF THE TREE, AND IT DECAYS FASTEST PRECISELY BECAUSE IT NAMES LIVE WORK.*** Third instance in one
evening, all ~2h: the RTL's `req` paragraph, this seat's own §5.2, and this row.

⇒ **OWNERSHIP, DERIVED NOT GUESSED: `docs/SEATS.md` gives `SaltWorks/HDL/**` to the COMPILER seat.
MemOrgan, CoreAssemblyD and TrapOrgan are all under it. There is no other lane to route to.**

⭐ **UPDATE — ALL THREE ROWS ARE NOW CLOSED, AND THE REMAINING INPUT IS THE DATAPATH'S 36 WIRES.**
`MemOrganPlacement` also removes the `memPlaced.length = 256` hypothesis from `widenedOuts_length`
outright, by PLACING the organ instead of assuming a list of the right size — so the 1316 receipt
below no longer rests on a promise.

## 📐 AND THESE ARE NOT T2'S THIRD ITEM

They are **c4spec step 7's assembly obligation** — the 257-bit extension, 256 memory + 1 trap.
T2's placement DEPENDS on them only because the two widenings were **deliberately fused into one
act**: `AdapterStateOrgan` fences the 1313 intermediate because *"two independently-correct
widenings land a wrong number"*. That fusion was the right call and this is its price — T2's
placement cannot complete until step 7's assembly does, and the dependency runs one way.

⛔ **SO THIS FILE DOES NOT ASSEMBLE THE CORE AND DOES NOT DISCHARGE `C4SpecD`.** What is proved is
that **given** `memPlaced` and `trapNet`, the arithmetic closes and the adapter's three bits land
on the top three positions — so when they arrive, the adapter half is already done rather than
pending.
-/

namespace SaltWorks.HDL.AdapterPlacement

open SaltWorks.HDL SaltWorks.HDL.AdapterStateOrgan

/-! ## §1 — THE WIRING, WITH THE OTHER LANE'S PART AS A PARAMETER -/

/-- The organ's five inputs: `k1 k0 b` are the layout's own top three nets — the adapter state as
it stands at the start of the cycle — and `req`/`we` come from wherever the instruction decode
lands them. **Those two are the only free choices, and they are not this seat's to make.** -/
def adapterSigma (reqNet weNet : Net) : Net → Net
  | 0 => kindHiNet
  | 1 => kindLoNet
  | 2 => beatNet
  | 3 => reqNet
  | 4 => weNet
  | n => n

/-- ⭐⭐ **THE PLACEMENT SIDE CONDITION, DISCHARGED.** `adapterNext` is already `ssa` and `wf`
(both kernel-checked in `AdapterStateOrgan`), so all `instOK` needs is that every input wire sits
strictly below the offset. For this organ that is five inequalities, three of which are the fixed
layout constants 1313/1314/1315. -/
theorem adapter_instOK (reqNet weNet : Net) (off : Nat)
    (hlayout : beatNet < off) (hreq : reqNet < off) (hwe : weNet < off) :
    instOK adapterNext (adapterSigma reqNet weNet) off := by
  refine ⟨adapterNext_ssa, adapterNext_wf, ?_⟩
  intro i hi
  rw [adapterNext_ports.1] at hi
  have h13 : kindHiNet < off := by
    have : kindHiNet < beatNet := by decide +kernel
    omega
  have h14 : kindLoNet < off := by
    have : kindLoNet < beatNet := by decide +kernel
    omega
  interval_cases i <;> simpa [adapterSigma] using ‹_›

/-! ## §2 — WHERE THE THREE BITS LAND -/

/-- The widened assembly's output list, with **memOrgan's placement and the trap net as
parameters**. Nothing landed produces either; taking them as arguments is what makes the adapter's
half provable without them. -/
def widenedOuts (memPlaced : List Net) (trapNet : Net) (σ : Net → Net) (off : Nat) : List Net :=
  CorePlace.core.outs ++ memPlaced ++ [trapNet] ++ instOuts adapterNext σ off

/-- ⭐ **THE ARITHMETIC CLOSES AT 1316.** 1056 registers/pc + 256 memory + 1 trap + 3 adapter. -/
theorem widenedOuts_length (memPlaced : List Net) (hm : memPlaced.length = 256)
    (trapNet : Net) (σ : Net → Net) (off : Nat) :
    (widenedOuts memPlaced trapNet σ off).length = stWidthA := by
  simp only [widenedOuts, List.length_append, List.length_cons, List.length_nil,
    CorePlace.core_outs_length, hm, instOuts, List.length_map, adapterNext_ports.2]
  decide +kernel

/-- ⭐⭐⭐ **THE THREE ADAPTER BITS ARE EXACTLY THE TOP THREE OUTPUTS.** Dropping the 1313
register/pc/memory/trap positions leaves precisely the organ's placed outputs — so positions
1313, 1314 and 1315 of the assembled state are driven by `adapterNext`, which
`adapterNext_correct` proves computes `BusFSM.next` over all 32 inputs. -/
theorem adapter_bits_are_the_top_outputs (memPlaced : List Net) (hm : memPlaced.length = 256)
    (trapNet : Net) (σ : Net → Net) (off : Nat) :
    (widenedOuts memPlaced trapNet σ off).drop 1313 = instOuts adapterNext σ off := by
  have hlen : (CorePlace.core.outs ++ memPlaced ++ [trapNet]).length = 1313 := by
    simp only [List.length_append, List.length_cons, List.length_nil,
      CorePlace.core_outs_length, hm]
    decide +kernel
  simpa [widenedOuts] using List.drop_left' (l₁ := CorePlace.core.outs ++ memPlaced ++ [trapNet])
    (l₂ := instOuts adapterNext σ off) hlen

/-! ## §3 — CONTROLS -/

/-- ⛔ **THE MEMORY LENGTH IS LOAD-BEARING.** With a wrong-sized memory placement the arithmetic
does not close, so `widenedOuts_length` is not passing on a hypothesis it never uses. -/
theorem control_mem_length_matters (trapNet : Net) (σ : Net → Net) (off : Nat) :
    (widenedOuts (List.replicate 255 0) trapNet σ off).length ≠ stWidthA := by
  simp only [widenedOuts, List.length_append, List.length_cons, List.length_nil,
    List.length_replicate, CorePlace.core_outs_length, instOuts, List.length_map,
    adapterNext_ports.2]
  decide +kernel

/-- ⛔ **THE SIDE CONDITION CAN FAIL.** An offset at or below the layout's top net does not
satisfy `instOK`, so `adapter_instOK`'s hypotheses are doing work. -/
theorem control_instOK_needs_the_offset (reqNet weNet : Net) :
    ¬ instOK adapterNext (adapterSigma reqNet weNet) beatNet := by
  rintro ⟨-, -, h3⟩
  have h := h3 2 (by rw [adapterNext_ports.1]; decide +kernel)
  simp only [adapterSigma] at h
  exact absurd h (Nat.lt_irrefl _)

#audit_axioms adapterSigma adapter_instOK widenedOuts widenedOuts_length
#audit_axioms adapter_bits_are_the_top_outputs
#audit_axioms control_mem_length_matters control_instOK_needs_the_offset

end SaltWorks.HDL.AdapterPlacement
