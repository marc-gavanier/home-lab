#!/usr/bin/env python3
"""Reject non-ASCII in content Ansible writes into ASCII-strict system files.

Why this exists, measured on 2026-09-04. `a5d450f` gave two blockinfile tasks a
marker containing an em dash and wrote it into /etc/ufw/after.rules. ufw rewrites
that file line by line whenever the default policy is set:

    ufw/backend_iptables.py:156 -> ufw.util.write_to_file(fd, line)
    ufw/util.py:256             -> os.write(fd, bytes(out, 'ascii'))

so the next run of the security role died with

    UnicodeEncodeError: 'ascii' codec can't encode character '\\u2014' in
    position 24: ordinal not in range(128)

position 24 being exactly where the dash sits in "# BEGIN ANSIBLE MANAGED - ".
It was latent for two days because the failing task runs BEFORE the task that
writes the marker, so the run that introduced it succeeded. Nothing else would
have caught it: yamllint reads UTF-8 happily, ansible-lint checks task structure,
and the file is only rewritten by ufw itself.

Two checks, and the difference between them is deliberate:

  1. Every `marker:` in the tree must be ASCII. A marker is ALWAYS written into
     the target file — unlike a YAML comment — so this is cheap, complete and
     has no false positives.
  2. Anything written to a path this file lists as ASCII-strict must be ASCII
     throughout: `block:`, `content:`, `line:` and `marker:`. The list is short
     and named, because "which consumers are ASCII-strict" is a fact about the
     consumer and cannot be inferred from the YAML.

Prose in a `content:` bound for goss, fail2ban or systemd is NOT flagged: those
read UTF-8 without complaint, and this repository's comments earn their keep.

Nor is a ufw RULE COMMENT, and the reason bounds this class rather than merely
excusing it: ufw hex-encodes rule comments into user.rules
(`comment=426974...c2b5...`), so any byte survives there by construction —
measured on the host, the live "\u00b5TP/DHT" comment appears as c2b5 and no rule
file contains a raw non-ASCII byte. A raw line or marker in after.rules is
written verbatim; a rule comment never is. That is the whole difference.

Nor is a `state: absent` blockinfile. There the marker is a SEARCH KEY for a
block already on the host, not content being written — retiring a bad marker
requires naming it, and a check that forbade that would forbid its own remedy.
"""
import pathlib
import sys

import yaml

REPO = pathlib.Path(__file__).resolve().parent.parent
ANSIBLE = REPO / "ansible"

# Consumers that rewrite their own configuration through an ASCII codec.
# Add a prefix here only with the line of source that proves it.
ASCII_STRICT_PREFIXES = ("/etc/ufw/",)

WRITTEN_KEYS = ("block", "content", "line", "marker", "replace")
PATH_KEYS = ("path", "dest")


def non_ascii(text):
    return [c for c in str(text) if ord(c) > 127]


def walk_tasks(node):
    """Yield every mapping that looks like a task, at any depth."""
    if isinstance(node, dict):
        yield node
        for value in node.values():
            yield from walk_tasks(value)
    elif isinstance(node, list):
        for item in node:
            yield from walk_tasks(item)


def main():
    failures = []
    for path in sorted(ANSIBLE.rglob("*.yml")):
        try:
            docs = list(yaml.safe_load_all(path.read_text(encoding="utf-8")))
        except (yaml.YAMLError, UnicodeDecodeError):
            # Vault-encrypted vars and anything unparseable: not our business.
            continue
        rel = path.relative_to(REPO)
        for doc in docs:
            for task in walk_tasks(doc):
                for module_args in task.values():
                    if not isinstance(module_args, dict):
                        continue

                    # `state: absent` names a marker to FIND, not one to write.
                    retiring = module_args.get("state") == "absent"

                    marker = module_args.get("marker")
                    if marker is not None and not retiring and non_ascii(marker):
                        failures.append(
                            f"{rel}: marker is not ASCII -> {marker!r} "
                            f"(a marker is written into the target file)"
                        )

                    target = next(
                        (module_args[k] for k in PATH_KEYS if k in module_args), None
                    )
                    if not isinstance(target, str):
                        continue
                    if not target.startswith(ASCII_STRICT_PREFIXES):
                        continue
                    for key in WRITTEN_KEYS:
                        if key not in module_args:
                            continue
                        if retiring:
                            continue
                        bad = non_ascii(module_args[key])
                        if bad:
                            failures.append(
                                f"{rel}: `{key}:` written to {target} contains "
                                f"non-ASCII {sorted(set(bad))!r} — that file is "
                                f"rewritten by an ASCII-only codec"
                            )

    if failures:
        print("Non-ASCII bound for an ASCII-strict system file:\n", file=sys.stderr)
        for line in sorted(set(failures)):
            print(f"  {line}", file=sys.stderr)
        print(
            "\nUse plain ASCII there. Prose comments elsewhere are fine — this "
            "check is about bytes that reach a consumer which cannot read them.",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
