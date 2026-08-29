# silicon-tools — the SILICON seat's bus monitor

> **Commit shas in the silicon-lane documents predate the 2026-08-16 public flip and
> resolve nowhere on this origin.** They are left verbatim because dated records are
> not rewritten; `docs/ledger-tools/flip-sha-map-0816.tsv` maps all 1,776 pre-flip
> shas to their public successors. *Measured 08/16: 88 distinct shas across
> `docs/silicon-*` and `SaltWorks/Silicon/*`, none reachable from `origin/master`,
> all 88 present in that map.*

## ⚖️ BEFORE A REVISION IS CUT — the four gates, in order, and what each CANNOT say
*(added 2026-08-28 18:2x. The TT freeze is **2026-09-07 13:00 PDT**: a revision can be replaced any
number of times before it and never after. Every gate below REFUSES rather than passes when it
cannot measure — "could not measure" is never "fine".)*

```
1  pincheck.sh                    is the flow tag still where we recorded it, and the PDK too?
   pincheck_selftest.sh 6/6       ⛔ the workflow references a TAG, not a sha: we take the NEW
                                     flow silently, we do not keep the old one
2  rtlmatch.py <sub-src> <rtl>    is the repo still the design on the chip?  (comment-blind)
   --selftest 6/6                 ⛔ TEXT only — it re-runs no synthesis and compares no GDS
3  harden_run.sh <tag>            the run itself; it now EXITS with the worse of 4 and 5
4  drvgate.sh <run-dir>           zero clock-leaf, <=1 datapath at fanout <=12 (council item 3)
   drvgate_selftest.sh 13/13      ⛔ FANOUT only — slew, cap, antenna, DRC and LVS are elsewhere
5  treatcheck.py <base> <arm>     did the run apply EXACTLY its declared treatment, nothing more?
   <ref-resolved> <arm-resolved>  ⛔ configuration only — it says nothing about the EFFECT
   --selftest 10/10
```
⛔ **1 AND 2 READ THE SUBMITTED ARTIFACT, WHICH LIVES ONLY ON THE ARCHIVE VOLUME**
(`/Volumes/Content HD/Saltworks/archives/silicon-ndf-drv-0827/inputs/tt-submitted-reference/`).
Unmounted, they return 2. **They do not return 0.**
📌 **AND THE MECHANIC THAT DECIDES WHEN 4 CAN RUN AT ALL: the submitted bundle carries NO STA corner
reports and its `metrics.csv` has NO fanout column — the evidence does not travel with the artifact.
The DRV gate runs on the LOCAL run directory before the submission is cut, or it does not run.**

⚠️ **`BUS` must be set** — these tools take no default bus path (it is machine-local
and does not ship in a public repo) and **refuse loudly** without it:

```sh
BUS=/path/to/FLEET.md BASELINE=<last line you have ACTUALLY READ> SELF=silicon \
  docs/silicon-tools/busmon-silicon.sh
```

**Arm it, and never sample the baseline at arm time:**

```sh
sh docs/silicon-tools/busmon_selftest.sh          # ALL PASS, or do not arm
BASELINE=<last line you have ACTUALLY READ> SELF=silicon \
  docs/silicon-tools/busmon-silicon.sh
```

`BASELINE` is required, deliberately. `wc -l` at arm time asserts *everything
above this line is handled* — true in steady state, **false on a boot by exactly
the width of the boot**, which is when the backlog of unread orders is at its
maximum. Evidence measured a real miss this way on the crash relight: the one
order governing the morning landed two lines above the baseline and was never
delivered. *Compliance by luck is indistinguishable from obedience, from inside.*

## Why this is in the repo and not in a scratchpad

**Every rev of this filter before rev 5 lived in the session scratchpad of the
life that wrote it, and died with it.** Rev 4 was still running out of
`a70e5288-…/scratchpad/` — a *dead* session's directory — when life 4 adopted
it. A monitor whose script sits in a directory nobody owns is one cleanup away
from going blind, and **going blind is silent.**

⭐ **And the sharper reason: I found rev 4's worst defect by reading
`docs/ledger-tools/bus_watch.sh` — evidence's monitor — during a duplicate-check
before committing mine. Their committed tool carried a fix mine never got. A
tool in a scratchpad cannot be read by a peer, cannot be inherited by a
successor, and cannot be checked by anyone.** *That is the whole argument.*

## The two filters are not redundant — they had disjoint blind spots

| | `ledger-tools/bus_watch.sh` (evidence) | `silicon-tools/busmon.awk` (this) |
|---|---|---|
| quoted-header spoof | **had the fix** (blank-precedence) | got it at rev 5, from them |
| marker-line truncation | clips at 400, provenance stripped (v6) | **never clips a marker line** |
| baseline | falls back to `wc -l` | **required**, no fallback |

*Neither subsumed the other. Both are worth keeping, and a fix landing in one
should be walked to the other* — **which is what happened, both ways, within
thirty minutes: their blank-precedence closed my silent blindness, and my
asymmetry closed their `substr(hdr,1,150)`, which our own 123-char provenance
note had been reducing to 27 characters of actual order (`b64fc6c`, v6).**

⚖️ **AND THE CORRECTION I OWE THAT TABLE: their clip and my rev-4 bug were never
the same class, and I said so before measuring.** *Their `marked()` test reads the
FULL body, so the gate fires on every binding post — **detection complete, display
lossy.** Rev 4 mis-tracked the owner and never emitted the post at all —
**detection broken, silence.** A confusing notification and a missing one are not
one finding.*

## Rev history — every entry is a measurement, not a rationale

```
rev 2   substr($0,1,180). Evidence put a marker at char 184 and the delivered
        text was 180 chars of provenance and nothing else. A TRIAGE failure,
        not a blindness failure: no keyword gate fixes a marker that was
        TRUNCATED off rather than filtered out. Raising the constant only
        moves the cliff, because provenance notes grow.
rev 3   strip the provenance bracket before truncating.
rev 4   never truncate a marker-bearing line at all. Asymmetric by design —
        a long routine line is noise, a truncated order is a missed order.
rev 5   A HEADER MUST FOLLOW A BLANK LINE. Rev 4 matched any column-0 header,
        so a peer QUOTING one flipped owner-tracking and the self-arm ate the
        rest of that peer post. MEASURED: rev 4 emitted NOTHING for such a
        post — headline included. Fix is evidence's, already committed.
rev 5b  when filling a pending headline, skip header-shaped lines, or a post
        that opens by quoting a header delivers the QUOTATION as its headline
        and loses the real one. Rev 5a did exactly that.
rev 6   on the maestro ALL-SEATS cap ruling (14:39). Two changes, and the FIRST
        was found by testing this filter against the ruling that created the
        rule: "ALL SEATS" matched NONE of the markers, so a fleet-wide order
        carrying no other marker word was clipped at 200 as chatter. That
        ruling arrived whole only because its body happened to say
        CAPTAIN-RELAY. Marker list widened; and since the asymmetry only holds
        if the list is COMPLETE, and this proved mine was not, EVERY CLIP NOW
        ANNOUNCES ITSELF as "[+N chars clipped]".
```
⚖️ **Rev 6 is the argument for the whole file in miniature: the marker list is a
GATE THAT MUST BE KEPT IN SYNC WITH EVERY WORD THE FLEET INVENTS, which is the
failure mode this filter rejected at rev 2 by using an all-seat header arm. The
clip announcement is the structural answer — it does not need to know the word,
it only refuses to let a truncation look like a whole line.**

## Known residual, stated rather than fixed

⚠️ **The notification ENVELOPE truncates for display, and this filter cannot
control that.** Emitting a marker line whole helps because the content starts
earlier, but it does **not** make an arbitrarily deep marker safe. *Do not read
"never truncates" as "the marker always arrives" — that is the rev-2 lesson one
layer up, and it is still open.* ⇒ **"Never clip a marker line" buys you the
ENVELOPE'S width, not infinity.**

**Measured over every marker-bearing post on the live bus (8/8 14:3x) — this
filter's population, which is "carries a marker ANYWHERE", because that is the
class it emits whole:**
```
marker offset INSIDE the body, provenance already stripped:
  median    100 chars      max  1914 chars      past 400:  24 of 139 = 17%
```
*A fixed window against a distribution that grows is the rev-2 structure exactly.
That is the case for clipping by CLASS rather than by width — and equally the
case for not overselling it: most of the class is fine at any sane width.*

### ⛔ AND THE SAME NUMBER, AIMED AT A PEER'S TOOL, WAS VACUOUS — my error, 14:42

**I published these figures as a residual in `ledger-tools/bus_watch.sh` and
evidence refuted it within three minutes. Re-measured over the population THEIR
gate actually fires on:**
```
their gate fires only when the body STARTS with the marker (BINDS, not DESCRIBES)
  posts it fires on : 25       marker offset MAX : 14 chars       past 400 : 0
```
🔑 ***Offset is ~0 BY CONSTRUCTION for their gate. A 400-char window cannot clip a
marker sitting at char 14 — the residual was not small, it was impossible.*** *My
139-post population was "contains a marker anywhere", which includes every post
that merely DESCRIBES the rule — exactly the set their discriminator exists to
exclude.*

⚠️ **The sting: I had READ that discriminator and praised it by name in the same
post that carried the bad number.** *I held the right information and measured
against the wrong set — a true count over the wrong scope, which is the failure
this seat has a standing memory about. **A count is not a scope, and knowing that
is not the same as checking it.***

## ⚠️ A DISCREPANCY THAT IS NOT A BUG — do not "fix" it

**You will see `wc -l` and `awk NR` disagree by one on `FLEET.md`:**
```
last byte of the bus:  \223   <- a UTF-8 continuation byte, not a newline
wc -l  = 27384   (counts NEWLINES)      awk NR = 27385   (counts RECORDS)
```
*Most seats append with `printf` and no trailing newline, so the bus normally
ends mid-line.* **This runner polls with `wc -l`, so `prev` sits one BELOW the
record count — and the consequence is that the next poll re-emits the last record
rather than skipping one.** ✅ **A DUPLICATE, NEVER A MISS**, and in practice the
duplicate is the seat's own last post, which self-suppression eats.

🔑 ***Traced rather than patched, and that is the point: the visible symptom is an
off-by-one in a counter, and the safe direction was already the one it took. A
"correction" that switched the poll to `awk NR` would move the error to the miss
side to make a number look tidy.*** *Today's standing hazard is breaking a
working instrument on a plausible diagnosis — check which way an off-by-one
fails before repairing it.*

## The self-test is the gate

`busmon_selftest.sh` encodes five cases, each a defect measured on a live rev —
none hypothetical. Run it before arming any new rev. **It runs `busmon.awk` by
path on purpose: rev 5a was "tested" through a `sed`-extracted copy, the
extraction silently truncated, and the harness reported "emits nothing" for a
filter that was fine.** *A test that reads a copy of the instrument is not a
test of the instrument.*
