#!/usr/bin/env python3
import re
import sys
from pathlib import Path

WINDOW_BEFORE = 30
WINDOW_AFTER = 15

ITERATION = re.compile(
    r"""(?x)
    (?:^|\s)for\s+\w+\s+in\s+(?:\$\(|`|\$\{?\w)   # for x in $(...) / `...` / $VAR
  | (?:^|\s)while\s+.*\bread\b                    # while read ...
    """
)

GUARDS = re.compile(
    r"""(?x)
    \[\s*-[nz]\s                 # [ -n "$v" ] / [ -z "$v" ]
  | \btest\s+-[nz]\s
  | -ge\s+(?:\d|\{\{)          # a cardinality floor, literal or rendered in
  | -gt\s+(?:\d|\{\{)
  | \bcount\s*\(\s*\*\s*\)       # select count(*) ... >= N
    """
)

FLOOR_NOTE = re.compile(r"#\s*floor:\s*(\S.*?)\s*$", re.MULTILINE)

SPEC_GLOBS = ("goss-*.yaml.j2",)
SHELL_SUFFIXES = (".sh", ".sh.j2")
ANSIBLE_GLOBS = ("roles/*/tasks/*.yml", "roles/*/handlers/*.yml", "playbooks/*.yml")


def strip_comments(text):
    out = []
    for line in text.splitlines():
        quote = None
        cut = None
        for i, ch in enumerate(line):
            if quote:
                if ch == quote:
                    quote = None
            elif ch in "'\"":
                quote = ch
            elif ch == "#" and (i == 0 or line[i - 1] in " \t"):
                cut = i
                break
        out.append(line if cut is None else line[:cut])
    return "\n".join(out)


def spec_blocks(text):
    lines = text.splitlines()
    starts = [i for i, l in enumerate(lines) if re.match(r"\s+exec:\s*(\||>|\S)", l)]
    for i in starts:
        indent = len(lines[i]) - len(lines[i].lstrip())
        name = "?"
        for j in range(i - 1, max(-1, i - 40), -1):
            m = re.match(r"\s{2}([A-Za-z0-9_.@/-]+):\s*$", lines[j])
            if m:
                name = m.group(1)
                break
        end = i + 1
        while end < len(lines):
            l = lines[end]
            if l.strip() and (len(l) - len(l.lstrip())) <= indent and not l.lstrip().startswith("#"):
                break
            end += 1
        yield name, i + 1, "\n".join(lines[i:end])


def check_spec(path, text):
    findings = []
    names = set(re.findall(r"^\s{2}([A-Za-z0-9_.@/-]+):\s*$", text, re.MULTILINE))
    for name, line, block in spec_blocks(text):
        body = strip_comments(block)
        if not ITERATION.search(body):
            continue
        if GUARDS.search(body):
            continue
        note = FLOOR_NOTE.search(block)
        if note:
            named = note.group(1).strip()
            if named in names:
                continue
            findings.append(
                (line, name, f"names floor '{named}', which is not an assertion in this file")
            )
            continue
        findings.append((line, name, "iterates a derived set with no floor and no `# floor:` note"))
    return findings


ANSIBLE_LOOP = re.compile(r"^([^\S\n]*)(?:loop|with_items):[^\S\n]*(\S.*?)[^\S\n]*$", re.MULTILINE)
ANSIBLE_ROOT_VAR = re.compile(r"\{\{\s*([A-Za-z_][A-Za-z0-9_]*)")
ANSIBLE_BARE_VAR = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)$")


def ansible_floor(window, var):
    if re.search(r"#\s*floor:\s*\S", window):
        return True
    cardinality = re.compile(
        r"\b" + re.escape(var) + r"\b[^\n]*\|\s*length\s*(?:>|>=|!=)"
    )
    return bool(cardinality.search(window))


def check_ansible(path, text):
    findings = []
    lines = text.splitlines()
    for m in ANSIBLE_LOOP.finditer(text):
        source = m.group(2)
        if source.startswith("[") or source in ("", ">-", "|"):
            continue
        quoted = source.strip().strip('"').strip("'")
        root = ANSIBLE_ROOT_VAR.search(source)
        if root:
            var = root.group(1)
        elif ANSIBLE_BARE_VAR.match(quoted):
            var = quoted
        else:
            continue
        line = text[: m.start()].count("\n") + 1
        hi = min(len(lines), line + WINDOW_AFTER)
        window = "\n".join(lines[:hi])
        if ansible_floor(window, var):
            continue
        findings.append(
            (line, var, "loops a variable source with no cardinality floor in the surrounding task")
        )
    return findings


def check_shell(path, text):
    findings = []
    lines = text.splitlines()
    bare = strip_comments(text).splitlines()
    for i, l in enumerate(bare):
        if not ITERATION.search(l):
            continue
        lo = max(0, i - WINDOW_BEFORE)
        hi = min(len(lines), i + WINDOW_AFTER + 1)
        window = "\n".join(bare[lo:hi])
        if GUARDS.search(window) or FLOOR_NOTE.search("\n".join(lines[lo:hi])):
            continue
        findings.append((i + 1, l.strip()[:60], "iterates a derived set with no floor in view"))
    return findings



CONTROLS = [
    (
        "must FLAG: the published-port derivation as it stood before 2026-09-05",
        "spec",
        """  no-undeclared-published-ports:
    exec: |
      declared="80 443"
      live=$(docker inspect $(docker ps -q) | jq -r '.[] | .HostPort')
      for p in $live; do
        case " $declared " in *" $p "*) ;; *) exit 1 ;; esac
      done
    exit-status: 0
""",
        True,
    ),
    (
        "must PASS: the same derivation with the floor it now carries",
        "spec",
        """  no-undeclared-published-ports:
    exec: |
      declared="80 443"
      live=$(docker inspect $(docker ps -q) | jq -r '.[] | .HostPort')
      [ -n "$live" ] || { echo "no published host port at all"; exit 1; }
      for p in $live; do
        case " $declared " in *" $p "*) ;; *) exit 1 ;; esac
      done
    exit-status: 0
""",
        False,
    ),
    (
        "must PASS: a loop whose floor is a sibling assertion, correctly named",
        "spec",
        """  credential-stores-derivation-nonempty:
    exec: 'true'
    exit-status: 0

  credential-stores-all-closed:
    exec: |
      # floor: credential-stores-derivation-nonempty
      for src in $(docker inspect $(docker ps -aq) | jq -r '.[].Source'); do
        stat -c %a "$src"
      done
    exit-status: 0
""",
        False,
    ),
    (
        "must FLAG: a floor note pointing at an assertion that does not exist",
        "spec",
        """  credential-stores-all-closed:
    exec: |
      # floor: a-check-that-was-deleted
      for src in $(docker inspect $(docker ps -aq) | jq -r '.[].Source'); do
        stat -c %a "$src"
      done
    exit-status: 0
""",
        True,
    ),
    (
        "must FLAG: the crash-heal loop as it stood during the 2026-08-26 outage",
        "shell",
        """#!/usr/bin/env bash
exited=$(docker ps -a --filter status=exited --format '{{.Names}}')
while read -r name; do
    log "restarting $name"
done <<EOF
$exited
EOF
""",
        True,
    ),
    (
        "must FLAG: an Ansible loop over a required list with no floor",
        "ansible",
        '''- name: firewall | Allow SSH from the permitted sources
  community.general.ufw:
    rule: allow
    from_ip: "{{ item }}"
  loop: "{{ ssh_allowed_sources }}"
''',
        True,
    ),
    (
        "must FLAG: `| default([])` is not a floor, it is the defect wearing a seatbelt",
        "ansible",
        '''- name: firewall | Allow service ports
  community.general.ufw:
    rule: allow
    port: "{{ item.port }}"
  loop: "{{ ufw_service_rules | default([]) }}"
''',
        True,
    ),
    (
        "must PASS: an assert above the loop floors it",
        "ansible",
        '''- name: firewall | Refuse to proceed with no SSH source to allow
  ansible.builtin.assert:
    that:
      - ssh_allowed_sources | default([]) | length > 0
    fail_msg: the host would become unreachable

- name: firewall | Allow SSH from the permitted sources
  community.general.ufw:
    rule: allow
    from_ip: "{{ item }}"
  loop: "{{ ssh_allowed_sources }}"
''',
        False,
    ),
    (
        "must PASS: a literal inline list is bounded by construction",
        "ansible",
        '''- name: nextcloud | Enable the apps this deployment uses
  ansible.builtin.command: occ app:enable {{ item }}
  loop: [calendar, contacts, tasks]
''',
        False,
    ),
    (
        "must PASS: a block list on the following lines is a literal too",
        "ansible",
        '''- name: system | Configure kernel parameters
  ansible.posix.sysctl:
    name: "{{ item.key }}"
  loop:
    - { key: "vm.swappiness", value: "10" }
''',
        False,
    ),
    (
        "must PASS: prose that merely contains the words (the first false positive)",
        "shell",
        """#!/usr/bin/env bash
# 25 services continuously while the offsite one is read once a night. Reading
# them for a while is fine.
echo ok
""",
        False,
    ),
]


def selftest():
    failures = 0
    for label, kind, body, want_flag in CONTROLS:
        fn = {"spec": check_spec, "ansible": check_ansible}.get(kind, check_shell)
        got = bool(fn(Path("<control>"), body))
        ok = got == want_flag
        print(f"  {'ok  ' if ok else 'FAIL'}  {label}")
        if not ok:
            failures += 1
            print(f"        expected {'a finding' if want_flag else 'no finding'}, got the opposite")
    if failures:
        print(f"\n{failures} control(s) failed: this gate does not discriminate.", file=sys.stderr)
    return 1 if failures else 0


def main(argv):
    if "--selftest" in argv:
        return selftest()
    root = Path(".")
    targets = []
    for g in SPEC_GLOBS:
        targets += [(p, check_spec) for p in root.rglob(g)]
    for suf in SHELL_SUFFIXES:
        targets += [(p, check_shell) for p in root.rglob(f"*{suf}")]
    for g in ANSIBLE_GLOBS:
        targets += [(p, check_ansible) for p in root.rglob(g)]
    for p in root.rglob("roles/*/files/*"):
        if p.is_file() and p.suffix == "" and p.read_bytes()[:2] == b"#!":
            targets.append((p, check_shell))

    total = 0
    seen = set()
    for path, fn in sorted(set(targets)):
        if path in seen or ".git" in path.parts:
            continue
        seen.add(path)
        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue
        for line, what, why in fn(path, text):
            print(f"{path}:{line}: {what}: {why}")
            total += 1
    if total:
        print(
            f"\n{total} iteration(s) over a derived set with nothing bounding it from below.\n"
            "Add a guard, or a `# floor: <name>` note saying what already bounds it.",
            file=sys.stderr,
        )
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
