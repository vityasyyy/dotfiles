---
name: writing-skills
description: Use when creating new skills, editing existing skills, or verifying skills work before deployment
---

<!-- Forked from obra/superpowers (github.com/obra/superpowers), MIT License. Local routing lives in AGENTS.md. -->

# Writing Skills

Writing a skill is TDD applied to process documentation: watch an agent fail
without it, write the smallest guidance that fixes that failure, then re-test.

Full methodology, pressure scenarios, and wording research live in
[`authoring-guide.md`](authoring-guide.md). Anthropic's guidance is in
[`anthropic-best-practices.md`](anthropic-best-practices.md).

## When to create one

Create when the technique is non-obvious, reusable across projects, and the
failure is one guidance can fix. Do not create for one-off solutions,
standard practice, project conventions (put those in the repo's `AGENTS.md`),
or mechanically enforceable constraints (automate those).

## Shape

- One directory per skill, flat namespace: `skills/<name>/SKILL.md`.
- Frontmatter: `name`, `description`. The description states **when to use**,
  not the workflow, and starts with "Use when…". Max 1024 characters.
- Keep `SKILL.md` under ~100 lines. Move API references, long examples, and
  scripts to sibling files; link them, do not inline them.
- One excellent example beats five mediocre ones.
- The model sees only name + description at startup; full instructions load
  on demand. Optimize the description for routing.
- Every absolute names its scope. An unscoped rule fires outside its lane,
  gets ignored, and teaches the agent that the rest are advisory.

## Test before deploying

**No skill without a failing test first.** Editing an existing skill counts.

1. RED: run a pressure scenario without the skill; record the exact failure
   and the rationalizations used.
2. GREEN: write the smallest guidance that fixes those failures; re-run.
3. REFACTOR: close new loopholes; re-test.
4. Micro-test wording with 5+ fresh-context reps and a no-guidance control
   before full scenarios.

Match the form to the failure: discipline failures get a prohibition plus a
rationalization table; wrong-shaped output gets a positive recipe; omitted
elements get a required field in the template. See the guide.

Representative prompts and expected routes live in
[`trigger-matrix.md`](trigger-matrix.md). Run the matrix in a fresh OpenCode
session when changing a description or routing row; all harnesses share the
canonical router, so only the invocation mechanics differ.

## Deploy checklist

- [ ] Name is lowercase letters, numbers, hyphens, and matches the directory.
- [ ] Description starts with "Use when" and names concrete triggers.
- [ ] Description is valid YAML; quote it or use `>-` when it contains `: `.
- [ ] Body is under ~100 lines; heavy detail is linked.
- [ ] Human-facing docs produced by the skill follow `documentation` and link
      their references.
- [ ] Baseline failure recorded; skill re-tested after writing.
- [ ] No rule duplicated from another skill — link to its owner.
- [ ] The skill is reachable from at least one harness routing instruction.
- [ ] Trigger matrix covers the skill and the prompt fires the expected route.
- [ ] `./scripts/check-agent-config.sh` passes.
- [ ] Changes committed with a descriptive body.
