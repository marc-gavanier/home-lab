# ADR-027 — A daily feed digest, and the token that turned out to be unnecessary

**Date**: 2026-08-13
**Status**: accepted — implemented and verified end to end on the Pi

## Context

Miniflux has been running since today (ADR-026) with **121 feeds**. That number is
deliberately too large for a human to read: the point was never to read it, but to have a
corpus wide enough for a daily summary to cross-reference. Marc was explicit — he does not
intend to read any of it, and wants a scheduled job to do it for him.

The sub-project has been described in issue #15 since 2026-07-19 and was deliberately kept
out of the Miniflux PR (#86) so that one change would not carry two subjects.

## Decision

A daily systemd timer has **Claude Code in `-p` mode** read Miniflux, writes a note into the
Obsidian vault, then marks the summarised entries read.

### The OAuth token in the spec was not needed

Issue #15 called for a long-lived token from `claude setup-token`, valid about a year and
stored in the Ansible vault. That was the most fragile piece of the design: a secret that
expires silently, once a year, on a job nobody watches.

Measured before writing a line of code:

```
sudo -u claude /home/claude/.local/bin/claude -p "Réponds exactement: OK"
→ OK
```

`claude -p` works non-interactively with the **session credentials already present** in
`~claude/.claude`, the ones Remote Control's claude.ai login left there. No extra token, no
secret to rotate. The #15 spec is corrected on this point.

### The script writes the note, the model does not

Claude receives the entries on stdin and emits nothing but markdown on stdout. The shell
script composes the frontmatter and writes the file.

Two benefits, and the second is the real one: the frontmatter stays deterministic and
compliant with the vault's own `CLAUDE.md`, and **the job needs no write tool at all**. A
digest that wrote into the vault itself would need permissions its attack surface does not
justify.

### The prompt lives in its own file

`feed-digest-prompt.md.j2` is separate from the script because it is the part meant to be
tuned. Adjusting the tone of a summary should not require reading shell.

#### The default is generic, the personal version lives in the vault

The split is not only about editing comfort. **This repository is public.** Marc's voice
profile, his day-to-day stack, his weekly publishing calendar and the rules he writes by are
not repository material — they are personal working notes that happen to be expressible as a
prompt.

So the two files carry different things:

| | Repo default | Vault override |
|---|---|---|
| Audience | anyone running this role | the person reading the digest |
| Content | prioritise, group, do not invent | plus their stack, slots and writing rules |
| Public | yes | no |

The default has to stand on its own: with no override it must still produce a useful digest,
so it carries the whole structure — security first, breaking changes, notable releases, the
rest collapsed into one bullet — and the rules that are not personal (assert nothing the
sources do not say, no superlatives, prefer a measurement to an authority, be short when the
day is empty). It says nothing about who reads it.

The override adds the person: the stack to filter against, the publishing slots, and a
second section that turns entries into things worth writing about. It establishes that
**zero such items is a valid answer** — most days produce none, and a digest that invents
them becomes noise people stop reading.

The two never have to agree on anything, including output language, because they never both
apply.

#### The override wins, and Ansible cannot reach it

`ansible.builtin.template` is authoritative by design, and this role leans on that hard —
it *purges* slash commands deleted from the repo so the host cannot drift from git. That is
right for infrastructure. A prompt is not infrastructure: it is tuning, adjusted the morning
a digest reads badly, from whatever device is at hand.

So the repo keeps full ownership of the default at
`~claude/.local/share/feed-digest/prompt.md`, and the script prefers
`<folder>/prompt.local.md` when it exists. The two can never collide:
Ansible has no reason to write into the vault, and the override is out of its reach by
construction.

Putting the override **in the vault** rather than next to the default is the part worth
justifying. It syncs through Nextcloud, so it is editable from Obsidian on any device,
phone included — and 06:30 is when the digest lands, which is exactly when a bad prompt
announces itself. The cost is that the override is not version-controlled; it is covered by
restic like the rest of the vault, and anything worth keeping should be folded back into
the template.

The override wins **silently**: no staleness warning when the repo default moves on. That
was a deliberate call — a recurring "your override is old" line in a daily job is noise that
gets tuned out. Which prompt is in use *is* logged, because a digest that suddenly reads
differently is otherwise very hard to explain.

### What is capped is reported

The job sends at most 400 entries per run. Beyond that, entries **stay unread** for the next
run, and the carried-over count appears both in the note and in the Kuma message. A digest
truncated in silence reads exactly like a complete one, which is the worst of both worlds.

### Three guards, two of them born from incidents the same day

- **`TimeoutStartSec=900`.** On 2026-08-13, six abandoned `claude` sessions were holding
  1.5 GB of RAM and 525 MB of swap on this host, some for eleven days, and had saturated
  swap. They were interactive, so someone eventually noticed. A timer-driven job that never
  exits would do the same thing with no witness.

  **The first version wrote `RuntimeMaxSec`, which systemd ignores under `Type=oneshot`** —
  a warning in the journal, buried among the start lines. And since `Type=oneshot` defaults
  `TimeoutStartSec` to *infinity*, the guard this ADR made the most noise about bounded
  precisely nothing while claiming otherwise. Caught on the first manual run, by reading the
  journal. A oneshot service is "starting" for its whole life, so the start timeout is what
  bounds it.

- **The `/proc/mounts` gate.** Taken as-is from `claude-remote-control.service`. When the
  rclone mount is absent the mount point still exists as an empty local directory: without
  this gate the note would be written to the SD card instead of Nextcloud, and nothing would
  report the error. Same reason for the soft `Wants=` rather than a hard `Requires=`,
  documented by a 54-hour outage in July.

- **A Kuma dead-man's switch.** A daily job that stops running is invisible by construction.

### The note goes in `Domaines/`, not `Inbox/`

The vault's `CLAUDE.md` applies PARA and warns that the Inbox must not become a dumping
ground. A daily automated drop would make it one within two weeks. Feed digest is a
continuing responsibility with no end, hence a folder of its own, with a
presentation note like every folder in that vault and dated notes named
`YYYY-MM-DD - <suffix>.md`.

## Verification

First manual run, 30 entries: **37 s wall clock, 8.2 s CPU**. Note written, entries marked
read, Kuma pushed. The output respected the priority order (security first), grouped what
did not deserve a line ("six other CERT-FR advisories outside the stack") instead of listing
each, and proposed two angles with a thesis, a slot and supporting evidence — one of them
suggesting a figure Marc could measure himself rather than an authority to cite.

## Consequences

- Miniflux becomes **a database, not an inbox**. Entries are marked read after summarising:
  the daily note is the only entry point, and the links it carries are the only route back
  to the articles.
- The job consumes Marc's Claude Code subscription, not a metered API key.
- Two manual steps remain, both irreducible: creating the API key in Miniflux (the API
  cannot mint its own) and the Kuma monitor (v2 has no supported automation).
- The prompt is a living artefact. When a digest reads badly, the prompt is what gets fixed,
  never the note.

## Related

Issue #15 (digest sub-project), ADR-026 (Miniflux), ADR-023 (Dozzle), ADR-011 (secrets on
LUKS), ADR-016 (secrets out of the environment),
`knowledge/runbooks/feed-digest.md`, `docs/05-services/claude-code.md`.
