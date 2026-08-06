#!/usr/bin/env python3
"""Self-test for the ledger tools. `python3 selftest.py` — exit 0 or die.

These are the tests that matter for a published number, so they are
written as the failure they prevent:

  * every harness-injected `role: "user"` record is rejected, one test per
    injection class (the Amendment-2 family plus the two classes found on
    2026-08-06: loop ticks and cron pings);
  * every genuine human touch is kept, including the ones the leg-1
    harvest dropped (slash commands, interrupts);
  * one API response written as three assistant records counts ONCE;
  * the contamination regression itself: the same commit measured against
    a contaminated touch list and a filtered one, showing the filtered
    answer is the long silence and the naive answer is ~zero.

Run it before believing any table this directory prints.
"""

from __future__ import annotations

import json
import sys
import tempfile
from datetime import datetime, timedelta
from pathlib import Path

import ledger_common as lc
from ledger_common import TZ, classify_user_record, human_touches, usage_events

FAILURES: list[str] = []
CHECKS = 0


def check(cond, msg):
    global CHECKS
    CHECKS += 1
    if not cond:
        FAILURES.append(msg)


def ts(day: int, hour: int, minute: int = 0) -> str:
    """A UTC timestamp string for 2026-08-<day> <hour>:<minute> LOCAL."""
    local = datetime(2026, 8, day, hour, minute, tzinfo=TZ)
    return local.astimezone(lc.ZoneInfo("UTC")).strftime("%Y-%m-%dT%H:%M:%S.000Z")


def urec(content, **kw):
    rec = {
        "type": "user",
        "isSidechain": False,
        "userType": "external",
        "timestamp": ts(1, 12),
        "message": {"role": "user", "content": content},
    }
    rec.update(kw)
    return rec


# --------------------------------------------------------------------------
# 1. classification
# --------------------------------------------------------------------------

REJECT_CASES = [
    ("task-notification (Amendment 2's class)",
     urec("<task-notification>\n<task-id>abc</task-id>\n</task-notification>",
          origin={"kind": "task-notification"}, promptSource="system"),
     "task-notification"),
    ("task-notification, legacy client (no provenance fields)",
     urec("<task-notification>\n<task-id>abc</task-id>"),
     "task-notification"),
    ("loop tick, dynamic pacing",
     urec("# Autonomous loop tick (dynamic pacing)\n\nRun the autonomous check…",
          isMeta=True, promptSource="system"),
     "harness-injection"),
    ("loop tick carrying the human's own words verbatim",
     urec("15-MINUTE UPDATE PING (JYH-requested while attentive): compose a brief…",
          isMeta=True, promptSource="system"),
     "harness-injection"),
    ("loop sentinel in the body",
     urec("do the thing <<autonomous-loop-dynamic>> again"),
     "loop-tick"),
    ("peer seat message",
     urec("Another Claude session sent a message:\n<agent-message from=\"Explore\">…",
          origin={"kind": "peer"}, isMeta=True),
     "peer"),
    ("coordinator message",
     urec("carry on", origin={"kind": "coordinator"}),
     "coordinator"),
    ("context-compaction summary",
     urec("This session is being continued from a previous conversation that ran out…"),
     "compaction-summary"),
    ("tool result carried back to the model",
     urec([{"type": "tool_result", "content": "ok"}], toolUseResult={"ok": True}),
     "tool-result"),
    ("subagent prompt (sidechain)",
     urec("You are a REFUTER for the SILICON seat…", isSidechain=True, agentId="a1"),
     "sidechain"),
    ("system reminder",
     urec("<system-reminder>remember to…</system-reminder>"),
     "system-reminder"),
]

HUMAN_CASES = [
    ("typed message", urec("go", origin={"kind": "human"}, promptSource="typed"), "typed"),
    ("queued message", urec("keep going, my friend", origin={"kind": "human"},
                            promptSource="queued"), "typed"),
    ("suggestion accepted", urec("yes", origin={"kind": "human"},
                                 promptSource="suggestion_accepted"), "typed"),
    ("slash command (leg-1 dropped these; we keep them)",
     urec("<command-name>/model</command-name>"), "slash-command"),
    ("ESC interrupt", urec([{"type": "text", "text": "[Request interrupted by user]"}]),
     "interrupt"),
    ("pasted image", urec([{"type": "image", "source": {}}]), "legacy-fallback"),
    ("plain legacy message", urec("prove the class-A Brun blueprint nodes"),
     "legacy-fallback"),
]

for name, rec, label in REJECT_CASES:
    v, l = classify_user_record(rec)
    check(v == "reject", f"CLASSIFY: {name} was NOT rejected (got {v}/{l})")
    check(l == label, f"CLASSIFY: {name} labelled {l!r}, expected {label!r}")

for name, rec, label in HUMAN_CASES:
    v, l = classify_user_record(rec)
    check(v == "human", f"CLASSIFY: {name} was NOT counted as human (got {v}/{l})")
    check(l == label, f"CLASSIFY: {name} labelled {l!r}, expected {label!r}")

# --------------------------------------------------------------------------
# 2. end-to-end over a synthetic project directory
# --------------------------------------------------------------------------

with tempfile.TemporaryDirectory() as tmp:
    pdir = Path(tmp) / "-Users-jyh-projects-claude-fixture"
    (pdir / "sess" / "subagents" / "workflows" / "wf_x").mkdir(parents=True)
    session = pdir / "sess.jsonl"

    records = [
        # a human types at 08:00, then goes quiet until 20:00
        urec("go", origin={"kind": "human"}, promptSource="typed", timestamp=ts(1, 8)),
        # everything in between is machine noise that LOOKS like a human
        urec("<task-notification>done</task-notification>",
             origin={"kind": "task-notification"}, timestamp=ts(1, 10)),
        urec("# Autonomous loop tick (dynamic pacing)\n\nRun…",
             isMeta=True, promptSource="system", timestamp=ts(1, 12)),
        urec("15-MINUTE UPDATE PING (JYH-requested…): status",
             isMeta=True, promptSource="system", timestamp=ts(1, 14)),
        urec("Another Claude session sent a message:", origin={"kind": "peer"},
             isMeta=True, timestamp=ts(1, 16)),
        urec("This session is being continued from a previous conversation…",
             timestamp=ts(1, 18)),
        urec("woohoo", origin={"kind": "human"}, promptSource="typed",
             timestamp=ts(1, 20)),
        # an interleaved sidechain record, as older clients wrote them
        urec("You are a scout…", isSidechain=True, agentId="a9", timestamp=ts(1, 15)),
        # one API response, three records, one usage block
        *[
            {
                "type": "assistant",
                "timestamp": ts(1, 9),
                "requestId": "req_1",
                "isSidechain": False,
                "message": {
                    "id": "msg_1",
                    "model": "claude-opus-5",
                    "usage": {
                        "input_tokens": 10,
                        "output_tokens": 100,
                        "cache_creation_input_tokens": 1000,
                        "cache_read_input_tokens": 10000,
                    },
                },
            }
            for _ in range(3)
        ],
        {
            "type": "assistant",
            "timestamp": ts(1, 9, 30),
            "requestId": "req_synth",
            "message": {"id": "msg_s", "model": "<synthetic>",
                        "usage": {"input_tokens": 0, "output_tokens": 0}},
        },
        # a queued message: the transcript writes it late, enqueue is the truth
        {"type": "queue-operation", "operation": "enqueue",
         "timestamp": ts(1, 19, 50), "content": "queued words"},
        urec("queued words", origin={"kind": "human"}, promptSource="queued",
             timestamp=ts(1, 20, 5)),
    ]
    session.write_text("\n".join(json.dumps(r) for r in records) + "\n")

    # a subagent transcript: its prompt is NOT a human touch, its tokens ARE
    sub = pdir / "sess" / "subagents" / "workflows" / "wf_x" / "agent-a1.jsonl"
    sub.write_text("\n".join(json.dumps(r) for r in [
        urec("You are a refuter…", isSidechain=True, agentId="a1", timestamp=ts(1, 13)),
        {"type": "assistant", "timestamp": ts(1, 13), "requestId": "req_2",
         "isSidechain": True,
         "message": {"id": "msg_2", "model": "claude-fable-5",
                     "usage": {"input_tokens": 5, "output_tokens": 50,
                               "cache_creation_input_tokens": 0,
                               "cache_read_input_tokens": 0}}},
    ]) + "\n")

    touches, stats = human_touches([pdir])
    kinds = [t.kind for t in touches]
    check(len(touches) == 3,
          f"TOUCHES: expected 3 human touches, got {len(touches)} ({kinds})")
    check(stats.rejected["task-notification"] == 1, "TOUCHES: task-notification not rejected")
    check(stats.rejected["harness-injection"] == 2, "TOUCHES: loop/cron not rejected")
    check(stats.rejected["peer"] == 1, "TOUCHES: peer not rejected")
    check(stats.rejected["compaction-summary"] == 1, "TOUCHES: compaction not rejected")
    check(stats.rejected["sidechain"] == 1, "TOUCHES: interleaved sidechain counted")
    check(all("agent-" not in t.session for t in touches),
          "TOUCHES: a subagent transcript contributed a human touch")
    check(stats.queue_corrections == 1,
          f"TOUCHES: queue correction not applied ({stats.queue_corrections})")
    check(any(t.when.hour == 19 and t.when.minute == 50 for t in touches),
          "TOUCHES: queued message not moved back to its enqueue time")

    # THE REGRESSION: a commit at 13:00 sits inside a 12h silence (08:00→20:00).
    # Count the injections as human and the same commit reads as ~1h.
    from silence_windows import enclosing_window, longest_run

    commit = datetime(2026, 8, 1, 13, 0, tzinfo=TZ)
    filtered = [t.when for t in touches]
    e = enclosing_window(commit, filtered, datetime(2026, 8, 2, tzinfo=TZ),
                         stats.corpus_start)
    check(abs(e.length_s - 11.833 * 3600) < 120,
          f"SILENCE: filtered window should be ~11h50m, got {e.length_s/3600:.2f}h")

    contaminated = sorted(filtered + [
        datetime(2026, 8, 1, h, tzinfo=TZ) for h in (10, 12, 14, 16, 18)])
    e2 = enclosing_window(commit, contaminated, datetime(2026, 8, 2, tzinfo=TZ),
                          stats.corpus_start)
    check(abs(e2.length_s - 2 * 3600) < 60,
          f"SILENCE: contaminated window should be 2h, got {e2.length_s/3600:.2f}h")
    check(e.length_s > 5 * e2.length_s,
          "SILENCE: the contamination regression does not reproduce")

    # a commit before any transcript record is UNOBSERVED, not silent
    early = enclosing_window(datetime(2026, 7, 1, tzinfo=TZ), filtered,
                             datetime(2026, 8, 2, tzinfo=TZ), stats.corpus_start)
    check(not early.observed, "SILENCE: pre-transcript commit was not marked unobserved")

    # dedup + subagent inclusion
    events, ustats = usage_events([pdir])
    check(len(events) == 2, f"USAGE: expected 2 requests, got {len(events)}")
    check(ustats.dedup_dropped == 2,
          f"USAGE: expected 2 duplicate records dropped, got {ustats.dedup_dropped}")
    check(ustats.synthetic_dropped == 1, "USAGE: <synthetic> record not dropped")
    check(sum(e.output_tokens for e in events) == 150,
          "USAGE: output tokens wrong (dedup or subagent inclusion is broken)")
    check(sum(e.cache_read for e in events) == 10000, "USAGE: cache_read wrong")
    check(any(e.subagent for e in events), "USAGE: subagent transcript not read")

    events_main, _ = usage_events([pdir], include_subagents=False)
    check(len(events_main) == 1, "USAGE: --no-subagents did not exclude the sidechain")

    # longest run
    class C:
        def __init__(self, h):
            self.when = datetime(2026, 8, 1, h, tzinfo=TZ)
    cs = [C(9), C(10), C(11), C(12), C(21), C(22)]
    i, n, span = longest_run(cs, filtered)
    check(n == 4 and i == 0,
          f"RUN: expected the 4-commit run before the 20:00 touch, got i={i} n={n}")

# --------------------------------------------------------------------------
# 3. the firewall
# --------------------------------------------------------------------------

check(lc.is_employer_lane("-Users-jyh-projects-claude-loca"), "FIREWALL: loca not blocked")
check(lc.is_employer_lane("-Users-jyh-projects-claude-holl"), "FIREWALL: holl not blocked")
check(not lc.is_employer_lane("-Users-jyh-projects-claude-salt"), "FIREWALL: salt blocked")
try:
    human_touches([Path("/tmp/-Users-jyh-projects-claude-loca")])
    check(False, "FIREWALL: reading an employer-lane dir did not raise")
except ValueError:
    check(True, "")
for d in lc.discover_personal_projects():
    check(not lc.is_employer_lane(d.name), f"FIREWALL: discovery returned {d.name}")

# --------------------------------------------------------------------------

if FAILURES:
    print(f"selftest: {len(FAILURES)} FAILURE(S) out of {CHECKS} checks\n")
    for f in FAILURES:
        print("  ✗", f)
    sys.exit(1)
print(f"selftest: OK — {CHECKS} checks passed "
      f"(classification, dedup, silence math, contamination regression, firewall)")
