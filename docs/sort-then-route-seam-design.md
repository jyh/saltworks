# SORT-THEN-ROUTE — the seam's KERNEL half

**Compiler's half. Silicon's RTL half is the companion; math refutes; evidence fences.**
**Supersedes this file's own 10:51 first draft, which was wrong in two places — §5 says how.**

⚖️ **Does not gate today's submission.** The 1x2 ships banyan content; this lands in the update
window before the ~Sept 7 freeze.

---

## 1. ① IS LANDED — `emitSeq(batcherNetC)`, the Captain's (b)

*Invocation, not a number — re-run it rather than trusting the table:*

```
sh docs/hdl-tools/emit_seq.sh batcher
```

| check | pre-registered 10:55 | measured |
|---|---|---|
| `dfxtp` flops | 96 (`= nState`) | **96** ✅ |
| `assign` | 104 (`= bnCCore.outs.length`) | **104** ✅ |
| `conb` | 0 | **0** ✅ |
| `dfxtp_1` | 0 (R2 — on `no_synth.cells`) | **0** ✅ |
| `initial` | 0 (power-gating law) | **0** ✅ |
| **cells** | **720 = 624 + 96** | **720** ✅ |

⭐ ***The last row is a CROSS-CHECK, not a restatement: 624 is SILICON's independent measurement of
the committed `batcher_c.v` at 10:50, made without reference to this emitter.*** *Two paths that
were not derived from each other agree on the same core. **96 `mux2_1` also appear — the same
peephole that took 816 gates to 624 cells.***

## 2. THE FINDING THAT RESOLVED THE SHAPE FORK

Silicon measured `batcher_c.v` exactly right — 624 cells, **zero flops, no clk**, 105 in / 104 out —
and read it as a combinational parallel-in sorter, which would have made the seam a domain crossing.
**It is not the design. It is the DESIGN'S CORE, with the state file exposed as ports:**

```
105 in  = 9 design inputs + 96 state        bnCCoreIn = bnCIn + 4 * bnCElems
104 out = 8 data         + 96 next-state    bnCCore_outs_split : = 8 + 4 * 24   (LANDED)
                                            bnC_core_outputs   : = 104          (LANDED)
816 gates - 624 cells = 192 = 96 x 2        the mux2 peephole, exactly
```
🔑 ***`batcherNetC` was ALREADY bit-serial and sequential — `nState = 96`, 24 elements x 4 state
bits. It was already shape (b). Nothing was missing but the emission.*** *The tell was that both
port counts DECOMPOSE: 105 = 9 + 96 and 104 = 8 + 96. That is the signature of a core, and it is the
`adjacent-object` shape — a true reading of the object next to the one named.*

✅ **Silicon's heritage point INVERTS IN THEIR FAVOUR:** *they argued "16 bit-times" is a latency, so
the 1990 Batcher was sequential and ours is a different object. **The first half is right and the
second is backwards** — ours is sequential too. Same object class as ISS90 p.78 s3.1.*

## 3. WHERE THE SEAM ACTUALLY IS — relocated, and it is bigger than an order tie

⏭️ **READ §4 BEFORE ACTING ON THIS SECTION.** *The `⛔ MISSING` below is accurate about its own
subject — `bnC_output_frames_driven`, the `cDestOf` theorem, IS still full-load only — but the
GAP it describes was CLOSED later the same day by `bnC_output_frames_partial` (§4). Kept
unedited because it is the reasoning that located the seam; it is not the current state.*

```
✅ LANDED  element -> key    ceC_realises_cKey_when_active        (CompareExchangeC)
           with cKey active dest = (!active, dest) — LITERALLY (¬active, dest) —
           cKeyLE_eq_lex · cKey_active_beats_idle · cKey_idle_never_beats_active
           controls: ceC_does_not_realise_cKey_naively · ceC_rejects_idle_sorts_low
                     ceCIdleLow_is_one_gate_from_ceC · ceC_idle_dest_is_unobservable
✅ LANDED  abstract sort -> routing   cSorted_concentrates · cSorted_strictMonoOn  (math's)
✅ LANDED  NETWORK -> a sort          bnC_output_frames_driven: the output frame vector
           IS runNetF (cDestOf · ≤ cDestOf ·) bnComps — for ARBITRARY st and trace…
⛔ MISSING …⚠️ BUT ONLY UNDER `StageOK`, WHOSE FIRST CLAUSE IS `cFrame true d p`
           ON EVERY WIRE. THE LANDED NETWORK THEOREM IS **FULL LOAD ONLY**.
```
🔑 ***THE SEAM IS THE PARTIAL-LOAD GAP, AND THAT IS WHY MATH'S MODULE IS CALLED `PartialLoad`.***
*At full load `(¬active, dest)` collapses to `dest` — `cKey_degenerates_at_full_load` — which is
exactly why `cDestOf` is a sound comparator inside `StageOK` and only inside it. The NDF's real
traffic is partial: idle lines are normal, and concentration is the entire point of sorting first.*

⛔ **AND THE LANDED COMPARATOR CANNOT SIMPLY BE EXTENDED — `SaltWorks/HDL/BatcherRun.lean`, 4
theorems, `[1 axioms]` each:** *`cDestOf` samples only the address bits, so an idle line reads as
**destination 0**, the most-preferred slot (`cDestOf_idle_is_zero`), and is indistinguishable from an
active line bound for 0 (`cDestOf_blind_to_activity`).* ⇒ ***`cDestOf ≤` at partial load IS
idle-sorts-low — the order `ceC_rejects_idle_sorts_low` refutes at the element and
`cKey_partial_load_differs_from_dest` refutes at the key. Extending the network theorem by keeping
its comparator would adopt the losing order.*** *`cDestOf_sound_at_full_load` is the control: the
landed theorem is **narrow, not wrong**, and that pair of facts is the whole seam.*

✅ **THE HARDWARE IS FINE — this is a PROOF gap, the good direction.** *Driven with five active
frames (dest 5,2,7,0,3) and three idle, `rst` high on cycle 0 only, `batcherNetC` emits the actives
on wires 0..4 in order 0,2,3,5,7 — each carrying its own line's payload — and the idles on 5,6,7.*
⚠️ ***That is a `#eval`, not a theorem: `decide +kernel` on `runTrace batcherNetC` was OS-killed at
24 GB (EXIT=137). 816 gates x 14 cycles is not a kernel computation — which is exactly why the
corpus proves network results structurally. A brute-force fixture is not available at this scale.***

## 4. PRE-REGISTERED COUNTS — for the seam as relocated

### ✅ LANDED — the ELEMENT half is complete (`SaltWorks/HDL/PartialLift.lean`)

```
ceC_hdrOKP                the header decides+routes off full load, 256 configs
ceC_header_routes_partial the extracted form
ceC_pair_partial          the whole frame, ARBITRARY payloads
ceC_pair_partial_out0/1   de-interleaved
ceCPort_partial_out0/1    from ANY initial state — the shape ElemSortsAt consumes
idle_idle_never_decides · idle_headers_are_identical    (the exclusion controls)
```
🔑 *Each mirror is the full-load proof with `true → a0/a1` and the final
`cKeyLE_full_load` rewrite OMITTED — **that rewrite is the only place `cDestOf`
ever entered the chain.** All five went through first try.*

### ✅ COMPLETE — (A) (B) (C) (D) ALL LANDED

```
ceCPort_identical             idle-vs-idle passes through, ANY comparator   (A)
PartialStageOK                the invariant off full load                   (B)
elemSortsAt_of_partial_stage  ElemSortsAt st tr k frameLE                   (D)
cKeyOfFrame / frameLE         the two-field comparator read off the frame
```
⭐ ***THE CHAIN IS UNBROKEN FROM ELEMENT TO NETWORK OUTPUT:***
```
PartialStageOK at stage k  →  ElemSortsAt st tr k frameLE
…at every stage            →  bnC_output_frames_are_the_fold   (landed, generic)
                           →  runNetF frameLE bnComps (input frames)
```
✅ **(C) LANDED TOO — `partialStageOK_succ` was TEN LINES, because
`frames_succ_perm` already takes the comparator as a parameter.** ⇒ **THE PAYOFF:
`bnC_output_frames_partial`.**

⚠️ ***WHAT THE PAYOFF DOES NOT SAY: it is NOT "the Batcher sorts".*** *Its nouns
are `runTrace batcherNetC` and `runNetF frameLE bnComps` — the NETLIST computes
what the abstract comparator fold computes. Whether that fold SORTS is a separate
fact about `bnComps`, and tying it to math's `cSorted` (`runNet batcher8 (cKey act
dst)`) is a further, **abstract-to-abstract** seam with no hardware in it.*
**The refinement was what was owed, and it is closed.**

### ✅ AND THE KEY LEVEL TOO — the handoff shape

```
bnC_output_keys_partial :
  natKey (netlist output on wire w) = runNetN bnComps (natKey of input frames) w
natKey f = (if active f then 0 else 8) + cDestOf f
```
🔑 *`bnC_output_keys_are_runNetN` wanted a **Nat** key and `frameLE` is a
**product** key — that mismatch is the whole reason this step exists. Sound
because `cDestOf_lt_eight` holds for ANY stream with no hypotheses, so the
8-weighted activity bit dominates the destination exactly as the product order
does.*

📌 ***THE REMAINING LINK TO MATH'S `cSorted` IS NOW `runNetN bnComps` vs
`runNet batcher8` — abstract-to-abstract, a `Nat` key on both sides, no hardware,
no frames, no `cKeyLE`.***

⭐ *Three times in this lift the network layer turned out already generic where
work had been priced — the fold, the port lemmas' `cKeyLE` form, and preservation.
`cDestOf` entered the whole chain at exactly one rewrite (`cKeyLE_full_load`);
omitting it generalised five theorems.*

### The original decomposition, kept for the record

```
(A) ceCPort_identical    idle-vs-idle: identical inputs ⇒ identical outputs, so
                         ElemSortsAt holds there for ANY comparator. NEEDED because
                         the keystone excludes idle-idle (it never decides), and
                         PartialStageOK must let two idle wires meet.
                         Route: the output gates compute (!s && i0) || (s && i1);
                         with i0 = i1 this is i0 for either s. State-length 4 comes
                         from bnCSlice_length (landed).
(B) PartialStageOK       clause 1 → "active OR idle, idles carrying the SILENT
                         (all-false) payload" — so two idles are the SAME BITS
                         (cFrame_idle_is_silent), which is what makes (A) apply.
                         clause 2 → distinctness on ACTIVE destinations only.
                         ⚠️ Distinctness on ACTIVES stays load-bearing:
                         ceC_pair_tie_splices_the_payload shows a genuine active
                         tie misroutes INVISIBLY to any header-level invariant.
(C) preservation         a compare-exchange permutes the two frames, so both
                         clauses survive a stage.
(D) elemSortsAt_of_stage_partial   →  THE EXISTING GENERIC FOLD, unchanged.
```
⭐ ***No new theory is owed. `bnC_output_frames_are_the_fold` already takes `le`
as a parameter, so nothing above touches the network layer.***
🔑 ***THE DISTINCTNESS CLAUSE IS THE LOAD-BEARING EDIT AND IT IS NOT COSMETIC: `StageOK` requires
pairwise-distinct `cDestOf`, and `cDestOf_idle_is_zero` says every idle line reads 0 — so with two
idle lines the hypothesis is FALSE, vacuously excluding exactly the traffic the NDF runs.*** *The
element already misroutes on a genuine tie (`ceC_pair_tie_splices_the_payload` is the corpus's own
control), so the replacement clause must be a real order, not a dropped requirement.*

⚠️ **I am NOT pricing the network theorem tonight.** *It is the one real proof in this design and my
banked law is that an estimate assembled from absences is worthless. `bnC_trace_factors` and
`bnC_output_frames_are_the_fold` are the levers and both are landed; the unknown is whether the
element's partial-load behaviour supports the same per-stage invariant.*

## 5. ⛔ WHAT THIS FILE'S FIRST DRAFT GOT WRONG, 65 MINUTES OLD

```
(1) It proposed a NEW theorem tying keyLE to the product order.
    THAT TIE ALREADY EXISTS — as ceC_realises_cKey_when_active, under the
    corpus's own cKey/cKeyLE names, in CompareExchangeC.lean.
(2) It aimed at `ce` (2 state bits, CompareExchange.lean). The element the
    NETWORK instances 24x is `ceC` (4 state bits, CompareExchangeC.lean).
    keyLE appears in exactly ONE file and it is not the network's.
```
🔑 ***I grepped MY reading of the seam (`keyLE`) in the file I had open, and filed the corpus's
silence as an absence. That is `absences-compound` firing on the same surface it was banked from:
three greps before any "the corpus lacks X" — other seats' slots, the corpus's convention not
yours, prose naming a superseded object. I ran none of them; the probe caught it, not the review.***
*The draft would have spent a session rebuilding a landed theorem against the wrong element.*

## 6. WHAT THIS DOES NOT CLAIM

- **Not** that the sorter is timing-closed or tile-fits. 720 cells is a CELL COUNT; area and timing
  are silicon's measurement at composition, and the alignment constant is theirs.
- **Not** that `batcherNetC` sorts. §3 is explicit that this is the missing theorem; the emission
  in §1 is a faithful clocking of the object, not a statement about what it computes.
- **Not** that `emitSeq` is trusted — it returns a `String`. What §1 buys is that the artifact
  coming back matches the kernel object's dimensions on six counts, one cross-checked.
