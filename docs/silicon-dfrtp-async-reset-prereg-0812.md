# PRE-REGISTRATION — the `dfrtp` async-reset sequential model

### SILICON seat · authored **2026-08-12 18:23:28 PDT** · repo head at authorship `d7d01a1`
### STATUS: **AWAITING HELM RULING.** Math consumes at muster (the statement-shape call is theirs).
### ⛔ THIS FILE IS FROZEN ON RULING. Outcomes go in the `.RESULTS.md` companion, never here —
### an immutable artifact cannot carry a tense, and this seat landed a stale one on 08-12 by trying.

---

## 0 · WHAT THIS IS, AND WHAT IT IS NOT

This registers **the checks and the pass/fail bar BEFORE the model is built**, so the verdict
cannot be fitted to the expectation. It is *not* a design approval and *not* a landing.
Nothing in `import_netlist.py` changes until the helm rules.

The refusal being lifted is deliberate and load-bearing. `Flow-docs/flop-treatment-0806.md`
says of `dfrtp`: *"that is a question to answer, not a line to type."* This is the answer
offered for ruling — **and §2 concludes the tempting line was wrong for a sharper reason than
the refusal itself gave.**

---

## 1 · THE MEASURED FACTS — every one reproduced by the command beside it

### 1.1 Population — the scope, inside the verdict

```
$ cd SaltWorks/Silicon/Flow
$ for f in *.v; do ... grep -c sky130_fd_sc_hd__dfrtp ... done
```
| netlist | `dfrtp_1` | `dfxtp` | `edfxtp` |
|---|---|---|---|
| `dmem8_nl.v`  | **256**  | 0 | 0 |
| `dmem16_nl.v` | **512**  | 0 | 0 |
| `dmem32_nl.v` | **1024** | 0 | 0 |
| *the other 43 `.v`* | **0** | — | — |

⇒ **`dfrtp` appears in exactly 3 of 46 netlists — 1792 cells, all of them the `dmem` family.**
Denominator is `ls *.v | wc -l` = 46. No other netlist in the tree contains one.

### 1.2 Drive structure — the fact that makes a restricted model possible

```
$ grep -o '\.RESET_B([^)]*)' dmem8_nl.v | sed 's/.*RESET_B(//;s/)//' | sort | uniq -c
    256 rst_n
```
Every `RESET_B` pin — **1792 of 1792 across all three** — connects **directly to the primary
input `rst_n`**. No buffer, no inverter, no gate, no clock-tree analogue.

And `rst_n` drives **nothing else**:
```
$ grep -c 'rst_n' dmem8_nl.v          259
$ grep -c '\.RESET_B(rst_n)' dmem8_nl.v   256
                                    other =   3
```
The residual 3 are `module dmem8(... rst_n ...)`, `input rst_n;`, `wire rst_n;` — the
declarations. **`rst_n`'s entire fan-out is the reset pins.** Identical arithmetic on
`dmem16` (515/512/3) and `dmem32` (1027/1024/3).

⚠️ **This is a property of THESE THREE ARTIFACTS, not of the technique.** A core with a
reset-aware controller will have `rst_n` feeding real logic, and there the restriction of §3
bites something. That is exactly why check **C2** below is a *report*, not an assumption.

### 1.3 Current behaviour — the refusal, pasted rather than asserted

```
$ python3 .../import_netlist.py .../dmem8_nl.v --top dmem8 --out ... --name dmem8NL \
    --inputs clk,rst_n,we,addr[0..2],wdata[0..31] --outputs rdata[0..31]
EXIT=1
importer: unmodelled sequential cell(s): dfrtp_1 x256. Skipping a flop loses a STATE BIT,
not a gate — add it to SEQ_MODELS only with a justified next-state model (see the note on
`dfrtp` there).
```

### 1.4 Vendor semantics — read from the PDK, not from memory

`sky130_fd_sc_hd__tt_025C_1v80.lib`, md5 `74170f905883f4d186941f3e107ccf51`:

| cell | `clocked_on` | `next_state` | `clear` / `preset` |
|---|---|---|---|
| `dfxtp_1`  | `CLK` | `D` | — |
| **`dfrtp_1`** | `CLK` | **`D`** | **`clear : "!RESET_B"`** |
| `dfstp_1`  | `CLK` | `D` | `preset : "!SET_B"` |
| `edfxtp_1` | `CLK` | `(D&DE) \| (IQ&!DE)` | — |

Corroborated by two further independent vendor views:
* **behavioural** `sky130_fd_sc_hd.v`: `not not0(RESET, RESET_B)` feeding
  `sky130_fd_sc_hd__udp_dff$PR` — `RESET` is a port **distinct from `CLK`**;
* **the UDP table** in `primitives.v`: `?  ?  1 : ? : 0 ;  // async reset` —
  **the reset row fires with `CLK` as `?` (don't-care). No clock event is required.**

✅ **A POSITIVE CONTROL ON MY READING OF THE LIBERTY FORMAT.** The same method, applied to
`edfxtp_1`, yields `(D&DE)|(IQ&!DE)`. The importer's **already-landed and already-trusted**
model for that cell is `next = DE ? D : Q`. These are the same function (`IQ` = `Q`).
*So the file-reading method is validated on a case whose answer was fixed independently of
this document* — [[a-check-never-shown-to-fail]] answered in the right direction for once.

---

## 2 · ⛔ THE TEMPTING MODEL IS REFUTED **STRUCTURALLY**, AND MORE SHARPLY THAN BEFORE

The line the flop treatment refused to type:
```
next = D & RESET_B          -- i.e.  next = rst_n ? D : 0
```
The 08-06 doc rejected it *behaviourally*: async reset "acts between edges", so the formula is
a synchronous reset resting on an unstated assumption. **That argument is correct. The vendor
file gives a stronger one:**

> **`next_state` and `clear` are SEPARATE FIELDS of the Liberty `ff` group, and `dfrtp_1`'s
> `next_state` is the string `D` — byte-identical to `dfxtp_1`'s.**

⇒ **The asynchronous reset contributes EXACTLY ZERO to the next-state function**, by the
vendor's own decomposition. `next = D & RESET_B` does not *approximate* the cell; it **merges
two fields the standard keeps disjoint**, which is a category error rather than a rounding.

🔑 ***And the consequence runs the other way too, which is the part worth ruling on: the
importer's existing `{"d": "D"}` entry is ALREADY the correct next-state model for `dfrtp`.
What `dfrtp` lacks is not a next-state model — it is a treatment for `clear`, which is not a
next-state phenomenon at all.***

**The concrete divergence M0 admits**, for the record, under a purely edge-sampled semantics:
a reset pulse that begins *and ends* strictly inside cycle *k*. Real silicon clears `Q` at the
pulse, so at edge *k+1* the flop latches `D` **computed from the cleared state**. M0 latches
`D` computed from `state_k`. The states differ at *k+1* — so M0 is unsound even for a
semantics that never looks between edges, which is the failure mode easiest to talk oneself
out of.

---

## 3 · THE MODELS ON THE TABLE

| | model | assumption carried | covers |
|---|---|---|---|
| **M0** | `next = D & RESET_B` | reset synchronous — **false** | ⛔ refuted §2 |
| **M1** | **pin `RESET_B` to its inactive value; `dfrtp` ⇒ `dfxtp`** | **none** | reset-deasserted regime |
| **M2** | M1 **+** the reset regime as a separate trivial datum (`rst_n`=0 ⇒ all `Q`=0) | none | both regimes, not the seam |
| **M3** | `next = rst_n ? D : 0` **+** explicit Lean hypothesis "`rst_n` changes only at edges" | environment obligation, **visible** | all traces meeting the hypothesis |

### ⭐ WHAT THIS SEAT PROPOSES: **M1, with the refusal RETAINED as the default.**

Under `RESET_B ≡ 1`, `clear = !1 = 0` — never asserted — and the cell's `ff` group reduces to
`clocked_on : CLK`, `next_state : D`: **literally `dfxtp_1`'s group, field for field.** The
equivalence is then *not an argument this seat makes*; it is a syntactic identity in the vendor
model, which is the strongest footing available and the reason M1 is preferred over M3.

The shape, deliberately in the spirit of `--cut` (a **checked structural restriction**, never a
silent approximation):

* a new flag — **`--pin-reset NET`** — names the net to hold at its inactive value;
* the inactive value is **declared per-cell in `SEQ_MODELS`** (`RESET_B` → 1), **never supplied
  by the caller**, so the flag cannot be misapplied to an active-high reset;
* `dfrtp` enters `SEQ_MODELS` with `pins {CLK, D, Q, RESET_B}`, `d: "D"`, and a
  `reset: ("RESET_B", 1)` entry — so the existing "connected pin the model does not account
  for" hard error keeps working unchanged;
* **without the flag, `dfrtp` still refuses, with the §1.3 text unchanged;**
* the emitted `.lean` carries a **visible scope marker**: the datum models the design
  **restricted to traces where `rst_n ≡ 1`**, and every theorem over it inherits that scope.

---

## 4 · ⚓ THE PRE-REGISTERED CHECKS AND THE BAR

**Registered before any code is written. Each check states how it goes RED, what this seat
PREDICTS, and — the part that makes it a pre-registration — what will be CONCLUDED in *either*
branch.** No check below has yet been run.

| | check | RED when | predicted | if it comes out otherwise |
|---|---|---|---|---|
| **C1** | every `RESET_B` in the design traces to the **single** net named by `--pin-reset`, and that net is a **primary input or a constant** | any reset pin reaches a different net, or a **driven** one | PASS (§1.2) | **STOP.** A gated/derived reset is not pinnable; refusal stands and this document is withdrawn |
| **C2** | **report** every *other* consumer of the pinned net, with a count | never — C2 cannot fail | count **0** on all three `dmem` | a non-zero count is **NOT a failure**; it is a mandatory disclosure that the restriction bites other logic, and it must appear in the run output and in the emitted marker |
| **C3** | pinned-`dfrtp` datum is **byte-identical** to the datum from the same netlist with `dfrtp_1`→`dfxtp_1` textually rewritten and `RESET_B` dropped | any byte differs | **identical** — §3's field-for-field identity predicts it | a difference is a **finding about the new code path**, not a tolerance to widen. Diff is published and the cause named before anything lands |
| **C4** | **the refusal survives**: no `--pin-reset` ⇒ `EXIT=1`, message naming `dfrtp_1 x256` | exit 0, or text changed | EXIT=1, §1.3 text verbatim | any drift means the default became permissive — **blocking** |
| **C5** | **M0 never creeps back**: no path emits a gate taking `RESET_B` as a data input | such a path exists | zero | blocking; §2 is the whole reason the flag exists |
| **C6** | flop-count conservation: cut = state-inputs = next-state-roots = **256** (512 / 1024), **expected vs measured stated side by side** | any inequality | 256 / 512 / 1024 | blocking — [[unobservable-state-is-deleted]] |

### 🔴 THE NEGATIVE CONTROLS — a check never shown to fail has not been shown to discriminate

Each is a **planted defect**, run through **the real command with the real flags** — not a
re-implementation of the check, which is the trap this seat fell into on 08-12.

```
NC1 → C1   copy dmem8_nl.v; rewire ONE instance's .RESET_B to a net driven by an and2_1
           MUST: EXIT!=0, message naming that instance
NC2 → C2   copy dmem8_nl.v; add one gate consuming rst_n
           MUST: the run REPORTS that consumer by name; count != 0
NC3 → C3   perturb one emitted gate in the pinned arm
           MUST: byte-comparison RED  (the control the 08-06 reimport.sh table already uses)
NC4 → C4   is its own negative arm — but it MUST BE RUN, not assumed
NC6 → C6   drop one flop from the cut list
           MUST: expected 256 vs measured 255 printed side by side, EXIT!=0
```
**BAR: all six checks GREEN *and* all five negative controls RED. Anything less does not land.**
A control that fails to go RED voids its check — the check is then unproven, not merely untested.

---

## 5 · ⚠️ THE DECLARED GAP — stated here so it cannot be discovered later as a surprise

**M1 does not cover the deassertion seam.** It covers `rst_n ≡ 1` throughout. It says nothing
about the cycle in which reset *releases* — the one transition where the async path and the
clock interact. M2 adds the reset regime (`rst_n ≡ 0` ⇒ all `Q` = 0) but **the seam remains
uncovered by both.**

This is a **scope limit, not a defect**, provided it is carried in the theorem. It becomes a
defect the moment a theorem over this datum is read as covering power-on behaviour.
⇒ **A theorem proved on the pinned datum MUST NOT be cited as covering reset or bring-up.**
Closing the seam needs M3's hypothesis or a genuine two-event cycle semantics; neither is
proposed tonight, and **D1a does not need either** — a memory's operating regime is
reset-deasserted by construction.

---

## 6 · WHAT IS NOT THIS SEAT'S TO DECIDE

**⚖️ THE HELM RULES ON:** whether the restricted-datum route (M1) is an acceptable shape at
all, or whether the refusal holds until a full two-event semantics exists. That is doctrine —
this seat has a recommendation and no authority.

**📐 MATH CALLS:** the **statement shape** — how the `rst_n ≡ 1` restriction is carried in the
Lean theorem. A hypothesis on a trace predicate? A datum whose input vector simply *lacks*
`rst_n`? A `Prop`-level side condition on the netlist? The semantics call is theirs, exactly as
the grammar call is theirs on the importer range extension. **This seat will not choose it and
will not pre-empt it by writing the emitter first.**

**🔧 THIS SEAT OWNS:** the measurement, the refutation of M0, the checks, the negative controls,
the bar — and the implementation once ruled.

---

## 7 · REPRODUCTION

```
head at authorship   d7d01a1
dmem8_nl.v           md5 374981e5281d6b1e0d186175ca4ed217
liberty              md5 74170f905883f4d186941f3e107ccf51
                     ~/.volare/sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib
behavioural          .../verilog/sky130_fd_sc_hd.v         module sky130_fd_sc_hd__dfrtp_1
UDP table            .../verilog/primitives.v:345          sky130_fd_sc_hd__udp_dff$PR
```

*Outcomes — check results, control results, verdict — belong in
`silicon-dfrtp-async-reset-prereg-0812.RESULTS.md`. **This file is the frozen prediction.***
