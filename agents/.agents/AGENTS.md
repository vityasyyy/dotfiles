# Global operator preferences

Owner: vityasyyy. One file, symlinked to OpenCode, Claude, and Codex. Rules
override skills unless unsafe; each rule has one owner, linked not restated.

## Workflow

Every non-trivial change follows one spine:

**inspect → contract → implement → verify → review → report.**

- **Inspect:** repo instructions, call path, nearest implementation, commands.
- **Contract:** behavior, acceptance, failures, compatibility; fix the review
  gate here. Multi-step gets a plan; testable behavior gets a failing test first.
- **Implement:** smallest correct diff; `ponytail`; reuse before adding.
- **Verify:** run the real commands; evidence, not claims.
- **Review:** standard/high-impact get a fresh-context round; trivial gets a
  self-check. Fix blockers; never self-approve.
- **Report:** what changed, what was verified, risks, rollback, gaps.

Load the owning skill for the task; announce "Using [skill] to [purpose]."
One owner per rule; load every skill the lane needs, nothing else.

| Trigger | Skill |
|---|---|
| Ambiguous intent, design interview | `grilling` |
| Multi-step plan | `writing-plans` |
| Bug or unexpected behavior | `systematic-debugging` |
| Behavior change needing tests | `test-driven-development` |
| Explain/onboard codebase | `codebase-explainer` |
| Implementation | `ponytail` then `feature-workflow` |
| Diff/PR review | fresh-context reviewer, `code-review` rubric |
| Commit, PR, CI | `git-pr-workflow` |
| Claiming done | `verification-before-completion` |
| Worker orchestration (harness supports it) | `herd` + `herdr` |
| Parallel or isolated in-repo work | `parallel-worktrees` |
| Ops, infra, reliability | `production-reliability` |
| Docs, runbooks, PR bodies, Confluence | `documentation` |
| UI/visual design | `frontend-design` |
| Editing skills | `writing-skills` |
| Durable preference | `memory` |
| Context rollover | `handoff` |

## Engineering defaults
- Priority: correctness > security > reliability > maintainability >
  observability > performance.
- Understand the system and existing conventions; no speculative abstraction,
  scaffolding, or unrequested refactor; delete only dead code you create.
- Validate at trust boundaries; make failures visible and actionable; never
  swallow errors, expose secrets, or report false success.
- One authoritative configuration source per setting; make precedence explicit.
- **State is explicit:** ≥3 mutually exclusive states, or any transition over
  an async/restart boundary, gets one closed state type, one transition
  function, and exhaustive matching; derived state is computed, never stored.
  Below that threshold: plain values, no state-machine ceremony.
- Production/infra: verify post-merge pipelines; PR CI green is not done.

## Delegation

- Lead orchestrates; workers implement. Where the harness supports workers,
  non-trivial code goes to one worker per worktree; otherwise do it inline
  with native subagents, state why, and never call it a process failure.
- Read-only research: `explore` / `document` when available; worker delegation owns the brief.
- Get approval before spawning workers; verify worker output before integrating.

## Tool discipline

- Never repeat an identical tool call. If output exists, use it or run a
  different diagnostic.
- Three similar calls without progress: stop, summarize, decide, or ask.
- Blocked on external state: use a blocking wait (`gh pr checks --watch`,
  `herdr agent wait`) or ask. Do not poll in a loop.

## Code hygiene

- No plan artifacts in code, comments, or commits ("step N", "phase N").
- Code stays minimal; unnecessary JSDoc, comments, boilerplate are defects.
- Commits are atomic: behavior + tests together; messages carry Conventional
  subject, what/why/impact body, evidence, risks. Subject-only is a defect.

## Documentation discipline

- Repo docs: current state, linked paths/URLs, no planning history; owner `documentation`. Confluence diagrams: render locally; use approved REST uploads if MCP lacks attachments.
- Create repo planning/summary Markdown only when asked; prefer raw artifacts.
- Sensitive data: raw resource first, ask before summarizing; docs stay concise.

## Response style

- Lead with the artifact. Concise but complete; structure over adjectives.
- Diagram architecture, data flow, and state changes with Mermaid, render-first;
  short top-down labels, annotated edges; 1–3 sentences of interpretation.

## Memory

- **Tier 0** this file (≤110); **Tier 1** repo `AGENTS.md`.
- **Tier 2** task state in agent-memory; **Tier 3** session index.
- Write a handoff at the `feature-workflow` checkpoints, before a context
  rollover, and at session end. Setup: `~/dotfiles/docs/agent-memory.md`.

## Approvals

- Routine non-destructive work is pre-authorized, including read-only
  diagnostics, `/tmp`, `~/.local/bin`, worktrees, and approved tool installs.
- Standing merge authorization: after the review round and green required CI,
  squash-merge and delete the branch without re-asking, unless the repo
  `AGENTS.md` requires an ask. This covers merges that trigger a deploy.
  Never merge to `main` directly or force-push.
- Ask before destructive commands, secrets/credentials, production or staging
  changes, deploy commands, migrations, or new worker waves.
- Large downloads: ask the user to run them; resume after confirmation.
