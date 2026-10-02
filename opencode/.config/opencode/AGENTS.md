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

## Confluence docs conventions (2026-10-01 — standing, do not re-ask)

Every Confluence page/brief drafted by any agent (lead or worker) must:

- Read as neutral tech docs (mirror Channel Activations 101 / Admin Dashboard
  Channel Approval/Activations voice): descriptive third person, no first
  person, no agent-talk. NEVER write meta lines like "workers wrote…",
  "this draft covers…", "open questions live at…", or tool-call narratives.
- NEVER emit inline citation codes ([101:…], [Arch:…], [DOCX:…]). Sources go
  in a References section as named page links. Body prose stays clean.
- NEVER reference local machine paths (~/Downloads, /tmp, .docx/.png
  filenames). If a source has no URL, write the source name with "(link TBD —
  confirm)" and ask the user for the URL instead of citing the local file.
- Diagrams: Confluence does NOT render Mermaid fences (they show as code
  text). Use plain code-block ASCII diagrams (box-and-arrow, renders as
  monospace everywhere) and/or flow tables. Keep each diagram small; split
  large architectures into a backbone diagram plus a connection table.
- Worker briefs must include this section by reference so workers comply
  without being told twice.
