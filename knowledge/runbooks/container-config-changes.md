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

6. **Leave the Pi's file consistent with the running state.** `docker compose`
   reads `/opt/homelab/compose.yaml`; if a container was rolled back but the file
   still holds the broken definition, the next `up` — from the heal timer, a
   reboot, or an Ansible deploy — reintroduces the failure. Ansible re-templates
   the file, so a temporary hand-copy is fine, but it must not be left behind.

## Restoring quickly

```bash
cd /opt/homelab
cp -a compose.yaml.bak compose.yaml     # or: git show <ref>:docker/compose.yaml
docker compose up -d <svc>
```

A container recreation is seconds. What takes time is noticing, so the
automation in step 2 is worth more than speed here.
