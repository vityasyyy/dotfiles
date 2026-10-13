# Global operator preferences

Owner: vityasyyy. Standing instructions from 2026-09-15 — these override any
skill or convention that says otherwise. Reconfirm if they ever look unsafe.

## Large downloads (2026-10-10 — standing)

Local network here downloads slowly. When a step requires downloading or
installing anything (tool installs, updates, release binaries), ask the user
and END the chat first so they can run the download on their machine; resume
the task only after they confirm the file is in place.

## Shared workflow skills

Portable engineering and document conventions live in `~/.agents/skills/`
and are shared with Codex. Load the relevant skill for the task. In
particular, use `confluence-authoring` for Confluence work and
`git-pr-workflow` for branch and PR work. OpenCode-specific providers,
roles, and Herdr orchestration remain in this configuration.

## Worker approvals (herd)

Auto-clear routine sandbox prompts on the operator's behalf: external-directory
access under `/tmp`, `~/.local/bin`, and worktrees, plus the planned tool
installs/downloads in the approved brief (promtool, amtool, crane, helm pulls,
pinned-image pulls).

Still escalate to the user first: secrets/credentials, destructive or
out-of-scope actions, anything affecting the cluster, and ambiguous decisions.

## Code hygiene (2026-10-08 — standing, do not re-ask)

- NEVER let plan artifacts leak into code: no "based on step N", "per phase
  N", "task N", or checkpoint/stage references in code comments, JSDoc,
  docstrings, or commit messages — code documents itself in the codebase's
  own terms. Plan structure belongs in the plan doc / PR description only.
- Invoke `ponytail` before ANY coding task (writing, fixing, refactoring,
  reviewing code, choosing dependencies) — lead and workers alike. It runs
  alongside the mapped process skill (e.g. `systematic-debugging`,
  `feature-workflow`), never instead of it.
