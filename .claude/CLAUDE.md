# CLAUDART Project Memory

## Project Overview

CLAUDART keeps the Claude-specific operating layer inside `.claude/`, including session state. If Claude Code `/init` generates a root `CLAUDE.md`, copy its useful project-specific content into this file before running `/refactor-memory`.

## Core Commands

- `/start` orients a new session from `.claude/CONTEXT.md`, task/spec indexes, the root knowledge router, and recent git history.
- `/plan <description>` creates a persistent implementation plan in `.claude/tasks/` — use instead of native plan mode for any multi-session or multi-file work.
- `/spec <mission>` creates a dated mission-scale spec workspace in `.claude/specs/` — interview → POC artifact → decision-complete SPEC + ROADMAP, approved once as a standing approval.
- `/spec-run <slug>` executes an approved spec autonomously until final review — verifies acceptance, records ROADMAP task dispositions and evidence, blocks unchanged failure loops, and offers session rotation at phase boundaries.
- `/refactor-memory` consolidates the memory system and normalizes knowledge in place.
- `/project-discovery` interviews the user about a rough project idea and creates a raw synthesis plus structured project docs.
- `/checkpoint` rewrites current state, syncs task/spec indexes, appends meaningful history, and bulk-maintains eligible knowledge candidates.
- `/handoff` writes a single-slot session baton (`.claude/HANDOFF.md`) distilling this session's reasoning state — run when the context window is nearly full or when pausing mid-investigation; the next `/start` consumes and deletes it. Never auto-load `HANDOFF.md`.
- `/learn` promotes validated recurring behavior into `.claude/rules/` and routes descriptive facts to knowledge.
- `/doctor` runs the mechanical knowledge checker followed by a read-only semantic health audit.

## Domain Rules

See @.claude/CONTEXT.md for the current state of work (updated by /checkpoint).
See @.claude/rules/ai-behavior.md for universal AI behavior guidelines.
See @.claude/rules/task-management.md for the persistent task-document workflow that replaces native plan mode.
See @.claude/rules/agent-delegation.md for how to delegate well to subagents (decomposition, worker prompts, anti-shadow-run, persistence) — the harness decides _whether_ to delegate; the rule adds the project's _how_.
See @.claude/rules/spec-workflow.md for dated mission-scale spec workspaces in `.claude/specs/` with `done/` archives — the loop-engineering layer above tasks, executed autonomously by /spec-run under a standing approval.
See @.claude/rules/knowledge-management.md for the always-available knowledge routing, capture, schema, and validation contract.

Project knowledge: `.claude/knowledge/INDEX.md` is the root router surfaced by `/start`; it and topic bodies are not auto-imported. Route entries on demand under the knowledge rule.

## Agent Self-Evolution & Context Maintenance

- "Do not assume a human will document your code patterns. If you build it, document it."
- Existing rules change -> update the relevant file in `.claude/rules/`.
- New domains/layers -> CREATE a new rule file in `.claude/rules/` (with flow-style `paths: [...]`, `description:`, `when_to_use:`, and inline `tags: [...]` frontmatter) AND APPEND its `@` import to `.claude/CLAUDE.md`'s Domain Rules section.
- Durable descriptive facts that pass the knowledge rule -> patch the canonical topic and reachable map atomically, then run the knowledge checker. Mid-session natural-language updates are valid; `/checkpoint` is bulk maintenance, not the sole write gate.
- Global changes -> update `.claude/CLAUDE.md` directly.
