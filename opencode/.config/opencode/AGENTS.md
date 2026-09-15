# Global operator preferences

Owner: vityasyyy. Standing instructions from 2026-09-15 — these override any
skill or convention that says otherwise. Reconfirm if they ever look unsafe.

## PR merges (invenio-rdm-gitops)

When CI is green on a pull request, squash-merge it and delete the branch
WITHOUT asking for per-PR approval first.

Standing rules that still apply every time:
- Verify first: read the diff and confirm CI status myself
  (`verification-before-completion`) — never merge red or unknown CI.
- Never merge directly to main; squash-merge only (`gh pr merge --squash`).
- If the merge fails (e.g. BEHIND base, conflicts), fix forward or report —
  do not force-push.
- Report each merge (commit SHA, what rode along).

## Worker approvals (herd)

Auto-clear routine sandbox prompts on the operator's behalf: external-directory
access under `/tmp`, `~/.local/bin`, and worktrees, plus the planned tool
installs/downloads in the approved brief (promtool, amtool, crane, helm pulls,
pinned-image pulls).

Still escalate to the user first: secrets/credentials, destructive or
out-of-scope actions, anything affecting the cluster, and ambiguous decisions.
