# CLAUDART Project Memory

## Project Overview

CLAUDART keeps the AI operating layer inside `.claude/`: project memory, domain rules, live context, journal, commands, and agents. If Claude Code `/init` generates a root `CLAUDE.md`, copy its useful project-specific content into this file before running `/refactor-memory`.

## Core Commands

- `/refactor-memory` consolidates this file, `.claude/rules/`, and `.claude/agents/` into a coherent Modular Rules System.
- `/checkpoint` rewrites `.claude/CONTEXT.md` as the current state and appends meaningful retired items to `.claude/JOURNAL.md`.
- `/learn` promotes validated recurring decisions into `.claude/rules/`.
- `/doctor` runs a read-only health check on the CLAUDART installation.

## Domain Rules

See @.claude/CONTEXT.md for the current state of work (updated by /checkpoint).
See @.claude/rules/ai-behavior.md for universal AI behavior guidelines.

## Agent Self-Evolution & Context Maintenance

- "Do not assume a human will document your code patterns. If you build it, document it."
- Existing rules change -> update the relevant file in `.claude/rules/`.
- New domains/layers -> CREATE a new rule file in `.claude/rules/` (with `paths: [...]` frontmatter) AND APPEND its `@` import to `.claude/CLAUDE.md`'s Domain Rules section.
- Global changes -> update `.claude/CLAUDE.md` directly.
