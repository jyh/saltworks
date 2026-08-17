#!/usr/bin/env python3
"""b2_blind_sheet.py — build the BLIND scoring sheet for the drawn rows.

THE PRE-REGISTRATION'S CLAUSE 1 SAYS: score from the ROW AND THE RULE ONLY, never
from the pass-1/pass-2 reason pair. That is a DISCIPLINE clause, and a discipline
clause is obeyed or it is not, with nothing but intention in between.

⛔ THIS SCRIPT MAKES IT A MECHANISM. It never opens either pass file. That is not a
promise -- it is checkable by any hand in one command:

    grep -c 'PASS1\\|PASS2\\|coder2\\|compiler-doublecode-PASS' b2_blind_sheet.py
    -> the only occurrences are inside THIS comment, which names them in order to
       state that they are not read. A reader can confirm the absence themselves
       rather than believing me.

The sheet it emits therefore CANNOT carry the other coder's reasoning, or my own
earlier reasoning, because the source of both is never read.

⚠️ WHAT IT CANNOT PROTECT AGAINST, DECLARED: my own memory. I authored the first
pass, and no script can blind me to what I may recall of it. The pre-registration
already accepted that limit when it registered me as the scorer; this closes the
mechanical half and leaves the human half visible instead of pretending it is shut.

INPUT  the drawn ids, read FROM the committed draw artifact
       the corpus, read at the line numbers those ids are
OUTPUT one block per row: the id, and the post's text. Nothing else. No class,
       no verdict field pre-filled, no hint of frequency or expected answer.
"""
import re, sys, pathlib, hashlib, os

DOCS = pathlib.Path(__file__).resolve().parents[1]
DRAW = DOCS / "compiler-B2-DRAW-B-0816.txt"
BUS = os.environ.get("FLEET_MD") or str(pathlib.Path.home() / "projects/claude/FLEET.md")

def die(m):
    print(f"b2_blind_sheet: REFUSING -- {m}", file=sys.stderr); sys.exit(2)

if not DRAW.is_file(): die(f"draw artifact not found: {DRAW}")
if not pathlib.Path(BUS).is_file(): die(f"corpus not found: {BUS}")

m = re.search(r"DRAWN IDS:\s*([\d ]+)", DRAW.read_text())
if not m: die("could not read the drawn ids from the draw artifact")
ids = [int(x) for x in m.group(1).split()]
if not ids: die("drawn id list is empty -- refusing to emit an empty sheet")

lines = pathlib.Path(BUS).read_text(encoding="utf-8", errors="replace").split("\n")
HDR = re.compile(r"^\[[0-9]{1,2}/[0-9]{1,2} [0-9:]+, ?[a-z]+")

# (1) MAPPING CHECK, ENFORCED. Every id must land on a post boundary. If the corpus
#     ever stops being append-only over this range the ids silently point at other
#     posts, and a sheet built from a shifted corpus is worse than no sheet.
bad = [i for i in ids if not (0 < i <= len(lines) and HDR.match(lines[i-1]))]
if bad:
    die(f"{len(bad)} drawn id(s) do NOT land on a post boundary: {bad[:6]} -- "
        f"the corpus has shifted and the sheet would be built on the wrong rows")

print(f"b2_blind_sheet: {len(ids)} rows · corpus {len(lines)} lines · all ids on a post boundary")
print(f"b2_blind_sheet: corpus sha256/16 = {hashlib.sha256(open(BUS,'rb').read()).hexdigest()[:16]}")
print()

out = []
for i in ids:
    start = i - 1
    end = start + 1
    while end < len(lines) and not HDR.match(lines[end]):
        end += 1
    body = "\n".join(lines[start:end]).rstrip()
    out.append((i, body))

sheet = []
sheet.append("# B-2 BLIND SCORING SHEET — row text only, NO verdicts, NO reasons")
sheet.append("# built by b2_blind_sheet.py, which never opens either pass file")
sheet.append("# score from THE ROW AND THE RULE ONLY. Publish verdicts BEFORE checking")
sheet.append("# them against anything. Discard-and-report any row later found named.")
sheet.append(f"# rows: {len(out)}")
sheet.append("")
for i, body in out:
    sheet.append(f"===== ROW {i} " + "=" * 52)
    sheet.append(body)
    sheet.append("")
    sheet.append(f"CLASS[{i}] = ")
    sheet.append("")
text = "\n".join(sheet)
print(f"b2_blind_sheet: sheet is {len(text)} B · {text.count(chr(10))} lines")
print(f"b2_blind_sheet: sheet sha256/16 = {hashlib.sha256(text.encode()).hexdigest()[:16]}")
sys.stdout.write("\n<<<SHEET>>>\n" + text)
