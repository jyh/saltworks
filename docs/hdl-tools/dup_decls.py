#!/usr/bin/env python3
"""Duplicate-declaration detector for the SaltWorks corpus.

WHY THIS EXISTS (2026-08-08).  `SeamJoinA` and `SeamJoinC` both declared
`SaltWorks.HDL.bnCFrameAt_length` -- same namespace, identical statement AND
proof, neither importing the other, and `SaltWorks.lean` imported both.

  * Lean accepts that SILENTLY: corpus EXIT=0, no warning, no error.
  * The environment keeps the FIRST-imported copy (math, measured, 3 runs), and
    it FLIPS if the two import lines are swapped.

=> While a duplicate exists, the LINE ORDER of `SaltWorks.lean` is semantically
load-bearing: an alphabetise in a maestro-owned file silently swaps which proof
downstream code sees.  A green build is not evidence against any of this.

Two seats hand-checked for collisions the same night and both said so with a
clock on it.  A measurement expires; this is the property, asserted.

    python3 docs/hdl-tools/dup_decls.py                  # tracked SaltWorks/**.lean
    python3 docs/hdl-tools/dup_decls.py FILE [FILE ...]  # explicit set (testable)

Exit 0 = no duplicates.  Exit 1 = duplicates found.  Exit 2 = refused to answer.

## ⛔ WHAT THIS IS NOT

A regex parser, not Lean.  It sees `namespace`/`end` nesting and declaration
keywords; it does NOT see `open`, `export`, macro-generated declarations, or
`section` variables.  It can therefore MISS a duplicate (never invent one) --
so a clean report is evidence, not proof.  It REFUSES (exit 2) rather than
guess when namespace nesting does not balance, because an unbalanced file makes
every name after it wrong.
"""
import re, sys, os, subprocess, collections

DECL = re.compile(
    r'^\s*(?:@\[[^\]]*\]\s*)*'
    r'(?:private\s+|protected\s+|noncomputable\s+|partial\s+|unsafe\s+)*'
    r'(theorem|lemma|def|abbrev|instance|structure|inductive)\s+'
    r'([A-Za-z_][A-Za-z0-9_.\'!?]*)')
NS_OPEN = re.compile(r'^\s*namespace\s+([A-Za-z_][A-Za-z0-9_.\']*)')
NS_END = re.compile(r'^\s*end\b\s*([A-Za-z_][A-Za-z0-9_.\']*)?\s*$')
SEC_OPEN = re.compile(r'^\s*section\b\s*([A-Za-z_][A-Za-z0-9_.\']*)?\s*$')


def tracked_lean(root="SaltWorks"):
    try:
        out = subprocess.run(["git", "ls-files", f"{root}/*.lean", f"{root}/**/*.lean"],
                             capture_output=True, text=True, check=True).stdout
        return [p for p in out.splitlines() if p.endswith(".lean")]
    except Exception as e:
        print(f"⛔ REFUSED: cannot list tracked files ({type(e).__name__})")
        sys.exit(2)


def decls_of(path):
    """-> (list of (fullname, lineno), problem_or_None). Strips block comments."""
    try:
        src = open(path, encoding="utf-8").read()
    except Exception as e:
        return [], f"UNREADABLE({type(e).__name__})"
    # Strip comments.  A `--` LINE comment must be consumed by the SAME scanner:
    # C4.lean line 95 is `-- ... a `/-- -/`` and a stripper that only looks for
    # `/-` opens a phantom block there that never closes.  Diagnosed, not guessed.
    depth, out, i = 0, [], 0
    while i < len(src):
        if depth == 0 and src.startswith("--", i):
            while i < len(src) and src[i] != "\n":
                out.append(" "); i += 1
            continue
        if src.startswith("/-", i):
            depth += 1; out.append("  "); i += 2; continue
        if src.startswith("-/", i):
            if depth == 0:
                return [], "UNBALANCED-COMMENT"
            depth -= 1; out.append("  "); i += 2; continue
        # PRESERVE newlines inside comments, or the line structure (and every
        # line number, and every `^namespace` match) collapses after the first
        # block comment.  Cost me 12 false REFUSALs on the first run.
        out.append(("\n" if src[i] == "\n" else " ") if depth else src[i])
        i += 1
    if depth != 0:
        return [], "UNBALANCED-COMMENT"
    text = "".join(out)
    # Stack entries are ('ns', name) or ('sec', name).  `section` does NOT
    # contribute to a declaration's full name but DOES consume an `end`, which
    # is why ignoring it made every `section Audit ... end Audit` file look
    # unbalanced -- 5 of my 12 first-run refusals.
    stack, found = [], []
    for n, line in enumerate(text.splitlines(), 1):
        m = NS_OPEN.match(line)
        if m:
            stack.append(("ns", m.group(1))); continue
        m = SEC_OPEN.match(line)
        if m:
            stack.append(("sec", m.group(1) or "")); continue
        m = NS_END.match(line)
        if m:
            if not stack:
                return [], f"UNBALANCED-END({(m.group(1) or '').strip()} at line {n})"
            stack.pop(); continue
        m = DECL.match(line)
        if m:
            prefix = [nm for kind, nm in stack if kind == "ns"]
            full = ".".join(prefix + [m.group(2)]) if prefix else m.group(2)
            found.append((full, n))
    if stack:
        return [], f"UNBALANCED-OPEN(unclosed {'/'.join(k for k, _ in stack)})"
    return found, None


def main(argv):
    files = argv[1:] or tracked_lean()
    if not files:
        print("⛔ REFUSED: empty file set — refusing to report 'no duplicates' over nothing")
        return 2
    where = collections.defaultdict(list)
    problems, ok = [], 0
    for p in files:
        ds, prob = decls_of(p)
        if prob:
            problems.append((p, prob)); continue
        ok += 1
        for full, n in ds:
            where[full].append((p, n))
    dups = {k: v for k, v in where.items() if len({p for p, _ in v}) > 1}
    head = os.popen("git rev-parse --short HEAD 2>/dev/null").read().strip() or "?"
    scope = f"SCOPE: {ok} files parsed, {len(where)} distinct declarations, HEAD={head}"
    if problems:
        scope += f", ⚠️ {len(problems)} REFUSED — scope INCOMPLETE"
    print(scope)
    for p, prob in problems:
        print(f"  ⚠️ REFUSED {p}: {prob}")
    if dups:
        print(f"⛔ DUPLICATE DECLARATIONS: {len(dups)}")
        for full, locs in sorted(dups.items()):
            print(f"  {full}")
            for p, n in locs:
                print(f"      {p}:{n}")
        print("  ⇒ While these exist, SaltWorks.lean's IMPORT ORDER decides which copy")
        print("    wins (first import). Delete the duplicate; do not manage the order.")
        return 1
    print("✅ no duplicate declarations in the scope above"
          + (" (but some files were REFUSED — the scope is incomplete)" if problems else ""))
    return 2 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
