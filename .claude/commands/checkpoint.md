---
description: Update .claude/CONTEXT.md to reflect the CURRENT state of work (declarative overwrite). Sync .claude/tasks/index.md with current task file states. Append graduated items to .claude/JOURNAL.md. Graduate durable project facts to .claude/knowledge/. Run at the end of meaningful sessions.
---

You are about to write a session checkpoint. The output is **not a log of what happened** — it is a **declarative snapshot of what is true right now**. Lifelong append is the failure mode this command exists to prevent.

## Hard Rules (read before doing anything)

1. **.claude/CONTEXT.md is overwritten, not appended.** Anything not still true *right now* must be removed.
2. **.claude/CONTEXT.md hard ceiling: 150 lines, target < 100.** If your draft exceeds 150, STOP and ask the user to trim manually or run `/refactor-memory`.
3. **.claude/JOURNAL.md is append-only.** Never edit or delete prior entries. Each new entry is a single line.
4. **NEVER add `@.claude/JOURNAL.md` to `.claude/CLAUDE.md`.** JOURNAL is intentionally outside the loaded context to save tokens. If you find such an import, remove it and warn the user.
5. **Skip JOURNAL entirely when there is nothing meaningful to record.** Empty entries pollute the file.
6. **Task files keep their own bodies; CONTEXT.md never absorbs a task body.** But CONTEXT.md **should** still reference the currently-focused task by slug + path in `## In Progress` so `/start` sees both task and non-task work in one place. Two valid CONTEXT entries:
   - Task reference: `- Working task \`add-jwt-auth\` (see .claude/tasks/2026-05-13-001-add-jwt-auth.md) <!-- since: YYYY-MM-DD -->`
   - Ad-hoc non-task change the user requested without creating a `/plan` (a quick tweak, a transient pivot): CONTEXT is its **only** home, so it gets a **micro-handoff** — intent in the user's words + files of interest + next step (see Step 4) — not just a one-line pointer.
   Checkpoint *syncs* `tasks/index.md` AND ensures CONTEXT references the focus task — but never copies a task's Steps/Decisions/Surprises into CONTEXT.

## Procedure

### Step 1 — Read prior state

- Read `.claude/CONTEXT.md`. If it doesn't exist, treat as empty.
- Read the last ~30 lines of `.claude/JOURNAL.md` to know what was already journaled (avoid duplicates). If it doesn't exist, you'll create it later.
- Skim recent conversation + `git log -10 --oneline` to know what's happened since the last checkpoint.

### Step 2 — Triage every section

For each item currently in `.claude/CONTEXT.md`, decide one of:

| Status | Action |
|---|---|
| Still true right now | Keep it (refresh wording if needed). Preserve any existing `<!-- since: YYYY-MM-DD -->` comment. |
| Done / resolved / merged | **Drop from .claude/CONTEXT.md.** Candidate for JOURNAL if it was a real decision, completion, or pivot. Pure tactical noise (e.g., "tried X, didn't work") is dropped silently. |
| Superseded by a newer state | Drop the old, write the new |
| Still relevant but applies broadly to all future work | This has graduated beyond CONTEXT — propose to user that it move to `.claude/rules/` via `/learn`, then drop from CONTEXT |
| A durable project *fact* (domain, architecture, integration, glossary, external-doc pointer — descriptive, not behavior) | Flag for **Step 6c** — checkpoint writes it into `.claude/knowledge/` itself (descriptive, distinct from prescriptive rules), then drop from CONTEXT |

### Step 3 — Add new state from this session

Add to `.claude/CONTEXT.md` only what's true *now*:
- What you are mid-stream on (with `file:line` if applicable). **If the work is being tracked in a task file**, reference it by slug + path (e.g., `Working task \`add-jwt-auth\` (see .claude/tasks/2026-05-13-001-add-jwt-auth.md)`). Do not duplicate the task body here.
- Ad-hoc changes the user requested *without* creating a `/plan` (quick fixes, transient tweaks, mid-flight pivots) — these have no task file, so CONTEXT **is** their handoff summary, not just a note. Give each *active* one a **micro-handoff** (see Step 4 skeleton): the user's intent in their own words, the files of interest with `file:line`, and the next concrete step. Mark them `(no task)`.
- Decisions just made that are not yet codified in rules
- Open questions / blockers currently unresolved
- The single most useful thing the next session should do first

A durable project *fact* surfaced this session (how a subsystem works, an integration detail, a pointer to a doc in another folder) does NOT belong in CONTEXT — flag it for **Step 6c**, which writes it into `.claude/knowledge/`. CONTEXT holds transient state, not reference knowledge.

Be terse: task references, decisions, and blockers are one short sentence each. Only *active* `(no task)` work earns the 3-line micro-handoff, and only while it is live — the moment it ships or is abandoned, drop it this same checkpoint (JOURNAL it if it was a real decision/completion). That triage is what keeps CONTEXT under the ceiling.

For every new bullet, append `<!-- since: YYYY-MM-DD -->` using today's date. If you keep an existing bullet, preserve its original `since:` date rather than resetting it. These comments make `/doctor` able to flag old decisions that should graduate into rules.

### Step 4 — Build the new .claude/CONTEXT.md

Use this skeleton; **omit any section that has nothing to say**:

```markdown
<!-- .claude/CONTEXT.md — current state of work. Updated by /checkpoint. Declarative, not a log. -->

## In Progress
<!-- planned work → one-line pointer; the task file holds the depth -->
- Working task `<slug>` (see .claude/tasks/<file>) <!-- since: YYYY-MM-DD -->
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

For every item that was DROPPED in Step 2 because it was *done/decided/pivoted*, write **one line** to `.claude/JOURNAL.md` in this format:

```
YYYY-MM-DD | <type> | <one-line summary, optional commit ref>
```

Types (use exactly one):
- `decision` — an architectural or non-obvious choice was settled
- `completed` — a chunk of work finished (link commit if available)
- `pivot` — direction changed; old approach abandoned
- `blocker-resolved` — external blocker cleared

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
   - Append one line to `.claude/JOURNAL.md`:
     `YYYY-MM-DD | completed | <slug> — <one-line outcome>, see tasks/done/<filename>`
     (Use `cancelled` instead of `completed` for cancelled tasks.)
   - Before archiving, scan the task's `### Memory Hints` and `### Related Docs`. If they captured project-wide durable facts (not task-specific detail), graduate them to `.claude/knowledge/` in **Step 6c** so they survive archival (project-wide durable facts only — never task-specific detail).
   - **DO NOT archive `awaiting-review` tasks.** Those are explicitly waiting for user confirmation; archiving them defeats the gate. They stay in the top-level `tasks/` folder and appear in the Active list.
4. Rewrite `.claude/tasks/index.md` from scratch using the canonical skeleton:
   ```markdown
   <!-- .claude/tasks/index.md — dashboard of task documents. Maintained by /plan and /checkpoint. -->

   ## Active
   - [<slug>](<filename>) — <status> — updated <YYYY-MM-DD>

   ## Recently Done (last 14 days)
   - [<slug>](done/<filename>) — done <YYYY-MM-DD>
   ```
   - `Active`: every task in top-level `tasks/` (status: planning, in-progress, **awaiting-review**, blocked).
   - When listing `awaiting-review` entries, append ` ⏳ awaiting your confirmation` to the line so the dashboard makes the gate visible.
   - `Recently Done`: every task in `tasks/done/` whose `updated:` date is within the last 14 days. Older completed tasks remain on disk but drop out of the index.
   - If a section has no entries, write `- _(none)_` instead.
5. Count lines. If `index.md` > 100 lines, trim `Recently Done` first (shorten to last 7 days, then last 3 days, then drop the section).
6. **Flag stalled tasks**: list each in the report.
   - `status: in-progress` AND `updated:` > 7 days old → stalled work. Suggest flipping to `blocked`/`cancelled` or resuming.
   - `status: awaiting-review` AND `updated:` > 3 days old → stuck awaiting confirmation. Suggest the user verify and confirm (or reject) so the task can move forward.
   - `status: planning` AND `updated:` > 14 days old → abandoned plan. Suggest cancellation.

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
4. Tasks synced: active=<n>, archived this run=<n>, stalled=<n>
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
