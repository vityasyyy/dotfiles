#!/usr/bin/env bash
# Shared Homebrew permission helper for multi-user Macs.
set -euo pipefail

MODE=""
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: brew-share.sh --check | --apply [--dry-run]

  --check     Report whether this profile can write to the shared brew prefix.
  --apply     Backfill group write and add an inheriting ACL for group admin.
  --dry-run   With --apply, print the commands without running them.
  --help      Show this help.

Single-user Macs need no action: if the current user owns the prefix, --check
reports that and exits 0.
EOF
}

log() { printf '%s\n' "$*"; }

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

check() {
  if [ "$(uname -s)" != "Darwin" ]; then
    log "skip: brew-share is macOS-only"
    return 0
  fi
  if ! command -v brew >/dev/null 2>&1; then
    log "skip: brew not found"
    return 0
  fi

  local p owner group current locks bad acl acl_ok
  p="$(brew --prefix)"
  owner="$(stat -f '%Su' "$p")"
  group="$(stat -f '%Sg' "$p")"
  current="$(id -un)"

  locks="$p/var/homebrew/locks"
  bad=0
  if [ -d "$locks" ]; then
    bad="$(find "$locks" -type f ! -perm -g+w 2>/dev/null | wc -l | tr -d ' ')"
  fi

  acl_ok=0
  acl="$(ls -lde "$p" 2>/dev/null || true)"
  case "$acl" in
    *"group:admin allow"*) acl_ok=1 ;;
  esac

  if [ "$owner" = "$current" ]; then
    if [ "$group" = "admin" ] && [ "$bad" -eq 0 ] && [ "$acl_ok" -eq 1 ]; then
      log "ok: $p is owned by $current and is shared-ready"
    else
      log "ok: $p is owned by $current; shared access is not configured"
      log "note: run --apply if another admin profile will use this brew"
    fi
    return 0
  fi

  if ! id -Gn "$current" | tr ' ' '\n' | grep -qx admin; then
    log "error: $p is owned by $owner, but $current is not in the admin group"
    return 1
  fi

  log "shared: $p (owner $owner, group $group)"
  [ "$group" = "admin" ] || log "warning: prefix group is $group, expected admin"
  [ "$bad" -eq 0 ] || log "warning: $bad lock file(s) are not group-writable; run --apply"
  [ "$acl_ok" -eq 1 ] || log "warning: no inheriting group:admin ACL on $p; run --apply"

  return 0
}

apply() {
  if [ "$(uname -s)" != "Darwin" ]; then
    log "skip: brew-share is macOS-only"
    return 0
  fi
  if ! command -v brew >/dev/null 2>&1; then
    log "skip: brew not found"
    return 0
  fi

  local p
  p="$(brew --prefix)"

  log "backfilling group write on $p"
  run sudo chgrp -R admin "$p"
  run sudo chmod -R g+rwX "$p"

  log "adding inheriting ACL for group admin on directories under $p"
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run] sudo find %q -type d -exec chmod +a %q {} +\n' "$p" \
      "group:admin allow file_inherit,directory_inherit,read,write,execute,delete,append,readattr,writeattr,readextattr,writeextattr,readsecurity"
  else
    sudo find "$p" -type d -exec chmod +a \
      "group:admin allow file_inherit,directory_inherit,read,write,execute,delete,append,readattr,writeattr,readextattr,writeextattr,readsecurity" {} +
  fi

  log "done; verify with: $0 --check"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --check) MODE=check ;;
    --apply) MODE=apply ;;
    --dry-run) DRY_RUN=1 ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

[ -n "$MODE" ] || { usage >&2; exit 1; }
"$MODE"
