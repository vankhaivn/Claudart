# Example: a new project with only approved intent

This is a synthetic illustration. `Fieldnote`, its names, paths, dates, limits,
versions, and named evidence below are invented; it does not show a real product,
implementation, test, deployment, or release.

An approved brief says that small field teams need to turn paper inspection notes
into a shareable weekly summary. There is no repository implementation yet, so the
smallest useful shape is a router and the approved product owner. It does not add
empty architecture or operations pages.

```text
fieldnote/
├── README.md
└── docs/
    ├── README.md
    └── product.md
```

`README.md` can be the narrow development owner until code exists:

```md
# Fieldnote

Fieldnote is an illustrative project concept for turning a team's inspection notes
into a weekly summary. It has no implementation, test suite, deployment, or
released capability yet.

## Development and testing

No local setup or verification command exists yet. When source work starts,
this file should own its setup and test entry points, with commands evidenced by
the repository rather than guessed here.

## Operations

There is no operated service or support procedure yet. A runbook belongs with the
actual operating owner only when one exists.
```

`docs/README.md` routes readers without turning the router into a second product
brief:

```md
# Fieldnote documentation

- [Product intent and open questions](product.md) — approved user problem, scope,
  and constraints.
- [Development and testing](../README.md#development-and-testing) — currently no
  established setup or checks.
- [Operations](../README.md#operations) — currently no operated service.

No behavior, architecture, API, or release reference exists yet because none is
evidenced for this illustrative project.
```

`docs/product.md` holds the agreed direction and names what remains unknown:

```md
# Product intent

## Approved problem

Illustrative field coordinators collect inspection notes in several formats and
spend too long assembling a weekly summary for site leads. Fieldnote should let a
coordinator enter a note with a site, date, and status, then prepare one summary
for that week's sites.

## Approved scope

The first release is limited to one team's manual note entry and a weekly summary
view. It excludes user accounts, integrations, attachments, and automatic alerts.

## Current intent

The weekly summary should group notes by site and show the note status. This is an
approved direction, not a statement that the behavior is implemented or released.

## Open questions

- Who may edit a note after the weekly summary is shared?
- Which status values and retention period does the team require?
```

Later, the product owner approves a narrower replacement: summaries must show
only unresolved notes. The current page changes one paragraph; it does not keep a
timeline of `group by site → show all statuses → unresolved only` in active
guidance. The updated current-intent section is:

```md
## Current intent

The weekly summary should group unresolved notes by site. This is an approved
direction, not a statement that the behavior is implemented or released.
```

The original product approval and the later approval are hypothetical inputs to
this example. A real project would keep any needed decision history in its chosen
work or decision record, not by copying each edit into `docs/product.md`.
