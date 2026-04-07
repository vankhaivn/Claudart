---
description: Auto-refactor CLAUDE.md into a Modular Rules System using Best Practices
---

Please analyze the existing `CLAUDE.md` file (if any) in this repository and refactor it to follow the "Modular Rules System" best practices. Our goal is to keep the root `CLAUDE.md` strictly as a lightweight index (ideally < 100 lines) and extract domain-specific context into path-scoped rules inside the `.claude/rules/` directory.

Please execute the following steps systematically without losing any essential project context:

1. **Analyze the Tech Stack & Architecture**:
   Determine the main framework and language used based on `CLAUDE.md` and the project structure. Identify the core logical layers (e.g., Database/Repositories, API/Controllers, UI/Components).

2. **Create the Rules Directory**:
   Create `.claude/rules/` if it doesn't already exist.

3. **Extract Domain-Specific Rules**:
   Group the detailed coding rules, boundaries, and validation requirements from `CLAUDE.md` into 2-4 logical domains logically based on the project type. For each domain, create a markdown file in `.claude/rules/` (e.g., `db-rules.md`, `api-routers.md`).
    - IMPORTANT YAML RULE: Every rule file MUST start with a YAML frontmatter specifying target paths to prevent VSCode YAML lint errors. Example:
        ```yaml
        ---
        paths: ["src/models/**/*.py", "src/repositories/**/*.py"]
        ---
        ```
    - **NO CODE SNIPPETS RULE: Do NOT copy-paste code blocks into these rule files. Instead, use file and line references (e.g., `See src/core/db.ts:45 for the database connection pattern`) so the context never gets outdated.**

4. **Refactor the Root `CLAUDE.md`**:
   Truncate the original `CLAUDE.md` so it ONLY contains: Project Overview, Core CLI Commands, Path Aliases, and Global Naming Conventions.
    - **CRITICAL: PURGE all domain-specific logic AND style/formatting rules (delegate styling to standard tools like Prettier/Eslint/Ruff). Do not keep redundant info already available in `package.json` or `README.md`. Less is more.**

5. **Cross-Link the Rules**:
   At the bottom of the newly trimmed `CLAUDE.md` (under a "Domain Rules" heading), add semantic imports for all newly created rule files. Example:
   See @.claude/rules/architecture.md for global boundaries.
   See @.claude/rules/db-rules.md for database patterns.

6. **Add "Agent Self-Evolution" Guidelines**:
   At the very end of the root `CLAUDE.md`, you MUST APPEND a section titled "## Agent Self-Evolution & Context Maintenance". This section must explicitly grant you the authority to autonomously update memory. Include these exact rules:
    - "Do not assume a human will document your code patterns. If you build it, document it."
    - Existing rules change: Update the relevant file in `.claude/rules/`.
    - NEW domains/layers: CREATE a new rule file in `.claude/rules/` (with `paths: [...]` frontmatter) AND APPEND its `@` import to `CLAUDE.md`'s Domain Rules section.
    - Global changes: Update `CLAUDE.md` directly.

Please confirm when you've successfully analyzed the stack, enforced the No Code Snippets rule, and injected the Self-Evolution guidelines!
