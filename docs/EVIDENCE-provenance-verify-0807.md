# S2 PROVENANCE BUNDLE — the fresh-eyes verification (2026-08-07)

**Duty:** the maestro's 13:08 order — *"your successor-self may verify the bundle
binds what it claims."* Subject: `a5d2ef7` (the bundle) against `bf2de34` (the
artifact). Verifier: the EVIDENCE seat, rebooted at 13:08, with no memory of the
bundle being built.

⚠️ **This is a check of the BINDING, not of the mathematics.** Whether the program
sorts is S3(b) and belongs to math. Everything below is about whether the record
and the artifact are actually attached to each other, and whether every number
printed on the record is true.

---

## The verdict in one line

🥇 **The bundle binds MORE than it claims — it is content-BOUND, provably — and
three of the sentences describing it are wrong.** The strongest claim in the
README is the one it declined to make.

---

## 1. 🥇 THE HEADLINE: "provenance, not contents" UNDERSTATES THE BUNDLE

The README's honest qualification reads:

> ⛔ The math seat did NOT read the transcript before committing it. […] So this
> bundle certifies **provenance, not contents**.

**That qualification was written because a 548 KB transcript will not fit in a
working context. But a transcript does not have to be READ to be CHECKED.** The
executor's `Write` and `Edit` calls are structured data. Replay them in order:

```
line   102  Write   -> 23882 chars, 517 lines
line   108  Edit    -> 23837 chars (-177 +132)

replayed    24070 bytes   515 lines  b1802e5d538c4a41ab51c6de57b4c89a…
committed   24070 bytes   515 lines  b1802e5d538c4a41ab51c6de57b4c89a…
```

⭐ **IDENTICAL. Character for character, byte for byte, on the first attempt.**
Two logged tool calls reproduce the committed `Program.lean` exactly — no hand
edit, no post-hoc touch-up, no seat-side polish between the executor's last
keystroke and the commit. The authorship claim in the module docstring
(*"every line written by an AI agent"*) is not a testimonial. **It is a
reproducible derivation, and it now has a tool that reruns it.**

📌 **Content-BOUND is not content-VETTED, and the distinction survives.** Replaying
the record proves the record produced the file; it says nothing about whether what
the agent did along the way was sound. **The README's caveat was true about
VETTING and wrong about BINDING, and it spent its honesty on the wrong one.**

*Why the seat that built the bundle could not see this: it was reasoning about the
file as something to READ, and at 548 KB the answer was correctly "no". The
adjacent-object principle from the other side — the right object, refused for a
property (size) the question did not actually turn on.*

## 2. ⛔ "BOUND IN THE SAME COMMIT" IS FALSE

> bound to `SaltWorks/Stack/Program.lean` **in the same commit** so the artifact
> and its birth record cannot drift apart or be separated later.

**`a5d2ef7` contains four files, and `Program.lean` is not one of them:**

| commit | contents |
|---|---|
| `bf2de34` | `SaltWorks/Stack/Program.lean`, `docs/LEDGER.md` |
| `a5d2ef7` | the four `docs/provenance/s2/` files — **and nothing else** |

✅ **What IS true:** `bf2de34` is an ancestor of `a5d2ef7` (verified), so the record
provably cannot predate the artifact, and the blob has **not** drifted —
`HEAD:…/Program.lean` is still `b2bf183b`, identical to `bf2de34`'s.

⛔ **What is not true is the MECHANISM.** Same-commit containment was the stated
guarantee and it was not the one used. The gap is real and directional: **a later
commit can edit `Program.lean` while the bundle sits unchanged**, still carrying a
README that says they cannot come apart. *The claim is safe today and unenforced
tomorrow.*

⇒ **Fixed by instrument, not by wording** — see §5.

## 3. ⛔ "ALL 120 ASSEMBLED WORDS" — THE FILE HOLDS 51

The README's table and the commit message both promise *"all 120 assembled
words."* `s2-emitted-program.md` ends in Lean's `#eval` truncation marker:

```
… 6464691, ⋯]
```

📊 **Counted: 51 words listed, of 120. 42.5%.** The `(120, 120)` header pair is
genuine and the two length theorems are real; the LIST is a truncated `#eval`
that nobody re-read after pasting. **The one file in the bundle whose entire
purpose is to be the program as DATA is the one file that is not all there.**

✅ **And the 51 that are there are structurally sound** — checked, because a
truncation and a fabrication look alike at a glance:

| test over the 10 complete 5-instruction groups | result |
|---|---|
| `w[1] == 297059` in every group (the branch) | ✅ 10/10 |
| `w[2] == w[4]` in every group (the 3-XOR swap's outer pair) | ✅ 10/10 |
| distinct compare words | 9 of 10 — group 8 repeats group 0, as a Batcher network should |

⇒ **The defect is truncation, not invention.** Regenerate the `#eval` with the
full list (`set_option pp.maxSteps`/`maxNumeric` or print via `IO`), or change the
sentence to *"the first 51 of 120."* **Either fixes it; leaving both is the only
wrong answer.**

## 4. ✅ WHAT CHECKED OUT EXACTLY

| claim | verdict |
|---|---|
| SHA-256 `eb3cf4e6…5fc81` | ✅ **exact** — working tree, committed blob, and README all three agree |
| 136 lines | ✅ exact |
| "a faithful copy" of the machine-local original | ✅ **verified** — the source is still on disk at `…/-claude-salt/9a758ca5…/subagents/agent-ac01cfad….jsonl` and is **byte-identical** to the committed copy |
| the transcript is where the program was written | ✅ 2 `Program.lean` mutations among 49 tool calls (41 `Bash`, 5 `Write`, 3 `Edit`); the other writes are `ScratchMATHS2.lean` / `…neg.lean`, exactly the scratch discipline the fleet's laws require |
| the executor's two errors are in the record | ✅ both, in its own words, with the certificates named |

### 📐 "548 KB" — the sixteenth axis

The file is **558,073 bytes**. That is **545.0 KiB**, or **558.1 kB**. It is not
548 of anything… until you ask what object *does* read 548:

```
ls -lh   545K        the file's length
du  -h   548K        the file's ALLOCATION  (137 × 4096 = 561,152 B = 548 KiB)
```

⇒ ***A true reading of an adjacent object, and the adjacent object was one
`du` away.*** **Sixteenth axis, and the first one found by a seat auditing a
document rather than an instrument.** The figure is off by 0.5% and nothing turns
on it — *which is the point: this is what the principle looks like when the stakes
are zero, and it is the same shape as when they are not.*

### 📌 The publication gate, scoped rather than warned about

The README flags the unredacted transcript as a publication-gate item and is right
to. **What it did not do is measure the exposure, so here it is:**

| class | hits | unique |
|---|---|---|
| absolute `/Users/jyh/…` paths | 225 | **14** |
| session / agent UUIDs | 508 | **141** |
| `claude.ai/code` session URL | 2 | 1 |
| email addresses | 3 | **1** — `noreply@anthropic.com` |
| API keys / `sk-` tokens | **0** | 0 |

⚠️ **My own instrument's false positive, named:** the email regex also matched
`n@LE.le` twice — that is Lean's `@LE.le` notation, not an address. *Reported
because a scanner's own wrong hits belong in the scan.*

⇒ **The exposure is REAL, SMALL, and MECHANICALLY REDACTABLE: 14 path strings and
141 UUIDs, no secrets, and — the part that matters for salt's purge doctrine —
NO outside-domain and no personal-account addresses.** This is not the class of
exposure the purge exists for. *It is a `sed` at the gate, not a history rewrite,
and whoever cuts the repo public should be told that rather than left to fear the
worst.*

## 5. 🔧 THE INSTRUMENT — `docs/ledger-tools/provenance_replay.py`

A finding that lives in a document decays. **The check is now a tool**, and the
manifest (`docs/provenance/MANIFEST.tsv`) is what makes §2's unenforced guarantee
enforced:

```sh
python3 docs/ledger-tools/provenance_replay.py --manifest docs/provenance/MANIFEST.tsv
# ✅ BOUND — the replay reproduces the committed artifact exactly.
# ✅ FAITHFUL COPY — bundle == source
# VERDICT: PASS (exit 0)
```

⚠️ **`--against HEAD:…` is deliberate, not a missing pin.** A pinned rev would pass
forever while the live artifact drifted away from its birth record. **HEAD is what
makes drift a RED.**

**Three-way exit, inherited from `import-closure.py`'s hard-won lesson —
0 bound · 1 MISMATCH · 2 could not check.** *Exit 2 exists because a green from a
tool that read nothing is worse than a red.*

### Mutation-verified — ten cases, and the tool is red in every one it should be

| # | mutation | expected | got |
|---|---|---|---|
| M0 | the real bundle | PASS | ✅ 0 |
| M1 | compare against a different real module | MISMATCH | ✅ 1 |
| M2 | **artifact edited in a later commit** ← *the drift §2 leaves open* | MISMATCH | ✅ 1 |
| M3 | bundle file missing | could-not-check | ✅ 2 |
| M4 | wrong `--target` path | could-not-check | ✅ 2 **(not a false green)** |
| M5 | the `Edit` op deleted from the transcript | MISMATCH | ✅ 1 |
| M6 | one unparseable JSON line | could-not-check | ✅ 2 |
| M7 | empty bundle | could-not-check | ✅ 2 |
| M8 | source tampered (one byte) | COPY DIFFERS | ✅ 1 |
| M9 | bad git rev | could-not-check | ✅ 2 |

📌 **M4 is the one that would have been a bug.** A wrong `--target` yields zero
matching ops, and the obvious implementation replays nothing, compares an empty
string, and reports… a mismatch — *or, in the version where an empty buffer is
"unchanged", a PASS.* **It refuses instead**, because the failure mode this whole
directory exists to prevent is a certificate that certifies nothing.

⚠️ **Two of my first-cut mutation tests (M1, M2) were themselves wrong** — they
named `SaltWorks/Stack/Machine.lean`, which does not exist, so the tool correctly
returned exit 2 and I briefly read a *working refusal* as a *missing detection*.
Redone against real paths and a real forward-drifted blob. ***A test that fails
for the wrong reason is indistinguishable from a passing test until you read the
message it printed.***

---

## What I would hand the next reader

1. ⛔ **One-token fix, owed by whoever owns the README:** *"in the same commit"* →
   the truth, plus a pointer at `MANIFEST.tsv`.
2. ⛔ **Regenerate `s2-emitted-program.md` with all 120 words, or retitle it 51.**
3. 🥇 **Upgrade the bundle's own claim** — it certifies provenance *and binds
   contents*; only the vetting is missing. **This is the campaign's strongest
   available sentence about agent-written code and it is currently unsaid.**
4. 📌 **Wire `provenance_replay.py --manifest` into the gate** that already runs
   `selftest.py` and `import-closure.py`, and add a manifest row for every future
   bundle at the moment it lands.

⭐ **And the thing worth banking: the seat that built this bundle wrote its
caveat honestly and wrote it about the wrong half. It could not read 548 KB, so it
said "provenance, not contents" — when the contents were checkable all along by a
machine that never reads a word.** ***The honest qualification and the unnoticed
strength were the same fact, seen from a context limit.***
