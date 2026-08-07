#!/usr/bin/env python3
# SPDX-FileCopyrightText: 2026 Jason Hickey
# SPDX-License-Identifier: Apache-2.0
"""
Offline pre-flight for the TinyTapeout submission — every gate that can be
checked WITHOUT an EDA toolchain, plus negative controls for each one.

    ./validate.py            # assemble a tree, check it, and self-test the checks
    ./validate.py --tree DIR # check an already-assembled tree

WHY THE SELF-TEST IS NOT OPTIONAL
---------------------------------
On 8/6 this fleet spent a day cataloguing instruments that reported success they
had not verified. The rule that came out of it: a checker that has never been
shown a bad input is not evidence. So `--self-test` (on by default) mutates the
assembled tree once per check and asserts the checker CATCHES it. If a mutation
slips through, this program fails loudly — a green run here means the checks
have teeth, not merely that they ran.

WHAT THIS CANNOT CHECK, STATED SO NOBODY READS MORE INTO A GREEN RUN
--------------------------------------------------------------------
Everything requiring the flow: DRC, LVS, antenna, setup/hold, area, routability,
and whether the design synthesizes at all. Those live in TT's CI. This program
checks the MECHANICAL gates — schema, substrings, cross-file agreement — which
are exactly the ones that waste a submission cycle by failing after a 40-minute
hardening run.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

try:
    import yaml
except ImportError:
    sys.exit("validate.py needs PyYAML (TT's own project_info.py parses with it, "
             "so a hand-rolled parser would answer a different question than the "
             "gate does).\n  pip install pyyaml")

HERE = os.path.dirname(os.path.abspath(__file__))

# The 24 mandatory pinout keys.
PINOUT_KEYS = ([f"ui[{i}]" for i in range(8)]
               + [f"uo[{i}]" for i in range(8)]
               + [f"uio[{i}]" for i in range(8)])

# TT's docs check is a substring grep over the WHOLE of docs/info.md, so a file
# that QUOTES the placeholder in order to warn about it fails the gate. These are
# therefore built by concatenation and never appear contiguously in any file we
# ship — including this one.
PLACEHOLDERS = [
    "# How it works\n\n" + "Explain how your project works",
    "# How to test\n\n" + "Explain how to use your project",
]

# ⚠️ THE KEYS BELOW TinyTapeout's "DO NOT CHANGE ANYTHING BELOW THIS POINT" BANNER.
# Shipping a config.json without them is what broke the first CI run: dropping
# `FP_SIZING: absolute` makes the floorplanner size the die by UTILISATION while
# the pins still come from the 2x2 DEF template, so `ena` lands at 146 um on an
# 85 um die and global routing dies with
#   [GRT-0209] Pin ena is completely outside the die area and cannot be routed.
# Nothing in TT's flow tells you the key is missing -- it tells you a pin is
# misplaced, forty minutes later, in a different tool.
REQUIRED_CONFIG_KEYS = {
    "RUN_KLAYOUT_XOR", "RUN_KLAYOUT_DRC", "DESIGN_REPAIR_BUFFER_OUTPUT_PORTS",
    "TOP_MARGIN_MULT", "BOTTOM_MARGIN_MULT", "LEFT_MARGIN_MULT",
    "RIGHT_MARGIN_MULT", "FP_SIZING", "GRT_ALLOW_CONGESTION", "FP_IO_HLENGTH",
    "FP_IO_VLENGTH", "FP_PDN_VPITCH", "RUN_CTS", "FP_PDN_MULTILAYER",
    "MAGIC_DEF_LABELS", "MAGIC_WRITE_LEF_PINONLY",
}
# Keys tt_tool.py writes into user_config.json, which is merged LAST and wins.
# Setting any of these in config.json looks like a setting and is a no-op.
OVERRIDDEN_KEYS = {
    "DESIGN_NAME", "VERILOG_FILES", "DIE_AREA", "FP_DEF_TEMPLATE",
    "VDD_PIN", "GND_PIN", "RT_MAX_LAYER",
}


def read(tree, rel):
    with open(os.path.join(tree, rel), encoding="utf-8") as f:
        return f.read()


# --------------------------------------------------------------------------
# The checks. Each returns a list of failure strings.
# --------------------------------------------------------------------------

def check_manifest(tree):
    bad = []
    info = yaml.safe_load(read(tree, "info.yaml"))

    if info.get("yaml_version") != 6:
        bad.append(f"yaml_version must be 6, got {info.get('yaml_version')!r}")

    p = info.get("project", {})
    for k in ("title", "author", "description", "language"):
        if not p.get(k):
            bad.append(f"project.{k} must be non-empty")

    hz = p.get("clock_hz")
    # bool is a subclass of int; 25e6 is a float and TT rejects it.
    if not isinstance(hz, int) or isinstance(hz, bool):
        bad.append(f"clock_hz must be a Python int, got {type(hz).__name__} ({hz!r})")

    top = p.get("top_module", "")
    if not top.startswith("tt_um_"):
        bad.append(f"top_module must start with 'tt_um_', got {top!r}")

    srcs = p.get("source_files") or []
    if not srcs:
        bad.append("source_files must be a non-empty list")
    for s in srcs:
        if "*" in s or "?" in s:
            bad.append(f"source_files may not use wildcards: {s!r}")
        elif not os.path.exists(os.path.join(tree, "src", s)):
            bad.append(f"source_files lists {s!r} but src/{s} does not exist")

    pin = info.get("pinout")
    if not isinstance(pin, dict):
        bad.append("pinout section missing")
    else:
        missing = [k for k in PINOUT_KEYS if k not in pin]
        if missing:
            bad.append(f"pinout is missing {len(missing)} mandatory key(s): "
                       f"{', '.join(missing[:5])}")
        extra = [k for k in pin if k not in PINOUT_KEYS]
        if extra:
            bad.append(f"pinout has key(s) TT rejects: {', '.join(extra)}")
        if not any(str(v).strip() for v in pin.values()):
            bad.append("at least one pinout entry must be non-empty")

    return bad


def check_docs(tree):
    bad = []
    body = read(tree, "docs/info.md")
    for ph in PLACEHOLDERS:
        if ph in body:
            bad.append("docs/info.md still contains an unedited template "
                       f"placeholder ({ph.splitlines()[0]!r} section)")
    stripped = body.lstrip()
    # The datasheet already supplies title/author/description above this slot.
    if stripped.startswith("# ") :
        bad.append("docs/info.md starts at '#'; it is spliced under a heading "
                   "the datasheet already provides, so it must start at '##'")
    return bad


def check_sources_in_sync(tree):
    """`source_files` in info.yaml vs PROJECT_SOURCES in test/Makefile. Nothing
    in TT's flow checks these agree, and they must."""
    info = yaml.safe_load(read(tree, "info.yaml"))
    declared = list(info.get("project", {}).get("source_files") or [])

    mk = read(tree, "test/Makefile")
    m = re.search(r"^PROJECT_SOURCES\s*=\s*(.*)$", mk, re.M)
    if not m:
        return ["test/Makefile has no PROJECT_SOURCES line"]
    used = m.group(1).split()

    if sorted(declared) != sorted(used):
        return [f"source_files {sorted(declared)} != PROJECT_SOURCES {sorted(used)}"]
    return []


def check_rtl(tree):
    bad = []
    info = yaml.safe_load(read(tree, "info.yaml"))
    top = info.get("project", {}).get("top_module", "")

    tops_found = []
    for name in os.listdir(os.path.join(tree, "src")):
        if not name.endswith(".v"):
            continue
        body = read(tree, f"src/{name}")
        # Strip comments before pattern checks: the RTL discusses the bug it
        # fixed by quoting the broken assign, and a naive grep sees that.
        code = re.sub(r"//[^\n]*", "", re.sub(r"/\*.*?\*/", "", body, flags=re.S))

        if re.search(r"^\s*initial\b", code, re.M):
            bad.append(f"src/{name} contains an `initial` statement — flops power "
                       "up random on this shuttle; use an explicit reset")
        if "met5" in code:
            bad.append(f"src/{name} references met5, which the precheck hard-fails")
        tops_found += re.findall(r"^\s*module\s+(\w+)", code, re.M)

    if top not in tops_found:
        bad.append(f"top_module {top!r} is not defined in any src/*.v "
                   f"(found: {', '.join(sorted(tops_found))})")

    # Look for an INSTANTIATION, not a mention. `tb.v` names the top module in
    # its header comment, so a `\btop\b` search over the raw file is satisfied by
    # the comment while the instantiation still says tt_um_example — this check
    # was written that way, and its own negative control caught it.
    tb = re.sub(r"//[^\n]*", "", re.sub(r"/\*.*?\*/", "", read(tree, "test/tb.v"),
                                        flags=re.S))
    if not re.search(rf"^\s*{re.escape(top)}\s+\w+\s*\(", tb, re.M):
        bad.append(f"test/tb.v does not INSTANTIATE {top!r} — the template ships "
                   "tt_um_example and it must be edited")
    return bad


def check_config(tree):
    bad = []
    raw = read(tree, "src/config.json")
    try:
        cfg = json.loads(raw)
    except json.JSONDecodeError as e:
        return [f"src/config.json is not valid JSON: {e}"]

    # ⚠️ THE CHECK THAT WAS MISSING, AND ITS ABSENCE COST A CI CYCLE. The old
    # version only asked "is any key here one that should not be?" — a whitelist,
    # which catches ADDITIONS and is structurally blind to DELETIONS. Shipping a
    # two-key config.json passed it cleanly while having removed sixteen required
    # settings. A validator that only bounds a set from above cannot see an
    # empty set.
    missing = sorted(REQUIRED_CONFIG_KEYS - set(cfg))
    if missing:
        bad.append(f"src/config.json is missing {len(missing)} key(s) from below "
                   f"TT's DO-NOT-CHANGE banner: {', '.join(missing[:6])}"
                   + (" …" if len(missing) > 6 else ""))

    # Duplicate keys are not reliably legal and json.loads silently keeps the
    # last. `"//"` repeated is TinyTapeout's OWN comment convention in this file,
    # so it is exempt — but a repeated REAL key is a silent override.
    keys = [k for k in re.findall(r'"([^"]+)"\s*:', raw) if k != "//"]
    dupes = {k for k in keys if keys.count(k) > 1}
    if dupes:
        bad.append(f"src/config.json has duplicate key(s): {', '.join(sorted(dupes))}")

    for k in cfg:
        if k in OVERRIDDEN_KEYS:
            bad.append(f"src/config.json sets {k}, which user_config.json overrides "
                       "— it would read as a setting and be a no-op")
    return bad


CHECKS = [
    ("manifest", check_manifest),
    ("docs", check_docs),
    ("sources-in-sync", check_sources_in_sync),
    ("rtl", check_rtl),
    ("config", check_config),
]


# --------------------------------------------------------------------------
# Negative controls: one mutation per check, each of which MUST be caught.
# --------------------------------------------------------------------------

def _sub(tree, rel, old, new):
    path = os.path.join(tree, rel)
    with open(path, encoding="utf-8") as f:
        body = f.read()
    assert old in body, f"mutation precondition failed: {old!r} not in {rel}"
    with open(path, "w", encoding="utf-8") as f:
        f.write(body.replace(old, new, 1))


MUTATIONS = [
    ("manifest", "clock_hz as a float",
     lambda t: _sub(t, "info.yaml", "clock_hz:    25000000", "clock_hz:    25e6")),
    ("manifest", "a missing pinout key",
     lambda t: _sub(t, "info.yaml", '  uio[7]: ""\n', "")),
    # SURGICAL: the Makefile is mutated in step with the manifest, so `source_files`
    # and PROJECT_SOURCES still AGREE and only the wildcard rule can fire. The
    # naive version (manifest only) also tripped `sources-in-sync`, which leaves
    # that guard un-exercised by its own mutant.
    ("manifest", "a wildcard in source_files",
     lambda t: (_sub(t, "info.yaml", '    - "project.v"\n    - "banyan_fabric.v"\n'
                                     '    - "bitserial_switch.v"', '    - "*.v"'),
                _sub(t, "test/Makefile",
                     "PROJECT_SOURCES = project.v banyan_fabric.v bitserial_switch.v",
                     "PROJECT_SOURCES = *.v"))),
    # SURGICAL: rename the module EVERYWHERE, so it is still defined in src/ and
    # still instantiated in tb.v — only the `tt_um_` prefix rule can fire. The
    # naive version renamed it in the manifest alone and also tripped `rtl`.
    ("manifest", "top_module without the tt_um_ prefix",
     lambda t: (_sub(t, "info.yaml", "tt_um_saltworks_banyan", "xx_um_saltworks_banyan"),
                _sub(t, "src/project.v", "module tt_um_saltworks_banyan",
                     "module xx_um_saltworks_banyan"),
                _sub(t, "test/tb.v", "tt_um_saltworks_banyan user_project",
                     "xx_um_saltworks_banyan user_project"))),
    ("docs", "the unedited template placeholder",
     lambda t: _sub(t, "docs/info.md", "## How it works",
                    "# How it works\n\n" + "Explain how your project works")),
    ("sources-in-sync", "Makefile out of sync with the manifest",
     lambda t: _sub(t, "test/Makefile", " bitserial_switch.v", "")),
    ("rtl", "an `initial` block in src/",
     lambda t: _sub(t, "src/bitserial_switch.v", "    reg act0, act1, sel0, sel1;",
                    "    reg act0, act1, sel0, sel1;\n    initial act0 = 1'b0;")),
    ("rtl", "tb.v left on the template's tt_um_example",
     lambda t: _sub(t, "test/tb.v", "tt_um_saltworks_banyan user_project",
                    "tt_um_example user_project")),
    ("config", "a config key user_config.json overrides",
     lambda t: _sub(t, "src/config.json", '{', '{\n  "DIE_AREA": "0 0 100 100",')),
    ("config", "a duplicated REAL key (not the // comment convention)",
     lambda t: _sub(t, "src/config.json", '"CLOCK_PORT": "clk",',
                    '"CLOCK_PORT": "clk",\n  "CLOCK_PORT": "gpio",')),
    # THE ONE THAT WOULD HAVE CAUGHT THE FIRST CI FAILURE. Deleting FP_SIZING
    # alone is enough: the die stops being taken from DIE_AREA, the pins keep
    # coming from the 2x2 template, and global routing fails on a misplaced pin.
    ("config", "FP_SIZING deleted from below the DO-NOT-CHANGE banner",
     lambda t: _sub(t, "src/config.json", '  "FP_SIZING": "absolute",\n', "")),
]


def run_checks(tree):
    failures = []
    for name, fn in CHECKS:
        for msg in fn(tree):
            failures.append((name, msg))
    return failures


def self_test(build_tree):
    """Every mutation must be caught by its OWN check and by NO OTHER.

    The second half is not fussiness (compiler seat's rule, 8/6): if a mutant
    trips two guards, a green suite does not prove the second guard works — it
    may be reacting to the first one's mutation and have a defect of its own that
    nothing here exercises. **One mutant per guard, and each mutant invisible to
    every other guard**, or the suite tests fewer things than it appears to."""
    print("\nself-test — each mutation caught by its own check, and ONLY its own:")
    escaped = []
    for owner, label, mutate in MUTATIONS:
        with tempfile.TemporaryDirectory() as d:
            t = os.path.join(d, "tree")
            build_tree(t)
            mutate(t)
            caught = sorted({n for n, _ in run_checks(t)})
            others = [c for c in caught if c != owner]
            if caught == [owner]:
                print(f"  caught  [{owner:16}] {label}")
            elif owner in caught:
                print(f"  LEAKY   [{owner:16}] {label} — also tripped {others}")
                escaped.append((label, f"also tripped {others}; those guards are "
                                       "not independently exercised"))
            elif caught:
                print(f"  MISFILED[{owner:16}] {label} — caught by {caught}")
                escaped.append((label, f"caught by the wrong check: {caught}"))
            else:
                print(f"  ESCAPED [{owner:16}] {label}")
                escaped.append((label, "not caught at all"))
    return escaped


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--tree", help="check an already-assembled tree")
    ap.add_argument("--no-self-test", action="store_true")
    args = ap.parse_args()

    def build_tree(target):
        subprocess.run([os.path.join(HERE, "assemble.sh"), target],
                       check=True, capture_output=True)

    with tempfile.TemporaryDirectory() as d:
        if args.tree:
            tree = args.tree
        else:
            tree = os.path.join(d, "tree")
            build_tree(tree)

        print(f"checking assembled tree: {tree}")
        failures = run_checks(tree)
        for name, msg in failures:
            print(f"  FAIL [{name}] {msg}")
        if not failures:
            print(f"  {len(CHECKS)}/{len(CHECKS)} checks pass")

        escaped = [] if args.no_self_test else self_test(build_tree)

    if failures or escaped:
        if escaped:
            print(f"\n{len(escaped)} MUTATION(S) NOT CAUGHT — these checks are not "
                  "evidence:")
            for label, why in escaped:
                print(f"  {label}: {why}")
        sys.exit(1)

    print("\nOK — checks pass, and all "
          f"{len(MUTATIONS)} negative controls were caught by their own check.")


if __name__ == "__main__":
    main()
