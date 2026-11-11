#!/usr/bin/env bash
# Prove the skill trigger matrix checker rejects malformed rows and links.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MATRIX="${ROOT}/agents/.agents/skills/writing-skills/trigger-matrix.md"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
cp "${MATRIX}" "${TMP}/matrix.md"

check() {
  python3 "${ROOT}/scripts/check-skill-triggers.py" \
    --matrix "${TMP}/matrix.md" \
    --link-root "$(dirname "${MATRIX}")"
}

reset() {
  cp "${MATRIX}" "${TMP}/matrix.md"
}

mutate_row() {
  python3 - "${TMP}/matrix.md" "$1" "$2" "$3" <<'PY'
import sys
from pathlib import Path

path, row_id, column, value = Path(sys.argv[1]), sys.argv[2], int(sys.argv[3]), sys.argv[4]
lines = path.read_text().splitlines()
for index, line in enumerate(lines):
    if line.startswith(f"| {row_id} |"):
        cells = [cell.strip() for cell in line.strip()[1:-1].split("|")]
        cells[column] = value
        lines[index] = "| " + " | ".join(cells) + " |"
        path.write_text("\n".join(lines) + "\n")
        raise SystemExit(0)
raise SystemExit(f"row not found: {row_id}")
PY
}

expect_pass() {
  if ! check >/dev/null 2>&1; then
    printf 'FAIL: expected pass: %s\n' "$1" >&2
    check >&2 || true
    exit 1
  fi
}

expect_fail() {
  local output
  if output="$(check 2>&1)"; then
    printf 'FAIL: expected rejection: %s\n' "$1" >&2
    exit 1
  fi
  if ! printf '%s\n' "${output}" | grep -Fq "$2"; then
    printf 'FAIL: %s failed for the wrong reason\n%s\n' "$1" "${output}" >&2
    exit 1
  fi
}

delete_row() {
  python3 - "${TMP}/matrix.md" "$1" <<'PY'
import sys
from pathlib import Path

path, row_id = Path(sys.argv[1]), sys.argv[2]
lines = path.read_text().splitlines()
kept = [line for line in lines if not line.startswith(f"| {row_id} |")]
if len(kept) == len(lines):
    raise SystemExit(f"row not found: {row_id}")
path.write_text("\n".join(kept) + "\n")
PY
}

expect_pass "baseline"

mutate_row T01 0 "t01"
expect_fail "lowercase id" "invalid matrix id"
reset

mutate_row T01 3 '`memory`'
expect_fail "unlinked supporting skill" "unlinked text"
reset

mutate_row T01 3 '[`memory`](../documentation/SKILL.md)'
expect_fail "wrong backticked target" "does not match"
reset

mutate_row T01 3 '[memory](../documentation/SKILL.md)'
expect_fail "wrong non-backticked target" "does not match"
reset

mutate_row T01 3 '[`memory`](https://example.com/SKILL.md)'
expect_fail "external skill link" "must be local"
reset

mutate_row T01 3 '[`memory`](../missing/SKILL.md)'
expect_fail "missing skill link" "missing link"
reset

mutate_row T01 2 '`ponytail`'
expect_fail "unlinked primary" "unlinked text"
reset

mutate_row T02 0 "T01"
expect_fail "duplicate id" "duplicate matrix id"
reset

mutate_row T02 1 "Simplify this over-engineered helper; use the smallest change."
expect_fail "duplicate prompt" "duplicate prompt"
reset

mutate_row T01 3 '[`ponytail`](../ponytail/SKILL.md)'
expect_fail "primary also supporting" "primary is also supporting"
reset

mutate_row T01 4 '[`ponytail`](../ponytail/SKILL.md)'
expect_fail "primary also forbidden" "primary is also forbidden"
reset

mutate_row T04 2 '[`ponytail`](../ponytail/SKILL.md)'
expect_pass "repeated primary"
reset

printf '| T99 | spare | `ponytail` |\n' >> "${TMP}/matrix.md"
expect_fail "malformed row" "row has 3 columns"
reset

printf 'T99 | spare | `ponytail` | | |\n' >> "${TMP}/matrix.md"
expect_fail "row without leading pipe" "table row must start with |"
reset

printf 't99 | spare | `ponytail` | | |\n' >> "${TMP}/matrix.md"
expect_fail "lowercase row without leading pipe" "table row must start with |"
reset

printf '|| T99 | spare | [`memory`](../memory/SKILL.md) | | |\n' >> "${TMP}/matrix.md"
expect_fail "extra leading pipe" "row has 6 columns"
reset

printf '  | T99 | spare | [`memory`](../memory/SKILL.md) | | |\n' >> "${TMP}/matrix.md"
expect_pass "indented row"
reset

printf '| T99 | spare | [`memory`](../memory/SKILL.md) | | x\n' >> "${TMP}/matrix.md"
expect_fail "missing trailing pipe" "table row must start with |"
reset

mutate_row T02 3 '[`documentation`](../documentation/SKILL.md)'
expect_fail "supporting equals forbidden" "both supporting and forbidden"
reset

mutate_row T05 1 ""
expect_fail "empty prompt" "empty prompt"
reset

mutate_row T01 2 '[`ponytail`](../ponytail/SKILL.md), [`memory`](../memory/SKILL.md)'
expect_fail "multiple primary skills" "primary must name exactly one skill"
reset

mutate_row T01 3 '[`nope`](../nope/SKILL.md)'
expect_fail "unknown skill" "unknown skill: nope"
reset

delete_row T17
delete_row T24
expect_fail "missing primary coverage" "skills with no primary matrix row: writing-skills"
reset

printf 'skill trigger matrix tests passed\n'
