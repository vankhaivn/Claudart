---
paths: ["**/*"]
description: Codex subagent delegation protocol — how to decompose work, write self-contained worker prompts, avoid shadow-running delegates, and integrate results from the built-in explorer/worker agents.
when_to_use: When work may parallelize across subagents, when planning a task that records a delegation strategy, or when consuming results returned by delegated agents.
tags: [subagents, delegation, parallelism, orchestration]
---

# Agent Delegation

Use the current harness and the user's constraints to decide whether delegation is available and appropriate. This protocol supplies ownership, cost, integration, and recovery rules; it does not add an approval gate for routine delegation. Available agent roles, context modes, tool arguments, and filesystem isolation come from the active tool schema, not assumptions about another client or model setting.

The routing policy below applies to ordinary general-purpose delegates. Named project specialists retain their own invocation restrictions and model policy; do not silently down-route or invoke an explicitly gated specialist.

## Route general-purpose delegates by difficulty

Role selection and execution-profile selection are separate decisions. `explorer`, `worker`, and `default` describe **what** the delegate does; the delegated unit's difficulty determines **which model and reasoning effort** should do it. This section applies only to ordinary built-in delegation. Named project specialists under `.codex/agents/` keep their existing model/reasoning policy and must not be silently down-routed by this guideline.

Before each ordinary spawn, classify the delegated unit by its ambiguity, breadth, consequence of a wrong answer, and difficulty of verification. Choose the lowest class that is likely to complete the unit reliably:

| Class      | Typical delegated unit                                                                                                    | Ideal Codex profile                    |
| ---------- | ------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- |
| `routine`  | focused search, call-site inventory, docs lookup, extraction, mechanical or highly constrained edit                       | `gpt-5.6-luna` / `low`                 |
| `standard` | bounded implementation or debugging with clear contracts and local verification                                           | `gpt-5.6-terra` / `medium`             |
| `complex`  | ambiguous cross-file debugging, architecture-sensitive reasoning, difficult review or integration                         | `gpt-5.6-sol` / `high`                 |
| `maximum`  | genuinely frontier-level, long-horizon, highly ambiguous work, or a unit whose cheaper attempt exposed a capability limit | `gpt-6-astra` / parent-selected effort |

The **parent session's selected model and reasoning effort are hard ceilings for implicit delegation**. Treat the child execution profile as two independent dimensions: choose the cheapest suitable model and the lowest sufficient reasoning effort for the class, then cap each at the parent session's selected setting. A difficult task is not permission to spend above the user's session choice on either dimension.

- Conceptually: `effective model = min(ideal model for task, parent-model ceiling)` and `effective effort = min(ideal effort for task, parent-effort ceiling)`.
- An Astra/high parent may route a `routine` unit to Luna/low, a `standard` unit to Terra/medium, a `complex` unit to Sol/high, and reserve Astra/high for `maximum` work.
- A Sol/medium parent caps both `complex` and `maximum` units at Sol/medium. A Terra/low parent caps the same way. The rule continues downward on both dimensions.
- **Never launch a model family or reasoning effort above the parent ceiling unless the user explicitly requests or authorizes that stronger execution profile for the delegated unit.** A project instruction, perceived urgency, retry, or "be thorough" request is not such authorization.
- Use the current tool schema for profile overrides and context inheritance. Where model and effort are independently selectable, set **both** when changing the child profile. If a full-history fork requires inheritance, choose a supported reduced-context mode with a self-contained prompt to use overrides, or inherit within the ceilings. If both effective values equal the parent's values, omit the overrides.
- If the ideal effort is unsupported by the selected child model, choose the nearest supported effort that does not exceed the parent-effort ceiling. Never compensate for an unsupported effort by silently raising the model or effort above either ceiling.
- Use the exact model slug exposed by the current `spawn_agent` model catalog. The intended current routing order is `gpt-5.6-luna` → `gpt-5.6-terra` → `gpt-5.6-sol` → `gpt-6-astra`; availability can change, so respect account/workspace allowlists and never substitute a model above the parent ceiling.
- If the parent model/effort cannot be identified, the desired child profile is unavailable or disallowed, or the override cannot be trusted, do not guess upward: inherit the parent or choose a known available model/effort pair that is no more capable or compute-intensive than the parent.
- Do not rewrite the project's intentional custom-agent model definitions to implement this policy.

A retry may use a stronger class **within the same model and reasoning ceilings** when the returned evidence shows a capability failure rather than a bad prompt. Keep the existing one-retry limit: sharpen the prompt and, when justified, move the retry up one class; if that retry still fails, pull the unit back to the parent. Do not climb through multiple paid retries, and never cross either parent ceiling implicitly.

## Decomposition and ownership

Delegate a concrete bounded unit when it can run alongside useful independent work. Identify the parent's next work, each delegate's read-only question or exact write scope, and how outputs will be consumed. Do blocking work locally unless the user explicitly requested delegation of that unit. For such a delegate-only request, wait and consume its result.

Continue independent work while delegates run; wait when the next action depends on their output. Do not re-investigate the same question in parallel or treat silence as failure. If a delegate appears stuck, inspect its status, steer it, or stop it before taking over. Deliberate independent review must be intentional and disclosed, not a silent hedge.

Use the runtime's read-only exploration role for specific codebase questions and its worker role for implementation. Give parallel writers non-overlapping ownership; never have another worker revert or overwrite a teammate's changes. Prefer isolation when the runtime supports it and the work benefits from it, but account for the actual filesystem mode when integrating.

## The task-file `delegation:` field records strategy, not permission

The `$codex-plan` task-file field carries a plan into execution; it does not authorize execution or override runtime restrictions:

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

Treat returned knowledge as evidence to verify. WIP, proposals, and uncertainty remain candidates in an authorized work surface; recurring behavior goes through `$codex-learn`. Before a durable fact promotion or assigned knowledge mutation, follow `knowledge-management.md` and its maintenance reference, including capture triggers, owner + reachable-map atomicity, and checker validation. A knowledge-writing worker must own both topic and map; after integration verify the checker result covers the resulting state. Do not rely on worker thread history as durable project memory.

## Cost and recursion

- Keep delegation one level deep unless the user explicitly asks for recursion; host limits still apply.
- Respect the parent's model and any selectable reasoning-effort ceilings. An unclear or unsupported override is not permission to spend upward.
- Keep concurrency conservative and within the active host configuration (the shipped Codex config caps concurrent threads at 6); match fan-out to useful independent units and the user's cost constraints.
- Use read-only permissions for read-only delegates where the runtime supports them.
