# Project Docs module

Project Docs is an optional lifecycle module for current project documentation. It helps an agent establish, adopt, update, audit, or compact documentation while preserving the repository's own conventions and sources of authority.

Install it with a selected runtime layer:

```bash
# Claude Code
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --claude --project-docs

# Codex
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --codex --project-docs

# Both
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --both --project-docs
```

The installation adds `/project-docs` for Claude Code and `$codex-project-docs` for Codex, with matching references, output templates, and filled examples. Installation does not create a document pack, migrate an existing `docs/project/` tree, add a new document store under the module, or authorize authoring or moving live documentation. The command or skill can make scoped changes when the user asks it to do so.

Use natural language or name a mode explicitly:

- **Init** for a new or lightly defined project.
- **Adopt** for an existing project or scattered documentation.
- **Update** when approved intent, observed behavior, a contract, or operating guidance changes.
- **Audit** to review ownership, routes, evidence, and drift without editing.
- **Compact** to make an authorized cleanup of superseded or duplicate material.

## Output templates and examples

The module includes actual adaptable Markdown bodies for these responsibilities:

```text
docs/
├── README.md                # overview, authoritative sources, work/release pointers
├── product.md               # problem, users, approved scope, capabilities, constraints
├── behavior/<capability>.md # rules, flows, quality expectations, delivery reality
├── architecture.md          # context, boundaries, runtime flows, data, risks
├── development.md           # setup, run, test strategy, checks, team workflow
└── operations.md            # run/update/recovery; release/support where applicable
```

This is a suggested mapping when owners are missing, not a required tree. A small project can keep behavior in its product page; a mature one can use its existing layout and link to architecture already maintained in knowledge. An optional decision template captures consequential rationale. Templates carry author notes about updates and retirement; adapt the selected body, resolve its placeholders, and remove irrelevant sections and author notes before publishing.

Fit documentation to how the software is actually used and delivered: local use, current `main`, continuous deployment, or formal releases. These scopes may coexist. An app already used from `main` can document a checked commit and keep run/check guidance in its README, without a separate operations page or release/support sections. A team's required approvals, readiness checks, recovery procedures, and support commitments remain in force. Personal/company labels and project maturity do not determine the process; missing formal release machinery is not itself an audit defect.

- [Codex template guide](.agents/skills/codex-project-docs/references/templates.md) links all seven bodies under that skill's `assets/templates/`.
- [Claude template guide](.claude/references/project-docs/templates.md) links matching bodies under `.claude/references/project-docs/assets/templates/`.
- [Filled new-project example](.agents/skills/codex-project-docs/references/examples/new-project.md) shows a minimal brief and replacement of approved intent.
- [Filled main-latest example](.agents/skills/codex-project-docs/references/examples/main-latest.md) shows an app already used during development, with commit-scoped behavior and local run/check/recovery guidance.
- [Filled adopted-project example](.agents/skills/codex-project-docs/references/examples/adopted-project.md) keeps existing knowledge ownership and follows a capability through implementation, release, and compaction. Both runtimes ship the same synthetic examples.

Read the guide when creating or reshaping a page, then only the relevant template or example. Ordinary updates can retain their current shape. A task/spec owns the proposed delta and execution; docs describe approved requirements and evidenced current behavior, with brief pending pointers when useful. Release evidence advances only its supported scope. Compaction replaces obsolete current claims and removes resolved pending summaries while retaining useful rationale and still-supported behavior.

## Ownership and maintenance

The module assigns one owner to each fact or topic. Approved intent stays distinct from evidenced behavior in the relevant commit or use scope; separate release/support states exist only where meaningful. Existing source, schemas, generated references, project documentation, team-owned external documents, and knowledge retain ownership when evidence shows the topic scope and maintenance responsibility fit. A file's location or whether people or agents read it is not enough to move it. Architecture knowledge can remain authoritative and be linked from the docs router; source evidence can support a distinct synthesis owned by knowledge. A small router such as `docs/README.md` is a useful default when the repository needs one, not a required layout.

Adoption records each affected topic's current owner, evidence or gap, and the smallest action: keep, update, link, or consolidate. A healthy docs-and-knowledge arrangement can require no change. Relocation needs a concrete reason such as overlap, scope mismatch, or changed maintenance responsibility; unresolved conflicts stay intact and are reported.

Discovery is bootstrap input while intent is unclear, not a permanent authority. Current pages replace claims that evidence has superseded; Git, release records, and archived work retain history unless a decision record still has a practical purpose. The module does not run a full audit on every session, checkpoint, or small code change. A task or specification uses it only when its work changes what current documentation says.
