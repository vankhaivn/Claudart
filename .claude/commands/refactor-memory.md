---
description: Auto-refactor .claude/CLAUDE.md, rules, and agents into a coherent Modular Rules System
---

Please analyze the existing `.claude/CLAUDE.md` (if any), `.claude/rules/*.md`, and `.claude/agents/*.md` in this repository and refactor everything into a coherent **Modular Rules System**. The goal is a lightweight `.claude/CLAUDE.md` (< 100 lines) acting purely as an index, with all domain knowledge extracted into path-scoped files inside `.claude/rules/`. Agents must also be audited so they stay on-pattern.

> **Pre-flight check (the user relies on git for rollback)**: confirm `git status` is clean or that the user has committed in-progress work before you begin. Refuse to proceed if the working tree has unrelated uncommitted changes that this refactor could swallow.

Execute the following steps systematically, without losing essential project context.

## 1. Analyze the Project

- Determine the main framework, language, and architectural layers based on `.claude/CLAUDE.md` and the project structure.
- Identify the core logical layers (e.g., Database/Repositories, API/Controllers, UI/Components, Background Jobs).
- Note linters/formatters/test runners detected — you will delegate styling rules to them rather than encoding into `.claude/CLAUDE.md`.

## 2. Ensure the Rules Directory Exists

Create `.claude/rules/` if it doesn't already exist.

## 3. Extract Domain-Specific Rules from .claude/CLAUDE.md

Group detailed coding rules, boundaries, and validation requirements from `.claude/CLAUDE.md` into 2–4 logical domain files inside `.claude/rules/` (e.g., `db-rules.md`, `api-routers.md`, `ui-components.md`).

**Required for each rule file:**

- **YAML frontmatter** with `paths:` glob to scope the rule (prevents VSCode YAML lint errors). Example:
  ```yaml
  ---
  paths: ["src/models/**/*.py", "src/repositories/**/*.py"]
  description: One-line summary of what this domain covers.
  ---
  ```
- **NO CODE SNIPPETS**. Do NOT copy-paste code blocks. Use file:line references (e.g., `See src/core/db.ts:45 for the connection pattern`) so context never gets stale.
- **Rule Quality Checklist** — for every rule written, verify:
  1. **Verifiable**: a reader can check whether it was followed by reading the code. If you can't verify it, rewrite it.
  2. **Loophole-closed**: if the rule has an obvious bypass, add `NEVER X, even when Y` to name the rationalization.
  3. **Critical-tagged**: prefix high-priority constraints with `NEVER`, `YOU MUST`, or `IMPORTANT`. Emphasis raises adherence.

## 4. Refactor .claude/CLAUDE.md

Trim `.claude/CLAUDE.md` so it ONLY contains:
- Project Overview
- Core CLI Commands
- Path Aliases
- Global Naming Conventions
- Domain Rules cross-links (step 5)
- AI Behavior Guidelines reference (step 6)
- Agent Self-Evolution section (step 8)

**CRITICAL**: PURGE all domain-specific logic AND style/formatting rules — delegate styling to standard tools (Prettier, ESLint, Ruff, gofmt). Do not duplicate info already in `package.json` or `README.md`. Less is more.

## 5. Cross-Link the Rules

Under a `## Domain Rules` heading near the bottom of the trimmed `.claude/CLAUDE.md`, add semantic imports for every rule file, plus the live-state CONTEXT file:

```markdown
See @.claudart/CONTEXT.md for the current state of work (updated by /checkpoint).
See @.claude/rules/architecture.md for global boundaries.
See @.claude/rules/db-rules.md for database patterns.
```

**NEVER add `@.claudart/JOURNAL.md`** — JOURNAL is intentionally excluded from session context to save tokens. If you find such an import already in `.claude/CLAUDE.md`, remove it and warn the user in your final summary.

## 6. Wire Up AI Behavior Guidelines (file-based, not inlined)

CLAUDART ships `.claude/rules/ai-behavior.md` as the canonical universal behavior guideline (Karpathy-derived).

- If `.claude/rules/ai-behavior.md` does NOT exist, create it from the CLAUDART template (see https://github.com/vankhaivn/Claudart) or copy from a fresh CLAUDART checkout.
- Do NOT inline the guidelines into `.claude/CLAUDE.md`. Instead, add this single line under the `## Domain Rules` heading:
  ```markdown
  See @.claude/rules/ai-behavior.md for universal AI behavior guidelines.
  ```
- If the user has customized `ai-behavior.md`, leave their content alone — only ensure the `@` import exists.

## 7. Audit Existing Rules and Agents (keep the whole system on-pattern)

Refactor isn't only about `.claude/CLAUDE.md`. Sweep through `.claude/rules/*.md` and `.claude/agents/*.md` and enforce the same standards.

For every file in `.claude/rules/`:
- Verify YAML frontmatter exists with a valid `paths:` glob and a `description:`.
- Run a Glob check on each `paths:` entry — if it matches **zero** files, flag the rule as potentially dead and ask the user whether to remove or rescope it.
- **NO CODE SNIPPETS**: replace any inlined code with `file:line` references.
- Apply the Rule Quality Checklist (verifiable, loophole-closed, critical-tagged).
- Merge near-duplicates: if two rules cover ≥80% the same scope, propose a consolidation (do not execute without user confirmation).

For every file in `.claude/agents/`:
- Verify YAML frontmatter has `name`, `description` (with `PROACTIVELY` if it should auto-trigger), `tools`, and `model`.
- Strip stale metadata like hardcoded `Last Updated: <date>` lines.
- Replace example code blocks with references to a real file in the project, OR remove them.
- Replace hardcoded `grep`/shell pattern lists with guidance ("scan the codebase for hardcoded secrets using the project's security tooling").
- Confirm the agent's responsibilities don't overlap >50% with another agent — if they do, propose a merge.

For `.claudart/CONTEXT.md`:
- Confirm it exists. If not, create it from the CLAUDART template (declarative state file maintained by `/checkpoint`).
- Verify line count ≤ 150. If exceeded, flag for user review — propose either trimming or graduating long-lived items into `.claude/rules/`.
- Confirm `@.claudart/CONTEXT.md` is imported in `.claude/CLAUDE.md` (Domain Rules section). If missing, add it.

For `.claudart/JOURNAL.md`:
- Confirm it exists. If not, create it from the CLAUDART template.
- **CRITICAL**: search `.claude/CLAUDE.md` and every file in `.claude/rules/` for any `@.claudart/JOURNAL.md` reference. If found, REMOVE it — JOURNAL must never be loaded into session context. Warn the user that this was fixed.
- Do NOT prune or rewrite JOURNAL entries. The file is append-only by contract.

Report all proposed audit changes in a clear bulleted list before applying them. Apply the safe ones (frontmatter fixes, snippet removal, missing `@.claudart/CONTEXT.md` import, JOURNAL @import removal); ask the user before merging or deleting agents/rules.

## 8. Append Agent Self-Evolution Section

At the very end of `.claude/CLAUDE.md`, APPEND `## Agent Self-Evolution & Context Maintenance` (skip if it already exists). Include these rules verbatim:

- "Do not assume a human will document your code patterns. If you build it, document it."
- Existing rules change → update the relevant file in `.claude/rules/`.
- New domains/layers → CREATE a new rule file in `.claude/rules/` (with `paths: [...]` frontmatter) AND APPEND its `@` import to `.claude/CLAUDE.md`'s Domain Rules section.
- Global changes → update `.claude/CLAUDE.md` directly.

## 9. Final Summary

Output a concise summary covering:
1. Domain rule files created/updated in step 3.
2. Audit findings from step 7 (what was auto-fixed vs. what needs user decision).
3. Final `.claude/CLAUDE.md` line count (should be < 100).
4. Suggest the user run `git diff` to review every change before committing.

Confirm only after every step has been completed.
