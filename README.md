<div align="center">
  <h1>CLAUDART</h1>
  <p><strong>A markdown operating layer for Claude Code &amp; Codex CLI — memory, plans, and review, all in git.</strong></p>

  <p>
    <a href="https://github.com/vankhaivn/Claudart/blob/main/LICENSE"><img alt="License" src="https://img.shields.io/github/license/vankhaivn/Claudart?style=for-the-badge&color=orange"></a>
    <img alt="Pure Markdown" src="https://img.shields.io/badge/memory-pure_markdown-blue?style=for-the-badge">
    <img alt="Offline-friendly" src="https://img.shields.io/badge/works-offline-green?style=for-the-badge">
    <a href="https://github.com/vankhaivn/Claudart/issues"><img alt="Issues" src="https://img.shields.io/github/issues/vankhaivn/Claudart?style=for-the-badge&color=blue"></a>
  </p>
</div>

---

Coding agents forget. Close the terminal and the plan is gone. The next session starts blind, re-reads half the repo, and re-litigates a decision you settled last Tuesday. Meanwhile `CLAUDE.md` keeps growing, because nobody trusts it enough to delete anything from it.

CLAUDART deals with this using files. A handful of slash commands maintain a small set of markdown documents under `.claude/` and `.codex/`: what's true right now, the plan for each task, the facts and rules worth keeping. Everything is committed to git, reviewable in a PR, and readable without any tooling. There is no vector database and no daemon. Nothing to host, nothing to babysit.

## Install

```bash
# Flag after `bash -s --`:  --claude (default) · --codex · --both · --force (overwrite)
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --claude
```

`install.sh` does a fresh copy, which is the wrong move for a project that already has its own setup. In that case, paste this into your agent instead. It reads the repo, diffs against your project, and merges only what you approve:

> Read https://raw.githubusercontent.com/vankhaivn/Claudart/main/INTEGRATE.md and follow it to integrate CLAUDART into this project. Ask me before touching anything I've customized.

Existing installations use `INTEGRATE.md` to derive their actual delta against current upstream instead of assuming a starting release. For the knowledge contract currently declared upstream, reconciliation runs `doctor → refactor-memory → doctor`; no additional recall or migration command is part of that workflow.

## What it solves

| Pain                                          | What CLAUDART does about it                                                                          |
| --------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| Every session starts blind                    | `/start` reads the current state, open tasks, and recent commits before touching anything            |
| Plans die when the session closes             | `/plan` writes the plan to a task file that any later session can pick up where you left off         |
| A mission is too big for one session or plan  | `/spec` freezes the intent in a POC + roadmap you approve once; `/spec-run` loops it to final review |
| A productive session hits the context ceiling | `/handoff` saves the session's reasoning — hypothesis, evidence, dead ends — for the next `/start`   |
| The same decisions get re-discovered weekly   | `/learn` turns recurring behavior corrections into path-scoped rules                                 |
| Durable facts have nowhere to live            | `knowledge/` maps them; the agent loads the matching map, topic outline, then only relevant sections |
| `CLAUDE.md` bloats into a token sink          | `/refactor-memory` trims it back to an index and files the content where it belongs                  |
| Memory rots silently                          | `/doctor` runs a shipped read-only checker, then audits semantic drift and misfiled content          |

Three review agents ship alongside the commands — `clean-code-reviewer`, `security-auditor`, and `ui-visual-critic`, each invoked on explicit request only (never automatically, not even inside a task or spec loop) — plus a delegation protocol that keeps parallel subagent work bounded instead of letting it sprawl.

## The memory model

Four kinds of memory, four different lifetimes:

```text
SESSION STATE (volatile)                DURABLE REFERENCE (survives sessions)

CONTEXT.md       JOURNAL.md             rules/ · guidelines/   knowledge/
what's true now  what happened          how to behave          what the project is
(declarative)    (history log)          (prescriptive)         (descriptive facts)

always loaded    never loaded           auto-loads on          INDEX on /start,
in context       (audit only)           a matching path        detail on demand
```

`/checkpoint` rebuilds `CONTEXT.md` at the end of a session, retires history to `JOURNAL.md`, and bulk-promotes remaining durable facts. It is not the only knowledge write boundary: during a long exploration, saying “update knowledge from what we just verified, then continue” triggers an immediate distillation pass. Verified, current project facts go to `knowledge/`; task/WIP/proposed state stays in its task, spec, or context; uncertain claims remain candidates unless evidence invalidates an existing owner, in which case that topic becomes `review-needed`; recurring behavior goes to rules through `/learn`.

Retrieval is map-first and bounded: root `INDEX.md`, at most the relevant domain maps, then topic frontmatter/outline and the smallest useful section. Full files and source-history search are fallbacks, not the default. `/doctor` and `/refactor-memory` call a dependency-free Bash checker internally; users do not add another command to normal prompts.

## Quick start

```bash
# In a project with CLAUDART installed
/start                          # orient the session
/plan add JWT middleware        # write a task file; the agent waits for your approval before coding
/spec build the demo game       # mission too big for one plan? interview → POC → roadmap, approved once
/spec-run demo-game             # fresh sessions execute the approved mission autonomously until final review
/handoff                        # context nearly full? save your reasoning, resume fresh with /start
/checkpoint                     # rebuild CONTEXT.md at session end
/learn                          # promote recurring decisions into rules
/doctor                         # health check when the setup feels off
```

Codex CLI runs the same flow with `$codex-` instead of `/` (e.g. `$codex-start`).

## Documentation

**[docs/WORKFLOW.md](docs/WORKFLOW.md)** is the manual — architecture, the full task lifecycle, every command, directory layout. This README is just the pitch.

## Comparison

|                                |        CLAUDART        |              Mem0               |          Zep          |        LangMem        |               Understand-Anything               |                     MemPalace                      |
| ------------------------------ | :--------------------: | :-----------------------------: | :-------------------: | :-------------------: | :---------------------------------------------: | :------------------------------------------------: |
| **Setup**                      |     `curl \| bash`     | vector DB + Docker + OpenAI key | Neo4j + managed cloud | PostgreSQL + pgvector |            `curl \| bash` or plugin             |            `pip install` + 300 MB model            |
| **Human-readable**             |           ✅           |               ❌                |          ❌           |          ❌           |               ⚠️ JSON + dashboard               |            ⚠️ verbatim text, binary DB             |
| **Works offline / air-gapped** |           ✅           |               ❌                |          ❌           |          ❌           |                 ❌ LLM required                 |                         ✅                         |
| **PR-reviewable memory**       |           ✅           |               ❌                |          ❌           |          ❌           |            ✅ JSON committed to git             |            ❌ ChromaDB + SQLite binary             |
| **Tool support**               | Claude Code, Codex CLI |            API only             |       API only        |    LangGraph only     | Claude, Codex, Cursor, Copilot, Gemini + 6 more | Claude Code, Codex CLI, Gemini CLI, MCP-compatible |

Plain markdown in the repo won this argument: `AGENTS.md` provides a versioned convention that multiple coding agents can share. CLAUDART builds the missing workflow on top of it — orientation, planning, learning, hygiene, and review.

## License

MIT, see [`LICENSE`](LICENSE). Contributions welcome; [`CONTRIBUTING.md`](CONTRIBUTING.md) has the ground rules.
