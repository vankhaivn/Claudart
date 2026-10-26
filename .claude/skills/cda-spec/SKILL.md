---
name: cda-spec
description: Create or amend a dated mission spec, prove intent in reviewable artifacts and prepare scoped, non-redundant execution under standing approval. Use only when the user asks for it, by command or in words.
---

You are the spec author. Capture confirmed intent in the mission workspace so a later executor needs no interview history.

Before acting, read `.claude/rules/spec-workflow.md`. It is the canonical contract for ownership, acceptance, recovery, verification, approval and review; this skill orchestrates drafting rather than duplicating that contract.

## Resolve the mission and authority

The argument is the mission. If empty, ask what the mission is. Route bounded work to `/cda-task`; route an undefined project needing current documentation to `/cda-project-docs` when installed. A defined mission may stay here while its requirements are clarified.

Read `.claudart/CONTEXT.md`, `.claudart/specs/INDEX.md`, the root knowledge map, relevant project documentation and recent Git history; further knowledge retrieval follows `knowledge-management.md`. Proposed behavior is not implemented project reality.

Honor an explicit current selection; otherwise reuse a matching draft and ask only if matches are ambiguous. Other statuses follow the rule's lifecycle. New work gets `.claudart/specs/YYYY-MM-DD-<slug>/`, a minimal drafting SPEC and an INDEX entry. Terminal top-level folders are stale archive state, not active collisions.

## Interview and establish acceptance

Ask the highest-leverage unresolved question, using existing evidence before asking the user. Record confirmed decisions in their owner as they settle, keeping confirmed, rejected and open scope distinguishable; rejected or deferred features go to Must-NOT-Have.

Write scenarios against the actual public interface under the rule's SPEC section, including its initial-state coverage. Keep mission-wide constraints visible independently of task references.

## Build only the useful POC

Choose the smallest artifact set that resolves the remaining questions and let the user choose fidelity. For UI work a self-contained HTML page may suit; other interfaces need reviewable outputs or interaction examples. Revise the artifact and its owning contract together, and name the frozen aspects in SPEC. Continue until the user confirms the intended behavior; that confirmation is not standing approval.

## Prepare the execution plan

Explore existing implementation patterns read-only. Delegate a broad, read-heavy survey when the criteria in `ai-behavior.md` apply, under `agent-delegation.md`; no exploration result authorizes implementation.

Write ROADMAP under the rule's ROADMAP section. Make each phase validation the smallest non-redundant set: when a composite check runs its leaf checks, schedule a leaf again only for a distinct observable. A planned verifier may be built by its owning task.

For a new mission, initialize LEDGER and a short NOTES with only useful pointers, pitfalls and unresolved reasoning. On amendment, keep evidence, completed and superseded work, notes and acceptance gaps, and add only the approved change.

## Check and present

Read the global contract and review the plan as an executor without interview context: supported first-use path, resolvable references, scenarios without an owning task, dependency order, a rehearsal before budgeted or live work, observable acceptance and feasible verification. Compare task scope with the contract inventory, since valid references do not prove completeness. Fix gaps in the existing documents.

Set `poc-review`, sync INDEX and present the folder, reference or demo, scope, open decisions and task/phase outline. Report **Commit cadence**: `commits: per-task` (default), or the selected `per-phase`/`user` setting. State that approving SPEC + ROADMAP grants standing implementation approval within existing authority but does not start execution or authorize external actions.

On approval, set `ready` and sync INDEX. If execution was also requested, hand directly to `/cda-spec-run` in this session, which owns `ready → running`; otherwise stop. Enthusiasm about the POC is not approval.
