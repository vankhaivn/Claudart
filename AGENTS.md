# CLAUDART Codex Instructions

This repository contains CLAUDART, a markdown-based operating layer for AI coding agents.

## Context Loading

- Read `.codex/CODEX.md` for Codex-specific project memory.
- Read `.claudart/CONTEXT.md` for current session state before meaningful work.
- Read `.codex/guidelines/*.md` for project behavior guidelines.
- Do not auto-load `.claudart/JOURNAL.md`; use it only for explicit history or learning tasks.

## Sync Workflow

- Use `$sync claude` when Claude Code was the last active side and Codex should update from `.claude/`.
- Use `.claudart/sync-map.md` as the sync contract.
- Do not duplicate `.claudart/CONTEXT.md` or `.claudart/JOURNAL.md` into `.codex/` or `.claude/`.
- In this CLAUDART base template, do not use sync to generate `.codex` from `.claude`. Maintain both native templates manually.

## Working Style

- Keep changes scoped to the user request.
- Prefer repository-local patterns over new abstractions.
- Report stale or conflicting AI-layer files instead of silently overwriting manual work.
