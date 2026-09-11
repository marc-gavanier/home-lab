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
COMPOSE = ROOT / "docker" / "compose.yaml"
SECRET_STORE = "/mnt/data/secrets"

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


def mounted_secret_dirs(compose_text):
    """Directories whose files a container reads directly, derived from compose.

    A Compose `secrets:` entry is a BIND MOUNT of the host inode into
    /run/secrets/<name>, so the container's own uid — postgres, mariadb, and the
    rest, none of them root — reads that very file. Those need the world read
    bit and their containment is the 0700 parent, not the mode.

    Derived from the `secrets:` block rather than from the literal string
    "docker/", so that moving the store moves the exemption with it.
    """
    dirs = set()
    block = re.search(r"(?ms)^secrets:\n(.*?)(?=^\S|\Z)", compose_text)
    if block:
        for m in re.finditer(r"^\s+file:\s*(\S+)", block.group(1), re.M):
            dirs.add(m.group(1).rsplit("/", 1)[0])
    return dirs


def world_readable_secret_writes(root, mounted_dirs):
    """Every task writing under the secret store, world-readable, unmounted.

    Derived from the DEST, not from a list of files, because the store has six
    writers across two roles and a sweep of one of them missed a file on
    2026-09-06 — the same scope trap this repo has now paid for six times.

    The narrowing is the part that matters, and it is why the first version of
    this check was deleted rather than fixed: flagging EVERY world-readable
    write under the store also flags the Compose secrets, which must carry that
    bit. So the exemption is derived from compose.yaml, and what is left is the
    files no container mounts — read by root, and world-readable for no reason.
    That is exactly the pair that sat at 0444 from 2026-09-06 to 2026-09-11.
    """
    bad = []
    for glob in TASK_GLOBS:
        for path in sorted(root.glob(glob)):
            text = path.read_text(encoding="utf-8")
            offset = 0
            for block in re.split(r"(?m)^- name:", text):
                nlines = block.count("\n")
                m_dest = re.search(r'dest:\s*"?(%s\S*)"?' % re.escape(SECRET_STORE), block)
                if m_dest:
                    dest = m_dest.group(1).rstrip('"')
                    dest_dir = dest.rsplit("/", 1)[0]
                    m = re.search(r'mode:\s*"?(\d{3,4})"?', block)
                    if m and dest_dir not in mounted_dirs:
                        mode = m.group(1).zfill(4)
                        if int(mode[3]) & 4:
                            line = offset + block[:block.index("mode:")].count("\n") + 1
                            bad.append((path.relative_to(root), line, dest, mode))
                offset += nlines
    return bad


def unmounted_bit_missing(root, mounted_dirs):
    """The OPPOSITE direction: a Compose secret that lost the bit it needs.

    Added 2026-09-11 because the first version of this gate guarded one
    direction only, and the direction it did NOT guard is the one that has
    actually caused an outage: 0400 on a `secrets:` file put nextcloud-db,
    miniflux-db and immich-db into an exit(1) restart loop on 2026-09-06,
    because Compose bind-mounts the host inode and the container's own uid —
    not root — opens it.

    A world-readable mode on these files is therefore not a defect but a
    requirement, and its containment is the 0700 parent. Anything that takes
    the bit away breaks every database that reads through it.
    """
    bad = []
    for glob in TASK_GLOBS:
        for path in sorted(root.glob(glob)):
            text = path.read_text(encoding="utf-8")
            offset = 0
            for block in re.split(r"(?m)^- name:", text):
                nlines = block.count("\n")
                m_dest = re.search(r'dest:\s*"?(%s\S*)"?' % re.escape(SECRET_STORE), block)
                if m_dest:
                    dest = m_dest.group(1).rstrip('"')
                    m = re.search(r'mode:\s*"?(\d{3,4})"?', block)
                    if m and dest.rsplit("/", 1)[0] in mounted_dirs:
                        mode = m.group(1).zfill(4)
                        # Readable by the container's uid means one of two
                        # things, and 0440 is the TIGHTER of them: the world
                        # bit, or the group bit with the group pinned to the
                        # container's gid. `group: root` with 0440 is not
                        # readable by anything the container runs as.
                        g = re.search(r'group:\s*"?([^"\n]+)"?', block)
                        gid = g.group(1).strip().strip('"') if g else ""
                        by_group = bool(int(mode[2]) & 4) and gid not in ("", "root", "0")
                        if not (int(mode[3]) & 4 or by_group):
                            line = offset + block[:block.index("mode:")].count("\n") + 1
                            bad.append((path.relative_to(root), line, dest, mode))
                offset += nlines
    return bad


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

    # --- the mode half, with its own derivation control ---
    compose_src = """
secrets:
  cf_dns_api_token:
    file: /mnt/data/secrets/docker/cf_dns_api_token
  pihole_password:
    file: /mnt/data/secrets/docker/pihole_password

networks:
  proxy:
"""
    mounted = mounted_secret_dirs(compose_src)
    if mounted != {"/mnt/data/secrets/docker"}:
        failures.append("compose derivation yielded %r, expected the docker dir" % mounted)

    mode_cases = [
        ("MUST FLAG - the regression of 2026-09-06, world-readable and unmounted",
         '  ansible.builtin.copy:\n    dest: "/mnt/data/secrets/{{ item.name }}"\n    mode: "0444"\n', True),
        ("MUST FLAG - the same file spelled without the loop",
         '  ansible.builtin.copy:\n    dest: /mnt/data/secrets/restic_password\n    mode: "0444"\n', True),
        ("must pass - owner only, which is the fix",
         '  ansible.builtin.copy:\n    dest: "/mnt/data/secrets/{{ item.name }}"\n    mode: "0400"\n', False),
        ("must pass - a Compose secret, which NEEDS the world read bit",
         '  ansible.builtin.copy:\n    dest: /mnt/data/secrets/docker/pihole_password\n    mode: "0444"\n', False),
        ("must pass - group read, no world bit",
         '  ansible.builtin.copy:\n    dest: /mnt/data/secrets/homelab.env\n    mode: "0640"\n', False),
        ("must pass - world-readable OUTSIDE the secret store",
         '  ansible.builtin.copy:\n    dest: /etc/motd\n    mode: "0444"\n', False),
    ]
    with tempfile.TemporaryDirectory() as d:
        root = Path(d)
        (root / "ansible/roles/x/tasks").mkdir(parents=True)
        for label, body, should_flag in mode_cases:
            (root / "ansible/roles/x/tasks/main.yml").write_text("- name: t\n" + body, encoding="utf-8")
            flagged = bool(world_readable_secret_writes(root, mounted))
            if flagged != should_flag:
                failures.append("%s: flagged=%s expected=%s" % (label, flagged, should_flag))

    # The opposite direction, which had no control until 2026-09-11.
    bit_cases = [
        ("MUST FLAG - the outage of 2026-09-06, a Compose secret at 0400",
         '  ansible.builtin.copy:\n    dest: /mnt/data/secrets/docker/pihole_password\n    mode: "0400"\n', True),
        ("MUST FLAG - group read but the group is root, which no container is",
         '  ansible.builtin.copy:\n    dest: /mnt/data/secrets/docker/pihole_password\n    owner: root\n    group: root\n    mode: "0440"\n', True),
        ("must pass - 0440 with the group pinned to the container gid, TIGHTER than 0444",
         '  ansible.builtin.template:\n    dest: /mnt/data/secrets/docker/nextcloud_redis.conf\n    owner: root\n    group: "999"\n    mode: "0440"\n', False),
        ("must pass - the Compose secret as it must be",
         '  ansible.builtin.copy:\n    dest: /mnt/data/secrets/docker/pihole_password\n    mode: "0444"\n', False),
        ("must pass - 0400 on a file NOTHING mounts, which is the fix",
         '  ansible.builtin.copy:\n    dest: "/mnt/data/secrets/{{ item.name }}"\n    mode: "0400"\n', False),
    ]
    with tempfile.TemporaryDirectory() as d:
        root = Path(d)
        (root / "ansible/roles/x/tasks").mkdir(parents=True)
        for label, body, should_flag in bit_cases:
            (root / "ansible/roles/x/tasks/main.yml").write_text("- name: t\n" + body, encoding="utf-8")
            flagged = bool(unmounted_bit_missing(root, mounted))
            if flagged != should_flag:
                failures.append("%s: flagged=%s expected=%s" % (label, flagged, should_flag))

    for f in failures:
        print("SELFTEST FAILED: %s" % f, file=sys.stderr)
    if failures:
        return 1
    print("selftest: %d controls, all as expected"
          % (len(cases) + len(mode_cases) + len(bit_cases) + 1))
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

    mounted = mounted_secret_dirs(COMPOSE.read_text(encoding="utf-8"))
    if not mounted:
        print("the mounted-secret set derived to ZERO directories — the "
              "derivation is broken, not the repo. Refusing to run the mode "
              "half, which would flag every Compose secret.", file=sys.stderr)
        return 1
    modes = world_readable_secret_writes(ROOT, mounted)
    for path, lineno, dest, mode in modes:
        print("%s:%d: writes %s with mode %s — the world read bit, on a file no "
              "container mounts. The parent does not close it: the secret store "
              "is 0711, so every local account traverses it. Compose secrets "
              "need this bit; this one does not." % (path, lineno, dest, mode),
              file=sys.stderr)

    stripped = unmounted_bit_missing(ROOT, mounted)
    for path, lineno, dest, mode in stripped:
        print("%s:%d: writes %s with mode %s — a Compose `secrets:` file WITHOUT "
              "the world read bit. Compose bind-mounts this inode and the "
              "container's own uid opens it; 0400 here took three databases "
              "down on 2026-09-06." % (path, lineno, dest, mode), file=sys.stderr)

    if bad or modes or stripped:
        return 1
    print("no secret in `environment:` (%d secret variables derived), "
          "no world-readable write outside the %d mounted secret director(ies)"
          % (len(secret_vars), len(mounted)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
