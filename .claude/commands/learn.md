---
description: Force the Agent to reflect on rules and self-learn after completing a task
---

Please execute a Retrospective & Learning Protocol on the work you just completed.

Based on the "Agent Self-Evolution & Context Maintenance" section in `CLAUDE.md`, you must perform a 2-step protocol:

**Phase 1: Rule Refinement (Retrospective)**

1. List every moment the human corrected you or you deviated from a rule. For each one, answer: _"What rationalization did I use to justify the deviation?"_ — do not just say "I missed the rule".
2. Did any rule fail because it only described the happy path without closing obvious loopholes?
3. For each identified gap, update the rule using this pattern: `NEVER do X, even when Y seems like a good reason` — explicitly name the rationalization so future runs cannot reuse it.
4. If rules contradict each other, resolve the contradiction immediately in `.claude/rules/` or `CLAUDE.md`.

**Phase 2: New Knowledge Integration (Self-Evolution)**

1. Identify any core bug root-causes, architectural decisions, or new design patterns successfully validated in this session.
2. Use Chain of Thought logically before updating files:
    - First, list all existing files in `.claude/rules/`.
    - Compare the new knowledge with the scope of these existing files.
    - CRITICAL CONSTRAINT: DO NOT shoehorn or force new concepts into an existing file if the match is less than 80%. It is strictly PREFERRED to create a new domain file rather than polluting existing specific rules.
    - Then, decide:
      => Existing domain (Perfect match) => Update the exact file in `.claude/rules/`.
      => New domain (No strong match) => Create a new `.md` file in `.claude/rules/` with proper YAML `paths: ["..."]` frontmatter and append the `@` import to `CLAUDE.md`.
      => Global standard (Applies universally) => Update root `CLAUDE.md`.

**Output Standard:**

- Rules must be **verifiable**: a reader must be able to check whether the rule was followed by reading the code. If you cannot verify it, rewrite it.
- Use `NEVER`, `YOU MUST`, or `IMPORTANT` emphasis for rules that have been violated before — this signals priority to future runs.
- **NO CODE SNIPPETS** in rule files. Reference the source file and line (e.g., `src/services/foo.ts:45`) so context never goes stale. Code in rule files rots.
- Execute file changes autonomously without asking for permission, then generate a brief summary of what was updated and why.
