#!/usr/bin/env python3
"""check_verification_claims.py -- a public verification claim names its check.

Council 2026-10-06, ruling 1 (desk AAN), adopting recommendations 1 and 5 of
docs/POSTMORTEM-riscv-core-2026-10.md:

  rec 1  Every "verified" / "proved" / "machine-checked" in a public README or
         abstract cites the theorem or suite whose subject it is, and a CI arm
         refuses such a word in public prose without a citation.
         Wrong if: a public sentence asserting verification passes CI with no
         cited check.
  rec 5  A fence is applied where it binds. When a record says "no theorem
         relates A to B", the public text is searched for claims about B.
         Wrong if: a fence stands while public prose claims what it fences.

The specimen: from 2026-08-16 to 2026-10-05 this repository's README said the
stack runs "to a **verified** RISC-V processor taped out on a community silicon
shuttle". Nothing ever verified that processor, and a record (the 08-09 claim
fence) already said no theorem related the model to the core.

WHAT IT READS (the population, printed with every verdict):
  * every tracked file whose name starts with README (any directory, any case);
  * the abstract of every tracked .tex file (\\begin{abstract} ... \\end{abstract});
  * the "Abstract" section of every tracked Markdown file under a paper/,
    papers/ or article/ directory, and every tracked file there whose name
    contains "abstract" (an arXiv metadata abstract), read whole.

WHAT A CLAIM IS: a word matching CLAIM_WORDS (below; printed with the verdict)
in prose. Fenced code blocks, inline `code` spans (quoted output, names) and
HTML/TeX comments are not prose; a code span can still be a CITATION.

WHAT A CITATION IS -- one of these, in the SAME BLOCK (a Markdown paragraph, a
single table row, a list item, or a whole abstract):
  * a link or backticked path / \\url / \\href / \\texttt to a file in this
    repository that is a CHECK: a Lean file, a test or a script (CHECK_SUFFIXES),
    a CI workflow under .github/workflows/,
    or a file under a test/tests/spec directory, or a directory holding one;
  * a backticked name that a tracked .lean file declares as a theorem/lemma;
  * a https://github.com/jyh/<repo>/(blob|tree)/<ref>/<path> URL whose path has
    the same shape (cross-repository: existence NOT checked, counted apart).
A citation to a document (.md, .txt, .pdf) is not a check and does not count.

FENCES (rec 5): `.verification-fences` at the repository root, one fence per
line: `<id> TAB <subject regex> TAB <record path> TAB <what is fenced>`. A
sentence that matches a fence's subject and carries a claim word is REFUSED
whatever it cites -- a fence says no theorem exists, so any citation is to
something else, which is the specimen exactly -- unless the sentence carries a
negation (see the limits). The record path must exist.

EXEMPTIONS: `.verification-claims-exempt`, one `<path> TAB <reason>` per line, for a
FROZEN record that cannot be edited to cite or waive (a byte-pinned provenance
file). The path must be tracked; every exemption is printed beside the verdict.

WAIVERS: a block may carry `<!-- claim-check: not-a-claim: <reason> -->` (or
`% claim-check: not-a-claim: <reason>` in TeX) when its claim word is not a
verification claim -- a proper name ("SWE-bench Verified"), a hypothesis held
open ("neither proven"). A waiver is the AUTHOR'S WORD, not a check: every
waiver is printed with its reason, the count rides beside the verdict, and a
waiver never excuses a fence.

DECLARED LIMITS (printed beside every verdict):
  * the claim words are a fixed list; a synonym outside it is not seen;
  * the citation scope is the block, not the sentence: a block with one real
    citation passes every claim word in it;
  * the CITATION'S SUBJECT is not checked -- the arm cannot tell whether the
    cited theorem is about what the sentence claims. Rec 5's fences are the
    only arm that reaches subject, and only for subjects someone has fenced;
  * negation is a token test: a claim word with a negation among the 3 words
    before it ("was not verified", "neither proven") is a DENIAL, needs no
    citation, and passes a fence. "not only verified" would be misread.
  * a heading is scoped by the block after it; a table's header row is a
    column label and is not read.

Exit: 0 clean, 1 findings, 2 usage or a broken fence file.
Usage:  check_verification_claims.py [--root DIR] [--verbose]
        check_verification_claims.py --self-test
"""
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys
import tempfile

CLAIM_WORDS = re.compile(
    r"(?i)(?<![A-Za-z])(verified|proved|proven|"
    r"machine-checked|kernel-checked)(?![A-Za-z])")
CLAIM_WORDS_DECLARED = ("verified proved proven machine-checked "
                        "kernel-checked (any case; a hyphenated prefix such as "
                        "machine-verified is matched; unverified is not; the agent's verbs "
                        "proves/verifies are NOT in the list)")
NEGATIONS = re.compile(
    r"(?i)(?<![A-Za-z])(not|never|no|nothing|none|neither|nor|without|un-?|n't)(?![A-Za-z])")
NEG_WINDOW = 3     # a claim word is NEGATED if one of the 3 words before it is a negation


def claim_hits(sentence):
    """-> [(word, negated)] for every claim word in a sentence."""
    hits = []
    for m in CLAIM_WORDS.finditer(sentence):
        before = re.findall(r"[A-Za-z'-]+", sentence[:m.start()])[-NEG_WINDOW:]
        neg = any(NEGATIONS.fullmatch(w) or w.lower().endswith("n't") for w in before)
        hits.append((m.group(1), neg))
    return hits
CHECK_SUFFIXES = (".lean", ".py", ".sh", ".v", ".sv", ".rs", ".swift", ".cs",
                  ".ml", ".smt2", ".dfy", ".tla", ".js", ".ts", ".c", ".cpp", ".ps1")
CI_DIR = ".github/workflows/"      # a CI workflow is a suite: its .yml counts as a check
CHECK_DIRS = {"test", "tests", "spec", "specs", "proofs"}
WAIVER = re.compile(r"claim-check:\s*not-a-claim:\s*(?!-->)(\S.*?)\s*(?:-->|$)", re.M)
FENCE_FILE = ".verification-fences"
EXEMPT_FILE = ".verification-claims-exempt"
DECL = re.compile(r"^\s*(?:@\[[^\]]*\]\s*)?(?:private\s+|protected\s+|noncomputable\s+)*"
                  r"(?:theorem|lemma)\s+([^\s(:{\[]+)", re.M)
# The saltworks F-core32 subject, kept here byte-for-byte so the self-test drives the fence that ships
# (the saltworks job asserts the two agree). A fence errs toward false positives: a denial still passes.
WIDE_CORE_FENCE = (r"\b(?:fabricated|taped[- ]?out|submitted|shuttle|chip|RISC[- ]?V|RV32I?|silicon|Tiny ?Tapeout|fab|hardware)\b(?:\W+\w+){0,3}?\W+(?:core|processor|CPU|implementation)\b|\b(?:core|processor|CPU|implementation)\b(?:\W+\w+){0,4}?\W+(?:fabricated|taped[- ]?out|submitted|on the shuttle|(?:on|in) (?:the|this) chip|went to fab|to fab)\b|core32|busadapt8")
GH_URL = re.compile(r"https://github\.com/jyh/([A-Za-z0-9_.-]+)/(?:blob|tree)/[^/\s)]+/([^\s)#}]+)")


def tracked_files(root):
    out = subprocess.run(["git", "-C", root, "ls-files", "-z"], capture_output=True)
    if out.returncode != 0:
        raise SystemExit(f"usage: {root} is not a git work tree (git ls-files rc {out.returncode})")
    return [p for p in out.stdout.decode("utf-8", "replace").split("\0") if p]


def read(root, rel):
    with open(os.path.join(root, rel), "rb") as fh:
        return fh.read().decode("utf-8", "replace")


class Repo:
    def __init__(self, root):
        self.root = root
        self.files = tracked_files(root)
        self.fileset = set(self.files)
        self.dirs = set()
        for f in self.files:
            parts = f.split("/")
            for i in range(1, len(parts)):
                self.dirs.add("/".join(parts[:i]))
        self.by_base = {}
        for f in self.files:
            self.by_base.setdefault(os.path.basename(f), []).append(f)
        self._decls = None

    def decls(self):
        if self._decls is None:
            names = set()
            for f in self.files:
                if f.endswith(".lean"):
                    for m in DECL.finditer(read(self.root, f)):
                        n = m.group(1)
                        names.add(n)
                        names.add(n.split(".")[-1])
            self._decls = names
        return self._decls

    def is_check_file(self, rel):
        parts = rel.split("/")
        return (rel.endswith(CHECK_SUFFIXES) or any(p in CHECK_DIRS for p in parts[:-1])
                or (rel.startswith(CI_DIR) and rel.endswith((".yml", ".yaml"))))

    def is_check_dir(self, rel):
        rel = rel.rstrip("/")
        pre = rel + "/"
        return any(f.startswith(pre) and self.is_check_file(f) for f in self.files)

    def resolve(self, target, src):
        """A repository path target -> True if it names a check."""
        t = target.strip().split("#")[0].split("?")[0]
        t = re.sub(r":\d+(?:-\d+)?$", "", t)          # file.lean:12 / :12-30
        if not t or "://" in t or t.startswith("mailto:"):
            return False
        cands = [os.path.normpath(os.path.join(os.path.dirname(src), t)),
                 os.path.normpath(t.lstrip("/"))]
        for c in cands:
            c = c.replace(os.sep, "/")
            if c in self.fileset and self.is_check_file(c):
                return True
            if c.rstrip("/") in self.dirs and self.is_check_dir(c):
                return True
        if "/" not in t and t in self.by_base:
            return any(self.is_check_file(f) for f in self.by_base[t])
        return False


def gh_url_is_check(path):
    parts = path.split("/")
    return path.endswith(CHECK_SUFFIXES) or any(p in CHECK_DIRS for p in parts)


def cited(block, src, repo):
    """-> 'local' | 'cross' | None"""
    targets = []
    targets += re.findall(r"\]\(([^)\s]+)\)", block)                  # [x](path)
    for t in re.findall(r"`([^`]+)`", block):                           # `path` or `Name`
        targets.append(t)
        if re.search(r"\s", t.strip()):
            targets.append(re.sub(r"\s+", "", t))                       # a path wrapped mid-span
    targets += re.findall(r"\\(?:url|path|nolinkurl|texttt|href)\{([^}]+)\}", block)
    cross = False
    for t in targets:
        t = t.strip()
        m = GH_URL.search(t)
        if m:
            if gh_url_is_check(m.group(2)):
                cross = True
            continue
        if repo.resolve(t, src):
            return "local"
        if re.fullmatch(r"[A-Za-z_][\w.'₀-₉]*", t) and t in repo.decls():
            return "local"
    for m in GH_URL.finditer(block):
        if gh_url_is_check(m.group(2)):
            cross = True
    return "cross" if cross else None


# ---------------------------------------------------------------- blocks

def md_blocks(text):
    """-> [(first_line_no, raw_block)] for Markdown prose blocks.

    A paragraph is one block; a list item, a table row each one block; a HEADING
    joins the block that follows it (a title is scoped by its section's first
    paragraph); a table's HEADER row (the row above `|---|`) is a column label
    and is dropped -- declared."""
    lines = text.split("\n")
    out, block, start, fence, heading = [], [], None, None, None

    def emit(n, raw):
        nonlocal heading
        if heading is not None:
            n, raw = heading[0], heading[1] + "\n" + raw
            heading = None
        out.append((n, raw))

    def flush():
        nonlocal block, start
        if block:
            emit(start, "\n".join(block))
        block, start = [], None

    for i, line in enumerate(lines, 1):
        s = line.strip()
        if fence:
            if s.startswith(fence):
                fence = None
            continue
        if s.startswith("```") or s.startswith("~~~"):
            flush(); fence = s[:3]; continue
        if not s:
            flush(); continue
        if s.startswith("#"):
            flush()
            if heading is not None:
                out.append(heading)
            heading = (i, line); continue
        if s.startswith("|"):
            flush()
            if re.fullmatch(r"\|?(\s*:?-{3,}:?\s*\|)+\s*:?-*:?\s*\|?", s):
                if out and out[-1][1].split("\n")[-1].lstrip().startswith("|"):
                    n, raw = out.pop()            # the header row: a column label
                    if "\n" in raw:              # a heading had joined it: the heading waits again
                        heading = (n, raw.rsplit("\n", 1)[0])
                continue
            emit(i, line); continue
        if re.match(r"^([-*+]|\d+[.)])\s", s):
            flush(); start = i; block.append(line); continue
        if start is None:
            start = i
        block.append(line)
    flush()
    if heading is not None:
        out.append(heading)
    return out


def strip_comments_md(block):
    return re.sub(r"<!--.*?-->", " ", block, flags=re.S)


def strip_comments_tex(block):
    return re.sub(r"(?<!\\)%.*", " ", block)


def sentences(flat):
    return [s for s in re.split(r"(?<=[.!?])\s+(?=[\"'*_`(\[A-Z])", flat) if s.strip()]


# ---------------------------------------------------------------- population

def population(repo):
    """-> list of (rel, kind, [(line, raw_block, is_tex)])"""
    out = []
    for f in repo.files:
        base = os.path.basename(f)
        parts = f.split("/")
        paperish = any(p in ("paper", "papers", "article") for p in parts[:-1])
        if base.lower().startswith("readme"):
            if base.lower().endswith(".tex"):
                continue
            out.append((f, "readme", [(n, b, False) for n, b in md_blocks(read(repo.root, f))]))
        elif f.endswith(".tex"):
            text = read(repo.root, f)
            for m in re.finditer(r"\\begin\{abstract\}(.*?)\\end\{abstract\}", text, re.S):
                line = text.count("\n", 0, m.start()) + 1
                out.append((f, "abstract", [(line, m.group(1), True)]))
        elif paperish and "abstract" in base.lower() and base.lower().endswith((".txt", ".md")):
            out.append((f, "abstract", [(1, read(repo.root, f), False)]))
        elif paperish and f.endswith(".md"):
            text = read(repo.root, f)
            m = re.search(r"(?im)^#{1,6}\s*abstract\s*$(.*?)(?=^#{1,6}\s|\Z)", text, re.S)
            if m:
                line = text.count("\n", 0, m.start()) + 1
                out.append((f, "abstract", [(line + n, b, False) for n, b in md_blocks(m.group(1))]))
    return out


def load_exempt(repo):
    """path TAB reason. A FROZEN record (byte-pinned, so it cannot be edited to cite or
    waive) is declared here rather than silently skipped; every exemption is printed."""
    path = os.path.join(repo.root, EXEMPT_FILE)
    if not os.path.exists(path):
        return {}
    out = {}
    for i, line in enumerate(read(repo.root, EXEMPT_FILE).split("\n"), 1):
        if not line.strip() or line.startswith("#"):
            continue
        cols = line.split("\t")
        if len(cols) != 2 or not cols[1].strip():
            raise SystemExit(f"usage: {EXEMPT_FILE}:{i}: expected <path> TAB <reason>")
        rel = cols[0].strip()
        if rel not in repo.fileset:
            raise SystemExit(f"usage: {EXEMPT_FILE}:{i}: {rel!r} is not a tracked file -- "
                             f"an exemption for nothing is a stale exemption")
        out[rel] = cols[1].strip()
    return out


def load_fences(repo):
    path = os.path.join(repo.root, FENCE_FILE)
    if not os.path.exists(path):
        return []
    fences = []
    for i, line in enumerate(read(repo.root, FENCE_FILE).split("\n"), 1):
        if not line.strip() or line.startswith("#"):
            continue
        cols = line.split("\t")
        if len(cols) != 4:
            raise SystemExit(f"usage: {FENCE_FILE}:{i}: expected 4 TAB-separated columns, got {len(cols)}")
        fid, subj, record, what = (c.strip() for c in cols)
        try:
            rx = re.compile(subj, re.I)
        except re.error as e:
            raise SystemExit(f"usage: {FENCE_FILE}:{i}: subject regex does not compile: {e}")
        if record not in repo.fileset:
            raise SystemExit(f"usage: {FENCE_FILE}:{i}: fence {fid} cites record {record!r}, "
                             f"which is not a tracked file -- a fence must name the record that says it")
        fences.append((fid, rx, record, what))
    return fences


def scan(root):
    repo = Repo(root)
    fences = load_fences(repo)
    exempt = load_exempt(repo)
    findings, waivers, stats = [], [], {"files": 0, "blocks": 0, "claims": 0,
                                         "cited_local": 0, "cited_cross": 0, "negated": 0}
    stats["exempt"] = exempt
    for rel, kind, blocks in population(repo):
        if rel in exempt:
            continue
        stats["files"] += 1
        for line, raw, is_tex in blocks:
            stats["blocks"] += 1
            waiver = WAIVER.search(raw)
            prose = strip_comments_tex(raw) if is_tex else strip_comments_md(raw)
            # an inline code span is quoted output or a name, not prose: it can CITE, never CLAIM
            flat = " ".join(re.sub(r"`[^`]*`", " ", prose).split())
            sents = sentences(flat)
            hits = [(sn, w, neg) for sn in sents for w, neg in claim_hits(sn)]
            if not hits:
                continue
            stats["claims"] += len(hits)
            stats["negated"] += sum(1 for _, _, neg in hits if neg)
            words = [w for _, w, neg in hits if not neg]
            if not words:
                continue                          # every claim word in the block is denied
            # rec 5 first: a fence is never excused by a citation or a waiver.
            fenced = False
            for sn in sents:
                if not any(not neg for _, neg in claim_hits(sn)):
                    continue
                # the fence reads what a reader READS: a link's target and a bare URL are not prose
                seen = re.sub(r"https?://\S+", " ", re.sub(r"\]\([^)]*\)", "]", sn))
                for fid, rx, record, what in fences:
                    if rx.search(seen):
                        fenced = True
                        findings.append((rel, line, "FENCED",
                                         f"fence {fid} ({what}; record {record}) -- "
                                         f"sentence claims about a fenced subject: {sn[:160]}"))
            if fenced:
                continue
            c = cited(prose, rel, repo)
            if c == "local":
                stats["cited_local"] += 1
                continue
            if c == "cross":
                stats["cited_cross"] += 1
                continue
            if waiver:
                waivers.append((rel, line, waiver.group(1)))
                continue
            findings.append((rel, line, "UNCITED",
                             f"{kind}: '{words[0]}' with no cited check in its block: {flat[:160]}"))
    return findings, waivers, stats, fences


def limits_lines(stats, waivers, fences):
    return [
        f"  population: {stats['files']} file(s) (READMEs + paper abstracts), {stats['blocks']} block(s), "
        f"{stats['claims']} claim word(s), {stats['negated']} of them NEGATED (a negation in the "
        f"{NEG_WINDOW} words before -- a token test, not a reading; negated words need no citation)",
        f"  claim words: {CLAIM_WORDS_DECLARED}",
        f"  cited: {stats['cited_local']} block(s) in-repo, {stats['cited_cross']} block(s) cross-repo "
        f"(cross-repo existence NOT checked)",
        f"  waivers: {len(waivers)} (the author's word, not a check)",
        f"  exempt: {len(stats['exempt'])} frozen file(s) NOT READ, from {EXEMPT_FILE}"
        + "".join(f"\n    {p}: {why}" for p, why in sorted(stats['exempt'].items())),
        f"  fences: {len(fences)} from {FENCE_FILE}" + ("" if fences else " (none declared: rec 5 reaches nothing here)"),
        "  NOT checked: whether a cited check is ABOUT the claim's subject (only a fence reaches subject); "
        "the citation scope is the block, not the sentence",
    ]


def main(argv=None):
    # A verdict that prints prose from the tree must not depend on the console's codec: on Windows a
    # redirected stdout is cp1252, an em-dash there exits 0 with a mangled line and a character outside
    # it exits 1, the same code as "finding found" (saltworks CLAUDE.md, the declared Windows non-goal).
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description="a public verification claim names its check")
    ap.add_argument("--root", default=".")
    ap.add_argument("--verbose", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args(argv)
    if a.self_test:
        return self_test()
    findings, waivers, stats, fences = scan(a.root)
    for rel, line, cls, msg in findings:
        print(f"{rel}:{line}: {cls}: {msg}")
    if a.verbose:
        for rel, line, why in waivers:
            print(f"{rel}:{line}: WAIVED: {why}")
    verdict = "FAIL" if findings else "OK"
    print(f"check_verification_claims: {verdict} ({len(findings)} finding(s))")
    print("\n".join(limits_lines(stats, waivers, fences)))
    return 1 if findings else 0


# ---------------------------------------------------------------- self-test

def self_test():
    """Every arm is driven red against a planted defect and green against its fix,
    in a scratch repository; the UNMUTATED subject runs in the same harness."""
    arms = 0
    fails = []

    def repo_with(files):
        d = tempfile.mkdtemp(prefix="vclaims-")
        subprocess.run(["git", "init", "-q", d], check=True)
        for rel, body in files.items():
            p = os.path.join(d, rel)
            os.makedirs(os.path.dirname(p), exist_ok=True)
            with open(p, "w", encoding="utf-8", newline="") as fh:
                fh.write(body)
        subprocess.run(["git", "-C", d, "add", "-A"], check=True)
        return d

    def expect(name, files, want_classes):
        nonlocal arms
        arms += 1
        d = repo_with(files)
        got = sorted(c for _, _, c, _ in scan(d)[0])
        if got != sorted(want_classes):
            fails.append(f"{name}: want {sorted(want_classes)} got {got}")

    lean = {"Core/Proof.lean": "theorem core_correct : True := trivial\n",
            "tests/run_suite.py": "print('ok')\n"}
    # the specimen, verbatim in shape: a verified processor, no citation anywhere in the block
    specimen = ("SaltWorks runs from application code to a **verified** RISC-V processor\n"
                "taped out on a community silicon shuttle.\n")
    expect("specimen is refused", {"README.md": specimen, **lean}, ["UNCITED"])
    expect("specimen cited by a Lean file passes",
           {"README.md": specimen.replace("shuttle.", "shuttle ([proof](Core/Proof.lean))."), **lean}, [])
    expect("a theorem NAME counts as a citation",
           {"README.md": specimen.replace("shuttle.", "shuttle (`core_correct`)."), **lean}, [])
    expect("a backticked name that is NOT a declared theorem does not",
           {"README.md": specimen.replace("shuttle.", "shuttle (`core_wrong`)."), **lean}, ["UNCITED"])
    expect("a citation to a DOCUMENT is not a check",
           {"README.md": specimen.replace("shuttle.", "shuttle ([notes](NOTES.md))."),
            "NOTES.md": "x\n", **lean}, ["UNCITED"])
    expect("a link to a path that does not exist is not a check",
           {"README.md": specimen.replace("shuttle.", "shuttle ([p](Core/Gone.lean))."), **lean},
           ["UNCITED"])
    expect("a CI workflow counts as a suite",
           {"README.md": "Frozen ports are verified by CI canaries (`.github/workflows/test.yml`).\n",
            ".github/workflows/test.yml": "on: push\n"}, [])
    expect("a .yml outside .github/workflows is not a check",
           {"README.md": "Frozen ports are verified by `conf/test.yml`.\n", "conf/test.yml": "a: 1\n"},
           ["UNCITED"])
    expect("a test directory counts as a suite",
           {"README.md": "The parser is verified by the suite in [`tests/`](tests/).\n", **lean}, [])
    expect("a cross-repo GitHub URL to a Lean file counts (existence unchecked)",
           {"README.md": "Proved in https://github.com/jyh/salt/blob/main/Salt/X.lean today.\n"}, [])
    expect("a cross-repo URL to a document does not",
           {"README.md": "Proved in https://github.com/jyh/salt/blob/main/README.md today.\n"},
           ["UNCITED"])
    expect("a hyphenated prefix is a claim (machine-verified)",
           {"README.md": "A machine-verified stack.\n"}, ["UNCITED"])
    expect("unverified is not a claim",
           {"README.md": "An unverified agent wrote it.\n"}, [])
    expect("a fenced code block is not prose",
           {"README.md": "Build it.\n\n```\nverified\n```\n"}, [])
    expect("an inline code span is quoted output, not prose (`a1 proven 9/15`)",
           {"README.md": "THE READ: `a1 proven 9/15` at the gate.\n"}, [])
    expect("an HTML comment is not prose",
           {"README.md": "Text <!-- verified --> here.\n"}, [])
    expect("a waiver excuses a non-claim",
           {"README.md": "Wave 1 ran on SWE-bench Verified. <!-- claim-check: not-a-claim: a dataset's proper name -->\n"},
           [])
    expect("a waiver with no reason is not a waiver",
           {"README.md": "Wave 1 ran on SWE-bench Verified. <!-- claim-check: not-a-claim: -->\n"},
           ["UNCITED"])
    expect("one table row is one block (a citation in the next row does not count)",
           {"README.md": "| a | b |\n|---|---|\n| CPU | verified |\n| X | [p](Core/Proof.lean) |\n", **lean},
           ["UNCITED"])
    expect("a TeX abstract is read and refused",
           {"paper/p.tex": "\\begin{abstract}Every theorem is verified by Lean.\\end{abstract}\n"},
           ["UNCITED"])
    expect("a TeX abstract cited by \\url to a Lean file passes",
           {"paper/p.tex": "\\begin{abstract}Every theorem is verified by Lean "
                           "(\\url{https://github.com/jyh/salt/tree/main/Salt/HB/A.lean}).\\end{abstract}\n"},
           [])
    expect("a TeX comment is not prose",
           {"paper/p.tex": "\\begin{abstract}% verified here\nWe count.\\end{abstract}\n"}, [])
    expect("a TeX body outside the abstract is not read",
           {"paper/p.tex": "\\begin{abstract}We count.\\end{abstract}\nIt is verified.\n"}, [])
    expect("an arXiv metadata abstract is read",
           {"papers/x/arxiv-abstract-v3.txt": "A machine-checked proof.\n"}, ["UNCITED"])
    expect("a Markdown paper's Abstract section is read",
           {"article/ARTICLE.md": "# T\n\n## Abstract\n\nIt is proved.\n\n## Body\n\nIt is proved.\n"},
           ["UNCITED"])
    expect("a heading's claim is scoped by the block after it (cited there: passes)",
           {"README.md": "# A verified core\n\nSee [the proof](Core/Proof.lean).\n", **lean}, [])
    expect("a heading's claim is scoped by the block after it (uncited there: refused)",
           {"README.md": "# A verified core\n\nIt is small.\n", **lean}, ["UNCITED"])
    expect("a table header under a HEADING is dropped and the heading joins the first row",
           {"README.md": "## Stack\n\n| Layer | What is proved |\n|---|---|\n| A | [p](Core/Proof.lean) |\n", **lean}, [])
    expect("a table HEADER row is a column label",
           {"README.md": "| Layer | What is proved |\n|---|---|\n| A | [p](Core/Proof.lean) |\n", **lean}, [])
    expect("a backticked path wrapped across lines still resolves",
           {"README.md": "It is verified by `Core/\nProof.lean`.\n", **lean}, [])
    expect("a denial is not a claim (was not verified)",
           {"README.md": "The core was not verified by anything.\n"}, [])
    expect("a negation far from the word does not deny it (Lean has proved X, but no theorem ...)",
           {"README.md": "Lean has proved a model of the core, but no theorem relates it.\n"}, ["UNCITED"])
    fence = "F1\tRISC-V (core|processor)\tNOTES.md\tno theorem relates the model to the core\n"
    expect("rec 5: a fenced subject is refused EVEN WITH a citation",
           {"README.md": specimen.replace("shuttle.", "shuttle ([proof](Core/Proof.lean))."),
            ".verification-fences": fence, "NOTES.md": "x\n", **lean}, ["FENCED"])
    expect("rec 5: a fenced subject is refused even with a waiver",
           {"README.md": specimen.replace("shuttle.", "shuttle. <!-- claim-check: not-a-claim: nope -->"),
            ".verification-fences": fence, "NOTES.md": "x\n", **lean}, ["FENCED"])
    expect("rec 5: a sentence that DENIES the fenced claim passes the fence (then needs citing)",
           {"README.md": "The RISC-V core was not verified ([erratum](Core/Proof.lean)).\n",
            ".verification-fences": fence, "NOTES.md": "x\n", **lean}, [])
    expect("rec 5: a fence sentence elsewhere in the block does not taint an unrelated sentence",
           {"README.md": "The compiler is verified ([p](Core/Proof.lean)). The RISC-V core is taped out.\n",
            ".verification-fences": fence, "NOTES.md": "x\n", **lean}, [])
    # the WIDENED core fence (saltworks .verification-fences F-core32, 2026-10-06): kent's four driven
    # paraphrases walked past the first subject regex beside any citation -- the specimen's own route.
    wide = ("F1\t" + WIDE_CORE_FENCE + "\tNOTES.md\tno theorem relates the model to the core\n")
    for sent in ("The fabricated core is verified.", "The taped-out processor is machine-checked.",
                 "An RV32I core on the shuttle is verified.", "The RISC V processor is verified.",
                 "The RISC-V core is verified.",
                 # kent's residual six (2026-10-06 10:58), closed the same hour
                 "The core that went to fab is verified.", "The silicon core is verified.",
                 "The Tiny Tapeout core is verified.", "The processor in the chip is verified.",
                 "The RISC-V implementation is verified.", "The hardware CPU is formally verified."):
        expect(f"rec 5 widened: '{sent}' is FENCED beside a citation",
               {"README.md": sent + " See [the proof](Core/Proof.lean).\n",
                ".verification-fences": wide, "NOTES.md": "x\n", **lean}, ["FENCED"])
    expect("rec 5 widened, control: a sentence about the Lean kernel is not fenced",
           {"README.md": "Every proof is verified by the Lean kernel ([p](Core/Proof.lean)).\n",
            ".verification-fences": wide, "NOTES.md": "x\n", **lean}, [])
    expect("rec 5 widened, control: 'the chip' alone is not fenced (the fence is the CORE vs core32.v)",
           {"README.md": "The chip is verified ([p](Core/Proof.lean)).\n",
            ".verification-fences": wide, "NOTES.md": "x\n", **lean}, [])
    expect("rec 5 widened, control: SAT at the silicon boundary names no core",
           {"README.md": "SAT-checked equivalence at the silicon boundary is verified ([p](Core/Proof.lean)).\n",
            ".verification-fences": wide, "NOTES.md": "x\n", **lean}, [])
    expect("rec 5 widened, control: 'this chip is the proved half' names no core",
           {"README.md": "This chip is the proved half ([p](Core/Proof.lean)).\n",
            ".verification-fences": wide, "NOTES.md": "x\n", **lean}, [])
    # a fence whose record is missing is a broken fence file, never a silent no-op
    arms += 1
    d = repo_with({"README.md": "x\n", ".verification-fences": fence})
    try:
        scan(d)
        fails.append("a fence citing a missing record must refuse (rc 2)")
    except SystemExit as e:
        if not str(e).startswith("usage:"):
            fails.append(f"missing-record fence refused with the wrong shape: {e}")
    expect("an exempt (frozen) file is not read",
           {"README.md": "A verified core.\n", ".verification-claims-exempt": "README.md\tbyte-pinned record\n"}, [])
    arms += 1
    d = repo_with({"README.md": "x\n", ".verification-claims-exempt": "GONE.md\tpinned\n"})
    try:
        scan(d)
        fails.append("an exemption for a missing file must refuse (rc 2)")
    except SystemExit as e:
        if not str(e).startswith("usage:"):
            fails.append(f"missing-file exemption refused with the wrong shape: {e}")
    # the control: an empty population is reported as one, not as a pass of something
    arms += 1
    d = repo_with({"src/x.py": "print(1)\n"})
    f, w, st, fe = scan(d)
    if f or st["files"] != 0:
        fails.append(f"empty population: want 0 files 0 findings, got {st['files']} / {len(f)}")
    for m in fails:
        print("SELF-TEST FAIL:", m)
    print(f"check_verification_claims --self-test: {arms - len(fails)}/{arms} arms "
          f"{'OK' if not fails else 'FAILED'}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
