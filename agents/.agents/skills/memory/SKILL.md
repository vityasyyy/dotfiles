---
name: memory
description: Use when persisting a durable preference or correction, deciding where a fact belongs, writing a handoff before compaction, or recalling past session context.
metadata:
  audience: ai-coding-agent
  workflow: memory
---

# Memory

Four tiers. One fact lives in exactly one tier. Retrieval is a query, never a
context dump. Workflow checkpoints are defined in `feature-workflow`; this
skill owns the tiers and the handoff template.

| Tier | Where | Budget | Holds |
|---|---|---|---|
| 0 | OpenCode: `~/.config/opencode/AGENTS.md` · Codex: `~/.codex/AGENTS.md` | ≤110 lines | invariants loaded every session |
| 1 | `<repo>/AGENTS.md` + `.opencode/memory/` | ≤80 lines | commands, conventions, gotchas |
| 2 | `<repo>/docs/plans/` | structured | active task state, decisions, next action |
| 3 | `~/.local/share/agent-memory/` | unbounded | session index + handoffs |

## Routing a fact

- Changes behavior every session → Tier 0. One terse bullet, merged into an
  existing section, never duplicated.
- True for this repo only → Tier 1.
- True for this task only → Tier 2.
- History, prior decisions, "where did we…" → Tier 3.

Never store secrets or credentials in any tier.

## Tier 0 rules

- Canonical sources are `~/dotfiles/opencode/.config/opencode/AGENTS.md` and
  `~/dotfiles/codex/.codex/AGENTS.md`; edit the source for your harness, not
  the `~` symlink.
- Match `## <Topic> (<date> — standing)`.
- Adding a rule requires deleting or merging one. The cap is the point.
- Do not commit Tier 0 edits without the user's approval; the user reviews
  dotfiles changes.

## Tier 2: handoff

Write the handoff at plan time and at every checkpoint, before compaction:

```markdown
# Handoff — <task>
Date:
Repo:
Branch:
Goal:
State: done | in progress | blocked
Decisions: what + why
Files: exact paths
Commands: worked / failed
Next: one next action
Open questions:
```

Store it with the task plan in `docs/plans/`, or in the handoff directory via
`mem handoff`. After compaction, re-read the handoff and the plan first; never
trust the summary alone.

## Tier 3: recall

```sh
MEM=~/.agents/skills/memory/scripts/mem
$MEM stats
$MEM search "query terms" --limit 10
$MEM sessions --limit 20
$MEM index
$MEM handoff --task "short title"
```

The index is FTS5 over OpenCode `session_message`, stored locally at
`~/.local/share/agent-memory/index.db`. It rebuilds automatically when the
session database changes. Search returns date, session title, and matching
snippets. Open the source session only when the snippet is insufficient.

The index currently covers OpenCode sessions. Codex transcripts are not
indexed yet; keep their handoffs in the plan or project memory.

## Session protocol

1. Start: read Tier 0, the repo `AGENTS.md`, and the active plan.
2. Checkpoint: update the plan and handoff with decisions, files, and next.
3. Compaction: refresh the handoff before `/compact`; re-read it after.
4. End: write a digest (goal, outcome, decisions, files, open questions) and
   index it. Start a new session for the next task.
5. Never let a session cross a compaction without a handoff.

## What does not qualify

- One-off requests: just do them.
- Project-specific conventions: repo `AGENTS.md`.
- Secrets: never written anywhere.
- Conversation transcripts: they stay in Tier 3; never paste them into Tier 0.

Setup and recovery on another machine: `~/dotfiles/docs/agent-memory.md`.
