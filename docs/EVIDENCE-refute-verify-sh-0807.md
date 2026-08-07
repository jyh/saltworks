# FRESH-EYES REFUTATION — `docs/provenance/verify.sh` (math, `f713c1f`)

**Duty:** the maestro's standing refutation order, priority (1) — *"does `verify.sh`
actually bind what it claims; run it, try to break it."* **Method:** an isolated
`git clone --local --no-hardlinks` into scratch, so the five-seat worktree is never
mutated. Seven break attempts, one live observation.

⚠️ **This is a check of the CHECKER.** The bundle itself was verified separately
(`EVIDENCE-provenance-verify-0807.md`); nothing below disputes the bundle's contents.

---

## Verdict

🥇 **The tool does the job it was built for — the defect-2 truncation is caught
cold.** ⛔ **But it returns `BOUND` from a manifest that checked NOTHING, and the
way that happens in practice is a missing trailing newline.**

---

## ✅ What survives the attempt (the tool works)

| # | attempt | result |
|---|---|---|
| **D** | truncate the word list to 51 + restore the `⋯` marker — **the exact 2026-08-07 defect** | ✅ `DRIFTED`, exit 1 |
| **E** | one byte appended to the executor transcript | ✅ `DRIFTED`, exit 1 |
| **F** | a bundle file deleted outright | ✅ `DRIFTED`, exit 1 |

⭐ **D is the one that matters: the check math built to close defect 2 permanently
does close it.** *The word count is genuinely derived — `cmpEx_length × batcher8_length`
read out of the Lean sources — and the marker check is correctly scoped to the fenced
data region so the tool does not flag its own documentation.* **That scoping is itself
a fix for the self-match class that has cost this fleet five findings in two days.**

## ⛔ Defect 1 — a manifest with no data rows returns `BOUND`

```
manifest reduced to comment lines only   ->  exit 0
                                             "BOUND: the bundle binds what it names."
```

⇒ ***A green from a tool that verified nothing.*** 📌 **This is precisely the
`import-closure.py` lesson — *"exit 0 with `OUTSIDE: 0` when `git ls-files` failed…
a clean green from a tool that had read nothing, in a tool whose job is gating a
commit"* — arriving in a tool written by the seat that has been citing it approvingly
all day.** *The loop is correct row-by-row; nothing asserts that any rows existed.*

## ⛔ Defect 2 — a missing trailing newline silently drops the LAST row

```
last line written without "\n"   ->  exit 0, "BOUND"
                                     words-check output: ABSENT (never ran)
```

**`while IFS=$'\t' read -r kind path expected` returns non-zero on a final unterminated
line, so the loop exits before processing it.** ⛔ **The manifest's last row is
`words … 120` — the defect-2 check.** ⇒ ***A one-byte, visually undetectable edit
disables the single check the tool exists for, and the tool reports success.***
*Any regeneration through `printf '%s'`, a Python `write()` without a trailing newline,
or an editor configured to strip final newlines produces exactly this.*

📌 **This is the mechanism by which defect 1 happens by accident rather than by
sabotage. They are one finding in two parts.**

## ⛔ Defect 3 — the manifest is not itself pinned

```
the `words` row deleted from the manifest   ->  exit 0, "BOUND"
```

**Any check can be removed and the tool still certifies the bundle.** *The manifest
says what to verify; nothing verifies the manifest.* ⚠️ **My own `REPLAY-MANIFEST.tsv`
has the identical gap — this is a finding against both tools, and I am not exempting
mine.**

## 📊 Live observation — `verify.sh` is RED in the tree right now, and not from a defect

```
expected 4abd7975…   (pinned at f713c1f, 14:06)
got      343c7aa6…   (Program.lean, after 202dd11 "C5IND")
```

⇒ **Program.lean moved again within ~50 minutes of the pin.** *This is legitimate
development, and the tool is reporting it correctly by its own design.* **It is the
same anchoring question I got wrong in the other direction at 13:2x** (I anchored a
BIRTH record at `HEAD:` and it went permanently red; this pins CURRENT and needs a
bump on every edit). 📌 **Not a defect — a maintenance cost that lands on whoever
edits a live module, and it should be a stated cost rather than a surprise.**

⛔ **But one claim in the header does not survive it.** The docstring asserts:
> *(1) the program blob is the one the bundle was written about;*

**`4abd7975` is the post-S3(b) blob. The bundle was written about `b2bf183b` — the
transcript replays to that, 841 lines earlier.** ⇒ ***The row pins "the blob as of
when I wrote this manifest", which is a real and useful thing, but it is not "the blob
the bundle was written about."*** *Same shape as the defect-1 finding math already
accepted this morning: the sentence names one mechanism and the code implements
another.*

---

## 📝 Proposed, not applied — math owns this file

1. **Count the data rows and refuse on zero.** `rows=$((rows+1))` in the loop; after
   it, `[ "$rows" -gt 0 ] || { echo "FAIL: manifest has no data rows"; exit 1; }`.
   Stronger: assert each expected `kind` was seen at least once.
2. **Read the final unterminated line:** `while … read -r kind path expected || [ -n "${kind:-}" ]; do`.
3. **Pin the manifest itself** — a `sha256` row naming `MANIFEST.tsv` cannot work
   (self-reference), so either put the expected row-count in the script, or have the
   script assert the set of `kind`s it requires.
4. **Reword claim (1)** to what the code does: *"the program blob matches the pin
   recorded here"*, and state the maintenance cost — **or** pin `bf2de34` and say
   "as born", which is `REPLAY-MANIFEST.tsv`'s question and would make the two tools
   redundant rather than complementary. **The current split is better; only the
   sentence needs to match it.**

⭐ **The honest summary: three of six break attempts got through, all three by the
same route — nothing checks that the checks ran.** *The row-level logic is sound and
the defect-2 check is genuinely derived and genuinely works. The gap is one layer up,
and it is the layer this fleet has now been bitten at three times: `import-closure`'s
empty read, my own wrong-`--target` refusal, and this.*
