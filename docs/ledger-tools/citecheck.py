#!/usr/bin/env python3
"""citecheck — verify that `path:line` citations in prose still point at what they claim.

BORN 2026-08-12 at the compiler seat, from a measured rate: four wrong locators from
one seat in one evening (three inherited from a predecessor's doc, one my own, in the
document proposing this tool).

THE RULING THAT DECIDES THE DESIGN (evidence, 2026-08-12 18:44):
    VERIFY CONTENT AT THE ADDRESS, NEVER THE EXISTENCE OF THE ADDRESS.
    `ISA.lean:803` is a REAL LINE carrying different text; an existence-checker
    returns GREEN on it. So does `ctrl32.v:26`. Two of that evening's three
    inherited defects are INVISIBLE to a file-and-line-exists check.

WHY THIS CLASS ROTS SILENTLY: a doc citing a moved line builds green forever,
because docs do not build at all. Same law as a docstring citing a renamed theorem.

VERDICTS — three, and the third is the point:
    OK           the citation's payload was found at the cited line.
    MISS         the payload is in the file but NOT at the cited line. A MISS that
                 reports "MOVED by ±N" is a REPAIR INSTRUCTION, not a complaint.
    UNCHECKED    anything outside this instrument's domain: no extractable payload,
                 a payload too generic to convict, a prose citation that never
                 quoted the file, an ambiguous path, or a path not found in any
                 root we were GIVEN. ***PRINTED, NEVER COUNTED AS OK.***

An UNCHECKED row is an instrument limit, not a pass. A tool that silently drops what
it cannot read reports N-1 greens as N — which is the defect this fleet spent the
evening on, one layer up.

⛔ AND THE LIMIT CUTS BOTH WAYS — evidence, at corpus scale, 2026-08-12 19:00:
an unresolvable path is UNCHECKED, NEVER a MISS. 20 of their 230 MISSes were paths
resolving perfectly in a SIBLING REPO. Convicting a citation because this tool was
pointed at the wrong root is the same defect as passing a figure it cannot read,
run in the opposite direction. Pass --also-root to widen the domain; without it,
the tool declines to convict rather than guessing.

REPORT, NEVER REWRITE. This tool does not edit a single byte of any doc.
"""
import argparse
import os
import re
import sys

# A locator: an optional dir-ish prefix, a filename with an extension, then :LINE.
# Bounded on the left so "…and the count is 352:1" style prose does not match.
LOCATOR = re.compile(
    r"(?<![\w/.])((?:[\w.\-]+/)*[\w.\-]+\.(?:lean|v|py|md|sh|mmd|svg|tsv|toml|json))"
    r":(\d+)(?!\d)"
)

# A payload we can actually verify: a backticked span, or a bare identifier-ish token
# (theorem/wire/def names) of reasonable length.
BACKTICKED = re.compile(r"`([^`\n]{2,120})`")
IDENTIFIER = re.compile(r"\b([A-Za-z_][A-Za-z0-9_']{4,}(?:\.[A-Za-z_][A-Za-z0-9_']+)*)\b")

# Tokens too generic to be evidence that a line is the right line.
STOPWORDS = {
    "theorem", "lemma", "assign", "module", "input", "output", "which", "there",
    "where", "these", "those", "their", "should", "would", "could", "about",
    "requires", "require", "carries", "carry", "states", "state", "value",
    "false", "true", "return", "returns", "line", "lines", "count", "counts",
    "actual", "actually", "wrong", "right", "check", "checks", "verify",
    "python", "import", "define", "defines", "definition", "claims", "claim",
}


def repo_root(start):
    d = os.path.abspath(start)
    while d != "/":
        if os.path.isdir(os.path.join(d, ".git")):
            return d
        d = os.path.dirname(d)
    return os.path.abspath(start)


def build_index(root):
    """Map basename -> [relative paths]. Skips .git and build dirs."""
    index = {}
    skip = {".git", ".lake", "__pycache__", "node_modules", ".venv"}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in skip]
        for fn in filenames:
            full = os.path.join(dirpath, fn)
            index.setdefault(fn, []).append(os.path.relpath(full, root))
    return index


def resolve(cited, root, index):
    """Resolve a cited path to real paths within ONE root. Returns (paths, how)."""
    direct = os.path.join(root, cited)
    if os.path.isfile(direct):
        return [cited], "direct"
    base = os.path.basename(cited)
    cands = index.get(base, [])
    if cited != base:
        # cited carries directories: keep only paths whose tail matches.
        cands = [p for p in cands if p.endswith(cited)]
    return cands, "suffix"


def resolve_across(cited, roots):
    """Resolve against the primary root first, then any --also-root.

    ⛔ OUTSIDE MY ROOT IS AN INSTRUMENT LIMIT, NOT A WRONG CITATION — evidence's
    finding at corpus scale (2026-08-12 19:00, 148 docs / 543 locators): 20 MISSes
    were paths resolving PERFECTLY in a sibling repo. Convicting them is the same
    error as counting an unreadable figure as clean, run in the opposite direction —
    the instrument's DOMAIN has to sit inside the verdict either way.

    So: a path that resolves nowhere we were TOLD to look is UNCHECKED, never MISS.
    Only a path absent from every known root is a genuine dangling citation.
    """
    for (rname, rpath, rindex) in roots:
        paths, how = resolve(cited, rpath, rindex)
        if paths:
            return rname, rpath, paths, how
    return None, None, [], "unresolved"


def read_line(root, relpath, lineno):
    try:
        with open(os.path.join(root, relpath), encoding="utf-8", errors="replace") as fh:
            for i, line in enumerate(fh, 1):
                if i == lineno:
                    return line.rstrip("\n")
    except OSError:
        return None
    return None


def file_contains_any(root, relpath, tokens):
    """Does any token appear ANYWHERE in the file? Distinguishes a MOVED line from a
    citation that never quoted the file at all."""
    try:
        with open(os.path.join(root, relpath), encoding="utf-8", errors="replace") as fh:
            blob = fh.read()
    except OSError:
        return False
    return any(t in blob for t in tokens)


def is_strong(tok):
    """Is this payload distinctive enough that finding it elsewhere PROVES a move?

    Weak payloads (`none`, `true`, short words) occur on hundreds of lines; a hit on
    one is not evidence of anything. Only a distinctive token may convict a citation.
    """
    if len(tok) < 6:
        return False
    if " " in tok:            # a multi-word quoted span is distinctive
        return True
    return "_" in tok or "." in tok or bool(re.search(r"[a-z][A-Z]", tok))


def payload_candidates(context, cited=""):
    """Extract verifiable payloads from the text around a citation.

    ⛔ THE CITED PATH IS NOT A PAYLOAD — measured 2026-08-12 on this tool's own
    negative control. `dmem_addr8.v:80` yielded the token `dmem_addr8`, which of
    course recurs at `module dmem_addr8 (` two lines up, so the tool declared a
    confident "MOVED by -2" against a citation that was CORRECT. A file's own name
    is evidence about the FILE, never about a LINE within it.
    """
    stem = os.path.basename(cited)
    stem_bare = stem.split(".")[0] if stem else ""

    def self_referential(tok):
        if not stem_bare:
            return False
        return tok == stem_bare or tok in stem or stem_bare in tok

    out = []
    for m in BACKTICKED.finditer(context):
        tok = m.group(1).strip()
        if len(tok) >= 3 and tok.lower() not in STOPWORDS and not self_referential(tok):
            out.append(tok)
    for m in IDENTIFIER.finditer(context):
        tok = m.group(1)
        if tok.lower() in STOPWORDS:
            continue
        # require it to look like code: underscore, camelCase, or a dot
        if self_referential(tok):
            continue
        if "_" in tok or "." in tok or re.search(r"[a-z][A-Z]", tok):
            out.append(tok)
    seen, uniq = set(), []
    for t in out:
        if t not in seen:
            seen.add(t)
            uniq.append(t)
    return uniq


def context_for(text, start, end, before, after, next_start=None):
    """Text around a citation, TRUNCATED AT THE NEXT CITATION.

    ⛔ THE BUG THIS EXISTS TO KILL — measured 2026-08-12 on this tool's own positive
    control, before it shipped. With a plain N-lines-after window, a citation's payload
    bled in from the FOLLOWING citation: `ctrl32.v:26` (cited for `is_load`) picked up
    `is_store` from the next row and matched it against line 26 — reporting **OK on a
    known defect.** An instrument that green-lights the exact class it was built to
    catch is worse than no instrument, and only a fixture with known ground truth
    could show it.
    """
    ls = text.rfind("\n", 0, start) + 1
    lines = text[:ls].count("\n")
    all_lines = text.split("\n")
    lo = max(0, lines - before)
    hi = min(len(all_lines), lines + after + 1)
    if next_start is not None:
        # never read past the start of the next citation's own line
        nls = text.rfind("\n", 0, next_start) + 1
        nline = text[:nls].count("\n")
        hi = min(hi, max(nline, lines + 1))
    return "\n".join(all_lines[lo:hi])


def check_doc(docpath, roots, window, before, after):
    with open(docpath, encoding="utf-8", errors="replace") as fh:
        text = fh.read()
    rows = []
    matches = list(LOCATOR.finditer(text))
    for idx, m in enumerate(matches):
        next_start = matches[idx + 1].start() if idx + 1 < len(matches) else None
        cited, lineno = m.group(1), int(m.group(2))
        docline = text[: m.start()].count("\n") + 1
        rname, rpath, paths, _how = resolve_across(cited, roots)
        if not paths:
            # UNCHECKED, not MISS: we can only speak for the roots we were given.
            rows.append(("UNCHECKED", docline, cited, lineno,
                         "path not found in %d known root(s) — may live in another "
                         "repo; pass --also-root to check it" % len(roots), ""))
            continue
        if len(paths) > 1:
            rows.append(("UNCHECKED", docline, cited, lineno,
                         "path is AMBIGUOUS (%d matches in %s); not guessing"
                         % (len(paths), rname), ""))
            continue
        rel = paths[0]
        root = rpath
        target = read_line(root, rel, lineno)
        if target is None:
            rows.append(("MISS", docline, cited, lineno,
                         "file has fewer than %d lines" % lineno, rel))
            continue
        ctx = context_for(text, m.start(), m.end(), before, after, next_start)
        cands = payload_candidates(ctx, cited)
        if not cands:
            rows.append(("UNCHECKED", docline, cited, lineno,
                         "no extractable payload beside the locator", rel))
            continue
        # A match AT the cited line settles it, strong payload or weak.
        hit = next((c for c in cands if c in target), None)
        if hit:
            rows.append(("OK", docline, cited, lineno, "payload %r at line" % hit, rel))
            continue
        # ⛔ ONLY A DISTINCTIVE PAYLOAD MAY CONVICT. A generic token (`none`, `true`)
        # occurs on hundreds of lines, so finding one elsewhere is not evidence the
        # citation MOVED — it is evidence the instrument cannot read this citation.
        # Measured on this tool's own negative control: `none` matched 5 lines away
        # and produced a confident false "MOVED" against a locator verified by hand.
        strong = [c for c in cands if is_strong(c)]
        if not strong:
            rows.append(("UNCHECKED", docline, cited, lineno,
                         "payload too generic to verify (%s)"
                         % ", ".join(repr(c) for c in cands[:3]), rel))
            continue
        near = None
        for off in range(1, window + 1):
            for delta in (-off, off):
                probe = read_line(root, rel, lineno + delta)
                if probe and any(c in probe for c in strong):
                    near = lineno + delta
                    break
            if near:
                break
        if near:
            rows.append(("MISS", docline, cited, lineno,
                         "payload found at line %d, not %d (MOVED by %+d)"
                         % (near, lineno, near - lineno), rel))
            continue
        # ⛔ ABSENT-FROM-THE-WHOLE-FILE IS "CANNOT VERIFY", NOT "WRONG" — measured
        # 2026-08-12 on the negative control. `dmem_addr8.v:80` is cited for a PROSE
        # claim ("takes ONE access strobe"), not a quotation, so its payload was never
        # going to appear in that file. Calling that a MISS convicts a CORRECT citation
        # (line 80 is `input wire req,`, verified by hand). A checker that cries wolf on
        # prose citations gets switched off, and then it protects nothing.
        if not file_contains_any(root, rel, strong):
            rows.append(("UNCHECKED", docline, cited, lineno,
                         "payload absent from the whole file — citation is prose, "
                         "not a quotation; cannot verify", rel))
        else:
            rows.append(("MISS", docline, cited, lineno,
                         "payload occurs in the file but not within %d lines of %d"
                         % (window, lineno), rel))
    return rows


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("docs", nargs="+", help="markdown/text files whose citations to check")
    ap.add_argument("--root", default=None, help="repo root (default: git root of first doc)")
    ap.add_argument("--also-root", action="append", default=[],
                    help="additional repo root(s) to resolve citations against; "
                         "repeatable. Without these, an unresolvable path is "
                         "UNCHECKED, never MISS.")
    ap.add_argument("--window", type=int, default=40,
                    help="how far to search for a MOVED payload (default 40)")
    ap.add_argument("--before", type=int, default=0,
                    help="context lines before the locator to mine for payload")
    ap.add_argument("--after", type=int, default=2,
                    help="context lines after the locator to mine for payload")
    ap.add_argument("--quiet-ok", action="store_true", help="print only MISS and UNCHECKED")
    args = ap.parse_args()

    primary = args.root or repo_root(os.path.dirname(os.path.abspath(args.docs[0])))
    roots = [(os.path.basename(os.path.abspath(primary)), os.path.abspath(primary),
              build_index(primary))]
    for extra in args.also_root or []:
        ap_ = os.path.abspath(extra)
        roots.append((os.path.basename(ap_), ap_, build_index(ap_)))
    root = roots[0][1]

    totals = {"OK": 0, "MISS": 0, "UNCHECKED": 0}
    for doc in args.docs:
        rows = check_doc(doc, roots, args.window, args.before, args.after)
        if not rows:
            print("%s: no citations parsed" % doc)
            continue
        print("== %s" % os.path.relpath(os.path.abspath(doc), root))
        for verdict, docline, cited, lineno, why, rel in rows:
            totals[verdict] += 1
            if args.quiet_ok and verdict == "OK":
                continue
            mark = {"OK": "  ok  ", "MISS": "⛔MISS", "UNCHECKED": "  ??  "}[verdict]
            print("  %s doc:%-5d %s:%-6d %s" % (mark, docline, cited, lineno, why))

    n = sum(totals.values())
    print("\ncitecheck: %d citation(s) — %d OK · %d MISS · %d UNCHECKED"
          % (n, totals["OK"], totals["MISS"], totals["UNCHECKED"]))
    if totals["UNCHECKED"]:
        print("⚠️  UNCHECKED rows are an INSTRUMENT LIMIT, NOT A PASS. "
              "%d citation(s) were not verified." % totals["UNCHECKED"])
    # Exit 1 on any MISS so this can gate; UNCHECKED alone does not fail the run,
    # but it is printed above so it can never read as clean.
    return 1 if totals["MISS"] else 0


if __name__ == "__main__":
    sys.exit(main())
