# Project Docs module

Project Docs is an optional module that helps the agent look after your project's own documentation: what the product is, how it behaves, how it is built, run, and released. It follows the conventions your repository already has.

## Install

Add `--project-docs` to the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/vankhaivn/Claudart/main/install.sh | bash -s -- --claude --project-docs
```

Use `--codex` or `--both` for the other layers. This adds `/project-docs` (Claude Code) or `$codex-project-docs` (Codex). Installing it creates no documents and moves nothing.

## Modes

Ask in plain language or name a mode:

| Mode        | Use it to                                                      |
| ----------- | -------------------------------------------------------------- |
| **Init**    | Start docs for a new or loosely defined project                |
| **Adopt**   | Take over an existing or scattered set of docs                 |
| **Update**  | Reflect a change in intent, behavior, contracts, or operations |
| **Audit**   | Review ownership, links, and drift without editing             |
| **Compact** | Remove outdated or duplicate material, when you authorize it   |

It runs only when you ask, or when a task changes what current docs say. It never audits on every session.

## Templates

When a responsibility has no owner yet, the module suggests this layout:

```text
docs/
├── README.md                # overview and where things live
├── product.md               # problem, users, scope, constraints
├── behavior/<capability>.md # rules, flows, quality expectations
├── architecture.md          # boundaries, runtime flows, data, risks
├── development.md           # setup, run, test, checks
└── operations.md            # run, update, recover, release, support
```

It is a suggestion, not a required tree. Create only the pages you need: a new idea may need just `product.md` and a short router. An app used straight from `main` does not need release notes or an operations page.

- [Claude template guide](.claude/references/project-docs/templates.md)
- [Codex template guide](.agents/skills/codex-project-docs/references/templates.md)
- Examples: [new project](.agents/skills/codex-project-docs/references/examples/new-project.md), [app used from `main`](.agents/skills/codex-project-docs/references/examples/main-latest.md), [adopted project](.agents/skills/codex-project-docs/references/examples/adopted-project.md)

## How it decides

- **One owner per fact.** If code, a schema, an existing doc, or CLAUDART knowledge already owns a topic, the module keeps it there and links to it.
- **Change the minimum.** For each topic it picks keep, update, link, or consolidate. A healthy setup may need no change at all.
- **Intent vs. reality.** Docs keep what was approved separate from what the code actually does today.
- **Current, not a diary.** Pages describe the present; history stays in Git, tasks, and specs.
