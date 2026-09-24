# CLAUDART Codex Instructions

This repository contains CLAUDART, a markdown-based operating layer for AI coding agents. Treat `AGENTS.md` as the Codex-native project memory index.

## Context Loading

- `.claudart/` is the single project-state authority for Claude and Codex, including CONTEXT, JOURNAL, HANDOFF, knowledge, tasks and specs. Runtime choice changes execution tools and adapter instructions, not state ownership.
- Read `.claudart/CONTEXT.md` and relevant indexes before meaningful work; current user instructions take precedence over saved state. Use repository-root paths even from a nested working directory.
- Keep scope, standing approvals, evidence and final-review gates when changing runtimes. The `agent` field records provenance; it neither selects a state store nor grants permission. Use the actual host's available tools and capabilities.
- Shared files support sequential handoff, not automatic concurrent synchronization. Serialize writes to shared summaries, indexes and the handoff slot; preserve unrelated unresolved work. Do not create another state store or use a fallback store.
- Read `.claudart/tasks/index.md` (if it exists) for active implementation plans.
- Read `.codex/guidelines/ai-behavior.md`, then load only the additional guideline files relevant to the current task. Do not read every guideline blindly.
- Read `.codex/guidelines/knowledge-management.md` when retrieving project knowledge. For knowledge writes, audits, or refactors, also follow `.codex/references/knowledge-maintenance.md`; retrieval alone does not require it.
- Do not auto-load `.claudart/JOURNAL.md`; use it only for explicit history or learning tasks.
- Do not auto-load `.claudart/HANDOFF.md`; it is a one-shot session baton consumed by `$codex-start`.
- Do not auto-load `.claudart/tasks/*/TASK.md` bodies or task artifacts. Read the selected `TASK.md` when resuming or working on it, then only supporting files needed for the next action.

## Core Commands

- `$codex-start` — orients a new session from current state, task/spec indexes, the root knowledge map only, and recent Git history; it never runs the knowledge checker.
- `$codex-plan <description>` — creates a lightweight workspace at `.claudart/tasks/YYYY-MM-DD-NNN-<slug>/TASK.md` when work needs a persistent plan or the user explicitly requests one. Small, clear edits do not require a workspace; file count alone is not a trigger. Artifacts are created only for a concrete need.
- `$codex-spec <mission>` — creates a mission-scale spec workspace in `.claudart/specs/` — interview → POC artifact → decision-complete SPEC + ROADMAP, approved once as a standing approval.
- `$codex-spec-run <slug>` — executes an approved spec autonomously until final review — verifies acceptance, records ROADMAP task dispositions and evidence, blocks unchanged failure loops, and offers session rotation at phase boundaries.
- `$codex-project-docs` — when `.agents/skills/codex-project-docs/SKILL.md` is installed, initializes, adopts, updates, audits, or retires current project documentation. Discovery is a focused step when project intent remains unclear.
- `$codex-checkpoint` — bulk-maintains current state, task/spec indexes, JOURNAL, and eligible durable knowledge; it is not the only knowledge write gate.
- `$codex-handoff` — writes a single-slot session baton (`.claudart/HANDOFF.md`) distilling the session's reasoning state when the context window is nearly full or an investigation pauses mid-flight; the next `$codex-start` consumes and deletes it.
- `$codex-learn` — promotes validated recurring behavior into Codex guidelines and routes descriptive facts to their owners.
- `$codex-doctor` — runs the read-only mechanical checker plus semantic health audit.
- `$codex-refactor-memory` — consolidates Codex memory and performs controlled, in-place knowledge normalization.

## Working Style

- Keep changes scoped to the user request.
- Prefer repository-local patterns over new abstractions.
- Report stale or conflicting AI-layer files instead of silently overwriting manual work.

## Guidelines

See `.codex/guidelines/ai-behavior.md` for universal AI behavior guidelines.
See `.codex/guidelines/code-health.md` for the continuous, behavior-preserving implementation baseline when implementing or reviewing code or code-adjacent artifacts; read the sections relevant to the change and its verification.
See `.codex/guidelines/task-management.md` for the lightweight task-workspace workflow that replaces session-only plan mode.
See `.codex/guidelines/agent-delegation.md` for Codex subagent and parallel delegation protocol. Trust the harness on whether to delegate; the guideline supplies the how — decomposition, self-contained worker prompts, anti-shadow-run discipline, and persisting delegated findings.
See `.codex/guidelines/spec-workflow.md` for mission-scale spec workspaces in `.claudart/specs/` — the loop-engineering layer above tasks, executed autonomously by `$codex-spec-run` under a standing approval.
See `.codex/guidelines/knowledge-management.md` for bounded retrieval and classification. Its maintenance reference supplies conditional capture, schema, lifecycle, and validation rules; load it under the triggers in Context Loading.
Project knowledge: `.claudart/knowledge/INDEX.md` is the root router surfaced by `$codex-start`; topic bodies are read on demand.
When the optional Project Docs skill is present, use it for project-document ownership and lifecycle work. Core tasks still follow the repository's existing documentation convention when it is absent.

## Knowledge Contract

- Map first: stay within 2 maps, 3 direct topics, and 2 one-hop related topics; inspect frontmatter, outline, and the smallest relevant section before a full body. Use bounded `rg`/Git evidence search only when routed context is insufficient; reading never writes.
- Capture only facts that are descriptive, durable beyond current work, current, and evidenced; scope may be narrow. WIP/proposals/state stay in task/spec/CONTEXT, behavior goes through `$codex-learn`, and uncertainty remains a candidate or `review-needed`.
- Find the owner of each fact first. Knowledge owns it only when no other authoritative source does; otherwise keep a pointer or minimal unique context. For a knowledge mutation, update the topic plus its reachable map atomically. Never auto-delete or auto-promote ambiguous unindexed files.
- After every knowledge mutation, run `bash .codex/scripts/knowledge-check.sh --root .`. `$codex-start` never runs it.

## Agent Self-Evolution & Context Maintenance

- "Do not assume a human will document your code patterns. If you build it, document it."
- Existing Codex guidelines change → update the relevant file in `.codex/guidelines/`.
- New domains/layers → create a new guideline file with flow-style `paths: [...]`, `description:`, `when_to_use:`, and inline `tags: [...]` frontmatter, then ensure `AGENTS.md` points to it when globally relevant.
- Durable project facts → follow the four-invariant Knowledge Contract and its conditional maintenance reference; a natural-language mid-session update is sufficient when the capture gate passes. Keep one owner per fact across project docs, source references, and knowledge.
- Live state → update `.claudart/CONTEXT.md` through `$codex-checkpoint`.
