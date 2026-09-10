# CLAUDART Workflow Guide

[Tiếng Việt](WORKFLOW_VI.md) · [README](../README.md)

This guide explains how to use CLAUDART after it has been installed. It focuses on the operator workflow: how a session starts, where information belongs, when to create a task or specification, and how work is reviewed and resumed.

The exact machine-facing contracts remain in the runtime files themselves:

- Claude Code: `.claude/commands/` and `.claude/rules/`
- Codex CLI: `.agents/skills/` and `.codex/guidelines/`

Those files are authoritative when a command schema or lifecycle detail changes.

## 1. Choose a runtime layer

CLAUDART provides two independent layers.

| Runtime     | Installed files                                | Command form                             | Main loader         |
| ----------- | ---------------------------------------------- | ---------------------------------------- | ------------------- |
| Claude Code | `.claude/`                                     | `/start`, `/plan`, and so on             | `.claude/CLAUDE.md` |
| Codex CLI   | `.codex/`, `.agents/skills/`, root `AGENTS.md` | `$codex-start`, `$codex-plan`, and so on | `AGENTS.md`         |

Install either layer or both. The workflows have the same intent, but their command and delegation files are written for the mechanics of each tool.

Both layers include the same dependency-free Bash knowledge checker. No database or background process is required.

## 2. Install or integrate

### New project

```bash
# Claude Code, the default
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash

# Codex CLI
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --codex

# Both runtimes
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --both
```

The installer copies files that are missing and skips existing files unless `--force` is supplied. It is suitable for a clean installation, not for merging a customized setup.

On a clean Codex installation, the installer copies the source template `.codex/AGENTS.md` to `AGENTS.md` at the project root and removes the duplicate template copy.

### Existing project or upgrade

Use [INTEGRATE.md](../INTEGRATE.md). The integration protocol asks an agent to:

1. compare the current project with the current upstream repository;
2. identify unchanged files, stale CLAUDART templates, and project-authored customizations;
3. present a concrete add, replace, merge, move, or retire plan;
4. wait for approval before writing;
5. preserve live state, task workspaces and attachments, specification folders, and project knowledge;
6. run the current reconciliation checks after the approved changes.

A useful prompt is:

> Read https://raw.githubusercontent.com/vankhaivn/Claudart/main/INTEGRATE.md and follow it to integrate or update CLAUDART in this project. Preserve project-specific content and show me the proposed changes before writing them.

### Initial reconciliation

Run this sequence once after installation or upgrade:

```text
Claude: /doctor → /refactor-memory → /doctor
Codex:  $codex-doctor → $codex-refactor-memory → $codex-doctor
```

`doctor` checks structure and semantic consistency. `refactor-memory` normalizes the memory layout in place. A second `doctor` confirms that the resulting state is healthy.

## 3. A normal session

A typical session follows this shape:

```text
start
  ↓
choose direct work, a task plan, or a specification
  ↓
implement and verify
  ↓
handoff only if the investigation must continue in a fresh session
  ↓
checkpoint at a meaningful stopping point
  ↓
user review and closure
```

### Start with orientation

Run `/start` or `$codex-start`.

The start command reads:

- current state from `CONTEXT.md`;
- the task and specification indexes;
- the root knowledge index, not every knowledge topic;
- a small amount of recent Git history;
- an outstanding `HANDOFF.md`, when one exists.

It does not run the knowledge checker. Start is intended to be lightweight.

### Choose the right work mode

| Mode          | Use it for                                                                  | Persistence                                |
| ------------- | --------------------------------------------------------------------------- | ------------------------------------------ |
| Direct work   | Small, clear, low-risk changes that do not need a durable plan              | Conversation and normal repository history |
| Task plan     | Implementation needing a durable plan, meaningful decisions, or an explicit plan request       | `tasks/<task-id>/TASK.md`                       |
| Specification | Mission-scale work needing shared approved intent and a multi-phase execution roadmap | One folder in `specs/`                     |

File count alone does not require a plan. Needing JSON, an image, or an archive does not require a specification. A small explicit plan stays brief, with `TASK.md` only unless supporting files are actually needed.

A specification replaces task plans within its approved scope. Do not create task files for work already owned by an active specification.

### End or pause cleanly

Use `/checkpoint` or `$codex-checkpoint` at a meaningful stopping point. Checkpoint rebuilds current state, synchronizes indexes, records retired history, and distills eligible durable facts.

Use `/handoff` or `$codex-handoff` only when a difficult investigation must continue in a fresh session. Handoff records the current hypothesis, evidence, failed approaches, constraints, and exact next step. It is not a general session summary.

## 4. Memory and knowledge

CLAUDART separates information by purpose and lifetime.

| Store                     | Contains                                              | Does not contain                                  |
| ------------------------- | ----------------------------------------------------- | ------------------------------------------------- |
| `CONTEXT.md`              | Current facts needed to resume work now               | Long history or stable reference material         |
| `JOURNAL.md`              | Compact history of retired state                      | Instructions that should load every session       |
| `rules/` or `guidelines/` | Prescriptive behavior: how the agent should work      | Descriptive project facts                         |
| `knowledge/`              | Durable, evidenced facts about the project            | Temporary plans, proposals, or unverified guesses |
| `tasks/`                  | State and decisions for one implementation task       | General project documentation                     |
| `specs/`                  | Approved intent and execution evidence for large work | Unrelated tasks                                   |
| `HANDOFF.md`              | Reasoning needed by the next session                  | Permanent history                                 |

### Current state

`CONTEXT.md` is declarative: it describes what is true now. Checkpoint rewrites it rather than appending forever. The shipped rules keep it at no more than 150 lines.

`JOURNAL.md` is append-only and is not loaded automatically. It exists for audits and historical lookup without consuming normal session context.

### Durable knowledge

The knowledge store is descriptive. Typical topics include architecture, terminology, domain rules, external system contracts, and pointers to canonical documents.

A claim belongs in knowledge when it is:

1. supported by repository or user-provided evidence;
2. true now;
3. likely to remain useful after the current task ends;
4. placed under the topic that already owns that fact, when one exists.

Work in progress, proposed designs, and task-specific discoveries remain in the task, specification, or `CONTEXT.md` until they become durable.

A useful capture test is:

> Would this still be true and useful if the current task were cancelled tomorrow?

### Retrieval

Knowledge retrieval is map-first and bounded:

1. read the root `INDEX.md`;
2. follow only the relevant domain map or topics;
3. inspect topic metadata and headings;
4. read the smallest section that answers the question;
5. use bounded repository or Git search only when routed knowledge is insufficient.

Reading knowledge never changes it.

### Topic contract and lifecycle

Knowledge topics use constrained YAML-compatible front matter. The required fields are:

```yaml
---
name: example-topic
description: "What this topic owns."
type: domain
status: active
updated: YYYY-MM-DD
last_verified: YYYY-MM-DD
sources:
  - "../../docs/example.md"
---
```

The supported lifecycle states are:

- `active`: current, verified authority;
- `review-needed`: visible uncertainty or conflict that must be checked before use as authority;
- `superseded`: replaced by another topic;
- `retired`: intentionally historical.

The exact field grammar, routing limits, map thresholds, and mutation rules live in the runtime's `knowledge-management` rule or guideline.

### Validation

The shipped checker validates structure, routes, references, lifecycle fields, freshness anchors, and size or sensitivity budgets. It does not decide whether a statement is true.

Run it directly only when maintaining the knowledge store:

```bash
bash .claude/scripts/knowledge-check.sh --root .
bash .codex/scripts/knowledge-check.sh --root .
```

The normal `/doctor` and `/refactor-memory` commands call the relevant checker as part of their own workflows.

## 5. Persistent task workflow

Use `/plan <task>` or `$codex-plan <task>` when the work should survive the current conversation.

The command creates `YYYY-MM-DD-NNN-<slug>/TASK.md` under `.claude/tasks/` or `.codex/tasks/`, using the UTC creation date and a daily sequence. `TASK.md` is the sole required file and authority for scope, status, steps, decisions, and acceptance. A useful task records:

- the user's request and observable purpose;
- relevant code, documents, and knowledge pointers;
- an ordered plan and one verification checkpoint per step;
- acceptance criteria;
- important decisions and rejected alternatives;
- discoveries that changed the plan;
- the final outcome and retrospective.

Reading `TASK.md` should explain the current state, decisions, and next action without the original chat. Keep it proportional: short findings stay inline, and sections with nothing relevant can say `None.`.

### Supporting files only when needed

A complete default workspace is:

```text
tasks/YYYY-MM-DD-NNN-<slug>/
└── TASK.md
```

Create `artifacts/` only for a concrete native-format input/output, evidence needed for verification or resumption that a short summary cannot preserve, or substantial task-local research that would obscure the actionable plan. Link meaningful files under the optional `### Workspace Files` section, with their purpose and workspace-relative path. Keep decisions and conclusions in `TASK.md`.

For a button adjustment, do not create a mockup package by default. For an API tweak, do not save a JSON report merely because the API returns JSON. A supplied ZIP needed to reproduce an import bug, or measurements needed to compare performance, may justify retained files. Link existing canonical project files instead of copying them; permanent source, docs, assets, and regression fixtures stay in normal project locations.

This changes storage, not the task's execution model: no mandatory POC, interview loop, separate roadmap or ledger, repeated review, or session rotation. Run the smallest sufficient verification set plus mandatory repository checks; further work needs an observed failure, relevant change, acceptance gap, or user feedback.

Artifacts follow the downstream project's privacy, storage, and Git policies; saving one does not authorize committing it. Mark local-only dependencies and how to retrieve or reproduce required inputs. Do not auto-extract or execute archives, bulk-load attachments, or remove evidence on completion.

The directory format is the only current task contract. Downstream upgrades must adapt existing work deliberately; there is no flat-task compatibility path or automatic migration.

### State machine

```text
planning ── user approves ──▶ in-progress
in-progress ── agent finishes ──▶ awaiting-review
awaiting-review ── user confirms ──▶ done
awaiting-review ── user reports a problem ──▶ in-progress
in-progress ── blocked ──▶ blocked
blocked ── blocker cleared ──▶ in-progress
any state ── user cancels ──▶ cancelled
```

`planning` and `awaiting-review` are write locks for source code:

- In `planning`, the agent may refine `TASK.md` and retain necessary notes, supplied inputs, or read-only evidence. Implementation is forbidden even inside `artifacts/`.
- In `awaiting-review`, the agent preserves the reviewed implementation and evidence while waiting for the user's review.
- A reported problem reopens the task and returns it to `in-progress`.

### Approval and completion

Approval is expressed in ordinary language. Clear phrases such as “go,” “implement,” or “approved” can start an approved plan. Clear completion phrases such as “looks good,” “confirmed,” or “close it” allow the task to be archived.

Praise, questions, or manual edits to the task file are not treated as approval.

Completion has two distinct steps:

1. **Agent completion:** implementation and validation finish; status becomes `awaiting-review`.
2. **User confirmation:** the user reviews the result; the task moves to `done`, the entire directory moves to `tasks/done/<task-id>/`, and the journal receives a compact record. Cancellation also preserves the whole workspace. Never overwrite an archive destination; workspace-relative attachment links survive the move.

### Resuming later

Startup reads only task metadata. On resume, read `TASK.md`, then only the code and supporting files required for the next action. Check recorded evidence against current code, verify affected claims when needed, and record drift; do not replay every completed check just because the session changed. Report a missing required input rather than inventing a successful reproduction.

A task file is a resumable plan, not proof that the repository has remained unchanged.

## 6. Specification workflow

Use `/spec <mission>` or `$codex-spec <mission>` for mission-scale scope that needs shared approved intent and a multi-phase execution roadmap—not merely because a task needs additional files.

A specification workspace lives under:

```text
.claude/specs/YYYY-MM-DD-<slug>/
.codex/specs/YYYY-MM-DD-<slug>/
```

Each workspace contains:

| File         | Purpose                                                                        |
| ------------ | ------------------------------------------------------------------------------ |
| `SPEC.md`    | Approved intent, acceptance scenarios, scope limits, and commit policy         |
| `ROADMAP.md` | Phases, executable work items, and a verification checkpoint for each item     |
| `NOTES.md`   | Curated working knowledge, decisions, constraints, and current acceptance gaps |
| `LEDGER.md`  | Append-only execution and validation evidence                                  |
| `artifacts/` | Approved proof-of-concept or reference artifacts                               |

### Planning and approval

The specification command interviews the user, records decisions in the workspace, and may create proof-of-concept artifacts. It then prepares a roadmap that another session can execute without access to the original interview.

The user approves `SPEC.md` and `ROADMAP.md` once. That approval applies to the work inside the approved scope. It does not authorize unrelated refactoring or a change in product intent.

The approved specification also records the commit policy. The default is no automatic commits; pushing is never implied.

### Execution

Run `/spec-run <slug>` or `$codex-spec-run <slug>` in a fresh session when practical.

Each iteration:

1. re-orients from the specification files;
2. selects the first runnable pending item;
3. implements and verifies it on an appropriate real surface;
4. updates the roadmap disposition;
5. appends evidence to the ledger;
6. records blockers with a concrete condition for resuming.

A failed check is retried only when the hypothesis, implementation, or verifier has materially changed. Repeating the same failed attempt is not progress.

At phase boundaries, rotate to a fresh session when useful. The specification workspace is the handoff; spec execution does not use `HANDOFF.md`.

### Final review

When all work is complete or explicitly superseded and no blocker remains, the executor runs a fresh acceptance gate. Every acceptance scenario must have current evidence before the specification moves to `awaiting-final-review`.

The user, not the agent, marks the specification done.

If review feedback changes only a bounded implementation detail, rerun the affected acceptance scenarios and any shared dependencies. If the impact cannot be defended, rerun the full gate. Feedback that changes intent or violates the approved scope requires a specification amendment and renewed approval.

## 7. Delegation and specialized agents

Delegation is optional. The active tool and repository instructions decide whether it is useful.

When work is delegated:

- split the request into non-overlapping units first;
- give each worker an explicit question or file scope;
- keep explorers read-only;
- give parallel writers disjoint ownership;
- avoid doing the same investigation locally and in a worker unless independent cross-checking is intentional;
- integrate returned work in dependency order and validate each result;
- keep the parent agent responsible for the final outcome.

The project includes three explicit-request-only specialist agents:

| Agent               | Behavior                                                                                                                             |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| Clean-code reviewer | May make a scoped, behavior-preserving improvement and run relevant checks. Review-only mode is available when explicitly requested. |
| Security auditor    | Reads code, performs an evidence-based audit, and writes a dated report.                                                             |
| UI visual critic    | Reviews rendered visual output and reports actionable design findings.                                                               |

None of these agents runs automatically, including during task or specification execution.

The shipped Codex configuration limits concurrent subagent threads to six per session. Delegation remains one level deep unless the user explicitly requests recursion.

## 8. Command reference

| Claude Code          | Codex CLI                  | Purpose                                                                                 |
| -------------------- | -------------------------- | --------------------------------------------------------------------------------------- |
| `/start`             | `$codex-start`             | Orient a session from current state, indexes, knowledge routing, and recent Git history |
| `/plan <task>`       | `$codex-plan <task>`       | Create a persistent implementation task                                                 |
| `/spec <mission>`    | `$codex-spec <mission>`    | Create and approve a multi-phase specification                                          |
| `/spec-run <slug>`   | `$codex-spec-run <slug>`   | Execute an approved specification to final review                                       |
| `/project-discovery` | `$codex-project-discovery` | Turn a rough project idea into structured project documents                             |
| `/checkpoint`        | `$codex-checkpoint`        | Rebuild current state, synchronize indexes, and distill durable information             |
| `/handoff`           | `$codex-handoff`           | Preserve an unfinished investigation for the next session                               |
| `/learn`             | `$codex-learn`             | Promote recurring behavior into rules or guidelines                                     |
| `/doctor`            | `$codex-doctor`            | Run structural and semantic health checks                                               |
| `/refactor-memory`   | `$codex-refactor-memory`   | Normalize and reorganize the memory structure in place                                  |

## 9. Installed layout

A Claude installation centers on:

```text
.claude/
├── CLAUDE.md
├── CONTEXT.md
├── JOURNAL.md
├── commands/
├── agents/
├── rules/
├── knowledge/
│   └── INDEX.md
├── scripts/
├── tasks/
│   ├── index.md
│   └── done/
└── specs/
    └── INDEX.md
```

`HANDOFF.md` appears only between a handoff and the next start. Task workspaces, specification workspaces, knowledge topics, and maps are created as the project evolves. Installable task seeds contain no live tasks or example artifacts.

A Codex installation centers on:

```text
AGENTS.md
.agents/
└── skills/
.codex/
├── CONTEXT.md
├── JOURNAL.md
├── config.toml
├── agents/
├── guidelines/
├── knowledge/
│   └── INDEX.md
├── scripts/
├── tasks/
│   ├── index.md
│   └── done/
└── specs/
    └── INDEX.md
```

In the CLAUDART source repository, `.codex/AGENTS.md` is the template used to create the root `AGENTS.md` during a clean installation.

## 10. Maintaining CLAUDART itself

Contributors should keep equivalent Claude and Codex behavior in sync where the concept applies to both runtimes. When a public command, file contract, or workflow changes, update both English and Vietnamese documentation.

Run the repository checks before opening a pull request:

```bash
npm ci
npm run check
```

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution rules and [INTEGRATE.md](../INTEGRATE.md) for downstream upgrades.
