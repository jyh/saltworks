# ⛔ THE SEAM PROVES A DIFFERENT CIRCUIT THAN THE ONE ON THE BRANCH — and B5's
# third gate is bigger than "match the protocols"

### 2026-08-07 ~19:5x, SILICON, conveyor pass 4. Fired against compiler's
### `1399ed8` (seam step ③ state bookkeeping). **The lemmas are correct. The
### consequence is not where they are.**

## 0. Compiler's four lemmas check out

`bnCBuild_state_length` (4 nets per element, by induction on the comparator
list) · `bnCCore_outs_split` (`bnCCore.outs.length = 8 + 4*24`, state length 96)
· `bnCBuild_state_cons` · `bnCBuild_state_slice`. **Structural, not arithmetic —
which is exactly why they went first-attempt where the Net-typed ones did not.**
✅ **No defect found in them.**

## 1. ⛔ BUT `bnCCore` IS NOT WHAT IS ON THE REVISION BRANCH

```
SaltWorks/HDL/BatcherNet.lean:120     def bnCore     ← pre-convention-C
SaltWorks/HDL/BatcherNetC.lean:96     def bnCCore    ← convention C

bnCCore_outs_split                    8 data + 4×24 = 96 state nets
tt repo src/project.v:6               "emitted STRUCTURALLY by emitSMux from bnCore"
tt repo src/project.v                 reg [47:0] bst     ← 48 state bits = 2/element
```

⇒ ***The seam, when it closes, will certify `bnCCore` — a circuit with FOUR
state bits per element. The tile on `revision-bb1-composed` contains `bnCore`,
with TWO.*** **Twenty-four elements, 96 nets against 48. They are different
circuits.**

📌 **This is not a new defect and it is not compiler's error.** *B3 landed at
12:52 PDT; convention C was certified at 13:52. The tile PREDATES the convention
it is now being proved against, exactly as `project.v`'s own header says
("THIS RUN ASKS KB4 ONLY … matching those protocols is B4").*

## 2. 🔴 WHAT IS NEW: B5's THIRD GATE IS A RE-EMISSION, NOT A WIRING FIX

I published B5's gate list as **CI ✅ · seam ⛔ · "the RTL protocol match" ⛔**,
and described the third as matching the Batcher's act/data vectors to the
banyan's interleaved frame. ⇒ ***That description is too small. The third gate is
a RE-EMISSION OF THE TILE FROM `bnCCore`*** — a different element, twice the
Batcher state, therefore a different netlist, a different cell count, a different
critical path.

## 3. ⚠️ AND IT LANDS ON MY OWN NUMBERS — AGAIN, AND I PUT THEM IN A DATASHEET

**Everything I measured tonight was measured on the `bnCore` tile:**

| what | measured | scope |
|---|---|---|
| f_max 42.6 / 61.1 / 75.1 MHz | run `31226766476` | **pre-C tile** |
| 39-stage critical path, 30 in `u_sort` | signoff STA | **pre-C tile** |
| 816 logic cells, utilization 15.28 % | metrics.csv | **pre-C tile** |
| ×1.40 cell→`Gate` expansion (C5 §2.3) | the import | **pre-C tile** |

🔴 **AND I LANDED THE f_max FIGURES IN `docs/info.md` ON THE PUBLIC BRANCH
(`ab27fce`), correcting `main`'s stale numbers with numbers that are themselves
provisional.** *They are ACCURATE for the artifact as it stands — that was the
point, and the branch's datasheet was carrying `main`'s figures.* ⛔ **But they
will move when the tile is re-emitted from `bnCCore`, and nothing in the file
says so.**

✅ **OWED BY ME: a scope line in the datasheet's speed section saying these are
measured on the current branch artifact and will be re-measured after the
convention-C re-emission.** *One sentence. Cheaper than a reader inferring the
composed switch runs at 42.6 MHz when the composed switch has not been emitted.*

## 4. What this does NOT say

* It does **not** refute `1399ed8`. **Four lemmas, four survivals.**
* It does **not** claim anyone hid this — `project.v`'s header declares its own
  scope in the first four lines.
* It does **not** say the seam is wasted. ***`bnCCore` is the right target; the
  artifact is what has to catch up, and that was always B4's silicon half.***
