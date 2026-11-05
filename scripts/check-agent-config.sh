#!/usr/bin/env bash
# Validate the agent-config invariants that keep the stack lean.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}" || exit 1

fail=0

err() {
  printf 'FAIL: %s\n' "$*" >&2
  fail=1
}

# Tier 0 stays small.
tier0_lines="$(wc -l < opencode/.config/opencode/AGENTS.md | tr -d ' ')"
if [ "${tier0_lines}" -gt 110 ]; then
  err "opencode/.config/opencode/AGENTS.md is ${tier0_lines} lines (cap 110)"
fi

claude_lines="$(wc -l < claude/.claude/CLAUDE.md | tr -d ' ')"
if [ "${claude_lines}" -gt 110 ]; then
  err "claude/.claude/CLAUDE.md is ${claude_lines} lines (cap 110)"
fi
if ! python3 -c 'import json,sys; json.load(open(sys.argv[1]))' \
  claude/.claude/settings.json; then
  err "claude/.claude/settings.json is not valid JSON"
fi
for agent in claude/.claude/agents/*.md; do
  grep -q '^name: ' "${agent}" || err "${agent} is missing name"
  grep -q '^description: ' "${agent}" || err "${agent} is missing description"
done

# The config parses, and MCP stays project-local.
if ! python3 -c 'import json,sys; json.load(open(sys.argv[1]))' \
  opencode/.config/opencode/opencode.json; then
  err "opencode/.config/opencode/opencode.json is not valid JSON"
fi
if ! python3 - <<'PY'
import json

config = json.load(open("opencode/.config/opencode/opencode.json"))
servers = config.get("mcp", {}).get("servers", {})
raise SystemExit(0 if not servers else 1)
PY
then
  err "global mcp.servers must be empty; enable MCP per project"
fi

# Every skill has portable frontmatter.
while IFS= read -r -d '' skill; do
  if [ "$(head -n 1 "${skill}")" != "---" ]; then
    err "${skill} is missing frontmatter"
    continue
  fi
  grep -q '^name: ' "${skill}" || err "${skill} is missing name"
  grep -q '^description: ' "${skill}" || err "${skill} is missing description"
  description="$(sed -n 's/^description: //p' "${skill}" | head -n 1)"
  if [ "${#description}" -gt 1024 ]; then
    err "${skill} description exceeds 1024 characters"
  fi
done < <(find agents/.agents/skills opencode/.config/opencode/skills -name SKILL.md -print0)

# Deleted skills must not reappear in active configuration.
if grep -rn -E 'engineering-core|find-skills|brainstorming|executing-plans|receiving-code-review' \
  --include='*.md' opencode agents codex claude docs/agent-memory.md 2>/dev/null \
  | grep -Ev 'authoring-guide|2026-10-13-skill-stack' >/dev/null; then
  err "active configuration references a deleted skill"
fi

# The memory CLI is valid Python.
python3 - <<'PY' || err "memory CLI has a syntax error"
import ast

source = open("agents/.agents/skills/memory/scripts/mem").read()
ast.parse(source)
PY

if [ "${fail}" -ne 0 ]; then
  exit 1
fi
printf 'agent config checks passed\n'
