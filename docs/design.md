# Design

One-page summary of the dotfiles repo.

## 1. Layout (Stow-style, mirrors `$HOME`)

Top-level dirs are install packages; the remainder of each repo path is the
`$HOME`-relative target:

- `zsh/` → `~/.zshrc`, `~/.p10k.zsh`, `~/.bashrc`, `~/.profile`
- `git/` → `~/.gitconfig`
- `tmux/` → `~/.tmux.conf`
- `opencode/.config/opencode/` → `~/.config/opencode/` (`opencode.json`,
  `AGENTS.md`, `skills/`, `agents/`, `plugins/`)
- `agents/.agents/` → `~/.agents/` (`skills/`)

Meta (never linked): `README.md`, `Brewfile`, `install.sh`, `docs/`,
`.github/`, `.gitignore`. Discovery is `find <pkg> -type f`; the link target
is `$HOME/<path-minus-pkg-prefix>`. No GNU Stow dependency.

OUT by design: `~/.claude`, `~/.codex`, `~/.vimrc`, `~/.vim_runtime`,
`~/.config/nvim` contents (cloned, not vendored), and all secrets.

## 2. Sanitization

- `zsh/.zshrc`: machine-specific
  `export KUBECONFIG="$HOME/Downloads/btd-rke2.yaml"` → commented placeholder
  `# export KUBECONFIG="$HOME/.kube/config"`. Everything else kept
  (aliases, oh-my-zsh, p10k source, pyenv, bun, pnpm, SOPS_AGE_KEY_FILE path).
- `git/.gitconfig`: `[user]` kept; `[credential] helper = store` →
  `osxkeychain` (store writes plaintext `~/.git-credentials`).
- Everything else byte-identical to source at import time.
- `.gitignore` blocks secret paths (`.git-credentials`, `gh/hosts.yml`,
  `antigravity-accounts.json`, `.figma-token`, `sops/age/keys.txt`, `.ssh/`,
  `.kube/`, `.docker/`, `node_modules/`, `.DS_Store`) plus generic key/env
  patterns as defense in depth.

## 3. Bootstrap flow (`install.sh`)

1. Parse `--dry-run`/`--help`. Resolve `DOTFILES_DIR` (script dir) and
   `HOME`. Timestamped `BACKUP_DIR=~/.dotfiles.backup.<ts>` created lazily.
2. For each file under `PACKAGES=(zsh git tmux opencode agents)`:
   - If `$dst` is a symlink to `$src` → skip (idempotent).
   - Else if `$dst` exists (file/dir/wrong symlink) → `mv` to backup dir,
     then `mkdir -p $(dirname $dst)` + `ln -s $src $dst`.
   - `--dry-run` prints `backup:`/`link:`/`skip:` lines, changes nothing.
3. `brew bundle --file=Brewfile` only when `uname -s == Darwin` and `brew`
   exists (skipped otherwise, incl. CI Linux).
4. `git clone https://github.com/vityasyyy/nvim-config.git ~/.config/nvim`
   only when `~/.config/nvim` is absent; existing checkout untouched.
5. `set -euo pipefail`, quoted vars, `shellcheck`-clean.

## 4. CI (`.github/workflows/ci.yml`, < ~2 min)

- `shellcheck install.sh` (fail on warnings).
- `gitleaks detect --source . --no-git -v` (secrets gate).
- Symlink-integrity: `./install.sh --dry-run` must exit 0 and list every
  tracked config file; then install into a temp `HOME` and assert each
  `readlink $HOME/<rel>` equals the repo source.
- Brewfile parse: `ruby --check Brewfile` on Linux + `brew bundle check`
  on macOS (casks are macOS-only, so the brew job runs on `macos-latest`).
