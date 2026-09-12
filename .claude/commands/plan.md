---
description: Create or resume a lightweight persistent task workspace in .claude/tasks/ when work benefits from a durable plan; execute it too when the user has already asked to implement.
---

Create or resume a persistent task workspace whose `TASK.md` is the authoritative plan. Before acting, read `.claude/rules/task-management.md`; it owns the workspace schema, artifact rules, state machine, approval signals, progress updates, resumption, and completion gate. Read `.claude/rules/agent-delegation.md` only when delegation is relevant.

## Inputs and routing

- The text after `/plan` is the task request. If it is empty, ask one short question: "What's the task?"
- Honor an explicit request for a persistent plan even for small work. Otherwise use a task when decisions, coordination, interruption, or review benefit from durable state. File count alone is not a reason.
- Use `/spec` instead when the requested outcome is a defined mission needing POC-frozen intent, phases, standing approval, and multi-session convergence. Use `/project-discovery` when the project or product itself is still undefined and the user needs project documentation before choosing an implementation mission.
- The user's current message has precedence for execution intent. A request to plan, explain, or review only keeps the planning lock. A direct request to implement, start, continue, or resume satisfies `planning → in-progress`, including when it appeared earlier and remains applicable.

## Create or select the workspace

Read `.claude/CONTEXT.md`, `.claude/tasks/index.md` if present, the root knowledge router, only relevant routed project context, relevant project docs, and recent Git history. Use the rule's shallow discovery rules because the index is a cache.

Reuse an active workspace that already owns the request. If several plausibly match and the user's selection is unclear, ask which one. Keep its id and history. When its status is not `planning`, route directly through the rule's resumption or review flow.

For a new task, allocate `.claude/tasks/YYYY-MM-DD-NNN-<slug>/TASK.md` under the canonical naming and collision rules. Seed it at `status: planning`, register it in `index.md`, and use the rule's required structure. **Default to `TASK.md` only.** Create `artifacts/` only when the canonical artifact trigger passes; link existing project files and keep short findings in `TASK.md`. Never automatically extract archives, execute attachments, or load all supporting files.

## Plan under the lock

While status is `planning`, inspect relevant evidence read-only and maintain only allowed planning state. No implementation code, scaffolding, runnable POCs, or write-scope workers. Locate the affected surface, record decisions and non-obvious constraints, and give every Concrete Step an observable `verify:` check. Keep the plan at decision altitude: it carries chosen outcomes and proof, not snippets or line-level solutions.

Before presenting the plan, read it once with fresh eyes and fix missing context or references. Report its workspace, status, step/check counts, and open questions.

If the user asked only for planning, stop at `planning` and tell them that a direct "go" or implementation request will start it. If execution is already authorized by the current request or an earlier still-applicable instruction, do not ask again: flip to `in-progress`, bump `updated:`, and execute through the rule's progress and two-phase completion contract. The final `awaiting-review → done` transition still requires the user's confirmation.

## Boundaries

- A task workspace changes persistence, not scope or external permissions.
- Material scope, public behavior, architecture, dependency, cost, security/privacy, or data changes outside the authorized outcome require a user decision.
- Do not create a task and spec for the same work.
- Do not treat enthusiasm, questions, silence, or edits to the plan as approval.
