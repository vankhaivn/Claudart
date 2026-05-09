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
curl … | bash -s -- --claude

# Codex CLI layer only (.codex/ + .agents/ + AGENTS.md)
curl … | bash -s -- --codex

# Both layers
curl … | bash -s -- --both
```

---

## Why CLAUDART?

Modern agent memory frameworks require real infrastructure:

| | CLAUDART | Mem0 | Zep | LangMem |
|---|:---:|:---:|:---:|:---:|
| **Setup** | `curl \| bash` | vector DB + Docker + OpenAI key | Neo4j + managed cloud | PostgreSQL + pgvector |
| **Human-readable** | ✅ | ❌ | ❌ | ❌ |
| **Works offline / air-gapped** | ✅ | ❌ | ❌ | ❌ |
| **PR-reviewable memory** | ✅ | ❌ | ❌ | ❌ |
| **Tool support** | Claude Code, Codex CLI, Cursor, Windsurf | API only | API only | LangGraph only |

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

## Commands & Skills

| Claude Code | Codex CLI | What it does |
|---|---|---|
| `/project-discovery` | `$codex-project-discovery` | Interview-first planning — turns rough ideas into project docs before any code |
| `/refactor-memory` | `$codex-refactor-memory` | Trims CLAUDE.md/AGENTS.md into a lightweight index; extracts durable guidance into rules/guidelines |
| `/checkpoint` | `$codex-checkpoint` | Declarative CONTEXT rebuild + JOURNAL append (hard 150-line ceiling) |
| `/learn` | `$codex-learn` | Retrospective — promotes recurring lessons into rules/guidelines with loophole-closing language |
| `/doctor` | `$codex-doctor` | Read-only health check: structure, frontmatter, token hygiene, wiring |

Two review agents are always available: `clean-code-reviewer` (scope + Clean Code discipline) and `secure-reviewer` (read-only OWASP audit).

## Directory Layout

```text
your-project/
├── AGENTS.md                       # Codex root loader (copied from .codex/AGENTS.md on install)
├── .agents/
│   └── skills/                     # Codex repo skills (codex-checkpoint, codex-doctor, …)
├── .codex/
│   ├── AGENTS.md                   # Codex memory index
│   ├── CONTEXT.md                  # Live state, declarative, ≤ 150 lines
│   ├── JOURNAL.md                  # Append-only audit log — never auto-loaded
│   ├── agents/                     # Codex TOML subagents
│   ├── config.toml                 # Codex project defaults
│   └── guidelines/                 # Codex-native semantic guidance
└── .claude/
    ├── CLAUDE.md                   # Lightweight index (< 100 lines)
    ├── CONTEXT.md                  # Live state, declarative, ≤ 150 lines
    ├── JOURNAL.md                  # Append-only audit log — never auto-loaded
    ├── agents/
    │   ├── clean-code-reviewer.md
    │   └── secure-reviewer.md
    ├── commands/                   # Slash command protocols
    └── rules/
        └── ai-behavior.md
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
