#!/usr/bin/env python3
"""Every shell program this repo embeds in a task must parse as shell.

Written 2026-09-11, after a comment INSIDE a single-quoted awk program contained
the apostrophe in "ufw's". The quote closed there, bash tried to interpret the
rest of the awk source, and the deploy died at the task — on the host, in the
middle of a run, with the ruleset half applied.

Nothing in the suite could have caught it. yamllint parsed the YAML, because the
YAML was valid. ansible-lint accepted the task, because the task was valid. The
program inside the string was never handed to a shell until the deploy ran it.

So: extract the cmd of every `shell:` task, and `bash -n` it. Tasks carrying
Jinja are skipped — their rendered form is not knowable here — but a task whose
Jinja is only in a comment or a filename is still worth checking, so the skip is
reported rather than silent.
"""
import re
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GLOBS = ("ansible/roles/*/tasks/*.yml", "ansible/roles/*/handlers/*.yml",
         "ansible/playbooks/*.yml")
GOSS_GLOBS = ("ansible/roles/*/templates/goss-*.yaml.j2",)

try:
    import yaml
except ImportError:
    print("PyYAML missing — cannot check embedded shell", file=sys.stderr)
    sys.exit(1)


def shell_cmds(root):
    """(file, task name, program) for every shell task, Jinja ones included."""
    out = []
    for glob in GLOBS:
        for path in sorted(root.glob(glob)):
            try:
                doc = yaml.safe_load(path.read_text(encoding="utf-8"))
            except yaml.YAMLError:
                continue          # yamllint owns that failure, not this check
            for task in doc or []:
                if not isinstance(task, dict):
                    continue
                for key in ("ansible.builtin.shell", "shell"):
                    spec = task.get(key)
                    if spec is None:
                        continue
                    cmd = spec.get("cmd") if isinstance(spec, dict) else spec
                    if isinstance(cmd, str):
                        out.append((path.relative_to(root),
                                    task.get("name", "<unnamed>"), cmd))
    return out


def goss_execs(root):
    """(file, assertion name, program) for every goss `exec:` body.

    Checked with `sh -n`, NOT bash, and the distinction is the whole reason this
    half exists: goss runs its commands with sh. On 2026-09-11 an assertion that
    passed under bash failed under dash, because dash's `read` builtin returns
    non-zero on a /proc/sys file. A static check cannot catch that one — it is a
    runtime difference, not a syntax error — but it catches every bashism that
    IS a syntax error, and it is the cheap half of the same lesson: exercise a
    goss body under sh before believing it.
    """
    out = []
    pat = re.compile(r"^(\s*)([a-z0-9-]+):\n\1  exec: \|\n((?:\1    .*\n|\n)+)", re.M)
    for glob in GOSS_GLOBS:
        for path in sorted(root.glob(glob)):
            text = path.read_text(encoding="utf-8")
            for m in pat.finditer(text):
                indent, name, body = m.group(1), m.group(2), m.group(3)
                strip = len(indent) + 4
                body = "\n".join(l[strip:] if l.startswith(" " * strip) else l
                                  for l in body.split("\n"))
                out.append((path.relative_to(root), name, body))
    return out


def parses(program, shell="bash"):
    with tempfile.NamedTemporaryFile("w", suffix=".sh", delete=False) as fh:
        fh.write(program)
        path = fh.name
    r = subprocess.run([shell, "-n", path], capture_output=True, text=True)
    Path(path).unlink(missing_ok=True)
    return r.returncode == 0, (r.stderr or "").strip()


def selftest():
    failures = []
    cases = [
        ("MUST FLAG - the real defect: an apostrophe inside a quoted awk program",
         "awk '\n  # ufw's file\n  { print }\n' /etc/hosts\n", False),
        ("must pass - the same program without the apostrophe",
         "awk '\n  # the ufw file\n  { print }\n' /etc/hosts\n", True),
        ("must pass - an ordinary pipeline",
         "set -o pipefail\nls /tmp | wc -l\n", True),
        ("MUST FLAG - an unclosed quote",
         "echo 'unterminated\n", False),
    ]
    for label, program, should_parse in cases:
        ok, _ = parses(program)
        if ok != should_parse:
            failures.append("%s: parsed=%s expected=%s" % (label, ok, should_parse))

    # What `sh -n` can and cannot see, stated rather than assumed. It catches
    # bashisms that are SYNTAX errors for dash. It does NOT catch `[[ ]]`, which
    # dash parses happily as a command name and only fails on at runtime, and it
    # does not catch a builtin that behaves differently — dash's `read` returning
    # non-zero on a /proc/sys file is the one that cost a deploy on 2026-09-11.
    # The gate is the cheap half; exercising the body under sh is the other half
    # and no static check replaces it.
    sh_cases = [
        ("MUST FLAG under sh - a bash array",
         "a=(one two)\necho ${a}\n", False),
        ("MUST FLAG under sh - process substitution",
         "diff <(echo a) <(echo b)\n", False),
        ("must pass under sh - the portable equivalents",
         "[ -f /etc/hosts ] && echo yes\nv=$(cat /etc/hostname)\n", True),
    ]
    for label, program, should_parse in sh_cases:
        ok, _ = parses(program, shell="sh")
        if ok != should_parse:
            failures.append("%s: parsed=%s expected=%s" % (label, ok, should_parse))

    for f in failures:
        print("SELFTEST FAILED: %s" % f, file=sys.stderr)
    if failures:
        return 1
    print("selftest: %d controls, all as expected" % (len(cases) + len(sh_cases)))
    return 0


def main():
    if "--selftest" in sys.argv:
        return selftest()

    cmds = shell_cmds(ROOT)
    if not cmds:
        print("found ZERO shell tasks — the extraction is broken, not the repo",
              file=sys.stderr)
        return 1

    bad, skipped = [], 0
    for path, name, cmd in cmds:
        if "{{" in cmd or "{%" in cmd:
            skipped += 1
            continue
        ok, err = parses(cmd)
        if not ok:
            bad.append((path, name, err))

    for path, name, err in bad:
        print("%s: `%s` does not parse as shell\n    %s" % (path, name, err),
              file=sys.stderr)
    if bad:
        print("\n%d embedded shell program(s) would fail at deploy time, on the "
              "host, mid-run." % len(bad), file=sys.stderr)
        return 1

    execs = goss_execs(ROOT)
    if not execs:
        print("found ZERO goss exec bodies — the extraction is broken, not the repo",
              file=sys.stderr)
        return 1
    gbad, gskipped = [], 0
    for path, name, body in execs:
        if "{{" in body or "{%" in body:
            gskipped += 1
            continue
        ok, err = parses(body, shell="sh")
        if not ok:
            gbad.append((path, name, err))
    for path, name, err in gbad:
        print("%s: goss assertion `%s` does not parse under SH, which is what "
              "goss runs it with\n    %s" % (path, name, err), file=sys.stderr)
    if gbad:
        return 1

    print("%d embedded shell programs parse under bash (%d skipped for Jinja), "
          "%d goss exec bodies parse under sh (%d skipped)"
          % (len(cmds) - skipped, skipped, len(execs) - gskipped, gskipped))
    return 0


if __name__ == "__main__":
    sys.exit(main())
