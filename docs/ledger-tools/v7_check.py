#!/usr/bin/env python3
"""v7_check.py — the V7 acceptance bar for an emitSeq-emitted CLOCKED cell.

EVIDENCE seat, built 2026-08-10 01:1x — BEFORE L1 exists, so the verdict on the
fleet's critical path costs it nothing. Pre-registration, not judgement.

V7, as compiler pre-registered it and asked to be held to (19:37):
    flops == nState EXACTLY
    cells == gates + nState
    conb == 0
    one assign per primary output   (NOT "0 assigns" — that would fail a CORRECT
                                     emitS output; the trap is registered)
    `initial` BANNED
    the refinement stays stated forall st0    <- STATEMENT-side, see REFUSED below

THE NUMBERS FOR L1, arithmetic verified against this seat's own measurements
BEFORE the artifact existed (01:1x):
    combinational gates, measured on mac_cell_signed.v   225
    nState, from committed MacCell.lean scellSeq          64
    ⇒ cells == 289  and  flops == 64      — matches the maestro's L1 figure.

⚠️ `flops == nState EXACTLY` CARRIES THE -ma LESSON AND IS THE REASON THIS TOOL
LEADS WITH IT: yosys once deleted 17 of 32 PC bits as unobservable, so "has a
32-bit PC" was true of the RTL and false of the gates. ***A FLOP SHORTFALL IS
STATE YOU THOUGHT YOU HAD.*** An EXCESS is equally a finding — it means state
nobody modelled.

⛔ REFUSED BY CONSTRUCTION, and printed as such on every run: the "refinement
stated forall st0" clause is a property of a LEAN STATEMENT, not of a netlist.
This tool reads a `.v`. A green here DOES NOT clear V7 — a hand must still read
the refinement. Same discipline as f5_port_test's criterion (c).

EXIT 0 = every mechanical clause MET (statement clause still owed to a hand)
     1 = a clause FAILED (a finding)
     2 = could not read / could not derive the expected numbers
"""

import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

CELL = re.compile(r"^\s*sky130_fd_sc_hd__(?P<type>[a-z0-9_]+)\s+(?P<inst>\S+)\s*\(")
ASSIGN = re.compile(r"^\s*assign\s+(?P<lhs>\w+)\s*=")
OUTPORT = re.compile(r"^\s*output\s+(?:wire|reg)?\s*(?P<name>\w+)\s*,?\s*$")
FLOPISH = ("dfxtp", "dfrtp", "dfstp", "dfbbn", "dlxtp", "dlrtp", "sdf")


def die(msg: str) -> None:
    print(f"v7_check: COULD NOT READ — {msg}", file=sys.stderr)
    sys.exit(2)


def find_repo(start: Path):
    p = start.resolve()
    for c in [p, *p.parents]:
        if (c / ".git").exists():
            return c
    return None


def derive_nstate(start: Path, seq: str):
    """nState from the COMMITTED MacCell.lean — never the worktree.

    Five seats share this tree and the file is under active edit on a night with
    waves running. Parsing a half-written file is a banked hazard; a committed
    ref is the only honest source for an acceptance number.
    """
    repo = find_repo(start)
    if repo is None:
        return None, "NO GIT REPO ABOVE THE NETLIST"
    try:
        out = subprocess.run(["git", "show", f"HEAD:SaltWorks/HDL/MacCell.lean"],
                             capture_output=True, text=True, cwd=repo, timeout=20)
    except (OSError, subprocess.SubprocessError) as e:
        return None, f"GIT UNAVAILABLE ({type(e).__name__})"
    if out.returncode != 0:
        return None, f"HEAD:MacCell.lean UNREADABLE (rc={out.returncode})"
    m = re.search(rf"^\s*def\s+{seq}\s*:\s*Seq\s*:=.*?nState\s*:=\s*(\d+)",
                  out.stdout, re.M | re.S)
    if not m:
        return None, f"nState for `{seq}` NOT FOUND in HEAD:MacCell.lean"
    return int(m.group(1)), f"HEAD:MacCell.lean ({seq})"


def main() -> None:
    if len(sys.argv) < 2:
        die("usage: v7_check.py <clocked-cell.v> [seq-name] [expected-gates]")
    path = Path(sys.argv[1])
    seq = sys.argv[2] if len(sys.argv) > 2 else "scellSeq"
    if not path.is_file():
        die(f"no such file: {path}")

    text = path.read_text(errors="replace")
    hist = defaultdict(int)
    for line in text.splitlines():
        m = CELL.match(line)
        if m:
            hist[m.group("type")] += 1
    if not hist:
        die(f"parsed ZERO cells from {path} — wrong file, or the emit format moved")

    total = sum(hist.values())
    flops = sum(n for t, n in hist.items() if t.startswith(FLOPISH))
    conb = sum(n for t, n in hist.items() if t.startswith("conb"))
    comb = total - flops
    # ⛔ THE FIRST VERSION COUNTED ZERO OF BOTH ON A FILE WITH 96 OF EACH.
    # `findall` on a `^`-anchored pattern without re.M matches only at the START
    # OF THE STRING, so both counts were structurally 0 — and the negative control
    # still EXITED 1, for the wrong reason. [[right-conclusion-wrong-reason]]: a
    # reason nobody needs is a reason nobody checks, and this one would have
    # started lying the moment a real L1 made the other clauses pass.
    # ⇒ count line-by-line; no anchor semantics to get wrong.
    assigns = sum(1 for ln in text.splitlines() if ASSIGN.match(ln))
    outs = sum(1 for ln in text.splitlines() if OUTPORT.match(ln))
    initials = len(re.findall(r"^\s*initial\b", text, re.M))

    nstate, prov = derive_nstate(path, seq)
    if nstate is None:
        die(f"cannot derive nState ({prov}). V7's bar is stated in terms of it, "
            "so I will not guess: an acceptance number invented by the checker "
            "is worse than no check.")

    exp_gates = int(sys.argv[3]) if len(sys.argv) > 3 else comb
    supplied = len(sys.argv) > 3

    print("=" * 70)
    print("V7 ACCEPTANCE BAR — the emitSeq-emitted CLOCKED cell")
    print("=" * 70)
    print(f"ARTIFACT   {path}")
    print(f"nState     {nstate}   DERIVED from {prov}, not assumed")
    print(f"HISTOGRAM  " + " · ".join(f"{t} {n}" for t, n in sorted(hist.items())))
    print(f"COUNTS     total {total} · flops {flops} · combinational {comb} · "
          f"conb {conb} · assigns {assigns} · output ports {outs} · initial {initials}")
    print("-" * 70)

    fails = []

    ok = flops == nstate
    print(f"{'✅' if ok else '⛔'} flops == nState EXACTLY      {flops} vs {nstate}")
    if not ok:
        fails.append("flops != nState")
        print("   ⚠️ A SHORTFALL IS STATE YOU THOUGHT YOU HAD (the -ma lesson: yosys")
        print("      deleted 17 of 32 PC bits as unobservable). AN EXCESS is state")
        print("      nobody modelled. Either way it is a finding, not a rounding.")

    ok = total == exp_gates + nstate
    src = "supplied" if supplied else "inferred from this netlist"
    print(f"{'✅' if ok else '⛔'} cells == gates + nState      {total} vs "
          f"{exp_gates}+{nstate}={exp_gates + nstate}  (gates {src})")
    if not ok:
        fails.append("cells != gates + nState")
    if not supplied:
        print("   ⚠️ gates were INFERRED as total-minus-flops, so this clause is")
        print("      near-tautological here. Pass the combinational count as argv[3]")
        print("      (225 for L1) to make it a real check against an independent number.")

    ok = conb == 0
    print(f"{'✅' if ok else '⛔'} conb == 0                    {conb}")
    if not ok:
        fails.append("conb tie cells present")

    ok = assigns == outs and outs > 0
    print(f"{'✅' if ok else '⛔'} one assign per output port   {assigns} assigns vs {outs} ports")
    if not ok:
        fails.append("assign/output mismatch")
    print("   📌 NOT '0 assigns' — emitS drives every primary output with an assign")
    print("      BY DESIGN, so a 0-assign bar would fail a CORRECT emission.")

    ok = initials == 0
    print(f"{'✅' if ok else '⛔'} `initial` BANNED             {initials} found")
    if not ok:
        fails.append("`initial` present")

    print("-" * 70)
    print("⛔ REFINEMENT ∀ st0   NOT ANSWERED BY THIS TOOL, BY CONSTRUCTION.")
    print("   That clause is a property of a LEAN STATEMENT; this reads a .v.")
    print("   A green below DOES NOT clear V7 — a hand must read the refinement.")
    print("=" * 70)

    if fails:
        print(f"VERDICT  V7 NOT MET — failing: {', '.join(fails)}")
        sys.exit(1)
    print("VERDICT  every MECHANICAL clause MET · the ∀ st0 clause OWED TO A HAND.")
    sys.exit(0)


if __name__ == "__main__":
    main()
