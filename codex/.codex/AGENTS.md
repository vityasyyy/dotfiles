# Codex global instructions

These are user-level defaults for Codex. Repository instructions and the user's current request take precedence where they are more specific.

## Work across both agents

- OpenCode remains an independent, supported workflow. Keep shared conventions in `~/.agents/skills`; keep Codex app/provider/auth settings separate from OpenCode settings.
- Read the current repository's `AGENTS.md` and relevant project guidance before changing code or documents. Inspect the repository to answer questions that can be settled from its files.
- Carry the requested task through to a useful, reviewable result. Make reasonable assumptions when the repository or conversation answers them; ask only when the choice materially affects correctness, safety, or the user's intent.
- Prefer a small, complete change that follows existing conventions. Do not put plan or phase references into code comments, docstrings, or commit messages.
- Protect credentials and private data. Ask before destructive or out-of-scope actions, actions affecting a live cluster, or handling secrets.
- Before a step that requires downloading or installing a tool or release binary, ask the user and pause that dependent step so they can perform the download; continue independent work where useful.

## Skill routing

- For coding, follow `ponytail` for minimal, deliberate implementation. For non-trivial changes, also use `engineering-core` and `feature-workflow`; use `production-reliability` for production, infrastructure, persistence, deployment, or reliability work.
- For reviews, use `code-review`. For branch and pull-request work, use `git-pr-workflow`. For concurrent write-capable work in one repository, use `parallel-worktrees` and isolate each worker in its own worktree.
- Use `frontend-design` for meaningful UI design work. Use `herdr` only when Herdr is requested or is the chosen interface for the task.
- For `.docx` work, use the available Documents skill; for `.pptx` work, use the available Presentations skill. Use their artifact-specific render and visual-check workflows. For Confluence pages, load `confluence-authoring` and use the connected Atlassian tools available in this session.
- A skill is guidance, not a reason to ignore the user's explicit request or to repeat a question already answered.

## Writing and delivery

- For Confluence, follow the shared `confluence-authoring` skill. Apply those conventions only to Confluence deliverables, not ordinary code comments or chat replies.
- Keep engineering updates concise and concrete. Report what changed and verification actually performed; do not claim a check ran when it did not.
- For document or presentation tasks, create the requested artifact in the requested location and show or link the finished file when possible.

## Git and release rules

- Preserve the user's working tree. Do not reset, clean, stash, rewrite pushed history, or commit unrelated changes.
- For `invenio-rdm-gitops`, the standing user rule permits squash-merging a pull request and deleting its branch once the diff is reviewed and required CI is green. Never merge directly to `main`; never force-push. Report the merge commit and what it contains.
- For changes consumed by deployment or infrastructure pipelines in that repository, follow its production verification guidance and verify required post-merge pipelines before reporting completion.
