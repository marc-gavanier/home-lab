#!/usr/bin/env python3
"""Refuse a secret passed through `environment:` in an Ansible task.

WHY THIS EXISTS
---------------
Ansible's become wrapper renders a task's `environment:` as an assignment on
the command line it hands to sudo:

    sudo ... /bin/sh -c 'echo BECOME-SUCCESS-xxxx ; P=<the secret> python3 ...'

and sudo journals the command line it runs. So the value lands in
/var/log/auth.log and in the systemd journal, both readable without sudo by any
account in the `adm` group. `no_log: true` does not help: it suppresses
Ansible's own output, not the wrapper.

Three tasks in this repo had that shape on 2026-09-05 — `restic init`, the
Pi-hole auth probe and the Vaultwarden Argon2 hash — and together they had
written two live secrets into the logs several hundred times.

WHY NINE AUDITS MISSED IT
-------------------------
The variable names were `P` and `T`. They were chosen deliberately, to keep the
value out of the program's argv, which was the previous defect in this same
class. **The name of the variable is picked by the author, not by the secret**,
so no search for *PASSWORD* / *TOKEN* / *SECRET* can ever be complete. Only a
search for the VALUE finds these, and this gate exists so that nobody has to.

WHAT IT CHECKS
--------------
The secret set is DERIVED, not listed: it is the set of variables this repo
already treats as secrets, read out of the deploy role's own assertions and out
of every file it writes under /mnt/data/secrets. A new secret is therefore
covered the day it is added, without editing this file — which is the property
that C13 and C20 lacked when they were demoted from the register's gated list.
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SECRETS_TASKS = ROOT / "ansible/roles/deploy/tasks/secrets.yml"
TASK_GLOBS = ("ansible/roles/*/tasks/*.yml", "ansible/playbooks/*.yml")

VAR_RE = re.compile(r"\{\{\s*([a-zA-Z_][a-zA-Z0-9_]*)")


def derive_secret_vars(text):
    """The variables this repo itself treats as secrets.

    Two independent sources, unioned, so that dropping one does not silently
    shrink the set: the `var:` entries of the empty-secret assertion, and every
    variable interpolated into something written under /mnt/data/secrets.
    """
    names = set()
    for m in re.finditer(r"^\s*-\s*var:\s*([a-zA-Z_][a-zA-Z0-9_]*)\s*$", text, re.M):
        names.add(m.group(1))
    for block in re.split(r"^- name:", text, flags=re.M):
        if "/mnt/data/secrets" not in block:
            continue
        for m in VAR_RE.finditer(block):
            n = m.group(1)
            if n in ("item", "ansible_managed"):
                continue
            if n.endswith(("_password", "_token", "_key", "_secret", "_hash",
                           "_url", "_keyword")):
                names.add(n)
    return names


def environment_blocks(text):
    """Yield (line_number, key, value) for every mapping under `environment:`.

    Read as text rather than through a YAML load on purpose: a task file that
    fails to parse must not silently pass this gate.
    """
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        m = re.match(r"^(\s*)environment:\s*$", lines[i])
        if not m:
            i += 1
            continue
        indent = len(m.group(1))
        j = i + 1
        while j < len(lines):
            line = lines[j]
            if not line.strip():
                j += 1
                continue
            cur = len(line) - len(line.lstrip())
            if cur <= indent:
                break
            kv = re.match(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*(.+)$", line)
            if kv:
                yield j + 1, kv.group(1), kv.group(2)
            j += 1
        i = j


def scan(root, secret_vars):
    bad = []
    for glob in TASK_GLOBS:
        for path in sorted(root.glob(glob)):
            text = path.read_text(encoding="utf-8")
            for lineno, key, value in environment_blocks(text):
                for m in VAR_RE.finditer(value):
                    if m.group(1) in secret_vars:
                        bad.append((path.relative_to(root), lineno, key, m.group(1)))
    return bad


def selftest():
    """Positive and negative controls, run beside the gate rather than trusted.

    The positive control is the defect as it actually stood on 2026-09-05.
    """
    import tempfile

    secrets_src = """
- name: secrets | Refuse to deploy silently-empty secrets
  loop:
    - var: pihole_password
    - var: restic_password
- name: secrets | Write the Pi-hole admin password
  ansible.builtin.copy:
    dest: /mnt/data/secrets/docker/pihole_password
    content: "{{ pihole_password }}"
"""
    secret_vars = derive_secret_vars(secrets_src)
    failures = []
    if "pihole_password" not in secret_vars or "restic_password" not in secret_vars:
        failures.append("derivation did not find the asserted secrets")

    cases = [
        ("MUST FLAG - the real defect",
         '  environment:\n    P: "{{ pihole_password }}"\n', True),
        ("MUST FLAG - descriptive name",
         '  environment:\n    RESTIC_PASSWORD: "{{ restic_password }}"\n', True),
        ("must pass - a non-secret variable",
         '  environment:\n    S: "{{ vaultwarden_admin_salt }}"\n', False),
        ("must pass - a path, not a value",
         '  environment:\n    RESTIC_PASSWORD_FILE: /mnt/data/secrets/restic_password\n', False),
        ("must pass - the secret outside an environment block",
         '  ansible.builtin.copy:\n    content: "{{ pihole_password }}"\n', False),
    ]
    with tempfile.TemporaryDirectory() as d:
        root = Path(d)
        (root / "ansible/roles/x/tasks").mkdir(parents=True)
        for label, body, should_flag in cases:
            target = root / "ansible/roles/x/tasks/main.yml"
            target.write_text("- name: t\n" + body, encoding="utf-8")
            flagged = bool(scan(root, secret_vars))
            if flagged != should_flag:
                failures.append("%s: flagged=%s expected=%s" % (label, flagged, should_flag))

    for f in failures:
        print("SELFTEST FAILED: %s" % f, file=sys.stderr)
    if failures:
        return 1
    print("selftest: %d controls, all as expected" % len(cases))
    return 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    secret_vars = derive_secret_vars(SECRETS_TASKS.read_text(encoding="utf-8"))
    if not secret_vars:
        print("the secret set derived to ZERO names — the derivation is broken, "
              "not the repo", file=sys.stderr)
        return 1
    bad = scan(ROOT, secret_vars)
    for path, lineno, key, var in bad:
        print("%s:%d: `environment: %s` carries {{ %s }} — sudo journals this "
              "command line. Use `stdin:`, or read the value from a file."
              % (path, lineno, key, var), file=sys.stderr)
    if bad:
        print("\n%d secret(s) passed through `environment:`. `no_log` does not "
              "mask it." % len(bad), file=sys.stderr)
        return 1
    print("no secret in `environment:` (%d secret variables derived)" % len(secret_vars))
    return 0


if __name__ == "__main__":
    sys.exit(main())
