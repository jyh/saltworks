# `docs/hdl-tools/` — leg-2 (compiler seat) instruments

## `audit_completeness.py`

**Is every THEOREM in leg 2 covered by an `#audit_axioms` line?**

`#audit_axioms` is a *whitelist*: it bounds coverage from above and nothing
enforces that the list is complete. `SaltWorks/HDL/Sem.lean:131-139` recorded
that hole on 8/6 and asked for the check to live "in CI rather than in anyone's
memory". This is it.

**Run it — this README quotes no result, deliberately.** The line that used to
sit here said *"Current result: 35 files, 360 theorems, every one audited."*
⛔ **It was stale in its COUNT (HDL alone measures 404) and, far worse, in its
SCOPE — and nothing invalidates a number pasted into a doc.** A cached
measurement with no invalidation is a claim that rots quietly while reading as
current.

```
python3 docs/hdl-tools/audit_completeness.py              # whole repo (default)
python3 docs/hdl-tools/audit_completeness.py SaltWorks/HDL   # one directory
```

Exit `0` complete · `1` unaudited theorems found · `2` could not check.

⛔⛔ **THE DEFAULT SCOPE WAS THE TOOL'S OWN WORST BUG — found by math 8/7 19:02,
widened and fixed in `7de0cb8`.** The default root was `SaltWorks/HDL` *and* the
glob was non-recursive, so the tool read **404 of the repo's 1093 theorems** and
its verdict line said *"every theorem"*. Six of the seven directories holding
`.lean` files had never been audited; naming the parent `SaltWorks` read **zero**
files and exited 2.

🔑 **And the sentence that used to defend it here — "it prints what it read (file
and theorem counts)" — WAS THE BUG IN THE FIX'S CLOTHES. A COUNT IS NOT A
SCOPE:** `READ: 35 files` cannot distinguish *all of them* from *35 of 48*.
⇒ **Every line the tool prints now names its `ROOT`, lists the directories it
scanned, and both verdict lines carry `[ROOT=…, N files in D dirs, T theorems]`,
so the verdict cannot be quoted without its scope.**

📌 **A red from the default scope is not automatically a defect.** "Every theorem
carries an `#audit_axioms` line" is *this seat's* convention; most unaudited
theorems live in other seats' slots (`Silicon/Equiv`, `Banyan`, `Stack`).
Whether it binds them is the maestro's ruling — the tool measures, it does not
adjudicate.

⚠️ **Both sides read the comment-stripped body.** The first version matched the
raw source and so read prose inside docstrings as code — it reported 149
unaudited "theorems" with names like `is`, `goes` and `rather`. And an
`#audit_axioms` line *quoted* in a docstring is prose about auditing, not an
audit; there is a real one in `SaltWorks/Tactic/AuditAxioms.lean`, where the
tactic documents itself by quoting its own syntax. Mutation-tested for both.

## Model integrity — USE `../ledger-tools/model_integrity.py`

**There is no model checker here, deliberately.** This seat wrote one
(`session_model_check.py`) on the maestro's 8/7 15:09 downgrade finding, and
EVIDENCE landed `docs/ledger-tools/model_integrity.py` for the same question
minutes later — fleet-wide rather than project-scoped, with date handling, an
outside-lane refusal that **raises in code** rather than skipping silently, and
nine mutation checks wired into `selftest`.

Theirs is the fleet instrument (kit item 11) and strictly dominates. **Mine was
deleted rather than kept beside it**: a second copy is how two tools about one
question drift apart, which is the rule this seat gave MATH about `decode_zero`
two hours earlier and therefore owed itself.

*(For the record, both agreed: session `296f9c3c` stable on `claude-opus-5`
throughout.)*
