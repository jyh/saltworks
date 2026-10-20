#!/usr/bin/env python3
"""check_prose_lean.py -- a public prose claim about a machine-checked result names its Lean statement
and carries a non-author's read of the sentence against that statement.

Council 2026-10-20, ruling 1(b) (objective O88), the Captain's "accept rec": no prose claim about a
machine-checked result goes public unless it NAMES THE LEAN STATEMENT IT PARAPHRASES and a NON-AUTHOR
HAS READ THE SENTENCE AGAINST THAT STATEMENT. Built beside check_verification_claims.py (desk AAN),
whose helpers it imports; AAN reads READMEs and abstracts and accepts any cited check, and says in its
own limits that it never asks whether the cited statement is the one the sentence paraphrases.

THE RECORD  .prose-lean-reads, one claim per line, TAB-separated:
    id  path  claim-sha12  lean-decl  stmt-sha12  author  reader  date
  claim-sha12 = sha256 of the whitespace-flattened sentence, first 12 hex.
  lean-decl   = <tracked .lean path>::<declaration name>  (unambiguous by construction).
  stmt-sha12  = sha256 of the flattened declaration statement (from its keyword to the first ':=' or
                ' where'), first 12 hex. A docstring is not part of it.
  author, reader = names; date = YYYY-MM-DD.

THE BASELINE  .prose-lean-baseline, one accepted-debt claim per line: claim-sha12 TAB path TAB class.
  Hits that predate the gate (the 2026-10-19 census) are listed so the gate is green at birth and RED on
  the next new claim. A baseline line whose sentence no longer exists is STALE and refused: a correction
  shrinks the file and cannot be un-shrunk.

THE LEDGERS  .prose-lean-ledgers, one path prefix per line: working logs that are public in the repo.
  Their claim sentences are COUNTED beside the verdict and NOT gated. Lean docstrings are the same tier.

REFUSALS (each printed with its class):
  UNREAD           a claim sentence with no record and no baseline line
  NO-STATEMENT     a record whose lean-decl is not declared in a tracked .lean file
  STALE-STATEMENT  a record whose stmt-sha12 is no longer the declaration's text (the Lean moved)
  STALE-CLAIM      a record whose claim-sha12 matches no sentence in its path (the prose moved)
  SELF-READ        reader empty, or equal to author (case-insensitive)
  BAD-RECORD       a malformed line
  STALE-BASELINE   a baseline line whose sentence is gone

WHAT A CLAIM IS: a sentence in a carrier (tracked .tex body, README, and Markdown outside the ledger
prefixes) containing a claim word of check_verification_claims (verified, proved, proven,
machine-checked, kernel-checked; a denial passes) or one of the SHAPES below, read off paper's census of
the five Fulcrum overclaims (the 2026-10-19 public-surface census).

DECLARED LIMITS (printed beside every verdict):
  * the reader is a NAME. The gate checks it differs from the author and that the hashes of the sentence
    and of the statement are the ones read; it cannot check that anyone read;
  * it checks that a statement is NAMED and UNCHANGED since the read, never that it is the RIGHT one;
  * the shape lexicon is fixed and was read off the census it is calibrated on; a claim in other words
    is not seen; a sentence the splitter cuts differently hashes differently;
  * ledgers and Lean docstrings are counted, not gated;
  * "a machine-checked result" is not decidable from prose; carrier + shape is a proxy.

Exit: 0 clean, 1 findings, 2 usage or a broken file.
Usage: check_prose_lean.py [--root DIR] [--verbose] [--list-claims] [--self-test]
"""
from __future__ import annotations

import argparse
import hashlib
import os
import re
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import check_verification_claims as aan  # noqa: E402

READS_FILE = ".prose-lean-reads"
BASELINE_FILE = ".prose-lean-baseline"
LEDGERS_FILE = ".prose-lean-ledgers"

# (class, name, regex). Read off the census; needs_word=True means the shape alone is not a claim.
SHAPES = [
    ("1", "log-chowla", re.compile(r"(?i)\b(?:log|logarithmic(?:ally)?)[- ](?:averaged[- ])?(?:two-point[- ])?chowla"), False),
    ("1", "door-only", re.compile(r"(?i)\bdoor-only\b"), False),
    ("2", "weakest", re.compile(r"(?i)\bweakest\b"), False),
    ("2", "proved-minimal", re.compile(r"(?i)\bproved minimal\b|\bminimal(?:ity)?\b[^.]{0,40}\b(?:hypothesis|fulcrum|engine)\b"), False),
    ("3", "strengthened", re.compile(r"(?i)\bstrengthened\b|\band effective\b"), False),
    ("4", "rate-census", re.compile(r"(?i)exchange[- ]rate|neutrality theorem|\bprices? every\b|parity-invariant cone|\bheadline theorems?\b"), False),
    ("5", "vmvt", re.compile(r"(?i)\bVinogradov\b"), True),
]
SHAPES_DECLARED = ("log-Chowla, door-only, weakest, proved-minimal / minimal+hypothesis, strengthened / "
                   "'and effective', exchange-rate / neutrality theorem / prices every / parity-invariant cone / "
                   "headline theorem, Vinogradov (only beside an AAN claim word)")


def sha12(s):
    return hashlib.sha256(s.encode("utf-8")).hexdigest()[:12]


def flat(s):
    return " ".join(s.split())


def is_headline(rel):
    """A headline carrier: a paper (.tex) or a README. Elsewhere only a census SHAPE makes a claim --
    a bare 'proved' in a working doc is the AAN arm's business (README/abstract) and would swamp this one."""
    return rel.endswith(".tex") or os.path.basename(rel).lower().startswith("readme")


def claim_sentences(prose, headline=True):
    """-> [(sentence, [shape names], [claim words])] for the claim sentences of a prose string."""
    out = []
    for sn in aan.sentences(flat(prose)):
        words = [w for w, neg in aan.claim_hits(sn) if not neg]
        shapes = [name for _, name, rx, needs in SHAPES if rx.search(sn) and (not needs or words)]
        if not headline:
            words = []
        if words or shapes:
            out.append((sn, shapes, words))
    return out


def tex_body(text):
    m = re.search(r"\\begin\{document\}(.*?)(?:\\end\{document\}|\Z)", text, re.S)
    body = m.group(1) if m else text
    return aan.strip_comments_tex(body)


def prose_of(rel, text):
    if rel.endswith(".tex"):
        return [tex_body(text)]
    out = []
    for _, b in aan.md_blocks(text):
        b = aan.strip_comments_md(re.sub(r"`[^`]*`", " ", b))
        rest = []
        for line in b.split("\n"):
            if line.lstrip().startswith("#"):
                out.append(line.lstrip("# \t"))      # a heading is its own sentence, not a prefix of the next
            else:
                rest.append(line)
        out.append("\n".join(rest))
    return out


def lean_docstrings(text):
    return re.findall(r"/-[-!](.*?)-/", text, re.S)


def decl_statement(repo, spec):
    """'<path>::<name>' -> (found, statement-or-None). 'found' False = not declared."""
    if "::" not in spec:
        return False, None
    path, name = spec.split("::", 1)
    if path not in repo.fileset or not path.endswith(".lean"):
        return False, None
    text = aan.read(repo.root, path)
    rx = re.compile(r"(?m)^[ \t]*(?:@\[[^\]]*\][ \t]*)?(?:private[ \t]+|protected[ \t]+|noncomputable[ \t]+)*"
                    r"(?:theorem|lemma|def|abbrev|structure|class|inductive|instance)[ \t]+" +
                    re.escape(name) + r"(?![\w.'])")
    m = rx.search(text)
    if not m:
        return False, None
    rest = text[m.start():]
    cut = re.search(r":=|\bwhere\b", rest)
    return True, flat(rest[:cut.start()] if cut else rest[:2000])


def load_tsv(repo, name, ncols):
    path = os.path.join(repo.root, name)
    rows = []
    if not os.path.exists(path):
        return rows
    for i, line in enumerate(aan.read(repo.root, name).split("\n"), 1):
        if not line.strip() or line.startswith("#"):
            continue
        cols = [c.strip() for c in line.split("\t")]
        rows.append((i, cols if len(cols) == ncols else None, line))
    return rows


def scan(root):
    repo = aan.Repo(root)
    ledgers = [c[0] for _, c, _ in load_tsv(repo, LEDGERS_FILE, 1) if c]
    claims = {}                               # (path, sha) -> (sentence, shapes, words, tier)
    stats = {"carriers": 0, "ledger_files": 0, "ledger_claims": 0, "docstring_claims": 0}
    for rel in repo.files:
        low = rel.lower()
        is_carrier = rel.endswith(".tex") or (rel.endswith(".md") and True)
        if rel.endswith(".lean"):
            for ds in lean_docstrings(aan.read(repo.root, rel)):
                stats["docstring_claims"] += len(claim_sentences(ds))
            continue
        if not is_carrier or (rel.endswith(".tex") and os.path.basename(low).startswith("readme")):
            continue
        in_ledger = any(rel.startswith(p) for p in ledgers)
        text = aan.read(repo.root, rel)
        found = 0
        for prose in prose_of(rel, text):
            for sn, shapes, words in claim_sentences(prose, is_headline(rel)):
                found += 1
                if in_ledger:
                    stats["ledger_claims"] += 1
                else:
                    claims[(rel, sha12(sn))] = (sn, shapes, words)
        if in_ledger:
            stats["ledger_files"] += 1
        else:
            stats["carriers"] += 1
    findings = []
    reads = load_tsv(repo, READS_FILE, 8)
    base = load_tsv(repo, BASELINE_FILE, 3)
    read_keys, base_keys = set(), set()
    for i, cols, line in reads:
        if cols is None:
            findings.append((READS_FILE, i, "BAD-RECORD", f"expected 8 TAB columns: {line[:120]}"))
            continue
        rid, path, csha, decl, ssha, author, reader, date = cols
        if not re.fullmatch(r"\d{4}-\d\d-\d\d", date):
            findings.append((READS_FILE, i, "BAD-RECORD", f"{rid}: date {date!r} is not YYYY-MM-DD"))
            continue
        if not reader or reader.casefold() == author.casefold():
            findings.append((READS_FILE, i, "SELF-READ", f"{rid}: reader {reader!r} is the author {author!r}"))
            continue
        found, stmt = decl_statement(repo, decl)
        if not found:
            findings.append((READS_FILE, i, "NO-STATEMENT", f"{rid}: {decl} is not declared in a tracked .lean file"))
            continue
        if sha12(stmt) != ssha:
            findings.append((READS_FILE, i, "STALE-STATEMENT",
                             f"{rid}: {decl} now hashes {sha12(stmt)}, the read was of {ssha} -- the Lean moved"))
            continue
        if (path, csha) not in claims:
            findings.append((READS_FILE, i, "STALE-CLAIM", f"{rid}: no sentence in {path} hashes {csha} -- the prose moved"))
            continue
        read_keys.add((path, csha))
    for i, cols, line in base:
        if cols is None:
            findings.append((BASELINE_FILE, i, "BAD-RECORD", f"expected 3 TAB columns: {line[:120]}"))
            continue
        if (cols[1], cols[0]) not in claims:
            findings.append((BASELINE_FILE, i, "STALE-BASELINE", f"{cols[0]} in {cols[1]}: the sentence is gone -- delete the line"))
            continue
        base_keys.add((cols[1], cols[0]))
    stats["claims"], stats["read"], stats["baselined"] = len(claims), len(read_keys), len(base_keys - read_keys)
    for (path, csha), (sn, shapes, words) in sorted(claims.items()):
        if (path, csha) in read_keys or (path, csha) in base_keys:
            continue
        why = "+".join(shapes + words) or "claim"
        findings.append((path, 0, "UNREAD", f"[{csha}] ({why}) no record names its Lean statement and a non-author reader: {sn[:150]}"))
    return findings, claims, stats, ledgers


def limits(stats, ledgers):
    return [
        f"  population: {stats['carriers']} carrier file(s) (tracked .tex body, README, Markdown outside the ledger prefixes); "
        f"{stats['claims']} claim sentence(s): {stats['read']} READ (record), {stats['baselined']} BASELINED (accepted debt), "
        f"{stats['claims'] - stats['read'] - stats['baselined']} neither",
        f"  shapes: {SHAPES_DECLARED}; claim words: {aan.CLAIM_WORDS_DECLARED}",
        f"  NOT GATED, counted: {stats['ledger_files']} ledger file(s) from {LEDGERS_FILE} with {stats['ledger_claims']} claim sentence(s)"
        f" ({len(ledgers)} prefix(es)); {stats['docstring_claims']} claim sentence(s) in Lean docstrings",
        "  NOT checked: that anyone read (the reader is a name, differing from the author); that the named statement is the RIGHT one "
        "(only that it exists and is unchanged since the read); a claim in words outside the lexicon; a sentence the splitter cut differently",
    ]


def main(argv=None):
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, "reconfigure"):
            stream.reconfigure(encoding="utf-8", errors="replace")
    ap = argparse.ArgumentParser(description="a prose claim about a machine-checked result names its Lean statement")
    ap.add_argument("--root", default=".")
    ap.add_argument("--verbose", action="store_true")
    ap.add_argument("--list-claims", action="store_true", help="print every claim sentence with its sha (to build the baseline)")
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args(argv)
    if a.self_test:
        return self_test()
    findings, claims, stats, ledgers = scan(a.root)
    if a.list_claims:
        for (path, csha), (sn, shapes, words) in sorted(claims.items()):
            print(f"{csha}\t{path}\t{'+'.join(shapes + words)}\t{sn[:200]}")
        return 0
    for rel, line, cls, msg in findings:
        print(f"{rel}:{line}: {cls}: {msg}")
    print(f"check_prose_lean: {'FAIL' if findings else 'OK'} ({len(findings)} finding(s))")
    print("\n".join(limits(stats, ledgers)))
    return 1 if findings else 0


# ---------------------------------------------------------------- self-test

def self_test():
    """Each arm driven red against a planted defect and green against its fix, in a scratch repo;
    the census's own sentences are the mutants."""
    fails, arms = [], 0

    def git(d, *args):
        subprocess.run(["git", "-C", d, *args], check=True, capture_output=True)

    def build(files):
        d = tempfile.mkdtemp(prefix="prose-lean-")
        git(d, "init", "-q")
        for rel, txt in files.items():
            p = os.path.join(d, rel)
            os.makedirs(os.path.dirname(p), exist_ok=True)
            with open(p, "w", encoding="utf-8") as fh:
                fh.write(txt)
        git(d, "add", "-A")
        return d

    def classes(files):
        d = build(files)
        f, _, _, _ = scan(d)
        return sorted({c for _, _, c, _ in f}), f

    def expect(name, files, want):
        nonlocal arms
        arms += 1
        got, f = classes(files)
        if got != sorted(want):
            fails.append(f"{name}: wanted {sorted(want)}, got {got}: {[m[:80] for *_, m in f]}")

    LEAN = "theorem fulcrum_minimal (C : Nat) : C = C := rfl\n"
    stmt = decl_statement(aan.Repo(build({"Salt/Fulcrum.lean": LEAN})), "Salt/Fulcrum.lean::fulcrum_minimal")[1]
    sent_weakest = "The fixed point of that process is the weakest twin-producing Siegel hypothesis in the surveyed record."
    sent_strong = "The second horn is thus the Heath-Brown dichotomy, machine-checked and strengthened."
    sent_chowla = "As a byproduct, the logarithmic two-point Chowla statement is machine-checked conditionally on a single named uniformity hypothesis."
    sent_vmvt = "No public artifact in any proof assistant proves the Vinogradov mean value theorem, and this corpus carries machine-checked proofs of it."
    tex = "\\begin{document}\n" + " ".join([sent_weakest, sent_strong, sent_chowla]) + "\n\\end{document}\n"
    md = "# Results\n\n" + sent_vmvt + "\n"
    base = {"Salt/Fulcrum.lean": LEAN, "papers/main.tex": tex, "docs/RESULTS.md": md}

    def rec(rid, path, sn, decl="Salt/Fulcrum.lean::fulcrum_minimal", ss=None, author="author-a", reader="reader-b", date="2026-10-20"):
        return "\t".join([rid, path, sha12(flat(sn)), decl, ss or sha12(stmt), author, reader, date]) + "\n"

    # every census mutant is refused UNREAD with no record
    expect("census mutants unread", base, ["UNREAD"])
    arms += 1
    _, f = classes(base)
    n_unread = sum(1 for *_, c, _ in f if c == "UNREAD")
    if n_unread != 4:
        fails.append(f"four census sentences must each be UNREAD, saw {n_unread}")
    # a record with right hashes and a different reader clears one sentence
    allrecs = (rec("r1", "papers/main.tex", sent_weakest) + rec("r2", "papers/main.tex", sent_strong) +
               rec("r3", "papers/main.tex", sent_chowla) + rec("r4", "docs/RESULTS.md", sent_vmvt))
    expect("fully read is green", {**base, READS_FILE: allrecs}, [])
    expect("self-read", {**base, READS_FILE: allrecs.replace("\tauthor-a\treader-b\t", "\tauthor-a\tauthor-a\t", 1)}, ["SELF-READ", "UNREAD"])
    expect("no statement", {**base, READS_FILE: allrecs.replace("::fulcrum_minimal", "::absent_thm", 1)}, ["NO-STATEMENT", "UNREAD"])
    moved = {**base, READS_FILE: allrecs, "Salt/Fulcrum.lean": "theorem fulcrum_minimal (C : Nat) : C = C + 0 := rfl\n"}
    expect("lean moved", moved, ["STALE-STATEMENT", "UNREAD"])
    prose_moved = {**base, READS_FILE: allrecs, "papers/main.tex": tex.replace("weakest", "weakest known")}
    expect("prose moved", prose_moved, ["STALE-CLAIM", "UNREAD"])
    expect("bad record", {**base, READS_FILE: "r1\tonly-two\n"}, ["BAD-RECORD", "UNREAD"])
    expect("bad date", {**base, READS_FILE: allrecs.replace("2026-10-20", "yesterday", 1)}, ["BAD-RECORD", "UNREAD"])
    # the baseline ratchet
    bl = "".join(f"{sha12(flat(s))}\t{p}\tcensus\n" for p, s in [("papers/main.tex", sent_weakest), ("papers/main.tex", sent_strong),
                                                              ("papers/main.tex", sent_chowla), ("docs/RESULTS.md", sent_vmvt)])
    expect("baseline makes it green", {**base, BASELINE_FILE: bl}, [])
    expect("baseline does not cover a NEW claim", {**base, BASELINE_FILE: bl,
           "docs/new.md": "This theorem is machine-checked and the weakest possible.\n"}, ["UNREAD"])
    expect("stale baseline", {**base, BASELINE_FILE: bl + "deadbeef0000\tdocs/RESULTS.md\tcensus\n"}, ["STALE-BASELINE"])
    # denials, ledgers and docstrings do not gate
    expect("denial passes", {"docs/a.md": "This is not machine-checked and nothing here is proven.\n"}, [])
    expect("ledger is counted not gated", {"docs/exploration/pilot.md": sent_weakest + "\n", LEDGERS_FILE: "docs/exploration/\n"}, [])
    expect("docstring is counted not gated", {"Salt/A.lean": "/-- the weakest hypothesis, machine-checked -/\ntheorem a : True := trivial\n"}, [])
    expect("vmvt alone is not a claim", {"docs/b.md": "The Vinogradov mean value theorem is a classical bound.\n"}, [])
    expect("correct scoped sentence still needs a read",
           {"docs/c.md": "The classical-exponent Vinogradov bound is machine-checked.\n"}, ["UNREAD"])
    if fails:
        print("check_prose_lean --self-test: FAIL")
        print("\n".join("  " + x for x in fails))
        return 1
    print(f"check_prose_lean --self-test: OK ({arms} arms)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
