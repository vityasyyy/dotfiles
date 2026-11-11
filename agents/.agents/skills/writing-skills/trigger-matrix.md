# Skill trigger matrix

Run each prompt in a fresh OpenCode session and record the skill the agent
announces or loads. The primary skill must fire; supporting skills may fire;
must-not skills must not fire. Every local skill appears at least once as
primary; combined scenarios may repeat a primary. All three harnesses read the
canonical router (`agents/.agents/AGENTS.md`); only invocation mechanics
differ. Keep this matrix current when a description or routing row changes.

| ID | Prompt | Primary | Supporting | Must not load |
|---|---|---|---|---|
| T01 | Simplify this over-engineered helper; use the smallest change. | [`ponytail`](../ponytail/SKILL.md) | [`feature-workflow`](../feature-workflow/SKILL.md) | [`documentation`](../documentation/SKILL.md) |
| T02 | Implement refresh token rotation across the auth service. | [`feature-workflow`](../feature-workflow/SKILL.md) | [`ponytail`](../ponytail/SKILL.md), [`test-driven-development`](../test-driven-development/SKILL.md) | [`documentation`](../documentation/SKILL.md) |
| T03 | Turn this approved spec into a task-by-task implementation plan. | [`writing-plans`](../writing-plans/SKILL.md) | [`grilling`](../grilling/SKILL.md) | [`herd`](../../../../opencode/.config/opencode/skills/herd/SKILL.md) |
| T04 | Interview me about the multi-tenant design before we build it. | [`grilling`](../grilling/SKILL.md) | [`writing-plans`](../writing-plans/SKILL.md) | [`feature-workflow`](../feature-workflow/SKILL.md) |
| T05 | These tests fail intermittently after the last change. | [`systematic-debugging`](../systematic-debugging/SKILL.md) | [`test-driven-development`](../test-driven-development/SKILL.md) | [`documentation`](../documentation/SKILL.md) |
| T06 | Add validation that rejects negative quantities. | [`test-driven-development`](../test-driven-development/SKILL.md) | [`feature-workflow`](../feature-workflow/SKILL.md) | [`documentation`](../documentation/SKILL.md) |
| T07 | Explain how the scheduler works; give me an architecture map. | [`codebase-explainer`](../codebase-explainer/SKILL.md) | | [`code-review`](../code-review/SKILL.md) |
| T08 | Review this architecture for reliability and failure modes. | [`code-review`](../code-review/SKILL.md) | [`production-reliability`](../production-reliability/SKILL.md) | [`feature-workflow`](../feature-workflow/SKILL.md) |
| T09 | Open a PR for this branch and wait for CI. | [`git-pr-workflow`](../git-pr-workflow/SKILL.md) | [`verification-before-completion`](../verification-before-completion/SKILL.md) | [`writing-plans`](../writing-plans/SKILL.md) |
| T10 | Is this fix actually done and verified? | [`verification-before-completion`](../verification-before-completion/SKILL.md) | [`feature-workflow`](../feature-workflow/SKILL.md) | [`documentation`](../documentation/SKILL.md) |
| T11 | Spawn two workers to split this migration. | [`herd`](../../../../opencode/.config/opencode/skills/herd/SKILL.md) | [`herdr`](../herdr/SKILL.md) | [`documentation`](../documentation/SKILL.md) |
| T12 | Show the panes in my Herdr workspace. | [`herdr`](../herdr/SKILL.md) | [`herd`](../../../../opencode/.config/opencode/skills/herd/SKILL.md) | [`writing-plans`](../writing-plans/SKILL.md) |
| T13 | Run three agents in isolated worktrees. | [`parallel-worktrees`](../parallel-worktrees/SKILL.md) | [`herd`](../../../../opencode/.config/opencode/skills/herd/SKILL.md) | [`documentation`](../documentation/SKILL.md) |
| T14 | Design backups, timeouts, and rollback for this service. | [`production-reliability`](../production-reliability/SKILL.md) | [`feature-workflow`](../feature-workflow/SKILL.md) | [`frontend-design`](../frontend-design/SKILL.md) |
| T15 | Write a runbook for rotating the database credential. | [`documentation`](../documentation/SKILL.md) | [`codebase-explainer`](../codebase-explainer/SKILL.md) | [`feature-workflow`](../feature-workflow/SKILL.md) |
| T16 | Make this dashboard feel distinctive, not templated. | [`frontend-design`](../frontend-design/SKILL.md) | [`documentation`](../documentation/SKILL.md) | [`production-reliability`](../production-reliability/SKILL.md) |
| T17 | Create a skill for incident response. | [`writing-skills`](../writing-skills/SKILL.md) | [`documentation`](../documentation/SKILL.md) | [`feature-workflow`](../feature-workflow/SKILL.md) |
| T18 | Remember that I prefer squash merges. | [`memory`](../memory/SKILL.md) | [`handoff`](../handoff/SKILL.md) | [`documentation`](../documentation/SKILL.md) |
| T19 | I'm near the context limit; hand this off. | [`handoff`](../handoff/SKILL.md) | [`memory`](../memory/SKILL.md) | [`feature-workflow`](../feature-workflow/SKILL.md) |
| T20 | Fix the flaky login test, then add a regression test. | [`systematic-debugging`](../systematic-debugging/SKILL.md) | [`test-driven-development`](../test-driven-development/SKILL.md), [`feature-workflow`](../feature-workflow/SKILL.md) | [`documentation`](../documentation/SKILL.md) |
| T21 | Plan the migration and implement it in parallel. | [`grilling`](../grilling/SKILL.md) | [`writing-plans`](../writing-plans/SKILL.md), [`herd`](../../../../opencode/.config/opencode/skills/herd/SKILL.md), [`parallel-worktrees`](../parallel-worktrees/SKILL.md) | [`documentation`](../documentation/SKILL.md) |
| T22 | Review this PR and merge it if CI is green. | [`git-pr-workflow`](../git-pr-workflow/SKILL.md) | [`code-review`](../code-review/SKILL.md), [`verification-before-completion`](../verification-before-completion/SKILL.md) | [`writing-plans`](../writing-plans/SKILL.md) |
| T23 | Clean up this README and link the file references. | [`documentation`](../documentation/SKILL.md) | [`codebase-explainer`](../codebase-explainer/SKILL.md) | [`feature-workflow`](../feature-workflow/SKILL.md) |
| T24 | This skill never fires; diagnose the trigger. | [`writing-skills`](../writing-skills/SKILL.md) | [`memory`](../memory/SKILL.md) | [`feature-workflow`](../feature-workflow/SKILL.md) |
| T25 | Review this diff before I merge it. | [`code-review`](../code-review/SKILL.md) | [`verification-before-completion`](../verification-before-completion/SKILL.md) | [`feature-workflow`](../feature-workflow/SKILL.md) |
