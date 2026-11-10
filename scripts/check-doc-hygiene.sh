#!/usr/bin/env bash
# Reject planning artifacts and development history in tracked docs and code.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}" || exit 1

fail=0
tmp_err="$(mktemp)"
trap 'rm -f "${tmp_err}"' EXIT

err() {
  printf 'FAIL: %s\n' "$*" >&2
  fail=1
}

# scan <label> <pattern> [pathspec...] — fail on matches or git errors.
scan() {
  local label="$1" pattern="$2" hits status=0
  shift 2
  : > "${tmp_err}"
  hits="$(git grep -niI -E "${pattern}" -- . "$@" 2>"${tmp_err}")" || status=$?
  if [ -s "${tmp_err}" ]; then
    cat "${tmp_err}" >&2
    err "scan failed: ${label}"
    return
  fi
  if [ "${status}" -gt 1 ]; then
    err "scan failed: ${label}"
    return
  fi
  if [ "${status}" -eq 0 ]; then
    printf '%s\n' "${hits}" >&2
    err "${label}"
  fi
}

# History markers and dates are banned everywhere, including skills.
history='(^|[^[:alnum:]_])(superseded|kept as history|what bit us|sanitization applied|future work|coming soon)([^[:alnum:]_]|$)|^[[:space:]]*#{1,6}[[:space:]].*(incident log|postmortem|retrospective|changelog|release notes|creation log)|(^|[^0-9])(19|20)[0-9]{2}[-/][0-9]{2}([-/][0-9]{2})?([^0-9]|$)|(January|February|March|April|May|June|July|August|September|October|November|December)[[:space:]]+([0-9]{1,2},?[[:space:]]+)?(19|20)[0-9]{2}'

# Milestone vocabulary is banned everywhere; only skill template layout is exempt.
plan_words='(^|[^[:alnum:]_])(milestones?|roadmaps?|phasing|sprints?|epics?|backlogs?|workstreams?)([^[:alnum:]_]|$)'
plan_template='^[[:space:]]*#{1,6}[[:space:]]+(.*[^[:alnum:]_])?(phase|step|task)[ _-]?[0-9]+|^[[:space:]]*[-*][[:space:]]*\[[ xX]\]'

scan "development history in tracked files" "${history}" \
  ':(exclude)scripts/check-doc-hygiene.sh' \
  ':(exclude)scripts/tests/**'

scan "milestone vocabulary in tracked files" "${plan_words}" \
  ':(exclude)scripts/check-doc-hygiene.sh' \
  ':(exclude)scripts/tests/**'

scan "planning artifact in tracked files" "${plan_template}" \
  ':(exclude)agents/.agents/skills/**' \
  ':(exclude)opencode/.config/opencode/skills/**' \
  ':(exclude)scripts/check-doc-hygiene.sh' \
  ':(exclude)scripts/tests/**'

status=0
: > "${tmp_err}"
tracked="$(git ls-files 2>"${tmp_err}")" || status=$?
if [ -s "${tmp_err}" ] || [ "${status}" -gt 0 ]; then
  cat "${tmp_err}" >&2
  err "git ls-files failed"
  tracked=""
fi

if printf '%s\n' "${tracked}" | grep -q '^docs/plans/'; then
  err "docs/plans/ is local scratch and must never be committed"
fi
if printf '%s\n' "${tracked}" | grep -E '(^|/)[^/]*(19|20)[0-9]{2}[-/][0-9]{2}([-/][0-9]{2})?' >/dev/null; then
  err "dated documents belong in agent-memory, not the repo"
fi
if ! git check-ignore -q docs/plans/probe; then
  err "docs/plans/ must be gitignored"
fi

if [ "${fail}" -ne 0 ]; then
  exit 1
fi
printf 'documentation hygiene checks passed\n'
