---
name: git-pr-workflow
description: Git and pull-request discipline for AI coding agents. Enforces clean diffs, Conventional Commits, safe branch handling, descriptive PRs, and waiting for required CI checks before completion.
metadata:
  audience: ai-coding-agent
  workflow: git
---

# Git and PR Workflow

## Branch Safety

Before changing files:

- inspect current branch;
- inspect working tree;
- inspect existing uncommitted changes;
- never overwrite unrelated user work.

Do not reset, checkout, clean, stash, or otherwise destroy user changes unless explicitly authorized.

Prefer creating a feature/fix branch when the repository workflow requires it.

## Diff Discipline

A commit must contain only related changes.

Before commit:

- inspect `git status`;
- inspect staged diff;
- inspect unstaged diff;
- remove accidental changes;
- verify generated files are intentional;
- verify no secrets are included.

Never commit:
- `.env` secrets;
- private keys;
- credentials;
- tokens;
- unrelated local files.

## Conventional Commits

Use:

`type(scope): description`

Allowed common types:

- `feat`
- `fix`
- `refactor`
- `test`
- `docs`
- `perf`
- `build`
- `ci`
- `chore`
- `revert`

Examples:

`feat(auth): add refresh token rotation`

`fix(worker): prevent duplicate job execution`

`refactor(db): isolate transaction boundary`

Scope should identify the domain/package/subsystem.

Always include a body — the subject alone is ambiguous. State what changed,
why, and any user-visible or behavioral consequence. Never commit a subject-only
message; amend before pushing.

## Commit Strategy

Prefer coherent commits.

Do not create dozens of meaningless commits.

Do not amend/rewrite history that the user may already have pushed unless explicitly requested.

## Pull Requests

PR title should follow the project's convention; otherwise use a concise Conventional Commit-style title.

PR body:

### Summary
What changed.

### Why
Problem and motivation.

### Implementation
Important technical decisions.

### Testing
Exact checks/tests performed.

### Risks
Known risks and tradeoffs.

### Rollback
How to revert or recover, especially for migrations/infrastructure.

### Notes
Operational/configuration/deployment considerations.

## CI

After PR creation:

- wait for required checks;
- inspect failures rather than guessing;
- reproduce locally when practical;
- fix failures;
- rerun local verification;
- push;
- wait again.

A PR with red required CI is not complete.

Never weaken or bypass tests merely to make CI green.

## Merge

Merge only when the user's current request or standing repository-specific workflow authorizes it. In `invenio-rdm-gitops`, once the full diff has been reviewed and required CI is green, the standing workflow authorizes squash-merging and deleting the branch without asking for per-PR approval. Never merge directly to `main` and never force-push. If merge fails, fix forward or report the blocker.

For changes consumed by deployment or infrastructure pipelines in `invenio-rdm-gitops`, verify the required post-merge production and infrastructure pipelines before reporting completion. A green PR check alone is not completion for those changes.

For other repositories, follow their own merge policy and the user's explicit authorization.
