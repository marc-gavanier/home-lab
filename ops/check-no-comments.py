#!/usr/bin/env python3
import ast
import io
import os
import re
import subprocess
import sys
import tokenize

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

TAGGED = re.compile(r"^\[(important|warning|critical)\]: \S")

DIRECTIVES = re.compile(
    r"^("
    r"renovate:\s*\S.*"
    r"|floor:\s*\S.*"
    r"|noqa(:\s*[\w-]+(,\s*[\w-]+)*)?"
    r"|shellcheck\s+(disable|enable|source|shell)=\S+"
    r"|yamllint\s+(disable|enable)(-line|-file)?(\s+rule:\S+)*"
    r"|nosemgrep(:\s*\S+)?"
    r"|gitleaks:allow"
    r"|type:\s*ignore(\[[\w,-]+\])?"
    r"|-\*-.*-\*-"
    r"|Ansible managed.*"
    r"|\{\{\s*ansible_managed\s*\}\}"
    r"|v\d+(\.\d+)*\S*"
    r")\s*$"
)

BLOCK_OPENER = re.compile(r"^\s*(?:-\s+)?(?:(?P<key>[\w.-]+):\s*)?[|>][-+0-9]*\s*(?:#.*)?$")
CODE_KEYS = {"cmd", "exec", "shell", "command", "script", "run", "content", None}

SKIP_SUFFIXES = (".md", ".md.j2", ".json", ".png", ".jpg", ".jpeg", ".svg", ".ico", ".gif", ".webp", ".lock")
SEMICOLON_SUFFIXES = (".ini", ".service", ".timer", ".socket", ".mount", ".path", ".target")


def language(path):
    name = path[:-3] if path.endswith(".j2") else path
    if path.endswith(SKIP_SUFFIXES) or path.startswith(".claude/"):
        return None
    if name.endswith(".py"):
        return "python"
    if name.endswith(".css"):
        return "css"
    return "hash"


def allowed(text):
    text = text.strip()
    return bool(TAGGED.match(text) or DIRECTIVES.match(text))


def inline_hash(line):
    quote = None
    prev = " "
    for i, ch in enumerate(line):
        if quote:
            if ch == "\\" and quote == '"':
                prev = ""
                continue
            if ch == quote:
                quote = None
        elif ch in ("'", '"') and (prev.isspace() or prev in "=:([{,|" or i == 0):
            quote = ch
        elif ch == "#" and prev.isspace() and not re.match(r"[}\d]", line[i + 1:i + 2]):
            return i
        prev = ch
    return None


def hash_comments(path, text):
    found = []
    in_jinja = False
    semicolons = path.removesuffix(".j2").endswith(SEMICOLON_SUFFIXES)
    jinja = path.endswith(".j2")
    yaml = path.removesuffix(".j2").endswith((".yml", ".yaml"))
    block_indent = None
    block_code = False
    for n, line in enumerate(text.splitlines(), 1):
        stripped = line.strip()
        indent = len(line) - len(line.lstrip())
        in_block = False
        if yaml and block_indent is not None:
            if stripped and indent < block_indent:
                block_indent = None
            elif stripped or block_indent is not None:
                in_block = True
        if yaml and not in_block:
            opened = BLOCK_OPENER.match(line)
            if opened:
                block_indent = indent + 1
                block_code = opened.group("key") in CODE_KEYS
        if in_jinja:
            found.append((n, stripped))
            if "#}" in line:
                in_jinja = False
            continue
        opener = re.search(r"(?<!\$)\{#", line) if jinja else None
        if opener:
            start = opener.start()
            found.append((n, line[start + 2:].split("#}")[0]))
            if "#}" not in line[start:]:
                in_jinja = True
            continue
        if n == 1 and stripped.startswith("#!"):
            continue
        if stripped.startswith("#include") or stripped.startswith("#!"):
            continue
        if stripped.startswith("#"):
            found.append((n, stripped.lstrip("#")))
            continue
        if semicolons and stripped.startswith(";"):
            found.append((n, stripped.lstrip(";")))
            continue
        if in_block and not block_code:
            continue
        col = inline_hash(line)
        if col is not None:
            found.append((n, line[col + 1:]))
    return found


def python_comments(path, text):
    found = []
    for tok in tokenize.generate_tokens(io.StringIO(text).readline):
        if tok.type == tokenize.COMMENT:
            if tok.start[0] == 1 and tok.string.startswith("#!"):
                continue
            found.append((tok.start[0], tok.string.lstrip("#")))
    for node in ast.walk(ast.parse(text)):
        if isinstance(node, (ast.Module, ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            body = node.body
            if body and isinstance(body[0], ast.Expr) and isinstance(getattr(body[0], "value", None), ast.Constant) \
                    and isinstance(body[0].value.value, str):
                found.append((body[0].lineno, "docstring"))
    return found


def css_comments(path, text):
    found = []
    for m in re.finditer(r"/\*(.*?)\*/", text, re.S):
        found.append((text.count("\n", 0, m.start()) + 1, m.group(1)))
    return found


def comments(path, text):
    lang = language(path)
    if lang == "python":
        return python_comments(path, text)
    if lang == "css":
        return css_comments(path, text)
    if lang == "hash":
        return hash_comments(path, text)
    return []


def offending(path, text):
    return [(n, c) for n, c in comments(path, text) if not allowed(c)]


def tracked():
    out = subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True)
    return [p for p in out.stdout.splitlines() if language(p)]


def selftest():
    cases = [
        ("MUST FLAG - a full-line comment", "x.yml", "a: 1\n# why a is 1\n", 1),
        ("MUST FLAG - an inline comment", "x.yml", "a: 1  # why\n", 1),
        ("MUST FLAG - a comment inside a block scalar", "x.yml", "cmd: |\n  # step one\n  ls\n", 1),
        ("MUST FLAG - a Jinja comment", "x.sh.j2", "{# note #}\necho hi\n", 1),
        ("MUST FLAG - a systemd semicolon comment", "x.service", "; note\n[Unit]\n", 1),
        ("MUST FLAG - a python comment and a docstring", "x.py", '"""doc"""\nx = 1  # why\n', 2),
        ("MUST FLAG - a css comment", "x.css", "/* note */\na { b: c }\n", 1),
        ("MUST FLAG - an unknown tag", "x.yml", "# [note]: text\n", 1),
        ("must pass - the three tags", "x.yml",
         "# [important]: a\n# [warning]: b\n# [critical]: c\n", 0),
        ("must pass - tool directives", "x.yml",
         "# renovate: datasource=docker\na: 1  # noqa: yaml\n# yamllint disable-line rule:x\n# floor: some-assertion\n", 0),
        ("must pass - a shebang and an include", "x.sh", "#!/bin/sh\n#include <tunables/global>\n", 0),
        ("MUST FLAG - prose that merely starts with a directive word", "x.yml",
         "# noqa command-instead-of-module: the module cannot do it\n# yamllint parses the YAML\n", 2),
        ("MUST FLAG - prose after a directive", "x.sh", "# shellcheck disable=SC2086  # deliberate splitting\n", 1),
        ("must pass - hashes that are not comments", "x.sh",
         'n=${#list}\necho "a # b"\nsed "s#a#b#"\necho $#\n', 0),
        ("must pass - markdown is out of scope", "x.md", "# Title\n", 0),
        ("must pass - an issue reference in prose", "x.yml", "d: >\n  fixed in #189 and #202\n", 0),
        ("must pass - a hash inside a folded message", "x.yml", "fail_msg: >-\n  any of ? # : breaks it\nb: 1\n", 0),
        ("MUST FLAG - an inline shell comment in a cmd block", "x.yml", "cmd: |\n  ls /tmp  # list it\n", 1),
        ("must pass - the version beside a pinned digest", "x.yml", "- uses: a/b@0123abcd  # v7.0.1\n", 0),
    ]
    failures = []
    for label, path, text, expected in cases:
        got = len(offending(path, text))
        if got != expected:
            failures.append("%s: flagged %d, expected %d" % (label, got, expected))
    for f in failures:
        print("SELFTEST FAILED - " + f, file=sys.stderr)
    if failures:
        return 1
    print("selftest: %d controls, all as expected" % len(cases))
    return 0


def main():
    if "--selftest" in sys.argv:
        return selftest()
    files = tracked()
    if not files:
        print("found ZERO files to check - the listing is broken, not the repo", file=sys.stderr)
        return 1
    bad = 0
    for path in files:
        full = os.path.join(ROOT, path)
        if not os.path.isfile(full):
            continue
        try:
            text = open(full, encoding="utf-8").read()
        except UnicodeDecodeError:
            continue
        for n, c in offending(path, text):
            bad += 1
            print("%s:%d: comment not allowed: %s" % (path, n, c.strip()[:80]))
    if bad:
        print("\n%d comment(s). Delete them, or tag what must stay: "
              "`# [important]: ...`, `# [warning]: ...`, `# [critical]: ...`." % bad, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
