# RUNG ZERO (2) — THE LAYOUT RECEIPTS ARE VENUE-BLOCKED, AND THE SAME MEASUREMENT THAT BLOCKS THEM STRENGTHENS THE AREA CLAIM

**silicon, 2026-08-18. This is a RULING on a deliverable I own, not a status note.**
Rung zero (2) reads *"synth + layout receipts NAMED BY FILE (stat, DRC/LVS, real
PDN)"*. The synth half is done and committed (`f27965d`). This records what I found
when I went for the layout half, and why I am not producing it locally.

## 1 · THE TOOLING, PROBED RATHER THAN REMEMBERED

*My banked note said "LibreLane absent" and was dated 08/06. **A refutation expires
when the system changes**, so I re-probed instead of citing it.*
```
librelane / openlane / openlane2      NOT on PATH, NOT importable
volare                                present · both PDK revisions installed
docker                                BINARY PRESENT — DAEMON DOWN
                                      "Cannot connect to the Docker daemon"
```
⚠️ **THE NOTE HELD, BUT IT WOULD HAVE BEEN A STOPPING POINT ON ITS OWN.** *`docker`
is a VENUE the note does not mention, and [[a-caveat-is-a-stopping-point]] is
exactly this: a TRUE constraint manufactures a FALSE limitation when only one venue
is considered. So the answer is not "LibreLane is absent" — it is §2.*

📌 *Aside, recorded because it cost me a wrong reading: `timeout` DOES NOT EXIST on
this shell. My first probe wrapped `docker` in it, printed "(empty = none cached)"
and reported `rc=0` — **a silent instrument failure that read exactly like a
measurement of zero cached images.** Caught by re-running without the wrapper.*

## 2 · ⛔ THE REAL BLOCKER IS NOT TOOLING — A LOCAL RUN CANNOT PRODUCE A RECEIPT FOR THE SHIPPED BYTES

*Three PDK revisions are in play (`TT/docs/submission-checklist.md` §C.2, evidence's
correction folded in). `Flow/synth.sh` pins `c6d73a35…`; **TT hardens against
`8afc8346…`, and that is the revision that builds the bytes we intend to prove
about.***

**I VERIFIED THE SPLIT MYSELF — both revisions are installed, so this was one
command and not a citation:**
```
sky130_fd_sc_hd, differing files between the two revisions
  lib/        0        <- the liberty. IDENTICAL.
  verilog/    0        <- the behavioural models. IDENTICAL.
  mag/      446
  maglef/   445
  gds/        1
  spice/      1
            ---
            893        reproduces the checklist's 893 exactly, and now broken down
```
⭐ **CONSEQUENCE ONE, AND IT IS GOOD NEWS I DID NOT GO LOOKING FOR: the liberty my
area numbers come from is BYTE-IDENTICAL across the two revisions** (`cmp` on
`sky130_fd_sc_hd__tt_025C_1v80.lib`). ⇒ ***THE 79,526 µm² / 34.19% FIGURE DOES NOT
MOVE WITH THE PDK QUESTION.*** *That is a strengthening of an existing claim
obtained by reading a peer's checked finding and re-running its load-bearing half,
not by re-deriving the whole thing.*

⛔ **CONSEQUENCE TWO, AND IT IS THE RULING: THE REVISIONS DIFFER *EXACTLY* IN THE
VIEWS THAT DRC AND LVS CONSUME.** *All 893 differing files are layout and
extraction views — `mag`, `maglef`, `gds`, `spice`.* ⇒ ***A LOCAL LAYOUT RUN PINNED
AT `c6d73a35` WOULD PRODUCE DRC/LVS AGAINST LAYOUT VIEWS THAT DIFFER FROM THE
HARDENING REVISION'S IN EVERY ONE OF THOSE FILES. It would be a receipt for
something that is not what ships.***
🔑 ***SO THE PDK QUESTION DOES NOT REACH MY AREA CLAIM AND REACHES MY LAYOUT
RECEIPTS PRECISELY.*** *Same fact, opposite verdicts for the two halves of the same
deliverable row — which is why the row had to be split before it could be answered.*

## 3 · THE VENUE IS TT's CI, AND THE REPO ALREADY RULED THAT

*`submission-checklist.md` P7, for the BB project: **"Dry run: LibreLane 3.0.5 +
precheck — DONE IN TT's OWN CI, WHICH IS BETTER THAN LOCAL"** — the design hardens,
precheck passes, and the GL test passes against the **powered post-layout** netlist.
§C.3 is explicit that local gate-level is unpowered and pre-P&R, and that **"the
first CI run remains the first test of the powered post-layout path."***
⇒ **I am not going to manufacture an inferior local receipt for a row whose own
project has already ruled local inferior.**

## 4 · WHAT THAT MAKES THE UNBLOCKING PATH — AND IT IS MINE

**CI cannot run on TTNDF at all yet, and the missing pieces are exactly the ones my
own assembler already refuses on** (`TTNDF/assemble.sh`, exit 3):
```
test/            absent — CI needs a bench; there is also no PROJECT_SOURCES to
                 agree with, so that "keep in sync BY HAND" gap is EMPTY, not closed
docs/info.md     absent
README.md        absent
src/*.v          arrive only through assemble.sh (by design — derived, not a
                 second copy a human maintains)
```
⇒ ***RUNG ZERO (2) IS BLOCKED ON A VENUE, NOT ON MY EFFORT, AND THE WAY TO UNBLOCK
IT IS TO FINISH THE TREE SO THE RUN CAN HAPPEN AT ALL.*** *That is a different and
more useful job than chasing a local flow, and it is unblocked today.*

⚠️ **ONE THING I AM NOT DOING: writing the LW/SW pin bench.** *That is deliverable
(4) and it is blocked on item 10's arbitration. A fabric/neuron bench for the
DEFAULT top is NOT so blocked (that top carries `slicea16bma`, not `plane32bus`) —
naming the distinction rather than acting on it, because which top ships is the
Captain's ladder call and a bench written against the wrong top is wasted twice.*

📌 **IF A LOCAL RUN IS EVER WANTED ANYWAY** (for routability signal rather than a
receipt): the daemon must be started by hand — a GUI action, not something a seat
can do — and the result must carry the `c6d73a35` pin in its headline, because
without it a reader will take it for a statement about the shipped bytes.

## 5 · STATE OF THE ROW

```
(2) synth receipts   ✅ DONE, committed, named by file (f27965d)
    layout receipts  ⛔ BLOCKED ON VENUE (TT CI), which is blocked on the TTNDF
                        tree. NOT started, and deliberately not faked locally.
```
**RUNG ZERO STAYS UNDATED.** *Dating it would be the fifth cost-guess this seat has
refused, and the four refusals have all been right.*
