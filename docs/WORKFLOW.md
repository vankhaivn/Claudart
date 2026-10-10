# CLAUDART Workflow Guide

[Tiếng Việt](WORKFLOW_VI.md) · [README](../README.md)

This guide explains how to work with CLAUDART once it is installed: what a session looks like, how big a piece of work should be, what you will be asked to review, and where information is kept.

It describes behavior, not every rule. The exact contracts the agent follows live in `.claude/rules/` and `.claude/commands/` (Claude Code) or `.codex/guidelines/` and `.agents/skills/` (Codex).

## 1. A normal session

```text
/cda-start  →  do the work  →  /cda-checkpoint
              │
              └─ stuck mid-investigation and out of context?  →  /cda-handoff
```

**Start.** `/cda-start` (or `$cda-start`) reads the current state in `CONTEXT.md`, the task and spec lists, the knowledge index, recent Git history, and any pending handoff. It is deliberately light; it does not read every file. If your message already names the task to continue, the agent goes straight to it.

**Work.** Ask for what you need. The agent picks the right size of work (see below).

**Checkpoint.** At a natural stopping point, `/cda-checkpoint` rewrites `CONTEXT.md`, updates the task and spec lists, moves old state into `JOURNAL.md`, and saves facts worth keeping as knowledge.

**Handoff.** Only for a hard investigation that must continue in a fresh session. `/cda-handoff` writes the current hypothesis, evidence, dead ends, and the exact next step to `HANDOFF.md`. The next `/cda-start` reads it and deletes it. It is not a session summary.

Claude Code and Codex read and write the same `.claudart/` folder, so you can switch tools between sessions. Use them one after another, not at the same time on the same files.

## 2. Pick the size of the work

| Mode               | Use it when                                                        | What gets saved                 |
| ------------------ | ------------------------------------------------------------------ | ------------------------------- |
| Just ask           | The change is small, clear, and low risk                           | Nothing extra; Git history only |
| Task (`/cda-plan`) | Work needs a plan that survives interruption, or you asked for one | One `TASK.md`                   |
| Spec (`/cda-spec`) | A whole mission with several phases that you approve once          | A folder in `.claudart/specs/`  |

Rules of thumb:

- Touching many files does not by itself need a plan.
- Needing an image, JSON, or ZIP does not by itself need a spec.
- Inside an active spec, no separate tasks are created.

## 3. Tasks

`/cda-plan <task>` creates `.claudart/tasks/YYYY-MM-DD-NNN-<slug>/TASK.md`. That one file holds the current state and next action, the goal, the steps with a check for each, the acceptance criteria, the decisions made, and the outcome. Extra files go in `artifacts/` only when they are really needed, such as a ZIP that reproduces a bug.

### What you see

You are not asked to read `TASK.md`. When the plan is ready, the agent gives you a short brief in your language:

- **Now:** the problem today.
- **After:** what will be true when done.
- **Plan:** three to five plain steps.
- **Review:** who signs off, and what you will need to look at.

If you only asked for a plan, the agent waits for your "go". If you already said "implement it", it starts right away.

### Who signs off

Every task says who reviews the result: you (`user`) or the agent (`agent`).

- **The agent** closes the task itself when every criterion can be checked objectively, for example "a failed request re-enables the submit button".
- **You** sign off when the result needs your judgment ("does this copy feel reassuring?"), a device or account the agent cannot reach, or when you asked for final approval.

When you are the reviewer, the agent finishes everything it can check, then stops and shows you the actual result and the one decision left for you. Say "looks good" or "close it" to finish, or describe the problem to reopen the task. Silence or praise does not close it.

### Lifecycle

```text
planning ──go──▶ in-progress ──agent proves all──▶ done
                     │
                     └──agent work finished──▶ awaiting-review ──you confirm──▶ done
                                                     └──you report a problem──▶ in-progress
```

A task can also be `blocked` or `cancelled`. Finished tasks move to `tasks/done/`; follow-up work after acceptance starts a new task. To resume later, name the task; the agent reads its `TASK.md` and only the files it needs next.

## 4. Specs for large work

`/cda-spec <mission>` interviews you, may build a small proof of concept, and writes a plan detailed enough to run without the original conversation. It does not write the product code.

| File         | Holds                                               |
| ------------ | --------------------------------------------------- |
| `SPEC.md`    | Approved intent, acceptance scenarios, scope limits |
| `ROADMAP.md` | Phases and work items, each with a check            |
| `NOTES.md`   | Decisions, constraints, open gaps                   |
| `LEDGER.md`  | Evidence log, append-only                           |
| `artifacts/` | Approved proof-of-concept files                     |

You approve `SPEC.md` and `ROADMAP.md` once. That approval covers all work inside the scope, but not unrelated changes or a change of intent; those need an amendment.

`/cda-spec-run <slug>` then works through the roadmap: implement, verify, record evidence, move on. A failed check is retried only after something real changes. At phase boundaries the agent may suggest a checkpoint or a fresh session; work continues if you don't answer.

When everything is done, the agent runs the acceptance checks and stops at `awaiting-final-review`. Only you mark the spec done.

## 5. Where information goes

| Store                     | Holds                                      | Does not hold                    |
| ------------------------- | ------------------------------------------ | -------------------------------- |
| `CONTEXT.md`              | What is true now, to resume work           | History, reference material      |
| `OWNER.md`                | How you want to work with the agent        | Code conventions, secrets        |
| `JOURNAL.md`              | Retired history (not loaded automatically) | Instructions                     |
| `rules/` or `guidelines/` | How the agent should behave                | Facts about the project          |
| `knowledge/`              | Durable, evidenced facts about the project | Plans, guesses, work in progress |
| `tasks/`, `specs/`        | Work in progress                           | General project documentation    |
| `HANDOFF.md`              | Reasoning for the next session only        | Anything permanent               |

**Owner profile.** When you correct the agent or state a lasting preference ("always answer in Vietnamese", "never push without asking"), it adds one dated line to `OWNER.md` and tells you. A one-time approval is never recorded as a standing one. Your current instruction always wins over the file.

**Knowledge.** A fact belongs in knowledge when it passes this test:

> Would this still be true and useful if the current task were cancelled tomorrow?

If the code, a schema, or a project doc already owns the fact, knowledge just links to it. The agent reads knowledge map-first: the root `INDEX.md`, then only the relevant topic and section. Reading never changes it.

**Checking it.** `/cda-doctor` runs a read-only structural check, then reviews meaning and consistency. To run just the knowledge checker:

```bash
bash .claude/scripts/knowledge-check.sh --root .
```

Use `.codex/scripts/` for Codex. The checker finds broken structure and links; it cannot tell whether a statement is true. `/cda-refactor-memory` reorganizes the store when it has grown messy.

## 6. Git

- The agent may make **local commits** of verified work, unless your global settings, the repository, or you say otherwise.
- It stages only the files it changed and never adds AI attribution or agent-named branches.
- It never pushes, merges, rebases, tags, or changes Git config without your explicit permission.
- A spec can set `commits: per-task` (default), `per-phase`, or `user` (no automatic commits).

## 7. Specialist agents

Three agents run only when you ask for them by name:

| Agent               | Does                                                        |
| ------------------- | ----------------------------------------------------------- |
| Clean-code reviewer | A scoped code-health review or behavior-preserving refactor |
| Security auditor    | A read-only security audit with a written report            |
| UI visual critic    | A review of rendered UI, slides, or other visual output     |

The main agent may also split work across helper agents when the tool supports it. It stays responsible for checking and integrating their results.

## 8. Project Docs (optional)

Installed with `--project-docs`. It adds `/cda-project-docs` (or `$cda-project-docs`) to create, adopt, update, audit, or tidy your project's own documentation, with templates and examples. It never runs on its own and never creates docs at install time. See the [module page](../modules/project-docs/README.md).

## 9. Commands

| Claude Code            | Codex                  | Purpose                                      |
| ---------------------- | ---------------------- | -------------------------------------------- |
| `/cda-start`           | `$cda-start`           | Orient a session                             |
| `/cda-plan <task>`     | `$cda-plan <task>`     | Create or resume a task                      |
| `/cda-spec <mission>`  | `$cda-spec <mission>`  | Create and approve a spec                    |
| `/cda-spec-run <slug>` | `$cda-spec-run <slug>` | Run an approved spec to final review         |
| `/cda-checkpoint`      | `$cda-checkpoint`      | Save current state and durable facts         |
| `/cda-handoff`         | `$cda-handoff`         | Pause a hard investigation for a new session |
| `/cda-learn`           | `$cda-learn`           | Turn a repeated lesson into a rule           |
| `/cda-doctor`          | `$cda-doctor`          | Health check                                 |
| `/cda-refactor-memory` | `$cda-refactor-memory` | Reorganize the memory store                  |
| `/cda-project-docs`    | `$cda-project-docs`    | Manage project documentation (optional)      |

## 10. Installed layout

```text
CLAUDE.md          # Claude Code loader
AGENTS.md          # Codex loader
.claudart/         # shared state: CONTEXT, OWNER, JOURNAL, knowledge/, tasks/, specs/
.claude/           # Claude Code: commands/, rules/, agents/, references/, scripts/
.codex/            # Codex: guidelines/, agents/, references/, scripts/, config.toml
.agents/skills/    # Codex skills
```

You get only the layers you installed. Tasks, specs, and knowledge topics appear as the project grows.

To upgrade an existing installation, use [INTEGRATE.md](../INTEGRATE.md). To contribute to CLAUDART itself, see [CONTRIBUTING.md](../CONTRIBUTING.md).
