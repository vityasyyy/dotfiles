# dotfiles

Public, secrets-free macOS dev configs for a **two-profile Mac**: one
source of truth, two independent homes, synced by git — never by file
writes across profiles.

> A fresh profile (or fresh Mac) goes from blank to full environment with
> `clone` + `./install.sh`. Everything under `~/dotfiles` is the truth;
> every dotfile in `$HOME` is a symlink into it.

---

## 1. The big picture

```
             ┌────────────── SOURCE OF TRUTH ───────────────┐
             │  github.com/vityasyyy/dotfiles               │
             │  shell · git · tmux · ghostty · opencode ·   │
             │  agents · install.sh · Brewfile · CI         │
             └───────┬──────────────────────────────┬───────┘
       git pull/push │                              │ git pull/push
                     ▼                              ▼
      /Users/miapalovaara/dotfiles      /Users/muhammad.vityasy/dotfiles
        (profile A, brew owner)           (profile B, daily ops)
             │ symlinks                       │ symlinks
             ▼                                ▼
      its $HOME dotfiles                its $HOME dotfiles
      (~/.zshrc → clone copy)           (~/.zshrc → clone copy)
```

One clone per profile, symlinks pointing **inward** to it. Sync ritual:

```
edit anywhere → git add/commit/push → git pull + ./install.sh in both
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
| **Config** | `.zshrc`, `.gitconfig`, `.tmux.conf`, ghostty, opencode, agents, Brewfile | Yes — repo + symlinks (the whole point) |
| **Per-profile state** | shell history, tool caches, `~/.oh-my-zsh`, `~/.config/nvim` clones | No — installed per profile by `install.sh`, never shared |
| **Secrets / auth** | `~/.ssh`, gh/gcloud/claude/opencode tokens, `~/.kube`, sops age key | **Never** — gitignored, CI-scanned; re-auth per profile by design |

---

## 3. Homebrew shared by two profiles

One install of brew lives at `/opt/homebrew`. It was installed by profile
A, so everything under it is owned by A. Sharing it with profile B is an
explicit model, not a default:

```
/opt/homebrew                       owner: miapalovaara   group: admin
├── Cellar/… · bin/… (kegs)         chgrp admin + chmod g+rwX  ← both profiles install
├── var/homebrew/locks/…            write-gate per install/upgrade
├── Library/Taps/<x>/<tap>  × 3     git repos ← git needs safe.directory opt-in
└── (prefix itself is a git repo)
```

| Piece | Rule | Why |
| --- | --- | --- |
| Admin group | both profiles are members | group-write rights come from membership |
| `chmod -R g+rwX /opt/homebrew` | sudo, run once | lets the non-owner install/upgrade |
| `git config safe.directory` ×4 | in the shared `.gitconfig` | git rejects *group-writable* repos owned by another uid — explicit trust is the designed escape |
| `brew trust <tap>` | per-profile | brew 7 refuses untrusted taps for outdated-checks |
| Homebrew API cache | per-profile (`~/Library/Caches/Homebrew`) | never shared; fresh profiles download once |

If a permission error ever comes back from the non-owner side (a file
created owner-only by some upgrade), re-run:

```sh
sudo chgrp -R admin /opt/homebrew && sudo chmod -R g+rwX /opt/homebrew
```

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

Copy a URL out of ssh: select it, `C-Space`, `v`, `y` (see §6) — it lands
on the local pasteboard.

Optional one-time copies for "exact" reproduction (not synced by design,
fine on the same physical Mac):

```sh
cp -Rp /Users/miapalovaara/.ssh ~/.ssh   # then own it: chown -R (in B)
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

### New profile (blank macOS account)

```sh
git clone https://github.com/vityasyyy/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh          # links + brew bundle + oh-my-zsh/p10k/nvim
gh auth login -w && gcloud auth login --no-launch-browser   # per-profile, once
brew trust hashicorp/tap && brew trust anomalyco/tap        # per-profile, once
```

### Weekly / any-change ritual

```sh
git -C ~/dotfiles pull && ~/dotfiles/install.sh
# + tmux reload (C-Space r) if .tmux.conf changed; new Ghostty window if it changed
```

### Verify a profile is fully healthy

```sh
./install.sh                            # all lines say "skip (already linked)"
brew bundle check --file=Brewfile       # Satisfied
gh auth status && gcloud auth list
ls -la ~/.zshrc ~/.tmux.conf ~/.gitconfig    # → symlinks into ~/dotfiles
```

Skip knobs: `DOTFILES_SKIP_BREW=1`, `DOTFILES_SKIP_OHMYZSH=1`,
`DOTFILES_SKIP_P10K=1`, `DOTFILES_SKIP_NVIM=1`.

---

## 7. Incident log (what bit us, and the exact fix)

| Symptom | Root cause | Fix |
| --- | --- | --- |
| `Permission denied @ rb_sysopen …/locks/X.formula.lock` from non-owner profile | brew prefix files owned by profile A, no group write | `sudo chgrp -R admin /opt/homebrew && sudo chmod -R g+rwX /opt/homebrew` |
| `fatal: detected dubious ownership in repository` after that chmod | git refuses group-writable repos owned by another uid | `safe.directory` entries in shared `.gitconfig` (§3) — no more fixes needed |
| `Refusing to load formula <tap> from untrusted tap` | brew 7 per-profile tap trust | `brew trust <tap>` (per profile, no sudo) |
| `Could not symlink bin/minikube — target already exists` | hand-copied binary occupied `bin/`; brew keg unlinked | `brew link --overwrite minikube` |
| Ghostty theme/settings not applying | stray plain file `config.ghostty` (wrong name) instead of symlinked `config` | re-run `./install.sh`; never hand-edit the Application Support copy |
| Outer tmux prefix suddenly C-a with blue bar | config reloaded from an ssh pane | reload from a local pane; double-press still works meanwhile |

---

## 8. Reference

### Layout (stow-style: folder mirrors `$HOME`)

| Repo path | Installs to |
| --- | --- |
| `zsh/.zshrc`, `.p10k.zsh`, `.bashrc`, `.profile` | `~/…` |
| `git/.gitconfig`, `git/.config/git/config-work` | `~/.gitconfig`, `~/.config/git/config-work` (work identity auto-includes for `~/work/`, `~/xendit/`) |
| `tmux/.tmux.conf` | `~/.tmux.conf` |
| `opencode/.config/opencode/**` | `~/.config/opencode/**` (config, agents, skills, plugins) |
| `agents/.agents/skills/**` | `~/.agents/skills/**` |
| `ghostty/Library/…/com.mitchellh.ghostty/config` | `~/Library/Application Support/com.mitchellh.ghostty/config` |

Meta files (not linked): `README.md`, `Brewfile`, `install.sh`, `docs/`,
`.github/`, `.gitignore`.

### install.sh

Idempotent Stow-style linker (no GNU Stow). Backs up pre-existing
non-symlink targets to `~/.dotfiles.backup.<timestamp>/`; runs
`brew bundle` on macOS; clones oh-my-zsh / powerlevel10k / nvim only when
missing; respects `DOTFILES_DIR` and `HOME` overrides (CI uses a temp
`HOME`).

### Neovim (not vendored)

```sh
git clone https://github.com/vityasyyy/nvim-config.git ~/.config/nvim
```

### Brew

```sh
brew bundle --file=Brewfile          # install
brew bundle check --file=Brewfile    # verify
brew outdated && brew upgrade        # shared Cellar — one run serves both profiles
```

### Secrets policy

Never committed, never printed:
`~/.git-credentials`, `~/.config/gh/hosts.yml`,
`~/.config/opencode/antigravity-accounts.json`,
`~/.config/opencode/.figma-token`, `~/.config/sops/age/keys.txt`,
`~/.ssh/`, `~/.kube/`, `~/.docker/`, `node_modules/`, `.DS_Store`.
Covered by `.gitignore` + CI `gitleaks detect`. If unsure whether a file
holds a secret, exclude it and record the question in `WORKER-REPORT.md`.

### CI

`.github/workflows/ci.yml`: shellcheck, gitleaks, symlink-integrity
(dry-run + temp-HOME install + `readlink` verification), Brewfile parse.
Target < ~2 min.

### Sanitization applied

- `zsh/.zshrc`: `KUBECONFIG` placeholder instead of a Downloads path.
- `git/.gitconfig`: `[user]` kept; credential helper `osxkeychain`.
