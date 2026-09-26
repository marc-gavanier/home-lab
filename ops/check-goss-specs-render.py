#!/usr/bin/env python3

import sys
from pathlib import Path

try:
    import yaml
    from jinja2 import ChainableUndefined, Environment
except ImportError:
    print("jinja2/pyyaml not installed; skipping goss spec render", file=sys.stderr)
    sys.exit(0)

REPO = Path(__file__).resolve().parent.parent
COMPOSE = REPO / "docker" / "compose.yaml"
VAR_FILES = [
    "ansible/inventory/group_vars/all.yml",
    "ansible/inventory/host_vars/homelab/main.yml",
    "ansible/inventory/host_vars/homelab/local.example.yml",
    "ansible/inventory/host_vars/homelab/private.example.yml",
    "ansible/inventory/host_vars/offsite/main.yml",
    "ansible/inventory/host_vars/offsite/local.example.yml",
]


class StrictLoader(yaml.SafeLoader):
    pass


def _no_duplicates(loader, node, deep=False):
    mapping = {}
    for key_node, value_node in node.value:
        key = loader.construct_object(key_node, deep=deep)
        if key in mapping:
            raise yaml.constructor.ConstructorError(
                None, None,
                f'mapping key "{key}" already defined',
                key_node.start_mark,
            )
        mapping[key] = loader.construct_object(value_node, deep=deep)
    return mapping


StrictLoader.add_constructor(
    yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, _no_duplicates
)


class Loose(ChainableUndefined):

    def __str__(self):
        return "PLACEHOLDER"

    def __iter__(self):
        return iter([])

    def __bool__(self):
        return False


def context():
    ctx = {}
    for rel in VAR_FILES:
        path = REPO / rel
        if not path.exists():
            continue
        loaded = yaml.safe_load(path.read_text(encoding="utf-8"))
        if isinstance(loaded, dict):
            ctx.update(loaded)
    ctx["lookup"] = lambda _kind, _path: COMPOSE.read_text(encoding="utf-8")
    ctx["playbook_dir"] = str(REPO / "ansible" / "playbooks")
    ctx.setdefault("domain", "example.com")
    return ctx


def main():
    env = Environment(
        undefined=Loose,
        trim_blocks=True,
        lstrip_blocks=False,
        keep_trailing_newline=True,
    )
    env.filters["from_yaml"] = yaml.safe_load

    ctx = context()
    failures = 0
    checked = 0
    for path in sorted((REPO / "ansible").rglob("goss-*.y*ml.j2")):
        rel = path.relative_to(REPO)
        try:
            rendered = env.from_string(path.read_text(encoding="utf-8")).render(**ctx)
        except Exception as exc:  # noqa: BLE001
            print(f"{rel}: does not render: {exc}", file=sys.stderr)
            failures += 1
            continue
        try:
            doc = yaml.load(rendered, Loader=StrictLoader)
        except yaml.YAMLError as exc:
            mark = getattr(exc, "problem_mark", None)
            where = f" (rendered line {mark.line + 1})" if mark else ""
            problem = getattr(exc, "problem", None) or str(exc).splitlines()[0]
            print(f"{rel}: goss would refuse this{where}: {problem}", file=sys.stderr)
            failures += 1
            continue
        if not isinstance(doc, dict) or not doc:
            print(f"{rel}: rendered to no resources at all", file=sys.stderr)
            failures += 1
            continue
        checked += 1

    if failures:
        print(
            f"\n{failures} goss spec(s) would not load on the host.",
            file=sys.stderr,
        )
        return 1
    print(f"{checked} goss spec(s) render and load")
    return 0


if __name__ == "__main__":
    sys.exit(main())
