# TOKEN METER — the campaign ledger

Generated 2026-08-06 09:51 America/Los_Angeles by `docs/ledger-tools/token_meter.py` (saltworks, EVIDENCE seat), per `docs/measurement-preregistration.md` §1.
Window: `2026-08-05 22:02` → `now` · 6 personal-lane projects · subagent transcripts INCLUDED.

> **Unit is TOKENS.** These records carry no prices and no account identifier, so no dollar figure and no per-account split is derivable from them. On a subscription, dollars are a flat envelope; the two framings are reported separately or not at all, never blended.
> **Cache is always its own column** and never enters a headline number.

## 1. Totals

| Quantity | Tokens |
|---|---:|
| API requests (deduplicated) | 2,763 |
| Input | 53,032 |
| **Output** | **880,785** |
| Cache created | 18,962,346 |
| Cache read | 347,054,453 |
| First request | 2026-08-05 22:02 |
| Last request | 2026-08-06 09:51 |

## 2. By project

| Project | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| `-Users-jyh-projects-claude-saltworks` | 2,087 | 32,888 | **569,607** | 9,383,882 | 203,148,832 |
| `-Users-jyh-projects-claude-salt` | 676 | 20,144 | **311,178** | 9,578,464 | 143,905,621 |
| **TOTAL** | **2,763** | **53,032** | **880,785** | **18,962,346** | **347,054,453** |

## 3. By model tier

| Tier | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| Opus 5 | 2,675 | 41,550 | **772,751** | 16,073,976 | 289,730,141 |
| Fable 5 | 80 | 151 | **106,392** | 1,573,144 | 57,118,981 |
| Opus 4.8 | 2 | 4 | **1,632** | 1,248,389 | 26,022 |
| Haiku 4.5 | 6 | 11,327 | **10** | 66,837 | 179,309 |
| **TOTAL** | **2,763** | **53,032** | **880,785** | **18,962,346** | **347,054,453** |

## 4. By day

| Date | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| 2026-08-05 | 24 | 11,361 | **22,571** | 228,132 | 10,006,395 |
| 2026-08-06 | 2,739 | 41,671 | **858,214** | 18,734,214 | 337,048,058 |
| **TOTAL** | **2,763** | **53,032** | **880,785** | **18,962,346** | **347,054,453** |

## 5. Main loop vs subagents

| Where | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| main loop | 514 | 1,914 | **665,822** | 6,045,602 | 150,428,869 |
| subagents / workflow agents | 2,249 | 51,118 | **214,963** | 12,916,744 | 196,625,584 |
| **TOTAL** | **2,763** | **53,032** | **880,785** | **18,962,346** | **347,054,453** |

_In this window the subagents made **81% of the requests** and **24% of the output tokens** (main loop: 19% / 76%). Design and orchestration sat in the main loops; the agents were many but individually cheap._

## 6. By wave — timestamp-join against git

| Wave (leading tag of the landing commit's subject) | Requests | Input | Output | Cache created | Cache read |
|---|---:|---:|---:|---:|---:|
| `TAU-SHARP` | 225 | 6,376 | **70,494** | 2,642,683 | 32,017,227 |
| `WEIL-TRIO` | 87 | 169 | **48,543** | 2,506,578 | 19,725,123 |
| `SILICON` | 78 | 152 | **34,430** | 783,630 | 18,722,293 |
| `COUNCIL` | 12 | 23 | **29,343** | 811,092 | 8,739,995 |
| `campaign` | 48 | 95 | **22,504** | 313,792 | 8,369,363 |
| `THE TRIPLE` | 22 | 11,357 | **22,407** | 226,318 | 8,703,407 |
| `hb1983-notes` | 36 | 70 | **18,513** | 238,858 | 10,088,198 |
| `CHAR-TRIO` | 5 | 9 | **16,632** | 23,559 | 1,257,668 |
| `WEIL-TRIO-W1` | 33 | 65 | **15,436** | 73,108 | 9,273,069 |
| **TOTAL** | **546** | **18,316** | **278,302** | **7,619,618** | **116,896,343** |

Attribution rule: each request is charged to the **next commit in `salt` at or after its timestamp**, if that commit lands within 4.0 h; otherwise it is unattributed. Unattributed in this window: 130 requests / 32,876 output tokens. Only requests from this repo's own seat (`-Users-jyh-projects-claude-salt`) are joined.

> **This join is a heuristic, and the table is labelled as one.** A request that produced no commit (a scout, a refuter, a council) is charged to whatever landed next. Read it as *tokens spent in the run-up to a landing*, never as *tokens the landing cost*.

## 7. Methodology — what was counted and what was thrown away

| Fact | Value |
|---|---:|
| Transcript files read | 2,239 |
| JSONL records scanned | 358,472 |
| Duplicate assistant records dropped (same `requestId`) | 114,377 |
| `<synthetic>` records dropped (API errors, zero usage) | 107 |
| Unparseable lines | 0 |

**The dedup rule.** Claude Code writes one assistant record per content block of a response, and **every one of those records repeats the whole `usage` block of the single API call**. Measured here: 114,377 records were duplicates of a request already counted. Summing records instead of requests would inflate every number in this file by roughly a factor of three. Usage was verified byte-identical within each `requestId` group before the rule was adopted.

**Subagents.** Workflow and Task agents write their own transcripts under `<session>/subagents/**/agent-*.jsonl`. They are included by default (`--no-subagents` to exclude). They are the majority of the spend, and a meter that reads only the session file is wrong by an order of magnitude.

**Per-account attribution: UNAVAILABLE.** The transcripts carry no account, organisation or subscription identifier — checked field by field across every record type. The campaign runs five accounts; these files cannot say which one paid for a given request. Reported here as a gap rather than estimated.

**The firewall.** Outside-lane projects are excluded in code (`ledger_common.EMPLOYER_LANE`), not by flag. Any token figure published from this tool is personal-lane only.
