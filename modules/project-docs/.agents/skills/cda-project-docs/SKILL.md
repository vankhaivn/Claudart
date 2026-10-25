---
name: cda-project-docs
description: Establish, adopt, update, or review current project documentation and its sources of authority. Use for project-doc lifecycle requests; cleaning stale or duplicated docs belongs to cda-tidy. Use only when the user asks for it, by command or in words.
---

# Project Docs

Keep usable project documentation aligned with approved intent, observed behavior, and the sources that own each topic. Work within the user's scope and the repository's conventions. This optional skill requires no document pack, new state store, or fixed folder layout.

Infer the operation from the request; a mode name is optional:

- **Init:** establish docs for a new or lightly defined project. Read [bootstrap](references/bootstrap.md).
- **Adopt:** take on an existing project or scattered docs. Read [bootstrap](references/bootstrap.md).
- **Update:** change owning docs and dependent routes when an approved decision or observed behavior changes them. Read [maintenance](references/maintenance.md).
- **Audit:** assess ownership, routes, evidence, and drift; report without edits unless the user also asks to fix them. Read [maintenance](references/maintenance.md).
- **Clean up:** stale, duplicated or noisy docs are cleaned by `$cda-tidy`, which reads [ownership](references/ownership.md) to place each fact.

For any operation that selects or changes a source of authority, read [ownership](references/ownership.md). Read only the mode reference needed. Delivery and release are contexts for update or audit, not required stages or permission to release; follow the project's actual use and commitments.

When authoring a missing page or reshaping an unsuitable one, use the [output templates and filled examples](references/templates.md), selecting only the relevant template. Existing suitable owners need no template conversion.

Inspect relevant source, docs, work records, and team-owned references before asking for facts the repository can answer. Ask only when an unresolved choice materially changes public behavior, ownership, permissions, or scope. Preserve custom and external sources outside authorized edits. Summarize changed owners, evidence, unresolved gaps, and checks at handoff.
