# Codex global instructions

These are user-level defaults for Codex. Repository instructions and the user's current request take precedence where they are more specific.

## Work across both agents

- OpenCode remains an independent, supported workflow. Keep shared conventions in `~/.agents/skills`; keep Codex app/provider/auth settings separate from OpenCode settings.
- Read the current repository's `AGENTS.md` and relevant project guidance before changing code or documents. Inspect the repository to answer questions that can be settled from its files.
- Carry the requested task through to a useful, reviewable result. Make reasonable assumptions when the repository or conversation answers them; ask only when the choice materially affects correctness, safety, or the user's intent.
- Prefer a small, complete change that follows existing conventions. Do not put plan or phase references into code comments, docstrings, or commit messages.
- Protect credentials and private data. Ask before destructive or out-of-scope actions, actions affecting a live cluster, or handling secrets.
- Before a step that requires downloading or installing a tool or release binary, ask the user and pause that dependent step so they can perform the download; continue independent work where useful.

## Skill routing (2026-10-13 — standing, mirrored from OpenCode)

Invoke the matching skill BEFORE acting; announce "Using [skill] to [purpose]".
One router: this table. Raise clarifying decisions through native question
tooling when the harness exposes it, inline otherwise.

| Trigger | Skill |
|---|---|
| Any coding task (writing, fixing, refactoring, reviewing, deps) | `ponytail` first — alongside the mapped process skill, never instead of it |
| Plan/design/creative work of any size | `grilling` first (interview rounds to shared understanding), then `brainstorming` → `writing-plans` → `executing-plans` |
| Any bug, failure, or unexpected behavior | `systematic-debugging` before proposing fixes |
| Implementing maintained app code / behavior changes | `test-driven-development` (triage gate inside the skill covers skippable cases) |
| About to claim done/fixed/passing | `verification-before-completion` — evidence before assertions |
| Reviewing diffs/PRs/architecture | `code-review`; when receiving review feedback → `receiving-code-review` |
| Commits, branches, PRs, CI | `git-pr-workflow` |
| Parallel or isolated in-repo work | `parallel-worktrees`; herdr orchestration only when a lead agent directs it — Codex does not self-orchestrate panes |
| Confluence/documentation work | `confluence-authoring` and the connected Atlassian tools in this session |
| Infra/production/reliability work | `production-reliability` |
| UI/visual design work | `frontend-design` |
| Writing or editing skills | `writing-skills` |
| `.docx` / `.pptx` artifacts | Documents / Presentations skills with their render and visual-check workflows |
| User states a durable preference/correction | `memory` — persist it as a dated standing-rule entry in this file |

Execution default: inline in the current session. Planning artifacts (specs,
plans, ADRs) live under the repo's `docs/plans/`.

## Response style (2026-10-13 — standing, mirrored from OpenCode)

Lead with the artifact, not prose. Concise but complete — detail lives in
structure, not adjectives.

- Diagram any architecture, data flow, or state change as Mermaid:
  `flowchart TD` / `sequenceDiagram` / `stateDiagram-v2`.
- Keep diagrams human-readable: short node labels, top-to-bottom layout,
  annotated edges, no spaghetti. If it reads as noodles, split it.
- Follow every diagram with 1–3 sentences interpreting it; don't assume the
  picture speaks for itself.
- Render-first: when the target surface renders Mermaid (Confluence, PR
  markdown), prefer rendered diagrams over ASCII art; in plain terminals,
  pair the Mermaid block with the verbal interpretation.

## Writing and delivery

## Writing and delivery

- For Confluence, follow the shared `confluence-authoring` skill. Apply those conventions only to Confluence deliverables, not ordinary code comments or chat replies.
- Keep engineering updates concise and concrete. Report what changed and verification actually performed; do not claim a check ran when it did not.
- For document or presentation tasks, create the requested artifact in the requested location and show or link the finished file when possible.

## Git and release rules

- Preserve the user's working tree. Do not reset, clean, stash, rewrite pushed history, or commit unrelated changes.
- For `invenio-rdm-gitops`, the standing user rule permits squash-merging a pull request and deleting its branch once the diff is reviewed and required CI is green. Never merge directly to `main`; never force-push. Report the merge commit and what it contains.
- For changes consumed by deployment or infrastructure pipelines in that repository, follow its production verification guidance and verify required post-merge pipelines before reporting completion.
