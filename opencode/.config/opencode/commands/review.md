---
description: Fresh-context review of the current diff against the fixed gate
agent: review
subtask: true
---

Review the current change in a fresh context. Arguments: `$ARGUMENTS`

1. Scope: if the arguments name a base ref, review `git diff <base>` plus
   untracked files; otherwise review the working tree against the merge-base
   with the default branch, including untracked files.
2. Fix the gate: read `.review/ledger.md` when present. Otherwise use the
   default gate in `code-review` plus any thresholds in the arguments. State
   the gate verbatim before reviewing.
3. Contract: use the contract from the arguments, `.review/ledger.md`, the
   plan, or the PR body. If none exists, run an advisory diff review: omit
   `acceptance` from the gate and state `Contract: none supplied; acceptance
   not verified`. Do not invent requirements.
4. Report findings by severity, the verdict, the evidence you checked, and what
   remains unverified. Do not edit, commit, or push.
