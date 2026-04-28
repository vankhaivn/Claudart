# Codex Refactor Memory Command

Analyze the existing Codex memory layer in this repository and refactor it into a coherent Codex-native Modular Rules System. The goal is a lightweight `AGENTS.md` plus `.codex/CODEX.md` acting as indexes, with durable domain knowledge extracted into scoped files inside `.codex/guidelines/`. Codex skills and agents must also be audited so they stay on-pattern.

This is the Codex-native equivalent of Claude Code `/refactor-memory`. It must preserve the same quality bar as `.claude/commands/refactor-memory.md`, adapted to Codex paths and skill mechanics.

> Pre-flight check: confirm `git status` is clean or that the user has committed in-progress work before you begin. Refuse to proceed if the working tree has unrelated uncommitted changes that this refactor could swallow.

Execute the following steps systematically, without losing essential project context.

## 1. Analyze the Project

- Determine the main framework, language, and architectural layers based on `AGENTS.md`, `.codex/CODEX.md`, and the project structure.
- Identify the core logical layers, such as database/repositories, API/controllers, UI/components, or background jobs.
- Note linters, formatters, and test runners detected. Delegate styling rules to those tools rather than encoding them into `AGENTS.md` or `.codex/CODEX.md`.
- If this repository also has `.claude/`, read it for parity checks, but do not treat `.claude/` as the source of truth unless the user explicitly asks for a sync workflow.

## 2. Ensure the Guideline Directory Exists

Create `.codex/guidelines/` if it does not already exist.

Do not use `.codex/rules/` for semantic coding guidance. Reserve `.codex/rules/*.rules` for Codex permission or environment rules if the project uses them.

## 3. Extract Domain-Specific Rules from Codex Memory

Group detailed coding rules, boundaries, and validation requirements from `AGENTS.md` and `.codex/CODEX.md` into 2-4 logical domain files inside `.codex/guidelines/`, such as `architecture.md`, `api.md`, `db.md`, or `ui.md`.

Required for each guideline file:

- YAML frontmatter with `paths:` glob and `description:`. Example:

```yaml
---
paths: ["src/models/**/*.py", "src/repositories/**/*.py"]
description: Database and repository patterns.
---
```

- NO CODE SNIPPETS. Do not copy-paste code blocks. Use `file:line` references such as `src/core/db.ts:45` so context never goes stale.
- Rule Quality Checklist:
  1. Verifiable: a reader can check whether it was followed by reading the code.
  2. Loophole-closed: if the rule has an obvious bypass, add `NEVER X, even when Y` to name the rationalization.
  3. Critical-tagged: prefix high-priority constraints with `NEVER`, `YOU MUST`, or `IMPORTANT`.

## 4. Refactor AGENTS.md and .codex/CODEX.md

Trim `AGENTS.md` so it stays a root loader, not a knowledge dump. It should contain only:

- Project identity
- Context loading order
- Core Codex workflows
- Links to `.codex/CODEX.md`, `.claudart/CONTEXT.md`, and `.codex/guidelines/*.md`
- A clear rule that `.claudart/JOURNAL.md` is not auto-loaded

Trim `.codex/CODEX.md` so it contains only:

- Codex-specific operating standards
- Core commands/skills
- Path aliases
- Guideline cross-links
- Agent self-evolution and context maintenance

Target: keep both files concise. If `.codex/CODEX.md` exceeds 100 lines, extract more into `.codex/guidelines/`.

## 5. Cross-Link the Guidelines

Under a `## Guidelines` or `## Domain Guidelines` heading in `.codex/CODEX.md`, add references for every guideline file plus the live-state context file:

```markdown
See `.claudart/CONTEXT.md` for the current state of work (updated by `$codex-checkpoint`).
See `.codex/guidelines/architecture.md` for global boundaries.
See `.codex/guidelines/db.md` for database patterns.
```

NEVER add `.claudart/JOURNAL.md` as a loaded context reference. JOURNAL is intentionally excluded from session context to save tokens. If you find such an import or auto-load instruction in `AGENTS.md`, `.codex/CODEX.md`, or `.codex/guidelines/`, remove it and warn the user in your final summary.

## 6. Wire Up AI Behavior Guidelines

CLAUDART ships `.codex/guidelines/ai-behavior.md` as the Codex-native universal behavior guideline.

- If `.codex/guidelines/ai-behavior.md` does not exist, create it from the CLAUDART template.
- Do not inline the guidelines into `AGENTS.md` or `.codex/CODEX.md`.
- Add a single reference under the guideline section:

```markdown
See `.codex/guidelines/ai-behavior.md` for universal AI behavior guidelines.
```

- If the user has customized `ai-behavior.md`, leave their content alone and only ensure the reference exists.

## 7. Audit Existing Guidelines, Skills, and Agents

Refactor is not only about `AGENTS.md` and `.codex/CODEX.md`. Sweep through `.codex/guidelines/*.md`, `.agents/skills/*/SKILL.md`, and `.codex/agents/*.toml`.

For every file in `.codex/guidelines/`:

- Verify YAML frontmatter exists with a valid `paths:` glob and a `description:`.
- Run a glob check on each `paths:` entry. If it matches zero files, flag the guideline as potentially dead and ask the user whether to remove or rescope it.
- Replace inlined code with `file:line` references.
- Apply the Rule Quality Checklist.
- Merge near-duplicates only after user confirmation.

For every file in `.agents/skills/`:

- Verify `SKILL.md` starts with YAML frontmatter.
- Confirm `name:` and `description:` are present.
- Confirm each skill points to the full protocol in `.codex/commands/` when the command is too large to inline.
- Keep skills thin, but not vague. A future Codex session should know exactly which command file to read and which files it may update.
- Remove stale "generated by sync" marker comments from CLAUDART base templates. In a user project, such markers may exist only on runtime-generated sync targets.

For every file in `.codex/agents/`:

- Verify TOML includes `name`, `description`, `model`, `sandbox_mode`, and `developer_instructions`.
- Keep review/explorer agents read-only unless the agent is explicitly a worker.
- Replace hardcoded grep pattern lists with guidance to scan the codebase and use project security/tooling when present.
- Confirm the agent's responsibilities do not overlap more than 50% with another agent. If they do, propose a merge.

For `.claudart/CONTEXT.md`:

- Confirm it exists. If not, create it from the CLAUDART template.
- Verify line count is at most 150. If exceeded, flag for user review and propose trimming or graduating long-lived items into `.codex/guidelines/`.
- Confirm `AGENTS.md` and `.codex/CODEX.md` reference `.claudart/CONTEXT.md`.

For `.claudart/JOURNAL.md`:

- Confirm it exists. If not, create it from the CLAUDART template.
- Search `AGENTS.md`, `.codex/CODEX.md`, and `.codex/guidelines/` for instructions that auto-load `.claudart/JOURNAL.md`. If found, remove them and warn the user.
- Do not prune or rewrite JOURNAL entries. The file is append-only by contract.

Report proposed audit changes in a clear list before applying them. Apply safe fixes such as frontmatter fixes, snippet removal, missing `.claudart/CONTEXT.md` references, and JOURNAL auto-load removal. Ask before merging or deleting agents/guidelines/skills.

## 8. Preserve Base Template Parity

This CLAUDART repository is a base template. Users copy `.claude/`, `.codex/`, `.agents/`, and `.claudart/` into their own projects.

- In this base repository, `.claude` and `.codex/.agents` are peer source templates. Do not generate one side from the other as a maintenance shortcut.
- If you improve a durable rule, command, skill, or agent here, update both native sides manually so neither tool becomes lower quality.
- Sync commands are for downstream user projects after installation. They are not the authoring workflow for this base template.
- Do not add `Generated by CLAUDART sync` markers to base template files except inside documentation that describes what runtime sync should create.

## 9. Append Agent Self-Evolution Section

At the end of `.codex/CODEX.md`, append `## Agent Self-Evolution & Context Maintenance` if it does not already exist. Include these rules verbatim, adapted to Codex paths:

- "Do not assume a human will document your code patterns. If you build it, document it."
- Existing guidelines change -> update the relevant file in `.codex/guidelines/`.
- New domains/layers -> create a new guideline file in `.codex/guidelines/` with `paths: [...]` frontmatter and append its reference to `.codex/CODEX.md`.
- Global Codex changes -> update `.codex/CODEX.md` or `AGENTS.md` directly.
- Shared live state -> update `.claudart/CONTEXT.md` through `$codex-checkpoint`, not through refactor-memory.

## 10. Final Summary

Output a concise summary covering:

1. Guideline files created or updated.
2. Audit findings from step 7, separated into auto-fixed and needs user decision.
3. Final `AGENTS.md` and `.codex/CODEX.md` line counts.
4. Whether base template parity with `.claude/` was preserved.
5. Suggest the user run `git diff` to review every change before committing.

Confirm only after every step has been completed.
