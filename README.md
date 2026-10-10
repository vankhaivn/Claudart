# CLAUDART

[Tiếng Việt](README_VI.md) · [Workflow guide](docs/WORKFLOW.md)

CLAUDART gives Claude Code and Codex a memory that lives in your repository. Current state, plans, project knowledge, and agent instructions are plain Markdown files, versioned with your code. A new session picks up where the last one stopped.

It works with Claude Code, Codex, or both. Both tools share one state folder, `.claudart/`. There is no database, daemon, or hosted service.

## What you get

- **Session start:** `/cda-start` gives the agent the current state, open work, and recent Git history.
- **Plans that survive:** a task keeps its plan and decisions in one `TASK.md`, so work can resume tomorrow.
- **Specs for big work:** approve a multi-phase mission once, then let the agent run it to final review.
- **Project knowledge:** durable facts about the project, kept apart from rules and from temporary work.
- **Owner profile:** how you like to work, recorded when you correct the agent.
- **Health checks:** a read-only checker for the memory structure.

## Install

New project, Claude Code layer (default):

```bash
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash
```

Add a flag after `bash -s --` to choose what to install:

| Flag             | Installs                                                       |
| ---------------- | -------------------------------------------------------------- |
| `--claude`       | Claude Code layer (default)                                    |
| `--codex`        | Codex layer                                                    |
| `--both`         | Both layers                                                    |
| `--project-docs` | Optional [Project Docs](modules/project-docs/README.md) module |

```bash
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --both
```

The installer only adds missing files and never touches existing project state.

**Already have CLAUDART or custom agent instructions?** Don't run the installer over them. Ask your agent instead:

> Read https://raw.githubusercontent.com/vankhaivn/Claudart/main/INTEGRATE.md and follow it to integrate or update CLAUDART in this project. Preserve project-specific content and show me the proposed changes before writing them.

The agent shows you a plan and waits for your approval before writing anything.

All CLAUDART workflows use the same `cda-` name on both hosts: type `/cda-plan` in Claude Code or `$cda-plan` in Codex. The leading character is the host's invocation syntax, not part of the workflow name.

## Daily use

| You want to                        | Claude Code            | Codex                  |
| ---------------------------------- | ---------------------- | ---------------------- |
| Start a session                    | `/cda-start`           | `$cda-start`           |
| Plan work that should survive      | `/cda-plan <task>`     | `$cda-plan <task>`     |
| Define a large, multi-session job  | `/cda-spec <mission>`  | `$cda-spec <mission>`  |
| Run an approved spec               | `/cda-spec-run <slug>` | `$cda-spec-run <slug>` |
| Save state at a stopping point     | `/cda-checkpoint`      | `$cda-checkpoint`      |
| Pause a hard investigation mid-way | `/cda-handoff`         | `$cda-handoff`         |
| Turn a repeated lesson into a rule | `/cda-learn`           | `$cda-learn`           |
| Check the installation             | `/cda-doctor`          | `$cda-doctor`          |

Small, clear edits need no command at all; just ask. See the [workflow guide](docs/WORKFLOW.md) for when to use a task or a spec.

## Where things live

| File or folder         | Holds                                   |
| ---------------------- | --------------------------------------- |
| `.claudart/CONTEXT.md` | What is true right now                  |
| `.claudart/OWNER.md`   | How you want the agent to work with you |
| `.claudart/knowledge/` | Durable facts about the project         |
| `.claudart/tasks/`     | Task plans                              |
| `.claudart/specs/`     | Large-work specifications               |
| `.claude/`, `.codex/`  | Agent rules, commands, and scripts      |

## Contributing

```bash
npm ci
npm run check
```

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE)
