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

## Quick Install

Run this one-liner inside your project root — no clone needed:

```bash
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash
```

The installer merges CLAUDART into your project **file by file**. Files you already have are never touched — only missing files are created. Pass `--force` to overwrite.

The default installs the **Claude Code layer** (`.claude/`). Add flags for other layers:

```bash
# Codex layer (AGENTS.md + .codex/ + .agents/)
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --codex

# Both layers
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --both

# Overwrite existing files
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --force
```

---

## Overview

**CLAUDART** (a portmanteau of **CLAUDE** and **SMART**) is a universal project template that gives AI coding agents a structured operating layer from day one. Instead of stuffing everything into one root memory file, CLAUDART keeps Claude and Codex native: each tool gets its own commands, review agents, and session-state files.

It scales from a solo project to a large team repo with **zero external dependencies, no vector databases, and no plugins** — just markdown, TOML, and version control.

## Key Features

- **Modular Rules System** — `.claude/CLAUDE.md` and `.codex/CODEX.md` stay lightweight indexes; durable guidance lives in `.claude/rules/` and `.codex/guidelines/`.
- **Agent-Local Session State** — Claude uses `.claude/CONTEXT.md` + `.claude/JOURNAL.md`; Codex uses `.codex/CONTEXT.md` + `.codex/JOURNAL.md`.
- **Built-in Review Agents** — `clean-code-reviewer` for scope discipline and clean-code review, plus `secure-reviewer` for read-only security audits.
- **Project Discovery Interview** — `/project-discovery` and `$project-discovery` turn rough ideas into usable project documentation before implementation starts.
- **Continuous Self-Learning** — `/learn` and `$codex-learn` re-read the active rule set, run a retrospective, and promote recurring lessons into durable guidance.
- **Health Checks Included** — `/doctor` and `$codex-doctor` validate structure, frontmatter, wiring, and token hygiene.

## Getting Started

The fastest path is the **Quick Install** one-liner above. Once the files are in your project:

1. Open the project in Claude Code, Codex, or both.
2. If the idea is still vague, run `/project-discovery` or `$project-discovery` before writing code.
3. If you use Claude Code, you can optionally run the built-in `/init` first. If it generates a root `CLAUDE.md`, copy the useful project-specific content into `.claude/CLAUDE.md`.
4. Run `/refactor-memory` for the Claude layer and/or `$codex-refactor-memory` for the Codex layer to consolidate the installed scaffold into project-specific guidance.
5. Run `/doctor` and/or `$codex-doctor` to verify the installation.
6. End meaningful sessions with `/checkpoint` or `$codex-checkpoint` so the next session starts with accurate state.

## Core Commands & Workflow

Claude Code uses slash commands from `.claude/commands/`. Codex uses repo skills in `.agents/skills/` backed by full command specs in `.codex/commands/`: `$project-discovery`, `$codex-refactor-memory`, `$codex-checkpoint`, `$codex-learn`, and `$codex-doctor`.

### `/project-discovery` and `$project-discovery`

An interview-first planning workflow for the moment before a project has a real spec.

- Asks one high-leverage question at a time instead of dumping a long questionnaire.
- Keeps confirmed facts, assumptions, rejected options, open questions, domain language, and scope boundaries separate.
- Adapts depth for lightweight projects, serious internal tools, or stakeholder-ready documentation.
- Writes `docs/project/00-raw-discovery.md` first, then creates the smallest useful structured documentation pack under `docs/project/`.
- Does not start implementation code.

### `/init` *(built in to Claude Code, not CLAUDART)*

Claude Code can scan the repo and generate a starter `CLAUDE.md`. CLAUDART intentionally does not replace that command. If you use it, copy the useful project-specific content into `.claude/CLAUDE.md`, then continue with `/refactor-memory`.

### `/refactor-memory` and `$codex-refactor-memory`

The consolidation pass for each AI layer.

- Trims the top-level memory file into a lightweight index.
- Extracts durable, scoped guidance into `.claude/rules/` or `.codex/guidelines/`.
- Ensures CONTEXT and AI-behavior references are wired correctly.
- Audits existing rules, skills, commands, and agents for stale structure or missing metadata.
- Relies on git for rollback, so commit before running it on a large refactor.

### `/checkpoint` and `$codex-checkpoint`

End-of-session commands that update the current-state snapshot and append meaningful retired items to the agent-local journal.

- **Declarative overwrite** — `CONTEXT.md` is rebuilt each run, not appended.
- **Hard 150-line ceiling** — the command refuses to write an oversized context file.
- **Append to JOURNAL on graduation** — when work is completed, pivoted, or settled, a one-line audit entry is recorded.
- **JOURNAL stays out of auto-loaded context** — it is append-only history, not active working memory.

### `/learn` and `$codex-learn`

Retrospective commands that promote validated lessons into durable guidance.

- Re-read the active memory index, rules/guidelines, and relevant agents.
- Name deviations and the rationalizations that caused them.
- Scan only the **tail** of `JOURNAL.md` for recurring decisions or pivots.
- Update durable rules with loophole-closing language such as `NEVER do X, even when Y feels convenient`.
- Keep `CONTEXT.md` and existing journal entries owned by checkpoint.

### `/doctor` and `$codex-doctor`

Read-only health checks. They report missing files, broken frontmatter, dead path globs, isolated rules/guidelines, token-hygiene violations, and agent overlap. They spot-check `JOURNAL.md` with `head`, `tail`, `wc -l`, and targeted searches instead of full-reading it.

## Memory Architecture

CLAUDART uses agent-local memory files plus each tool's native operating layer:

| File | Loaded? | Who writes | Lifetime |
|---|---|---|---|
| `.claude/CLAUDE.md` | Always | You + `/learn` + `/refactor-memory` | Project lifetime |
| `.claude/CONTEXT.md` | Always (via `@import`) | `/checkpoint` | Live, declarative |
| `.claude/JOURNAL.md` | **Never** auto-loaded | `/checkpoint` (append) | Forever |
| `AGENTS.md` + `.codex/AGENTS.md` + `.codex/CODEX.md` | Always | You + `$codex-learn` + `$codex-refactor-memory` | Project lifetime |
| `.codex/CONTEXT.md` | Always | `$codex-checkpoint` | Live, declarative |
| `.codex/JOURNAL.md` | **Never** auto-loaded | `$codex-checkpoint` (append) | Forever |
| `~/.claude/projects/<hash>/memory/` | First 200 lines | Claude Code | Per machine |

**Why no vector DB?** For a single-developer or small-team project, native markdown + git + path-scoped guidance cover most of the value. CLAUDART keeps the system inspectable, grep-friendly, and easy to migrate.

## Recommended Workflow

```text
new project                    daily loop
─────────────                  ──────────
/project-discovery             work on feature/bug
  ↓                              ↓
/init (optional)               /checkpoint or $codex-checkpoint
  ↓                              ↓
copy useful bits into          /learn or $codex-learn
.claude/CLAUDE.md                ↓
  ↓                            /refactor-memory or
/refactor-memory or            $codex-refactor-memory
$codex-refactor-memory           ↓
  ↓                            /doctor or $codex-doctor
/doctor or $codex-doctor
```

## Directory Layout

```text
your-project/
├── AGENTS.md                       # Codex root loader, copied from .codex/AGENTS.md by installer
├── .agents/
│   └── skills/                     # Codex repo skills
├── .codex/
│   ├── AGENTS.md                   # Source template copied to root AGENTS.md during install
│   ├── CODEX.md                    # Codex-native lightweight index
│   ├── CONTEXT.md                  # Codex live state, declarative, ≤ 150 lines
│   ├── JOURNAL.md                  # Codex append-only audit log — never auto-loaded
│   ├── agents/                     # Codex TOML subagents
│   ├── commands/                   # Codex command specs used by skills
│   ├── config.toml                 # Codex project defaults
│   └── guidelines/                 # Codex-native semantic guidance
└── .claude/
    ├── CLAUDE.md                   # Claude lightweight index (< 100 lines after /refactor-memory)
    ├── CONTEXT.md                  # Claude live state, declarative, ≤ 150 lines
    ├── JOURNAL.md                  # Claude append-only audit log — never auto-loaded
    ├── agents/
    │   ├── clean-code-reviewer.md  # PROACTIVE: scope + Clean Code + project conventions
    │   └── secure-reviewer.md      # PROACTIVE: read-only OWASP-focused audit
    ├── commands/
    │   ├── checkpoint.md           # /checkpoint — declarative state update + JOURNAL append
    │   ├── doctor.md               # /doctor — read-only health check
    │   ├── learn.md                # /learn — retrospective + rule promotion
    │   ├── project-discovery.md    # /project-discovery — interview rough ideas into project docs
    │   └── refactor-memory.md      # /refactor-memory — consolidate .claude/CLAUDE.md + rules + agents
    └── rules/
        └── ai-behavior.md          # Universal behavior guardrails
```

CLAUDART ships a Claude-specific layer in `.claude/` and a Codex-specific layer in `.codex/` plus `.agents/skills/`. During Codex installation, the installer also copies `.codex/AGENTS.md` to `AGENTS.md` at the project root so Codex auto-loads it.

## The Graduation Pipeline

Each tool keeps its own short-lived and medium-lived knowledge locally:

```text
Claude: .claude/CONTEXT.md  →  .claude/JOURNAL.md  →  .claude/rules/
        ("now")               ("happened")            ("always true")

Codex:  .codex/CONTEXT.md   →  .codex/JOURNAL.md   →  .codex/guidelines/
        ("now")               ("happened")            ("always true")
```

A tactical note starts in `CONTEXT.md`. When checkpoint retires it because the work is done or the decision is settled, one line goes to `JOURNAL.md`. When learn later sees the same pattern recurring, it promotes the underlying principle into durable rules or guidelines.

## Contributing

We want CLAUDART to be the standard for modern AI-assisted projects. Contributions, issues, and feature requests are welcome.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

Distributed under the MIT License. See `LICENSE` for more information.

---
<div align="center">
  <i>Built for the future of AI Assisted Development.</i>
</div>
