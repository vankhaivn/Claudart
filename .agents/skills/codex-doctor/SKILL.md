---
name: codex-doctor
description: Run a read-only health check for the Codex installation.
---

# Codex Doctor

Run a read-only health check on this repository's CLAUDART installation from the Codex side. This is diagnostic only. Do not auto-fix anything. Report findings so the user can run `$codex-refactor-memory`, `/refactor-memory`, or edit files manually.

## What to Check

### 1. Required Structure

- `AGENTS.md` exists at the repository root (copied from `.codex/AGENTS.md` by the installer).
- `.codex/CONTEXT.md` exists. Warn if missing because the user may not have run checkpoint yet.
- `.codex/JOURNAL.md` exists. Warn if missing.
- `.codex/guidelines/` exists and contains at least `ai-behavior.md`.
- `.codex/agents/` exists, even if the user removed shipped agents.
- `.agents/skills/` exists and contains `codex-checkpoint`, `codex-learn`, `codex-doctor`, and `codex-refactor-memory`.

For each missing path, report which workflow would create or repair it.

### 2. Frontmatter and Metadata Validity

For every `.md` file under `.codex/guidelines/`:

- Verify the file starts with YAML frontmatter delimited by `---`.
- Confirm `paths:` and `description:` are present.
- Report malformed YAML, missing required keys, or obviously broken frontmatter.

For every `.agents/skills/*/SKILL.md` file:

- Verify the file starts with YAML frontmatter.
- Confirm `name:` and `description:` are present.
- Confirm the skill contains sufficient procedure detail to execute the workflow.

For every `.codex/agents/*.toml` file:

- Confirm `name`, `description`, `model`, `model_reasoning_effort`, `sandbox_mode`, and `developer_instructions` keys are present.
- Confirm review/explorer agents use `sandbox_mode = "read-only"` unless their purpose clearly requires writes.

### 3. Guideline Path Coverage

For every guideline file in `.codex/guidelines/*.md`:

- Read each glob pattern in `paths:`.
- Verify each pattern matches at least one real file in the repo.
- Patterns matching zero files -> flag as possibly dead guideline. Suggest re-scoping or removal.

`paths: ["**/*"]` is allowed for universal guidelines such as `ai-behavior.md`.

### 4. Codex Memory Cross-Linking

- Read `AGENTS.md`.
- Confirm it points Codex to `.codex/CONTEXT.md` and `.codex/guidelines/*.md`.
- Find the guideline section in `AGENTS.md`.
- For every `.codex/guidelines/*.md` reference there, confirm the target file exists.
- For every file under `.codex/guidelines/`, confirm there is a matching reference in `AGENTS.md`. Files without a reference may not be loaded consistently; flag them as isolated guidelines.

### 5. AI Behavior Wiring

- Confirm `.codex/guidelines/ai-behavior.md` exists.
- Confirm `AGENTS.md` references `.codex/guidelines/ai-behavior.md`.
- If missing, flag as High severity because universal behavior guidelines are not loaded.

### 6. CONTEXT/JOURNAL Wiring

- Confirm `.codex/CONTEXT.md` is referenced in `AGENTS.md`.
- `.codex/CONTEXT.md` line count must be at most 150. Use `wc -l`; do not full-read the file just to count.
- Search `AGENTS.md` and `.codex/guidelines/` for any operational auto-load instruction for `.codex/JOURNAL.md`. If found, flag as Critical.
- For `.codex/JOURNAL.md` integrity, use spot-checks rather than full reads:
  - `head -n 20 .codex/JOURNAL.md`
  - `wc -l .codex/JOURNAL.md`
  - `tail -n 5 .codex/JOURNAL.md`
- Skip deeper validation unless a malformed line is suspected.

### 7. Anti-Patterns

- Inlined code blocks longer than about 5 lines inside guideline or agent files. These usually violate the no-stale-snippets rule.
- Stale metadata such as `Last Updated: <date>`.
- Hardcoded shell pattern lists inside agent instructions. Agents should use repository tooling or discover patterns from the codebase.
- Vague Codex skills that do not contain sufficient detail to execute the workflow.

### 8. Size Sanity

- Count lines in `AGENTS.md`. Target is under 100 lines.
- If bloated, recommend `$codex-refactor-memory`.

### 9. Agent Overlap

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
CLAUDART Codex installation healthy. <n> guidelines, <n> agents, <n> skills.
```

Reminder: this command is read-only. Never modify files.
