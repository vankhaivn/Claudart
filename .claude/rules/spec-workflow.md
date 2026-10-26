---
paths: [".claude/skills/cda-spec*/SKILL.md"]
description: Dated mission-scale specs with standing approval, scoped context loading, owned execution state and evidence-driven verification through final user review.
when_to_use: Whenever the user invokes `/cda-spec` or `/cda-spec-run`, when a spec folder under `.claudart/specs/` is open or referenced, or when resuming mission-scale work that spans many sessions.
tags: [specs, loop-engineering, autonomy, cross-session, missions]
---

# Spec Workflow (Loop Engineering)

A spec is a mission that needs a frozen intent, a phased plan, standing approval and recovery across sessions. Use `/cda-task` for bounded work whose decisions fit one task workspace; use `/cda-project-docs`, when installed, for an undefined project needing current documentation. A spec replaces the task layer for its scope: its executor never creates matching `.claudart/tasks/` work.

Both runtimes use the same dated workspace under `.claudart/specs/`. Resume the same workspace regardless of its `agent` metadata; it records provenance, not ownership or permission. Changing runtimes preserves scope, approval, execution evidence and review gates. Serialize writes and re-read their owners before updating them.

## File Layout and Ownership

```text
.claudart/specs/
├── INDEX.md                    # Derived registry; SPEC metadata owns lifecycle.
├── done/                       # Archived done/cancelled missions.
└── YYYY-MM-DD-<slug>/
    ├── SPEC.md                 # Approved contract and mission metadata.
    ├── ROADMAP.md              # Current task dispositions, dependencies and acceptance gaps.
    ├── LEDGER.md               # Append-only observations and evidence.
    ├── NOTES.md                # Unresolved reasoning, pitfalls and source pointers.
    └── artifacts/              # Only concrete references or evidence the mission needs.
```

- The folder name is `<created>-<slug>`, with a slug of 2–5 lowercase kebab-case words. Never nest active specs.
- `/cda-spec-run` resolves either the dated folder id or its SPEC `slug`. An omitted argument selects the only active ready/running/blocked/review mission; ask only if several match. Report archived matches without executing them.
- One editable owner per fact: SPEC defines behavior, ROADMAP owns current execution state and the verification plan, LEDGER owns results and history, and NOTES keeps useful reasoning with no other owner. Link to existing architecture documents or runbooks instead of restating them.
- SPEC scenarios have stable IDs, not completion checkboxes. Update SPEC `updated:` only when its contract or lifecycle metadata changes; execution activity shows in ROADMAP and LEDGER.
- Use only these files for state. Add no other trackers, caches, checklists, resource estimates, attempt counters, model or rotation thresholds, or approval rounds. An optional acceptance or release report is a derived view with source references, never another authority.

## SPEC.md — approved intent

```markdown
---
slug: <kebab-slug>
status: drafting # drafting | poc-review | ready | running | blocked | awaiting-final-review | done | cancelled
created: YYYY-MM-DD
updated: YYYY-MM-DD
agent: claude # claude | codex | both
commits: per-task # per-task | per-phase | user
---

# <Mission Title>

## Mission

<2–3 self-contained sentences: end state, actors/public entrypoints, preserved boundaries.
Normalize confirmed intent; do not paste interview conversation.>

## Acceptance Scenarios

- S1 — <initial conditions; literal action/command> → <observable result>
- S2 — ...

## Must-NOT-Have

<Rejected/deferred scope and global constraints.>

## POC Artifacts

- `artifacts/<file>` — <observable aspects this approved reference locks in>

## Contract References

<Only when needed: link to additional contract sections and state their scope.
Existing headings and scenario IDs form the inventory; do not duplicate their bodies.>

## Definition of Done

All ROADMAP work completed or explicitly superseded, no unresolved blocker,
and every scenario supported by valid final-gate evidence. The user confirms done.
```

Each scenario must be observable by an executor without interview history. Split independently failing obligations into sub-IDs, but do not turn every assertion into a task or command.

Scenarios cover initial state. For each different first-use path, trace the minimum supported state through the real entrypoint to the first useful result; each fixture it needs has a supported creation path or an explicit external prerequisite. Cover first-use behavior that differs from later use, and controlled rejection, cancellation or recovery where they matter; an empty input need not succeed. Add no out-of-scope features or state matrix.

POC artifacts freeze only the aspects the user chose, such as interaction, appearance or protocol/output behavior. Use the smallest artifact that fits the interface, and confirm how it can be inspected before acceptance relies on it. Drafting may produce runnable POC artifacts inside the workspace, never a second full implementation, production code or scaffolding.

## ROADMAP.md — plan and current execution state

Write for an executor without interview context: boundaries, dependencies, contract and scenario references, approaches where they matter, and a `verify:` that names the behavior and its proving check rather than prescribing new tests. Give file paths when known or contractual; do not pre-solve internals. Plan Altitude from `task-management.md` applies.

```markdown
# ROADMAP — <Mission Title>

<Build order rationale and optional parallel waves; every ordering constraint is also a task's `depends:`.>

## Phase 1 — <name>

Goal: <observable milestone>

- [ ] P1.1 <action and ownership boundary> (contracts: <S#/section refs>; verify: <observable>)
- [ ] P1.2 <action> (depends: P1.1; contracts: <refs>; verify: <observable>)

**Phase validation:** <the commands or cases that prove the due scenario IDs, their prerequisites,
and the smallest non-redundant final verification set>

## Current Acceptance Delta

- None.
<!-- Or one line per gap: <S# or named gate>: <unresolved gap>; owner: <task-id>;
evidence: <LEDGER entry>; next: <action or NOTES hypothesis ref>.
A review back-edge also names its baseline gate and affected scenarios. -->
```

Task dispositions:

- `- [ ] <task>`: pending, runnable only when its dependencies are satisfied and it is not blocked.
- `- [x] <task>`: completed, backed by a `task-completed` evidence entry.
- `- [x] ~~<task>~~ — superseded by <task-id or short reason>`: terminal, backed by a `replanned` entry that holds the full reason.
- `- [ ] <task> — ⚠ blocked: <condition>; unlock: <required input/change>`: unresolved, skipped by selection and prevents final completion.
- Unchecked struck rows are invalid. Reconcile from evidence; ambiguous disposition becomes a blocker, never an assumed completion.

Size a task around one coherent observable and its proof. Phases yield observable progress early. Dependencies are acyclic; numbering does not make work runnable. Record every ordering constraint as `depends:`, including two tasks that write the same files; the build-order note explains and adds no order. Split a task whose parts wait on different dependencies. Order release work as software verification → rehearsal/readiness → separately authorized release/cutover → post-release observations, omitting stages outside approved scope. When acceptance depends on a real environment or a metered budget, rehearsal is its own task on the actual target that consumes none of that budget: it crosses every integration boundary the budgeted work will cross, such as startup, connectivity, persistence at the largest planned size and real latency, monitors, and rollback or restore of a no-op change, and budgeted work depends on it. A software gate never requires future live evidence, which stays pending with an owner, and release never waits for a gate that includes post-release checks.

The Current Acceptance Delta exists only in ROADMAP. It lists contradicted or unproven obligations and approved review changes, keyed by scenario or gate, and references LEDGER and NOTES instead of copying them. A review back-edge records the latest successful final-gate baseline and provisional impact, recomputed from the actual changed surface before verification. Only valid evidence clears a gap; reassigning its task does not.

The executor may add missing in-scope work and log it, supersede dead work explicitly, and reopen only the current task whose evidence was invalidated. A fix and its verification stay in that task; never append fix/replay task pairs.

## LEDGER.md — append-only evidence

```markdown
### YYYY-MM-DD HH:MMZ — <event> <task-id or scope>

- Evidence: <command/case or observation → result; scenario refs>
- Decision: <optional change and why; link to its current owner>
```

Events include `run-started`, `task-started`, `task-completed`, `validation-failed`, `phase-validated`, `task-blocked`, `replanned`, `delegated`, `circuit-breaker`, `rotation-checkpoint`, `scope-change` (user-initiated only), and `final-gate`. Never rewrite or delete historical entries. An entry is its header plus at most three short lines; `task-started` and `delegated` may be the header alone. Only gate entries add the fields below, one line each. Record what was done and observed, not lists of actions that were not taken. Store large outputs in artifacts and reference them.

Each successful gate records its resulting revision or bounded worktree fingerprint, actual environment or artifact, observed scenario coverage, and `executed`, `covered` and any `reused` evidence. For a dirty tree, give the base revision and changed-path/content digests, excluding secrets and unrelated user files. Record verifier, fixture/configuration and dependency state, reusing existing build/test identifiers.

A `final-gate` records `mode: full-baseline | scoped-review`. A full baseline records its reason: `initial`, `material-amendment` or `conservative-fallback`. A scoped review names the latest successful `final-gate` cumulative evidence state, the actual changed surface, newly observed coverage and why retained evidence still applies; its chain must reach an identifiable full baseline.

An unmatched `task-started` or `delegated` marks interrupted work. Find unresolved events by header and ID and inspect their bodies, including failures since the baseline; a fixed tail length does not prove that no work remains. Reconcile a result written before its ROADMAP update from evidence instead of repeating the operation. Recover an interrupt this way too; the user need not wait for a clean boundary.

## NOTES.md — unresolved working memory

```markdown
# NOTES — <Mission Title>

## Orientation

- <source/section> — <why the next task may need it>

## Pitfalls / Open Reasoning

- <task/scenario ref>: <unresolved hypothesis or unique execution trap; next distinguishing check>

## Candidates

- <uncertain or mission-local fact; source ref; optional graduation flag>
```

Keep notes declarative, curated and under 150 lines without packing paragraphs to fit. Remove resolved reasoning or move the fact to its owner, leaving a pointer when useful; never copy what another file owns. Load only the relevant notes. Flag durable descriptive candidates `→ graduate: knowledge/` and recurring behavior `→ graduate: /cda-learn`; a local scope does not disqualify a fact. Uncertainty stays here, not in canonical knowledge.

For a direct knowledge mutation, read `knowledge-management.md` and its maintenance reference; require the full capture gate and an immediate-promotion trigger. Update the existing owner and reachable map atomically, then run `bash .claude/scripts/knowledge-check.sh --root .`. Checkpoint bulk-maintains remaining flags.

## Standing Approval and Authority

The user approves SPEC + ROADMAP once. That standing approval replaces task, phase and delegation approval inside a running spec; do not create task-layer work or stop for intermediate review. Approval alone leaves the spec `ready`; an instruction to execute lets the same session enter `running` and stays valid until withdrawn. Approval never authorizes work beyond the approved scope or existing authority. A material scope change needs amendment and renewed approval.

`commits:` sets local commit cadence: `per-task` is the default and creates a verified task restore point, `per-phase` waits for phase validation, and `user` disables automatic commits. Follow `git-workflow.md` and higher-scope restrictions; this setting never grants push, history rewrite, deployment or production authority.

User interactions are initial approval, optional rotation offers and final acceptance. Ask only for missing consequential decisions or external authority, and reuse existing authorization within its scope. Prepare a concrete reviewable release before requesting remaining release permission.

## Load Context by Scope

At entry or recovery, read SPEC metadata, Mission, Must-NOT-Have and global constraints (including linked global contracts), and the contract inventory of headings, scenario IDs and contract links. Inspect ROADMAP dispositions, dependencies and Current Acceptance Delta, and locate the latest gate and unresolved LEDGER events. Then load the selected task, its dependency outputs and the relevant contract, evidence and NOTES sections. During uninterrupted work, read the changes since the previous selection.

References are starting points. Check that they resolve and compare their declared scope with the actual interfaces, shared components and changed files before editing and whenever scope grows; read further contracts for newly affected boundaries. Compaction alone does not require reloading full documents. Broken references, unclear contract scope, mismatched state or an interrupted write require broader reads, up to complete files. Do not guess at an unread boundary.

## Select Verification Before Expensive Work

Before the first expensive batch, or after its scope, verifiers or prerequisites change, reconcile the scenarios due at that boundary with concrete commands or cases, fixtures, expected observables and prerequisites from the task `verify:` and phase/final plan. A test filename or count does not demonstrate coverage; use discovery, listing or inspection. Repair missing coverage before the batch and continue independent ready work meanwhile. A composite check covers leaf checks only if they actually run and their failures propagate; keep a direct check for each distinct public entrypoint.

Match proof to the interface: CLI/API/library execution, browser interaction or another literal observable, compared with POC-locked aspects. Mock/DOM checks do not establish rendered behavior or an external integration they never exercise. Required project checks and reliability repetitions still run.

Reuse evidence only when the recorded candidate inputs, verifier, fixtures, configuration, dependencies and environment directly support it; a matching hash or a small edit does not prove that. A change within that boundary invalidates the old evidence for the new state, while a new commit alone does not invalidate unchanged inputs. Changes to shared runtime, public interfaces, dependency resolution, persistent data, security boundaries or build/test behavior, and any uncertainty, expand verification up to a full baseline; a task label or broad path does not determine impact. Live or environment-sensitive evidence must match its actual target.

The final verification plan exercises the candidate's relevant component interactions together; separate task passes do not substitute for them.

## The Loop

1. **Orient and select.** Load by scope and reconcile interrupted state. Pick a pending task whose dependencies are satisfied and that is not blocked. Then weigh the other ready tasks and the selected task's read-heavy steps against the delegation criteria in `ai-behavior.md`, and delegate what qualifies under `agent-delegation.md`. Dependencies define the ready set; waves are optional.
2. **Implement.** Append `task-started` before edits. Before delegating, record the routing decision required by `agent-delegation.md`, owner and expected output; reassess when a resume or follow-up changes the unit.
3. **Verify.** Before an expensive batch, reconcile coverage, then run the smallest non-redundant set that proves the due observables on the actual candidate.
4. **Record, then mark complete.** Append observed evidence and `task-completed` before ticking ROADMAP, then clear only the delta this evidence resolves. On failure append `validation-failed`, update the delta and reopen the responsible work.
5. **Persist the verified unit.** Under `per-task`, make a coherent local commit under `git-workflow.md` (`spec(<slug>): <task-id> <summary>` unless repository conventions differ). If policy blocks the commit, keep the worktree, report it and continue authorized work unless that is unsafe.
6. **At a phase boundary, evaluate its evidence.** Run missing or invalid checks and distinct integration observables; do not rerun qualifying composite or leaf evidence just because a boundary was reached. Append `phase-validated` only on PASS. Under `per-phase`, commit the verified phase; `per-task` and `user` add no phase commit. Offer rotation without pausing for an answer.

## Convergence and Circuit Breakers

- Progress means an acceptance gap clears or its diagnosis narrows enough to change the next action. More tasks, ticks or repeated confirmation of the same failure are not progress.
- Retry only with a different hypothesis, implementation or verifier, keeping the next action in ROADMAP or NOTES. Otherwise mark the responsible task blocked with its condition and unlock, and continue independent work.
- Evidence that exercises the required action or observable more directly or representatively invalidates a contradicting green result. Append the failure, update the delta and reopen responsible work; the weaker verifier is no longer sole proof.
- After two exploration passes with no new facts, act on available evidence or block the affected work. Explicit user or runtime budgets are authoritative.
- If blockers remain and no independent runnable task does, append `circuit-breaker`, set `status: blocked`, sync INDEX and report the exact unlock condition. Never weaken acceptance or loop silently.

Resume a blocked mission with `/cda-spec-run`. Continue when the diagnosis and delta show a different evidence-backed path. Clear only the affected block, or supersede dead work with the smallest in-scope replacement and log `replanned`. Scope ambiguity stays blocked on the missing decision, recorded in the workspace rather than a pasted handoff prompt.

## Rotation and Interruption

Offer rotation at useful phase boundaries or after context degradation, once in-flight work is safe. Report progress and the unresolved delta; a decline or no reply means continue.

On an affirmative request, append `rotation-checkpoint` with the next task and references, then use `/cda-checkpoint` to sync INDEX and CONTEXT pointers and evaluate eligible NOTES candidates. Do not create `.claudart/HANDOFF.md` for spec work. The next session uses `/cda-start` and `/cda-spec-run`.

## Completion and Final Review

When all ROADMAP work is completed or superseded and no blocker remains, run the final gate on the reconciled coverage plan:

- **Full baseline** is required when the mission has no successful full-baseline gate, after an approved material amendment, or when the evidence boundary is uncertain. Every scenario needs fresh evidence for the candidate or released target, plus the planned candidate integration and required project checks. Fresh means valid for that state; checks already observed on an unchanged candidate need no rerun. When release is in scope, the gate needs both software and release evidence.
- **Scoped review** follows an anchored defect or bounded review patch after final review. Start from the latest successful `final-gate` cumulative evidence state, confirm its full-baseline root, and derive impact from the actual changed surface. Run the affected scenarios and the consumer and integration checks they need; retain other evidence only under the reuse rule. If the chain or boundary is uncertain, use a full baseline.
- Record the successful gate as the LEDGER section defines, and clear the delta only when every required observation is proven.
- On any failure, append `validation-failed`, keep the gap and reopen its responsible task. Add no bookkeeping-only replay tasks and never report completion with failing criteria.
- On complete PASS, set `awaiting-final-review`, sync INDEX, present exact demo steps and evidence, and stop. The mission is read-only until the user responds.

Classify feedback before unlocking:

- **Anchored defect:** contradicts an exact approved scenario, Must-NOT-Have clause or POC observable. Record the baseline and provisional impact in ROADMAP, append the failure, reopen responsible work and return to `running`.
- **Explicit bounded review patch:** one concrete user-requested delta, with no conflict with frozen intent, unresolved design choice or effects that escape a defensible local boundary. Record the request as `scope-change`, amend SPEC with its observable, add only necessary work, record baseline and impact and return to `running`. Implement only the stated observable, its direct dependencies and proof; no adjacent hardening, documentation, refactors or extra gates.
- **Material or ambiguous amendment:** keep the lock, explain the scope delta and request amendment approval. On explicit approval return to `drafting` and `/cda-spec` for renewed standing approval.

Broad requests such as “quality” or “production-ready” are not defect anchors. Only the user's confirmation closes the mission, never the executor's own PASS:

1. Set `status: done` and append one completion line to `.claudart/JOURNAL.md`, pointing to the archived SPEC.
2. Evaluate NOTES graduation candidates under the knowledge contract; preserve uncertainty and propose `/cda-learn` for behavioral lessons.
3. Move the whole folder to `.claudart/specs/done/YYYY-MM-DD-<slug>/` and sync INDEX. Repair every knowledge `sources` entry that points into the moved folder to its archived path; path repair changes neither `updated` nor `last_verified`. Run the knowledge checker after the move if any knowledge file changed.

## Status and Index

```text
drafting → poc-review → ready → running → awaiting-final-review → done
poc-review → drafting                     # requested changes
running ↔ blocked                        # no independent runnable work / valid unlock
awaiting-final-review → running           # anchored defect or bounded requested patch
awaiting-final-review → drafting          # approved material amendment
any active → cancelled                    # user cancellation
```

`drafting`/`poc-review` belong to the author and `ready`/`running` to the runner. INDEX is a cache derived from SPEC metadata: Active links non-terminal top-level folders and Done links archived `done`/`cancelled` folders. Mark `poc-review` and `awaiting-final-review` Active lines with ` ⏳ awaiting your review`. Archive a top-level terminal folder when syncing; never delete it. Checkpoint does not tick tasks or advance status.

## Relationship to CLAUDART

Keep one CONTEXT pointer to the active spec; never copy its plan there or into task indexes. Start reads the registry, checkpoint maintains it and eligible candidates, and the author or runner owns status transitions. Knowledge follows its own owner, map and validation contract. Flag recurring behavior for `/cda-learn`; the executor does not rewrite framework guidelines mid-mission.
