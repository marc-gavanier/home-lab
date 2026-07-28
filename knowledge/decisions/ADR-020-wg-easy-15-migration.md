# ADR-020 — Migrating wg-easy 14 → 15, and keeping the VPN in the repository

**Date**: 2026-07-28
**Status**: accepted — sandbox-verified on the Pi (2026-07-28); production
switch happens on the deploy that follows the merge

## Context

wg-easy 15 is a rewrite, not an image bump. Upstream's own advice is to "start
from scratch and import your existing configs". Concretely: nearly every
environment variable is gone, the configuration moves from `wg0.json` to
SQLite, and the documented migration path is an interactive setup wizard.

Three things made this more than a maintenance task (issue #48):

1. **It threatened the infra-as-code model.** `WG_HOST`, `PASSWORD_HASH`,
   `WG_DEFAULT_DNS` and `WG_ALLOWED_IPS` are rendered by the deploy role today.
   If they moved into a database edited through a browser, the repository would
   stop describing the VPN.
2. **A wizard cannot have an unattended rollback.** Every risky change on this
   stack runs behind a script that reverts when a functional probe fails
   (`knowledge/runbooks/container-config-changes.md`). A step that waits for a
   click cannot be one.
3. **The offsite Pi is reachable only through this tunnel.** It sits behind a
   NAT we do not control and initiates the handshake, so a changed server key
   would put it out of reach with no remote repair. Topology matters here: the
   homelab host is itself a *client* of wg-easy, and the offsite Pi is another
   one — `ssh offsite` runs host → wg-easy → offsite.

A sandbox on a **copy** of `wg0.json`, in a throwaway container publishing
nothing, answered all three. Production was never touched.

## Decision

Migrate to `15.3.0`, driven entirely by Ansible, and keep this repository the
source of truth by re-asserting the settings through the admin API on every
deploy.

### The three findings that made it possible

**The server key survives verbatim.** `POST /api/setup/migrate` validates the
uploaded file against a schema matching our `wg0.json` field for field, then
calls `updateKeyPair(oldConfig.server.privateKey, oldConfig.server.publicKey)`.
Verified against the resulting database: server public key byte-identical, 4 of
4 peers with the same public keys, addresses and pre-shared keys.

**The wizard is not a wizard.** `defineSetupEventHandler` gates on the setup
step, not on a browser session — `ValidSetupSteps = { 1: [2], 3: [4, "migrate"] }`.
So the whole migration is three HTTP calls, and an unattended switch with a real
rollback becomes possible after all.

**The posture improves.** v15 runs read-only, with `NET_ADMIN` and `NET_RAW`
alone and `docker diff` empty. **`SYS_MODULE`, which v14 required, is dropped.**

### `DISABLE_IPV6=true`

v15 enables IPv6 by default and emits `ip6tables` rules through its bundled
**legacy** `iptables` binaries. This host runs the `nf_tables` backend, so the
legacy `ip6_tables` module is never loaded — UFW's 159 IPv6 rules do not need
it. The result is not a warning:

```
modprobe: FATAL: Module ip6_tables not found in directory /lib/modules/6.8.0-1060-raspi
ip6tables v1.8.11 (legacy): can't initialize ip6tables table `nat'
[#] ip link delete dev wg0
Error: Command failed: wg-quick up wg0   (code 3)
```

**No tunnel comes up at all, and the container stays green** — the VPN and the
offsite link gone at once, with nothing in `systemctl --failed`.

The alternative was loading the module persistently. Rejected: this Pi has **no
global IPv6 whatsoever** (no address, no default route, `Network is
unreachable`), so the feature cannot work here, and a boot-time module load
would put a *new silent failure* on the critical path of a host that already
needs a manual unlock after every reboot. Measured with the flag set: zero
`ip6tables` rules generated, interface `10.8.0.1/24` only, 4 peers up —
identical in shape to what v14 serves today.

Reversible in one line if the ISP ever provides IPv6.

### Ansible keeps ownership

Two task files, and the placement of the first is the whole design:

- **`wg_easy_migrate.yml`** runs *between* the compose file copy and
  `compose up`. Any later and the deploy would have started v15 on a v14 data
  directory — no database, setup wizard reopened, no tunnel.
- **`wg_easy_config.yml`** runs after, re-asserting host, Pi-hole DNS and
  allowed IPs from `wg-easy-setup.env`, comparing before writing so an unchanged
  deploy reports unchanged. This is what stops the web UI from silently becoming
  the source of truth.

The migration script stages everything on a **copy** of the data directory,
verifies the staged database carries the same server key and the same peer set,
and only then removes the live container. Production downtime is the container
swap, not the migration. It probes the **offsite Pi first** — the full path
host → wg-easy → offsite — and rolls back to 14 unattended if it does not come
back, leaving a marker file so a broken migration cannot loop into a repeated
outage on every deploy.

## Consequences

**The admin password becomes plaintext at rest.** v15 hashes with argon2 on its
side and accepts no precomputed hash, so `PASSWORD_HASH` and the bcrypt block in
`hashes.yml` are gone. The password lives in
`/mnt/data/secrets/wg-easy-setup.env`, `0600 root:root` on the LUKS volume —
deliberately *not* in `homelab.env`, which is group-readable by docker and
mounted into containers (ADR-011, ADR-016).

**Two settings the import gets wrong are now repaired by the deploy.** `migrate`
leaves `host` empty and DNS on Cloudflare's `1.1.1.1`. Existing peers keep their
generated configs, but any *newly* generated client would have silently left
Pi-hole — no ad-blocking, no split DNS, queries off the box.

**One restart is part of the procedure.** `migrate` assigns IPv6 addresses even
with the flag set, because it runs *after* startup while the cleanup runs *at*
startup. The script restarts once before probing, so the probe reads the steady
state rather than a transient one.

**Renovate's `<15` hold is lifted**, replaced by dashboard approval on majors
for this image: it is the VPN and the only route to the offsite Pi, so a major
here is read before it is merged, never merged blind.

**The shipped CLI does not run.** `/app/server/cli.mjs` imports `citty`, absent
from the image's 56 bundled modules. No consequence — the HTTP API covers
everything — but it rules out the CLI as a configuration path, which was the
first option considered for keeping Ansible in charge.

**The peer inventory stays out of this repository**, as before.
