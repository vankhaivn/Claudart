---
paths: ["**/*"]
description: Canonical contract for routing, capturing, validating, and maintaining durable descriptive project knowledge under `.codex/knowledge/`.
when_to_use: When a task needs project knowledge beyond the root map, when the user asks to update or search prior project knowledge, or when a workflow audits or mutates `.codex/knowledge/`.
tags: [knowledge, retrieval, evidence, memory]
---

# Knowledge Management

`.codex/knowledge/` stores durable **descriptive** project facts. Topic Markdown is the source of truth; `INDEX.md` and `_maps/*.md` are compact routers. This file is the source of truth for the knowledge contract.

Read this guideline in full only when the current task retrieves, writes, audits, or refactors knowledge, or when the user asks for a knowledge update or prior-project evidence. Routine `$codex-start` reads only the root `INDEX.md`; it does not load this guideline, detail topics, domain maps, or the checker.

## Route With A Fixed Budget

1. Read `.codex/knowledge/INDEX.md`.
2. Follow at most 2 relevant `_maps/*.md` routes.
3. Select at most 3 direct topics using exact slug/name/alias first, then typed scope, triggers, description/type, and source match.
4. For each topic, inspect frontmatter and the heading outline, then read the smallest relevant section. Read the full body only when the task needs the whole invariant or the smaller view is insufficient.
5. Expand at most 2 one-hop `related` topics. Do not recurse through the graph.
6. Treat `review-needed`, conflicting, superseded, or retired material as context to verify, not current authority.

If routed context is insufficient, search actual repository evidence with bounded `rg` and Git queries across canonical sources, knowledge, task/spec archives, and targeted JOURNAL lines. Return file/section evidence and distinguish source text from inference. This is an internal fallback, not a recall command. Reading never writes, promotes, deletes, or records telemetry.

## Capture Gate And Destination

Promote a claim to knowledge only when all four tests pass:

- **Descriptive**: it states what the project is or how it currently works, not how an agent should behave.
- **Durable**: it remains useful beyond the current work. A narrowly scoped fact is valid when `scope` says where it applies.
- **Current**: it describes implemented reality, not a proposal, acceptance target, roadmap, backlog, or intended future state.
- **Evidenced**: repository evidence or an authoritative source supports it now.

Route everything else by kind:

- WIP, proposals, task status, acceptance state, and discoveries local to current work stay in the active task, spec, or `CONTEXT.md`.
- Recurring behavior, conventions, behavioral corrections, and reusable procedures go to the owning guideline through `$codex-learn`.
- Uncertain or conflicting observations remain candidates in the working artifact. If they invalidate an existing owner, set that owner to `review-needed`, preserve the evidence, and explain the uncertainty in `status_note`.

A natural-language request such as “update knowledge from what we just explored” is sufficient authorization to distill and write eligible facts immediately. Immediate promotion requires the capture gate plus one trigger: the user asks; a verified correction must land to avoid continuing from known-wrong canonical knowledge; confirmed source drift requires an owner trust/content update; or a lifecycle workflow reaches its promotion boundary. Otherwise keep the observation as a candidate. Checkpoint performs bulk maintenance and promotion; it is not the only write gate.

Never auto-write after every exploration. Never copy a transcript, chronology, or entire canonical document into knowledge. Reference the source and preserve only the compact fact needed for future routing.

## Mutation Contract

1. Confirm `.codex/scripts/knowledge-check.sh` exists before writing; missing checker is a High-severity installation problem.
2. Find the canonical owner before writing. Patch an existing focused topic before creating another.
3. Verify the claim and record scope/source information without inventing metadata.
4. Change the topic and its reachable route atomically in the same diff. Preserve curated hooks, grouping, order, and external routes.
5. Do not auto-delete topics. Do not auto-promote, retire, or supersede an ambiguous unindexed file.
6. After any knowledge mutation, run:

   ```bash
   bash .codex/scripts/knowledge-check.sh --root .
   ```

Fix in-scope mechanical failures before reporting success.

## Canonical Topic Frontmatter

Every topic uses the restricted grammar below. Required fields are `name`, `description`, `type`, `status`, and `updated`.

```yaml
---
name: example-service-contract
description: "Illustrative ownership and boundary facts for a synthetic service."
type: domain
status: active
updated: 2026-07-29
aliases:
  - "example service"
triggers:
  - "example boundary lookup"
scope:
  - "component:example-service"
  - "path:examples/service/**"
last_verified: 2026-07-29
sources:
  - "../../docs/example-service.md"
related:
  - "knowledge:example-adjacent-contract"
  - "guideline:example-service-safety"
supersedes:
  - "knowledge:example-retired-contract"
verify: "Recheck when the synthetic example service contract changes."
sensitivity: internal
---
```

Grammar:

- `name` is a kebab-case slug matching the filename.
- `description`, `verify`, and `status_note` are one-line double-quoted text.
- `type` is one of `domain`, `architecture`, `integration`, `glossary`, `reference`, or `agent-context`.
- `status` is one of `active`, `review-needed`, `superseded`, or `retired`.
- `updated` changes only when topic content changes. `last_verified` changes only after checking evidence.
- An `active` topic additionally requires `last_verified` and at least one of `sources` or `verify`.
- Every non-active topic requires a one-line double-quoted `status_note` explaining the review need or lifecycle state.
- Optional fields are `aliases`, `triggers`, `scope`, `last_verified`, `sources`, `related`, `supersedes`, `verify`, `status_note`, and `sensitivity`.
- Every list uses block form with two-space-indented, double-quoted items. Flow lists are forbidden.
- `scope` items are typed `<selector>:<value>` strings; common selectors are `path`, `component`, `platform`, `environment`, `version`, and `symbol`.
- `related` items are typed `knowledge:<slug>` or `guideline:<slug>`. `supersedes` items are typed `knowledge:<slug>`.
- `sensitivity` is `public`, `internal`, or `restricted`.
- Folded or multiline scalars, single quotes, inline comments, YAML anchors/tags, and unrecognized fields are forbidden.

## Canonical Domain Map Frontmatter

Every `_maps/<domain>.md` file uses the same restricted scalar/list grammar and starts with:

```yaml
---
name: example-service
description: "Routes knowledge for an explicitly synthetic example service."
type: map
status: active
updated: 2026-07-29
triggers:
  - "example service"
scope:
  - "component:example-service"
last_verified: 2026-07-29
verify: "Recheck when the synthetic example service routing changes."
sensitivity: internal
---
```

- `name` matches the map filename.
- `type` is exactly `map`; status is only `active` or `review-needed`.
- An active map requires `last_verified` and at least one of `sources` or `verify`.
- A review-needed map requires `status_note`.
- Optional map fields are `aliases`, `triggers`, `scope`, `last_verified`, `sources`, `verify`, `status_note`, and `sensitivity`.
- A map routes topics only. `related` and `supersedes` are forbidden on maps.

## Router Grammar And Scale

Every knowledge route is exactly one compact line with no date:

```markdown
- [Title](relative.md) — <compact hook> · <type|map> · <status>
```

- A small store may route root → topic directly.
- Domain maps live at `_maps/<domain>.md`; the root routes to them with type `map`, and each map routes only to topics. Maps never link to other maps.
- Every active topic must be reachable from the root exactly once through a direct route or one domain map.
- A review-needed topic may remain unindexed while ownership is ambiguous. If routed for visibility, route it at most once and never present it as active authority.
- Create domain maps when active topics exceed 24 or the root exceeds 1,200 visible words. Preserve deliberate direct/external routes while reorganizing.
- A topic over 10 KiB is a split candidate, not an automatic rewrite. Keep using outline/section-first retrieval until a reviewed split preserves ownership and links.
- Hooks route; they do not summarize the whole topic or expose restricted details.
