/* ndf_memserver.c — protocol core. Pure C, no SDK. See ndf_memserver.h. */
#include "ndf_memserver.h"
#include <string.h>

static uint32_t rd32(const uint8_t *m, uint8_t a)
{
    /* low byte first, per slicea16bma's contract and busadapt8's inbound assembly */
    return (uint32_t)m[(uint8_t)(a)]
         | ((uint32_t)m[(uint8_t)(a + 1)] << 8)
         | ((uint32_t)m[(uint8_t)(a + 2)] << 16)
         | ((uint32_t)m[(uint8_t)(a + 3)] << 24);
}

void ndf_init(ndf_server_t *s)
{
    memset(s, 0, sizeof(*s));
    s->type = NDF_T_IDLE;
}

uint8_t ndf_step(ndf_server_t *s, uint8_t pp, uint8_t pout, int *consumed)
{
    uint8_t phase = s->phase;
    uint8_t drive = 0x00;
    int     used  = 0;

    if (phase == 0) {
        s->type = (uint8_t)(pp & 3u);
        switch (s->type) {
            case NDF_T_FETCH: s->n_fetch_loops++; break;
            case NDF_T_LOAD:  s->n_load_loops++;  break;
            case NDF_T_STORE: s->n_store_loops++; break;
            default:          s->n_idle_loops++;  break;
        }
    } else if ((pp & 3u) != phase) {
        /* the chip says it is somewhere else in the frame than we think it is */
        s->desync++;
    }

    s->a[phase] = pout;

    switch (s->type) {
    case NDF_T_FETCH:
        /* ⛔ THE FETCH IS IN-PHASE AND OPTION (2) DID NOT CHANGE THAT. §7 gained
         * "+4" on the LOAD row only, while its own text says the load's
         * assumption holds "exactly as the instruction does during a fetch".
         * So at phase 0 this server must produce instr[7:0] from an address byte
         * it is being handed IN THE SAME PHASE. That is satisfiable HERE only
         * because the host owns the clock and the PIO SM is stalled with clk LOW
         * while this function runs (see ndf_bus.pio) — the turnaround is a
         * software step, not a nanosecond budget.
         * ⇒ UNDER A FREE-RUNNING CLOCK THIS PATH DOES NOT HOLD. Measured: with
         *   the fetch registered, the machine executes 225 fetch loops and ZERO
         *   memory transactions (Sim/reghost, arm REGHOST_FETCH). That gap is a
         *   SEPARATE two-signature row and is NOT part of option (2). */
        if (phase == 0) s->word = rd32(s->prog, pout);   /* pout = PC[7:0] */
        drive = (uint8_t)(s->word >> (8u * phase));
        used  = 1;
        break;

    case NDF_T_LOAD:
        if (!s->beat) {
            /* ── the ADDRESS loop. The chip is telling us where to read. The DUT
             * does NOT latch ui_in this loop (busadapt8's capture is gated on
             * `load_beat`), so what we drive here is a don't-care by protocol. */
            if (phase == 3) {
                /* ⭐ THIS IS WHAT OPTION (2) BOUGHT: the lookup happens at the END
                 * of the address loop, with the WHOLE address in hand, and the
                 * first data byte is not due until the NEXT phase 0. A registered
                 * host — which is what an RP2040 PIO memory server is — has no
                 * other way to answer. Deliberately written this way even though
                 * the stalled clock would forgive a later lookup, so that this
                 * path stays correct if the clock is ever let free-run. */
                s->word = rd32(s->mem, s->a[0]);
            }
        } else {
            drive = (uint8_t)(s->word >> (8u * phase));
            used  = 1;
        }
        break;

    case NDF_T_STORE:
        if (!s->beat) {
            s->st_addr[phase] = pout;
        } else if (phase == 3) {
            uint8_t base = s->st_addr[0];
            s->mem[(uint8_t)(base    )] = s->a[0];
            s->mem[(uint8_t)(base + 1)] = s->a[1];
            s->mem[(uint8_t)(base + 2)] = s->a[2];
            s->mem[(uint8_t)(base + 3)] = pout;
        }
        break;

    default:
        break;
    }

    if (used) s->n_consumed++;

    if (phase == 3) {
        /* loop boundary: a LOAD or a STORE owns a second loop; a FETCH does not */
        if ((s->type == NDF_T_LOAD || s->type == NDF_T_STORE) && !s->beat) s->beat = 1;
        else                                                               s->beat = 0;
    }
    s->phase = (uint8_t)((phase + 1u) & 3u);

    if (consumed) *consumed = used;
    return drive;
}
