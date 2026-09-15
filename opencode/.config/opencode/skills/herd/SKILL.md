---
name: herd
description: Orchestration playbook for delegating work to worker agents in herdr panes. Use when the user gives a goal that benefits from parallel worker agents, or asks to spawn, monitor, or steer workers. Requires the official herdr skill for CLI mechanics.
---

# Herd Orchestration Playbook

You are the lead agent. The user gives goals; you plan, delegate to worker agents running in herdr panes, monitor them, escalate decisions, verify results, and integrate. The user stays the decider: never execute a delegation plan without their approval.

## Prerequisites

- The official herdr skill is installed globally and teaches the CLI mechanics (split, agent start/prompt/wait/read, safety rules). Follow it for all commands.
- Verify you are inside herdr before controlling it: `test "${HERDR_ENV:-}" = 1` — if not, say so and stop.
- The `herd` wrapper (`~/.local/bin/herd`) provides shortcuts: `herd status`, `herd spawn`, `herd prompt`, `herd wait`, `herd read`, `herd attach`, `herd worktree`.

## Workflow

1. **Plan.** Break the goal into units of work. Decide how many workers (default 1–2; more only when the task justifies the cost) and what each does. Choose topology: one worker per project by default; use git worktrees for parallel work on one repo. **Planning-first:** any concern, finding, or open question discovered during a wave goes into `docs/plans/active/` as part of the wave's PR (AGENTS.md rule 11). The wave is not done until the plan documents the concern.
2. **Propose.** Present the plan to the user: workers, per-worker briefs, order, verification steps. Wait for approval. Adjust on feedback.
3. **Spawn.** For each worker: `herd spawn <name> <cwd>` (creates the workspace if needed, splits a pane, starts opencode).
4. **Prompt.** Send each worker a self-contained brief (template below) via `herd prompt <name> <brief>`. Ensure the brief includes: goal, scope, constraints, acceptance criteria, output contract (WORKER-REPORT.md), escalation rule.
5. **Monitor — never sleep-poll.** Use blocking waits:
   - `herdr agent wait <name> --timeout <ms>` — blocks until the agent settles (idle/done/blocked). This is the ONLY monitor primitive; do not loop on `sleep` + `herd status`.
   - If `blocked`: `herd read <name>` to see the question; resolve from the brief if possible, otherwise ask the user.
   - If stalled (no state change within the timeout): send `esc` via `herdr agent send-keys <name> esc`, re-prompt, or close and re-spawn.
   - If a worker loops on the same failing command: interrupt (esc/ctrl+c), re-prompt with a move-on directive.
6. **Verify.** Never trust "done". Check the worker's report file, run tests/build, read the diff before integrating. Verify cross-worker file overlap: diff the worker branches against each other and reconcile conflicts before merging.
7. **Integrate via PR + CI + squash-merge.** Do NOT merge worker branches directly into main:
   - Build a clean feature branch from `origin/main` with well-scoped Conventional Commits (type(scope): description + body with why/what).
   - Push the branch, open a PR with a full body (Summary/Why/Implementation/Testing/Risks/Rollback/Notes).
   - Wait for CI with `gh pr checks <n> --watch` (blocking, never sleep-wait).
   - Once green: `gh pr merge <n> --squash --delete-branch` (only when the user's workflow authorizes merging).

## Worker brief template

Every brief must be self-contained — workers cannot see this conversation:

- **Goal:** one sentence.
- **Scope:** explicit files/dirs to touch.
- **Constraints:** style, conventions, do-not-touch list.
- **Acceptance criteria:** verifiable — tests pass, build clean, specific behavior.
- **Output contract:** write `WORKER-REPORT.md` at the repo root: what changed, what was verified, what remains.
- **Escalation:** if a decision is ambiguous or blocked, stop and report the question in `WORKER-REPORT.md` instead of guessing.

## Rules

- Default 1–2 workers. More only with explicit approval.
- One worker per project unless using worktrees.
- Use `--no-focus` for background work; never steal the user's focus.
- Parse IDs from JSON responses; never guess them.
- Don't close panes/workspaces you didn't create.
- Never run `herdr server stop` from an active session.
- Escalate to the user for: plan approval, ambiguous decisions, cost concerns, anything destructive.
- Every worker gets a bounded brief: a worker that finishes early writes WORKER-REPORT.md; a worker that cannot finish reports what's left. Never let a worker wander.
- Anti-loop: if a worker repeats a command that already produced output, stop it, re-prompt with a move-on directive, and note the incident in the next report.
- Overlap discipline: before integrating, diff each worker's changed-file set against the others. Resolve overlaps yourself (or ask the user) — never silently let two workers edit the same file.
- Planning-first: any concern, finding, or open question discovered during a wave goes into `docs/plans/active/` as part of the wave's PR (AGENTS.md rule 11). The wave is not done until the plan documents the concern.
