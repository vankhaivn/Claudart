# Knowledge Maintenance

Read this reference only when a task creates, updates, routes, normalizes, audits, or refactors `.codex/knowledge/`. Apply the four-part classification and retrieval bounds in `.codex/guidelines/knowledge-management.md` first. This reference does not grant authority beyond the current task.

## Capture Authority And Destination

An eligible fact may be promoted immediately only when at least one trigger applies:

- the user asks for a knowledge update in natural language;
- a verified correction must land to avoid continued reliance on known-wrong canonical knowledge;
- confirmed source drift requires an owner trust or content update;
- a lifecycle workflow reaches its defined promotion boundary.

Otherwise preserve the observation as a candidate in its owning work artifact. `$codex-checkpoint` performs bulk maintenance and promotion, but it is not the only write gate.

Never auto-write after every exploration. Never copy a transcript, chronology, or entire canonical document into knowledge. Reference the source and preserve only the compact fact needed for future routing. If uncertainty or conflict invalidates an existing owner, set it to `review-needed`, preserve the evidence, and explain the uncertainty in `status_note`.

## Mutation Contract

1. Confirm `.codex/scripts/knowledge-check.sh` exists before writing. A missing checker is a High-severity installation problem and blocks the mutation.
2. Find the canonical owner. Patch an existing focused topic before creating another.
3. Verify the claim and record scope/source information without inventing metadata.
4. Change the topic and its reachable route atomically in the same diff. Preserve curated hooks, grouping, order, and external routes.
5. Do not auto-delete topics. Do not auto-promote, retire, or supersede an ambiguous unindexed file.
6. After any knowledge mutation, run:

   ```bash
   bash .codex/scripts/knowledge-check.sh --root .
   ```

Fix in-scope mechanical failures before reporting success. For an audit or refactor, use the checker as the mechanical baseline and preserve its schema and severity output rather than recreating its parser.

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

- `name` is a kebab-case slug matching the filename.
- `description`, `verify`, and `status_note` are one-line double-quoted text.
- `type` is `domain`, `architecture`, `integration`, `glossary`, `reference`, or `agent-context`.
- `status` is `active`, `review-needed`, `superseded`, or `retired`.
- `updated` changes only when topic content changes. `last_verified` changes only after checking evidence.
- An active topic additionally requires `last_verified` and at least one of `sources` or `verify`.
- Every non-active topic requires a one-line double-quoted `status_note` explaining the review need or lifecycle state.
- Optional fields are `aliases`, `triggers`, `scope`, `last_verified`, `sources`, `related`, `supersedes`, `verify`, `status_note`, and `sensitivity`.
- Every list uses block form with two-space-indented, double-quoted items. Flow lists are forbidden.
- `scope` items are typed `<selector>:<value>` strings; common selectors are `path`, `component`, `platform`, `environment`, `version`, and `symbol`.
- `related` items are typed `knowledge:<slug>` or `guideline:<slug>`. `supersedes` items are typed `knowledge:<slug>`.
- `sensitivity` is `public`, `internal`, or `restricted`.
- Folded or multiline scalars, single quotes, inline comments, YAML anchors/tags, and unrecognized fields are forbidden.

## Canonical Domain Map Frontmatter

Every `_maps/<domain>.md` uses the same restricted scalar/list grammar and starts with:

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

## Router Grammar And Lifecycle

Every knowledge route is exactly one compact line with no date:

```markdown
- [Title](relative.md) — <compact hook> · <type|map> · <status>
```

- A small store may route root → topic directly.
- Domain maps live at `_maps/<domain>.md`; the root routes to them with type `map`, and each map routes only to topics. Maps never link to other maps.
- Every active topic must be reachable from the root exactly once through a direct route or one domain map.
- A `review-needed` topic may remain unindexed while ownership is ambiguous. If routed for visibility, route it at most once and never present it as active authority.
- Create domain maps when active topics exceed 24 or the root exceeds 1,200 visible words. Preserve deliberate direct and external routes while reorganizing.
- A topic over 10 KiB is a split candidate, not an automatic rewrite. Keep using outline/section-first retrieval until a reviewed split preserves ownership and links.
- Hooks route; they do not summarize the whole topic or expose restricted details.
