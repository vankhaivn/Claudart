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

**CLAUDART** (a portmanteau of **CLAUDE** and **SMART**) is a universal project template that supercharges your AI-assisted workflow from day one. Instead of starting from scratch, CLAUDART gives every project a "brain" — a Modular Rules System, opinionated review agents, and a built-in self-learning loop tuned to your codebase.

It scales from a small side project to a large team repo, acting as your intelligent pair programmer and project memory.

## Key Features

- **Modular Rules System** — root `CLAUDE.md` stays a lightweight index; domain rules live in path-scoped files under `.claude/rules/`.
- **Built-in Review Agents** — `clean-code-reviewer` (scope discipline + Clean Code + project conventions) and `secure-reviewer` (read-only OWASP audit) ship out of the box.
- **Continuous Self-Learning** — `/learn` re-reads the rule set, runs a retrospective on the just-completed work, and updates the rules so the same mistake never repeats.
- **Health Check Built In** — `/doctor` validates that your installation is wired correctly: YAML frontmatter, rule path coverage, AI-behavior import, agent overlap.

## Getting Started

To equip your project with CLAUDART, you do **not** need to clone this entire repository — only the `.claude/` directory.

1. From a fresh CLAUDART checkout, copy `.claude/` into the root of your project.
2. Open the project in Claude Code (or any compatible AI IDE).
3. (Optional) Run the built-in `/init` to let Claude Code generate a starter `CLAUDE.md` from your codebase.
4. Run `/refactor-memory` to extract domain rules into `.claude/rules/` and wire up the universal AI-behavior guidelines.
5. Run `/doctor` to verify the installation is healthy.

By copying only `.claude/`, your project stays free of CLAUDART's own README, license, and changelog.

## Core Commands & Workflow

### `/init` *(built-in to Claude Code, not CLAUDART)*

The standard Claude Code command. Scans the repo and generates a starter `CLAUDE.md`. CLAUDART does **not** override this — we deliberately reuse the built-in so you stay aligned with upstream Claude Code defaults. After running it, hand off to `/refactor-memory`.

### `/refactor-memory`

The CLAUDART-specific consolidator. Run this any time `CLAUDE.md`, `.claude/rules/`, or `.claude/agents/` need a sweep.

- Extracts domain-specific logic from a bloated `CLAUDE.md` into 2–4 path-scoped files in `.claude/rules/`.
- Trims root `CLAUDE.md` to a < 100-line index.
- Wires in `.claude/rules/ai-behavior.md` (universal Karpathy-derived guardrails) via `@` import.
- **Audits existing rule files and agents** to enforce the same standards: valid YAML frontmatter, no inlined code snippets, no stale metadata, no >50% overlap between agents.
- Relies on git for rollback — CLAUDART intentionally creates no separate backup files. Commit before running.

### `/learn`

Run this after completing a complex feature, fixing a tricky bug, or adopting a new pattern. The agent will:

1. **Re-read** the entire rule set (`CLAUDE.md` + `.claude/rules/*.md` + relevant agents).
2. Run a retrospective: name every deviation and the rationalization that justified it.
3. Patch the rules with `NEVER X, even when Y` framing to close the loophole.
4. Save quiet confirmations too — when the human accepted an unusual judgment call, that's a validated approach worth recording.

### `/doctor`

A read-only health check. Reports broken YAML frontmatter, dead rule paths (globs matching zero files), missing AI-behavior wiring, isolated rule files (not cross-linked from `CLAUDE.md`), inlined code snippets in rules, and overlapping agent triggers. Never modifies files — diagnostic only.

## Recommended Workflow

```text
new project              maintenance loop
─────────────            ────────────────
/init                    work on a feature/bug
  ↓                        ↓
copy .claude/            /learn   (capture new patterns)
  ↓                        ↓
/refactor-memory         /refactor-memory   (occasionally, to consolidate)
  ↓                        ↓
/doctor                  /doctor   (whenever something feels off)
```

## Directory Layout

```text
.claude/
├── agents/
│   ├── clean-code-reviewer.md   # PROACTIVE: scope + Clean Code + project conventions
│   └── secure-reviewer.md       # PROACTIVE: read-only OWASP-focused audit
├── commands/
│   ├── doctor.md                # /doctor — read-only health check
│   ├── learn.md                 # /learn — retrospective + rule refinement
│   └── refactor-memory.md       # /refactor-memory — consolidate CLAUDE.md + rules + agents
└── rules/
    └── ai-behavior.md           # Universal Karpathy-derived behavior guardrails
```

By keeping all AI assets version-controlled alongside your code, the entire team shares one standard of AI assistance.

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
