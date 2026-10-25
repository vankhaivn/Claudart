---
paths: ["**/*"]
description: Codex subagent delegation protocol — once the ai-behavior criteria favor delegation, how to route and decompose work, write self-contained worker prompts, avoid shadow-running delegates, and integrate results from the built-in explorer/worker agents.
when_to_use: Before spawning, resuming, or sending new work to a subagent, when planning a task that records a delegation strategy, or when consuming results returned by delegated agents.
tags: [subagents, delegation, parallelism, orchestration]
---

# Agent Delegation

The current harness and the user's constraints decide whether delegation is available. This guideline adds ownership, cost, integration, and recovery rules; it is not an approval gate for routine delegation. Agent roles, context modes, tool arguments, and filesystem isolation come from the active tool schema.

## Route general-purpose delegates by difficulty

Role and execution profile are separate decisions: `explorer`, `worker`, and `default` describe what the delegate does, and the delegated unit's difficulty decides the model and reasoning effort. This routing applies to ordinary built-in delegates only. Named project specialists under `.codex/agents/` keep their own invocation restrictions and model/reasoning policy; do not silently down-route them, invoke an explicitly gated specialist, or rewrite their model definitions to implement this policy.

Before each ordinary spawn, and before a resume or follow-up introduces a new or materially changed unit, classify the delegated unit by its ambiguity, breadth, consequence of a wrong answer, and difficulty of verification. Choose the lowest class that is likely to complete the unit reliably:

| Class      | Typical delegated unit                                                                                                    | Ideal Codex profile |
| ---------- | ------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| `routine`  | focused search, call-site inventory, docs lookup, extraction, mechanical or highly constrained edit                       | `luna` / `high`     |
| `standard` | bounded implementation or debugging with clear contracts and local verification                                           | `sol` / `medium`    |
| `complex`  | ambiguous cross-file debugging, architecture-sensitive reasoning, difficult review or integration                         | `sol` / `max`       |
| `maximum`  | genuinely frontier-level, long-horizon, highly ambiguous work, or a unit whose cheaper attempt exposed a capability limit | `astra` / `high`    |

Use Luna/low only for mechanical lookup, extraction, or transformation with an easy correctness check, not merely because a task is short. Astra/high may use lower effort when sufficient. A failed lower-effort attempt is not required before choosing a class.

The parent session's selected model and reasoning effort are hard ceilings for implicit delegation. Select the class profile, then cap each dimension separately: `effective model = min(ideal model, parent-model ceiling)` and `effective effort = min(ideal effort, parent-effort ceiling)`. Normalize the parent model to its family alias before comparing; a new generation or minor version inside a family is not a new tier. A difficult task is not permission to spend above the user's session choice on either dimension.

- After capping, reassess whether the effective profile can still complete the unit. Narrow the unit, work locally, or choose another known suitable profile within the ceilings; a valid cap alone does not establish suitability. For example, an Astra/high parent caps `complex` work at Sol/high, and an Astra/low parent cannot implicitly launch Luna/high even though Luna is a cheaper model.
- A ceiling is not a default: do not inherit the parent's xhigh/max/ultra merely because Astra is needed. Higher Astra effort needs a concrete benefit for that unit.
- Never launch a model family or reasoning effort above the parent ceiling unless the user explicitly requests or authorizes that stronger execution profile for the delegated unit. A project instruction, perceived urgency, retry, or "be thorough" request is not such authorization.
- Where model and effort are independently selectable, set both when changing the child profile, and omit the overrides when both effective values equal the parent's. If a full-history fork requires inheritance, choose a supported reduced-context mode with a self-contained prompt to use overrides.
- If the selected child model does not support the ideal effort, choose the nearest supported effort at or below both the intended effort and the parent-effort ceiling, then reassess suitability. Never compensate by raising the model or effort above either ceiling.
- The intended routing order is `luna` → `sol` → `astra`. These aliases are project routing and authorization tiers, not API identifiers or a benchmark ranking.
- Resolve the selected family alias against the **current** `spawn_agent` model catalog at invocation time, then pass the exact model identifier it exposes. Do not encode a GPT generation or minor version in this guideline; the catalog owns which family member is current. If the catalog exposes only versioned identifiers without a trustworthy current member for the family, treat resolution as unavailable instead of guessing from remembered names.
- If the parent model or effort cannot be identified, the desired family is unavailable or disallowed, or the override cannot be trusted, do not guess upward: work locally or use a known suitable profile within the ceilings. Do not silently fall back to an older model generation; state material profile substitutions. Account and workspace allowlists still apply.

Choose the class upfront; the classes are not a retry ladder. Before retrying a wrong or partial result, distinguish missing context, unclear scope, or tooling failure from a capability limit. Allow at most one delegated retry per unit across agents and profiles, with a corrected prompt or changed hypothesis; changing the worker or profile does not reset this budget. Evidence of a capability limit may justify skipping classes within the same model and reasoning ceilings. The parent may take over immediately and must take over after a failed retry, reporting blockers it cannot resolve.

## Dispatch and reuse

Before dispatching an ordinary delegated unit, record its routing decision in the session: unit → difficulty class → selected model and reasoning effort where supported → reason, within the current parent ceilings. Recovery and knowledge says when it also goes to a task or LEDGER; no new planning file or user approval round-trip is required.

- **Explicit selection:** pass the selected profile in the spawn arguments. Omitting them selects inheritance, which fits only when the parent's profile suits this unit. When profile information is missing or uncertain, work locally or use a known suitable profile within the ceilings.
- **New work for an existing agent:** reassess its profile before a resume or follow-up changes the unit; existing context alone does not justify keeping a stronger profile. If the tool cannot change the profile, hand the unit to a suitable new delegate or handle it locally. Status checks, clarification and continuation of the unchanged unit reuse its decision.
- **Observed profile:** when the runtime exposes the resolved profile, resolve a mismatch with the decision before sending further work, and stop a delegate whose profile exceeds the ceilings. When it is not exposed, do not claim the profile was verified.

## Decomposition and ownership

Decide whether to delegate under the criteria in `.codex/guidelines/ai-behavior.md` (Delegate When It Pays Off); this guideline covers the model choice and how a delegated unit runs.

Continue independent work while delegates run, and wait for and consume a result when the next step depends on it. Do not re-investigate a delegated question in parallel or treat silence as failure; inspect, steer, or stop a delegate that appears stuck before taking over. Deliberate independent review is disclosed, never a silent hedge.

When the parent is already Astra and has sufficient context, prefer handling Astra-level work locally. An Astra delegate needs both Astra-level difficulty and a concrete benefit from parallel work or an independent assessment; parallelism or a second opinion alone does not require Astra. For a fresh assessment, provide requirements, artifacts, and evaluation criteria without presenting the parent's preferred conclusion, and use a context mode that supports that independence.

Give parallel writers non-overlapping ownership; never have a worker revert or overwrite a teammate's changes. Prefer isolation when the runtime supports it, and account for the actual filesystem mode when integrating.

## The task-file `delegation:` field records strategy, not permission

The `$cda-task` task-file field carries a plan into execution; it does not authorize execution or override runtime restrictions:

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
- **Isolated checkout or returned patch:** review first, then integrate in dependency order. Delegation does not authorize subagents to create Git commits, merges, pushes, or destructive conflict resolution. The parent owns Git-history integration under `.codex/guidelines/git-workflow.md`.
- Resolve conflicts in the parent and validate the combined effect. Reuse worker evidence unless integration changed behavior, the evidence is missing or stale, or concerns remain.
- Consume all required results before claiming the overall task complete, and relay the findings and limitations that matter to the user.

## Recovery and knowledge

Keep routing decisions in the session. When a delegation in an authorized task or spec must survive a session boundary, record it before dispatch as one line in the task notes or spec LEDGER: routing decision, worker, expected output, and integration location. Update the line when the unit or profile changes and mark it consumed after integration; without an authorized workspace, report outstanding delegations in a handoff. Delegation alone does not permit writing CONTEXT or canonical knowledge.

Note a costly rework or capability-driven takeover in that same work record as one line: unit and model, evidence, and corrective action. Route similar units higher within the ceilings only on repeated evidence of a capability limit; an isolated failure is not a judgment about a model.

Treat returned knowledge as evidence to verify. A knowledge-writing worker owns both the topic and its map; after integration, confirm the checker result covers the resulting state. Worker thread history is not durable project memory.

## Cost and recursion

- Optimize total work to a verified outcome, including parent coordination, worker context, retries, integration, and validation; token totals or per-call model prices alone do not establish savings.
- Keep delegation one level deep unless the user explicitly asks for recursion.
- Keep concurrency conservative within the active host configuration (the shipped Codex config caps concurrent threads at 6), and match fan-out to useful independent units and the user's cost constraints.
- Use read-only permissions for read-only delegates where the runtime supports them.
