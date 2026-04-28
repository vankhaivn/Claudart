---
description: Force the Agent to reflect on rules and self-learn after completing a task
---

Please execute a Retrospective & Learning Protocol on the work you just completed.

Based on the "Agent Self-Evolution & Context Maintenance" section in `.claude/CLAUDE.md`, you must perform a 3-phase protocol. **Do not skip Phase 0** — without re-reading the rules, you cannot reliably detect what was violated.

## Phase 0: Re-Ground in the Rule Set (MANDATORY first step)

Before any retrospective:

1. Read `.claude/CLAUDE.md` in full.
2. Read every file in `.claude/rules/*.md` in full (use Glob first if you don't already know what exists).
3. Read every file in `.claude/agents/*.md` whose tools you used during this session.
4. Read `.claude/CONTEXT.md` to know what state the work was in when this session started.
5. Build a short mental index: rule name → core constraint → loophole keyword (if any).

You cannot judge deviations against rules you haven't re-read. If `.claude/rules/` is empty or missing, note that and continue with `.claude/CLAUDE.md` only.

## Phase 1: Rule Refinement (Retrospective)

Walk the conversation chronologically, comparing each assistant turn against the rule index from Phase 0.

1. List every moment the human corrected you OR you deviated from a rule. For each one, answer: *"What rationalization did I use to justify the deviation?"* — do not just say "I missed the rule".
2. Did any rule fail because it only described the happy path without closing obvious loopholes?
3. For each identified gap, update the rule using this pattern: `NEVER do X, even when Y seems like a good reason` — explicitly name the rationalization so future runs cannot reuse it.
4. If rules contradict each other, resolve the contradiction immediately in `.claude/rules/` or `.claude/CLAUDE.md`.
5. Also save quiet *confirmations*: if the human accepted an unusual judgment call without pushback, that's a validated approach — record it so you don't drift away from it next time.

## Phase 2: New Knowledge Integration (Self-Evolution)

1. Identify any core bug root-causes, architectural decisions, or new design patterns successfully validated in this session.
2. **Pattern check via JOURNAL** — `.claude/JOURNAL.md` can grow to thousands of lines, so NEVER full-read it. Use this token-efficient strategy:
    - **Tail first**: read only the last ~200 lines via `tail -n 200 .claude/JOURNAL.md` (Bash) or `Read` with an `offset` near EOF.
    - **Grep when targeted**: if you suspect a specific pattern is recurring, use `grep '| decision |' .claude/JOURNAL.md` (or `pivot`) to surface only matching lines without loading the rest.
    - Look for the same `decision` or `pivot` recurring 2+ times in what you read. A repeating decision is a strong signal that the underlying principle should graduate from CONTEXT/JOURNAL into `.claude/rules/`. Surface these candidates explicitly.
    - Skip this step entirely if `.claude/JOURNAL.md` doesn't exist or has fewer than 5 entries.
3. Use Chain of Thought before updating files:
    - First, list all existing files in `.claude/rules/` (already done in Phase 0).
    - Compare the new knowledge with the scope of these existing files.
    - **CRITICAL CONSTRAINT**: DO NOT shoehorn or force new concepts into an existing file if the match is less than 80%. It is strictly PREFERRED to create a new domain file rather than polluting existing specific rules.
    - Then, decide:
      - Existing domain (perfect match) → Update the exact file in `.claude/rules/`.
      - New domain (no strong match) → Create a new `.md` file in `.claude/rules/` with proper YAML `paths: [...]` frontmatter and append the `@` import to `.claude/CLAUDE.md`.
      - Global standard (applies universally) → Update `.claude/CLAUDE.md` (or `.claude/rules/ai-behavior.md` if it's a behavioral rather than structural rule).

**Boundary**: `/learn` updates **rules and `.claude/CLAUDE.md` only**. Do NOT modify `.claude/CONTEXT.md` (that's `/checkpoint`'s job) and do NOT rewrite `.claude/JOURNAL.md` entries (it's append-only). You may *read* both as evidence.

## Output Standard

- Rules must be **verifiable**: a reader must be able to check whether the rule was followed by reading the code. If you cannot verify it, rewrite it.
- Use `NEVER`, `YOU MUST`, or `IMPORTANT` emphasis for rules that have been violated before — this signals priority to future runs.
- **NO CODE SNIPPETS** in rule files. Reference the source file and line (e.g., `src/services/foo.ts:45`) so context never goes stale. Code in rule files rots.
- Execute file changes autonomously without asking for permission, then generate a brief summary listing each file touched and the reason.
