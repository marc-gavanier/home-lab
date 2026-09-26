#!/usr/bin/env python3

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
