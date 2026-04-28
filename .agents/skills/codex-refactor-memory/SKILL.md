---
name: codex-refactor-memory
description: Consolidate Codex project memory, guidelines, skills, and agents while preserving the shared CLAUDART memory core.
---

# Codex Refactor Memory

Use this skill as the Codex-native equivalent of Claude Code `/refactor-memory`.

Read `.codex/commands/refactor-memory.md` for the full Codex consolidation standards.

Apply the standards to:

- `AGENTS.md`
- `.codex/CODEX.md`
- `.codex/guidelines/*.md`
- `.codex/commands/*.md`
- `.codex/agents/*.toml`
- `.agents/skills/*/SKILL.md`

Do not move, duplicate, or rewrite `.claudart/CONTEXT.md` and `.claudart/JOURNAL.md` except where the checkpoint or learn protocols explicitly allow it.

In this CLAUDART base template, `.claude` and `.codex/.agents` are peer source templates. Do not use sync as a shortcut for this refactor.
