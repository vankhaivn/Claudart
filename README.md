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

> **The problem.** Working with AI coding agents leaks state in every direction: every session starts blind, plans die in chat, the same decisions are re-discovered every week, and `CLAUDE.md` / `AGENTS.md` accumulates until it's a token sink that nobody trusts.

CLAUDART is a small set of slash commands and a layered markdown memory model that turns ad-hoc agent use into a reproducible workflow. Everything is plain markdown under `.claude/` and `.codex/` — versioned in git, reviewable in PRs, readable offline. No vector DB. No daemon. No cloud account.

## Install

```bash
# Claude Code layer (default)
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --claude
```

```bash
# Codex layer
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --codex
```

```bash
# Both layers
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --both
```

```bash
# Overwrite existing files
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --force
```

### Or install with your agent (AI-native)

`install.sh` does a fresh copy — great for a clean project, but it will clobber an existing setup and can't tell you what changed on an upgrade. If you **already run your own agents/workflow**, or you're **upgrading from an older CLAUDART**, paste this into your Claude Code or Codex session instead. Your agent reads the repo, diffs it against your project, and merges — asking before it changes anything you've customized:

> Read https://raw.githubusercontent.com/vankhaivn/Claudart/main/INTEGRATE.md and follow it to integrate CLAUDART into this project. Ask me before touching anything I've customized.

## What it solves

| Pain when working with coding agents                                 | CLAUDART's answer                                                                                                                                           |
| -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Every session starts blind                                           | `/start` reads `CONTEXT.md` + active tasks + last 3 commits — instant orientation                                                                           |
| Plans die when the session closes                                    | `/plan <task>` writes a persistent doc in `tasks/` that survives any pause                                                                                  |
| Same decisions re-discovered every week                              | `/learn` graduates recurring patterns into durable `rules/` files that auto-load on relevant paths                                                          |
| Durable project facts have nowhere to live (not behavior, not state) | `knowledge/` holds descriptive facts — domain, architecture, glossary, pointers to external docs; `/start` surfaces the index so they survive every session |
| `CLAUDE.md` / `AGENTS.md` bloats and burns tokens                    | `/refactor-memory` extracts knowledge into scoped rules;                                                                                                    |
| Codex subagents get used inconsistently or too broadly               | `agent-delegation.md` makes parallel Codex work explicit, bounded, and parent-reviewed                                                                      |
| Agents drift off-scope; nobody catches it                            | `clean-code-reviewer` + `security-auditor` agents run on explicit review/audit or authorized delegation                                                     |
| Memory files drift silently — no way to spot rot                     | `/doctor` validates structure, frontmatter, token hygiene, and knowledge freshness end-to-end                                                               |
| Rough idea, no project skeleton yet                                  | `/project-discovery` interviews you into structured project docs before any code                                                                            |
| Other memory frameworks need vector DBs, Docker, cloud accounts      | Pure markdown. Works offline. PR-reviewable.                                                                                                                |

## The memory model

```text
SESSION STATE (volatile)                DURABLE REFERENCE (survives sessions)

CONTEXT.md       JOURNAL.md             rules/ · guidelines/   knowledge/
what's true now  what happened          how to behave          what the project is
(declarative)    (history log)          (prescriptive)         (descriptive facts)

always loaded    never loaded           auto-loads on          INDEX on /start,
in context       (audit only)           a matching path        detail on demand
```

`/checkpoint` rebuilds `CONTEXT.md` declaratively (hard 150-line ceiling), graduates retired items to `JOURNAL.md`, and writes durable **facts** (domain, architecture, external-doc pointers) into `knowledge/` topic files. `/learn` promotes recurring **behavior** into path-scoped rule files. The journal is audit history, kept out of the working context to save tokens (see the loading row above). Knowledge stays honest on its own loop — `/doctor` flags drift (stale facts, dead links, duplication), and `/refactor-memory` consolidates it and re-checks each fact against the code.

## Quick start

```bash
# In a project with CLAUDART installed
/start                          # orient the session
/plan add JWT middleware        # write a persistent task doc — agent waits for your approval before coding
/checkpoint                     # rebuild CONTEXT.md and sync state at end of session
/learn                          # graduate recurring decisions into durable rules
/doctor                         # health check whenever the setup feels off
```

Codex CLI: same flow, swap `/` for `$codex-` (e.g. `$codex-start`, `$codex-plan`).

Codex subagents are supported as an opt-in workflow. Tell Codex explicitly to use subagents, delegation, or parallel agents; CLAUDART then guides it to split critical-path work from sidecar explorers/workers, assign non-overlapping ownership, and persist durable results in task files.

## Documentation

**[docs/workflow.md](docs/workflow.md)** — architecture, memory model, full task lifecycle, every command and skill, directory layout. The README is the pitch; `workflow.md` is the manual.

## Comparison

|                                |                 CLAUDART                 |              Mem0               |          Zep          |        LangMem        |               Understand-Anything               |                     MemPalace                      |
| ------------------------------ | :--------------------------------------: | :-----------------------------: | :-------------------: | :-------------------: | :---------------------------------------------: | :------------------------------------------------: |
| **Setup**                      |              `curl \| bash`              | vector DB + Docker + OpenAI key | Neo4j + managed cloud | PostgreSQL + pgvector |            `curl \| bash` or plugin             |            `pip install` + 300 MB model            |
| **Human-readable**             |                    ✅                    |               ❌                |          ❌           |          ❌           |               ⚠️ JSON + dashboard               |            ⚠️ verbatim text, binary DB             |
| **Works offline / air-gapped** |                    ✅                    |               ❌                |          ❌           |          ❌           |                 ❌ LLM required                 |                         ✅                         |
| **PR-reviewable memory**       |                    ✅                    |               ❌                |          ❌           |          ❌           |            ✅ JSON committed to git             |            ❌ ChromaDB + SQLite binary             |
| **Tool support**               | Claude Code, Codex CLI, Cursor, Windsurf |            API only             |       API only        |    LangGraph only     | Claude, Codex, Cursor, Copilot, Gemini + 6 more | Claude Code, Codex CLI, Gemini CLI, MCP-compatible |

Every major coding tool converged on plain markdown in the repo — `AGENTS.md` already appears in ~20k public GitHub repos. CLAUDART makes the convention structured and adds the workflow pieces around it: orientation, planning, learning, hygiene checks, and code-review safety nets.

## License

MIT. See [`LICENSE`](LICENSE). Contributions welcome — see [`CONTRIBUTING.md`](CONTRIBUTING.md).

---

<div align="center">
  <i>Built for the future of AI-assisted development.</i>
</div>
