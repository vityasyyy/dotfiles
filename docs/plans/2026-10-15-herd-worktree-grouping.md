# Herd Worker Worktree Grouping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task in this session. Delegated/parallel execution goes through herd (herdr panes); do not spawn ad-hoc subagent chains. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Group worker workspaces beneath the parent repo when `herd spawn` targets an existing linked Git worktree, while retaining flat prefixed-label workspaces for other paths.

**Architecture:** `herd spawn` checks the parent workspace's Herdr worktree list for an exact linked-worktree path. A match is registered with `herdr worktree open`; otherwise spawn uses `herdr workspace create`. Both start the agent in the returned root pane, and cleanup closes only a workspace created by that invocation.

**Tech Stack:** Bash, Herdr CLI, shell regression test with a fake Herdr executable.

## Global Constraints

- Always use a dedicated workspace; do not split the lead workspace pane.
- Keep focus on the caller with `--no-focus`.
- Use Herdr's native grouping only for a linked worktree in the parent repo; keep `<parent>/<worker>` labels as the fallback.
- Match the canonical cwd exactly; nested subdirectories do not count as a worktree-root match.
- Never close a workspace that existed before this spawn invocation.
- Preserve running agents and Git checkouts while grouping existing workspaces.

---

### Task 1: Add regression tests for grouped and fallback spawns

**Files:**
- Modify: `opencode/.local/bin/tests/herd-spawn.sh`

**Interfaces:**
- The fake `herdr worktree list --workspace <id>` returns `result.worktrees` entries with `path` and `is_linked_worktree`.
- The fake `herdr worktree open` returns `result.workspace.workspace_id`, `result.root_pane.pane_id`, and `result.already_open`.

- [x] Extend the fake Herdr command to return a matching linked worktree, a matching non-linked worktree, no match, worktree-list failure, and whether `worktree open` reused an existing workspace.
- [x] Assert that a matching path runs `worktree open --workspace w1 --path "$linked" --label worker --no-focus`, then starts the agent in the returned root pane without calling `workspace create` or `pane split`.
- [x] Assert that a nonmatching path uses `workspace create --cwd "$fallback" --label parent/worker --no-focus` and starts the agent in that root pane.
- [x] Assert that a worktree-open error is returned without falling through to `workspace create`.
- [x] Add a start-failure case where `worktree open` reports `already_open=true`; assert that `workspace close` is not called. Add a newly-opened case (`already_open=false`) to assert failed startup still closes the workspace created by this invocation.
- [x] Run `bash opencode/.local/bin/tests/herd-spawn.sh`; confirm the new linked-worktree assertion fails against the current `workspace create` implementation.

### Task 2: Register linked checkouts and preserve safe cleanup

**Files:**
- Modify: `opencode/.local/bin/herd`
- Test: `opencode/.local/bin/tests/herd-spawn.sh`

**Interfaces:**
- Input: worker name, canonical cwd, and caller `HERDR_WORKSPACE_ID`.
- Output: workspace ID and root pane ID from either `worktree.opened` or `workspace.created`.

- [x] Query `herdr worktree list --workspace "$parent_ws"` and match only an entry whose `path` equals the canonical cwd and whose `is_linked_worktree` is true.
- [x] If worktree listing fails or no entry matches, use the standalone-workspace fallback. If `worktree open` fails after a match, surface that error and do not attempt a second workspace creation.
- [x] For a match, call `herdr worktree open --workspace "$parent_ws" --path "$cwd" --label "$name" --no-focus`; otherwise keep the prefixed-label `workspace create` path.
- [x] Parse the returned workspace and root pane from either response. Track whether the target existed before this invocation using `already_open` for `worktree open` and the known-created state for `workspace create`.
- [x] On agent-start failure, close the workspace only when this invocation created it; leave pre-existing workspaces intact.
- [x] Run `bash opencode/.local/bin/tests/herd-spawn.sh` and `bash -n opencode/.local/bin/herd`.

### Task 3: Document the topology and group current workers

**Files:**
- Modify: `opencode/.config/opencode/skills/herd/SKILL.md`

- [x] Document native worktree grouping for linked worker checkouts and the prefixed-label fallback for other paths. State that Herdr does not support arbitrary nested workspaces.
- [x] Run the regression test and shell syntax check again, then inspect the complete diff.
- [x] In the default Herdr session, run `herdr --session default worktree open --workspace w3V --path /Users/miapalovaara/invenio-rdm-gitops/.worktrees/feat/137-stability-audit --label invenio-audit --no-focus` and `herdr --session default worktree open --workspace w3V --path /Users/miapalovaara/invenio-rdm-gitops/.worktrees/fix/137-planning-cleanup --label planning-cleanup --no-focus`. Do not restart agents or change checkouts.
- [x] Verify `herdr --session default api snapshot` reports worktree provenance for both workers, `herdr --session default worktree list --cwd /Users/miapalovaara/invenio-rdm-gitops` maps them to existing workspaces, and both panes still run OpenCode.

### Task 4: Commit and hand off

- [x] Review `git diff --check`, `git status`, and the staged diff; stage the implementation plan, wrapper, test, and herd playbook, then commit them with `git commit -m "fix(herd): group linked worker workspaces"`.
- [x] Report the exact local checks and live-session verification performed. Do not claim a CI/PR result unless one was actually run.
