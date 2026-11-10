# Global operator preferences

Owner: vityasyyy. These rules override skills and conventions unless they
would be unsafe. Each rule has one owner: link to it, never restate it.

## Workflow

Every non-trivial change follows one spine:

**inspect → contract → implement → verify → review → report.**

- **Inspect:** repo instructions, call path, nearest implementation, commands.
- **Contract:** behavior, acceptance, failures, compatibility; fix the review
  gate here. Multi-step gets a plan; testable behavior gets a failing test first.
- **Implement:** smallest correct diff; `ponytail`; reuse before adding.
- **Verify:** run the real commands; evidence, not claims.
- **Review:** standard/high-impact get an independent fresh-context round
  (`/review`); trivial gets a self-check. Fix blockers; never self-approve.
- **Report:** what changed, what was verified, risks, rollback, gaps.

Use only the skill for the current task. Announce: "Using [skill] to [purpose]."
When the user asks to review a diff/change, run `/review`; architecture review uses `code-review`.

| Trigger | Skill |
|---|---|
| Ambiguous intent, design interview | `grilling` |
| Multi-step plan, inline execution | `writing-plans` |
| Bug or unexpected behavior | `systematic-debugging` |
| Behavior change needing tests | `test-driven-development` |
| Explain/onboard codebase, architecture map | `codebase-explainer` |
| Implementation | `ponytail` then `feature-workflow` |
| Diff/PR and architecture review | `/review` for diffs; `code-review` otherwise |
| Commit, PR, CI | `git-pr-workflow` |
| Claiming done | `verification-before-completion` |
| Non-trivial implementation | `herd` + `herdr`; `parallel-worktrees` for parallel |
| Ops, infra, reliability | `production-reliability` |
| Docs, runbooks, PR bodies, Confluence | `documentation` |
| UI/visual design | `frontend-design` |
| Editing skills | `writing-skills` |
| Durable preference | `memory` |
| OpenCode config | `opencode` (built-in) |

## Engineering defaults
- Priority: correctness > security > reliability > maintainability >
  observability > performance.
- Understand the system and existing conventions; no speculative abstraction,
  scaffolding, or unrequested refactor; delete only dead code you create.
- Validate at trust boundaries; make failures visible/actionable; handle
  idempotent conditions explicitly; never swallow errors, expose secrets, or
  report false success.
- One authoritative configuration source per setting; make precedence explicit.
- Tests protect behavior, not implementation details.
- Production/infra: PR CI green is not done; verify post-merge Deploy and
  Infra Apply.

## Delegation

- Lead orchestrates; workers implement. Non-trivial code goes to `herd` (one
  worker per worktree); inline only for trivial docs/config/one-line fixes.
- Read-only research: `explore` / `document` subagents. Workers follow the same
  skill routing and subagent policy; `herd` owns the brief.
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
- Code stays minimal; unnecessary JSDoc, comments, and boilerplate are
  defects.
- Commits are atomic: behavior + tests together; messages carry Conventional
  subject, what/why/impact body, evidence, risks. Subject-only is a defect.

## Documentation discipline

- Repo docs: current state, linked paths/URLs, no planning history; owner:
  `documentation`. Task state lives in agent-memory (`docs/plans/` gitignored).
- Create repo planning/summary Markdown only when asked; prefer raw artifacts.
- Sensitive data: raw resource first, ask before summarizing; docs stay concise.

## Response style

- Lead with the artifact. Concise but complete; structure over adjectives.
- Diagram architecture, data flow, and state changes with Mermaid (`flowchart TD`,
  `sequenceDiagram`, `stateDiagram-v2`); render-first when supported.
- Short node labels, top-down layout, annotated edges; split spaghetti diagrams.
- Follow each diagram with 1–3 sentences of interpretation.

## Memory

- **Tier 0** this file (≤110); **Tier 1** repo `AGENTS.md`.
- **Tier 2** task state in agent-memory (gitignored `docs/plans/` only when
  asked); **Tier 3** session index.
- Write a handoff at the `feature-workflow` checkpoints, before a context
  rollover, and at session end. Setup: `~/dotfiles/docs/agent-memory.md`.

## Approvals

- Routine non-destructive work is pre-authorized, including read-only
  diagnostics, `/tmp`, `~/.local/bin`, worktrees, and approved tool installs.
- Ask before destructive commands, secrets/credentials, production or staging
  changes, deploys, migrations, new worker waves, or out-of-scope changes.
- Large downloads: ask the user to run them; resume after confirmation.
