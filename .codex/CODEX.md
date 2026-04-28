# CODEXART Project Memory

## Project Overview

CLAUDART keeps shared session state in `.claudart/` and tool-specific operating layers in `.claude/` and `.codex/`. Codex should treat this file as the Codex-native project memory index.

## Core Commands

- `$sync claude` reads the current Claude snapshot and updates the Codex side.
- `$codex-checkpoint` updates `.claudart/CONTEXT.md` and appends meaningful retired items to `.claudart/JOURNAL.md`.
- `$codex-learn` promotes validated recurring decisions into Codex guidelines.
- `$codex-doctor` runs a read-only health check.
- `$codex-refactor-memory` consolidates Codex memory, commands, skills, guidelines, and agents.

## Shared State

Read `.claudart/CONTEXT.md` at the start of meaningful work.
Do not auto-load `.claudart/JOURNAL.md`; read it only for explicit history or learning tasks.

## Guidelines

See `.codex/guidelines/ai-behavior.md` for universal AI behavior guidelines.
See `.claudart/sync-map.md` before running any sync workflow.

## Base Template Maintenance

This repository is the CLAUDART base template. Maintain `.claude` and `.codex/.agents` manually as peer source templates. Sync is for downstream user projects after installation, not for authoring this template.

## Agent Self-Evolution & Context Maintenance

- "Do not assume a human will document your code patterns. If you build it, document it."
- Existing Codex guidelines change -> update the relevant file in `.codex/guidelines/`.
- New domains/layers -> create a new guideline file and ensure `AGENTS.md` or `.codex/CODEX.md` points to it when globally relevant.
- Shared live state -> update `.claudart/CONTEXT.md` through checkpoint, not through sync.
