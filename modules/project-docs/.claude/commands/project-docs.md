---
description: Establish, adopt, update, audit, or compact current project documentation and its sources of authority
---

# Project Docs

Keep the project's usable documentation aligned with approved intent, observed behavior, and the sources that own each topic. Work within the user's requested scope and the repository's existing conventions. This optional command does not require a document pack, new state store, or fixed folder layout.

Infer the operation from the request; an explicit mode name is optional:

- **Init:** establish documentation for a new or lightly defined project. Read [bootstrap](../references/project-docs/bootstrap.md).
- **Adopt:** take on an existing project or scattered documentation. Read [bootstrap](../references/project-docs/bootstrap.md).
- **Update:** change the owning docs and dependent routes when an approved decision or observed behavior changes them. Read [maintenance](../references/project-docs/maintenance.md).
- **Audit:** assess ownership, routes, evidence, and drift; report findings without edits unless the user also asked to fix them. Read [maintenance](../references/project-docs/maintenance.md).
- **Compact:** make an authorized, focused cleanup of superseded or duplicated docs. Read [maintenance](../references/project-docs/maintenance.md).

For any operation that selects or changes a source of authority, read [ownership](../references/project-docs/ownership.md). Read only the mode reference needed for this request. Release is a context for update or audit, not a release operation.

When authoring a missing page or reshaping an unsuitable one, use the [output templates and filled examples](../references/project-docs/templates.md), selecting only the relevant template. Existing suitable owners need no template conversion.

Inspect existing source, docs, task/spec records, and team-owned references within scope before asking for facts the repository can answer. Ask only when an unresolved choice would materially change the project's public behavior, ownership, permissions, or documentation scope. Preserve custom and external sources outside the user's authorized edits. Summarize changed owners, supporting evidence, unresolved gaps, and checks at handoff.
