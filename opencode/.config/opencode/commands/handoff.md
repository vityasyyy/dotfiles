---
description: Write an inferred handoff and continue in a fresh session
---

Use the `handoff` skill to roll this session over. Infer the handoff from this
session's evidence for $ARGUMENTS (or the current task if no argument was
given), write it with `~/.agents/skills/handoff/scripts/session-handoff path
--task "<short title>"`, then run `session-handoff start --handoff <path>`.
Report the successor session id and title, then stop working in this session.
