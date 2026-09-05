#!/usr/bin/env python3
"""Refuse an iteration over a derived set that has no floor under it.

The defect this exists for, in one sentence: a loop over a set that came back
EMPTY falls straight through to the success path, so "I examined nothing" and
"I found nothing wrong" become the same observable. The audit of 2026-09-05
swept 976 sites for it and found ~30 live instances across goss specs, shell
reports and Ansible tasks; the remedy had already been written into this repo by
hand six separate times without ever being generalised.

WHAT IS FLAGGED

An iteration whose source is derived at run time --

    for x in $(cmd ...)      for x in `cmd ...`      for x in $VAR
    while read ... done < <(cmd)   |   ... | while read ...   |   done <<EOF

-- unless the same unit also carries one of:

  * a non-emptiness guard: [ -n "$V" ], [ -z "$V" ], test -n/-z
  * a cardinality guard:   -ge N, -gt N, "$n" -eq 0 leading to a failure
  * an explicit annotation naming what floors it (see below)

THE ANNOTATION, AND WHY IT IS NOT AN OPT-OUT

Some floors legitimately live elsewhere. `credential-stores-all-closed` loops
over a derived mount set with no guard of its own, and it is correct: the
cardinality is asserted 39 lines away by `credential-stores-derivation-nonempty`.
So a loop may declare its floor:

    # floor: credential-stores-derivation-nonempty

In a goss spec the named assertion MUST EXIST in the same file, and this script
checks that it does. A floor that is deleted therefore breaks the commit that
deletes it, which is the property a comment alone would not have. Outside a goss
spec the annotation takes free text and must give a reason.

THE UNIT

For a goss spec, the unit is one `exec:` block. For a shell script, it is the
loop plus WINDOW_BEFORE lines above it (where the source is assigned and
usually guarded) and WINDOW_AFTER below (where a count is usually compared).
The window is deliberate: a whole-file unit would let one guard anywhere excuse
every loop in the file.

Run over the repository, not only over staged files, so the count in the commit
message means something.
"""
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
# `for x in a b c` over literal words is bounded by construction and is not the
# defect; only a derived source counts. A literal list never reaches ITERATION
# because it has no `$` and no backtick.

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


def strip_comments(text):
    """Drop comment bodies before matching.

    Prose is full of the words this script looks for: `homelab-disk.sh.j2`
    carries "... is read once a night", which matched the `while ... read`
    pattern and produced this script's first false positive. A `#` inside a
    single- or double-quoted string is not a comment, so quotes are tracked
    rather than the line being cut at the first `#`.
    """
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
    """Yield (name, start_line, block_text) for each `exec:` block in a goss spec."""
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



# --- The controls, and why they are in the file rather than beside it --------
# This register's rule is that a gate counts only once it has been made to FAIL
# on purpose; #278 is the reference, and it was disbelieved until it failed in
# both modes. A lint that has only ever been run over a clean repository has
# proven nothing at all — it would pass just as quietly with its regex broken,
# which is this script's own defect class applied to itself.
#
# So the controls ship with it and run in pre-commit. Each names the real
# defect it is drawn from.
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
        fn = check_spec if kind == "spec" else check_shell
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
