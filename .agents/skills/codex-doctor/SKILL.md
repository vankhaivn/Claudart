---
name: codex-doctor
description: Run a read-only health check for the Codex installation.
---

# Codex Doctor

Run a read-only health check on this repository's CLAUDART installation from the Codex side. This is diagnostic only. Do not auto-fix anything. Report findings so the user can run `$codex-refactor-memory`, `/refactor-memory`, or edit files manually.

## What to Check

### 1. Required Structure

- A Codex memory index exists: root `AGENTS.md` for an installed downstream project, or `.codex/AGENTS.md` for the CLAUDART source template copied by the installer. If both exist, compare them and flag drift.
- `.codex/CONTEXT.md` exists. Warn if missing because the user may not have run checkpoint yet.
- `.codex/JOURNAL.md` exists. Warn if missing.
- `.codex/guidelines/` exists and contains at least `ai-behavior.md`, `task-management.md`, and `agent-delegation.md`.
- `.codex/knowledge/` exists with `INDEX.md` (warn if missing — `$codex-refactor-memory` will recreate it).
- `.codex/agents/` exists, even if the user removed shipped agents.
- `.codex/config.toml` exists and contains an `[agents]` table with conservative delegation limits.
- `.codex/tasks/` exists with `index.md` and `done/` subdirectory (warn if missing — `$codex-plan` will create on first use).
- `.agents/skills/` exists and contains `codex-start`, `codex-checkpoint`, `codex-learn`, `codex-doctor`, `codex-refactor-memory`, `codex-plan`, and `codex-handoff`.

For each missing path, report which workflow would create or repair it.

### 2. Frontmatter and Metadata Validity

For every `.md` file under `.codex/guidelines/`:

- Verify the file starts with YAML frontmatter delimited by `---`.
- Confirm `paths:`, `description:`, `when_to_use:`, and `tags:` are present.
- Confirm `paths:` uses YAML flow sequence style, e.g. `paths: ["src/**/*.ts", "test/**/*.ts"]`. Flag block-list style (`paths:` followed by `- item`) because frontmatter conventions should stay compact and grep-friendly.
- Confirm `tags:` uses inline YAML array style on one line, e.g. `tags: [architecture, nestjs, boundaries]`. Flag block-list style (`tags:` followed by `- item`) because tag indexing depends on single-line frontmatter.
- Confirm `tags:` contains 1-5 lowercase kebab-case tags describing domain or scope.
- Report malformed YAML, missing required keys, or obviously broken frontmatter.

For every `.agents/skills/*/SKILL.md` file:

- Verify the file starts with YAML frontmatter.
- Confirm `name:` and `description:` are present.
- Confirm the skill contains sufficient procedure detail to execute the workflow.

For every `.codex/agents/*.toml` file:

- Confirm `name`, `description`, `model`, `model_reasoning_effort`, `sandbox_mode`, and `developer_instructions` keys are present.
- Confirm review/explorer agents use `sandbox_mode = "read-only"` unless their purpose clearly requires writes.
- Confirm any worker-style agent clearly describes its write scope expectations and warns that other agents may be editing in parallel.

### 3. Guideline Path Coverage

For every guideline file in `.codex/guidelines/*.md`:

- Read each glob pattern in `paths:`.
- Verify each pattern matches at least one real file in the repo.
- Patterns matching zero files -> flag as possibly dead guideline. Suggest re-scoping or removal.

`paths: ["**/*"]` is allowed for universal guidelines such as `ai-behavior.md`.

### 4. Codex Memory Cross-Linking

- Determine the active memory index to inspect:
  - If root `AGENTS.md` exists, read it.
  - Otherwise read `.codex/AGENTS.md` and report that this is the template source copied to root by `install.sh`.
  - If both exist, compare them and flag drift unless the project deliberately documents a different canonical file.
- Confirm the memory index points Codex to `.codex/CONTEXT.md` and `.codex/guidelines/*.md`.
- Find the guideline section in the memory index.
- For every `.codex/guidelines/*.md` reference there, confirm the target file exists.
- For every file under `.codex/guidelines/`, confirm there is a matching reference in the memory index. Files without a reference may not be loaded consistently; flag them as isolated guidelines.

### 5. AI Behavior Wiring

- Confirm `.codex/guidelines/ai-behavior.md` exists.
- Confirm the active memory index references `.codex/guidelines/ai-behavior.md`.
- If missing, flag as High severity because universal behavior guidelines are not loaded.

### 5b. Agent Delegation Wiring

- Confirm `.codex/guidelines/agent-delegation.md` exists.
- Confirm the active memory index references `.codex/guidelines/agent-delegation.md`.
- Confirm `.codex/config.toml` has `[agents] max_depth = 1`. If higher, flag as Medium unless the repo explicitly documents recursive delegation.
- Confirm `.codex/config.toml` has `[agents] max_threads` set to a positive integer. Flag values above 6 as Medium unless documented, because broad fan-out can create token cost and merge-conflict risk.
- Confirm delegation guidance says subagents require explicit user authorization. If missing, flag as High because Codex may over-delegate on vague prompts.

### 5c. Knowledge Base Wiring (`.codex/knowledge/`)

Skip this section if `.codex/knowledge/` does not exist.

- Confirm `.codex/knowledge/INDEX.md` exists. If missing, flag as Medium — `$codex-refactor-memory` should regenerate it.
- Empty tier (informational — not a Warning): if `INDEX.md` lists no entries and no topic files exist, note that the tier is wired but unused. For a fresh adopter this is normal — do NOT flag it as a problem. If the project plausibly has durable facts worth capturing, surface a gentle nudge (under Passing or Recommended Next Step): `$codex-refactor-memory` will seed it from existing docs (grounded drafts you review in the diff), and `$codex-checkpoint` fills it over time.
- INDEX ↔ files match (both directions):
  - Every `.md` file under `.codex/knowledge/` (excluding `INDEX.md`) must be listed in `INDEX.md`. Unlisted files -> flag as Medium (invisible to `$codex-start`, defeats the tier).
  - Every entry in `INDEX.md` must point to a file that exists on disk. Dead entries -> flag as Low.
- For every knowledge file (excluding `INDEX.md`), check frontmatter: required `name`, `description`, `type`, `updated`; `type` in {domain, architecture, integration, glossary, reference, agent-context}. Missing/invalid -> flag as Low.
- Dead local references: for each `sources:` entry that is a relative path, confirm the target exists on disk; missing -> flag as Low. Do NOT fetch URLs — only list `sources:` that are neither a valid `http(s)` URL nor an existing path as malformed.
- Staleness: flag any knowledge file whose `updated:` is more than 90 days old, or whose stated `verify:` condition no longer holds, as a Low review candidate.
- Descriptive-only separation: knowledge is facts, not behavior. If a knowledge file contains prescriptive language (`MUST`, `NEVER`, `YOU MUST`, `always do`/`never do`), flag as Medium — that content belongs in `.codex/guidelines/`. The boundary runs both ways — §7 flags the reverse (a purely descriptive guideline that belongs in knowledge).
- INDEX stays a map: `INDEX.md` should be one line per entry. If it grows prose paragraphs or deep sections, flag as Low.
- Not auto-loaded: search the active memory index (`AGENTS.md` / `.codex/AGENTS.md`) for any operational auto-load instruction for a knowledge detail file. A plain pointer line to `INDEX.md` is fine; an auto-load directive -> flag as Medium (`$codex-start` surfaces the index; knowledge is not force-loaded every turn).
- Unanchored entries (staleness cannot be checked): a knowledge file with neither a `sources:` path nor a `verify:` condition can't be staleness-checked deterministically -> flag as Low, suggest adding a `verify:` anchor or a `sources:` path so future runs can catch rot.
- Dead code references in the body: for each backtick-quoted repo path in a knowledge body (e.g. `src/auth/legacy.ts`), confirm it still exists; missing -> flag as Low (the fact may describe deleted code). Bounded and offline — check only backtick'd path-like tokens, never free prose.
- Dangling `related:` links: for each `[[slug]]` in a knowledge file's `related:`, confirm it resolves to an existing knowledge topic (`<slug>.md`) or guideline; unresolved -> flag as Low.
- Duplication signal: if two knowledge entries share most of their `description` keywords, or an entry's keywords strongly overlap a guideline's `description`/`tags`, flag as Low — possible intra-tier or cross-tier duplication (`$codex-refactor-memory` can consolidate). Keyword-overlap only; do not deep-read to confirm.

### 6. CONTEXT/JOURNAL Wiring

- Confirm `.codex/CONTEXT.md` is referenced in the active memory index.
- `.codex/CONTEXT.md` line count must be at most 150. Use `wc -l`; do not full-read the file just to count.
- Report approximate `.codex/CONTEXT.md` tokens using both estimates:
  - `wc -w .codex/CONTEXT.md | awk '{printf "~%d tokens\n", $1 * 1.3}'`
  - `wc -c .codex/CONTEXT.md | awk '{printf "~%d tokens (byte estimate)\n", $1 / 4}'`
- Search the active memory index and `.codex/guidelines/` for any operational auto-load instruction for `.codex/JOURNAL.md`. If found, flag as Critical.
- Search `.codex/CONTEXT.md` for `<!-- since: YYYY-MM-DD -->` comments. Flag items older than 30 days as graduation candidates if they remain in Recent Decisions or otherwise look durable. If an obviously long-lived decision has no `since:` comment, warn that future `$codex-checkpoint` should preserve/add one.
- For `.codex/JOURNAL.md` integrity, use spot-checks rather than full reads:
  - `head -n 20 .codex/JOURNAL.md`
  - `wc -l .codex/JOURNAL.md`
  - `tail -n 5 .codex/JOURNAL.md`
- Skip deeper validation unless a malformed line is suspected.

### 6b. Task Document Health (`.codex/tasks/`)

Skip this section if `.codex/tasks/` does not exist.

- Confirm `.codex/tasks/index.md` exists. If missing, flag as Medium — `$codex-checkpoint` or `$codex-plan` should regenerate it.
- Count `.codex/tasks/index.md` lines via `wc -l`. Hard ceiling 100. If exceeded, flag as High — trim Recently Done.
- For every `.codex/tasks/*.md` file (excluding `index.md` and `done/`), check the YAML frontmatter:
  - Required keys: `slug`, `status`, `created`, `updated`, `agent`, `tags`.
  - `status` must be one of: `planning`, `in-progress`, `awaiting-review`, `blocked`, `done`, `cancelled`.
  - `slug` must match the filename (excluding the `YYYY-MM-DD-NNN-` prefix and `.md` suffix).
  - `tags` must be inline YAML array style with 1-5 lowercase kebab-case tags.
- Flag any task in the top-level folder with `status: done` or `status: cancelled` — these should have been moved to `done/` by `$codex-checkpoint`. Suggest running `$codex-checkpoint`.
- Flag any task with `status: in-progress` AND `updated:` more than 7 days old as stalled — Medium severity. Suggest flipping to `blocked` or `cancelled`.
- Flag any task with `status: awaiting-review` AND `updated:` more than 3 days old as stuck awaiting confirmation — Medium severity. The agent has reported completion; the user has not confirmed. Surface prominently and suggest the user verify and run the close-out signal (or reject and flip back to in-progress).
- Flag any task with `status: planning` AND `updated:` more than 14 days old — the user probably abandoned it. Suggest cancellation.
- Cross-check `index.md` Active entries against actual task files: every Active entry must correspond to a real file; every real file with `status` in {planning, in-progress, awaiting-review, blocked} must appear in Active. Mismatches -> suggest `$codex-checkpoint` to resync.
- Required sections in every task file body: `## Purpose`, `## Context & Orientation`, `## Plan of Work`, `## Concrete Steps`, `## Validation & Acceptance`, `## Decision Log`, `## Surprises & Discoveries`, `## Outcomes & Retrospective`. Flag missing sections.
- Within `## Context & Orientation`, flag if `### Memory Hints` is missing or empty — that section is the cross-session lifeline.
- Redundant `.gitkeep`: if `.codex/tasks/done/.gitkeep` exists AND `.codex/tasks/done/` contains at least one real `.md` file, flag as Low severity. The `.gitkeep` exists only to track an empty folder; once real archived tasks live there, it is redundant. Mention that `$codex-refactor-memory` will clean it up, or the user can `rm` it manually.

### 6c. Session Handoff Hygiene (`.codex/HANDOFF.md`)

`.codex/HANDOFF.md` is a transient single-slot baton written by `$codex-handoff` and consumed (deleted) by the next `$codex-start`. Absent is the normal state — never warn when it is missing.

- If present, it is an unconsumed baton. Report it informationally. If its frontmatter `created:` is more than 7 days old, flag as Medium — reasoning state rots fast; suggest resuming via `$codex-start` or deleting it.
- Line count must be at most 150 (use `wc -l`). If exceeded, flag as High — the baton is drifting toward a transcript dump; `$codex-handoff`'s distillation rules were not honored.
- Search the active memory index (`AGENTS.md` / `.codex/AGENTS.md`) and `.codex/guidelines/` for any operational auto-load instruction for `.codex/HANDOFF.md`. If found, flag as Critical — the baton is consumed once by `$codex-start`, never auto-loaded into every session.
- Multiple handoff artifacts (`HANDOFF-*.md`, dated copies, a `handoff/` directory under `.codex/`) -> flag as Medium — violates the single-slot contract; suggest consolidating into one `HANDOFF.md` or deleting stale copies.

### 7. Anti-Patterns

- Inlined code blocks longer than about 5 lines inside guideline or agent files. These usually violate the no-stale-snippets rule.
- Stale metadata such as `Last Updated: <date>`.
- Hardcoded shell pattern lists inside agent instructions. Agents should use repository tooling or discover patterns from the codebase.
- Vague Codex skills that do not contain sufficient detail to execute the workflow.
- Agent delegation instructions that promise automatic subagent use without explicit user authorization.
- Worker agent instructions that allow overlapping writes or omit ownership boundaries.
- Mis-tiered guideline (descriptive, not prescriptive): a `.codex/guidelines/` file whose body states only facts (how a subsystem works, an integration detail, a domain term, a doc pointer) with no behavioral constraint (`MUST`/`NEVER`/`should`/`avoid`/`always`/`never`) -> flag as Low: it likely belongs in `.codex/knowledge/`. Mirror of §5c's descriptive-only check; the boundary runs both ways. Universal guidance like `ai-behavior.md` is exempt.

### 8. Size Sanity

- Count lines in the active memory index. Target is under 100 lines.
- Report approximate tokens using both estimates:
  - `wc -w <active-memory-index> | awk '{printf "~%d tokens\n", $1 * 1.3}'`
  - `wc -c <active-memory-index> | awk '{printf "~%d tokens (byte estimate)\n", $1 / 4}'`
- If bloated, recommend `$codex-refactor-memory`.

### 9. Guideline Tag Index And Overlap

- Build a tag index from guideline frontmatter only, e.g. `grep -h '^tags:' .codex/guidelines/*.md | sort -u`.
- Flag guidelines missing `tags:`, using block-list tags, or using vague/non-domain tags.
- Use overlapping tags as an initial signal for possible duplicate guidelines; read bodies only when tags or paths suggest overlap.

### 10. Agent Overlap

For all files in `.codex/agents/`, compare their `description` and responsibilities.

If two agents share more than 50% of trigger keywords or review scope, flag possible overlap. They may waste tokens or compete for the same work.

## Output Format

```text
# CLAUDART Codex Health Check

## Passing
- [item 1]
- [item 2]

## Warnings
[file:line or section] - [what is wrong] -> [suggested action]

## Errors
[file or section] - [what is broken] -> [suggested action]

## Recommended Next Step
[Single actionable suggestion]
```

If everything passes, output:

```text
CLAUDART Codex installation healthy. <n> guidelines, <n> knowledge entries, <n> agents, <n> skills. Delegation wiring: <ok/warnings>.
```

Reminder: this command is read-only. Never modify files.
