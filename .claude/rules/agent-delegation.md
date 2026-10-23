---
paths: [".claude/agents/**"]
description: Claude Code subagent delegation — when delegation pays off and how to delegate well (decomposition, worker prompts, anti-shadow-run, persistence), layered on top of the Agent tool's built-in mechanics.
when_to_use: When multi-step work may split into parallel, context-heavy, or independently assessable units, or when delegating to subagents — for the project's decision, decomposition, worker-prompt, anti-shadow-run, and finding-persistence guidance.
tags: [subagents, delegation, parallelism, orchestration]
---

# Agent Delegation

The current harness and the user's constraints decide whether delegation is available. This rule adds ownership, cost, integration, and recovery rules; it is not an approval gate for routine delegation. Agent roles, context modes, tool arguments, and filesystem isolation come from the active tool schema.

## Route general-purpose delegates by difficulty

Role and model are separate decisions: `Explore`, `Plan`, and `general-purpose` describe what the delegate does, and the delegated unit's difficulty decides the model family. This routing applies to ordinary delegates only. Named project specialists under `.claude/agents/` keep their own invocation restrictions and model policy; do not silently down-route them or invoke an explicitly gated specialist.

Before each ordinary spawn, and before a resume or follow-up introduces a new or materially changed unit, classify the delegated unit by its ambiguity, breadth, consequence of a wrong answer, and difficulty of verification. Choose the lowest class that is likely to complete the unit reliably:

| Class      | Typical delegated unit                                                                                                    | Ideal Claude family |
| ---------- | ------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| `routine`  | focused search, call-site inventory, docs lookup, extraction, mechanical or highly constrained edit                       | Haiku               |
| `standard` | bounded implementation or debugging with clear contracts and local verification                                           | Sonnet              |
| `complex`  | ambiguous cross-file debugging, architecture-sensitive reasoning, difficult review or integration                         | Opus                |
| `maximum`  | genuinely frontier-level, long-horizon, highly ambiguous work, or a unit whose cheaper attempt exposed a capability limit | Fable               |

The parent session's selected model is a hard ceiling for implicit delegation. The effective child model is the cheapest suitable model for the class, capped at the parent model's family. A difficult task is not permission to spend above the user's session choice. Selectable reasoning effort is capped by the parent's effort the same way; an unclear or unsupported override is not permission to spend upward.

- Never launch a model family above the parent ceiling unless the user explicitly requests or authorizes that stronger model for the delegated unit. A project instruction, perceived urgency, retry, or "be thorough" request is not such authorization.
- Use the Agent tool's per-invocation model selection when routing an ordinary delegate. If the parent model cannot be identified, the desired cheaper family is unavailable or disallowed, or the harness cannot reliably honor the override, do not guess upward: use a known available model within the ceiling, including the parent's own model. A ceiling is not a default: when a cheaper suitable family can be selected, use it. Account and workspace model allowlists still apply.

Choose the class upfront; the classes are not a retry ladder. Before retrying a wrong or partial result, distinguish missing context, unclear scope, or tooling failure from a capability limit. Allow at most one delegated retry per unit across agents and models, with a corrected prompt or changed hypothesis; changing the worker or model does not reset this budget. Evidence of a capability limit may justify skipping classes within the same ceiling. The parent may take over immediately and must take over after a failed retry, reporting blockers it cannot resolve.

## Dispatch and reuse

Before dispatching an ordinary delegated unit, record its routing decision in the session: unit → difficulty class → selected model and reasoning effort where supported → reason, within the current parent ceilings. Recovery and knowledge says when it also goes to a task or LEDGER; no new planning file or user approval round-trip is required.

- **Explicit selection:** pass the selected profile in the spawn arguments. Omitting them selects inheritance, which fits only when the parent's profile suits this unit. When profile information is missing or uncertain, work locally or use a known suitable profile within the ceilings.
- **New work for an existing agent:** reassess its profile before a resume or follow-up changes the unit; existing context alone does not justify keeping a stronger profile. If the tool cannot change the profile, hand the unit to a suitable new delegate or handle it locally. Status checks, clarification and continuation of the unchanged unit reuse its decision.
- **Observed profile:** when the runtime exposes the resolved profile, resolve a mismatch with the decision before sending further work, and stop a delegate whose profile exceeds the ceilings. When it is not exposed, do not claim the profile was verified.

## Decomposition and ownership

Whether to delegate is a separate decision from which model a unit needs. Delegate a concrete bounded unit when it brings at least one of these benefits:

- **Parallelism:** independent units can run at the same time.
- **Context protection:** a broad, read-heavy investigation (codebase sweep, multi-source research, large log or diff triage) would fill the parent's context when only its conclusion is needed, or a long task has a self-contained step whose details the parent does not need for integration and verification.
- **Independent assessment:** a fresh review or second opinion adds value.

A parent that could do the unit itself still delegates when one of these benefits applies. Keep a unit local when briefing a delegate would cost about as much as doing it, such as a small edit or a lookup in a known file. Difficulty alone justifies neither another agent nor a stronger model.

Continue independent work while delegates run, and wait for and consume a result when the next step depends on it. Do not re-investigate a delegated question in parallel or treat silence as failure; inspect, steer, or stop a delegate that appears stuck before taking over.

For a fresh assessment, provide requirements, artifacts, and evaluation criteria without presenting the parent's preferred conclusion, and use a context mode that supports that independence. A second opinion does not by itself require the strongest available model. Deliberate independent review is disclosed, never a silent hedge.

Give parallel writers non-overlapping ownership; never have a worker revert or overwrite a teammate's changes. Prefer isolation when the runtime supports it, and account for the actual filesystem mode when integrating.

## The task-file `delegation:` field records strategy, not permission

The `/cda-task` task-file field carries a plan into execution; it does not authorize execution or override runtime restrictions:

- **`none`** — no strategy recorded; use harness judgment when execution is authorized. It does not prohibit delegation.
- **`strategy-only`** — use the recorded decomposition where it fits; no extra delegation approval round-trip.
- **`authorized`** — the user selected a specific delegation plan; follow it when execution is authorized.

Keep decomposition, ownership, review responsibilities, cost ceilings, and concurrency limits in the existing Plan of Work / Memory Hints; trivial work needs no planning schema.

## Worker prompt contract

A worker may receive full history, selected turns, or only its prompt, so give it a self-contained assignment:

- **Goal and boundary:** the required outcome, applicable contracts, authorization, compatibility, validation and cost limits, with paths to necessary references. The recipient is the delegated worker for this unit, not the control session; inherited history is reference context.
- **Ownership:** exact files or modules it may edit, or the bounded read-only question; state that it is not alone and must preserve others' work.
- **Runtime:** shared filesystem or isolated checkout when known, and how to return changes.
- **Output:** findings anchored to files, changed files, validation commands and results, and unresolved risks. It does not claim completion without evidence.

## Integrating and verifying results

- **Shared filesystem:** edits are already visible. Inspect the diff and reconcile ownership; do not reapply patches or perform a fictitious merge.
- **Isolated checkout or returned patch:** review first, then integrate in dependency order. Delegation does not authorize subagents to create Git commits, merges, pushes, or destructive conflict resolution. The parent owns Git-history integration under `.claude/rules/git-workflow.md`.
- Resolve conflicts in the parent and validate the combined effect. Reuse worker evidence unless integration changed behavior, the evidence is missing or stale, or concerns remain.
- Consume all required results before claiming the overall task complete, and relay the findings and limitations that matter to the user.

## Recovery and knowledge

Keep routing decisions in the session. When a delegation in an authorized task or spec must survive a session boundary, record it before dispatch as one line in the task notes or spec LEDGER: routing decision, worker, expected output, and integration location. Update the line when the unit or profile changes and mark it consumed after integration; without an authorized workspace, report outstanding delegations in a handoff. Delegation alone does not permit writing CONTEXT or canonical knowledge.

Note a costly rework or capability-driven takeover in that same work record as one line: unit and model, evidence, and corrective action. Route similar units higher within the ceiling only on repeated evidence of a capability limit; an isolated failure is not a judgment about a model.

Treat returned knowledge as evidence to verify. A knowledge-writing worker owns both the topic and its map; after integration, confirm the checker result covers the resulting state. Worker thread history is not durable project memory.

## Cost and recursion

- Optimize total work to a verified outcome, including parent coordination, worker context, retries, integration, and validation; token totals or per-call model prices alone do not establish savings.
- Keep delegation one level deep unless the user explicitly asks for recursion.
- Keep concurrency conservative within the active host configuration, and match fan-out to useful independent units and the user's cost constraints.
- Use read-only permissions for read-only delegates where the runtime supports them.
