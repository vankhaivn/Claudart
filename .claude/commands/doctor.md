---
description: Validate the CLAUDART installation in this repository and report any drift, broken rules, or missing wiring
---

Please run a health check on this repository's CLAUDART installation. Your job is **diagnostic only** — do NOT auto-fix anything. Report findings; the user will run `/refactor-memory` or edit files manually based on your output.

## What to Check

### 1. Required Structure

- `.claude/` exists at the repository root
- `.claude/commands/` exists and contains at least: `learn.md`, `refactor-memory.md`, `doctor.md`, `checkpoint.md`
- `.claude/agents/` exists (may be empty if user removed shipped agents)
- `.claude/rules/` exists (may be empty before the user runs `/refactor-memory`)
- `.claude/CLAUDE.md` exists
- `.claudart/CONTEXT.md` exists (warn if missing — the user may not have run `/checkpoint` yet)
- `.claudart/JOURNAL.md` exists (warn if missing)

For each missing path, report which command would create it (e.g., "missing → run `/refactor-memory`").

### 2. YAML Frontmatter Validity

For every `.md` file under `.claude/commands/`, `.claude/agents/`, `.claude/rules/`:

- Verify the file starts with a YAML frontmatter block delimited by `---`.
- For agents: confirm `name`, `description`, `tools`, `model` keys are present. If `description` should auto-trigger the agent, confirm it contains `PROACTIVELY` (note when missing — may be intentional).
- For rules: confirm `paths:` (a list of glob patterns) and `description:` keys are present.
- For commands: confirm `description:` is present.
- Report any malformed YAML, missing required keys, or obviously broken frontmatter.

### 3. Rule Path Coverage

For every rule file in `.claude/rules/*.md`:

- Read each glob pattern in `paths:`.
- Use Glob to verify each pattern matches at least one real file in the repo.
- Patterns matching zero files → flag as **possibly dead rule**: either the codebase moved or the rule was scoped wrong. Suggest re-scoping or removal.

### 4. .claude/CLAUDE.md ↔ Rules Cross-Linking

- Read `.claude/CLAUDE.md`.
- Find the `## Domain Rules` section.
- For every `@.claude/rules/*.md` import there, confirm the target file exists.
- For every file under `.claude/rules/`, confirm there is a matching `@` import in `.claude/CLAUDE.md`. Files without an import are loaded only when their `paths:` glob fires — flag this as **isolated rule** so the user knows it won't be globally visible.

### 5. AI Behavior Wiring

- Confirm `.claude/rules/ai-behavior.md` exists.
- Confirm `.claude/CLAUDE.md` has `@.claude/rules/ai-behavior.md` (or equivalent reference) under Domain Rules. If missing, the universal behavior guidelines are not loaded — flag as **High** severity.

### 5b. CONTEXT/JOURNAL Wiring (token hygiene)

- Confirm `@.claudart/CONTEXT.md` is referenced in `.claude/CLAUDE.md` Domain Rules. If missing, current-state handoff isn't loaded — flag as **Medium**.
- `.claudart/CONTEXT.md` line count must be ≤ 150 (use `wc -l`, do NOT full-read the file). If exceeded, flag as **High** — past the declarative ceiling, needs trimming or graduation via `/learn`.
- **CRITICAL**: search `.claude/CLAUDE.md` AND every file in `.claude/rules/` for any `@.claudart/JOURNAL.md` reference (use `grep -r '@.claudart/JOURNAL.md' .claude/CLAUDE.md .claude/rules/`). If found, flag as **Critical** — JOURNAL must NEVER be loaded into session context (defeats the entire token-saving purpose). Recommend immediate removal.
- For `.claudart/JOURNAL.md` integrity, use spot-checks rather than full reads (the file may be large):
    - `head -n 20 .claudart/JOURNAL.md` — verify the canonical header is intact.
    - `wc -l .claudart/JOURNAL.md` — report total entry count for the user.
    - `tail -n 5 .claudart/JOURNAL.md` — sample-check the most recent lines match the `YYYY-MM-DD | <type> | <summary>` format.
    - Skip deeper validation. If a malformed line is suspected, ask the user; do not slurp the whole file just to verify format.

### 6. Anti-Patterns Inside Rules and Agents

- **Inlined code blocks**: any triple-backtick code block longer than ~5 lines inside a rule or agent file is a likely violation of the "NO CODE SNIPPETS" principle. Report file + line.
- **Stale metadata**: lines like `Last Updated: <date>` rot quickly. Flag for removal.
- **Hardcoded shell patterns** (e.g., long `grep -r` lists) inside agent files. Flag — these belong in the project's tooling, not the agent prompt.

### 7. .claude/CLAUDE.md Size Sanity

- Count lines of `.claude/CLAUDE.md`. The target is < 100 lines.
- If significantly larger, recommend running `/refactor-memory` to extract domains.

### 8. Agent Overlap

- For all files in `.claude/agents/`, compare their `description:` fields.
- If two agents share >50% of trigger keywords (e.g., both contain "review", "code", "PROACTIVELY"), flag as **possible overlap** — they may both auto-trigger on the same situation and waste tokens.

## Output Format

```
# CLAUDART Health Check

## ✅ Passing
- [item 1]
- [item 2]

## ⚠️ Warnings
**[file:line or section]** — [what's wrong] → [suggested action]

## ❌ Errors
**[file or section]** — [what's broken] → [suggested action]

## Recommended Next Step
[Single actionable suggestion: e.g., "Run /refactor-memory to extract domains and create missing ai-behavior import."]
```

If everything passes, output a one-line summary: `✅ CLAUDART installation healthy. <n> rules, <n> agents, <n> commands.`

**Reminder**: this command is read-only. Never modify files.
