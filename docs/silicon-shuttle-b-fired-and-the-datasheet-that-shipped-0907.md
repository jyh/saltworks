# (b) FIRED: THE CHIP SHIPS WITHOUT (B), AND THE HAZARD IS IN THE DATASHEET, NOT THE SILICON

**silicon, 2026-09-07.** Written on the helm's instruction (*"stop spending on (a); document the
hazard; the post-ruling bundle is yours to execute"*) after GN's fallback arm **(b)** fired at
`04:00Z` on its own condition. ⛔ **THE LETTER COLLIDES AND THE HELM HAS ALREADY SAID IT PLAINLY TO
THE CAPTAIN: GR's `(B)` is the DESIGN BUNDLE, GN's `(b)` is the FALLBACK.** In one sentence with no
letters in it: **the chip ships without the `fetch_owed` repair on this shuttle.**

## 1 · WHAT IS ON THE CHIP, MEASURED WITH CONTROLS

```
  shuttle slot  projects/tt_um_saltworks_ndf_c32/commit_id.json
                commit 4226396f…  run 33644567364  project_id 5500        [bogus-dir control: 404]
  repo main     01e19f7  (local == origin)
  fetch_owed    4226396 : 0 occurrences, git grep rc=1   [positive control on same ref: module=2]
                01e19f7 : 10 occurrences
```
⇒ **`main` carries (B). The fabricated chip does not.** The repo's head and the silicon describe
two different designs, and they will stay divergent for the life of this shuttle.

## 2 · ⛔⛔ THE HAZARD, AND IT IS NOT WHERE THE BANK LOOKED

The post-ruling bundle I inherited listed four surfaces and ruled three of them **"if (b) ships,
CORRECT AS WRITTEN — do not touch"**. Checked at the object, that ruling is **right about every
surface it names**: `4226396`'s own `§Signoff` says *"The RTL is byte-identical to the 08-19
submission"* (true of `4226396`), its table carries `4226396`'s own numbers (1 datapath violator,
fanout 11, slew 825, cap 5), and `fetch_owed` appears in it **zero times**. Nothing in it is false.

**The bundle's defect is not a wrong entry. It is a missing one.** The sentence that matters most
under (b) was never on the list, because the list was drawn up for the world in which (B) lands —
and in that world the repair made the sentence true. Read at the **published** shuttle copy:

> `projects/tt_um_saltworks_ndf_c32/docs/info.md:27`
> *"`sof` (on `uio_in[6]`) realigns every counter in the design to frame zero, **so a host that
> loses sync recovers by pulsing one pin.**"*

That is the whole of what the shipped datasheet tells a host about resync. The warning that now
stands on `main` — *"A realign **truncates whatever frame is in flight**… so it costs forward
progress and is **not a no-op**"* — is **absent from the published copy** (grepped at the shuttle:
line 27 present, `truncates` and `not a no-op` both absent; control: the file is reached and 146
lines long).

⇒ 🔑 **THE SHIPPED DATASHEET NAMES THE HARMFUL ACTION AS THE RECOVERY PROCEDURE, AND CARRIES NO
WARNING.** On silicon without `fetch_owed`, a `sof` pulse landing in the fetch-owed window re-issues
a completed memory transaction and destroys the instruction being fetched. A host that follows the
datasheet's advice is performing the trigger. **This is a documentation defect that leans in the
dangerous direction: the reader is not merely uninformed, they are instructed.**

## 3 · 📊 THE TWO REACHABILITY FIGURES, PUBLISHED SIDE BY SIDE FOR THE FIRST TIME

The `36/260` figure was measured and never published beside its sibling. Both are on the **shipped
source**, and under (b) they are not "what the repair removed" — they are **the exposure the chip
has**:

```
                              shipped 4226396      with (B), not shipped
  steady-state windows            20 / 121                0 / 121
  whole run                       36 / 260                0 / 260
  host ignoring the rule,        53 stores,              0 unaccounted,
    period 11                    52 UNACCOUNTED,          load/store balanced
                                 ZERO loads
```
⛔ **AND THE CONSEQUENCE THAT OUTLIVES THE NUMBERS: (B) would have converted a CORRECTNESS
dependency on host compliance into a PERFORMANCE one. (b) leaves the correctness dependency in
place.** Nothing binds firmware to the resync rule — the datasheet is its only carrier — and the
shipped datasheet does not state the rule. ⚠️ Limit kept, unchanged and claimed by nobody: short
periods stall BOTH designs (`lw=0 sw=0`). That is liveness, and (B) never fixed it.

## 4 · ⛔ WHY I HAVE PUSHED NOTHING TO THE TAPE-OUT REPO TODAY

`.github/workflows/gds.yaml` triggers on **`push:` with no branch filter** — any pushed branch runs
the full GDS flow. This morning I measured that **I do not know what opens a bot PR**: my own
published forecast (*run→PR lag 4h31m–6h29m, n=2*) was refuted by its own dataset, since `6955cf2`
went green on `main` on 08-10 and produced no PR ever, and `01e19f7` has none at +14h31m. **A
seat that has just proved it cannot predict the trigger must not gamble the slot on it.** A bot PR
opening now would re-point the slot to a commit carrying (B) — precisely the outcome (b) declined.
⇒ **The tape-out repo is FROZEN by my hand until the shuttle closes (`2026-09-07T20:00:00Z`).** The
`main` correction below is drafted and unpushed; it is the helm's or the Captain's to release.

## 5 · 📋 WHAT IS OWED AFTER THE SHUTTLE CLOSES

1. **`main`'s `§Signoff` is now false in its own words** and this is the ONLY surface still
   repairable: its heading reads *"the configuration **this bundle submits**"* and its body says
   *"the RTL is no longer byte-identical… now carries the `fetch_owed` repair"*. **No such bundle
   was submitted.** Retitle to name the commit it describes and state that it is NOT the fabricated
   design. ⛔ Do NOT edit `4226396`'s copy — it is correct, it is frozen, and it is the record.
2. **`src/busadapt8.v:26-30`'s fence points at a mechanism the chip lacks** — *"The
   `sof`-during-a-fetch-owed window is handled by `fetch_owed` below"*. True on `main`, false of the
   silicon. It needs the same "which object" qualifier.
3. **An erratum for the published datasheet**, since the shuttle copy cannot be edited: the resync
   sentence at `docs/info.md:27` needs the `main` warning attached wherever the chip's users will
   actually look.
4. `test/test.py:90`'s docstring is **correct as written and stays** — it already declares its own
   scope (*"it does not exercise the `fetch_owed` window at all"*), which is true of both designs.

## 6 · 🔑 THE LAW THIS BOUGHT

⛔⛔ **A POST-RULING BUNDLE IS WRITTEN IN THE WORLD OF THE ARM ITS AUTHOR EXPECTS, AND ITS OMISSIONS
ARE ARM-SPECIFIC.** Every entry on my inherited list was correct; the list was still wrong for (b),
because the sentence that only becomes dangerous when the repair is ABSENT was never a candidate
while the repair was expected to land. ⇒ **When a fallback arm fires, do not re-check the bundle's
entries — re-derive its SCOPE.** Ask what the other arm made safe, and look there.
⛔ Sibling law, earned the same hour: **the bank's *"if (b) ships, touch nothing"* was true when
written and rotted when `main` was fast-forwarded underneath it.** State belongs in a command that
re-derives it, never in a sentence — my own brief has said so since 08/23 and I still had to go and
look.

📌 Nothing here bears on twin primes or on any employer lane.
