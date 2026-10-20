# Design

The README is the single source of truth. Invariants:

- The repo carries config only: no secrets, UIDs, ACL state, or auth.
- `/opt/homebrew` may be single-user or shared; `scripts/brew-share.sh`
  detects and repairs the shared case.
- Each profile has its own `$HOME`, clone, oh-my-zsh, nvim, caches, and auth.
- Brew owns every managed CLI/GUI tool; `Brewfile` is the tool spec.
