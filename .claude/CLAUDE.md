# CLAUDART Project Memory

## Project Overview

CLAUDART keeps the Claude-specific operating layer inside `.claude/`, including session state. If Claude Code `/init` generates a root `CLAUDE.md`, copy its useful project-specific content into this file before running `/refactor-memory`.

## Core Commands

- `/start` orients a new session from `.claude/CONTEXT.md`, `.claude/tasks/index.md`, `.claude/knowledge/INDEX.md`, and the last three git commits.
- `/plan <description>` creates a persistent implementation plan in `.claude/tasks/` — use instead of native plan mode for any multi-session or multi-file work.
- `/refactor-memory` consolidates this file, `.claude/rules/`, and `.claude/agents/` into a coherent Modular Rules System.
- `/project-discovery` interviews the user about a rough project idea and creates a raw synthesis plus structured project docs.
- `/checkpoint` rewrites `.claude/CONTEXT.md` as the current state, syncs `.claude/tasks/index.md`, and appends meaningful retired items to `.claude/JOURNAL.md`.
- `/handoff` writes a single-slot session baton (`.claude/HANDOFF.md`) distilling this session's reasoning state — run when the context window is nearly full or when pausing mid-investigation; the next `/start` consumes and deletes it. Never auto-load `HANDOFF.md`.
- `/learn` promotes validated recurring decisions into `.claude/rules/`.
- `/doctor` runs a read-only health check on the CLAUDART installation.

## Domain Rules

See @.claude/CONTEXT.md for the current state of work (updated by /checkpoint).
See @.claude/rules/ai-behavior.md for universal AI behavior guidelines.
See @.claude/rules/task-management.md for the persistent task-document workflow that replaces native plan mode.
See @.claude/rules/agent-delegation.md for the subagent delegation protocol (when the user authorizes parallel agent work).

Project knowledge: see `.claude/knowledge/INDEX.md` for durable project facts and pointers to external docs. Surfaced by `/start`; NOT auto-loaded (no `@`) — read entries on demand.

## Agent Self-Evolution & Context Maintenance

- "Do not assume a human will document your code patterns. If you build it, document it."
- Existing rules change -> update the relevant file in `.claude/rules/`.
- New domains/layers -> CREATE a new rule file in `.claude/rules/` (with flow-style `paths: [...]`, `description:`, `when_to_use:`, and inline `tags: [...]` frontmatter) AND APPEND its `@` import to `.claude/CLAUDE.md`'s Domain Rules section.
- Durable project facts (domain, architecture, integrations, glossary, external-doc pointers) -> CREATE or update a topic file in `.claude/knowledge/` and register it in `.claude/knowledge/INDEX.md`. Knowledge is descriptive; rules are prescriptive.
- Global changes -> update `.claude/CLAUDE.md` directly.
