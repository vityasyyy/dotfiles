---
name: codebase-explainer
description: Use when asked to explain, understand, onboard onto, map, or trace an unfamiliar codebase, module, or feature. Produces an evidence-based architecture map with Mermaid diagrams and path:line references. Not for code review or implementation.
metadata:
  audience: ai-coding-agent
  workflow: understanding
---

# Codebase Explainer

Read-only. Build the smallest accurate model that answers the question. Do not
review, plan, or change code. `feature-workflow` owns implementation,
`code-review` owns critique, and the native `explore` subagent owns targeted
lookups.

## Pick the mode

| Mode | Trigger | Stop when |
|---|---|---|
| `orient` (default) | "explain this repo/module" | top-level map, entry points, and next places to read |
| `trace <feature>` | "how does X work" | one flow traced end-to-end, success and failure |
| `deep` | "deep dive", "onboard me" | architecture, state, reliability, conventions, change guide |

If the target is unclear, ask one question: repo, subsystem, or feature? Start
with the narrowest scope that answers it. A whole-repo request still gets an
orient pass first; offer `trace` or `deep` instead of reading everything.

## 1. Recon

- Read README, manifests, config, entry points, CI, and tests.
- Record languages/frameworks, run/build/test commands, and major modules.
- Treat docs as claims; verify them against code.
- Search for symbols and call sites before opening files.

## 2. Map

- Find module boundaries, dependency direction, and state ownership.
- Compare the documented design with the code; call out divergence.
- Follow one representative call path per major component.
- Read the smallest set of files that proves the map; stop when it holds.

## 3. Trace

For `trace` and `deep`, follow the selected operation:

entry -> validation -> auth -> business logic -> persistence -> side effects -> output.

- Trace one success path and one failure path.
- Note security boundaries, transaction boundaries, retries, idempotency,
  timeouts, and observability.
- For `deep`, also cover concurrency, recovery, test organization, fixtures,
  mocking, and the conventions a change must follow.

## 4. Report

Use this shape; scale section depth to the mode.

1. **60-second summary** — purpose, stack, and the one boundary that matters.
2. **Architecture diagram** — Mermaid `flowchart TD`, short labels, annotated edges.
3. **Module map** — component | responsibility | key files/symbols.
4. **Runtime lifecycle** — startup, request/command path, shutdown.
5. **Critical flows** — `sequenceDiagram`; success and failure paths.
6. **State and data ownership** — who owns what, consistency boundaries.
7. **Change guide** — where to add behavior, which tests/commands to run.
8. **Unknowns** — `[verified]`, `[inferred]`, and missing evidence.

Every verified claim cites `path:line` plus a symbol. Mark inferences
`[inferred]`; never present them as facts. After each diagram, add 1-3
sentences of interpretation.

## Rules

- No edits, destructive commands, or secrets.
- Do not turn findings into review comments; hand critique to `code-review`.
- Do not dump files or summarize code that does not affect the answer.
- Do not infer architecture from framework conventions; confirm it in code.
- If a claim needs a fact you have not read, say what is missing and how to verify it.
- Optional: write `docs/codebase-map.md` only when the user asks; include the
  commit SHA and date.
