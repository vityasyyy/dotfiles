#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../../.." && pwd -P)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat >"$tmp/herdr" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"$HERDR_CALLS"
case "$1 $2" in
  "workspace get")
    printf '%s\n' '{"result":{"workspace":{"label":"parent"}}}'
    ;;
  "workspace create")
    printf '%s\n' '{"result":{"workspace":{"workspace_id":"w2"},"root_pane":{"pane_id":"w2:p1"}}}'
    ;;
  "agent start")
    ;;
  *)
    echo "unexpected herdr command: $*" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$tmp/herdr"

HERDR="$tmp/herdr" HERDR_CALLS="$tmp/calls" HERDR_WORKSPACE_ID=w1 \
  "$repo_root/opencode/.local/bin/herd" spawn worker "$repo_root"

grep -Fx 'workspace create --cwd '"$repo_root"' --label parent/worker --no-focus' "$tmp/calls"
grep -Fx 'agent start worker --kind opencode --pane w2:p1' "$tmp/calls"
! grep -q 'pane split' "$tmp/calls"
