<div align="center">
  <h1>CLAUDART</h1>
  <p><strong>The markdown operating layer for Claude Code &amp; Codex CLI — memory, plans, and review, all in git.</strong></p>

  <p>
    <a href="https://github.com/vankhaivn/Claudart/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/vankhaivn/Claudart?style=for-the-badge&color=orange"></a>
    <img alt="Pure Markdown" src="https://img.shields.io/badge/memory-pure_markdown-blue?style=for-the-badge">
    <img alt="Offline-friendly" src="https://img.shields.io/badge/works-offline-green?style=for-the-badge">
    <a href="https://github.com/vankhaivn/Claudart/issues"><img alt="Issues" src="https://img.shields.io/github/issues/vankhaivn/Claudart?style=for-the-badge&color=blue"></a>
  </p>
</div>

---

> **The problem.** AI coding agents leak state: every session starts blind, plans die in chat, decisions get re-discovered weekly, and `CLAUDE.md` / `AGENTS.md` bloats into a token sink nobody trusts.

CLAUDART fixes this with a handful of slash commands over a layered markdown memory model — plain files under `.claude/` and `.codex/`, versioned in git, reviewable in PRs, readable offline. No vector DB, no daemon, no cloud.

## Install

```bash
# Flag after `bash -s --`:  --claude (default) · --codex · --both · --force (overwrite)
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --claude
```

**Already have your own setup, or upgrading?** `install.sh` does a fresh copy that clobbers customizations. Instead, paste this into your agent — it reads the repo, diffs against your project, and merges only what you approve:

> Read https://raw.githubusercontent.com/vankhaivn/Claudart/main/INTEGRATE.md and follow it to integrate CLAUDART into this project. Ask me before touching anything I've customized.

## What it solves

| Pain                                          | CLAUDART's answer                                                                                        |
| --------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Every session starts blind                    | `/start` — reads current state, active tasks, the knowledge index, and recent commits                    |
| Plans die when the session closes             | `/plan` — a persistent task doc that survives any pause                                                  |
| A productive session hits the context ceiling | `/handoff` — a single-slot baton with the session's reasoning state; the next `/start` resumes from it   |
| Same decisions re-discovered weekly           | `/learn` — graduates recurring patterns into path-scoped `rules/`                                        |
| Durable facts have nowhere to live            | `knowledge/` — descriptive facts (domain, architecture, glossary), surfaced every session                |
| `CLAUDE.md` bloats and burns tokens           | `/refactor-memory` — trims it to a lean index; behavior → rules, facts → knowledge                       |
| Memory drifts silently; agents go off-scope   | `/doctor` flags rot; `clean-code-reviewer`, `security-auditor`, and `agent-delegation` keep work bounded |

## The memory model

```text
SESSION STATE (volatile)                DURABLE REFERENCE (survives sessions)

CONTEXT.md       JOURNAL.md             rules/ · guidelines/   knowledge/
what's true now  what happened          how to behave          what the project is
(declarative)    (history log)          (prescriptive)         (descriptive facts)

always loaded    never loaded           auto-loads on          INDEX on /start,
in context       (audit only)           a matching path        detail on demand
```

`/checkpoint` rebuilds `CONTEXT.md`, retires history to `JOURNAL.md` (audit-only, never loaded), and writes durable facts to `knowledge/`. `/learn` promotes recurring behavior to `rules/`. `/doctor` and `/refactor-memory` keep knowledge honest — flagging drift and re-checking each fact against the code.

## Quick start

```bash
# In a project with CLAUDART installed
/start                          # orient the session
/plan add JWT middleware        # persistent task doc — agent waits for your approval before coding
/handoff                        # context window nearly full — distill reasoning state, resume via /start
/checkpoint                     # rebuild CONTEXT.md + sync state at session end
/learn                          # graduate recurring decisions into rules
/doctor                         # health check when the setup feels off
```

Codex CLI: same flow, swap `/` for `$codex-` (e.g. `$codex-start`).

## Documentation

**[docs/WORKFLOW.md](docs/WORKFLOW.md)** is the manual — architecture, full task lifecycle, every command, directory layout. This README is just the pitch.

## Comparison

|                                |        CLAUDART        |              Mem0               |          Zep          |        LangMem        |               Understand-Anything               |                     MemPalace                      |
| ------------------------------ | :--------------------: | :-----------------------------: | :-------------------: | :-------------------: | :---------------------------------------------: | :------------------------------------------------: |
| **Setup**                      |     `curl \| bash`     | vector DB + Docker + OpenAI key | Neo4j + managed cloud | PostgreSQL + pgvector |            `curl \| bash` or plugin             |            `pip install` + 300 MB model            |
| **Human-readable**             |           ✅           |               ❌                |          ❌           |          ❌           |               ⚠️ JSON + dashboard               |            ⚠️ verbatim text, binary DB             |
| **Works offline / air-gapped** |           ✅           |               ❌                |          ❌           |          ❌           |                 ❌ LLM required                 |                         ✅                         |
| **PR-reviewable memory**       |           ✅           |               ❌                |          ❌           |          ❌           |            ✅ JSON committed to git             |            ❌ ChromaDB + SQLite binary             |
| **Tool support**               | Claude Code, Codex CLI |            API only             |       API only        |    LangGraph only     | Claude, Codex, Cursor, Copilot, Gemini + 6 more | Claude Code, Codex CLI, Gemini CLI, MCP-compatible |

Markdown-in-the-repo won — `AGENTS.md` already appears in ~20k public repos. CLAUDART makes the convention structured and adds the workflow around it: orientation, planning, learning, hygiene, and review.

## License

MIT. See [`LICENSE`](LICENSE). Contributions welcome — see [`CONTRIBUTING.md`](CONTRIBUTING.md).

---

<div align="center">
  <i>Built for the future of AI-assisted development.</i>
</div>
