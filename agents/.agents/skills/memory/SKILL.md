---
name: memory
description: Use when persisting a durable preference or correction, deciding where a fact belongs, writing a handoff before a context rollover, or recalling past session context.
metadata:
  audience: ai-coding-agent
  workflow: memory
---

# Memory

Four tiers; one fact lives in one tier. Retrieval is a query, never a context
dump. `feature-workflow` owns checkpoints; this skill owns tiers and the
handoff template. Commands use `MEM=~/.agents/skills/memory/scripts/mem`.

| Tier | Where | Budget | Holds |
|---|---|---|---|
| 0 | OpenCode: `~/.config/opencode/AGENTS.md` · Claude: `~/.claude/CLAUDE.md` · Codex: `~/.codex/AGENTS.md` | ≤110 lines | invariants loaded every session |
| 1 | `<repo>/AGENTS.md` + `.opencode/memory/` | ≤80 lines | commands, conventions, gotchas |
| 2 | `~/.local/share/agent-memory/{tasks,handoffs}/` | structured | plan, handoff, decisions |
| 3 | `~/.local/share/agent-memory/` | unbounded | session index + digests |

## Routing a fact

- Changes behavior every session → Tier 0. One terse bullet, merged into an
  existing section, never duplicated.
- True for this repo only → Tier 1.
- True for this task only → Tier 2. Use task state when work crosses a
  session, a worker, or a context rollover; otherwise keep it in chat. Repo
  `docs/plans/` only when asked.
- History, prior decisions, "where did we…" → Tier 3.

Never store secrets or credentials in any tier.

## Tier 0 rules

- Canonical sources are `~/dotfiles/opencode/.config/opencode/AGENTS.md`,
  `~/dotfiles/claude/.claude/CLAUDE.md`, and `~/dotfiles/codex/.codex/AGENTS.md`;
  edit the source for your harness, not the `~` symlink.
- Match `## <Topic> (<date> — standing)`.
- Adding a rule requires deleting or merging one. The cap is the point.
- Do not commit Tier 0 edits without the user's approval; the user reviews
  dotfiles changes.

## Tier 2: task state and handoff

Write the handoff at plan time and at every checkpoint, before a context
rollover:

```sh
$MEM plan --task "short title"
$MEM handoff --task "short title"
```

`plan` scaffolds a task-state plan; `handoff` scaffolds the template below and
prints its path. Both are idempotent.

```markdown
# Handoff — <task>
Date:
Repo:
Branch:
Goal:
Plan: task-state path or chat
Acceptance:
Gate:
State: done | in progress | blocked
Decisions: what + why
Files: exact paths
Commands: worked / failed
Next: one next action
Open questions:
```

The handoff points at the plan. Update both at checkpoints; archive the task
directory under `~/.local/share/agent-memory/tasks/archive/` when the task ends.
A stale plan is worse than none. For an OpenCode rollover, `handoff` writes the
handoff, exports the transcript, and continues in a new session; re-read both
first, never trust a summary alone.

## Tier 3: recall

```sh
$MEM stats
$MEM search "query terms" --limit 10
$MEM sessions --limit 20
$MEM index
```

The FTS5 index over OpenCode `session_message` lives at
`~/.local/share/agent-memory/index.db`, rebuilds when the session database
changes, and returns date, title, and snippets. Open the source session only
when the snippet is insufficient. Codex transcripts are not indexed yet.

## Session protocol

1. Start: read Tier 0, the repo `AGENTS.md`, and the active plan.
2. Checkpoint: update the plan and handoff with decisions, files, and next.
3. Rollover: refresh the handoff before `session-handoff start`; re-read it in
   the new session.
4. End: write a digest (goal, outcome, decisions, files, open questions) and
   index it. Start a new session for the next task.
5. Never let a session hit its context limit without a handoff.

## Exclusions

One-off requests: just do them. Project conventions: repo `AGENTS.md`. Secrets:
never written anywhere. Transcripts: Tier 3 only; never paste them into Tier 0.

Setup and recovery on another machine: `~/dotfiles/docs/agent-memory.md`.
