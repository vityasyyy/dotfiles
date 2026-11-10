#!/usr/bin/env python3
"""Verify relative Markdown links and anchors in the human-facing docs."""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = [
    ROOT / "README.md",
    *(
        path
        for path in sorted((ROOT / "docs").rglob("*.md"))
        if "plans" not in path.relative_to(ROOT / "docs").parts
    ),
]

LINK = re.compile(r"\[[^\]]*\]\((<[^>]+>|[^)]+)\)")
HEADING = re.compile(r"^(#{1,6})\s+(.*?)\s*$")
FENCE = re.compile(r"^\s*(```|~~~)")
INLINE = re.compile(r"`([^`]+)`")
MD_LINK = re.compile(r"\[([^\]]+)\]\([^)]+\)")


def slug(text: str) -> str:
    text = MD_LINK.sub(r"\1", text)
    text = INLINE.sub(r"\1", text)
    text = re.sub(r"<[^>]+>", "", text)
    text = text.strip().lower()
    text = re.sub(r"[^\w\s-]", "", text, flags=re.UNICODE)
    return text.replace(" ", "-")


def headings(path: Path) -> set[str]:
    seen: dict[str, int] = {}
    result: set[str] = set()
    fenced = False
    for line in path.read_text(encoding="utf-8").splitlines():
        if FENCE.match(line):
            fenced = not fenced
            continue
        if fenced:
            continue
        match = HEADING.match(line)
        if not match:
            continue
        base = slug(match.group(2))
        count = seen.get(base, 0)
        seen[base] = count + 1
        result.add(base if count == 0 else f"{base}-{count}")
    return result


def check(doc: Path) -> list[str]:
    errors: list[str] = []
    fenced = False
    lines = doc.read_text(encoding="utf-8").splitlines()
    for number, line in enumerate(lines, 1):
        if FENCE.match(line):
            fenced = not fenced
            continue
        if fenced:
            continue
        for match in LINK.finditer(line):
            target = match.group(1).strip()
            if target.startswith("<") and target.endswith(">"):
                target = target[1:-1]
            if target.startswith(("http://", "https://", "mailto:")):
                continue
            path_part, _, anchor = target.partition("#")
            if not path_part:
                linked = doc
            else:
                linked = (doc.parent / path_part).resolve()
            if not linked.exists():
                errors.append(f"{doc.relative_to(ROOT)}:{number}: missing link target: {target}")
                continue
            if anchor and linked.suffix == ".md":
                if anchor not in headings(linked):
                    errors.append(f"{doc.relative_to(ROOT)}:{number}: missing anchor: {target}")
    return errors


def main() -> int:
    errors = [error for doc in DOCS if doc.exists() for error in check(doc)]
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"documentation links passed ({len(DOCS)} files)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
