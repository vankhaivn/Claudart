# CLAUDART Project Memory

## Project Overview

CLAUDART keeps Claude adapter internals inside `.claude/` and shared project state inside `.claudart/`. This source template is installed as the downstream project's `CLAUDE.md`; keep project-specific loader content there and use `.claude/` for commands, agents, rules, references, and scripts.

## Core Commands

- `/start` orients a new session from `.claudart/CONTEXT.md`, task/spec indexes, the root knowledge router, and recent git history.
- `/plan <description>` creates a lightweight workspace at `.claudart/tasks/YYYY-MM-DD-NNN-<slug>/TASK.md` when work needs a persistent plan or the user explicitly requests one. Small, clear edits do not require a workspace; file count alone is not a trigger. Artifacts are created only for a concrete need.
- `/spec <mission>` creates a dated mission-scale spec workspace in `.claudart/specs/` — interview → POC artifact → decision-complete SPEC + ROADMAP, approved once as a standing approval.
- `/spec-run <slug>` executes an approved spec autonomously until final review — verifies acceptance, records ROADMAP task dispositions and evidence, blocks unchanged failure loops, and offers session rotation at phase boundaries.
- `/refactor-memory` consolidates the memory system and normalizes knowledge in place.
- `/project-docs` initializes, adopts, updates, audits, or retires current project documentation when `.claude/commands/project-docs.md` is installed. Discovery is a focused step when project intent remains unclear.
- `/checkpoint` rewrites current state, syncs task/spec indexes, appends meaningful history, and bulk-maintains eligible knowledge candidates.
- `/handoff` writes a single-slot session baton (`.claudart/HANDOFF.md`) distilling this session's reasoning state — run when the context window is nearly full or when pausing mid-investigation; the next `/start` consumes and deletes it. Never auto-load `HANDOFF.md`.
- `/learn` promotes validated recurring behavior into `.claude/rules/` and routes descriptive facts to their owners.
- `/doctor` runs the mechanical knowledge checker followed by a read-only semantic health audit.

Task bodies (`.claudart/tasks/*/TASK.md`) and artifacts are not auto-imported. Read the selected `TASK.md` on resume, then only supporting files needed for the next action.

## Domain Rules

`.claudart/` is the single project-state authority for Claude and Codex, including CONTEXT, JOURNAL, HANDOFF, knowledge, tasks and specs. Runtime choice changes execution tools and adapter instructions, not state ownership.

Read `.claudart/CONTEXT.md` and relevant indexes before meaningful work; current user instructions take precedence over saved state. Use repository-root paths even from a nested working directory. Task bodies and history remain on demand.

Keep scope, standing approvals, evidence and final-review gates when changing runtimes. The `agent` field records provenance; it neither selects a state store nor grants permission. Use the actual host's available tools and capabilities.

Shared files support sequential handoff, not automatic concurrent synchronization. Serialize writes to shared summaries, indexes and the handoff slot; preserve unrelated unresolved work. Do not create another state store or use a fallback store.

See @.claude/rules/ai-behavior.md for universal behavior. Imports resolve relative to the installed `CLAUDE.md`; reserve automatic imports for universally needed instructions.

Read these project-root paths only when their trigger applies. Conditional rules use command/reference scopes so reading startup indexes or metadata does not activate entire workflows:

- `.claude/rules/code-health.md` when implementing or reviewing code or code-adjacent artifacts; use relevant sections and required verification.
- `.claude/rules/task-management.md` when creating, executing, or resuming a persistent task.
- `.claude/rules/agent-delegation.md` when planning delegation or consuming worker results; use the current runtime's capabilities.
- `.claude/rules/spec-workflow.md` when authoring or executing a mission spec.
- `.claude/rules/knowledge-management.md` when retrieving project knowledge; also read `.claude/references/knowledge-maintenance.md` before knowledge writes, audits, or refactors.

Project knowledge: `.claudart/knowledge/INDEX.md` is the root router surfaced by `/start`; it and topic bodies are not auto-imported. Route entries on demand under the knowledge rule.
When the optional Project Docs command is present, use it for project-document ownership and lifecycle work. Core tasks still follow the repository's existing documentation convention when it is absent.

## Agent Self-Evolution & Context Maintenance

- "Do not assume a human will document your code patterns. If you build it, document it."
- Existing rules change -> update the relevant file in `.claude/rules/`.
- New domains/layers -> CREATE a new rule file in `.claude/rules/` (with flow-style `paths: [...]`, `description:`, `when_to_use:`, and inline `tags: [...]` frontmatter) and add a conditional route in this file's Domain Rules section. Use narrow paths for conditional rules; reserve `@` imports for universal guidance, with paths relative to this file.
- Durable descriptive facts that pass the knowledge rule -> find their owner first. Knowledge owns a fact only when no other authoritative source does; otherwise keep a pointer or minimal unique context. For a knowledge mutation, patch the topic and reachable map atomically, then run the checker. Mid-session natural-language updates are valid; `/checkpoint` is bulk maintenance, not the sole write gate.
- Global changes -> update `CLAUDE.md` directly.
