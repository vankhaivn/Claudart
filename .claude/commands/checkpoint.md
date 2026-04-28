---
description: Update .claude/CONTEXT.md to reflect the CURRENT state of work (declarative overwrite). Append graduated items to JOURNAL.md. Run at the end of meaningful sessions.
---

You are about to write a session checkpoint. The output is **not a log of what happened** — it is a **declarative snapshot of what is true right now**. Lifelong append is the failure mode this command exists to prevent.

## Hard Rules (read before doing anything)

1. **.claude/CONTEXT.md is overwritten, not appended.** Anything not still true *right now* must be removed.
2. **.claude/CONTEXT.md hard ceiling: 150 lines, target < 100.** If your draft exceeds 150, STOP and ask the user to trim manually or run `/refactor-memory`.
3. **JOURNAL.md is append-only.** Never edit or delete prior entries. Each new entry is a single line.
4. **NEVER add `@.claude/JOURNAL.md` to `CLAUDE.md`.** JOURNAL is intentionally outside the loaded context to save tokens. If you find such an import, remove it and warn the user.
5. **Skip JOURNAL entirely when there is nothing meaningful to record.** Empty entries pollute the file.

## Procedure

### Step 1 — Read prior state

- Read `.claude/CONTEXT.md`. If it doesn't exist, treat as empty.
- Read the last ~30 lines of `.claude/JOURNAL.md` to know what was already journaled (avoid duplicates). If it doesn't exist, you'll create it later.
- Skim recent conversation + `git log -10 --oneline` to know what's happened since the last checkpoint.

### Step 2 — Triage every section

For each item currently in `.claude/CONTEXT.md`, decide one of:

| Status | Action |
|---|---|
| Still true right now | Keep it (refresh wording if needed) |
| Done / resolved / merged | **Drop from .claude/CONTEXT.md.** Candidate for JOURNAL if it was a real decision, completion, or pivot. Pure tactical noise (e.g., "tried X, didn't work") is dropped silently. |
| Superseded by a newer state | Drop the old, write the new |
| Still relevant but applies broadly to all future work | This has graduated beyond CONTEXT — propose to user that it move to `.claude/rules/` via `/learn`, then drop from CONTEXT |

### Step 3 — Add new state from this session

Add to `.claude/CONTEXT.md` only what's true *now*:
- What you are mid-stream on (with `file:line` if applicable)
- Decisions just made that are not yet codified in rules
- Open questions / blockers currently unresolved
- The single most useful thing the next session should do first

Be terse. One bullet ≈ one short sentence.

### Step 4 — Build the new .claude/CONTEXT.md

Use this skeleton; **omit any section that has nothing to say**:

```markdown
<!-- .claude/CONTEXT.md — current state of work. Updated by /checkpoint. Declarative, not a log. -->

## In Progress
- [What is mid-stream right now, with file:line]

## Open Questions / Blockers
- [Unresolved things blocking progress]

## Recent Decisions (not yet promoted to rules)
- [Decision + brief why; promote to .claude/rules/ via /learn when it stabilizes]

## Next Session Should Start By
- [One concrete action, e.g., "run pytest tests/auth/", "ask user about caching strategy"]
```

Count lines. If > 150, STOP and report to the user; do not write the file.

### Step 5 — Append to JOURNAL.md

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

### Step 7 — Report

Output a 5-line summary:
1. Lines in new .claude/CONTEXT.md
2. Items kept / dropped / added (counts)
3. JOURNAL entries appended (or "none")
4. Anything proposed for `/learn` graduation
5. Reminder for the user to commit so the checkpoint enters git history

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
