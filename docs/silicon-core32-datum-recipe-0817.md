# THE core32 DATUM — RECIPE, NOT ARTIFACT. A decision taken under act-and-account.

## ⛔⛔ THIS RECIPE NO LONGER RUNS — MEASURED 2026-08-18, AND THE GOOD NEWS IS *WHY*

***`en` LANDED AT `5f25f53` AFTER THIS RECIPE WAS WRITTEN, AND A NEW INPUT PORT IS A
BREAKING CHANGE TO EVERY CONSUMER — INCLUDING A RECIPE THAT NAMES AN `--inputs`
LIST.*** *Same law as `00ebe93` (`en` floating in four consumers), one level up: there
the consumers were instantiations, here the consumer is a PROCEDURE.*

**RUN AS WRITTEN, TODAY, both steps verbatim:**
```
STEP 1  SYNTH_SPLITNETS=1 ./synth.sh core32     EXIT 0
        -> module core32(clk, rst_n, en, ...)   169 port bits
        -> and it DIFFERS from the committed Flow/core32_nl.v, which has NO `en`
           port and 168 port bits. THE COMMITTED NETLIST NO LONGER REPRODUCES
           FROM ITS OWN RECIPE.
STEP 2  import_netlist.py ... --inputs "$INS"   EXIT 1
        -> "importer: net 'en' has no driver and is not an input"
```
✅ ***THE CHAIN IS SELF-PROTECTING, AND THAT IS THE FINDING WORTH KEEPING: the
importer REFUSES rather than inventing a driver or silently dropping the port. A
stale recipe that HALTS is in a different class from one that quietly emits a wrong
datum*** — *this is [[a-check-never-shown-to-fail]]'s good direction, and it is the
reason this block is a NOTICE and not an incident.* ⚠️ *The refusal is the importer's,
not mine; I did not build this protection and am not taking credit for it. I found it
by running the recipe instead of reading it.*

⛔ **WHAT I AM DELIBERATELY *NOT* DOING: REGENERATING ANYTHING.** *How `en` should
appear in the datum — a 67th input, or tied, or excluded with a stated reason — is a
question about `en`'s SHAPE, and `en`'s shape is **item 10, TWO-SIGNATURE, on the
Captain's desk**. Regenerating would settle by keystroke what is reserved for two
signatures. **The recipe stays broken and LOUDLY SO until that rules.** Restoring the
snapshots after the test above was verified by `git status` returning clean.*

📌 **AND THE COMMITTED `Flow/core32_stat.txt` IS STALE THE SAME WAY** (168 vs 169;
its ports == port bits, which is itself the tell that it was produced in SPLITNETS
mode). *Do not cite it for a flop or area claim. `docs/silicon-tools/seqstat.sh` now
REFUSES on exactly this condition — the currency check that rung zero's control row
asked for and did not contain, because "committed" and "still true" are different
properties and only one of them was in the bar.* *(Collateral finding from the
flop-delta executor, `d628532`; I re-derived the port counts independently before
acting on it.)*

**The helm's 15:15 HOLD converted to my judgment (Sancho's relay, 19:2x). I am not
committing the datum, not splitting it, and not holding it as a pending question. I am
replacing it with the thing that regenerates it.**

## THE DECISION

```
the artifact   Core32.lean, 394,164 B / 19,653 lines = 6.4× my read cap
the recipe     the 6 lines below
```

⭐ **REASONING, AND IT IS NOT THE ONE I GAVE THIS AFTERNOON.** *Then I said: too big to
read, therefore the monolith's lie applies. True, but incomplete — the decisive fact is
different and stronger:*

> ***ITS SUBJECT CHANGES WITHIN DAYS.*** The adapter (`busadapt8`), the stall contract
> and the address-map split all land before the 08-27 freeze, and every one of them
> re-synthesises `core32`. **A datum committed tonight is a 394 KB artifact that is
> WRONG BY 08-20 and still sitting in the tree looking authoritative.**

⇒ **A generated artifact whose generator is committed, deterministic and controlled is
BETTER STORED AS ITS RECIPE.** *`reimport.sh` already embodies that principle for the
ten datums that ARE committed; the difference here is that those are stable and this
one is not.*

## THE RECIPE — regenerates the datum exactly, on demand

```sh
# 1. splitnets synthesis (the plain flow REFUSES: `imem_addr[31:2]` is a range assign)
cd SaltWorks/Silicon/Flow && SYNTH_SPLITNETS=1 ./synth.sh core32

# 2. import, omitting the two CONSTANT bits (imem_addr = {pc_q[31:2], 2'b00}, so after
#    splitnets the low two bits have no driver and the importer refuses to invent one)
INS=$(python3 -c "print('clk,rst_n,'+','.join(f'instr[{i}]' for i in range(32))+','+','.join(f'dmem_rdata[{i}]' for i in range(32)))")
OUTS=$(python3 -c "print(','.join(f'dmem_addr[{i}]' for i in range(32))+','+','.join(f'dmem_wdata[{i}]' for i in range(32))+','+','.join(f'dmem_be[{i}]' for i in range(4))+',dmem_req,dmem_we,'+','.join(f'imem_addr[{i}]' for i in range(2,32)))")
python3 SaltWorks/Silicon/Importer/import_netlist.py \
    SaltWorks/Silicon/Flow/core32_nl.v --top core32 --out Core32.lean \
    --name core32NL --inputs "$INS" --outputs "$OUTS"
```

**WHAT IT PRODUCES, measured 08/17 (recorded so a regeneration can be CHECKED, not
trusted):**
```
4,441 instances (3,417 logic / 1,024 sequential) → 18,439 gates
1,090 inputs (66 design + 1,024 state) · 1,124 outputs (100 design + 1,024 next-state)
conservation  text-scan 1024 = parsed 1024 = cut 1024
readback      32 vectors × 1,124 outputs — agrees with VENDOR LIBERTY
core32NL_out_names   dmem_req → index 68 · dmem_we → index 69
core32NL_outs_omitted = ["imem_addr[0]", "imem_addr[1]"]
```
⚠️ **THOSE FIGURES ARE FOR THE 08/17 RTL AND WILL MOVE THE MOMENT THE ADAPTER LANDS.
That is the point: a recipe re-derives, an artifact rots.**

## WHAT THIS COSTS, STATED HONESTLY

- **Route (A) cannot cite a committed datum.** It must regenerate, which costs one
  synthesis and one import — minutes, and both are already controlled.
- **If the recipe is wrong, nothing catches it until someone runs it.** *Mitigation:
  the figures above are the check — a regeneration that does not reproduce them is a
  regeneration that is wrong, and the conservation and readback lines fail loudly on
  their own.*
- ⛔ **It is NOT a substitute for the datum at proof time.** When the RTL freezes on
  08-27, the datum SHOULD be committed — stable subject, permanent object. **This
  decision is about TONIGHT, not about forever.**
