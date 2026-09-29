# dotfiles

Public, secrets-free macOS dev configs. Stow-style layout: each top-level folder
mirrors `$HOME`, so `zsh/.zshrc` installs to `~/.zshrc`.

## Layout

| Repo path | Installs to |
| --- | --- |
| `zsh/.zshrc`, `zsh/.p10k.zsh`, `zsh/.bashrc`, `zsh/.profile` | `~/.zshrc`, `~/.p10k.zsh`, `~/.bashrc`, `~/.profile` |
| `git/.gitconfig` | `~/.gitconfig` |
| `tmux/.tmux.conf` | `~/.tmux.conf` |
| `opencode/.config/opencode/opencode.json` | `~/.config/opencode/opencode.json` |
| `opencode/.config/opencode/AGENTS.md` | `~/.config/opencode/AGENTS.md` |
| `opencode/.config/opencode/skills/**` | `~/.config/opencode/skills/**` |
| `opencode/.config/opencode/agents/**` | `~/.config/opencode/agents/**` |
| `opencode/.config/opencode/plugins/**` | `~/.config/opencode/plugins/**` |
| `agents/.agents/skills/**` | `~/.agents/skills/**` |
| `ghostty/Library/Application Support/com.mitchellh.ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` |

Meta files (not linked): `README.md`, `Brewfile`, `install.sh`, `docs/`,
`.github/`, `.gitignore`.

Explicitly OUT: `~/.claude`, `~/.codex`, `~/.vimrc`, `~/.vim_runtime`,
`~/.config/nvim` contents, and any secrets (see below).

## Install

```sh
git clone https://github.com/vityasyyy/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run   # preview
./install.sh             # link + brew bundle (macOS) + oh-my-zsh/p10k/nvim if missing
```

Idempotent: re-running skips already-correct symlinks and existing clones.
Pre-existing files are moved to `~/.dotfiles.backup.<timestamp>/` before linking.

What `install.sh` sets up (so a fresh macOS profile just works):
- symlinks for shell (`~/.zshrc`, `~/.p10k.zsh`), git, tmux, opencode, agents, ghostty
- `brew bundle` on macOS (`zsh-autosuggestions` lives here)
- `~/.oh-my-zsh` + `powerlevel10k` theme (expected by `.zshrc`, shallow-cloned)
- `~/.config/nvim` (cloned only when missing; existing installs never touched)

Skip knobs: `DOTFILES_SKIP_BREW=1`, `DOTFILES_SKIP_OHMYZSH=1`,
`DOTFILES_SKIP_P10K=1`, `DOTFILES_SKIP_NVIM=1`.

Not carried over (re-auth per profile): `~/.ssh/`, `gh auth login`,
`gcloud auth login`, opencode/Antigravity login, sops age key, `~/.kube/`.

`DOTFILES_DIR` and `HOME` env overrides are respected (CI uses a temp `HOME`).

## Neovim (not vendored)

`install.sh` clones only when missing:

```sh
git clone https://github.com/vityasyyy/nvim-config.git ~/.config/nvim
```

Your existing `~/.config/nvim` is never touched.

## Brew

```sh
brew bundle --file=Brewfile          # install
brew bundle check --file=Brewfile    # verify
```

Curated from `brew list --installed-on-request`; transitive libs and Mac App
Store blobs dropped. `install.sh` runs this automatically on macOS only.

## Secrets policy

Never committed, never printed:

- `~/.git-credentials`, `~/.config/gh/hosts.yml`
- `~/.config/opencode/antigravity-accounts.json`, `~/.config/opencode/.figma-token`
- `~/.config/sops/age/keys.txt`, `~/.ssh/`, `~/.kube/`, `~/.docker/`
- `node_modules/`, `.DS_Store`

Covered by `.gitignore` + CI `gitleaks detect`. If unsure whether a file holds
a secret, exclude it and record the question in `WORKER-REPORT.md`.

## Sanitization applied

- `zsh/.zshrc`: `KUBECONFIG="$HOME/Downloads/…"` replaced with a commented
  placeholder defaulting to `$HOME/.kube/config`. Aliases, oh-my-zsh, p10k,
  pyenv, bun, pnpm kept.
- `git/.gitconfig`: `[user]` name/email kept; `[credential] helper` changed
  from `store` to `osxkeychain`.

## CI

`.github/workflows/ci.yml`: shellcheck, gitleaks, symlink-integrity
(dry-run + temp-HOME install + `readlink` verification), Brewfile parse
(`ruby -c` + `brew bundle check` on macOS). Target < ~2 min.
