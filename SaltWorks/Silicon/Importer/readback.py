#!/usr/bin/env python3
"""READBACK — the check `import_netlist.py`'s docstring claimed for weeks and did
not have.

## What was wrong

The importer's header said *"every run is CHECKED per-instance (`--check`, on by
default)"* and described a readback pass. **No such flag and no such pass
existed.** What the run printed was a census REPORT — and a report cannot fail.
Corrected in the docstring on 2026-08-06; this file is the check itself.

## What it actually does, and why it is not a mirror

The emitted Lean datum is read back **from disk** and simulated, and the SOURCE
Verilog is simulated beside it, on the same random valuations. Any disagreement
is a hard error.

The point is that the reference side shares **none of the importer's trusted
tables**. It takes every semantic fact from the **vendor Liberty**:

| the importer trusts | readback instead reads |
|---|---|
| `EXPAND` (cell -> gate program) | Liberty `function` on each output pin |
| `OUTPINS` (which pins are outputs) | Liberty `direction : output` |
| `SEQ_PREFIX` (which cells are flops) | presence of a Liberty `ff` block |
| `SEQ_MODELS` (a flop's next state) | Liberty `ff { next_state : ... }` |

So a wrong expansion, a missed output pin, a misclassified flop, or a wrong
next-state model each show up as a mismatch rather than as agreement between a
table and itself. It also re-derives the instance graph with its own bit-select
composition, so a net-aliasing bug (the one R3 found on escaped vector names)
is caught rather than shared.

## Negative controls — run 2026-08-06, because a check that only ever passes is worth nothing

| mutation | expected | observed |
|---|---|---|
| `EXPAND["nand2_1"]` loses its inverter | caught | ✅ `MISMATCH … index 0 (design output)` |
| `SEQ_MODELS["dfxtp"]` next-state points at the wrong pin | caught | ✅ `MISMATCH … index 24 (next-state)` |
| two design outputs swapped in `--outputs` | **not** caught | ✗ passes — **see below** |

The first two are the ones that matter: they corrupt the importer's own tables
and the check still fires, which is what "not a mirror" has to mean in practice.
(The `SEQ_MODELS` mutation is caught by readback on a netlist the *treatment*
cuts; on the switch, whose flops are cut by hand, an earlier guard rejects it
first and readback never runs. Both are correct — the control had to be run on
both shapes to see it.)

⚠️ **What it does NOT cover, stated so nobody reads more into a pass than is
there.**

* **The caller's port ORDER is invisible to it** — control 3. Swapping two
  entries in `--outputs` permutes the emitted datum *and* the reference's
  expectation identically, so they still agree. This check validates the datum
  against the netlist **for the port list it was given**; it cannot know which
  order was intended. Order is covered elsewhere, by `reimport.sh`'s byte
  comparison against committed data.
* **The tokenizer is shared** (`Sim/refparse.tokenize`), so a tokenizer bug is
  invisible here.
* **It is a random-vector check, not a proof**: it can show a netlist wrong and
  cannot show one right. The proof obligation is the per-cone equivalence; this
  is a guard on the IMPORT step in between.

    ./readback.py  — no CLI; invoked by import_netlist.py --check
"""
import os
import re
import random

_HERE = os.path.dirname(os.path.abspath(__file__))
PDK_VER = os.environ.get("PDK_VER", "8afc8346a57fe1ab7934ba5a6056ea8b43078e71")
PDK_ROOT = os.environ.get(
    "PDK_ROOT", os.path.expanduser(f"~/.volare/volare/sky130/versions/{PDK_VER}"))
LIB = os.path.join(PDK_ROOT,
                   "sky130A/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib")

PG = {"VPWR", "VGND", "VPB", "VNB"}


# --------------------------------------------------------------------------
# Liberty: brace-matched blocks and scalar attributes.
# --------------------------------------------------------------------------
def _blocks(s, kw):
    for m in re.finditer(r'(?<![a-z_])' + kw + r'\s*\(([^)]*)\)\s*\{', s):
        i = s.index('{', m.end() - 1)
        depth, j = 0, i
        while True:
            if s[j] == '{':
                depth += 1
            elif s[j] == '}':
                depth -= 1
                if depth == 0:
                    break
            j += 1
        yield m.group(1).replace('"', '').strip(), s[i + 1:j]


def _attr(key, body):
    m = re.search(key + r'\s*:\s*"?([^";]*)"?\s*;', body)
    return m.group(1).strip() if m else None


def load_liberty(cells_wanted):
    """-> {short_cell: {'ins': [...], 'outs': {pin: fn}, 'ff': (state, next) | None}}"""
    if not os.path.exists(LIB):
        return None
    txt = open(LIB).read()
    out = {}
    for name, body in _blocks(txt, 'cell'):
        short = name.replace("sky130_fd_sc_hd__", "")
        if short not in cells_wanted:
            continue
        ins, outs = [], {}
        for pin, pb in _blocks(body, 'pin'):
            d = _attr('direction', pb)
            if d == 'input':
                ins.append(pin)
            elif d == 'output':
                f = re.search(r'\n\s*function\s*:\s*"([^"]*)"', pb)
                if f:
                    outs[pin] = f.group(1)
        ff = None
        for ffname, fb in _blocks(body, 'ff'):
            ff = (ffname.split(",")[0].strip(), _attr('next_state', fb))
        out[short] = {"ins": ins, "outs": outs, "ff": ff}
    return out


# --------------------------------------------------------------------------
# A Liberty boolean expression evaluator.  Grammar (sky130 uses & | ! ^ and
# juxtaposition-as-AND); precedence  !  >  &  >  ^  >  |.
# --------------------------------------------------------------------------
def eval_fn(expr, env):
    toks = re.findall(r"[A-Za-z_][A-Za-z_0-9]*|[()!&|^*+']|[01]", expr)
    pos = 0

    def peek():
        return toks[pos] if pos < len(toks) else None

    def take():
        nonlocal pos
        t = toks[pos]
        pos += 1
        return t

    def atom():
        t = take()
        if t == '(':
            v = or_()
            assert take() == ')'
        elif t == '!':
            v = not atom()
        elif t in ('0', '1'):
            v = (t == '1')
        else:
            v = env[t]
        while peek() == "'":                     # postfix negation
            take()
            v = not v
        return v

    def and_():
        v = atom()
        while peek() is not None and (peek() in ('&', '*')
                                      or re.match(r"[A-Za-z_(!]", peek() or "")):
            if peek() in ('&', '*'):
                take()
            v = and_atom(v)
        return v

    def and_atom(v):
        return atom() and v

    def xor_():
        v = and_()
        while peek() == '^':
            take()
            v = v ^ and_()
        return v

    def or_():
        v = xor_()
        while peek() in ('|', '+'):
            take()
            v = or_() or v
        return v

    return or_()


# --------------------------------------------------------------------------
# An INDEPENDENT walk of the source netlist's instances.
# --------------------------------------------------------------------------
def parse_ref(toks):
    """-> [(cell, iname, {pin: net})], composing bit-selects on BOTH `ID` and
    `ESCID` — the composition whose absence aliased 961 nets (found by R3)."""
    insts, i, n = [], 0, len(toks)
    while i < n:
        k, v = toks[i]
        if k == "ID" and v.startswith("sky130_"):
            cell = v.replace("sky130_fd_sc_hd__", "")
            i += 1
            iname = toks[i][1]
            i += 1
            conns, depth = {}, 0
            while i < n:
                if toks[i] == ("P", "("):
                    depth += 1
                    i += 1
                elif toks[i] == ("P", ")"):
                    depth -= 1
                    i += 1
                    if depth == 0:
                        break
                elif toks[i] == ("P", "."):
                    pin = toks[i + 1][1]
                    i += 3
                    d2, net = 1, None
                    while i < n and d2 > 0:
                        if toks[i] == ("P", "("):
                            d2 += 1
                        elif toks[i] == ("P", ")"):
                            d2 -= 1
                            if d2 == 0:
                                break
                        elif toks[i][0] in ("ID", "ESCID"):
                            net = toks[i][1]
                            if (i + 3 < n and toks[i + 1] == ("P", "[")
                                    and toks[i + 2][0] == "NUM"
                                    and toks[i + 3] == ("P", "]")):
                                net = f"{net}[{toks[i+2][1]}]"
                                i += 3
                        i += 1
                    i += 1
                    if net is not None:
                        conns[pin] = net
                else:
                    i += 1
            insts.append((cell, iname, conns))
            while i < n and toks[i] != ("P", ";"):
                i += 1
        else:
            i += 1
    return insts


def base_of(cell):
    return re.sub(r"_\d+$", "", cell)


def check(toks, assigns, lean_path, name, ins_all, outs_named, flops, cuts,
          trials=32, seed=20260806):
    """-> (ok, message). Simulates the emitted datum against Liberty semantics."""
    insts = parse_ref(toks)
    cells = {c for c, _, _ in insts}
    lib = load_liberty({base_of(c) for c in cells} | cells)
    if lib is None:
        return None, f"readback: SKIPPED — no Liberty at {LIB}"

    def L(cell):
        return lib.get(cell) or lib.get(base_of(cell))

    # driver map from LIBERTY's notion of an output pin, not the importer's.
    drv, seqQ, unknown = {}, {}, set()
    for (cell, iname, conns) in insts:
        e = L(cell)
        if e is None:
            unknown.add(cell)
            continue
        for p, nt in conns.items():
            if p in e["outs"]:
                drv[nt] = (cell, iname, conns, p)
            elif e["ff"] and p == "Q":
                seqQ[nt] = (cell, iname, conns)

    # --- the emitted Lean datum, read back FROM DISK -----------------------
    src = open(lean_path).read()
    body = src.split("Netlist := [", 1)[1].split("\n]", 1)[0]
    gates = []
    for line in body.strip().split(",\n"):
        t = line.strip().split()
        gates.append((t[0].lstrip("."), t[1:]))
    outs = eval(re.search(r"_outs : List Nat := (\[[^\]]*\])", src).group(1))

    rng = random.Random(seed)
    aliasmap = {}
    for (l, r) in assigns:
        aliasmap[l] = r

    for trial in range(trials):
        vec = [rng.random() < 0.5 for _ in ins_all]
        leaf = dict(zip(ins_all, vec))

        # ---- evaluate the emitted netlist ----
        val = []
        for (op, a) in gates:
            if op == "inp":
                val.append(vec[int(a[0])])
            elif op == "const":
                val.append(a[0] == "true")
            elif op == "not":
                val.append(not val[int(a[0])])
            elif op == "and":
                val.append(val[int(a[0])] and val[int(a[1])])
            elif op == "or":
                val.append(val[int(a[0])] or val[int(a[1])])
            elif op == "xor":
                val.append(val[int(a[0])] ^ val[int(a[1])])
            else:
                return False, f"readback: unknown gate op '{op}' in {lean_path}"
        got = [val[k] for k in outs]

        # ---- evaluate the SOURCE, from Liberty ----
        memo = {}

        def ev(net, _stack=()):
            if net in leaf:
                return leaf[net]
            if net in memo:
                return memo[net]
            if net.startswith("1'b"):
                return net.endswith("1")
            if net in aliasmap:
                return ev(aliasmap[net], _stack)
            if net not in drv:
                return False                       # undriven: matches importer
            cell, iname, conns, pin = drv[net]
            e = L(cell)
            env = {}
            for p in e["ins"]:
                if p in conns:
                    env[p] = ev(conns[p], _stack + (net,))
            memo[net] = eval_fn(e["outs"][pin], env)
            return memo[net]

        def next_state(f):
            """From Liberty's own ff block, with IQ bound to the state leaf."""
            cell, conns = f["cell"], f["conns"]
            e = L(cell)
            st, nxt = e["ff"]
            env = {st: leaf[conns["Q"]]}
            for p in e["ins"]:
                if p in conns:
                    env[p] = ev(conns[p])
            return eval_fn(nxt, env)

        def cut_root(nm):
            cell, iname, conns, pin = drv[nm]
            e = L(cell)
            env = {p: ev(conns[p]) for p in e["ins"] if p in conns}
            return eval_fn(e["outs"][pin], env)

        want = ([ev(o) for o in outs_named]
                + [next_state(f) for f in flops]
                + [cut_root(c) for c in cuts])

        if got != want:
            bad = [i for i, (g, w) in enumerate(zip(got, want)) if g != w]
            k = bad[0]
            kind = ("design output" if k < len(outs_named)
                    else "next-state" if k < len(outs_named) + len(flops) else "cut root")
            return False, (f"readback: MISMATCH on trial {trial}, output index {k} "
                           f"({kind}): emitted={got[k]} liberty={want[k]}; "
                           f"{len(bad)} of {len(got)} outputs disagree")

    # ⚠️ A cell absent from Liberty is either a PHYSICAL cell — fill, tap, decap,
    # diode, which genuinely have no `function` and nothing to check — or a LOGIC
    # cell whose semantics this check could not read, which is a hole in the very
    # coverage the pass is claiming. Those are not the same thing and must not
    # print the same way: the second is a hard error, not a footnote.
    physical = ("tapvpwrvgnd", "fill", "decap", "diode")
    unchecked = sorted(c for c in unknown if not base_of(c).startswith(physical))
    if unchecked:
        return False, (f"readback: {', '.join(unchecked)} have no Liberty entry and are "
                       f"not physical cells — their semantics went UNCHECKED, so a pass "
                       f"here would overstate its own coverage")
    note = (f"; {len(unknown)} physical cell type(s) have no Liberty function and "
            f"nothing to check ({', '.join(sorted(unknown))})") if unknown else ""
    return True, (f"readback: {trials} random vectors, {len(outs)} outputs each — "
                  f"emitted datum agrees with vendor Liberty{note}")
