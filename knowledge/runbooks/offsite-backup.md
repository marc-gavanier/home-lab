# Runbook — Offsite backup Pi (ADR-010)

The offsite Pi ("backup", 10.8.0.4 on the VPN) receives a nightly
`restic copy` from the homelab and exposes the repo via rest-server in
append-only mode. The repo password is deliberately NOT stored on it.

## Daily operation (all automatic)

- 03:00 — `homelab-backup.service` runs resticprofile twice: a local backup, then
  an offsite copy of **every** snapshot not already there (Kuma push monitor
  "offsite copy").
  It is a retry window, not a single `restic copy latest`: a night that failed its copy
  is picked up by the following nights instead of being lost (#158). Re-offering
  snapshots already present creates no duplicates. So a red copy monitor that goes
  green the next night has **self-healed**, and needs no manual copy.

  The beat reads `offsite copy completed`, and that is all it reads. This page
  used to quote `1 new, 7 already there` as the message to look for — that was
  `backup.sh`'s wording, built from restic's `--json` summary, and it died with
  the move to resticprofile (ADR-031), whose hooks are not given the summary.
  Counting what a night actually copied means comparing snapshot counts, not
  reading the beat:

  ```bash
  ls /mnt/data/backups/restic-repo/snapshots | wc -l            # local
  ssh offsite 'sudo ls /mnt/backup/restic/snapshots | wc -l'    # offsite, filesystem only
  ```

  The `sudo` on the offsite side is load-bearing: `snapshots/` is `0700
  rest-server`, so without it `ls` is denied and `wc -l` still prints a small
  number rather than an error. A count that looks like an almost-empty
  repository is the worst possible answer on this page.
- Tuesday 02:00 — homelab `homelab-offsite-check.timer`: `restic check` of the
  offsite repo through the tunnel (Kuma push monitor "offsite check").
- Daily 08:00 — offsite `offsite-health.timer`: disk/SMART/power self-report,
  and the assertion that the rest-server still refuses deletes (Kuma push
  monitor "offsite health"). Daily since 2026-09-12: it was weekly, which gave
  the append-only property a seven-day detection window.

  **Do not maintain the DOWN conditions by hand — read them.** This list drifted
  8 assertions behind the spec between 2026-08-21 and 2026-08-29, while
  `backup-monitoring.md` pointed readers here for "the exact DOWN conditions".
  The authoritative list is the named assertions in the spec itself:

  ```bash
  ssh offsite 'sudo sh -c "grep -oE \"^  [^ #][^:]*:\" /etc/goss/offsite-health.yaml | sort | nl"'
  ```

  Note the `sudo sh -c`: `/etc/goss` is `drwx------`, so a glob or a redirect
  written outside the privileged shell silently returns nothing.

  **And note the character class, which is the reason this command is numbered.**
  It used to read `[a-z0-9-]+`, and that pattern cannot match a resource whose
  name carries a `.`, a `/` or an `@`. Measured 2026-09-05: it returned **30 of
  35**, dropping `/mnt/backup`, `fail2ban.service`, `rest-server.service`,
  `ssh.service` and `wg-quick@wg0.service` — the five whose own comments in the
  spec say every other assertion depends on them. The page told you to read the
  spec instead of maintaining a list by hand, and then read it through a filter
  that quietly removed the important part. `nl` numbers the output so the count
  is in front of you: if it drops, suspect the pattern before the spec.

  **The count and the taxonomy that used to sit here have been deleted, and the
  deletion is the fix.** This paragraph said "22 assertions, in five groups" and
  listed them, four lines under its own instruction not to maintain the DOWN
  conditions by hand. It had already been corrected once for drifting eight
  assertions behind the spec between 2026-08-21 and 2026-08-29; it then drifted
  **seven in a single day**, because #291 and #292 added conditions — the clock,
  the control parity, the unit state — that fit none of the five groups. An
  operator diagnosing a DOWN would have read a taxonomy that could not contain
  the assertion which fired, and gone looking for a fault in disk or SMART.
  Run the command above; it is the answer.

  **One condition is not in the spec, deliberately**: security updates still
  unapplied after 48 h. It needs to remember when the count first went nonzero,
  which goss cannot do, so it lives in `offsite-health.sh`. Its 48 h is measured
  against the daily cadence it has had since 2026-09-12, so it means "still pending
  at the next two runs". The reboot half is absent on purpose: this host reboots
  itself at 04:00 (ADR-013).

  CPU temperature was reported and never compared until #201, on a host sampled
  once a week.
- 1st of the month 04:00 — offsite `offsite-smart-test.timer`: SMART long
  self-test (the drive scans its own surface); result read by the daily
  health report.

## Management access (SSH)

Since the 2026-07-25 move the tunnel is the only way in: the LAN IP the Pi was
prepared on no longer routes, and the Pi dials out rather than accepting an
inbound connection. Reach it through the homelab, which holds the peer
identity (`homelab-host`, 10.8.0.5):

```bash
ssh -J homelab -p <ssh_port_hardened> <admin_user>@10.8.0.4
```

Worth a workstation alias — `~/.ssh/config`:

```
Host offsite
    HostName 10.8.0.4
    User <admin_user>
    Port <ssh_port_hardened>
    IdentityFile ~/.ssh/id_ed25519
    ProxyJump homelab
```

The jump only works once the homelab has been unlocked: its `wg-quick@wg0`
config lives on the encrypted volume, so the tunnel is pulled in by
`mnt-data.mount`, not at boot. A refused jump right after a homelab reboot
means `homelab-unlock` is still pending, not that the offsite Pi is down.

## Moving day checklist (installing at the relative's home)

1. Shut down cleanly: `ssh offsite sudo poweroff` (no USB tamper on
   this host; unplugging is safe once halted).
2. At the relative's home: plug ethernet + power. Nothing to configure — the
   WireGuard client dials out to vpn.<domain>:51820 from any network.
3. Verify from the homelab: `ping 10.8.0.4`, then
   `systemctl start homelab-offsite-check.service` and check Kuma goes green.
4. Nothing to change in the inventory: `offsite_ip` tracks `offsite_wg_ip`
   since the 2026-07-25 move, so Ansible already manages this host through
   the tunnel. Confirm with
   `cd ansible && ansible offsite -m ping --ask-vault-pass` — the `cd` matters,
   `ansible.cfg` points at `inventory/hosts.yml` relatively, so from anywhere
   else Ansible parses no inventory and just warns that the host pattern
   matched nothing.
   The override goes the *other* way now — if the Pi ever comes home for
   maintenance, or is reflashed before its WireGuard config exists, reach it
   on the LAN for that run only: `-e offsite_ip=<lan_ip>`.

## If the offsite Pi is stolen

The SSD holds only restic ciphertext, the htpasswd hash and the WireGuard
client key. The WG key is the only live credential:
1. wg-easy UI → delete/disable client `offsite-backup` (revokes VPN access).
2. Rotate `rest_server_auth_password` (vault) — it only guards bandwidth, not
   data confidentiality.
3. Recreate the Kuma "offsite health" push monitor (its token is in the
   health script — a thief could forge green pings with it).
4. The repo password was never on the Pi: backups remain confidential.

## Never run two copies at once

Two concurrent `restic copy` processes to the append-only repo re-upload
each other's packs as **permanent duplicates** (append-only blocks the
cleanup; interrupted copies also leave unindexed packs that the next run
re-uploads entirely). The 2026-07-12 initial seed collided with the 03:00
nightly copy this way: ~100 GB of duplicates, reclaimed by a one-time manual
prune. The profile now guards the WHOLE run — backup and copy alike — with
`lock: /run/lock/resticprofile-homelab.lock`, which is wider than the
`flock` on the copy step it replaces. A second invocation is refused with
"another process is already running this profile".

That protection only holds if manual runs go through resticprofile rather than
calling restic directly:

```bash
set -a; . /opt/homelab/backup.env; set +a
resticprofile -c /opt/homelab/resticprofile.yaml -n homelab copy
```

> **Corrected 2026-09-13.** The `backup.env` line was missing, and its absence
> was silent in both directions. `homelab-backup.service` sources that file
> through `EnvironmentFile=`, so the scheduled run has the Kuma push URLs and a
> hand-run from this block did not — `backup-notify.sh` found an empty URL,
> logged one line to `/var/log/homelab-backup.log` and exited 0. Measured on a
> real hand-run: `[14:41:24] no push URL for copy — nothing pushed`. The copy
> itself completed; nothing announced it, and the dead-man's window on the
> offsite monitor is 25 h, so a *failed* hand-run would have been just as quiet
> for just as long. `backup-notify.sh` now emits the lost-report marker in that
> case, which is the half that survives the next runbook omission.

> **Corrected 2026-08-29.** Until today this block showed
> `flock /var/lock/offsite-copy.lock restic copy ...` — a direct restic call
> holding the narrower lock that ADR-031 replaced, which is exactly what the
> sentence above it forbids. Someone reaching for a manual copy under pressure
> copies the block, not the sentence, and this page is the one that documents
> what that costs.

Also disable the backup timer for the duration of any multi-hour seed:
`systemctl disable --now homelab-backup.timer` (re-enable after).

## Manual retention (rare — when disk usage approaches 85%)

Append-only means no automatic pruning. On site (or via SSH), with the repo
password fetched from outside this host AT THAT MOMENT (never store it on the
Pi):

```bash
# restic and sqlite3 are installed by the offsite-backup role since ddc44c5 —
# they were added the day a real recovery attempt found them missing. Verify
# rather than assume on a freshly rebuilt host: command -v restic
sudo systemctl stop rest-server            # free the repo
sudo restic -r /mnt/backup/restic forget \
    --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --prune
sudo systemctl start rest-server
```

Enter the password at restic's interactive prompt (never export it into a
shell variable or file on this host).

## Deep integrity check (on demand — never yet performed)

**"Quarterly" is what this heading used to say, and nothing ever implemented
it.** There is no timer, no unit and no schedule behind the deep read: it
happens when someone runs the commands below, and as of 2026-09-19 nobody had.
The journal is not what establishes that: measured 2026-09-21, the offsite
journal reaches back to 2026-07-05 (the host's own birth) and the homelab's to
2026-08-30. 2026-05-14 is the date of the oldest local restic snapshot, which
is a different thing entirely. The scheduled
`homelab-offsite-check.service` is a **metadata** check by design — the
`offsite` profile in `resticprofile.yaml` carries no `read-data` flag and says
why: reading the data back would pull hundreds of gigabytes across a domestic
uplink to verify bytes the remote host can verify itself. Automating the deep
read sits next to the declined restore drill and is not proposed. Treat what
follows as a procedure available on demand, not as a cadence anyone is keeping.

> **Disable the backup timer for the duration. The profile locks do NOT cover
> this.** The two facts that make it necessary, both verified 2026-09-13:
> `check` takes an **exclusive** lock on the repository, and the `offsite`
> profile holds `/run/lock/resticprofile-offsite.lock` while the nightly copy
> runs under the `homelab` profile and holds a **different** lock
> (`resticprofile-homelab.lock`). Two different locks on one append-only
> repository serialise nothing. Running the command below "overnight", as this
> page used to say without qualification, aims a multi-hour exclusive lock
> straight at the 03:00 copy window — and the section *Never run two copies at
> once* above records what that cost the last time: ~100 GB of permanent
> duplicates.

```bash
sudo systemctl disable --now homelab-backup.timer     # re-enable when it finishes

sudo systemctl start homelab-offsite-check.service    # weekly metadata check
# Deep read of 2% of the data (WAN-heavy once offsite — several hours):
sudo -i
set -a; . /opt/homelab/backup.env; set +a
RESTIC_REPOSITORY="$OFFSITE_RESTIC_REPOSITORY" RESTIC_PASSWORD="$OFFSITE_RESTIC_PASSWORD" \
RESTIC_REST_USERNAME="$OFFSITE_REST_USER" RESTIC_REST_PASSWORD="$OFFSITE_REST_PASSWORD" \
restic check --read-data-subset=2%

sudo systemctl enable --now homelab-backup.timer      # and check it is armed
systemctl list-timers homelab-backup.timer
```

**Run it under `tmux` or `screen`.** The only route to this host is the single
WireGuard tunnel; a dropped SSH session kills the check mid-read and leaves the
exclusive lock behind, which is the next section.

### If a lock is left behind

Nothing in this repository documented `restic unlock` until 2026-09-13, and the
local stale-lock detector (`restic-repo-has-no-stale-lock`) scans
`<backup_dir>/restic-repo/locks` — **the local repository only**. The offsite
repository had no lock assertion at all; one was added to
`goss-offsite-health.yaml.j2` in the same change as this paragraph.

```bash
# List first. Never unlock blind — a lock with a live restic behind it is doing
# its job, and removing it is how two writers meet on an append-only repo.
restic list locks
restic unlock            # removes stale locks only
restic unlock --remove-all   # last resort, and only with NO restic running anywhere
```

A lock created by the offsite host's own manual prune carries
`hostname=offsite`, so the homelab can never age it out on its own — check both
hosts before concluding a lock is stale.

`restic unlock` acts on the repository's own `locks/` directory. It does not
touch resticprofile's **profile** lock, which is a separate file and the one
that produces "another process is already running this profile":

```bash
ls -l /run/lock/resticprofile-*.lock   # the profile locks
pgrep -a resticprofile                 # nothing? then the lock is orphaned
rm /run/lock/resticprofile-homelab.lock
```

These live under `/run/lock` — a tmpfs — so a reboot clears them and an orphan
can only outlive the run that made it, never the boot. They were under
`/var/lock` until 2026-09-21, which on this image is a real directory on the
root filesystem rather than the symlink to `/run/lock` that
`/usr/lib/tmpfiles.d/legacy.conf` declares, so an orphan survived indefinitely.
`force-inactive-lock` is still deliberately unset: breaking a lock automatically
repairs without reporting, which is how issue #331 went unnoticed for eight and
a half hours.

## Disaster recovery (homelab lost)

1. Retrieve the offsite Pi or its SSD — **or read it where it stands**, which
   the 2026-08-15 drill proved works and is faster. On the relative's LAN, with
   no tunnel and no homelab:

   ```bash
   ssh -o ProxyJump=none -p <ssh_port_hardened> <admin_user>@<pi-lan-ip>
   sudo restic -r /mnt/backup/restic snapshots
   ```

   Two things bite here. The repository belongs to `rest-server`, so without
   `sudo` restic fails on `keys/` before asking for anything. And the host key
   is known under the tunnel address, so connecting by LAN address trips
   verification — compare the fingerprint against the known one instead of
   accepting blindly.
2. On any machine: `restic -r /mnt/backup/restic restore latest --target /restore`
   with the **offsite repo password** — the vaulted `offsite_restic_password`,
   **not** the local `restic_password`. They differ by design, and the first
   drill attempt failed for exactly that reason. This password is the root of
   the whole recovery chain; make sure a copy of it survives whatever takes out
   the homelab — and keep that copy **physically apart from the media carrying
   the repository**. Stored side by side, they stop being two things: one theft
   hands over the plaintext of every snapshot, and the design's promise that a
   stolen disk yields only ciphertext (ADR-010) quietly stops being true.
3. Re-provision a new Pi from the git repo (`ansible/`), reinject
   `/restore/mnt/data/...` and the `.env` files from `/restore/opt/homelab`.
4. Follow "Full disaster recovery" in `restore-from-backup.md`.

See also: ADR-010, `backup-monitoring.md`, `restore-from-backup.md`.
