# STATUS for `silicon-d1b-cell-derivation-sealed-0812.txt` — the part that MOVES

⛔ **THE `.txt` BESIDE THIS FILE IS SEALED AND MUST NOT BE EDITED.** Its value is
byte-identity to a hash published on the bus at 2026-08-12 13:45, *before* math
drafted the same two cells:
```
sha256  cc2e08c49e695237f5e9818bc7afa1c3fbb045ae4d1b7396908f8b488c36d9c2
```
*Any edit — including a correct one — voids the pre-registration it exists to
prove. **Change this file instead.***

## ⚠️ WHY THIS FILE EXISTS: THE SEAL CARRIES A STANZA THAT WENT FALSE

The sealed text ends:
> *"NOT YET DONE, and required before landing: Liberty adjudication against the
> pinned PDK, and the Sky130.lean model + theorem."*

**That was true when sealed at 13:45. It was FALSE by 13:56, and the file did not
land until 14:28** — so it entered the repository already stale, and its commit
message recorded the completion zero times. A reader at HEAD finds a landed
document asserting outstanding work that was finished 32 minutes before it
arrived.

🔑 ***THE GENERAL LAW, AND IT IS THE REASON THIS WAS UNAVOIDABLE ONCE WRITTEN: AN
IMMUTABLE ARTIFACT CANNOT CARRY A TENSE. A frozen document may contain only
statements that are true at seal time AND STAY TRUE — a "not yet done" list is
guaranteed to rot and, uniquely, CANNOT BE REPAIRED IN PLACE.*** *The seal should
have contained the derivation and nothing else; the TODO belonged here from the
start.*

## CURRENT STATE (this file is the one that moves)

| item | state |
|---|---|
| hand-derivation from the naming convention | **DONE**, sealed 13:45, pre-disclosure |
| independence vs math's draft | **VERIFIED** — identical, seal unbroken |
| Liberty adjudication, pinned PDK `c6d73a35` | **DONE 13:56** — see below |
| `Sky130.lean` models + theorems | **NOT DONE** — math's draft is in gitignored scratch; silicon cannot land what it cannot read |
| `EXPAND` rows in `import_netlist.py` | **NOT DONE** — blocked on the above |

**LIBERTY ADJUDICATION, discharged 2026-08-12 13:56, read at the vendor file:**
```
nor4_1    function "(!A&!B&!C&!D)"             = De Morgan of !(A|B|C|D)   ✅
nand4_1   function "(!A) | (!B) | (!C) | (!D)" = De Morgan of !(A&B&C&D)   ✅
output pin Y on both                                                       ✅
```
*The vendor states the DUAL rather than the negation — the same shape the
importer already records for `a2bb2oi`.*

⚠️ **ONE HONEST LIMIT, carried forward from the bus post:** math and I agree on
temp names and left-associative chaining because we both patterned the SHAPE on
the `nor3`/`nand3` siblings — a shared source. **The FUNCTION and PIN NAMES are
independently corroborated; the SHAPE is one derivation wearing two hats.**

*Found 2026-08-12 14:49 by running compiler's self-retiring-stanza class against
my own landed artifacts.*
