---
paths: ["**/*"]
description: How agents create, maintain, resume, and complete persistent implementation plans stored in `.claude/tasks/`. Replaces session-only plan mode with cross-session task documents.
when_to_use: Whenever the user invokes `/plan`, when a task file is open or referenced, or when resuming work that may have an active task in `.claude/tasks/`.
tags: [tasks, planning, persistence, cross-session]
---

# Task Management

Plans live as markdown documents in `.claude/tasks/`, not in session memory. One task per file. The file is self-contained — reading it alone must be enough to resume work in a future session, even after intervening commits.

This rule supersedes the native plan mode workflow. Do not rely on `ExitPlanMode` for persistence; the task file is the persistence layer.

## File Layout

```
.claude/tasks/
├── index.md                                # Active + recently-done dashboard
├── 2026-05-13-001-add-auth-middleware.md       # Active task
├── 2026-05-13-002-refactor-payments.md         # Active task
└── done/
    └── 2026-04-28-fix-cors-bug.md          # Archived completed task
```

- **Naming**: `YYYY-MM-DD-NNN-<kebab-slug>.md`. Date is creation date (UTC). NNN is a zero-padded 3-digit sequence number starting at 001, incrementing per day (001, 002, … 999). Slug is 2-5 words, lowercase, hyphen-separated.
- **One task per file.** Never split a single task across files. Do not nest folders inside `tasks/` beyond `done/`.
- **`done/` is archive.** Files move here on completion or cancellation; they are never deleted.
- **`index.md` is a dashboard**, maintained by `/plan` and `/checkpoint`. Task files are the source of truth; `index.md` is a convenience cache.

## Required Task File Structure

Every task file must use this exact skeleton. Omit a section only if explicitly noted as optional.

```markdown
---
slug: <kebab-slug-matching-filename>
status: planning # planning | in-progress | awaiting-review | blocked | done | cancelled
created: YYYY-MM-DD
updated: YYYY-MM-DD
agent: claude # claude | codex | both
tags: [1-5 lowercase kebab-case tags]
---

# <Human-readable Title>

## Purpose

<2-3 sentences: what someone gains after this change and how they can see it working.>

## Context & Orientation

### Related Code

- `path/to/file.ext` — why it matters
- `path/to/dir/` — what's in there

### Related Docs

- `docs/...` — internal project docs the next session must read
- https://... — external spec, RFC, or reference

### Memory Hints

<Free-form notes from this session to the next. Things the future agent must not "forget":

- Non-obvious constraints discovered while exploring
- Libraries/tools the project uses (e.g., "uses Zod, not Joi")
- Pitfalls already encountered
- Anything that would save the next session from re-discovering the same thing>

## Plan of Work

<Prose narrative, 1-3 paragraphs, describing the sequence of edits and why they happen in that order. Not a checklist — that comes next.>

## Concrete Steps

- [ ] Step 1 — exact action, target file, expected outcome
- [ ] Step 2 — ...
- [x] (YYYY-MM-DD HH:MMZ) Step 0 — example completed step with UTC timestamp

## Validation & Acceptance

- [ ] Observable check 1 (e.g., `npm test -- auth.spec.ts` passes)
- [ ] Observable check 2 (e.g., curl with no token returns 401)

## Decision Log

- **Decision** (YYYY-MM-DD, claude): <what was chosen>.
  **Rationale**: <why; what alternatives were rejected>.

## Surprises & Discoveries

- (YYYY-MM-DD) <what was unexpected while exploring or implementing>

## Outcomes & Retrospective

<Fill only when status flips to `done` or `cancelled`. What was delivered, what gaps remain, what was learned.>
```

## Status State Machine

```
planning ──(user approves: "go" / "implement" / etc.)──▶ in-progress
in-progress ──(agent finishes all steps + validation)──▶ awaiting-review
awaiting-review ──(user confirms: "approved" / "looks good")──▶ done
awaiting-review ──(user reports a problem)──▶ in-progress            ← back-edge
in-progress ──(external blocker)──▶ blocked
blocked ──(blocker cleared)──▶ in-progress
{planning, in-progress, awaiting-review, blocked} ──(user cancels)──▶ cancelled
```

- **`planning`**: file is being drafted or awaiting user approval to start. **No code edits allowed.** See "Read-only Locks" below.
- **`in-progress`**: user has approved; agent may edit code as the plan dictates.
- **`awaiting-review`**: agent believes the work is done; user has not yet verified. **No code edits allowed.** Agent is parked until user confirms or rejects.
- **`blocked`**: external dependency missing. State the blocker in the Surprises section.
- **`done`**: completed AND user-confirmed. Move file to `tasks/done/`. Append one line to `.claude/JOURNAL.md`.
- **`cancelled`**: abandoned. Move file to `tasks/done/` with Outcomes explaining why.

## Read-only Locks (Critical)

Two task states forbid code edits — the agent may only touch the task file (and `index.md`):

### Planning Lock — `status: planning`

The agent is drafting / awaiting approval to start.

- **Do NOT modify any code file.** No `Write`, `Edit`, or `NotebookEdit` outside `.claude/tasks/` (or `.codex/tasks/` for the Codex mirror).
- **Allowed**: read-only exploration (`Read`, `Grep`, `Glob`, `git log/diff/status`), and creating/editing the task file itself.
- If the user requests a code change while a planning-locked task is open, ask whether to flip status to `in-progress` first.

### Awaiting-Review Lock — `status: awaiting-review`

The agent has reported completion; the user has not yet verified.

- **Do NOT modify any code file.** The work is under user review; if changes are needed, the user will tell you, and you flip status back to `in-progress` first.
- **Allowed**: refining the draft Outcomes & Retrospective in the task file based on user comments before they give the final signal.
- If the user reports a problem or requests a code change, follow the "User requests changes" flow in the Completion section — do not patch silently while still in awaiting-review.

Both locks are enforced by convention, not tool restriction. Honor them strictly. They are the safety net replacing native plan mode and replacing blind agent self-completion.

## Approval Signal (planning → in-progress)

The agent must judge from natural-language cues, not require a slash command. Treat these as approval:

- "go", "go ahead", "implement", "approved", "do it", "ok làm đi", "ok start", "proceed", "ship it"
- Direct instructions referring to a step ("start with step 1")

Treat these as NOT approval (still in planning):

- "looks good but…" — they want a revision
- Questions about the plan
- Requests to add/remove/reorder steps

On approval: flip frontmatter `status: planning → in-progress`, bump `updated:` to today, then begin executing the first unchecked step.

## Progress Updates During Implementation

When `status: in-progress`, the agent maintains the task file as it works:

1. After completing each step, flip `- [ ]` → `- [x]` and prefix with `(YYYY-MM-DD HH:MMZ)` UTC timestamp.
2. Bump frontmatter `updated:` whenever the file is touched.
3. Append to **Surprises & Discoveries** when reality diverges from the plan (e.g., file moved, dependency missing, existing helper found).
4. Append to **Decision Log** when changing approach mid-flight. Include rationale.
5. **Do not delete or rewrite steps that were skipped or abandoned** — strike them through with `~~text~~` and add a Surprises entry explaining why.

The plan is a living document. Edits to it are part of the work, not an afterthought.

## Completion — Two-Phase Gate

Completion is a **two-phase** process: agent reports, user verifies. The agent **NEVER** unilaterally archives a task. This mirrors the planning-approval gate at the other end of the workflow.

### Phase 1 — Agent reports complete (`in-progress → awaiting-review`)

When every Concrete Steps box AND every Validation & Acceptance box is checked:

1. Fill **Outcomes & Retrospective** as a **draft** (what shipped, what's deferred, lessons). The user reads this as part of verification.
2. Flip frontmatter `status: in-progress → awaiting-review`.
3. Bump `updated:`.
4. Report to the user, explicitly:
   > "All steps and validation done. Task `<slug>` is `awaiting-review`. Please verify (run the app, manual QA, check the diff) and confirm to close — or tell me what didn't work and I'll flip back to in-progress."
5. **STOP.** Do NOT move the file, do NOT write to JOURNAL, do NOT update `Recently Done` in `index.md`. Honor the Awaiting-Review Lock.

### Phase 2a — User confirms (`awaiting-review → done`)

When the user gives a completion signal — "approved", "confirmed", "looks good", "close it", "done", "ship", "ok đóng task", "ok merge" — run the archive flow:

1. Flip frontmatter `status: awaiting-review → done`.
2. Bump `updated:`.
3. Move the file to `.claude/tasks/done/`.
4. Append one line to `.claude/JOURNAL.md`:
   ```
   YYYY-MM-DD | completed | <slug> — <one-line outcome>, see tasks/done/<filename>
   ```
5. Update `.claude/tasks/index.md`: remove from Active, add to Recently Done.
6. If a recurring pattern emerged, propose `/learn` to graduate it into a rule.

### Phase 2b — User reports a problem (`awaiting-review → in-progress`)

If the user reports something is wrong — "step 3 didn't actually work in build", "the style resets to normal at runtime", "you missed X" — do NOT defend. The first completion attempt being wrong is normal; the system is designed to catch this. Run the rollback flow:

1. Append the user's report to **Surprises & Discoveries** with today's UTC date, verbatim if useful. This is high-signal data for future-self.
2. Un-check any Concrete Steps or Validation boxes that turned out to be wrong, OR add new steps if the gap is novel.
3. Flip frontmatter `status: awaiting-review → in-progress`.
4. Bump `updated:`.
5. Begin addressing the issue. When done, return to Phase 1.

The cycle Phase 1 ↔ Phase 2b may repeat. That's correct behavior, not a bug.

## Approval Signal Cheat Sheet

| Transition                      | What user says                                                                           |
| ------------------------------- | ---------------------------------------------------------------------------------------- |
| `planning → in-progress`        | "go", "approved", "implement", "do it", "ok làm đi", "start"                             |
| `awaiting-review → done`        | "approved", "confirmed", "looks good", "close it", "done", "ship", "ok đóng", "merge it" |
| `awaiting-review → in-progress` | Any report of a problem — "didn't work", "broken", "missed X", "step Y is wrong"         |
| `* → cancelled`                 | "cancel", "abandon", "drop this", "bỏ task"                                              |

The agent must wait for the explicit signal. Enthusiasm ("great!", "nice plan") is NOT approval. Questions are NOT approval. Edits the user makes to the task file are NOT approval.

## Resumption Across Sessions

A new session resuming a task must:

1. Read the entire task file (it is self-contained by design).
2. Verify Concrete Steps marked `[x]` still hold by spot-checking the current code. Between sessions, unrelated commits may have moved or changed referenced files.
3. If reality drifted from what the file expects, append a Surprises entry and ask the user whether to adapt the plan or revisit prior steps.
4. Only then proceed with the next unchecked step.

Never assume the file is still accurate without verification. The Memory Hints section is the future-session's lifeline — treat it as authoritative recall.

## `index.md` Format

```markdown
<!-- .claude/tasks/index.md — dashboard of task documents. Maintained by /plan and /checkpoint. -->

## Active

- [<slug>](<YYYY-MM-DD-NNN-slug>.md) — <status> — updated <YYYY-MM-DD>

## Recently Done (last 14 days)

- [<slug>](done/<YYYY-MM-DD-NNN-slug>.md) — done <YYYY-MM-DD>
```

- Active list shows every file in `tasks/` whose `status` is `planning`, `in-progress`, or `blocked`.
- Recently Done shows files in `tasks/done/` whose `updated:` date is within the last 14 days.
- Older completed tasks remain on disk in `done/` but drop out of `index.md` to keep it short.
- **Hard ceiling: 100 lines.** Trim Recently Done first if exceeded.

## Relationship to `CONTEXT.md`

CONTEXT.md and task files are complementary, not exclusive:

- **CONTEXT.md** holds two things: (a) a one-line pointer to the currently-focused task (`Working task \`<slug>\` (see .claude/tasks/<file>)`) so `/start`sees task work at a glance, and (b) ad-hoc work the user asked for **without** a`/plan` — quick fixes, transient tweaks, mid-flight pivots that don't justify a full task document.
- **Task file** holds the full body: Purpose, Plan of Work, Concrete Steps, Decisions, Memory Hints, etc.
- **`tasks/index.md`** is the canonical dashboard for _all_ active tasks; CONTEXT only mentions the one in focus.

So: a task's existence is signalled in CONTEXT by a pointer line. The task's content lives in its own file. The two never duplicate each other.

## Anti-Patterns

- ❌ **Agent auto-completing.** Flipping `status` directly from `in-progress` to `done`, moving the file to `done/`, writing to JOURNAL, or updating Recently Done in `index.md` without a user completion signal. The agent's job is to reach `awaiting-review` and stop.
- ❌ Editing code while `status: planning` or `status: awaiting-review`. Both states are read-only locks.
- ❌ Treating user enthusiasm or silence as approval. The signals listed in the cheat sheet are explicit and required.
- ❌ Letting `updated:` go stale (>3 days during in-progress without movement signals abandonment — flip to `blocked` or address it).
- ❌ Copying a task's body (Steps / Decisions / Surprises / Memory Hints) into `.claude/CONTEXT.md`. CONTEXT may _reference_ the active task by slug + path, but must never duplicate its content.
- ❌ Importing task files into `.claude/CLAUDE.md`. Task files are working documents, not always-loaded rules.
- ❌ Deleting completed task files. They are project history.
- ❌ Creating a task without filling Memory Hints if any non-obvious context was discovered during planning.
