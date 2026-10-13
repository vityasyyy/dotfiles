---
name: confluence-authoring
description: Write, revise, or publish Confluence technical pages and briefs using the user's house style, structure, diagrams, and source conventions.
---

# Confluence authoring

Use this skill for Confluence pages and briefs. It applies to drafts and published pages, whether work is performed by a lead agent or delegated worker.

## Voice and sources

- Write neutral technical documentation in descriptive third person. Do not mention agents, drafting process, tool calls, or where open questions are tracked.
- Do not use inline citation codes such as `[101:…]`, `[Arch:…]`, or `[DOCX:…]`. Put named source links in a References section.
- Do not include local machine paths or filenames. If a source has no URL, identify it as `Source name (link TBD — confirm)` and ask for its URL when needed.
- Use tables before prose for comparisons, mappings, and per-instance rules. Keep status values short and use expand macros for deep detail when appropriate.

## Page structure

Use the relevant parts of this structure; tailor it to the page rather than padding a short page:

1. Metadata table: spec writer, reviewer, epic link.
2. Overview, goals, and scope.
3. Dated decisions, marked `supersedes` when replacing earlier text.
4. Stakeholders, including relevant Slack channels.
5. Testable acceptance criteria.
6. Risks and mitigations table.
7. Numbered flows.
8. Components and effort table.
9. Schema and interface tables where applicable.
10. Deployment guidance.
11. Open questions with owners.
12. Named References links.

For long pages, include a table of contents and changelog in expand macros.

## Diagrams

- Use Mermaid in chat, plans, PRs, and editor tooling. Prefer `flowchart TD` or `flowchart LR` for architecture and `sequenceDiagram` for request flows. For a large architecture, show the backbone and provide a connection table.
- A published Confluence page must contain a rendered diagram, not a raw Mermaid code block. Keep the `.mmd` source with the project's documentation. Render to SVG with an already available local renderer or an approved diagram rendering service, then attach and embed the image using the connected Confluence tooling. Do not assume OpenCode-specific tool names; use the tools available in the current agent.
- Caption rendered figures `Figure N — <name>.` and add a one-line reading note.

## Updates and announcements

- For significant page updates, update the changelog and prepare an announcement for the owning team's Slack channel.
- Send the Slack announcement only when the user has explicitly authorized sending it. Otherwise provide the draft for review.
