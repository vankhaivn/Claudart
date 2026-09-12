---
paths: ["**/*"]
description: Bounded retrieval and classification contract for durable descriptive project knowledge under `.codex/knowledge/`; routes mutations and audits to the maintenance reference.
when_to_use: When a task retrieves or searches project knowledge, classifies a possible durable fact, or audits, mutates, or refactors `.codex/knowledge/`.
tags: [knowledge, retrieval, evidence, memory]
---

# Knowledge Management

`.codex/knowledge/` stores durable **descriptive** project facts and compact routes to other current owners. A topic owns a fact when no source code, schema, generated reference, project document, or other authoritative source already states that same claim as its maintained contract. Source code can be evidence for a distinct, useful synthesis in knowledge without owning that synthesis. `INDEX.md` and `_maps/*.md` are compact routers. Choose ownership by the subject and evidence, not by which agent or reader needs the information; keep one owner per fact and link from other surfaces.

This guideline is the root contract for retrieval and classification. Routine `$codex-start` reads only `.codex/knowledge/INDEX.md`; it does not load this guideline, detail topics, domain maps, the maintenance reference, or the checker.

## Load Maintenance Detail Only When Needed

- For retrieval, prior-project evidence, or classification without a write, use this guideline only.
- If the task creates, updates, routes, normalizes, audits, or refactors knowledge, read [`.codex/references/knowledge-maintenance.md`](../references/knowledge-maintenance.md) before acting. It owns write authorization triggers, lifecycle operations, canonical metadata and route schemas, and validation.
- An instruction from an existing workflow to read `knowledge-management.md` “in full” for a knowledge mutation or audit means read both this guideline and that maintenance reference. Do not load the maintenance reference for retrieval alone.

## Route With A Fixed Budget

1. Read `.codex/knowledge/INDEX.md`.
2. Follow at most 2 relevant `_maps/*.md` routes.
3. Select at most 3 direct topics using exact slug/name/alias first, then typed scope, triggers, description/type, and source match.
4. For each topic, inspect frontmatter and the heading outline, then read the smallest relevant section. Read the full body only when the task needs the whole invariant or the smaller view is insufficient.
5. Expand at most 2 one-hop `related` topics. Do not recurse through the graph.
6. Treat `review-needed`, conflicting, superseded, or retired material as context to verify, not current authority.

If routed context is insufficient, search actual repository evidence with bounded `rg` and Git queries across canonical sources, knowledge, task/spec archives, and targeted JOURNAL lines. Return file/section evidence and distinguish source text from inference. This is an internal fallback, not a recall command.

Retrieval never writes, promotes, deletes, changes trust state, or records telemetry.

## Classify Before Persistence

A claim qualifies for knowledge only when all four tests pass:

- **Descriptive**: it states what the project is or how it currently works, rather than how an agent should behave.
- **Durable**: it remains useful beyond the current work. A narrowly scoped fact is valid when its scope says where it applies.
- **Current**: it describes implemented reality rather than a proposal, acceptance target, roadmap, backlog, or intended future state.
- **Evidenced**: repository evidence or an authoritative source supports it now.

Passing these tests makes a claim eligible for knowledge routing, not necessarily a new canonical topic body. If another current source owns it, keep only the pointer or minimal agent-specific context needed to find and use that source. A knowledge topic may remain the owner when no other source owns the fact. If the optional Project Docs module is installed, its ownership and maintenance procedure applies to current project documents; the knowledge gate and checker still apply to knowledge mutations.

Route everything else by kind:

- WIP, proposals, task status, acceptance state, and discoveries local to current work stay in the active task, spec, or `CONTEXT.md`.
- Recurring behavior, conventions, behavioral corrections, and reusable procedures go to the owning guideline, normally through `$codex-learn`.
- Uncertain or conflicting observations remain candidates in the working artifact. Existing knowledge they call into question is not current authority until verified.

Eligibility does not authorize a write. Never mutate knowledge merely because retrieval found a qualifying claim, and never capture automatically after exploration. When the task includes an authorized mutation or a lifecycle workflow reaches a possible promotion boundary, load the maintenance reference and apply its trigger, owner, routing, and validation contract.
