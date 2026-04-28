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

**CLAUDART** (a portmanteau of **CLAUDE** and **SMART**) is a universal project template that supercharges your AI-assisted workflow from day one. Instead of starting from scratch, CLAUDART gives every project a "brain" — a Modular Rules System, opinionated review agents, a session-handoff convention, and a built-in self-learning loop tuned to your codebase.

It scales from a small side project to a large team repo, acting as your intelligent pair programmer and project memory — with **zero external dependencies, no vector DBs, no plugins**. Just markdown files and slash commands.

## Key Features

- **Modular Rules System** — root `CLAUDE.md` stays a lightweight index; domain rules live in path-scoped files under `.claude/rules/`.
- **Built-in Review Agents** — `clean-code-reviewer` (scope discipline + Clean Code + project conventions) and `secure-reviewer` (read-only OWASP audit). Both ship with persistent `memory: user` so they accumulate stack-specific knowledge across sessions.
- **Session Handoff via `.claude/CONTEXT.md` + `.claude/JOURNAL.md`** — declarative current-state file (auto-pruned) plus an append-only audit log that is intentionally NOT loaded into sessions (no token cost).
- **Continuous Self-Learning** — `/learn` re-reads the rule set, runs a retrospective on the just-completed work, and promotes recurring patterns from JOURNAL into rules.
- **Health Check Built In** — `/doctor` validates that your installation is wired correctly: YAML frontmatter, rule path coverage, AI-behavior import, CONTEXT/JOURNAL hygiene, agent overlap.

## Getting Started

To equip your project with CLAUDART, copy the relevant files into your repo — no installation, no dependencies.

1. From a fresh CLAUDART checkout, copy `.claude/` into the root of your project. That's it — everything CLAUDART ships lives inside this single directory.
2. Open the project in Claude Code (or any compatible AI IDE).
3. (Optional) Run the built-in `/init` to let Claude Code generate a starter `CLAUDE.md` from your codebase.
4. Run `/refactor-memory` to extract domain rules into `.claude/rules/` and wire up `@.claude/CONTEXT.md` + AI-behavior guardrails.
5. Run `/doctor` to verify the installation is healthy.

## Core Commands & Workflow

### `/init` *(built-in to Claude Code, not CLAUDART)*

The standard Claude Code command. Scans the repo and generates a starter `CLAUDE.md`. CLAUDART does **not** override this — we deliberately reuse the built-in so you stay aligned with upstream Claude Code defaults. After running it, hand off to `/refactor-memory`.

### `/refactor-memory`

The CLAUDART-specific consolidator. Run this any time `CLAUDE.md`, `.claude/rules/`, or `.claude/agents/` need a sweep.

- Extracts domain-specific logic from a bloated `CLAUDE.md` into 2–4 path-scoped files in `.claude/rules/`.
- Trims root `CLAUDE.md` to a < 100-line index.
- Wires in `@.claude/CONTEXT.md` and `@.claude/rules/ai-behavior.md`. Strips any accidental `@.claude/JOURNAL.md` import (JOURNAL must never be loaded).
- **Audits existing rule files and agents** to enforce the same standards: valid YAML frontmatter, no inlined code snippets, no stale metadata, no >50% overlap between agents, CONTEXT.md within its 150-line ceiling.
- Relies on git for rollback — CLAUDART intentionally creates no separate backup files. Commit before running.

### `/checkpoint`

End-of-session command. Updates `.claude/CONTEXT.md` to reflect the **current** state of work and appends graduated items to `.claude/JOURNAL.md`. Designed to prevent unbounded growth:

- **Declarative overwrite** — `.claude/CONTEXT.md` is rebuilt each run, not appended. Anything no longer true is removed.
- **Hard 150-line ceiling** — the command refuses to write a CONTEXT.md that exceeds 150 lines, forcing you to trim or graduate.
- **Append to JOURNAL on graduation** — when an item is dropped because it was *decided/completed/pivoted*, one line goes to JOURNAL: `YYYY-MM-DD | <type> | <summary>`.
- **Skip JOURNAL when nothing meaningful happened** — no empty entries.

### `/learn`

Run this after completing a complex feature, fixing a tricky bug, or adopting a new pattern. The agent will:

1. **Re-read** the entire rule set (`CLAUDE.md` + `.claude/rules/*.md` + `.claude/CONTEXT.md` + relevant agents).
2. Run a retrospective: name every deviation and the rationalization that justified it.
3. Scan the **tail** of `.claude/JOURNAL.md` (last ~200 lines) for recurring decisions/pivots — repeating patterns are strong signals to **graduate** principles into `.claude/rules/`. JOURNAL is never full-read; that would burn tokens for no benefit.
4. Patch the rules with `NEVER X, even when Y` framing to close loopholes.
5. Save quiet confirmations too — when the human accepted an unusual judgment call, that's a validated approach worth recording.

`/learn` only writes to **rules and CLAUDE.md**. It never touches `.claude/CONTEXT.md` (that's `/checkpoint`'s job) or rewrites `JOURNAL.md` entries (append-only).

### `/doctor`

A read-only health check. Reports broken YAML frontmatter, dead rule paths (globs matching zero files), missing AI-behavior wiring, isolated rule files, inlined code snippets, agent overlap, oversized `.claude/CONTEXT.md`, and any accidental `@.claude/JOURNAL.md` imports. Uses spot-checks (`head`/`tail`/`wc -l`/`grep`) — never full-reads JOURNAL. Diagnostic only; never modifies files.

## Memory Architecture

CLAUDART uses **four files** plus Claude Code's native auto memory:

| File | Loaded? | Who writes | Lifetime |
|---|---|---|---|
| `CLAUDE.md` | Always | You | Project lifetime |
| `.claude/rules/*.md` | Always (or on path match) | You + `/learn` | Project lifetime |
| `.claude/CONTEXT.md` | Always (via `@import`) | `/checkpoint` | Live, declarative |
| `.claude/JOURNAL.md` | **Never** (intentional) | `/checkpoint` (append) | Forever (git history) |
| `~/.claude/projects/<hash>/memory/` | First 200 lines | Claude itself | Per-machine |

**Why no vector DB?** For a single-developer or small-team project, native markdown + git + path-scoped rules cover 90% of the value. Vector DB adds infrastructure overhead, sync costs, and lock-in — for marginal benefit on codebases under ~100k LOC. CLAUDART's `.claude/JOURNAL.md` is grep-friendly, plain text, and survives every tool transition.

## Recommended Workflow

```text
new project              daily loop
─────────────            ──────────
/init                    work on feature/bug
  ↓                        ↓
copy .claude/            /checkpoint   (end of session — update CONTEXT, log to JOURNAL)
  ↓                        ↓
/refactor-memory         /learn         (after meaningful changes — refine rules)
  ↓                        ↓
/doctor                  /refactor-memory   (occasionally — consolidate)
                           ↓
                         /doctor       (whenever something feels off)
```

## Directory Layout

```text
your-project/
├── CLAUDE.md                       # Lightweight index (< 100 lines after /refactor-memory)
└── .claude/
    ├── CONTEXT.md                  # Live state, declarative, ≤ 150 lines, @imported in CLAUDE.md
    ├── JOURNAL.md                  # Append-only audit log — NEVER @imported
    ├── agents/
    │   ├── clean-code-reviewer.md  # PROACTIVE: scope + Clean Code + project conventions
    │   └── secure-reviewer.md      # PROACTIVE: read-only OWASP-focused audit
    ├── commands/
    │   ├── checkpoint.md           # /checkpoint — declarative state update + JOURNAL append
    │   ├── doctor.md               # /doctor — read-only health check
    │   ├── learn.md                # /learn — retrospective + rule promotion
    │   └── refactor-memory.md      # /refactor-memory — consolidate CLAUDE.md + rules + agents
    └── rules/
        └── ai-behavior.md          # Universal Karpathy-derived behavior guardrails
```

Everything CLAUDART ships lives inside `.claude/` — copying that single directory bootstraps a new project entirely. The only file that lives at the repo root is `CLAUDE.md` (Claude Code's convention).

By keeping all AI assets version-controlled alongside your code, the entire team shares one standard of AI assistance.

## The Graduation Pipeline

CLAUDART's three knowledge stores serve different lifetimes:

```
ephemeral              medium-lived           permanent
─────────              ────────────           ─────────
.claude/CONTEXT.md  →  .claude/JOURNAL.md  →  .claude/rules/
("now")                ("happened")           ("always true")

   ↑                       ↑                       ↑
/checkpoint           /checkpoint              /learn
                                          (when JOURNAL tail
                                           shows the same
                                           decision ≥ 2 times)
```

A tactical note lives in `.claude/CONTEXT.md`. When `/checkpoint` retires it (decision settled, work merged), one line goes to `.claude/JOURNAL.md`. When `/learn` later spots the same decision recurring in the JOURNAL tail, it promotes the underlying principle into `.claude/rules/` — where it becomes loaded into every future session.

This pipeline keeps each layer small and on-purpose: `.claude/CONTEXT.md` doesn't bloat, `.claude/JOURNAL.md` stays grep-friendly, and `.claude/rules/` only contains principles that have proven their value.

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
