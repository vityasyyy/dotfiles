---
name: grilling
description: Use when requirements are ambiguous, the change is high-impact, or the user asks to stress-test a design. Runs interview rounds and writes the design spec before implementation.
---

# Grilling

Interview the user until you reach a shared understanding. Map the work as a
**design tree**: every decision branches into the decisions that hang off it.

## Rounds

Work the tree in rounds. The **frontier** is every decision whose prerequisites
are settled — the questions you can ask now without guessing at answers you
have not heard. Ask the whole frontier in one round, numbered, each with your
recommended answer. Then wait.

```
❓ **Q1** — **<title>**: <question body and choices>

➡️ <recommended answer>
```

Use the native question modal when the harness exposes one. One decision per
modal. Otherwise use the inline format.

Each round reshapes the tree: settled answers push the frontier outward.
Recompute it and ask the next round. A question that depends on another open
question belongs to a later round.

## Facts are yours, decisions are the user's

When a frontier question needs a fact from the environment, look it up. Do not
ask the user for what you can inspect. Do not block the whole round on one
lookup: ask the questions that do not depend on it now.

## When not to use

A clear, small, reversible change with an obvious acceptance check does not
need an interview. State a one-line contract and proceed. Use this skill when
the contract cannot be filled without guessing, or when the change is
high-impact.

## Before the first round

Inspect the project: files, docs, recent commits, existing patterns. If the
request spans independent subsystems, say so and decompose it before refining
details. Each sub-project gets its own design → plan → implementation cycle.

## Explore approaches

For a non-trivial design, propose 2–3 approaches with trade-offs and a
recommendation. Lead with the recommended one and say why. Apply YAGNI
ruthlessly: remove unnecessary features from every approach.

## Present the design

Present in sections scaled to complexity — a few sentences when simple, up to
a few hundred words when nuanced. Ask after each section whether it looks
right. Cover architecture, components, data flow, failure handling, and
testing. Prefer small units with clear boundaries and testable interfaces.

## Write the spec

Save the approved design to `docs/plans/YYYY-MM-DD-<topic>-design.md` unless
the project overrides the location. Then self-review:

1. Placeholder scan: no TBD, TODO, or vague requirements.
2. Internal consistency: no contradictions between sections.
3. Scope: one implementation plan can deliver it.
4. Ambiguity: each requirement has one interpretation.

Fix issues inline. Then ask the user to review the spec and wait.

## Hard gate

For ambiguous or high-impact work, do not implement or scaffold until the
design is approved. The design can be three sentences, but it is presented and
approved. A clear, small change does not enter this skill.

## Handoff

The only next skill is `writing-plans`. Do not invoke implementation skills
from here.
