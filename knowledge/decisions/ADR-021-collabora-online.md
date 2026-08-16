# ADR-021 — Collabora Online for collaborative editing, and what it costs in posture

**Date**: 2026-07-28
**Status**: accepted — sandbox-measured on the Pi (2026-07-28)

## Context

Issue #16 asked for collaborative document editing inside Nextcloud. The
alternative, OnlyOffice, was ruled out on hardware grounds before any testing:
no official arm64 image, and 4 GB RAM recommended on a host that already runs
21 containers. Collabora publishes arm64 images and claims ~300–500 MB.

The open question was never *whether it runs* — it was what it would do to a
stack where 12 of 21 containers hold no capability at all, 17 have a read-only
root filesystem, and `no-new-privileges` has exactly one documented exception
(netdata, ADR-017).

Everything below was measured in a throwaway container publishing nothing.
Production was never touched, and the one production change the wiring test
required — enabling `richdocuments` — was reverted to a byte-identical config.

## Decision

Deploy `collabora/code:26.04.2.4.1` behind Traefik at `office.<domain>`,
VPN-only like every other service, wired to Nextcloud's `richdocuments`
connector by the deploy rather than by the admin UI.

### The capability minimum is three, and it is not the documented one

`cap_drop: ALL` plus **`SYS_CHROOT`, `CHOWN`, `FOWNER`**. Removing any one of
the three leaves `coolwsd` unable to spawn its forkit, and it exits 70 at
startup. **`MKNOD` is not needed**, despite appearing in Collabora's own
container documentation — measured, not assumed.

The image helps here: it already runs as **uid 1001**, ships **no shell**, and
its entrypoint is `coolwsd` directly. That is a better starting posture than
most images in this stack arrive with.

### `no-new-privileges` is off — the second exception, for netdata's reason

`coolwsd` spawns each document through `coolforkit-caps`, a binary carrying
**file capabilities**. `no-new-privileges` blocks that gain. Netdata's exception
is setuid plugins; this is the same shape — a binary that must gain privilege
after `exec`.

What makes it worth writing down is the failure mode. The container does not
crash. It stays `running`, serves `/hosting/discovery` normally, and loops
forever:

```
INF  Waiting for a new child for a max of 20000ms
```

A status check, a `curl`, and `systemctl --failed` all say green while no
document can ever open. The image's own healthcheck **does** catch it
(`unhealthy`, failing streak 3, container still `running`), which is why it is
left enabled and why the stack's "unhealthy for > 10 min" alert covers this.

### `read_only` is off — it works, and costs 700 MB of RAM

This one is a trade, not an impossibility. With leaf tmpfs on
`/opt/cool/child-roots`, `/opt/cool/cache`, `/opt/cool/.cache`, `/tmp` and
`/home/nonroot`, a read-only Collabora converts documents fine. (A tmpfs on
`/opt/cool` itself does not: it erases the image's `systemplate` and coolwsd
exits 78 — the "mount the leaf, never the parent" rule, again.)

The cost comes from a chain worth following. Without `CAP_SYS_ADMIN`,
`coolmount` cannot create its mount namespace:

```
ERR  enterMountingNS, CLONE_NEWUSER unshare failed (EPERM)
ERR  Bind-Mounting fails and will be disabled for this run.
```

So Collabora falls back from bind-mounting each jail to **copying** it —
**759 MB** of jail tree. On the writable layer that lands on `/mnt/data`
(3.7 TB free, and *not* the SD card, since Docker's data-root is on the HDD).
In tmpfs it is RAM:

| | Writable rootfs | `read_only` + tmpfs |
|---|---|---|
| Container memory | **573 MiB** | **1.257 GiB** |
| Disk on `/mnt/data` | 759 MB | 0 |

Granting `SYS_ADMIN` would remove the copy entirely — and is close enough to
root to be a worse bargain than either column. Rejected.

So: writable rootfs, 759 MB on a disk that has 3.7 TB, and the RAM stays free
for Immich. The posture check needs no exception mechanism for this — it
generates `want_ro` and `want_nnp` per service from `compose.yaml`, so it will
now assert that Collabora must *not* have them, and would catch either being
added by accident.

### The callback pin is mandatory, and its absence is invisible

Collabora calls Nextcloud back over the public hostname — the WOPI callback URL
is autodetected from the user's browsing URL. From a container, that name
**does not resolve at all**:

```
wget: bad address 'drive.example.com'
```

Not a hairpin to the public IP — a plain failure, because the host is not a
Pi-hole client and the name exists only in split DNS. With
`extra_hosts: drive.<domain>:<PI_LAN_IP>` the same request reaches Nextcloud's
WOPI endpoint. Without it, every document fails to open while the container
stays green.

### The repository keeps the settings, not the web UI

`roles/deploy/tasks/collabora.yml` re-asserts `wopi_url` and `public_wopi_url`
on every deploy, comparing before writing. This is not ceremony:
`richdocuments:activate-config` derives `public_wopi_url` from `wopi_url` by
swapping the scheme, which hands the browser an internal container name. It also
writes `wopi_callback_url`. Both were discovered by diffing the config after the
sandbox against the snapshot taken before it.

**And it does not merely fill the value in when unset — it overwrites one that
is already correct.** So `public_wopi_url` must be set *after* `activate-config`,
never before. The first production deploy proved it the hard way: the task
setting it reported `changed`, `activate-config` ran next, and the stored value
was `https://collabora:9980` afterwards. The write succeeded and was undone
seconds later, in the same play, with nothing in the output suggesting it.

### `wopi_url` is the public name, and that is not a mistake

The obvious configuration — `wopi_url` = `http://collabora:9980`, the container
name, since that *is* how Nextcloud reaches the server — does not work, and
fails in a way no server-side check catches. richdocuments fetches the WOPI
discovery from `wopi_url` (`DiscoveryService::getDiscoveryEndpoint`) and then
hands the browser the `urlsrc` it finds there **verbatim**, with no rewriting
(`WOPI\Parser::getUrlSrcValue`). Collabora builds that `urlsrc` from the `Host`
header of the request it received. Ask it over the container name and it
answers with the container name.

`public_wopi_url` does not fix this: it feeds the CSP allowlist, not the URL.
The two then disagree, and the browser refuses the page Nextcloud just built:

```
Content-Security-Policy: blocked form-action at
  https://collabora:9980/browser/…/cool.html?WOPISrc=…
because it violates: form-action 'self' https://office.<domain>
```

Every server-side signal was green at that moment — container healthy, posture
0, capabilities 200, a document converting to PDF on demand — and Collabora's
log showed **no activity at all**, because no request ever arrived. The only
diagnosis path was the browser console.

So `wopi_url` is `https://office.<domain>`, and Nextcloud's own traffic goes out
through Traefik and back in. That requires the Nextcloud container to resolve a
name that exists only in split DNS, hence the second `extra_hosts` pin in its
compose block — the same mechanism Collabora needs in the other direction.

One consolation: with both URLs equal, `activate-config`'s derivation lands on
the right value, so the ordering trap above becomes harmless rather than
load-bearing.

### The discovery cache is state, and state needs its own trigger

richdocuments never fetches the WOPI discovery on demand.
`CachedRequestService::get()` reads a cache and returns `null` when it is empty
— the caller then does `simplexml_load_string(null)` and calls `xpath()` on
`false`. The visible result is HTTP 500 on `/apps/richdocuments/token`, a
document that loads forever with no error in the interface, and every other
signal green.

An empty cache is not an edge case, because only `activate-config` fills it, and
the first version of this task ran `activate-config` **only when the
configuration changed**. The sequence that followed was:

1. a deploy set `wopi_url` to the public name, then ran `activate-config`, which
   **failed** — the Nextcloud container could not yet resolve `office.<domain>`,
   as the pin arrived in the same run but after this task. The cache was left
   empty.
2. the next deploy found `wopi_url` already correct, so nothing was `changed`,
   so `activate-config` was **skipped**.
3. so did the one after, which reported `changed=0` — a perfectly idempotent run
   over a service that could not open a single file.

**A refresh triggered only by configuration drift never retries its own
failures.** The condition now includes the cache's contents, so a failed refresh
is repaired by the next deploy instead of being frozen by it.

Four probes now guard this service, and each exists because the previous three
missed something real:

| Probe | Catches |
|---|---|
| `/hosting/capabilities` | coolwsd not listening |
| a real PDF conversion | kits that cannot spawn (the `no-new-privileges` trap) |
| the advertised `urlsrc` | a URL the browser cannot reach (the CSP trap) |
| the cached discovery | richdocuments' own state (this trap) |

The first three all look outward, at Collabora and at the network. Nothing read
what Nextcloud actually held until a document refused to open.

## Consequences

**A deploy now verifies a conversion, not a status.** The wiring task ends by
converting a text file to PDF through the container and failing the deploy if
the result is not a PDF. That is the probe that would have caught the
`no-new-privileges` failure above; `/hosting/capabilities` would not have.

**The WOPI proof key cannot be generated.** `/etc/coolwsd` is `root:root 0755`
and the container runs as uid 1001, so `Could not open proof RSA key` at every
start. It cannot be fixed by mounting a writable directory there without
shadowing `coolwsd.xml`, which the image ships — the leaf-versus-parent rule
once more. Consequence: Nextcloud cannot verify that WOPI requests are signed by
this server, and falls back to the access token alone. Accepted; the token is
what protects the document either way, and the whole surface is VPN-only.

**Three `ERR` lines at every start are expected.** They are the bind-mount
fallback above. `--o:mount_jail_tree=false`, which the log itself suggests, has
**no effect** — while `--o:ssl.*` overrides passed in the same string do take
effect. Left as noise rather than chased.

**Collabora joins wave 3 of the staged startup**, with Immich and Jellyfin. It
takes ~80 s to serve and nothing needs it until a document is opened. Like every
other member of that wave, a container that cannot be created fails the wave.

**No unattended rollback harness**, unlike ADR-020. This is an additive service
on nothing's critical path: if it fails, no existing service degrades. The
runbook's rollback rule is scoped to changes that can take something down, and
this is not one. The undo is two commands, in `docs/05-services/collabora.md`.

**Renovate holds majors for dashboard approval.** Collabora majors track the
LibreOffice core and pair with a `richdocuments` version on the Nextcloud side;
a mismatch breaks editing while the container stays healthy.

**LibreSign, the third part of #16, is deliberately out of scope.** Its Java and
CFSSL prerequisites are a different problem and deserve their own sandbox.

*Followed up in ADR-022: the Java prerequisite was real and is downloaded at
runtime; the CFSSL one had already been superseded by an OpenSSL engine.*
