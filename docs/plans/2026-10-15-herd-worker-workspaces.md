# Herd Worker Workspace Topology Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task in this session. Delegated/parallel execution goes through herd (herdr panes); do not spawn ad-hoc subagent chains. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `herd spawn` create a dedicated worker workspace labeled beneath the calling workspace by name, using the supported label fallback when native nesting is unavailable.

**Architecture:** Read the calling workspace label from Herdr, create a fresh workspace labeled `<parent>/<worker>`, and start the agent in that workspace's root pane without splitting or reusing a workspace. Update the herd playbook to match actual behavior and preserve the no-scattered-workspaces rule.

**Tech Stack:** Bash, Herdr CLI, Markdown.

## Global Constraints

- Do not create native parent-child relationships unsupported by the installed Herdr CLI.
- Do not reuse an existing workspace for a spawned worker.
- Do not close workspaces that this invocation did not create.
- Preserve existing uncommitted user changes.

---

### Task 1: Test and update worker workspace creation

**Files:**
- Modify: `opencode/.local/bin/herd`
- Test: `opencode/.local/bin/tests/herd-spawn.sh`

- [x] Add a shell test with a fake Herdr executable; assert spawn creates a labeled workspace and starts the agent in its root pane, with no pane split.
- [x] Run the test and confirm it fails against the existing split/reuse behavior.
- [x] Update `cmd_spawn` to derive the parent label from `HERDR_WORKSPACE_ID`, create a dedicated `<parent>/<worker>` workspace, and start the worker in the returned root pane.
- [x] Run the test and confirm it passes.

### Task 2: Align the orchestration playbook

**Files:**
- Modify: `opencode/.config/opencode/skills/herd/SKILL.md`

- [x] Document that each worker gets a new Herdr workspace, labeled with its parent prefix; explicitly note native nesting is not exposed by this CLI and panes are not split in the parent workspace.
- [x] Run the shell test and `bash -n opencode/.local/bin/herd`.
