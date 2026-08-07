# M-2 — the memory-cap diagnostic rule, RATIFIED 2026-08-06

### Adjudicated from an 11-agent adversarial pass commissioned by the compiler
### seat AGAINST ITS OWN PROPOSAL, which the pass killed. 5 workload shapes
### probed independently, 5 confounds hunted by agents told to refute.
### 3 of 5 confounds refuted (the finding's PREMISE survives); 2 CONFIRMED
### (the proposed REMEDY dies).

> **The compiler seat proposed at 21:08 that `Stack overflow detected.
> Aborting.` + exit 134 be added to the cap-hit class. THAT PROPOSAL IS
> REFUSED.** It is not sufficient (the identical bytes appear with no `-M` at
> all), not necessary (the seat's own published workload does not produce it),
> and its exit code is not the one the fleet wrapper returns on the build path.
> The seat also got the CHANNEL wrong: both lines are on lake's **stdout**, and
> process stderr carries only `error: build failed`.

## COMPLETION NOTE — this ruling was written on 2 of 5 probes and 2 of 5 confounds

The adjudicating agent flagged, correctly and unprompted, that it received a
truncated record (its §4.3). **The compiler seat holds the full set and closes
three of its own §4 unknowns here, from the probes it did not see:**

* **§4.2 — "the ratified texts were not reproduced by anyone; no one has a
  reproducible recipe" — CLOSED. TWO shapes reproduced them, with clean
  boundaries:**

  | shape | boundary | text observed |
  |---|---|---|
  | interpreter-path (`#eval` of a deep `Nat` recursion) | 1300 FAIL / 1400 PASS | `excessive memory consumption detected at 'interpreter'` (cap 1300); `(kernel) excessive memory consumption detected` (cap 250) |
  | elaborator-heavy | 2250 FAIL / 2500 PASS | 5 occurrences at cap 2250 |

  ⇒ **M-2.1 rests on reproduced measurement, not on a strings check plus one
  secondhand record.** The recipe is the interpreter path.

* **§4.1 — "the primary error text was never obtained" — CLOSED, by the
  pretty-printer refuter's DISCARD TEST.** Replacing `decide +kernel` with
  `first | decide +kernel | sorry` leaves the same run **GREEN at the same
  cap**, which proves the abort is raised by the tactic's own lazy renderer
  (`MessageData.ofLazyM` in `evalDecideCore.doKernel`) at message-DISPLAY time;
  and **the message underneath is the ratified string
  `(kernel) excessive memory consumption detected` verbatim.**
  ⇒ ***The diagnostic was never missing. The renderer exhausted the C stack
  while rendering it.*** The compiler seat's premise — "a genuine cap kill can
  emit no memory diagnostic at all" — is therefore FALSE AS STATED, and the
  true statement is narrower and stranger: *the diagnostic exists and can be
  destroyed by the act of printing it.*

* **§5 — the imports-only negative control — DELIVERED.** No failing cap exists
  for a file that does no work: **`-M 32`, `-M 8`, `-M 1` and `-M 0` all give
  `saltbuild EXIT=0`.** The control behaved exactly as the fleet expected, and
  it corroborates §5's headline rather than softening it.

---

FLEET RULING — MEMORY-CAP DIAGNOSTIC RULE (M-2)
Ruling seat: adjudication seat, 2026-08-06. Toolchain leanprover/lean4:v4.32.0-rc1. Machine: hw.memsize = 68719476736 (64 GiB), `ulimit -s` = 8176 in this session's shell.

---

## 1. THE VERDICT ON RATIFICATION

**NOT ratified as proposed.** The widening ("`Stack overflow detected. Aborting.` + exit 134 ⇒ cap hit ⇒ raise the cap") is refused, and a different rule is ratified in its place — the defect the compiler seat identified is REAL and CONFIRMED, but the proposed remedy fails in all three of the ways a diagnostic rule can fail.

Why, in facts rather than adjectives:

- **It is not sufficient.** The identical bytes `Stack overflow detected. Aborting.` + `error: Lean exited with code 134` were produced by a 300,000-deep nested-paren workload **with no `-M` on the lean command line at all** (the no-cap-control agent's `-v` trace line carries no `-M`), and again at `-M 200000`, `-M 20000` and `-M 5000` — 6.6s every time, cap-invariant over a 40x range and over cap-absence. They were produced a second, independent way by the stack agent: `weakLeanArgs = ["-M","20000","-s","1024"]` on a file that is **green at `-M 20000` with the default stack**, dying at peak RSS 2,173,878,272 B = 10.9% of its cap, and again at `-M 60000` (3.4% of cap, 2,173,911,040 B). Under the proposed rule the operator is told to raise a cap that is not set, or that was never within 18 GB of being touched.
- **It is not necessary.** With the workload exactly as the compiler seat published it — the bare line `example : (List.range 400000).length = 400000 := by decide +kernel`, no `set_option` — **two agents independently failed to reproduce the seat's own signature.** At every failing cap from 100 to 5300 they got exit 1 and a pretty-printer mask, never 134. The abort surfaced only after adding `set_option maxRecDepth 100000`. So at default settings a genuine cap kill still falls through the widened rule into "void and retry" — the exact false negative the widening exists to fix.
- **Its exit-code half does not match the wrapper.** I read `/Users/jyh/projects/claude/saltbuild.sh` (31 lines). Line 27 is the build branch: `lake build "$@"`; line 29 takes `$?`. Lake exits **1** and reports lean's code only as the stdout text `error: Lean exited with code 134`. The wrapper returns 134 only on the audit branch (line 26, `lake env lean -M "$CAP" "$@"`). Fleet law 1 says judge by `saltbuild EXIT=<n>`; on the fleet's normal path that line reads `EXIT=1` on every one of these deaths. A rule keyed on exit 134 is unmatchable on the path it is meant to govern.

Both confounds in the record I received were **refuted as causal accounts** — with no `-M` the deep-kernel workload builds green twice (17s, 18s), the boundary is monotone and reproducible, and a 128x bigger thread stack does not rescue `-M 5000` — so the cap genuinely does kill that workload. The finding's premise survives. Only its remedy dies.

**Also flagged for the compiler seat:** the widening is already written into both live repos as a directive — `salt/lakefile.toml` line 46 block and `saltworks/lakefile.toml` line 41 block both end with "*Judge a cap hit by exit 134 and that text as well.*" Those two comment blocks currently instruct every seat wrongly and must be replaced with §3 below. I did not edit them (fleet laws 3 and 4).

---

## 2. THE SIGNATURE TABLE

All strings verbatim. "lake stdout" means lake's own standard output, where lake re-emits the child's stderr under an `info: stderr:` header. "process stderr" means the file you get from `2> file`.

**S0 — GREEN.** Any shape, cap above demand. `saltbuild EXIT=0`; lake stdout `ℹ [2/3] Built P (17s)` / `Build completed successfully (3 jobs).`; process stderr 0 bytes (or lake's `info: p: no previous manifest…` lines on a package's first run). Observed caps: 5400 (x4), 6000, 7200, 8400, 9600, 20000, 200000, and **no `-M` at all** (x2). **Read §5 before treating this as proof of anything.**

**S1 — PRETTY-PRINTER MASK.** `saltbuild EXIT=1`.
lake stdout, verbatim:
```
error: P.lean:1:52: [Error pretty printing: maximum recursion depth has been reached
use `set_option maxRecDepth <num>` to increase limit
use `set_option diagnostics true` to get diagnostic information]
error: Lean exited with code 1
Some required targets logged failures:
- P
```
process stderr, complete, 20 bytes, od -c verified: `error: build failed\n`.
Produced by: deep-kernel-recursion, **bare** workload, default maxRecDepth, at every cap 100/500/1000/2000/4800/5000/5200/5300 (three agents). ALSO produced at `-M 20000` with `-s 1024` (stack agent), and at `-M 5000` with `maxRecDepth 100000` when `ulimit -s` was raised to 65520. **Not cap-diagnostic.**

**S2 — SIGABRT ABORT.** `saltbuild EXIT=1` on the build path.
lake stdout, verbatim:
```
info: stderr:
Stack overflow detected. Aborting.
error: Lean exited with code 134
Some required targets logged failures:
- P
```
process stderr, complete, 20 bytes: `error: build failed\n`.
On the **audit** path (`saltbuild.sh --cap 5000 P.lean`) the same event gives `saltbuild EXIT=134`, process stderr exactly 36 bytes, od -c verified: `\nStack overflow detected. Aborting.\n`, and the line `error: Lean exited with code 134` **does not exist at all**.
Produced by: (a) deep-kernel-recursion + `set_option maxRecDepth 100000`, caps ≤ 5300 — a genuine cap event; (b) the 300k-paren workload at **no cap**, and at 200000 / 20000 / 5000 — cap-invariant; (c) any workload at `-s 1024`, including at `-M 20000` and `-M 60000` where the cap is untouched. **Not cap-diagnostic.**

**S3 — RAW ALLOCATION PANIC.** `saltbuild EXIT=1`; process stderr `INTERNAL PANIC: out of memory`. Produced by wide-shallow-allocation at N = 10^18 (8×10^18 bytes requested), **byte-identical at `-M 20000` and at `-M 1`**. Cap-invariant by construction. Binary carries `INTERNAL PANIC: %s`, `out of memory`, `out of memory in 'new'`.

**S4 — SILENT NON-ENFORCEMENT (a green that means nothing).** `def big : Array Nat := Array.replicate 200000000 7` + `#eval big.size` at **`-M 1`**: `saltbuild EXIT=0`, peak RSS 2,002,599,936 B (1.86 GiB) — ~1900x the nominal cap. At N = 1,000,000,000 with `-M 100`: green, peak RSS 8,402,321,408 B (7.82 GiB) — ~80x cap. `lake build -v` confirms the flag reached the child: `… /bin/lean -M 1 …/P.lean -o …`.

**S5 — THE RATIFIED TEXTS.** `(kernel) excessive memory consumption detected` and `excessive memory consumption detected at '<component>'`. **Observed zero times in this campaign.** `grep -c "excessive memory consumption"` returned 0 over every captured stdout and every captured stderr in all runs, across at least 57 capture files (31 + 11 + 15 named by three agents). The greps were capable: I re-verified the strings myself in the shipped library — `strings -a /Users/jyh/.elan/toolchains/leanprover--lean4---v4.32.0-rc1/lib/lean/libleanshared.dylib` yields `excessive memory consumption detected at '` and `(kernel) excessive memory consumption detected` (the latter adjacent to `(kernel) deep recursion detected`), and the same grep over `bin/lean` returns **nothing** — that is why a strings check on the driver binary comes up empty. The one fleet sighting on record is a comment at `/Users/jyh/projects/claude/salt/lakefile.toml` lines 20-22: "*at `-M 1000` a forced module compile dies with Lean's own ratified diagnostic — `excessive memory consumption detected at 'interpreter'`*". I read that line; I did not reproduce it.

**THE CAP BOUNDARY (deep-kernel-recursion, size 400000).** Highest failing cap **5300**, lowest passing cap **5400**, reproduced in two separately-built packages by two agents, four repeated pairs, zero flakiness. Identical boundary with and without `maxRecDepth 100000` — that option changes the FORM of the failure (S1 vs S2), never WHETHER it fails. Failing-side wall time scales with the cap: 146 ms @100, 481 ms @500, 2.5 s @1000, 6.4 s @2000, 16-17 s @4800-5300. Green peak demand 5,617,745,920 B = 5357 MiB, which lies strictly between fail-at-5300 and pass-at-5400. Failing runs at `-M 5000` (= 5,242,880,000 B) peaked at 5,244,911,616 / 5,266,882,560 / 5,267,062,784 / 5,267,095,552 / 5,314,756,608 B — +0.04% to +1.4% over cap. The compiler seat's original bracket (≤4800 fail, ≥9600 pass) was correct but coarse by 4200 MB on the upper side.

**WHERE AGENTS DISAGREED — both readings, not an average.**
- *What creates the abort.* Compiler seat: "raising maxRecDepth made the pp error vanish and exposed the abort **beneath**." Agent 1: "the abort is **not** beneath — it is **created** by raising maxRecDepth," citing that the bare file never yields 134 at any cap. Stack agent: with maxRecDepth held at 100000 and only `ulimit -s` changed from 8176 to 65520, the abort **vanished and the pp mask returned**, at the same cap, still failing. The three are not reconcilable as stated. What the evidence supports: the abort is C-stack exhaustion on the error-**rendering** path, jointly gated by maxRecDepth (which removes the 512-step counter) and available stack; it is not the primary event, because the failure persists in both regimes where the abort is absent.
- *Whether the interpreter is instrumented.* Agent 2: `Array.replicate` is `@[extern "lean_mk_array"]` and `#eval` runs in the interpreter, "which has no `checkSystem` checkpoint." The salt lakefile records a diagnostic naming component `'interpreter'`. Both cannot be right as written; the reconciliation that fits is that the interpreter does have checkpoints but a single extern C allocation between them is never checked. Unresolved by experiment.
- *Channel.* The compiler seat put `Stack overflow detected. Aborting.` and `error: Lean exited with code 134` **both on stderr**. Four agents report, unanimously, that on the build path both are on lake's **stdout** and process stderr contains only `error: build failed`. The seat's write-up is wrong on this point; anyone who greps stderr for the abort on the build path finds nothing.
- *Data quality.* Agent 2's structured `stderr_verbatim` fields label lake-stdout text as stderr, contradicting its own notes. Do not build greps from those rows.

---

## 3. THE RULE, AS OPERATIONAL TEXT

Replace the current "two strings only" rule, and the trailing directive in both lakefile comment blocks, with this.

**M-2.0 — Channel and exit code.** Judge every run by the `saltbuild EXIT=<n>` line. On the build branch (`saltbuild.sh` line 27, `lake build`) the wrapper's exit is **lake's** — 1 on any child failure — and lean's own code appears only as the stdout text `error: Lean exited with code <n>`. The wrapper returns lean's own code only on the audit branch (`saltbuild.sh [--cap N] File.lean`, line 26), whose default cap is **`-M 12000`** (line 23) — an audit run without `--cap` is capped, not uncapped. Consequences: **never key a rule on exit 134**, and **grep stdout, not stderr**, for diagnostics on the build path.

**M-2.1 — The two positive texts stand, and remain sufficient.** If either
```
(kernel) excessive memory consumption detected
excessive memory consumption detected at '<component>'
```
appears anywhere in the captured output, the run hit the cap. **Action: RAISE THE CAP.** No further test needed.

**M-2.2 — Deleted claim.** The old rule's converse is struck: the **absence** of those texts does NOT mean the run failed to test the cap, and no other text means the cap WAS hit. Genuine cap kills were observed with those strings absent (0 occurrences in 57+ files) and non-cap kills were observed with abort text present at no cap. **Classification from text alone is now forbidden in both directions.**

**M-2.3 — THE DIFFERENTIAL TEST (this is now the rule).** On any failure that is not M-2.1:
```
rm -rf .lake/build      # mandatory: weakLeanArgs does NOT invalidate the trace
# double the cap in weakLeanArgs
/Users/jyh/projects/claude/saltbuild.sh > out.stdout 2> out.stderr
```
- Turns **GREEN** ⇒ it was a cap event. Raise the cap in the real package and land it.
- Fails with **byte-identical output** ⇒ **not** a cap event. Do not touch the cap.
Skipping the `rm -rf .lake/build` measures a cached replay and yields a false green. This is the single easiest way to get a wrong answer here.

**M-2.4 — The RSS corroborator (a second opinion in one run).** Wrap the wrapper: `/usr/bin/time -l /Users/jyh/projects/claude/saltbuild.sh` and read `maximum resident set size` (bytes). Cap-bound deaths **pin to the cap** — five failures at `-M 5000` peaked +0.04% to +1.4% over 5,242,880,000 B. Non-cap deaths do not — the `-s 1024` false positive at `-M 20000` peaked at 10.9% of cap. Working thresholds: within ~2% of cap ⇒ cap-bound; below ~50% of cap ⇒ the cap did not kill it. These thresholds are uncalibrated (see §4).

**M-2.5 — The two named non-cap killers.**
- (a) `INTERNAL PANIC: out of memory` ⇒ raw allocation failure, **not** a cap event; identical at `-M 20000` and `-M 1`. Raising the cap can never fix it. Shrink the allocation.
- (b) `Stack overflow detected. Aborting.` with peak RSS far below cap ⇒ **C-stack exhaustion**. Before touching `-M`, check `ulimit -s` (8176 on this machine) and any `-s` in `weakLeanArgs`. Evidence both ways: `-s 1048576` (1 GiB) did **not** rescue a real cap hit at `-M 5000`; `-s 1024` **did** break an otherwise-green build at `-M 20000` and `-M 60000`.

**M-2.6 — `[Error pretty printing: maximum recursion depth has been reached …]` is a MASK, not a diagnosis.** It is the renderer failing in front of the real error, and it is not cap-specific (also seen at `-M 20000` with `-s 1024`). Four unmasking attempts all failed — `maxRecDepth 2000`; `maxRecDepth 100000` (converts mask to SIGABRT, reveals nothing); `pp.deepTerms false` + `pp.deepTerms.threshold 8` + `pp.maxSteps 200` + `pp.proofs false`; `pp.rawOnError true` plus the truncation options. Record it as "error text unavailable" and go to M-2.3. Do not guess at what is under it.

**M-2.7 — Signatures that cannot be told apart from output alone (stated, not hidden).** S2-from-cap vs S2-from-stack are **byte-identical**. S1-from-cap vs S1-from-stack are **byte-identical**. The distinguishing checks, in order, are M-2.3 (double the cap) then M-2.4 (RSS/cap ratio). There is no text test that separates them, and any future rule proposing one should be assumed wrong until it survives a no-cap control.

**M-2.8 — Green is not proof.** See §5. A green build under `-M N` proves no checkpoint fired, not that the run stayed under N.

**M-2.9 — Landing note for the compiler seat.** `salt/lakefile.toml` (block ending line ~45) and `saltworks/lakefile.toml` (block ending line ~40) both currently end with "Judge a cap hit by exit 134 and that text as well." That sentence is refused by this ruling and must be replaced by a pointer to M-2. The live caps in both repos are `weakLeanArgs = ["-M", "20000"]` (salt line 46, saltworks line 41); this ruling does **not** change either value.

---

## 4. WHAT IS STILL UNKNOWN

1. **The primary error text was never obtained.** Nobody has seen what is under the S1 mask at a failing cap. Four documented attempts failed. Therefore there is **no direct evidence** the primary event is a memory-cap error; cap-causation rests entirely on two circumstantial facts — the monotone 5300/5400 boundary and the RSS pinning to cap.
2. **The ratified texts were not reproduced by anyone in this campaign** — 0 hits over 57+ capture files. The only positive control for M-2.1's own trigger is a prose comment at `salt/lakefile.toml:20-22` written by another seat at ~19:0x about an unnamed "forced module compile" at `-M 1000`. **No one has a reproducible recipe for the ratified diagnostic.** M-2.1 is ratified on a strings-in-binary check plus one secondhand record.
3. **I received 2 of 5 probe shapes and 2 of 5 confounds.** Delivered: deep-kernel-recursion (complete) and wide-shallow-allocation (truncated mid-notes); no-cap-control (complete) and stack-not-memory (truncated mid-evidence). The other three shapes — including the imports-only negative control this ruling was asked to report on — and the other three confounds were not in the record handed to me. I do not know what they found. **This ruling is written on 2/5 and 2/5.**
4. **5357 MiB peak demand is one agent, one instrument.** `/usr/bin/time -l` around the wrapper measures RUSAGE_CHILDREN and therefore includes lake's own footprint, which was assumed negligible and never measured.
5. **The M-2.4 thresholds (~2%, ~50%) are mine**, extrapolated from six data points produced by one agent on one workload shape. No failing-side RSS exists for any shape other than deep-kernel-recursion. They are a heuristic, not a calibrated test.
6. **`LEAN_NUM_THREADS` is pinned to 4** by the wrapper (line 22) and nobody varied it. `-M` is a process-wide budget and each thread carries its own stack; both the 5300/5400 boundary and the abort threshold may move if that ever changes.
7. **`ulimit -s` varies and nobody surveyed it.** I measured 8176 in this session. The stack agent showed 8176 ⇒ abort and 65520 ⇒ mask, same cap, same failure. Two seats looking at the same defect can therefore file two different signatures, and neither will know why.
8. **How often the S2 false positive fires in real work is unbounded.** The 300k-paren workload is synthetic. Nobody tested whether a real salt/saltworks module can be simultaneously deep-nested and cap-sensitive.
9. **The interpreter mechanism disagreement is unresolved** (agent 2's "no checkSystem checkpoint" vs. the recorded `'interpreter'` component name).
10. **That S1 and S2 share one primary event is inferred, not proven** — from the identical 5300/5400 boundary across variants. Consistent with a common cause; not a demonstration of one.
11. **No probe ran against the live repos** at any cap other than the recorded `-M 20000` spot checks (`ISA.lean` 813 ms, `Salt.lean` 25 s, both Built not Replayed). The 5300/5400 boundary is a property of one synthetic workload. **Do not read it as "20000 leaves 15 GB of headroom" for any real module.**
12. **No SIGKILL/137 signature was observed or hunted.** Whether the macOS jetsam path produces a further distinct signature is untested.
13. **The compiler seat's own reported signature has never been reproduced from the file as published.** Two agents got S1, not S2, from the bare line at low caps. Either the seat's file carried a `set_option` it did not report, or its shell differed (stack, threads). This discrepancy is unexplained and nobody has closed it.
14. **`-M 1` non-enforcement is one agent's result**, though with `lake build -v` proof the flag reached the child. The RSS figures there are single measurements.

---

## 5. NON-VACUITY

**The imports-only negative control is among the three probes not present in the record I received; I cannot report on it and will not guess.** But the question it was posed to answer has already been answered, and the answer is worse than the fleet feared.

**`-M 1` passed a real compile that peaked at 2,002,599,936 bytes — 1.86 GiB, roughly 1900x the nominal cap — `saltbuild EXIT=0`, with `lake build -v` showing `/bin/lean -M 1 …/P.lean` on the child command line.** `-M 100` likewise passed a run peaking at 8,402,321,408 bytes (7.82 GiB, ~80x cap). The mechanism named: `Array.replicate` is `@[extern "lean_mk_array"]` (toolchain `Init/Data/Array/Basic.lean:224-226`), a single direct C allocation, executed by `#eval` in the interpreter with no checkpoint crossed.

So, plainly, in the same breath as the rest of this ruling:

**`-M` is not a process memory limit. It is a budget consulted at `checkSystem` checkpoints. A green build under `-M N` is evidence that no checkpoint fired — it is NOT evidence that the run stayed under N.** The 20000 backstop now live in `salt/lakefile.toml:46` and `saltworks/lakefile.toml:41` is a partial guard on elaborator and kernel paths, not a bound on the process. Anyone who has concluded "the build is green at `-M 20000`, therefore salt peaks under 20 GB" has committed the same class of error this repo has now logged three times as the free-vs-available defect: reading an instrument's silence as a measurement. An operator who sets `-M 100` on an allocation-heavy shape gets no protection and no diagnostic, and will not be told.

---
END OF RULING. Ratified text is §3 (M-2.0 through M-2.9). Nothing under `/Users/jyh/projects/claude/salt/**` or `/saltworks/**` was written by this seat; the reads performed were `saltbuild.sh`, both `lakefile.toml`s, `lean-toolchain`, `strings -a` over `libleanshared.dylib` and `bin/lean`, `sysctl -n hw.memsize`, and `ulimit -s`. No build was run by this seat.
