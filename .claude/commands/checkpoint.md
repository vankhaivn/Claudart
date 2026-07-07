---
description: Update .claude/CONTEXT.md to reflect the CURRENT state of work (declarative overwrite). Sync .claude/tasks/index.md and .claude/specs/INDEX.md with current file states. Append graduated items to .claude/JOURNAL.md. Graduate durable project facts to .claude/knowledge/. Run at the end of meaningful sessions.
---

You are about to write a session checkpoint. The output is **not a log of what happened** — it is a **declarative snapshot of what is true right now**. Lifelong append is the failure mode this command exists to prevent.

## Hard Rules (read before doing anything)

1. **.claude/CONTEXT.md is overwritten, not appended.** Anything not still true _right now_ must be removed.
2. **.claude/CONTEXT.md hard ceiling: 150 lines, target < 100.** If your draft exceeds 150, STOP and ask the user to trim manually or run `/refactor-memory`.
3. **.claude/JOURNAL.md is append-only.** Never edit or delete prior entries. Each new entry is a single line.
4. **NEVER add `@.claude/JOURNAL.md` to `.claude/CLAUDE.md`.** JOURNAL is intentionally outside the loaded context to save tokens. If you find such an import, remove it and warn the user.
5. **Skip JOURNAL entirely when there is nothing meaningful to record.** Empty entries pollute the file.
6. **Task files keep their own bodies; CONTEXT.md never absorbs a task body.** But CONTEXT.md **should** still reference the currently-focused task by slug + path in `## In Progress` so `/start` sees both task and non-task work in one place. Two valid CONTEXT entries:
   - Task reference: `- Working task \`add-jwt-auth\` (see .claude/tasks/2026-05-13-001-add-jwt-auth.md) <!-- since: YYYY-MM-DD -->`
   - Ad-hoc non-task change the user requested without creating a `/plan` (a quick tweak, a transient pivot): CONTEXT is its **only** home, so it gets a **micro-handoff** — intent in the user's words + files of interest + next step (see Step 4) — not just a one-line pointer.
     Checkpoint _syncs_ `tasks/index.md` AND ensures CONTEXT references the focus task — but never copies a task's Steps/Decisions/Surprises into CONTEXT.
7. **Subagent threads are not durable project memory.** Do not store subagent ids, nicknames, or transient thread state in CONTEXT. Store only durable outcomes: decisions, unresolved blockers, validated findings, changed ownership boundaries, and next steps.

## Procedure

### Step 1 — Read prior state

- Read `.claude/CONTEXT.md`. If it doesn't exist, treat as empty.
- Read the last ~30 lines of `.claude/JOURNAL.md` to know what was already journaled (avoid duplicates). If it doesn't exist, you'll create it later.
- Skim recent conversation + `git log -10 --oneline` to know what's happened since the last checkpoint.

### Step 2 — Triage every section

For each item currently in `.claude/CONTEXT.md`, decide one of:

| Status                                                                                                                   | Action                                                                                                                                                                           |
| ------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Still true right now                                                                                                     | Keep it (refresh wording if needed). Preserve any existing `<!-- since: YYYY-MM-DD -->` comment.                                                                                 |
| Done / resolved / merged                                                                                                 | **Drop from .claude/CONTEXT.md.** Candidate for JOURNAL if it was a real decision, completion, or pivot. Pure tactical noise (e.g., "tried X, didn't work") is dropped silently. |
| Superseded by a newer state                                                                                              | Drop the old, write the new                                                                                                                                                      |
| Still relevant but applies broadly to all future work                                                                    | This has graduated beyond CONTEXT — propose to user that it move to `.claude/rules/` via `/learn`, then drop from CONTEXT                                                        |
| A durable project _fact_ (domain, architecture, integration, glossary, external-doc pointer — descriptive, not behavior) | Flag for **Step 6c** — checkpoint writes it into `.claude/knowledge/` itself (descriptive, distinct from prescriptive rules), then drop from CONTEXT                             |

### Step 3 — Add new state from this session

Add to `.claude/CONTEXT.md` only what's true _now_:

- What you are mid-stream on (with `file:line` if applicable). **If the work is being tracked in a task file**, reference it by slug + path (e.g., `Working task \`add-jwt-auth\` (see .claude/tasks/2026-05-13-001-add-jwt-auth.md)`). Do not duplicate the task body here.
- Ad-hoc changes the user requested _without_ creating a `/plan` (quick fixes, transient tweaks, mid-flight pivots) — these have no task file, so CONTEXT **is** their handoff summary, not just a note. Give each _active_ one a **micro-handoff** (see Step 4 skeleton): the user's intent in their own words, the files of interest with `file:line`, and the next concrete step. Mark them `(no task)`.
- Decisions just made that are not yet codified in rules
- Durable subagent outcomes that still matter after this session, such as a validated finding, an unresolved worker/reviewer blocker, or a changed ownership boundary. Do not mention subagent thread ids.
- Open questions / blockers currently unresolved
- The single most useful thing the next session should do first

A durable project _fact_ surfaced this session (how a subsystem works, an integration detail, a pointer to a doc in another folder) does NOT belong in CONTEXT — flag it for **Step 6c**, which writes it into `.claude/knowledge/`. CONTEXT holds transient state, not reference knowledge.

Be terse: task references, decisions, and blockers are one short sentence each. Only _active_ `(no task)` work earns the 3-line micro-handoff, and only while it is live — the moment it ships or is abandoned, drop it this same checkpoint (JOURNAL it if it was a real decision/completion). That triage is what keeps CONTEXT under the ceiling.

For every new bullet, append `<!-- since: YYYY-MM-DD -->` using today's date. If you keep an existing bullet, preserve its original `since:` date rather than resetting it. These comments make `/doctor` able to flag old decisions that should graduate into rules.

### Step 4 — Build the new .claude/CONTEXT.md

Use this skeleton; **omit any section that has nothing to say**:

```markdown
<!-- .claude/CONTEXT.md — current state of work. Updated by /checkpoint. Declarative, not a log. -->

## In Progress

<!-- planned work → one-line pointer; the task file holds the depth -->

- Working task `<slug>` (see .claude/tasks/<file>) <!-- since: YYYY-MM-DD -->
<!-- mission work → one-line pointer; the spec folder holds the depth -->

- Running spec `<slug>` (see .claude/specs/YYYY-MM-DD-<slug>/SPEC.md) <!-- since: YYYY-MM-DD -->
<!-- un-planned work → CONTEXT is the only handoff, so each live thread gets a micro-handoff -->
- <short label> (no task) <!-- since: YYYY-MM-DD -->
  > "<the user's intent, quoted in their own words>"
  - Files: path/to/file.ext:LINE — why it matters
  - Next: <one concrete step>

## Open Questions / Blockers

- [Unresolved things blocking progress] <!-- since: YYYY-MM-DD -->

## Recent Decisions (not yet promoted to rules)

- [Decision + brief why; promote when it stabilizes — behavior → .claude/rules/ via /learn, durable fact → .claude/knowledge/ via /checkpoint] <!-- since: YYYY-MM-DD -->

## Next Session Should Start By

- [One concrete action, e.g., "run pytest tests/auth/", "ask user about caching strategy"] <!-- since: YYYY-MM-DD -->
```

Count lines. If > 150, STOP and report to the user; do not write the file.

### Step 5 — Append to .claude/JOURNAL.md

For every item that was DROPPED in Step 2 because it was _done/decided/pivoted_, write **one line** to `.claude/JOURNAL.md` in this format:

```
YYYY-MM-DD | <type> | <one-line summary, optional commit ref>
```

Types (use exactly one):

- `decision` — an architectural or non-obvious choice was settled
- `completed` — a chunk of work finished (link commit if available)
- `pivot` — direction changed; old approach abandoned
- `blocker-resolved` — external blocker cleared
- `cancelled` — a task was abandoned (used by the Step 6b archive flow; Outcomes in the task file explain why)

Examples:

```
2026-04-28 | decision | Use JWT with refresh tokens in httpOnly cookie (not localStorage)
2026-04-28 | completed | Auth refactor merged — commit abc1234
2026-04-29 | pivot | Dropped GraphQL, going REST due to caching simplicity
2026-04-30 | blocker-resolved | Redis available in staging
```

If `.claude/JOURNAL.md` doesn't exist, create it with the canonical header (see CLAUDART template) before appending.

If there is nothing to journal, skip this step. Do NOT write empty entries.

### Step 6 — Overwrite .claude/CONTEXT.md

Now (and only now) write the new `.claude/CONTEXT.md` from Step 4.

### Step 6b — Sync .claude/tasks/index.md

This step is independent of CONTEXT.md. Skip entirely if `.claude/tasks/` does not exist.

1. List `.claude/tasks/*.md` (exclude `index.md` and the `done/` subfolder). For each, read only frontmatter (`status`, `slug`, `updated`).
2. List `.claude/tasks/done/*.md`. For each, read frontmatter (`status`, `slug`, `updated`).
3. Detect any task in the top-level `tasks/` folder whose `status` is `done` or `cancelled`. These have been user-confirmed (or cancelled) and not yet archived. For each:
   - Ensure `Outcomes & Retrospective` is filled (read the body to confirm). If empty, flag in the report — do NOT auto-fill; the user or implementing agent should write it.
   - Move the file to `.claude/tasks/done/`.
   - Append the completion line to `.claude/JOURNAL.md` in the Phase 2a format from `.claude/rules/task-management.md` (use type `cancelled` instead of `completed` for cancelled tasks).
   - Before archiving, scan the task's `### Memory Hints` and `### Related Docs`. If they captured project-wide durable facts (not task-specific detail), graduate them to `.claude/knowledge/` in **Step 6c** so they survive archival (project-wide durable facts only — never task-specific detail).
   - **DO NOT archive `awaiting-review` tasks.** Those are explicitly waiting for user confirmation; archiving them defeats the gate. They stay in the top-level `tasks/` folder and appear in the Active list.
4. Rewrite `.claude/tasks/index.md` from scratch per the canonical **"`index.md` Format"** in `.claude/rules/task-management.md` — Active includes `awaiting-review` (with its ⏳ marker); Recently Done covers the last 14 days.
5. Enforce that section's 100-line ceiling and trim ladder.
6. **Flag stalled tasks**: apply the **Staleness Thresholds** table in `.claude/rules/task-management.md` (stalled `in-progress`, stuck `awaiting-review`, abandoned `planning`) and list each flagged task in the report.

### Step 6b2 — Sync .claude/specs/INDEX.md

Skip entirely if `.claude/specs/` does not exist.

1. Ensure `.claude/specs/done/` exists.
2. List `.claude/specs/*/SPEC.md` from top-level dated folders only (exclude `INDEX.md` and the `done/` subfolder). For each, read frontmatter only (`slug`, `status`, `created`, `updated`).
3. Detect any top-level spec whose `status` is `done` or `cancelled`. These have passed their user gate (or were cancelled) and were not yet archived. For each:
   - Move the entire folder to `.claude/specs/done/<folder-id>/`, preserving the existing dated folder name.
   - Append the completion/cancellation line to `.claude/JOURNAL.md` only if the recent journal tail does not already contain that spec completion/cancellation.
   - Before archiving, scan `NOTES.md` for `→ graduate:` flags: route `knowledge/` flags into Step 6c, surface `/learn` flags as proposals in the report, and clear each flag once routed.
   - DO NOT archive `awaiting-final-review` specs. Those are explicitly waiting for user confirmation; archiving them defeats the final gate. They stay in the top-level specs folder and appear in the Active list.
4. List `.claude/specs/done/*/SPEC.md`. For each, read frontmatter only (`slug`, `status`, `created`, `updated`). If any archived spec is not `done` or `cancelled`, flag it in the report and do not move it automatically.
5. Rewrite `INDEX.md` per the canonical format in `.claude/rules/spec-workflow.md` — Active entries link to top-level dated folders and include every status except `done`/`cancelled` (with the ⏳ marker on `poc-review` and `awaiting-final-review`); Done entries link to `done/<folder-id>/SPEC.md` and include `done`/`cancelled`.
6. Flag stalled specs per the Staleness Thresholds table in `.claude/rules/task-management.md`, mapped as: `running` ↔ `in-progress`, `poc-review`/`awaiting-final-review` ↔ `awaiting-review`, `drafting` ↔ `planning`. List flagged specs in the report.
7. Scan each Active spec's `NOTES.md` for `→ graduate:` flags: route `knowledge/` flags into Step 6c, surface `/learn` flags as proposals in the report, and clear each flag once routed.
8. Do NOT tick roadmap boxes, write LEDGER entries, or change any spec `status` — those transitions belong to `/spec`, `/spec-run`, and the user.

### Step 6c — Graduate durable facts to .claude/knowledge/

Skip if no durable project fact surfaced this session (the common case for routine checkpoints).

A **durable project fact** is descriptive, project-wide, and outlives this session: how a subsystem works, an integration detail, a domain/glossary term, or a pointer to a doc in another folder. It is NOT transient state (that stays in CONTEXT) and NOT a behavioral rule (that graduates to `.claude/rules/` via `/learn`). When unsure whether a fact is durable, leave it in CONTEXT/JOURNAL — do not write a speculative entry. Never write secrets.

For each durable fact flagged in Step 2, Step 3, or Step 6b:

1. Read `.claude/knowledge/INDEX.md` (the map). If `.claude/knowledge/` is missing, create it with the INDEX scaffold first.
2. If an existing entry already covers the topic, **update** it (merge the fact, bump `updated:` to today). Otherwise **create** `.claude/knowledge/<kebab-slug>.md` using the frontmatter template in INDEX (`name`/`description`/`type`/`updated`; optional `sources`/`related`/`verify`). Keep it descriptive — never `MUST`/`NEVER` (that belongs in rules).
3. In the **same step**, add or update the one-line INDEX entry so the map never drifts from the files: `- [Title](<slug>.md) — <hook> · <type> · updated YYYY-MM-DD`.

This is an automatic write, like the CONTEXT/JOURNAL/index writes above — the git diff is the review gate, so the user sees exactly what was captured before committing. Do not duplicate an entry that already exists.

### Step 7 — Report

Output a 6-line summary:

1. Lines in new .claude/CONTEXT.md
2. Items kept / dropped / added (counts)
3. JOURNAL entries appended (or "none")
4. Tasks synced: active=<n>, archived this run=<n>, stalled=<n>; specs synced: active=<n>, archived this run=<n>, stalled=<n>
5. Knowledge entries written/updated this run (list slugs, or "none"); plus anything proposed for `/learn` (recurring behavior → rules)
6. Reminder for the user to commit so the checkpoint enters git history

Do not run `git commit` yourself.

## When to Run This Command

Good triggers:

- End of a significant work session
- Before `/compact`
- Before switching to a different feature/branch
- When the user says "let's pick this up tomorrow"
- Right before closing your laptop

Bad triggers:

- After every single tool call (overhead with no benefit)
- During active back-and-forth debugging (state isn't stable yet)
