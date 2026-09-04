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
    reg       load_beat;  // 0 = address loop, 1 = the LOAD's data loop  (option (2))
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
    // ⛔⛔ THE PARAGRAPH BELOW IS ANSWERED — AND IT WAS ANSWERED 2.5 HOURS AFTER IT
    // WAS WRITTEN, IN THIS FILE, ~90 LINES DOWN. It is kept verbatim (struck, not
    // deleted) because compiler cites these lines and because the record matters.
    // ── STRUCK 2026-08-26 19:4x, silicon ──────────────────────────────────────
    //   > ⚠️ AND ONE THING I DO NOT KNOW, LEFT VISIBLE RATHER THAN SMOOTHED:
    //   > `instr_r` is written on the phase-3 edge and `kind`/`store_beat` update
    //   > on that SAME edge, so this decision reads a `c_dmem_req` derived from the
    //   > PREVIOUS instruction. Whether that is off-by-one or exactly right I have
    //   > not proved; the design's §3 was already wrong about its own mechanism
    //   > once, so a plausible story is not good enough here. The bench is what
    //   > speaks.
    // ── THE ANSWER, AND THE BENCH DID SPEAK ───────────────────────────────────
    // THE INSTRUCTION BYPASS (this file, `assign c_instr = …`, ratified 08/18
    // 16:5x — i.e. AFTER the struck paragraph, which was written at 14:2x) makes
    // `c_instr` present the NEWLY ASSEMBLED word at exactly `kind == T_FETCH &&
    // phase == 2'd3`. `loop_end` IS `phase == 2'd3`. So at the decision edge the
    // decode reads the CURRENT instruction, not the previous one.
    // ✅ MEASURED 2026-08-26, BOTH ARMS, by `Sim/wordonly/run_lwsw_bypass_control.sh`:
    //     ARM A  as shipped      → 6/6 PASS
    //     ARM B  bypass defeated → RED, 2/6 FAIL, and it reproduces the recorded
    //            08/18 signature EXACTLY: st_data=00000000, instr=0000a183, rs2=0
    //   ⇒ the bench DISCRIMINATES on this quantity; ARM A's green is evidence and
    //     not a replay. The runner REFUSES if ARM B ever goes green.
    // ⚠️ SCOPE, BECAUSE THIS IS NOT A DISCHARGE OF THE PAIR ITEM: this settles the
    //   RTL side only. compiler's `off_by_one_confined_to_fetch` (`ab6bc2b`) proves
    //   `retire` consults `req` in the FETCH state and NOWHERE ELSE, which is what
    //   makes this RTL fact SUFFICIENT rather than merely encouraging. What remains
    //   unproved is the NETLIST↔Lean correspondence (`sem (bridge nl outs) ≡ runP`),
    //   and that is the bridge induction already routed off this seat — a KNOWN
    //   blocker, not a new one.
    // ⭐⭐ OPTION (2) — §7's "+4" SECOND LOAD LOOP. RATIFIED: council 09/04
    // ruling (7), *"FF RATIFIED — NDF option (2) on the double signature"*, on
    // silicon's signature 09/03 18:34:07 and compiler's 18:27.
    //
    // ── WHAT IT CHANGES, IN ONE SENTENCE ────────────────────────────────────────
    // A `T_LOAD` now owns TWO loops instead of one — an ADDRESS loop and a DATA
    // loop — exactly as a `T_STORE` always has. `load_beat` mirrors `store_beat`.
    // ⇒ EVERY MEMORY TRANSACTION IS NOW EXACTLY TWO LOOPS. §7's CPI table is the
    //   price and already carries it: LW 8 -> 12, SW 12 unchanged, non-memory 4.
    //
    // ── WHY, AND THE MEASUREMENT THAT FORCED IT ────────────────────────────────
    // §7: *"THE LOAD ROW ASSUMES READ DATA RETURNS ON `ui` DURING THE ADDRESS
    // PHASES ... If the host cannot turn a read around in-phase, every LOAD row
    // below gains 4."* The RP2040 as a PIO memory server CANNOT: it samples a pin
    // on one clock edge and can drive a response only on a later one.
    // ✅ MEASURED, RED-FIRST, by Sim/reghost/tb_plane32bus_reghost.v, whose host
    //    drives `pin_in` from a FLOP: against the ONE-loop LOAD the loaded word
    //    never reaches a register (`x3=00000000`, G3 and G4 RED, 2/6) while the
    //    store path — which needs no turnaround — stays green. That green control
    //    is what makes the red a finding about the LOAD row and not about the bench.
    //
    // ⛔ COMPILER'S AMENDMENT 1, HONOURED. My 09/03 sentence *"needs no change to
    //    the ratified arbitration"* was true of the ARBITRATION RULE and let the
    //    reader carry it to THE MODULE, which is false: this DOES change `retire`
    //    for `T_LOAD`, and therefore compiler's kernel model. Cheap and bounded is
    //    not free, and the bill is named here rather than discovered downstream.
    //
    // ⛔⛔ COMPILER'S AMENDMENT 2 IS **NOT** DISCHARGED BY THIS EDIT AND MUST NOT
    //    BE READ AS DISCHARGED. The `sof` arm still does not consult `retire` —
    //    the latent asymmetry measured 09/03 (a one-cycle `sof` at a retiring
    //    phase-3 edge re-issues a completed transaction). That is a SEPARATE
    //    two-signature row. The `sof` arm below clears `load_beat` for exactly the
    //    reason it already clears `store_beat` — a realign reframes the
    //    transaction — and that is the SAME TREATMENT, NOT THE REPAIR.
    always @(posedge clk)
        if (!rst_n) begin kind <= T_FETCH; store_beat <= 1'b0; load_beat <= 1'b0; end
        else if (sof) begin
            store_beat <= 1'b0;
            load_beat  <= 1'b0;
            kind <= c_dmem_req ? (c_dmem_we ? T_STORE : T_LOAD) : T_FETCH;
        end
        else if (loop_end) begin
            if (retire) begin
                // the instruction is DONE — by the frame's own decode, not by a
                // request that cannot fall. Next loop fetches the next one.
                kind       <= T_FETCH;
                store_beat <= 1'b0;
                load_beat  <= 1'b0;
            end else if (kind == T_FETCH) begin
                // a committed memory instruction: its ADDRESS loop is next.
                // `c_dmem_we` is isSW, a pure decode — no DriveMap exposure.
                kind       <= c_dmem_we ? T_STORE : T_LOAD;
                store_beat <= 1'b0;
                load_beat  <= 1'b0;
            end else begin
                // reachable ONLY as "a memory transaction that has sent its
                // ADDRESS": under option (2) that is a T_STORE with store_beat=0
                // OR a T_LOAD with load_beat=0 — for both, `retire` is 0 at this
                // loop_end, so both fall here. `kind` is deliberately NOT
                // reassigned: the type code stays put so the host knows the second
                // loop belongs to the same transaction.
                if (kind == T_STORE) store_beat <= 1'b1;
                else                 load_beat  <= 1'b1;
            end
        end

    // §2's derivation, verbatim: a DECODE of the frame, introducing no new state.
    // ⭐ THE ONE-LINE HEART OF OPTION (2): `T_LOAD`'s arm was `1'b1` — retire on the
    //   address loop, giving the host no turnaround at all. It is now `load_beat`,
    //   which is the exact mirror of the store's arm one line below it.
    assign retire = loop_end && ( (kind == T_FETCH) ? ~c_dmem_req
                                : (kind == T_LOAD)  ? load_beat
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
                    // ⭐ OPTION (2): a LOAD's read data arrives in its SECOND loop.
                    // Gating on `load_beat` is not decoration — without it the
                    // ADDRESS loop would commit whatever the host happened to be
                    // driving while it was still being told the address, and the
                    // data loop's correct word would then be overwritten by nothing.
                    if (kind == T_LOAD && load_beat) rdata_r <= {pin_in, in_acc[23:0]};
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
