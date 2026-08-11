#!/usr/bin/env python3
"""
# prose_rot: ignore-start  (this docstring quotes every banned phrase verbatim)
claim_fence.py — the claim fence, RUNNABLE, against any text.

    python3 docs/ledger-tools/claim_fence.py <file> [...]
    python3 docs/ledger-tools/claim_fence.py --list
    python3 docs/ledger-tools/claim_fence.py --selftest
    gh api repos/<o>/<r>/contents/<p> --jq .content | base64 -d > /tmp/d.md
      && python3 docs/ledger-tools/claim_fence.py /tmp/d.md

EVIDENCE seat, 2026-08-10 18:2x. Built to discharge a defect of this seat's own,
caught the same hour it charged another seat with the identical class.

⛔ WHY IT EXISTS -----------------------------------------------------------------

This seat published "NINE PHRASES, ZERO HITS" four times on 2026-08-10 — at
11:07, twice at 17:57 (one of them the SUBMISSION CLEARANCE, its most
load-bearing post of the day), and by reference in the 18:13 handoff.

IT WAS EXECUTING SEVEN.

The measurement was sound: every phrase it did check read zero at the published
blob, and that clearance stands. The COUNT was wrong, and it was wrong because
the list lived in this seat's memory instead of in an artifact. Forty minutes
before, this seat had told the math seat that "a count is only re-verifiable if
its EXTRACTOR ships with it" — while carrying a bare number with no extractor.

So the canon is HERE, the count is len(BANNED), and no hand ever types it again.

⚖️ WHAT THIS TOOL CAN AND CANNOT DO. It reads TEXT. It cannot read a talk, a
meeting, or a sentence said at a dinner — the surfaces where "verified silicon"
is actually born. A green means "these N phrases are absent from THIS text". It
is not an approval, this seat holds no T1 authority, and a fence that clears a
draft says nothing about the version that gets spoken.

EXIT 0 = clean · 1 = findings · 2 = could not run
# prose_rot: ignore-end
"""
import re
import sys
import pathlib

# ---- THE CANON. The count is len(BANNED) — never a remembered number. -------
# Each entry: (phrase, rule, why it is banned, the qualified form that is fine)
# prose_rot: ignore-start  (the table IS the description)
BANNED = [
    ("verified silicon", "F4",
     "the die is 39% kernel-emitted flops; the rest is hand RTL",
     "'a verified MAC core on unverified silicon' / name the proved part"),
    ("verified learning", "F6",
     "no training loop has been verified at any tier",
     "state which of the 3 earn-tiers is met, or drop the word"),
    ("every step", "F3",
     "quantifies over a chain whose later links are unproved",
     "'every step OF THE COMBINATIONAL CORE', with the excluded parts named"),
    ("down to silicon", "F3",
     "the model-vs-artifact gap: a Lean proof is about a model",
     "'down to the emitted netlist' — which IS proved, by SAT"),
    ("inside the Lean kernel", "F3",
     "attaches kernel authority to things the kernel never read",
     "name the theorem and the file:line the kernel checked"),
    ("forecasts weather", "F7",
     "GraphCast work is public-paper-only; this chip forecasts nothing",
     "cite the public paper; say what was NOT carried across"),
    ("preserves the count", "F4",
     "a parts-are-not-a-product claim about an unproved composition",
     "state it of the specific lemma that proves it, with its name"),
]
# prose_rot: ignore-end

# ---- the WHEN-DRIVEN read: whole-neuron sentences need a driven-ness clause --
# prose_rot: ignore-start
WHOLE_NEURON = re.compile(
    r"\b(a\s+neuron|the\s+neuron|whole\s+neuron|a\s+neural\s+network|"
    r"the\s+network|end[- ]to[- ]end)\b", re.I)
WHEN_DRIVEN = re.compile(
    r"\b(when\s+driven|while\s+driven|given\s+a\s+driven|under\s+the\s+"
    r"schedule|on\s+the\s+schedule\s+class|for\s+the\s+rounds\s+certified)\b", re.I)
# prose_rot: ignore-end


def _pat(phrase):
    """⛔ WORD-BOUNDED, and the fixture is why.

    The first version matched bare substrings, so "un|verified silicon" —
    THE EXACT QUALIFIED FORM THIS FENCE RECOMMENDS — tripped its own ban. A
    fence that rejects the language it prescribes trains people to ignore it.
    Caught by the positive-control fixture, not by reading.
    """
    return r"\b" + re.escape(phrase) + r"\b"


def strip_comments(text, suffix):
    """Structured configs carry the fence's OWN documentation in comments.

    info.yaml's comments quote "verified silicon" to explain why it is banned —
    the carrier class, ninth instance in this seat's bank. The published CLAIM
    of a yaml is its FIELDS; its comments are documentation and are rendered
    nowhere. Markdown gets no stripping: there, prose IS the claim.
    Returns (text, n_lines_dropped) so the exclusion can be PRINTED.
    """
    if suffix not in (".yaml", ".yml"):
        return text, 0
    keep, dropped = [], 0
    for line in text.splitlines():
        if line.lstrip().startswith("#"):
            dropped += 1
            continue
        keep.append(re.sub(r"\s+#.*$", "", line))
    return "\n".join(keep), dropped


def check_text(text):
    flat = " ".join(text.split())
    hits = []
    for phrase, rule, why, ok in BANNED:
        n = len(re.findall(_pat(phrase), flat, re.I))
        if n:
            for m in re.finditer(_pat(phrase), flat, re.I):
                ctx = flat[max(0, m.start() - 60):m.end() + 60]
                hits.append((phrase, rule, why, ok, ctx))
    # whole-neuron sentences lacking a driven-ness qualifier
    neuron = []
    for sent in re.split(r"(?<=[.!?])\s+", flat):
        if WHOLE_NEURON.search(sent) and not WHEN_DRIVEN.search(sent):
            neuron.append(sent.strip()[:150])
    return hits, neuron


def report(paths):
    files = [pathlib.Path(p) for p in paths]
    for f in files:
        if not f.is_file():
            print(f"claim_fence: no such file: {f}", file=sys.stderr)
            sys.exit(2)
    print("=" * 74)
    print("CLAIM FENCE — runnable, against text only")
    print("=" * 74)
    print(f"CANON      {len(BANNED)} banned phrases, emitted by len(BANNED).")
    print("           ⛔ This seat published 'nine' four times while running")
    print("              seven. The number now comes from the artifact.")
    print(f"SCOPE      {len(files)} file(s). TEXT ONLY — a talk, a meeting and a")
    print("           dinner sentence are all UNREACHABLE by this tool, and they")
    print("           are where the banned phrases are actually born.")
    print("NOT        an approval. This seat holds no T1 authority and wants none.")
    rc = 0
    for f in files:
        body, dropped = strip_comments(f.read_text(errors="replace"), f.suffix)
        hits, neuron = check_text(body)
        print("-" * 74)
        print(f"{f}")
        if dropped:
            print(f"  EXCLUDED {dropped} comment line(s) — a config's CLAIM is its")
            print("           fields; its comments carry this fence's own wording.")
            print("           Printed because an exclusion never announces itself.")
        if hits:
            rc = 1
            for phrase, rule, why, ok, ctx in hits:
                print(f"  ⛔ [{rule}] \"{phrase}\"")
                print(f"       why banned : {why}")
                print(f"       instead    : {ok}")
                print(f"       context    : …{ctx}…")
        else:
            print(f"  ✅ none of the {len(BANNED)} banned phrases present")
        if neuron:
            rc = 1
            print(f"  ⚠️  {len(neuron)} whole-neuron sentence(s) with NO when-driven "
                  f"clause:")
            for s in neuron[:5]:
                print(f"       · {s}")
        else:
            print("  ✅ no unqualified whole-neuron sentence")
    print("-" * 74)
    print("⚖️  A GREEN IS ABOUT THIS TEXT. It is not about the version that gets")
    print("    spoken, and it is not permission to say anything.")
    sys.exit(rc)


def selftest():
    ok = True
    # prose_rot: ignore-start  (fixtures quote the specimens)
    cases = [
        ("We put a neural network on verified silicon.", True, "banned phrase"),
        ("A verified MAC core on unverified silicon.", False, "qualified form"),
        ("VERIFIED SILICON", True, "uppercase — the case class"),
        ("verified\nsilicon", True, "line-wrapped — the hard-wrap class"),
        ("The neuron computes a dot product.", True, "whole-neuron, no clause"),
        ("The neuron computes a dot product when driven.", False, "qualified"),
    ]
    # prose_rot: ignore-end
    for text, want, why in cases:
        h, n = check_text(text)
        got = bool(h or n)
        if got != want:
            ok = False
        print(f"  {'ok ' if got == want else 'FAIL'} flagged={got!s:<5} "
              f"want={want!s:<5} {why}")
    print(f"  ok  canon size emitted from the artifact: {len(BANNED)}")
    print("SELFTEST", "PASS" if ok else "FAIL")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    a = sys.argv[1:]
    if not a:
        print(__doc__.split("EXIT")[0])
        sys.exit(2)
    if a[0] == "--selftest":
        selftest()
    if a[0] == "--list":
        print(f"{len(BANNED)} banned phrases:")
        for p, r, w, o in BANNED:
            print(f"  [{r}] {p!r}\n        why: {w}\n        instead: {o}")
        sys.exit(0)
    report(a)
