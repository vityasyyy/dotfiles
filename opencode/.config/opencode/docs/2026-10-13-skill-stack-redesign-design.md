# Skill stack redesign — 2026-10-13

Owner: vityasyyy · Decided in a grilling session this same day.

## Problem

1. **9 of 13 local skills were dead on arrival.** The 2026-10-13 dotfiles
   restructure ("feat: share agent workflows with Codex") moved skills from
   `opencode/.config/opencode/skills/` to `agents/.agents/skills/` without
   re-running `install.sh`, leaving stale symlinks in
   `~/.config/opencode/skills/` pointing at deleted sources. The AGENTS.md
   trigger map referenced skills that were literally unreadable files.
   Root cause of "skills are not invoked enough".
2. **~33 nominal skills with overlapping trigger zones** (plans, reviews,
   parallelism, grills each had 2–3 claimants), a 2.2k-token superpowers
   bootstrap injected every session, and a trigger map mandating chained
   skill loads on every task.
3. **Stale/risky plugins:** `opencode-antigravity-auth` (archived upstream,
   accounts flagged per 2026-10 reporting), `opencil-pencil-sync` (dead
   upstream), Figma + Atlassian MCP always in context though rarely used.

## Decisions

| # | Decision | Rationale |
|---|---|---|
| 1 | Drop the superpowers plugin; fork its 8 highest-value skills into the shared dotfiles skill farm (MIT attribution kept) | Kills the per-session bootstrap, frees trigger routing to AGENTS.md, keeps upstream-tested discipline. The plugin is not necessary; the skills are. |
| 2 | herdr is the primary orchestrator; `subagent-driven-development` and `dispatching-parallel-agents` are dropped, not demoted | The user orchestrates via herdr panes; a second delegation doctrine is redundant |
| 3 | TDD fork gets a triage gate: mandatory for maintained app code/behavior changes, explicitly skippable (stated, not silent) for throwaway scripts, prototypes, config/YAML/docs, trivial fixes | Measured evidence: ceremony pays on medium/complex work, taxes small work; "available rather than mandatory" |
| 4 | Memory: a small skill persists durable preferences as dated standing-rule entries in `~/.config/opencode/AGENTS.md` only | One file, always loaded, matches existing dated-section pattern; no new deps |
| 5 | Response style always-on in AGENTS.md: Mermaid diagrams (short labels, top-down, annotated edges, followed by 1–3 sentences of interpretation), concise but complete | User preference; zero-cost when in always-on config |
| 6 | Grilling consolidated 3 → 1: `grilling` stays model-invocable and fires on any planning work; `grill-me` deleted (pure alias), `grill-with-docs` deleted (broken: referenced uninstalled `domain-modeling`) | One grill authority; native question modals permitted always via `permission.question: "allow"` |
| 7 | Atlassian MCP `enabled: false` (login preserved in auth store; re-enable = flip flag + restart); Figma MCP removed globally, re-add per project when needed | MCP cannot be on-demand; dormant config is the only lazy path |
| 8 | shadcn skill → project-local copies in the 6 repos that have `components.json` (oprec-25, oprec-25-fe, omah-to/web, b2b/frontend, kkn/melukisambelia, mbox-clone) | User call: not all repos use shadcn |
| 9 | Plugins: `opencode-antigravity-auth` → `opencode-google-antigravity-auth` (user runs the startup fetch), pencil-sync dropped, quota + herdr-agent-state kept | Maintained alternative; dead upstream |

## Final inventory (24 advertised vs ~33 nominal, all links live)

| Tier | Skills |
|---|---|
| Core (shared, dotfiles) | ponytail · engineering-core (absorbs general) · git-pr-workflow · feature-workflow · code-review (absorbs requesting-code-review) · parallel-worktrees (absorbs using-git-worktrees) |
| Forked (shared, MIT from obra/superpowers) | brainstorming · systematic-debugging · test-driven-development (triage gate) · verification-before-completion · writing-plans (edge-case + requirements-traceability self-review items) · executing-plans (delegation → herd, execution inline) · receiving-code-review · writing-skills |
| Orchestration | herd · herdr (single copy) |
| User-invoked | grilling (one grill authority) |
| Specialist | frontend-design · production-reliability · confluence-authoring · find-skills |
| New | memory |
| opencode-only | customize-opencode (built-in, free) |

Dropped entirely: using-superpowers bootstrap, subagent-driven-development,
dispatching-parallel-agents, requesting-code-review (folded), using-git-worktrees
(folded), general (folded), grill-me, grill-with-docs, pencil-sync plugin,
antigravity-auth plugin, global figma MCP, global atlassian MCP (dormant flag),
shadcn (→ 6 project copies), duplicate herdr under ~/.claude/skills.

## AGENTS.md architecture (one router, two tiers)

- **Tier 1 — always-on standing rules:** large-downloads protocol, worker
  approvals, code hygiene (no plan artifacts in code; no unnecessary
  JSDoc/bloat; minimal, non-speculative code), Mermaid response style,
  memory convention, atlassian dormant flag reminder.
- **Tier 2 — routing table:** skill → trigger, herd-first delegation,
  execution inline by default, grill on all planning.

## Consequences

- We own the 8 forked files; upstream improvements are cherry-picked manually
  (they are markdown; slow to rot).
- Framework updates no longer arrive automatically — acceptable trade for
  full routing control.
- opencode restart required after install.sh re-link + opencode.json change;
  next startup fetches the google-antigravity plugin (the one download).

## Re-enablement snippets (kept out of live config until needed)

Figma MCP, per-project `opencode.json` when design work resumes:

```json
"mcp": {
  "figma": {
    "type": "remote",
    "url": "https://mcp.figma.com/mcp",
    "oauth": {
      "clientId": "WIOaMeIVh0QpJStFlrBWyS",
      "clientSecret": "{env:FIGMA_MCP_CLIENT_SECRET}"
    }
  }
}
```

Atlassian MCP re-enable = set `"enabled": true` on `mcp.atlassian` + restart.

