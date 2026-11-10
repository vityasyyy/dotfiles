#!/usr/bin/env python3
"""Validate the skill trigger matrix: coverage, links, and routing contradictions."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MATRIX = ROOT / "agents/.agents/skills/writing-skills/trigger-matrix.md"
SKILL_DIRS = [
    ROOT / "agents/.agents/skills",
    ROOT / "opencode/.config/opencode/skills",
]
LOCAL = {path.parent.name for directory in SKILL_DIRS for path in directory.glob("*/SKILL.md")}
LINK = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
ROW_ID = re.compile(r"^T\d{2}$")
SEPARATOR = re.compile(r"^:?-{3,}:?$")


def table_rows(matrix: Path):
    in_table = False
    for number, line in enumerate(matrix.read_text(encoding="utf-8").splitlines(), 1):
        stripped = line.strip()
        if not in_table:
            if stripped.startswith("| ID | Prompt |"):
                in_table = True
            continue
        if not stripped:
            break
        if not stripped.startswith("|") or not stripped.endswith("|"):
            yield number, None
            break
        cells = [cell.strip() for cell in stripped[1:-1].split("|")]
        if all(SEPARATOR.match(cell) for cell in cells):
            continue
        yield number, cells


def check_cell(base: Path, row_id: str, column: str, cell: str, errors: list[str]) -> list[str]:
    pairs = LINK.findall(cell)
    names = [label.strip("`").strip() for label, _ in pairs]
    remainder = re.sub(r"[\s,`]+", "", LINK.sub("", cell))
    if remainder:
        errors.append(f"{row_id}: {column} has unlinked text: {remainder}")
    if cell.strip() and not pairs:
        errors.append(f"{row_id}: {column} must contain a link")
    for label, target in pairs:
        name = label.strip("`").strip()
        if target.startswith(("http://", "https://", "mailto:", "#")):
            errors.append(f"{row_id}: {column} skill link must be local: {target}")
            continue
        path = (base / target).resolve()
        if not path.exists():
            errors.append(f"{row_id}: missing link: {target}")
        elif path.name != "SKILL.md" or path.parent.name != name:
            errors.append(f"{row_id}: link label {name!r} does not match {target!r}")
    return names


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--matrix", type=Path, default=MATRIX)
    parser.add_argument("--link-root", type=Path, default=None)
    args = parser.parse_args()
    matrix = args.matrix.resolve()
    base = (args.link_root or matrix.parent).resolve()

    errors: list[str] = []
    seen_ids: set[str] = set()
    seen_prompts: set[str] = set()
    primary_seen: set[str] = set()
    rows = 0

    for number, cells in table_rows(matrix):
        if cells is None:
            errors.append(f"line {number}: table row must start with | and end with |")
            continue
        if len(cells) != 5:
            errors.append(f"line {number}: row has {len(cells)} columns")
            continue
        row_id, prompt, primary, supporting, forbidden = cells
        rows += 1
        if not ROW_ID.match(row_id):
            errors.append(f"line {number}: invalid matrix id: {row_id!r}")
        if row_id in seen_ids:
            errors.append(f"{row_id}: duplicate matrix id")
        seen_ids.add(row_id)
        if not prompt:
            errors.append(f"{row_id}: empty prompt")
        if prompt in seen_prompts:
            errors.append(f"{row_id}: duplicate prompt")
        seen_prompts.add(prompt)

        expected = check_cell(base, row_id, "primary", primary, errors)
        support = check_cell(base, row_id, "supporting", supporting, errors)
        blocked = check_cell(base, row_id, "forbidden", forbidden, errors)
        if len(expected) != 1:
            errors.append(f"{row_id}: primary must name exactly one skill")
        for name in expected + support + blocked:
            if name not in LOCAL:
                errors.append(f"{row_id}: unknown skill: {name}")
        primary_seen |= set(expected)
        if set(expected) & set(support):
            errors.append(f"{row_id}: primary is also supporting")
        if set(expected) & set(blocked):
            errors.append(f"{row_id}: primary is also forbidden")
        if set(support) & set(blocked):
            errors.append(f"{row_id}: both supporting and forbidden")

    missing = LOCAL - primary_seen
    if missing:
        errors.append(f"skills with no primary matrix row: {', '.join(sorted(missing))}")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"skill trigger matrix passed ({rows} rows, {len(LOCAL)} skills)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
