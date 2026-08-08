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
