# Example: adopting a mature project without duplicating owners

This is a synthetic illustration. `Ledgerline`, its file names, versions, limits,
and named evidence are invented. The snippets demonstrate documentation shape;
they are not proof that an application, test, release, or operating procedure ran.

The adopter finds a maintained router, source-backed behavior, an architecture
synthesis in Codex knowledge, a runbook, and a work spec. The useful adoption
keeps those owners instead of creating a generic document pack.

```text
ledgerline/
├── README.md                         # development setup and checks
├── docs/
│   ├── README.md                     # existing documentation router
│   ├── capabilities/report-exports.md
│   └── operations/export-runbook.md
├── .codex/knowledge/
│   ├── INDEX.md
│   └── reporting-architecture.md     # existing technical synthesis
├── specs/background-csv-export.md    # proposed work and acceptance evidence
├── src/reports/exportCsv.ts           # observed current behavior
├── tests/reports/exportCsv.test.ts    # implementation evidence
└── releases/2.4.0.md                  # release and support evidence
```

There is deliberately no `docs/architecture.md`: the retained knowledge synthesis
is the architecture owner. The same principle applies when an existing
`.claude/knowledge/` topic is the maintained architecture owner.

The existing `docs/README.md` becomes a concise router and responsibility map:

```md
# Ledgerline documentation

- [Report exports](capabilities/report-exports.md) — current supported behavior
  and approved product direction.
- [Reporting architecture](../.codex/knowledge/reporting-architecture.md) —
  maintained technical synthesis and component boundaries.
- [Development and testing](../README.md#development-and-testing) — local setup,
  test commands, and repository-owned verification.
- [Export operations](operations/export-runbook.md) — support owner, alert
  handling, and recovery procedure.

The approved background CSV change is tracked in
[`specs/background-csv-export.md`](../specs/background-csv-export.md). That spec,
not this router, owns execution steps, acceptance checks, and implementation
evidence.
```

Before the change, the filled capability owner separates intent from shipped
behavior. Its named sources are hypothetical example references only:

```md
# Report exports

## Purpose and agreed rules

Account administrators export report rows for offline analysis. Exports must use
the requesting account's permissions and the selected report filters. A user
without export permission receives a denial and no report rows. A failed export
must show a retryable error; it must never present a partial file as complete.

Permission isolation and matching the selected row set are stable requirements
verified by the export contract tests, not a new acceptance checklist here.

## Supported in illustrative release 2.4.0

An account administrator can download a report as CSV from the report page. The
request completes synchronously and the browser receives the file in that request.
This claim is supported in this example by `src/reports/exportCsv.ts`,
`tests/reports/exportCsv.test.ts`, and `releases/2.4.0.md`.

## Approved direction

The illustrative product decision `DEC-18` approves a background CSV export for
reports over 50,000 rows. The current synchronous capability is not evidence that
the background export exists or is released.

## Pending work

Proposed execution and acceptance details are in
[`specs/background-csv-export.md`](../../specs/background-csv-export.md).
```

Existing developer and operator owners also stay in place. For example, the
runbook's current support section can be concise and specific:

```md
## CSV export support

The reporting team supports release 2.4.0's synchronous export. Check the export
error dashboard and the request correlation ID before retrying a failed request.
Escalate a permission mismatch to the reporting team without attaching report
rows to the incident. Follow the delivery pipeline's recorded release and rollback
procedure; confirm account isolation and successful CSV download after a release.

The pipeline owns release steps and artifact identity. This runbook owns export
health signals and recovery guidance; the release record owns observed results.
```

An implementation can add evidence without claiming a release. The compact update
to that same page might be:

```md
## Current implementation evidence

`src/reports/queueCsvExport.ts` and
`tests/reports/queueCsvExport.test.ts` illustrate that queued export processing
was implemented and checked in a work record. This is implementation evidence,
not release evidence; supported behavior remains the 2.4.0 statement above.
```

After hypothetical verified release evidence for 2.5.0 arrives, update the
affected delivery sections below. Keep the purpose and agreed rules above intact;
their requirements still apply. Release 2.4.0 remains explicitly supported in this
example, so its behavior stays scoped by version. Remove the resolved pending
summary from both the capability page and router, and update the runbook's queue
health and recovery guidance from the same release's operating evidence:

```md
## Supported in illustrative release 2.5.0

An account administrator can download reports up to 50,000 rows as a synchronous
CSV from the report page. For larger reports, the application creates a background
CSV export and makes the completed file available from the report page.

This illustrative claim is supported by `releases/2.5.0.md` and the release's
linked verification record. The source and tests remain implementation evidence;
they do not alone establish a supported release.

## Still supported: release 2.4.0

Release 2.4.0 continues to export synchronously, including reports above 50,000
rows. Its existing limits and recovery guidance remain in the 2.4.0 support record;
the 2.5.0 background behavior does not apply to that version.
```

The completed spec and release record keep execution and chronology. No archival
copy of the capability page is created just because its current claim changed.
