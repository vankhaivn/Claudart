# Contributing to CLAUDART

First off, thank you for considering contributing to **CLAUDART**! It's people like you that make CLAUDART a powerful, universal "brain" template for everyone.

By participating in this project, you agree to abide by our code of conduct.

## How Can I Contribute?

### 1. Reporting Bugs
This section guides you through submitting a bug report. Following these guidelines helps maintainers and the community understand your report, reproduce the behavior, and find related reports.
- Ensure the bug was not already reported by searching on GitHub under Issues.
- Open a new Issue. Be sure to include a title and clear description, as much relevant information as possible, and a code sample or an executable test case demonstrating the expected behavior that is not occurring.

### 2. Suggesting Enhancements
This section guides you through submitting an enhancement suggestion, including completely new features and minor improvements to existing functionality.
- Open a new Issue and provide a clear and descriptive title.
- Provide a step-by-step description of the suggested enhancement in as many details as possible.
- Explain why this enhancement would be useful to most CLAUDART users.

### 3. Contributing Code & Agents
We welcome new AI commands and highly specialized agents! If you have built an awesome agent inside `.claude/agents/` or a new command, we would love to see it.

**To submit your code:**

1. **Fork the repository** and create your branch from `main`.
    ```bash
    git checkout -b feature/my-awesome-agent
    ```
2. **Add or modify files** within the `.claude/` directory. Ensure your prompt engineering is clean, structured, and robust across different models.
3. If you've changed APIs or commands, **update the documentation** (e.g., `README.md`).
4. **Commit your changes**. Write clear, concise commit messages.
    ```bash
    git commit -m "feat: Add brilliant-architect agent"
    ```
5. **Push to the branch**.
    ```bash
    git push origin feature/my-awesome-agent
    ```
6. **Open a Pull Request** against the `main` branch of this repository.

## Understanding the Architecture Structure

If you're contributing new logic, please adhere to our directory structure:
- `.claude/commands/`: CLAUDART slash commands (`/learn`, `/checkpoint`, etc.). Your command files here should detail the steps the AI takes.
- `.claude/agents/`: Highly specialized role-based instruction sets (`reviewer.md`, `architect.md`, etc.). Make sure agent prompts are self-contained and heavily instruct the AI on its specific persona and constraints.

## Pull Request Process

1. Your pull request will be reviewed by the maintainers.
2. We may ask for changes or clarifications about your prompt engineering choices.
3. Once approved, your PR will be merged into the `main` branch.

Thank you for making CLAUDART smarter! 🚀
