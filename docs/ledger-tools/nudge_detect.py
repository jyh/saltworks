#!/usr/bin/env python3
"""Which "human" touches were actually MACHINE-AUTHORED via `tmux send-keys`?

THE PROBLEM THIS EXISTS FOR (measurement-preregistration.md ADDENDUM 3 §J).
ADDENDUM 1 §A established that harness injections are classified by the
record's OWN PROVENANCE FIELDS -- `origin.kind`, `promptSource`, `isMeta` --
with string patterns only as a legacy fallback. That method is sound and it
fails completely on a channel the maestro adopted at 17:07 on 2026-08-06:
composing a message and injecting it into another seat's input box with
`tmux send-keys`.

Checked field by field, a nudge arrives in the RECEIVING seat as:

    promptSource: "typed"   userType: "external"   origin.kind: "human"

Identical to a human typing, because at the terminal layer IT IS A KEYSTROKE.
The harness cannot know a machine produced it. No provenance field
distinguishes them and none ever will.

THE ONLY DETECTOR THAT CAN WORK IS CROSS-SEAT, AND THIS IS IT. A nudge exists
TWICE in the record: once as a `tmux send-keys` Bash tool call in the SENDING
seat's transcript, and once as a "human" message in the RECEIVING seat's,
moments later. Provenance cannot see it; CORRELATION can.

WHY IT MATTERS, AND IN WHICH DIRECTION -- both are stated because they run
opposite ways and neither excuses the other:
  * human-time      INFLATED  (a machine message extends an engagement block)
  * silence windows SHORTENED (a fake touch makes the fleet look attended)
The first pads THE CLAIM, which is the dishonest direction.

Usage:
    python3 docs/ledger-tools/nudge_detect.py [--window 300] [--since '...']

Exit 0 always: finding zero nudges is a legitimate result on a day nobody
nudged. What is NOT legitimate is reading nothing and reporting zero, so a
scan that reads no records at all RAISES (the 16:52 instrument law).
"""
from __future__ import annotations

import argparse
import json
import re
from datetime import datetime, timedelta

import ledger_common as lc

# `tmux send-keys -t fleet:math -l 'payload'`  /  ... -t fleet:2 -l "payload"
SEND_KEYS = re.compile(
    r"tmux\s+send-keys\b[^'\"]*?-t\s+(?P<target>\S+)[^'\"]*?-l\s+(?P<q>['\"])(?P<payload>.*?)(?P=q)",
    re.S)

# how much of the payload must reappear in the receiving message
PREFIX = 60


def _norm(s: str) -> str:
    return re.sub(r"\s+", " ", s).strip()


def sends(project_dirs) -> list[dict]:
    """Every `tmux send-keys` injection, from the SENDING side."""
    out, records = [], 0
    for d in project_dirs:
        if lc.is_employer_lane(d.name):
            continue
        for f in list(lc.session_files(d)) + list(lc.subagent_files(d)):
            for line in open(f, "r", errors="replace"):
                records += 1
                if "send-keys" not in line:
                    continue
                try:
                    r = json.loads(line)
                except Exception:
                    continue
                msg = r.get("message") or {}
                blocks = msg.get("content") if isinstance(msg.get("content"), list) else []
                for b in blocks:
                    if not (isinstance(b, dict) and b.get("type") == "tool_use"):
                        continue
                    cmd = (b.get("input") or {}).get("command", "")
                    if not isinstance(cmd, str):
                        continue
                    for m in SEND_KEYS.finditer(cmd):
                        try:
                            when = lc.parse_ts(r["timestamp"])
                        except Exception:
                            continue
                        out.append({"when": when, "target": m.group("target"),
                                    "payload": _norm(m.group("payload")),
                                    "sender": d.name, "session": f.stem[:8]})
    if records == 0:
        raise ValueError(
            "nudge_detect read ZERO transcript records — reporting 'no nudges' "
            "from an empty scan would be indistinguishable from a clean fleet. "
            "Check the project discovery before trusting any number here.")
    out.sort(key=lambda s: s["when"])
    return out


def human_records(project_dirs) -> list[dict]:
    """Human-classified records WITH THEIR TEXT.

    ⛔ `ledger_common.Touch` carries `chars` (a COUNT), not the text — so the
    first version of this file matched against `getattr(t, "text", "")`,
    which was always empty, skipped every record, and reported **0.0%
    machine-authored from a matcher that could not compare anything.** The
    guard at the time checked that records were READ; it did not check that
    the comparison was POSSIBLE. Hence this function, and the second guard in
    `main`.

    Classification stays `lc.classify_user_record` — the charter's sanctioned
    filter — so this tool never invents its own notion of "human".
    """
    out, records = [], 0
    for d in project_dirs:
        if lc.is_employer_lane(d.name):
            continue
        for f in lc.session_files(d):
            for line in open(f, "r", errors="replace"):
                records += 1
                if '"type":"user"' not in line and '"type": "user"' not in line:
                    continue
                try:
                    r = json.loads(line)
                except Exception:
                    continue
                if r.get("type") != "user":
                    continue
                verdict, _label = lc.classify_user_record(r)
                if verdict != "human":
                    continue
                msg = r.get("message") or {}
                c = msg.get("content")
                text = c if isinstance(c, str) else " ".join(
                    b.get("text", "") for b in c if isinstance(b, dict)
                ) if isinstance(c, list) else ""
                try:
                    when = lc.parse_ts(r["timestamp"])
                except Exception:
                    continue
                out.append({"when": when, "text": _norm(text),
                            "project": d.name, "session": f.stem[:8]})
    out.sort(key=lambda t: t["when"])
    return out


def match(touches, injections, window_s: float) -> list[tuple]:
    """`[(touch, injection)]` for touches a `send-keys` explains."""
    hits = []
    for t in touches:
        text = t["text"]
        if not text:
            continue
        for inj in injections:
            dt = (t["when"] - inj["when"]).total_seconds()
            if not (-5 <= dt <= window_s):
                continue
            head = inj["payload"][:PREFIX]
            if len(head) < 20:
                continue
            # the receiving record must CONTAIN the injected head, and the two
            # must be in different sessions -- a seat cannot nudge itself
            if head in text and inj["session"] != t["session"]:
                hits.append((t, inj))
                break
    return hits


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--window", type=float, default=300.0,
                    help="seconds after a send-keys in which the receiving record may appear")
    ap.add_argument("--since", default=None)
    args = ap.parse_args()

    projects = lc.discover_personal_projects()
    injections = sends(projects)
    touches = human_records(projects)

    # ⛔ SECOND GUARD: a matcher with nothing to compare must not report 0%.
    with_text = sum(1 for t in touches if t["text"])
    if touches and with_text == 0:
        raise ValueError(
            f"nudge_detect found {len(touches)} human records and NONE carried "
            f"text — the comparison is impossible, so '0 machine-authored' "
            f"would mean 'I could not look', not 'none found'.")

    if args.since:
        lo = lc.parse_local(args.since) if hasattr(lc, "parse_local") else None
        if lo:
            touches = [t for t in touches if t["when"] >= lo]
            injections = [i for i in injections if i["when"] >= lo]

    hits = match(touches, injections, args.window)

    print("# MACHINE-AUTHORED 'HUMAN' TOUCHES — the `tmux send-keys` channel")
    print()
    print(f"Generated {lc.iso_local(lc.now_local())} America/Los_Angeles by "
          f"`docs/ledger-tools/nudge_detect.py`, per "
          f"`docs/measurement-preregistration.md` ADDENDUM 3 §J.")
    print()
    print("> **No provenance field can catch these.** A `tmux send-keys` nudge "
          "arrives with `promptSource: typed`, `userType: external`, "
          "`origin.kind: human` — identical to a human typing, because at the "
          "terminal layer it IS a keystroke. This tool correlates the "
          "RECEIVING record against a `send-keys` tool call in the SENDING "
          "seat's transcript.")
    print()
    print("| Quantity | Value |")
    print("|---|---:|")
    print(f"| `tmux send-keys` injections found | **{len(injections)}** |")
    print(f"| Touches classified HUMAN | {lc.fmt_int(len(touches))} |")
    print(f"| — of which MACHINE-AUTHORED | **{len(hits)}** |")
    if touches:
        print(f"| Share | **{100*len(hits)/len(touches):.1f}%** |")
    print(f"| Correlation window | {args.window:.0f} s |")
    print()

    if hits:
        print("| Received | Receiving seat | Sent by | → pane | Opening words |")
        print("|---|---|---|---|---|")
        for t, inj in hits:
            print(f"| {lc.iso_local(t['when'])} | "
                  f"`{t['project'].replace('-Users-jyh-projects-claude-','')}` | "
                  f"`{inj['sender'].replace('-Users-jyh-projects-claude-','')}"
                  f":{inj['session']}` | `{inj['target']}` | "
                  f"{inj['payload'][:54]}… |")
        print()
        print("⛔ **These are counted as HUMAN by every figure in this "
              "directory.** The bias runs two ways and both are stated: "
              "human-time is **inflated** (a machine message extends an "
              "engagement block — the dishonest direction, it pads THE CLAIM) "
              "and silence windows are **shortened** (a fake touch makes the "
              "fleet look more attended than it was — the self-deprecating "
              "direction).")
        print()
        print("⛔⛔ **AND THE DISTINCTION THIS TOOL CANNOT MAKE — READ THIS "
              "BEFORE QUOTING THE NUMBER.** It establishes that the "
              "**TRANSPORT** was mechanical. It says **nothing** about "
              "whether the **DECISION** was. A maestro seat relaying the "
              "Captain's order verbatim through `send-keys` produces a record "
              "byte-identical to a maestro seat composing that order itself — "
              "and the first is genuine human direction with a machine "
              "courier, while the second is not human direction at all.")
        print()
        print("⇒ **What the flagged records DO establish:** none of them is "
              "evidence that *the human typed into that seat*, which is "
              "exactly what seat attribution and human-time block boundaries "
              "assume. **What they do NOT establish:** that no human decided "
              "the content. *The counterfactual test in §2 — would the "
              "artifact exist without this touch? — must be applied to the "
              "DECISION, and this instrument cannot see decisions.* Resolving "
              "which is which requires the sending seat's own account, and "
              "that is a human judgement, not a query.")
    else:
        print("✅ **No machine-authored touch found in this window.** Note what "
              "that does and does not say: it means no `send-keys` injection "
              "correlates with a human-classified record here — not that the "
              "classification is sound in general.")
    print()
    print(f"⚠️ **What this cannot see.** An injection whose payload was "
          f"rewritten before delivery, one sent by a tool other than "
          f"`tmux send-keys`, or one whose sending transcript is not in the "
          f"personal lane. It matches on the first {PREFIX} characters "
          f"appearing verbatim in the receiving record; a paraphrase escapes "
          f"it. **This is a floor on the count, never a ceiling.**")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
