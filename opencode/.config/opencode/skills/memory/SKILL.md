---
name: memory
description: Use when the user states a durable preference, standing rule, or correction worth remembering across sessions — persist it to the operator's AGENTS.md as a dated standing-rule entry
metadata:
  audience: ai-coding-agent
  workflow: memory
---

# Memory

Persist durable user preferences so no agent has to be told twice.

## The Rule

When the user states a preference, standing instruction, correction, or environmental fact that should outlive this session:

1. Append it to `~/.config/opencode/AGENTS.md` (canonical source: `~/dotfiles/opencode/.config/opencode/AGENTS.md`).
2. State in one line that you saved it.
3. Continue the task.

Don't create memory files elsewhere, don't restate it in chat prose, don't store conversation history — only durable rules.

## What qualifies

- Style preferences ("always mermaid diagrams", "concise explanations")
- Workflow standing rules ("run X before Y", "never touch Z")
- Corrections of agent behavior ("I said don't do X")
- Environment facts ("slow network — ask before downloads")

## What does NOT qualify

- Task-specific details → the plan doc
- One-off requests → just do the thing
- Secrets/credentials → never written to AGENTS.md or any file
- Project-specific conventions → the repo's own `AGENTS.md`, not global

## Editing rules

- Match the existing pattern: `## <Topic> (<date> — standing)`
- Merge into an existing section when the topic already exists; never duplicate sections
- One preference, one terse bullet — these are read every session; keep them tight
- Do not commit; the user reviews dotfiles changes themselves
