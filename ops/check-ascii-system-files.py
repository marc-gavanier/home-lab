#!/usr/bin/env python3
import pathlib
import sys

import yaml

REPO = pathlib.Path(__file__).resolve().parent.parent
ANSIBLE = REPO / "ansible"

ASCII_STRICT_PREFIXES = ("/etc/ufw/",)

WRITTEN_KEYS = ("block", "content", "line", "marker", "replace")
PATH_KEYS = ("path", "dest")


def non_ascii(text):
    return [c for c in str(text) if ord(c) > 127]


def walk_tasks(node):
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
            continue
        rel = path.relative_to(REPO)
        for doc in docs:
            for task in walk_tasks(doc):
                for module_args in task.values():
                    if not isinstance(module_args, dict):
                        continue

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
