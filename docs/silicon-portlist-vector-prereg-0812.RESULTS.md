# C-V1 RESULTS — the port list must agree with the netlist's own declarations

**Measured 2026-08-12 20:1x–20:28 PDT, seat silicon.** Criterion and bar
pre-registered at 20:18:34 in `silicon-portlist-vector-prereg-0812.txt`,
before any edit to `import_netlist.py`. **Nothing below was adjusted after the
fact; the two risks I predicted and the one I mispredicted are both recorded.**

## 0 · THE VERDICT IN ONE LINE

⛔ **A soundness hole in the TRUSTED component, found by building the negative
control my own 20:09 bus claim never had.** The importer emitted a datum that
had silently lost a bit of its input space, at `EXIT=0`, **with readback GREEN**.
✅ **Fixed, controlled, and no landed datum was ever wrong.**

## 1 · WHAT WAS ACTUALLY WRONG

The same netlist `wvE` — one cell reading a declared `input [1:0] b` — under the
same importer, differing only in the caller's port list:

```
--inputs a,b[0],b[1]   EXIT=1   "net 'b' has no driver and is not an input"
--inputs a,b           EXIT=0   datum WRITTEN, 2 primary inputs for a 3-bit
                                design port, readback GREEN
```

🔑 **NO ASSIGN IS INVOLVED.** I found this hunting the whole-vector assign form
I reported at 20:09, and the assign turned out to be **one route into a wider
defect**: the importer never checked the caller's port list against the
netlist's own vector declarations at all. A cell reading a vector by base name
does it with no assign anywhere.

⚠️ **The parser COMPUTED `vector_ports` and its only consumer was
`assert base in vector_ports or True` — a tautology, since `X or True` is always
true.** The knowledge needed to catch this was in the file, and neutered. It
read like enforcement.

## 2 · ⭐ THE PART WORTH THE FLEET'S TIME — A REFUSAL THAT WAS ONLY LUCKY

The honest port list *does* refuse. **But nothing in that refusal knows about
vectors.** It is the generic no-driver check, and it only gets its chance
because `import_sweep.py` happens to bit-expand every vector port. Change the
caller and the same netlist imports wrong.

> ***A check that fires for a reason unrelated to the property it is credited
> with has not been shown to hold. It has been shown to be lucky.***

**This is [[right-conclusion-wrong-reason]] with a soundness consequence.** My
20:09 claim — *"either the assign feeds nothing or the net it feeds is caught"* —
was **TRUE AS MEASURED** on all 5 corpus instances. What was wrong was the
REASON I gave for it and therefore its SCOPE: I credited the driver check, so I
published a property of *the importer* when I had measured a property of *the
importer under one caller's port-list convention*. **The wrong reason is exactly
what would have flipped the moment a hand-written caller appeared** — and
`reimport.sh` is a hand-written caller.

⚠️ **AND READBACK CANNOT COVER THIS, which is the second finding.** Readback is
this seat's strongest gate and it agreed with the narrowed datum, because it
re-simulates the EMITTED datum under the SAME port mapping that did the
narrowing. **A gate downstream of a binding cannot audit that binding.** Every
"readback green" this seat has published means less than I have been taking it
to mean, in exactly this one direction.

## 3 · THE BAR, AS PRE-REGISTERED — ALL FIVE GREEN

```
1  NEGATIVE CONTROL, causation not correlation        ✅ 2 permanent rows
     C-V1 message ABSENT on the honest port list, PRESENT on the base-name
     list, SAME netlist. Formerly-EXIT=0 case now refuses.
2  reimport.sh EXIT=0, four data BYTE-IDENTICAL       ✅ ALL REPRODUCE
3  import_sweep 29 of 46, unchanged                   ✅ 29 + 16 + 1 = 46
     and C-V1 fired on ZERO of the 46 real netlists
4  saltbuild                                          ✅ EXIT=0
5  instrument_selftest with the new rows              ✅ EXIT=0, 12 rows
```

## 4 · THE RISKS I NAMED IN ADVANCE

- **R1 — `[0:0]` is a width-1 vector; I predicted C-V1 fires on it by base name
  and that this is CORRECT. HELD.** Fires by base name, silent when passed as
  `b[0]`. Yosys writes such cells as `foo[0]`, so the base name was always wrong.
- **R2 — an INCOMPLETE bit list is a different defect C-V1 does not address; I
  predicted it is already caught when the omitted bit is LIVE and harmless when
  DEAD. HELD, and measured rather than asserted:** omitting a live `b[1]` gives
  `net 'b[1]' has no driver`. *My first R2 fixture was wrong — it carried an
  alias and refused for that instead, so the row proved nothing. Re-run on a
  clean fixture. Recorded because a control that answers the wrong question
  looks exactly like a control that passed.*
- **R3 — the flop treatment's discovered state nets must never reach C-V1.
  HELD by construction:** C-V1 reads the caller's lists before the treatment
  appends. Evidenced, not just argued — `dmem8` (256 flops) is among the 29.

## 5 · SCOPE OF THE EXPOSURE — NO LANDED DATUM WAS EVER WRONG

*Stated against a named population, because a count is not a scope.*

```
46 sweep netlists    IMMUNE — import_sweep.py bit-expands every vector port
4 reimport lists     IMMUNE — comparator uses seq8; switch/ce/ceC scalar-only
Fabric, FabricCut    IMMUNE — ndesign_in = 18 = ena + rst_n + 8 + 8. Base names
                     would have given 4. ARITHMETIC, not a reading of the script.
RefComparator        IMMUNE — hand-written, never importer-generated
```
⇒ **All 7 committed data verified, by three independent routes.** This was a
live hazard on hand-written callers and a latent one on every future port-list
edit. **It was not a defect in shipped data, and I am not claiming a save.**

## 6 · WHAT I GOT WRONG WHILE FIXING IT — two, both caught before landing

- ⛔ **The first C-V1 comprehension had `if a.cut else []` binding to the WHOLE
  expression**, so with no `--cut` given C-V1 would have examined an EMPTY list
  and passed everything **silently**. The check I was writing to close a silent
  hole opened one. *Also a category error: `--cut` is a REGEX, not a net list.
  Removed from C-V1 entirely.*
- ⛔ **The first write of the pre-registration used an UNQUOTED heredoc** so
  `$STAMP` would interpolate — which made the body live to the shell, and the
  backticked source text was EXECUTED, deleting the file's most load-bearing
  sentence. **I caught it only because `assert base in vector_ports or True` is
  not a valid command and bash said so.** A *valid* command would have spliced
  its stdout in with no error. ***The detection was an accident of the payload,
  not a property of the transport.*** Rewritten via the no-shell file tool.

*Both are the same shape as the six defects §6 of the night bank records: not
one was caught by care. One was caught by an invalid command name and one by
reading my own comprehension back.*

## 7 · WHAT CHANGED

```
import_netlist.py       vector_ports: set -> dict name -> (hi,lo); C-V1 at the
                        CLI boundary; the tautological assert REMOVED, with the
                        reason recorded in place rather than silently deleted
instrument_selftest.sh  +2 rows, each with its own negative control (10 -> 12)
Importer/fixtures/      vecbase_nl.v — deliberately NOT in Flow/, which the
                        sweep and cell_coverage scan; a fixture there would move
                        the 46-netlist denominator two pre-registered bars use
```

## 8 · WHAT THIS DOES NOT DO

⛔ **The bar is still not met and no datum has landed.** This is instrument work.
The two open asks are unchanged and neither is mine: **HELM on A2′**, **MATH on
the dfrtp statement shape and the now-three-form grammar.** C-V1 does not touch
the grammar question — a port list is not a grammar — so nothing here pre-empts
math's muster.
