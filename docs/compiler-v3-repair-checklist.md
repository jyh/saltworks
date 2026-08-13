# COLD ROUND TWO — THE REPAIR CHECKLIST, EXTRACTED MECHANICALLY FROM THE VERDICT FILE

**Source: `docs/pi2-cold-verdicts-0813.json` (`dc7e66e`). Built by script, not by recall —
the helm's 12:44 order says round two is COLD, from the verdict file, and my memory of
what it said is precisely what must not drive it.**

**Overall verdict: REPAIR-THEN-FIRE. v2 DOES NOT FIRE.**

⛔ **NOTHING BELOW IS DONE.** *This file is the agenda, not the work. Each item is
checked off only against the verdict's own words, and the redesign gets its own fresh
cold pass before it is anything.*


## V1 — CONFIRMED-FATAL

**Question asked:** *(1a) v1 FATAL 1 — the population source named no instrument that exists. Does v2's shipped instrument actually answer it, and is v2's description of that instrument true at the bytes?*

**REPAIR REQUIRED, verbatim:**

> (1) Strike :60-61 and replace with what the code does: 'the record is written by a SECOND
> command in the same script; a crash or a log-write failure between them leaves a post on the
> bus with no record, and the population is then a subset.' (2) INVERT THE ORDER so the
> failure direction is visible: write an INTENT line to the log BEFORE the append and a
> completion mark after, so a crash yields a claimed send with no post — detectable as LOST —
> instead of a post with no claim, which nothing can detect. (3) Pin one canonical log path
> inside the script; refuse a $LOG that does not already exist rather than creating it. (4)
> Refuse if $BUS and $LOG are transposed (require the log to be the TSV, the bus the .md).


## V2 — CONFIRMED-REPAIRABLE

**Question asked:** *(1b) v1 FATAL 2 — the four outcomes were neither exhaustive nor exclusive. Are v2's outcomes a true partition, is the epistemic axis genuinely separated, and is NOT-FOUND actually restored?*

**REPAIR REQUIRED, verbatim:**

> Define LOST against NOT-FOUND explicitly (suggest: NOT-FOUND = the recorded offset does not
> resolve to a header; LOST = it resolves and the region is absent/empty) or mark it OPEN in
> the §1 table. Reconcile §3 with §5: state the identity as LISTED = PROCESSED = Σ(status
> buckets) + UNEXAMINED, so the epistemic axis is countable without being a status. Make the
> duplicate check conditional on a locked append (see Q2), or state that it cannot run under
> contention.


## V3 — CONFIRMED-REPAIRABLE

**Question asked:** *(1c) v1 FATAL 3 — the warrant was false. Is §0's correction honest, complete, and accurately sourced?*

**REPAIR REQUIRED, verbatim:**

> Change '66 seconds later' to 'inside ninety seconds, per the correcting post's own words
> (FLEET.md:85153)' — the seconds of the 08:27 post are not in the record. Add a §7 bullet:
> 'THE BASE RATE IS UNMEASURED. One real corruption in the whole record, self-found. Nothing
> here measures how often the detected event occurs, so no cost/benefit argument for mandating
> this method is available.'


## V4 — CONFIRMED-FATAL

**Question asked:** *(2) bus_send.sh at the bytes: is the send record written by the same act as the append, what happens on partial failure, and does it introduce a new corruption vector? Tested against a scratch bus with an [...]*

**REPAIR REQUIRED, verbatim:**

> (1) Assert the mutation: `diff "$SRC" "$SUBST"` must show ONLY stamp-token changes, and
> refuse if the source contains an @@STAMP@@ off the header line — or use a placeholder that
> cannot occur in prose. (2) Record the offset AFTER the append as `wc -c` minus the
> substituted length, or drop the leading `printf '\n'` and record the true header offset;
> either way spec and script must agree to the byte. (3) Define 'header' as a regex in §4 and
> record the region END offset too, so the region is bounded by two recorded facts and no scan
> is needed. (4) flock the bus across offset-capture + append + record. (5) `set -o pipefail`;
> refuse on an empty BODY_SHA. (6) Change exit 4's text to 'APPEND MAY HAVE PARTIALLY LANDED'.


## V5 — CONFIRMED-FATAL

**Question asked:** *(3) Are NC0–NC8 controls of the right form under rider 4 clause (i) — do they traverse the real pipeline — and is NC8 actually send-side?*

**REPAIR REQUIRED, verbatim:**

> Strike every ✅ in the §6 table until (1) a verifier is committed to docs/ledger-tools/ with
> its own sha recorded, (2) each control's inputs and outputs are committed as a receipt file,
> and (3) NC0 passes against the SHIPPED region rule and the SHIPPED instrument — today it
> does not. Re-declare NC8's substitutions as four, not one. Add NC9: a body containing a
> literal @@STAMP@@ as content must not be silently rewritten. Add NC10: two concurrent sends
> must not record the same offset.


## V6 — CONFIRMED-REPAIRABLE

**Question asked:** *(4) Is each §7 humility claim stated accurately — neither over- nor under-claimed?*

**REPAIR REQUIRED, verbatim:**

> Rewrite bullet 2: 'the send log records an offset captured BEFORE the append, so under
> concurrent writers it can be stale or point into another post; interleaving then presents as
> CORRUPTED and is not distinguishable from real corruption. Until the append is locked, this
> is a known false-positive source.' Replace bullet 3 with: 'it covers ONLY posts sent through
> bus_send.sh. Today that is zero posts; the entire existing bus is outside the population and
> always will be. Nothing prevents a seat from appending directly.' Add bullets for
> remediation, the mutating stage, and the base rate.


## V7 — CONFIRMED-FATAL

**Question asked:** *(5) What does v2 newly introduce that v1 did not have — new single points of failure, new corruption vectors, new undefined terms?*

**REPAIR REQUIRED, verbatim:**

> Add a §8 'WHAT v2 INTRODUCES THAT v1 DID NOT' listing the mutating writer, the short-log
> failure, and the unpinned log path. Carry v1:52-55 forward verbatim as the send-side rule
> for anyone not using the tool. Either give the DRAFT population an instrument or delete it
> and say drafts are unenumerable under this method. Define LOST.


## UNASSIGNED KILLS — carried, none of them yet answered

- [ ] DO NOT RUN bus_send.sh AGAINST FLEET.md UNTIL THE SUBSTITUTION IS FIXED. Its first real use on a post about this method silently rewrites that [...]
- [ ] NO REMEDIATION CLAUSE ANYWHERE IN v2, and v1's kill on this was never assigned either. Nothing states what an auditor DOES on CORRUPTED. There [...]
- [ ] THE SPEC AND THE INSTRUMENT DO NOT COMPOSE UNDER ANY READING, AND NOBODY RAN THEM TOGETHER. §4:108's region rule applied to bus_send.sh's own [...]
- [ ] THE INSTRUMENT HAS NO DRY-RUN AND NO ARGUMENT-SHAPE GUARD. bus_send.sh:40 checks only that $BUS exists. Transposing args 2 and 3 appends a post [...]
- [ ] THE SEND-LOG STAMP CARRIES NO YEAR AND NO TIMEZONE (bus_send.sh:42, `+%m/%d %H:%M:%S`). The log is the population and its human-readable key is [...]
- [ ] v2 IS NOT SELF-DESCRIBING ABOUT ITS OWN RECEIPTS. §6's table has a column headed 'run 2026-08-13' with nine ✅ and one parenthetical '(run [...]
- [ ] GOOD FAITH NOTED, AND IT MATTERS FOR THE DISPOSITION: this is a genuine cold redesign, not a rename. §0's warrant correction is accurate against [...]

---

**7 verdicts · 7 unassigned kills.**

⚖️ **AND THE QUESTION ROUND TWO MUST NOT ASSUME PAST, stated before any repair is
attempted so the answer cannot be steered by the work already invested:
SHOULD THERE BE A v3 AT ALL?** *The method has never fired on a live corruption; when it
finally met one it PASSED it; the base rate is unmeasured; there is no remediation clause.
'Publish whatever dominates' permits the answer being a documented negative. The author is
the wrong seat to settle that quickly in either direction — including the flattering one,
which here is 'keep building'.*
