# CLAUDART

[Tiếng Việt](README_VI.md) · [Workflow guide](docs/WORKFLOW.md)

CLAUDART is a repository-local workflow for Claude Code and Codex. It keeps session state, implementation plans, project knowledge, and agent instructions in versioned Markdown files alongside the code.

Claude Code and Codex have separate runtime adapters and share one project-state directory, `.claudart/`. Install either adapter or both. CLAUDART does not require a database, daemon, or hosted service.

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

# Codex
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --codex

# Both
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --both

# Add the optional Project Docs module to the selected layer or layers
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --claude --project-docs
```

Every installation seeds `.claudart/` once and installs the selected adapters. The installer copies missing files and preserves existing project state. The default installation contains only the core layer; `--project-docs` adds the optional documentation-lifecycle command or skill and its references. It never creates or migrates your project documentation. `--force` refreshes adapter payload only; existing shared state and the Codex root loader remain untouched. Reconcile customized instructions with `INTEGRATE.md`.

Project Docs includes [output templates and filled examples](modules/project-docs/README.md#output-templates-and-examples) for product scope, behavior, architecture, development, and operations, linked by a small documentation router. Use only the responsibilities that need an owner; existing docs and knowledge can retain theirs. Templates adapt to local use, `main` latest, continuous deployment, or formal team releases; they preserve actual requirements without imposing a production-readiness process.

A clean Codex installation adds `.claudart/`, `.codex/`, `.agents/skills/`, and a root `AGENTS.md`. The source template is stored at `.codex/AGENTS.md` in this repository.

### Existing project or existing CLAUDART installation

Do not use the installer as a merge tool. It can copy or overwrite files, but it does not reconcile custom instructions, live state, tasks, specifications, or project knowledge.

Ask your coding agent to follow the integration protocol instead:

> Read https://raw.githubusercontent.com/vankhaivn/Claudart/main/INTEGRATE.md and follow it to integrate or update CLAUDART in this project. Preserve project-specific content and show me the proposed changes before writing them.

The protocol compares the current project with the current `main` branch and separates stale CLAUDART files from project-authored customizations. It also identifies relevant optional modules and explains recommendations in the proposed plan. You do not need to know their names in advance; a module is installed only if you include it in the approved plan. Installing Project Docs does not automatically reorganize existing docs or knowledge.

### First run

Begin a normal session with `/start` or `$codex-start`. Integration follows the bounded verification in [INTEGRATE.md](INTEGRATE.md); a full doctor or memory refactor is conditional on findings or your request.

For a health audit, `/doctor` or `$codex-doctor` runs `doctor-check.sh` once, then reviews meaning and workflow consistency. The helper checks structure, metadata, explicit local references and size limits, and includes the existing knowledge checker. Link targets may be code or docs anywhere in the repository; additional Markdown sources are opt-in. See the [checker usage and limits](.codex/references/doctor-check.md). It is read-only and requires Bash 3.2 plus standard utilities, with no package installation.

## Daily workflow

| Purpose                                           | Claude Code        | Codex                    |
| ------------------------------------------------- | ------------------ | ------------------------ |
| Orient a session                                  | `/start`           | `$codex-start`           |
| Create a persistent implementation plan           | `/plan <task>`     | `$codex-plan <task>`     |
| Define large, multi-session work                  | `/spec <mission>`  | `$codex-spec <mission>`  |
| Execute an approved specification                 | `/spec-run <slug>` | `$codex-spec-run <slug>` |
| Preserve an unfinished investigation              | `/handoff`         | `$codex-handoff`         |
| Rebuild current state at a natural stopping point | `/checkpoint`      | `$codex-checkpoint`      |
| Turn recurring behavior into a rule               | `/learn`           | `$codex-learn`           |
| Check the installation                            | `/doctor`          | `$codex-doctor`          |
| Maintain current project documentation (optional) | `/project-docs`    | `$codex-project-docs`    |

Use a task plan when meaningful decisions, coordination, interruption, or review need persistence, or when explicitly requested. Small, clear edits do not require a workspace; file count alone is not a trigger. Use a specification for mission-scale scope with shared approved intent and a multi-phase roadmap—not merely because a task needs an image, JSON, or an archive.

A task starts as `.claudart/tasks/YYYY-MM-DD-NNN-<slug>/TASK.md`, shared by both runtimes. `TASK.md` is the only required file. Create `artifacts/` only for a concrete native-format input/output, necessary retained evidence, or substantial task-local research; short findings stay inline. There is no mandatory POC, ledger, repeated review loop, or session rotation. On user-confirmed closure, archive the whole directory. Task discovery uses this workspace layout only.

An explicit instruction to implement or resume carries through planning without a second approval prompt. Planning-only requests remain read-only, and final closure still needs user confirmation. An approved spec can transfer to its runner in the same session when execution was requested; session rotation is optional.

## How state is organized

| Location                  | Purpose                                         | Loading behavior                                                 |
| ------------------------- | ----------------------------------------------- | ---------------------------------------------------------------- |
| `.claudart/CONTEXT.md`    | Current project and work state                  | Read at session start; rewritten by checkpoint                   |
| `.claudart/JOURNAL.md`    | Retired history                                 | Append-only; not loaded automatically                            |
| `rules/` or `guidelines/` | Prescriptive instructions for agent behavior    | Loaded when applicable                                           |
| `.claudart/knowledge/`    | Durable descriptive facts about the project     | Routed through `INDEX.md`; details loaded on demand              |
| `.claudart/tasks/`        | Persistent implementation plans                 | Metadata at start; selected `TASK.md` and needed files on resume |
| `.claudart/specs/`        | Large-work specifications and execution records | Read when a specification is active                              |
| `.claudart/HANDOFF.md`    | One-session reasoning handoff                   | Consumed by the next start, then removed                         |

The important boundary is simple: **rules say how the agent should work; knowledge records facts with no better current owner; tasks and specifications record work in progress.** When source, schema, generated reference, or a project document already owns a fact, knowledge keeps a concise route instead of a competing copy.

Both adapters read and write the same `.claudart/` state. Switching runtimes preserves task/spec scope, approvals, evidence and final-review gates; `agent` metadata records provenance rather than selecting a store or granting permission. Use the actual host's tools and adapter instructions.

Shared files support sequential handoff, not automatic multi-writer synchronization. Coordinate writes to summaries, indexes and the handoff slot; checkpoint preserves unrelated unresolved work and an unconsumed handoff is never silently replaced. Separate checkouts still follow the project's Git and collaboration policy.

Workflow rules load when needed. Claude's source template lives at `.claude/CLAUDE.md`, while installed projects use root `CLAUDE.md` and resolve adapter imports through `.claude/`; knowledge-maintenance detail lives in `references/`. The optional Project Docs module is used for lifecycle requests or when a change affects current documentation it owns; it does not run a full audit at start, checkpoint, or after an ordinary minor edit. Retrieval does not load mutation schemas, and uninterrupted spec iterations read relevant state instead of repeatedly reloading all mission files.

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
- [Project Docs module](modules/project-docs/README.md)
- [Integration and upgrade protocol](INTEGRATE.md)
- [Contributing](CONTRIBUTING.md)

## License

CLAUDART is available under the [MIT License](LICENSE).
