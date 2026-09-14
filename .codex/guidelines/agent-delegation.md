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

| Class      | Typical delegated unit                                                                                                    | Ideal Codex profile        |
| ---------- | ------------------------------------------------------------------------------------------------------------------------- | -------------------------- |
| `routine`  | focused search, call-site inventory, docs lookup, extraction, mechanical or highly constrained edit                       | `gpt-5.6-luna` / `low`     |
| `standard` | bounded implementation or debugging with clear contracts and local verification                                           | `gpt-5.6-terra` / `medium` |
| `complex`  | ambiguous cross-file debugging, architecture-sensitive reasoning, difficult review or integration                         | `gpt-5.6-sol` / `high`     |
| `maximum`  | genuinely frontier-level, long-horizon, highly ambiguous work, or a unit whose cheaper attempt exposed a capability limit | `gpt-6-astra` / `high`     |

The **parent session's selected model and reasoning effort are hard ceilings for implicit delegation**. Treat the child execution profile as two independent dimensions: choose the cheapest suitable model and the lowest sufficient reasoning effort for the class, then cap each at the parent session's selected setting. A difficult task is not permission to spend above the user's session choice on either dimension.

- Conceptually: `effective model = min(ideal model for task, parent-model ceiling)` and `effective effort = min(ideal effort for task, parent-effort ceiling)`.
- A ceiling is not a default: use Astra/high for a justified Astra delegate unless lower effort suffices. Higher effort needs a concrete benefit for that unit within the authorized ceilings; do not inherit the parent's xhigh/max/ultra merely because Astra is needed. A failed lower-effort attempt is not required.
- An Astra/high parent may route a `routine` unit to Luna/low, a `standard` unit to Terra/medium, a `complex` unit to Sol/high, and reserve Astra/high for `maximum` work.
- A Sol/medium parent caps both `complex` and `maximum` units at Sol/medium. A Terra/low parent caps the same way. The rule continues downward on both dimensions.
- **Never launch a model family or reasoning effort above the parent ceiling unless the user explicitly requests or authorizes that stronger execution profile for the delegated unit.** A project instruction, perceived urgency, retry, or "be thorough" request is not such authorization.
- Use the current tool schema for profile overrides and context inheritance. Where model and effort are independently selectable, set **both** when changing the child profile. If a full-history fork requires inheritance, choose a supported reduced-context mode with a self-contained prompt to use overrides. Inherit only when the parent's full profile is suitable for the unit under these rules; if both effective values equal the parent's values, omit the overrides.
- If the ideal effort is unsupported by the selected child model, choose the nearest supported effort that does not exceed the parent-effort ceiling. Never compensate for an unsupported effort by silently raising the model or effort above either ceiling.
- Use the exact model slug exposed by the current `spawn_agent` model catalog. The intended current routing order is `gpt-5.6-luna` → `gpt-5.6-terra` → `gpt-5.6-sol` → `gpt-6-astra`; availability can change, so respect account/workspace allowlists and never substitute a model above the parent ceiling.
- If the parent model/effort cannot be identified, the desired child profile is unavailable or disallowed, or the override cannot be trusted, do not guess upward: work locally or use a known available profile within the ceilings. Inheritance still requires the suitability check above.
- Do not rewrite the project's intentional custom-agent model definitions to implement this policy.

The classes are routing options, not a mandatory retry ladder. Choose the appropriate class upfront. Before retrying a wrong or partial result, distinguish missing context, unclear scope, or tooling failure from a capability limit. Allow at most one delegated retry per unit across agents and profiles, with a corrected prompt or changed hypothesis; evidence of a capability limit may justify skipping classes **within the same model and reasoning ceilings**. A retry is optional: the parent may take over immediately and must take over after a failed retry, reporting blockers it cannot resolve.

## Decomposition and ownership

Decide whether to delegate separately from which model a unit needs. Delegate a concrete bounded unit for useful parallel work or a justified independent assessment. Size alone warrants neither more agents nor stronger models; difficulty alone does not justify another agent. Identify each delegate's scope and how outputs will be consumed, plus the parent's independent work when parallelizing. Keep blocking work local unless an independent assessment adds value or the user explicitly requested delegation; then wait and consume the result.

When the parent is already Astra and has sufficient context, prefer handling Astra-level work locally. An Astra delegate needs both Astra-level difficulty and a concrete benefit from independent parallel work or an independent assessment. Parallelism or a second opinion alone does not require Astra. For a fresh assessment, provide requirements, artifacts, and evaluation criteria without presenting the parent's preferred conclusion as the expected answer; use a context mode that supports that independence.

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

Provide the smallest context that preserves the relevant contracts and evidence; omitting necessary context can cause repeated investigation or rework.

## Integrating and verifying results

- **Shared filesystem:** edits are already visible. Inspect the diff and reconcile ownership; do not reapply patches or perform a fictitious merge.
- **Isolated checkout or returned patch:** review first, then integrate in dependency order using an authorized mechanism. Delegation does not authorize Git merges, commits, pushes, or destructive conflict resolution.
- Resolve conflicts in the parent. Check the combined effect with validation appropriate to the changed surface; inspect existing worker evidence before repeating checks. Re-run when integration changes behavior, evidence is missing/stale, or concerns remain.
- Apply the per-unit retry budget above; changing the worker or profile does not reset it.
- Consume all required results before claiming the overall task complete. Relay the findings and limitations that matter to the user regardless of how the client displays worker messages.

## Recovery and knowledge

For long-running work with an authorized task/spec workspace, record outstanding delegations at spawn time in its existing recovery surface (task notes or spec LEDGER): unit, worker, selected profile when relevant, expected output, and integration location. Mark results consumed. For a read-only or one-off task without authorized persistent state, retain that information in session/tool state and report it if handing off; delegation alone does not permit writing CONTEXT or canonical knowledge.

For retrospectives, record significant coordination incidents, such as costly rework or a capability-driven escalation/takeover, in the existing authorized work surface or handoff: affected unit/profile, evidence, and corrective action. Do not require a retrospective report for every spawn. Use repeated evidence of capability limits to route similar units higher within the ceilings; do not turn an isolated failure into a global judgment about a model.

Treat returned knowledge as evidence to verify. WIP, proposals, and uncertainty remain candidates in an authorized work surface; recurring behavior goes through `$codex-learn`. Before a durable fact promotion or assigned knowledge mutation, follow `knowledge-management.md` and its maintenance reference, including capture triggers, owner + reachable-map atomicity, and checker validation. A knowledge-writing worker must own both topic and map; after integration verify the checker result covers the resulting state. Do not rely on worker thread history as durable project memory.

## Cost and recursion

- Optimize total work to a verified outcome, including parent coordination, worker context, retries, integration, and validation; token totals or per-call model prices alone do not establish savings.
- Keep delegation one level deep unless the user explicitly asks for recursion; host limits still apply.
- Respect the parent's model and any selectable reasoning-effort ceilings. An unclear or unsupported override is not permission to spend upward.
- Keep concurrency conservative and within the active host configuration (the shipped Codex config caps concurrent threads at 6); match fan-out to useful independent units and the user's cost constraints.
- Use read-only permissions for read-only delegates where the runtime supports them.
