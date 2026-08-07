# `docs/hdl-tools/` — leg-2 (compiler seat) instruments

## `audit_completeness.py`

**Is every THEOREM in leg 2 covered by an `#audit_axioms` line?**

`#audit_axioms` is a *whitelist*: it bounds coverage from above and nothing
enforces that the list is complete. `SaltWorks/HDL/Sem.lean:131-139` recorded
that hole on 8/6 and asked for the check to live "in CI rather than in anyone's
memory". This is it.

Current result: **35 files, 360 theorems, every one audited.**

Exit `0` complete · `1` unaudited theorems found · `2` could not check. It prints
what it read (file and theorem counts), not only what it concluded.

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
