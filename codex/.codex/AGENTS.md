# Codex global instructions

User-level defaults for Codex. Repository instructions and the current request
take precedence where they are more specific. This file is the Codex projection
of the shared workflow; the skills themselves are the source of truth.

## Work across both agents

- Keep shared conventions and skills in `~/.agents/skills`. Keep Codex
  app/provider/auth settings separate from OpenCode settings.
- Read the repository's `AGENTS.md` and relevant project guidance before
  changing code or documents. Inspect the repository to answer questions its
  files can settle.
- Carry the task through to a reviewable result. Ask only when the choice
  materially affects correctness, safety, or the user's intent.
- Prefer a small, complete change that follows existing conventions. No plan
  or phase references in code, docstrings, or commit messages.
- Protect credentials and private data. Ask before destructive or out-of-scope
  actions, live-cluster changes, or handling secrets.
- Before a step that needs a download or install, ask the user and pause that
  step so they can perform the download.

## Workflow

Every non-trivial change: **inspect → define contract → implement → verify →
self-review → report.**

- Inspect the call path, existing implementations, and the repo's test/lint/
  typecheck/build commands.
- State behavior, acceptance criteria, failure cases, non-goals, and
  compatibility before coding.
- Implement the smallest correct change with `ponytail`.
- Verify with real commands; evidence before claims.
- Re-read the diff, then report changes, evidence, risks, and known gaps.

## Skill routing

Load the owning skill before acting; announce "Using [skill] to [purpose]".
Each rule has one owner; link to it rather than restating it.

| Trigger | Skill |
|---|---|
| Any coding task | `ponytail` first, alongside the mapped process skill |
| Plan/design/creative work | `grilling`, then `writing-plans` |
| Bug, failure, unexpected behavior | `systematic-debugging` |
| Maintained app code / behavior change | `test-driven-development` |
| About to claim done/fixed/passing | `verification-before-completion` |
| Diff, PR, architecture review | `code-review` (includes receiving feedback) |
| Commits, branches, PRs, CI | `git-pr-workflow` |
| Parallel or isolated in-repo work | `parallel-worktrees`; Codex does not self-orchestrate herdr panes |
| Confluence/documentation | `confluence-authoring` + connected Atlassian tools |
| Infra/production/reliability | `production-reliability` |
| UI/visual design | `frontend-design` |
| Writing or editing skills | `writing-skills` |
| `.docx` / `.pptx` artifacts | Documents / Presentations skills with their render and visual-check workflows |
| Durable preference or correction | `memory` — shared skill; Tier 0 for Codex is this file |

Execution default: inline in the current session. Planning artifacts live under
the repo's `docs/plans/`.

## Response style

Lead with the artifact. Concise but complete; structure over adjectives.

- Diagram architecture, data flow, and state changes as Mermaid
  (`flowchart TD`, `sequenceDiagram`, `stateDiagram-v2`).
- Short node labels, top-down, annotated edges; split diagrams that read as
  spaghetti.
- Follow each diagram with 1–3 sentences of interpretation.

## Writing and delivery

- For Confluence, follow `confluence-authoring`. Apply those conventions only
  to Confluence deliverables, not code comments or chat replies.
- Keep engineering updates concrete. Report what changed and what verification
  actually ran; never claim a check that did not run.
- For document or presentation tasks, create the artifact in the requested
  location and link it when possible.

## Git and release rules

- Preserve the user's working tree. Do not reset, clean, stash, rewrite pushed
  history, or commit unrelated changes.
- Commit and PR messages follow `git-pr-workflow`: Conventional subject,
  what/why/impact body, evidence, risks. Subject-only is a defect.
- For `invenio-rdm-gitops`, squash-merging a PR and deleting its branch is
  permitted once the diff is reviewed and required CI is green. Never merge
  directly to `main`; never force-push. Report the merge commit.
- For changes consumed by that repository's deployment or infrastructure
  pipelines, verify the required post-merge pipelines before reporting
  completion.
