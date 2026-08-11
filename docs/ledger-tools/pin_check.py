#!/usr/bin/env python3
"""
# prose_rot: ignore-start  (this docstring quotes the failure modes it detects)
pin_check.py — do the doc's `name` + `file:line` citations still point at it?

    python3 docs/ledger-tools/pin_check.py <doc.md> [...] [--ref HEAD] [--repo .]
    python3 docs/ledger-tools/pin_check.py --selftest

EVIDENCE seat, 2026-08-10 18:2x. Built because the maestro re-verified the
memory block's load-bearing pins BY HAND before printing them and found FIVE
already drifted (decQ_encD :97→:140, slice_a_excluded :558→:578, among them).

A hand process that finds five real defects is a tool that has not been written
yet — and this seat had just banked, twenty minutes earlier, that MECHANISING A
HABIT IS ITSELF A DETECTOR.

⛔ WHY THIS CLASS IS INVISIBLE TO EVERY OTHER SWEEP -------------------------------

A citation `decQ_encD (Foo.lean:97)` is a POSITIVE ASSERTION about the corpus.
It carries no tense marker and no keyword, so prose_rot's direction (A) cannot
see it. It goes false SILENTLY the moment anyone inserts a line above it — and
it goes false in the WORST direction, because a stale pin still LOOKS precise
and a reader who follows it lands on unrelated code and trusts what they find.

But unlike a bare number, a pin carries its own re-derivation key: THE NAME.
So this is the one sub-class of direction (B) that a machine can actually close.

⚖️ WHAT IT CANNOT DO, printed in its own output. It only checks pins that carry
a NAME. A bare `Foo.lean:97` has nothing to search for and is EXCLUDED — this
corpus has ~205 of those against ~378 named ones, so a green here covers barely
half the citations by count. It reads a COMMITTED ref, never the worktree: the
tree is shared and another seat's half-written file has accused this seat's
tools of nonsense before.

EXIT 0 = every named pin resolves · 1 = drift or absence found · 2 = could not run
# prose_rot: ignore-end
"""
import re
import subprocess
import sys
import pathlib

# ⛔ TWO MATCHERS, and the second exists because the first LIED ABOUT THE CORPUS.
#
# The strict form below requires the name to sit IMMEDIATELY before the path.
# On the live corpus it matched 55 of 205 citations, and this seat published
# "coverage 26.8%" — a figure that reads as an indictment of everyone's citation
# discipline. The math seat then ran the same criterion on the flagship and
# nearly published that its pins were bare, about a paper at 98%.
#
# MEASURED: 109 of the 150 "bare" pins carry a name within 120 characters, just
# not adjacent. TRUE name-bearing rate is 80.0%, not 26.8%. The number was
# measuring THIS REGEX'S BLIND SPOT and calling it a property of the documents.
#
# Association by proximity is weaker evidence than adjacency, so a proximity pin
# can only ever be reported as OK or as DRIFT-when-the-name-is-declared-in-that-
# file. It never yields an ABSENT finding — an unresolved loose association is
# my parser's problem, not the author's.
PIN = re.compile(
    r"`([A-Za-z_][\w'.]*)`\s*[（(\[]?\s*`([\w/\-.]+\.lean):(\d+)`")
ANYPIN = re.compile(r"`([\w/\-.]+\.lean):(\d+)`")
NEARNAME = re.compile(r"`([A-Za-z_][\w'.]{2,})`")
DECL = r"(?:theorem|lemma|def|abbrev|structure|instance|inductive|noncomputable\s+def)"


def git_show(repo, ref, path):
    r = subprocess.run(["git", "show", f"{ref}:{path}"],
                       capture_output=True, text=True, cwd=repo)
    return r.stdout if r.returncode == 0 else None


def resolve(repo, ref, path, index):
    """A pin may cite a bare basename. Fall back to a unique basename match."""
    body = git_show(repo, ref, path)
    if body is not None:
        return path, body
    cands = index.get(pathlib.PurePath(path).name, [])
    if len(cands) == 1:
        return cands[0], git_show(repo, ref, cands[0])
    return None, None


def build_index(repo, ref):
    r = subprocess.run(["git", "ls-tree", "-r", "--name-only", ref],
                       capture_output=True, text=True, cwd=repo)
    if r.returncode != 0:
        return None
    idx = {}
    for p in r.stdout.split():
        if p.endswith(".lean"):
            idx.setdefault(pathlib.PurePath(p).name, []).append(p)
    return idx


def find_decl_lines(body, name):
    """Every line where `name` is DECLARED (not merely mentioned).

    ⛔ NAMESPACE-AWARE, and the live corpus is why. The first version reported
    `Seq.runTrace` ABSENT from Seq.lean — where it is declared as `def runTrace`
    inside `namespace Seq`. A fully-qualified citation is CORRECT prose and the
    file never contains that string. Two false FAILs on the first real doc, both
    my criterion and neither the artifact: this seat's standing rule is that when
    an instrument fails work that passed a covering build, the prior is on the
    criterion.
    """
    names = {name}
    if "." in name:
        names.add(name.rsplit(".", 1)[1])      # Seq.runTrace -> runTrace
    out = []
    for n in names:
        pat = re.compile(rf"^\s*(?:@\[[^\]]*\]\s*)?(?:private\s+|protected\s+|"
                         rf"noncomputable\s+|partial\s+)*{DECL}\s+{re.escape(n)}\b")
        out += [i for i, l in enumerate(body.splitlines(), 1) if pat.match(l)]
    return sorted(set(out))


def occurs_at(body, name, line):
    """Does the name simply APPEAR at the cited line (± 1 for wrapped decls)?

    ⚖️ A PIN HAS TWO LEGITIMATE MEANINGS and the first version knew only one.
    `BitVec.toInt` (`Spec.lean:...`) cites where a MATHLIB symbol is USED — it
    is declared in no file of this repo and never will be. Demanding a
    declaration there is demanding something the prose never claimed.
    """
    lines = body.splitlines()
    short = name.rsplit(".", 1)[-1]
    for i in range(max(1, line - 1), min(len(lines), line + 1) + 1):
        if re.search(rf"\b{re.escape(short)}\b", lines[i - 1]):
            return True
    return False


def check_doc(repo, ref, doc, index):
    text = pathlib.Path(doc).read_text(errors="replace")
    rows = []
    strict_spans = {m.span() for m in PIN.finditer(text)}
    pins = [(m.group(1), m.group(2), int(m.group(3)), True)
            for m in PIN.finditer(text)]
    for m in ANYPIN.finditer(text):
        if any(a <= m.start() and m.end() <= b for a, b in strict_spans):
            continue
        pre = text[max(0, m.start() - 120):m.start()]
        cands = [n for n in NEARNAME.findall(pre) if not n.endswith(".lean")]
        if cands:
            pins.append((cands[-1], m.group(1), int(m.group(2)), False))
    for name, path, line, strict in pins:
        real, body = resolve(repo, ref, path, index)
        if body is None:
            # ⚖️ EXTERNAL vs BROKEN, and the first sweep conflated them: six
            # Mathlib paths were reported as failures. A citation into a
            # DEPENDENCY is not a broken pin — this repo will never contain
            # Mathlib/Data/List/OfFn.lean and the prose never said it did.
            # Printed, never counted, because an exclusion must announce itself.
            rows.append(("external", name, path, line, None))
            continue
        decls = find_decl_lines(body, name)
        if line in decls:
            rows.append(("ok", name, real, line, line))          # declared there
        elif occurs_at(body, name, line):
            rows.append(("okuse", name, real, line, line))       # used there
        elif decls:
            # a DECLARATION elsewhere in the cited file is strong evidence of a
            # real pin that moved, under either association.
            nearest = min(decls, key=lambda d: abs(d - line))
            rows.append(("drift", name, real, line, nearest))
        else:
            short = name.rsplit(".", 1)[-1]
            hits = [i for i, l in enumerate(body.splitlines(), 1)
                    if re.search(rf"\b{re.escape(short)}\b", l)]
            if hits and strict:
                # occurrence-only drift is reportable ONLY when the AUTHOR put
                # the name adjacent to the path. Under a proximity association
                # it is noise: `def`, `xor`, `core` and `Iff.rfl` all "occur"
                # somewhere else in any file, and nearest-occurrence means
                # nothing. Publishing 38 of these would have been this seat's
                # third count-over-the-wrong-scope of the day.
                rows.append(("driftuse", name, real, line,
                             min(hits, key=lambda d: abs(d - line))))
            elif hits:
                rows.append(("loose", name, real, line, None))
            elif strict:
                rows.append(("absent", name, real, line, None))
            else:
                # loose association that did not resolve — MY parser's doubt,
                # never the author's defect. Counted as unchecked, not failed.
                rows.append(("loose", name, real, line, None))
    # what we could NOT check: bare pins with no name
    bare = len(re.findall(r"`[\w/\-.]+\.lean:\d+`", text)) - len(rows)
    return rows, max(bare, 0)


def main(argv):
    repo, ref, docs = ".", "HEAD", []
    i = 0
    while i < len(argv):
        if argv[i] == "--ref":
            ref = argv[i + 1]; i += 2
        elif argv[i] == "--repo":
            repo = argv[i + 1]; i += 2
        else:
            docs.append(argv[i]); i += 1
    if not docs:
        print(__doc__.split("EXIT")[0]); sys.exit(2)
    index = build_index(repo, ref)
    if index is None:
        print(f"pin_check: cannot read ref {ref!r} in {repo!r}", file=sys.stderr)
        sys.exit(2)

    print("=" * 74)
    print("PIN CHECK — do the named citations still point at the declaration?")
    print("=" * 74)
    print(f"REF        {ref}  in  {repo}   (a COMMITTED ref, never the worktree —")
    print("           the tree is shared and a half-written file lies)")
    rc, tot_bare = 0, 0
    for doc in docs:
        rows, bare = check_doc(repo, ref, doc, index)
        tot_bare += bare
        ok = sum(1 for r in rows if r[0] in ("ok", "okuse"))
        asdecl = sum(1 for r in rows if r[0] == "ok")
        ext = sum(1 for r in rows if r[0] == "external")
        loose = sum(1 for r in rows if r[0] == "loose")
        print("-" * 74)
        print(f"{doc}   {len(rows)} named pin(s)")
        for kind, name, path, line, got in rows:
            if kind in ("ok", "okuse"):
                continue
            if kind not in ("external", "loose"):
                rc = 1
            if kind == "loose":
                continue
            if kind == "drift":
                d = got - line
                print(f"  ⚠️  DRIFT   `{name}`  {path}:{line} → :{got}  "
                      f"({d:+d} lines)")
            elif kind == "driftuse":
                d = got - line
                print(f"  ⚠️  DRIFT   `{name}`  {path}:{line} → :{got}  "
                      f"({d:+d} lines, by occurrence — not declared in this repo)")
            elif kind == "absent":
                print(f"  ⛔ ABSENT  `{name}` does not appear in {path} at all")
            else:
                print(f"  ❓ EXTERNAL {path} is not in this repo (cited for "
                      f"`{name}`) — a dependency pin, UNCHECKABLE here")
        print(f"  ✅ {ok}/{len(rows) - ext - loose} in-repo named pins resolve "
              f"({asdecl} at their DECLARATION, {ok - asdecl} at a USE)"
              + (f"  · {ext} external" if ext else "")
              + (f"  · {loose} loose-association unchecked" if loose else ""))
        if bare:
            print(f"  EXCLUDED {bare} BARE pin(s) with no name — nothing to search")
            print("           for, so they are UNCHECKABLE, not clean.")
    print("-" * 74)
    print(f"⚖️  A GREEN COVERS NAMED PINS ONLY. {tot_bare} bare pin(s) were "
          f"excluded across")
    print("    all inputs and no instrument in this kit can check them.")
    sys.exit(rc)


def selftest():
    ok = True
    body = "\n".join(["-- header", "theorem alpha : True := trivial",
                      "", "lemma beta : True := trivial", "def gamma := 1"])
    for name, want in (("alpha", [2]), ("beta", [4]), ("gamma", [5]),
                       ("delta", [])):
        got = find_decl_lines(body, name)
        good = got == want
        ok &= good
        print(f"  {'ok ' if good else 'FAIL'} decl lines for {name!r}: {got} "
              f"want {want}")
    # a MENTION must not count as a declaration — the whole point
    m = find_decl_lines("theorem x := by exact alpha", "alpha")
    print(f"  {'ok ' if m == [] else 'FAIL'} a mention is NOT a declaration: {m}")
    ok &= (m == [])
    # prose_rot: ignore-start  (fixtures quote pin syntax)
    got = [(x.group(1), x.group(2), x.group(3)) for x in
           PIN.finditer("see `foo_bar` (`SaltWorks/HDL/X.lean:149`) and `Y.lean:7`")]
    # prose_rot: ignore-end
    good = got == [("foo_bar", "SaltWorks/HDL/X.lean", "149")]
    ok &= good
    print(f"  {'ok ' if good else 'FAIL'} named pin parsed, bare pin ignored: {got}")
    print("SELFTEST", "PASS" if ok else "FAIL")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--selftest":
        selftest()
    main(sys.argv[1:])
