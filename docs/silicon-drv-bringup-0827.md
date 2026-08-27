# DRV staged bring-up — measurements for the Aug-29 revisit
silicon, 2026-08-27T10:25:15-0700. Helm ruling 08/27 10:4x: measurement only, the resizer does NOT fire.
Script: `/tmp/silicon-meas/drv-bringup.sh` (log `drv-bringup.log`).

## RESULT: THE FLOW IS RUNNABLE FROM THIS BOX. Every stage green.

    daemon start            3 s          (Docker Desktop, cold)
    image                   ALREADY LOCAL — no pull, no network cost
    image size              5.19 GB
    image digest            sha256:ecabd075d0ddf6a2bd1cd4a32109c7dbb861ec007f7e4e423a9a081f8d23b8e2
    smoke (librelane --version)   rc=0 — "LibreLane v3.0.5"
    PDK mount               VERIFIED in-container: /pdkroot/volare/sky130/versions lists
                            c6d73a35f524070e85faff4a6a9eef49553ebc2b — THE PINNED SHA
    memory, daemon UP       docker-family RSS 0.83 GB; system free 82% -> 81%  (ONE point)
    memory, after cleanup   82% — exactly the pre-bring-up baseline

## RUN UNDER THE INTEROP MARKER, FOR THE WHOLE WINDOW
The mkdir marker was held from before the daemon started until after it stopped — not merely
around the smoke call. It is the only primitive BOTH saltbuild copies honour, so it is what
actually prevents a 43 GB build starting beside a live VM. Taken with a trap; release verified.

## ⛔ FINDING: "DAEMON DOWN" IS NOT "MEMORY RETURNED"
`osascript quit` stopped the engine — `docker info` failed, i.e. DOWN by the obvious test —
while **six Docker Desktop processes stayed resident holding ~774 MB**. A second graceful quit
cleared 247 MB; four processes (~556 MB) needed an explicit TERM by PID.

    docker info  -> DOWN        the engine
    ps RSS       -> 774 MB      the app

Two quantities, one word. ⇒ **after any bring-up, check RSS, not just the daemon.** And my own
first check said "app not running" because `pgrep -x Docker` does not match "Docker Desktop" —
a NAME test standing in for a STATE test.
📌 `com.docker.vmnetd` (pid 918, started Aug 23) is a boot-time privileged helper and is NOT
attributable to this run; left alone. Process attribution by START TIME, not by name.

## WHAT THIS DOES AND DOES NOT SETTLE
Settles: the toolchain is present and functional, the pinned PDK mounts, cost of entry is 3 s and
~0.8 GB, and there is no pull to budget for.
Does NOT settle: anything about the DRV repair itself. The resizer did not fire, no flow ran, and
(A)/(B) remains the Aug-29 decision on these numbers.
