---
paths: [".claude/commands/spec.md", ".claude/commands/spec-run.md"]
description: Dated mission-scale specs with standing approval, scoped context loading, owned execution state and evidence-driven verification through final user review.
when_to_use: Whenever the user invokes `/spec` or `/spec-run`, when a spec folder under `.claudart/specs/` is open or referenced, or when resuming mission-scale work that spans many sessions.
tags: [specs, loop-engineering, autonomy, cross-session, missions]
---

# Spec Workflow (Loop Engineering)

A **spec** is a mission that needs a frozen intent, a phased plan, standing approval and recovery across sessions. Use `/plan` for bounded work whose decisions fit one task workspace; use `/project-docs`, when installed, for an undefined project needing current documentation. A spec replaces the task layer for its scope: its executor never creates matching `.claudart/tasks/` work.

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

- The folder name is `<created>-<slug>`; use a creation date and a short slug of 2–5 lowercase kebab-case words. Never nest active specs.
- `/spec-run` resolves either the dated folder id or its SPEC `slug`. An omitted argument selects the only active ready/running/blocked/review mission; ask only if several match. Report archived matches without executing them.
- **One editable owner per fact.** SPEC defines behavior; ROADMAP owns current execution state and the verification plan; LEDGER owns results/history; NOTES keeps useful reasoning that has no other current owner. Link to an existing architecture document or runbook instead of restating its contracts or procedures.
- SPEC scenarios have stable IDs, not mutable completion checkboxes. Optional acceptance/release reports are derived views with source references, never another authority. INDEX is a cache and CONTEXT may contain one pointer.
- Update SPEC `updated:` when its contract or lifecycle metadata changes, not after every task. Current execution activity is in ROADMAP/LEDGER. These ownership rules replace duplicate updates; they do not require generated reports, a new state engine or per-task compliance documents.

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

Each scenario must be observable by an executor without interview history. Split independently failing obligations into sub-IDs where necessary; do not turn every assertion into a task or a separate command. Identify checks that need a released artifact or live environment so they cannot block their own prerequisites.

**Initial-state coverage belongs in existing acceptance.** For each materially different first-use path, trace the minimum supported state to the first useful result through the real entrypoint. Essential pre-populated fixture resources must have a supported creation path or an explicit external prerequisite. Cover first-use behavior when it differs from later use; include controlled rejection, cancellation or recovery when material. An empty input need not succeed. Do not add out-of-scope features, a Cartesian state matrix or a separate checklist report.

POC artifacts freeze only the aspects the user chose: interaction, appearance, protocol/output behavior or another observable. Select the smallest useful artifact for the actual interface and confirm how it can be inspected before relying on it for acceptance. Avoid building a second full implementation. Drafting may produce runnable POC artifacts within its workspace, not production implementation or scaffolding.

## ROADMAP.md — plan and current execution state

A later executor must understand the work without interview context. Record boundaries, dependencies, relevant contract/scenario references, chosen approaches where they matter, and a sharp `verify:`. Exact file paths are useful when known or contractual; do not pre-solve internal implementation. Plan Altitude from `task-management.md` still applies.

```markdown
# ROADMAP — <Mission Title>

<Build order and important dependencies; optional parallel waves under the active harness.>

## Phase 1 — <name>

Goal: <observable milestone>

- [ ] P1.1 <action and ownership boundary> (contracts: <S#/section refs>; verify: <observable>)
- [ ] P1.2 <action> (depends: P1.1; contracts: <refs>; verify: <observable>)

**Phase validation:** <due scenarios → concrete verifiers/cases, fixtures and prerequisites;
name composite coverage and the smallest non-redundant final verification set>

## Current Acceptance Delta

- None.
<!-- Or: <S# or named gate>: <unresolved gap>; owner: <task-id>;
evidence: <LEDGER entry>; baseline: <gate ref, when applicable>;
impact: <affected scenarios/checks>; next: <action or NOTES hypothesis ref>. -->
```

Task dispositions:

- `- [ ] <task>`: pending, runnable only when its dependencies are satisfied and it is not blocked.
- `- [x] <task>`: completed, backed by a `task-completed` evidence entry.
- `- [x] ~~<task>~~ — superseded by <task-id or reason>`: terminal, backed by `replanned`.
- `- [ ] <task> — ⚠ blocked: <condition>; unlock: <required input/change>`: unresolved, skipped by selection and prevents final completion.
- Unchecked struck rows are invalid. Reconcile from evidence; ambiguous disposition becomes a blocker, never an assumed completion.

Size a task around a coherent observable and its proof, small enough for an iteration. A phase should yield useful observable progress early. Dependencies must be acyclic; later numbering does not make work runnable. For release work, order software verification → applicable rehearsal/readiness → separately authorized release/cutover → post-release observations. Omit stages outside the approved scope. A software gate must not require future live evidence, and release must not wait for a gate that already includes post-release checks.

**Current Acceptance Delta lives only here.** Keep current contradicted/unproven obligations or approved review changes, keyed by scenario/gate rather than task. Reference LEDGER for the last attempt/result and NOTES only for unresolved reasoning; do not copy them. A review back-edge records the latest successful final-gate baseline and provisional impact, recomputed from the actual changed surface before verification. Clear a gap only with valid evidence; changing its task/owner never resolves it.

The executor may append genuinely missing implementation work and log it, within approved scope. Supersede dead work explicitly; preserve history and phase intent. Reopen only the current non-superseded task whose evidence was invalidated. Keep a fix and its verification in that task; never append mechanical fix/replay task pairs. Scope changes follow the review/amendment rules below.

## LEDGER.md — append-only evidence

```markdown
### YYYY-MM-DD HH:MMZ — <event> <task-id or scope>

- Evidence: <command/case or observation → result; scenario refs; state/environment proved>
- Decision: <optional change and why; link to its current owner>
```

Events include `run-started`, `task-started`, `task-completed`, `validation-failed`, `phase-validated`, `task-blocked`, `replanned`, `delegated`, `circuit-breaker`, `rotation-checkpoint`, `scope-change` (user-initiated only), and `final-gate`. Never rewrite or delete historical entries. Store large outputs in appropriate artifacts and reference them.

Each successful gate records its **resulting revision or bounded worktree fingerprint**, actual environment/artifact, observed scenario coverage, and `executed`, `covered` and any `reused` evidence. For a dirty tree, identify the base revision and relevant changed-path/content digests; exclude secrets and unrelated user files. Record relevant verifier, fixture/configuration and dependency state, using existing build/test identifiers where available rather than maintaining a per-file cache.

A `final-gate` records `mode: full-baseline | scoped-review`. Full baseline records its reason (`initial`, `material-amendment` or `conservative-fallback`). Scoped review names the latest successful `final-gate` cumulative evidence state, the actual changed surface, newly observed coverage and the reason retained evidence still applies. Its cumulative chain must reach an identifiable full baseline.

An unmatched `task-started` or `delegated` marks interrupted work. Locate unresolved events from their headers/IDs and inspect the relevant bodies, including failures since the baseline; a fixed tail length is not proof that no work remains. A result written before its ROADMAP update can be reconciled from evidence without automatically repeating the operation.

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

Keep notes declarative and curated. Remove resolved reasoning or route the established fact to its owner, leaving a pointer when helpful. Approved scope belongs in SPEC, implementation decisions in their design/plan owner, past attempts in LEDGER, and acceptance gaps in ROADMAP. Do not copy those into NOTES.

The existing 150-line ceiling is a backstop, not a context budget: do not pack paragraphs to satisfy it or automatically read the entire file. Load relevant notes only. Flag durable descriptive candidates `→ graduate: knowledge/` and recurring behavior `→ graduate: /learn`; a local scope does not disqualify a fact. Uncertainty stays here, not in canonical knowledge.

For a direct knowledge mutation, read `knowledge-management.md` and its maintenance reference; require the full capture gate and an immediate-promotion trigger. Update the existing owner and reachable map atomically, then run `bash .claude/scripts/knowledge-check.sh --root .`. Checkpoint bulk-maintains remaining flags. This exception does not authorize production implementation during drafting.

## Standing Approval and Authority

The user approves SPEC + ROADMAP once. That standing approval replaces task/phase approval requests inside a running spec; do not create task-layer work or stop at intermediate user review. Approval and execution intent remain separate: approval alone leaves `ready`; an applicable instruction to execute permits the same session to enter `running`. A material scope change still needs amendment and renewed approval.

`commits:` sets local cadence: `per-task` is the default and creates a verified task restore point, `per-phase` waits for phase validation, and `user` disables automatic commits. Follow `git-workflow.md` and higher-scope restrictions; this setting never grants push, history rewrite, deployment or production authority.

Normal interactions are initial approval, optional rotation offers, and final user acceptance. Ask for missing consequential decisions or external authority only where needed; reuse existing authorization within its scope. Prepare a concrete reviewable release before requesting any remaining release permission. A blocked task stops the whole loop only when no independent runnable work remains.

## Load Context by Scope

At initial entry or recovery, read SPEC metadata, Mission, global constraints/Must-NOT-Have (including globally applicable linked contracts), and the contract inventory (headings, scenario IDs and additional contract links). Inspect ROADMAP task dispositions/dependencies and Current Acceptance Delta; locate the latest gate and unresolved LEDGER events. Then load the selected task, its dependency outputs and relevant contract/evidence/NOTES sections. During uninterrupted work, read changes since the previous selection.

References are starting points, not proof of completeness. Check that they resolve and compare their declared scope with actual interfaces, shared components and changed files before editing and whenever scope expands. A structural reference check cannot discover every omitted semantic dependency. Read additional relevant contracts for newly affected boundaries; global constraints remain mandatory.

Compaction alone does not require reloading every full document. Missing/broken references, unclear contract scope, mismatched state or an interrupted write require broader inspection, up to complete files when necessary. Do not guess at an unread boundary to save context.

**Legacy recovery:** existing workspaces may keep acceptance checkboxes in SPEC or Current Acceptance Delta in NOTES. Read those sections and LEDGER evidence before relying on them; old ticks alone never establish PASS. On the next authorized state update, reconcile unresolved gaps into ROADMAP and replace the old NOTES delta with a pointer, preserving baseline/impact/history. Do not rewrite approved scenario text or drop unresolved work. At a read-only lock, inspect/report inconsistencies without migrating them. A flat legacy document may need a full read until its relevant contracts can be identified.

## Select Verification Before Expensive Work

Use the existing task `verify:` and phase/final coverage plan. Before the first expensive batch, or after its scope/verifiers/prerequisites change, reconcile the scenarios due at that boundary with concrete commands/cases, fixtures, expected observables and execution prerequisites. Use discovery/listing or focused inspection when needed; a test filename or count alone does not demonstrate coverage. Future live/manual observations remain pending with explicit owners rather than blocking their software prerequisites.

Repair missing coverage before launching that batch; continue independent ready work. This is part of selecting tests, not another approval, permanent report, mandatory tool or checklist after every command. It checks the plan, not whether the product passes. A composite check covers leaf checks only if they actually run and their failures propagate; retain a direct check for a distinct public entrypoint.

Match proof to the interface: CLI/API/library execution, browser interaction or another literal observable. Compare POC-locked aspects where relevant. Mock/DOM checks do not establish rendered behavior or an external integration they never exercise. Required project checks and reliability repetitions remain required.

**Reuse conservatively.** A hash identifies inputs; it does not establish that the recorded dependency boundary is complete. Reuse only when applicability is directly supported by the recorded candidate/inputs, verifier, fixtures, configuration, dependencies and environment. A change within that input boundary invalidates the old evidence for the new state. A changed commit alone does not invalidate unchanged inputs; a small edit alone does not prove independence. Shared-contract changes or uncertainty expand verification, up to a full baseline. Live/environment-sensitive evidence must match its actual target and observation requirements.

The existing final verification plan must exercise the candidate's relevant component interactions; separate task passes cannot substitute for interactions never exercised together. This is part of final verification, not a second suite afterward. Do not add a fine-grained cache or dependency-tracking engine. No workflow speedup is established merely by these rules.

## The Loop

1. **Orient and select.** Apply scoped loading and reconcile interrupted state. Pick a pending task only when dependencies are satisfied and it is not blocked. Prepared waves permit parallelism only under the active harness and `agent-delegation.md`.
2. **Implement.** Append `task-started` before edits. Record any authorized delegation with unit, owner, profile when relevant and expected output. Give self-contained goals, boundaries, constraints and references; a worker's completion is a claim to verify.
3. **Verify.** Use focused checks while implementing. Before an expensive batch, perform the coverage reconciliation above; run the smallest non-redundant set proving the due observables on the actual candidate.
4. **Record, then mark complete.** Append observed evidence/`task-completed` before ticking ROADMAP. Re-read the updated disposition and clear only the delta this evidence resolves. On failure append `validation-failed`, update the ROADMAP delta and reopen its responsible work. NOTES changes only for useful new reasoning; SPEC changes only for contract/lifecycle metadata.
5. **Persist the verified unit.** Inspect the owned diff. Under `per-task`, follow `git-workflow.md` for a coherent local commit (`spec(<slug>): <task-id> <summary>` unless repository conventions differ). If policy blocks persistence, keep the worktree, report the restriction and continue authorized work unless it makes continuation unsafe.
6. **At a phase boundary, evaluate its evidence.** Execute missing/invalid checks and distinct integration observables; do not rerun qualifying composite/leaf evidence just because a boundary was reached. Append `phase-validated` only on PASS. Under `per-phase`, commit the verified phase; `per-task` adds no duplicate phase commit and `user` adds none. Offer rotation without pausing for silence.

## Convergence and Circuit Breakers

- Progress means an acceptance gap clears or its diagnosis narrows enough to change the next action. More tasks, ticks or repeated confirmation of the same failure are not progress.
- Retry only with a materially different hypothesis, implementation or verifier. Keep the next action in ROADMAP or reference NOTES reasoning; LEDGER owns attempts/results. Otherwise mark the responsible task blocked with its condition/unlock and continue independent work.
- Stronger contradictory evidence invalidates a green result when it exercises the required action/observable more directly or representatively. Append the failure, update the delta and reopen responsible work; do not erase history or reuse the insufficient verifier as sole proof.
- Evidence follows semantic impact, its verifier and its dependency surface. Shared runtime, public interface, dependency resolution, persistent data/schema, security boundaries and build/test behavior can expand the affected scope. Do not infer impact from a task label or broad path alone.
- After two exploration passes with no new facts, act on available evidence or block the affected work. Explicit user/runtime budgets remain authoritative; do not invent resource estimates, attempt-accounting systems or model/rotation thresholds.
- If no independent runnable task remains with unresolved blockers, append `circuit-breaker`, set `status: blocked`, sync INDEX and report the exact unlock condition. Never weaken acceptance or silently loop.

Resume a blocked mission with the same `/spec-run`. Read the diagnosis/delta; continue when a materially different evidence-backed path exists. Clear only the affected block, or supersede dead work with the smallest approved-scope replacement and log `replanned`. Scope ambiguity remains blocked on the missing decision. Keep the amendment in the workspace, not in a pasted handoff prompt.

## Rotation and Interruption

Offer rotation at useful phase boundaries or after context degradation once in-flight work is safe. Report progress and unresolved delta; a decline or no reply means continue authorized work.

On an affirmative request, append `rotation-checkpoint` with the next task and references, then use `/checkpoint` to sync INDEX/CONTEXT pointers and evaluate eligible NOTES candidates. Do not bump SPEC just for a rotation or create `.claudart/HANDOFF.md` for spec work. The next session uses `/start` and `/spec-run`.

An interrupt is recoverable like a crash. Verify unmatched work and any evidence/disposition mismatch before repeating it; do not require the user to wait for a clean boundary.

## Completion and Final Review

When all ROADMAP work is completed or explicitly superseded and no blocker remains, establish the applicable final gate using the already reconciled coverage plan:

- **Full baseline** is required when the mission has no successful full-baseline gate, after an approved material amendment, or when the evidence boundary is uncertain. Every scenario needs fresh observed evidence for the candidate or applicable released target. Fresh means applicable to that state, not mechanically rerunning an unchanged candidate's already observed checks. Include the planned candidate integration and project-required checks.
- **Scoped review** follows an anchored defect or explicit bounded review patch after final review. Start from the latest successful `final-gate` cumulative evidence state, confirm its full-baseline root, and determine impact from the actual changed surface. Run affected scenarios and necessary consumer/integration checks; retain other evidence only under the conservative reuse rule. If the chain or boundary is uncertain, use a full baseline.
- Record the successful gate with the resulting revision or bounded worktree fingerprint, executed/covered/reused evidence and any reuse rationale. Clear the delta only when all required observations are proven. Software and later release evidence may be gathered in their prerequisite order; a full final gate still requires both when both are in scope.
- On any failure, append `validation-failed`, keep the gap and reopen its responsible task. Do not add bookkeeping-only replay tasks or report completion with failing criteria.
- On complete PASS, set `awaiting-final-review`, sync INDEX, present exact demo steps and evidence, then **STOP**. This is a read-only lock; the user confirms completion.

Classify feedback before unlocking:

- **Anchored defect:** contradicts an exact approved scenario, Must-NOT-Have clause or POC observable. Record the baseline/provisional impact in ROADMAP, append the failure, reopen responsible work and return to `running`.
- **Explicit bounded review patch:** one concrete user-requested delta, with no conflict with frozen intent, unresolved design choice or effects that escape a defensible local boundary. Record the request as `scope-change`, amend SPEC with its observable, add only necessary work, record baseline/impact and return to `running`. Implement only the stated observable, direct dependency closure and proof; no adjacent hardening, documentation, refactors or extra gates.
- **Material or ambiguous amendment:** keep the lock, explain the scope delta and request amendment approval. On explicit approval return to `drafting` and `/spec` for renewed standing approval.

Broad requests such as “quality” or “production-ready” alone are not defect anchors. Completion confirmation closes the mission, never the executor's own PASS:

1. Set `status: done` and append one completion line to `.claudart/JOURNAL.md`, pointing to the archived SPEC.
2. Evaluate NOTES graduation candidates under the knowledge contract; preserve uncertainty and propose `/learn` for behavioral lessons.
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

`drafting`/`poc-review` belong to the author and permit no production implementation. `ready`/`running` belong to the runner. Approval alone does not imply execution, and changing runtimes never changes authority.

INDEX is derived from SPEC metadata, with Active links to non-terminal top-level folders and Done links to archived `done`/`cancelled` folders. Mark `poc-review` and `awaiting-final-review` as awaiting user review. A top-level terminal folder is stale archive state: archive it when syncing, never delete it. Checkpoint does not tick tasks or advance status. For execution staleness, inspect current ROADMAP/LEDGER activity rather than treating an unchanged contract date as inactivity.

## Relationship to CLAUDART

Keep one CONTEXT pointer to the active spec; never copy its plan there or into task indexes. Start reads the registry, checkpoint maintains it and eligible candidates, and the selected author/runner owns transitions. Knowledge follows its existing owner/map and validation contract. Recurring behavior may be flagged for `/learn`; the executor does not rewrite framework guidelines mid-mission.
