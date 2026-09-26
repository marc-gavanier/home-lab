# Runbook — changing a running container's configuration safely

Use this page for any `compose.yaml` change that recreates a container: capabilities,
security options, mounts, users, image pins.

## Before you start

Two failure modes matter:

- **Crash loop.** The container never becomes usable and nothing on the Pi fixes it. The
  heal timer restarts containers that exited non-zero, are `created`/`dead`, or have been
  unhealthy for 15 minutes — never one caught in a restart loop, which
  `restart: unless-stopped` keeps alive.
- **Silent degradation.** The container is `healthy` and answers HTTP, but one function is
  dead (for example Kuma's ping monitors failing with `spawn EPERM` after a capability drop).
  For every service, ask what it *does* beyond answering.

Critical-path services: Pi-hole (LAN DNS), Traefik (all HTTPS), wg-easy (VPN and the offsite
link).

## Steps

1. **Sweep for file-capability binaries first.** Step 2 needs its `--cap-add` list from here.
   Run it from the host through `/proc/<pid>/root`: `docker exec … getcap` is blind, because
   most images ship no `getcap` and some have no shell.

   ```bash
   for c in $(docker ps --format '{{.Names}}' | sort); do
     p=$(docker inspect -f '{{.State.Pid}}' "$c" 2>/dev/null)
     if [ -z "$p" ] || [ "$p" = 0 ] || ! sudo test -d "/proc/$p/root"; then
       echo "$c: NOT INSPECTED — no live root"; continue
     fi
     out=$(sudo getcap -r /proc/$p/root/usr/bin /proc/$p/root/usr/sbin \
                         /proc/$p/root/bin /proc/$p/root/sbin 2>/dev/null)
     if [ -z "$out" ]; then echo "$c: none"
     else echo "$out" | sed "s|/proc/$p/root||; s|^|$c: |"; fi
   done
   ```

   - Keep `sudo test -d`: without `sudo`, every container reports `NOT INSPECTED`.
   - Only `none` allows dropping capabilities or adding `no-new-privileges`. `NOT INSPECTED`
     or any listed binary means: check by hand, then run the functional probe (step 4).
   - The same answer decides `no-new-privileges`: a file capability is a privilege gain at
     exec, which the flag blocks. With the flag, Collabora stays `running` but opens no
     document. Netdata needs its setuid plugins ([ADR-017](../decisions/ADR-017-drop-all-capabilities.md)).
   - The sweep shows what to investigate, not what is live (Collabora's `coolmount` bit is
     outside its bounding set).

   Expected carriers:

   ```
   collabora:    /usr/bin/coolmount       cap_sys_admin=ep
   collabora:    /usr/bin/coolforkit-caps cap_chown,cap_fowner,cap_sys_chroot=ep
   netdata:      /usr/bin/fping           cap_net_raw=ep
   pihole:       /usr/bin/pihole-FTL      cap_chown,cap_net_bind_service,cap_sys_nice=ep
   uptime-kuma:  /usr/bin/ping            cap_net_raw=ep
   ```

2. **Sandbox critical-path services.** Run a throwaway container with the same image, a copy
   of the config with the **same ownership** (a fresh `/tmp` dir belongs to your user; the
   real one may be root-owned), and non-conflicting ports:

   ```bash
   docker run -d --name svc-captest --security-opt no-new-privileges:true \
     --cap-drop ALL --cap-add ... -v /tmp/svc-captest:/etc/<svc> <image>
   docker logs svc-captest | grep -iE "denied|not permitted|unable"
   ```

3. **Apply critical-path changes only with an unattended rollback.** Run from
   `/opt/homelab`: both paths are relative, and from anywhere else the script silently does
   nothing, including the rollback.

   ```bash
   cd /opt/homelab
   cp -a compose.yaml compose.yaml.bak
   scp <new compose>; docker compose up -d <svc>
   ok=no
   for i in $(seq 1 20); do sleep 6; <functional probe> && { ok=yes; break; }; done
   [ "$ok" = yes ] || { cp -a compose.yaml.bak compose.yaml; docker compose up -d <svc>; }
   ```

   - Pull the new image first (`docker pull`) so a bad tag aborts before the working
     container is removed. Never send `docker compose up` output to `/dev/null`.
   - The backup must be older than the change. When changing several services, stage one at
     a time, or refuse a backup that already holds the new setting:

     ```bash
     grep -q '<the new setting>' "$BAK" && { echo "not a rollback point"; exit 2; }
     ```

4. **Probe the function of each service**, not its status:

   | Service        | Probe                                                                                                      |
   |----------------|------------------------------------------------------------------------------------------------------------|
   | Traefik        | force a real ACME issuance (throwaway router on a name with no A record; DNS-01 needs none) — cached certs hide a broken config for weeks |
   | Pi-hole        | resolve a name, a *blocked* name, a split-DNS name; check the log for permission errors even when it resolves |
   | Databases      | a SQL round-trip, not the healthcheck                                                                      |
   | Transmission   | RPC with good credentials (409) *and* bad ones (401) — a 409 alone can mean auth is off                    |
   | wg-easy        | `wg show` handshake ages, then ping a peer; poll for a minute, clients reconnect at their own pace        |
   | Uptime Kuma    | spawn a ping from inside the container                                                                     |
   | Nextcloud      | `occ status` plus the age of `core lastcron`                                                               |
   | Nextcloud cron | `core lastcron` **must advance** — without `SETGID`, busybox `crond` logs "can't set groups" and never runs `cron.php` |
   | Netdata        | uid of PID 1 = 201, the full plugin list, chart-context counts per family — see `docs/07-observability`   |
   | Collabora      | convert a file with `/cool/convert-to/pdf`; `/hosting/discovery` proves nothing                            |

   - A probe a cache can answer proves nothing. For DNS, query a random label (`NXDOMAIN`
     passes: upstream replied), and check the container is `running` first.
   - Check the probe can succeed. The Pi does not use Pi-hole as its resolver, so internal
     names do not resolve on the host: use `curl --resolve <name>:443:<pi-lan-ip>` or probe
     from inside the container. Only `drive` and `services` are pinned in `/etc/hosts`.
     Example of the failing form: `curl https://videos.example.com/health`.

5. **If the image declares `VOLUME` at the path you change, delete the container.** On
   recreate, Compose carries over mounts for image-declared volume paths, so a removed mount
   survives until its source disappears and the restart fails with:

   ```
   invalid mount config for type "bind": bind source path does not exist: ...
   ```

   ```bash
   docker image inspect <image> --format '{{json .Config.Volumes}}'
   docker rm -f <svc> && docker compose up -d <svc>
   ```

   Then check `docker inspect <svc> --format '{{range .Mounts}}...'`, restart once to prove
   the mount survives, and remove the anonymous volume this recreation left
   (`docker volume rm <id>`), not every dangling volume: older ones can hold data.

6. **Making a container read-only** ([ADR-019](../decisions/ADR-019-read-only-rootfs.md)):
   list the write set with `docker diff <container>`, then:

   - Mount the leaf, never the parent: `/run/mysqld`, `/run/postgresql`, `/run/netdata`, not
     `/run` (it erases the image's subdirectories: `Bind on unix socket: No such file or
     directory`). Check what a directory holds first — netdata's `/var/log/netdata` is all
     symlinks to `/dev/stdout`.
   - `tmpfs` is `noexec` by default. s6 stages binaries under `/run`: use `- /run:exec`.
   - A write target that shares a directory with image content is a stop: leave the rootfs
     writable and write down why.
   - `docker diff` misses rare paths (log rotation, cert renewal, weekly jobs): probe them.

7. **Leave `/opt/homelab/compose.yaml` matching the running state.** A rolled-back container
   with a broken file comes back broken on the next `up` (heal timer, reboot, deploy).

8. **Changing capabilities, `read_only` or `security_opt`.** The posture check's expectations
   are generated from `compose.yaml` into a goss spec. The render is `tags: always`, so any
   tagged run, `--tags deploy` included, refreshes it. After a deploy, compare `sudo grep <service> /etc/goss/posture.yaml` with the compose
   block before chasing a posture finding.

## Restarting a container that others share a namespace with

With `network_mode: "service:<other>"`, restarting the host container destroys the namespace;
the guest keeps running, detached, and never recovers. Here the pair is `pihole` and
`dnsproxy` (Pi-hole's only DoH upstream, `127.0.0.1#5053`). Restarting Pi-hole alone causes a
LAN-wide DNS outage while both containers read `healthy`.

Symptoms:

- The `Pi-hole DNS` Kuma monitor goes down (`queryA ETIMEOUT`). It is the fastest and usually
  the only signal: check Kuma first.
- Pi-hole's log shows:

  ```
  WARNING: Connection error (127.0.0.1#5053): TCP connection failed (Connection refused)
  ```

Any change to the split-DNS template fires the `Restart pihole` handler, which restarts the
pair in order. By hand, the fix depends on the trigger:

- After `docker restart pihole` (same container ID):
  ```bash
  docker restart pihole && docker restart dnsproxy
  ```
- After `docker compose up -d pihole` or anything that **recreates** pihole — a plain restart
  of dnsproxy exits 1 against the dead ID and leaves it stopped:
  ```bash
  docker compose up -d --force-recreate dnsproxy
  ```

The handler is in `ansible/roles/deploy/handlers/main.yml`; the recreate case is handled by a
task in `ansible/roles/deploy/tasks/compose.yml`.

Before restarting anything, check what rides on its namespace:

```bash
docker ps -q | xargs docker inspect \
  --format '{{.Name}} {{.HostConfig.NetworkMode}}' | grep container:
```

Read the service's own log before suspecting the network layer.

## When `compose up` cannot perform the change

Some image bumps need a data migration the image will not do (wg-easy 15:
[ADR-020](../decisions/ADR-020-wg-easy-15-migration.md)). Started on old data, it reopens its
setup wizard and brings up no tunnel, with the container green.

- Put the migration inside the deploy path, as a self-guarded Ansible task between the
  compose file copy and `compose up`; delete it once it has run
  ([ADR-030](../decisions/ADR-030-configure-the-tools-dont-write-the-glue.md)).
- Stage it on a copy of the data with a throwaway container that publishes nothing, and
  check the result (for a VPN: same server key, same peers).
- Remove the container, do not stop it: the heal timer restarts exited containers every two
  minutes. Use `docker compose rm -sf <svc>`.
- Hold the version meanwhile with a Renovate `allowedVersions` rule.

## Restoring quickly

From the backup copy, or from git with `git show <ref>:docker/compose.yaml`:

```bash
cd /opt/homelab
cp -a compose.yaml.bak compose.yaml
docker compose up -d <svc>
```

Recreation takes seconds; noticing takes longer, which is why step 3 automates the rollback.
