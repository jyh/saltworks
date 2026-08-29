#!/usr/bin/env python3
"""rtlmatch.py — has the repo's RTL drifted from the bytes that were FABRICATED?

  python3 rtlmatch.py <submitted-src-dir> <repo-rtl-dir>
  python3 rtlmatch.py --selftest

  exit 0 = every submitted file matches the repo AS CODE   1 = DRIFT   2 = cannot measure

⛔ THE QUESTION THIS ANSWERS, AND WHY IT HAS A DEADLINE ON IT. A TinyTapeout revision can be
   REPLACED any number of times until 2026-09-07 13:00 PDT and NEVER AFTER. So "is what we would
   submit today the same design as what is on the shuttle?" is answerable now and unanswerable on
   09-08. Measured 2026-08-28 17:5x: 11/11 files code-identical; the ONLY divergence in the tree is
   a struck-and-answered COMMENT block in `busadapt8.v` (08/26). ⇒ no revision is owed on this
   account — which is a finding, not an absence of one.

⛔ COMMENTS ARE STRIPPED, AND THAT IS THE WHOLE RISK IN THIS TOOL: a stripper that eats too much
   reports IDENTICAL for free, in the flattering direction. So the mutation control is built IN
   rather than run beside — and it mutates a line that is UNAMBIGUOUSLY CODE.
   ⚠️ I got that wrong on the first attempt and the control caught me: my mutation landed on
   `assign c_instr`, whose FIRST occurrence in the file is inside a comment quoting the code, so the
   stripper removed the mutation and the check reported "identical" for a changed file. ***A
   MUTATION CONTROL IS ONLY A CONTROL IF THE MUTATION SURVIVES THE PIPELINE — verify that it
   CHANGED THE COMPARED TEXT, not merely that you applied it.***
"""
import os, re, sys


def strip_code(text):
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)   # block comments
    text = re.sub(r'//[^\n]*', '', text)                 # line comments
    text = re.sub(r'[ \t]+', ' ', text)                  # collapse runs of whitespace
    return "\n".join(l.strip() for l in text.splitlines() if l.strip())


def mutate_a_code_line(text):
    """Return (mutated,描述) with the change on a line carrying no comment marker at all."""
    lines = text.splitlines()
    cands = [i for i, l in enumerate(lines)
             if '//' not in l and '/*' not in l and l.strip() and not l.strip().startswith('`')]
    if not cands:
        return None, "no unambiguous code line"
    i = cands[len(cands) // 2]
    l = lines[i]
    lines[i] = l.replace(l.strip()[0], 'Z', 1)
    return "\n".join(lines), f"line {i+1}: {l.strip()[:40]!r}"


def compare(ref_dir, repo_dir):
    if not os.path.isdir(ref_dir):
        print(f"rtlmatch: reference dir absent: {ref_dir}")
        print("  ⛔ CANNOT MEASURE — this is NOT a pass. Mount the archive volume.")
        return 2
    if not os.path.isdir(repo_dir):
        print(f"rtlmatch: repo dir absent: {repo_dir}  ⛔ CANNOT MEASURE.")
        return 2
    refs = sorted(f for f in os.listdir(ref_dir) if f.endswith('.v'))
    if not refs:
        print(f"rtlmatch: 0 .v files under {ref_dir} ⛔ CANNOT MEASURE (a blank is not a pass).")
        return 2

    drift, missing, ok = [], [], []
    for name in refs:
        rp = os.path.join(repo_dir, name)
        if not os.path.isfile(rp):
            missing.append(name); continue
        a = strip_code(open(os.path.join(ref_dir, name), errors='replace').read())
        b = strip_code(open(rp, errors='replace').read())
        raw_same = open(os.path.join(ref_dir, name), 'rb').read() == open(rp, 'rb').read()
        if a == b:
            ok.append((name, raw_same))
        else:
            drift.append(name)
        # CONTROL, per file: the stripper must still SEE a code change in this very file.
        mut, what = mutate_a_code_line(open(rp, errors='replace').read())
        if mut is None:
            print(f"  ⚠️ {name}: {what} — no per-file control possible")
        else:
            mb = strip_code(mut)
            if mb == b:
                print(f"  ⛔ {name}: CONTROL FAILED — a code change survived stripping unseen ({what}).")
                print("     THE COMPARISON IS NOT TRUSTWORTHY. No verdict offered.")
                return 2

    print(f"rtlmatch: {len(refs)} submitted file(s) · {len(ok)} code-identical · "
          f"{len(drift)} drifted · {len(missing)} absent from repo")
    for name, raw_same in ok:
        print(f"    ✅ {name:32s} {'byte-identical' if raw_same else 'code-identical (comments differ)'}")
    for name in drift:
        print(f"    ⛔ {name:32s} CODE DIFFERS from the fabricated bytes")
    for name in missing:
        print(f"    ⛔ {name:32s} SUBMITTED BUT ABSENT FROM THE REPO")
    if drift or missing:
        print("  ⛔ RTL DRIFT: the repo is not the design on the shuttle.")
        print("     A revision can replace it until 2026-09-07 13:00 PDT and never after.")
        return 1
    print("  ✅ NO DRIFT — every submitted file matches the repo as code.")
    print("     ⚠️ Scope: these files only, as TEXT. It does not re-run synthesis or compare GDS.")
    return 0


def selftest():
    import tempfile, shutil
    rc = 0
    d = tempfile.mkdtemp(prefix="rtlmatch-selftest.")
    try:
        ref, repo = os.path.join(d, "ref"), os.path.join(d, "repo")
        os.makedirs(ref); os.makedirs(repo)
        body = "module m(input a, output b);\n  assign b = ~a;\nendmodule\n"
        open(os.path.join(ref, "m.v"), "w").write(body)
        open(os.path.join(repo, "m.v"), "w").write(body)
        print("SELFTEST rtlmatch:")
        for name, repo_text, want in (
            ("identical",              body, 0),
            ("comment added only",     "// a note\n" + body, 0),
            ("CODE changed",           body.replace("~a", "a"), 1),
            ("code change INSIDE a comment quote",
                                       body + "// see `assign b = a;` in the note\n", 0),
        ):
            open(os.path.join(repo, "m.v"), "w").write(repo_text)
            got = compare(ref, repo)
            print(f"  {'✅' if got == want else '⛔'} {name}: rc={got} wanted {want}\n")
            if got != want:
                rc = 1
        # missing file, and a reference dir that does not exist
        os.remove(os.path.join(repo, "m.v"))
        got = compare(ref, repo)
        print(f"  {'✅' if got == 1 else '⛔'} file absent from repo: rc={got} wanted 1\n")
        if got != 1: rc = 1
        got = compare(os.path.join(d, "nope"), repo)
        print(f"  {'✅' if got == 2 else '⛔'} reference absent: rc={got} wanted 2 (NOT a pass)\n")
        if got != 2: rc = 1
    finally:
        shutil.rmtree(d, ignore_errors=True)
    print("⇒ " + ("✅ SELFTEST PASSED" if rc == 0 else "⛔ SELFTEST FAILED"))
    return rc


if __name__ == '__main__':
    if '--selftest' in sys.argv:
        sys.exit(selftest())
    if len(sys.argv) < 3:
        print(__doc__); sys.exit(2)
    sys.exit(compare(sys.argv[1], sys.argv[2]))
