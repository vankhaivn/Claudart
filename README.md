# CLAUDART

**CLAUDART** (Claude Architecture & Rules Toolkit) is an architectural solution and design pattern to optimize the memory and rules system for AI Agents in software projects, specifically tailored for Claude.

Instead of cramming all instructions and coding standards into a single `CLAUDE.md` file (which causes context overload), CLAUDART aims to build a **Modular Rules System** combined with an **Agent Self-Evolution** mechanism.

---

## Why optimize CLAUDE.md?

As a project scales, a monolithic `CLAUDE.md` file reveals several weaknesses:

- **Context Window Consumption:** The AI has to read all the rules, including parts irrelevant to the file being edited.
- **Hard to Maintain:** Developers can easily get lost when trying to update a specific small rule.
- **Decreased Accuracy:** The AI might confuse the logical flows of Frontend, Backend, Database, etc.

## Key Features

1. **Modular Rules System:** Breaks down `CLAUDE.md` into domain-specific rule files. For example: `db-rules.md`, `ui-components.md`.
2. **Context Path-Scoped:** Uses YAML frontmatter (`paths: [...]`) via Glob patterns to instruct the AI exactly when to apply rules based on spatial context.
3. **Agent Self-Evolution:** Clearly defines the AI's authority and responsibility to _automatically_ update, maintain, and generate new rule files when code structures change, instead of waiting for humans to write documentation.
4. **Lightweight Root Index:** Keeps the root `CLAUDE.md` clean and lightweight, retaining only the Project Overview, Core CLI Commands, and Semantic Links to sub-modules.

## Standard Directory Structure

The structure after applying CLAUDART will look like this:

```text
├── .claude/
│   └── rules/
│       ├── architecture.md    # Global architecture rules
│       ├── api-routers.md     # Rules for API/Controllers
│       ├── db-rules.md        # Rules for Database/ORMs
│       └── ui-components.md   # Rules for UI/Components
├── CLAUDE.md                  # Lightweight Root File (Root Index)
└── [Source code directories]
```

_Inside every rule file in `.claude/rules/`, always start with YAML frontmatter:_

```yaml
---
paths: ["src/models/**/*.py", "src/repositories/**/*.py"]
---
```

## Usage Guide

### Initial Setup

1. **Initialize Engine:** Start your workspace chat by running the `/init` command using the best capabilities/model you have available.
2. **Inject the Prompt:** Open `OPTIMIZE_CLAUDE.md`, copy its entire content, and paste it directly into your chat.
3. **Automated Restructuring:** The AI will then read your current structure, create the `.claude/rules/` directory, distribute your rules into distinct domains, and trim down your root `CLAUDE.md`.

### Continuous Learning (`/learn`)

To maintain the self-evolution mechanism, developers should proactively use the `/learn` command. Trigger this command manually after:

- Concluding a highly effective and productive chat session.
- The agent finishes fixing a tricky bug that might reoccur or contains a good lesson for the future.
- The agent finishes coding a new feature but forgets to update the long-term context (`CLAUDE.md` or files inside `.claude/rules/`).

## Self-Evolution Rule Structure

A crucial part of CLAUDART is adding the following commitment to `CLAUDE.md`:

> _"Do not assume a human will document your code patterns. If you build it, document it."_

- **Update existing rules:** Update the corresponding file in `.claude/rules/`.
- **Add new rules (New Domain):** Automatically create a new `.md` file with `paths:` frontmatter and add a semantic reference (`@`) into the root `CLAUDE.md`.
- **Global changes:** Update `CLAUDE.md` directly.

---

_Designed to optimize the capabilities of LLM Coding Agents._
