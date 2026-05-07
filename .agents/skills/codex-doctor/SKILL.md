---
name: codex-doctor
description: Run a read-only health check for the Codex installation.
---

# Codex Doctor

Use this skill as the Codex-native equivalent of Claude Code `/doctor`.

Read `.codex/commands/doctor.md`, then report health for:

- Codex session files: `.codex/CONTEXT.md`, `.codex/JOURNAL.md`
- Codex config: `.codex/CODEX.md`, `.codex/guidelines/`, `.codex/commands/`, `.codex/agents/`
- Codex repo skills: `.agents/skills/`
- Root `AGENTS.md` (copied from `.codex/AGENTS.md` by installer)

This skill is diagnostic only. Do not modify files.
