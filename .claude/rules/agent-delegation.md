---
paths: [".claude/agents/**"]
description: Claude Code subagent delegation — project guidance on HOW to delegate well (decomposition, worker prompts, anti-shadow-run, persistence), layered on top of the Agent tool's built-in WHEN-to-delegate mechanics.
when_to_use: When delegating to subagents, or planning a task that may parallelize — for the project's decomposition, worker-prompt, anti-shadow-run, and finding-persistence guidance.
tags: [subagents, delegation, parallelism, orchestration]
---

# Agent Delegation

Use the current harness and the user's constraints to decide whether delegation is available and appropriate. This protocol supplies ownership, cost, integration, and recovery rules; it does not add an approval gate for routine delegation. Available agent roles, context modes, tool arguments, and filesystem isolation come from the active tool schema, not assumptions about another client or model setting.

The routing policy below applies to ordinary general-purpose delegates. Named project specialists retain their own invocation restrictions and model policy; do not silently down-route or invoke an explicitly gated specialist.

## Route general-purpose delegates by difficulty

Role selection and model selection are separate decisions. `Explore`, `Plan`, and `general-purpose` describe **what** the delegate does; the delegated unit's difficulty determines **which model family** should do it. This section applies only to ordinary delegation. Named project specialists under `.claude/agents/` keep their own model policy and must not be silently down-routed by this rule.

Before each ordinary spawn, classify the delegated unit by its ambiguity, breadth, consequence of a wrong answer, and difficulty of verification. Choose the lowest class that is likely to complete the unit reliably:

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
- Use the Agent tool's per-invocation model selection when routing an ordinary delegate. If the parent model cannot be identified, the desired cheaper family is unavailable or disallowed, or the harness cannot reliably honor the override, do not guess upward: inherit the parent or choose a known available model that is no more capable/expensive than the parent.
- Model availability and aliases can change. Treat the family ordering above as the routing intent, not permission to bypass account/workspace allowlists.

A retry may use a stronger class **within the same ceiling** when the returned evidence shows a capability failure rather than a bad prompt. Keep the existing one-retry limit: sharpen the prompt and, when justified, move the retry up one class; if that retry still fails, pull the unit back to the parent. Do not climb through multiple paid retries, and never cross the parent ceiling implicitly.

## Decomposition and ownership

Delegate a concrete bounded unit when it can run alongside useful independent work. Identify the parent's next work, each delegate's read-only question or exact write scope, and how outputs will be consumed. Do blocking work locally unless the user explicitly requested delegation of that unit. For such a delegate-only request, wait and consume its result.

Continue independent work while delegates run; wait when the next action depends on their output. Do not re-investigate the same question in parallel or treat silence as failure. If a delegate appears stuck, inspect its status, steer it, or stop it before taking over. Deliberate independent review must be intentional and disclosed, not a silent hedge.

Use the runtime's read-only exploration role for specific codebase questions and its worker role for implementation. Give parallel writers non-overlapping ownership; never have another worker revert or overwrite a teammate's changes. Prefer isolation when the runtime supports it and the work benefits from it, but account for the actual filesystem mode when integrating.

## The task-file `delegation:` field records strategy, not permission

The `/plan` task-file field carries a plan into execution; it does not authorize execution or override runtime restrictions:

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

## Integrating and verifying results

- **Shared filesystem:** edits are already visible. Inspect the diff and reconcile ownership; do not reapply patches or perform a fictitious merge.
- **Isolated checkout or returned patch:** review first, then integrate in dependency order using an authorized mechanism. Delegation does not authorize Git merges, commits, pushes, or destructive conflict resolution.
- Resolve conflicts in the parent. Check the combined effect with validation appropriate to the changed surface; inspect existing worker evidence before repeating checks. Re-run when integration changes behavior, evidence is missing/stale, or concerns remain.
- A wrong or partial result gets at most one retry with a corrected prompt or changed hypothesis. A capability-driven escalation must stay within the routing ceilings above. If it still fails, complete the unit locally; never repeat the identical attempt hoping for a different answer.
- Consume all required results before claiming the overall task complete. Relay the findings and limitations that matter to the user regardless of how the client displays worker messages.

## Recovery and knowledge

For long-running work with an authorized task/spec workspace, record outstanding delegations at spawn time in its existing recovery surface (task notes or spec LEDGER): unit, worker, selected profile when relevant, expected output, and integration location. Mark results consumed. For a read-only or one-off task without authorized persistent state, retain that information in session/tool state and report it if handing off; delegation alone does not permit writing CONTEXT or canonical knowledge.

Treat returned knowledge as evidence to verify. WIP, proposals, and uncertainty remain candidates in an authorized work surface; recurring behavior goes through `/learn`. Before a durable fact promotion or assigned knowledge mutation, follow `knowledge-management.md` and its maintenance reference, including capture triggers, owner + reachable-map atomicity, and checker validation. A knowledge-writing worker must own both topic and map; after integration verify the checker result covers the resulting state. Do not rely on worker thread history as durable project memory.

## Cost and recursion

- Keep delegation one level deep unless the user explicitly asks for recursion; host limits still apply.
- Respect the parent's model and any selectable reasoning-effort ceilings. An unclear or unsupported override is not permission to spend upward.
- Keep concurrency conservative and within the active host configuration; match fan-out to useful independent units and the user's cost constraints.
- Use read-only permissions for read-only delegates where the runtime supports them.
