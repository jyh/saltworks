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
    // ⭐⭐ SHAPE A — `kind` CONSULTS `retire`. RATIFIED by the Captain 2026-08-18
    // 14:2x ("yes, ratify shape A") after compiler showed shapes A and B
    // EQUIVALENT for its object, which put the choice here alone.
    //
    // ── WHAT WAS WRONG, AND IT IS NOT WHAT §3 OF THE DESIGN SAYS ────────────────
    // The 08/18 ruling: `retire` appeared NOWHERE in this arbitration, and what
    // actually released the fetch was `instr_r` committing UNGATED. THE TWO
    // DEFECTS CANCELLED. Concretely, the old `else` arm re-derived `kind` from
    // `c_dmem_req` at every loop boundary — including after a LOAD or a completed
    // STORE. But `c_dmem_req` is a PURE DECODE of the instruction still held in
    // `instr_r`, so it CANNOT FALL until a new instruction is fetched: the old
    // code asked "is there a memory request?" of a signal that answers YES for as
    // long as the same instruction is loaded. It only ever escaped because
    // `instr_r` updated behind its back.
    //
    // ── WHY SHAPE A AND NOT SHAPE B ("the request clears on retire") ────────────
    // `SaltWorks/Certs/DmemKernelBridge.lean` declares
    //     req : ins 32 = (ctrlSpec w)[7]!
    // i.e. `dmem_req` is a PURE FUNCTION OF THE INSTRUCTION WORD, and its
    // docstring says it is "assumed here and proved nowhere, deliberately".
    // Making it clear on retire turns it into a function of CYCLE STATE, so
    // `DriveMap` becomes FALSE at that port — and being an ASSUMED hypothesis,
    // NOTHING WOULD CATCH IT: F4 door 1 would rest on a false premise with a
    // green build. It also reaches a composition nobody was changing, because
    // `memplane8` discharges `DriveMap` BY DIRECT WIRE.
    // ⇒ So the sequencing lives HERE, where no proof binds, and `c_dmem_we`
    //   below is read as a PURE DECODE only (DriveMap-safe).
    //
    // ⛔ THE SCOPE OF THE RULING, IN THE RULING'S OWN TERMS — do not let a green
    // here be read as any of these:
    //   · it REPAIRS the arbitration.
    //   · it does NOT close criterion (c). Compiler's `Env` question is open:
    //     `stalls : Env → Bool` and `retire` is not a function of `Env`.
    //   · it does NOT ratify the enable. `en = retire` remains a MARKED
    //     VALIDATION ARTIFACT and `plane32bus` carries that marking forward.
    //
    // ⚠️ AND ONE THING I DO NOT KNOW, LEFT VISIBLE RATHER THAN SMOOTHED: `instr_r`
    // is written on the phase-3 edge and `kind`/`store_beat` update on that SAME
    // edge, so this decision reads a `c_dmem_req` derived from the PREVIOUS
    // instruction. Whether that is off-by-one or exactly right I have not proved;
    // the design's §3 was already wrong about its own mechanism once, so a
    // plausible story is not good enough here. The bench is what speaks.
    always @(posedge clk)
        if (!rst_n) begin kind <= T_FETCH; store_beat <= 1'b0; end
        else if (sof) begin
            store_beat <= 1'b0;
            kind <= c_dmem_req ? (c_dmem_we ? T_STORE : T_LOAD) : T_FETCH;
        end
        else if (loop_end) begin
            if (retire) begin
                // the instruction is DONE — by the frame's own decode, not by a
                // request that cannot fall. Next loop fetches the next one.
                kind       <= T_FETCH;
                store_beat <= 1'b0;
            end else if (kind == T_FETCH) begin
                // a committed memory instruction: its ADDRESS loop is next.
                // `c_dmem_we` is isSW, a pure decode — no DriveMap exposure.
                kind       <= c_dmem_we ? T_STORE : T_LOAD;
                store_beat <= 1'b0;
            end else begin
                // reachable ONLY as "a store that has sent its address": for
                // T_LOAD retire is 1 at loop_end, and for T_STORE with
                // store_beat=1 retire is 1, so both take the first arm. `kind`
                // is deliberately NOT reassigned — the type code stays T_STORE so
                // the host knows the datum is coming.
                store_beat <= 1'b1;
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

    // ⭐⭐ THE INSTRUCTION BYPASS — RATIFIED 2026-08-18 16:5x on the receipts in
    // docs/silicon-candidate-instr-bypass-0818.md, under two conditions recorded there.
    //
    // THE DEFECT IT REPAIRS, measured by Sim/wordonly/tb_plane32bus_lwsw.v: the
    // arbitration at a fetch's phase-3 edge reads `c_dmem_req`/`c_dmem_we`, which
    // core32 decodes from `instr` — and at that instant `instr_r` still held the
    // PREVIOUS instruction. So the transaction following fetch-of-N served N-1 while
    // the core already saw N. At a store commit: dmem_addr=0x40 with
    // dmem_wdata=0x00000000, instr_r=0000a183 (the `lw`, rs2=x0), regs[1]=0x40.
    // ⚠️ THE STORE ADDRESS LOOKED CORRECT ONLY BY COINCIDENCE — both instructions use
    //   x1 as base, so the DATA was the only quantity that could expose it.
    //
    // ⛔ AND `c_instr` IS NOW A MUX, WHICH IS A FACT A CONSUMER MUST READ. compiler
    // re-worded F4 door 1's satisfaction argument for exactly this at `a212073`:
    // DriveMap STILL HOLDS because `w` is a PARAMETER, but it must be instantiated at
    // a pure decode of the CURRENT `c_instr` and never at "whatever is in instr_r" —
    // a consumer that silently fixes the latter is wrong for one cycle per fetch loop,
    // and that is precisely the cycle this repair exists to change.
    //
    // ⚠️ IT ALSO CHANGES `retire`'s TIMING SEMANTICS, SIGNED as decQ-visible: at a
    // fetch's phase 3 retire is computed from the NEW instruction, so a non-memory
    // instruction retires at the end of ITS OWN fetch. Not a pure bugfix; ratified.
    assign c_instr      = (kind == T_FETCH && phase == 2'd3)
                            ? {pin_in, in_acc[23:0]}
                            : instr_r;
    assign c_dmem_rdata = rdata_r;
endmodule
