/* ndf_pico_main.c — THE SDK GLUE. The protocol lives in ndf_memserver.c; this
 * file is only wires, and it is the ONLY file here that needs the pico SDK.
 *
 * ⛔⛔ NOT COMPILED AT THIS HAND AND I AM SAYING SO RATHER THAN LETTING THE FILE
 *    IMPLY IT. There is no pico SDK and no RP2040 on this box. What IS measured
 *    is the part that can be: `ndf_memserver.c` is replayed against the Verilog
 *    bench's own pin trace and compared byte for byte (run_firmware_replay.sh).
 *    This file is UNRUN CODE — its TEXT is as unverified as its logic, which is
 *    this seat's fourth form of "a check never shown to fail".
 *
 * ⛔ AND THE PIN NUMBERS BELOW ARE PLACEHOLDERS, MARKED, NOT GUESSED-AND-HIDDEN.
 *    They must be taken from the demo board pinout before this is flashed. I did
 *    not have that document at this hand and a plausible-looking GPIO number is
 *    exactly the kind of figure this seat has been bitten by.
 */
#include "hardware/pio.h"
#include "hardware/gpio.h"
#include "pico/stdlib.h"
#include "ndf_bus.pio.h"
#include "ndf_memserver.h"

/* ⚠️ SET THESE FROM THE DEMO BOARD PINOUT. Placeholders. */
#define PIN_UI_IN_BASE   0u    /* ui_in[0] .. ui_in[7], consecutive     */
#define PIN_UO_OUT_BASE  8u    /* uo_out[0] .. uo_out[7], consecutive   */
#define PIN_UIO_BASE    16u    /* uio[0], uio[1] = phase pins           */
#define PIN_SOF         22u    /* uio_in[6] = sof                       */
#define PIN_CLK         24u    /* the project clock                     */
#define PIN_RST_N       25u

static ndf_server_t srv;

int main(void)
{
    stdio_init_all();
    ndf_init(&srv);
    /* load the program image and the initial data image into srv.prog / srv.mem
     * before releasing reset — the server answers from these and nothing else. */

    gpio_init(PIN_SOF);    gpio_set_dir(PIN_SOF,    GPIO_OUT);
    gpio_init(PIN_RST_N);  gpio_set_dir(PIN_RST_N,  GPIO_OUT);
    for (uint i = 0; i < 8; i++) { gpio_init(PIN_UO_OUT_BASE + i); gpio_set_dir(PIN_UO_OUT_BASE + i, GPIO_IN); }
    for (uint i = 0; i < 2; i++) { gpio_init(PIN_UIO_BASE    + i); gpio_set_dir(PIN_UIO_BASE    + i, GPIO_IN); }

    PIO  pio    = pio0;
    uint sm     = 0;
    uint offset = pio_add_program(pio, &ndf_bus_program);
    ndf_bus_program_init(pio, sm, offset, PIN_UI_IN_BASE, PIN_CLK);

    /* Reset, then realign the frame with our own `sof` so the server's phase
     * counter and the chip's cannot disagree about where phase 0 is (busadapt8
     * decision 2 exists for exactly this). */
    gpio_put(PIN_RST_N, 0);
    gpio_put(PIN_SOF,   1);
    for (int i = 0; i < 8; i++) pio_sm_put_blocking(pio, sm, 0x00);
    gpio_put(PIN_RST_N, 1);
    gpio_put(PIN_SOF,   0);
    srv.phase = 0;

    for (;;) {
        /* The SM is stalled at `pull` with clk LOW, so every chip output is
         * stable and we may take as long as we like here. Read the pins, decide
         * the byte, hand it over; the handover is what advances the DUT by one
         * phase. Nothing in this loop is timed. */
        uint32_t all  = gpio_get_all();
        uint8_t  pout = (uint8_t)((all >> PIN_UO_OUT_BASE) & 0xFFu);
        uint8_t  pp   = (uint8_t)((all >> PIN_UIO_BASE)    & 0x03u);

        uint8_t  drive = ndf_step(&srv, pp, pout, 0);
        pio_sm_put_blocking(pio, sm, drive);

        if (srv.desync) { /* the frame is lost — re-`sof` rather than serve garbage */ }
    }
}
