---
description: Fresh-context review of the current diff against the fixed gate
agent: review
subtask: true
---

Review the current change in a fresh context. Arguments: `$ARGUMENTS`

1. Lane: `light` or `full` from the arguments, the contract, or the ledger. If
   none names a lane, use `light`. Record `Review: skip|light|full` when you
   own the contract; a light pass blocks only on `CRITICAL`.
2. Scope: if the arguments name a base ref, review `git diff <base>` plus
   untracked files; otherwise review the working tree against the merge-base
   with the default branch, including untracked files.
3. Gate: read `.review/ledger.md` when present. Otherwise use the default gate
   in `code-review` plus any thresholds in the arguments. State the gate
   verbatim before reviewing. The default `block` is `[critical, high]`; never
   widen it to include `LOW` without the user's approval. A light review is
   advisory: only `CRITICAL` blocks.
4. Contract: use the contract from the arguments, `.review/ledger.md`, the
   plan, or the PR body. If none exists, omit `acceptance` from the gate and
   state `Contract: none supplied; acceptance not verified`. Do not invent
   requirements.
5. Budget and round cap: per `code-review` and the review agent. A ledger past
   `max_rounds` gets no review; escalate to the user.
6. Scope the round: if the ledger records a previously reviewed head, review
   only the delta since that head. Round 1 is the only full-PR review; one
   round covers a stack, not each layer.
7. Report `SHIP`, `SHIP WITH FOLLOW-UPS`, or `DO NOT SHIP`, then must-fix
   findings, follow-ups, evidence checked, and unverified items. Do not edit,
   commit, or push.
