# ⭐⭐ THE FABRICATED DESIGN — `01e19f7`, THE RTL THAT WENT TO FAB

**This directory is not "the current RTL". It is a photograph of the design that was
manufactured.** `01e19f7ef1d1c68255ea424265251c0a377e4b7e` is the commit the TinyTapeout shuttle
slot pins for `tt_um_saltworks_ndf_c32`; it carries **shape (B)**, the `fetch_owed` repair.

⛔ **A 2027 READER MUST NOT MISTAKE THIS FOR HEAD.** `4226396` and `01e19f7` are both history now;
only one of them is the chip. The directory is named for the sha for exactly this reason.

## WHY VENDORING IS SAFE HERE, WHEN IT USUALLY IS NOT
Vendoring a moving target is how a fixture rots. **This target cannot move: the design has been
fabricated.** Until the tape-out closed, "the shipped RTL" named a different commit every few
days — and it did: two landed sweeps in this repo measured `4226396` and called it *the SHIPPED
DUT*, which was true when written and false the moment the Captain clicked. **The freeze is what
makes this fixture legitimate**, and it is the whole of the argument.

## ⛔ THE THREE CONDITIONS THIS FIXTURE IS HELD TO (evidence, saltworks' lead, 2026-09-07)
1. **PINNED IN THE FIXTURE, AND CONFORMANCE IS CHECKED AGAINST THE EXTERNAL REF.** `PIN.psv`
   carries the ref and, per file, git's blob id and the content sha256. `docs/ledger-tools/
   check_fabricated_fixture.sh` verifies these **against `github.com/jyh/tt-neural-dataflow-fabric`
   at that ref** — never against the local clone that produced the copy. *A gate comparing an
   artifact to the source that PRODUCED it proves CUSTODY, never CONFORMANCE.*
2. **NEVER SILENTLY TRACK `main`.** The pin is a SHA. If the RTL moves, that is a **new sibling
   directory** `Fabricated/<newsha>/` — never an edit to this one. The layout makes that
   structural rather than remembered. *(As of 2026-09-07 the external `main` happens to equal
   this sha. That is a coincidence of today and is not what is pinned.)*
3. **LABELLED AS THE FABRICATED DESIGN** — in the path, in this file, and in `PIN.psv`.

## ⛔⛔ DO NOT EDIT THE `.v` FILES — NOT EVEN TO ADD A WARNING
The bytes must equal the external ref's bytes exactly, so **the label lives beside them, never
inside them.** This seat has already paid for the other lesson once: a protective marker added to
a digest-frozen file moved its digest and voided the thing it was protecting. **A freeze forbids
every edit, including a protective one**, and a file cannot carry its own digest.

## WHAT THIS BUYS
The two compliant-host sweeps needed a shuttle checkout, so they were **one-shot MEASUREMENTS and
could never be scheduled.** With the DUT committed here they can run in CI — which converts them
into **ARMS**. The `sof` host-protocol exposure is a permanent property of a part that exists.
