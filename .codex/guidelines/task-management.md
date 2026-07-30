---
paths: ["**/*"]
description: How agents create, maintain, resume, and complete persistent implementation plans stored in `.codex/tasks/`. Replaces session-only plan mode with cross-session task documents.
when_to_use: Whenever the user invokes `$codex-plan`, when a task file is open or referenced, or when resuming work that may have an active task in `.codex/tasks/`.
tags: [tasks, planning, persistence, cross-session]
---

# Task Management

Plans live as markdown documents in `.codex/tasks/`, not in session memory. One task per file. The file is self-contained — reading it alone must be enough to resume work in a future session, even after intervening commits.

This guideline supersedes the native plan mode workflow. Do not rely on session-only plan state for persistence; the task file is the persistence layer.

For work that may parallelize, also follow `agent-delegation.md`. The `delegation:` frontmatter field records a delegation strategy at planning time and carries it into execution at the approval signal; its values and whether they gate delegation are defined there, not in this file.

Mission-scale work runs one layer up, in `.codex/specs/` (see `spec-workflow.md`), and **supersedes this guideline within its scope**: an approved spec's standing approval replaces the per-task approval and review gates below, and a spec executor never creates task files. Never run both layers over the same work.

## File Layout

```
.codex/tasks/
├── index.md                                # Active + recently-done dashboard
├── 2026-05-13-001-add-auth-middleware.md       # Active task
├── 2026-05-13-002-refactor-payments.md         # Active task
└── done/
    └── 2026-04-28-fix-cors-bug.md          # Archived completed task
```

- **Naming**: `YYYY-MM-DD-NNN-<kebab-slug>.md`. Date is creation date (UTC). NNN is a zero-padded 3-digit sequence number starting at 001, incrementing per day (001, 002, … 999). Slug is 2-5 words, lowercase, hyphen-separated.
- **One task per file.** Never split a single task across files. Do not nest folders inside `tasks/` beyond `done/`.
- **`done/` is archive.** Files move here on completion or cancellation; they are never deleted.
- **`index.md` is a dashboard**, maintained by `$codex-plan` and `$codex-checkpoint`. Task files are the source of truth; `index.md` is a convenience cache.

## Required Task File Structure

Every task file must use this exact skeleton. Omit a section only if explicitly noted as optional.

```markdown
---
slug: <kebab-slug-matching-filename>
status: planning # planning | in-progress | awaiting-review | blocked | done | cancelled
created: YYYY-MM-DD
updated: YYYY-MM-DD
agent: codex # claude | codex | both
delegation: none # none | strategy-only | authorized — see "Delegation strategy" below
tags: [1-5 lowercase kebab-case tags]
---

# <Human-readable Title>

## Purpose

> "<the user's original request, quoted verbatim — paraphrase is where intent bends>"

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
- Delegation strategy when relevant: subagent roles, ownership boundaries, validation responsibilities (mirror the `delegation:` field)
- Knowledge candidates not yet eligible for promotion, labeled with their evidence gap or conflict
- Anything that would save the next session from re-discovering the same thing>

## Plan of Work

<Prose narrative, 1-3 paragraphs, describing the sequence of edits and why they happen in that order. Not a checklist — that comes next.>

## Concrete Steps

- [ ] Step 1 — exact action, target file, expected outcome (verify: <observable check>)
- [ ] Step 2 — ...
- [x] (YYYY-MM-DD HH:MMZ) Step 0 — example completed step with UTC timestamp

## Validation & Acceptance

- [ ] Observable check 1 (e.g., `npm test -- auth.spec.ts` passes)
- [ ] Observable check 2 (e.g., curl with no token returns 401)

## Decision Log

- **Decision** (YYYY-MM-DD HH:MMZ, codex): <what was chosen>.
  **Rationale**: <why; what alternatives were rejected>.

## Surprises & Discoveries

- (YYYY-MM-DD HH:MMZ) <what was unexpected while exploring or implementing>

## Outcomes & Retrospective

<Fill only when status flips to `done` or `cancelled`. What was delivered, what gaps remain, what was learned.>
```

## Plan Altitude

The task file is the interface between the session that plans and the session that executes — often a cheaper model. The economics only work when the file carries the right cargo:

- **Carry**: decisions (what was chosen, why, what was rejected), non-obvious constraints and pitfalls discovered while exploring, and a `verify:` check per step.
- **Do not carry**: the solution. No code snippets, pseudo-code, or line-level edit instructions in Concrete Steps. If writing a step required solving the problem first, the plan has overstepped — lift the step back to decision + verify and let the executor derive the how.
- A step may stay vague about _how_ as long as its `verify:` is sharp about _what success is_. Verification substitutes for detail: it catches executor drift at the step where it happens, at a fraction of the tokens.
- A well-written step can be handed verbatim to a subagent as the **Goal** of a worker prompt (see `agent-delegation.md`). Self-contained means it carries the decisions, constraints, and verify — not the answer.

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
- **`done`**: completed AND user-confirmed. Move file to `tasks/done/`. Append one line to `.codex/JOURNAL.md`.
- **`cancelled`**: abandoned. Move file to `tasks/done/` with Outcomes explaining why.

## Read-only Locks (Critical)

Two task states forbid code edits. The agent may touch the task file and `index.md`, plus the knowledge-maintenance exception below:

### Planning Lock — `status: planning`

The agent is drafting / awaiting approval to start.

- **Do NOT modify any code file.** No writes against anything outside `.codex/tasks/`.
- **Allowed**: read-only exploration (read files, grep, glob, `git log/diff/status`), and creating/editing the task file itself.
- If the user requests a code change while a planning-locked task is open, ask whether to flip status to `in-progress` first.

### Awaiting-Review Lock — `status: awaiting-review`

The agent has reported completion; the user has not yet verified.

- **Do NOT modify any code file.** The work is under user review; if changes are needed, the user will tell you, and you flip status back to `in-progress` first.
- **Allowed**: refining the draft Outcomes & Retrospective in the task file based on user comments before they give the final signal.
- If the user reports a problem or requests a code change, follow the "User reports a problem" flow in the Completion section — do not patch silently while still in awaiting-review.

### Knowledge-maintenance exception

The locks protect implementation code; they do not block knowledge maintenance. Immediate promotion requires the full capture gate plus one trigger: the user asks in natural language, a verified correction must land to avoid continued reliance on known-wrong canonical knowledge, confirmed source drift requires an owner trust/content update, or a lifecycle workflow reaches its promotion boundary. Otherwise keep the observation as a task candidate. WIP, proposals, acceptance state, and task-local or uncertain discoveries stay in the task file. Read `.codex/guidelines/knowledge-management.md` in full, patch the existing owner first, update the topic plus its reachable route atomically, and run `bash .codex/scripts/knowledge-check.sh --root .`. This exception never authorizes code edits or automatic capture after every exploration.

Both locks are enforced by convention, not tool restriction. Honor them strictly. They are the safety net replacing native plan mode and replacing blind agent self-completion.

## Approval Signal (planning → in-progress)

The agent must judge from natural-language cues, not require a slash command. Treat these as approval:

- "go", "go ahead", "implement", "approved", "do it", "ok làm đi", "ok start", "proceed", "ship it"
- Direct instructions referring to a step ("start with step 1")

Treat these as NOT approval (still in planning):

- "looks good but…" — they want a revision
- Questions about the plan
- Requests to add/remove/reorder steps

On approval: flip frontmatter `status: planning → in-progress`, bump `updated:` to today, then begin executing the first unchecked step. The `delegation:` field carries any recorded delegation strategy into execution — see "Delegation strategy" below; its values and gating semantics live in `agent-delegation.md`.

## Delegation strategy (the `delegation:` field)

The frontmatter `delegation:` field records a delegation strategy at planning time so the approval signal ("go") can carry it into execution without re-deriving the decomposition. Set it during planning and note the choice in the Decision Log.

Its values — `none`, `strategy-only`, `authorized` — and **whether they gate execution** are defined in `agent-delegation.md`, which is harness-specific; this file does not redefine them. If the strategy changes at runtime, update the field.

## Progress Updates During Implementation

When `status: in-progress`, the agent maintains the task file as it works:

1. After completing each step, flip `- [ ]` → `- [x]` and prefix with `(YYYY-MM-DD HH:MMZ)` UTC timestamp.
2. Bump frontmatter `updated:` whenever the file is touched.
3. Append to **Surprises & Discoveries** when reality diverges from the plan (e.g., file moved, dependency missing, existing helper found). Prefix each entry with a `(YYYY-MM-DD HH:MMZ)` UTC timestamp.
4. Append to **Decision Log** when changing approach mid-flight, prefixed with `(YYYY-MM-DD HH:MMZ, <agent>)`. Include rationale.
5. **Do not delete or rewrite steps that were skipped or abandoned** — strike them through with `~~text~~` and add a Surprises entry explaining why.

The plan is a living document. Edits to it are part of the work, not an afterthought. Every in-task log entry — a completed step, a Decision Log line, a Surprises line — carries the full `YYYY-MM-DD HH:MMZ` UTC time, never date-only: one task often logs several entries in a single day, and the time is the only thing that keeps them ordered for audit.

Default discoveries to the task file. Promote one immediately only under the knowledge-maintenance exception; checkpoint can bulk-evaluate the remaining candidates later.

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
3. Move the file to `.codex/tasks/done/`.
4. Append one line to `.codex/JOURNAL.md`:
   ```
   YYYY-MM-DD | completed | <slug> — <one-line outcome>, see tasks/done/<filename>
   ```
5. Update `.codex/tasks/index.md`: remove from Active, add to Recently Done.
6. If a recurring pattern emerged, propose `$codex-learn` to graduate it into a guideline.
7. Leave task-local outcomes in the archived task. At this lifecycle boundary, promote only descriptive claims that pass the full knowledge gate; update owner + reachable route atomically and run the checker after a mutation. Keep unresolved claims as candidates in the archive.

### Phase 2b — User reports a problem (`awaiting-review → in-progress`)

If the user reports something is wrong — "step 3 didn't actually work in build", "the style resets to normal at runtime", "you missed X" — do NOT defend. The first completion attempt being wrong is normal; the system is designed to catch this. Run the rollback flow:

1. Append the user's report to **Surprises & Discoveries**, stamped with the current `(YYYY-MM-DD HH:MMZ)` UTC time, verbatim if useful. This is high-signal data for future-self.
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

Subagent execution is governed by the `delegation:` field and your harness — see `agent-delegation.md`. The signals in this table concern task _status_ (`planning → in-progress → done`), not whether to delegate.

## Resumption Across Sessions

A new session resuming a task must:

1. Read the entire task file (it is self-contained by design).
2. Verify Concrete Steps marked `[x]` still hold — re-run their `(verify: …)` checks where cheap, or spot-check the current code. Between sessions, unrelated commits may have moved or changed referenced files.
3. If reality drifted from what the file expects, append a Surprises entry and ask the user whether to adapt the plan or revisit prior steps.
4. Only then proceed with the next unchecked step.

Never assume the file is still accurate without verification. Memory Hints are a routing aid, not authority; verify them against current code and use bounded `rg`/Git evidence search only when routed context is insufficient.

## `index.md` Format

```markdown
<!-- .codex/tasks/index.md — dashboard of task documents. Maintained by $codex-plan and $codex-checkpoint. -->

## Active

- [<slug>](<YYYY-MM-DD-NNN-slug>.md) — <status> — updated <YYYY-MM-DD>

## Recently Done (last 14 days)

- [<slug>](done/<YYYY-MM-DD-NNN-slug>.md) — done <YYYY-MM-DD>
```

- Active list shows every file in `tasks/` whose `status` is `planning`, `in-progress`, `awaiting-review`, or `blocked`. Append ` ⏳ awaiting your confirmation` to `awaiting-review` lines so the gate is visible on the dashboard.
- Recently Done shows files in `tasks/done/` whose `updated:` date is within the last 14 days.
- Older completed tasks remain on disk in `done/` but drop out of `index.md` to keep it short.
- If a section has no entries, write `- _(none)_` instead.
- **Hard ceiling: 100 lines.** Trim Recently Done first if exceeded (shorten the window to 7 days, then 3, then drop the section).

## Staleness Thresholds

Canonical numbers for flagging stalled tasks. `$codex-start` surfaces them, `$codex-checkpoint` acts on them, `$codex-doctor` audits them — none of those files redefine the numbers.

| Status            | `updated:` older than | Flag as                                                                                                                                              |
| ----------------- | --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `in-progress`     | 7 days                | Stalled work — suggest resuming, or flipping to `blocked`/`cancelled`                                                                                |
| `awaiting-review` | 3 days                | Stuck awaiting confirmation — not abandoned; the user likely forgot to verify. Surface prominently and ask for the close-out signal (or a rejection) |
| `planning`        | 14 days               | Abandoned plan — suggest cancellation                                                                                                                |

## Relationship to `CONTEXT.md`

CONTEXT.md and task files are complementary, not exclusive:

- **CONTEXT.md** holds two things: (a) a one-line pointer to the currently-focused task (`Working task \`<slug>\` (see .codex/tasks/<file>)`) so `$codex-start` sees task work at a glance, and (b) ad-hoc work the user asked for **without** a `$codex-plan` — quick fixes, transient tweaks, mid-flight pivots that don't justify a full task document.
- **Task file** holds the full body: Purpose, Plan of Work, Concrete Steps, Decisions, Memory Hints, etc.
- **`tasks/index.md`** is the canonical dashboard for _all_ active tasks; CONTEXT only mentions the one in focus.

So: a task's existence is signalled in CONTEXT by a pointer line. The task's content lives in its own file. The two never duplicate each other.

## Anti-Patterns

- **Agent auto-completing.** Flipping `status` directly from `in-progress` to `done`, moving the file to `done/`, writing to JOURNAL, or updating Recently Done in `index.md` without a user completion signal. The agent's job is to reach `awaiting-review` and stop.
- Editing code while `status: planning` or `status: awaiting-review`. Both states are read-only locks.
- **Spawning write-scope subagents from a planning-locked task.** The lock forbids code edits, so any worker that writes must wait for `in-progress`; read-only exploration subagents are fine.
- Treating user enthusiasm or silence as approval. The signals listed in the cheat sheet are explicit and required.
- Letting `updated:` go stale (>3 days during in-progress without movement signals abandonment — flip to `blocked` or address it).
- Copying a task's body (Steps / Decisions / Surprises / Memory Hints) into `.codex/CONTEXT.md`. CONTEXT may _reference_ the active task by slug + path, but must never duplicate its content.
- Auto-loading task files via `AGENTS.md`. Task files are working documents, not always-loaded guidelines.
- Deleting completed task files. They are project history.
- Creating a task without filling Memory Hints if any non-obvious context was discovered during planning.
- Writing code into the plan. Concrete Steps carry decisions, constraints, and `verify:` checks — never snippets or line-level edits (see "Plan Altitude").
