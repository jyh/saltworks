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


CODE_SPAN = re.compile(r"`[^`]*`")
# claim phrasings the first census did not need but the non-author read found passing the README carrier;
# a HEADLINE carrier only (in a working doc 'formalization' is a noun, not a claim)
EXTRA_WORDS = re.compile(r"(?i)\bsorry-free\b|\bformali[sz]\w*|\bmechanically[- ]checked\b|\bformally (?:established|verified)\b"
                         r"|\bcertified by the lean kernel\b")
EXTRA_DECLARED = "sorry-free, formaliz*, mechanically checked, formally established/verified, certified by the Lean kernel (headline carriers only)"


# THE SPLITTER (desk O88, 2026-10-21, paris's measurement on x86lean's paper): `aan.sentences` splits only where a
# sentence-ending [.!?] is DIRECTLY followed by whitespace and a capital, and two shapes this gate's own carriers
# write are not that. (1) A TeX source tag rides AFTER its sentence's period -- `claim. \src{docs/X.md 1b} Next
# sentence` -- and ends in `}`, so nothing splits after it: five sentences of a paper were ONE 1,983-character span
# hashed as a single claim. (2) A closing quote after the period, `validation''. Next`, `."`, `.)`: the char before
# the whitespace is the quote, not the period. The `\src{...}` tag stays with the sentence before it, as designed
# (a citation edit moves that sentence's hash, by intent); only the span BOUNDARY moves. LIMITS: a nested brace
# inside a \src tag, a next sentence opening with a macro, `$` or a digit, and an abbreviation inside a quote are
# NOT split here (the same class `aan.sentences` already declines).
_SRC_END = re.compile(r"(\\src\{[^{}]*\})\s+(?=[\"'*_`(\[A-Z])")
_QUOTE_END = re.compile(r"([.!?](?:''|[\"')\]])+)\s+(?=[\"'*_`(\[A-Z])")


def split_sentences(flat_text, legacy=False):
    """aan.sentences, then each span cut again after a \\src{...} tag and after a closing quote that follows a period.
    legacy=True is the splitter as it stood before this fix: the ratchet reads the BASE tree with it, so a baseline row
    keyed on an old fused span can be matched to its text."""
    if legacy:
        return aan.sentences(flat_text)
    out = []
    for frag in aan.sentences(flat_text):
        cuts = sorted({m.end(1) for rx in (_SRC_END, _QUOTE_END) for m in rx.finditer(frag)})
        last = 0
        for c in cuts:
            out.append(frag[last:c].strip())
            last = c
        out.append(frag[last:].strip())
    return [x for x in out if x]


def claim_sentences(prose, headline=True, legacy=False):
    """-> [(sentence, [shape names], [claim words])] for the claim sentences of a prose string.
    The sentence (and so its hash) KEEPS its inline code spans -- a span is the part that names the Lean, so a
    span edited after the read must move the hash. Detection runs on the span-stripped sentence: a span can
    cite, never claim."""
    out = []
    for sn in split_sentences(flat(prose), legacy):
        seen = flat(CODE_SPAN.sub(" ", sn))
        words = [w for w, neg in aan.claim_hits(seen) if not neg]
        if headline:
            words += [m.group(0).lower() for m in EXTRA_WORDS.finditer(seen)]
        shapes = [name for _, name, rx, needs in SHAPES if rx.search(seen) and (not needs or words)]
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
        b = aan.strip_comments_md(b)
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


def lean_mask(text, strings=True):
    """Blank out Lean comments (nested /- -/ and --) and string literals, keeping every newline and offset,
    so a declaration is looked up in CODE and never in a comment or a string."""
    out, i, n, depth = [], 0, len(text), 0
    while i < n:
        two = text[i:i + 2]
        if depth:
            if two == "/-":
                depth += 1; out.append("  "); i += 2; continue
            if two == "-/":
                depth -= 1; out.append("  "); i += 2; continue
            out.append("\n" if text[i] == "\n" else " "); i += 1; continue
        if two == "/-":
            depth = 1; out.append("  "); i += 2; continue
        if two == "--":
            j = text.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i)); i = j; continue
        if text[i] == "'" and re.match(r"'(?:\\.[^']*|[^\\'])'", text[i:i + 8]):
            m = re.match(r"'(?:\\.[^']*|[^\\'])'", text[i:i + 8])
            out.append(m.group(0)); i += len(m.group(0)); continue          # a char literal such as '"' opens no string
        if text[i] == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            j = min(j + 1, n)
            out.append("".join("\n" if c == "\n" else " " for c in text[i:j]) if strings else text[i:j]); i = j; continue
        out.append(text[i]); i += 1
    return "".join(out)


DECL_HEAD = re.compile(r"(?m)^[ \t]*(?:@\[[^\]]*\][ \t]*)*(?:private[ \t]+|protected[ \t]+|noncomputable[ \t]+)*"
                       r"(?:theorem|lemma|def|abbrev|structure|class|inductive|instance)[ \t]+([^\s(:{\[]+)")
NS_LINE = re.compile(r"(?m)^[ \t]*(namespace|section|mutual|end)\b[ \t]*([^\s]*)")


def lean_decls(code):
    """-> [(qualified_name, bare_name, start_offset)] from masked Lean code, tracking namespace/section/end."""
    events = [(m.start(), "ns", m) for m in NS_LINE.finditer(code)] + [(m.start(), "decl", m) for m in DECL_HEAD.finditer(code)]
    stack, out = [], []
    for _, kind, m in sorted(events, key=lambda e: e[0]):
        if kind == "ns":
            word, nm = m.group(1), m.group(2)
            if word == "end":
                if stack:
                    stack.pop()
            else:
                stack.append(nm if word == "namespace" else "")      # section and mutual: anonymous scopes
        else:
            bare = m.group(1)
            prefix = ".".join(x for x in stack if x)
            q = bare[len("_root_."):] if bare.startswith("_root_.") else (prefix + "." + bare if prefix else bare)
            out.append((q, bare, m.start()))
    return out


def stmt_end(code, start):
    """Offset of the first ':=' or 'where' at bracket depth 0 after start (a binder default is inside brackets)."""
    depth, i, n = 0, start, len(code)
    while i < n:
        c = code[i]
        if c in "([{\u27e8":
            depth += 1
        elif c in ")]}\u27e9":
            depth = max(0, depth - 1)
        elif depth == 0 and code.startswith(":=", i):
            return i
        elif depth == 0 and code.startswith("where", i) and not (code[i - 1:i].isalnum() or code[i + 5:i + 6].isalnum()):
            return i
        i += 1
    return min(n, start + 2000)


def decl_statement(repo, spec):
    """'<path>::<name>' -> (state, statement). state: 'found' | 'missing' | 'ambiguous'.
    The name may be bare or namespace-qualified; a bare name matching more than one declaration in its file is
    AMBIGUOUS (the record must then qualify it)."""
    if "::" not in spec:
        return "missing", None
    path, name = spec.split("::", 1)
    if path not in repo.fileset or not path.endswith(".lean"):
        return "missing", None
    raw = aan.read(repo.root, path)
    code = lean_mask(raw)                        # for FINDING declarations: no comments, no strings
    stmt_code = lean_mask(raw, strings=False)    # for HASHING one: a string inside a statement is part of it
    exact = [d for d in lean_decls(code) if d[0] == name]
    hits = exact or [d for d in lean_decls(code) if d[1] == name]
    if not hits:
        return "missing", None
    if len(hits) > 1:
        return "ambiguous", None
    start = hits[0][2]
    return "found", flat(stmt_code[start:stmt_end(code, start)])


def norm_name(n):
    """'Kent.' / 'kent (helm)' / 'KENT' -> kent / kent-helm / kent. An empty or '-' name names no one."""
    return re.sub(r"[^a-z0-9]+", "-", n.casefold()).strip("-")


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
        na, nr = norm_name(author), norm_name(reader)
        if not na:
            findings.append((READS_FILE, i, "BAD-RECORD", f"{rid}: the author {author!r} names no one"))
            continue
        if not nr or nr == na or nr.split("-")[0] == na.split("-")[0]:
            findings.append((READS_FILE, i, "SELF-READ", f"{rid}: reader {reader!r} is the author {author!r}"))
            continue
        state, stmt = decl_statement(repo, decl)
        if state == "ambiguous":
            findings.append((READS_FILE, i, "AMBIGUOUS", f"{rid}: {decl} matches more than one declaration in its file -- qualify it with its namespace"))
            continue
        if state != "found":
            findings.append((READS_FILE, i, "NO-STATEMENT", f"{rid}: {decl} is not declared in code in a tracked .lean file (a comment or string does not count)"))
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


def git_show(root, ref, path):
    r = subprocess.run(["git", "-C", root, "show", f"{ref}:{path}"], capture_output=True)
    return r.stdout.decode("utf-8", "replace") if r.returncode == 0 else None


def rows_of(text, key_cols):
    out = set()
    for line in (text or "").split("\n"):
        if line.strip() and not line.startswith("#"):
            cols = [c.strip() for c in line.split("\t")]
            out.add(tuple(cols[:key_cols]))
    return out


def ratchet(root, base):
    """The baseline and the ledger prefixes may only SHRINK against BASE (the pull request's base ref): an added
    line is refused. Without this the ratchet is a habit of whoever edits the file, not a property of the gate.
    A file absent at BASE is a birth and is allowed once."""
    probe = subprocess.run(["git", "-C", root, "rev-parse", "--verify", "--quiet", f"{base}^{{commit}}"], capture_output=True)
    if probe.returncode != 0:
        print(f"usage: --base {base!r} does not resolve to a commit here -- the ratchet cannot run, and a ratchet "
              f"that cannot run must not print OK (CI needs fetch-depth: 0 and the base ref fetched)", file=sys.stderr)
        sys.exit(2)       # 2 = usage or broken, never 1 (findings): a caller must not read a missing base as findings
    findings = []
    for name, cls, key in ((BASELINE_FILE, "BASELINE-GROWN", 2), (LEDGERS_FILE, "LEDGER-GROWN", 1)):
        old = git_show(root, base, name)
        if old is None:
            continue
        head = aan.read(root, name) if os.path.exists(os.path.join(root, name)) else ""
        seen = set()
        for line in head.split("\n"):
            if line.strip() and not line.startswith("#"):
                row = tuple(c.strip() for c in line.split("\t")[:key])
                if name == BASELINE_FILE and row in seen:
                    findings.append((name, 0, cls, f"{' / '.join(row)} appears twice -- a duplicate row is a second spend of one license"))
                seen.add(row)
        added = sorted(rows_of(head, key) - rows_of(old, key))
        removed = rows_of(old, key) - rows_of(head, key)
        migrated = split_migration(root, base, added, removed) if name == BASELINE_FILE and added and removed else set()
        for row in added:
            if row in migrated:
                continue
            findings.append((name, 0, cls, f"{' / '.join(row)} is not in {base}:{name} -- the file can only shrink"))
    return findings


def split_migration(root, base, added, removed):
    """-> the set of ADDED baseline rows (sha, path) that are a SPLIT of a row the same change REMOVES (desk O88, the
    splitter fix). An added row is allowed only if its hash is a PIECE the new splitter cuts a REMOVED row's span
    into: the span is the sentence that row's hash named at BASE, read from the BASE tree's own text with the
    splitter as it stood (`legacy`) -- derived, never typed. A new claim is not a piece of an old span, and a
    sentence that merely APPEARS inside a removed span (a quotation, a half-sentence) is not a piece either, so both
    are still refused; so is a piece of a row the change KEEPS. LIMIT: this proves the added text existed inside a removed span, not that
    the removed span was acceptable debt: that was the baseline's own birth decision, unchanged here."""
    claims = scan(root)[1]
    old_text = {}                                   # (path, sha) -> the sentence at BASE
    head_by_path = {}                               # path -> the flat prose blocks of the HEAD file
    for path in {p for _, p in removed}:
        text = git_show(root, base, path)
        if text is None:
            continue
        want = {sh for sh, p in removed if p == path}
        head_prose = [flat(x) for x in prose_of(path, aan.read(root, path))] if os.path.exists(os.path.join(root, path)) else []
        head_by_path[path] = head_prose
        for prose in prose_of(path, text):
            for sn, _, _ in claim_sentences(prose, is_headline(path), legacy=True):
                # the removed span must be INTACT at HEAD: a migration moves cut points and never removes or edits text
                # (systems' A1/A2: delete the qualifier half, or edit the span, and baseline what is left)
                if sha12(sn) in want and any(flat(sn) in hp for hp in head_prose):
                    old_text[(path, sha12(sn))] = flat(sn)
    pieces = {}                                      # path -> the shas of every PIECE the new splitter cuts those spans into
    for (path, _), span in old_text.items():
        pieces.setdefault(path, set()).update(sha12(x) for x in split_sentences(span))
    out = set()
    for sh, path in added:
        if sh not in pieces.get(path, ()) or (path, sh) not in claims:
            continue
        # systems' A6/A7: the baseline keys on (path, sha), so a migrated piece licenses EVERY copy of its text in the
        # file. Allow it only if every occurrence of the piece in the head prose lies INSIDE an intact removed span:
        # the piece's total occurrences must equal its occurrences within those spans (a span counted once per place
        # it occurs at HEAD). A bare copy elsewhere, or beside a never-rendered copy of the span, makes the totals differ.
        piece = flat(claims[(path, sh)][0])
        hp = head_by_path.get(path, [])
        total = sum(b.count(piece) for b in hp)
        inside = sum(sum(b.count(span) for b in hp) * span.count(piece) for (p, _), span in old_text.items() if p == path)
        if total == inside:
            out.add((sh, path))
    return out


def limits(stats, ledgers):
    return [
        f"  population: {stats['carriers']} carrier file(s) (tracked .tex body, README, Markdown outside the ledger prefixes); "
        f"{stats['claims']} claim sentence(s): {stats['read']} READ (record), {stats['baselined']} BASELINED (accepted debt), "
        f"{stats['claims'] - stats['read'] - stats['baselined']} neither",
        f"  shapes: {SHAPES_DECLARED}; claim words: {aan.CLAIM_WORDS_DECLARED}",
        f"  NOT GATED, counted: {stats['ledger_files']} ledger file(s) from {LEDGERS_FILE} with {stats['ledger_claims']} claim sentence(s)"
        f" ({len(ledgers)} prefix(es)); {stats['docstring_claims']} claim sentence(s) in Lean docstrings",
        "  RATCHET: the baseline and the ledger prefixes are diffed against the pull request's base only when --base is given "
        "(CI on a pull_request); a direct push to the default branch is NOT diffed, and branch protection is what closes that",
        f"  also a claim in a headline carrier: {EXTRA_DECLARED}; a bare 'machine-checked' in a working doc outside a headline carrier is NOT a claim, by design",
        "  A PR THAT TOUCHES check_prose_lean.py RUNS ITS OWN CHECKER IN CI, so the ratchet cannot bind a change to the checker itself: "
        "such a PR is reviewed by its diff, and the five repos' copies stay ONE blob",
        "  A BASELINE ROW LICENSES EVERY COPY of its sentence in that file (it keys on path + hash): a baselined sentence copied elsewhere in "
        "its own file stays green, with or without a migration; and TeX that never renders (\\iffalse, a comment environment) counts as prose, "
        "because only % comments are stripped. Both are older than the migration arm and are declared here, not fixed here",
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
    ap.add_argument("--base", help="git ref of the pull request's base: refuse an added baseline line or ledger prefix")
    ap.add_argument("--list-claims", action="store_true", help="print every claim sentence with its sha (to build the baseline)")
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args(argv)
    if a.self_test:
        return self_test()
    findings, claims, stats, ledgers = scan(a.root)
    if a.base:
        findings += ratchet(a.root, a.base)
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
            with open(p, "w", encoding="utf-8", newline="") as fh:
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
    # ---- the non-author read of PR 370 (F1-F4 and the minors), each a mutant
    def sentence_rec(rid, path, sn, decl, ss, author="author-a", reader="reader-b"):
        ssh = ss if re.fullmatch(r"[0-9a-f]{12}", ss) else sha12(ss)
        return "\t".join([rid, path, sha12(flat(sn)), decl, ssh, author, reader, "2026-10-20"]) + "\n"

    def lean_stmt(files, spec):
        return decl_statement(aan.Repo(build(files)), spec)[1]

    # F2: an inline code span is part of the hashed sentence
    rd = "A machine-checked proof of `Dich = TPC ∨ NoSiegelZeros`, conditional on one hypothesis.\n"
    rd_moved = rd.replace(" ∨ NoSiegelZeros", "")
    st = lean_stmt({"A.lean": LEAN}, "A.lean::fulcrum_minimal")
    recd = sentence_rec("f2", "README.md", rd.strip(), "A.lean::fulcrum_minimal", st)
    expect("F2 span-in-hash: unmoved is green", {"A.lean": LEAN, "README.md": rd, READS_FILE: recd}, [])
    expect("F2 span edited after the read", {"A.lean": LEAN, "README.md": rd_moved, READS_FILE: recd}, ["STALE-CLAIM", "UNREAD"])
    # F3: a binder default does not end the statement
    bd = "theorem probe (k : Nat := 3) (n : Nat) : n + k = k + n := by omega\n"
    bd2 = bd.replace("n + k = k + n", "n + k = n + k")
    sb = lean_stmt({"B.lean": bd}, "B.lean::probe")
    ok = isinstance(sb, str) and "n + k = k + n" in sb
    arms += 1
    if not ok:
        fails.append(f"F3 statement must reach the conclusion past a binder default, got {sb!r}")
    sent = "This is machine-checked."
    recb = sentence_rec("f3", "README.md", sent, "B.lean::probe", sb)
    expect("F3 conclusion edited after the read", {"B.lean": bd2, "README.md": sent + "\n", READS_FILE: recb}, ["STALE-STATEMENT", "UNREAD"])
    # F4: comments, strings and namespaces
    expect("F4a declared only in a block comment", {"C.lean": "/-\ntheorem ghost : True := trivial\n-/\n", "README.md": sent + "\n",
           READS_FILE: sentence_rec("f4a", "README.md", sent, "C.lean::ghost", "0" * 12)}, ["NO-STATEMENT", "UNREAD"])
    expect("F4d declared only in a string", {"C.lean": 'def s := "\ntheorem ghost : True := trivial\n"\n', "README.md": sent + "\n",
           READS_FILE: sentence_rec("f4d", "README.md", sent, "C.lean::ghost", "0" * 12)}, ["NO-STATEMENT", "UNREAD"])
    live = "-- theorem probe : 1 = 1 := rfl\ntheorem probe : 2 = 2 := rfl\n"
    sl = lean_stmt({"D.lean": live}, "D.lean::probe")
    arms += 1
    if sl is None or "2 = 2" not in sl:
        fails.append(f"F4b the live statement must be hashed, not the commented-out copy: {sl!r}")
    recl = sentence_rec("f4b", "README.md", sent, "D.lean::probe", sl)
    expect("F4b live edited, comment above untouched", {"D.lean": live.replace("2 = 2", "2 = 3"), "README.md": sent + "\n", READS_FILE: recl},
           ["STALE-STATEMENT", "UNREAD"])
    two = "namespace A\ntheorem probe : 1 = 1 := rfl\nend A\nnamespace B\ntheorem probe : 2 = 2 := rfl\nend B\n"
    expect("F4c bare name matching two declarations", {"E.lean": two, "README.md": sent + "\n",
           READS_FILE: sentence_rec("f4c", "README.md", sent, "E.lean::probe", "0" * 12)}, ["AMBIGUOUS", "UNREAD"])
    sa = lean_stmt({"E.lean": two}, "E.lean::A.probe")
    expect("F4c qualified name reads the right one and survives an edit to the other",
           {"E.lean": two.replace("2 = 2", "2 = 4"), "README.md": sent + "\n", READS_FILE: sentence_rec("f4c2", "README.md", sent, "E.lean::A.probe", sa)}, [])
    # minors: the author/reader comparison and an empty author
    recs = sentence_rec("m1", "README.md", sent, "A.lean::fulcrum_minimal", st)
    for label, rdr in (("trailing dot", "author-a."), ("parenthesised role", "author-a (helm)"), ("case", "AUTHOR-A")):
        expect(f"self-read via {label}", {"A.lean": LEAN, "README.md": sent + "\n",
               READS_FILE: sentence_rec("m1", "README.md", sent, "A.lean::fulcrum_minimal", st, reader=rdr)}, ["SELF-READ", "UNREAD"])
    expect("empty author", {"A.lean": LEAN, "README.md": sent + "\n",
           READS_FILE: sentence_rec("m2", "README.md", sent, "A.lean::fulcrum_minimal", st, author="-")}, ["BAD-RECORD", "UNREAD"])
    # lexicon: phrasings the read found passing the README carrier
    for ph in ("A sorry-free Lean proof of the bound.", "The dichotomy is formally established in Lean.", "Every step is mechanically checked."):
        expect(f"README phrasing: {ph[:30]}", {"README.md": ph + "\n"}, ["UNREAD"])
    expect("the same phrasing in a working doc is not a claim", {"docs/w.md": "A sorry-free Lean proof of the bound.\n"}, [])
    # F1: the baseline and the ledger prefixes only shrink against the base
    def ratchet_case(base_files, head_files):
        d = build(base_files)
        git(d, "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "-m", "base")
        for rel, txt in head_files.items():
            with open(os.path.join(d, rel), "w", encoding="utf-8", newline="") as fh:
                fh.write(txt)
        git(d, "add", "-A")
        return sorted({c for _, _, c, _ in ratchet(d, "HEAD")})

    bl0 = f"{sha12('old claim')}\tREADME.md\tpredates\n"
    bl1 = bl0 + f"{sha12('new claim')}\tREADME.md\tpredates\n"
    nm = {BASELINE_FILE: bl0, LEDGERS_FILE: "docs/exploration/\n"}
    for name, head, want in (
            ("F1 a baseline line added", {BASELINE_FILE: bl1}, ["BASELINE-GROWN"]),
            ("F1 a ledger prefix added", {LEDGERS_FILE: "docs/exploration/\npapers/new/\n"}, ["LEDGER-GROWN"]),
            ("F1 a baseline line removed (shrink)", {BASELINE_FILE: ""}, []),
            ("F1 a class edit only", {BASELINE_FILE: bl0.replace("predates", "shape")}, []),
            ("F1 unchanged", {}, [])):
        arms += 1
        got = ratchet_case(nm, head)
        if got != want:
            fails.append(f"{name}: wanted {want}, got {got}")
    arms += 1
    if ratchet_case({"x": "1"}, {BASELINE_FILE: bl1, LEDGERS_FILE: "docs/\n"}):
        fails.append("F1 a file absent at the base is a birth and must be allowed once")
    # ---- the second read (N1-N4)
    d = build({"x": "1"})
    arms += 1
    try:
        ratchet(d, "origin/nonexistent")
        fails.append("N1 an unresolvable --base must refuse, not print OK")
    except SystemExit as e:
        if e.code != 2:
            fails.append(f"N1 an unresolvable --base must exit 2 (usage/broken), got {e.code!r}")
    sq = 'theorem q (h : s = "abc") : True := trivial\n'
    s1 = lean_stmt({"S.lean": sq}, "S.lean::q")
    s2 = lean_stmt({"S.lean": sq.replace("abc", "abcd")}, "S.lean::q")
    arms += 1
    if s1 == s2:
        fails.append("N2 a string literal inside a statement must be part of the hash")
    ch = "def q : Char := '\"'\ndef r : String := \"\ntheorem ghost : True := trivial\n\"\n"
    expect("N3 char literal does not open a string", {"T.lean": ch, "README.md": sent + "\n",
           READS_FILE: sentence_rec("n3", "README.md", sent, "T.lean::ghost", "0" * 12)}, ["NO-STATEMENT", "UNREAD"])
    mu = "namespace Outer\nnamespace A\nmutual\ntheorem u : True := trivial\nend\ntheorem probe : 1 = 1 := rfl\nend A\nend Outer\n"
    sm = lean_stmt({"M.lean": mu}, "M.lean::Outer.A.probe")
    arms += 1
    if sm is None:
        fails.append("N4 a `mutual ... end` must not pop the enclosing namespace")
    # ---- THE SPLITTER (desk O88, 2026-10-21): the shapes paris measured on x86lean's paper, red against the old split
    def n_claims(files):
        return len(scan(build(files))[1])

    ca, cb = "The first result is machine-checked in Lean.", "The second result is machine-checked in Lean."
    texf = lambda body: {"paper/p.tex": "\\begin{document}\n" + body + "\n\\end{document}\n"}
    # S1 a \src tag rides after its sentence's period and ends in `}`: it is a boundary
    arms += 1
    if n_claims(texf(ca + " \\src{docs/X.md 1b} " + cb + " \\src{docs/Y.md 2}")) != 2:
        fails.append("S1 a sentence after a \\src{...} tag must be its own claim, not fused into the one before it")
    # S2 a closing quote after the period (TeX `''`, ASCII `"`) and a closing bracket are boundaries
    for label, q in (("tex quote", "''"), ("ascii quote", '"'), ("paren", ")")):
        arms += 1
        if n_claims(texf(ca[:-1] + "." + q + " " + cb)) != 2:
            fails.append(f"S2 {label}: a sentence after a closing {label} must be its own claim")
    # S3 the \src tag stays WITH the sentence before it: editing the tag moves THAT sentence's hash and no other
    def hashes(files):
        return {k[1] for k in scan(build(files))[1]}
    h1 = hashes(texf(ca + " \\src{docs/X.md 1b} " + cb))
    h2 = hashes(texf(ca + " \\src{docs/X.md 1c} " + cb))
    arms += 1
    if len(h1 & h2) != 1 or len(h1) != 2:
        fails.append(f"S3 a \\src edit must move exactly the sentence it rides with: {sorted(h1)} vs {sorted(h2)}")
    # S4 CONTROLS: an abbreviation and a plain one-sentence paragraph are not over-split
    arms += 1
    if n_claims(texf("It is machine-checked, e.g. in the Lean kernel, and nothing else.")) != 1:
        fails.append("S4 a sentence with an inner 'e.g.' must stay ONE claim")

    # ---- THE MIGRATION ARM of the ratchet: a split of a REMOVED baseline row is allowed, nothing else is
    fused = texf(ca + " \\src{docs/X.md 1b} " + cb)
    def old_hash_of_fused():
        t = fused["paper/p.tex"]
        prose = next(iter(prose_of("paper/p.tex", t)))
        return sha12([sn for sn, _, _ in claim_sentences(prose, is_headline("paper/p.tex"), legacy=True)][0])
    hf = old_hash_of_fused()
    hnew = sorted(hashes(fused))
    bl_fused = f"{hf}\tpaper/p.tex\tpredates\n"
    bl_split = "".join(f"{h}\tpaper/p.tex\tpredates\n" for h in hnew)
    bl_extra = bl_fused + f"{hnew[0]}\tpaper/p.tex\tpredates\n"
    arms += 1
    if len(hnew) != 2 or hf in hnew:
        fails.append("M0 the fixture must be a fused span under the old split and two claims under the new")
    for name, head_bl, want in (
            ("M1 a fused row replaced by its split pieces is a MIGRATION", bl_split, []),
            ("M2 an unrelated added row is still refused", bl_split + f"{sha12('a brand new claim')}\tpaper/p.tex\tpredates\n", ["BASELINE-GROWN"]),
            ("M3 a sub-span row added while the fused row is KEPT is still refused", bl_extra, ["BASELINE-GROWN"]),
            ("M4 a row for a path whose base row was not removed is still refused", bl_split.replace("paper/p.tex", "paper/q.tex"), ["BASELINE-GROWN"])):
        arms += 1
        got = ratchet_case({BASELINE_FILE: bl_fused, **fused}, {BASELINE_FILE: head_bl})
        if got != want:
            fails.append(f"{name}: wanted {want}, got {got}")
    # systems' attacks A1, A2, A5 (desk O88): the migration moves cut points and never removes or edits text
    arms += 1
    edit = texf(ca + " \\src{docs/X.md 1b} " + cb.replace("second", "second, unconditional,"))
    got = ratchet_case({BASELINE_FILE: bl_fused, **fused}, {BASELINE_FILE: "".join(f"{h}\tpaper/p.tex\tpredates\n" for h in sorted(hashes(edit))), **edit})
    if got != ["BASELINE-GROWN"]:
        fails.append(f"A1 an EDITED removed span must not migrate: {got}")
    arms += 1
    dropq = texf(cb)
    got = ratchet_case({BASELINE_FILE: bl_fused, **fused}, {BASELINE_FILE: f"{sorted(hashes(dropq))[0]}\tpaper/p.tex\tpredates\n", **dropq})
    if got != ["BASELINE-GROWN"]:
        fails.append(f"A2 deleting the qualifier half of a removed span and baselining the rest must be refused: {got}")
    arms += 1
    two = {**fused, "paper/q.tex": fused["paper/p.tex"]}
    got = ratchet_case({BASELINE_FILE: bl_fused, **two}, {BASELINE_FILE: "".join(f"{h}\tpaper/q.tex\tpredates\n" for h in hnew)})
    if got != ["BASELINE-GROWN"]:
        fails.append(f"A5a a removed row in file A must not license rows in file B: {got}")
    arms += 1
    got = ratchet_case({BASELINE_FILE: bl_fused, **fused}, {BASELINE_FILE: bl_split + bl_split})
    if got != ["BASELINE-GROWN"]:
        fails.append(f"A5b a duplicate row (one license spent twice) must be refused: {got}")
    arms += 1
    if not any("TOUCHES check_prose_lean.py" in x for x in limits({"carriers": 0, "claims": 0, "read": 0, "baselined": 0, "ledger_files": 0, "ledger_claims": 0, "docstring_claims": 0}, [])):
        fails.append("A4 the limits line must say a PR touching the checker is reviewed by its diff")
    # systems' A6 and A7 (blob 820e3b8ee95a FAIL): a bare copy of a migrated piece must not ride in on the migration
    bare = cb
    a6 = texf(ca + " \\src{docs/X.md 1b} " + cb + "\n\n" + bare)
    arms += 1
    got = ratchet_case({BASELINE_FILE: bl_fused, **fused}, {BASELINE_FILE: "".join(f"{h}\tpaper/p.tex\tpredates\n" for h in sorted(hashes(a6))), **a6})
    if got != ["BASELINE-GROWN"]:
        fails.append(f"A6 an intact span migrated AND its claim piece copied alone elsewhere in the file must be refused: {got}")
    a7 = texf("\\iffalse " + ca + " \\src{docs/X.md 1b} " + cb + " \\fi\n\n" + bare)
    arms += 1
    got = ratchet_case({BASELINE_FILE: bl_fused, **texf("\\iffalse " + ca + " \\src{docs/X.md 1b} " + cb + " \\fi")}, {BASELINE_FILE: "".join(f"{h}\tpaper/p.tex\tpredates\n" for h in sorted(hashes(a7))), **a7})
    if got != ["BASELINE-GROWN"]:
        fails.append(f"A7 the intact span inside \\iffalse and its claim piece in the visible prose must be refused: {got}")
    arms += 1
    if not any("LICENSES EVERY COPY" in x for x in limits({"carriers": 0, "claims": 0, "read": 0, "baselined": 0, "ledger_files": 0, "ledger_claims": 0, "docstring_claims": 0}, [])):
        fails.append("A6b the limits line must declare that a baseline row licenses every copy of its sentence and that \\iffalse counts as prose")
    # M5 (systems' A3) the removed span stays INTACT at HEAD and a NEW standalone sentence that merely APPEARS inside it is added: still refused
    quoted = "Note that the claim is machine-checked in Lean proves nothing."
    inner = "Note that the claim is machine-checked in Lean"
    arms += 1
    got = ratchet_case({BASELINE_FILE: f"{sha12(quoted)}\tpaper/p.tex\tpredates\n", **texf(quoted)},
                       {BASELINE_FILE: f"{sha12(inner)}\tpaper/p.tex\tpredates\n", **texf(quoted + "\n\n" + inner)})
    if got != ["BASELINE-GROWN"]:
        fails.append(f"M5 a sentence that only appears inside a removed span must be refused: {got}")
    if fails:
        print("check_prose_lean --self-test: FAIL")
        print("\n".join("  " + x for x in fails))
        return 1
    print(f"check_prose_lean --self-test: OK ({arms} arms)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
