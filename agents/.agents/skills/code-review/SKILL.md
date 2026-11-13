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

## Before Requesting Review

Before handing your own work to review (or asking a worker to review):

1. Run the verification suite yourself (`verification-before-completion`) — a review request is never a status report.
2. Re-read your own diff first: stray debug code, leftover plan artifacts ("per step N"), unrelated churn.
3. Confirm every requirement is demonstrably implemented; state any known gaps explicitly rather than hoping the reviewer misses them.
4. Run single-session reviews in a fresh context: OpenCode `/review`, Claude the
   `review` subagent, Codex a fresh session. Parallel or worker output still
   goes through the harness's worker orchestration when it has one. Never
   self-approve.

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
  stall_rounds: 2                  # same blocking set twice -> escalate
  max_rounds: 5                    # circuit breaker, not the goal
```

- `acceptance`: every contract item maps to evidence. Omit only for an explicit
  advisory review; state that acceptance is unverified.
- `evidence`: claimed commands were re-run or spot-checked.
- `scope`: no files outside the declared scope.
- `thresholds`: measurable, repo-specific checks. If a threshold cannot be
  measured, the verdict is `BLOCKED`, not `PASS`.

Secrets are reported, never gated on absence: any credential, key, or token in
the diff is `CRITICAL`. Record a scanner result as evidence when one is
available; absence cannot be proven by inspection.

The gate decides blocking, not reporting: report every finding. Never downgrade
severity to pass. A numeric score is not a gate unless it is derived
mechanically from binary criteria.

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

Each round is a new reviewer session. Carry state, not context:

- contract, gate, and diff range;
- the ledger: open findings, fixed findings, and pushbacks with reasons;
- prior evidence claims, for spot-checking.

Do not pass the previous reviewer transcript or the implementation chat.

The implementer owns the fix loop; the reviewer never edits. Capture
`git status --short` before each round; compare it after. If the reviewer
mutated the tree, the round is invalid: the implementer restores the change and
you escalate.

Then:

1. `PASS` — every gate item is satisfied.
2. `FAIL` with progress — fix blocking findings or push back with evidence,
   update the ledger, run a fresh round.
3. `STALL` — the same blocking set twice — escalate.
4. Budget exhausted, or `BLOCKED` — escalate; do not keep looping.

Ledger (untracked; never commit):

```markdown
# Review ledger — <task>
Gate: <verbatim, fixed>
Base: <sha>  Head: <sha>
Round: <n>
Open: <id> [SEVERITY] <location> — <problem>
Fixed: <id> ...
Pushed back: <id> ... — <why>
Verdict: PASS | FAIL | BLOCKED
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

Every finding should include:
- location;
- problem;
- why it matters;
- concrete remediation.

Do not invent problems. If no meaningful issue exists, say so and summarize what was verified.
