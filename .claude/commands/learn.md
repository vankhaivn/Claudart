---
description: Force the Agent to self-learn and update Modular Rules after completing a task
---

Please execute a Learning Protocol on the work you just completed.

Based on the "Agent Self-Evolution & Context Maintenance" section in `CLAUDE.md`:

1. Identify the core bug root-cause, architectural decisions, or new design patterns used in this session.
2. Use Chain of Thought logically before updating files:
    - First, list all existing files in `.claude/rules/`.
    - Compare the new knowledge with the scope of these existing files.
    - CRITICAL CONSTRAINT: DO NOT shoehorn or force new concepts into an existing file if the match is less than 80%. It is strictly PREFERRED to create a new domain file rather than polluting existing specific rules.
    - Then, decide:
      => Existing domain (Perfect match) => Update the exact file in `.claude/rules/`.
      => New domain (No strong match) => Create a new `.md` file in `.claude/rules/` with proper YAML `paths: ["..."]` frontmatter and append the `@` import to `CLAUDE.md`.
      => Global standard (Applies universally) => Update root `CLAUDE.md`.
3. Write the rule concisely. If applicable, provide a short "Do not" and "Do" code block representing the standard.

Execute the file changes autonomously without asking for permission, and generate a brief summary of what memory was updated.
