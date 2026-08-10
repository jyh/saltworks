#!/usr/bin/env python3
"""f5_port_test.py — the F5 UNREACHABLE-HYPOTHESIS port test, mechanised.

EVIDENCE seat. Charter: docs/EVIDENCE-neural-claim-fence-0809.md, F5.

WHAT F5 ASKS (math's test, verbatim, and it is why this file exists):
    "for each hypothesis of a composed theorem, ask WHICH PORT OF THE COMPOSED
     ARTIFACT SUPPLIES IT. If no port can, the theorem is true and inapplicable."

WHAT THIS TOOL DOES AND DOES NOT DO — stated first, because a tool that answers
a narrower question than its name suggests is this seat's most-repeated defect:

    (a) MECHANISED.  Is there an XOR BANK in the EMITTED netlist -- a set of
        xor2 cells sharing ONE common input net -- so the addend path can
        PRESENT ~w rather than only `andWord x w`?
    (b) MECHANISED.  Is that common sign net THE SAME NET as the carry-in port
        (maCin)?  Criterion (b), pinned to the EMITTED netlist after silicon's
        160->157 measurement showed "the netlist" names two artifacts.
    (c) ⛔ NOT MECHANISED, AND THIS TOOL MUST NOT BE READ AS COVERING IT.
        "every hypothesis of the signed composition theorem traces to a port
        that can supply it" is a STATEMENT-side question. It needs the Lean
        theorem beside the netlist and a hand that reads both. This tool sees
        only the netlist, so it CANNOT clear (c) and says so in its own output.

⚠️ THE FRAME THIS TOOL DISCLOSES, because an instrument that travels must say
whose object it measured ([[instrument-must-disclose-its-frame]]): it prints the
artifact PATH, its size and mtime, the git blob sha if the file is tracked, and
the full cell histogram it actually parsed -- never a bare verdict.

EXIT CODES — three-way, and deliberately NOT reusing a code the caller already
means "I am broken" by:
    0  F5 (a) AND (b) MET on the emitted netlist   (c) still owed to a hand
    1  NOT MET -- no XOR bank, or the sign net is not the carry-in port
    2  COULD NOT READ -- missing file, unparsable, zero instances found

📌 EXIT 1 IS THE EXPECTED ANSWER BEFORE THE COMPLEMENT PATH LANDS. It is the
NEGATIVE CONTROL this tool was built against: at 16:02 on 2026-08-09 the emitted
mac_cell carried 193 cells (97 and2 + 64 xor2 + 32 or2), the 64 XORs were the
ripple adder's two-per-bit sum gates, and NO net fed 32 of them. A tool that
reports MET on that file is broken, and that is the first thing to re-run.
"""

import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

INSTANCE = re.compile(
    r"^\s*sky130_fd_sc_hd__(?P<type>[a-z0-9_]+)\s+(?P<inst>\S+)\s*\((?P<conns>[^;]*)\);"
)
CONN = re.compile(r"\.(?P<pin>[A-Za-z0-9_]+)\s*\(\s*(?P<net>[^)]*?)\s*\)")

# Output pins of the combinational cells emitS uses. An input is any other pin.
OUTPUT_PINS = {"X", "Y", "Q", "Z"}

# The bank must be at least this wide to count as a 32-bit complement path.
#
# ⚠️ EXPECT 33, NOT 32 — AND I LEARNED THAT FROM THE POSITIVE CONTROL, NOT FROM
# REASONING. `i2` ALREADY feeds one xor2 in the pre-landing netlist: the carry-in
# entering the ripple adder's first sum gate. So a COMPLETE 32-wide bank tied to
# the carry-in port reads as 33 on this counter, and the control printed exactly
# that. Pre-registering the expected reading so a 33 is not mistaken for an
# off-by-one and a 32 is not mistaken for completeness.
# 🔑 THE RESIDUAL, NAMED RATHER THAN PAPERED OVER: a 31-wide bank plus that
# pre-existing carry XOR also totals 32 and would pass this threshold. The tool
# therefore PRINTS THE COUNT in the verdict line -- the number is the evidence,
# the threshold is only the trigger. A reader who sees 32 where 33 was
# pre-registered should treat it as a FINDING, not as a pass.
BANK_MIN = 32


def die(msg: str) -> None:
    print(f"f5_port_test: COULD NOT READ — {msg}", file=sys.stderr)
    sys.exit(2)


def blob_sha(path: Path) -> str:
    """The tracked blob sha, or an explicit UNTRACKED. Never a guess.

    A sha I did not read is decoration in the shape of a receipt — this seat
    published a nonexistent one on 2026-08-09 18:57 and retracted it a minute
    later. So this is read out of git or it is not printed.
    """
    # ⛔ THE FIRST VERSION OF THIS FUNCTION LIED, AND IT LIED IN A FRAME LINE.
    # It passed a repo-relative path while running git with cwd=path.parent, so
    # git looked for `SaltWorks/Silicon/RTL/mac_cell.v` INSIDE
    # `SaltWorks/Silicon/RTL/` and found nothing -- printing UNTRACKED for a file
    # `git ls-files` confirms is tracked. A disclosure line that is WRONG is worse
    # than one that is absent: it reads as a measured fact.
    # ⇒ resolve() first, and pass the absolute path.
    p = path.resolve()
    try:
        out = subprocess.run(
            ["git", "ls-files", "-s", "--", str(p)],
            capture_output=True, text=True, cwd=p.parent, timeout=10,
        )
        if out.returncode == 0 and out.stdout.strip():
            return out.stdout.split()[1]
        # Tracked-vs-untracked is a real distinction; git being unavailable is a
        # DIFFERENT fact, and collapsing them is how a frame line stops being one.
        if out.returncode == 0:
            return "NOT-TRACKED (git ran, file not in index)"
        return f"GIT-REFUSED (rc={out.returncode})"
    except (OSError, subprocess.SubprocessError) as e:
        return f"GIT-UNAVAILABLE ({type(e).__name__})"


def parse(path: Path):
    gates = []
    skipped = 0
    for line in path.read_text(errors="replace").splitlines():
        if "sky130_fd_sc_hd__" not in line:
            continue
        m = INSTANCE.match(line)
        if not m:
            skipped += 1          # counted and PRINTED, never dropped in silence
            continue
        conns = {c.group("pin"): c.group("net") for c in CONN.finditer(m.group("conns"))}
        ins = {p: n for p, n in conns.items() if p not in OUTPUT_PINS}
        outs = {p: n for p, n in conns.items() if p in OUTPUT_PINS}
        gates.append(
            {"type": m.group("type"), "inst": m.group("inst"), "in": ins, "out": outs}
        )
    return gates, skipped


def main() -> None:
    if len(sys.argv) < 2:
        die("usage: f5_port_test.py <emitted-netlist.v> [carry-in-port, default i2]")
    path = Path(sys.argv[1])
    cin_port = sys.argv[2] if len(sys.argv) > 2 else "i2"
    if not path.is_file():
        die(f"no such file: {path}")

    gates, skipped = parse(path)
    if not gates:
        die(f"parsed ZERO gate instances from {path} — wrong file, or the emit format moved")

    st = path.stat()
    hist = defaultdict(int)
    for g in gates:
        hist[g["type"]] += 1

    print("=" * 72)
    print("F5 PORT TEST — the UNREACHABLE-HYPOTHESIS check, on the EMITTED netlist")
    print("=" * 72)
    print(f"ARTIFACT      {path}")
    print(f"              {st.st_size} bytes · mtime {st.st_mtime:.0f} · blob {blob_sha(path)}")
    print(f"PARSED        {len(gates)} gate instances"
          + (f"  ⚠️ {skipped} sky130 lines did NOT match the instance form and were SKIPPED"
             if skipped else "  (0 unparsed sky130 lines)"))
    print("HISTOGRAM     " + " · ".join(f"{t} {n}" for t, n in sorted(hist.items())))
    print(f"CARRY-IN PORT assumed to be `{cin_port}` (override as argv[2]) — "
          "this is an ASSUMPTION about the port order, not a measurement")

    # ---- (a) is there an XOR bank: one net feeding >= BANK_MIN xor2 cells? ----
    fanout = defaultdict(list)
    for g in gates:
        if not g["type"].startswith("xor2"):
            continue
        for net in set(g["in"].values()):
            fanout[net].append(g["inst"])

    banks = sorted(
        ((net, insts) for net, insts in fanout.items() if len(insts) >= BANK_MIN),
        key=lambda kv: -len(kv[1]),
    )
    n_xor = sum(n for t, n in hist.items() if t.startswith("xor2"))

    print("-" * 72)
    print(f"(a) XOR BANK  xor2 cells total: {n_xor}")
    if not banks:
        top = sorted(((len(v), k) for k, v in fanout.items()), reverse=True)[:3]
        print(f"    ⛔ ABSENT — no net feeds >= {BANK_MIN} xor2 cells.")
        print("       widest xor2 fanouts found: "
              + (", ".join(f"{k}->{c}" for c, k in top) if top else "none"))
        print("    ⇒ the addend path cannot PRESENT ~w. The signed hypothesis is")
        print("      UNREACHABLE — true of the organ, inapplicable to this artifact.")
        verdict_a = False
        sign_net = None
    else:
        sign_net, insts = banks[0]
        print(f"    ✅ PRESENT — net `{sign_net}` feeds {len(insts)} xor2 cells "
              f"(>= {BANK_MIN})")
        if len(banks) > 1:
            print(f"    ⚠️ {len(banks) - 1} OTHER net(s) also reach >= {BANK_MIN} xor2 cells: "
                  + ", ".join(f"{n}({len(i)})" for n, i in banks[1:])
                  + " — the widest was taken; NOT a silent pick.")
        verdict_a = True

    # ---- (b) is that sign net the carry-in port? ----
    print("-" * 72)
    print("(b) SAME NET  maCin and the XOR bank sign input, in the EMITTED module")
    if not verdict_a:
        print("    — NOT REACHED: (a) failed, so there is no sign net to compare.")
        verdict_b = False
    elif sign_net == cin_port:
        print(f"    ✅ MET — the bank's common input IS `{cin_port}`, the carry-in port.")
        verdict_b = True
    else:
        print(f"    ⛔ NOT MET — bank sign net is `{sign_net}`, carry-in port is `{cin_port}`.")
        print("       Two nets, not one. acc + (addend XOR sign) + sign needs ONE signal.")
        verdict_b = False

    # ---- (c) refused, loudly ----
    print("-" * 72)
    print("(c) HYPOTHESES→PORTS   ⛔ NOT ANSWERED BY THIS TOOL, BY CONSTRUCTION.")
    print("    It reads a netlist; (c) needs the signed composition theorem beside")
    print("    it. A green (a)+(b) DOES NOT CLEAR F5 on its own — a hand must still")
    print("    name the supplying port for each hypothesis of the landed statement.")

    print("=" * 72)
    if verdict_a and verdict_b:
        print("VERDICT  (a) MET · (b) MET · (c) OWED TO A HAND — F5 not yet cleared.")
        sys.exit(0)
    print("VERDICT  F5 (a)/(b) NOT MET on this artifact.")
    print("         Before the complement path lands, THIS IS THE EXPECTED ANSWER")
    print("         and it is this tool's negative control.")
    sys.exit(1)


if __name__ == "__main__":
    main()
