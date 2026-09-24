---
description: Orient a new CLAUDART session from current context, recent git history, and active task workspaces
---

Start this session with a lightweight CLAUDART orientation. This command is read-only, with one exception: consuming the handoff baton (Case H) deletes `.claudart/HANDOFF.md` once the user resumes or discards it.

The user's current request controls what happens after orientation. If it explicitly selects a task/spec or says to continue/resume the unambiguous current focus, honor that direction without asking again: complete the lightweight inventory, then load the selected workflow's canonical files and continue under its authorization rules. A startup scan never overrides or delays an explicit request.

## Procedure

1. Check `.claudart/HANDOFF.md`. If present, read it in full — it is a one-shot reasoning baton written by a previous session in either runtime. Note its `created:` date. Consumption flow: see Case H below. If absent (the normal state), continue silently.
2. Read `.claudart/CONTEXT.md` if it exists. If missing, say the project has no shared project context yet and suggest `/checkpoint` after meaningful work.
3. Read `.claudart/tasks/index.md` if it exists and extract `## Active`. If missing, use shallow `.claudart/tasks/*/TASK.md` discovery and report that `/checkpoint` should regenerate the index; a missing cache does not prove there are no tasks.
4. Resolve Active entries only to `.claudart/tasks/<YYYY-MM-DD-NNN-slug>/TASK.md` and verify existence. Use valid top-level workspace ids during fallback discovery; exclude `done/` itself and symlinked workspaces or `TASK.md` files. Read `TASK.md` frontmatter (`status`, `updated`, `created`, `slug`) only; flag missing/broken references for `/checkpoint`. Do not read task bodies or artifact contents, recurse into workspaces, or create supporting files during startup.
5. Read `.claudart/knowledge/INDEX.md` if it exists — the root router only. Count visible route lines under `## Knowledge` that match the canonical Markdown route grammar; ignore HTML comments/templates and `- _(none)_`, so a seed index reports zero. Do not follow domain-map or topic links during startup. Later work follows the bounded map-first retrieval in `.claude/rules/knowledge-management.md`.
6. Read `.claudart/specs/INDEX.md` if it exists — the INDEX only. Extract entries under `## Active`. Do NOT read SPEC/ROADMAP/NOTES/LEDGER bodies in `/start`.
7. Run `git log -3 --oneline`. If the directory is not a git repo or has fewer than three commits, report what is available.
8. Extract only these sections from `.claudart/CONTEXT.md` when present:
   - `## In Progress`
   - `## Next Session Should Start By`
   - `## Open Questions / Blockers`
9. Do not read `.claudart/JOURNAL.md`.
10. Do not read task bodies in `.claudart/tasks/done/`.
11. Do not run `/doctor` or `bash .claude/scripts/knowledge-check.sh`; startup must stay lightweight.

## Output Format

```markdown
## Session Ready

**Handoff:** [present — created <date>, objective one-liner; or "None"]
**Current focus:** [In Progress section, or "None recorded"]
**Last 3 commits:** [git log -3 --oneline output, compact]
**Active tasks:** [list of "<slug> (<status>, updated <date>)" from tasks/index.md, or "None"]
**Active specs:** [list of "<slug> (<status>, updated <date>)" from specs/INDEX.md, or "None"]
**Project knowledge:** [N root routes in knowledge/INDEX.md, or "none"]
**Start by:** [Next Session Should Start By section, or see "Five Cases" below]
**Open blockers:** [Open Questions / Blockers section, or "None recorded"]
```

## Shared Handoff Safety

The handoff slot is shared across runtimes. Before deleting a resumed or discarded baton, re-read it and confirm it is the same content inspected for that decision. If it changed, preserve the new content and report the conflict. Serialize handoff consumption with other writers; this check is not an atomic lock. Do not filter shared task/spec discovery by the recorded `agent` value.

## Five Cases — What to Ask After the Report

Decide based on what was found in steps 1-6 and the current request. An explicit task/spec selection or continue/resume instruction takes precedence over the prompts below. Otherwise Case H takes precedence; Case S coexists with Case A (report both, lead with whichever is awaiting the user).

### Case H — `.claudart/HANDOFF.md` exists (a previous session handed off mid-flight)

A reasoning baton is waiting. Surface it before anything else:

> "A previous session left a handoff (created <date>): <Objective, one line>. Recorded next step: <Next Step, one line>. Resume from it? On resume I'll verify its Evidence against current code, then consume the baton. Or tell me to discard it."

- If the baton's `created:` is more than 7 days old, lead with that: reasoning state rots fast — the recorded hypothesis may no longer match the code.
- **On resume**: warm the session — read the files referenced in Evidence and Next Step (cap ~5), verify the baton's claims still hold against current code, surface any drift, then **delete `.claudart/HANDOFF.md`**. The baton is consumed exactly once; its durable parts were already routed to knowledge/task files by `/handoff`.
- **On discard**: delete the file without acting on it.
- **If the user starts unrelated work instead**: ask once whether to keep the baton for later or delete it. If kept, it stays on disk untouched — `/doctor` will flag it when stale.

Never act on baton content without verifying it against the current code first — it is a point-in-time snapshot, and commits may have landed since.

### Case S — `.claudart/specs/INDEX.md` lists an Active spec (mission in flight)

For the most relevant spec (prefer `drafting`/`poc-review`/`awaiting-final-review`, then `running`, then `ready`, then `blocked`):

- **`drafting`**: say:
  > "Spec `<slug>` is being drafted or amended. Run `/spec` to continue in its existing dated folder."
- **`poc-review`**: say:
  > "Spec `<slug>` is waiting for your review — open its dated folder from `.claudart/specs/INDEX.md` (POC in `artifacts/`, then SPEC.md and ROADMAP.md). Approving is a standing approval: `/spec-run` will then execute the whole roadmap without asking again until the final review."
- **`awaiting-final-review`**: say:
  > "Spec `<slug>` passed its final gate and is waiting for your demo verification. Run `/spec-run <slug>` to surface the demo steps and final-gate evidence, then confirm to close or report what failed."
- **`ready` / `running`**: say:
  > "Spec `<slug>` is <status> (updated <date>). Run `/spec-run <slug>` (or the dated folder id if needed) to continue here; a fresh session is optional."
- **`blocked`**: say:
  > "Spec `<slug>` is blocked — the last LEDGER.md entry records why and what unlocks it. Run `/spec-run <slug>` to investigate with a materially different path, or tell me if the external blocker cleared."

Do not infer execution from an orientation-only request. When the current request explicitly says to run, implement, continue, or resume this approved spec, hand control to `/spec-run` without another confirmation.

### Case A — At least one task with `status: awaiting-review`, `in-progress`, or `blocked`

Pick the most recently updated one. The exact prompt depends on its status:

- **`awaiting-review`**: a previous session reported the task complete and is waiting for the user's verification. Say:
  > "Task `<slug>` is `awaiting-review` — a previous session finished it and is waiting for your verification. Open `.claudart/tasks/<task-id>/TASK.md` to review draft Outcomes. Confirm to close, or tell me what didn't work and I'll flip it back to `in-progress`."
- **`in-progress`**: say:
  > "There's an active task `<slug>` (in-progress, updated <date>). Want to resume? I'll read TASK.md and check whether recorded evidence still applies to the next step. Or tell me to start something else."
- **`blocked`**: say:
  > "Task `<slug>` is blocked (updated <date>). Has the blocker cleared? If yes, I'll flip to in-progress and resume. If no, tell me what to work on instead."

Do not infer resumption or completion from an orientation-only request. When the current request already selects or resumes the task, that is explicit direction: **warm the session** by reading `TASK.md`, then only the next action's relevant code and linked supporting files (cap ~5 most relevant references), and follow the Resumption protocol in `.claude/rules/task-management.md` without asking again. The same direct instruction satisfies `planning → in-progress` when the selected task is still planning. Reuse applicable evidence, verify relevant drift or gaps, and never replay all completed checks merely because this is a new session.

### Case B — No active task, but CONTEXT.md carries a handoff: `## Next Session Should Start By` is set, or an active `(no task)` micro-handoff sits under `## In Progress`

Surface the Next-Session line (or the micro-handoff's label and its `Next:` step) and ask:

> "Next-session handoff says: <line>. Pick that up, or start something new?"

### Case C — No active task and no useful handoff in CONTEXT.md

Ask plainly:

> "No active task or session handoff found. What would you like to tackle? If it's non-trivial or multi-session, I can run `/plan <description>` to create a lightweight task workspace with TASK.md only unless supporting material is actually needed."

## Notes

- Keep the report short and actionable.
- **Warm resume for ad-hoc work:** when the user picks up a `(no task)` micro-handoff from `## In Progress` (Case B), read the files on its `Files:` line (cap ~5) before acting — the same warm-up a task resume gets. This is the `/compact`-style "re-read recent files" applied to un-planned work.
- If `.claudart/CONTEXT.md` items look stale (e.g., dated `<!-- since: -->` more than 30 days old), mention that `/checkpoint` should refresh them after this session.
- Flag stale Active tasks per the **Staleness Thresholds** table in `.claude/rules/task-management.md` (stalled `in-progress`, stuck `awaiting-review`, abandoned `planning`) — surface a stuck `awaiting-review` prominently; it is not abandoned, it just needs the user's sign-off.
