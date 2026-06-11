# CLAUDART Workflow

This is the manual. The [README](../README.md) is the pitch; this document explains how the pieces actually work — the two layers, the memory model, the task lifecycle, every command, and where each file lives.

## Contents

- [Two layers](#two-layers)
- [Memory model — the graduation pipeline](#memory-model--the-graduation-pipeline)
- [Session handoff — surviving a context overflow](#session-handoff--surviving-a-context-overflow)
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

CLAUDART installs as two parallel layers. They don't depend on each other — install one, or both, and the only thing they share is the git history they're committed to.

- **Claude layer** (`.claude/`): slash commands, rules, review agents, session state
- **Codex layer** (`.codex/` + `.agents/skills/`): guidelines, TOML subagents, repo skills

Every Claude command has a Codex skill that follows the same protocol. Where the two runtimes genuinely differ, the guidance differs with them. Subagent delegation, for example, is written twice on purpose: `.claude/rules/agent-delegation.md` speaks to Claude's Agent tool, `.codex/guidelines/agent-delegation.md` to Codex's explorer/worker model. Pretending they're the same tool would help nobody.

## Memory model — the graduation pipeline

Project memory is split by how long things stay true:

```text
CONTEXT.md       JOURNAL.md          rules/ · guidelines/      knowledge/
("right now")    ("what happened")   ("how to behave")         ("what the project is")
```

`CONTEXT.md` says what is true right now. `/checkpoint` (Codex: `$codex-checkpoint`) rewrites it at the end of a session — rewrites, not appends. When something stops being true it is removed, and the file has a hard ceiling of 150 lines to keep that honest.

`JOURNAL.md` is the archive: append-only, one line per retired item, and never loaded into a session. That sounds wasteful until you notice what it buys — history exists for the rare audit, not for burning tokens on every prompt.

`rules/` (Claude) and `guidelines/` (Codex) hold behavior: the prescriptive "always do X" patterns that earned a permanent place by recurring. `/learn` is how they get there.

`knowledge/` holds facts: what the project is, how it's wired, what the words mean. Rules prescribe, knowledge describes — keeping the two apart is what stops both from rotting. One topic per file, and only `knowledge/INDEX.md` is surfaced at session start; detail files wait until a task actually needs them. Where a canonical doc already exists elsewhere, a knowledge entry points at it instead of copying it, so it can't go stale by copy.

The graduation path: a note starts life in `CONTEXT.md`. If it settles into history, one line goes to `JOURNAL.md`. If it turns out to be a durable fact, `/checkpoint` files it under `knowledge/`. If it's a behavior worth repeating, `/learn` makes it a rule. Only `CONTEXT.md` and rules are auto-loaded — everything else waits to be asked.

None of this survives without maintenance, so two commands exist to fight rot. `/doctor` is read-only: it flags stale facts, dead `sources:`/`related:` links, duplicated content, and things filed in the wrong tier. `/refactor-memory` acts on those flags — it re-verifies each fact against the current code, consolidates duplicates, and moves content across the descriptive/prescriptive boundary in both directions (a fact hiding in a rule goes to `knowledge/`; a rule that leaked into knowledge goes back). Nothing is deleted automatically. Drift is surfaced; you decide.

One detail makes the checking possible at all: every knowledge entry carries a `sources:` or `verify:` anchor pointing at what it summarizes, so `/doctor` can test the claim instead of guessing at it.

## Session handoff — surviving a context overflow

The four tiers above store _project_ state. A session in the middle of a hard debug carries something else entirely: a working hypothesis, the evidence behind it, the approaches already tried and ruled out, the exact next move. That reasoning state dies when the context window fills. The native `/compact` will summarize it in place, but the summary is invisible, unreviewable, gone when the session ends, and locked to one tool.

`/handoff` (Codex: `$codex-handoff`) writes it to disk instead — one file, `.claude/HANDOFF.md` or `.codex/HANDOFF.md`, with a fixed schema: Objective, State of Play, Working Hypothesis, Evidence as `file:line` anchors, Dead Ends with the reason each was ruled out, User Constraints, Next Step, Open Questions.

Three rules keep the baton honest:

- The user's explicit constraints, their most recent request, and the quote showing where work stopped are kept word for word. Everything else is distilled. A handoff is never a transcript dump.
- The recorded next step must trace to the user's latest request, quote included, so the resuming session can't wander off onto a tangent.
- Durable content is routed out first — facts to `knowledge/`, task discoveries to the task file's Memory Hints. The baton keeps only the reasoning that has no durable home.

The lifecycle is deliberately short. Writing a new baton overwrites the old one. The next `/start` surfaces it, verifies its claims against the current code, and deletes it once the work is picked up. One file, one hop, never an archive — repeated summarization is cumulatively lossy, which is also why `/doctor` flags a baton left unconsumed for more than 7 days.

Handoff complements `/checkpoint` rather than replacing it. Checkpoint records what is true about the project; handoff records what the conversation was thinking. Reach for it when the window is nearly full or when you're pausing mid-investigation — not as a session-end ritual.

## Persistent task workflow

Native plan mode (Shift+Tab in Claude Code, `/plan` in Codex CLI) keeps plans in chat. Close the terminal and the plan is gone; pause for a day and the codebase drifts out from under it.

CLAUDART keeps plans in files instead — one markdown document per task, under `.claude/tasks/` or `.codex/tasks/`, versioned like everything else:

```text
/plan <task>  →  tasks/<YYYY-MM-DD-NNN-slug>.md  →  tasks/done/<NNN-slug>.md  →  JOURNAL.md
 (create)         (lifecycle: planning → in-progress →    (archived after       (one-line record)
                  awaiting-review → done)                  user confirms)
```

### Task file structure

A task file is written to be self-contained: reading it alone should be enough to resume the work days later, after unrelated commits have landed. The sections:

- **Frontmatter** — `slug`, `status`, `created`, `updated`, `agent`, `tags`
- **Purpose** — who gains what, and how to see it working
- **Context & Orientation** — `Related Code`, `Related Docs`, and `Memory Hints`
- **Plan of Work** — prose narrative of the sequence and why it's ordered that way
- **Concrete Steps** — ordered checklist, UTC timestamps on completed items
- **Validation & Acceptance** — observable success criteria (commands, manual checks)
- **Decision Log** — non-obvious choices, with the alternatives that were rejected
- **Surprises & Discoveries** — where reality diverged from the plan
- **Outcomes & Retrospective** — filled at completion

Memory Hints deserves a special mention: it's free-form notes from this session to the next, and it's the section that saves a future session from re-discovering the same constraint, the same library quirk, the same pitfall. When in doubt, write it down there.

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

Two of these states are read-only locks. In `planning` and in `awaiting-review`, the agent may edit the task file and nothing else — no code. `planning` means the plan hasn't been approved yet; `awaiting-review` means the agent believes it's done and you haven't said so.

### Two-phase completion gate

Most agent workflows let the agent grade its own homework, and you find the real bug after the green checkbox is already in the log. CLAUDART splits completion in two:

**Phase 1 — the agent reports** (`in-progress → awaiting-review`). When every checkbox is ticked, the agent drafts the Outcomes section, flips the status, tells you, and stops. No archive yet, no JOURNAL entry.

**Phase 2a — you confirm** (`awaiting-review → done`). You verify for real: run the app, check the build, read the diff. Say "approved" or "looks good" or "ok đóng", and the agent archives the task — file to `done/`, one line to JOURNAL, index updated.

**Phase 2b — you report a problem** (`awaiting-review → in-progress`). Found a bug? Just say it. Your report goes verbatim into Surprises & Discoveries, the wrong steps get unchecked, and the agent goes back to work. The Phase 1 ↔ 2b loop can repeat several times. That's the gate catching real bugs, not the system failing.

### Approval signals

The agent reads natural language, not slash commands:

| Transition                      | What you say                                                                 |
| ------------------------------- | ---------------------------------------------------------------------------- |
| `planning → in-progress`        | "go", "approved", "implement", "do it", "ok làm đi", "start"                 |
| `awaiting-review → done`        | "approved", "confirmed", "looks good", "close it", "done", "ship", "ok đóng" |
| `awaiting-review → in-progress` | Any report of a problem — "didn't work", "broken", "missed X"                |
| `* → cancelled`                 | "cancel", "abandon", "drop this", "bỏ task"                                  |

Enthusiasm is not approval — "nice plan!" keeps the task in `planning`. Neither are questions, and neither are edits you make to the task file yourself. The signals above are required.

### Cross-session resumption

A new session resuming a task:

1. Reads the entire task file. It's self-contained by design.
2. Checks that the completed steps still hold against the current code — unrelated commits may have moved files or changed APIs since.
3. Logs any drift in Surprises & Discoveries and asks whether to adapt the plan or revisit earlier steps.
4. Only then picks up the next unchecked step.

The file is a snapshot, not a guarantee. Verifying before continuing is what keeps a three-day-old plan from quietly executing against a codebase that no longer matches it.

## Subagent delegation

Both layers can fan work out to subagents — parallel exploration, bounded implementation, review, audits. CLAUDART treats this as authorized parallelism, never a default: "be thorough" doesn't spawn agents; "use subagents" does.

Each runtime gets a protocol written for its own mechanics (`.claude/rules/agent-delegation.md` for Claude's Agent tool, `.codex/guidelines/agent-delegation.md` for Codex's explorer/worker model). They share one spine:

- **A decomposition gate.** Before spawning anything, the parent writes down the critical path it will work locally, the bounded sidecar tasks that can run in parallel, exactly which files or questions each subagent owns, and how the results come back. If the next step is blocked on the subtask, there's nothing to parallelize — do it locally.
- **Delegate-and-consume vs. delegate-and-continue.** Judged by task structure, not by the user's wording. When the delegated question _is_ the whole task, spawn one agent and wait — running the same investigation yourself in parallel pays twice for one answer. Fan out only when the request splits into units that don't overlap. The reliable tell is overlap: if your own next step answers a question a subagent already owns, that's redundancy, not parallelism. Deliberate redundancy is fine when disclosed (independent cross-review, a hedge the user asked for); silent redundancy never is.
- **Ownership discipline.** Explorers stay read-only. Parallel writers get disjoint scopes — on Claude, each gets its own git worktree. Reviewer and auditor findings still belong to the parent, who validates before integrating. A subagent patch is never final without parent review.

What survives afterwards goes in the task document: who authorized what, the roles, the ownership boundaries, the findings, the validation outcomes. Never transient thread ids — `/checkpoint` carries active delegation blockers forward in `CONTEXT.md`, and completed findings live in the task file until they retire to `JOURNAL.md`.

## Commands and skills

| Claude Code          | Codex CLI                  | What it does                                                                                                                                                                                               |
| -------------------- | -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/start`             | `$codex-start`             | Lightweight session boot — reads CONTEXT, active tasks, the knowledge INDEX, and the last 3 git commits                                                                                                    |
| `/plan <task>`       | `$codex-plan <task>`       | Creates a persistent implementation plan in `tasks/` — replaces native plan mode                                                                                                                           |
| `/project-discovery` | `$codex-project-discovery` | Interview-first planning — turns rough ideas into project docs before any code                                                                                                                             |
| `/refactor-memory`   | `$codex-refactor-memory`   | Trims CLAUDE.md/AGENTS.md to a lean index; routes durable content by type (behavior → rules/guidelines, facts → knowledge); bootstraps + re-verifies the knowledge tier                                    |
| `/checkpoint`        | `$codex-checkpoint`        | Declarative CONTEXT rebuild + `tasks/index.md` sync + JOURNAL append + durable facts → `knowledge/`                                                                                                        |
| `/handoff`           | `$codex-handoff`           | Single-slot session baton (`HANDOFF.md`) distilling reasoning state — hypothesis, evidence, dead ends, anchored next step — when the context window is nearly full; consumed and deleted by the next start |
| `/learn`             | `$codex-learn`             | Retrospective — promotes recurring lessons into rules/guidelines with loophole-closing language                                                                                                            |
| `/doctor`            | `$codex-doctor`            | Read-only health check: structure, frontmatter, token hygiene, wiring, task & knowledge hygiene                                                                                                            |

Both layers also ship two review agents. `clean-code-reviewer` enforces scope and Clean Code discipline. `security-auditor` runs an OWASP-mapped audit — read-only on your code, writing its findings to a `security-audit-<date>.md` report at the project root and printing only the summary to chat. Claude names agents in kebab-case Markdown; Codex uses snake_case TOML `name` values.

The shipped Codex config (`.codex/config.toml`) keeps `[agents] max_depth = 1` and `max_threads = 6` — Codex's default — so a downstream project gets useful parallelism without a small request accidentally fanning out into recursive subagent trees.

## Directory layout

```text
your-project/
├── AGENTS.md                       # Codex root loader (copied from .codex/AGENTS.md on install)
├── .agents/
│   └── skills/                     # Codex repo skills (codex-start, codex-plan, codex-checkpoint, …)
├── .codex/
│   ├── AGENTS.md                   # Codex source template; copied to root AGENTS.md
│   ├── CONTEXT.md                  # Live state, declarative, ≤ 150 lines
│   ├── HANDOFF.md                  # Transient session baton — exists only between $codex-handoff and the next $codex-start
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
    ├── HANDOFF.md                  # Transient session baton — exists only between /handoff and the next /start
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
