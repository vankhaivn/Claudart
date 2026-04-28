# Codex Checkpoint Command

Update `.claudart/CONTEXT.md` to reflect the current state of work from a Codex session. Append meaningful retired items to `.claudart/JOURNAL.md`. Run this at the end of meaningful sessions or before handing work back to Claude Code.

The output is not a log of what happened. It is a declarative snapshot of what is true right now. Lifelong append is the failure mode this command exists to prevent.

## Hard Rules

1. `.claudart/CONTEXT.md` is overwritten, not appended. Anything not still true right now must be removed.
2. `.claudart/CONTEXT.md` hard ceiling: 150 lines, target under 100. If your draft exceeds 150, stop and ask the user to trim manually or run `$codex-refactor-memory`.
3. `.claudart/JOURNAL.md` is append-only. Never edit or delete prior entries. Each new entry is a single line.
4. Never add `.claudart/JOURNAL.md` as auto-loaded context in `AGENTS.md`, `.codex/CODEX.md`, `.claude/CLAUDE.md`, `.codex/guidelines/`, or `.claude/rules/`.
5. Skip JOURNAL entirely when there is nothing meaningful to record. Empty entries pollute the file.

## Procedure

### Step 1: Read Prior State

- Read `.claudart/CONTEXT.md`. If it does not exist, treat it as empty.
- Read the last ~30 lines of `.claudart/JOURNAL.md` to avoid duplicate entries. If it does not exist, create it later.
- Skim the recent conversation and `git log -10 --oneline` to understand what changed since the last checkpoint.

### Step 2: Triage Every CONTEXT Item

For each item currently in `.claudart/CONTEXT.md`, decide one of:

| Status | Action |
|---|---|
| Still true right now | Keep it, refreshing wording if needed. |
| Done / resolved / merged | Drop it from `.claudart/CONTEXT.md`. Candidate for JOURNAL if it was a real decision, completion, or pivot. |
| Superseded by newer state | Drop the old item and write the new current state. |
| Broadly relevant to all future work | Propose moving it into `.codex/guidelines/` via `$codex-learn`, then drop it from CONTEXT. |

Pure tactical noise is dropped silently.

### Step 3: Add New State from This Session

Add to `.claudart/CONTEXT.md` only what is true now:

- Work that is mid-stream, with `file:line` where useful.
- Decisions just made that are not yet codified in guidelines.
- Open questions or blockers currently unresolved.
- The single most useful thing the next session should do first.

Be terse. One bullet should be one short sentence.

### Step 4: Build the New CONTEXT

Use this skeleton. Omit any section that has nothing to say.

```markdown
<!-- .claudart/CONTEXT.md - current state of work. Updated by checkpoint. Declarative, not a log. -->

## In Progress
- [What is mid-stream right now, with file:line]

## Open Questions / Blockers
- [Unresolved things blocking progress]

## Recent Decisions (not yet promoted to rules)
- [Decision + brief why; promote via learn when it stabilizes]

## Next Session Should Start By
- [One concrete action, e.g. "run pytest tests/auth/" or "ask user about caching strategy"]
```

Count lines. If more than 150, stop and report to the user. Do not write the file.

### Step 5: Append to JOURNAL

For every item dropped in Step 2 because it was done, decided, pivoted, or resolved, write one line to `.claudart/JOURNAL.md` in this format:

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

If `.claudart/JOURNAL.md` does not exist, create it with the canonical CLAUDART header before appending.

If there is nothing to journal, skip this step. Do not write empty entries.

### Step 6: Overwrite CONTEXT

Now, and only now, write the new `.claudart/CONTEXT.md` from Step 4.

### Step 7: Report

Output a 5-line summary:

1. Lines in new `.claudart/CONTEXT.md`.
2. Items kept, dropped, and added.
3. JOURNAL entries appended, or `none`.
4. Anything proposed for `$codex-learn` graduation.
5. Reminder for the user to commit so the checkpoint enters git history.

Do not run `git commit` yourself.

## When to Run This Command

Good triggers:

- End of a significant Codex work session.
- Before `/compact` or equivalent context compaction.
- Before switching to a different feature or branch.
- Before handing work back to Claude Code.
- When the user says they will pick this up later.

Bad triggers:

- After every tool call.
- During active debugging where state is not stable yet.
