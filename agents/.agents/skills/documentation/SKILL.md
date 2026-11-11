---
name: documentation
description: >-
  Use when writing, revising, or publishing human-facing technical documentation:
  READMEs, runbooks, design docs, ADRs, PR descriptions, and Confluence pages.
  Enforces current-state docs, navigable references, house structure, Mermaid
  diagrams, and source conventions.
---

# Documentation

Use this skill for human-facing technical docs: READMEs, runbooks, design
docs, ADRs, PR descriptions, and Confluence pages. It applies to drafts and
published pages, whether a lead agent or delegated worker writes them. It does
not cover code comments, chat replies, or agent instruction files.

## Current state only

- Describe what exists and how to use it. Do not narrate delivery stages, task
  lists, dated plans, or development history.
- Git history and PR descriptions are the decision record. Do not duplicate
  them in a doc body.
- If a decision outlives the task, fold it into the current design or
  architecture section, not a separate decisions log.
- Do not add a dated change log or old-patterns section to a repo doc; the
  platform's history view already holds that.

## Links

Link every durable reference; leave executable snippets as code.

- Repo file or directory: [`path/to/file`](relative/path), resolved from the
  current document.
- External resource: [short label](https://example.com).
- Section reference: [§N](#anchor).
- Home path with a repo source: link the source, e.g.
  [`agents/.agents/AGENTS.md`](../../AGENTS.md)
  (repo-relative; adjust for the document's location).
- Confluence: use inline links or a References section with absolute URLs.
- Do not link commands, flags, environment variables, keybindings, secret
  paths, runtime-only paths, or anything inside a code fence.
- Never invent a URL. If a source has no URL, write
  `Source name (link TBD — confirm)` and ask for it.

Verify relative links and anchors with `scripts/check-doc-links.py` when the
repository provides it. External URLs are checked manually, not in blocking CI.

## Structure

Use the relevant parts; tailor to the doc rather than padding a short page:

1. TL;DR: what this is, who it is for, and the outcome.
2. Prerequisites and scope.
3. Current-state body: concepts, flows, tables, and examples.
4. Verification: commands or checks the reader can run.
5. References: named sources with links.

For a runbook, lead with the trigger and the exact commands. For an ADR, state
the decision, the forces, and the consequences in present tense. For a PR body,
follow [`git-pr-workflow`](../git-pr-workflow/SKILL.md) and link changed files,
design docs, and dashboards.

## Office formats

`.docx` and `.pptx` use the harness's document tooling, including its render
and visual-check workflow. Verify the rendered artifact, not just the source.

## Voice

- Write neutral technical prose in descriptive third person.
- Do not mention agents, drafting process, tool calls, or where open questions
  are tracked.
- Do not use inline citation codes such as `[101:…]`, `[Arch:…]`, or
  `[DOCX:…]`. Use named source links.
- Prefer tables for comparisons, mappings, and per-instance rules.
- Keep status values short.

## Diagrams

- Use Mermaid in chat, Markdown docs, plans, and PRs. Prefer `flowchart TD` or
  `flowchart LR` for architecture and `sequenceDiagram` for request flows.
- For a large architecture, show the backbone and provide a connection table.
- A published Confluence page must contain a rendered diagram, not a raw Mermaid
  code block. Keep the `.mmd` source with the project's documentation. Render
  to SVG with an available local renderer or an approved service, then attach
  and embed the image with the connected Confluence tooling.
- Caption rendered figures `Figure N — <name>.` and add a one-line reading note.

## Confluence pages

- Follow the structure above; add a metadata table with writer, reviewer, and
  related work item.
- Use the platform's page history instead of a dated change log section.
- Include stakeholder channels, testable acceptance criteria, risks, flows,
  components, schema/interface tables, deployment guidance, and open questions
  when the page needs them. Do not pad a short page.
- For significant updates, prepare a Slack announcement; send it only after
  explicit authorization.

## Verification

- Relative links and anchors resolve.
- No planning or history sections, and no dated artifacts.
- Commands are copy-pasteable; code fences are intentional.
- The doc names its audience and verification path.
