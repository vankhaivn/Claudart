# CLAUDART Workflow

The deep-dive companion to the [README](../README.md). Covers architecture, memory model, task lifecycle, commands, and directory layout.

## Contents

- [Two layers](#two-layers)
- [Memory model — the graduation pipeline](#memory-model--the-graduation-pipeline)
- [Persistent task workflow](#persistent-task-workflow)
  - [Task file structure](#task-file-structure)
  - [Status state machine](#status-state-machine)
  - [Two-phase completion gate](#two-phase-completion-gate)
  - [Approval signals](#approval-signals)
  - [Cross-session resumption](#cross-session-resumption)
- [Subagent delegation](#subagent-delegation)
- [Commands and skills](#commands-and-skills)
- [Directory layout](#directory-layout)

## Two layers

CLAUDART installs as two parallel layers in your project. Run them independently or side-by-side; both write to the same git history.

- **Claude layer** (`.claude/`) — slash commands, rules, review agents, session state
- **Codex layer** (`.codex/` + `.agents/skills/`) — guidelines, TOML subagents, repo skills

Every Claude command has a mirrored Codex skill, and the core memory and task lifecycle protocols are identical. Where the runtimes differ, the guidance adapts to each one: subagent delegation, for instance, ships on both layers — `.claude/rules/agent-delegation.md` for Claude's Agent tool and `.codex/guidelines/agent-delegation.md` for Codex's explorer/worker model.

## Memory model — the graduation pipeline

CLAUDART has these tiers of project memory, with explicit graduation between them:

```text
CONTEXT.md       JOURNAL.md          rules/ · guidelines/      knowledge/
("right now")    ("what happened")   ("how to behave")         ("what the project is")
```

- **`CONTEXT.md`** — declarative state, what is true _right now_. Updated by `/checkpoint` (Claude) or `$codex-checkpoint` (Codex). Hard ceiling: 150 lines.
- **`JOURNAL.md`** — append-only audit log. One line per retired item. **Never auto-loaded into session context** — it exists for explicit review, not active recall.
- **`rules/`** (Claude) and **`guidelines/`** (Codex) — durable, path-scoped **behavioral** rules (prescriptive — "how to behave"). Created when a pattern recurs enough that `/learn` (or `$codex-learn`) promotes it.
- **`knowledge/`** — durable **descriptive** project facts (domain, architecture, glossary) and pointers to canonical docs in other folders. The opposite axis from rules: rules prescribe, knowledge describes. One topic per file; only `knowledge/INDEX.md` is surfaced — by `/start` (or `$codex-start`) — and detail files are read on demand (map-not-encyclopedia). Reference external docs rather than duplicating them, so they never go stale-by-copy.

A note enters at `CONTEXT.md`. When it settles, one line graduates to `JOURNAL.md`. `/checkpoint` graduates durable **facts** to a `knowledge/` topic file (registered in `INDEX.md`); when a behavioral pattern recurs, `/learn` promotes it to a rule file. Only rules and `CONTEXT.md` are auto-loaded; knowledge is surfaced as an index and pulled on demand — the rest stay out of the working set unless explicitly invoked.

Knowledge is **maintained, not just accumulated**. `/doctor` is read-only and flags drift — stale facts, dead `sources:`/`related:` links, duplication across tiers, or content sitting in the wrong tier. `/refactor-memory` acts on those flags: it re-verifies each fact against the current code, consolidates duplicates, and moves content across the descriptive↔prescriptive boundary **both ways** (a fact misfiled as a rule → `knowledge/`; a rule that leaked into knowledge → back). Nothing is auto-deleted — drift is surfaced for you to confirm.

Across commands, knowledge has a clear lifecycle: `/start` **surfaces** the INDEX, `/checkpoint` **writes** new facts (including project-wide ones rescued from an archived task's Memory Hints), and `/refactor-memory` **seeds** an empty tier from your existing docs and routes extracted content by type — behavior → rules, facts → knowledge. Every entry carries a `sources:`/`verify:` anchor to the file it summarizes, so `/doctor` can check it instead of guessing.

## Persistent task workflow

Native plan mode (Shift+Tab in Claude Code, `/plan` in Codex CLI) keeps plans in chat. Close the terminal and the plan is gone; pause for a day and the context drifts away as other commits land.

CLAUDART replaces this with **persistent task documents** — one markdown file per task, in `.claude/tasks/` or `.codex/tasks/`, versioned in git.

```text
/plan <task>  →  tasks/<YYYY-MM-DD-NNN-slug>.md  →  tasks/done/<NNN-slug>.md  →  JOURNAL.md
 (create)         (lifecycle: planning → in-progress →    (archived after       (one-line record)
                  awaiting-review → done)                  user confirms)
```

### Task file structure

Each task file is **self-contained** — reading it alone is enough to resume work in a new session, even days later, even after unrelated commits have landed. Required sections:

- **Frontmatter** — `slug`, `status`, `created`, `updated`, `agent`, `tags`
- **Purpose** — who gains what, how to verify it works
- **Context & Orientation** — `Related Code`, `Related Docs`, and **`Memory Hints`** (free-form notes from this session to the next — the lifeline against context loss)
- **Plan of Work** — prose narrative of the sequence and rationale
- **Concrete Steps** — ordered checklist with UTC timestamps on completed items
- **Validation & Acceptance** — observable success criteria (commands, manual checks)
- **Decision Log** — non-obvious choices with rationale
- **Surprises & Discoveries** — where reality diverged from the plan
- **Outcomes & Retrospective** — filled at completion

The canonical schema and protocol live in [`.claude/rules/task-management.md`](../.claude/rules/task-management.md) and [`.codex/guidelines/task-management.md`](../.codex/guidelines/task-management.md).

### Status state machine

```text
planning ──(user approves)──▶ in-progress
in-progress ──(agent finishes)──▶ awaiting-review
awaiting-review ──(user confirms)──▶ done
awaiting-review ──(user reports problem)──▶ in-progress     ← back-edge
in-progress ──(blocker)──▶ blocked
blocked ──(cleared)──▶ in-progress
{any} ──(user cancels)──▶ cancelled
```

Two states are **read-only locks** — the agent may only touch the task file, never code:

- `planning` — drafting or awaiting approval to start
- `awaiting-review` — agent has reported completion; user hasn't verified

### Two-phase completion gate

Most agent workflows let the agent self-mark a task done — and you find the real bug after the green checkbox is already in JOURNAL. CLAUDART splits completion into two phases:

**Phase 1 — Agent reports** (`in-progress → awaiting-review`)

When all checkboxes are ticked, the agent fills draft Outcomes, flips status to `awaiting-review`, reports to you, and **stops**. No archive, no JOURNAL entry yet.

**Phase 2a — You confirm** (`awaiting-review → done`)

You verify the work for real — run the app, check the build, inspect the diff. Say "approved" / "looks good" / "ok đóng" — the agent runs the archive flow: move the file to `done/`, append a JOURNAL line, update the index.

**Phase 2b — You report a problem** (`awaiting-review → in-progress`)

Found a bug? Just say it. The agent appends your report verbatim to Surprises, un-checks the wrong steps, flips back to `in-progress`, and fixes. The cycle Phase 1 ↔ 2b may repeat — that's the system catching real bugs, not a failure.

### Approval signals

The agent watches for natural-language cues, not slash commands:

| Transition                      | What you say                                                                 |
| ------------------------------- | ---------------------------------------------------------------------------- |
| `planning → in-progress`        | "go", "approved", "implement", "do it", "ok làm đi", "start"                 |
| `awaiting-review → done`        | "approved", "confirmed", "looks good", "close it", "done", "ship", "ok đóng" |
| `awaiting-review → in-progress` | Any report of a problem — "didn't work", "broken", "missed X"                |
| `* → cancelled`                 | "cancel", "abandon", "drop this", "bỏ task"                                  |

Enthusiasm ("great!", "nice plan") is **not** approval. Edits you make to the task file are **not** approval. The signals are explicit and required.

## Cross-session resumption

A new session resuming a task:

1. Reads the entire task file (self-contained by design).
2. Verifies completed steps still hold against the **current** code — unrelated commits may have moved files or changed APIs.
3. Logs any drift in Surprises and asks you whether to adapt the plan or revisit prior steps.
4. Picks up the next unchecked step.

Memory Hints from previous sessions is the lifeline. Populate it generously when planning — every non-obvious constraint, library quirk, or pitfall discovered during exploration belongs there.

## Subagent delegation

Both layers can run subagents for parallel exploration, bounded implementation, review, and audit work. CLAUDART treats that capability as **explicitly authorized parallelism**, not an automatic response to large tasks — "be thorough" or "research deeply" is not authorization; "use subagents", "delegate this", or "parallelize with agents" is.

Each runtime gets a protocol written to its own mechanics — `.claude/rules/agent-delegation.md` (Claude's Agent tool) and `.codex/guidelines/agent-delegation.md` (Codex's explorer/worker model) — and they share one spine:

- **Decomposition gate** — before spawning, the parent separates the **critical path** (work to do locally now), **sidecar tasks** (bounded, parallel-safe), **ownership** (the exact read question or write scope per subagent), and a **merge plan** (how findings return). If the next step is blocked on the subtask, don't spawn — do it locally.
- **Delegate-and-consume vs. delegate-and-continue** — judged by task structure, not wording. If the delegated question _is_ the whole task, spawn and **wait** — don't shadow-run the same work in parallel. Fan out parallel agents only when the request splits into non-overlapping units; the tell is **overlap of the same sub-question** (if your next step answers what a subagent already owns, that's redundancy, not parallelism). Deliberate, disclosed redundancy is fine — independent review, or a hedge you authorized — but never a silent hedge because a tool felt risky.
- **Ownership discipline** — explorers stay read-only; workers need disjoint write scopes (Claude isolates parallel writers in their own git worktrees); reviewers and security auditors produce findings the parent still owns and validates. A subagent patch is never final without parent review.

Task documents persist the durable parts of delegation — authorization status, roles, ownership boundaries, findings, decisions, and validation outcomes — never transient thread ids. `/checkpoint` (or `$codex-checkpoint`) carries forward active delegation blockers in `CONTEXT.md`, but completed findings live in the task file and eventually `JOURNAL.md`.

## Commands and skills

| Claude Code          | Codex CLI                  | What it does                                                                                                                                                            |
| -------------------- | -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/start`             | `$codex-start`             | Lightweight session boot — reads CONTEXT, active tasks, the knowledge INDEX, and the last 3 git commits                                                                 |
| `/plan <task>`       | `$codex-plan <task>`       | Creates a persistent implementation plan in `tasks/` — replaces native plan mode                                                                                        |
| `/project-discovery` | `$codex-project-discovery` | Interview-first planning — turns rough ideas into project docs before any code                                                                                          |
| `/refactor-memory`   | `$codex-refactor-memory`   | Trims CLAUDE.md/AGENTS.md to a lean index; routes durable content by type (behavior → rules/guidelines, facts → knowledge); bootstraps + re-verifies the knowledge tier |
| `/checkpoint`        | `$codex-checkpoint`        | Declarative CONTEXT rebuild + `tasks/index.md` sync + JOURNAL append + durable facts → `knowledge/`                                                                     |
| `/learn`             | `$codex-learn`             | Retrospective — promotes recurring lessons into rules/guidelines with loophole-closing language                                                                         |
| `/doctor`            | `$codex-doctor`            | Read-only health check: structure, frontmatter, token hygiene, wiring, task & knowledge hygiene                                                                         |

Review agents ship with both layers: `clean-code-reviewer` (scope + Clean Code discipline) and `security-auditor` (OWASP audit — read-only on your code, but writes its findings to a `security-audit-<date>.md` report at the project root and prints only the summary to chat). Claude uses kebab-case Markdown agent names; Codex uses snake_case TOML `name` values.

Subagent delegation is governed by `.claude/rules/agent-delegation.md` (Claude) and `.codex/guidelines/agent-delegation.md` (Codex). The shipped Codex config (`.codex/config.toml`) keeps `[agents] max_depth = 1` and `max_threads = 6` (Codex's default) so downstream projects get useful parallelism without recursive fan-out.

## Directory layout

```text
your-project/
├── AGENTS.md                       # Codex root loader (copied from .codex/AGENTS.md on install)
├── .agents/
│   └── skills/                     # Codex repo skills (codex-start, codex-plan, codex-checkpoint, …)
├── .codex/
│   ├── AGENTS.md                   # Codex source template; copied to root AGENTS.md
│   ├── CONTEXT.md                  # Live state, declarative, ≤ 150 lines
│   ├── JOURNAL.md                  # Append-only audit log — never auto-loaded
│   ├── agents/                     # Codex TOML subagents
│   │   ├── clean-code-reviewer.toml
│   │   └── security-auditor.toml
│   ├── config.toml                 # Codex project defaults
│   ├── guidelines/                 # Codex-native semantic guidance
│   │   ├── ai-behavior.md
│   │   ├── agent-delegation.md
│   │   └── task-management.md
│   ├── knowledge/                  # Durable descriptive facts + external-doc pointers
│   │   └── INDEX.md                # Map surfaced by $codex-start; topic files read on demand
│   └── tasks/                      # Persistent implementation plans (one file per task)
│       ├── index.md                # Active + recently-done dashboard, ≤ 100 lines
│       └── done/                   # Archived completed/cancelled tasks
└── .claude/
    ├── CLAUDE.md                   # Lightweight index (< 100 lines)
    ├── CONTEXT.md                  # Live state, declarative, ≤ 150 lines
    ├── JOURNAL.md                  # Append-only audit log — never auto-loaded
    ├── agents/
    │   ├── clean-code-reviewer.md
    │   └── security-auditor.md
    ├── commands/                   # Slash command protocols
    ├── knowledge/                  # Durable descriptive facts + external-doc pointers
    │   └── INDEX.md                # Map surfaced by /start; topic files read on demand
    ├── rules/
    │   ├── agent-delegation.md
    │   ├── ai-behavior.md
    │   └── task-management.md
    └── tasks/                      # Persistent implementation plans (one file per task)
        ├── index.md                # Active + recently-done dashboard, ≤ 100 lines
        └── done/                   # Archived completed/cancelled tasks
```
