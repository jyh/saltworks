# R10 SITTING TABLE — silicon's three items, for the Captain's sitting of 2026-09-02

*silicon, 2026-09-02 07:4x. Desk row DW (SHIP EARLY, the Captain, council 09/02 07:2x). Three items,
in the order DW names them: (A) the `ndf-2a` bundle READY-TO-CLICK · (B) the DRAFT R10 STATEMENT TEXT ·
(C) BP's one paragraph. Everything measured here is re-derivable from the artifacts named; nothing is
quoted from memory.*

---

## (A) THE `ndf-2a` BUNDLE — STATE, AND THE CRITERION FOR "READY"

**Repo `jyh/tt-neural-dataflow-fabric`, branch `ndf-2a`, off `main` `7d2b2756` (the 08-19 submission,
run `32284710003`, project 5500).** Two commits, both at origin:

```
119d9705  ndf-2a: the accepted configuration (1d + 2a), exactly four keys over the 08-19 submission
          src/config.json only: PL_RESIZER_HOLD_SLACK_MARGIN 0.1→0.45 · GRT_RESIZER_HOLD_SLACK_MARGIN
          0.05→0.3 · RSZ_CORNERS = {nom_tt, max_ss, nom_ss, min_ss} · CTS_SINK_CLUSTERING_SIZE = 10
4226396f  docs: the signoff note for THIS configuration — folded into docs/info.md under "Signoff",
          the fanout note of docs/signoff-fanout-note-FOR-BUNDLE.md re-cut to describe ndf-2a
```
**The RTL is unchanged** — the branch diff touches `src/config.json` and `docs/info.md` and nothing else
(`git diff --stat main..ndf-2a`); `info.yaml`, pinout, 55 ns clock, 6x2 tile untouched.

**Runs on the shuttle's own runner** (`gds` ≈ 26 min + `precheck` ≈ 8 min, measured on the 08-19 run):
```
33640518663  119d9705  config only        started 07:12 PDT   ← verifies the numbers against 08/27
33640897082  4226396f  config + note      started 07:15 PDT   ← the READY candidate
```

**READY-TO-CLICK means ALL of these, and I post READY only when all four hold:**
1. Run `33640897082` green on every job (`gds` · `precheck` · `gl_test` · `viewer` · `docs` · `test`).
2. `treatcheck.py` over the run's `resolved.json` against the 08-19 signoff's: **exactly** the four keys
   differ (refuses on EXTRA = contamination, on MISSING = treatment not applied).
3. The run's signoff metrics equal the 2026-08-27 local measurement of `config-ndf-2a` (the local
   `ndf-base` arm reproduced the 08-19 signoff bit-exactly, so identity is the expectation, not a hope):
   `max_fanout 1` (clock-leaf 0, datapath 1: `wire695/X` @11 in all nine corners) · `max_slew 825` ·
   `max_cap 5` · setup ws `+7.859 ns` · hold ws `+0.198 ns` · TNS 0/0 · DRC/LVS/antenna 0/0/0.
   If they differ, the note is re-cut to the run's numbers and re-pushed (one more run), and the
   difference is reported as a finding about determinism, not hidden.
4. `ndf-2a` fast-forwarded onto `main` — the click takes `main`'s latest green `gds` run.

**The click is the Captain's**: TinyTapeout project 5500 → re-submit from `main`. **Hard wall unchanged:
2026-09-07 13:00 PDT**; every day before it is margin for a fix, per the 09/02 ruling.

**The scope question — ANSWERED, by construction.** The fanout note was held (Q4) because it describes
configuration ①d+②a and the fabricated bundle documents `ndf-base`, where `wire695` is not a net of the
chip. In this bundle the note and the configuration are the same object: `docs/info.md` §Signoff
describes `src/config.json` of the same commit, measured by the same run. Nothing is named OPEN on this
item. *(If the click never happens, the note never ships — the row's own death clause — and the fabricated
bundle stays as it is, without it.)*

**Rung zero's date (compiler's item 3): the click.** Rung 0 of the claim ladder is MEASURED ONLY — area,
DRC/LVS, timing — and its datum for the tape-out is this bundle's signoff. Its date is the day the
Captain clicks; if today, 2026-09-02.

---

## (B) DRAFT R10 STATEMENT TEXT — the flagship restatement, for adoption or correction at the desk

### B.0 What the flagship says today, and why it is false — so the restatement is read against the object

```
C4Spec core        := ∀ ins : Env, sem core ins = encD (stepT (decQ ins) (seenWord ins))        HDL/C4.lean:76
RegDatapathOK      := ∀ ins r k, k < 32 → (the core's write to bit k of reg r) = (ISA's)         HDL/C4Reduction.lean:39
identity_it_is_the_flagship : RegDatapathOK → PcField core → C4Spec core                          HDL/C4Refuted.lean:163
```
**Refuted at the LANDED witness `insL` = `LW x1, x2, 4` with `x2 = 4`, `x1` holding bit 2** (non-trapping):
the core writes `x1` bit 3 (the address 8 = 0b1000, `sel3_insL`); the ISA loads the constant 0
(`isa3_insL`); the prior value's bit 3 is also clear. `regDatapathOK_is_false_at_the_LANDED_witness`
⇒ `not_c4Spec_core_at_the_landed_witness : ¬ C4Spec core` (`HDL/LwTrapRefuted.lean`, `[3 axioms]`).
**Mechanism, in one sentence: the modelled core has no memory-data input, so on a load it cannot produce
the loaded value; the die has one.** The RTL was right throughout; the Lean model moved to match the die
(council 08/29 (f) ③). And it is NOT stall-shaped: `core_refutes_every_stall_arm` — for every stall
set, next-word policy and pad, the core's induced cycle map fails `CycleRealisesStepOrStalls`
(`HDL/LwNotStallShaped.lean`, public at `32f6ecf`). **No R10 wording disposes LW by calling a cycle a
stall.**

### B.1 THE SENTENCE — three clauses, per §14's live table

**R10-1 · THE BOUND IS STATED IN THE UNITS THE MACHINE HONORS.**
> The flagship's bound is a bound on **ISA steps realised**, `stepsIn stalls cyc ins n` — the number of
> non-stalled clocks among the first `n` — and never on clocks. Any clock guard that appears is DERIVED
> from the stall declaration and carries its derivation as a theorem beside it; **no numeral survives whose
> meaning depends on the retired cycle = step identity.** *(T8 — the K/N unit re-cut, UK1 — is the
> Captain's word at the window's open and is routed, not designed here: the sentence is parameterised so
> that whatever unit K/N re-cuts, the bound it states is `stepsIn`.)*

**R10-2 · THE PREDICATE IS THE STALL-ARMED ONE, AND THE STALL DECLARATION IS NAMED.**
> The flagship's cycle predicate is `CycleRealisesStepOrStalls (cycOfCirc core nextW pad) seenWord stalls`
> (`HDL/StallShape.lean`): every clock either realises `stepT` on `(regs, pc)` or is a DECLARED stall that
> holds `(regs, pc)`. The stall declaration is **`stalls := ¬ retire`**, Contract B of
> `docs/retire-two-contracts-0826.md` — ratified if BP is signed at this sitting, carried as a STATED
> assumption if BP is declared MOOT. `stallArm_reduces` recovers today's predicate at the empty stall set
> by `Iff.rfl`; `stallArm_strictly_extends` proves the arm is a real weakening and not a rename.
> **Where `stalls` comes from (compiler's one-bit question, 07:10):** `retire = f(kind, storeBeat, req)`;
> `kind` and `storeBeat` are the adapter bits the ratified `Full` layout carries (`stWidthAdapter`), `req`
> is in `Env`. ⇒ `stalls` is a function of the ratified state and **NO retire/`en` net enters the layout —
> draft position: OUT.** *(silicon's reading; compiler measured 07:10 that the ratified widening carries
> no such net. If the sitting wants the bit IN, R10-2 does not change; only the layout does.)*

**R10-3 · THE LW ROW'S HONEST DISPOSITION — BY SCOPE, ON THE PREDICATE, NOT BY SILENCE AND NOT BY A STALL.**
> The kernel-backed claim is made over exactly the clocks whose presented word cannot touch memory, and
> the exclusion is written INTO the predicate, as a new definition ratified here:
> ```
> def CycleRealisesStepOrStallsOn (scope : Env → Bool) (cyc) (wordAt) (stalls) : Prop :=
>   ∀ ins, if scope ins then (if stalls ins then ⟨holds (regs, pc)⟩ else ⟨realises stepT on (regs, pc)⟩)
>                        else True
> ```
> with `scope ins := memFreeB (wordAt ins)`, the decidable Bool of `MemFree` (`decode w = some i →
> touchesMem i = false`, `Stack/Program.lean:1495`). **Bool-valued, `if … then … else True`, so that at
> `scope := fun _ => true` the definition is defeq to `CycleRealisesStepOrStalls` and `stallArm_reduces`
> still closes by `Iff.rfl` — the property the twenty-declaration cone rests on.** *(compiler 07:12: the
> Prop-valued spelling `scope ins → …` would leave `∀ ins, True → P ins`, a function type, and lose the
> `Iff.rfl`. **CONFIRMED BY THE KERNEL 07:17, saltworks `86f7efd7`, `HDL/ScopeShapeDifferential.lean`:**
> `scopedB_reduces` closes by `Iff.rfl`; the Prop form's `Iff.rfl` is a TYPE MISMATCH pinned as a
> `#guard_msgs` arm, and `scopedP_reduces_propositionally` shows P loses the DEFEQ, not the reduction;
> `control_scope_actually_excludes` shows the scope argument is not decoration. `saltbuild EXIT=0`, 4685
> audit ticks (+3 = that module), 0 sorryAx. ⇒ this clause is adopted UNCONDITIONALLY in the Bool form.)*
> **Why this is honest and not a dodge:** `witness_is_not_memFree` (kernel-checked) puts `insL` OUTSIDE
> the scope, so the scoped sentence is not refuted by the landed witness and its positive half (R9b,
> compiler) becomes inhabitable; and the sentence NAMES what it excludes — **memory-touching words are not
> claimed at the kernel.** They ride at RUNG 1 (simulated), and the die's memory-data path is a measured
> fact of the RTL, stated as one. Scoping the CONSUMER's hypothesis (`hmf` of
> `cycles_realise_steps_of_stalls`) would NOT do this — the consumer's `h` is still universal over `ins`
> and `core_refutes_every_stall_arm` instantiates it at `insL` upstream of any `hmf`. Hence the definition.

**R10-4 · THE CAPTION (row 5, ruled (a), council 09/01 item 7) — INSIDE THE STATEMENT TEXT, ZERO HARDWARE COST.**
> *The fabricated core does not hold `rd` on a trapping load: the die writes `dmem_rdata` to `rd` and
> continues; the model holds `rd`. Measured by simulation with both controls firing. Conforming programs —
> those issuing no trap-class loads — are identical on die and model; divergence is confined to trap-class
> loads, and it is exactly one wire (`regWriteSig` port 10, R9a; `reqSig` untouched). A corrective gate is
> priced at +40 cells / +160.15 µm² / +0.282% and not taken.* **The restated flagship therefore claims
> nothing about trap-class loads; they lie outside `scope` (a trapping LW touches memory) and are stated
> here as measured residue of the submitted part.**

### B.2 WHERE THE RESTATED FLAGSHIP SITS ON THE CLAIM LADDER (§4 / §18 of the offboard block)

```
RUNG 4  PROVEN AT THE GATES, TOTAL           dmem_addr8                                 unchanged
RUNG 3  PROVEN AT THE GATES, RESTRICTED      dmem8 (rst_n ≡ 1)                          unchanged
RUNG 2  TRUE OF THE HARDWARE BY CONSTRUCTION, DriveMap; and THE RESTATED FLAGSHIP       ← R10 puts it HERE:
        ASSUMED IN LEAN                      (scoped, stall-armed) until R9b inhabits     the sentence exists and
                                             it — the kernel holds its NEGATIVE half     is stated honestly; its
                                             (no stall arm rescues the core) and the     positive half is compiler's
                                             scope theorem (insL is outside)             R9b, dated WITH R10's close
RUNG 1  SIMULATED, NOT PROVED                memory-touching words · trap-class loads   named, not claimed
                                             (row 5's harness) · the offboard protocol
RUNG 0  MEASURED ONLY                        area · DRC/LVS · timing = THIS BUNDLE's     dated by the click
                                             signoff (ndf-2a)
```
**What R10 does NOT claim, said now:** nothing about memory realisation (stage ③'s obligation at the F4
bridge) · no bound in clocks · and — compiler's warning, read whole — **`C4SpecD core` STAYS REFUTED under
every scope**, by a WIDTH argument (`outs_length`) with no witness and no instruction; the non-D flagship is
what R10 restates, and R10-3's scope does nothing for the D form. A reader must not carry "open, not
false" from the one to the other.

### B.3 WHAT THE SITTING IS ASKED TO DO WITH (B)
Adopt R10-1..R10-4 as the statement text at the desk (or correct them there); ratify the `…On` definition
in its Bool form (kernel-confirmed at `86f7efd7`); give the T8 word; settle R10-2's one bit
(retire/`en` net OUT of the layout — draft). R9b then dates with this close.

---

## (C) BP — `retire`'s TWO SIGNATURES: THE ONE PARAGRAPH

**What is on the table.** `docs/retire-two-contracts-0826.md` states the two contracts one pin carries — A
(silicon's): `retire` is the only output separating a store's address beat from its data beat, so any
consumer placing a store datum must read it; B (compiler's): the kernel's stall declaration is
`stalls := ¬retire`, instantiable once the ratified widening puts the adapter's `kind` and `storeBeat` bits
in the state. Its §0 makes one signature cover both, inseparably; the Captain's earlier "Yes, renumber"
ratified the 1316 width and nothing else. Compiler signed §6.1 on 08/26; §6.2 is blank. **What a signature
would and would not do.** It would ratify the two contracts as the *stated meaning* of the pin, so that a
later hand touching `retire` learns before the edit that it has two jobs, and so that R10-2 and R9b's
positive half cite a ratified declaration rather than an unsigned document. It would not certify the
hardware: §5.3.1 records that the netlist↔Lean correspondence (`sem (bridge nl outs) = runP`) and the
three-bit placement both reduce to the bridge induction, routed off both seats — the pair is measured on
RTL and kernel-checked on the model, not composed. **What MOOT would mean.** The `ndf-2a` resubmission
changes four configuration keys and no RTL, so `retire` ships exactly as §1 describes whether or not anyone
signs — MOOT is true of the wire. But it leaves R10-2 citing an unratified stall declaration, which is the
object that clause depends on. **Recommendation: SIGN §6.2 at the sitting, with the §5.3.1 caveat read into
the minute** — the signature ratifies a statement, the caveat names what is still unproved, and the row
closes on the Captain's hand rather than by default. If the Captain prefers not to ratify a contract whose
bridge is unbuilt, MOOT closes the row equally and R10-2 carries the stall declaration as an assumption,
stated as one.

---

## OPEN, NAMED, NOT MINE TO CLOSE HERE
- **T8** (K/N unit re-cut): the Captain's word at the window's open.
- **Row 5's side-item**: the trap-gate fidelity harness (`tb_lwtrap.v`, `core32_gated.v`, stat files) was
  scratchpad-resident on 08/30 and is NOT in this repo (`git log --all -- '*lwtrap*'` empty at this hand);
  the measurement stands on the record (minute 09/01 item 7); the harness is owed as a file, silicon's.
- ~~compiler's differential on the Bool/Prop scope spelling~~ — LANDED `86f7efd7` 07:17; R10-3 adopted unconditionally.
