---
paths: [".claude/agents/**"]
description: Claude Code subagent delegation — when delegation pays off and how to delegate well (decomposition, worker prompts, anti-shadow-run, persistence), layered on top of the Agent tool's built-in mechanics.
when_to_use: When multi-step work may split into parallel, context-heavy, or independently assessable units, or when delegating to subagents — for the project's decision, decomposition, worker-prompt, anti-shadow-run, and finding-persistence guidance.
tags: [subagents, delegation, parallelism, orchestration]
---

# Agent Delegation

Use the current harness and the user's constraints to decide whether delegation is available and appropriate. This protocol supplies ownership, cost, integration, and recovery rules; it does not add an approval gate for routine delegation. Available agent roles, context modes, tool arguments, and filesystem isolation come from the active tool schema, not assumptions about another client or model setting.

The routing policy below applies to ordinary general-purpose delegates. Named project specialists retain their own invocation restrictions and model policy; do not silently down-route or invoke an explicitly gated specialist.

## Route general-purpose delegates by difficulty

Role selection and model selection are separate decisions. `Explore`, `Plan`, and `general-purpose` describe **what** the delegate does; the delegated unit's difficulty determines **which model family** should do it. This section applies only to ordinary delegation. Named project specialists under `.claude/agents/` keep their own model policy and must not be silently down-routed by this rule.

Before each ordinary spawn, and before a resume or follow-up introduces a new or materially changed unit, classify the delegated unit by its ambiguity, breadth, consequence of a wrong answer, and difficulty of verification. Choose the lowest class that is likely to complete the unit reliably:

| Class      | Typical delegated unit                                                                                                    | Ideal Claude family |
| ---------- | ------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| `routine`  | focused search, call-site inventory, docs lookup, extraction, mechanical or highly constrained edit                       | Haiku               |
| `standard` | bounded implementation or debugging with clear contracts and local verification                                           | Sonnet              |
| `complex`  | ambiguous cross-file debugging, architecture-sensitive reasoning, difficult review or integration                         | Opus                |
| `maximum`  | genuinely frontier-level, long-horizon, highly ambiguous work, or a unit whose cheaper attempt exposed a capability limit | Fable               |

The **parent session's selected model is a hard ceiling for implicit delegation**. The effective child model is the cheapest suitable model for the class, capped at the parent model's family. A difficult task is not permission to spend above the user's session choice.

- Conceptually: `effective child = min(ideal child for task, parent-session ceiling)`.
- A Fable parent may route a `routine` unit to Haiku, a `standard` unit to Sonnet, a `complex` unit to Opus, and reserve Fable for `maximum` work.
- An Opus parent caps both `complex` and `maximum` units at Opus. A Sonnet parent caps them at Sonnet. The same rule continues downward.
- **Never launch a model family above the parent ceiling unless the user explicitly requests or authorizes that stronger model for the delegated unit.** A project instruction, perceived urgency, retry, or "be thorough" request is not such authorization.
- Use the Agent tool's per-invocation model selection when routing an ordinary delegate. If the parent model cannot be identified, the desired cheaper family is unavailable or disallowed, or the harness cannot reliably honor the override, do not guess upward: use a known available model within the ceiling, including the parent's own model. A ceiling is not a default: when a cheaper suitable family can be selected, use it.
- Model availability and aliases can change. Treat the family ordering above as the routing intent, not permission to bypass account/workspace allowlists.

The classes are routing options, not a mandatory retry ladder. Choose the appropriate class upfront. Before retrying a wrong or partial result, distinguish missing context, unclear scope, or tooling failure from a capability limit. Allow at most one delegated retry per unit across agents and models, with a corrected prompt or changed hypothesis; evidence of a capability limit may justify skipping classes **within the same ceiling**. A retry is optional: the parent may take over immediately and must take over after a failed retry, reporting blockers it cannot resolve.

## Dispatch and reuse

Before dispatching an ordinary delegated unit, record one concise routing decision: **unit → difficulty class → selected model and reasoning effort where supported → reason**. Name the concrete profile, including an inherited profile, and apply the current parent ceilings. Keep this decision in the existing work record or session/tool state as described under Recovery and knowledge; no new planning file or user approval round-trip is required.

- **Explicit selection:** populate the supported profile arguments from the routing decision. Omitting them selects inheritance; verify that the inherited profile matches the decision and explain why it fits this unit. Missing or uncertain profile information is a reason to work locally or use a known suitable profile within the ceilings, not to accept an unchecked default.
- **New work for an existing agent:** reassess its profile before a resume or follow-up changes the unit. Existing context alone does not justify retaining a stronger profile. If the tool cannot change the profile, give a bounded handoff to a suitable new delegate or handle the unit locally. Retain a stronger profile only for a concrete benefit to this unit within the current ceilings, recorded in the routing decision. Status checks, clarification and continuation of the unchanged unit reuse its decision.
- **Observed profile:** when the runtime exposes the resolved profile, compare it with the decision. Resolve a mismatch before sending further work; stop an active delegate whose profile exceeds the authorized ceilings. When the resolved profile is unavailable, record only the requested or documented inherited profile, without claiming runtime verification.

## Decomposition and ownership

Decide whether to delegate separately from which model a unit needs. Delegate a concrete bounded unit when it brings at least one of these benefits:

- **Parallelism:** independent units can run at the same time.
- **Context protection:** a broad, read-heavy investigation (codebase sweep, multi-source research, large log or diff triage) would fill the parent's context when only its conclusion is needed, or a long task has a self-contained step whose details the parent does not need for integration and verification.
- **Independent assessment:** a fresh review or second opinion adds value.

The parent's own capability does not settle this: a parent that could do the unit itself still delegates when one of these benefits applies. Keep a unit local when briefing a delegate would cost about as much as doing it, such as a small edit or a lookup in a known file. Difficulty alone justifies neither another agent nor a stronger model. Identify each delegate's scope and how outputs will be consumed, plus the parent's independent work when parallelizing. When a delegated unit blocks the next step, wait for and consume its result.

A second opinion does not by itself require the strongest available model. For a fresh assessment, provide requirements, artifacts, and evaluation criteria without presenting the parent's preferred conclusion as the expected answer; use a context mode that supports that independence.

Continue independent work while delegates run; wait when the next action depends on their output. Do not re-investigate the same question in parallel or treat silence as failure. If a delegate appears stuck, inspect its status, steer it, or stop it before taking over. Deliberate independent review must be intentional and disclosed, not a silent hedge.

Use the runtime's read-only exploration role for specific codebase questions and its worker role for implementation. Give parallel writers non-overlapping ownership; never have another worker revert or overwrite a teammate's changes. Prefer isolation when the runtime supports it and the work benefits from it, but account for the actual filesystem mode when integrating.

## The task-file `delegation:` field records strategy, not permission

The `/cda-plan` task-file field carries a plan into execution; it does not authorize execution or override runtime restrictions:

- **`none`** — no strategy recorded; use harness judgment when execution is authorized. It does not prohibit delegation.
- **`strategy-only`** — use the recorded decomposition where it fits; no extra delegation approval round-trip.
- **`authorized`** — the user selected a specific delegation plan; follow it when execution is authorized.

Keep decomposition, ownership, review responsibilities, cost ceilings, and useful concurrency limits in the existing Plan of Work / Memory Hints. Do not add an always-required planning schema for trivial work.

## Worker prompt contract

Context inheritance varies by runtime and spawn mode: a worker may receive full history, selected turns, or only its prompt. Check the active schema and selected mode. Always give a self-contained assignment so neither missing context nor inherited parent instructions change the worker's role:

- **Goal and boundary:** the required outcome; the recipient is the delegated worker for this unit, not the control session. Inherited history is reference context.
- **Ownership:** exact files/modules it may edit or the bounded read-only question; state that it is not alone and must preserve others' work.
- **Constraints:** applicable contracts, authorization, compatibility, validation, and cost limits; provide paths to necessary references.
- **Runtime:** shared filesystem or isolated checkout when known, and how to return changes.
- **Output:** concrete findings anchored to files, changed files, validation commands/results, and unresolved risks. Do not claim completion without evidence.

Provide the smallest context that preserves the relevant contracts and evidence; omitting necessary context can cause repeated investigation or rework.

## Integrating and verifying results

- **Shared filesystem:** edits are already visible. Inspect the diff and reconcile ownership; do not reapply patches or perform a fictitious merge.
- **Isolated checkout or returned patch:** review first, then integrate in dependency order using an authorized mechanism. Delegation does not authorize subagents to create Git commits, merges, pushes, or destructive conflict resolution. The parent owns Git-history integration: inspect and verify the combined result, then stage/commit it under `.claude/rules/git-workflow.md` when that policy allows.
- Resolve conflicts in the parent. Check the combined effect with validation appropriate to the changed surface; inspect existing worker evidence before repeating checks. Re-run when integration changes behavior, evidence is missing/stale, or concerns remain.
- Apply the per-unit retry budget above; changing the worker or model does not reset it.
- Consume all required results before claiming the overall task complete. Relay the findings and limitations that matter to the user regardless of how the client displays worker messages.

## Recovery and knowledge

For long-running work with an authorized task/spec workspace, record outstanding delegations before dispatch in its existing recovery surface (task notes or spec LEDGER): routing decision, worker, expected output, and integration location. Update the decision when the unit or profile changes; mark results consumed. For a read-only or one-off task without authorized persistent state, retain that information in session/tool state and report it if handing off; delegation alone does not permit writing CONTEXT or canonical knowledge.

For retrospectives, record significant coordination incidents, such as costly rework or a capability-driven escalation/takeover, in the existing authorized work surface or handoff: affected unit/model, evidence, and corrective action. Do not require a retrospective report for every spawn. Use repeated evidence of capability limits to route similar units higher within the ceiling; do not turn an isolated failure into a global judgment about a model.

Treat returned knowledge as evidence to verify. WIP, proposals, and uncertainty remain candidates in an authorized work surface; recurring behavior goes through `/cda-learn`. Before a durable fact promotion or assigned knowledge mutation, follow `knowledge-management.md` and its maintenance reference, including capture triggers, owner + reachable-map atomicity, and checker validation. A knowledge-writing worker must own both topic and map; after integration verify the checker result covers the resulting state. Do not rely on worker thread history as durable project memory.

## Cost and recursion

- Optimize total work to a verified outcome, including parent coordination, worker context, retries, integration, and validation; token totals or per-call model prices alone do not establish savings.
- Keep delegation one level deep unless the user explicitly asks for recursion; host limits still apply.
- Respect the parent's model and any selectable reasoning-effort ceilings. An unclear or unsupported override is not permission to spend upward.
- Keep concurrency conservative and within the active host configuration; match fan-out to useful independent units and the user's cost constraints.
- Use read-only permissions for read-only delegates where the runtime supports them.
