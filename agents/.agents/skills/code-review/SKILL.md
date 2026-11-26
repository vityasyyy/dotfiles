---
name: code-review
description: >-
  Use when running a fresh-context review: the rubric and dimensions for
  correctness, security, reliability, maintainability, observability,
  performance, testing, database safety, and production failure modes. Defines
  the gate, severity, and rounds for diffs, PRs, and architecture; it never
  replaces the review round itself.
metadata:
  audience: ai-coding-agent
  workflow: review
---

# Code Review

Review the system, not just the changed lines.

## Review Triage

Choose the lane at contract time and record `Review: skip|light|full`.

**Skip** when the entire change is docs, comments, formatting, tests only that
do not weaken a risky assertion, local tooling config, a mechanical dependency
bump with green CI, a revert of a known-good commit, or a one-line fix with an
obvious check. Self-check the diff.

**Full** when any change touches money movement, auth/authz, secrets, PII or
tenant isolation, schema or data migration, a public API or shared contract,
production infra or deploy, concurrency, idempotency, retries or an external
provider, or exceeds 400 changed lines or 12 files, or adds behavior without
tests.

**Light** otherwise. When unsure, use light. A light review that finds a
full-lane issue promotes the change to full; it does not expand in place.

Budgets are soft. Return the verdict and unverified items at the limit:

- light: 15 tool calls, no test execution, at most 5 findings;
- full: 40 tool calls, targeted checks only, at most 10 findings;
- delta: 10 tool calls, closure and regressions only.

Over budget with a verdict is a result; over budget without one is a failure.

## Before Requesting Review

Before handing your own work to review (or asking a worker to review):

1. Run the verification suite yourself (`verification-before-completion`) — a review request is never a status report.
2. Re-read your own diff first: stray debug code, leftover plan artifacts ("per step N"), unrelated churn.
3. Confirm every requirement is demonstrably implemented; state any known gaps explicitly rather than hoping the reviewer misses them.
4. Exercise the seam the change touches: the composed app/router/middleware stack, the API response → consumer render path, or the provider status matrix. Green tests on isolated pieces are not evidence for those seams.
5. Run single-session reviews in a fresh context: OpenCode `/review light|full`,
   Claude the `review` subagent, Codex a fresh session. Pass the lane and gate.
   Parallel or worker output still goes through the harness's worker
   orchestration when it has one. Never self-approve.
6. Before a human review of work that was reviewed only in deltas, or that
   spans linked PRs (a stack, or an API and its consumer in another
   repository), the closing round reviews the final combined state across all
   of them, not only the delta. It counts toward `max_rounds`; when no round
   is left, escalate instead. Delta rounds never see cross-layer seams.

## Review Gate

The gate is fixed before round 1 and recorded verbatim in the ledger. Changing
it requires the user's approval and a new ledger entry; never move the bar to
finish a round.

```yaml
gate:
  block: [critical, high]          # severities that fail the gate
  require: [acceptance, evidence, scope]
  thresholds: {}                   # e.g. coverage_pct: 80
stop:
  stall_rounds: 2                  # same must-fix set twice -> escalate
  max_rounds: 3                    # circuit breaker, not the goal
```

`block` starts at `[critical, high]`. Widening it — adding `medium` or
`low` — requires the user's explicit approval and a ledger entry. A `MEDIUM`
blocks only when the contract names a security or data-loss surface; fix it in
the same batch as the must-fix findings, then review the batch once.

The gate applies to `full`. A `light` review is advisory: `HIGH`/`MEDIUM`
findings are follow-ups unless the change is promoted to full; only `CRITICAL`
blocks.

Don't widen the gate to `LOW` to chase zero findings: a fresh reviewer always
finds one. Stop when only `LOW`/`NOTE` remain. Prefer deleting code to adding
it.

- `acceptance`: every contract item maps to evidence. Omit only for an explicit
  advisory review; state that acceptance is unverified.
- `evidence`: claimed commands were re-run or spot-checked.
- `scope`: no files outside the declared scope.
- `thresholds`: measurable, repo-specific checks. If a threshold cannot be
  measured, the verdict is `DO NOT SHIP`, never `SHIP`.

Secrets are reported, never gated on absence: any credential, key, or token in
the diff is `CRITICAL`. Record a scanner result as evidence when one is
available; absence cannot be proven by inspection.

The gate decides blocking, not reporting. Report material findings: behavior,
security, data, reliability, or test validity. Style preferences are not
findings. Never downgrade severity to pass. A numeric score is not a gate
unless it is derived mechanically from binary criteria.

Verdicts:

- `SHIP` — no must-fix finding and every required gate item is measured.
- `SHIP WITH FOLLOW-UPS` — no must-fix; advisory findings, or acceptance
  unverified because no contract was supplied.
- `DO NOT SHIP` — a must-fix finding, or a required gate item that cannot be
  measured.

A must-fix finding is `CRITICAL`, a `HIGH` on a full review, or a `MEDIUM` on a
security or data-loss surface. Everything else is a follow-up.

## Evidence Discipline

Combine every available source before reporting: the diff, the contract, the
ledger, the full files around each hunk, their callers, tests, CI config, and
the command output that proves each claim. Every finding cites the exact line
and a reproducible check. Mark inference `unverified` instead of reporting it
as fact; a diff-only reading is the main source of false positives.

For a new package or module, also scan existing neighbors for conventions
(import style, module naming, loader semantics) and check the target runtime's
load path; a diff-only review misses packaging and import failures.

## Fresh-Context Rounds

A round is **one fresh reviewer pass at a fixed head**. A resumed pass counts
as the same round once; a second resume is a new round. Never relabel passes
as "second/final pass" to stay inside `max_rounds`.

Each round is a new reviewer session. Carry state, not context:

- contract, gate, and diff range;
- the ledger: open findings, fixed findings, and pushbacks with reasons;
- prior evidence claims, for spot-checking.

For a `full` review, the implementer writes `.review/ledger.md` before round 1;
the reviewer only reads it. A `light` pass needs a ledger only when a delta
round follows it; create it then, with `Round: 2`. Create it
once per task; never reconstruct it from a transcript.

Do not pass the previous reviewer transcript or the implementation chat.

The implementer owns the fix loop; the reviewer never edits. Capture
`git status --short` before each round; compare it after. If the reviewer
mutated the tree, the round is invalid: the implementer restores the change and
you escalate.

Then:

1. `SHIP` — done.
2. `SHIP WITH FOLLOW-UPS` — fix or record the follow-ups; do not start a round
   for them.
3. `DO NOT SHIP` with progress — fix must-fix findings or push back with
   evidence, update the ledger, run a delta round.
4. `STALL` — the same must-fix set twice — escalate.
5. Budget exhausted — escalate; do not keep looping.

Round rules:

- **One reviewer per round.** A round is one reviewer session for the whole
  change, including linked PRs in other repositories. Never run parallel
  reviewers per layer, per file, per repository, or per worker.
- **The ledger enforces the cap.** The ledger starts at `Round: 1`. Before
  spawning each later round, increment `Round:`. When it would exceed
  `max_rounds`, do not spawn; escalate to the user with the ledger. A reviewer
  handed a ledger past the cap refuses the review.
- **A round is for must-fix closure or an explicit user request.** Fixing
  `LOW`/`NOTE` items never starts one.
- **Round 1 is the full review.** Every later round reviews the delta since the
  last reviewed head, not the whole PR again, except the closing final-state
  round in Before Requesting Review step 6.
- **Review the stack once.** Round 1 covers the aggregate diff; do not review
  each stacked layer separately.
- **A pass without a verdict is a failure.** Resume the same session once with
  "finish the report"; if it fails again, escalate. Do not spawn a new pass to
  recover a report.
- **Stop on convergence.** Two consecutive rounds with no new must-fix finding
  means the gate is satisfied; record the remaining follow-ups and finish.
- **Do not re-review a test-only or follow-up-only change in a dedicated
  round.** Include it in the next batch.

Ledger (untracked; never commit):

```markdown
# Review ledger — <task>
Lane: <skip|light|full>
Gate: <verbatim, fixed>
Base: <sha>  Head: <sha>
Round: <n>
Open: <id> [SEVERITY] <location> — <problem>
Fixed: <id> ...
Pushed back: <id> ... — <why>
Verdict: SHIP | SHIP WITH FOLLOW-UPS | DO NOT SHIP
```

## Review Order

1. Correctness
2. Security
3. Data integrity
4. Failure handling
5. Concurrency
6. Reliability
7. Maintainability
8. Observability
9. Performance
10. Tests
11. Documentation

## Integration and Render Contract

A diff can pass every isolated test and still fail at the seams below. Check
each seam the change touches:

- **Composition:** middleware, limiters, routers, listeners, and schedulers are
  order- and mount-sensitive. Count executions per real request at the
  production topology; do not infer from a router mounted alone. A request that
  consumes N limiter slots for one action is a defect.
- **Field survival:** list every field the downstream consumer reads, then
  follow each one through unwrap, allowlist, normalize, and render. A fixture
  that omits a consumed field cannot catch its loss; assert the field after
  every transform.
- **Exact render unit:** UI assertions name the concrete row, pair, label,
  value, and tone class (for example, `Approved date: <ISO date>`). A
  panel-wide substring that another element can satisfy is a change detector,
  not a test.
- **Status matrix:** every provider or lifecycle state maps to a tested
  user-visible label, tone, icon, and next action. Include non-success states;
  a default branch is behavior and needs a case.
- **Matcher parity:** a path or key filter (log redaction, auth skip,
  limiter allowlist) matches every form the router or parser accepts: case,
  trailing slash, encoding. Test a variant that differs only in case.
- **Deadline budget:** sum the server's sequential downstream timeouts at
  their configured maximums. One end-to-end server deadline must bound that
  sum, and every client must wait longer than it; otherwise the client aborts
  before the server answers.
- **Untrusted-key lookup:** a table indexed by external input must not resolve
  inherited keys (JS: `Map` or `Object.hasOwn`). Test the fallback with
  `constructor` and `__proto__`.
- **Validation parity:** the client accepts exactly what the server accepts.
  A server rejection of one item must not fail the whole batch or discard the
  user's edits.
- **Context across awaits:** every await that can outlive a user context
  switch (ticket, tab, account) re-checks the context captured at start,
  including handoffs from one flow into another.
- **No silent loss:** every item reaches a user-actionable terminal state on
  every termination path (done, error, dropped stream, timeout, abort). Every
  cap or truncation is reported with its own reason; never drop or mislabel
  input silently.

Reject a claim of "tested" when the evidence is only a coverage percentage, a
whole-container text match, or a per-router test for app-level composition.
Report code or tests that exist only to satisfy a coverage threshold as a
finding ([`testing`](../testing/SKILL.md#coverage)).
Report a test hook in production code as a finding even when the PR calls it
a testability boundary: `run`/`runWith` wrappers, reassigned package-level
function variables, options or constructor variants only tests call, and
"for tests" comments
([hook shapes](../testing/SKILL.md#production-code-reads-as-if-tests-did-not-exist)).

## Correctness

Check:
- invariants;
- edge cases;
- null/empty values;
- state transitions;
- off-by-one behavior;
- ordering;
- race conditions;
- incorrect assumptions;
- API contract compatibility.

## Error and Failure Review

For each external operation:
- timeout?
- error propagation?
- retry policy?
- retry safety?
- idempotency?
- partial failure?
- cancellation?
- resource cleanup?

Check process-level failures:
- panic/crash;
- OOM;
- graceful shutdown;
- connection pool exhaustion;
- file descriptor exhaustion.

Check infrastructure-level assumptions:
- what if the host dies?
- what if DNS fails?
- what if a dependency is unavailable?
- what if storage is full?

## Database

Check:
- transaction boundary;
- atomicity;
- isolation requirements;
- locks;
- race conditions;
- indexes;
- N+1 queries;
- unbounded queries;
- pagination;
- migration safety;
- backward compatibility;
- rollback strategy;
- duplicate writes;
- idempotency.

For destructive migrations, require a clear recovery strategy.

## Security

Check:
- authentication;
- authorization;
- tenant/resource isolation;
- input validation;
- output encoding;
- SQL/command/template injection;
- SSRF;
- CSRF;
- path traversal;
- secret handling;
- sensitive logging;
- insecure dependencies;
- unsafe defaults;
- rate limiting where necessary.

Never assume authenticated means authorized.

## Observability

Determine whether the change needs:
- structured logs;
- metrics;
- traces;
- alerts.

Avoid noisy alerts.

A normal client error should generally not page an engineer. Repeated infrastructure failures, crashes, integrity violations, and availability-impacting conditions should be observable and alertable.

## Concurrency

Look for:
- shared mutable state;
- race conditions;
- duplicate workers;
- double processing;
- deadlocks;
- lock contention;
- non-atomic check-then-act sequences;
- unsafe retries.

## Maintainability

Check:
- cohesion;
- coupling;
- naming;
- abstraction quality;
- duplication;
- dependency direction;
- testability;
- complexity;
- unnecessary indirection.

Prefer a simple correct abstraction over a generic framework.

## Performance

Look for concrete issues, not hypothetical micro-optimizations.

Pay attention to:
- N+1;
- O(n²) accidental behavior;
- unbounded memory;
- unnecessary serialization;
- excessive network round trips;
- blocking operations;
- missing indexes;
- uncontrolled concurrency.

## Testing

Require tests for:
- new behavior;
- important failure paths;
- regression cases;
- security-sensitive behavior;
- data integrity;
- concurrency-sensitive behavior where applicable.

Reject tests that merely assert implementation details without protecting behavior.

Check the `testing` finalize audit evidence block; do not repeat the audit.
Its absence on a code change is a finding. Spot-check one recorded mutation by
reading the test that claims to catch it; never mutate the tree to confirm it.
A low-signal, redundant, or flaky test in the diff is a finding.

## Receiving Feedback

When the feedback is about your own work:

1. Read it completely. Restate the requirement in your own words.
2. Verify it against the codebase before changing anything.
3. Evaluate whether it is correct for this codebase — not whether it sounds
   confident.
4. Clarify all unclear items before implementing any of them. Items may be
   related.
5. Implement in order: blocking/security, simple fixes, complex fixes. Test
   each.

No performative agreement or gratitude. State the technical requirement, or
just fix it and say what changed. Push back with evidence when the suggestion
breaks behavior, lacks context, violates YAGNI, or conflicts with an earlier
decision. If you were wrong, say what you verified and move on.

External reviewers: be skeptical but check carefully. If you cannot verify a
suggestion, say what you need. Reply to GitHub inline comments in the thread
(`gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`), not as a
top-level PR comment.

## Review Output

Report findings by severity:

- CRITICAL: immediate security/data-loss/system-integrity risk.
- HIGH: likely production failure or serious security/reliability issue.
- MEDIUM: meaningful maintainability/reliability issue.
- LOW: minor improvement.
- NOTE: optional observation.

Report at most 5 findings in `light` and 10 in `full`; beyond that, summarize
the count and keep the highest-severity items. Do not list style preferences.

Every finding should include:
- location;
- problem;
- why it matters;
- concrete remediation.

Lead with the verdict; end with evidence checked and unverified items. Do not invent
problems. If no meaningful issue exists, say so and summarize what was verified.
