<div align="center">
  <h1>CLAUDART</h1>
  <p><strong>CLAUDE + SMART</strong></p>
  <p>The Ultimate AI-Powered Foundation Template for Every Project</p>

  <p>
    <a href="https://github.com/vankhaivn/Claudart/issues"><img alt="Issues" src="https://img.shields.io/github/issues/vankhaivn/Claudart?style=for-the-badge&color=blue"></a>
    <a href="https://github.com/vankhaivn/Claudart/pulls"><img alt="Pull Requests" src="https://img.shields.io/github/issues-pr/vankhaivn/Claudart?style=for-the-badge&color=brightgreen"></a>
    <a href="https://github.com/vankhaivn/Claudart/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/vankhaivn/Claudart?style=for-the-badge&color=orange"></a>
  </p>
</div>

---

## Overview

**CLAUDART** (a portmanteau of **CLAUDE** and **SMART**) is a revolutionary, universal project template designed to supercharge your development workflow directly from day one. Instead of starting from scratch, CLAUDART gives your project a "brain"—equipping it with highly capable AI tools, automated code-reviewers, and continuous learning mechanisms tailored to your specific codebase.

Whether you are building a small side project or an enterprise-grade application, CLAUDART scales seamlessly to act as your intelligent pair programmer and project manager.

## Key Features

- **Auto-Initializing AI Foundation:** Instantly equip your project with the best available foundational models.
- **Custom Code-Reviewers:** Spin up context-aware code reviewers that understand your exact design patterns.
- **Continuous Auto-Learning:** The project gets "smarter" over time as your AI agents learn from completed tasks and refactored code.
- **Dedicated Agent Ecosystem:** House your specialized, task-driven AI subagents natively inside `.claude/agents`.

## Getting Started

Start using CLAUDART in your local environment by cloning this template and initiating it.

```bash
# 1. Clone the CLAUDART template into your new project directory
git clone https://github.com/vankhaivn/Claudart.git my-awesome-project
cd my-awesome-project

# 2. Reinitialize git for your own project
rm -rf .git
git init
```

## Core Commands & Workflow

To fully harness the power of CLAUDART within your AI IDE (like Cursor or Claude Code), use the following standard slash commands:

### `> /init`
Use this command **once** at the beginning of your project. It initializes the CLAUDART environment using the most advanced AI model available to you. 
- *What it does:* Scaffolds core memory structures, analyzes the initial stack, and sets up project context guidelines.

### `> /create-reviewer`
Need an expert eye before merging to production? 
- *What it does:* Analyzes your current architecture and generates the absolute best custom **code-reviewer agent** for your specific project needs. 

### `> /refactor-memory`
Projects evolve, and so should your AI's understanding.
- *What it does:* Cleans up, consolidates, and updates the AI's internal project memory so it stops hallucinating stale context and stays laser-focused on your current architecture.

### `> /learn`
The true power of "SMART".
- *What it does:* Run this after completing a complex feature, fixing a tricky bug, or adopting a new pattern. The agent will digest the recent changes and update its knowledge base automatically, ensuring it never makes the same mistake twice.

## The Agent Ecosystem

CLAUDART embraces subagent architecture. All custom intelligence modules are stored locally in the following directory:

```text
.claude/
└── agents/          # Your custom-built specialized subagents live here
    ├── reviewer.md
    ├── architect.md
    └── ...
```

By keeping agents version-controlled alongside your code, your entire team shares the same standard of AI assistance.

## Contributing

We want to make CLAUDART the standard for every modern AI-driven project! Contributions, issues, and feature requests are highly welcome.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.

---
<div align="center">
  <i>Built for the future of AI Assisted Development.</i>
</div>
