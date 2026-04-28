# JOURNAL

Append-only history of decisions, completions, pivots, and resolved blockers. Maintained by `/checkpoint`.

> **DO NOT add `@.claude/JOURNAL.md` to `.claude/CLAUDE.md`.** This file is intentionally excluded from session context to save tokens. Claude reads it only on explicit user request (e.g., "why did we choose X last month?") or during `/learn` to detect recurring patterns that should be promoted to rules.

## Format

```
YYYY-MM-DD | <type> | <one-line summary, optional commit ref>
```

**Types** (use exactly one):
- `decision` — architectural or non-obvious choice was settled
- `completed` — a chunk of work finished (link commit if available)
- `pivot` — direction changed; old approach abandoned
- `blocker-resolved` — external blocker cleared

## Rules

- **Append only.** Never edit or delete prior entries — git history is your audit trail.
- **One line per entry.** If you need more than ~100 chars, link a commit instead.
- **No empty entries.** If `/checkpoint` has nothing meaningful to journal, it skips this file entirely.

## Entries

<!-- /checkpoint appends new lines below this marker -->
