# CLAUDART Codex Instructions

This repository contains CLAUDART, a markdown-based operating layer for AI coding agents.

## Context Loading

- Read `.codex/CODEX.md` for Codex-specific project memory.
- Read `.codex/CONTEXT.md` for current session state before meaningful work.
- Read `.codex/guidelines/*.md` for project behavior guidelines.
- Do not auto-load `.codex/JOURNAL.md`; use it only for explicit history or learning tasks.

## Working Style

- Keep changes scoped to the user request.
- Prefer repository-local patterns over new abstractions.
- Report stale or conflicting AI-layer files instead of silently overwriting manual work.
