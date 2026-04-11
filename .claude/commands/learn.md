---
description: Force the Agent to reflect on rules and self-learn after completing a task
---

Please execute a Retrospective & Learning Protocol on the work you just completed.

Based on the "Agent Self-Evolution & Context Maintenance" section in `CLAUDE.md`, you must perform a 2-step protocol:

**Phase 1: Rule Refinement (Retrospective)**
1. Did you violate any rules, or require human intervention/corrections during this session?
2. Did you encounter any contradictory statements within `.claude/rules/` vs `CLAUDE.md`, or interpret existing rules too literally/incorrectly?
3. If yes to either, structurally list the root causes of the misinterpretation.
4. If the existing rules are contradictory or misleading, immediately fix those existing rules in `.claude/rules/` or `CLAUDE.md` to prevent future bias.

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
- Write rules concisely. Treat them as rigid constraints.
- If applicable, provide a short "Do not" and "Do" code block representing the standard.
- Execute the file changes autonomously without asking for permission, and generate a brief summary of what memory and rules were updated.
