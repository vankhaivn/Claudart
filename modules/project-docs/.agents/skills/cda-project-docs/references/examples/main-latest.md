# Example: a personal app used from main

This is a synthetic illustration. `Daymark`, revisions `R1` and `R2`, commands,
paths, outputs, limits, and evidence names are invented. No actual application,
check, commit, data change, or release is represented here.

One person develops and uses Daymark directly from their local `main` checkout.
That is its delivery model: current behavior is described against an evidenced
main revision, with no separate release notes, operations page, or version-support
matrix because those would have no distinct reader or owner.

```text
daymark/
├── README.md                    # run, check, use, and local recovery
├── docs/
│   ├── README.md                # router
│   └── behavior/daily-log.md    # current user-facing behavior
├── work/faster-search.md        # approved pending change and execution evidence
├── src/log/search.ts            # behavior evidence
└── tests/log/search.test.ts     # check evidence
```

`README.md` owns the actual local workflow and takes a real data problem
seriously even for a personal app:

````md
# Daymark

Daymark is an illustrative local daily-log app used from a local `main` checkout.
Updating `main` does not replace an already-running instance; restart from the
checkout you intend to use.

## Run, check, and use

```console
$ pnpm dev
Daymark listening at http://127.0.0.1:4173

$ pnpm test -- search
3 passed
```

Open the local address, add a dated log entry, and use the search field to find
matching text. These commands and outputs are illustrative; a real README uses
the repository's observed commands and results.

## Local recovery

If an entry is missing, stop using the app, copy `data/daymark.json` before any
repair, and inspect the local error output. A bug that corrupts or loses app data
is still an issue for a one-person app; record the reproduction and recovery in
the work item before changing the file.
````

The router has one behavior owner and a concise pointer to approved work. It does
not invent a release process or a generic production-readiness checklist:

```md
# Daymark documentation

- [Daily-log behavior](behavior/daily-log.md) — current behavior on the evidenced
  `main` revision.
- [Run, check, use, and recovery](../README.md) — local workflow and data care.

The approved faster-search change is tracked in
[`work/faster-search.md`](../work/faster-search.md). That record owns proposal,
implementation steps, and check evidence while it is pending.
```

At `R1`, the filled behavior page reports current evidence and keeps the approved
change separate:

```md
# Daily-log behavior

## Current on illustrative main revision R1

Search matches text in saved log entries and returns results after each keystroke.
This example treats `src/log/search.ts` and `tests/log/search.test.ts` as the
evidence for that behavior on R1. It does not claim a formal release.

## Approved pending change

The user approved showing the newest matching entry first. The proposal and its
execution evidence belong in [`work/faster-search.md`](../../work/faster-search.md).
```

Later, `R2` merges the newest-first behavior and its focused check. The behavior
page can update the affected scope because source and check evidence exist for
`main`; it need not wait for a separate release stage that this project does not use:

```md
## Current on illustrative main revision R2

Search matches text in saved log entries and shows the newest matching entry
first. This example treats `src/log/search.ts` and
`tests/log/search.test.ts` as evidence for the merged R2 behavior on `main`.
```

The pending section and router pointer are removed once the work record records
its completion. A local browser already running R1 has not changed merely because
R2 merged: the person updates their checkout and restarts the app when they want
the new behavior. The work record retains the implementation history; current
docs keep the one current claim. Unrelated merges do not require rewriting this
page or maintaining a per-commit documentation log.
