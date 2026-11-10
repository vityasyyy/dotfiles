# Claude Code global instructions

User-level defaults for Claude Code. Repository instructions (`CLAUDE.md`,
`AGENTS.md`) and the current request take precedence where they are more
specific. This file is the Claude Code projection of the shared workflow; the
skills in `~/.claude/skills` (linked to `~/.agents/skills`) are the source of
truth.

## Work across agents

- Shared conventions and skills live in `~/.agents/skills`. Keep Claude Code
  auth, model, and runtime settings separate from OpenCode and Codex.
- Read the repository's `CLAUDE.md`/`AGENTS.md` before changing code or docs.
  Inspect the repo to answer questions its files can settle.
- Carry the task to a reviewable result. Ask only when the choice materially
  affects correctness, safety, or the user's intent.
- Protect credentials and private data. Ask before destructive or out-of-scope
  actions, live-cluster changes, or handling secrets.
- Before a step that needs a large download or install, ask the user to run it
  and pause that step.
- Ask before destructive commands, production/staging changes, deploys,
  migrations, or secrets. Routine read-only diagnostics are pre-authorized.

## Workflow

Every non-trivial change: **inspect → define contract → implement → verify →
review → report.**

- Inspect the call path, existing implementations, and the repo's test/lint/
  typecheck/build commands.
- State behavior, acceptance criteria, failure cases, non-goals, and
  compatibility before coding; fix the review gate here.
- Implement the smallest correct change with `ponytail`.
- Verify with real commands; evidence before claims.
- Review in a fresh context (the `review` subagent) against the fixed gate; fix
  blockers or push back with evidence. Never self-approve.
- Report changes, evidence, risks, and known gaps.

## Skill routing

Load the owning skill before acting; announce "Using [skill] to [purpose]".
Each rule has one owner; link to it rather than restating it.

| Trigger | Skill |
|---|---|
| Any coding task | `ponytail` first, alongside the mapped process skill |
| Ambiguous intent, design interview | `grilling`, then `writing-plans` |
| Bug, failure, unexpected behavior | `systematic-debugging` |
| Behavior change needing tests | `test-driven-development` |
| Explain/onboard a codebase | `codebase-explainer` |
| Implementation | `ponytail` then `feature-workflow` |
| About to claim done/fixed/passing | `verification-before-completion` |
| Diff/PR and architecture review | `review` subagent for diffs; `code-review` otherwise |
| Commits, branches, PRs, CI | `git-pr-workflow` |
| Parallel or isolated in-repo work | `parallel-worktrees` |
| Infra/production/reliability | `production-reliability` |
| Confluence docs | `confluence-authoring` (via the `document` subagent) |
| UI/visual design | `frontend-design` |
| Writing or editing skills | `writing-skills` |
| Durable preference or correction | `memory`; Tier 0 for Claude Code is this file |

`handoff` drives OpenCode sessions (`opencode api`). In Claude Code, scaffold
the handoff with the memory skill's `mem handoff` at the same checkpoints, then
tell the user to start a fresh session from it; do not run
`session-handoff start`.

## Delegation

- Default: do the work inline.
- Read-only code research: `explore` subagent. Confluence/Drive work:
  `document` subagent. Bounded side tasks: `general` subagent. Independent
  review: `review` subagent (never edits).
- Get approval before fanning out parallel write work; verify subagent output
  before integrating.

## Tool discipline

- Never repeat an identical tool call. If output exists, use it or run a
  different diagnostic.
- Three similar calls without progress: stop, summarize, decide, or ask.
- Blocked on external state: use a blocking wait (`gh pr checks --watch`) or
  ask. Do not poll in a loop.

## Code hygiene

- No plan artifacts in code, comments, or commits ("step N", "phase N").
- Create repo planning/summary Markdown only when asked; keep task state in
  agent-memory and prefer raw artifacts.
- Unnecessary comments, JSDoc, and boilerplate are defects.
- Commit/PR messages follow `git-pr-workflow`: Conventional subject,
  what/why/impact body, evidence, risks; behavior + tests land in one commit.
  Subject-only is a defect.

## Response style

- Lead with the artifact. Concise but complete; structure over adjectives.
- Diagram architecture, data flow, and state changes as Mermaid
  (`flowchart TD`, `sequenceDiagram`, `stateDiagram-v2`); short labels,
  top-down, annotated edges; 1–3 sentences of interpretation after each.

## Git and release rules

- Preserve the working tree. Do not reset, clean, stash, rewrite pushed
  history, or commit unrelated changes.
- Production/infra: PR CI green is not done; verify post-merge Deploy and
  Infra Apply before reporting completion.
