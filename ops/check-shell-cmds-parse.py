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


def parses(program):
    with tempfile.NamedTemporaryFile("w", suffix=".sh", delete=False) as fh:
        fh.write(program)
        path = fh.name
    r = subprocess.run(["bash", "-n", path], capture_output=True, text=True)
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

    for f in failures:
        print("SELFTEST FAILED: %s" % f, file=sys.stderr)
    if failures:
        return 1
    print("selftest: %d controls, all as expected" % len(cases))
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

    print("%d embedded shell programs parse (%d skipped for Jinja)"
          % (len(cmds) - skipped, skipped))
    return 0


if __name__ == "__main__":
    sys.exit(main())
