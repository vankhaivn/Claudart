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

**CLAUDART** (a portmanteau of **CLAUDE** and **SMART**) is a universal project template that supercharges your AI-assisted workflow from day one. Instead of starting from scratch, CLAUDART gives every project a "brain" — a Modular Rules System, opinionated review agents, a session-handoff convention, a sync contract for Claude/Codex, and a built-in self-learning loop tuned to your codebase.

It scales from a small side project to a large team repo, acting as your intelligent pair programmer and project memory — with **zero external dependencies, no vector DBs, no plugins**. Just markdown files and slash commands.

## Key Features

- **Modular Rules System** — `.claude/CLAUDE.md` and `.codex/CODEX.md` stay lightweight indexes; domain rules live in path-scoped files under `.claude/rules/` and `.codex/guidelines/`.
- **Built-in Review Agents** — `clean-code-reviewer` (scope discipline + Clean Code + project conventions) and `secure-reviewer` (read-only OWASP audit). Claude agents use `memory: user`; Codex agents ship as native TOML definitions with read-only sandboxing.
- **Project Discovery Interview** — `/project-discovery` and `$project-discovery` turn rough ideas into raw discovery notes plus a presentation-ready project documentation pack before any code is written.
- **Shared Session Handoff via `.claudart/CONTEXT.md` + `.claudart/JOURNAL.md`** — declarative current-state file (auto-pruned) plus an append-only audit log shared by Claude and Codex.
- **Claude/Codex Sync** — `/sync codex` and `$sync claude` translate rules, commands, skills, and agents between tool-native formats in your downstream project without duplicating shared state.
- **Continuous Self-Learning** — `/learn` re-reads the rule set, runs a retrospective on the just-completed work, and promotes recurring patterns from JOURNAL into rules.
- **Health Check Built In** — `/doctor` validates that your installation is wired correctly: YAML frontmatter, rule path coverage, AI-behavior import, CONTEXT/JOURNAL hygiene, agent overlap.

## Getting Started

To equip your project with CLAUDART, copy the relevant files into your repo — no installation, no dependencies.

1. From a fresh CLAUDART checkout, copy the AI layer you use into the root of your project:
   - Claude Code: copy `.claude/` and `.claudart/`.
   - Codex: copy `AGENTS.md`, `.codex/`, `.agents/`, and `.claudart/`.
   - Both: copy all of the above.
2. Open the project in Claude Code, Codex, or both.
3. If the idea is still vague, run `/project-discovery` or `$project-discovery` before writing code to create a raw discovery file and structured project docs.
4. (Optional) Run the built-in `/init` to let Claude Code generate a starter `CLAUDE.md` from your codebase.
5. If `/init` created a root `CLAUDE.md`, copy its generated project content into `.claude/CLAUDE.md`. CLAUDART keeps Claude memory inside `.claude/` so the AI layer stays versioned.
6. Run `/refactor-memory` to extract domain rules into `.claude/rules/` and wire up `@.claudart/CONTEXT.md` + AI-behavior guardrails.
7. Run `/doctor` to verify the installation is healthy.
8. If you also use Codex, copy the Codex-native files from this template rather than generating them from sync. Use `$sync claude` later only when your project-specific Claude side has changed and Codex should receive those changes.

For an older Claude-only project migrating to Codex for the first time, the intended flow is:

1. Keep the project's existing `.claude/` as-is.
2. Add `AGENTS.md`, `.codex/`, `.agents/`, and any missing `.claudart/` files from the new CLAUDART template.
3. Open Codex in that project and run `$sync claude`.
4. The first sync may overwrite the freshly copied generic Codex scaffold. That is expected bootstrap behavior, not a conflict.

## Core Commands & Workflow

Claude Code uses slash commands from `.claude/commands/`. Codex uses repo skills in `.agents/skills/` backed by full command specs in `.codex/commands/`: `$project-discovery`, `$codex-refactor-memory`, `$codex-checkpoint`, `$codex-learn`, `$codex-doctor`, and `$sync claude`.

### `/project-discovery` and `$project-discovery`

An interview-first planning command for the moment before a project has a real spec.

- Asks one high-leverage question at a time instead of dumping a long questionnaire.
- Keeps confirmed facts, assumptions, rejected options, open questions, domain language, and scope boundaries separate.
- Adapts depth: Lite for personal/local/family projects, Standard for internal or serious solo tools, Full for stakeholder handoff or public publishing.
- Writes `docs/project/00-raw-discovery.md` first, then creates the smallest useful structured documentation pack under `docs/project/`.
- Produces stakeholder-friendly docs such as an executive brief, product requirements, user journeys, domain language, technical brief, roadmap, risk register, presentation outline, and implementation-readiness gate.
- Does not start implementation code.

### `/init` *(built-in to Claude Code, not CLAUDART)*

The standard Claude Code command. Scans the repo and generates a starter `CLAUDE.md`. CLAUDART does **not** override this — we deliberately reuse the built-in so you stay aligned with upstream Claude Code defaults. After running it, copy the generated content into `.claude/CLAUDE.md`, then hand off to `/refactor-memory`.

### `/refactor-memory`

The CLAUDART-specific consolidator. Run this any time `.claude/CLAUDE.md`, `.claude/rules/`, or `.claude/agents/` need a sweep.

- Extracts domain-specific logic from a bloated `.claude/CLAUDE.md` into 2–4 path-scoped files in `.claude/rules/`.
- Trims `.claude/CLAUDE.md` to a < 100-line index.
- Wires in `@.claudart/CONTEXT.md` and `@.claude/rules/ai-behavior.md`. Strips any accidental `@.claudart/JOURNAL.md` import (JOURNAL must never be loaded).
- **Audits existing rule files and agents** to enforce the same standards: valid YAML frontmatter, no inlined code snippets, no stale metadata, no >50% overlap between agents, CONTEXT.md within its 150-line ceiling.
- Relies on git for rollback — CLAUDART intentionally creates no separate backup files. Commit before running.

### `/checkpoint`

End-of-session command. Updates `.claudart/CONTEXT.md` to reflect the **current** state of work and appends graduated items to `.claudart/JOURNAL.md`. Designed to prevent unbounded growth:

- **Declarative overwrite** — `.claudart/CONTEXT.md` is rebuilt each run, not appended. Anything no longer true is removed.
- **Hard 150-line ceiling** — the command refuses to write a CONTEXT.md that exceeds 150 lines, forcing you to trim or graduate.
- **Append to JOURNAL on graduation** — when an item is dropped because it was *decided/completed/pivoted*, one line goes to JOURNAL: `YYYY-MM-DD | <type> | <summary>`.
- **Skip JOURNAL when nothing meaningful happened** — no empty entries.

### `/learn`

Run this after completing a complex feature, fixing a tricky bug, or adopting a new pattern. The agent will:

1. **Re-read** the entire rule set (`.claude/CLAUDE.md` + `.claude/rules/*.md` + `.claudart/CONTEXT.md` + relevant agents).
2. Run a retrospective: name every deviation and the rationalization that justified it.
3. Scan the **tail** of `.claudart/JOURNAL.md` (last ~200 lines) for recurring decisions/pivots — repeating patterns are strong signals to **graduate** principles into `.claude/rules/`. JOURNAL is never full-read; that would burn tokens for no benefit.
4. Patch the rules with `NEVER X, even when Y` framing to close loopholes.
5. Save quiet confirmations too — when the human accepted an unusual judgment call, that's a validated approach worth recording.

`/learn` only writes to **rules and `.claude/CLAUDE.md`**. It never touches `.claudart/CONTEXT.md` (that's `/checkpoint`'s job) or rewrites `JOURNAL.md` entries (append-only).

### `/doctor`

A read-only health check. Reports broken YAML frontmatter, dead rule paths (globs matching zero files), missing AI-behavior wiring, isolated rule files, inlined code snippets, agent overlap, oversized `.claudart/CONTEXT.md`, and any accidental `@.claudart/JOURNAL.md` imports. Uses spot-checks (`head`/`tail`/`wc -l`/`grep`) — never full-reads JOURNAL. Diagnostic only; never modifies files.

### `/sync codex` and `$sync claude`

Directional snapshot sync between Claude Code and Codex. The argument is the source side:

- Claude Code: `/sync codex` reads Codex files and updates `.claude/`.
- Codex: `$sync claude` reads `.claude/` and updates `AGENTS.md`, `.codex/`, and `.agents/skills/`.
- Sync never uses `git diff` or commit history. It reads the current filesystem snapshot.
- Sync never copies `.claudart/CONTEXT.md` or `.claudart/JOURNAL.md`; both tools already share those files.
- First migration exception: if the Codex side is still just the generic CLAUDART scaffold you copied into an older Claude-only project, `$sync claude` should overwrite that scaffold and promote it into sync-managed Codex files.
- In this CLAUDART base template, sync is not the authoring workflow. Maintainers update `.claude` and `.codex/.agents` manually so both shipped layers remain first-class.

## Memory Architecture

CLAUDART uses **four files** plus Claude Code's native auto memory:

| File | Loaded? | Who writes | Lifetime |
|---|---|---|---|
| `.claude/CLAUDE.md` / `.codex/CODEX.md` / `AGENTS.md` | Always | You + learn/refactor; sync in downstream projects | Project lifetime |
| `.claude/rules/*.md` / `.codex/guidelines/*.md` | Always (or on path match) | You + learn/refactor; sync in downstream projects | Project lifetime |
| `.claudart/CONTEXT.md` | Always (via `@import`) | `/checkpoint` | Live, declarative |
| `.claudart/JOURNAL.md` | **Never** (intentional) | `/checkpoint` (append) | Forever (git history) |
| `~/.claude/projects/<hash>/memory/` | First 200 lines | Claude itself | Per-machine |

**Why no vector DB?** For a single-developer or small-team project, native markdown + git + path-scoped rules cover 90% of the value. Vector DB adds infrastructure overhead, sync costs, and lock-in — for marginal benefit on codebases under ~100k LOC. CLAUDART's `.claudart/JOURNAL.md` is grep-friendly, plain text, and survives every tool transition.

## Recommended Workflow

```text
new project              daily loop
─────────────            ──────────
/project-discovery       work on feature/bug
  ↓                        ↓
/init                    /checkpoint   (end of session — update CONTEXT, log to JOURNAL)
  ↓                        ↓
copy CLAUDE.md ->         /learn         (after meaningful changes — refine rules)
.claude/CLAUDE.md
  ↓                        ↓
/refactor-memory         /refactor-memory   (occasionally — consolidate)
  ↓                        ↓
/doctor                  /doctor       (whenever something feels off)
```

## Directory Layout

```text
your-project/
├── AGENTS.md                       # Codex root instructions
├── .agents/
│   └── skills/                     # Codex repo skills, including $sync
├── .claudart/
│   ├── CONTEXT.md                  # Shared live state, declarative, ≤ 150 lines, @imported in .claude/CLAUDE.md
│   ├── JOURNAL.md                  # Shared append-only audit log — NEVER @imported
│   └── sync-map.md                 # Runtime sync contract for downstream projects
├── .codex/
│   ├── CODEX.md                    # Codex-native lightweight index
│   ├── agents/                     # Codex TOML subagents
│   ├── commands/                   # Codex command specs used by skills
│   ├── config.toml                 # Codex project defaults
│   └── guidelines/                 # Codex-native semantic rules
└── .claude/
    ├── CLAUDE.md                   # Lightweight index (< 100 lines after /refactor-memory)
    ├── agents/
    │   ├── clean-code-reviewer.md  # PROACTIVE: scope + Clean Code + project conventions
    │   └── secure-reviewer.md      # PROACTIVE: read-only OWASP-focused audit
    ├── commands/
    │   ├── checkpoint.md           # /checkpoint — declarative state update + JOURNAL append
    │   ├── doctor.md               # /doctor — read-only health check
    │   ├── learn.md                # /learn — retrospective + rule promotion
    │   ├── project-discovery.md    # /project-discovery — interview rough ideas into project docs
    │   ├── refactor-memory.md      # /refactor-memory — consolidate .claude/CLAUDE.md + rules + agents
    │   └── sync.md                 # /sync codex — update Claude from Codex
    └── rules/
        └── ai-behavior.md          # Universal Karpathy-derived behavior guardrails
```

CLAUDART ships a Claude-specific layer in `.claude/`, a Codex-specific layer in `.codex/` plus `.agents/skills/`, and a shared memory core in `.claudart/`. If `/init` creates a root `CLAUDE.md`, copy its content into `.claude/CLAUDE.md` so project memory stays versioned with the CLAUDART layer.

By keeping all AI assets version-controlled alongside your code, the entire team shares one standard of AI assistance.

## The Graduation Pipeline

CLAUDART's three knowledge stores serve different lifetimes:

```
ephemeral              medium-lived           permanent
─────────              ────────────           ─────────
.claudart/CONTEXT.md  →  .claudart/JOURNAL.md  →  .claude/rules/
("now")                ("happened")           ("always true")

   ↑                       ↑                       ↑
/checkpoint           /checkpoint              /learn
                                          (when JOURNAL tail
                                           shows the same
                                           decision ≥ 2 times)
```

A tactical note lives in `.claudart/CONTEXT.md`. When `/checkpoint` retires it (decision settled, work merged), one line goes to `.claudart/JOURNAL.md`. When `/learn` later spots the same decision recurring in the JOURNAL tail, it promotes the underlying principle into `.claude/rules/` — where it becomes loaded into every future session.

This pipeline keeps each layer small and on-purpose: `.claudart/CONTEXT.md` doesn't bloat, `.claudart/JOURNAL.md` stays grep-friendly, and `.claude/rules/` only contains principles that have proven their value.

## Contributing

We want CLAUDART to be the standard for every modern AI-driven project. Contributions, issues, and feature requests are highly welcome.

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
