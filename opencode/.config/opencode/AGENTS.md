# Global operator preferences

Owner: vityasyyy. Standing instructions from 2026-09-15 — these override any
skill or convention that says otherwise. Reconfirm if they ever look unsafe.

## Skill routing table (2026-10-13 — standing)

Invoke the matching skill BEFORE acting; announce "Using [skill] to [purpose]".
One router: this table. Raise clarifying decisions through native question
modals when the harness exposes them, inline otherwise.

| Trigger | Skill |
|---|---|
| Plan/design/creative work of any size | `grilling` first (interview rounds to shared understanding), then `brainstorming` → `writing-plans` → `executing-plans` |
| Any bug, failure, or unexpected behavior | `systematic-debugging` before proposing fixes |
| Implementing maintained app code / behavior changes | `test-driven-development` (triage gate inside the skill covers skippable cases) |
| About to claim done/fixed/passing | `verification-before-completion` — evidence before assertions |
| Reviewing diffs/PRs/architecture | `code-review`; when receiving review feedback → `receiving-code-review` |
| Commits, branches, PRs, CI | `git-pr-workflow` |
| Parallel or delegated work | Tier 1: native subagents (`explore`, `document`, `general`) for read-only research, doc fetching, short bounded tasks. Tier 2: `herd` is the primary orchestrator (workers = herdr panes) for parallel write-capable, long-running, or approval-heavy waves; `parallel-worktrees` for isolated in-repo branches. No subagent-of-subagent chains. |
| Confluence/documentation work | `confluence-authoring`; atlassian MCP is disabled (below) until needed |
| Infra/production/reliability work | `production-reliability` |
| UI/visual design work | `frontend-design` |
| Writing or editing skills | `writing-skills` |
| opencode's own config/agents/skills/plugins | `opencode` (built-in V2 skill) |
| User states a durable preference/correction | `memory` — persist as dated standing rule here |

Execution default: inline in this session. Planning artifacts (specs, plans,
ADRs) live under the repo's `docs/plans/`.

## Large downloads (2026-10-10 — standing)

Local network here downloads slowly. When a step requires downloading or
installing anything (tool installs, updates, release binaries), ask the user
and END the chat first so they can run the download on their machine; resume
the task only after they confirm the file is in place.

## Atlassian MCP dormant (2026-10-13 — standing)

`mcp.atlassian` ships disabled in opencode.json (login is preserved in the
auth store). For Confluence/Jira work: set `disabled: false` on
`mcp.atlassian`, have the user restart opencode, then proceed with
`confluence-authoring`. Flip it back to `disabled: true` afterward. Same
pattern if a per-session integration is requested (Figma is configurable
per-project when needed).

## Shared workflow skills

Skill files live canonically in `~/dotfiles/agents/.agents/skills/` (shared
with Codex) and `~/dotfiles/opencode/.config/opencode/skills/` (opencode-only),
linked into `~/.agents/skills/` and `~/.config/opencode/skills/` by
`dotfiles/install.sh`. Edit the dotfiles source, never the `$HOME` link; run
`install.sh` after adding or moving skills. Project-local skills live in the
repo's `.opencode/skills/`.

## Worker workspace topology (2026-10-15 — standing)

- Always create each worker in a new Herdr workspace, never by splitting panes; attach worker workspaces beneath the lead workspace in a tree when supported. If native grouping is unavailable, use parent-prefixed workspace labels and explain the limitation.

## Worker lifecycle (2026-10-19 — standing)

- In herd tasks, prefer workers for implementation; the lead coordinates, reviews, verifies and integrates, and hands bounded rescue work back rather than quietly taking over the remaining implementation.
- Close this session's idle worker workspaces after handoff; preserve reports, branches and uncommitted work, remove worktrees only after safe integration, and leave other leads' workers alone unless explicitly authorized.

## Worker approvals (herd)

Auto-clear routine sandbox prompts on the operator's behalf: external-directory
access under `/tmp`, `~/.local/bin`, and worktrees, plus the planned tool
installs/downloads in the approved brief (promtool, amtool, crane, helm pulls,
pinned-image pulls).

Still escalate to the user first: secrets/credentials, destructive or
out-of-scope actions, and ambiguous decisions. Routine non-destructive cluster
inspection does not require renewed approval.

## Routine permissions (2026-10-15 — standing)

- Routine non-destructive work within the requested task is pre-authorized, including read-only cluster diagnostics; do not repeatedly ask for basic permissions. Ask before destructive actions, preserve explicit approval gates for deployments and worker spawning, and retain the separate download and secrets rules.

## Approved-scope execution (2026-10-19 — standing)

- Once a task's scope and actions are approved, proceed without repeated routine confirmations. Interrupt only for required credentials/secrets, destructive or out-of-scope actions, new worker/deployment approval gates, or material safety decisions. Do not interpret this as permission to bypass those gates or claim unverified recovery.

## Code hygiene (2026-10-08 — standing, do not re-ask)

- NEVER let plan artifacts leak into code: no "based on step N", "per phase
  N", "task N", or checkpoint/stage references in code comments, JSDoc,
  docstrings, or commit messages — code documents itself in the codebase's
  own terms. Plan structure belongs in the plan doc / PR description only.
- Invoke `ponytail` before ANY coding task (writing, fixing, refactoring,
  reviewing code, choosing dependencies) — lead and workers alike. It runs
  alongside the mapped process skill (e.g. `systematic-debugging`,
  `feature-workflow`), never instead of it.
- Code stays minimal: no speculative abstractions, no boilerplate, no
  unnecessary JSDoc or comment bloat. Bloat in any artifact (code, docs,
  skills) is a defect.

## Commit messages (2026-10-20 — standing)

- Every commit — lead, agent, worker, subagent — carries a descriptive body,
  not just a Conventional Commits subject. The body states what changed, why,
  and any user-visible or behavioral consequence the subject cannot carry.
  A body-less or ambiguous commit message is a defect; amend before pushing.

## Response style (2026-10-13 — standing)

Lead with the artifact, not prose. Concise but complete — detail lives in
structure, not adjectives.

- Diagram any architecture, data flow, or state change as Mermaid:
  `flowchart TD` / `sequenceDiagram` / `stateDiagram-v2`.
- Keep diagrams human-readable: short node labels, top-to-bottom layout,
  annotated edges, no spaghetti. If it reads as noodles, split it.
- Follow every diagram with 1–3 sentences interpreting it; don't assume the
  picture speaks for itself.
- Render-first: when the target surface renders Mermaid (Confluence, PR
  markdown), prefer rendered diagrams over ASCII art; in plain terminals,
  pair the Mermaid block with the verbal interpretation.

## Memory convention (2026-10-13 — standing)

Durable preferences from the operator are persisted via the `memory` skill as
dated standing-rule sections in this file. New preferences arriving in chat
are saved here automatically — the operator should not have to repeat himself.
Never store secrets or credentials here.
