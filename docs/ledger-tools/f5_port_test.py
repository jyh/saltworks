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

📌 EXIT 1 MEANS ONE THING ONLY: A CURRENT NETLIST WITHOUT THE BANK.
⛔ IT DOES **NOT** MEAN "the complement path has not landed" — that reading was in
this header until 2026-08-09 19:1x, and silicon caught that the two states read
IDENTICALLY off an exit code. `7364548` landed the complement path in MacCell.lean
and touched zero `.v` files, so "landed in Lean, NOT YET EMITTED" was arriving as
exit 1 and would have been read as a design failure. That state is now EXIT 2 via
the staleness guard, and exit 1 is unambiguous again.
The original negative control, which remains valid on a CURRENT netlist: at 16:02 on 2026-08-09 the emitted
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


def find_repo(start: Path):
    """Walk up for a .git. ONE implementation, used by every caller.

    ⛔ There were two: derive_port_map() walked up properly, and the staleness
    guard hardcoded `parents[3]` — correct only for SaltWorks/Silicon/RTL/*.v and
    silently wrong everywhere else, so `git log` failed, src_epoch fell to 0, and
    THE GUARD SKIPPED ITSELF. It reported nothing and looked like a pass.
    🔑 I wrote a correct repo-root walk and then hand-rolled a second one three
    lines later — [[prefer-the-verified-instrument]] inside a single function.
    """
    p = start.resolve()
    for cand in [p, *p.parents]:
        if (cand / ".git").exists():
            return cand
    return None


def derive_port_map(start: Path):
    """Read ccCin and ccIn out of the COMMITTED MacCell.lean. Never the worktree.

    ⛔ WHY THIS EXISTS — silicon, 2026-08-09 19:07, turning this tool's own
    disclosed assumption into a measurement and then naming the hazard it hides:

        `i2` IS A POSITION, NOT A NAME. The emitted module has anonymous
        positional ports (i0..i66); the netlist CANNOT name its own carry-in,
        so the iN -> maCin mapping lives ONLY in the Lean source.

    If the complement path reuses ccCin as the XOR sign (the one's-complement
    identity), i2 stays the carry-in and the old default was right. If it adds a
    SEPARATE sign port, every index at or above it SHIFTS and a hard-coded 2
    compares the wrong net -- silently, with a confident verdict attached.
    ⚠️ A FALSE PASS AND A FALSE FAIL ARE BOTH AVAILABLE FROM THAT SHIFT.

    ⇒ So the index is DERIVED, and the derivation is cross-checked against the
    netlist's own port count. The old `i2` default is GONE: a tool that guesses
    is worse here than a tool that refuses, because the guess is checkable-looking.

    📌 COMMITTED REF, NOT THE WORKING TREE, on purpose: five seats share this
    tree and compiler is amending this very file tonight. Parsing a half-written
    file is [[read-tools-inherit-the-shared-tree]] -- a source-parsing tool once
    caught another seat mid-write and accused it of 544 unaudited theorems.
    """
    repo = find_repo(start)
    if repo is None:
        return None, "NO GIT REPO ABOVE THE NETLIST"

    rel = "SaltWorks/HDL/MacCell.lean"
    try:
        out = subprocess.run(["git", "show", f"HEAD:{rel}"],
                             capture_output=True, text=True, cwd=repo, timeout=20)
    except (OSError, subprocess.SubprocessError) as e:
        return None, f"GIT UNAVAILABLE ({type(e).__name__})"
    if out.returncode != 0:
        return None, f"HEAD:{rel} UNREADABLE (rc={out.returncode})"

    src = out.stdout
    cin = re.search(r"^\s*def\s+ccCin\s*:\s*Net\s*:=\s*(\d+)", src, re.M)
    nin = re.search(r"^\s*def\s+ccIn\s*:\s*Nat\s*:=\s*(\d+)", src, re.M)
    if not cin or not nin:
        missing = ", ".join(n for n, m in (("ccCin", cin), ("ccIn", nin)) if not m)
        return None, f"HEAD:{rel} PARSED BUT {missing} NOT FOUND — the source moved"
    return (int(cin.group(1)), int(nin.group(1))), f"HEAD:{rel}"


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
    override = sys.argv[2] if len(sys.argv) > 2 else None
    if not path.is_file():
        die(f"no such file: {path}")

    n_inputs = len(re.findall(r"^\s*input\s+wire\s+\w+", path.read_text(errors="replace"), re.M))
    derived, prov = derive_port_map(path)

    # THE INDEX IS A MEASUREMENT OR THE TOOL REFUSES. Every disagreement below
    # exits 2 (COULD NOT CHECK) and never 1 (NOT MET): "the port map moved" and
    # "criterion (b) failed" are different facts, and collapsing them would
    # manufacture exactly the false FAIL this derivation exists to prevent.
    if derived is None and override is None:
        die(f"cannot derive the carry-in index ({prov}) and none was given. "
            "Pass it as argv[2] once you have READ it from the landed source. "
            "This tool no longer defaults to i2 — a positional guess is worse "
            "than a refusal, because it comes with a confident verdict attached.")
    # ⛔⛔⛔ STALENESS GUARD — ADDED 2026-08-09 19:1x, ON A LIVE FALSE FAIL THAT
    # THIS TOOL PRODUCED AND I ALMOST PUBLISHED.
    #
    # `7364548` is titled "THE COMPLEMENT PATH LANDS — the composed cell can
    # subtract" and it changed `MacCell.lean` by 344 lines and touched ZERO `.v`
    # files. The emitted `mac_cell.v` on the tree is still the 16:02 snapshot, so
    # this tool read a netlist that PREDATES the source it was checking, found no
    # XOR bank, and returned EXIT=1 NOT MET with full confidence.
    #
    # ⚠️ THAT VERDICT WOULD HAVE BEEN A FALSE FAIL AGAINST CORRECT WORK. The
    # complement path may be entirely right in the kernel; nobody has RE-EMITTED
    # yet. "The artifact does not have it" and "the artifact has not been
    # regenerated" are different facts and only one of them is a fence finding.
    #
    # 🔑 AND THE PORT-COUNT CROSS-CHECK DOES NOT CATCH IT: if the complement path
    # reuses `ccCin` as the XOR sign (the one's-complement identity), `ccIn` stays
    # 67 and the stale netlist still agrees on width. The guard I already had
    # passes precisely in the case that matters.
    # ⇒ Staleness is its own question, so it gets its own guard and its own exit 2.
    if derived is not None:
        try:
            src_epoch = int(subprocess.run(
                ["git", "log", "-1", "--format=%ct", "--", "SaltWorks/HDL/MacCell.lean"],
                capture_output=True, text=True, cwd=find_repo(path), timeout=20,
            ).stdout.strip() or 0)
        except (OSError, subprocess.SubprocessError, ValueError, IndexError, TypeError):
            src_epoch = 0
        if src_epoch and path.stat().st_mtime < src_epoch:
            die(f"STALE NETLIST: {path.name} mtime {int(path.stat().st_mtime)} PREDATES "
                f"the last commit to MacCell.lean ({src_epoch}). The netlist was emitted "
                "from an OLDER source, so a missing XOR bank here says nothing about the "
                "landed design. RE-EMIT before running the fence:\n"
                "         sh docs/ledger-tools/emit_cell.sh cell > "
                "SaltWorks/Silicon/RTL/mac_cell.v\n"
                "         (silicon owns that file; this tool does not write it)")

    if derived is not None:
        cc_cin, cc_in = derived
        if n_inputs != cc_in:
            die(f"PORT-COUNT DISAGREEMENT: the netlist has {n_inputs} input ports, "
                f"{prov} says ccIn = {cc_in}. The netlist and the source describe "
                "DIFFERENT objects — re-emit, or point me at the matching pair.")
        cin_port = f"i{cc_cin}"
        if override and override != cin_port:
            die(f"INDEX CONFLICT: you passed {override}, {prov} says {cin_port}. "
                "Refusing to pick — one of them is stale and I cannot tell which.")
    else:
        cin_port = override

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
    if derived is not None:
        print(f"CARRY-IN PORT `{cin_port}` — DERIVED from {prov} (ccCin = {derived[0]}), "
              f"cross-checked against the netlist's own {n_inputs} input ports "
              f"(ccIn = {derived[1]}). MEASURED, not assumed.")
    else:
        print(f"CARRY-IN PORT `{cin_port}` — SUPPLIED BY THE CALLER. Derivation "
              f"failed: {prov}. This verdict is only as good as that argument.")

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
