# Codex Learn Command

Run a Retrospective & Learning Protocol on the work you just completed.

Based on the "Agent Self-Evolution & Context Maintenance" section in `.codex/CODEX.md`, perform this 3-phase protocol. Do not skip Phase 0. Without re-reading the active rules, you cannot reliably detect what was violated.

## Phase 0: Re-Ground in the Rule Set

Before any retrospective:

1. Read `AGENTS.md` in full.
2. Read `.codex/CODEX.md` in full.
3. Read every file in `.codex/guidelines/*.md` in full. Use `rg --files .codex/guidelines` first if you do not already know what exists.
4. Read every `.codex/agents/*.toml` file whose role or instructions mattered during this session.
5. Read every `.agents/skills/*/SKILL.md` file whose skill you used during this session.
6. Read `.claudart/CONTEXT.md` to know the current shared state.
7. Build a short mental index: guideline name -> core constraint -> loophole keyword if any.

You cannot judge deviations against rules you have not re-read. If `.codex/guidelines/` is empty or missing, note that and continue with `AGENTS.md` and `.codex/CODEX.md` only.

## Phase 1: Rule Refinement

Walk the conversation chronologically, comparing each assistant turn against the rule index from Phase 0.

1. List every moment the human corrected you or you deviated from a rule. For each one, answer: "What rationalization did I use to justify the deviation?" Do not just say "I missed the rule".
2. Did any rule fail because it only described the happy path without closing obvious loopholes?
3. For each identified gap, update the relevant guideline using this pattern: `NEVER do X, even when Y seems like a good reason`.
4. If rules contradict each other, resolve the contradiction immediately in `.codex/guidelines/`, `.codex/CODEX.md`, or `AGENTS.md`.
5. Save quiet confirmations. If the human accepted an unusual judgment call without pushback, record it when it should repeat in future sessions.

## Phase 2: New Knowledge Integration

1. Identify core bug root causes, architectural decisions, or design patterns validated in this session.
2. Pattern check via JOURNAL:
   - `.claudart/JOURNAL.md` can grow to thousands of lines, so never full-read it.
   - Tail first: read only the last ~200 lines with `tail -n 200 .claudart/JOURNAL.md`.
   - Search when targeted: if you suspect a recurring pattern, search for matching `decision` or `pivot` lines instead of loading the whole file.
   - If the same decision or pivot recurs 2+ times, surface it as a candidate to graduate into `.codex/guidelines/`.
   - Skip this step if `.claudart/JOURNAL.md` does not exist or has fewer than 5 entries.
3. Decide where new knowledge belongs:
   - Existing domain with a strong match -> update the exact file in `.codex/guidelines/`.
   - New domain with no strong match -> create a new guideline file in `.codex/guidelines/` with proper `paths: [...]` and `description:` frontmatter, then reference it from `.codex/CODEX.md`.
   - Global Codex standard -> update `.codex/CODEX.md` or `AGENTS.md`.
   - Shared behavior that must also apply to Claude in this base repository -> update the matching `.claude/` file manually too. Do not use sync as the authoring shortcut for the base template.

Critical constraint: do not shoehorn a new concept into an existing guideline if the match is weaker than 80%. Prefer creating a new domain file over polluting a specific guideline.

## Boundary

`$codex-learn` updates rules, guidelines, skills, agents, `AGENTS.md`, and `.codex/CODEX.md`.

It does not modify `.claudart/CONTEXT.md`; checkpoint owns that file.

It does not rewrite `.claudart/JOURNAL.md`; JOURNAL is append-only. You may read it as evidence using the token-efficient strategy above.

In a downstream user project, after Codex-side learning you may ask whether to run `$sync claude` or have Claude run `/sync codex`. In this CLAUDART base repository, maintain both native sides manually.

## Output Standard

- Rules must be verifiable from the codebase. If a reader cannot check whether the rule was followed, rewrite it.
- Use `NEVER`, `YOU MUST`, or `IMPORTANT` for constraints that have been violated before.
- Do not paste long code snippets into guideline files. Cite source file paths and line numbers instead.
- Execute safe file changes autonomously, then summarize each file touched and why.
