---
description: Validate the CLAUDART installation in this repository and report any drift, broken rules, or missing wiring
---

Please run a health check on this repository's CLAUDART installation. Your job is **diagnostic only** — do NOT auto-fix anything. Report findings; the user will run `/refactor-memory` or edit files manually based on your output.

## What to Check

### 1. Required Structure

- `.claude/` exists at the repository root
- `.claude/commands/` exists and contains at least: `start.md`, `learn.md`, `refactor-memory.md`, `doctor.md`, `checkpoint.md`, `plan.md`
- `.claude/agents/` exists (may be empty if user removed shipped agents)
- `.claude/rules/` exists (may be empty before the user runs `/refactor-memory`)
- `.claude/knowledge/` exists with `INDEX.md` (warn if missing — `/refactor-memory` will recreate it)
- `.claude/tasks/` exists with `index.md` and `done/` subdirectory (warn if missing — `/plan` will create on first use)
- `.claude/CLAUDE.md` exists
- `.claude/CONTEXT.md` exists (warn if missing — the user may not have run `/checkpoint` yet)
- `.claude/JOURNAL.md` exists (warn if missing)

For each missing path, report which command would create it (e.g., "missing → run `/refactor-memory`").

### 2. YAML Frontmatter Validity

For every `.md` file under `.claude/commands/`, `.claude/agents/`, `.claude/rules/`:

- Verify the file starts with a YAML frontmatter block delimited by `---`.
- For agents: confirm `name`, `description`, `tools`, and `model` keys are present. If `description` should auto-trigger the agent, confirm it contains `PROACTIVELY` (note when missing — may be intentional).
- For rules: confirm `paths:` (a list of glob patterns), `description:`, `when_to_use:`, and `tags:` keys are present.
- For rule `paths:`, confirm paths use YAML flow sequence style, e.g. `paths: ["src/**/*.ts", "test/**/*.ts"]`. Flag block-list style (`paths:` followed by `- item`) because frontmatter conventions should stay compact and grep-friendly.
- For rule `tags:`, confirm tags use inline YAML array style on one line, e.g. `tags: [architecture, nestjs, boundaries]`. Flag block-list style (`tags:` followed by `- item`) because tag indexing depends on single-line frontmatter.
- Confirm there are 1-5 lowercase kebab-case tags describing domain or scope.
- For commands: confirm `description:` is present.
- Report any malformed YAML, missing required keys, or obviously broken frontmatter.

For every `.agents/skills/*/SKILL.md` file:

- Verify the file starts with YAML frontmatter.
- Confirm `name:` and `description:` are present.

### 3. Rule Path Coverage

For every rule file in `.claude/rules/*.md`:

- Read each glob pattern in `paths:`.
- Use Glob to verify each pattern matches at least one real file in the repo.
- Patterns matching zero files → flag as **possibly dead rule**: either the codebase moved or the rule was scoped wrong. Suggest re-scoping or removal.
- `paths: ["**/*"]` is allowed for universal rules such as `ai-behavior.md`.

### 4. .claude/CLAUDE.md ↔ Rules Cross-Linking

- Read `.claude/CLAUDE.md`.
- Find the `## Domain Rules` section.
- For every `@.claude/rules/*.md` import there, confirm the target file exists.
- For every file under `.claude/rules/`, confirm there is a matching `@` import in `.claude/CLAUDE.md`. Files without an import are loaded only when their `paths:` glob fires — flag this as **isolated rule** so the user knows it won't be globally visible.

### 5. AI Behavior Wiring

- Confirm `.claude/rules/ai-behavior.md` exists.
- Confirm `.claude/CLAUDE.md` has `@.claude/rules/ai-behavior.md` (or equivalent reference) under Domain Rules. If missing, the universal behavior guidelines are not loaded — flag as **High** severity.

### 5b. CONTEXT/JOURNAL Wiring (token hygiene)

- Confirm `@.claude/CONTEXT.md` is referenced in `.claude/CLAUDE.md` Domain Rules. If missing, current-state handoff isn't loaded — flag as **Medium**.
- `.claude/CONTEXT.md` line count must be ≤ 150 (use `wc -l`, do NOT full-read the file just to count). Also report approximate tokens using `wc -w .claude/CONTEXT.md | awk '{printf "~%d tokens", $1 * 1.3}'` and cross-check with `wc -c .claude/CONTEXT.md | awk '{printf "~%d tokens", $1 / 4}'`. If line count exceeded, flag as **High** — past the declarative ceiling, needs trimming or graduation via `/learn`.
- **CRITICAL**: search `.claude/CLAUDE.md` AND every file in `.claude/rules/` for any `@.claude/JOURNAL.md` reference (use `grep -r '@.claude/JOURNAL.md' .claude/CLAUDE.md .claude/rules/`). If found, flag as **Critical** — JOURNAL must NEVER be loaded into session context (defeats the entire token-saving purpose). Recommend immediate removal.
- Search `.claude/CONTEXT.md` for `<!-- since: YYYY-MM-DD -->` comments. Flag items older than 30 days as graduation candidates if they remain in Recent Decisions or otherwise look durable. If an obviously long-lived decision has no `since:` comment, warn that future `/checkpoint` should preserve/add one.
- For `.claude/JOURNAL.md` integrity, use spot-checks rather than full reads (the file may be large):
    - `head -n 20 .claude/JOURNAL.md` — verify the canonical header is intact.
    - `wc -l .claude/JOURNAL.md` — report total entry count for the user.
    - `tail -n 5 .claude/JOURNAL.md` — sample-check the most recent lines match the `YYYY-MM-DD | <type> | <summary>` format.
    - Skip deeper validation. If a malformed line is suspected, ask the user; do not slurp the whole file just to verify format.

### 5c. Task Document Health (`.claude/tasks/`)

Skip this section if `.claude/tasks/` does not exist.

- Confirm `.claude/tasks/index.md` exists. If missing, flag as **Medium** — `/checkpoint` or `/plan` should regenerate it.
- Count `.claude/tasks/index.md` lines via `wc -l`. Hard ceiling 100. If exceeded, flag as **High** — trim Recently Done.
- For every `.claude/tasks/*.md` file (excluding `index.md` and `done/`), check the YAML frontmatter:
  - Required keys: `slug`, `status`, `created`, `updated`, `agent`, `tags`.
  - `status` must be one of: `planning`, `in-progress`, `awaiting-review`, `blocked`, `done`, `cancelled`.
  - `slug` must match the filename (excluding the `YYYY-MM-DD-NNN-` prefix and `.md` suffix).
  - `tags` must be inline YAML array style with 1-5 lowercase kebab-case tags.
- Flag any task in the top-level folder with `status: done` or `status: cancelled` — these should have been moved to `done/` by `/checkpoint`. Suggest running `/checkpoint`.
- Flag any task with `status: in-progress` AND `updated:` more than 7 days old as **stalled** — Medium severity. Suggest flipping to `blocked` or `cancelled`.
- Flag any task with `status: awaiting-review` AND `updated:` more than 3 days old as **stuck awaiting confirmation** — Medium severity. The agent has reported completion; the user has not confirmed. Surface prominently and suggest the user verify and run the close-out signal (or reject and flip back to in-progress).
- Flag any task with `status: planning` AND `updated:` more than 14 days old — the user probably abandoned it. Suggest cancellation.
- Cross-check `index.md` Active entries against actual task files: every Active entry must correspond to a real file; every real file with `status` ∈ {planning, in-progress, blocked} must appear in Active. Mismatches → suggest `/checkpoint` to resync.
- Required sections in every task file body: `## Purpose`, `## Context & Orientation`, `## Plan of Work`, `## Concrete Steps`, `## Validation & Acceptance`, `## Decision Log`, `## Surprises & Discoveries`, `## Outcomes & Retrospective`. Flag missing sections.
- Within `## Context & Orientation`, flag if `### Memory Hints` is missing or empty — that section is the cross-session lifeline.
- **Redundant `.gitkeep`**: if `.claude/tasks/done/.gitkeep` exists AND `.claude/tasks/done/` contains at least one real `.md` file, flag as **Low** severity. The `.gitkeep` exists only to track an empty folder; once real archived tasks live there, it is redundant. Mention that `/refactor-memory` will clean it up, or the user can `rm` it manually.

### 5d. Knowledge Tier Wiring (`.claude/knowledge/`)

Skip this section if `.claude/knowledge/` does not exist.

- Confirm `.claude/knowledge/INDEX.md` exists. If missing, flag as **Medium** — `/refactor-memory` should regenerate it.
- **Empty tier** (informational — not a Warning): if `INDEX.md` lists no entries and no topic files exist, note that the tier is wired but unused. For a fresh adopter this is normal — do NOT flag it as a problem. If the project plausibly has durable facts worth capturing, surface a gentle nudge (under Passing or Recommended Next Step): `/refactor-memory` can bootstrap it (opt-in, from existing docs), and `/checkpoint` fills it over time.
- **INDEX ↔ files match** (both directions):
  - Every `.md` file under `.claude/knowledge/` (excluding `INDEX.md`) must be listed in `INDEX.md`. Unlisted files → flag as **Medium** (invisible to `/start`, defeats the tier).
  - Every entry in `INDEX.md` must point to a file that exists on disk. Dead entries → flag as **Low**.
- For every knowledge file (excluding `INDEX.md`), check frontmatter: required `name`, `description`, `type`, `updated`; `type` ∈ {domain, architecture, integration, glossary, reference, agent-context}. Missing/invalid → flag as **Low**.
- **Dead local references**: for each `sources:` entry that is a relative path, confirm the target exists on disk; missing → flag as **Low** (stale pointer). Do NOT fetch URLs — only list `sources:` that are neither a valid `http(s)` URL nor an existing path as malformed.
- **Staleness**: flag any knowledge file whose `updated:` is more than 90 days old, or whose stated `verify:` condition no longer holds, as a **Low** review candidate.
- **Descriptive-only separation**: knowledge is facts, not behavior. If a knowledge file contains prescriptive language (`MUST`, `NEVER`, `YOU MUST`, `always do`/`never do`), flag as **Medium** — that content belongs in `.claude/rules/`. The boundary runs both ways — §6 flags the reverse (a purely descriptive *rule* that belongs in knowledge).
- **INDEX stays a map**: `INDEX.md` should be one line per entry. If it grows prose paragraphs or deep sections, flag as **Low** (knowledge belongs in topic files, not the index).
- **Not auto-loaded**: run `grep -n '@.claude/knowledge/' .claude/CLAUDE.md`. A plain (non-`@`) pointer line is fine; an `@`-import of `INDEX.md` or any detail file → flag as **Medium** (knowledge is surfaced by `/start`, not force-loaded every turn).
- **Unanchored entries** (staleness cannot be checked): a knowledge file with neither a `sources:` path nor a `verify:` condition can't be staleness-checked deterministically → flag as **Low**, suggest adding a `verify:` anchor or a `sources:` path so future runs can catch rot.
- **Dead code references in the body**: for each backtick-quoted repo path in a knowledge body (e.g. `` `src/auth/legacy.ts` ``), use Glob to confirm it still exists; missing → flag as **Low** (the fact may describe deleted code). Bounded & offline — check only backtick'd path-like tokens, never free prose.
- **Dangling `related:` links**: for each `[[slug]]` in a knowledge file's `related:`, confirm it resolves to an existing knowledge topic (`<slug>.md`) or rule; unresolved → flag as **Low**.
- **Duplication signal**: if two knowledge entries share most of their `description` keywords, or an entry's keywords strongly overlap a rule's `description`/`tags`, flag as **Low** — possible intra-tier or cross-tier duplication (`/refactor-memory` can consolidate). Keyword-overlap only; do not deep-read to confirm.

### 6. Anti-Patterns Inside Rules and Agents

- **Inlined code blocks**: any triple-backtick code block longer than ~5 lines inside a rule or agent file is a likely violation of the "NO CODE SNIPPETS" principle. Report file + line.
- **Stale metadata**: lines like `Last Updated: <date>` rot quickly. Flag for removal.
- **Hardcoded shell patterns** (e.g., long `grep -r` lists) inside agent files. Flag — these belong in the project's tooling, not the agent prompt.
- **Mis-tiered rule (descriptive, not prescriptive)**: a `.claude/rules/` file whose body states only facts (how a subsystem works, an integration detail, a domain term, a doc pointer) with no behavioral constraint (`MUST`/`NEVER`/`should`/`avoid`/`always`/`never`) → flag as **Low**: it likely belongs in `.claude/knowledge/`. This is the mirror of §5d's descriptive-only check — the boundary runs both ways. Universal guidance like `ai-behavior.md` is exempt.

### 7. .claude/CLAUDE.md Size Sanity

- Count lines of `.claude/CLAUDE.md`. The target is < 100 lines.
- Report approximate tokens using both estimates:
  - `wc -w .claude/CLAUDE.md | awk '{printf "~%d tokens\n", $1 * 1.3}'`
  - `wc -c .claude/CLAUDE.md | awk '{printf "~%d tokens (byte estimate)\n", $1 / 4}'`
- If significantly larger, recommend running `/refactor-memory` to extract domains.

### 8. Rule Tag Index And Overlap

- Build a tag index from rule frontmatter only, e.g. `grep -h '^tags:' .claude/rules/*.md | sort -u`.
- Flag rules missing `tags:`, using block-list tags, or using vague/non-domain tags.
- Use overlapping tags as an initial signal for possible duplicate rules; read bodies only when tags or paths suggest overlap.

### 9. Agent Overlap

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

If everything passes, output a one-line summary: `✅ CLAUDART installation healthy. <n> rules, <n> knowledge entries, <n> agents, <n> commands.`

**Reminder**: this command is read-only. Never modify files.
