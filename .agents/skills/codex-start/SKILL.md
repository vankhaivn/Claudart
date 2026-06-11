---
name: codex-start
description: Orient a new Codex session from current context, recent git history, and active task documents.
---

# Codex Start

Start a Codex session with a lightweight CLAUDART orientation. This skill is read-only, with one exception: consuming the handoff baton (Case H) deletes `.codex/HANDOFF.md` once the user resumes or discards it.

## Procedure

1. Check `.codex/HANDOFF.md`. If present, read it in full — it is a one-shot reasoning baton written by a previous session's `$codex-handoff`. Note its `created:` date. Consumption flow: see Case H below. If absent (the normal state), continue silently.
2. Read `.codex/CONTEXT.md` if it exists. If missing, say the project has no Codex context yet and suggest `$codex-checkpoint` after meaningful work.
3. Read `.codex/tasks/index.md` if it exists. If missing, treat as "no active tasks". If present, extract entries under `## Active`.
4. For each Active entry, verify the underlying file exists in `.codex/tasks/` (the index is a cache; the file is truth). Read its frontmatter (`status`, `updated`, `slug`) only — do not full-read task bodies in `$codex-start`.
5. Read `.codex/knowledge/INDEX.md` if it exists — the INDEX only. Count the entries under `## Knowledge`. Do NOT read individual knowledge detail files, and do NOT validate freshness or dead links (that is `$codex-doctor`'s job). The index makes durable project facts discoverable; read a detail file only if a later task needs it.
6. Run `git log -3 --oneline`. If the directory is not a git repo or has fewer than three commits, report what is available.
7. Extract only these sections from `.codex/CONTEXT.md` when present:
   - `## In Progress`
   - `## Next Session Should Start By`
   - `## Open Questions / Blockers`
8. Do not read `.codex/JOURNAL.md`.
9. Do not read task bodies in `.codex/tasks/done/`.
10. Do not run `$codex-doctor`; that is a heavier health check.

## Output Format

```markdown
## Session Ready

**Handoff:** [present — created <date>, objective one-liner; or "None"]
**Current focus:** [In Progress section, or "None recorded"]
**Last 3 commits:** [git log -3 --oneline output, compact]
**Active tasks:** [list of "<slug> (<status>, updated <date>)" from tasks/index.md, or "None"]
**Project knowledge:** [N entries in knowledge/INDEX.md, or "none"]
**Start by:** [Next Session Should Start By section, or see "Four Cases" below]
**Open blockers:** [Open Questions / Blockers section, or "None recorded"]
```

## Four Cases: What to Ask After the Report

Decide based on what was found in steps 1-4. Case H takes precedence over all others.

### Case H: `.codex/HANDOFF.md` exists (a previous session handed off mid-flight)

A reasoning baton is waiting. Surface it before anything else:

> "A previous session left a handoff (created <date>): <Objective, one line>. Recorded next step: <Next Step, one line>. Resume from it? On resume I'll verify its Evidence against current code, then consume the baton. Or tell me to discard it."

- If the baton's `created:` is more than 7 days old, lead with that: reasoning state rots fast — the recorded hypothesis may no longer match the code.
- **On resume**: warm the session — read the files referenced in Evidence and Next Step (cap ~5), verify the baton's claims still hold against current code, surface any drift, then **delete `.codex/HANDOFF.md`**. The baton is consumed exactly once; its durable parts were already routed to knowledge/task files by `$codex-handoff`.
- **On discard**: delete the file without acting on it.
- **If the user starts unrelated work instead**: ask once whether to keep the baton for later or delete it. If kept, it stays on disk untouched — `$codex-doctor` will flag it when stale.

Never act on baton content without verifying it against the current code first — it is a point-in-time snapshot, and commits may have landed since.

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
