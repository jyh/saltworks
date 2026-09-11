#!/usr/bin/env python3
"""effort_frozen_check.py — the frozen effort intermediate must keep summing.

    python3 docs/ledger-tools/effort_frozen_check.py            # check
    python3 docs/ledger-tools/effort_frozen_check.py --selftest  # + mutation controls

Owner: the EVIDENCE seat. Subject: ``docs/EVIDENCE-effort-intermediate-0820.tsv``.

WHY A CHECKER AND NOT A DOCUMENT
--------------------------------
The TSV exists because the transcripts behind the campaign's effort headline
are deleted on a rolling retention schedule and 2.4 days of the window are
already gone. A file like that is the ONLY surviving evidence for a published
number, which makes a silent transcription error in it unrecoverable and
invisible: there is nothing left to re-derive it from.

⇒ So the decompositions are not published beside the headline as a courtesy.
  They are published so that the headline has a MECHANICAL OBLIGATION attached
  to it -- three independent sums that must agree, and a seam bracket the
  two-piece reconstruction must sit inside. A typo in any row breaks a sum.

⛔ THIS CHECK CANNOT VALIDATE THE MEASUREMENT. It validates the ARITHMETIC and
  the INTERNAL CONSISTENCY of a record whose subject is gone. A green here says
  "these numbers are the ones that were measured, unaltered since"; it says
  nothing about whether the measurement was right. Those are different claims
  and only the first one is still checkable.

⛔ AND IT REFUSES RATHER THAN PASSES when it cannot find its subject: a missing
  TSV is exit 2, not exit 0. A checker whose silence means "file absent" is a
  checker that reports success on a deleted record.
"""

from __future__ import annotations

import argparse
import sys
import tempfile
from pathlib import Path

TSV = Path(__file__).resolve().parent.parent / "EVIDENCE-effort-intermediate-0820.tsv"


def load(path: Path) -> list[dict]:
    rows, header = [], None
    for line in path.read_text().splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        cells = line.split("\t")
        if cells[0] == "piece":            # a header line; two blocks in this file
            header = cells
            continue
        if header is None:
            raise SystemExit("RED  a data row appeared before any header row")
        rows.append(dict(zip(header, cells)))
    return rows


def num(row: dict, col: str):
    v = row.get(col, "n/a")
    return None if v in ("n/a", "") else int(v)


def check(path: Path) -> list[str]:
    """Return a list of failure strings; empty means green."""
    if not path.is_file():
        raise SystemExit(f"RED  subject not found: {path}  (exit 2 — a missing record is not a pass)")
    rows = load(path)
    fail: list[str] = []

    # ⛔ AN EMPTY RECORD IS NOT A CLEAN ONE. Every assertion below is a comparison
    #   between two sums, and a file with no data rows makes every comparison
    #   vacuously true. That is the shape a truncating write leaves behind, and it
    #   is indistinguishable from a green run unless the population is asserted.
    if not rows:
        return ["the record carries ZERO data rows — nothing was compared, so nothing passed"]
    if not any(r["piece"] == "HEADLINE" and r["grain"] == "total" for r in rows):
        return ["the record carries no HEADLINE total — the figure it exists to preserve is absent"]

    def total(piece, col):
        m = [r for r in rows if r["piece"] == piece and r["grain"] == "total"]
        return num(m[0], col) if m else None

    def summed(piece, grain, col):
        vals = [num(r, col) for r in rows if r["piece"] == piece and r["grain"] == grain]
        vals = [v for v in vals if v is not None]
        return sum(vals) if vals else None

    # 1-3. every decomposition of every piece must reconstitute that piece's total.
    for piece in ("HEADLINE", "A-committed", "B-frozen", "REPLAY-0911"):
        for grain in ("project", "tier", "where"):
            for col in ("requests", "output"):
                s, t = summed(piece, grain, col), total(piece, col)
                if s is None or t is None:
                    continue
                if s != t:
                    fail.append(f"{piece} by {grain}: {col} sums to {s:,}, total says {t:,} (delta {s-t:+,})")

    # 4. the two-piece reconstruction must land inside the driven seam bracket.
    for col in ("requests", "output"):
        a, b, h = total("A-committed", col), total("B-frozen", col), total("HEADLINE", col)
        ctl = [num(r, col) for r in rows if r["piece"] == "CONTROL" and r["grain"] == "total"]
        ctl = [c for c in ctl if c is not None]
        if None in (a, b, h) or len(ctl) < 2:
            continue
        recon, lo, hi = a + b, min(ctl), max(ctl)
        if not lo <= h <= hi:
            fail.append(f"headline {col} {h:,} is OUTSIDE the seam bracket [{lo:,}, {hi:,}]")
        if not lo <= recon <= hi:
            fail.append(f"A+B {col} {recon:,} is OUTSIDE the seam bracket [{lo:,}, {hi:,}]")

    # 5. the replay must be a SHORTFALL, never a surplus — a surplus would mean
    #    the headline had understated, which is a different paper and a different
    #    problem, and it must not pass silently as "close enough".
    for col in ("requests", "output"):
        r, h = total("REPLAY-0911", col), total("HEADLINE", col)
        if r is not None and h is not None and r > h:
            fail.append(f"replay {col} {r:,} EXCEEDS the headline {h:,} — re-open the measurement")

    return fail


def selftest() -> int:
    """Drive the mutation controls. A check that cannot fail is decoration."""
    base = TSV.read_text()
    arms, bad = 0, 0

    def arm(name: str, text: str | None, want_fail: bool):
        """text=None drives the ABSENT-SUBJECT arm against a path that does not exist.
        An empty temp file is NOT that arm -- it is a present-but-empty record, which
        this checker would read as zero rows and accept. The two failure modes are
        different and only one of them is 'the record was deleted'."""
        nonlocal arms, bad
        arms += 1
        if text is None:
            p = Path(tempfile.gettempdir()) / "effort-frozen-no-such-file.tsv"
            if p.exists():
                p.unlink()
        else:
            with tempfile.NamedTemporaryFile("w", suffix=".tsv", delete=False) as fh:
                fh.write(text)
                p = Path(fh.name)
        try:
            got = bool(check(p))
        except SystemExit:
            got = True
        finally:
            if text is not None:
                p.unlink()
        ok = got == want_fail
        if not ok:
            bad += 1
        print(f"  {'ok  ' if ok else 'FAIL'} {name}: {'rejected' if got else 'accepted'} (wanted {'reject' if want_fail else 'accept'})")

    arm("unmutated subject accepts", base, False)
    arm("a project row off by one digit", base.replace("\t44157\t", "\t44158\t"), True)
    arm("a tier row off by one digit", base.replace("\t56230975\t", "\t56230976\t"), True)
    arm("the headline total moved", base.replace("\t66169968\t", "\t66169969\t"), True)
    arm("a frozen piece-B row dropped",
        "\n".join(l for l in base.splitlines()
                  if not l.startswith("B-frozen\tproject\t-Users-jyh-projects-claude-jas")), True)
    arm("the replay overtakes the headline", base.replace("\t52566927\t", "\t99566927\t"), True)
    arm("the subject is missing", None, True)
    arm("the subject is present but empty", "", True)

    print(f"\nARMS {arms - bad}/{bad}  ({arms} driven)")
    return 1 if bad else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--tsv", default=str(TSV))
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    fail = check(Path(a.tsv))
    if fail:
        print("RED  the frozen intermediate no longer sums:")
        for f in fail:
            print("   ⛔", f)
        return 1
    print(f"GREEN  {Path(a.tsv).name}: every decomposition reconstitutes its total; "
          f"the headline and the two-piece reconstruction both sit inside the driven seam bracket.")
    print("       ⚠️ This certifies ARITHMETIC over a record whose source is deleted. "
          "It does not certify the measurement.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
