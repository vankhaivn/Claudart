---
description: Create or resume a lightweight persistent task workspace in .claudart/tasks/ when work benefits from a durable plan; execute it too when the user has already asked to implement.
---

Create or resume a persistent task workspace whose `TASK.md` is the authoritative plan. Before acting, read `.claude/rules/task-management.md`; it owns the workspace schema, artifact rules, state machine, approval signals, progress updates, resumption, and completion gate. Read `.claude/rules/agent-delegation.md` only when delegation is relevant.

## Inputs and routing

- The text after `/cda-plan` is the task request. If it is empty, ask one short question: "What's the task?"
- Honor an explicit request for a persistent plan even for small work. Otherwise use a task when decisions, coordination, interruption, or review benefit from durable state. File count alone is not a reason.
- Use `/cda-spec` instead when the requested outcome is a defined mission needing POC-frozen intent, phases, standing approval, and multi-session convergence. When the project or product itself needs documentation before an implementation mission, use `/cda-project-docs` if installed; otherwise clarify intent within the current work and follow the repository's documentation convention.
- The user's current message has precedence for execution intent. A request to plan, explain, or review only keeps the planning lock. A direct request to implement, start, continue, or resume satisfies `planning → in-progress`, including when it appeared earlier and remains applicable.

## Create or select the workspace

Read `.claudart/CONTEXT.md`, `.claudart/tasks/index.md` if present, the root knowledge router, only relevant routed project context, relevant project docs, and recent Git history. Use the rule's shallow discovery rules because the index is a cache.

Reuse an active workspace that already owns the request. If several plausibly match and the user's selection is unclear, ask which one. Keep its id and history. When its status is not `planning`, route directly through the rule's resumption or review flow.

For a new task, allocate `.claudart/tasks/YYYY-MM-DD-NNN-<slug>/TASK.md` under the canonical naming and collision rules. Seed it at `status: planning`, register it in `index.md`, and use the rule's required structure.

Classify the completion reviewer before the plan is ready under "Completion Reviewer": choose `user` for subjective judgment, required observations unavailable to the agent, explicit human approval, or mixed/unclear ownership; choose `agent` when every criterion is objective and agent-verifiable with no human gate. Visibility alone is not a user review requirement. Record the specific acceptance basis and its source in the Decision Log; do not invent a generic confirmation checkbox. Preserve explicit human approval requirements and complete the agent's own verification before closeout.

**Default to `TASK.md` only.** Create `artifacts/` only when the canonical artifact trigger passes; link existing project files and keep short findings in `TASK.md`. Never automatically extract archives, execute attachments, or load all supporting files.

## Plan under the lock

While status is `planning`, inspect relevant evidence read-only and maintain only allowed planning state. No implementation code, scaffolding, runnable POCs, or write-scope workers. Locate the affected surface, record decisions and non-obvious constraints, and give every Concrete Step an observable `verify:` check. Keep the plan at decision altitude: it carries chosen outcomes and proof, not snippets or line-level solutions.

Before presenting the plan, read `TASK.md` once with fresh eyes and fix missing context, references, reviewer classification, or acceptance gaps.

Then present a compact **User Plan Brief** in the user's language. Do not paste the task file and do not tell the user to open or review `TASK.md` as the normal approval step. Summarize:

- **Current state** — the problem or missing behavior now.
- **Desired outcome** — the result this task is meant to produce.
- **Plan** — usually 3–5 short, plain-language steps that group the lower-level task details.
- **Review / approval** — `reviewer: user | agent`, what the user will actually need to verify at completion (if anything), and any unresolved decision that blocks starting.

Keep the brief focused on what the user needs to understand and decide. Do not lead with workspace paths, status metadata, checkbox counts, timestamps, or verification syntax. You may show the task path after the brief as a reference, not as homework.

If the user asked only for planning, remain at `planning` and end with one direct approval prompt after the brief. If execution is already authorized by the current request or an earlier still-applicable instruction, do not ask again: present the brief, flip to `in-progress`, bump `updated:`, and execute through the rule's progress and reviewer-gated completion contract. User-reviewed tasks still stop at `awaiting-review`; agent-reviewed tasks may self-close only after every acceptance criterion is proven under the conservative reviewer rules.

## Boundaries

- A task workspace changes persistence, not scope or external permissions.
- Material scope, public behavior, architecture, dependency, cost, security/privacy, or data changes outside the authorized outcome require a user decision.
- Do not create a task and spec for the same work.
- Do not treat enthusiasm, questions, silence, or edits to the plan as approval.
