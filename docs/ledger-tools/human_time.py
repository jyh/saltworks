#!/usr/bin/env python3
"""Human-time accounting — the four categories, from the transcripts.

    python3 docs/ledger-tools/human_time.py --since '2026-08-05 22:00'

Owner: the EVIDENCE seat. Charter: docs/measurement-preregistration.md §2,
frozen 2026-08-06 at Council I:

  DIRECTING  — rulings, councils, requirement-setting.
  REVIEWING  — reading that GATES an artifact (freeze ratification, paper
               review).
  UNBLOCKING — logins, purchases, physical acts.
  WATCHING   — curiosity: reading along, questions redirecting nothing.

  THE CLAIM = DIRECTING + REVIEWING + UNBLOCKING only ("would the artifact
  exist without this touch?"). WATCHING is reported as its own proud line.
  Mechanism: session transcripts (every typed word timestamped) + the
  rubric published beside every number + the maestro tags at councils +
  JYH spot-audits tags. NO manual time-tracking.

This tool supplies the mechanism's first half: it turns the transcripts
into ENGAGEMENT BLOCKS -- runs of human touches with no long gap -- each
with a stable id, a measured duration and enough of the opening message
to tag it. The second half is the tag file, one line per block:

    docs/EVIDENCE-human-time-tags.tsv
    <block-id>\t<DIRECTING|REVIEWING|UNBLOCKING|WATCHING>\t<optional note>

Blocks with no tag are reported as UNTAGGED and are never silently folded
into a category. A block id is its start timestamp plus its seat, so it is
stable across re-runs as long as the block's first message does not move.

WHAT A BLOCK'S DURATION IS, EXACTLY
-----------------------------------
last touch minus first touch, plus a floor for one-touch blocks. It
therefore UNDER-counts: the reading and thinking before the first message
of a block leaves no trace in the transcript. The number is a floor on
JYH's engaged time and is published as one. It is not adjusted upward by
any estimate.
"""

from __future__ import annotations

import argparse
from collections import defaultdict
from datetime import datetime, timedelta
from pathlib import Path

import ledger_common as lc
from ledger_common import (
    day_local,
    discover_personal_projects,
    fmt_hours,
    fmt_int,
    human_touches,
    iso_local,
    now_local,
)

CATEGORIES = ("DIRECTING", "REVIEWING", "UNBLOCKING", "WATCHING")
CLAIM_CATEGORIES = ("DIRECTING", "REVIEWING", "UNBLOCKING")
DEFAULT_GAP_MIN = 20.0
SINGLE_TOUCH_FLOOR_S = 60.0


def parse_local(s: str) -> datetime:
    for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%d %H:%M", "%Y-%m-%d"):
        try:
            return datetime.strptime(s, fmt).replace(tzinfo=lc.TZ)
        except ValueError:
            continue
    raise SystemExit(f"cannot parse local time: {s!r}")


def load_tags(path: Path) -> dict[str, tuple[str, str]]:
    tags: dict[str, tuple[str, str]] = {}
    if not path.is_file():
        return tags
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("\t")
        if len(parts) < 2:
            # ⛔ A MALFORMED TAG LINE IS NOT A NON-EVENT. This branch used to
            # `continue` in silence, so a line separated with SPACES instead of
            # TABs — the obvious mistake, and invisible in every editor —
            # vanished without a word, and the block it was meant to tag was
            # then reported as UNTAGGED. That is the exact failure this file's
            # containment matching was written to end (see below), surviving in
            # the loader underneath it: an instrument silently discarding its
            # own input and reporting a smaller claim than the record supports.
            # Fails loud now, per the 2026-08-06 instrument law: an instrument
            # must PRINT WHAT IT READ, and "no matching data" is a DISTINCT
            # output from zero.
            raise SystemExit(
                f"{path}: line is not TAB-separated and would have been "
                f"silently ignored:\n    {line!r}\n"
                f"  Tag lines are: <block-id>\\t<CATEGORY>\\t<optional note>. "
                f"Spaces do not work.")
        block_id, cat = parts[0].strip(), parts[1].strip().upper()
        note = parts[2].strip() if len(parts) > 2 else ""
        if cat not in CATEGORIES:
            raise SystemExit(f"{path}: unknown category {cat!r} for block {block_id}")
        tags[block_id] = (cat, note)
    return tags


def build(args) -> str:
    since = parse_local(args.since) if args.since else None
    until = parse_local(args.until) if args.until else None

    dirs = ([Path(p).expanduser() for p in args.project] if args.project
            else discover_personal_projects())
    dirs = [d for d in dirs if d.is_dir()]
    touches, stats = human_touches(dirs)
    if since:
        touches = [t for t in touches if t.when >= since]
    if until:
        touches = [t for t in touches if t.when < until]

    gap = timedelta(minutes=args.gap_min)
    blocks: list[list] = []
    for t in touches:
        if blocks and t.when - blocks[-1][-1].when <= gap:
            blocks[-1].append(t)
        else:
            blocks.append([t])

    tag_path = Path(args.tags).expanduser()
    tags = load_tags(tag_path)

    def block_id(b) -> str:
        return f"{b[0].when.strftime('%Y%m%dT%H%M')}"

    # --- match tags to blocks by CONTAINMENT, not by exact id -------------
    #
    # A block id is its FIRST TOUCH's timestamp, which is not stable: change
    # --since, or let one new message land inside a former gap, and two
    # blocks merge, the id moves, and every tag on them silently detaches.
    # Measured on 2026-08-06: the morning's six tags produced four blocks
    # with three tags orphaned and NOTHING SAID ABOUT IT. A tagging
    # instrument that silently drops its own tags reports a smaller claim
    # than the truth and calls it data.
    #
    # So: a tag whose timestamp falls INSIDE a block tags that block; tags
    # matching no block are reported as ORPHANED; and a block carrying two
    # or more DIFFERENT categories is reported as CONFLICTED and folded
    # into nothing, because a merged block genuinely has no single answer.
    def tag_ts(tid: str) -> datetime | None:
        try:
            return datetime.strptime(tid, "%Y%m%dT%H%M").replace(tzinfo=lc.TZ)
        except ValueError:
            return None

    block_tags: dict[int, list[tuple[str, str, str]]] = {}
    matched: set[str] = set()
    for i, b in enumerate(blocks):
        # a block id is minute-truncated, so it is always <= the true first
        # touch (07:57 vs 07:57:23). Truncate the bound to match, or every
        # tag misses its own block by seconds.
        lo = b[0].when.replace(second=0, microsecond=0)
        hi = b[-1].when
        for tid, (cat, note) in tags.items():
            t = tag_ts(tid)
            if t is not None and lo <= t <= hi:
                block_tags.setdefault(i, []).append((tid, cat, note))
                matched.add(tid)
    orphaned = sorted(set(tags) - matched)

    def category_of(i: int) -> tuple[str, str]:
        got = block_tags.get(i, [])
        cats = {c for _, c, _ in got}
        if not cats:
            return "UNTAGGED", ""
        if len(cats) > 1:
            return "CONFLICTED", "/".join(sorted(cats))
        return next(iter(cats)), got[0][2]

    out: list[str] = []
    w = out.append
    w("# HUMAN-TIME LEDGER — the four categories")
    w("")
    w(f"Generated {iso_local(now_local())} America/Los_Angeles by "
      f"`docs/ledger-tools/human_time.py`, per "
      f"`docs/measurement-preregistration.md` §2.")
    w(f"Window: `{args.since or 'all'}` → `{args.until or 'now'}` · "
      f"block gap {args.gap_min:.0f} min · tags from `{tag_path.name}`"
      f"{' (absent)' if not tag_path.is_file() else ''}.")
    w("")
    w("**The rubric, published beside the number** — DIRECTING: rulings, "
      "councils, requirement-setting. REVIEWING: reading that *gates* an "
      "artifact. UNBLOCKING: logins, purchases, physical acts. WATCHING: "
      "curiosity — reading along, questions that redirect nothing. "
      "**The dependency claim = DIRECTING + REVIEWING + UNBLOCKING only**, by "
      "the counterfactual test *would the artifact exist without this touch?* "
      "WATCHING is reported as its own line, proudly: the joy is evidence, "
      "not overhead.")
    w("")

    if not blocks:
        w("_No human touches in the window._")
        return "\n".join(out)

    def dur(b) -> float:
        return max((b[-1].when - b[0].when).total_seconds(), SINGLE_TOUCH_FLOOR_S)

    per_cat: dict[str, float] = defaultdict(float)
    per_cat_n: dict[str, int] = defaultdict(int)
    for i, b in enumerate(blocks):
        cat, _ = category_of(i)
        per_cat[cat] += dur(b)
        per_cat_n[cat] += 1

    total = sum(per_cat.values())
    claim = sum(per_cat[c] for c in CLAIM_CATEGORIES)

    w("## 1. Totals")
    w("")
    w("| Category | Blocks | Time | Share |")
    w("|---|---:|---:|---:|")
    for c in CATEGORIES + ("UNTAGGED", "CONFLICTED"):
        if not per_cat_n.get(c):
            continue
        w(f"| {'**' + c + '**' if c in CLAIM_CATEGORIES else c} | "
          f"{per_cat_n[c]} | {fmt_hours(per_cat[c])} | "
          f"{100*per_cat[c]/total:.1f}% |")
    w(f"| **THE CLAIM** (D+R+U) | "
      f"{sum(per_cat_n[c] for c in CLAIM_CATEGORIES)} | "
      f"**{fmt_hours(claim)}** | {100*claim/total:.1f}% |")
    w(f"| (all engaged time) | {len(blocks)} | {fmt_hours(total)} | 100% |")
    w("")
    if per_cat.get("UNTAGGED"):
        w(f"> **{per_cat_n['UNTAGGED']} block(s), {fmt_hours(per_cat['UNTAGGED'])}, "
          f"are UNTAGGED.** They are counted in neither the claim nor "
          f"WATCHING. Tag them in `{tag_path.name}` — one line per block id — "
          f"and re-run. An untagged block is never silently folded into a "
          f"category.")
        w("")

    if orphaned:
        w(f"> ⛔ **{len(orphaned)} TAG(S) MATCH NO BLOCK IN THIS WINDOW** and are "
          f"contributing nothing: `{'`, `'.join(orphaned)}`. A block id is its "
          f"first touch's timestamp, so changing `--since`, or one new message "
          f"landing inside a former gap, merges blocks and detaches their tags. "
          f"**Tags are matched by containment rather than by exact id precisely "
          f"so this is visible instead of silent** — but a tag outside the "
          f"window still needs re-pointing. Re-run the worksheet and re-tag.")
        w("")
    if per_cat_n.get("CONFLICTED"):
        w(f"> ⛔ **{per_cat_n['CONFLICTED']} block(s) carry TWO OR MORE different "
          f"categories** — almost certainly because separately-tagged blocks "
          f"merged when a message landed in the gap between them. They are "
          f"folded into **nothing**, because a merged block genuinely has no "
          f"single answer. Split them by re-tagging.")
        w("")
    w("## 2. Per day")
    w("")
    days: dict[str, list] = defaultdict(list)
    for b in blocks:
        days[day_local(b[0].when)].append(b)
    w("| Date | Blocks | Engaged time | Claim time (D+R+U) | Messages |")
    w("|---|---:|---:|---:|---:|")
    for d in sorted(days):
        bs = days[d]
        eng = sum(dur(b) for b in bs)
        idx = {id(b): i for i, b in enumerate(blocks)}
        cl = sum(dur(b) for b in bs
                 if category_of(idx[id(b)])[0] in CLAIM_CATEGORIES)
        w(f"| {d} | {len(bs)} | {fmt_hours(eng)} | {fmt_hours(cl)} | "
          f"{sum(len(b) for b in bs)} |")
    w("")

    w("## 3. The blocks — the tagging worksheet")
    w("")
    w("Copy a block id into the tag file with its category. The opening "
      "message is shown only so the block can be recognised.")
    w("")
    w("| Block id | Seat | Start | End | Duration | Msgs | Category | Opens with |")
    w("|---|---|---|---|---:|---:|---|---|")
    for i, b in enumerate(blocks):
        bid = block_id(b)
        cat, note = category_of(i)
        if cat == "UNTAGGED":
            cat = "**UNTAGGED**"
        elif cat == "CONFLICTED":
            cat = f"⛔ **CONFLICTED** ({note})" 
        seat = b[0].project.replace("-Users-jyh-projects-claude-", "")
        preview = ""
        for t in b:
            if t.kind in ("typed", "legacy-fallback") and t.chars:
                preview = f"({t.chars} chars)"
                break
        kinds = ",".join(sorted({t.kind for t in b}))
        w(f"| `{bid}` | {seat} | {b[0].when.strftime('%m-%d %H:%M')} | "
          f"{b[-1].when.strftime('%H:%M')} | {fmt_hours(dur(b))} | {len(b)} | "
          f"{cat} | {kinds} {preview} |")
    w("")

    w("## 4. Method notes")
    w("")
    w(f"- A **block** is a run of human touches with no gap longer than "
      f"{args.gap_min:.0f} minutes. Its duration is last touch minus first "
      f"touch, floored at {int(SINGLE_TOUCH_FLOOR_S)} s for a single-touch "
      f"block.")
    w("- **This under-counts, deliberately.** Reading and thinking before the "
      "first message of a block leave no trace in the transcript, so the "
      "figure is a *floor* on engaged time. It is published as a floor and "
      "never adjusted upward by estimate.")
    w("- **No manual time-tracking**, per the frozen design. Every timestamp "
      "comes from the transcript; the only human input is the category tag, "
      "and the rubric that assigns it is printed above the number.")
    w("- The touch filter is the one in `ledger_common.classify_user_record` "
      "— see `README.md`. Injected records (task notifications, loop ticks, "
      "cron pings, peer messages) are not human time.")
    w(f"- Touches read: {fmt_int(len(touches))} in window. "
      f"Rejected as non-human across the whole record: "
      f"{fmt_int(sum(stats.rejected.values()))}.")
    w("")
    return "\n".join(out)


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--since", default=None)
    ap.add_argument("--until", default=None)
    ap.add_argument("--project", action="append", default=None)
    ap.add_argument("--gap-min", type=float, default=DEFAULT_GAP_MIN)
    ap.add_argument("--tags",
                    default=str(Path(__file__).resolve().parents[1]
                                / "EVIDENCE-human-time-tags.tsv"))
    ap.add_argument("--out", default=None)
    args = ap.parse_args()
    md = build(args)
    if args.out:
        lc.write_atomic(args.out, md)
        print(f"wrote {args.out} ({len(md.splitlines())} lines)")
    else:
        print(md)


if __name__ == "__main__":
    main()
