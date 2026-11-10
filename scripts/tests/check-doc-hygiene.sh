#!/usr/bin/env bash
# Prove the documentation hygiene gate rejects artifacts and accepts clean trees.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

mkdir -p "${TMP}/scripts"
cp "${ROOT}/scripts/check-doc-hygiene.sh" "${TMP}/scripts/check-doc-hygiene.sh"
cd "${TMP}"
git init -q
git config user.email test@example.com
git config user.name test
printf 'docs/plans/\n' > .gitignore
printf '# Project\n\nCurrent state.\n' > README.md
printf '# shell config\n' > .zshrc
git add .gitignore README.md .zshrc

gate() {
  bash scripts/check-doc-hygiene.sh
}

expect_pass() {
  local out
  if ! out="$(gate 2>&1)"; then
    printf 'FAIL: expected pass: %s\n%s\n' "$1" "${out}" >&2
    exit 1
  fi
}

expect_fail() {
  local label="$1" expected="$2" out
  if out="$(gate 2>&1)"; then
    printf 'FAIL: expected rejection: %s\n' "${label}" >&2
    exit 1
  fi
  if ! printf '%s\n' "${out}" | grep -Fq "FAIL: ${expected}"; then
    printf 'FAIL: %s failed for the wrong reason\n%s\n' "${label}" "${out}" >&2
    exit 1
  fi
}

expect_pass "clean tree"

printf '# Project\n\n## Phase 1\n' > README.md
expect_fail "phase heading" "planning artifact in tracked files"
printf '# Project\n\n## Roadmaps\n' > README.md
expect_fail "plural milestone heading" "milestone vocabulary in tracked files"
printf '# Project\n\nCurrent state as of December 2025.\n' > README.md
expect_fail "month-name date" "development history in tracked files"
printf '# Project\n\nCurrent state.\n' > README.md

printf 'x\n' > locked.md
git add locked.md
chmod 000 locked.md
expect_fail "git read failure" "scan failed: development history in tracked files"
chmod 644 locked.md
git rm -q --cached locked.md
rm -f locked.md

mkdir -p notes src
printf '# Current\n\nThe epicenter is here. See PR #123 for context.\n' > notes/current.md
printf '// Step 2: normalize the input\n// The flag is no longer supported.\n' > src/current.ts
git add notes/current.md src/current.ts
expect_pass "current-state prose and comments"
git rm -q --cached notes/current.md src/current.ts
rm -rf notes src

mkdir -p docs/plans
printf '# local scratch\n' > docs/plans/local.md
expect_pass "untracked local plan"
git add -f docs/plans/local.md
expect_fail "tracked local plan" "docs/plans/ is local scratch"
git rm -q --cached docs/plans/local.md
rm -rf docs/plans

printf '# no ignore rule\n' > .gitignore
expect_fail "missing docs/plans ignore" "docs/plans/ must be gitignored"
printf '/docs/plans/**\n' > .gitignore
expect_pass "alternate ignore form"
printf 'docs/plans/\n' > .gitignore

mkdir -p notes
printf '# Design\n' > notes/2026-10-13-design.md
git add notes/2026-10-13-design.md
expect_fail "dated document" "dated documents belong in agent-memory"
git rm -q --cached notes/2026-10-13-design.md
rm -f notes/2026-10-13-design.md
printf '# Design\n' > notes/2026-10-design.md
git add notes/2026-10-design.md
expect_fail "month-only dated document" "dated documents belong in agent-memory"
git rm -q --cached notes/2026-10-design.md
rm -rf notes

printf '# Project\n\n## Incident log\n\nSomething happened.\n' > README.md
expect_fail "history heading" "development history in tracked files"
printf '# Project\n\nCurrent state.\n' > README.md

printf '# shell config\n# Created on 2025-12-03\n' > .zshrc
expect_fail "dated source comment" "development history in tracked files"
printf '# shell config\n' > .zshrc

printf '# Project\n\n- [x] Done\n' > PLAN.md
git add PLAN.md
expect_fail "checkbox plan" "planning artifact in tracked files"
printf '# Project\n\n### Task 1\n' > PLAN.md
git add PLAN.md
expect_fail "plan heading without checkbox" "planning artifact in tracked files"
git rm -q --cached -f PLAN.md
rm -f PLAN.md

mkdir -p agents/.agents/skills/demo
printf '# Demo\n\n### Task 1\n\n- [ ] Do it\n' > agents/.agents/skills/demo/SKILL.md
git add agents/.agents/skills/demo/SKILL.md
expect_pass "skill template"
printf '# Demo\n\n## Milestone\n' > agents/.agents/skills/demo/MILESTONE.md
git add agents/.agents/skills/demo/MILESTONE.md
expect_fail "milestone vocabulary in a skill" "milestone vocabulary in tracked files"
git rm -q --cached agents/.agents/skills/demo/MILESTONE.md
rm -f agents/.agents/skills/demo/MILESTONE.md
printf '# Demo history\n\nCreated: 2025-10-03\n' > agents/.agents/skills/demo/HISTORY.md
git add agents/.agents/skills/demo/HISTORY.md
expect_fail "dated skill history" "development history in tracked files"
git rm -q --cached agents/.agents/skills/demo/SKILL.md agents/.agents/skills/demo/HISTORY.md
rm -rf agents

printf 'documentation hygiene tests passed\n'
