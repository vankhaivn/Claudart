---
name: codex-learn
description: Run a Codex retrospective and promote recurring decisions into Codex guidelines and memory.
---

# Codex Learn

Run a Retrospective & Learning Protocol on the work you just completed.

Based on the "Agent Self-Evolution & Context Maintenance" section in `AGENTS.md`, perform this 3-phase protocol. Do not skip Phase 0. Without re-reading the active rules, you cannot reliably detect what was violated.

## Phase 0: Re-Ground in the Rule Set

Before any retrospective:

1. Read `AGENTS.md` in full.
2. Read every file in `.codex/guidelines/*.md` in full. Use `rg --files .codex/guidelines` first if you do not already know what exists.
3. Read every `.codex/agents/*.toml` file whose role or instructions mattered during this session.
4. Read every `.agents/skills/*/SKILL.md` file whose skill you used during this session.
5. Read `.codex/CONTEXT.md` to know the current shared state.
6. Build a short mental index: guideline name -> core constraint -> loophole keyword if any.

You cannot judge deviations against rules you have not re-read. If `.codex/guidelines/` is empty or missing, note that and continue with `AGENTS.md` only.

## Phase 1: Rule Refinement

Walk the conversation chronologically, comparing each assistant turn against the rule index from Phase 0.

1. List every moment the human corrected you or you deviated from a rule. For each one, answer: "What rationalization did I use to justify the deviation?" Do not just say "I missed the rule".
2. Did any rule fail because it only described the happy path without closing obvious loopholes?
3. For each identified gap, update the relevant guideline using this pattern: `NEVER do X, even when Y seems like a good reason`.
4. If rules contradict each other, resolve the contradiction immediately in `.codex/guidelines/` or `AGENTS.md`.
5. Save quiet confirmations. If the human accepted an unusual judgment call without pushback, record it when it should repeat in future sessions.

## Phase 2: New Knowledge Integration

1. Identify core bug root causes, architectural decisions, or design patterns validated in this session.
   - If subagents were used, identify delegation patterns that should repeat or be avoided: authorization wording, task decomposition, ownership boundaries, merge conflicts, validation gaps, and reviewer usefulness.
2. Pattern check via JOURNAL:
   - `.codex/JOURNAL.md` can grow to thousands of lines, so never full-read it.
   - Tail first: read only the last ~200 lines with `tail -n 200 .codex/JOURNAL.md`.
   - Search when targeted: if you suspect a recurring pattern, search for matching `decision` or `pivot` lines instead of loading the whole file.
   - If the same decision or pivot recurs 2+ times, surface it as a candidate to graduate into `.codex/guidelines/`.
   - Skip this step if `.codex/JOURNAL.md` does not exist or has fewer than 5 entries.
3. Decide where new knowledge belongs:
   - Existing domain with a strong match -> update the exact file in `.codex/guidelines/`.
   - Codex subagent/delegation behavior -> update `.codex/guidelines/agent-delegation.md` when it exists.
   - New domain with no strong match -> create a new guideline file in `.codex/guidelines/` with complete frontmatter, then reference it from `AGENTS.md`.
   - Global Codex standard -> update `AGENTS.md` directly.
   - Durable project *fact* (descriptive, not behavior — how a subsystem works, an integration detail, a domain term, a pointer to a doc in another folder) -> this is knowledge, not a guideline. Create or update a topic file in `.codex/knowledge/` (frontmatter `name`/`description`/`type`/`updated`; optional `sources`/`related`/`verify`) and register it in `.codex/knowledge/INDEX.md` in the same step. Guidelines prescribe behavior; knowledge describes facts. (Routine fact-capture is `$codex-checkpoint`'s job; `$codex-learn` writes knowledge only when a retrospective surfaces a durable fact checkpoint missed.)

Critical constraint: do not shoehorn a new concept into an existing guideline if the match is weaker than 80%. Prefer creating a new domain file over polluting a specific guideline.

## Boundary

`$codex-learn` updates rules, guidelines, `.codex/knowledge/`, skills, agents, and `AGENTS.md`.

It does not modify `.codex/CONTEXT.md`; checkpoint owns that file.

It does not rewrite `.codex/JOURNAL.md`; JOURNAL is append-only. You may read it as evidence using the token-efficient strategy above.

## Output Standard

- Rules must be verifiable from the codebase. If a reader cannot check whether the rule was followed, rewrite it.
- New or updated guideline files must include frontmatter with `paths:`, `description:`, `when_to_use:`, and `tags:`. Write `paths:` as a YAML flow sequence, e.g. `paths: ["src/**/*.ts", "test/**/*.ts"]`; never use block-list style. Write `tags:` as an inline YAML array on one line, e.g. `tags: [architecture, nestjs, boundaries]`; never use block-list style. Use 1-5 lowercase kebab-case tags that describe the domain or scope.
- Use `NEVER`, `YOU MUST`, or `IMPORTANT` for constraints that have been violated before.
- Do not paste long code snippets into guideline files. Cite source file paths and line numbers instead.
- Execute safe file changes autonomously, then summarize each file touched and why.
