# CLAUDART Project Memory

## Project Overview

CLAUDART keeps the Claude-specific operating layer inside `.claude/`, including session state. If Claude Code `/init` generates a root `CLAUDE.md`, copy its useful project-specific content into this file before running `/refactor-memory`.

## Core Commands

- `/start` orients a new session from `.claude/CONTEXT.md` plus the last three git commits.
- `/refactor-memory` consolidates this file, `.claude/rules/`, and `.claude/agents/` into a coherent Modular Rules System.
- `/project-discovery` interviews the user about a rough project idea and creates a raw synthesis plus structured project docs.
- `/checkpoint` rewrites `.claude/CONTEXT.md` as the current state and appends meaningful retired items to `.claude/JOURNAL.md`.
- `/learn` promotes validated recurring decisions into `.claude/rules/`.
- `/doctor` runs a read-only health check on the CLAUDART installation.

## Domain Rules

See @.claude/CONTEXT.md for the current state of work (updated by /checkpoint).
See @.claude/rules/ai-behavior.md for universal AI behavior guidelines.

## Agent Self-Evolution & Context Maintenance

- "Do not assume a human will document your code patterns. If you build it, document it."
- Existing rules change -> update the relevant file in `.claude/rules/`.
- New domains/layers -> CREATE a new rule file in `.claude/rules/` (with `paths: [...]`, `description:`, `when_to_use:`, and `tags:` frontmatter) AND APPEND its `@` import to `.claude/CLAUDE.md`'s Domain Rules section.
- Global changes -> update `.claude/CLAUDE.md` directly.
