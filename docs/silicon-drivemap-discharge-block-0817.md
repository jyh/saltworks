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
