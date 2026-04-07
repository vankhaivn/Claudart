Please analyze the existing `CLAUDE.md` file in this repository and refactor it to follow the "Modular Rules System" best practices. Our goal is to keep the root `CLAUDE.md` as a lightweight index and extract domain-specific context into path-scoped rules inside the `.claude/rules/` directory.

Please execute the following steps systematically without losing any existing rules:

1. **Analyze the Tech Stack & Architecture**:
   Determine the main framework and language used (e.g., FastAPI, Next.js, Golang, React, etc.) based on `CLAUDE.md` and the project structure. Identify the core logical layers (e.g., Database/Models/Repositories, API/Controllers/Routers, UI/Components, Core/Utils).

2. **Create the Rules Directory**:
   Create `.claude/rules/` if it doesn't already exist.

3. **Extract Domain-Specific Rules**:
   Group the detailed coding rules, boundaries, and validation requirements from `CLAUDE.md` into 2-4 logical domains based on the detected project type. For each domain, create a markdown file in `.claude/rules/` (e.g., `db-rules.md`, `api-routers.md`, `ui-components.md`, `architecture.md`).

    IMPORTANT FORMATTING RULE: Every rule file MUST start with a YAML frontmatter specifying the target paths using the correct JSON array format (to prevent VSCode YAML lint errors). Select glob patterns dynamically to match the project's folder structure. Example format:

    ```yaml
    ---
    paths: ["src/models/**/*.py", "src/repositories/**/*.py"]
    ---
    ```

4. **Refactor the Root `CLAUDE.md`**:
   Truncate the original `CLAUDE.md` so it ONLY contains: Project Overview, Core CLI Commands, Path Aliases, Global Naming Conventions, and Global Lint/Formatting Rules. Remove all domain-specific logic.

5. **Cross-Link the Rules**:
   At the bottom of the newly trimmed `CLAUDE.md` (under a "Domain Rules" heading), add semantic imports for all the newly created rule files. Example:
   See @.claude/rules/architecture.md for global architecture boundaries.
   See @.claude/rules/db-rules.md for database and ORM rules.

6. **Add "Agent Self-Evolution" Guidelines**:
   At the very end of the root `CLAUDE.md`, you MUST APPEND a section titled "## Agent Self-Evolution & Context Maintenance". This section must explicitly grant you (the AI agent) the authority and responsibility to autonomously update memory files. It MUST include a table or bullet points stating:
    - "Do not assume a human will document your code patterns. If you build it, document it."
    - Action for existing rules change: Update the relevant file in `.claude/rules/`
    - Action for completely NEW domains/layers: CREATE a new rule file in `.claude/rules/` (using the same `paths: [...]` array frontmatter) AND APPEND its `@` import to the Domain Rules section of `CLAUDE.md`.
    - Action for global changes: Update `CLAUDE.md` directly.

Please confirm when you've successfully analyzed the stack, created the files, formatted paths correctly, and injected the Self-Evolution guidelines into `CLAUDE.md`!
