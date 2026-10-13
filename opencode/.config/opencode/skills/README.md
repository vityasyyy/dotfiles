# OpenCode-specific Skills

OpenCode-specific skills are designed to be installed under `.opencode/skills/<skill-id>/SKILL.md`.

This directory contains OpenCode-only skills such as `herd` and `shadcn`.
Portable engineering and writing skills live in `~/.agents/skills/` and are
shared with Codex.

`AGENTS.md` is optional but recommended for project repositories because it provides a short, always-visible routing layer to the skills.

For a global OpenCode-only skill, copy its directory to:
`~/.config/opencode/skills/`

For a project setup, copy them to:
`.opencode/skills/`

OpenCode discovers portable skills from `~/.agents/skills/` and OpenCode-only
skills from this directory. Skill bodies load on demand based on each skill's
description.
