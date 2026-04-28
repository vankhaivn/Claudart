---
name: codex-doctor
description: Run a read-only health check for the shared CLAUDART/Codex installation.
---

# Codex Doctor

Use this skill as the Codex-native equivalent of Claude Code `/doctor`.

Read `.codex/commands/doctor.md`, then report health for:

- Shared memory files in `.claudart/`
- Claude files in `.claude/`
- Codex files in `.codex/`
- Codex repo skills in `.agents/skills/`
- Root `AGENTS.md`

This skill is diagnostic only. Do not modify files.
