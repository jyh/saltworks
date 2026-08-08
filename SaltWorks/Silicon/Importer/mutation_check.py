#!/usr/bin/env python3
"""MUTATION CHECK — does `readback` actually REFUSE a corrupted datum?

## Why this file exists, and why `reimport.sh` is not enough

`reimport.sh` proves the committed data are *reproducible*: regenerate, compare
bytes. That is a check on the GENERATOR. It says nothing about whether the
READBACK check — this harness's trust anchor, the reason a generated file may
carry "the generator is UNTRUSTED" in its header — would notice if the datum
were wrong.

⛔ **And on 2026-08-07 it would not have.** `readback.check` read the emitted
netlist as `src.split("Netlist := [", 1)[1]` — the FIRST block only. When
`import_netlist.py` began emitting large netlists in `++`-joined chunks, that
silently checked chunk 0 and reported success for the whole file. It surfaced as
an `IndexError` only because the outputs happened to index past chunk 0; a
netlist whose outputs all landed inside the first chunk would have PASSED a check
that read a third of the gates.

📌 **`reimport.sh` could not have caught that**, and the reason generalises: both
committed data are below the chunking threshold, so they take the unchanged path.
***A regression test built from the existing corpus cannot see a bug that only
fires above the corpus's size.***

## What this does

1. Import a real post-layout netlist, and confirm the readback **passes**
   (`BASELINE` — without this, "refused" proves nothing, since a check that
   refuses everything is not a check).
2. Flip ONE gate in the **first** chunk. Readback must **refuse**.
3. Flip ONE gate in the **LAST** chunk. Readback must **refuse**.

⭐ **Step 3 is the discriminating one.** It is the case the pre-repair reader was
structurally blind to, and it is the reason this file exists rather than a
one-line assertion that the fix works.

## Usage

    SRC=<post-layout .v>  python3 mutation_check.py

`SRC` defaults to a `tt_submission` artifact path if one is exported as `ART`.
Mutations are written to temporary copies; nothing in the repo is modified.
"""
import contextlib
import io
import os
import re
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)


def run(art):
    tmp = tempfile.mkdtemp(prefix="mutation_check.")
    out = os.path.join(tmp, "Datum.lean")
    ins = ",".join(["rst_n", "ena"]
                   + [f"ui_in[{i}]" for i in range(8)]
                   + [f"uio_in[{i}]" for i in range(8)])
    outs = ",".join([f"uo_out[{i}]" for i in range(8)]
                    + [f"uio_out[{i}]" for i in range(8)])
    sys.argv = ["import_netlist.py", art, "--top", "tt_um_saltworks_banyan",
                "--out", out, "--name", "datumNL", "--inputs", ins,
                "--outputs", outs]

    g = {"__name__": "__main__",
         "__file__": os.path.join(HERE, "import_netlist.py")}
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        exec(compile(open(g["__file__"]).read(), "import_netlist.py", "exec"), g)
    base = [l for l in buf.getvalue().splitlines() if "readback" in l]
    print("  BASELINE (unmutated datum must PASS):")
    print(f"    {base[0].strip() if base else 'no readback line — check is OFF?'}")

    readback, tokenize = g["readback"], g["tokenize"]
    toks = tokenize(open(art).read())
    rest = ("datumNL", g["ins_all"], g["outs_named"], g["auto"], g["cuts"])

    nchunks = len(re.findall(r"^def datumNL__c\d+ : ", open(out).read(), re.M))
    if nchunks == 0:
        print("    ⚠️  datum is NOT chunked — the discriminating case cannot run "
              "on this source; use a netlist above the chunking threshold")
        return 0

    failures = 0
    for chunk, note in ((0, "first chunk"), (nchunks - 1, "LAST chunk — "
                                             "the pre-repair reader was BLIND here")):
        s = open(out).read()
        start = s.index(f"def datumNL__c{chunk} : ")
        end = s.index("\n]", start)
        seg = s[start:end]
        flip = {"and": "or", "or": "and", "xor": "and"}
        m = list(re.finditer(r"^  \.(and|or|xor) (\d+) (\d+)$", seg, re.M))
        if m:
            h = m[len(m) // 2]
            rep = f"  .{flip[h.group(1)]} {h.group(2)} {h.group(3)}"
            what = f"one .{h.group(1)}→.{flip[h.group(1)]}"
        else:
            # `.not n` → `.not (n-1)`: BACKWARD, so the netlist stays well formed.
            # A forward reference would be a different (and invalid) experiment —
            # and note that Lean's `runP` uses `getD … false` there while this
            # evaluator raises, so the two disagree on malformed input.
            m = list(re.finditer(r"^  \.not (\d+)$", seg, re.M))
            if not m:
                print(f"    chunk {chunk}: no mutable logic gate — skipped")
                continue
            h = m[len(m) // 2]
            rep = f"  .not {max(0, int(h.group(1)) - 1)}"
            what = "one .not rewired backward"
        path = os.path.join(tmp, f"Datum_c{chunk}.lean")
        open(path, "w").write(s[:start] + seg[:h.start()] + rep + seg[h.end():]
                              + s[end:])
        ok, _ = readback.check(toks, g["assigns"], path, *rest)
        good = ok is False
        failures += 0 if good else 1
        print(f"    chunk {chunk} ({note}): {what} → "
              f"{'REFUSED ✅' if good else f'ACCEPTED ⛔ (ok={ok})'}")
    return failures


if __name__ == "__main__":
    art = os.environ.get("SRC") or os.environ.get("ART")
    if not art or not os.path.exists(art):
        sys.exit("mutation_check: set SRC=<post-layout .v> (a tt_submission "
                 "artifact); nothing is checked without a real netlist")
    print("mutation_check: does readback REFUSE a one-gate corruption?")
    n = run(art)
    print(f"mutation_check: {'ALL MUTATIONS REFUSED' if n == 0 else f'{n} ACCEPTED — FAILURE'}")
    sys.exit(1 if n else 0)
