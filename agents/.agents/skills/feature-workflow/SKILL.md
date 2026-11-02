---
name: feature-workflow
description: Use when implementing a feature, bug fix, or refactor. Runs the inspect → contract → implement → verify → self-review spine and scales the process to the change's risk.
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
| Standard | behavior change in maintained code | contract → tests (TDD when testable) → implement → verify → self-review → PR |
| High-impact | architecture, data model, security, cross-cutting, production infra | grilling/spec → plan → herd if parallel → contract → implement → verify → review → PR → post-merge pipelines |

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
Evidence:
```

- If Behavior or Acceptance cannot be filled without guessing, use `grilling`.
- Multi-step: put the contract at the top of the plan (`writing-plans`).
- Testable: turn Acceptance into failing tests (`test-driven-development`).
- Trivial: one line in the response is enough.

## 3. Plan and delegate

- Multi-step: write the plan with `writing-plans` in `docs/plans/`.
- Parallel or isolated: `herd` + `parallel-worktrees`; the worker brief carries
  the contract and the evidence commands.
- Otherwise execute inline.

## 4. Implement

- Use `ponytail`.
- Keep the diff scoped. Ask before a large refactor or public API change.
- Update the docs, config, and migrations the change requires.

## 5. Verify

- Run targeted tests first, then the full relevant suite.
- Run the formatter, linter, typecheck/build, and project-specific checks.
- Map each Acceptance item to evidence. A green suite that misses an
  acceptance item is not done.
- If a check cannot run, state why. Do not claim success without evidence.
- Use `verification-before-completion` for the final gate.

## 6. Self-review and report

- Standard/high-impact: review the diff with `code-review`; fix findings.
- Trivial: re-read the diff yourself; fix stray debug code and scope creep.
- Commit, open the PR, and wait for CI with `git-pr-workflow`.
- Report:

  | Requirement | Evidence |
  |---|---|
  | ... | command, test, or manual check |

  Add risks, rollback, and known gaps.

## Checkpoints

Write or refresh the handoff at these points, using the `memory` skill:

1. After the contract or plan.
2. Before `/compact`.
3. After verification.
4. Before delegating to a worker.
5. At session end.

The handoff is the recovery artifact; the summary is not.
