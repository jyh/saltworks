#!/usr/bin/env python3
"""
# prose_rot: ignore-start  (this docstring quotes both directions verbatim)
prose_rot.py — the staleness sweep, WITH THE HALF IT CANNOT SEE PRINTED.

    python3 docs/ledger-tools/prose_rot.py <file|dir> [...]
    python3 docs/ledger-tools/prose_rot.py --selftest

EVIDENCE seat, 2026-08-10 18:1x. Built because the sweep it mechanises had been
living in this seat's MEMORY as a grep one-liner since 08:0x, and an ad-hoc
one-liner is the exact shape of every case-sensitivity error this seat has made
(four, all of them hand-typed at the prompt, none of them in a committed tool).

⛔ THE THING THIS TOOL EXISTS TO SAY OUT LOUD -----------------------------------

Staleness has TWO directions. This tool measures ONE of them.

  (A) THE ABSENCE GOING FALSE      "emitSeq does not exist" -> it landed 12h ago
      COVERED HERE                 Announces its own tense. A regex finds it.

  (B) THE ASSERTION GOING FALSE    "c > 0 (with c = c_1^8)" -> the corpus now
      *** NOT COVERED ***          carries per-row floors 17/3, 50/49, 850/133
                                   Contains NO tense marker and NO sweep word.
                                   UNGREPPABLE. No regex will ever find it.

Direction (B) was found by the math seat at 18:04 on a week-cold paper, twenty
minutes after this seat published the (A) sweep as if it were "the" staleness
check. (B) is the WORSE direction: a stale absence under-claims and costs a
reader nothing, while a stale assertion is a false statement WITH A NUMBER IN IT,
and a reader who trusts it carries it onward. Only (B) propagates.

So this tool does two different things, and never confuses them:
  * for (A) it gives a VERDICT      — findings, with line numbers, exit 1
  * for (B) it gives a WORK LIST    — every asserted number/exponent/count it can
                                     see, flagged NOT CHECKED, because the only
                                     instrument for (B) is re-derivation against
                                     the live corpus and this tool has no corpus.

A green from this tool means "no stale ABSENCE claims". It NEVER means clean.

⚖️ DATEDNESS IS THE RANKING AXIS, and that is a CORRECTION this file's own
selftest forced. The first version ranked by NORMATIVITY and scored a bare
"EMITSEQ DOES NOT EXIST" as safe narrative because it contains no normative
keyword — while that is precisely the sentence a successor obeys, and precisely
the shape of this seat's own stale F3 scope. A DATE is what makes an absence
claim harmless (it records a moment). A normative word only makes an undated one
worse. So: rank 0 = undated + normative · rank 1 = undated · rank 2 = dated.
Only ranks 0 and 1 set the exit code; dated narrative is never a defect.

EXIT 0 = no stale-absence findings · 1 = findings · 2 = could not run
# prose_rot: ignore-end
"""
import re
import sys
import pathlib

# ---- direction (A): claims that ANNOUNCE THEIR TENSE ------------------------
# Case-INSENSITIVE by construction: four of this seat's errors were a
# case-sensitive grep returning a confident zero over a populated object.
# prose_rot: ignore-start  (the pattern table IS the description)
ABSENCE = [
    r"lacks?\b", r"\babsent\b", r"\bmissing\b", r"does\s+not\s+exist",
    r"\bno\s+theorem\b", r"\bhas\s+no\b", r"nothing\s+(?:in|ties|proves)\b",
    r"\bunproved\b", r"\bnot\s+yet\b", r"\bdoes\s+not\s+(?:cover|carry|hold)\b",
    r"\bis\s+not\s+(?:proved|proven|verified|emitted|implemented)\b",
    r"\bno\s+(?:instrument|artifact|proof|kernel|control)\b",
    r"\bstill\s+(?:absent|missing|owed|open)\b", r"\bawait(?:s|ing)\b",
    r"\bTODO\b", r"\bnobody\s+has\b", r"\bcannot\s+be\s+(?:run|checked|measured)\b",
]
# prose_rot: ignore-end
ABSENCE_RE = re.compile("|".join(ABSENCE), re.I)

# ---- normative markers: a stale absence HERE gets obeyed --------------------
NORMATIVE = re.compile(
    r"\b(scope|criterion|criteria|bar|rule|law|must|shall|never|always|"
    r"required|forbidden|banned|acceptance|gate|order|standing|policy|"
    r"do\s+not|refuse)\b", re.I)

# a dated line is narrative: it records a moment, not a standing instruction
DATED = re.compile(r"\b(20\d\d-\d\d-\d\d|\d\d?/\d\d?\s+\d\d?:\d\d|"
                   r"\b\d\d?:\d\dx?\b|yesterday|tonight|this\s+(?:morning|evening))", re.I)

# ---- direction (B): the enumerable target list ------------------------------
# NOT a verdict. These are the things a human must re-derive against the corpus.
#
# ⛔ THIS BLOCK'S FIRST VERSION COULD NOT ENUMERATE `c = c_1^8` — the exact
# example cited in this file's own docstring as the canonical (B) target. Two
# causes, both caught by the selftest below and neither by reading:
#   * the superscript pattern required a DIGIT before `^`, so the identifier
#     form `c_1^8` was invisible (the `_` also killed the lookbehind);
#   * bare single-digit exponents ("the exponent is 8") were excluded by a
#     \d{2,} floor added to keep noise down.
# The instrument exhibited its own class: a (B)-hunter blind to (B)'s specimen.
ASSERTED_NUM = re.compile(
    r"("
    r"(?<![\w.])\d+\s*/\s*\d+(?![\w.])"      # 17/3, 850/133 — Holder floors
    r"|[A-Za-z][\w]*\s*\^\s*\{?\d+\}?"       # c_1^8, x^{12} — IDENTIFIER base
    r"|(?<![\w.])\d+\s*\^\s*\{?\d+\}?"       # 2^8
    r"|(?<![\w.])\d+\.\d+(?![\w.])"          # 86.2267
    r"|(?<![\w.])\d{2,}(?![\w.])"            # 902, 289, 352
    r")")
# single digits are enumerated ONLY where the line already reads as a claim —
# otherwise every "2 arms" in narrative floods the work list into uselessness.
BARE_DIGIT = re.compile(r"(?<![\w.^_/])\d(?![\w.])")
SHAPE_WORD = re.compile(
    r"\b(exactly|precisely|all\s+\d+|every\s+\w+|uniform|identical|"
    r"the\s+only|equals?|==)\b", re.I)


# ---- the CARRIER gate ------------------------------------------------------
# prose_rot: ignore-start  (this comment quotes the specimen it gates)
# ⛔ FIRST RUN AGAINST ITS OWN SOURCE: 10 findings, ALL OF THEM THIS FILE
# DESCRIBING ITS OWN PATTERNS — the pattern table, the docstring's worked
# example, the selftest fixtures. Seventh instance of the carrier class in this
# seat's bank: the doc explaining a hazard makes the detector fire on the
# explanation. No regex separates "emitSeq does not exist" ASSERTED from the
# same bytes QUOTED AS AN EXAMPLE — they are byte-identical.
#
# So the gate is STRUCTURAL and AUTHOR-DECLARED, never inferred: a region marked
# with the markers below is description, not assertion. And per this seat's
# frame law, THE EXCLUSION IS PRINTED — a miss announces itself, an exclusion
# never does unless you make it.
# prose_rot: ignore-end
IGNORE_START = "prose_rot: ignore-start"
IGNORE_END = "prose_rot: ignore-end"


# prose_rot: ignore-start
# ⛔ A DATE IN THE FILENAME IS STILL A DATE, and missing that ranked four
# EVIDENCE-ledger-2026-08-0N.md files as carrying live normative scopes. A
# dated artifact is a SNAPSHOT: every line in it records what was true then,
# which is exactly what this tool's ranking law says is harmless. My DATED
# regex assumed the date sits in the LINE; in this corpus it very often sits in
# the NAME. Third instance tonight of an instrument's SHAPE being an assumption
# about the document's shape — and the countermeasure I published an hour ago
# (attack your own denominator with a looser method) is what found it, applied
# BEFORE publishing this time rather than after.
DATED_NAME = re.compile(r"(20\d\d-\d\d-\d\d|-\d{4}(?:\.|$|-))")
# prose_rot: ignore-end


def sweep_text(text, path):
    findings, targets = [], []
    excluded = 0
    skipping = False
    for n, raw in enumerate(text.splitlines(), 1):
        if IGNORE_START in raw:
            skipping = True
        if skipping:
            excluded += 1
            if IGNORE_END in raw:
                skipping = False
            continue
        line = raw.strip()
        if not line:
            continue
        # comment/prose both count: a stale scope in a code comment is obeyed too
        hit = ABSENCE_RE.search(line)
        if hit:
            dated = bool(DATED.search(line)) or bool(DATED_NAME.search(
                pathlib.PurePath(path).name))
            norm = bool(NORMATIVE.search(line))
            # prose_rot: ignore-start  (quotes the fixture it explains)
            # ⚖️ DATEDNESS IS THE PRIMARY AXIS, not normativity — corrected after
            # the selftest failed on a bare uppercase "EMITSEQ DOES NOT EXIST".
            # That line carries no normative KEYWORD and is still exactly the
            # sentence a successor obeys; my own stale F3 scope was this shape.
            # A date is what makes an absence claim safe (it records a moment);
            # a normative word only makes an undated one WORSE.
            # prose_rot: ignore-end
            rank = 2 if dated else (0 if norm else 1)
            findings.append((rank, path, n, hit.group(0), line[:110], dated, norm))
        claimish = bool(SHAPE_WORD.search(line)) or "=" in line
        if claimish:
            seen = set()
            for m in ASSERTED_NUM.finditer(line):
                if m.group(0) not in seen:
                    seen.add(m.group(0))
                    targets.append((path, n, m.group(0), line[:90]))
            for m in BARE_DIGIT.finditer(line):
                if m.group(0) not in seen:
                    seen.add(m.group(0))
                    targets.append((path, n, m.group(0), line[:90]))
    if skipping:
        # an unterminated region would silently swallow the file's whole tail
        raise ValueError(f"{path}: {IGNORE_START} never closed — refusing to "
                         f"report over a scope that silently ends at EOF")
    return findings, targets, excluded


def collect(paths):
    files = []
    for p in paths:
        pp = pathlib.Path(p)
        if pp.is_dir():
            files += [f for f in sorted(pp.rglob("*"))
                      if f.suffix in (".md", ".py", ".sh", ".lean", ".tex", ".v")]
        elif pp.is_file():
            files.append(pp)
        else:
            print(f"prose_rot: no such path: {p}", file=sys.stderr)
            sys.exit(2)
    return files


def main(argv):
    quiet = "--quiet" in argv
    argv = [a for a in argv if a != "--quiet"]
    if not argv:
        print(__doc__.split("EXIT")[0])
        sys.exit(2)
    files = collect(argv)
    if not files:
        print("prose_rot: matched zero files — refusing to report a green over "
              "an empty scope (see: a count is not a scope)", file=sys.stderr)
        sys.exit(2)

    allf, allt, excl = [], [], 0
    for f in files:
        try:
            t = f.read_text(errors="replace")
        except OSError as e:
            print(f"prose_rot: unreadable {f}: {e}", file=sys.stderr)
            sys.exit(2)
        try:
            a, b, ex = sweep_text(t, str(f))
        except ValueError as e:
            print(f"prose_rot: {e}", file=sys.stderr)
            sys.exit(2)
        allf += a
        allt += b
        excl += ex
    allf.sort(key=lambda r: (r[0], r[1], r[2]))

    print("=" * 74)
    print("PROSE ROT — DIRECTION (A) ONLY. Read the scope line before the verdict.")
    print("=" * 74)
    print(f"SCOPE      {len(files)} file(s), {sum(1 for _ in files)} scanned, "
          f"all suffixes .md/.py/.sh/.lean/.tex/.v")
    print(f"COVERS     (A) absence claims that ANNOUNCE THEIR TENSE — "
          f"{len(ABSENCE)} patterns, case-insensitive")
    print(f"EXCLUDED   {excl} line(s) inside author-declared `{IGNORE_START}` "
          f"regions —")
    print("           description-of-the-pattern, not assertion. A MISS PRINTS")
    print("           ITSELF; AN EXCLUSION DOES NOT, so it is printed here.")
    print("DOES NOT   (B) a POSITIVE assertion the corpus made false. It carries")
    print("COVER      no tense marker and no keyword. UNGREPPABLE BY DESIGN.")
    print("           math seat, 08/10 18:04: 'c = c_1^8' was false and clean here.")

    norm = [f for f in allf if f[0] <= 1]
    print("-" * 74)
    if allf and not quiet:
        for rank, path, n, tok, line, dated, isnorm in allf:
            tag = ("⛔ UNDATED+NORMATIVE" if rank == 0 else
                   "⚠️  UNDATED" if rank == 1 else "·  dated narrative")
            print(f"{tag:<20} {path}:{n}")
            print(f"     matched {tok!r}: {line}")
    elif quiet:
        # ⚖️ IN A REPORT, ONLY RANK 0 GETS A LINE. Rank 1 (undated but carrying
        # no normative word) is real and worth a count, but 700 lines of it in a
        # nightly ledger is the pasted-build-log defect this seat diagnosed on
        # the bus the same hour. A report that buries its findings has none.
        r1 = 0
        for rank, path, n, tok, line, dated, isnorm in allf:
            if rank == 0:
                print(f"  ⛔ UNDATED+NORMATIVE  {path}:{n}  {tok!r}")
            elif rank == 1:
                r1 += 1
        if r1:
            print(f"  ⚠️  {r1} further UNDATED absence claim(s) carrying no "
                  f"normative word — counted, not listed.")
            print("      Re-run without --quiet to see them.")
    else:
        print("no (A) findings.")
    print("-" * 74)
    print(f"(A) FINDINGS   {len(allf)}   of which UNDATED: {len(norm)}"
          f"  (normative subset: {sum(1 for f in allf if f[0]==0)})")
    print("               ^ these are the ones a successor OBEYS. Dated narrative")
    print("                 is not a defect; it records what was true then.")

    print()
    print("=" * 74)
    print("(B) WORK LIST — NOT CHECKED, NOT A VERDICT, NOT SUMMED WITH THE ABOVE")
    print("=" * 74)
    # prose_rot: ignore-start  (the output text names the tool's own limits)
    print(f"{len(allt)} asserted number(s) found in claim-shaped lines. This tool")
    print("has NO corpus and CANNOT verify one of them. Each needs re-derivation")
    print("against the live source of truth — that is the only instrument for (B).")
    for path, n, num, line in ([] if quiet else allt[:25]):
        print(f"  ? {path}:{n}  [{num}]  {line}")
    if quiet:
        print("  (list suppressed by --quiet; re-run per file to see it)")
    elif len(allt) > 25:
        print(f"  … {len(allt) - 25} more (full list is the point; re-run per file)")

    # prose_rot: ignore-end
    print()
    print("⚖️  A GREEN HERE MEANS 'NO STALE ABSENCE CLAIMS'. IT DOES NOT MEAN CLEAN.")
    sys.exit(1 if norm else 0)


# prose_rot: ignore-start  (fixtures are quoted specimens, not claims)
def selftest():
    """Positive controls, mutation-verified: each fixture must be CAUGHT."""
    ok = True
    cases = [
        ("emitSeq does not exist and must never be assumed",  True,  "undated normative"),
        ("On 2026-08-09 emitSeq did not exist yet",           False, "dated narrative"),
        ("EMITSEQ DOES NOT EXIST",                            True,  "uppercase (the case class)"),
        ("the scope lacks a clocked cell",                    True,  "lacks + scope"),
        ("everything is fine here",                           False, "clean line"),
    ]
    for text, want_norm, why in cases:
        f, _, _ = sweep_text(text, "fixture")
        # "dangerous" == UNDATED (rank 0 or 1); dated narrative (rank 2) is safe
        got = any(r[0] <= 1 for r in f)
        status = "ok " if got == want_norm else "FAIL"
        if got != want_norm:
            ok = False
        print(f"  {status} undated={got!s:<5} want={want_norm!s:<5} {why}")
    # (B) enumerated, never verdicted
    _, t, _ = sweep_text("the exponent is exactly 8 and c = c_1^8", "fixture")
    print(f"  {'ok ' if t else 'FAIL'} (B) work list enumerated {len(t)} target(s), "
          f"contributes ZERO to the exit code")
    if not t:
        ok = False
    # the critical negative: a (B)-only defect must NOT raise an (A) finding
    f2, t2, _ = sweep_text("Thm 3.3: c > 0 with c = c_1^8 for an explicit c_1", "fixture")
    a_clean = not f2
    print(f"  {'ok ' if a_clean else 'FAIL'} math's real (B) defect is INVISIBLE to "
          f"(A) — {len(f2)} absence finding(s), as documented, not as a bug")
    if not a_clean:
        ok = False
    print("SELFTEST", "PASS" if ok else "FAIL")
    sys.exit(0 if ok else 1)
# prose_rot: ignore-end


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--selftest":
        selftest()
    main(sys.argv[1:])
