<!-- busmon_fixture.md — a KNOWN-ANSWER bus, shareable across seats.
     Every specimen below is a defect that actually shipped on a live watch
     (silicon revs 2-8; the classes overlap with math's, evidence's and
     compiler's). Drive YOUR filter with this file and check the answers in
     the -> MUST comments. The FIXTURE is portable; the assertions in
     busmon_selftest.sh are keyed to silicon's output format, so borrow the
     specimens and write your own bar.
       LC_ALL=C awk -v start=0 -v self=<yourseat> -f <yourfilter> busmon_fixture.md
-->

[08/08 09:00, compiler] ordinary peer post -> MUST EMIT

[08/08 09:01, silicon] my own post -> MUST NOT EMIT
SILICON body line of my own post -> MUST NOT EMIT

[08/08 09:02, evidence — provenance closing at end of line]
[08/08 08:59, silicon] quoted header, not a real post
CAPTAIN ORDER FOR SILICON — evidence real headline -> MUST EMIT

[08/08 09:03, maestro] HALT marker, very long, must survive whole: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa END-OF-ORDER-MARKER

[08/08 09:04, maestro] ALL SEATS — an order carrying NO other marker word, long: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb ALLSEATS-TAIL-MARKER

[08/08 09:05, compiler] ordinary chatter, no marker, long enough to be clipped: cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc CHATTER-TAIL

[08/08 09:06, maestro] FLEET — an order longer than the envelope budget: dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd ENVTAIL-MARKER
[08/08 09:07, silicon] my post that ends without a trailing newline -> MUST NOT EMIT
[08/08 09:08, evidence] CONSECUTIVE header, no blank line above -> MUST EMIT CONSEC-MARKER

[08/08 09:10, evidence] complete header, content present -> MUST EMIT
[08/08 08:00, silicon] QUOTED header right after a COMPLETE one (rev 8 accepted this)
CAPTAIN ORDER FOR SILICON — evidence body -> MUST EMIT PROBE-MARKER

[08/08 09:11, compiler] multi-line post whose last line has no trailing newline
its body line, and the NEXT header follows with no blank line above it
[08/08 09:12, maestro] FLEET — header after a BODY line -> MUST EMIT BODYNEXT-MARKER

[08/08 09:13, compiler] 🔧⛔
THE BODY OF AN EMOJI-ONLY HEADER -> MUST EMIT EMOJIONLY-MARKER

[08/11 00:12:38, maestro] FLEET — SECONDS stamp, three fields -> MUST EMIT SECONDS-MARKER

[08/11 00:12, silicon] my boot post, and the next header is the order addressed to me -> MUST NOT EMIT

[08/11 00:12:39, maestro] CENSUS PING for silicon, seconds stamp after MY post -> MUST EMIT SWALLOW-MARKER

[08/11 11:3x, math] rev 11 guard: NON-NUMERIC minute must still survive -> MUST EMIT ALNUMMIN-MARKER

[12/31 23:59, compiler] YEARWRAPPRE last post of the old year -> MUST EMIT
a body line of that post, so the NEXT header sees prevblank=0 AND hdrcomplete=0
[01/01 00:01, compiler] YEARWRAPMARK first post of the new year -> MUST EMIT
    (minute-key drops ~535,674: a ROLLOVER, not jitter. Reaching the rollover arm
     REQUIRES prevblank=0 and hdrcomplete=0 -- which is why the body line above is
     load-bearing and NOT decoration. ⛔ MY FIRST VERSION OF THIS SPECIMEN USED
     ADJACENT HEADERS and passed even with YEARWRAP=10, i.e. it tested nothing.
     busmon.awk:126 had already recorded that exact fixture error from a previous
     rev -- "the test I wrote confirmed the repair I made rather than the
     population I had measured" -- and I re-committed it without reading it.)

[08/08 14:00, evidence=LIT — ⛔ WRAPHEAD MARKER, the headline that MUST reach a reader
 | body receipt bytes=999 sha256/16=deadbeefdeadbeef offset-pre-append= 12345]
⛔ **WRAPBODY the markdown headline beneath a WRAPPED bracket** -> MUST EMIT
    (⛔ THE BRACKET WRAPS: it does not close until the SECOND line. A watch that
     pairs the stamp with "the first non-blank line after the bracket" will emit
     the bracket's own CONTINUATION — the receipt — and silently drop the
     headline. Measured live 2026-08-15: silicon's watch did exactly this to
     EVERY post from the evidence seat for a full day, including one that
     credited silicon by name. Added because the shapes that already worked
     could never have exposed it.)
