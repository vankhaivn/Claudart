# Doctor Check Fixtures

Run `node tests/doctor-check/run.mjs` from the repository root.

The test builds temporary, offline fixtures and executes the trusted Codex helper with `--layer codex` and `--layer claude`. It mocks only the sibling knowledge checker, so it can verify invocation count, exit propagation, and preserved `K` diagnostics without network access or model calls. Fixtures are deleted after each run.
