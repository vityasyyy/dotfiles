#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../../.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin"
cat >"$tmp/bin/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$HERDR_CALLS"
case "$1 $2" in
  "workspace get")
    printf '%s\n' '{"result":{"workspace":{"label":"parent"}}}'
    ;;
  "worktree list")
    if [ "${HERDR_LIST_FAIL:-0}" = 1 ]; then
      printf '%s\n' '{"error":{"code":"not_git_worktree"}}' >&2
      exit 1
    fi
    if [ "${HERDR_MATCH:-0}" = 1 ]; then
      printf '{"result":{"worktrees":[{"path":"%s","is_linked_worktree":%s}]}}\n' "$HERDR_TARGET" "${HERDR_LINKED:-true}"
    else
      printf '%s\n' '{"result":{"worktrees":[]}}'
    fi
    ;;
  "worktree open")
    if [ "${HERDR_OPEN_FAIL:-0}" = 1 ]; then
      printf '%s\n' '{"error":{"code":"worktree_not_found"}}' >&2
      exit 1
    fi
    printf '{"result":{"workspace":{"workspace_id":"w2"},"root_pane":{"pane_id":"w2:p1"},"already_open":%s}}\n' "${HERDR_ALREADY_OPEN:-false}"
    ;;
  "workspace create")
    printf '%s\n' '{"result":{"workspace":{"workspace_id":"w2"},"root_pane":{"pane_id":"w2:p1"}}}'
    ;;
  "agent start")
    if [ "${HERDR_START_FAIL:-0}" = 1 ]; then
      printf '%s\n' '{"error":{"code":"agent_start_failed"}}' >&2
      exit 1
    fi
    ;;
  "agent get")
    exit 1
    ;;
  "workspace close")
    ;;
  *)
    echo "unexpected herdr command: $*" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$tmp/bin/herdr"

cat >"$tmp/bin/sleep" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$tmp/bin/sleep"

linked="$tmp/linked"
fallback="$tmp/fallback"
mkdir -p "$linked" "$fallback"
linked="$(cd "$linked" && pwd -P)"
fallback="$(cd "$fallback" && pwd -P)"

run_spawn() {
  HERDR="$tmp/bin/herdr" HERDR_CALLS="$tmp/calls" HERDR_WORKSPACE_ID=w1 \
    PATH="$tmp/bin:$PATH" "$repo_root/opencode/.local/bin/herd" spawn worker "$1"
}

assert_call() {
  if ! grep -Fxq -- "$1" "$tmp/calls"; then
    echo "missing Herdr call: $1" >&2
    return 1
  fi
}

assert_no_matching_call() {
  if grep -Fq -- "$1" "$tmp/calls"; then
    echo "unexpected Herdr call: $1" >&2
    return 1
  fi
}

: >"$tmp/calls"
HERDR_MATCH=1 HERDR_TARGET="$linked" HERDR_ALREADY_OPEN=false run_spawn "$linked"
assert_call "worktree open --workspace w1 --path $linked --label worker --no-focus"
assert_call 'agent start worker --kind opencode --pane w2:p1'
assert_no_matching_call "workspace create --cwd $linked "
assert_no_matching_call 'pane split'

: >"$tmp/calls"
HERDR_MATCH=0 run_spawn "$fallback"
assert_call 'workspace create --cwd '"$fallback"' --label parent/worker --no-focus'
assert_call 'agent start worker --kind opencode --pane w2:p1'
assert_no_matching_call 'worktree open --workspace w1 '

: >"$tmp/calls"
HERDR_MATCH=1 HERDR_LINKED=false HERDR_TARGET="$linked" run_spawn "$linked"
assert_call 'workspace create --cwd '"$linked"' --label parent/worker --no-focus'
assert_no_matching_call 'worktree open --workspace w1 '

: >"$tmp/calls"
HERDR_LIST_FAIL=1 run_spawn "$fallback"
assert_call 'workspace create --cwd '"$fallback"' --label parent/worker --no-focus'

: >"$tmp/calls"
if HERDR_MATCH=1 HERDR_TARGET="$linked" HERDR_OPEN_FAIL=1 run_spawn "$linked" >/dev/null 2>&1; then
  echo 'expected worktree open failure' >&2
  exit 1
fi
assert_call "worktree open --workspace w1 --path $linked --label worker --no-focus"
assert_no_matching_call "workspace create --cwd $linked "

: >"$tmp/calls"
if HERDR_MATCH=1 HERDR_TARGET="$linked" HERDR_ALREADY_OPEN=true HERDR_START_FAIL=1 run_spawn "$linked" >/dev/null 2>&1; then
  echo 'expected agent start failure for existing workspace' >&2
  exit 1
fi
assert_no_matching_call 'workspace close w2'

: >"$tmp/calls"
if HERDR_MATCH=1 HERDR_TARGET="$linked" HERDR_ALREADY_OPEN=false HERDR_START_FAIL=1 run_spawn "$linked" >/dev/null 2>&1; then
  echo 'expected agent start failure for newly opened workspace' >&2
  exit 1
fi
assert_call 'workspace close w2'
