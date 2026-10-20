#!/usr/bin/env bash
# Idempotent dotfiles installer (Stow-style, no GNU Stow dependency).
#
# Usage:
#   ./install.sh [--dry-run] [--check] [--prune] [--help]
#
# Behaviour:
#   - Links every file under zsh/, git/, tmux/, opencode/, agents/, codex/, ghostty/
#     into $HOME, stripping the first path component
#     (e.g. zsh/.zshrc -> ~/.zshrc).
#   - Backs up pre-existing non-symlink targets to ~/.dotfiles.backup.<timestamp>/.
#   - Skips symlinks that already point at the correct source.
#   - Runs `brew bundle` on macOS only when the Brewfile is unsatisfied.
#   - `--prune` is standalone: it only removes dangling links.
#   - Clones oh-my-zsh + powerlevel10k theme only when missing
#     (the .zshrc expects both; zsh-autosuggestions comes via Brewfile).
#   - Clones vityasyyy/nvim-config into ~/.config/nvim only when missing.
#   - Respects DOTFILES_DIR and HOME env overrides (used by CI).

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
TARGET_HOME="${HOME}"
DRY_RUN=0
CHECK=0
PRUNE=0
CHANGES=0
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${TARGET_HOME}/.dotfiles.backup.${TIMESTAMP}"

PACKAGES=(zsh git tmux opencode agents codex ghostty)
PRUNE_ROOTS=(
  "${TARGET_HOME}/.config/opencode"
  "${TARGET_HOME}/.agents"
  "${TARGET_HOME}/.codex"
  "${TARGET_HOME}/.local/bin"
  "${TARGET_HOME}/Library/Application Support/com.mitchellh.ghostty"
)
OHMYZSH_REPO="https://github.com/ohmyzsh/ohmyzsh.git"
OHMYZSH_DIR="${TARGET_HOME}/.oh-my-zsh"
P10K_REPO="https://github.com/romkatv/powerlevel10k.git"
P10K_DIR="${OHMYZSH_DIR}/custom/themes/powerlevel10k"
NVIM_REPO="https://github.com/vityasyyy/nvim-config.git"
NVIM_DIR="${TARGET_HOME}/.config/nvim"

log() {
  printf '%s\n' "$*"
}

dry_prefix() {
  if [ "${DRY_RUN}" -eq 1 ]; then
    printf '[dry-run] '
  fi
}

usage() {
  cat <<'EOF'
Usage: install.sh [--dry-run] [--check] [--prune] [--help]

  --dry-run   Print what would change without modifying anything.
  --check     Report what would change; exit 1 if the profile is not up to date.
  --prune     Remove dangling symlinks only; do not link, clone, or run brew.
  --help      Show this help.
EOF
}

link_one() {
  local src="$1"
  local dst="$2"
  local dst_dir
  dst_dir="$(dirname "${dst}")"

  # Already correct -> skip (idempotent).
  if [ -L "${dst}" ] && [ "$(readlink "${dst}")" = "${src}" ]; then
    log "$(dry_prefix)skip (already linked): ${dst} -> ${src}"
    return 0
  fi

  # Existing file/dir/symlink pointing elsewhere -> back up.
  if [ -e "${dst}" ] || [ -L "${dst}" ]; then
    CHANGES=1
    if [ "${DRY_RUN}" -eq 1 ]; then
      log "[dry-run] backup: ${dst} -> ${BACKUP_DIR}/"
    else
      mkdir -p "${BACKUP_DIR}"
      chmod 700 "${BACKUP_DIR}"
      # Preserve basename collisions with a counter.
      local base backup_dst n
      base="$(basename "${dst}")"
      backup_dst="${BACKUP_DIR}/${base}"
      n=1
      while [ -e "${backup_dst}" ] || [ -L "${backup_dst}" ]; do
        n=$((n + 1))
        backup_dst="${BACKUP_DIR}/${base}.${n}"
      done
      mv "${dst}" "${backup_dst}"
      log "backup: ${dst} -> ${backup_dst}"
    fi
  fi

  if [ "${DRY_RUN}" -eq 1 ]; then
    CHANGES=1
    log "[dry-run] link: ${dst} -> ${src}"
    return 0
  fi

  CHANGES=1
  mkdir -p "${dst_dir}"
  ln -s "${src}" "${dst}"
  log "link: ${dst} -> ${src}"
}

link_packages() {
  local pkg pkg_dir src rel dst f
  for pkg in "${PACKAGES[@]}"; do
    pkg_dir="${DOTFILES_DIR}/${pkg}"
    [ -d "${pkg_dir}" ] || continue
    while IFS= read -r -d '' f; do
      src="${f}"
      # Strip "<dotfiles>/<pkg>/" prefix -> path relative to $HOME.
      rel="${f#"${pkg_dir}/"}"
      dst="${TARGET_HOME}/${rel}"
      link_one "${src}" "${dst}"
    done < <(find "${pkg_dir}" -type f -print0)
  done
}

prune_links() {
  local root link target pkg pkg_dir f rel dst

  for root in "${PRUNE_ROOTS[@]}"; do
    [ -d "${root}" ] || continue
    while IFS= read -r -d '' link; do
      target="$(readlink "${link}")"
      case "${target}" in
        "${DOTFILES_DIR}"/*) ;;
        *) continue ;;
      esac
      if [ ! -e "${link}" ]; then
        CHANGES=1
        if [ "${DRY_RUN}" -eq 1 ]; then
          log "[dry-run] prune: ${link} -> ${target}"
        else
          rm -f "${link}"
          log "prune: ${link} -> ${target}"
        fi
      fi
    done < <(find "${root}" -type l -print0)
  done

  for pkg in "${PACKAGES[@]}"; do
    pkg_dir="${DOTFILES_DIR}/${pkg}"
    [ -d "${pkg_dir}" ] || continue
    while IFS= read -r -d '' f; do
      rel="${f#"${pkg_dir}/"}"
      case "${rel}" in */*) continue ;; esac
      dst="${TARGET_HOME}/${rel}"
      [ -L "${dst}" ] || continue
      target="$(readlink "${dst}")"
      case "${target}" in
        "${DOTFILES_DIR}"/*) ;;
        *) continue ;;
      esac
      if [ ! -e "${dst}" ]; then
        CHANGES=1
        if [ "${DRY_RUN}" -eq 1 ]; then
          log "[dry-run] prune: ${dst} -> ${target}"
        else
          rm -f "${dst}"
          log "prune: ${dst} -> ${target}"
        fi
      fi
    done < <(find "${pkg_dir}" -maxdepth 1 -type f -print0)
  done
}

maybe_brew_bundle() {
  if [ "${DOTFILES_SKIP_BREW:-0}" = "1" ]; then
    log "skip: brew bundle (DOTFILES_SKIP_BREW=1)"
    return 0
  fi
  if [ "$(uname -s)" != "Darwin" ]; then
    log "skip: brew bundle (not macOS)"
    return 0
  fi
  if ! command -v brew >/dev/null 2>&1; then
    log "skip: brew not found (run ./bootstrap.sh on a blank Mac)"
    if [ "${CHECK}" -eq 1 ]; then
      CHANGES=1
    fi
    return 0
  fi

  if [ "${CHECK}" -eq 1 ]; then
    if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --file="${DOTFILES_DIR}/Brewfile" >/dev/null 2>&1; then
      log "ok: brew bundle is satisfied"
    else
      log "brew bundle: unsatisfied"
      CHANGES=1
    fi
    return 0
  fi

  if [ "${DRY_RUN}" -eq 1 ]; then
    log "[dry-run] run: brew bundle --file=${DOTFILES_DIR}/Brewfile"
    CHANGES=1
    return 0
  fi

  if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --file="${DOTFILES_DIR}/Brewfile" >/dev/null 2>&1; then
    log "ok: brew bundle is satisfied"
    return 0
  fi

  log "run: brew bundle --file=${DOTFILES_DIR}/Brewfile"
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file="${DOTFILES_DIR}/Brewfile"
}

maybe_check_brew_share() {
  local script="${DOTFILES_DIR}/scripts/brew-share.sh"
  [ -x "${script}" ] || return 0
  "${script}" --check || true
}

maybe_install_ohmyzsh() {
  if [ "${DOTFILES_SKIP_OHMYZSH:-0}" = "1" ]; then
    log "skip: oh-my-zsh clone (DOTFILES_SKIP_OHMYZSH=1)"
    return 0
  fi
  if [ -d "${OHMYZSH_DIR}" ]; then
    log "skip: ${OHMYZSH_DIR} already exists"
    return 0
  fi
  if [ "${CHECK}" -eq 1 ]; then
    log "missing: ${OHMYZSH_DIR} (would clone)"
    CHANGES=1
    return 0
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    log "[dry-run] run: git clone --depth=1 ${OHMYZSH_REPO} ${OHMYZSH_DIR}"
    return 0
  fi
  log "run: git clone --depth=1 ${OHMYZSH_REPO} ${OHMYZSH_DIR}"
  git clone --depth=1 "${OHMYZSH_REPO}" "${OHMYZSH_DIR}"
}

maybe_install_p10k() {
  if [ "${DOTFILES_SKIP_P10K:-0}" = "1" ]; then
    log "skip: powerlevel10k clone (DOTFILES_SKIP_P10K=1)"
    return 0
  fi
  if [ -d "${P10K_DIR}" ]; then
    log "skip: ${P10K_DIR} already exists"
    return 0
  fi
  if [ "${CHECK}" -eq 1 ]; then
    log "missing: ${P10K_DIR} (would clone)"
    CHANGES=1
    return 0
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    log "[dry-run] run: git clone --depth=1 ${P10K_REPO} ${P10K_DIR}"
    return 0
  fi
  log "run: git clone --depth=1 ${P10K_REPO} ${P10K_DIR}"
  mkdir -p "$(dirname "${P10K_DIR}")"
  git clone --depth=1 "${P10K_REPO}" "${P10K_DIR}"
}

maybe_clone_nvim() {
  if [ "${DOTFILES_SKIP_NVIM:-0}" = "1" ]; then
    log "skip: nvim clone (DOTFILES_SKIP_NVIM=1)"
    return 0
  fi
  if [ -d "${NVIM_DIR}" ]; then
    log "skip: ${NVIM_DIR} already exists"
    return 0
  fi
  if [ "${CHECK}" -eq 1 ]; then
    log "missing: ${NVIM_DIR} (would clone)"
    CHANGES=1
    return 0
  fi
  if [ "${DRY_RUN}" -eq 1 ]; then
    log "[dry-run] run: git clone ${NVIM_REPO} ${NVIM_DIR}"
    return 0
  fi
  log "run: git clone ${NVIM_REPO} ${NVIM_DIR}"
  mkdir -p "$(dirname "${NVIM_DIR}")"
  git clone "${NVIM_REPO}" "${NVIM_DIR}"
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run)
        DRY_RUN=1
        shift
        ;;
      --check)
        CHECK=1
        DRY_RUN=1
        shift
        ;;
      --prune)
        PRUNE=1
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        printf 'unknown argument: %s\n' "$1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  log "dotfiles: ${DOTFILES_DIR}"
  log "home: ${TARGET_HOME}"
  if [ "${CHECK}" -eq 1 ]; then
    log "mode: check (no changes)"
  elif [ "${DRY_RUN}" -eq 1 ]; then
    log "mode: dry-run (no changes)"
  fi

  if [ "${PRUNE}" -eq 1 ]; then
    prune_links
    if [ "${CHECK}" -eq 1 ] && [ "${CHANGES}" -ne 0 ]; then
      log "check: profile is not up to date"
      exit 1
    fi
    log "done."
    return 0
  fi

  link_packages
  maybe_install_ohmyzsh
  maybe_install_p10k
  maybe_clone_nvim
  maybe_brew_bundle
  maybe_check_brew_share

  if [ "${CHECK}" -eq 1 ] && [ "${CHANGES}" -ne 0 ]; then
    log "check: profile is not up to date"
    exit 1
  fi

  log "done."
}

main "$@"
