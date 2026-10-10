# Global operator preferences

Owner: vityasyyy. Standing instructions from 2026-09-15 — these override any
skill or convention that says otherwise. Reconfirm if they ever look unsafe.

## Large downloads (2026-10-10 — standing)

Local network here downloads slowly. When a step requires downloading or
installing anything (tool installs, updates, release binaries), ask the user
and END the chat first so they can run the download on their machine; resume
the task only after they confirm the file is in place.

## PR merges (invenio-rdm-gitops)

When CI is green on a pull request, squash-merge it and delete the branch
WITHOUT asking for per-PR approval first.

Standing rules that still apply every time:
- Verify first: read the diff and confirm CI status myself
  (`verification-before-completion`) — never merge red or unknown CI.
- Never merge directly to main; squash-merge only (`gh pr merge --squash`).
- If the merge fails (e.g. BEHIND base, conflicts), fix forward or report —
  do not force-push.
- Report each merge (commit SHA, what rode along).

## Worker approvals (herd)

Auto-clear routine sandbox prompts on the operator's behalf: external-directory
access under `/tmp`, `~/.local/bin`, and worktrees, plus the planned tool
installs/downloads in the approved brief (promtool, amtool, crane, helm pulls,
pinned-image pulls).

Still escalate to the user first: secrets/credentials, destructive or
out-of-scope actions, anything affecting the cluster, and ambiguous decisions.

## Confluence docs conventions (2026-10-01 — standing, do not re-ask)

Every Confluence page/brief drafted by any agent (lead or worker) must:

- Read as neutral tech docs (mirror Channel Activations 101 / Admin Dashboard
  Channel Approval/Activations voice): descriptive third person, no first
  person, no agent-talk. NEVER write meta lines like "workers wrote…",
  "this draft covers…", "open questions live at…", or tool-call narratives.
- NEVER emit inline citation codes ([101:…], [Arch:…], [DOCX:…]). Sources go
  in a References section as named page links. Body prose stays clean.
- NEVER reference local machine paths (~/Downloads, /tmp, .docx/.png
  filenames). If a source has no URL, write the source name with "(link TBD —
  confirm)" and ask the user for the URL instead of citing the local file.
- Page skeleton (mirror Channel Activation: Tech Architecture): metadata
  table (spec writer, reviewer, epic link) → Overview → Goals → decisions
  (dated, marked "supersedes" when they override earlier text) → Scope →
  Stakeholders (with Slack channels) → Acceptance criteria (testable bullets)
  → Risks and mitigations (table) → Flows (numbered steps) → Components and
  effort (table) → schemas and interfaces (tables) → Deploy → Open questions
  WITH owners → References (named page links). On long pages keep TOC and
  changelog in expand macros.
- Diagrams: use Mermaid code fences by default everywhere (Argya Vityasy
  preference, 2026-10-09 — supersedes the earlier SVG/ASCII rule from
  2026-10-01). In chat, plans, PRs and editor tooling Mermaid renders natively;
  use `flowchart` (TD/LR) for architecture and `sequenceDiagram` for request
  flows. Split large architectures into a backbone diagram plus a connection
  table. ASCII box-and-arrow is only a last resort if Mermaid syntax cannot
  express it.
- RENDERED DIAGRAMS IN DOCS (2026-10-09 — Argya Vityasy standing rule): what
  lands in documents is the RENDERED diagram, not the Mermaid source. Pipeline,
  proven on 2026-10-09: (1) write `<name>.mmd` source files; (2) render to SVG
  via mermaid.ink (`$ B64=$(base64 -i f.mmd | tr -d '=' | tr '+' '-' | tr '/'
  '_'); curl -s "https://mermaid.ink/svg/$B64" -o f.svg`) or kroki.io
  (`curl --data-binary @f.mmd -H "Content-Type: text/plain" -o f.svg
  https://kroki.io/mermaid/svg`) or mermaid-cli (`npx -y
  @mermaid-js/mermaid-cli -i f.mmd -o f.svg`) — mermaid.ink/kroki need no
  browser download; (3) attach the SVG to the target Confluence page via
  createConfluenceAttachment (returns a short-lived curl uploadCommand — run
  it from bash, keep tokens out of logs); (4) embed with the media-single
  figure pattern using the attachment's `fileId` UUID + collection
  `contentId-<pageId>`, with `<figcaption>` "Figure N — <name>." plus a
  one-line reading note; (5) keep the .mmd sources on disk under the project
  docs dir. Never embed raw Mermaid code fences into a published Confluence
  page again — the render-first rule replaces that interim behavior.
- Tables before prose for comparisons, mappings, and per-instance rules;
  status enums as short lozenge-like values; use expands to hide deep detail
  a reader opens on demand. For significant page updates: update the changelog
  and announce in the owning team's Slack channel (Remittance "How to
  Document" update checklist).
- Worker briefs must include this section by reference so workers comply
  without being told twice.

## Code hygiene (2026-10-08 — standing, do not re-ask)

- NEVER let plan artifacts leak into code: no "based on step N", "per phase
  N", "task N", or checkpoint/stage references in code comments, JSDoc,
  docstrings, or commit messages — code documents itself in the codebase's
  own terms. Plan structure belongs in the plan doc / PR description only.
- Invoke `ponytail` before ANY coding task (writing, fixing, refactoring,
  reviewing code, choosing dependencies) — lead and workers alike. It runs
  alongside the mapped process skill (e.g. `systematic-debugging`,
  `feature-workflow`), never instead of it.
