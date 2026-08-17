# DESIGN BLOCK — DISCHARGING `DriveMap` AGAINST THE BUILT PLANE

**silicon, 2026-08-17. Authored under the helm's 08:55:30 ruling: the Lean-side
discharge stays in ③, runs as its own wave, DESIGN-BLOCK-FIRST, and a refuter pass
gates the wave. This is that block. NOTHING IS BUILT AGAINST IT YET.**

> ⚠️ Written while the hardware half is blocked upward on a tile-budget decision. It
> is not a bid to reorder the sequencing — the helm ruled hardware first, and this
> costs the hardware nothing because the hardware is waiting on money, not on me.

---

## §0 · WHAT WOULD ACTUALLY BE DISCHARGED

`DriveMap` (`Certs/DmemKernelBridge.lean:50-52`) is two equations:

```lean
structure DriveMap (w : BitVec 32) (ins : Nat → Bool) : Prop where
  we  : ins 33 = (ctrlSpec w)[6]!     -- dmem_addr8.we_in ← isSW
  req : ins 32 = (ctrlSpec w)[7]!     -- dmem_addr8.req   ← isLW ∨ isSW
```

**The content is the EQUALITY WITH THE KERNEL'S DECODER, not the wiring.** `memplane8`
(`a76b647`) makes the wiring exist; what remains unproved is that the thing arriving
at `we_in` *is* `isSW` as `ctrlSpec` computes it, for every instruction word.

⇒ **A discharge that proves the wires connect and assumes the strobes are correct has
moved the assumption, not removed it.** That is the failure mode every option below
is scored against.

## §1 · THE FOUR ARCHITECTURES, EACH WITH ITS AVAILABLE LIE

### (1) MONOLITHIC — import the flattened `memplane8` netlist as one datum

*Import all 5,302 cells the way `Dmem8.lean` imports 673, then state `DriveMap`'s two
equations over the resulting `ins`.*

```
SIZE, estimated from the Dmem8 ratio and NOT measured for this cell mix:
  netlist 36,186 lines / 713,059 B / 5,302 instances
  datum   ~18,450 lines / ~407 KB  =  7.9× Dmem8  ≈ 6.6× my whole read cap
```

⛔ **THE LIE IT MAKES AVAILABLE: nobody can read it.** A 400 KB generated datum is
checked by the importer's census and by nothing else. If the port order is wrong, or
an index binds to an adjacent net, the theorem is *true of a different circuit* and
looks identical. `Dmem8` is already at the edge of what a head can inspect at 51 KB;
at 8× that, "I read the datum" stops being an available claim.

⚠️ **AND THE ELABORATION HAZARD IS NOT THE COST, IT IS THE PRESSURE:** a datum that
strains `maxRecDepth` invites *weakening the theorem until it elaborates* — proving
over a sampled subspace, or over one instruction, and calling it the discharge. This
seat has a standing memory that the phrasing is the cost, not the circuit; here the
temptation runs the other way and would be invisible in a green build.

### (2) CHUNKED — the same import, emitted in chunks of ≤500

*Exactly what `Dmem8.lean` already does (4 chunks) and `DmemAddr8` before it.*

⛔ **THE LIE: chunking is a PRESENTATION change and reads like a structural one.** It
makes elaboration tractable and changes nothing about semantic size, reviewability,
or whether the stated theorem is the right theorem. **A green build of a chunked
monolith is evidence about Lean's recursion depth and about nothing else.** Every
objection to (1) survives (2) intact.

### (3) PORTS-ONLY — prove over the module hierarchy, not the gates

*Do not import the flattened plane. State that `memplane8` connects
`core32.dmem_req → dmem_addr8.req` and `core32.dmem_we → dmem_addr8.we_in`, and lift
`DriveMap` from that.*

⛔ **THE LIE, AND IT IS THE DANGEROUS ONE BECAUSE THE RESULT LOOKS COMPLETE: this
proves the WIRING and assumes the STROBES.** It discharges "the plane connects the
ports `DriveMap` names" while leaving "`core32.dmem_req` *is* `ctrlSpec[7]`" exactly
as assumed as it is today. ***That is §0's failure mode in its purest form: the
assumption moves one module upstream and the certificate reads as discharged.***

⚖️ It is not worthless — it is the right way to state the *structural* half — but it
must never be published as the discharge.

### (4) SUB-CONE — import only the cone that computes the strobes ⭐ RECOMMENDED

*Cut the netlist at `dmem_req`/`dmem_we` and import only the logic from `instr` to
those two nets. Prove that cone equals `ctrlSpec[7]` / `ctrlSpec[6]`.*

```
what it carries   THE ACTUAL CONTENT: the RTL's strobe generation = the kernel's
                  decoder spec, for every one of the 2^32 words, by the same
                  Boolean-tautology route DmemAddr8Suppress already uses
size              the cone is opcode + funct3 compares — tens of cells, not 5,302
readable          a head can inspect the whole datum, which is the property (1)
                  and (2) destroy
```

⛔ **THE LIE IT MAKES AVAILABLE, STATED AS PLAINLY AS THE OTHERS: I CHOOSE THE CUT.**
A cone cut too narrowly proves a theorem about a function that is not the port's
driver; cut too widely it drags in the datapath and stops elaborating. **Nothing in a
green build distinguishes a correct cut from a convenient one.**

✅ **AND THAT LIE IS THE ONLY ONE ON THIS PAGE WITH A KNOWN ANTIDOTE, ALREADY BUILT:**
the importer records port NAMES in the datum, and `DmemAddr8Suppress.lean` checks the
recorded name before indexing (`dmemAddr8_we_in_is_index_33`). The same move binds a
cone to `dmem_req`/`dmem_we` by declared name rather than by my say-so, and
`--cut REGEX` already exists in `import_netlist.py` for exactly this.

## §2 · PRE-REGISTERED CRITERIA — published BEFORE the wave, per standing practice

The wave is a discharge only if ALL of these hold. Written now so they cannot be
fitted to whatever comes out.

```
D1  the theorem quantifies over ALL instruction words, not a sample and not a list
D2  both DriveMap fields are discharged — `we` AND `req`, not one with the other
    left assumed
D3  the cone's boundary nets are bound to DECLARED PORT NAMES from the datum's own
    recorded table, never to a numeral I typed
D4  a NEGATIVE CONTROL: the same statement over the PRE-RULING opcode-only core
    must FAIL. If it passes on both, the theorem is not about funct3 at all
D5  `#audit_axioms` on every new theorem, and the datum regenerates byte-for-byte
    through `reimport.sh`
D6  the build row is quoted from `saltbuild` EXIT text, and says `Built`, not
    `Replayed`
```

⚠️ **D4 IS THE ONE THAT WILL BE TEMPTING TO SKIP** — it needs the old RTL kept around
to synthesise against, and it is the only criterion that can catch a theorem which is
true for a reason unrelated to the change.

## §3 · WHAT I AM NOT DECIDING HERE

- **Whether the wave runs.** The helm ruled hardware first; this block is authored,
  not started.
- **(3) versus (4) as a pair.** They may well both be wanted — (3) for the structural
  half, (4) for the semantic half — but that is a reviewer's call, and pairing them
  invites exactly the "one covers the other" reading that §0 warns about.
- **The refuter pass.** Gates the wave, per the ruling. This block is its target, and
  §1's four "available lie" paragraphs are written to give it something to bite.

---

# ROUND 2 — AFTER THE REFUTER PASS. §1's RECOMMENDATION IS WITHDRAWN.

**Verdict was HOLD, five fatals. I confirmed every one at the bytes before accepting.
§1(4) above is left standing because dated records are not rewritten — but it is
WRONG and this section supersedes it.**

## §7 · WHAT I GOT WRONG, AND THE SHAPE OF IT

```
CLAIMED (§1.4)   "the antidote is ALREADY BUILT … --cut REGEX already exists in
                 import_netlist.py for exactly this"
MEASURED         FabricCut.lean carries ZERO name tables (DmemAddr8 has 2), so a
                 cut net is UNNAMED BY DESIGN and D3 is unsatisfiable by --cut
                 `--cut` help: "ALSO cut at every net matching REGEX" — it adds
                 boundaries inside a FULL import and never shrinks one
                 run on my own regex: REFUSED, "matched no DRIVEN net"
CLAIMED (§1.4)   the cone from `instr` to the strobes discharges DriveMap
MEASURED         `DriveMap`'s `ins` indexes the dmemAddr8 DATUM's inputs
                 (`dmemAddr8_env ins = runP ins [] dmemAddr8NL`). My cone ended at
                 core32's outputs — THE WRONG END OF THE SEAM
```
🔑 ***I wrote "already built" about a mechanism I never ran, inside the one document
whose purpose was to name the lie each option makes available. The lie §1(4) made
available is the lie I took, and no amount of naming it protected me from it.***

## §8 · THE SEAM HAS TWO ENDS AND NEEDS BOTH — this is the corrected §0

`DriveMap` is discharged only if BOTH hold:

```
(i)  SEMANTIC   the core's named output `dmem_req` = ctrlSpec[7]!, `dmem_we` =
                ctrlSpec[6]!, for every instruction word
(ii) STRUCTURAL those very outputs are what arrive at dmemAddr8's `ins 32` / `ins 33`
```
⚠️ **(i) WITHOUT (ii) PROVES A CORE NOBODY WIRED. (ii) WITHOUT (i) IS THE PORTS-ONLY
LIE FROM §1(3) — it moves the assumption one module upstream.** *Route (A) below
addresses (i). **(ii) HAS NO INSTRUMENT TODAY** and I am not going to imply otherwise;
naming it as an open sub-problem is the honest state.*

## §9 · ROUTE (A) — MEASURED, NOT RECOMMENDED-THEN-DISCOVERED

The refuter's road: `dmem_req`/`dmem_we` are DECLARED OUTPUT PORTS of `core32` as of
`a76b647`, so synthesize with them in `--outputs` and the importer's own name table
binds them — the true `DmemAddr8Suppress`-class move, and the other end already has
`we_in` at index 33.

**I ran it before writing it down. It does not work out of the box, and here is the
price:**

```
1. import core32_nl.v        REFUSED — "assign uses a RANGE 'imem_addr[31:2]'"
2. SYNTH_SPLITNETS=1         ✅ clears it. Area IDENTICAL — 4,441 cells /
                             56,536.7232 µm² either way, so the treatment does not
                             perturb the mapping (this is the same call (4) option
                             (b) cure dmem_addr8 already carries)
3. import again              REFUSED — "no expansion for cell 'o32ai_1'"
4. CENSUS BY CONTENT         43 of core32's 64 cell types have NO model.
                             EXPAND holds 80 entries today ⇒ a ~54% ENLARGEMENT
                             of the trusted table, each entry also owing a Liberty
                             proof in Sky130.lean
```
⇒ ***THAT is the price of (A), and it was invisible until someone ran it. It is not a
reason to reject (A) — it is the number (A) must be chosen WITH.***

## §10 · CRITERIA, ROUND 2

`D1` `D2` `D5` `D6` stand as written. Replacing `D3`, redesigning `D4`, adding two.

```
D3′  boundary nets bound by DECLARED PORT NAME from the datum's own recorded table.
     NO CUT NETS — cut entries are unnamed by design, so any architecture requiring
     a named cut is excluded a priori rather than attempted and patched.

D4′  THE NEGATIVE CONTROL MUST FAIL AS A FALSE THEOREM, NEVER AS A TOOLING REFUSAL.
     ⛔ My round-1 D4 said "run it against the pre-ruling opcode-only core" — that
     core has NO dmem_req/dmem_we ports, so the import REFUSES and I would have
     scored a compile error as a negative control. That is the precise mistake I
     published a law about at 08:19 and repeated at 10:2x.
     ⇒ THE CONTROL IS A PORT-COMPATIBLE MUTANT: keep the ports, drive them
       opcode-only (`dmem_req = is_load|is_store`). It imports identically and the
       theorem must then be REJECTED BY THE KERNEL. A control that cannot be
       elaborated has not been shown to discriminate.

D7   CELL-MODEL COVERAGE IS CENSUSED BY CONTENT AND THE CENSUS CARRIES CONTROLS.
     The count is 43/64 today. ⚠️ It took FOUR instrument attempts to get that
     number, and every wrong one was caught by a control rather than by reading:
     three runs printed a plausible "45" while reporting dfxtp_1 as unmodelled —
     which cannot be true, since dmem8 imported 256 flops. The gate is three-sided:
     dfxtp_1 modelled · and2_1 modelled · o32ai_1 NOT modelled.

D8   EVERY THEOREM INHERITS `Restricted_rst_n_eq_1` AND SAYS SO. dmem8's datum is
     imported under a pinned reset; anything quoting it is restricted to traces with
     rst_n ≡ 1 and is silent about the deassertion seam. A certificate that restates
     such a theorem must carry the restriction with it.
```
*(The round-1 D7 — cut-identity and cut-completeness — is DROPPED, not renumbered
away: D3′ excludes cuts, so no cut survives to need it.)*

## §11 · WHAT ROUND 2 STILL DOES NOT ANSWER

- **(ii), the structural half, has no instrument.** Route (A) does not touch it.
- **Whether the 43 cell models are worth it** — that is a wave-sizing question for
  whoever prices the wave, not a design question I can settle.
- **Whether (A) should be paired with a structural argument, and of what kind.** The
  refuter called ports-only refused from compiler's lane; I record the pairing as
  OPEN rather than assuming §8(ii) will be someone else's problem.
