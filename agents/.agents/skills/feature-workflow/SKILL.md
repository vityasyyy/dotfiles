---
name: feature-workflow
description: Use when implementing a feature, bug fix, or refactor. Runs the inspect → contract → implement → verify → review spine and scales the process to the change's risk.
metadata:
  audience: ai-coding-agent
  workflow: feature-development
---

# Feature Workflow

The spine lives in `AGENTS.md`. This skill sequences the owners and sets the
minimum gates for each lane. Do not restate a rule another skill owns.

## Pick the lane

| Lane | Trigger | Review | Minimum gates |
|---|---|---|---|
| Trivial | typo, one-line fix, config/docs; reversible; obvious check | skip | one-line contract → implement → verify → report |
| Standard | behavior change in maintained code | light | contract + gate → tests (TDD when testable) → implement → verify → advisory review → PR |
| High-impact | architecture, data model, money/auth/security, cross-cutting, production infra | full | grilling/spec → plan → worker delegation (worktrees if parallel) → contract + gate → implement → verify → full review → PR → post-merge pipelines |

Review triggers and verdicts are owned by `code-review`. Record
`Review: skip|light|full` in the contract. When unsure between code lanes, take
the higher lane; between review lanes, take `light` and promote the change if
the review finds a full-lane issue.

If a trivial change grows, move to the standard lane immediately; do not
retrofit a plan after the fact.

## 1. Inspect

- Read repo `AGENTS.md`, README, manifests, and CI config.
- Find the nearest existing implementation; trace the real call path.
- Identify test, lint, typecheck, and build commands.
- If the repo has no `AGENTS.md` and the conventions are non-obvious, propose
  a short one (Tier 1 memory).
- If behavior is broken, use `systematic-debugging` before proposing a fix.

## 2. Contract

Write the contract before coding:

```markdown
## Contract
Behavior:
Acceptance:
Failure cases:
Composition:      # app/router/middleware/listener order and per-request counts
Consumer fields:  # every response field downstream reads, through each transform
Status matrix:    # every provider/lifecycle state -> visible outcome
Non-goals:
Compatibility:
Gate:
Review:           # skip | light | full
Evidence:
```

- If Behavior or Acceptance cannot be filled without guessing, use `grilling`.
- For a change with a consumer (UI, API client, agent), the seam the consumer
  sees is part of Acceptance; plan the composition or exact-render test here.
  Isolated unit tests do not satisfy that seam.
- Pick the review lane here with the contract: `skip`, `light`, or `full`;
  triggers and the gate live in `code-review`.
- Multi-step: put the contract at the top of the plan (`writing-plans`).
- Testable: turn Acceptance into failing tests (`testing`).
- Trivial: one line in the response is enough.

## 3. Plan and delegate

- Multi-step: keep the contract and plan in chat for single-session work; use
  task state (`memory`) when the work crosses a session, a worker, or a context
  rollover; plan location rules live in `memory`. Plan format and task
  granularity: `writing-plans`.
- Lead: where the harness supports workers (`herd`), non-trivial
  implementation goes to one; add a worktree (`git-pr-workflow`) only when
  work is parallel or isolated. Otherwise implement inline with native subagents for
  research and review, and state why. The worker brief carries the contract
  and evidence commands. Workers never spawn workers.
- Before the first edit, record the delegation decision. Inline non-trivial
  work is a process failure only when a worker runtime is available.

## 4. Implement

- Keep the diff scoped. Ask before a large refactor or public API change.
- Update the docs with `documentation`, plus config and migrations the change
  requires.

## 5. Verify

- Run targeted tests first, then the repository's full validation entrypoint
  (`git-pr-workflow`), not only the files you changed.
- Run the formatter, linter, typecheck/build, and project-specific checks.
- Map each Acceptance item to evidence. A green suite that misses an
  acceptance item is not done.
- If a gate cannot run, replace it with the smallest equivalent check
  (`verification-before-completion`); stating why is not coverage.
- Run the `testing` finalize audit; its evidence block goes in the report.
- Use `verification-before-completion` for the final gate.

## 6. Review and report

- `skip`: re-read the diff yourself; fix stray debug code and scope creep.
- `light`: one advisory pass (OpenCode `/review light`, Claude the `review`
  subagent, Codex a fresh session). Fix must-fix findings; record accepted
  follow-ups. It blocks only on `CRITICAL`.
- `full`: independent review against the contract gate. Fix must-fix findings
  or push back with evidence; re-review only the delta that closes them, at
  most three rounds. Escalate on `DO NOT SHIP` twice or budget exhaustion.
- Review the stack, not each layer: one full pass covers the aggregate diff.
- Commit, open the PR, and wait for CI with `git-pr-workflow`.
- Report:

  | Requirement | Evidence |
  |---|---|
  | ... | command, test, or manual check |

  Add risks, rollback, and known gaps.

## Checkpoints

Write or refresh the handoff at these points, using the `memory` skill. Use the
`handoff` skill at a context rollover: OpenCode starts the successor session;
for other harnesses, tell the user to start a fresh session from the handoff.

1. After the contract or plan: write the handoff; for multi-session or
   delegated work, update task state first.
2. Before a context rollover (`handoff` skill).
3. After verification.
4. Before delegating to a worker.
5. At session end.
6. When the task merges or is abandoned, archive its task state under
   `~/.local/share/agent-memory/tasks/archive/`.

The handoff is the recovery artifact; the summary is not.
