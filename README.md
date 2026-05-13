<div align="center">
  <h1>CLAUDART</h1>
  <p><strong>Pure-markdown memory and rules for Claude Code and Codex CLI.<br>No vector DBs. No APIs. No config. Just files in git.</strong></p>

  <p>
    <a href="https://github.com/vankhaivn/Claudart/issues"><img alt="Issues" src="https://img.shields.io/github/issues/vankhaivn/Claudart?style=for-the-badge&color=blue"></a>
    <a href="https://github.com/vankhaivn/Claudart/pulls"><img alt="Pull Requests" src="https://img.shields.io/github/issues-pr/vankhaivn/Claudart?style=for-the-badge&color=brightgreen"></a>
    <a href="https://github.com/vankhaivn/Claudart/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/vankhaivn/Claudart?style=for-the-badge&color=orange"></a>
  </p>
</div>

---

## Quick Install

Run inside your project root — no clone needed:

```bash
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash
```

The installer merges files **non-destructively**: existing files are never touched, only missing ones are created. Pass `--force` to overwrite.

```bash
# Claude Code layer only (.claude/)  ← default
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --claude

# Codex CLI layer only (.codex/ + .agents/ + AGENTS.md)
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --codex

# Both layers
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --both
```

---

## Why CLAUDART?

Modern agent memory frameworks require real infrastructure:

|                                |                 CLAUDART                 |              Mem0               |          Zep          |        LangMem        |       Understand-Anything        |             MemPalace              |
| ------------------------------ | :--------------------------------------: | :-----------------------------: | :-------------------: | :-------------------: | :------------------------------: | :--------------------------------: |
| **Setup**                      |              `curl \| bash`              | vector DB + Docker + OpenAI key | Neo4j + managed cloud | PostgreSQL + pgvector |      `curl \| bash` or plugin     |   `pip install` + 300 MB model    |
| **Human-readable**             |                    ✅                    |               ❌                |          ❌           |          ❌           |       ⚠️ JSON + dashboard        |    ⚠️ verbatim text, binary DB    |
| **Works offline / air-gapped** |                    ✅                    |               ❌                |          ❌           |          ❌           |      ❌ LLM required             |               ✅                   |
| **PR-reviewable memory**       |                    ✅                    |               ❌                |          ❌           |          ❌           |      ✅ JSON committed to git    |    ❌ ChromaDB + SQLite binary     |
| **Tool support**               | Claude Code, Codex CLI, Cursor, Windsurf |            API only             |       API only        |    LangGraph only     | Claude Code, Codex, Cursor, Copilot, Gemini CLI + 6 more | Claude Code, Codex CLI, Gemini CLI, MCP-compatible |

Every major coding tool converged independently on plain markdown files in the repo — AGENTS.md appears in ~20k public GitHub repos. CLAUDART just makes it structured.

## How It Works

Two thin layers installed into your project:

- **Claude layer** (`.claude/`) — slash commands, rules, review agents, session state
- **Codex layer** (`.codex/` + `.agents/skills/`) — guidelines, TOML subagents, repo skills

Both share the same three-tier memory pattern — the **graduation pipeline**:

```text
CONTEXT.md      →   JOURNAL.md        →   rules/ or guidelines/
("right now")       ("what happened")     ("always true")
```

A note starts in `CONTEXT.md`. When it's settled, one line goes to `JOURNAL.md`. When the same pattern recurs, `/learn` or `$codex-learn` promotes it to durable rules. The journal is **never auto-loaded** — it's audit history, not active memory.

### Plan persistence — replacing built-in plan mode

Both Claude Code and Codex CLI ship a built-in plan mode (Shift+Tab or `/plan`), but their plans live only in the chat session — close the terminal, lose the plan; let a few unrelated commits land while you pause, lose the context. CLAUDART persists every non-trivial plan as a markdown document:

```text
/plan <task>  →  tasks/<YYYY-MM-DD-slug>.md  →  tasks/done/<slug>.md  →  JOURNAL.md
 (create)         (working doc, status: planning →     (archived after        (one-line record)
                  in-progress → awaiting-review →      user confirms)
                  done)
```

Each task file is self-contained: Purpose, related code paths, related docs, **Memory Hints for the next session**, Plan of Work, checkbox steps with UTC timestamps, Decision Log, Surprises, Validation criteria, and final Outcomes. A session can resume from the file alone — even days later, even after other branches landed. The full schema lives in `.claude/rules/task-management.md` (and `.codex/guidelines/task-management.md`).

**Two symmetric safety gates** — the agent is locked out of code edits at both ends of the lifecycle, and only the user can flip the gate open:

- **Planning gate** (`status: planning` → `in-progress`): the agent explores read-only and drafts the plan. Say "go" / "approved" / "implement" to start coding.
- **Completion gate** (`status: awaiting-review` → `done`): when all steps and validation are checked, the agent flips to `awaiting-review` and **stops** — no archiving, no JOURNAL entry. You verify the work for real (run the app, manual QA, check the diff). Say "approved" / "looks good" / "ok đóng" to close. If something's broken, just report it — the agent flips back to `in-progress`, logs your feedback in Surprises, and fixes it.

Both gates are convention-enforced. Together they replace native plan mode (no more lost plans on session close) **and** the silent agent self-completion that hides real bugs behind a green checkbox.

## Commands & Skills

| Claude Code          | Codex CLI                  | What it does                                                                                        |
| -------------------- | -------------------------- | --------------------------------------------------------------------------------------------------- |
| `/start`             | `$codex-start`             | Lightweight session boot — reads CONTEXT, active tasks, and the last 3 git commits                  |
| `/plan <task>`       | `$codex-plan <task>`       | Creates a persistent implementation plan as a markdown doc in `tasks/` — replaces native plan mode  |
| `/project-discovery` | `$codex-project-discovery` | Interview-first planning — turns rough ideas into project docs before any code                      |
| `/refactor-memory`   | `$codex-refactor-memory`   | Trims CLAUDE.md/AGENTS.md into a lightweight index; extracts durable guidance into rules/guidelines |
| `/checkpoint`        | `$codex-checkpoint`        | Declarative CONTEXT rebuild + `tasks/index.md` sync + JOURNAL append                                |
| `/learn`             | `$codex-learn`             | Retrospective — promotes recurring lessons into rules/guidelines with loophole-closing language     |
| `/doctor`            | `$codex-doctor`            | Read-only health check: structure, frontmatter, token hygiene, wiring, task hygiene                 |

Two review agents are always available: `clean-code-reviewer` (scope + Clean Code discipline) and `secure-reviewer` (read-only OWASP audit).

## Directory Layout

```text
your-project/
├── AGENTS.md                       # Codex root loader (copied from .codex/AGENTS.md on install)
├── .agents/
│   └── skills/                     # Codex repo skills (codex-start, codex-plan, codex-checkpoint, …)
├── .codex/
│   ├── AGENTS.md                   # Codex source template in CLAUDART; copied to root AGENTS.md
│   ├── CONTEXT.md                  # Live state, declarative, ≤ 150 lines
│   ├── JOURNAL.md                  # Append-only audit log — never auto-loaded
│   ├── agents/                     # Codex TOML subagents
│   ├── config.toml                 # Codex project defaults
│   ├── guidelines/                 # Codex-native semantic guidance
│   │   ├── ai-behavior.md
│   │   └── task-management.md
│   └── tasks/                      # Persistent implementation plans (one file per task)
│       ├── index.md                # Active + recently-done dashboard, ≤ 100 lines
│       └── done/                   # Archived completed/cancelled tasks
└── .claude/
    ├── CLAUDE.md                   # Lightweight index (< 100 lines)
    ├── CONTEXT.md                  # Live state, declarative, ≤ 150 lines
    ├── JOURNAL.md                  # Append-only audit log — never auto-loaded
    ├── agents/
    │   ├── clean-code-reviewer.md
    │   └── secure-reviewer.md
    ├── commands/                   # Slash command protocols
    ├── rules/
    │   ├── ai-behavior.md
    │   └── task-management.md
    └── tasks/                      # Persistent implementation plans (one file per task)
        ├── index.md                # Active + recently-done dashboard, ≤ 100 lines
        └── done/                   # Archived completed/cancelled tasks
```

## Contributing

Contributions, issues, and feature requests are welcome.

1. Fork → branch (`git checkout -b feature/AmazingFeature`) → commit → PR

## License

MIT. See `LICENSE`.

---

<div align="center">
  <i>Built for the future of AI-assisted development.</i>
</div>
