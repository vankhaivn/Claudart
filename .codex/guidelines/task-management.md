---
paths: ["**/*"]
description: How Codex creates, maintains, resumes, and completes persistent implementation plans stored in `.codex/tasks/`. Replaces session-only plan mode with cross-session task documents.
when_to_use: Whenever the user invokes `$codex-plan`, when a task file is open or referenced, or when resuming work that may have an active task in `.codex/tasks/`.
tags: [tasks, planning, persistence, cross-session]
---

# Task Management

Plans live as markdown documents in `.codex/tasks/`, not in session memory. One task per file. The file is self-contained — reading it alone must be enough to resume work in a future session, even after intervening commits.

This guideline supersedes the native `/plan` mode workflow for persistence. Use `$codex-plan` to create a task document instead of relying on session-only plan state.

## File Layout

```
.codex/tasks/
├── index.md                                # Active + recently-done dashboard
├── 2026-05-13-add-auth-middleware.md       # Active task
├── 2026-05-10-refactor-payments.md         # Active task
└── done/
    └── 2026-04-28-fix-cors-bug.md          # Archived completed task
```

- **Naming**: `YYYY-MM-DD-<kebab-slug>.md`. Date is creation date (UTC). Slug is 2-5 words, lowercase, hyphen-separated.
- **One task per file.** Never split a single task across files. Do not nest folders inside `tasks/` beyond `done/`.
- **`done/` is archive.** Files move here on completion or cancellation; they are never deleted.
- **`index.md` is a dashboard**, maintained by `$codex-plan` and `$codex-checkpoint`. Task files are the source of truth; `index.md` is a convenience cache.

## Required Task File Structure

Every task file must use this exact skeleton. Omit a section only if explicitly noted as optional.

```markdown
---
slug: <kebab-slug-matching-filename>
status: planning              # planning | in-progress | blocked | done | cancelled
created: YYYY-MM-DD
updated: YYYY-MM-DD
agent: codex                  # claude | codex | both
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
- **Decision** (YYYY-MM-DD, codex): <what was chosen>.
  **Rationale**: <why; what alternatives were rejected>.

## Surprises & Discoveries
- (YYYY-MM-DD) <what was unexpected while exploring or implementing>

## Outcomes & Retrospective
<Fill only when status flips to `done` or `cancelled`. What was delivered, what gaps remain, what was learned.>
```

## Status State Machine

```
planning ──(user says "go" / "approved" / "implement")──▶ in-progress
in-progress ──(all Concrete Steps + Validation checked)─▶ done
in-progress ──(external blocker)──▶ blocked
blocked ──(blocker cleared)──▶ in-progress
{planning,in-progress,blocked} ──(user cancels)──▶ cancelled
```

- **`planning`**: file is being drafted or awaiting user approval. **No code edits allowed in this state.** See "Planning Lock" below.
- **`in-progress`**: user has approved; agent may now edit code as the plan dictates.
- **`blocked`**: external dependency missing. State the blocker in the Surprises section.
- **`done`**: completed. Move file to `tasks/done/`. Append one line to `.codex/JOURNAL.md`.
- **`cancelled`**: abandoned. Move file to `tasks/done/` with Outcomes explaining why.

## Planning Lock (Critical)

While a task file has `status: planning`:

- **Do NOT modify any code file.** No writes against anything outside `.codex/tasks/` (or `.claude/tasks/` for the Claude mirror).
- **Allowed**: read-only exploration (read files, grep, glob, `git log/diff/status`), and creating or editing the task file itself (and `index.md`).
- If the user requests a code change while a planning-locked task is open, ask whether to flip status to `in-progress` first.

This lock mirrors the safety of native plan mode but is enforced by convention, not by tool restriction. Honor it strictly.

## Approval Signal (planning → in-progress)

Judge from natural-language cues, not a slash command. Treat these as approval:

- "go", "go ahead", "implement", "approved", "do it", "ok làm đi", "ok start", "proceed", "ship it"
- Direct instructions referring to a step ("start with step 1")

Treat these as NOT approval (still in planning):

- "looks good but…" — they want a revision
- Questions about the plan
- Requests to add/remove/reorder steps

On approval: flip frontmatter `status: planning → in-progress`, bump `updated:` to today, then begin executing the first unchecked step.

## Progress Updates During Implementation

When `status: in-progress`, maintain the task file as work progresses:

1. After completing each step, flip `- [ ]` → `- [x]` and prefix with `(YYYY-MM-DD HH:MMZ)` UTC timestamp.
2. Bump frontmatter `updated:` whenever the file is touched.
3. Append to **Surprises & Discoveries** when reality diverges from the plan.
4. Append to **Decision Log** when changing approach mid-flight. Include rationale.
5. **Do not delete or rewrite steps that were skipped or abandoned** — strike them through with `~~text~~` and add a Surprises entry explaining why.

The plan is a living document. Edits to it are part of the work, not an afterthought.

## Completion

When every Concrete Steps box AND every Validation & Acceptance box is checked:

1. Fill **Outcomes & Retrospective** (what shipped, what's deferred, lessons).
2. Flip frontmatter `status: in-progress → done`.
3. Bump `updated:`.
4. Move the file to `.codex/tasks/done/`.
5. Append one line to `.codex/JOURNAL.md`:
   ```
   YYYY-MM-DD | completed | <slug> — <one-line outcome>, see tasks/done/<filename>
   ```
6. Update `.codex/tasks/index.md`: remove from Active, add to Recently Done.
7. If a recurring pattern emerged, propose `$codex-learn` to graduate it into a guideline.

## Resumption Across Sessions

A new session resuming a task must:

1. Read the entire task file (it is self-contained by design).
2. Verify Concrete Steps marked `[x]` still hold by spot-checking the current code. Between sessions, unrelated commits may have moved or changed referenced files.
3. If reality drifted from what the file expects, append a Surprises entry and ask the user whether to adapt the plan or revisit prior steps.
4. Only then proceed with the next unchecked step.

Never assume the file is still accurate without verification. The Memory Hints section is the future-session's lifeline — treat it as authoritative recall.

## `index.md` Format

```markdown
<!-- .codex/tasks/index.md — dashboard of task documents. Maintained by $codex-plan and $codex-checkpoint. -->

## Active
- [<slug>](<YYYY-MM-DD-slug>.md) — <status> — updated <YYYY-MM-DD>

## Recently Done (last 14 days)
- [<slug>](done/<YYYY-MM-DD-slug>.md) — done <YYYY-MM-DD>
```

- Active list shows every file in `tasks/` whose `status` is `planning`, `in-progress`, or `blocked`.
- Recently Done shows files in `tasks/done/` whose `updated:` date is within the last 14 days.
- Older completed tasks remain on disk in `done/` but drop out of `index.md` to keep it short.
- **Hard ceiling: 100 lines.** Trim Recently Done first if exceeded.

## Relationship to `CONTEXT.md`

CONTEXT.md and task files are complementary, not exclusive:

- **CONTEXT.md** holds two things: (a) a one-line pointer to the currently-focused task (`Working task \`<slug>\` (see .codex/tasks/<file>)`) so `$codex-start` sees task work at a glance, and (b) ad-hoc work the user asked for **without** a `$codex-plan` — quick fixes, transient tweaks, mid-flight pivots that don't justify a full task document.
- **Task file** holds the full body: Purpose, Plan of Work, Concrete Steps, Decisions, Memory Hints, etc.
- **`tasks/index.md`** is the canonical dashboard for *all* active tasks; CONTEXT only mentions the one in focus.

So: a task's existence is signalled in CONTEXT by a pointer line. The task's content lives in its own file. The two never duplicate each other.

## Anti-Patterns

- Editing code while `status: planning`.
- Letting `updated:` go stale (>3 days during in-progress without movement signals abandonment — flip to `blocked` or address it).
- Copying a task's body (Steps / Decisions / Surprises / Memory Hints) into `.codex/CONTEXT.md`. CONTEXT may *reference* the active task by slug + path, but must never duplicate its content.
- Auto-loading task files via `AGENTS.md`. Task files are working documents, not always-loaded guidelines.
- Deleting completed task files. They are project history.
- Creating a task without filling Memory Hints if any non-obvious context was discovered during planning.
