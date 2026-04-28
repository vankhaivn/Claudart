---
name: sync
description: Sync CLAUDART configuration from the named source side into the active Codex side. Use when the user says "$sync claude" or asks Codex to update from Claude Code.
---

# Sync

Run the Codex sync workflow.

## Usage

```text
$sync claude
```

## Instructions

1. Read `.claudart/sync-map.md`.
2. Read `.codex/commands/sync.md`.
3. Treat the argument after `$sync` as the source side.
4. For `$sync claude`, read the current filesystem snapshot from `.claude/` and update the Codex side.
5. Do not use `git diff`, commit history, or session history to infer changes.
6. Do not copy, convert, or duplicate `.claudart/CONTEXT.md` or `.claudart/JOURNAL.md`.
7. Follow the conflict policy in `.claudart/sync-map.md`.
8. Run the verification checks listed in `.codex/commands/sync.md`.
9. On the first migration from a Claude-only project, do not mistake freshly copied Codex scaffold files for protected manual targets. If they are still generic CLAUDART template content, treat them as bootstrap scaffolding and overwrite them.

This skill is for downstream user projects after CLAUDART is installed. In the CLAUDART base template itself, do not use sync to author `.codex` from `.claude`; maintain both native sides manually.
