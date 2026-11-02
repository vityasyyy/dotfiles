---
name: feature-workflow
description: Use when implementing a feature, bug fix, or refactor. Runs the inspect → contract → implement → verify → self-review spine and delegates each phase to its owning skill.
metadata:
  audience: ai-coding-agent
  workflow: feature-development
---

# Feature Workflow

The spine lives in `AGENTS.md`. This skill sequences the owners. Do not restate
a rule another skill owns; link to it.

## 1. Inspect

- Read repo `AGENTS.md`, README, manifests, and CI config.
- Find the nearest existing implementation; trace the real call path.
- Identify test, lint, typecheck, and build commands.
- If behavior is broken, use `systematic-debugging` before proposing a fix.

## 2. Define the contract

- State behavior, acceptance criteria, failure cases, non-goals, and
  compatibility.
- Multi-step work: write the plan with `writing-plans` in `docs/plans/`.
- Testable behavior: write the failing test with `test-driven-development`.
- Ambiguous intent or architecture: settle it with `grilling`.

## 3. Implement

- Use `ponytail`.
- Keep the diff scoped. Ask before a large refactor or public API change.
- Update the docs, config, and migrations the change requires.

## 4. Verify

- Run targeted tests first, then the full relevant suite.
- Run the formatter, linter, typecheck/build, and project-specific checks.
- If a check cannot run, state why. Do not claim success without evidence.
- Use `verification-before-completion` for the final gate.

## 5. Self-review and report

- Review the diff with `code-review`; fix findings before commit.
- Commit, open the PR, and wait for CI with `git-pr-workflow`.
- Report what changed, the evidence (commands and results), risks, rollback,
  and any known gaps.
