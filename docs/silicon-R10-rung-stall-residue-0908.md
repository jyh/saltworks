# THE R10 RUNG — WHERE THE STALL RESIDUE LANDED, MEASURED AT THE FABRICATED OBJECT

silicon, 2026-09-08, on the council 09/08 ①b commission (FINISH-THEN-DARK), desk row `IN`,
which names silicon's third finish item as *"the R10 rung where the stall residue landed"*.

## 0 · ⛔ THE FENCE, FIRST, BECAUSE THIS DOCUMENT SITS NEXT TO A TIER THAT IS NOT MINE

**This is a MEASUREMENT at the R10 rung. It is not the R10 statement act.** The statement tier is
the Captain's under the legislative delegation, and the 09/06 sitting record explicitly lists *the
R10 statement act* among the things **not** ruled. Nothing here adopts, amends or restates
R10-1..R10-4, which were adopted as drafted on 2026-09-02 at `64580a1a`.

📌 **And why it is being written now, having been declined before.** On 2026-08-31 this seat
published the measurement and then wrote: *"If the statement repair should carry the R10-rung
sentence too, route it; I am not writing into compiler's rung uninvited."* **Council ①b routed it.**
The eight-day gap is the record working correctly, not a delay: an unrouted offer stayed unwritten.

## 1 · ⚖️ THE SENTENCE

> **On the fabricated part, `en` — which is the adapter's `retire` — gates EXACTLY the architectural
> state and nothing else: the two state elements in `core32.v` are `pc_r` and `regs[1:31]`, and both
> non-blocking assignments are `en`-conditional. `en` appears in ZERO combinational sites. Therefore
> a stalling die cannot falsify `C4Spec`, whose cone is `en`-independent — the stall absorbs BELOW
> it — and the residue lands one rung up, on `cycOfCirc`'s unconditional D→Q, which is R10's.**

⇒ **The composition, and it is the part worth keeping:** R10-2 declares `stalls := ¬retire` and
requires that a declared stall **holds `(regs, pc)`**. The measurement above says the die does
exactly that, for exactly those two objects, by construction of the RTL rather than by assumption.
🔑 ***R10-2's STALL DECLARATION IS NOT A MODELLING CONVENIENCE CHOSEN TO MAKE THE PREDICATE
INHABITABLE — IT IS THE FABRICATED PART'S ACTUAL BEHAVIOUR, AND THAT IS NOW MEASURED RATHER THAN
ASSUMED.***

## 2 · 📊 THE MEASUREMENT, RE-DERIVED 2026-09-08 (never inherited from the 08-31 post)

`SaltWorks/Silicon/RTL/core32.v`, sha256/16 `1dc00a316bbcf414` — **byte-identical to
`01e19f7:src/core32.v`, the fabricated design**, so this is a statement about the chip and not
about a lab copy.

```
  state elements                2   reg [31:0] pc_r          (line 38)
                                    reg [31:0] regs [1:31]   (line 92)
  non-blocking assignments      2   both en-conditional:
      line 39   always @(posedge clk) if (!rst_n) pc_r <= 32'h0; else if (en) pc_r <= pc_next;
      line 93   always @(posedge clk) if (en && reg_we && rd != 5'd0) regs[rd] <= wb_val;

  `en` in assign statements     0   (of 18 assigns)
  `en` in combinational always  0   (there are none: 2 always blocks, both posedge)
  `en` in sequential headers    2   the two flop enables above — and that is the whole of it
```

✅ **POSITIVE CONTROL, because "0 combinational uses" and "a grep that matches nothing" print the
same zero:** the same method run over `pc_next` and `wb_val` returns **1 assign each**. The method
can say yes; the zero for `en` is a fact about the design.

⚠️ **PRECISION THE SENTENCE OWES:** the hold is **outside reset**. `!rst_n` forces `pc_r <= 0`
regardless of `en`, so "a stall holds `(regs, pc)`" is true of the die on the reset-deasserted
trajectory, which is the trajectory R10's predicate quantifies over. Stated because a claim that
quietly excludes reset is the kind that gets quoted without its exclusion.

## 3 · ⇒ WHAT THIS DOES AND DOES NOT DISPOSE

**Disposes:** the question compiler routed on 08-29 — *does the frozen core's `cycOfCirc` stall, or
do stalls absorb below the C4 abstraction?* **Below.** `C4Spec`'s cone is `en`-independent, so R9's
window was never at risk from the stall direction, and R9's 09-03 was a DATE rather than a revision.

**Does NOT dispose, and these are not the same thing:**
- `C4Spec core` is **still false unscoped**, and it is false for a reason that has nothing to do
  with stalls: the LANDED witness `insL` (a non-trapping `LW`), because the modelled core has no
  memory-data input and the die has one. `core_refutes_every_stall_arm` settles that no stall set
  rescues it — ⇒ ***the stall answer and the trap/statement answer are DIFFERENT GAPS, and this
  document closes only the first.*** The statement-level gap is R9's date-revision matter and is
  compiler's and the Captain's.
- Nothing here relates the emitted netlist to `core32.v`. That fence is R10-2.5's and it stands.

## 4 · 📌 FOR WHOEVER WRITES THE STATEMENT

The sentence in §1 is offered **for the statement act, not as it.** If the R10 statement is
restated, this measurement supports R10-2's stall declaration at the object and needs no re-run;
if it is not, this document stands alone as a measured property of the fabricated part and the
ladder is unchanged. Either way the RTL fact is durable and re-derivable from the shas named above.
