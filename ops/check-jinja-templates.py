#!/usr/bin/env python3
"""Parse every Ansible Jinja template, so a syntax error fails here and not at deploy.

Why this exists. On 2026-08-29 a comment inside `goss-posture.yaml.j2` contained a
doubled-brace expression, written to WARN against doubled braces. Jinja does not
know what a YAML comment is: it parsed the comment as an expression and the deploy
died at the `template` task with `Syntax error in template: unexpected '.'`.

Both linters passed over it. yamllint reads the file as YAML, where the broken line
is a comment; ansible-lint checks task structure, not template bodies. Nothing in
the chain rendered the template, so nothing could see it — the error was reachable
only by running a deploy against the live host.

This parses (does not render) every template: no variables are needed, and a parse
is enough for the whole class. `TemplateSyntaxError` carries the real line number,
which the Ansible failure does not always point at precisely.
"""

import sys
from pathlib import Path

try:
    from jinja2 import Environment, TemplateSyntaxError
except ImportError:
    print("jinja2 not installed; skipping template parse", file=sys.stderr)
    sys.exit(0)

env = Environment()
failed = []

for path in sorted(Path("ansible").rglob("*.j2")):
    try:
        env.parse(path.read_text(), filename=str(path))
    except TemplateSyntaxError as exc:
        failed.append((path, exc.lineno, exc.message))
    except OSError as exc:
        failed.append((path, 0, f"unreadable: {exc}"))

for path, lineno, message in failed:
    print(f"{path}:{lineno}: {message}", file=sys.stderr)

if failed:
    print(f"\n{len(failed)} template(s) would fail at deploy time.", file=sys.stderr)
    sys.exit(1)

sys.exit(0)
