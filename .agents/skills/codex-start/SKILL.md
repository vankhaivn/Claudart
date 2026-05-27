---
name: codex-start
description: Orient a new Codex session from current context, recent git history, and active task documents.
---

# Codex Start

Start a Codex session with a lightweight CLAUDART orientation. This skill is read-only.

## Procedure

1. Read `.codex/CONTEXT.md` if it exists. If missing, say the project has no Codex context yet and suggest `$codex-checkpoint` after meaningful work.
2. Read `.codex/tasks/index.md` if it exists. If missing, treat as "no active tasks". If present, extract entries under `## Active`.
3. For each Active entry, verify the underlying file exists in `.codex/tasks/` (the index is a cache; the file is truth). Read its frontmatter (`status`, `updated`, `slug`) only — do not full-read task bodies in `$codex-start`.
4. Run `git log -3 --oneline`. If the directory is not a git repo or has fewer than three commits, report what is available.
5. Extract only these sections from `.codex/CONTEXT.md` when present:
   - `## In Progress`
   - `## Next Session Should Start By`
   - `## Open Questions / Blockers`
6. Do not read `.codex/JOURNAL.md`.
7. Do not read task bodies in `.codex/tasks/done/`.
8. Do not run `$codex-doctor`; that is a heavier health check.

## Output Format

```markdown
## Session Ready

**Current focus:** [In Progress section, or "None recorded"]
**Last 3 commits:** [git log -3 --oneline output, compact]
**Active tasks:** [list of "<slug> (<status>, updated <date>)" from tasks/index.md, or "None"]
**Start by:** [Next Session Should Start By section, or see "Three Cases" below]
**Open blockers:** [Open Questions / Blockers section, or "None recorded"]
```

## Three Cases: What to Ask After the Report

Decide based on what was found in steps 1-3:

### Case A: At least one task with `status: awaiting-review`, `in-progress`, or `blocked`

Pick the most recently updated one. The exact prompt depends on its status:

- `awaiting-review`: a previous session reported the task complete and is waiting for the user's verification. Say:
  > "Task `<slug>` is `awaiting-review` — a previous session finished it and is waiting for your verification. Open `.codex/tasks/<file>` to review draft Outcomes. Confirm to close, or tell me what didn't work and I'll flip it back to `in-progress`."
- `in-progress`: say:
  > "There's an active task `<slug>` (in-progress, updated <date>). Want to resume? I'll read the full file and verify the completed steps still hold against current code. Or tell me to start something else."
- `blocked`: say:
  > "Task `<slug>` is blocked (updated <date>). Has the blocker cleared? If yes, I'll flip to in-progress and resume. If no, tell me what to work on instead."

Do not auto-read the task body, auto-resume, or auto-confirm completion. Wait for explicit user direction. When the user confirms a resume, **warm the session**: read the full task file, then read the files in its `Related Code` section (cap ~5 most relevant) so you resume against real code, not the plan's description of it. Then follow the Resumption protocol in `.codex/guidelines/task-management.md` (verify completed steps still hold against current code, surface drift in Surprises section).

### Case B: No active task, but `## Next Session Should Start By` is set in CONTEXT.md

Surface that line and ask:

> "Next-session handoff says: <line>. Pick that up, or start something new?"

### Case C: No active task and no useful handoff in CONTEXT.md

Ask plainly:

> "No active task or session handoff found. What would you like to tackle? If it's non-trivial or multi-session, I can run `$codex-plan <description>` to create a persistent task document."

## Notes

- Keep the report short and actionable.
- **Warm resume for ad-hoc work:** when the user picks up a `(no task)` micro-handoff from `## In Progress` (Case B), read the files on its `Files:` line (cap ~5) before acting — the same warm-up a task resume gets. This is the `/compact`-style "re-read recent files" applied to un-planned work.
- If `.codex/CONTEXT.md` items look stale (`<!-- since: -->` more than 30 days old), mention that `$codex-checkpoint` should refresh them after this session.
- If a task in the Active list has `updated:` more than 7 days old AND `status: in-progress`, flag it as possibly stalled — suggest either resuming or flipping to `blocked`/`cancelled` via `$codex-checkpoint`.
- If a task has `status: awaiting-review` AND `updated:` more than 3 days old, flag it as awaiting-review stuck — the user likely forgot to confirm. Surface it prominently; the task is not abandoned, it just needs a sign-off.
