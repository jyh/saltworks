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
import os
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

    # ---- record coverage: a HOLE IN THE MIDDLE, the migration failure -----
    # §E of the charter modelled "unobserved ≠ silent" only for commits
    # PREDATING the record. The 2026-08-06 laptop→Mini migration produced the
    # other direction, and these checks pin the detector that closes it.
    trace = lc.activity_trace([pdir])
    check(len(trace) > len(filtered),
          "COVERAGE: activity_trace should see every record, not only human ones")
    check(trace == sorted(trace), "COVERAGE: activity_trace is not sorted")

    class FakeCommit:
        def __init__(self, when, sha):
            self.when = when
            self.sha = sha
            self.subject = sha
            self.insertions = 0
            self.ext_insertions = 0

    inside = FakeCommit(trace[len(trace) // 2], "inside")
    # a hole one full day past the fixture's last record
    hole = FakeCommit(trace[-1] + timedelta(days=1), "hole")

    holes = lc.unrecorded_commits([inside, hole], trace)
    check([c.sha for c, _ in holes] == ["hole"],
          f"COVERAGE: expected only the hole to flag, got {[c.sha for c, _ in holes]}")

    # the boundary is a real boundary, checked on BOTH sides of it
    near = FakeCommit(trace[-1] + timedelta(seconds=lc.RECORD_TOL_S - 30), "near")
    far = FakeCommit(trace[-1] + timedelta(seconds=lc.RECORD_TOL_S + 30), "far")
    check([c.sha for c, _ in lc.unrecorded_commits([near, far], trace)] == ["far"],
          "COVERAGE: the tolerance boundary does not bind on both sides")

    # AND THE GUARD ON THE SCANNER ITSELF: if the record format ever changes,
    # the scan must RAISE, not return an empty trace that reads as "clean".
    # (The first version of activity_trace did exactly that on these fixtures.)
    blind = Path(tmp) / "-Users-jyh-projects-claude-blindtest"
    blind.mkdir()
    (blind / "x.jsonl").write_text('{"type":"user","stamp":"2026-08-01T00:00:00Z"}\n')
    try:
        lc.activity_trace([blind])
        check(False, "COVERAGE: a scanner that extracted ZERO stamps did not raise")
    except ValueError:
        check(True, "")

    # AN EMPTY TRACE MUST FLAG EVERYTHING. A detector that reports "no holes"
    # when it has no record at all is the day-1 failure mode exactly: an
    # instrument reporting success it has not verified.
    check(len(lc.unrecorded_commits([inside, hole], [])) == 2,
          "COVERAGE: an EMPTY trace reported no holes — the green-tick failure")

    # the live calibration must SEE the two populations separate, and must
    # refuse to bless a tolerance that no longer separates them
    sep = lc.separation([d for _, d in lc.record_distances([inside, hole], trace)])
    check(sep["n_below"] == 1 and sep["n_above"] == 1,
          f"COVERAGE: separation miscounted, got {sep}")
    check(sep["best_above"] > sep["worst_below"],
          "COVERAGE: separation reports an inverted gap")

    # ---- the bus parser, which had NO coverage and was wrong -------------
    # Backtesting 2026-08-06 found it blind to 26% of FLEET.md: it required
    # `]` immediately after the seat name, so every `date`-verified post was
    # invisible, and it never knew the maestro's dash convention at all.
    # math's last post read 12:22 when it was 15:52. These pin both.
    import fleet_hygiene as fhy

    def seat_of(line):
        m = fhy.POST_RE.match(line)
        if m:
            return m.group(4)
        m = fhy.DASH_RE.match(line)
        return m.group(5) if m else None

    check(seat_of("[8/6 14:30, evidence] x") == "evidence", "BUS: plain post missed")
    check(seat_of("[8/6 13:58, math — `date`-verified] x") == "math",
          "BUS: an ANNOTATED seat name is still invisible — the 3.5 h defect")
    check(seat_of("[8/6 15:49, evidence — `date`-verified] x") == "evidence",
          "BUS: annotated evidence post missed")
    check(seat_of("- 08-06 13:52 MAESTRO: x") == "MAESTRO",
          "BUS: the maestro's dash convention is not parsed")
    check(seat_of("random prose about [8/6 whatever]") is None,
          "BUS: parser matched a non-post line")

    # the calibration must REFUSE to bless a threshold nothing came near
    day = datetime(2026, 8, 6, 12, tzinfo=TZ)
    tight = {"a": [day + timedelta(minutes=10 * i) for i in range(6)]}
    cal = fhy.post_gap_calibration(tight, day)
    check(cal["headroom"] is not None and cal["headroom"] > 2,
          f"CALIBRATION: a 10-min-gap day should show large headroom, got {cal}")
    wide = {"a": [day, day + timedelta(hours=7)]}
    cal2 = fhy.post_gap_calibration(wide, day)
    check(cal2["headroom"] < 1,
          f"CALIBRATION: a gap PAST the threshold should show headroom < 1, got {cal2}")

    # ---- import-closure: the GATE must not open when it cannot read -------
    # Landed by the compiler seat 20:50; its first version returned exit 0
    # with "OUTSIDE: 0" when `git ls-files` failed, i.e. a clean green from a
    # tool that had read nothing — and its docstring says it gates a commit.
    import subprocess as _sp
    _ic = str(Path(__file__).parent / "import-closure.py")

    # ⛔⛔ REPAIRED 2026-08-08 14:3x BY THE EVIDENCE SEAT, AND THE BREAKAGE WAS
    # ONLY VISIBLE BECAUSE THE NIGHTLY WAS DRY-RUN SIX HOURS EARLY.
    # `import-closure.py` gained MULTI-ROOT discovery (roots read from
    # lakefile.toml, so the tool's model of the build comes from the build's own
    # declaration). It fails CLOSED — no lakefile.toml => exit 2 — which is
    # correct. But these fixtures predate that upgrade and none of them has a
    # lakefile.toml, so every fixture hit the new guard: 6 of 134 checks failed,
    # and `nightly.sh` runs this file FIRST under `set -e`, so TONIGHT'S LEDGER
    # WOULD NOT HAVE RUN AT ALL.
    #
    # ⭐ AND FIXING IT EXPOSED A SECOND, OLDER DEFECT: the two exit-2 checks below
    # asserted ONLY the exit code, never the REASON. Measured, both states:
    #     empty repo, NO lakefile  -> exit 2 "NO BUILD ROOTS DISCOVERED"
    #     empty repo, WITH lakefile-> exit 2 "ZERO tracked .lean files"   <- intended
    # Both are 2, so the check passed while testing a guard it never reached. It
    # would still pass with the zero-tracked-.lean guard DELETED. A check that
    # cannot fail for the reason it exists is not a check.
    # ⇒ Fixtures now declare a lakefile; every exit-2 assertion names its REASON;
    # and the no-lakefile path gets its own explicit check instead of being the
    # accidental cause of everyone else's green.
    LAKE = '[[lean_lib]]\nname = "SaltWorks"\n'

    def closure(root, roots=None):
        env = dict(os.environ, CLOSURE_ROOT=str(root))
        if roots:                      # documented override, for the git-read guard
            env["CLOSURE_ROOTS"] = roots
        else:
            env.pop("CLOSURE_ROOTS", None)
        r = _sp.run([sys.executable, _ic], capture_output=True, text=True, env=env)
        return r.returncode, r.stdout + r.stderr

    # roots supplied, so discovery SUCCEEDS and the git-read guard is the one tested
    rc, out = closure(Path(tmp) / "does-not-exist-at-all", roots="SaltWorks")
    check(rc == 2, f"CLOSURE: unreadable repo returned {rc}, must be 2 (not 0, not 1)")
    # the expected string is QUOTED FROM THE TOOL, not guessed — my first version
    # of this assertion listed three plausible phrasings and the real one
    # ("CANNOT READ REPO") was none of them, which is the same
    # belief-for-a-measurement error the corpus records elsewhere.
    check("CANNOT READ REPO" in out,
          f"CLOSURE: unreadable repo exited 2 for an UNSTATED reason — the check must "
          f"reach the git-read guard, not the root-discovery guard:\n{out}")

    empty = Path(tmp) / "empty-repo"
    (empty / "SaltWorks").mkdir(parents=True)
    (empty / "lakefile.toml").write_text(LAKE)
    _sp.run(["git", "init", "-q", str(empty)], capture_output=True)
    _sp.run(["git", "-C", str(empty), "add", "-A"], capture_output=True)
    rc, out = closure(empty)
    check(rc == 2, f"CLOSURE: repo with ZERO tracked .lean returned {rc}, must be 2 — "
                   f"'nothing outside an empty set' is not 'everything covered'")
    check("ZERO tracked" in out,
          f"CLOSURE: exited 2 without reaching the zero-tracked-.lean guard — this "
          f"check passed for the WRONG REASON before 8/8:\n{out}")

    # a fixture where the answer is known: hub imports A, B is orphaned
    fix = Path(tmp) / "fixture-repo"
    (fix / "SaltWorks").mkdir(parents=True)
    (fix / "SaltWorks.lean").write_text("import SaltWorks.A\n")
    (fix / "SaltWorks" / "A.lean").write_text("#audit_axioms foo\n")
    (fix / "SaltWorks" / "B.lean").write_text("#audit_axioms bar\n#audit_axioms baz\n")
    _sp.run(["git", "init", "-q", str(fix)], capture_output=True)
    _sp.run(["git", "-C", str(fix), "add", "-A"], capture_output=True)

    # NEW 8/8: the no-lakefile path, pinned explicitly. Tracked .lean files exist,
    # so ONLY the missing build declaration can produce this exit — the exact
    # state that silently broke every fixture above.
    rc, out = closure(fix)
    check(rc == 2, f"CLOSURE: tracked .lean but NO lakefile.toml returned {rc}, must "
                   f"be 2 — roots must come from the build's own declaration")
    check("NO BUILD ROOTS" in out,
          f"CLOSURE: missing lakefile.toml must SAY so — a tool that guesses the "
          f"build when it cannot read it is the defect this guard exists for:\n{out}")

    (fix / "lakefile.toml").write_text(LAKE)
    _sp.run(["git", "-C", str(fix), "add", "-A"], capture_output=True)
    rc, out = closure(fix)
    check("lakefile.toml" in out,
          f"CLOSURE: must report WHERE its roots came from, so a reader can tell a "
          f"declared build from a guessed one:\n{out}")
    check(rc == 1, f"CLOSURE: an orphaned module must exit 1 (the gate), got {rc}")
    check("SaltWorks.B" in out, "CLOSURE: did not name the orphaned module")
    check("SaltWorks.A" not in out.split("OUTSIDE")[-1],
          "CLOSURE: reported an IMPORTED module as outside")
    check("outside the default build: 2" in out,
          f"CLOSURE: miscounted audit sites (expected 2 from B), got:\n{out}")

    # ⚠️ A standalone .lean TOOL is not a library module and must not inflate the
    # OUTSIDE count. On 8/7 `docs/hdl-tools/reach_census.lean` landed and the count
    # read 8 -> 10 modules; the audit-SITE total was unaffected (a tool carries no
    # sites), which is why the wrong number survived being quoted on the bus.
    (fix / "docs").mkdir(exist_ok=True)
    (fix / "docs" / "some_tool.lean").write_text("-- a metaprogram, not a module\n")
    _sp.run(["git", "-C", str(fix), "add", "-A"], capture_output=True)
    rc, out = closure(fix)
    check("SaltWorks.B" in out, "CLOSURE: lost the real orphan after adding a tool file")
    check("some_tool" not in out.split("OUTSIDE")[-1],
          "CLOSURE: a non-library .lean tool was counted as an OUTSIDE module")
    check("outside the default build: 2" in out,
          f"CLOSURE: a tool file changed the audit-site total, got:\n{out}")
    check("excluded as NON-LIBRARY" in out,
          "CLOSURE: the exclusion must be PRINTED, not silent — a filter nobody "
          "can see is how the population becomes wrong without anyone noticing")

    # ---- the three tools the README lists as UNCOVERED ---------------------
    # Both of 2026-08-06's worst defects (the swap threshold, nudge_detect's
    # empty matcher) lived in the untested region. These are the properties
    # each tool's own docstring says it depends on.

    # token_meter: DEDUP BY requestId. ADDENDUM 1 §D — one API response is
    # written as several assistant records, each repeating the whole usage
    # block; summing records inflates every published figure ~2.3x.
    ev, ustats = usage_events([pdir])
    check(ustats.dedup_dropped > 0,
          "TOKENS: the fixture has duplicate requestIds and none was dropped — "
          "the dedup rule is the difference between a true figure and a ~2.3x one")
    seen_ids = [getattr(e, "request_id", None) for e in ev]
    seen_ids = [i for i in seen_ids if i]
    check(len(seen_ids) == len(set(seen_ids)),
          "TOKENS: a requestId appears twice in the deduplicated events")

    # cache must never be folded into output — the charter forbids it in a
    # headline, and the only structural guarantee is that they are separate
    # fields that never sum into one another
    tot_out = sum(e.output_tokens for e in ev)
    tot_cr = sum(e.cache_read for e in ev)
    check(tot_out != tot_cr or tot_out == 0,
          "TOKENS: output and cache_read are indistinguishable in the fixture — "
          "the separation cannot be checked")

    # human_time: an ORPHANED tag must be REPORTED, never silently dropped.
    # Measured 2026-08-06: the morning's six tags produced four blocks with
    # three orphaned and nothing said about it.
    import human_time as ht
    tagf = Path(tmp) / "orphan-tags.tsv"
    tagf.write_text("20990101T0000\tDIRECTING\ta tag that can match nothing\n")
    loaded = ht.load_tags(tagf)
    check("20990101T0000" in loaded,
          "HUMAN_TIME: a well-formed tag line did not load")
    check(loaded["20990101T0000"][0] == "DIRECTING",
          "HUMAN_TIME: tag category was not read")

    # an unknown category must ABORT, not be silently coerced
    bad = Path(tmp) / "bad-cat.tsv"
    bad.write_text("20990101T0000\tPRODUCTIVE\tnot a charter category\n")
    try:
        ht.load_tags(bad)
        check(False, "HUMAN_TIME: an unknown category was accepted silently")
    except SystemExit:
        check(True, "")

    # landed: lane attribution is a PATH HEURISTIC and must be total —
    # every path lands somewhere, and an unknown path must not vanish
    import landed as ld
    for p, expect_known in (("SaltWorks/HDL/ISA.lean", True),
                            ("docs/ledger-tools/x.py", True),
                            ("some/unmapped/path.txt", False)):
        lane = ld.lane_of(p)
        check(isinstance(lane, str) and lane != "",
              f"LANDED: lane_of({p!r}) returned no lane — a path that vanishes "
              f"is a commit missing from every per-lane total")

    # ---- META-TIME: the classification is FROZEN, so pin it ---------------
    # docs/EVIDENCE-metatime-design.md §4 forbids publishing a fraction below
    # 5 days of data. These checks exist so the DEFINITION cannot drift while
    # those days accumulate — a measure that changes under you is a measure
    # chosen by the data.
    for p, expect in (("SaltWorks/HDL/ISA.lean", "DESIGN"),
                      ("Salt/HB/X.lean", "DESIGN"),
                      ("papers/x.tex", "DESIGN"),
                      ("docs/ledger-tools/landed.py", "META"),
                      ("docs/EVIDENCE-campaign.md", "META"),
                      ("docs/measurement-preregistration.md", "META"),
                      ("docs/silicon-design-v1.md", "AMBIGUOUS"),
                      ("docs/hdl-codegen-freeze-v1.md", "AMBIGUOUS")):
        check(ld.metatime_of(p) == expect,
              f"METATIME: {p!r} classified {ld.metatime_of(p)!r}, frozen value is "
              f"{expect!r} — the definition must not drift while data accumulates")

    # AMBIGUOUS must never be silently folded into either of the other two
    check(ld.metatime_of("docs/silicon-design-v1.md") != "DESIGN"
          and ld.metatime_of("docs/silicon-design-v1.md") != "META",
          "METATIME: a gating design doc was folded into DESIGN or META — the "
          "design says it is reported as its own column, never split")

    # fmt_dur_h must never round a sub-threshold window UP across a bucket
    check(lc.fmt_dur_h(59.14 * 60) == "59 min",
          f"FORMAT: 59.14 min printed as {lc.fmt_dur_h(59.14*60)!r} — the 1.0 h defect")
    check(lc.fmt_dur_h(3599) == "59 min",
          f"FORMAT: 3599 s printed as {lc.fmt_dur_h(3599)!r}, must not read as an hour")
    check(lc.fmt_dur_h(20.9 * 3600).startswith("20h"),
          f"FORMAT: the 20.9 h exhibit now prints as {lc.fmt_dur_h(20.9*3600)!r}")

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
# 4. provenance_replay — the bundle-binding check
#
# Written as the failures it prevents. The one that would have been a real
# bug is WRONG-TARGET: it yields zero matching ops, and the obvious
# implementation then replays nothing and compares an empty string — which
# in the variant where "unchanged" means "fine" is a PASS from a tool that
# located nothing. It must REFUSE. Every case below is the red, not the green.
# --------------------------------------------------------------------------

import provenance_replay as pr  # noqa: E402

_T = "/x/Program.lean"


def _line(name, inp):
    return json.dumps({"type": "assistant", "message": {"role": "assistant", "content": [
        {"type": "tool_use", "name": name, "input": inp}]}})


def _bundle(lines, tmp, fname="b.jsonl"):
    p = os.path.join(tmp, fname)
    with open(p, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")
    return p


with tempfile.TemporaryDirectory() as _tmp:
    _w = _line("Write", {"file_path": _T, "content": "alpha\nbeta\n"})
    _e = _line("Edit", {"file_path": _T, "old_string": "beta", "new_string": "gamma"})

    # the happy path: Write then Edit replays to the expected text
    text, _ = pr.replay(pr.read_ops(_bundle([_w, _e], _tmp), _T))
    check(text == "alpha\ngamma\n", f"REPLAY: expected alpha/gamma, got {text!r}")

    # ops aimed at ANOTHER file must not leak into this file's replay
    _other = _line("Write", {"file_path": "/x/Other.lean", "content": "NOPE"})
    text, _ = pr.replay(pr.read_ops(_bundle([_w, _other, _e], _tmp), _T))
    check(text == "alpha\ngamma\n", "REPLAY: an op for a different file leaked in")

    # ⛔ wrong target => REFUSE, never a silent empty replay
    try:
        pr.replay(pr.read_ops(_bundle([_w, _e], _tmp), "/x/Nowhere.lean"))
        check(False, "REPLAY: wrong target did not refuse (this is the false green)")
    except pr.Unreadable:
        check(True, "")

    # ⛔ an Edit whose old_string is absent => the file moved outside the bundle
    _bad = _line("Edit", {"file_path": _T, "old_string": "absent", "new_string": "x"})
    try:
        pr.replay(pr.read_ops(_bundle([_w, _bad], _tmp), _T))
        check(False, "REPLAY: absent old_string did not refuse")
    except pr.Unreadable:
        check(True, "")

    # ⛔ an ambiguous Edit (2 matches, no replace_all) => refuse, do not guess
    _dup = _line("Write", {"file_path": _T, "content": "aa\naa\n"})
    _amb = _line("Edit", {"file_path": _T, "old_string": "aa", "new_string": "bb"})
    try:
        pr.replay(pr.read_ops(_bundle([_dup, _amb], _tmp), _T))
        check(False, "REPLAY: ambiguous old_string did not refuse")
    except pr.Unreadable:
        check(True, "")
    # ...and with replace_all it is unambiguous, so it must SUCCEED
    _all = _line("Edit", {"file_path": _T, "old_string": "aa",
                          "new_string": "bb", "replace_all": True})
    text, _ = pr.replay(pr.read_ops(_bundle([_dup, _all], _tmp), _T))
    check(text == "bb\nbb\n", f"REPLAY: replace_all did not apply, got {text!r}")

    # ⛔ an Edit with no preceding Write => the bundle lacks the file's creation
    try:
        pr.replay(pr.read_ops(_bundle([_e], _tmp), _T))
        check(False, "REPLAY: Edit-before-Write did not refuse")
    except pr.Unreadable:
        check(True, "")

    # ⛔ one unparseable line => holes in the op sequence, refuse the whole bundle
    try:
        pr.read_ops(_bundle([_w, "{ not json", _e], _tmp), _T)
        check(False, "REPLAY: unparseable line did not refuse")
    except pr.Unreadable:
        check(True, "")

    # ⛔ empty bundle => refuse (exit 2), never "nothing to compare, so fine"
    _empty = os.path.join(_tmp, "empty.jsonl")
    open(_empty, "w").close()
    for _arg, _why in ((_empty, "empty bundle"), (_tmp + "/nope.jsonl", "missing bundle")):
        try:
            pr.read_ops(_arg, _T)
            check(False, f"REPLAY: {_why} did not refuse")
        except pr.Unreadable:
            check(True, "")

# integration: the real S2 manifest must still bind. A red here is a FINDING
# (the artifact drifted from its birth record), not a broken test.
_man = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                    "..", "provenance", "REPLAY-MANIFEST.tsv")
if os.path.exists(_man):
    _rows = [l.split("\t") for l in open(_man, encoding="utf-8").read().splitlines()
             if l.strip() and not l.lstrip().startswith("#")]
    check(len(_rows) >= 1, "MANIFEST: no rows — a manifest nobody adds to is not a gate")
    for _r in _rows:
        _b = os.path.join(pr.REPO, _r[0])
        if not os.path.exists(_b):
            check(False, f"MANIFEST: bundle missing: {_r[0]}")
            continue
        try:
            _rc = pr.check_one(_b, _r[1], _r[2], None, quiet=True)
        except pr.Unreadable as _ex:
            _rc = 2
            check(False, f"MANIFEST: {_r[0]} could not be checked: {_ex}")
        check(_rc == 0, f"MANIFEST: {_r[0]} does NOT bind {_r[2]} (exit {_rc}) "
                        "— the artifact has drifted from its birth record")

# --------------------------------------------------------------------------
# 5. model_integrity — which model actually served each message
#
# Written as the failures it prevents. The date filter is here because the
# first version filtered on the FILE's mtime, and a session file spans days:
# it printed a run reading "11:22 -> 09:06", start after end, which is what a
# lost date looks like when two days are averaged into one.
# --------------------------------------------------------------------------

import model_integrity as mi  # noqa: E402


def _mrec(hour, model, day=7, typ="assistant", minute=0):
    local = datetime(2026, 8, day, hour, minute, tzinfo=TZ)
    return json.dumps({
        "type": typ,
        "timestamp": local.astimezone(lc.ZoneInfo("UTC")).strftime("%Y-%m-%dT%H:%M:%S.000Z"),
        "message": {"model": model},
    })


with tempfile.TemporaryDirectory() as _tmp:
    def _mk(recs, name="s.jsonl"):
        p = os.path.join(_tmp, name)
        with open(p, "w", encoding="utf-8") as fh:
            fh.write("\n".join(recs) + "\n")
        return p

    # contiguous same-model records collapse to ONE run
    r = mi.runs_for(_mk([_mrec(9, "claude-opus-5"), _mrec(10, "claude-opus-5")]), "2026-08-07")
    check(len(r) == 1 and r[0][3] == 2, f"MODEL: same model did not collapse ({r})")

    # a change splits into runs, in order, and is what the tool reports
    r = mi.runs_for(_mk([_mrec(9, "claude-opus-5"), _mrec(13, "claude-opus-4-8"),
                         _mrec(15, "claude-opus-5")]), "2026-08-07")
    check(len(r) == 3, f"MODEL: a mid-session change was not split ({len(r)} runs)")
    check([x[2] for x in r] == ["claude-opus-5", "claude-opus-4-8", "claude-opus-5"],
          "MODEL: runs are not in timestamp order")

    # ⛔ the date filter is on the MESSAGE, not the file: yesterday must not leak in
    r = mi.runs_for(_mk([_mrec(9, "claude-opus-5", day=6), _mrec(10, "claude-opus-5", day=7)]),
                    "2026-08-07")
    check(len(r) == 1 and r[0][3] == 1,
          f"MODEL: a record from another day leaked into the day's runs ({r})")
    # ...and every run must have start <= end, the shape that exposed the bug
    for _s, _e, _m, _n in r:
        check(_s <= _e, f"MODEL: run start after end ({_s} > {_e}) — a lost date")

    # synthetic and non-assistant records are not evidence of a model
    r = mi.runs_for(_mk([_mrec(9, "<synthetic>"), _mrec(10, "claude-opus-5", typ="user"),
                         _mrec(11, "claude-opus-5")]), "2026-08-07")
    check(len(r) == 1 and r[0][3] == 1, f"MODEL: synthetic/user records were counted ({r})")

    # an unparseable line is skipped, not fatal — a transcript is append-only and
    # its last line can be a partial write while a session is live
    r = mi.runs_for(_mk(["{ not json", _mrec(9, "claude-opus-5")]), "2026-08-07")
    check(len(r) == 1, "MODEL: a partial final line broke the read")

    # ⛔ THE FIREWALL RAISES, and does not silently skip
    for _lane in ("-Users-jyh-projects-claude-loca", "-Users-jyh-projects-claude-holl"):
        try:
            mi._guard(_lane)
            check(False, f"MODEL FIREWALL: {_lane} was not refused")
        except mi.Unreadable:
            check(True, "")
    try:
        mi._guard("-Users-jyh-projects-claude-saltworks")
        check(True, "")
    except mi.Unreadable:
        check(False, "MODEL FIREWALL: a personal-lane path was refused")

# --------------------------------------------------------------------------

if FAILURES:
    print(f"selftest: {len(FAILURES)} FAILURE(S) out of {CHECKS} checks\n")
    for f in FAILURES:
        print("  ✗", f)
    sys.exit(1)
print(f"selftest: OK — {CHECKS} checks passed "
      f"(classification, dedup, silence math, contamination regression, firewall)")
