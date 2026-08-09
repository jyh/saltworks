# Duplicate HEADER STRINGS on the bus, classified by the GAP between copies.
# Adjacent copies are ordinary same-minute posting. Widely separated copies are
# a quote, a re-surfacing, or a fixture reproducing a real header -- and those
# are the ones that break any uniqueness check keyed on header text.
{
  if ($0 ~ /^\[[^]]{2,90}\]/) {
    h = $0
    sub(/\].*$/, "]", h)          # the header bracket alone, body discarded
    n[h]++
    if (n[h] == 1) first[h] = NR
    else {
      gap = NR - last[h]
      if (gap > 200) { far[h] = far[h] " " last[h] "->" NR }
      else            near[h] = near[h] " " last[h] "->" NR
    }
    last[h] = NR
  }
}
END {
  for (h in n) if (n[h] > 1) {
    tot++
    if (far[h] != "") { farc++; printf "  ⛔ FAR  %-42s x%d  %s\n", substr(h, 1, 42), n[h], far[h] }
  }
  printf "  --- duplicate header strings: %d total, %d with a FAR pair (gap > 200 lines) ---\n", tot + 0, farc + 0
}
