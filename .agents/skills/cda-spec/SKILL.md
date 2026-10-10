---
name: cda-spec
description: Create or amend a dated mission spec, prove intent in reviewable artifacts and prepare scoped, non-redundant execution under standing approval.
---

# Codex Spec

You are the spec author. Capture confirmed intent in the mission workspace so a later executor needs no interview history.

Before acting, read `.codex/guidelines/spec-workflow.md`. It is the canonical contract for ownership, acceptance, recovery, verification, approval and review; this skill orchestrates drafting rather than duplicating that contract.

## Resolve the mission and authority

The argument is the mission. If empty, ask what the mission is. Route bounded work to `$cda-task`; route an undefined project needing current documentation to `$cda-project-docs` when installed. A defined mission may stay here while its requirements are clarified.

Read `.claudart/CONTEXT.md`, `.claudart/specs/INDEX.md`, the root knowledge map, relevant project documentation and recent Git history. Additional knowledge retrieval follows `knowledge-management.md`. Proposed behavior is not implemented project reality.

Honor an explicit current selection; otherwise reuse a matching draft and ask only if matches are ambiguous. Follow the canonical lifecycle for other statuses. New work uses `.claudart/specs/YYYY-MM-DD-<slug>/`, a minimal drafting SPEC and an INDEX entry. Terminal top-level folders are stale archive state, not active collisions.

Keep execution intent separate from approval. An applicable request to execute after approval remains valid until withdrawn. The drafting lock permits spec-folder documents and POC artifacts, not production implementation or scaffolding. The guideline's narrow knowledge-maintenance exception remains subject to its full capture gate.

## Interview and establish acceptance

Ask the highest-leverage unresolved question, using existing evidence before asking the user. Capture confirmed decisions in their current owner as they settle; keep confirmed, rejected and open scope distinguishable. Move rejected/deferred features into Must-NOT-Have.

While drafting existing acceptance scenarios, apply the guideline's initial-state coverage rule: identify the minimum supported state, the first useful result and how fixture prerequisites are created or supplied. Cover materially different first-use behavior without adding a separate matrix or expanding scope. Use the actual public interface, whether UI, CLI, API or another surface.

Give scenarios stable IDs, explicit initial conditions, actions and observables. Split independently failing obligations when useful. Record additional contract links with their scope instead of copying bodies. Keep mission-wide constraints visible independently of task references.

## Build only the useful POC

Choose the smallest artifact set that resolves the remaining questions and let the user choose fidelity. For UI work, a self-contained HTML may be suitable; other interfaces need appropriate reviewable outputs or interaction examples. Establish how the user and executor can inspect the reference before making it an acceptance requirement.

Revise the artifact and its owning contract together. Freeze only the approved aspects and identify them in SPEC. Do not build a second full implementation or force multiple artifacts when one answers the questions. Continue until the user confirms the intended behavior; that confirmation is distinct from standing implementation approval.

## Prepare the execution plan

Explore existing implementation patterns read-only. Use delegation only under the active harness and `agent-delegation.md`; no exploration result authorizes implementation.

Write ROADMAP tasks with ownership boundaries, dependencies, relevant scenario/contract references and observable `verify:` checks. Use concrete paths where known or contractual without pre-solving internal code. Arrange useful early milestones and non-cyclic dependencies, including software verification before any authorized release and post-release observations afterward where applicable.

Map due scenarios to concrete verifiers/cases, necessary fixtures and prerequisites in the existing phase/final plan. Name composite coverage and the smallest non-redundant verification set; do not schedule included leaf checks again without a distinct observable. Planned verifiers may be implemented by their owning tasks, but their coverage must be reconciled before an expensive batch runs.

For a new mission, initialize LEDGER and concise NOTES containing only useful pointers, pitfalls and unresolved reasoning. Put Current Acceptance Delta in ROADMAP. On amendment, preserve evidence and completed/superseded work; add only the approved change. Follow legacy recovery rather than silently discarding existing notes or acceptance gaps.

## Check and present

Read the global contract and inspect the plan as an executor without interview context. Check the supported first-use path, resolvable references, missing scenario ownership, dependency order, observable acceptance and feasible verification. Reference validity alone does not prove completeness: compare the task scope with the contract inventory. Fix gaps in the existing documents rather than creating another readiness report or approval gate.

Set `poc-review`, sync INDEX and present the folder, reference/demo, scope, open decisions and task/phase outline. Report **Commit cadence**: `commits: per-task` (default), or the selected `per-phase`/`user` setting. Explain that approving SPEC + ROADMAP grants standing implementation approval within existing authority; it does not itself request execution or authorize external actions.

On approval, set `ready` and sync INDEX. Approval alone stops there. If execution was also requested, hand directly to `$cda-spec-run` in this session; the runner owns `ready → running`. A new session is optional. Enthusiasm about the POC is not an explicit approval.
