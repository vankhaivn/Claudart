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

The installation adds `/project-docs` for Claude Code and `$codex-project-docs` for Codex, with matching ownership and maintenance references. Installation does not create a document pack, migrate an existing `docs/project/` tree, or add a new state store. The command or skill can author scoped documentation when the user asks it to do so.

Use natural language or name a mode explicitly:

- **Init** for a new or lightly defined project.
- **Adopt** for an existing project or scattered documentation.
- **Update** when approved intent, observed behavior, a contract, or operating guidance changes.
- **Audit** to review ownership, routes, evidence, and drift without editing.
- **Compact** to make an authorized cleanup of superseded or duplicate material.

The module assigns one owner to each fact or topic. Approved intent, implemented behavior, and released or supported behavior remain distinct. Existing source, schemas, generated references, project documentation, and team-owned external documents retain ownership when they fit; knowledge owns only durable facts with no better current owner and otherwise routes readers to that source. A small router such as `docs/README.md` is a useful default when the repository needs one, not a required layout.

Discovery is bootstrap input while intent is unclear, not a permanent authority. Current pages replace claims that evidence has superseded; Git, release records, and archived work retain history unless a decision record still has a practical purpose. The module does not run a full audit on every session, checkpoint, or small code change. A task or specification uses it only when its work changes what current documentation says.
