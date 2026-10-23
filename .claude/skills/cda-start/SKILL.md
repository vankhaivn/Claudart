---
name: cda-start
description: Orient a new CLAUDART session from current context, recent git history, and active task workspaces
disable-model-invocation: true
---

Start this session with a lightweight CLAUDART orientation. This skill is read-only, with one exception: consuming the handoff baton (Case H) deletes `.claudart/HANDOFF.md` once the user resumes or discards it.

The user's current request controls what happens after orientation. When it explicitly selects a task or spec, or says to run, continue or resume the unambiguous current focus, complete the lightweight inventory, then load that workflow's canonical files and continue under its authorization rules without asking again: hand an approved spec to `/cda-spec-run`, and resume a task under the Resumption protocol in `.claude/rules/task-management.md`. The same direct instruction satisfies `planning → in-progress` for a task still in planning. An orientation-only request never implies execution, resumption or completion. A startup scan never overrides or delays an explicit request.

## Procedure

1. Check `.claudart/HANDOFF.md`. If present, read it in full and note its `created:` date; Case H covers consumption. If absent, continue silently.
2. `.claudart/OWNER.md` is loaded through `CLAUDE.md`. If `CLAUDE.md` does not import it, read it and report that the loader needs the import. Follow it for the session and do not summarize it in the report. Read `.claudart/CONTEXT.md` if it exists; if it is missing, say the project has no shared project context yet and suggest `/cda-checkpoint` after meaningful work.
3. Read `.claudart/tasks/index.md` if it exists and extract `## Active`. If missing, use shallow `.claudart/tasks/*/TASK.md` discovery and report that `/cda-checkpoint` should regenerate the index; a missing cache does not prove there are no tasks.
4. Resolve Active entries only to `.claudart/tasks/<YYYY-MM-DD-NNN-slug>/TASK.md` and verify existence. Use valid top-level workspace ids during fallback discovery; exclude `done/` itself and symlinked workspaces or `TASK.md` files. Read `TASK.md` frontmatter (`status`, `updated`, `created`, `slug`, `reviewer`) only; report a missing or invalid `reviewer` as incomplete metadata without guessing ownership; flag missing/broken references for `/cda-checkpoint`. Do not read task bodies or artifact contents, recurse into workspaces, or create supporting files during startup.
5. Read `.claudart/knowledge/INDEX.md` if it exists — the root router only. Count visible route lines under `## Knowledge` that match the canonical Markdown route grammar; ignore HTML comments/templates and `- _(none)_`, so a seed index reports zero. Do not read domain maps, topic files, `.claude/rules/knowledge-management.md` or its maintenance reference during startup, and do not validate freshness or dead links. Later work that needs knowledge loads the rule and follows its bounded retrieval.
6. Read `.claudart/specs/INDEX.md` if it exists — the INDEX only — and extract entries under `## Active`. Do not read SPEC, ROADMAP, NOTES or LEDGER bodies.
7. Run `git log -3 --oneline`. If the directory is not a git repo or has fewer than three commits, report what is available.
8. Extract only `## In Progress`, `## Next Session Should Start By` and `## Open Questions / Blockers` from `.claudart/CONTEXT.md` when present.
9. Do not read `.claudart/JOURNAL.md` or task bodies in `.claudart/tasks/done/`, and do not run `/cda-doctor` or `bash .claude/scripts/knowledge-check.sh`.

## Output Format

```markdown
## Session Ready

**Handoff:** [present — created <date>, objective one-liner; or "None"]
**Current focus:** [In Progress section, or "None recorded"]
**Last 3 commits:** [git log -3 --oneline output, compact]
**Active tasks:** [list of "<slug> (<status>, updated <date>)" from tasks/index.md, or "None"]
**Active specs:** [list of "<slug> (<status>, updated <date>)" from specs/INDEX.md, or "None"]
**Project knowledge:** [N root routes in knowledge/INDEX.md, or "none"]
**Start by:** [Next Session Should Start By section, or the case prompt below]
**Open blockers:** [Open Questions / Blockers section, or "None recorded"]
```

## Shared Handoff Safety

The handoff slot is shared across runtimes. Before deleting a resumed or discarded baton, re-read it and confirm it is the same content inspected for that decision. If it changed, preserve the new content and report the conflict. Serialize handoff consumption with other writers; this check is not an atomic lock. Do not filter shared task/spec discovery by the recorded `agent` value.

## What to Ask After the Report

Without an explicit request, Case H takes precedence; Case S coexists with Case A (report both, lead with whichever is awaiting the user).

### Case H — `.claudart/HANDOFF.md` exists

Surface it before anything else: its objective and recorded next step, and offer to resume from it or discard it.

- If its `created:` is more than 7 days old, lead with that: the recorded hypothesis may no longer match the code.
- On resume, read the files referenced in Evidence and Next Step (cap ~5), verify the baton's claims against current code, surface any drift, then delete `.claudart/HANDOFF.md`. The baton is consumed exactly once.
- On discard, delete the file without acting on it.
- If the user starts unrelated work instead, ask once whether to keep the baton or delete it. A kept baton stays on disk untouched; `/cda-doctor` flags it when stale.

Never act on baton content before verifying it against the current code.

### Case S — `.claudart/specs/INDEX.md` lists an Active spec

For the most relevant spec (prefer `drafting`/`poc-review`/`awaiting-final-review`, then `running`, then `ready`, then `blocked`), tell the user:

- `drafting`: run `/cda-spec` to continue in its existing dated folder.
- `poc-review`: it waits for their review — the POC in `artifacts/`, then SPEC.md and ROADMAP.md in its dated folder. Approving is a standing approval: `/cda-spec-run` then executes the whole roadmap without asking again until the final review.
- `awaiting-final-review`: it passed its final gate and waits for their demo verification; `/cda-spec-run <slug>` surfaces the demo steps and final-gate evidence, then they confirm or report what failed.
- `ready` / `running`: run `/cda-spec-run <slug>` (or the dated folder id) to continue here; a fresh session is optional.
- `blocked`: the last LEDGER.md entry records why and what unlocks it; `/cda-spec-run <slug>` investigates with a materially different path, or the user reports that the external blocker cleared.

### Case A — At least one task with `status: awaiting-review`, `in-progress`, or `blocked`

Pick the most recently updated one:

- `awaiting-review`: report that it awaits user review. On resume, read the task and present the reviewable result plus the specific outstanding acceptance under the completion contract. Do not ask the user to read `TASK.md` or repeat evidenced QA.
- `in-progress`: offer to resume it, with its updated date and reviewer; on resume, check whether recorded evidence still applies to the next step.
- `blocked`: ask whether the blocker cleared; if it did, flip the task to in-progress and resume.

On resume, read `TASK.md`, then only the next action's relevant code and linked supporting files (cap ~5), and follow the Resumption protocol in `.claude/rules/task-management.md`.

### Case B — No active task, but CONTEXT.md carries a handoff

When `## Next Session Should Start By` is set or an active `(no task)` micro-handoff sits under `## In Progress`, surface that line (or the micro-handoff's label and `Next:` step) and ask whether to pick it up or start something new. Before acting on a picked-up micro-handoff, read the files on its `Files:` line (cap ~5).

### Case C — No active task and no useful handoff

Ask what to tackle. For non-trivial or multi-session work, offer `/cda-task <description>`, which creates `TASK.md` only unless supporting material is needed.

## Notes

- Keep the report short and actionable.
- If CONTEXT items carry a `<!-- since: -->` date more than 30 days old, mention that `/cda-checkpoint` should refresh them.
- Flag stale Active tasks per the Staleness Thresholds in `.claude/rules/task-management.md`; surface a stuck `awaiting-review` prominently as waiting for the user's sign-off, not abandoned.
