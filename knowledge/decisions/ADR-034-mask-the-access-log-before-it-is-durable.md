# ADR-034 — Mask the access log before it becomes durable

- **Status**: Accepted
- **Date**: 2026-08-30
- **Issue**: #287
- **Supersedes nothing. Constrains**: ADR-023 (Dozzle), and the accessLog half of #259

## Context

Traefik's access log is the only place where every HTTP request to this host is
recorded. #259 removed its `filters.statusCodes: 400-599` on 2026-08-28, for a
sound reason: filtered to refusals, the log could not answer *who is present*,
and a census drawn from it had already produced one wrong conclusion and cost
the offsite host a week of silence.

That fix reopened a credential class underneath it. With successful requests
kept, the log started recording request lines whose query string carries a
credential — because some clients have nowhere else to put one. SignalR cannot
set an `Authorization` header on its WebSocket handshake; a media player handed
a stream URL carries whatever is in that URL. Measured over the 3.5 days the log
retains: fifty request lines across two services, twelve distinct live tokens,
one class of which does not rotate on its own.

`filePath: /dev/stdout` is what makes this durable. Docker's `json-file` keeps
it for about 3.5 days, and Dozzle (ADR-023) serves it to every account
authorised for it — a readership well beyond the account that owns the file.

## The levers that do not work

**Fix the emitting side.** Not available: the protocols decide where the
credential goes, not our configuration.

**Filter the log.** `filters` works on status code, retry count and duration.
None of those dimensions separates a request carrying a credential from one
worth keeping.

**Turn the access log off.** Restores exactly the blindness #259 cured.

**Redact the field in Traefik.** Measured on 3.7.11, in both `common` and
`json`: `fields.names.RequestPath: redact` is a **no-op** — the value passes
through verbatim. Only `drop` works, and it blanks the whole path on every
line. That was the cheap answer and it was rejected on a measurement:
Vaultwarden logs no request line of its own and Jellyfin logged four in a day,
so Traefik is the only HTTP visibility either service has. Dropping the path
would have blinded us to the two services the finding is about.

## Decision

Mask the value between Traefik and the durable store, keeping everything else
in the line.

    traefik ──writes──▶ /run/traefik/access.log     tmpfs, raw, 0750 root:root
                              │
                       tail -F │ awk
                              ▼
                 redactor stdout ──▶ json-file ──▶ Dozzle      masked

- Traefik writes to `/run/traefik/access.log`. `/run` is a tmpfs: RAM, emptied
  at boot, not on the SD card, not on the encrypted volume, on no backup source.
  `0750 root:root` keeps the raw line unreadable to every other account.
- `traefik-log-redactor` tails that file and rewrites credential values to
  `***`. Its stdout is the container log — so the durable trace, and everything
  Dozzle serves, has never held a credential.
- The parameter list is the credential **class**, not the two services found
  emitting one. A service added tomorrow is covered without an edit.

## Why this is glue, and why it ships anyway

ADR-030 says: configure the tools, do not write the glue. This is glue — an awk
program in the request path of every logged line. It ships because the premise
of that rule fails here: **no installed tool does this job.** Traefik cannot;
Docker's log driver cannot; the alternatives that could (a log shipper as the
log driver) take `docker logs` away and blind Dozzle, which is a worse trade.

Four things keep the glue small enough to be worth it:

- It is 4 lines of awk with no state, no network, no filesystem writes.
- It runs with every capability dropped, a read-only rootfs, both mounts `ro`
  and `network_mode: none`.
- Its two non-obvious choices were **measured**, not reasoned: busybox `tail -F`
  across a `copytruncate` (no line lost, none duplicated) and `fflush()` against
  awk's 4 KB block buffering into a pipe.
- It is gated. `traefik-access-log-carries-no-credential` reads the durable
  trace, not this file, and was made to fail on purpose before being believed.

## Consequences

- `docker logs traefik` no longer shows access lines; they are on
  `traefik-log-redactor`. Documented in `docs/05-services/traefik.md`.
- The raw log exists, in RAM, root-only, until the next boot or the daily
  rotation — whichever comes first. That is the residue, and it is asserted by
  `traefik-raw-access-log-stays-in-ram-and-root-only` rather than assumed.
- A credential class that reaches a query string is now masked for **every**
  service behind the proxy, including ones not yet deployed.
- Over-redaction is possible and costs nothing: a value nobody needed.
- The redactor is Tier 0, which it does not look like from its job. `tail -F`
  opens the file where it is, so anything written while it is down never reaches
  the durable log — and left to the staged startup it would come up in wave 1,
  after the 300 s DNS gate, blinding the access log for exactly the part of boot
  that has already produced #252, #253, #260 and #292. It costs the boot storm
  nothing: one alpine reading one file, no image layers off the USB disk.
- PID 1 in the redactor is a shell, so `docker stop` waits out the grace period
  and kills. Harmless here — no state to flush, every line already shipped —
  and the grace period is shortened to 5 s so a stack stop is not held up. It is
  the opposite of the #288 case, and the compose block says so.
