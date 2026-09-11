# CLAUDART

[Tiếng Việt](README_VI.md) · [Workflow guide](docs/WORKFLOW.md)

CLAUDART is a repository-local workflow for Claude Code and Codex CLI. It keeps session state, implementation plans, project knowledge, and agent instructions in versioned Markdown files alongside the code.

The two runtime layers are independent. Install Claude Code support, Codex support, or both. CLAUDART does not require a database, daemon, or hosted service.

## What it adds

- **Session orientation:** start a new session from current state, active work, project knowledge, and recent Git history.
- **Persistent plans:** keep a resumable `TASK.md` in a lightweight task workspace, with supporting files only when needed.
- **Large-work specifications:** define and execute work that spans several tasks or sessions under one approved specification.
- **Project knowledge:** store durable facts separately from behavioral rules and temporary work state.
- **Session handoff:** preserve an unfinished investigation when the context window is nearly full.
- **Maintenance tools:** check and normalize the memory structure without introducing a separate service.
- **On-demand specialists:** use focused agents for code health, security review, and visual review only when requested.

## Installation

### New project

The default installation adds the Claude Code layer:

```bash
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash
```

Choose a layer explicitly when needed:

```bash
# Claude Code
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --claude

# Codex CLI
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --codex

# Both
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --both
```

The installer copies missing files and skips files that already exist. `--force` overwrites existing files and should be used only when that is intentional.

A clean Codex installation adds `.codex/`, `.agents/skills/`, and a root `AGENTS.md`. The source template is stored at `.codex/AGENTS.md` in this repository.

### Existing project or existing CLAUDART installation

Do not use the installer as a merge tool. It can copy or overwrite files, but it does not reconcile custom instructions, live state, tasks, specifications, or project knowledge.

Ask your coding agent to follow the integration protocol instead:

> Read https://raw.githubusercontent.com/vankhaivn/Claudart/main/INTEGRATE.md and follow it to integrate or update CLAUDART in this project. Preserve project-specific content and show me the proposed changes before writing them.

The protocol compares the current project with the current `main` branch and separates stale CLAUDART files from project-authored customizations.

### First run

After installation or reconciliation, run the health and normalization sequence once:

| Claude Code        | Codex CLI                |
| ------------------ | ------------------------ |
| `/doctor`          | `$codex-doctor`          |
| `/refactor-memory` | `$codex-refactor-memory` |
| `/doctor`          | `$codex-doctor`          |

Then begin a normal session with `/start` or `$codex-start`.

## Daily workflow

| Purpose                                           | Claude Code        | Codex CLI                |
| ------------------------------------------------- | ------------------ | ------------------------ |
| Orient a session                                  | `/start`           | `$codex-start`           |
| Create a persistent implementation plan           | `/plan <task>`     | `$codex-plan <task>`     |
| Define large, multi-session work                  | `/spec <mission>`  | `$codex-spec <mission>`  |
| Execute an approved specification                 | `/spec-run <slug>` | `$codex-spec-run <slug>` |
| Preserve an unfinished investigation              | `/handoff`         | `$codex-handoff`         |
| Rebuild current state at a natural stopping point | `/checkpoint`      | `$codex-checkpoint`      |
| Turn recurring behavior into a rule               | `/learn`           | `$codex-learn`           |
| Check the installation                            | `/doctor`          | `$codex-doctor`          |

Use a task plan when meaningful decisions, coordination, interruption, or review need persistence, or when explicitly requested. Small, clear edits do not require a workspace; file count alone is not a trigger. Use a specification for mission-scale scope with shared approved intent and a multi-phase roadmap—not merely because a task needs an image, JSON, or an archive.

A task starts as `tasks/YYYY-MM-DD-NNN-<slug>/TASK.md` under the selected runtime. `TASK.md` is the only required file. Create `artifacts/` only for a concrete native-format input/output, necessary retained evidence, or substantial task-local research; short findings stay inline. There is no mandatory POC, ledger, repeated review loop, or session rotation. On user-confirmed closure, archive the whole directory. The current contract has no flat-task compatibility path; downstream upgrades adapt existing work deliberately.

## How state is organized

| Location                  | Purpose                                         | Loading behavior                                    |
| ------------------------- | ----------------------------------------------- | --------------------------------------------------- |
| `CONTEXT.md`              | Current project and work state                  | Read at session start; rewritten by checkpoint      |
| `JOURNAL.md`              | Retired history                                 | Append-only; not loaded automatically               |
| `rules/` or `guidelines/` | Prescriptive instructions for agent behavior    | Loaded when applicable                              |
| `knowledge/`              | Durable descriptive facts about the project     | Routed through `INDEX.md`; details loaded on demand |
| `tasks/`                  | Persistent implementation plans                 | Metadata at start; selected `TASK.md` and needed files on resume               |
| `specs/`                  | Large-work specifications and execution records | Read when a specification is active                 |
| `HANDOFF.md`              | One-session reasoning handoff                   | Consumed by the next start, then removed            |

The important boundary is simple: **rules say how the agent should work; knowledge records what is true about the project; tasks and specifications record work in progress.**

## Specialized agents

These agents never run automatically.

| Agent               | Role                                                                                                                    |
| ------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Clean-code reviewer | Makes a scoped, behavior-preserving code-health improvement and validates it. A review-only request keeps it read-only. |
| Security auditor    | Performs a read-only, evidence-based security audit and writes a report.                                                |
| UI visual critic    | Reviews rendered UI or visual output on explicit request.                                                               |

The parent agent remains responsible for scope, integration, and validation of delegated work.

## Developing CLAUDART

This repository uses Prettier for Markdown and Bash-based checks for the installer, knowledge contract, task workspaces, and specification workflow.

```bash
npm ci
npm run check
```

To use the repository's pre-commit hook:

```bash
npm run hooks:install
```

## Documentation

- [Workflow guide](docs/WORKFLOW.md)
- [Vietnamese workflow guide](docs/WORKFLOW_VI.md)
- [Integration and upgrade protocol](INTEGRATE.md)
- [Contributing](CONTRIBUTING.md)

## License

CLAUDART is available under the [MIT License](LICENSE).
