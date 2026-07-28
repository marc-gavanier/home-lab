# Runbook — changing a running container's configuration safely

Applies to any `compose.yaml` change that recreates a container: capabilities,
security options, mounts, users, image pins. Written after a `cap_drop` change
took the VPN down for three hours (#24).

## The two failure modes that matter

**Crash loop.** The container never becomes usable, and *nothing on the Pi fixes
it*. The heal timer restarts containers that **exited**; a container restarting
every few seconds because its configuration is wrong is not that case, and it
will sit there until a human intervenes. Docker's `restart: unless-stopped`
actively keeps the loop alive.

**Silent degradation.** The container is `healthy`, its HTTP endpoint answers,
and one internal function is dead. Uptime Kuma kept serving its UI while every
ping monitor reported `spawn EPERM`, because `/usr/bin/ping` carries
`cap_net_raw` as a file capability and the exec failed. A status check and a
`curl` both said green. Assume this mode exists for every service and ask what
the service *does* beyond answering.

## Order of operations

1. **Sandbox first, for anything on the critical path** — Pi-hole (LAN DNS),
   Traefik (all HTTPS), wg-easy (VPN *and* the offsite link that rides it).
   A throwaway container with the same image, a copy of the config with the same
   ownership, and non-conflicting ports reproduces startup faithfully:

   ```bash
   docker run -d --name svc-captest --security-opt no-new-privileges:true \
     --cap-drop ALL --cap-add ... -v /tmp/svc-captest:/etc/<svc> <image>
   docker logs svc-captest | grep -iE "denied|not permitted|unable"
   ```

   Ownership matters: a fresh `/tmp` directory belongs to the host user, while
   the real one may hold root-owned files. Reproduce both, or the sandbox
   answers a different question than the one asked.

2. **Never apply to a critical service without an automatic rollback.** Not a
   plan to roll back — a script that does it unattended, because the tool
   output may be the last thing anyone reads for hours:

   ```bash
   cp -a compose.yaml compose.yaml.bak
   scp <new compose>; docker compose up -d <svc>
   ok=no
   for i in $(seq 1 20); do sleep 6; <functional probe> && { ok=yes; break; }; done
   [ "$ok" = yes ] || { cp -a compose.yaml.bak compose.yaml; docker compose up -d <svc>; }
   ```

   The probe must be the *function*, not the status: `dig @127.0.0.1 example.com`
   for Pi-hole, `wg show wg0` for wg-easy, an HTTPS response for Traefik.

   **The backup has to be older than the change.** A harness that copies the
   whole `compose.yaml` per service quietly breaks this after its first run: the
   file on the Pi already carries every service's change, so the "backup" taken
   before service #3 already contains service #3's change and rolling back
   recreates the container identically. That is how the nextcloud-cron attempt
   under #28 stayed broken after its rollback fired correctly. Either stage one
   service's change at a time, or make the script refuse to run when the file it
   is about to keep already contains the new setting:

   ```bash
   grep -q '<the new setting>' "$BAK" && { echo "not a rollback point"; exit 2; }
   ```

3. **Verify functions, one per service.** What proved useful:

   | Service | Probe that actually proves something |
   |---------|--------------------------------------|
   | Traefik | force a real ACME issuance (throwaway router on a name with no A record — DNS-01 needs none); cached certs keep serving a broken config for weeks |
   | Pi-hole | resolve, resolve a *blocked* name, resolve a split-DNS name, check the log for permission complaints even when it resolves |
   | Databases | a SQL round-trip, not the healthcheck |
   | Transmission | RPC with good credentials (409) *and* bad (401) — a 409 alone can mean auth is off |
   | wg-easy | `wg show` peer handshake ages, then ping a peer; recreation drops handshakes and they return at each client's own pace, so poll for a minute before concluding |
   | Uptime Kuma | spawn a ping from inside the container |
   | Nextcloud | `occ status` plus the age of `core lastcron` |
   | Nextcloud cron | `core lastcron` **must advance** — busybox `crond` calls `setgroups()` before every job, so without `SETGID` it logs "can't set groups" once per run and never executes `cron.php`, with the container still Up (#28) |
   | Netdata | uid of PID 1 = 201, the full plugin list, and the chart-context counts per family — see `docs/07-observability` |

   **A probe a cache can satisfy is not a probe.** Swapping Pi-hole's DoH client
   on 2026-07-27, the harness reported success while **no upstream container
   existed at all**: it queried three names it had just resolved itself moments
   earlier, and Pi-hole answered every one from cache. Uncached names were timing
   out the whole time. Probe with something that *cannot* be cached — a random
   label, where `NXDOMAIN` is a passing answer because it proves something
   upstream replied — and gate on the container actually being `running` before
   believing any functional result.

   **Pull the replacement before dismantling what works.** The same switch took
   DNS down because the image was pinned `0.83.0` where the registry publishes
   `v0.83.0`: `up -d` failed *after* the working container had been removed. A
   `docker pull` as the first step of the script turns that into an abort with
   nothing touched. And never send `docker compose up` to `/dev/null` — that is
   what hid the error.

   **Validate the probe before you trust it.** A probe that cannot succeed turns
   a working change into a rollback, and then reports the rollback as failed
   too. On this host the trap is DNS: internal names resolve only in Pi-hole,
   and the Pi does **not** use Pi-hole as its own resolver, so `curl
   https://videos.gavanier.com/health` fails on the host with "Could not resolve
   host" while the service is perfectly healthy. Use `--resolve
   <name>:443:192.168.1.100`, or probe from inside the container. Only
   `drive` and `services` are pinned in `/etc/hosts`.

4. **Sweep for file-capability binaries** before dropping capabilities anywhere,
   since that failure is invisible from outside:

   ```bash
   for c in $(docker ps --format '{{.Names}}'); do
     docker exec "$c" sh -c 'getcap -r /usr/bin /usr/sbin /bin /sbin 2>/dev/null'
   done
   ```

   Currently: `pihole-FTL` (chown, net_bind_service, sys_nice), `ping` in
   uptime-kuma and `fping` in netdata (net_raw).

5. **If the image declares `VOLUME` at the path you are changing, `up -d` is not
   enough.** Compose carries mounts for image-declared volume paths over from
   the previous container when it recreates, so a mount you *removed* from
   `compose.yaml` can survive in the running container. It then fails the moment
   the old source disappears:

   ```
   invalid mount config for type "bind": bind source path does not exist: ...
   ```

   Measured on SearXNG, whose image declares `VOLUME /etc/searxng`: the
   directory mount was replaced by a file mount in `compose.yaml`, the container
   was recreated and *still* carried the old bind, and once Ansible removed that
   directory both `--force-recreate` and `docker restart` failed — the service
   went down at the restart, not at the change. Check the image first, and
   delete the container rather than recreating it:

   ```bash
   docker image inspect <image> --format '{{json .Config.Volumes}}'
   docker rm -f <svc> && docker compose up -d <svc>
   ```

   Then `docker inspect <svc> --format '{{range .Mounts}}...'` to confirm what
   the container actually got, and restart it once to prove the mount survives.
   Each such recreation leaves the previous anonymous volume dangling
   (`docker volume ls -f dangling=true`).

6. **Making a container read-only** (ADR-019) — the write set is measurable, so
   measure it: `docker diff <container>` lists everything written to the image
   layer since the container was created. Then:

   - **Mount the leaf, never the parent.** A `tmpfs` on `/run` erases the
     subdirectories the image made there and the process will not recreate them
     (`Bind on unix socket: No such file or directory`). Mount `/run/mysqld`,
     `/run/postgresql`, `/run/netdata`. Check what a directory holds before
     covering it — netdata's `/var/log/netdata` is all symlinks to `/dev/stdout`.
   - **`tmpfs` is mounted `noexec` by default.** An init system that stages
     binaries under `/run` (s6) fails with `Permission denied` on exec. Use
     `- /run:exec`.
   - **A write target that shares a directory with image content is a stop.**
     Both workarounds — `tmpfs` over the directory, or a host copy of what the
     image ships — hide the next image update. Leave the rootfs writable and
     write down why.
   - `docker diff` only shows writes since the container started, so rare paths
     (log rotation, certificate renewal, weekly jobs) will not appear. Probe
     those explicitly.

7. **Leave the Pi's file consistent with the running state.** `docker compose`
   reads `/opt/homelab/compose.yaml`; if a container was rolled back but the file
   still holds the broken definition, the next `up` — from the heal timer, a
   reboot, or an Ansible deploy — reintroduces the failure. Ansible re-templates
   the file, so a temporary hand-copy is fine, but it must not be left behind.

## When `compose up` cannot perform the change

Some image bumps need a **data migration that the image will not do for you**.
wg-easy 15 is the case that taught this (ADR-020): the configuration moves from
`wg0.json` to SQLite, and the only import path is an HTTP call that must happen
*before* the setup is marked complete. Start the new image on the old data
directory and it finds no database, reopens its setup wizard, and brings up **no
tunnel at all** — with the container green and nothing in `systemctl --failed`.

The trap is that the change looks like a one-line image bump in `compose.yaml`,
so it rides the next deploy — or a Renovate merge — with no migration anywhere.
Three rules came out of it:

- **Put the migration inside the deploy path, not beside it.** A documented
  manual step before `compose up` is a step someone will skip. The wg-easy
  migration runs as an Ansible task placed *between* the compose file copy and
  `compose up`, self-guarded so it is a no-op once done.
- **Stage it on a copy and verify before touching production.** Copy the data
  directory, run the migration against a throwaway container that publishes
  nothing, and assert the result carries what matters — for a VPN, the same
  server key and the same peer set. The live service keeps running the whole
  time; downtime becomes the container swap, seconds, instead of the migration.
- **Remove the container, do not stop it.** The crash-heal timer resurrects
  containers it finds exited, every two minutes. A `stop` during a swap can be
  undone mid-flight, on the new image, against a half-migrated directory. Use
  `docker compose rm -sf <svc>` — a removed container is invisible to the timer.

And hold the version until then: a Renovate rule with `allowedVersions` costs
nothing and buys the time to do the above properly.

## Restoring quickly

```bash
cd /opt/homelab
cp -a compose.yaml.bak compose.yaml     # or: git show <ref>:docker/compose.yaml
docker compose up -d <svc>
```

A container recreation is seconds. What takes time is noticing, so the
automation in step 2 is worth more than speed here.
