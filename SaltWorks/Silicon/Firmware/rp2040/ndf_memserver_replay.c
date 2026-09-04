/* ndf_memserver_replay.c — REPLAY THE FIRMWARE'S PROTOCOL CORE AGAINST THE
 * VERILOG BENCH'S OWN PIN TRACE, AND COMPARE BYTE FOR BYTE.
 *
 * ⭐ WHY THIS EXISTS. Firmware for a board nobody here has is unrun code, and
 *   unrun code's TEXT is as unverified as its logic. The one thing that CAN be
 *   measured on this box is whether the server's protocol state machine emits
 *   THE SAME BYTES, IN THE SAME PHASES, as the registered host that scored 6/6
 *   in Sim/reghost/tb_plane32bus_reghost.v. That is what this does.
 *
 * INPUT: `TRACE <phase_pins> <uo_out> <ui_in>` lines, one per DUT cycle, emitted
 *        by that bench under -DTRACE and sampled at the negedge (mid-phase).
 *
 * ⛔ THE COMPARISON IS RESTRICTED TO PHASES THE DUT ACTUALLY CONSUMES — a FETCH
 *   phase or a LOAD DATA phase. Everywhere else `ui_in` is a don't-care by the
 *   protocol (busadapt8 gates its capture on `kind` and `load_beat`), so
 *   comparing there would be comparing noise. A restricted comparison is exactly
 *   where a check goes vacuous, so F3 pins the COUNT of compared phases to a
 *   number DERIVED FROM THE PROTOCOL rather than from the trace.
 */
#include <stdio.h>
#include <string.h>
#include "ndf_memserver.h"

int main(void)
{
    ndf_server_t s;
    ndf_init(&s);

    /* the program image, byte-identical to the bench's `progword` (which indexes
     * on a[3:2], so the 16-byte block repeats through the whole address space) */
    static const uint32_t blk[4] = {
        0x04000093u,  /* addi x1, x0, 64  */
        0x0010A023u,  /* sw   x1, 0(x1)   */
        0x0000A183u,  /* lw   x3, 0(x1)   */
        0x00000013u   /* nop              */
    };
    for (unsigned i = 0; i < NDF_MEM_BYTES; i++)
        s.prog[i] = (uint8_t)(blk[(i >> 2) & 3u] >> (8u * (i & 3u)));

    unsigned long line = 0, compared = 0, mismatch = 0;
    unsigned long load_data_phases = 0;
    int  pp; unsigned pout, uin;
    char buf[256];
    unsigned first_bad_line = 0, first_bad_got = 0, first_bad_want = 0;

    while (fgets(buf, sizeof buf, stdin)) {
        if (strncmp(buf, "TRACE ", 6) != 0) continue;
        if (sscanf(buf + 6, "%d %x %x", &pp, &pout, &uin) != 3) continue;
        line++;

        int consumed = 0;
        uint8_t drive = ndf_step(&s, (uint8_t)pp, (uint8_t)pout, &consumed);
        if (consumed) {
            compared++;
            if (s.type == NDF_T_LOAD) load_data_phases++;
            if (drive != (uint8_t)uin) {
                if (!mismatch) { first_bad_line = (unsigned)line;
                                 first_bad_got = drive; first_bad_want = uin; }
                mismatch++;
            }
        }
    }

    unsigned long expect = 4ul * s.n_fetch_loops + 4ul * (s.n_load_loops / 2ul);
    uint32_t mem64 = (uint32_t)s.mem[64] | ((uint32_t)s.mem[65] << 8)
                   | ((uint32_t)s.mem[66] << 16) | ((uint32_t)s.mem[67] << 24);

    printf("  trace cycles=%lu  loops: FETCH=%u LOAD=%u STORE=%u IDLE=%u\n",
           line, s.n_fetch_loops, s.n_load_loops, s.n_store_loops, s.n_idle_loops);
    printf("  phases compared=%lu (of which LOAD data=%lu)  mismatches=%lu  desync=%u\n",
           compared, load_data_phases, mismatch, s.desync);
    printf("  server memory mem[64..67]=%08x\n", mem64);
    if (mismatch)
        printf("  FIRST MISMATCH at trace line %u: server drove %02x, bench drove %02x\n",
               first_bad_line, first_bad_got, first_bad_want);

    int fails = 0;
    #define CHK(c, n) do { if (c) printf("  F-pass  %s\n", n); \
                          else { printf("  F-FAIL  %s\n", n); fails++; } } while (0)
    printf("  ---- firmware replay criteria ----\n");
    CHK(line > 100,            "F0 the trace actually arrived (not an empty stdin)");
    CHK(s.desync == 0,         "F1 the server never lost the frame (phases 1..3, 3 of every 4)");
    CHK(mismatch == 0,         "F2 every CONSUMED phase matches the bench byte for byte");
    CHK(compared == expect,    "F3 the compared-phase COUNT equals the protocol's own prediction");
    CHK(mem64 == 64u,          "F4 the server's OWN memory holds the stored word (store path)");
    CHK(s.n_load_loops > 0 && s.n_load_loops == 2u * (s.n_load_loops / 2u),
                               "F5 LOAD loops come in PAIRS — the server saw option (2)'s +4");
    if (!fails) { printf("==> FIRMWARE REPLAY: ALL PASS (6/6)\n"); return 0; }
    printf("==> FIRMWARE REPLAY RED: %d/6 FAILED\n", fails);
    return 1;
}
