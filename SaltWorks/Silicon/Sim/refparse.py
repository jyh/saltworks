TOKEN_PUNCT = set("(),;=[]:{}")


def tokenize(s):
    toks = []
    i, n = 0, len(s)
    while i < n:
        c = s[i]
        if c in " \t\r\n":
            i += 1
        elif c == "\\":
            j = i + 1
            while j < n and s[j] not in " \t\r\n":
                j += 1
            toks.append(("ESCID", s[i + 1:j]))
            i = j + 1
        elif c in TOKEN_PUNCT:
            toks.append(("P", c))
            i += 1
        elif c == "." :
            toks.append(("P", "."))
            i += 1
        elif c.isdigit():
            j = i
            while j < n and (s[j].isdigit() or s[j] == "'" or s[j] in "bhdoxBHDOXzZxX_abcdefABCDEF"):
                j += 1
            toks.append(("NUM", s[i:j]))
            i = j
        elif c.isalpha() or c == "_" or c == "$":
            j = i
            while j < n and (s[j].isalnum() or s[j] in "_$"):
                j += 1
            toks.append(("ID", s[i:j]))
            i = j
        elif c == "/" and i + 1 < n and s[i + 1] == "/":
            while i < n and s[i] != "\n":
                i += 1
        elif c == "/" and i + 1 < n and s[i + 1] == "*":
            i = s.index("*/", i) + 2
        elif c == "`":
            while i < n and s[i] != "\n":
                i += 1
        else:
            raise SyntaxError("stray char %r at %d" % (c, i))
    return toks


class P:
    def __init__(self, toks):
        self.t, self.i = toks, 0

    def peek(self, k=0):
        return self.t[self.i + k] if self.i + k < len(self.t) else ("EOF", "")

    def next(self):
        v = self.peek()
        self.i += 1
        return v

    def eat(self, kind, val=None):
        k, v = self.next()
        if k != kind or (val is not None and v != val):
            raise SyntaxError("want %s %s got %s %s @%d" % (kind, val, k, v, self.i))
        return v

    def name(self):
        k, v = self.next()
        if k not in ("ID", "ESCID"):
            raise SyntaxError("want name got %s %s" % (k, v))
        return ("esc:" if k == "ESCID" else "") + v

    def netref(self):
        if self.peek() == ("P", "{"):          # concatenation (hierarchical macro ports)
            self.next()
            parts = []
            while self.peek() != ("P", "}"):
                parts.append(self.netref())
                if self.peek() == ("P", ","):
                    self.next()
            self.next()
            return tuple(parts)
        nm = self.name()
        if self.peek() == ("P", "["):
            self.next()
            idx = self.eat("NUM")
            self.eat("P", "]")
            return (nm, int(idx))
        return (nm, None)


def parse(src):
    p = P(tokenize(src))
    p.eat("ID", "module")
    top = p.name()
    p.eat("P", "(")
    while p.peek() != ("P", ")"):
        p.name()
        if p.peek() == ("P", ","):
            p.next()
    p.eat("P", ")")
    p.eat("P", ";")
    ports, wires, insts, assigns = {}, set(), [], []
    while p.peek() != ("ID", "endmodule"):
        k, v = p.peek()
        if k == "ID" and v in ("input", "output", "inout", "wire"):
            p.next()
            width = 1
            if p.peek() == ("P", "["):
                p.next()
                hi = int(p.eat("NUM"))
                p.eat("P", ":")
                int(p.eat("NUM"))
                p.eat("P", "]")
                width = hi + 1
            while True:
                nm = p.name()
                (wires.add(nm) if v == "wire" else ports.setdefault(nm, (v, width)))
                if p.peek() == ("P", ","):
                    p.next()
                    continue
                break
            p.eat("P", ";")
        elif k == "ID" and v == "assign":
            p.next()
            lhs = p.netref()
            p.eat("P", "=")
            rhs = p.netref()
            p.eat("P", ";")
            assigns.append((lhs, rhs))
        else:
            cell = p.name()
            inst = p.name()
            p.eat("P", "(")
            conns = []
            while p.peek() != ("P", ")"):
                p.eat("P", ".")
                pin = p.name()
                p.eat("P", "(")
                conns.append((pin, None if p.peek() == ("P", ")") else p.netref()))
                p.eat("P", ")")
                if p.peek() == ("P", ","):
                    p.next()
            p.eat("P", ")")
            p.eat("P", ";")
            insts.append((cell, inst, conns))
    p.eat("ID", "endmodule")
    if p.peek()[0] != "EOF":
        raise SyntaxError("trailing tokens")
    return top, ports, wires, insts, assigns


if __name__ == "__main__":
    import glob, sys
    for f in sorted(glob.glob(sys.argv[1] if len(sys.argv) > 1 else "*.v")):
        top, ports, wires, insts, assigns = parse(open(f).read())
        print("OK %-46s top=%-32s ports=%d wires=%d insts=%d assigns=%d"
              % (f, top, len(ports), len(wires), len(insts), len(assigns)))
