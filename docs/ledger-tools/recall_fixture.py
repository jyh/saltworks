#!/usr/bin/env python3
"""RECALL TEST FIXTURE — does a seat who has read the bus RECOGNISE a row from its
text alone, and remember its verdict?

    recall_fixture.py build   > /tmp/recall_sheet.txt     # hand THIS to the scorer
    recall_fixture.py key     > /tmp/recall_key.txt       # DO NOT open before scoring
    recall_fixture.py score /tmp/recall_answers.txt       # compare, print the rate

WHY THIS EXISTS.  Compiler's dream 2 (2026-08-14) showed the codebook's contamination is
ID-KEYED: it names rows by FLEET.md line number, so a scorer handed the TEXT WITHOUT THE
ID has inert exposure.  Mechanically 274-278 of 278 rows carry nothing tying them back.
BUT that measures self-location, NOT human recall -- and recall cannot be self-tested,
because asking yourself contaminates the answer with the memory under test.

*** THE ONE DESIGN RULE ***
The SHEET must never contain a verdict, a class name, or a row id.  The KEY lives in a
separate file and the scorer must not open it until their answers are written down.  If
you extend this, keep that: a fixture that shows the answer measures nothing.
"""
import sys, re, bisect, pathlib, hashlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
# The bus sits BESIDE the repo in the normal checkout, but a git WORKTREE lives
# elsewhere on disk -- so resolve by SEARCHING UPWARD rather than assuming depth.
# (Found the hard way: in a worktree this crashed, and the leak-check that followed
#  then passed on an EMPTY file -- a vacuous control reporting CLEAN on nothing.)
def _find(name, start):
    import os
    env = os.environ.get("FLEET_BUS")
    if env and pathlib.Path(env).exists(): return pathlib.Path(env)
    for d in [start, *start.parents]:
        if (d / name).exists(): return d / name
    # a git WORKTREE lives outside the checkout and shares no ancestor with it:
    # fall back to the real repo root recorded in .git
    gitf = ROOT / ".git"
    if gitf.is_file():
        m = re.search(r'gitdir:\s*(\S+)', gitf.read_text())
        if m:
            common = pathlib.Path(m.group(1)).resolve()
            for d in common.parents:
                if (d / name).exists(): return d / name
    raise SystemExit(f"⛔ cannot locate {name}. Set FLEET_BUS=/path/to/FLEET.md")
BUS  = _find("FLEET.md", ROOT)
CB   = ROOT / "docs" / "helm-doublecode-codebook-amendment-DRAFT2-0813.md"
HDR  = re.compile(r'^\[\d{1,2}/\d{1,2}\s+\d{1,2}:[\dx]{2}(?::\d{2})?\s*[,—-]')
CLS  = r'type-traps|misattributed(?:-mechanisms)?|stale-citations|wrong-scope|EXCLUDED|OTHER'

def rows_with_rulings():
    """Rows the codebook decides, parsed from each table's OWN header row.
    The document uses THREE table shapes; a fixed-column parser is wrong on some of each."""
    lines = CB.read_text(errors="replace").split("\n")
    out, i = {}, 0
    while i < len(lines):
        if lines[i].startswith("|") and i+1 < len(lines) and re.fullmatch(r'\|[\s\-:|]+\|?', lines[i+1].strip()):
            hdr = [c.strip() for c in lines[i].strip().strip("|").split("|")]
            col = None
            for j,h in enumerate(hdr):
                if re.search(r'DRAFT 3|Result|→', h, re.I) and "DRAFT 1" not in h.upper(): col = j
            if col is None:
                for j,h in enumerate(hdr):
                    if re.search(r'result|verdict|class', h, re.I): col = j
            k = i+2
            while k < len(lines) and lines[k].startswith("|"):
                c = [x.strip() for x in lines[k].strip().strip("|").split("|")]
                m = re.fullmatch(r'\*\*?(\d{2,6})\*\*?', c[0]) if c else None
                if m and col is not None and col < len(c):
                    v = re.search(CLS, c[col])
                    if v: out[int(m.group(1))] = v.group(0)
                k += 1
            i = k
        else:
            i += 1
    return out

def body(lid, lines, hdrs):
    i = lid - 1
    k = bisect.bisect_right(hdrs, i)
    return "\n".join(lines[i:(hdrs[k] if k < len(hdrs) else len(lines))])

def redact(text, lid, quoted):
    """Strip the row's identity: its header stamp, any line-number-shaped token, and any
    phrase the codebook quotes verbatim (the ONE leak channel dream 2 found)."""
    t = re.sub(r'^\[[^\]]*\]', '[HEADER REDACTED]', text, count=1)
    t = re.sub(r'(?<!\d)\d{3,6}(?!\d)', '<N>', t)          # every id-shaped token, not just its own
    for q in quoted:
        if q in t: t = t.replace(q, '<PHRASE REDACTED>')
    return t

def build(n=20):
    lines = BUS.read_text(errors="replace").split("\n")
    hdrs  = [i for i,l in enumerate(lines) if HDR.match(l)]
    key   = rows_with_rulings()
    ids   = sorted(key)                                     # DETERMINISTIC, no seed
    pick  = [ids[(i*len(ids))//min(n,len(ids))] for i in range(min(n,len(ids)))]
    cbtxt = CB.read_text(errors="replace")
    quoted = [m.group(1) for m in re.finditer(r'"([^"]{25,90})"', cbtxt)]
    return pick, lines, hdrs, key, quoted

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"
    pick, lines, hdrs, key, quoted = build()
    if cmd == "build":
        print("RECALL TEST — SCORER'S SHEET.  Do NOT open the key file until your answers are written.")
        print("For each item: (a) do you RECOGNISE this post?  (b) name its class, or write UNKNOWN.")
        print("Classes: type-traps | misattributed-mechanisms | stale-citations | wrong-scope | EXCLUDED | OTHER")
        print("="*78)
        for n,lid in enumerate(pick,1):
            print(f"\n--- ITEM {n} ---")
            print(redact(body(lid, lines, hdrs), lid, quoted)[:1200])
        print("\n" + "="*78)
        print(f"sheet sha256/16 = {hashlib.sha256(str(pick).encode()).hexdigest()[:16]}  (pin this in your answer file)")
    elif cmd == "key":
        print("⛔ ANSWER KEY — opening this before scoring VOIDS the test.")
        for n,lid in enumerate(pick,1):
            print(f"ITEM {n}\tFLEET.md:{lid}\t{key[lid]}")
    elif cmd == "score":
        ans = pathlib.Path(sys.argv[2]).read_text().strip().split("\n")
        hit = sum(1 for n,lid in enumerate(pick) if n < len(ans) and key[lid].lower() in ans[n].lower())
        print(f"correct: {hit}/{len(pick)} = {100*hit/len(pick):.0f}%")
        print(f"chance baseline for 6 classes: 17%")
        print("⇒ near chance ⇒ recall is WEAK ⇒ ID-blind scoring restores exposed seats.")
        print("⇒ well above chance ⇒ recall is a real channel and ID-blind scoring is NOT enough.")
