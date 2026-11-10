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
- Prefer a small, complete change that follows existing conventions. Repo docs
  describe current behavior, link existing paths and URLs, and carry no plan
  artifacts, dated history, or task checklists.
- Protect credentials and private data. Ask before destructive or out-of-scope
  actions, live-cluster changes, or handling secrets.
- Before a step that needs a download or install, ask the user and pause that
  step so they can perform the download.
- Ask before destructive commands, production/staging changes, deploys,
  migrations, or secrets. Routine read-only diagnostics are pre-authorized.

## Workflow

Every non-trivial change: **inspect → define contract → implement → verify →
review → report.**

- Inspect the call path, existing implementations, and the repo's test/lint/
  typecheck/build commands.
- State behavior, acceptance criteria, failure cases, non-goals, and
  compatibility before coding; fix the review gate here.
- Implement the smallest correct change with `ponytail`.
- Verify with real commands; evidence before claims.
- Review in a fresh session against the fixed gate (`code-review`); fix blockers
  or push back with evidence. Never self-approve.
- Report changes, evidence, risks, and known gaps.

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
| Diff, PR, architecture review | `code-review` in a fresh session |
| Commits, branches, PRs, CI | `git-pr-workflow` |
| Parallel or isolated in-repo work | `parallel-worktrees`; Codex does not self-orchestrate herdr panes |
| Documentation | `documentation`; Confluence via connected Atlassian tools |
| Infra/production/reliability | `production-reliability` |
| UI/visual design | `frontend-design` |
| Writing or editing skills | `writing-skills` |
| `.docx` / `.pptx` artifacts | Documents / Presentations skills with their render and visual-check workflows |
| Durable preference or correction | `memory` — shared skill; Tier 0 for Codex is this file |

Execution default: inline in the current session. Create repo planning/summary
Markdown only when the user asks; keep task state in agent-memory. A
`docs/plans/` copy is gitignored and never committed.

## Response style

Lead with the artifact. Concise but complete; structure over adjectives.

- Diagram architecture, data flow, and state changes as Mermaid
  (`flowchart TD`, `sequenceDiagram`, `stateDiagram-v2`).
- Short node labels, top-down, annotated edges; split diagrams that read as
  spaghetti.
- Follow each diagram with 1–3 sentences of interpretation.

## Writing and delivery

- Follow `documentation` for human-facing docs: READMEs, runbooks, design
  docs, ADRs, PR bodies, and Confluence. Do not apply it to code comments or
  chat replies.
- Keep engineering updates concrete. Report what changed and what verification
  actually ran; never claim a check that did not run.
- For document or presentation tasks, create the artifact in the requested
  location and link it when possible.

## Git and release rules

- Preserve the user's working tree. Do not reset, clean, stash, rewrite pushed
  history, or commit unrelated changes.
- Commit and PR messages follow `git-pr-workflow`: Conventional subject,
  what/why/impact body, evidence, risks; behavior + tests land in one commit.
  Subject-only is a defect.
- For `invenio-rdm-gitops`, squash-merging a PR and deleting its branch is
  permitted once the diff is reviewed and required CI is green. Never merge
  directly to `main`; never force-push. Report the merge commit.
- For changes consumed by that repository's deployment or infrastructure
  pipelines, verify the required post-merge pipelines before reporting
  completion.
