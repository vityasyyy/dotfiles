---
name: handoff
description: Use when a session nears its context limit (the 80% context-rollover warning), at the end of a long task, before handing work to another agent or session, or when the user asks for a handoff. Infers the handoff from the session's evidence, archives the transcript, and continues in a fresh session.
metadata:
  audience: ai-coding-agent
  workflow: handoff
---

# Handoff

Compaction is disabled. Roll over instead: infer the state from evidence, write
it down, archive the transcript, and continue in a fresh session. The old
session is never mutated; nothing is summarized away.

## Trigger

- The `context-rollover` plugin warns that the window is at 80% or 90%.
- The user runs `/handoff`.
- The task is done, or the user is about to switch tasks or agents.
- You are about to finish a long session.

Do not wait for the hard limit. At the limit the provider rejects the request
and the session stops.

## Steps

1. **Gather evidence.** Never invent state.
   - Goal, acceptance, and review gate: from the task plan or conversation.
   - Repository: `git status --short`, `git diff --stat`, `git log -1 --oneline`.
   - Files: exact paths you changed or read, and why.
   - Commands: what passed, what failed, what was not run.
   - Open questions: only real blockers.
2. **Write the handoff** with
   `~/.agents/skills/memory/scripts/mem handoff --task "<task>"` and fill the
   scaffolded template in place. It writes to
   `~/.local/share/agent-memory/handoffs/YYYY-MM-DD-<slug>.md`.
   Aim for under 80 lines; the successor can search the transcript for detail.
   A handoff is operational, not a planning/summary document; do not create
   additional Markdown.
3. **Roll over.** In OpenCode:

   ```sh
   ~/.agents/skills/handoff/scripts/session-handoff start --handoff <path>
   ```

   The script exports the full transcript, appends session pointers to the
   handoff, creates a successor session with the same agent and model, and
   seeds it. It prints the new session id and title. In Claude Code or Codex,
   tell the user to start a fresh session from the handoff; do not call the
   script.
4. **Report and stop.** OpenCode reports the successor session id and title;
   Claude Code and Codex report the handoff path and tell the user to start a
   fresh session from it. Do not start new work in the old session.

## Harness

`session-handoff start` is OpenCode-only. Every harness writes the handoff with
`mem handoff`; only OpenCode creates the successor session automatically. Stop
work in the old session once the handoff is written.

## Template

Owned by `memory` (Tier 2: task state and handoff); scaffold it with
`~/.agents/skills/memory/scripts/mem handoff --task "<task>"` instead of
copying it here.

## Inference rules

- Separate what you verified from what you assume. Mark assumptions.
- Record decisions with their reason, not just the outcome.
- Record the next action as one concrete step, not a plan.
- Include failures and dead ends; they save the successor a retry.
- Never include secrets, credentials, or prompt dumps.
- If you cannot infer a field, write `unknown` rather than guessing.

## Failure

If the script fails, stop and surface the error. Do not create a second
successor session and do not continue work in the old one.

## Related

- `memory` owns the tiers and the handoff template.
- Tier 3 history: `~/.agents/skills/memory/scripts/mem search "<terms>"`.
