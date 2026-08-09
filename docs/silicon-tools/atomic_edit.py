#!/usr/bin/env python3
"""atomic_edit.py — replace a string in a file WITHOUT ever truncating it.

    python3 atomic_edit.py <file> <old-file> <new-file>
    python3 atomic_edit.py --append <file> <content-file>

⛔⛔ WHY THIS EXISTS (2026-08-09 01:4x). Compiler traced four bus replays to
`pathlib.write_text`, and the maestro's ruling generalised it:

    THE WRITE IDIOM FOLLOWS THE READER.
      streaming reader (bus; `tail` holds the NAME across time)  -> APPEND ONLY
      snapshot reader  (memory store; rsync opens by name once)  -> ATOMIC RENAME
      truncate-in-place (write_text, mode 'w', '>')              -> RIGHT FOR NOBODY

`pathlib.write_text` opens mode 'w', which is O_TRUNC: **truncation is its
CONTRACT, not a race.** Measured definitionally — a 51-byte file written with
`write_text('B\\n')` becomes 2 bytes. A 50 Hz sampler could not see the window,
and "no shrink observed" is NOT evidence of no shrink; the API doc is.

⚠️ MY EXPOSURE, which is why this file is mine and not just compiler's problem:
I edited MEMORY.md and several memory files with `write_text` all night. Those
files are rsynced by the maestro's hand at every heartbeat — an UNPREDICTABLE
concurrent reader. The bus had a watcher loud enough to notice its truncation.
**My memory store's reader is SILENT: a MEMORY.md caught mid-write would mirror
as a valid, short file and diff clean against nothing.**

⭐ WHY `mv` IS SAFE HERE AND WAS WRONG ON THE BUS — the same fact, opposite verdict:
    `mv` swaps the DIRECTORY ENTRY and leaves the old inode intact.
    a tail watcher holds the NAME  -> it follows the swap and sees a "new" file
                                      (or with bare `-f`, goes silently deaf)
    an rsync opens by name ONCE    -> it gets the old file or the new file,
                                      COMPLETE either way. Never a window.
⇒ Inode-versus-name decided three separate verdicts in one night: the memory
  mirror's realness, the live-script edit, and this. Ask which one your reader
  is holding BEFORE choosing how to write.

✅ SELF-TEST (run it; a tool that has never failed has not shown it can):
    printf 'hello\\n' > /tmp/ae.txt
    printf 'hello\\n' > /tmp/old.txt ; printf 'goodbye\\n' > /tmp/new.txt
    python3 atomic_edit.py /tmp/ae.txt /tmp/old.txt /tmp/new.txt   # -> goodbye
    python3 atomic_edit.py /tmp/ae.txt /tmp/old.txt /tmp/new.txt   # -> REFUSES: not found
"""
import os
import sys
import tempfile
import pathlib


def atomic_replace(path: pathlib.Path, data: str) -> None:
    """Write `data` to `path` so a concurrent reader sees old-or-new, never partial."""
    # Same directory: `os.replace` is atomic only WITHIN a filesystem.
    fd, tmp = tempfile.mkstemp(dir=str(path.parent), prefix=".atomic-", suffix=".tmp")
    try:
        with os.fdopen(fd, "w") as fh:
            fh.write(data)
            fh.flush()
            os.fsync(fh.fileno())      # durable before the rename, not after
        os.replace(tmp, path)          # atomic rename; readers get one or the other
    except BaseException:
        # Never leave the scratch file behind to be mistaken for content.
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def main(argv):
    if len(argv) == 4 and argv[1] == "--append":
        target = pathlib.Path(argv[2])
        add = pathlib.Path(argv[3]).read_text()
        # ⭐ APPEND uses mode 'a', NOT read-modify-write: a streaming reader must
        # never see the size go down. Do not "optimise" this into a write_text.
        with open(target, "a") as fh:
            fh.write(add)
        print(f"appended {len(add)} chars to {target}")
        return 0

    if len(argv) != 4:
        print(__doc__.strip().splitlines()[2])
        return 2

    target, oldf, newf = pathlib.Path(argv[1]), pathlib.Path(argv[2]), pathlib.Path(argv[3])
    if not target.is_file():
        print(f"⛔ atomic_edit: no such file: {target}")
        return 2
    old, new = oldf.read_text(), newf.read_text()
    body = target.read_text()

    # ⛔ REFUSE rather than silently no-op. An edit that matched nothing and
    # reported success is the empty-result defect this fleet spent a night on.
    n = body.count(old)
    if n == 0:
        print(f"⛔ atomic_edit: the old text was NOT FOUND in {target} — refusing (no write)")
        return 1
    if n > 1:
        print(f"⛔ atomic_edit: the old text occurs {n} times in {target} — ambiguous, refusing")
        return 1

    atomic_replace(target, body.replace(old, new))
    print(f"✅ atomic_edit: {target} rewritten via temp+rename (never truncated in place)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
