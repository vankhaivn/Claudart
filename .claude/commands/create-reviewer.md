---
description: Automatically generate a highly customized Code Review subagent and compare it with the existing one
---

Please analyze the current project structure, tech stack, and any existing rules in `CLAUDE.md` or `.claude/rules/` to generate a highly optimized, project-specific Code Review Subagent.

Our goal is to create a fresh, modern Claude Code subagent that deeply understands the exact frameworks, linters, and architectural boundaries of this repository, and enforces them proactively.

Please execute the following steps systematically:

1. **Analyze Project Context**:
    - Detect the core programming languages, frameworks, and testing libraries used in this workspace.
    - Identify any existing style guides, security rules, or architectural patterns currently documented in `CLAUDE.md` or configuration files (e.g., eslint, ruff, pyproject.toml).

2. **Draft the Fresh Subagent (Do not let existing files constrain you)**:
   Draft the content for a conceptually NEW `.claude/agents/code-reviewer.md` file using modern subagent best practices.

    **A. YAML Frontmatter Requirements:**
    The draft MUST strictly start with this YAML block. The word "PROACTIVELY" is critical to ensure automatic delegation.

    ```yaml
    ---
    name: code-reviewer
    description: Expert code review specialist tailored for [Detected Stack]. Use PROACTIVELY after writing or modifying code to ensure quality, security, and project-specific standards.
    tools: Read, Grep, Glob, Bash
    model: inherit
    ---
    ```

    **B. System Prompt Content Requirements:**
    - **Role Definition**: "You are a senior code reviewer ensuring high standards of code quality, security, and performance for a [Detected Tech Stack] project."
    - **Trigger Routine**: "When invoked: 1. Run `git diff` or `git status` to identify recent changes. 2. Read the modified files to gather context."
    - **Project-Specific Review Priorities**: List 4-5 prioritized review areas injected with the specific patterns you found in Step 1 (e.g., specific framework anti-patterns, lint rule enforcements).
    - **Strict Output Format**: Force the reporting of issues into Actionable chunks: Severity, Category, Location, Description, Suggested Fix (implementable code block), and Impact.

3. **Compare & Propose (Hold execution)**:
    - Check if `.claude/agents/code-reviewer.md` currently exists in the workspace.
    - If it **DOES exist**: Read the current file. Present a clear, bulleted summary of the differences and the specific improvements/advantages your newly drafted version has over the old/outdated one.
    - If it **DOES NOT exist**: Simply present a summary of the powerful capabilities the new reviewer will have.
    - Show a quick preview/snippet of the most important custom rules you wrote in Step 2.

4. **Ask for User Approval**:
   DO NOT create or overwrite the file yet. End your response by asking the user: _"Would you like me to replace the existing code-reviewer.md (or create it) with this optimized version?"_
   Only proceed to write the file to disk if the user explicitly answers "Yes".
