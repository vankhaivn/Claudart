---
name: cda-checkpoint
description: Rewrite current context, sync task/spec indexes, append meaningful history, and bulk-maintain eligible durable descriptive knowledge. Use only when the user asks for it, by command or in words.
---

Write a session checkpoint: a declarative snapshot of what is true now, not a log of what happened.

## Rules

1. `.claudart/CONTEXT.md` is overwritten, not appended. Remove anything that is no longer true.
2. `.claudart/CONTEXT.md` has a hard ceiling of 150 lines, target under 100. Over the ceiling, ask the user to trim manually or run `/cda-tidy`. Each bullet is one short sentence. Evidence, run or job IDs, timestamps, test totals and quoted chat stay in the task, commit or JOURNAL; CONTEXT links to them.
3. `.claudart/JOURNAL.md` is append-only: never edit or delete prior entries, and write each new entry as a single line. Never add it as auto-loaded context in `CLAUDE.md` or `.claude/rules/`. If such wiring already exists, remove it and warn the user.
4. CONTEXT never absorbs a task body. `## In Progress` points to the focused task or spec by slug and path, so `/cda-start` sees task and non-task work in one place.
5. Shared state belongs to the project, not this session. Preserve another session's unresolved work, blockers and next actions unless current evidence or the user resolves them. Absence from this conversation is not completion. Re-read CONTEXT and any index immediately before writing; if the file changed since inspection, reconcile the delta before replacing it. Serialize shared writes; this workflow is not a concurrent merge service.

## Procedure

### Step 1 — Read prior state

- Read `.claudart/CONTEXT.md`; treat a missing file as empty.
- Read the last ~30 lines of `.claudart/JOURNAL.md` to avoid duplicate entries.
- Skim the recent conversation and `git log -10 --oneline` for what changed since the last checkpoint.

### Step 2 — Triage every section

For each item currently in `.claudart/CONTEXT.md`, decide one of using current evidence; retain unresolved work outside this session:

| Status                                                                                                 | Action                                                                                                                                                                                                                                  |
| ------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Still true right now                                                                                   | Keep it (refresh wording if needed). Preserve any existing `<!-- since: YYYY-MM-DD -->` comment.                                                                                                                                        |
| Done / resolved / merged                                                                               | Drop it from CONTEXT. Candidate for JOURNAL if it was a real decision, completion, or pivot. Pure tactical noise (e.g., "tried X, didn't work") is dropped silently.                                                                    |
| Superseded by a newer state                                                                            | Drop the old, write the new                                                                                                                                                                                                             |
| A standing owner preference or approval about working with the owner, stated or confirmed by the owner | Record it in `.claudart/OWNER.md` under `.claude/rules/ai-behavior.md` if it is missing, then drop it from CONTEXT; a correction about work an existing rule owns goes to that rule (next row); a one-time approval stays with its work |
| A durable convention for a code area, workflow, or other area a rule owns                              | Propose `.claude/rules/` via `/cda-learn`, then drop it from CONTEXT                                                                                                                                                                    |
| A fact that may pass the knowledge capture gates                                                       | Flag for Step 6c; it may be local in scope but must be descriptive, durable beyond this work, current, and evidenced                                                                                                                    |
| Uncertain, conflicting, WIP, or proposed state                                                         | Keep it as a candidate in the owning task/spec/CONTEXT surface; do not promote it as canonical knowledge                                                                                                                                |

### Step 3 — Add new state from this session

Add to `.claudart/CONTEXT.md` only what is true now:

- Work in progress, with `file:line` where useful. Tracked work gets the task or spec pointer from the Step 4 skeleton.
- Each active change the user requested without a `/cda-task` gets a `(no task)` micro-handoff from the Step 4 skeleton, because CONTEXT is its only home. Keep it only while the work is live; when it ships or is abandoned, drop it in this checkpoint and journal it if it was a real decision or completion.
- Decisions just made that are not yet codified in rules.
- Durable subagent outcomes that still matter, such as a validated finding, an unresolved worker or reviewer blocker, or a changed ownership boundary. Never store subagent ids, nicknames, or thread state.
- Open questions and blockers still unresolved.
- The single most useful thing the next session should do first.

A standing owner correction, preference, or approval from this session belongs in `.claudart/OWNER.md`, not CONTEXT; route it, and every other new item, as the Step 2 table routes existing ones.

Task references, decisions, and blockers are one short sentence each. Append `<!-- since: YYYY-MM-DD -->` with today's date to every new bullet, and keep the original date on a kept bullet; `/cda-doctor` uses it to flag old decisions.

### Step 4 — Build the new .claudart/CONTEXT.md

Use this skeleton and omit any section that has nothing to say:

```markdown
<!-- .claudart/CONTEXT.md — current state of work. Updated by /cda-checkpoint. Declarative, not a log. -->

## In Progress

<!-- planned work → one-line pointer; TASK.md routes the task details -->

- Working task `<slug>` (see .claudart/tasks/<task-id>/TASK.md) <!-- since: YYYY-MM-DD -->
<!-- mission work → one-line pointer; the spec folder holds the depth -->

- Running spec `<slug>` (see .claudart/specs/YYYY-MM-DD-<slug>/SPEC.md) <!-- since: YYYY-MM-DD -->
<!-- un-planned work → CONTEXT is the only handoff, so each live thread gets a micro-handoff -->
- <short label> (no task) <!-- since: YYYY-MM-DD -->
  - Intent: <the requested outcome in one sentence; quote only a short constraint whose exact wording matters>
  - Files: path/to/file.ext:LINE — why it matters
  - Next: <one concrete step>

## Open Questions / Blockers

- [Unresolved things blocking progress] <!-- since: YYYY-MM-DD -->

## Recent Decisions (not yet promoted to rules)

- [Decision and its reason in one sentence; behavior → .claude/rules/ via /cda-learn; eligible descriptive fact → its owner under the knowledge rule] <!-- since: YYYY-MM-DD -->

## Next Session Should Start By

- [One concrete action, e.g., "run pytest tests/auth/", "ask user about caching strategy"] <!-- since: YYYY-MM-DD -->
```

A micro-handoff lists at most three files. Count lines; if the draft exceeds 150, stop and report to the user without writing the file.

### Step 5 — Append to .claudart/JOURNAL.md

For every item dropped in Step 2 because it was done, decided, or pivoted, append one line:

```
YYYY-MM-DD | <type> | <one short summary, optional commit ref>
```

Use exactly one type:

- `decision` — an architectural or non-obvious choice was settled
- `completed` — a chunk of work finished (link commit if available)
- `pivot` — direction changed; old approach abandoned
- `blocker-resolved` — external blocker cleared
- `cancelled` — a task was abandoned (used by the Step 6b archive flow; Outcomes in the task file explain why)

Example: `2026-04-28 | decision | Use JWT with refresh tokens in httpOnly cookie (not localStorage)`

If `.claudart/JOURNAL.md` does not exist, create it with the canonical header before appending. If there is nothing meaningful to journal, skip this step; never write empty entries.

### Step 6 — Overwrite .claudart/CONTEXT.md

Write the new `.claudart/CONTEXT.md` from Step 4.

### Step 6b — Sync .claudart/tasks/index.md

This step is independent of CONTEXT.md. Skip it if `.claudart/tasks/` does not exist.

1. List `.claudart/tasks/*/TASK.md` from valid top-level workspace ids only, excluding `done/` itself and symlinked workspaces or `TASK.md` files. Read only frontmatter (`status`, `slug`, `created`, `updated`, `reviewer`). Never recursively enumerate task bodies or parse attachments as tasks.
2. List `.claudart/tasks/done/*/TASK.md` at that exact depth. Read the same metadata. Flag an archived nonterminal task or a validly named workspace missing `TASK.md`; do not move, repair, or infer status automatically.
3. Move the entire workspace of each top-level task whose status is `done` or `cancelled` with the Shared archive flow in `.claude/rules/task-management.md`, under these conditions:
   - Require a valid `reviewer: user | agent` before archiving; report incomplete metadata without inventing acceptance ownership.
   - Confirm `Outcomes & Retrospective` is filled in `TASK.md`. If empty, report it; do not invent the outcome.
   - Before archiving, inspect only `TASK.md` Memory Hints and Related Docs for knowledge candidates for Step 6c. Do not bulk-read supporting files or promote task/WIP/proposal state.
   - Append the flow's JOURNAL line only if the recent journal tail does not already contain it, with type `cancelled` for a cancellation.
   - Never archive `awaiting-review` tasks; that state requires `reviewer: user`. Report inconsistent reviewer/status metadata without requesting a completion signal. Checkpoint never changes task status, reviewer, or acceptance boxes.
4. Rewrite `.claudart/tasks/index.md` per the `index.md` Format in `.claude/rules/task-management.md`, including its 100-line ceiling and trim ladder. Report any still-unarchived terminal workspace rather than linking it to a nonexistent archive. Missing `artifacts/` is normal; checkpoint never creates supporting files.
5. Flag stalled tasks using the Staleness Thresholds in `.claude/rules/task-management.md`; surface the needed user decision rather than cancelling or reopening work automatically.

### Step 6b2 — Sync .claudart/specs/INDEX.md

Skip this step if `.claudart/specs/` does not exist.

1. Ensure `.claudart/specs/done/` exists.
2. List `.claudart/specs/*/SPEC.md` from top-level dated folders only (exclude `INDEX.md` and the `done/` subfolder). For each, read frontmatter only (`slug`, `status`, `created`, `updated`).
3. Scan `NOTES.md` of each Active spec, and of each terminal spec before archiving it, for `→ graduate:` flags: route `knowledge/` flags into Step 6c and surface `/cda-learn` flags as proposals. Clear only a claim that was successfully promoted or deliberately reclassified; keep unresolved candidates flagged in NOTES.
4. For each top-level spec whose `status` is `done` or `cancelled`:
   - Move the entire folder to `.claudart/specs/done/<folder-id>/`, preserving the dated folder name. Repair knowledge `sources` that point into the moved folder as the closure in `.claude/rules/spec-workflow.md` defines.
   - Append the completion or cancellation line to `.claudart/JOURNAL.md` only if the recent journal tail does not already contain it.
   - Never archive `awaiting-final-review` specs; they wait for the user's final confirmation and stay in the Active list.
5. List `.claudart/specs/done/*/SPEC.md` frontmatter. Flag any archived spec that is not `done` or `cancelled`; do not move it automatically.
6. Rewrite `INDEX.md` per the format in `.claude/rules/spec-workflow.md`.
7. Flag stalled specs per the Staleness Thresholds in `.claude/rules/task-management.md`, mapped as `running` ↔ `in-progress`, `poc-review`/`awaiting-final-review` ↔ `awaiting-review`, `drafting` ↔ `planning`. Measure execution activity from the latest ROADMAP/LEDGER activity under the spec rule, not the SPEC contract date. Report missing activity evidence without inventing an update.
8. Never tick ROADMAP boxes, write LEDGER entries, or change a spec `status`; those transitions belong to `/cda-spec`, `/cda-spec-run`, and the user.

### Step 6c — Route durable facts to their owners

Skip this step if no candidate from this session, task closeout, or spec NOTES passes the capture gates in `.claude/rules/knowledge-management.md`. Checkpoint is bulk maintenance, not the only knowledge write gate; mid-session promotion under that rule remains valid.

For each eligible claim, read the knowledge rule, patch the owner under `.claude/references/knowledge-maintenance.md`, and update its reachable route in the same change. Checkpoint does not take over project-document maintenance or require a docs audit. Never write secrets. Run `bash .claude/scripts/knowledge-check.sh` after the final knowledge mutation; if it fails, report the exact findings and do not claim the update healthy. These writes are autonomous; the Git diff is the review surface.

### Step 6d — Persist through the shared Git workflow

A checkpoint is durable in Git only when its in-scope delta is committed. For Git persistence, read `.claude/rules/git-workflow.md`; that shared contract owns higher-scope/runtime, repository, user, staging, identity, and remote/history rules.

The checkpoint-owned delta is verified in-scope session work that is still uncommitted plus the CONTEXT, JOURNAL, index, archive, owner-profile and knowledge maintenance this checkpoint produced. When the shared Git workflow authorizes a local commit, stage only the owned paths or hunks and commit that delta with the repository's message convention; do nothing when it is already persisted. A spec with `commits: user` stays no-auto-commit for its spec-owned changes; checkpoint does not bypass that choice. If policy blocks the commit, staging cannot be isolated safely, or the commit fails, leave the worktree intact and report `CHECKPOINT NOT PERSISTED IN GIT: commit required` plus the reason. Never describe an uncommitted checkpoint as durable.

### Step 7 — Report

Output a 6-line summary:

1. Lines in new .claudart/CONTEXT.md
2. Items kept / dropped / added (counts)
3. JOURNAL entries appended (or "none")
4. Tasks synced: active=<n>, archived this run=<n>, stalled=<n>; specs synced: active=<n>, archived this run=<n>, stalled=<n>
5. Knowledge entries written/updated this run (list slugs, or "none"); owner-profile entries added or updated (or "none"); plus anything proposed for `/cda-learn` (recurring behavior → rules)
6. Git persistence: the new commit SHA and summary when committed, otherwise `CHECKPOINT NOT PERSISTED IN GIT: commit required` plus the reason. Do not diagnose unrelated uncommitted work in this summary.
