# CLAUDART Workflow Guide

[Tiếng Việt](WORKFLOW_VI.md) · [README](../README.md)

This guide explains how to use CLAUDART after it has been installed. It focuses on the operator workflow: how a session starts, where information belongs, when to create a task or specification, and how work is reviewed and resumed.

The exact machine-facing contracts remain in the runtime files themselves:

- Claude Code: `.claude/commands/` and `.claude/rules/`
- Codex: `.agents/skills/` and `.codex/guidelines/`

Those files are authoritative when a command schema or lifecycle detail changes.

## 1. Choose a runtime adapter

CLAUDART provides two runtime adapters over one shared `.claudart/` project-state directory.

| Runtime     | Installed files                                | Command form                             | Main loader |
| ----------- | ---------------------------------------------- | ---------------------------------------- | ----------- |
| Claude Code | `.claude/`, root `CLAUDE.md`                   | `/start`, `/plan`, and so on             | `CLAUDE.md` |
| Codex       | `.codex/`, `.agents/skills/`, root `AGENTS.md` | `$codex-start`, `$codex-plan`, and so on | `AGENTS.md` |

Install either layer or both. The workflows have the same intent, but their command and delegation files are written for the mechanics of each tool.

Every installation includes the shared state seeds. Both adapters include the same dependency-free Bash checker for `.claudart/knowledge/`. No database or background process is required.

Project Docs is an optional module. It adds a documentation-lifecycle command or skill only when selected during installation; the core workflow neither creates a documentation pack nor runs a full documentation audit automatically. Use it for a lifecycle request or when a change affects current documentation it owns.

## 2. Install or integrate

### New project

```bash
# Claude Code, the default
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash

# Codex
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --codex

# Both runtimes
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --both

# Add the optional Project Docs module to the selected layer or layers
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --claude --project-docs
```

The installer creates missing shared-state seeds and copies the selected adapter payload. It preserves existing `.claudart/` state and both root loaders even with `--force`; that flag refreshes adapter payload only. The default installation is core only; `--project-docs` adds the optional documentation-lifecycle module and never generates or migrates actual project docs. It is suitable for a clean installation, not for merging a customized setup.

On a clean installation, the installer places `.claude/CLAUDE.md` at root `CLAUDE.md` for Claude and `.codex/AGENTS.md` at root `AGENTS.md` for Codex, without installing duplicate adapter-local loaders.

### Existing project or upgrade

Use [INTEGRATE.md](../INTEGRATE.md). The integration protocol asks an agent to:

1. compare the current project with the current upstream repository;
2. identify unchanged files, stale CLAUDART templates, and project-authored customizations;
3. present a concrete add, replace, merge, move, or retire plan, including relevant optional-module recommendations for the user to select;
4. wait for approval before writing;
5. preserve live state, task workspaces and attachments, specification folders, and project knowledge;
6. run the current reconciliation checks after the approved changes.

A useful prompt is:

> Read https://raw.githubusercontent.com/vankhaivn/Claudart/main/INTEGRATE.md and follow it to integrate or update CLAUDART in this project. Preserve project-specific content and show me the proposed changes before writing them.

### Initial reconciliation

Follow the bounded mechanical verification in `INTEGRATE.md`. The shared `doctor-check.sh` baseline includes knowledge validation once. Run a full `/doctor` or `$codex-doctor` only when findings need semantic review or the user requests it. `refactor-memory` changes files and needs concrete scope and authorization; it is not an automatic next step. After an approved repair, verify the affected checks again.

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
user review when required, otherwise evidence-backed closure
```

### Start with orientation

Run `/start` or `$codex-start`. Both commands discover the same `.claudart/` work records. Changing runtime preserves scope, approvals, evidence and review gates; `agent` metadata is provenance, not permission.

Coordinate shared writes and use sequential handoff. Checkpoint retains unresolved work from other sessions. An unconsumed handoff is not silently overwritten, and consumption checks that the baton has not changed before deleting it. These workflows provide no atomic lock or automatic cross-checkout synchronization.

The start command reads:

- current state from `CONTEXT.md`;
- the task and specification indexes;
- the root knowledge index, not every knowledge topic;
- a small amount of recent Git history;
- an outstanding `HANDOFF.md`, when one exists.

It does not run the knowledge checker. Start is intended to be lightweight.

Every session also loads the owner working agreement in `OWNER.md`: Claude imports it from `CLAUDE.md`, and Codex reads it through `AGENTS.md` and at start.

The current request remains authoritative during startup. If it already names a task or specification to continue, or explicitly says to resume the unambiguous current focus, `start` completes the lightweight inventory and then enters that workflow without asking the user to select it again.

### Choose the right work mode

| Mode                           | Use it for                                                                                    | Persistence                                |
| ------------------------------ | --------------------------------------------------------------------------------------------- | ------------------------------------------ |
| Direct work                    | Small, clear, low-risk changes that do not need a durable plan                                | Conversation and normal repository history |
| Task plan                      | A bounded implementation needing durable decisions, interruption support, or a requested plan | `tasks/<task-id>/TASK.md`                  |
| Specification                  | A defined mission needing POC-frozen intent, phases, and standing approval                    | One folder in `specs/`                     |
| Project Docs module (optional) | Establish, adopt, update, audit, or compact current documentation                             | Existing documentation owners and router   |

File count alone does not require a plan. Needing JSON, an image, or an archive does not require a specification. A small explicit plan stays brief, with `TASK.md` only unless supporting files are actually needed.

A specification replaces task plans within its approved scope. Do not create task files for work already owned by an active specification. When product intent is still unclear, use Project Docs if installed to gather bootstrap input and establish only the current owners that are needed; it does not require a discovery pack or a `docs/project/` directory.

### Git persistence

CLAUDART allows verified, coherent **local commits by default** when no higher-scope runtime/user instruction, repository Git rule, or tool restriction prohibits them or requires another approval. Claude respects applicable higher-scope policy such as `~/.claude/CLAUDE.md` and `~/.claude/settings.json`; Codex respects applicable `~/.codex/AGENTS.md` and active approval/sandbox restrictions. A higher-scope requirement for explicit user approval remains binding until that approval is actually given.

Commit only owned in-scope changes after their relevant verification passes. Preserve unrelated work and stage explicit paths or hunks rather than broad staging. Commit messages and branch names follow repository conventions; CLAUDART does not add AI/tool co-author or generated-by attribution and does not create agent-branded namespaces such as `codex/*`, `claude/*`, or `agent/*`. Permission to make a local commit never implies permission to push, merge, rewrite history, create tags, or change Git configuration.

Task review remains a product/workflow gate, not a Git-persistence gate. User-reviewed tasks may already have a local restore-point commit when they reach `awaiting-review`; the user still owns final acceptance. Agent-reviewed tasks may close only when every acceptance criterion is objective, agent-observable, and proven with concrete evidence. Neither path grants push, merge, deploy, or other external authority. Subagents do not create history commits merely because work was delegated; the parent integrates, verifies, and persists their work under the same Git policy.

### End or pause cleanly

Use `/checkpoint` or `$codex-checkpoint` at a meaningful stopping point. Checkpoint rebuilds current state, synchronizes indexes, records retired history, and distills eligible durable facts.

Checkpoint follows that same Git workflow. When local commits are allowed, it persists the verified checkpoint-owned delta that is not already committed; when a higher-scope rule blocks the commit or safe staging is impossible, it leaves the worktree intact and reports that persistence is still required. A spec with `commits: user` remains an explicit no-auto-commit exception for its spec-owned changes.

Use `/handoff` or `$codex-handoff` only when a difficult investigation must continue in a fresh session. Handoff records the current hypothesis, evidence, failed approaches, constraints, and exact next step. It is not a general session summary.

## 4. Memory and knowledge

CLAUDART separates information by purpose and lifetime.

| Store                     | Contains                                                                                 | Does not contain                                  |
| ------------------------- | ---------------------------------------------------------------------------------------- | ------------------------------------------------- |
| `CONTEXT.md`              | Current facts needed to resume work now                                                  | Long history or stable reference material         |
| `OWNER.md`                | How the project owner wants to work: people, communication, approvals, mistakes to avoid | Code conventions, project facts, or secrets       |
| `JOURNAL.md`              | Compact history of retired state                                                         | Instructions that should load every session       |
| `rules/` or `guidelines/` | Prescriptive behavior: how the agent should work                                         | Descriptive project facts                         |
| `knowledge/`              | Durable, evidenced facts about the project                                               | Temporary plans, proposals, or unverified guesses |
| `tasks/`                  | State and decisions for one implementation task                                          | General project documentation                     |
| `specs/`                  | Approved intent and execution evidence for large work                                    | Unrelated tasks                                   |
| `HANDOFF.md`              | Reasoning needed by the next session                                                     | Permanent history                                 |

### Current state

`CONTEXT.md` is declarative: it describes what is true now. Checkpoint rewrites it rather than appending forever. The shipped rules keep it at no more than 150 lines.

`JOURNAL.md` is append-only and is not loaded automatically. It exists for audits and historical lookup without consuming normal session context.

### Owner profile

`OWNER.md` is the working agreement with the project owner. It records the owner and the people around the project, how to communicate with them, standing approvals and pacing, and mistakes to avoid.

An agent adds an entry as soon as the owner corrects how it works, states a standing preference or approval, or confirms a non-obvious way of working. Each entry is one line with its scope or exception and a date, and it holds only what the owner said or confirmed. The owner's statement is itself the request to record it, so an agent records it during review or planning work too, unless the owner, the repository, or the runtime forbids writes. A one-time approval never becomes a standing approval. Checkpoint records entries a session missed, and learn consolidates them. The file stays at 60 lines or fewer and never contains secrets or account identifiers.

The current instruction outranks the profile. An approval recorded there never widens a higher-scope, repository, or tool restriction.

### Durable knowledge

The knowledge store is descriptive. Typical topics include architecture, terminology, domain rules, external system contracts, and pointers to canonical documents. Keep one owner per claim: when source, schema, generated reference, project docs, or a team source already maintains it, knowledge links there instead of keeping a competing account. Evidence in source can still support a distinct, useful synthesis owned by knowledge.

A claim qualifies for knowledge capture or routing when it is:

1. supported by repository or user-provided evidence;
2. true now;
3. likely to remain useful after the current task ends;
4. routed to its existing owner, with a knowledge owner only when no other maintained source owns that claim.

Work in progress, proposed designs, and task-specific discoveries remain in the task, specification, or `CONTEXT.md` until they become durable.

A useful capture test is:

> Would this still be true and useful if the current task were cancelled tomorrow?

Shared project docs describe approved product intent, architecture, operating guidance, and supported capabilities under the repository’s own convention. Keep approved intent distinct from implemented or released behavior. The optional [Project Docs module](../modules/project-docs/README.md) supports their init/adopt, targeted update, read-only audit, and authorized compaction; task/spec records retain execution history.

For an established project, `adopt` retains valid current owners, including knowledge topics. A docs router can link to an existing architecture synthesis in knowledge; the subject or intended reader alone does not justify moving it. Reconcile only demonstrated gaps or overlap within the requested scope. A healthy setup may need no changes.

The module ships [actual output templates and filled examples](../modules/project-docs/README.md#output-templates-and-examples): router, product scope, capability behavior, architecture, development/testing, operations/release/support, and an optional significant-decision record. When creating or reshaping a page, select the relevant body and adapt it to existing owners and paths. A new idea may need only a product brief and router; do not generate empty technical or operational pages.

Behavior docs distinguish approved rules and quality expectations from actual behavior in the relevant commit or use scope. Link the pending delta to its task/spec and update affected owners as evidence becomes available. Compaction replaces superseded current claims and removes resolved pending summaries, preserving useful rationale and any still-supported versions without appending an edit diary.

Release is an optional delivery context, not a required project stage. An app used from `main` can document the evidenced revision and local run/check guidance without separate release notes, support tables, or an operations page. Continuous deployments use environment-specific evidence; teams with formal releases retain their actual approval, readiness, verification, recovery, and support requirements. Infer these needs from existing use and commitments, not personal/company labels. Audit does not treat missing formal release machinery as a defect by itself; real behavior or data problems still matter.

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

`sources` names the files that own or prove the topic's claims, not every file that was read. The checker warns when a topic lists more than 10.

The supported lifecycle states are:

- `active`: current, verified authority;
- `review-needed`: a claim that repository evidence should confirm is unverified, conflicting, or has drifted, and must be checked before use as authority;
- `superseded`: replaced by another topic;
- `retired`: intentionally historical.

A topic may end with a `## Point-in-time observations` section for dated observations of runtime or environment state that the repository cannot confirm. The lifecycle state and `last_verified` describe the rest of the topic; observations are leads to re-check, never authority.

The exact field grammar, routing limits, map thresholds, and mutation rules live in the runtime's `knowledge-management` rule or guideline.

### Validation

The shipped checker validates structure, routes, references, lifecycle fields, freshness anchors, and size or sensitivity budgets. It does not decide whether a statement is true.

Run it directly only when maintaining the knowledge store:

```bash
bash .claude/scripts/knowledge-check.sh --root .
bash .codex/scripts/knowledge-check.sh --root .
```

`refactor-memory` calls the knowledge checker after knowledge changes. `/doctor` and `$codex-doctor` use `doctor-check.sh`, which calls that checker once and adds selected-layer structure, metadata, explicit local-reference, and size checks. Do not run knowledge validation a second time after doctor.

For the mechanical baseline alone, run `bash .codex/scripts/doctor-check.sh --root . --layer codex` or its Claude counterpart. By default, it scans operating-layer Markdown; reference targets may be code or docs anywhere inside the repository. Add `--include docs` only when you want to scan project Markdown too. It checks target existence, skips examples and ambiguous path mentions, and never repairs files or decides semantic correctness. See [coverage, options, and exit statuses](../.codex/references/doctor-check.md).

## 5. Persistent task workflow

Use `/plan <task>` or `$codex-plan <task>` when the work should survive the current conversation.

The command creates `YYYY-MM-DD-NNN-<slug>/TASK.md` under `.claudart/tasks/`, using the UTC creation date and a daily sequence. `TASK.md` is the sole required file and authority for scope, status, steps, decisions, and acceptance. A useful task records:

- the user's request and observable purpose;
- relevant code, documents, and knowledge pointers;
- an ordered plan and one verification checkpoint per step;
- acceptance criteria;
- the completion reviewer (`user` or `agent`) and the reason that reviewer can observe the final acceptance surface;
- important decisions and rejected alternatives;
- discoveries that changed the plan;
- the final outcome and retrospective.

Reading `TASK.md` should explain the current state, decisions, and next action without the original chat. Keep it proportional: short findings stay inline, and sections with nothing relevant can say `None.`.

### User-facing plan brief

`TASK.md` is the durable execution and resumption record for agents; it is not the default approval interface for the user. The planning agent is responsible for translating the task into a short explanation instead of handing the file to the user and asking them to decode it.

When a plan is ready, `/plan` or `$codex-plan` presents a compact brief in the user's language covering:

- **Current state** — the problem or missing behavior now.
- **Desired outcome** — what should be true after the task.
- **Plan** — normally 3–5 plain-language steps that group lower-level implementation and verification work.
- **Review / approval** — who owns final acceptance, what the user will actually need to inspect at completion (if anything), and any unresolved decision needed before starting.

The brief should normally fit on one screen. Paths, timestamps, checkbox counts, command syntax, frontmatter, and other agent bookkeeping stay out unless they materially affect the user's decision. The task path may be shown after the brief as a reference, but “open/read/review `TASK.md`” is not the normal approval action.

For a planning-only request, ask for one clear approval signal after the brief. If execution was already authorized, show the brief and proceed without creating another approval gate. The brief is presentation only; `TASK.md` remains the source of truth.

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

### Completion reviewer

Every task records `reviewer: user | agent`.

Choose from the required decision or observation, not whether the result is visible. Use `user` for subjective judgment, a required environment the agent cannot inspect through authorized tools, an explicit human approval gate, or mixed human/machine acceptance. Clarify ambiguous ownership and retain `user` until resolved. Use `agent` when every criterion is objective, reproducible, directly observable, and verifiable with concrete evidence, with no human gate. For example, proving that a failed request releases a submit button can be agent-reviewed; deciding whether new copy feels reassuring belongs to the user.

Record the reviewer's basis and source. Do not add a generic "user confirms it works" criterion or ask the user to repeat evidenced QA. Missing objective checks remain agent work and keep the task active or blocked. Tests do not waive subjective acceptance or explicit approval.

Before closeout and when acceptance changes, verify that the reviewer matches the required acceptance and record changes with their source. Only the authority that owns an explicit human approval requirement may change it. Orientation, checkpoint, and doctor report task state without changing acceptance ownership.

### State machine

```text
planning ── user approves ──▶ in-progress
in-progress ── reviewer: agent + all acceptance proven ──▶ done
in-progress ── reviewer: user + agent validation complete ──▶ awaiting-review
awaiting-review ── user confirms ──▶ done
awaiting-review ── user reports a problem ──▶ in-progress
in-progress ── blocked ──▶ blocked
blocked ── blocker cleared ──▶ in-progress
any state ── user cancels ──▶ cancelled
```

`planning` and `awaiting-review` are write locks for source code:

- In `planning`, the agent may refine `TASK.md` and retain necessary notes, supplied inputs, or read-only evidence. Implementation is forbidden even inside `artifacts/`.
- In `awaiting-review`, the agent preserves the reviewed implementation and evidence while waiting for the user's concrete review surface. This state is for `reviewer: user`.
- A reported problem reopens the task and returns it to `in-progress`.

### Approval and completion

Approval is expressed in ordinary language. Clear phrases such as “go,” “implement,” or “approved” can start an approved plan. User-reviewed completion still needs a clear signal such as “looks good,” “confirmed,” or “close it.”

Resolve execution intent from the current message first, then from an earlier explicit instruction that is still applicable. A direct request to implement, start, continue, or resume satisfies `planning → in-progress`; the agent changes status before writing implementation and does not ask for the same authorization again. A request to create, explain, revise, or review the plan only keeps the planning lock.

Closeout depends on the recorded reviewer:

1. **`reviewer: user`:** finish all agent-verifiable work, including relevant failure cases, then move to `awaiting-review` with only genuine user acceptance unchecked. Present the actual reviewable result and access instructions, summarize completed checks and their limits, and ask for the precise outstanding judgment, unavailable observation, or reserved approval. For an environment only the user can access, provide the prepared result and targeted check steps. A chat summary or task-file link alone is not a handoff. User confirmation satisfies the remaining gate.
2. **`reviewer: agent`:** move directly from `in-progress` to `done` only when every criterion is still eligible and has current concrete evidence. Required checks must pass. Missing or stale objective proof keeps work active or blocked; a real user-only requirement changes the reviewer. Report the result and evidence without redundant confirmation.

A valid `done` task is archived as the whole directory under `tasks/done/<task-id>/` and the journal receives a compact record. Cancellation also preserves the whole workspace. Never overwrite an archive destination; workspace-relative attachment links survive the move. Praise, questions, silence, or manual task-file edits never remove a user review gate.

### Resuming later

Startup reads only task metadata. On resume, read `TASK.md`, then only the code and supporting files required for the next action. Check recorded evidence against current code, verify affected claims when needed, and record drift; do not replay every completed check just because the session changed. Report a missing required input rather than inventing a successful reproduction.

A task file is a resumable plan, not proof that the repository has remained unchanged.

## 6. Specification workflow

Use `/spec <mission>` or `$codex-spec <mission>` for a defined mission that needs shared approved intent, POC references, and a multi-phase execution roadmap—not merely because a task needs additional files. When a project or product is still undefined, the optional Project Docs module can gather bootstrap input before a mission is planned; ordinary open details inside an already-defined mission stay in the spec interview.

A specification workspace lives under:

```text
.claudart/specs/YYYY-MM-DD-<slug>/
.claudart/specs/YYYY-MM-DD-<slug>/
```

Each workspace contains:

| File         | Purpose                                                                        |
| ------------ | ------------------------------------------------------------------------------ |
| `SPEC.md`    | Approved intent, acceptance scenarios, scope limits, and commit cadence        |
| `ROADMAP.md` | Phases, executable work items, and a verification checkpoint for each item     |
| `NOTES.md`   | Curated working knowledge, decisions, constraints, and current acceptance gaps |
| `LEDGER.md`  | Append-only execution and validation evidence                                  |
| `artifacts/` | Approved proof-of-concept or reference artifacts                               |

### Planning and approval

The specification command is the authoring protocol. It interviews the user, records decisions in the workspace, may create proof-of-concept artifacts, and prepares a roadmap that can be executed without access to the original interview. It does not write the product implementation.

The user approves `SPEC.md` and `ROADMAP.md` once. That approval applies to the work inside the approved scope. It does not authorize unrelated refactoring or a change in product intent.

The approved specification also records its commit cadence. The default is `per-task`: after a ROADMAP task passes its `verify:` and its tick/evidence updates land, the executor creates a local restore-point commit when the shared Git policy permits it. `per-phase` waits for successful phase validation; `user` disables automatic commits for that spec. The cadence can narrow CLAUDART's normal local-commit behavior but never overrides a higher-scope prohibition, and none of these modes implies push.

Approval and execution intent are separate. Approval alone may leave the specification at `ready`. If the current message or an earlier still-applicable instruction also says to implement, run, continue, or resume after approval, the author hands directly to the spec runner in the same session. Starting a fresh session remains an option, not a requirement. A material change outside the approved intent still requires amendment and renewed approval.

### Execution

Run `/spec-run <slug>` or `$codex-spec-run <slug>` in the current or a later session.

At the first run, after session change or compaction, during crash recovery, or when drift is suspected, the runner reads `SPEC.md`, `ROADMAP.md`, and `NOTES.md` in full plus enough of the ledger tail to recover any open incident. During uninterrupted iterations it reloads only the selected task and dependencies, applicable acceptance and scope constraints, the current acceptance delta, and new ledger entries. The full workspace remains canonical; incremental reads avoid repeating unchanged context.

The loop then:

1. loads the boundary-appropriate canonical state described above;
2. selects the first runnable pending item;
3. implements and verifies it on an appropriate real surface;
4. updates the roadmap disposition;
5. appends evidence to the ledger;
6. records blockers with a concrete condition for resuming.

With the default `per-task` cadence, a verified task restore point is committed after the task's roadmap/evidence updates. `per-phase` commits only after the whole phase validation passes; `user` leaves spec commits to the user. All three modes remain subject to the shared Git authority and staging rules.

A failed check is retried only when the hypothesis, implementation, or verifier has materially changed. Repeating the same failed attempt is not progress.

At a useful boundary, the runner may offer checkpoint and rotation while reporting phase progress and the current acceptance delta. The offer is nonblocking: if the user declines or does not reply, authorized work continues. On acceptance, the specification workspace is the handoff; spec execution does not use `HANDOFF.md`. The workflow honors explicit user or runtime budgets and does not invent resource estimates, model tiers, attempt limits, or rotation thresholds.

### Final review

When all work is complete or explicitly superseded and no blocker remains, the executor runs the applicable acceptance gate. The first gate and a materially amended mission establish a full baseline with the smallest non-redundant fresh check set. After a bounded review change, a scoped gate runs fresh checks for the actual affected surface and direct dependents while carrying forward unaffected evidence with an explicit rationale; uncertainty falls back to a full baseline. Every scenario must have valid evidence before the specification moves to `awaiting-final-review`.

The user, not the agent, marks the specification done.

If review feedback changes only a bounded implementation detail, rerun the affected acceptance scenarios and any shared dependencies. If the impact cannot be defended, rerun the full gate. Feedback that changes intent or violates the approved scope requires a specification amendment and renewed approval.

## 7. Delegation and specialized agents

Delegation is optional. The active tool and repository instructions decide whether it is useful.

When work is delegated:

- split the request into non-overlapping units first;
- give each worker an explicit question or file scope;
- keep explorers read-only;
- give parallel writers disjoint ownership;
- treat inherited conversation context as host-dependent and include every required goal, constraint, and acceptance condition in the worker prompt;
- check whether the host shares a filesystem: on a shared filesystem, returned edits may already be present; in an isolated environment, integrate the returned patch or artifact explicitly;
- avoid doing the same investigation locally and in a worker unless independent cross-checking is intentional;
- integrate returned work in dependency order and validate each result;
- verify the affected surface and its relevant dependents rather than trusting a worker's completion claim;
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

| Claude Code                | Codex                            | Purpose                                                                                 |
| -------------------------- | -------------------------------- | --------------------------------------------------------------------------------------- |
| `/start`                   | `$codex-start`                   | Orient a session from current state, indexes, knowledge routing, and recent Git history |
| `/plan <task>`             | `$codex-plan <task>`             | Create a persistent implementation task                                                 |
| `/spec <mission>`          | `$codex-spec <mission>`          | Create and approve a multi-phase specification                                          |
| `/spec-run <slug>`         | `$codex-spec-run <slug>`         | Execute an approved specification to final review                                       |
| `/project-docs` (optional) | `$codex-project-docs` (optional) | Establish, adopt, update, audit, or compact current project documentation               |
| `/checkpoint`              | `$codex-checkpoint`              | Rebuild current state, synchronize indexes, and distill durable information             |
| `/handoff`                 | `$codex-handoff`                 | Preserve an unfinished investigation for the next session                               |
| `/learn`                   | `$codex-learn`                   | Promote recurring behavior into rules or guidelines                                     |
| `/doctor`                  | `$codex-doctor`                  | Run structural and semantic health checks                                               |
| `/refactor-memory`         | `$codex-refactor-memory`         | Normalize and reorganize the memory structure in place                                  |

## 9. Installed layout

A Claude installation centers on:

```text
.claudart/
├── CONTEXT.md
├── JOURNAL.md
├── OWNER.md
├── HANDOFF.md                  # Only when a handoff exists
├── knowledge/
│   └── INDEX.md
├── tasks/
│   ├── index.md
│   └── done/
└── specs/
    ├── INDEX.md
    └── done/
```

Claude Code adds its adapter:

```text
.claude/
├── CLAUDE.md
├── commands/
├── rules/
├── agents/
├── references/
└── scripts/
```

`HANDOFF.md` appears only between a handoff and the next start. Task workspaces, specification workspaces, knowledge topics, and maps are created as the project evolves. Installable task seeds contain no live tasks or example artifacts.

A Codex installation centers on:

```text
AGENTS.md
.agents/
└── skills/
.codex/
├── config.toml
├── agents/
├── guidelines/
├── references/
└── scripts/
```

In the CLAUDART source repository, `.codex/AGENTS.md` is the template used to create the root `AGENTS.md` during a clean installation.

When selected, Project Docs adds `.claude/commands/project-docs.md` with resources under `.claude/references/project-docs/` for Claude, and `.agents/skills/codex-project-docs/` for Codex. Output templates live under each resource root's `assets/templates/`; the template guide links filled examples. These resources guide documentation work but create no project docs by themselves.

## 10. Maintaining CLAUDART itself

Contributors should keep equivalent Claude and Codex behavior in sync where the concept applies to both runtimes. When a public command, file contract, or workflow changes, update both English and Vietnamese documentation.

Run the repository checks before opening a pull request:

```bash
npm ci
npm run check
```

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution rules and [INTEGRATE.md](../INTEGRATE.md) for downstream upgrades.
