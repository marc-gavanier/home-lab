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

## 2026-08-22 — the one-shot migration code is removed, the decision stands

`wg_easy_migrate.yml` and `homelab-wg-easy-migrate.sh.j2` (312 lines together)
have been deleted. The migration ran on 2026-07-28; wg-easy has been on `15.3.0`
since, `wg-easy.db` exists, and the script's own first guard made it a no-op on
every deploy after that day.

Removing it takes nothing away, and the reason is worth recording because it was
not obvious: the script's **fresh-install branch also exits 0** — `no wg0.json:
fresh install, v15 will run its own setup`. So it was never a safety net for a
rebuild, only for the 14→15 transition itself. The one state it would still act
on is a `wg0.json` present *without* `wg-easy.db`, which now means restoring a
backup older than 2026-07-28.

What survives: this ADR as the record of how the migration was done, and the
pre-migration copy under the v14 rollback directory on the encrypted volume,
which is untouched by this change.

`wg_easy_config.yml` — the second task file described above — is unaffected and
still re-asserts the settings on every deploy. It is the subject of open issue
#160, and see the correction below: until 2026-08-25 it could not write at all.

First application of ADR-030 (tier 0: delete what has already run).

---

## Correction, 2026-08-25 — the re-assertion had never once written

This ADR made two claims that were not true of the running system. Both are
recorded here rather than edited away, because the way they stayed true-looking
is the useful part.

### "keep this repository the source of truth by re-asserting the settings"

The re-assertion task could **verify** and could never **enforce**. Every write
into wg-easy returned HTTP 500 with `SQLITE_READONLY`: `cap_drop: ALL` takes
`CAP_DAC_OVERRIDE` from a container running as root, and its data directory was
owned by uid 1000, so the database's rollback journal could not be created. The
database was reachable and could not be written (#138). Adding or **revoking** a
VPN peer failed the same way, from the same cause.

`homelab-wg-easy-config.sh` exited 0 on every deploy for a month — on "settings
already match", never on a write. A mechanism that would have failed the first
time it was needed, whose daily success is what hid it. Worse, `failed_when: rc
not in [0, 2]` meant the first genuine configuration change would have aborted
the deploy at step 4 of 12, on the host whose only route in is the tunnel this
same service manages (#160).

Fixed by `chown root:root` on the data directory, expressed in
`roles/deploy/tasks/data_dirs.yml`. No capability is handed back — the opposite
of reopening `DAC_OVERRIDE`.

Verified end to end on 2026-08-25, which is the part that was missing:

| Step | Result |
|---|---|
| POST the CURRENT settings back (write path, no semantic change) | HTTP 200, `user_configs_table.updated_at` moved |
| deliberate drift: `defaultMtu` 1420 → 1380 through the API | accepted, read back as 1380 |
| `homelab-wg-easy-config.sh` | `settings drifted — rewriting them`, exit **2** |
| read back | `defaultMtu = 1420`, host and DNS intact |
| run it again | `settings already match`, exit **0** |

So the sentence at the top of this ADR describes the system for the first time
since it was written.

### "`migrate` assigns IPv6 addresses even with the flag set"

True, and the conclusion drawn from it was too narrow. The residue is still in
the database today — `ipv6_cidr` on the interface and an `ipv6_address` on all
four clients — and this ADR's reading of it (cleanup runs *at startup*, the
migration runs *after*) left a hazard on the record: that the first write would
regenerate `wg0.conf` from the database and take IPv6 with it, which on a host
with no global IPv6 makes `wg-quick up wg0` fail outright and leaves **no tunnel
at all behind a green container**.

That hazard blocked the one-line fix above for eight days. It was reasoned, not
measured. Measured now, on the LAN, with `wg0.conf` and the database backed up
first: the write **does** regenerate `wg0.conf` — its mtime moves — and the file
is byte-identical, `md5 eb8ac06c…` before and after. `wg show wg0` keeps the
same four IPv4 `/32` peers, `ssh offsite` still answers through the tunnel.

`DISABLE_IPV6=true` is therefore honoured when the configuration is
**generated**, not only during the startup cleanup. The IPv6 in the database
never reaches the interface.

It is still drift that nothing asserts, and it is now its own follow-up rather
than the reason a fix cannot land.

---

## Correction, 2026-08-26 — "the settings" meant the defaults only

The re-assertion described above compares six fields, and every one of them is a
**default**: `host`, `port`, `defaultDns`, `defaultAllowedIps`, `defaultMtu`,
`defaultPersistentKeepalive`. A default is read exactly once, when a client is
created, and never looked at again.

So the values that actually reach a phone — the ones written into the
configuration file it imports — were asserted by nothing. This ADR said the
repository was the source of truth for "the VPN settings"; it was the source of
truth for what a *future* client would be born with.

That is not a theoretical gap. It is #125: the repository's DNS was right, the
default was right, and all four existing clients kept Cloudflare's `1.1.1.1` —
off Pi-hole, off split DNS, queries leaving the box.

Extended on 2026-08-26 (#238) to compare and rewrite the per-client values too.
Two fields, chosen rather than swept up:

| Field | Asserted | Why |
|---|---|---|
| `dns` | yes | no client has a legitimate reason to resolve elsewhere, and #125 is what happens when nothing checks |
| `allowedIps` | yes | it was the one drifting — every client carried `["0.0.0.0/0", "::/0"]`, migration residue routing a client's IPv6 into a tunnel with none |
| `mtu` | no | nothing has ever moved it, and it harms nothing if it does |
| `persistentKeepalive` | no | a roaming phone behind a bad NAT has a real reason to want its own |

The cost of asserting `allowedIps` is worth naming: a split-tunnel client now
has to be expressed in the repository rather than clicked in the web UI. That is
this ADR's model applied, not a side effect.

**What it does not do.** These fields produce the configuration FILE at download
time; they do not steer a running peer. Correcting a client here fixes what the
next import contains — the device keeps what it was given until someone
re-imports it. That was the painful half of #125 as well, and it is easy to
misremember in the other direction.

Verified end to end on 2026-08-26, both fields:

```
allowedIps  4 clients drifted -> detected by name, rewritten, exit 2
            second run: "per-client values already match", exit 0
dns         client 1 driven to 1.1.1.1 -> detected, rewritten, exit 2
            second run: exit 0
```

`wg0.conf` md5 unchanged throughout (`eb8ac06c…`), four peers up, offsite
reachable through the tunnel — a client-side setting does not touch the server
configuration, which is what made the change safe to exercise on the live
system.
