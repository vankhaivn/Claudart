---
name: codex-checkpoint
description: Bulk-maintain Codex current state, task/spec indexes, JOURNAL history, and eligible durable project knowledge at a session boundary.
---

# CodexCheckpoint

Update `.codex/CONTEXT.md` to reflect the current state of work from a Codex session. Sync `.codex/tasks/index.md` with current task file states. Append meaningful retired items to `.codex/JOURNAL.md`. Run this at the end of meaningful sessions.

The output is not a log of what happened. It is a declarative snapshot of what is true right now. Lifelong append is the failure mode this command exists to prevent.

Checkpoint is a bulk-maintenance boundary, not the only way to write knowledge. A user may request an eligible knowledge update in natural language at any point; that update follows `.codex/guidelines/knowledge-management.md` immediately and does not require checkpoint.

## Hard Rules

1. `.codex/CONTEXT.md` is overwritten, not appended. Anything not still true right now must be removed.
2. `.codex/CONTEXT.md` hard ceiling: 150 lines, target under 100. If your draft exceeds 150, stop and ask the user to trim manually or run `$codex-refactor-memory`.
3. `.codex/JOURNAL.md` is append-only. Never edit or delete prior entries. Each new entry is a single line.
4. Never add `.codex/JOURNAL.md` as auto-loaded context in `AGENTS.md` or `.codex/guidelines/`. If such an auto-load already exists, remove that wiring and warn the user; JOURNAL remains append-only and outside session context.
5. Skip JOURNAL entirely when there is nothing meaningful to record. Empty entries pollute the file.
6. Task files keep their own bodies; CONTEXT.md never absorbs a task body. But CONTEXT.md should still reference the currently-focused task by slug + path in `## In Progress` so `$codex-start` sees both task and non-task work in one place. Two valid CONTEXT entries:
   - Task reference: `- Working task \`add-jwt-auth\` (see .codex/tasks/2026-05-13-001-add-jwt-auth.md) <!-- since: YYYY-MM-DD -->`
   - Ad-hoc non-task change the user requested without creating a `$codex-plan` (a quick tweak, a transient pivot): CONTEXT is its **only** home, so it gets a **micro-handoff** — intent in the user's words + files of interest + next step (see Step 4) — not just a one-line pointer.
     Checkpoint _syncs_ `tasks/index.md` AND ensures CONTEXT references the focus task, but never copies a task's Steps/Decisions/Surprises into CONTEXT.
7. Subagent threads are not durable project memory. Do not store subagent ids, nicknames, or transient thread state in CONTEXT. Store only durable outcomes: decisions, unresolved blockers, validated findings, changed ownership boundaries, and next steps.

## Procedure

### Step 1: Read Prior State

- Read `.codex/CONTEXT.md`. If it does not exist, treat it as empty.
- Read the last ~30 lines of `.codex/JOURNAL.md` to avoid duplicate entries. If it does not exist, create it later.
- Skim the recent conversation and `git log -10 --oneline` to understand what changed since the last checkpoint.

### Step 2: Triage Every CONTEXT Item

For each item currently in `.codex/CONTEXT.md`, decide one of:

| Status                                                                                              | Action                                                                                                   |
| --------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Still true right now                                                                                | Keep it, refreshing wording if needed. Preserve any existing `<!-- since: YYYY-MM-DD -->` comment.       |
| Done / resolved / merged                                                                            | Drop it from `.codex/CONTEXT.md`. Candidate for JOURNAL if it was a real decision, completion, or pivot. |
| Superseded by newer state                                                                           | Drop the old item and write the new current state.                                                       |
| Broad recurring behavior relevant to future work                                                    | Propose moving it into `.codex/guidelines/` via `$codex-learn`, then drop it from CONTEXT.               |
| Descriptive, durable-beyond-current-work, current, and evidenced project fact (scope may be narrow) | Flag for **Step 6c**, then drop it from CONTEXT after the knowledge write validates.                     |
| WIP, proposed future state, task/acceptance state, or an uncertain/conflicting observation          | Keep it in the task/spec/CONTEXT candidate surface; never promote it as an active fact.                  |

Pure tactical noise is dropped silently.

### Step 3: Add New State from This Session

Add to `.codex/CONTEXT.md` only what is true now:

- Work that is mid-stream, with `file:line` where useful. If the work is being tracked in a task file, reference it by slug + path (e.g., `Working task \`add-jwt-auth\` (see .codex/tasks/2026-05-13-001-add-jwt-auth.md)`). Do not duplicate the task body here.
- Ad-hoc changes the user requested _without_ creating a `$codex-plan` (quick fixes, transient tweaks, mid-flight pivots). These have no task file, so CONTEXT **is** their handoff summary, not just a note. Give each _active_ one a **micro-handoff** (see Step 4 skeleton): the user's intent in their own words, the files of interest with `file:line`, and the next concrete step. Mark them `(no task)`.
- Decisions just made that are not yet codified in guidelines.
- Durable subagent outcomes that still matter after this session, such as a validated finding, unresolved worker/reviewer blocker, or changed ownership boundary. Do not mention subagent thread ids.
- Open questions or blockers currently unresolved.
- The single most useful thing the next session should do first.

A fact that passes the full knowledge capture gate does not belong in CONTEXT — flag it for **Step 6c**. Proposed, uncertain, conflicting, or current-work-only observations remain in their working artifact until verified; CONTEXT holds transient state, not canonical reference knowledge.

Be terse: task references, decisions, and blockers are one short sentence each. Only _active_ `(no task)` work earns the 3-line micro-handoff, and only while it is live — the moment it ships or is abandoned, drop it this same checkpoint (JOURNAL it if it was a real decision/completion). That triage is what keeps CONTEXT under the ceiling.

For every new bullet, append `<!-- since: YYYY-MM-DD -->` using today's date. If you keep an existing bullet, preserve its original `since:` date rather than resetting it. Codex is not documented to strip HTML comments, so keep these comments short; they exist so `$codex-doctor` can flag old decisions that should graduate into guidelines.

### Step 4: Build the New CONTEXT

Use this skeleton. Omit any section that has nothing to say.

```markdown
<!-- .codex/CONTEXT.md - current state of work. Updated by checkpoint. Declarative, not a log. -->

## In Progress

<!-- planned work → one-line pointer; the task file holds the depth -->

- Working task `<slug>` (see .codex/tasks/<file>) <!-- since: YYYY-MM-DD -->
<!-- mission work → one-line pointer; the spec folder holds the depth -->

- Running spec `<slug>` (see .codex/specs/YYYY-MM-DD-<slug>/SPEC.md) <!-- since: YYYY-MM-DD -->
<!-- un-planned work → CONTEXT is the only handoff, so each live thread gets a micro-handoff -->
- <short label> (no task) <!-- since: YYYY-MM-DD -->
  > "<the user's intent, quoted in their own words>"
  - Files: path/to/file.ext:LINE — why it matters
  - Next: <one concrete step>

## Open Questions / Blockers

- [Unresolved things blocking progress] <!-- since: YYYY-MM-DD -->

## Recent Decisions (not yet promoted to guidelines)

- [Decision + brief why; promote when it stabilizes — behavior → .codex/guidelines/ via $codex-learn, eligible descriptive fact → knowledge under its guideline] <!-- since: YYYY-MM-DD -->

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
- `cancelled`: a task was abandoned (used by the Step 6b archive flow; Outcomes in the task file explain why).

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
   - Append the completion line to `.codex/JOURNAL.md` in the Phase 2a format from `.codex/guidelines/task-management.md` (use type `cancelled` instead of `completed` for cancelled tasks).
   - Before archiving, scan the task's `### Memory Hints` and `### Related Docs`. Route only claims that pass the knowledge guideline's full capture gate into **Step 6c**; leave uncertain or task-specific material in the archived task.
   - DO NOT archive `awaiting-review` tasks. Those are explicitly waiting for user confirmation; archiving them defeats the gate. They stay in the top-level `tasks/` folder and appear in the Active list.
4. Rewrite `.codex/tasks/index.md` from scratch per the canonical **"`index.md` Format"** in `.codex/guidelines/task-management.md` — Active includes `awaiting-review` (with its ⏳ marker); Recently Done covers the last 14 days.
5. Enforce that section's 100-line ceiling and trim ladder.
6. Flag stalled tasks: apply the **Staleness Thresholds** table in `.codex/guidelines/task-management.md` (stalled `in-progress`, stuck `awaiting-review`, abandoned `planning`) and list each flagged task in the report.

### Step 6b2: Sync .codex/specs/INDEX.md

Skip entirely if `.codex/specs/` does not exist.

1. Ensure `.codex/specs/done/` exists.
2. List `.codex/specs/*/SPEC.md` from top-level dated folders only (exclude `INDEX.md` and the `done/` subfolder). For each, read frontmatter only (`slug`, `status`, `created`, `updated`).
3. Detect any top-level spec whose `status` is `done` or `cancelled`. These have passed their user gate (or were cancelled) and were not yet archived. For each:
   - Move the entire folder to `.codex/specs/done/<folder-id>/`, preserving the existing dated folder name.
   - Append the completion/cancellation line to `.codex/JOURNAL.md` only if the recent journal tail does not already contain that spec completion/cancellation.
   - Before archiving, scan `NOTES.md` for `→ graduate:` flags: evaluate `knowledge/` flags against the capture gate in Step 6c, surface `$codex-learn` flags as proposals in the report, and clear only flags successfully routed or explicitly retained as candidates.
   - DO NOT archive `awaiting-final-review` specs. Those are explicitly waiting for user confirmation; archiving them defeats the final gate. They stay in the top-level specs folder and appear in the Active list.
4. List `.codex/specs/done/*/SPEC.md`. For each, read frontmatter only (`slug`, `status`, `created`, `updated`). If any archived spec is not `done` or `cancelled`, flag it in the report and do not move it automatically.
5. Rewrite `INDEX.md` per the canonical format in `.codex/guidelines/spec-workflow.md` — Active entries link to top-level dated folders and include every status except `done`/`cancelled` (with the ⏳ marker on `poc-review` and `awaiting-final-review`); Done entries link to `done/<folder-id>/SPEC.md` and include `done`/`cancelled`.
6. Flag stalled specs per the Staleness Thresholds table in `.codex/guidelines/task-management.md`, mapped as: `running` ↔ `in-progress`, `poc-review`/`awaiting-final-review` ↔ `awaiting-review`, `drafting` ↔ `planning`. List flagged specs in the report.
7. Scan each Active spec's `NOTES.md` for `→ graduate:` flags: evaluate `knowledge/` flags in Step 6c, surface `$codex-learn` flags as proposals in the report, and clear only flags successfully routed or explicitly retained as candidates.
8. Do NOT tick roadmap boxes, write LEDGER entries, or change any spec `status` — those transitions belong to `$codex-spec`, `$codex-spec-run`, and the user.

### Step 6c: Graduate Durable Facts to .codex/knowledge/

Skip if no candidate fact surfaced; do not run the knowledge checker for a checkpoint that makes no knowledge mutation.

Before evaluating or writing any candidate, read `.codex/guidelines/knowledge-management.md` in full. It is the source of truth for capture, frontmatter, routing, lifecycle, and validation; do not recreate a second schema here.

For candidates from Step 2, Step 3, task close, or spec NOTES:

1. Distill claims rather than copying chronology or task prose. Promote only claims that are descriptive, durable beyond the current work, current, and evidenced. A fact may be narrowly scoped when its typed `scope` records that boundary.
2. Keep WIP/proposals/state in task/spec/CONTEXT. Route behavior to `$codex-learn`. Keep uncertainty as a candidate; when evidence contradicts an existing canonical owner, mark that owner `review-needed` with a `status_note` instead of asserting a replacement.
3. Read the root router and the smallest relevant maps/topics within the guideline's budget. Patch the existing owner first; create a focused topic only when no owner exists.
4. Write canonical frontmatter and update the topic plus its reachable root/domain-map route atomically. Preserve curated hooks, grouping, ordering, and external routes. Never auto-delete, retire, supersede, or promote an ambiguous unindexed file.
5. After all knowledge mutations in this checkpoint, run `bash .codex/scripts/knowledge-check.sh --root .`. Repair in-scope mechanical failures before reporting success. If the checker is missing, stop the knowledge mutation and report a High-severity installation problem.

The Git diff remains the review surface. Checkpoint may bulk-promote eligible facts, but it is not an exclusive write boundary.

### Step 7: Report

Output a 6-line summary:

1. Lines in new `.codex/CONTEXT.md`.
2. Items kept, dropped, and added.
3. JOURNAL entries appended, or `none`.
4. Tasks synced: active=<n>, archived this run=<n>, stalled=<n>; specs synced: active=<n>, archived this run=<n>, stalled=<n>.
5. Knowledge entries written/updated (list slugs, or `none`), candidates retained/review-needed, checker result, and anything proposed for `$codex-learn`.
6. Reminder that the user must commit when they want this checkpoint persisted in Git history.

Do not run `git commit` yourself or diagnose unrelated uncommitted work during this summary.

## When to Run This Command

Good triggers:

- End of a significant Codex work session.
- Before `/compact` or equivalent context compaction.
- Before switching to a different feature or branch.
- When the user says they will pick this up later.

Bad triggers:

- After every tool call.
- During active debugging where state is not stable yet.
- A natural-language request to distill eligible knowledge mid-session; perform that update directly instead of forcing an unrelated checkpoint.
