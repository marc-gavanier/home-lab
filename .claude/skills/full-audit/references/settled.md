# Settled

Living document. Paste it into every agent brief, and update it after every run
— both what got fixed and what was declined. Its whole value is being current:
an agent that re-proposes something already turned down burns the report's
credibility along with its own budget.

**State does not live here. It lives in `classes.md`.** Counts, cardinals and
"still open" tables belong to the register; this file holds decisions, history
and instrument traps. That split exists because every stale number this file has
carried has propagated straight into the next run's eight agent briefs — three
times with the same figure, the goss total, which by 2026-08-29 contradicted
itself twice within the same document. When you are tempted to write a number
here, write the rule that regenerates it instead.

Two kinds of entry, and the distinction matters:

- **Declined** — the operator considered it and said no. Not an oversight, not
  an opening for a better-argued version. Do not raise it again. If a later
  change makes the underlying gap materially worse, state the new fact; do not
  repeat the old proposal.
- **Measured and rejected** — it was investigated and the numbers killed it.
  Re-raising it requires new numbers, not new enthusiasm.

---

## Shipped on 2026-09-26 (SIXTEENTH run) — key `propagation`, one PR, deployed from the branch before merge

- **The homelab's `pending` monitor now asks `needrestart -b`** once dpkg has
  changed since boot: a service needrestart excludes or suspends keeps a replaced
  library until a reboot, and only apparmor, dbus, libc6 and libpam0g write
  `reboot-required`. In batch mode needrestart lists excluded services too and
  never restarts anything (read in its source).
- **The four `/etc/hosts` / cloud-init pins carry a `regexp:`**, so a changed
  `homelab_ip` replaces the line instead of appending one behind the old.
- **`rotate-a-secret.md`: replace any offline copy of a restic password before
  removing the old key.**
- **Documentation**: the posture message and network page on re-importing VPN
  client configs and the unwatched LAN subnet; how to tell a stale LUKS header
  copy; the heal timer skips exit code 0; Miniflux's datadir is lost on `down`,
  not on `--force-recreate`; `run-before` destroys restored dumps on ANY run;
  12 pointers to comments #390 removed; ADR-007/013/015/017/012, pihole,
  wireguard-peer-revocation, container-config-changes.

## Decisions taken on 2026-09-26 (sixteenth run) — do not re-propose

- **The operator's rule for this run, and for fixes in general: if the fix costs
  more than it pays, even for an important gap, don't build it.**
- **No guard on the `deploy` handlers against a lost handler queue (C84).** An
  interrupted deploy (Ctrl-C, lost SSH, a failing earlier handler) can leave a
  service on its old config with a `changed=0` next run; `force_handlers` covers
  none of it. Accepted and documented in `.claude/agents/ansible-deploy.md`.
- **No needrestart check on the offsite.** Its excluded services wait for the
  next kernel auto-reboot.
- **The LAN subnet stays hard-coded and unwatched**, documented as accepted in
  `docs/04-network/README.md`.

## Instrument traps paid on 2026-09-26 (sixteenth run)

- **`tr -d "\x27"` deletes the characters x, 2 and 7**, not a quote.
- **A trailing newline changes a hash**, and `jq -r`, `cat` and command
  substitution disagree on it — normalise both sides before comparing.
- **`ExecMainStartTimestamp` of early-boot units can be ~40 h off the wall
  clock** (pre-NTP), far more than the ~73-100 s recorded earlier. Compare
  monotonic timestamps.
- **`needrestart -b` costs 4-6 s of CPU on a Pi**: gate it.
- **Every agent that needed a scratch file wrote one to `/dev/shm` on the host.**
  Pipe scripts through `ssh host 'sudo bash -s' <<'EOF'` instead.

## Shipped on 2026-09-26 (FIFTEENTH run) — key `truncation`, one PR, deployed from the branch before merge

- **`-e deploy_services="a b"` deployed `a` only, with a clean recap.** Ansible
  splits a `-e k=v` string at spaces; the dropped words land in `_raw_params`.
  15 runs in that form in the operator's history, the last on 2026-09-25
  (netdata deployed, calibre-web not). Both playbooks now open with an `always`
  assert that `_raw_params` is undefined — red on the broken form, green on
  `-e deploy_services=x` and on the JSON form, tested. `.claude/agents/ansible-deploy.md`
  taught the broken form and now teaches the JSON one. Filed under C77.
- **The UFW→fail2ban handler is `reload --restart`** — see the correction under
  the 2026-09-13 shipped list below.
- **Push messages capped at 1 000 characters** in `homelab-posture`,
  `homelab-health` and `homelab-netdata-kuma`, ending in `… +N characters, full
  text in the journal`, with the full text written to the journal first. Kuma
  hands `msg` verbatim to a Discord embed field, Discord refuses a field over
  1 024 characters with HTTP 400, and Kuma only logs the refusal: the WHOLE alert
  was lost, not its tail. Longest DOWN ever notified 718 (posture, 2026-09-07).
- **Documentary corrections**: `rotate-a-secret.md` (the success line it quoted
  does not exist), `docs/04-network/README.md` and the posture failure message
  (the "19 places" count), `docs/03-security/README.md` (16 of 32 keep no
  capability; the published ports), `claude-code.md`, `restore-from-backup.md`
  (dumps survive a FAILED run), `boot-and-unlock.md` (compare counts, not colours).

## Decisions taken on 2026-09-26 (fifteenth run) — do not re-propose

- **No pre-commit gate for C124.** `ansible-deploy` sketched one (six grammars,
  an `# [important]:` marker) and judged it a list-gate of low value; C124 stays
  ENUMERATED.
- **The posture LAN-address check keeps `head -1`** over eth0's global IPv4
  addresses (1 of 1 today). Recorded as latent, not changed.

## Instrument traps paid on 2026-09-26 (fifteenth run)

- **`api/v1/alarm_log` is bounded by COUNT, not by time**: it returns the newest
  N transitions, N being `[health] in memory max health log entries`
  (`docker/configs/netdata/netdata.conf`), 5 000 today = 2 h 36 min. The meta
  database holds the 60 days. The twelfth run's "1 000 entries over 0.37 day" was
  the same bound at its old default. Answer "has this ever tripped" from the
  database read `mode=ro`, or from the metric range.
- **An empty `iptables-save | grep f2b` proves nothing**: fail2ban creates its
  chains on the first ban, and there were 0 bans. The main session paid it.
- **`fail2ban-client get <jail> <unknown attribute>` writes an ERROR line into
  `fail2ban.log`.** Read-only in intent, not in effect. Paid by `security` (3 lines)
  and by the main session (1).
- **A template already wrapped in `{% raw %}` must not be wrapped again**: a
  nested `{% endraw %}` closes the outer block early and the file fails to render
  ("Missing end of comment tag"). And Ansible trims the newline after a block tag,
  so `fi{% endraw %}` glues `fi` to the next line. Wrap the token inline,
  `"{% raw %}${#msg}{% endraw %}"`, as `homelab-posture` does, and render with
  Ansible's own `template` module: it sets `trim_blocks`, plain Jinja2 does not.

---

## Shipped on 2026-09-25 (THIRTEENTH run) — key `initiality`, one PR, deployed from the branch before merge

- **The journal-on-volume block moved from `base/tasks/logging.yml` to
  `storage/tasks/journal.yml`.** `base` runs on the offsite, which has no
  `mnt-data.mount`, so `add-wants` failed there on every run since `e273399`.
- **`deploy` stats `homelab-stack-heal.timer` before suspending it**, and
  **`daemon.json` is written before `docker-ce` is installed** — both only
  mattered on a fresh provision.
- **The `Reboot required` handler touches `/var/run/reboot-required`** instead
  of printing a debug line, so the `pending` monitor asks for the reboot boot
  settings need.
- **netdata→Kuma adapter: a running netdata younger than `STARTUP_GRACE` that
  does not answer at all is reported UP.** Stopped or absent stays DOWN.
  `RestartCount` is useless as a crash-loop guard here: netdata runs with
  `restart: "no"` and the heal timer's `docker start` does not increment it.
- **netdata `stop_grace_period: 90s`.** The general extension stays DECLINED;
  this is the per-container, measured-loss exception, like transmission's.
- **calibre-web `start_period: 900s`** (cold boot 2026-09-24: ~800-830 s).
- **The deep-check posture assertion reads `.success` first.**
- **Comments corrected**: the unlock script's arming comment and timing message,
  ADR-008's arming sentence, and the two `backup.yml` comments that described a
  boot catch-up.

## Decisions taken on 2026-09-25 (thirteenth run) — do not re-propose

- **The USB tamper response stays armed AFTER the integrity check and the
  mount, not at `cryptsetup open`.** The key sits unprotected in RAM for the
  length of `e2fsck` — under a second normally, minutes on the monthly forced
  check. Arming earlier would let a touched cable power off the Pi in the middle
  of a repair on a disk that is itself on USB. The window is accepted and
  documented in ADR-008.
- **`homelab-health`'s 240 s unit gate is NOT raised for `claude-remote-control`'s
  cold-boot wait** (551 s on 2026-09-24, 228 s on 09-20). 0 of 2 reports were
  delivered, and the gate is shared by every unit. Re-raise only with a
  delivered false red.
- **`/var/lock/offsite-copy.lock` is left in place.** It is a `flock` target
  that a runbook still uses by hand; a flock is released on process exit
  whatever the file's persistence. Inert by construction.

## Instrument traps paid on 2026-09-25 (thirteenth run)

1. **Pi-hole's FTL database has no rows for the queries answered while it
   reloads its history at start** — 292-311 s on a cold boot, 70-130 s warm,
   93 queries missing on 2026-09-24. Read a boot timeline from `pihole.log`.
2. **The journal's wall clock is ~73-100 s off before NTP on every boot.** Boot
   timelines are read in monotonic time or after the first sync.
3. **Two instruments, one fact.** A first verdict dated from netdata's own data
   (779 s) and from the adapter's log (<= 986 s) are a value and an upper
   bound; the adapter logs nothing on the steady path.
4. **`pkill -f` on the host matches the agent's own SSH command line.** It
   killed its own session. Stop a runaway remote command with the local
   timeout, never with a pattern kill on the host.

## Shipped on 2026-09-21 (TWELFTH run) — key `durability`, one PR, deployed from the branch before merge

Six live corrections and nine documentary ones. The key asked one question of
every mechanism — does the state it relies on outlive what is asked of it? —
and required two numbers for every instance: the depth DEMANDED and the depth
RETAINED.

- **netdata's alarm transition history: `5d` -> `60d`, in-memory entries
  1 000 -> 5 000** (`docker/configs/netdata/netdata.conf`, a `[health]` section
  the file never had). The metric store retains 55 days; the store that answers
  "has this alarm ever fired?" retained five. Proof it mattered: the swap guard's
  own rupture, 94.55 % against an 85 % threshold on 2026-08-31→09-02, left no
  retained transition, with a positive control. **This is a bound on the audit's
  own instruments before it is a defect in the estate.**
- **`STARTUP_GRACE` 300 s -> 1 200 s**
  (`roles/observability/templates/homelab-netdata-kuma.sh.j2`). Measured startup
  is 787 s, so the adapter was declaring a fault 487 s early: six DOWN beats on
  2026-09-20, two monitors red for 7 min 33 and 6 min 17 with nothing wrong, six
  such non-incidents in fifteen days. The agent derived 900 s from the longest
  curated `lookup` window plus collector startup; **the operator chose 1 200 s.**
  **The 787 s is a COLD start and the original measurement did not say so.**
  netdata was restarted twice while verifying this change, on a warm host with
  the stack already up, and both times the health engine had real verdicts
  within 297 s — so neither restart entered the grace window and neither
  exercised the fix. The six false reds it removes all followed a BOOT, when
  the whole stack competes for the Pi. **The change is justified and unproven,
  and the distinction is the finding**: a measurement of a startup cost must
  say which start it measured. It will first be exercised at the next full
  boot, which cannot be provoked here — a reboot costs the tunnel, hence the
  host. Zero DOWN beats across both restarts either way.
- **Two restart limiters made reachable**, and **the two windows are different
  on purpose**: `StartLimitIntervalSec=600` / `StartLimitBurst=5` on
  `vault-mount` (`roles/claude-code/tasks/vault.yml`), `300` / `5` on the
  offsite `rest-server`
  (`roles/offsite-backup/templates/rest-server.service.j2`). With `RestartSec=10`
  against the undeclared default window of 10 s, five attempts span 40 s and the
  burst counter resets between them, so `failed` was unreachable and
  `systemctl --failed` could never see either unit. **The window must span BURST
  whole ATTEMPTS, and an attempt is not the same length on both units**:
  `rest-server` is `Type=simple`, so a start does not wait and an attempt costs
  `RestartSec` alone (5 x 10 = 50 s, 300 s with room); `vault-mount` is
  `Type=notify` and inherits `DefaultTimeoutStartUSec=1min30`, so an attempt on
  the HANG path — the documented rclone failure this unit exists to survive —
  costs 90 + 10 = 100 s and the window must reach 5 x 100 = 500 s. **The first
  patch gave both 300 s**, which would have left `vault-mount` exactly as
  unreachable on the hang path as the default did; caught on 2026-09-21 by
  writing the derivation down, not by testing. See the instrument traps.
- **The resticprofile profile locks moved from `/var/lock` to `/run/lock`**
  (`roles/deploy/templates/resticprofile.yaml.j2`, both profiles). `/var/lock`
  is a real directory on the root filesystem on BOTH hosts — dev 45826 against
  `/run/lock`'s dev 28 — because `/usr/lib/tmpfiles.d/legacy.conf`'s `L` directive
  cannot replace the directory `base-files` ships. A profile lock left by a hard
  kill therefore survived the boot, on a path whose name says it should not.
  `/run/lock` is the tmpfs, so a reboot now expires it.
- **The runbook's lock repair section now names the right file**
  (`knowledge/runbooks/offsite-backup.md`). It taught only `restic unlock`,
  which acts on the repository's `locks/` directory; the profile lock that
  produces "another process is already running this profile" is a different
  object that no assertion watches.

**Deployed from the branch and verified 2026-09-21, before merge.** Two hosts,
`--tags observability,claude-code,backup` and `--tags offsite-backup`. Verified
on the running systems rather than from the recap: `vault-mount` reads
`StartLimitIntervalUSec=10min` / burst 5 against `RestartSec=10` and
`Type=notify`, so five hang-path attempts at 100 s fit inside the window and
`failed` is reachable — and the mount still answers, with Remote Control active,
which is the function and not the status; `rest-server` reads 5min / 5 on the
offsite host, correct for `Type=simple`; the running netdata agent serves
`health log retention = 2mo` (it normalises `60d`) and `in memory max health log
entries = 5000`; `/opt/homelab/resticprofile.yaml` carries both locks under
`/run/lock`, confirmed on dev 28, the tmpfs. **Idempotence proven on a third
pass: `changed=0`.** The second pass showed `changed=2` and it was not a defect
— the first deploy predated the commit that added the derivations, so those two
files were landing for the first time; the main session had flagged only
`vault-mount` as missing from that first pass and should have flagged the two
observability files with it.

## Decisions taken on 2026-09-21 (twelfth run) — do not re-propose

- **Alarming on transmission's forced kills is DECLINED.** The operator:
  transmission habitually crashes during downloads, alarms on it are wasted
  effort, *"ce qui m'intéresse c'est qu'au final ça se remet"*. The measured
  facts stand and are recorded rather than acted on: over 14 days the docker
  journal holds 114 "using the force" — 87 at the 10 s default, 5 at 5 s, 1 at
  1m0s (transmission's declared 60 s budget) and none at 90 s — while
  `no-container-came-back-recovering` loops over a hand-written list of exactly
  the four containers at 90 s, the only budget never exceeded. **The assertion
  was deliberately NOT re-derived from `compose.services[*].stop_grace_period`,
  because deriving it is precisely what would add transmission to it.** The
  derivation defect remains recorded and unfixed, the same shape as C18's
  `logs.db` siblings. A proposal that demonstrates RECOVERY instead of alarming
  on the kill is a different question and has not been put.
- **`force-inactive-lock` stays unset** — re-confirmed, not re-decided. The
  repo's own reasoning at `goss-units.yaml.j2:235` is the answer to any future
  proposal: it authorises a run to break a lock it did not create and repairs
  without ever reporting, which is how #331 went unnoticed for eight and a half
  hours. Detection first. An agent proposed setting it on 2026-09-21 and was
  declined on that ground.
- **pihole's `start_period` of 120 s against the 300 s the staged startup grants
  itself** is a real C120 instance, deferred rather than declined. The one-line
  remedy recreates pihole and destroys dnsproxy's network namespace; the measured
  cost of doing nothing is 0 over 16 days. Ship it inside a pihole deploy that is
  already happening for another reason, never on its own.

## Withdrawn after measurement on 2026-09-21 (twelfth run) — 2

- **"`--tags storage` before `homelab-unlock` writes 4 GiB onto the SD card."**
  Refuted by the main session and withdrawn by its author, along with the class
  it had minted. `storage/tasks/luks.yml:16-22` opens the LUKS volume
  unconditionally; `storage/tasks/mount.yml:59-63` starts `mnt-data.mount` with
  no `ignore_errors` or `failed_when` anywhere in the role, so a failure aborts
  four imports before `swap.yml`; and `deploy/tasks/main.yml` carries
  `tags: always`, so its mount assert runs under ANY tag filter — the claim that
  it is "never executed under `--tags storage`" was the pivot and was false.
  `--start-at-task` is the only path that reaches `swap.yml` bare, and the agent
  refused to use it to save the finding, correctly: that flag disables every
  precondition in the play and the same argument would condemn every ordering
  invariant in the repo.
- **"5 tmpfs mounts, not the 41 the register carries."** Not a register
  correction. Measured both ways by the main session: `mount -t tmpfs | wc -l`
  gives 5 on the host, the sum of `HostConfig.Tmpfs` over running containers
  gives 41 — which is C36's space and C36's cardinal, correct and unchanged.
  **Two different spaces sharing a word; the register would have been corrupted
  by believing the agent.**

## Instrument traps paid on 2026-09-21 (twelfth run) — four, and TWO were the main session's own

1. **`StartLimitIntervalSec` is silently ignored in `[Service]`** — systemd
   moved it to `[Unit]`. The main session wrote it into the wrong section for
   both units and caught it by re-reading the rendered template rather than by
   testing. A unit that ignores the directive looks exactly like one that
   honours it.
1b. **And then sized the window against the WRONG PATH.** Both units first got
   300 s. `vault-mount` is `Type=notify` and inherits a 90 s start timeout, so
   an attempt on the hang path costs 100 s and five need 500 s — the very path
   the unit exists to survive, since its documented failure is rclone hanging
   on a dead endpoint. 300 s would have left it as unreachable as the default.
   **Caught only when the operator asked for the derivation to be written into
   the comment**, which is the argument for that convention: the number that
   cannot be derived in writing is the number that is wrong. A guard sized
   against the fast path of a mechanism whose slow path is the failure mode is
   itself a C120 instance, produced by the run that closed C120.
2. **Two lock objects with similar names.** The main session attributed its
   `/var/lock` discovery to issue #331 and was wrong: #331 concerns restic
   REPOSITORY locks, which live inside the repository on `/mnt/data` and survive
   a reboot because that is what a repository does. The deployed detector
   (`restic-repo-has-no-stale-lock`) scans `<backup_dir>/restic-repo/locks` and
   has never watched the profile lock. Caught by reading the detector before
   writing the register.
3. **`resticprofile` cannot be run by hand outside its unit** — the repository
   comes from an `EnvironmentFile`, and a bare invocation fails with
   `unable to open config file: stat <no value>/config`. The main session could
   not independently re-measure the snapshot census and SAID SO rather than
   inheriting two agents' figure silently. It also verified its failed attempts
   left no lock behind, which is the check that matters when the audit's subject
   is stale locks.
4. **`docker diff` reports bind MOUNTS as added files.** Two `php/conf.d/*.ini`
   entries under nextcloud look exactly like the `zz-disable-jit.ini` that fell
   into the writable layer on 2026-08-27 and cost six hours of outage.
   `compose.yaml:885` mounts them. Self-caught by `services`.

---

## Shipped on 2026-09-20/21 (ELEVENTH run) — key `tolerance`, PR #378, deployed from the branch before merge

Six live defects, all of them instances of the class this run minted: a guard
sitting at the wrong distance from the rupture it guards. Deployed with
`--tags security,observability,claude-code,stack-startup,deploy` and
`-e '{"deploy_services": "traefik"}'`, `changed=17`, then `changed=0` on the
idempotence re-run **before** the merge.

1. **`vault-mount` ordered after the staged startup.** It restarted 15 times on
   2026-09-20 and still read `active`/`success`, because its 15 s failure cycle
   never fits the **systemd default** `StartLimitIntervalSec=10s` — the burst
   counter resets between attempts, so `failed` is unreachable and nothing can
   report it (0 of 59 283 retained Kuma beats mention it). The cause was
   ordering, not the limiter: it mounts over HTTPS while the stack is still
   coming up. `After=homelab-stack-startup.service` binds only when both units
   share a transaction, so nothing is delayed when `claude-remote-control` pulls
   the mount later. Verified `NRestarts=0`.
2. **`homelab-stack-startup`: ceiling 600 -> 1800 s, limiter window 1800 ->
   7200 s.** The script grants itself 660 s of health gates before any dispatch;
   the last cold start used 482 s of 600. Its limiter could not fire either —
   3 x (600 + 60) never fit 1800 s — so the unit could not reach `failed`, and
   neither the alert nor the crash-heal that waits on `is-failed` could run. The
   window is now derived from the attempt cost and the derivation is written
   beside it.
3. **The credential masker gained a padded-base64 alternative.**
   `[A-Za-z0-9_]{32,}` counts word characters; base64 uses `+` and `/`, which
   split a key into runs shorter than 32. Measured 107 of 200 synthetic 32-byte
   keys passing through untouched. Now `([A-Za-z0-9_]{32,}|[A-Za-z0-9+/]{20,}={1,2})`,
   which takes those 200 to zero survivors.
4. **`homelab-netdata-kuma` lost `--retry 2`.** Each push cost 3 x TIMEOUT, for a
   real ceiling of 336 s against a 240 s bound and a 300 s timer period. Above 336
   and below 300 cannot both hold, so the retry went rather than the bound; rc=28
   is already reported honestly as an unconfirmed beat.
5. **Traefik `readTimeout: 600s` on `websecure`.** Nothing declared
   `respondingTimeouts`, so all three entry points inherited the v3 default of
   60 s, which cuts any request body that takes longer regardless of throughput.
   Verified functionally after deploy: a body dripped for 75 s now completes,
   against a 403 control in 0.25 s proving the probe reaches Traefik.
6. **Kuma dead windows** (UI, not the repo): 15 `Backup` and 16 `Offsite backup`
   90 000 -> 93 600 s, 23 `Pi security posture` 90 000 -> 93 600, 30
   `Veille quotidienne` 90 000 -> 100 800. All five daily margins now sit in a
   6.8-7.4 % band instead of 3.0 %. **18 `Offsite health` was deliberately left
   at 90 000** — its red beats are genuine failures, not window expiries.

Documentary corrections in the same PR, each confronted with the running system:
the observability page promised `Count: 19, Failed: 13` for a hand-run of
`backup-dumps` where the machine answers 46/27, and now prints the derivation
instead of the pair; `.env.example` gained `LIBRARY_DIR` and the command that
derives its own gap; frozen fleet counts moved from a 21- and 28-container estate
to 32; the monitor count to 37; dozzle's "No tmpfs" sat one line under its tmpfs;
`middlewares.yml` named traefik's address as wg-easy's egress and now names no
literal at all; ADR-006 still listed a drawback `e1f071e` removed; the lynis
rationale spoke in the present of a masked timer; `kuma-dump` counted 114 monitor
columns against a live 120; a goss floor called itself `5x` above metadata at
300/32 = 9.4x; ADR-021's premise is dated rather than rewritten.

## Decisions taken on 2026-09-20/21 (eleventh run) — do not re-propose

- **The `/`-widened masking class is REJECTED, and it was measured before being
  rejected.** Adding `/` to `[A-Za-z0-9_]` reaches 100 % key coverage — the same
  as the form shipped — but it redacts filesystem paths in `sudo.log` and
  destroys the record of which file a root command touched. Cost measured on the
  live store: **270 extra lines changed in auth.log against 1** for the padded
  form, at identical key coverage. The operator's proposed character set also
  included `-`, which the repo had deliberately excluded because it masks goss
  assertion names like `no-kuma-report-was-lost-in-silence`; the shipped form
  keeps that exclusion.
- **journald is REJECTED as the redactor's log destination.** It is the one store
  the masking in the security role cannot filter — journald captures `_CMDLINE`
  itself, in binary, with no hook.
- **Traefik's read timeout is BOUNDED at 600 s, not disabled.** `readTimeout: 0`
  was proposed and not taken: 80/443 are not forwarded, so the slowloris
  rationale for the v3 default does not apply, but an unbounded read still holds
  a connection forever on a proxy that has a rate-limit middleware and trusted
  clients only.
- **Kuma monitor 18 `Offsite health` stays at 90 000 s.** Its retained red beats
  are substantive failures (`ssh.service`, `goss spec missing`), not window
  expiries, so the tightening applied to 15/16/23/30 does not apply to it.

## Withdrawn after measurement on 2026-09-20/21 (eleventh run) — 2

Both had already been relayed to the operator before the main session checked
them, which is why they are recorded here rather than quietly dropped.

- **"`.env.example` is missing three secrets, and a from-scratch rebuild brings up
  Pi-hole with no admin password."** NOT REPRODUCIBLE. Derived both ways against
  what the deploy actually writes: the gap between `env.j2` and `.env.example` is
  **one** key, `LIBRARY_DIR`. The Pi-hole and Redis secrets are docker secrets,
  not `.env` entries, and the file itself states that Nextcloud takes no admin
  credentials at all. The real finding was kept and fixed; the alarming half was
  withdrawn.
- **"No false alarm has fired yet on the backup window."** The retained history
  holds a `No heartbeat in the time window` beat for monitor 15 on 2026-09-13.
  The window had already fired once; its authenticity cannot be settled from
  retained data.

## Instrument traps paid on 2026-09-20/21 (eleventh run) — eight, and THREE were the main session's own

- **A gap between consecutive UP heartbeats swallows genuine outages.** The main
  session reported a Kuma window "already exceeded by 30 %" — false. Excluding
  spans that contain a DOWN beat is necessary but NOT sufficient: **retention
  prunes old DOWN beats, so an old outage still reads as an ordinary night.**
  Both corrections were needed. Name the incidents you exclude.
- **Comparing a masking result to the literal `***`** scores a PARTIALLY masked
  value as surviving. Test whether `sed` changed the string at all.
- **The main session propagated a false statement from `classes.md` into an agent
  brief as established fact** (`traefik` declaring no `start_period`; it has
  carried 240 s since #308). The agent caught it. Nothing grades these four files
  — no goss assertion, no script, no CI check reads `full-audit` — so the audit's
  only quality control over its own register is the audit.
- `/etc/apt/apt.conf.d/20auto-upgrades` matches neither `*periodic*` nor
  `*unattended*`, so a glob there reads as "the setting is absent". Ask
  `apt-config dump`.
- **`heartbeat.duration` returns 0 for all 22 active Kuma monitors** — a zero that
  looks like data. The real column is `ping`. And raw `heartbeat` retention is
  **~44 h, not the 180 d `keepDataPeriodDays` advertises**; amplitude must come
  from `stat_daily`.
- A `json-file` container log **survives a `restart` but not a recreate**, which
  invalidates any throughput figure computed across a deploy.
- **A commented-out line in a stock Ubuntu file is not live configuration.**
  Reading one as such nearly produced a false finding on the offsite reboot hour.
- **The host resolves through 1.1.1.1, not Pi-hole**, so split-DNS names do not
  resolve from the host itself. A functional probe from the host needs
  `--resolve`, or `curl` fails with rc=6 and it looks like a proxy fault.
---

## Shipped on 2026-09-20 (TENTH run) — key `substitution`, one PR, deployed from the branch before merge

Four commits, all verified against the running systems before the branch was
opened, each carrying the rule it encodes:

- **A tag whose stated purpose was rotation reached one carrier of two.**
  `--tags secrets` was documented in the role's own orchestrator as the way to
  write, **rotate** or re-mode a secret without a `compose up`. It reaches
  `secrets.yml` alone; four other task files render secret values behind other
  tags, one of them the WireGuard configuration. **Rule: a tag is a filter over
  tasks, never a statement about a VALUE. Before calling any subset of a deploy
  a rotation route, enumerate the value's carriers and check that the subset
  reaches all of them.** Corrected in the comment and in
  `rotate-a-secret.md`, whose consumer table named one consumer of two.
- **Nothing on the deploy path asserted that the encrypted volume was mounted.**
  The tasks that write credentials use only file-writing modules, so with the
  volume locked they write in clear onto the card at the mount point's path and
  report success; the next unlock hides the result under the mount. **Rule: a
  write whose destination is a mount point is a claim about the mount, and a
  module that cannot fail on an unmounted target will not make that claim for
  you.** An `assert` never reports `changed`, so the guard is silent on every
  correct run — which is what distinguishes it from the mtime comparator
  declined for C44, and the distinction was stated when it was proposed.
  Deliberately NOT placed in the role that runs before the volume is mounted on
  a full provisioning run.
- **restic skips a source that is not there and carries on.** The strings are in
  the installed binary; it aborts only when every target is gone, and the
  notification carries no byte, file or path count, so a smaller snapshot is
  indistinguishable from a good one. **Rule: a backup's report must be able to
  say that it backed up LESS than it was asked to.** The assertion added parses
  the deployed profile rather than a hand-kept list, and derives its own
  exemption the same way — a source that a hook deletes after a successful run
  is hook-managed and cannot be required to exist. **Without that derivation the
  check would have been red twenty-three hours a day**, which is the second time
  in this file that a correct-looking assertion was one measurement away from
  being a noise generator.
- **Five rationales refuted by what they cite or by the system they describe.**
  The expensive one opened a file arguing for a file mode, twenty lines above
  tasks declaring the opposite mode and a paragraph calling the argued-for mode
  "the thing that must never be tried again" after it took every database down
  twice. **Rule, and it is the second night running that it has cost something:
  a rationale is not evidence until someone re-reads what it rests on. When the
  rationale and the mechanism live in one file, they rot independently.**

### What was NOT shipped, and why — added 2026-09-20 (tenth run)

- **Widening the secret-mount comparison to the three uncovered credential
  files.** They are `volumes:` binds rather than `secrets:` entries, so they
  never appear at `/run/secrets/<name>` and the comparison path itself would
  have to change. Measured with zero mismatch and both consumers carrying
  restart handlers. **The risk of turning a working gate into a silent green is
  larger than the coverage gained**; re-raising needs a live divergence, not a
  tidier derivation.
- **Verifying the DDNS record by resolution.** Only the cardinality guard
  shipped. In an unattended timer an unreachable resolver reports the updater
  down while the updater is fine — the noisy shape declined repeatedly in this
  file. Verifying by function is right when a human is watching the output, and
  wrong as an unattended gate.

### Measured and rejected — added 2026-09-20 (tenth run)

- **"Four monitors have stopped reporting."** They are on weekly Tuesday timers
  and the beats land one to six minutes after each trigger; the appearance came
  from reading Kuma's UTC timestamps as local time. Killed independently by two
  domains, both with the trigger and next-fire times. **The lead was written
  into the agents' own briefs by the main session's baseline** — a baseline that
  flags something as suspicious manufactures the finding it then receives.
- **"Files are hidden under `/mnt/data`."** Nothing is. Seven directories dated
  10-May-2026, zero files, no secrets directory and no docker directory,
  verified behind the live mount with a positive control. The 2026-09-02 decline
  of this question stands as a decline; it simply now has an answer.

### The instrument that retires an intrusive measurement — 2026-09-20

`sudo debugfs -R "ls -l <path>" <device>` reads a filesystem **behind a live
mount, read-only**, without unmounting anything and without the bind mount that
made the same question intrusive when it was declined on 2026-09-02. Use it
whenever the question is "what is underneath this mount point".

### Instrument traps paid on 2026-09-20 (tenth run) — seven, all self-caught

- **`git log %cd` is the REBASE date in a rebase-only repository.** Any drift
  measured against it is fiction. Use `%ad`.
- **`docker compose config --hash` is not a drift oracle for a container sharing
  another's network namespace** — compose resolves it to `container:<id>` before
  hashing. The dry-run is the oracle.
- **`grep -oE "\$\{"` sent through an ssh double-quoted heredoc reports zero**:
  `\$` becomes a mid-pattern ERE anchor.
- **An un-`sudo`'d `[ -f ]` fails toward "absent"**, the same family as the glob
  trap — paid for the seventh time the same evening, with a new symptom: it
  reads as "the files are missing" rather than as an empty result. **Glob and
  privilege must share one shell.**
- **`docker exec … sqlite3 -cmd …` returns empty with exit 0.**
- **Probing service endpoints from the workstation needs `--resolve`**, or a
  healthy estate reads as a total outage.
- **`include`ing a PHP config returns 1, not the array**, and `ufw status | head
  -1` picks the wrong rule.

### How to sweep every column of a credential-bearing table without leaking it

An agent derived all 120 columns of the monitor table to find operator-set
values, and printed a basic-auth password and two push tokens into its own
transcript on the way. Nothing reached its report. **A derivation over every
column is exactly as dangerous as a verbatim paste, and the fix is the same one
the dump script already applies to its output: a credential-column denylist
applied BEFORE anything prints.**

---

## Shipped on 2026-09-20 (NINTH run) — key `interference`, one PR, deployed from the branch before merge

Three corrections, all verified against the running systems before the branch was
opened for merge, and each one carrying the rule it encodes:

- **A sentinel counted as data.** `journalctl` writes `-- No entries --` to
  **stdout**, so `2>/dev/null` does not remove it and `grep -c .` returns 1 on a
  loss-free day. Downstream, `date -d "--"` **does not fail** — it returns today's
  local midnight — so the check judged recovery against a fabricated loss and
  dropped 9 of 15 push monitors from its second clause. Keeping only
  timestamp-shaped lines is immune to the sentinel's wording. **Rule: a command
  that prints a human-readable "nothing here" on stdout is not a silent command,
  and `2>/dev/null` is not a filter for it.** Second rule, from the same line:
  **`date -d` accepts far more than it should — validate what you pass it, or
  check that the result is not suspiciously round.**
- **A redactor and the assertion that grades it, both blind in the same
  direction.** Both anchored on `[?&]`, so neither could see a credential carried
  in a PATH; Uptime Kuma puts its push token there. 1 283 lines in 24 h held a
  live token in clear while the assertion reported `bad=0`. **Rule: when a
  detector and the thing it grades share an expression, they share its blind
  spot, and the verdict cannot reveal it.** The masking pass added is
  deliberately one known path rather than a generic token-shaped-segment rule —
  over-redacting a query value costs nothing, over-redacting a path would stop
  the log from saying which endpoint was called.
- **Six writes per deploy reporting no change.** Nextcloud's external-storage
  options were re-applied unconditionally under `changed_when: false`. **Rule:
  `changed_when: false` is a claim that the task cannot change anything, not a
  way to keep a recap quiet; if the task writes, the report must be able to say
  so.** The guard uses the listing the loop already consumes, and accepts both
  `"1"` and `true` because the value arrives as a string — a future version
  emitting the other form would otherwise re-run the task every deploy and
  report a change each time, which is the same defect inverted.

### Shipped in the evening — the journal store left the unencrypted card

The last piece of "nothing sensitive on the SD card", done with the operator
physically at the machine and **validated by a real reboot**.

- **The journal now lives on the encrypted volume.** `Storage=auto` plus a bind
  mount created by systemd when the volume appears, plus a oneshot running
  `journalctl --flush`, both pulled by `mnt-data.mount.wants` — the pattern three
  other units already use. **Nothing in the boot path waits for the volume**, and
  `systemd-journal-flush.service` is untouched: if the volume never mounts the
  journal stays volatile and the machine boots normally.
- **The reboot proved the part that mattered.** Kernel up 15:43:37, volume
  unlocked 15:46:26, and the first entry of that boot reads 15:42:10 — the
  pre-unlock window was held in RAM and recovered. 9 boots still readable, 547 MB
  in the store, no volatile residue, `/` down to 18 %.
- **`journalctl` without sudo still works**, against the prediction: `mv`
  preserved the per-file ACLs across filesystems.
- **An assertion guards the one procedure that silently undoes it.** A reflash
  and re-provision gives back a distribution that creates `/var/log/journal` on
  the card; `Storage=auto` writes there until the unlock and the bind mount then
  HIDES those files instead of removing them. `journal-store-is-on-the-encrypted-volume`
  requires a mount point AND the encrypted source, and was made to fail on
  purpose against real paths in four directions.

**The rule this shipped, and it is the expensive one: a rationale that cites a
document is not evidence until someone reads that document.** The comment in
`logging.yml` kept 560 MB of command lines on an unencrypted card by asserting
that the poweroff runbook needs them. The runbook says the journal "proves
nothing" *because* it is on the SD. **A false rationale blocked a real security
fix for months, and the only thing missing was putting two sentences side by
side.** That is why C34 reopens: it was swept over the 20 service pages, a space
bounded by a directory, while the property covers any artefact citing a sibling —
including a code comment.

### Shipped later the same day — the log stores, after the operator ordered a second sweep

- **`auth.log` and `sudo.log` rotate DAILY and their rotated copy is MASKED.**
  Same four-week window as before, moved together; the clear-text window goes
  from five weeks to twenty-four hours. The rule is any run of 32+ characters
  from `[A-Za-z0-9_]`, measured before shipping against both known shapes. **The
  hyphen is deliberately out of the class** — with it, goss assertion names were
  masked too. Taking `auth.log` out of the distribution's stanza means owning
  `/etc/logrotate.d/rsyslog`; the other five paths are reproduced verbatim.
- **The already-written files were masked in place**, owner and mode preserved:
  0 occurrences of the live value afterwards, against 1 before, with 22 359
  masks applied and all 142 171 lines still present. **The offsite host was NOT
  touched** — independently re-measured clean (75 513 lines, 0 credential-header
  shapes), and a history rewrite with nothing to remove is a write for nothing.
- **The Cloudflare token was rotated**, and verified by FUNCTION rather than by
  state: `/user/tokens/verify` returned `success=true status=active`, the zone
  lookup returned 1 zone, and an invalid token returned `success=false` as the
  discriminating control. The new value appears in no log, with a positive
  control proving the search works. **`DNS:Edit` is declared but not exercised**
  — proving it needs a real TXT write; the 21-day certificate watch is the net
  that makes that acceptable.

**Closed out at 14:44 the same day.** Both consumers were aligned on the new
value at 14:16, the SCHEDULED DDNS run of 14:30:02 was verified end to end
(`LastTriggerUSec` read beside `Result`, so a hand-run could not be mistaken for
it: zone lookup OK, `unchanged (…)`, Kuma UP at 14:30:08), and the operator then
revoked every older token. **Exactly one Cloudflare token now exists and both
consumers read it from one vault variable**, which is what removes the cause
rather than the symptom — a future rotation can no longer reach one consumer and
miss the other.

**Rule the rotation produced, and it is the one that nearly cost remote access:
before revoking a credential, enumerate its CONSUMERS, not its carriers.** Three
Cloudflare tokens were live; the DDNS held one the September rotation had never
replaced, and the DDNS keeps the `vpn` A record that is the WireGuard endpoint,
which is the only route to the Pi. Revoking from the dashboard by name had a
one-in-two chance of costing remote access at the next public-IP change.

### Instrument traps paid on 2026-09-20, second batch — two, and BOTH were the main session's

- **A shape search anchored on CONTEXT that the occurrence does not have returns
  zero, with working positive controls, and looks like proof of absence.** The
  main session twice failed to reproduce a real Cloudflare token leak: once
  searching for the token beside the word `cloudflare`, once beside a
  `CF_`/`API_TOKEN` variable name. Both controls passed — the words matched 29,
  113, 10 and 96 times — so the instrument was demonstrably reading the right
  files and hunting the wrong thing. The occurrences are a **bare argument** to
  `grep -qF`, with no name and no vendor word on the line. **Only a literal-value
  search settles a question about a specific value**; a shape search can support
  a negative only when the shape is the whole claim.
- **`sudo`'s logfile WRAPS long command lines**, and the wrap can fall between a
  header and its value: `X-Api-Key: <32 hex>` returns 17 in `auth.log` and **0**
  in `sudo.log` for the same 17 events. Any sweep that requires a marker and its
  value on one line under-reports `sudo.log`.

### How to verify a secret WITHOUT creating the leak you are checking for

The Cloudflare token reached the journal through `sudo grep -qF <token> <file>`
run during the audit of 2026-09-12 — **the audit created the exposure it later
found**. The rule existed for deployed scripts (C26) and had never been written
for ad-hoc commands. It is now:

- Never put a secret value in argv. `sudo` records the command line in
  `auth.log`, in `sudo.log` and in the journal's `_CMDLINE`, and only the first
  two can ever be masked.
- To search for a value: write it to a file (`/dev/shm`, `umask 077`, shredded by
  a trap), then `grep -F -f <file>`. Only the FILENAME reaches argv.
- To send the whole script over SSH: `ssh host 'sudo sh -s' <<'EOF'`. `sudo` then
  records `sh -s` and nothing else; the script and the value travel on stdin.
- To call an API with a token: `curl --config <file>` holding
  `header = "Authorization: Bearer ..."`. `-H` puts the token in argv and
  therefore in `/proc` and in the journal.
- Never print a value, not even truncated, and not even to date a hit. The sweep
  agent disclosed printing 12 and 8 characters of two credentials into its own
  transcript while doing exactly that.

### DECLINED on 2026-09-20 (ninth run) — do not re-propose

- **Rotating the three `*arr` API keys.** They were found in clear in
  `auth.log.1` (0640 syslog:adm, readable without root) and remain in the
  systemd journal for ~24 days; the flat files were masked on 2026-09-20 but the
  journal cannot be. **Operator: "je ne veux pas faire de rotation de ces clés :
  l'enjeu est trop faible." Never re-propose it.** The judgement is supported by
  the measurements: the keys are usable only from the LAN or the tunnel, no
  monitor, no posture assertion and no script outside the three applications
  consumes them, and the whole dependency graph is 3 keys and 4 entries living
  inside Radarr, Sonarr and Prowlarr. **The consumer enumeration was done before
  the decline and is recorded here so that nobody redoes it**: Prowlarr's key
  sits in one indexer entry in each of Radarr and Sonarr; Radarr's and Sonarr's
  keys sit in Prowlarr's `Applications` table; Kuma's three monitors are
  keyword probes on the login page and carry no key.
- **Sonarr's re-creation of the leak, by consequence.** Sonarr writes Prowlarr's
  key into its own container log on each HTTP error, about once a day. It has no
  clean remedy — the behaviour is upstream and Docker captures the stream, so
  there is no insertion point for a redactor of the kind Traefik has. The log
  lives on the ENCRYPTED volume, so it is outside the "nothing sensitive on the
  SD card" rule; the residual exposure is Dozzle, which is authenticated.
  Recorded as an accepted risk following the decline above.

- **fail2ban's `ignoreip` names the host's own address rather than the address
  that authenticates to it.** Measured on both hosts with an argv-safe pattern:
  offsite ignores its own LAN address and **423/423** authentications arrive from
  the tunnel; homelab ignores its own and **4507/4507** arrive from the
  workstation. `maxretry=3`, `findtime=600`, `bantime=3600`. **Operator: with
  key-only authentication and no password path, a repeated refusal means the key
  is wrong, and then the ban changes nothing about what has to be done — the key
  has to be reloaded either way.** The argument holds and the numbers support it:
  0 failures and 0 bans on both hosts since installation. Do not re-propose an
  `ignoreip` change, in any form.
  **The one residual, recorded because it is NOT what was declined**: `MaxAuthTries`
  is 3 on both hosts and the workstation's client runs `IdentitiesOnly no`, so a
  future agent holding three or more keys could be refused **with a valid key**
  and ban itself for an hour. The agent currently holds one. The remedy is one
  line in the operator's own `~/.ssh/config` (`IdentitiesOnly yes`), outside this
  repository, and it removes the trigger rather than the consequence.
- **C29's vacuous liveness half, re-found and re-declined.** An agent minted it
  as a new class; it is the instance the operator declined on 2026-09-02. The
  generalised property was kept as half of C119 **solely to stop a tenth
  rediscovery**; the remedy (`pgrep -x awk`) stays declined.

### Measured and rejected — added 2026-09-20 (ninth run)

- **"A fail2ban ban would cut the offsite backup path."** No. The `nftables`
  action is `type = multiport` on the SSH port alone and `rest-server` listens on
  `*:8000`; `bantime` is 3600 with no increment. The ban costs an hour of admin
  SSH and nothing else.
- **"The purge of the leaked access-log lines has to be performed."** It did not:
  recreating `traefik-log-redactor` during the deploy destroyed the old
  container's json log with it. Verified after the fact — **0 files under the
  Docker data root hold a `/api/push/<token>`, against a positive control of 1
  holding the masked form**, and the container directory count equals the
  container count, so no orphan log survived. The operator had authorised the
  write; it was not needed and was not made.

### Instrument traps paid on 2026-09-20 (ninth run) — three, and TWO were the main session's own

- **`systemctl show -p A -p B --value` does not return the values in the order
  asked.** systemd prints them in its own order, so positional parsing transposes
  fields silently. The symptom was a `LastTriggerUSec` dated tomorrow. Ask for one
  property per call, or drop `--value` and read `key=value`.
- **For a `oneshot` unit with several `ExecStart=` lines,
  `ExecMainStartTimestamp` dates only the LAST one.** It understated
  `homelab-backup.service` by 3 min 48 s in this run's own baseline. **Read
  `InactiveExitTimestamp` for a unit's span.**
- **Sixth payment of the un-`sudo`'d glob**, caught by its own positive control.

### The method note this run owes the next one

`interference` was applied to the audit itself and the numbers are in
`classes.md`: **~79 % of posture runs are produced by audits and deploys rather
than by the timer**, 91 % of the access log and 89.5 % of the journal are the
estate observing itself. The conclusion is not to observe less. It is that
**"the most recent verdict" is not evidence until you know who caused it** — read
`LastTriggerUSec`, compare the verdict's timestamp to the mtime of what it
graded, and say which run you are quoting.

---

## Shipped on 2026-09-20 (EIGHTH run) — key `independence`. DOCUMENTATION ONLY

The operator declined every mechanism this run proposed and asked for one thing:
"s'il y a des erreurs dans la doc corrige les". What shipped, and the rule each
one encodes:

- **ADR-010's blast-radius claim was false and now says so.** "Homelab repo
  password is useless against the offsite repo, and vice versa" became "two
  distinct values, so neither is derivable from the other. NOT a blast-radius
  guarantee", with the reasoning below the table and a cross-reference to the
  LUKS header runbook, which already argues the identical circular dependency
  for a different secret. **Rule: when a second document already reasons about
  the same shape, point at it instead of re-deriving it.** The table was
  re-aligned (all rows 198 chars).
- **A verification step that verified nothing.** `kill-switch.md` told the
  reader to run `journalctl -u killswitch.service` and look for "armed". That
  command does not show the line at all, and the line is logged
  unconditionally before the first connection is attempted. Replaced with
  `journalctl -t killswitch` plus an `ss` check for an established socket, and
  a paragraph saying plainly which of the three commands proves anything.
  **Rule: a verification step must be able to fail; if you cannot say what
  makes it print something different, it is decoration.**
- **A comment whose numerator stood still while its denominator grew.**
  `homelab-health.sh.j2:379` said Kuma watches "15 of the 18 certificates.
  Three are unwatched". Live: 21 certificates, still 15 watched, **six**
  unwatched — the three `*arr` services arrived with `expiry_notification=0`
  and nothing moved the watched count. **Rule: a coverage statement written as
  "N of M" rots from the M end, silently, and the gap widens without the
  sentence changing.**
- **Five self-contradictions in `classes.md`**, one of which was the previous
  night's fix for the same defect. Detail in the register's eighth-run section.

### DECLINED on 2026-09-20 — do not re-propose, any of these, ever

All five were put with measurements and all five were arbitrated by the
operator the same day. Three of them became DECLINED classes (C116, C117, C118)
rather than being dropped, so the mint count stays honest.

- **The alerting path that terminates inside uptime-kuma (C116).** Netdata has
  no recipient of its own; Kuma is the only channel; a Kuma failure silences
  the alarm about Kuma, the 15 push reporters, both gated fuses and the single
  Discord notification. Remedy offered was a netdata-native Discord recipient
  for one alarm. **Operator: "je m'en fiche complètement, note de ne plus jamais
  me parler de ça." NEVER RAISE ALERTING-PATH COUPLING AGAIN**, in any form, in
  any run, however new the evidence.
- **The two restic passwords sharing a fate (C117).** **Operator: accepted
  risk, an independent offline copy exists outside the estate. Never raise
  again.** **PUBLIC-REPO RULE, ABSOLUTE: never write in the repository — or in
  any issue, PR, commit message or published text — that the operator holds
  these passwords offline, nor by what means.** Recommending the practice in
  the abstract is permitted and was done in ADR-010; stating that it has been
  done is not.
- **The guard/fallback chain, `ssh_port_hardened: 22` (C118).** **Operator:
  what matters is coherence, and if the fallback fired everything would move
  to 22 coherently; a port is weak security anyway and not worth panicking
  over.** The argument is sound — the failure mode is an access annoyance, not
  a hole. Do not re-propose deleting the five committed fallbacks.
- **Deny-direction assertions (C113's remedies).** **Operator: "je ne trouve
  pas ça très pertinent."** This retires the two remedies the seventh run left
  unshipped (`vpn-only`, `dns.blocking.active`) and everything the eighth run's
  sweep found — the 11 assertions that stay green, and the three uncovered
  controls (`DOCKER-USER` DROPs, `killswitch.service`, the USB tamper flag).
  The 2-of-197 figure may be cited as context by a later run. It may not be
  cited as a proposal.
- **The mtime comparator for C44.** A real and simple remedy —
  `mtime(file) < start(daemon)`, six lines, one rule for sixteen subsystems —
  **declined because it would fire on every legitimate edit-without-restart**,
  and a noisy check gets ignored. **What replaced it is one sentence of
  documentation**: the four comparators check that the deploy applied what the
  repo declares, and do not detect an external writer. Do not propose this rule
  or any successor without a live drift to point at.
- **The 10 h 54 min posture-grading window.** **Operator: it resolves itself,
  11 hours is acceptable.** Do not propose a `systemd.path` trigger, or any
  other way to grade a freshly deployed spec sooner.

### The rule-7 violation of 2026-09-20 — committed by the session enforcing it, and a 7-day-old exposure it uncovered

**The main session wrote the vaulted SSH port into `classes.md` three times**
while recording C44's evidence and C118's row — into a file tracked in a PUBLIC
repository, hours after writing rule 7 ("never propose writing a secret or a
port number into the repo") into all eight agent briefs. Caught by its own
post-edit diff check, redacted to `<vaulted>` before any commit. **The lesson is
not "be careful": it is that verbatim command output is the highest-risk text an
audit produces, because its value is precisely that it was not paraphrased.**
Grep the diff for the vaulted values before every commit, not after.

**The check that caught it also found the port had already been public for seven
days.** Two occurrences predating this run, both introduced by commit `ed430df`
(2026-09-13, itself an audit-run commit): `classes.md:3380` and
`ansible/inventory/host_vars/homelab/main.yml:23`, both in a comment recording a
port-reachability test. **Left in place, not redacted** — the value is already in
public git history, so editing the working tree does not unpublish it and would
only hide the exposure from the next audit. **Raised to the operator as a
decision: rotate the port, or accept it and drop the pretence that it is
secret.** Note the tension to resolve either way:
`security/meta/argument_specs.yml:16` marks it `no_log: true` with the
description "the port is deliberately not published", and `group_vars/all.yml`
argues the same in prose.

### Instrument traps paid on 2026-09-20 — six, and THREE were the main session's own

- **A false GAP, new in direction** — three previous runs produced a false
  CLEAN. `ExecMainExitTimestamp` read while a unit is mid-run looks exactly
  like a unit that never ran. Read `LoadState` and `ExecMainStartTimestamp`.
- **A partial read of a multi-line block is a false negative with no symptom.**
  A `source:` list read to line 215 of a block ending at 241 produced a
  confident contradiction of a correct agent. Read to the end of the block.
- **A wrong path returns zero, and zero looks like data.** Paid twice in one
  run by the main session, on a netdata config and on `acme.json`
  (`/mnt/data/services/traefik/acme.json` does not exist; the file is one level
  down under `acme/`, and it holds 21 certificates, not 0). Both were caught by
  adding a control; neither would have been caught without one.
- **FIFTH payment of the un-`sudo`'d glob**, this time with a new symptom: read
  through one, every netdata plugin reads `serves=false`, which is
  indistinguishable from healthy rather than obviously empty.
- **NEVER run `udevadm test` on a USB device path.** If a `RUN+=` rule fires,
  the Pi powers off and recovery needs physical presence.
- **`journalctl -u <unit>` drops `logger` output that `journalctl -t <tag>`
  shows.** Cost the kill-switch runbook a verification command that printed
  nothing for an unknown length of time.

---

## Shipped on 2026-09-19/20 (SEVENTH run) — key `asymmetry`, one PR, deployed from the branch before merge

The operator asked for everything in a single PR. What shipped, and the rule
each one encodes:

- **The direction a month of documentary sweeps had never measured.** Every one
  of them verified `{what the docs name} subset-of {what exists}`. **Rule: an
  inclusion measured in one direction is half a measurement — ask which set is
  derivable from the machine, and sweep it the other way.** It produced the
  three missing secrets, the five wg-easy sites, a monthly prune job documented
  nowhere, three ADR citations pointing at the wrong ADR, and five stale tables.
- **A detector that sampled a <=2 s pulse once a day.** The premise "the
  firmware latches undervoltage into the rpi_volt hwmon alarm" is false and it
  was written in FOUR templates, carrying the cadence in two of them. **Rule:
  when a comment states the physical property that justifies a cadence, verify
  the property — and verify it in the artefact you actually run**, which here
  meant reading both driver strings out of the shipped module binary rather
  than trusting upstream source.
- **An exclusion whose premise was checked in one direction only.** "Every byte
  of it is a second copy" was true of the ingestion and false of the inventory:
  five files, one of them a whole book, existed only inside an excluded
  archive. **Rule: an exclusion is a claim about a set difference, so measure
  the difference, not the process that was supposed to produce it.** The
  replacement lists the siblings rather than the parent, so a staging directory
  invented later fails toward being backed up.
- **C07 widened by a derivation with no hand-chosen constant**, and the
  collector it found on its first run. **Rule: when a floor cannot be keyed on
  the axis you tried, try another axis before accepting a literal** — the
  context axis is not a function, the plugin axis is. `cgroups.plugin` went from
  1002 samples/s with zero consumers to 200.4. Deployed and green.
- **Where a document repeats what the machine already knows, it now prints the
  command that regenerates it** rather than a day and an hour. Two files had
  contradicted themselves seventy lines apart on the same cadence.

### Declined or recorded without a remedy this run

- **Transmission's intermittent 404s. DECLINED by the operator**, who identified
  the load as Transmission downloading — a better explanation than the
  audit-load hypothesis the session was carrying. The mechanism is real and
  worth remembering: a 5 s healthcheck timeout under contention makes Traefik
  drop the router, and the estate cannot see it (alarm needs `min -10m` against
  an actuator acting in seconds; the monitor goes PENDING, which escalates with
  the wrong text). **Do not re-propose lengthening the probe timeout.**
- **C113's two remedies** (an assertion in the deny direction for `vpn-only`,
  and one for `dns.blocking.active`) were NOT shipped. Not declined — not put.
- **C115's 19 restore procedures** carry no expected result. Not shipped; the
  remedy is documentary, and the operator has already declined timed restore
  drills, so do not bundle the two.
- **Nothing observes that a fail2ban filter still MATCHES.** `security` declined
  to propose anything: the only honest check needs a deliberate authentication
  failure, which the operator declined, and a frozen sample would be
  self-certifying. **Recorded so the next run does not re-derive it.**

### Instrument traps paid, both by the main session

- **An un-`sudo`'d glob over a root-only directory expands to nothing — FOURTH
  payment**, this time by the session whose own brief carried the warning.
- **A positive control inside the instrument's horizon proves nothing about its
  reach.** NEW IN KIND. Docker's event buffer goes back 2 min 30 s; a control
  taken inside that window proved only that the instrument works NOW, and a
  "zero events" reading nearly became a conclusion about a question 45 minutes
  old. **A control must be comparable to the question in the dimension that
  matters — here age, not validity.**

---

## Shipped on 2026-09-19 (SIXTH run) — key `oracle`, one PR, deployed from the branch before merge

The operator answered all eight findings and asked for a single PR. What shipped,
and the rule each one encodes:

- **`logtimezone = UTC` removed from the vaultwarden jail.** Commit `8763306`
  that morning had put the container on CEST, and the directive's own comment
  stated the premise it had just lost: *"its container runs on UTC while this
  host runs on CEST"*. **Rule: when you correct a defect, grep for the arguments
  that were resting on it** — that is C52's property, and its sweep had been
  bounded to `arguments` while a live `directive` sat outside that bound.
- **A derived replacement for a frozen floor.** `netdata_min_contexts: 270`
  against a live 383 could not see an entire collector die. The new check reads
  the `on:` line of every installed curated alarm and asserts netdata still
  serves that context — no literal, no author to go absent. **Rule: when a
  literal has no author, look for the thing that CONSUMES it and derive the
  expectation from there.** The old floor stays as a coarse canary and is no
  longer load-bearing.
- **A functional check for `nextcloud-cron`**, the one container of 32 with no
  healthcheck, no monitor and no assertion. It asserts the age of Nextcloud's
  own `core lastcron`, not that a process is running. **Rule: a green container
  is not a working service.** The 3600 s threshold is the one hand-chosen number
  this run introduced and it is declared as such.
- **The observability monitor table**, which named a monitor that does not exist
  (`Pi services`), attributed the marginal-sector report to the wrong monitor,
  and said "three to create by hand" when there are five. A **"Fed by"** column
  was added so the table cannot read as coverage again. **Rule: an enumeration
  that puts a watched thing next to an unwatched one reads as coverage** — the
  #201 shape, third appearance.
- **ADR-010's cadence and scope.** It said the offsite push is *weekly* and that
  the Pi *only* self-reports disk health; it is daily since 2026-09-12 and the
  spec carries 33 named checks including `append-only`. **A recovery reader
  would have accepted a 7-day silence as normal.** The count was deliberately
  NOT written into the ADR — it names the file instead, per this file's own rule
  about regenerating numbers rather than freezing them.
- **CI now runs the repository's own checks.** `lint.yml` claimed to mirror the
  pre-commit hooks and ran 1 of 10. All nine `ops/check-*.py` entry points plus
  the three selftests now run on every PR. **Rule: a gate that only runs on the
  developer's machine is not a gate** — and `--no-verify` is this repo's own
  documented GPG-timeout remedy.
- **Dozzle's doc version**, `v10.6.14` -> `v11.1.0`, inside a command meant to be
  pasted. `v11.1.0` confirmed latest upstream; the compose↔host gap was a pending
  pin and was deployed.
- **The register's own contradictions**, corrected: C107's minting row still read
  NOT BOUNDED after its closure, C103's row still read OPEN, C31 carried 18/18
  against 21/21, C33 carried 104 links against 113, C20 carried "16 secret files"
  against 43-by-value in two places, and **C108, C109 and C110 had no table row at
  all** (`grep '^| C10[89] |'` returned 0 against a positive control of ≥1 for all
  107 others).

## Deployed and verified — 2026-09-19 (sixth run)

`ansible-playbook playbooks/site.yml --ask-vault-pass --tags security,observability,deploy -e deploy_services=dozzle`
— `ok=256 changed=5 failed=0`. Verified on the host afterwards, function rather
than status each time:

- `logtimezone` gone from `jail.local` (count 0, positive control: the
  `[vaultwarden]` block still present at 1, so the directive went and the jail
  did not).
- fail2ban loads **3 jails** — nextcloud, sshd, vaultwarden. Not "the service is
  active"; the jails are up.
- Dozzle reports **`v11.1.0`** from `/dozzle --version`, and declares it. The
  running binary, not the tag.
- Both new assertions present in the deployed spec, and a full posture run:
  **exit 0 in 42 s, `posture OK — 432 checks (goss 409, ...)`** against 406
  before. Each new check re-executed on its own, as root, from the DEPLOYED
  text rather than the draft: 6 contexts derived and present, exit 0; lastcron
  age within bound, exit 0.

**Idempotence VERIFIED, not assumed.** The operator re-ran the same line:
`ok=254 changed=0 failed=0`. The first pass was `ok=256 changed=5 skipped=48`,
the second `ok=254 changed=0 skipped=49` — two fewer tasks ran, which is
consistent with handlers that fire only on a change and did not fire on a clean
pass. **That reading was not verified task by task and is recorded as a reading,
not a measurement.** The number that matters is `changed=0`.

## What was NOT shipped, and why it is the run's best discipline result

**`ansible-deploy` proposed "~6 lines fix all 11" for the posture checks that
vanish with their declaration. The fix already exists in history and was
reverted.** `goss-posture.yaml.j2:548-560` records it: emitting the complement
for every service was tried on 2026-09-05 and is wrong, because `Config.User`
carries the IMAGE's user when compose declares none — socket-proxy returns
`root`, collabora returns `1001` — so asserting the complement writes upstream's
values into this repository. The template also says the gap does not close by
assertion anyway, because a service that loses its `user:` falls back to the
image's user and the running system is telling the truth.

**Rule, and it is this run's rule: read the code before proposing to change it.
This estate writes down why it did things, at the point where it did them.**

C111's real remedy is an **intent declaration separate from the configuration**
— the `declared intent vs effective state` pattern already shipped for sshd,
sysctl, postfix and ufw in #368. It is a design change, it was put to the
operator as such, and nothing was built on a guess.

## Measured and rejected — added 2026-09-19 (sixth run)

- **"60 netdata alarms evaluate and can reach nobody."** Measurement right,
  conclusion wrong. `group_vars/all.yml:308` states *"Netdata notifies NOBODY —
  stock alarms and curated ones alike"*, ADR-030 phase 1, with the Kuma adapter
  as the single channel and polling chosen deliberately so each monitor is a
  dead-man's switch. **Third time an agent has reported a written decision as a
  gap.** The residual worth keeping: the MEMBERSHIP of the curated six is a
  hand-written list with no revision event.
- **"9 alarm names / 187 instances are literally decorative."** They are
  intermediate calculation alarms consumed by sibling alarms — `disk_fill_rate`
  -> `disks.conf`, `load_cpu_number` -> `load.conf`, `1m_received_packets_rate`
  -> `net.conf`. They are exactly the alarms whose recipient is `root`, which is
  the tell that should have prompted the check.
- **"netdata's disk alarms watch neither `/` nor `/mnt/data`."** True and
  irrelevant: those alarms are not forwarded at all, and `homelab-health.sh:234`
  is `for fs in / /mnt/data` at threshold 85, with monitor 20's beat reading
  `/ 19%, /mnt/data 21%`. The script's own comment anticipates the objection.
- **"The marginal sector is reported by nothing."** It is reported daily by
  `homelab-disk.sh` (live beat `pending 2`), with a deliberate implementation
  referencing #207. The defect was the documentation naming the wrong monitor.
- **"11 of 32 containers are the subject of no monitor."** Cut to **1**:
  `homelab_container_down` and `homelab_container_unhealthy` each cover 32/32,
  and of the four containers with no healthcheck, three have a dedicated monitor
  or a daily assertion. Only `nextcloud-cron` was uncovered.

## Instrument traps paid on 2026-09-19 (sixth run) — four, and three were the main session's own

1. **A `grep -A<n>` context window is as wrong as a loose regex, and it fails
   silently in the direction of a clean result.** `-A4` on a 5-line block cut off
   exactly the `logtimezone` line under investigation and returned a false "not
   deployed". New in kind: the fifth run's version was an alternation, this one
   is a window.
2. **A positive control that itself returns zero is not a control.** `grep -c
   "title:"` over specs that do not use `title:` made a null result look
   negative. Re-run with `grep -c "command:"` (=1, file 192 290 bytes) it finally
   meant something.
3. **An awk keyed on the last-seen name bleeds across block boundaries.**
   Counting expectations by proximity gave "1 false + 2 true" per service —
   arithmetically impossible against one check per service. **An impossible
   total is the cheapest signal that a parser is straddling its unit.**

4. **An un-`sudo`'d glob over a root-only directory expands to nothing — paid
   for the THIRD time, and this time by the session that had written the warning
   into its own brief.** Verifying the new context check after deployment, the
   main session extracted the check body from the deployed spec and ran it as
   the normal user. `/mnt/data/services/netdata/health.d/` is root-only, the
   glob matched nothing, and the check reported *"no curated alarm declares a
   context"*. The conclusion "the deployed assertion fails" was wrong; goss runs
   it as root, where it derives all six contexts and exits 0.

   **The redeeming half, and it is the strongest evidence the check works: its
   empty-set floor caught the condition and failed loudly instead of passing
   vacuously.** A floor written to prevent a vacuous pass was made to fail on
   purpose by accident, which is a better proof than the deliberate controls
   that preceded it. **Rule already on file and evidently not yet learned:
   before believing a null result, ask what the instrument could read.**

## Shipped on 2026-09-19 (FIFTH run) — key `attendance`, one PR, deployed from the branch before merge

The operator answered all five findings put to them and asked for a single PR.
**Two were declined outright and are in `classes.md`'s DECLINED list.** What
shipped, and the rule each one encodes:

- **Uptime Kuma 2.5.0 -> 2.5.5.** It had sat in Renovate's "Pending Approval"
  list for **24 days**, and the package is the supervision itself. **Rule: a bot
  that rewrites its own dashboard every day destroys the only freshness signal
  that queue has** — issue #8's `updatedAt` was the day of the audit, dating the
  rewrite and never the wait. Bumped directly in `compose.yaml` rather than
  through the bot's branch, so the whole run stays in one PR.
- **The offsite deep check stops claiming a cadence.** The runbook heading said
  "quarterly, manual" and nothing ever implemented it: no timer, no unit, no
  trace, journal complete back to 2026-05-14. **Rule: a heading that states a
  cadence is a promise; if nothing implements it, the heading is the defect.**
  The scheduled check is metadata-only **by written design** — that part is not
  a gap and was requalified before it reached the operator. Automating the deep
  read stays next to the declined restore drill.
- **The Nextcloud app counter was NOT shipped, and the reason is the run's best
  finding.** See below.
- **Six self-contradictions in the register**, corrected — and the failure mode
  is identical to the fourth run's: **cardinal corrections get written into the
  run narration and never reach the tables.** The worst was C44, the register's
  only OPEN class, sitting in the ENUMERATED table with a stale cardinal and
  without the "left this table" pointer its peers carry.

## The Nextcloud app counter — declined by measurement, 2026-09-19 (fifth run)

The operator chose "a counter in the existing beat" to close the app-update gap.
**Implementing it proved the counter would have published a permanent, green,
meaningless value**, and stopping to say so is the point of this file.

- `appstoreenabled` is **false**, set deliberately at
  `ansible/roles/deploy/tasks/nextcloud.yml:78` on 2026-09-18, for a measured
  reason: the nightly fetch failed with cURL 23 and wrote a 10.17 MB Guzzle
  trace into the very file the fail2ban `[nextcloud]` jail re-reads.
- Therefore `occ app:update --all --showonly` can **never** report an update.
  Its output — *"All apps are up-to-date or no updates could be found"* — is
  always the second clause. **Rule: when a tool names its own ambiguity in its
  output string, that string is not a measurement.**
- The repo's own comment excuses this with *"they are pinned in the image and
  the runbook updates them with occ"*. **False for exactly the two that
  matter**: `richdocuments` 11.1.1 and `libresign` 14.1.0 live in
  `custom_apps` — persisted on disk, not in the image — verified inside the
  container. ADR-022:179 had already recorded *"Renovate does not see this"*.
- `collabora.yml:80` runs `occ app:install richdocuments`, which needs the
  appstore that is now off: **a rebuild-from-scratch hazard**, not a running
  fault.

**Net: those two apps are updated by nothing and watched by nothing, and the
written mechanism that would excuse it does not apply to them.** The remedy is a
real decision, not a counter, and it was put back to the operator rather than
guessed at.

## Instrument traps paid on 2026-09-19 (fifth run) — seven, and two were the main session's own

1. **An alternation regex is only as precise as its loosest term.** The main
   session grepped `tamper|armed|disarm` and matched control-timer and fsck
   vocabulary, returning 6 where the strict answer is 0 — briefly contradicting
   an agent that was right.
2. **The main session broke its own rule 6**, running a `journalctl` over four
   months on a Pi carrying eight agents; it exceeded 120 s. The result was
   discarded and the evidence taken from the configuration instead.
3. **`git branch --no-merged` lies in a rebase-only repository.** It announced 10
   branches and 48 commits ahead; `git cherry` proved 48/48 already landed.
4. **`last -x reboot` is corrupted by the absent RTC.** Only lines cross-checked
   against `dpkg.log` are usable; real kernel latency measured at 1 h 11 and
   ~1.6 d, nowhere near the 14 d bound.
5. **netdata's light endpoints do not carry `update_every`** — 383/383 missing on
   `/api/v1|v2|v3/contexts`. No cheap route exists; it is `/api/v1/charts`,
   5.3 MB, 0.74 s.
6. **`grep -c " 429 "` over a CLF log overcounts 2.1x** — the trailing 429 is the
   request count, not the status. The anchored `'" 429 [0-9]+ '` gives 14 in
   17.7 days.
7. **`sudo grep /etc/goss/*.yaml` fails with "No such file"** — the glob resolves
   before `sudo`. Already on file; re-paid live.

## A rule-5 violation, self-declared — 2026-09-19 (fifth run)

`observability` wrote 5.3 MB into the netdata container's `/tmp`, removed it, and
re-derived the single result it could have biased. **It disclosed this
unprompted.** The main session re-measured the load-bearing conclusion after the
cleanup and it held. Recorded because the disclosure is the behaviour these
briefs are written to produce, not because the write did harm.

## Measured and rejected — added 2026-09-19 (fifth run)

- **The missing `--read-data` on the offsite check, as a gap.** It is a written,
  deliberate decision with its cost stated. Two agents framed it as an oversight
  before the main session read the profile verbatim. The documentation was the
  defect; the configuration was not.
- **`(context -> update_every)` as the basis for a C07 floor.** The fourth run
  recorded it as a FUNCTION and it is not: `disk.space` and `disk.inodes` each
  carry 1 and 5. **A per-plugin floor is the replacement** — 4 plugins over 100
  charts, red on exactly one member, against 1712 of 3838 charts for a naive
  `>= 5`.

## Shipped on 2026-09-19 (FOURTH run) — key `staleness`, one PR, deployed from the branch before merge

The operator answered all six findings and asked for one PR. What shipped, and
the rule each one encodes:

- **The firewall's deny-by-default is now asserted, on both hosts.** `ufw status`
  does not print the default policy; only `status verbose` does, and all three
  deployed ufw checks read `status`. **Rule: an instrument that omits a field
  cannot be the reader of that field, however loudly it reports the rest.**
  The offsite also gained the per-rule check it never received, derived from
  `ufw_service_rules` + `ssh_allowed_sources` rather than hand-listed.
  - **Trap paid writing it**: `ufw status verbose` renders the rule table
    differently — `ALLOW` becomes `ALLOW IN` — so switching the per-rule loop to
    verbose would have silently broken every SSH-source assertion, which matched
    `ALLOW +${src}`. The regex is now tolerant of both forms. **A format change
    in the columns you were not reading is the cheapest way to break a working
    check.**
- **Immich moved to v3.2.2 and Renovate can speak about it again.** The rule was
  `"enabled": false`, which is a correct manual-pin policy that ALSO suppressed
  security advisories — no channel in the estate could have reported a CVE. It
  now carries `groupName: null` + `dependencyDashboardApproval: true`, the same
  shape as the resticprofile/goss/rest-server rule. **Rule: switching a
  dependency off to stop it auto-updating also switches off the only thing that
  would have told you it must.** The DB image does NOT move — upstream v3.2.2
  expects `vectorchord0.4.3-pgvectors0.2.0`, which is what this estate already
  runs.
- **lynis's 41 suggestions now reach a human.** The "new since last run"
  comparison existed but lived only inside the regression branch; on the green
  path it never ran, and suggestions were never read at all. Both the warning-ID
  set and the suggestion-ID set are now compared on every path, a NEW warning
  gates, a new suggestion is named in the message, and the suggestion count rides
  in the beat so a frozen value is visible. **Rule: archiving a signal is not
  reading it.**
  - **Trap paid writing it**: the comparison must precede the `cp` that
    refreshes `last-green-report.dat`, or it compares the report to itself and
    finds nothing new, forever.
- **A gate for C108**, `containers-run-the-image-their-tag-designates`. It went
  red on the live estate before it was written down — `n=31`, naming exactly the
  two known divergences — which is stronger than a made-to-fail test against a
  fixture. Digest pins are skipped as structurally immune; an anti-vacuity floor
  guards the derivation.
- **The Kuma retention premise, corrected in all three live artefacts** — and the
  correction is the opposite of what both agents proposed. `keepDataPeriodDays`
  IS 180, so the sentence was true as configuration. What is false is the
  inference: heartbeat rows are pruned on a **per-monitor row budget**, measured
  at ~36 h for an ordinary beat on the 5-minute monitor, and the three assertions
  survive only because their monitor is weekly. **Rule: when a premise is true by
  accident, write down the accident.** The operator declined to extend retention
  — two months is enough.
- **The stale-cadence pass.** Eight statements still said "weekly" for the
  offsite health job that became DAILY on 2026-09-12. Corrected, including the
  8-day lookback cap whose comment claimed it was DERIVED from a weekly timer:
  the value is kept and now says it is conservative rather than derived, because
  narrowing it is a behaviour change and not a documentation fix.
- **`.claude/agents/observability.md` said "(10-min gate)"** for a 5-minute timer
  with 240 s gates. Wrong for 60 days, and the commit that morning had rewritten
  the other half of that same line while carrying the number across. **Rule: an
  edit to a line is not a check of the line.**

## Shipped on 2026-09-19 (third run) — key `aggregation`, PR #368, deployed from the branch before merge

The operator took all five items put to them and asked for one PR. What shipped,
and the rule each one encodes:

- **The floor is the DECLARED count, not zero — in all four consumers now.**
  `homelab-posture.sh` (400 assertions) and `homelab-health.sh` (9) compared the
  goss TAP plan line against nothing. The correction shipped the previous night to
  `backup-notify.sh` and `offsite-health.sh` had not travelled, **and
  `backup-notify.sh`'s own comment already claimed all four carried it** — so the
  fix makes the comment true rather than correcting it. Second recorded instance of
  a correction that stopped before its siblings.
- **A cached blocklist is not a fresh one.** On a failed download gravity parses
  the cached copy, records `adlist.status=3` and stamps `info.updated` with now, so
  a freshness check reading only the timestamp can never go red. `adlist.status` had
  zero readers anywhere in the estate, and nothing floored the domain count, with a
  single adlist carrying all 79 963 domains.
- **A name Traefik routes must resolve to the Pi.** The 21 split-DNS records were a
  hand-kept list; the new assertion derives the expected set from `compose.yaml`'s
  own `Host()` rules. A service added without a record resolves to the public IPv4
  where 80/443 are not forwarded — dead from LAN and VPN with every monitor green.
- **An empty list is not a permitted source.** `required: true` on a `type: list`
  bounds presence, not cardinality: `[]` validates with zero errors. The allow loop
  would add nothing while the retractions and `ufw enable` ran regardless.
- **A hardening nobody asserts is a hardening nobody keeps.** Nothing checked any of
  the 22 SSH directives continuously; the only standing signal was the weekly lynis
  index, which does not parse the suggestions where every SSH finding lands. The new
  check compares the managed file against what `sshd` actually applies, so a drop-in
  under `sshd_config.d` is covered too.

### Four declared-vs-effective comparators, added to the same PR and deployed 11:48

The operator asked for the `sshd` shape to be applied to the kernel, the firewall,
mail and the system services, **if it was useful and simple**. Three of the four
were; the fourth was not, and saying so was the right answer rather than shipping a
weaker version of it.

- **sysctl** — the 30 keys Ansible writes into `/etc/sysctl.d/99-homelab.conf`,
  against what the kernel holds. **Double-floored**: the parse must find as many
  keys as the file declares, because a pattern that silently stops matching shrinks
  the sweep without emptying it.
- **postfix** — the 22 directives of `main.cf` against `postconf -h`.
- **ufw** — every rule the inventory declares against `ufw status`, with the SSH
  port rendered from its variable and never written down.

**systemd was refused, with the reason recorded.** Comparing unit files to
`systemctl show` founders on normalisation (`TimeoutStartSec=600` reads back as
`10min`); asserting no unexpected drop-in needs a seven-entry exemption list, which
is a list dressed as a derivation. All seven live drop-ins were checked and all
seven ARE declared in the repository. **Six carry no `ansible_managed` marker
because they are deployed by `copy: content:` — the marker is not a provenance
instrument, and any future check that keys on it is already wrong.**

Deployed `--tags observability`: `ok=47 changed=1 failed=0`, the spec and nothing
else. Verified on the host: **plan 406 / 406 results / 0 failures**, the three new
checks passing at `ok 67`, `ok 282`, `ok 333`. Each was made to fail on purpose
first — a revoked key, a cancelled `inet_interfaces`, an absent rule as a negative
control — and the sysctl floor was exercised with an empty file.

**The Jinja trap this cost, worth carrying**: a `{%-` tag placed between two YAML
keys eats the newline that separates them, and the spec rendered
`exit-status: 0  next-key:` on one line. `ops/check-goss-specs-render.py` caught it
before the commit, which is exactly what that gate is for. Put `{% set %}` blocks
where their whitespace cannot join two keys.

### What the deploy produced, measured 2026-09-19 11:20

`ok=100 changed=3 failed=0` on homelab — exactly the three modified files, nothing
else. Verified on the host rather than from the recap: both guards present at
`homelab-posture.sh:188` and `homelab-health.sh:584`; the three assertions at
`/etc/goss/posture.yaml:2050,2393,2437`; and the full spec re-run gives
**plan 403 / 403 results / 0 failures**, with the three new checks passing as
`ok 203`, `ok 240`, `ok 305`. The plan moved 400 -> 403, which is the quantity the
new guard compares, so it is working on real data.

**Every new assertion was made to fail on purpose before being written**, which is
the rule this file adopted after a gate proven against a fixture turned out to be
proven against the fixture's model of the world. The sshd check was run against a
fabricated config on the host: a revoked `PermitRootLogin`/`PasswordAuthentication`
pair is named in the message, a conforming config passes, an empty file trips the
floor. The gravity check's failure branch was demonstrated read-only by widening
the predicate to the status the live list actually holds.

### Deployed with `--tags security,observability`, and why that matters

Those tags do not invoke the `deploy` role, so `compose.yaml` is not copied and
**no pending image pin is armed**. Four were pending on the day: dozzle
11.0.1 -> 11.1.0, forgejo 16.0.4 -> 16.0.5, and the two Nextcloud sidecars running
a base layer four days behind the tag they share with `nextcloud`.

## Instrument traps paid on 2026-09-19 (third run) — five, and three were the main session's own

- **A `grep` run under `sudo` writes into the log the string it is searching for.**
  It cost two conclusions in one run. One was relayed to the operator as a possible
  unexplained `ufw reload`; the operator confirmed it was not them, and it was not
  anyone — the 10:28 entry WAS the search. A `sed` rewriting the matched tail into
  `COMMAND=ufw reload` made the record indistinguishable from the real thing. The
  same artefact killed the A15 resolution, which claimed two reloads on 2026-09-13
  that never happened. **Never count occurrences of a command string in `auth.log`
  without excluding the searching process's own record.**
- **`systemctl show -p Result --value` returns `success` for a unit that does not
  exist** — paid again, live, in the audit's own opening baseline.
- **`Result` cannot distinguish scheduled from manual either.** Read
  `systemctl show <unit>.timer -p LastTriggerUSec` beside `ExecMainStartTimestamp`.
  Two consecutive runs have now opened on a false clean built from a hand-run.
- **A grep pattern narrower than the code it hunts.** `_total\|_seen` found nothing
  in the offsite script, whose variables are `total` and `seen` unprefixed; it nearly
  contradicted a correct agent. Read the block, not the pattern's verdict.
- **A `docker inspect --format` range that returns 0 silently**, and a Traefik API
  `curl` that returned 0 routers with no control. In both cases the main session's
  own figure was discarded rather than used to contradict an agent.

## Open decisions left with the operator on 2026-09-19 (third run)

Not declined — put to them and not yet answered. Do not treat as settled either way.

- ~~Widening `ops/check-empty-set-floors.py` to Ansible tasks.~~ **APPROVED and
  SHIPPED in #368.** The gate now reaches `loop:`/`with_items:` whose source is a
  variable or expression. **`| default([])` is explicitly not a floor** — it turns
  "undefined" into "iterate nothing", the defect wearing a seatbelt.

  **The unit for Ansible is the file up to the loop, not a fixed window, and the
  reason is semantic**: a task file is a sequential play, so an earlier assert
  really does gate what follows, while a shell guard may sit in a branch that was
  not taken. `check_shell` keeps its window for that reason.

  Five controls added; the selftest discriminates in both directions, and the
  decisive check is that the gate flags `firewall.yml` **as it stood that morning**.
  Run over the repository it leaves **seven** sites, and the useful finding is that
  **every one already had a floor — living in another file, in a ternary, or in the
  option's designed-empty state.** The repository was right; it had simply never
  recorded WHERE the floors were. Each now says so. No behaviour change, no deploy.

  **Trap paid writing it**: `\s` crosses the newline in a MULTILINE regex, so
  `loop:` followed by a block list was read as an inline source and every such loop
  was flagged on the variable inside its FIRST ITEM. The tell was a finding on
  `ssh_port_hardened`, which is a port and not a list. **An implausible subject is
  the cheapest signal that a pattern is matching the wrong thing.**
- **Whether the three new assertions should carry explanatory comments.** The
  operator's standing rule forbids writing comments without explicit authorisation;
  this repository otherwise explains its reasoning directly above the code. The
  reasoning currently lives in the failure messages and the commit messages.
- ~~The proposed mint.~~ **ACCEPTED as C107 on 2026-09-19.** See `classes.md` for the
  property and the bound worth trying. Note for the next run: bounding it by
  ASSERTION is what defeated the minting run; bound it by INSTRUMENT instead.

## Shipped on 2026-09-19 (second run) — key `commensurability`, one PR, deployed from the branch before merge

The operator took four lots of five and asked for one PR. What shipped, and the
rule each one now encodes:

- **No tag selection can ship a service the posture checks have never heard of.**
  The spec render, its parent directory and the Tier 0 assert are `tags: always`.
  The spec is generated from `docker/compose.yaml` by the `observability` role
  while `deploy` ships that file, and **nothing on the host reads `compose.yaml` at
  run time** — the host-side mentions are comments and frozen constants, which is
  what makes the generation the only link. Cost of the trade, stated to the
  operator and accepted: the render now runs on light deploys too, `--tags ddns`
  included.
- **A green Ansible run is not evidence that a passphrase rotated.**
  `community.crypto.luks_device` with `state: opened` returns `ok` for an
  already-open volume — it never opens the device, so it never validates what it
  was handed. The rotation runbook now carries the LUKS procedure in the restic
  order: add the keyslot, prove it with `cryptsetup luksOpen --test-passphrase`
  (works while mounted), re-take the header backup, deploy, and only kill the old
  slot after an ATTENDED unlock. `wg_password` got its own row: nothing in the
  deploy ever sets it.
- **An assertion that matches on message text must fail closed when the text stops
  identifying one reporter.** `restic-deep-check-not-stale` took `max(time)` over
  every monitor's messages matching `'%deep check%'`.
- **The floor is the DECLARED count, not zero.** `backup-notify.sh` and
  `offsite-health.sh` now compare the TAP plan line against the number of result
  lines. The corrected form already existed at `homelab-health.sh:747` and had not
  travelled to its two siblings.
- **A container that writes timestamps must be told the host's timezone.**
  `vaultwarden` had no `TZ`, wrote UTC on a CEST host, and fail2ban's own remedy —
  re-stamping entries to *now* — turned `findtime = 600` into "3 failures since the
  last restart".
- **The agent instruction files are in C01's space from now on.** They had never
  been, and they are what every session reads first. Corrected by REMOVING counts
  and stale references rather than updating them — the same move the ADR count got.

### What the deploy produced, measured 2026-09-19 01:57-02:08

`ok=202 changed=6 failed=0` on homelab. Verified on the host, not assumed:
`/etc/goss/posture.yaml` re-rendered at 01:57:43; the new guard present at
`:2173`; `backup-notify.sh` carrying the comparison at `:187`; `vaultwarden`
reporting `2026-09-19 02:08:04 CEST +0200` against a host second-for-second
identical, with `TZ=Europe/Paris` in its environment. The regenerated spec
validates **400 plan / 400 results / 0 failures**.

**Both new clauses were made to fail on purpose.** A TAP with plan 3, one result
and zero `not ok` is caught as "the run was cut short"; a complete plan-3 TAP stays
green. The deep-check guard reports one distinct reporter and proceeds, 12 days
against a 45-day threshold.

### A deploy-time trap worth carrying

Deploying `compose.yaml` ARMS every pending image pin for the heal timer even when
the `compose up` is scoped to one service. This run armed dozzle 11.0.1 -> 11.1.0
and forgejo 16.0.4 -> 16.0.5, both from an already-merged Renovate PR that had
never been applied. Neither applied on the day — the containers were 6 and 7 days
old after the deploy — but they will on the next recreate. **Check
`repo image pin vs running image` before any deploy that copies `compose.yaml`, and
tell the operator what the deploy arms.**

## Instrument traps paid on 2026-09-19 (second run) — four, and two were the main session's own

- **`systemctl show -p Result --value` returns `success` for a unit that does not
  exist**, exit 0, `LoadState=not-found`. Measured with a control. Succeeded, never
  ran and absent are one value to anything reading `Result`. Never treat `Result`
  as evidence that something ran; read `ExecMainStartTimestamp` beside it.
- **GitHub's branch-protection API returns 404 for a branch protected by a
  RULESET.** The main session read that 404 as "not protected at all" and nearly
  contradicted a correct agent finding on the strength of it. The instrument is
  `repos/:owner/:repo/rulesets`.
- **`fail2ban.log` must be read across its rotation.** A grep of the current file
  alone returned zero occurrences of a warning that had fired seven times, and
  nearly killed a true finding. `zgrep` over `fail2ban.log*`.
- **A DF ping probe whose control returns nothing proves nothing.** The main
  session's counter-probe of the `wg0` MTU passed at every size because it targeted
  an address that never leaves the box. The disagreement is recorded unresolved
  rather than decided — which is the correct outcome for an instrument that failed
  its own control.

## Measured and rejected — added 2026-09-19 (second run)

- **"The Traefik access-log rate doubled to 9.99 MB/day."** Re-measured from the
  file's own first and last timestamps — 429 316 bytes over 1 h 44 — gives
  **5.95 MB/day**, the documented rate, and measured during an eight-agent audit
  that should have inflated it. The retention constant needs a quiet-period
  re-measure before anyone edits it, not a correction on this basis.
- **"The posture provenance probe compares nothing."** False. The deployed script
  compares start against trigger with a 5 s tolerance and today's beat says
  `manual run` verbatim. Two agents made the same conflation between
  `homelab-posture.sh` and `homelab-health.sh`; the real defect is in the latter.

## Shipped on 2026-09-19 — key `collision`, one PR, deployed from the branch before merge

The operator took five items of the eight put to them, declined three, and asked
for one PR.

- **The heal timer's blind spot on `Interval = 0`.** A container declaring
  `start_period` and no interval reports `Interval=0s` while the daemon probes it
  at its own default — `immich-server` and `immich-ml`, the two heaviest on the
  machine, measured 31 s apart in `State.Health.Log`. The guard skipped them
  without a word. Now it falls back to the daemon's 30 s default and logs which
  containers are aged that way. **`HEALTH_INTERVAL_DEFAULT` is the knob.**
- **The posture beat carries its provenance** — `scheduled run` / `manual run`,
  decided by comparing the service's start against the timer's last trigger, and
  saying `provenance unreadable` rather than guessing. A green from a hand-run and
  a green from the timer are no longer the same line.
- **A timer that FIRED SINCE THIS BOOT and whose service never started** is now
  reported by the health script, off the monotonic pair — the only slice of
  `Result`'s ambiguity that is decidable without crying wolf on every weekly
  timer.
- **`exit 2` means "could not measure", `exit 1` means "the property is
  violated".** Applied to five branches of the three posture checks that have
  actually fired this month, and documented once at the head of the spec's
  `command:` section. The exit status is the only field that reaches the alert —
  see the instrument trap below for why the obvious alternative does not exist.
- **Nextcloud's app store is off and its log is bounded.** The nightly fetch had
  failed with cURL error 23 since at least 2026-09-01, writing a 10 MB Guzzle
  trace each time into the file the fail2ban `[nextcloud]` jail re-reads.
  `appstoreenabled=false` removes the writer, `log_rotate_size` 10 MiB bounds what
  any writer can leave. The idempotence guard now case-folds both sides, because
  occ renders a boolean whose Jinja `string` is `"False"`.
- **Three documentary corrections**: the ADR count in `.claude/agents/project-manager.md`
  (16 claimed, 36 on disk) replaced by the command that regenerates it rather than
  by a fresher number; what the heal timer actually restarts, in the runbook read
  during a failed boot; and "Six of the conditions below" where nine is the count.

### What the deploy produced, measured 2026-09-19 00:30-00:35

215 tasks, 11 changed, 0 failed, and every claim below was checked on the host
rather than inferred from the recap.

- **The heal fallback is live** and was exercised against the real value:
  `immich-ml` reads `Interval=0s`, the fallback puts it at 30 s, so 30 failed
  probes — about 15 minutes at the daemon's real 31 s cadence — now reach the
  restart. `jellyfin`, which declares 30 s, takes no fallback. Positive and
  negative control, one command.
- **The posture beat now reads `— manual run`**, confirmed in the heartbeat table
  on the run the deploy itself triggered and on a hand-started one. **The
  `scheduled run` branch has NOT been exercised by a timer yet** — first chance
  2026-09-19 11:02. Both branches were proven in isolation instead, at the
  boundary: 5 s apart reads scheduled, 6 s apart reads manual, an absent trigger
  reads "timer never fired", an unreadable start refuses to guess.
- **The never-started check is deployed and silent**, which proves nothing on its
  own, so it was made to fire on purpose in isolation: a trigger since boot with
  no start fires; a trigger since boot with a start does not; and the case that
  must stay quiet — the offsite's 2026-09-01 trigger against its 09-12 boot —
  does not.
- **Nextcloud** reads `appstoreenabled=false` and `log_rotate_size=10485760`
  live. The next nightly fetch is the test of whether the 10 MB line stops.
- **An instrument trap paid a third time in one evening**: the deployed heal
  script lives in `/usr/local/sbin`, the first grep looked in `/usr/local/bin`,
  and the empty result read as "not deployed".

### The follow-up deploy, 2026-09-19 01:14 — the sample floor against netdata's age

The Renovate bumps recreated netdata at 00:55:45; the posture run that deploy
triggered at 01:02:05 read 76 health samples against a hard floor of 100 and
pushed DOWN; at 01:07:31 the count was 110 and the monitor was green again,
nothing having been repaired. A routine procedure had produced exactly the state
an assertion calls a failure — C105, found and shipped against within the hour.

The floor now derives from netdata's uptime, capped at the window's figure.
**Made to fail on purpose against the DEPLOYED text**, extracted verbatim from
`/etc/goss/posture.yaml` and run with its value sources stubbed: a mute collector
exits 1 at 900 s (floor 100) AND at 380 s (floor 63), so the young-netdata case
is not a blind window; the 01:02 situation and a healthy estate exit 0. The
failure sentence now carries the uptime and the cap, so "the collector is mute"
and "netdata just restarted" no longer read alike.

### What the Renovate deploy produced, measured 2026-09-19 00:48-01:02

Six image bumps — collabora, vaultwarden, prowlarr, sonarr, radarr, netdata —
verified image by image on the host rather than from the recap. `update every = 5`
survived netdata's recreation and the cost after the bump measures 19.48 % of a
core against 18.33 % before it. MariaDB 12 -> 13 (#364) was NOT merged: the
Nextcloud admin manual lists 10.11 / 11.4 / 11.8 / 12.3 and not 13, a major
MariaDB upgrade rewrites the data directory in place with no downgrade, and the
freshest dump was 21 h old. The PR stays open until Nextcloud lists it.

## Declined — added 2026-09-19, do not re-propose

- **A second, restricted SSH key for the sshfs mount.** One key covers four roles
  — admin on both hosts, the music mount, Ansible — with no restriction options,
  and at VERBOSE the journal shows no `sftp-server` line, so the mount and an
  intruder holding the key are the same entry. **The operator assumes this.** Do
  not offer `restrict,command="internal-sftp"` again.
- **Annotating the 16 documented procedures that trip a live assertion**
  (C105). A restore is an exceptional event and a surveillance outage during one
  is acceptable to the operator. The class stays in the register; the annotation
  does not.
- **Asserting on an empty `deploy_services`** (C106). The operator does not read
  the full-stack deploy it silently produces as a risk worth a guard. The
  measurement stands, the guard does not.

## Instrument traps paid on 2026-09-19 — four, and the first one removes a remedy

- **goss never prints what a check wrote.** Verified on the host against the
  deployed binary: a failing check renders its exit status, and a declared
  `stdout:` renders the literal `"object: *bytes.Reader"`. Any plan that involves
  "declare `stdout:` so the message shows up" is dead on arrival; the exit status
  is the only field that survives into the alert.
- **`--timestamp=unix` is not honoured by every timestamp property.** It works on
  `ExecMainStartTimestamp` and is ignored by `LastTriggerUSec`, which renders
  human whatever you ask. The locale-free route is the monotonic pair, and it
  resets at boot on both sides together — which is what makes a comparison across
  the two objects reboot-safe. Verify it on the offsite, whose last trigger
  predates its boot.
- **A wrong path returns empty, not an error** — the same family as the
  un-`sudo`'d glob. A Nextcloud log read one directory too high produced silence,
  one step from concluding there was no log.
- **A count that agrees with itself proves nothing.** Two independent methods, or
  the number is not usable.
- **`-e key="a b c"` keeps only the first token.** Ansible's key=value parser
  splits extra-vars on whitespace, so
  `-e deploy_services="collabora vaultwarden prowlarr sonarr radarr netdata"`
  sets `deploy_services=collabora` and the playbook succeeds, reporting changes,
  having deployed one service of six. Proven with
  `ansible localhost -m debug -a 'var=deploy_services'` in both forms. The form
  that works is JSON: `-e '{"deploy_services": "a b c"}'`. **A deploy that did
  the work and a deploy that did one sixth of it print the same PLAY RECAP** —
  which is this run's own key, paid by the main session while remediating it.
  Verify the images in place, never the recap.

## Shipped on 2026-09-18 — key `quiescence`, PR #361, deployed from the branch before merge

The operator took five items of the lot, declined one permanently, deferred one
for investigation, and the seventh dissolved under measurement.

1. **Every deadline in the posture spec is now explicit and generous.** A timeout
   renders as a FAILURE in goss, so a check that is merely slow pushes the same
   red as a check that is wrong. **Thirty of the forty-eight `exec` assertions
   declared no deadline at all** and ran on goss's implicit 10 s — the tightest
   bound in the file was the one nobody had written down. The eighteen explicit
   ones are tripled with a 60 s floor; the access-log walk goes to 300 s. The rule
   is written into the header so the next addition follows it: **at least three
   times the worst observed runtime, floor 60 s, and the run is bounded by the sum**
   (the unit has no `TimeoutStartSec`, the timer is daily, real runs take 40-55 s).
2. **`POLLING_PARSING_ERROR_LIMIT` is declared at 15.** It had never been chosen,
   so Miniflux ran on its upstream default of 3 and three transient fetch failures
   retired a feed permanently while the UI kept showing it active. The operator's
   instruction was "lengthen the delays, nothing needs to be tight, and I do not
   care about the feed that stopped being followed", and delegated the judgement on
   how far. **The assertion now reads that value from the container** instead of
   carrying its own copy of the number — same reasoning as fake-hwclock's 900 s.
3. **`[plugin:apps] update every = 5`.** The file declared `[db]` and nothing else:
   the retention had been argued and written down, the sampling rate never had.
4. **The armed state of every control timer is asserted**, inside the parity
   assertion that already built the set. Six lines, 14/14 green.
5. **Five documentary statements** that counted something other than what they say.

**Verified after the run — `ok=202 changed=9 failed=0`.** Exactly 2 of the 32
containers were recreated, miniflux and netdata, and nothing else moved.
`POLLING_PARSING_ERROR_LIMIT=15` is live in the container. **netdata fell from
42.74 % of a core to 20.61 %**, fleet total 85.59 % -> 60.90 %, measured with the
same 30 s cgroup window as the before figure so the two are comparable — about 22
points of a core recovered, slightly more than the 4.5 % predicted. The spec
validates at **400 assertions, 0 failures, 35 s**, and the armed branch was given
a negative control rather than assumed: a masked timer (`e2scrub_all`) is flagged,
an armed one is not.

**The posture check was NOT run through `homelab-posture.sh` to verify any of
this**, on purpose. That wrapper pushes a heartbeat, and a heartbeat pushed by
hand is exactly what made this run's baseline a false clean. `goss -g … validate`
executes the same assertions and pushes nothing. **The first real test of the
deadline fix is the scheduled run at 11:05**, not anything typed tonight.

**The deploy was `--tags observability,deploy -e '{"deploy_services": "miniflux"}'`,
never a bare run.** Checked first, and worth repeating as a habit: the 32 running
services carried **exactly** the images the repo pins, so no pending pin was armed
for the heal timer. `docker ps` abbreviates a digest pin to its tag — compare
`Config.Image`, not the `docker ps` column, or one service reads as pending when
it is not.

## Declined — added 2026-09-18, do not re-propose

- **Anything about the offsite tunnel re-resolving onto a wrong address.** On
  2026-09-16 `offsite-wg-reresolve.sh` installed the parents' box's wildcard answer
  as the endpoint of the only tunnel to that host, and corrected itself 67 seconds
  later. The operator's decision, in their words: it repaired itself, the box is
  the likely cause, and a durable failure would surface as a backup failure. **The
  class (C102) stays in the register; the authenticated-resolution fix does not.**
- **Reclaiming the frozen snapshot groups — for the FOURTH time.** This file
  already carried three refusals, including the sentence *"A third proposal needs a
  new consequence, not a new number."* An agent brought a fourth number, and it was
  wrong as well. See the measurement below. Nothing about `group-by`, `forget`, or
  pruning those groups is to be raised again without a new CONSEQUENCE.

## Measured and rejected — added 2026-09-18

- **Deleting the Transmission downloads frees nothing.** `du` reports 71 GB under
  `library/downloads/complete`, and **42 of its 52 files are hardlinks into the
  library — same inode, verified** (`Outlander - S08E02.mkv` resolves to one block
  from both paths). The single-link remainder is 0.0 GiB. Deleting them would
  reclaim no space and only stop seeding. **`du` counts a hardlinked file once per
  path**; that is the whole illusion.
- **The frozen snapshot groups are 71.7 GiB, not 253 GB.** Repo 414.4 GiB raw
  against 342.7 GiB for the live group alone. Four path groups: 12 live, 12 frozen
  on 2026-07-13 when `secrets` joined the set, 9 frozen on 2026-05-25 when `media`
  did, and 1 from 2026-09-13. `/mnt/data` is 20 % full with 3.5 TB free.
- **Netdata is about HALF the fleet's CPU, not more than it.** 42.74 % of a core
  against 85.59 % for all 32 containers, on an independent 30 s cgroup window.
  Quote "about half"; the agent's "more than the other 31 combined" does not hold.

## Arbitrated on 2026-09-18 — the heal timer's asymmetric bound, investigated then bounded

**The investigation changed the diagnosis, which is why it was worth doing before
proposing anything.** It is not a runaway healer. On 2026-09-06 an **Ansible
deploy was running** — 679 traces in the journal, a session open 23:00 to 03:01,
the `chmod 0444` of the secrets — recreating containers while the heal timer,
sampling every two minutes, saw them as `created` or `exited` and raced it with a
second `compose up`. The `ERROR: failed to restart` lines are two `compose up`
colliding. **131 attempts, 51 failures, 54 minutes, seven containers of which
three were databases.**

**The race itself is already settled and was NOT reopened.** `classes.md` records
it as a confirmed C90 instance seen twice (2026-09-05, 2026-09-12), and this file
already carries *"the heal-loop-versus-operator shape has no interlock and does
not need a new class — it is a convention, documented in five places, settled via
#126"*. What was new is the DURATION, and its cause: the `unhealthy` branch has a
one-restart-per-hour latch whose own comment describes this failure mode, and the
`exited`/`created`/`dead` branches — **the ones that actually execute** — had
none.

**Two things had already changed by the time this was investigated**, and both
belong in the record because they bound how much the remaining gap is worth:
- **Detection was shipped on 2026-09-13.** A collision makes the heal run count
  MORE containers than are declared, and `homelab-health.sh` gained the `-gt`
  branch for exactly that. On 09-06 three instruments were blind at once; they are
  not now.
- **The convention works when followed.** The targeted deploy of 2026-09-18
  recreated two containers at 23:02, and the heal run at **23:02:48 landed inside
  it and reported `0 restarted`.** The window is only wide for a full-stack
  deploy, which is already discouraged.

**The operator chose the short latch: ten minutes, not the neighbouring hour.**
The asymmetry is deliberate and is the whole reason the question was worth asking:
the exited branch is the only recovery path for the 23 of 32 services running
`restart: "no"`, so refusing to retry costs more there than it does on the
unhealthy branch. Ten minutes breaks a collision loop without delaying a real
recovery by anything a human would notice — the same event becomes six attempts
per container instead of twenty-eight.

**The interlock stays declined.** This bounds the race, it does not prevent it.
Do not re-propose a lock between the deploy path and the heal timer.

**Verified**: the logic was exercised in both directions before shipping — it
abstains, it reopens at eleven minutes, and each container carries its own stamp,
so one container's latch cannot delay another's genuine recovery. Deployed
`--tags stack-startup`, `ok=20 changed=1 failed=0`, and the run at 23:22:29 — the
first on the new script — reported `checked 32 of 32, 0 restarted`.

**Not related, recorded so it is not rediscovered as a consequence**: the backup
of 2026-09-06 failed at 03:13, an hour after the loop ended, at the RETENTION
step and after the snapshot was saved. It pushed DOWN at the time, so it was not
silent, and the following night was clean.

## Instrument traps paid on 2026-09-18 — four by the MAIN session, and one retires a rule written five days earlier

1. **Kuma prunes raw heartbeats after about 48 hours, while its setting says 180
   days.** 57 295 rows span 2026-06-22 to now, but the per-day counts are 26 189
   (today), 30 177 (yesterday), then **31 per day** beyond. `keepDataPeriodDays` is
   180 and governs the AGGREGATES. What survives past two days is `important = 1`
   plus `stat_minutely` / `stat_hourly` / `stat_daily`. **So the rule this file
   wrote on 2026-09-13 — "before recording that a failure was unobserved, query the
   monitor's own beats" — expires after two days.** Beyond that the question is
   answerable at the hour and not at the minute, and a run that answers it must say
   which store it read. `stat_hourly` did answer it here: 2 650 UP and 2 DOWN over
   the hour of the 09-16 tunnel outage.
2. **An empty enumeration returned the healthy value, in the main session's own
   instrument.** A per-container CPU loop built the cgroup path from `docker ps -q`
   — the 12-character id — where the path needs the full 64. It matched nothing and
   printed `0.00 % over 0 containers`. **Only the control line caught it.** Put a
   cardinal in every measurement loop and print it.
3. **A wrong field name reads as a zero, not as an error.** `expiryNotification`
   where the Kuma column is `expiry_notification`: 0 of 18, one step from filing a
   true documentary claim as false. **A zero from a named field must be controlled
   against a field known to be populated.**
4. **PostgreSQL has SQLite's double-quoted-string misfeature too.**
   `to_char(checked_at, "YYYY-MM-DD")` fails with `column "YYYY-MM-DD" does not
   exist`. Single quotes in every SQL, in both engines.

Two more, cheaper but repeatable: **a control chosen on the homelab proves nothing
on the offsite** (`/etc/goss/units.yaml` does not exist there, so its absence
"failed" a test that was never valid); and **`docker exec cat` is not a way to read
a container's `resolv.conf`** — Dozzle and Collabora ship no `cat`, so reading from
inside them answers "no embedded resolver" for two containers that have one. Read
`ResolvConfPath` from the host.

## The correction of 2026-09-13 (night-second) — "told nobody" was false, and it justified two decisions

The late-evening run's second headline reads *"a scheduled job failed at 07:00
and told nobody"* and *"the failure is silent"*. Measured from the live Kuma
database the following night: **`Pi health` (monitor 20) announced
`homelab-local-maintenance.service` by name at 07:06:04 CEST**, and carried it
for **72 DOWN beats over six hours** alongside `homelab-feed-digest`, which it
had already named at **06:41:12 — seven minutes and eleven seconds after that
unit failed.** Control: 1 665 beats in the window, 1 646 UP and 19 DOWN.

Monitor 22's silence is real and stays true. **"Told nobody" is not**, and the
error is not cosmetic: the same false premise drove two decisions that night.
`OnFailure=` was declined — correctly, and it is not being re-raised here, by
anyone — and `SuccessExitStatus=1` was shipped, which **deletes the detector that
made the decline safe.** See `classes.md`'s run section.

**The rule this pays for**: before recording that a failure was unobserved, query
the monitor's own beats. A unit's journal and a monitor's register answer
different questions, and the register is the one that knows whether a human could
have learned of it.

## Measured and rejected — added 2026-09-13 (night-second)

- **The image-retention arithmetic, in both halves.** `services` reported "42 of
  44 unreferenced images go; 1 of 14 services keeps its previous tag". Re-measured
  per repository: of 18 repos holding an unreferenced previous tag, **6 keep it
  and 12 lose it**; restricted to the comment's own scope — bumped this month —
  **7 qualify and exactly one loses its rollback tag (navidrome)**. Do not quote
  the agent's figures.
- **Escalating the lost rollback tags.** All 8 checked are **still pullable
  upstream** (controls: a tag that must exist -> pullable; a fabricated tag ->
  gone). The cost of losing one is bandwidth and time, never data. `services`
  refuted its own escalation on a second ground — the host resolves via
  1.1.1.1/8.8.8.8 and not Pi-hole, so a DNS-stack outage does not block the
  re-pull. **The remedy is to fix the sentence, not the mechanism.**
- **A stale wg-easy peer** (`security`, self-refuted: the container has only been
  up 2 days). **`udp/50349` with no owner** (`network`, self-refuted: it is wg0's
  kernel socket). **The Sunday/Tuesday timer discrepancy** (PR #354 rewrote the
  timer at 12:22 that day).
- **`system`'s swap note**: `swap.yml:14`'s "~1.9 GiB in swap" is 18 % low against
  2 309 MB measured by cgroup counters, with the last container restarts 3-6 h
  before. Still inside 4 632 MB available. A comment figure, not a defect.
- **`fake-hwclock.service` being masked** is deliberate, not drift — its
  replacement pair is enabled and firing. Recorded so nobody re-files it.

## Instrument trap paid a FOURTH time, 2026-09-13 (night-second), verifying the remediation

**An unprivileged read of a path inside a 0700 directory does not fail loudly —
it produces a false NEGATIVE that reads like a finding.** Verifying that the new
`state: absent` branches had deleted nothing, the main session ran
`readlink -f /etc/wireguard/wg0.conf` without `sudo` and got an empty answer,
which the check printed as `MISSING` — for the symlink that is the only remote
path to this host.

It was intact. `/etc/wireguard` is `drwx------ root root`, so the unprivileged
resolution failed rather than answering. Re-measured as root:
`wg0.conf -> /mnt/data/secrets/wg0.conf`, target readable, 294 bytes at 0600.
The control was the same unprivileged command run again deliberately, which
failed again.

This is the same family as the un-`sudo`'d GLOB (paid three times) and the
un-`sudo`'d recursive `grep` (2026-09-11), and it is now **four**. The rule
generalises past globs: **any read under a root-only directory must be run
through `sudo sh -c`, and a negative result from one that was not is an artefact
until re-measured.** A verification step is exactly where this hurts most — it
turns a successful remediation into an apparent catastrophe.

## Instrument traps paid on 2026-09-13 (night-second) — TWO ARE NEW, and one is aimed at this skill's own brief

1. **`sqlite3 "file:X?mode=ro"` is read-only at the SQL level, NOT at the
   filesystem level.** It still creates `-wal` and `-shm` beside the database.
   `project-manager` left a zero-length `-wal` and a 32 KB `-shm` next to two
   dormant Kuma rollback copies at 23:20:28 — impact nil, inside the
   `kuma-pre-*` restic exclusion, but it was a write on a read-only run.
   **This skill's own observability brief prescribes `mode=ro` as the safe
   form. It is not sufficient on its own**, and the brief should say so.
2. **SQLite's double-quoted-string misfeature.** `type in ("http","keyword")`
   silently becomes `type IN ('http', monitor.keyword)` when a column of that
   name exists — `observability` got 12 rows instead of 18 **and a false CLEAN on
   the very defect it then found by another route.** Single quotes in every Kuma
   query, always.
3. **`docker image prune --filter until=` reads the image's upstream BUILD date**,
   not its local pull date. Proof on the host: `ghcr.io/wg-easy/wg-easy:14`
   carries 2025-06-03 on a machine born in July 2026. Controls: `until=1h`
   selects 73/73, `until=87600h` selects 0/73. Anything reasoning about rollback
   age from that filter is measuring the wrong clock.

**Two rule-5 writes, both disclosed unprompted** — trap 1 above, and `services`
writing then deleting two files under `/tmp` on the host. Both agents reported
themselves before being asked, which is why the rest of their reports were
believed. `observability` disclosed trap 2 against its own headline. `network`
disproved its own instrument rather than reporting a hole. `system` and
`project-manager` each rejected a near-mint of their own.

## Shipped on 2026-09-13 (late evening) — key `repetition`, one PR, deployed from the branch before merge

The operator accepted every item of the lot except one, declined that one
permanently (below), and asked for a single PR.

**Deployed with `--tags observability,backup,ddns,claude-code,image-retention`,
never a bare run**: the tags keep `compose.yml` out, so no `compose up` copied
the stack definition and no pending image pin was armed for the heal timer.
`ok=116 changed=8 failed=0`, then `ok=46 changed=1` for the follow-up.

- **`h.status = 1` on both clauses of `no-kuma-report-was-lost-in-silence`.**
  Re-proven off-host against a database that CONTAINS fabricated rows, five
  scenarios, old and new side by side: a mute reporter fed only fabricated rows
  goes from exit 0 to exit 1, and the discriminating twin — a reporter that
  really recovered — still exits 0 on both. Verified on the host afterwards:
  the assertion EVALUATES, no timeout, posture exit 0.
- **`SuccessExitStatus=1` on `homelab-ddns`, `homelab-offsite-check` and
  `homelab-feed-digest`**, the three of the five candidates that carry a single
  `ExecStart`. **NOT on `homelab-backup` or `homelab-local-maintenance`**, and
  this is the decision worth carrying: both declare TWO `ExecStart` lines whose
  ordering guarantee depends on `Type=oneshot` stopping at the first failure —
  no replication if the backup did not run, no `check` if the `prune` did not.
  Making exit 1 a success would run the second command anyway. Their duplicate
  notification is the cheaper of the two costs. The agent that proposed the lot
  of five did not look at the `ExecStart` count.
- **The Kuma repair runbook copies `kuma.db*`** — all three files — and reads
  the throwaway copy plainly instead of through `?immutable=1`, which hides the
  `-wal` by design. Its rollback set is timestamped, so a second repair cannot
  overwrite the first one's; the restic exclusion became a GLOB in the same
  change, because a literal path list would then have backed up every later
  copy.
- **Nine restore recipes clear `/mnt/data/tmp/restore` before staging**, with
  one section saying why once. The deletion is a line in each recipe, not an
  automatism: the person running it can see it.
- **`fail2ban-client reload` chained to the UFW reload handler.** **It did NOTHING —
  corrected 2026-09-26 (fifteenth run).** A plain `reload` runs the jail's empty
  `actionreload` and never restarts the action, so the `-j f2b-<jail>` jump that
  `ufw reload` flushes out of `DOCKER-USER` stayed gone; a later ban does not
  restore it either. Now `reload --restart`, proven in a network namespace with
  the hosts' own fail2ban 1.0.2: the jump comes back and the bans are restored.
- **A monthly `homelab-image-retention` timer**, images only, `-a --filter
  until=720h`, off the deploy path.
- **calibre-web's ingest staging excluded from restic**; the live 3.3 GB is
  untouched, because reclaiming bytes on disk is a decision and not a deploy's.
- Three documentary corrections verified against the hosts.

### The new timer turned a gate red, and the gate was right

`offsite-parity-register-covers-every-control-timer` failed on the first posture
run after the deploy. It derives the set of controls from the MACHINE — every
`homelab-*.timer` with a unit file — and refuses to pass until a decision is
recorded for each. A new timer appeared; it caught it within the minute.

**That is the difference between a sweep and a gate, demonstrated on this
session's own work.** The entry added is a fact about the host rather than an
opinion about the check, which is the standard that register sets: docker is not
installed on the offsite, re-verified that night (`command -v docker` empty, no
`docker.service` unit file, against a `systemctl` control that answers) rather
than inherited from the 2026-08-30 line above it.

### Deployment note worth keeping

**The deploy role's final "re-assert the posture" task is UNTAGGED**, so a
tagged deploy does not run it. The posture spec was updated on the host and had
not been evaluated; the check had to be started by hand to verify the fix. Any
future tagged deploy that changes an assertion needs the same manual run, or
the verification is of the file rather than of the behaviour.

## Declined — added 2026-09-13 (late evening), NEVER propose again

- **`OnFailure=` on the `homelab-*` units.** Raised after
  `homelab-local-maintenance` failed at 07:00:01 on 2026-09-13 — it died on a
  lock-wait timeout *before* the profile started, so no hook ran, and monitor 22
  received no beat at all, neither up nor down. The measurement stands and is
  recorded in `classes.md`: **`OnFailure=` is empty on 14 of 14 units**, and one
  single unit on the whole host declares one, so every scheduled job depends on
  its own script reaching its own notification code.
  **The operator's answer is no, and the instruction is that it never be raised
  again** — not with a new number, not with a fresh instance, not as part of a
  larger lot. The silence fuse (C41) remains the backstop and the operator
  carries the gap knowingly.
  *Do not re-propose. Do not re-measure it to make the case better.*

## The lesson of 2026-09-13 (late evening, key `repetition`) — a gate proven against a fixture

**C03-T was promoted to GATED on the strength of six fail-on-purpose runs and it
was blind the day it shipped.** The runs were real, the assertion was read
verbatim, `docker`/`journalctl`/`sqlite3` were stubbed, and a discriminating twin
was included. The proof was sincere.

It ran against a **synthetic Kuma database**, which by construction contained
only the rows the test itself wrote. Production contains rows nobody writes on
purpose: Kuma 2.5.0 fabricates a DOWN beat carrying `No heartbeat in the time
window`, once per interval, for any push monitor whose previous beat is not UP.
C03-T counts `heartbeat` rows with no `status` filter, so those rows answer
"something reached the dashboard" on behalf of a reporter that reached nothing.

> **A gate proven against a fixture is proven against the fixture's model of the
> world.** Before trusting a fail-on-purpose proof, ask what the real store
> contains that the fixture cannot: rows the upstream writes itself, files
> another process leaves, state that predates the test.

The general form of the remedy is also recorded, because the obvious fix is the
wrong one: **do not key an assertion on an upstream's human-readable message
string.** `'No heartbeat in the time window'` is a literal from one version.
Key on the structured field — `h.status = 1` — which is what C41 has done since
2026-08-30 and precisely why C41 survives what breaks C03-T.

## Instrument traps paid on 2026-09-13 (late evening) — two by the MAIN session

1. **`systemctl show -p Result` reports the LAST run, not the cadence.** The
   audit's own baseline read "14/14 `homelab-*` timer services at
   `Result=success ExecMainStatus=0`" at 21:25 and called the surface clean. One
   of those units had FAILED at 07:00:01 that morning; a hand-run at 12:24:27
   overwrote the state. **A unit's current state is not its cadence's history** —
   to audit a schedule, read the journal for the scheduled instant, or the
   monitor's beats, not the unit's last result.
2. **An un-`sudo`'d shell glob over a 0700 directory, paid for the THIRD time.**
   `sudo ls -l /mnt/data/services/uptime-kuma/kuma.db*` answered "No such file"
   in the same second that `sqlite3` opened that database successfully — the
   glob expands in the unprivileged shell before `sudo` ever runs. `sudo sh -c
   '...'` gave the real answer. This rule is already trap 5 of the secret section
   below, and it was written into this run's own agent brief before being broken
   by the person who wrote it.

**Three disclosures by the agents, all unprompted, all worth the credibility they
buy.** `services` corrected its own filed report to say that a `du -sh
/mnt/data/docker` it had described as producing nothing had in fact completed at
exit 0 — so a rule-6 walk did run over the whole store with seven agents on the
board. It then refused to scale a measured 16.62 GB by a measured 51 G / 32.4 GB
ratio, on the grounds that the gap was recorded and not attributed. `system`
caught itself hitting the `logrotate -d` trap below before filing. `network`
disproved its own instrument rather than reporting a hole.

## Declined near-mints — added 2026-09-13 (late evening)

Both were **offered rather than claimed** by the agents that found them, and that
is what makes the two mints the same run kept credible.

- **`system`'s "a periodic mechanism whose decision to act is read from a record
  it rewrites on every run".** Derived and swept: logrotate state (22/19
  entries), the gate library, heal latches, `pending.last`, 23 systemd stamps, 6
  apt stamps. **Zero defective, anywhere.** A property with a cardinal and no
  instance is a hunch with arithmetic. Re-raising needs an instance, not an
  argument.
- **`security`'s "a declarative apply step that adds but never retracts, so the
  deployed set is the union of every value the variable has ever held".** Its own
  agent rejected it as a re-mint of C88 under a different mechanism. Correct —
  and it became the second independent derivation that REOPENED C88 off its
  "file rendered into a directory" axis.

## Measured and rejected — added 2026-09-13 (late evening)

- **`/var/log/sudo.log` unrotated.** 88 168 entries back to 2026-07-18, 15.7 MB
  on the SD card, no rotated sibling, same signature on the offsite — and it is
  **not a defect**: `/etc/logrotate.d/sudo` was created 2026-09-12 15:10
  (`8a4c186`), logrotate registered it at 00:00:08 on 09-13, and it falls due
  2026-09-20. Do not re-report before that date.
- **An ACME duplicate-order loop.** Refuted with numbers: 21 certificates, 21
  names, **21 distinct serials**, 10 issuances in 4 days against Let's Encrypt's
  50/week. No retry storm exists.
- **NAT rule accumulation.** `DOCKER-USER` holds exactly 8 rules, wg-easy's
  MASQUERADE appears once, every host `nat` rule counts 1. The `--noflush`
  re-append is real and latent, not accumulating.
- **Pi-hole gravity rebuilding rather than appending.** 79 963 rows == 79 963
  distinct == the adlist number. It rebuilds.
- **Entrypoints appending to configs they own.** Zero, over a derived set: file
  mtime within 3 minutes of each container's own `StartedAt`, non-empty for 8 of
  14 probed (positive control), every hit a fixed-size rewrite.
- **The heal timer's exited ∩ unhealthy double-pass.** Safe: the second pass sees
  `running`/`starting`.

## An instrument with no discriminating power — added 2026-09-13 (late evening)

**The `vpn-only` allow-list cannot be probed from the host.** `curl --interface
172.17.0.1` and `--interface 172.19.0.1` — both addresses outside the allow-list
— returned **200**, and the access log shows why: Docker masqueraded both to
172.18.0.1, which is inside it. The test proves nothing in either direction, and
a "hole" reported from it would be an artefact. Probe from a real client on the
real path or do not probe.

## Declined — added 2026-09-13 (late evening), do not re-propose

- **Removing or hedging the ISP references.** "SFR/Red" appears in six files as
  operational knowledge — how to leave CGNAT, why port forwarding fails in
  silence. It was raised as an identifying detail during the privacy pass, with
  the option of rewriting it as "some ISPs, for example SFR/Red". **The operator
  decided to leave it exactly as it is.** Removing it would cost a reader the
  one piece of this repository they cannot easily find elsewhere, and the
  identification it carries is worth less than that. Do not raise it again.

## Instrument trap paid on 2026-09-13 (late evening)

**`ansible-inventory` does not template.** It prints inventory values RAW, so a
`hostvars[...]` or even a same-host `{{ }}` reference appears literally. A check
built on it proves nothing in either direction — and its own output carries the
control that shows this, rendering `backup_dir` as
`{{ data_mount_point }}/backups`.

The discriminating test for anything the inventory resolves is a CONNECTION:
`ansible <hosts> -m ping`. It travels the real path, `ping` writes nothing, and
a jump host is exercised rather than described. Used to verify that `homelab_ip`
resolves from the gitignored `private.yml` and that the offsite's ProxyJump
templates in its own scope — both `SUCCESS`.

## Shipped on 2026-09-13 (evening, second) — key `locality`, one PR

The operator's instruction was "everything in one PR", and one constraint came
with it and overrides any argument about clarity: **nothing in the public repo
may reveal the real domain, whatever else the fix requires.**

**The firewall was NOT changed, and that is the decision worth carrying.** The
first reading of the SSH finding was "widen the ufw rule to reach the VPN
clients". It was wrong twice over: the clients arrive masqueraded behind a bridge
address, so the widening would have opened the host's sshd to every container on
`proxy` — which `host_vars` refuses in writing — and it was unnecessary, because
the host is a peer of its own wg-easy and the tunnel address already matches the
rule as written. **Remote SSH goes to the tunnel address, never to the LAN
address.** Documented in `docs/03-security/README.md`, in the `host_vars`
comment, and in the WireGuard page's client section.

**What shipped**, all in one PR, deployed from the branch before merge:

- `stop_grace_period: 60s` on transmission — the only container that writes
  multi-gigabyte payloads it cannot re-verify on its own. **Explicitly not a
  general extension to the other 27**, which stays measured-and-rejected.
- `goss --max-concurrent 8` in `homelab-posture.sh`. The 13 timing-out
  assertions were contention on one dockerd from 50 concurrent tests on 4 cores,
  not slow checks. **Fixed the concurrency, not the thirteen timeouts.**
- The feed-digest vault gate moved out of `ExecStartPre` and into `digest.sh`,
  three lines after `fail()` exists. Same two assertions, same protection, in the
  one place that can announce its own failure.
- `backup-notify.sh` emits the lost-report marker when its push URL is empty,
  and still exits 0 — a backup that ran perfectly must not be recorded as failed
  because its notification had nowhere to go.
- `offsite-backup.md`'s manual copy block sources `backup.env`, which is what
  made a hand-run silent.
- navidrome's healthcheck reads the body, like the three `*arr` probes fixed
  that afternoon.
- The `claude-code` purge tasks resolve their inventories once and assert them
  non-empty. `fileglob` returns `[]` rather than failing, and `not in []` is true
  for everything.
- fail2ban's `sshd` journalmatch names `ssh.service`. A correctness fix with no
  live effect — see the rejected claim in `classes.md`.
- Documentary: 10 typed commands moved from the masked literal to `<domain>`,
  with the convention finally stated in `README.md`; `/config` replaced by the
  host path in the restore runbook; `cd /opt/homelab` added to the unattended
  rollback; the media-restore sentence corrected in two places; the dump list
  replaced by the command that regenerates it; the 29 denominators corrected to
  32; the posture by-hand section says which host.

## Declined — added 2026-09-13 (evening, second), do not re-propose

- **Widening the ufw SSH rule to any bridge source.** See above: unnecessary and
  harmful. The tunnel address is the supported remote path.
- **`system`'s near-mint, "a failure recorded only in the supervisor's
  namespace".** Offered for arbitration, not claimed by its own agent. No bounded
  space; its instances are members of C97.
- **A general `stop_grace_period` extension.** Re-raised with a genuinely new
  fact — the earlier sweep read container logs, which cannot see a SIGKILL, and
  the daemon journal shows 56 forced kills in 7 days. The new fact was accepted
  and the answer is unchanged for the other 27: only transmission gets one.

## Instrument traps paid on 2026-09-13 (evening, second) — three, all by the MAIN session

1. **A sample is not a sweep, and this run put a number on it.** An agent
   re-hashed 14 of 1579 torrent pieces and found 3 bad. The main session
   reproduced all 3, found a 4th the sample had not covered, then enumerated all
   1579 and found **89**. The method was sound at every step; only the coverage
   was not. When a full enumeration is affordable, sampling is not a shortcut,
   it is a different and weaker claim.
2. **`mountpoint` as root returns NO on a healthy FUSE mount.** Without
   `allow_other`, a FUSE mount denies even root, so the stat fails and
   `mountpoint` reports a false negative. Read `/proc/mounts` and look for the
   mounting process instead.
3. **A heavy `journalctl` scan is a change to the system under audit.** A
   7-day unbounded scan took the Pi to load 10.3 while seven agents worked on
   it. The rule was already in the brief; it was broken by the person who wrote
   it. Bound every journal query by unit or by a narrow window.

Two older traps recurred and are restated rather than re-filed: **a live probe
must never carry the masked domain** (paid a fifth time, and now fixed at the
source — the repo says `<domain>` in commands and states the convention in
`README.md`), and **a negative result needs a control known to be non-empty**.

## Arbitrated and shipped on 2026-09-13 (late afternoon) — key `granularity`, PR #354

**The operator's two register decisions.** C92 closed by decision as a REVIEW
RULE; C95 stays OPEN. Both are in `classes.md` with their reasoning.

**The review rule C92 became, and it is the durable output of that class:**

> Every fix states the population its own property defines, and either sweeps it
> or says why it does not.

It exists because the run proved no instrument can derive that population: the
directory bound gives 2 of 203 fix commits, and a correction's residues routinely
live in directories the commit never opened. A machine cannot do this; the
sentence in a commit message can.

**What shipped**, deployed to both hosts from the branch before merge and
verified by function: the split-DNS monitor re-pointed at an internal name with a
condition on the address; SSH scoped in ufw per host; the three `*arr`
healthchecks matched on their body; and the documentary corrections (media
library on four pages, the Sunday->Tuesday schedule in six places, the restore
section's 4-of-10 database list, `wireguard.md`'s missing Backup section, three
`*arr` monitors absent from the Kuma registry).

## Declined — added 2026-09-13 (late afternoon), do not re-propose

- **Announcing the maintenance job's pre-restic failures.** `resticprofile`
  attaches `run-after-fail` per command, so a failure before the first restic
  command pushes nothing — proven on the 07:00:01 event. The operator's answer
  was "on s'en fiche". Note the fact that makes it defensible: `689c4f2` moved
  the job to Tuesday 01:00, ahead of the 03:00 backup, so the lock collision that
  caused it cannot recur in that direction.
- **The short-alarm sampling gap.** The netdata->Kuma adapter reads current alarm
  state every 300 s; the two container alarms have no `delay:`, so a raised
  window can be as short as 60 s. Measured: of the three raised episodes netdata
  retains, one lasted 120 s and fell between two samples. Declined.
- **Reclaiming the stranded snapshot's space.** Path-group cleanup was declined
  in August at 1.2 GiB. The new fact — a stranded group now holds the media
  library — was stated rather than re-argued, and the answer was unchanged. The
  snapshot stays; the consequence is documented instead.

## Instrument traps paid on 2026-09-13 (late afternoon) — four, all by the MAIN session

1. **A live probe typed with the masked domain.** `example.com` resolves to
   nothing on the hosts. This file has carried the rule since August and it still
   happened — so it is restated here as an operational habit, not a footnote:
   **the repo says `example.com`, every command typed at a host says the real
   one.**
2. **Three services tested on one service's port.** The two `rc=7` results were
   connection-refused, not evidence. A per-target re-run is the only valid form.
3. **A `sed` that relabelled every port**, turning an unrelated port-8000 rule
   into an apparent third SSH rule on a host that had just been firewalled.
4. **A null result with a control that was also null.** `journalctl -t <tag>`
   returned "No entries" and so did the control, so the instrument was not shown
   to discriminate. A control known to be non-empty is what makes an absence
   mean something.

## The GPG signing failure of 2026-09-13, which is NOT the one this file documents

The existing entry describes an intermittent signing failure that TIMES OUT, and
prescribes a retry then `--no-verify`. This run hit a different one:
`gpg: signing failed: Inappropriate ioctl for device`, **immediate**, and it
survived all of it — retry, `DISPLAY=:1`, `DBUS_SESSION_BUS_ADDRESS`,
`gpg-connect-agent updatestartuptty`, and `--no-verify`. Four attempts, four
identical failures.

`/usr/bin/pinentry` is already `pinentry-gnome3` and the X socket exists, so the
documented cause does not apply. **What cleared it was the operator unlocking the
agent once in their own terminal**; every subsequent commit signed without a
prompt. So: after two immediate `Inappropriate ioctl` failures, stop retrying and
ask for one interactive unlock rather than working around the signature.

## Arbitrated and shipped on 2026-09-13 (night) — one PR

**The operator's three decisions.** C01 closed by arbitration; C03 split, its
decidable half gated and its review half closed by decision; the `*arr`
`logs.db` siblings left undumped. All three are in `classes.md`'s DECLINED
table with their reasoning. **Do not re-propose any of them.**

**What shipped.** A fallback resolver and 21 `extra_hosts` pins for
`uptime-kuma`; four documentary corrections (the WireGuard restore recipe, the
`*arr` restore procedure, the `*arr` backup section, the backup coverage table).

**How C03-T was made to fail on purpose, because the method generalises.** The
run was read-only and the assertion reads the live journal and the live Kuma
database, so it could not be exercised in place without writing a marker — which
would have tripped a real monitor and is the "no test heartbeats" rule. Instead
the deployed `exec` was extracted verbatim and run **off-host** with `docker`,
`journalctl` and `sqlite3` replaced by stubs and a synthetic Kuma database.
Six runs, both directions, including a **discriminating twin**: the same clock
and the same marker, changing only whether the reporter had beaten since the
loss, which isolates the variable instead of demonstrating two unrelated
outcomes. Nothing was written on either host.

**One caveat recorded with it**: this proves the SCRIPT discriminates, not that
the deployed instance is wired to the right journal and database. The wiring is
evidenced separately — the assertion is present at `posture.yaml:2995` and
executed in the 13:03 run — and that pair of facts is what the GATED entry
rests on.

**And a trap paid inside the proof itself.** The first run of all five scenarios
returned the same early exit, because the `docker` stub passed `$1` after
`shift 3` where the query is `$2` — so every SQL call received the connection
URI as its statement. **A harness is an instrument.** The tell was that all five
scenarios agreed, which no discriminating test should ever do; the fix was a
one-line instrument check (`does the floor query return an epoch?`) before
trusting any scenario. A second scenario then failed for a different and better
reason: the loss was dated 30 minutes back while the reporter's cadence is
3600 s, so the assertion correctly refused to judge a reporter not yet past its
own interval. **The test was wrong, not the gate** — and distinguishing those
two took re-reading the assertion's own comment.

---

## Instrument traps paid for on 2026-09-13 (night) — one by the MAIN session, and it reached all eight briefs

- **`systemctl show -p ConditionPathExists` returns EMPTY even when the unit
  declares it.** On this systemd version the property is not exposed that way.
  The main session read that silence as "the unit has no guard", wrote it into
  the shared brief as a live lead, and four domains spent budget refuting it.
  `homelab-ddns.service` carries `ConditionPathExists=/mnt/data/secrets/ddns.env`
  at line 5, plus `After=mnt-data.mount`, and is wired into
  `mnt-data.mount.wants`. **Read the unit file.** And the general rule, which
  this file has carried since 2026-08-15 and which applies to the verifier as
  much as to the agents: **a null result from an instrument you have not
  controlled is not a finding.** The premise of the key was controlled; the lead
  drawn from it was not.
- **`RequiresMountsFor=` is silent for a FUSE path and hard for a real mount
  unit.** In `claude-remote-control.service` it names `/home/claude/vault`, an
  rclone mount with no `.mount` unit, and resolves to nothing. In
  `homelab-feed-digest.service` it names `/mnt/data`, which has one, and
  resolves to `Requires=mnt-data.mount`. Two units that look inconsistent are
  not. This is what made an agent read a comment as contradicted when the
  comment's own cross-reference proves it means the vault in both files.
- **Proving a `pgrep -f` self-match needs the pattern OFF the argv.** Passing it
  as an argument makes every test positive, including the control — the invoking
  `sh -c` carries the pattern itself. The correct instrument feeds the pattern on
  **stdin**: `printf '%s\n' "$pat" | docker exec -i <c> sh -c 'read p; pgrep -f "$p"'`.
  With that, a nonexistent process correctly returns no-match and a real one
  returns MATCH, so the argv form's SELF-MATCH is proven rather than assumed.
  The main session's first negative control was contaminated this way and was
  re-run.

---

## Deployed on 2026-09-13 between 14:15 and 14:21 — and the audit's baseline missed it

A deploy landed **eleven minutes before** this run's baseline and eighteen before
the agents were sent. It carried three things the register recorded as pending:

- **The C03 gate**, `no-kuma-report-was-lost-in-silence`, into
  `/etc/goss/posture.yaml` (spec mtime 14:15:44). Derived, and it names its own
  unknown: it takes its floor from Kuma's `StartedAt`, refuses to judge when it
  cannot read that floor or when no beat exists, and caps the lookback at 26 h
  for a reason written in the file.
- **The offsite sysctl residual**, `net.ipv6.conf.eth0.accept_redirects`, now 0
  with `99-homelab.conf` at 30 lines on both hosts (mtime 14:21:20).
- **The dump assertions**, 46 live on the deployed spec.

**The lesson is about the baseline, not the deploy.** A baseline that reads
failed units, container states, timer codes and monitor colours cannot see a
spec file that changed minutes earlier. When the register says "not deployed",
**check the artefact's mtime before writing it into a brief** — it costs one
`stat` and it would have saved a whole agent's mandate here.

---

## Instrument traps paid for on 2026-09-13 (evening) — three by the MAIN session, all while verifying

Every one of them produced a wrong verdict that survived until a control was
added. They are recorded first because they are the cheapest lesson in this file.

- **Do not evaluate the dump spec outside the backup window.** `resticprofile`'s
  `run-before` does `rm -rf /mnt/data/backups/dumps` then recreates it; the dumps
  are written; the spec is validated at line 182 of the profile, INSIDE the
  window, into `/run/homelab-backup-dumps.tap`; `run-after` deletes the
  directory once the snapshot holds it. Running `goss -g /etc/goss/backup-dumps
  .yaml validate` at 14:30 therefore returns ~24 red assertions and means
  nothing. It produced a false alarm about the entire backup chain. **The real
  verdict is the TAP file from the last run** — 31 ok / 0 not ok that day. This
  is C03's own property, committed by the session auditing C03.
- **Read the assertion names before grepping for them.** The dump assertions are
  `dump-sonarr-source`, not `sonarr-source`. A grep for the wrong prefix returned
  0 and read as "the deploy did not land" when the file had been rendered eight
  minutes earlier. A positive control — grep a name known to be present — turns
  this into a five-second check.
- **Find a deployed script through its unit, not by guessing its path.** The feed
  digest is at `/home/claude/.local/share/feed-digest/digest.sh`, under the
  `claude` user, not under `/opt/homelab/scripts/`. `systemctl show -p ExecStart`
  answers in one command what three `find` guesses got wrong.

The shape common to all three: **an instrument that answers a different question
from the one being asked, with no control to reveal it.** The rule this file has
carried since 2026-08-15 applies to the verifier as much as to the agents —
always include a control that proves the instrument works.

---

## Shipped on 2026-09-13 (evening) — PR #352, deployed to both hosts before merge

Six changes, each verified by function rather than by colour.

- **Sonarr, Radarr and Prowlarr enter `backup_sqlite_dumps`.** They were already
  in the restic set; what was missing was the dump and the assertion. Measured
  before: `radarr.db-wal` held 3.77 MB of committed transactions outside the main
  file. 15 assertions generated, 31 → 46.
- **The nine other Kuma emitters distinguish `curl` exit 28** from a real
  failure, as `77efb2a` had done for the tenth that morning. The form is
  `|| rc=$?` and not a bare pipeline read through `PIPESTATUS`, **because two of
  the ten run under `set -e`** — the old `|| echo` was providing that guard by
  accident, and removing it without replacement would have turned a cosmetic
  defect into an aborted script.
- **The shared-credential-store set is declared and asserted EQUAL.** Not a
  floor: a floor lets the set GROW in silence, which is the direction that costs
  something. Proven under `dash` on the host, in both directions.
- **`no-new-privileges` is asserted exactly**, by list membership in Jinja and an
  anchored regex in jq. Proven in three directions on live containers, including
  `no-new-privileges:false`, where the old substring test returned `true`.
- **fail2ban**: `iptables-multiport` so the jails' declared `port = http,https`
  is honoured, and the host's own address into `ignoreip` via
  `ansible_default_ipv4`. The offsite deploy justified that choice by writing
  that host's own address on a different subnet, where a literal would have
  written the wrong one. **Proven by function**: a test ban of a documentation
  address produced a jump reading `multiport dports 80,443` where the old one
  carried no port match at all; the unban returned the chain to a bare `RETURN`.
- **The three `config.php.bak-*` copies were removed by hand** — residue, not
  state to maintain, so no Ansible task.

And the standing consequence, which is NOT fixed: **the offsite host has no
continuous posture assertion of any kind.** `offsite.yml` never plays the
`observability` role, so `/etc/goss` there holds one spec. That is why a sysctl
fix could sit undeployed for two days with nothing to say so.

---

## Declined — added 2026-09-13 (evening)

- **Rotating the Nextcloud database password** after two unmanaged copies of the
  live value were found in the service directory. The copies had been in every
  restic snapshot since 2026-09-01, offsite included. The copies are gone; the
  snapshots are encrypted with a key the operator controls, and that is accepted.
- **Reclaiming the ~70 GiB pinned by the permanent snapshot group.** The same
  cleanup was declined on 2026-08-15 at 1.2 GiB; the figure is now right and the
  answer is the same — there is room. **A third proposal needs a new
  consequence, not a new number.**
- **Moving the `*.example.yml` files out of `inventory/host_vars/homelab/`.**
  They are loaded as live variables because Ansible loads every file in a
  host_vars directory regardless of its name — reproduced in isolation, and
  `ansible-deploy` measured that 24 of 78 `required: true` options are therefore
  protected by nothing. The operator's decision: the file is the reference, it
  must stay current, and it stays where it is. Nothing is live today and the
  residual risk is carried knowingly. Do not propose the move again.

---

## Handling secrets DURING an audit — eight traps, five paid on 2026-09-12 and one on 2026-09-13

The dedicated secret audit of 2026-09-12 found two real defects and caused five
exposures of its own. The exposures were not bad luck; each is a specific,
repeatable mistake, and any future value-first sweep will hit them again unless
these rules are followed literally.

**1. Never let a secret reach an argv.** `sudo grep "$secret" file` puts the
value on sudo's command line, which sudo journals — so searching for a leak
creates one. The main session added four fresh copies of a live app-password to
`auth.log` while investigating that password's presence in `auth.log`. The only
correct form is patterns on STDIN: `printf '%s' "$v" | sudo grep -F -f - file`.

**2. NEVER pipe data into `ssh host 'sudo sh -s'` that is also fed a heredoc.**
Both go to the same stdin, the pipe wins, and `sh` reads the SECRETS AS ITS
SCRIPT and echoes each one in a `not found` error. This printed roughly forty
live secret values in cleartext into a session transcript. It is the single most
damaging mistake in this file. Choose one channel: either the script comes from
the heredoc and the data from a file descriptor, or the data comes from the pipe
and the script is a quoted argument.

**3. Never print a grep match from a file that may hold secrets.** `grep -n
"P=" file` prints the value. Every display must be masked, and the masking must
run BEFORE the output is produced, not after it is read.

**4. `umask 077` before creating any pattern file**, and shred it in a trap on
EXIT/INT/TERM. A default umask writes 0644, which is the exact class under
audit. Prefer `/dev/shm`, never a disk path.

**5. Run as root, and let root expand the globs.** An un-`sudo`'d recursive grep
skips root-only files silently, and an un-`sudo`'d SHELL GLOB over a 0700
directory expands to nothing — which reads as "clean" and is not. Use
`sudo sh -c '...'` so the glob resolves with the privilege.

**6. Compare secrets by hash only, with both sides stripped identically.**
`jq -r` appends a newline and `cat` may not; hashing one of each compares
different strings and returns a confident "they differ". Always include a
control that hashes one known string twice in the same pipeline.

**7. Derive the value set, then CONTROL it before believing any sweep.** V took
three iterations (63 → 51 → 36) and two of them looked right while producing
mostly noise. Assert that a handful of known secrets are present in V before the
sweep runs; a sweep over a bad V is worse than no sweep, because it looks
thorough.

**8. Never `head`/`cat` a credential store to learn its SHAPE.** Paid on
2026-09-13: an agent ran `head -c 400 /etc/wireguard/wg0.json` to find out
whether the store carried an IPv6 field. That file is plain JSON with the
**WireGuard server private key first**, followed by the first client's private
key, so the probe printed both into the session transcript. A key-name listing
answers the shape question and reveals nothing:
`python3 -c 'import json,sys; print(list(json.load(open(sys.argv[1]))))'`.
The v14 `wg0.json` is the specific trap because the secret is the first field.

## The exposure of 2026-09-12, and the operator's arbitration

Trap 2 above put roughly forty live secret values into a session transcript —
not a public place, but off the machines: the terminal, the conversation's
storage at the vendor, and the local transcript under `~/.claude/projects/`.
Nothing reached GitHub, no commit, no issue, no PR; that was verified against the
full 6 919-object history before and after.

**The operator declined a general rotation, and that decision stands.** The
reasoning recorded with it: everything exposed is reachable only from inside the
LAN or through the WireGuard tunnel, with one exception — the **Cloudflare API
token**, which works from anywhere on the internet with no VPN and no LAN, and
which is therefore the only one where "not public" does not change the exposure.
Two further judgements were made and should not be re-litigated:

- **The restic repository passwords are NOT to be rotated.** A botched key
  rotation locks the operator out of their own backups, and that risk is larger
  than the one it would address.
- **The WireGuard key set is NOT to be rotated** for this reason. Revocation is
  still impossible (#138), and an attacker would already need to reach the
  endpoint.

Do not re-propose any of this. If a NEW fact appears — the transcript becoming
public, or one of these credentials being used — that is a new decision, not a
re-argument of this one.

## Instrument traps paid for on 2026-09-12 — carry these, they cost a false verdict each

**An un-`sudo`'d shell GLOB over a root-only directory does not fail.** It
expands to nothing (or to the literal pattern) and every count downstream reads
zero, silently. It cost the main session a false "0 domains" when reading
Traefik's ACME backups under a `0700` directory; re-run as `sudo sh -c '...'` so
the glob expands with the privilege. This is the same family as the un-`sudo`'d
recursive `grep` recorded on 2026-09-11, and it will recur under a different
shell construct — the general rule is that **privilege must be acquired before
the shell resolves names, not after.**

**Comparing two secrets by hash requires both sides stripped identically.**
`jq -r` appends a newline; `cat` of a file may not; hashing one of each compares
two different strings and returns a confident "they differ". The main session
reported a Vaultwarden admin token as changed on exactly that basis, then
re-measured it as byte-identical. **Always include a control that hashes one
known string twice**, in the same command, with the same pipeline.

**A WireGuard key set must be matched against the right interface.** wg-easy
runs its tunnel inside its own container; the host's `wg0` is a different
tunnel (the offsite link, 1 peer). An agent compared stored client keys against
the host interface, got 0/4, and read it as "not current" — the correct
comparison against the container's interface returns 4/4, and the stored
*server* key still derives the live server identity. State which interface a
peer count came from.

**`logrotate -d /etc/logrotate.d/<file>` is not how logrotate runs.** Tested
standalone it bypasses `/etc/logrotate.conf`, whose global `su root adm` is what
makes rotation legal in a `775 root:syslog` `/var/log` — so it reports
`parent directory has insecure permissions` for a stanza that is perfectly
correct. The proof that the test and not the configuration is wrong: the SAME
error appears for rsyslog's stanza, whose rotation demonstrably works. Verify
with `logrotate -d /etc/logrotate.conf` and look for the file by name.

**`ansible_managed` is undefined inside `copy: content:`** — the variable is
supplied by the `template` module. The three logrotate and sudoers files this
repo writes with `copy` all use the literal
`# Managed by Ansible — do not edit on the host.`; follow them.

**`stat -c %a` on a symlink reports 777**, which is the link's own mode and is
always 777. `/opt/homelab/.env` looks world-writable and is a link to a 0600
file. Resolve the target, and test with `sudo -u nobody test -r/-w` plus a
control.

**`docker inspect` output is not secret-free by default, and it is not secret-
bearing either.** The 2026-09-12 run left a 412 KB dump world-readable in `/tmp`;
its 13 secret-shaped matches were all `*_FILE=` **paths** and public GPG key ids.
Check before alarming — and before dismissing.

## Shipped on 2026-09-13 — the remediation, and what it cost to find

Twelve commits, all deployed and verified by probing the function rather than
reading a PLAY RECAP. **Five defects were found while APPLYING the audit's
corrections, none of them visible on any dashboard**, and that ratio is the
lesson: verifying that a fix took effect is a better detector than the audit
that motivated the fix.

- **`--tags backup` reached none of the three restic timers.** A reschedule
  deployed, reported `changed=2`, and left both timers on the host still saying
  Sunday. `backup.yml` and `offsite.yml` were untagged; only `resticprofile.yml`
  carried the tag. Any timer change since the role was written would have been
  lost in silence. Both are tagged now.
- **`homelab-backup` had no `--lock-wait`**, so a held lock made it fail
  instantly and skip the night. It could never fire while the weekly
  maintenance ran downstream of it; inverting the order exposed it.
- **The vault mount's credential task notified nothing.** Rotating
  `rclone_webdav_pass` wrote a new value and left the running rclone on the old
  one until a reboot. Cause of an 18-hour outage behind `active (running)`.
- **`rclone_webdav_pass` in the vault was stale since 2026-09-12**, which is
  what the missing notify had been hiding. The fix made it fail loudly on the
  next deploy, which is the correct behaviour and felt like a regression.
- **Three Kuma monitors created by hand had `resend_interval = 0`**, alone in
  the lab. Found by the repo's OWN posture assertion as soon as it could run
  without timing out — the gate did the audit's job.

## GitGuardian incident 37230384 — a false positive, and how it surfaced

Raised on PR #351, 2026-09-13. `ansible/roles/claude-code/tasks/vault.yml`,
detector **Generic Password**, on:

    pass = {{ rclone_obscured_pass.stdout }}

**It is a Jinja expression, not a credential.** The value lives in the vaulted
`rclone_webdav_pass`, is obscured by the preceding task without reaching an
argv, and is interpolated at render time. gitleaks, the repository's other
scanner, passed on the same commits.

**The line was NOT touched by that PR** — zero `pass =` additions or removals in
the diff. A `notify:` added four lines below pulled it into the diff hunk's
CONTEXT, and the scanner reads the whole hunk. Any future edit near that line
will raise it again.

**A `.gitguardian.yaml` does not help and should not be added.** That file is
read by ggshield, and this repository has no ggshield step in
`.github/workflows`; the check comes from the GitHub App, which is configured in
the dashboard. Committing the file would look like remediation and do nothing —
the exact shape this skill exists to find. The remedy is to mark the incident
*False positive* in the dashboard, which retains the signature; `Unmonitor` does
not close incidents.

**The check does not block.** `main` carries no branch protection, so the PR was
MERGEABLE with the check red (`mergeStateStatus: UNSTABLE`).

**One diagnostic lesson worth keeping.** The main session first deduced, with a
coherent argument, that the trigger was a `-n "$USER":"$PASS"` string it had
just written into `docs/05-services/transmission.md`. That was wrong, and it had
said it would wait for the dashboard detail before editing — which is what
stopped it from rewriting the wrong file. **A plausible cause is not a located
cause.**

## Declined — added 2026-09-13, do not re-propose

- **An assertion on Transmission's s6 stop hook.** The image's own
  `svc-transmission/finish` runs `transmission-remote -n "$USER":"$PASS" --exit`
  on every container stop, and `/proc` has no hidepid. It is real, it is
  **accepted**, and it is documented in `docs/05-services/transmission.md`.
  It is NOT fixed (both files are inside the image; an edit is undone by the
  next pull) and it is NOT asserted, deliberately: **a check that pins the
  contents of an upstream script is class C86** — a value restated to freeze an
  upstream default — and fires on any benign refactor. A permanently-red
  monitor is worse than a written acceptance. What would re-open it is written
  in the doc: Transmission reachable beyond the tunnel, or an untrusted local
  account on the host.
- **`hidepid` on `/proc`**, rejected on cost: netdata reads `/proc` for every
  container's metrics and would need an exemption, which is a larger change
  than the exposure warrants on a LAN-only host behind a VPN.
- **Moving the daily reports ahead of the 03:00 backup.** Proposed by the
  operator, declined with evidence and accepted: `disk` (2 s), `posture` (2 min)
  and `feed-digest` (2.3 min) take no restic lock and can starve nothing, and
  the disk timer's 07:00 is a documented choice — it reports *after* the backup
  so that "a night that filled the disk is reported with the consequences
  already in".
- **Moving `homelab-smart-test` into the weekly block.** Its own measurements
  forbid it: the scan runs four to eight hours at 3-5x read latency, and its
  schedule was already chosen to sit AFTER the backup for exactly that reason.

## Measured and rejected — added 2026-09-13

- **The 70 GiB backup growth as an anomaly.** It is the intended consequence of
  ADR-035: Radarr/Sonarr import into `library/`, hard-linked from `downloads/`,
  and that directory had never been backed up. 41 files, two TV seasons and
  five films, verified by inode. Restic read 418 GiB and stored 69.986 GiB —
  deduplication held. The path-set change is what broke parent-snapshot
  selection and forced the full re-read; it is one-off.
- **`ls -l <file>` on the rclone vault mount** prints `Input/output error` AND
  the correct line, on a HEALTHY mount. `stat`, directory listing, read, write
  and delete all work. Do not diagnose a broken mount from it — and do not
  assert on it.

## Instrument traps paid for on 2026-09-13 — carry these

**A `docker logs --since/--until` window in the wrong frame returns silence, not
an error.** `--since`/`--until` parse in host LOCAL time while `-t` prints UTC.
The main session queried a crash window in UTC against a container whose event
was logged at that same wall-clock in UTC and got nothing back, then nearly
recorded "the logs are gone". Logs reached back six days. **Find the signature
first with a grep over the whole log, and only then narrow the window** — a null
from a time window proves nothing about the window OR the data.

**`grep -c` over a repo counts text, not behaviour.** Two agents reported the
lab's `flock` usage as "none anywhere" and "one hit". The truth is four textual
occurrences — every one a comment or a line of prose — and **zero live
invocations**. Before reporting a mechanism absent or present from a grep count,
separate the call sites from the places that merely name it.

**An agent timestamp is not a measurement.** A report stated its host work
"finished 02:57" and that it had avoided the 03:00 window; the run ended at
02:19. Nothing downstream depended on it, but it is a reminder that a subagent's
narrated times are prose. Re-measure any timing that carries a conclusion.

**A one-sided comparison cannot see the event it was written for.**
`homelab-health.sh.j2:719` asserts `heal_n -lt heal_m` — fewer containers
examined than declared. The failure it needed to catch produces `checked 30 of
29`, one *more* than declared. The assertion is not weak, it is pointed the
wrong way, and it passed through two real collisions. When writing a floor, ask
what the defect's signature actually looks like before choosing the operator.

**A poll rate is an instrument and it needs its own control.** `security`'s
first `/proc` sweep at 50 ms missed a target process **six times out of six**; a
last-pid-counter sweep at 500 Hz caught it twice in 90 s. A null result from the
first would have closed C26's argv axis wrongly. **A sampling sweep must prove
it can catch a known-present instance before any null from it is believed.**

## Closed by the run of 2026-09-13

- **C26 — a credential reaching a command line, a child process, a scheduled job
  or a trace.** All four axes closed. The argv axis was swept from both sides
  independently and **2 of its 3 instances are in the argv the IMAGES ship**, a
  sub-space no previous sweep had enumerated and that no grep over this repo can
  reach: `transmission`'s own s6 stop hook runs
  `transmission-remote -n "$USER":"$PASS" --exit` on **every container stop**,
  and `/app/blocklist-update.sh` carries the same form (inert only because
  `blocklist-enabled: false`). The third is this repo's own
  `ansible/roles/deploy/tasks/pihole.yml:117`, where `sh -c` expands
  `$(cat /run/secrets/…)` **inside** the container and execs
  `pihole setpassword <plaintext>`. `transmission.yml:55-70` documents this exact
  defect and fixes itself with `TR_AUTH`; 6 of 7 sites use the env form, that one
  does not.
- **C87 — a hand-made artefact that outlives its operation.** Closed with a
  stated depth AND an unbounded-depth cross-check that agreed instance for
  instance. The method is the keeper: **state the depth limit as part of the
  cardinal**, because an unstated depth limit is how a directory bound gets
  mistaken for a property bound.

## Measured and rejected — added 2026-09-13

- **The heal timer self-overlapping.** Refuted three ways: p50 0.8 s against a
  120 s period, `Type=oneshot` (systemd merges the job rather than starting a
  second), and 8 977 runs in 14 days with no instance. The 513 "missing" ticks
  are `PartOf=homelab-services.target` doing its job across a reboot. **Do not
  re-raise the 2-minute period as a cost** — 1.05 s CPU per run is 0.9 % of one
  core per day.
- **`copytruncate` + `rotate 0` on the Traefik access log vs the redactor's
  busybox `tail -F`.** The run's best lead, refuted on the machine: output
  continued across the 22:00 UTC truncate at 4 199 lines, in the busiest hour.
- **Transmission vs the `*arr` importers.** Two independent serialisations, one
  of them this repo's own hard-link mount layout. Not a race.
- **`stop_grace_period` as a general gap.** 5 of 32 declare one and 27 sit on the
  10 s default, but a 32-container × 14-day log sweep returns exactly one hit.
  No extension proposed.
- **A15, open since 2026-09-11, RESOLVED and not a defect — but read the whole
  history before quoting this, because the resolution was WRONG TWICE before it
  was right.** `MANAGE_BUILTINS=no` and `delete_chains` is ufw-scoped, so a
  `ufw reload` destroys neither `DOCKER-USER` nor the `f2b-*` chains: **no ban is
  lost.** That half always held. **Corrected 2026-09-26 (fifteenth run): the
  CHAINS survive, the JUMP does not.** `after.rules` declares `:DOCKER-USER - [0:0]`,
  which flushes that chain on every restore, and the `-j f2b-nextcloud` /
  `-j f2b-vaultwarden` jumps live in it. The bans stay listed and stop being
  enforced until fail2ban restarts — see the handler entry in the 2026-09-13
  shipped list.
  - The half that did not: this bullet once claimed the 8 `DOCKER-USER` rules are
    **re-appended** per reload, evidenced by reading 8 rather than 16 "across two
    `sudo ufw reload`s on 2026-09-13". **Those two reloads never happened** — a
    `zgrep` over the whole retained rotation returns nothing — so the control
    never ran and the claim was WITHDRAWN on 2026-09-19 (third run).
  - **Settled on 2026-09-19 (fourth run, key `staleness`) by the experiment the
    withdrawal asked for**, run in a throwaway `unshare --net` namespace with the
    host's own nft binary: three identical `iptables-restore -n` over a chain
    re-declared `:CHAIN - [0:0]` leave **2 rules, not 6**; a manual `-A` makes 3,
    which is the positive control. **A re-declared user chain is flushed, not
    appended.** Corroborated live: the `DOCKER-USER` counters match 7.5 days of
    uptime, so no reload has happened since 2026-09-11 23:37 — the live 8 is not
    the control, the experiment is. **C74's last open mechanism closes.**
  - Residual worth carrying: the chain has therefore not been compared to its
    source file for 7.5 days, and nothing compares it.

## Closed by the run of 2026-09-12

- **C10 — a credential store readable beyond its service.** CLOSED, 29/29
  runtime stores and 32/32 write sites, 0 instances. The two restic repository
  passwords that reopened it on 09-11 are `0400` today, and the derived gate
  `world_readable_secret_writes()` was **restored by `b761450`** — the register's
  claim that it had been deleted with the defect was one commit out of date.
- **C86 — a value restating an upstream default in order to freeze it.** CLOSED,
  363/363 over five domains. Three confirmed instances, none exploitable today,
  and all three are worth remembering as shapes rather than as defects: a *pure*
  restatement with zero policy content (sshd `Ciphers`), a block copied
  "verbatim" from a binary that has since moved (the netdata AppArmor profile),
  and a default restated minus one element (`ansible.cfg` `ssh_args`, minus
  `-C`, costing 33.7 % on every module payload).

## Measured and rejected — added 2026-09-12

- **`/mnt/data/services/wireguard/wg0.json` as a finding.** It does hold the live
  WireGuard server private key and four client private keys — verified. It is
  also `0640` under a `0700` parent on the encrypted volume, and documented in
  **14 places**, including a runbook that instructs the reader not to open it and
  a service page recording the rollback copy deliberately. A known, documented,
  root-only artefact is not an audit finding. Do not re-report it.
- **The three `acme.json.bak*` files as an exposure.** 37 certificate+private-key
  pairs, three of them for names retired long ago (`acmetest`, `capdroptest`,
  `notes`), and no reference anywhere in the repo — but `0600` root-only on LUKS.
  Worth one `state: absent` when something else touches that role; not worth a
  cycle of its own.
- **Reopening C27 instead of minting C87.** Proposed by `ansible-deploy` on the
  reasonable ground that "a live object with no declaring source" is C27 read
  backwards. Rejected: C27's property presumes a repo counterpart to differ
  from, and these artefacts have none.
- **Minting "a rejection list drawn from memory rather than from the tool's
  option surface"** (27 "Alternatives considered" sections across 24 of 34 ADRs).
  The agent that found it argued against minting it, and the main session
  agrees — an ADR rejecting an alternative because "X cannot do Y" is C01's
  property on a new stratum, not a new property. It is recorded in C01's space
  as the stratum to sample first.

## Declined — hardening

Live kernel patching, an IPS/reputation layer, a forward-auth SSO portal, user
namespace remapping, and the kernel audit daemon. All assessed, all declined.

The remaining containers with an elevated capability, and the remaining
writable root filesystems, are **structural** — they were examined one by one
and cannot be removed without breaking the service. Do not re-report them as
findings.

Additional fail2ban jails for recently added web forms: rejected after
measurement — the existing jails show zero failures and zero bans since they
were deployed.

**rkhunter is gone, deliberately.** It had been installed since the beginning
and had never run once on either host — no log, `CRON_DAILY_RUN=""`, signatures
frozen at 2026-05-10. It was removed rather than scheduled on 2026-08-16:
scheduling it would mean adding an alerting path and a false-positive budget for
machinery nobody asked for, next to an already-declined reputation/IPS layer. Do
not propose reinstalling it. `roles/security/tasks/audit.yml` records how to go
the other way if the decision ever changes.

**The distribution's `lynis.timer` is masked, deliberately.** It ran daily at
5 min 45 s of CPU for a report nobody read, and its freshness made the weekly
report script's only guard unable to fire. Our own weekly run is the one with a
reporting path attached. Do not report the masked timer as a gap.

**`errors=remount-ro` on the ext4 volumes was raised and deliberately left
alone** on 2026-08-16. Both volumes are on `Continue`. Turning a data volume
read-only mid-incident on a host serving media and backups is a real trade-off,
not an obvious win, and it deserves its own decision rather than riding along
with an instrumentation change. Raise it as a decision if you raise it at all —
not as a finding.

## Declined — supervision

- **External supervision of the main host.** Every dead-man's switch terminates
  in a push monitor running on the very machine it watches. The gap is real,
  confirmed, and the operator does not want it closed that way.
- **A timed restore drill.** The existing drill record stands as it is.
- **Drift detection between the two hosts.** They are provisioned by different
  roles and nothing checks that the second keeps up. Verdict: too little
  configuration involved to be worth machinery.

## Declined — backup scope

- **Dumping the media services' metadata databases.** They hold play counts,
  watch and reading progress, shelves and query history — a rescan rebuilds all
  of it. The media files themselves are covered, which is what matters. This is
  a decision, not an oversight: do not re-audit it.

## Measured and rejected

- **Expiring the frozen snapshots left by obsolete path sets.** Grouping the
  retention policy by host would drop them, but deduplication already shares
  their chunks. Not worth a repository-wide prune, still less on the append-only
  offsite copy. **Declined four times; a fifth proposal needs a new CONSEQUENCE,
  not a new number.** The figure this bullet carried undated — "1.218 GiB of 343,
  i.e. 0.35 %" — is superseded: the 2026-09-18 measurement is **71.7 GiB** of a
  414.4 GiB raw repository, and the operator's arbitration that day priced it at
  ~70 GiB. A 58x gap, in the only part of this file that carried no date. The
  decision is unchanged; the number was wrong and is removed rather than
  restated, because the decision never rested on it.
- **Memory limits on containers.** The absence is real. Adding them would
  create an OOM kill that does not exist today: working set is well under
  capacity and memory pressure sits near zero over a fortnight.
- **The DNS-over-HTTPS connection investigation.** Closed with no action — the
  upstream retires connections on a timer, and every per-query rate computed
  during the investigation turned out to be an artefact. Do not reopen.

## Tooling constraints, not preferences

- Uptime Kuma is **v2**. The widely cited automation tooling is v1-only and does
  not speak v2; monitors are entered by hand in the web UI. Do not propose it.
- **No git worktrees for work that DEPLOYS.** Work in the operator's directory,
  on their branch, and announce any branch switch — a checkout changes what
  their next deploy ships. Documentation-only work may use one; the operator
  asked for that explicitly, and there the worktree protects the shared tree
  rather than endangering it.
- **The operator deploys from the PR branch, BEFORE merging** — so that anything
  the deploy turns up becomes another commit on the open PR instead of a second
  PR. Never sequence instructions as merge-then-deploy. It earned its keep the
  same evening: masking a timer left a unit permanently failed, and the fix went
  onto the branch before anything was merged.
- **Ansible commands are run from `ansible/`, on ONE line.** `ansible.cfg`
  already sets the inventory, so `-i` is never needed, and the playbooks live in
  `playbooks/`. Multi-line commands break the operator's copy/paste.
- The photo service's version pins are explicit and deliberate; its migration
  is one-way. Do not propose bumping components independently.

## Deferred, not declined

- **Marking the internal container network as internal.** Correct in principle;
  two services currently reach out through it and would break. A real piece of
  work to be scoped, not a quick fix, and not an audit finding to repeat.

- **Moving the audit register out of the public repository.** `classes.md` and
  `settled.md` are **658 KB** — measured 2026-09-19, fifth run; this line said
  "~460 KB" for long enough that the figure understated the argument it exists
  to make by 43 %, and the figure IS the argument — describing one installation
  in more detail than anything else here: its containers, paths, schedules,
  failures and accounts.
  Raised during the privacy pass of 2026-09-13 alongside the MAC address and the
  LAN topology, which were fixed; this one was not, and the difference is that
  the register is also the engineering log that gives the repository its value.

  **The operator's decision, 2026-09-13: it stays where it is WHILE THIS WORK IS
  ONGOING.** That is a condition, not a verdict — which is why this sits here and
  not under Declined. Do not re-propose it run after run; do raise it once when
  the condition changes, i.e. when the audit cycle stops being active work.
  Whoever raises it then should bring the three options as they stood: leave it,
  move it to a private repository, or sanitise it the way the rest of the repo
  was sanitised.

---

## Closed by the run of 2026-08-16 — proven, not assumed

The 2026-08-15 table is retired: every line in it is resolved, and the four
items that run left owed to its successor were confirmed **on the machines**,
from the live artefact rather than the commit log.

| Owed item | Proven how |
|---|---|
| Memory and swap in the health push | The pushed message now reads `cpu 41C, / 18%, /mnt/data 17%, mem 4705Mi free, swap 52%, dns ok`. Read from the monitor, not the template. |
| Dump assertions on a real nightly run | The five `check_dump` assertions and the Immich freshness guard all fired at 03:00:38, each logging a real byte count. The dumps are in the snapshot with matching sizes and intact terminators. |
| The digest's message carrying real counts | Sends `20 entries summarised`; it was still the constant `OK` on 08-15. |
| Git service encryption key, restore-runbook service names, capped cloud-service log, recreated swap file | `SECRET_KEY` empty in `app.ini` with only `SECRET_KEY_URI` populated; service names checked against compose; kernel took the full 4 GiB swap file. |

Also established that day, and not to be re-derived: both hosts are
**byte-identical to `main`** (12/12 verbatim artefacts by sha256, 8 templates
structurally identical); the offsite host's `toolbox` role, unreachable since
2026-07-19, finally converged at 16:02; and the offsite backup path came back
unaided after a reboot.

**The swap threshold: keep 85 %, but the 53 % figure was misread.** Occupancy
sat at 53 % all through 2026-08-16 and was described here as a steady state
projecting to 59–64 %. That reading is **wrong**, and the evening of the same day
disproved it by accident: an `apt upgrade` restarted the Docker daemon at 21:37,
all 28 containers came back, and swap fell to **3 %**. So 53 % was not an
equilibrium but cold pages accumulated since the previous restart — long-lived
container memory that had simply never been touched again.

The conclusion survives, the reasoning does not. Swap is cold parking rather
than thrashing (+6 pages in, 0 out over 60 s; 20-day averages of 2.9 / 5.9
KiB/s), so **keep 85 %**. But the recheck around 2026-08-30 now starts from 3 %
after a known restart, which makes it a real measurement of the refill rate
instead of a reading of an unknown accumulation. Do not quote 53 % as a baseline.

## Measured and rejected — added 2026-08-16

- **Excluding the metrics store from the nightly backup.** 1.9 GB at 380 MiB/day
  of churn, roughly half the nightly delta. Buys ~108 s of copy time and no
  space that is needed: the offsite copy grew 7 GB in 35 days.
- **Kernel RCU stall messages.** 226 over 14 days, 204 of them at 21 jiffies
  (~84 ms), maximum 85. Informational on a preempt kernel. Not a defect.
- **Thermal and hardware margin.** `throttled=0x0` on both hosts — sticky bits,
  so never throttled or under-volted in 19 days. Zero USB, ext4, I/O or OOM
  events in the retained journal. Do not re-audit without a new symptom.

## Two agent claims that did not survive verification

Recorded because the next run will be tempted by both.

- **"The Nextcloud healthcheck is a façade that keeps its monitor green."**
  Refuted. The Kuma monitor is `type=keyword` on
  `"maintenance":false,"needsDbUpgrade":false` — it goes red on exactly the
  state alleged to slip past. Only the container's own `curl -f` cannot fail in
  maintenance mode, and nothing acts on that column: the heal timer triggers on
  exits, not on health. Cosmetic.
- **Kernel ring-buffer line counts.** An agent reported 16 334 retained lines,
  74 % of them repeaters. That is `journalctl -k`, not `dmesg`. The real ring
  holds **904 lines / 128 KiB**, of which 646 are `[UFW BLOCK]` and 623 are the
  router's IGMP query. The wrap is real — a 21.6-hour window against 19 days of
  uptime — but journald is **persistent**, so nothing is lost. The defect is the
  documentation line pointing at `dmesg`; use `journalctl -k -b`.

The lesson generalises: check which instrument produced a number before
believing what it implies.

## One operational note, learned the hard way during the #123 repair

A raw `cp` of a WAL-mode SQLite file is **not a backup**. The first copy taken
of the Forgejo database captured the `.db` alone while a 4 MB `-wal` sat beside
it, so everything since the last checkpoint was missing — and it looked like a
complete backup, right size, right name. Use `sqlite3 ".backup"`, which merges
them, and check `integrity_check` on the result. The nightly script already
does this correctly; hand work is where it slips.

---

## Findings from the run of 2026-08-16

All nine are tracked. Verify them **gone** rather than rediscover them, and
remember that merged is not deployed and deployed is not proven.

| # | Finding | Status |
|---|---|---|
| #123 | Forgejo mirror dead 22 h behind a healthy container; the `SECRET_KEY` fix sealed its remote address | **fixed and verified** — mirror level with `main`, both HEADs `881005b`, 0 decrypt errors since. Repaired by clearing the undecryptable blob so Forgejo's own recovery branch could re-read the address from git config; the settings form **cannot** do it, it 500s on the same decrypt. See the issue for the sequence. |
| #132 | Nothing detects a mirror that stops mirroring — follow-up to #123 | **fixed in main, pending deploy** — and the check the issue proposed was **impossible**: `mirror.updated_unix` moves on every ATTEMPT (00:56 UTC in the 03:00 dump taken four hours into the outage), and Forgejo records no last-successful-sync at all. `next_update_unix` is the real signal: it only advances on completion, so it sat 2 h 30 in the past and sinking during that same outage. |
| #124 | Vaultwarden's whole `environment:` block shadowed by a May `config.json`, three settings inverted | **fixed and verified** — three keys removed, icon probe returns the built-in fallback with zero outbound fetches. A posture assertion now compares the container's environment against the file it reads, and names the three keys exactly when replayed against the pre-fix backup. Deploy idempotent (`changed=1` then `0`). |
| #125 | Every re-downloaded VPN client config carries Cloudflare DNS; split DNS dies on a re-paired device | **fixed** — all four clients now serve the Pi-hole address in the configuration a device would download, `wg0.conf` byte-identical throughout. Applied as a direct SQLite `UPDATE`, **around** the API, because of #138. The issue's IPv6 aside was wrong: clients do have ULA v6 addresses. |
| #126 | Three restore procedures still say `stop` where the heal timer resurrects | **fixed** — the sweep found **eleven** sites across nine files, not three. Also corrected the issue's premise: the logged resurrections are miniflux crash-heals, not stopped containers, so the danger is conditional on the image's SIGTERM handling — which is exactly why a runbook cannot use `stop`. |
| #127 | Truncation floor at 0.04 % of the dump, and a push that sends a constant | **fixed and deployed**, idempotent. Content assertions replace the floor; the push carries restic's own summary. `quick_check` alone would have been a **regression** — a zero-byte file passes it — so the SQLite branch also asserts the database holds tables. Real 03:00 run still unobserved: #137. |
| #128 | Traefik sees all VPN clients as one gateway address; `vpn-only` subnet rule dead, `rate-limit` one bucket | open |
| #129 | Peer-revocation runbook reads a file frozen by the v15 migration | **fixed** (PR #140) — listing now queries `clients_table`; revocation section gated on #138, since revoking is itself impossible. The four commands were re-run from another session before closing: `docker exec` works without `sudo`, which the emergency stopgap depends on. |
| #130 | README understates the public perimeter; swap documented at half its size | **fixed** (PR #142) — figures re-measured on the hosts: 8 GB board (7.7 GiB usable), 4 GiB swap, offsite is the retired 4 GB board. |
| #131 | Empty strings in the example override working defaults; two bind-mounted configs without a restart handler | **fixed and deployed**, `changed=0` with `skipped` 32→33 — the increment is the new assertion skipping, which is what proves it is there. Sweep found these three keys were the only collision. |
| #137 | The backup assertions and summary push are proven on fixtures only — follow-up to #127 | open |
| #138 | wg-easy cannot write its own database: adding or **revoking** a peer fails behind a healthy container — found via #125 | **open, do at the machine.** Closed by mistake on 2026-08-16 and reopened the same evening once the machine was checked: `/mnt/data/services/wireguard` is still uid 1000 and `docker exec wg-easy touch` still returns `Permission denied`, so revoking a VPN peer through the UI remains impossible. The `wg set … remove` stopgap on the live interface still works, but does not survive a container restart. #144 fixed the identical defect for three other services with the same one-line `chown`; wg-easy is excluded because the first successful write regenerates `wg0.conf` and runs `wg syncconf`, and that interface is the only path to the host. |

Still open and still cosmetic: one orphaned anonymous volume (~48 MB) from a
first container start. Remove by hand, never with a broad prune.

## Findings from the SECOND run of 2026-08-16 (evening)

Re-run at the operator's request, three hours after the morning campaign closed.
Baseline was clean — 0 failed units, 28/28 containers healthy, 31 monitors green
— and it found twelve things anyway. All are tracked in #144, #145 and #146, all
three merged, deployed and verified the same night.

| # | Finding | Proven how |
|---|---|---|
| #144 | Vaultwarden, Traefik and immich-server run as root **without `DAC_OVERRIDE`** over data directories owned by uid 1000, so none can create a file. Vaultwarden's vault survived only because its `-wal`/`-shm` predated the capability drop by six days | `docker exec … touch` → `Permission denied` on all three, with a control returning a *different* errno elsewhere. Replayed on the host: root **with** `dac_override` reads the base, root **without** returns `attempt to write a readonly database (8)`. Fixed; `touch` now succeeds |
| #145 | Transmission's healthcheck was `curl` with no `-f` — 401 → rc=0, nonexistent route → rc=0, only a closed port failed | Replaced with `transmission-remote`, which authenticates and enumerates: rc=1 on a bad password, rc=1 on an unreachable daemon |
| #145 | The weekly lynis guard could never fire: the **distribution's own** `lynis.timer` runs daily and kept the report permanently fresh | 14 runs in 14 days, 5 min 45 s of CPU each. Freshness now asserted on the report's mtime; the redundant timer masked |
| #145 | `MIN_INDEX=65` against an index measured at **74 on 5/5 samples, zero variance** | Ratchet on the best index; replayed across seven states — 66 after 76 now reports DOWN where the old code said UP |
| #145 | `Pi health` **detected problems and notified none**: the restart check is true for exactly one run, `maxretries=1` makes that PENDING, and PENDING does not notify in Kuma v2 | 60 days of heartbeats: one real detection (`claude-remote-control.service 7->8`, status=2), zero notifications. The only two DOWN beats are the dead-man's switch. Now held across a second beat; verified to emit on beats 1 and 2 and stop |
| #145 | A **stale dump** could be snapshotted: a failed `sqlite3 .backup` leaves its destination byte-for-byte intact | Needs a run that *aborted* — 103 `started` against 102 `completed`. `rm -rf "$DUMP_DIR"` before the `mkdir` |
| #145 | The posture check never asserted `Config.User`, though nine services declare one | Asserted where compose declares it; all nine match |
| #145 | Two Ansible loops rebuilt the orphan `internal` network **on every deploy** | Removed by hand at 14:12, rebuilt at 14:51. Both loops now name `proxy` only |
| #145 | Eleven Docker secrets had **no restart handler** — a rotated credential is never read while the deploy reports changed | `forgejo_secret_key` ran 17 h 44 on the old key after being written. One handler per consumer, mapped from the running containers' mounts |
| #145 | rkhunter installed and **never run** — no log on either host, `CRON_DAILY_RUN=""`, signatures frozen at 2026-05-10 | Removed rather than scheduled |
| #145 | Journal retention 14.3 days against 19 days of uptime, at a 200M cap sitting at 199.1M; nothing watched the **filesystem**, only the disk | Cap raised to 500M (the cap governs deletion, not writing). ext4 superblock counters now in the daily report: `disk 17%, hdd 53C, ext4 clean` in the message the monitor received |
| #146 | Three `## Restore` blocks contradicted the runbook on the three databases with no second copy, one of them pointing at a path deleted after every backup | `ls /mnt/data/backups/dumps/` → `No such file or directory`. All three now defer to the runbook, which is why `immich.md` had never drifted |

Two things are still **live** after this campaign, and the next run should verify
them on the machine rather than trust their tracking state:

- **wg-easy still cannot write** — see the #138 row above. That issue was closed
  by mistake and reopened once the machine was checked, which is the whole
  argument for verifying against the running system: the tracker said done, the
  filesystem said `Permission denied`. Its exclusion in the posture assertion is
  the only one there, and it disappears with the fix.
- **The orphan `internal` network is gone**, removed 2026-08-22. It had survived
  since 14:51 on 2026-08-16 — the timestamp of the Ansible loop that rebuilt it
  39 minutes after the first hand removal, before that loop was fixed. Nothing
  recreates it: no Ansible task declares a bare `internal` network, and Compose
  declares `internal` without `external`, so it creates the project-prefixed
  `homelab_internal` instead. Identified unambiguously before deletion — the
  orphan carried **no Compose labels and 0 containers**, against 12 containers
  and a full label set on the live one — and `homelab_internal` was confirmed
  still carrying its 12 afterwards.

### Method traps, all paid for the same evening

Worth more than the findings, because each one silently produced a wrong answer.

- **`docker top -o uid` returns nothing.** A sweep built on it reported *every*
  container as mismatched. Derive container uids from `Config.User`, which also
  surfaces the image's own `USER` — that is how Forgejo reads `1000:1000`.
- **busybox `test -w` lies for uid 0.** It answered "writable" for wg-easy.
  Only `access(2)` and host-side permission arithmetic are trustworthy.
- **`systemctl mask --now` leaves the unit `failed`**, so `systemctl --failed`
  stops being empty. Stop first, mask second — measured both orders.
- **A looped Ansible task counts as ONE `changed` in the PLAY RECAP**, not one
  per item. Three chowns plus a template read as `changed=3`, and inferring "the
  template was skipped" from that was wrong.
- **`apt upgrade` is inherently non-idempotent.** A `changed=1` whose only task
  is that one is not a defect. It also restarts whatever links against what it
  upgrades: on this evening it took `docker-ce` and the Kerberos libraries with
  it, which bounced all 28 containers and **killed the running play's SSH
  connection mid-task**. Narrow the tags when the change does not need `base`.
- **A 24-hour window that straddles the tail of a finished event reads as an
  incident in progress.** This one produced a headline finding that was simply
  false, so it is the most important entry here.

  The network agent reported, and the main session repeated twice, that a
  Nextcloud client had been stuck on a WebDAV lock "since at least 2026-08-12" —
  1036 responses of HTTP 423 in 24 hours, one path, ongoing. The count was real.
  The conclusion was not: the whole of it fell on 2026-08-15, and the episode had
  **ended at 20:24 UTC that day**, roughly 26 hours before the audit ran.

  The full retained log, which goes back to 08-12, shows ~700 an hour for three
  days and then nothing at all. It was a client retrying a single Obsidian note —
  49 777 DELETE and 4 977 PUT — and the deletion eventually succeeded: the file
  and its parent folder are gone, Redis holds no lock key, and a targeted
  `files:scan` reports zero discrepancies.

  So: **`--since <duration>` establishes a rate, never a present tense.** Always
  bucket by hour across the whole retained log before writing "ongoing", and
  read the LAST occurrence rather than the total. Note also that
  `docker logs -t` prints UTC while `--since` parses in host local time, and that
  the retention shown by `--since 24h` is the clip, not the actual window — take
  the first line without `--since` to learn how far back the log really goes.

### Two agent claims that did not survive verification, and one of mine

- The backup agent gave the stale-dump window as general. It is **conditional on
  an aborted run**: the cleanup sits *before* the `exit 1`, so a night that fails
  its assertions still empties the directory.
- The network agent attributed 87 rate-limit rejections between middleware and
  backend. **My own instrument for checking that was wrong** (`"-"` appears in
  several columns of the access log), so only the total and the absence of any
  successful `/image_proxy` request survive. Those belong to #128.
- Claiming "the first `docker compose down` leaves the vault read-only" (#144)
  was **too strong**. A full daemon restart happened that evening before the fix
  and Vaultwarden came back intact, same inodes: a Docker-initiated stop does not
  make it close SQLite cleanly. The fix stands — the trigger depends on the
  image's shutdown path, which can change at any version bump — but the urgency
  did not. The correction is recorded on the issue rather than edited away.

### The three patterns behind them

Worth more than the list, and worth checking for new instances next time.

1. **The setting is applied, the state is not.** A declared value never reaches
   the running object because something persisted earlier wins — a service's own
   config file, a database row seeded only at creation, a bind-mounted file with
   no restart handler, an empty string in an example that overrides a working
   default. Four instances this run (#124, #125, #131).
2. **The check cannot fail.** A threshold three orders of magnitude below what
   it guards, a push carrying a constant, a monitor probing the wrong side of a
   NAT (#127, #128, and the Transmission peer-port monitor). The verification
   layer is consistently thinner than it presents.
3. **Yesterday's fix, today's breakage — and partial sweeps.** The `SECRET_KEY`
   correction killed the mirror; the restore runbook was corrected in three
   places out of six; the swap batch left the old size in two files. **Every
   correction should end with a sweep for siblings**, which is how two of this
   run's findings were found at all.

   #138 is the sharpest instance and arrived after the table above was written.
   `cap_drop: ALL` is correct hardening and stays. But it takes `DAC_OVERRIDE`
   away from a container running as root, which then falls back under the
   permission bits it used to bypass — and one service's data directory is owned
   by another uid, so it can no longer create files there. Its database has been
   read-only ever since, which means a VPN peer cannot be **revoked**. Nothing
   showed it: the container is healthy and the tunnel works, because the running
   interface never writes.

   Worth generalising for the next sweep: **after dropping capabilities, check
   what each container still needs to WRITE**, not just that it still starts.
   A service that only writes when the operator asks it to will look healthy
   indefinitely.

### What the evening run added to them

Pattern 2 **dominated**: five of the twelve findings were controls that could
not report the failure they name. After five the same morning, that is ten in a
day, and it is the single most productive thing to hunt here.

The generalisation above **paid immediately** and is the reason #144 exists at
all: it was written down in the morning, and the evening's security agent used
it as a search key to find three more services in the same state, one of them
the password manager. **An audit does not find what it does not yet know to look
for** — which is most of the answer to why successive runs keep producing
findings, and why writing the generalisation down matters more than fixing the
instance.

A fourth pattern is now visible, and it is the uncomfortable one:

4. **The correction creates the next finding.** The `SECRET_KEY` fix killed the
   mirror. `cap_drop: ALL` made three services unable to write. #126's sweep
   from `stop` to `compose down` made #144's failure *more* likely to trigger.
   The orphan network was removed by hand and rebuilt 39 minutes later by the
   automation nobody thought to check. Masking a timer left a unit permanently
   failed. **Every fix deserves the same question as every mechanism: what does
   it now claim that it does not do?** Deploying before merging is what caught
   the last of those.

### A note on scope, for the next run

The dominant pattern is **enumerable rather than samplable**, and three
consecutive runs have sampled it. Measured on 2026-08-16: 18 declared
healthchecks over 42 services, 88 places where a failure can be swallowed
(`|| true`, `2>/dev/null`, `failed_when: false`, `creates:`), 31 monitors, and 5
hard-coded thresholds in the health and posture scripts — roughly 140 objects.
Sampling that space will keep returning findings indefinitely; enumerating it
once ends the pattern. Consider a bounded exhaustive pass instead of a fourth
general audit.

It will not cover defects of **absence** — nothing watches the Nextcloud cron's
freshness, and nothing noticed a WebDAV lock that produced 54 754 rejected
requests over three days in August and then resolved itself unremarked, in
either direction — nor the drift each deploy creates. Those stay the audit's
business. (That episode was also misreported as ongoing while it was already
over; see the 24-hour-window trap above.)

---

## Closed between 2026-08-17 and 2026-08-19 — three days of follow-up runs

The 2026-08-16 table above is now fully resolved except the four issues listed
at the end of this section. Everything here is merged **and deployed**; verify
it gone rather than rediscover it.

| # | Finding | Closed by |
|---|---|---|
| #152 | `rp_filter` declared twice in the sysctl template; the strict value silently won and the kernel dropped VPN client packets | PR #167 — single declaration, loose value; drops stopped |
| #153 | wg-easy's database was world-readable and held the interface key, four client keys and the admin hash | PR #163 — 0644 → 0600 |
| #155 | The offsite host was missed by two sibling sweeps: the distro `lynis.timer`, and a SMART guard that could report "SMART ok" without reading SMART | PR #166 — both sweeps completed on the second host. This is pattern 3 (partial sweep) caught once more; **check both hosts by default** |
| #156 | Five more controls that could not report the failure they name: netdata healthcheck, empty-secret assert, posture count, Lynis retries, DDNS failure branches | PR #170 — including "posture OK on 0 containers" and DDNS branches that could never execute |
| #157 | Three of eighteen certificates had no expiry watch, and a failed ACME renewal left no trace at all | PR #175 — `homelab-health.sh` now parses `acme.json` directly, 21-day threshold, 18/18 covered. Root cause of the blind spot: Traefik's WARN-level filter hides renewal logs, so a log-based watch was structurally impossible |
| #158 | A snapshot that missed its offsite copy was never retried, and the weekly check passed regardless | PR #173 — 7-day time-window filter; 18 snapshots had been at risk |
| #159 | Three database passwords could not be rotated, and the handlers made the no-op look like a rotation | PR #176 — see the rotation notes below |
| #161 | Four documentation statements that would mislead during an incident, out of 238 runbook commands checked | PR #165 |
| #162 | `it-tools:nightly` unrebuilt upstream for 185 days; Renovate cannot tell abandoned from current | PRs #162/#164 — ADR-024 now states an **exposure-based** drop condition; the original one measured the wrong thing |
| #168 | A failed `restic forget` was invisible to the monitor: retention stopped with the push still green | PR #171 |
| #169 | Thirty read-only probes had no `check_mode: false`, so a dry run guarded on output it never read | PR #172 |
| #137 / #174 | The backup assertions and the summary push, proven on fixtures only | Both closed on the real 03:00 runs — assertions fired with real byte counts, push carried restic's own summary, and the first night under the new offsite window was read before anything else |

### What the #159 rotation work established, and must not be re-derived

- **A deploy can rotate some secrets and not others.** Which is which is now
  written down in the repo, together with what the others need. Do not re-audit
  the question; read the doc.
- **The detection bug was a case mismatch** on `admin_token`, which is why the
  posture check could not see an unrotated secret. Fixed, and the posture check
  now makes a rotation that did not land report itself.
- **Password rotation must be verified through container-name probes**, not
  through `localhost` — a localhost probe succeeds against the wrong endpoint.
- **`knowledge/runbooks/rotate-a-secret.md` was wrong in three ways** and each
  was found only by running it: the step order, a missing `occ` step, and a
  required `notify_push` restart. The procedure is now correct; trust the file,
  not memory.
- Two live rotations were performed for real reasons: **Miniflux** (its password
  had been exposed in a `bash -x` trace) and **Nextcloud** (exposed in logs).
  Both completed and were re-verified. Not findings — history.

### New method traps, all paid for between 17 and 19 August

- **`docker logs --since/--until` parse in host local time while `-t` prints
  UTC.** Always suffix `Z`, and cross-check any total against an hourly
  histogram. This compounds the 24-hour-window trap recorded above.
- **`pihole setpassword` has no flags** and will happily take `--help` as the
  new password. Documented; do not "improve" the invocation.
- **The compose pull task always reads `changed` under `--check`.** It is not an
  idempotence defect and is documented as such.
- **A dry run is not free.** Two offsite tasks misbehaved under `--check` alone:
  one announced it would remount the backup disk, another aborted the play on a
  task check mode had skipped. Both fixed, but the lesson stands — `--check` has
  its own failure modes and they are not the play's.

### Still open going into the run of 2026-08-19

Four, and they are the only ones. Do not re-report them; do report anything that
makes one of them materially worse.

| # | Why it is still open |
|---|---|
| #128 | Traefik sees every VPN client as one Docker gateway address — `vpn-only` subnet rule dead, rate-limit one shared bucket. Needs local work |
| #138 | wg-easy cannot write its own database; a peer cannot be revoked. **Requires someone at the machine**: the first successful write regenerates `wg0.conf` and runs `wg syncconf` on the only interface that reaches the host |
| #154 | Neither ext4 volume is ever checked, and a weekly green timer checks nothing. Half doable remotely |
| #160 | `wg_easy_config` claims to enforce the VPN settings, cannot write, and would abort the deploy at step 4 of 12. Sibling of #138 |

---

## The run of 2026-08-19 — what it settled, and what it corrected

Fourth general audit. Baseline clean on both hosts: 0 failed units, 28/28
containers, 12/12 timers exited 0, 31/31 monitors UP. Twenty-three findings,
grouped into four issues — #177 (sweep residues), #178 (statements without
effect), #179 (push monitors), #180 (offsite tunnel, a decision).

### Two previously settled conclusions are now WRONG. Do not quote either.

- **"PENDING notifies nobody" is false.** PENDING escalates — with the wrong
  text. A push monitor at `maxretries=1` raises `"No heartbeat in the time
  window"` whenever the previous beat is not UP, and that raised beat is the one
  that notifies. Counted on notifying heartbeats: `Pi health` 4 alerts, 4 without
  the script's message; the monitors at `maxretries=0`, 6 of 7 kept it (the
  seventh is a genuine no-push case). And there are **two** monitors at
  `maxretries=1`, not three: `Pi health` and `DDNS`. Tracked in #179.
- **Swap is at 38 %, not 44 % and not 53 %.** The audit's own system agent
  headlined "~1800 MiB = 44 %" while citing its own cgroup measurement of
  1571.4 MiB in the same paragraph. Four instruments agree on 1571 MiB of 4095:
  `/proc/swaps`, `free -m`, `/proc/meminfo`, and the live Kuma push (`swap 38%`).
  Keep 85 % — the margin is 47 points, wider than previously believed. Both
  earlier figures were arithmetic errors on top of a conclusion that survived
  each time, which is now a pattern in its own right.

### Measured and rejected — added 2026-08-19

- **The whole secret store being world-readable.** Raised, investigated,
  refuted. The files are 0444 but the **directories** gate the path
  (`drwx--x--x` on `secrets`, `drwx--x---` root:docker on `docker/`); an
  unprivileged read is refused, with `/etc/shadow` refused in the same call as a
  control. The design is sound. What IS exposed is `/mnt/data/services`
  (`drwxr-xr-x`) — a different store, tracked in #177.
- **Transmission's empty-password branch as a present exposure.** The mechanism
  is real (the LSIO init disables RPC auth on an empty value) but impact today is
  zero: `rpc-authentication-required: true`, whitelist enabled, secret 128 bytes.
  It is a rebuild-from-example hazard, ranked accordingly in #177.
- **A read-data check against the offsite repository.** Never run, log complete
  back to 2026-05-14. Not proposed: it sits next to the declined restore drill.
- **The Lynis ratchet seeded at 73** rather than the 74 of #145. That single
  point is `malware_scanner_installed=0` — the arithmetic of rkhunter's
  deliberate removal. No action; recorded so 73 is not later read as drift.

### New instrument traps — three, and one of them was mine

- **`docker inspect .RestartCount` is inert here.** It reads 0 on all 28
  containers while the heal journal records 47 crash-restarts in 19 days. An
  audit concluding "nothing has restarted" from it would be wrong on every count.
  Use the heal journal.
- **mtime against commit date is a false drift instrument in this repo**,
  because deploying before merging makes deployed files legitimately older than
  their source commit. Nine artefacts read as drift until content was compared.
- **A permission error swallowed by `2>/dev/null` produced a wrong answer during
  the main session's own verification**: an unprivileged `grep` on the offsite
  WireGuard config returned nothing, which reads identically to "no Endpoint
  line". Re-run with `sudo`, it returned the hostname that the whole of #180
  rests on. The audit's own instruments are subject to the defect it hunts.

### Verified gone on the machines, not assumed

rp_filter (martians 213/day on 08-12, 49 on 08-17, last line 10 minutes *before*
the sysctl file was written, zero in the 44 h since; `TcpExtIPReversePathFilter`
frozen at 1653 across four samples). #158 and #168 on the real 08-19 run
("8 snapshot(s) offered… 1 new, 7 already there", zero offsite duplicates). The
cert parse, exhaustively: 18/18 `notAfter` values byte-identical to the leaf
served in a live handshake. The perimeter, probed from the offsite uplink with a
known-open port as control: everything else closed, no IPv6 anywhere.

### The pattern shift — the most useful thing this run established

**"The check cannot fail" is thinning.** Hit rate on the class this audit exists
to find: 5/5 on 2026-08-15, 5/12 on 08-16 evening, **4/23** now — and the new
instances are narrow (an `ext4 clean` over zero visited volumes, a cert block
skipped on a missing file) rather than structural.

**The dominant pattern is now the PARTIAL SWEEP**, five instances in one run:
#153 stopped at wg-easy, #155 stopped before the ext4 counter on the offsite
host, #161 swept documentation for existence and never for content, the
empty-secret guard stopped at 4 keys of 35, the cloud-init pin runbook covers one
host of two. The existing rule — every correction ends with a sweep for siblings
— is not enough. Sweep **both hosts and both axes**: existence *and* content.

Also worth carrying: roughly a third of this run's findings could not have been
found earlier. Three were created by fixes younger than 72 hours (pattern 4
again), and four required a search key minted between 17 and 19 August — the
file-mode axis from #153, and "where can a secret reach a log, a trace or an
argument list" from the two rotations of 08-19. The generalisation keeps paying
more than the instance.

### For the next run

The spaces that were genuinely **enumerated** this time came back clean: 28/28
healthchecks, 30/30 sysctls on both hosts, 18/18 certificates, the Ansible key
set in both directions, 19/19 bind-mount inodes against `/proc/<pid>/root`. That
is the third confirmation that enumeration ends a pattern where sampling does
not. Two spaces remain un-enumerated and are where the next yield is:
**file modes across both hosts**, and **the content of documentary claims** as
opposed to their existence.

---

## Follow-up of 2026-08-20/21 — the 08-19 run is fully shipped

All four issues the 08-19 audit produced are merged and deployed, each verified
on the machines and idempotent: **#177** (sweep residues, PR #181), **#178**
(statements without effect, PR #184), **#179** (push monitors, PR #183),
**#180** (offsite tunnel, PR #185). Plus **PR #186**, a CI fix unrelated to the
audit. **#182 stays open by design**: three `notify()` sites and the dump gate
are still proven on fixtures only, and their real runs are Sun 2026-08-23 05:00
and 06:00 and Mon 2026-08-24 00:42.

### One of MY OWN entries in this file was contradicted without being read

On 2026-08-21 I told the operator #128 was the best remaining remote-doable
issue, reasoning that SSH does not traverse Traefik so a bad rule is
recoverable. The reasoning is true and answers the wrong question. **This file
already classified #128 as "Needs local work", and that classification is
right.**

Checked afterwards, on the compose file rather than from memory: wg-easy and
Traefik are **already on the same `proxy` network**. The source address is not
erased by a boundary between them but by the *path* — VPN traffic leaves to the
host and re-enters through the published port, arriving as the bridge gateway.
Correcting that means touching wg-easy's forwarding rules, or changing what VPN
clients resolve and therefore the `AllowedIPs` in **every client configuration**.
Both touch the only route to the host; the second also needs every device
re-provisioned.

The lesson is not about #128. **Read the reason column before contradicting the
table.** An entry that says why something is open is load-bearing, and
re-litigating it from a plausible-sounding argument is exactly the failure this
file exists to prevent.

### A live break test was repaired by a mechanism nobody had enumerated

The #180 mechanism was exercised for real: the offsite peer's endpoint was
forced to an unroutable TEST-NET-1 address with an unattended rollback armed
first. The tunnel recovered in **under ten seconds — and not by the mechanism
under test**, whose 150 s gate was never reached and whose journal stayed silent.

```
+0s   endpoint forced to TEST-NET-1        (handshake 117s)
+10s  endpoint ALREADY correct, handshake still ageing at 127s
+20s  new handshake completed
```

The middle line is the proof: corrected **without a new handshake**, so nothing
on that host initiated it. WireGuard's **roaming** did — a peer adopts the source
address of any authenticated packet it receives, and the homelab initiated a
rekey to the endpoint it still knew.

**Before breaking something to test a repair, enumerate every mechanism that
could repair it.** Otherwise the test measures the fastest one, which may not be
the one being tested, and a green result reads as proof.

The test also chose the wrong scenario: breaking the endpoint while the home
address is unchanged is precisely the sub-case roaming covers. The target
failure — a home address *change* — remains unexercised.

### Settled by research, do not re-derive

- **Roaming does NOT recover a server address change for a client behind NAT.**
  Upstream states it directly (a moved server cannot reach the client, "it needs
  client to initial the connection"; `PersistentKeepalive` does not help), and
  RFC 4787 explains why: the NAT holds a mapping created toward the OLD address,
  and address-dependent or address-and-port-dependent filtering — the common
  consumer behaviours — drop packets from a source the internal host never wrote
  to. Only one direction of repair exists: **the offsite host must send first**,
  which reaches the peer and opens the return path in the same packet. So the
  re-resolve timer is **load-bearing, not redundant**, and it holds under any
  filtering behaviour because it never asks that NAT to accept an unsolicited
  source.
- **The offsite tunnel is split**, and that is what makes any re-resolution
  possible: the host's resolver is its own LAN router over `eth0`, AllowedIPs
  carry the homelab VPN subnet only. A full-tunnel client could not look the name
  up while the tunnel was down, and only detection would have remained.
- **Handshake age is a sawtooth with a structural ceiling**: 60 samples at 5 s
  gave p50 55 s, p90 112 s, max 122 s, never above 135 s — WireGuard's ~120 s
  renegotiation plus establishment, not a variable that drifts. The 150 s gate
  sits 28 s above it. A spurious fire rewrites the same address on an existing
  peer and changes nothing.
- **`ansible-galaxy role install` does not accept `--no-cache`**; only
  `collection install` does (checked against ansible-core 2.21.2). The response
  cache cannot help on a runner that starts empty — it is reusable only between
  the two invocations of one job.
- **Navidrome reads `ND_SCANNER_SCHEDULE`**, and an unknown `ND_*` warns about
  nothing. Check the boot log for `Scheduling periodic scan`, never the variable.
- **`deploy_services` with more than one service needs the JSON form**
  (`-e '{"deploy_services": "a b"}'`); the shell eats the quotes otherwise.
- **Credential stores are gated by DIRECTORY mode 0700**, not per-file modes,
  because SQLite recreates `-wal`/`-shm` with the process umask. Safe only
  because each of the five is bind-mounted by exactly one container and reached
  as the directory's own owner — no `DAC_OVERRIDE` dependency, so no repeat of
  #138.

### New instrument traps — four, three of them mine

- **`head -10` truncated a sweep and hid its only real result.** The sweep for
  the false "PENDING does not notify" claim reported clean on docs and templates;
  the one genuine instance was a comment block in `homelab-health.sh.j2`,
  asserting it about the very monitor #179 was changing. **Never pipe a
  completeness sweep through `head`** — cap the output, or count it, but do not
  truncate the evidence you are about to call complete.
- **A regex found 2 of 4 unsized tmpfs; the YAML parser found 4.** Structured
  files get parsed, not grepped, when the question is "how many".
- **The journal bounds the journal, not reality.** "1239 DDNS runs unchanged"
  reads as long-term stability; it reaches back 13 days. Cloudflare's own record
  answers properly — `created_on == modified_on == 2026-07-19` means the address
  has *never* changed. Ask the authoritative system, not the local log.
- **zsh command-substituted a backticked segment inside `git commit -m`**,
  silently emptying it. Write long messages to a file and `-F` them, and verify
  from the commit object rather than the exit code.
- Related, from the same evening: an unprivileged `grep` with `2>/dev/null` on a
  root-only config returned nothing, which is indistinguishable from "the line is
  absent". A permission error swallowed is a false negative.

### Still open going into the next run

Five, and four of them share a cause.

| # | Why it is still open |
|---|---|
| #128 | Traefik sees every VPN client as one gateway address. **Local work** — the fix touches wg-easy's forwarding or every client's `AllowedIPs`; already re-confirmed once, do not re-litigate |
| #138 | wg-easy cannot write its own database; a peer cannot be revoked. **Requires someone at the machine** |
| #154 | Neither ext4 volume is ever checked. **Half doable remotely**: the configuration change is remote, the verification needs a boot-time check or an unmount of `/mnt/data` — and `/mnt/data` carries wg-easy, so unmounting it removes remote access |
| #160 | `wg_easy_config` cannot write and would abort the deploy at step 4 of 12. Sibling of #138 |
| #182 | Scheduled, not blocked: the three unrun `notify()` sites and the dump gate fire on their own over 23–24 August |

The four blocked ones all touch **the tunnel or the disk** — the two things that
cannot be broken without someone on site. That is not a planning accident; it is
what remained after everything else was done.

Also open: **Renovate PR #88**, eleven image bumps, one of which is wg-easy.
It cannot be merged whole from a distance. Split the wg-easy bump out, ship the
other ten, and hold the VPN upgrade for a day with physical access.

## The run of 2026-08-21 — one pattern, four instances, and one finding that dissolved

The baseline was clean before the fan-out: zero failed units, 28 containers up,
eight `homelab-*` timers at exit 0, 31/31 monitors UP. The run still returned
findings, which is the whole argument for running it against a green surface.

One piece of baseline work paid for itself immediately: five containers had been
recreated at the same second the evening before, and checking `RestartCount=0`
and `OOMKilled=false` **before** briefing the agents kept two of them from
reporting "unexplained restarts". It was PR #186 shipping, nothing more.

### The run's headline finding was the household leaving on holiday

Written down in full because it was the most confident wrong conclusion of the
run, and the correction cost one sentence from the operator.

Since **2026-08-08**, not one LAN address had sent a query:

| Day        | Queries | Distinct clients |
|------------|---------|------------------|
| 2026-08-07 | 42 364  | 7                |
| 2026-08-08 | 27 460  | 7 ← the break    |
| 2026-08-09 | 24 251  | 3                |
| 2026-08-20 | 46 635  | 4                |

The four LAN clients stopped between 08:56 and 14:34 on the same day, and the
remaining traffic was the VPN peers, the Docker gateway, the loopback and the Pi
itself. Every fact was correct and independently re-measured. The reading built
on them — a resolver nobody uses any more, ad-blocking silently off for the whole
LAN — was wrong.

**2026-08-08 is the day the operator left for holiday.** The devices went with
them. The VPN peers that kept querying throughout are the same people, remotely.
Nothing broke; the house emptied.

The rules this buys, and they are cheap to apply:

- **Ask what changed in the household, not only in the configuration.** Nothing
  on either machine could have distinguished the two readings, and no amount of
  further measurement on the machines would have either. One question to the
  operator settled it in a sentence.
- **A disappearance is not an event until something identifies the disappearing
  side.** Traffic that stops in a band of a few hours on a single day describes
  people at least as well as it describes machinery.
- **Do not build an alarm on this.** "No LAN client is querying" is true every
  time the house is empty for a week, so any monitor asserting it would fire on
  holidays and teach everyone to ignore it. The gap it appears to expose — Kuma
  asserts the resolver answers, never that anyone asks — is real but not worth
  closing, for exactly that reason.

The one follow-up worth keeping is dated and manual: **after the return, confirm
that LAN clients reappear in the query log.** If they come back and do *not*
resume querying, that is the finding this run thought it had.

Two smaller things, still true: pinging those addresses at 01:00 and finding them
silent with `INCOMPLETE` ARP entries proves nothing — a sleeping phone answers
identically, and an absent one does too. And the remaining traffic kept the daily
count high enough that no volume-based alarm could have fired either way.

### The pattern: four sweeps, each stopped one instance short

Every correction of the previous week was applied to the set its author had open,
not to the set that shares the defect.

| Sweep                    | What it closed                         | What it left behind                                                  | Issue |
|--------------------------|----------------------------------------|----------------------------------------------------------------------|-------|
| argv (#177)              | 11 scripts moved to `curl -K -`        | the `claude-code` role — `feed-digest` leaks **two** credentials     | #188  |
| credential stores (#177) | 5 directories set to 0700              | `pihole.toml`, 644 under 755 parents, carrying the API password hash | #189  |
| dump guards              | 3 gates became `check_sqlite_dump`     | the 4th, Immich: no `else`, and content never asserted               | #190  |
| accepted 401 (#145)      | the Transmission container healthcheck | the Kuma monitor, still accepting 401                                | #191  |

Two of the four were found independently by two agents each, from different
angles — that convergence is what moved them from lead to finding.

**The lesson for the next sweep**: enumerate the class from the property that
defines it (every process that hands a credential to `curl`, every store holding
a hash, every dump the script does not produce itself), not from the files
already open in the editor. All four instances were outside the directory the
original work was in.

### Reported on 2026-08-21, not yet decided

Kept here so the next run does not re-derive them from scratch. Evidence is in
that run's reports, outside the repo.

- **The 5 TB drive's temperature threshold is its own lifetime maximum.** The
  daily check alarms at 60 °C and comments "rated to 65"; the drive reports
  `Specified Max Operating 50`, `Power Cycle Max 56`, `Lifetime Max 60`. It is
  sampled once a day, so the peak is never seen. `-l scttempsts` reads the max
  since power-up. Same sweep applies to the offsite host.
- **The documented mirror-staleness threshold cannot fire.** The observability
  page promises an alert after 4 h without a completed sync; the mirror interval
  is 8 h and the grace is one more, so the earliest possible alarm is 9 h.
- **46 container resurrections in 30 days that nothing counts** (44 miniflux, 2
  miniflux-db). Unit flapping is watched closely; the heal timer's own journal is
  read by no instrument. Two agents, two routes, same gap.
- **One floating image tag out of 28**: miniflux's database. Renovate cannot
  raise a PR against it, so the binary can change under the data directory
  without a commit.
- **The stored `offsite-backup` VPN profile is full-tunnel** while the deployed
  one is split. Regenerating it from the UI would remove the recovery path #180
  added. Two documentation lines — attach them to #138, do not open a row.
- **The Discord notification is not the default.** 31/31 monitors are bound
  today, but the next one entered by hand is born with no alerting path.
- **A pre-branding copy of the compose file** sits next to the live one, dated
  5 July, referenced nowhere, carrying 13 floating tags — one of which would
  refuse to start against the current data directory. A `rm`.
- **The box-reset warning covers the web ports and omits the published DNS one**,
  the only one with no application-layer guard. Proved closed today from the
  offsite uplink, with a known-open port as control.
- The offsite VPN role claims a name "resolves publicly" when it has no public
  record; the `/etc/hosts` pin is what makes it resolve at all.

### Measured and rejected — added 2026-08-21

- **The swap question is answered, and the 08-30 recheck can be closed.** It is a
  ceiling, not a ramp: 3 % after the 08-16 restart, peak 1826 MiB (44.6 %) on
  08-18, then **down to 1620 MiB with no restart at all**, and 1460 MiB (35.7 %)
  on 08-21. Forty points below the 85 % gate. Re-open only on a peak above
  44.6 %.
- The same measurement shows **the 08-15 resize was not cosmetic**: `free+used`
  was 2048 MiB until 08-15 10:51 UTC, with mean free swap between 1.6 and
  9.7 MiB for about ten days. The cold-page set measured now would not have fit.
- **Memory stalls are bounded, not worsening**: 0.067 % of time above 5 % before,
  0.069 % after — same frequency, amplitude halved (34.93 → 14.96 %). Every daily
  maximum falls inside the 03:00 backup window.
- **ext4 reserved blocks on the data volume** (250 GB): pointless against a
  ten-year runway at +0.97 GiB/day.
- **dm-crypt write latency** (123 ms against 1.7 ms on the raw device): real, but
  the only lever touches the unlock path for 1.3 % blocked time, and per-bio
  accounting biases the mean.
- **SD wear**: 1.94–1.97 GB/day on two concordant instruments, about eleven card
  rewrites a year. No action.
- **Collabora's 33 `coolmount`/`CAP_SYS_ADMIN` errors and its 95.8 s jail copy**
  are documented and decided in ADR-021. Refuted on the machine before being
  written down; do not re-report.
- **fail2ban has never banned anything** — and the absence of `f2b` chains is
  **not** proof it is broken: 1.0.2 enables `actionstart_on_demand` by itself.
  Only a reversible drill settles it, and an audit is read-only, so it stays
  suspected.

### New instrument traps — eight, two of them mine

- **Mine: counting the heal journal with a grep that matched systemd's own lines
  returned 26 922.** The real number is 46. Count only what the script itself
  emits, never the unit's start/stop chatter around it.
- **Mine: ping and ARP at 01:00 say nothing about a device's presence.** A
  sleeping client is indistinguishable from an absent one. It nearly turned a
  solid finding into a wrong causal claim.
- **`no_log` does not mask `environment:`** — both tasks leak identically under
  `-vvv`. Do not propose adding it to `restic init`.
- **`default:` in an `argument_specs` file defines nothing** (measured on
  ansible-core 2.21.2; 0 of 113 in this repo rely on it).
- **`is-enabled` counts the `mnt-data.mount.wants` links**, which inflates any
  enabled-unit tally that goes through it.
- **A `*unattended*` glob returns the inverse of the truth on the offsite host.**
- **The `config-hash` drift check gives a systematic false positive on dnsproxy**:
  Compose resolves `network_mode: service:pihole` to a container ID before
  hashing. Proved by substitution — the correct reading is 28/28 conforming.
- **An unprivileged shell glob evaluated in front of `sudo`, under a 0770
  directory, reads as "path does not exist"** — the same false-negative family as
  the swallowed permission error already recorded above. And
  `grep "^#\+ *Restore"` misses `## Data and Restore`, which nearly produced a
  false finding about Calibre-Web's restore procedure.

### One entry in this file was wrong: `.RestartCount`

It is not inert. It counts **policy** restarts only — useless for the 23
containers at `restart=no`, which is presumably how it got written off, but it is
the right instrument for the five Tier-0 ones, and those write no line in the
heal journal at all.

### Verified clean by enumeration — do not re-derive without a new symptom

- **Repo→host drift is zero on both hosts**: 21/21 verbatim copies identical by
  sha256, 23/23 homelab templates and 9/9 offsite artefacts identical line by
  line.
- 93 operator keys with no dead knob (`offsite_ip` is read by the inventory);
  45 `notify:` with no orphan handler; no `command`/`shell` without
  `changed_when` or `creates:`; 81 silent-disablement constructs read one by one,
  the three gates on absent variables documented and applied.
- 28/28 arm64, 28/28 log rotation, 37 tmpfs all sized, healthchecks with zero
  retained probe failures, mount coherence, `depends_on`.
- Perimeter: no IPv6, 19/19 routers carrying all three middlewares, headers
  served on 18/18, `sniStrict` proven, 18/18 certificates at 49–83 days, split
  DNS 18/18, a single DoH upstream, gravity fresh.
- **No no-op push**: all 12 push monitors carry their own script's message. The
  constant DDNS message means the address has never changed; lynis reporting
  `best 0` is the bootstrap run, and the file holds 73.
- Documentation: 100 relative links with none broken, 153 absolute paths, 28/28
  image tags, 17/17 thresholds in the health script, every timer schedule, and
  the restore runbook point by point.
- Backup verified on **content**, not presence: all five dumps and all seven
  Immich dumps byte-identical between the two hosts, 44 snapshots continuous
  since 2026-07-11 with only the documented 07-20 hole.

### Still open going into the next run

| #    | Why it is still open                                                                                                   |
|------|------------------------------------------------------------------------------------------------------------------------|
| #188 | `feed-digest` hands two credentials to argv. Remote, two lines, the only live exposure of the run                      |
| #189 | `pihole.toml` readable by every local account. Remote, one line in two places                                          |
| #190 | The Immich dump guard skips silently and never asserts content. Remote, one commit                                     |
| #191 | The Transmission monitor accepts 401. **UI plus a doc line** — Kuma monitors are entered by hand                       |
| #128 | Traefik sees every VPN client as one gateway address. **Local work**; already re-confirmed twice, do not re-litigate   |
| #138 | wg-easy cannot write its own database; a peer cannot be revoked. **Requires someone at the machine**                   |
| #154 | Neither ext4 volume is ever checked. **Half doable remotely** — the verification needs a boot-time check or an unmount |
| #160 | `wg_easy_config` cannot write and would abort the deploy at step 4 of 12. Sibling of #138                              |
| #182 | Scheduled, not blocked: the unrun `notify()` sites and the dump gate fire on their own over 23–24 August               |

The four new ones are all remote work. The four blocked ones still touch the
tunnel or the disk, unchanged from the previous run.

Also still open: **Renovate PR #88**, eleven image bumps, one of which is
wg-easy. Split that one out, ship the other ten, hold the VPN upgrade for a day
with physical access.

---

## The run of 2026-08-22 — the yield does not decay, and the reason matters

Fifth general audit. Baseline clean before the fan-out on both hosts: 0 failed
units, 28/28 containers, 12/12 timer services at exit 0, 31/31 monitors UP. Eight
agents, ~29 confirmed findings, grouped into seven issues — **#198** (argv),
**#199** (credential stores), **#200** (Kuma), **#201** (offsite health),
**#202** (Pi-hole log), **#203** (documentation), **#204** (rate limit).

One piece of baseline work paid for itself again: eight containers had started
recently, and checking `RestartCount=0` / `OOMKilled=false` / `restart=no`
**before** briefing the agents stopped them being reported as unexplained
restarts. They were the 08-19 and 08-20 deploys.

### Two entries in this file are now wrong. Do not quote either.

- **"The 4 `DAC_OVERRIDE` and the 4 writable rootfs are structural"** — it is
  **5 and 6** since Calibre-Web (2026-08-05). They remain structural and are not
  to be re-proposed; only the count drifted, and it drifted because a service
  arrived after the verdict was written and was never read under it.
- **"87 rate-limit rejections"** — the real figure is **851 over nine days**,
  a tenfold undercount. That entry already flagged its own instrument as
  unreliable; the correct count anchors on the status field of the CLF access
  log. All 851 are on the SearXNG image proxy, the most recent the day before.

### The headline: a fix from six days earlier created a continuous exposure

#145 replaced a Transmission healthcheck that could not fail (it accepted a 401)
with `transmission-remote`, which authenticates — **through the command line**.
Captured from an unprivileged account, digest compared against the secret file:
the full RPC password, every 30 s, **2 880 times a day**. Pattern 4 in its purest
form, and the largest finding of the run.

The credential must be treated as disclosed and rotated, not merely hidden: the
account that could read it is the one running a model over arbitrary third-party
feed content every morning.

### Two spaces are now ENUMERATED, and that is the useful outcome

`settled.md` has said since 2026-08-16 that enumeration ends a pattern where
sampling makes it recur. Both spaces it named as un-enumerated were closed this
run, by hand, after the agents finished.

**The 20 service pages, three axes each** (does the page agree with its ADR, its
runbook, and its container?). All 20 read in full. **11 are clean on all three
axes**; nine carry ten findings, two of which the sampled pass had missed — the
Nextcloud monitor documented as `HTTP(s)` when it is a Keyword check on
`"maintenance":false,"needsDbUpgrade":false`, and `claude-code.md` claiming a
`/sandbox` confinement that does not exist. Seven of the ten have the same
signature: **the correction reached the ADR and/or the runbook and stopped before
the service page.** `docs/05-services/*.md` is the set every sweep forgets, and
it is the first thing anyone opens during an incident.

**The "any argv" class on `compose.yaml`.** Four axes, because the text alone
proves nothing:

- static YAML parse of all 28 services — 24 command lines built across
  `healthcheck` / `command` / `entrypoint`, exactly **one** carrying a
  credential; the 4 interpolated `${VAR}` are database names and users; **0**
  labels match;
- **child processes**, because a clean command line can spawn a dirty one:
  MariaDB's `healthcheck.sh` uses `--defaults-extra-file=` (a path), and Immich's
  own scheduled dump passes `PGPASSWORD` in the child's **environment**
  (`/proc/<pid>/environ` is 0400), not in argv;
- **scheduled in-container jobs**, outside any sampling window by construction:
  `nextcloud-cron` is `busybox crond`, no credential;
- **empirical** — 35 real secret values extracted structurally from the secret
  files and four `.env` files, 3 457 sweeps of `/proc` over 140 s covering more
  than two cycles of all 24 healthchecks, 3 808 distinct command lines,
  **positive control passed**, **exactly 1 match**.

The empirical axis proves *continuous* exposures only. The nightly and
deploy-time sites were established by reading the deployed artefacts. Say so
rather than claiming the class is empty everywhere.

### The most important correction of the run was to one of our own agents

The security agent concluded, after "an exhaustive enumeration of argv across all
deployed executables on both hosts", that there was **exactly one** live
instance. It was wrong, and the reason is the pattern this audit exists to find:
its scope was *deployed scripts*, and the worst instance lives in
`compose.yaml`. It also reported "no control that cannot report its own failure"
while three other domains found three.

**An audit agent defines a class as narrowly as the sweep it is auditing.** Where
two agents disagree, resolve it before writing a word to the operator — and treat
a confident negative from a single domain as a claim about that domain's scope,
not about the class.

### Does the yield decay? No — and the reason is not that the system is rotten

Counted honestly: 5 findings (08-15), 9 (08-16 am), 12 (08-16 pm), 23 (08-19),
4 + 9 undecided (08-21), **~29 (08-22)**. Neither quantity nor severity is
falling — this run's headline is a continuous credential exposure and a
supervision healthcheck that cannot fail, the same calibre as the founding run.

The law that fits the data: **the yield tracks the quality of the search key and
what shipped since the last run, not the residual defect stock.** This run's
biggest finding came from a key minted 24 hours earlier (#188's "any argv").

There are **two stocks**, and only one of them drains:

1. **Design defects** — structural, severe, genuinely being exhausted. No
   equivalent of the dead mirror or the three unwritable services this time.
2. **Sweep residue** — created by the corrections themselves, and therefore
   **recharged by every fix**. Five of this run's biggest findings are children
   of previous corrections.

What empties the second stock is not another general audit. It is enumerating the
class by its defining property. Every space enumerated once has come back clean
and stayed clean across four runs — and two more closed this time.

### New instrument traps — five, four of them ours

- **`find -size -1M` matches only EMPTY files.** `find` rounds block counts up,
  so any non-empty file under a megabyte occupies 1 block and is not `< 1`. A
  sweep silently fell from 89 371 files to 724 and returned "0 matches" twice.
  Use `-size -1000000c`. **Only the positive control revealed it.**
- **`sudo -u <other> find` ABORTS if the cwd is not traversable by that account**
  — 10 files returned out of 1 069. With `2>/dev/null` that is indistinguishable
  from a clean system. `cd /` first, and never discard `find`'s stderr.
- **`/etc/os-release` is a symlink**, so `-type f` excludes it. A positive
  control must be a regular file; `/etc/passwd` works.
- **A `/proc` sweep that reads the pid and then re-opens the file loses the
  race.** Short-lived processes evaporate between the two reads
  (`No such file or directory`). Let one `grep` read `/proc/*/cmdline` in a
  single pass. And exclude the sweeper's own command line, or it matches itself.
- **The harness truncates too, not only the command.** A 150 s measurement was
  killed by a 2-minute tool timeout and still wrote partial output that looked
  like a complete result; only exit code 143 gave it away. This is the "never
  pipe a completeness sweep through `head`" rule in a form this file did not
  cover.

And one method note worth more than the traps: **a null result is worthless
without a positive control.** "1 match" and "the sweep is broken" are the same
observation until something known-present is shown to be found.

### Verified gone on the machines, not assumed

The four findings of 2026-08-21 (#188–#191) were confirmed **on the hosts** before
the fan-out, not from the commit log: `digest.sh` uses `--data-urlencode`, the
Pi-hole store directory is 0700, and the Immich guard now reads the dump. That
guard then fired for real on the 03:00 run of 2026-08-22 —
`fresh <48h, completion marker present`, with a real byte count — which closes
the dump-gate half of #182 on a real run rather than on fixtures. The offsite
host's armed 04:00 reboot happened and it came back unaided: disk mounted,
0 failed units, 6 security updates installed, and the night's copy landed
(46 snapshots, newest 03:05:49).

### Still open going into the next run

| #    | Why it is still open                                                                                                   |
|------|------------------------------------------------------------------------------------------------------------------------|
| #198 | The argv class: one continuous exposure plus four narrower sites and five documented commands. Remote, one commit + a rotation |
| #199 | The nightly dump copies are world-readable, and `forgejo.db` is the seventh store. Remote, two lines                   |
| #200 | Kuma notifies once per incident, and its own healthcheck cannot fail. UI plus one healthcheck                          |
| #201 | The offsite health report never thresholds the CPU temperature the runbook says it watches. Remote                     |
| #202 | Pi-hole's query log is orphaned and its rotation is permanently skipped. Remote                                        |
| #203 | Fourteen documentary statements that contradict their ADR, runbook or container. Remote, one commit                    |
| #204 | The Traefik rate limit rejected 851 real requests in nine days. Remote, one value                                      |
| #128 | Traefik sees every VPN client as one gateway address. **Local work**; re-confirmed twice, do not re-litigate           |
| #138 | wg-easy cannot write its own database; a peer cannot be revoked. **Requires someone at the machine**                   |
| #154 | Neither ext4 volume is ever checked. **Half doable remotely**                                                          |
| #160 | `wg_easy_config` cannot write and would abort the deploy at step 4 of 12. Sibling of #138                              |
| #182 | The dump gate is now proven on a real run; the unrun `notify()` sites remain                                           |

Seven new ones, all remote work. The four blocked ones still touch the tunnel or
the disk, unchanged for a third run.

Also still open: **Renovate PR #88**, eleven image bumps, one of which is
wg-easy. Split that one out, ship the other ten, hold the VPN upgrade for a day
with physical access.

### For the next run

Both spaces named last time are now enumerated. The two that remain sampled, and
are therefore where the next yield is:

- **What each container's own scheduled work does** — the in-container jobs that
  run rarely enough that no sweep window catches them. Two were checked by hand
  this run (Immich's dump, the Nextcloud cron); nobody has enumerated the set.
- **The offsite host as a whole.** Three of this run's findings were its missing
  half of a homelab control. It has been the trailing edge of four sweeps now
  (#155, #156, #201), which makes "check both hosts by default" a rule that keeps
  being written down and not applied.

---

## Shipped the same day — 2026-08-22 evening

Five of the seven issues the morning run produced were fixed, deployed and
**verified on function rather than on status**, all remotely, in one afternoon:
**#198** (argv), **#199** (credential-store copies), **#201** (offsite health),
**#203** (fourteen documentary statements), **#204** (rate-limit burst). What
remains is #200 and #202 — both recreate a container — and #207, which waits for
someone at the machine.

### What each fix actually proved

- **#198.** The Transmission healthcheck moved to `-ne`/`TR_AUTH`. Proven by PID:
  the process's argv reads `sleep 25`, its `environ` carries the value at 0400,
  and an unprivileged read of `environ` is refused. Then proven again in
  operation — a 140 s `/proc` sweep with a positive control **saw
  `transmission-remote` run twice** and found the secret in **zero** command
  lines. `backup.sh` reads the secret inside the container through `MYSQL_PWD`,
  which also made `NEXTCLOUD_DB_PASSWORD` dead weight in `backup.env`; it is
  gone. Pi-hole gained a Docker secret because `pihole setpassword` takes its
  argument from the command line and nowhere else. **The RPC password was
  rotated**, and the rotation was proven rather than assumed: the digest of the
  secret file changed, the new value was accepted and a wrong one refused.
- **#199.** `install -d -m 0700` for the nightly dumps, `0700` on Forgejo's data
  directory, both now asserted by the posture check. The load-bearing check was
  **not** the mode but whether Forgejo could still WRITE — it can, `touch` and
  `database:ping` both pass. That is the #138 question, asked before it could
  bite instead of six weeks later.
- **#201.** CPU temperature thresholded at 70 (not the homelab's 80 — that board
  idles at ~50 °C and its fan engages at 60), the `apt-check` guard ported, and a
  "visited nothing" guard added to the undervoltage loop. Verified by the real
  push: `SMART ok, disk 20%, ext4 clean (2), ssd 43C, cpu 51C, tunnel 75s` —
  green, carrying the temperature, not alarming on it.
- **#204.** `burst` 50 → 250, sized on **episodes** rather than seconds. Verified
  from Traefik's own API rather than from the file:
  `{"rateLimit":{"average":100,"burst":250},"status":"enabled"}`.

### Corrections to entries written earlier the same day

Recorded rather than edited away, because each was a confident wrong reading.

- **`notifempty` does NOT make Pi-hole's rotation skip forever.** #202 says it
  does; the nightly job runs `logrotate --force`, and `--force` overrides
  `notifempty`.
  **Corrected 2026-09-26 (fourteenth run): the last clause is wrong.** `--force`
  overrides the PERIOD, not `notifempty` — an empty `webserver.log` was not
  rotated on 09-26 while the non-empty files rotated in the same second. What
  `--force` does override is `weekly`: every stanza of that file rotates daily. The mechanism is also not system logrotate at all — there is no
  `cron.d` entry and no state file — but `pihole flush once quiet` at 00:00,
  which runs logrotate with its **own** state file and **no FTL restart**, so
  reopening depends entirely on the `postrotate` `kill -USR2`. That signal has a
  valid target: the pidfile exists and matches `pidof`.
- **The #198 deploy accidentally cured #202's symptom.** Recreating pihole for
  the secret mount wiped `/var/log/pihole`, which lives in the writable layer.
  The orphaned 71 MB inode is gone and the log is healthy again — and five days
  of query history were destroyed by a deploy that had nothing to do with
  Pi-hole. The design defect is now *observed* rather than inferred.
- **The marginal sector was not new.** It was reported as appearing that
  morning. The drive's self-test log shows the **same LBA** failing at 2529 h,
  2363 h and 2363 h of power-on time — three reproducible failures over about
  seven days.
- **The offsite SMART test is already `-t long`.** #207 suggested folding a
  short-to-long change into #201; wrong — the short-test gap is homelab-only.

### New facts, established on the machines

- **A remote reboot of the homelab is impossible, and this is now a rule.**
  `/etc/wireguard/wg0.conf` is a symlink onto the encrypted volume, so after a
  reboot it dangles and `wg-quick@wg0` cannot start; `wg-easy` cannot either,
  being a container on the same volume. `homelab-unlock` asks for the passphrase
  interactively. **No unlock without the tunnel, no tunnel without the unlock.**
  `claude-remote-control` is no escape hatch — its vault mount needs Nextcloud,
  hence docker, hence the unlock. Stated by the operator as a standing
  constraint: they go home to reboot.
- **Recreating pihole orphans dnsproxy, and nothing paired them.** `dnsproxy`
  runs in pihole's network namespace; `compose up` recreates pihole whenever its
  definition changes, which destroys that namespace while dnsproxy stays up and
  healthy — a LAN-wide outage with both containers green. The `Restart pihole`
  handler pairs them; nothing did after a compose recreate. Now guarded by a
  namespace comparison rather than by inspecting `compose_result.actions`, so it
  also covers a recreate nobody predicted.
- **Rotating a credential can require a change in Kuma.** Exactly **1 of the 31**
  monitors authenticates (Transmission, since #191), and its password lives in
  `kuma.db`. A rotation that stops at the deploy leaves the monitor red with
  nothing on the host to explain it. The general form: **a change that makes a
  service authenticate creates a credential copy wherever it is monitored from.**
- **The household has still not returned.** One LAN client, ~20 queries on 08-16,
  08-17 and 08-21, none today. The dated follow-up from the 08-21 run therefore
  stays open, and it is what makes the reboot constraint above bite.

### New instrument traps — six, all paid the same day

Worth more than the fixes, on the usual reasoning.

- **A SQL `LIMIT` truncates a completeness sweep exactly like `head`.** Querying
  the last 10 heartbeats across five monitors returned only the two daily ones,
  and three monitors looked absent. Query per monitor, or count, but never bound
  a completeness question by a global limit.
- **A canary injected on the command line matches itself.** The first attempt to
  prove the argv fix passed the marker to `docker exec`, so the sweep found four
  hits — all of them mine. Let the value come from the file at runtime, exactly
  as the mechanism under test does.
- **A two-step `/proc` read loses the race.** Finding the pid and then reopening
  `cmdline` returns `No such file or directory` for anything short-lived. Let one
  `grep` read `/proc/*/cmdline` in a single pass.
- **Stripping Jinja with `sed` to shell-check a template produces broken shell,
  twice.** `{{ }}` and `{% %}` both have to go, and removing `{% if %}` lines
  leaves orphan `fi`. It reports a syntax error in *your filter*, not in the
  file. Extract the block you added and check that alone.
- **The harness truncates too.** A 150 s measurement was killed by a 2-minute
  tool timeout and still printed partial output that looked like a complete
  result; only exit code 143 gave it away. Same family as the `head` rule, one
  layer up.
- **A green monitor carrying its own script's message can still be unproven.**
  Three push monitors showed exactly the text #182 asks for — from runs three
  days *older* than the deploy that rewrote them. Compare the beat's timestamp
  with the artefact's mtime before ticking anything off.

### Still open

| #    | Why                                                                                                     |
|------|---------------------------------------------------------------------------------------------------------|
| #200 | Kuma notifies once per incident, and its own healthcheck cannot fail. Remote, but recreates a container   |
| #202 | Pi-hole's rotation. Symptom cleared by accident; cause undecided until the 00:00 run is observed          |
| #207 | One marginal sector, seven days old. **On site**, during the reboot, before the volume is mounted         |
| #182 | Four scheduled observations, all within 48 h                                                              |
| #128 | Traefik sees every VPN client as one gateway address. **Local work**, re-confirmed twice                  |
| #138 | wg-easy cannot write its own database. **Requires someone at the machine**                                |
| #154 | Neither ext4 volume is ever checked. Configuration change is remote; verification needs the on-site reboot |
| #160 | `wg_easy_config` cannot write and would abort the deploy. Sibling of #138                                 |

Also open: **Renovate PR #88**, eleven image bumps, one of which is wg-easy.

Four of these now share one moment: #207, #154, #138 and #160 all resolve during
the same on-site visit, and the reboot that #207 needs is the one #154's
verification wants. Plan them as one trip, not four.

---

## Between 2026-08-23 and 2026-08-27 — twenty-six issues closed, three ADRs shipped

Ninety-nine commits and forty PRs (#205–#258) since the entry above. Nothing in
this block is open work. An agent that reports any of it is re-reporting a fix.

### The on-site visit happened — 2026-08-26, 23:54

The reboot that four issues were waiting on took place. `uptime -s` says
2026-08-26 23:54 (`last reboot` disagrees: wtmp still shows the 28 July boot as
running — **do not read the reboot date from `last`**). The four issues planned
as one trip are all closed: **#207** (marginal sector), **#154** (neither ext4
volume ever checked), **#138** (wg-easy cannot write its database), **#160**
(`wg_easy_config` cannot write and would abort the deploy).

The consequence for this run: the stack has been up for about ninety minutes,
several containers for twenty. **Any figure that accumulates — swap occupancy,
container memory, log sizes, restart counts — is reading a machine that restarted
tonight.** Say so before quoting one, and do not project from it.

### The three ADRs — the glue is gone, and that changes where to look

- **ADR-030, "configure the installed tools, don't write the glue."** Curated
  Netdata alarms route through Kuma rather than straight to Discord, one monitor
  per action. Its migration rule is load-bearing and still in force: *no bash
  line is deleted until its replacement has been **observed** firing.*
- **ADR-031, resticprofile.** `backup.sh` (deleted), `local-maintenance.sh`
  (deleted), `offsite-check.sh` (deleted). The nightly job is `resticprofile`
  with hooks; the single notify site left is `backup-notify.sh`.
- **ADR-032, goss.** `backup-dumps.sh` (373 lines) and the posture assertions
  became declared specs. **Four specs across the two hosts.** The totals are
  deliberately not written here: this line has carried a stale figure three
  times (376, then 384 against its own 387 later in the same file), and each
  time it reached eight agent briefs before anyone measured. Count with `1..N`
  in TAP. And do NOT carry forward the old rule that one assertion emits two
  TAP lines — see the correction at the end of this file
  (`exit-status` and `stdout`), which is why adding a single check moves the
  total by two. `posture.sh` keeps only what goss cannot
  express. They are documented in `docs/07-observability/README.md` since #263 —
  including the one trap: `backup-dumps.yaml` run by hand outside the backup
  window reports 13 of 19 failed, because the dump directory only exists during
  a run. That is not a finding.

Net effect: **roughly a thousand lines of shell were deleted in five days.** The
audit's usual hunting ground — a script whose guard is inert — has moved into
YAML. Read `/etc/goss/*.yaml` and the resticprofile profile for the same shapes:
an assertion that watches the wrong path, a gate that can only pass, a hook whose
failure is swallowed.

### Closed, with the defect each names — do not re-report

| # | What it was |
|---|---|
| #128 | Traefik saw every VPN client as one Docker gateway address |
| #138 | wg-easy could not write its own database |
| #154 | Neither ext4 volume was ever checked; a weekly green timer scrubbed zero bytes |
| #160 | `wg_easy_config` could not write, would abort the deploy at step 4 of 12 |
| #198 | The argv sweep enumerated curl, not argv |
| #199 | The credential sweep closed the live stores and never their nightly copies |
| #200 | An incident notified once and never again; Kuma's own healthcheck could not fail |
| #201 | The offsite health report never thresholded what the runbook said it watched |
| #202 | Pi-hole's query log orphaned eight days, every future rotation skipped |
| #203 | Fourteen documentary statements contradicting ADR, runbook or container |
| #204 | The Traefik rate limit rejected 851 real requests in nine days |
| #207 | Two more bad sectors, one making a live file unreadable |
| #215 | The dnsproxy re-attach guard could detect but never repair |
| #216 | Both host-health monitors latched DOWN on a scheduled item, muting 17 acute checks |
| #217 | The credential-store assertion was a hand-maintained list of seven |
| #218 | A world-readable Immich dump beside the closed dumps directory since 5 July |
| #219 | Three assertions the machine did not honour (reboot runbook, ADR-004, ADR-015) |
| #220 | Five latent one-liners of the silent-disablement shape |
| #236 | wg-easy's database carried the migration's IPv6, nothing asserted either way |
| #238 | `wg_easy_config` asserted defaults, and a default is read exactly once |
| #241 | The staged startup gave up nine seconds before Postgres finished recovering |
| #242 | The unlock gate was deployed and had never run |
| #252 | The fail-fast guard added after 2026-07-04 had never been able to fire |
| #253 | The staged startup assumed Docker had already brought Tier 0 up |
| #254 | The one volume holding every byte of data was the one nothing ever checked |

Plus, from the same stretch and never issue-tracked: `/etc/hosts` rewritten
forever by ansible and cloud-init in turn; an offsite deploy that only ever
worked from outside the house; wg-easy moving its login endpoint in a MINOR
release; the hardening ratchet that could only go one way and erased its own
evidence; the weekly surface scan running through the working day; the heal that
switched off with the failure it existed for.

### Settled by the same stretch — do not re-derive

- **Splitting the last startup wave was measured and bought nothing** (reverted
  in 03d6dbe). Wave 3 concurrency plus retry is the shipped answer. Do not propose
  re-splitting it.
- **`start_period` is now set deliberately, per container**, on cold-startup
  measurement: the databases (#250), then netdata, jellyfin, immich-server,
  immich-ml, calibre-web, collabora (#258, e8bae61 — jellyfin was re-sized after
  the first figure turned out not to be the worst case). A container reporting
  `(health: starting)` shortly after a boot is the design, not a defect.
- **Renovate's weekly batch rule was decorative** and is fixed; the Dependency
  Dashboard is issue **#8** and is not a finding.
- **An abort is not a failure**, in three separate places now: a SMART extended
  test that meets itself, a skipped run, a Netdata instance with no verdict yet,
  a REMOVED instance. Monitors were red for each of these and are not any more.
  A red-looking word in a monitor message is not automatically a defect.

### The state this run starts from

Both hosts: **zero failed units**. Homelab: **28 containers, all up, 24 of the
28 with a healthcheck reporting healthy** (`dnsproxy`, `nextcloud-cron`,
`nextcloud-notify-push`, `searxng` have none). **34 active Kuma monitors, all
UP** — counted `select count(*) from monitor where active=1` on 2026-08-29, and
there are no inactive rows. An earlier version of this line said 35; do not
carry that figure forward. `goss` and `resticprofile` are installed at `/usr/local/bin`. The Kuma
database is at `/mnt/data/services/uptime-kuma/kuma.db` — **not**
`/mnt/data/uptime-kuma/`, which is where a previous run's command pointed and
failed.

### What the 2026-08-27 run produced — filed, not lost

Five issues, **#259 to #263**. They are tracked; report them as known rather
than as new findings, and check their state before spending budget on them.

- **#259 — closed 2026-08-28** (PR #266). `#128` removed `10.8.0.0/24` from the
  `vpn-only` allow-list on a census drawn from an access log filtered to
  400-599 — a log of refusals, in which the offsite host's successful pushes
  could not appear. Offsite was mute from 2026-08-24. The subnet is back, the
  accessLog filter is gone so the log can answer who is present, and there is
  now one assertion per allow-list entry: the single one that existed probed
  from a container on the docker network and stayed green throughout. **Do not
  re-report the allow-list, and do not draw a census from a filtered log.**
- **#260** — the offsite backup disk has no filesystem check of any kind, and
  the root fsck interval trigger cannot fire on either host (both stamped
  `Tue Jul 28 17:04:4x 2026` to the second — a frozen pre-timesync clock, not a
  date). Mount count still works, so it is real but not urgent.
- **#261** — five validations that pass in the state they were written to
  catch, including the `wireguard` credential-store exemption that outlived
  #138.
- **#262** — the container-unhealthy alarm fires on charts younger than its own
  lookup window; `start_period` does not protect jellyfin.
- **#263** — seven documentary statements the machine no longer honours.

### Still open going into that run

**#182 only** — four scheduled observations, and it is a good statement of what
"unproven" means here. Two weekly resticprofile commands have each carried their
own message exactly once, from a hand-started run; their first scheduled run is
**Sun 2026-08-30, 05:00 and 06:00**.

**The two container-alarm observations are DONE, and this file said otherwise
for three days.** Both were made on 2026-08-26 — `homelab_container_down` on a
container stopped and left stopped at 22:14 (alarm at 10 min 44 s, adapter
pushed to Kuma 51 s later), and the supervised reboot at 10:04-10:28. `c2c2a36`
recorded them, deleted both blocks from `homelab-health.sh`, and referenced
#182 — whose body was never updated and still read *Pending*.

The reboot observation came out **blind, not noisy**: netdata is itself a
container in the last startup wave, so by the time its docker collector has any
chart every container is already up. That is the opposite of what the alarm's
own header predicted, and the templates kept announcing the pre-deletion state
until #273.

Cost of the staleness, and the reason it is written up rather than quietly
fixed: the 2026-08-29 run sent this claim to eight agents, and two of them plus
the main session independently rediscovered and re-reported work that had
shipped on 2026-08-26. **A tracker that still says pending after the code is
gone buys the same rediscovery every run.** Check `git log` for the commit that
references an issue before trusting the issue's own table.

---

## The run of 2026-08-29 — four lots, and the file you are reading cost the run its first hour

Baseline was clean on both hosts and stayed clean: 0 failed units, 28 containers
up, 34 monitors UP, 13 timer services at exit 0. Both hosts had rebooted that
morning (offsite 02:41:01, homelab 02:45:59, a deliberate `systemd-reboot`), so
every accumulating figure that day was reading an eight-hour-old machine.

### Shipped, deployed and verified — do not re-report

| # | What it was | Proven how |
|---|---|---|
| #272 | The nightly Immich dumps were world-readable at the path #218 never closed — seven files of ~89 MB at 0644, rewritten at 02:01, under a chain traversable end to end | `access(2)` from the unprivileged `claude` account, with the Vaultwarden database refused in the same call. Fixed with 0700 plus a NAMED assertion, because the derivation cannot be widened to reach it |
| #273 | Three migration markers outlived their phase, one of them a decision rule for an observation already made | Text corrected against `c2c2a36`; #182's table and this file corrected with it |
| #274 | Three sweeps stopped one instance short: two `start_period`s, six argument specs, a tmpfs the docs called absent | `start_period` ENUMERATED (below); specs declared in the roles that consume them; docs swept to their siblings |
| #278 | Nothing asserted `--append-only` on the offsite rest-server — 26 assertions on that host and none about security | Assertion added on the LIVE process, and **made to fail on purpose** in both modes before being believed |

### Two decisions, so nothing re-opens them

- **The Immich photo library stays world-readable, deliberately.** The operator
  browses it with other tools — Nextcloud, an agent on the host — and wants that
  to keep working. The exemption in `group_vars` previously left this open as
  "a real question this issue deliberately does not answer"; it is answered.
  **Do not propose closing it.** It is also precisely why the *dump* had to move
  out from under the same exemption: the same account reads both, and only one
  of them is meant to be read.
- **The `--append-only` assertion was arbitrated IN**, though it sits next to the
  inter-host drift detection that was declined. The line is drawn at the one
  property that makes the offsite host a backup rather than a mirror.

### ENUMERATED — do not re-sample

`start_period`, from netdata's `health_status` charts across the whole
02:50-03:25 window. Of the containers declaring one — the count lives in
`classes.md` under C06, not here — exactly **two** ever left `starting` for
`unhealthy`:

    collabora       993 s against 600 s   ->  1320 s
    immich-server   773 s against 480 s   ->  1020 s
    calibre-web     511 s against 600 s   held — 89 s, the thinnest margin left
    all the others  never sampled `starting` in the window

This paragraph carried "Twelve" from 2026-08-29 until the run of the same
evening measured thirteen, against `classes.md` (13/13) and the `compose.yaml`
header (THIRTEEN) — the **third** stale cardinal in this file in one day, and
this one sat under the heading that forbids re-sampling. Hence no number here.

Caveat that keeps this honest: netdata is itself a container and only began
collecting at 02:55:13, so the four containers started at ~02:50 were healthy
before anything could watch them. Complete for the later waves, which is where
every overshoot has ever been.

Both figures are ~2x the 2026-08-27 measurements #258 sized from, because the
03:00 backup landed on the tail of the startup. **A boot that COLLIDES with the
nightly backup is the worst case**; a quiet cold boot is not.

### The new fact worth more than the fix

**`start_period` does not only govern the alarm — Traefik withholds a
container's router while it is `starting`.** An undersized one makes the service
answer 404 through the proxy. Neither #258 nor #262 records this; both cost it
only in alarm noise. It is now in the `compose.yaml` header, and it is the whole
explanation of "five services down" on a morning when `RestartCount` was 0
across all 28 and the heal timer had taken no action in 217 passes.

### Claims that did not survive verification — one agent's, one the session's own

- **"Five services down from disk saturation caused by the restic backup."**
  Refuted by three agents independently, from three instruments. The first 404s
  fall at 02:56, **four minutes before the backup service starts** and six
  before restic's first read. It was the staged startup after the 02:46 reboot.
  What survives: the iowait saturation IS recurrent (55-80 % peaks over four
  nights) and the backup lengthened the recovery — scan 928 s against 122-251 s
  — but no night without a reboot has ever dropped a service.
- **"The reboot observation has just been made and it inverts the alarm's own
  rule."** A rediscovery. The observation was made on 2026-08-26, and `c2c2a36`
  reached the identical structural conclusion three days earlier. What survived
  was only the stale text. **The cause was this file**, which still said the
  observation was pending — see the correction above. Two agents and the main
  session spent budget on shipped work because of one stale line here.

### New instrument traps — six, and three were the main session's

1. **A glob under `sudo` expands in the UNPRIVILEGED shell.** `sudo grep
   /etc/goss/*.yaml` returns nothing at all, silently, because `/etc/goss` is
   `drwx------` and the glob never expands. Use `sudo sh -c '…'`. The same bug
   makes the restore runbook's `sudo ls /path/*.sql.gz` useless now that #272
   closed that directory — it reports "no matches", which reads like an empty
   backup directory rather than a permission error.
2. **A negative result from a path that does not exist is not a negative
   result.** `/etc/netdata/health.d` exists only INSIDE the container; the host
   side is `/mnt/data/services/netdata/health.d`. A `grep -rl` against the
   container path reported "no occurrences" of a marker that was still there.
3. **`docker exec … ls` prints container-local time.** A file read `10:02`
   against a deploy at `12:05` and looked unwritten. UTC inside, CEST outside —
   the same offset already recorded for `docker logs -t`, arriving by a
   different command.
4. **Kuma's first UP beat is bounded by KUMA's own startup, not the
   container's.** Kuma came up at 00:50:53 and its earliest beats land at
   00:56:49, so anything "first UP" before ~00:58 measures Kuma. Three
   containers looked like start_period overshoots and were not.
5. **Grepping for the marker you just replaced matches the corrected file**,
   when the new text quotes the old one. Anchor on `^#`.
6. **An epoch computed for the wrong year** returns a well-formed empty answer
   from the netdata API, which reads as "no chart" for every container at once.
   A uniform null across a heterogeneous set is a bug in the query, not a fact
   about the system.

### The meta-lesson, and it is about this file

`settled.md` is pasted into all eight agent briefs. Two lines in it were stale
that morning — the #182 container observations, and the goss total of 376 — and
both propagated straight into the run.

The afternoon run of the same day proved the lesson had not been learned: the
replacement figure was itself stale and **contradicted a second figure elsewhere
in this file**, which sent one agent to a wrong arithmetic and cost the main
session a correction in front of the operator. The numbers are now gone from
this file entirely — see `classes.md` — and only the rule remains:

~~one assertion emits TWO TAP lines~~ — **that rule is wrong**, and it was
itself a source of the confusion it was written to prevent. Measured on
2026-08-29 while deploying #285: six assertions declaring only `exit-status`
added SIX lines, while one declaring `exit-status` and `stdout` added two. The
line count follows the number of ATTRIBUTES declared, not the number of
assertions.

Count with `1..N` in TAP; never carry the figure forward, and never derive it.

### Still open going into the next run

- **#182**, and less of it than before: the two container observations are done
  (2026-08-26). What remains is the two weekly resticprofile commands on their
  real schedule — **Sun 2026-08-30, 05:00 and 06:00** — and item 3, the
  absent-`acme.json` branch, recorded and deliberately not scheduled.
- **#8**, the Renovate dashboard. Not a finding.
- Unproven and unprovable on the day: that the 02:01 Immich dump lands normally
  under the new 0700. The write probe (`docker exec … touch`) succeeded as root
  inside the container, which is the closest substitute. Note the net is **48 h
  wide, not 24**: `dump-immich-fresh` accepts a dump under 48 hours old, so a
  single missing night passes and only the second fails. A corrupt dump is
  caught the next morning by `dump-immich-usable`.

## The run of 2026-08-30 (evening) — the key was `order`, and the founding defect was still live

### Shipped, deployed and verified — do not re-report

PR #305, four commits, deployed to both hosts and re-validated at **359/359**
(homelab) and **43/43** (offsite):

1. **The ten Kuma push sites.** Seven detected a failed push and discarded the
   verdict with `2>&1 || true`; one had no `--fail` at all. All now keep the
   failure, and two assertions read the marker — one per host, each with a
   floor DERIVED from the machine rather than a constant.
2. **The token in argv.** `homelab-netdata-kuma.sh` passed the push URL, token
   included, as a curl parameter. Converted to the `-K -` stdin form its twelve
   siblings already used.
3. **The LUKS header procedure.** Output moved off tmpfs to `/root`; the armed
   USB tamper is now announced with the disarm/arm commands; the store and the
   medium no longer appear in a public file; and the runbook's header-restore
   ends with `homelab-unlock` instead of the raw `luksOpen` that skips the
   integrity check.
4. **Documentation.** Two procedures the machine refuses (the disaster-recovery
   sequence that started the stack on empty data; the DNS remedy that is
   measured to leave DNS dead after a recreate) and six counts it denies.

### Two decisions, so nothing reopens them

- **The LUKS header file lives on `/root`, not in `/tmp`.** Chosen knowing the
  cost: a forgotten copy used to self-destruct at the next boot and no longer
  does. The trade was taken because the procedure's own next step invites a
  poweroff, which used to erase the header at exactly the moment it was needed.
  Mitigated in the script — it lists leftovers on every run — and the runbook's
  shred step is now mandatory rather than best-effort. **Do not "restore" this
  to tmpfs on the security argument; the argument was considered.**
- **One PR, three commits, rather than three PRs.** Both deployed lots ride one
  deploy; the commit split preserves review and a clean revert path.

### `cloudflare-ddns.sh` — the one artefact whose deploy was held back

Its role has no task-level tags, so `--tags deploy` runs the whole deploy role
including `compose up`. Established before deciding: the task that copies it
**notifies no handler**, so the deploy changes one file and restarts nothing,
and `compose.yaml` was byte-identical between repo and host (C27, 129/129), so
nothing was armed for the heal timer. The safe form is
`-e '{"deploy_services": "<one unchanged service>"}'` — JSON, because the shell
strips the quotes on the bare `-e deploy_services="a b"` form, which the role's
own header warns about.

### New instrument traps — seven, and three were ours

1. **`datetime(x, 'localtime')` inside the Kuma container is a NO-OP.** The
   container runs UTC, so the modifier converts nothing and a fresh beat reads
   as two hours stale. Compare epochs, or know the container's zone.
2. **`journalctl | grep MARKER` matches the whole formatted line.** So `sudo`'s
   audit log of a command that merely MENTIONS the marker counts as an
   occurrence — measured, 7 phantom losses on a host that had lost none, all
   seven being the audit's own verification commands. `journalctl --grep` tests
   the MESSAGE field alone; anchor it at `^` to separate an emission from a
   mention. Control both ways: anchored gave 0, unanchored gave 7, and a
   deliberately looser pattern found the one real old-format line, proving the
   filter reached script output rather than matching nothing.
3. **dockerd's `failed to exit within Ns — using the force` is not proof of a
   kill.** It is written when the grace elapses, and dockerd writes it for
   containers that had already exited. Pair each by container id against
   `received task-delete event from containerd`: after the message (+103 to
   +338 ms) is a real kill, before it (2 to 9 s) is not. 17 messages, 8 kills,
   1 undecidable. **Positive controls are what settle it** — three containers
   wrote their own completion line seconds before their alleged killing.
4. **Crash-recovery markers in container logs can only see databases.** That
   instrument under-counted a 29-container shutdown class by a factor of two.
   The daemon's own log is uniform across the fleet.
5. **`-fsS` bundles `--fail`.** A classifier requiring `-f` as a standalone
   token reports every sibling as unguarded. Ours did, for one turn.
6. **A goss timeout is reported as `not ok`**, indistinguishable from a failed
   assertion. Size the timeout against the load THIS SPEC creates, not the idle
   cost: 20 s against a measured 4.2 s idle still timed out inside a 359-check
   run. Re-paid, having already been paid at `no-container-came-back-recovering`.
7. **`pgrep -f "<pattern>"` matches the command line of the shell running
   `pgrep`.** Any healthcheck built on it passes vacuously — proven in-container
   with a pattern naming a path that does not exist.

### Claims that did not survive verification — two agents' and one of ours

- **"17 containers force-killed"** — 8. Relayed to the operator before being
  arbitrated, which was ours, not the agent's.
- **"netdata killed at shutdown step 17/22"** — 15 of 22 steps completed. It
  never reached `wait for dbengine collectors to finish`, `stop dbengine tiers`
  or `close SQL databases`; its own counters read 41 restarts, 10 crashes.
- **"everything deployed today is a file that has never been executed"** —
  overstated. The deploy ran goss by hand at 17:25 and the audit re-ran it that
  evening. The defect is the CADENCE (no boot hook, next scheduled run the
  following day), which is narrower and repairable.

### Still open going into the next run

- The six OPEN classes in `classes.md`, of which **C51** has one unswept
  sequence and one suspected instance, and **C50** is unswept at 2 of 64.
- **C03 has now reopened four times.** It needs a gate, not a fifth sweep.
- **C26 is GATED on one of its four axes** and the table said GATED. The argv
  axis still has no assertion; the instance was fixed by hand.
- ~~**C44's remedy is not written.**~~ **Shipped the same evening** (PR #307),
  two lines: `meta: flush_handlers` before the deploy role's posture
  re-assertion, and `OnBootSec=30min` on the timer. Verified live —
  `OnBootUSec=30min`, and the post-flush re-assertion ran `Result=success` with
  its monitor carrying a real reading. **Corrected, NOT gated**: nothing stops a
  future timer shipping without a boot hook, and C53's second instance is
  untouched (`Restart Docker` still lands after the deploy has configured the
  stack against the old daemon).
- **C44's cardinal was wrong and is corrected in `classes.md`: 1 instance, not
  12.** The 12 counted `homelab-*` timers lacking `OnBootSec`, which is a proxy
  for the property rather than the property. Re-read against *a verification
  whose cadence cannot observe the event it guards*: `homelab-health` runs every
  five minutes and sees any post-boot state on its own, the dailies and weeklies
  guard facts a reboot does not change, and only the posture check both guards
  state that a reboot and a deploy alter and ran on a cadence blind to both.
  **A convenient enumeration is not a cardinal** — the same trap this file
  records from 2026-08-22.

## The run of 2026-08-30 (night) — the key was `identity`, and the gate written the night before was already leaking

### State, in one line

Four OPEN classes closed by enumeration (C50, C51, C52, C54), twelve minted, six
of them OPEN. Counts live in `classes.md` and **only** there.

### Two decisions, so nothing reopens them

- **C05 is bounded from now on by `docs/03-security/README.md`, not by
  imagination.** The class was recorded for days as "not exhaustible by sweeping"
  because *what a reader would assume* has no cardinal. That was the wrong
  reading: the document IS the reader's expectation, written down and countable
  at 53 statements. Do not restore the "unbounded" framing.
- **C45 stays ENUMERATED and is not promoted.** Its assertion is well built; its
  emitter list is not derived. Promotion waits for the marker's emitters to come
  from the machine rather than from a list.

### New instrument traps — six, and three were ours

1. **A perimeter probe fired from the LAN traverses the hairpin NAT and reads
   443 OPEN.** False. The same probe from the offsite uplink, with two positive
   controls, settles it. Never conclude anything about the router's forwarding
   from inside the house.
2. **`pg_isready -d <db> -U <user>` ignores both arguments.** It returns
   `accepting connections` and exit 0 for a database and a role that do not
   exist — byte-identical to the real call. Any probe built on it proves the
   postmaster listens, nothing else. **The control is what proves it**: run it
   with deliberate nonsense and compare.
3. **`grep -q <field>` on a JSON body matches the FIELD NAME.** Kuma's own
   healthcheck greps `entryPage` against `{"type":"entryPage","entryPage":null}`
   and passes on a null value. Grep the value, or parse.
4. **`/run/netdata/` does not exist on the HOST.** Checking it there and
   concluding the control pipe is absent is a namespace error — ours, for one
   turn. The pipe lives inside the container, and `docker exec netdata
   netdatacli ping` answering `pong` is the positive control.
5. **`ps -u <name>` on the host attributes container processes to a host
   account** whenever a container's uid collides with one. It is how Collabora
   surfaced, and it will mislead anyone reading it as "this service spawned
   that".
6. **Ansible's invocation log records the CALL, not the change.** The task that
   writes `/etc/docker/daemon.json` was invoked **10 times** since 2026-08-14 (4
   on the 16th, 5 on the 27th, 1 on the 29th), while the file's `mtime` is
   `2026-08-29 23:53:32` — so **at most one** of those ten actually changed it.
   Counting the ten log lines would answer "ten Docker restarts" where the
   machine took **one** of Ansible origin; the other restarts that night carry
   the `sudo ... systemctl restart docker` signature of a human hand.
   `mtime` is the instrument that answers the question asked. Textbook C03, found
   by the agent against its own earlier reasoning.
7. **A uid-collision sweep with a loose predicate is worthless.** Counting every
   container whose PID-1 uid resolves to a host account gives 15 of 29 — 14 of
   them root. The property is a collision with a *non-system* account, and that
   is 5. Ours, and it is the same "convenient enumeration is not a cardinal"
   trap the register records from 2026-08-22.

### Claims that did not survive verification — two agents' and one of ours

- **"The `claude` account is root de facto via the `docker` group."** No.
  `id claude` -> `uid=1001 gid=1004 groups=1004`; `getent group docker` ->
  `marc-gavanier` alone; no sudoers entry; no `authorized_keys`. The account is
  real and undocumented — the class stands — but its privilege is that of an
  ordinary user. Independently confirmed by a second agent.
- **"fail2ban's Nextcloud/Vaultwarden jails cannot ban VPN clients."** No. The
  measured 77.5 % of Traefik lines arriving as `172.18.0.1` is real (recounted
  independently, 4458 of 5752), and `172.16.0.0/12` is indeed in `ignoreip` —
  but the masked traffic is **Uptime Kuma's own probes** (`/healthcheck`,
  `/ping`, `/health`, `/alive`, empty user-agent on 4459 of 4459). VPN clients
  appear in the clear as `10.8.0.x` and are in no ignored range. The headline
  survived; the causal claim did not.
- **"Collabora carries `coolmount cap_sys_admin`, so the capability sweep's
  blindness is an exposure."** Half. The blindness is real and confirmed — the
  container has no shell, so `getcap` cannot run there — but `CapBnd` decodes to
  `cap_chown,cap_fowner,cap_sys_chroot` and `CapPrm`/`CapAmb` are zero.
  CAP_SYS_ADMIN is outside the bounding set: the file bit exists and cannot be
  acquired.
- **Ours: "uptime-kuma's `start_period` has drifted from the repo."** No. Repo
  and host both carry `start_period: 960s` at `compose.yaml:1499`. C27 holds.
  Raised aloud before being checked, which is the error worth recording.

### One operational note

`ansible/roles/deploy/files/backup-notify.sh` lives under `files/`, not
`templates/`, and deploys to `/opt/homelab/scripts/`. The digest deploys to
`/home/claude/.local/share/feed-digest/digest.sh`. **Neither is in
`/usr/local/bin/`**, which is why every enumeration of "the push sites" that
started from a directory has missed them — including the one that wrote C45's
gate, and including ours on the first pass.

### Shipped and verified on 2026-08-31 (PR #308) — do not re-report

Deployed service by service from the branch before merge, each verified on the
running hosts rather than on the play recap.

1. **C45 is closed on the emitters, 10/10 measured on the machines.** The two
   sites the gate could not see now emit the anchored marker. The enumeration
   that finally got to ten was by PROPERTY — every file that curls a Kuma push —
   and it took three tries: a `KUMA_PUSH_URL|api/push` grep missed
   `homelab-netdata-kuma.sh.j2`, which names its variable differently. Counting
   by the words you happened to choose is the same defect as counting by the
   directory you happened to read. `killswitch.sh` is correctly NOT a push site:
   it subscribes to ntfy.
2. **The database probes discriminate**, proven live after deploy on both:
   real pair 0, absent database 2, absent role 2. Immich came back with
   `vchord`/`vector`/`vectors` loaded and 9489 assets — which a `select 1` would
   not have proven either.
3. **Traefik 240 s / redactor 180 s live**, `healthy`, 0 restarts, and HTTPS
   verified end to end through the proxy with a valid certificate.
4. **The fsck ordering holds on both hosts**, and the check that matters is that
   a drop-in on the `systemd-fsck@.service` TEMPLATE propagates to instances:
   `systemctl show <the backup disk instance> -p After` lists
   `fake-hwclock-load.service` on the offsite. `systemd-analyze verify` exits 0
   on both. The offsite's superblock was re-anchored with the clock correct —
   `Last checked Aug 31 01:38`, `Next check after Sep 30`, in the future for the
   first time.
5. **netdata was NOT restarted** by the handler split (`StartedAt` unchanged,
   `RestartCount` 0), which is the point of splitting it.

### Corrections to what this run reported

- **The redactor's PID 1 is `sh`, not the pipeline.** Measured after the
  redeploy: `sh -c exec tail -F ... | awk ...` keeps the shell as PID 1 with
  `tail` (7) and `awk` (8) as children, because `exec` inside a pipeline cannot
  replace the shell. So the C29 calibration relayed earlier — "either death
  exits the container, and the restart policy plus the container-down alarm
  already cover it" — is **wrong**. If `tail` dies the container stays `Up` with
  a `pgrep` healthcheck that passes vacuously. Out of scope for #308 and not
  fixed there; it makes C29's instance an exposure rather than a tidy-up.

### New instrument traps — one, and it was ours three times in one night

8. **`[ -f ]` and `[ -d ]` answer "can I see this", not "does this exist".**
   Without `sudo`, `test -d /proc/<pid>/root` fails on a root-owned process and
   `test -f` fails under a 0750 home — so a guard written that way reports
   ABSENT for everything it cannot read, and the sweep behind it reports clean.
   Paid three times in one session: it made the new capability sweep report 29
   of 29 NOT INSPECTED, and it twice made a push-site count come back short. The
   fix is `sudo test`, and the tell is a sweep that finds nothing at all.

## The run of 2026-08-31 — the key was `scale`, and the gate written the night before was already over budget

### State, in one line

Nine OPEN classes (not eight — the header omitted C03 while its own prose kept
it open), five closed by enumeration, seven minted after arbitrating eleven
proposals, five OPEN at the end. Counts live in `classes.md` and **only** there.

### Three decisions, so nothing reopens them

- **`-p err` must never be added to a `kuma-push-failed:` scan as a speedup.**
  It is a 22x win and it makes the check blind: the marker is written to plain
  stderr, the units run `StandardError=inherit` with `SyslogLevel=6`, and script
  stderr therefore lands at priority 6. Proven with a positive control — `curl:
  (28) Operation timed out after 10001 milliseconds`, unmistakably stderr, sits
  at priority 6. **The remedy for that check is to bound the window**, which its
  own comment already says. If a priority filter is ever wanted, the marker must
  be EMITTED at that priority in the same change, never before.
- **C05's cardinal is 104, not 53**, under a stated criterion: one proposition
  per verifiable predicate, not one per bullet. Three of the seven false
  statements hide inside bullets whose other clauses are true, which is why the
  per-bullet count could not see them. Do not restore the 53.
- **The `scale` key is spent, and it was the last one this project had named.**
  `time` paid 5, `order` 11, `identity` 12, `scale` 7. The rate is decaying,
  which is the good news; the bad news is that the next key has to be invented
  rather than taken off a list, and until one is, no run can honestly claim the
  second half of the termination criterion.

### Measured and rejected — added 2026-08-31

Five leads closed with numbers and needing no action. Recorded so no future run
re-derives them:

- `/mnt/data` grows **+0.913 GiB/day** -> 85 % in ~8.8 years. Offsite
  **+0.524 GiB/day** -> 85 % in ~6.3 years with 525 days of lead. Level
  thresholds are sufficient; **a trend watcher was considered and is not needed.**
- SD card: **1.97 GB/day = 11.5 card-writes per year.** Decades of endurance.
- The data volume's forced fsck falls due ~2026-09-25 and costs **3 min 27 s** —
  dominated by a fixed 152.6 M-inode table, so it does **not** grow with the data.
- Swap is a ceiling, not a ramp: 35.3 % at 25 h after a reboot, post-08-18 peak
  45.0 % against an 85 % gate.
- netdata's 2.2 GB/day of JSON through the socket proxy costs the proxy
  **0.70 % of one core**. Not worth touching.
- fail2ban cannot grow: 0 bans, 1-day purge; no log rotates within 1000x of its
  `findtime`; no auth store exceeds four digits.

### New instrument traps — four, and two were the main session's

1. **`journalctl --since` cost is superlinear in the window and swamped by
   ambient load.** The same query measured 5.63 s at 6 h, 20.04 s at 25 h and
   52.90 s at 48 h at idle, and 59.6 s at 25 h while eight agents were on the
   Pi. **Never quote one reading**: sweep three window lengths in one session,
   and say whether the machine was loaded.
2. **A `-p err` sweep returning nothing is not evidence of no events.** It is
   evidence about priorities, and script stderr is priority 6 by default. The
   control is to find a line you KNOW came from stderr and read its PRIORITY
   field. Ours, and it nearly shipped as a remedy.
3. **A correlation between two logs one second apart is not attribution.**
   Kuma probes 34 monitors on ~60 s cycles, so a one-second coincidence between
   a probe and a real request is the expected case, not evidence. Any such claim
   needs a base-rate control. An agent's, and it was asking to overturn a
   settled entry on that basis.
4. **`free` is not the constraint on a tmpfs write; the tmpfs `size=` is.**
   Reading `free -m`'s *free* column (260 MB) instead of *available* (4038 MB)
   turned a cap question into a false RAM-pressure question. Ours to catch, an
   agent's to make.

### One reasoning trap, and it is subtler than the instrument ones

**A negative result on one axis does not clear a claim tested on another.** Two
agents examined the same "around 7 hours" restore estimate. One asked whether it
had drifted with data growth — it had not, +2.6 % — and reported the lead as not
surviving. The other asked whether it had ever been derived correctly — it had
not, being extrapolated from a 243 MiB / 18 s sample against a true range of
7.4-33 h. **Both were right, and reporting only the first would have been a
false all-clear.** When an agent reports a lead as dissolved, check which
question it actually answered.

## The run of 2026-09-02 — the key was `authority`, and the operator cut the backlog

### Three decisions, so nothing reopens them

- **The next key had to be invented and was.** `authority` asks, for every fact
  the machine acts on, how many places state it, which one binds when they
  diverge, and what detects the divergence. It minted 3 — against 12 for
  `identity`, 11 for `order`, 7 for `scale`, 5 for `time`. First single-digit
  yield, and the first key whose tell was already in the register: C13 and C27
  were narrow cases of a dimension nothing had a general word for.
- **A class may be closed by arbitration, not only by sweeping.** C57 and C66
  both reached the point where the only remaining move was one the operator
  declines to make — a deliberate-failure drill, and an unbounded hunt through
  uncommitted hand-fixes. Recording that as *closed by decision* is more honest
  than leaving them OPEN to be re-sampled by every future run. Two classes had
  already been closed this way (C04, C08); this is now a normal outcome, not an
  exception.
- **What replaces C66 is a method, not a class.** Compare live populations
  against what is written — every unit, every assertion, every path — and ask
  which have one member treated and siblings intact. It bounds without history,
  which `git log` cannot. It found three instances the evening it was proposed,
  including a doc row listing five watched units against the six deployed.

### The operator's arbitration — three items kept, the rest refused

Kept: the port-53 firewall pre-emption, Miniflux's two administrators, and the
documentation tidying. Refused, with the instruction never to raise them again:
the 2026-09-01 Docker daemon stall, `killswitch.service`'s inability to reach
`failed`, the offsite restore that cannot fit, C29's vacuous liveness half, the
offsite root's missing fsck assertion, the files hidden under `/mnt/data`, and
both intrusive measurements. The list lives in `classes.md`'s DECLINED table.

**The lesson for the report, not for the register:** the operator asked for the
findings again in plain language before deciding, and cut six of nine. A run's
output is only as good as the sentence the operator can act on.

### New instrument traps — one, and it was the main session's to catch

**An audit that loads the machine invalidates its own timing measurements.**
Two goss assertions were reported as timing out; re-measured at near-idle they
ran the entire spec in 27.68 s and 24.55 s with zero timeouts. Eight concurrent
agents were the cause. This is trap #1 (`journalctl --since` cost swamped by
ambient load) generalised: **any duration measured while the fleet is running is
a measurement of the fleet.** Re-measure at idle before reporting a timing
result, and say which regime each reading came from.

### One rule-5 violation, disclosed by the agent that made it

`security` provoked a genuine authentication failure against the offsite
`rest-server` while investigating C57, and said so unprompted. Nothing was
persisted and the append-only repository was untouched. It is recorded because
the act was exactly what the register places out of scope — and because the
operator refused that same drill hours later, which makes the violation a
decision taken on their behalf rather than a harmless shortcut.

---

## The run of 2026-09-03 — the key was `representation`, and both open classes closed

### State, in one line

C03 closed 107/107 after nineteen days and seven runs; C75 closed 18/18 with zero
live instances; four classes minted after merging six proposals; the counter went
2 OPEN to 3, all three of them new. Full state in `classes.md`.

### Three decisions, so nothing reopens them

- **The invented key was `representation`**: for every value that crosses a
  boundary, in what encoding does the producer write it, in what encoding does the
  consumer read it, and what detects the mismatch? It minted 4 — against 3 for
  `authority`, 5 for `time`, 7 for `scale`, 11 for `order`, 12 for `identity`.
  Second-lowest yield on record, which continues the decay. **It is now spent; the
  next key must be invented again.** One shape worth passing on: this key found
  its own tell inside the register, exactly as `authority` did. `?immutable=1`
  against `?mode=ro` had been sitting in C03 for weeks as a *validation* defect
  when it is a *representation* defect. Look for a paid instrument trap that no
  class has adopted — that is where the next dimension is hiding, and C80 was
  minted by exactly that route.
- **A mint proposed by three agents from three routes is one class, and the
  convergence is evidence.** Four agents each numbered a mint C77 and only three
  of those were the same class. Merging is part of the run's output: an unmerged
  list inflates the counter and hides the very thing that makes the class
  credible. Two further proposals merged into C78 for the same reason.
- **`| quote` and `| urlencode` appear zero times in the entire tree.** That is
  not a finding, it is the shape of C77's space, and it is why the class is open
  rather than a one-line fix. The only live guard is a single `assert` on one
  variable, added on 2026-09-01 after the outage that paid for it.

### Measured and rejected — added 2026-09-03

- **Size-suffix drift as a class of defect.** Swept on the system side: every
  systemd, tmpfs and logrotate suffix is base-1024 on both the writing and the
  reading side; the only divergence found was 4.86 % in prose, below the noise
  floor. It is not a lead. Do not re-derive it without a consumer that actually
  disagrees with its producer.
- **YAML type coercion in `compose.yaml` and the `.env` files.** 0 coercions,
  57/57 durations suffixed, 41/41 tmpfs sized in `m`, PHP limits coherent at
  512M. Swept; clean.
- **Ansible octal modes.** 185/185 `mode:` quoted, zero bare octal, and 145/145
  deployed permissions matching on both hosts. Swept; clean. Instrument trap
  recorded below.

### New instrument traps — three

- **`stat -c %a` does not follow symlinks**, and produced two false permission
  discrepancies before it was caught. Use it on the resolved target.
- **A `grep` for settable keys that omits `inventory/` reports live knobs as
  dead.** Cost three false "dead knob" findings on the first pass of C28.
- **Instrument trap #1 reproduced a third time, and this time an agent stopped
  instead of paying it.** A `journalctl --since` cross-check for C40 overran 120 s
  under eight concurrent agents and was killed. The agent did not retry it and
  said so, narrowing its own claim to what the surviving instrument supported.
  That is the behaviour this file has been asking for since 2026-08-19: **when
  the load invalidates the instrument, shrink the claim, do not re-run the
  measurement into the load.**
- **`ps` cannot sweep the argv axis for anything that only runs during a deploy.**
  Two agents disagreed about C26 and both were right about what they measured. The
  property has to be swept in the *source* of anything that spawns a process, not
  only in the live process table. This is the scope trap of 2026-08-22 in a new
  costume: **define the class by its property, not by the instrument you happen to
  be holding.**

### One correction the main session made to an agent, and it sharpened the finding

`ansible-deploy` reported that 2 of the 3 units in `mnt-data.mount.wants/` are
unasserted. The facts held; the conclusion was too strong. `units.yaml:54` does
assert `wg-quick@wg0.service` — as `running: true`. `systemctl show` gives
`WantedBy=mnt-data.mount` and nothing else, so that symlink is the sole activation
path of the only remote access to the host. The precise gap is therefore not
"unasserted" but **"the consequence is asserted and the precondition is not"** —
and the consequence is only observable after the reboot that already cost the
tunnel, which is when nobody can act. `systemctl is-enabled` reads the precondition
directly, so the fix is one word in an existing block. The precedent is on file:
`enabled: false` erased that symlink on 2026-07-13.

### One disclosure, made unprompted

`services` reports that the cleartext value of Nextcloud's Redis `save_path`
transited its context, its own redaction having filtered `auth[]=` and not `auth=`.
Nothing was written and nothing was transmitted. Recorded for the same reason as
last run's rule-5 violation: an audit that handles secrets says when it mishandles
one.

## The deploy of 2026-09-04 — what running the corrections found

The audit's thirteen findings were all visible from a repository, a database or
a running process. **The fourteenth existed only while Ansible was running**, and
no agent could have found it: `a5d450f` had written a non-ASCII marker into
`/etc/ufw/after.rules`, which ufw rewrites through an ASCII codec, so the
security role had been unrunnable on the homelab for two days. Nothing was red.
That is C81, and its shape is C82.

### Three decisions, so nothing reopens them

- **Deploying from the PR branch before merging is what found it**, exactly as
  the rule promises. It is now paid for twice over: this defect predated the
  branch entirely and would have surfaced on whatever deploy came next, at a
  moment nobody had chosen.
- **A gate is only a gate once it has failed on purpose in BOTH directions.**
  `ops/check-ascii-system-files.py` was made to fail on the three live markers
  before they were changed, and made to fail again on a deliberately
  re-introduced em dash afterwards. The second half is the one usually skipped.
- **Idempotence is checked before the merge, on every host, per playbook.** Four
  runs, `changed=0` on all four, including the `replace` that repairs the marker
  — a repair task that is not idempotent re-introduces what it just fixed, and
  the only way to know is to run it twice.

### New instrument traps — three, and all three were the main session's

- **A negative result from an instrument that could not read its input.** The
  first search for the offending character ran `grep` without `sudo` against
  0640 root-owned files and came back empty. It produced a confident wrong
  answer for several minutes. **A search that finds nothing must prove it could
  have found something** — the same positive-control rule this file already
  applies to ports and to assertions, applied to file reads.
- **Testing the wrong address and then explaining the result.** A DNS check ran
  against `192.168.1.10`; the host is `192.168.1.100`. The timeout was then
  rationalised at length as "a path nobody uses", complete with a caveat about
  missing baselines. Both were fiction. **Verify the target of a probe before
  interpreting its answer**, especially when the answer is the one that would
  justify a story.
- **A regexp written in byte escapes for a character matcher.** `\xe2\x80\x94`
  in a Python regexp matches three Latin-1 characters, not an em dash. It would
  have matched nothing, silently, and the repair task would have reported
  success while repairing nothing. Caught by testing the pattern against the
  real deployed lines before committing — which is the only reason it is a trap
  and not a fourth finding.

### One fail-open found in our own fix, before it could bite

The task obscuring the WebDAV password through stdin had no guard on its output.
An rclone exiting 0 with an empty stdout would have written `pass = ` into
rclone.conf — well-formed INI, silently wrong, and the vault mount would have
stopped working with nothing to explain it. **A fix that replaces a loud failure
mode with a quiet one is not an improvement**, and the guard went in before the
merge.

## The run of 2026-09-05 — the key was `vacuity`, and the remedy was already written six times

The key: **for every mechanism that consumes or produces a set, a list, a
string, a file or a command's output, what does it do at ZERO elements, and is
that outcome distinguishable from the healthy one?** `scale` had asked what
breaks at ten times the data; nothing had ever asked what happens at none.

### The finding that generalises, and it is about this repo's habits

Eight domains swept 1 216 sites and the instances matter less than their shape:
**the remedy for this entire class is already written into the repository in at
least six places, each on the day one instance was fixed, and it has never been
turned into a rule.** C10's derivation floor, the SQLite dumps' row-count floor,
`homelab-posture.sh`'s absent-vs-unresolvable distinction, ADR-030's "no silent
caps" else-branch, C41's starvation guard, the WireGuard peers' `[ -n "$live" ]`.

Twice the remedy and the gap sit in the SAME FILE: the dump spec asserts
`count(*) from sqlite_master >= 1` for SQLite and asserts only a completion
marker for the three SQL dumps; `homelab-posture.sh` distinguishes an absent
config from an unresolvable mount for Vaultwarden thirty lines below a loop whose
`checked` counter increments over a set that may be empty. This is the
sampling-versus-enumeration pathology the register's preamble describes, applied
to a property instead of to findings.

**The rule worth carrying into new code**: when a mechanism reports on a set, the
report carries the set's cardinal. `checked 0` and `checked 29, healed 0` must
not be the same sentence.

### New instrument traps — two

- **`fail2ban-regex` in FILE mode cannot be used to count date-template hits.**
  It reported zero hits over 4 892 Nextcloud lines, which reads exactly like a
  dead jail and nearly became a headline; a real line from that same file,
  re-tested singly, returns one hit. The negative result did not survive its own
  positive control.
- **A pipeline's exit status is its last command's, and `| jq` launders a failed
  producer into a clean empty answer.** `docker compose config --format json |
  jq …` returns 6 lines from `/opt/homelab` and 0 lines with exit 0 from
  anywhere else. This is the same trap the dump spec's own comment records for
  `zcat | tail`, met again in a runbook rather than in a spec.

### Read the text, not the exit code — where a human is the parser

`cryptsetup status <typo'd-mapper>` prints `is inactive.`, which is the exact
word `luks-header-backup.md` licenses a `luksHeaderRestore` on. The exit code
(4) carries the truth and the page never mentions it. **Wherever a runbook tells
an operator to read output and decide, the empty or not-found case must be
spelled out on the page** — the operator is the parser, and the parser needs the
same floor a script would.

### Confirmed settled, so a later run does not re-derive them

- The vacuous `stdout: []` form is **gone from both hosts**, verified
  independently by three agents across 227-251 deployed assertions.
- 13 of the 14 corrections of 2026-09-03/04 are verified gone **against the
  running systems**, not against git. The fourteenth
  (`/boot/firmware/config.txt` em-dash markers on the homelab) is harmless by the
  role's own measured argument and converges on the next `base` run.
- `nextcloud-notify-push` now mounts `/var/www/html` read-only; C16's recorded
  live instance is gone even though C16's gate is still broken.

### The deploy of 2026-09-05 — the fix reproduced the class it fixed

The five corrections went to the homelab from the PR branch: `ok=197 changed=4`.
One of them pushed a four-minute false DOWN, and it is the best single argument
in this file for deploying before merging.

The new health assertion reads a line the new heal script writes. `observability`
is phase 1, `stack-startup` is phase 5, so the assertion is **always** installed
about ten minutes before its producer. Nothing in the repository, on a dashboard
or in any test could have shown that: it exists only in the interval between two
roles of one play.

**The rule, which generalises past this instance:** an assertion must never
demand a window longer than the producer of its evidence has existed. Start the
window at the later of `now - window` and `mtime(producer)`. Where the producer
can also vanish, make the missing case fail OPEN — `stat … || echo 0` yields an
age of decades, so a deleted producer alarms instead of being excused.

**And the instrument note:** the same event wrote two heartbeats two seconds
apart, the assertion's own DOWN at 08:41:08 UTC and Kuma's "No heartbeat in the
time window" at 08:41:10. Reading only the newest would have blamed a starved
push instead of the assertion that caused it. Kuma stores UTC; applying
`datetime(…, 'localtime')` to a value that is already UTC is right, and doing it
to one that is not shifts the answer two hours — always print `datetime('now')`
from the same query as a control.

---

## The run of 2026-09-05 (midday) — the key was `exclusivity`, and it came back empty

The first run in this skill's history to sweep a new dimension and mint nothing.
Recorded here so the next run does not re-sweep the eight concurrency spaces
that dissolved on measurement. Details, counts and class states live in
`classes.md`, not here.

### Settled, so a later run does not re-derive them

- **No `homelab-*` timer can overlap itself.** All 13 measured against their own
  periods, worst ratio 45-58 s of 300 s under load average 8.06.
  `homelab-stack-heal.timer` is `OnUnitActiveSec`, which makes overlap
  unreachable by construction rather than by luck.
- **`ufw reload` cannot flush a fail2ban chain.** `delete_chains` is a hardcoded
  list, every restore is `-n`, `MANAGE_BUILTINS` is unset, and `flush_builtins`
  is unreachable from a reload. Do not re-investigate.
- **Two concurrent Ansible runs need no lock in this layout**: no fact cache,
  atomic `rename(2)` writes, no `serial`/`throttle`, one host per play. The only
  shared objects are four fixed-name temp paths, and a collision there fails
  loudly.
- **The restic locks are genuinely taken.** Both profile locks are declared in
  the deployed `resticprofile.yaml`, `locks/` is empty, and the weekly units
  carry `--lock-wait 2h` against a 1h38m margin. The 2026-08-17 03:12:53
  collision belonged to the old `backup.sh` and is impossible under ADR-031.
- **One writer per object, wherever it mattered**: 15/15 push tokens, four state
  directories, one `acme.json` writer, one wg-easy allocator (the homelab Pi is
  itself one of its four clients — that is why the address looked shared), and
  exactly one two-writer bind path out of 60, guarded by Redis locking.
- **Nextcloud is 177/177 InnoDB**, so `--single-transaction` on its dump is
  load-bearing rather than decorative.
- **The heal-loop-versus-operator shape has no interlock and does not need a new
  class.** It is a convention, documented in five places, settled via #126, and
  it belongs to C44/C69.

### New instrument traps — five, and two were the main session's

1. **A pipeline ending in `jq` reports `jq`'s exit status.** `docker inspect
   <absent-container> | jq -r '...'` yields exit 0 and an empty line — byte for
   byte what a healthy container with no added capabilities produces. Any goss
   check of that shape is unfalsifiable by construction; a control on a name
   that does not exist is one command and settles it.
2. **`@127.0.0.99` is not a dead DNS target on this host.** Pi-hole's
   `listeningMode: all` binds all of 127/8, so a probe meant as a negative
   control answers. It nearly produced a false headline about the Pi-hole
   healthcheck. A genuinely dead target returns exit 9.
3. **Both hosts run OpenSSH 9.6p1, not 9.8.** The `sshd` -> `sshd-session`
   process rename does not apply here, and any reasoning built on it is wrong
   for this estate. Re-check the version before reusing that argument.
4. **A zero from a journal grep needs a positive control in the same journal.**
   The technique that validated one: run the same failure patterns over the
   whole retained journal with no `_COMM` restriction and group by `_COMM`. It
   returned 7 real authentication failures elsewhere (2 polkit, 5 sudo) and 0
   from any sshd process, which turns "the grep found nothing" into "there is
   nothing to find". This is the antidote to the `fail2ban-regex` file-mode trap
   recorded the night before.
5. **A SMART counter loop cannot assume its attributes exist.** `raw <id>`
   returning empty means the attribute is absent from THIS drive's table, not
   that it is zero. Read the table first: the 5 TB drive holds
   `1 3 4 5 7 9 10 11 12 192 193 194 196 197 198 199 200`, so a loop over
   `5 184 187 198 199` silently checks three of five.

### The main session's own near-miss, recorded because it nearly shipped

`Current_Pending_Sector: 2` on the 5 TB drive reads exactly like a live fault
nobody has been told about. It is not one: it is deliberately excluded from the
disk script's counter loop, always reported, and alarmed on a RISE rather than
on a value — the reasoning is written out at length in the script and in #207,
because a permanently red monitor is a monitor nobody reads. **Check whether the
repo already argued with you before reporting a number as a discovery.**

### Read the file that is deployed, not the file in the repo

Every instance the main session confirmed this run was confirmed by reading
`/etc/goss/*.yaml` and `/usr/local/bin/*` on the host, and two of them were
sharpened in the process. The repo is where a fix is written; the host is where
it is true.

### New instrument traps — two more, both the main session's, both from one afternoon

Added after the corrections of 2026-09-05 were deployed. They are recorded
together because they only bite as a pair, and because each one alone would have
been caught by the other.

6. **Ansible renders Jinja with `trim_blocks=True`; a bare
   `jinja2.Environment()` does not.** So `{%- set x = 1 %}` eats the newline
   BEFORE it (the hyphen) and the newline AFTER it (trim_blocks) on the host,
   while the same bytes rendered on the workstation keep the second one. A
   template verified locally glued a mapping key onto the comment above it on
   the Pi, from one file and one commit. Any local render test must pass
   `trim_blocks=True, lstrip_blocks=False, keep_trailing_newline=True`, and must
   hand Jinja nothing Ansible would not — an earlier version of the same test
   supplied a `len` global that Ansible's Jinja does not have, and the template
   that depended on it would have failed at deploy.
7. **PyYAML accepts duplicate mapping keys and keeps the last; goss's Go parser
   refuses them.** `yaml.safe_load` therefore reports a glued spec as healthy,
   which is exactly what a glued key produces — a second `exec` in the block
   above. Loading with a duplicate-rejecting constructor reproduces goss's own
   message and rendered line number.

Both are closed by `ops/check-goss-specs-render.py` in pre-commit, whose
positive control was the working tree at the moment it was written.

**The general lesson, and it cost two deploys to learn twice:** parsing a
template is not rendering it, and rendering it is not loading it the way the
consumer loads it. `check-jinja-templates.py` states in its own docstring that
"a parse is enough for the whole class". That was true for the class it was
written for and false for this one.

---

## The run of 2026-09-11 — the key was `succession`, and the correct gate had lived for one day

The question no previous key had asked: **against WHICH VERSION of its
counterpart** was this written, and what does that counterpart now IGNORE rather
than refuse? Three admissible shapes — an ignored input, a parse that decays to
empty rather than to an error, a constraint that stopped constraining —
everything else refuted with a number.

### The instrument traps paid, and they are the reusable part

- **An un-`sudo`'d recursive `grep` silently skips root-only files.** It cost the
  `system` sweep three of five output parsers on its first pass and `grep` said
  nothing at all. Any sweep of `/usr/local/bin` on these hosts runs as root or
  states that it did not.
- **The two-control method for any regex written against another component's
  human-readable output**, and it is cheap: (1) extract the PRODUCER's own format
  string from the running artefact — `grep -a` the binary, or the deployed
  source; (2) run the CONSUMER's own engine over a synthetic line in the real
  format *and* one in the format the regex was written for. If the second matches
  and the first misses, the finding is proven rather than argued. That is how the
  Vaultwarden TOTP jail line was settled in one command.
- **Verify a program in the context that will RUN it, not the one that is handy.**
  Paid twice in one evening, both times on the same branch, and it is the most
  expensive trap on this list because the verification LOOKED rigorous each time.
  (1) An awk program was tested over SSH with a positive and a negative control —
  as a program. Ansible renders it through YAML into a shell, where an apostrophe
  inside a comment closed the quote; the deploy died on the host mid-run.
  (2) A goss assertion was tested with `sudo bash -s` and passed in 0.156 s.
  **goss runs its commands with sh**, and dash's `read` builtin returns non-zero
  on a `/proc/sys` file, so every iteration fell through, the counter stayed at
  zero and the anti-vacuity floor fired. Under bash it was green.
  The rule: an Ansible `shell:` cmd is verified by extracting it from the PARSED
  YAML and running that; a goss `exec:` body is verified under **sh**, on the
  host, and preferably under both shells so the difference is visible.
  `ops/check-shell-cmds-parse.py` gates the syntax half of both. It cannot gate
  the runtime half — `read` on /proc is not a syntax error, and dash parses
  `[[ ]]` happily as a command name — so the exercise is not optional.
- **A local `/bin/sh` is not evidence about the target's.** Both are dash here,
  checked with `readlink -f` on both machines rather than assumed; on a host
  where they differ, a static check run locally proves nothing about the deploy.
- **How to tell an IDLE detector from a DEAD one, and it is one measurement.**
  A jail reporting `Total failed: 0` proves nothing on its own — the Vaultwarden
  TOTP line reported exactly that while being structurally unable to match. The
  discriminator is to count what the SOURCE carries over a real window and ask
  whether any line of the shape exists at all. Done on the `sshd` jail over 30
  days: `_COMM=sshd` carries 103 681 messages, of which **2** are auth-shaped —
  both the operator's own aborted LAN connections — and the filter declines them
  correctly in `normal` mode. That zero is honest. A zero with thousands of
  candidate lines behind it is not, and that is the test to run before believing
  any "no bans" figure.
- **`jq -r` appends a trailing newline**, which reads as "the values differ" when
  comparing an environment variable against a config file. It produced a false
  positive in the `services` sweep and was caught by the agent itself.
- **A `ConditionPathExists` that fails records `Result=success`.** "All timers
  green" therefore cannot distinguish *ran* from *skipped* — on this estate that
  is `homelab-ddns` and `homelab-offsite-check`, both of which skip silently when
  `/mnt/data` is locked. Not a defect; a limit on what the baseline proves.
- **`docker exec … sqlite3 "file:…?mode=ro"`** on the live Kuma database remains
  the only correct read; a `cp` misses the WAL.

### What was measured and needs no re-deriving

- **`immich-redis` is durable now**: `--appendonly yes --appendfsync everysec`,
  live AOF growing. The goss exemption that still calls both Redis instances
  persistence-free is prose, not behaviour.
- **`/mnt/data/secrets/docker` is genuinely 0700** and the Compose secrets inside
  it are correctly protected by the parent — proven with a refused read as a
  control. The 0444 problem is confined to the two files that live one level up.
- **Pi-hole FTL binds `:53` as uid 1000 with an EMPTY capability set**, because
  Docker sets `ip_unprivileged_port_start=0` inside the container.
  `NET_BIND_SERVICE` is not what lets it bind. And `CHOWN`/`NET_BIND_SERVICE`/
  `SYS_NICE` must stay in `cap_add` anyway: the binary carries them as file
  capabilities with the effective bit set, and the kernel refuses to `exec` such
  a binary when any is outside the bounding set. **Removing them kills the
  container at exec** — the same mechanism this repo already documented for
  dnsproxy in ADR-017.
- **lynis PKGS-7388 is permanent and means nothing here.** lynis 3.0.9 greps only
  the legacy one-line sources format; `noble-security` is configured in deb822.
  The warning count therefore has a floor of 1. No action — the ratchet compares
  warning IDs, so a real second warning still appears as a new ID.
- **fail2ban has never banned anything on this host** — `bans` and `bips` are
  both empty in `/var/lib/fail2ban/fail2ban.sqlite3`. That is context for any
  future jail claim, not a defect.
- **`restic snapshots --json` at 0.16.4** still carries `short_id`; the one parse
  of restic output in the estate is sound and degrades to a quieter success
  rather than to a failure.
- **All 83 compose-injected environment variables are read** by the versions now
  running, and **26/26 image pins still bind** to the digest the container runs.
- **`sshd -T` accepts all 22 keys** the repo sets on OpenSSH 9.6p1. The
  `_COMM=sshd` → `sshd-session` rename that will break the sshd jail's
  `journalmatch` arrives at OpenSSH 9.8 and has not landed.

### The lesson the register took from it

The scope trap was paid for a sixth time, and its shape has changed. The bound
that failed was no longer a directory someone happened to be reading — **it was
a correct, DERIVED gate whose derivation keys on the wrong axis.** C10 derives
its set from container bind mounts, so a credential file no container mounts
cannot enter it for any value of the data. A derived gate reads as the strongest
kind there is, and that is exactly why its blind spot is invisible from inside
it. The question to ask of a derived gate is no longer "is it derived?" but
**"derived along which axis, and what does that axis structurally exclude?"**

And one detail worth keeping for its own sake: the gate that would have caught
the 0444 secrets — `world_readable_secret_writes()`, which derived its
population from the `dest:` of every task writing under the secrets directory —
was written one day and deleted the next, bundled into the revert that created
the defect it was written for.


## The run of 2026-09-05 (evening) — the key was `interruption`, and it reset the clock twice in one day

The second invented key of the same day, and the first one this skill has run
whose stated result was *"come back empty"*. It did not: it kept two mints and
reopened two classes. Counts and class states live in `classes.md`; what follows
is what a later run must not re-derive, and what it must not be caught by.

### Settled, so a later run does not re-derive them

- **Ansible does not leave half-written files.** `atomic_move` covers all but
  three of the module write sites in the installed ansible-core, `unsafe_writes`
  appears nowhere in the repo, and the corresponding residue is absent from both
  hosts. The dangerous shape — new file, old service, after an aborted play —
  was measured pair by pair against `StartedAt` / `ActiveEnterTimestamp` on both
  machines and every pair was consistent. Do not re-open this without a new
  symptom.
- **An interrupted `pihole -g` cannot poison the gravity guard.** `gravity.sh`
  writes `info.updated` into the TEMPORARY database and the swap is a `mv`, so a
  build that stops halfway neither refreshes the timestamp the guard reads nor
  leaves a half-built list in service.
- **A truncated dump can neither survive nor be certified.** The dumps write in
  place, but the C18 floor is a completion marker rather than a size, and it runs
  after every dump and before the snapshot.
- **An interrupted offsite copy has been caught and retried, twice, in the
  historical record.** The retry is not theoretical.
- **`dpkg` is not in a half-configured state on either host**, `copytruncate`
  loses nothing measurable on the Traefik access log, and no `TimeoutStopSec`
  has ever been reached on a `.service`.
- **No reporting chain pushes "up" for its own first half.** They all push once,
  on their last line.
- **The staged startup writes no progress marker**, so there is no resume that
  can skip a step.
- **The restic `locks/` directory is not reliably empty.** Stale locks appear
  when a tool timeout kills a restic command; restic expires them at 30 minutes
  and they mean nothing. Do not report one as a finding. And `--lock-wait` in
  the weekly units is *resticprofile*'s lock, not the repository's — the two
  were conflated once already.

### New instrument traps — three, and the first one nearly cost a correct finding

1. **Check the boot id before reasoning about any timestamp on this host.**
   `fake-hwclock` makes consecutive boots OVERLAP in wall-clock time: boot -1
   here begins twenty-eight minutes *before* boot -2 ends, because its early
   clock is restored from the saved file and corrected later. A merged
   `journalctl` therefore prints a line from the new boot in the middle of the
   old boot's shutdown, and the natural reading — "this condition check
   preceded those refusals, so the mechanism was disarmed" — is exactly wrong.
   The main session reached that wrong conclusion and only a per-boot
   `journalctl -b <id>` overturned it. Related to but distinct from C42: that
   class is about ranking BY a bad timestamp, this is about reading a merged
   journal AS IF timestamps ordered it.
2. **`ON_ERROR_STOP=on` plus `--single-transaction` does not make a `psql` load
   atomic against a TRUNCATED input, but it does not fail to either — it depends
   on where the cut falls.** A cut inside a `COPY` block's data that happens to
   end at a record boundary is read as a clean end of input: psql commits the
   partial table and exits 0 with an empty stderr. A cut that leaves a partial
   record errors and rolls back. Measured over thirty truncation points on the
   runbook's exact pipeline: twelve committed silently, eighteen were caught.
   **So never report this shape as "always silent" or as "guarded" — report the
   proportion, and say the guard answers "did a SQL statement fail", not "did
   the input end early".**
3. **A pipeline that ends in `psql` reports `psql`'s status, so the `gunzip`
   that failed upstream is visible only as a line on stderr.** Same family as
   the `jq` trap recorded that morning. The antidote for a restore is not
   `pipefail` in a runbook nobody will paste correctly — it is a `gzip -t`
   before the step that destroys the live data.

### One method note, and it is the reason two proposals became reopenings

Four mints were proposed and two were kept. The two that were refused were
refused by the same sentence, applied symmetrically: *define the class by its
property, not by the directory you happen to be reading.* A USB tamper response
refused by systemd is C74's property in a slice C74's sweep never covered; a
script that destroys its own artefact after parsing it is C82's property in a
slice C82's sweep never covered. **An agent had already applied that argument
against its own second proposal before the main session saw it, which is what
made the symmetry obvious.** Reopening a class with a restated space is a
better outcome than minting a near-duplicate: it says the cardinal was wrong,
not that a new dimension exists.

### The keys are now nine, and `interruption` is spent

`time`, `order`, `identity`, `scale`, `authority`, `representation`, `vacuity`,
`exclusivity`, `interruption`. A run that reuses one proves nothing. The two
that paid best were both found the same way: look for an instrument trap in this
file that no class has adopted, or a pair of narrow classes in `classes.md` that
are obviously two faces of a dimension nobody named.

### One more instrument trap, from the same evening, and it is free

**A journal grep meant to return zero can be controlled by the audit line of its
own invocation.** `sudo` journals the `COMMAND=` of the command being run, so a
`journalctl --grep=<pattern>` run under `sudo` will always match at least its
own `sudo` line — which proves the grep reaches the journal and the pattern
compiles. That satisfies instrument trap #4 above at no cost. Note the price:
an untagged `--grep` over the whole retained journal takes about half an hour on
this host and must be run in the background.

### An instrument trap paid during the deploy of the corrections, 2026-09-05

**A healthcheck that answers before the configuration is read cannot report a
configuration error.** Traefik's `/ping` entry point on :8082 comes up before
the static configuration is parsed, so a fatal static-config error produces a
container that restart-loops while `docker inspect` reports **healthy** and the
health log shows an unbroken run of `OK: http://:8082/ping`. Nothing in the
container's status distinguishes "serving" from "exiting every 60 seconds". What
did distinguish them: `docker ps` showing `Restarting (1)`, and the Kuma
monitors — which is the composition the register keeps crediting.

**And the warning that caused it names the wrong level.** Traefik 3.7 says
"Please set it to delete or reject **on the entry points** fronting such
backends", and `aliasHeadersStrategy` lives one level below that, under the
entry point's `http:`. Written where the sentence suggests, traefik exits with
`command error: field not found, node: aliasHeadersStrategy`. Six minutes of
reverse proxy.

The general rule, and it is the cheap one: **when an upstream warning tells you
to set an option, ask the BINARY where the option lives before believing the
prose.** `traefik --help` lists the full flag path
(`--entrypoints.<name>.http.aliasheadersstrategy`) and settles it in one
command. Then parse-test the candidate file in a throwaway container
(`docker run --rm --network none -v <candidate>:/etc/traefik/traefik.yml`):
reaching provider startup — even with provider errors from the missing network
and volumes — proves the static configuration loaded, which is exactly the stage
that fails.

### The C26 leak: closed the same evening, and one artefact worth not re-discovering

Fixed at the source (`RESTIC_PASSWORD_FILE`, verified by a deploy that wrote zero
lines against 374 `BECOME-SUCCESS` lines in the same window), then purged from
both stores on 2026-09-05.

- `auth.log` and its four rotations were **redacted in place, not deleted** — the
  lines stay, the value becomes a token. An authentication log with holes in it
  is worth less than one with the secret struck out.
- The rewrite was done with **rsyslog stopped**. Reading a live log and writing
  the result back loses whatever arrived in between (measured: 17 lines), and
  `sed -i` on a file rsyslog holds open changes the inode and stops logging
  SILENTLY. Nothing is lost by the stop itself, because journald holds the same
  events.
- Every affected **journal** file was a `user-1000` journal; not one system file
  carried the value. So the fix was to delete 27 archived user journals — whose
  content is the `sudo` session trail that `auth.log` now keeps in redacted form
  — and the system journal's history survived intact.
- **The offsite host never had it**, and the reason is structural rather than
  lucky: it does not run `restic init` under `become`.

**The artefact, and it fooled the first pass twice:** `sudo` journals the
`COMMAND=` of the command being run, so **a grep for a secret's NAME adds a
matching line to the very log it searches**. A count taken twice grows between
the two readings, and every residual match after a purge is likely to be the
purge's own verification. Always inspect the residue before believing it, and
require a value (`BECOME-SUCCESS` is the discriminator for this leak) rather
than a name.

## The run of 2026-09-26 — the key was `precedence`

### Settled, so a later run does not re-derive them

- **needrestart: our drop-in assigns `override_rc` key by key.** A whole-hash
  assignment in `conf.d/` replaces the vendor's 43 exclusions (dbus, logind,
  `user@`, getty…). The cost, accepted: those services wait for a reboot after a
  library update instead of being restarted hot. C124.
- **Pi-hole's `FTL.log` and `webserver.log`: `daily` + `rotate 21`.** The only
  rotator is `pihole flush` with `--force`, so a period is never read;
  retention is written in generations.
- **The postfix `main.cf` edits on a fresh host (C122) are left as they are.**
  The operator will decide between installing postfix explicitly and skipping
  the edits when it is absent as part of the mail work. Do not re-propose before
  then, and do not re-propose rkhunter.
- **`NEXTCLOUD_TRUSTED_DOMAINS` stays in `compose.yaml`** for a from-scratch
  install; `trusted_domains` on the live instance comes from the `occ` task.
- **The two infrastructure WireGuard peers keep their split tunnel only in their
  own `wg0.conf`.** The deploy's enforcer rewrites `allowedIps` for every client;
  there is no per-client value in the repository. Documented, not changed.
- **The glibc / resolved divergence on the homelab is structural** — resolved
  follows `eth0`'s DHCP DNS (Pi-hole), glibc reads the repository's
  `resolv.conf`. Nothing on the host uses resolved; documented as a diagnostic
  trap.
- **restic precedence, proven on the deployed version:** `--password-file` beats
  `RESTIC_PASSWORD`, `--repo` beats `RESTIC_REPOSITORY`. The deployed pairs carry
  equal values.

### New instrument traps — three

- **`needrestart.conf` ends by including `conf.d/`.** "The vendor file alone" is
  obtained by cutting it before that loop, not by evaluating it.
- **A Docker tmpfs inherits the mode of the image's directory at that path**
  (`755 root` on `/var/cache/nginx` in `nginx:alpine`, `1777` on `/tmp`). There
  is no single default to argue about; measure per path.
- **The session scratchpad does not survive a reboot of the workstation.** The
  eight reports of this run were lost before the corrections; only the agents'
  summaries remained. A summary must carry file:line for every instance it asks
  to be fixed.

### After a restart of dbus

`systemd-timesyncd` and `systemd-resolved` keep working but stop answering on the
bus (`timedatectl show-timesync`, `resolvectl` time out) until the next boot, and
`systemctl --failed` does not show it. Seen on both hosts on 2026-09-26. With
C124 fixed, needrestart no longer restarts dbus.
