#!/usr/bin/env bash
# Move this machine from manual/npm AI tools to the brew-owned set.
set -euo pipefail

APPLY=0

usage() {
  cat <<'EOF'
Usage: migrate-tools.sh [--apply]

Dry-run by default: prints every command without changing the machine.
--apply runs the commands. Config and auth are preserved; only binaries and
package-manager state are touched.
EOF
}

case "${1:-}" in
  --apply) APPLY=1 ;;
  --help|-h) usage; exit 0 ;;
  "") ;;
  *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 1 ;;
esac

if ! command -v brew >/dev/null 2>&1; then
  printf 'migrate-tools: brew not found\n' >&2
  exit 1
fi

run() {
  printf '+ %s\n' "$*"
  if [ "$APPLY" -eq 1 ]; then
    "$@"
  fi
}

# Trust the V2 tap before upgrading from it.
run brew trust --tap anomalyco/tap

# Remove the npm-owned codex before the cask claims /opt/homebrew/bin/codex.
if command -v npm >/dev/null 2>&1 && npm list -g --depth=0 @openai/codex >/dev/null 2>&1; then
  run npm uninstall -g @openai/codex
fi

run brew install --cask codex
run brew install --cask claude-code
run brew install herdr
run brew upgrade opencode-v2

# Adopt the GUI apps only when the manual app is not already brew-managed.
if [ -d /Applications/Ghostty.app ] && ! brew list --cask ghostty >/dev/null 2>&1; then
  printf 'Ghostty.app exists but is not brew-managed. Quit Ghostty, then run:\n'
  printf '  brew install --cask --force ghostty\n'
else
  run brew install --cask ghostty
fi

if [ -d /Applications/Antigravity.app ] && ! brew list --cask antigravity >/dev/null 2>&1; then
  printf 'Antigravity.app exists but is not brew-managed. Quit it, then run:\n'
  printf '  brew install --cask --force antigravity\n'
else
  run brew install --cask antigravity
fi
run brew install --cask antigravity-cli

# Remove the manual binaries only after the brew versions are installed.
if [ -x /opt/homebrew/bin/claude ] || [ "$APPLY" -eq 0 ]; then
  run rm -f "$HOME/.local/bin/claude"
  run rm -rf "$HOME/.local/share/claude"
fi
if [ -x /opt/homebrew/bin/herdr ] || [ "$APPLY" -eq 0 ]; then
  run rm -f "$HOME/.local/bin/herdr"
fi

# Remove only the manual Antigravity CLI symlinks; keep any app config.
run rm -f "$HOME/.antigravity/antigravity/bin/agy"
run rm -f "$HOME/.antigravity/antigravity/bin/antigravity"
run rmdir "$HOME/.antigravity/antigravity/bin" 2>/dev/null || true
run rmdir "$HOME/.antigravity/antigravity" 2>/dev/null || true
run rmdir "$HOME/.antigravity" 2>/dev/null || true
run rm -f "$HOME"/.local/bin/.herdr-update-*.tmp

if brew tap | grep -qx 'cloudflare/cloudflare'; then
  run brew untap cloudflare/cloudflare
fi

printf '\nOptional: brew uninstall gemini-cli (deprecated; replaced by antigravity-cli)\n'
printf 'Done. Run: ./install.sh --check\n'
