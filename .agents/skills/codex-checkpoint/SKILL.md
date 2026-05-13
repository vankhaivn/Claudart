---
name: codex-checkpoint
description: Update Codex current state by rewriting .codex/CONTEXT.md, syncing .codex/tasks/index.md with task file states, and appending meaningful retired items to .codex/JOURNAL.md.
---

# CodexCheckpoint

Update `.codex/CONTEXT.md` to reflect the current state of work from a Codex session. Sync `.codex/tasks/index.md` with current task file states. Append meaningful retired items to `.codex/JOURNAL.md`. Run this at the end of meaningful sessions.

The output is not a log of what happened. It is a declarative snapshot of what is true right now. Lifelong append is the failure mode this command exists to prevent.

## Hard Rules

1. `.codex/CONTEXT.md` is overwritten, not appended. Anything not still true right now must be removed.
2. `.codex/CONTEXT.md` hard ceiling: 150 lines, target under 100. If your draft exceeds 150, stop and ask the user to trim manually or run `$codex-refactor-memory`.
3. `.codex/JOURNAL.md` is append-only. Never edit or delete prior entries. Each new entry is a single line.
4. Never add `.codex/JOURNAL.md` as auto-loaded context in `AGENTS.md` or `.codex/guidelines/`.
5. Skip JOURNAL entirely when there is nothing meaningful to record. Empty entries pollute the file.
6. Task files keep their own bodies; CONTEXT.md never absorbs a task body. But CONTEXT.md should still reference the currently-focused task by slug + path in `## In Progress` so `$codex-start` sees both task and non-task work in one place. Two valid CONTEXT entries:
   - Task reference: `- Working task \`add-jwt-auth\` (see .codex/tasks/2026-05-13-add-jwt-auth.md) <!-- since: YYYY-MM-DD -->`
   - Ad-hoc non-task change the user requested without creating a `$codex-plan` (a quick tweak, a transient pivot): `- Tweaking rate-limit constant in src/api/limits.ts:42 (no task) <!-- since: YYYY-MM-DD -->`
   Checkpoint *syncs* `tasks/index.md` AND ensures CONTEXT references the focus task, but never copies a task's Steps/Decisions/Surprises into CONTEXT.

## Procedure

### Step 1: Read Prior State

- Read `.codex/CONTEXT.md`. If it does not exist, treat it as empty.
- Read the last ~30 lines of `.codex/JOURNAL.md` to avoid duplicate entries. If it does not exist, create it later.
- Skim the recent conversation and `git log -10 --oneline` to understand what changed since the last checkpoint.

### Step 2: Triage Every CONTEXT Item

For each item currently in `.codex/CONTEXT.md`, decide one of:

| Status | Action |
|---|---|
| Still true right now | Keep it, refreshing wording if needed. Preserve any existing `<!-- since: YYYY-MM-DD -->` comment. |
| Done / resolved / merged | Drop it from `.codex/CONTEXT.md`. Candidate for JOURNAL if it was a real decision, completion, or pivot. |
| Superseded by newer state | Drop the old item and write the new current state. |
| Broadly relevant to all future work | Propose moving it into `.codex/guidelines/` via `$codex-learn`, then drop it from CONTEXT. |

Pure tactical noise is dropped silently.

### Step 3: Add New State from This Session

Add to `.codex/CONTEXT.md` only what is true now:

- Work that is mid-stream, with `file:line` where useful. If the work is being tracked in a task file, reference it by slug + path (e.g., `Working task \`add-jwt-auth\` (see .codex/tasks/2026-05-13-add-jwt-auth.md)`). Do not duplicate the task body here.
- Ad-hoc changes the user requested *without* creating a `$codex-plan` (quick fixes, transient tweaks, mid-flight pivots). These have no task file, so CONTEXT is their only home. Mark them with `(no task)` so they are obviously distinct from task-tracked work.
- Decisions just made that are not yet codified in guidelines.
- Open questions or blockers currently unresolved.
- The single most useful thing the next session should do first.

Be terse. One bullet should be one short sentence.

For every new bullet, append `<!-- since: YYYY-MM-DD -->` using today's date. If you keep an existing bullet, preserve its original `since:` date rather than resetting it. Codex is not documented to strip HTML comments, so keep these comments short; they exist so `$codex-doctor` can flag old decisions that should graduate into guidelines.

### Step 4: Build the New CONTEXT

Use this skeleton. Omit any section that has nothing to say.

```markdown
<!-- .codex/CONTEXT.md - current state of work. Updated by checkpoint. Declarative, not a log. -->

## In Progress
- [What is mid-stream right now, with file:line] <!-- since: YYYY-MM-DD -->

## Open Questions / Blockers
- [Unresolved things blocking progress] <!-- since: YYYY-MM-DD -->

## Recent Decisions (not yet promoted to rules)
- [Decision + brief why; promote via learn when it stabilizes] <!-- since: YYYY-MM-DD -->

## Next Session Should Start By
- [One concrete action, e.g. "run pytest tests/auth/" or "ask user about caching strategy"] <!-- since: YYYY-MM-DD -->
```

Count lines. If more than 150, stop and report to the user. Do not write the file.

### Step 5: Append to JOURNAL

For every item dropped in Step 2 because it was done, decided, pivoted, or resolved, write one line to `.codex/JOURNAL.md` in this format:

```text
YYYY-MM-DD | <type> | <one-line summary, optional commit ref>
```

Types:

- `decision`: an architectural or non-obvious choice was settled.
- `completed`: a chunk of work finished.
- `pivot`: direction changed and the old approach was abandoned.
- `blocker-resolved`: an external blocker cleared.

Examples:

```text
2026-04-28 | decision | Use JWT with refresh tokens in httpOnly cookie, not localStorage
2026-04-28 | completed | Auth refactor merged, commit abc1234
2026-04-29 | pivot | Dropped GraphQL, going REST due to caching simplicity
2026-04-30 | blocker-resolved | Redis available in staging
```

If `.codex/JOURNAL.md` does not exist, create it with the canonical CLAUDART header before appending.

If there is nothing to journal, skip this step. Do not write empty entries.

### Step 6: Overwrite CONTEXT

Now, and only now, write the new `.codex/CONTEXT.md` from Step 4.

### Step 6b: Sync .codex/tasks/index.md

This step is independent of CONTEXT.md. Skip entirely if `.codex/tasks/` does not exist.

1. List `.codex/tasks/*.md` (exclude `index.md` and the `done/` subfolder). For each, read only frontmatter (`status`, `slug`, `updated`).
2. List `.codex/tasks/done/*.md`. For each, read frontmatter (`status`, `slug`, `updated`).
3. Detect any task in the top-level `tasks/` folder whose `status` is `done` or `cancelled`. These have been user-confirmed (or cancelled) and not yet archived. For each:
   - Ensure `Outcomes & Retrospective` is filled (read the body to confirm). If empty, flag in the report — do not auto-fill; the user or implementing agent should write it.
   - Move the file to `.codex/tasks/done/`.
   - Append one line to `.codex/JOURNAL.md`:
     `YYYY-MM-DD | completed | <slug> — <one-line outcome>, see tasks/done/<filename>`
     (Use `cancelled` instead of `completed` for cancelled tasks.)
   - DO NOT archive `awaiting-review` tasks. Those are explicitly waiting for user confirmation; archiving them defeats the gate. They stay in the top-level `tasks/` folder and appear in the Active list.
4. Rewrite `.codex/tasks/index.md` from scratch using the canonical skeleton:
   ```markdown
   <!-- .codex/tasks/index.md — dashboard of task documents. Maintained by $codex-plan and $codex-checkpoint. -->

   ## Active
   - [<slug>](<filename>) — <status> — updated <YYYY-MM-DD>

   ## Recently Done (last 14 days)
   - [<slug>](done/<filename>) — done <YYYY-MM-DD>
   ```
   - `Active`: every task in top-level `tasks/` (status: planning, in-progress, awaiting-review, blocked).
   - When listing `awaiting-review` entries, append ` ⏳ awaiting your confirmation` to the line so the dashboard makes the gate visible.
   - `Recently Done`: every task in `tasks/done/` whose `updated:` date is within the last 14 days. Older completed tasks remain on disk but drop out of the index.
   - If a section has no entries, write `- _(none)_` instead.
5. Count lines. If `index.md` > 100 lines, trim `Recently Done` first (shorten to last 7 days, then last 3 days, then drop the section).
6. Flag stalled tasks: list each in the report.
   - `status: in-progress` AND `updated:` > 7 days old -> stalled work. Suggest flipping to `blocked`/`cancelled` or resuming.
   - `status: awaiting-review` AND `updated:` > 3 days old -> stuck awaiting confirmation. Suggest the user verify and confirm (or reject) so the task can move forward.
   - `status: planning` AND `updated:` > 14 days old -> abandoned plan. Suggest cancellation.

### Step 7: Report

Output a 6-line summary:

1. Lines in new `.codex/CONTEXT.md`.
2. Items kept, dropped, and added.
3. JOURNAL entries appended, or `none`.
4. Tasks synced: active=<n>, archived this run=<n>, stalled=<n>.
5. Anything proposed for `$codex-learn` graduation.

Do not run `git commit` yourself. Do not mention uncommitted changes — the user commits independently.

## When to Run This Command

Good triggers:

- End of a significant Codex work session.
- Before `/compact` or equivalent context compaction.
- Before switching to a different feature or branch.
- When the user says they will pick this up later.

Bad triggers:

- After every tool call.
- During active debugging where state is not stable yet.
