# CLAUDART Codex Instructions

This repository contains CLAUDART, a markdown-based operating layer for AI coding agents. Treat `AGENTS.md` as the Codex-native project memory index.

## Context Loading

- Read `.codex/CONTEXT.md` for current session state before meaningful work.
- Read `.codex/guidelines/*.md` for project behavior guidelines.
- Do not auto-load `.codex/JOURNAL.md`; use it only for explicit history or learning tasks.

## Core Commands

- `$project-discovery` — interviews the user about a rough project idea and creates a raw synthesis plus structured project docs.
- `$codex-checkpoint` — updates `.codex/CONTEXT.md` and appends meaningful retired items to `.codex/JOURNAL.md`.
- `$codex-learn` — promotes validated recurring decisions into Codex guidelines.
- `$codex-doctor` — runs a read-only health check.
- `$codex-refactor-memory` — consolidates Codex memory, commands, skills, guidelines, and agents.

## Working Style

- Keep changes scoped to the user request.
- Prefer repository-local patterns over new abstractions.
- Report stale or conflicting AI-layer files instead of silently overwriting manual work.

## Guidelines

See `.codex/guidelines/ai-behavior.md` for universal AI behavior guidelines.

## Agent Self-Evolution & Context Maintenance

- "Do not assume a human will document your code patterns. If you build it, document it."
- Existing Codex guidelines change → update the relevant file in `.codex/guidelines/`.
- New domains/layers → create a new guideline file and ensure `AGENTS.md` points to it when globally relevant.
- Live state → update `.codex/CONTEXT.md` through `$codex-checkpoint`.
