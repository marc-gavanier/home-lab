# Masks credential values out of the Traefik access log before the line reaches
# any durable store (#287, ADR-034).
#
# Two passes, because awk substitution has no capture groups — neither POSIX awk
# nor gawk can put a matched sub-expression back into the replacement. The first
# pass marks the position just after the `=` with \001, a byte that cannot occur
# in an HTTP request line; the second eats the value from that mark to the next
# separator. The parameter name survives, so the log still says WHICH credential
# was carried and the rest of the query string is untouched:
#
#   GET /some/path?access_token=eyJhbGci...&page=2
#   GET /some/path?access_token=***&page=2
#
# The one-liner this replaces does not exist: busybox sed has no -u, so
# `sed -E 's/(x=)[^ ]*/\1***/'` block-buffers 4 KB into the pipe and shows
# nothing for minutes at noon and hours at 04:00 — and loses the tail entirely
# if the container is killed. fflush() below is what buys line-at-a-time.
#
# The parameter list is the credential CLASS, not the two services measured
# emitting one on 2026-08-29 (#287 asks for exactly this): a service added
# tomorrow that puts a token in a query string is covered without touching this
# file. Over-redaction costs nothing — a value nobody needed.
{
  gsub(/[?&][Aa]ccess_?[Tt]oken=|[?&][Aa]pi_?[Kk]ey=|[?&](token|auth|secret|password|sig|signature)=/, "&\001")
  gsub(/\001[^ &"]*/, "***")
  print
  fflush()
}
