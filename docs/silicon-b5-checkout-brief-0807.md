# B5 — THE CHECKOUT BRIEF: the revision mechanics

### 2026-08-07 ~21:1x, SILICON, for the council package. **Every fact below is
### read at its source today — the shuttle API, the repo, the dossier — or is
### marked UNRESOLVED. No remembered steps.**

---

## 1. WHERE WE ACTUALLY ARE — read from the shuttle API, just now

```json
GET https://app.tinytapeout.com/api/shuttles/ttsky26c
{ "deadline": "2026-09-07T20:00:00+00:00",
  "tiles":  { "total": 512, "available": 202 },
  "pcbs":   { "total":  80, "available":   0 },
  "mostRecentSubmission": {
      "name": "Verified 8x8 bit-serial banyan switch",
      "repo": "https://github.com/jyh/tt-verified-banyan-switch" } }
```

⇒ ✅ ***H1–H8 ARE ALL DONE. The project is registered and OUR REPO IS THE
SHUTTLE'S MOST RECENT SUBMISSION.*** **The floor is on the chip list.** *There is
no first-submission work left; B5 is a **re**-submission and nothing else.*

📌 **AND THE RECORDED NAME IS THE FLOOR'S TITLE** — *"Verified 8x8 bit-serial
banyan switch"*, which is `main`'s `info.yaml`. **What TinyTapeout currently
holds is the banyan alone.**

| | |
|---|---|
| deadline | **2026-09-07 20:00 UTC = 13:00 PDT** — 31 days out |
| tiles | **ours are bought** (4, 2×2, €280, 8/6). The 202-free figure is other people's risk, not ours |
| PCBs | 0 of 80 — the discounted devkit pool is gone; irrelevant to submitting |

---

## 2. THE CLICK SEQUENCE — a REVISION, not a first submission

**The Captain's part is ONE click, and it is the one the dossier flags as the
classic miss.**

1. Sign in at **`app.tinytapeout.com`** (GitHub OAuth — the only method).
2. Open the existing project — *not* "Create a new project*.* It is already
   there; §1 proves it.
3. **PRESS "Submit a new revision".**

⚠️ **THAT IS THE WHOLE OF IT, AND IT IS ALSO THE WHOLE OF THE RISK.** *The
dossier records TinyTapeout's own wording:* **"You have now submitted your
design, but it's not yet part of the tapeout."** ⇒ ***Paying is not submitting,
and PUSHING IS NOT SUBMITTING EITHER. A green CI run changes nothing on the
shuttle until that button is pressed.***

✅ **And it is reversible until the deadline:** *"Revisions may be resubmitted
freely until the deadline; **no new revisions will be accepted after the closing
date**."* The backing repo can even be swapped afterwards (**"Change" → new
URL**) provided it is template-based and its GDS action passes. ⇒ **Pressing it
early is cheap; pressing it late is the only irreversible mistake available.**

---

## 3. ⛔ THE ONE UNRESOLVED MECHANIC — AND IT GATES THE CLICK

**Which ref does TinyTapeout ingest?** *The dossier does not say. The
`tt-gds-action` README does not say. The shuttle API records a **repo**, with no
branch or commit field.*

🔴 **This matters more than anything else in this brief**, because the composed
tile lives on **`revision-bb1-composed`** and the floor lives on **`main`**:

* **If TT builds the repo's DEFAULT BRANCH** — which the evidence leans toward,
  since the submission's recorded *name* is `main`'s title and GitHub Pages for
  this repo serves from `main` — then **pressing "Submit a new revision" today
  would re-submit THE FLOOR**, and the composed tile must be **merged to `main`
  first**.
* **If TT lets you pick a run or ref**, no merge is needed.

📋 **HOW TO SETTLE IT — two minutes, and it must be done BEFORE the click, not
after:** open the project page and look at the revision dialog. *If it offers a
branch/commit/run selector, take the branch. If it does not, the merge in §4 is
mandatory.* ⇒ ***Do not infer this from the outcome of a click that cannot be
un-pressed inside a deadline.***

### ✅ HALF OF IT IS NOW MEASURED (silicon, 8/7 20:4x — re-verified 23:1x)
**The "evidence leans toward" clause above is no longer a lean. It is a reading:**
```
gh api repos/jyh/tt-verified-banyan-switch --jq .default_branch   →  main
gh api repos/jyh/tt-verified-banyan-switch/branches/main          →  f14a4fa
                                                                     = THE FLOOR
```
⇒ ***`default_branch` IS `main`; `main` IS `f14a4fa`; `f14a4fa` IS the floor. So IF
TT builds the default branch, pressing Submit today re-submits the floor — and the
premise of that conditional is now MEASURED rather than inferred.***
⚠️ **WHAT REMAINS UNRESOLVED IS ONLY THE OTHER HALF: does the revision dialog offer
a branch/commit/run selector?** *No API answers that; it needs a human at the page.*
📌 **AND NOTE THE INSTRUMENT, because `git` cannot answer either question here —
the TT repo is NOT cloned on this machine, and `git` reports `f14a4fa` as
`fatal: ambiguous argument`, which reads like a broken repo rather than a missing
clone. Use `gh api`. Reading a ref never needs a checkout.**
🟢 **B4 STATUS AT THE TIME OF WRITING: CLOSED and UNCONDITIONAL (`33a3c86` +
sweep `924a44e`; the corpus's own build emits
`✓ SaltWorks.HDL.composed_switch_of_bnC_driven [3 axioms]`).** *So the floor law no
longer holds B5 — **this §3 dialog question is the only remaining gate**, and it is
not one a seat can answer.*

---

## 4. WHAT REPLACES WHAT — the floor law, unchanged

**The campaign's rule (`bb1-composed-switch-addendum.md:67`):** *"the revision
replaces the floor **ONLY when CI is green and B4 is in the kernel**."*

```
main   f14a4fa   the PROVEN BANYAN ALONE      ← the floor. Untouched all day.
       ↑ never moved, and must not move until both gates below are ✅

revision-bb1-composed   e5b8331   the CONVENTION-C COMPOSED TILE
       CI green            ✅  six of six on 0d15a06
       re-emission         ✅  bnCCore, sorter feeds banyan directly
       B4 in the kernel    ⛔  compiler's trace induction → discharge to runNet
```

⇒ **When `hseam` discharges: merge `revision-bb1-composed` → `main` (if §3 says a
merge is needed), confirm the six jobs go green on `main`, THEN press.**

⚠️ **AND THE FLOOR LAW HAS A SHARP EDGE WORTH SAYING OUT LOUD: merging to `main`
IS the act that retires the floor.** *Until that merge, a failed revision costs
nothing — the shuttle still holds a proven banyan.* ***After it, `main` is the
composed tile and there is no proven-banyan fallback on the chip list.***
📌 **If the seam does not land in time, DO NOTHING: the floor is already
submitted and already proven. B5 is an upgrade, never a rescue.**

---

## 5. WHAT IS READY ON MY SIDE

* **P1/P4/P5/P6** ✅ — wrapper, bench, config, licence headers; `test` green.
* **P8** ✅ — the flow is **pinned to a SHA** (`tt-gds-action@651ea05e…`), because
  `ttsky26c` is a movable tag. ⚠️ **Its obligation: RE-CHECK the tag before the
  click** — a pinned repo silently keeps a stale flow, and the shuttle re-runs
  `precheck.py` on the submitted `.oas` itself.
* **PDK pinned** to `8afc8346…` (the *hardening* revision), read from `pdk.json`
  in the artifact, not remembered.
* **Artifacts staged** for OPEN-THE-DIE v2 at
  `${LOCAL_SEAT}/tour-0807/composed/` — GDS, OAS, post-layout netlist, SPEFs,
  render, and a `PROVENANCE.md` naming the run and commit.
* **Datasheet** carries the convention-C numbers (38.6 / 56.5 / 71.1) and no
  longer claims the pre-C ones.

## 6. WHAT THIS BRIEF DOES NOT SAY

* It does **not** say the revision is ready to submit. **One gate is open and it
  is not mine.**
* It does **not** resolve §3. *That is a two-minute look at a page I should not
  be clicking through on the Captain's account.*
* The `gl_test` green means the bench's cases pass on the post-layout netlist.
  **It is not the proof.** The proof is `hseam` plus the composed theorem.
