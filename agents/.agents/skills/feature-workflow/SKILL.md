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

| Lane | Trigger | Minimum gates |
|---|---|---|
| Trivial | typo, one-line fix, config/docs; reversible; obvious check | one-line contract → implement → verify → report |
| Standard | behavior change in maintained code | contract + gate → tests (TDD when testable) → implement → verify → review gate → PR |
| High-impact | architecture, data model, security, cross-cutting, production infra | grilling/spec → plan → worker delegation (parallel-worktrees if parallel) → contract + gate → implement → verify → review gate → PR → post-merge pipelines |

When unsure, take the higher lane. If a trivial change grows, move to the
standard lane immediately; do not retrofit a plan after the fact.

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
Non-goals:
Compatibility:
Gate:
Evidence:
```

- If Behavior or Acceptance cannot be filled without guessing, use `grilling`.
- Fix the review gate here with the contract: the default lives in
  `code-review`, plus any task-specific thresholds.
- Multi-step: put the contract at the top of the plan (`writing-plans`).
- Testable: turn Acceptance into failing tests (`test-driven-development`).
- Trivial: one line in the response is enough.

## 3. Plan and delegate

- Multi-step: keep the contract and plan in chat for single-session work; use
  task state (`memory`) when the work crosses a session, a worker, or a context
  rollover. A user-requested `docs/plans/` copy is gitignored and never
  committed. Plan format and task granularity: `writing-plans`.
- Lead: where the harness supports workers (`herd`), non-trivial
  implementation goes to one; add `parallel-worktrees` only when work is
  parallel or isolated. Otherwise implement inline with native subagents for
  research and review, and state why. The worker brief carries the contract
  and evidence commands. Workers never spawn workers.
- Before the first edit, record the delegation decision. Inline non-trivial
  work is a process failure only when a worker runtime is available.

## 4. Implement

- Keep the diff scoped. Ask before a large refactor or public API change.
- Update the docs with `documentation`, plus config and migrations the change
  requires.

## 5. Verify

- Run targeted tests first, then the full relevant suite.
- Run the formatter, linter, typecheck/build, and project-specific checks.
- Map each Acceptance item to evidence. A green suite that misses an
  acceptance item is not done.
- If a check cannot run, state why. Do not claim success without evidence.
- Use `verification-before-completion` for the final gate.

## 6. Review and report

- Standard/high-impact: run an independent review round against the gate fixed
  at contract time (OpenCode `/review`, Claude the `review` subagent, Codex a
  fresh session). The reviewer reports; you fix blocking findings or push back
  with evidence.
- Re-review the delta in a fresh round. Stop on `PASS`; escalate on `STALL`
  (same blocking set twice), `BLOCKED`, or the round budget.
- Trivial: re-read the diff yourself; fix stray debug code and scope creep.
- Commit, open the PR, and wait for CI with `git-pr-workflow`. The feature and
  its tests land in one commit; never split `feat`/`fix` from `test`.
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
