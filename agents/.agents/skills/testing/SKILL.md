---
name: testing
description: Use when implementing behavior that needs tests, writing or changing tests, auditing a test suite for flaky, redundant, or low-signal tests, or finalizing a change before a completion claim or PR. Owns the test-first cycle, test-writing rules, coverage policy, and the finalize audit.
---

# Testing

A test earns its place by catching a break a consumer would notice. This skill
owns writing tests first, judging them, and the finalize audit. The rules,
smell catalogue, and scan recipes live in [smells.md](smells.md).

## Triage

State the disposition before starting: test-first, or a one-line skip.

- **Test-first (default):** behavior changes, features, and bug fixes in code
  that will be maintained, wherever test infrastructure exists or is plausible.
- **Stated skip:** throwaway spikes, infra or config as code, docs, and trivial
  fixes where the test costs more than the change (typos, copy, formatting).

The question: *will this code exist in a month, and could it silently break?*
Yes means test-first. A skip that is not stated is a defect.

## Cycle

1. **Red.** Write one test for one behavior. Run it. It must fail, and fail
   because the behavior is missing, not because of a typo or import error. A
   test that passes at once tests existing behavior; fix the test.
2. **Green.** Write the least code that passes. Run the test and its package;
   the output is clean.
3. **Refactor.** Only at green. No new behavior.

Code written before its test is deleted and rewritten from the test; do not
keep it as reference. Exploration is fine; discard it before red. A bug fix
starts with a test that reproduces the symptom. Commit cadence is owned by
`git-pr-workflow`.

## Writing Rules

Before writing the body, name the production change that should make the test
fail, and confirm it is a bug, not a decision. Then:

- Derive expected values by hand: literals or hand-checked fixtures, never the
  code under test or its helpers.
- Assert behavior: outputs, side effects, emitted events, exit codes. Not
  constants, wording, private structure, or source text.
- Use real code. Mock only slow, external, or nondeterministic dependencies, at
  the lowest level, mirroring the full real structure. Never assert on a mock.
- One behavior per test; a table for cases of one behavior; no branches or
  loops computing expectations.
- Deterministic: injected clock, seeded randomness, await the event instead of
  sleeping, no order dependence or shared mutable state.
- Test at the lowest level that can prove the behavior, once. Composition and
  seam behavior follow `code-review` § Integration and Render Contract.

Details, examples, and gate functions: [smells.md](smells.md).

## Coverage

Coverage measures behavior tests; it never justifies code. A line no behavior
test reaches is deleted, or left uncovered with the reason stated. Never add a
seam, branch, export, fake server, test-only package, or assertion-free test to
raise the number. When a global percentage gate forces that, report the gate
as the defect and propose changed-line coverage or a reasoned exclusion.

### Production code reads as if tests did not exist

A dependency belongs in production code only when production uses it: an I/O
port the logic is written against, or a clock or randomness source passed
through the constructor production already calls. Anything else that exists so
a test can reach a line is a hook.

| Hook shape | Fix |
|---|---|
| `main` → `run(deps)` / `runWith(load, getenv, listen)` | Keep `main` a thin script; test what it calls; the gate excludes `main` |
| Package-level function variable a test reassigns | Pass the dependency to the constructor, or test the function it wraps |
| Option or constructor variant only tests call | One constructor; tests build its real inputs |
| Fake server or emulator only to cover an SDK constructor | Leave it uncovered; an opt-in integration test covers it |
| A comment saying "tests use this" or "seam for tests" | The comment names the hook; remove the hook |

## Finalize Audit

Runs before every completion claim and PR (`verification-before-completion`),
and whenever the user asks for one. A change that touches no code skips it with
one stated line.

**Scope:** every test in each package or module the change touched — a Go
package, a JS/TS package or its test directory, a Python package. An on-demand
audit takes the scope the user names. **The diff** is the files this change
edits.

1. **Baseline.** Run the scope. Record passed, failed, and skipped counts and
   the run time. A red test outside the diff is reported, not fixed here.
2. **Signal.** Scan every test in scope against the warning signs in
   [smells.md](smells.md): no assertion, mirror assertion, change detector,
   mock assertion, container-wide substring, test of the framework, and test
   hooks in production code.
3. **Mutation.** For each changed production function with a branch, loop, or
   side effect, and each new or changed test, apply the
   [mutation operators](smells.md#mutation-operators) by hand: break the
   behavior, run the scope, and confirm a test fails with a message that names
   the behavior. Restore the file and confirm `git status --short` matches its
   state before the mutation. Record each mutation as caught by a named test or
   survived. When the repository already has a mutation tool (gremlins,
   go-mutesting, Stryker, mutmut, PIT), run it on the changed files instead;
   never install one without asking.
4. **Redundancy.** A test is a removal candidate only when the mutation record
   shows every break it catches is caught by another test at the same or a
   lower level, and it documents no behavior the others leave implicit. Tests
   that differ only in input are merge candidates for one table.
5. **Flakiness.** Always run the static scan in
   [smells.md](smells.md#flaky-tests). When tests in scope touch time,
   concurrency, I/O, network, randomness, or shared state, also rerun them five
   times in shuffled order with race detection where the runner has it:
   `go test -count=5 -shuffle=on -race`, Playwright `--repeat-each=5`, or a
   five-run loop with Vitest `--sequence.shuffle`, Jest `--randomize`, or
   pytest with `pytest-randomly` when installed. A failure is a defect: find
   the cause with `systematic-debugging`; never add a retry, sleep, or skip.
6. **Disposition.**
   - A mutation that survived in the diff gets a test, written test-first,
     without asking.
   - Remove, merge, or rewrite proposals in the diff go to the user as **one
     batched question** (native question tool): each item names the test, the
     smell, the evidence, and the action. Apply only what the user selects,
     then rerun the scope.
   - Findings outside the diff are **reported only**, in the follow-up table.
     Never edit them in this change; the user decides.
7. **Evidence.** Add this block to the report and the PR's Testing section:

   ```text
   Test audit: <packages>
   Baseline: <passed/failed/skipped, time>  Final: <passed/failed/skipped, time>
   Mutations: <tried>, caught <n>; survived: <mutation → test added | reported>
   Flakiness: <static scan clean | 5x shuffled: pass | flaky: test → cause>
   In diff: <added / removed / merged / rewritten, with the user's selection>
   Outside diff (report only): <test — smell — proposed action>
   ```

   A lower test count is explained: each removed test names the test that
   still catches its mutations.

## Red Flags

| Thought | Reality |
|---|---|
| "It should pass now" | Run it |
| "The test passed on its first run" | Red was skipped; fix the test |
| "I'll loosen the assertion to get green" | The test was right; fix the code |
| "A retry or a longer sleep stabilizes it" | Flaky; find the cause |
| "This test just raises coverage" | Delete it, or test the behavior |
| "I'll clean up this old test while I'm here" | Outside the diff: report it |
