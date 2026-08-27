# PAIR DOCUMENT — silicon's T5 contract, and silicon's check of compiler's T2

*Written 2026-08-26 by silicon. Half (a) of the pair: my contract in my words, and my reading
of compiler's against the wire I measured. The value is that each contract is checked by the
owner of the other, so neither is graded by its author.*

---

## PART 1 · MY T5 CONTRACT — THE STORE PATH, IN MY WORDS

**T5 is "store-path timing — `dmem_we` rising vs the beat leaving the pins". The framing does
not survive contact with the port list, and my contract is about what is there instead.**

### 1.1 · There is no `we` at the interface

`busadapt8`'s outputs are `pin_out`, `phase_pins`, `retire`. **`c_dmem_we` is an INPUT**,
consumed internally to choose `kind`, and it never reaches a pin. ⇒ *there is no write-enable
edge to skew against the data, and a control aimed at one cannot fire.*

### 1.2 · THE CONTRACT

> **A store occupies TWO consecutive bus loops. Both announce `T_STORE` on the type pins at
> phase 0. The first carries `c_dmem_addr` on `pin_out`; the second carries `c_dmem_wdata`.
> The ONLY output that distinguishes them is `retire`: LOW on the address beat, HIGH on the
> data beat.**
>
> **Therefore: any consumer that places a store datum MUST read `retire`. A consumer that
> reads only the type pins will pair the beats wrongly and write the ADDRESS into memory as
> the datum — silently, with no hang and no type-stream anomaly.**

Kernel-checked, `SaltWorks/HDL/BusFSM.lean`:
```
store_beats_share_a_type_code      typeAtPhase0 ⟨store,false⟩ = typeAtPhase0 ⟨store,true⟩
store_beats_differ_in_payload      outWord    ⟨store,false⟩ ≠ outWord    ⟨store,true⟩
retire_separates_the_store_beats   retire ⟨store,false⟩ = false, retire ⟨store,true⟩ = true
retire_is_the_only_separator       EXHAUSTIVE over all state pairs sharing a type code and
                                   differing in payload — so "nothing else separates them"
                                   is a measurement, not a reading of the port list
```

### 1.3 · WHAT I AM NOT CLAIMING

- **I am not claiming `retire` is ratified.** It is not: `busadapt8.v`'s own port block says its
  shape "must not be read as ratified. Two signatures are owed." My contract says the store path
  DEPENDS on it, which makes the unratified pin load-bearing rather than decorative.
- **I am not claiming the beat pairing is externally recoverable without `retire`.** I proved the
  opposite.
- **I have not settled the `req` timing question** at `busadapt8.v:126-131` — `instr_r` and
  `kind`/`storeBeat` update on the same phase-3 edge, so the arbitration reads a `req` derived
  from the PREVIOUS instruction. Off-by-one or exactly right is open, and it is upstream of this
  contract rather than part of it.

---

## PART 2 · MY CHECK OF COMPILER'S T2 — IS IT TRUE OF THE WIRE?

**Compiler's shape (§7.2 of their block):**
```lean
def CycleRealisesStepOrStalls (cyc : Env → Env) (wordAt : Env → Word)
    (stalls : Env → Bool) : Prop := ∀ ins, if stalls ins then … else …
```
with the note: *"THE STALL SET IS A PARAMETER, NOT A CONSTANT. The predicate says what a stall
MEANS; silicon's T1 contract says which cycles ARE stalls."*

### 2.1 · WHAT IS RIGHT, AND IT IS THE LOAD-BEARING HALF

✅ **The split is correct and it is the right split.** Separating *what a stall means* from
*which cycles are stalls* is what lets the predicate serve every landing site without knowing the
arbitration rule. **I would not change it**, and my T1/T5 contracts are exactly the other half it
names. ✅ The parameterisation also makes the definition well-formed independently of my machine —
`stalls` being a parameter means nothing I measure can make the DEFINITION false.

### 2.2 · ⛔ WHAT IS NOT TRUE OF THE WIRE — THE PARAMETER CANNOT BE SUPPLIED

**`stalls : Env → Bool` cannot be instantiated from the machine as built.** The stall predicate
is `¬retire` (design §1: *"`retire` is ONE WIRE and the stall predicate is its complement"*), and
I measured `retire`'s domain:
```
retire = f(kind, storeBeat, req)        BusFSM.retire, kernel-checked
  kind       2 bits   ADAPTER register, busadapt8.v:77   — NOT in Env
  storeBeat  1 bit    ADAPTER register, busadapt8.v:78   — NOT in Env
  req                 decodable from the instruction     — in Env
```
⇒ ***THREE BITS OF THE STALL PREDICATE'S DOMAIN ARE ADAPTER STATE. There is no `stalls : Env →
Bool` equal to `¬retire`.*** This is criterion (c), and compiler stated it correctly against
their own shape. **The shape is true; it is not yet SATISFIABLE.**

### 2.3 · ⭐⭐ AND THE FIX IS ALREADY RATIFIED — THE TWO ITEMS ARE THE SAME ITEM

**The Captain ratified the state widening on 2026-08-26 ("Yes, renumber").** Once `kind` and
`storeBeat` are IN the state, they are in `Env` — and `retire` becomes a function of `Env`,
because its third input `req` already was.
```
before widening   retire : (adapter state × Env) → Bool     ⇒ criterion (c) UNSATISFIABLE
after  widening   retire : Env → Bool                       ⇒ criterion (c) SATISFIABLE
the widening      stWidth 1056 → 1316, shift 260, ONE act (StateCodecD.renumbering_offsets_full)
```
🔑 ***SO T2'S BLOCKER AND STEP 7'S RENUMBERING ARE NOT TWO PROBLEMS. The renumbering the Captain
just ratified for the ASSEMBLY is the same act that makes compiler's T2 instantiable.*** *I do not
think either of us had said that; each of us was holding one end.*

### 2.4 · WHAT I STILL CANNOT SIGN

**The widening makes the shape satisfiable. It does not make it SATISFIED.** Somebody must still
exhibit the `stalls` function at the widened layout and prove it equals `¬retire` — and the three
adapter bits still need PLACING in `core.outs`, which waits on the `Netlist → Circ` bridge. **I am
not signing `en = retire` today, and my reason is unchanged: the wire's contract is unratified and
the placement does not exist yet.** *What has changed is that the route from here is arithmetic
rather than unknown.*
