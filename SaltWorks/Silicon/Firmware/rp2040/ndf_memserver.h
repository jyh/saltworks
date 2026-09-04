/* ndf_memserver.h — THE RP2040 BYTE-PHASE MEMORY SERVER, PROTOCOL CORE.
 *
 * Written against RATIFIED OPTION (2) — §7's "+4" second LOAD loop (council
 * 09/04 ruling (7), on silicon's signature 09/03 18:34:07 and compiler's 18:27).
 *
 * ⭐ THE CORE IS PURE C AND TOUCHES NO SDK. That is deliberate and it is the
 *    whole reason this firmware has a receipt: `ndf_step()` is replayed against
 *    a PIN TRACE emitted by the Verilog bench that scores 6/6, and compared BYTE
 *    FOR BYTE at every phase the DUT actually consumes. Firmware whose protocol
 *    logic can only be tested on the bench-top is firmware nobody can check.
 *
 * THE PROTOCOL, as busadapt8.v implements it after option (2):
 *   · one loop = 4 phases = 4 DUT clocks; the phase counter FREE-RUNS (decision 3)
 *   · `uio_out[1:0]` carries TYPE at phase 0 and the PHASE NUMBER at 1..3 (decision 1)
 *       00 IDLE   01 FETCH   10 LOAD   11 STORE
 *   · `uio_in[6]` = `sof` forces phase 0 — the HOST realigns the frame (decision 2),
 *     which is why this server may keep its own phase counter and never guess.
 *   · FETCH  1 loop : chip drives PC bytes on uo_out, host drives instr on ui_in
 *   · LOAD   2 loops: (1) chip drives EA bytes   (2) HOST drives read data   <- option (2)
 *   · STORE  2 loops: (1) chip drives EA bytes   (2) chip drives wdata bytes
 *   ⇒ EVERY MEMORY TRANSACTION IS EXACTLY TWO LOOPS. CPI: non-mem 4, LW 12, SW 12.
 */
#ifndef NDF_MEMSERVER_H
#define NDF_MEMSERVER_H
#include <stdint.h>

#define NDF_T_IDLE  0u
#define NDF_T_FETCH 1u
#define NDF_T_LOAD  2u
#define NDF_T_STORE 3u

#define NDF_MEM_BYTES 256u   /* the harness memory: byte-addressed, 8-bit address */

typedef struct {
    uint8_t  phase;        /* the host's OWN phase counter, aligned by the sof it drove */
    uint8_t  type;         /* transaction type, latched at phase 0 */
    uint8_t  beat;         /* 0 = address loop, 1 = the transaction's DATA loop */
    uint8_t  a[4];         /* bytes handed over during the current loop */
    uint8_t  st_addr[4];   /* a STORE's address, held across its two loops */
    uint32_t word;         /* the word this server is streaming back (FETCH or LOAD) */
    uint8_t  mem[NDF_MEM_BYTES];
    uint8_t  prog[NDF_MEM_BYTES];

    /* ── self-checks. A server that has silently lost the frame must SAY SO. ──
     * `desync` counts phases where the chip's own phase pins disagree with this
     * server's counter. It can only ever be checked at phases 1..3, because at
     * phase 0 those pins carry the TYPE instead — so a zero here is a real
     * measurement over 3 of every 4 phases and NOT a vacuous one. */
    uint32_t desync;
    uint32_t n_fetch_loops, n_load_loops, n_store_loops, n_idle_loops;
    uint32_t n_consumed;   /* phases where the DUT actually latches what we drove */
} ndf_server_t;

void    ndf_init(ndf_server_t *s);
/* One bus phase, from the host's side.
 *   pp   — uio_out[1:0] as visible right now (TYPE at phase 0, else the phase)
 *   pout — the byte the chip is driving on uo_out right now
 * returns the byte the host must drive on ui_in for THIS phase.
 * *consumed (may be NULL) is set iff the DUT latches this byte into a word it
 * will use — i.e. a FETCH phase or a LOAD DATA phase. Everywhere else ui_in is
 * a don't-care by the protocol, and saying so explicitly is what keeps the
 * replay check from quietly comparing bytes that mean nothing. */
uint8_t ndf_step(ndf_server_t *s, uint8_t pp, uint8_t pout, int *consumed);
#endif
