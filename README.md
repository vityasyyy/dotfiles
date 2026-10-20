# dotfiles

Public, secrets-free macOS dev configs for a **multi-profile Mac**: one
source of truth, many independent homes, synced by git — never by file
writes across profiles.

> A new profile on a Mac that already has Homebrew goes from blank to full
> environment with `clone` + `./install.sh`. A truly blank Mac uses
> `clone` + `./bootstrap.sh`, which installs Homebrew first.
> Everything under `~/dotfiles` is the truth; every dotfile in `$HOME` is a
> symlink into it.

---

## 1. The big picture

```
             ┌────────────── SOURCE OF TRUTH ───────────────┐
             │  github.com/<you>/dotfiles                   │
             │  shell · git · tmux · ghostty · opencode ·   │
             │  codex · shared skills · install.sh · CI     │
             └───────┬──────────────────────────────┬───────┘
       git pull/push │                              │ git pull/push
                     ▼                              ▼
      /Users/<profile-a>/dotfiles     /Users/<profile-n>/dotfiles
        (may own brew)                  (shared or own brew)
             │ symlinks                       │ symlinks
             ▼                                ▼
      its $HOME dotfiles                its $HOME dotfiles
      (~/.zshrc → clone copy)           (~/.zshrc → clone copy)
```

*Roles, not identities:* Profile A is the account that installed Homebrew
first, if any; every other profile either shares that prefix (with the
ACL) or uses its own. Swap in your own usernames — that is the only
personalization the sharing model needs. Add as many profiles as you need.

One clone per profile, symlinks pointing **inward** to it. Sync ritual:

```
edit anywhere → git add/commit/push → git pull + ./install.sh in every profile
```

Profiles cannot write into each other's `$HOME` (filesystem boundary +
macOS ACL) — git *is* the bridge. Conflicts surface as git conflicts
before anything live is touched.

---

## 2. The three buckets

Everything in this setup is one of three things. "Why didn't X carry
over?" is always answered by the row it lands in.

| Bucket | What | Synced? |
| --- | --- | --- |
| **Config** | `.zshrc`, `.gitconfig`, `.tmux.conf`, Ghostty, OpenCode, Codex instructions, shared agent skills, Brewfile | Yes — repo + symlinks (the whole point) |
| **Per-profile state** | shell history, tool caches, `~/.oh-my-zsh`, `~/.config/nvim` clones | No — installed per profile by `install.sh`, never shared |
| **Secrets / auth** | `~/.ssh`, gh/gcloud/OpenCode/Codex tokens, `~/.kube`, sops age key | **Never** — gitignored, CI-scanned; re-auth per profile by design |

---

## 3. Homebrew across profiles and laptops

The repo does not assume a particular brew owner. Each machine detects its
own layout:

| Layout | What happens |
| --- | --- |
| Single user owns `/opt/homebrew` | `scripts/brew-share.sh --check` reports single-user mode; no ACL needed. |
| Shared Mac, multiple admins | Run `scripts/brew-share.sh --apply` once. It backfills group write and adds an inheriting ACL for group `admin`. |
| New laptop | Clone, run `./bootstrap.sh` if brew is missing, then `./install.sh`. Auth and secrets are recreated per machine. |

The ACL is what makes the shared prefix durable: new kegs and lock files
inherit group write, so one profile's install does not break the other.
`install.sh` only warns when the prefix is shared and not writable; it never
runs `sudo`.

If a permission error still appears:

```sh
~/dotfiles/scripts/brew-share.sh --check
~/dotfiles/scripts/brew-share.sh --apply
```

The `admin` group is macOS's administrator group. The ACL does not add
anyone to it; it only gives existing admins write access to the shared
prefix. If a profile should not be able to modify brew code, do not make it
an admin, or give it its own brew prefix.

---

## 4. Auth model

Tokens are **state**, not config — they live per profile and per machine.
Running the CLI in a profile is what puts auth *in* that profile; the
browser is just a UI step and can happen anywhere.

| Context | gh token lives in | gcloud token in | ssh keys |
| --- | --- | --- | --- |
| Profile A | its `~/.config/gh` + its Keychain | its `~/.config/gcloud` | its `~/.ssh` |
| Profile B | the other `~/.config/gh` + *that* Keychain | the other `~/.config/gcloud`, etc. | the other `~/.ssh` |
| A remote box over ssh | that box's `~/.config/gh` | that box's gcloud | that box's keys |

Every new context = one auth. Device flows (browser anywhere, tool code):

```sh
gh auth login -w                          # prints a code → https://github.com/login/device
gcloud auth login --no-launch-browser     # prints URL → paste auth code back
BROWSER=echo <other-tool> login           # forces URL-print for tools that insist on a browser
```

Copy a URL out of ssh: select it, `C-Space`, `v`, `y` (see §5) — it lands
on the local pasteboard.

Optional one-time copies for "exact" reproduction (not synced by design,
fine on the same physical Mac):

```sh
cp -Rp /Users/<profile-a>/.ssh ~/.ssh   # then take ownership: chown -R "$USER" ~/.ssh
# same for ~/.kube, sops age key — move via /Users/Shared
```

---

## 5. tmux & Ghostty user guide

```
Ghostty ── shell-integration zsh ── tmux (outer prefix C-Space)
              │
              └─ ssh → remote tmux (auto-detects nesting → prefix flips to C-a,
                                     status bar turns blue with "[ssh]" label)
```

| Key | Effect | Where |
| --- | --- | --- |
| `C-Space` | prefix: local tmux | always |
| `C-Space C-Space` | legacy double-press: forwards prefix to nested tmux | fallback, works everywhere |
| `C-a` | prefix: ssh-nested tmux | inside remote tmux (auto-switch via config) |
| `C-Space` inside nested | passes through — still controls the **outer** tmux | |
| `C-a C-a` | forwards `C-a` to the next-inner level | deep nesting |
| `C-Space r` | reload config | caveat: reload from a *local* pane — reloading from an ssh pane flips the outer prefix to C-a (blue bar makes it visible) |
| `C-Space [` → `v` → `y` | copy mode: select + copy-to-real-clipboard (OSC 52) | |
| `Shift + drag` | native selection bypassing tmux → copy-on-select | in tmux panes |
| `Cmd+V` | paste (works into ssh/tmux) | always |
| `Ctrl+click` on URL | opens in default browser | Ghostty |

Copy-from-ssh plumbing (why it works):

```
inner tmux y → OSC52 esc ──ssh──▶ outer tmux (set-clipboard on) ──▶ Ghostty
                              (allow-passthrough)               (clipboard-write)
                                                              → macOS pasteboard
```

Config locations that point into the repo: `~/.tmux.conf`,
`~/Library/Application Support/com.mitchellh.ghostty/config` (note: file
is called `config`, not `config.ghostty` — Ghostty only reads `config`).

---

## 6. Runbooks

### New profile on a Mac with Homebrew

```sh
git clone https://github.com/vityasyyy/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
gh auth login -w && gcloud auth login --no-launch-browser
```

### Blank Mac

```sh
git clone https://github.com/vityasyyy/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./bootstrap.sh
```

`bootstrap.sh` installs Homebrew after an explicit confirmation, then runs
`install.sh`. The full Brewfile includes large casks (`mactex`, GUI apps), so
the first run takes a while.

Brewfile trust is encoded with `trusted: true` on the two third-party
formulae; no per-profile `brew trust` step is needed unless you add a new tap
or formula.

This repository is the shared source of truth for every profile. Clone it once
per profile; after that, pull the latest changes and re-run the installer:

```sh
git -C ~/dotfiles pull --ff-only
~/dotfiles/install.sh
```

To publish a config change, commit and push it from one profile, then run
those two commands in each other profile. All clones use the same GitHub
repository, while authentication and runtime state stay local to each profile.

### Weekly / any-change ritual

```sh
git -C ~/dotfiles pull && ~/dotfiles/install.sh
# + tmux reload (C-Space r) if .tmux.conf changed; new Ghostty window if it changed
```

### Verify a profile is fully healthy

```sh
./install.sh --check                     # links + brew bundle + shared-brew state
brew bundle check --no-upgrade --file=Brewfile
gh auth status && gcloud auth list
ls -la ~/.zshrc ~/.tmux.conf ~/.gitconfig    # → symlinks into ~/dotfiles
```

`--check` exits 1 until the Brewfile is fully installed; run the migration
first on an existing machine.

Skip knobs: `DOTFILES_SKIP_BREW=1`, `DOTFILES_SKIP_OHMYZSH=1`,
`DOTFILES_SKIP_P10K=1`, `DOTFILES_SKIP_NVIM=1`.

### Make it yours (fork checklist)

| File | Personalize |
| --- | --- |
| `git/.gitconfig` | `[user]` name/email; `[includeIf]` paths if your work repos don't live in `~/work/` |
| `agents/.agents/skills/` | Shared workflow conventions and skills used by OpenCode and Codex |
| `codex/.codex/AGENTS.md` | Codex-specific routing into shared skills and Codex document tools |
| `opencode/.config/opencode/AGENTS.md` | OpenCode-specific provider, Herdr, and TUI instructions |
| `install.sh` (`NVIM_REPO`) | your own nvim-config fork, or skip cloning (`DOTFILES_SKIP_NVIM=1`) |
| `Brewfile` | add your own tools; keep `trusted: true` scoped to formulae you actually use |
| `scripts/brew-share.sh` | shared Mac: `--check` monthly, `--apply` only when it warns |
| git remote | `fork` first, then `git remote set-url origin <your-fork-url>` in each profile's clone |

---

## 7. Incident log (what bit us, and the exact fix)

| Symptom | Root cause | Fix |
| --- | --- | --- |
| `Permission denied @ rb_sysopen …/locks/X.formula.lock` from non-owner profile | brew prefix files owned by the owner, no group write | `scripts/brew-share.sh --check`, then `--apply` |
| `fatal: detected dubious ownership in repository` after that chmod | git refuses group-writable repos owned by another uid | the `.gitconfig` taps glob covers every tap; no per-tap edit |
| `Refusing to load formula <tap> from untrusted tap` | brew 7 formula trust | formula-level `trusted: true` in the Brewfile |
| `Could not symlink bin/minikube — target already exists` | hand-copied binary occupied `bin/`; brew keg unlinked | `brew link --overwrite minikube` |
| Ghostty theme/settings not applying | stray plain file `config.ghostty` (wrong name) instead of symlinked `config` | re-run `./install.sh`; never hand-edit the Application Support copy |
| Outer tmux prefix suddenly C-a with blue bar | config reloaded from an ssh pane | reload from a local pane; double-press still works meanwhile |

---

## 8. Reference

### Layout (stow-style: folder mirrors `$HOME`)

| Repo path | Installs to |
| --- | --- |
| `zsh/.zshrc`, `.p10k.zsh`, `.bashrc`, `.profile` | `~/…` |
| `git/.gitconfig`, `git/.config/git/config-work` | `~/.gitconfig`, `~/.config/git/config-work` (work identity auto-includes for the `[includeIf]` paths you define — e.g. an org subfolder under `$HOME`) |
| `tmux/.tmux.conf` | `~/.tmux.conf` |
| `opencode/.config/opencode/**` | `~/.config/opencode/**` (config, agents, OpenCode-only skills, plugins) |
| `agents/.agents/skills/**` | `~/.agents/skills/**` |
| `codex/.codex/AGENTS.md` | `~/.codex/AGENTS.md` (global Codex instructions only; auth/runtime state stays local) |
| `ghostty/Library/…/com.mitchellh.ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` |

Meta files (not linked): `README.md`, `Brewfile`, `install.sh`,
`bootstrap.sh`, `scripts/`, `docs/`, `.github/`, `.gitignore`.

### install.sh

Idempotent Stow-style linker (no GNU Stow). Backs up pre-existing
non-symlink targets to `~/.dotfiles.backup.<timestamp>/` with mode `700`;
clones oh-my-zsh / powerlevel10k / nvim before brew; runs `brew bundle`
only when `brew bundle check --no-upgrade` is unsatisfied; respects
`DOTFILES_DIR` and `HOME` overrides (CI uses a temp `HOME`).

`--check` is a read-only health check (exit 1 when the profile is not up to
date). `--prune` removes symlinks that point into the repo but whose target
was deleted. Backups are kept, not auto-deleted.

### Neovim (not vendored)

```sh
git clone https://github.com/<you>/nvim-config.git ~/.config/nvim
```

(`install.sh` clones whatever `NVIM_REPO` points at, only when
`~/.config/nvim` is missing — existing installs are never touched.)

### Brew

```sh
brew bundle --file=Brewfile                    # install
brew bundle check --no-upgrade --file=Brewfile # verify presence
brew update                                    # weekly, explicit
brew outdated && brew upgrade                  # shared Cellar — one run serves every profile
```

### Tool ownership

Brew owns every managed CLI and GUI tool. Auth and runtime state stay per
profile.

| Tool | Brew entry | Update path |
| --- | --- | --- |
| OpenCode V2 | `anomalyco/tap/opencode-v2` | `brew upgrade opencode-v2` |
| Codex | `cask "codex"` | `brew upgrade --cask codex` |
| Claude Code | `cask "claude-code"` | `brew upgrade --cask claude-code` |
| Herdr | `brew "herdr"` | `brew upgrade herdr` |
| Antigravity | `cask "antigravity"`, `cask "antigravity-cli"` | `brew upgrade --cask ...` |
| Ghostty | `cask "ghostty"` | `brew upgrade --cask ghostty` |

Do not use self-updaters (`opencode upgrade`, npm `codex`, manual `claude`
installers) on these tools; brew is the single owner.

### Portability across laptops

The repo carries config only. It never carries UIDs, ACL state, SSH keys,
gh/gcloud tokens, or sops keys. On a new Apple Silicon laptop:

1. Clone the repo.
2. Run `./bootstrap.sh` (blank Mac) or `./install.sh` (brew already present).
3. Re-auth per machine: `gh auth login -w`, `gcloud auth login --no-launch-browser`, SSH/sops keys as needed.
4. Run `scripts/brew-share.sh --check`; if the prefix is shared, `--apply`.

`safe.directory` uses `/opt/homebrew/Library/Taps/*`, so new taps do not need
a per-tap edit.

### Secrets policy

Never committed, never printed:
`~/.git-credentials`, `~/.config/gh/hosts.yml`,
`~/.config/opencode/antigravity-accounts.json`,
`~/.config/opencode/.figma-token`, `~/.config/sops/age/keys.txt`,
`~/.ssh/`, `~/.kube/`, `~/.docker/`, `node_modules/`, `.DS_Store`.
Covered by `.gitignore` + CI `gitleaks detect`. If unsure whether a file
holds a secret, exclude it and do not commit it.

### CI

`.github/workflows/ci.yml`: shellcheck and `bash -n` for `install.sh`,
`bootstrap.sh`, and `scripts/*.sh`; gitleaks; symlink-integrity including
`codex`; prune test; Brewfile entry resolution on macOS. External clones are
skipped in the temp-HOME job. Target < ~2 min.

### Sanitization applied

- `zsh/.zshrc`: `KUBECONFIG` placeholder instead of a Downloads path.
- `git/.gitconfig`: `[user]` kept; credential helper `osxkeychain`.
