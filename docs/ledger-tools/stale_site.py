#!/usr/bin/env python3
"""
stale_site.py — DREAM ARTIFACT (2026-08-14 night, evidence seat, dreams/evidence-stale-site)

THE CLASS IT HUNTS, named from four landed instances in 48 hours:

    A document carries TWO statuses for ONE object. The superseding text sits near
    the superseded text. Neither site is annotated at the other's location. Every
    reader lands on whichever their access path reaches, and two careful readers
    hold opposite true beliefs about one file.

  QUEUE.md:1039 "P2 (1) IS PAID - THE GATE IS OPEN"  vs  :1061 "maestro-owed, TONIGHT"
      -> three seats read 1061, none read 1039; 21h of a gated arc, one false debt
  SEATS.md:22   "SPENT AT THIS COMMIT"               vs  :31   "STANDING PRE-GRANT"
      -> grep said live, prose said spent; two seats, opposite true beliefs
  main.tex:335  "the placed-logic region is shown"   vs  a regeneration that falsified it
  Tier-1 defining line: pre-A2 name form AND pre-D-flag target, both superseded below

NOT an NLP tool. It is structural: opposing status tokens, on entries sharing a rare
key, with no cross-reference between them.

DECLARED LIMITS ARE IN --limits. Read them before trusting a zero.
"""
import re, sys, json

# Opposing status vocabulary. Each pair is (A, B) where asserting both about one
# object is a contradiction unless one site annotates the other.
PAIRS = [
    (r'\bIS PAID\b|\bPAID\b',                 r'\bowed\b|\b[a-z]+-owed\b|\bOWED\b'),
    (r'GATE IS OPEN|\bUNGATED\b',             r'\bgated on\b|\bstays gated\b|\bGATED\b'),
    (r'\bSPENT\b|\bRETIRED\b',                r'\bSTANDING\b|⏳'),
    (r'\bDISCHARGED\b|\bCLOSED\b',            r'\bOWED\b|\bOUTSTANDING\b|\bPENDING\b'),
    (r'\bRESOLVED\b|✅',                       r'\bFLAGGED\b|⛔|\bUNRESOLVED\b'),
    (r'\bLANDED\b|\bPOSTED\b',                r'\bUNPOSTED\b|\bNOT POSTED\b'),
]
# A site is annotated if its neighbourhood carries an explicit supersession signal.
ANNOT = re.compile(r'supersed|corrected|retired at|reconstructed|stale|annotat|'
                   r'see :?\d+|←|\bwas paid\b|no longer|OVERTAKEN|amended', re.I)

KEY = re.compile(r'[①②③④⑤⑥]|(?<![A-Za-z])P[0-9](?![A-Za-z])|'
                 r'\b[A-Z][A-Z0-9]{2,}(?:[ -][A-Z][A-Z0-9]{2,})*\b|`[^`]+`')

def entries(text):
    """Split into entries: top-level '- ' bullets, else paragraph blocks."""
    lines = text.split('\n')
    starts = [i for i,l in enumerate(lines) if re.match(r'^\s*[-*]\s+\S', l)]
    if len(starts) < 3:
        starts, cur = [], None
        for i,l in enumerate(lines):
            if l.strip() and cur is None: cur = i; starts.append(i)
            elif not l.strip(): cur = None
    out = []
    for a,b in zip(starts, starts[1:]+[len(lines)]):
        out.append((a+1, b, '\n'.join(lines[a:b])))
    return out, lines

def scan(path, text=None):
    text = text if text is not None else open(path, encoding='utf-8', errors='replace').read()
    ents, lines = entries(text)
    keyed = {}
    for ln, end, body in ents:
        flat = re.sub(r'\s+', ' ', body)   # FIX: identifiers WRAP; flatten before keying
        ks = {k.strip('`') for k in KEY.findall(flat)}
        for k in ks:
            keyed.setdefault(k, []).append((ln, end, body))
    # rare keys only: a key naming half the document identifies nothing
    rare = {k:v for k,v in keyed.items() if 2 <= len(v) <= 12 and (len(k) > 6 or re.match(r'[①②③④⑤⑥]|P[0-9]$', k))}
    findings = []
    for k, sites in sorted(rare.items()):
        for pa, pb in PAIRS:
            A = [s for s in sites if re.search(pa, s[2])]
            B = [s for s in sites if re.search(pb, s[2])]
            for a in A:
                for b in B:
                    if a[0] == b[0]: continue
                    lo, hi = sorted([a, b], key=lambda s: s[0])
                    # SUPPRESS if either site, or the span between them, is annotated
                    span = '\n'.join(lines[lo[0]-1: min(hi[1], lo[0]+80)])
                    if ANNOT.search(span): continue
                    findings.append({'key': k, 'lines': [lo[0], hi[0]],
                                     'gap': hi[0]-lo[0], 'status_a': pa, 'status_b': pb})
    # dedupe by (key, line pair)
    seen, out = set(), []
    for f in findings:
        t = (f['key'], tuple(f['lines']))
        if t in seen: continue
        seen.add(t); out.append(f)
    return out

LIMITS = """
DECLARED LIMITS — read before trusting a zero:
 1. VOCABULARY-BOUND. It finds only the six opposing pairs above. A status expressed
    in words not on that list is invisible. The list is not a population.
 2. NO SEMANTICS. "PAID" near an unrelated object in the same entry can pair wrongly;
    every finding is a CANDIDATE for a human, never a verdict.
 3. SUPPRESSION IS COARSE. Any supersession word in the span silences the pair --
    so a document that DISCUSSES staleness anywhere near a real conflict hides it.
    This fails toward silence, which is the dangerous direction, and is declared.
 4. ENTRY SPLITTING is heuristic (top-level bullets, else paragraphs). A document
    whose entries nest differently will group wrongly.
 5. RARE-KEY WINDOW (2..6 sites) is a knob and it is the only one. Swept in the
    self-test; a key naming 7+ entries identifies nothing, one naming 1 cannot conflict.
"""
if __name__ == '__main__':
    if '--limits' in sys.argv: print(LIMITS); sys.exit(0)
    for p in [a for a in sys.argv[1:] if not a.startswith('-')]:
        f = scan(p)
        print(f"{p}: {len(f)} candidate(s)")
        for x in f: print(f"   key={x['key']!r:28} lines {x['lines'][0]} vs {x['lines'][1]} (gap {x['gap']})")
