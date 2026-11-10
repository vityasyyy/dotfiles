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

# agent_denies <file> <action>... — true when every action is denied.
agent_denies() {
  local file="$1"
  shift
  awk -v required="$*" '
    BEGIN { n = split(required, want, " ") }
    /^[[:space:]]*-[[:space:]]*action:/ { action=$3 }
    /^[[:space:]]*effect:/ { effect=$2 }
    action != "" && effect != "" {
      denied[action] = (effect == "deny")
      action=""; effect=""
    }
    END {
      for (i = 1; i <= n; i++) {
        if (!denied[want[i]]) exit 1
      }
      exit 0
    }
  ' "${file}"
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

codex_lines="$(wc -l < codex/.codex/AGENTS.md | tr -d ' ')"
if [ "${codex_lines}" -gt 110 ]; then
  err "codex/.codex/AGENTS.md is ${codex_lines} lines (cap 110)"
fi
if ! python3 -c 'import json,sys; json.load(open(sys.argv[1]))' \
  claude/.claude/settings.json; then
  err "claude/.claude/settings.json is not valid JSON"
fi
for agent in claude/.claude/agents/*.md; do
  grep -q '^name: ' "${agent}" || err "${agent} is missing name"
  grep -q '^description: ' "${agent}" || err "${agent} is missing description"
done
claude_review="claude/.claude/agents/review.md"
if [ ! -f "${claude_review}" ]; then
  err "Claude review agent is missing"
elif ! grep -q '^tools: ' "${claude_review}"; then
  err "Claude review agent must declare tools"
elif grep -Eq '^tools:.*(Edit|Write|NotebookEdit)' "${claude_review}"; then
  err "Claude review agent must not have Edit or Write"
fi

claude_explore="claude/.claude/agents/explore.md"
if [ ! -f "${claude_explore}" ]; then
  err "Claude explore agent is missing"
elif ! grep -q '^tools: ' "${claude_explore}"; then
  err "Claude explore agent must declare tools"
elif grep -Eq '^tools:.*(Edit|Write|NotebookEdit)' "${claude_explore}"; then
  err "Claude explore agent must not have Edit or Write"
fi

# OpenCode agents have valid frontmatter; the review agent stays read-only.
while IFS= read -r -d '' agent; do
  if [ "$(head -n 1 "${agent}")" != "---" ]; then
    err "${agent} is missing frontmatter"
    continue
  fi
  grep -q '^description: ' "${agent}" || err "${agent} is missing description"
done < <(find opencode/.config/opencode/agents -name '*.md' -print0)

review_agent="opencode/.config/opencode/agents/review.md"
if [ ! -f "${review_agent}" ]; then
  err "review agent is missing"
else
  grep -q '^mode: subagent' "${review_agent}" \
    || err "review agent must be a subagent"
  grep -q '^model: opencode-go/deepseek-v4.1-flash#max' "${review_agent}" \
    || err "review agent must pin DS V4.1 Flash max"
  agent_denies "${review_agent}" edit task \
    || err "review agent must deny edit and task"
fi

explore_agent="opencode/.config/opencode/agents/explore.md"
if [ ! -f "${explore_agent}" ]; then
  err "explore agent is missing"
else
  agent_denies "${explore_agent}" edit \
    || err "explore agent must deny edit"
fi

worker_agent="opencode/.config/opencode/agents/worker.md"
if [ ! -f "${worker_agent}" ]; then
  err "worker agent is missing"
else
  grep -q '^mode: primary' "${worker_agent}" \
    || err "worker agent must be a primary agent"
  grep -q '^model: opencode-go/deepseek-v4.1-flash#max' "${worker_agent}" \
    || err "worker agent must pin DS V4.1 Flash max"
fi

if ! grep -q -- '"agent":"worker"' opencode/.local/bin/herd; then
  err "herd spawn must create a worker session"
fi
if ! grep -q -- '-- --session "$session_id"' opencode/.local/bin/herd; then
  err "herd spawn must open the worker session"
fi

review_command="opencode/.config/opencode/commands/review.md"
if [ ! -f "${review_command}" ]; then
  err "review command is missing"
else
  grep -q '^agent: review' "${review_command}" \
    || err "review command must target the review agent"
  grep -q '^subtask: true' "${review_command}" \
    || err "review command must set subtask: true"
fi

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
if ! python3 - <<'PY'
import json

config = json.load(open("opencode/.config/opencode/opencode.json"))
asks = {
    item.get("resource")
    for item in config.get("permissions", [])
    if item.get("action") == "bash" and item.get("effect") == "ask"
}
required = {
    "rm -r*",
    "git reset --hard*",
    "git push --force*",
    "kubectl *",
    "terraform apply*",
    "aws *",
}
raise SystemExit(0 if required <= asks else 1)
PY
then
  err "global destructive-command ask rules are missing"
fi

for file in opencode/.config/opencode/AGENTS.md claude/.claude/CLAUDE.md codex/.codex/AGENTS.md; do
  grep -q 'Ask before destructive commands' "${file}" \
    || err "${file} is missing the destructive-command approval rule"
done

# Scaffolded templates carry the review contract and stay idempotent.
check_dir="$(mktemp -d)"
mem_bin=agents/.agents/skills/memory/scripts/mem
plan_path="$(AGENT_MEMORY_DIR="${check_dir}" "${mem_bin}" plan --task check)" \
  || err "mem plan failed"
plan_again="$(AGENT_MEMORY_DIR="${check_dir}" "${mem_bin}" plan --task check)" \
  || err "mem plan failed on rerun"
[ "${plan_path}" = "${plan_again}" ] || err "mem plan is not idempotent"
for field in Behavior Acceptance Gate Evidence; do
  grep -q "^${field}:" "${plan_path}" 2>/dev/null \
    || err "mem plan is missing ${field}"
done
handoff_path="$(AGENT_MEMORY_DIR="${check_dir}" "${mem_bin}" handoff --task check)" \
  || err "mem handoff failed"
for field in Plan Acceptance Gate; do
  grep -q "^${field}:" "${handoff_path}" 2>/dev/null \
    || err "mem handoff is missing ${field}"
done
grep -Fq "Plan: ${plan_path}" "${handoff_path}" 2>/dev/null \
  || err "mem handoff does not point at the plan"
printf 'keep\n' >> "${handoff_path}"
AGENT_MEMORY_DIR="${check_dir}" "${mem_bin}" handoff --task check >/dev/null \
  || err "mem handoff failed on rerun"
grep -q keep "${handoff_path}" 2>/dev/null \
  || err "mem handoff overwrites an existing file"
unknown_path="$(AGENT_MEMORY_DIR="${check_dir}" "${mem_bin}" handoff --task unplanned)" \
  || err "mem handoff failed without a plan"
grep -q '^Plan: unknown$' "${unknown_path}" 2>/dev/null \
  || err "mem handoff does not default to unknown"
rm -rf "${check_dir}"

# Every skill has portable frontmatter, and its name matches its directory.
while IFS= read -r -d '' skill; do
  if ! message="$(ruby -ryaml -e '
    path = ARGV[0]
    text = File.read(path)
    body = text.sub(/\A---\r?\n/, "")
    abort "missing frontmatter" if body == text
    front, rest = body.split(/^---\s*$/, 2)
    abort "missing closing frontmatter" unless rest
    begin
      data = YAML.safe_load(front) || {}
    rescue StandardError => e
      abort "invalid YAML: #{e.message}"
    end
    abort "frontmatter is not a mapping" unless data.is_a?(Hash)
    name = data["name"].to_s
    description = data["description"].to_s
    abort "missing name" if name.empty?
    expected = File.basename(File.dirname(path))
    abort "name #{name.inspect} does not match directory #{expected.inspect}" unless name == expected
    abort "missing description" if description.empty?
    abort "description exceeds 1024 characters" if description.length > 1024
  ' "${skill}" 2>&1)"; then
    err "${skill}: ${message}"
  fi
done < <(find agents/.agents/skills opencode/.config/opencode/skills -name SKILL.md -print0)

# Every skill is referenced in at least one harness routing instruction.
while IFS= read -r -d '' skill; do
  skill_name="$(basename "$(dirname "${skill}")")"
  if ! grep -Fq -- "\`${skill_name}\`" \
    opencode/.config/opencode/AGENTS.md \
    claude/.claude/CLAUDE.md \
    codex/.codex/AGENTS.md; then
    err "skill is not routed: ${skill_name}"
  fi
done < <(find agents/.agents/skills opencode/.config/opencode/skills -name SKILL.md -print0)

# Deleted skills must not reappear in active configuration.
if grep -rn -E 'engineering-core|find-skills|brainstorming|executing-plans|receiving-code-review|confluence-authoring' \
  --include='*.md' opencode agents codex claude docs/agent-memory.md 2>/dev/null \
  | grep -Ev 'authoring-guide' >/dev/null; then
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
