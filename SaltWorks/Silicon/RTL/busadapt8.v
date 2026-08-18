// busadapt8 — THE BYTE-PHASE BUS ADAPTER. Rung zero's first object.
//
// §7 of docs/silicon-offboard-data-block-0817.md specifies this and nothing
// implemented it. The rev-3 refuters found §7 carried THREE FATALS at the pins;
// under the Captain's act-and-account licence ("you can strike out and present a
// clear explanation at council") each is DECIDED here rather than referred upward,
// and each decision is chosen to PRESERVE AN EXISTING CONTRACT rather than to
// invent a new one.
//
// ── DECISION 1 · TRANSACTION TYPE IS CARRIED ON THE PHASE PINS AT PHASE 0 ───────
// FATAL: "the four transaction types are INDISTINGUISHABLE at the interface — the
// host must drive `ui` for FETCH and LOAD but not STORE, and no chip→host signal
// says which." There are no free pins (all 24 allocated, §1/§6), so a new port is
// not available. DECIDED: `uio_out[1:0]` carries TYPE during phase 0 and the PHASE
// NUMBER during phases 1..3. The host already samples those pins every cycle to
// align; it now learns the type in the same sample, at zero pin cost.
//   TYPE encoding, phase 0:  00 IDLE   01 FETCH   10 LOAD   11 STORE
//
// ── DECISION 2 · `sof` BECOMES A CORE INPUT ────────────────────────────────────
// FATAL: "the `sof` framing the design assumes HAS NO PORT ON THE CORE." It is a
// real omission: decision 1 is meaningless unless the host and the core agree WHERE
// phase 0 is. DECIDED: `sof` is an input that forces the phase counter to 0. The
// NDF top already routes `uio_in[6]` to `sof` for the fabric, so the pin exists and
// the wire is free to fan out — no pin cost, and the two consumers cannot disagree
// about frame start because they read the same net.
//
// ── DECISION 3 · THE PHASE COUNTER FREE-RUNS ───────────────────────────────────
// FATAL: "the gate-level bench asserts `phase_o` increments mod 4 EVERY cycle,
// which the arbitration rule would break." Two ways out: stall the counter during a
// data transaction (breaks the bench and the host's alignment), or let it free-run
// and make transactions occupy WHOLE 4-PHASE LOOPS. DECIDED: FREE-RUN.
//   · the existing bench assertion stays TRUE — no contract is broken
//   · the host's alignment rule is unchanged
//   · the cost is granularity: a transaction is a whole number of loops, so the
//     worst case stays §7's CPI 12 (fetch 4 + address 4 + store data 4) and never
//     improves on it. That cost is REAL and is the price of not breaking the bench.
//
// ⚠️ WHAT IS NOT DECIDED HERE: there is still NO NOT-READY SIGNAL. A host slower
// than the free-running counter cannot stall this core, because under (d) there is
// no pin for one. §7 named that and it remains open — decisions 1-3 do not close
// it and must not be read as closing it.
//
// NOT a submission artifact. Draft under act-and-account: re-shaping by criterion
// (c) tomorrow is a RETRACTION, and retractions are cheap by the Captain's register.
module busadapt8(clk, rst_n, sof,
                 c_imem_addr, c_dmem_addr, c_dmem_wdata, c_dmem_req, c_dmem_we,
                 c_instr, c_dmem_rdata,
                 pin_in, pin_out, phase_pins, retire);
    input         clk, rst_n, sof;
    // from the 32-bit-parallel core
    input  [31:0] c_imem_addr, c_dmem_addr, c_dmem_wdata;
    input         c_dmem_req, c_dmem_we;
    // to the core (assembled)
    output [31:0] c_instr, c_dmem_rdata;
    // the pins
    input  [7:0]  pin_in;      // ui_in  — returned byte, low byte first
    output [7:0]  pin_out;     // uo_out — address byte, then store-data byte
    output [1:0]  phase_pins;  // uio_out[1:0] — TYPE at phase 0, PHASE at 1..3
    // ⚠️ ENABLE LANDED FOR VALIDATION — SHAPE AWAITING COMPILER SEAM CHECK.
    // `retire` is ONE WIRE and the stall predicate is its complement (design §1).
    // Landed under the helm's raised ceiling to CLOSE THE LOOP AND MEASURE; its
    // shape where it meets compiler's predicate is NOT settled here and must not
    // be read as ratified. Two signatures are owed before that.
    output        retire;

    // ---- decision 3: the phase counter free-runs, sof realigns it -------------
    reg [1:0] phase;
    always @(posedge clk)
        if (!rst_n)   phase <= 2'd0;
        else if (sof) phase <= 2'd0;
        else          phase <= phase + 2'd1;

    // ---- loop kind. A data transaction owns the NEXT whole loop (FETCH YIELDS
    //      TO DATA, §7). `pend` latches the request at the loop boundary so a
    //      transaction never starts mid-loop and never straddles two.
    localparam T_IDLE = 2'b00, T_FETCH = 2'b01, T_LOAD = 2'b10, T_STORE = 2'b11;
    reg [1:0] kind;      // what THIS loop is doing
    reg       store_beat; // 0 = address loop, 1 = the store's data loop
    wire      loop_end = (phase == 2'd3);

    // ⛔ MID-LOOP `sof` TRUNCATION — the executor's residual (1), and it was REAL.
    // `sof` forced `phase` to 0 at ANY cycle while `kind`/`store_beat` only updated at
    // loop_end, so a mid-loop realign left the FRAME restarted and the TRANSACTION
    // mid-flight: 2 mis-locks over 56 join points, bounded to 2 wrong cycles by a
    // re-arming decoder. My own bench never caught it because it pulses `sof` when
    // phase is ALREADY 0 (tb:45) — a test of the case that cannot fail.
    // FIXED HERE rather than pushed into the spec: `sof` now reframes the TRANSACTION
    // as well as the counter. A host that realigns gets a clean loop boundary, which
    // is what realigning is FOR.
    always @(posedge clk)
        if (!rst_n) begin kind <= T_FETCH; store_beat <= 1'b0; end
        else if (sof) begin
            store_beat <= 1'b0;
            kind <= c_dmem_req ? (c_dmem_we ? T_STORE : T_LOAD) : T_FETCH;
        end
        else if (loop_end) begin
            if (kind == T_STORE && !store_beat) begin
                // a store owns a SECOND loop for its data; the type code stays
                // T_STORE so the host knows the datum is coming.
                store_beat <= 1'b1;
            end else begin
                store_beat <= 1'b0;
                kind <= c_dmem_req ? (c_dmem_we ? T_STORE : T_LOAD) : T_FETCH;
            end
        end

    // §2's derivation, verbatim: a DECODE of the frame, introducing no new state.
    assign retire = loop_end && ( (kind == T_FETCH) ? ~c_dmem_req
                                : (kind == T_LOAD)  ? 1'b1
                                : (kind == T_STORE) ? store_beat : 1'b1 );

    // ---- decision 1: TYPE at phase 0, PHASE at 1..3 --------------------------
    assign phase_pins = (phase == 2'd0) ? kind : phase;

    // ---- outbound byte select ------------------------------------------------
    wire [31:0] out_word = (kind == T_FETCH) ? c_imem_addr
                         : (kind == T_STORE && store_beat) ? c_dmem_wdata
                         : c_dmem_addr;
    assign pin_out = (phase == 2'd0) ? out_word[7:0]
                   : (phase == 2'd1) ? out_word[15:8]
                   : (phase == 2'd2) ? out_word[23:16]
                                     : out_word[31:24];

    // ---- inbound assembly. Low byte first, per slicea16bma's contract. -------
    reg [31:0] in_acc, instr_r, rdata_r;
    always @(posedge clk)
        if (!rst_n) begin in_acc <= 32'd0; instr_r <= 32'd0; rdata_r <= 32'd0; end
        else begin
            case (phase)
                2'd0: in_acc[7:0]   <= pin_in;
                2'd1: in_acc[15:8]  <= pin_in;
                2'd2: in_acc[23:16] <= pin_in;
                2'd3: begin
                    // commit the assembled word to whichever consumer this loop served
                    if (kind == T_FETCH) instr_r <= {pin_in, in_acc[23:0]};
                    if (kind == T_LOAD)  rdata_r <= {pin_in, in_acc[23:0]};
                end
            endcase
        end

    assign c_instr      = instr_r;
    assign c_dmem_rdata = rdata_r;
endmodule
