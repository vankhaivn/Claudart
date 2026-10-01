---
paths: ["**/*"]
description: Shared Git persistence policy for local commits, branch naming, commit identity, staging scope, and authority precedence.
when_to_use: Before staging, committing, creating or renaming branches, or when a workflow reaches a Git persistence boundary.
tags: [git, commits, branches, provenance]
---

# Git Workflow

CLAUDART provides a default for **local Git persistence**, not a competing authority layer. Higher-scope runtime/user instructions, repository-local Git rules, current user instructions, and tool-enforced restrictions remain authoritative.

## Resolve authority before the first Git write

1. Apply the active higher-scope Claude policy first. When available and relevant, include `~/.claude/CLAUDE.md`, `~/.claude/settings.json`, runtime permissions, hooks, and tool approval constraints in that decision. Do not weaken a tool-enforced or explicitly non-overridable restriction.
2. Apply repository-local Git instructions and conventions next. They own required branch shape, commit format, protected paths, review flow, and any stricter approval rule.
3. Apply the current user's explicit instruction for this work. A higher-scope rule such as "do not commit without explicit user approval" is satisfied only by an explicit user grant; silence is not approval. A current user denial always narrows CLAUDART's default.
4. If no applicable source prohibits local commits or requires another approval, **local commit is authorized by default** after a coherent in-scope unit is verified. No additional CLAUDART approval prompt is required.
5. Workflow-local settings may narrow this default. In particular, a spec with `commits: user` disables automatic commits for that spec. A workflow-local setting never widens permission above a higher-scope restriction.

If authority is unclear, keep the verified worktree intact and report the ambiguity instead of guessing.

## Commit verified coherent units

- Inspect `git status --short` and the relevant diff before staging.
- Commit only work owned by the current task plus necessary workflow-state updates that belong to the same boundary. Preserve unrelated and pre-existing changes.
- Stage explicit paths or owned hunks. Never use broad staging such as `git add -A` or `git add .` merely for convenience.
- If a file mixes owned and unrelated edits that cannot be separated safely, leave it unstaged and report the incomplete persistence.
- By default, commit only after the relevant verification passes. A known-failing/WIP snapshot requires an explicit user request.
- Direct/ad-hoc work may commit after its coherent verified outcome. A persistent task may commit verified implementation at its review-ready boundary. User-reviewed tasks still need user acceptance before closure/archive; agent-reviewed tasks may close from complete evidence under `task-management.md`. Neither path changes remote/history authority.
- Checkpoint and refactor-memory use this same policy for their verified in-scope changes. They do not define independent commit authorization.
- A spec follows its `commits:` cadence from `spec-workflow.md`, subject to this authority contract.

Follow the repository's commit-message convention. If none exists, use a concise imperative summary of the actual change.

## Keep history free of agent identity

Unless a higher-scope repository policy explicitly requires otherwise:

- Do not add AI/model/tool `Co-authored-by` trailers or invent co-authors.
- Do not add `Generated-by`, `Generated with`, `AI-generated`, model/vendor/tool signatures, or equivalent attribution in commit subjects, bodies, or trailers.
- Branch names describe the work, not the agent. Follow repository naming conventions; otherwise use a concise purpose-based name. Do not create agent/tool/vendor/model namespaces such as `codex/*`, `claude/*`, `agent/*`, or equivalent identity prefixes.

## Local commit is not remote/history authority

Permission to create a local commit does **not** authorize push, force-push, merge, rebase/history rewrite, tag creation, remote branch deletion, or Git configuration changes. Perform those only when separately authorized by applicable higher-scope/repository/user policy.

Subagents never gain Git-history authority merely from delegation. The parent integrates and verifies delegated work, then stages and commits it under this policy.
