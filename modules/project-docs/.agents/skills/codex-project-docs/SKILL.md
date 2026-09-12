---
name: codex-project-docs
description: Establish, adopt, update, or review current project documentation and its sources of authority. Use for project-doc lifecycle requests, including natural-language requests to reconcile or compact stale docs.
---

# Project Docs

Keep usable project documentation aligned with approved intent, observed behavior, and the sources that own each topic. Work within the user's scope and the repository's conventions. This optional skill requires no document pack, new state store, or fixed folder layout.

Infer the operation from the request; a mode name is optional:

- **Init:** establish docs for a new or lightly defined project. Read [bootstrap](references/bootstrap.md).
- **Adopt:** take on an existing project or scattered docs. Read [bootstrap](references/bootstrap.md).
- **Update:** change owning docs and dependent routes when an approved decision or observed behavior changes them. Read [maintenance](references/maintenance.md).
- **Audit:** assess ownership, routes, evidence, and drift; report without edits unless the user also asks to fix them. Read [maintenance](references/maintenance.md).
- **Compact:** make an authorized, focused cleanup of superseded or duplicated docs. Read [maintenance](references/maintenance.md).

For any operation that selects or changes a source of authority, read [ownership](references/ownership.md). Read only the mode reference needed. Release is a context for update or audit, not a release operation.

Inspect relevant source, docs, work records, and team-owned references before asking for facts the repository can answer. Ask only when an unresolved choice materially changes public behavior, ownership, permissions, or scope. Preserve custom and external sources outside authorized edits. Summarize changed owners, evidence, unresolved gaps, and checks at handoff.
