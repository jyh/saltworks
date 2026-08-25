#!/usr/bin/env python3
"""Stack two same-width PNGs vertically. Encoder is the COMMITTED fig4_render.py's
write_png, imported by path and sha-pinned; decoder is stdlib zlib only."""
import sys, zlib, struct, hashlib, importlib.util

TOOL = "/Users/jyh/projects/claude/saltworks/docs/silicon-tools/fig4_render.py"
WANT = "218314e8492dd25818d5416591660a2c97fc20e395740fc5389c0a06b3023dda"
got = hashlib.sha256(open(TOOL,'rb').read()).hexdigest()
if got != WANT:
    sys.exit("REFUSING: fig4_render.py moved. want %s got %s" % (WANT, got))
spec = importlib.util.spec_from_file_location("fig4r", TOOL)
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)

def read_png(p):
    d = open(p,'rb').read()
    assert d[:8] == b'\x89PNG\r\n\x1a\n', p
    i, idat, w, h = 8, b'', None, None
    while i < len(d):
        ln = struct.unpack(">I", d[i:i+4])[0]; tag = d[i+4:i+8]; body = d[i+8:i+8+ln]
        if tag == b'IHDR':
            w, h, bd, ct = struct.unpack(">IIBB", body[:10])
            assert (bd, ct) == (8, 2), (bd, ct)
        elif tag == b'IDAT': idat += body
        i += 12 + ln
    raw = zlib.decompress(idat)
    stride = w*3
    rows = []
    for y in range(h):
        off = y*(stride+1)
        assert raw[off] == 0, "filter %d on row %d of %s" % (raw[off], y, p)
        rows.append(raw[off+1:off+1+stride])
    return w, h, rows

top, bot, out = sys.argv[1:4]
w1,h1,r1 = read_png(top); w2,h2,r2 = read_png(bot)
assert w1 == w2, (w1,w2)
px = bytearray()
for r in (r1 + r2): px.extend(r)
m.write_png(out, w1, h1+h2, px)
print("stacked %dx%d + %dx%d -> %dx%d  %s" % (w1,h1,w2,h2,w1,h1+h2,out))
