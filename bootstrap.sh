#!/usr/bin/env bash
# Bootstrap a blank Apple Silicon Mac: install Homebrew, then run install.sh.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [install.sh options]

Installs Homebrew if missing, then runs ./install.sh. On a Mac that already
has Homebrew, it goes straight to install.sh.
EOF
}

case "${1:-}" in
  --help|-h) usage; exit 0 ;;
esac

if [ "$(uname -s)" != "Darwin" ]; then
  printf 'bootstrap: macOS only\n' >&2
  exit 1
fi
if [ "$(uname -m)" != "arm64" ]; then
  printf 'bootstrap: Apple Silicon only (found %s)\n' "$(uname -m)" >&2
  exit 1
fi

if [ -x /opt/homebrew/bin/brew ] && ! command -v brew >/dev/null 2>&1; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if ! command -v brew >/dev/null 2>&1; then
  cat <<'EOF'
This will download and install Homebrew, then install the full Brewfile.
The Brewfile includes large casks (mactex, GUI apps) and can take a while.
EOF
  read -r -p "Continue? [y/N] " reply
  case "$reply" in
    [yY]|[yY][eE][sS]) ;;
    *) printf 'aborted\n'; exit 1 ;;
  esac

  if ! xcode-select -p >/dev/null 2>&1; then
    printf 'Command Line Tools are required. Run: xcode-select --install\n' >&2
    printf 'Re-run bootstrap.sh after the installer finishes.\n' >&2
    exit 1
  fi

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

"${REPO_DIR}/install.sh" "$@"
printf '\nNext: open a new terminal, then run: gh auth login -w\n'
