# Global operator preferences

Owner: vityasyyy. These rules override skills and conventions unless they
would be unsafe. Each rule has one owner: link to it, never restate it.

## Workflow

Every non-trivial change follows one spine:

**inspect → define contract → implement → verify → self-review → report.**

- **Inspect:** read repo instructions, trace the call path, find the nearest
  existing implementation, identify test/lint/typecheck/build commands.
- **Contract:** state behavior, acceptance criteria, failure cases, non-goals,
  and compatibility. Multi-step work gets a plan; testable behavior gets a
  failing test first.
- **Implement:** smallest correct diff. Follow `ponytail`; reuse before adding.
- **Verify:** run the real commands. Evidence, not claims.
- **Self-review:** re-read the diff as a reviewer, then report what changed,
  what was verified, risks, rollback, and known gaps.

Use only the skill for the current phase. Announce: "Using [skill] to [purpose]."

| Phase | Skill |
|---|---|
| Ambiguous intent, design interview | `grilling` |
| Multi-step plan, inline execution | `writing-plans` |
| Bug or unexpected behavior | `systematic-debugging` |
| Behavior change needing tests | `test-driven-development` |
| Explain/onboard codebase, architecture map | `codebase-explainer` |
| Implementation | `ponytail` then `feature-workflow` |
| Diff, PR, architecture review | `code-review` |
| Commit, PR, CI | `git-pr-workflow` |
| Claiming done | `verification-before-completion` |
| Parallel write work | `herd` + `herdr` + `parallel-worktrees` |
| Ops, infra, reliability | `production-reliability` |
| Confluence docs | `confluence-authoring` |
| UI/visual design | `frontend-design` |
| Editing skills | `writing-skills` |
| Durable preference | `memory` |
| OpenCode config | `opencode` (built-in) |

## Engineering defaults
- Priority: correctness > security > reliability > maintainability >
  observability > performance.
- Understand the system and existing conventions; no speculative abstraction,
  scaffolding, or unrequested refactor. Delete only dead code you create.
- Validate at trust boundaries. Make operational failures visible and
  actionable; handle expected idempotent conditions explicitly; never swallow
  unexpected errors, expose secrets, or report false success.
- One authoritative configuration source per setting; make precedence explicit.
- Tests protect behavior, not implementation details.
- Production/infra: PR CI green is not done; verify post-merge Deploy and
  Infra Apply.

## Delegation

- Default: do the work inline.
- Read-only research: native `explore` / `document` subagents.
- Parallel write work, long jobs, approval-heavy work: `herd` with herdr
  panes, one worker per worktree.
- Get approval before spawning workers; verify worker output before integrating.

## Tool discipline

- Never repeat an identical tool call. If output exists, use it or run a
  different diagnostic.
- Three similar calls without progress: stop, summarize, decide, or ask.
- Blocked on external state: use a blocking wait (`gh pr checks --watch`,
  `herdr agent wait`) or ask. Do not poll in a loop.

## Code hygiene

- No plan artifacts in code, comments, or commits ("step N", "phase N",
  "per task N").
- No process artifacts committed to product repos (reports, plans,
  walkthroughs).
- Code stays minimal; unnecessary JSDoc, comments, and boilerplate are
  defects.
- Commit/PR messages are compact and scannable: Conventional subject,
  what/why/impact body, evidence, risks. Subject-only is a defect.

## Response style

- Lead with the artifact. Concise but complete; structure over adjectives.
- Diagram architecture, data flow, and state changes with Mermaid
  (`flowchart TD`, `sequenceDiagram`, `stateDiagram-v2`). Render-first when
  the surface supports it.
- Short node labels, top-down layout, annotated edges. Split diagrams that
  read as spaghetti.
- Follow each diagram with 1–3 sentences of interpretation.

## Memory

- **Tier 0** — this file: invariants only, target ≤110 lines. Adding a rule
  requires deleting or merging one.
- **Tier 1** — repo `AGENTS.md`: commands, conventions, gotchas.
- **Tier 2** — `docs/plans/`: active task state, decisions, next action.
- **Tier 3** — session archive + `mem search`: history, never injected.
- Write a handoff at the `feature-workflow` checkpoints, before compaction,
  and at session end. Setup: `~/dotfiles/docs/agent-memory.md`.

## Approvals

- Routine non-destructive work is pre-authorized, including read-only
  diagnostics, `/tmp`, `~/.local/bin`, worktrees, and approved tool installs.
- Ask before secrets/credentials, destructive actions, deployments, new
  worker waves, or out-of-scope changes.
- Large downloads: ask the user to run the download and end the chat; resume
  after they confirm the file is in place.
