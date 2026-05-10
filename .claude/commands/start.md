---
description: Orient a new CLAUDART session from current context and recent git history
---

Start this session with a lightweight CLAUDART orientation. This command is read-only.

## Procedure

1. Read `.claude/CONTEXT.md` if it exists. If missing, say the project has no Claude context yet and suggest `/checkpoint` after meaningful work.
2. Run `git log -3 --oneline`. If the directory is not a git repo or has fewer than three commits, report what is available.
3. Extract only these sections from `.claude/CONTEXT.md` when present:
   - `## In Progress`
   - `## Next Session Should Start By`
   - `## Open Questions / Blockers`
4. Do not read `.claude/JOURNAL.md`.
5. Do not run `/doctor`; that is a heavier health check.

## Output Format

```markdown
## Session Ready

**Current focus:** [In Progress section, or "None recorded"]
**Last 3 commits:** [git log -3 --oneline output, compact]
**Start by:** [Next Session Should Start By section, or "Ask user what to tackle first"]
**Open blockers:** [Open Questions / Blockers section, or "None recorded"]
```

Keep the report short and actionable. If the context file contains stale-looking items, mention that `/checkpoint` should refresh it after this session.
