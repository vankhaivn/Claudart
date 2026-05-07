# CODEXART Project Memory

## Project Overview

CLAUDART keeps the Codex-specific operating layer inside `.codex/`, including session state. Codex should treat this file as the Codex-native project memory index.

## Core Commands

- `$project-discovery` interviews the user about a rough project idea and creates a raw synthesis plus structured project docs.
- `$codex-checkpoint` updates `.codex/CONTEXT.md` and appends meaningful retired items to `.codex/JOURNAL.md`.
- `$codex-learn` promotes validated recurring decisions into Codex guidelines.
- `$codex-doctor` runs a read-only health check.
- `$codex-refactor-memory` consolidates Codex memory, commands, skills, guidelines, and agents.

## Session State

Read `.codex/CONTEXT.md` at the start of meaningful work.
Do not auto-load `.codex/JOURNAL.md`; read it only for explicit history or learning tasks.

## Guidelines

See `.codex/guidelines/ai-behavior.md` for universal AI behavior guidelines.

## Agent Self-Evolution & Context Maintenance

- "Do not assume a human will document your code patterns. If you build it, document it."
- Existing Codex guidelines change -> update the relevant file in `.codex/guidelines/`.
- New domains/layers -> create a new guideline file and ensure `AGENTS.md` or `.codex/CODEX.md` points to it when globally relevant.
- Live state -> update `.codex/CONTEXT.md` through $codex-checkpoint.
